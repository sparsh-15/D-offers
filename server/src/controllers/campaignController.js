const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const {
  normalizeChannels,
  estimateAudience,
  calculateCost,
  launchCampaign,
  getCampaignAnalytics,
} = require('../services/campaignService');

function ci(value) {
  return String(value || '').trim();
}

function toNumber(value) {
  if (value == null) return null;
  const num = Number(value);
  return Number.isFinite(num) ? num : null;
}

const SUPPORTED_LIVE_CHANNELS = new Set(['app_inbox']);
const ANNOUNCED_CHANNELS = new Set(['app_inbox', 'whatsapp', 'email', 'push_notification']);

function getUnsupportedChannels(channels) {
  if (!Array.isArray(channels)) return [];
  return channels
    .map((channel) => ci(channel).toLowerCase())
    .filter((channel) => channel && !SUPPORTED_LIVE_CHANNELS.has(channel));
}

function hasUnknownChannels(channels) {
  if (!Array.isArray(channels)) return false;
  return channels.some((channel) => {
    const normalized = ci(channel).toLowerCase();
    return normalized && !ANNOUNCED_CHANNELS.has(normalized);
  });
}

function serializeCampaign(campaign, analytics = null) {
  return {
    id: campaign.id,
    shopkeeperId: campaign.shopkeeperId,
    offerId: campaign.offerId,
    title: campaign.title,
    description: campaign.description,
    bannerUrl: campaign.bannerUrl,
    bannerType: campaign.bannerType,
    shopCategory: campaign.shopCategory,
    channels: campaign.channels || [],
    status: campaign.status,
    targetCity: campaign.targetCity,
    targetArea: campaign.targetArea,
    targetPincode: campaign.targetPincode,
    targetState: campaign.targetState,
    targetAgeMin: campaign.targetAgeMin,
    targetAgeMax: campaign.targetAgeMax,
    targetGender: campaign.targetGender,
    estimatedAudience: campaign.estimatedAudience,
    selectedAudienceSize: campaign.selectedAudienceSize,
    actualAudienceReached: campaign.actualAudienceReached,
    whatsappUnitPrice: toNumber(campaign.whatsappUnitPrice),
    inboxUnitPrice: toNumber(campaign.inboxUnitPrice),
    totalCost: toNumber(campaign.totalCost),
    paymentStatus: campaign.paymentStatus,
    paymentMethod: campaign.paymentMethod,
    transactionId: campaign.transactionId,
    scheduledAt: campaign.scheduledAt,
    launchedAt: campaign.launchedAt,
    completedAt: campaign.completedAt,
    createdAt: campaign.createdAt,
    updatedAt: campaign.updatedAt,
    isPanIndia:
      !campaign.targetPincode &&
      !campaign.targetCity &&
      !campaign.targetState,
    channelAvailability: {
      app_inbox: { enabled: true },
      whatsapp: {
        enabled: false,
        reason: 'Coming soon: provider not integrated yet',
      },
      email: {
        enabled: false,
        reason: 'Coming soon: provider not integrated yet',
      },
      push_notification: {
        enabled: false,
        reason: 'Coming soon: device-token push pipeline pending',
      },
    },
    offer: campaign.offer
      ? {
          id: campaign.offer.id,
          title: campaign.offer.title,
          photos: campaign.offer.photos || [],
          status: campaign.offer.status,
        }
      : null,
    analytics,
  };
}

async function requireOwnedOffer(req, offerId) {
  if (!offerId) return null;
  const pgOfferId = (await resolvePgId('offers', offerId)) || offerId;
  const offer = await prisma.offer.findUnique({ where: { id: pgOfferId } });
  if (!offer) {
    const error = new Error('Offer not found');
    error.statusCode = 404;
    throw error;
  }
  const shopkeeperId = await resolvePgId('users', req.user.userId);
  if (String(offer.shopkeeperId) !== String(shopkeeperId)) {
    const error = new Error('Offer does not belong to this shopkeeper');
    error.statusCode = 403;
    throw error;
  }
  return offer;
}

async function estimateAudienceHandler(req, res, next) {
  try {
    const result = await estimateAudience(req.body || {});
    const selectedAudienceSize = Number(req.body?.selectedAudienceSize) || result.count;
    const channels = normalizeChannels(req.body?.channels || ['app_inbox']);
    const cost = await calculateCost(channels, Math.min(selectedAudienceSize, result.count));
    res.status(200).json({
      success: true,
      data: {
        audienceCount: result.count,
        selectedAudienceSize: Math.min(selectedAudienceSize, result.count),
        filters: result.filters,
        pricing: cost.priceSnapshot,
        cost,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function createCampaign(req, res, next) {
  try {
    const title = ci(req.body?.title);
    if (!title) {
      return res.status(400).json({ success: false, message: 'Campaign title is required' });
    }

    const isPanIndia = req.body?.isPanIndia === true;
    const hasLocation =
      isPanIndia || ci(req.body?.targetCity) || ci(req.body?.targetPincode) || ci(req.body?.targetState);
    if (!hasLocation) {
      return res.status(400).json({
        success: false,
        message: 'At least one location filter is required',
      });
    }

    if (hasUnknownChannels(req.body?.channels || [])) {
      return res.status(400).json({
        success: false,
        message: 'Unsupported campaign channel requested',
      });
    }

    const unsupportedChannels = getUnsupportedChannels(req.body?.channels || []);
    if (unsupportedChannels.length) {
      return res.status(400).json({
        success: false,
        message: `These channels are not live yet: ${unsupportedChannels.join(', ')}`,
      });
    }

    const channels = normalizeChannels(req.body?.channels || ['app_inbox']);
    if (!channels.length) {
      return res.status(400).json({ success: false, message: 'Select at least one campaign channel' });
    }

    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const [offer, profile, audience] = await Promise.all([
      requireOwnedOffer(req, req.body?.offerId),
      prisma.shopkeeperProfile.findUnique({ where: { userId: shopkeeperId } }),
      estimateAudience(req.body || {}),
    ]);

    if (!audience.count) {
      return res.status(400).json({
        success: false,
        message: 'No customers match the selected targeting filters',
      });
    }

    const selectedAudienceSize = Math.min(
      Math.max(Number(req.body?.selectedAudienceSize) || audience.count, 1),
      audience.count,
    );
    const cost = await calculateCost(channels, selectedAudienceSize);

    const campaign = await prisma.campaign.create({
      data: {
        shopkeeperId,
        offerId: offer?.id || null,
        title,
        description: ci(req.body?.description) || null,
        bannerUrl: ci(req.body?.bannerUrl) || null,
        bannerType: ci(req.body?.bannerType) || 'template',
        shopCategory: ci(req.body?.shopCategory) || ci(profile?.category) || 'general',
        channels,
        status: 'draft',
        targetCity: audience.filters.targetCity,
        targetArea: audience.filters.targetArea,
        targetPincode: audience.filters.targetPincode,
        targetState: audience.filters.targetState,
        targetAgeMin: audience.filters.targetAgeMin,
        targetAgeMax: audience.filters.targetAgeMax,
        targetGender: audience.filters.targetGender,
        estimatedAudience: audience.count,
        selectedAudienceSize,
        whatsappUnitPrice: cost.priceSnapshot.whatsapp,
        inboxUnitPrice: cost.priceSnapshot.appInbox,
        totalCost: cost.totalCost,
        scheduledAt: req.body?.scheduledAt ? new Date(req.body.scheduledAt) : null,
      },
      include: {
        offer: {
          select: { id: true, title: true, photos: true, status: true },
        },
      },
    });

    res.status(201).json({ success: true, campaign: serializeCampaign(campaign) });
  } catch (error) {
    next(error);
  }
}

async function listCampaigns(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const limitNum = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 100);
    const offsetNum = Math.max(parseInt(req.query.offset, 10) || 0, 0);
    const status = ci(req.query.status).toLowerCase();

    const where = { shopkeeperId };
    if (status) where.status = status;

    const [campaigns, total] = await Promise.all([
      prisma.campaign.findMany({
        where,
        include: {
          offer: { select: { id: true, title: true, photos: true, status: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: offsetNum,
        take: limitNum,
      }),
      prisma.campaign.count({ where }),
    ]);

    res.status(200).json({
      success: true,
      campaigns: campaigns.map((campaign) => serializeCampaign(campaign)),
      pageInfo: {
        offset: offsetNum,
        limit: limitNum,
        total,
        hasMore: offsetNum + campaigns.length < total,
        nextOffset: offsetNum + campaigns.length < total ? offsetNum + campaigns.length : null,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function getCampaignTemplates(req, res, next) {
  try {
    const category = ci(req.query.category);
    const where = { isActive: true };
    if (category) {
      where.OR = [
        { category: { equals: category, mode: 'insensitive' } },
        { category: 'all' },
      ];
    }
    const templates = await prisma.campaignTemplate.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    });
    res.status(200).json({ success: true, templates });
  } catch (error) {
    next(error);
  }
}

async function getCampaign(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const campaignId = (await resolvePgId('campaigns', req.params.id)) || req.params.id;
    const campaign = await prisma.campaign.findUnique({
      where: { id: campaignId },
      include: {
        offer: { select: { id: true, title: true, photos: true, status: true } },
      },
    });
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }
    if (String(campaign.shopkeeperId) !== String(shopkeeperId)) {
      return res.status(403).json({ success: false, message: 'Insufficient permissions' });
    }
    const analytics = await getCampaignAnalytics(campaign.id);
    res.status(200).json({ success: true, campaign: serializeCampaign(campaign, analytics) });
  } catch (error) {
    next(error);
  }
}

async function updateCampaign(req, res, next) {
  try {
        if (hasUnknownChannels(req.body?.channels || [])) {
          return res.status(400).json({
            success: false,
            message: 'Unsupported campaign channel requested',
          });
        }

        const unsupportedChannels = getUnsupportedChannels(req.body?.channels || []);
        if (unsupportedChannels.length) {
          return res.status(400).json({
            success: false,
            message: `These channels are not live yet: ${unsupportedChannels.join(', ')}`,
          });
        }

    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const campaignId = (await resolvePgId('campaigns', req.params.id)) || req.params.id;
    const existing = await prisma.campaign.findUnique({ where: { id: campaignId } });
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }
    if (String(existing.shopkeeperId) !== String(shopkeeperId)) {
      return res.status(403).json({ success: false, message: 'Insufficient permissions' });
    }
    if (existing.status !== 'draft') {
      return res.status(400).json({ success: false, message: 'Only draft campaigns can be edited' });
    }

    const audience = await estimateAudience({
      ...existing,
      ...req.body,
    });
    if (!audience.count) {
      return res.status(400).json({ success: false, message: 'No customers match the selected targeting filters' });
    }
    const channels = normalizeChannels(req.body?.channels || existing.channels);
    const selectedAudienceSize = Math.min(
      Math.max(Number(req.body?.selectedAudienceSize) || existing.selectedAudienceSize || audience.count, 1),
      audience.count,
    );
    const cost = await calculateCost(channels, selectedAudienceSize);

    const offer = await requireOwnedOffer(req, req.body?.offerId || existing.offerId);
    const updated = await prisma.campaign.update({
      where: { id: existing.id },
      data: {
        title: req.body?.title != null ? ci(req.body.title) : existing.title,
        description: req.body?.description != null ? ci(req.body.description) || null : existing.description,
        bannerUrl: req.body?.bannerUrl != null ? ci(req.body.bannerUrl) || null : existing.bannerUrl,
        bannerType: req.body?.bannerType != null ? ci(req.body.bannerType) || 'template' : existing.bannerType,
        channels,
        offerId: offer?.id || null,
        targetCity: audience.filters.targetCity,
        targetArea: audience.filters.targetArea,
        targetPincode: audience.filters.targetPincode,
        targetState: audience.filters.targetState,
        targetAgeMin: audience.filters.targetAgeMin,
        targetAgeMax: audience.filters.targetAgeMax,
        targetGender: audience.filters.targetGender,
        estimatedAudience: audience.count,
        selectedAudienceSize,
        whatsappUnitPrice: cost.priceSnapshot.whatsapp,
        inboxUnitPrice: cost.priceSnapshot.appInbox,
        totalCost: cost.totalCost,
      },
      include: {
        offer: { select: { id: true, title: true, photos: true, status: true } },
      },
    });

    res.status(200).json({ success: true, campaign: serializeCampaign(updated) });
  } catch (error) {
    next(error);
  }
}

async function payCampaign(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const campaignId = (await resolvePgId('campaigns', req.params.id)) || req.params.id;
    const campaign = await prisma.campaign.findUnique({ where: { id: campaignId } });
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }
    if (String(campaign.shopkeeperId) !== String(shopkeeperId)) {
      return res.status(403).json({ success: false, message: 'Insufficient permissions' });
    }
    if (!['draft', 'pending_payment'].includes(campaign.status)) {
      return res.status(400).json({ success: false, message: 'Campaign cannot be paid in its current state' });
    }

    const now = new Date();
    const hasFutureSchedule = campaign.scheduledAt && new Date(campaign.scheduledAt) > now;

    const paidCampaign = await prisma.campaign.update({
      where: { id: campaign.id },
      data: {
        paymentStatus: 'paid',
        paymentMethod: req.body?.paymentMethod || 'upi',
        transactionId: ci(req.body?.transactionId) || null,
        status: hasFutureSchedule ? 'queued' : 'paid',
      },
      include: {
        offer: { select: { id: true, title: true, photos: true, status: true } },
      },
    });

    if (hasFutureSchedule) {
      const analytics = await getCampaignAnalytics(campaign.id);
      return res.status(200).json({
        success: true,
        campaign: serializeCampaign(paidCampaign, analytics),
        message: 'Campaign payment received and queued for scheduled launch.',
      });
    }

    const launched = await launchCampaign(campaign.id);
    const analytics = await getCampaignAnalytics(campaign.id);
    res.status(200).json({ success: true, campaign: serializeCampaign(launched, analytics) });
  } catch (error) {
    next(error);
  }
}

async function cancelCampaign(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const campaignId = (await resolvePgId('campaigns', req.params.id)) || req.params.id;
    const campaign = await prisma.campaign.findUnique({ where: { id: campaignId } });
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }
    if (String(campaign.shopkeeperId) !== String(shopkeeperId)) {
      return res.status(403).json({ success: false, message: 'Insufficient permissions' });
    }
    if (!['draft', 'pending_payment', 'paid', 'queued'].includes(campaign.status)) {
      return res.status(400).json({ success: false, message: 'Campaign cannot be cancelled now' });
    }

    const updated = await prisma.campaign.update({
      where: { id: campaign.id },
      data: { status: 'cancelled' },
    });
    res.status(200).json({ success: true, campaign: serializeCampaign(updated) });
  } catch (error) {
    next(error);
  }
}

async function deleteCampaign(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const campaignId = (await resolvePgId('campaigns', req.params.id)) || req.params.id;
    const campaign = await prisma.campaign.findUnique({ where: { id: campaignId } });
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }
    if (String(campaign.shopkeeperId) !== String(shopkeeperId)) {
      return res.status(403).json({ success: false, message: 'Insufficient permissions' });
    }
    if (campaign.status !== 'draft') {
      return res.status(400).json({ success: false, message: 'Only draft campaigns can be deleted' });
    }
    await prisma.campaign.delete({ where: { id: campaign.id } });
    res.status(200).json({ success: true, message: 'Campaign deleted' });
  } catch (error) {
    next(error);
  }
}

async function listInbox(req, res, next) {
  try {
    const customerId = await resolvePgId('users', req.user.userId);
    const limitNum = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 100);
    const offsetNum = Math.max(parseInt(req.query.offset, 10) || 0, 0);

    const [messages, total] = await Promise.all([
      prisma.inboxMessage.findMany({
        where: { customerId },
        include: {
          shopkeeper: {
            select: {
              id: true,
              name: true,
            },
          },
          campaign: {
            select: {
              id: true,
              status: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: offsetNum,
        take: limitNum,
      }),
      prisma.inboxMessage.count({ where: { customerId } }),
    ]);

    res.status(200).json({
      success: true,
      messages: messages.map((message) => ({
        id: message.id,
        customerId: message.customerId,
        campaignId: message.campaignId,
        shopkeeperId: message.shopkeeperId,
        title: message.title,
        body: message.body,
        bannerUrl: message.bannerUrl,
        offerId: message.offerId,
        isRead: message.isRead,
        readAt: message.readAt,
        createdAt: message.createdAt,
        shopkeeperName: message.shopkeeper?.name || 'Nearby shop',
        campaignStatus: message.campaign?.status || null,
      })),
      pageInfo: {
        offset: offsetNum,
        limit: limitNum,
        total,
        hasMore: offsetNum + messages.length < total,
        nextOffset: offsetNum + messages.length < total ? offsetNum + messages.length : null,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function getUnreadInboxCount(req, res, next) {
  try {
    const customerId = await resolvePgId('users', req.user.userId);
    const count = await prisma.inboxMessage.count({
      where: {
        customerId,
        isRead: false,
      },
    });
    res.status(200).json({ success: true, count });
  } catch (error) {
    next(error);
  }
}

async function markInboxMessageRead(req, res, next) {
  try {
    const customerId = await resolvePgId('users', req.user.userId);
    const messageId = req.params.id;
    const message = await prisma.inboxMessage.findUnique({ where: { id: messageId } });
    if (!message || String(message.customerId) !== String(customerId)) {
      return res.status(404).json({ success: false, message: 'Inbox message not found' });
    }

    const now = new Date();
    const updated = await prisma.inboxMessage.update({
      where: { id: message.id },
      data: {
        isRead: true,
        readAt: message.readAt || now,
      },
    });

    if (message.campaignId) {
      await prisma.campaignDelivery.updateMany({
        where: {
          campaignId: message.campaignId,
          customerId,
          channel: 'app_inbox',
          status: { in: ['delivered', 'sent'] },
        },
        data: {
          status: 'opened',
          openedAt: now,
        },
      });
    }

    res.status(200).json({ success: true, message: updated });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  estimateAudienceHandler,
  createCampaign,
  listCampaigns,
  getCampaignTemplates,
  getCampaign,
  updateCampaign,
  payCampaign,
  cancelCampaign,
  deleteCampaign,
  listInbox,
  getUnreadInboxCount,
  markInboxMessageRead,
};