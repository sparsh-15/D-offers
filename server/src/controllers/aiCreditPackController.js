const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const { logAdminAction } = require('../middleware/roleAuth');
const { isValidCategory, BUSINESS_CATEGORY_LIST } = require('../config/businessCategories');
const aiPackBulkService = require('../services/aiPackBulkService');

/** Generate unique SKU from displayName + category (e.g. starter_100_retail). */
function generatePackSku(displayName, category) {
  const base = `${String(displayName).trim().toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')}_${String(category).trim().toLowerCase()}`
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
  return base || 'pack';
}

async function getAllPacks(req, res, next) {
  try {
    const { isActive, category } = req.query;
    const where = {};
    if (isActive !== undefined) where.isActive = isActive === 'true';
    if (category && category.trim()) {
      if (!isValidCategory(category)) {
        return res.status(400).json({ success: false, message: 'Invalid category' });
      }
      where.category = category.trim();
    }
    const packs = await prisma.aiCreditPack.findMany({
      where,
      orderBy: [{ priceSilver: 'desc' }, { sortOrder: 'asc' }, { credits: 'asc' }],
    });
    res.json({ success: true, data: packs });
  } catch (err) {
    next(err);
  }
}

async function getPackById(req, res, next) {
  try {
    const packId = await resolvePgId('ai_credit_packs', req.params.packId) || req.params.packId;
    const pack = await prisma.aiCreditPack.findUnique({ where: { id: packId } });
    if (!pack) return res.status(404).json({ success: false, message: 'AI credit pack not found' });
    res.json({ success: true, data: pack });
  } catch (err) {
    next(err);
  }
}

async function createPack(req, res, next) {
  try {
    const { displayName, category, credits, priceSilver, priceGold, pricePlatinum, sortOrder, isActive } = req.body;
    if (!displayName || !category || credits === undefined || priceSilver === undefined || priceGold === undefined || pricePlatinum === undefined) {
      return res.status(400).json({
        success: false,
        message: 'displayName, category, credits, priceSilver, priceGold, and pricePlatinum are required',
      });
    }
    if (!isValidCategory(category)) {
      return res.status(400).json({ success: false, message: 'Invalid category' });
    }
    let sku = generatePackSku(displayName, category);
    let suffix = 0;
    while (await prisma.aiCreditPack.findUnique({ where: { sku } })) {
      suffix += 1;
      sku = `${generatePackSku(displayName, category)}_${suffix}`;
    }
    const pack = await prisma.aiCreditPack.create({
      data: {
        sku,
        displayName: String(displayName).trim(),
        category: String(category).trim().toLowerCase(),
        credits: Number(credits),
        priceSilver: Number(priceSilver),
        priceGold: Number(priceGold),
        pricePlatinum: Number(pricePlatinum),
        sortOrder: sortOrder !== undefined ? Number(sortOrder) : 0,
        isActive: isActive !== false,
      },
    });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_created', null, null, { packId: pack.id, sku: pack.sku }, req.ip);
    res.status(201).json({ success: true, message: 'AI credit pack created successfully', data: pack });
  } catch (err) {
    next(err);
  }
}

async function updatePack(req, res, next) {
  try {
    const packId = await resolvePgId('ai_credit_packs', req.params.packId) || req.params.packId;
    const pack = await prisma.aiCreditPack.findUnique({ where: { id: packId } });
    if (!pack) return res.status(404).json({ success: false, message: 'AI credit pack not found' });
    const { displayName, category, credits, priceSilver, priceGold, pricePlatinum, sortOrder, isActive } = req.body;
    if (category !== undefined && !isValidCategory(category)) {
      return res.status(400).json({ success: false, message: 'Invalid category' });
    }
    const updated = await prisma.aiCreditPack.update({
      where: { id: packId },
      data: {
        ...(displayName !== undefined ? { displayName: String(displayName).trim() } : {}),
        ...(category !== undefined ? { category: String(category).trim().toLowerCase() } : {}),
        ...(credits !== undefined ? { credits: Number(credits) } : {}),
        ...(priceSilver !== undefined ? { priceSilver: Number(priceSilver) } : {}),
        ...(priceGold !== undefined ? { priceGold: Number(priceGold) } : {}),
        ...(pricePlatinum !== undefined ? { pricePlatinum: Number(pricePlatinum) } : {}),
        ...(sortOrder !== undefined ? { sortOrder: Number(sortOrder) } : {}),
        ...(isActive !== undefined ? { isActive: !!isActive } : {}),
      },
    });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_updated', null, null, { packId: updated.id, sku: updated.sku }, req.ip);
    res.json({ success: true, message: 'AI credit pack updated successfully', data: updated });
  } catch (err) {
    next(err);
  }
}

async function deletePack(req, res, next) {
  try {
    const packId = await resolvePgId('ai_credit_packs', req.params.packId) || req.params.packId;
    const pack = await prisma.aiCreditPack.findUnique({ where: { id: packId } });
    if (!pack) return res.status(404).json({ success: false, message: 'AI credit pack not found' });
    await prisma.aiCreditPack.update({
      where: { id: packId },
      data: { isActive: false },
    });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_deleted', null, null, { packId: pack.id, sku: pack.sku }, req.ip);
    res.json({ success: true, message: 'AI credit pack deactivated successfully' });
  } catch (err) {
    next(err);
  }
}

async function downloadAiPackTemplate(req, res, next) {
  try {
    const { format = 'csv' } = req.query;
    const detectedFormat = String(format).toLowerCase();

    const categories = BUSINESS_CATEGORY_LIST;
    let buffer;

    if (detectedFormat === 'xlsx') {
      buffer = await aiPackBulkService.buildTemplateXlsx({ categories });
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename="ai_packs_template.xlsx"');
    } else {
      buffer = aiPackBulkService.buildTemplateCsv();
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="ai_packs_template.csv"');
    }

    await logAdminAction(req.user.userId, req.user.role, 'ai_pack_template_downloaded', null, null, { format: detectedFormat }, req.ip);
    res.send(buffer);
  } catch (err) {
    next(err);
  }
}

async function exportAiPacks(req, res, next) {
  try {
    const { format = 'csv' } = req.query;
    const detectedFormat = String(format).toLowerCase();

    const packs = await prisma.aiCreditPack.findMany({
      orderBy: [{ priceSilver: 'desc' }, { sortOrder: 'asc' }, { credits: 'asc' }],
    });

    const exportRows = aiPackBulkService.packsToExportRows(packs);
    let buffer;

    if (detectedFormat === 'xlsx') {
      buffer = await aiPackBulkService.buildExportXlsx(exportRows);
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename="ai_packs_export.xlsx"');
    } else {
      buffer = aiPackBulkService.buildExportCsv(exportRows);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="ai_packs_export.csv"');
    }

    await logAdminAction(req.user.userId, req.user.role, 'ai_packs_exported', null, null, { format: detectedFormat, count: packs.length }, req.ip);
    res.send(buffer);
  } catch (err) {
    next(err);
  }
}

async function importAiPacks(req, res, next) {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ success: false, message: 'Upload file is required' });
    }

    const rawRows = await aiPackBulkService.parsePackFile({
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

    const normalized = aiPackBulkService.normalizeImportRows(rawRows, {
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

    const result = await prisma.$transaction(async (tx) => {
      let created = 0;
      let updated = 0;

      for (const item of normalized.rows) {
        const payload = item.payload;
        const existing = await tx.aiCreditPack.findUnique({ where: { sku: payload.sku } });

        if (!existing) {
          await tx.aiCreditPack.create({
            data: {
              sku: payload.sku,
              displayName: payload.displayName,
              category: payload.category,
              credits: payload.credits,
              priceSilver: payload.priceSilver,
              priceGold: payload.priceGold,
              pricePlatinum: payload.pricePlatinum,
              sortOrder: payload.sortOrder,
              isActive: payload.isActive,
            },
          });
          created += 1;
          continue;
        }

        await tx.aiCreditPack.update({
          where: { id: existing.id },
          data: {
            displayName: payload.displayName,
            category: payload.category,
            credits: payload.credits,
            priceSilver: payload.priceSilver,
            priceGold: payload.priceGold,
            pricePlatinum: payload.pricePlatinum,
            sortOrder: payload.sortOrder,
            isActive: payload.isActive,
          },
        });
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
      'ai_packs_bulk_imported',
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
      message: 'AI credit packs imported successfully',
      data: result,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getAllPacks,
  getPackById,
  createPack,
  updatePack,
  deletePack,
  downloadAiPackTemplate,
  exportAiPacks,
  importAiPacks,
};
