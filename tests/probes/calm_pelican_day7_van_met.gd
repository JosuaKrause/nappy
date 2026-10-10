extends RefCounted
## Measurement probe for olive-badger's day-7 route van: once the rigged bag puts a second
## `delivery_van` on her route, does a played walk ever bring it into her view? Not a suite: it
## prints what each walk met, so it lives under `tests/probes/` and runs only by name:
##
##     tools/test.sh probes/calm_pelican_day7_van_met.gd      (prints DAY7_VAN lines)
##
## **The walk** is the one `--route mark,calm,home` plays (`RouteRig`), without its hazard pricing:
## from the doorstep to the mark along the shortest walkable path, reading it there, then to the
## nearest calm tile on foot, a settle of `SETTLE_SECONDS` standing still, then home. Every step runs
## what the manager's own tick runs for her walk (`_site_what_is_on_her_way()`,
## `_place_what_is_owed_ahead()`, `stream_around()`), at `Tuning.WALK_SPEED`.
##
## **What is counted**, per seed: whether the van's marble was drawn; where the van was put — how far
## ahead of her, and how near her own later walk ever came to it; whether it was ever inside her view
## (`Tuning.VIEW_HALF_EXTENT` round her, the player's unrotated screen); and, where it was not, why:
## never sited, sited past where she stopped walking, or sited off the way she then walked.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The day and row measured, and the same for day 6's man shouting, rigged and sited the way the
## other places on her route are, for comparison.
const CASES := [[7, "delivery_van"], [6, "homeless_yeller"]]
const STEP := 0.1
const SETTLE_SECONDS := 12.0
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024, 555, 8080, 99, 123456, 271828,
		314159]

func run(t) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	for case: Array in CASES:
		var tally := {}
		for seed_value in SEEDS:
			var outcome := _walk_a_day(t, seed_value, case[0], case[1])
			tally[outcome] = int(tally.get(outcome, 0)) + 1
		print("DAY7_VAN day %d %s, %d walks: %s" % [case[0], case[1], SEEDS.size(), tally])
	GameState.completed_resistance_steps.assign(saved_completed)
	GameState.failed_resistance_steps.assign(saved_failed)
	GameState.resistance_progress = saved_progress

func _walk_a_day(t, seed_value: int, day: int, row: String) -> String:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _rng(seed_value, day, "closures"))
	var consumed: Array[String] = []
	city.events.start_day(day, _rng(seed_value, day, "events"), consumed)
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < day:
			done.append(step.index)
	GameState.completed_resistance_steps.assign(done)
	GameState.failed_resistance_steps.assign([])
	GameState.resistance_progress = 0
	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city, city.map)
	resistance.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = city.map.doorstep_world_position()
	city.events._find_player()
	var walk := Walk.new()
	walk.city = city
	walk.row = row
	var mark := resistance.current_step()
	var map := city.map
	var outcome := "no mark"
	if mark and mark.is_pickup:
		var mark_at := resistance.contact_position()
		walk.along(player, _path(map, player.global_position, [map.world_to_tile(mark_at)]))
		resistance._on_contact_completed(mark.index)
		walk.read_at = player.global_position
		walk.phase = "to the task"
		var task_van: EventInstance = resistance._rider
		if task_van:
			walk.along(player, _path(map, player.global_position,
					_beside(map, task_van.global_position)))
		walk.phase = "to calm"
		var calm := map.calm_tiles()
		walk.along(player, _path(map, player.global_position, calm))
		walk.phase = "settling"
		walk.settle(player, SETTLE_SECONDS)
		walk.phase = "home"
		var home: Array[Vector2i] = [map.world_to_tile(map.doorstep_world_position())]
		walk.along(player, _path(map, player.global_position, home))
		outcome = walk.outcome()
		print("day7_VAN seed %d: %s | %s" % [seed_value, outcome, walk.detail()])
	player.free()
	resistance.free()
	city.free()
	return outcome

## Her walk, ticking what the manager ticks, and what it saw of the van.
class Walk extends RefCounted:
	var city: City
	var row := ""
	var read_at := Vector2.INF
	var walked := 0.0
	var van: EventScheduler.Planned = null
	var drawn_at := -1.0
	var sited_at := -1.0
	var her_at_siting := Vector2.INF
	var ahead_at_siting := 0.0
	var nearest_after := INF
	var seen_at := -1.0
	var walked_after_siting := 0.0
	var was_live := false
	var phase := "to the mark"
	var drawn_phase := ""
	var sited_phase := ""

	func along(player: Stroller, points: Array[Vector2]) -> void:
		for point in points:
			while player.global_position.distance_to(point) > 1.0:
				var toward := point - player.global_position
				var stride := minf(toward.length(), Tuning.WALK_SPEED * STEP)
				player.velocity = toward.normalized() * Tuning.WALK_SPEED
				_tick(player)
				player.global_position += toward.normalized() * stride
				walked += STEP
				if van and van.is_placed():
					walked_after_siting += stride

	func settle(player: Stroller, seconds: float) -> void:
		player.velocity = Vector2.ZERO
		var waited := 0.0
		while waited < seconds:
			_tick(player)
			waited += STEP

	func _tick(player: Stroller) -> void:
		var events := city.events
		events._site_what_is_on_her_way(STEP)
		events._place_what_is_owed_ahead(STEP)
		events.stream_around(player.global_position)
		if van == null:
			for plan: EventScheduler.Planned in events._director._placed_from_the_route:
				if plan.def.id == row:
					van = plan
					drawn_at = walked
					drawn_phase = phase
		if van and van.is_placed():
			if sited_at < 0.0:
				sited_at = walked
				sited_phase = phase
				her_at_siting = player.global_position
				ahead_at_siting = van.position.distance_to(player.global_position)
			var off := (van.position - player.global_position).abs()
			nearest_after = minf(nearest_after, van.position.distance_to(player.global_position))
			if seen_at < 0.0 and off.x <= Tuning.VIEW_HALF_EXTENT.x \
					and off.y <= Tuning.VIEW_HALF_EXTENT.y:
				seen_at = walked
			was_live = was_live or van.was_live

	func outcome() -> String:
		if van == null:
			return "marble not drawn"
		if not van.is_placed():
			return "drawn, never sited"
		if seen_at >= 0.0:
			return "seen"
		return "sited, never in view"

	func detail() -> String:
		var where := "-"
		if van and van.is_placed():
			where = "sited %.0fs into her walk, %.0fpx from her (straight); nearest she came %.0fpx after %.0fpx more walking; streamed in %s" \
					% [sited_at, ahead_at_siting, nearest_after, walked_after_siting, was_live]
		var waits: Dictionary = city.events._siting.waits if city.events._siting else {}
		return "walked %.0fs, drawn at %.0fs (%s), sited %s | %s | waits %s | seen at %s" % [walked,
				drawn_at, drawn_phase, sited_phase, where, waits,
				"%.0fs" % seen_at if seen_at >= 0.0 else "never"]

## The shortest walkable path from `from` to the nearest of `goals`, as tile centres, over ground
## that is walkable, open and unobstructed today.
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

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("day7-van-met:%d:%d:%s" % [seed_value, day, stream])
	return rng

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
