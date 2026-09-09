ONE WAY Grass 4s — FINAL v23 ADMIN PRIZE

NEW
- First-place prize is now stored in Supabase.
- Admin can change it without editing GitHub or code.
- Home page updates automatically for everyone.
- Admin controls are directly inside the First Place Prize card.
- Enter a dollar amount and click Save Prize.
- Set to TBD clears the public dollar amount.

ADMIN FLOW
1. Enter Admin mode.
2. Home -> First Place Prize.
3. Enter the amount, e.g. 800.
4. Click Save Prize.
5. Everyone sees: First Place Prize: $800.
6. To hide the amount again, click Set to TBD.

DEPLOY
1. Supabase -> SQL Editor -> New Query.
2. Run supabase_v23_admin_prize.sql.
3. Replace GitHub index.html with the v23 index.html.
4. Commit + hard refresh.
5. Footer should show Build FINAL v23.
