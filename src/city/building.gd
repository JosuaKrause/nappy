class_name Building
extends StaticBody2D
## A 2.5D extruded block, assembled from 32px facade and roof tiles.
##
## The node origin is the SOUTH edge centre of the lot, so y-sorting against the player
## uses the same ground plane the collision does. The lot spans local y in [-depth, 0].
##
## The building's drawn mass fills exactly its lot: the front wall takes the southern
## `height` px and the roof takes what is left. That is what an oblique view of a taller
## building actually looks like — more wall, less roof — and it keeps every extrusion off
## the *ground* the player walks on.
##
## **It does not follow that she is never hidden by one**, and that is the trap in the paragraph
## above. The mass extends a whole block north of the origin y-sort compares, so on its own a
## building draws in front of everything on the pavement beside it wherever the two also overlap in
## x. What is true is the stronger thing, and it is why the answer lives in `city.gd` rather than
## here: nothing can ever legitimately be *behind* a building, so nothing sorts against one.
##
##      lot top ─▶ ┌──────────┐  roof   y = -depth .. -height
##                 ├──────────┤
##                 │          │  wall   y = -height .. 0
##   origin (0,0)  └──────────┘
##
## Both bands are whole tiles. Heights used to be continuous floats, which meant a facade
## tile had to be stretched to fit; snapping to the tile grid is what lets the art be
## authored art. It also makes the old "a roof always shows" clamp exact rather than
## approximate — see `wall_tiles()`.
##
## Fills are authored near-white and multiplied by the variant's colour; edges, plinth and
## windows are overlays drawn at full colour on top. That is why a corner cell needs no
## dedicated corner tile: it simply takes two edge overlays and the parapet turns.

const TILE := float(Tuning.TILE_SIZE)

const WALL := preload("res://assets/buildings/wall.svg")
const WALL_BASE := preload("res://assets/buildings/wall_base.svg")
const WALL_EDGE_W := preload("res://assets/buildings/wall_edge_w.svg")
const WALL_EDGE_E := preload("res://assets/buildings/wall_edge_e.svg")
const ROOF := preload("res://assets/buildings/roof.svg")
const ROOF_EDGE_N := preload("res://assets/buildings/roof_edge_n.svg")
const ROOF_EDGE_S := preload("res://assets/buildings/roof_edge_s.svg")
const ROOF_EDGE_W := preload("res://assets/buildings/roof_edge_w.svg")
const ROOF_EDGE_E := preload("res://assets/buildings/roof_edge_e.svg")
const WINDOW_DARK := preload("res://assets/buildings/window_dark.svg")
const WINDOW_LIT := preload("res://assets/buildings/window_lit.svg")
const ROOF_CAP := preload("res://assets/buildings/roof_cap.svg")
const FACADE_BALCONY := preload("res://assets/buildings/facade_balcony.svg")
const FACADE_AWNING := preload("res://assets/buildings/facade_awning.svg")
const FACADE_SHUTTERS := preload("res://assets/buildings/facade_shutters.svg")
const FACADE_CIVIC := preload("res://assets/buildings/facade_civic.svg")
const FACADE_INDUSTRIAL := preload("res://assets/buildings/facade_industrial.svg")
const FACADE_BOARDED := preload("res://assets/buildings/facade_boarded.svg")

## Share of the wall cells that are lit at all. Fixed at build time, never per frame.
const LIT_WINDOW_CHANCE := 0.28

## Lot size in px: x = width, y = depth (how far north it extends).
@export var footprint := Vector2(96.0, 96.0):
	set(value):
		footprint = value
		_rebuild()

## Requested extruded height in px. Snapped down to whole tiles, and always left at least
## one tile of roof unless the lot is a single tile deep.
@export var height := 64.0:
	set(value):
		height = value
		_rebuild()

## Selects the roof colour and the window pattern.
@export var variant := 0:
	set(value):
		variant = value
		_rebuild()

## Starting district identity, used only for façade dressing. It remains fixed while a block's
## daily condition changes, so a civic building can burn without becoming a generic house.
@export var district := 0:
	set(value):
		district = value
		queue_redraw()

## What has happened to this building's block. The footprint never changes — the street
## lattice and the block boundaries are fixed for the run — so a block that goes dark or
## burns says so here rather than by moving walls around.
enum Condition {
	LIVED_IN, ## Lights on after dark, as generated.
	BOARDED,  ## Nobody home. Every window dark.
	BURNT,    ## Blackened, roofless, windows gone.
}

@export var condition := Condition.LIVED_IN:
	set(value):
		if condition == value:
			return
		condition = value
		queue_redraw()

## The tile rect this building stands on, so the city can find its block again.
var lot := Rect2i()

var _collision: CollisionShape2D
## One entry per wall cell, row-major from the ground up: true where the light is on.
var _windows: Array[bool] = []

func _ready() -> void:
	_collision = CollisionShape2D.new()
	_collision.shape = RectangleShape2D.new()
	add_child(_collision)
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	# Collision is the whole lot, including the strip the roof is drawn over, so the player
	# can never walk into the space the building's mass occupies on screen.
	(_collision.shape as RectangleShape2D).size = footprint
	_collision.position = Vector2(0.0, -footprint.y * 0.5)
	_build_windows()
	queue_redraw()

# ------------------------------------------------------------------- layout ---

## Lot width in whole tiles.
func columns() -> int:
	return maxi(1, roundi(footprint.x / TILE))

## Lot depth in whole tiles.
func rows() -> int:
	return maxi(1, roundi(footprint.y / TILE))

## Rows of front wall. A one-tile sliver is all wall and no roof — anything else would have
## to overhang the lot behind it, and the whole point of the layout is that it never does.
func wall_tiles() -> int:
	return clampi(roundi(height / TILE), 1, maxi(1, rows() - 1))

## Rows of visible roof once the wall has taken its share of the lot.
func roof_tiles() -> int:
	return rows() - wall_tiles()

## Whether a window is showing a light. Only a lived-in block ever does: a boarded street is
## the same street with nobody in it, and that reads at a glance where a colour shift alone
## would not.
func _lit(index: int) -> bool:
	if condition != Condition.LIVED_IN:
		return false
	return _windows[index] if index < _windows.size() else false

## Window lighting is fixed at build time, not rolled per frame, or the city would flicker.
func _build_windows() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	_windows.clear()
	for i in columns() * wall_tiles():
		_windows.append(rng.randf() < LIT_WINDOW_CHANCE)

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	var cols := columns()
	var wall_rows := wall_tiles()
	var roof_rows := roof_tiles()
	var wall_colour := Palette.building_wall(variant)
	var roof_colour := Palette.building_roof(variant)
	if condition == Condition.BURNT:
		wall_colour = Palette.burnt(wall_colour)
		roof_colour = Palette.burnt(roof_colour)

	for row in wall_rows:
		for col in cols:
			var at := _cell(col, row)
			draw_texture(WALL, at, wall_colour)
			var index := row * cols + col
			draw_texture(WINDOW_LIT if _lit(index) else WINDOW_DARK, at)
			if col == 0:
				draw_texture(WALL_EDGE_W, at)
			if col == cols - 1:
				draw_texture(WALL_EDGE_E, at)
			if row == 0:
				draw_texture(WALL_BASE, at)
			_draw_facade_detail(at, col, row, wall_rows)
			if condition == Condition.BOARDED:
				draw_texture(FACADE_BOARDED, at)
			# A one-tile sliver still owns a roof cap. The cap stays inside the lot rather
			# than implying an overhanging second footprint.
			if roof_rows == 0 and row == wall_rows - 1:
				draw_texture(ROOF_CAP, at, roof_colour)
				draw_texture(ROOF_EDGE_N, at)

	for row in roof_rows:
		for col in cols:
			var at := _cell(col, wall_rows + row)
			draw_texture(ROOF, at, roof_colour)
			if row == 0:
				draw_texture(ROOF_EDGE_S, at)
			if row == roof_rows - 1:
				draw_texture(ROOF_EDGE_N, at)
			if col == 0:
				draw_texture(ROOF_EDGE_W, at)
			if col == cols - 1:
				draw_texture(ROOF_EDGE_E, at)

## Top-left corner of a cell, counting rows northward from the ground line.
func _cell(col: int, row: int) -> Vector2:
	return Vector2(-columns() * TILE * 0.5 + col * TILE, -(row + 1) * TILE)

## Draws one restrained architectural accent per building family. The pattern is derived from
## the generated variant and cell position, so a deterministic city keeps its landmarks.
func _draw_facade_detail(at: Vector2, col: int, row: int, wall_rows: int) -> void:
	if condition != Condition.LIVED_IN or wall_rows <= 0:
		return
	var family := posmod(variant, 3)
	var marker := posmod(variant + col * 3 + row * 5, 5)
	if marker != 0 and district != GameEnums.BlockPurpose.CIVIC \
			and district != GameEnums.BlockPurpose.INDUSTRIAL:
		return
	if district == GameEnums.BlockPurpose.CIVIC:
		draw_texture(FACADE_CIVIC, at)
		return
	if district == GameEnums.BlockPurpose.INDUSTRIAL:
		draw_texture(FACADE_INDUSTRIAL, at)
		return
	match family:
		0:
			draw_texture(FACADE_SHUTTERS, at)
		1:
			draw_texture(FACADE_AWNING, at)
		_:
			if row == wall_rows - 1:
				draw_texture(FACADE_BALCONY, at)
