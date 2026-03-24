const { prisma } = require('../db/prisma');
const { logAdminAction } = require('../middleware/roleAuth');
const {
  isValidCategory,
  ALL_CATEGORIES,
  getAllCategories,
} = require('../config/businessCategories');
const subscriptionPlanRepository = require('../repositories/subscriptionPlanRepository');
const { resolvePgId } = require('../repositories/idResolver');
const {
  plansToExportRows,
  normalizeImportRows,
  buildTemplateXlsx,
  buildTemplateCsv,
  buildExportXlsx,
  buildExportCsv,
  parsePlanFile,
} = require('../services/subscriptionPlanBulkService');

const ALLOWED_PLAN_TIERS = new Set(['free', 'trial', 'silver', 'gold', 'platinum']);

function normalizeTierInput(tier) {
  if (tier === undefined || tier === null) return undefined;
  const normalized = String(tier).trim().toLowerCase();
  return normalized || undefined;
}

function asBooleanQuery(value) {
  if (value === undefined) return undefined;
  const normalized = String(value).trim().toLowerCase();
  if (normalized === 'true') return true;
  if (normalized === 'false') return false;
  return undefined;
}

function asDownloadFormat(value) {
  const normalized = String(value || 'csv').trim().toLowerCase();
  return normalized === 'xlsx' ? 'xlsx' : 'csv';
}

function sendAttachment(res, { buffer, fileName, contentType }) {
  res.setHeader('Content-Type', contentType);
  res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
  res.send(buffer);
}

async function getCategories(req, res, next) {
  try {
    res.json({ success: true, data: getAllCategories() });
  } catch (err) {
    next(err);
  }
}

async function createPlan(req, res, next) {
  try {
    const { name, displayName, description, monthlyPrice, durationDays, category, features, maxOffers, maxPhotosPerOffer, analyticsEnabled, prioritySupport, sortOrder, monthlyAiLimit, rankingTier, homepageRotation, aiOptimizationSuggestions, aiCreditTier, tier } = req.body;
    if (!name || !displayName || monthlyPrice === undefined || !category) {
      return res.status(400).json({ success: false, message: 'Name, display name, monthly price, and category are required' });
    }
    if (!isValidCategory(category)) {
      return res.status(400).json({ success: false, message: 'Invalid category' });
    }
    const normalizedTier = normalizeTierInput(tier);
    if (normalizedTier !== undefined && !ALLOWED_PLAN_TIERS.has(normalizedTier)) {
      return res.status(400).json({ success: false, message: 'Invalid tier. Allowed values: free, trial, silver, gold, platinum' });
    }
    const existing = await prisma.subscriptionPlan.findFirst({ where: { name } });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Plan with this name already exists' });
    }
    const plan = await subscriptionPlanRepository.createPlan({
      name,
      displayName,
      description,
      monthlyPrice,
      durationDays: durationDays || 30,
      category,
      features: features || [],
      maxOffers: maxOffers !== undefined ? maxOffers : -1,
      maxPhotosPerOffer: maxPhotosPerOffer || 5,
      analyticsEnabled: analyticsEnabled || false,
      prioritySupport: prioritySupport || false,
      sortOrder: sortOrder || 0,
      isActive: true,
      monthlyAiLimit: monthlyAiLimit !== undefined ? monthlyAiLimit : 0,
      rankingTier: rankingTier || 'normal',
      homepageRotation: !!homepageRotation,
      aiOptimizationSuggestions: !!aiOptimizationSuggestions,
      aiCreditTier: aiCreditTier || 'silver',
      tier: normalizedTier,
    });
    await prisma.subscriptionPlanPriceHistory.create({
      data: {
        planId: plan.id,
        price: monthlyPrice,
        changedBy: await resolvePgId('users', req.user.userId),
        reason: 'Initial price',
      },
    });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_created', null, null, { planId: plan.id, planName: plan.name, category: plan.category }, req.ip);
    res.status(201).json({ success: true, message: 'Subscription plan created successfully', data: plan });
  } catch (err) {
    next(err);
  }
}

async function getAllPlans(req, res, next) {
  try {
    const { isActive, category } = req.query;
    const where = {};
    if (isActive !== undefined) where.isActive = isActive === 'true';
    if (category) where.category = category;
    const plans = await prisma.subscriptionPlan.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    });
    res.json({ success: true, data: plans });
  } catch (err) {
    next(err);
  }
}

async function getPlanById(req, res, next) {
  try {
    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: req.params.planId } });
    if (!plan) return res.status(404).json({ success: false, message: 'Plan not found' });
    const activeSubscriptions = await prisma.subscription.count({
      where: { planId: plan.id, status: 'active' },
    });
    res.json({ success: true, data: { ...plan, activeSubscriptions } });
  } catch (err) {
    next(err);
  }
}

async function updatePlan(req, res, next) {
  try {
    const { planId } = req.params;
    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: planId } });
    if (!plan) return res.status(404).json({ success: false, message: 'Plan not found' });
    const { displayName, description, monthlyPrice, durationDays, category, features, maxOffers, maxPhotosPerOffer, analyticsEnabled, prioritySupport, sortOrder, isActive, priceChangeReason, monthlyAiLimit, rankingTier, homepageRotation, aiOptimizationSuggestions, aiCreditTier, tier } = req.body;
    if (category !== undefined && !isValidCategory(category)) {
      return res.status(400).json({ success: false, message: 'Invalid category' });
    }
    const normalizedTier = normalizeTierInput(tier);
    if (normalizedTier !== undefined && !ALLOWED_PLAN_TIERS.has(normalizedTier)) {
      return res.status(400).json({ success: false, message: 'Invalid tier. Allowed values: free, trial, silver, gold, platinum' });
    }
    const priceChanged = monthlyPrice !== undefined && Number(monthlyPrice) !== Number(plan.monthlyPrice);
    const updated = await subscriptionPlanRepository.updatePlan(planId, {
      ...(displayName !== undefined ? { displayName } : {}),
      ...(description !== undefined ? { description } : {}),
      ...(monthlyPrice !== undefined ? { monthlyPrice } : {}),
      ...(durationDays !== undefined ? { durationDays } : {}),
      ...(category !== undefined ? { category } : {}),
      ...(features !== undefined ? { features } : {}),
      ...(maxOffers !== undefined ? { maxOffers } : {}),
      ...(maxPhotosPerOffer !== undefined ? { maxPhotosPerOffer } : {}),
      ...(analyticsEnabled !== undefined ? { analyticsEnabled } : {}),
      ...(prioritySupport !== undefined ? { prioritySupport } : {}),
      ...(sortOrder !== undefined ? { sortOrder } : {}),
      ...(isActive !== undefined ? { isActive } : {}),
      ...(monthlyAiLimit !== undefined ? { monthlyAiLimit } : {}),
      ...(rankingTier !== undefined ? { rankingTier } : {}),
      ...(homepageRotation !== undefined ? { homepageRotation } : {}),
      ...(aiOptimizationSuggestions !== undefined ? { aiOptimizationSuggestions } : {}),
      ...(aiCreditTier !== undefined ? { aiCreditTier } : {}),
      ...(tier !== undefined ? { tier: normalizedTier } : {}),
    });
    if (priceChanged) {
      await prisma.subscriptionPlanPriceHistory.create({
        data: {
          planId,
          price: monthlyPrice,
          changedBy: await resolvePgId('users', req.user.userId),
          reason: priceChangeReason || 'Price update',
        },
      });
    }
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_updated', null, null, { planId: updated.id, planName: updated.name, priceChanged, newPrice: priceChanged ? monthlyPrice : undefined }, req.ip);
    res.json({ success: true, message: 'Plan updated successfully', data: updated });
  } catch (err) {
    next(err);
  }
}

async function deletePlan(req, res, next) {
  try {
    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: req.params.planId } });
    if (!plan) return res.status(404).json({ success: false, message: 'Plan not found' });
    const activeSubscriptions = await prisma.subscription.count({
      where: { planId: plan.id, status: 'active' },
    });
    if (activeSubscriptions > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete plan with active subscriptions',
        details: { activeSubscriptions, action: 'Deactivate the plan instead or wait for subscriptions to expire' },
      });
    }
    await subscriptionPlanRepository.updatePlan(plan.id, { isActive: false });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_deleted', null, null, { planId: plan.id, planName: plan.name }, req.ip);
    res.json({ success: true, message: 'Plan deactivated successfully' });
  } catch (err) {
    next(err);
  }
}

async function getRecommendedPlans(req, res, next) {
  try {
    const { category } = req.query;
    if (!category) return res.status(400).json({ success: false, message: 'Category is required' });
    if (!isValidCategory(category)) return res.status(400).json({ success: false, message: 'Invalid category' });
    const plans = await prisma.subscriptionPlan.findMany({
      where: {
        isActive: true,
        OR: [{ category }, { category: ALL_CATEGORIES }],
        NOT: [
          { name: 'free_starter_all' },
          { tier: 'free' },
          { tier: 'trial' },
        ],
      },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    });
    res.json({ success: true, data: plans });
  } catch (err) {
    next(err);
  }
}

async function downloadPlanTemplate(req, res, next) {
  try {
    const format = asDownloadFormat(req.query.format);
    const categories = [ALL_CATEGORIES, ...getAllCategories().map((c) => c.value)];
    const tiers = Array.from(ALLOWED_PLAN_TIERS.values()).filter((tier) => tier !== 'free');

    if (format === 'xlsx') {
      const workbookBuffer = await buildTemplateXlsx({ categories, tiers });
      await logAdminAction(
        req.user.userId,
        req.user.role,
        'subscription_plan_template_downloaded',
        null,
        null,
        { format: 'xlsx' },
        req.ip
      );
      return sendAttachment(res, {
        buffer: Buffer.from(workbookBuffer),
        fileName: 'subscription-plans-template.xlsx',
        contentType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
    }

    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_plan_template_downloaded',
      null,
      null,
      { format: 'csv' },
      req.ip
    );
    return sendAttachment(res, {
      buffer: buildTemplateCsv(),
      fileName: 'subscription-plans-template.csv',
      contentType: 'text/csv; charset=utf-8',
    });
  } catch (err) {
    return next(err);
  }
}

async function exportPlans(req, res, next) {
  try {
    const format = asDownloadFormat(req.query.format);
    const where = {};
    const isActiveQuery = asBooleanQuery(req.query.isActive);

    if (isActiveQuery !== undefined) where.isActive = isActiveQuery;
    if (req.query.category) where.category = String(req.query.category).trim().toLowerCase();

    const plans = await prisma.subscriptionPlan.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    });

    const exportRows = plansToExportRows(plans);
    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_plan_exported',
      null,
      null,
      {
        format,
        count: exportRows.length,
        filters: {
          category: where.category || null,
          isActive: where.isActive === undefined ? null : where.isActive,
        },
      },
      req.ip
    );

    if (format === 'xlsx') {
      const workbookBuffer = await buildExportXlsx(exportRows);
      return sendAttachment(res, {
        buffer: Buffer.from(workbookBuffer),
        fileName: 'subscription-plans-export.xlsx',
        contentType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
    }

    return sendAttachment(res, {
      buffer: buildExportCsv(exportRows),
      fileName: 'subscription-plans-export.csv',
      contentType: 'text/csv; charset=utf-8',
    });
  } catch (err) {
    return next(err);
  }
}

async function importPlans(req, res, next) {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ success: false, message: 'Upload file is required' });
    }

    const rawRows = await parsePlanFile({
      fileBuffer: req.file.buffer,
      fileName: req.file.originalname,
      format: req.query.format,
    });

    if (!rawRows.length) {
      return res.status(400).json({
        success: false,
        message: 'No data rows found in uploaded file',
      });
    }

    const normalized = normalizeImportRows(rawRows, {
      allowedTiers: ALLOWED_PLAN_TIERS,
      isValidCategory,
    });

    if (normalized.errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed. Fix all rows before re-uploading.',
        data: {
          totalRows: rawRows.length,
          failedRows: normalized.errors.length,
          errors: normalized.errors,
        },
      });
    }

    const changedBy = await resolvePgId('users', req.user.userId);
    const result = await prisma.$transaction(async (tx) => {
      let created = 0;
      let updated = 0;

      for (const item of normalized.rows) {
        const payload = item.payload;
        const existing = await tx.subscriptionPlan.findFirst({ where: { name: payload.name } });

        if (!existing) {
          const createdPlan = await tx.subscriptionPlan.create({ data: payload });
          await tx.subscriptionPlanPriceHistory.create({
            data: {
              planId: createdPlan.id,
              price: payload.monthlyPrice,
              changedBy,
              reason: 'Bulk import initial price',
            },
          });
          created += 1;
          continue;
        }

        const priceChanged = Number(existing.monthlyPrice) !== Number(payload.monthlyPrice);
        await tx.subscriptionPlan.update({
          where: { id: existing.id },
          data: payload,
        });

        if (priceChanged) {
          await tx.subscriptionPlanPriceHistory.create({
            data: {
              planId: existing.id,
              price: payload.monthlyPrice,
              changedBy,
              reason: 'Bulk import price update',
            },
          });
        }
        updated += 1;
      }

      return {
        totalRows: normalized.rows.length,
        created,
        updated,
      };
    });

    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_plan_bulk_imported',
      null,
      null,
      {
        fileName: req.file.originalname,
        ...result,
      },
      req.ip
    );

    return res.status(200).json({
      success: true,
      message: 'Plans imported successfully',
      data: result,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getCategories,
  createPlan,
  getAllPlans,
  getPlanById,
  updatePlan,
  deletePlan,
  getRecommendedPlans,
  downloadPlanTemplate,
  exportPlans,
  importPlans,
};
