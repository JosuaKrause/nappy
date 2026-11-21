# minty-quail — The row is asked where it has the answer (row 4a) · 2026-11-20

**What was asked.** Row 4a of minty-quail's `event-interface.md` (the tests, the probes and the cost table read
through the methods), designed by Opus as three pull requests built side by side; this is the third, "the row is asked
where it has the answer", built by a Sonnet agent as #1601. The rule it serves: a field is not an API, and a caller asks
(section 2.1's four rules; minty-lemur #785, #794).

**What was built.** One scripted rewrite: every read of a row's field in `tests/` and `tools/cost_table.gd` that a row
method answers asks the method (603 uses in 88 files, `outer_radius` to `heard_within()`, `pursuit != null` to
`pursues()` and the rest), each replacement one `tools/field_answers.py` confirms returns exactly that field, so every
check reads the same value; the script is in the pull request's description, so a branch merging main reruns it. The
cost table types its two loop variables and loses its opt-out line. No line under `src/` changes and no row field
changes visibility: the row's fields stay public until row 4b writes a row as its parts. The suites' check total on CI
equals main's at the base.

**The builder's change to the design's script:** a row field read through a plan's, live event's or warning's `def`
is left alone (`body.def.outer_radius`), since those lines belong to row 4a's other two pull requests, which read
through the plan and the live event; without it the rewrite touched nineteen files outside its own.

**Left for later rows:** a row's fields written by the tests (row 4b, which builds a row through a draft), reads no
row method answers (`pursuit.warns_for`, `kind != AMBIENT`; row 4b's parts), and the reads under `src/`, which are not
this row's.

**Open to overturn:** the design's forks F3 to F6 (the three pull requests built side by side and rerun on conflict;
which class a use belongs to decided by the engine's parse; the script kept in the description, not under `tools/`;
the old-name search reported grouped by reason with counts).
