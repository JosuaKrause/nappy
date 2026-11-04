# minty-quail — The walk plan and route lines suites drive the dev tools through what they take (tests through public seams: W10a) · 2026-11-04

minty-quail's `tests-public-seams.md`: the walk plan, route lines and burst capture suites, subtask
W10a of the scoped plan. One `src/` change: `AutoScreenshot._parse_script()` is `parse_script()`,
since `AutoScreenshot.from_config()` and `SceneRecipeRuntime` (recipe validation and its `WalkPlan`)
already call it, the second from outside its class.

**Built.**
- `test_walk_plan.gd` (private-read lines 11 to 0, hand-called frame functions 3 to 0) walks a real
  `Stroller` in the tree on real physics ticks, one a frame, pressed by the rig
  `AutoScreenshot.from_config(RunConfig.parse(...))` builds from `--walk`, or `--smooth-walk` for the
  smoothed one; the abrupt rig is handed a clock that counts the ticks passed, and its first step is
  checked by a probe that sees the press stay west at a second and a half. It takes about fifty
  seconds, since each walk passes game time at the game's own tick rate.
- `test_route_lines.gd` (21 to 0) builds the readout as `test_debug_layers.gd` does, in a tree from
  `RunConfig.parse()` with a label, a layer and the run's header, presses keys through the viewport,
  and reads the `RouteLines` node and whether it is visible. It gains nine checks: six other keys
  that must not toggle the routes, the layer flag starting the node on or leaving it off, and a
  release page whose key does nothing.
- Checks 58 and 30472 to 58 and 30481; twelve mutation runs.

**Open to overturn:** the route lines suite still calls `RouteLines.routes()`, a public member no
game class calls.

**Not done:** `test_burst_capture.gd`'s three swaps of `Telemetry._bursts`, so the end of a day and
of a run can be seen cutting a burst short: `Telemetry.start_burst()` refuses in a headless run, so
no call the game makes starts the burst; it wants a screen or recorder handed to `Telemetry`, with
the run folder handed to `begin_run()`, as the item already lists for `test_telemetry.gd`.
