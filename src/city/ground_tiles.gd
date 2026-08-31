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
const ROAD_MAIN := 21
const ROAD_MAIN_LINE_E := 22
const ROAD_MAIN_LINE_W := 23
const ROAD_MAIN_LINE_N := 24
const ROAD_MAIN_LINE_S := 25
const SIDEWALK_KERB_MAIN_N := 26
const SIDEWALK_KERB_MAIN_S := 27
const SIDEWALK_KERB_MAIN_E := 28
const SIDEWALK_KERB_MAIN_W := 29
const PRECINCT := 30

## The land the city stops at. *(Playtest 14.)* These five are the **only** sources no
## `GameEnums.TileType` maps to, and that is deliberate: they are painted outside `map.size` by
## `City._paint_outside_the_map` and nothing in the game can stand on them, so giving them tile
## types would put five entries nobody can reach into every `match` that walks the enum — and into
## `Tile.is_walkable`, which is the one place a mistake would be silent and expensive.
##
## See `City._paint_outside_the_map` for which side gets which.
const WATER := 31
const BULKHEAD := 32
const FENCE := 33
const MOUNTAIN := 34
const SCREE := 35
const CROSSING_MAIN_N := 36
const CROSSING_MAIN_S := 37
const CROSSING_MAIN_W := 38
const CROSSING_MAIN_E := 39

## Tileset source id for a cell, or -1 where no ground should be drawn at all.
static func source_for(map: CityMap, tile: Vector2i) -> int:
	match map.tile_at(tile):
		GameEnums.TileType.BUILDING:
			return -1  # A building covers its whole lot; nothing shows through.
		GameEnums.TileType.SIDEWALK:
			return _sidewalk_variant(map, tile)
		GameEnums.TileType.ROAD:
			return _road_variant(map, tile)
		GameEnums.TileType.CROSSING:
			return _crossing_variant(map, tile)
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
##
## Two exceptions, and both are a street kind saying what it is. A **pedestrianised** corridor is
## brick from frontage to frontage: no kerb, because there is nothing on the other side of it to
## step down to. A **main road** keeps its kerb and adds the doubled clearway marking, so a
## pavement says which street it belongs to even when the road itself is off-screen.
static func _sidewalk_variant(map: CityMap, tile: Vector2i) -> int:
	var x := CityMap.corridor_offset(tile.x)
	var y := CityMap.corridor_offset(tile.y)
	var x_kind := map.street_kind_at(true, tile)
	var y_kind := map.street_kind_at(false, tile)
	if (x >= 0 and x_kind == GameEnums.StreetKind.PEDESTRIAN) \
			or (y >= 0 and y_kind == GameEnums.StreetKind.PEDESTRIAN):
		return PRECINCT

	var inner := Tuning.SIDEWALK_WIDTH - 1
	var outer := Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
	var main: bool

	# In a vertical corridor, running alongside a block.
	if x >= 0 and y < 0:
		main = x_kind == GameEnums.StreetKind.MAIN
		if x == inner:
			return SIDEWALK_KERB_MAIN_E if main else SIDEWALK_KERB_E
		if x == outer:
			return SIDEWALK_KERB_MAIN_W if main else SIDEWALK_KERB_W
	# In a horizontal corridor, running alongside a block.
	if y >= 0 and x < 0:
		main = y_kind == GameEnums.StreetKind.MAIN
		if y == inner:
			return SIDEWALK_KERB_MAIN_S if main else SIDEWALK_KERB_S
		if y == outer:
			return SIDEWALK_KERB_MAIN_N if main else SIDEWALK_KERB_N
	return SIDEWALK

## The centre line falls on the seam between the two carriageway tiles, so each of them
## carries half of it. Junctions get plain asphalt: a centre line does not run through one.
##
## A main road is the same geometry in a darker asphalt with an unbroken double line, and the
## carriageway is the half of the difference that has to read from a distance — it is what a
## player sees before she sees the traffic on it.
static func _road_variant(map: CityMap, tile: Vector2i) -> int:
	var x := CityMap.corridor_offset(tile.x)
	var y := CityMap.corridor_offset(tile.y)
	var x_main := map.street_kind_at(true, tile) == GameEnums.StreetKind.MAIN
	var y_main := map.street_kind_at(false, tile) == GameEnums.StreetKind.MAIN
	var first := Tuning.SIDEWALK_WIDTH
	var second := Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH - 1

	if x >= 0 and y < 0:
		if x == first:
			return ROAD_MAIN_LINE_E if x_main else ROAD_LINE_E
		if x == second:
			return ROAD_MAIN_LINE_W if x_main else ROAD_LINE_W
	if y >= 0 and x < 0:
		if y == first:
			return ROAD_MAIN_LINE_S if y_main else ROAD_LINE_S
		if y == second:
			return ROAD_MAIN_LINE_N if y_main else ROAD_LINE_N
	# Inside a junction, or a stretch of main-road carriageway where a side street's zebra would
	# have been. Either way it is the main road's own surface if either corridor is one.
	return ROAD_MAIN if (x_main and x >= 0) or (y_main and y >= 0) else ROAD

## A crossing is where a carriageway passes over the *other* corridor's pavement, so the
## road's axis is whichever of the two offsets is on the carriageway.
##
## **On the main road it is not a zebra**, and that is a rule rather than a decoration.
## *(M51, playtest 15 finding 2: "the main road shouldn't have zebra crossings (since they have
## traffic lights) it should be two dotted lines demarking the pedestrian safe zone".)* A zebra
## means *the traffic gives way to you*, and on the spine it does not — what stops it is the light,
## which is `Tuning.validate_signals`' whole contract. So the paint had been contradicting the rule
## at every junction of the one street where getting it wrong ends the day.
##
## What replaces it is **two dotted lines** and not nothing, which is the distinction M41 already
## drew when it considered painting the crossing away and rejected it: *"a walker crossing a side
## street would then be standing on open carriageway, and the one thing a zebra is for is saying
## where a person on a road is meant to be."* The tile type is unchanged for exactly that reason —
## every rule that reads `CROSSING`, from the traffic's give-way scan to where an event may stand,
## goes on meaning what it meant. Only the picture moved.
##
## The two lines run **along the way she is crossing**, one at each edge of the two-tile band, so
## each tile carries the one on its own outer side. Within a pavement band the tile at the even
## offset is the outer one, which is what `% SIDEWALK_WIDTH` is asking.
static func _crossing_variant(map: CityMap, tile: Vector2i) -> int:
	var across_x := CityMap.is_road_offset(CityMap.corridor_offset(tile.x))
	var main := map.street_kind_at(across_x, tile) == GameEnums.StreetKind.MAIN
	if not main:
		return CROSSING_V if across_x else CROSSING_H
	if across_x:
		# A north-south carriageway: she crosses east to west, so the lines run that way.
		return CROSSING_MAIN_N if CityMap.corridor_offset(tile.y) % Tuning.SIDEWALK_WIDTH == 0 \
				else CROSSING_MAIN_S
	return CROSSING_MAIN_W if CityMap.corridor_offset(tile.x) % Tuning.SIDEWALK_WIDTH == 0 \
			else CROSSING_MAIN_E
