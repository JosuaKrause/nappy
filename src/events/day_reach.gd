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
## (`EventScheduler.Planned.obstructs()`, as `EventScheduler.blocked_by()` paints it), and the soft
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
static func of(map: CityMap, plans: Array[EventScheduler.Planned]) -> DayReach:
	var reach := DayReach.new()
	reach._grid = ReachabilityGrid.build(map)
	var blockers: Array[EventScheduler.Planned] = []
	for plan in plans:
		if plan.obstructs():
			blockers.append(plan)
	reach._shut = EventScheduler.blocked_by(map, blockers)
	reach._shut.merge(map.blocked.tiles_of(Mover.SOFT_SEALS))
	reach._reached = reach._grid.flood([map.home_rect.position], reach._shut)
	return reach

## Whether `tile` is reached from home over the ground left open.
func reaches(tile: Vector2i) -> bool:
	return _grid.reaches(tile, _shut, _reached)

## Whether `tile` is shut.
func is_shut(tile: Vector2i) -> bool:
	return _shut.has(tile)

## The shut tiles (`tile -> true`), a copy: for a caller that shuts more on top of them and floods
## again (`ResistanceDirector._on_her_side()`, the park cordon's last gap).
func shut() -> Dictionary:
	return _shut.duplicate()

## The reachability grid the reach is flooded on: the city's walkable tiles in two-tile cells.
func grid() -> ReachabilityGrid:
	return _grid
