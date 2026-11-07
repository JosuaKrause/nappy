# The classes that demand a whole City take only what they read

**The ask.** "the city should never be built for tests that don't test the actual city"
(inbox #1156 in gray-dolphin), "no test should build a real object that it doesn't test (it should mock it)" (inbox #1159 in gray-dolphin),
and, on the board's test-isolation-plan, "yes" to its third step: hand-ins for the six classes that
demand a whole city, a way to hand `main` its map, and one shared writer for small test maps
(inbox #1159 in gray-dolphin). On the design in PR #1166: "yes three prs is fine" (inbox #1173 in gray-dolphin).

**Read as:** six classes take a whole `City` today (the resistance director, the resistance
happenings, day 12's park cordon, the crowd, the run log's observer, and `main`'s city map), so no
test of them can avoid building a city. Each is handed only the parts it reads, by `main`, `City`,
the director or the happenings, as #1166's description designs: `DayStreets` (today's route tree,
region plan, closures and siting region, as dawn left them) and `CityFronts` (the building fronts the
story changes) are new, and the event manager is handed as itself.

**What is in flight.** The first of the three pull requests, the `DayStreets` move off `City` with
every caller reading `city.streets`, is being built on #1166.

**What is left after it:**

- **The second pull request:** `CityFronts`, the six hand-ins, the calm-ground question moved onto
  `CityMap`, the generator's street pass moved into `StreetLayout`, and the shared test-map writer
  (`tests/fixtures/street_map.gd`), with `tests/test_navigator_fallbacks.gd` as its first consumer.
  *Proposed, not asked for (the orchestrator's add, which stands unless the player overturns it):*
  the same pull request moves one resistance-happenings test onto `FakeEventManager` and
  `FakeCityFronts`, so no new seam lands without a test using it (inbox #1156 in gray-dolphin).
- **The third pull request:** the event manager's own city (`EventManager.setup(city, …)` and
  `EventWorld.city`) and the smaller cases (scenery residency and ground, the blackout, the still
  watch, the debug readout, the developer's rigs), after the after-dawn work
  (`walk-placed-blockers.md`), since both change the same files.
- **The run log reads today's route tree from `DayStreets`** and grows none of its own: "of course,
  the observer needs to read the actual tree from DayStreets" (inbox #1173 in gray-dolphin). Done in whichever of
  these pull requests hands the observer `DayStreets`, after checking on a few seeds and days whether
  the two trees ever differed.

**Which map a test uses** is writing-tests' rule (inbox #1172 in gray-dolphin): the shared writer's map is for a test
of one interaction or edge case, never for a booted day or a measurement.

**Fields are not API** (designing-classes, inbox #1173 in gray-dolphin): `DayStreets` and `CityFronts` keep their
state in underscore fields behind methods, and a read this work rewrites goes through a method.
