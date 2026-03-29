-- CreateEnum: customer_claim_status_enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'customer_claim_status_enum') THEN
    CREATE TYPE "customer_claim_status_enum" AS ENUM ('active', 'redeemed', 'expired', 'cancelled');
  END IF;
END $$;

-- CreateTable: customer_offer_claims
CREATE TABLE IF NOT EXISTS "customer_offer_claims" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
  "customer_id" UUID NOT NULL,
  "offer_id" UUID NOT NULL,
  "coupon_id" UUID NOT NULL,
  "status" "customer_claim_status_enum" NOT NULL DEFAULT 'active',
  "claimed_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "redeemed_at" TIMESTAMPTZ(6),
  "expires_at" TIMESTAMPTZ(6),
  "metadata" JSONB NOT NULL DEFAULT '{}',
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "customer_offer_claims_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "customer_offer_claims_coupon_id_key"
  ON "customer_offer_claims"("coupon_id");

CREATE UNIQUE INDEX IF NOT EXISTS "uq_customer_offer_claims_customer_offer"
  ON "customer_offer_claims"("customer_id", "offer_id");

CREATE INDEX IF NOT EXISTS "idx_customer_offer_claims_customer_claimed_desc"
  ON "customer_offer_claims"("customer_id", "claimed_at" DESC);

CREATE INDEX IF NOT EXISTS "idx_customer_offer_claims_offer_claimed_desc"
  ON "customer_offer_claims"("offer_id", "claimed_at" DESC);

CREATE INDEX IF NOT EXISTS "idx_customer_offer_claims_status_claimed_desc"
  ON "customer_offer_claims"("status", "claimed_at" DESC);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'customer_offer_claims_customer_id_fkey'
  ) THEN
    ALTER TABLE "customer_offer_claims"
      ADD CONSTRAINT "customer_offer_claims_customer_id_fkey"
      FOREIGN KEY ("customer_id") REFERENCES "users"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'customer_offer_claims_offer_id_fkey'
  ) THEN
    ALTER TABLE "customer_offer_claims"
      ADD CONSTRAINT "customer_offer_claims_offer_id_fkey"
      FOREIGN KEY ("offer_id") REFERENCES "offers"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'customer_offer_claims_coupon_id_fkey'
  ) THEN
    ALTER TABLE "customer_offer_claims"
      ADD CONSTRAINT "customer_offer_claims_coupon_id_fkey"
      FOREIGN KEY ("coupon_id") REFERENCES "coupons"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;
