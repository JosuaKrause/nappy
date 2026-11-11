@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## A generated map's precinct posts: where `CityMap.post_positions()` puts them, and that everything
## that steps or floods over the map sees their tiles as blocked.
##
## The posts' bodies and her walking into them are `tests/test_bollards.gd`'s. This suite asks the map,
## across a spread of generated cities (`tests/city_map_cache.gd` hands each seed's city as a copy of
## its own), and builds no `City`.
##
## **Why `Navigator` and `ReachabilityGrid` are in a map's suite**: the promise is that a post's tile
## is closed to *everything* that moves over the map, her own body aside, a guarantee that spans the
## map and the two things that walk on it, so the last case asks all three of one map and a mock of
## any of them would answer nothing.

const MapCache := preload("res://tests/city_map_cache.gd")

func run(t: TestRunner) -> void:
	_test_every_gap_is_narrower_than_her_body(t)
	_test_nothing_walks_through_the_row_but_her_own_body(t)

## The rows of one map, as lists of cross-axis centres, plus the axis they run along.
func _rows(map: CityMap) -> Array:
	var rows := {}
	var out: Array = []
	var posts := map.post_positions()
	for span in map.precinct_spans:
		var vertical := span.x == 1
		for at in posts:
			var tile := map.world_to_tile(at)
			if CityMap.junction_index(tile.x if vertical else tile.y) != span.y:
				continue
			var along: float = at.y if vertical else at.x
			var key := "%d:%d:%d" % [span.y, int(vertical), int(along)]
			if not rows.has(key):
				rows[key] = {"vertical": vertical, "along": along, "across": [] as Array[float]}
				out.append(rows[key])
			rows[key].across.append(at.x if vertical else at.y)
	return out

## Every gap between two posts of a row is narrower than her body, on every map.
func _test_every_gap_is_narrower_than_her_body(t: TestRunner) -> void:
	var post_radius := Prop.bollard_shape().radius
	# Her body alone, whatever way she faces, is 2 x 14 across; a gap that holds it lets her by.
	var body := 2.0 * Tuning.PLAYER_BODY_RADIUS
	var widest := 0.0
	for i in 6:
		var map := MapCache.of(1000 + i * 7919)
		for row in _rows(map):
			var across: Array = row.across
			across.sort()
			t.check(across.size() >= 2, "a row has at least two posts")
			for k in range(1, across.size()):
				widest = maxf(widest, float(across[k]) - float(across[k - 1]) - 2.0 * post_radius)
	t.check(widest < body,
			"the widest gap between two posts (%.1fpx) is narrower than her body (%.1fpx)" % [widest, body])

## **Everything that steps or floods for her or a pursuer sees the posts' tiles as blocked**, the
## way her body does (`CityMap.post_tiles()`): a pursuer's step does not enter one, a flood from the
## street side of a row reaches the precinct side only by the pavement (so it is longer than the
## straight line down the band), and `ReachabilityGrid` has no node on a post's tile but joins the
## two sides all the same.
func _test_nothing_walks_through_the_row_but_her_own_body(t: TestRunner) -> void:
	for seed_value in [1000, 500, 4242]:
		var map: CityMap = MapCache.of(seed_value)
		var posts := map.post_positions()
		var row: Dictionary = _rows(map)[0]
		var vertical: bool = row.vertical
		var along := Vector2(0.0, 1.0) if vertical else Vector2(1.0, 0.0)
		var tile := Vector2i(1, 0) if vertical else Vector2i(0, 1)
		var middle: Vector2 = posts[2]
		for at in posts:
			t.check(not map.is_walkable(map.world_to_tile(at)) and not map.is_open(map.world_to_tile(at)),
					"a post's tile is neither walkable nor open")
		# A pursuer walking straight down the band is not let onto the row's tile.
		var before := middle - along * float(Tuning.TILE_SIZE)
		var step := Navigator.new(map).step(before, along * float(Tuning.TILE_SIZE),
				Mover.on_foot(EventInstance.FIGURE_RADIUS))
		t.check(not step.is_equal_approx(along * float(Tuning.TILE_SIZE)),
				"a pursuer's step does not enter the row's tile (seed %d)" % seed_value)
		# Reachability: round by the pavement, never through.
		var from := map.world_to_tile(middle - along * float(Tuning.TILE_SIZE) * 3.0)
		var to := map.world_to_tile(middle + along * float(Tuning.TILE_SIZE) * 3.0)
		var field := map.walk_field(from)
		t.check(map.reaches(field, to), "the two sides of the row are joined (seed %d)" % seed_value)
		t.check(map.distance_at(field, to) > 6,
				"and joined round the row, not down the band (%d tiles, seed %d)"
				% [map.distance_at(field, to), seed_value])
		var grid := ReachabilityGrid.build(map)
		t.check(grid.node_at(map.world_to_tile(middle)) < 0, "the grid has no node on a post's tile")
		t.check(ReachabilityGrid.build(map, Mover.ground()).node_at(map.world_to_tile(middle)) >= 0,
				"but the lattice the route tree grows on still does")
		var reached := grid.flood([from])
		t.check(grid.reaches(to, {}, reached), "the grid joins the two sides of the row (seed %d)" % seed_value)
