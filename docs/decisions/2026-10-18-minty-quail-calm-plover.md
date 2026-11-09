# minty-quail — The day's open locations are drawn as she walks · 2026-11-09

minty-quail's `placement-by-construction.md`, its fourth step's first part (4a); 3c is downy-toad.

**Built.** The dawn fixes the fixed parts, the scripted rows and day 13's roadblocks and leaves every
other location undrawn; the walk draws each from its view's bag as she comes near it (`WalkDraw`,
handed on as `DayEvents.walk_draw()`, run by `EventManager` each tick before the streaming):

- **When** (the orchestrator's reading (a), open to the player's overturn): the nearest location out
  of her view within the band past the stream radius (`WalkDraw.BAND_FAR`: the radius, its
  hysteresis and two seconds of walking), those ahead of her heading first, is drawn a step a tick;
  any location out of her view within `WalkDraw.MUST_DRAW` (the radius and a second of walking) is
  drawn whole on that tick, however many a sharp turn brings near, and `WalkDraw.forced()` counts
  them. A location in her view is never drawn, and one part-way drawn records and stands nothing
  until its draw ends, so nothing of it can stream in. Before her first step every location within
  `MUST_DRAW` of her start is drawn whole.
- **A step** (decision B, the orchestrator's): one marble taken from the view's bag, or one tile of
  a row's offer. The brief said one offer or marble ask a tick; one offer was measured at up to
  74 ms, since it asks the row at every tile of the location, so the step is one candidate tile
  (`LocationGround.begin_offer()`, `RuledOffer`), and `ViewBag.Drawing` takes an answer of "still
  weighing" for a marble. A candidate kept over ticks is asked the day's rules again on the offer's
  last step if the walk gained a plan since, and the offer is nothing if that plan now refuses it.
  A marble another draw took meanwhile is refused. The bag's state follows the walk's ticks, so a
  replay of the same walk draws the same.
- **A sidewalk is drawn after its section** (`DayLocations.drawn_before()`), as the dawn's street
  order gave, so an event that takes a section takes the sidewalks in it before they draw; a
  sidewalk whose section she can see waits. `DayLocations.drawing_order()` goes with its last reader.
- **The reach rule is asked at walk time** against the walk's plans (`RuledLocationGround` judges
  against the walk once it starts), using the day's reach worked out at dawn and kept in step
  (`RouteReachRule.prepare()`, on the loading screen). A body that leaves is kept blocking until the
  day ends, which can only refuse, never cut a route off, and spares a flood. What a body cuts off is
  worked out by growing the reached pieces beside its disc a tile at a time in turn until one piece
  is left, rather than flooding the city from home again; `tests/test_route_rules.gd` holds that it
  answers what the flood answers, body for body.
- **A row handed to her walk** (the poster crew) is drawn unplaced (`LocationDraw.finish()`) and
  handed to the director (`EventDirector.hand_to_her_walk()`), as the dawn handed one over.
- `WalkSiting` keeps its beats: the fire, the crews, the man shouting, the van, the added mast and
  the dusk fire are sited as before; 4b makes them rigs (decisions (b) keep the rig at 2 events,
  (c) the split, (d) the dusk fire, all the orchestrator's, open to the player's overturn).
- **The day's reach learns what the walk draws**: a body a location the walk drew shuts its ground
  in the walk's `DayReach` (`shut_what_was_drawn()`), flooded again when next asked, so a mark the
  resistance relocates mid-walk is never sent to an alley a drawn body closed off; a body a task puts
  up later still shuts nothing there.
- **The caps and the ground weights are refit** (the orchestrator's decision, open to the player's
  overturn): drawn as she walks, a row's cap (`max_per_day`) counted only what her walk drew, so a
  capped row was met at its cap where the dawn had spent it over the city, and the fitted ground
  weights sent those rows to the junction boxes, which drew last at dawn and draw when she comes near
  them now. Keeping the walk's draws, which are the player's design, the refactor keeps what she
  meets: `EventScheduler.WALK_CAPS` holds the most of each capped row the walk's draw stands a day
  (the charging dog, the chatting mother, the abduction, the alley mouse, the pigeon flock and the
  roadblock), rounded up or down on the caps' stream as every cap is, with the gatehouse day's
  thinning on top, and `GROUND_WEIGHTS` is refit for the order.
- Suites that ask the day's rules of the day's rows draw every location at once, nearest her door
  first (`tests/drawn_day.gd`, `WalkDraw.draw_everywhere()`); the pacing sweep's walled beat comes
  from city 555 (days 1 and 11), since city 88's rested on the dawn's draw order. A crew drawn by a
  location is checked handed on unplaced; the rows drawn after it are spaced without it, as in play.

**Measured.** `tests/probes/walk_rows.gd` plans each day as the game does and walks the day's
longest route out and home at walking speed, a tick a thirtieth of a second, the director siting as
it does, counting each placed row as it comes within the stream radius. Against main (`0d2e9f5ce`)
over the four samples, 64 cities, main's walks run once:

- **Before the refit**, 123 of 498 cells were outside 2σ pooled and 72 on two samples with the same
  sign: off the route +14% a walk a day, on her route +4%; the charging dog about 1 → 3 a day on days
  4 to 8, the abduction 1.02 → 3.12 on day 8, the chatting mother on a junction box 0.14 → 1.98 and
  on a sidewalk 0.87 → 0.02.
- **The refit**, fitted on `90210+31i` and `70001+37i` and checked on `31337+43i` and `24601+41i`,
  each pass stepping a capped row's walk cap by main's count over the branch's on a day outside 1σ,
  and a row's ground weight on a kind of ground outside 1.5σ, toward main's. Cells outside 2σ pooled
  on the fitted pair went 43, 15, 21 and 16 over the four passes, and 18 on the unseen pair after the
  fourth, about what chance puts outside 2σ of 497 cells. Over all four samples after the fourth:
  walls on her route 3.97 → 4.08 a walk a day (+3%, z +1.2), route-adjacent 12.89 → 13.05 (+1%),
  off the route 4.62 → 4.41 (−5%, z −2.1); friction on her route 11.55 → 11.69 (+1%, z +0.9),
  route-adjacent 4.39 → 4.45 (+1%), off the route 11.67 → 11.38 (−2%, z −1.8); every day's count of
  what she meets within 4% of main's, z within ±1.6.
- **What still moves**, stated by the stopping rule: 28 cells are outside 2σ pooled and 7 on two
  samples with the same sign, and the fit stops here because what moves is a capped row's view, which
  no table steps (`GROUND_WEIGHTS` is per kind of ground, the view scales per role): a capped row is
  drawn where she first comes near, so its view leans to her route. The chatting mother off the route
  0.24 → 0.07 a walk a day and on her route 0.61 → 0.76; the charging dog on her route 0.03 → 0.13
  and off the route 0.50 → 0.32; the pigeon flock off the route 1.07 → 0.91; the roadblock off the
  route 0.36 → 0.28; the protest on day 12 2.83 → 3.55. Off the route every row is −4% (17.36 →
  16.70, z −3.4).
- **Frame cost**, three cities of sample `90210+31i`, 42 walks, main and then the branch, one at a
  time: the walk's draw takes a median tick of 1 µs, a p99 of 0.80 ms (the median over walks; the
  worst walk's 1.57 ms) and a worst tick of 17.6 ms, over 16 ms on 1 walk of 42. Main's siting on the
  same walks: median 2 µs, p99 0.41 ms (worst walk's 1.32 ms), worst tick 56.7 ms, over 16 ms on 36
  of 42 walks, so main already has ticks over 16 ms. In all, the draw costs 23.2 s over the walks
  against the siting's 6.8 s. The refit moves none of it: on the same walks after it, the
  draw's median tick 1 µs, p99 0.72 ms (worst walk's 1.68 ms), worst tick 12.4 ms, none over 16 ms,
  22.9 s in all.
- **Forced draws**: 0.19% of the locations drawn on those walks (105 of 55,884; 0.29% after the
  refit), 0.31% to 0.44% on the four samples.

**For the end-of-refactor remeasure**, generated by the rule grassy-magpie states, from the logs of
the fourth pass against main's. Its output, verbatim:

    (a) Changed on purpose:
    - Every location the dawn leaves open is drawn as she walks near it (WalkDraw), nearest ahead first, out of her view, a sidewalk after its section.
    - A row's cap counts what the walk drew, so the capped rows take the walk's own caps (EventScheduler.WALK_CAPS: abduction, alley_mouse, charging_dog, chatting_mother, pigeon_flock, roadblock), fitted to what she met on main's walks, and GROUND_WEIGHTS is refit for the walk's order, in which the junction boxes no longer draw last.
    - A poster crew a location draws joins the walk unplaced for the director to site, as the dawn handed one over.
    - The run log's baseline (tests/fixtures/observed_run_log.txt) is re-recorded: only its plan line moves, which counts the walk's plans at its start, the dawn's and the locations drawn within reach of her start; every other line is unchanged.

    What the probe cannot see:
    - The poster crews: their ground is the buildings' blank fronts, which a city built without its scene does not have, so neither tree's probe walk sites one (WalkSiting waits with "no tile of its ground on the branch ahead of her").
    - RouteReachRule keeps a body that has left (spent) blocking until the day ends; the probe spends nothing, so it cannot see whether that refuses a draw main would have allowed.
    - The walk's DayReach shuts what a location the walk drew stands on (a relocated mark is never sent behind it); the crowd learns a walk-drawn body when it is drawn, out of her view, rather than at dawn.
    - A dev spawn at a row with none placed has the walk draw every location first (EventManager.draw_everywhere()).
    - The walk's caps are fitted at heat 0, on the day's longest route out and home, with no scars and no calm area used; a walk that covers more of the city meets a capped row no more often.

    (b) Outside 2σ pooled over all 64 walks per day (90210+31i (18), 70001+37i (18), 31337+43i (14), 24601+41i (14)), events met per walk per day, main → head:
    - friction by view and day: on her route day 11, 9.20 → 10.36 (+13%, z +2.1); z per sample +0.4 / +1.2 / +1.3 / +1.4
    - row by day: homeless_yeller day 13, 4.30 → 3.39 (-21%, z -2.6); z per sample -2.0 / -0.5 / -0.4 / -2.4
    - row by day: market_stall day 10, 1.58 → 1.11 (-30%, z -2.3); z per sample -1.6 / -2.3 / -0.4 / +0.0
    - row by day: protest day 12, 2.83 → 3.55 (+25%, z +2.3); z per sample +2.1 / +0.0 / +2.3 / +0.4
    - row by day: leaf_blower day 2, 5.72 → 4.80 (-16%, z -2.3); z per sample -0.6 / -0.9 / -2.2 / -0.9
    - row by day: dog_walker day 11, 8.44 → 9.64 (+14%, z +2.3); z per sample +0.7 / +1.6 / +0.5 / +1.7
    - row by day: police_patrol day 4, 5.97 → 5.03 (-16%, z -2.3); z per sample -1.8 / -1.5 / -0.2 / -1.0
    - row by day: construction day 12, 1.25 → 0.84 (-32%, z -2.2); z per sample -1.5 / -1.7 / +0.0 / -1.3
    - row by day: market_stall day 14, 1.53 → 2.06 (+35%, z +2.2); z per sample +1.2 / +1.3 / +0.9 / +1.0
    - row by day: poster_crew_square day 4, 0.08 → 0.00 (-100%, z -2.2); z per sample -1.4 / -1.7 / +0.0 / +0.0
    - row by day: ice_cream_van day 2, 2.30 → 2.92 (+27%, z +2.2); z per sample +0.0 / +0.9 / +2.4 / +1.0
    - row by day: abduction day 12, 0.59 → 0.34 (-42%, z -2.1); z per sample -0.3 / -1.1 / -1.5 / -1.1
    - row by kind of ground: police_patrol carriageway, 2.16 → 1.95 (-10%, z -3.0); z per sample -0.6 / -3.2 / -1.5 / -0.7
    - row by kind of ground: ice_cream_van sidewalk, 1.53 → 1.69 (+11%, z +2.7); z per sample +0.8 / +0.2 / +3.0 / +1.5
    - row by kind of ground: police_patrol junction, 1.69 → 1.82 (+8%, z +2.1); z per sample +0.6 / +0.4 / +2.3 / +1.0
    - row by view: chatting_mother off the route, 0.24 → 0.07 (-72%, z -9.2); z per sample -4.8 / -4.4 / -4.2 / -5.1
    - row by view: charging_dog on her route, 0.03 → 0.13 (+314%, z +7.5); z per sample +4.7 / +3.7 / +2.7 / +3.7
    - row by view: charging_dog off the route, 0.50 → 0.32 (-36%, z -5.9); z per sample -3.7 / -3.1 / -1.2 / -3.7
    - row by view: charging_dog route-adjacent, 0.06 → 0.12 (+93%, z +4.1); z per sample +2.9 / +1.9 / +1.7 / +1.6
    - row by view: chatting_mother on her route, 0.61 → 0.76 (+25%, z +3.8); z per sample +2.3 / +1.8 / +2.1 / +1.4
    - row by view: pigeon_flock off the route, 1.07 → 0.91 (-15%, z -3.5); z per sample -2.4 / -0.9 / -1.8 / -2.0
    - row by view: abduction route-adjacent, 0.03 → 0.06 (+122%, z +3.3); z per sample +0.9 / +1.6 / +1.9 / +2.2
    - row by view: roadblock off the route, 0.36 → 0.28 (-22%, z -3.0); z per sample -0.5 / -2.2 / -0.9 / -2.6
    - row by view: ice_cream_van route-adjacent, 1.30 → 1.44 (+11%, z +2.6); z per sample +0.8 / +0.1 / +2.9 / +1.7
    - row by view: homeless_yeller off the route, 1.23 → 1.10 (-10%, z -2.4); z per sample +1.3 / -1.8 / -1.3 / -3.3
    - row by view: abduction off the route, 0.30 → 0.25 (-17%, z -2.1); z per sample -1.0 / -1.5 / -0.5 / -1.1
    - view by day: off the route day 13, 23.03 → 21.19 (-8%, z -2.2); z per sample -1.0 / -2.5 / +0.4 / -1.3
    - walls by view: off the route all days, 4.62 → 4.41 (-5%, z -2.1); z per sample -0.8 / -1.0 / +0.0 / -2.5

    (c) Outside 2σ on at least two samples with the same sign:
    - row by day: protest day 12, 2.83 → 3.55 (+25%, z +2.3); z per sample +2.1 / +0.0 / +2.3 / +0.4
    - row by view: chatting_mother off the route, 0.24 → 0.07 (-72%, z -9.2); z per sample -4.8 / -4.4 / -4.2 / -5.1
    - row by view: charging_dog on her route, 0.03 → 0.13 (+314%, z +7.5); z per sample +4.7 / +3.7 / +2.7 / +3.7
    - row by view: charging_dog off the route, 0.50 → 0.32 (-36%, z -5.9); z per sample -3.7 / -3.1 / -1.2 / -3.7
    - row by view: roadblock off the route, 0.36 → 0.28 (-22%, z -3.0); z per sample -0.5 / -2.2 / -0.9 / -2.6
    - row by view: pigeon_flock off the route, 1.07 → 0.91 (-15%, z -3.5); z per sample -2.4 / -0.9 / -1.8 / -2.0
    - row by view: chatting_mother on her route, 0.61 → 0.76 (+25%, z +3.8); z per sample +2.3 / +1.8 / +2.1 / +1.4

    Per day, events met on the walk and per view, main → head:
    - day 1: all 47.48 → 47.48 (+0%, z +0.0); on her route 17.70 → 17.98 (+2%, z +0.4); route-adjacent 19.44 → 19.52 (+0%, z +0.1); off the route 10.34 → 9.98 (-3%, z -0.6)
    - day 2: all 50.86 → 51.08 (+0%, z +0.2); on her route 15.98 → 15.58 (-3%, z -0.6); route-adjacent 21.69 → 22.73 (+5%, z +1.3); off the route 13.19 → 12.77 (-3%, z -0.7)
    - day 3: all 52.47 → 53.23 (+1%, z +0.6); on her route 15.66 → 16.45 (+5%, z +1.1); route-adjacent 21.61 → 22.47 (+4%, z +1.0); off the route 15.20 → 14.31 (-6%, z -1.3)
    - day 4: all 52.75 → 51.52 (-2%, z -1.0); on her route 18.03 → 18.34 (+2%, z +0.4); route-adjacent 19.41 → 18.73 (-3%, z -0.9); off the route 15.31 → 14.44 (-6%, z -1.3)
    - day 5: all 53.62 → 53.86 (+0%, z +0.2); on her route 19.17 → 20.66 (+8%, z +1.9); route-adjacent 19.28 → 19.12 (-1%, z -0.2); off the route 15.17 → 14.08 (-7%, z -1.6)
    - day 6: all 59.84 → 60.91 (+2%, z +0.8); on her route 20.55 → 21.22 (+3%, z +0.8); route-adjacent 21.34 → 21.84 (+2%, z +0.6); off the route 17.95 → 17.84 (-1%, z -0.1)
    - day 7: all 64.19 → 64.08 (-0%, z -0.1); on her route 24.42 → 24.81 (+2%, z +0.4); route-adjacent 22.09 → 22.73 (+3%, z +0.8); off the route 17.67 → 16.53 (-6%, z -1.6)
    - day 8: all 63.08 → 63.09 (+0%, z +0.0); on her route 23.52 → 23.09 (-2%, z -0.5); route-adjacent 19.64 → 20.55 (+5%, z +1.1); off the route 19.92 → 19.45 (-2%, z -0.6)
    - day 9: all 40.42 → 39.80 (-2%, z -0.6); on her route 11.58 → 11.66 (+1%, z +0.1); route-adjacent 11.30 → 11.62 (+3%, z +0.5); off the route 17.55 → 16.52 (-6%, z -1.4)
    - day 10: all 42.34 → 41.72 (-1%, z -0.5); on her route 12.30 → 11.98 (-3%, z -0.5); route-adjacent 12.34 → 11.67 (-5%, z -1.1); off the route 17.70 → 18.06 (+2%, z +0.5)
    - day 11: all 41.42 → 42.97 (+4%, z +1.3); on her route 12.22 → 13.22 (+8%, z +1.6); route-adjacent 12.30 → 12.53 (+2%, z +0.4); off the route 16.91 → 17.22 (+2%, z +0.4)
    - day 12: all 45.00 → 43.17 (-4%, z -1.6); on her route 12.14 → 12.45 (+3%, z +0.5); route-adjacent 12.45 → 11.69 (-6%, z -1.2); off the route 20.41 → 19.03 (-7%, z -1.8)
    - day 13: all 56.31 → 55.02 (-2%, z -1.0); on her route 11.25 → 11.33 (+1%, z +0.1); route-adjacent 22.03 → 22.50 (+2%, z +0.6); off the route 23.03 → 21.19 (-8%, z -2.2)
    - day 14: all 49.47 → 49.59 (+0%, z +0.1); on her route 13.77 → 13.56 (-1%, z -0.3); route-adjacent 12.98 → 13.72 (+6%, z +1.1); off the route 22.72 → 22.31 (-2%, z -0.5)

    Summary, pooled over all 64 walks per day:
    - walls by view, on her route: 3.97 → 4.08 (+3%, z +1.2)
    - walls by view, route-adjacent: 12.89 → 13.05 (+1%, z +0.9)
    - walls by view, off the route: 4.62 → 4.41 (-5%, z -2.1)
    - friction by view, on her route: 11.55 → 11.69 (+1%, z +0.9)
    - friction by view, route-adjacent: 4.39 → 4.45 (+1%, z +0.5)
    - friction by view, off the route: 11.67 → 11.38 (-2%, z -1.8)
    - every row, on her route: 16.31 → 16.60 (+2%, z +1.5)
    - every row, route-adjacent: 17.71 → 17.96 (+1%, z +1.3)
    - every row, off the route: 17.36 → 16.70 (-4%, z -3.4)

    Cells compared: 498. Outside 2σ pooled: 28. Outside on two samples or more, same sign: 7.
