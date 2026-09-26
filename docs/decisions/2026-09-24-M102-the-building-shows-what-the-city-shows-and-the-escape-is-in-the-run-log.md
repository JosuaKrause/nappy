## M102 — The building shows what the city shows, and the escape is in the run log · built 2026-09-24

*([PLAYTEST-115](../playtests/PLAYTEST-115.md): "The escape shouldn't behave any different than the
rest of the game".)* The screen-edge badge, the excitement halo and the debug view's layers work
in the building. They only ever asked `EventManager` for `instances()`, which `InteriorEvents`
already answers under the same name, so each now takes any node that does, and a missing crowd;
no adapter class was needed. `main.gd` hands them the building's events until the city exists and
re-points them at the service door, so a layer switched on stays on; the readout (`4`) and the
frame graph (`6`) run in both sections, the readout showing the section and its clock. The shadow
layer no longer outlines a pram while she carries the baby.

**The escape writes a run log as a day does.** The day's `TelemetryObserver` watches both
sections through `FinaleController.clock()`: each section start writes `start entered|restarted
the building|city at (x,y)` with the clock at zero, a lost section writes the day's `lost` line
naming the section, and getting out writes `home escaped by the tunnel|bridge, Ns to spare`.
**What a day writes and the escape does not:** `path` (no route tree), `cross`, `road` and
`calm`/`left` in the building (no streets or calm ground), `closure` (the finale's walls are
events, met as `near`), `contact`, `crowd`, `quiet` and `nerve`, and the dawn and dusk maps.
`tests/test_interior.gd` and `tests/test_telemetry.gd` cover the halo rim, the badge, the
bounding-box layer and the log's lines; evidence is in
`evidence/m102-building-shows-what-the-city-shows-2026-09-24/`.

**Open to overturn, chosen by the agent:** a shared method name rather than a base class; a
restart is a `lost` line then a `start … restarted` line rather than a new header; `lost` and
`home` are reused, so `tools/stats.sh` counts escape sections with days. **Not built:** the route
layer (`5`) draws nothing in either section, since neither has a day route tree; drawing the two
chains there would be a new feature nobody has asked for. Three findings went to M100's defects.
