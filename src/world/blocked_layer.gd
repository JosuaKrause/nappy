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
var posts := {}
## Tile -> true for today's closed ground (`CityMap.close_streets()`, the fenced park).
var closed := {}
## Tile -> true where a soft seal's body shuts the pavement to walkers today.
var soft_sealed := {}
## Tile -> how many stationary solid bodies stand on it.
var bodies := {}
## Owner id -> the tiles it recorded, so `release()` gives exactly those back.
var _owners := {}
## Bumped whenever a tile enters or leaves `bodies` — a version a reader only compares with the one
## its own answer was built from (the red arrow's sweeps, a figure's walk to her). Not bumped when a
## second body is counted onto a tile already standing.
var body_version := 0

## Whether anything on this record of `layers` (a `Mover`'s `blocked_by`, or part of it) stands on
## `tile`. The ground's own type is the map's question (`CityMap.passable()`).
func blocks(tile: Vector2i, layers: int) -> bool:
	return (layers & Mover.POSTS != 0 and posts.has(tile)) \
			or (layers & Mover.CLOSED != 0 and closed.has(tile)) \
			or (layers & Mover.SOFT_SEALS != 0 and soft_sealed.has(tile)) \
			or (layers & Mover.BODIES != 0 and bodies.has(tile))

## Writes `value` into `ground` (a flat grid `width` wide and `height` deep, indexed
## `y * width + x`) at every tile this record holds in `layers`: how a flood lays the record out once
## rather than asking it per neighbour.
func lay_out(ground: PackedInt32Array, width: int, height: int, layers: int,
		value: int) -> void:
	var records: Array[Dictionary] = []
	if layers & Mover.POSTS != 0:
		records.append(posts)
	if layers & Mover.CLOSED != 0:
		records.append(closed)
	if layers & Mover.SOFT_SEALS != 0:
		records.append(soft_sealed)
	if layers & Mover.BODIES != 0:
		records.append(bodies)
	for layer in records:
		for tile: Vector2i in layer:
			if tile.x >= 0 and tile.y >= 0 and tile.x < width and tile.y < height:
				ground[tile.y * width + tile.x] = value

## Every tile this record holds in `layers`, as one set: what a flood over another grid
## (`ReachabilityGrid`) is handed as its blocked tiles.
func tiles_of(layers: int) -> Dictionary:
	var found := {}
	if layers & Mover.POSTS != 0:
		found.merge(posts)
	if layers & Mover.CLOSED != 0:
		found.merge(closed)
	if layers & Mover.SOFT_SEALS != 0:
		found.merge(soft_sealed)
	if layers & Mover.BODIES != 0:
		for tile: Vector2i in bodies:
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
		if not bodies.has(tile):
			body_version += 1
		bodies[tile] = int(bodies.get(tile, 0)) + 1
	_owners[owner] = tiles

## Gives one body's tiles back. An unknown owner is a no-op, so every way a body can stop existing
## may call this without checking first.
func release(owner: int) -> void:
	if not _owners.has(owner):
		return
	var tiles: Array[Vector2i] = _owners[owner]
	for tile in tiles:
		var left := int(bodies.get(tile, 0)) - 1
		if left > 0:
			bodies[tile] = left
		else:
			bodies.erase(tile)
			body_version += 1
	_owners.erase(owner)

## Clears every body, at the start of a day.
func clear_bodies() -> void:
	bodies.clear()
	_owners.clear()
	body_version += 1
