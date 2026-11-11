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
  excitement source's `rim`. Every field the suites read or write is listed by class under "Fields
  read and written, by class" below.
- **The plan record is typed under `EventScheduler.Planned`**; the placement track's scripted rename
  to `EventPlan` reruns over it.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `bdf1f92dc`, over the pass's files
(the `.gd` files under `tests/` its pull request changed, and any that "What was built" names as
already free of an opt-out line), and each method it names read in its class and the classes it
extends. Each read is listed with the public method that returns exactly that field, or "no method",
and with a yes-or-no method the tool prints beside it, a hint for a null test; each write with every
public method that assigns the field, and what it assigns.

- **`DangerEdge`**: `atlas`, written → no method.
- **`EventDef`**: `falloff_power` → no method; `notice` → no method (a yes-or-no on the field alone:
  `waits_for_her()`).
- **`EventInstance`**: `age` → no method (`EventInstance.Figure.age()` returns it on a view no
  public method hands out).
- **`EventManager`**: `atlas` → no method; `sources` → no method; `world` → no method.
- **`EventScheduler.Planned`**: `comes_in` → no method; `repeat_every` → no method.
- **`ExcitementSource`**: `rim` through `EventExcitement` → no method.
- **`InteriorMapPlan.Door`**: `id` → no method; `target_door` → no method; `tile` → no method.
- **`InteriorScene`**: `atlas` → no method; `atlas`, written → no method; `map` → no method.
- **`NoticeSpec`**: `runs_within` → no method.
- **`Stroller`**: `carrying`, written → no method.

## Verified

The interior suites pass, `tools/typing_census.py --check` holds, and the field-read check passes.
No check was deleted or moved.
