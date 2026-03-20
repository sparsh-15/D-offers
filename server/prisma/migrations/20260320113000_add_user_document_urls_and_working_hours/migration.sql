ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "shop_registration_document_url" TEXT,
  ADD COLUMN IF NOT EXISTS "gst_document_url" TEXT,
  ADD COLUMN IF NOT EXISTS "electricity_bill_document_url" TEXT,
  ADD COLUMN IF NOT EXISTS "aadhaar_document_url" TEXT,
  ADD COLUMN IF NOT EXISTS "pan_document_url" TEXT,
  ADD COLUMN IF NOT EXISTS "working_hours" TEXT;
