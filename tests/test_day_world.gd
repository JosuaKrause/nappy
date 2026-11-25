extends RefCounted
## A world standing for one spec (`DayWorld`) alone: whether it is a city, which is the one answer
## the day director and the run log key every city branch on (`is_in_a_city()`).
##
## **A city has all five of its parts or is refused.** `in_the_city()` is handed the city's dressing,
## its map, today's streets, its crowd and its poster walls, and answers null when any is missing,
## so no walk is stood in a half-city. The parts are tokens handed through and never asked
## anything: the dressing's base, which dresses nothing, a bare map, empty streets, and a crowd and
## poster walls never set up.

func run(t: TestRunner) -> void:
	_test_a_city_with_every_part_is_a_city(t)
	_test_a_city_missing_a_part_is_refused(t)
	_test_the_building_is_no_city(t)

## Every part, then the world: a dressing, a crowd and poster walls (nodes, freed by the caller), a
## map and streets.
func _parts() -> Dictionary:
	return {"dressing": CityDressing.new(), "map": CityMap.new(Vector2i(8, 8)),
			"streets": DayStreets.new(), "crowd": Crowd.new(), "posters": PosterWalls.new()}

## `in_the_city()` handed `parts`, nobody in it, put down at the origin.
func _city_of(parts: Dictionary) -> DayWorld:
	return DayWorld.in_the_city(parts["dressing"], parts["map"], parts["streets"], parts["crowd"],
			parts["posters"], null, null, null, Vector2.ZERO, null, {})

func _free(parts: Dictionary) -> void:
	for key: String in ["dressing", "crowd", "posters"]:
		var node: Node = parts[key]
		node.free()

func _test_a_city_with_every_part_is_a_city(t: TestRunner) -> void:
	var parts := _parts()
	var world := _city_of(parts)
	t.check(world != null and world.is_in_a_city(),
			"a world with all five of the city's parts is a city")
	_free(parts)

func _test_a_city_missing_a_part_is_refused(t: TestRunner) -> void:
	for missing: String in ["dressing", "map", "streets", "crowd", "posters"]:
		var parts := _parts()
		var handed := parts.duplicate()
		handed[missing] = null
		t.check(_city_of(handed) == null, "a city world with no %s is refused" % missing)
		_free(parts)

func _test_the_building_is_no_city(t: TestRunner) -> void:
	var world := DayWorld.in_the_building(WorldMap.open_ground(), null, null, null, Vector2.ZERO,
			Vector2.UP, null)
	t.check(not world.is_in_a_city(), "a world stood with no city is no city")
