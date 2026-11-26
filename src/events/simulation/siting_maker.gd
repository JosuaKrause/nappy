class_name SitingMaker
extends RefCounted
## **Makes a day's siting** (`WalkSiting`): the one place that knows what one is made of.
## `EventsAhead` is handed a maker and asks it for every siting it needs, so a test hands in one
## that answers a stand-in (`tests/fake_siting_maker.gd`), or one that keeps what it made
## (`tests/keeping_siting_maker.gd`).
##
## Handed the world the events stand in and the walk's events the siting is stated against. It reads
## the city's map, plan builder and poster walls off the world when it is asked, not when it is
## made: the manager makes it before a city is handed over.

var _world: EventWorld
var _walk: WalkEvents

func _init(the_world: EventWorld, walk: WalkEvents) -> void:
	_world = the_world
	_walk = walk

## A siting for `day` over `tree` (the day's route tree, which the caller hands), standing
## its rows on `ground` (what `EventsAhead._ground_of_the_walk()` answers): the walk's events, the
## city's plan builder and, where the city has poster walls, the fronts a crew may paste (only the
## city's buildings know their blank walls, and the walls paste every dawn, so the fronts are asked
## for today's here). The streams its judge builds candidates on are seeded by the run and the day
## (`EventWorld.day_stream()` named "siting"), so a day is laid the same way from the same walk.
func make(day: int, tree: RouteTree, ground: RowGround) -> WalkSiting:
	var fronts := {}
	if _world.poster_walls():
		fronts = _world.poster_walls().fronts()
	var streets := _world.streets()
	var left_open := streets.tutorial_walk_left_open() if streets else null
	return _assemble(_world.rows(), day, _world.city_map(), tree, _walk, _world.plan_builder(),
			ground, fronts, _world.day_stream(day, "siting").seed, left_open)

## **A siting from pieces** (`make()` hands it the world's). `base` seeds the streams its judge
## builds candidates on. Builds, in order: the corridor made of the day's tree, which its caller
## hands (the day's own, from `DayStreets`, so nothing grows a second one); the calm she has not used
## (`CalmAreas.unused_ground()`, none for a walk with no calm); the day's rules
## (`StreetInvalidation`) over the map, the corridor, that calm and the walk's doors; the fit
## (`LocationFit`, of which the judge asks only `build()`); the judge, a `RuledLocationGround`
## with no standing bodies (a beat is judged among the walk's whole plan, the seals and the wall
## included), its `roomiest` setting off (the first tile no rule refuses: nothing ranks a tile
## by room) and a route kept on its location's run (`DawnDraw.ROUTES_STAY_ON_THE_RUN`); the
## locations, the walk's or, for a walk that carries none (a rig's recipe walk), laid out
## here; the tiles a row may stand on (`SitedGround`) over `fronts`, the fronts a crew may paste
## (empty for a walk with no city). `left_open` is day 1's walk on the day that leaves it open
## (`DayStreets.tutorial_walk_left_open()`), else null: the rules keep one sidewalk of each of its
## streets open, as the dawn's do (`DawnContext.use_the_walk_left_open()`).
static func _assemble(rows: EventCatalogue, day: int, map: CityMap, tree: RouteTree,
		walk: WalkEvents,
		builder: PlanBuilder, ground: RowGround, fronts: Dictionary, base: int,
		left_open: TutorialRoute = null) -> WalkSiting:
	var corridor := Corridor.of(tree)
	var calm := walk.calm()
	var leave_alone: Array[Rect2] = calm.unused_ground() if calm else ([] as Array[Rect2])
	var kept: Array[StreetNetwork.Segment] = left_open.lesson_streets() if left_open \
			else ([] as Array[StreetNetwork.Segment])
	var rules := StreetInvalidation.new(map, corridor, leave_alone, walk.doors(), null, null, kept)
	var fit := LocationFit.new(day, map, builder, ground)
	var standing: Array[EventPlan] = []
	var judge := RuledLocationGround.new(day, base, map, standing, corridor, fit, rules, ground,
			false, DawnDraw.ROUTES_STAY_ON_THE_RUN)
	var locations := walk.locations()
	if not locations:
		locations = DayLocations.lay_out(map, corridor)
	return WalkSiting.new(map, tree, walk, locations, judge,
			SitedGround.new(rows, map, ground, fronts))
