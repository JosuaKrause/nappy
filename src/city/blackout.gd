class_name Blackout
extends Node
## The last night's blackout: the city's power cut, and everything that runs on it off at once.
##
## **Everything, in one frame, once she is far enough away.** *(The player, 2026-09-20: "just wait
## until a certain distance away -- then everything is off at once. the player wouldn't be able to
## see a rolling blackout anyway"; "yes all lights should go out".)* Once the sabotage is done
## (`ResistanceRunState.sabotage_went_through()`) and she is `BLACKOUT_DISTANCE` from the power station, one
## call to `_go_dark()` puts out every lit window and the station's own hall (`Building.switch_power()`),
## every traffic light (`TrafficSignals.use_power()`), and every loudspeaker mast
## (`EventManager.silence_all_masts()`), because the masts have no power of their own. The
## distance is what the story needs as well as what the picture needs: the station is off screen, so
## the moment is the city going dark around her rather than one building, and the minutes it takes
## her to walk that far are the minutes the man on the night shift needs (`docs/NARRATIVE.md`,
## "What the tasks are for").
##
## **Stated over the flag, never over how it was set.** Whatever touch or step sets
## `sabotage_done`, this watches the flag and her distance and nothing else, so it cannot fire
## before the sabotage exists — which is day 14 — and a retry of that day, which gives the flag
## back at dawn (the run's dawn photograph), gives the city its power back with it. Once dark it
## stays dark for as long as the flag stands: walking back towards the station does not put the
## lights on.
##
## **The escape is in the dark too**, since it is the same night: a city built for the escape
## (`dark_from_the_start`, its `DaySpec`'s) is dark from its first frame. `--blackout` stands in for
## the flag, for this class alone, so the moment can be photographed on any day.

## How far from the power station she has to be, once the sabotage is done, for the city to go dark
## — measured from the nearest point of the station's lot, in px. *(The player, 2026-09-20: "just
## wait until a certain distance away -- then everything is off at once".)* Far enough that no part
## of the station is on screen whichever way she leaves it, so the blackout is something she sees
## happen to the city around her rather than to the building: the view is 640×360 at the camera's
## zoom and leads her by `Stroller.CAMERA_LOOK_AHEAD` (46px), and the stacks rise four tiles past
## the lot's north edge, so leaving past a corner needs the diagonal of (320 + 46) by
## (180 + 46 + 128), which is 509px. Chosen where the design was silent, open to overturn.
const BLACKOUT_DISTANCE := 512.0

## True from the frame the city went dark.
var _is_dark := false

## What it switches and watches, handed in by `setup()`: the signals, the events whose masts it
## silences and the resistance's progress whose `sabotage_done` it watches.
var _signals: TrafficSignals
var _events: EventManager
var _resistance: ResistanceRunState
var _buildings: Array[Building] = []
## The station's lot in world space, which the distance is measured from, or an empty rect on a
## city with no station — where "far enough from it" is true everywhere.
var _station := Rect2()
## Her, whose distance from the station is watched: handed in once the world is live and she walks
## it (`use_player()`); none before, and nothing is decided without her.
var _player: Node2D
## `--blackout`, handed to `setup()`: the city counts as sabotaged.
var _forced := false
## Handed to `setup()`: the city is dark from its first frame and stays dark, whatever the sabotage
## and wherever she is — the escape's.
var _dark_from_the_start := false
## The signals the blackout reports on (`EventBus`'s script), so the bus it is handed has a class.
const _BUS := preload("res://src/autoload/event_bus.gd")
## The bus it says the city went dark and went quiet on, handed in before `setup()` (`use_bus()`);
## none, and it tells nobody.
var _bus: _BUS

## Hands the blackout the bus it reports on. Before `setup()`, which may already go dark.
func use_bus(bus: _BUS) -> void:
	_bus = bus

## Hands the blackout her, from the moment the world is live and she walks it
## (`WorldSimulation.meet_her()`).
func use_player(player: Node2D) -> void:
	_player = player

## Called once by whoever stands the city's simulation (`SimulationBuilder`), after the buildings,
## the signals and the events exist. `forced` is `--blackout`; a city `dark_from_the_start`, the
## escape's, goes dark here, before its first frame is drawn.
func setup(map: CityMap, buildings: Array[Building], signals: TrafficSignals,
		events: EventManager, resistance: ResistanceRunState, forced: bool,
		dark_from_the_start: bool) -> void:
	_buildings = buildings
	_signals = signals
	_events = events
	_resistance = resistance
	_forced = forced
	_dark_from_the_start = dark_from_the_start
	if map.has_power_station():
		_station = map.tile_rect_to_world(CityMap.blocks_tile_rect(map.power_station_blocks()))
	if _dark_from_the_start:
		_go_dark()

func _physics_process(_delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return
	_update(_player.global_position)

## One frame's decision, with her at `at`.
func _update(at: Vector2) -> void:
	if _dark_from_the_start:
		if not _is_dark:
			_go_dark()
		return
	if not _sabotaged():
		if _is_dark:
			restore()
		return
	if not _is_dark and _distance_from_station(at) >= BLACKOUT_DISTANCE:
		_go_dark()

## How far `at` is from the nearest point of the station's lot, in px — `INF` on a city with none.
func _distance_from_station(at: Vector2) -> float:
	if not _station.has_area():
		return INF
	var nearest := Vector2(clampf(at.x, _station.position.x, _station.end.x),
			clampf(at.y, _station.position.y, _station.end.y))
	return nearest.distance_to(at)

## Everything off, in this one call. The masts go through the one mechanism that silences them for
## the rest of the day, which also covers a mast out of reach right now; `EventBus.city_went_quiet`
## says so for whatever listens, when there was a mast to stop.
func _go_dark() -> void:
	_is_dark = true
	# `VisitCounter`'s own "blackout" — every go-dark, unlike `city_went_quiet` below, which only
	# fires when there was a mast to silence. See docs/TELEMETRY.md, "The page counts visits".
	if _bus:
		_bus.city_gone_dark.emit()
	for building in _buildings:
		building.switch_power(false)
	_signals.use_power(false)
	if _events.silence_all_masts() > 0 and _bus:
		_bus.city_went_quiet.emit()

## Power back on — only ever a retried day, whose dawn gave the sabotage back. The masts need
## nothing: a day's masts are that day's own plans, and a retry plans them afresh.
func restore() -> void:
	_is_dark = false
	for building in _buildings:
		building.switch_power(true)
	_signals.use_power(true)

func _sabotaged() -> bool:
	return _resistance.sabotage_went_through() or _forced
