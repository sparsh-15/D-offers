-- CreateTable
CREATE TABLE "app_settings" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    CONSTRAINT "app_settings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "app_settings_key_key" ON "app_settings"("key");

-- Seed global coupon cap (used for all SSA/SA)
INSERT INTO "app_settings" ("id", "key", "value")
SELECT uuid_generate_v7(), 'max_coupon_discount_percent', '50'
WHERE NOT EXISTS (SELECT 1 FROM "app_settings" WHERE "key" = 'max_coupon_discount_percent');
