# minty-quail — Six members only tests call get their game answer or go (the scene recipes' pass, D2a) · 2026-11-23

Typing the scene recipes' two files (`SceneRecipeRuntime`, `SceneRecipeDraft`) will delete their
opt-out lines, and `tools/check_test_only_members.py` then counts their untyped receivers no more
as readers of any member of that name. Run on a copy of `src/`, `tests/`, `tools/` and
`project.godot` with both lines deleted, it failed on six members, each of which this change fixes;
the same probe on the branch passes.

- `PauseScreen.close()` (30 test lines) is `_close()`. The game closes the screen only through its
  own input handler, so the suites dismiss it as a keyboard player does: `UI.dismiss()`
  (`tests/ui_screens.gd`) pushes `ui_accept` (space) through the viewport, which closes it at once.
- `DaySpec.length` (16) and `CordonTape.length` (6) are `_length`. The spec's clock is read through
  its existing `seconds_on_the_clock()`. The tape's six lines were `Vector2.length()` calls the
  check read as its field by name; a private field ends the misreading.
- `CrowdField.map` (1, a read of another class's `.map`) is `_map`; `WalkField.keys` (1, a
  dictionary's `keys()`) is `_keys`, read through its existing `key_at()`.
- `ProposedMoves.all()` (3) is kept, in the [kept] group, with its reason. Two readers moved to
  `keeping_their_course()`, which the game's separation pass reads (the event figures' moves keep
  their course). `tests/test_move_poses.gd` checks that each listed move stands where a mover does,
  crowd bodies' moves (which give way) included, and the movers keep their moves private, so the
  whole list has no other call. Rejected: dropping the crowd half of that check, which loosens it.
  Open to overturn: a mover's move given a public answer would let the check go through the movers.
