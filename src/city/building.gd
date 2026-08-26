class_name Building
extends StaticBody2D
## A 2.5D extruded block.
##
## The node origin is the SOUTH edge centre of the lot, so y-sorting against the player
## uses the same ground plane the collision does. The lot spans local y in [-depth, 0].
##
## The building's drawn mass fills exactly its lot: the front wall takes the southern
## `height` px and the roof takes what is left. That is what an oblique view of a taller
## building actually looks like — more wall, less roof — and it keeps every extrusion off
## the street, so the player is never hidden under a roof while walking past one.
##
##      lot top ─▶ ┌──────────┐  roof   y = -depth .. -height
##                 ├──────────┤
##                 │          │  wall   y = -height .. 0
##   origin (0,0)  └──────────┘

## Lot size in px: x = width, y = depth (how far north it extends).
@export var footprint := Vector2(96.0, 96.0):
	set(value):
		footprint = value
		_rebuild()

## Extruded height. Must stay below `footprint.y`, or there is no roof left to draw.
@export var height := 44.0:
	set(value):
		height = value
		_rebuild()

## Selects the roof colour and the window pattern.
@export var variant := 0:
	set(value):
		variant = value
		_rebuild()

var _collision: CollisionShape2D
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

## Depth of the visible roof once the wall has taken its share of the lot.
func roof_depth() -> float:
	return maxf(footprint.y - height, 4.0)

## Window lighting is fixed at build time, not rolled per frame, or the city would flicker.
func _build_windows() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	_windows.clear()
	for i in _window_columns() * _window_rows():
		_windows.append(rng.randf() < 0.28)

func _window_columns() -> int:
	return maxi(1, int(footprint.x / 26.0))

func _window_rows() -> int:
	return maxi(1, int(height / 20.0))

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	var w := footprint.x * 0.5
	var roof := roof_depth()

	draw_rect(Rect2(Vector2(-w, -height), Vector2(footprint.x, height)),
			Palette.building_wall(variant))
	_draw_windows(w)
	draw_rect(Rect2(Vector2(-w, -height - roof), Vector2(footprint.x, roof)),
			Palette.building_roof(variant))

	# Outline the roof and the wall separately so the eaves line reads as an edge.
	draw_rect(Rect2(Vector2(-w, -height - roof), Vector2(footprint.x, roof)),
			Palette.OUTLINE, false, 1.5)
	draw_rect(Rect2(Vector2(-w, -height), Vector2(footprint.x, height)),
			Palette.OUTLINE, false, 1.5)

func _draw_windows(half_width: float) -> void:
	var cols := _window_columns()
	var rows := _window_rows()
	var cell := Vector2(footprint.x / cols, height / rows)
	var size := Vector2(cell.x * 0.34, cell.y * 0.42)
	for row in rows:
		for col in cols:
			var index := row * cols + col
			var lit: bool = _windows[index] if index < _windows.size() else false
			var at := Vector2(
				-half_width + cell.x * (col + 0.5) - size.x * 0.5,
				-height + cell.y * (row + 0.5) - size.y * 0.5)
			draw_rect(Rect2(at, size), Palette.WINDOW_LIT if lit else Palette.WINDOW_DARK)
