# amber-ibis — What the rules review found outside the rule files: a pelican check, two static checks, and a lethal-field walk that would ask nothing · 2026-11-25

The queue entry amber-ibis held five things the rules review found outside the rule files
(inbox #1267 in olive-ferret), none of them the player's request. The entry is fable-only, so
Fable wrote the design, pull request #1794 with its handover and its own record, and another model
built it from main. The design's readings are kept here where the build followed them; where the
build chose differently it says so.

## What each item came to

**The pelican cyclist has no illustrated PNG: built.** The player's words stand (inbox #437 in
minty-hedgehog: converted to PNG by the atlas bake and never a converted PNG), so the rule keeps a
check rather than being removed. `tests/test_atlas_events.gd` asks two things, since a PNG reaches
the game two ways: no picture of the pelican's two view tables has a file at its transfer path,
which the default bake would take over the SVG, and no PNG anywhere under `art/illustrated/` has
"pelican" in its name. Planted and removed: a 40x42 PNG at the side view's transfer path and a
stray pelican PNG in the rooftop family's folder failed three checks by name (the transfer PNG
fails both questions). *Rejected (the design's):* a refusal in the bake, which would name one
family in the baker while the other families' transfer rules are held by suites.

**Every street closure comes from the closure planner: built, as a static check.**
`tools/check_closure_writers.py`, which `tools/lint.sh` runs, reads `src/` as text and fails a call
of `close_streets()`, a `RoadClosure` or a class extending it built, a recipe closure listed, or the
closed ground written, anywhere but the sites its table allows, each a file and the function it
stands in, with its reason; an allowed site that no longer holds its kind of line fails too.
Planted in a copy of `src/`: a function in the event scheduler that builds a closure, closes
streets and writes the closed ground failed on all three lines. *Rejected (the design's):* a test
over a started day comparing the map's shut streets with the plan. `City` calls the planner as a
static, so the test would repeat the city's own call with the same stream to have a plan to compare
with, and it would see only the days and the moment it sampled. *The build's choice:* a site is
keyed by its function rather than by a count of lines, so a second closure in an allowed function
passes, and the fenced park is its own site (`CityMap._shut_the_spent_calm()`, which closes the
area `ClosurePlanner.calm_to_shut()` accepts first).

**No doc or comment names a suite that does not exist: built.** About eighty-five sentences named
`tests/test_events.gd`, `tests/test_routes.gd` or `test_crowd.gd`; each names the suite that
holds the check it speaks of, read off the check, and the split history in the suites' headers goes.
The mapping follows the design's reading, checked case by case against the suites. Three claims no
suite holds, and the sentences say so: that a field with no core is `Field.falloff` bit for bit
(`FieldSpec` and `docs/EVENTS.md`), that the narrow rows keep their whole share of the corridor
(`docs/CITY.md`), and that the corridor's depth array beats a dictionary (`Corridor`).
`tools/check_test_paths.py`, which `tools/lint.sh` runs, fails a `tests/` path or a bare
`test_<name>.gd` that names no file, in `AGENTS.md`, `CLAUDE.md`, `README.md`, the skills, the
top-level docs but `docs/DECISIONS.md`, and the comments of every `.gd` file under `src/`,
`tests/` and `tools/`; on main it found the eighty-five. It does not read the records, the
playtests, the queue or the review items, which may name a file that is gone or not written yet.
The pass probe's two comments are among the sentences fixed, so the queue item about them
(lilac-pelican, the parked probes that fail on main, its pass-probe item) now holds only what is
left of it, that `historical_def()` is public with no caller outside the probe.

**Five sentences that say something the code does not do: four fixed, one already true.** The
header of `tests/test_events_costs.gd` already said what its cases hold. The resistance package's
decay multiplier was compared with a main road's 0.6, a figure no ground has (the main road's own
is far lower); its docstring now places it between the two constants it sits between, harsher than
an alley's and far gentler than a main road's. That wording is a reading, since the original
comparison cannot be restored.

**A test walks a planned day and finds every lethal field kept clear: not built, because the walk
would ask nothing.** The design wrote the walk over planned days of several seeds and found no
field to ask, and the build confirmed why from the code: `EventScheduler.role_for()` gives a lethal
row placed on a tile the `WALL` role unless it is a one-shot, a wall is exempt
(`EventPlan.keeps_its_field_clear()`), and the catalogue's one one-shot, the burning building, has
no field. The one lethal row in a day's plan that keeps a field clear is the cyclist, which the
director sends at her and no dawn or unit places. A walk that finds no field passes with the rule
deleted, so none was written. `docs/EVENTS.md` and the events skill say which suites hold the
rule's pieces, why a walk finds nothing, and that the row that adds a lethal one-shot adds the
walk.

## Left open

- **The lethal-field rule binds nothing a day places today**, and the director asks one direction
  of it. Filed as the queue entry gray-bunny, nothing keeps a placed event out of a sent cyclist's
  lethal field.
- **The resistance package's meter multiplier** (0.5) was set beside a main road's old 0.6 and not
  re-derived when M117 re-derived the streets'. Filed as the queue entry minty-elk, the package's
  multiplier against the streets', which asks the player.
- **The frozen Codex fixture** (`tools/test_codex_hooks.py`) copies `tools/lint.sh` without the
  two new scripts. It passes, since the lint starts the test-path check only for a file the check
  reads and the fixture lints a playtest; a Codex lint of a `.gd` file or a governed doc would need
  them when Codex is brought back.
