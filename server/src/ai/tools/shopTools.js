const { prisma } = require('../../db/prisma');

function ci(value) {
  return String(value || '').trim();
}

/**
 * Find approved shopkeepers (shops) near the user, filtered by
 * pincode / city / state. Returns basic shop info plus location.
 */
async function searchShopsNearby({ params }) {
  const { pincode, city, state, limit = 10 } = params || {};

  const where = {
    role: 'shopkeeper',
    approvalStatus: 'approved',
  };

  if (ci(pincode)) where.pincode = ci(pincode);
  if (ci(city)) {
    where.city = { equals: ci(city), mode: 'insensitive' };
  }
  if (ci(state)) {
    where.state = { equals: ci(state), mode: 'insensitive' };
  }

  const limitNum = Math.min(Math.max(parseInt(limit, 10) || 10, 1), 30);

  const users = await prisma.user.findMany({
    where,
    select: {
      id: true,
      name: true,
      phone: true,
      pincode: true,
      city: true,
      state: true,
    },
    orderBy: { createdAt: 'desc' },
    take: limitNum,
  });

  const profiles = await prisma.shopkeeperProfile.findMany({
    where: { userId: { in: users.map((u) => u.id) } },
    select: { userId: true, shopName: true },
  });
  const shopNameByUserId = {};
  profiles.forEach((p) => {
    shopNameByUserId[p.userId] = p.shopName || null;
  });

  const shops = users.map((u) => ({
    id: u.id,
    name: u.name || '',
    shopName: shopNameByUserId[u.id] || u.name || 'Shop',
    phone: u.phone || null,
    pincode: u.pincode || null,
    city: u.city || null,
    state: u.state || null,
  }));

  return { shops };
}

module.exports = {
  searchShopsNearby,
};

