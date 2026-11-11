# minty-quail — The player's and the baby's suites are typed and read the baby through methods · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin).
This is the player's and the baby's pass of `typed-everywhere.md`'s "What is untyped in a test goes
as its suite is converted", after the baby and the stroller were handed their parts
(minty-quail-fluffy-yak) and the runner was typed in every suite (minty-quail-downy-kestrel).

## What was built

- **`test_meters`, `test_camera_start`, `test_move_poses`, `test_player_presentation`,
  `test_tutorial_dog`, `test_stroller` and `test_stroller_gait` are typed and lose their opt-out
  line**; `test_baby_world` and `test_loose_dog_arrives` had none. No line under `src/` changed.
- **`test_meters` and `test_baby_world` read the baby through `sleepiness_level()`,
  `excitement_level()`, `condition()` and `last_frame_incoming()`**, which the game calls.
- **`test_player_presentation`, `test_stroller` and `test_stroller_gait` hand the stroller its
  atlas** through `Stroller.use_atlas()` and read the picture off the library they handed, where
  they read `Stroller.atlas`. **An asleep baby is set up by `Baby.force_sleep()`**, which the day
  director calls, and **`test_tutorial_dog` works its mast sites out once per city**.
- **`test_camera_start` types `main` by a preload of `res://src/main.gd`**, as `test_atlas_boot`
  does, since the file has no class name.

## Left, each with its reason

- **Some setup writes stay because the game writes the same field the same way**: `sleepiness` and
  `excitement`, which the game's own developer code sets by field (the dev rig and the scene
  recipes' runtime), and the stroller's `carrying`, which `main` writes itself. No method is added
  for a test.
- **`last_incoming = -1.0` stays because no game call gives that marker**: `reset()` zeroes it.
- **`test_stroller` writes the stroller's `facing`**, since `reset_at()` settles her view at once and
  the cases on how she turns need real frames to turn over.
- **The reads of a `Stroller.Pose`'s `mother_sources`, `mirrored`, `view`, `gait_frame`,
  `walk_phase`, `pram_offset` and `pram_size`** stay, since no game method answers them.
- **`Stroller.atlas` and `Baby.timing` stay public**: `test_atlas_boot` finds the atlas by the
  field's name and `test_frame_record_wiring` reads the timing, as `field-reads.md` says.
- **`test_tutorial_dog`'s case on where the scheduler places the dog** stays, since the scheduler's
  suite is not this pass's; `tests-one-module.md` keeps it as written.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `9f34854cf`, over the `.gd` files
under `tests/` its pull request changed, and each method read in its class and the classes it
extends: each read with the public method that returns exactly that field, or "no method"; each
write with every public method that assigns the field, and what it assigns.

- **`Baby`**: `excitement`, written → `reset()` does `excitement = 0.0`; `last_incoming`, written →
  `reset()` does `last_incoming = 0.0`; `sleepiness`, written → `reset()` does `sleepiness =
  starting_sleepiness`, `force_sleep()` does `sleepiness = Tuning.METER_MAX`.
- **`City`**: `crowd` → no method; `events` → no method; `map` → no method; `scenery` → no method;
  `scenery_ground` → no method.
- **`CrowdAgent`**: `excitement` → `mood()`.
- **`EventDef`**: `from_day_after`, written → no method; `id` → no method; `inner_radius` →
  `core_within()`; `notice` → no method; `notice.within` → `notice_within()`; `outer_radius` →
  `heard_within()`; `shape` → `ground_shape()`; `shape`, written → `solid()` does `shape =
  new_shape`.
- **`EventInstance`**: `def` → `row()`; `def.id` → `row_id()`; `excitement` → `source()`.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.id` → `row_id()`.
- **`LaneMover`**: `kind` through `CrowdAgent` → `lane().kind()` on its view.
- **`MoveProposal`**: `from` → `stands_at()`; `open` → no method; `to` → `steps_to()`.
- **`RunHeader`**: `day`, written → `reset()` does `day = 1`, `restore()` does `day =
  int(data["…"])`; `player_is_male` → no method.
- **`RunState`**: `calendar` → no method; `header` → no method.
- **`SceneryGround`**: `chunks` → no method.
- **`Stroller`**: `carrying`, written → no method; `facing`, written → `reset_at()` does `facing =
  look.normalized()`.
- **`Stroller.Pose`**: `gait_frame` → no method; `mirrored` → no method; `mother_sources` → no
  method; `pram_offset` → no method; `pram_size` → no method; `view` → no method; `walk_phase` → no
  method.
- **`TouchControls`**: `rotated` → no method.
- **`WorldMap`**: `moves` through `CityMap` → no method.

## Verified

The nine suites pass, `tools/typing_census.py --check` holds, and no game file changed, so the
identity probes do not apply. No check was deleted or moved.
