ONE WAY v52 — RESET TOURNAMENT DATA FIX

The error "DELETE requires a WHERE clause" came from the old Supabase
admin_reset_tournament_v2 function.

DEPLOY:
1. Supabase -> SQL Editor -> New Query.
2. Run supabase_v52_RESET_FIX_RUN_THIS.sql.
3. The Reset Tournament Data button should work immediately after SQL succeeds.
4. Replacing index.html with v52 is optional for functionality, but recommended
   so the visible badge/footer show LIVE BUILD v52 / Build FINAL v52.

The reset does NOT erase editable prize/payment/rule settings.
