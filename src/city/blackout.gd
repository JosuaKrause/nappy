class_name Blackout
extends Node
## The last night's blackout: the city's power cut, and everything that runs on it off at once.
##
## **Everything, in one frame, once she is far enough away.** *(The player, 2026-09-20: "just wait
## until a certain distance away -- then everything is off at once. the player wouldn't be able to
## see a rolling blackout anyway"; "yes all lights should go out".)* Once the sabotage is done
## (`GameState.sabotage_done`) and she is `Tuning.BLACKOUT_DISTANCE` from the power station, one
## call to `go_dark()` puts out every lit window and the station's own hall (`Building.powered`),
## every traffic light (`TrafficSignals.powered`), and every loudspeaker mast
## (`EventManager.silence_all_masts()`), because the masts have no power of their own. The
## distance is what the story needs as well as what the picture needs: the station is off screen, so
## the moment is the city going dark around her rather than one building, and the minutes it takes
## her to walk that far are the minutes the man on the night shift needs (`docs/NARRATIVE.md`,
## "What the tasks are for").
##
## **Stated over the flag, never over how it was set.** Whatever touch or step sets
## `sabotage_done`, this watches the flag and her distance and nothing else, so it cannot fire
## before the sabotage exists — which is day 14 — and a retry of that day, which gives the flag back
## at dawn (`GameState`), gives the city its power back with it. Once dark it stays dark for as long
## as the flag stands: walking back towards the station does not put the lights on.
##
## **The escape is in the dark too**, since it is the same night: a city built for the escape
## (`GameState.escape_section` set) is dark from its first frame. `--blackout` stands in for the
## flag, for this class alone, so the moment can be photographed on any day.

## True from the frame the city went dark.
var is_dark := false

var _city: City
var _buildings: Array[Building] = []
## The station's lot in world space, which the distance is measured from, or an empty rect on a
## city with no station — where "far enough from it" is true everywhere.
var _station := Rect2()
var _player: Node2D
## `--blackout`, read once rather than off the command line every frame.
var _forced := false

## Called once by `City.build()`, after the buildings, the signals and the events exist. A city
## built for the escape goes dark here, before its first frame is drawn.
func setup(city: City, buildings: Array[Building]) -> void:
	_city = city
	_buildings = buildings
	_forced = DevFlags.blackout_requested()
	if city.map.has_power_station():
		_station = city.map.tile_rect_to_world(CityMap.blocks_tile_rect(city.map.power_station))
	if _in_the_escape():
		go_dark()

func _physics_process(_delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if not _player:
			return
	update(_player.global_position)

## One frame's decision, with her at `at`. Public so a suite can walk her away from the station
## without a tree to step.
func update(at: Vector2) -> void:
	if _in_the_escape():
		if not is_dark:
			go_dark()
		return
	if not _sabotaged():
		if is_dark:
			restore()
		return
	if not is_dark and distance_from_station(at) >= Tuning.BLACKOUT_DISTANCE:
		go_dark()

## How far `at` is from the nearest point of the station's lot, in px — `INF` on a city with none.
func distance_from_station(at: Vector2) -> float:
	if not _station.has_area():
		return INF
	var nearest := Vector2(clampf(at.x, _station.position.x, _station.end.x),
			clampf(at.y, _station.position.y, _station.end.y))
	return nearest.distance_to(at)

## Everything off, in this one call. The masts go through the one mechanism that silences them for
## the rest of the day, which also covers a mast out of reach right now; `EventBus.city_went_quiet`
## says so for whatever listens, when there was a mast to stop.
func go_dark() -> void:
	is_dark = true
	for building in _buildings:
		building.powered = false
	if _city.signals:
		_city.signals.powered = false
	if _city.events and _city.events.silence_all_masts() > 0:
		EventBus.city_went_quiet.emit()

## Power back on — only ever a retried day, whose dawn gave the sabotage back. The masts need
## nothing: a day's masts are that day's own plans, and a retry plans them afresh.
func restore() -> void:
	is_dark = false
	for building in _buildings:
		building.powered = true
	if _city.signals:
		_city.signals.powered = true

func _sabotaged() -> bool:
	return GameState.sabotage_done or _forced

func _in_the_escape() -> bool:
	return GameState.escape_section != FinaleController.Section.NONE
