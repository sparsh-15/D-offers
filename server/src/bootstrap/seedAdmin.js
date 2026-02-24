const { prisma } = require('../db/prisma');
const config = require('../config');

const ADMIN_PHONE_REGEX = /^\d{10}$/;
const ALLOWED_ADMIN_ROLES = ['super_admin', 'subadmin'];

function normalizeAdminSeedConfig(overrides = {}) {
  const adminCfg = config.adminSeed || {};
  const merged = { ...adminCfg, ...overrides };
  const role = ALLOWED_ADMIN_ROLES.includes(merged.role) ? merged.role : 'super_admin';

  return {
    enabled: merged.enabled !== false,
    phone: String(merged.phone || '').trim(),
    name: String(merged.name || 'Admin').trim() || 'Admin',
    pincode: String(merged.pincode || '').trim(),
    address: String(merged.address || '').trim(),
    role,
  };
}

async function seedAdminFromEnv(overrides = {}) {
  const admin = normalizeAdminSeedConfig(overrides);
  if (!admin.enabled || !admin.phone) return null;

  if (!ADMIN_PHONE_REGEX.test(admin.phone)) {
    throw new Error('ADMIN_PHONE must be exactly 10 digits');
  }

  const data = {
    name: admin.name,
    phone: admin.phone,
    role: admin.role,
    approvalStatus: 'approved',
    isActive: true,
    permissions: admin.role === 'super_admin' ? ['all'] : [],
  };

  if (admin.pincode) data.pincode = admin.pincode;
  if (admin.address) data.address = admin.address;

  const existing = await prisma.user.findUnique({ where: { phone: admin.phone } });
  if (existing) {
    const user = await prisma.user.update({
      where: { id: existing.id },
      data,
    });
    return { created: false, user };
  }

  const user = await prisma.user.create({ data });
  return { created: true, user };
}

module.exports = {
  seedAdminFromEnv,
};
