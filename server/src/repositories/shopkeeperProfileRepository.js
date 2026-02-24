const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

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
    category: profile.category,
    description: profile.description,
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt,
  };
}

async function upsertByUserId(userId, update) {
  const pgUserId = await resolvePgId('users', userId);
  if (!pgUserId) return null;
  const row = await prisma.shopkeeperProfile.upsert({
    where: { userId: pgUserId },
    create: {
      userId: pgUserId,
      shopName: update.shopName,
      address: update.address || null,
      pincode: update.pincode || null,
      city: update.city || null,
      category: update.category || null,
      description: update.description || null,
    },
    update: {
      shopName: update.shopName,
      address: update.address || null,
      pincode: update.pincode || null,
      city: update.city || null,
      category: update.category || null,
      description: update.description || null,
    },
  });
  return toProfileShape(row);
}

module.exports = { upsertByUserId };
