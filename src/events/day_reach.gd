class_name DayReach
extends RefCounted
## **Where she can get to from home today**: the ground the walk's plan shuts and the flood from
## home over it, worked out when the walk starts and handed to whoever asks whether a place is one
## she can be sent to — the resistance's marks, contacts,
## masts and roadblocks, and the park cordon's last gap.
##
## *(inbox #1156: "have an object that contains the derived information -- don't rederive over
## and over again -- then pass that object around".)* `EventManager` makes one at every walk's start
## in the city (`EventManager._take()`) and the walk's events hold it (`WalkEvents.reach()`).
##
## **What is shut**: today's closures, the disc of every plan that blocks the way
## (`EventPlan.obstructs()`, as `EventScheduler.blocked_by()` paints it), and the soft
## seals' bands (`Mover.SOFT_SEALS`, the pavement a soft seal shuts to walkers), which the city's own
## guarantee does not ask: the red arrow reads a band as ground she cannot walk, so a place reached
## only through one is no place to send her. A region door's bodies shut nothing: she walks through
## a door.
##
## **Taken when the walk starts, and told only what the units draw** (`shut_more()`): a unit's
## draw follows from the day's seed as the dawn's plan does, and each unit draws as she comes near
## it (`EventsAhead`), so its bodies shut ground as the dawn's do. What is sited from her walk is
## never added: a body put up later (day 11's added mast, day 13's roadblock) must not shut the
## ground its own task stands on, and a body that leaves only gives ground back. **Never saved**: a
## load starts the walk again from the run's saved inputs.

## The four steps a walk takes from a tile.
const _STEPS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var _map: CityMap
var _grid: ReachabilityGrid
var _shut := {}
var _reached := {}
## Whether `_shut` grew since `_reached` was flooded (`shut_more()`): the next question floods
## again.
var _stale := false

## **The reach of `plans` on `map`**, read as `map` stands now: its closures and its soft seals.
static func of(map: CityMap, plans: Array[EventPlan]) -> DayReach:
	var reach := DayReach.new()
	reach._map = map
	reach._grid = ReachabilityGrid.build(map)
	reach._shut = shut_by(map, plans)
	reach._reached = reach._grid.flood([map.home_tile()], reach._shut)
	return reach

## **The ground `plans` shut on `map`** (`tile -> true`), as `map` stands now: the disc of every plan
## that blocks the way, today's closures and the soft seals' bands. What a reach is flooded over, for
## a caller that needs only the ground: dawn, placing day 13's roadblocks before the walk is planned
## (`DawnRoadblocks`).
static func shut_by(map: CityMap, plans: Array[EventPlan]) -> Dictionary:
	var blockers: Array[EventPlan] = []
	for plan in plans:
		if plan.obstructs():
			blockers.append(plan)
	var shut := EventScheduler.blocked_by(map, blockers)
	shut.merge(map.tiles_shut_to(Mover.SOFT_SEALS))
	return shut

## Whether `tile` is reached from home over the ground left open.
func reaches(tile: Vector2i) -> bool:
	if _stale:
		_reached = _grid.flood([_map.home_tile()], _shut)
		_stale = false
	return _grid.reaches(tile, _shut, _reached)

## **Shuts what the obstructing plans among `plans` stand on as well** (`EventPlan.obstructs()`,
## their discs as `of()` paints them), the next question flooding again: what a unit's draw placed
## as she walks (`EventsAhead`), which follows from the day's seed as the dawn's plan does. What is
## sited from her walk is never added.
func shut_more(plans: Array[EventPlan]) -> void:
	var blockers: Array[EventPlan] = []
	for plan in plans:
		if plan.obstructs():
			blockers.append(plan)
	if blockers.is_empty():
		return
	_shut.merge(EventScheduler.blocked_by(_map, blockers))
	_stale = true

## **A shortest walk from home to `tile`** over the ground left open, home first and `tile` last, a
## tile a step; empty where none reaches it. It walks the ground the flood floods (what the
## lattice's walker may cross, `CityMap.passable()` with `Mover.lattice()`, less what is shut), so
## a tile `reaches()` answers for has a way. Home is walked from even where the ground there is
## shut, as the flood is. What a place fixed from her walk is confirmed along (`WayConfirmation`).
##
## **Searched towards the tile, not flooded out from home**: a tile is taken up in the order of
## the steps walked to it plus the steps a straight walk from it to `tile` would still take, the
## least first, and of those the one found last, so the search runs at `tile` and widens only where
## that way is shut. That sum never falls along a walk and grows by two with a step away from
## `tile`, so the tiles wait in two lists, the least sum's (`front`) and the next's (`beyond`); a
## tile found again by a shorter walk takes the shorter, and by the time it is taken up from
## `front` its steps are its fewest. On the lattice it looks at the streets between home and the
## tile where a flood looks at the city as far out as the tile: the search is asked on the tick
## she reads a mark.
func way_from_home(tile: Vector2i) -> Array[Vector2i]:
	var way: Array[Vector2i] = []
	var ground := Mover.lattice()
	var bounds := Rect2i(Vector2i.ZERO, _map.size_in_tiles())
	var home := _map.home_tile()
	var came_from := {home: home}
	var steps_to := {home: 0}
	var front: Array[Vector2i] = [home]
	var beyond: Array[Vector2i] = []
	while not front.is_empty() or not beyond.is_empty():
		if front.is_empty():
			front = beyond
			beyond = []
		var at: Vector2i = front.pop_back()
		if at == tile:
			break
		var steps: int = int(steps_to[at]) + 1
		var left := absi(tile.x - at.x) + absi(tile.y - at.y)
		for step in _STEPS:
			var next := at + step
			if int(steps_to.get(next, steps + 1)) <= steps or _shut.has(next) \
					or not bounds.has_point(next) or not _map.passable(next, ground):
				continue
			steps_to[next] = steps
			came_from[next] = at
			if absi(tile.x - next.x) + absi(tile.y - next.y) < left:
				front.append(next)
			else:
				beyond.append(next)
	if not came_from.has(tile):
		return way
	var back := tile
	while back != home:
		way.append(back)
		var previous: Vector2i = came_from[back]
		back = previous
	way.append(home)
	way.reverse()
	return way

## Whether `tile` is shut.
func is_shut(tile: Vector2i) -> bool:
	return _shut.has(tile)

## The shut tiles (`tile -> true`), a copy: for a caller that shuts more on top of them and checks
## again (the park cordon's last gap).
func shut() -> Dictionary:
	return _shut.duplicate()

## **The ground her paths reach from `seeds` without leaving the circle of `radius` round `centre`**,
## walked tile by tile over walkable ground the reach leaves open, going on only from a tile inside
## the circle: `tile -> its distance from centre`, the seeds among them. How close by is measured for
## day 13's task (`ResistanceDirector._place_the_roadblock_near()`), from where she read the mark.
func paths_within(map: CityMap, seeds: Array[Vector2i], centre: Vector2, radius: float) -> Dictionary:
	return paths_over(map, _shut, seeds, centre, radius)

## `paths_within()` over `shut` rather than a reach's own: the one walk both the task's measure and
## dawn's (`DawnRoadblocks`) take, so the two measure close by alike.
## They measure it over different ground: dawn over what stood when its pass ran, the task over the
## walk's whole plan, which the passes after dawn's shut more of (`DawnRoadblockCount`
## counts the route tiles that leaves without a roadblock).
static func paths_over(map: CityMap, shut: Dictionary, seeds: Array[Vector2i], centre: Vector2,
		radius: float) -> Dictionary:
	var found := {}
	var queue: Array[Vector2i] = []
	for tile in seeds:
		# A seed is walked from even where the ground is shut: she may stand inside a body's disc.
		if found.has(tile) or not map.is_walkable(tile):
			continue
		var distance := map.tile_to_world(tile).distance_to(centre)
		if distance >= radius:
			continue
		found[tile] = distance
		queue.append(tile)
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + step
			if found.has(next) or not map.is_walkable(next) or shut.has(next):
				continue
			var distance := map.tile_to_world(next).distance_to(centre)
			if distance >= radius:
				continue
			found[next] = distance
			queue.append(next)
	return found
