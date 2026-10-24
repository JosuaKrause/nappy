class_name Navigator
extends RefCounted
## **The one way anything that walks or drives across a world moves**: each map builds one
## (`WorldMap.navigator()`), and it is handed to every mover by whoever builds it — the city to its
## event manager, its crowd and the resistance, the event manager to every figure it makes — rather
## than fetched. A step, a walk down a list of points, a way round and a way out are all asked of the
## map's one blocked record through the mover's own layers (`Mover`, `WorldMap.passable()`), so a cat,
## a bike, a pursuer, a departing dog, a man walking back to his van and the masked man on the
## building's stairs are all stopped by what stops her.
##
## **Every step is swept**: the tiles the whole step crosses are asked, not only the one it lands
## on, so a long frame cannot carry a chaser through a wall a tile thick. And it keeps the mover's
## body clear: the ground its radius reaches past where it would land, in the way it is going, has
## to be open too.
##
## A navigator over open ground (`open_ground()`, `WorldMap.open_ground()`) takes every step whole,
## sees every line clear and walks every way straight: what a data rig with no world walks on.

## How far, at most, past where a step lands the ground has to be open, whatever the mover's own
## radius: under half a tile, since every way between solids is a tile wide at least and a walk
## down its middle runs along tile centres, so a wider reach would stop a mover in the middle of a
## way it fits through.
const REACH_LIMIT := Tuning.TILE_SIZE * 0.5 - 1.0
## How many tiles a search for a way (`path()`, `way_out()`) looks at before it gives up: several
## times the tiles in her view, so it gives up only where solids leave no way at all.
const SEARCH_LIMIT := 4096

var _map: WorldMap

## A navigator over `map`, or over open ground where none is named.
func _init(map: WorldMap = null) -> void:
	_map = map if map else WorldMap.open_ground()

## A navigator over open ground: every step is taken whole and every line is clear.
static func open_ground() -> Navigator:
	return Navigator.new()

## The map this navigator walks.
func map() -> WorldMap:
	return _map

## Whether `mover` may stand on `tile` (`WorldMap.passable()`).
func passable(tile: Vector2i, mover: Mover) -> bool:
	return _map.passable(tile, mover)

## Whether `mover` may stand at the world point `at`.
func passable_at(at: Vector2, mover: Mover) -> bool:
	return _map.passable(_map.world_to_tile(at), mover)

## Whether the straight line from `from` to `to` crosses only ground `mover` may enter
## (`WorldMap.clear_line()`): the line a pursuer notices her along, lunges along and catches her
## along.
func clear_line(from: Vector2, to: Vector2, mover: Mover) -> bool:
	return _map.clear_line(from, to, mover)

## The ground a sweep over the whole map runs on for `mover` (`WorldMap.ground_for()`).
func ground(mover: Mover) -> PackedInt32Array:
	return _map.ground_for(mover)

# ---------------------------------------------------------------------- steps ---

## **The part of the step `delta` from `from` that `mover` takes**: the whole of it where the swept
## step is open; otherwise the larger of its two axis parts that is, then the smaller, so a mover
## meeting a wall slides along it rather than stopping dead; otherwise nothing. The whole step is
## answered as `delta` itself, so `position += step(...)` lands exactly where the unblocked step
## always did.
##
## **A mover standing on blocked ground may walk off it.** One placed on a day's solid — a figure
## sited on a tile a body later covered, a guard standing in his own band — is asked only about the
## ground's own type until it stands clear, and one inside the ground itself (which a placement
## never does) about nothing, so nothing the world put somewhere can be stuck there.
func step(from: Vector2, delta: Vector2, mover: Mover) -> Vector2:
	if not _map.has_ground() or delta.is_zero_approx():
		return delta
	if _sweep_is_clear(from, delta, mover):
		return delta
	var along_x := Vector2(delta.x, 0.0)
	var along_y := Vector2(0.0, delta.y)
	var first := along_x if absf(delta.x) >= absf(delta.y) else along_y
	var second := along_y if first == along_x else along_x
	for candidate: Vector2 in [first, second]:
		if not candidate.is_zero_approx() and _sweep_is_clear(from, candidate, mover):
			return candidate
	return Vector2.ZERO

## Where `mover` ends up going from `from` toward `to` in one step: `to` itself where the step is
## open (`step()`), else wherever the slide takes it.
func move_to(from: Vector2, to: Vector2, mover: Mover) -> Vector2:
	var wanted := to - from
	var taken := step(from, wanted, mover)
	return to if taken == wanted else from + taken

## Whether the whole step from `from` by `delta` is open to `mover`, its body's reach past the
## landing point included: see `step()`.
func _sweep_is_clear(from: Vector2, delta: Vector2, mover: Mover) -> bool:
	var start := _map.world_to_tile(from)
	var asked := mover
	if not _map.passable(start, mover):
		var built := Mover.new(mover.blocked_by & ~Mover.TODAY)
		if not _map.passable(start, built):
			return true
		asked = built
	var reach := minf(mover.radius, REACH_LIMIT)
	var to := from + delta
	if reach > 0.0:
		to += delta.normalized() * reach
	return _map.step_is_clear(from, to, asked)

# ---------------------------------------------------------------------- walks ---

## What one walk down a list of points did (`walk()`).
class Walked:
	extends RefCounted
	## Where the walker stands at the end of it.
	var at := Vector2.ZERO
	## The points not yet reached, in order.
	var points := PackedVector2Array()
	## The way it was last walking toward a point it did not reach, or zero where every step reached
	## its point.
	var heading := Vector2.ZERO
	## The way it was last walking toward any point, reached or not, or zero where it walked toward
	## none.
	var toward := Vector2.ZERO
	## How far it went.
	var travelled := 0.0
	## How much of the distance it was given is left: the points ran out first, or it was stopped.
	var left := 0.0
	## Whether a solid stopped it short of a point with nothing at all taken.
	var stopped := false

## **Walks `distance` px down `points` from `from`**, dropping each point as it is reached, each
## step through `step()`. A step a solid shortens slides and ends the walk for this frame; one it
## refuses whole ends it with `stopped` set, and the caller decides whether to find another way.
func walk(from: Vector2, points: PackedVector2Array, distance: float,
		mover: Mover) -> Walked:
	var walked := Walked.new()
	walked.at = from
	walked.left = distance
	while walked.left > 0.0 and not points.is_empty():
		var toward := points[0] - walked.at
		var length := toward.length()
		if length > 0.001:
			walked.toward = toward / length
		if length > walked.left:
			var heading := toward.normalized()
			var wanted := heading * walked.left
			var taken := step(walked.at, wanted, mover)
			walked.heading = heading
			if taken == wanted:
				walked.at += wanted
				walked.travelled += walked.left
				walked.left = 0.0
				break
			_walked_short(walked, taken)
			break
		var taken := step(walked.at, toward, mover)
		if taken != toward:
			walked.heading = toward.normalized() if length > 0.0 else walked.heading
			_walked_short(walked, taken)
			break
		walked.at = points[0]
		walked.left -= length
		walked.travelled += length
		points.remove_at(0)
	walked.points = points
	return walked

## A walk a solid cut short at `taken`: it slides as far as that, and is over for this frame.
func _walked_short(walked: Walked, taken: Vector2) -> void:
	if taken.is_zero_approx():
		walked.stopped = true
		return
	walked.at += taken
	walked.travelled += taken.length()
	walked.left = 0.0

## **A way from `from` to `to` round whatever stands between**: tile centres from the tile after
## `from`'s to the tile before `to`'s, then `to` itself, by a breadth-first search over the tiles
## `mover` may stand on, square steps only, so each leg stays on the two tiles it joins, never
## entering a tile of `avoid`. Empty when `to`'s tile is not reached within `SEARCH_LIMIT` tiles,
## and just `to` when the two share a tile.
##
## **`near` above zero ends it beside `to`** rather than on it: at the first tile whose centre is
## within `near` of `to`, that tile's centre last and `to` left out — the way up to somebody whose
## own body takes the ground they stand on, which no way can end on.
func path(from: Vector2, to: Vector2, mover: Mover, avoid := Rect2i(),
		near := 0.0) -> PackedVector2Array:
	if not _map.has_ground():
		return PackedVector2Array([to])
	var goal := _map.world_to_tile(to)
	var found := _search(_map.world_to_tile(from), mover, avoid,
			func(tile: Vector2i) -> bool: return tile == goal \
					or (near > 0.0 and _map.tile_to_world(tile).distance_to(to) <= near))
	if found.is_empty():
		return found
	if _map.world_to_tile(found[found.size() - 1]) == goal:
		found[found.size() - 1] = to
	return found

## **A way out of her sight**: tile centres from `from`'s tile to the nearest tile `mover` may stand
## on more than `beyond` and a tile from `her`, by the same search as `path()`, never entering a tile
## of `avoid`. Empty when none is found within `SEARCH_LIMIT` tiles.
func way_out(from: Vector2, her: Vector2, beyond: float, mover: Mover,
		avoid := Rect2i()) -> PackedVector2Array:
	if not _map.has_ground():
		return PackedVector2Array()
	var far := beyond + Tuning.TILE_SIZE
	return _search(_map.world_to_tile(from), mover, avoid,
			func(tile: Vector2i) -> bool: return _map.tile_to_world(tile).distance_to(her) > far)

## The tile centres from `start` (not included) to the first tile `arrived` answers true for, by a
## breadth-first search over the tiles `mover` may stand on outside `avoid`; the start itself always
## counts as standing ground. Empty when none is found within `SEARCH_LIMIT` tiles, or when `start`
## is already one.
func _search(start: Vector2i, mover: Mover, avoid: Rect2i, arrived: Callable) -> PackedVector2Array:
	var came_from: Dictionary[Vector2i, Vector2i] = {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size() and head < SEARCH_LIMIT:
		var tile := queue[head]
		head += 1
		if arrived.call(tile):
			var way := PackedVector2Array()
			while tile != start:
				way.insert(0, _map.tile_to_world(tile))
				tile = came_from[tile]
			return way
		for offset: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next := tile + offset
			if not came_from.has(next) and _map.passable(next, mover) \
					and not avoid.has_point(next):
				came_from[next] = tile
				queue.append(next)
	return PackedVector2Array()

# --------------------------------------------------------------------- routes ---

## **A route cut to the ground `mover` can walk it on**, checked before it is accepted rather than
## found out by the walker: every leg kept whole while the swept step down it is open, and the first
## that is not cut at the farthest point it reaches, the rest dropped. Empty when the route's first
## point is not ground the mover may stand on.
func trim(route: PackedVector2Array, mover: Mover) -> PackedVector2Array:
	if route.is_empty() or not _map.has_ground():
		return route
	if not passable_at(route[0], mover):
		return PackedVector2Array()
	var kept := PackedVector2Array([route[0]])
	for i in range(1, route.size()):
		var from := kept[kept.size() - 1]
		var leg := route[i] - from
		if _sweep_is_clear(from, leg, mover):
			kept.append(route[i])
			continue
		var reach := _farthest_along(from, leg, mover)
		if reach > 0.0:
			kept.append(from + leg * reach)
		break
	return kept

## The largest share of `leg` from `from` whose swept step is open to `mover`, to within a
## pixel: a shorter step down the same line asks a prefix of the same ground, so the open share is
## one interval from zero and a halving search finds its end.
func _farthest_along(from: Vector2, leg: Vector2, mover: Mover) -> float:
	var low := 0.0
	var high := 1.0
	var length := leg.length()
	while (high - low) * length > 1.0:
		var middle := (low + high) * 0.5
		if _sweep_is_clear(from, leg * middle, mover):
			low = middle
		else:
			high = middle
	return low
