# minty-quail — The player's and the baby's suites are typed and read the baby through methods · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin).
This is the player's and the baby's pass of `typed-everywhere.md`'s "What is untyped in a test goes
as its suite is converted", after the baby and the stroller were handed their parts
(minty-quail-fluffy-yak) and the runner was typed in every suite (minty-quail-downy-kestrel).

## What was built

- **`test_meters`, `test_camera_start`, `test_move_poses`, `test_player_presentation` and
  `test_tutorial_dog` are typed and lose their opt-out line**; `test_baby_world` and
  `test_loose_dog_arrives` had none. No line under `src/` changed.
- **`test_meters` and `test_baby_world` read the baby through `sleepiness_level()`,
  `excitement_level()`, `condition()` and `last_frame_incoming()`**, which the game calls.
- **`test_player_presentation` hands the stroller its atlas** through `Stroller.use_atlas()` and
  reads the picture off the library it handed, where it read `Stroller.atlas`.
- **`test_camera_start` types `main` by a preload of `res://src/main.gd`**, as `test_atlas_boot`
  does, since the file has no class name.

## Left, each with its reason

- **The suites still write the baby's meters** (`sleepiness`, `excitement`, `state`,
  `last_incoming`) and the stroller's `carrying` to set a case up: no game method sets a meter, and
  none is added for a test. The fields stay public.
- **`Stroller.atlas` and `Baby.timing` stay public**: suites outside this pass read them
  (`test_frame_record_wiring` among them), as `field-reads.md` says.
- **`test_tutorial_dog`'s case on where the scheduler places the dog** stays, since the scheduler's
  suite is not this pass's; `tests-one-module.md` keeps it as written.

## Verified

The seven suites pass, `tools/typing_census.py --check` holds, and no game file changed, so the
identity probes do not apply. No check was deleted or moved.
