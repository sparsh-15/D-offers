# Prisma & Neon (production) sync guide

You work with **one database – Neon production** and need to keep it in sync for daily APK builds. Use this workflow.

---

## Your setup: single live DB (Neon)

- `.env` → `DATABASE_URL` points to **Neon** (production).
- You change `schema.prisma`, then you need Neon updated so the app and APK work.
- **Never run** `prisma migrate reset` – it would wipe Neon and all data.

---

## Daily workflow: when you change the schema

### 1. Edit the schema

Edit `prisma/schema.prisma` (new table, new column, index, etc.).

### 2. Sync schema to Neon (choose one)

**Option A – Use migrations (recommended for real changes)**

From the **server** folder:

```bash
cd server
npx prisma migrate dev --name describe_your_change
```

Example: `npx prisma migrate dev --name add_user_avatar`

- Creates a new migration under `prisma/migrations/` and **applies it to Neon**.
- If you see **drift** or “migration was modified”, use the [Fix drift](#fix-drift-so-migrate-dev-works) section below once, then run this again.

**Option B – Quick sync without migration file (fast iteration)**

When you only need the DB to match the schema immediately and don’t need a migration file yet:

```bash
cd server
npx prisma db push
```

- Pushes current `schema.prisma` to Neon. No migration file, no history.
- Use for quick daily sync; use **migrate dev** when you want to keep a migration for the change.

### 3. Regenerate client and run app

```bash
npx prisma generate
```

Then start the server and build the APK as usual.

---

## One-time: fix drift so `migrate dev` works

If `prisma migrate dev` fails with “drift detected” or “migration was modified after it was applied”, fix the migration history once (no data loss):

1. **Do not run** `prisma migrate reset`.

2. See which migration Prisma complains about (e.g. `20260228113344_add_monetization_ai_wallet_boost`).

3. If the error says the migration is **already applied** but the **file was modified** (checksum mismatch), run the checksum fix script:

   ```bash
   cd server
   node scripts/fix-migration-checksum.js
   ```

   (To fix a different migration, edit `MIGRATION_NAME` in that script.) Then run `npx prisma migrate status` to confirm.

4. Otherwise, mark that migration as already applied (you applied it by hand):

   ```bash
   cd server
   npx prisma migrate resolve --applied 20260228113344_add_monetization_ai_wallet_boost
   ```

   Use the **exact folder name** of the migration (from `prisma/migrations/`).

5. Check status:

   ```bash
   npx prisma migrate status
   ```

6. If there are pending migrations, apply them:

   ```bash
   npx prisma migrate deploy
   ```

7. After that, use **Option A** (`migrate dev --name your_change`) for new schema changes; it will apply to Neon.

---

## Summary: “I only use Neon, I changed the schema”

| What you want | Command |
|---------------|--------|
| Create migration and apply to Neon | `npx prisma migrate dev --name your_change` |
| Apply existing migrations only (e.g. after pull) | `npx prisma migrate deploy` |
| Sync schema to Neon without migration file | `npx prisma db push` |
| Fix “drift” / “migration modified” | `npx prisma migrate resolve --applied MIGRATION_NAME` then `migrate deploy` if needed. Or run `node scripts/fix-migration-checksum.js` for checksum mismatch. |
| Regenerate client after schema change | `npx prisma generate` |

**Never run:** `npx prisma migrate reset` (deletes all data on the DB in `.env`).

---

## Quick reference

| Goal | Command |
|------|--------|
| New schema change → create migration + apply to Neon | `npx prisma migrate dev --name name` |
| Apply pending migrations to Neon | `npx prisma migrate deploy` |
| Sync schema to Neon, no migration file | `npx prisma db push` |
| Check migration status | `npx prisma migrate status` |
| Mark migration as applied (fix history) | `npx prisma migrate resolve --applied MIGRATION_NAME` |
| Regenerate client | `npx prisma generate` |

Use **`migrate resolve`** only when Prisma reports drift or “migration was modified”; use the exact migration folder name (e.g. `20260228113344_add_monetization_ai_wallet_boost`).
