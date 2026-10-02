class_name SceneryGround
extends Node2D
## Freeable map-cell batches sharing one loading-time TileSet. Queries expose resident cells;
## the CityMap remains the complete source of ground and gameplay facts.

const CHUNK_TILES := 8
const CHUNK_PX := CHUNK_TILES * Tuning.TILE_SIZE
## Match each step to one renderer quadrant so later steps never rebuild earlier cells.
const STEP_TILES := 4
@export var tile_set: TileSet
var chunks: Dictionary = {}
## Visible in-tree at their real off-screen coordinates; hidden TileMaps discard render data.
## Only chunks owns complete regions. Each pending key owns exactly one unfinished layer.
var pending: Dictionary = {}
var _city: City
var prepared := 0
var evicted := 0
var worst_prepare_usec := 0
var worst_step_usec := 0
## One pausable city clock keeps adjacent water chunks in phase, including newly entered ones.
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	for layer: TileMapLayer in chunks.values() + _pending_layers():
		for child in layer.get_children():
			if child is SceneryWater:
				child.elapsed = elapsed
				child._ripples.set_shader_parameter("elapsed", elapsed)

func configure(city: City, composed: TileSet) -> void:
	clear()
	_city = city
	tile_set = composed

static func key_for(tile: Vector2i) -> Vector2i:
	return Vector2i(floori(float(tile.x) / CHUNK_TILES),
			floori(float(tile.y) / CHUNK_TILES))

static func bounds(key: Vector2i) -> Rect2:
	return Rect2(Vector2(key) * CHUNK_PX, Vector2.ONE * CHUNK_PX)

func keys_in(view: Rect2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var extent := Rect2(Vector2.ZERO, _city.map.world_size()).grow(
			City.OUTSIDE_DEPTH_TILES * Tuning.TILE_SIZE)
	var clipped := view.intersection(extent)
	if not clipped.has_area():
		return result
	var lo := Vector2i((clipped.position / CHUNK_PX).floor())
	var hi := Vector2i((clipped.end / CHUNK_PX).ceil())
	for y in range(lo.y, hi.y):
		for x in range(lo.x, hi.x):
			result.append(Vector2i(x, y))
	return result

func prepare(key: Vector2i) -> void:
	if chunks.has(key):
		return
	var started := Time.get_ticks_usec()
	while not prepare_step(key):
		pass
	worst_prepare_usec = maxi(worst_prepare_usec, Time.get_ticks_usec() - started)

## One bounded quadrant, including TileMap renderer command preparation. The residency owner
## calls this at most once per process frame; prepare() drains it for the safety guard.
func prepare_step(key: Vector2i) -> bool:
	if chunks.has(key):
		return true
	var started := Time.get_ticks_usec()
	if not pending.has(key):
		var created := TileMapLayer.new()
		created.tile_set = tile_set
		created.rendering_quadrant_size = STEP_TILES
		created.name = "Chunk%d_%d" % [key.x, key.y]
		add_child(created)
		pending[key] = {"layer": created, "step": 0}
	var job: Dictionary = pending[key]
	var layer: TileMapLayer = job.layer
	var side := CHUNK_TILES / STEP_TILES
	var step: int = job.step
	var origin := key * CHUNK_TILES + Vector2i(step % side, step / side) * STEP_TILES
	var water_cells: Array[Vector2i] = []
	for y in range(origin.y, origin.y + STEP_TILES):
		for x in range(origin.x, origin.x + STEP_TILES):
			var tile := Vector2i(x, y)
			var source := _city.scenery_ground_source(tile)
			if source == GroundTiles.WATER:
				water_cells.append(tile)
			elif source >= 0:
				layer.set_cell(tile, source,
						GroundLayers.atlas_coords_for(source, _city.map.seed_used, tile, tile_set))
	if not water_cells.is_empty():
		var water := SceneryWater.new()
		water.elapsed = elapsed
		layer.add_child(water)
		water.configure(water_cells)
		water.set_process(false)
	# set_cell defers engine work. Flush this quadrant now so the timer includes that work,
	# and the last frame cannot inherit creation of all the preceding quadrants.
	layer.update_internals()
	job.step = step + 1
	var complete: bool = job.step == side * side
	if complete:
		chunks[key] = layer
		pending.erase(key)
		prepared += 1
	worst_step_usec = maxi(worst_step_usec, Time.get_ticks_usec() - started)
	return complete

func _pending_layers() -> Array:
	return pending.values().map(func(job: Dictionary): return job.layer)

func cancel(key: Vector2i) -> void:
	if pending.has(key):
		(pending[key].layer as TileMapLayer).free()
		pending.erase(key)

func release(key: Vector2i) -> void:
	(chunks[key] as TileMapLayer).free()
	chunks.erase(key)
	evicted += 1

func clear() -> void:
	for key: Vector2i in pending.keys():
		cancel(key)
	for key: Vector2i in chunks.keys():
		release(key)

func repaint() -> void:
	var keys := chunks.keys()
	clear()
	for key: Vector2i in keys:
		prepare(key)

func set_cell(tile: Vector2i, source: int, coords := Vector2i.ZERO) -> void:
	# A live edit can alter neighbors already prepared in an unfinished quadrant. Reconstruct
	# that region from current map state on the next step instead of publishing mixed state.
	cancel(key_for(tile))
	var layer: TileMapLayer = chunks.get(key_for(tile))
	if layer:
		layer.set_cell(tile, source, coords)

func get_cell_source_id(tile: Vector2i) -> int:
	var layer: TileMapLayer = chunks.get(key_for(tile))
	return layer.get_cell_source_id(tile) if layer else -1

func get_cell_atlas_coords(tile: Vector2i) -> Vector2i:
	var layer: TileMapLayer = chunks.get(key_for(tile))
	return layer.get_cell_atlas_coords(tile) if layer else Vector2i(-1, -1)

func get_used_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for layer: TileMapLayer in chunks.values():
		cells.append_array(layer.get_used_cells())
	return cells

func has_water(tile: Vector2i) -> bool:
	var layer: TileMapLayer = chunks.get(key_for(tile))
	if layer:
		for child in layer.get_children():
			if child is SceneryWater and child.cells.has(tile):
				return true
	return false
