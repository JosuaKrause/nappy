# minty-quail — The escape city's placement runs on the day's scheduler, with its marble bag · 2026-10-24


minty-quail's `escape-placement.md`, the refactor's eighth PR (PR #839). The escape city placed its
events through a pipeline of its own: `EventScheduler.build_finale` with `EscapeGround`/`EscapeSolid`
and its own ground cache, `SealPlanner.plan_finale` with its own loop, `City.start_finale` skipping
half of `start_day`, `tint_the_escape_route` beside `_tint_the_route_kerbs`, and `main` clearing the
crowd by hand. The player allowed only the building its own way of placing events, and answered
`build_finale`'s fixed counts with the marble bag being orthogonal to prefilling (minty-lemur #785).

**Built.** `RouteSource` (`src/routes/route_source.gd`) is the walk placement is stated against;
`RouteTree` and `FinalePlanner.Plan` both extend it (the streets on the walk, whether a tile carries a
route, the kerbs the tint marks, whether an alley is reached, the start street, start and ends, the
corridor). `build_day(spec, …)` is the one entry point and one judge for a day and the escape's city:
the spec says how rows are drawn, `DaySpec.Draw.CATALOGUE` for every day or `BAG_PER_STREET` for the
city section, each street of the walk drawing `slots_per_street` marbles from one bag in the player's
order, the counts `DaySpec.for_section(CITY)`'s from `Tuning.FINALE_BAG_*` and
`FINALE_SLOTS_PER_STREET`, handed in rather than read inside the scheduler; the bag's draw goes through
the same `_best_of()`/`_judge()` and the day's own ground. The rules are spec settings both draws
read: `keeps_unused_calm_clear`, `holds_the_home_streets`, `caps_per_day` (off for the city section,
the PR #781 forks, minty-lemur #785), `one_notice_at_a_time` and `keeps_the_walk_open` (on).
`WalkGround` (`src/events/walk_ground.gd`) is the walk kept open, one rule stated over the
`RouteSource` it is handed. `plan_finale` is folded into `SealPlanner.plan_day(map, spec, route, rng,
…)`, with `seal_pictures`, `seals_the_main_road` and `seals_every_street_off_the_walk` as spec
settings and one alley-mouth pick. `City.start_finale` is folded into `City.start_day(state, day, rng,
spec)` (`closes_streets`, `pastes_posters`), the two tints are `City.tint_the_route(route)`, and the
crowd is the spec's (`DaySpec.crowd_density`, `main._start_the_crowd()`).

**Two changes on purpose.** The walk is kept clear of a standing lethal reach, not only a body
(`WalkGround.held_by()`): a row that stands, is `hard_fail` and does not pursue — the parked van —
holds her centre off its 54px reach, while a pursuer, whose reach moves and warns first, counts at its
band. And a real walker runs on the escape boot: `main` builds `RouteRig` when a city section starts
with `--route tunnel|bridge`, and `tests/probes/escape_winnable.gd` walks the game's own plan with it
instead of its stand-in meter, walker and camera.

**Verified at test parity** (inbox #813 in curly-moose): `check.sh`, `lint.sh`,
`ci_telemetry_kinds.py`, and the whole suite shard by shard with 0 failures and no script error. A
throwaway fingerprint of every placement's row, position, facing, role and path on eight escape seeds
and days 1, 4, 8, 9, 10, 12 and 14 on two seeds was identical before and after, and again after the
lethal-reach rule, which refused nothing a body had not on those seeds. The real walker got out on
seeds 4242 and 1 by the tunnel (64.3s, 81.9s) and the bridge (40.6s, 53.6s). Tests changed only as far
as the code moved: every `build_day`, `plan_day` and `FinalePlanner.plan` call hands a spec; the
renamed classes and fields (`WalkGround`, `street_bag`, `DaySpec.EMPTY_MARBLE`, `_street_ground`);
`start_day(…, city spec)` for `start_finale`. New tests: both exits are reached from the service exit
past every body and every standing lethal reach on nine seeds, with the rule's reading of one van and
one roadblock (`test_finale`); `--route tunnel|bridge` resolves to the spec's exits and `mark`/`task`
are unavailable with no resistance director (`test_route_rig`).

**Choices made where the design was silent, open to overturn:** the shared rule is one class asked by
the one judge for any spec that keeps the walk open, and days keep it off, since turning it on changes
their placement; `FinalePlanner.plan()` still orchestrates the escape's planning (route, seals,
events on one stream) and `EventManager.start_planned()` hosts it, since moving it into `start_day`
would change the escape's streams; the placement settings are flat `DaySpec` fields; `RouteSource`
carries more than the two questions the item named; a spec handed to no manager plans under
`DaySpec.for_day(day)`; the escape city's `start_day` syncs the home door to the run's scars and
refreshes the street trees, which `start_finale` skipped; `street_bag_seed` keeps its `escape-bag`
key, so the bag draws as before.

**Downy-tapir's fix:** `build_finale` and its loop are gone; what survives is data
(`Tuning.FINALE_SLOTS_PER_STREET`, `FINALE_BAG_*`, read by `DaySpec.for_section`) and the bag
constructor, `street_bag`. **orchestrating**'s exception for that fix covers no code; the PR closing
minty-quail removes it (minty-lemur #799).

**Left for later items**, filed in `events-composed.md`: `FinalePlanner` (routes, layer 2) calls the
seal planner and the scheduler, the escape's planning half where a day's is `EventManager.start_day`,
and `EventManager.start_planned()` stays a second entry point, the alternative being the escape
planned inside `start_day` once the manager is split; `WalkSiting` reads the day's home-street rule
always, since only day specs reach it; `--route` from the building section waits at the city's
brief. `comments.md` is applied to the code this PR wrote only.

**For the remeasuring step:** the walk rule keeps a parked van's 54px reach as ground (no change on
the eight fingerprinted seeds; where it binds, a van moves or is spent unmet); the winnable probe
measures with the game's walker, which neither lures a roadblock's guard nor settles the baby, so its
numbers are not comparable with `docs/evidence/winnable-escape-2026-10-19/` and the full 24-seed run
is the remeasuring step's; the escape city's home door shows the run's own state (sealed after day
10's raid), and so does an authored scene's (`start_recipe_day()` shares the dressing); `RouteRig`'s route lines name day 16 in the escape's city; a `--route` escape boot opens on
no brief.
