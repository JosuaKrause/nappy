extends RefCounted
## **A walk of day 1's tutorial route for its dog walkers**, shared by the suite that holds them
## (`tests/test_tutorial_dog_walkers.gd`) and the probe that counts them over more seeds
## (`tests/probes/grassy_beaver_dog_walkers.gd`).
##
## Per seed, a real city in a run of its own (`RunCity`), handed its tutorial route as `main`
## hands it, and day 1 started through the real day order (`City.start_day()`,
## `EventManager.start_day()`, so the director holds its bag on the route). She walks from the
## doorstep along the day's branch to the tutorial park (the tree grows it on the line,
## `TutorialRoute.line_ground()`), steps into the park, and walks the same way back to the doorstep,
## at `Tuning.WALK_SPEED`, running each `STEP` what the manager's tick runs for her walk and for the
## encounters (`EventManager.step_what_is_ahead()`, `step_the_encounters()`). No crowd and no meter:
## what is walked is what the director sends and where she meets it.
##
## **Her camera is where the game's would be** (`FollowCamera`): leading her along her facing by the
## look-ahead (`Stroller.CAMERA_LOOK_AHEAD`), eased in, and trailing her by the position smoothing of
## her scene's camera, stepped at the physics rate, so the director judges sight against the view
## the player has; or, for a measurement, a fixed distance ahead of her (`walk()`'s `ahead`).
##
## **Met** is a live dog walker inside that view (`Tuning.VIEW_HALF_EXTENT` about the camera's centre).
## For each dog walker `walk()` says where she was when it came nearest, on the leg it was first seen
## on (`OUT_ON_THREE`, `OUT_ELSEWHERE` or `HOME`), how near that was, and whether the director sent
## it: created on a step that spent one of the moments she is owed (`EventManager.owed_ahead()`),
## rather than placed at dawn and streamed in.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const DAY := 1
const RUN_SEED := 2
const ROW := "dog_walker"
const STEP := 0.1
## Where she was when a dog walker came nearest: on lesson (3)'s street on her way to the park,
## elsewhere on that way, or on her walk home.
const OUT_ON_THREE := "out, on lesson (3)'s street"
const OUT_ELSEWHERE := "out, elsewhere"
const HOME := "home"
## `walk()`'s camera as it is in play (`FollowCamera`), rather than a fixed distance ahead of her.
const AS_IN_PLAY := -1.0
## Where no walk was had: the city has no tutorial route or no branch to its park, or she never
## stood in the park.
const NEVER_IN_THE_PARK := "never stood in the park"

## The seeds of the city suites.
static func seeds() -> Array[int]:
	var found: Array[int] = []
	for i in 6:
		found.append(4400 + i * 31)
	for i in 12:
		found.append(5150 + i * 13)
	for i in 6:
		found.append(71717 + i * 91)
	return found

## Each dog walker met on the walk of `seed_value`, in the order first met: `{where, nearest, sent}`;
## empty with no route to walk. Her camera leads her as in play, or by `ahead` px along her facing
## (its height foreshortened by `Stroller.OBLIQUE_Y`, as the look-ahead is).
static func walk(t: TestRunner, seed_value: int, ahead := AS_IN_PLAY) -> Array[Dictionary]:
	var met: Array[Dictionary] = []
	var run := RunCity.started_run(RUN_SEED)
	var city: City = RunCity.new_city(CITY_SCENE)
	t.add_child(city)
	var map := CityGenerator.generate(seed_value)
	RunCity.build(city, run, map)
	var route := TutorialRoute.for_city(EventCatalogue.shipped(), city.map())
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
	# Not the viewport's current camera, so what she sees is drawn from its transform
	# (`Stroller.view_centre_of()`), which `FollowCamera` moves: no frame runs in a probe to move a
	# current one off the origin, which would put every place down her line out of sight.
	camera.enabled = false
	player.add_child(camera)
	var follow := FollowCamera.new(camera, ahead, _smoothing_speed())
	t.add_child(player)
	player.set_physics_process(false)
	RunCity.events(city).use_player(player)
	var path := _to_the_park(city, route)
	if route and path.size() >= 2:
		player.global_position = city.map().doorstep_world_position()
		var seen := {}
		var sent := {}
		var phase := ["out"]
		var stood_in_park := [false]
		var tick := func() -> void:
			var events := RunCity.events(city)
			var owed_before := events.owed_ahead()
			var before := {}
			for instance in events.instances():
				before[instance.get_instance_id()] = true
			events.step_what_is_ahead(STEP)
			var sent_now := events.owed_ahead() < owed_before
			events.step_the_encounters(STEP)
			var her := player.global_position
			var centre := Stroller.view_centre_of(player)
			if route.has_in_its_park(city.map().world_to_tile(her)):
				stood_in_park[0] = true
			for instance in events.instances():
				if instance.row_id() != ROW:
					continue
				var key := instance.get_instance_id()
				if sent_now and not before.has(key):
					sent[key] = true
				var off := (instance.global_position - centre).abs()
				var in_view := off.x <= Tuning.VIEW_HALF_EXTENT.x \
						and off.y <= Tuning.VIEW_HALF_EXTENT.y
				if not seen.has(key):
					if not in_view:
						continue
					seen[key] = {"where": "", "nearest": INF, "phase": phase[0],
							"sent": sent.has(key)}
					met.append(seen[key])
				var entry: Dictionary = seen[key]
				var gap := instance.global_position.distance_to(her)
				# Nearest on the leg it was first seen on: one met on the way out and passed again on
				# the way home counts where she met it first.
				if entry["phase"] == phase[0] and gap < float(entry["nearest"]):
					var where: String = phase[0]
					if where == "out":
						where = OUT_ON_THREE if route.is_on_lesson(
								TutorialRoute.Lesson.NOISE_WITH_LESS_ROOM,
								city.map().world_to_tile(her)) else OUT_ELSEWHERE
					entry["where"] = where
					entry["nearest"] = gap
		_along(player, path, tick, follow)
		if not stood_in_park[0]:
			met.append({"where": NEVER_IN_THE_PARK, "nearest": INF})
		phase[0] = HOME
		var back := path.duplicate()
		back.reverse()
		back.append(city.map().doorstep_world_position())
		_along(player, back, tick, follow)
	player.free()
	city.free()
	return met

## Her way from the doorstep to the tutorial park: the cell centres of the first route of the
## day's branch to the park, from the doorstep end out, and one more point on the park's own ground
## within a few tiles of where the route ends; empty where the day has no such branch.
static func _to_the_park(city: City, route: TutorialRoute) -> Array[Vector2]:
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

static func _along(player: Stroller, points: Array[Vector2], tick: Callable,
		follow: FollowCamera) -> void:
	for point in points:
		while player.global_position.distance_to(point) > 1.0:
			var toward := point - player.global_position
			var stride := minf(toward.length(), Tuning.WALK_SPEED * STEP)
			player.velocity = toward.normalized() * Tuning.WALK_SPEED
			tick.call()
			follow.carry(player, toward.normalized(), stride, STEP)

## **Her camera as the game moves it, for a stroller that runs no frames**: each step it carries her
## `stride` along `facing` and puts the camera where the game's would be drawing from by then. In
## play (`AS_IN_PLAY`), stepped at the physics rate as `Stroller._update_camera()` and the camera's
## position smoothing step it: the offset eased toward the look-ahead along her facing
## (`Stroller.CAMERA_LOOK_AHEAD`, its height times `Stroller.OBLIQUE_Y`), and the smoothed point
## eased toward her at the scene camera's smoothing speed (Godot's `Camera2D` moves it that share of
## the way each tick). Otherwise a fixed `ahead` px along her facing.
class FollowCamera:
	var _camera: Camera2D
	var _ahead: float
	var _smoothing: float
	var _smoothed := Vector2.INF
	var _offset := Vector2.ZERO

	func _init(camera: Camera2D, ahead: float, smoothing: float) -> void:
		_camera = camera
		_ahead = ahead
		_smoothing = smoothing

	func carry(player: Node2D, facing: Vector2, stride: float, seconds: float) -> void:
		var lead := Vector2(facing.x, facing.y * Stroller.OBLIQUE_Y)
		if _ahead >= 0.0:
			player.global_position += facing * stride
			_camera.position = lead * _ahead
			return
		if _smoothed == Vector2.INF:
			_smoothed = player.global_position
		var ticks := maxi(1, roundi(seconds * Engine.physics_ticks_per_second))
		var tick := seconds / float(ticks)
		for i in ticks:
			player.global_position += facing * (stride / float(ticks))
			_offset = _offset.lerp(lead * Stroller.CAMERA_LOOK_AHEAD, clampf(tick * 3.0, 0.0, 1.0))
			var share := clampf(_smoothing * tick, 0.0, 1.0) if _smoothing > 0.0 else 1.0
			_smoothed += (player.global_position - _smoothed) * share
		_camera.position = _smoothed + _offset - player.global_position

## The position smoothing speed of the camera in her scene (`scenes/player/stroller.tscn`), read off
## the scene rather than restated; 0 where it sets none, which leaves no lag (`FollowCamera`).
static func _smoothing_speed() -> float:
	var scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var state := scene.get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != "Camera2D":
			continue
		for p in state.get_node_property_count(i):
			if state.get_node_property_name(i, p) == "position_smoothing_speed":
				var speed: float = state.get_node_property_value(i, p)
				return speed
	return 0.0

static func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("grassy-beaver-dog-walkers:%d:%d:%s" % [seed_value, DAY, stream])
	return rng
