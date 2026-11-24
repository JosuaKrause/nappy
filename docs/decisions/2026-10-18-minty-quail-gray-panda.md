# minty-quail — The director walks measured; a step is the tick's stretch (A2b W) · 2026-11-24

**The ask.** The event manager's design (A2b, W): the suites that walk her down a day's route
and read what the director put in front of her reached into `ahead` by hand
(`site_what_is_on_her_way`, `place_what_is_owed_ahead`, `stream_around`) and into the director's
private state (`is_from_her_route()`, `route_bag()`). W measures whether real physics ticks can
replace the hand steps, and adds a step only where they cannot.

## What was built

- `EventManager.step_what_is_ahead(delta)` is the tick's whole stretch from her camera's view to
  what is owed (the view, the day's units drawing, what her walk sites, the streaming, what is
  owed); `_tick_the_events()` calls exactly it, so a walk that steps it and the tick cannot
  drift. It is a kept line in `tools/test_only_members.txt`, as is `route_row()` (answer 9:
  `test_resistance_arrow.gd` reads the mast as her route's bag hands it out, which the game
  shows only by walking it; five more walks would multiply the suite's cost).
- Four suites keep the step: `test_route_bag.gd`, `test_day7_van.gd`, `test_day6_yeller_met.gd`
  and `test_resistance_arrow.gd` call `step_what_is_ahead()`, and read "is put on her route" off
  the run log through `tests/put_on_her_route.gd` and a `RecordingTrace` on the events'
  surroundings, in place of `is_from_her_route()` (`test_resistance_arrow.gd` asks
  `route_row()`).
- `test_pursuer_on_foot.gd` takes real ticks, each wait with its own tick: `STEP` (1/60 s) for
  the warning's run-down, the game's own 1/30 s for the sweep of retired instances, and 0.1 s
  (`WALK_TICK`) for the walk the day hands her. Ticks of `STEP` for the walk (7,200 where 0.1 s
  takes 1,200) took the suite 122 s locally against 40 s.
- The walk reads what the director put in front of her where the game writes it: the `ahead`
  lines the events tell the run log on each day, since the streaming also brings in the day's
  planned events on her way (246 instances against the director's 6 on one seed). The guard that
  the plain day hands her something counts those lines.
- The two rewraps left by #1700 (the escape-building case's docstring, the last line of the
  record minty-quail-freckled-toad).

## Measured

- Why four suites keep a step: real ticks over a day's longest route also met a district door's
  hold that put her down elsewhere (`test_route_bag.gd`, `test_resistance_arrow.gd`), a chatting
  mother on her way in (all four) and an extra row the director sent (the day 6 and 7 walks and
  `test_route_bag.gd`), none of which a case asks about, and cost 1.1 to 2.1 times as much. The
  builder's first runs, main / real ticks / step: test_route_bag 7.8 / 13.7 / 11.2 s,
  test_day7_van 12.2 / 26.1 / 17.0 s, test_day6_yeller_met 18.7 / 35.3 / 24.5 s,
  test_resistance_arrow 94 / 105 / 111 s. A later pair of runs, main / head: 8.8 / 10.9, 13.8 /
  15.9, 21.0 / 21.2 and 104 / 110 s. The real-tick logs were not kept. Times are local and
  information; CI's are the proof.
- `test_pursuer_on_foot.gd`: the run log of its walk is identical on real ticks and on main (the
  same six `ahead` lines on each day); 24.8 s on main and about 40 s on the head.
- Check counts, main and head, the same in every suite: 96 (route_bag), 37 (day7_van), 2
  (day6_yeller_met), 208 (pursuer_on_foot), 86 (resistance_arrow), 18 (walk_siting_spec).
- `tools/test.sh --repeat 3 --shuffle 7` on the six suites passes with no failure.

## Mutations shown failing, then reverted

- `route_row()` answering null: `test_resistance_arrow.gd` fails (the rigged mast has no place
  in five of the six cities).
- `EventsAhead` writing its line as "is put on her way" instead of "is put on her route": 10
  failures across the three route suites, 2 in `test_day6_yeller_met.gd` (the rigged man never
  laid), 7 in `test_day7_van.gd` (the rigged van never laid in all three cities) and 1 in
  `test_route_bag.gd` (day 11's loudspeaker). `PutOnHerRoute.says()` holds those checks.
- The step without `_look_through_the_camera()`: 8 checks fail in the suites named
  `test_event_manager`, `test_event_view` and `test_camera` (the fire sighted at the tap
  scheme's corner, the pursuer sighted as he rides in), none in the four walks. The day 6 and 7
  walks judge "out of her view" against a rectangle they build themselves
  (`Tuning.VIEW_HALF_EXTENT` led by the camera's look-ahead), not against the manager's view, so
  the line's place in the tick's order is held by the manager's suites.
- The pursuer walk not moving her, so the director's clock never turns: "the plain day hands her
  events to compare (0)" fails.

## Two adapted checks in `test_pursuer_on_foot.gd`

- "Created wholly out of her sight": the tick that makes the pursuer also takes his first step,
  so the check reads the position one stride back along his own travel (`travel_velocity()`
  times the tick's `STEP`), where he was made. For a pursuer on foot that velocity is his
  heading times his chase speed, straight at her over the clear run the same case asserts, so
  the stride back is exact; a pursuer made in view or too near is still read where he was made
  and fails.
- "Nothing joins the day's plan": real ticks let the day add plans over a second, so the torn
  day is compared with a plain day that waits the same ticks: equal plan counts. A plan the tear
  added makes the torn count higher and fails it.
