# minty-quail — The fixed parts, the scripted rows, the one-shots and the scene recipes are placed by location · 2026-11-08

minty-quail's `placement-by-construction.md`, its third step's last part (3c); 3b is jolly-toad.

**Built.** What the day placed at dawn by rolling a tile is placed by location now, and what a
fixed part holds is recorded on its location (the design's fixed parts' phases, `docs/EVENTS.md`,
"The three views and the placement order"):

- **The masts' sites are worked out once per run**, when the event manager is handed its city
  (`EventWorld.work_out_mast_sites()`, `mast_sites()`), and handed to every dawn
  (`EventScheduler.build_day()`'s `mast_sites`); a caller that hands none works them out there, and
  finds the same. A probe over 12 cities and 14 days found the sites the same on every day.
- **The masts and the playgrounds hold their locations.** At dawn each is recorded on the location
  holding its tile (`DayLocations.holding()`, `hold_fixed_part()`), so the draw passes over it. A
  mast's location on a day before the masts holds nothing and is drawn like any other. A
  playground's ground is in no location, so in practice only the masts hold one.
- **The scripted rows and the one-shots have a dawn phase** (`ScriptedPhase`): it draws one of the
  day's open locations (`DayLocations.open_locations()`), each weighted by the copies the row's role
  gives its tiles (`EventScheduler.ground_for()`'s pool: a wall kept off the route, friction drawn
  onto it), offers the row through the dawn draw's own path (`RuledLocationGround`), and assigns the
  location what it took. Day 10's night raid and day 13's firefight go this way; a one-shot whose
  roll comes up would too, a group of one. `_place_one()` and `_place_a_set_piece()` are deleted.
- **A scene recipe's row stands in the location its tile names**, asked once: the tile is one the
  location takes for the row (`LocationFit`) and the day's rules allow it (`StreetInvalidation`), on
  the recipe's own `route_seed`, with no tries and no fallback (`EventScheduler.recipe_placement()`).
  A refusal fails the recipe loudly with its reason. Recipes keep their data; `place_at()` is
  unchanged, since it already sites one tile and its only roll is the route a recipe pins.

**The covering sites are deleted, and the guarantee they gave moves to the walk.** With the
set-piece branch gone, `RouteTree.covering_sites()` (the smallest set of streets every route
touches) had no reader, so it goes with its cover search, `Corridor.sites()`, `ground_for()`'s
`site` parameter, `NO_SITE`, `room_around()`'s exception for offers, and the two route-tree tests of
the fan-out. The guarantee they gave was that something she must meet is in at least two places,
since she can take either way: *"you have to account for things to be potentially in one of two
places at the very least, in the ideal case where there are exactly two distinct paths"*
(M50-the-city-points-somewhere). No row today has to be met on every route. Under the design, a
row she must meet whatever route she takes is a rigged marble on the walk's draw, landing on the
next location she comes to, so it exists wherever she goes; the walk-draws step (step 4) carries it
(the orchestrator's decision). The player asked for code nothing reaches to go (inbox #1180 in
gray-dolphin), which the dead-code sweep holds; this was its first case.

**Measured.** Against main (`05967a93e`) with `tests/probes/placement_rows.gd` over the four samples
the earlier steps measured, 64 cities: `90210+31i` (18) and `70001+37i` (18), on which the fitted
tables were fitted, and `31337+43i` and `24601+41i` (14 each), unseen by them; main and the branch
run at once on each sample, every `build_day()` timed. **Days 1 to 4 are byte-identical to main on
every sample** (no mast stands yet, and a playground holds no location); days 5 to 14 move, and
every cell stays within noise: no cell is outside 2σ pooled or on two samples with the same sign.
By the stopping rule (refit until the passes move within noise) no table is refit. Walls on her
route 6.36 → 6.37 a city a day, friction on her route 18.96 → 18.96. Dawn planning time inside
`build_day()` is +1.0% (2249 s → 2272 s). Where the two scripted rows stand moves within the same
ground, as the (a) list below gives.

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
- the masts' sites once per run and handed in, the masts and playgrounds recorded on their
  locations so the draw passes over them, a mast's location before the masts drawn like any other.

**For the end-of-refactor remeasure**, generated by the rule grassy-magpie states, from the logs of
the measurement above. Its output, verbatim:

    (a) Changed on purpose:
    - The masts stand at the run's sites, worked out once when the run's city is handed over (EventWorld.mast_sites()), and each holds the location under it from day 5, so the draw passes over a mast's location.
    - The scripted rows (day 10's night_raid, day 13's firefight) each draw one location at dawn, weighted by their role over its tiles, and are assigned it (ScriptedPhase), where a tile was rolled from their ground; the draw passes over the location.
    - A one-shot the day places takes one location of its own at dawn, a group of one, where it was offered at every covering site; no catalogue row is placed that way, so the probe sees no change from it.

    What the probe cannot see:
    - Dawn planning time inside EventScheduler.build_day(), main and head run at once on every sample, timed per call: 2249 s → 2272 s (+1.0%; 90210+31i +1.0%, 70001+37i +1.0%, 31337+43i +1.2%, 24601+41i +0.9%).
    - The scene recipes: an authored row stands in the location its tile names, asked once with no tries; the recipe suites hold it, and the probe plans none.
    - The probe plans at heat 0, with no region doors, no scars, nothing standing and no calm area used.
    - A playground's ground is in no location, so the ambient rows hold none; days 1 to 4 are byte-identical to main on every sample for that reason.

    (b) Outside 2σ pooled over all 64 cities (90210+31i (18), 70001+37i (18), 31337+43i (14), 24601+41i (14)), events per city per day, main → head:
    Note: (b) is empty. What moves on days 5 to 14, the masts' locations held and the scripted rows' locations drawn, stays within noise in every cell, so by the stopping rule no table is refit.

    (c) Outside 2σ on at least two samples with the same sign (z per sample in the order of (b)):
    Note: (c) is empty. The police patrol on her route moves within noise on every day from 4 to 14 (day 4 3.69 → 3.69, day 5 4.59 → 4.67, day 6 4.45 → 4.61, day 7 4.42 → 4.55, day 8 4.48 → 4.50, day 9 3.91 → 3.92, day 10 3.66 → 3.55, day 11 4.05 → 3.94, day 12 4.16 → 4.00, day 13 3.38 → 3.34, day 14 4.25 → 4.00); it is fitted at the end-of-refactor remeasure, after the walk draws.

    Summary, pooled over all 64 cities:
    - walls by view, on her route: 6.36 → 6.37 (+0%, z +0.1)
    - walls by view, route-adjacent: 30.54 → 30.57 (+0%, z +0.1)
    - walls by view, off the route: 18.11 → 18.08 (-0%, z -0.1)
    - friction by view, on her route: 18.96 → 18.96 (-0%, z -0.0)
    - friction by view, route-adjacent: 9.45 → 9.39 (-1%, z -0.4)
    - friction by view, off the route: 35.82 → 35.65 (-1%, z -0.6)
    - each row per kind of ground: 49 cells, every cell main or head has, from -50% (firefight open) to +inf% (military_convoy junction); within 2σ, from -50% to +inf%
    - each row per view: 65 cells, every cell main or head has, from -43% (poster_crew_square route-adjacent) to +200% (poster_crew_square on her route); within 2σ, from -43% to +200%

    Cells compared: 524. Outside 2σ pooled: 0. Outside on two samples or more, same sign: 0.
