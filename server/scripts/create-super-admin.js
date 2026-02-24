require('dotenv').config();
const { prisma } = require('../src/db/prisma');
const { seedAdminFromEnv } = require('../src/bootstrap/seedAdmin');

async function run() {
  const phoneArg = process.argv[2];
  const nameArg = process.argv[3];
  const phone = phoneArg || process.env.ADMIN_PHONE || '';
  const name = nameArg || process.env.ADMIN_NAME || 'Admin';
  if (!phone) {
    console.error('Error: Phone number is required');
    console.log('Usage: node scripts/create-super-admin.js <phone> <name>');
    console.log('Or set ADMIN_PHONE and ADMIN_NAME in .env');
    process.exit(1);
  }

  const result = await seedAdminFromEnv({ phone, name });
  if (!result) {
    console.log('Admin seed skipped. Set ADMIN_PHONE in .env or pass it as CLI arg.');
    return;
  }

  const action = result.created ? 'created' : 'updated';
  console.log(`Admin ${action}:`, result.user.id, result.user.phone, result.user.role);
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('Error:', err.message);
    await prisma.$disconnect();
    process.exit(1);
  });
