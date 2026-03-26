-- Harden coin model integrity and reversal race safety

-- Keep new writes safe while allowing existing historical data to be remediated separately.
ALTER TABLE "coin_wallets"
  ADD CONSTRAINT "chk_coin_wallets_balance_non_negative"
  CHECK ("balance" >= 0) NOT VALID;

ALTER TABLE "coin_lots"
  ADD CONSTRAINT "chk_coin_lots_original_amount_positive"
  CHECK ("original_amount" > 0) NOT VALID;

ALTER TABLE "coin_lots"
  ADD CONSTRAINT "chk_coin_lots_remaining_amount_non_negative"
  CHECK ("remaining_amount" >= 0) NOT VALID;

ALTER TABLE "coin_lots"
  ADD CONSTRAINT "chk_coin_lots_remaining_lte_original"
  CHECK ("remaining_amount" <= "original_amount") NOT VALID;

ALTER TABLE "coin_ledger_entries"
  ADD CONSTRAINT "chk_coin_ledger_entries_amount_positive"
  CHECK ("amount" > 0) NOT VALID;

CREATE INDEX IF NOT EXISTS "idx_coin_ledger_reference_entry"
  ON "coin_ledger_entries"("reference_entry_id");

-- Ensure a credit entry can be reversed only once, while preserving flexibility for other reference use-cases.
CREATE UNIQUE INDEX IF NOT EXISTS "uq_coin_ledger_reversal_reference_entry"
  ON "coin_ledger_entries"("reference_entry_id")
  WHERE "action_type" = 'reversal' AND "reference_entry_id" IS NOT NULL;
