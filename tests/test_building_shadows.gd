extends RefCounted
## M122, the shadow every building casts. `BuildingShadows.compute()` is pure tile arithmetic over
## `CityMap.building_rects`, so this suite asserts the tile sets directly rather than through a
## built `City` scene — see the **verify** skill, "test what a screenshot cannot see."

func run(t) -> void:
	_test_a_single_rectangle_casts_the_read_shape(t)
	_test_two_edge_joined_buildings_shade_as_one_with_no_seam(t)
	_test_a_disjoint_building_is_unaffected_by_a_neighbour(t)
	_test_the_chunks_are_a_partition_of_the_tile_sets(t)
	_test_a_chunk_holds_only_its_own_tiles(t)

## The exact reading of the shape the entry gives: a band along the bottom edge one tile past the
## western corner, a band up the western edge stopping one tile short of the top, and a triangle
## under the south-eastern corner alone — nothing at the top of the western band.
func _test_a_single_rectangle_casts_the_read_shape(t) -> void:
	var rect := Rect2i(5, 5, 3, 4) # columns 5..7, rows 5..8 (x0=5, x1=7, y0=5, y1=8)
	var tiles := BuildingShadows.compute([rect])
	var full := _to_set(tiles.full)
	var expected_bottom := [Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9)]
	for tile in expected_bottom:
		t.check(full.has(tile), "the bottom band shades %s, one tile past the western corner" % tile)
	var expected_west := [Vector2i(4, 6), Vector2i(4, 7), Vector2i(4, 8), Vector2i(4, 9)]
	for tile in expected_west:
		t.check(full.has(tile), "the western band shades %s" % tile)
	t.check(not full.has(Vector2i(7, 9)),
			"the bottom band stops one tile short of the eastern corner, where the triangle takes over")
	t.check(not full.has(Vector2i(4, 5)),
			"the western band stops one tile short of the top — no shadow at the top of the band")
	t.check(full.size() == expected_bottom.size() + expected_west.size() - 1,
			"the bottom and western bands meet at exactly one shared tile and nowhere else grows a full tile")
	var triangles := _to_set(tiles.triangles)
	t.check(triangles.size() == 1 and triangles.has(Vector2i(7, 9)),
			"only the tile under the south-eastern corner is a half-shaded triangle")

## Two buildings sharing a north-south edge — the second immediately east of the first, same rows —
## merge into one 6-wide union. The player's own contract: nothing is shaded where they touch, and
## the union shades as one rectangle rather than each building shading its neighbour's own wall.
func _test_two_edge_joined_buildings_shade_as_one_with_no_seam(t) -> void:
	var west := Rect2i(5, 5, 3, 4) # columns 5..7, so a lone west would put its own corner
			# triangle at (7, 9) — see `_test_a_single_rectangle_casts_the_read_shape`.
	var east := Rect2i(8, 5, 3, 4) # columns 8..10, sharing the seam at column 7/8
	var joined := BuildingShadows.compute([west, east])
	var solo := BuildingShadows.compute([Rect2i(5, 5, 6, 4)]) # the same 6-wide union, one rect
	t.check(_to_set(joined.full) == _to_set(solo.full),
			"two edge-joined buildings shade exactly as their merged union would")
	t.check(_to_set(joined.triangles) == _to_set(solo.triangles),
			"two edge-joined buildings put the corner triangle where the merged union would")
	# The seam itself never grows a shadow: `west`'s own corner triangle at (7, 9) is not a corner
	# once `east` continues the building past it, and joins the continuous bottom band instead.
	t.check(not _to_set(joined.triangles).has(Vector2i(7, 9)),
			"the join swallows west's own corner triangle rather than keeping it beside east's")
	t.check(_to_set(joined.full).has(Vector2i(7, 9)),
			"what was west's own corner triangle is now part of the merged union's continuous band")
	t.check(_to_set(joined.triangles).has(Vector2i(10, 9)),
			"the merged union's own corner triangle sits under its actual south-eastern corner")

## A building far from any other casts its own shadow untouched by a neighbour it does not touch —
## the two footprints' shadows are simply the union of what each would cast alone.
func _test_a_disjoint_building_is_unaffected_by_a_neighbour(t) -> void:
	var near := Rect2i(0, 0, 2, 2)
	var far := Rect2i(20, 20, 2, 2)
	var combined := BuildingShadows.compute([near, far])
	var near_alone := BuildingShadows.compute([near])
	var far_alone := BuildingShadows.compute([far])
	var expected_full := _to_set(near_alone.full)
	for tile in _to_set(far_alone.full):
		expected_full[tile] = true
	t.check(_to_set(combined.full) == expected_full,
			"two buildings that do not touch each shade exactly as they would alone")

# -------------------------------------------------------------------- the chunks ---
# The shadows are drawn by one `CanvasItem` per patch of city rather than one for the whole of it,
# so the renderer's own rect culling drops the off-screen ones — see `BuildingShadows`' class doc.
# The picture may not move a pixel for it, and what makes that true is that the split is a
# **partition**: every tile `compute()` produced is drawn by exactly one chunk, and none is drawn
# twice. A dropped tile is a shadow that silently stops being drawn and a duplicated one is a tile
# shaded twice over, and nothing else in a frame would report either.

## Buildings scattered far enough apart to land in several chunks, and one straddling a chunk
## boundary so the split is actually exercised rather than handed a set that fits in one.
func _spread_out_buildings() -> Array[Rect2i]:
	return [
		Rect2i(1, 1, 4, 4),
		Rect2i(BuildingShadows.CHUNK_TILES - 2, 3, 5, 3), # straddles the first vertical boundary
		Rect2i(3, BuildingShadows.CHUNK_TILES * 2 + 1, 6, 4),
		Rect2i(BuildingShadows.CHUNK_TILES * 3, BuildingShadows.CHUNK_TILES * 3, 7, 7),
	]

func _test_the_chunks_are_a_partition_of_the_tile_sets(t) -> void:
	var tiles := BuildingShadows.compute(_spread_out_buildings())
	var by_chunk := BuildingShadows.split(tiles)
	t.check(by_chunk.size() > 1,
			"the buildings were spread over more than one chunk (%d)" % by_chunk.size())
	var full: Array[Vector2i] = []
	var triangles: Array[Vector2i] = []
	for key in by_chunk:
		var chunk: BuildingShadows.Tiles = by_chunk[key]
		full.append_array(chunk.full)
		triangles.append_array(chunk.triangles)
	t.check(full.size() == tiles.full.size(),
			"the chunks hold every full tile exactly once (%d of %d)" % [full.size(), tiles.full.size()])
	t.check(triangles.size() == tiles.triangles.size(),
			"the chunks hold every corner triangle exactly once (%d of %d)"
					% [triangles.size(), tiles.triangles.size()])
	t.check(_to_set(full) == _to_set(tiles.full),
			"and they are the same full tiles, not a different set of the same size")
	t.check(_to_set(triangles) == _to_set(tiles.triangles),
			"and the same corner triangles")

## Each chunk's key is the patch its tiles actually fall in, which is what makes the renderer's rect
## culling correct: a tile filed under a neighbour's key would be drawn by an item whose rect is
## somewhere else, so it would come and go with the wrong patch of city.
func _test_a_chunk_holds_only_its_own_tiles(t) -> void:
	var by_chunk := BuildingShadows.split(BuildingShadows.compute(_spread_out_buildings()))
	var size := BuildingShadows.CHUNK_TILES
	var checked := 0
	for key in by_chunk:
		var chunk: BuildingShadows.Tiles = by_chunk[key]
		var all: Array[Vector2i] = []
		all.append_array(chunk.full)
		all.append_array(chunk.triangles)
		for tile in all:
			checked += 1
			t.check(Vector2i(floori(float(tile.x) / size), floori(float(tile.y) / size)) == key,
					"%s belongs to chunk %s" % [tile, key])
	t.check(checked > 0, "there were tiles to ask about (%d)" % checked)

func _to_set(tiles: Array[Vector2i]) -> Dictionary:
	var set := {}
	for tile in tiles:
		set[tile] = true
	return set
