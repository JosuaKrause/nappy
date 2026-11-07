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
## along her heading (`Stroller._update_camera()`'s lead), and the director's own ticks
## (`ResistanceDirector.tick()`, the step `main` runs every physics tick) run the arrow to rest and
## make one more of its choices, each of which asks the guard to follow it. She arrives within
## `ARRIVED` px of the roadblock's body. Each city stands in a run of its own
## (`RunCity.with_own_run()`); she is handed to the director and the events as `main` hands her; the
## guard is the live `task_guard` among the city's instances, and the arrow's roadblock the instance
## its `_arrow_key` names.
##
## **On arrival** the guard is counted as:
## - **guarding** the roadblock the arrow points at: in its band (`inner_radius` plus its touch reach
##   to `EventDef.notice` plus it), with a clear line to its body;
## - **near it**: with a clear line to it, outside the band but within
##   `ResistanceDirector.TASK_GUARD_FARTHEST`, the farther out-of-view spot a move takes when every
##   spot of the band is in her view;
## - **elsewhere**: anywhere else, with his distance from the arrow's.
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
## The seed of each city's own run: the one the test runner starts the live run on.
const RUN_SEED := 2

func run(t) -> void:
	var totals := {"walks": 0, "guarding": 0, "near": 0, "elsewhere": 0, "none": 0, "moves": 0,
			"noticed": 0, "on_his_tile": 0, "no_way": 0, "placed": 0, "placed_without_a_way": 0}
	var elsewhere: Array[String] = []
	for seed_value in SEEDS:
		var day := _read_the_mark(t, seed_value)
		if day.is_empty():
			print("DAY13_GUARD seed %d: no roadblock task" % seed_value)
			continue
		var targets := _nearest_on_foot(day)
		var placed := _task_guard(day["city"])
		var own: EventInstance = day["director"].rider()
		var way := _a_way_past_from(day["city"].map, placed, own, day["mark"])
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

## A day 13 on `seed_value` with the mark read from where it stands: `{city, director, player,
## step, mark}`, or empty when the day offers no roadblock task.
func _read_the_mark(t, seed_value: int) -> Dictionary:
	var city := RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
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
	city.events.visible_view().look(_view_of(player), null)
	director.set_sight(city.events.sees)
	director.contact().complete_now()
	var step := director.current_step()
	if step == null or step.task_event_id != "roadblock" or _task_guard(city) == null:
		_tear_down(day)
		return {}
	_settle_the_arrow(director)
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
	var map: CityMap = day["city"].map
	var by_length: Array = []
	for target: Dictionary in _arrow_targets(director):
		var roadblock := _live_instance(target["key"])
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
	var city: City = day["city"]
	var map: CityMap = city.map
	var target: EventInstance = null
	for candidate: Dictionary in _arrow_targets(director):
		var roadblock := _live_instance(candidate["key"])
		if roadblock and map.world_to_tile(roadblock.body_position()) == tile:
			target = roadblock
	if target == null:
		return {}
	var path := _path_toward(map, day["mark"], target.body_position())
	if path.is_empty():
		return {}
	var moves := 0
	var guard := _task_guard(city)
	var guard_at := guard.global_position if guard else Vector2.INF
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
			_settle_the_arrow(director)
			_choose_again(director)
			if _task_guard(city) != guard or (guard and guard.global_position != guard_at):
				moves += 1
				guard = _task_guard(city)
				guard_at = guard.global_position if guard else Vector2.INF
			var arrow := _live_instance(director._arrow_key)
			var her := player.global_position
			if guard and arrow and her.distance_to(arrow.body_position()) \
					> ResistanceDirector._touch_reach(arrow):
				var off := her.distance_to(guard.global_position)
				nearest = minf(nearest, off)
				if off <= notice and map.clear_line(guard.global_position, her):
					noticed = true
			next_choice += STEP
		walked += length
	player.global_position = points.back()
	_settle_the_arrow(director)
	_choose_again(director)
	if _task_guard(city) != guard or (guard and guard.global_position != guard_at):
		moves += 1
	var result := _what_he_guards(city, director, moves)
	result["noticed"] = noticed
	result["nearest"] = nearest
	result["way"] = _a_way_past_from(map, _task_guard(city), _live_instance(director._arrow_key),
			day["mark"])
	return result

## Whether some walk from `from` reaches ground within touch reach of `roadblock` without her
## centre coming within `guard`'s `EventDef.notice` along a clear line: a flood fill over open,
## unobstructed walkable tiles, never onto a tile his notice reaches. Yes with either missing.
static func _a_way_past_from(map: CityMap, guard: EventInstance, roadblock: EventInstance,
		from: Vector2) -> bool:
	if guard == null or roadblock == null:
		return true
	var notice := EventCatalogue.by_id("alley_robbery").notice_within()
	var reach := ResistanceDirector._touch_reach(roadblock)
	var body := roadblock.body_position()
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

func _what_he_guards(city: City, director: ResistanceDirector, moves: int) -> Dictionary:
	var guard := _task_guard(city)
	var arrow := _live_instance(director._arrow_key)
	if guard == null or arrow == null:
		return {"kind": "none", "from_arrow": -1.0, "clear": false, "moves": moves}
	var robbery := EventCatalogue.by_id("alley_robbery")
	var reach := ResistanceDirector._touch_reach(arrow)
	var from_arrow := guard.global_position.distance_to(arrow.body_position())
	var clear := city.map.clear_line(guard.global_position, arrow.body_position())
	var kind := "elsewhere"
	if from_arrow >= robbery.inner_radius + reach - 0.5 \
			and from_arrow <= robbery.notice_within() + reach + 0.5 and clear:
		kind = "guarding"
	elif clear and from_arrow <= ResistanceDirector.TASK_GUARD_FARTHEST + 0.5:
		kind = "near"
	return {"kind": kind, "from_arrow": from_arrow, "clear": clear, "moves": moves}

## The task's guard as the street has him: the live `task_guard` among `city`'s instances, or null.
static func _task_guard(city: City) -> EventInstance:
	for instance in city.events.instances():
		if instance.def.id == EventCatalogue.task_guard().id and not instance.is_finished:
			return instance
	return null

## The live instance an arrow key names (an instance id), or null.
static func _live_instance(key: Variant) -> EventInstance:
	if not key is int:
		return null
	var found := instance_from_id(key)
	if not is_instance_valid(found) or not found is EventInstance \
			or (found as EventInstance).is_finished:
		return null
	return found as EventInstance

## Runs the arrow to rest the way the game does: it chooses, then the physics ticks `main` runs sweep
## its walking fields a slice at a time, choosing again as each finishes, until none is under way.
static func _settle_the_arrow(director: ResistanceDirector) -> void:
	director._retarget_the_arrow()
	var ticks := 0
	while _arrow_sweeping(director) and ticks < 1200:
		director.tick(1.0 / Engine.physics_ticks_per_second)
		ticks += 1

## One of the arrow's choices: a tick as long as its clock, which chooses again and asks the guard
## to follow it.
static func _choose_again(director: ResistanceDirector) -> void:
	director.tick(ResistanceDirector.ARROW_RETARGET_SECONDS)

func _start_the_day(t, city: City, director: ResistanceDirector, seed_value: int) -> Stroller:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	var run: RunState = city.run
	run.resistance.completed_steps.assign(done)
	var state := CityState.new()
	run.attempt_spend.city_state = state
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
	director.use_player(player)
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

## `ResistanceDirector`'s places that answer today's task, as the arrow chooses among them
## (`_arrow_candidates()`): empty with no step on offer or one a single place answers. The probe
## reads the director's private state, which the director offers no query of.
static func _arrow_targets(director: ResistanceDirector) -> Array[Dictionary]:
	var step := director.current_step()
	if step == null or not ResistanceSteps.answers_at_several_places(step):
		var none: Array[Dictionary] = []
		return none
	return director._arrow_candidates(step)

## Whether a sweep of the arrow's walking fields is under way (`ResistanceDirector._arrow_*_next`).
static func _arrow_sweeping(director: ResistanceDirector) -> bool:
	return director._arrow_nearest_next != null or director._arrow_own_next != null
