class_name ResistanceHappenings
extends RefCounted
## What the resistance's story puts in the street that is not a task: the neighbor leaving for
## work on the mornings before day 10, and the once-only happenings of days 10 to 13 that are not
## the scheduler's to plan. Owned and ticked by `ResistanceDirector`, which is the one node that
## already knows the day, the city and where she is.
##
## **Deterministic from the run seed and the day**, like every other placement: its own stream
## (`GameState.day_rng(day, "happenings")`), so nothing here moves a draw the director or the
## scheduler makes.

## The day the neighbor is out in the city rather than leaving at dawn, and the day of the raid.
## Named here rather than read off `ResistanceSteps` because the neighbor's mornings are the story
## whether or not this run is ever offered the task.
const NEIGHBOR_DAY := 10

## How far beside her the neighbor comes out of the door, along the street: enough that the two
## figures do not stand in one another on the first frame, not so far that they read as strangers.
const NEIGHBOR_BESIDE_HER := 1.5 * Tuning.TILE_SIZE

var _city: City
var _map: CityMap
var _day := 0
var _rng: RandomNumberGenerator
## The neighbor's morning figure, or null on a day that has none. Kept for the tests.
var morning_neighbor: EventInstance

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map

## Starts the day's happenings: on the mornings before `NEIGHBOR_DAY` the neighbor walks out of
## her building beside her and off along her street.
func start_day(day: int) -> void:
	_day = day
	_rng = GameState.day_rng(day, "happenings")
	morning_neighbor = null
	if day < NEIGHBOR_DAY:
		morning_neighbor = _send_the_neighbor_to_work()

## The neighbor, leaving for work as she does: out of the same door and along the same sidewalk,
## away from her, until the street runs out or something closes it, then off the ordinary way a
## route that ran out leaves (`EventInstance._be_done()`). **Nothing points at them** — no arrow,
## no field, no line of text — so the neighbor is a figure she may notice and never a task.
##
## The way is a coin flip between the two directions along her street, each taken as far as
## `EventScheduler._room_along()` allows and stopped short of a closed tile, the same shape every
## route along a street is given; the longer one when only one fits a block. A figure walking half
## her pace down her own street is out of sight long before the route runs out, whichever way she
## goes, so the departure at its end is one nobody sees.
func _send_the_neighbor_to_work() -> EventInstance:
	if not _city or not _city.events or not _map:
		return null
	var def := EventCatalogue.by_id("neighbor")
	if not def:
		return null
	var door := _map.doorstep_world_position()
	var tile := _map.world_to_tile(door)
	var east := EventScheduler._room_along(_map, tile, Vector2i.RIGHT)
	var west := EventScheduler._room_along(_map, tile, Vector2i.LEFT)
	var along := Vector2i.RIGHT if east >= west else Vector2i.LEFT
	if mini(east, west) >= CityMap.period() and _rng.randf() < 0.5:
		along = -along
	var room := maxi(east, west)
	var length := 0
	for step in range(1, room + 1):
		if _map.is_closed(tile + along * step) or not _map.is_walkable(tile + along * step):
			break
		length = step
	if length < 2:
		return null
	var start := door + Vector2(along) * NEIGHBOR_BESIDE_HER
	var finish := _map.tile_to_world(tile + along * length)
	finish.y = start.y
	var path := PackedVector2Array([start, finish])
	Telemetry.note("contact", "the neighbor leaves for work, %s along her street"
			% ("east" if along.x > 0 else "west"))
	return _city.events.spawn_extra(def, start, path)
