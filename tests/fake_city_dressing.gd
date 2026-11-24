class_name FakeCityDressing
extends CityDressing
## A stand-in for the city scene's dressing, handed to what is handed a `CityDressing` (the day
## director, `DayDirector.start()`, and an authored scene, `SceneRecipeRuntime.install()`) in place
## of the city, so the check builds no city. It records each ask in order, as a line of the list it
## is handed (`asked`), and dresses nothing. A helper, not a suite: the runner loads only `test_*.gd`.
##
## **Read off a real city once** (the two steps of writing-tests): the asks are those the director
## and the runtime make of the city scene, in the order they make them; `refresh_street_trees()`
## notes how many of the map's tree pits are emptied at that moment, which is what the real city's
## refresh reads to hide a tree; `furnish_a_roof()` answers no problem, as the city does for a lot a
## building stands on; `buildings()` and `props()` answer what the suite hands in, none by default.
## The city's own dressing is checked in the city's suites (`tests/test_recipe_city_drawing.gd`).
##
## A node: the suite frees it.

var _fake_asked: Array[String]
var _fake_tinted: RouteSource
var _fake_prepared: Array[Rect2] = []
var _fake_map: CityMap
var _fake_emptied_at_refresh: Array[int] = []
var _fake_buildings: Array[Building] = []
var _fake_props: Array[Node2D] = []
var _fake_fronts: CityFronts

## A dressing that notes its asks as lines of `asked`, the list a suite shares among its stand-ins.
func _init(asked: Array[String] = []) -> void:
	_fake_asked = asked

## Hands it the map whose emptied tree pits `refresh_street_trees()` counts.
func read_pits_of(map: CityMap) -> FakeCityDressing:
	_fake_map = map
	return self

## Hands it the buildings and props it answers.
func stand(buildings: Array[Building], props: Array[Node2D]) -> FakeCityDressing:
	_fake_buildings = buildings
	_fake_props = props
	return self

## Hands it the fronts it answers.
func front_with(fronts: CityFronts) -> FakeCityDressing:
	_fake_fronts = fronts
	return self

## The route the kerbs were last asked to be tinted for, null before the ask.
func tinted_route() -> RouteSource:
	return _fake_tinted

## Every view the scenery was asked to be prepared over, in order.
func prepared_views() -> Array[Rect2]:
	return _fake_prepared

## How many tree pits of the map were emptied at each ask to refresh the street trees, in order.
func emptied_pits_at_each_refresh() -> Array[int]:
	return _fake_emptied_at_refresh

## How many roofs were furnished.
func roofs_furnished() -> int:
	return _fake_asked.count("furnish_a_roof")

## Overrides CityDressing.start_day.
func start_day(_state: CityState, _day: int, _rng: RandomNumberGenerator,
		_spec: DaySpec = null) -> void:
	_fake_asked.append("dress start_day")

## Overrides CityDressing.start_recipe_day.
func start_recipe_day(_state: CityState, _day: int, _rng: RandomNumberGenerator,
		_spec: DaySpec = null) -> void:
	_fake_asked.append("dress start_recipe_day")

## Overrides CityDressing.set_act.
func set_act(act: int) -> void:
	_fake_asked.append("set_act %d" % act)

## Overrides CityDressing.set_daylight.
func set_daylight(fraction: float) -> void:
	_fake_asked.append("daylight %.1f" % fraction)

## Overrides CityDressing.refresh_street_trees.
func refresh_street_trees() -> void:
	_fake_asked.append("refresh_street_trees")
	var emptied := 0
	if _fake_map != null:
		for pit in StreetTrees.planted(_fake_map):
			if _fake_map.is_tree_pit_emptied(pit.tile):
				emptied += 1
	_fake_emptied_at_refresh.append(emptied)

## Overrides CityDressing.tint_the_route.
func tint_the_route(route: RouteSource) -> void:
	_fake_tinted = route
	_fake_asked.append("tint")

## Overrides CityDressing.furnish_a_roof.
func furnish_a_roof(_lot: Rect2i, _fixtures: Array) -> Array[String]:
	_fake_asked.append("furnish_a_roof")
	var none: Array[String] = []
	return none

## Overrides CityDressing.start_the_signals.
func start_the_signals(into_the_cycle: float, dark: bool) -> void:
	_fake_asked.append("start_the_signals %.1f %s" % [into_the_cycle, dark])

## Overrides CityDressing.buildings.
func buildings() -> Array[Building]:
	return _fake_buildings

## Overrides CityDressing.props.
func props() -> Array[Node2D]:
	return _fake_props

## Overrides CityDressing.fronts.
func fronts() -> CityFronts:
	return _fake_fronts

## Overrides CityDressing.prepare_scenery_in.
func prepare_scenery_in(view: Rect2) -> void:
	_fake_prepared.append(view)
	_fake_asked.append("prepare")
