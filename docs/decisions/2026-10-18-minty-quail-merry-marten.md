# minty-quail — The routes are typed · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module. This pass is the routes
(`src/routes/`, the model layer). Its search is none: it types and deletes lines and converts no read.

## What was built

- **Six files parse without their file-level opt-out line**: `src/routes/street_network.gd`, `road_closure.gd`,
  `route_tree.gd`, `closure_planner.gd` and `region_planner.gd` (`untyped_declaration`), and `reachability_grid.gd`
  (`untyped_declaration`, `unsafe_method_access`); none after. No method, call or signature changes, and no other
  file changes.
- **Typing**: loops over literal arrays take their element's type (a mouth's or an alley's two sides as `bool`, a
  segment's two ends as `Vector2i`, the candidate segment keys in `StreetNetwork.at_junction()` as `Vector3i`); loops
  over a dictionary's keys take the type of what writes them (segment keys from `Segment.key()` as `Vector3i`, grid
  nodes from `ReachabilityGrid.node_at()` as `int`, region ids from `region_of_junction()` as `int`); nested
  collections are read through typed locals (`_ADJACENT_LOCAL`'s pairs and the junction pairs as `Array` of
  `Vector2i`, a mask's components as the `Array[int]` `_compute_components()` builds); `_maybe_edge()` appends
  through `(_edges[na] as Array)`, the same array by reference.
- **`ReachabilityGrid.flood()` keeps its `sources: Array` parameter** and types only its loop variable `Vector2i`:
  every caller under `src/` and `tests/` passes `Vector2i`s, and a parameter typed `Array[Vector2i]` would fail at run
  time for each caller handing a literal `[tile]`.
- **Left, no read converted**: every field the list below names stays read, each for its own module's pass; the region
  planner's reads of an event plan's row and fields (`EventPlan.def`, `facing`, `gate_state`, `EventDef.guard_sides`)
  for row 3a of `event-interface.md`.

## Fields read and written, by class

`tools/field_answers.py` on the six files, as it prints them at 5b7ccf578, each named method read in its class.

Fields of classes under `src/` that `src/routes/street_network.gd`, `src/routes/road_closure.gd`, `src/routes/route_tree.gd`, `src/routes/reachability_grid.gd`, `src/routes/closure_planner.gd`, `src/routes/region_planner.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `BlockLayout`: `open_rect` read (`src/routes/closure_planner.gd`:222,223): `open_ground()` (8 calls)
- `CityMap`: `absent_segments` read (`src/routes/closure_planner.gd`:457): no method; `alley_rects` read (`src/routes/region_planner.gd`:310,616): `alley_lots()` (4 calls); `block_layouts` read (`src/routes/closure_planner.gd`:221): no method; `boundary_wall_at_a` read (`src/routes/region_planner.gd`:556,635,718): no method; `boundary_wall_at_a` written (`src/routes/region_planner.gd`:137): no method; `calm_blocks` read (`src/routes/closure_planner.gd`:208,310,318,363): `calm_blocks_now()` (5 calls, +1 own); `closed_tiles` read (`src/routes/closure_planner.gd`:403): `closed_tile_set()` (1 call); `fenced_park` read (`src/routes/closure_planner.gd`:116,117): `fenced_park_block()` (1 call); `main_road` read (`src/routes/route_tree.gd`:553): `main_road_corridor()` (18 calls); `network` read (`src/routes/closure_planner.gd`:202,249,459,545; `src/routes/region_planner.gd`:212,250,251,345,374,563; `src/routes/route_tree.gd`:556,774,802,824,825,845,860,892,921,925,982,986,1017,1031): `street_network()` (19 calls); `power_station_door` read (`src/routes/route_tree.gd`:241): `power_station_door_tiles()` (3 calls); `precinct_spans` read (`src/routes/region_planner.gd`:163): `precinct_stretches()` (5 calls); `region_has_calm` read (`src/routes/region_planner.gd`:573): no method; `region_has_calm` written (`src/routes/region_planner.gd`:136): no method; `region_of_junction` read (`src/routes/region_planner.gd`:136,525,527): no method; `region_of_junction` written (`src/routes/region_planner.gd`:135): no method; `seed_used` read (`src/routes/route_tree.gd`:237): `city_seed()` (14 calls); `shut_calm` read (`src/routes/route_tree.gd`:253): no method; `square_rects` read (`src/routes/region_planner.gd`:158): no method
- `ClosurePlanner.CalmArea`: `access` read (`src/routes/region_planner.gd`:507,509): no method; `block` read (`src/routes/route_tree.gd`:253,327): no method; `rect` read (`src/routes/region_planner.gd`:151; `src/routes/route_tree.gd`:352,357): no method
- `EventDef`: `guard_sides` written (`src/routes/region_planner.gd`:674): no method
- `EventPlan`: `def` read (`src/routes/region_planner.gd`:673,674): `row()` (27 calls); `facing` written (`src/routes/region_planner.gd`:732,748): no method; `gate_state` written (`src/routes/region_planner.gd`:734): no method
- `RegionPlanner.RegionPlan`: `doors` read (`src/routes/closure_planner.gd`:541): no method; `walls` read (`src/routes/closure_planner.gd`:539): no method
- `StreetNetwork.Segment`: `a` read (`src/routes/closure_planner.gd`:177; `src/routes/region_planner.gd`:162,216,289,306,330,331,346,377,509,535,552,566,634,717; `src/routes/road_closure.gd`:66; `src/routes/route_tree.gd`:894,924,985,1021): no method; `b` read (`src/routes/region_planner.gd`:162,216,291,307,330,331,347,378,536,553,566,634,717; `src/routes/route_tree.gd`:895,924,985,1021): no method; `horizontal` read (`src/routes/region_planner.gd`:278,720,723; `src/routes/road_closure.gd`:65,95; `src/routes/route_tree.gd`:559): no method
- `StreetTrees.Planted`: `tile` read (`src/routes/closure_planner.gd`:168): no method
- `WorldMap`: `size` read through `CityMap` (`src/routes/closure_planner.gd`:349; `src/routes/reachability_grid.gd`:119,120,122,144): `size_in_tiles()` (66 calls)


## Verified

At parity: `tools/check.sh` boots clean; the field-read check against `origin/main` passes with `tools/field_reads.txt`
unchanged; the typing census and the layer check pass; the routes' suites and every other that names one of the six
classes or runs a rig that does pass, the grid's, the tree's and the regions' again after the merge of main; CI is green.
