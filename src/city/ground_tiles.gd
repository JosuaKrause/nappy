class_name GroundTiles
extends RefCounted
## Chooses the tile art for every ground cell.
##
## The city used to draw its ground with `draw_rect` and computed lines. That is now
## `assets/ground_tileset.tres`, and this is the single place that decides which tile a cell
## gets — kerbs, centre lines and crossings included, so those are authored art rather than
## geometry recomputed every redraw.
##
## Source ids mirror the order the tileset was built in. Keep them in step.

const ROAD := 0
const ROAD_LINE_E := 1
const ROAD_LINE_W := 2
const ROAD_LINE_N := 3
const ROAD_LINE_S := 4
const CROSSING_V := 5
const CROSSING_H := 6
const SIDEWALK := 7
const SIDEWALK_KERB_N := 8
const SIDEWALK_KERB_S := 9
const SIDEWALK_KERB_E := 10
const SIDEWALK_KERB_W := 11
const GRASS := 12
const SAND := 13
const ALLEY := 14
const PLAZA := 15
const STOOP := 16
const FOREST := 17
const QUIET_SQUARE := 18
const COURTYARD := 19
const SPOILED := 20

## Tileset source id for a cell, or -1 where no ground should be drawn at all.
static func source_for(map: CityMap, tile: Vector2i) -> int:
	match map.tile_at(tile):
		GameEnums.TileType.BUILDING:
			return -1  # A building covers its whole lot; nothing shows through.
		GameEnums.TileType.SIDEWALK:
			return _sidewalk_variant(tile)
		GameEnums.TileType.ROAD:
			return _road_variant(tile)
		GameEnums.TileType.CROSSING:
			return _crossing_variant(tile)
		GameEnums.TileType.PARK:
			return GRASS
		GameEnums.TileType.PLAYGROUND:
			return SAND
		GameEnums.TileType.ALLEY:
			return ALLEY
		GameEnums.TileType.SQUARE:
			return PLAZA
		GameEnums.TileType.HOME:
			return STOOP
		GameEnums.TileType.FOREST:
			return FOREST
		GameEnums.TileType.QUIET_SQUARE:
			return QUIET_SQUARE
		GameEnums.TileType.COURTYARD:
			return COURTYARD
		GameEnums.TileType.SPOILED:
			return SPOILED
		_:
			return -1

## The kerb runs along the pavement's edge against the carriageway — but only alongside a
## block. Through a junction there is no kerb, because that is the mouth of the junction.
static func _sidewalk_variant(tile: Vector2i) -> int:
	var x := CityMap.corridor_offset(tile.x)
	var y := CityMap.corridor_offset(tile.y)
	var inner := Tuning.SIDEWALK_WIDTH - 1
	var outer := Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH

	# In a vertical corridor, running alongside a block.
	if x >= 0 and y < 0:
		if x == inner:
			return SIDEWALK_KERB_E
		if x == outer:
			return SIDEWALK_KERB_W
	# In a horizontal corridor, running alongside a block.
	if y >= 0 and x < 0:
		if y == inner:
			return SIDEWALK_KERB_S
		if y == outer:
			return SIDEWALK_KERB_N
	return SIDEWALK

## The centre line falls on the seam between the two carriageway tiles, so each of them
## carries half of it. Junctions get plain asphalt: a centre line does not run through one.
static func _road_variant(tile: Vector2i) -> int:
	var x := CityMap.corridor_offset(tile.x)
	var y := CityMap.corridor_offset(tile.y)
	var first := Tuning.SIDEWALK_WIDTH
	var second := Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH - 1

	if x >= 0 and y < 0:
		if x == first:
			return ROAD_LINE_E
		if x == second:
			return ROAD_LINE_W
	if y >= 0 and x < 0:
		if y == first:
			return ROAD_LINE_S
		if y == second:
			return ROAD_LINE_N
	return ROAD

## A crossing is where a carriageway passes over the *other* corridor's pavement, so the
## road's axis is whichever of the two offsets is on the carriageway.
static func _crossing_variant(tile: Vector2i) -> int:
	return CROSSING_V if CityMap.is_road_offset(CityMap.corridor_offset(tile.x)) else CROSSING_H
