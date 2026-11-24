# minty-quail — The scene recipes' stretch suite to its modules · 2026-11-24

D4b of the scene-recipes pass (`tests-one-module.md`, entry 1): `tests/test_scene_recipe_stretch.gd`
is deleted, and each of its checks is held by the one suite of the module it is about. No file under
`src/` is edited.

## Where each check went

- **`tests/test_recipe_city_builder.gd`** (no city): the stretch is the only ground as
  `stretch.tiles` lists it, void elsewhere, the cut-off ground in the saved context, asked of the
  saved scene and of a hand-edited copy; the saved layout ignores the drafting inputs; a malformed
  context fails; a hand-edited tile survives the dawn's repaint; a resized lot and a planted tree are
  the author's; a tile listed twice is refused.
- **`tests/test_recipe_city_drawing.gd`** (a real `City`, for the guarantee between a map with a
  stretch and the city): the day's and the finale's preparation keep the manual ground; an edited
  rear wall raises the front roof; the partial courtyard's tint is its first visible piece's; the
  city draws only the recipe's buildings, walls the void and draws no ground there.
- **`tests/test_walk_field.gd`** (new): the red arrow's ground (`WalkField.ground_for()`) keeps to
  the stretch.
- **`tests/test_crowd_field.gd`**: the crowd enters at the stretch's ends and the field stays over
  the whole stretch while the camera moves.
- **`tests/test_event_director.gd`**: the rigged route is owed the count the scene gives and draws
  its pre-bag first.
- **`tests/test_masts.gd`**: every body of a day's street door stands on a point a mast keeps clear
  of (the one guarantee between `MastSites` and `RegionPlanner`, which runs real for it).
- **`tests/test_scene_recipe.gd`**: the schema's three stretch refusals.
- **`tests/test_scene_recipe_runtime.gd`**: the three runtime refusals of a stretch recipe, and
  `appeared` asking the camera's real view, on a world of stand-ins (`SceneWorld`) with her camera
  the engine's.
- **`tests/test_scene_recipe_draft.gd`** (new, on `SceneWorld` over the witness map): a draft takes
  whole streets and the junction at each end, a pinned mark its own corner only, a walked alley
  whole, and the drafted JSON reads back with the same ground.

The checks that read only the built map need no city, and the one suite that builds a real city for
a stretch is the drawing suite, whose header gives the reason.

## Measured

Each moved check fails under a temporary break in `src/` and passes on restore: `WalkField.ground_for()`
ignoring the map's void; `CrowdField` with no stretch ends, with a junction arm counted as an end, and
with the field following the camera; the director's owed count and pre-bag order; a door body 3 px off
its point; the three schema refusals each dropped; the two runtime refusals and the observation
refusal each dropped; `_she_can_see()` answering true; the draft skipping the junction boxes, then
the `walked` alley test; the builder listing every tile as sidewalk, not showing the void, taking
tile types from the context, regenerating the context from its seed, accepting a malformed tile run,
not listing a resized lot, not planting an authored tree and accepting a tile listed twice; the city
extending the roof a fixed two rows, letting a hidden courtyard piece choose the tint, building every
context building, not adding the void edge, ignoring the recipe's cracks and answering border ground
beyond the map's edge.

## Two checks were weaker than they read, and are now held

- **The dawn's repaint** (builder) and **the day's preparation** (drawing) kept a hand-edited *road*
  tile, which a repaint never touches: the check passed with the saved dawn ground gone. The edit now
  also turns one *alley* tile (block ground, which a repaint without the saved dawn ground paints back)
  into sidewalk, and both suites fail without `CityMap.keep_dawn_ground()`.
- **A marble the director does not site** was refused as unavailable on day 7, which hid the
  siting condition. A row available that day and placed on the map (`pigeon_flock`) is refused too,
  and fails when the siting condition is dropped.

## Two guards, two sets of tiles

- **No ground in the void** (drawing): the void inside the map is held by `GroundTiles.source_for()`
  answering no ground for a building tile, and the void beyond the map's edge by the city's own guard
  at the top of `scenery_ground_source()`, since off the map's rectangle the city answers the border
  band's ground. The check asks both, a tile inside the map and three outside it, and fails with the
  city's guard alone removed: the three tiles outside (-3,-3) and one past each far edge then answer
  border ground on day 7's stretch, where the guard answers no ground.

## Choices where the design was silent

- The masts check runs on the cached city of the scenes' context seed (`MapCache.of()`), the same map
  the recipe builder makes of it.
- The draft suite asks the draft only of its tiles: its stand-in dressing answers no buildings or
  props and its stand-in crowd nobody, since none of the three checks reads them.
- Day 7's recipe is the data every suite of the move reads, as the old suite read it; day 14's is the
  partial courtyard's.
