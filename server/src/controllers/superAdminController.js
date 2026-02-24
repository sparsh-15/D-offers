const { prisma } = require('../db/prisma');
const { logAdminAction } = require('../middleware/roleAuth');
const { resolvePgId } = require('../repositories/idResolver');

async function getDashboardAnalytics(req, res, next) {
  try {
    const users = await prisma.user.groupBy({
      by: ['role', 'isActive'],
      _count: { _all: true },
    });
    const usersByRole = {};
    users.forEach((u) => {
      if (!usersByRole[u.role]) usersByRole[u.role] = { total: 0, active: 0, inactive: 0 };
      usersByRole[u.role].total += u._count._all;
      if (u.isActive) usersByRole[u.role].active += u._count._all;
      else usersByRole[u.role].inactive += u._count._all;
    });
    const totalShops = await prisma.shopkeeperProfile.count();
    const subStats = await prisma.subscription.groupBy({
      by: ['status'],
      _count: { _all: true },
      _sum: { actualPrice: true },
    });
    const recentActivityCount = await prisma.auditLog.count({
      where: { createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
    });
    const byStatus = {};
    subStats.forEach((s) => {
      byStatus[s.status] = { count: s._count._all, revenue: Number(s._sum.actualPrice || 0) };
    });
    const mrr = byStatus.active?.revenue || 0;
    res.json({
      success: true,
      data: { usersByRole, totalShops, subscriptions: { byStatus, mrr }, recentActivityCount },
    });
  } catch (err) {
    next(err);
  }
}

async function getAllUsers(req, res, next) {
  try {
    const { role, isActive, approvalStatus, pincode, search, page = 1, limit = 20 } = req.query;
    const where = {};
    if (role) where.role = role;
    if (isActive !== undefined) where.isActive = isActive === 'true';
    if (approvalStatus) where.approvalStatus = approvalStatus;
    if (pincode) where.pincode = pincode;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { phone: { contains: search, mode: 'insensitive' } },
      ];
    }
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [users, total] = await Promise.all([
      prisma.user.findMany({ where, orderBy: { createdAt: 'desc' }, skip, take: parseInt(limit, 10) }),
      prisma.user.count({ where }),
    ]);
    res.json({ success: true, data: { users, pagination: { total, page: parseInt(page, 10), limit: parseInt(limit, 10), pages: Math.ceil(total / parseInt(limit, 10)) } } });
  } catch (err) {
    next(err);
  }
}

async function getAllShops(req, res, next) {
  try {
    const { subscriptionStatus, pincode, city, category, search, page = 1, limit = 20 } = req.query;
    const userWhere = { role: 'shopkeeper' };
    if (pincode) userWhere.pincode = pincode;
    if (city) userWhere.city = city;
    const users = await prisma.user.findMany({ where: userWhere, select: { id: true } });
    const shopWhere = { userId: { in: users.map((u) => u.id) } };
    if (category) shopWhere.category = category;
    if (search) shopWhere.shopName = { contains: search, mode: 'insensitive' };
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [shops, total] = await Promise.all([
      prisma.shopkeeperProfile.findMany({
        where: shopWhere,
        include: { user: { select: { name: true, phone: true, pincode: true, city: true, isActive: true, approvalStatus: true, createdAt: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.shopkeeperProfile.count({ where: shopWhere }),
    ]);
    const shopsWithSubscription = await Promise.all(
      shops.map(async (shop) => {
        const sub = await prisma.subscription.findFirst({ where: { shopkeeperId: shop.userId }, orderBy: { createdAt: 'desc' } });
        return { ...shop, subscription: sub || null };
      })
    );
    const filtered = subscriptionStatus
      ? shopsWithSubscription.filter((s) => s.subscription?.status === subscriptionStatus)
      : shopsWithSubscription;
    res.json({ success: true, data: { shops: filtered, pagination: { total, page: parseInt(page, 10), limit: parseInt(limit, 10), pages: Math.ceil(total / parseInt(limit, 10)) } } });
  } catch (err) {
    next(err);
  }
}

async function toggleUserStatus(req, res, next) {
  try {
    const { userId } = req.params;
    const { isActive } = req.body;
    if (typeof isActive !== 'boolean') return res.status(400).json({ success: false, message: 'isActive must be a boolean value' });
    const pgUserId = await resolvePgId('users', userId) || userId;
    const user = await prisma.user.findUnique({ where: { id: pgUserId } });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    if (String(user.id) === String(await resolvePgId('users', req.user.userId)) && !isActive) {
      return res.status(400).json({ success: false, message: 'Cannot deactivate your own account' });
    }
    const updated = await prisma.user.update({ where: { id: pgUserId }, data: { isActive } });
    await logAdminAction(req.user.userId, req.user.role, isActive ? 'user_activated' : 'user_deactivated', userId, user.role, { previousStatus: !isActive, newStatus: isActive }, req.ip);
    res.json({ success: true, message: `User ${isActive ? 'activated' : 'deactivated'} successfully`, data: { userId: updated.id, isActive: updated.isActive } });
  } catch (err) {
    next(err);
  }
}

async function updateApprovalStatus(req, res, next) {
  try {
    const { userId } = req.params;
    const { approvalStatus } = req.body;
    if (!['pending', 'approved', 'rejected'].includes(approvalStatus)) return res.status(400).json({ success: false, message: 'Invalid approval status' });
    const pgUserId = await resolvePgId('users', userId) || userId;
    const user = await prisma.user.findUnique({ where: { id: pgUserId } });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    const previousStatus = user.approvalStatus;
    const updated = await prisma.user.update({ where: { id: pgUserId }, data: { approvalStatus } });
    await logAdminAction(req.user.userId, req.user.role, approvalStatus === 'approved' ? 'user_approved' : 'user_rejected', userId, user.role, { previousStatus, newStatus: approvalStatus }, req.ip);
    res.json({ success: true, message: `User ${approvalStatus} successfully`, data: { userId: updated.id, approvalStatus: updated.approvalStatus } });
  } catch (err) {
    next(err);
  }
}

async function getAuditLogs(req, res, next) {
  try {
    const { action, adminId, targetUserId, startDate, endDate, page = 1, limit = 50 } = req.query;
    const where = {};
    if (action) where.action = action;
    if (adminId) where.adminId = (await resolvePgId('users', adminId)) || adminId;
    if (targetUserId) where.targetUserId = (await resolvePgId('users', targetUserId)) || targetUserId;
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = new Date(startDate);
      if (endDate) where.createdAt.lte = new Date(endDate);
    }
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        include: {
          admin: { select: { name: true, phone: true, role: true } },
          targetUser: { select: { name: true, phone: true, role: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.auditLog.count({ where }),
    ]);
    res.json({ success: true, data: { logs, pagination: { total, page: parseInt(page, 10), limit: parseInt(limit, 10), pages: Math.ceil(total / parseInt(limit, 10)) } } });
  } catch (err) {
    next(err);
  }
}

async function getUserDetails(req, res, next) {
  try {
    const pgUserId = await resolvePgId('users', req.params.userId) || req.params.userId;
    const user = await prisma.user.findUnique({ where: { id: pgUserId } });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    let additionalData = {};
    if (user.role === 'shopkeeper') {
      const [profile, subscription] = await Promise.all([
        prisma.shopkeeperProfile.findUnique({ where: { userId: user.id } }),
        prisma.subscription.findFirst({ where: { shopkeeperId: user.id }, orderBy: { createdAt: 'desc' } }),
      ]);
      additionalData = { profile, subscription };
    }
    const recentLogs = await prisma.auditLog.findMany({
      where: { targetUserId: user.id },
      include: { admin: { select: { name: true, phone: true, role: true } } },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
    res.json({ success: true, data: { user, ...additionalData, recentLogs } });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getDashboardAnalytics,
  getAllUsers,
  getAllShops,
  toggleUserStatus,
  updateApprovalStatus,
  getAuditLogs,
  getUserDetails,
};
