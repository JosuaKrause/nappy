class_name DayReach
extends RefCounted
## **Where she can get to from home today, as the walk was planned**: the ground the walk's plan
## shuts and the flood from home over it, worked out once when the walk starts and handed to
## whoever asks whether a place is one she can be sent to — the resistance's marks, contacts,
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
## **Taken when the walk starts and kept**, never brought up to date: a body put up later (day 11's
## added mast, day 13's roadblock) must not shut the ground its own task stands on, and a body that
## leaves only gives ground back. **Never saved**: a load starts the walk again from the run's saved
## inputs.

var _grid: ReachabilityGrid
var _shut := {}
var _reached := {}

## **The reach of `plans` on `map`**, read as `map` stands now: its closures and its soft seals.
static func of(map: CityMap, plans: Array[EventPlan]) -> DayReach:
	var reach := DayReach.new()
	reach._grid = ReachabilityGrid.build(map)
	reach._shut = shut_by(map, plans)
	reach._reached = reach._grid.flood([map.home_tile()], reach._shut)
	return reach

## **The ground `plans` shut on `map`** (`tile -> true`), as `map` stands now: the disc of every plan
## that blocks the way, today's closures and the soft seals' bands. What a reach is flooded over, for
## a caller that needs only the ground: dawn, placing day 13's roadblocks before the walk is planned
## (`EventScheduler._place_the_roadblocks()`).
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
	return _grid.reaches(tile, _shut, _reached)

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
## dawn's (`EventScheduler._place_the_roadblocks()`) take, so the two measure close by alike.
## They measure it over different ground: dawn over what stood when its pass ran, the task over the
## walk's whole plan, which the passes after dawn's shut more of (`EventScheduler.
## _count_what_is_left_uncovered()` counts the route tiles that leaves without a roadblock).
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
