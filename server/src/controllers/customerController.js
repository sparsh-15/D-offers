const mongoose = require('mongoose');
const Offer = require('../models/Offer');
const User = require('../models/User');
const ShopkeeperProfile = require('../models/ShopkeeperProfile');

function buildCaseInsensitiveRegex(value) {
  const escaped = String(value)
    .trim()
    .replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`^${escaped}$`, 'i');
}

async function listOffers(req, res, next) {
  try {
    const { status, limit, skip, pincode, city, state } = req.query;
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);

    const filter = {
      status: status || 'active',
    };

    // Location filtering: pincode > city > state
    const hasGeoFilter =
      (pincode && String(pincode).trim()) ||
      (city && String(city).trim()) ||
      (state && String(state).trim());

    // Resolve shopkeepers by location only when filters are provided
    if (hasGeoFilter) {
      const ids = new Set();

      if (pincode && String(pincode).trim()) {
        const normalizedPincode = String(pincode).trim();
        const byUser = await User.find({
          role: 'shopkeeper',
          approvalStatus: 'approved',
          pincode: normalizedPincode,
        })
          .select('_id')
          .lean();
        const byProfile = await ShopkeeperProfile.find({
          pincode: normalizedPincode,
        })
          .select('userId')
          .lean();
        byUser.forEach((u) => ids.add(String(u._id)));
        byProfile.forEach((p) => ids.add(String(p.userId)));
      } else if (city && String(city).trim()) {
        const cityRegex = buildCaseInsensitiveRegex(city);
        const byUser = await User.find({
          role: 'shopkeeper',
          approvalStatus: 'approved',
          city: cityRegex,
        })
          .select('_id')
          .lean();
        const byProfile = await ShopkeeperProfile.find({
          city: cityRegex,
        })
          .select('userId')
          .lean();
        byUser.forEach((u) => ids.add(String(u._id)));
        byProfile.forEach((p) => ids.add(String(p.userId)));
      } else if (state && String(state).trim()) {
        const stateRegex = buildCaseInsensitiveRegex(state);
        const byUser = await User.find({
          role: 'shopkeeper',
          approvalStatus: 'approved',
          state: stateRegex,
        })
          .select('_id')
          .lean();
        byUser.forEach((u) => ids.add(String(u._id)));
      }

      if (ids.size === 0) {
        return res.status(200).json({ success: true, offers: [] });
      }

      const shopkeeperIds = Array.from(ids).map(
        (id) => new mongoose.Types.ObjectId(id)
      );
      filter.shopkeeperId = { $in: shopkeeperIds };
    }

    const now = new Date();
    filter.$or = [{ validTo: null }, { validTo: { $gte: now } }];

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
        likesCount: o.likesCount,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listOffers,
};

