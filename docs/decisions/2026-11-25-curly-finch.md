# curly-finch — The run's rows handed from main, so the catalogue keeps no run state · 2026-11-26

The run's charger timing (`ChargerTiming`, `--chargers` and `?chargers=`) was kept in a static of the
catalogue, `EventCatalogue._chargers`, written once at boot by `main.configure()` through
`use_charger_timing()`, and every row was built from it. So ten world and simulation files fetched run state from
a static, the one declared break of the layer map (`tools/layer_map.py`'s `EXCEPTIONS`, declared in
designing-classes). The entry was the orchestrator's proposal, carrying out the player's rule on dependency
injection (minty-lemur #794) and the rule that a legacy implementation never holds back a clean design
(minty-dolphin #852).

**The catalogue is an object built from a timing**, `EventCatalogue.new(timing)`: every row builder, accessor and
cache is an instance member. `main.configure()` builds the run's once, `EventCatalogue.for_run(config.charger_timing())`,
and hands it to everything that reads a row. `for_run()` holds the one catalogue at the shipped timing itself (the
static `_shipped`, built once from constants, never written), so a boot at the shipped timing builds and validates
no second copy of every row; at any other timing it makes a catalogue of its own. What depends on nothing a run
sets stays static: `shipped_charger_timing()`, `heat_levels()` and `without_its_aftermath()`. A row holds the row
it leaves behind (`Aftermath.then(row)`, `EventDef.left_behind()`), so the explosion's crater is known without a
catalogue to look it up in, and the catalogue memoizes the crater so it is the very row `by_id("lane_crater")`
answers.

**How the rows reach their readers.** The events read them from their surroundings
(`EventSurroundings.reading()`, `EventWorld.rows()`, `EventManager.rows()`); the dawn from its context
(`DawnContext.new(rows, ...)`); the static planners take them as their first parameter (`SealPlanner`,
`RegionPlanner`, `ClosurePlanner.plan_day()`, `MastSites`, `BuildingPlan.plan()`, `DayPlanner.plan_the_escape_city()`,
`EventDirector.ordinary_route_marbles()`, `ResistanceDirector.task_guard_farthest()`), so the parser flags a caller
left behind. Where a hand-in had been a setter with no default it is a required argument, so a forgotten one fails
at parse: `SimulationBuilder.new(rows)`, `City.build(rows, map)`, `TutorialRoute.for_city(rows, map)`,
`RecipeCityBuilder.build(rows, data)`, `SceneRecipeRuntime.load_recipe(rows, ...)` and `configure(rows, ...)`,
`SceneRecipeDraft.new(rows)`, `EventDirector.new(rows, ...)`, `ParkCordon.new(rows, ...)`,
`SitedGround.new(rows, ...)`, and the `setup(rows, ...)` of the crowd, the resistance and its happenings.
`EventManager.new()` now requires its surroundings: its checkpoint reads the door guard from the rows as the manager
is made, so the default it had always failed.

**One setter stays: `EventSurroundings.reading()`.** The surroundings are a chained value whose every part has a
default (`EventSurroundings.new().on(map).hearing(where)...`), and an event instance set up alone reads no row, so a
catalogue is not a part every holder needs. A manager or a world without it fails at its first row lookup.

**The suites hand the shipped catalogue**, `Shipped.rows()` (`tests/shipped.gd`, which asks `for_run()` at the shipped
timing). A suite that asks what another timing builds makes a catalogue of its own: `tests/test_events_catalogue.gd`
and the probes `charger_warning.gd` and `m213_far_end.gd`, which handed the static catalogue a timing and handed it
back, now build `EventCatalogue.new(timing)` (or `for_run()`) and hand it to what they measure
(`CatalogueRows.of(rows)` walks a given catalogue's rows).

**Measured, behaviour unchanged.** A scratch probe dumped every row of the catalogue at every heat and every day,
the door guard, the task guard waiting and sent, the mark guard, the lesson dog, the escape's roadblock and the men
out of the car on every day (notice radius, field reach, warning and catch, 1174 lines) at a non-shipped timing,
1.5s and x1.2: on `main` through `use_charger_timing()` and on the branch through `for_run()`. The two dumps are
identical. The boot's run log is untouched, since the shipped timing builds the same rows from the same constants.

**Rejected:**
- A public `EventCatalogue.shipped()` for the suites and tools to read. Nothing under `src/` read it (`main` calls
  `for_run()`), so it was a member only tests read, which `tools/check_test_only_members.py` fails and
  writing-tests answers by fixing the member, not listing it; `for_run()` holds the shipped catalogue instead.
- `City.use_rows()` and keeping `SimulationBuilder.use_rows()`: setters with no default, which a caller can forget
  and the parser cannot see.
- Keeping the exception and the static (the plainer alternative the entry named).

The layer map's `EventCatalogue` exception and its declaration in designing-classes are deleted, and the catalogue's
memoised statics in the map's static-state list are one, `EventCatalogue._shipped`.
