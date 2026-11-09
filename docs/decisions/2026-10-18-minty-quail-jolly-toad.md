# minty-quail — Every body a phase places is judged by the street rules, and the repairs go · 2026-11-08

minty-quail's `placement-by-construction.md`, its third step's second half (3b), in #1256; the
first half is grassy-magpie, in #1254.

**Built.** The day's placement rules are classes (`StreetRule`, one file per rule under
`src/events/street_rules/`): the calm she has not used, a region door's clear ground, a route's
junctions, the sidewalk a route is walked along, a pacing beat's opening, no body cutting a route
tile off from home, and in the escape one waiting guard's notice at a time and the walk kept open.
`StreetInvalidation` composes them from the walk's spec and answers a candidate's room, or none
where a rule refuses; `LocationFit` answers a location's own ground for a row and builds the
candidate on a tile of it. Each rule's logic is in its class, with the helpers only it uses:
the scheduler's rule functions moved into them (the reviewer counted 18 calls from the rule files
into the scheduler's private functions where main had one; the orchestrator sent them to move in
this step), and what the scheduler still shares is public there (`EventScheduler.ground_for()`,
`build_placement()`, `role_for()`, `clearance_around_her()`, `body_stands_at()`,
`leaves_no_line_along_a_sidewalk()`), or public on the rule that owns it
(`StreetInvalidation.room_around()`, `DoorClearanceRule.clear_of_the_doors()`,
`RouteSidewalkRule.closes_the_run()` and `closes_a_walked_sidewalk_band()`); `CityMap` and
`EventDef` gained three small questions the moved code asks in place of their fields. The move
places every cell of the probe as before it. They replace `_judge()` as the dawn draw's invalidation
(`RuledLocationGround`) and the roadblock phase's (`RuledRoadblockGround`), and `_best_of()` asks
the same rules for its callers outside the draw, keeping its tries and its roomiest fallback (the
orchestrator's answer B): the walk's sitings, the scripted rows, the one-shots and the scene
recipes, each until a later step moves it to the locations. The escape draws on the same rules:
each street on the walk draws one marble, offered at the street's locations in their drawing
order, the first that fits takes it, and the rest of the street stays empty.
`_fill_the_walk_from_the_bag`, `KeptGround`, `Rules` and `DaySpec.slots_per_street` are deleted.

`DayRepairs` is deleted, and the two guarantees it repaired are kept by construction. **A route
from home:** `RouteReachRule` refuses an obstructing body that would leave a route tile home
reached without it unreached, and asks bodies off the routes too, since the last of a ring that
seals home in can stand beside a route the ring's first body crossed; one is built per dawn and
handed to every judge of a day's dawn (not the escape's, whose plan has no route tree and whose
walk `WalkOpenRule` keeps open), holding the reach tile by tile and keeping it in step (a body the
ground round goes round takes only its disc off it). The run's scars and the park spoilers are
asked `RouteReachRule` alone before they stand, the one question the repair asked of them: not the
line rules, not the spacing, and no role is written onto them. The first version asked them the
whole invalidation, the spacing included, and the review measured what that cost a used park
(24 cities from 61003 in steps of 41, days 2 to 14, yesterday's area used): 1668 → 1493 events
standing in 307 used areas (−10.5%), and 1 → 11 areas with nothing in them, against PLAYTEST-140 8
(a used park is shut by the events placed in it). Asked the reach alone it is main's again, 1668
and 1. **One calm area clean:** on the day she has used every
counted calm area this act, the one she used longest ago that nothing spoils, else the least
spoiled, is chosen before the spoilers and its ground joins what nothing may reach
(`EventScheduler._calm_kept_clean()`). Without the reach rule, `test_acts`' rings of barricades
round home sealed her in on days 2 to 14: the line rules ask only a body that charges her to pass,
and a barricade charges nothing. The first version built a fresh reach for every placement and
flooded the city whenever a body was added, and took `test_acts` from 25 s to 92 s; the version
kept in step runs it in 26 s.

**Measured.** Against main (`d4a3a426f`) with `tests/probes/placement_rows.gd` over the four
samples grassy-magpie measured, 64 cities: `90210+31i` (18) and `70001+37i` (18), on which every
fitted table (`GROUND_WEIGHTS`, `VIEW_SHARE_SCALES`, `WALL_VIEW_SCALES`, `FRICTION_VIEW_SCALES`) was
fitted, and `31337+43i` and `24601+41i` (14 each), unseen by every table. Main and the branch were
run at once on each sample, every `build_day()` timed. **Every cell the probe counts is main's,
on every sample**: the rules ask what `_judge()` asked, and what replaces the repairs acts only on
what the probe never plans (a scar, a standing body, a day with every calm area used). By the
stopping rule (refit until the passes move within noise) there was nothing to refit, and no table
changed. Walls and friction on her route per day, events per city, main and the branch alike:

    walls:    day 1 7.81, 2 8.06, 3 6.80, 4 6.88, 5 7.81, 6 8.78, 7 9.09, 8 9.20, 9 4.44, 10 4.14,
              11 4.34, 12 3.47, 13 4.08, 14 4.09
    friction: day 1 16.42, 2 13.52, 3 12.53, 4 16.66, 5 19.62, 6 19.78, 7 22.38, 8 22.41, 9 20.75,
              10 21.56, 11 20.66, 12 20.77, 13 17.95, 14 20.50

The police patrol on her route is main's, 3.22 a city a day over days 1 to 14. 3b leaves the
patrol exactly at main's, still −14% on her route (3.72 → 3.22) and +22% route-adjacent
(1.52 → 1.86) against `9f148031c`; it is fitted at the end-of-refactor remeasure, after the walk
draws, not in 3b as grassy-magpie's note expected (the orchestrator's decision: step 4 moves
placement again, so a fit now would be redone).
Dawn planning time inside `build_day()` is +1.0% (2433 s → 2458 s over the 64 cities × 14 days,
eight probes at once). The escape (`tests/probes/escape_density.gd`, 10 seeds, 309 streets): its
own rows 204 → 203, planned in 279 → 317 ms a city on average.

**The day-6 man shouting.** The rig grassy-magpie measured holds at the same parity:
`tests/test_day6_yeller_met.gd`, the guarantee that the bag is rigged at the mark and he is sited
ahead of her on the street she walks, out of her view, passes unchanged on every pinned city.

**The repairs' guarantees, mutated.** With `RouteReachRule` answering yes to everything,
`test_route_rules`' ring of barricades round home keeps every barricade and cuts 2025 route tiles
off, and `test_acts` fails "day N leaves a walkable route from home to a park" on days 2 to 14.
With `_calm_kept_clean()` keeping nothing, `test_spent_park`'s days with every calm area used
leave none clean, on every seed. `test_spent_park` asserts that every used, open, unfenced area is
spoiled, where it printed a count. **Day 12's route to a clean area other than the swing's** has
its integration case back, converted (`test_events_scheduler`,
`_test_a_scar_cutting_the_clean_calm_area_off_is_not_stood`): every street but the ones home needs
to the swing, the clean area and the spoiled one is closed, and a burst water main stood through
the scars across the clean area's one street, alone, cuts it off; `_place_scars()` refuses it and
the clean area is reached under every body the day stands. With `RouteReachRule` answering yes,
the scar is stood and the case fails.

**Choices where the design was silent, open to overturn:**

- the step split in two, the bags and the draw first (grassy-magpie) and the rules next (the
  orchestrator's);
- `_best_of()` kept with its tries and its roomiest fallback for the callers outside the draw,
  judged by the same rules, until each moves to the locations (the orchestrator's answer B);
- **the escape's row a street no location takes is spent unmet**, as the slots spent it. The
  alternative is that the bag keeps it for the next street, which costs roughly a third more
  escape density;
- the reach is a dawn rule: a walk's sitings are not asked it, as the repair it replaces ran at
  dawn only, and a flood per siting would be paid in the walk's frames.

**For the end-of-refactor remeasure:** generated by the rule grassy-magpie states (z = (head −
main) / √(head + main) for every cell over each sample's cities; (a) the changes made on purpose,
then what the probe cannot see, (b) every cell with |z| > 2 pooled over all 64 cities, (c) every
cell with |z| > 2 on at least two samples with the same sign, each of the last two with a note),
from the logs of the measurement above. The script stays outside the repository for this step,
as grassy-magpie's did; the end-of-refactor remeasure makes it a `tools/` script. Its output,
verbatim:

    (a) Changed on purpose:
    - The day's placement rules are StreetRule classes composed by StreetInvalidation, with LocationFit for a location's own ground, asking what _judge() asked; _best_of() keeps its tries and its roomiest fallback, judged by the same rules.
    - DayRepairs is gone: a body that would cut a route tile off from home is refused where it would stand (RouteReachRule), where the repair dropped the widest body after the plan, and on a day she has used every calm area the one kept clean is chosen before the spoilers, where the repair stripped one after.
    - The run's scars and the park spoilers are asked RouteReachRule alone before they stand, as the repair asked them only whether home stays reached.
    - The escape draws one marble a street, offered at the street's locations in their drawing order; a row no location takes is spent unmet.

    What the probe cannot see:
    - Dawn planning time inside EventScheduler.build_day(), main and head run at once on every sample, timed per call: 2433 s → 2458 s (+1.0%; 90210+31i +1.7%, 70001+37i +1.4%, 31337+43i +0.3%, 24601+41i +0.6%).
    - The probe plans at heat 0, with no region doors, no scars, nothing standing and no calm area used, so what replaces the repairs (the reach rule against a scar or a standing body, the calm area kept clean) is not measured here; test_acts and the calm suites hold it.
    - The escape is not planned by the probe. tests/probes/escape_density.gd over its 10 seeds (309 streets): the escape's own rows 204 → 203 (military_convoy 69 → 67, abduction 39 → 39, roadblock 17 → 18, finale_explosion 79 → 79).
    - A walk's sitings are not asked the reach rule, as the repair ran at dawn only.

    (b) Outside 2σ pooled over all 64 cities (90210+31i (18), 70001+37i (18), 31337+43i (14), 24601+41i (14)), events per city per day, main → head:
    Note: (b) is empty because head places every cell as main does on all 64 cities: the rules ask what _judge() asked, and what replaces the repairs acts only on what this probe never plans. By the stopping rule, no table is refit.

    (c) Outside 2σ on at least two samples with the same sign (z per sample in the order of (b)):
    Note: the police patrol on her route is main's on every day from 4 to 14 (day 4 3.69 → 3.69, day 5 4.59 → 4.59, day 6 4.45 → 4.45, day 7 4.42 → 4.42, day 8 4.48 → 4.48, day 9 3.91 → 3.91, day 10 3.66 → 3.66, day 11 4.05 → 4.05, day 12 4.16 → 4.16, day 13 3.38 → 3.38, day 14 4.25 → 4.25). Against the tree before the bags it is still -14% on her route and +22% route-adjacent; it is fitted at the end-of-refactor remeasure, after the walk draws.

    Summary, pooled over all 64 cities:
    - walls by view, on her route: 6.36 → 6.36 (+0%, z +0.0)
    - walls by view, route-adjacent: 30.54 → 30.54 (+0%, z +0.0)
    - walls by view, off the route: 18.11 → 18.11 (+0%, z +0.0)
    - friction by view, on her route: 18.96 → 18.96 (+0%, z +0.0)
    - friction by view, route-adjacent: 9.45 → 9.45 (+0%, z +0.0)
    - friction by view, off the route: 35.82 → 35.82 (+0%, z +0.0)
    - each row per kind of ground: 48 cells, every cell main or head has, from +0% (abduction junction) to +0% (roadblock carriageway); within 2σ, from +0% to +0%
    - each row per view: 65 cells, every cell main or head has, from +0% (abduction off the route) to +0% (roadblock route-adjacent); within 2σ, from +0% to +0%

    Cells compared: 523. Outside 2σ pooled: 0. Outside on two samples or more, same sign: 0.
