class_name BlockedLayer
extends RefCounted
## **One map's record of what stands on its ground today**, the half of "can this mover stand
## here" that is not the ground's own tile type: a precinct's posts, today's closures, the tiles a
## soft seal shuts to walkers, and the tiles under every stationary solid body. A map owns one
## (`CityMap.blocked`), and every question about walking — a step, a line, a flood, a placement —
## reads it through a `Mover`, which names the layers that stop it (`CityMap.passable()`).
##
## **A body is recorded from its footprint** (`Footprint.tiles()`), the same footprint that builds
## its physics body (`Footprint.body()`), so what stops her and what stops a figure are one solid
## read twice rather than two authored copies. The record counts bodies per tile rather than
## flagging tiles, because two bodies can overlap one tile and the first to go must not open ground
## the second still stands on; each body's tiles are kept under the owner id it was recorded with,
## so it gives exactly its own back.
##
## The ground's tile type is the map's own (`CityMap.tile_at()`), since only the map knows how a
## recipe's exterior or a stretch's void reads; this record holds what is put down on top of it.

## Tile -> true where a precinct's post stands.
var _posts := {}
## Tile -> true for today's closed ground (`CityMap.close_streets()`, the fenced park).
var _closed := {}
## Tile -> true where a soft seal's body shuts the pavement to walkers today.
var _soft_sealed := {}
## Tile -> how many stationary solid bodies stand on it.
var _bodies := {}
## Owner id -> the tiles it recorded, so `release()` gives exactly those back.
var _owners := {}
## Bumped whenever a tile enters or leaves `_bodies` — a version a reader only compares with the one
## its own answer was built from (the red arrow's sweeps, a figure's walk to her). Not bumped when a
## second body is counted onto a tile already standing.
var _body_version := 0

## The same record as one of its own, every tile and every body's owner carried, so a tile
## recorded or released on one record is not on the other (`CityMap.copy()`).
func copy() -> BlockedLayer:
	var twin := BlockedLayer.new()
	twin._posts = _posts.duplicate()
	twin._closed = _closed.duplicate()
	twin._soft_sealed = _soft_sealed.duplicate()
	twin._bodies = _bodies.duplicate()
	for owner: int in _owners:
		var tiles: Array[Vector2i] = _owners[owner]
		twin._owners[owner] = tiles.duplicate()
	twin._body_version = _body_version
	return twin

## Records the precinct's posts afresh: the tiles under `at`, replacing whatever was laid before
## (`CityMap.index_posts()`).
func lay_posts(at: Array[Vector2i]) -> void:
	_posts = {}
	for tile in at:
		_posts[tile] = true

## Today's closed ground as the record itself, tile -> true, not a copy: what a closure writes into
## and a flood reads (`CityMap.closed_tiles`).
func todays_closed_tiles() -> Dictionary:
	return _closed

## Lets go of today's closed ground and records `tiles` as the closed ground instead.
func replace_closed_tiles(tiles: Dictionary) -> void:
	_closed = tiles

## Today's soft-sealed pavement as the record itself, tile -> true (`CityMap.soft_sealed_tiles`).
func todays_soft_sealed_tiles() -> Dictionary:
	return _soft_sealed

## Lets go of today's soft-sealed pavement and records `tiles` instead.
func replace_soft_sealed_tiles(tiles: Dictionary) -> void:
	_soft_sealed = tiles

## The tiles under today's stationary solid bodies as the record itself, tile -> how many bodies
## stand on it (`CityMap.obstructed_tiles`).
func todays_body_tiles() -> Dictionary:
	return _bodies

## How many times a tile has entered or left the bodies' ground: a version a reader compares with
## the one its own answer was built from (`CityMap.obstruction_version`).
func body_ground_changes() -> int:
	return _body_version

## Whether anything on this record of `layers` (a `Mover`'s `blocked_by`, or part of it) stands on
## `tile`. The ground's own type is the map's question (`CityMap.passable()`).
func blocks(tile: Vector2i, layers: int) -> bool:
	return (layers & Mover.POSTS != 0 and _posts.has(tile)) \
			or (layers & Mover.CLOSED != 0 and _closed.has(tile)) \
			or (layers & Mover.SOFT_SEALS != 0 and _soft_sealed.has(tile)) \
			or (layers & Mover.BODIES != 0 and _bodies.has(tile))

## Writes `value` into `ground` (a flat grid `width` wide and `height` deep, indexed
## `y * width + x`) at every tile this record holds in `layers`: how a flood lays the record out once
## rather than asking it per neighbour.
func lay_out(ground: PackedInt32Array, width: int, height: int, layers: int,
		value: int) -> void:
	var records: Array[Dictionary] = []
	if layers & Mover.POSTS != 0:
		records.append(_posts)
	if layers & Mover.CLOSED != 0:
		records.append(_closed)
	if layers & Mover.SOFT_SEALS != 0:
		records.append(_soft_sealed)
	if layers & Mover.BODIES != 0:
		records.append(_bodies)
	for layer in records:
		for tile: Vector2i in layer:
			if tile.x >= 0 and tile.y >= 0 and tile.x < width and tile.y < height:
				ground[tile.y * width + tile.x] = value

## Every tile this record holds in `layers`, as one set: what a flood over another grid
## (`ReachabilityGrid`) is handed as its blocked tiles.
func tiles_of(layers: int) -> Dictionary:
	var found := {}
	if layers & Mover.POSTS != 0:
		found.merge(_posts)
	if layers & Mover.CLOSED != 0:
		found.merge(_closed)
	if layers & Mover.SOFT_SEALS != 0:
		found.merge(_soft_sealed)
	if layers & Mover.BODIES != 0:
		for tile: Vector2i in _bodies:
			found[tile] = true
	return found

# --------------------------------------------------------------------- bodies ---

## Records one body's tiles under `owner`, an `Object.get_instance_id()` the caller hands back
## later. Re-recording the same owner replaces its old tiles, so a body that moved or a plan
## recorded again on a second day cannot leave tiles behind.
func obstruct(owner: int, tiles: Array[Vector2i]) -> void:
	release(owner)
	if tiles.is_empty():
		return
	for tile in tiles:
		if not _bodies.has(tile):
			_body_version += 1
		_bodies[tile] = int(_bodies.get(tile, 0)) + 1
	_owners[owner] = tiles

## Gives one body's tiles back. An unknown owner is a no-op, so every way a body can stop existing
## may call this without checking first.
func release(owner: int) -> void:
	if not _owners.has(owner):
		return
	var tiles: Array[Vector2i] = _owners[owner]
	for tile in tiles:
		var left := int(_bodies.get(tile, 0)) - 1
		if left > 0:
			_bodies[tile] = left
		else:
			_bodies.erase(tile)
			_body_version += 1
	_owners.erase(owner)

## Clears every body, at the start of a day.
func clear_bodies() -> void:
	_bodies.clear()
	_owners.clear()
	_body_version += 1
