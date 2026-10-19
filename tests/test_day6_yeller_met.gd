extends RefCounted
## Day 6's second man shouting is one she meets *(olive-koala, statement 2: "the yeller is
## guaranteed to encounter a yeller in the next three events")*. Reading the mark rigs her route's
## bag with one `homeless_yeller`; sited by the route band of the branch she is walking, he was
## never sited or put 1,300px and more ahead on a branch she then left, and in view on 1 of 12
## walks. He is sited on the street she is walking (`WalkSiting.ahead_on_her_street()`), the way
## day 7's route van is.
##
## Walks the way `--route mark,task,calm,home` does, at `Tuning.WALK_SPEED`, running what the
## manager's own tick runs for her walk, and counts the walks on which the rigged man was inside
## her view (`Tuning.VIEW_HALF_EXTENT` round her). A sweep of the walks, not one: where she ends
## up depends on the city. `tests/probes/calm_pelican_day7_van_met.gd` measures all 12 and says why
## the rest miss. Run by name: `tools/test.sh day6_yeller_met`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 31337, 555, 99]
## Most of the walks, not all: a walk that never passes a sidewalk of its own is not a defect.
const AT_LEAST := 4
const DAY := 6
const ROW := "homeless_yeller"
const STEP := 0.1
const SETTLE_SECONDS := 12.0

func run(t) -> void:
	# Whether the rigged man is sited in view depends on the run's seed; this was checked on seed 2.
	GameState.start_run(2)
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_alleys := GameState.completed_resistance_alley_tiles.duplicate()
	var met := 0
	var outcomes: Array[String] = []
	for seed_value in SEEDS:
		var outcome := _walk(t, seed_value)
		outcomes.append(outcome)
		if outcome == "seen":
			met += 1
	t.check(met >= AT_LEAST, "the rigged man shouting is in her view on most walks of day %d (%d of %d: %s)"
			% [DAY, met, SEEDS.size(), outcomes])
	GameState.completed_resistance_steps.assign(saved_completed)
	GameState.failed_resistance_steps.assign(saved_failed)
	GameState.resistance_progress = saved_progress
	GameState.completed_resistance_alley_tiles.assign(saved_alleys)

## "seen", "sited, never in view", "never sited", or "no mark".
func _walk(t, seed_value: int) -> String:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	city.events.start_day(DAY, _rng(seed_value, "events"), consumed)
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	GameState.completed_resistance_steps.assign(done)
	GameState.failed_resistance_steps.assign([])
	GameState.resistance_progress = 0
	GameState.completed_resistance_alley_tiles.assign([])
	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city, city.map)
	resistance.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = city.map.doorstep_world_position()
	city.events._find_player()
	var map := city.map
	var outcome := "no mark"
	var mark := resistance.current_step()
	if mark and mark.is_pickup:
		var seen := {"man": null, "in_view": false}
		var tick := func() -> void:
			var events := city.events
			events._site_what_is_on_her_way(STEP)
			events._place_what_is_owed_ahead(STEP)
			events.stream_around(player.global_position)
			if seen["man"] == null:
				for plan: EventScheduler.Planned in events._director._placed_from_the_route:
					if plan.def.id == ROW:
						seen["man"] = plan
			var man: EventScheduler.Planned = seen["man"]
			if man and man.is_placed():
				var off := (man.position - player.global_position).abs()
				if off.x <= Tuning.VIEW_HALF_EXTENT.x and off.y <= Tuning.VIEW_HALF_EXTENT.y:
					seen["in_view"] = true
		_along(player, _path(map, player.global_position, [map.world_to_tile(
				resistance.contact_position())]), tick)
		resistance._on_contact_completed(mark.index)
		var task_man: EventInstance = resistance._rider
		if task_man:
			_along(player, _path(map, player.global_position, _beside(map,
					task_man.global_position)), tick)
		_along(player, _path(map, player.global_position, map.calm_tiles()), tick)
		player.velocity = Vector2.ZERO
		for i in int(SETTLE_SECONDS / STEP):
			tick.call()
		var home: Array[Vector2i] = [map.world_to_tile(map.doorstep_world_position())]
		_along(player, _path(map, player.global_position, home), tick)
		var man: EventScheduler.Planned = seen["man"]
		if seen["in_view"]:
			outcome = "seen"
		elif man and man.is_placed():
			outcome = "sited, never in view"
		else:
			outcome = "never sited"
	player.free()
	resistance.free()
	city.free()
	return outcome

func _along(player: Stroller, points: Array[Vector2], tick: Callable) -> void:
	for point in points:
		while player.global_position.distance_to(point) > 1.0:
			var toward := point - player.global_position
			var stride := minf(toward.length(), Tuning.WALK_SPEED * STEP)
			player.velocity = toward.normalized() * Tuning.WALK_SPEED
			tick.call()
			player.global_position += toward.normalized() * stride

## The shortest walkable path from `from` to the nearest of `goals`, as tile centres.
func _path(map: CityMap, from: Vector2, goals: Array[Vector2i]) -> Array[Vector2]:
	var start := map.world_to_tile(from)
	var wanted := {}
	for goal in goals:
		wanted[goal] = true
	var came := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	var found := Vector2i(-1, -1)
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if wanted.has(tile):
			found = tile
			break
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + step
			if came.has(next) or not map.is_walkable(next) or map.is_closed(next) \
					or (map.is_obstructed(next) and not wanted.has(next)):
				continue
			came[next] = tile
			queue.append(next)
	var points: Array[Vector2] = []
	if found == Vector2i(-1, -1):
		return points
	var at := found
	while at != start:
		points.push_front(map.tile_to_world(at))
		at = came[at]
	return points

## The walkable, unobstructed tiles within two tiles of `at`: where she stands to touch a body.
func _beside(map: CityMap, at: Vector2) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var centre := map.world_to_tile(at)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var tile := centre + Vector2i(dx, dy)
			if map.is_walkable(tile) and not map.is_obstructed(tile) and not map.is_closed(tile):
				found.append(tile)
	return found

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("day7-van-met:%d:%d:%s" % [seed_value, DAY, stream])
	return rng
