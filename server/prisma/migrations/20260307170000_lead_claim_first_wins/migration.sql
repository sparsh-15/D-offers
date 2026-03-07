-- Add new audit actions for lead funnel tracking
ALTER TYPE "audit_action_enum" ADD VALUE IF NOT EXISTS 'lead_created';
ALTER TYPE "audit_action_enum" ADD VALUE IF NOT EXISTS 'lead_linked_existing_user';
ALTER TYPE "audit_action_enum" ADD VALUE IF NOT EXISTS 'lead_invite_sent';
ALTER TYPE "audit_action_enum" ADD VALUE IF NOT EXISTS 'lead_invite_failed';
ALTER TYPE "audit_action_enum" ADD VALUE IF NOT EXISTS 'lead_conflict_rejected';

-- Extend users with first-lead ownership pointer
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "onboarded_by_lead_id" UUID;

-- Extend shop_leads with linkage/invite metadata
ALTER TABLE "shop_leads" ADD COLUMN IF NOT EXISTS "shopkeeper_user_id" UUID;
ALTER TABLE "shop_leads" ADD COLUMN IF NOT EXISTS "source_agent_role" "role_enum";
ALTER TABLE "shop_leads" ADD COLUMN IF NOT EXISTS "claimed_at" TIMESTAMPTZ(6);
ALTER TABLE "shop_leads" ADD COLUMN IF NOT EXISTS "invite_status" TEXT NOT NULL DEFAULT 'pending';
ALTER TABLE "shop_leads" ADD COLUMN IF NOT EXISTS "invite_sent_at" TIMESTAMPTZ(6);
ALTER TABLE "shop_leads" ADD COLUMN IF NOT EXISTS "invite_error" TEXT;

-- Foreign keys (guarded to avoid duplicate constraint errors)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'shop_leads_shopkeeper_user_id_fkey'
  ) THEN
    ALTER TABLE "shop_leads"
      ADD CONSTRAINT "shop_leads_shopkeeper_user_id_fkey"
      FOREIGN KEY ("shopkeeper_user_id") REFERENCES "users"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_onboarded_by_lead_id_fkey'
  ) THEN
    ALTER TABLE "users"
      ADD CONSTRAINT "users_onboarded_by_lead_id_fkey"
      FOREIGN KEY ("onboarded_by_lead_id") REFERENCES "shop_leads"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- Normalize existing duplicate active leads before adding first-lead unique guard
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (PARTITION BY phone ORDER BY created_at ASC, id ASC) AS rn
  FROM "shop_leads"
  WHERE status IN ('open', 'contacted', 'claimed')
)
UPDATE "shop_leads"
SET status = 'duplicate', updated_at = now()
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Indexes for lookups and ownership
CREATE INDEX IF NOT EXISTS "idx_shop_leads_shopkeeper_user_id" ON "shop_leads"("shopkeeper_user_id");
CREATE INDEX IF NOT EXISTS "idx_users_onboarded_by_lead_id" ON "users"("onboarded_by_lead_id");

-- DB-level first-lead-wins rule for active leads
CREATE UNIQUE INDEX IF NOT EXISTS "uq_shop_leads_phone_active_first_lead"
ON "shop_leads"("phone")
WHERE status IN ('open', 'contacted', 'claimed');
