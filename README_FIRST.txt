ONE WAY Grass 4s — FINAL v26

FIXED
- Pool Builder now displays as a normal full-width Admin panel.
- Captain Contacts now displays as a normal full-width Admin panel.
- Fixed the Admin CSS bug that caused Admin DIV sections to become inline.
- Admin buttons and dynamic status controls retain the correct layout.

SCORING UX
Before pools are finalized:
- Schedule clearly says live scoring is locked.
- No Keep Score buttons are shown.

After Admin locks pools & generates the official schedule:
- Orange Keep Score button appears on every official pool match.
- Clicking it opens the full-screen scorekeeper.
- Completed matches display View Score.

SCORING CODE CHECK
- Pool +1 / -1 controls are connected.
- Pool scores cap at 25.
- At 25, scorekeeper prompts to confirm the match.
- Confirmed match is marked final and locked.
- Final pool results feed standings.
- Bracket Keep Score buttons use the same score overlay.
- Bracket sets use 21 / 21 / 15, win by 2.
- JavaScript syntax check passed.

No new Supabase SQL is required for v26 if v25 SQL has already been run.

DEPLOY
1. Replace GitHub index.html with v26 index.html.
2. Commit.
3. Hard refresh.
4. Footer should show Build FINAL v26.
