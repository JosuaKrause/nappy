# polite-tapir — Who builds the event manager and the crowd: one SimulationBuilder stands every world's simulation · 2026-11-16

**The ask.** The escape is a normal day with some special settings, implemented through the game's
regular means and with no separate code (inbox #785 in minty-lemur). The refactor's design review
found that the city scene built its own event manager, crowd, poster walls and blackout while
`main` hand-built the escape building's event manager, and that this group of layer breaks had no
home in the design; the player approved the review's points and the plan of one start for every
kind of day, its world built per spec by a builder handed in (inbox #1268 in olive-ferret). The
item `one-start-for-every-spec.md` held this as its last open bullet, and `standing-layer-breaks.md`
held it as the group "the city scene as builder".

**Who did what.** A Fable agent wrote the design and its prototype and handed the coding off
(inbox #1432 in minty-rabbit). It went in as three pull requests: #1485, the suites ask a fixture
(`RunCity`) for a city's parts, with a codemod over 131 test files; #1484, the world layer no
longer names her class; and #1486, this one, the builder. Opus built #1486; Fable reviewed it.

## What was built

- **`SimulationBuilder`** (`src/simulation_builder.gd`, the root layer): `main` makes one a boot and
  hands it the trace, the atlas, the frame timing, the bus, the poster art, the crowd's screen and
  the developer's flags as plain values (`equip()`, `use_bus()`, `use_poster_art()`,
  `use_the_crowds_screen()`, `leave_out()`, `make_every_cyclist_a_pelican()`, `force_a_row()`,
  `force_the_blackout()`). `in_the_city()` stands the poster walls, the events, the crowd and the
  blackout under the city, in that order; `in_the_building()` stands the building's events alone,
  the whole plan streamed in at once. One function, `_new_events()`, makes every event manager, so
  the city and the building get theirs the same way. The builder tells each world what charges
  her there (`WorldContext.use_excitement_sources()`, which replaces the old public field).
- **`WorldSimulation`** (`src/day/world_simulation.gd`, the flow layer): a node named `Simulation`
  under its world (`City/Simulation/{Posters, Events, Crowd, Blackout}`,
  `Interior/Simulation/Events`), answering `events()`, `crowd()`, `poster_walls()` and
  `excitement_sources()`, and handing her to the crowd, the walls and the blackout in
  `meet_her()`, which `main` calls at the three moments it handed the crowd her before.
- **The city scene builds none of them** and keeps no field for them. Dressed for a day it emits
  `CityDressing.day_dressed`, and the poster walls paste from that signal (`PosterWalls.dress_for()`).
  The blackout and the poster walls are handed the bus and her, so their `player`-group lookups
  and three `EventBus` fetches are gone; the blackout's `--blackout` and dark-from-the-start flags
  are `setup()` arguments. The event manager makes the one `SpawnSiting` and answers it
  (`spawn_siting()`). `AuthoredScene`, `DayWorld` and the scene recipe's runtime and draft take the
  simulation or its parts instead of reading the city's fields.
- **No parity node in the suites.** Each suite that runs real frames with a city and her in one
  tree says when the walls and the blackout see her
  (`RunCity.show_her_to_the_walls_and_the_blackout()`, or `WorldSimulation.meet_her()` where it
  already handed the crowd her); a suite that steps no frame with both standing hands nothing.
- **`tests/test_simulation_builder.gd`** holds the builder's wiring on a bare `CityDressing` and a
  hand-drawn map, with no `City`; each check fails with the builder line it holds removed (or, for
  `meet_her()` in the building, with the events handed her there).

## Measured

- **Layer breaks**: `uv run python tools/check_layers.py --list` printed 84 listed uses before and 67
  after, none unlisted. The 17 gone are `city.gd`'s 12 (`Blackout` 2, `Crowd` 2, `CrowdTiming`,
  `CrowdView`, `EventManager` 2, `EventSpawner`, `PosterWalls` 3), `blackout.gd`'s 3 and
  `poster_walls.gd`'s 2; `city.gd` has no line left in the list.
- **Nothing a day places or charges changed**: the three fingerprint probes printed identical lines
  before and after, diffed whole: `director_placement_fingerprint` (2,360 lines),
  `excitement_fingerprint` without its wall-clock `XF_COST` lines (20,377 lines) and
  `trap_arrival_fingerprint` (1,036 lines).
- **The boots**, headless with `--no-save --no-telemetry`, each exiting clean with no error or
  warning: the title (the city generated and day 1 planned behind it); a day (`--no-title`); a scene
  recipe (`task-06-note.json`, scripted); the building (`--start-escape`, its events under
  `Interior/Simulation`); and the escape's city (`--start-escape city`).
- **The full local suite** ran before the pull request opened; its only failures were two new boot
  checks in `test_run_config` that read nothing behind the title, fixed on the branch.

## Rejected, with the reason

The design's alternatives (its section 9), each kept as designed unless said:

- **The names**: `WorldLife` was the other candidate; "cast" was ruled out because the code already
  uses it for the act's color. `SimulationBuilder` and `WorldSimulation` take the layer's own name.
- **The product as a `RefCounted` each suite holds beside its city**: it would thread a second
  variable through the helpers of 131 test files by hand. The product is a node the fixture finds
  by name.
- **The parity node** (the design's choice): a node in the fixture keeping the `player`-group
  lookup, so 47 test files need not change. Overturned by the orchestrator before the build,
  because no legacy shape is kept, a forwarder for callers or tests included (minty-dolphin #852);
  each file says when the walls and the blackout see her instead.
- **The posters' dawn as a step of the day director**: every caller of the city's `start_day()`
  that expects the walls pasted (the suites) would stop getting them, the order against the
  scenery's update would change, and every day-director test would need a poster-walls fake. The
  world-layer city tells the simulation by an event instead (`day_dressed`).
- **The builder making the `SpawnSiting`** and handing it to the events and the resistance: the
  manager already built the same siting for a rig that handed none, with the formula
  `City.build()` repeated, so the fact was derived in two places; it is now derived once, in the
  manager.
- **Moving the city's own eight fields now** (`trace`, `run`, `ground_recipe`, `atlas`,
  `ground_mode`, `scenery_frame_locked`, `skip_shadows`, `frame_timing`): they serve the city's
  own ground and scenery, and wait for the city scene's own pass.
- **Three setters for the three `--skip` words**: one `leave_out()` is the one hand-in.
- **No pelican rig on the building's manager**: it is set there too, where it does nothing, so
  `_new_events()` keys nothing on which world it builds for.
- **The world layer's two `Stroller` names in this pull request**: they touch no line this one
  touches, and went alone (#1484).
- **A getter on the blackout and the poster walls for the boot test**: it would be read only by
  tests. `test_run_config` holds `--force` and `--blackout` by what they do instead.
- **A check that the building's events site nothing**, made to fail with `setup_world()`'s reset of
  the siting removed: it needs a manager set up for a city and then for the building, which the
  game never does, so it would hold a setup the game cannot reach. The check was deleted; the
  reset stays beside `setup_world()`'s other resets.

Where the design was silent, the builder's choices: the suites' fixture finds a city's blackout by
its node name (`RunCity.BLACKOUT_NODE`), since `WorldSimulation` has no `blackout()` getter;
`PosterWalls.start_day()` became internal, since only tests called it; and the builder suite's
`meet_her()` check uses a rig body that presses north to make the walls tear.

## What stays open

- **The bus through the event manager's parts and the resistance** (the design's pull request 4,
  `standing-layer-breaks.md`): `main` hands the resistance director the bus, the builder hands the
  event manager its own in `_new_events()`, and the manager hands it on; it waits for #1477, which
  rewrites `events_ahead.gd` and `event_director.gd`.
- **The city's own eight fields**, which `main` still writes, with the city scene's pass.
- **The other readers of a whole `City`** (`DayWorld.scene_city()`, the scene recipes, the debug
  layers), in minty-quail's `city-hand-ins.md`.
