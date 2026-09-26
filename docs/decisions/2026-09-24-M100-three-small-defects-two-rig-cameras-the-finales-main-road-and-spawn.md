## M100 — Three small defects: two rig cameras, the finale's main road, and `--spawn` · built 2026-09-24

- **Two rigs no longer trigger the physics-mode camera warning.** `_chat_stroller` in
  `tests/test_events.gd` and `_build_pickup` in `tests/test_resistance.gd` set their `Camera2D`'s
  `process_callback` to physics, as `stroller.tscn`'s camera and the balance rig do.
- **The finale planner asks `CityMap.is_main_road()`.** `FinalePlanner.service_exit_tile()`
  compared `map.main_road == lot.position.x` by hand; both are block-column indices, so the
  answer was already right and the change routes it through the one place the question is
  stated.
- **`--spawn event:<id>` refuses a row the day's plan never places, by name**, in the run log (a
  new `spawn` entry) and on stderr, then falls back to the doorstep as an unknown target does:
  `cat_dash`, `cyclist`, `loose_dog`, day 3's `charging_dog` and `burning_building` are sited
  from her walk. **For a row that waits** (`pursues_within` above zero), it stands her outside
  the trigger, at the larger of its outer radius and `pursues_within` plus a tile, where the
  ordinary offset put her inside a flock's 150px trigger. **Open to overturn, chosen by the
  agent:** a refusal is an error line, not a quit, since the fence left out `main.gd`; the margin
  is one tile.
