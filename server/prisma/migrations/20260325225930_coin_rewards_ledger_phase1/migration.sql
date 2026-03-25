-- CreateEnum
CREATE TYPE "coin_direction_enum" AS ENUM ('credit', 'debit');

-- CreateEnum
CREATE TYPE "coin_action_type_enum" AS ENUM ('like_offer', 'purchase_success', 'sale_closed', 'install_verified', 'reversal', 'expiry', 'milestone_redeem', 'admin_adjustment');

-- CreateEnum
CREATE TYPE "milestone_redemption_status_enum" AS ENUM ('pending', 'approved', 'rejected', 'paid');

-- CreateTable
CREATE TABLE "coin_wallets" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "user_id" UUID NOT NULL,
    "user_type" "role_enum" NOT NULL,
    "balance" INTEGER NOT NULL DEFAULT 0,
    "last_reconciled_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "coin_wallets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coin_ledger_entries" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "wallet_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "user_type" "role_enum" NOT NULL,
    "direction" "coin_direction_enum" NOT NULL,
    "amount" INTEGER NOT NULL,
    "action_type" "coin_action_type_enum" NOT NULL,
    "source_ref" TEXT NOT NULL,
    "idempotency_key" TEXT NOT NULL,
    "reference_entry_id" UUID,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "expires_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "coin_ledger_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reward_events" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "user_id" UUID NOT NULL,
    "user_type" "role_enum" NOT NULL,
    "action_type" "coin_action_type_enum" NOT NULL,
    "source_ref" TEXT NOT NULL,
    "device_fingerprint" TEXT,
    "idempotency_key" TEXT,
    "validated" BOOLEAN NOT NULL DEFAULT false,
    "rejected_reason" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "reward_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coin_lots" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "wallet_id" UUID NOT NULL,
    "ledger_entry_id" UUID NOT NULL,
    "original_amount" INTEGER NOT NULL,
    "remaining_amount" INTEGER NOT NULL,
    "earned_at" TIMESTAMPTZ(6) NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "coin_lots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coin_milestone_definitions" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "threshold_coins" INTEGER NOT NULL,
    "reward_amount_paise" INTEGER NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "coin_milestone_definitions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coin_milestone_progress" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "user_id" UUID NOT NULL,
    "lifetime_credited" INTEGER NOT NULL DEFAULT 0,
    "current_milestone_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "coin_milestone_progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coin_milestone_redemptions" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "user_id" UUID NOT NULL,
    "milestone_id" UUID NOT NULL,
    "status" "milestone_redemption_status_enum" NOT NULL DEFAULT 'pending',
    "requested_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processed_at" TIMESTAMPTZ(6),
    "notes" TEXT,

    CONSTRAINT "coin_milestone_redemptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reward_configs" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "key" TEXT NOT NULL,
    "config_value" JSONB NOT NULL DEFAULT '{}',
    "version" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "reward_configs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coin_reconciliation_runs" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "user_id" UUID,
    "checked_wallets" INTEGER NOT NULL DEFAULT 0,
    "mismatched_wallets" INTEGER NOT NULL DEFAULT 0,
    "auto_healed_wallets" INTEGER NOT NULL DEFAULT 0,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "coin_reconciliation_runs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "coin_wallets_user_id_key" ON "coin_wallets"("user_id");

-- CreateIndex
CREATE INDEX "idx_coin_wallets_user_type" ON "coin_wallets"("user_type");

-- CreateIndex
CREATE UNIQUE INDEX "coin_ledger_entries_idempotency_key_key" ON "coin_ledger_entries"("idempotency_key");

-- CreateIndex
CREATE INDEX "idx_coin_ledger_user_created_desc" ON "coin_ledger_entries"("user_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_coin_ledger_wallet_created_desc" ON "coin_ledger_entries"("wallet_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_coin_ledger_action_created_desc" ON "coin_ledger_entries"("action_type", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_coin_ledger_user_direction_created_desc" ON "coin_ledger_entries"("user_id", "direction", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_coin_ledger_expires_at" ON "coin_ledger_entries"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "uq_coin_ledger_user_action_source" ON "coin_ledger_entries"("user_id", "action_type", "source_ref");

-- CreateIndex
CREATE INDEX "idx_reward_events_user_created_desc" ON "reward_events"("user_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_reward_events_action_created_desc" ON "reward_events"("action_type", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_reward_events_device_fingerprint" ON "reward_events"("device_fingerprint");

-- CreateIndex
CREATE UNIQUE INDEX "uq_reward_events_user_action_source" ON "reward_events"("user_id", "action_type", "source_ref");

-- CreateIndex
CREATE UNIQUE INDEX "coin_lots_ledger_entry_id_key" ON "coin_lots"("ledger_entry_id");

-- CreateIndex
CREATE INDEX "idx_coin_lots_wallet_expires" ON "coin_lots"("wallet_id", "expires_at");

-- CreateIndex
CREATE INDEX "idx_coin_lots_expires_at" ON "coin_lots"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "coin_milestone_definitions_threshold_coins_key" ON "coin_milestone_definitions"("threshold_coins");

-- CreateIndex
CREATE INDEX "idx_coin_milestones_active_sort" ON "coin_milestone_definitions"("is_active", "sort_order");

-- CreateIndex
CREATE UNIQUE INDEX "coin_milestone_progress_user_id_key" ON "coin_milestone_progress"("user_id");

-- CreateIndex
CREATE INDEX "idx_coin_milestone_progress_lifetime" ON "coin_milestone_progress"("lifetime_credited");

-- CreateIndex
CREATE INDEX "idx_coin_redemptions_user_requested_desc" ON "coin_milestone_redemptions"("user_id", "requested_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "uq_coin_redemptions_user_milestone" ON "coin_milestone_redemptions"("user_id", "milestone_id");

-- CreateIndex
CREATE UNIQUE INDEX "reward_configs_key_key" ON "reward_configs"("key");

-- CreateIndex
CREATE INDEX "idx_coin_reconciliation_created_desc" ON "coin_reconciliation_runs"("created_at" DESC);

-- AddForeignKey
ALTER TABLE "coin_wallets" ADD CONSTRAINT "coin_wallets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_ledger_entries" ADD CONSTRAINT "coin_ledger_entries_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "coin_wallets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_ledger_entries" ADD CONSTRAINT "coin_ledger_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_ledger_entries" ADD CONSTRAINT "coin_ledger_entries_reference_entry_id_fkey" FOREIGN KEY ("reference_entry_id") REFERENCES "coin_ledger_entries"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reward_events" ADD CONSTRAINT "reward_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_lots" ADD CONSTRAINT "coin_lots_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "coin_wallets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_lots" ADD CONSTRAINT "coin_lots_ledger_entry_id_fkey" FOREIGN KEY ("ledger_entry_id") REFERENCES "coin_ledger_entries"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_milestone_progress" ADD CONSTRAINT "coin_milestone_progress_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_milestone_progress" ADD CONSTRAINT "coin_milestone_progress_current_milestone_id_fkey" FOREIGN KEY ("current_milestone_id") REFERENCES "coin_milestone_definitions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_milestone_redemptions" ADD CONSTRAINT "coin_milestone_redemptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_milestone_redemptions" ADD CONSTRAINT "coin_milestone_redemptions_milestone_id_fkey" FOREIGN KEY ("milestone_id") REFERENCES "coin_milestone_definitions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coin_reconciliation_runs" ADD CONSTRAINT "coin_reconciliation_runs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
