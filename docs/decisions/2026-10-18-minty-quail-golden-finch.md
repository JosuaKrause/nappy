# minty-quail — The tutorial dog's and the night group's day-planning cases move to the scheduler's and the crowd's suites · 2026-11-23

The two cases `docs/todo/2026-10-18-minty-quail/tests-one-module.md` listed for the player and the baby
(entry 1) and the night group (entry 3) are in the suite of the module whose answer each asks, and
both entries are deleted from the list, the rest renumbered.

- **The tutorial dog's placement past the teaching day** (`_test_day_4_is_a_map_placement` in
  `tests/test_tutorial_dog.gd`) asks where `EventScheduler` places `charging_dog` on days 4 to 14 of
  three generated cities, which is the scheduler's answer and not the director's. It is now
  `_test_the_dog_past_the_teaching_day_is_a_map_placement` in `tests/test_events_scheduler.gd`, with
  the same seeds, days and check texts; it takes the mast sites from the suite's `_sites_of()`, which
  is the call it made before. `test_tutorial_dog` had no other generated city, so it drops the map
  cache and builds none: 268 checks became 173, 95 of them moved; the scheduler's 9474 became 9569.
  Suite time, one local run each, before and after: `test_tutorial_dog` 62.9 s to 1.8 s,
  `test_events_scheduler` 224 s to 284 s (the three cities' days planned there).
- **The dark spine** (`tests/test_dark_spine.gd`) holds one case: the crowd's cars on the spine,
  lit and then dark, on day 14's city. What it plans is the city's closures for that day
  (`City.start_day()`); it starts no event, so no scheduler answer is in it, and the whole case is
  the crowd's with the lights'. It is now `_test_a_dark_spine_keeps_moving` in `tests/crowd_rig.gd`,
  the last case of the `streets` part (`tests/test_crowd_streets.gd`), which already stands a
  generated city of seed 4242 and runs the spine's other cases; the file and its `.uid` are
  deleted. The three checks and the two random streams (closures, traffic) are as they were: lit
  99 px/s with 23% stopped and dark 127 px/s with 7% stopped before and after. The case leaves the
  city on day 14, so it stays last. `test_crowd_streets` went from 19 to 22 checks and from 33 s
  to 51 s, and `test_dark_spine`'s 3 checks and 19 s are gone with it.
- **Each moved check still fails.** With `TrafficSignals` holding every spine light red once the power
  is out, the dark spine measured 4 px/s with 93% stopped and two of the three checks failed. With
  `EventDef.spawn_mode_on()` ignoring the day switch, so the dog stays director-sited past day 3,
  the case failed on seed 4242's dogs from day 4 on (the first six failures read). Both changes were local
  and are not committed.
- References to `test_dark_spine.gd` in `tests/test_blackout.gd`, `tests/test_traffic_signals.gd`,
  `docs/ARCHITECTURE.md` and `docs/CITY.md` name `test_crowd_streets.gd`.
