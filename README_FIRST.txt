ONE WAY Grass 4s — FINAL v18

NEW
1. Paid / Unpaid and Checked In / Not Checked In are back BEFORE pools are finalized.
2. Those statuses follow the registration into the final balanced pool.
3. Statuses remain synchronized if Admin reopens and finalizes again.
4. Every pool match displays a reffing team.
5. 3-team pools: the idle third team refs automatically.
6. 4-team pools: ref duty rotates among idle teams.
7. Bracket QFs use non-advancing teams when available, otherwise Tournament Staff.
8. Semifinals use eliminated QF teams; Final uses an eliminated semifinal team.
9. Admin can override any OFFICIAL match ref to another available team or Tournament Staff.
10. Successful registration now opens a dedicated Registration Complete screen.
11. Captain gets Copy Link + native phone Share Link.
12. No automatic email is required.
13. Admin Captain Contacts includes Copy Confirmation Link for recovery.

DEPLOY
1. Supabase -> SQL Editor -> New Query.
2. Run supabase_v18_status_refs_share.sql.
3. Confirm Success.
4. GitHub -> replace index.html with v18 index.html.
5. Commit.
6. Hard refresh.
7. Footer should show Build FINAL v18.

The old Resend Edge Function can be left alone or deleted later. v18 does not call it.
