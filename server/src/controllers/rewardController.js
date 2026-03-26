const rewardService = require('../services/rewardService');

function getIdempotencyKey(req) {
  return req.headers['idempotency-key'] || req.headers['x-idempotency-key'] || null;
}

async function awardCustomerLike(req, res, next) {
  try {
    const result = await rewardService.awardReward({
      userId: req.user.userId,
      userRole: req.user.role,
      userRoles: req.user.roles,
      actionType: 'like_offer',
      sourceRef: req.body.sourceRef || req.body.offerId,
      idempotencyKey: getIdempotencyKey(req),
      metadata: req.body.metadata || {},
    });

    res.status(result.duplicate ? 200 : 201).json({
      success: true,
      duplicate: result.duplicate,
      walletBalance: result.wallet.balance,
      ledgerEntry: result.ledgerEntry,
    });
  } catch (err) {
    next(err);
  }
}

async function awardCustomerPurchase(req, res, next) {
  try {
    const { sourceRef, purchaseId, validationStatus, metadata } = req.body;

    if (validationStatus && validationStatus !== 'validated') {
      const error = new Error('Purchase validation failed');
      error.statusCode = 400;
      error.code = 'PURCHASE_NOT_VALIDATED';
      throw error;
    }

    const result = await rewardService.awardReward({
      userId: req.user.userId,
      userRole: req.user.role,
      userRoles: req.user.roles,
      actionType: 'purchase_success',
      sourceRef: sourceRef || purchaseId,
      idempotencyKey: getIdempotencyKey(req),
      metadata: metadata || {},
    });

    res.status(result.duplicate ? 200 : 201).json({
      success: true,
      duplicate: result.duplicate,
      walletBalance: result.wallet.balance,
      ledgerEntry: result.ledgerEntry,
    });
  } catch (err) {
    next(err);
  }
}

async function reverseCustomerUnlike(req, res, next) {
  try {
    const result = await rewardService.reverseLikeRewardOnUnlike({
      userId: req.user.userId,
      userRole: req.user.role,
      userRoles: req.user.roles,
      sourceRef: req.body.sourceRef || req.body.offerId,
      idempotencyKey: getIdempotencyKey(req),
    });

    res.status(200).json({
      success: true,
      duplicate: result.duplicate === true,
      reversed: result.reversed === true,
      reason: result.reason || null,
      walletBalance: result.wallet?.balance ?? null,
      ledgerEntry: result.ledgerEntry || null,
    });
  } catch (err) {
    next(err);
  }
}

async function awardShopkeeperSale(req, res, next) {
  try {
    const result = await rewardService.awardReward({
      userId: req.user.userId,
      userRole: req.user.role,
      userRoles: req.user.roles,
      actionType: 'sale_closed',
      sourceRef: req.body.sourceRef || req.body.saleId,
      idempotencyKey: getIdempotencyKey(req),
      metadata: req.body.metadata || {},
    });

    res.status(result.duplicate ? 200 : 201).json({
      success: true,
      duplicate: result.duplicate,
      walletBalance: result.wallet.balance,
      ledgerEntry: result.ledgerEntry,
    });
  } catch (err) {
    next(err);
  }
}

async function awardShopkeeperInstall(req, res, next) {
  try {
    const result = await rewardService.awardReward({
      userId: req.user.userId,
      userRole: req.user.role,
      userRoles: req.user.roles,
      actionType: 'install_verified',
      sourceRef: req.body.sourceRef || req.body.installId,
      idempotencyKey: getIdempotencyKey(req),
      deviceFingerprint: req.body.deviceFingerprint,
      metadata: req.body.metadata || {},
    });

    res.status(result.duplicate ? 200 : 201).json({
      success: true,
      duplicate: result.duplicate,
      walletBalance: result.wallet.balance,
      ledgerEntry: result.ledgerEntry,
    });
  } catch (err) {
    next(err);
  }
}

async function reverseReward(req, res, next) {
  try {
    const result = await rewardService.reverseReward({
      userId: req.user.userId,
      adminRole: req.user.role,
      originalEntryId: req.body.originalEntryId,
      sourceRef: req.body.sourceRef,
      idempotencyKey: getIdempotencyKey(req),
      metadata: req.body.metadata || {},
    });

    res.status(result.duplicate ? 200 : 201).json({
      success: true,
      duplicate: result.duplicate,
      walletBalance: result.wallet.balance,
      ledgerEntry: result.ledgerEntry,
    });
  } catch (err) {
    next(err);
  }
}

async function getMyWallet(req, res, next) {
  try {
    const wallet = await rewardService.getWalletByUser({
      userId: req.user.userId,
    });

    res.status(200).json({ success: true, wallet });
  } catch (err) {
    next(err);
  }
}

async function getMyLedger(req, res, next) {
  try {
    const ledger = await rewardService.getWalletLedger({
      userId: req.user.userId,
      limit: req.query.limit,
      skip: req.query.skip,
    });

    res.status(200).json({ success: true, ...ledger });
  } catch (err) {
    next(err);
  }
}

async function getMyExpirySummary(req, res, next) {
  try {
    const expirySummary = await rewardService.getExpirySummary({ userId: req.user.userId });
    res.status(200).json({ success: true, ...expirySummary });
  } catch (err) {
    next(err);
  }
}

async function getMyMilestones(req, res, next) {
  try {
    const milestones = await rewardService.getShopkeeperMilestones({
      userId: req.user.userId,
    });

    res.status(200).json({ success: true, ...milestones });
  } catch (err) {
    next(err);
  }
}

async function redeemMilestone(req, res, next) {
  try {
    const redemption = await rewardService.redeemMilestone({
      userId: req.user.userId,
      milestoneId: req.params.milestoneId,
    });

    res.status(201).json({ success: true, redemption });
  } catch (err) {
    next(err);
  }
}

async function getAdminMetrics(req, res, next) {
  try {
    const metrics = await rewardService.getAdminMetrics();
    res.status(200).json({ success: true, metrics });
  } catch (err) {
    next(err);
  }
}

async function listRewardConfig(req, res, next) {
  try {
    const configs = await rewardService.listRewardConfig();
    res.status(200).json({ success: true, configs });
  } catch (err) {
    next(err);
  }
}

async function updateRewardConfig(req, res, next) {
  try {
    const config = await rewardService.updateRewardConfig({
      key: req.params.key,
      value: req.body.value,
    });

    res.status(200).json({ success: true, config });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  awardCustomerLike,
  awardCustomerPurchase,
  reverseCustomerUnlike,
  awardShopkeeperSale,
  awardShopkeeperInstall,
  reverseReward,
  getMyWallet,
  getMyLedger,
  getMyExpirySummary,
  getMyMilestones,
  redeemMilestone,
  getAdminMetrics,
  listRewardConfig,
  updateRewardConfig,
};
