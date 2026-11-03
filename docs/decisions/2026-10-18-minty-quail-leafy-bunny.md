# minty-quail — The crowd suites place agents through the crowd's own entry and ask its strike box (tests through public seams) · 2026-11-02

minty-quail's `tests-public-seams.md`: the crowd suites the stroller's pass did not reach, one PR's
worth. The item stays open for what they still read and for the pelican and police-car suites.

**Built.**
- `CarStrike.hits(centre, heading, speed, here)` (new `src/crowd/car_strike.gd`): the front-half
  strike box as a static function of a car's centre, heading and speed, called by `Crowd._strike()`
  every physics tick for each car near her, so the box can be asked without a car on the street.
- `WalkerStrategy.door_answer_for(roll)`: the cut of a roll into passes, turns back and held, called
  by `draw_the_door_answer()` for every walker placed; a suite finds the seed whose first roll gives
  the answer it wants instead of writing `_door_answer`.
- The suites place bodies through `Crowd.add_recipe_actor()`, the entry a task scene's pinned actors
  use, read them through `heading()`, `lane_key()` and the crowd's public queries, and let the
  crowd's own physics frames pass for the horn, the strike and the motion skip. Nothing private was
  renamed public; `src/` changes stay in `src/crowd/`.
- Private-read lines: car_front 8 to 0, crowd_contributions 21 to 0, crowd_bodies 28 to 3,
  crowd_yields 20 to 14, turns 47 to 19, crowd 44 to 35 (hand-called frames 3 to 0), crowd_closures
  68 to 34; pelican and police_car unchanged. Every check kept; six added.

**Not done, with the reason:** reads that want seams in the events and telemetry folders (the
pelican and police-car suites, the events' instances and streaming plans), held by other work at
the time; and the crowd's internal stepping (`_bump()`, `_recycle()`, the look-ahead, the door state
machine), which no game class calls from outside, so a public name would be a member only a test
reads (records -44 and -47). A crowd car at a standstill or at speed 700, and a walker at pace 0
other than a waiting one, are not reachable through the public entry.
