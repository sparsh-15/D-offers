ALTER TABLE "shopkeeper_profiles"
ADD COLUMN "shop_images" TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE "shopkeeper_profiles"
ADD COLUMN "logo_url" TEXT;