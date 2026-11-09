# minty-quail — The day's open locations are drawn as she walks · 2026-11-09

minty-quail's `placement-by-construction.md`, its fourth step's first part (4a); 3c is downy-toad.

**Built.** The dawn draws every row that blocks the way and leaves every other location for the
walk, which draws among the rows that block nothing as she comes near (`WalkDraw`, handed on as
`DayEvents.walk_draw()`, run by `EventManager` each tick before the streaming):

- **What the walk draws blocks nothing, and nothing on the walk asks whether a route is open**
  (the orchestrator's reading of gray-dolphin #1173 30 and 33, open to the player's overturn; it
  overturns the orchestrator's earlier ruling that the walk's draws ask the reach rule on the dawn's
  kept reach). The dawn sweeps every location in the day's order (`LocationDraw.draw_all()`,
  `DayLocations.drawing_order()`), each from its view's bag as the whole draw would, and stands only
  the rows that block the way (`EventDef.blocks_the_way()`), each asked every dawn rule, the reach
  among them, and the rows her walk sites (the poster crew), handed to it with no position; a location
  that drew anything else is left open. The walk draws from bags of its own and never accepts a row
  the dawn draws, judged by every rule but the reach (`EventScheduler._draw_the_locations()`), and the
  day's reach (`DayReach`) is worked out once as the walk starts and never again. No beat needs a
  walk-time reach ask: the walk's sitings (`WalkSiting`) asked none before this step either; that a
  beat which blocks takes the place of a body already placed off the route is 4b's.
- **When** (the orchestrator's reading (a)): the nearest location out of her view within the band
  past the stream radius (`WalkDraw.BAND_FAR`), those ahead of her heading first, is drawn a step a
  tick; any location out of her view within `WalkDraw.MUST_DRAW` is drawn whole on that tick,
  however many a sharp turn brings near, and `WalkDraw.forced()` counts them. A location in her view
  is never drawn, and one part-way drawn holds nothing until its draw ends. Before her first step
  every location within `MUST_DRAW` of her door is drawn whole.
- **Each draw stands as it is drawn**: during the walk the day's ground stands every draw before the
  next location is judged (`RuledLocationGround.stand()`), so a batch drawn at once (the start of the
  walk, a tick's forced draws, a dev spawn's `draw_everywhere()`) keeps the spacing, the lethal field
  and every other rule between its own draws.
- **A step** (decision B): one marble from the view's bag, or one tile of a row's offer
  (`LocationGround.begin_offer()`, `RuledOffer`, `ViewBag.Drawing`'s "still weighing"); a candidate
  kept over ticks is asked again if what the rules read changed since.
- **A walk's caps are a rate** (the orchestrator's reading, open to the player's overturn): a row's
  cap is spread over the locations the walk may draw by each location's chance of the row (its share
  of the location's bag times the location's weight for it), so once the walk has drawn locations
  holding a share of that chance the row may have stood that share of its cap, rounded up or down at
  random once per row (`LocationDraw`'s `spread`, on `WALK_CAPS_SALT`). The dawn spent a cap over the
  whole city as each location's chance came up, and so does the walk.
- **A sidewalk is drawn after its section** (`DayLocations.drawn_before()`), and waits while she can
  see the section.
- **The reach rule** works out what a body cuts off by growing the pieces beside its disc rather than
  flooding the city again (`tests/test_route_rules.gd` holds that it answers what the flood answers),
  and a disc over home cuts off everything.
- The dawn's crew hand-over (`_hand_to_her_walk()`) is gone: the sweep hands a crew over as it draws
  it (`LocationDraw._as_drawn()`). A dev spawn at a row with none placed draws every location from her
  door first (`EventManager.draw_everywhere()`). Suites that ask the day's rules of every row draw
  every location at once from her door (`tests/drawn_day.gd`), one sample of the draws a walk could
  make. The pacing sweep's walled beat comes from city 555 (days 1 and 11).
- **The refit** (the orchestrator's decision, open to the player's overturn): keep the walk's draws,
  the player's design, and refit so what she meets matches main's. `WALK_SHARE_SCALES` scales the
  walk bags' shares per view and day, since the walk draws among every body the dawn stood, which
  refuse more of its draws than the whole sweep refused; `GROUND_WEIGHTS` is refit for the rows the
  walk draws (the chatting mother, the alley mouse, the pigeon flock, the dog walker, the man
  shouting, the police patrol), and `WALL_VIEW_SCALES` on her route is stepped down, since the sweep
  stands bodies with no row that blocks nothing standing to refuse them.

**Measured.** `tests/probes/walk_rows.gd` plans each day as the game does and walks the day's
longest route out and home at walking speed, a tick a thirtieth of a second, the director siting as
it does, counting each placed row as it comes within the stream radius. Against main (`0d2e9f5ce`)
over the four samples, 64 cities, main's walks run once:

- **The refit**: fitted on `90210+31i` and `70001+37i`, checked on `31337+43i` and `24601+41i`. With
  the bodies at dawn and the caps a rate, before any table moved, 128 of 498 cells were outside 2σ
  pooled, friction on her route −19% a walk a day. Over four passes on the fitted pair the cells
  outside 2σ pooled went 27, 26, 15 and 8, none on both samples with the same sign after the last
  two; the unseen pair has 16 after the last, none on both its samples. Over all four samples after
  it, a walk a day, main → branch: walls on her route 3.97 → 4.04 (+2%, z +0.8), route-adjacent
  12.89 → 13.32 (+3%, z +2.5), off the route 4.62 → 4.70 (+2%); friction on her route 11.55 → 11.76
  (+2%, z +1.3), route-adjacent 4.39 → 4.55 (+4%, z +1.6), off the route 11.67 → 11.29 (−3%, z −2.4);
  every day's count of what she meets within 4% of main's, z within ±1.5.
- **What still moves**, by the stopping rule: 24 cells outside 2σ pooled and 6 on two samples with
  the same sign, where chance puts about 25 and 1: the chatting mother on a junction box 0.14 → 0.22
  a walk a day, the alley mouse in an alley 1.89 → 1.67 (off the route 1.80 → 1.57), the square's
  poster crew 0.04 → 0.06, the pigeon flock on open ground 0.04 → 0.02. The fit stops here.
- **Where the capped rows are met** (the six whose caps bound what she met when the dawn drew the
  whole city: the abduction, the alley mouse, the charging dog, the chatting mother, the pigeon flock
  and the roadblock): on main 16% of their encounters come within the stream radius of her door at
  the start (1,207 of 7,650) and 2,823 in the second half of the walk out; on the branch 11% (828 of
  7,373) and 2,939. The flat walk caps this replaces put them at her door.
- **Frame cost**, three cities of sample `90210+31i`, 42 walks, one at a time: the walk's draw takes
  a median tick of 1 µs, a p99 of 0.59 ms (the median over walks; the worst walk's 0.79 ms) and a
  worst tick of 11.3 ms, none over 16 ms, 21.1 s in all. Main's siting on the same walks: median
  2 µs, p99 0.41 ms (worst walk's 1.32 ms), worst tick 56.7 ms, over 16 ms on 36 of 42 walks, so main
  already has ticks over 16 ms. Forced draws: 0.11% of the locations drawn (62 of 54,024).

**For the end-of-refactor remeasure**, generated by the rule grassy-magpie states, from the logs of
the last pass against main's. Its output, verbatim:

    (a) Changed on purpose:
    - Every row that blocks the way, and every row her walk sites, is drawn at dawn by a sweep of every location in the day's order, standing only those rows; every other location is drawn as she walks near it (WalkDraw), among the rows that block nothing, nearest ahead first, out of her view, a sidewalk after its section, each draw standing before the next is judged.
    - A walk's caps are a rate, spread over the locations it may draw by each one's chance of the row.
    - WALK_SHARE_SCALES, GROUND_WEIGHTS for the rows the walk draws and WALL_VIEW_SCALES on her route are refit to what she met on main's walks.
    - The run log's baseline (tests/fixtures/observed_run_log.txt) is re-recorded: only its plan line moves, which counts the walk's plans at its start, the dawn's and the locations drawn within reach of her door; every other line is unchanged.

    What the probe cannot see:
    - The poster crews: their ground is the buildings' blank fronts, which a city built without its scene does not have, so neither tree's probe walk sites one.
    - The crowd learns a walk-drawn row when it is drawn, out of her view, rather than at dawn.
    - A dev spawn at a row with none placed has the walk draw every location from her door first (EventManager.draw_everywhere()).
    - The tables are fitted at heat 0, on the day's longest route out and home, with no scars and no calm area used.

    (b) Outside 2σ pooled over all 64 walks per day (90210+31i (18), 70001+37i (18), 31337+43i (14), 24601+41i (14)), events met per walk per day, main → head:
    - friction by view: off the route all days, 11.67 → 11.29 (-3%, z -2.4); z per sample -1.3 / -1.3 / -0.3 / -1.8
    - friction by view and day: on her route day 3, 9.69 → 10.89 (+12%, z +2.1); z per sample +0.2 / +1.4 / +1.3 / +1.4
    - friction by view and day: on her route day 4, 12.55 → 13.88 (+11%, z +2.1); z per sample +1.3 / +0.9 / +0.8 / +1.0
    - row by day: poster_crew_square day 9, 0.02 → 0.12 (+700%, z +2.3); z per sample +1.7 / +0.0 / +1.4 / +1.4
    - row by day: dog_walker day 12, 9.22 → 8.08 (-12%, z -2.2); z per sample -0.1 / -1.4 / -1.6 / -1.2
    - row by day: homeless_yeller day 8, 4.89 → 4.11 (-16%, z -2.1); z per sample -0.6 / -1.2 / -1.1 / -1.4
    - row by day: leaf_blower day 8, 4.41 → 5.19 (+18%, z +2.0); z per sample +0.3 / -0.1 / +1.5 / +2.5
    - row by kind of ground: chatting_mother junction, 0.14 → 0.22 (+62%, z +4.2); z per sample +1.1 / +3.3 / +1.0 / +3.2
    - row by kind of ground: alley_mouse alley, 1.89 → 1.67 (-11%, z -3.4); z per sample -2.5 / -0.9 / -0.7 / -2.7
    - row by kind of ground: pigeon_flock sidewalk, 1.28 → 1.12 (-13%, z -3.1); z per sample -1.1 / -1.8 / -1.7 / -1.7
    - row by kind of ground: construction sidewalk, 1.95 → 2.14 (+10%, z +2.8); z per sample +1.3 / +2.0 / +0.8 / +1.5
    - row by kind of ground: poster_crew_square open, 0.04 → 0.06 (+67%, z +2.3); z per sample +2.2 / -0.2 / +0.3 / +2.5
    - row by kind of ground: abduction sidewalk, 0.15 → 0.11 (-26%, z -2.2); z per sample -1.3 / -2.3 / -0.1 / -0.6
    - row by kind of ground: police_patrol carriageway, 2.16 → 2.01 (-7%, z -2.2); z per sample -0.2 / -2.0 / -1.4 / -0.8
    - row by kind of ground: pigeon_flock open, 0.04 → 0.02 (-43%, z -2.0); z per sample -0.2 / -2.3 / -2.3 / +0.3
    - row by view: alley_mouse off the route, 1.80 → 1.57 (-13%, z -3.7); z per sample -2.7 / -1.2 / -0.8 / -2.8
    - row by view: construction on her route, 0.38 → 0.48 (+28%, z +3.4); z per sample +1.7 / +1.8 / +2.0 / +1.3
    - row by view: poster_crew_square off the route, 0.02 → 0.05 (+109%, z +2.9); z per sample +2.7 / -0.2 / +0.3 / +3.0
    - row by view: pigeon_flock off the route, 1.07 → 0.95 (-11%, z -2.4); z per sample -1.5 / -0.7 / -1.4 / -1.3
    - row by view: chatting_mother on her route, 0.61 → 0.70 (+15%, z +2.3); z per sample +1.3 / +1.2 / +1.6 / +0.5
    - row by view: police_patrol on her route, 1.78 → 1.64 (-8%, z -2.3); z per sample -0.3 / -0.4 / -1.7 / -2.3
    - row by view: leaf_blower route-adjacent, 2.90 → 3.08 (+6%, z +2.2); z per sample +1.2 / +1.0 / +1.1 / +1.2
    - walls by view: route-adjacent all days, 12.89 → 13.32 (+3%, z +2.5); z per sample +1.9 / +0.6 / +0.8 / +1.6
    - walls by view and day: on her route day 6, 5.38 → 6.23 (+16%, z +2.0); z per sample +1.1 / +1.7 / -0.1 / +1.2

    (c) Outside 2σ on at least two samples with the same sign:
    - row by kind of ground: chatting_mother junction, 0.14 → 0.22 (+62%, z +4.2); z per sample +1.1 / +3.3 / +1.0 / +3.2
    - row by kind of ground: alley_mouse alley, 1.89 → 1.67 (-11%, z -3.4); z per sample -2.5 / -0.9 / -0.7 / -2.7
    - row by kind of ground: poster_crew_square open, 0.04 → 0.06 (+67%, z +2.3); z per sample +2.2 / -0.2 / +0.3 / +2.5
    - row by kind of ground: pigeon_flock open, 0.04 → 0.02 (-43%, z -2.0); z per sample -0.2 / -2.3 / -2.3 / +0.3
    - row by view: poster_crew_square off the route, 0.02 → 0.05 (+109%, z +2.9); z per sample +2.7 / -0.2 / +0.3 / +3.0
    - row by view: alley_mouse off the route, 1.80 → 1.57 (-13%, z -3.7); z per sample -2.7 / -1.2 / -0.8 / -2.8

    Per day, events met on the walk and per view, main → head:
    - day 1: all 47.48 → 49.08 (+3%, z +1.3); on her route 17.70 → 18.19 (+3%, z +0.6); route-adjacent 19.44 → 20.09 (+3%, z +0.8); off the route 10.34 → 10.80 (+4%, z +0.8)
    - day 2: all 50.86 → 52.14 (+3%, z +1.0); on her route 15.98 → 16.48 (+3%, z +0.7); route-adjacent 21.69 → 22.56 (+4%, z +1.1); off the route 13.19 → 13.09 (-1%, z -0.1)
    - day 3: all 52.47 → 54.34 (+4%, z +1.5); on her route 15.66 → 16.55 (+6%, z +1.3); route-adjacent 21.61 → 22.95 (+6%, z +1.6); off the route 15.20 → 14.84 (-2%, z -0.5)
    - day 4: all 52.75 → 53.98 (+2%, z +1.0); on her route 18.03 → 19.47 (+8%, z +1.9); route-adjacent 19.41 → 19.53 (+1%, z +0.2); off the route 15.31 → 14.98 (-2%, z -0.5)
    - day 5: all 53.62 → 52.75 (-2%, z -0.7); on her route 19.17 → 18.41 (-4%, z -1.0); route-adjacent 19.28 → 19.78 (+3%, z +0.6); off the route 15.17 → 14.56 (-4%, z -0.9)
    - day 6: all 59.84 → 61.11 (+2%, z +0.9); on her route 20.55 → 21.45 (+4%, z +1.1); route-adjacent 21.34 → 22.80 (+7%, z +1.7); off the route 17.95 → 16.86 (-6%, z -1.5)
    - day 7: all 64.19 → 63.80 (-1%, z -0.3); on her route 24.42 → 24.30 (-1%, z -0.1); route-adjacent 22.09 → 22.66 (+3%, z +0.7); off the route 17.67 → 16.84 (-5%, z -1.1)
    - day 8: all 63.08 → 64.50 (+2%, z +1.0); on her route 23.52 → 23.91 (+2%, z +0.5); route-adjacent 19.64 → 20.75 (+6%, z +1.4); off the route 19.92 → 19.84 (-0%, z -0.1)
    - day 9: all 40.42 → 40.58 (+0%, z +0.1); on her route 11.58 → 11.94 (+3%, z +0.6); route-adjacent 11.30 → 11.11 (-2%, z -0.3); off the route 17.55 → 17.53 (-0%, z -0.0)
    - day 10: all 42.34 → 41.39 (-2%, z -0.8); on her route 12.30 → 11.59 (-6%, z -1.2); route-adjacent 12.34 → 12.72 (+3%, z +0.6); off the route 17.70 → 17.08 (-4%, z -0.8)
    - day 11: all 41.42 → 41.72 (+1%, z +0.3); on her route 12.22 → 12.08 (-1%, z -0.2); route-adjacent 12.30 → 12.73 (+4%, z +0.7); off the route 16.91 → 16.91 (+0%, z +0.0)
    - day 12: all 45.00 → 44.83 (-0%, z -0.1); on her route 12.14 → 12.11 (-0%, z -0.1); route-adjacent 12.45 → 13.44 (+8%, z +1.5); off the route 20.41 → 19.28 (-6%, z -1.4)
    - day 13: all 56.31 → 55.69 (-1%, z -0.5); on her route 11.25 → 10.84 (-4%, z -0.7); route-adjacent 22.03 → 22.50 (+2%, z +0.6); off the route 23.03 → 22.34 (-3%, z -0.8)
    - day 14: all 49.47 → 48.72 (-2%, z -0.6); on her route 13.77 → 13.81 (+0%, z +0.1); route-adjacent 12.98 → 12.67 (-2%, z -0.5); off the route 22.72 → 22.23 (-2%, z -0.6)

    Summary, pooled over all 64 walks per day:
    - walls by view, on her route: 3.97 → 4.04 (+2%, z +0.8)
    - walls by view, route-adjacent: 12.89 → 13.32 (+3%, z +2.5)
    - walls by view, off the route: 4.62 → 4.70 (+2%, z +0.7)
    - friction by view, on her route: 11.55 → 11.76 (+2%, z +1.3)
    - friction by view, route-adjacent: 4.39 → 4.55 (+4%, z +1.6)
    - friction by view, off the route: 11.67 → 11.29 (-3%, z -2.4)
    - every row, on her route: 16.31 → 16.51 (+1%, z +1.1)
    - every row, route-adjacent: 17.71 → 18.31 (+3%, z +3.0)
    - every row, off the route: 17.36 → 16.94 (-2%, z -2.1)

    Cells compared: 498. Outside 2σ pooled: 24. Outside on two samples or more, same sign: 6.
