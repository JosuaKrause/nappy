# crisp-ferret — Leaving a hut draws her in one place only · built 2026-09-27

*([sunny-hedgehog](../playtests/2026-09-27-sunny-hedgehog.md), statements 1 and 2: "the flicker when
exiting a hut is still there btw. it's shorter now but it still happens" · "the position of the
player is at its original position a frame before the player teleports")*

**The cause.** `Stroller.teleport_to()` calls `reset_physics_interpolation()` while she is still
hidden, since `EventManager` puts her down on the far side one line before it shows her again, and
Godot skips that reset on a hidden node (godotengine/godot#110584). Her interpolated position stays
pinned at the door for the whole hold, and the first frame she is shown blends from the door toward
the far side.

**Built (PR #413).** Godot's skip reads `is_visible_in_tree()`, so every reset has to land while
she is shown. `teleport_to()`, `show_after_inspection()` and `reset_at()` (a day that begins after
one ended mid-hold) all reset through one helper, `_reset_interpolation_if_shown()`, and the
camera's reset on hold entry, made while its parent is already hidden, goes through
`_force_reset_camera_interpolation()`, which shows her for that one call. `tests/test_checkpoints.gd` drives a real hold through a
spy subclass (`tests/stroller_interpolation_spy.gd`) and asserts the reset arrives while she is
visible; it fails without the line. The bursts in `docs/evidence/hut-exit-frame-2026-09-27/` do not
show the frame either way: a burst samples every 80 to 100ms and the flicker is one 33ms tick, so
the test is the proof and the player's eye is the check.
