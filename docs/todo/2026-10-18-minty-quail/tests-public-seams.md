# Tests drive public seams and real frames

A test reaches the game through what the game itself offers and lets real frames pass; it does not
read a private member or call a frame function by hand. Two commands count the breaches. The first
counts a suite's lines that read a private member, including one named in a string:
`rg -c '^[^#]*(\.\_[a-z][a-zA-Z0-9_]*|\.(call|callv|set|get|call_deferred)\("_)' tests/*.gd`. The
second counts its lines that call a frame function or emit the frame signal by hand:
`rg -c '^[^#]*(\._(physics_)?process\(|\._(unhandled_)?input\(|process_frame\.emit)' tests/*.gd`.
Both skip comment lines, count every file under `tests/` (the rigs and helpers the suites share as
well as the suites), and neither sees access through a variable holding the name, so
`tests-unseen-reads.md` covers what they cannot see. The first takes a private member to start
with a lower-case letter after its underscore, so it misses a private constant:
`tests/test_touch.gd`'s reads of `TouchControls._FOCUS_KNOB_OFFSET` and `_FOCUS_KNOB_RADIUS`, in the
open list below, are not counted. Outside the two files below they print one breach still open: `tests/test_event_manager_fire.gd` and
`tests/test_fire_truck_body.gd` each call the private `EventSpawner._where_the_summoned_row_stops()`. A test or
helper that makes them print anything else is a breach.

- `tests/shared_state.gd` stays: its matches are the names in the runner's table of statics it
  leaves out of its comparison, read by name since the runner's job is to compare every static.
- `tests/test_prediction_reuse.gd` stays: it changes the event's heading, notice, spread axis and
  vehicle side and a crowd body's speed, axis, yield and door hold by writing them (some through a
  name held in a variable: `_speed`, `_direction`, `_turn_back_hold`, the `_jolt` fields),
  overrides `_sample_expected_landed`, and reads its reference fixture's `_event` and `_agent`,
  since no game path changes one input alone and that is what it proves the cache notices.

**Build:** where a test needs something of a class, that class gets public seams and
injected dependencies, and the test moves to them, with fakes handed in instead of statics patched;
since the test runner lets frames pass, scene-level tests step real frames. Planners get public
"place this at this site" entry points that the scheduler and recipes both call. A seam is one the
game itself uses: a member made public, or added, has a caller among the game's own classes, or is a
dependency the game's own code hands in (records minty-quail-44 and -47); a public member only a
test reads is not a seam, however it is named, and where the game has no reader the test goes
through what the game exposes (what is drawn, a signal, real input and frames). A step that touches
a test may convert it as it goes, "you can also do it as a bit with each step as long as the final
result is the same" (inbox #813 in curly-moose).

**Accepted, open to overturn.** A clock with a wall-clock default that only tests hand in
(`TouchControls.use_clock()`, as `ModeButton.use_clock()`, `TitleScreen.use_clock()` and
`ReturnWindow.use_clock()` are) is a seam: read strictly, the rule would rule all four out, and real
time with short waits would replace them.

**Drawn art.** The suites that read what the game draws with nothing in the game reading it back
(the roof art: scenery animation, roof entities, recipe roofs, residency, blackout, city decay; and
the event pictures: the catalogue's caps, the fire's flames) follow the player's answer to the
board question drawn-art-tests: "what are we testing here? the placement of the elements is defined
by the rng which can be tested in isolation. the drawing happens through general drawing code which
is also tested in isolation elsewhere. if you're just testing the holder for it the inject a mock
drawer that confirms that all elements are properly drawn" (inbox #1018 in brisk-ferret).

**Read as:** placement is tested on its own through the random draws, as a function of the seed;
the general drawing code is not retested; the holder (a building's roof, an event's picture) is
tested with an injected mock drawer that confirms every element is drawn. It is read as applying to
the roof art and the event picture suites, whose reads of what a look draws it answers with the
injected drawer.

**Where a suite drives a public step by hand.** Each is a different experiment from the one real
ticks give, and is kept with its reason:

- `test_pursuer_on_foot.gd` calls `EventManager.step_the_encounters()` and `check_hard_fails()`,
  the two steps the manager's own tick calls, since real manager ticks over its whole encounters run
  past four hundred seconds against about thirty (record minty-quail-snowy-panda).
- `test_checkpoints.gd` drives the street-door rig's public `watch_the_door_lines()`,
  `warn_at_the_doors()` and `hut.step()` on a city that never ticks, a standalone guard's `step()` in
  the pursuit simulations, and the gate rig's `city.crowd.step()`: a real tick passes the car at
  another time than the rig's own.
- A crowd car at speed 700, and a walker at pace 0 other than a waiting one, are not reachable
  through `Crowd.add_recipe_actor()`; a stopped car is reached through `crashed_into()`, which the
  game calls.

**Open: what a test still reads that the game does not, or does not check.**

- **The resistance director's fallback to the map's navigator is untested:** a director handed no
  city siting builds its spawn siting on it, and the one start it sites that way is a trap sent at
  her (`_send_at_her()`). The test it needs is a director handed a city whose spawn siting is unset,
  with that trap sited.
- **No test isolates the raid's wait for the patrol car's beat to be out of her view** in
  `ResistanceHappenings._maybe_raid()`: deleting that check fails nothing, since the vans' own check
  holds the raid back; the happenings' tests gain one that fails without it.
- **No test catches removing `DayDirector.prepare_city_scenery()` from `start_day()`** (the home's
  ground is already loaded; `test_camera_start.gd`'s dawn check does not fail without the call), or
  `DaySummary`'s `_continuing` guard.
- **`PlanBuilder._cross_street_path`** serves no catalogue row today, since the director sites the
  cat; it wants a row or removing.
- **A recycled walker's heading** when it chooses its lane again has no suite guarding it.
- **`EventsAhead.walk_siting()`** has no game caller (the route bag and resistance arrow suites and two probes read it); it goes with step 4 of polite-tapir's `placement-by-construction.md` (`tests-unseen-reads.md`). `test_route_bag.gd` reads a place waiting for its site in the director's private
  list, which nothing a game class asks reads. `test_day7_van.gd` reads the rigged bag through
  `EventsAhead.director().route_bag()`, an accessor no game class reads, and wants the manager or the
  resistance director to answer what is in front of her.
- **`WalkSiting.offers_worked_out`** is a public counter only `test_siting_judges_once.gd` reads,
  which wants the offer handed in.
- **`RouteLines.routes()`**, a public member no game class calls, is read by `test_route_lines.gd`'s
  picture sweep.
- **`test_touch.gd`** reads `TouchControls._FOCUS_KNOB_OFFSET` and `_FOCUS_KNOB_RADIUS` (the knob
  drawn inside its ring has no reader but the drawing), and **`HelpText.line`** is read only by tests
  (the HUD's teaching line, whose parsed text drops the icons).
- **The recording counter's override of `_send_event()`** in `test_visit_counter.gd` and
  `test_observers.gd`: the counter's gate reads the platform, which a headless run cannot fake.
- **The scene recipe suites leave untested:** the director's own use of the arrow ground (it wants a
  task scene of several targets on a stretch), free play past its whole duration (it wants a clock
  the scene is handed), the runtime suite's boundary probe writing the runtime's named world (it
  wants a scene recipe actor that needs no city), and the bounded scene's check that no event body
  stands outside the authored ground, which holds on today's recipes by construction (it wants a
  bounded recipe that names a gate).
