class_name Litter
extends RefCounted
## Loose litter: small ground decals from `Tuning.degradation_for(day)` and a seeded roll, one per
## qualifying tile at most. A pure function of `CityMap` and the day, the same shape `StreetTrees`
## is of the map alone — nothing here reaches into `City` or a scene, and `CityDecals` draws
## exactly what this returns.
##
## **Eligible ground is pavements, alleys and squares, never the road's own lanes and never a calm
## area** — `SIDEWALK`, `ALLEY` and `SQUARE` are also every walkable tile type that is neither of
## those two, so the exclusion the milestone asked for falls out of the eligible set rather than
## needing its own check. `Tile.is_calm()`'s five types (`PARK`, `PLAYGROUND`, `FOREST`,
## `QUIET_SQUARE`, `COURTYARD`) are none of them, and `ROAD`/`CROSSING` are not either.

const _ELIGIBLE: Array[GameEnums.TileType] = [
	GameEnums.TileType.SIDEWALK, GameEnums.TileType.ALLEY, GameEnums.TileType.SQUARE,
]

const APPLE := preload("res://assets/props/litter_apple.svg")
const NEWSPAPER := preload("res://assets/props/litter_newspaper.svg")
const CUP := preload("res://assets/props/litter_cup.svg")
const BAG := preload("res://assets/props/litter_bag.svg")
const CAN := preload("res://assets/props/litter_can.svg")
const TEXTURES: Array[Texture2D] = [APPLE, NEWSPAPER, CUP, BAG, CAN]

## Share of an eligible tile that carries a decal at the curve's maximum (day 14). Kept low: this
## is rubbish scattered across a city, not a tip on every flagstone.
const DENSITY_SHARE := 0.05

## How far a decal may drift off its tile's own centre, in px — enough to read as dropped rather
## than planted on a grid, well inside the tile so it never crosses into a neighbour's.
const JITTER := 8.0

## One placed decal: where, and which of `TEXTURES`.
class Placed extends RefCounted:
	var position: Vector2
	var texture_index: int

## Every litter decal the city places today.
static func placed(map: CityMap, day: int) -> Array[Placed]:
	var found: Array[Placed] = []
	var density := Tuning.degradation_for(day) * DENSITY_SHARE
	if density <= 0.0:
		return found
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if not _ELIGIBLE.has(map.tile_at(tile)):
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("litter:%d:%d:%d" % [map.seed_used, x, y])
			if rng.randf() >= density:
				continue
			var entry := Placed.new()
			entry.texture_index = rng.randi_range(0, TEXTURES.size() - 1)
			var jitter := Vector2(rng.randf_range(-JITTER, JITTER), rng.randf_range(-JITTER, JITTER))
			entry.position = map.tile_to_world(tile) + jitter
			found.append(entry)
	return found
