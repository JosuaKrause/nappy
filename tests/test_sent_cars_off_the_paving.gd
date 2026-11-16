extends RefCounted
## **A car the director sends ahead of her never drives on a precinct's paving while she could see
## it** (`EventDirector.leg_in_the_lane()`): the police patrol and the military convoy it sends down
## a lane of the road beside her (`EventDef.is_sent_ahead()`), from the moment each is created until
## it is gone. A car that has run out of route leaves straight on until it is `Tuning.OUT_OF_SIGHT`
## from her (`EventDeparture.begin()`), so what is asked is where the car is, on its leg and on its
## way out alike, not where its leg ends.
##
## Every street of a generated city that runs into a paved junction box (a precinct on either street
## paves the box, `CityMap.is_driveable_at()`) is asked: she stands on its sidewalk at a few
## distances back from the box (`BACK_FROM_THE_BOX`), walking away from it, so the patrol comes down
## the lane toward her and on toward the box, and the convoy comes from either end. Her route's bag
## holds one marble of the row (`EventManager.start_recipe_route()`, the way a scene recipe rigs
## one), and every car of it is watched a tick at a time until it is gone: the tiles under its middle
## and its two ends must be carriageway on every tick it is in her view.
##
## **The subject is what the event manager creates and steps**, so it is built over a copy of the
## generated city's map and no city (`tests/fixtures/street_events.gd`), as
## `tests/test_sent_down_her_line.gd` is: the lanes, the paved boxes and the way a car leaves are the
## streets' and the manager's own, and nothing else of a city is read. The walk is a recipe's with
## nothing planned in it (`EventManager.start_recipe()`), so no plan refuses a car room.

const MapCache := preload("res://tests/city_map_cache.gd")
## The city: the one the third review of the sent rows measured the patrol crossing a paved box on.
const SEED := 4242
## The run's seed, for the run the events belong to.
const RUN_SEED := 2
## The engine's clock for the walk, sped up and put back after it.
const FAST_SCALE := 3.0
## How far back from the paved box she stands, in tiles: right beside it, where a leg cut at the box
## ends level with her; nearer than a car leaving is in her sight; and far enough back that a car is
## sent and is gone before the box.
const BACK_FROM_THE_BOX: Array[int] = [0, 6, 15]
## Game seconds of her walking before her route's one marble is due, then how long a place waits for
## its car to be created, and the most it watches one.
const FIRST_AFTER := 0.5
const WAIT_FOR_ONE := 3.0
const WATCH_FOR := 24.0
## A car's middle to either end along the way it faces, and the box about it the view must clear for
## it not to be seen (`tests/test_patrol_vanish.gd`'s `CAR_BOX`).
const HALF_LENGTH := 24.0
const CAR_BOX := Vector2(48.0, 48.0)

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
	await _test_no_sent_car_is_on_paving_in_her_view(t)
	_rig.free()

## For each place beside a street into a paved box and each of the two rows, no car is seen on
## paving. Not vacuous: there are such places, and cars are sent there and driven through her view.
func _test_no_sent_car_is_on_paving_in_her_view(t: TestRunner) -> void:
	var map := MapCache.of(SEED)
	var run := RunState.new()
	run.start_run(RUN_SEED)
	var streets := DayStreets.new()
	var events := StreetEvents.over(t, map, run, streets)
	events.use_player(_rig)
	var spots := _beside_paved_boxes(map)
	var cars := 0
	var seen_ticks := 0
	var on_paving: Array[String] = []
	for spot: Array in spots:
		for row: String in ["police_patrol", "military_convoy"]:
			var watched := await _watch(t, events, map, streets, row, spot[0], spot[1])
			cars += watched[0]
			seen_ticks += watched[1]
			for tile: Vector2i in watched[2]:
				on_paving.append("%s, her at %s: on %s" % [row, map.world_to_tile(spot[0]), tile])
	events.free()
	t.check(spots.size() > 0, "there are places beside a street into a paved box (%d)" % spots.size())
	t.check(cars > 0 and seen_ticks > 0,
			"cars are sent there and driven through her view (%d cars, %d ticks in view)"
			% [cars, seen_ticks])
	t.check(on_paving.is_empty(), "no sent car is on paving while she could see it%s"
			% ("" if on_paving.is_empty() else ": " + "; ".join(on_paving.slice(0, 8))
			+ (" and %d more" % (on_paving.size() - 8) if on_paving.size() > 8 else "")))

## `row`, her route's one marble, while she stands at `her` walking `heading`: `[cars created, ticks
## one was in her view, the paving tiles one was on in her view]`, watched until the car is gone.
func _watch(t: TestRunner, events: EventManager, map: CityMap, streets: DayStreets, row: String,
		her: Vector2, heading: Vector2) -> Array:
	var spec := DaySpec.for_day(13)
	RigStreets.begin(streets, map, spec)
	var no_plans: Array[EventPlan] = []
	events.start_recipe(no_plans, spec, 13, her)
	events.start_recipe_route([row], [], 1, FIRST_AFTER)
	_rig.global_position = her
	_rig.velocity = heading * Tuning.WALK_SPEED
	var view := VisibleView.around(her, null)
	var cars: Array[EventInstance] = []
	var seen := [0]
	var paving: Array[Vector2i] = []
	var step := FAST_SCALE / Engine.physics_ticks_per_second
	var waited := [0.0]
	var each := func(_n: int) -> bool:
		waited[0] += step
		for instance in events.instances():
			if instance.def.id == row and not cars.has(instance):
				cars.append(instance)
		for car in cars:
			if not _is_live(events, car):
				continue
			var at := car.global_position
			if not view.sees_any(Rect2(at - CAR_BOX * 0.5, CAR_BOX)):
				continue
			seen[0] += 1
			var axis := car.solid_axis()
			for along: float in [-HALF_LENGTH, 0.0, HALF_LENGTH]:
				var tile := map.world_to_tile(at + axis * along)
				if not map.is_driveable_at(true, tile) and not paving.has(tile):
					paving.append(tile)
		if cars.is_empty():
			return waited[0] >= FIRST_AFTER + WAIT_FOR_ONE
		return not _is_live(events, cars[0]) or waited[0] >= WATCH_FOR
	await PhysicsTicks.pass_ticks_faster(t,
			PhysicsTicks.ticks_for(FIRST_AFTER + WAIT_FOR_ONE + WATCH_FOR, FAST_SCALE),
			PhysicsTicks.FASTER, each, FAST_SCALE)
	return [cars.size(), seen[0], paving]

## Whether `car` is still in the manager's world.
static func _is_live(events: EventManager, car: EventInstance) -> bool:
	return is_instance_valid(car) and not car.is_finished and events.instances().has(car)

## Where she stands beside a street that runs into a paved junction box: `[her, heading]`, on the
## street's sidewalk on the low side (west or north), `BACK_FROM_THE_BOX` tiles back from the box,
## walking away from it, on every arm whose carriageway is a car's right up to the box and whose box
## is paved.
static func _beside_paved_boxes(map: CityMap) -> Array:
	var spots := []
	var period := CityMap.period()
	var size := map.size_in_tiles()
	var side := Tuning.SIDEWALK_WIDTH - 1
	for bx in range(0, size.x, period):
		for by in range(0, size.y, period):
			var origin := Vector2i(bx, by)
			for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var vertical := out.x == 0
				var across := Vector2i(1, 0) if vertical else Vector2i(0, 1)
				# The box's row on this arm's side, the box's tile in it on the carriageway, and the
				# arm's first tile out of the box.
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
