extends RefCounted
## `ReachabilityGrid`: the tile graph contracted into two-tile cells.
##
## The one property that matters is agreement with `CityMap.walk_field`: the grid is the tile
## graph contracted, so any tile it answers differently for is a defect in the contraction rather
## than a design choice. Everything else here is what makes that agreement possible — the mask
## table, and a query's ability to see a blocked tile the grid was not built with.

const SEEDS := 12
const BASE_SEED := 61030

func run(t) -> void:
	var maps: Array[CityMap] = []
	for i in SEEDS:
		maps.append(CityGenerator.generate(BASE_SEED + i * 17))
	_test_the_mask_table(t)
	_test_the_grid_agrees_with_walk_field(t, maps)
	_test_every_walkable_tile_has_a_node(t, maps)
	_test_a_sliver_building_is_not_walked_through(t)
	_test_a_query_sees_a_blocked_tile_the_grid_was_not_built_with(t, maps)
	_test_a_diagonal_split_is_two_components(t)

# ------------------------------------------------------------------- the mask ---

## Sixteen masks. Fourteen are zero or one component; the two diagonals — `NW+SE` (bit 0 and bit
## 3, mask 9) and `NE+SW` (bit 1 and bit 2, mask 6) — are two components that do not connect to
## each other, because a diagonal pair of tiles shares no edge.
func _test_the_mask_table(t) -> void:
	var counts := {
		0: 0, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 2, 7: 1,
		8: 1, 9: 2, 10: 1, 11: 1, 12: 1, 13: 1, 14: 1, 15: 1,
	}
	for mask in 16:
		var components: Array = ReachabilityGrid._components_of_mask(mask)
		t.check(components.size() == counts[mask],
				"mask %d has %d component(s) (got %d)" % [mask, counts[mask], components.size()])
		var seen := {}
		for component: Array in components:
			for slot in component:
				t.check(not seen.has(slot), "mask %d: slot %d claimed by one component only"
						% [mask, slot])
				seen[slot] = true
				t.check(mask & (1 << slot) != 0,
						"mask %d: component only names walkable slots" % mask)

# ------------------------------------------------------------ agreement with tiles ---

## The property the whole class exists for: with nothing blocked, flooding the grid from the
## doorstep reaches exactly the tiles `CityMap.walk_field` does. Checked both ways — nothing the
## tile flood reaches is missed, and nothing extra is claimed — over every seed generated above,
## which is what makes this a sweep rather than a single example.
func _test_the_grid_agrees_with_walk_field(t, maps: Array[CityMap]) -> void:
	var checked := 0
	for map in maps:
		var grid := ReachabilityGrid.build(map)
		var from := map.world_to_tile(map.doorstep_world_position())
		var field := map.walk_field(from)
		var reached := grid.flood([from])
		for y in map.size.y:
			for x in map.size.x:
				var tile := Vector2i(x, y)
				var walked := map.reaches(field, tile)
				var gridded := grid.reaches(tile, {}, reached)
				t.check(walked == gridded,
						"seed %d: %s agrees between walk_field (%s) and the grid (%s)"
						% [map.seed_used, tile, walked, gridded])
				checked += 1
	t.check(checked > SEEDS * 100 * 100, "the sweep actually covered the maps (%d tiles)" % checked)

## Every walkable tile belongs to some node — a tile the grid drops on the floor would make it
## agree with `walk_field` by accident on any seed that never routes through it.
func _test_every_walkable_tile_has_a_node(t, maps: Array[CityMap]) -> void:
	var map := maps[0]
	var grid := ReachabilityGrid.build(map)
	var missing := 0
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.is_walkable(tile) and grid.node_at(tile) < 0:
				missing += 1
	t.check(missing == 0, "seed %d: every walkable tile has a node (%d missing)"
			% [map.seed_used, missing])

# --------------------------------------------------------------------- the sliver ---

## The case the milestone is named for: a one-tile building sliver with open ground on both
## sides. A cell whose mask is a single component would walk straight through it; the grid must
## see two components (or, once neighbours are counted, two islands that only reconnect around
## the sliver) instead.
func _test_a_sliver_building_is_not_walked_through(t) -> void:
	var map := CityMap.new(Vector2i(8, 4))
	map.tiles.fill(GameEnums.TileType.SIDEWALK)
	# A wall down the middle column, two tiles tall — a sliver exactly one tile wide.
	for y in 4:
		map.set_tile(Vector2i(4, y), GameEnums.TileType.BUILDING)
	var grid := ReachabilityGrid.build(map)
	var west := grid.flood([Vector2i(0, 0)])
	t.check(not grid.reaches(Vector2i(5, 0), {}, west),
			"a sliver wall is not walked through by the grid")
	t.check(grid.reaches(Vector2i(3, 0), {}, west), "the west side of the sliver is reachable")

# --------------------------------------------------------------------- blocked tiles ---

## A query can hand in tiles the grid never saw at build time and still get the right answer,
## which is what a candidate closure's barrier and an event's obstruction circle both need: the
## grid is built once a day, long before either exists.
func _test_a_query_sees_a_blocked_tile_the_grid_was_not_built_with(t, maps: Array[CityMap]) -> void:
	var map := maps[0]
	var grid := ReachabilityGrid.build(map)
	var home := map.world_to_tile(map.home_rect.position)
	var open := grid.flood([home])
	var far: Vector2i = map.calm_tiles()[0]
	t.check(grid.reaches(far, {}, open), "seed %d: some calm tile is reachable at all"
			% map.seed_used)

	# Wall the home in on all four sides with a fresh blocked set the grid was never built with.
	var blocked := {}
	for offset in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		blocked[home + offset] = true
	var sealed := grid.flood([home], blocked)
	t.check(not grid.reaches(far, blocked, sealed),
			"seed %d: sealing every tile round the source blocks the query" % map.seed_used)
	# And unrelated to the block, an unblocked query is untouched by having asked a blocked one.
	var reopened := grid.flood([home])
	t.check(grid.reaches(far, {}, reopened),
			"seed %d: a later unblocked query is unaffected by an earlier blocked one"
			% map.seed_used)

## A query's blocking can turn one component into two even though the grid was built with the
## cell as a single component — the diagonal case, produced here by blocking two of a cell's four
## tiles rather than by generation. The map is exactly the one cell, so there is no way round it:
## anything that reconnects NE and SW would have to be the grid seeing them as one component.
func _test_a_diagonal_split_is_two_components(t) -> void:
	var map := CityMap.new(Vector2i(2, 2))
	map.tiles.fill(GameEnums.TileType.SIDEWALK)
	var grid := ReachabilityGrid.build(map)
	# Block NW and SE: NE and SW survive and are not adjacent to each other, only diagonal.
	var blocked := {Vector2i(0, 0): true, Vector2i(1, 1): true}
	var reached := grid.flood([Vector2i(1, 0)], blocked)
	t.check(grid.reaches(Vector2i(1, 0), blocked, reached), "NE of the split cell is itself reached")
	t.check(not grid.reaches(Vector2i(0, 1), blocked, reached),
			"and SW is not, because the two surviving corners of the cell do not touch")
