const { prisma } = require('../db/prisma');

function toOtpShape(otp) {
  if (!otp) return null;
  return {
    id: otp.id,
    _id: otp.id,
    phone: otp.phone,
    otp: otp.otp,
    expiresAt: otp.expiresAt,
    createdAt: otp.createdAt,
    updatedAt: otp.updatedAt,
  };
}

async function deleteByPhone(phone) {
  await prisma.otp.deleteMany({ where: { phone } });
}

async function create(data) {
  const otp = await prisma.otp.create({
    data: {
      phone: data.phone,
      otp: data.otp,
      expiresAt: data.expiresAt,
    },
  });
  return toOtpShape(otp);
}

async function findLatestByPhone(phone) {
  const otp = await prisma.otp.findFirst({
    where: { phone },
    orderBy: { createdAt: 'desc' },
  });
  return toOtpShape(otp);
}

module.exports = {
  deleteByPhone,
  create,
  findLatestByPhone,
};
