# minty-quail — The night group's suites build no city where they test no city · 2026-11-07

minty-quail's `tests-one-module.md`, the night group, in #1225: each suite tests its one module
with everything else mocked, the city built only where a suite tests the city (inbox #1159 and
#1156 in gray-dolphin).

**Built.**
- **`test_blackout`** tests only Blackout's decision, over a never-built `City` holding a
  hand-drawn `CityMap` (seed 4242's station lot), a `TrafficSignals.new(null)`, the shared
  `FakeEventManager` (which gained a counting `silence_all_masts()`), three bare `Building`s and a
  node in the `player` group. Its other modules' cases moved to their own suites: the hall's
  clerestory to `test_power_station`, the lit and dark signal head to a new `test_traffic_light`,
  the dark junction's box rule to a new `test_traffic_signals`, the escape building's light by part
  to `test_interior`, and the spine's traffic with the lights out to a new `test_dark_spine`, which
  keeps a real `City` and crowd and says why. The "every mast stopped" check is `test_masts`', and
  the lit windows' toggle is `test_scenery_residency`'s.
- **`test_bollards`** needs no map: seed 1000's first row of posts is held as constants. It keeps
  her real body and the real posts, since only the physics engine answers what stands between
  them, and reads a post through `Prop.body_shape()`. The checks that asked `CityMap` moved to a new
  `test_precinct_posts`.
- **`test_power_station`** and **`test_heat`** take their maps from `tests/city_map_cache.gd`; the
  stacks case and the two day-planning cases keep what they test, each with its reason.
- **Measured** (user CPU before, wall after, on a heavily loaded machine): blackout 83.9 s to about
  8 s; bollards 20.1 s to 3.0 s; power_station 61.7 s to about 51 s; heat unchanged, since its
  planned days and event instances are what it tests.

**Choices where the design was silent, open to overturn:** the sabotage flag set directly in
`test_blackout`, since Blackout is stated over the flag; `TrafficSignals` kept real there as the
holder of one flag; three small new suites rather than cases folded into larger ones.

**Left:** the item's order says what the night group still waits for.
