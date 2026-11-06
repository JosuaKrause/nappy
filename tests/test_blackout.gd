extends RefCounted
## The last night's blackout: once the sabotage is done and she is far enough from the power
## station, every lit window, every traffic light and every loudspeaker mast goes off in one frame —
## and the spine it leaves behind still moves and is still fair to cross.
##
## `Blackout` is the design; these ask a real city what it did, since a window, a lamp and a mast
## are three different classes that each have to hear about it in the same call.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RecordingFrontDrawer := preload("res://tests/recording_front_drawer.gd")
const RecordingTrafficLightDrawer := preload("res://tests/recording_traffic_light_drawer.gd")
const UI := preload("res://tests/ui_screens.gd")
const SEED := 4242

## The city and its run the test now running stands in: `_begin()` builds both afresh at the top of
## every test and `_end()` frees them at its bottom, so no test reads what an earlier one left.
var _run: RunState
var _city: City
## How many car samples the last `_spine_traffic()` took.
var _sampled_cars := 0

func run(t) -> void:
	await _test_nothing_goes_dark_without_the_sabotage(t)
	await _test_nothing_goes_dark_beside_the_station(t)
	await _test_everything_goes_dark_at_once(t)
	await _test_it_stays_dark_walking_back(t)
	await _test_a_retry_gives_the_power_back(t)
	await _test_the_station_hall_is_lit_only_on_the_last_night(t)
	await _test_a_dark_junction_is_negotiated(t)
	await _test_the_dark_spine_keeps_moving(t)
	await _test_the_escape_is_dark_from_its_first_frame(t)
	await _test_the_building_is_dark_too(t)

## A city on the last day, over a run of its own (held by the city, so `_end()` frees both), with
## the sabotage not yet done.
func _begin(t) -> void:
	_city = RunCity.with_own_run(CITY_SCENE, SEED)
	_run = _city.run
	_run.resistance.sabotage_done = false
	_run.facts.escape_section = DaySpec.Section.NONE
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_start_the_last_day()

func _end() -> void:
	_city.free()
	_city = null
	_run = null

## The city after the sabotage is done and she has walked far enough south of the station.
func _go_dark() -> void:
	_run.resistance.sabotage_done = true
	_city.blackout.update(_south_of_the_station(Blackout.BLACKOUT_DISTANCE + 4.0))

func _rng(label: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("blackout:%d:%s" % [SEED, label])
	return rng

## Day 14 as the game starts it: the city's day, then its events, so the masts are real plans.
func _start_the_last_day() -> void:
	var day := Tuning.RUN_LENGTH_DAYS
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng("closures"))
	_city.events.start_day(DaySpec.for_day(day), _rng("events"), [], _city.map.power_station_door_position())
	_city.crowd.start_day(day, _rng("crowd"))

## A point `distance` px straight south of the station's lot, the way she walks off from its door.
func _south_of_the_station(distance: float) -> Vector2:
	var lot := _city.map.tile_rect_to_world(CityMap.blocks_tile_rect(_city.map.power_station))
	return Vector2(lot.get_center().x, lot.end.y + distance)

func _station_building() -> Building:
	for child in _city.get_node("Buildings").get_children():
		if child is Building and (child as Building).power_station:
			return child
	return null

func _buildings() -> Array[Building]:
	var buildings: Array[Building] = []
	for child in _city.get_node("Buildings").get_children():
		if child is Building:
			buildings.append(child)
	return buildings

func _mast_plans() -> Array[EventScheduler.Planned]:
	var masts: Array[EventScheduler.Planned] = []
	for plan in _city.events.plans():
		if plan.mast_id != "":
			masts.append(plan)
	return masts

func _spine_junction() -> Vector2i:
	return Vector2i(_city.map.main_road, 3)

# ---------------------------------------------------------------------- tests ---

func _test_nothing_goes_dark_without_the_sabotage(t) -> void:
	_begin(t)
	_city.blackout.update(_south_of_the_station(Blackout.BLACKOUT_DISTANCE * 4.0))
	t.check(not _city.blackout.is_dark, "far from the station with no sabotage, the city is lit")
	t.check(_city.signals.is_signalled(_spine_junction()), "and the spine's lights are working")
	_end()

## The station must be off screen before it goes, so the moment is the city going dark round her.
func _test_nothing_goes_dark_beside_the_station(t) -> void:
	_begin(t)
	_run.resistance.sabotage_done = true
	_city.blackout.update(_city.map.power_station_door_position())
	t.check(not _city.blackout.is_dark, "at the door she has just touched, nothing is off yet")
	_city.blackout.update(_south_of_the_station(Blackout.BLACKOUT_DISTANCE - 4.0))
	t.check(not _city.blackout.is_dark, "nor just short of the distance")
	_end()

func _test_everything_goes_dark_at_once(t) -> void:
	_begin(t)
	t.check(_mast_plans().size() > 0, "day %d carries masts to stop (%d)"
			% [Tuning.RUN_LENGTH_DAYS, _mast_plans().size()])
	var lit_windows := 0
	for building in _buildings():
		lit_windows += _lit_windows(building)
	t.check(lit_windows > 0, "there were lit windows to put out (%d)" % lit_windows)
	var quiet: Array[bool] = []
	var handler := func() -> void: quiet.append(true)
	EventBus.city_went_quiet.connect(handler)
	# A signal head on the spine's junction, handed the city's signals and a drawer that records
	# what it draws, as the city hands a head both: face-on, so it paints its lamp.
	var light := TrafficLight.new()
	var head := RecordingTrafficLightDrawer.new()
	light.drawer = head
	light.signals = _city.signals
	light.junction = _spine_junction()
	light.faces(Vector2.UP)
	t.add_child(light)
	await UI.frames(t, 2)
	var lit_head := head.shown()
	t.check(lit_head.get("picture") == TrafficLight.HEAD and lit_head.get("lamps", []).size() == 1,
			"a lit signal head shows its face with one lamp on it (%s)" % [lit_head])

	_go_dark()

	t.check(_city.blackout.is_dark, "past the distance, with the sabotage done, the city is dark")
	var still_lit := 0
	for building in _buildings():
		still_lit += _lit_windows(building)
	t.check(still_lit == 0, "every lit window went out in the same call (%d left)" % still_lit)
	t.check(not _city.signals.is_signalled(_spine_junction()),
			"the spine's lights decide nothing")
	t.check(_city.signals.has_lights(_spine_junction()), "though they still stand there")
	var still_speaking := 0
	for plan in _mast_plans():
		if not plan.silenced:
			still_speaking += 1
	t.check(still_speaking == 0, "and every mast stopped with them (%d left)" % still_speaking)
	t.check(quiet.size() == 1, "the city went quiet once (%d)" % quiet.size())
	await UI.frames(t, 2)
	var dark_head := head.shown()
	t.check(dark_head.get("frame", -1) > lit_head.get("frame", -1)
			and dark_head.get("picture") == TrafficLight.HEAD and dark_head.get("lamps", [0]).is_empty(),
			"a signal head is drawn again with no lamp at all (%s)" % [dark_head])
	light.free()
	EventBus.city_went_quiet.disconnect(handler)
	_end()

## How many of a building's windows are drawn showing a light: the lit variants of the window
## textures `Building.window_texture()` hands the drawing for each wall cell.
func _lit_windows(building: Building) -> int:
	var lit := [Building.WINDOW_LIT, Building.WINDOW_SHUTTERED_LIT, Building.WINDOW_TALL_LIT]
	var count := 0
	for index in building.columns() * building.wall_tiles():
		if building.window_texture(index) in lit:
			count += 1
	return count

func _test_it_stays_dark_walking_back(t) -> void:
	_begin(t)
	_go_dark()
	_city.blackout.update(_city.map.power_station_door_position())
	t.check(_city.blackout.is_dark, "walking back to the door does not put the lights on")
	_end()

## A lost day 14 gives the sabotage back at dawn, and with it the power: the retry is the same day.
func _test_a_retry_gives_the_power_back(t) -> void:
	_begin(t)
	_go_dark()
	t.check(_city.blackout.is_dark, "the power was off before the retry")
	_run.resistance.sabotage_done = false
	_city.blackout.update(_south_of_the_station(Blackout.BLACKOUT_DISTANCE * 4.0))
	t.check(not _city.blackout.is_dark, "with the sabotage given back, the power is back")
	t.check(_city.signals.is_signalled(_spine_junction()), "and the lights decide the spine again")
	var lit_windows := 0
	for building in _buildings():
		lit_windows += _lit_windows(building)
	t.check(lit_windows > 0, "and the same windows are lit again (%d)" % lit_windows)
	_end()

## The hall is dimly lit on the one night it is seen to go out, and drawn as approved on every other.
## A station hall dressed as the city dresses its own, handed a drawer that records its front, as the
## city hands it the real one; what is checked is the clerestory band the front was drawn with.
func _test_the_station_hall_is_lit_only_on_the_last_night(t) -> void:
	_begin(t)
	var station := _station_building()
	t.check(station != null, "the city has its station building")
	if station == null:
		_end()
		return
	var hall := Building.new()
	var front := RecordingFrontDrawer.new()
	hall.front_drawer = front
	hall.power_station = true
	hall.station_door_col = station.station_door_col
	hall.station_yard_cols = station.station_yard_cols
	hall.footprint = station.footprint
	hall.height = station.height
	hall.variant = station.variant
	hall.district = station.district
	hall.lot = station.lot
	hall.position = station.position
	hall.day = Tuning.POWER_STATION_DAY
	hall.powered = true
	t.add_child(hall)
	await UI.frames(t, 2)
	var band := _clerestory_band(front)
	var columns := hall.hall_cols().y - hall.hall_cols().x
	t.check(columns > 0 and band.size() == columns
			and band.count(Building.POWER_STATION_CLERESTORY_LIT) == columns,
			"on the last night, with the power on, the hall is lit (%s)" % [band])
	var yards := front.pictures().count(Building.POWER_STATION_YARD)
	t.check(yards == 1, "and its yard is stood beside it, once (%d)" % yards)
	front.draws.clear()
	hall.powered = false
	await UI.frames(t, 2)
	band = _clerestory_band(front)
	t.check(band.size() == columns and band.count(Building.POWER_STATION_CLERESTORY) == columns,
			"and with it off, the hall is dark (%s)" % [band])
	front.draws.clear()
	hall.powered = true
	hall.day = Tuning.POWER_STATION_DAY - 1
	await UI.frames(t, 2)
	band = _clerestory_band(front)
	t.check(band.size() == columns and band.count(Building.POWER_STATION_CLERESTORY) == columns,
			"on any other day the hall is unlit, as it always was (%s)" % [band])
	hall.free()
	_end()

## The pictures the hall's clerestory band shows now, read off what its front was last drawn with.
## Empty when the front has not been drawn since `front` was cleared.
func _clerestory_band(front: RecordingFrontDrawer) -> Array[StringName]:
	var band: Array[StringName] = []
	for entry in front.shown():
		if entry.picture in [Building.POWER_STATION_CLERESTORY, Building.POWER_STATION_CLERESTORY_LIT]:
			band.append(entry.picture)
	return band

## With no light, nothing but the crowd's own box rule decides a spine junction: a car with
## nobody crossing is let through on the spine exactly as on a side street, rather than held
## at a red that no longer shows.
func _test_a_dark_junction_is_negotiated(t) -> void:
	_begin(t)
	var signals := _city.signals
	var junction := _spine_junction()
	var reds := 0
	# One cycle of the day's signal clock in 24 steps, as the crowd's ticks advance it.
	for i in 24:
		if not signals.green_for(junction, true):
			reds += 1
		signals.advance(Tuning.signal_cycle_seconds() / 24.0)
	t.check(reds > 0, "a lit spine junction holds its own traffic for part of the cycle (%d/24)"
			% reds)
	_go_dark()
	t.check(not signals.is_signalled(junction),
			"a dark one is left to the crowd's own give-way, the same as a side street's")
	_end()

## A spine left to the box rule still carries its traffic: right before left and "nothing enters a
## box it cannot leave" hold a five-times-busier street together without a light. Stated against the
## lit spine on the same day rather than as a speed, since what is being asked is that the dark one
## is no car park by comparison.
func _test_the_dark_spine_keeps_moving(t) -> void:
	_begin(t)
	var lit: Vector2 = await _spine_traffic(t)
	var lit_samples := _sampled_cars
	_go_dark()
	var dark: Vector2 = await _spine_traffic(t)
	_sampled_cars = mini(_sampled_cars, lit_samples)
	print("[test_blackout] spine traffic over 40s, lit: mean %.0f px/s, %.0f%% stopped; "
			% [lit.x, lit.y * 100.0] + "dark: mean %.0f px/s, %.0f%% stopped"
			% [dark.x, dark.y * 100.0])
	t.check(_sampled_cars > 0, "there were cars on the spine to sample (%d samples)" % _sampled_cars)
	t.check(dark.x >= lit.x * 0.8,
			"the dark spine carries its traffic about as fast as the lit one (%.0f vs %.0f px/s)"
			% [dark.x, lit.x])
	t.check(dark.y < 0.5, "and most of it is moving at any instant (%.0f%% stopped)"
			% (dark.y * 100.0))
	_end()

## Mean speed and stopped share of the cars on the spine, sampled every half second over forty
## seconds of the crowd's own physics ticks, with a stroller standing on the sidewalk beside the
## spine for the crowd to make way for, so the field is over the spine and the cars there are the
## ones being simulated. The spine is lit or dark as the city left it.
func _spine_traffic(t) -> Vector2:
	_city.crowd.start_day(Tuning.RUN_LENGTH_DAYS, _rng("traffic"))
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	her.add_child(camera)
	_city.add_child(her)
	her.set_physics_process(false)
	her.global_position = _sidewalk_beside_the_spine()
	_city.crowd.use_player(her)
	var totals := {"speed": 0.0, "stopped": 0, "samples": 0}
	var sample := func(ticks: int) -> bool:
		if ticks % 30 != 0:
			return false
		for agent in _city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR or not agent.travelling_vertically() \
					or not _city.map.is_main_road(true, CrowdLanes.corridor_at(agent.position.x)):
				continue
			totals.samples += 1
			totals.speed += agent.speed()
			if agent.speed() < Tuning.CAR_STOPPED_SPEED:
				totals.stopped += 1
		return false
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(40.0, 1.0), sample)
	_city.crowd.use_player(null)
	her.free()
	_sampled_cars = totals.samples
	return Vector2(totals.speed / maxf(1.0, totals.samples),
			float(totals.stopped) / maxf(1.0, totals.samples))

## A sidewalk tile beside the spine at the map's middle height, where a body stands off the
## carriageway the cars drive on.
func _sidewalk_beside_the_spine() -> Vector2:
	var row := _city.map.size.y / 2
	for x in range(_city.map.main_road * CityMap.period(),
			_city.map.main_road * CityMap.period() + Tuning.STREET_WIDTH + 1):
		var tile := Vector2i(x, row)
		if _city.map.tile_at(tile) == GameEnums.TileType.SIDEWALK:
			return _city.map.tile_to_world(tile)
	return _city.map.tile_to_world(Vector2i(_city.map.main_road * CityMap.period(), row))

## The escape is the same night, so a city built for it — its `DaySpec` dark from the start — is
## dark before its first frame.
func _test_the_escape_is_dark_from_its_first_frame(t) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	city.run.resistance.sabotage_done = true
	city.run.facts.escape_section = DaySpec.Section.NONE
	city.dark_from_the_start = DaySpec.for_section(DaySpec.Section.CITY, 180.0).dark_from_the_start
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	t.check(city.blackout.is_dark, "the escape's city is dark from the moment it is built")
	t.check(not city.signals.powered, "its lights with it")
	city.free()

## The building she escapes through is the same night: the hallways and the lobby in the gloom, the
## basement darker, the stairwells on the red emergency lighting, and a hallway lit by a blast while
## its windows flash. Every door is asked which part it is in, since a door's id names its part and
## the light is chosen by the part.
func _test_the_building_is_dark_too(t) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var plan := InteriorMap.build()
	var misplaced := 0
	for id: String in plan.doors:
		var door: InteriorMapPlan.Door = plan.doors[id]
		if InteriorMap.part_at(door.tile) != id.split(":")[0]:
			misplaced += 1
	t.check(plan.doors.size() > 0 and misplaced == 0,
			"every door is in the part its id names (%d of %d misplaced)"
			% [misplaced, plan.doors.size()])
	var hallway := scene.lighting_at(plan.waypoints["hallway_second"])
	var lobby := scene.lighting_at(plan.waypoints["lobby"])
	var basement := scene.lighting_at(plan.waypoints["basement"])
	var stairs := scene.lighting_at(plan.waypoints["stairwell_left"])
	t.check(hallway == Palette.ESCAPE_GLOOM and lobby == Palette.ESCAPE_GLOOM,
			"the hallways and the lobby are in the gloom")
	t.check(basement.get_luminance() < hallway.get_luminance(),
			"and the basement is darker than they are")
	t.check(stairs == Palette.ESCAPE_EMERGENCY_RED,
			"the stairwells are on the red emergency lighting")
	t.check(scene.lighting_at(plan.waypoints["stairwell_right"]) == stairs,
			"both of them")
	scene.flash_windows()
	t.check(scene.lighting_at(plan.waypoints["hallway_second"]).get_luminance()
			> hallway.get_luminance(), "a hallway is lit up while its windows flash")
	t.check(scene.lighting_at(plan.waypoints["stairwell_left"]) == stairs,
			"a stairwell, with no windows, is not")
	scene.free()
