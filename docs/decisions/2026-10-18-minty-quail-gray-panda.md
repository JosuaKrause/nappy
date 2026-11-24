# minty-quail — The director walks take real ticks, measured (A2b W) · 2026-11-24

**The ask.** The event manager's design (A2b, W): the suites that walk her down a day's route and read what the
director put in front of her reached into `ahead` by hand (`site_what_is_on_her_way`,
`place_what_is_owed_ahead`, `stream_around`) and into the director's private state
(`is_from_her_route()`, `route_bag()`). W measures whether real physics ticks can replace the hand steps, and
adds a step only where they cannot.

## What was built

- `EventManager.step_what_is_ahead(delta)` is the tick's whole stretch from her camera's view to what is owed
  (the view, the day's units drawing, what her walk sites, the streaming, what is owed); `_tick_the_events()`
  calls exactly it, so a walk that steps it and the tick cannot drift. It is a kept line in
  `tools/test_only_members.txt`, as is `route_row()` (answer 9: `test_resistance_arrow.gd` reads the mast as
  her route's bag hands it out, which the game shows only by walking it; five more walks would multiply the
  suite's cost).
- `test_route_bag.gd`, `test_day7_van.gd`, `test_day6_yeller_met.gd` and `test_resistance_arrow.gd` step it and
  read "is put on her route" off the run log through `tests/put_on_her_route.gd` and a `RecordingTrace` on the
  events' surroundings, in place of `is_from_her_route()`.
- `test_pursuer_on_foot.gd` takes real ticks (`PhysicsTicks.pass_ticks_faster` at `STEP` seconds a tick, the
  game's 30 ticks a second) for the warning's run-down, the walk the day hands her and the one tick that sweeps
  retired instances.
- The two rewraps left by #1700 (the escape-building case's docstring, the last line of the record
  minty-quail-freckled-toad).

## Measured

- Why four suites keep a step: real ticks over a day's longest route also ran a district door's hold (that put
  her down elsewhere), a chatting mother on her way in, and an extra row the director sent, none of which a
  case asks about, and cost 1.1 to 2.1 times as much (the first runs, main / real ticks / step:
  test_route_bag 7.8 / 13.7 / 11.2 s, test_day7_van 12.2 / 26.1 / 17.0 s, test_day6_yeller_met 18.7 / 35.3 /
  24.5 s, test_resistance_arrow 94 / 105 / 111 s). A later pair of runs, main / head: 8.8 / 10.9, 13.8 / 15.9,
  21.0 / 21.2 and 104 / 110 s. Times are local and information; CI's are the proof.
- `test_pursuer_on_foot.gd`: the run log of its walk is identical on real ticks and on main; 24.3 to 40.9 s
  on the first runs and 24.8 to 45.2 s on the later pair, the price of the real ticks.
- Check counts, main and head, the same in every suite: 96 (route_bag), 37 (day7_van), 2 (day6_yeller_met),
  208 (pursuer_on_foot), 86 (resistance_arrow), 18 (walk_siting_spec).
- `tools/test.sh --repeat 3 --shuffle 7` on the six suites: 1341 checks, 0 failures.
- Mutations shown failing: `route_row()` answering null fails `test_resistance_arrow.gd` (the rigged mast has no
  place in five of the six cities); the step without `_look_through_the_camera()` fails eight checks of the
  manager's suites (the fire sighted at the tap scheme's corner, the pursuer sighted as he rides in) and none of
  the four walks, whose cameras need no view set: the line is the tick's order, held by the manager's suites.

## Two adapted checks in `test_pursuer_on_foot.gd`

- "Created wholly out of her sight": the tick that makes the pursuer also takes his first step, so the check reads
  the position one stride back along his own travel (`travel_velocity()` times the tick's `STEP`), where he was
  made. It holds its claim: a pursuer made inside her view, or nearer than the least distance, is read there.
  Reading his place after the step would be a stride late.
- "Nothing joins the day's plan": real ticks let the day add plans over a second, so the torn day is compared
  with a plain day that waits the same ticks: equal plan counts. Anything the tear joined to the plan fails it;
  the earlier comparison with the dawn's count held only because nothing ticked.
