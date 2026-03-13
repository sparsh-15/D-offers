-- CreateEnum
CREATE TYPE "campaign_status_enum" AS ENUM ('draft', 'pending_payment', 'paid', 'queued', 'sending', 'completed', 'cancelled', 'failed');

-- CreateEnum
CREATE TYPE "delivery_status_enum" AS ENUM ('pending', 'sent', 'delivered', 'opened', 'clicked', 'failed');

-- CreateTable
CREATE TABLE "campaigns" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "shopkeeper_id" UUID NOT NULL,
    "offer_id" UUID,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "banner_url" TEXT,
    "banner_type" TEXT NOT NULL DEFAULT 'template',
    "shop_category" TEXT NOT NULL,
    "channels" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "campaign_status_enum" NOT NULL DEFAULT 'draft',
    "target_city" TEXT,
    "target_area" TEXT,
    "target_pincode" TEXT,
    "target_state" TEXT,
    "target_age_min" INTEGER,
    "target_age_max" INTEGER,
    "target_gender" TEXT,
    "estimated_audience" INTEGER NOT NULL DEFAULT 0,
    "selected_audience_size" INTEGER NOT NULL DEFAULT 0,
    "actual_audience_reached" INTEGER NOT NULL DEFAULT 0,
    "whatsapp_unit_price" DECIMAL(8,2),
    "inbox_unit_price" DECIMAL(8,2),
    "total_cost" DECIMAL(12,2) NOT NULL,
    "payment_status" "payment_status_enum" NOT NULL DEFAULT 'pending',
    "payment_method" "payment_method_enum",
    "transaction_id" TEXT,
    "scheduled_at" TIMESTAMPTZ(6),
    "launched_at" TIMESTAMPTZ(6),
    "completed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "campaign_deliveries" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "campaign_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "channel" TEXT NOT NULL,
    "status" "delivery_status_enum" NOT NULL DEFAULT 'pending',
    "sent_at" TIMESTAMPTZ(6),
    "delivered_at" TIMESTAMPTZ(6),
    "opened_at" TIMESTAMPTZ(6),
    "clicked_at" TIMESTAMPTZ(6),
    "error_message" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "campaign_deliveries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inbox_messages" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "customer_id" UUID NOT NULL,
    "campaign_id" UUID,
    "shopkeeper_id" UUID,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "banner_url" TEXT,
    "offer_id" UUID,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "read_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inbox_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "campaign_templates" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "banner_url" TEXT NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "campaign_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "campaign_pricing" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "channel" TEXT NOT NULL,
    "price_per_message" DECIMAL(8,2) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "campaign_pricing_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_campaigns_shopkeeper_status" ON "campaigns"("shopkeeper_id", "status");

-- CreateIndex
CREATE INDEX "idx_campaigns_shopkeeper_created_desc" ON "campaigns"("shopkeeper_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_campaigns_status_scheduled_at" ON "campaigns"("status", "scheduled_at");

-- CreateIndex
CREATE INDEX "idx_campaign_deliveries_campaign_status" ON "campaign_deliveries"("campaign_id", "status");

-- CreateIndex
CREATE INDEX "idx_campaign_deliveries_customer_created_desc" ON "campaign_deliveries"("customer_id", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "uniq_campaign_delivery_channel" ON "campaign_deliveries"("campaign_id", "customer_id", "channel");

-- CreateIndex
CREATE INDEX "idx_inbox_messages_customer_read_created_desc" ON "inbox_messages"("customer_id", "is_read", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_inbox_messages_campaign_id" ON "inbox_messages"("campaign_id");

-- CreateIndex
CREATE INDEX "idx_campaign_templates_category_active" ON "campaign_templates"("category", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "campaign_pricing_channel_key" ON "campaign_pricing"("channel");

-- AddForeignKey
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_shopkeeper_id_fkey" FOREIGN KEY ("shopkeeper_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_offer_id_fkey" FOREIGN KEY ("offer_id") REFERENCES "offers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaign_deliveries" ADD CONSTRAINT "campaign_deliveries_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaign_deliveries" ADD CONSTRAINT "campaign_deliveries_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inbox_messages" ADD CONSTRAINT "inbox_messages_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inbox_messages" ADD CONSTRAINT "inbox_messages_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inbox_messages" ADD CONSTRAINT "inbox_messages_shopkeeper_id_fkey" FOREIGN KEY ("shopkeeper_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

