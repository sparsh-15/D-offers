#!/usr/bin/env node
require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

function pad(num) {
  return String(num).padStart(2, '0');
}

function timestamp() {
  const now = new Date();
  return (
    String(now.getFullYear()) +
    pad(now.getMonth() + 1) +
    pad(now.getDate()) +
    pad(now.getHours()) +
    pad(now.getMinutes()) +
    pad(now.getSeconds())
  );
}

function slugify(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .replace(/_+/g, '_');
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

function main() {
  const rawName = process.argv.slice(2).join(' ');
  const migrationName = slugify(rawName);

  if (!migrationName) {
    fail('Usage: npm run prisma:migration:new -- <migration_name>');
  }

  if (!process.env.DATABASE_URL) {
    fail('DATABASE_URL is not set. Add it to server/.env before generating migrations.');
  }

  const serverRoot = path.resolve(__dirname, '..');
  const schemaPath = path.join('prisma', 'schema.prisma');

  const prismaCliPath = require.resolve('prisma/build/index.js', {
    paths: [serverRoot],
  });

  const diff = spawnSync(
    process.execPath,
    [
      prismaCliPath,
      'migrate',
      'diff',
      '--from-url',
      process.env.DATABASE_URL,
      '--to-schema-datamodel',
      schemaPath,
      '--script',
    ],
    {
      cwd: serverRoot,
      encoding: 'utf8',
      env: process.env,
      maxBuffer: 10 * 1024 * 1024,
    },
  );

  if (diff.error) {
    fail(`Failed to run Prisma diff: ${diff.error.message}`);
  }

  if (diff.status !== 0) {
    const stderr = (diff.stderr || '').trim();
    fail(stderr || 'Prisma diff failed with a non-zero exit code.');
  }

  const sql = (diff.stdout || '').trim();
  const isEmptyMigration =
    !sql || /^--\s*this is an empty migration\.?$/i.test(sql);

  if (isEmptyMigration) {
    console.log('No schema changes detected. Migration was not created.');
    return;
  }

  const id = `${timestamp()}_${migrationName}`;
  const migrationDir = path.join(serverRoot, 'prisma', 'migrations', id);
  const migrationPath = path.join(migrationDir, 'migration.sql');

  fs.mkdirSync(migrationDir, { recursive: true });
  fs.writeFileSync(migrationPath, `${sql}\n`, { encoding: 'utf8' });

  console.log(`Created migration: prisma/migrations/${id}/migration.sql`);
  console.log('Next step: npx prisma migrate deploy');
}

main();