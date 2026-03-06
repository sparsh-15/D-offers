const shopkeeperProfileRepository = require('../repositories/shopkeeperProfileRepository');
const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const { getAvailableCredits } = require('../services/aiWalletService');

async function getProfile(req, res, next) {
  try {
    let userId = req.user.userId;
    const adminRoles = ['super_admin', 'subadmin'];
    if (adminRoles.includes(req.user.role) && req.query.userId) {
      userId = req.query.userId;
    }
    const pgUserId = await resolvePgId('users', userId);
    if (!pgUserId) {
      const err = new Error('Invalid user id');
      err.statusCode = 400;
      return next(err);
    }
    const profile = await prisma.shopkeeperProfile.findUnique({ where: { userId: pgUserId } });
    if (!profile) {
      const err = new Error('Profile not found');
      err.statusCode = 404;
      return next(err);
    }
    res.status(200).json({ success: true, profile });
  } catch (err) {
    next(err);
  }
}

async function upsertProfile(req, res, next) {
  try {
    const { shopName, address, pincode, city, category, description } = req.body;
    if (!shopName || typeof shopName !== 'string' || !shopName.trim()) {
      const err = new Error('shopName is required');
      err.statusCode = 400;
      return next(err);
    }
    const profile = await shopkeeperProfileRepository.upsertByUserId(req.user.userId, {
      shopName: shopName.trim(),
      address: address != null ? String(address).trim() : undefined,
      pincode: pincode != null ? String(pincode).trim() : undefined,
      city: city != null ? String(city).trim() : undefined,
      category: category != null ? String(category).trim() : undefined,
      description: description != null ? String(description).trim() : undefined,
    });

    // Keep core user location fields in sync so customer pincode/city filters work correctly.
    const pgUserId = await resolvePgId('users', req.user.userId);
    if (pgUserId) {
      const data = {};
      if (pincode != null) data.pincode = String(pincode).trim();
      if (city != null) data.city = String(city).trim();
      if (Object.keys(data).length > 0) {
        await prisma.user.update({
          where: { id: pgUserId },
          data,
        });
      }
    }

    res.status(200).json({ success: true, profile });
  } catch (err) {
    next(err);
  }
}

async function getDashboard(req, res, next) {
  try {
    const pgUserId = await resolvePgId('users', req.user.userId);
    const profile = await prisma.shopkeeperProfile.findUnique({ where: { userId: pgUserId } });
    let subscription = req.subscription || null;
    if (subscription && subscription.status === 'active') {
      const wallet = await prisma.aiWallet.findUnique({ where: { shopkeeperId: pgUserId } });
      subscription = {
        ...subscription,
        availableAiCredits: wallet ? getAvailableCredits(wallet) : 0,
        usedThisCycle: wallet?.usedThisCycle ?? 0,
        extraCreditsCurrentCycle: wallet?.extraCreditsCurrentCycle ?? 0,
        cycleEnd: wallet?.cycleEnd ?? subscription.endDate,
      };
    }
    res.status(200).json({
      success: true,
      dashboard: {
        profile: profile
          ? {
              id: profile.id,
              shopName: profile.shopName,
              address: profile.address,
              city: profile.city,
              category: profile.category,
            }
          : null,
        subscription,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getProfile, upsertProfile, getDashboard };
