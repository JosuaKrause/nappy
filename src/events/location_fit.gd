class_name LocationFit
extends RefCounted
## **Whether a row has ground to stand on in a location, and the candidate built there**: the tiles
## of the location it takes (`Location.takes()`) that are the row's own ground for its role on the
## day (`EventScheduler._ground_for()`: off every tile a route runs along for a wall, off a held or
## closed street, the home block, a tree, the side of the sidewalk the row wants), and the
## candidate built on one of them as any placement is (`EventScheduler._build_placement()`: its
## facing and its path). Whether the candidate may stand is the rules' (`StreetInvalidation`). The
## row's own ground is worked out once a row. Model: no node.

var _day := 0
var _map: CityMap
var _ground: Dictionary
var _corridor: Corridor
var _holds_the_home_streets := true
var _own := {}

## The fit on `map` for `day`, routed by `corridor`: `ground` is the day's ground cache, and
## `holds_the_home_streets` whether the home's streets are the day's (`DaySpec`).
func _init(day: int, map: CityMap, ground: Dictionary, corridor: Corridor,
		holds_the_home_streets: bool) -> void:
	_day = day
	_map = map
	_ground = ground
	_corridor = corridor
	_holds_the_home_streets = holds_the_home_streets

## The tiles of `location` `def` may stand on, in the location's own order, row by row.
func tiles(def: EventDef, location: Location) -> Array[Vector2i]:
	var own := _own_ground(def)
	var rect := location.tiles()
	var fits: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if own.has(tile) and location.takes(_map.tile_at(tile)):
				fits.append(tile)
	return fits

## `def`'s candidate built at `tile`, its facing and path drawn on `rng`, or null where none fits.
func build(def: EventDef, tile: Vector2i, rng: RandomNumberGenerator) -> EventScheduler.Planned:
	return EventScheduler._build_placement(def, _map, tile, rng)

func _own_ground(def: EventDef) -> Dictionary:
	if not _own.has(def):
		var found := {}
		for tile in EventScheduler._ground_for(def, _map, _ground, _corridor,
				EventScheduler._role_for(def, _day), EventScheduler.NO_SITE, _holds_the_home_streets):
			found[tile] = true
		_own[def] = found
	return _own[def]
