-- AlterTable
ALTER TABLE "subscription_plans" ADD COLUMN IF NOT EXISTS "ai_credit_tier" TEXT NOT NULL DEFAULT 'silver',
ADD COLUMN IF NOT EXISTS "ai_optimization_suggestions" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS "boost_credits" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS "homepage_rotation" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS "monthly_ai_limit" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS "ranking_tier" TEXT NOT NULL DEFAULT 'normal',
ADD COLUMN IF NOT EXISTS "tier" TEXT;

-- CreateTable
CREATE TABLE IF NOT EXISTS "ai_wallet" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "shopkeeper_id" UUID NOT NULL,
    "subscription_id" UUID,
    "cycle_start" TIMESTAMPTZ(6),
    "cycle_end" TIMESTAMPTZ(6),
    "monthly_limit" INTEGER NOT NULL DEFAULT 0,
    "used_this_cycle" INTEGER NOT NULL DEFAULT 0,
    "extra_credits_current_cycle" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "ai_wallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "ai_credit_purchases" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "shopkeeper_id" UUID NOT NULL,
    "subscription_id" UUID NOT NULL,
    "pack_sku" TEXT NOT NULL,
    "credits" INTEGER NOT NULL,
    "price" DECIMAL(12,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_credit_purchases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "boost_credits" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "shopkeeper_id" UUID NOT NULL,
    "subscription_id" UUID NOT NULL,
    "total_granted" INTEGER NOT NULL,
    "used" INTEGER NOT NULL DEFAULT 0,
    "expires_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "boost_credits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "ai_credit_packs" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "sku" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "credits" INTEGER NOT NULL,
    "price_silver" DECIMAL(12,2) NOT NULL,
    "price_gold" DECIMAL(12,2) NOT NULL,
    "price_platinum" DECIMAL(12,2) NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "ai_credit_packs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "ai_wallet_shopkeeper_id_key" ON "ai_wallet"("shopkeeper_id");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "idx_ai_wallet_subscription_id" ON "ai_wallet"("subscription_id");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "idx_ai_credit_purchases_shopkeeper_created_desc" ON "ai_credit_purchases"("shopkeeper_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "idx_ai_credit_purchases_subscription_id" ON "ai_credit_purchases"("subscription_id");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "idx_boost_credits_shopkeeper_id" ON "boost_credits"("shopkeeper_id");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "idx_boost_credits_subscription_id" ON "boost_credits"("subscription_id");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "ai_credit_packs_sku_key" ON "ai_credit_packs"("sku");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "idx_subscription_plans_category_tier" ON "subscription_plans"("category", "tier");

-- AddForeignKey
ALTER TABLE "ai_wallet" ADD CONSTRAINT "ai_wallet_shopkeeper_id_fkey" FOREIGN KEY ("shopkeeper_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_wallet" ADD CONSTRAINT "ai_wallet_subscription_id_fkey" FOREIGN KEY ("subscription_id") REFERENCES "subscriptions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_credit_purchases" ADD CONSTRAINT "ai_credit_purchases_shopkeeper_id_fkey" FOREIGN KEY ("shopkeeper_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_credit_purchases" ADD CONSTRAINT "ai_credit_purchases_subscription_id_fkey" FOREIGN KEY ("subscription_id") REFERENCES "subscriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "boost_credits" ADD CONSTRAINT "boost_credits_shopkeeper_id_fkey" FOREIGN KEY ("shopkeeper_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "boost_credits" ADD CONSTRAINT "boost_credits_subscription_id_fkey" FOREIGN KEY ("subscription_id") REFERENCES "subscriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
