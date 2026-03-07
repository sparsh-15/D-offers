-- Create shop_leads if it does not exist (some DBs never had this table)
CREATE TABLE IF NOT EXISTS "shop_leads" (
  "id" UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
  "ssa_id" UUID REFERENCES "users"("id") ON DELETE SET NULL,
  "csa_id" UUID REFERENCES "users"("id") ON DELETE SET NULL,
  "shop_name" TEXT NOT NULL,
  "owner_name" TEXT,
  "phone" TEXT NOT NULL,
  "pincode" TEXT,
  "city" TEXT,
  "category" TEXT,
  "notes" TEXT,
  "coupon_code" TEXT,
  "status" TEXT NOT NULL DEFAULT 'open',
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS "idx_shop_leads_ssa_status" ON "shop_leads"("ssa_id", "status");
CREATE INDEX IF NOT EXISTS "idx_shop_leads_csa_status" ON "shop_leads"("csa_id", "status");
CREATE INDEX IF NOT EXISTS "idx_shop_leads_coupon_code" ON "shop_leads"("coupon_code");

-- If shop_leads already existed without csa_id, add column and make ssa_id nullable
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'shop_leads' AND column_name = 'ssa_id')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'shop_leads' AND column_name = 'csa_id') THEN
    ALTER TABLE "shop_leads" ADD COLUMN "csa_id" UUID REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    ALTER TABLE "shop_leads" ALTER COLUMN "ssa_id" DROP NOT NULL;
    CREATE INDEX IF NOT EXISTS "idx_shop_leads_csa_status" ON "shop_leads"("csa_id", "status");
  END IF;
END $$;

-- AlterTable users: signup coupon intent (shopkeeper registration)
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "signup_coupon_code" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "signup_coupon_captured_at" TIMESTAMPTZ(6);

-- AlterTable subscriptions: coupon attribution snapshots
ALTER TABLE "subscriptions" ADD COLUMN IF NOT EXISTS "coupon_agent_id_snapshot" UUID;
ALTER TABLE "subscriptions" ADD COLUMN IF NOT EXISTS "coupon_agent_name_snapshot" TEXT;
ALTER TABLE "subscriptions" ADD COLUMN IF NOT EXISTS "coupon_agent_role_snapshot" TEXT;
ALTER TABLE "subscriptions" ADD COLUMN IF NOT EXISTS "coupon_campaign_snapshot" JSONB;
