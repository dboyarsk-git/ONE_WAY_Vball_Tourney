ONE WAY v42

WHAT CHANGED
- Player-by-player confirmation is OFF for ONE WAY.
- Captain submits team name, captain name/phone/email, and all four player names once.
- First 16 complete submissions become Registered immediately; extras are Waitlisted.
- Pool eligibility stays: Registered + Paid + Checked In.
- Before pools lock: public identity is TEAM NAME ONLY.
- After pools lock:
  • Teams page = Team Name + Captain Name
  • Schedule = Team Name + Captain Name
  • Bracket = Team Name + Captain Name
  • Standings = Team Name only
  • Scorekeeper = Team Name only
- Captain phone/email and all four player names are kept in Admin.
- Anonymous direct reads of registration player names are removed.
- The old confirmation system is PRESERVED:
  • old backend confirmation RPCs/tables are not deleted
  • archive_confirmation_frontend_v41.html is included for reuse/reference

IMPORTANT DEPLOY ORDER
1. In Supabase SQL Editor, run: supabase_v42_run_this.sql
2. After it succeeds, replace GitHub root index.html with v42 index.html.
3. Commit/deploy.
4. Hard refresh / fully close and reopen on iPhone.
5. Footer should show Build FINAL v42.

Do not deploy the v42 frontend before running the v42 SQL because registration uses the new register_team_oneway RPC.

FUTURE CONFIRMATION TOURNAMENT
- archive_confirmation_frontend_v41.html keeps the old confirmation-enabled frontend.
- CONFIRMATION_SYSTEM_RESTORE_FOR_FUTURE.sql restores the anonymous player-read policy that old frontend expected.
- Use that only for a separate/future tournament after reviewing its privacy setup.
