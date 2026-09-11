class_name GarbageSacks
extends RefCounted
## Where garbage sacks stand: alleys from `Tuning.DEGRADATION_FIRST_DAY`, building fronts a day or
## two later (`FRONT_DAY`) — alleys first, fronts as the city degrades further. A pure function of
## `CityMap` and the day, the same shape `StreetTrees` is of the map alone — nothing here reaches
## into `City` or a scene.
##
## **A single sack is decoration with a `GroundShape` and no body; a pile carries neither
## either.** Whether a pile that narrows an alley should carry one is a route decision the
## milestone leaves for when a pile is actually seen standing in an alley she has to use, not
## before it exists at all — so this version places piles exactly like single sacks: seen,
## stepped around visually, walked straight through physically.

## Building fronts start a couple of days after alleys do — the same "day or two" gap the player's
## own words asked for, read off the one curve rather than a second one.
const FRONT_DAY := Tuning.DEGRADATION_FIRST_DAY + 2

## Share of an eligible tile that carries a sack at the curve's maximum (day 14). Higher than
## `Litter.DENSITY_SHARE`: a sack is a deliberate dumping point, not something dropped in passing.
const DENSITY_SHARE := 0.22
## Share of a placed sack that is the heaped pile rather than the single sack, at the curve's
## maximum — worse decay reads as sacks accumulating into heaps, not just more single sacks.
const PILE_SHARE := 0.35

## How far a front sack sits off its tile's own centre, in px, nudged toward the building it
## stands against — `CityMap.pavement_inward()`'s own direction — so it reads as leant on the
## wall rather than floating in the middle of the pavement. An alley sack stays centred: an alley
## is `ALLEY_WIDTH_TILES` (2) tiles wide with no single kerb side to hug.
const FRONT_NUDGE := 8.0

## One placed sack: where, and whether it is the heaped pile.
class Placed extends RefCounted:
	var position: Vector2
	var pile: bool

## Every garbage sack the city places today.
static func placed(map: CityMap, day: int) -> Array[Placed]:
	var found: Array[Placed] = []
	var density := Tuning.degradation_for(day)
	if density <= 0.0:
		return found
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			var entry := _candidate(map, tile, day, density)
			if entry:
				found.append(entry)
	return found

## Alley tiles carrying a pile today, for `EventScheduler`'s own preference: the mouse in the
## alley (`EventCatalogue._alley_mouse()`) would rather stand beside one once both exist.
static func alley_pile_tiles(map: CityMap, day: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var density := Tuning.degradation_for(day)
	if density <= 0.0:
		return tiles
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.ALLEY:
				continue
			var entry := _candidate(map, tile, day, density)
			if entry and entry.pile:
				tiles.append(tile)
	return tiles

static func _candidate(map: CityMap, tile: Vector2i, day: int, density: float) -> Placed:
	var type := map.tile_at(tile)
	var alley := type == GameEnums.TileType.ALLEY
	var inward := map.pavement_inward(tile) if type == GameEnums.TileType.SIDEWALK else Vector2i.ZERO
	var front := day >= FRONT_DAY and inward != Vector2i.ZERO \
			and map.tile_at(tile + inward) == GameEnums.TileType.BUILDING
	if not alley and not front:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sack:%d:%d:%d" % [map.seed_used, tile.x, tile.y])
	var severity := rng.randf()
	if severity >= density * DENSITY_SHARE:
		return null
	var entry := Placed.new()
	entry.pile = rng.randf() < density * PILE_SHARE
	entry.position = map.tile_to_world(tile)
	if front:
		entry.position += Vector2(inward) * FRONT_NUDGE
	return entry
