extends RefCounted
## Measurement probe for grassy-beaver's dog walkers on the tutorial route (a day one that teaches):
## **is lesson (3)'s dog walker met on its street on the way to the park, and the second rigged dog
## walker met before her door on the walk home?** Not a suite: it prints rather than asserts, and a
## seed where the second is not met goes to the board. Run by name:
##
##     tools/test.sh probes/grassy_beaver_dog_walkers.gd   (prints DOG_WALKERS lines)
##
## **The rig.** Per seed of the city suites, a real city in a run of its own (`RunCity`), handed
## its tutorial route as `main` hands it, and day 1 started through the real day order
## (`City.start_day()`, `EventManager.start_day()`, so the director holds its bag on the route).
## She walks from the doorstep along the day's branch to the tutorial park (the tree grows it on
## the line, `TutorialRoute.line_ground()`), steps into the park, and walks the same way back to the
## doorstep, at `Tuning.WALK_SPEED`, running each `STEP` what the manager's tick runs for her walk
## and for the encounters (`EventManager.step_what_is_ahead()`, `step_the_encounters()`). No crowd
## and no meter: what is measured is what the director sends and where she meets it.
##
## **Met** is a live dog walker inside the camera's view round her (`Tuning.VIEW_HALF_EXTENT`). For
## each dog walker the line says where she was when it was first in her view (on lesson (3)'s
## street, elsewhere on the way out, or on the way home) and how near it came.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const DAY := 1
const RUN_SEED := 2
const ROW := "dog_walker"
const STEP := 0.1

static func _seeds() -> Array[int]:
	var found: Array[int] = []
	for i in 6:
		found.append(4400 + i * 31)
	for i in 12:
		found.append(5150 + i * 13)
	for i in 6:
		found.append(71717 + i * 91)
	return found

func run(t: TestRunner) -> void:
	var first_on_its_street := 0
	var second_before_the_door := 0
	var walked := 0
	var missed: Array[String] = []
	for seed_value in _seeds():
		var met := _walk(t, seed_value)
		if met.is_empty():
			print("DOG_WALKERS seed %d: no tutorial route or no branch to its park" % seed_value)
			continue
		walked += 1
		var out_on_three := false
		var home := false
		var lines: Array[String] = []
		for seen: Dictionary in met:
			lines.append("%s nearest %.0fpx" % [seen["where"], float(seen["nearest"])])
			out_on_three = out_on_three or seen["where"] == "out, on lesson (3)'s street"
			home = home or seen["where"] == "home"
		first_on_its_street += 1 if out_on_three else 0
		second_before_the_door += 1 if home else 0
		if not home:
			missed.append(str(seed_value))
		print("DOG_WALKERS seed %d: %s" % [seed_value, lines])
	print("DOG_WALKERS walks=%d first met on lesson (3)'s street=%d second met before her door=%d; second not met: %s"
			% [walked, first_on_its_street, second_before_the_door, missed])
	t.check(true, "a probe asserts nothing")

## Each dog walker met on the walk of `seed_value`, in the order first met: `{where, nearest}`;
## empty with no route to walk.
func _walk(t: TestRunner, seed_value: int) -> Array[Dictionary]:
	var met: Array[Dictionary] = []
	var run := RunCity.started_run(RUN_SEED)
	var city: City = RunCity.new_city(CITY_SCENE)
	t.add_child(city)
	var map := CityGenerator.generate(seed_value)
	RunCity.build(city, run, map)
	var route := TutorialRoute.for_city(city.map())
	city.use_tutorial_route(route)
	var state := CityState.new()
	state.begin_day(city.map().plans_by_block(), DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	RunCity.events(city).start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), consumed)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	RunCity.events(city).use_player(player)
	var path := _to_the_park(city, route)
	if route and path.size() >= 2:
		player.global_position = city.map().doorstep_world_position()
		var seen := {}
		var phase := ["out"]
		var stood_in_park := [false]
		var tick := func() -> void:
			var events := RunCity.events(city)
			events.step_what_is_ahead(STEP)
			events.step_the_encounters(STEP)
			var her := player.global_position
			if route.has_in_its_park(city.map().world_to_tile(her)):
				stood_in_park[0] = true
			for instance in events.instances():
				if instance.row_id() != ROW:
					continue
				var key := instance.get_instance_id()
				var off := (instance.global_position - her).abs()
				var in_view := off.x <= Tuning.VIEW_HALF_EXTENT.x \
						and off.y <= Tuning.VIEW_HALF_EXTENT.y
				if not seen.has(key):
					if not in_view:
						continue
					var where: String = phase[0]
					if where == "out":
						where = "out, on lesson (3)'s street" if route.is_on_lesson(
								TutorialRoute.Lesson.NOISE_WITH_LESS_ROOM,
								city.map().world_to_tile(her)) else "out, elsewhere"
					seen[key] = {"where": where, "nearest": INF}
					met.append(seen[key])
				var entry: Dictionary = seen[key]
				entry["nearest"] = minf(float(entry["nearest"]),
						instance.global_position.distance_to(her))
		_along(player, path, tick)
		if not stood_in_park[0]:
			met.append({"where": "never stood in the park", "nearest": INF})
		phase[0] = "home"
		var back := path.duplicate()
		back.reverse()
		back.append(city.map().doorstep_world_position())
		_along(player, back, tick)
	player.free()
	city.free()
	return met

## Her way from the doorstep to the tutorial park: the cell centres of the first route of the
## day's branch to the park, from the doorstep end out, and one more point on the park's own ground
## within a few tiles of where the route ends; empty where the day has no such branch.
func _to_the_park(city: City, route: TutorialRoute) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if route == null:
		return points
	var tree := city.streets().route_tree()
	for branch in tree.branches():
		if branch.area != route.park_block() or branch.routes.is_empty():
			continue
		var cells: Array = branch.routes[0]
		for i in range(cells.size() - 1, -1, -1):
			points.append(tree.cell_centre(cells[i]))
		break
	if points.is_empty():
		return points
	var map := city.map()
	var end := map.world_to_tile(points.back())
	if not route.has_in_its_park(end):
		var best := Vector2i(-1, -1)
		for dy in range(-8, 9):
			for dx in range(-8, 9):
				var tile := end + Vector2i(dx, dy)
				if route.has_in_its_park(tile) and (best.x < 0
						or (tile - end).length_squared() < (best - end).length_squared()):
					best = tile
		if best.x >= 0:
			points.append(map.tile_to_world(best))
	return points

func _along(player: Stroller, points: Array[Vector2], tick: Callable) -> void:
	for point in points:
		while player.global_position.distance_to(point) > 1.0:
			var toward := point - player.global_position
			var stride := minf(toward.length(), Tuning.WALK_SPEED * STEP)
			player.velocity = toward.normalized() * Tuning.WALK_SPEED
			tick.call()
			player.global_position += toward.normalized() * stride

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("grassy-beaver-dog-walkers:%d:%d:%s" % [seed_value, DAY, stream])
	return rng
