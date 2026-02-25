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

async function create(data) {
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
