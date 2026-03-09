const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

function toUserShape(user) {
  if (!user) return null;
  return {
    id: user.id,
    _id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    password: user.password,
    role: user.role,
    pincode: user.pincode,
    city: user.city,
    state: user.state,
    region: user.region,
    territory: user.territory,
    address: user.address,
    maxCouponDiscountPercent: user.maxCouponDiscountPercent,
    approvalStatus: user.approvalStatus,
    permissions: user.permissions || [],
    isActive: user.isActive,
    signupCouponCode: user.signupCouponCode ?? null,
    signupCouponCapturedAt: user.signupCouponCapturedAt ?? null,
    onboardedByLeadId: user.onboardedByLeadId ?? null,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

async function findByPhone(phone) {
  const user = await prisma.user.findUnique({ where: { phone } });
  return toUserShape(user);
}

async function findById(id) {
  const pgId = await resolvePgId('users', id);
  if (!pgId) return null;
  const user = await prisma.user.findUnique({ where: { id: pgId } });
  return toUserShape(user);
}

async function findByEmailOrPhone(email, phone) {
  const user = await prisma.user.findFirst({
    where: {
      OR: [{ email: email || undefined }, { phone }],
    },
  });
  return toUserShape(user);
}

function normalizeSignupCoupon(value) {
  if (value == null || typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed ? trimmed.toUpperCase() : null;
}

async function create(data) {
  const signupCouponCode = data.signupCouponCode != null ? normalizeSignupCoupon(data.signupCouponCode) : null;
  const signupCouponCapturedAt = signupCouponCode ? (data.signupCouponCapturedAt || new Date()) : null;

  const user = await prisma.user.create({
    data: {
      name: data.name || '',
      email: data.email || null,
      phone: data.phone,
      password: data.password || null,
      role: data.role,
      pincode: data.pincode || '',
      city: data.city || '',
      state: data.state || '',
      region: data.region || '',
      territory: data.territory || '',
      address: data.address || '',
      gender: data.gender || null,
      dob: data.dob || null,
      occupation: data.occupation || null,
      aboutMe: data.aboutMe || null,
      maxCouponDiscountPercent:
        data.maxCouponDiscountPercent !== undefined
          ? data.maxCouponDiscountPercent
          : 50,
      // Default all users (including shopkeepers) to approved unless an explicit
      // approvalStatus is provided. Shop activation is now driven by onboarding
      // and subscription status instead of a separate manual approval step.
      approvalStatus: data.approvalStatus || 'approved',
      permissions: data.permissions || [],
      isActive: data.isActive !== undefined ? data.isActive : true,
      signupCouponCode: signupCouponCode || undefined,
      signupCouponCapturedAt: signupCouponCapturedAt || undefined,
      onboardedByLeadId: data.onboardedByLeadId || undefined,
    },
  });
  return toUserShape(user);
}

async function updateById(id, updates) {
  const pgId = await resolvePgId('users', id);
  if (!pgId) return null;
  const user = await prisma.user.update({
    where: { id: pgId },
    data: updates,
  });
  return toUserShape(user);
}

module.exports = {
  findByPhone,
  findById,
  findByEmailOrPhone,
  create,
  updateById,
};
