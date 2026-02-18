/**
 * Cron job to automatically expire subscriptions
 * Run this daily to check and expire old subscriptions
 */

const Subscription = require('../models/Subscription');

async function checkAndExpireSubscriptions() {
  try {
    console.log('[CRON] Running subscription expiry check...');

    const result = await Subscription.expireOldSubscriptions();

    console.log(`[CRON] Expired ${result.modifiedCount} subscriptions`);

    // Get subscriptions expiring in next 7 days for notifications
    const now = new Date();
    const sevenDaysFromNow = new Date(now);
    sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

    const expiringSoon = await Subscription.find({
      status: 'active',
      endDate: {
        $gte: now,
        $lte: sevenDaysFromNow,
      },
    })
      .populate('shopkeeperId', 'name phone email')
      .lean();

    console.log(`[CRON] Found ${expiringSoon.length} subscriptions expiring soon`);

    // TODO: Send notifications to shopkeepers
    // This can be implemented with email/SMS service

    return {
      expired: result.modifiedCount,
      expiringSoon: expiringSoon.length,
    };
  } catch (error) {
    console.error('[CRON] Error in subscription expiry check:', error);
    throw error;
  }
}

// If running as standalone script
if (require.main === module) {
  require('dotenv').config();
  const mongoose = require('mongoose');
  const config = require('../config');

  mongoose
    .connect(config.mongodbUri)
    .then(async () => {
      console.log('Connected to MongoDB');
      await checkAndExpireSubscriptions();
      await mongoose.connection.close();
      console.log('Disconnected from MongoDB');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Error:', error);
      process.exit(1);
    });
}

module.exports = { checkAndExpireSubscriptions };
