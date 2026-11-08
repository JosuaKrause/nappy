# minty-quail — The atlas and scenery suites test their own module · 2026-11-07

minty-quail's `tests-one-module.md`, atlas and scenery, in #1226: each suite tests its one module
with everything else mocked, the city built only where a suite tests the city (inbox #1159 and
#1156 in gray-dolphin).

**Built.**
- **No suite named for something else builds a city.** `destination_drawing` hands a
  `ContactPoint` the step table's rows and builds nothing; `atlas_events` runs a real
  `EventManager` over `StreetMap.full()`, a walk started with `start_recipe([])`;
  `atlas_stroller_crowd` a real `Crowd` over a bare `WorldContext` and `StreetMap.full()`;
  `scenery_animation` one `SceneryWater` alone; `building_shadows` the cached map; `ground_floor`
  hand-built buildings, with `tests/ground_floor_checks.gd` sharing its reads.
- **The city's own checks moved to suites named for the city or the boot**, each with its reason:
  `test_city_atlas_holds`, `test_city_ground_water`, `test_city_buildings`, `test_atlas_boot`,
  `test_debug_hitboxes`, and `test_resistance_destination` for the resistance director's two
  destination checks (the task on offer after the pickup is read; the red arrow ending on the
  destination), which span the city, the day's events and the director.
- **`scenery_residency`** still observes a whole city, and its header says why.
- **Measured** (single process, shared load, rough): the group about 175 s to about 112 s;
  `destination_drawing` 44.7 s to 0.03 s, `atlas_loading` 41.5 s to 0.06 s, `ground_floor` 48.1 s
  to 5.7 s; the moved city and boot checks keep their cost in their new suites.

**Choices where the design was silent, open to overturn:** the moved city checks went into new
suites rather than existing city suites, which the running work owned.
