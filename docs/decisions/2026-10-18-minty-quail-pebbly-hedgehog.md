# minty-quail — The building's interior suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The building's interior suites and their rig are typed and lose their opt-out line**:
  `test_interior`, `test_interior_masked_man` and the rig `masked_man_meeting.gd`, which keeps every
  function's name, argument order and answer (`test_interior_masked_man_badge`, which also loads it,
  passes). Loop variables over literals and enum values are typed (`InteriorTile.Kind` among them),
  a loop over `get_children()` is typed `Node2D`, a loop over a floor's `floor_tiles()` takes its
  element's type, and a dictionary of components is `Dictionary[String, Dictionary]`. No line under `src/` changed.
- **Reads converted to the methods the game calls**: the scene's start position through
  `InteriorScene.start_world_position()` rather than through its map; and, of other modules, the
  live event's `row()`, `row_id()`, `walks()`, `is_gone()`, `is_on_its_way_out()`, `source()`; the
  row's `obstructs_within()`, `core_within()`, `heard_within()`, `telegraphs_for()` and `peak()`; the
  plan record's `placed_at()`, `is_in_the_world()` and `come_again_every()` (a write); and her
  `steering_direction()`.

## Left, each with its reason

The search covered `InteriorScene`, `InteriorMap`, `InteriorMapPlan` and `InteriorTile`.

- **`InteriorScene.map` and `InteriorScene.atlas`**: no method answers either; `main.gd`, the
  game's one caller, reads `map` and writes `atlas` as fields, and both are listed in
  `tools/field_reads.txt`. Their conversion belongs to the building's pass under `src/interior/`.
- **A door's `id`, `tile` and `target_door`** (`InteriorMapPlan.Door`): the plan answers a door by
  id, the list of ids and the transition at a tile, and no method gives a door's tile or its
  counterpart; the interior scene reads the same fields.
- **`InteriorMap` and `InteriorTile`**: the suites read no public field of them.
- **Other modules' fields no method answers stay for their passes**, each checked against its
  class and its base class: the live event's `age`; the row's `falloff_power` and `notice`; a
  notice's `runs_within` (`runs_its_own_line()` answers only whether it is set); the plan record's
  `repeat_every` and `comes_in`, read (`repeats()` is a bool); the event manager's `sources`,
  `world` and `atlas`; her `carrying`, written; the danger edge's `atlas`, written; and an
  excitement source's `rim`.
- **The plan record is typed under `EventScheduler.Planned`**; the placement track's scripted rename
  to `EventPlan` reruns over it.

## Verified

The interior suites pass, `tools/typing_census.py --check` holds, and the field-read check passes.
No check was deleted or moved.
