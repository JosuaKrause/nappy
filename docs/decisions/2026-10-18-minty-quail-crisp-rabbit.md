# minty-quail — The city layer's unreached members are deleted · 2026-11-07

minty-quail's `dead-code-sweep.md`, `src/city/`, in #1230, a commit per class; each member
re-checked unreached across `src/`, `tests/`, `tools/`, `scenes/` and `project.godot`, comments
aside.

**Deleted.**
- **`MarbleBag.take`, `has_marbles` and `is_shared`**: nothing called the first two since the bag
  came in (#565), nor the third (#715); the bag's own code reads its private `_is_shared`.
- **`CityMap.walkable_by_type`** (#588, a duplicate of `walkable_lut`, which `WalkField` reads) and
  **`CityMap.purpose_tiles`** (uncalled since M15); one doc comment now names `walkable_lut`.
- **`StreetTrees.has_trees`** (uncalled since M106; `ClosurePlanner`, `SealPlanner` and the scene
  recipe runtime read `segment_keys_with_trees`) and **`STREET_TREE_MAX_LINED_FRACTION`**, which no
  code read; the rarity test in `tests/test_blocks.gd` that used it stays and holds 0.25 itself, and
  `street_trees.gd`'s comments and `docs/CITY.md` say what holds.

**Choice where the design was silent, open to overturn:** the rarity test keeps its bound as a
local rather than going with the constant.
