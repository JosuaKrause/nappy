## M151 — The city stays hidden until the camera is on her · built 2026-09-15

*(2026-09-15, [PLAYTEST-76](../playtests/PLAYTEST-76.md): "when starting the game I can briefly
see the top left of the map".)* One agent commit on `feature/m151-camera-start`, reviewed on
the PR.

**Which frame it was.** Neither candidate the entry led with. `reset_smoothing()` after
`Stroller.reset_at()` takes, and the title screen's camera is parked on her throughout by
`stand_aside()`'s `process_mode = ALWAYS`. The frame is earlier than either: `Main._ready()`
builds the city and adds it to the tree, then awaits twice inside `_warm_the_pictures()` — the
halo shader's warm-up — before the player and her `Camera2D` exist. Those two frames are drawn
through the viewport's default identity transform, whose origin is the map's top-left, with
the built city under it; a headless boot printing the canvas transform at those awaits shows
the identity.

**The fix.** `_city.visible = false` when it is instantiated, and `true` right after
`_player.reset_at()` in `_start_day()`, where the camera is on her the instant the call
returns; every later day finds it already visible. Nothing about the camera's follow changes.

**The check.** `tests/test_camera_start.gd` boots the real `scenes/main.tscn`: adding it runs
`_ready()` up to its first suspension, which is the state the first frame draws from, and
asserts there that no player exists and the city is hidden; then resumes the two awaits by
emitting `process_frame` by hand, the way `tests/test_pause.gd` resumes a coroutine, and
asserts that the two frames the entry named — the first with the run started and the first
after the title's disc — draw within a tile of her. It failed on the code before the fix on the
hidden-city check alone and passes after. No still: the frame is earlier than a screenshot rig
exists in the tree. The agent's choices, open to overturn: the escape sequence was left alone,
since its city is built only after the warm pass returns; the check writes a real run log,
because a suite cannot pass `--no-telemetry` to its own process, and ends the run afterwards.
