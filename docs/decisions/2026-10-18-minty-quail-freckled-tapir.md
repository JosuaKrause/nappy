# minty-quail — The event scheduler's placement calls, the baby's stroller and the checkpoint's guard drive public seams (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: the event scheduler's placement calls, the baby's stroller and
step, the checkpoint's guard, and the leftover private reads in `test_checkpoints.gd` and the probes.
The item stays open for the callers of the scheduler's private names and `_is_spoiled()`.

**Built.**
- `EventScheduler.open_ground_for()`, `room_around()`, `place_masts()` and `street_ground()`, public
  forms beside the private bodies they forward to, and `place_at(def, map, tile, rng, already)`, the
  one "site this row here if the day's spacing leaves room" entry, which `SceneRecipeRuntime`'s two
  placements call. The scheduler's own loop stays on `_judge()`, which asks many more rules and keeps
  each candidate's verdict and role, so routing it through `place_at()` would change what a day
  places. A test shows `place_at()` refuses a tile a placed plan holds; removing that refusal fails
  it.
- `Baby.set_stroller()` and `step()` (`_physics_process()` calls `step()`); the game's baby still
  takes its parent as its stroller in `_ready()`, so only tests hand one in.
  `CheckpointController.set_a_guard_on_her()` (was private), which only tests call from outside.
- `reach_contacts`, `traps`, `placement_kinds`, `test_checkpoints.gd` and the probes moved onto
  these, `trap()`, `mark_guard()`, `raid_vans()` and `raid_beat()`, and `reach_relocated` onto
  `place_masts()`. `test_checkpoints.gd`'s rig sets the guard on her through the real spawner on
  open ground. No check was dropped or added except `place_at()`'s test.

**Open to overturn** (the builders' choices where the brief was silent): forwards beside the private
bodies rather than renaming them while other files call the private names; leaving the scheduler's
own loop off `place_at()`.
