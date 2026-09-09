ONE WAY Grass 4s — FINAL v25 SAFE EDITABLE RULES

ADMIN CAN EDIT
- Non-Negotiables
- Conduct & Sportsmanship
- General Game Rules

LOCKED FROM TEXT EDITING
- Location & Schedule
- Registration & Tournament Format
- Scoring Format

WHY THEY ARE LOCKED
Those sections contain information that can affect the actual tournament
program: scheduled match times, pool structure, bracket advancement, score
limits, set format, and related calculations.

This prevents the public website from saying one thing while the scoring /
bracket engine is programmed to do something different.

PRIZE
The separate Admin Prize control remains editable because it is already a
real database setting and does not affect tournament calculations.

DEPLOY
1. Supabase -> SQL Editor -> New Query.
2. Run supabase_v25_safe_editable_rules.sql.
3. Replace GitHub index.html with v25 index.html.
4. Commit and hard refresh.
5. Footer should show Build FINAL v25.
