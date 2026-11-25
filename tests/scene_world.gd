class_name SceneWorld
extends RefCounted
## A world of stand-ins over a real recipe map, for a suite that hands an authored scene the world
## the run flow hands it (`SceneRecipeRuntime.install()`, `DayWorld`): the dressing, the crowd, the
## events, the poster walls, her and the baby are stand-ins that record what they are asked
## (`FakeCityDressing`, `FakeCrowd`, `FakeEventManager`, `FakePosterWalls`, `FakeStroller`,
## `FakeBaby`, all noting their asks on the one list `asked`), and the map and today's streets are
## real: model data a recipe builds (`RecipeCityBuilder.build()`) and the day's own planners
## (`RouteTree`, `RegionPlanner.plan_day()`, the recipe's closures) begin as the city scene's
## `start_recipe_day()` does, without the scene. A helper, not a suite: the runner loads only
## `test_*.gd`.
##
## The stand-ins are nodes the suite frees (`free_all()`), and the map is the one it handed in, so a
## suite that stands several worlds over one recipe hands each its own copy (`CityMap.copy()`).

## The world the scene is installed into.
var world: DayWorld
## The map, as handed in, painted for the day and its closures shut.
var map: CityMap
## Today's streets, begun from the day's own planners.
var streets: DayStreets
var dressing: FakeCityDressing
var crowd: FakeCrowd
var events: FakeEventManager
var posters: FakePosterWalls
var player: FakeStroller
var baby: FakeBaby
## What the stand-ins were asked, in order, one line each.
var asked: Array[String] = []

## A world over `map` on `day`: the map painted for the day's state and its streets begun under
## `spec` (a day's, `DaySpec.for_day()`, when none is handed), her put down at the doorstep.
static func over(on: CityMap, day: int, spec: DaySpec = null) -> SceneWorld:
	var made := SceneWorld.new()
	var walk := spec if spec else DaySpec.for_day(day)
	made.map = on
	var state := CityState.new()
	state.begin_day(on.plans_by_block(), day)
	on.repaint(state)
	var edges := on.witness_only()
	var tree := RouteTree.for_day(on, day, null)
	var plan := RegionPlanner.plan_day(on, walk, tree)
	on.restore_edges(edges)
	var closures: Array[RoadClosure] = on.recipe_road_closures().duplicate()
	made.streets = DayStreets.new()
	made.streets.begin_day(tree, plan, closures)
	on.close_streets(closures)
	made.dressing = FakeCityDressing.new(made.asked).read_pits_of(on)
	made.crowd = FakeCrowd.new(made.asked)
	made.events = FakeEventManager.new()
	made.posters = FakePosterWalls.new()
	made.player = FakeStroller.new(made.asked)
	made.baby = FakeBaby.new(made.asked)
	made.world = DayWorld.in_the_city(made.dressing, on, made.streets, made.crowd, made.posters,
			made.events, made.player, made.baby, on.doorstep_world_position(), null, {})
	return made

## Frees the stand-ins.
func free_all() -> void:
	for node: Node in [dressing, crowd, events, posters, player, baby]:
		node.free()
