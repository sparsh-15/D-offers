-- CreateEnum
CREATE TYPE "callback_status_enum" AS ENUM ('pending', 'completed', 'cancelled');

-- DropForeignKey
ALTER TABLE "shop_leads" DROP CONSTRAINT "shop_leads_csa_id_fkey";

-- DropForeignKey
ALTER TABLE "shop_leads" DROP CONSTRAINT "shop_leads_ssa_id_fkey";

-- DropForeignKey
ALTER TABLE "users" DROP CONSTRAINT "users_onboarded_by_lead_id_fkey";

-- AlterTable
ALTER TABLE "shop_leads" ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "users"
ADD COLUMN "about_me" TEXT,
ADD COLUMN "dob" TIMESTAMPTZ(6),
ADD COLUMN "gender" TEXT,
ADD COLUMN "occupation" TEXT;

-- CreateTable
CREATE TABLE "login_history" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "user_id" UUID NOT NULL,
    "role" "role_enum" NOT NULL,
    "phone" TEXT NOT NULL,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "logged_in_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "login_history_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "callback_requests" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
    "offer_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "message" TEXT,
    "status" "callback_status_enum" NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "callback_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_login_history_user_logged_in_desc" ON "login_history"("user_id", "logged_in_at" DESC);

-- CreateIndex
CREATE INDEX "idx_callback_requests_offer_created_desc" ON "callback_requests"("offer_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_callback_requests_customer_created_desc" ON "callback_requests"("customer_id", "created_at" DESC);

-- AddForeignKey
ALTER TABLE "login_history" ADD CONSTRAINT "login_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shop_leads" ADD CONSTRAINT "shop_leads_ssa_id_fkey" FOREIGN KEY ("ssa_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shop_leads" ADD CONSTRAINT "shop_leads_csa_id_fkey" FOREIGN KEY ("csa_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
