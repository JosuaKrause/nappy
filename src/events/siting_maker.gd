class_name SitingMaker
extends RefCounted
## **Makes a day's siting** (`EventScheduler.WalkSiting`): the one place that knows what one is made
## of. `EventsAhead` is handed a maker and asks it for every siting it needs, so a test hands in one
## that answers a stand-in, or one that keeps what it made (`tests/keeping_siting_maker.gd`).
##
## Handed the world the events stand in and the walk's events the siting is stated against. It reads
## the city's map, plan builder and poster walls off the world when it is asked, not when it is
## made: the manager makes it before a city is handed over.

var _world: EventWorld
var _walk: WalkEvents

func _init(the_world: EventWorld, walk: WalkEvents) -> void:
	_world = the_world
	_walk = walk

## A siting for `day` over `tree` (the day's route tree), standing its rows on `ground` (what
## `EventsAhead._ground_of_the_walk()` answers): the walk's events, a verdict store of its own, the
## city's plan builder and, where the city has poster walls, the fronts a crew may paste (only the
## city's buildings know their blank walls, and the walls paste every dawn, so the fronts are asked
## for today's here).
func make(day: int, tree: RouteTree, ground: RowGround) -> EventScheduler.WalkSiting:
	var siting := EventScheduler.WalkSiting.new(day, _world.the_city_map(), tree, _walk,
			EventScheduler.Verdicts.new(), _world.plan_builder(), ground)
	if _world.poster_walls():
		siting.fronts = _world.poster_walls().fronts()
	return siting
