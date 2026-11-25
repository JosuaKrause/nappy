# minty-quail — The baby reports on a bus it is handed; the stroller tells the controls by a signal · 2026-11-10

**The ask.** "never read fields directly. always read through a method" (inbox #1173 in
gray-dolphin), and a component is handed what it depends on (minty-lemur #794). A Fable planning
agent cut the player and baby module pass: her and the baby's readers (`field-reads.md`), the
baby's share of the signal bus and the stroller's two names of view classes
(`standing-layer-breaks.md`), with `baby.gd` typed.

## What was built

- **The baby reports on a bus it is handed** (`Baby.use_bus()`, called by `main._make_player()`
  with the `EventBus` autoload) instead of fetching the autoload. Its four signals each go out
  through one private teller that does nothing without a bus, at the same points and in the same
  order as before. The shape (the bus script preloaded as the field's type, `use_bus()`, one
  guarded teller per signal) is what the other emitters copy. `baby.gd` leaves the layer map's
  `EventBus` group.
- **`main` hands her and the baby their parts through calls**: `Stroller.use_atlas()`,
  `Stroller.draw_as_father()`, `Baby.freeze_excitement()` (on an invincible run) and
  `Baby.use_frame_timing()`, in place of four field writes.
- **The HUD asks the baby** through `sleepiness_level()`, `excitement_level()` and the new
  `Baby.condition()`, which of her states she is in (awake, asleep or crying), the value
  `baby_state_changed` carries.
- **The stroller names no view class.** It emits `let_out_of_the_hold` where it called the
  on-screen controls' group; `main._make_player()` connects that to
  `TouchControls.stand_still_after_hold()` for each of the three places that make her.
  `Stroller.set_screen_rotation()` is deleted: `Stroller.camera()` hands out her camera and
  `main._apply_orientation()` turns it, as it turns the boot camera. The layer map loses its
  `ScreenOrientation` entry, its `HelpText.CONTROLS_GROUP` group entry and `stroller.gd` from the
  `HelpText` entry.
- **`baby.gd` is typed** and loses its first-line opt-out; the float sums keep their order.
- **Two fields went underscore-private beyond the brief**, which expected a reader to remain:
  `Stroller.is_male` and `Baby.excitement_frozen`. Once `main` calls methods nothing under `src/`
  reads either, and `tools/check_test_only_members.py` answers that by fixing the member, never by
  listing it. Their tests ask through the seam: `draw_as_father()` and the picture she is drawn
  with (`pose(1.0).mother_sources`), `freeze_excitement()`, and in `test_run_config` what the flag
  does, whether the booted baby's excitement rises over three ticks against a loud stand-in world.
- **Two fields stay public for the tests alone**: `Stroller.atlas` and `Baby.timing`, which nothing
  under `src/` but their own file reads once `main` hands them in. `check_test_only_members.py` does
  not see them, since `atlas` and `timing` are words other files use; the tests hand the stroller its atlas
  through `Stroller.use_atlas()` and the baby's timing through `Sitting.use_frame_timing()`, which `main`
  hands on (no test calls `Baby.use_frame_timing()`), and `field-reads.md` holds them until the tests read
  through methods.
- **Which bus a test hands the baby.** The autoload where the test composes something that listens
  on it (the day's clock, the HUD, the run log's observer, an event manager); a bus of its own in
  `test_meters`, a suite about the baby alone; none where nothing listens.
- `tools/field_reads.txt` lost seven lines, and the two comments that named the removed members
  (`ScreenOrientation.apply_to_camera()`, `DevFlags.invincible()`) say what she and the baby offer.

## Parity

The excitement fingerprint (what every source charges her) and the events tick sweep's chains give
one hash each on `main` at `651606332` and on the pull request's head. Nothing on screen changes.

## Choices open to the player's overturn

- **The names** `Baby.condition()` (the brief asked for what the HUD wants, not `state`;
  `baby_state()` was weighed and dropped as the field's name with a prefix),
  `Stroller.let_out_of_the_hold` and `Stroller.draw_as_father()` (its parameter stays the run
  header's yes-or-no).
- **A baby handed no bus tells nobody**, as a baby handed no world answers neutrally
  (`Baby.set_world()`); the orchestrator's reading.
- **The two fields made private** past the brief, for the reason above.
