require('dotenv').config();
const config = require('./src/config');
const app = require('./src/app');
const { seedAdminFromEnv } = require('./src/bootstrap/seedAdmin');
const { prisma } = require('./src/db/prisma');

async function startServer() {
  try {
    const seeded = await seedAdminFromEnv();
    if (seeded) {
      const action = seeded.created ? 'created' : 'updated';
      console.log(`Admin seed ${action}: ${seeded.user.phone} (${seeded.user.role})`);
    }
  } catch (err) {
    console.error(`Admin seed failed: ${err.message}`);
  }

  app.listen(config.port, () => {
    console.log(`Server running on port ${config.port}`);
    console.log('DB provider: postgres');
  });
}

startServer();

process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
