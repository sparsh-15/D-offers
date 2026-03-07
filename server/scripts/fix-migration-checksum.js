/**
 * One-off: update _prisma_migrations.checksum so it matches the current
 * migration file. Fixes "migration was modified after it was applied" (drift).
 * Run from server dir: node scripts/fix-migration-checksum.js
 */
require('dotenv').config();
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const MIGRATION_NAME = '20260228113344_add_monetization_ai_wallet_boost';

async function main() {
  const migrationPath = path.join(
    __dirname,
    '..',
    'prisma',
    'migrations',
    MIGRATION_NAME,
    'migration.sql'
  );
  if (!fs.existsSync(migrationPath)) {
    console.error('Migration file not found:', migrationPath);
    process.exit(1);
  }
  const content = fs.readFileSync(migrationPath, 'utf8');
  const checksum = crypto.createHash('sha256').update(content, 'utf8').digest('hex');

  const prisma = new PrismaClient();
  try {
    // Prisma stores checksum in _prisma_migrations
    await prisma.$executeRawUnsafe(
      `UPDATE "_prisma_migrations" SET "checksum" = $1 WHERE "migration_name" = $2`,
      checksum,
      MIGRATION_NAME
    );
    console.log('Updated checksum for', MIGRATION_NAME);
    console.log('Checksum:', checksum);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
