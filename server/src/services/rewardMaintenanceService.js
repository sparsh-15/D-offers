const { prisma } = require('../db/prisma');

let expiryTimer = null;
let reconcileTimer = null;

function buildExpiryIdempotencyKey(lot) {
  return `expiry:${lot.id}:${new Date(lot.expiresAt).getTime()}`;
}

async function expireCoinLotsBatch(batchSize = 200) {
  const now = new Date();
  const dueLots = await prisma.coinLot.findMany({
    where: {
      remainingAmount: { gt: 0 },
      expiresAt: { lte: now },
    },
    select: {
      id: true,
      walletId: true,
      remainingAmount: true,
      expiresAt: true,
      wallet: {
        select: {
          userId: true,
          userType: true,
        },
      },
    },
    orderBy: { expiresAt: 'asc' },
    take: batchSize,
  });

  let processed = 0;
  let debitedCoins = 0;

  for (const dueLot of dueLots) {
    await prisma.$transaction(async (tx) => {
      const lot = await tx.coinLot.findUnique({
        where: { id: dueLot.id },
        select: {
          id: true,
          walletId: true,
          remainingAmount: true,
          expiresAt: true,
          wallet: {
            select: {
              userId: true,
              userType: true,
            },
          },
        },
      });

      if (!lot || lot.remainingAmount <= 0 || new Date(lot.expiresAt) > now) {
        return;
      }

      const amountToExpire = Number(lot.remainingAmount);
      const idempotencyKey = buildExpiryIdempotencyKey(lot);
      const existingExpiry = await tx.coinLedgerEntry.findUnique({
        where: { idempotencyKey },
      });

      if (!existingExpiry) {
        await tx.coinLedgerEntry.create({
          data: {
            walletId: lot.walletId,
            userId: lot.wallet.userId,
            userType: lot.wallet.userType,
            direction: 'debit',
            amount: amountToExpire,
            actionType: 'expiry',
            sourceRef: lot.id,
            idempotencyKey,
            metadata: {
              reason: 'lot_expired',
              lotId: lot.id,
            },
          },
        });
      }

      await tx.coinWallet.update({
        where: { id: lot.walletId },
        data: {
          balance: { decrement: amountToExpire },
        },
      });

      await tx.coinLot.update({
        where: { id: lot.id },
        data: { remainingAmount: 0 },
      });

      processed += 1;
      debitedCoins += amountToExpire;
    });
  }

  return {
    scanned: dueLots.length,
    processed,
    debitedCoins,
  };
}

async function reconcileCoinWalletsBatch(batchSize = 200) {
  const wallets = await prisma.coinWallet.findMany({
    select: {
      id: true,
      userId: true,
      balance: true,
    },
    orderBy: { updatedAt: 'asc' },
    take: batchSize,
  });

  let mismatchedWallets = 0;
  let autoHealedWallets = 0;

  for (const wallet of wallets) {
    const [credits, debits] = await Promise.all([
      prisma.coinLedgerEntry.aggregate({
        _sum: { amount: true },
        where: {
          walletId: wallet.id,
          direction: 'credit',
        },
      }),
      prisma.coinLedgerEntry.aggregate({
        _sum: { amount: true },
        where: {
          walletId: wallet.id,
          direction: 'debit',
        },
      }),
    ]);

    const expected = Number(credits._sum.amount || 0) - Number(debits._sum.amount || 0);
    const current = Number(wallet.balance || 0);

    if (expected !== current) {
      mismatchedWallets += 1;

      await prisma.coinWallet.update({
        where: { id: wallet.id },
        data: {
          balance: expected,
          lastReconciledAt: new Date(),
        },
      });

      autoHealedWallets += 1;
    } else {
      await prisma.coinWallet.update({
        where: { id: wallet.id },
        data: {
          lastReconciledAt: new Date(),
        },
      });
    }
  }

  await prisma.coinReconciliationRun.create({
    data: {
      checkedWallets: wallets.length,
      mismatchedWallets,
      autoHealedWallets,
      metadata: {
        mode: 'scheduled',
      },
    },
  });

  return {
    checkedWallets: wallets.length,
    mismatchedWallets,
    autoHealedWallets,
  };
}

async function runExpiryCycle() {
  try {
    const result = await expireCoinLotsBatch();
    if (result.scanned > 0) {
      console.log('[REWARD_MAINTENANCE] Expiry cycle result:', result);
    }
  } catch (error) {
    console.error('[REWARD_MAINTENANCE] Expiry cycle failed:', error.message);
  }
}

async function runReconciliationCycle() {
  try {
    const result = await reconcileCoinWalletsBatch();
    if (result.checkedWallets > 0) {
      console.log('[REWARD_MAINTENANCE] Reconciliation cycle result:', result);
    }
  } catch (error) {
    console.error('[REWARD_MAINTENANCE] Reconciliation cycle failed:', error.message);
  }
}

function startRewardMaintenanceScheduler({
  expiryIntervalMs = 10 * 60 * 1000,
  reconciliationIntervalMs = 30 * 60 * 1000,
  startupDelayMs = 15000,
} = {}) {
  if (!expiryTimer) {
    expiryTimer = setInterval(() => {
      runExpiryCycle();
    }, expiryIntervalMs);
  }

  if (!reconcileTimer) {
    reconcileTimer = setInterval(() => {
      runReconciliationCycle();
    }, reconciliationIntervalMs);
  }

  setTimeout(() => {
    runExpiryCycle();
    runReconciliationCycle();
  }, startupDelayMs);

  console.log(
    `[REWARD_MAINTENANCE] Started (expiry=${expiryIntervalMs}ms, reconciliation=${reconciliationIntervalMs}ms)`,
  );
}

function stopRewardMaintenanceScheduler() {
  if (expiryTimer) {
    clearInterval(expiryTimer);
    expiryTimer = null;
  }

  if (reconcileTimer) {
    clearInterval(reconcileTimer);
    reconcileTimer = null;
  }

  console.log('[REWARD_MAINTENANCE] Stopped');
}

module.exports = {
  expireCoinLotsBatch,
  reconcileCoinWalletsBatch,
  startRewardMaintenanceScheduler,
  stopRewardMaintenanceScheduler,
};
