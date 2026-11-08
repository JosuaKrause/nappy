extends RefCounted
## The street rig the crowd suites share: a straight stretch of a real city's ordinary street, and
## an agent placed on one of its lanes through the entry the game gives a task scene's pinned actors
## (`Crowd.add_recipe_actor()`). `test_crowd_bodies.gd` extends it, so the suites that reach it
## through that file keep their calls; `test_danger.gd` uses it directly.

## A straight stretch of ordinary vertical street this city actually has, as the corridor index and
## the first along tile of a run of `length` tiles that is street all the way across and all the way
## down. Returns `-1` for the corridor when the city has no such run, which no generated city does —
## the caller checks, so a rig that has quietly stopped testing anything says so.
func a_straight_run(map: CityMap, length: int) -> Vector2i:
	for corridor in range(1, CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x) - 1):
		if corridor == map.main_road:
			continue
		for start in range(4, map.size.y - length - 4):
			if _run_is_ordinary_street(map, corridor, start, length):
				return Vector2i(corridor, start)
	return Vector2i(-1, -1)

func _run_is_ordinary_street(map: CityMap, corridor: int, start: int, length: int) -> bool:
	for along in range(start, start + length):
		if map.street_kind(true, corridor, along) != GameEnums.StreetKind.ORDINARY:
			return false
		for offset in range(Tuning.STREET_WIDTH):
			var tile := Vector2i(corridor * CityMap.period() + offset, along)
			if not map.is_street(tile) or map.is_closed(tile):
				return false
	return true

## An agent on one lane of one corridor of `crowd`'s map, walking or driving at a given along position, added to the
## day's (emptied) crowd so `Crowd.step()` moves it exactly as it moves anybody.
func place_on(crowd: Crowd, map: CityMap, kind: CrowdAgent.Kind, corridor: int, lane: int,
		along: float, direction: float, vertical := true,
		offsets: Array[int] = CrowdLanes.SIDEWALK_OFFSETS, speed := -1.0,
		seed_value := 1) -> CrowdAgent:
	var centre := CrowdLanes.lane_centre(corridor, lane) if kind == CrowdAgent.Kind.CAR \
			else CrowdLanes.walker_lane_centre(corridor, lane, offsets)
	var at := Vector2(centre, along) if vertical else Vector2(along, centre)
	var heading := Vector2(0.0, direction) if vertical else Vector2(direction, 0.0)
	# The same entry the game gives a pinned actor in a task scene (`SceneRecipeRuntime`): the
	# lane, the body clearance and the pocket are checked as a rolled morning's are.
	if speed < 0.0:
		speed = 60.0 if kind == CrowdAgent.Kind.WALKER else 130.0
	var placed := crowd.add_recipe_actor("rig-%d" % crowd.agent_count(), kind, at,
			heading, speed, seed_value)
	assert(placed["error"] == "", "the rig's agent is placed: %s" % placed["error"])
	return placed.get("actor")

## `place_on()` on a built city's crowd, for the suites that still build the city around theirs.
func agent_on(city: City, map: CityMap, kind: CrowdAgent.Kind, corridor: int, lane: int,
		along: float, direction: float, vertical := true,
		offsets: Array[int] = CrowdLanes.SIDEWALK_OFFSETS, speed := -1.0,
		seed_value := 1) -> CrowdAgent:
	return place_on(city.crowd, map, kind, corridor, lane, along, direction, vertical, offsets,
			speed, seed_value)

## A crowd on `map` in a bare world held under `t`, built the way a task scene's rig builds it (the
## world, the map, the lights and no streets handed to `Crowd.setup()`) and with no city around it,
## which a suite of the crowd does not test. Free it with `free_crowd()`.
func a_crowd(t, map: CityMap) -> Crowd:
	var world := WorldContext.new()
	t.add_child(world)
	var crowd := Crowd.new()
	crowd.name = "Crowd"
	world.add_child(crowd)
	crowd.setup(world, map, TrafficSignals.new(map), DayStreets.new())
	return crowd

## Frees the world `a_crowd()` made, and the crowd and every agent in it with it.
func free_crowd(crowd: Crowd) -> void:
	crowd.get_parent().free()
