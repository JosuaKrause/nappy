# minty-quail — The booted suites hold the boot still, and the navigator names the crowd's lane step as its exception · 2026-11-07


minty-quail's `tests-isolated.md` (its last part) and `shared-components.md`, in #1191. Both items
are closed by it.

**Built.**
- **The boot held still where a check reads what drifts.** A booted `main` has stepped as many
  physics ticks by the time a suite takes hold as the wall clock gave its boot frames. The shared
  boot (`Boot.boot`, `Boot.until_booted` in `tests/booted_main.gd`, and `Seat.boot`) takes
  `still := true`, which runs the boot at a time scale of 1e-7 (`STILL_SCALE`, the value
  `test_move_poses.gd` uses) and restores the scale before it returns. `test_boot_handing` (the
  crowd patch's centre and her position), and `test_main` (the camera hand-off) hold it. `test_run_config`, `test_run_flow` and `test_run_checkpoints`
  read no position or crowd state after their boots, so they do not, and nor does
  `test_frame_record`, whose crowd count is read after the title press and many real frames. `test_move_poses` keeps its own
  hold, which spans the title press too.
- **What makes the suites isolated otherwise** was already built: the runner fails a suite that
  leaves shared state changed, shuffles and repeats suites (`--shuffle SEED`, `--repeat N`), and
  each CI shard prints its shuffled order with the command that replays it (freckled-moose #914).
- **The navigator's header** (`src/world/navigator.gd`) names the crowd's lane-following held step
  (`LaneMover`, with its `LaneStrategy`) as the one motion that stays off it, a different model from the navigator's swept
  step, kept off it through the refactor because moving it cannot hold test parity (inbox #1155 in
  gray-dolphin). Whether it moves later is sunny-osprey, after the remeasuring.
- **Measured:** the six suites, `--repeat 5 --shuffle 7`, before and after: 3110 checks, 0
  failures each. Their checks print no values, so a drift inside a check's tolerance shows in
  neither run.

**Open to overturn:** the hold is an optional argument on the shared boot rather than a helper of
its own; two of the six suites hold it, by the item's rule that a suite holds it when a check
reads a position or a crowd state.
