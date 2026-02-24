const { prisma } = require('../db/prisma');
const couponRepository = require('../repositories/couponRepository');
const userRepository = require('../repositories/userRepository');
const { resolvePgId } = require('../repositories/idResolver');

const MAX_PERCENTAGE_DISCOUNT = 99;
const DEFAULT_AGENT_MAX_DISCOUNT = 50;

function normalizeAgentMaxDiscount(value) {
  if (value === undefined || value === null || value === '') return DEFAULT_AGENT_MAX_DISCOUNT;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) return null;
  if (parsed < 1 || parsed > MAX_PERCENTAGE_DISCOUNT) return null;
  return parsed;
}

function sanitizeNameChunk(value) {
  return String(value || '').replace(/[^A-Za-z]/g, '').toUpperCase();
}

function toTwoLetters(value, fallback) {
  const cleaned = sanitizeNameChunk(value);
  return (cleaned.slice(0, 2) || fallback).padEnd(2, 'X');
}

function generateRandomToken(length = 2) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let out = '';
  for (let i = 0; i < length; i++) {
    out += chars[Math.floor(Math.random() * chars.length)];
  }
  return out;
}

async function generateCouponCodeForAgent(agent, discountSuffix) {
  const tokens = String(agent.name || '').trim().split(/\s+/).filter(Boolean);
  const first = toTwoLetters(tokens[0], 'AG');
  const last = toTwoLetters(tokens.length > 1 ? tokens[tokens.length - 1] : tokens[0], 'NT');
  const agentKey = String(agent.id || '')
    .replace(/[^A-Za-z0-9]/g, '')
    .toUpperCase()
    .slice(-4)
    .padStart(4, '0');

  for (let attempt = 0; attempt < 20; attempt++) {
    const random = generateRandomToken(2);
    const code = `${first}${last}${agentKey}${random}${discountSuffix}`;
    const exists = await prisma.coupon.findUnique({ where: { code } });
    if (!exists) return code;
  }

  throw new Error('Failed to generate unique coupon code. Please retry.');
}

async function getSSAList(req, res, next) {
  try {
    const { page = 1, limit = 20, search, isActive } = req.query;
    const where = { role: 'ssa' };
    if (isActive !== undefined) where.isActive = isActive === 'true';
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { phone: { contains: search, mode: 'insensitive' } },
      ];
    }
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: { id: true, name: true, phone: true, pincode: true, city: true, maxCouponDiscountPercent: true, isActive: true, createdAt: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.user.count({ where }),
    ]);
    const ssaList = await Promise.all(
      users.map(async (u) => {
        const onboardingCount = await prisma.shopkeeperProfile.count({ where: { onboardedBy: u.id } });
        return { ...u, onboardingCount };
      })
    );
    res.json({ success: true, data: { ssaList, pagination: { total, page: parseInt(page, 10), limit: parseInt(limit, 10), pages: Math.ceil(total / parseInt(limit, 10)) } } });
  } catch (err) {
    next(err);
  }
}

async function getCompanySalesAgentList(req, res, next) {
  try {
    const { page = 1, limit = 20, search, isActive } = req.query;
    const where = { role: 'company_sales_agent' };
    if (isActive !== undefined) where.isActive = isActive === 'true';
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { phone: { contains: search, mode: 'insensitive' } },
      ];
    }
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: { id: true, name: true, phone: true, pincode: true, city: true, maxCouponDiscountPercent: true, isActive: true, createdAt: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.user.count({ where }),
    ]);
    const csaList = await Promise.all(
      users.map(async (u) => {
        const onboardingCount = await prisma.shopkeeperProfile.count({ where: { onboardedBy: u.id } });
        return { ...u, onboardingCount };
      })
    );
    res.json({ success: true, data: { csaList, pagination: { total, page: parseInt(page, 10), limit: parseInt(limit, 10), pages: Math.ceil(total / parseInt(limit, 10)) } } });
  } catch (err) {
    next(err);
  }
}

async function getCouponList(req, res, next) {
  try {
    const { page = 1, limit = 20, search, isActive } = req.query;
    const where = {};
    if (isActive !== undefined) where.isActive = isActive === 'true';
    if (search) where.code = { contains: search, mode: 'insensitive' };
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [coupons, total] = await Promise.all([
      prisma.coupon.findMany({
        where,
        include: { agent: { select: { name: true, phone: true, role: true, maxCouponDiscountPercent: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.coupon.count({ where }),
    ]);

    const couponsWithIncentive = coupons.map((coupon) => {
      const agentCap = coupon.agent?.maxCouponDiscountPercent || DEFAULT_AGENT_MAX_DISCOUNT;
      const isPercentage = coupon.discountType === 'percentage';
      const discount = Number(coupon.discountValue || 0);
      const remainingIncentivePercent = isPercentage
        ? Math.max(0, agentCap - discount)
        : null;

      return {
        ...coupon,
        agentMaxDiscountPercent: agentCap,
        remainingIncentivePercent,
      };
    });

    res.json({ success: true, data: { coupons: couponsWithIncentive, pagination: { total, page: parseInt(page, 10), limit: parseInt(limit, 10), pages: Math.ceil(total / parseInt(limit, 10)) } } });
  } catch (err) {
    next(err);
  }
}

async function getCouponActivations(req, res, next) {
  try {
    const { page = 1, limit = 20, startDate, endDate, couponCode } = req.query;
    const where = { couponCode: { not: null } };
    if (couponCode) where.couponCode = { contains: couponCode, mode: 'insensitive' };
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = new Date(startDate);
      if (endDate) where.createdAt.lte = new Date(endDate);
    }
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [activations, total, summary] = await Promise.all([
      prisma.subscription.findMany({
        where,
        include: {
          shopkeeper: { select: { name: true, phone: true } },
          plan: { select: { displayName: true, monthlyPrice: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.subscription.count({ where }),
      prisma.subscription.aggregate({
        where,
        _sum: { discountAmount: true },
        _count: { _all: true },
      }),
    ]);
    res.json({
      success: true,
      data: {
        activations,
        summary: {
          totalDiscount: Number(summary._sum.discountAmount || 0),
          totalActivations: summary._count._all || 0,
        },
        pagination: { total, page: parseInt(page, 10), limit: parseInt(limit, 10), pages: Math.ceil(total / parseInt(limit, 10)) },
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getAgentGovernanceDashboard(req, res, next) {
  try {
    const [totalSSA, activeSSA, totalCSA, activeCSA, totalOnboardings, couponStats, top] = await Promise.all([
      prisma.user.count({ where: { role: 'ssa' } }),
      prisma.user.count({ where: { role: 'ssa', isActive: true } }),
      prisma.user.count({ where: { role: 'company_sales_agent' } }),
      prisma.user.count({ where: { role: 'company_sales_agent', isActive: true } }),
      prisma.shopkeeperProfile.count({ where: { onboardedBy: { not: null } } }),
      prisma.subscription.aggregate({ where: { couponCode: { not: null } }, _sum: { discountAmount: true }, _count: { _all: true } }),
      prisma.shopkeeperProfile.groupBy({
        by: ['onboardedBy'],
        where: { onboardedBy: { not: null } },
        _count: { _all: true },
        orderBy: { _count: { onboardedBy: 'desc' } },
        take: 5,
      }),
    ]);

    const topPerformers = await Promise.all(
      top.map(async (t) => {
        const agent = await prisma.user.findUnique({ where: { id: t.onboardedBy } });
        return {
          agentId: t.onboardedBy,
          agentName: agent?.name,
          agentPhone: agent?.phone,
          agentRole: agent?.role,
          onboardingCount: t._count._all,
        };
      })
    );

    res.json({
      success: true,
      data: {
        ssa: { total: totalSSA, active: activeSSA, inactive: totalSSA - activeSSA },
        csa: { total: totalCSA, active: activeCSA, inactive: totalCSA - activeCSA },
        onboarding: { total: totalOnboardings },
        coupons: {
          totalActivations: couponStats._count._all || 0,
          totalDiscountDistributed: Number(couponStats._sum.discountAmount || 0),
        },
        topPerformers,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function createSSA(req, res, next) {
  try {
    const { name, email, phone, password, state, region, pincode, maxCouponDiscountPercent } = req.body;
    if (!name || !email || !phone || !password) {
      return res.status(400).json({ success: false, message: 'Name, email, phone, and password are required' });
    }
    const normalizedMax = normalizeAgentMaxDiscount(maxCouponDiscountPercent);
    if (normalizedMax === null) {
      return res.status(400).json({ success: false, message: 'maxCouponDiscountPercent must be an integer between 1 and 99' });
    }
    const existing = await userRepository.findByEmailOrPhone(email, phone);
    if (existing) return res.status(400).json({ success: false, message: 'User with this email or phone already exists' });
    const user = await userRepository.create({
      name,
      email,
      phone,
      password,
      role: 'ssa',
      state,
      region,
      pincode,
      maxCouponDiscountPercent: normalizedMax,
      isActive: true,
    });
    const { password: _pwd, ...data } = user;
    res.status(201).json({ success: true, message: 'SSA created successfully', data });
  } catch (err) {
    next(err);
  }
}

async function createCompanySalesAgent(req, res, next) {
  try {
    const { name, email, phone, password, region, territory, pincode, maxCouponDiscountPercent } = req.body;
    if (!name || !email || !phone || !password) {
      return res.status(400).json({ success: false, message: 'Name, email, phone, and password are required' });
    }
    const normalizedMax = normalizeAgentMaxDiscount(maxCouponDiscountPercent);
    if (normalizedMax === null) {
      return res.status(400).json({ success: false, message: 'maxCouponDiscountPercent must be an integer between 1 and 99' });
    }
    const existing = await userRepository.findByEmailOrPhone(email, phone);
    if (existing) return res.status(400).json({ success: false, message: 'User with this email or phone already exists' });
    const user = await userRepository.create({
      name,
      email,
      phone,
      password,
      role: 'company_sales_agent',
      region,
      territory,
      pincode,
      maxCouponDiscountPercent: normalizedMax,
      isActive: true,
    });
    const { password: _pwd, ...data } = user;
    res.status(201).json({ success: true, message: 'Company Sales Agent created successfully', data });
  } catch (err) {
    next(err);
  }
}

async function createCoupon(req, res, next) {
  try {
    const { discountType, discountValue, agentId, description, expiryDate, maxUses } = req.body;
    if (!discountType || discountValue === undefined || discountValue === null || !agentId) {
      return res.status(400).json({ success: false, message: 'Discount type, discount value, and agent ID are required' });
    }
    if (!['percentage', 'fixed'].includes(discountType)) {
      return res.status(400).json({ success: false, message: 'Discount type must be either \"percentage\" or \"fixed\"' });
    }

    const normalizedDiscountValue = Number(discountValue);
    if (!Number.isFinite(normalizedDiscountValue) || normalizedDiscountValue <= 0) {
      return res.status(400).json({ success: false, message: 'Discount value must be a valid positive number' });
    }

    const pgAgentId = await resolvePgId('users', agentId) || agentId;
    const agent = await prisma.user.findUnique({ where: { id: pgAgentId } });
    if (!agent || !['ssa', 'company_sales_agent'].includes(agent.role)) {
      return res.status(400).json({ success: false, message: 'Invalid agent ID or agent is not SSA/Company Sales Agent' });
    }

    if (discountType === 'percentage') {
      if (!Number.isInteger(normalizedDiscountValue) || normalizedDiscountValue < 1 || normalizedDiscountValue > MAX_PERCENTAGE_DISCOUNT) {
        return res.status(400).json({ success: false, message: 'Percentage discount must be an integer between 1 and 99' });
      }
      const agentLimit = agent.maxCouponDiscountPercent || DEFAULT_AGENT_MAX_DISCOUNT;
      if (normalizedDiscountValue > agentLimit) {
        return res.status(400).json({
          success: false,
          message: `Discount cannot exceed this agent limit (${agentLimit}%)`,
        });
      }
    }

    const discountSuffix = discountType === 'percentage'
      ? String(normalizedDiscountValue).padStart(2, '0')
      : '00';

    const generatedCode = await generateCouponCodeForAgent(agent, discountSuffix);

    const coupon = await couponRepository.createCoupon({
      code: generatedCode,
      discountType,
      discountValue: normalizedDiscountValue,
      agentId: pgAgentId,
      description,
      expiryDate: expiryDate ? new Date(expiryDate) : null,
      maxUses,
    });
    res.status(201).json({
      success: true,
      message: 'Coupon created successfully',
      data: {
        ...coupon,
        agentMaxDiscountPercent: agent.maxCouponDiscountPercent || DEFAULT_AGENT_MAX_DISCOUNT,
        remainingIncentivePercent:
          discountType === 'percentage'
            ? Math.max(
                0,
                (agent.maxCouponDiscountPercent || DEFAULT_AGENT_MAX_DISCOUNT) -
                    normalizedDiscountValue
              )
            : null,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getSSAList,
  getCompanySalesAgentList,
  getCouponList,
  getCouponActivations,
  getAgentGovernanceDashboard,
  createSSA,
  createCompanySalesAgent,
  createCoupon,
};
