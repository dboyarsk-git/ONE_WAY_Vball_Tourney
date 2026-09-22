ONE WAY v53 — AUDITED HARDENING

Run supabase_v53_HARDENING_RUN_THIS.sql, then deploy index.html.
This patch is non-destructive.

Key fixes:
- stale score locks + revisions during Admin correction
- reopen-registration lock clearing
- stronger scoring backend health check
- old teammate-confirmation wording removed/sanitized
