-- AlterTable
ALTER TABLE "ai_credit_packs" ADD COLUMN IF NOT EXISTS "category" TEXT NOT NULL DEFAULT 'all';

-- CreateIndex
CREATE INDEX IF NOT EXISTS "ai_credit_packs_category_idx" ON "ai_credit_packs"("category");
