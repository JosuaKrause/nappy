# Tests drive public seams and real frames

A test reaches the game through what the game itself offers and lets real frames pass; it does not
read a private member or call a frame function by hand. Two commands count the breaches. The first
counts a suite's lines that read a private member, including one named in a string:
`rg -c '^[^#]*(\.\_[a-z][a-zA-Z0-9_]*|\.(call|callv|set|get|call_deferred)\("_)' tests -g '*.gd' -g '!tests/probes/**'`.
The second counts its lines that call a frame function or emit the frame signal by hand:
`rg -c '^[^#]*(\._(physics_)?process\(|\._(unhandled_)?input\(|process_frame\.emit)' tests -g '*.gd' -g '!tests/probes/**'`.
Both skip comment lines, count every file under `tests/` but the measurement probes (the rigs, the
fixtures and the helpers the suites share as well as the suites), and neither sees access through
a variable holding the name, so `tests-unseen-reads.md` covers what they cannot see. Outside the
two files below they print nothing, and a test or helper that makes them print anything is a
breach.

- `tests/shared_state.gd` stays: its matches are the names in the runner's table of statics it
  leaves out of its comparison, read by name since the runner's job is to compare every static.
- `tests/test_prediction_reuse.gd` stays: it writes the event's row and heading and a crowd body's
  axis (the body's `_direction`, `_turn_back_hold` and `_jolt` fields through a name held in a
  variable), reads the event's `_where` to hand it back, and overrides `_sample_expected_landed`;
  its pace, yield and door hold go through the calls the game's strategy makes. No game path
  changes one input alone, and that is what it proves the cache notices.

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
- `test_route_bag.gd`, `test_day7_van.gd`, `test_day6_yeller_met.gd` and `test_resistance_arrow.gd` call
  `EventManager.step_what_is_ahead()`, the tick's own stretch from her camera's view to what is owed,
  as they walk her down a day's longest route: real ticks there ran what the hand steps never ran and
  no case asks about (a district door's hold that put her down elsewhere, a chatting mother, an extra
  row the director sent) and took 1.1 to 2.1 times as long. `test_pursuer_on_foot.gd`'s walk, whose
  run log real ticks left as it was, takes real ticks.
- `test_checkpoints.gd` drives a standalone guard's `step()` in the pursuit simulations
  (`_guard_rig()`), and the gate rig's `RunCity.crowd(city).step()`: a real tick passes the car at
  another time than the rig's own. Its street-door rigs take real ticks.
- `test_resistance_crossing.gd` calls `EventManager.step_the_doors()`, the tick's three door steps,
  and `step_the_encounters()` before it where a hut's hold runs, since real ticks over a whole day 9
  with every event live ran 94.2 s in CI against 46.0 s recorded (record minty-quail-polite-quail).
- `tests/basement_walk_rig.gd` calls `EventManager.step_the_repeats()`, the tick's retire-and-repeat
  step, with each blow's own `step()`: real ticks over 400 walks took 1.87 times as long
  (about 45 s more, roughly 120 s across the probe's 1,100) and changed nothing a walk meets.
- A crowd car at speed 700, and a walker at pace 0 other than a waiting one, are not reachable
  through `Crowd.add_recipe_actor()`; a stopped car is reached through `crashed_into()`, which the
  game calls.

**Open: what a test still reads that the game does not, or does not check.**

- **`RouteLines.routes()`** is kept in `tools/test_only_members.txt` as the only handle on the drawn
  polylines, as `EventRouteLines.routes()` is.
- **The scene recipe suites leave untested:** the director's own use of the arrow ground (it wants a
  task scene of several targets on a stretch), free play past its whole duration (it wants a clock
  the scene is handed), the runtime suite's boundary probe writing the runtime's named world (it
  wants a scene recipe actor that needs no city), and the bounded scene's check that no event body
  stands outside the authored ground, which holds on today's recipes by construction (it wants a
  bounded recipe that names a gate).
