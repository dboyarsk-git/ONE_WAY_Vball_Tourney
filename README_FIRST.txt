ONE WAY Grass 4s — v11

FIXED
- Schedule and Keep Score buttons render immediately, even while Supabase is connecting.
- A slow registration query can no longer block the tournament schedule.
- Live database data replaces the fallback schedule as soon as it arrives.
- Live-sync status can be tapped to retry.
- v10 full-viewport scorekeeper remains.
- All registration/admin features remain.

NO NEW SUPABASE SQL IS REQUIRED FOR THIS FIX.

INSTALL
1. Replace GitHub index.html with v11 index.html.
2. Commit and wait for Pages deployment.
3. Hard refresh.
4. Footer should show Build v11.
