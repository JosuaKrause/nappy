extends RefCounted
## The route's own curbstones, tinted whole: `City._tint_the_route_kerbs()` re-sets cells on
## `_ground` itself when `Corridor.depth(tile) == 0`, the same street-grained membership
## `RouteTree.streets()`/`is_on_the_tree()` and `GroundTiles.source_for` already answer
## independently.
##
## Split from `tests/test_routes.gd` under M125, "the test suite is slow again" -- kept on its own
## because it is the one check here that needs a real scene tree (`City.start_day` repaints
## `_ground`, a child node, and reads its own tile set back) rather than the bare
## `CityMap`/`RouteTree` pair every other route test works from directly, and builds its own single
## city rather than sharing `test_routes_lattice.gd`'s twelve.

## Built only by the test below, which needs a real scene tree rather than the bare
## `CityMap`/`RouteTree` pair every other route test works from directly.
const CITY_SCENE := preload("res://scenes/world/city.tscn")

func run(t) -> void:
	_test_the_route_kerb_tint_matches_the_cells_the_tree_carries(t)


## The route's own curbstones, tinted whole: `City._tint_the_route_kerbs()` re-sets cells on
## `_ground` itself when `Corridor.depth(tile) == 0`, the same street-grained membership
## `RouteTree.streets()`/`is_on_the_tree()` and `GroundTiles.source_for` already answer
## independently, so this test recomputes the expected set from those rather than trusting the
## paint to have used its own inputs correctly, and checks `_ground`'s cells directly since there
## is no second layer to read back.
func _test_the_route_kerb_tint_matches_the_cells_the_tree_carries(t) -> void:
	var kerb_sources := GroundTiles.ROUTE_KERB_SOURCES

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(90210))

	var day := 1
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("m145-route-kerbs:closures:%d" % day)
	city.start_day(state, day, rng)

	var tree := city.route_tree()
	var corridor := Corridor.of(tree)
	var expected := {}
	# Every kerb tile in the map, grouped by street segment, with which of them sit at depth 0 --
	# the mark says *this street*, not *this sidewalk*, so the checks below ask whether a segment
	# is tinted whole on both sides or not at all, never a lone tile or a stretch of one.
	var tiles_by_segment := {}
	for y in city.map.size.y:
		for x in city.map.size.x:
			var tile := Vector2i(x, y)
			var source := GroundTiles.source_for(city.map, tile, day)
			if not (source in kerb_sources):
				continue
			var segment := StreetNetwork.segment_containing(tile)
			if not segment:
				continue
			var entry: Dictionary = tiles_by_segment.get(segment.key(), {"tiles": {}, "sources": {}})
			(entry["tiles"] as Dictionary)[tile] = true
			(entry["sources"] as Dictionary)[source] = true
			tiles_by_segment[segment.key()] = entry
			if corridor.depth(tile) == 0:
				expected[tile] = true
	t.check(expected.size() > 0, "the sweep found kerb tiles at depth 0 to check (%d)"
			% expected.size())

	var twin_source_ids := {}
	for source in kerb_sources:
		twin_source_ids[GroundTiles.route_twin_of(source)] = true

	var twinned := {}
	for cell in city._ground.get_used_cells():
		if twin_source_ids.has(city._ground.get_cell_source_id(cell)):
			twinned[cell] = true
	t.check(twinned.size() == expected.size(),
			"Ground carries a route-kerb twin on exactly the kerb tiles at depth 0 "
			+ "(%d expected, %d twinned)" % [expected.size(), twinned.size()])
	for cell in twinned:
		t.check(expected.has(cell), "twinned cell %s is a kerb tile at depth 0" % cell)
	for tile in expected:
		var plain_source := GroundTiles.source_for(city.map, tile, day)
		var expected_atlas := GroundLayers.atlas_coords_for(plain_source, city.map.seed_used, tile,
				city._ground.tile_set)
		t.check(city._ground.get_cell_source_id(tile) == GroundTiles.route_twin_of(plain_source),
				"Ground's cell at %s carries its kerb source's route twin" % tile)
		t.check(city._ground.get_cell_atlas_coords(tile) == expected_atlas,
				"Ground's twinned cell at %s keeps the atlas coordinates the plain source would have had"
				% tile)

	# 1. Whole or nothing: every real street segment is tinted on both kerb lines, every tile, or
	# not at all -- `RouteTree.is_on_the_tree(key)` is the independent, whole-segment membership
	# question, and this checks tile by tile that `Corridor.depth()` agrees with it exactly rather
	# than trusting the two were built the same way.
	var on_tree_segments := 0
	var off_tree_segments := 0
	for key: Vector3i in tiles_by_segment:
		var entry: Dictionary = tiles_by_segment[key]
		var segment_tiles: Dictionary = entry["tiles"]
		var segment_sources: Dictionary = entry["sources"]
		var tinted_count := 0
		for tile: Vector2i in segment_tiles:
			if expected.has(tile):
				tinted_count += 1
		if tree.is_on_the_tree(key):
			on_tree_segments += 1
			t.check(tinted_count == segment_tiles.size(),
					"street %s is on the tree, so every one of its %d kerb tiles is tinted (%d tinted)"
					% [key, segment_tiles.size(), tinted_count])
			t.check(segment_sources.size() == 2,
					"street %s carries kerb tiles on both its sides (%d distinct sources)"
					% [key, segment_sources.size()])
		else:
			off_tree_segments += 1
			t.check(tinted_count == 0,
					"street %s is not on the tree, so none of its kerb tiles are tinted (%d tinted)"
					% [key, tinted_count])
	t.check(on_tree_segments > 0, "the sweep found on-tree streets to check (%d)" % on_tree_segments)
	t.check(off_tree_segments > 0, "the sweep found off-tree streets to check (%d)" % off_tree_segments)

	# 2. A route that only walks part of a segment -- leaving it through an alley or a park, or
	# ending at a calm area partway along -- still tints the whole thing. Found independently of
	# `Corridor.depth()`: `RouteTree.branches_on(tile)` is non-empty on the exact cells a route
	# walks, so a segment where it is non-empty on some of the segment's kerb tiles and empty on
	# others (neither zero nor a whole pavement's worth) is a genuine partial run, and it still has
	# to come back tinted whole in the check above.
	var partial_run_found := false
	for key: Vector3i in tiles_by_segment:
		if not tree.is_on_the_tree(key):
			continue
		var segment_tiles: Dictionary = tiles_by_segment[key]["tiles"]
		var carried := 0
		for tile: Vector2i in segment_tiles:
			if not tree.branches_on(tile).is_empty():
				carried += 1
		var one_pavement: int = segment_tiles.size() / 2
		if carried > 0 and carried != one_pavement and carried != segment_tiles.size():
			partial_run_found = true
			var tinted_count := 0
			for tile: Vector2i in segment_tiles:
				if expected.has(tile):
					tinted_count += 1
			t.check(tinted_count == segment_tiles.size(),
					"street %s, walked by the tree on only %d of its %d kerb tiles, is tinted whole regardless"
					% [key, carried, segment_tiles.size()])
	t.check(partial_run_found,
			"the sweep found a street the tree only partly walked, to check (found one: %s)"
			% partial_run_found)

	# 3. A street the tree only crosses at a junction is never tinted. `RouteTree.gaps()` is
	# exactly that shape -- "one street of the tree crossing each end, and nothing of the tree on
	# the street itself" -- and a stretch of the main road the tree never walked is refused the
	# same way: its own pavements and carriageway are off the growth graph everywhere but at a
	# junction (`RouteTree._is_off_the_growths_graph`), so a main-road segment off the tree can
	# never carry a coloured cell to begin with.
	var gaps := tree.gaps()
	t.check(gaps.size() > 0, "the sweep found gap streets (crossed, not walked) to check (%d)"
			% gaps.size())
	for key: Vector3i in gaps:
		var entry: Dictionary = tiles_by_segment.get(key, {"tiles": {}})
		for tile: Vector2i in (entry["tiles"] as Dictionary):
			t.check(not expected.has(tile),
					"tile %s, on a street the tree only crosses at a junction, is not tinted" % tile)

	var main_road_off_tree := 0
	for key: Vector3i in tiles_by_segment:
		if key.z != 1 or key.x != city.map.main_road or tree.is_on_the_tree(key):
			continue
		main_road_off_tree += 1
		for tile: Vector2i in (tiles_by_segment[key]["tiles"] as Dictionary):
			t.check(not expected.has(tile),
					"tile %s, on a main-road stretch the tree never walked, is not tinted" % tile)
	t.check(main_road_off_tree > 0,
			"the sweep found main-road streets off the tree to check (%d)" % main_road_off_tree)

	city.start_finale(state, day + 1)
	var twinned_after_finale := 0
	for cell in city._ground.get_used_cells():
		if twin_source_ids.has(city._ground.get_cell_source_id(cell)):
			twinned_after_finale += 1
	t.check(twinned_after_finale == 0,
			"start_finale paints no route-kerb twin, since the finale grows no tree")

	city.free()
