# minty-quail — The city's buildings, poster walls and streamed ground are typed · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module. This pass is the city's buildings,
poster walls and scenery (`src/city/`). Its search is `SceneryWater`, the animated water layer.

## What was built

- **Three of the four files parse without their file-level opt-out line**: `src/city/building.gd`
  (`untyped_declaration`, `unsafe_method_access`), `poster_walls.gd` (`unsafe_method_access`) and
  `scenery_ground.gd` (all three); none after. `src/city/scenery_residency.gd` keeps its line (below).
- **Typing**: the building's two roof-unit sorts take typed comparators, and its district's furniture kinds are read
  `as Array` before `duplicate()`; the poster walls read the poster kind's enum key through `String()` before
  lowering it, as `VisitCounter` does, the run log's text unchanged; the streamed ground's pending-layers lambda
  answers `TileMapLayer`, and its per-frame loop casts a child once `is SceneryWater` has matched; the residency's
  distance sort answers `bool`.
- **The ground sets its water's clock through `SceneryWater.set_clock()`**, which sets `elapsed` and, once the surface
  has its ripple material, the shader's `elapsed` parameter, the null check `SceneryWater._process()` already makes.
  The ground calls it every frame, where it wrote `child.elapsed` and `child._ripples` directly, and when it stands a
  surface up in `_prepare_whole()` and `prepare_step()`, where it wrote `water.elapsed` before the surface had its
  material (the builder's choice beyond the brief, which named the per-frame writes: before `configure()` only the
  clock is set, as before). A surface the ground stands up has its own `_process()` switched off
  (`water.set_process(false)`), so the ground's clock is the one it runs on; the water's phase each frame is what it
  was. `tools/field_reads.txt` loses its line `scenery_ground.gd elapsed` and gains none. Left reading
  `SceneryWater.elapsed`, no method being added for a test: `tests/test_scenery_animation.gd`, one line of
  `tests/test_scenery_residency.gd` and the probe `tests/probes/scenery_animation_runtime.gd`; the description lists
  every other hit of the old names, each another class's field.
- **The scenery residency keeps its line.** `SceneryResidency`, which stands scenery up near the view and frees it far
  away, registers objects that share no class below `Node2D`: a `Building` (a `StaticBody2D`), the city's home door
  (`City.HomeDoor`, a `Sprite2D`) and every `ScenerySprite`. Its `register()` and `update()` call
  `set_scenery_resident()` and `scenery_bounds()` and read `scenery_resident` on an untyped item; typed `Node2D`, the
  file would gain `unsafe_property_access`, and typed `Variant` or called by name, the read would hide from the
  check. Typing it needs an interface the three kinds share (typed callables the city hands `register()`, or a part
  each is composed of), with `scenery_resident` behind a method, a change to `src/city/city.gd`,
  `src/city/scenery_sprite.gd` and the home door outside this pass: its own design step.

## Fields read and written, by class

`tools/field_answers.py` on the four files, as it prints them at 68f322cc9, each named method read in its class.

Fields of classes under `src/` that `src/city/building.gd`, `src/city/poster_walls.gd`, `src/city/scenery_ground.gd`, `src/city/scenery_residency.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `Building`: `poster_art` written (`src/city/poster_walls.gd`:182): no method
- `CityMap`: `seed_used` read (`src/city/scenery_ground.gd`:101,138): `city_seed()` (14 calls)
- `FrameTiming`: `on` read (`src/city/scenery_residency.gd`:95): `is_on()` (5 calls)
- `PosterState`: `pasted_through` read (`src/city/poster_walls.gd`:213,215): no method; `pasted_through` written (`src/city/poster_walls.gd`:215): `reset()` does `pasted_through = 0` (3 calls, +1 own)
- `RunHeader`: `run_seed` read (`src/city/poster_walls.gd`:375,461,485): no method
- `RunState`: `calendar` read (`src/city/poster_walls.gd`:249): no method; `header` read (`src/city/poster_walls.gd`:375,461,485): no method; `posters` read (`src/city/poster_walls.gd`:162): no method
- `SceneryGround`: `chunks` read (`src/city/scenery_residency.gd`:109,119): no method; `elapsed` read (`src/city/building.gd`:762,763): no method; `mode` read (`src/city/scenery_residency.gd`:184,191): no method; `pending` read (`src/city/scenery_residency.gd`:114): no method
- `SceneryWater`: `atlas` written (`src/city/scenery_ground.gd`:104,141): no method


## Verified

At parity: `tools/check.sh` boots clean; the field-read check against `origin/main` passes with one listed line fewer;
the typing census and the layer check pass; the scenery's, the buildings' and the posters' suites pass, the water's and
the buildings' again on the final tree; CI is green.
