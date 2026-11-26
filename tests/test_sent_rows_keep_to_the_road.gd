extends RefCounted
## **A row the director sends ahead of her keeps to its ground for as long as she can see it, with her
## walking, and never vanishes in her view**: a sent police patrol or military convoy is never seen on
## a precinct's paving or off the carriageway (a street a calm zone absorbed, a closed street, the
## map's edge), never stands two seconds while leaving, and never turns by more than a quarter turn in
## one tick; no sent row, the dog walker included, is gone on a tick after one it was in her view; and
## no sent row still live comes inside the field a placed lethal row keeps clear. Its route is worked
## out as it goes (`WayOn`, `EventInstance.go_on_by()`) and it leaves by legs of the same, held to her
## sight (`EventDeparture`), which is what this holds, on what she sees.
##
## **She walks**: each tick she is moved `Tuning.WALK_SPEED` the way she heads, where the ground lets
## her, and the view is the one around where she is then. Three walks: **on**, she keeps her heading;
## **with it**, once a row that came toward her has passed her she turns and walks its way down her
## street, waiting for it on the sidewalk between crossings when she is more than `KEEP` ahead of it;
## and **after it**, once it has passed her she follows it street by street wherever it goes, standing
## while she is within `KEEP` of it, so she stays beside a patrol (slower than her walk) or a dog
## walker for as long as it goes on, and behind a convoy until it outruns her.
##
## **Where she starts**, on two cities with the day's own closures laid (`ClosurePlanner.plan_day()`):
## - **plain**: `PLAIN_EACH_AXIS` sidewalk tiles beside a carriageway on streets running north-south
##   and as many on streets running east-west, all three rows, all three walks;
## - **before a dead end**: on every street where the street on past a junction box runs into a paved
##   box, one in `PAVED_ONE_IN`; where it is not a car's to drive for another reason (a closure, a
##   street a calm zone absorbed), one in `STUB_ONE_IN`; and on every street on past a box into a box
##   with no second way out (a corner of the map whose other street is cut), she stands just short of
##   the box before that one, heading away from it, so a car that passes her comes to it on its second
##   leg: the patrol and the convoy, her walking after them;
## - **past a paved box**: beside a street that runs into a paved junction box,
##   `BACK_FROM_THE_BOX` tiles back from it, heading away from it, where a car coming toward her would
##   have to cross the paving on its first leg, so none may be sent: the patrol and the convoy, her
##   walking with them;
## - **toward a lethal row's field**: on a street that runs on through three boxes, a reversing lorry
##   standing on the far sidewalk beyond the second box past her, a plan of the walk that keeps its
##   field clear, so a row that passes her is refused the leg past it while live and leaves by legs in
##   her view: the patrol with her walking with it (she outwalks it, so it leaves behind her), the
##   convoy and the dog walker with her walking after them.
##
## **The places are found from the map's own ground, never from `ThroughRoads`** (`_is_a_cars()`
## asks a stretch's lanes as a car would), so a change to the through roads cannot move where she
## stands. Her route's bag holds one marble of the row (`EventManager.start_recipe_route()`, the way a
## scene recipe rigs one), and every sent row is watched a tick at a time until it is gone.
##
## **The subject is what the event manager creates and steps**, so it is built over a copy of a
## generated city's map and no city (`tests/fixtures/street_events.gd`), as
## `tests/test_sent_down_her_line.gd` is: the lanes, the through roads, the paved boxes and the way a
## row leaves are the streets' and the manager's own, and a hand-drawn map would not have the
## lattice's paved boxes, absorbed streets, corners and edges this asks about. The walk is a recipe's
## (`EventManager.start_recipe()`), with nothing planned in it but the lorry where there is one.

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
## How many times real time the engine takes its ticks (`PhysicsTicks.pass_ticks_faster()`), and the
## sleep a headless engine takes every frame while the walk runs (`OS.low_processor_usage_mode_sleep_usec`,
## 6900 by default, which would hold every tick to it): together enough that the walk is held up by the
## work of a tick rather than by the engine's own pace.
const TICKS_FASTER := 64
const FRAME_SLEEP_USEC := 200
## Plain sidewalk tiles she starts from on each axis, in each city.
const PLAIN_EACH_AXIS := 2
## Of the streets on past a box into a paved box, one in this many is a place she starts before, and
## of the other streets on past a box that are not a car's, one in this many.
const PAVED_ONE_IN := 1
const STUB_ONE_IN := 6
## How far short of the box past her she stands, before a dead end and toward a field, in tiles.
const BEFORE_THE_BOX := 2
## Streets running on through three boxes with a lorry beyond the second, on each axis, in each city.
const FIELDS_EACH_AXIS := 1
## How far past the second box past her the lorry stands, along the street, in tiles: past where that
## box's leg ends by more than the lorry's field, and short of the third box.
const LORRY_PAST := 7
## How far back from a paved box she stands, in tiles: right beside it, and a few tiles back.
const BACK_FROM_THE_BOX: Array[int] = [0, 6]
## Game seconds of her walking before her route's one marble is due, then how long a place waits for
## its row to be created, and the most it watches one.
const FIRST_AFTER := 0.5
const WAIT_FOR_ONE := 3.0
const WATCH_FOR := 36.0
## Watched longer than this, a row was followed a good while.
const LONG_WATCH := 15.0
## How long a car leaving may stand in her view before it counts as standing.
const STANDS_FOR := 2.0
## Walking after a row, she stands while she is this near it; walking with one, she waits for it once
## she is this far ahead of it.
const KEEP := 64.0
## A car's middle to either end along the way it faces, and the box about it the view must clear for
## it not to be seen (`tests/test_patrol_vanish.gd`'s `CAR_BOX`).
const HALF_LENGTH := 24.0
const CAR_BOX := Vector2(48.0, 48.0)
const CARS: Array[String] = ["police_patrol", "military_convoy"]
const ROWS: Array[String] = ["police_patrol", "military_convoy", "dog_walker"]

enum Walk { ON, WITH_IT, AFTER_IT }
enum Place { PLAIN, BEFORE_A_PAVED_BOX, BEFORE_A_STUB, BEFORE_A_CORNER, PAST_A_PAVED_BOX,
		TOWARD_A_FIELD }
const PLACE_NAMES: Array[String] = ["plain", "before a paved box", "before a stub",
		"before a box with one way out", "past a paved box", "toward a lethal row's field"]
const WALK_NAMES: Array[String] = ["walking on", "walking with it", "walking after it"]

## **Where she starts**: her place and heading, what kind of place it is, and where a lorry stands
## for it (`Vector2.INF` for none).
class Spot:
	var her: Vector2
	var heading: Vector2
	var place: Place
	var lorry := Vector2.INF

	func _init(at: Vector2, going: Vector2, kind: Place) -> void:
		her = at
		heading = going
		place = kind

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
	var seen_leaving_for := 0.0
	## Whether it turned a corner in her view while it was not leaving: a row given no further leg
	## ends its route and leaves, and a corner is only turned on a further leg.
	var turned_a_corner_live := false
	var in_a_box := false
	## The junction boxes it drove out of while she could see it.
	var boxes_left := 0
	## Whether she turned to walk its way, or after it, once it had passed her.
	var followed := false
	## What went wrong, each once: a line naming it and where.
	var faults: Array[String] = []

	func _init(of: EventInstance) -> void:
		instance = of
		row = of.row_id()
		axis = of.facing_now()
		last_axis = axis

	func fault(what: String) -> void:
		for already in faults:
			if already.begins_with(what.get_slice(" ", 0)):
				return
		faults.append(what)

## **What the watches came to**, counted by the kind of place, the row and the axis of her street.
class Tally:
	var places: Array[int] = [0, 0, 0, 0, 0, 0]
	## `"<place> <row>"` -> rows sent, and of those seen.
	var sent := {}
	var seen := {}
	## `"<row> <vertical>"` -> rows sent from a street on that axis.
	var by_axis := {}
	var long_watched := 0
	var followed := 0
	## `"<row>"` -> cars that turned a corner while still live, and that drove out of two boxes, in
	## her view, before a dead end.
	var corners := {}
	var three_legs := {}
	## `"<row>"` -> rows seen leaving for longer than the departure's backstop, toward a field.
	var long_leaving := {}
	var faults: Array[String] = []

	func count(key: String, into: Dictionary) -> void:
		into[key] = int(into.get(key, 0)) + 1

	func of(key: String, into: Dictionary) -> int:
		return int(into.get(key, 0))

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
	# A headless engine sleeps this long every frame it cannot draw, which would hold every tick of
	# the walk to it however fast the ticks are asked for; put back once the walk is done.
	var frame_sleep := OS.low_processor_usage_mode_sleep_usec
	OS.low_processor_usage_mode_sleep_usec = FRAME_SLEEP_USEC
	await _test_sent_rows_keep_to_the_road_while_she_walks(t)
	OS.low_processor_usage_mode_sleep_usec = frame_sleep
	_rig.free()

## Every place, row and walk: no sent car off its ground, standing or turning on the spot in her
## view, no sent row gone in it, and none live in a lethal row's field. Not vacuous: there are places
## of every kind; each row is sent and seen from streets on both axes; before a dead end a patrol and
## a convoy are each watched over three legs and turning a corner while still live (the followed
## convoy the player settled on, inbox #1460 in silky-lemur); some car is watched a good while;
## and toward a field rows are seen leaving for longer than the departure's backstop.
func _test_sent_rows_keep_to_the_road_while_she_walks(t: TestRunner) -> void:
	var tally := Tally.new()
	for index in SEEDS.size():
		var map := MapCache.of(SEEDS[index])
		var spec := DaySpec.for_day(DAY)
		var tree := RouteTree.for_day(map, DAY, null)
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
		var watches: Array[Array] = []
		for spot in _places(map):
			tally.places[spot.place] += 1
			match spot.place:
				Place.PLAIN:
					for row in ROWS:
						for walk: Walk in [Walk.ON, Walk.WITH_IT, Walk.AFTER_IT]:
							watches.append([spot, row, walk])
				Place.BEFORE_A_PAVED_BOX, Place.BEFORE_A_STUB, Place.BEFORE_A_CORNER:
					for row in CARS:
						watches.append([spot, row, Walk.AFTER_IT])
				Place.PAST_A_PAVED_BOX:
					for row in CARS:
						watches.append([spot, row, Walk.WITH_IT])
				Place.TOWARD_A_FIELD:
					watches.append([spot, "police_patrol", Walk.WITH_IT])
					watches.append([spot, "military_convoy", Walk.AFTER_IT])
					watches.append([spot, "dog_walker", Walk.AFTER_IT])
		for watch: Array in watches:
			var spot: Spot = watch[0]
			var row: String = watch[1]
			var walk: Walk = watch[2]
			streets.begin_day(tree, region, closures)
			var plans: Array[EventPlan] = []
			if spot.lorry != Vector2.INF:
				plans.append(EventPlan.new(EventCatalogue.shipped().by_id("reversing_lorry"), spot.lorry))
			var watched := await _watch(t, events, map, spec, row, spot, walk, plans)
			_count(tally, watched, spot, row, walk, map, SEEDS[index])
		events.free()
	_check(t, tally)

## Adds what one watch saw to `tally`.
static func _count(tally: Tally, watched: Array[Watched], spot: Spot, row: String, walk: Walk,
		map: CityMap, seed_value: int) -> void:
	var vertical := absf(spot.heading.y) > absf(spot.heading.x)
	for car in watched:
		tally.count("%d %s" % [spot.place, row], tally.sent)
		tally.count("%s %s" % [row, vertical], tally.by_axis)
		if car.seen_for > 0.0:
			tally.count("%d %s" % [spot.place, row], tally.seen)
		tally.long_watched += 1 if car.row in CARS and car.seen_for > LONG_WATCH else 0
		tally.followed += 1 if car.followed else 0
		if spot.place in [Place.BEFORE_A_PAVED_BOX, Place.BEFORE_A_STUB, Place.BEFORE_A_CORNER]:
			if car.turned_a_corner_live:
				tally.count(row, tally.corners)
			if car.boxes_left >= 2:
				tally.count(row, tally.three_legs)
		if spot.place == Place.TOWARD_A_FIELD \
				and car.seen_leaving_for > EventDeparture.LEAVING_GIVES_UP:
			tally.count(row, tally.long_leaving)
		for what in car.faults:
			tally.faults.append("seed %d, %s, %s, her at %s heading %s, %s: %s" % [seed_value, row,
					PLACE_NAMES[spot.place], map.world_to_tile(spot.her), spot.heading,
					WALK_NAMES[walk], what])

static func _check(t: TestRunner, tally: Tally) -> void:
	var counts: Array[String] = []
	for i in PLACE_NAMES.size():
		counts.append("%s %d" % [PLACE_NAMES[i], tally.places[i]])
	t.check(not tally.places.has(0), "there are places of every kind (%s)" % ", ".join(counts))
	for row in ROWS:
		var north_south := tally.of("%s true" % row, tally.by_axis)
		var east_west := tally.of("%s false" % row, tally.by_axis)
		t.check(north_south > 0 and east_west > 0,
				"%s is sent from streets running north-south (%d) and east-west (%d)"
				% [row, north_south, east_west])
	for place: Place in [Place.PLAIN, Place.BEFORE_A_PAVED_BOX, Place.BEFORE_A_STUB,
			Place.BEFORE_A_CORNER, Place.TOWARD_A_FIELD]:
		var sent := 0
		var seen := 0
		for row in ROWS:
			sent += tally.of("%d %s" % [place, row], tally.sent)
			seen += tally.of("%d %s" % [place, row], tally.seen)
		t.check(sent > 0 and seen > 0, "rows are sent and seen %s (%d sent, %d seen)"
				% [PLACE_NAMES[place], sent, seen])
	for row in CARS:
		t.check(tally.of(row, tally.three_legs) > 0 and tally.of(row, tally.corners) > 0,
				("before a dead end, a %s is watched over three legs (%d) and turns a corner "
				+ "still live (%d)")
				% [row, tally.of(row, tally.three_legs), tally.of(row, tally.corners)])
	t.check(tally.long_watched > 0 and tally.followed > 0,
			"some cars are watched over %.0fs (%d), and some with her walking their way (%d)"
			% [LONG_WATCH, tally.long_watched, tally.followed])
	var patrols_leaving := tally.of("police_patrol", tally.long_leaving)
	var walkers_leaving := tally.of("dog_walker", tally.long_leaving)
	t.check(patrols_leaving > 0 and walkers_leaving > 0,
			"toward a field, a patrol (%d) and a dog walker (%d) are seen leaving for over %.0fs"
			% [patrols_leaving, walkers_leaving, EventDeparture.LEAVING_GIVES_UP])
	var faults := tally.faults
	var listed := "" if faults.is_empty() else ": " + "; ".join(faults.slice(0, 8))
	if faults.size() > 8:
		listed += " and %d more" % (faults.size() - 8)
	t.check(faults.is_empty(), "no sent row leaves its ground, stands, turns on the spot, vanishes "
			+ "or comes into a kept-clear field in her view" + listed)

## One watch: `row` her route's one marble, her starting at the spot walking its heading, and walking
## on, with a row once it has passed her, or after it, as `walk` says; `plans` the walk's plans.
## Answers each sent row as she saw it.
func _watch(t: TestRunner, events: EventManager, map: CityMap, spec: DaySpec, row: String,
		spot: Spot, walk: Walk, plans: Array[EventPlan]) -> Array[Watched]:
	events.start_recipe(plans, spec, DAY, spot.her)
	events.start_recipe_route([row], [], 1, FIRST_AFTER)
	var her: Array[Vector2] = [spot.her, spot.heading]
	var following: Array[Watched] = [null]
	_rig.global_position = spot.her
	_rig.velocity = spot.heading * Tuning.WALK_SPEED
	var watched: Array[Watched] = []
	var step := FAST_SCALE / Engine.physics_ticks_per_second
	var waited: Array[float] = [0.0]
	var on_foot := Mover.on_foot()
	var each := func(_n: int) -> bool:
		waited[0] += step
		var going := her[1]
		var leader := following[0]
		if walk == Walk.AFTER_IT and leader != null:
			going = Vector2.ZERO if leader.gone else _after(map, on_foot, her[0], leader, step)
		elif walk == Walk.WITH_IT and leader != null and not leader.gone \
				and _waits_for(her[0], her[1], leader):
			going = Vector2.ZERO
		elif not _steps(map, on_foot, her[0], going, step):
			going = Vector2.ZERO
		her[0] += going * Tuning.WALK_SPEED * step
		_rig.velocity = going * Tuning.WALK_SPEED
		_rig.global_position = her[0]
		var view := VisibleView.around(her[0], null)
		for instance in events.instances():
			if instance.row_id() == row and not _has(watched, instance):
				watched.append(Watched.new(instance))
		var all_gone := true
		for car in watched:
			if car.gone:
				continue
			if not _is_live(events, car.instance):
				car.gone = true
				if car.was_seen:
					car.fault("gone in her view at %s, %.0fpx from her"
							% [map.world_to_tile(car.last), car.last.distance_to(her[0])])
				continue
			all_gone = false
			var place := car.instance.global_position
			if walk != Walk.ON and following[0] == null and car.axis.dot(her[1]) < 0.0 \
					and (place - her[0]).dot(her[1]) < -16.0:
				following[0] = car
				car.followed = true
				her[1] = -her[1]
			var seen := view.sees_any(Rect2(place - CAR_BOX * 0.5, CAR_BOX))
			if seen:
				_look_at(car, map, place, step)
			if not car.instance.is_on_its_way_out():
				for plan in plans:
					if plan.keeps_its_field_clear() \
							and plan.distance_from(place) < plan.row().field_reach() - 1.0:
						car.fault("live inside %s's field at %s, %.0fpx from it" % [plan.row_id(),
								map.world_to_tile(place), plan.distance_from(place)])
			car.last = place
			car.last_axis = car.instance.facing_now()
			car.was_seen = seen
		if watched.is_empty():
			return waited[0] >= FIRST_AFTER + WAIT_FOR_ONE
		return all_gone or waited[0] >= FIRST_AFTER + WATCH_FOR
	await PhysicsTicks.pass_ticks_faster(t,
			PhysicsTicks.ticks_for(FIRST_AFTER + WAIT_FOR_ONE + WATCH_FOR, FAST_SCALE),
			TICKS_FASTER, each, FAST_SCALE)
	return watched

## **Whether she may walk `going` from `at` this tick**: the ground a step and a little ahead is on
## the map and hers to walk.
static func _steps(map: CityMap, on_foot: Mover, at: Vector2, going: Vector2, step: float) -> bool:
	if going == Vector2.ZERO:
		return false
	var ahead := map.world_to_tile(at + going * (Tuning.WALK_SPEED * step + 8.0))
	return map.in_bounds(ahead) and map.passable(ahead, on_foot)

## **Whether, walking `going` with `leader`, she waits for it**: she is more than `KEEP` ahead of it
## along the way it faces, and stands on a sidewalk between two crossings, never by a crossing's
## paint, where a car gives way to her (`GiveWay`) and would wait for her as she waits for it.
static func _waits_for(at: Vector2, going: Vector2, leader: Watched) -> bool:
	var ahead := (at - leader.instance.global_position).dot(leader.instance.facing_now())
	if ahead <= KEEP:
		return false
	var along := at.y if absf(going.y) > absf(going.x) else at.x
	for off: float in [-2.0 * Tuning.TILE_SIZE, 0.0, 2.0 * Tuning.TILE_SIZE]:
		if CrowdLanes.corridor_at(along + off) >= 0:
			return false
	return true

## **The way she walks after `leader` this tick**: none while she is within `KEEP` of it; otherwise
## along the axis it lies furthest along, or the other where that way is not hers to walk, so she
## follows it down the street and round the corner it turns.
static func _after(map: CityMap, on_foot: Mover, at: Vector2, leader: Watched,
		step: float) -> Vector2:
	var to := leader.instance.global_position - at
	if to.length() <= KEEP:
		return Vector2.ZERO
	var along_x := Vector2(signf(to.x), 0.0)
	var along_y := Vector2(0.0, signf(to.y))
	var ways: Array[Vector2] = [along_x, along_y]
	if absf(to.y) >= absf(to.x):
		ways.reverse()
	for way in ways:
		if way != Vector2.ZERO and _steps(map, on_foot, at, way, step):
			return way
	return Vector2.ZERO

## What `car` does on a tick it is in her view, at `place`.
static func _look_at(car: Watched, map: CityMap, place: Vector2, step: float) -> void:
	car.seen_for += step
	if car.instance.is_on_its_way_out():
		car.seen_leaving_for += step
	var in_a_box := CrowdLanes.corridor_at(place.x) >= 0 and CrowdLanes.corridor_at(place.y) >= 0
	if car.in_a_box and not in_a_box:
		car.boxes_left += 1
	car.in_a_box = in_a_box
	if car.row not in CARS:
		return
	var axis := car.instance.facing_now()
	if not car.last_axis.is_zero_approx() and axis.dot(car.last_axis) < 0.0:
		car.fault("turned on the spot at %s" % map.world_to_tile(place))
	if absf(axis.dot(car.axis)) < 0.5 and not car.instance.is_on_its_way_out():
		car.turned_a_corner_live = true
	for along: float in [-HALF_LENGTH, 0.0, HALF_LENGTH]:
		var under := map.world_to_tile(place + axis * along)
		if not map.is_driveable_at(true, under):
			car.fault("on paving at %s" % under)
	var tile := map.world_to_tile(place)
	if not map.in_bounds(tile) or not map.is_carriageway(tile):
		car.fault("off the carriageway at %s" % tile)
	if car.last != Vector2.INF and place.distance_to(car.last) < 0.01:
		car.still += step
		if car.still > STANDS_FOR and car.instance.is_on_its_way_out():
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
	return is_instance_valid(car) and not car.is_gone() and events.instances().has(car)

# ------------------------------------------------------------------ the places ---

## Every place she starts from on `map`, of every kind.
static func _places(map: CityMap) -> Array[Spot]:
	var spots: Array[Spot] = []
	spots.append_array(_plain(map))
	spots.append_array(_before_dead_ends(map))
	spots.append_array(_past_paved_boxes(map))
	spots.append_array(_toward_fields(map))
	return spots

## `PLAIN_EACH_AXIS` plain sidewalk tiles beside a carriageway on streets running north-south and
## as many on streets running east-west, spread over the map, each heading one way along its street,
## the next the other.
static func _plain(map: CityMap) -> Array[Spot]:
	var north_south: Array[Vector2i] = []
	var east_west: Array[Vector2i] = []
	var size := map.size_in_tiles()
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
			if vertical:
				north_south.append(tile)
			else:
				east_west.append(tile)
	var spots: Array[Spot] = []
	for vertical: bool in [true, false]:
		var tiles := north_south if vertical else east_west
		var along := Vector2(0, 1) if vertical else Vector2(1, 0)
		for k in PLAIN_EACH_AXIS:
			var tile := tiles[(k + 1) * tiles.size() / (PLAIN_EACH_AXIS + 1)]
			spots.append(Spot.new(map.tile_to_world(tile), along if k % 2 == 0 else -along,
					Place.PLAIN))
	return spots

## **Where a car that passes her comes to a dead end on its second leg**: for every junction box
## `box` and way `out` of it where the street on to the next box is not a car's to drive
## (`_is_a_cars()`), one in `PAVED_ONE_IN` where the next box is paved (`_is_paved()`) and one in
## `STUB_ONE_IN` otherwise, and every one where it is a car's but the next box has no second way out,
## she stands `BEFORE_THE_BOX` tiles short of the box before `box`, heading away from it, on a street
## a car may drive to `box`.
static func _before_dead_ends(map: CityMap) -> Array[Spot]:
	var spots: Array[Spot] = []
	var boxes := _boxes(map)
	var paved := 0
	var stubs := 0
	for y in boxes.y:
		for x in boxes.x:
			var box := Vector2i(x, y)
			for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next := box + out
				var first := box - out * 2
				if not _on_the_lattice(next, boxes) or not _on_the_lattice(first, boxes) \
						or not _is_a_cars(map, first, out) or not _is_a_cars(map, box - out, out):
					continue
				var kind: Place
				if not _is_a_cars(map, box, out) and _is_paved(map, next, out):
					paved += 1
					if paved % PAVED_ONE_IN != 0:
						continue
					kind = Place.BEFORE_A_PAVED_BOX
				elif not _is_a_cars(map, box, out):
					stubs += 1
					if stubs % STUB_ONE_IN != 0:
						continue
					kind = Place.BEFORE_A_STUB
				elif _ways_out(map, next, boxes) < 2:
					kind = Place.BEFORE_A_CORNER
				else:
					continue
				var her := _short_of(map, box - out, out, BEFORE_THE_BOX)
				if her.size() > 0:
					spots.append(Spot.new(her[0], -Vector2(out), kind))
	return spots

## Where she stands beside a street that runs into a paved junction box: on the street's sidewalk on
## the low side (west or north), `BACK_FROM_THE_BOX` tiles back from the box, walking away from it, on
## every arm whose carriageway is a car's right up to the box and whose box is paved.
static func _past_paved_boxes(map: CityMap) -> Array[Spot]:
	var spots: Array[Spot] = []
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
						spots.append(Spot.new(map.tile_to_world(tile), Vector2(out),
								Place.PAST_A_PAVED_BOX))
	return spots

## **Streets a car drives on through three boxes past her, with a lethal row beyond the second**:
## `FIELDS_EACH_AXIS` on each axis, she `BEFORE_THE_BOX` tiles short of the first box past her heading
## away from it, and a reversing lorry `LORRY_PAST` tiles past the second box on the sidewalk across
## the street from her.
static func _toward_fields(map: CityMap) -> Array[Spot]:
	var spots: Array[Spot] = []
	var boxes := _boxes(map)
	var period := CityMap.period()
	for out: Vector2i in [Vector2i.DOWN, Vector2i.RIGHT]:
		var found := 0
		var vertical := out.x == 0
		for y in range(boxes.y - 1, -1, -1):
			for x in range(boxes.x - 1, -1, -1):
				if found >= FIELDS_EACH_AXIS:
					break
				var first := Vector2i(x, y)
				var runs_on := _on_the_lattice(first - out, boxes) \
						and _on_the_lattice(first + out * 3, boxes)
				for k in range(-1, 3):
					runs_on = runs_on and _is_a_cars(map, first + out * k, out)
				if not runs_on:
					continue
				var her := _short_of(map, first, out, BEFORE_THE_BOX)
				if her.size() == 0:
					continue
				var second := first + out
				var past := (second.y if vertical else second.x) * period + Tuning.STREET_WIDTH \
						+ LORRY_PAST - 1
				var her_offset: int = her[1]
				var far_side: Array[int] = [1, 0]
				if her_offset < Tuning.SIDEWALK_WIDTH:
					far_side = [Tuning.STREET_WIDTH - 2, Tuning.STREET_WIDTH - 1]
				var corridor := (second.x if vertical else second.y) * period
				var lorry := Vector2i(-1, -1)
				for offset in far_side:
					var tile := Vector2i(corridor + offset, past) if vertical \
							else Vector2i(past, corridor + offset)
					if map.in_bounds(tile) and map.tile_at(tile) == GameEnums.TileType.SIDEWALK:
						lorry = tile
						break
				if lorry == Vector2i(-1, -1):
					continue
				var spot := Spot.new(her[0], -Vector2(out), Place.TOWARD_A_FIELD)
				spot.lorry = map.tile_to_world(lorry)
				spots.append(spot)
				found += 1
	return spots

## **Where she stands short of junction box `box`, coming from the side a car driving `out` comes
## from**: `[her place, the corridor offset of her sidewalk tile]` on a plain sidewalk tile of the
## street through `box` along `out`, `back` tiles short of the box, or empty where there is none.
static func _short_of(map: CityMap, box: Vector2i, out: Vector2i, back: int) -> Array:
	var period := CityMap.period()
	var vertical := out.x == 0
	var along_index := box.y if vertical else box.x
	var forward := (out.y if vertical else out.x) > 0
	var near := along_index * period if forward \
			else along_index * period + Tuning.STREET_WIDTH - 1
	var along := near - back if forward else near + back
	var corridor := (box.x if vertical else box.y) * period
	for offset: int in [1, Tuning.STREET_WIDTH - 2, 0, Tuning.STREET_WIDTH - 1]:
		var tile := Vector2i(corridor + offset, along) if vertical \
				else Vector2i(along, corridor + offset)
		if map.in_bounds(tile) and map.tile_at(tile) == GameEnums.TileType.SIDEWALK \
				and map.pavement_inward(tile) != Vector2i.ZERO:
			return [map.tile_to_world(tile), offset]
	return []

## Whether the lanes in the middle of junction box `box`, as a car driving `out` crosses it, are a
## precinct's paving (`CityMap.is_driveable_at()`).
static func _is_paved(map: CityMap, box: Vector2i, out: Vector2i) -> bool:
	var period := CityMap.period()
	var vertical := out.y != 0
	var middle := (box.y if vertical else box.x) * period + Tuning.STREET_WIDTH / 2
	for lane: int in CrowdLanes.ROAD_OFFSETS:
		var across := (box.x if vertical else box.y) * period + lane
		var tile := Vector2i(across, middle) if vertical else Vector2i(middle, across)
		if map.in_bounds(tile) and not map.is_driveable_at(vertical, tile):
			return true
	return false

## How many junction boxes the lattice has each way, numbered by their corridors.
static func _boxes(map: CityMap) -> Vector2i:
	var size := map.size_in_tiles()
	var period := CityMap.period()
	return Vector2i((size.x - Tuning.STREET_WIDTH) / period + 1,
			(size.y - Tuning.STREET_WIDTH) / period + 1)

static func _on_the_lattice(box: Vector2i, boxes: Vector2i) -> bool:
	return box.x >= 0 and box.y >= 0 and box.x < boxes.x and box.y < boxes.y

## How many of the streets out of `box` are a car's to drive to the next box.
static func _ways_out(map: CityMap, box: Vector2i, boxes: Vector2i) -> int:
	var ways := 0
	for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _on_the_lattice(box + out, boxes) and _is_a_cars(map, box, out):
			ways += 1
	return ways

## **Whether the street from the middle of junction box `box` to the middle of the next box `out` is
## a car's to drive**, asked of the map's own ground as a car is stopped by it: both lanes, every tile,
## carriageway (`CityMap.is_carriageway()`), no precinct's paving (`CityMap.is_driveable_at()`), on the
## map, and ground a vehicle may stand on (`CityMap.passable()`). Where she stands is chosen by this
## rather than by `ThroughRoads`, so that a change to the through roads cannot move her.
static func _is_a_cars(map: CityMap, box: Vector2i, out: Vector2i) -> bool:
	var period := CityMap.period()
	var vertical := out.y != 0
	var from := box if (out.x + out.y) > 0 else box + out
	var first: int = CrowdLanes.ROAD_OFFSETS[0]
	var last: int = CrowdLanes.ROAD_OFFSETS[CrowdLanes.ROAD_OFFSETS.size() - 1]
	var along_from := (from.y if vertical else from.x) * period + first
	var across := (from.x if vertical else from.y) * period
	var vehicle := Mover.vehicle()
	for lane: int in CrowdLanes.ROAD_OFFSETS:
		for along in range(along_from, along_from + period + (last - first) + 1):
			var tile := Vector2i(across + lane, along) if vertical else Vector2i(along, across + lane)
			if not map.in_bounds(tile) or not map.is_carriageway(tile) \
					or not map.is_driveable_at(vertical, tile) or not map.passable(tile, vehicle):
				return false
	return true
