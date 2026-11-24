# minty-quail — The scene recipes' install suite on stand-ins · 2026-11-24

D4a of the scene-recipes pass (`tests-one-module.md`, entry 1): the suite that checks
`SceneRecipeRuntime.install()` runs on stand-ins and builds no city.

## What was built

- **Shared stand-ins** in `tests/`: `fake_city_dressing.gd`, `fake_crowd.gd`,
  `fake_stroller.gd`, `fake_baby.gd` (promoted from the director suite), `fake_poster_walls.gd`,
  and `scene_world.gd`, which assembles them into one world. `fake_event_manager.gd` records
  `start_recipe()`'s arguments, answers `plans()`, `event_of()`, `calm_as_the_map_stands()`,
  `start_recipe_route()` and `spawn_warned()`, and puts each plan in the world. Each answer was
  read off the real objects in the same situation first.
- **`tests/test_scene_recipe_install.gd`** (`git mv` of `test_recipe_structures.gd`) holds the
  install checks on `SceneWorld`: the fallen tree, the bounded extent, the door, the soft seal,
  the column, spec identity, the ground handed to the walk, the oversized uniform population and
  the mast cases.
- **`test_recipe_composition.gd` is deleted.** Its checks moved to the module each tests: the
  builder's to the new `tests/test_recipe_city_builder.gd`, the relocated-tree props to
  `test_recipe_city_drawing.gd`, the uniform walkers and the ordinary day to
  `test_crowd_coverage.gd`.
- `test_scene_recipe_task.gd` lost its mast install cases and its city preloads.

## Measured

Each moved or new check fails under a temporary break in `src/` and passes on restore (the
install suite: the seal tree pits, the refresh order, the non-empty guard, the extent test,
`stand_door`, `stand_whole`, the seal bodies, a fresh `DaySpec`, the `agent_count()` refusal, a
null ground; the mast cases: the day check, `is_closed`, `is_held_at`, the door-reach test; the
builder: the tree moves and the opposite-curb check; the drawing: the tree prop offset, and
`City.refresh_street_trees()` showing every tree; the crowd: the overlap refusal and the uniform
flag).

## Choices where the design was silent, open to overturn

- The home street's rule cannot be told from the install's own holds, so the ground check shows
  only that the home street is not offered; the rule alone is `test_walk_siting_spec.gd`'s.
- The crowd check that uniform walkers do not concentrate on the main road passed with the flag
  ignored under the old bound; the bound is now 1.25x of an even spread.
- `MastQueue` stays in `test_resistance_recipe_task.gd`: the stand-in does not answer
  `queue_a_mast()` or `mast_foot()`.
- Two `_mast_placement` conditions (the tile type, the home block) have no case, as before.

## Noted

- The runtime holds the home's streets for every spec, so the spec's home-street rule does
  nothing in a scene, and an escape scene's ground differs from the escape walk's own. Whether
  that is intended is open: it is the queue entry woolly-trout, a scene holding the home's
  streets for every spec.
- A torn poster on an escape section's city sends nobody: held by
  `tests/test_scene_recipe_boot.gd` (the `trailer-chase` boot), the escape building section's
  version by `test_walk_siting_spec.gd`.
