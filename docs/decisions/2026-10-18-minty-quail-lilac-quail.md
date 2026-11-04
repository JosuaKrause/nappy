# minty-quail — The wall shield, danger, crowd bodies and stretch-crowd suites read what the crowd does (tests through public seams: W4) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the wall shield, danger, crowd
bodies and stretch-crowd suites, subtask W4 of the scoped plan. No `src/` change and no seam added;
the shared test helper `tests/building_events.gd` lets `events_in()` take the run it builds on.

**Built.**
- `test_wall_shield.gd` (private-read lines 19 to 2) hands the map to `EventInstance.setup()`,
  places cars with `CrowdAgent.setup_at()`, reads a contribution through `contribution_at()` after
  `move_to()` and a wall through `wall_grid().wall_between()`, and lets the explosion wait run real
  manager ticks through `PhysicsTicks`. Its skip test asks the public `open_runs()` with a one-point
  outline (a blocked line leaves no run, an open one exactly one) instead of the private
  `_deep_ground_meets()`; the skip itself is checked apart, by handing `open_runs()` a map that
  counts its wall questions through the parameter the game uses for an emitter's `wall_grid()`: none
  on open ground or with a building out of reach, some beside a thick building.
- `test_danger.gd` (3 to 0) places its car and walker on a real street through the crowd's own
  entry, with the street helpers it shares with the crowd-bodies suite in `tests/crowd_street_rig.gd`; the car runs at 130, since the old 100 is below what the entry accepts.
- `test_crowd_bodies.gd` (3 to 0) reads an `EventInstance` set up as the spawner sets one up, and
  checks every crashed car's middle against the ground the day's record holds.
- `test_scene_recipe_stretch_crowd.gd` (5 to 0) walks a walker and a car off every end of a real
  `City` on a fresh `RunState` under a `ScreenCrowdView` and a real camera, on the crowd's own
  ticks: a body at an end in view turns round, and every entry is out of the real view and on the
  stretch's street. It places one walker and one car per end, where the old test recycled the authored
  actors from their authored positions. Its 96 checks that the camera centred on the actor go, since they tested the old
  test's own camera placement.
- Each suite builds its city or run on a fresh `RunState`; the stand-in reached through
  `RunCity.of_the_run` and `BuildingEvents.events_in` is gone from all four. Checks 87, 153, 91 and
  174 to 95, 155, 97 and 100; sixteen mutation runs.

**Open to overturn:** two mutations survive: dropping one
of the stretch's redundant in-view guards alone (the pairs are pinned, as before), and dropping
`invalidate_contribution()` from `EventInstance.move_to()`, since no wall check asks the same point
twice running.

**Not done:** the wall shield's cull test still reads `DebugLayers._bounds_of` and `_may_be_seen`;
it wants `DebugLayers` handed emitters of a chosen shape and speed, since no real event row or crowd
agent reaches the old sweep's speeds and spines.
