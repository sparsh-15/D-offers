const { prisma } = require('../db/prisma');

const DEFAULT_PRICING = {
  app_inbox: 0.5,
  whatsapp: 1,
};

function ci(value) {
  return String(value || '').trim();
}

function normalizeChannels(channels) {
  const allowed = new Set(['app_inbox']);
  if (!Array.isArray(channels)) return [];
  return Array.from(
    new Set(
      channels
        .map((channel) => ci(channel).toLowerCase())
        .filter((channel) => allowed.has(channel)),
    ),
  );
}

function normalizeFilters(input = {}) {
  const ageMin = Number.isFinite(Number(input.targetAgeMin))
    ? Number(input.targetAgeMin)
    : null;
  const ageMax = Number.isFinite(Number(input.targetAgeMax))
    ? Number(input.targetAgeMax)
    : null;

  return {
    targetCity: ci(input.targetCity) || null,
    targetArea: ci(input.targetArea) || null,
    targetPincode: ci(input.targetPincode) || null,
    targetState: ci(input.targetState) || null,
    isPanIndia: input.isPanIndia === true,
    targetGender: ci(input.targetGender).toLowerCase() || null,
    targetAgeMin: ageMin,
    targetAgeMax: ageMax,
  };
}

function buildAudienceWhere(filters) {
  const where = {
    role: 'customer',
    isActive: true,
    approvalStatus: 'approved',
  };

  if (!filters.isPanIndia) {
    if (filters.targetPincode) {
      where.pincode = filters.targetPincode;
    } else if (filters.targetCity) {
      where.city = { equals: filters.targetCity, mode: 'insensitive' };
    } else if (filters.targetState) {
      where.state = { equals: filters.targetState, mode: 'insensitive' };
    }
  }

  if (filters.targetArea) {
    where.address = { contains: filters.targetArea, mode: 'insensitive' };
  }

  if (filters.targetGender && filters.targetGender !== 'all') {
    where.gender = { equals: filters.targetGender, mode: 'insensitive' };
  }

  return where;
}

function getAge(dateOfBirth) {
  if (!dateOfBirth) return null;
  const dob = new Date(dateOfBirth);
  if (Number.isNaN(dob.getTime())) return null;
  const today = new Date();
  let age = today.getFullYear() - dob.getFullYear();
  const monthDelta = today.getMonth() - dob.getMonth();
  if (monthDelta < 0 || (monthDelta === 0 && today.getDate() < dob.getDate())) {
    age -= 1;
  }
  return age;
}

function matchesAge(user, filters) {
  if (filters.targetAgeMin == null && filters.targetAgeMax == null) {
    return true;
  }
  const age = getAge(user.dob);
  if (age == null) return false;
  if (filters.targetAgeMin != null && age < filters.targetAgeMin) return false;
  if (filters.targetAgeMax != null && age > filters.targetAgeMax) return false;
  return true;
}

async function findMatchingCustomers(filters, options = {}) {
  const normalized = normalizeFilters(filters);
  const users = await prisma.user.findMany({
    where: buildAudienceWhere(normalized),
    select: {
      id: true,
      dob: true,
    },
    orderBy: { createdAt: 'desc' },
  });

  const matched = users.filter((user) => matchesAge(user, normalized));
  if (options.limit != null) {
    return matched.slice(0, Math.max(options.limit, 0));
  }
  return matched;
}

async function estimateAudience(filters) {
  const normalized = normalizeFilters(filters);
  const customers = await findMatchingCustomers(normalized);
  return {
    count: customers.length,
    filters: normalized,
  };
}

async function getPricingMap() {
  const rows = await prisma.campaignPricing.findMany({
    where: { isActive: true },
  });
  const pricing = { ...DEFAULT_PRICING };
  rows.forEach((row) => {
    pricing[row.channel] = Number(row.pricePerMessage);
  });
  return pricing;
}

async function calculateCost(channels, audienceSize) {
  const normalizedChannels = normalizeChannels(channels);
  const safeAudienceSize = Math.max(Number(audienceSize) || 0, 0);
  const pricing = await getPricingMap();
  const breakdown = {
    whatsappCost: 0,
    inboxCost: 0,
    totalCost: 0,
    priceSnapshot: {
      whatsapp: pricing.whatsapp,
      appInbox: pricing.app_inbox,
    },
  };

  if (normalizedChannels.includes('whatsapp')) {
    breakdown.whatsappCost = safeAudienceSize * pricing.whatsapp;
  }
  if (normalizedChannels.includes('app_inbox')) {
    breakdown.inboxCost = safeAudienceSize * pricing.app_inbox;
  }
  breakdown.totalCost = breakdown.whatsappCost + breakdown.inboxCost;
  return breakdown;
}

async function launchCampaign(campaignId) {
  const campaign = await prisma.campaign.findUnique({
    where: { id: campaignId },
  });
  if (!campaign) {
    const error = new Error('Campaign not found');
    error.statusCode = 404;
    throw error;
  }
  if (campaign.paymentStatus !== 'paid') {
    const error = new Error('Campaign payment is not complete');
    error.statusCode = 400;
    throw error;
  }

  if (campaign.launchedAt || ['sending', 'completed', 'queued'].includes(campaign.status)) {
    return campaign;
  }

  const channels = normalizeChannels(campaign.channels);
  await prisma.campaign.update({
    where: { id: campaignId },
    data: {
      status: 'sending',
      launchedAt: new Date(),
    },
  });

  const matchedCustomers = await findMatchingCustomers(campaign, {
    limit: campaign.selectedAudienceSize || campaign.estimatedAudience,
  });
  const customerIds = matchedCustomers.map((customer) => customer.id);

  if (!customerIds.length) {
    const completed = await prisma.campaign.update({
      where: { id: campaignId },
      data: {
        status: 'completed',
        actualAudienceReached: 0,
        completedAt: new Date(),
      },
    });
    return completed;
  }

  const now = new Date();
  const appInboxEnabled = channels.includes('app_inbox');
  const whatsappEnabled = channels.includes('whatsapp');

  if (appInboxEnabled) {
    await prisma.campaignDelivery.createMany({
      data: customerIds.map((customerId) => ({
        campaignId: campaign.id,
        customerId,
        channel: 'app_inbox',
        status: 'delivered',
        sentAt: now,
        deliveredAt: now,
      })),
      skipDuplicates: true,
    });

    await prisma.inboxMessage.createMany({
      data: customerIds.map((customerId) => ({
        customerId,
        campaignId: campaign.id,
        shopkeeperId: campaign.shopkeeperId,
        title: campaign.title,
        body: campaign.description || 'New campaign from a nearby shop.',
        bannerUrl: campaign.bannerUrl,
        offerId: campaign.offerId,
      })),
      skipDuplicates: false,
    });
  }

  if (whatsappEnabled) {
    await prisma.campaignDelivery.createMany({
      data: customerIds.map((customerId) => ({
        campaignId: campaign.id,
        customerId,
        channel: 'whatsapp',
        status: 'pending',
        errorMessage: 'WhatsApp delivery is not enabled yet.',
      })),
      skipDuplicates: true,
    });
  }

  const finalStatus = appInboxEnabled ? 'completed' : 'queued';
  return prisma.campaign.update({
    where: { id: campaign.id },
    data: {
      status: finalStatus,
      actualAudienceReached: appInboxEnabled ? customerIds.length : 0,
      completedAt: appInboxEnabled ? now : null,
    },
  });
}

async function getCampaignAnalytics(campaignId) {
  const grouped = await prisma.campaignDelivery.groupBy({
    by: ['channel', 'status'],
    where: { campaignId },
    _count: { _all: true },
  });

  const summary = {
    totalReached: 0,
    opened: 0,
    clicked: 0,
    failed: 0,
    openRate: 0,
    clickRate: 0,
    channelBreakdown: {},
  };

  grouped.forEach((row) => {
    if (!summary.channelBreakdown[row.channel]) {
      summary.channelBreakdown[row.channel] = {
        delivered: 0,
        opened: 0,
        clicked: 0,
        failed: 0,
        pending: 0,
      };
    }
    const bucket = summary.channelBreakdown[row.channel];
    bucket[row.status] = row._count._all;
    if (row.status === 'delivered' || row.status === 'opened' || row.status === 'clicked') {
      summary.totalReached += row._count._all;
    }
    if (row.status === 'opened') summary.opened += row._count._all;
    if (row.status === 'clicked') summary.clicked += row._count._all;
    if (row.status === 'failed') summary.failed += row._count._all;
  });

  if (summary.totalReached > 0) {
    summary.openRate = Number(((summary.opened / summary.totalReached) * 100).toFixed(2));
    summary.clickRate = Number(((summary.clicked / summary.totalReached) * 100).toFixed(2));
  }

  return summary;
}

module.exports = {
  normalizeChannels,
  normalizeFilters,
  estimateAudience,
  calculateCost,
  launchCampaign,
  getCampaignAnalytics,
};