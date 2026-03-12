CREATE TABLE "loan_applications" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v7(),
  "customer_id" UUID NOT NULL,
  "full_name" TEXT NOT NULL,
  "mobile_number" TEXT NOT NULL,
  "employment_type" TEXT NOT NULL,
  "monthly_salary_income" DECIMAL(14,2) NOT NULL,
  "loan_amount" DECIMAL(14,2) NOT NULL,
  "pan_number" TEXT NOT NULL,
  "bank_name" TEXT NOT NULL,
  "account_type" TEXT NOT NULL,
  "last_4_account_digits" TEXT NOT NULL,
  "cibil_consent" BOOLEAN NOT NULL DEFAULT false,
  "communication_consent" BOOLEAN NOT NULL DEFAULT false,
  "status" TEXT NOT NULL DEFAULT 'pending',
  "cibil_score" INTEGER,
  "eligibility_status" TEXT,
  "evaluated_at" TIMESTAMPTZ(6),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ(6) NOT NULL,

  CONSTRAINT "loan_applications_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "loan_applications_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "idx_loan_applications_customer_created_desc"
  ON "loan_applications"("customer_id", "created_at" DESC);

CREATE INDEX "idx_loan_applications_status"
  ON "loan_applications"("status");
