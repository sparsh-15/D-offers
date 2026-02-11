const Offer = require('../models/Offer');
const mongoose = require('mongoose');

function canAccessOffer(offer, req) {
  if (req.user.role === 'admin') return true;
  return offer.shopkeeperId && String(offer.shopkeeperId) === String(req.user.userId);
}

async function create(req, res, next) {
  try {
    const { title, description, discountType, discountValue, validFrom, validTo } = req.body;
    if (!title || typeof title !== 'string' || !title.trim()) {
      const err = new Error('title is required');
      err.statusCode = 400;
      return next(err);
    }
    const offer = await Offer.create({
      shopkeeperId: req.user.userId,
      title: title.trim(),
      description: description != null ? String(description).trim() : '',
      discountType: discountType || 'percentage',
      discountValue: discountValue != null ? discountValue : null,
      validFrom: validFrom ? new Date(validFrom) : null,
      validTo: validTo ? new Date(validTo) : null,
      status: 'active',
    });
    res.status(201).json({
      success: true,
      offer: {
        id: offer._id,
        shopkeeperId: offer.shopkeeperId,
        title: offer.title,
        description: offer.description,
        discountType: offer.discountType,
        discountValue: offer.discountValue,
        validFrom: offer.validFrom,
        validTo: offer.validTo,
        status: offer.status,
        createdAt: offer.createdAt,
        updatedAt: offer.updatedAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function list(req, res, next) {
  try {
    const { status, limit, skip } = req.query;
    const filter = {};
    if (req.user.role !== 'admin') {
      filter.shopkeeperId = req.user.userId;
    }
    if (status) filter.status = status;
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);
    const offers = await Offer.find(filter)
      .sort({ createdAt: -1 })
      .skip(skipNum)
      .limit(limitNum)
      .lean();
    res.status(200).json({
      success: true,
      offers: offers.map((o) => ({
        id: o._id,
        shopkeeperId: o.shopkeeperId,
        title: o.title,
        description: o.description,
        discountType: o.discountType,
        discountValue: o.discountValue,
        validFrom: o.validFrom,
        validTo: o.validTo,
        status: o.status,
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
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      const err = new Error('Invalid offer id');
      err.statusCode = 400;
      return next(err);
    }
    const offer = await Offer.findById(id).lean();
    if (!offer) {
      const err = new Error('Offer not found');
      err.statusCode = 404;
      return next(err);
    }
    if (!canAccessOffer(offer, req)) {
      const err = new Error('Insufficient permissions');
      err.statusCode = 403;
      return next(err);
    }
    res.status(200).json({
      success: true,
      offer: {
        id: offer._id,
        shopkeeperId: offer.shopkeeperId,
        title: offer.title,
        description: offer.description,
        discountType: offer.discountType,
        discountValue: offer.discountValue,
        validFrom: offer.validFrom,
        validTo: offer.validTo,
        status: offer.status,
        createdAt: offer.createdAt,
        updatedAt: offer.updatedAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { id } = req.params;
    const { title, description, discountType, discountValue, validFrom, validTo, status } = req.body;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      const err = new Error('Invalid offer id');
      err.statusCode = 400;
      return next(err);
    }
    const offer = await Offer.findById(id);
    if (!offer) {
      const err = new Error('Offer not found');
      err.statusCode = 404;
      return next(err);
    }
    if (!canAccessOffer(offer, req)) {
      const err = new Error('Insufficient permissions');
      err.statusCode = 403;
      return next(err);
    }
    if (title !== undefined) offer.title = String(title).trim();
    if (description !== undefined) offer.description = String(description).trim();
    if (discountType !== undefined) offer.discountType = discountType;
    if (discountValue !== undefined) offer.discountValue = discountValue;
    if (validFrom !== undefined) offer.validFrom = validFrom ? new Date(validFrom) : null;
    if (validTo !== undefined) offer.validTo = validTo ? new Date(validTo) : null;
    if (status !== undefined) offer.status = status;
    await offer.save();
    res.status(200).json({
      success: true,
      offer: {
        id: offer._id,
        shopkeeperId: offer.shopkeeperId,
        title: offer.title,
        description: offer.description,
        discountType: offer.discountType,
        discountValue: offer.discountValue,
        validFrom: offer.validFrom,
        validTo: offer.validTo,
        status: offer.status,
        createdAt: offer.createdAt,
        updatedAt: offer.updatedAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      const err = new Error('Invalid offer id');
      err.statusCode = 400;
      return next(err);
    }
    const offer = await Offer.findById(id);
    if (!offer) {
      const err = new Error('Offer not found');
      err.statusCode = 404;
      return next(err);
    }
    if (!canAccessOffer(offer, req)) {
      const err = new Error('Insufficient permissions');
      err.statusCode = 403;
      return next(err);
    }
    await Offer.deleteOne({ _id: id });
    res.status(200).json({ success: true, message: 'Offer deleted' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  create,
  list,
  getOne,
  update,
  remove,
};
