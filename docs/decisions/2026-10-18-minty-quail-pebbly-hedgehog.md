# minty-quail — The building's interior suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The building's interior suites and their rig are typed and lose their opt-out line**:
  `test_interior`, `test_interior_masked_man` and the rig `masked_man_meeting.gd`, which keeps every
  function's name, argument order and answer (`test_interior_masked_man_badge`, which also loads it,
  passes). Loop variables over literals and enum values are typed, a loop over `get_children()` is
  typed `Node2D`, and a dictionary of components is `Dictionary[String, Dictionary]`. No line under
  `src/` changed.

## Left, each with its reason

The search covered `InteriorScene`, `InteriorMap`, `InteriorMapPlan` and `InteriorTile`.

- **`InteriorScene.map` and `InteriorScene.atlas`, read**: no method answers either; `main.gd`, the
  game's one caller, reads `map` and writes `atlas` as fields, and both are listed in
  `tools/field_reads.txt`. Their conversion belongs to the building's pass under `src/interior/`.
- **`InteriorMap`, `InteriorMapPlan` and `InteriorTile`**: the suites read no public field of them.
- **The plan record is typed under `EventScheduler.Planned`**; the placement track's scripted rename
  to `EventPlan` reruns over it.

## Verified

The interior suites pass, `tools/typing_census.py --check` holds, and the field-read check passes.
No check was deleted or moved.
