ONE WAY Grass 4s — FINAL v28 DIRECT CONFIRMATION

FIXED
Confirmation links now behave like a separate page.

When a teammate opens:
  ?confirm=<their-team-token>

THEY IMMEDIATELY SEE
- PLAYER CONFIRMATION
- Confirm Your Spot
- Team name
- Player names
- "Yes, I am committed to playing for this team."
- Rules agreement
- Yes — Confirm My Spot

THEY DO NOT SEE FIRST
- Home page
- Hero
- Navigation
- Registration form
- Pool Builder
- Captain Contacts
- Schedule / standings / bracket

The browser detects the confirmation token in the HEAD before the main page
renders, preventing the normal Home page from flashing first.

Back to Tournament Site removes the confirmation token and returns to Home.

DEPLOY
1. Replace GitHub index.html with v28 index.html.
2. Commit / redeploy.
3. Hard refresh.
4. Footer on the normal site should show Build FINAL v28.
5. Test by opening one real confirmation link in an incognito/private tab.

SUPABASE
No new SQL is required for this v28 routing fix.
