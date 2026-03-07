-- Optional: enforce one coupon per (agent_id, discount_type, discount_value).
-- Run this manually in your DB (e.g. Neon SQL editor) if you want the constraint.
-- Only run if you have no duplicate rows; otherwise remove duplicates first.

CREATE UNIQUE INDEX IF NOT EXISTS "coupons_agent_discount_unique"
  ON "coupons" ("agent_id", "discount_type", "discount_value");
