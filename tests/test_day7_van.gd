extends RefCounted
## Day 7's van gets a second instance on her route, from a rigged bag *(inbox #586 in
## olive-hedgehog: "each olive badger rigged bag should be 2 or 3"; inbox #650 in mossy-beaver: "I
## guess that leaves only the van?")*.
##
## Holds, through a real city: reading day 7's mark rigs her route with a bag of
## `Tuning.VAN_WITHIN_THE_NEXT` holding one `delivery_van`; walking the day's route, the van's marble
## is among that many events handed out on it, and a van is then put on her route — on ground the
## day's routes run along, past the streaming band, where she can walk to it, and in the world once
## she walks to it — while the van the task rides, placed near the mark, stays where it is.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 1234567]
const DAY := 7
const ROW := "delivery_van"
const STEP := 0.1

func run(t) -> void:
	var met := 0
	for seed_value in SEEDS:
		if _a_mark_puts_a_van_on_her_route(t, seed_value):
			met += 1
	t.check(met > 0, "a van is put on her route in at least one city (%d of %d)"
			% [met, SEEDS.size()])

## Answers whether a second van was put on her route in this city.
func _a_mark_puts_a_van_on_her_route(t, seed_value: int) -> bool:
	var size := Tuning.VAN_WITHIN_THE_NEXT
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	city.events.start_day(DAY, _rng(seed_value, "events"), consumed)

	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	GameState.completed_resistance_steps.assign(done)
	GameState.failed_resistance_steps.assign([])
	GameState.resistance_progress = 0
	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city, city.map)
	resistance.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	var mark := resistance.current_step()
	t.check(mark != null and mark.is_pickup and mark.day == DAY,
			"seed %d: day %d opens on its mark" % [seed_value, DAY])
	var bag := city.events._director.route_bag()
	if mark:
		resistance._on_contact_completed(mark.index)
	var task_van: EventInstance = resistance._rider
	t.check(task_van != null and task_van.def.id == ROW,
			"seed %d: reading it puts the task's van near the mark" % seed_value)
	var task_van_at := task_van.global_position if task_van else Vector2.INF
	var rigged := bag.bag_in_front()
	t.check(rigged.size() == size and rigged.count(ROW) == 1,
			"seed %d: reading the mark rigs her route with a bag of %d holding one %s (%s)"
			% [seed_value, size, ROW, rigged])

	var path := _the_longest_route(city)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	t.check(path.size() >= 2 and city.events._find_player(), "a route to walk and her on it")
	var placed: Array[EventScheduler.Planned] = []
	var drawn_within := false
	var her_at_siting := Vector2.INF
	var where_sited := Vector2.INF
	var heading_at_siting := Vector2.ZERO
	if path.size() >= 2:
		var index := 0
		var direction := 1
		player.global_position = path[0]
		var handed := 0
		var walked := 0.0
		while (handed < size or placed.is_empty() or not placed[0].was_live) and walked < 600.0:
			var next: Vector2 = path[index + direction] if index + direction >= 0 \
					and index + direction < path.size() else Vector2.INF
			if next == Vector2.INF:
				direction = -direction
				continue
			var toward := next - player.global_position
			if toward.length() < Tuning.WALK_SPEED * STEP:
				player.global_position = next
				index += direction
				continue
			player.velocity = toward.normalized() * Tuning.WALK_SPEED
			var owed_before := city.events.owed_ahead()
			var plans_before := city.events.plans().size()
			# In the order the manager's own tick runs them: what her walk sites, then what is owed.
			city.events._site_what_is_on_her_way(STEP)
			city.events._place_what_is_owed_ahead(STEP)
			city.events.stream_around(player.global_position)
			if city.events.owed_ahead() < owed_before and handed < size:
				handed += 1
				if handed == size:
					drawn_within = _a_place_from_her_route(city.events._director) != null
			for plan: EventScheduler.Planned in city.events.plans().slice(plans_before):
				if plan.def.id == ROW and city.events._director.is_from_her_route(plan):
					placed.append(plan)
					her_at_siting = player.global_position
					where_sited = plan.position
					heading_at_siting = player.velocity.normalized()
			player.global_position += player.velocity * STEP
			walked += STEP
	t.check(drawn_within, "seed %d: the van's marble is among the next %d events on her route"
			% [seed_value, size])
	var met_on_her_walk := placed.size() == 1 and placed[0].was_live
	print("[test_day7_van] seed %d: %d van put on her route, %s in the world by her walk"
			% [seed_value, placed.size(), "and" if met_on_her_walk else "not"])
	t.check(placed.size() <= 1, "seed %d: at most one van is put on her route (%d)"
			% [seed_value, placed.size()])
	if placed.size() == 1:
		var plan := placed[0]
		var map := city.map
		var tile := map.world_to_tile(where_sited)
		# A van leaves no line past it on the sidewalk it stands on, so the day never puts one on a
		# sidewalk a route runs along: "on her route" is the street she walks, across from her.
		var corridor := Corridor.of(city.route_tree())
		t.check(corridor.depth(tile) == 0 and not corridor.carries_a_route(tile),
				"seed %d: it stands on a street the day's routes run along, across from the route"
				% seed_value)
		t.check(where_sited.distance_to(her_at_siting) >= Tuning.EVENT_STREAM_RADIUS,
				"seed %d: it is put past the streaming band, so it is never seen to appear (%.0fpx)"
				% [seed_value, where_sited.distance_to(her_at_siting)])
		var grid := ReachabilityGrid.build(map)
		var reached := grid.flood([map.world_to_tile(her_at_siting)])
		t.check(grid.reaches(tile, {}, reached),
				"seed %d: she can walk to it from where she was" % seed_value)
		# Across the street is still on her way, so walking toward it does not move it on ahead of her
		# again before she reaches it (`EventDirector._is_no_longer_on_her_way()`).
		t.check(city.events._siting.still_ahead_of(her_at_siting, heading_at_siting, where_sited),
				"seed %d: across the street it still counts as on her way" % seed_value)
		t.check(met_on_her_walk and plan.position == where_sited,
				"seed %d: and walking on, she brings it into the world" % seed_value)
	t.check(task_van != null and is_instance_valid(task_van) and not task_van.is_finished
			and task_van.global_position == task_van_at and resistance._rider == task_van,
			"seed %d: the task's own van stays where it was placed, and stays the task" % seed_value)
	player.free()
	resistance.free()
	city.free()
	GameState.completed_resistance_steps.assign(saved_completed)
	GameState.failed_resistance_steps.assign(saved_failed)
	GameState.resistance_progress = saved_progress
	return placed.size() == 1

## The van a marble from her route's bag handed to her walk to site, sited or not; null when none
## has been.
func _a_place_from_her_route(director: EventDirector) -> EventScheduler.Planned:
	for plan: EventScheduler.Planned in director._placed_from_the_route:
		if plan.def.id == ROW:
			return plan
	return null

## The cell centres of the day's longest route, from the doorstep end out — the walk she takes.
func _the_longest_route(city: City) -> Array[Vector2]:
	var longest: Array = []
	for branch in city.route_tree().branches:
		for route: Array in branch.routes:
			if route.size() > longest.size():
				longest = route
	var points: Array[Vector2] = []
	for i in range(longest.size() - 1, -1, -1):
		points.append(EventScheduler.WalkSiting._cell_centre(city.map, longest[i]))
	return points

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("day7-van:%d:%d:%s" % [seed_value, DAY, stream])
	return rng
