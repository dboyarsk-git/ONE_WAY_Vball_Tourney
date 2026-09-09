ONE WAY Grass 4s — Fresh GitHub Pages Build

UPLOAD INSTRUCTIONS
1. Delete the old repository files if you want a clean reset.
2. Upload index.html to the ROOT of the repository.
3. GitHub Settings → Pages.
4. Source: Deploy from a branch.
5. Branch: main.
6. Folder: /(root).
7. Save and wait for deployment.
8. Hard refresh the live site (Cmd+Shift+R on Mac).

DEMO ADMIN PIN
146

CURRENT FEATURES
- 16 teams, 4 pools of 4, 4 courts
- 24 pool matches, 3 guaranteed per team
- Pool play: one set to 25, hard cap at 25
- Automatic standings: wins → point differential → points for → original slot
- Top 2 from each pool advance to an 8-team bracket
- Bracket: best 2 of 3, sets to 21 / 21 / 15, win by 2
- Full-screen flip-style mobile scoring
- Tap either side to add a point
- Minus buttons and undo
- Switch sides
- Completed pool matches and bracket matches lock
- Admin can unlock a completed match
- Team names, payment status, and check-in status
- Data persists in the browser with localStorage

IMPORTANT
This version is a single-device / single-browser demo. It does NOT sync live between different phones yet.
The next version will add a real backend/database (for example Supabase or Firebase) so multiple scorers and spectators see the same live scores.
