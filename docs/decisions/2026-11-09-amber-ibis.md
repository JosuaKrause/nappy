# amber-ibis — What the rules review found outside the rule files: a pelican check, two static checks, and a lethal-field walk that would ask nothing · 2026-11-25

The queue entry amber-ibis held five things the rules review found outside the rule files
(inbox #1267 in olive-ferret). None was the player's request; each was a defect the review named.
Each item was checked against main as the refactor left it before anything was built.

## What each item came to

**The pelican cyclist has no illustrated PNG: built.** The player's word stands (inbox #437 in
minty-hedgehog), so the rule keeps its check and is not removed.
`tests/test_atlas_events.gd` holds it beside the case that holds the dogs' transfers, and asks
two things because a PNG can reach the game two ways: no picture of the pelican's two view
tables has a file at its transfer path, and no PNG under `art/illustrated/` has "pelican" in its
name. Planted and removed: a 40x42 PNG at the side view's transfer path and a stray PNG in the
rooftop family's folder each failed their check by name. *Rejected:* a refusal in the bake, which
would name one family in the baker while the other families' transfer rules are held by suites.

**Every street closure comes from the closure planner: built, as a static check.**
`tools/check_closure_writers.py`, which `tools/lint.sh` runs, reads `src/` as text and fails a
call of `CityMap.close_streets()`, a `RoadClosure` (or a class extending it) built, a recipe
closure listed, or the closed ground written, anywhere but the sites its table allows, each with
its reason; an allowed site that is gone fails too. Planted in a copy of `src/`: a function in
the event scheduler that builds a closure, closes streets and writes the closed ground failed on
all three lines. *Rejected:* a test over a started day comparing the map's shut streets with the
plan. `City` calls the planner as a static, so the test would have to repeat the city's own call
with the same stream to have a plan to compare with, and it would see only the days and the
moment it sampled; a closure made mid-day, or on a path no sampled day takes, would pass.

**No doc or comment names a suite that does not exist: built.** The sentences that named
`tests/test_events.gd`, `tests/test_routes.gd` and `test_crowd.gd` name the suite that holds
the check each speaks of, found by reading the check and not by the suite's name. Four say that
no suite holds the claim: that a field with no core is `Field.falloff` bit for bit
(`FieldSpec.emission_at_distance()`, and `docs/EVENTS.md`), that the narrow rows keep their
share of the corridor (`docs/CITY.md`), and that the corridor's depth array is faster than a
dictionary (`Corridor`). `tools/check_test_paths.py`, which `tools/lint.sh` runs, keeps it so: it
fails a `tests/` path or a bare `test_<name>.gd` that does not exist, in `CLAUDE.md`,
`README.md`, the skills, the top-level docs and the comments of every `.gd` file under `src/`,
`tests/` and `tools/`. It does not read the records, the playtests, the queue or the review
items, which may name a file that is gone or not there yet. The pass probe's two comments are
fixed with the rest, so the queue item about them (lilac-pelican, the pass probe's comments) now
holds only what is left of it, the function nothing outside the probe calls.

**Five sentences that say something the code does not do: four fixed, one already true.** The
header of `tests/test_events_costs.gd` already says what its cases hold. The resistance
package's decay multiplier was compared with a main road's 0.6, a figure no ground has; the
docstring states the two relations that hold, harsher than an alley's multiplier and far gentler
than a main road's. That wording is a reading, since the original comparison cannot be restored.

**A test walks a planned day and finds every lethal field kept clear: not built, because the walk
would ask nothing.** The case was written in `tests/test_events_scheduler.gd` over the shared
city's fourteen days, the same run with its calm used up, the taught day of four seeds and a late
day of two more cities, and it found no field to ask. A probe of the fourteen days says why:
every lethal row a day places on a tile is a wall (`reversing_lorry`, `abduction`,
`firefight`) or a pursuer (`charging_dog`, `alley_robbery`), and both are exempt
(`EventPlan.keeps_its_field_clear()`). `EventScheduler.role_for()` gives a lethal row placed on
a tile the `WALL` role unless it is a one-shot, and the catalogue's one one-shot, the burning
building, is not lethal. The one row in a day's plan that keeps a field clear is the cyclist, which
the director sends at her and no dawn or unit places. A walk that finds no field passes with the
rule deleted, so it was not committed. `docs/EVENTS.md` and the events skill say what is true
instead: which two suites hold the rule's pieces, why a walk finds nothing, and that the row that
adds a lethal one-shot adds the walk.

## Left open

- **The lethal-field rule binds nothing a day places today.** Its branch in
  `StreetInvalidation.room_around()` is reached only with a plan built by hand
  (`tests/test_masts.gd`). Whether the rule should bind more (a lethal wall beside a route, say)
  is a design question nobody has asked.
- **The director asks one direction of the rule.** A row sent ahead of her is kept out of the
  fields placed plans keep clear (`EventDirector._clear_of_the_plans()`), and nothing keeps placed
  rows out of the field of a lethal row that is sent, the cyclist's. Not investigated here.
- **The frozen Codex fixture** (`tools/test_codex_hooks.py`) copies `tools/lint.sh` without the
  two new scripts; it needs them when Codex is brought back.
- **Sentences found stale and left**, outside this entry's reach: `docs/CITY.md` says the
  off-corridor case samples "several seeds" where it uses two maps, `tests/events_shared_city.gd`
  lists five suites as extending it where two do, and `tests/test_routes_fallen_trees.gd` names a
  case by a name the rig no longer has.
