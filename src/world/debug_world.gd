extends WorldContext
## Scaffold world for M1-M2: a hand-built 3x3 street grid with one park, one alley and one
## noise source, so movement, the meters and the falloff maths can all be exercised before
## the real city exists. M3 replaces this with the seeded CityGenerator; the block geometry
## here deliberately matches the constants that generator will use.

const GRID := Vector2i(3, 3)
## Which block is a park (calm zone), and which is split by an alley.
const PARK_BLOCK := Vector2i(1, 1)
const ALLEY_BLOCK := Vector2i(0, 2)
const ALLEY_WIDTH := 32.0

@onready var _entities: Node2D = $Entities

var _block_px: float
var _street_px: float
var _kerb: float
var _period: float
var _noise_sources: Array[DebugNoiseSource] = []

func _ready() -> void:
	super()
	_block_px = Tuning.BLOCK_SIZE * Tuning.TILE_SIZE
	_street_px = Tuning.STREET_WIDTH * Tuning.TILE_SIZE
	_kerb = float(Tuning.TILE_SIZE)
	_period = _block_px + _street_px
	_spawn_buildings()
	_spawn_noise()
	_spawn_player()
	queue_redraw()

# ----------------------------------------------------------- WorldContext ---

func is_calm_zone(world_position: Vector2) -> bool:
	return _park_rect().has_point(world_position)

func is_alley(world_position: Vector2) -> bool:
	return _alley_rect().has_point(world_position)

func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for source in _noise_sources:
		total += source.contribution_at(world_position)
	return total

# ------------------------------------------------------------------ layout ---

func _block_origin(block: Vector2i) -> Vector2:
	return Vector2(_street_px + block.x * _period, _street_px + block.y * _period)

## A block plus its kerb — the full walkable-or-built extent of the lot.
func _block_rect(block: Vector2i) -> Rect2:
	return Rect2(_block_origin(block) - Vector2.ONE * _kerb,
			Vector2.ONE * (_block_px + _kerb * 2.0))

func _park_rect() -> Rect2:
	return _block_rect(PARK_BLOCK)

func _alley_rect() -> Rect2:
	var origin := _block_origin(ALLEY_BLOCK)
	return Rect2(origin.x + (_block_px - ALLEY_WIDTH) * 0.5, origin.y - _kerb,
			ALLEY_WIDTH, _block_px + _kerb * 2.0)

func _spawn_buildings() -> void:
	var variant := 0
	for by in GRID.y:
		for bx in GRID.x:
			var block := Vector2i(bx, by)
			variant += 1
			if block == PARK_BLOCK:
				continue
			if block == ALLEY_BLOCK:
				_spawn_alley_pair(block, variant)
				continue
			_add_building(_block_origin(block) + Vector2(_block_px * 0.5, _block_px),
					Vector2(_block_px, _block_px), variant)

## An alley is carved by putting two narrower buildings on the lot with a gap between them.
func _spawn_alley_pair(block: Vector2i, variant: int) -> void:
	var origin := _block_origin(block)
	var half := (_block_px - ALLEY_WIDTH) * 0.5
	_add_building(origin + Vector2(half * 0.5, _block_px), Vector2(half, _block_px), variant)
	_add_building(origin + Vector2(_block_px - half * 0.5, _block_px),
			Vector2(half, _block_px), variant + 3)

func _add_building(at: Vector2, footprint: Vector2, variant: int) -> void:
	var building := Building.new()
	building.position = at
	building.footprint = footprint
	# Kept well under the lot depth so a roof always remains (see building.gd).
	building.height = 34.0 + float((variant * 23) % 62)
	building.variant = variant
	_entities.add_child(building)

func _spawn_noise() -> void:
	var source := DebugNoiseSource.new()
	source.position = _block_origin(PARK_BLOCK) + Vector2(_block_px * 0.5, -_street_px * 0.5)
	source.label = "test noise"
	_entities.add_child(source)
	_noise_sources.append(source)

func _spawn_player() -> void:
	var player := preload("res://scenes/player/stroller.tscn").instantiate()
	player.position = _block_origin(Vector2i(0, 0)) \
			+ Vector2(_block_px * 0.5, _block_px + _street_px * 0.5)
	_entities.add_child(player)

# ------------------------------------------------------------------ drawing ---
# Ground only. Drawn by this node itself so it sits behind the y-sorted Entities child.

func _draw() -> void:
	var extent := Vector2(GRID) * _period + Vector2.ONE * _street_px
	draw_rect(Rect2(Vector2.ZERO, extent), Palette.ASPHALT)
	_draw_road_markings(extent)

	for by in GRID.y:
		for bx in GRID.x:
			var block := Vector2i(bx, by)
			var rect := _block_rect(block)
			var is_park := block == PARK_BLOCK
			draw_rect(rect, Palette.GRASS if is_park else Palette.SIDEWALK)
			draw_rect(rect, Palette.SIDEWALK_SEAM, false, 1.0)

	draw_rect(_alley_rect(), Palette.ALLEY_FLOOR)

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
