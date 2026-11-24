# minty-quail — The resistance director's recipe task gets a suite of its own (D4c) · 2026-11-24

minty-quail's scene recipes' pass (`.claude/briefs/designs/minty-quail-scene-recipes-pass.md`, D4c, §4.3's
director cases). `test_scene_recipe_task` built a whole `City` for cases that test the resistance
director alone.

**Built.**
- `tests/test_resistance_recipe_task.gd` holds the director's six recipe-task cases: a pinned mark
  stands unread and its task is placed when read; a mark is touched only from inside its alley; its
  guard keeps the mouth's distance; a mark off the tile in is refused, not moved; a neighbor start
  the day could not draw is refused; day 11 puts up a mast where none stands. It builds no `City`:
  the director stands on the recipe's map, a `DayStreets` begun from `RouteTree` and the recipe's
  closures, `FakeEventManager` and a bare `WorldContext`.
- `test_scene_recipe_task` keeps the mast install cases and its `City`; its day builds no director.
- The cases read `ContactPoint.task_step()` and `is_finished()`, so `ContactPoint.step`'s line
  leaves `tools/test_only_members.txt`.

**Noted.** `FakeEventManager` answers none of `queue_a_mast()`, `plans()` or `mast_foot()`, which
D4a adds; until then the suite carries a subclass, `MastQueue`, that lays the mast on the first tile
the director offers, so the day-11 check holds the tiles the director offers. The counts across the
two suites are main's.
