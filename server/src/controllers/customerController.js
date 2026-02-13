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
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 100, 1), 200);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);

    const filter = {};
    
    // Only filter by status if explicitly provided, otherwise show all
    if (status) {
      filter.status = status;
    }

    // Location filtering: pincode > city > state
    const hasGeoFilter =
      (pincode && String(pincode).trim()) ||
      (city && String(city).trim()) ||
      (state && String(state).trim());

    console.log(`[CUSTOMER_OFFERS] Request - Status: ${status || 'all'}, Filters: ${hasGeoFilter ? `pincode=${pincode || ''}, city=${city || ''}, state=${state || ''}` : 'none'}`);

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
      console.log(`[CUSTOMER_OFFERS] Location filter applied - Found ${ids.size} shopkeepers`);
    } else {
      // When no location filters, only show offers from approved shopkeepers
      const approvedShopkeepers = await User.find({
        role: 'shopkeeper',
        approvalStatus: 'approved',
      })
        .select('_id')
        .lean();
      const shopkeeperIds = approvedShopkeepers.map((u) => new mongoose.Types.ObjectId(u._id));
      if (shopkeeperIds.length > 0) {
        filter.shopkeeperId = { $in: shopkeeperIds };
        console.log(`[CUSTOMER_OFFERS] Showing all offers from ${shopkeeperIds.length} approved shopkeepers`);
      } else {
        console.log(`[CUSTOMER_OFFERS] No approved shopkeepers found`);
      }
    }

    // Don't filter by date - show all offers regardless of validity dates
    // const now = new Date();
    // filter.$or = [{ validTo: null }, { validTo: { $gte: now } }];

    const offers = await Offer.find(filter)
      .sort({ createdAt: -1 })
      .skip(skipNum)
      .limit(limitNum)
      .lean();

    console.log(`[CUSTOMER_OFFERS] Returning ${offers.length} offers`);

    const userId = req.user.userId;
    const userIdStr = String(userId);

    res.status(200).json({
      success: true,
      offers: offers.map((o) => {
        const likedByArray = o.likedBy || [];
        const isLiked = likedByArray.some(id => String(id) === userIdStr);
        return {
          id: o._id?.toString() || o._id,
          shopkeeperId: o.shopkeeperId?.toString() || o.shopkeeperId,
          title: o.title || '',
          description: o.description || '',
          discountType: o.discountType || '',
          discountValue: o.discountValue,
          validFrom: o.validFrom ? o.validFrom.toISOString() : null,
          validTo: o.validTo ? o.validTo.toISOString() : null,
          status: o.status || 'active',
          likesCount: likedByArray.length,
          isLiked: isLiked,
          createdAt: o.createdAt ? o.createdAt.toISOString() : null,
          updatedAt: o.updatedAt ? o.updatedAt.toISOString() : null,
        };
      }),
    });
  } catch (err) {
    next(err);
  }
}

async function toggleLike(req, res, next) {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

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

    const likedByArray = offer.likedBy || [];
    const userIdObj = new mongoose.Types.ObjectId(userId);
    const isLiked = likedByArray.some(id => id.toString() === userId.toString());

    if (isLiked) {
      // Remove like
      offer.likedBy = likedByArray.filter(id => id.toString() !== userId.toString());
      offer.likesCount = Math.max(0, offer.likesCount - 1);
    } else {
      // Add like
      if (!offer.likedBy) {
        offer.likedBy = [];
      }
      offer.likedBy.push(userIdObj);
      offer.likesCount = (offer.likesCount || 0) + 1;
    }

    await offer.save();

    res.status(200).json({
      success: true,
      isLiked: !isLiked,
      likesCount: offer.likedBy.length,
    });
  } catch (err) {
    next(err);
  }
}

async function getLikedOffers(req, res, next) {
  try {
    const userId = req.user.userId;
    const userIdObj = new mongoose.Types.ObjectId(userId);

    // Find all offers liked by this user
    const offers = await Offer.find({
      likedBy: userIdObj,
    })
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      success: true,
      offers: offers.map((o) => {
        const likedByArray = o.likedBy || [];
        return {
          id: o._id?.toString() || o._id,
          shopkeeperId: o.shopkeeperId?.toString() || o.shopkeeperId,
          title: o.title || '',
          description: o.description || '',
          discountType: o.discountType || '',
          discountValue: o.discountValue,
          validFrom: o.validFrom ? o.validFrom.toISOString() : null,
          validTo: o.validTo ? o.validTo.toISOString() : null,
          status: o.status || 'active',
          likesCount: likedByArray.length,
          isLiked: true,
          createdAt: o.createdAt ? o.createdAt.toISOString() : null,
          updatedAt: o.updatedAt ? o.updatedAt.toISOString() : null,
        };
      }),
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listOffers,
  toggleLike,
  getLikedOffers,
};

