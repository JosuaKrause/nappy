extends Node2D
## Scaffold world for M1: a hand-built 3x3 street grid to prove out movement, the oblique
## rendering and y-sorting. M3 replaces this wholesale with the seeded CityGenerator; the
## block geometry here deliberately matches the constants that generator will use.

const GRID := Vector2i(3, 3)

@onready var _entities: Node2D = $Entities

var _block_px: float
var _street_px: float
var _period: float

func _ready() -> void:
	_block_px = Tuning.BLOCK_SIZE * Tuning.TILE_SIZE
	_street_px = Tuning.STREET_WIDTH * Tuning.TILE_SIZE
	_period = _block_px + _street_px
	_spawn_buildings()
	_spawn_player()
	queue_redraw()

func _spawn_buildings() -> void:
	var variant := 0
	for by in GRID.y:
		for bx in GRID.x:
			var origin := _block_origin(Vector2i(bx, by))
			var building := Building.new()
			# Origin is the south edge centre of the footprint (see building.gd).
			building.position = origin + Vector2(_block_px * 0.5, _block_px)
			building.footprint = Vector2(_block_px, _block_px)
			# Varied heights, all comfortably under the lot depth so a roof always shows.
			building.height = 34.0 + float((variant * 23) % 62)
			building.variant = variant
			_entities.add_child(building)
			variant += 1

func _spawn_player() -> void:
	var player := preload("res://scenes/player/stroller.tscn").instantiate()
	# Start on the street south of the first block.
	player.position = _block_origin(Vector2i(0, 0)) + Vector2(_block_px * 0.5, _block_px + _street_px * 0.5)
	_entities.add_child(player)

func _block_origin(block: Vector2i) -> Vector2:
	return Vector2(_street_px + block.x * _period, _street_px + block.y * _period)

# ------------------------------------------------------------------ drawing ---
# Ground only. Drawn by this node itself so it sits behind the y-sorted Entities child.

func _draw() -> void:
	var extent := Vector2(GRID) * _period + Vector2.ONE * _street_px
	draw_rect(Rect2(Vector2.ZERO, extent), Palette.ASPHALT)
	_draw_road_markings(extent)

	# Sidewalks: each block plus a one-tile kerb all the way round.
	var kerb := float(Tuning.TILE_SIZE)
	for by in GRID.y:
		for bx in GRID.x:
			var origin := _block_origin(Vector2i(bx, by))
			var rect := Rect2(origin - Vector2.ONE * kerb,
					Vector2.ONE * (_block_px + kerb * 2.0))
			draw_rect(rect, Palette.SIDEWALK)
			draw_rect(rect, Palette.SIDEWALK_SEAM, false, 1.0)

func _draw_road_markings(extent: Vector2) -> void:
	var dash := 14.0
	var gap := 12.0
	for i in GRID.x + 1:
		var x := _street_px * 0.5 + i * _period
		var y := 0.0
		while y < extent.y:
			draw_line(Vector2(x, y), Vector2(x, minf(y + dash, extent.y)), Palette.ROAD_MARKING, 2.0)
			y += dash + gap
	for i in GRID.y + 1:
		var y2 := _street_px * 0.5 + i * _period
		var x2 := 0.0
		while x2 < extent.x:
			draw_line(Vector2(x2, y2), Vector2(minf(x2 + dash, extent.x), y2), Palette.ROAD_MARKING, 2.0)
			x2 += dash + gap
