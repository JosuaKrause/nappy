class_name BuildingShadows
extends Node2D
## The one-tile shadow every building casts to its south and west, from a light standing to the
## north-east. See `docs/CITY.md`, "Carving is rect subtraction", and `docs/DECISIONS.md`, M122,
## for the reading of the player's shape and why the north-western corner is square.
##
## **The union of every building's own footprint tiles is the only surface asked about — never one
## building at a time.** A tile outside that union is fully shaded when the tile to its north-east
## lies inside it, and it is a corner triangle, cut on the diagonal from its own north-east corner
## to its south-west corner with the building-side (upper-left) half filled, when the tile to its
## north lies inside the union and the tile to its north-east does not. Nothing else is drawn. Two
## buildings that share an edge merge into one union with nothing asked about which building either
## tile belongs to, which is what keeps a shared seam undrawn without a special case for it, and
## what makes an alley beside a building carry that building's own band down its length.
##
## Placed between `Ground` and `Buildings` in `city.tscn`, so it never sorts against anything and
## always lies flat under the crowd, the player and every event, the way a seal's own body shadow
## does — see `EventInstance._draw_body_shadow()`. Computed once by `City.build()`, since building
## footprints are fixed for the run (`docs/DECISIONS.md`, M61); nothing here changes per day or
## per frame.
##
## **Drawn in chunks, because a `CanvasItem`'s draw list is culled as one item by its own rect.**
## The whole city's shadow set is nearly two thousand commands, and the visible world holds a
## couple of hundred tiles — so one item covering the map submits every off-screen command of it,
## every frame, and no per-command culling reaches inside. This node draws nothing itself; it holds
## one child `CanvasItem` per `CHUNK_TILES`-square patch of city that has any shadow in it, and the
## renderer's own rect culling drops the ones that are not on screen. The picture is identical
## because the drawing is: each chunk runs the same `draw_rect`/`draw_colored_polygon` pair over
## its own share of the same tile sets, in world coordinates.

const TILE := float(Tuning.TILE_SIZE)

## How many tiles square one chunk is. 512px against a 640x360 visible world at zoom 2 means a
## handful of chunks are on screen at once, which is the number that matters: smaller chunks cull
## tighter but add items for the renderer to walk over the whole map, larger ones drag more
## off-screen commands on screen with them. The city is about 160 tiles square, so this is a
## hundred chunks of which a hundred minus a handful cost nothing per frame.
const CHUNK_TILES := 16

## One shadow tile set: tiles fully covered, and tiles cut on the diagonal from their north-east
## corner to their south-west corner with the upper-left half filled.
class Tiles extends RefCounted:
	var full: Array[Vector2i] = []
	var triangles: Array[Vector2i] = []

var _tiles := Tiles.new()

## `DevFlags.skip_shadows()`, read once when this node is built — the same "read once" shape
## `main._debug` and `main._readout_requested` are: `BuildingShadows` is computed once by
## `City.build()` and never changes per day or per frame, so re-parsing `--skip`'s comma list on
## every chunk's own `_draw_chunk()` would be silly work repeated for an answer that was already
## settled before the first frame, and a test can set this directly to check the skip without a
## real `--skip` flag behind it.
var _skip_draw := DevFlags.skip_shadows()

## Builds the shadow tile sets from `rects` — a city's building footprints, in tile coordinates
## (`CityMap.building_rects`) — and rebuilds the chunks that draw them.
func set_buildings(rects: Array[Rect2i]) -> void:
	_tiles = compute(rects)
	_rebuild_chunks()

## The one `CanvasItem` per occupied chunk that the culling works on. Freed and rebuilt whole rather
## than updated, since `set_buildings()` is called once per run with a fixed footprint set and the
## alternative is bookkeeping for a case that never happens.
##
## A chunk is a plain `Node2D` with its `draw` signal connected to a closure over its own two tile
## lists — the shape `EntityHalo` already uses to give a node a `_draw()` without a script of its
## own. The tiles keep their world coordinates and every chunk sits at the origin, so the drawing
## below is the same arithmetic it was when one item held all of it.
func _rebuild_chunks() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	var by_chunk := split(_tiles)
	for key in by_chunk:
		var tiles: Tiles = by_chunk[key]
		var chunk := Node2D.new()
		chunk.name = "Chunk%d_%d" % [key.x, key.y]
		chunk.draw.connect(_draw_chunk.bind(chunk, tiles))
		add_child(chunk)

## `tiles` dealt out into one `Tiles` per occupied chunk, keyed by the chunk's own coordinates —
## pulled out of `_rebuild_chunks()` for the same reason `compute()` is pulled out of
## `set_buildings()`: `tests/test_building_shadows.gd` can then hold the one property the split has
## to have, that it is a **partition** of what `compute()` produced and not a filter of it. A tile
## dropped here is a shadow that silently stops being drawn, and nothing else in the frame would
## say so.
##
## `floori` rather than integer division, which truncates toward zero and would fold the two chunks
## either side of an axis into one. The map's own tile coordinates are never negative today and
## nothing here depends on that.
static func split(tiles: Tiles) -> Dictionary:
	var by_chunk := {}
	for tile in tiles.full:
		_chunk_for(by_chunk, tile).full.append(tile)
	for tile in tiles.triangles:
		_chunk_for(by_chunk, tile).triangles.append(tile)
	return by_chunk

static func _chunk_for(by_chunk: Dictionary, tile: Vector2i) -> Tiles:
	var key := Vector2i(floori(float(tile.x) / CHUNK_TILES), floori(float(tile.y) / CHUNK_TILES))
	if not by_chunk.has(key):
		by_chunk[key] = Tiles.new()
	var chunk: Tiles = by_chunk[key]
	return chunk

## The geometry, pulled out of `set_buildings()` so `tests/test_building_shadows.gd` can assert the
## tile sets directly without building a scene. Tile `y` increases downward, the same convention
## `CityMap` uses everywhere else, so "north" is `-y` and a light from the north-east casts toward
## the south-west: a `(1, -1)` step off a shaded tile lands back on the building that casts it.
##
## Runs off the occupied tiles rather than scanning the map: every tile satisfying either rule has
## an occupied neighbour by definition, so offsetting from each occupied tile finds every shaded
## tile without a pass over ground that holds none.
static func compute(rects: Array[Rect2i]) -> Tiles:
	var occupied := {}
	for rect in rects:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				occupied[Vector2i(x, y)] = true
	var tiles := Tiles.new()
	var seen_full := {}
	var seen_triangle := {}
	for tile in occupied:
		# `tile` is the north-east neighbour of the candidate full-shade tile at `tile + (-1, 1)`.
		var full_candidate: Vector2i = tile + Vector2i(-1, 1)
		if not occupied.has(full_candidate) and not seen_full.has(full_candidate):
			seen_full[full_candidate] = true
			tiles.full.append(full_candidate)
		# `tile` is the north neighbour of the candidate triangle at `tile + (0, 1)` — a triangle
		# only where that candidate's own north-east neighbour is not also occupied, or it would be
		# a full-shade tile instead.
		var triangle_candidate: Vector2i = tile + Vector2i(0, 1)
		if occupied.has(triangle_candidate):
			continue
		var triangle_ne: Vector2i = triangle_candidate + Vector2i(1, -1)
		if not occupied.has(triangle_ne) and not seen_triangle.has(triangle_candidate):
			seen_triangle[triangle_candidate] = true
			tiles.triangles.append(triangle_candidate)
	return tiles

func _draw_chunk(canvas: CanvasItem, tiles: Tiles) -> void:
	# `--skip shadows`'s own probe (docs/DECISIONS.md, M124, "the desktop half", row (c)): no chunk
	# draws anything, so a frame under the flag differs from an ordinary one by drawing alone.
	if _skip_draw:
		return
	var colour := Color(Palette.SHADOW.r, Palette.SHADOW.g, Palette.SHADOW.b,
			Tuning.BUILDING_SHADOW_ALPHA)
	for tile in tiles.full:
		canvas.draw_rect(Rect2(Vector2(tile) * TILE, Vector2.ONE * TILE), colour)
	for tile in tiles.triangles:
		var origin := Vector2(tile) * TILE
		# North-west, north-east, south-west: the half of the tile on the building's own side of
		# the north-east-to-south-west cut, which is why the whole top edge — the edge shared with
		# the building to the north — is one side of this triangle rather than split by it.
		canvas.draw_colored_polygon(PackedVector2Array([
			origin,
			origin + Vector2(TILE, 0.0),
			origin + Vector2(0.0, TILE),
		]), colour)
