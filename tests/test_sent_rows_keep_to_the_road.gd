extends RefCounted
## **A row the director sends ahead of her keeps to its ground for as long as she can see it, with her
## walking, and never vanishes in her view**: a sent police patrol or military convoy is never seen on
## a precinct's paving or off the carriageway (a street a calm zone absorbed, a closed street, the
## map's edge), never stands two seconds while leaving, and never turns by more than a quarter turn in
## one tick; and no sent row, the dog walker included, is gone on a tick after one it was in her view.
## Its route is worked out as it goes (`WayOn`, `EventInstance.go_on_by()`) and it leaves by legs of the
## same, held to her sight (`EventDeparture`), which is what this holds, on what she sees.
##
## **She walks**: each tick she is moved `Tuning.WALK_SPEED` the way she heads, where the ground lets
## her, and the view is the one around where she is then. Two walks from each place: **on**, she keeps
## her heading, and **with it**, once a thing that came toward her has passed her she turns and walks
## its way, so she follows a car toward whatever lies past her.
##
## **Places**: every `ONE_IN`th plain sidewalk tile beside a carriageway, each way along its street,
## for all three rows and both walks; and every street into a paved junction box, she on its sidewalk
## `BACK_FROM_THE_BOX` tiles back from the box heading away from it, for the two cars, walking with
## them, so a car that passes her drives on toward the paving and she follows it there. On two cities, **with the day's own closures laid** (`ClosurePlanner.plan_day()`), so a
## closed street is met. Her route's bag holds one marble of the row (`EventManager.start_recipe_route()`,
## the way a scene recipe rigs one), and every sent row is watched a tick at a time until it is gone.
##
## **The subject is what the event manager creates and steps**, so it is built over a copy of a
## generated city's map and no city (`tests/fixtures/street_events.gd`), as
## `tests/test_sent_down_her_line.gd` is: the lanes, the through roads, the paved boxes and the way a
## row leaves are the streets' and the manager's own, and a hand-drawn map would not have the
## lattice's paved boxes, absorbed streets and edges this asks about. The walk is a recipe's with
## nothing planned in it (`EventManager.start_recipe()`), so no plan refuses a row room.

const MapCache := preload("res://tests/city_map_cache.gd")
## The cities: the one the third review of the sent rows measured the patrol crossing a paved box
## on, and a second.
const SEEDS: Array[int] = [4242, 90210]
## The run's seed for each city, for the run the events belong to.
const RUN_SEEDS: Array[int] = [2, 5]
## The day the rows are owed on and the closures are planned for: one the convoy comes on.
const DAY := 13
## The engine's clock for the walk, sped up and put back after it.
const FAST_SCALE := 3.0
## One plain sidewalk tile beside a carriageway in this many is a place she starts from.
const ONE_IN := 2000
## How far back from a paved box she stands, in tiles: right beside it, and a few tiles back.
const BACK_FROM_THE_BOX: Array[int] = [0, 6]
## Game seconds of her walking before her route's one marble is due, then how long a place waits for
## its row to be created, and the most it watches one.
const FIRST_AFTER := 0.5
const WAIT_FOR_ONE := 3.0
const WATCH_FOR := 45.0
## Watched longer than this, a row was followed a good while.
const LONG_WATCH := 15.0
## How long a car leaving may stand in her view before it counts as standing.
const STANDS_FOR := 2.0
## A car's middle to either end along the way it faces, and the box about it the view must clear for
## it not to be seen (`tests/test_patrol_vanish.gd`'s `CAR_BOX`).
const HALF_LENGTH := 24.0
const CAR_BOX := Vector2(48.0, 48.0)
const CARS: Array[String] = ["police_patrol", "military_convoy"]
const ROWS: Array[String] = ["police_patrol", "military_convoy", "dog_walker"]

## **One sent row as she sees it**: what it did on the ticks it was in her view.
class Watched:
	var instance: EventInstance
	var row: String
	var axis := Vector2.ZERO
	var last := Vector2.INF
	var last_axis := Vector2.ZERO
	var was_seen := false
	var gone := false
	var still := 0.0
	var seen_for := 0.0
	var turned_a_corner := false
	## Whether she turned to walk its way once it had passed her.
	var followed := false
	## What went wrong, each once: a line naming it and where.
	var faults: Array[String] = []

	func _init(of: EventInstance) -> void:
		instance = of
		row = of.def.id
		axis = of.facing_now()
		last_axis = axis

	func fault(what: String) -> void:
		for already in faults:
			if already.begins_with(what.get_slice(" ", 0)):
				return
		faults.append(what)

var _rig: Stroller

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	_rig = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	_rig.add_child(camera)
	t.add_child(_rig)
	_rig.set_physics_process(false)
	await _test_sent_rows_keep_to_the_road_while_she_walks(t)
	_rig.free()

## Every place, row and walk: no sent car off its ground, standing or turning on the spot in her
## view, and no sent row gone in it. Not vacuous: rows are sent and seen, some followed a good while,
## some with her walking their way, and some cars turn a corner in her view.
func _test_sent_rows_keep_to_the_road_while_she_walks(t: TestRunner) -> void:
	var faults: Array[String] = []
	var sent := 0
	var seen := 0
	var long_watched := 0
	var followed := 0
	var corners := 0
	var places := 0
	for index in SEEDS.size():
		var map := MapCache.of(SEEDS[index])
		var spec := DaySpec.for_day(DAY)
		var tree := RouteTree.for_day(map, DAY)
		var region := RegionPlanner.plan_day(map, spec, tree)
		var rng := RandomNumberGenerator.new()
		rng.seed = SEEDS[index]
		var closures := ClosurePlanner.plan_day(map, spec, rng, tree, region)
		map.close_streets(closures)
		var run := RunState.new()
		run.start_run(RUN_SEEDS[index])
		var streets := DayStreets.new()
		var events := StreetEvents.over(t, map, run, streets)
		events.use_player(_rig)
		var plain := _beside_carriageways(map)
		var paved := _beside_paved_boxes(map)
		places += plain.size() + paved.size()
		var watches: Array[Array] = []
		for spot: Array in plain:
			for row in ROWS:
				for with_it: bool in [false, true]:
					watches.append([spot, row, with_it])
		for spot: Array in paved:
			for row in CARS:
				watches.append([spot, row, true])
		for watch: Array in watches:
			var spot: Array = watch[0]
			var row: String = watch[1]
			var with_it: bool = watch[2]
			streets.begin_day(tree, region, closures)
			var watched := await _watch(t, events, map, spec, row, spot[0], spot[1],
					with_it)
			for car in watched:
				sent += 1
				seen += 1 if car.seen_for > 0.0 else 0
				long_watched += 1 if car.seen_for > LONG_WATCH else 0
				followed += 1 if car.followed else 0
				corners += 1 if car.turned_a_corner else 0
				for what in car.faults:
					faults.append("seed %d, %s, her at %s heading %s%s: %s" % [SEEDS[index],
							row, map.world_to_tile(spot[0]), spot[1],
							", walking with it" if with_it else "", what])
		events.free()
	t.check(places > 0, "there are places to start from (%d)" % places)
	t.check(sent > 0 and seen > 0, "rows are sent and seen (%d sent, %d seen)" % [sent, seen])
	t.check(long_watched > 0 and followed > 0,
			"some are watched over %.0fs (%d), and some with her walking their way (%d)"
			% [LONG_WATCH, long_watched, followed])
	t.check(corners > 0, "and some cars turn a corner in her view (%d)" % corners)
	t.check(faults.is_empty(), "no sent row leaves its ground, stands, turns on the spot or vanishes "
			+ "in her view%s" % ("" if faults.is_empty() else ": " + "; ".join(faults.slice(0, 8))
			+ (" and %d more" % (faults.size() - 8) if faults.size() > 8 else "")))

## One watch: `row` her route's one marble, her starting at `her` walking `heading`, turning to walk
## a row's way once it has passed her where `with_it`. Answers each sent row as she saw it.
func _watch(t: TestRunner, events: EventManager, map: CityMap, spec: DaySpec, row: String,
		her: Vector2, heading: Vector2, with_it: bool) -> Array[Watched]:
	var no_plans: Array[EventPlan] = []
	events.start_recipe(no_plans, spec, DAY, her)
	events.start_recipe_route([row], [], 1, FIRST_AFTER)
	var at: Array[Vector2] = [her, heading]
	var turned: Array[bool] = [false]
	_rig.global_position = her
	_rig.velocity = heading * Tuning.WALK_SPEED
	var watched: Array[Watched] = []
	var step := FAST_SCALE / Engine.physics_ticks_per_second
	var waited: Array[float] = [0.0]
	var on_foot := Mover.on_foot()
	var each := func(_n: int) -> bool:
		waited[0] += step
		var next := at[0] + at[1] * Tuning.WALK_SPEED * step
		var ahead := map.world_to_tile(next + at[1] * 8.0)
		if map.in_bounds(ahead) and map.passable(ahead, on_foot):
			at[0] = next
			_rig.velocity = at[1] * Tuning.WALK_SPEED
		else:
			_rig.velocity = Vector2.ZERO
		_rig.global_position = at[0]
		var view := VisibleView.around(at[0], null)
		for instance in events.instances():
			if instance.def.id == row and not _has(watched, instance):
				watched.append(Watched.new(instance))
		var all_gone := true
		for car in watched:
			if car.gone:
				continue
			if not _is_live(events, car.instance):
				car.gone = true
				if car.was_seen:
					car.fault("gone in her view at %s, %.0fpx from her"
							% [map.world_to_tile(car.last), car.last.distance_to(at[0])])
				continue
			all_gone = false
			var place := car.instance.global_position
			if with_it and not turned[0] and car.axis.dot(at[1]) < 0.0 \
					and (place - at[0]).dot(at[1]) < -16.0:
				turned[0] = true
				at[1] = -at[1]
				car.followed = true
			var seen := view.sees_any(Rect2(place - CAR_BOX * 0.5, CAR_BOX))
			if seen:
				_look_at(car, map, place, step)
			car.last = place
			car.last_axis = car.instance.facing_now()
			car.was_seen = seen
		if watched.is_empty():
			return waited[0] >= FIRST_AFTER + WAIT_FOR_ONE
		return all_gone or waited[0] >= FIRST_AFTER + WATCH_FOR
	await PhysicsTicks.pass_ticks_faster(t,
			PhysicsTicks.ticks_for(FIRST_AFTER + WAIT_FOR_ONE + WATCH_FOR, FAST_SCALE),
			PhysicsTicks.FASTER, each, FAST_SCALE)
	return watched

## What `car` does on a tick it is in her view, at `place`.
static func _look_at(car: Watched, map: CityMap, place: Vector2, step: float) -> void:
	car.seen_for += step
	if car.row not in CARS:
		return
	var axis := car.instance.facing_now()
	if not car.last_axis.is_zero_approx() and axis.dot(car.last_axis) < 0.0:
		car.fault("turned on the spot at %s" % map.world_to_tile(place))
	if absf(axis.dot(car.axis)) < 0.5:
		car.turned_a_corner = true
	for along: float in [-HALF_LENGTH, 0.0, HALF_LENGTH]:
		var under := map.world_to_tile(place + axis * along)
		if not map.is_driveable_at(true, under):
			car.fault("on paving at %s" % under)
	var tile := map.world_to_tile(place)
	if not map.in_bounds(tile) or not map.is_carriageway(tile):
		car.fault("off the carriageway at %s" % tile)
	if car.last != Vector2.INF and place.distance_to(car.last) < 0.01:
		car.still += step
		if car.still > STANDS_FOR and car.instance.is_leaving:
			car.fault("stood leaving at %s" % tile)
	else:
		car.still = 0.0

static func _has(watched: Array[Watched], instance: EventInstance) -> bool:
	for car in watched:
		if car.instance == instance:
			return true
	return false

## Whether `car` is still in the manager's world.
static func _is_live(events: EventManager, car: EventInstance) -> bool:
	return is_instance_valid(car) and not car.is_finished and events.instances().has(car)

## Every `ONE_IN`th plain sidewalk tile beside a carriageway, each way along its street:
## `[her, heading]`.
static func _beside_carriageways(map: CityMap) -> Array[Array]:
	var spots: Array[Array] = []
	var size := map.size_in_tiles()
	var count := 0
	for y in size.y:
		for x in size.x:
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.SIDEWALK:
				continue
			var inward := map.pavement_inward(tile)
			if inward == Vector2i.ZERO:
				continue
			var vertical := inward.x != 0
			var outer := map.tile_at(tile - inward) == GameEnums.TileType.SIDEWALK
			var road := tile - inward * (Tuning.SIDEWALK_WIDTH if outer else 1)
			if not map.in_bounds(road) or map.tile_at(road) != GameEnums.TileType.ROAD \
					or not map.is_driveable_at(vertical, road):
				continue
			count += 1
			if count % ONE_IN != 0:
				continue
			var along := Vector2(0, 1) if vertical else Vector2(1, 0)
			spots.append([map.tile_to_world(tile), along])
			spots.append([map.tile_to_world(tile), -along])
	return spots

## Where she stands beside a street that runs into a paved junction box: `[her, heading]`, on the
## street's sidewalk on the low side (west or north), `BACK_FROM_THE_BOX` tiles back from the box,
## walking away from it, on every arm whose carriageway is a car's right up to the box and whose box
## is paved.
static func _beside_paved_boxes(map: CityMap) -> Array[Array]:
	var spots: Array[Array] = []
	var period := CityMap.period()
	var size := map.size_in_tiles()
	var side := Tuning.SIDEWALK_WIDTH - 1
	for bx in range(0, size.x, period):
		for by in range(0, size.y, period):
			var origin := Vector2i(bx, by)
			for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var vertical := out.x == 0
				var across := Vector2i(1, 0) if vertical else Vector2i(0, 1)
				var rim := origin + (Vector2i.ZERO if out.x + out.y < 0
						else out * (Tuning.STREET_WIDTH - 1))
				var edge := rim + across * Tuning.SIDEWALK_WIDTH
				var outside := edge + out
				if not map.in_bounds(outside) or map.tile_at(outside) != GameEnums.TileType.ROAD \
						or not map.is_driveable_at(vertical, outside) \
						or map.is_driveable_at(vertical, edge):
					continue
				for back in BACK_FROM_THE_BOX:
					var tile := rim + across * side + out * (back + 1)
					if map.in_bounds(tile) and map.tile_at(tile) == GameEnums.TileType.SIDEWALK \
							and map.pavement_inward(tile) != Vector2i.ZERO:
						spots.append([map.tile_to_world(tile), Vector2(out)])
	return spots
