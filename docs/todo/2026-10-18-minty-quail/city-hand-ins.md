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

**What is left, the third pull request.** One pull request cannot hold it, so it goes in as several
small pull requests, each reviewed and merged on its own, the player's answer to the cut
(inbox #1381 in gray-moose): the four developer tools, the run log's summary lines off the city
scene and the developer's rigs have merged (#1364, #1365, #1374); the event manager's own city is
in review (#1378), and goes before the dawn's context rewrites `build_day()`'s call
(polite-tapir's `scheduler-breakup.md`); the smaller cases go when they are ready, and who
builds the event manager and the crowd is last (polite-tapir's `standing-layer-breaks.md`). The earlier answer was
three pull requests ("yes three prs is fine", inbox #1173 in gray-dolphin):

- the event manager's own city: `EventManager.setup(city, …)` and `EventWorld.city`;
- the smaller cases: `day_director.gd`, `main.gd` and `day_planner.gd`, as 3c's row in #1166's
  "Files it touches" lists them (the scenery's residency and ground, the blackout and the poster
  walls take what they read since the record 2026-10-18-minty-quail-quiet-ibis, the still watch, the
  debug readout, the frame recorder and the frame trace since the record
  2026-10-18-minty-quail-calm-wombat, and the developer's rig, the route rig and its planner since
  the record 2026-10-18-minty-quail-plush-chipmunk);
- `DayPlanner`'s fallback that grows a route tree when dawn grew none is deleted, since no game
  path reaches it. The rigs that start the event manager's day on a built city without `City.start_day()`
  (`tests/event_manager_rig.gd`, which the two event manager suites share, `tests/test_masts.gd`,
  `tests/test_pursuer_on_foot.gd` and three probes, at least) hand it a `DayStreets` whose day they
  began instead.

**Which map a test uses** is writing-tests' rule (inbox #1172 in gray-dolphin): the shared writer's map is for a test
of one interaction or edge case, never for a booted day or a measurement.

**Fields are not API** (designing-classes, inbox #1173 in gray-dolphin): new state is kept in underscore fields
behind methods, and a read this work rewrites goes through a method.
