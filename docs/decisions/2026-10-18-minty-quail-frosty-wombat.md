# minty-quail — The plan is read through its methods (row 4a) · 2026-11-21

**What was asked.** Row 4a of minty-quail's `event-interface.md` (the tests, the probes and the cost table read
through the methods), designed by Opus as three pull requests; this is the first, "the plan is read through its
methods", built as #1604 by a Sonnet agent from a first agent's pushed work that a usage limit stopped, and the last of
the three to merge, so row 4a is built with it. The rule it serves: a field is not an API, and a caller asks (section
2.1's four rules; minty-lemur #785, #794).

**What was built.** One scripted rewrite (the scripts in the pull request's description): the suites, rigs and probes
ask the plan (`EventPlan`) what they read off it (`row()`, `row_id()`, `placed_at()`, `walks()`, `faces()`,
`is_spent()`, `gate()`), each replacement one `tools/field_answers.py` confirms returns exactly the field, and a row
field read through a plan asks the row's method where one answers (the design's F2). Then, as the design's F1 picks,
the plan's last six public fields (`def`, `position`, `path`, `facing`, `spent`, `gate_state`) are private and their
lines leave `tools/test_only_members.txt`. Two writes of a plan's position in `tests/test_unit_draw.gd` site the plan the
way the game does (`stand_where()`).

**Merged three times.** Main's #1600, #1601 and #1603 each merged in; every conflicting test file took main's side and
the script ran again on it, and the hand edits were checked to be still there after each. `tools/field_answers.py`
answers nothing for a field already private, so a rerun on a branch where the fields are private runs it against
main's `event_plan.gd`.

**Left for row 4b:** reads of a row's field through `plan.row()` that no row method answers (`kind`, `solid_parts`,
`on_her_way`, `placement`, `guard_sides` and three more).

**Open to overturn:** the design's forks F1 to F6, built on the designer's picks.
