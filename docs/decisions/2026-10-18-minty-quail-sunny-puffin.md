# minty-quail — Every row's every answer is printed (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus as
ten pull requests; this is the first, the parity proof the other nine run on base and branch, built by a Sonnet agent as
#1605. The refactor holds test parity and remeasures once at the end (inbox #813 in curly-moose), and the catalogue is a
balance file in which no number a player can feel may move, so every step that rewrites a row needs a check that every
row still answers every question the same.

**What was built.** `tests/probes/row_fingerprint.gd` prints every public method's answer on every catalogue row and
every script variable of the row and of each settings object it holds, recursively (`RF`), one hash per copy the game
makes of a row, the director's copy at every heat included (`RFV`), and the rows the region and seal planners stand on three
cities over five days (`RFP`), closed by an `RF_DONE` line so a run that stopped early shows. Its header says where the
output goes (standard output, never committed), how a step compares it (base and head in two checkouts, then a diff) and
what a diff may show. Runs on main give the same output every time. No line under `src/` changes.

**Why it prints variables as well as answers.** The review of #1605 found that settings no method reads (the walls'
`guard_sides`, a pursuit's `warns_for`, the van's `standing_offset` and a dozen more) changed no line when altered, and
they are what the later steps move into parts; printed as variables, a setting that moves shows the part's answer
against the base's value. It reads them the way a save would, as a dump of state, not one member as an API.

**What it leaves out:** a copy of a row the game never makes. The design's prototype also printed every row without its
aftermath through `EventCatalogue.without_its_aftermath()`, which only the catalogue calls; reaching it from a probe
by name would have got round `tools/check_test_only_members.py`, so the probe prints the two copies the game makes that
way (`building_fire()`, `explosion_outside()`) and nothing else. The raid's pacing patrol, built inline in
`ResistanceHappenings._maybe_raid()`, is not a catalogue copy either: the steps that touch it print it from a throwaway
line, as the design says.
