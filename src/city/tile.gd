class_name Tile
extends RefCounted
## Per-tile-type behaviour. The single place that answers "what does this ground do".

static func is_walkable(type: GameEnums.TileType) -> bool:
	return type != GameEnums.TileType.BUILDING

## Parks calm the baby: sleepiness fills faster, excitement fades faster.
static func is_calm(type: GameEnums.TileType) -> bool:
	return type == GameEnums.TileType.PARK or type == GameEnums.TileType.PLAYGROUND

## Alleys apply a constant excitement trickle.
static func is_alley(type: GameEnums.TileType) -> bool:
	return type == GameEnums.TileType.ALLEY

## Road surface, which is what traffic events path along.
static func is_road(type: GameEnums.TileType) -> bool:
	return type == GameEnums.TileType.ROAD or type == GameEnums.TileType.CROSSING

## The flat colour of a surface, for anything that has to represent the ground without
## drawing it — the route map M17 adds. The world itself is painted from the tileset.
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
		_:
			# BUILDING tiles are covered by a Building node; this only shows through bugs.
			return Palette.OUTLINE
