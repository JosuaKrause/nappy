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
  Suite time from CI's shard logs, main's run against the pull request's: `test_tutorial_dog`
  72.1 s to 0.4 s, `test_events_scheduler` 246.3 s to 403.7 s and 389.4 s on two slower runners
  (its shard mates 21% and 12% slower than on main's run); back to back locally, 282 s with the
  case planning its own days and 261 s once it reads the suite's own plans (seed 4242's are the
  suite's memoized ones; the other two seeds' 22 dawns are what the case adds).
- **The dark spine** (`tests/test_dark_spine.gd`) holds one case: the crowd's cars on the spine,
  lit and then dark, on day 14's city. What it plans is the city's closures for that day
  (`City.start_day()`); it starts no event, so no scheduler answer is in it, and the whole case is
  the crowd's with the lights'. It is now `_test_a_dark_spine_keeps_moving` in `tests/crowd_rig.gd`,
  the last case of the `streets` part (`tests/test_crowd_streets.gd`), which already stands a
  generated city of seed 4242 and runs the spine's other cases; the file and its `.uid` are
  deleted. The three checks and the two random streams (closures, traffic) are as they were: lit
  99 px/s with 23% stopped and dark 127 px/s with 7% stopped before and after. The case leaves the
  city on day 14, so it stays last. `test_crowd_streets` went from 19 to 22 checks and, in CI,
  from 56.6 s to 63.4 s (73.3 s at the last head), and `test_dark_spine`'s 3 checks and 17.7 s are
  gone with it.
- **Each moved check still fails.** With `TrafficSignals` holding every spine light red once the power
  is out, the dark spine measured 4 px/s with 93% stopped and two of the three checks failed. With
  `EventDef.spawn_mode_on()` ignoring the day switch, so the dog stays director-sited past day 3,
  the case failed on seed 4242's dogs from day 4 on (the first six failures read). Both changes were local
  and are not committed.
- References to `test_dark_spine.gd` in `tests/test_blackout.gd`, `tests/test_traffic_signals.gd`,
  `docs/ARCHITECTURE.md` and `docs/CITY.md` name `test_crowd_streets.gd`.
