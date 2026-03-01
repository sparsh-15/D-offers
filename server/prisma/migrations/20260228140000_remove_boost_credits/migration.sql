-- Drop BoostCredit table (and its FKs)
DROP TABLE IF EXISTS "boost_credits";

-- Remove boost_credits column from subscription_plans
ALTER TABLE "subscription_plans" DROP COLUMN IF EXISTS "boost_credits";
