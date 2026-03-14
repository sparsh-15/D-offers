const { prisma } = require('../db/prisma');
const { launchCampaign } = require('./campaignService');

let schedulerTimer = null;

async function dispatchDueCampaigns() {
  const now = new Date();
  try {
    const dueCampaigns = await prisma.campaign.findMany({
      where: {
        paymentStatus: 'paid',
        status: { in: ['paid', 'queued'] },
        scheduledAt: { lte: now },
      },
      select: { id: true },
      orderBy: { scheduledAt: 'asc' },
      take: 50,
    });

    for (const campaign of dueCampaigns) {
      try {
        await launchCampaign(campaign.id);
      } catch (error) {
        console.error(`[CAMPAIGN_SCHEDULER] Launch failed for ${campaign.id}:`, error.message);
      }
    }
  } catch (error) {
    console.error('[CAMPAIGN_SCHEDULER] Dispatch error:', error.message);
  }
}

function startCampaignScheduler(intervalMs = 60 * 1000) {
  if (schedulerTimer) return;

  schedulerTimer = setInterval(() => {
    dispatchDueCampaigns();
  }, intervalMs);

  // Trigger one cycle shortly after startup.
  setTimeout(() => {
    dispatchDueCampaigns();
  }, 5000);

  console.log(`[CAMPAIGN_SCHEDULER] Started with interval ${intervalMs}ms`);
}

function stopCampaignScheduler() {
  if (!schedulerTimer) return;
  clearInterval(schedulerTimer);
  schedulerTimer = null;
  console.log('[CAMPAIGN_SCHEDULER] Stopped');
}

module.exports = {
  dispatchDueCampaigns,
  startCampaignScheduler,
  stopCampaignScheduler,
};
