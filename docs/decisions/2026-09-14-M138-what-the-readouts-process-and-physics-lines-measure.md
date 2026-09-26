## M138 — What the readout's `process` and `physics` lines measure · read 2026-09-14

*(2026-09-14, [PLAYTEST-75](../playtests/PLAYTEST-75.md): "local laptop also stutters even though
fps is way above 60", with two desktop screenshots reading 85 to 89 fps beside a `process`
mean of 21 to 52 ms; `evidence/playtest-75-desktop-stutter-2026-09-14/` holds the run.)* Read
from the engine's own `main/main.cpp` on the 4.7 branch, `Main::iteration()`.

**The engine hands over the worst interval of the second, once a second.** Every frame,
`process_ticks` is measured from just before the main loop's `process()` call to just after
the rendering server's `sync()` and `draw()`, and `process_max = MAX(process_ticks,
process_max)`; the physics loop keeps `physics_process_max` the same way over every tick.
Once a second (`if (frame > 1000000)`) the engine calls
`performance->set_process_time(USEC_TO_SEC(process_max))` and
`set_physics_process_time(USEC_TO_SEC(physics_process_max))` and zeroes both. So
`Performance.TIME_PROCESS`, which `FrameCost.process_ms()` reads, is the **longest** process
interval of the previous second, render submit included, and holds that value for a second;
`TIME_PHYSICS_PROCESS` is the longest physics tick of it. The readout's `mean` column (M138,
below) is the mean of a number that changes once a second, and its `max` the larger of two
such numbers.

**What that recasts.** The oddity carried since playtest 72 — the `process` mean outrunning
the frame the `fps` line implied, on every phone screenshot — is not an oddity: a worst frame
of 41 to 50 ms inside a second drawn at 28 fps is a hitch, not a contradiction, and every
`process` figure in the phone tables (M124, the phone's process time split; M139, the phone
reading; M140, the phone reading) is the worst frame of its second, render submit included,
not the cost of a typical one. The `fps` line was the right number to read, as those records
already concluded, and `process` is the size of the hitch beside it. The readout fix is M143.

**The desktop reading.** On the laptop at 85 to 112 fps the run log's `frame` lines read a
worst frame of 16 to 24 ms in every second of play (126 to 148 ms in the day's first second,
which is the day starting), `physics` at 1.7 ms, and the two screenshots' 24 and 67 ms are
the seconds the screenshots themselves were taken in. Two candidates for the stutter, not
one, and they are tested differently:

- **Motion on the physics tick drawn at a frame rate that is not a multiple of it.** She and
  her camera's target move on the tick, sixty a second on this build, and at 85 to 112 drawn
  frames some frames carry a step and some do not, while the crowd moves per frame and the
  camera's smoothing runs per frame — her jitter against a smooth view, the same shape M141
  (the physics tick at thirty) names, and the reason that milestone turns physics
  interpolation on. The M141 release is the test: if her walk reads smooth there, this was it.
- **A hitch of about 24 ms in most seconds, and it is not the observer.** A 16 to 24 ms
  frame in every second at 90 to 110 fps is a frame two to three times its neighbours, and
  the one thing this project does on a one-second cadence is the telemetry observer's own
  `frame` note, so that was the first suspect. Ruled out the same evening: under
  `--no-telemetry --debug` (playtest 75, the hitch without the observer) the readout's
  `process last` — the engine's own longest frame of the previous second, needing no observer
  — read 24.0 and 24.4 ms at 87 and 103 fps, and 11.5 at 119 fps in one second with no hitch.
  What is left is a frame of a remarkably constant length, about 24 ms on this machine, in
  most seconds but not all, on a cadence nothing has measured, with `physics` at 1.6 to 2.0
  throughout. The engine's per-second maximum cannot say when it happens or what ran in it;
  the probe that would is M144, a spike line in the run log naming every frame more than
  twice its neighbours and what the game did in it, and the editor's profiler is the tool
  for a person sitting at the machine.
