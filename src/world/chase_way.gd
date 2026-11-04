class_name ChaseWay
extends RefCounted
## **The way a walker follows toward somebody who may be a city away**, round the buildings between
## them: a `WalkField` sweep out from her over the ground a figure on foot can walk, kept fresh as she
## moves and read a step at a time (`Navigator.way_to()` makes one for a mover). Only day 13's task
## guard has one (`EventInstance.notice_her_at()`); every other pursuer starts within sight of her
## with a straight run at her and keeps the straight line the navigator's step slides along walls.
## *(curly-gecko, the player: "as long as he starts pursuing when you hit the task it's fine".)*
##
## **Where there is a clear line to her the walker goes straight at her**, exactly as without a way;
## only where a building stands between them does it follow the walk instead. The walk is a sweep out
## from her (`WalkField`, the red arrow's own sweep, a slice a frame), and the walker steps down it
## toward her, aiming at the farthest of the next few tiles it can see.

## How many tiles of a sweep one frame of the chase runs: under half a millisecond, half the red
## arrow's slice (`ResistanceDirector.ARROW_SWEEP_TILES_PER_TICK`), since this runs whenever she
## has moved on rather than only when the targets change. A sweep is adopted as soon as it has
## reached the walker's tile, so from close by it takes a frame or two.
const SWEEP_TILES_PER_FRAME := 500
## How far, in tiles either way, she walks from where the sweep began before another is begun,
## at the least: close to her a sweep is a frame or two, and a walk two tiles stale is a corner cut
## wrong.
const REFRESH_TILES := 2
## **And while the walker is far, a sweep is begun only once she has walked a quarter of its walk
## to her** from where the last began. Far off, every sweep is many frames, and one begun every two
## tiles of her walk kept a sweep under way on most frames of a chase she walked away from; a walk
## that is a quarter stale still takes the walker the right way round the buildings, and it is
## refreshed more often the nearer it comes.
const REFRESH_SHARE := 4
## How many tiles down the sweep the walker looks for the farthest it can see to aim at, so its walk
## cuts the corners the four-way tile walk takes rather than zig-zagging along it.
const LOOKAHEAD_TILES := 6

var _navigator: Navigator
var _map: WorldMap
## The layers the walker walks on, and the ones it sees along (a car's view leaves out street ground).
var _mover: Mover
var _sight: Mover

## The sweep followed (out from where she stood when it began), or null before the first one has
## reached the walker.
var _field: WalkField
## The ground `_field` was swept over, which is what the walk down it is asked against.
var _field_ground := PackedInt32Array()
## Her tile `_field` was swept from.
var _field_from := Vector2i(-1, -1)
## The sweep under way that will replace `_field`, its ground, and her tile it began from.
var _next: WalkField
var _next_ground := PackedInt32Array()
var _next_from := Vector2i(-1, -1)
## The ground laid out for the sweeps, and the state of what blocks her it was laid out for
## (`WorldMap.day_record_version`, `WorldMap.obstruction_version`).
var _ground_laid := PackedInt32Array()
var _ground_versions := Vector2i(-1, -1)
## The tiles down `_field` from the tile the walker stood on when it was walked (`_chain_from`), as
## world points, nearest first; walked again when it is on another tile or the sweep changes.
var _chain := PackedVector2Array()
var _chain_from := Vector2i(-1, -1)
var _chain_field: WalkField

## A way for `mover`, which sees along `sight`, over `navigator`'s map.
func _init(navigator: Navigator, mover: Mover, sight: Mover) -> void:
	_navigator = navigator
	_map = navigator.map()
	_mover = mover
	_sight = sight

## The sweep under way, or null: what a probe watches begin.
func sweep_under_way() -> WalkField:
	return _next

## Begins a fresh sweep out from `her` when she has walked on from where the last began or what
## blocks her has changed, runs a slice of the one under way, and adopts it the moment it has
## reached `from`'s tile. A sweep runs the walk out from her in rings, so every tile at most as far
## as the walker's is final once its is reached, and the walk down from its tile never asks one
## further out.
func keep_fresh(her_at: Vector2, from: Vector2) -> void:
	if her_at == Vector2.INF or not _map.has_ground():
		return
	var versions := Vector2i(_map.day_record_version, _map.obstruction_version)
	if _next == null:
		var her := _map.world_to_tile(her_at)
		var stale := REFRESH_TILES
		if _field != null:
			var his := _field.length_at(_map.world_to_tile(from))
			stale = maxi(stale, floori(float(his) / REFRESH_SHARE))
		var moved := absi(her.x - _field_from.x) >= stale \
				or absi(her.y - _field_from.y) >= stale
		if _field != null and not moved and _field.versions == versions:
			return
		var target: Array[Dictionary] = [{"key": 0, "at": her_at, "reach": 0.0,
				"beat": PackedVector2Array()}]
		_next = WalkField.start(_map, target, versions)
		_next_ground = _ground_for_the_way(versions)
		_next_from = her
		# Laying out the ground is a frame's work of its own, like the sweep's own layout.
		return
	_next.advance(_map, _next_ground, SWEEP_TILES_PER_FRAME)
	if _next.done or _next.length_at(_map.world_to_tile(from)) >= 0:
		_field = _next
		_field_ground = _next_ground
		_field_from = _next_from
		_next = null
		_next_ground = PackedInt32Array()

## The ground the sweeps run over, the walker's own as a figure on foot and the red arrow's
## (`Navigator.ground()`, `WalkField.ground_for()`): what she cannot walk right now is blocked —
## today's closures, the soft seals, the tile under every stationary body standing and a precinct's
## posts. So where no clear line runs to her the walker goes round what she has to walk round, and a
## line through any of it is no clear line. Laid out once for each state of what blocks her.
func _ground_for_the_way(versions: Vector2i) -> PackedInt32Array:
	if versions == _ground_versions and not _ground_laid.is_empty():
		return _ground_laid
	_ground_laid = _navigator.ground(_mover)
	_ground_versions = versions
	return _ground_laid

## Which way the walker at `from` goes toward `her_at`: `straight` where it has a clear line to her
## or no sweep has reached it yet, else toward the farthest of the next `LOOKAHEAD_TILES` tiles down
## the walk that it can see along open ground (`_is_open()`), or the next one where it sees none.
func toward(from: Vector2, her_at: Vector2, straight: Vector2) -> Vector2:
	if _field == null or _navigator.clear_line(from, her_at, _sight):
		return straight
	var here := _map.world_to_tile(from)
	if here != _chain_from or _field != _chain_field:
		_chain = _down_the_way(here)
		_chain_from = here
		_chain_field = _field
	if _chain.is_empty():
		return straight
	var aim := _chain[0]
	for i in range(_chain.size() - 1, 0, -1):
		if _navigator.clear_line(from, _chain[i], _mover):
			aim = _chain[i]
			break
	var to_aim := aim - from
	return to_aim.normalized() if to_aim.length() >= 1.0 else straight

## Up to `LOOKAHEAD_TILES` tiles down `_field` from `from`, each the open neighbour one step
## nearer her, as tile centres: empty where `from` is no part of the walk or is already where the
## sweep began.
func _down_the_way(from: Vector2i) -> PackedVector2Array:
	var chain := PackedVector2Array()
	var tile := from
	var length := _field.length_at(tile)
	if length < 0:
		return chain
	for i in LOOKAHEAD_TILES:
		var best := tile
		var best_length := length
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + offset
			if not _is_open(next):
				continue
			var next_length := _field.length_at(next)
			if next_length >= 0 and next_length < best_length:
				best = next
				best_length = next_length
		if best == tile:
			break
		tile = best
		length = best_length
		chain.append(_map.tile_to_world(tile))
	return chain

## Whether `tile` is ground the walk may step onto: walkable, and not blocked in the ground
## `_field` was swept over. Asked before `WalkField.length_at()`, which answers a blocked tile
## through its neighbours and would otherwise lead the walker onto it.
func _is_open(tile: Vector2i) -> bool:
	if not _map.in_bounds(tile) or not _map.is_walkable(tile):
		return false
	return _field_ground[tile.y * _map.size.x + tile.x] != WalkField.BLOCKED
