# polite-tapir — Step 4's third part, second half: the old siting roll goes, and a beat is laid by location · 2026-11-17

**What it is.** The second half of placement step 4's third pull request (polite-tapir's
`placement-by-construction.md`, step 4), after the first half handed the siting in (the record
polite-tapir-coral-egret). It builds Fable's design
(`.claude/briefs/designs/placement-step4-rigged-marbles-design.md` in the orchestrator's checkout,
not tracked), sections 4.3 to 4.7 and 4.12 to 4.13.

**What was built.** The walk's siting roll, the roomiest of 24 tries
(`EventScheduler.WalkSiting`, `_best_of()`, `Verdicts`, `EVENT_PLACEMENT_TRIES`), is deleted.
`WalkSiting` is a file of its own (`src/events/walk_siting.gd`), made by `SitingMaker`, and lays a
beat on the nearest free location that takes it, taken from the day's locations for her walk and
given back when the beat moves (`DayLocations.take_for_her_walk()`, `give_back()`). The judge takes
the tiles it is brought (`LocationGround.offer_on()`), and the tiles a beat may stand on are
`SitedGround`'s. Where a beat is looked for is unchanged. `test_siting_judges_once.gd` and the probe
`bouncy_egret_day11_mast.gd`, which read the old roll, are deleted with it, and with them the last two
files under `tests/` that opted out of the typing warnings for this step.

**What it measured** (each probe against main, in the description): no route tile is cut off from
home on any of `walk_rows`' walks, and its longest chain is the same; every unit draw and the
excitement fingerprint are unchanged; the poster crews are sited and met on all ten walks; the fire
is seen on 4 walks of 12 rather than 5, since it now stands nearer and one walk that met it no longer
does; day 6's man shouting is seen on 9 walks of 12 rather than 8. The siting's first build cost six
to seven times main's per tick on days 4 to 14, since a beat's look asked about every tile before
asking whether the row may stand there; it now indexes a row's ground by the route tree's cell and
asks about the row's own tiles first, and `walk_rows`' total tick time is below main's. The fire's
attempt cost did not fall as the design expected: on day 3 it is the units drawn inside a look,
which pull request 4 removes.

**What is left of step 4:** the beat laid in the next undrawn unit ahead of her before it draws, and
the unit's draw told of it (pull request 4), waiting on the board questions `beats-on-her-street`
and `beat-changes-its-unit`. Day 6's man shouting and day 7's route van keep their place on her
street meanwhile, the design's pick (b) on the first question.

**Proposed, not asked for, open to the player** (the builders' choices where the design was silent
or could not be built as written): `WalkSiting` takes the day first, since its role for a row needs
it, and no unit list until pull request 4; `SitedGround.is_a_wall_by_cost()`, the siting's one way to
the walk's ground; `SitingMaker.assemble()` kept internal, since a public member only a probe reads
fails the test-only check, so `walk_rows` builds an event world and asks `make()`; the maker's random
stream from a new `EventWorld.day_stream()`, since the design's `world.run.calendar.day_rng` is a
field read; the dusk run-log line ending "her walk waited on ..."; the row ground indexed by route
cell. One sentence of the events skill's `references/plan-and-excitement.md` names `lay_ahead()`
where it named `ahead_of()`, a method that no longer exists.
