# minty-quail — The cities the rigs rebuild are cached, and main is handed a ready map · 2026-11-07


minty-quail's `city-cache.md`, in #1192: the fifth step of the board's test-isolation-plan ("yes",
inbox #1159 in gray-dolphin), with `main.use_city_maps()`, which waited for it (city-maps-later,
"yes", inbox #1173 in gray-dolphin). Behaviour is unchanged.

**Built.**
- **`CityMap.copy()`**, a deep copy: everything generation fixed, the last repaint's calm areas and
  playgrounds, an authored scene's saved context, and today's records. It does not carry the world
  it is drawn in, the navigator, the movers' moves, or the tiles-by-type cache, which refills on
  the first ask. `BlockPlan`, `BlockLayout` and `BlockedLayer` copy themselves, so the map reads no
  other object's fields. `tests/test_city_map.gd` holds it on seeds 4242, 1 and 77: the copy
  validates, answers the game's questions as the original does (as generated, after day 8's and
  day 14's repaints, mid-day), every declared member compares equal by reflection, and a write to
  either leaves the other unchanged.
- **`tests/city_map_cache.gd`:** `of(seed)` generates a seed's city once per test process and hands
  each caller its own copy; `source()` is the same as a `Callable` for a boot. The key is the seed
  alone, since the generator reads nothing else.
- **`main.use_city_maps(source)`**, a hand-in defaulting to `CityGenerator.generate`; an authored
  scene's map still wins. `tests/booted_main.gd`'s `boot()` takes `maps`.
- **The rigs moved onto it:** the finale, crowd-closures, event-manager and resistance rigs, 14
  suites, and `test_main`'s fixed-seed boots.
- **Measured:** the placement fingerprint is the same 15787 lines on main, on the branch, and on the
  branch with every city from the cache. Across the whole suite there were 1368 generations
  (about 840s); the moved suites went from 588 to 80, and their time from 1244s to 1083s on a
  shared machine, the resistance suites gaining most (`test_resistance_reach_narrow` 81s to 52s).

**Rejected.** A codec over the scene recipe's serializer (`RecipeCityContext`): it is not lossless,
and a copy through a stored form costs more than a field copy for every user of the cache.

**Open to overturn:**
- the suites not moved: the generator's and the city's own, which test what `generate()` builds;
  `routes_closures_rig.gd`, whose parts each generate 6 maps (its "uncached" is the rig's own plan
  cache, `_plan_uncached()` called twice on one map, not fresh maps); `test_events_scheduler`,
  whose determinism case already replans on one shared map and whose other cases generate seed
  4242 five more times; and `test_telemetry`. Moving those is left for scope;
- only fixed-seed boots take the cache;
- the copy carries the day's bodies with their owners;
- the copy test reads members by reflection, private ones included, since it is the one check that
  fails when a field is added and `copy()` does not carry it.
