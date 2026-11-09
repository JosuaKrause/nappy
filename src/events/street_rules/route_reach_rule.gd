class_name RouteReachRule
extends StreetRule
## **A body never cuts the day's routes off from home**: a candidate that obstructs (a body she
## cannot pass, or a hard fail, `EventScheduler.Planned.obstructs()`) and stands on ground she can
## reach from home is asked whether, among everything that already obstructs, it leaves every tile
## a route runs along (`Corridor.carries_a_route()`) that home reached without it still reached,
## but those it stands on. A body off the routes is asked too: the last of a ring that seals home
## in may stand beside a route the ring's first body already crossed. The day's routes run from
## home to the calm and to the day's narrow resistance target, so a day keeps them reachable by
## construction: the line rules (`RouteJunctionsRule`, `RouteSidewalkRule`) see a row that charges
## her to pass, this one a body that charges nothing and still stops her (a barricade the run left,
## a silent van).
##
## **One per day or per walk, handed to every judge of it** (`StreetInvalidation`), since what it
## holds is derived once and kept in step: the ground home reaches among the bodies it has been
## shown, tile by tile, over the city's own 4-connected walkable tiles (`CityMap.passable()` for the
## lattice walker, the graph `ReachabilityGrid` contracts). A body shown it that the ground round
## its disc goes round takes only its disc off the reach; one it does not floods from home again.
## A body that leaves (spent, or no longer handed in) is kept blocking until the day is over: taking
## a body away can only add reach, so keeping it can refuse a candidate that would have been fine but
## never lets one cut a route off, and it spares the walk a flood each time something leaves.
## Model: no node.

## How far round a disc the ground is walked to find it still one piece.
const ROUND_MARGIN := 3
const STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _map: CityMap
var _corridor: Corridor
var _size := Vector2i.ZERO
## Per tile (`y * width + x`): 1 where the lattice walker may stand, before the day puts anything down.
var _open := PackedByteArray()
## Per tile: 1 where today's closures or a body shown the rule stand.
var _blocked := PackedByteArray()
## Per tile: 1 where she can walk from home among `_blocked`.
var _reached := PackedByteArray()
## The bodies the reach is worked out among, by instance id.
var _seen := {}
var _ready := false

## The rule on `map` for the routes `corridor` runs, asking nothing where there is no corridor.
## Nothing is worked out until a body is first asked about.
func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> bool:
	if _corridor == null or not candidate.obstructs():
		return true
	_catch_up(around, candidate)
	var disc := _disc_of(candidate)
	if not _touches(disc) or _goes_round(disc):
		return true
	var after := _flood(disc)
	for i in _reached.size():
		if _reached[i] == 1 and after[i] == 0 and not disc.has(i) \
				and _corridor.carries_a_route(Vector2i(i % _size.x, i / _size.x)):
			return false
	return true

## Brings the reach up to `around`'s bodies (but `candidate`): a body not shown yet is folded in,
## and a body shown that `around` no longer holds sends the reach back to a flood from home.
func _catch_up(around: Array[EventScheduler.Planned], candidate: EventScheduler.Planned) -> void:
	var bodies: Array[EventScheduler.Planned] = []
	var fresh: Array[EventScheduler.Planned] = []
	for plan in around:
		if plan != candidate and plan.obstructs():
			bodies.append(plan)
			if not _seen.has(plan.get_instance_id()):
				fresh.append(plan)
	if not _ready:
		_rebuild(bodies)
		return
	for body in fresh:
		var disc := _disc_of(body)
		var goes_round := not _touches(disc) or _goes_round(disc)
		for i: int in disc:
			_blocked[i] = 1
		if goes_round:
			for i: int in disc:
				_reached[i] = 0
		else:
			_reached = _flood({})
		_seen[body.get_instance_id()] = true

func _rebuild(bodies: Array[EventScheduler.Planned]) -> void:
	if not _ready:
		_size = _map.world_to_tile(_map.world_size())
		_open.resize(_size.x * _size.y)
		var walker := Mover.lattice()
		for y in _size.y:
			for x in _size.x:
				_open[y * _size.x + x] = 1 if _map.passable(Vector2i(x, y), walker) else 0
		_ready = true
	_blocked = PackedByteArray()
	_blocked.resize(_size.x * _size.y)
	for tile: Vector2i in EventScheduler.blocked_by(_map, bodies):
		if _inside(tile):
			_blocked[_index(tile)] = 1
	_seen.clear()
	for body in bodies:
		_seen[body.get_instance_id()] = true
	_reached = _flood({})

## The tiles (by index) a body's disc covers.
func _disc_of(plan: EventScheduler.Planned) -> Dictionary:
	var tiles := {}
	EventScheduler.block_a_disc(_map, tiles, plan.placed_at(), plan.blocking_radius())
	var disc := {}
	for tile: Vector2i in tiles:
		if _inside(tile):
			disc[_index(tile)] = true
	return disc

func _touches(disc: Dictionary) -> bool:
	for i: int in disc:
		if _reached[i] == 1:
			return true
	return false

## **Whether the ground round `disc` stays one piece without it**: every reached tile beside the
## disc joins every other one within `ROUND_MARGIN` tiles of it, walking only open ground the disc
## leaves. Then any way from home that crossed the disc goes round it instead, so nothing home
## reached is cut off, and the city is not flooded again.
func _goes_round(disc: Dictionary) -> bool:
	if disc.has(_index(_map.home_tile())):
		return false
	var low := Vector2i(1 << 30, 1 << 30)
	var high := -low
	for i: int in disc:
		var at := Vector2i(i % _size.x, i / _size.x)
		low = Vector2i(mini(low.x, at.x), mini(low.y, at.y))
		high = Vector2i(maxi(high.x, at.x), maxi(high.y, at.y))
	var box := Rect2i(low - Vector2i.ONE * ROUND_MARGIN,
			high - low + Vector2i.ONE * (2 * ROUND_MARGIN + 1))
	var beside := {}
	for i: int in disc:
		var at := Vector2i(i % _size.x, i / _size.x)
		for step in STEPS:
			var next: Vector2i = at + step
			if _inside(next) and _reached[_index(next)] == 1 and not disc.has(_index(next)):
				beside[_index(next)] = true
	if beside.is_empty():
		return false
	var first: int = beside.keys()[0]
	var seen := {first: true}
	var queue: Array[int] = [first]
	var head := 0
	while head < queue.size():
		var at := Vector2i(queue[head] % _size.x, queue[head] / _size.x)
		head += 1
		for step in STEPS:
			var next: Vector2i = at + step
			if not box.has_point(next) or not _inside(next):
				continue
			var j := _index(next)
			if not seen.has(j) and _walkable(j) and not disc.has(j):
				seen[j] = true
				queue.append(j)
	for i: int in beside:
		if not seen.has(i):
			return false
	return true

## The tiles home reaches among `_blocked` and `disc` besides, as a per-tile array.
func _flood(disc: Dictionary) -> PackedByteArray:
	var reached := PackedByteArray()
	reached.resize(_size.x * _size.y)
	var home := _map.home_tile()
	if not _inside(home) or not _walkable(_index(home)) or disc.has(_index(home)):
		return reached
	var queue := PackedInt32Array([_index(home)])
	reached[_index(home)] = 1
	var head := 0
	var width := _size.x
	var count := reached.size()
	while head < queue.size():
		var i := queue[head]
		head += 1
		var x := i % width
		# The four sides in turn, written out: a packed array handed to a helper is a copy.
		for side in 4:
			var j := i
			if side == 0:
				if x == 0:
					continue
				j = i - 1
			elif side == 1:
				if x == width - 1:
					continue
				j = i + 1
			elif side == 2:
				j = i - width
			else:
				j = i + width
			if j < 0 or j >= count or reached[j] == 1 or _open[j] == 0 or _blocked[j] == 1 \
					or disc.has(j):
				continue
			reached[j] = 1
			queue.append(j)
	return reached

func _walkable(i: int) -> bool:
	return _open[i] == 1 and _blocked[i] == 0

func _inside(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < _size.x and tile.y < _size.y

func _index(tile: Vector2i) -> int:
	return tile.y * _size.x + tile.x
