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
## does — see `EventInstance._draw_body_shadow()`. Building footprints are fixed for the run
## (`docs/DECISIONS.md`, M61), while each nearby chunk's shadow geometry is prepared on demand and
## freed beyond the scenery retention boundary. Returning chunks are reconstructed from the same
## footprints.
##
## **Drawn in chunks, because a `CanvasItem`'s draw list is culled as one item by its own rect.**
## A `CanvasItem`'s draw list is culled as one item by its own rect, with no per-command culling
## inside it. This node prepares a child `CanvasItem` for each nearby `CHUNK_TILES`-square area,
## including areas with no shadow tiles; renderer rect culling drops the ones outside the view.
## Distant children are freed and rebuilt from the fixed footprints when their areas return. Each
## child draws its share of the same tile geometry in world coordinates.

const TILE := float(Tuning.TILE_SIZE)

## Side length, in tiles, for a shadow chunk. At 16 tiles (512px), this sets the area prepared and
## culled as one item, while scenery residency determines how many such items exist nearby.
## Smaller chunks tighten culling but add renderer items; larger chunks include more off-screen
## shadow commands.
const CHUNK_TILES := 16

## One shadow tile set: tiles fully covered, and tiles cut on the diagonal from their north-east
## corner to their south-west corner with the upper-left half filled.
class Tiles extends RefCounted:
	var full: Array[Vector2i] = []
	var triangles: Array[Vector2i] = []

var _tiles := Tiles.new()
var streamed := false
var _by_chunk: Dictionary = {}
var _resident: Dictionary = {}
var _rects: Array[Rect2i] = []
## Which tiles a shadow may fall on, or empty for every tile. A task scene's stretch casts no shadow
## into its void (`City.build()`): a shadow is ground darkened, and the void has no ground.
var falls_on := Callable()

## `DevFlags.skip_shadows()`, read once when this node is built. The flag controls drawing, while
## shadow geometry is prepared per nearby chunk and reconstructed when a chunk returns. Reading
## the flag once avoids reparsing `--skip`'s comma list in each chunk's `_draw_chunk()`, and a test
## can set this directly to check the skip without a real `--skip` flag behind it.
var _skip_draw := DevFlags.skip_shadows()

## Stores `rects` — a city's building footprints, in tile coordinates
## (`CityMap.building_rects`) — as the source for shadow geometry. Non-streamed use also computes
## and builds all drawing chunks here; streamed use prepares nearby chunks on demand.
func set_buildings(rects: Array[Rect2i]) -> void:
	_rects = rects
	if streamed:
		return
	_tiles = _on_the_ground(compute(rects))
	_by_chunk = split(_tiles)
	if not streamed:
		_rebuild_chunks()

func update_view(load_view: Rect2, retained: Rect2, enqueue := Callable()) -> void:
	for key: Vector2i in _resident.keys():
		if not retained.intersects(_chunk_bounds(key)):
			(_resident[key] as Node2D).free()
			_resident.erase(key)
	var width := CHUNK_TILES * TILE
	var lo := Vector2i((load_view.position / width).floor())
	var hi := Vector2i((load_view.end / width).ceil())
	for y in range(lo.y, hi.y):
		for x in range(lo.x, hi.x):
			var key := Vector2i(x, y)
			if _resident.has(key):
				continue
			if enqueue.is_valid():
				enqueue.call(_chunk_bounds(key), _prepare_chunk.bind(key))
			else:
				_prepare_chunk(key)

func _prepare_chunk(key: Vector2i) -> void:
	var tiles := _tiles_for_chunk(key)
	var chunk := Node2D.new()
	chunk.draw.connect(_draw_chunk.bind(chunk, tiles))
	add_child(chunk)
	_resident[key] = chunk

func _tiles_for_chunk(key: Vector2i) -> Tiles:
	var area := Rect2i(key * CHUNK_TILES, Vector2i.ONE * CHUNK_TILES)
	var nearby: Array[Rect2i] = []
	for rect in _rects:
		if rect.intersects(area.grow(1)):
			nearby.append(rect.intersection(area.grow(1)))
	var tiles := _on_the_ground(compute(nearby))
	tiles.full = tiles.full.filter(func(tile: Vector2i): return area.has_point(tile))
	tiles.triangles = tiles.triangles.filter(func(tile: Vector2i): return area.has_point(tile))
	return tiles

## `tiles` less those `falls_on` refuses.
func _on_the_ground(tiles: Tiles) -> Tiles:
	if falls_on.is_valid():
		tiles.full = tiles.full.filter(falls_on)
		tiles.triangles = tiles.triangles.filter(falls_on)
	return tiles

func _chunk_bounds(key: Vector2i) -> Rect2:
	return Rect2(Vector2(key) * CHUNK_TILES * TILE, Vector2.ONE * CHUNK_TILES * TILE)

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
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_SCENERY)
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
