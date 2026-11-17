class_name SitedGround
extends RefCounted
## **The tiles a row her walk lays may stand on**: the walk's ground for the row (`RowGround`),
## narrowed for the two rows a location's draw places otherwise. A crew her walk lays stands in
## front of a blank wall it can paste, in the lane of a south-facing front, where a unit lays one by
## its own side; a mast stands only where a mast site may be (`MastSites.is_eligible()`). Handed the
## map, the walk's ground and the fronts a crew may paste (`PosterWalls.fronts()`; empty for a walk
## with no city), so a test hands it stand-ins.
##
## **The precinct weighting is dropped here and that is correct rather than a shortcut.** The
## weighting offers a retail tile several times so the day's own draw lands there more often; her
## walk asks only which tiles are the row's, and which street she is walking has decided everything
## the weight was for.

var _map: CityMap
var _ground: RowGround
var _fronts: Dictionary
## A row -> the set of tiles it may stand on, asked of the ground once a row.
var _tiles := {}
## Tile -> whether a mast may stand there, each tile asked of `MastSites` once.
var _mast_may_stand := {}
## Where a region door could ever stand, for `_a_mast_may_stand()`; empty until first asked.
var _door_points := PackedVector2Array()

func _init(map: CityMap, ground: RowGround, fronts: Dictionary) -> void:
	_map = map
	_ground = ground
	_fronts = fronts

## **The row's ground as a set** (`tile -> a count`, read for its keys): for a row that stands at a
## front, the tiles of its `AT_THE_FRONT` lane, with every rule the day's ground asks of any other
## row, that are fronts, and nothing at all where no city handed any over; for any other row what
## the ground offers (`RowGround.offers_for()`). Worked out once a row.
func tiles_of(def: EventDef) -> Dictionary:
	if not _tiles.has(def):
		if def.stands_at_a_front():
			var found := {}
			for tile: Vector2i in _ground.offers_for(def, EventDef.Pavement.AT_THE_FRONT):
				if _fronts.has(tile):
					found[tile] = true
			_tiles[def] = found
		else:
			_tiles[def] = _ground.offers_for(def)
	var kept: Dictionary = _tiles[def]
	return kept

## **Whether `def` may stand on `tile`**: in `tiles_of(def)` and, for a mast, a tile a mast site
## may be (`MastSites.is_eligible()`: off the home street, its field off a calm interior and off
## every place a region door could stand), the refusal day 11's mast near the mark is under, so a
## mast is never on the home street whichever way it is put down. Asked only of a tile a caller
## brings, never of the whole ground: over every sidewalk and square in the city it is seconds of
## work on the frame she reads day 11's mark. Each tile's answer is kept, and the door points it
## measures against are worked out once (`MastSites.possible_door_points()`).
func takes(def: EventDef, tile: Vector2i) -> bool:
	if not tiles_of(def).has(tile):
		return false
	return not def.is_a_mast() or _a_mast_may_stand(tile)

## Whether `def` is a wall by what it costs to walk through, as the walk's ground reads it
## (`RowGround.is_a_wall_by_cost()`): a row that is a wall by its fit alone is laid on her street.
func is_a_wall_by_cost(def: EventDef) -> bool:
	return _ground.is_a_wall_by_cost(def)

## Does at a day's start the scan the first ask for `def` would do mid-walk: the scan for ground
## `def` may stand on and the set a tile asks about. It is a scan of the whole city, which at dawn
## is part of a load and mid-walk is a hitch on the one beat of the day she is meant to be watching.
## Nothing here rolls, so the day is the same day whether or not this ran.
func prepare(def: EventDef) -> void:
	tiles_of(def)

func _a_mast_may_stand(tile: Vector2i) -> bool:
	if not _mast_may_stand.has(tile):
		if _door_points.is_empty():
			_door_points = MastSites.possible_door_points(_map)
		_mast_may_stand[tile] = MastSites.is_eligible(_map.tile_to_world(tile), _map, _door_points)
	return _mast_may_stand[tile]
