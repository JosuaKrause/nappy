# minty-quail — The live event and the warning are read through their methods (row 4a) · 2026-11-21

**What was asked.** Row 4a of minty-quail's `event-interface.md` (the tests, the probes and the cost table read
through the methods), designed by Opus as three pull requests; this is the second, "the live event and the warning are
read through their methods", built as #1603 by a Sonnet agent from a first agent's pushed work that a usage limit
stopped. The rule it serves: a field is not an API, and a caller asks (section 2.1's four rules; minty-lemur #785,
#794).

**What was built.** One scripted rewrite (the scripts in the pull request's description): the suites, rigs and probes
ask the live event (`EventInstance`) and the warning (`PendingWarning`) what they read off them, each replacement one
`tools/field_answers.py` confirms returns exactly the field, and a row field read through a live event's `def` asks
`row()` and the row's method where one answers (the design's F2). Then, as the design's F1 picks, the live event's
`def`, `path` and `gave_up` and the warning's `def` are private, and the live event's three yes-or-no properties
(`is_finished`, `is_leaving`, `is_parked`) are deleted for `is_gone()`, `is_on_its_way_out()` and `has_parked()`.
Streaming's two reads that row 3b left (`event_streaming.gd`) and the spawner's `instance.def` ask the methods; the
lines of `tools/field_reads.txt` and `tools/test_only_members.txt` that kept them public for the suites go, and the
manager's `world` and the live event's `transition` stay listed with their reasons pointing past row 4a.

**Against the row's text:** the row says no line under `src/` changes; the design's F1 makes the fields private in
the same pull request, which changes the four files above mechanically, so no field stays public only for tests.

**Merged twice.** Main's #1600 (curly-stork) merged clean; #1601 (row 4a's row reads) conflicted on one line each in
eight test files, resolved by taking main's side and rerunning the script, as the design's section 5 says.

**Left for row 4b:** 34 reads through `x.row().<field>` with no row method (a row's `id`, a spec's field, writes).

**Open to overturn:** the design's forks F1 to F6, built on the designer's picks.
