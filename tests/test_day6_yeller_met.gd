extends RefCounted
## Day 6's second man shouting is one she meets *(olive-koala, statement 2: "the yeller is
## guaranteed to encounter a yeller in the next three events")*. Reading the mark rigs her route's
## bag so his marble is one of the next `ResistanceSteps.TASK_CONTACT_WITHIN_THE_NEXT` events handed
## out on her route (`MarbleBag.rig()`, `EventDirector.rig_her_route()`), and when his marble comes
## up he is sited on the street she is walking (`WalkSiting.ahead_on_her_street()`): ahead of her,
## just out of her sight and inside the streaming radius, in the world at once.
##
## **What is checked is the guarantee, on every walk**: once she has read the mark, he is sited
## while no more than that many events have been handed out on her route since (`EventManager.
## owed_ahead()` counts down one for each), ahead of her along her line of travel, on her street
## (no further across it than `HER_STREET_HALF_WIDTH`), out of her view
## (`WalkSiting.could_be_in_her_view()`) and within `Tuning.EVENT_STREAM_RADIUS` of her, and on the
## same tick one of the world's men shouting stands there (`EventManager.instances()`). Whether
## she then sees him is her walk's: a walk that turns off her street before it reaches him passes
## him by, and `tests/probes/calm_pelican_day7_van_met.gd` measures how often a played walk does.
##
## Walks the way `--route mark,task,calm,home` does, at `Tuning.WALK_SPEED`, running what the
## manager's own tick runs for her walk, so he is sited where a played day sites him; and where that
## walk ends before he is sited, on walking, back to the mark and home again, until he is, since the
## guarantee counts events and a walk that ends first owes nothing (a third event handed out before
## his siting still fails him). A sweep of
## the walks, not one: where she is when his marble comes up depends on the city. Run by name:
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
## How many more legs she walks, mark and home in turn, where the walk ends before he is sited:
## enough for the next events at `EventDirector.AHEAD_INTERVAL`'s pace on the pinned
## cities, where only city 555 walks on, for one leg.
const MORE_LEGS := 6
## The street she is on, from her sidewalk to the far kerb, either side of her line of travel: the
## width `WalkSiting.ahead_on_her_street()` looks across.
const HER_STREET_HALF_WIDTH := 5.0 * Tuning.TILE_SIZE

func run(t: TestRunner) -> void:
	var outcomes: Array[String] = []
	var kept := 0
	for seed_value in SEEDS:
		var outcome := _walk(t, seed_value)
		outcomes.append(outcome)
		if outcome == "kept":
			kept += 1
	t.check(kept == SEEDS.size(),
			"on every walk of day %d the rigged man shouting is sited ahead of her on her street, out " % DAY
			+ "of sight and in the world, within the next %d events after the mark (%s)"
			% [ResistanceSteps.TASK_CONTACT_WITHIN_THE_NEXT, outcomes])

## "kept", "no mark", "never sited", or what about his first siting broke the guarantee.
func _walk(t: TestRunner, seed_value: int) -> String:
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), consumed)
	# The days behind her, completed the way the game completes them.
	for step in ResistanceSteps.all():
		if step.day < DAY:
			city.run.complete_resistance_step(step.index, step.grants_progress)
	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city.map, city.run, city.events, city.streets(), city.fronts(), city, null,
			city.spawn_siting)
	resistance.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = city.map.doorstep_world_position()
	city.events.use_player(player)
	var map := city.map
	var outcome := "no mark"
	var mark := resistance.current_step()
	if mark and mark.is_pickup:
		var seen := {"man": null, "standing": [], "read": false, "owed": 0, "outcome": "never sited",
				"to_stream": false}
		var tick := func() -> void:
			var events := city.events
			events.ahead.site_what_is_on_her_way(STEP)
			var sited_now := false
			if seen["man"] == null and seen["read"]:
				for plan: EventScheduler.Planned in events.plans():
					if plan.def.id == ROW and not (seen["standing"] as Array).has(plan):
						seen["man"] = plan
						seen["outcome"] = _first_siting(plan, player,
								int(seen["owed"]) - events.owed_ahead())
						sited_now = true
			events.ahead.place_what_is_owed_ahead(STEP)
			events.stream_around(player.global_position)
			# In the world on the tick he is sited, standing where he was sited.
			if sited_now and seen["outcome"] == "kept":
				seen["outcome"] = _in_the_world(events, seen["man"])
		_along(player, _path(map, player.global_position, [map.world_to_tile(
				resistance.contact_position())]), tick)
		resistance.contact().complete_now()
		# The dawn's rows and the task's own man; a man not among them was put on her route.
		seen["standing"] = city.events.plans().duplicate()
		seen["read"] = true
		seen["owed"] = city.events.owed_ahead()
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
		# The guarantee counts events after the mark, not the walk: where the walk home ends before
		# he is sited, she walks on, back to the mark and home again, until he is.
		var mark_tile: Array[Vector2i] = [map.world_to_tile(resistance.contact_position())]
		var legs := 0
		while seen["man"] == null and legs < MORE_LEGS:
			_along(player, _path(map, player.global_position, home if legs % 2 == 1 else mark_tile),
					tick)
			legs += 1
		outcome = seen["outcome"]
	player.free()
	resistance.free()
	city.free()
	return outcome

## "kept" when one of the world's men shouting stands where `man` was sited (within a tile, the
## band middle a pacing body is laid on), or what is wrong.
func _in_the_world(events: EventManager, man: EventScheduler.Planned) -> String:
	var nearest := INF
	for instance in events.instances():
		if instance.def.id == ROW:
			nearest = minf(nearest, instance.global_position.distance_to(man.placed_at()))
	if nearest == INF:
		return "sited but not in the world"
	if nearest > Tuning.TILE_SIZE:
		return "in the world %.0fpx from where he was sited" % nearest
	return "kept"

## Whether the man's first siting keeps the guarantee: "kept", or what it broke. `handed` is how
## many events her route had been handed since the mark was read when he was sited.
func _first_siting(man: EventScheduler.Planned, player: Stroller, handed: int) -> String:
	if handed > ResistanceSteps.TASK_CONTACT_WITHIN_THE_NEXT:
		return "sited after %d events" % handed
	var offset := man.position - player.global_position
	var heading := player.velocity.normalized()
	if offset.dot(heading) <= 0.0:
		return "sited behind her"
	if absf(offset.cross(heading)) > HER_STREET_HALF_WIDTH:
		return "sited off her street"
	if EventScheduler.WalkSiting.could_be_in_her_view(man.def, man.position, player.global_position):
		return "sited in her view"
	if offset.length() > Tuning.EVENT_STREAM_RADIUS:
		return "sited past the streaming radius"
	return "kept"

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
