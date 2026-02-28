const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');

async function getStats(req, res, next) {
  try {
    const [totalUsers, totalShopkeepers, pendingShopkeepers, activeOffers] =
      await Promise.all([
        prisma.user.count(),
        prisma.user.count({ where: { role: 'shopkeeper' } }),
        prisma.user.count({
          where: { role: 'shopkeeper', approvalStatus: 'pending' },
        }),
        prisma.offer.count({ where: { status: 'active' } }),
      ]);

    res.status(200).json({
      success: true,
      stats: { totalUsers, totalShopkeepers, pendingShopkeepers, activeOffers },
    });
  } catch (err) {
    next(err);
  }
}

function buildUsersWhere(role, state, city, category) {
  const where = {};
  if (role) where.role = role;
  if (state && state.trim()) {
    where.state = { equals: state.trim(), mode: 'insensitive' };
  }
  if (city && city.trim()) {
    where.city = { equals: city.trim(), mode: 'insensitive' };
  }
  if (role === 'shopkeeper' && category && category.trim()) {
    where.shopkeeperProfile = { category: category.trim() };
  }
  return where;
}

async function listUsers(req, res, next) {
  try {
    const { role, limit, skip, state, city, category } = req.query;
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);
    const where = buildUsersWhere(role, state, city, category);

    const usersRaw = await prisma.user.findMany({
      where,
      select: {
        id: true,
        name: true,
        phone: true,
        role: true,
        pincode: true,
        city: true,
        state: true,
        address: true,
        approvalStatus: true,
        isActive: true,
        createdAt: true,
        onboardingStatus: {
          select: {
            businessProfileCompleted: true,
            subscriptionActivated: true,
            onboardingCompleted: true,
          },
        },
        shopkeeperProfile: {
          select: { category: true },
        },
        subscriptions: {
          where: { status: 'active' },
          select: { id: true, status: true },
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: skipNum,
      take: limitNum,
    });

    const users = usersRaw.map((user) => {
      const hasActiveSubscription = (user.subscriptions || []).length > 0;
      const onboarding = user.onboardingStatus;

      let statusLabel = 'active';

      if (user.role === 'shopkeeper') {
        if (hasActiveSubscription || onboarding?.subscriptionActivated) {
          statusLabel = 'subscribed';
        } else if (
          onboarding?.businessProfileCompleted ||
          onboarding?.onboardingCompleted
        ) {
          statusLabel = 'active';
        } else {
          statusLabel = 'setup_pending';
        }
      } else {
        statusLabel = user.isActive ? 'active' : 'inactive';
      }

      const category =
        user.shopkeeperProfile?.category ?? '';
      return {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        pincode: user.pincode,
        city: user.city,
        state: user.state,
        approvalStatus: user.approvalStatus,
        createdAt: user.createdAt,
        statusLabel,
        category,
      };
    });

    res.status(200).json({ success: true, users });
  } catch (err) {
    next(err);
  }
}

async function listShopkeepers(req, res, next) {
  try {
    const { status } = req.query;
    const where = { role: 'shopkeeper' };
    if (status) where.approvalStatus = status;
    const users = await prisma.user.findMany({
      where,
      select: {
        id: true,
        name: true,
        phone: true,
        pincode: true,
        city: true,
        state: true,
        address: true,
        approvalStatus: true,
        createdAt: true,
        updatedAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    res.status(200).json({ success: true, shopkeepers: users });
  } catch (err) {
    next(err);
  }
}

async function approveShopkeeper(req, res, next) {
  try {
    const pgId = await resolvePgId('users', req.params.id);
    if (!pgId) return res.status(400).json({ success: false, message: 'Invalid user id' });
    const user = await prisma.user.findFirst({ where: { id: pgId, role: 'shopkeeper' } });
    if (!user) return res.status(404).json({ success: false, message: 'Shopkeeper not found' });
    const updated = await prisma.user.update({
      where: { id: pgId },
      data: { approvalStatus: 'approved' },
      select: { id: true, phone: true, approvalStatus: true },
    });
    res.status(200).json({ success: true, message: 'Shopkeeper approved', shopkeeper: updated });
  } catch (err) {
    next(err);
  }
}

async function rejectShopkeeper(req, res, next) {
  try {
    const pgId = await resolvePgId('users', req.params.id);
    if (!pgId) return res.status(400).json({ success: false, message: 'Invalid user id' });
    const user = await prisma.user.findFirst({ where: { id: pgId, role: 'shopkeeper' } });
    if (!user) return res.status(404).json({ success: false, message: 'Shopkeeper not found' });
    const updated = await prisma.user.update({
      where: { id: pgId },
      data: { approvalStatus: 'rejected' },
      select: { id: true, phone: true, approvalStatus: true },
    });
    res.status(200).json({ success: true, message: 'Shopkeeper rejected', shopkeeper: updated });
  } catch (err) {
    next(err);
  }
}

async function getUsersStats(req, res, next) {
  try {
    const { role, state, city, category } = req.query;
    const where = buildUsersWhere(role, state, city, category);

    // Subscribed: only count when role filter includes shopkeepers
    const countSubscribed =
      role === 'customer' || role === 'admin'
        ? 0
        : await prisma.user.count({
            where: {
              ...where,
              role: 'shopkeeper',
              subscriptions: { some: { status: 'active' } },
            },
          });

    // Active (customers): only count when role filter includes customers
    const countActive =
      role === 'shopkeeper'
        ? 0
        : await prisma.user.count({
            where: {
              ...where,
              role: 'customer',
              isActive: true,
            },
          });

    const totalUsers = await prisma.user.count({ where });

    res.status(200).json({
      success: true,
      stats: {
        totalUsers,
        subscribedUsers: countSubscribed,
        activeUsers: countActive,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getLocationOptions(req, res, next) {
  try {
    const users = await prisma.user.findMany({
      where: {
        OR: [{ state: { not: '' } }, { city: { not: '' } }],
      },
      select: { state: true, city: true },
    });

    const statesSet = new Set();
    const citiesByState = {};
    const allCitiesSet = new Set();

    for (const u of users) {
      const stateVal = (u.state || '').trim();
      const cityVal = (u.city || '').trim();
      if (stateVal) {
        statesSet.add(stateVal);
        if (!citiesByState[stateVal]) citiesByState[stateVal] = new Set();
        if (cityVal) citiesByState[stateVal].add(cityVal);
      }
      if (cityVal) allCitiesSet.add(cityVal);
    }

    const states = Array.from(statesSet).sort();
    const citiesByStateObj = {};
    for (const [s, cities] of Object.entries(citiesByState)) {
      citiesByStateObj[s] = Array.from(cities).sort();
    }
    const allCities = Array.from(allCitiesSet).sort();

    res.status(200).json({
      success: true,
      data: { states, citiesByState: citiesByStateObj, allCities },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getStats,
  listUsers,
  listShopkeepers,
  approveShopkeeper,
  rejectShopkeeper,
  getUsersStats,
  getLocationOptions,
};
