const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

function hasOwn(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

function toProfileShape(profile) {
  if (!profile) return null;
  return {
    id: profile.id,
    _id: profile.id,
    userId: profile.userId,
    shopName: profile.shopName,
    address: profile.address,
    pincode: profile.pincode,
    city: profile.city,
    latitude: profile.latitude?.toString() ?? null,
    longitude: profile.longitude?.toString() ?? null,
    category: profile.category,
    description: profile.description,
    shopImages: profile.shopImages || [],
    logoUrl: profile.logoUrl,
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt,
  };
}

async function upsertByUserId(userId, update) {
  const pgUserId = await resolvePgId('users', userId);
  if (!pgUserId) return null;
  const user = await prisma.user.findUnique({
    where: { id: pgUserId },
    select: { address: true, pincode: true, city: true, onboardedByLeadId: true },
  });

  // Resolve the onboarding agent from the lead that created this shopkeeper.
  // Only applied on CREATE so existing attribution is never overwritten.
  let onboardedBy = null;
  if (user?.onboardedByLeadId) {
    const lead = await prisma.shopLead.findUnique({
      where: { id: user.onboardedByLeadId },
      select: { ssaId: true, csaId: true },
    });
    onboardedBy = lead?.ssaId || lead?.csaId || null;
  }

  const createData = {
    userId: pgUserId,
    shopName: update.shopName,
    address: update.address || user?.address || null,
    pincode: update.pincode || user?.pincode || null,
    city: update.city || user?.city || null,
    ...(hasOwn(update, 'latitude') ? { latitude: update.latitude } : {}),
    ...(hasOwn(update, 'longitude') ? { longitude: update.longitude } : {}),
    category: update.category || null,
    description: update.description || null,
    shopImages: update.shopImages || [],
    logoUrl: update.logoUrl || null,
    ...(onboardedBy ? { onboardedBy } : {}),
  };

  const updateData = {
    shopName: update.shopName,
    address: update.address || null,
    pincode: update.pincode || null,
    city: update.city || null,
    ...(hasOwn(update, 'latitude') ? { latitude: update.latitude } : {}),
    ...(hasOwn(update, 'longitude') ? { longitude: update.longitude } : {}),
    category: update.category || null,
    description: update.description || null,
    ...(update.shopImages !== undefined ? { shopImages: update.shopImages } : {}),
    ...(update.logoUrl !== undefined ? { logoUrl: update.logoUrl || null } : {}),
  };

  const row = await prisma.shopkeeperProfile.upsert({
    where: { userId: pgUserId },
    create: createData,
    update: updateData,
  });
  return toProfileShape(row);
}

module.exports = { upsertByUserId };
