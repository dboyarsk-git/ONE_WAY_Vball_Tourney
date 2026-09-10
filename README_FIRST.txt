ONE WAY v39

FIXES
- Fixed the v38 Registration runtime variable error.
- Fixed the v38 Pool Builder runtime variable error.

MOBILE MENU
- Scroll down -> menu slides out of view.
- Scroll up -> menu returns.
- Near the top of the page -> menu stays visible.
- Small iPhone bounce movements are ignored.
- Desktop navigation is unchanged.

DATABASE
- v39 itself requires no new Supabase migration.
- If v38 backend SQL has not yet been run, use the included supabase_v38_run_this.sql.

DEPLOY
1. Replace GitHub index.html with this v39 index.html.
2. Commit/deploy.
3. Hard refresh.
4. Footer should show Build FINAL v39.
