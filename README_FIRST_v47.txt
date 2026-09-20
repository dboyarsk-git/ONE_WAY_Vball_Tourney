ONE WAY v47 — EDITABLE PRIZE TEXT

WHAT CHANGED
- First Place Prize is no longer limited to a dollar amount.
- Second Place Prize is no longer limited to a dollar amount.
- Admin can type the actual prize description, for example:
    Champion T-Shirts + Trophy
    Runner-Up T-Shirts
    Medals
    Gift Cards
    TBD
- "Set to TBD" still works.
- Old numeric prize database fields/functions are preserved for history.
- If an old dollar prize exists, the v47 migration converts it into readable text once.
- The stale "First Place Prize: TBD" line is removed from the Tournament Format card so the dedicated Prize card is the single public source.
- v46 Free/Paid mode remains unchanged.
- v45 scoring repair behavior remains unchanged.
- v44 mobile scroll fix remains unchanged.

DEPLOY
1. Run supabase_v47_EDITABLE_PRIZE_TEXT_RUN_THIS.sql in Supabase.
2. Replace GitHub root index.html with the v47 index.html.
3. Commit/deploy and reload.
4. Footer should say Build FINAL v47.
