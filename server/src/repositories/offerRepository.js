const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

async function createOffer(payload) {
  const shopkeeperId = await resolvePgId('users', payload.shopkeeperId);
  if (!shopkeeperId) return null;
  const offer = await prisma.offer.create({
    data: {
      shopkeeperId,
      title: payload.title,
      description: payload.description || null,
      photos: payload.photos || [],
      termsAndConditions: payload.termsAndConditions || null,
      category: payload.category || null,
      discountType: payload.discountType || 'percentage',
      discountValue:
        payload.discountValue !== undefined && payload.discountValue !== null
          ? payload.discountValue
          : null,
      validFrom: payload.validFrom || null,
      validTo: payload.validTo || null,
      status: payload.status || 'active',
    },
  });
  return offer;
}

async function updateOffer(offerId, changes) {
  const pgOfferId = await resolvePgId('offers', offerId) || offerId;
  return prisma.offer.update({
    where: { id: pgOfferId },
    data: changes,
  });
}

async function deleteOffer(offerId) {
  const pgOfferId = await resolvePgId('offers', offerId) || offerId;
  await prisma.offer.delete({ where: { id: pgOfferId } });
}

async function toggleLike(offerId, userId, isCurrentlyLiked) {
  const pgOfferId = await resolvePgId('offers', offerId) || offerId;
  const pgUserId = await resolvePgId('users', userId) || userId;
  if (isCurrentlyLiked) {
    await prisma.offerLike.deleteMany({ where: { offerId: pgOfferId, userId: pgUserId } });
  } else {
    await prisma.offerLike.create({ data: { offerId: pgOfferId, userId: pgUserId } }).catch(() => null);
  }
  const likeCount = await prisma.offerLike.count({ where: { offerId: pgOfferId } });
  await prisma.offer.update({ where: { id: pgOfferId }, data: { likesCount: likeCount } });
  return likeCount;
}

module.exports = {
  createOffer,
  updateOffer,
  deleteOffer,
  toggleLike,
};
