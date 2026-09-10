ONE WAY Grass 4s — FINAL v32 CAPTAIN PAYMENT

PAYMENT MODEL
- Captain is responsible for the full $60 team fee.
- Players do not manage individual payment statuses.
- Admin remains the only person who marks a team Paid / Unpaid.

HOME PAGE
Inside the First Place Prize card there is now a Payments section:
- Team Fee: $60
- Zelle: Admin-editable
- Cash instructions: Admin-editable
- Captain payment note: Admin-editable

CAPTAIN REGISTRATION COMPLETE SCREEN
After submitting a team, the captain sees:
- the teammate confirmation link
- $60 team fee
- current Zelle information
- current cash instructions
- reminder that Admin verifies payment

PLAYER CONFIRMATION PAGE
No payment controls were added. Players only confirm their roster spot and rules.

ADMIN
Home -> First Place Prize / Payments:
- edit Zelle phone/email
- edit cash instructions
- edit payment note
- Clear Zelle -> public display returns to TBD

DEPLOY
1. Supabase -> SQL Editor -> run supabase_v32_captain_payment.sql.
2. Replace GitHub index.html with v32 index.html.
3. Commit / redeploy.
4. Hard refresh.
5. Footer should show Build FINAL v32.
