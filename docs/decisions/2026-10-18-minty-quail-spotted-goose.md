# minty-quail — Tests close, seal and block map tiles through the map's own calls (tests through public seams) · 2026-11-05


minty-quail's `tests-unseen-reads.md`, section 2.3: tests that wrote a map's tile state by hand.
Tests only; no `src/` change.

**Built.**
- `closed_tiles`: `tests/routes_closures_rig.gd` clears through `close_streets([])`;
  `test_scene_recipe_task.gd` and `tests/finale_rig.gd` close through `close_streets()` on a real
  `RoadClosure`; `test_world_passability.gd` builds a lattice-sized yard with a real street walled in
  and shut for that test.
- `soft_sealed_tiles`: `test_world_passability.gd` seals through `seal_soft_tile()`;
  `test_day13_guard.gd` clears through `clear_day_soft_seals()` and seals the day's own seals again.
- `obstructed_tiles`: `test_day13_guard.gd`, `test_route_rig.gd` and `test_spawn_siting.gd` block and
  free through `obstruct_tiles()` and `release_obstruction()`.
- `alley_rects`: `test_event_views.gd` takes a horizontal and a vertical alley from a generated city.
- Three checks are added, one per rebuilt fixture, that the fixture holds what the test assumes; the
  suites pass shuffled and repeated.
- Five fixtures stay, each listed in the item with why no game writer makes it.

**Open to overturn:** owner id 1 for a test's own obstructions; the added fixture checks;
`test_event_views.gd` uses the first alley of each direction on alley ground in seed 4242, with the
barrier at the alley's centre.
