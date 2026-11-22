# What the events are set up in is built once, where the world is built, and handed down whole

**What is wrong today.**

- **Every hand-in is restated at each level.** Take the trace the run log is written through. It passes through `SimulationBuilder._trace`, `EventManager.use_trace()`, `EventWorld._trace` with `use_trace()` and `trace()`, `EventWorld.surroundings()`, and `EventSurroundings._trace`.
- **All eleven members of `EventSurroundings` are copies of `EventWorld` fields.** `EventWorld.surroundings()` copies them into a new object for every live event (`EventSpawner.create()`). The class's own first line calls it what every live event of a world is set up in.
- **The cost shows in a filed entry.** minty-newt, the events' looks are handed the drawn view, has to touch the builder, the manager, the world and the surroundings for one hand-in. That entry is my own and followed the mechanism it found.
- **The rule is the live event's and not the manager's.** `EventSurroundings` says "nothing writes to it after it is set up". The manager's order lives in five doc comments: `use_trace()`, `draw_nothing()`, `use_timing()` and `draw_in()` say "before `setup()`", and `use_atlas()` says "before it enters the tree". `EventWorld.surroundings()`'s comment states the consequence: an event made before a hand-in "is not the one a later one is". A second `setup()` is asserted; these are not.
- **Nothing goes wrong in the game.** The one builder calls them in the right order. What is wrong is that the order is the caller's to know.
- **Defaults are stated at up to four levels.** The null timing sink is in the builder, the manager, the world and the surroundings; the silent trace in three; open ground in two; an atlas made where none was handed in two.
- **Suites hand things in through seams kept for them.** `tools/test_only_members.txt` keeps `EventWorld.use_drawer()`, `EventManager.use_run()` and the manager's public `world`.
- **The folder already has the right shape once.** `EventReports` is one object for a manager's life, shared by every part and every live event, so the bus reaches "a live event made before it included".

**The design.**

- **`EventSurroundings` keeps its name, its chained builders and its defaults.** It is the one place each default is stated. The rig defaults stand as snowy-lynx left them.
- **It also owns the world's one `WhereSheIs` from birth** (where she is this tick), and answers its atlas.
- **One is built per world by `SimulationBuilder`, complete**, and handed to the manager as it is made: `EventManager.new(surroundings)`. With none handed, the defaults apply: a suite's manager on open ground.
- **`EventWorld` keeps that one object and answers from it**: `map()`, `navigator()`, `trace()`, `drawn_in()`, `where_she_is()`. Its own copies and their hand-ins go.
- **`surroundings()` returns the one object**, and every live event is handed the same one.
- **The manager loses its pass-throughs**: `use_trace()`, `use_timing()`, `use_atlas()`, `draw_nothing()` and `draw_in()`, with no forwarder kept.
- **The protest target is the one late hand-in.** A protest's placards point at the resistance's objective, and the resistance is built over the events. `use_protest_target()` tells the shared object, so an event made earlier points too and `EventWorld`'s indirection for it goes.
- **Fork, my pick: the city's map is asked of the surroundings.** `in_the_city(map: CityMap)` beside `on(map)` (the name is my proposal); `city_map()` answers null elsewhere. `setup()` and `setup_world()` then differ only in today's streets and the poster walls, and become one `setup(run, streets, poster_walls)`. The plainer alternative keeps both calls and names the city's map a second time.
- **What stays as it is**: `stream_within()`, `rig_the_pelican()`, `force()`, `use_planner()`, `use_bus()`, `use_player()`, `use_controls()`, `use_body_listener()` and `use_the_spec()`. Each is the manager's own setting, or changes during a run, and is stated once.

**Tests.**

- The files that build a manager build its surroundings first, by a script kept in the pull request's description.
- A recording drawer is handed with `drawing_through()`, so the kept line for `EventWorld.use_drawer()` goes.
- The builder reports whether `EventManager.use_run()` goes too.
- Events built by hand with `EventSurroundings.new()` do not change.

**Order.** One pull request: the surroundings; the world; the manager and the builder; the spawner's one line; the suites and rigs.

**What holds parity.** Nothing a player sees or the run log records changes. The checks:

- `tools/test.sh observers`, line for line;
- the `XF` lines of `tests/probes/excitement_fingerprint.gd` and the `chain` of `tests/probes/m159_tick_sweep_events_cost.gd`, identical, with its time reported;
- the `LK` lines of `tests/probes/look_fingerprint.gd`, identical;
- the boot suite's check that every holder has the sitting's atlas library;
- snowy-lynx's check that a manager handed a navigator answers that same object.

**Cost.** Medium. Five files under `src/`: `simulation_builder.gd`, `event_manager.gd`, `event_world.gd`, `event_surroundings.gd`, `event_spawner.gd`. About two dozen suite and rig files construct a manager (23 when Fable counted them).

**What it collides with.**

- minty-newt, the events' looks are handed the drawn view: either order. If this is first, minty-newt's hand-in is one line at the builder and one member of the surroundings. If minty-newt is first, this removes its two pass-throughs.
- Row 5's event-manager suites: this lands before them.
- Row 4b's twelfth pull request: line-level.
- The row 3a change above: one after the other in `EventInstance.setup()`.
