extends RefCounted
## What a `Building`'s front shows, read off the pictures it was drawn with.
##
## A building paints its front through a `FrontDrawer` (`Building.front_drawer`), and
## `RecordingFrontDrawer` records every picture it is told to paint instead of painting it. This reads
## the record by where each picture was put, in the building's own space: a wall cell's top-left
## corner is `(-columns() * TILE / 2 + col * TILE, -(row + 1) * TILE)`, rows counted north from the
## ground line, and a picture stood on its foot (a door, a balcony, the portico) is put at the middle
## of its bottom edge. That layout is the front's drawn geometry, so a suite asking where a window or
## a door shows asks the picture and not a member of the building that decided it.
##
## Build one with `FrontReads.new_building()`, add it to the tree, let two frames pass (`UI.frames()`),
## then `look()` at it.

const RecordingFrontDrawer := preload("res://tests/recording_front_drawer.gd")

const TILE := Building.TILE

## The building and the drawer it was handed.
var building: Building
var drawer: RecordingFrontDrawer

## What the front shows now, on its own canvas: the entries of `RecordingFrontDrawer.shown()`.
var _shown: Array[Dictionary] = []

## A building handed a recording drawer, not yet in the tree.
static func new_building() -> Building:
	var made := Building.new()
	made.front_drawer = RecordingFrontDrawer.new()
	return made

## Hands a building a recording drawer in place of the real one a city gave it, has its scenery
## resident (a building draws nothing while it is not), and asks for a redraw.
static func watch(building: Building) -> void:
	building.front_drawer = RecordingFrontDrawer.new()
	building.set_scenery_resident(true)
	building.queue_redraw()

## The reads of `building`'s front as it was last drawn.
static func look(building: Building):
	var reads = load("res://tests/front_reads.gd").new()
	reads.building = building
	reads.drawer = building.front_drawer as RecordingFrontDrawer
	reads.refresh()
	return reads

## Reads the drawer's record again, after the building has been drawn once more.
func refresh() -> void:
	_shown.clear()
	for entry in drawer.shown():
		if entry.canvas == building:
			_shown.append(entry)

## The window pictures a front can show.
static func window_pictures() -> Array[StringName]:
	return [Building.WINDOW_DARK, Building.WINDOW_LIT, Building.WINDOW_TALL_DARK,
			Building.WINDOW_TALL_LIT, Building.WINDOW_SHUTTERED_DARK, Building.WINDOW_SHUTTERED_LIT,
			Building.WINDOW_BURNT]

## The pictures a ground floor shows in a column: the plinth or a shop.
static func ground_pictures() -> Array[StringName]:
	var found: Array[StringName] = [Building.WALL_BASE, Building.STOREFRONT_BURNT]
	found.append_array(Building.STOREFRONT_TEXTURES)
	found.append_array(Building.STOREFRONT_AWNING_TEXTURES)
	found.append_array(Building.STOREFRONT_SHUTTERED_TEXTURES)
	return found

## The pictures an escape's balconies are drawn with.
static func escape_pictures() -> Array[StringName]:
	return [Building.FIRE_ESCAPE_A, Building.FIRE_ESCAPE_B, Building.FIRE_ESCAPE_PLATFORM_A,
			Building.FIRE_ESCAPE_PLATFORM_B]

## The pictures an entrance door is drawn with.
static func door_pictures() -> Array[StringName]:
	return [Building.ENTRANCE_DOOR, Building.ENTRANCE_DOOR_INDUSTRIAL, Building.ENTRANCE_DOOR_BURNT]

## The local x of the left edge of column 0.
func left_edge() -> float:
	return -building.columns() * TILE * 0.5

## The column a picture painted with its top-left corner at x `at_x` starts in.
func column_of_corner(at_x: float) -> int:
	return roundi((at_x - left_edge()) / TILE)

## The column a picture stood with the middle of its bottom edge at x `foot_x` stands in.
func column_of_foot(foot_x: float) -> int:
	return floori((foot_x - left_edge()) / TILE)

## The row a cell painted with its top-left corner at y `at_y` is in, counted north from the ground
## line. The upper windows are lifted two pixels over a door or a shop, which this absorbs.
static func row_of_corner(at_y: float) -> int:
	return roundi(-at_y / TILE) - 1

## Every picture painted (not stood) on the front, as `{"picture", "col", "row", "at", "colour"}`.
func painted() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry in _shown:
		if not entry.standing:
			found.append({"picture": entry.picture, "col": column_of_corner(entry.at.x),
					"row": row_of_corner(entry.at.y), "at": entry.at, "colour": entry.colour})
	return found

## Every picture stood on its foot on the front, as `{"picture", "col", "foot"}`.
func stood() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry in _shown:
		if entry.standing:
			found.append({"picture": entry.picture, "col": column_of_foot(entry.at.x),
					"foot": entry.at})
	return found

## How many pictures the front shows.
func picture_count() -> int:
	return _shown.size()

## The window picture drawn in wall cell (`col`, `row`), or `&""` where none is.
func window_at(col: int, row: int) -> StringName:
	for entry in painted():
		if entry.col == col and entry.row == row and window_pictures().has(entry.picture):
			return entry.picture
	return &""

## Every wall cell a window is drawn in, as `Vector2i(col, row)`.
func window_cells() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for entry in painted():
		if window_pictures().has(entry.picture):
			found.append(Vector2i(entry.col, entry.row))
	return found

## How many wall cells show a lit window.
func lit_windows() -> int:
	var lit := [Building.WINDOW_LIT, Building.WINDOW_SHUTTERED_LIT, Building.WINDOW_TALL_LIT]
	var count := 0
	for entry in painted():
		if lit.has(entry.picture):
			count += 1
	return count

## The window picture of every wall cell the front draws one in, row by row and column by column
## within a row: the style and which cells are lit, in one list.
func window_pictures_in_order() -> Array[StringName]:
	var found: Array[StringName] = []
	for row in building.wall_tiles():
		for col in building.columns():
			var picture := window_at(col, row)
			if picture != &"":
				found.append(picture)
	return found

## The picture the ground floor shows in column `col` (the plinth, or the shop whose pair starts
## there), or `&""` where it shows none: the second column of a pair, or one nothing is drawn in.
func ground_floor_at(col: int) -> StringName:
	for entry in painted():
		if entry.col == col and ground_pictures().has(entry.picture):
			return entry.picture
	return &""

## The column the entrance door is drawn in, or -1 when the front draws none.
func door_col() -> int:
	for entry in stood():
		if door_pictures().has(entry.picture):
			return entry.col
	return -1

## The entrance door's picture, or `&""` when the front draws none.
func door_picture() -> StringName:
	for entry in stood():
		if door_pictures().has(entry.picture):
			return entry.picture
	return &""

## Every balcony drawn, as `{col: {row: picture}}`: `row` is the floor line the balcony stands on.
## A balcony stood on the foot `-(row - 1) * TILE` is the one on floor line `row`.
func balconies() -> Dictionary:
	var found := {}
	for entry in stood():
		if not escape_pictures().has(entry.picture):
			continue
		var row := roundi(1.0 - entry.foot.y / TILE)
		if not found.has(entry.col):
			found[entry.col] = {}
		found[entry.col][row] = entry.picture
	return found

## The columns a fire escape is drawn in, ascending.
func escape_cols() -> Array[int]:
	var cols: Array[int] = []
	for col: int in balconies():
		cols.append(col)
	cols.sort()
	return cols

## How many balconies the front draws.
func balcony_count() -> int:
	var count := 0
	for col: int in balconies():
		count += (balconies()[col] as Dictionary).size()
	return count

## Whether the civic portico is drawn.
func portico_drawn() -> bool:
	for entry in stood():
		if entry.picture == Building.CIVIC_PORTICO:
			return true
	return false

## The columns the portico covers: those its 32px picture, stood at its foot, overlaps.
func portico_cols() -> Array[int]:
	var cols: Array[int] = []
	for entry in stood():
		if entry.picture != Building.CIVIC_PORTICO:
			continue
		for col in building.columns():
			var x := left_edge() + col * TILE
			if x < entry.foot.x + TILE * 0.5 and x + TILE > entry.foot.x - TILE * 0.5:
				cols.append(col)
	return cols

## Whether anything of the facade is drawn in column `col`: a wall cell, a window, a shop, a door or
## a balcony, below the roof. A covered column draws none.
func facade_drawn_in(col: int) -> bool:
	for entry in painted():
		if entry.col == col and entry.row < building.wall_tiles() and entry.picture != Building.ROOF:
			return true
	for entry in stood():
		if entry.col == col:
			return true
	return false

## The roof rows drawn over column `col`, counted north from the front lip: how many `ROOF` cells
## stand in it.
func roof_rows_at(col: int) -> int:
	var rows := 0
	for entry in painted():
		if entry.picture == Building.ROOF and entry.col == col:
			rows += 1
	return rows

## The lips drawn on roof cell (`col`, `row`), as `Building.ROOF_EDGE_BIT_*` flags, or 0 for a cell
## that is no roof or has none. Row 0 is the front lip, directly above the wall.
func roof_edges_at(col: int, row: int) -> int:
	var wall_row := building.wall_tiles() + row
	var roof_here := false
	var edges := 0
	for entry in painted():
		if entry.col != col or entry.row != wall_row:
			continue
		match entry.picture:
			Building.ROOF:
				roof_here = true
			Building.ROOF_EDGE_N:
				edges |= Building.ROOF_EDGE_BIT_N
			Building.ROOF_EDGE_W:
				edges |= Building.ROOF_EDGE_BIT_W
			Building.ROOF_EDGE_E:
				edges |= Building.ROOF_EDGE_BIT_E
			_:
				if entry.picture == Building.ROOF_EDGE_S \
						or Building.ROOF_EDGE_S_BURNT.has(entry.picture):
					edges |= Building.ROOF_EDGE_BIT_S
	return edges if roof_here else 0

## Whether roof cell (`col`, `row`) is drawn at all.
func roof_cell_drawn(col: int, row: int) -> bool:
	var wall_row := building.wall_tiles() + row
	for entry in painted():
		if entry.picture == Building.ROOF and entry.col == col and entry.row == wall_row:
			return true
	return false
