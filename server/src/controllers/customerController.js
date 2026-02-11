const mongoose = require('mongoose');
const Offer = require('../models/Offer');
const User = require('../models/User');
const ShopkeeperProfile = require('../models/ShopkeeperProfile');

async function listOffers(req, res, next) {
  try {
    const { status, limit, skip, pincode } = req.query;
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);

    let effectivePincode = (pincode || '').toString().trim();
    if (!effectivePincode && req.user && req.user.userId) {
      const me = await User.findById(req.user.userId)
        .select('pincode')
        .lean();
      effectivePincode = me?.pincode || '';
    }

    const filter = {
      status: status || 'active',
    };

    // Filter by pincode via shopkeeper's User.pincode or ShopkeeperProfile.pincode
    let shopkeeperIds = null;
    if (effectivePincode) {
      const byUser = await User.find({
        role: 'shopkeeper',
        approvalStatus: 'approved',
        pincode: effectivePincode,
      })
        .select('_id')
        .lean();
      const byProfile = await ShopkeeperProfile.find({
        pincode: effectivePincode,
      })
        .select('userId')
        .lean();

      const ids = new Set();
      byUser.forEach((u) => ids.add(String(u._id)));
      byProfile.forEach((p) => ids.add(String(p.userId)));

      if (ids.size === 0) {
        return res.status(200).json({ success: true, offers: [] });
      }
      shopkeeperIds = Array.from(ids).map((id) => new mongoose.Types.ObjectId(id));
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

