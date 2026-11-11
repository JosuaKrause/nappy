extends RefCounted
## The planning calls the dev walker (`BuildingWalker`) makes on the building, through their public
## surface: `InteriorMapPlan.way_out()`, with and without tiles to keep off, and the two accessors on `BuildingPlan`
## that say what to keep off, `fire_tile()` and `pursuer_ground_below_the_first_floor()`. The game
## itself calls none of them, so no other suite reaches them.

func run(t: TestRunner) -> void:
	var map := InteriorMap.build()
	_test_a_way_out_is_legs_from_her_start_to_the_exit_ending_on_door_thresholds(t, map)
	_test_a_way_out_keeps_off_the_ground_it_is_told_to(t, map)
	_test_a_way_out_steps_around_a_blocked_tile_in_the_middle_of_its_first_leg(t, map)
	_test_the_fire_tile_is_the_second_floors_approach_in_the_burning_shaft(t, map)
	_test_the_pursuers_ground_is_the_shaft_below_the_first_floor_landing(t, map)

func _test_a_way_out_is_legs_from_her_start_to_the_exit_ending_on_door_thresholds(t: TestRunner, map: InteriorMapPlan) -> void:
	var legs := map.way_out(map.start_position())
	t.check(not legs.is_empty(), "there is a way out from her start")
	if legs.is_empty():
		return
	for i in legs.size() - 1:
		var leg: Array = legs[i]
		var end: Vector2i = leg.back()
		t.check(map.transition_at(end).get("kind", "") == "door",
				"leg %d ends on a door's threshold (%s)" % [i, end])
		var door: InteriorMapPlan.Door = map.transition_at(end)["door"]
		var counterpart: InteriorMapPlan.Door = map.door(door.target_door)
		var next: Array = legs[i + 1]
		t.check(next.is_empty() or InteriorMap.part_at(next.front()) == InteriorMap.part_at(counterpart.tile),
				"and the next leg starts in the part that door leads to")
		for tile: Vector2i in leg.slice(1, leg.size() - 1):
			t.check(map.transition_at(tile).get("kind", "") != "door",
					"no leg steps on a door between where it starts and where it ends (%s)" % [tile])
	t.check((legs.back() as Array).back() == map.exit_position(), "the last leg ends on the service exit")

func _test_a_way_out_keeps_off_the_ground_it_is_told_to(t: TestRunner, map: InteriorMapPlan) -> void:
	var blocked := {}
	var fire := BuildingPlan.fire_tile(map)
	blocked[fire] = true
	for tile in BuildingPlan.pursuer_ground_below_the_first_floor(map):
		blocked[tile] = true
	var legs := map.way_out(map.start_position(), blocked)
	t.check(not legs.is_empty(), "there is still a way out with the fire and the pursuer's ground kept off")
	for leg: Array in legs:
		for tile: Vector2i in leg:
			t.check(not blocked.has(tile), "the way keeps off the blocked tile %s" % [tile])

func _test_a_way_out_steps_around_a_blocked_tile_in_the_middle_of_its_first_leg(t: TestRunner, map: InteriorMapPlan) -> void:
	var first: Array = map.way_out(map.start_position())[0]
	var middle: Vector2i = first[first.size() / 2]
	var legs := map.way_out(map.start_position(), {middle: true})
	var crossed := false
	for leg: Array in legs:
		crossed = crossed or leg.has(middle)
	t.check(first.size() >= 3 and not legs.is_empty() and not crossed,
			"a tile in the middle of the first leg is stepped around, not crossed (%s)" % [middle])
	var goal: Vector2i = first.back()
	var with_the_goal_blocked := map.way_out(map.start_position(), {goal: true})
	t.check(not with_the_goal_blocked.is_empty() and with_the_goal_blocked[0] == first,
			"the goal itself is never blocked")

func _test_the_fire_tile_is_the_second_floors_approach_in_the_burning_shaft(t: TestRunner, map: InteriorMapPlan) -> void:
	var fire := BuildingPlan.fire_tile(map)
	t.check(fire != InteriorMapPlan.NOWHERE and map.is_walkable(fire), "the fire stands on walkable ground")
	var landing := map.waypoint("stairwell_%s:landing_second" % BuildingPlan.BURNING_SIDE)
	t.check(fire == landing + Vector2i.DOWN, "directly below the burning shaft's second-floor landing")

func _test_the_pursuers_ground_is_the_shaft_below_the_first_floor_landing(t: TestRunner, map: InteriorMapPlan) -> void:
	var ground := BuildingPlan.pursuer_ground_below_the_first_floor(map)
	t.check(not ground.is_empty(), "the masked man's shaft has ground below the first floor")
	var walk := map.stairwell_walk("stairwell_%s" % BuildingPlan.PURSUED_SIDE)
	var landing := map.waypoint("stairwell_%s:landing_first" % BuildingPlan.PURSUED_SIDE)
	t.check(not ground.has(landing), "it stops short of the first floor's landing")
	t.check(ground.size() == walk.find(landing), "and is every cell of his walk before it")
	for i in ground.size():
		t.check(ground[i] == walk[i], "cell %d is the shaft's own walk" % i)
