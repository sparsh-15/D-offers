# MyOffers Role Wise Development Plan

This markdown file is the editable source for updates.
Keep this in sync with `docs/MyOffers Role Wise Development Plan.pdf`.

## Latest Updates (2026-02-24)

1. Backend database migration completed to PostgreSQL + Prisma runtime.
2. Mongo runtime dependency removed from active backend startup path.
3. Admin seed flow implemented using env configuration:
   - `ADMIN_PHONE`
   - `ADMIN_NAME`
   - `ADMIN_ROLE`
   - `ADMIN_SEED_ENABLED`
4. Render deployment issue identified as old Mongo-based commit being deployed.
5. Agent coupon governance improved:
   - Coupon code now auto-generated from agent name + agent id + random token.
   - Last two digits encode discount percentage for percentage coupons.
   - Agent-level max discount cap enforced (`max_coupon_discount_percent`, default 50).

## Sync Rule

Whenever role-wise development changes, update this `.md` first and regenerate the PDF.
