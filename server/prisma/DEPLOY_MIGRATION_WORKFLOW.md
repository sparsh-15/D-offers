# Deploy-Safe Prisma Migration Workflow

Use this workflow whenever you add new tables/columns/indexes and want migrations that can be applied directly with `npx prisma migrate deploy`.

## Why this flow

- It generates a SQL migration from the current live DB state to your `schema.prisma`.
- It avoids `migrate reset` and works safely with existing production data.
- It creates standard migration folders in `prisma/migrations/` so deploy is one command.

## 1. Update schema

Edit `prisma/schema.prisma` with your new tables/relations.

## 2. Generate a migration folder

From `server/`:

```bash
npm run prisma:migration:new -- add_campaign_tables
```

This creates:

```text
prisma/migrations/<timestamp>_add_campaign_tables/migration.sql
```

If there is no DB diff, no migration is created.

## 3. Apply migration

```bash
npx prisma migrate deploy
```

or

```bash
npm run prisma:migrate
```

## 4. Regenerate client

```bash
npx prisma generate
```

## Useful checks

```bash
npm run prisma:migrate:status
```

## Notes

- Always use `npx prisma migrate deploy` (not `npx migrate deploy`).
- Do not use `prisma migrate reset` on shared/prod DBs.
- Commit both files together for every schema change:
  - `prisma/schema.prisma`
  - `prisma/migrations/<timestamp>_<name>/migration.sql`