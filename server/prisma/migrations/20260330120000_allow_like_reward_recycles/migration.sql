-- Allow like/unlike reward cycles by removing strict per-source uniqueness.
-- Idempotency uniqueness remains enforced via idempotency_key.

DROP INDEX IF EXISTS "uq_coin_ledger_user_action_source";
DROP INDEX IF EXISTS "uq_reward_events_user_action_source";

CREATE INDEX IF NOT EXISTS "idx_coin_ledger_user_action_source"
  ON "coin_ledger_entries"("user_id", "action_type", "source_ref");

CREATE INDEX IF NOT EXISTS "idx_reward_events_user_action_source"
  ON "reward_events"("user_id", "action_type", "source_ref");
