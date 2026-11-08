extends RefCounted
## M122, the shadow every building casts. The tile arithmetic over `CityMap.building_rects` is the
## shadows' own; this suite hands a `BuildingShadows` footprints and a recording drawer, as the city
## hands its real one, and reads which tiles each chunk is told to shade, rather than a built `City`
## scene — see the **writing-tests** skill, "test what a screenshot cannot see." The one realistic
## case reads the footprints of a generated map, from the cache of generated maps
## (`tests/city_map_cache.gd`); no city is built.

const MapCache := preload("res://tests/city_map_cache.gd")
const RecordingShadowDrawer := preload("res://tests/recording_shadow_drawer.gd")

func run(t) -> void:
	await _test_a_single_rectangle_casts_the_read_shape(t)
	await _test_two_edge_joined_buildings_shade_as_one_with_no_seam(t)
	await _test_a_disjoint_building_is_unaffected_by_a_neighbour(t)
	await _test_the_chunks_are_a_partition_of_the_tile_sets(t)
	await _test_a_chunk_holds_only_its_own_tiles(t)
	await _test_resident_geometry_matches_the_complete_union(t)

## What a non-streamed `BuildingShadows` over `rects` has every chunk draw once a frame has passed:
## `{"full": [...], "triangles": [...]}`, every chunk's tiles together, and `"chunks"`, each chunk's
## own entry as the recording drawer saw it.
func _drawn_over(t, rects: Array[Rect2i]) -> Dictionary:
	var drawer := RecordingShadowDrawer.new()
	var shadows := BuildingShadows.new()
	shadows.drawer = drawer
	shadows.set_buildings(rects)
	t.add_child(shadows)
	await t.get_tree().process_frame
	var full: Array[Vector2i] = []
	var triangles: Array[Vector2i] = []
	var chunks: Array[Dictionary] = []
	for entry in drawer.shown():
		full.append_array(entry.full)
		triangles.append_array(entry.triangles)
		chunks.append(entry)
	shadows.free()
	return {"full": full, "triangles": triangles, "chunks": chunks}

## Streamed shadows, each chunk's tiles worked out from the footprints near it alone, shade what the
## whole city's union shades, across every chunk seam. What each chunk shades is read off a
## recording drawer handed through the member the city hands its own through
## (`BuildingShadows.drawer`), once every chunk of the city is prepared (`update_view()`, which the
## residency calls) and drawn.
##
## Which tiles a shadow may fall on is asked through `BuildingShadows.falls_on`, the filter the city
## hands in for a task scene's stretch; here it lets every tile through and counts the tiles it is
## asked about. A tile is asked about only when shadow tiles are worked out, so streamed shadows
## handed their footprints ask about none until a view prepares a chunk.
func _test_resident_geometry_matches_the_complete_union(t) -> void:
	var map := MapCache.of(4242)
	var whole_drawn: Dictionary = await _drawn_over(t, map.building_rects)
	var expected := {}
	for entry: Dictionary in whole_drawn.chunks:
		var tiles: Array[Vector2i] = []
		tiles.append_array(entry.full)
		tiles.append_array(entry.triangles)
		if tiles.is_empty():
			continue
		var size := BuildingShadows.CHUNK_TILES
		expected[Vector2i(floori(float(tiles[0].x) / size), floori(float(tiles[0].y) / size))] = entry
	var drawer := RecordingShadowDrawer.new()
	var asked := [0]
	var shadows := BuildingShadows.new()
	shadows.drawer = drawer
	shadows.falls_on = func(_tile: Vector2i) -> bool:
		asked[0] += 1
		return true
	shadows.streamed = true
	shadows.set_buildings(map.building_rects)
	t.check(shadows.get_child_count() == 0 and asked[0] == 0,
			"streaming keeps footprint facts without working out or preparing distant shadows"
					+ " (%d tiles asked about)" % asked[0])
	t.add_child(shadows)
	var whole := Rect2(Vector2.ZERO, map.world_size()).grow(
			BuildingShadows.CHUNK_TILES * BuildingShadows.TILE)
	shadows.update_view(whole, whole)
	await t.get_tree().process_frame
	# Each drawn chunk's tiles, filed under the chunk the first of them falls in; a chunk with
	# nothing to shade is drawn with nothing.
	var drawn := {}
	var shading := 0
	for entry in drawer.shown():
		var tiles: Array[Vector2i] = []
		tiles.append_array(entry.full)
		tiles.append_array(entry.triangles)
		if tiles.is_empty():
			continue
		shading += 1
		var size := BuildingShadows.CHUNK_TILES
		var key := Vector2i(floori(float(tiles[0].x) / size), floori(float(tiles[0].y) / size))
		drawn[key] = entry
	t.check(shading == expected.size() and drawn.size() == expected.size(),
			"every chunk the union shades is drawn once (%d drawn, %d expected)"
					% [shading, expected.size()])
	for key: Vector2i in expected:
		var whole_tiles: Dictionary = expected[key]
		t.check(drawn.has(key), "the chunk %s the union shades is drawn" % key)
		if not drawn.has(key):
			continue
		var actual: Dictionary = drawn[key]
		t.check(_to_set(actual.full) == _to_set(whole_tiles.full),
				"streamed full shadows match the complete footprint union across chunk seams")
		t.check(_to_set(actual.triangles) == _to_set(whole_tiles.triangles),
				"streamed corner shadows match the complete footprint union across chunk seams")
	shadows.free()

## The exact reading of the shape the entry gives: a band along the bottom edge one tile past the
## western corner, a band up the western edge stopping one tile short of the top, and a triangle
## under the south-eastern corner alone — nothing at the top of the western band.
func _test_a_single_rectangle_casts_the_read_shape(t) -> void:
	var rect := Rect2i(5, 5, 3, 4) # columns 5..7, rows 5..8 (x0=5, x1=7, y0=5, y1=8)
	var tiles: Dictionary = await _drawn_over(t, [rect])
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
	var joined: Dictionary = await _drawn_over(t, [west, east])
	var solo: Dictionary = await _drawn_over(t, [Rect2i(5, 5, 6, 4)]) # the same 6-wide union, one rect
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
	var combined: Dictionary = await _drawn_over(t, [near, far])
	var near_alone: Dictionary = await _drawn_over(t, [near])
	var far_alone: Dictionary = await _drawn_over(t, [far])
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
	var drawn: Dictionary = await _drawn_over(t, _spread_out_buildings())
	var by_chunk: Array = drawn.chunks
	t.check(by_chunk.size() > 1,
			"the buildings were spread over more than one chunk (%d)" % by_chunk.size())
	# The partition is judged against the same footprints drawn as one chunk would hold them:
	# every tile appears once across the chunks, so the set is as large as the list of them.
	t.check(_to_set(drawn.full).size() == drawn.full.size(),
			"no full tile is drawn by more than one chunk (%d tiles)" % drawn.full.size())
	t.check(_to_set(drawn.triangles).size() == drawn.triangles.size(),
			"no corner triangle is drawn by more than one chunk (%d tiles)" % drawn.triangles.size())
	# And none is dropped: each building, drawn alone, shades tiles that are all among the whole's.
	var whole_full := _to_set(drawn.full)
	var whole_triangles := _to_set(drawn.triangles)
	for rect in _spread_out_buildings():
		var alone: Dictionary = await _drawn_over(t, [rect])
		for tile in alone.full:
			t.check(whole_full.has(tile), "%s, shaded by %s alone, is drawn in the whole" % [tile, rect])
		for tile in alone.triangles:
			t.check(whole_triangles.has(tile),
					"%s, a corner of %s alone, is drawn in the whole" % [tile, rect])

## Each chunk's tiles are the patch it actually covers, which is what makes the renderer's rect
## culling correct: a tile drawn by an item whose rect is somewhere else would come and go with the
## wrong patch of city.
func _test_a_chunk_holds_only_its_own_tiles(t) -> void:
	var drawn: Dictionary = await _drawn_over(t, _spread_out_buildings())
	var size := BuildingShadows.CHUNK_TILES
	var checked := 0
	for entry: Dictionary in drawn.chunks:
		var all: Array[Vector2i] = []
		all.append_array(entry.full)
		all.append_array(entry.triangles)
		if all.is_empty():
			continue
		var key := Vector2i(floori(float(all[0].x) / size), floori(float(all[0].y) / size))
		for tile in all:
			checked += 1
			t.check(Vector2i(floori(float(tile.x) / size), floori(float(tile.y) / size)) == key,
					"%s belongs to the chunk its neighbours are drawn by, %s" % [tile, key])
	t.check(checked > 0, "there were tiles to ask about (%d)" % checked)

func _to_set(tiles: Array[Vector2i]) -> Dictionary:
	var set := {}
	for tile in tiles:
		set[tile] = true
	return set
