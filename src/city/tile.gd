class_name Tile
extends RefCounted
## Per-tile-type behaviour. The single place that answers "what does this ground do".

static func is_walkable(type: GameEnums.TileType) -> bool:
	return type != GameEnums.TileType.BUILDING

## Calm ground: sleepiness fills faster, excitement fades faster. It is the only ground a day can
## be won on, so what is on this list is the whole difficulty curve.
##
## `SQUARE` is deliberately absent and `QUIET_SQUARE` deliberately present: a market plaza
## and an empty one are the same paving and not the same place. `SPOILED` is what calm
## ground becomes when it is taken or burnt — the same ground, no longer calm.
const _CALM: Array[GameEnums.TileType] = [
	GameEnums.TileType.PARK,
	GameEnums.TileType.PLAYGROUND,
	GameEnums.TileType.FOREST,
	GameEnums.TileType.QUIET_SQUARE,
	GameEnums.TileType.COURTYARD,
]

static func is_calm(type: GameEnums.TileType) -> bool:
	return _CALM.has(type)

## Alleys apply a constant excitement trickle.
static func is_alley(type: GameEnums.TileType) -> bool:
	return type == GameEnums.TileType.ALLEY

## Road surface, which is what traffic events path along.
static func is_road(type: GameEnums.TileType) -> bool:
	return type == GameEnums.TileType.ROAD or type == GameEnums.TileType.CROSSING

## The flat colour of a surface, for anything that has to represent the ground without
## drawing it — `TelemetryMap`, which is a tile to a pixel. The world itself is painted from the
## tileset.
static func ground_colour(type: GameEnums.TileType) -> Color:
	match type:
		GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING:
			return Palette.ASPHALT
		GameEnums.TileType.SIDEWALK:
			return Palette.SIDEWALK
		GameEnums.TileType.PARK:
			return Palette.GRASS
		GameEnums.TileType.PLAYGROUND:
			return Palette.SAND
		GameEnums.TileType.SQUARE:
			return Palette.SQUARE_STONE
		GameEnums.TileType.ALLEY:
			return Palette.ALLEY_FLOOR
		GameEnums.TileType.HOME:
			return Palette.HOME_STOOP
		GameEnums.TileType.FOREST:
			return Palette.FOREST_FLOOR
		GameEnums.TileType.QUIET_SQUARE:
			return Palette.QUIET_STONE
		GameEnums.TileType.COURTYARD:
			return Palette.COURTYARD_STONE
		GameEnums.TileType.SPOILED:
			return Palette.SPOILED_GROUND
		_:
			# BUILDING tiles are covered by a Building node; this only shows through bugs.
			return Palette.OUTLINE
