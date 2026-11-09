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
- Suites that ask the day's rules of the day's rows draw every location at once
  (`tests/drawn_day.gd`); the pacing sweep's walled beat comes from city 555 (days 1 and 11), since
  city 88's rested on the dawn's draw order.

**Measured.** `tests/probes/walk_rows.gd` plans each day as the game does and walks the day's
longest route out and home at walking speed, a tick a thirtieth of a second, the director siting as
it does, counting each placed row as it comes within the stream radius. Against main (`0d2e9f5ce`),
over the four samples, 64 cities, main and the branch run at once on each:

- **Not at parity.** 123 of 498 cells are outside 2σ pooled and 72 on two samples with the same
  sign. Events met per walk rise 3% to 15% a day; off the route +14% (17.36 → 19.87 a walk a day),
  on her route +4% (16.31 → 16.90), route-adjacent +1%. Two causes, both of drawing during the walk:
  a row's cap now counts what the walk drew, so the capped rows are met at their caps (charging dog
  1 → 3 a day on days 4 to 8, abduction 1.02 → 3.12 on day 8); and the junction boxes no longer draw
  last, so the fitted ground weights send those capped rows to the junction boxes (chatting mother
  on a junction box 0.14 → 1.98 a walk a day, on a sidewalk 0.87 → 0.02). No table is refit here:
  whether the caps should count the walk's draws is the orchestrator's to decide first.
- **Frame cost**, three cities of sample `90210+31i`, 42 walks, main and then the branch, one at a
  time: the walk's draw takes a median tick of 1 µs, a p99 of 0.80 ms (the median over walks; the
  worst walk's 1.57 ms) and a worst tick of 17.6 ms, over 16 ms on 1 walk of 42. Main's siting on the
  same walks: median 2 µs, p99 0.41 ms (worst walk's 1.32 ms), worst tick 56.7 ms, over 16 ms on 36
  of 42 walks, so main already has ticks over 16 ms. In all, the draw costs 23.2 s over the walks
  against the siting's 6.8 s. Run at once with everything else, the four samples' figures are
  inflated alike: the draw's worst tick 58 to 88 ms, main's siting's 193 to 248 ms.
- **Forced draws**: 0.19% of the locations drawn on those walks (105 of 55,884), 0.31% to 0.44% on
  the four samples.

**For the end-of-refactor remeasure**, generated by the rule grassy-magpie states, from the logs of
the measurement above. Its output, verbatim:

    (a) Changed on purpose:
    - Every location the dawn leaves open is drawn as she walks near it (WalkDraw), nearest ahead first, out of her view; a row's cap (max_per_day) now counts what the walk drew, so a capped row is met up to its cap on the walk where main spent its cap over the whole city: charging_dog (3), chatting_mother (2), abduction (4), alley_mouse (4) and pigeon_flock (5) rise toward their caps.
    - The order the locations draw in is the walk's, not the lattice's: the junction boxes and the other ground beyond the streets drew last at dawn and draw when she comes near them now, so the rows the fitted ground weights (GROUND_WEIGHTS) send to junction boxes take their caps there first: chatting_mother, charging_dog and abduction move from the sidewalks to the junction boxes.
    - A sidewalk is drawn after its section, which the dawn's street order gave (DayLocations.drawn_before()).
    - A poster crew a location draws joins the walk unplaced for the director to site, as the dawn handed one over.
    - The run log's baseline (tests/fixtures/observed_run_log.txt) is re-recorded: only its plan line moves, which counts the walk's plans at its start, the dawn's and the locations drawn within reach of her start; every other line is unchanged.

    What the probe cannot see:
    - The poster crews: their ground is the buildings' blank fronts, which a city built without its scene does not have, so neither tree's probe walk sites one (WalkSiting waits with "no tile of its ground on the branch ahead of her").
    - RouteReachRule keeps a body that has left (spent) blocking until the day ends; the probe spends nothing, so it cannot see whether that refuses a draw main would have allowed.
    - The crowd learns a walk-drawn body when it is drawn, out of her view, rather than at dawn.
    - A dev spawn at a row with none placed has the walk draw every location first (EventManager.draw_everywhere()).
    - The probe walks the day's longest route out and home at heat 0, with no scars and no calm area used.

    (b) Outside 2σ pooled over all 64 walks per day (90210+31i (18), 70001+37i (18), 31337+43i (14), 24601+41i (14)), events met per walk per day, main → head:
    - friction by view: off the route all days, 11.67 → 12.22 (+5%, z +3.4); z per sample +1.5 / +1.5 / +2.7 / +1.1
    - friction by view: on her route all days, 11.55 → 12.02 (+4%, z +2.9); z per sample +2.4 / +1.7 / +1.4 / +0.2
    - friction by view and day: off the route day 11, 11.88 → 13.23 (+11%, z +2.2); z per sample +0.2 / +1.0 / +1.6 / +1.6
    - friction by view and day: route-adjacent day 14, 3.52 → 4.23 (+20%, z +2.1); z per sample +0.6 / +2.1 / -0.8 / +2.2
    - friction by view and day: route-adjacent day 10, 3.80 → 3.12 (-18%, z -2.0); z per sample -2.2 / -1.5 / -0.3 / +0.2
    - row by day: abduction day 8, 1.02 → 3.12 (+208%, z +8.3); z per sample +4.0 / +4.5 / +4.4 / +3.7
    - row by day: charging_dog day 4, 1.03 → 2.98 (+189%, z +7.8); z per sample +3.8 / +4.5 / +4.3 / +3.0
    - row by day: charging_dog day 8, 0.98 → 2.81 (+186%, z +7.5); z per sample +4.4 / +3.3 / +5.0 / +2.5
    - row by day: abduction day 11, 0.36 → 1.69 (+370%, z +7.4); z per sample +4.1 / +3.1 / +3.8 / +4.1
    - row by day: charging_dog day 7, 1.12 → 2.98 (+165%, z +7.3); z per sample +4.4 / +3.2 / +3.6 / +3.6
    - row by day: charging_dog day 6, 1.14 → 2.94 (+158%, z +7.1); z per sample +3.6 / +4.1 / +3.6 / +2.9
    - row by day: charging_dog day 5, 1.17 → 2.92 (+149%, z +6.9); z per sample +4.5 / +3.7 / +2.9 / +2.7
    - row by day: abduction day 14, 0.53 → 1.72 (+224%, z +6.3); z per sample +4.0 / +3.0 / +3.8 / +1.9
    - row by day: abduction day 13, 0.56 → 1.73 (+208%, z +6.2); z per sample +3.2 / +2.6 / +3.2 / +3.5
    - row by day: charging_dog day 10, 0.41 → 1.44 (+254%, z +6.1); z per sample +3.0 / +2.8 / +2.9 / +3.7
    - row by day: charging_dog day 12, 0.39 → 1.41 (+260%, z +6.1); z per sample +3.9 / +4.0 / +1.7 / +2.5
    - row by day: charging_dog day 11, 0.42 → 1.45 (+244%, z +6.0); z per sample +4.0 / +2.7 / +3.3 / +2.2
    - row by day: chatting_mother day 11, 0.81 → 2.00 (+146%, z +5.7); z per sample +3.1 / +3.3 / +2.9 / +2.0
    - row by day: chatting_mother day 14, 0.83 → 2.00 (+142%, z +5.6); z per sample +2.9 / +2.9 / +2.5 / +2.7
    - row by day: charging_dog day 14, 0.53 → 1.52 (+185%, z +5.5); z per sample +2.4 / +2.9 / +2.9 / +2.9
    - row by day: abduction day 12, 0.59 → 1.59 (+168%, z +5.4); z per sample +3.5 / +2.5 / +2.3 / +2.5
    - row by day: chatting_mother day 12, 0.88 → 2.00 (+129%, z +5.3); z per sample +3.3 / +2.9 / +2.0 / +2.3
    - row by day: chatting_mother day 7, 0.91 → 2.00 (+121%, z +5.1); z per sample +2.8 / +2.9 / +2.7 / +1.8
    - row by day: charging_dog day 13, 0.56 → 1.47 (+161%, z +5.1); z per sample +1.7 / +3.0 / +2.6 / +3.0
    - row by day: alley_mouse day 13, 1.73 → 3.11 (+79%, z +5.0); z per sample +2.0 / +2.3 / +3.5 / +2.4
    - row by day: charging_dog day 9, 0.62 → 1.52 (+142%, z +4.9); z per sample +2.2 / +3.5 / +3.0 / +1.0
    - row by day: abduction day 10, 0.72 → 1.66 (+130%, z +4.9); z per sample +2.2 / +2.8 / +1.8 / +2.9
    - row by day: chatting_mother day 9, 1.00 → 2.00 (+100%, z +4.6); z per sample +2.3 / +2.8 / +2.9 / +1.3
    - row by day: chatting_mother day 6, 1.02 → 2.00 (+97%, z +4.5); z per sample +1.7 / +2.4 / +2.7 / +2.3
    - row by day: chatting_mother day 5, 1.02 → 2.00 (+97%, z +4.5); z per sample +2.3 / +2.3 / +2.3 / +2.2
    - row by day: chatting_mother day 13, 1.02 → 2.00 (+97%, z +4.5); z per sample +1.8 / +2.8 / +2.0 / +2.5
    - row by day: chatting_mother day 10, 1.03 → 2.00 (+94%, z +4.5); z per sample +2.0 / +2.3 / +2.3 / +2.3
    - row by day: chatting_mother day 2, 1.03 → 2.00 (+94%, z +4.5); z per sample +2.6 / +2.0 / +1.6 / +2.7
    - row by day: chatting_mother day 1, 1.05 → 2.00 (+91%, z +4.4); z per sample +2.8 / +2.8 / +1.6 / +1.5
    - row by day: chatting_mother day 8, 1.14 → 2.00 (+75%, z +3.9); z per sample +2.0 / +2.0 / +2.3 / +1.5
    - row by day: chatting_mother day 4, 1.14 → 2.00 (+75%, z +3.9); z per sample +1.8 / +1.8 / +2.3 / +1.8
    - row by day: chatting_mother day 3, 1.16 → 2.00 (+73%, z +3.8); z per sample +2.0 / +1.8 / +2.0 / +1.8
    - row by day: abduction day 9, 0.84 → 1.58 (+87%, z +3.8); z per sample +1.4 / +2.5 / +1.9 / +1.8
    - row by day: pigeon_flock day 11, 1.95 → 2.89 (+48%, z +3.4); z per sample +1.4 / +1.4 / +2.0 / +2.1
    - row by day: alley_mouse day 14, 2.05 → 2.97 (+45%, z +3.3); z per sample +2.0 / +0.6 / +2.8 / +1.3
    - row by day: alley_mouse day 12, 1.88 → 2.67 (+42%, z +3.0); z per sample +1.9 / +1.7 / +0.7 / +1.6
    - row by day: roadblock day 11, 2.88 → 3.83 (+33%, z +2.9); z per sample +0.4 / +3.4 / +1.7 / +0.2
    - row by day: alley_mouse day 11, 1.77 → 2.52 (+42%, z +2.9); z per sample -0.3 / +2.0 / +2.9 / +1.6
    - row by day: pigeon_flock day 1, 2.14 → 2.91 (+36%, z +2.7); z per sample +0.5 / +2.2 / +1.9 / +0.9
    - row by day: protest day 14, 3.89 → 3.03 (-22%, z -2.6); z per sample -0.2 / -3.1 / -0.6 / -1.0
    - row by day: roadblock day 12, 3.14 → 3.97 (+26%, z +2.5); z per sample +2.8 / +1.4 / -0.5 / +1.2
    - row by day: reversing_lorry day 8, 1.00 → 1.48 (+48%, z +2.5); z per sample +2.0 / +2.1 / +0.0 / +0.5
    - row by day: roadblock day 14, 3.19 → 3.98 (+25%, z +2.4); z per sample +0.2 / +2.6 / +0.5 / +1.4
    - row by day: pigeon_flock day 2, 2.25 → 2.89 (+28%, z +2.3); z per sample +1.4 / +0.9 / +0.5 / +1.8
    - row by day: roadblock day 7, 3.80 → 4.61 (+21%, z +2.2); z per sample +1.4 / +1.2 / +1.4 / +0.5
    - row by day: pigeon_flock day 12, 2.08 → 2.69 (+29%, z +2.2); z per sample +1.6 / +1.9 / +0.6 / +0.2
    - row by day: homeless_yeller day 6, 4.66 → 3.84 (-17%, z -2.2); z per sample -1.9 / -0.7 / -1.7 / -0.3
    - row by day: leaf_blower day 2, 5.72 → 4.84 (-15%, z -2.2); z per sample +0.1 / -2.0 / -1.3 / -1.1
    - row by day: dog_walker day 12, 9.22 → 8.11 (-12%, z -2.1); z per sample +0.6 / -1.4 / -0.9 / -2.7
    - row by kind of ground: chatting_mother junction, 0.14 → 1.98 (+1368%, z +38.0); z per sample +19.8 / +20.6 / +17.3 / +18.2
    - row by kind of ground: charging_dog junction, 0.30 → 1.65 (+445%, z +28.8); z per sample +15.4 / +15.8 / +13.9 / +12.5
    - row by kind of ground: chatting_mother sidewalk, 0.87 → 0.02 (-98%, z -27.0); z per sample -14.3 / -14.5 / -11.7 / -13.3
    - row by kind of ground: abduction junction, 0.18 → 0.92 (+402%, z +21.0); z per sample +11.0 / +11.2 / +10.0 / +9.8
    - row by kind of ground: charging_dog sidewalk, 0.28 → 0.02 (-94%, z -14.5); z per sample -8.0 / -8.0 / -6.0 / -6.8
    - row by kind of ground: pigeon_flock junction, 0.89 → 1.40 (+58%, z +10.1); z per sample +5.7 / +4.7 / +5.6 / +4.3
    - row by kind of ground: abduction sidewalk, 0.15 → 0.02 (-89%, z -9.6); z per sample -4.7 / -5.6 / -4.4 / -4.5
    - row by kind of ground: alley_mouse alley, 1.89 → 2.35 (+25%, z +6.7); z per sample +3.2 / +2.9 / +4.9 / +2.6
    - row by kind of ground: roadblock carriageway, 2.51 → 2.88 (+15%, z +4.8); z per sample +2.3 / +3.9 / +1.2 / +2.1
    - row by kind of ground: ice_cream_van sidewalk, 1.53 → 1.73 (+13%, z +3.3); z per sample +2.0 / +0.8 / +3.5 / +0.4
    - row by kind of ground: homeless_yeller junction, 1.09 → 0.93 (-14%, z -3.3); z per sample -1.6 / -1.2 / -3.1 / -0.7
    - row by kind of ground: dog_walker sidewalk, 7.13 → 6.76 (-5%, z -3.0); z per sample -0.9 / -2.3 / -2.1 / -0.7
    - row by kind of ground: police_patrol junction, 1.69 → 1.88 (+11%, z +2.9); z per sample +1.2 / +0.9 / +2.7 / +1.0
    - row by kind of ground: homeless_yeller sidewalk, 3.06 → 2.83 (-7%, z -2.8); z per sample -1.8 / -0.7 / -1.6 / -1.5
    - row by kind of ground: police_patrol carriageway, 2.16 → 1.98 (-8%, z -2.6); z per sample -0.6 / -1.2 / -1.3 / -2.3
    - row by kind of ground: pigeon_flock sidewalk, 1.28 → 1.16 (-10%, z -2.4); z per sample -1.0 / -0.8 / -2.0 / -1.0
    - row by kind of ground: protest open, 0.05 → 0.03 (-43%, z -2.3); z per sample -1.1 / -1.6 / -0.6 / -1.1
    - row by view: charging_dog off the route, 0.50 → 1.47 (+191%, z +20.5); z per sample +10.8 / +10.9 / +11.1 / +8.3
    - row by view: abduction off the route, 0.30 → 0.93 (+206%, z +16.9); z per sample +9.0 / +8.7 / +8.2 / +7.9
    - row by view: chatting_mother off the route, 0.24 → 0.72 (+205%, z +14.8); z per sample +6.9 / +9.2 / +6.7 / +6.6
    - row by view: chatting_mother on her route, 0.61 → 1.18 (+93%, z +12.7); z per sample +7.1 / +6.2 / +6.5 / +5.7
    - row by view: charging_dog route-adjacent, 0.06 → 0.20 (+221%, z +8.1); z per sample +4.7 / +4.6 / +2.5 / +4.1
    - row by view: alley_mouse off the route, 1.80 → 2.21 (+23%, z +6.1); z per sample +2.9 / +2.6 / +4.4 / +2.5
    - row by view: pigeon_flock off the route, 1.07 → 1.38 (+29%, z +5.9); z per sample +4.2 / +3.1 / +2.5 / +1.9
    - row by view: roadblock on her route, 0.97 → 1.24 (+28%, z +5.5); z per sample +2.2 / +4.3 / +1.8 / +2.3
    - row by view: charging_dog on her route, 0.03 → 0.00 (-86%, z -4.4); z per sample -2.2 / -2.7 / -2.1 / -1.6
    - row by view: abduction route-adjacent, 0.03 → 0.00 (-91%, z -4.2); z per sample -2.6 / -2.5 / -1.0 / -2.0
    - row by view: homeless_yeller off the route, 1.23 → 1.05 (-14%, z -3.4); z per sample -2.4 / -0.4 / -2.6 / -1.6
    - row by view: alley_mouse route-adjacent, 0.09 → 0.14 (+57%, z +3.2); z per sample +1.5 / +1.5 / +2.7 / +0.6
    - row by view: chatting_mother route-adjacent, 0.16 → 0.10 (-35%, z -3.2); z per sample -1.3 / -2.1 / -1.2 / -2.0
    - row by view: ice_cream_van route-adjacent, 1.30 → 1.47 (+13%, z +3.0); z per sample +1.5 / +0.5 / +3.8 / +0.4
    - row by view: protest off the route, 0.76 → 0.67 (-12%, z -2.2); z per sample -0.7 / -2.2 / +0.4 / -1.9
    - row by view: homeless_yeller on her route, 2.31 → 2.17 (-6%, z -2.1); z per sample -0.8 / -1.1 / -1.2 / -1.1
    - row by view: dog_walker off the route, 2.76 → 2.60 (-6%, z -2.0); z per sample -0.8 / -0.5 / -1.3 / -1.6
    - the day's walked count: day 11, 41.42 → 47.47 (+15%, z +5.1); z per sample +1.8 / +2.6 / +4.1 / +2.0
    - the day's walked count: day 8, 63.08 → 68.98 (+9%, z +4.1); z per sample +1.8 / +2.7 / +2.5 / +1.2
    - the day's walked count: day 12, 45.00 → 50.00 (+11%, z +4.1); z per sample +3.6 / +2.0 / +1.5 / +1.1
    - the day's walked count: day 6, 59.84 → 65.14 (+9%, z +3.8); z per sample +1.7 / +2.7 / +1.8 / +1.3
    - the day's walked count: day 10, 42.34 → 46.16 (+9%, z +3.2); z per sample +2.1 / +1.6 / +1.5 / +1.2
    - the day's walked count: day 9, 40.42 → 43.61 (+8%, z +2.8); z per sample +1.7 / +1.4 / +2.3 / +0.1
    - the day's walked count: day 7, 64.19 → 67.45 (+5%, z +2.3); z per sample +1.6 / +1.1 / +0.6 / +1.2
    - the day's walked count: day 14, 49.47 → 52.30 (+6%, z +2.2); z per sample +1.4 / +1.2 / +0.6 / +1.2
    - the day's walked count: day 5, 53.62 → 56.34 (+5%, z +2.1); z per sample +1.1 / +1.2 / +1.9 / -0.2
    - view by day: off the route day 8, 19.92 → 25.17 (+26%, z +6.3); z per sample +3.8 / +3.4 / +3.1 / +2.1
    - view by day: off the route day 11, 16.91 → 20.91 (+24%, z +5.2); z per sample +2.7 / +2.6 / +2.5 / +2.6
    - view by day: off the route day 10, 17.70 → 21.47 (+21%, z +4.8); z per sample +2.2 / +3.0 / +2.4 / +2.0
    - view by day: off the route day 12, 20.41 → 24.09 (+18%, z +4.4); z per sample +4.0 / +2.1 / +1.4 / +1.5
    - view by day: off the route day 5, 15.17 → 17.84 (+18%, z +3.7); z per sample +2.3 / +1.9 / +1.6 / +1.6
    - view by day: off the route day 13, 23.03 → 25.91 (+12%, z +3.3); z per sample +0.7 / +1.5 / +3.3 / +1.2
    - view by day: off the route day 6, 17.95 → 20.33 (+13%, z +3.1); z per sample +1.7 / +1.9 / +2.0 / +0.5
    - view by day: off the route day 4, 15.31 → 17.28 (+13%, z +2.8); z per sample +3.1 / -0.7 / +3.4 / -0.4
    - view by day: off the route day 14, 22.72 → 25.09 (+10%, z +2.7); z per sample +1.4 / +1.1 / +1.4 / +1.6
    - view by day: off the route day 9, 17.55 → 19.61 (+12%, z +2.7); z per sample +2.2 / +1.6 / +1.9 / -0.5
    - view by day: off the route day 7, 17.67 → 19.73 (+12%, z +2.7); z per sample +1.1 / +2.3 / +1.1 / +0.8
    - view by day: on her route day 6, 20.55 → 22.41 (+9%, z +2.3); z per sample +1.2 / +1.4 / +0.9 / +1.0
    - view by day: off the route day 2, 13.19 → 14.66 (+11%, z +2.2); z per sample +0.0 / +1.0 / +2.4 / +1.1
    - walls by view: off the route all days, 4.62 → 6.27 (+36%, z +15.0); z per sample +8.5 / +8.2 / +8.0 / +5.0
    - walls by view and day: off the route day 8, 7.70 → 12.12 (+57%, z +7.9); z per sample +4.5 / +3.7 / +4.6 / +3.1
    - walls by view and day: off the route day 12, 4.00 → 6.25 (+56%, z +5.6); z per sample +4.9 / +2.4 / +1.5 / +2.6
    - walls by view and day: off the route day 10, 4.47 → 6.78 (+52%, z +5.5); z per sample +3.1 / +3.3 / +2.3 / +2.3
    - walls by view and day: off the route day 11, 4.08 → 6.20 (+52%, z +5.3); z per sample +4.0 / +2.6 / +2.5 / +1.4
    - walls by view and day: off the route day 14, 4.69 → 6.92 (+48%, z +5.2); z per sample +1.7 / +3.6 / +2.5 / +2.6
    - walls by view and day: off the route day 5, 4.22 → 6.06 (+44%, z +4.6); z per sample +3.2 / +2.7 / +2.3 / +0.9
    - walls by view and day: off the route day 13, 5.64 → 7.73 (+37%, z +4.6); z per sample +1.1 / +2.3 / +3.2 / +2.8
    - walls by view and day: off the route day 6, 4.97 → 6.80 (+37%, z +4.3); z per sample +1.3 / +2.4 / +3.5 / +1.5
    - walls by view and day: off the route day 4, 4.61 → 5.81 (+26%, z +3.0); z per sample +1.4 / +1.6 / +3.1 / +0.0
    - walls by view and day: off the route day 7, 5.11 → 6.36 (+24%, z +3.0); z per sample +2.1 / +1.7 / +1.2 / +0.9
    - walls by view and day: off the route day 9, 4.58 → 5.73 (+25%, z +2.9); z per sample +2.1 / +2.0 / +1.9 / -0.2
    - walls by view and day: on her route day 3, 4.08 → 4.89 (+20%, z +2.2); z per sample +1.2 / +2.3 / -0.8 / +1.4

    (c) Outside 2σ on at least two samples with the same sign:
    - friction by view and day: route-adjacent day 14, 3.52 → 4.23 (+20%, z +2.1); z per sample +0.6 / +2.1 / -0.8 / +2.2
    - row by day: charging_dog day 8, 0.98 → 2.81 (+186%, z +7.5); z per sample +4.4 / +3.3 / +5.0 / +2.5
    - row by day: charging_dog day 4, 1.03 → 2.98 (+189%, z +7.8); z per sample +3.8 / +4.5 / +4.3 / +3.0
    - row by day: abduction day 8, 1.02 → 3.12 (+208%, z +8.3); z per sample +4.0 / +4.5 / +4.4 / +3.7
    - row by day: charging_dog day 5, 1.17 → 2.92 (+149%, z +6.9); z per sample +4.5 / +3.7 / +2.9 / +2.7
    - row by day: charging_dog day 7, 1.12 → 2.98 (+165%, z +7.3); z per sample +4.4 / +3.2 / +3.6 / +3.6
    - row by day: abduction day 11, 0.36 → 1.69 (+370%, z +7.4); z per sample +4.1 / +3.1 / +3.8 / +4.1
    - row by day: charging_dog day 6, 1.14 → 2.94 (+158%, z +7.1); z per sample +3.6 / +4.1 / +3.6 / +2.9
    - row by day: charging_dog day 11, 0.42 → 1.45 (+244%, z +6.0); z per sample +4.0 / +2.7 / +3.3 / +2.2
    - row by day: charging_dog day 12, 0.39 → 1.41 (+260%, z +6.1); z per sample +3.9 / +4.0 / +1.7 / +2.5
    - row by day: abduction day 14, 0.53 → 1.72 (+224%, z +6.3); z per sample +4.0 / +3.0 / +3.8 / +1.9
    - row by day: charging_dog day 10, 0.41 → 1.44 (+254%, z +6.1); z per sample +3.0 / +2.8 / +2.9 / +3.7
    - row by day: charging_dog day 9, 0.62 → 1.52 (+142%, z +4.9); z per sample +2.2 / +3.5 / +3.0 / +1.0
    - row by day: abduction day 13, 0.56 → 1.73 (+208%, z +6.2); z per sample +3.2 / +2.6 / +3.2 / +3.5
    - row by day: abduction day 12, 0.59 → 1.59 (+168%, z +5.4); z per sample +3.5 / +2.5 / +2.3 / +2.5
    - row by day: alley_mouse day 13, 1.73 → 3.11 (+79%, z +5.0); z per sample +2.0 / +2.3 / +3.5 / +2.4
    - row by day: chatting_mother day 12, 0.88 → 2.00 (+129%, z +5.3); z per sample +3.3 / +2.9 / +2.0 / +2.3
    - row by day: chatting_mother day 11, 0.81 → 2.00 (+146%, z +5.7); z per sample +3.1 / +3.3 / +2.9 / +2.0
    - row by day: charging_dog day 13, 0.56 → 1.47 (+161%, z +5.1); z per sample +1.7 / +3.0 / +2.6 / +3.0
    - row by day: chatting_mother day 7, 0.91 → 2.00 (+121%, z +5.1); z per sample +2.8 / +2.9 / +2.7 / +1.8
    - row by day: chatting_mother day 14, 0.83 → 2.00 (+142%, z +5.6); z per sample +2.9 / +2.9 / +2.5 / +2.7
    - row by day: charging_dog day 14, 0.53 → 1.52 (+185%, z +5.5); z per sample +2.4 / +2.9 / +2.9 / +2.9
    - row by day: chatting_mother day 9, 1.00 → 2.00 (+100%, z +4.6); z per sample +2.3 / +2.8 / +2.9 / +1.3
    - row by day: alley_mouse day 11, 1.77 → 2.52 (+42%, z +2.9); z per sample -0.3 / +2.0 / +2.9 / +1.6
    - row by day: abduction day 10, 0.72 → 1.66 (+130%, z +4.9); z per sample +2.2 / +2.8 / +1.8 / +2.9
    - row by day: chatting_mother day 1, 1.05 → 2.00 (+91%, z +4.4); z per sample +2.8 / +2.8 / +1.6 / +1.5
    - row by day: chatting_mother day 13, 1.02 → 2.00 (+97%, z +4.5); z per sample +1.8 / +2.8 / +2.0 / +2.5
    - row by day: alley_mouse day 14, 2.05 → 2.97 (+45%, z +3.3); z per sample +2.0 / +0.6 / +2.8 / +1.3
    - row by day: chatting_mother day 2, 1.03 → 2.00 (+94%, z +4.5); z per sample +2.6 / +2.0 / +1.6 / +2.7
    - row by day: chatting_mother day 6, 1.02 → 2.00 (+97%, z +4.5); z per sample +1.7 / +2.4 / +2.7 / +2.3
    - row by day: chatting_mother day 10, 1.03 → 2.00 (+94%, z +4.5); z per sample +2.0 / +2.3 / +2.3 / +2.3
    - row by day: chatting_mother day 5, 1.02 → 2.00 (+97%, z +4.5); z per sample +2.3 / +2.3 / +2.3 / +2.2
    - row by day: pigeon_flock day 11, 1.95 → 2.89 (+48%, z +3.4); z per sample +1.4 / +1.4 / +2.0 / +2.1
    - row by kind of ground: chatting_mother junction, 0.14 → 1.98 (+1368%, z +38.0); z per sample +19.8 / +20.6 / +17.3 / +18.2
    - row by kind of ground: charging_dog junction, 0.30 → 1.65 (+445%, z +28.8); z per sample +15.4 / +15.8 / +13.9 / +12.5
    - row by kind of ground: chatting_mother sidewalk, 0.87 → 0.02 (-98%, z -27.0); z per sample -14.3 / -14.5 / -11.7 / -13.3
    - row by kind of ground: abduction junction, 0.18 → 0.92 (+402%, z +21.0); z per sample +11.0 / +11.2 / +10.0 / +9.8
    - row by kind of ground: charging_dog sidewalk, 0.28 → 0.02 (-94%, z -14.5); z per sample -8.0 / -8.0 / -6.0 / -6.8
    - row by kind of ground: pigeon_flock junction, 0.89 → 1.40 (+58%, z +10.1); z per sample +5.7 / +4.7 / +5.6 / +4.3
    - row by kind of ground: abduction sidewalk, 0.15 → 0.02 (-89%, z -9.6); z per sample -4.7 / -5.6 / -4.4 / -4.5
    - row by kind of ground: alley_mouse alley, 1.89 → 2.35 (+25%, z +6.7); z per sample +3.2 / +2.9 / +4.9 / +2.6
    - row by kind of ground: roadblock carriageway, 2.51 → 2.88 (+15%, z +4.8); z per sample +2.3 / +3.9 / +1.2 / +2.1
    - row by kind of ground: ice_cream_van sidewalk, 1.53 → 1.73 (+13%, z +3.3); z per sample +2.0 / +0.8 / +3.5 / +0.4
    - row by kind of ground: dog_walker sidewalk, 7.13 → 6.76 (-5%, z -3.0); z per sample -0.9 / -2.3 / -2.1 / -0.7
    - row by view: charging_dog off the route, 0.50 → 1.47 (+191%, z +20.5); z per sample +10.8 / +10.9 / +11.1 / +8.3
    - row by view: chatting_mother off the route, 0.24 → 0.72 (+205%, z +14.8); z per sample +6.9 / +9.2 / +6.7 / +6.6
    - row by view: abduction off the route, 0.30 → 0.93 (+206%, z +16.9); z per sample +9.0 / +8.7 / +8.2 / +7.9
    - row by view: chatting_mother on her route, 0.61 → 1.18 (+93%, z +12.7); z per sample +7.1 / +6.2 / +6.5 / +5.7
    - row by view: charging_dog route-adjacent, 0.06 → 0.20 (+221%, z +8.1); z per sample +4.7 / +4.6 / +2.5 / +4.1
    - row by view: alley_mouse off the route, 1.80 → 2.21 (+23%, z +6.1); z per sample +2.9 / +2.6 / +4.4 / +2.5
    - row by view: roadblock on her route, 0.97 → 1.24 (+28%, z +5.5); z per sample +2.2 / +4.3 / +1.8 / +2.3
    - row by view: pigeon_flock off the route, 1.07 → 1.38 (+29%, z +5.9); z per sample +4.2 / +3.1 / +2.5 / +1.9
    - row by view: charging_dog on her route, 0.03 → 0.00 (-86%, z -4.4); z per sample -2.2 / -2.7 / -2.1 / -1.6
    - row by view: abduction route-adjacent, 0.03 → 0.00 (-91%, z -4.2); z per sample -2.6 / -2.5 / -1.0 / -2.0
    - row by view: homeless_yeller off the route, 1.23 → 1.05 (-14%, z -3.4); z per sample -2.4 / -0.4 / -2.6 / -1.6
    - the day's walked count: day 11, 41.42 → 47.47 (+15%, z +5.1); z per sample +1.8 / +2.6 / +4.1 / +2.0
    - the day's walked count: day 12, 45.00 → 50.00 (+11%, z +4.1); z per sample +3.6 / +2.0 / +1.5 / +1.1
    - the day's walked count: day 8, 63.08 → 68.98 (+9%, z +4.1); z per sample +1.8 / +2.7 / +2.5 / +1.2
    - view by day: off the route day 12, 20.41 → 24.09 (+18%, z +4.4); z per sample +4.0 / +2.1 / +1.4 / +1.5
    - view by day: off the route day 8, 19.92 → 25.17 (+26%, z +6.3); z per sample +3.8 / +3.4 / +3.1 / +2.1
    - view by day: off the route day 4, 15.31 → 17.28 (+13%, z +2.8); z per sample +3.1 / -0.7 / +3.4 / -0.4
    - view by day: off the route day 10, 17.70 → 21.47 (+21%, z +4.8); z per sample +2.2 / +3.0 / +2.4 / +2.0
    - view by day: off the route day 11, 16.91 → 20.91 (+24%, z +5.2); z per sample +2.7 / +2.6 / +2.5 / +2.6
    - walls by view: off the route all days, 4.62 → 6.27 (+36%, z +15.0); z per sample +8.5 / +8.2 / +8.0 / +5.0
    - walls by view and day: off the route day 12, 4.00 → 6.25 (+56%, z +5.6); z per sample +4.9 / +2.4 / +1.5 / +2.6
    - walls by view and day: off the route day 8, 7.70 → 12.12 (+57%, z +7.9); z per sample +4.5 / +3.7 / +4.6 / +3.1
    - walls by view and day: off the route day 11, 4.08 → 6.20 (+52%, z +5.3); z per sample +4.0 / +2.6 / +2.5 / +1.4
    - walls by view and day: off the route day 14, 4.69 → 6.92 (+48%, z +5.2); z per sample +1.7 / +3.6 / +2.5 / +2.6
    - walls by view and day: off the route day 6, 4.97 → 6.80 (+37%, z +4.3); z per sample +1.3 / +2.4 / +3.5 / +1.5
    - walls by view and day: off the route day 10, 4.47 → 6.78 (+52%, z +5.5); z per sample +3.1 / +3.3 / +2.3 / +2.3
    - walls by view and day: off the route day 5, 4.22 → 6.06 (+44%, z +4.6); z per sample +3.2 / +2.7 / +2.3 / +0.9
    - walls by view and day: off the route day 13, 5.64 → 7.73 (+37%, z +4.6); z per sample +1.1 / +2.3 / +3.2 / +2.8

    Per day, events met on the walk and per view, main → head:
    - day 1: all 47.48 → 48.92 (+3%, z +1.2); on her route 17.70 → 18.25 (+3%, z +0.7); route-adjacent 19.44 → 19.17 (-1%, z -0.3); off the route 10.34 → 11.50 (+11%, z +2.0)
    - day 2: all 50.86 → 52.58 (+3%, z +1.4); on her route 15.98 → 16.17 (+1%, z +0.3); route-adjacent 21.69 → 21.75 (+0%, z +0.1); off the route 13.19 → 14.66 (+11%, z +2.2)
    - day 3: all 52.47 → 52.02 (-1%, z -0.4); on her route 15.66 → 16.69 (+7%, z +1.5); route-adjacent 21.61 → 20.69 (-4%, z -1.1); off the route 15.20 → 14.64 (-4%, z -0.8)
    - day 4: all 52.75 → 54.23 (+3%, z +1.1); on her route 18.03 → 18.50 (+3%, z +0.6); route-adjacent 19.41 → 18.45 (-5%, z -1.2); off the route 15.31 → 17.28 (+13%, z +2.8)
    - day 5: all 53.62 → 56.34 (+5%, z +2.1); on her route 19.17 → 19.47 (+2%, z +0.4); route-adjacent 19.28 → 19.03 (-1%, z -0.3); off the route 15.17 → 17.84 (+18%, z +3.7)
    - day 6: all 59.84 → 65.14 (+9%, z +3.8); on her route 20.55 → 22.41 (+9%, z +2.3); route-adjacent 21.34 → 22.41 (+5%, z +1.3); off the route 17.95 → 20.33 (+13%, z +3.1)
    - day 7: all 64.19 → 67.45 (+5%, z +2.3); on her route 24.42 → 24.95 (+2%, z +0.6); route-adjacent 22.09 → 22.77 (+3%, z +0.8); off the route 17.67 → 19.73 (+12%, z +2.7)
    - day 8: all 63.08 → 68.98 (+9%, z +4.1); on her route 23.52 → 23.50 (-0%, z -0.0); route-adjacent 19.64 → 20.31 (+3%, z +0.9); off the route 19.92 → 25.17 (+26%, z +6.3)
    - day 9: all 40.42 → 43.61 (+8%, z +2.8); on her route 11.58 → 12.41 (+7%, z +1.4); route-adjacent 11.30 → 11.59 (+3%, z +0.5); off the route 17.55 → 19.61 (+12%, z +2.7)
    - day 10: all 42.34 → 46.16 (+9%, z +3.2); on her route 12.30 → 13.14 (+7%, z +1.3); route-adjacent 12.34 → 11.55 (-6%, z -1.3); off the route 17.70 → 21.47 (+21%, z +4.8)
    - day 11: all 41.42 → 47.47 (+15%, z +5.1); on her route 12.22 → 13.38 (+9%, z +1.8); route-adjacent 12.30 → 13.19 (+7%, z +1.4); off the route 16.91 → 20.91 (+24%, z +5.2)
    - day 12: all 45.00 → 50.00 (+11%, z +4.1); on her route 12.14 → 13.06 (+8%, z +1.5); route-adjacent 12.45 → 12.84 (+3%, z +0.6); off the route 20.41 → 24.09 (+18%, z +4.4)
    - day 13: all 56.31 → 58.94 (+5%, z +2.0); on her route 11.25 → 10.55 (-6%, z -1.2); route-adjacent 22.03 → 22.48 (+2%, z +0.5); off the route 23.03 → 25.91 (+12%, z +3.3)
    - day 14: all 49.47 → 52.30 (+6%, z +2.2); on her route 13.77 → 14.08 (+2%, z +0.5); route-adjacent 12.98 → 13.12 (+1%, z +0.2); off the route 22.72 → 25.09 (+10%, z +2.7)

    Summary, pooled over all 64 walks per day:
    - walls by view, on her route: 3.97 → 4.02 (+1%, z +0.6)
    - walls by view, route-adjacent: 12.89 → 12.94 (+0%, z +0.2)
    - walls by view, off the route: 4.62 → 6.27 (+36%, z +15.0)
    - friction by view, on her route: 11.55 → 12.02 (+4%, z +2.9)
    - friction by view, route-adjacent: 4.39 → 4.44 (+1%, z +0.4)
    - friction by view, off the route: 11.67 → 12.22 (+5%, z +3.4)
    - every row, on her route: 16.31 → 16.90 (+4%, z +3.1)
    - every row, route-adjacent: 17.71 → 17.81 (+1%, z +0.5)
    - every row, off the route: 17.36 → 19.87 (+14%, z +12.3)

    Cells compared: 498. Outside 2σ pooled: 123. Outside on two samples or more, same sign: 72.
