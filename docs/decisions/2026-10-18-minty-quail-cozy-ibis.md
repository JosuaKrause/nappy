# minty-quail — The day director and the run log take the city's parts, not the whole city · 2026-11-16

**The ask.** `city-hand-ins.md`, the third pull request's smaller cases, `day_director.gd` and `main.gd`, and the first bullet of
"Other readers of a whole `City` under `src/`": the day director and the run log's session ask the world for the whole city to
read its map, streets and crowd, and the director takes it from there too. The player's words behind it: the city should never
be built for tests that do not test the actual city (inbox #1156 in gray-dolphin), and no test should build a real object it
does not test but mock it (inbox #1159 in gray-dolphin). This is the pull request #1482, one cut of `city-hand-ins.md`'s third
pull request; the rest, who builds the event manager and the crowd, is the polite-tapir record `snowy-toad`. Behaviour is
unchanged.

## What was built

- **`CityDressing`** (`src/city/city_dressing.gd`, world layer): what the director asks the city scene to do as a walk starts,
  each method doing nothing in the base: `start_day()` and `start_recipe_day()`, `set_act()` and `set_daylight()`,
  `refresh_street_trees()`, `tint_the_route()` and the new `prepare_scenery_in(view)`, which replaces the director's static
  `prepare_city_scenery()` (the scenery's residency brought to a view at once). **`City extends CityDressing`**, which extends
  `WorldContext`; each of the seven `City` methods carries `## Overrides CityDressing.<name>.`.
- **`DayWorld.in_the_city()` takes the city's parts**: the dressing, the map, today's streets (`DayStreets`) and the crowd,
  answered by `city_map()`, `streets()`, `crowd()` and `dressing()`, each null in the escape's building; **`DayWorld.city()` is
  gone**. `DayWorld.is_in_a_city()` is the one answer to "is this walk in a city", true only for a world `in_the_city()` stood,
  which answers null when a part is missing. Every city branch in the director (seven) and in `RunSession` (three) keys on it.
- **The whole city reaches one reader**, an authored scene (`AuthoredScene.install()`, played by
  `src/dev/scene_recipe_runtime.gd`): `in_the_city()` takes an optional last `scene_city`, answered by `DayWorld.scene_city()`,
  and the main scene hands it only when `_flow.authored`.
- **`DayDirector`**: `use_the_world(world, resistance, day)` takes the stood `DayWorld` in place of six arguments and reads the
  four city parts into private fields; `var city: City` is gone; the won day's unmet fire is lit through the world's own
  `events`.
- **`main.gd`** stands the city world from the parts and hands the director `_flow.world()` (`RunFlow.world()` is new and answers
  the world the flow already kept from its `world_stood` announcement, so `main` keeps no copy). `RunSession` reads the map,
  streets and crowd's sources from the world.
- **The rigs and the suites**: `tests/standing_city.gd` stands its city's parts; `tests/test_day_director.gd` builds no `City`
  for the director (`_FakeDressing`, `_FakeMap`, `_FakeCrowd`, a real `DayStreets.new()`, `DayWorld.in_the_building()` for the
  end's tests, and a stand-in `_SceneCity extends City`, never built, for an authored scene); `tests/test_day_world.gd` is new.
- `tools/field_reads.txt` loses six lines and gains none. `docs/ARCHITECTURE.md` gets three small hunks, and the queue text
  (`city-hand-ins.md`, `field-reads.md`, `tests-public-seams.md`) is rewritten on the branch to what is true.

## Measured

`check.sh` clean; the suites the fixes reach, 39,981 checks, 0 failures (`test_day_world`, `test_day_director`, `test_run_flow`,
the five suites moved onto `prepare_scenery_in()`, the two left reading the residency, the run log's four, `test_scene_recipe_boot`,
the rigs); before the fixes a further 85,336 checks over thirteen suites, 0 failures. A search for `.city` and `.city()` on a
director or a world, and for `prepare_city_scenery`, finds none of the removed names: every `.city` hit is another object's
(a recipe's dictionary, a rig's field, a probe's walk record). The merge of main (#1478 to #1480) was Git's own.

## Choices where the design was silent (each open to overturn)

1. **The city scene's own steps become one interface, `CityDressing`, a base class `City` extends**, as the design says a
   narrow interface in GDScript is. Rejected: a part `City` builds that calls back into it (a layer of forwarders, which the
   design's fork 4 ruled out for the fronts); moving the dressing code out of `City` (it acts on the scene's own nodes, and
   `city.gd` is read whole by the who-builds pass); Callables (untyped, no object to name, the design's fork 5).
2. **The name `CityDressing`**, for what the director gets out of it. The reviewer's preference on the name stretch stands.
3. **The scenery's prepare is one of its methods.** Rejected: handing the director the `SceneryResidency` as a fifth part; it
   only ever brought it to one view at once.
4. **`DayWorld` takes the four parts as arguments of `in_the_city()`**, eleven with the optional scene city. Rejected: a record
   grouping the city's parts, a new type only to carry them.
5. **The whole city goes in the world only for an authored scene**, so a day of the game's own run holds no `City` in its world.
   Rejected: always handing it.
6. **`City.scenery` stays public under a `[kept]` line**: five suites only brought the residency to a view at once and now call
   the game's own ask, `prepare_scenery_in()`; what is left reads the residency itself (`test_recipe_city_drawing.gd`,
   `test_run_config.gd`'s `frame_locked`, and the probes `ground_frames.gd` and `ground_frames_matched.gd`), which no method the
   game calls answers. The plainer alternative is the var made internal and those four files rewritten. The reviewer found the
   line's first citation, `tests-one-module.md` entry 3, did not reach its suites; it was corrected.
7. **A null return, not a `push_error`, from a refusing `in_the_city()`**: the runner fails a run on an engine error, so a test
   of the refusal could not see one; nothing in the game reaches the refusal.
8. **The director's suite hands an authored scene a stand-in `City`**, since the scene's contract takes a `City`.

## Review

The first review (changes requested) found the queue sentences missing from the pull request (blocking), `main._world`
duplicating `RunFlow`'s world, "is a city world" keyed on three different parts, and the `[kept]` line's citation; all four were
fixed (`RunFlow.world()`, `is_in_a_city()`, the corrected citation, the queue text), and the delta review approved. A preference
on the director-level check for the scenery ask stays open.

## What stays open

Who builds the event manager and the crowd and the dev settings `main.gd` writes into `City`'s fields (`snowy-toad`); `main.gd`'s
remaining reads of `City`'s vars (`map`, `navigator`, `spawn_siting`, `excitement_sources`), which are the composition root's
own wiring and the entry's row 3c, after who builds.
