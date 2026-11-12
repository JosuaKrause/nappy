# minty-quail — The routes', the closures' and the seals' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the routes; its search covers `RouteTree`, `ReachabilityGrid` and
`RoadClosure`.

## What was built

- **Eight files parse without their file-level opt-out line** (`untyped_declaration`, the only warning each
  tripped): `tests/routes_closures_rig.gd`, `test_routes_closures_a.gd`, `_b.gd`, `_c.gd`, `test_route_tree.gd`,
  `test_reachability_grid.gd`, `test_seals.gd` and `test_spent_park.gd`. Every trip was an untyped loop variable
  or one local; the rig keeps every function's name, argument order and answer, and the three other suites that
  load it (`test_routes_fallen_trees`, `test_routes_lattice`, `test_day_spec`) pass unedited.
- **No read converted**: `RouteTree`'s `branches` and `grid` and `RoadClosure`'s `kind` and `segment` (read
  through `ParkClosure`) are read and no method answers them; no field of `ReachabilityGrid` is read. No check
  deleted or moved; nothing under `src/` or `tools/test_only_members.txt` changed.

## Fields read and written, by class

`tools/field_answers.py --counts` on the eight files, as it prints them at b4ef8930d, each named method read in
its class. None is converted: the searched classes' fields above have no method, and every other class's fields,
answered or not, are left for their own modules' passes.

- `City`: `map` read (`tests/test_spent_park.gd` on 15 lines): no method
- `CityMap`: `absent_segments` read (`tests/test_route_tree.gd` on 1 line): no method; `alley_rects` read (`tests/test_seals.gd` on 1 line): `alley_lots()` (4 calls); `block_plans` read (`tests/routes_closures_rig.gd` on 1 line, `tests/test_route_tree.gd` on 1 line, `tests/test_seals.gd` on 1 line, `tests/test_spent_park.gd` on 5 lines): `plans_by_block()` (9 calls, +1 own); `calm_blocks` read (`tests/test_spent_park.gd` on 10 lines): `calm_blocks_now()` (5 calls, +1 own); `closed_tiles` read (`tests/routes_closures_rig.gd` on 1 line, `tests/test_seals.gd` on 1 line, `tests/test_spent_park.gd` on 4 lines): `closed_tile_set()` (1 call); `fenced_park` read (`tests/test_spent_park.gd` on 27 lines): `fenced_park_block()` (1 call); `fenced_park_act` read (`tests/test_spent_park.gd` on 1 line): no method; `home_block` read (`tests/test_seals.gd` on 1 line): `home_block_coordinate()` (6 calls); `home_rect` read (`tests/test_reachability_grid.gd` on 1 line, `tests/test_seals.gd` on 1 line): `home_tile_rect()` (7 calls); `main_road` read (`tests/test_route_tree.gd` on 1 line, `tests/test_seals.gd` on 3 lines): `main_road_corridor()` (18 calls); `network` read (`tests/routes_closures_rig.gd` on 5 lines, `tests/test_route_tree.gd` on 5 lines, `tests/test_seals.gd` on 13 lines, `tests/test_spent_park.gd` on 1 line): `street_network()` (19 calls); `recipe_closures` read (`tests/test_spent_park.gd` on 2 lines): `recipe_road_closures()` (1 call); `seed_used` read (`tests/routes_closures_rig.gd` on 15 lines, `tests/test_reachability_grid.gd` on 5 lines, `tests/test_route_tree.gd` on 25 lines, `tests/test_seals.gd` on 27 lines, `tests/test_spent_park.gd` on 36 lines): `city_seed()` (14 calls); `shut_calm` read (`tests/test_spent_park.gd` on 13 lines): no method; `tiles` read (`tests/test_reachability_grid.gd` on 4 lines): `walk_tiles()` (1 call)
- `ClosureMarker`: `across` read through `ParkFenceMarker` (`tests/test_spent_park.gd` on 1 line): no method; `kind` read (`tests/test_spent_park.gd` on 1 line): no method; `piece` read through `ParkFenceMarker` (`tests/test_spent_park.gd` on 3 lines): no method
- `ClosurePlanner.CalmArea`: `access` read (`tests/routes_closures_rig.gd` on 2 lines, `tests/test_route_tree.gd` on 2 lines): no method; `block` read (`tests/test_route_tree.gd` on 3 lines): no method; `rect` read (`tests/routes_closures_rig.gd` on 1 line, `tests/test_route_tree.gd` on 2 lines): no method
- `EventDef`: `obstructs_radius` read (`tests/test_seals.gd` on 8 lines): `obstructs_within()` (7 calls); of it alone, `has_a_body()` returns `obstructs_radius > 0.0` (7 calls); `shape` read (`tests/test_seals.gd` on 1 line): `ground_shape()` (10 calls); `solid_parts` read (`tests/test_seals.gd` on 3 lines): no method
- `EventInstance`: `age` written (`tests/test_seals.gd` on 1 line): `resume()` does `age = from_age` (3 calls); `def` read (`tests/test_seals.gd` on 1 line): `row()` (2 calls); `excitement` read (`tests/test_seals.gd` on 1 line): `source()` (16 calls)
- `EventPlan`: `def` read (`tests/test_seals.gd` on 14 lines, `tests/test_spent_park.gd` on 1 line): `row()` (27 calls); `def.id` read (`tests/test_seals.gd` on 8 lines, `tests/test_spent_park.gd` on 1 line): `row_id()` (6 calls); `def.obstructs_radius` read (`tests/test_seals.gd` on 1 line): `obstructs_within()` (1 call); `position` read (`tests/test_seals.gd` on 9 lines, `tests/test_spent_park.gd` on 1 line): `placed_at()` (28 calls); of it alone, `is_placed()` returns `position != Vector2.INF` (31 calls, +4 own)
- `ParkClosure`: `area` read (`tests/test_spent_park.gd` on 1 line): no method; `joined_end` read (`tests/test_spent_park.gd` on 1 line): no method; `joined_start` read (`tests/test_spent_park.gd` on 1 line): no method; `outward` read (`tests/test_spent_park.gd` on 1 line): no method; of it alone, `barrier_runs_across()` returns `outward.y != 0` (3 calls)
- `ParkFenceMarker`: `sign_offset` read (`tests/test_spent_park.gd` on 1 line): no method
- `RegionPlanner.RegionPlan`: `alley_doors` read (`tests/test_seals.gd` on 1 line): no method; `alley_walls` read (`tests/test_seals.gd` on 1 line): no method; `doors` read (`tests/test_seals.gd` on 2 lines): no method; `wall_bodies` read (`tests/test_seals.gd` on 1 line): no method; `walls` read (`tests/test_seals.gd` on 2 lines): no method
- `RoadClosure`: `kind` read through `ParkClosure` (`tests/routes_closures_rig.gd` on 3 lines, `tests/test_spent_park.gd` on 1 line): no method; `segment` read through `ParkClosure` (`tests/routes_closures_rig.gd` on 10 lines, `tests/test_route_tree.gd` on 1 line, `tests/test_seals.gd` on 1 line, `tests/test_spent_park.gd` on 3 lines): no method
- `RouteTree`: `branches` read (`tests/test_route_tree.gd` on 14 lines, `tests/test_seals.gd` on 2 lines, `tests/test_spent_park.gd` on 3 lines): no method; `grid` read (`tests/test_route_tree.gd` on 6 lines): no method
- `RouteTree.Branch`: `area` read (`tests/test_route_tree.gd` on 16 lines, `tests/test_spent_park.gd` on 4 lines): no method; `routes` read (`tests/test_route_tree.gd` on 8 lines): no method
- `RunFacts`: `fenced_park` read (`tests/test_spent_park.gd` on 1 line): no method; `fenced_park` written (`tests/test_spent_park.gd` on 1 line): `reset()` does `fenced_park = Vector2i(-1, -1)` (3 calls), `remember_fenced_park()` does `fenced_park = block` (1 call), `restore()` does `fenced_park = Vector2i(int(fenced.get("…", -1)), int(fenced.get("…", -1)))` (3 calls); `fenced_park_act` read (`tests/test_spent_park.gd` on 1 line): no method; `fenced_park_act` written (`tests/test_spent_park.gd` on 1 line): `reset()` does `fenced_park_act = 0` (3 calls), `remember_fenced_park()` does `fenced_park_act = act` (1 call), `restore()` does `fenced_park_act = int(data.get("…", 0))` (3 calls)
- `RunState`: `calendar` read (`tests/test_spent_park.gd` on 1 line): no method; `facts` read (`tests/test_spent_park.gd` on 4 lines): no method
- `SealPlanner.Candidate`: `def_ids` read (`tests/test_seals.gd` on 6 lines): no method; `id` read (`tests/test_seals.gd` on 8 lines): no method; `strength` read (`tests/test_seals.gd` on 4 lines): no method
- `StreetNetwork.Segment`: `a` read (`tests/test_route_tree.gd` on 1 line, `tests/test_seals.gd` on 4 lines): no method; `b` read (`tests/test_route_tree.gd` on 1 line, `tests/test_seals.gd` on 2 lines): no method; `horizontal` read (`tests/routes_closures_rig.gd` on 1 line, `tests/test_route_tree.gd` on 1 line, `tests/test_seals.gd` on 4 lines): no method
- `StreetTrees.Planted`: `position` read (`tests/test_seals.gd` on 2 lines): no method; `segment_key` read (`tests/test_seals.gd` on 1 line): no method; `tile` read (`tests/test_seals.gd` on 2 lines): no method
- `WorldMap`: `size` read through `CityMap` (`tests/test_reachability_grid.gd` on 4 lines, `tests/test_seals.gd` on 1 line, `tests/test_spent_park.gd` on 1 line): `size_in_tiles()` (66 calls)

## Verified

At test parity: the seven changed suites and the three that load the rig pass; the typing census and
`./tools/check.sh` pass.
