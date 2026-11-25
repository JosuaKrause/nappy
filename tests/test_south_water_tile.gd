extends RefCounted
## The south water's one live tile (`SouthWaterTile`): that the square it draws is seamless, and
## that the place each ground cell takes its picture from makes the cells, and the chunks the ground
## streams in, meet without a seam. Which cells of a city are water is
## `tests/test_city_ground_water.gd`'s; the tile's clock and its drawing while water stands are the
## ground's, in `tests/test_scenery_residency.gd`.

func run(t: TestRunner) -> void:
	_test_the_square_wraps(t)
	_test_cells_meet_without_a_seam(t)

## The shader's centroids repeat every `wrap_cells` cells of `cell_size` pixels; the square is
## seamless only when that period is its side.
func _test_the_square_wraps(t: TestRunner) -> void:
	var tile := SouthWaterTile.new()
	var lines := (tile.get_child(0) as CanvasItem).material as ShaderMaterial
	var period := float(lines.get_shader_parameter("cell_size")) \
			* int(lines.get_shader_parameter("wrap_cells"))
	t.check(is_equal_approx(period, float(tile.size.x)) and tile.size.x == tile.size.y,
			"the tile's side is the period its centroids repeat at (%.1f, %s)" % [period, tile.size])
	tile.free()

## Across a stretch of cells on both sides of the origin, wide enough to cross the tile's edge more
## than once: each cell's region lies inside the tile and is a ground cell's size, the cell beside
## it takes the texels beside it or wraps from the tile's far edge to its near one, and a cell a
## tile further on takes the same region.
func _test_cells_meet_without_a_seam(t: TestRunner) -> void:
	var tile := SouthWaterTile.new()
	var side := float(tile.size.x)
	var bounds := Rect2(Vector2.ZERO, Vector2(side, side))
	var period := tile.size.x / Tuning.TILE_SIZE
	var extent := Vector2(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
	var asked := 0
	var inside := true
	var east_meets := true
	var south_meets := true
	var repeats := true
	for y in range(-period - 2, period + 3):
		for x in range(-period - 2, period + 3):
			var cell := Vector2i(x, y)
			var region := tile.region_for(cell)
			asked += 1
			inside = inside and bounds.encloses(region) and region.size == extent
			var east := tile.region_for(cell + Vector2i.RIGHT)
			east_meets = east_meets and east.position.y == region.position.y \
					and (east.position.x == region.end.x
							or (region.end.x == side and east.position.x == 0.0))
			var south := tile.region_for(cell + Vector2i.DOWN)
			south_meets = south_meets and south.position.x == region.position.x \
					and (south.position.y == region.end.y
							or (region.end.y == side and south.position.y == 0.0))
			repeats = repeats and tile.region_for(cell + Vector2i(period, -period)) == region
	t.check(asked > 4 * period * period, "there were cells to ask (%d)" % asked)
	t.check(inside, "every cell's region lies inside the tile and is a ground cell's size")
	t.check(east_meets, "the cell to the east takes the texels to the east, wrapping at the edge")
	t.check(south_meets, "the cell to the south takes the texels to the south, wrapping at the edge")
	t.check(repeats, "a cell a whole tile away takes the same region")
	tile.free()
