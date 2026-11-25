# minty-quail — The crowd's suites build no city · 2026-11-07

minty-quail's `tests-one-module.md`, the crowd, in #1228: each suite tests its one module with
everything else mocked, the city built only where a suite tests the city (inbox #1159 and #1156 in
gray-dolphin).

**Built.**
- **The crowd suites build and plan no `City`.** `Crowd.setup()` is handed what a task scene's rig
  hands it: a bare `WorldContext`, a copy of a cached generated map (`tests/city_map_cache.gd`), the
  map's `TrafficSignals` and an empty `DayStreets`. `tests/crowd_street_rig.gd` gained
  `a_crowd(t, map)`, `free_crowd()` and `place_on(crowd, ...)`; `agent_on(city, ...)` forwards to
  `place_on` for the rigs that still hand a city.
- **`test_crowd_bodies`'s real-day sweep** moved unchanged to **`test_crowd_bodies_on_a_real_day`**,
  which keeps its real city and days by its stated reason: the guarantee spans the event plan, the
  city's day start and the crowd.
- `test_crowd_contributions`, `test_crowd_yields` and `test_danger`'s three crowd cases (a car on
  course, a walker brushing past, the arterial density) run on a bare crowd; `test_wall_shield`
  takes its map from the cache.
- **Measured** (local, load varying): `test_crowd_bodies` 130.9 s to 1.5 to 5.5 s, the new sweep
  suite 91 to 134 s; `test_danger` 59.8 s to about 40 s; `test_crowd_contributions` and
  `test_crowd_yields` about halved; `test_wall_shield` about the same. No check changed.

**Choices where the design was silent, open to overturn:** the crowd gets the map's real
`TrafficSignals`, a plain timing object, since with none the spine's junctions lose their lights
and the arterial density changes (a fake that answers for the lights is the stricter reading); the
crowd uses the map's own navigator, `setup()`'s default.

**Left:** the item's order says what the crowd suites still hold for other modules.
