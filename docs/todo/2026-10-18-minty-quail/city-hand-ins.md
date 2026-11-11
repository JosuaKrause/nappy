# The classes that demand a whole City take only what they read

**The ask.** "the city should never be built for tests that don't test the actual city"
(inbox #1156 in gray-dolphin), "no test should build a real object that it doesn't test (it should mock it)" (inbox #1159 in gray-dolphin),
and, on the board's test-isolation-plan, "yes" to its third step: hand-ins for the classes that
demand a whole city, a way to hand `main` its map, and one shared writer for small test maps
(inbox #1159 in gray-dolphin). On the design in PR #1166: "yes three prs is fine" (inbox #1173 in gray-dolphin).

**Read as:** no class takes a whole `City` when it reads only parts of it, so no test of it has to
build a city. `DayStreets`, `CityFronts` and the hand-ins for the resistance director, its
happenings, day 12's park cordon, the crowd and the run log's observer are built; the design is in
#1166's description, under "The step's design".

**What is left, the third pull request.** *Proposed, not asked for, and to go to the player before
it is built:* one pull request cannot hold it, so cut it, the event manager's own city and the day
planner's fallback below first, before the dawn's context rewrites `build_day()`'s call
(`scheduler-breakup.md`), then the smaller cases, then the summary lines, and who builds the event
manager and the crowd last (`standing-layer-breaks.md`). The player's answer was three pull requests
("yes three prs is fine", inbox #1173 in gray-dolphin), so the plainer alternative is one large
third pull request:

- the event manager's own city: `EventManager.setup(city, …)` and `EventWorld.city`;
- the smaller cases: the still watch, the debug readout, the developer's rigs (`dev_rig.gd`, `route_rig_planner.gd`), `day_director.gd`,
  `main.gd` and `day_planner.gd`, as 3c's row in #1166's "Files it touches" lists them, and the
  frame recorder and the frame trace, which read `City.events` and `City.crowd`
  (`field-reads.md`) (the
  scenery's residency and ground, the blackout and the poster walls take what they read since the
  record 2026-10-18-minty-quail-quiet-ibis);
- `DayPlanner`'s fallback that grows a route tree when dawn grew none is deleted, since no game
  path reaches it. The rigs that drive the event manager without `City.start_day()`
  (`tests/test_event_manager.gd`, `tests/test_balance.gd`) hand it a `DayStreets` instead;
- *proposed by the hand-ins' builder (where `calm_summary()` goes, by the orchestrator), open to the player's correction:* the city's three summary
  lines move off `City`, so the run log's session (`RunSession`, where it hears
  `RunFlow.day_planned`) takes the parts too. `closure_summary()` moves
  onto `DayStreets` and `event_summary()` onto the event manager. `calm_summary()` reads the map
  with the run's city state, so it moves onto `CityMap`, asked with the city state handed in.

**Which map a test uses** is writing-tests' rule (inbox #1172 in gray-dolphin): the shared writer's map is for a test
of one interaction or edge case, never for a booted day or a measurement.

**Fields are not API** (designing-classes, inbox #1173 in gray-dolphin): new state is kept in underscore fields
behind methods, and a read this work rewrites goes through a method.
