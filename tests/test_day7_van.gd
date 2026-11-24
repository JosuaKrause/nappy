extends RefCounted
## Day 7's van gets a second instance on her way, from a rigged bag *(inbox #586 in
## olive-hedgehog: "each olive badger rigged bag should be 2 or 3"; inbox #650 in mossy-beaver: "I
## guess that leaves only the van?")*, laid when its marble is handed out on her route, just ahead of her
## *(inbox #1520 in breezy-magpie, of day 6's man shouting and day 7's van: "the bag gets the biased
## bag in front (via the chained bags mechanism) and the next draw (whenever that happens) will
## guarantee the shouting man"; inbox #1549: "you would draw only for the path and only just
## ahead")*.
##
## Holds, through a real city: reading day 7's mark rigs her route's bag with one `delivery_van`,
## so its marble is one of the next `ResistanceSteps.VAN_WITHIN_THE_NEXT` events handed out on it
## (`EventManager.rig_her_route()`); walking the day's longest route until it is handed out and
## laid, and on the way she was heading after that (keeping on her way, which is what the rule
## promises; a fork of her branch she turns off at is a walk the probe below measures), she meets it: her walk lays it straight ahead of her on her branch (`WalkSiting.lay_just_ahead()`)
## with no part of what it draws in the camera's view of her on the tick it is laid, and keeping on
## her way brings it into her view (`Tuning.VIEW_HALF_EXTENT` round her). It is laid under the day's
## rules a unit's own van is under: on no tile a route of the day runs along, cutting none of the
## day's routes and leaving her a way home and a way to it — while the van the task rides, placed
## near the mark, stays where it is. How often a walk that leaves her branch sees it is
## `tests/probes/calm_pelican_day7_van_met.gd`'s to measure.
##
## The units draw as she walks (`EventManager.stream_around()`). The tiles the van shuts are read
## off the tick it is laid, which units drawing on that tick add their own bodies to, so that check
## holds of both. Combines the director, the siting and the streaming on a real city on purpose: the
## guarantee is the meeting, which spans them.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 1234567]
const DAY := 7
## The seed of the run each city stands in (a run of its own, held by the city), fixed so a walk
## repeats.
const RUN_SEED := 2
const ROW := "delivery_van"
const STEP := 0.1

func run(t: TestRunner) -> void:
	var met := 0
	for seed_value in SEEDS:
		if _a_mark_puts_a_van_on_her_way(t, seed_value):
			met += 1
	t.check(met == SEEDS.size(), "she meets the rigged van in every city (%d of %d)"
			% [met, SEEDS.size()])

## Answers whether she met the rigged van in this city: laid, and later in her view.
func _a_mark_puts_a_van_on_her_way(t: TestRunner, seed_value: int) -> bool:
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	RunCity.build(city, CityGenerator.generate(seed_value))
	# What the events tell the run log: a place is put on her route when a line says so.
	var put_down: Array[String] = []
	RunCity.events(city).world.surroundings().tracing_to(RecordingTrace.new(put_down))
	var state := CityState.new()
	state.begin_day(city.map.plans_by_block(), DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	RunCity.events(city).start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), consumed)

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
	var mark := resistance.current_step()
	t.check(mark != null and mark.is_pickup and mark.day == DAY,
			"seed %d: day %d opens on its mark" % [seed_value, DAY])
	if mark:
		resistance.contact().complete_now()
	var task_van: EventInstance = resistance.rider()
	t.check(task_van != null and task_van.row_id() == ROW,
			"seed %d: reading it puts the task's van near the mark" % seed_value)
	var task_van_at := task_van.global_position if task_van else Vector2.INF
	t.check(_the_rigged_van(city, put_down) == null,
			"seed %d: the rigged van is not laid yet as she reads the mark" % seed_value)

	# Out from the doorstep end and back, so she is never put down on ground that has not drawn.
	var path := _the_longest_route(city)
	var back := path.duplicate()
	back.reverse()
	path.append_array(back)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	RunCity.events(city).use_player(player)
	t.check(path.size() >= 2 and RunCity.events(city).world.has_player(), "a route to walk and her on it")
	var map := city.map
	var seen := {"van": null, "her": Vector2.INF, "heading": Vector2.ZERO,
			"tiles": [] as Array[Vector2i], "met": false}
	var tick := func() -> void:
		var obstructed_before := map.obstructed_tiles().duplicate()
		var events := RunCity.events(city)
		# The tick's stretch from her camera's view to what is owed, in the tick's own order.
		events.step_what_is_ahead(STEP)
		var laid: EventPlan = seen["van"]
		if laid != null:
			var off := (laid.placed_at() - player.global_position).abs()
			if off.x <= Tuning.VIEW_HALF_EXTENT.x and off.y <= Tuning.VIEW_HALF_EXTENT.y:
				seen["met"] = true
			return
		var van := _the_rigged_van(city, put_down)
		if van == null:
			return
		seen["van"] = van
		seen["her"] = player.global_position
		seen["heading"] = player.velocity.normalized()
		var its: Array[Vector2i] = []
		for tile: Vector2i in map.obstructed_tiles():
			if not obstructed_before.has(tile):
				its.append(tile)
		seen["tiles"] = its
	if path.size() >= 2:
		player.global_position = path[0]
		# Her branch until the van is laid, then on the way she was heading: what the rule promises
		# (`WalkSiting.lay_just_ahead()`) is that keeping on her way brings it into view.
		for point in path:
			if seen["van"] != null:
				break
			_along(player, [point] as Array[Vector2], tick)
		if seen["van"] != null:
			_along(player, [player.global_position + player.velocity.normalized()
					* WalkSiting.JUST_AHEAD] as Array[Vector2], tick)
	var plan: EventPlan = seen["van"]
	t.check(plan != null, "seed %d: her walk lays the rigged van" % seed_value)
	t.check(bool(seen["met"]), "seed %d: and keeping on her way brings it into her view" % seed_value)
	if plan:
		var her: Vector2 = seen["her"]
		var heading: Vector2 = seen["heading"]
		var its_tiles: Array[Vector2i] = seen["tiles"]
		var where_laid := plan.placed_at()
		var tile := map.world_to_tile(where_laid)
		# What it draws, where it is drawn, against the camera's view as it leads her
		# (`Stroller.CAMERA_LOOK_AHEAD` along her heading, `Stroller.OBLIQUE_Y` of it up or down).
		var box := EventFootprints.footprint_of(plan.row())
		var drawn := Rect2(where_laid + box.position, box.size)
		var lead := Vector2(heading.x, heading.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
		var view := Rect2(her + lead - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
		t.check(not view.intersects(drawn, true),
				"seed %d: no part of it is in the camera's view on the tick it is laid, so it is never seen to appear (%s, view %s)"
				% [seed_value, drawn, view])
		var corridor := Corridor.of(city.streets().route_tree())
		t.check(not corridor.carries_a_route(tile),
				"seed %d: it stands on no tile a route of the day runs along" % seed_value)
		var routes := _routes_it_cuts(city, its_tiles)
		t.check(not its_tiles.is_empty() and routes.x > 0 and routes.y == 0,
				"seed %d: its body (%d tiles) cuts none of the %d routes of the day she could walk without it (%d cut)"
				% [seed_value, its_tiles.size(), routes.x, routes.y])
		t.check(_walkable_from(map, her).has(map.world_to_tile(map.doorstep_world_position())),
				"seed %d: with it standing she can still walk home from where she was" % seed_value)
		var grid := ReachabilityGrid.build(map)
		var reached := grid.flood([map.world_to_tile(her)])
		t.check(grid.reaches(tile, {}, reached),
				"seed %d: she can walk to it from where she was" % seed_value)
	t.check(task_van != null and is_instance_valid(task_van) and not task_van.is_gone()
			and task_van.global_position == task_van_at and resistance.rider() == task_van,
			"seed %d: the task's own van stays where it was placed, and stays the task" % seed_value)
	player.free()
	resistance.free()
	city.free()
	return plan != null and bool(seen["met"])

## The van the mark rigged once her walk has laid it (the walk's plan of the row whose place the
## run log says was put on her route), or null while it is not laid.
func _the_rigged_van(city: City, put_down: Array[String]) -> EventPlan:
	var events := RunCity.events(city)
	for plan in events.walk_events().plans():
		if plan.row_id() == ROW and plan.is_placed() \
				and PutOnHerRoute.says(put_down, city.map, plan):
			return plan
	return null

## Walks her through `points` at `Tuning.WALK_SPEED`, a tick a step.
func _along(player: Stroller, points: Array[Vector2], tick: Callable) -> void:
	for point in points:
		while player.global_position.distance_to(point) > 1.0:
			var toward := point - player.global_position
			var stride := minf(toward.length(), Tuning.WALK_SPEED * STEP)
			player.velocity = toward.normalized() * Tuning.WALK_SPEED
			tick.call()
			player.global_position += toward.normalized() * stride

## How many of the day's routes she can walk without `body` standing (x), and how many of those
## `body` cuts (y): routes whose own ground — the tiles of their cells —
## leads from their first cell to their last around every standing body but the one on `body`, and
## no longer does with it standing. A route's sidewalk the van leaves open is walked past it.
static func _routes_it_cuts(city: City, body: Array[Vector2i]) -> Vector2i:
	var map := city.map
	var its := {}
	for tile in body:
		its[tile] = true
	var walkable := 0
	var cut := 0
	for branch in city.streets().route_tree().branches():
		for route: Array in branch.routes:
			if route.size() < 2:
				continue
			var ground := {}
			for cell: Vector2i in route:
				for dy in ReachabilityGrid.CELL:
					for dx in ReachabilityGrid.CELL:
						ground[cell * ReachabilityGrid.CELL + Vector2i(dx, dy)] = true
			var first: Vector2i = route[0]
			var last: Vector2i = route[route.size() - 1]
			if not _along_route(map, ground, first, last, its):
				continue
			walkable += 1
			if not _along_route(map, ground, first, last, {}):
				cut += 1
	return Vector2i(walkable, cut)

## Whether some tile of cell `last` is reached from a tile of cell `first` over `ground` alone,
## walkable, open and unobstructed — the tiles of `ignoring` counted as unobstructed, as though the
## body standing on them were not there.
static func _along_route(map: CityMap, ground: Dictionary, first: Vector2i, last: Vector2i,
		ignoring: Dictionary) -> bool:
	var open := func(tile: Vector2i) -> bool:
		return ground.has(tile) and map.is_walkable(tile) and not map.is_closed(tile) \
				and (not map.is_obstructed(tile) or ignoring.has(tile))
	var queue: Array[Vector2i] = []
	var reached := {}
	for dy in ReachabilityGrid.CELL:
		for dx in ReachabilityGrid.CELL:
			var tile := first * ReachabilityGrid.CELL + Vector2i(dx, dy)
			if open.call(tile):
				reached[tile] = true
				queue.append(tile)
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if Vector2i(tile.x / ReachabilityGrid.CELL, tile.y / ReachabilityGrid.CELL) == last:
			return true
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + side
			if not reached.has(next) and open.call(next):
				reached[next] = true
				queue.append(next)
	return false

## Every tile she can walk to from `from` today, around every closure, sealed way and standing body.
static func _walkable_from(map: CityMap, from: Vector2) -> Dictionary:
	var start := map.world_to_tile(from)
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + side
			if reached.has(next) or not map.in_bounds(next) or not map.is_walkable(next) \
					or map.is_closed(next) or map.soft_sealed_tiles().has(next) \
					or map.is_obstructed(next):
				continue
			reached[next] = true
			queue.append(next)
	return reached

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
	rng.seed = hash("day7-van:%d:%d:%s" % [seed_value, DAY, stream])
	return rng
