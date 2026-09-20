ONE WAY v49 — CONFIRM SCORE FIX

FIX:
- Running score still uses protected safe score saving.
- Confirm Match / Confirm Set now uses a dedicated atomic backend RPC.
- It confirms the CURRENT server score instead of relying on a possibly stale
  browser score_revision.
- Safe same-operation retry prevents double-confirmation.
- Pool match: 25-point hard cap is validated server-side.
- Bracket: 21/21/15 and win-by-2 are validated server-side at confirmation.
- Bracket set confirmation cannot accidentally append the same set twice.
- Existing teams, pools, schedules, registrations, and scores are untouched.

DEPLOY:
1. Supabase -> SQL Editor -> run supabase_v49_CONFIRM_SCORE_FIX_RUN_THIS.sql
2. Replace live index.html with v49 index.html
3. Commit/deploy
4. Fully close/reopen the browser on the iPad
5. Footer should say Build FINAL v49
6. Test a pool match to 25 and tap Confirm

The already-saved 25-16 score is not erased by this patch.
