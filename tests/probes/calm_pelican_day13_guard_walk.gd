extends RefCounted
## Measurement probe for calm-pelican's day-13 guard (the-arrow-and-the-day-13-guard): walked from
## the mark to each of the nearest live roadblocks, **does the task's waiting guard stand over the
## roadblock the red arrow points at when she arrives?** *(inbox #651 in lilac-marmot: "just move
## the guard always to any roadblock she approaches. We can move the guard around offscreen as much
## as we want. If we need to move multiple times so be it".)* Not a suite: it prints counts rather
## than asserting them, so it lives under `tests/probes/` and runs only by name:
##
##     tools/test.sh probes/calm_pelican_day13_guard_walk.gd      (prints DAY13_GUARD lines)
##
## **The rig.** Per seed, a real city through the real day order (`CityState.begin_day()`,
## `City.start_day()`, `EventManager.start_day()`, then the director), her standing on the mark and
## the mark read, as `calm_pelican_day13_roadblock.gd` rigs it. Then, for each of the `NEAREST`
## live roadblocks nearest the mark on foot, the day is built afresh and she walks a tile path from
## the mark toward it. Every `STEP` px of walking — the arrow's own half-second retarget at her
## walking speed — the camera's view is the 640x360 box round her led `Stroller.CAMERA_LOOK_AHEAD`
## along her heading (`Stroller._update_camera()`'s lead), and the director does what `_process()`
## does on the arrow's clock: settles the arrow (`_settle_the_arrow()`) and asks the guard to follow
## it (`_move_the_task_guard_to_her_target()`). She arrives within `ARRIVED` px of the roadblock's
## body.
##
## **On arrival** the guard is counted as:
## - **guarding** the roadblock the arrow points at: over it, in its band (`inner_radius` plus its
##   touch reach to `EventDef.notice` plus it), with a clear line to its body;
## - **near it**: over it, outside the band, the farther out-of-view spot a move takes when every
##   spot of the band is in her view;
## - **elsewhere**: over another roadblock, with his distance from the arrow's.
## A guard who noticed her is not ticked in this rig, so none is.
##
## **And whether he stands on her way** (review of #659): on each step before she is within touch
## reach of the arrow's roadblock, whether she is within his `EventDef.notice` along a clear line
## (`CityMap.clear_line()`) — her shortest walk passing his notice — and how near she comes to his
## feet; and, on arrival, whether any walk from the mark reaches touch range without entering his
## notice (a flood fill of this file's own, tile centres, around closures and standing bodies).

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const DAY := 13
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024, 555, 8080, 99, 123456,
		271828, 314159]
## How many of the live roadblocks nearest the mark on foot she walks to, each on a fresh day.
const NEAREST := 4
## How far she walks between two of the arrow's choices: `ResistanceDirector.ARROW_RETARGET_SECONDS`
## at her walking speed, 0.5s at 92px/s.
const STEP := 46.0
## How near the roadblock's body she has arrived: within its touch reach, a little over.
const ARRIVED := 160.0

func run(t) -> void:
	var saved_completed := GameState.resistance.completed_steps.duplicate()
	var saved_failed := GameState.resistance.failed_steps.duplicate()
	var saved_progress := GameState.resistance.progress
	var saved_scars := GameState.attempt_spend.scars.duplicate()
	var saved_alleys := GameState.facts.completed_resistance_alley_tiles.duplicate()
	var saved_state := GameState.attempt_spend.city_state
	var totals := {"walks": 0, "guarding": 0, "near": 0, "elsewhere": 0, "none": 0, "moves": 0,
			"noticed": 0, "on_his_tile": 0, "no_way": 0, "placed": 0, "placed_without_a_way": 0}
	var elsewhere: Array[String] = []
	for seed_value in SEEDS:
		var day := _read_the_mark(t, seed_value)
		if day.is_empty():
			print("DAY13_GUARD seed %d: no roadblock task" % seed_value)
			continue
		var targets := _nearest_on_foot(day)
		var placed: EventInstance = day["director"]._task_guard
		var own: EventInstance = day["director"]._rider
		var way: bool = day["director"]._leaves_her_a_way_past(placed.global_position,
				own.body_position(), ResistanceDirector._body_touch_reach(own), day["mark"],
				ResistanceDirector.HerSide.new(own.body_position(), day["mark"]))
		totals["placed"] += 1
		totals["placed_without_a_way"] += 0 if way else 1
		_tear_down(day)
		for index in targets.size():
			var walk := _read_the_mark(t, seed_value)
			if walk.is_empty():
				continue
			var result := _walk_to(walk, targets[index])
			_tear_down(walk)
			if result.is_empty():
				print("DAY13_GUARD seed %d walk to roadblock %d (%s): not live on the rebuilt day"
						% [seed_value, index, targets[index]])
				continue
			totals["walks"] += 1
			totals[result["kind"]] += 1
			totals["moves"] += result["moves"]
			totals["noticed"] += 1 if result["noticed"] else 0
			totals["on_his_tile"] += 1 if result["nearest"] <= 16.0 else 0
			totals["no_way"] += 1 if not result["way"] else 0
			if result["kind"] == "elsewhere":
				elsewhere.append("seed %d %.0fpx" % [seed_value, result["from_arrow"]])
			print("DAY13_GUARD seed %d walk to roadblock %d (%s): %s, %.0fpx from the arrow's roadblock, clear line %s, %d moves; her walk in his notice before touch range %s, nearest his feet %.0fpx, a way past him from the mark %s" % [
					seed_value, index, targets[index], result["kind"], result["from_arrow"],
					result["clear"], result["moves"], result["noticed"], result["nearest"],
					result["way"]])
	print("DAY13_GUARD %d arrivals: guarding %d, near it outside the band %d, elsewhere %d %s, no guard %d | %d moves | her shortest walk in his notice before touch range %d, within 16px of his feet %d, no way past him from the mark %d | guards placed with the task %d, of them with no way past (the fallback) %d"
			% [totals["walks"], totals["guarding"], totals["near"], totals["elsewhere"], elsewhere,
			totals["none"], totals["moves"], totals["noticed"], totals["on_his_tile"],
			totals["no_way"], totals["placed"], totals["placed_without_a_way"]])
	GameState.resistance.completed_steps.assign(saved_completed)
	GameState.resistance.failed_steps.assign(saved_failed)
	GameState.resistance.progress = saved_progress
	GameState.attempt_spend.scars.assign(saved_scars)
	GameState.facts.completed_resistance_alley_tiles.assign(saved_alleys)
	GameState.attempt_spend.city_state = saved_state

## A day 13 on `seed_value` with the mark read from where it stands: `{city, director, player,
## step, mark}`, or empty when the day offers no roadblock task.
func _read_the_mark(t, seed_value: int) -> Dictionary:
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	GameState.attempt_spend.scars = []
	var director := ResistanceDirector.new()
	var player := _start_the_day(t, city, director, seed_value)
	var day := {"city": city, "director": director, "player": player}
	var mark := director.current_step()
	if mark == null or not mark.is_pickup:
		_tear_down(day)
		return {}
	var mark_at := director.contact_position()
	player.global_position = mark_at
	player.facing = Vector2.DOWN
	city.events.visible_view().look(_view_of(player))
	director.set_sight(city.events.sees)
	director._on_contact_completed(mark.index)
	var step := director.current_step()
	if step == null or step.task_event_id != "roadblock" or director._task_guard == null:
		_tear_down(day)
		return {}
	director._settle_the_arrow()
	day["step"] = step
	day["mark"] = mark_at
	return day

## The camera's view round her, led along her facing as `Stroller._update_camera()` leads it.
static func _view_of(player: Stroller) -> Rect2:
	var lead := Vector2(player.facing.x, player.facing.y * Stroller.OBLIQUE_Y) \
			* Stroller.CAMERA_LOOK_AHEAD
	return Rect2(player.global_position + lead - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2.0)

## The tiles of the `NEAREST` live roadblocks nearest the mark on foot, by their body's tile.
func _nearest_on_foot(day: Dictionary) -> Array[Vector2i]:
	var director: ResistanceDirector = day["director"]
	var map: CityMap = director._map
	var by_length: Array = []
	for target: Dictionary in director._arrow_candidates(day["step"]):
		var roadblock := ResistanceDirector._live_instance(target["key"])
		if roadblock == null:
			continue
		var path := _path_toward(map, day["mark"], roadblock.body_position())
		if path.is_empty():
			continue
		by_length.append([path.size(), map.world_to_tile(roadblock.body_position())])
	by_length.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var nearest: Array[Vector2i] = []
	for entry: Array in by_length.slice(0, NEAREST):
		nearest.append(entry[1])
	return nearest

## A tile path over open, unobstructed walkable ground from `from` until a tile within `ARRIVED`
## of `body`, breadth first; empty when none reaches it.
func _path_toward(map: CityMap, from: Vector2, body: Vector2) -> Array[Vector2i]:
	var start := map.world_to_tile(from)
	var came := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if map.tile_to_world(tile).distance_to(body) <= ARRIVED:
			var path: Array[Vector2i] = [tile]
			while path[0] != start:
				path.push_front(came[path[0]])
			return path
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + side
			if came.has(next) or not map.in_bounds(next) or not map.is_walkable(next) \
					or map.is_closed(next) or map.is_obstructed(next):
				continue
			came[next] = tile
			queue.append(next)
	return []

## Walks her from the mark toward the live roadblock whose body stands on `tile`, and answers what
## the guard is doing when she arrives: `{kind, from_arrow, clear, moves}`, or empty when that
## roadblock is not live on this day.
func _walk_to(day: Dictionary, tile: Vector2i) -> Dictionary:
	var director: ResistanceDirector = day["director"]
	var player: Stroller = day["player"]
	var map: CityMap = director._map
	var target: EventInstance = null
	for candidate: Dictionary in director._arrow_candidates(day["step"]):
		var roadblock := ResistanceDirector._live_instance(candidate["key"])
		if roadblock and map.world_to_tile(roadblock.body_position()) == tile:
			target = roadblock
	if target == null:
		return {}
	var path := _path_toward(map, day["mark"], target.body_position())
	if path.is_empty():
		return {}
	var moves := 0
	var guard: EventInstance = director._task_guard
	var points: Array[Vector2] = [day["mark"]]
	for step_tile in path:
		points.append(map.tile_to_world(step_tile))
	var walked := 0.0
	var next_choice := STEP
	var noticed := false
	var nearest := INF
	var notice := EventCatalogue.by_id("alley_robbery").notice_within()
	for i in range(1, points.size()):
		var from: Vector2 = points[i - 1]
		var to: Vector2 = points[i]
		var length := from.distance_to(to)
		if length <= 0.0:
			continue
		player.facing = (to - from) / length
		while next_choice <= walked + length:
			player.global_position = from.lerp(to, (next_choice - walked) / length)
			director._settle_the_arrow()
			director._move_the_task_guard_to_her_target()
			if director._task_guard != guard:
				moves += 1
				guard = director._task_guard
			var arrow := ResistanceDirector._live_instance(director._arrow_key)
			var her := player.global_position
			if guard and arrow and her.distance_to(arrow.body_position()) \
					> ResistanceDirector._body_touch_reach(arrow):
				var off := her.distance_to(guard.global_position)
				nearest = minf(nearest, off)
				if off <= notice and map.clear_line(guard.global_position, her):
					noticed = true
			next_choice += STEP
		walked += length
	player.global_position = points.back()
	director._settle_the_arrow()
	director._move_the_task_guard_to_her_target()
	if director._task_guard != guard:
		moves += 1
	var result := _what_he_guards(director, moves)
	result["noticed"] = noticed
	result["nearest"] = nearest
	result["way"] = _a_way_past(director, day["mark"])
	return result

## Whether some walk from `from` reaches ground within touch reach of the arrow's roadblock without
## her centre coming within the guard's `EventDef.notice` along a clear line: a flood fill over
## open, unobstructed walkable tiles, never onto a tile his notice reaches.
func _a_way_past(director: ResistanceDirector, from: Vector2) -> bool:
	var map: CityMap = director._map
	var guard: EventInstance = director._task_guard
	var arrow := ResistanceDirector._live_instance(director._arrow_key)
	if guard == null or arrow == null:
		return true
	var notice := EventCatalogue.by_id("alley_robbery").notice_within()
	var reach := ResistanceDirector._body_touch_reach(arrow)
	var body := arrow.body_position()
	var start := map.world_to_tile(from)
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if map.tile_to_world(tile).distance_to(body) <= reach:
			return true
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + side
			if seen.has(next):
				continue
			seen[next] = true
			if not map.in_bounds(next) or not map.is_walkable(next) or map.is_closed(next) \
					or map.is_obstructed(next):
				continue
			var at := map.tile_to_world(next)
			if at.distance_to(guard.global_position) <= notice \
					and map.clear_line(guard.global_position, at):
				continue
			queue.append(next)
	return false

func _what_he_guards(director: ResistanceDirector, moves: int) -> Dictionary:
	var guard: EventInstance = director._task_guard
	var arrow := ResistanceDirector._live_instance(director._arrow_key)
	if guard == null or not is_instance_valid(guard) or guard.is_finished or arrow == null:
		return {"kind": "none", "from_arrow": -1.0, "clear": false, "moves": moves}
	var robbery := EventCatalogue.by_id("alley_robbery")
	var reach := ResistanceDirector._body_touch_reach(arrow)
	var from_arrow := guard.global_position.distance_to(arrow.body_position())
	var clear := director._map.clear_line(guard.global_position, arrow.body_position())
	var over := ResistanceDirector._same_key(director._task_guard_over, director._arrow_key)
	var kind := "elsewhere"
	if over and from_arrow >= robbery.inner_radius + reach - 0.5 \
			and from_arrow <= robbery.notice_within() + reach + 0.5 and clear:
		kind = "guarding"
	elif over:
		kind = "near"
	return {"kind": kind, "from_arrow": from_arrow, "clear": clear, "moves": moves}

func _start_the_day(t, city: City, director: ResistanceDirector, seed_value: int) -> Stroller:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	GameState.resistance.completed_steps.assign(done)
	GameState.resistance.failed_steps.assign([])
	GameState.resistance.progress = 0
	# A read mark's alley is remembered and never chosen again, so each day built on one seed starts
	# from none remembered and reads the same mark.
	GameState.facts.completed_resistance_alley_tiles.assign([])
	var state := CityState.new()
	GameState.attempt_spend.city_state = state
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	city.events.start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), [], city.map.doorstep_world_position())
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	city.events.use_player(player)
	player.set_physics_process(false)
	player.global_position = city.map.doorstep_world_position()
	return player

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, DAY, stream])
	return rng

func _tear_down(day: Dictionary) -> void:
	(day["player"] as Stroller).free()
	(day["director"] as ResistanceDirector).free()
	(day["city"] as City).free()
