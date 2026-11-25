# minty-quail — The building and the finale's planner are typed · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module. This pass is the building
(`src/interior/`) and the finale's planner. Its search is none: it types and deletes lines and converts no read.

## What was built

- **Five files parse without their file-level opt-out line**, each `@warning_ignore_start("untyped_declaration")`
  before and none after: `src/interior/interior_map_plan.gd`, `interior_map.gd`, `interior_scene.gd`,
  `interior_tileset.gd` and `src/finale/finale_planner.gd`. Nothing else in them changes and no other file changes.
- **Typing**: eight `for` variables over an array literal or an untyped dictionary take their element's type: the four
  steps in the finale planner's `_flood_calm()`, which grows a calm area tile by tile, as `Vector2i`; the basement's
  jog rows and the plan's neighbour offsets in `flight_bands()` as `int`; the hallway waypoints where chandeliers hang
  and the stairwell sides whose backdrop is drawn as `String`; and the tileset's loop over its ground sources as
  `InteriorTile.Kind`, the enum `_SOURCES` is keyed by, the same integer at run time.
- **Left, no read converted**: the fields of `InteriorMapPlan.Door`, the plan's small record of a door (`id`, `tile`,
  `target_door`), which `InteriorMap._add_door()` writes, reached through the public `InteriorMap.build()`, and the
  scene reads to place thresholds and run a door's transition; the check does not count a field only an inner class
  declares, so `tools/field_reads.txt` has no line for them. And `WorldMap.world` written by the scene
  (`map.world = self`), its line in `tools/field_reads.txt` standing, for the map interface's world half.

## Fields read and written, by class

`tools/field_answers.py` on the five files, as it prints them at 3490772cf, each named method read in its class.

Fields of classes under `src/` that `src/interior/interior_map_plan.gd`, `src/interior/interior_map.gd`, `src/interior/interior_scene.gd`, `src/interior/interior_tileset.gd`, `src/finale/finale_planner.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `InteriorMapPlan.Door`: `id` read (`src/interior/interior_scene.gd`:462): no method; `id` written (`src/interior/interior_map.gd`:371): no method; `target_door` read (`src/interior/interior_scene.gd`:622): no method; `target_door` written (`src/interior/interior_map.gd`:373): no method; `tile` read (`src/interior/interior_scene.gd`:463,465,693,696): no method; `tile` written (`src/interior/interior_map.gd`:372): no method
- `WorldMap`: `world` written through `InteriorMapPlan` (`src/interior/interior_scene.gd`:205): no method


## Verified

At parity: `tools/check.sh` passes (without the typing, the boot failed on the warnings made errors); the field-read
check against `origin/main` sees no new read; the typing census passes; the building's, the finale's and the boot's
suites pass; CI is green.
