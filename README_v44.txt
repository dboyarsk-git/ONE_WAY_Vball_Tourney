ONE WAY v44

MOBILE NAVIGATION FIX
- Mobile nav is no longer sticky.
- Mobile nav no longer auto-hides, expands, collapses, or changes page height.
- It sits below the header and naturally scrolls off-screen with the page.
- This removes the iPhone/iPad Safari bottom-of-page hide/show glitch loop.
- Desktop navigation remains sticky.

No new Supabase SQL is required.
If you already ran the v42 SQL, only replace index.html.

DEPLOY
1. Replace your GitHub root index.html with the v44 index.html.
2. Commit/deploy.
3. Fully close and reopen the browser/app on your phone.
4. Confirm the footer says Build FINAL v44.
