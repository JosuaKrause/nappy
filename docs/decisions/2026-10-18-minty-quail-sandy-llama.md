# minty-quail — CityMap's tiles, stretch, stretch_active and recipe_bounds go private, and the scene recipes read the map through its methods (D2b) · 2026-11-23

minty-quail's scene recipes' pass (`.claude/briefs/designs/minty-quail-scene-recipes-pass.md`, D2b),
after D1 (the scene installs into the world it is handed). Four fields of `CityMap` were read from
outside by the scene recipes' runtime and draft and written by tests: `tiles`, `stretch`,
`stretch_active` and `recipe_bounds`.

**Built.**
- The four fields are `_tiles`, `_stretch`, `_stretch_active` and `_recipe_bounds`. The draft reads
  the dawn's tiles through the existing `tiles_snapshot()` (a copy of the grid, one byte a tile), the
  design's `tile_bytes()` not being added since `tiles_snapshot()` already answers it and the city
  generator already reads it. The runtime reads the recipe's window through the existing
  `recipe_window()`.
- `CityMap.drop_the_stretch()` is new: it empties the stretch and stops showing it. The draft lays the
  temporary stretch its starting crowd is placed again on with `begin_stretch()`,
  `add_stretch_tile(tile, map.tile_at(tile))` and `show_stretch()`, and lifts it with
  `drop_the_stretch()`; the bytes it writes are the ones already there.
- The runtime and the draft read `size_in_tiles()` in place of `WorldMap.size`, and their lines leave
  `tools/field_reads.txt` (the `[CityMap]` group's four lines and the two `size` lines).
- The tests read what the map answers: `is_void()` of a tile outside the stretch for `stretch_active`,
  `recipe_window()` and `show_recipe_window()` for `recipe_bounds`, `tiles_snapshot()` and
  `restore_tiles()` for `tiles` (`tests/test_reachability_grid.gd` fills a map through one helper).

**Noted.** `test_recipe_structures.gd`'s bounded setup writes the window through
`show_recipe_window()`, which also turns the recipe's exterior on; the suite's checks pass unchanged with it.
A scene draft of `task-07-package` is byte-identical before and after.
