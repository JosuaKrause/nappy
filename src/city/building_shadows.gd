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

const TILE := float(Tuning.TILE_SIZE)

## One shadow tile set: tiles fully covered, and tiles cut on the diagonal from their north-east
## corner to their south-west corner with the upper-left half filled.
class Tiles extends RefCounted:
	var full: Array[Vector2i] = []
	var triangles: Array[Vector2i] = []

var _tiles := Tiles.new()

## Builds the shadow tile sets from `rects` — a city's building footprints, in tile coordinates
## (`CityMap.building_rects`) — and redraws.
func set_buildings(rects: Array[Rect2i]) -> void:
	_tiles = compute(rects)
	queue_redraw()

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

func _draw() -> void:
	var colour := Color(Palette.SHADOW.r, Palette.SHADOW.g, Palette.SHADOW.b,
			Tuning.BUILDING_SHADOW_ALPHA)
	for tile in _tiles.full:
		draw_rect(Rect2(Vector2(tile) * TILE, Vector2.ONE * TILE), colour)
	for tile in _tiles.triangles:
		var origin := Vector2(tile) * TILE
		# North-west, north-east, south-west: the half of the tile on the building's own side of
		# the north-east-to-south-west cut, which is why the whole top edge — the edge shared with
		# the building to the north — is one side of this triangle rather than split by it.
		draw_colored_polygon(PackedVector2Array([
			origin,
			origin + Vector2(TILE, 0.0),
			origin + Vector2(0.0, TILE),
		]), colour)
