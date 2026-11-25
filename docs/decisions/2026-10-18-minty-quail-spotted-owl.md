# minty-quail — The scene recipe's own suite builds no city · 2026-11-07

minty-quail's `tests-one-module.md`, the scene recipes, in #1224: each suite tests its one module
with everything else mocked (inbox #1159 in gray-dolphin), the city built only where a suite tests
the city (inbox #1156 in gray-dolphin).

**Built.**
- **`tests/test_scene_recipe.gd` builds no `City`.** Its two city blocks (the bounded context's
  exterior ground and hall roof extension; the hall and yard examples' facade columns and fallback
  ground streaming) moved unchanged to **`tests/test_recipe_city_drawing.gd`**, combined by its
  stated reason: a built map must be one the city can draw, which no single suite can hold. The
  pair holds the same 52 checks.
- **Header reasons** in `test_recipe_composition`, `test_recipe_crowd`, `test_recipe_structures`,
  `test_scene_recipe_task`, `test_scene_recipe_stretch`, `test_scene_recipe_activity` and
  `test_scene_recipe_stretch_crowd` say why each builds a city or boots `main`;
  `test_scene_recipe_boot` and the lifecycle rig already did. `test_recipe_roofs` and
  `test_scene_recipe_runtime` build none.
- **Measured** (local, heavily loaded, noisy): `test_scene_recipe` 20242 ms before, 14693 ms after;
  the new suite 2842 to 6069 ms. The city build moved rather than disappeared.

**Left:** the suites `SceneRecipeRuntime.install()` reaches, which takes the whole `City`; the
item's order says what they wait for.
