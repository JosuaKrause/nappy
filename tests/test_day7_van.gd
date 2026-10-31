extends RefCounted
## Day 7's van gets a second instance on her route, from a rigged bag *(inbox #586 in
## olive-hedgehog: "each olive badger rigged bag should be 2 or 3"; inbox #650 in mossy-beaver: "I
## guess that leaves only the van?")*.
##
## Holds, through a real city: reading day 7's mark rigs her route with a bag of
## `Tuning.VAN_WITHIN_THE_NEXT` holding one `delivery_van`; walking the day's route, the van's marble
## is among that many events handed out on it, and a van is then put on her route — ahead of her on
## the street she is walking, with no part of what it draws in the camera's view (led along her
## heading), where she can walk to it, in the world at once, and where keeping on her way brings it
## into view; on no tile a route of the day runs along, and leaving her a way home — while the van
## the task rides, placed near the mark, stays where it is. How often a played walk sees it is
## `tests/probes/calm_pelican_day7_van_met.gd`'s to measure.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 1234567]
const DAY := 7
const ROW := "delivery_van"
const STEP := 0.1

func run(t) -> void:
	var met := 0
	for seed_value in SEEDS:
		if _a_mark_puts_a_van_on_her_route(t, seed_value):
			met += 1
	t.check(met > 0, "a van is put on her route in at least one city (%d of %d)"
			% [met, SEEDS.size()])
	_test_the_van_is_sited_wholly_out_of_the_camera_view(t)

## Answers whether a second van was put on her route in this city.
func _a_mark_puts_a_van_on_her_route(t, seed_value: int) -> bool:
	var size := Tuning.VAN_WITHIN_THE_NEXT
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), consumed)

	var saved_completed := GameState.resistance.completed_steps.duplicate()
	var saved_failed := GameState.resistance.failed_steps.duplicate()
	var saved_progress := GameState.resistance.progress
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	GameState.resistance.completed_steps.assign(done)
	GameState.resistance.failed_steps.assign([])
	GameState.resistance.progress = 0
	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city, city.map)
	resistance.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	var mark := resistance.current_step()
	t.check(mark != null and mark.is_pickup and mark.day == DAY,
			"seed %d: day %d opens on its mark" % [seed_value, DAY])
	var bag := city.events.ahead._director.route_bag()
	if mark:
		resistance._on_contact_completed(mark.index)
	var task_van: EventInstance = resistance._rider
	t.check(task_van != null and task_van.def.id == ROW,
			"seed %d: reading it puts the task's van near the mark" % seed_value)
	var task_van_at := task_van.global_position if task_van else Vector2.INF
	var rigged := bag.bag_in_front()
	t.check(rigged.size() == size and rigged.count(ROW) == 1,
			"seed %d: reading the mark rigs her route with a bag of %d holding one %s (%s)"
			% [seed_value, size, ROW, rigged])

	var path := _the_longest_route(city)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	city.events.use_player(player)
	t.check(path.size() >= 2 and city.events.world.has_player(), "a route to walk and her on it")
	var placed: Array[EventScheduler.Planned] = []
	var drawn_within := false
	var her_at_siting := Vector2.INF
	var where_sited := Vector2.INF
	var heading_at_siting := Vector2.ZERO
	var live_at_once := false
	var its_tiles: Array[Vector2i] = []
	if path.size() >= 2:
		var index := 0
		var direction := 1
		player.global_position = path[0]
		var handed := 0
		var walked := 0.0
		while (handed < size or placed.is_empty()) and walked < 600.0:
			var next: Vector2 = path[index + direction] if index + direction >= 0 \
					and index + direction < path.size() else Vector2.INF
			if next == Vector2.INF:
				direction = -direction
				continue
			var toward := next - player.global_position
			if toward.length() < Tuning.WALK_SPEED * STEP:
				player.global_position = next
				index += direction
				continue
			player.velocity = toward.normalized() * Tuning.WALK_SPEED
			var owed_before := city.events.owed_ahead()
			var plans_before := city.events.plans().size()
			var obstructed_before := city.map.obstructed_tiles.duplicate()
			# In the order the manager's own tick runs them: what her walk sites, then what is owed.
			city.events.ahead.site_what_is_on_her_way(STEP)
			city.events.ahead.place_what_is_owed_ahead(STEP)
			city.events.stream_around(player.global_position)
			if city.events.owed_ahead() < owed_before and handed < size:
				handed += 1
				if handed == size:
					drawn_within = _a_place_from_her_route(city.events.ahead._director) != null
			for plan: EventScheduler.Planned in city.events.plans().slice(plans_before):
				if plan.def.id == ROW and city.events.ahead._director.is_from_her_route(plan):
					placed.append(plan)
					her_at_siting = player.global_position
					where_sited = plan.position
					heading_at_siting = player.velocity.normalized()
					city.events.stream_around(player.global_position)
					live_at_once = plan.live != null
					for tile: Vector2i in city.map.obstructed_tiles:
						if not obstructed_before.has(tile):
							its_tiles.append(tile)
			player.global_position += player.velocity * STEP
			walked += STEP
	t.check(drawn_within, "seed %d: the van's marble is among the next %d events on her route"
			% [seed_value, size])
	t.check(placed.size() == 1, "seed %d: one van is put on her route (%d)"
			% [seed_value, placed.size()])
	if placed.size() == 1:
		var plan := placed[0]
		var map := city.map
		var tile := map.world_to_tile(where_sited)
		# A van leaves no line past it on a sidewalk a route runs along, so it is put on the street
		# she is walking, just out of her sight ahead of her (`WalkSiting.ahead_on_her_street()`).
		var offset := where_sited - her_at_siting
		t.check(offset.dot(heading_at_siting) > 0.0
				and absf(offset.cross(heading_at_siting)) <= 5.0 * Tuning.TILE_SIZE,
				"seed %d: it stands ahead of her on the street she is walking (%s)"
				% [seed_value, offset])
		# What it draws, where it is drawn, against the camera's view as it leads her
		# (`Stroller.CAMERA_LOOK_AHEAD` along her heading, `Stroller.OBLIQUE_Y` of it up or down).
		var box := EventInstance.footprint_of(plan.def)
		var drawn := Rect2(where_sited + box.position, box.size)
		var lead := Vector2(heading_at_siting.x, heading_at_siting.y * Stroller.OBLIQUE_Y) \
				* Stroller.CAMERA_LOOK_AHEAD
		var view := Rect2(her_at_siting + lead - Tuning.VIEW_HALF_EXTENT,
				Tuning.VIEW_HALF_EXTENT * 2.0)
		t.check(not view.intersects(drawn, true),
				"seed %d: no part of it is in the camera's view when it is put there, so it is never seen to appear (%s, view %s)"
				% [seed_value, drawn, view])
		var corridor := Corridor.of(city.route_tree())
		t.check(not corridor.carries_a_route(tile),
				"seed %d: it stands on no tile a route of the day runs along" % seed_value)
		var routes := _routes_it_cuts(city, its_tiles)
		t.check(not its_tiles.is_empty() and routes.x > 0 and routes.y == 0,
				"seed %d: its body (%d tiles) cuts none of the %d routes of the day she could walk without it (%d cut)"
				% [seed_value, its_tiles.size(), routes.x, routes.y])
		t.check(_walkable_from(map, her_at_siting).has(
				map.world_to_tile(map.doorstep_world_position())),
				"seed %d: with it standing she can still walk home from where she was" % seed_value)
		var grid := ReachabilityGrid.build(map)
		var reached := grid.flood([map.world_to_tile(her_at_siting)])
		t.check(grid.reaches(tile, {}, reached),
				"seed %d: she can walk to it from where she was" % seed_value)
		t.check(live_at_once and plan.position == where_sited,
				"seed %d: it is in the world at once, and stays where it was put" % seed_value)
		t.check(_keeping_on_brings_it_into_view(map, her_at_siting, heading_at_siting, where_sited),
				"seed %d: keeping on the way she was walking, over walkable ground, it comes into her view"
				% seed_value)
	t.check(task_van != null and is_instance_valid(task_van) and not task_van.is_finished
			and task_van.global_position == task_van_at and resistance._rider == task_van,
			"seed %d: the task's own van stays where it was placed, and stays the task" % seed_value)
	player.free()
	resistance.free()
	city.free()
	GameState.resistance.completed_steps.assign(saved_completed)
	GameState.resistance.failed_steps.assign(saved_failed)
	GameState.resistance.progress = saved_progress
	return placed.size() == 1

## **No part of the route van is in the camera's view the frame it is created** ("Nothing may be
## seen to appear", `docs/EVENTS.md`): asked of `WalkSiting.ahead_on_her_street()` directly, from
## every third cell of the day's longest route with her walking it either way, its drawing
## (`EventInstance.footprint_of()`, where it is drawn round its feet) against the 640x360 view led
## `Stroller.CAMERA_LOOK_AHEAD` along her heading as the camera leads her.
func _test_the_van_is_sited_wholly_out_of_the_camera_view(t) -> void:
	var seed_value: int = SEEDS[0]
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), consumed)
	var siting: EventScheduler.WalkSiting = city.events.ahead._siting
	var def := EventCatalogue.by_id(ROW)
	var box := EventInstance.footprint_of(def)
	var path := _the_longest_route(city)
	var sited := 0
	var seen: Array[String] = []
	var rng := _rng(seed_value, "sited")
	for i in range(1, path.size(), 3):
		for way in [1, -1]:
			var from: Vector2 = path[i - 1] if way == 1 else path[i]
			var to: Vector2 = path[i] if way == 1 else path[i - 1]
			if from.distance_to(to) < 1.0:
				continue
			var heading := (to - from).normalized()
			var plan := siting.ahead_on_her_street(def, rng, city.events.plans(), from, heading)
			if plan == null:
				continue
			sited += 1
			var lead := Vector2(heading.x, heading.y * Stroller.OBLIQUE_Y) \
					* Stroller.CAMERA_LOOK_AHEAD
			var view := Rect2(from + lead - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
			if view.intersects(Rect2(plan.position + box.position, box.size), true):
				seen.append("%s heading %s" % [city.map.world_to_tile(from), heading])
	t.check(sited > 0 and seen.is_empty(),
			"no van sited ahead of her is drawn in the camera's view as it is put there (%d sited, %d seen: %s)"
			% [sited, seen.size(), seen.slice(0, 3)])
	city.free()

## Whether walking on from `from` along `heading`, over walkable ground and no further than the
## streaming radius, brings `van` inside her view (`Tuning.VIEW_HALF_EXTENT` round her) — that it
## stands on the way she is walking rather than across a building or past where the street ends.
func _keeping_on_brings_it_into_view(map: CityMap, from: Vector2, heading: Vector2,
		van: Vector2) -> bool:
	var at := from
	var gone := 0.0
	while gone <= Tuning.EVENT_STREAM_RADIUS:
		var off := (van - at).abs()
		if off.x <= Tuning.VIEW_HALF_EXTENT.x and off.y <= Tuning.VIEW_HALF_EXTENT.y:
			return true
		at += heading * 8.0
		gone += 8.0
		if not map.is_walkable(map.world_to_tile(at)):
			return false
	return false

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
	for branch in city.route_tree().branches:
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
			if not _along(map, ground, first, last, its):
				continue
			walkable += 1
			if not _along(map, ground, first, last, {}):
				cut += 1
	return Vector2i(walkable, cut)

## Whether some tile of cell `last` is reached from a tile of cell `first` over `ground` alone,
## walkable, open and unobstructed — the tiles of `ignoring` counted as unobstructed, as though the
## body standing on them were not there.
static func _along(map: CityMap, ground: Dictionary, first: Vector2i, last: Vector2i,
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
					or map.is_closed(next) or map.soft_sealed_tiles.has(next) \
					or map.is_obstructed(next):
				continue
			reached[next] = true
			queue.append(next)
	return reached

## The van a marble from her route's bag handed to her walk to site, sited or not; null when none
## has been.
func _a_place_from_her_route(director: EventDirector) -> EventScheduler.Planned:
	for plan: EventScheduler.Planned in director._placed_from_the_route:
		if plan.def.id == ROW:
			return plan
	return null

## The cell centres of the day's longest route, from the doorstep end out — the walk she takes.
func _the_longest_route(city: City) -> Array[Vector2]:
	var longest: Array = []
	for branch in city.route_tree().branches:
		for route: Array in branch.routes:
			if route.size() > longest.size():
				longest = route
	var points: Array[Vector2] = []
	for i in range(longest.size() - 1, -1, -1):
		points.append(EventScheduler.WalkSiting._cell_centre(city.map, longest[i]))
	return points

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("day7-van:%d:%d:%s" % [seed_value, DAY, stream])
	return rng
