extends RefCounted
## `SimulationBuilder`, the one place a world's simulation is stood: a city's poster walls, events,
## crowd and blackout, and the building's events, each handed what it reads and wired to the others.
##
## **The builder's parts are real, and that is the reason this suite builds them**: what the builder
## does is wire them (the walls to the events, the events to the crowd's recycle, each to the bus and
## her), so a fake part would hold back exactly the wiring under test. What each part then does with
## what it was handed is that part's own suite. **No `City` is built**: the builder is handed the
## city's parts, never the city (`in_the_city()`), so the world is a bare `CityDressing` with nothing
## to dress and the map a hand-drawn one, a full lattice of streets with no home (`StreetMap.full()`),
## one interaction each (writing-tests, "Which map a test uses"). The one check that needs a planned
## day, a body the events stand on a lane reaching the crowd's recycle, plans it on a generated map
## from the cache (`tests/city_map_cache.gd`), since a day is planned only on a city with a home.
##
## `force_a_row()` reaching the events' director is held by `test_run_config.gd`
## (`_test_the_forced_row_is_handed_to_the_director()`, a city stood through this builder), since it
## needs a walk on a generated city's arterial; the poster art a builder is handed reaching the
## fronts is held by `test_posters.gd`.

const MapCache := preload("res://tests/city_map_cache.gd")
const FrontReads := preload("res://tests/front_reads.gd")
const CrowdStreetRig := preload("res://tests/crowd_street_rig.gd")
## The bus script, so a recording bus of the suite's own is the class the builder takes.
const _BUS := preload("res://src/autoload/event_bus.gd")
## The generated city the recycle check plans its day on, over a run of the same seed: one whose
## day 8 stands a far roadblock across a car lane.
const RECYCLE_SEED := 4242
## The run every world here belongs to.
const RUN_SEED := 2

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	_test_a_city_stands_its_four_parts_in_its_tree(t)
	_test_the_building_stands_its_events_alone(t)
	_test_the_world_answers_her_from_the_events_then_the_crowd(t)
	_test_a_dark_city_says_so_on_the_bus_it_was_handed(t)
	_test_both_worlds_events_report_on_the_bus_it_was_handed(t)
	_test_the_dressed_day_pastes_the_walls(t)
	_test_each_setting_reaches_its_part(t)
	await _test_meeting_her_reaches_the_crowd_the_walls_and_the_blackout(t)
	_test_a_body_on_a_lane_takes_the_car_there_away(t)

# ----------------------------------------------------------------- the rig ---

## A city's simulation as a test stands it: a bare dressing under `t`, holding the hand-drawn map's
## streets, its lights and `buildings`, over a run of its own, stood by `builder` (one handed only
## the bus `bus` where none is given). Returns `{world, map, streets, signals, run, simulation}`;
## free it with `_free()`.
func _city(t: TestRunner, builder: SimulationBuilder = null, bus: _BUS = null,
		dark_from_the_start := false, buildings: Array[Building] = [],
		map: CityMap = null, run_seed := RUN_SEED) -> Dictionary:
	if map == null:
		map = StreetMap.full()
	var world := CityDressing.new()
	t.add_child(world)
	# The map is drawn in this world, as a built city says of its own (`City.build()`), so what the
	# events stream in has somewhere to stand.
	map.world = world
	for building in buildings:
		world.add_child(building)
	var run := RunState.new()
	run.start_run(run_seed)
	var streets := DayStreets.new()
	var signals := TrafficSignals.new(map)
	if builder == null:
		builder = SimulationBuilder.new()
		builder.use_bus(bus)
	var simulation := builder.in_the_city(world, map, streets, signals, buildings, run,
			dark_from_the_start)
	return {"world": world, "map": map, "streets": streets, "signals": signals, "run": run,
			"simulation": simulation}

## Frees the world `_city()` or `_building()` made, and the simulation under it with it.
static func _free(made: Dictionary) -> void:
	(made["world"] as Node).free()

static func _simulation(made: Dictionary) -> WorldSimulation:
	return made["simulation"] as WorldSimulation

## The names of `node`'s children, in order.
static func _children_of(node: Node) -> Array[String]:
	var names: Array[String] = []
	for child in node.get_children():
		names.append(String(child.name))
	return names

## A recording bus of the suite's own, which only this suite hears: what a part says on the bus
## it is handed, counted by signal. Free it with `free()`.
class RecordingBus extends "res://src/autoload/event_bus.gd":
	var heard := {}

	func _init() -> void:
		city_gone_dark.connect(func() -> void: _note("city_gone_dark"))
		event_telegraphed.connect(func(_instance: Object) -> void: _note("event_telegraphed"))
		crowd_bumped.connect(func(_at: Vector2) -> void: _note("crowd_bumped"))
		poster_torn.connect(func() -> void: _note("poster_torn"))

	func _note(what: String) -> void:
		heard[what] = int(heard.get(what, 0)) + 1

	## How many times `what` was said.
	func times(what: String) -> int:
		return int(heard.get(what, 0))

## Her, pressing north the whole time, as a stick held up does: the one push the poster walls tear
## a sheet by (`Stroller.steering_direction()`). Physics off, so nothing but the test moves her.
class PressingNorth extends Stroller:
	## Overrides Stroller.steering_direction.
	func steering_direction() -> Vector2:
		return Vector2.UP

## A rig body for her, in the tree under `t` at `at` with her camera under it, physics off.
static func _her(t: TestRunner, at: Vector2) -> Stroller:
	var her := PressingNorth.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	her.add_child(camera)
	t.add_child(her)
	her.set_physics_process(false)
	her.global_position = at
	return her

# ----------------------------------------------------------- what stands ---

## **A city's simulation stands under the city as one node, its four parts its children in the
## order they tick** (posters, events, crowd, blackout), and answers each part but the blackout,
## which nothing reads back; its events site what they send at her.
func _test_a_city_stands_its_four_parts_in_its_tree(t: TestRunner) -> void:
	var made := _city(t)
	var simulation := _simulation(made)
	t.check(simulation.get_parent() == made["world"] and simulation.name == WorldSimulation.NODE_NAME,
			"a city's simulation stands under the city, under its own name")
	var in_order: Array[String] = ["Posters", "Events", "Crowd", "Blackout"]
	t.check(_children_of(simulation) == in_order and simulation.get_child(3) is Blackout,
			"its four parts are its children, in the order they tick (%s)" % [_children_of(simulation)])
	t.check(simulation.poster_walls() == simulation.get_child(0)
			and simulation.events() == simulation.get_child(1)
			and simulation.crowd() == simulation.get_child(2),
			"and it answers the walls, the events and the crowd it stood")
	t.check(simulation.events().spawn_siting() != null,
			"a city's events site what is sent at her")
	_free(made)

## **The building's simulation is its events alone, with the whole plan in the world at once**;
## the building answers her from its events' set, and meeting her there hands her to nothing, the
## events being handed her when she is put into the world (`EventManager.use_player()`).
func _test_the_building_stands_its_events_alone(t: TestRunner) -> void:
	var world := WorldContext.new()
	t.add_child(world)
	var map := StreetMap.full()
	# The map is drawn in this world, as the building's is in its scene, so what the events stand
	# has somewhere to stand.
	map.world = world
	var run := RunState.new()
	run.start_run(RUN_SEED)
	var simulation := SimulationBuilder.new().in_the_building(world, map, run)
	var events_alone: Array[String] = ["Events"]
	t.check(simulation.get_parent() == world and _children_of(simulation) == events_alone
			and simulation.events() == simulation.get_child(0),
			"the building's simulation stands its events alone (%s)" % [_children_of(simulation)])
	t.check(simulation.crowd() == null and simulation.poster_walls() == null,
			"with no crowd and no walls")
	t.check(simulation.events().stream_radius == INF,
			"its events stream the whole plan, since the building is walked through doors")
	var stretch: Vector2i = CrowdStreetRig.new().a_straight_run(map, Tuning.BLOCK_SIZE)
	var at := map.tile_to_world(Vector2i(stretch.x * CityMap.period() + 1, stretch.y + 2))
	var yeller := simulation.events().spawn_extra(EventCatalogue.by_id("homeless_yeller"), at)
	var answered := false
	for pair: Array in world.excitement_sources_at(at):
		answered = answered or pair[0] == yeller.source()
	t.check(answered, "the building answers her from its events' set")
	var her := _her(t, Vector2.ZERO)
	simulation.meet_her(her)
	t.check(not simulation.events().world.has_player(),
			"meeting her in the building hands her to nothing")
	her.free()
	world.free()

## **The world answers the baby from the events' set and then the crowd's**: a walker and a man
## yelling beside it, both charging the ground she would stand on, come back in that order.
func _test_the_world_answers_her_from_the_events_then_the_crowd(t: TestRunner) -> void:
	var made := _city(t)
	var simulation := _simulation(made)
	var map: CityMap = made["map"]
	var crowd := simulation.crowd()
	var rng := RandomNumberGenerator.new()
	rng.seed = RUN_SEED
	crowd.start_day(1, rng, Vector2.ZERO)
	crowd.clear()
	var street_rig := CrowdStreetRig.new()
	var stretch: Vector2i = street_rig.a_straight_run(map, Tuning.BLOCK_SIZE)
	var walker: CrowdAgent = street_rig.place_on(crowd, map, CrowdAgent.Kind.WALKER, stretch.x, 1,
			float(stretch.y + 2) * Tuning.TILE_SIZE, 1.0)
	var at := walker.global_position
	var events := simulation.events()
	events.start_recipe([] as Array[EventPlan], DaySpec.for_day(1), 1, at)
	var yeller := events.spawn_extra(EventCatalogue.by_id("homeless_yeller"), at + Vector2(8.0, 0.0))
	var order: Array[String] = []
	for pair: Array in (made["world"] as CityDressing).excitement_sources_at(at):
		if pair[0] == yeller.source():
			order.append("events")
		elif pair[0] == walker.mood():
			order.append("crowd")
	var events_then_crowd: Array[String] = ["events", "crowd"]
	t.check(order == events_then_crowd,
			"the world answers her from the events' set and then the crowd's (%s)" % [order])
	var sets := simulation.excitement_sources()
	t.check(sets.size() == 2 and sets[0] == events.sources and sets[1] == crowd.sources,
			"and the simulation answers the same sets in the same order, for the halo")
	_free(made)

## **A city dark from its first frame says so on the bus the builder was handed**, which it does
## inside its setup: the page counts the escape's blackout by it.
func _test_a_dark_city_says_so_on_the_bus_it_was_handed(t: TestRunner) -> void:
	var bus := RecordingBus.new()
	var made := _city(t, null, bus, true)
	t.check(bus.times("city_gone_dark") == 1,
			"a city dark from the start says it went dark on its bus (%d)" % bus.times("city_gone_dark"))
	t.check(not (made["signals"] as TrafficSignals).powered, "and its lights are out")
	_free(made)
	bus.free()

## **Both worlds' events report on the bus the builder was handed**: a row put in a city's
## simulation and one put in the building's each say on it that they are telegraphing, as the page
## counts every event it saw coming. Both worlds, since the city's and the building's managers are
## made in the one place (`_new_events()`), and a hand-in moved into the city's alone would leave
## the building's events telling nobody.
func _test_both_worlds_events_report_on_the_bus_it_was_handed(t: TestRunner) -> void:
	var bus := RecordingBus.new()
	var builder := SimulationBuilder.new()
	builder.use_bus(bus)
	var made := _city(t, builder)
	var map: CityMap = made["map"]
	var stretch: Vector2i = CrowdStreetRig.new().a_straight_run(map, Tuning.BLOCK_SIZE)
	var at := map.tile_to_world(Vector2i(stretch.x * CityMap.period() + 1, stretch.y + 2))
	var before := bus.times("event_telegraphed")
	_simulation(made).events().spawn_extra(EventCatalogue.by_id("homeless_yeller"), at)
	t.check(bus.times("event_telegraphed") == before + 1,
			"a row put in a city's simulation says it is telegraphing on the builder's bus (%d)"
			% (bus.times("event_telegraphed") - before))
	_free(made)
	var world := WorldContext.new()
	t.add_child(world)
	var building_map := StreetMap.full()
	building_map.world = world
	var run := RunState.new()
	run.start_run(RUN_SEED)
	var building := builder.in_the_building(world, building_map, run)
	before = bus.times("event_telegraphed")
	building.events().spawn_extra(EventCatalogue.by_id("homeless_yeller"), at)
	t.check(bus.times("event_telegraphed") == before + 1,
			"and so does one put in the building's (%d)" % (bus.times("event_telegraphed") - before))
	world.free()
	bus.free()

## **The day the dressing says pastes the walls**: the walls paste every dawn up to the day said.
func _test_the_dressed_day_pastes_the_walls(t: TestRunner) -> void:
	var made := _city(t)
	var run: RunState = made["run"]
	t.check(run.posters.pasted_through < 3, "the walls start before day 3's dawn")
	(made["world"] as CityDressing).day_dressed.emit(3, DaySpec.for_day(3))
	t.check(run.posters.pasted_through == 3,
			"the city dressed for day 3 pastes the walls through its dawn (%d)"
			% run.posters.pasted_through)
	_free(made)

## **Each developer setting the builder is handed reaches the part it is for**, and a builder handed
## none stands an ordinary run's parts.
func _test_each_setting_reaches_its_part(t: TestRunner) -> void:
	var ordinary := _city(t)
	var events := _simulation(ordinary).events()
	var crowd := _simulation(ordinary).crowd()
	t.check(not events.skip_drawing and events.pelican_rig == EventSpawner.PelicanRig.BAG
			and not crowd.skip_agent_drawing and not crowd.skip_motion and crowd.view == null,
			"a builder handed nothing stands an ordinary run's events and crowd")
	_free(ordinary)
	var builder := SimulationBuilder.new()
	builder.leave_out(true, true, true)
	builder.make_every_cyclist_a_pelican()
	var view := CrowdView.new()
	var timing := CrowdTiming.new()
	builder.use_the_crowds_screen(view, timing)
	var trace := RunTrace.new()
	var atlas := AtlasLibrary.new()
	var frames := FrameTiming.new()
	builder.equip(trace, atlas, frames)
	var made := _city(t, builder)
	events = _simulation(made).events()
	crowd = _simulation(made).crowd()
	t.check(events.skip_drawing and crowd.skip_agent_drawing and crowd.skip_motion,
			"--skip events, crowd and motion reach the events and the crowd")
	t.check(events.pelican_rig == EventSpawner.PelicanRig.ALWAYS,
			"--pelican reaches the events")
	t.check(crowd.view == view and crowd.timing == timing, "the screen reaches the crowd")
	t.check(events.trace == trace and events.atlas == atlas and events.timing == frames
			and crowd.atlas == atlas,
			"and what the events and the crowd are equipped with reaches each")
	_free(made)

## **Meeting her reaches the crowd, the walls and the blackout**, and nothing reaches them before:
## the crowd bumps her standing on a walker, a sheet she presses into tears, and a city counted as
## sabotaged (`--blackout`) goes dark round her, this map having no station to be near.
func _test_meeting_her_reaches_the_crowd_the_walls_and_the_blackout(t: TestRunner) -> void:
	var map := StreetMap.full()
	var front := _a_front(map, 6)
	t.check(front.x >= 0, "the hand-drawn map has a front six tiles long (%s)" % front)
	if front.x < 0:
		return
	var building := FrontReads.new_building()
	building.stand_on(Rect2i(), Vector2(6, 4) * Building.TILE, 0,
			GameEnums.BlockPurpose.RESIDENTIAL, 2.0 * Building.TILE)
	var face := map.tile_rect_to_world(Rect2i(front, Vector2i.ONE)).position
	building.position = Vector2(face.x + 3.0 * Building.TILE, face.y)
	var bus := RecordingBus.new()
	var builder := SimulationBuilder.new()
	builder.use_bus(bus)
	builder.force_the_blackout()
	var buildings: Array[Building] = [building]
	var made := _city(t, builder, null, false, buildings, map)
	var simulation := _simulation(made)
	var run: RunState = made["run"]
	var signals: TrafficSignals = made["signals"]
	var sheet := Vector2i(-1, -1)
	for tile: Vector2i in simulation.poster_walls().fronts():
		sheet = tile
	t.check(sheet.x >= 0, "the building has a blank cell on its front to paste on")
	if sheet.x < 0:
		_free(made)
		bus.free()
		return
	(made["world"] as CityDressing).day_dressed.emit(1, DaySpec.for_day(1))
	run.posters.paste(sheet, PosterArt.Kind.RULES, false, 1)
	var crowd := simulation.crowd()
	var rng := RandomNumberGenerator.new()
	rng.seed = RUN_SEED
	crowd.start_day(1, rng, Vector2.ZERO)
	crowd.clear()
	var street_rig := CrowdStreetRig.new()
	var stretch: Vector2i = street_rig.a_straight_run(map, Tuning.BLOCK_SIZE)
	var walker: CrowdAgent = street_rig.place_on(crowd, map, CrowdAgent.Kind.WALKER, stretch.x, 1,
			float(stretch.y + 2) * Tuning.TILE_SIZE, 1.0)
	walker.set_physics_process(false)
	# She presses into the sheet, her pram's body against the wall.
	var sheet_face := map.tile_rect_to_world(Rect2i(sheet, Vector2i.ONE))
	var her := _her(t, Vector2(sheet_face.get_center().x, sheet_face.position.y + 24.0))
	var a_push := PhysicsTicks.ticks_for(PosterWalls.PRESS_TO_TEAR * 2.0)
	await PhysicsTicks.pass_ticks(t, a_push)
	t.check(not run.posters.is_torn(sheet) and signals.powered,
			"before she is met nothing tears and the lights stay on")
	simulation.meet_her(her)
	await PhysicsTicks.pass_ticks(t, a_push)
	t.check(run.posters.is_torn(sheet) and bus.times("poster_torn") == 1,
			"met, her push tears the sheet, said on the bus the walls were handed")
	t.check(not signals.powered, "and the blackout, handed --blackout, puts the lights out round her")
	crowd.set_focus(walker.global_position)
	her.global_position = walker.global_position
	await PhysicsTicks.pass_ticks(t, 2)
	t.check(bus.times("crowd_bumped") > 0, "and the crowd bumps her, standing on a walker")
	her.free()
	_free(made)
	bus.free()

## The west end of a run of `length` front tiles on `map` (the sidewalk in front of a block's south
## face, where a poster crew stands), or (-1, -1) for none: the cells a building's front pastes on.
static func _a_front(map: CityMap, length: int) -> Vector2i:
	for y in map.size.y:
		var run := 0
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.pavement_inward(tile) == Vector2i.UP \
					and map.tile_at(tile + Vector2i.UP) == GameEnums.TileType.BUILDING:
				run += 1
				if run == length:
					return Vector2i(x - length + 1, y)
			else:
				run = 0
	return Vector2i(-1, -1)

# ------------------------------------------------------- the events and the crowd ---

## **A body the events stand on a lane takes the car there away** (`Crowd.recycle_cars_on()`), the
## one line where the events and the crowd meet. Day 8 drawn whole on a generated map with a
## recording listener names a far roadblock's lane tile; the simulation is stood again with the
## builder's own wiring, day 8 started at the played stream radius so that unit is still undrawn, a
## car stood on that tile (`Crowd.add_recipe_actor()`), and the draw round the start made: the car
## has moved.
func _test_a_body_on_a_lane_takes_the_car_there_away(t: TestRunner) -> void:
	var spec := DaySpec.for_day(8)
	var told: Array[Vector2i] = []
	var first := _city(t, null, null, false, [], MapCache.of(RECYCLE_SEED), RECYCLE_SEED)
	var map: CityMap = first["map"]
	var events := _simulation(first).events()
	events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	events.use_body_listener(func(tiles: Array[Vector2i]) -> void: told.append_array(tiles))
	_start(first, spec)
	events.draw_the_ground_round(Vector2.ZERO, INF)
	var period := CityMap.period()
	var candidates: Array[Vector2i] = []
	for tile in told:
		if tile.x % period in CrowdLanes.ROAD_OFFSETS \
				and map.tile_to_world(tile).length() > 2.0 * Tuning.OUT_OF_SIGHT:
			candidates.append(tile)
	t.check(not candidates.is_empty(),
			"day 8's far bodies stand on a car lane (%d tiles told)" % told.size())
	_free(first)
	# Stood again, with the wiring the builder makes and no listener of the test's own.
	var made := _city(t, null, null, false, [], MapCache.of(RECYCLE_SEED), RECYCLE_SEED)
	map = made["map"]
	events = _simulation(made).events()
	events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(made, spec)
	var crowd := _simulation(made).crowd()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [RECYCLE_SEED, 8])
	crowd.start_day(8, rng, Vector2.ZERO, false)
	crowd.clear()
	crowd.set_focus(Vector2.ZERO)
	# The first of the lane tiles a car may stand on (the crowd refuses a place in a junction, at a
	# crossing and the like).
	var car: CrowdAgent = null
	for lane_tile in candidates:
		var offset := lane_tile.x % period
		var placed := crowd.add_recipe_actor("car-under-a-body", CrowdAgent.Kind.CAR,
				Vector2(CrowdLanes.lane_centre(lane_tile.x / period, offset),
						float(lane_tile.y * Tuning.TILE_SIZE + 16)),
				Vector2(0.0, CrowdLanes.road_direction(true, offset)), 130.0, 1)
		if placed["error"] == "":
			car = placed["actor"]
			break
	t.check(car != null, "a car stands on a lane tile a far body will cover")
	if car != null:
		var was := car.position
		events.draw_the_ground_round(Vector2.ZERO, INF)
		t.check(car.position.distance_to(was) > float(Tuning.TILE_SIZE),
				"the draw that stands the body takes the car under it away (moved %.0fpx)"
				% car.position.distance_to(was))
	_free(made)

## Starts `spec`'s day on the events `made` stood, the way a rig with no dawn of the city's does:
## today's streets begun with no street closed (`RigStreets.begin()`), the day's own stream, round
## the map's origin.
static func _start(made: Dictionary, spec: DaySpec) -> void:
	RigStreets.begin(made["streets"] as DayStreets, made["map"] as CityMap, spec)
	var events := _simulation(made).events()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [RECYCLE_SEED, spec.number])
	events.start_day(spec, rng, [] as Array[String], Vector2.ZERO)
