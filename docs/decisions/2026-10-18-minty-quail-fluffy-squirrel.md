# minty-quail — The run log is handed its screen, its burst recorder and its run folder by the game (tests through public seams) · 2026-11-05

minty-quail's `tests-public-seams.md`: `tests/test_telemetry.gd` and `tests/test_burst_capture.gd`.
Observers: `src/autoload/telemetry.gd` and a new `src/telemetry/telemetry_viewport_screen.gd`; the
composition root: `src/main.gd`; run flow: `RunSession.open()`.

**Built.** `Telemetry.use_screen()` and `use_bursts()` take the screen and the burst recorder and
return the ones they replace; `main` hands in a `TelemetryViewportScreen` (the autoload's own
viewport screen, moved to a file of its own) and a `BurstRecorder` over it at boot, right after
`configure()`. `begin_run()` takes the folder the day folders go in, and `RunSession.open()` hands
it `Telemetry.DIRECTORY`. A path that does not go through `main` (tools, probes, suites driving
`Telemetry` alone) keeps what the autoload builds for itself. The telemetry suite counts the shots
a drawing screen writes into a scratch run folder, and its three run-folder tests write a scratch
folder instead of the player's own `user://telemetry`; the burst suite hands its bench recorder
through `use_bursts()` and hands the game's back. The runner's shared-state check compares the
autoload's screen and recorder as observer fields.

**Choices, open to overturn.** The folder comes from `RunSession.open()` passing the default
rather than from the run's configuration, which has no folder field: a configured folder wants a
dev flag, a `RunConfig` field and their docs and tests (the builder's call).
