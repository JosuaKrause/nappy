# polite-tapir — Step 4's third part, first half: the siting is handed in · 2026-11-17

**What it is.** The first half of placement step 4's third pull request (polite-tapir's
`placement-by-construction.md`, step 4), cut at the maker as Fable's design allows
(`.claude/briefs/designs/placement-step4-rigged-marbles-design.md` in the orchestrator's checkout,
not tracked). It changes nothing in play: the placement fingerprint and the crews' and fire's probes
print what main does.

**What was built.** `EventsAhead` is handed a maker of its walk's siting, `SitingMaker`, through
`use_sitings()`; `EventManager` hands it the game's maker, which builds the same siting
`EventsAhead` built itself. `EventsAhead.walk_siting()`, which only tests read, is deleted: the suites
and probes that read the day's siting are handed a keeping maker (`tests/keeping_siting_maker.gd`),
and a test can hand a stand-in (`tests/fake_siting_maker.gd`). This answers the player's "make it so
you can inject it which will allow for it to be mocked easily" (inbox #1456 in silky-lemur) for
`EventsAhead`.

**What is left of step 4:** the old roll deleted, with `WalkSiting` a file of its own laying a beat by
location (the second half, 3b); and the beats laid in a unit before it draws, waiting on the board
questions `beats-on-her-street` and `beat-changes-its-unit`.

**Proposed, not asked for, open to the player:** a maker object rather than a `Callable` (the design's
pick); `EventWorld.the_city_map()`, a method the design did not name, added so the maker asks the
world rather than reading its field; `queue_a_mast()`'s siting keeps having no ground drawer until 3b.
