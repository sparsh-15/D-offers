-- Add audit log action for AI packs bulk import without resetting data
ALTER TYPE "audit_action_enum"
  ADD VALUE IF NOT EXISTS 'ai_packs_bulk_imported';
