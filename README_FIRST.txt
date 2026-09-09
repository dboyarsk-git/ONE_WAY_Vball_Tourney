ONE WAY Grass 4s — FINAL v29

HOME PAGE ADMIN EDITING
All six public Home-page rule/info cards can now be edited in Admin mode:

- Location & Schedule
- Registration & Tournament Format
- Non-Negotiables
- Conduct & Sportsmanship
- Scoring Format
- Game Rules

The First Place Prize remains editable through its separate Admin Prize controls.

IMPORTANT
Editing these boxes changes the PUBLIC WORDING only.
For example, if Admin changes "Pool Play: 1 set to 25" to "1 set to 21",
the actual scoring engine will still be programmed to 25 until its code/database
logic is separately changed.

ALL v28 FEATURES ARE RETAINED
- direct confirmation link page
- register-page layout fixes
- scoring buttons after pool finalization
- paid/check-in
- refs
- dynamic pools/bracket
- Admin prize control

DEPLOY
1. Run supabase_v29_all_home_boxes_editable.sql in Supabase.
2. Replace GitHub index.html with the v29 file.
3. Commit/redeploy.
4. Hard refresh.
5. Footer should show Build FINAL v29.
