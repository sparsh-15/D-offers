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
  unlikeReversal: {
    enabled: true,
    windowMinutes: 30,
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

function normalizeUserRoles(userRole, userRoles) {
  const roles = new Set();

  if (userRole) {
    roles.add(String(userRole).trim());
  }

  if (Array.isArray(userRoles)) {
    for (const role of userRoles) {
      if (role) {
        roles.add(String(role).trim());
      }
    }
  }

  return Array.from(roles);
}

function hasRole(roles, role) {
  return roles.includes(role);
}

function resolveRewardCapRole(roles, fallbackRole) {
  if (hasRole(roles, 'customer')) return 'customer';
  if (hasRole(roles, 'shopkeeper')) return 'shopkeeper';
  return fallbackRole;
}

function isReversalReferenceUniqueViolation(error) {
  const target = String(error?.meta?.target || '');
  return error?.code === 'P2002' && target.includes('uq_coin_ledger_reversal_reference_entry');
}

function isWalletBalanceConstraintViolation(error) {
  const dbError = String(error?.meta?.database_error || error?.message || '');
  return dbError.includes('chk_coin_wallets_balance_non_negative');
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
    unlikeReversal: {
      ...DEFAULT_REWARD_CONFIG.unlikeReversal,
      ...(row.configValue.unlikeReversal || {}),
    },
  };
}

function getActionPolicy(actionType, roles, config) {
  const amount = config.amounts[actionType];

  if (actionType === 'like_offer' || actionType === 'purchase_success') {
    if (!hasRole(roles, 'customer')) {
      throw buildError('Only customers can claim this reward', 403, 'ROLE_MISMATCH');
    }
  }

  if (actionType === 'sale_closed' || actionType === 'install_verified') {
    if (!hasRole(roles, 'shopkeeper')) {
      throw buildError('Only shopkeepers can claim this reward', 403, 'ROLE_MISMATCH');
    }
  }

  if (!amount || amount <= 0) {
    throw buildError(`Unsupported reward action: ${actionType}`, 400, 'UNSUPPORTED_ACTION');
  }

  return { amount: Number(amount) };
}

async function enforceDailyFraudLimits(tx, { userId, capRole, actionType, config }) {
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
  const cap = capRole === 'customer'
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

async function awardReward({ userId, userRole, userRoles, actionType, sourceRef, idempotencyKey, deviceFingerprint, metadata }) {
  if (!idempotencyKey) {
    throw buildError('Idempotency-Key header is required', 400, 'IDEMPOTENCY_KEY_REQUIRED');
  }

  if (!sourceRef || typeof sourceRef !== 'string') {
    throw buildError('sourceRef is required', 400, 'SOURCE_REF_REQUIRED');
  }

  const config = await getEffectiveRewardConfig();
  const roles = normalizeUserRoles(userRole, userRoles);
  const capRole = resolveRewardCapRole(roles, userRole);
  const { amount } = getActionPolicy(actionType, roles, config);

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
      capRole,
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
  }, {
    maxWait: 10000,
    timeout: 30000,
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

  try {
    return await prisma.$transaction(async (tx) => {
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

    const walletUpdate = await tx.coinWallet.updateMany({
      where: {
        id: original.walletId,
        balance: { gte: original.amount },
      },
      data: {
        balance: { decrement: original.amount },
      },
    });

    if (walletUpdate.count === 0) {
      throw buildError('Insufficient wallet balance for reversal', 409, 'INSUFFICIENT_BALANCE');
    }

    const wallet = await tx.coinWallet.findUnique({
      where: { id: original.walletId },
    });

    if (!wallet) {
      throw buildError('Wallet not found after reversal', 404, 'WALLET_NOT_FOUND');
    }

    return {
      duplicate: false,
      ledgerEntry,
      wallet,
    };
    }, {
      maxWait: 10000,
      timeout: 30000,
    });
  } catch (error) {
    if (isReversalReferenceUniqueViolation(error)) {
      throw buildError('Entry already reversed', 409, 'ENTRY_ALREADY_REVERSED');
    }
    if (isWalletBalanceConstraintViolation(error)) {
      throw buildError('Insufficient wallet balance for reversal', 409, 'INSUFFICIENT_BALANCE');
    }
    throw error;
  }
}

async function reverseLikeRewardOnUnlike({ userId, userRole, userRoles, sourceRef, idempotencyKey }) {
  if (!idempotencyKey) {
    throw buildError('Idempotency-Key header is required', 400, 'IDEMPOTENCY_KEY_REQUIRED');
  }

  if (!sourceRef || typeof sourceRef !== 'string') {
    throw buildError('sourceRef is required', 400, 'SOURCE_REF_REQUIRED');
  }

  const roles = normalizeUserRoles(userRole, userRoles);
  if (!hasRole(roles, 'customer')) {
    throw buildError('Only customers can reverse like rewards', 403, 'ROLE_MISMATCH');
  }

  const config = await getEffectiveRewardConfig();
  const policy = config.unlikeReversal || DEFAULT_REWARD_CONFIG.unlikeReversal;

  if (policy.enabled === false) {
    return {
      reversed: false,
      reason: 'REVERSAL_DISABLED',
      wallet: null,
      ledgerEntry: null,
    };
  }

  const originalLikeReward = await prisma.coinLedgerEntry.findFirst({
    where: {
      userId,
      actionType: 'like_offer',
      sourceRef,
      direction: 'credit',
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!originalLikeReward) {
    return {
      reversed: false,
      reason: 'NO_LIKE_REWARD_FOUND',
      wallet: null,
      ledgerEntry: null,
    };
  }

  const alreadyReversed = await prisma.coinLedgerEntry.count({
    where: { referenceEntryId: originalLikeReward.id },
  });

  if (alreadyReversed > 0) {
    return {
      reversed: false,
      reason: 'ALREADY_REVERSED',
      wallet: null,
      ledgerEntry: null,
    };
  }

  const windowMinutes = Number(policy.windowMinutes || 0);
  if (windowMinutes > 0) {
    const ageMs = Date.now() - new Date(originalLikeReward.createdAt).getTime();
    if (ageMs > windowMinutes * 60 * 1000) {
      return {
        reversed: false,
        reason: 'REVERSAL_WINDOW_EXPIRED',
        wallet: null,
        ledgerEntry: null,
      };
    }
  }

  try {
    return await prisma.$transaction(async (tx) => {
    const existingByIdempotency = await tx.coinLedgerEntry.findUnique({
      where: { idempotencyKey },
      include: { wallet: true },
    });

    if (existingByIdempotency) {
      return {
        duplicate: true,
        reversed: true,
        reason: null,
        ledgerEntry: existingByIdempotency,
        wallet: existingByIdempotency.wallet,
      };
    }

    const wallet = await tx.coinWallet.findUnique({
      where: { id: originalLikeReward.walletId },
    });

    if (!wallet) {
      return {
        reversed: false,
        reason: 'WALLET_NOT_FOUND',
        ledgerEntry: null,
        wallet: null,
      };
    }

    if (wallet.balance < originalLikeReward.amount) {
      return {
        reversed: false,
        reason: 'INSUFFICIENT_BALANCE',
        ledgerEntry: null,
        wallet,
      };
    }

    const ledgerEntry = await tx.coinLedgerEntry.create({
      data: {
        walletId: originalLikeReward.walletId,
        userId: originalLikeReward.userId,
        userType: originalLikeReward.userType,
        direction: 'debit',
        amount: originalLikeReward.amount,
        actionType: 'reversal',
        sourceRef,
        idempotencyKey,
        referenceEntryId: originalLikeReward.id,
        metadata: {
          trigger: 'unlike_offer',
        },
      },
    });

    const walletUpdate = await tx.coinWallet.updateMany({
      where: {
        id: originalLikeReward.walletId,
        balance: { gte: originalLikeReward.amount },
      },
      data: {
        balance: { decrement: originalLikeReward.amount },
      },
    });

    if (walletUpdate.count === 0) {
      const latestWallet = await tx.coinWallet.findUnique({
        where: { id: originalLikeReward.walletId },
      });
      return {
        reversed: false,
        reason: 'INSUFFICIENT_BALANCE',
        ledgerEntry: null,
        wallet: latestWallet,
      };
    }

    const updatedWallet = await tx.coinWallet.findUnique({
      where: { id: originalLikeReward.walletId },
    });

    if (!updatedWallet) {
      return {
        reversed: false,
        reason: 'WALLET_NOT_FOUND',
        ledgerEntry: null,
        wallet: null,
      };
    }

      return {
        duplicate: false,
        reversed: true,
        reason: null,
        ledgerEntry,
        wallet: updatedWallet,
      };
    }, {
      maxWait: 10000,
      timeout: 30000,
    });
  } catch (error) {
    if (isReversalReferenceUniqueViolation(error)) {
      return {
        reversed: false,
        reason: 'ALREADY_REVERSED',
        wallet: null,
        ledgerEntry: null,
      };
    }
    if (isWalletBalanceConstraintViolation(error)) {
      return {
        reversed: false,
        reason: 'INSUFFICIENT_BALANCE',
        wallet: null,
        ledgerEntry: null,
      };
    }
    throw error;
  }
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

  const offerRefEntries = entries.filter((entry) => {
    if (!entry?.sourceRef) return false;
    if (entry.actionType === 'like_offer') return true;
    return entry.actionType === 'reversal' && entry?.metadata?.trigger === 'unlike_offer';
  });

  const offerIds = Array.from(new Set(offerRefEntries.map((entry) => entry.sourceRef)));
  const offers = offerIds.length
    ? await prisma.offer.findMany({
        where: { id: { in: offerIds } },
        select: { id: true, title: true },
      })
    : [];

  const offerTitleById = offers.reduce((map, offer) => {
    map[offer.id] = offer.title || 'Offer';
    return map;
  }, {});

  const hydratedEntries = entries.map((entry) => {
    const fallbackTitle = entry?.metadata?.offerTitle;
    const title = offerTitleById[entry.sourceRef] || fallbackTitle || null;
    return {
      ...entry,
      sourceLabel: title,
    };
  });

  return {
    entries: hydratedEntries,
    total,
    limit: safeLimit,
    skip: safeSkip,
  };
}

async function getExpirySummary({ userId }) {
  const now = new Date();

  const [wallet, grouped] = await Promise.all([
    prisma.coinWallet.findUnique({
      where: { userId },
      select: { balance: true },
    }),
    prisma.coinLot.groupBy({
      by: ['expiresAt'],
      where: {
        wallet: { userId },
        remainingAmount: { gt: 0 },
        expiresAt: { gt: now },
      },
      _sum: { remainingAmount: true },
      orderBy: { expiresAt: 'asc' },
    }),
  ]);

  const availableBalance = Math.max(Number(wallet?.balance || 0), 0);
  let remainingCap = availableBalance;

  const upcomingExpiries = [];
  for (const row of grouped) {
    if (remainingCap <= 0) {
      break;
    }

    const rawAmount = Math.max(Number(row._sum.remainingAmount || 0), 0);
    const cappedAmount = Math.min(rawAmount, remainingCap);

    if (cappedAmount <= 0) {
      continue;
    }

    upcomingExpiries.push({
      expiresAt: row.expiresAt,
      amount: cappedAmount,
    });

    remainingCap -= cappedAmount;
  }

  const totalExpiring = upcomingExpiries.reduce((sum, row) => sum + row.amount, 0);

  return {
    totalExpiring,
    upcomingExpiries,
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
  reverseLikeRewardOnUnlike,
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
