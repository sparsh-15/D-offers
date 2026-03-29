-- CreateEnum: verification_method_enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_method_enum') THEN
    CREATE TYPE "verification_method_enum" AS ENUM ('qr', 'manual');
  END IF;
END $$;

-- CreateEnum: redemption_status_enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'redemption_status_enum') THEN
    CREATE TYPE "redemption_status_enum" AS ENUM ('redeemed', 'reversed');
  END IF;
END $$;

-- CreateEnum: scan_attempt_result_enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'scan_attempt_result_enum') THEN
    CREATE TYPE "scan_attempt_result_enum" AS ENUM (
      'verified',
      'invalid',
      'expired',
      'usage_limit_reached',
      'offer_not_found',
      'coupon_not_found',
      'already_redeemed',
      'unauthorized',
      'error'
    );
  END IF;
END $$;

-- CreateTable: coupon_redemptions
CREATE TABLE IF NOT EXISTS "coupon_redemptions" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
  "coupon_id" UUID NOT NULL,
  "offer_id" UUID NOT NULL,
  "redeemed_by_user_id" UUID NOT NULL,
  "verification_method" "verification_method_enum" NOT NULL,
  "status" "redemption_status_enum" NOT NULL DEFAULT 'redeemed',
  "idempotency_key" TEXT,
  "metadata" JSONB NOT NULL DEFAULT '{}',
  "redeemed_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "coupon_redemptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable: coupon_scan_attempts
CREATE TABLE IF NOT EXISTS "coupon_scan_attempts" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
  "attempted_code" TEXT NOT NULL,
  "normalized_code" TEXT,
  "coupon_id" UUID,
  "offer_id" UUID,
  "actor_user_id" UUID NOT NULL,
  "verification_method" "verification_method_enum" NOT NULL,
  "result" "scan_attempt_result_enum" NOT NULL,
  "reason" TEXT,
  "idempotency_key" TEXT,
  "ip_address" TEXT,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "coupon_scan_attempts_pkey" PRIMARY KEY ("id")
);

-- Constraints and indexes for coupon_redemptions
CREATE UNIQUE INDEX IF NOT EXISTS "coupon_redemptions_idempotency_key_key"
  ON "coupon_redemptions"("idempotency_key");

CREATE UNIQUE INDEX IF NOT EXISTS "uq_coupon_redemptions_coupon_offer"
  ON "coupon_redemptions"("coupon_id", "offer_id");

CREATE INDEX IF NOT EXISTS "idx_coupon_redemptions_coupon_created_desc"
  ON "coupon_redemptions"("coupon_id", "created_at" DESC);

CREATE INDEX IF NOT EXISTS "idx_coupon_redemptions_offer_created_desc"
  ON "coupon_redemptions"("offer_id", "created_at" DESC);

CREATE INDEX IF NOT EXISTS "idx_coupon_redemptions_actor_created_desc"
  ON "coupon_redemptions"("redeemed_by_user_id", "created_at" DESC);

-- Constraints and indexes for coupon_scan_attempts
CREATE INDEX IF NOT EXISTS "idx_coupon_scan_attempts_code_created_desc"
  ON "coupon_scan_attempts"("normalized_code", "created_at" DESC);

CREATE INDEX IF NOT EXISTS "idx_coupon_scan_attempts_coupon_created_desc"
  ON "coupon_scan_attempts"("coupon_id", "created_at" DESC);

CREATE INDEX IF NOT EXISTS "idx_coupon_scan_attempts_offer_created_desc"
  ON "coupon_scan_attempts"("offer_id", "created_at" DESC);

CREATE INDEX IF NOT EXISTS "idx_coupon_scan_attempts_actor_created_desc"
  ON "coupon_scan_attempts"("actor_user_id", "created_at" DESC);

-- Foreign keys
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'coupon_redemptions_coupon_id_fkey'
  ) THEN
    ALTER TABLE "coupon_redemptions"
      ADD CONSTRAINT "coupon_redemptions_coupon_id_fkey"
      FOREIGN KEY ("coupon_id") REFERENCES "coupons"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'coupon_redemptions_offer_id_fkey'
  ) THEN
    ALTER TABLE "coupon_redemptions"
      ADD CONSTRAINT "coupon_redemptions_offer_id_fkey"
      FOREIGN KEY ("offer_id") REFERENCES "offers"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'coupon_redemptions_redeemed_by_user_id_fkey'
  ) THEN
    ALTER TABLE "coupon_redemptions"
      ADD CONSTRAINT "coupon_redemptions_redeemed_by_user_id_fkey"
      FOREIGN KEY ("redeemed_by_user_id") REFERENCES "users"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'coupon_scan_attempts_coupon_id_fkey'
  ) THEN
    ALTER TABLE "coupon_scan_attempts"
      ADD CONSTRAINT "coupon_scan_attempts_coupon_id_fkey"
      FOREIGN KEY ("coupon_id") REFERENCES "coupons"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'coupon_scan_attempts_offer_id_fkey'
  ) THEN
    ALTER TABLE "coupon_scan_attempts"
      ADD CONSTRAINT "coupon_scan_attempts_offer_id_fkey"
      FOREIGN KEY ("offer_id") REFERENCES "offers"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'coupon_scan_attempts_actor_user_id_fkey'
  ) THEN
    ALTER TABLE "coupon_scan_attempts"
      ADD CONSTRAINT "coupon_scan_attempts_actor_user_id_fkey"
      FOREIGN KEY ("actor_user_id") REFERENCES "users"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;
