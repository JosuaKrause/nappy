extends RefCounted
## Day 6's second man shouting is one she meets *(olive-koala, statement 2: "the yeller is
## guaranteed to encounter a yeller in the next three events")*, and the draw that stands him need
## not happen where she reads the mark *(inbox #1520 in breezy-magpie: "the draw doesn't have to
## happen at the point where she touches the mark. the bag gets the biased bag in front (via the
## chained bags mechanism) and the next draw (whenever that happens) will guarantee the shouting
## man")*. Reading the mark rigs a bag in front of the units' draws (`EventManager.rig_the_next_draw()`,
## `UnitDraw.rig_the_next_draw()`), and the next unit to draw that can stand him draws him first.
##
## **What is checked is the guarantee, on every walk**: once she has read the mark, a unit drawn
## after it draws him out of the bag in front (`UnitDraw.drew_from_the_front()`), standing out of her
## view on the tick it draws (what he draws, `EventFootprints.footprint_of()` at his place, misses the
## camera's view round her, `Tuning.VIEW_HALF_EXTENT`), so he is never seen to appear; and once she
## is within `Tuning.EVENT_STREAM_RADIUS` of him, one of the world's men shouting stands there
## (`EventManager.instances()`). Whether she then meets him is her walk's: the unit that draws next
## lies wherever her walk takes the streaming band, and `tests/probes/calm_pelican_day7_van_met.gd`
## measures how often a played walk sees him.
##
## Walks the way `--route mark,task,calm,home` does, at `Tuning.WALK_SPEED`, running what the
## manager's own tick runs for her walk, the units drawing as she comes near them
## (`EventManager.stream_around()`), so he is drawn where a played day draws him; and where that
## walk ends before he is drawn, on walking toward the nearest unit that has not drawn, until he is,
## since only a unit that draws can stand him and the ground she has walked has drawn. A sweep
## of the walks, not one: which unit draws next depends on the city. Run by name:
## `tools/test.sh day6_yeller_met`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 31337, 555, 99]
const DAY := 6
## The seed of the run each walk's city stands in, fixed so a walk repeats. The check does not depend
## on it: it holds on seed 1 as well.
const RUN_SEED := 2
const ROW := "homeless_yeller"
const STEP := 0.1
const SETTLE_SECONDS := 12.0
## How many more legs she walks, each to the nearest unit that has not drawn, where the walk ends
## before he is drawn.
const MORE_LEGS := 6

func run(t: TestRunner) -> void:
	var outcomes: Array[String] = []
	var kept := 0
	for seed_value in SEEDS:
		var outcome := _walk(t, seed_value)
		outcomes.append(outcome)
		if outcome == "kept":
			kept += 1
	t.check(kept == SEEDS.size(),
			"on every walk of day %d a unit drawn after the mark draws the rigged man shouting, out " % DAY
			+ "of her view, and he is in the world once she is within the stream radius of him (%s)"
			% [outcomes])

## "kept", "no mark", "never drawn", or what about where he was drawn broke the guarantee.
func _walk(t: TestRunner, seed_value: int) -> String:
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	RunCity.build(city, CityGenerator.generate(seed_value))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	RunCity.events(city).start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), consumed)
	# The units draw as she walks; the man the mark rigged is the one a unit drew out of the bag in
	# front (`_the_rigged_man()`).
	var draw := RunCity.events(city).walk_events().unit_draw()
	# The days behind her, completed the way the game completes them.
	for step in ResistanceSteps.all():
		if step.day < DAY:
			city.run.complete_resistance_step(step.index, step.grants_progress)
	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city.map, city.run, RunCity.events(city), city.streets(), city.fronts(), city, null,
			RunCity.spawn_siting(city))
	resistance.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = city.map.doorstep_world_position()
	RunCity.events(city).use_player(player)
	var map := city.map
	var outcome := "no mark"
	var mark := resistance.current_step()
	if mark and mark.is_pickup:
		var seen := {"man": null, "read": false, "outcome": "never drawn", "streamed": false}
		var tick := func() -> void:
			var events := RunCity.events(city)
			events.ahead.site_what_is_on_her_way(STEP)
			events.ahead.place_what_is_owed_ahead(STEP)
			events.stream_around(player.global_position)
			if seen["read"] and seen["man"] == null:
				var man := _the_rigged_man(draw)
				if man:
					seen["man"] = man
					seen["outcome"] = "drawn in her view" if _in_the_cameras_view(man,
							player.global_position, player.velocity.normalized()) else "kept"
			var drawn_man: EventPlan = seen["man"]
			if drawn_man and not seen["streamed"] and seen["outcome"] == "kept" \
					and drawn_man.distance_from(player.global_position) < Tuning.EVENT_STREAM_RADIUS:
				seen["streamed"] = true
				seen["outcome"] = _in_the_world(events, drawn_man)
		_along(player, _path(map, player.global_position, [map.world_to_tile(
				resistance.contact_position())]), tick)
		resistance.contact().complete_now()
		seen["read"] = true
		seen["drawn_at_the_mark"] = _drawn_count(draw)
		var task_man: EventInstance = resistance.rider()
		if task_man:
			_along(player, _path(map, player.global_position, _beside(map,
					task_man.global_position)), tick)
		_along(player, _path(map, player.global_position, map.calm_tiles()), tick)
		player.velocity = Vector2.ZERO
		for i in int(SETTLE_SECONDS / STEP):
			tick.call()
		var home: Array[Vector2i] = [map.world_to_tile(map.doorstep_world_position())]
		_along(player, _path(map, player.global_position, home), tick)
		# Where the walk home ends before he is drawn, she walks on toward ground that has not
		# drawn, until he is.
		var legs := 0
		while seen["man"] == null and legs < MORE_LEGS:
			var toward := _undrawn_ground(map, draw, player.global_position)
			if toward.is_empty():
				break
			_along(player, _path(map, player.global_position, toward), tick)
			legs += 1
		outcome = seen["outcome"]
		if seen["man"] == null:
			outcome += " (%d units drew after the mark)" % (_drawn_count(draw) - int(seen["drawn_at_the_mark"]))
	player.free()
	resistance.free()
	city.free()
	return outcome

## The walkable tiles of the nearest unit that has not drawn, or none where every unit has.
func _undrawn_ground(map: CityMap, draw: UnitDraw, her: Vector2) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for unit in draw.units().undrawn_within(her, INF):
		var rect := unit.tiles()
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var tile := Vector2i(x, y)
				if map.is_walkable(tile) and not map.is_obstructed(tile) and not map.is_closed(tile):
					found.append(tile)
		if not found.is_empty():
			return found
	return found

## How many of the day's units have drawn.
func _drawn_count(draw: UnitDraw) -> int:
	var count := 0
	for unit in draw.units().all():
		if unit.is_drawn():
			count += 1
	return count

## The man shouting a unit drew out of the bag in front (`UnitDraw.drew_from_the_front()`), or null
## while no unit has.
func _the_rigged_man(draw: UnitDraw) -> EventPlan:
	for unit in draw.units().all():
		for plan in unit.drawn():
			if plan.row_id() == ROW and draw.drew_from_the_front(plan):
				return plan
	return null

## "kept" when one of the world's men shouting stands where `man` was drawn (within a tile, the
## band middle a pacing body is laid on), or what is wrong.
func _in_the_world(events: EventManager, man: EventPlan) -> String:
	var nearest := INF
	for instance in events.instances():
		if instance.def.id == ROW:
			nearest = minf(nearest, instance.global_position.distance_to(man.placed_at()))
	if nearest == INF:
		return "drawn but not in the world once she was near"
	if nearest > Tuning.TILE_SIZE:
		return "in the world %.0fpx from where he was drawn" % nearest
	return "kept"

## Whether any of what the man draws, standing where he was drawn, meets the camera's view round
## `her`, led `Stroller.CAMERA_LOOK_AHEAD` along her `heading` as the camera leads her.
func _in_the_cameras_view(man: EventPlan, her: Vector2, heading: Vector2) -> bool:
	var box := EventFootprints.footprint_of(man.row())
	var drawn := Rect2(man.placed_at() + box.position, box.size) if box.has_area() \
			else Rect2(man.placed_at(), Vector2.ZERO)
	var lead := Vector2(heading.x, heading.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	return Rect2(her + lead - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0) \
			.intersects(drawn, true)

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
