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
  const user = await prisma.user.findUnique({
    where: { id: pgUserId },
    select: { address: true, pincode: true, city: true },
  });

  const createData = {
    userId: pgUserId,
    shopName: update.shopName,
    address: update.address || user?.address || null,
    pincode: update.pincode || user?.pincode || null,
    city: update.city || user?.city || null,
    category: update.category || null,
    description: update.description || null,
  };

  const updateData = {
    shopName: update.shopName,
    address: update.address || null,
    pincode: update.pincode || null,
    city: update.city || null,
    category: update.category || null,
    description: update.description || null,
  };

  const row = await prisma.shopkeeperProfile.upsert({
    where: { userId: pgUserId },
    create: createData,
    update: updateData,
  });
  return toProfileShape(row);
}

module.exports = { upsertByUserId };
