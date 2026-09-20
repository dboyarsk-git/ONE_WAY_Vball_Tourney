ONE WAY v43

MOBILE BOTTOM-SCROLL FIX
- Fixes the iPhone/iPad glitch where the mobile menu could rapidly hide/show
  when swiping all the way to the bottom of the page.
- The nav now stays hidden while the viewport is at the bottom.
- iOS rubber-band / bounce / layout-shift movement is ignored.
- A real upward scroll away from the bottom brings the nav back normally.
- Desktop behavior is unchanged.

No new Supabase SQL is required for v43.
If you already ran the v42 Supabase SQL, do NOT run anything new.

DEPLOY
1. Replace your GitHub root index.html with the v43 index.html.
2. Commit/deploy.
3. Fully close and reopen the page on iPhone/iPad, or hard refresh.
4. Footer should show Build FINAL v43.
