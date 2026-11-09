# minty-quail — The fixed parts, the scripted rows, the one-shots and the scene recipes are placed by location · 2026-11-08

minty-quail's `placement-by-construction.md`, its third step's last part (3c); 3b is jolly-toad.

**Built.** What the day placed at dawn by rolling a tile is placed by location now, and what a
fixed part holds is recorded on its location (the design's fixed parts' phases, `docs/EVENTS.md`,
"The three views and the placement order"):

- **The masts' sites are fixed for the run**: worked out once, on the city as built, when the
  event manager is handed its city (`EventWorld.work_out_mast_sites()`, `mast_sites()`), and handed
  to every dawn (`EventScheduler.build_day()`'s `mast_sites`, which every caller hands in: no
  fallback, so a probe measures the dawn the game plans). That is the player's "the mast locations
  are known from the beginning of the game" (inbox #1185), and a change made on purpose: worked out
  on each day's paint, as main does, a calm area grown or a tile changed can let a newly eligible
  candidate win the pick, and the reviewer found main's sites differ from the run's on 23 of 400
  city-days (5 of 40 cities from 55501 in steps of 29, from day 8).
- **The fixed parts hold their locations.** At dawn each mast, each playground and every standing
  fixed part (the seals, the region wall's and its doors' bodies) is recorded on the location
  holding its tile (`DayLocations.holding()`, `hold_fixed_part()`), so the draw passes over it. A
  soft seal stands on a street no hold closes, so its sidewalk locations are what it holds. A
  mast's location on a day before the masts holds nothing and is drawn like any other. A
  playground's ground is in no location, so it holds none.
- **The scripted rows have a dawn phase** (`ScriptedPhase`): it draws one of the day's open
  locations (`DayLocations.open_locations()`), each weighted by the copies the row's role gives its
  tiles (`EventScheduler.ground_for()`'s pool: a wall kept off the route, friction drawn onto it),
  offers the row through the dawn draw's own path (`RuledLocationGround`), and assigns the location
  what it took. Day 10's night raid and day 13's firefight go this way. `_place_one()` and
  `_place_a_set_piece()` are deleted.
- **A one-shot is sited on her way**: `EventDef.validate()` refuses a one-shot without
  `on_her_way`, and the day owes each one to her walk (`_place_one_shots()`), with no roll and no
  dawn placement. The escape building's own fire, placed by its plan, is a scripted row on no day.
- **A scene recipe's row stands in the location its tile names**, asked once: the tile is one the
  location takes for the row (`LocationFit`) and the day's rules allow it (`StreetInvalidation`), on
  the recipe's own `route_seed`, with no tries and no fallback (`EventScheduler.recipe_placement()`).
  A refusal fails the recipe loudly with its reason. Recipes keep their data; `place_at()` is
  unchanged, since it already sites one tile and its only roll is the route a recipe pins.

**The covering sites and the groups are deleted, and the guarantee they gave is the walk's.** With
the set-piece branch gone, `RouteTree.covering_sites()` (the smallest set of streets every route
touches) had no reader, so it goes with its cover search, `Corridor.sites()`, `ground_for()`'s
`site` parameter, `NO_SITE` and the two route-tree tests of the fan-out; and with every one-shot a
single plan owed to her walk, the groups of mutually exclusive placements go too
(`Planned.set_piece_group`, `EventStreaming._spend_the_rest_of_the_group()`, `room_around()`'s
exception for offers). That last is a change to day 3's walk on purpose: a siting during the walk
spaces against the fire as against anything placed. Measured over a scripted day-3 walk on 24
cities (30011 in steps of 53, 150 s along the day's longest route, the director drawing and siting
as the game does), every walk siting is where main puts it: on day 3 the walk sites only the fire,
and the route bag's day-3 marbles are moments the director sites itself. The guarantee the covering
sites gave is that something she must meet exists wherever she goes, since she can take either
way: *"you have to account for things to be potentially in one of two places at the very least, in
the ideal case where there are exactly two distinct paths"* (M50-the-city-points-somewhere). It
holds now because a row she must meet is sited on her way and `validate()` refuses one that is not
(`docs/CITY.md`, "A set piece has to be met"); the walk's draw is to carry it next, a rigged marble
on the next location she comes to (step 4, the orchestrator's decision). The player asked for code
nothing reaches to go (inbox #1180 in gray-dolphin), which the dead-code sweep holds; this was its
first case.

**Measured.** Against main (`6f4a81196`) with `tests/probes/placement_rows.gd` over the four samples
the earlier steps measured, 64 cities: `90210+31i` (18) and `70001+37i` (18), on which the fitted
tables were fitted, and `31337+43i` and `24601+41i` (14 each), unseen by them; main and the branch
run at once on each sample, every `build_day()` timed, each handed its mast sites as its game does
(main on each day's paint, the branch once on the city as built). **Days 1 to 4 are byte-identical
to main on every sample** (no mast stands yet, and a playground holds no location); days 5 to 14
move, and every cell stays within noise: no cell is outside 2σ pooled or on two samples with the
same sign. By the stopping rule (refit until the passes move within noise) no table is refit.
Walls on her route 6.36 → 6.37 a city a day, friction on her route 18.96 → 18.95. Dawn planning
time inside `build_day()` is −0.1% (2809 s → 2805 s). Where the two scripted rows stand moves
within the same ground, as the (a) list below gives. The escape building's fire, a scripted row on
no day where it was a one-shot, is placed exactly as before (`BuildingPlan.plan()` over 20 streams,
140 placements, identical to main), and the escape's density probe and the finale and building
suites are unchanged.

**The walled pacer.** `tests/test_events_placement.gd`'s floor of one pacing row whose beat passes
no way off its sidewalk rested on one such row in its sample, on a day the masts' locations now
change; the sample found none. City 88's day 1, before any mast holds a location, paces one, so it
is in the sweep. The claim was not wrong before; it rested on chance.

**Choices where the design was silent, open to overturn** (the orchestrator's, open to the
player's overturn):

- the scripted rows' dawn phase draws a location weighted by role, on the row's own stream, offered
  through the dawn draw's path and then taken; placement by location, not parity by roll;
- recipes keep their data: `at` names its location, checked once, a refusal failing the recipe
  with its reason;
- the masts' sites fixed for the run and handed in with no fallback, the fixed parts recorded on
  their locations so the draw passes over them, a mast's location before the masts drawn like any
  other;
- the suites that plan one city over many days work the sites out at each call, on the day's paint,
  rather than once per city as the game does; the tests queue item (`tests-one-module.md`) hoists
  them as it touches each suite.

**For the end-of-refactor remeasure**, generated by the rule grassy-magpie states, from the logs of
the measurement above. Its output, verbatim:

    (a) Changed on purpose:
    - The masts' sites are fixed for the run, worked out once on the city as built (EventWorld.mast_sites()), the player's 'the mast locations are known from the beginning of the game' (inbox #1185); main works them out on each day's paint, and the reviewer found the two differ on 23 of 400 city-days (5 of 40 cities from 55501 in steps of 29, from day 8). Each mast holds the location under it from day 5, so the draw passes over it.
    - Every standing fixed part holds the location under it at dawn, a soft seal its sidewalk locations included, so the draw passes over them; the probe plans no seals, so it sees none of it.
    - The scripted rows each draw one location at dawn, weighted by their role over its tiles, and are assigned it (ScriptedPhase), where a tile was rolled from their ground; the draw passes over the location. Of the 64 cities, where they stand: night_raid: junction 12 -> 15, sidewalk 51 -> 49, route-adjacent 23 -> 22, off the route 40 -> 42; firefight: junction 60 -> 62, open 4 -> 2, off the route 64 -> 64.
    - A one-shot is sited on her way: EventDef.validate() refuses one without on_her_way, and the dawn neither rolls nor places one; burning_building already was, so the probe sees no change from it.

    What the probe cannot see:
    - Dawn planning time inside EventScheduler.build_day(), main and head run at once on every sample, timed per call: 2809 s → 2805 s (-0.1%; 90210+31i -0.4%, 70001+37i -0.2%, 31337+43i +0.1%, 24601+41i +0.0%).
    - The scene recipes: an authored row stands in the location its tile names, asked once with no tries; the recipe suites hold it, and the probe plans none.
    - Day 3's walk: a siting during the walk spaces against the fire as against anything placed, where the groups of placements exempted it. Over a scripted day-3 walk on 24 cities (30011 in steps of 53, 150 s along the day's longest route, the director drawing and siting as the game does), every walk siting stands where main puts it: on day 3 the walk sites only the fire, and the route bag's day-3 marbles are moments the director sites itself.
    - The escape building's own fire is a scripted row on no day, where it was a one-shot: the building's plan places it exactly as main does (BuildingPlan.plan() over 20 streams, 140 placements, 20 fires, identical), and tests/probes/escape_density.gd is identical to main.
    - The probe plans at heat 0, with no region doors, no scars, nothing standing and no calm area used.
    - A playground's ground is in no location, so the ambient rows hold none; days 1 to 4 are byte-identical to main on every sample for that reason.

    (b) Outside 2σ pooled over all 64 cities (90210+31i (18), 70001+37i (18), 31337+43i (14), 24601+41i (14)), events per city per day, main → head:
    Note: (b) is empty. What moves on days 5 to 14, the masts' locations held and the scripted rows' locations drawn, stays within noise in every cell, so by the stopping rule no table is refit. Main works its mast sites out on each day's paint and the branch on the city as built, each as its game does.

    (c) Outside 2σ on at least two samples with the same sign (z per sample in the order of (b)):
    Note: (c) is empty. The police patrol on her route moves within noise on every day from 4 to 14 (day 4 3.69 → 3.69, day 5 4.59 → 4.67, day 6 4.45 → 4.61, day 7 4.42 → 4.55, day 8 4.48 → 4.48, day 9 3.91 → 3.92, day 10 3.66 → 3.53, day 11 4.05 → 3.98, day 12 4.16 → 3.97, day 13 3.38 → 3.33, day 14 4.25 → 4.00); it is fitted at the end-of-refactor remeasure, after the walk draws.

    Summary, pooled over all 64 cities:
    - walls by view, on her route: 6.36 → 6.37 (+0%, z +0.1)
    - walls by view, route-adjacent: 30.54 → 30.57 (+0%, z +0.1)
    - walls by view, off the route: 18.11 → 18.08 (-0%, z -0.1)
    - friction by view, on her route: 18.96 → 18.95 (-0%, z -0.1)
    - friction by view, route-adjacent: 9.45 → 9.39 (-1%, z -0.4)
    - friction by view, off the route: 35.82 → 35.66 (-0%, z -0.6)
    - each row per kind of ground: 49 cells, every cell main or head has, from -50% (firefight open) to +inf% (military_convoy junction); within 2σ, from -50% to +inf%
    - each row per view: 65 cells, every cell main or head has, from -43% (poster_crew_square route-adjacent) to +200% (poster_crew_square on her route); within 2σ, from -43% to +200%

    Cells compared: 524. Outside 2σ pooled: 0. Outside on two samples or more, same sign: 0.
