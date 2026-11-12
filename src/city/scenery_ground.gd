class_name SceneryGround
extends Node2D
## Freeable map-cell batches sharing one loading-time TileSet. Queries expose resident cells;
## the CityMap remains the complete source of ground and gameplay facts.

const CHUNK_TILES := 8
const CHUNK_PX := CHUNK_TILES * Tuning.TILE_SIZE
## Match each step to one renderer quadrant so later steps never rebuild earlier cells.
const STEP_TILES := 4
## How SceneryResidency schedules a needed region's preparation; laziness, nearby-only and the
## load/unload boundaries are the same in all three. ALL prepares every needed region whole in
## the frame that needs it, as many as the residency's soft budget allows, the rest in the
## following frames, each under its own budget; ONE prepares at most one whole region a frame, the rest waiting for
## following frames; STEPPED spreads one region over frames, a renderer quadrant a frame. The
## values are the `--ground-mode` numbers (docs/playtests/2026-10-03-tawny-stork.md).
enum Mode { ALL = 1, ONE = 2, STEPPED = 3 }
## Handed in by the city before it builds (`--ground-mode`); a test sets it on an empty ground.
var mode: Mode = Mode.ONE
@export var tile_set: TileSet
var chunks: Dictionary = {}
## Visible in-tree at their real off-screen coordinates; hidden TileMaps discard render data.
## Only chunks owns complete regions. Each pending key owns exactly one unfinished layer.
var pending: Dictionary = {}
var _map: CityMap
## Which source each tile is painted from, asked of the city that owns the answer
## (`City.scenery_ground_source()`), handed in by `configure()`.
var _source_of := Callable()
## The city's library (`AtlasLibrary`), handed by the city before it configures the ground, and
## handed on to every water surface a chunk stands up.
var atlas: AtlasLibrary
## Whole-region prepare() time: every preparation in ALL and ONE, the guard's alone in STEPPED,
## whose ordinary quadrant steps use worst_step_usec.
var worst_prepare_usec := 0
var worst_step_usec := 0
## One pausable city clock keeps adjacent water chunks in phase, including newly entered ones.
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	for layer: TileMapLayer in chunks.values() + _pending_layers():
		for child: Node in layer.get_children():
			if child is SceneryWater:
				(child as SceneryWater).set_clock(elapsed)

func configure(map: CityMap, source_of: Callable, composed: TileSet) -> void:
	clear()
	_map = map
	_source_of = source_of
	tile_set = composed

static func key_for(tile: Vector2i) -> Vector2i:
	return Vector2i(floori(float(tile.x) / CHUNK_TILES),
			floori(float(tile.y) / CHUNK_TILES))

static func bounds(key: Vector2i) -> Rect2:
	return Rect2(Vector2(key) * CHUNK_PX, Vector2.ONE * CHUNK_PX)

func keys_in(view: Rect2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	# Ground residency follows whatever view asks, including the player's own camera, which has
	# no limits and so shows the landscape past the city's edge. Keeping it view-driven avoids a
	# permanently allocated world-sized backdrop.
	if not view.has_area():
		return result
	var lo := Vector2i((view.position / CHUNK_PX).floor())
	var hi := Vector2i((view.end / CHUNK_PX).ceil())
	for y in range(lo.y, hi.y):
		for x in range(lo.x, hi.x):
			result.append(Vector2i(x, y))
	return result

## The whole region in one call. STEPPED drains the quadrant steps, so its layout is the same
## whichever way a region is reached; ALL and ONE build it as one layer with one renderer
## quadrant and one water surface, its renderer work deferred to the frame's end.
func prepare(key: Vector2i) -> void:
	if chunks.has(key):
		return
	var started := Time.get_ticks_usec()
	if mode == Mode.STEPPED:
		while not prepare_step(key):
			pass
	else:
		_prepare_whole(key)
	worst_prepare_usec = maxi(worst_prepare_usec, Time.get_ticks_usec() - started)

func _prepare_whole(key: Vector2i) -> void:
	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	layer.name = "Chunk%d_%d" % [key.x, key.y]
	chunks[key] = layer
	add_child(layer)
	var water_cells: Array[Vector2i] = []
	for y in range(key.y * CHUNK_TILES, (key.y + 1) * CHUNK_TILES):
		for x in range(key.x * CHUNK_TILES, (key.x + 1) * CHUNK_TILES):
			var tile := Vector2i(x, y)
			var source: int = _source_of.call(tile)
			if source == GroundTiles.WATER:
				water_cells.append(tile)
			elif source >= 0:
				layer.set_cell(tile, source,
						GroundLayers.atlas_coords_for(source, _map.seed_used, tile, tile_set))
	if not water_cells.is_empty():
		var water := SceneryWater.new()
		water.atlas = atlas
		water.elapsed = elapsed
		layer.add_child(water)
		water.configure(water_cells)
		water.set_process(false)

## One bounded quadrant, including TileMap renderer command preparation, for STEPPED alone. The
## residency owner advances each region once per process frame; prepare() drains it for the
## safety guard.
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
			var source: int = _source_of.call(tile)
			if source == GroundTiles.WATER:
				water_cells.append(tile)
			elif source >= 0:
				layer.set_cell(tile, source,
						GroundLayers.atlas_coords_for(source, _map.seed_used, tile, tile_set))
	if not water_cells.is_empty():
		var water := SceneryWater.new()
		water.atlas = atlas
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
	worst_step_usec = maxi(worst_step_usec, Time.get_ticks_usec() - started)
	return complete

func _pending_layers() -> Array:
	return pending.values().map(func(job: Dictionary) -> TileMapLayer: return job.layer)

func cancel(key: Vector2i) -> void:
	if pending.has(key):
		(pending[key].layer as TileMapLayer).free()
		pending.erase(key)

func release(key: Vector2i) -> void:
	(chunks[key] as TileMapLayer).free()
	chunks.erase(key)

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
