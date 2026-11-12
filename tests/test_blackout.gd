extends RefCounted
## The last night's blackout: once the sabotage is done and she is far enough from the power
## station, every lit window, every traffic light and every loudspeaker mast goes off in one frame.
##
## **This suite tests `Blackout`, the one decision**: when the city goes dark, once, and when it comes
## back. It builds no city and plans no day. The parts the blackout switches are stand-ins that keep
## what it did to them: the parts `Blackout` is handed (a hand-drawn map with a power station on it,
## a run's resistance, a `TrafficSignals` that holds the one `powered` flag, a `FakeEventManager`
## that counts the masts it is asked to silence) and three `Building`s that were never put in a
## world. The map's station is the lot seed 4242's generated city has, read off once.
##
## What each switched part does once it is off is that part's own suite: a hall and its clerestory
## (`tests/test_power_station.gd`), a signal head and a light that decides nothing
## (`tests/test_traffic_light.gd`, `tests/test_traffic_signals.gd`), the spine's traffic with its lights
## out (`tests/test_dark_spine.gd`), every mast silenced (`tests/test_masts.gd`), and the escape
## building's lighting (`tests/test_interior.gd`).

const BASE_SEED := 4242
## Seed 4242's generated power station: the pair of blocks it stands on and the door's tile rect.
const STATION := Rect2i(Vector2i(6, 2), Vector2i(2, 1))
const STATION_DOOR := Rect2i(Vector2i(93, 42), Vector2i(2, 1))
## How many windows' worth of buildings the blackout is handed.
const BUILDINGS := 3

## The run's resistance the test now running hands the blackout: `_begin()` makes it afresh at the top
## of every test and `_end()` frees what it made at its bottom, so no test reads what an earlier one
## left.
var _resistance: ResistanceRunState
var _map: CityMap
var _signals: TrafficSignals
var _events: FakeEventManager
var _buildings: Array[Building] = []
var _blackout: Blackout
## Her, once a test has stood her somewhere: a node in the group the blackout finds her through.
var _her: Node2D
## How many times the city said it went dark (`EventBus.city_gone_dark`) and how many times it said
## it went quiet (`EventBus.city_went_quiet`) since `_begin()`.
var _went_dark := 0
var _went_quiet := 0

func run(t: TestRunner) -> void:
	await _test_nothing_goes_dark_without_the_sabotage(t)
	await _test_nothing_goes_dark_beside_the_station(t)
	await _test_everything_goes_dark_at_once(t)
	await _test_it_stays_dark_walking_back(t)
	await _test_a_retry_gives_the_power_back(t)
	_test_the_escape_is_dark_from_its_first_frame(t)

## A blackout over a city on the last day with the sabotage not yet done, handed its parts the way
## `City.build()` hands them, and in the tree.
func _begin(t: TestRunner, from_the_start := false) -> void:
	_resistance = ResistanceRunState.new()
	_resistance.sabotage_done = false
	_map = CityMap.new()
	_map.record_power_station(STATION, Vector3i(-1, -1, -1), STATION_DOOR, 0)
	_signals = TrafficSignals.new(null)
	_events = FakeEventManager.new()
	_events.masts_to_silence = 2
	_buildings.clear()
	for i in BUILDINGS:
		_buildings.append(Building.new())
	_went_dark = 0
	_went_quiet = 0
	EventBus.city_gone_dark.connect(_count_dark)
	EventBus.city_went_quiet.connect(_count_quiet)
	_blackout = Blackout.new()
	_blackout.dark_from_the_start = from_the_start
	t.add_child(_blackout)
	_blackout.setup(_map, _buildings, _signals, _events, _resistance)

func _count_dark() -> void:
	_went_dark += 1

func _count_quiet() -> void:
	_went_quiet += 1

func _end() -> void:
	EventBus.city_gone_dark.disconnect(_count_dark)
	EventBus.city_went_quiet.disconnect(_count_quiet)
	_blackout.free()
	if is_instance_valid(_her):
		_her.free()
	for building in _buildings:
		building.free()
	_events.free()
	_blackout = null
	_her = null
	_resistance = null
	_map = null
	_signals = null
	_events = null

## The sabotage done: the flag the blackout watches, which the last night's contact at the station sets
## (`ResistanceDirector`, where `tests/test_resistance_*` hold how). The blackout is stated over the
## flag and never over how it was set.
func _do_the_sabotage() -> void:
	_resistance.sabotage_done = true

## The city after the sabotage is done and she has walked far enough south of the station.
func _go_dark(t: TestRunner) -> void:
	_do_the_sabotage()
	await _she_stands_at(t, _south_of_the_station(Blackout.BLACKOUT_DISTANCE + 4.0))

## She stands at `point` for two physics ticks, which is how often the blackout looks at where she is:
## a node in the `player` group, which is where the blackout finds her.
func _she_stands_at(t: TestRunner, point: Vector2) -> void:
	if not is_instance_valid(_her):
		_her = Node2D.new()
		_her.add_to_group("player")
		t.add_child(_her)
	_her.global_position = point
	await PhysicsTicks.pass_ticks(t, 2)

## Whether the city's lights are out, as the one flag the blackout puts them out by shows it.
func _is_dark() -> bool:
	return not _signals.powered

## How many of the buildings the blackout was handed still have their power.
func _powered_buildings() -> int:
	var count := 0
	for building in _buildings:
		if building.powered:
			count += 1
	return count

## A point `distance` px straight south of the station's lot, the way she walks off from its door.
func _south_of_the_station(distance: float) -> Vector2:
	var lot := _map.tile_rect_to_world(CityMap.blocks_tile_rect(_map.power_station))
	return Vector2(lot.get_center().x, lot.end.y + distance)

# ---------------------------------------------------------------------- tests ---

func _test_nothing_goes_dark_without_the_sabotage(t: TestRunner) -> void:
	_begin(t)
	await _she_stands_at(t, _south_of_the_station(Blackout.BLACKOUT_DISTANCE * 4.0))
	t.check(not _is_dark() and _went_dark == 0, "far from the station with no sabotage, the city is lit")
	t.check(_powered_buildings() == BUILDINGS and _events.silenced_all == 0,
			"and its windows are lit and its masts speak")
	_end()

## The station must be off screen before it goes, so the moment is the city going dark round her.
func _test_nothing_goes_dark_beside_the_station(t: TestRunner) -> void:
	_begin(t)
	_do_the_sabotage()
	await _she_stands_at(t, _map.power_station_door_position())
	t.check(not _is_dark(), "at the door she has just touched, nothing is off yet")
	await _she_stands_at(t, _south_of_the_station(Blackout.BLACKOUT_DISTANCE - 4.0))
	t.check(not _is_dark() and _went_dark == 0, "nor just short of the distance")
	_end()

func _test_everything_goes_dark_at_once(t: TestRunner) -> void:
	_begin(t)
	t.check(_powered_buildings() == BUILDINGS, "there were lit buildings to put out (%d)"
			% _powered_buildings())

	await _go_dark(t)

	t.check(_is_dark() and _went_dark == 1,
			"past the distance, with the sabotage done, the city goes dark, once (%d)" % _went_dark)
	t.check(_powered_buildings() == 0,
			"every building went out in the same call (%d left)" % _powered_buildings())
	t.check(_events.silenced_all == 1, "and every mast was told to stop with them, once (%d)"
			% _events.silenced_all)
	t.check(_went_quiet == 1, "the city went quiet once (%d)" % _went_quiet)
	_end()

func _test_it_stays_dark_walking_back(t: TestRunner) -> void:
	_begin(t)
	await _go_dark(t)
	await _she_stands_at(t, _map.power_station_door_position())
	t.check(_is_dark() and _powered_buildings() == 0 and _went_dark == 1,
			"walking back to the door does not put the lights on")
	_end()

## A lost day 14 gives the sabotage back at dawn, and with it the power: the retry is the same day.
func _test_a_retry_gives_the_power_back(t: TestRunner) -> void:
	_begin(t)
	await _go_dark(t)
	t.check(_is_dark(), "the power was off before the retry")
	_resistance.give_back()
	await _she_stands_at(t, _south_of_the_station(Blackout.BLACKOUT_DISTANCE * 4.0))
	t.check(not _is_dark(), "with the sabotage given back, the power is back")
	t.check(_powered_buildings() == BUILDINGS, "and the same windows are lit again (%d)"
			% _powered_buildings())
	_end()

## The escape is the same night, so a blackout built for it — its `DaySpec` dark from the start — is
## dark before her first frame, with nobody to watch and no sabotage.
func _test_the_escape_is_dark_from_its_first_frame(t: TestRunner) -> void:
	_begin(t, true)
	t.check(_went_dark == 1, "the escape's city is dark from the moment it is built (%d)" % _went_dark)
	t.check(not _signals.powered and _powered_buildings() == 0, "its lights and windows with it")
	_end()
