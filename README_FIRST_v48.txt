ONE WAY v48 — SCORING FIX + BACKEND SELF-CHECK

WHY THE POPUP HAPPENED
The normal tournament database can be connected while the protected
score-lock RPC is missing/unavailable. Those are separate backend paths.

v48 fixes the misleading UI:
- The Schedule only says "Live scoring is ready" after the scoring backend
  passes a real backend health check.
- Keep Score is disabled if the protected scoring backend is not ready.
- Error messages now point to the exact scoring repair instead of saying
  the entire database is unreachable.
- One-phone-at-a-time scoring protection is preserved.

DEPLOY IN THIS ORDER
1. Supabase -> SQL Editor -> New Query.
2. Run supabase_v48_SCORING_REPAIR_RUN_THIS.sql.
3. Wait for Success.
4. Replace the custom-domain/GitHub index.html with the v48 index.html.
5. Commit/deploy.
6. Fully close and reopen the browser on iPad.
7. Footer should show Build FINAL v48.
8. Schedule should show "✓ Live scoring is ready." and Keep Score should open.

The scoring repair does NOT delete teams, registrations, pools,
schedule, bracket, or existing scores.
