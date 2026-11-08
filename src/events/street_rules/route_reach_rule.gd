class_name RouteReachRule
extends StreetRule
## **A body never cuts the day's routes off from home**: a candidate that obstructs (a body she
## cannot pass, or a hard fail, `EventScheduler.Planned.obstructs()`) whose disc reaches ground a
## route runs along (`Corridor.carries_a_route()`) is asked whether, standing among everything that
## already obstructs, it leaves every route tile home reached without it still reached, but those it
## stands on. The day's routes run from home to the calm and to the day's narrow resistance target,
## so a day keeps them reachable by construction: the line rules (`RouteJunctionsRule`,
## `RouteSidewalkRule`) see a row that charges her to pass, this one a body that charges nothing and
## still stops her (a barricade the run left, a silent van). Model: no node.

var _map: CityMap
var _corridor: Corridor
var _grid: ReachabilityGrid = null
const ROUND_MARGIN := 3
const STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _route_tiles: Array[Vector2i] = []
var _walker := Mover.lattice()
var _key := 0
var _blocked := {}
var _reached = null

## The rule on `map` for the routes `corridor` runs, or none where there is no corridor.
func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor
	if corridor == null:
		return
	_grid = ReachabilityGrid.build(map)
	var size := map.world_to_tile(map.world_size())
	for y in size.y:
		for x in size.x:
			var tile := Vector2i(x, y)
			if map.is_walkable(tile) and corridor.carries_a_route(tile):
				_route_tiles.append(tile)

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> bool:
	if _grid == null or not candidate.obstructs():
		return true
	var bodies: Array[EventScheduler.Planned] = []
	for plan in around:
		if plan != candidate and plan.obstructs():
			bodies.append(plan)
	_catch_up(bodies)
	var disc := {}
	EventScheduler.block_a_disc(_map, disc, candidate.position, candidate.blocking_radius())
	var touches := false
	for at: Vector2i in disc:
		if _grid.reaches(at, _blocked, _reached):
			touches = true
			break
	if not touches or _goes_round(disc):
		return true
	var after := _blocked.duplicate()
	after.merge(disc)
	var reached_after := _grid.flood([_map.home_tile()], after)
	for at in _route_tiles:
		if after.has(at):
			continue
		if _grid.reaches(at, _blocked, _reached) and not _grid.reaches(at, after, reached_after):
			return false
	return true

## **Whether the ground round `disc` stays one piece without it**: every reached tile beside the
## disc joins every other one within `ROUND_MARGIN` tiles of it, walking only open ground the disc
## leaves. Then any way from home that crossed the disc goes round it instead, so nothing home
## reached is cut off, and the whole city is not flooded again. Sound because the walk here is the
## grid's own 4-connected tiles (`CityMap.passable()` for the lattice walker), never more.
func _goes_round(disc: Dictionary) -> bool:
	if disc.has(_map.home_tile()):
		return false
	var low := Vector2i(1 << 30, 1 << 30)
	var high := -low
	for at: Vector2i in disc:
		low = Vector2i(mini(low.x, at.x), mini(low.y, at.y))
		high = Vector2i(maxi(high.x, at.x), maxi(high.y, at.y))
	var box := Rect2i(low - Vector2i.ONE * ROUND_MARGIN,
			high - low + Vector2i.ONE * (2 * ROUND_MARGIN + 1))
	var beside: Array[Vector2i] = []
	for at: Vector2i in disc:
		for step in STEPS:
			var next: Vector2i = at + step
			if not disc.has(next) and not beside.has(next) and _open(next, disc) \
					and _grid.reaches(next, _blocked, _reached):
				beside.append(next)
	if beside.is_empty():
		return false
	var seen := {beside[0]: true}
	var queue: Array[Vector2i] = [beside[0]]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for step in STEPS:
			var next: Vector2i = at + step
			if box.has_point(next) and not seen.has(next) and _open(next, disc):
				seen[next] = true
				queue.append(next)
	for at in beside:
		if not seen.has(at):
			return false
	return true

## Whether she may stand on `tile` with `disc` down as well as everything already blocked.
func _open(tile: Vector2i, disc: Dictionary) -> bool:
	return not disc.has(tile) and not _blocked.has(tile) and _map.in_bounds(tile) \
			and _map.passable(tile, _walker)

## Floods from home among `bodies`, once for each set of them: a walk asks many candidates among
## the same bodies before it places one.
func _catch_up(bodies: Array[EventScheduler.Planned]) -> void:
	var ids := PackedInt64Array()
	for plan in bodies:
		ids.append(plan.get_instance_id())
	var key := hash(ids)
	if key == _key and _reached != null:
		return
	_key = key
	_blocked = EventScheduler.blocked_by(_map, bodies)
	_reached = _grid.flood([_map.home_tile()], _blocked)
