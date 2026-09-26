## Capture key and encoder compatibility — 2026-09-08

PLAYTEST-41 reported that Shift interfered with running and ffmpeg rejected `-fps_mode`. Burst
capture moves to plain B, which is independent of the run modifier and remains available while
Shift is held. P remains the single-screenshot key; `snapshot_burst` remains the rig action.
The converter uses `-vsync vfr` and its test decoder uses `-vsync 0`, preserving measured frame
intervals without requiring `-fps_mode`. The shell used for development found ffmpeg 7.1.1,
which accepted the newer option; that local success did not establish compatibility with the
encoder reached by the player's command. Source frames and existing videos remain untouched.

The focused burst tests cover B, Shift+B, P, Shift+P and key repeats. The real ffmpeg
encode/decode test also rejects any converter invocation containing `-fps_mode` while retaining
frame-order, timing and source-preservation assertions. Boot, focused tests and lint passed.
Retrying the telemetry scan converted both pending bursts from the reported run, including
the sequence that failed in PLAYTEST-41, to sibling MP4s without changing their PNGs.
