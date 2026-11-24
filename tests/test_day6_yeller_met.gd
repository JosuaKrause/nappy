extends RefCounted
## Day 6's second man shouting is one she meets *(olive-koala, statement 2: "the yeller is
## guaranteed to encounter a yeller in the next three events")*: reading the mark rigs her route's
## bag with him, so his marble is one of the next `ResistanceSteps.TASK_CONTACT_WITHIN_THE_NEXT`
## events handed out on her route *(inbox #1520 in breezy-magpie: "the bag gets the biased bag in
## front (via the chained bags mechanism) and the next draw (whenever that happens) will guarantee
## the shouting man")*, and when it comes up he is laid only on her path and just ahead of her
## *(inbox #1549: "you would draw only for the path and only just ahead")*
## (`EventManager.rig_her_route()`, `WalkSiting.lay_just_ahead()`). The walk after the mark lasts
## until his marble is handed out, at most that many handouts.
##
## **What is checked is the meeting, on every walk**: reading the mark, then walking the day's
## longest route out and back until he is laid and on the way she was heading after that (keeping on
## her way, which is what the rule promises; a fork of her branch she turns off at is a walk the
## probe below measures), her walk lays him with none of what he draws
## (`EventFootprints.footprint_of()` at his place) in the camera's view round her, led along her
## heading, so he is never seen to appear; he then comes into her view (`Tuning.VIEW_HALF_EXTENT`
## round her); and once she is within `Tuning.EVENT_STREAM_RADIUS` of him, one of the world's men
## shouting stands there (`EventManager.instances()`), a check that runs on every walk. How often a
## walk that leaves her branch sees him is `tests/probes/calm_pelican_day7_van_met.gd`'s to measure.
##
## Runs what the manager's own tick runs for her walk, at `Tuning.WALK_SPEED`, the units drawing as
## she comes near them (`EventManager.stream_around()`). Combines the director, the siting and the
## streaming on a real city on purpose: the guarantee is the meeting, which spans them. A sweep of
## cities, not one: where he can stand depends on the city. Run by name:
## `tools/test.sh day6_yeller_met`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 31337, 555, 99]
const DAY := 6
## The seed of the run each walk's city stands in, fixed so a walk repeats.
const RUN_SEED := 2
const ROW := "homeless_yeller"
const STEP := 0.1

func run(t: TestRunner) -> void:
	var outcomes: Array[String] = []
	var kept := 0
	var in_the_world_asked := 0
	for seed_value in SEEDS:
		var walk := _walk(t, seed_value)
		outcomes.append(walk[0])
		if walk[0] == "kept":
			kept += 1
		if walk[1]:
			in_the_world_asked += 1
	t.check(kept == SEEDS.size(),
			"on every walk of day %d her walk lays the rigged man shouting out of her view, he comes " % DAY
			+ "into her view, and he is in the world once she is within the stream radius of him (%s)"
			% [outcomes])
	t.check(in_the_world_asked == SEEDS.size(),
			"and whether he is in the world was asked on every walk (%d of %d)"
			% [in_the_world_asked, SEEDS.size()])

## `[outcome, whether the in-the-world check ran]`: "kept", "no mark", "never laid", or what broke
## the guarantee.
func _walk(t: TestRunner, seed_value: int) -> Array:
	var run := RunCity.started_run(RUN_SEED)
	var city: City = RunCity.in_run(CITY_SCENE, run)
	t.add_child(city)
	RunCity.build(city, run, CityGenerator.generate(seed_value))
	# What the events tell the run log: a place is put on her route when a line says so.
	var put_down: Array[String] = []
	RunCity.events(city).world.surroundings().tracing_to(RecordingTrace.new(put_down))
	var state := CityState.new()
	state.begin_day(city.map().plans_by_block(), DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	RunCity.events(city).start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), consumed)
	# The days behind her, completed the way the game completes them.
	for step in ResistanceSteps.all():
		if step.day < DAY:
			run.complete_resistance_step(step.index, step.grants_progress)
	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city.map(), run, RunCity.events(city), city.streets(), city.fronts(), city, null,
			RunCity.spawn_siting(city))
	resistance.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	RunCity.events(city).use_player(player)
	var outcome := "no mark"
	var asked := false
	var mark := resistance.current_step()
	var path := _the_longest_route(city)
	if mark and mark.is_pickup and path.size() >= 2:
		# Out from the doorstep end and back, so she is never put down on ground that has not drawn.
		resistance.contact().complete_now()
		var back := path.duplicate()
		back.reverse()
		path.append_array(back)
		player.global_position = path[0]
		var seen := {"man": null, "outcome": "never laid", "met": false, "asked": false,
				"nearest": INF, "laid": ""}
		var tick := func() -> void:
			var events := RunCity.events(city)
			# The tick's stretch from her camera's view to what is owed, in the tick's own order.
			events.step_what_is_ahead(STEP)
			var man: EventPlan = seen["man"]
			if man == null:
				man = _the_rigged_man(city, put_down)
				if man == null:
					return
				seen["man"] = man
				seen["laid"] = "she at %s heading %s, he at %s" % [player.global_position,
						player.velocity.normalized(), man.placed_at()]
				seen["outcome"] = "laid in her view" if _in_the_cameras_view(man,
						player.global_position, player.velocity.normalized()) \
						else "laid, never in her view"
			if seen["outcome"] == "laid in her view":
				return
			seen["nearest"] = minf(float(seen["nearest"]),
					man.placed_at().distance_to(player.global_position))
			var off := (man.placed_at() - player.global_position).abs()
			if off.x <= Tuning.VIEW_HALF_EXTENT.x and off.y <= Tuning.VIEW_HALF_EXTENT.y:
				seen["met"] = true
			if not seen["asked"] \
					and man.distance_from(player.global_position) < Tuning.EVENT_STREAM_RADIUS:
				seen["asked"] = true
				var in_world := _in_the_world(events, man)
				seen["outcome"] = in_world if in_world != "kept" else "kept, not yet met"
			if seen["met"] and seen["outcome"] == "kept, not yet met":
				seen["outcome"] = "kept"
		# Her branch until he is laid, then on the way she was heading: what the rule promises
		# (`WalkSiting.lay_just_ahead()`) is that keeping on her way brings him into view.
		for point in path:
			if seen["man"] != null:
				break
			_along(player, [point] as Array[Vector2], tick)
		if seen["man"] != null:
			var heading := player.velocity.normalized()
			_along(player, [player.global_position + heading * WalkSiting.JUST_AHEAD] as Array[Vector2],
					tick)
		outcome = seen["outcome"]
		if outcome != "kept" and seen["man"] != null:
			outcome += " (%s; nearest she came %.0fpx)" % [seen["laid"], float(seen["nearest"])]
		asked = bool(seen["asked"])
	player.free()
	resistance.free()
	city.free()
	return [outcome, asked]

## The man shouting the mark rigged once her walk has laid him (the walk's plan of the row whose
## place the run log says was put on her route), or null while he is not laid.
func _the_rigged_man(city: City, put_down: Array[String]) -> EventPlan:
	var events := RunCity.events(city)
	for plan in events.walk_events().plans():
		if plan.row_id() == ROW and plan.is_placed() \
				and PutOnHerRoute.says(put_down, city.map(), plan):
			return plan
	return null

## "kept" when one of the world's men shouting stands where `man` was laid (within a tile, the
## band middle a pacing body is laid on), or what is wrong.
func _in_the_world(events: EventManager, man: EventPlan) -> String:
	var nearest := INF
	for instance in events.instances():
		if instance.row_id() == ROW:
			nearest = minf(nearest, instance.global_position.distance_to(man.placed_at()))
	if nearest == INF:
		return "laid but not in the world once she was near"
	if nearest > Tuning.TILE_SIZE:
		return "in the world %.0fpx from where he was laid" % nearest
	return "kept"

## Whether any of what the man draws, standing where he was laid, meets the camera's view round
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

## The cell centres of the day's longest route, from the doorstep end out — the walk she takes.
func _the_longest_route(city: City) -> Array[Vector2]:
	var tree := city.streets().route_tree()
	var longest: Array = []
	for branch in tree.branches():
		for route: Array in branch.routes:
			if route.size() > longest.size():
				longest = route
	var points: Array[Vector2] = []
	for i in range(longest.size() - 1, -1, -1):
		points.append(tree.cell_centre(longest[i]))
	return points

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("day7-van-met:%d:%d:%s" % [seed_value, DAY, stream])
	return rng
