# minty-quail — The resistance's happenings and director are typed · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module. This pass is the resistance's
happenings and director (`src/resistance/`). Its search is none: it types and deletes lines and converts no read.

## What was built

- **Two files parse without their file-level opt-out line**: `src/resistance/happenings.gd` and
  `resistance_director.gd`, each `@warning_ignore_start("untyped_declaration")` before and none after.
- **Typing**: the two loops over literal lists of integers take `int` (`side` in `_plan_the_raid()`, `across` in
  `_door_can_be_touched()`), and `def` in `_place_the_roadblock_near()` is declared `EventDef`, which the field-read
  check needs written out since it cannot tell a ternary's type: its two `def.id` reads then land on the line
  `tools/field_reads.txt` already holds under `[EventDef]`, the list unchanged.
- **Left, no read converted**: every field the list below names, each for its own module's pass.

## Fields read and written, by class

`tools/field_answers.py` on the two files, as it prints them at a5a8daef1, each named method read in its class.

Fields of classes under `src/` that `src/resistance/happenings.gd`, `src/resistance/resistance_director.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `EventDef`: `id` read (`src/resistance/resistance_director.gd`:1752,1754,3080): no method; `inner_radius` read (`src/resistance/resistance_director.gd`:867,916,994,1303): `core_within()` (1 call); `paces` read (`src/resistance/resistance_director.gd`:3278): no method; `paces` written (`src/resistance/happenings.gd`:257): no method; `redetains` read (`src/resistance/resistance_director.gd`:1951): `detains_again()` (2 calls); `role` read (`src/resistance/resistance_director.gd`:2060,3288): no method; `shape` read (`src/resistance/happenings.gd`:255): `ground_shape()` (10 calls); `shape` written (`src/resistance/happenings.gd`:255): `solid()` does `shape = new_shape` (33 calls); `solid_parts` read (`src/resistance/happenings.gd`:256): no method; `solid_parts` written (`src/resistance/happenings.gd`:256): no method; `solid_when` read (`src/resistance/resistance_director.gd`:1948): `solid_from()` (2 calls); of it alone, `is_a_boom()` returns `solid_when == SolidWhen.WHILE_LOWERED` (3 calls); `speed` read (`src/resistance/resistance_director.gd`:2237): no method
- `EventInstance`: `def` read (`src/resistance/resistance_director.gd`:2315,2628,3275,3278): `row()` (2 calls); `def.id` read (`src/resistance/resistance_director.gd`:2628,3275): `row_id()` (11 calls); `is_finished` read (`src/resistance/resistance_director.gd`:2588,2628,2701,2802,2830,3240,3275): `is_gone()` (20 calls, +1 own); `is_parked` read (`src/resistance/resistance_director.gd`:2546): on its view, `EventInstance.Figure.has_parked()` (3 calls), a view no public method hands out; `path` read (`src/resistance/resistance_director.gd`:3278): `walks()` (1 call)
- `EventManager`: `points_at` written (`src/resistance/resistance_director.gd`:305): no method
- `EventPlan`: `def` read (`src/resistance/resistance_director.gd`:1948,1951,2060,3288): `row()` (27 calls); `facing` read (`src/resistance/resistance_director.gd`:1950,1962): no method; `mast_id` read (`src/resistance/resistance_director.gd`:2060,2104,3271,3288,3458,3461): no method; `position` read (`src/resistance/resistance_director.gd`:1946,1949,1956,1957,1961,1963,2063,2098,2105,2152,2154,3271,3291,3458,3461): `placed_at()` (28 calls); of it alone, `is_placed()` returns `position != Vector2.INF` (31 calls, +4 own); `silenced` read (`src/resistance/resistance_director.gd`:2060,3288): no method
- `GroundShape`: `half_length` read (`src/resistance/resistance_director.gd`:658): `spine_half_length()` (2 calls); `radius` read (`src/resistance/resistance_director.gd`:658): `rounding_radius()` (6 calls)
- `RegionPlanner.RegionPlan`: `alley_walls` read (`src/resistance/resistance_director.gd`:2352): no method; `door_bodies` read (`src/resistance/resistance_director.gd`:1945): no method; `doors` read (`src/resistance/resistance_director.gd`:1940): no method
- `ResistanceRunState`: `carrying_package` written (`src/resistance/resistance_director.gd`:367,3008): `reset()` does `carrying_package = false` (3 calls), `give_back()` does `carrying_package = _dawn_carrying_package` (1 call), `restore()` does `carrying_package = bool(data["…"])` (3 calls); `completed_steps` read (`src/resistance/resistance_director.gd`:370): no method; `failed_steps` read (`src/resistance/resistance_director.gd`:371): no method; `sabotage_done` written (`src/resistance/resistance_director.gd`:3055): `reset()` does `sabotage_done = false` (3 calls), `give_back()` does `sabotage_done = _dawn_sabotage_done` (1 call), `restore()` does `sabotage_done = bool(data["…"])` (3 calls)
- `ResistanceSteps.Step`: `applies_package_weight` read (`src/resistance/resistance_director.gd`:3007): no method; `at_a_front_door` read (`src/resistance/resistance_director.gd`:1189): no method; `deadline_fraction` read (`src/resistance/resistance_director.gd`:2576,2578,2580): no method; `grants_progress` read (`src/resistance/resistance_director.gd`:2991): no method; `index` read (`src/resistance/resistance_director.gd`:479,510,541,561,563,569,727,1987,2640,2865,2867,2976,2982,2983,3440): no method; `is_a_guarded_band` read (`src/resistance/resistance_director.gd`:495,503,545,598,609,1010,2570,3045): no method; `is_one_place` read (`src/resistance/resistance_director.gd`:2555): no method; `is_pickup` read (`src/resistance/resistance_director.gd`:489,520,534,602,605,607,1010,1512,2553,2861,2995,2997,3045,3148,3179): no method; `lingers_after_handover` read (`src/resistance/resistance_director.gd`:3022): no method; `needs_goal` read (`src/resistance/resistance_director.gd`:3052): no method; `placement` read (`src/resistance/resistance_director.gd`:1517): no method; `rigs_within` read (`src/resistance/resistance_director.gd`:3078,3082): no method; `target_kind` read (`src/resistance/resistance_director.gd`:467,483,501,548,594,636,1025,1188,1497,1504,1506,1508,1510,1981,2327,2546,2574,3028,3034,3039,3080,3182,3249,3267,3442): no method; `task_event_id` read (`src/resistance/resistance_director.gd`:471,472,480,538,541,697,1742,2628,3081,3275): no method; `trap_noun` read (`src/resistance/resistance_director.gd`:1065): no method; `trap_row` read (`src/resistance/resistance_director.gd`:1062): no method
- `RunFacts`: `completed_resistance_alley_tiles` read (`src/resistance/resistance_director.gd`:2441,2939): no method
- `RunState`: `attempt_spend` read (`src/resistance/happenings.gd`:295,357,399; `src/resistance/resistance_director.gd`:664): no method; `calendar` read (`src/resistance/happenings.gd`:154): no method; `facts` read (`src/resistance/resistance_director.gd`:2441,2939,2996): no method; `resistance` read (`src/resistance/resistance_director.gd`:367,370,371,3008,3055): no method
- `SpawnSiting.Start`: `across` read (`src/resistance/resistance_director.gd`:1093): no method; `at` read (`src/resistance/resistance_director.gd`:1157,1158,1159): no method; `beside` read (`src/resistance/resistance_director.gd`:1096): no method; `clear` read (`src/resistance/resistance_director.gd`:1095,1155): no method
- `WorldMap`: `day_record_version` read through `CityMap` (`src/resistance/resistance_director.gd`:2720,3320,3345,3416): no method; `obstruction_version` read through `CityMap` (`src/resistance/resistance_director.gd`:2719,3320,3345,3416): no method


## Verified

At parity: `tools/check.sh` boots clean; the field-read check against `origin/main` passes with `tools/field_reads.txt`
unchanged; the typing census and the layer check pass; the resistance's suites and every other that loads these two
classes pass; CI is green.
