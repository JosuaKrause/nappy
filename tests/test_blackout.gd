extends RefCounted
## The last night's blackout: once the sabotage is done and she is far enough from the power
## station, every lit window, every traffic light and every loudspeaker mast goes off in one frame —
## and the spine it leaves behind still moves and is still fair to cross.
##
## `Blackout` is the design; these ask a real city what it did, since a window, a lamp and a mast
## are three different classes that each have to hear about it in the same call.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

var _city: City

func run(t) -> void:
	var saved_sabotage := GameState.sabotage_done
	var saved_section := GameState.escape_section
	GameState.sabotage_done = false
	GameState.escape_section = FinaleController.Section.NONE
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_start_the_last_day()

	_test_nothing_goes_dark_without_the_sabotage(t)
	_test_nothing_goes_dark_beside_the_station(t)
	_test_everything_goes_dark_at_once(t)
	_test_it_stays_dark_walking_back(t)
	_test_a_retry_gives_the_power_back(t)
	_test_the_station_hall_is_lit_only_on_the_last_night(t)
	_test_a_dark_junction_is_negotiated(t)
	_test_the_dark_spine_is_crossed_on_the_horn(t)
	_test_the_dark_spine_keeps_moving(t)
	_city.free()

	_test_the_escape_is_dark_from_its_first_frame(t)
	GameState.sabotage_done = saved_sabotage
	GameState.escape_section = saved_section

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
	_city.events.start_day(day, _rng("events"), [], _city.map.power_station_door_position())
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
	GameState.sabotage_done = false
	_city.blackout.update(_south_of_the_station(Tuning.BLACKOUT_DISTANCE * 4.0))
	t.check(not _city.blackout.is_dark, "far from the station with no sabotage, the city is lit")
	t.check(_city.signals.is_signalled(_spine_junction()), "and the spine's lights are working")

## The station must be off screen before it goes, so the moment is the city going dark round her.
func _test_nothing_goes_dark_beside_the_station(t) -> void:
	GameState.sabotage_done = true
	_city.blackout.update(_city.map.power_station_door_position())
	t.check(not _city.blackout.is_dark, "at the door she has just touched, nothing is off yet")
	_city.blackout.update(_south_of_the_station(Tuning.BLACKOUT_DISTANCE - 4.0))
	t.check(not _city.blackout.is_dark, "nor just short of the distance")

func _test_everything_goes_dark_at_once(t) -> void:
	t.check(_mast_plans().size() > 0, "day %d carries masts to stop (%d)"
			% [Tuning.RUN_LENGTH_DAYS, _mast_plans().size()])
	var lit_windows := 0
	for building in _buildings():
		for i in building._windows.size():
			if building._lit(i):
				lit_windows += 1
	t.check(lit_windows > 0, "there were lit windows to put out (%d)" % lit_windows)
	var quiet: Array[bool] = []
	var handler := func() -> void: quiet.append(true)
	EventBus.city_went_quiet.connect(handler)

	GameState.sabotage_done = true
	_city.blackout.update(_south_of_the_station(Tuning.BLACKOUT_DISTANCE + 4.0))

	t.check(_city.blackout.is_dark, "past the distance, with the sabotage done, the city is dark")
	var still_lit := 0
	for building in _buildings():
		for i in building._windows.size():
			if building._lit(i):
				still_lit += 1
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
	var light := TrafficLight.new()
	light.signals = _city.signals
	t.check(light._lamp() == TrafficLight.DARK, "a signal head shows no lamp at all")
	light.free()
	EventBus.city_went_quiet.disconnect(handler)

func _test_it_stays_dark_walking_back(t) -> void:
	_city.blackout.update(_city.map.power_station_door_position())
	t.check(_city.blackout.is_dark, "walking back to the door does not put the lights on")

## A lost day 14 gives the sabotage back at dawn, and with it the power: the retry is the same day.
func _test_a_retry_gives_the_power_back(t) -> void:
	GameState.sabotage_done = false
	_city.blackout.update(_south_of_the_station(Tuning.BLACKOUT_DISTANCE * 4.0))
	t.check(not _city.blackout.is_dark, "with the sabotage given back, the power is back")
	t.check(_city.signals.is_signalled(_spine_junction()), "and the lights decide the spine again")
	var lit_windows := 0
	for building in _buildings():
		for i in building._windows.size():
			if building._lit(i):
				lit_windows += 1
	t.check(lit_windows > 0, "and the same windows are lit again (%d)" % lit_windows)

## The hall is dimly lit on the one night it is seen to go out, and drawn as approved on every other.
func _test_the_station_hall_is_lit_only_on_the_last_night(t) -> void:
	var station := _station_building()
	t.check(station != null, "the city has its station building")
	if station == null:
		return
	var day := station.day
	station.day = Tuning.POWER_STATION_DAY
	station.powered = true
	t.check(station._clerestory_texture() == Building.POWER_STATION_CLERESTORY_LIT,
			"on the last night, with the power on, the hall is lit")
	station.powered = false
	t.check(station._clerestory_texture() == Building.POWER_STATION_CLERESTORY,
			"and with it off, the hall is dark")
	station.powered = true
	station.day = Tuning.POWER_STATION_DAY - 1
	t.check(station._clerestory_texture() == Building.POWER_STATION_CLERESTORY,
			"on any other day the hall is unlit, as it always was")
	station.day = day

## With no light, nothing but the crowd's own box rule decides a spine junction: a car with
## nobody crossing is let through on the spine exactly as on a side street, rather than held
## at a red that no longer shows.
func _test_a_dark_junction_is_negotiated(t) -> void:
	var signals := _city.signals
	var junction := _spine_junction()
	var reds := 0
	signals.powered = true
	for i in 24:
		signals.elapsed = float(i) / 24.0 * Tuning.signal_cycle_seconds()
		if not signals.green_for(junction, true):
			reds += 1
	t.check(reds > 0, "a lit spine junction holds its own traffic for part of the cycle (%d/24)"
			% reds)
	signals.powered = false
	t.check(not signals.is_signalled(junction),
			"a dark one is left to the crowd's own give-way, the same as a side street's")
	signals.powered = true

## The contract a dark crossing of the spine keeps is the side street's: the painted carriageway
## and the horn, since the spine's traffic does not give way at its zebras lit or dark.
func _test_the_dark_spine_is_crossed_on_the_horn(t) -> void:
	t.check(Tuning.validate_signals(), "the spine is fair to cross with the lights on and off")
	t.check(Tuning.CAR_HORN_TIME >= Tuning.required_horn_time(),
			"the horn %.2fs covers the spine's %.0fpx of carriageway doubled (%.2fs)"
			% [Tuning.CAR_HORN_TIME, Tuning.carriageway_width(), Tuning.required_horn_time()])

## A spine left to the box rule still carries its traffic: right before left and "nothing enters a
## box it cannot leave" hold a five-times-busier street together without a light. Stated against the
## lit spine on the same day rather than as a speed, since what is being asked is that the dark one
## is no car park by comparison.
func _test_the_dark_spine_keeps_moving(t) -> void:
	var lit := _spine_traffic(true)
	var dark := _spine_traffic(false)
	print("[test_blackout] spine traffic over 40s, lit: mean %.0f px/s, %.0f%% stopped; "
			% [lit.x, lit.y * 100.0] + "dark: mean %.0f px/s, %.0f%% stopped"
			% [dark.x, dark.y * 100.0])
	t.check(dark.x >= lit.x * 0.8,
			"the dark spine carries its traffic about as fast as the lit one (%.0f vs %.0f px/s)"
			% [dark.x, lit.x])
	t.check(dark.y < 0.5, "and most of it is moving at any instant (%.0f%% stopped)"
			% (dark.y * 100.0))
	_city.signals.powered = true

## Mean speed and stopped share of the cars on the spine, sampled over forty seconds of a real
## crowd step, with the field on the spine so the cars there are the ones being simulated.
func _spine_traffic(powered: bool) -> Vector2:
	_city.crowd.start_day(Tuning.RUN_LENGTH_DAYS, _rng("traffic"))
	_city.signals.powered = powered
	var centre := Vector2((_city.map.main_road * CityMap.period()
			+ Tuning.STREET_WIDTH * 0.5) * Tuning.TILE_SIZE, _city.map.world_size().y * 0.5)
	_city.crowd.set_focus(centre)
	var speed_sum := 0.0
	var stopped := 0
	var samples := 0
	for i in int(round(40.0 / STEP)):
		_city.crowd.step(STEP)
		if i % 30 != 0:
			continue
		for agent in _city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR or not agent._vertical \
					or not _city.map.is_main_road(true, agent._corridor):
				continue
			samples += 1
			speed_sum += agent.speed()
			if agent.speed() < Tuning.CAR_STOPPED_SPEED:
				stopped += 1
	return Vector2(speed_sum / maxf(1.0, samples), float(stopped) / maxf(1.0, samples))

## The escape is the same night, so a city built for it is dark before its first frame.
func _test_the_escape_is_dark_from_its_first_frame(t) -> void:
	GameState.sabotage_done = true
	GameState.escape_section = FinaleController.Section.CITY
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	t.check(city.blackout.is_dark, "the escape's city is dark from the moment it is built")
	t.check(not city.signals.powered, "its lights with it")
	city.free()
	GameState.escape_section = FinaleController.Section.NONE
