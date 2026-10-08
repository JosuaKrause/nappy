class_name ArrowField
extends RefCounted
## How far she has to walk to the places that answer a task, from every tile at once: the
## red arrow's measure of "closest" for a task several places answer
## (`ResistanceDirector.retarget_the_arrow()`). *(Inbox #561 in coral-bunny, the player:
## "closest here always means path closeness not crow closeness".)*
##
## **Built out from the targets, not out from her.** The places that answer a task stand still
## for the day — a mast, a roadblock, a man shouting who paces his own few tiles of sidewalk —
## and she does not, so one sweep out from the targets answers every tile she can stand on, and
## asking where she stands is a lookup rather than a walk. A sweep from several targets at once
## labels every tile with the target its wave reached first, so one field answers both "which is
## closest" and "how far" for that one; a field from a single target answers "how far is this
## one" wherever the closest is something else, which is what the arrow's hold needs.
##
## **The same walk the city's own fields take** (`CityMap.walk_field_from()`): 4-connected, a
## step costs one tile, over walkable tiles, with what blocks her today refused on top (the
## `ground` an `advance()` is handed) — the game has no weighted path cost. A target is reached
## when the sweep reaches a tile whose centre is within the target's touch reach plus one tile of
## where it stands (or of any point of the beat it paces), so "how far" is how far to where her
## touch would count.
##
## **Built a slice at a time** (`advance()`), because one whole sweep of a city's open ground is
## a long frame (`tests/probes/plush_moose_arrow_cost.gd` measures it). A field is only read
## once `done`; until then the arrow keeps reading the one it replaces.

const UNREACHED := -1
const BLOCKED := -2

## The key of each target, by label: an `EventInstance`'s instance id or a mast's id.
var keys: Array = []
## Where each key stood when the sweep started (`anchor_of()`), so a caller can tell whether the
## targets are still the ones this field measures.
var anchors := {}
## The two versions of what blocks her that this field was started under
## (`CityMap.day_record_version`, `CityMap.obstruction_version`).
var versions := Vector2i(-1, -1)
var done := false

var _targets: Array[Dictionary] = []
var _begun := false
var _width := 0
var _cells := 0
var _tiles: PackedByteArray
var _walkable: PackedByteArray
var _distance: PackedInt32Array
var _label: PackedInt32Array
var _queue: PackedInt32Array
var _head := 0
var _tail := 0

## Where `target` (`{key, at, reach, beat}`) counts as standing for `anchors`: the tile of the
## start of its beat when it paces one, which does not move as it walks it, or else its own tile.
static func anchor_of(map: CityMap, target: Dictionary) -> Vector2i:
	var beat: PackedVector2Array = target["beat"]
	return map.world_to_tile(beat[0] if not beat.is_empty() else target["at"])

## A sweep out from `targets`, each `{key, at, reach, beat}`: `at` where it stands, `reach` how far
## from it a touch counts, `beat` the path it paces (empty for one that stands still). Nothing is
## laid out or swept until `advance()`, so starting one costs a frame nothing.
static func start(map: CityMap, targets: Array[Dictionary],
		blocked_versions: Vector2i) -> ArrowField:
	var field := ArrowField.new()
	field.versions = blocked_versions
	field._targets = targets
	for target in targets:
		field.keys.append(target["key"])
		field.anchors[target["key"]] = anchor_of(map, target)
	return field

## Lays the field out on `ground` — every tile `UNREACHED`, or `BLOCKED` where she cannot walk
## today (`ResistanceDirector._ground_for_the_arrow()`) — and seeds the targets.
func _begin(map: CityMap, ground: PackedInt32Array) -> void:
	_begun = true
	_width = map.size.x
	_cells = map.size.x * map.size.y
	_tiles = map.tiles
	_walkable = CityMap.walkable_by_type()
	_distance = ground.duplicate()
	_label = PackedInt32Array()
	_label.resize(_cells)
	_label.fill(-1)
	_queue = PackedInt32Array()
	_queue.resize(_cells)
	for label in _targets.size():
		var target: Dictionary = _targets[label]
		var within: float = float(target["reach"]) + Tuning.TILE_SIZE
		var beat: PackedVector2Array = target["beat"]
		var points: Array[Vector2] = [target["at"]]
		for i in range(1, beat.size()):
			var from := beat[i - 1]
			var steps := maxi(1, ceili(from.distance_to(beat[i]) / Tuning.TILE_SIZE))
			for s in steps + 1:
				points.append(from.lerp(beat[i], float(s) / steps))
		for point in points:
			_seed_around(map, point, within, label)
	_targets = []

## Seeds every open tile whose centre is within `within` of `at` as at the target `label`.
func _seed_around(map: CityMap, at: Vector2, within: float, label: int) -> void:
	var centre := map.world_to_tile(at)
	var r := ceili(within / Tuning.TILE_SIZE)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var tile := centre + Vector2i(dx, dy)
			if not map.in_bounds(tile) or map.tile_to_world(tile).distance_to(at) > within:
				continue
			var index := tile.y * _width + tile.x
			if _distance[index] != UNREACHED or _walkable[_tiles[index]] == 0:
				continue
			_distance[index] = 0
			_label[index] = label
			_queue[_tail] = index
			_tail += 1

## Sweeps up to `budget` more tiles over `ground` (read on the first call only) and answers how
## much of `budget` it used; `done` once nothing is left. The first call only lays the field out
## and seeds it, and answers the whole budget used.
func advance(map: CityMap, ground: PackedInt32Array, budget: int) -> int:
	if not _begun:
		# Laying the field out and seeding it is a frame's work of its own, so it never shares one
		# with a slice of the sweep.
		_begin(map, ground)
		return budget
	var swept := 0
	var width := _width
	var cells := _cells
	var distance := _distance
	var labels := _label
	var queue := _queue
	var tiles := _tiles
	var walkable := _walkable
	var head := _head
	var tail := _tail
	# Each array held once, here, so writing to it never copies it: a packed array is copied on
	# write while a second reference to it stands.
	_distance = PackedInt32Array()
	_label = PackedInt32Array()
	_queue = PackedInt32Array()
	# Written out rather than looped over four offsets, and with no call per tile, as
	# `CityMap.walk_field_from()` is: the loop's own bounds test costs more than what it guards.
	# The row's own ends for left and right: a step off the left edge would land on the right end
	# of the row above.
	while head < tail and swept < budget:
		var index := queue[head]
		head += 1
		swept += 1
		var next_distance: int = distance[index] + 1
		var label: int = labels[index]
		var x := index % width
		var next := index - 1
		if x > 0 and distance[next] == UNREACHED and walkable[tiles[next]] == 1:
			distance[next] = next_distance
			labels[next] = label
			queue[tail] = next
			tail += 1
		next = index + 1
		if x < width - 1 and distance[next] == UNREACHED and walkable[tiles[next]] == 1:
			distance[next] = next_distance
			labels[next] = label
			queue[tail] = next
			tail += 1
		next = index - width
		if next >= 0 and distance[next] == UNREACHED and walkable[tiles[next]] == 1:
			distance[next] = next_distance
			labels[next] = label
			queue[tail] = next
			tail += 1
		next = index + width
		if next < cells and distance[next] == UNREACHED and walkable[tiles[next]] == 1:
			distance[next] = next_distance
			labels[next] = label
			queue[tail] = next
			tail += 1
	_distance = distance
	_label = labels
	_head = head
	_tail = tail
	if head >= tail:
		done = true
	else:
		# The queue is only needed while sweeping; a finished field keeps its answer alone.
		_queue = queue
	return swept

## How many tiles she walks from `tile` to the nearest target this field was swept from, or -1
## when none can be walked to. A tile a body or a closure covers — her centre pressed against a
## roadblock — answers through the best of its four neighbours, one step on.
func length_at(tile: Vector2i) -> int:
	var index := _best_index(tile)
	if index < 0:
		return -1
	return _distance[index] + (0 if index == _index_of(tile) else 1)

## The key of the target nearest `tile` on foot, or null when none can be walked to from it.
func nearest_at(tile: Vector2i) -> Variant:
	var index := _best_index(tile)
	return keys[_label[index]] if index >= 0 else null

func _index_of(tile: Vector2i) -> int:
	if tile.x < 0 or tile.y < 0 or tile.x >= _width or tile.y * _width + tile.x >= _cells:
		return -1
	return tile.y * _width + tile.x

## `tile`'s own index when the sweep reached it, else its reached neighbour nearest a target.
func _best_index(tile: Vector2i) -> int:
	var own := _index_of(tile)
	if own >= 0 and _distance[own] >= 0:
		return own
	var best := -1
	for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var index := _index_of(tile + step)
		if index >= 0 and _distance[index] >= 0 \
				and (best < 0 or _distance[index] < _distance[best]):
			best = index
	return best
