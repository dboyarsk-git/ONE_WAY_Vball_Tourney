ONE WAY v51 — POOL CONFIRM MODAL KILL + BUILD CHECK

POOL PLAY:
- 25th point auto-finalizes and locks.
- Pool confirm modal is blocked in multiple places.
- Any stale pool confirm modal is forcibly closed.
- Confirm button cannot run for pool matches.
- Retry-save cannot reopen pool confirmation.

BUILD CHECK:
- Under Live Sync you MUST see: LIVE BUILD v51
- Footer says Build FINAL v51
- Page title includes v51

NO NEW SUPABASE SQL REQUIRED.

DEPLOY:
1. Replace the live index.html with v51.
2. Commit/deploy.
3. Open this exact fresh URL:
   https://onewaygrass.churchofnewhope.org/?v=51
4. Verify LIVE BUILD v51 is visible under Live Sync.
5. If you do NOT see LIVE BUILD v51, the custom domain/browser is still serving an older cached file.
6. Once v51 is visible, test a pool match to 25.
