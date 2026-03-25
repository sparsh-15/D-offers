const { prisma } = require('../db/prisma');

const DEFAULT_REWARD_CONFIG = {
  expiryDays: 90,
  amounts: {
    like_offer: 50,
    purchase_success: 50,
    sale_closed: 50,
    install_verified: 100,
  },
  limits: {
    likesPerDay: 20,
    customerDailyCoins: 300,
    shopkeeperDailyCoins: 1000,
  },
};

function getDayStart(date = new Date()) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function buildError(message, statusCode = 400, code) {
  const error = new Error(message);
  error.statusCode = statusCode;
  if (code) {
    error.code = code;
  }
  return error;
}

async function getEffectiveRewardConfig() {
  const row = await prisma.rewardConfig.findUnique({
    where: { key: 'reward_rules' },
  });

  if (!row || !row.configValue || typeof row.configValue !== 'object') {
    return DEFAULT_REWARD_CONFIG;
  }

  return {
    expiryDays: Number(row.configValue.expiryDays) || DEFAULT_REWARD_CONFIG.expiryDays,
    amounts: {
      ...DEFAULT_REWARD_CONFIG.amounts,
      ...(row.configValue.amounts || {}),
    },
    limits: {
      ...DEFAULT_REWARD_CONFIG.limits,
      ...(row.configValue.limits || {}),
    },
  };
}

function getActionPolicy(actionType, userRole, config) {
  const amount = config.amounts[actionType];

  if (actionType === 'like_offer' || actionType === 'purchase_success') {
    if (userRole !== 'customer') {
      throw buildError('Only customers can claim this reward', 403, 'ROLE_MISMATCH');
    }
  }

  if (actionType === 'sale_closed' || actionType === 'install_verified') {
    if (userRole !== 'shopkeeper') {
      throw buildError('Only shopkeepers can claim this reward', 403, 'ROLE_MISMATCH');
    }
  }

  if (!amount || amount <= 0) {
    throw buildError(`Unsupported reward action: ${actionType}`, 400, 'UNSUPPORTED_ACTION');
  }

  return { amount: Number(amount) };
}

async function enforceDailyFraudLimits(tx, { userId, userRole, actionType, config }) {
  const dayStart = getDayStart();

  if (actionType === 'like_offer') {
    const likesCountToday = await tx.rewardEvent.count({
      where: {
        userId,
        actionType: 'like_offer',
        validated: true,
        createdAt: { gte: dayStart },
      },
    });

    if (likesCountToday >= config.limits.likesPerDay) {
      throw buildError('Daily like reward limit reached', 429, 'DAILY_LIKE_LIMIT_REACHED');
    }
  }

  const creditSumToday = await tx.coinLedgerEntry.aggregate({
    _sum: { amount: true },
    where: {
      userId,
      direction: 'credit',
      createdAt: { gte: dayStart },
    },
  });

  const dailyEarned = Number(creditSumToday._sum.amount || 0);
  const cap = userRole === 'customer'
    ? Number(config.limits.customerDailyCoins)
    : Number(config.limits.shopkeeperDailyCoins);

  return { dailyEarned, cap };
}

async function upsertWallet(tx, { userId, userRole }) {
  return tx.coinWallet.upsert({
    where: { userId },
    update: {},
    create: {
      userId,
      userType: userRole,
      balance: 0,
    },
  });
}

async function updateMilestoneProgress(tx, { userId, amount }) {
  let progress = await tx.coinMilestoneProgress.upsert({
    where: { userId },
    update: {
      lifetimeCredited: { increment: amount },
    },
    create: {
      userId,
      lifetimeCredited: amount,
    },
  });

  const reachedMilestone = await tx.coinMilestoneDefinition.findFirst({
    where: {
      isActive: true,
      thresholdCoins: { lte: progress.lifetimeCredited },
    },
    orderBy: { thresholdCoins: 'desc' },
  });

  if (reachedMilestone && progress.currentMilestoneId !== reachedMilestone.id) {
    progress = await tx.coinMilestoneProgress.update({
      where: { userId },
      data: { currentMilestoneId: reachedMilestone.id },
    });
  }

  return progress;
}

async function awardReward({ userId, userRole, actionType, sourceRef, idempotencyKey, deviceFingerprint, metadata }) {
  if (!idempotencyKey) {
    throw buildError('Idempotency-Key header is required', 400, 'IDEMPOTENCY_KEY_REQUIRED');
  }

  if (!sourceRef || typeof sourceRef !== 'string') {
    throw buildError('sourceRef is required', 400, 'SOURCE_REF_REQUIRED');
  }

  const config = await getEffectiveRewardConfig();
  const { amount } = getActionPolicy(actionType, userRole, config);

  return prisma.$transaction(async (tx) => {
    const existingByIdempotency = await tx.coinLedgerEntry.findUnique({
      where: { idempotencyKey },
      include: { wallet: true },
    });

    if (existingByIdempotency) {
      return {
        duplicate: true,
        ledgerEntry: existingByIdempotency,
        wallet: existingByIdempotency.wallet,
      };
    }

    const existingEvent = await tx.rewardEvent.findUnique({
      where: {
        userId_actionType_sourceRef: {
          userId,
          actionType,
          sourceRef,
        },
      },
    });

    if (existingEvent) {
      throw buildError('Reward already granted for this action', 409, 'DUPLICATE_ACTION_REWARD');
    }

    if (actionType === 'install_verified' && deviceFingerprint) {
      const duplicateDeviceInstall = await tx.rewardEvent.count({
        where: {
          actionType: 'install_verified',
          deviceFingerprint,
          validated: true,
        },
      });

      if (duplicateDeviceInstall > 0) {
        throw buildError('Install reward already used by this device', 409, 'DUPLICATE_INSTALL_DEVICE');
      }
    }

    const { dailyEarned, cap } = await enforceDailyFraudLimits(tx, {
      userId,
      userRole,
      actionType,
      config,
    });

    if (dailyEarned + amount > cap) {
      throw buildError('Daily coin earning cap exceeded', 429, 'DAILY_COIN_CAP_EXCEEDED');
    }

    const wallet = await upsertWallet(tx, { userId, userRole });
    const expiresAt = new Date(Date.now() + config.expiryDays * 24 * 60 * 60 * 1000);

    await tx.rewardEvent.create({
      data: {
        userId,
        userType: userRole,
        actionType,
        sourceRef,
        deviceFingerprint: deviceFingerprint || null,
        idempotencyKey,
        validated: true,
      },
    });

    const ledgerEntry = await tx.coinLedgerEntry.create({
      data: {
        walletId: wallet.id,
        userId,
        userType: userRole,
        direction: 'credit',
        amount,
        actionType,
        sourceRef,
        idempotencyKey,
        metadata: metadata && typeof metadata === 'object' ? metadata : {},
        expiresAt,
      },
    });

    await tx.coinLot.create({
      data: {
        walletId: wallet.id,
        ledgerEntryId: ledgerEntry.id,
        originalAmount: amount,
        remainingAmount: amount,
        earnedAt: ledgerEntry.createdAt,
        expiresAt,
      },
    });

    const updatedWallet = await tx.coinWallet.update({
      where: { id: wallet.id },
      data: {
        balance: { increment: amount },
      },
    });

    if (userRole === 'shopkeeper') {
      await updateMilestoneProgress(tx, { userId, amount });
    }

    return {
      duplicate: false,
      ledgerEntry,
      wallet: updatedWallet,
    };
  });
}

async function reverseReward({ userId, adminRole, originalEntryId, idempotencyKey, sourceRef, metadata }) {
  if (!['super_admin', 'subadmin'].includes(adminRole)) {
    throw buildError('Admin role required to reverse rewards', 403, 'ADMIN_ROLE_REQUIRED');
  }

  if (!idempotencyKey) {
    throw buildError('Idempotency-Key header is required', 400, 'IDEMPOTENCY_KEY_REQUIRED');
  }

  if (!originalEntryId) {
    throw buildError('originalEntryId is required', 400, 'ORIGINAL_ENTRY_ID_REQUIRED');
  }

  return prisma.$transaction(async (tx) => {
    const existingByIdempotency = await tx.coinLedgerEntry.findUnique({
      where: { idempotencyKey },
      include: { wallet: true },
    });

    if (existingByIdempotency) {
      return {
        duplicate: true,
        ledgerEntry: existingByIdempotency,
        wallet: existingByIdempotency.wallet,
      };
    }

    const original = await tx.coinLedgerEntry.findUnique({
      where: { id: originalEntryId },
    });

    if (!original) {
      throw buildError('Original ledger entry not found', 404, 'LEDGER_ENTRY_NOT_FOUND');
    }

    if (original.direction !== 'credit') {
      throw buildError('Only credit entries can be reversed', 400, 'INVALID_REVERSAL_TARGET');
    }

    const alreadyReversed = await tx.coinLedgerEntry.count({
      where: { referenceEntryId: originalEntryId },
    });

    if (alreadyReversed > 0) {
      throw buildError('Entry already reversed', 409, 'ENTRY_ALREADY_REVERSED');
    }

    const ledgerEntry = await tx.coinLedgerEntry.create({
      data: {
        walletId: original.walletId,
        userId: original.userId,
        userType: original.userType,
        direction: 'debit',
        amount: original.amount,
        actionType: 'reversal',
        sourceRef: sourceRef || original.id,
        idempotencyKey,
        referenceEntryId: original.id,
        metadata: metadata && typeof metadata === 'object' ? metadata : {},
      },
    });

    const wallet = await tx.coinWallet.update({
      where: { id: original.walletId },
      data: {
        balance: { decrement: original.amount },
      },
    });

    return {
      duplicate: false,
      ledgerEntry,
      wallet,
    };
  });
}

async function getWalletByUser({ userId }) {
  const wallet = await prisma.coinWallet.findUnique({
    where: { userId },
  });

  if (!wallet) {
    return {
      balance: 0,
      userId,
      userType: null,
      walletId: null,
      createdAt: null,
      updatedAt: null,
    };
  }

  return {
    balance: wallet.balance,
    userId: wallet.userId,
    userType: wallet.userType,
    walletId: wallet.id,
    createdAt: wallet.createdAt,
    updatedAt: wallet.updatedAt,
  };
}

async function getWalletLedger({ userId, limit = 20, skip = 0 }) {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safeSkip = Math.max(Number(skip) || 0, 0);

  const [entries, total] = await Promise.all([
    prisma.coinLedgerEntry.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      skip: safeSkip,
      take: safeLimit,
    }),
    prisma.coinLedgerEntry.count({ where: { userId } }),
  ]);

  return {
    entries,
    total,
    limit: safeLimit,
    skip: safeSkip,
  };
}

async function getExpirySummary({ userId }) {
  const now = new Date();

  const grouped = await prisma.coinLot.groupBy({
    by: ['expiresAt'],
    where: {
      wallet: { userId },
      remainingAmount: { gt: 0 },
      expiresAt: { gt: now },
    },
    _sum: { remainingAmount: true },
    orderBy: { expiresAt: 'asc' },
  });

  const totalExpiring = grouped.reduce((sum, row) => sum + Number(row._sum.remainingAmount || 0), 0);

  return {
    totalExpiring,
    upcomingExpiries: grouped.map((row) => ({
      expiresAt: row.expiresAt,
      amount: Number(row._sum.remainingAmount || 0),
    })),
  };
}

async function getShopkeeperMilestones({ userId }) {
  const [progress, definitions, redemptions] = await Promise.all([
    prisma.coinMilestoneProgress.findUnique({
      where: { userId },
    }),
    prisma.coinMilestoneDefinition.findMany({
      where: { isActive: true },
      orderBy: { thresholdCoins: 'asc' },
    }),
    prisma.coinMilestoneRedemption.findMany({
      where: { userId },
      select: { milestoneId: true, status: true },
    }),
  ]);

  const redeemedByMilestoneId = redemptions.reduce((map, item) => {
    map[item.milestoneId] = item.status;
    return map;
  }, {});

  const lifetime = Number(progress?.lifetimeCredited || 0);

  return {
    lifetimeCredited: lifetime,
    currentMilestoneId: progress?.currentMilestoneId || null,
    milestones: definitions.map((definition) => ({
      id: definition.id,
      thresholdCoins: definition.thresholdCoins,
      rewardAmountPaise: definition.rewardAmountPaise,
      reached: lifetime >= definition.thresholdCoins,
      redemptionStatus: redeemedByMilestoneId[definition.id] || null,
    })),
  };
}

async function redeemMilestone({ userId, milestoneId }) {
  return prisma.$transaction(async (tx) => {
    const [progress, milestone] = await Promise.all([
      tx.coinMilestoneProgress.findUnique({ where: { userId } }),
      tx.coinMilestoneDefinition.findUnique({ where: { id: milestoneId } }),
    ]);

    if (!milestone || !milestone.isActive) {
      throw buildError('Milestone not found', 404, 'MILESTONE_NOT_FOUND');
    }

    if (!progress || progress.lifetimeCredited < milestone.thresholdCoins) {
      throw buildError('Milestone not reached yet', 400, 'MILESTONE_NOT_REACHED');
    }

    const existing = await tx.coinMilestoneRedemption.findUnique({
      where: {
        userId_milestoneId: {
          userId,
          milestoneId,
        },
      },
    });

    if (existing) {
      return existing;
    }

    return tx.coinMilestoneRedemption.create({
      data: {
        userId,
        milestoneId,
        status: 'pending',
      },
    });
  });
}

async function getAdminMetrics() {
  const [issued, debited, byAction, redemptionStats, wallets] = await Promise.all([
    prisma.coinLedgerEntry.aggregate({
      _sum: { amount: true },
      where: { direction: 'credit' },
    }),
    prisma.coinLedgerEntry.aggregate({
      _sum: { amount: true },
      where: { direction: 'debit' },
    }),
    prisma.coinLedgerEntry.groupBy({
      by: ['actionType'],
      _sum: { amount: true },
      _count: { _all: true },
    }),
    prisma.coinMilestoneRedemption.groupBy({
      by: ['status'],
      _count: { _all: true },
    }),
    prisma.coinWallet.count(),
  ]);

  return {
    totalIssued: Number(issued._sum.amount || 0),
    totalDebited: Number(debited._sum.amount || 0),
    activeWallets: wallets,
    byAction: byAction.map((row) => ({
      actionType: row.actionType,
      totalAmount: Number(row._sum.amount || 0),
      count: row._count._all,
    })),
    redemptionStats: redemptionStats.map((row) => ({
      status: row.status,
      count: row._count._all,
    })),
  };
}

async function listRewardConfig() {
  const rows = await prisma.rewardConfig.findMany({
    orderBy: { key: 'asc' },
  });

  return rows;
}

async function updateRewardConfig({ key, value }) {
  if (!key) {
    throw buildError('Config key is required', 400, 'CONFIG_KEY_REQUIRED');
  }

  return prisma.rewardConfig.upsert({
    where: { key },
    update: {
      configValue: value,
      version: { increment: 1 },
    },
    create: {
      key,
      configValue: value,
      version: 1,
    },
  });
}

module.exports = {
  awardReward,
  reverseReward,
  getWalletByUser,
  getWalletLedger,
  getExpirySummary,
  getShopkeeperMilestones,
  redeemMilestone,
  getAdminMetrics,
  listRewardConfig,
  updateRewardConfig,
};
