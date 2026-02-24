const { prisma } = require('../db/prisma');
const offerRepository = require('../repositories/offerRepository');
const { resolvePgId } = require('../repositories/idResolver');

async function create(req, res, next) {
  try {
    const { title, description, discountType, discountValue, validFrom, validTo, photos, termsAndConditions, category } = req.body;
    if (!title || typeof title !== 'string' || !title.trim()) {
      const err = new Error('title is required');
      err.statusCode = 400;
      return next(err);
    }
    const offer = await offerRepository.createOffer({
      shopkeeperId: req.user.userId,
      title: title.trim(),
      description: description != null ? String(description).trim() : '',
      photos: Array.isArray(photos) ? photos.filter((p) => p && typeof p === 'string') : [],
      termsAndConditions: termsAndConditions != null ? String(termsAndConditions).trim() : '',
      category: category != null ? String(category).trim() : '',
      discountType: discountType || 'percentage',
      discountValue: discountValue != null ? discountValue : null,
      validFrom: validFrom ? new Date(validFrom) : null,
      validTo: validTo ? new Date(validTo) : null,
      status: 'active',
    });
    res.status(201).json({ success: true, offer: { ...offer, id: offer.id } });
  } catch (err) {
    next(err);
  }
}

async function list(req, res, next) {
  try {
    const { status, limit, skip } = req.query;
    const adminRoles = ['super_admin', 'subadmin'];
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);

    const where = {};
    if (!adminRoles.includes(req.user.role)) {
      const pgShopkeeperId = await resolvePgId('users', req.user.userId);
      where.shopkeeperId = pgShopkeeperId;
    }
    if (status) where.status = status;

    const offers = await prisma.offer.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: skipNum,
      take: limitNum,
    });

    const skIds = [...new Set(offers.map((o) => o.shopkeeperId).filter(Boolean))];
    const profiles = skIds.length
      ? await prisma.shopkeeperProfile.findMany({
          where: { userId: { in: skIds } },
          select: { userId: true, shopName: true },
        })
      : [];
    const shopNameMap = {};
    profiles.forEach((p) => {
      shopNameMap[String(p.userId)] = p.shopName || 'Shop';
    });

    res.status(200).json({
      success: true,
      offers: offers.map((o) => ({
        id: o.id,
        shopkeeperId: o.shopkeeperId,
        shopName: shopNameMap[o.shopkeeperId] || null,
        title: o.title,
        description: o.description,
        photos: o.photos || [],
        termsAndConditions: o.termsAndConditions || '',
        category: o.category || '',
        discountType: o.discountType,
        discountValue: o.discountValue,
        validFrom: o.validFrom,
        validTo: o.validTo,
        status: o.status,
        likesCount: o.likesCount,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function getOne(req, res, next) {
  try {
    const pgOfferId = (await resolvePgId('offers', req.params.id)) || req.params.id;
    const offer = await prisma.offer.findUnique({ where: { id: pgOfferId } });
    if (!offer) {
      const err = new Error('Offer not found');
      err.statusCode = 404;
      return next(err);
    }
    const adminRoles = ['super_admin', 'subadmin'];
    if (!adminRoles.includes(req.user.role)) {
      const myId = await resolvePgId('users', req.user.userId);
      if (String(offer.shopkeeperId) !== String(myId)) {
        const err = new Error('Insufficient permissions');
        err.statusCode = 403;
        return next(err);
      }
    }
    res.status(200).json({ success: true, offer: { ...offer, id: offer.id } });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const pgOfferId = (await resolvePgId('offers', req.params.id)) || req.params.id;
    const existing = await prisma.offer.findUnique({ where: { id: pgOfferId } });
    if (!existing) {
      const err = new Error('Offer not found');
      err.statusCode = 404;
      return next(err);
    }

    const adminRoles = ['super_admin', 'subadmin'];
    if (!adminRoles.includes(req.user.role)) {
      const myId = await resolvePgId('users', req.user.userId);
      if (String(existing.shopkeeperId) !== String(myId)) {
        const err = new Error('Insufficient permissions');
        err.statusCode = 403;
        return next(err);
      }
    }

    const { title, description, discountType, discountValue, validFrom, validTo, status, photos, termsAndConditions, category } = req.body;
    const changes = {};
    if (title !== undefined) changes.title = String(title).trim();
    if (description !== undefined) changes.description = String(description).trim();
    if (photos !== undefined) changes.photos = Array.isArray(photos) ? photos.filter((p) => p && typeof p === 'string') : [];
    if (termsAndConditions !== undefined) changes.termsAndConditions = String(termsAndConditions).trim();
    if (category !== undefined) changes.category = String(category).trim();
    if (discountType !== undefined) changes.discountType = discountType;
    if (discountValue !== undefined) changes.discountValue = discountValue;
    if (validFrom !== undefined) changes.validFrom = validFrom ? new Date(validFrom) : null;
    if (validTo !== undefined) changes.validTo = validTo ? new Date(validTo) : null;
    if (status !== undefined) changes.status = status;

    const offer = await offerRepository.updateOffer(pgOfferId, changes);
    res.status(200).json({ success: true, offer: { ...offer, id: offer.id } });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const pgOfferId = (await resolvePgId('offers', req.params.id)) || req.params.id;
    const offer = await prisma.offer.findUnique({ where: { id: pgOfferId } });
    if (!offer) {
      const err = new Error('Offer not found');
      err.statusCode = 404;
      return next(err);
    }
    const adminRoles = ['super_admin', 'subadmin'];
    if (!adminRoles.includes(req.user.role)) {
      const myId = await resolvePgId('users', req.user.userId);
      if (String(offer.shopkeeperId) !== String(myId)) {
        const err = new Error('Insufficient permissions');
        err.statusCode = 403;
        return next(err);
      }
    }
    await offerRepository.deleteOffer(pgOfferId);
    res.status(200).json({ success: true, message: 'Offer deleted' });
  } catch (err) {
    next(err);
  }
}

module.exports = { create, list, getOne, update, remove };
