ONE WAY Grass 4s — FINAL v17

INCLUDES ALL v16 INTEGRITY FIXES
- Dynamic 8–16 team formats.
- Stronger private skill-level pool balancing.
- Skill level ONLY influences initial pool balance.
- Live-sync DELETE handling.
- Pending-confirmation protection after pools lock.
- Result-correction invalidation through QF -> SF -> Final.
- Same-pool QF rematches avoided whenever mathematically possible.
- Teams / Schedule / Standings / Bracket show NOT FINALIZED / PENDING REVIEW 16-team outlines before locking.

NEW IN v17
- Mobile registration agreement checkbox can no longer inherit full-width form-input styling.
- Agreement text wraps completely inside the phone screen.
- Player confirmation rows, roster names, and confirmation link are mobile-safe.
- Automatic captain thank-you/confirmation email support.
- Email includes the link for all teammates to confirm.
- Email failure never deletes or rolls back the registration; the copyable link remains available.
- Failed email includes a Retry Email button.

DEPLOY ORDER
1. Supabase -> SQL Editor -> New Query.
2. Run supabase_v17_integrity_email_patch.sql.
3. Confirm Success.
4. Set up/deploy the included Edge Function (see EMAIL_SETUP_README.txt).
5. GitHub -> replace index.html with v17 index.html.
6. Commit and hard refresh.
7. Footer should show Build FINAL v17.

If email is not configured yet, registration still works normally and displays the copyable confirmation link.
