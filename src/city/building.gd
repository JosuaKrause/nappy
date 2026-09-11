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

## Share of the wall cells that are lit at all. Fixed at build time, never per frame.
const LIT_WINDOW_CHANCE := 0.28

# ------------------------------------------------------------- roof furniture ---
# One roof unit per interior cell: never on the perimeter row or column, so nothing overhangs
# the silhouette the parapet and edge tiles already draw. Drawn by this node, above its own roof
# tiles and inside the Buildings layer, so a roof unit never enters the y-sorted comparison the
# class doc's own warning is about.

const VENT_A := preload("res://assets/props/industrial_vent.svg")
const VENT_B := preload("res://assets/props/industrial_vent_b.svg")
const HVAC_A := preload("res://assets/props/roof_hvac_unit.svg")
const HVAC_B := preload("res://assets/props/roof_hvac_unit_b.svg")
const DUCT_STRAIGHT := preload("res://assets/props/roof_duct_straight.svg")
const DUCT_CORNER := preload("res://assets/props/roof_duct_corner.svg")
const SKYLIGHT_A := preload("res://assets/props/roof_skylight.svg")
const SKYLIGHT_B := preload("res://assets/props/roof_skylight_b.svg")
const VENT_STACK := preload("res://assets/props/roof_vent_stack.svg")
const WATER_TANK := preload("res://assets/props/roof_water_tank.svg")

## What stands on a roof. `VENT` is the one that animates; everything else is fixed art.
enum _Furniture { VENT, HVAC_A, HVAC_B, DUCT_STRAIGHT, DUCT_CORNER, SKYLIGHT_A, SKYLIGHT_B,
	VENT_STACK, WATER_TANK }

## Which units a district's roof may roll. `INDUSTRIAL` also gets a duct run — see
## `_place_duct_run()` — on top of whatever this list places. Repeating `WATER_TANK` three times
## against one `VENT` is "the odd vent" the milestone asked for: mostly tanks, occasionally a fan.
const _INDUSTRIAL_KINDS: Array = [_Furniture.HVAC_A, _Furniture.HVAC_B, _Furniture.VENT,
	_Furniture.VENT_STACK]
const _CIVIC_KINDS: Array = [_Furniture.SKYLIGHT_A, _Furniture.SKYLIGHT_B]
const _RESIDENTIAL_KINDS: Array = [_Furniture.WATER_TANK, _Furniture.WATER_TANK,
	_Furniture.WATER_TANK, _Furniture.VENT]
const _KINDS_BY_DISTRICT := {
	GameEnums.BlockPurpose.INDUSTRIAL: _INDUSTRIAL_KINDS,
	GameEnums.BlockPurpose.CIVIC: _CIVIC_KINDS,
	GameEnums.BlockPurpose.RESIDENTIAL: _RESIDENTIAL_KINDS,
	GameEnums.BlockPurpose.COMMERCIAL: _RESIDENTIAL_KINDS,
}

## Share of a district's interior cells that carry a unit at all — the count the milestone asked
## to scale with the footprint, stated as a density rather than a fixed number so a wide roof
## carries more of them than a narrow one without a second table to keep in step with the first.
const _FURNITURE_DENSITY := {
	GameEnums.BlockPurpose.INDUSTRIAL: 0.4,
	GameEnums.BlockPurpose.CIVIC: 0.22,
	GameEnums.BlockPurpose.RESIDENTIAL: 0.15,
	GameEnums.BlockPurpose.COMMERCIAL: 0.15,
}

## How often the vent's rotor swaps frames, in seconds. Purely cosmetic — nothing a route
## decision is stated over — so it lives beside the art it times rather than in `Tuning`.
const VENT_FRAME_INTERVAL := 1.4

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

## The block's own starting purpose — fixed for the run, the same fact `City._height_for` already
## reads — and what picks the roof furniture's district table. Never today's purpose: a requisitioned
## park does not change what is bolted to a roof.
@export var district := GameEnums.BlockPurpose.RESIDENTIAL:
	set(value):
		district = value
		_rebuild()

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

## This building's own ground shape — a rectangle of half `footprint`, the one place `GroundShape`
## is a rectangle rather than a point or a band: nothing else in the game has a footprint that
## is not already one of those two. Kept in step with `footprint` in `_rebuild()`, since the
## `@export` setter can still reassign it. Buildings draw no shadow, so this is read for its body
## alone today.
var shape: GroundShape

var _collision: CollisionShape2D
## One entry per wall cell, row-major from the ground up: true where the light is on.
var _windows: Array[bool] = []
## One entry per roof unit: `{"cell": Vector2i, "kind": _Furniture, "span": int}`. Sorted
## north-most (highest row) first at build time, so `_draw_roof_furniture` can paint far units
## before near ones without re-sorting every frame — the same back-to-front order a unit taller
## than one tile (the water tank) needs to lie correctly over whatever is in the row behind it.
var _roof_furniture: Array[Dictionary] = []
## Whether any roof unit this building rolled is the animated vent, so `_process` only runs — and
## `queue_redraw()` only fires on a timer — for the buildings that have something moving on them.
var _has_vent := false
var _vent_frame_b := false
var _vent_timer := 0.0

func _ready() -> void:
	_collision = CollisionShape2D.new()
	add_child(_collision)
	_rebuild()

func _process(delta: float) -> void:
	_vent_timer += delta
	if _vent_timer < VENT_FRAME_INTERVAL:
		return
	_vent_timer = 0.0
	_vent_frame_b = not _vent_frame_b
	queue_redraw()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	# Collision is the whole lot, including the strip the roof is drawn over, so the player
	# can never walk into the space the building's mass occupies on screen. Built from `shape`
	# rather than a `RectangleShape2D` sized separately, so the body and the shape cannot disagree.
	shape = GroundShape.rect(footprint * 0.5)
	_collision.shape = shape.collision_shape()
	_collision.position = Vector2(0.0, -footprint.y * 0.5)
	_build_windows()
	_build_roof_furniture()
	set_process(_has_vent)
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
			draw_texture(TextureResolver.resolve(WALL), at, wall_colour)
			var index := row * cols + col
			draw_texture(TextureResolver.resolve(WINDOW_LIT if _lit(index) else WINDOW_DARK), at)
			if col == 0:
				draw_texture(TextureResolver.resolve(WALL_EDGE_W), at)
			if col == cols - 1:
				draw_texture(TextureResolver.resolve(WALL_EDGE_E), at)
			if row == 0:
				draw_texture(TextureResolver.resolve(WALL_BASE), at)
			# With no roof at all, the parapet is what stops the wall.
			if roof_rows == 0 and row == wall_rows - 1:
				draw_texture(TextureResolver.resolve(ROOF_EDGE_N), at)

	for row in roof_rows:
		for col in cols:
			var at := _cell(col, wall_rows + row)
			draw_texture(TextureResolver.resolve(ROOF), at, roof_colour)
			if row == 0:
				draw_texture(TextureResolver.resolve(ROOF_EDGE_S), at)
			if row == roof_rows - 1:
				draw_texture(TextureResolver.resolve(ROOF_EDGE_N), at)
			if col == 0:
				draw_texture(TextureResolver.resolve(ROOF_EDGE_W), at)
			if col == cols - 1:
				draw_texture(TextureResolver.resolve(ROOF_EDGE_E), at)

	_draw_roof_furniture(wall_rows)

## Top-left corner of a cell, counting rows northward from the ground line.
func _cell(col: int, row: int) -> Vector2:
	return Vector2(-columns() * TILE * 0.5 + col * TILE, -(row + 1) * TILE)

# ------------------------------------------------------------- roof furniture ---

## Rolls this building's roof units, once per `_rebuild()` rather than once per frame — the same
## contract `_build_windows()` already keeps. Nothing is placed on a roof too shallow to have an
## interior cell at all (`roof_tiles() < 3` or `columns() < 3`), which most `INDUSTRIAL` and
## `CIVIC` roofs are not, and most single-tile-deep slivers are.
func _build_roof_furniture() -> void:
	_roof_furniture.clear()
	_has_vent = false
	var roof_rows := roof_tiles()
	var cols := columns()
	if roof_rows < 3 or cols < 3:
		return
	var kinds: Array = _KINDS_BY_DISTRICT.get(district, [])
	var density: float = _FURNITURE_DENSITY.get(district, 0.0)
	if kinds.is_empty() or density <= 0.0:
		return
	var interior: Array[Vector2i] = []
	for row in range(1, roof_rows - 1):
		for col in range(1, cols - 1):
			interior.append(Vector2i(col, row))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("roof:%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	_shuffle(interior, rng)
	var wanted := clampi(roundi(interior.size() * density), 1, interior.size())
	var used := {}
	if district == GameEnums.BlockPurpose.INDUSTRIAL:
		wanted -= _place_duct_run(cols, roof_rows, used, rng)
	var placed := 0
	for cell in interior:
		if placed >= wanted:
			break
		if used.has(cell):
			continue
		var kind: int = kinds[rng.randi() % kinds.size()]
		_roof_furniture.append({"cell": cell, "kind": kind, "span": 1})
		if kind == _Furniture.VENT:
			_has_vent = true
		placed += 1
	# Farthest (highest row) first, so `_draw_roof_furniture` paints back to front without
	# re-sorting on every redraw.
	_roof_furniture.sort_custom(func(a, b): return (a["cell"] as Vector2i).y > (b["cell"] as Vector2i).y)

## `INDUSTRIAL` only: a straight duct run and, where there is a second interior row to turn into,
## one elbow continuing it — "a duct run laid as a straight-and-corner chain" rather than loose
## units. Returns how many interior cells it used, which is subtracted from the district's own
## furniture budget so a duct run is not extra furniture on top of the density table.
func _place_duct_run(cols: int, roof_rows: int, used: Dictionary, rng: RandomNumberGenerator) -> int:
	if cols < 4 or roof_rows < 3:
		return 0
	var row := rng.randi_range(1, roof_rows - 2)
	var start_col := rng.randi_range(1, cols - 3)
	var straight := Vector2i(start_col, row)
	var straight_far := Vector2i(start_col + 1, row)
	used[straight] = true
	used[straight_far] = true
	_roof_furniture.append({"cell": straight, "kind": _Furniture.DUCT_STRAIGHT, "span": 2})
	var consumed := 2
	var corner := Vector2i(start_col + 1, row + 1)
	if row + 1 <= roof_rows - 2 and not used.has(corner):
		used[corner] = true
		_roof_furniture.append({"cell": corner, "kind": _Furniture.DUCT_CORNER, "span": 1})
		consumed += 1
	return consumed

## A Fisher-Yates shuffle over `rng` rather than `Array.shuffle()`, which reads the engine's own
## global RNG and would make the roll different every launch — every other seeded pick in this
## file (and `_build_windows()` beside it) stays reproducible from `variant` and position alone.
static func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cells[i]
		cells[i] = cells[j]
		cells[j] = tmp

## Paints every roof unit, back to front (`_build_roof_furniture` sorted them), above the roof
## tiles this same `_draw()` call has just finished — see the class doc for why nothing here may
## ever be y-sorted against the street: this is still the one `_draw()` the Buildings layer calls.
func _draw_roof_furniture(wall_rows: int) -> void:
	for entry in _roof_furniture:
		var cell: Vector2i = entry["cell"]
		var span: int = entry["span"]
		var at := _cell(cell.x, wall_rows + cell.y)
		var anchor := at + Vector2(TILE * span * 0.5, TILE)
		Sprites.draw_standing(self, _furniture_texture(entry["kind"]), anchor)

func _furniture_texture(kind: int) -> Texture2D:
	match kind:
		_Furniture.VENT:
			return VENT_B if _vent_frame_b else VENT_A
		_Furniture.HVAC_A:
			return HVAC_A
		_Furniture.HVAC_B:
			return HVAC_B
		_Furniture.DUCT_STRAIGHT:
			return DUCT_STRAIGHT
		_Furniture.DUCT_CORNER:
			return DUCT_CORNER
		_Furniture.SKYLIGHT_A:
			return SKYLIGHT_A
		_Furniture.SKYLIGHT_B:
			return SKYLIGHT_B
		_Furniture.VENT_STACK:
			return VENT_STACK
		_:
			return WATER_TANK
