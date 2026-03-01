const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const { logAdminAction } = require('../middleware/roleAuth');
const { isValidCategory } = require('../config/businessCategories');

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

module.exports = {
  getAllPacks,
  getPackById,
  createPack,
  updatePack,
  deletePack,
};
