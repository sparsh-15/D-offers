ALTER TABLE users
ADD COLUMN IF NOT EXISTS max_coupon_discount_percent integer NOT NULL DEFAULT 50;

ALTER TABLE users
DROP CONSTRAINT IF EXISTS chk_users_max_coupon_discount_percent;

ALTER TABLE users
ADD CONSTRAINT chk_users_max_coupon_discount_percent
CHECK (max_coupon_discount_percent >= 1 AND max_coupon_discount_percent <= 99);
