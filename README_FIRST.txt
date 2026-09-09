ONE WAY Grass 4s — v10 Forced Full-Viewport Scorekeeper

FIX
The scorekeeper now:
- hides the underlying site while scoring
- uses a forced header / scoreboard / controls grid
- measures the device's live Visual Viewport in pixels
- resizes itself whenever Safari changes viewport size
- fills all available screen space even if native fullscreen is blocked
- still attempts native Fullscreen API / WebKit fullscreen

NO NEW SUPABASE SQL IS REQUIRED FOR THIS VISUAL FIX.

INSTALL
1. Replace GitHub index.html with the v10 index.html.
2. Commit.
3. Wait for GitHub Pages.
4. Hard refresh.
5. Footer should say Build v10.
