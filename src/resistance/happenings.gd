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

## How far along her street either van of the raid stands from her door, in tiles: far enough
## apart that the doorstep between them is plainly open, near enough that both are at her building.
const RAID_VAN_OFFSET_TILES := 3
## How far along her street the raid's patrol car paces either way from her door, in tiles.
const RAID_PATROL_REACH_TILES := 7

var _city: City
var _map: CityMap
var _day := 0
var _rng: RandomNumberGenerator
## The neighbor's morning figure, or null on a day that has none. Kept for the tests.
var morning_neighbor: EventInstance
## The raid at her building, once it has arrived: the vans and the patrol. Empty before then and on
## every other day.
var raid: Array[EventInstance] = []
## Where the raid will stand, worked out at dawn so waiting for her to be out of sight costs a
## distance and a screen test a frame: the vans' points, and the patrol's beat.
var _raid_vans := PackedVector2Array()
var _raid_beat := PackedVector2Array()

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map

## Starts the day's happenings: on the mornings before `NEIGHBOR_DAY` the neighbor walks out of
## her building beside her and off along her street.
func start_day(day: int) -> void:
	_day = day
	_rng = GameState.day_rng(day, "happenings")
	morning_neighbor = null
	raid.clear()
	_raid_vans = PackedVector2Array()
	_raid_beat = PackedVector2Array()
	if day < NEIGHBOR_DAY:
		morning_neighbor = _send_the_neighbor_to_work()
	if day == NEIGHBOR_DAY:
		_plan_the_raid()

## Once a frame, from the director: brings in whatever the day is waiting to bring in. `her` is her
## position, `Vector2.INF` with no player; `sight` is the danger edge's own on-screen test, which a
## rig may leave unset.
func tick(her: Vector2, sight: Callable) -> void:
	if not _raid_vans.is_empty() and raid.is_empty():
		_maybe_raid(her, sight)

# ------------------------------------------------------------------ the raid ---

## Where day 10's raid stands at her building: **vans in the street at her building with a patrol,
## and the doorstep stays reachable** (PLAYTEST-122). Two `night_raid` vans on the far sidewalk of
## her own street, `RAID_VAN_OFFSET_TILES` either side of her door, and a patrol car pacing the
## carriageway between them. The far sidewalk rather than hers, because a van body closes the
## sidewalk it stands on (44px against a 64px band), and on her own side two of them would leave the
## door reachable only across the traffic; on the far side her own sidewalk runs past the door
## open both ways, and the vans are across the street from it, facing it.
func _plan_the_raid() -> void:
	if not _map:
		return
	var door := _map.world_to_tile(_map.doorstep_world_position())
	var corridor := door.y - CityMap.corridor_offset(door.y)
	var far_side := corridor + Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
	for side in [-1, 1]:
		var tile := Vector2i(door.x + side * RAID_VAN_OFFSET_TILES, far_side)
		if _map.tile_at(tile) == GameEnums.TileType.SIDEWALK and not _map.is_closed(tile):
			_raid_vans.append(_map.tile_to_world(tile))
	var lane := corridor + Tuning.SIDEWALK_WIDTH
	var from := Vector2i(door.x - RAID_PATROL_REACH_TILES, lane)
	var to := Vector2i(door.x + RAID_PATROL_REACH_TILES, lane)
	if _map.is_walkable(from) and _map.is_walkable(to):
		_raid_beat = PackedVector2Array([_map.tile_to_world(from), _map.tile_to_world(to)])

## **What she comes home to**: the raid arrives once she has left, is `Tuning.OUT_OF_SIGHT` from
## her door and none of it would be on screen — *nothing is seen to appear* — so it is waiting at
## home rather than arriving in front of her. Cold, whatever the run's heat: `night_raid` hunts at
## `Tuning.HEAT_HUNTS_LEVEL`, and a van that ran her down at her own door would make the doorstep
## the one place the day cannot end, which is the opposite of what the raid was decided as.
func _maybe_raid(her: Vector2, sight: Callable) -> void:
	if not _city or not _city.events or her == Vector2.INF:
		return
	var door := _map.doorstep_world_position()
	if her.distance_to(door) < Tuning.OUT_OF_SIGHT:
		return
	var points: Array[Vector2] = []
	points.append_array(Array(_raid_vans))
	points.append_array(Array(_raid_beat))
	if sight.is_valid():
		for point in points:
			if sight.call(point):
				return
	var van := EventCatalogue.by_id("night_raid")
	for at in _raid_vans:
		raid.append(_city.events.spawn_extra(van, at))
	if _raid_beat.size() == 2:
		var patrol: EventDef = EventCatalogue.by_id("police_patrol").duplicate()
		patrol.paces = true
		raid.append(_city.events.spawn_extra(patrol, _raid_beat[0], _raid_beat))
	Telemetry.note("contact", "the raid is at her building: %d vans and a patrol" % _raid_vans.size())

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
