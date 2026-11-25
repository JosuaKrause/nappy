extends Node
## The amber-puffin water experiment, a scene outside the game: the south water drawn as a blue
## base crossed by the white outlines of a Voronoi diagram whose centroids' intensities
## oscillate (`voronoi_water.gdshader`), beside the drawing it would replace. Nothing under
## `src/` loads it.
##
## One job a run, named after `--`:
##   --capture DIR   writes each look's frames as PNGs under DIR/<look>/, for a clip;
##   --measure FILE  writes what each way of drawing the water costs a frame at phone-sized
##                   canvases, as JSON.
## Either needs a display: a headless run draws nothing, and says so. The window takes no focus,
## and every frame is drawn on demand, so a covered window is measured and captured all alike.

const WATER_SHADER: Shader = preload("res://tests/probes/voronoi_water.gdshader")
## The game's own south-water shader, for the drawing the experiment would replace.
const CURRENT_SHADER: Shader = preload("res://assets/shaders/scenery_water.gdshader")
## The picture the baked `tiles/water` region holds today (`AtlasLibrary` takes the PNG transfer
## over `art/tiles/water.svg`). `art/` is not imported, so it is read from the file.
const CURRENT_TILE := "res://art/illustrated/svg-transfer/tiles/water.png"

const USAGE := "usage: voronoi_water.tscn -- (--capture NEW_DIR | --measure NEW_FILE | --help)"
## Where the drawn water stands in the world: south of anything, and far from the origin, so the
## shader's world coordinates are as large as the south water's own.
const WORLD_ORIGIN := Vector2(1600.0, 3200.0)
## A capture is the desktop window: the game's view at two screen pixels a world pixel.
const CAPTURE_SIZE := Vector2i(1280, 720)
const CAPTURE_FPS := 30
const CAPTURE_SECONDS := 6.0
## The looks a capture writes, in order.
const CAPTURE_LOOKS: Array[String] = ["curved", "straight", "tile_live", "current"]
## Phone-sized canvases. The game keeps 16:9, so on a phone held sideways the drawn area is the
## screen's height at 16:9: about 1920x1080 device pixels at a ratio near 2.6, the ratio the
## player's phone reported, and 1280x720 at a ratio capped near 1.7.
const CANVASES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720)]
## The ways of drawing the water a measurement compares. "empty" draws none, the baseline.
const MEASURED_LOOKS: Array[String] = [
	"empty", "flat", "current", "curved", "straight", "tile_prerendered", "tile_live",
]
## Each look is drawn once and this many times over the whole canvas; the difference over the
## extra copies is one pass's cost, apart from the fixed cost of a frame and of a live tile.
const STACK := 8
const TRIALS := 5
const WARMUP_FRAMES := 10
const TIMED_FRAMES := 120
## The prerendered tile is this many cells on a side, so its centroids wrap seamlessly.
const TILE_CELLS := 8
## A run that is not done by then is stuck, and ends.
const DEADLINE_MSEC := 300000

var _started := 0
## Every material whose clock a frame advances.
var _clocked: Array[ShaderMaterial] = []

func _ready() -> void:
	_started = Time.get_ticks_msec()
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(USAGE)
		get_tree().quit()
		return
	if args.size() != 2 or not (args[0] in ["--capture", "--measure"]) \
			or args[1].begins_with("-"):
		printerr(USAGE)
		get_tree().quit(2)
		return
	var target: String = args[1]
	if DirAccess.dir_exists_absolute(target) or FileAccess.file_exists(target):
		printerr("refusing to overwrite existing output: %s" % target)
		get_tree().quit(2)
		return
	if DisplayServer.get_name() == "headless":
		printerr("voronoi_water: nothing to draw, this run is headless")
		get_tree().quit(1)
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	get_window().size = Vector2i(320, 180)
	if args[0] == "--capture":
		_capture.call_deferred(target)
	else:
		_measure.call_deferred(target)

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - _started > DEADLINE_MSEC:
		push_error("voronoi_water exceeded its deadline")
		get_tree().quit(1)

# ---------------------------------------------------------------- capture ---

func _capture(directory: String) -> void:
	for look in CAPTURE_LOOKS:
		var folder := directory.path_join(look)
		if DirAccess.make_dir_recursive_absolute(folder) != OK:
			printerr("cannot create %s" % folder)
			get_tree().quit(1)
			return
		var view := _water(look, CAPTURE_SIZE, 1)
		await get_tree().process_frame
		var frames := roundi(CAPTURE_SECONDS * CAPTURE_FPS)
		for frame in frames:
			_set_clock(float(frame) / CAPTURE_FPS)
			RenderingServer.force_draw(false, 0.0)
			var image := view.get_texture().get_image()
			image.save_png(folder.path_join("frame-%04d.png" % frame))
		_drop(view)
		print("VORONOI_WATER captured %s: %d frames at %d fps" % [look, frames, CAPTURE_FPS])
		await get_tree().process_frame
	get_tree().quit()

# ---------------------------------------------------------------- measure ---

func _measure(output: String) -> void:
	var trials: Array[Dictionary] = []
	for trial in TRIALS:
		# Each trial walks the looks in a rotated order, so a drift in the machine's speed over the
		# run does not fall on the same look every time.
		var order: Array[String] = []
		for index in MEASURED_LOOKS.size():
			order.append(MEASURED_LOOKS[(index + trial) % MEASURED_LOOKS.size()])
		for canvas in CANVASES:
			for look in order:
				var counts: Array[int] = [1, STACK]
				if look == "empty":
					counts = [0]
				for copies in counts:
					var timing := await _time(look, canvas, copies)
					timing["trial"] = trial
					trials.append(timing)
	var result := {
		"engine": Engine.get_version_info().get("string", ""),
		"renderer": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"processor": OS.get_processor_name(),
		"stack": STACK, "timed_frames": TIMED_FRAMES, "warmup_frames": WARMUP_FRAMES,
		"tile_cells": TILE_CELLS, "summary": _summary(trials), "trials": trials,
		"elapsed_ms": Time.get_ticks_msec() - _started,
	}
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		printerr("cannot write %s" % output)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(result, "  ") + "\n")
	file.close()
	print("VORONOI_WATER " + JSON.stringify(result["summary"]))
	get_tree().quit()

## Draws `copies` of `look` over a `canvas`-sized viewport for TIMED_FRAMES frames, each drawn
## on demand, and returns the wall time a frame took. The clock moves every frame so nothing can
## be reused, and the closing read-back waits for the GPU to finish what was queued. Wall time
## rather than the engine's own GPU timer, which reads 0 under the Compatibility renderer.
func _time(look: String, canvas: Vector2i, copies: int) -> Dictionary:
	var view := _water(look, canvas, copies)
	await get_tree().process_frame
	for frame in WARMUP_FRAMES:
		_set_clock(float(frame) / 60.0)
		RenderingServer.force_draw(false, 0.0)
	view.get_texture().get_image()
	var began := Time.get_ticks_usec()
	for frame in TIMED_FRAMES:
		_set_clock(float(frame) / 60.0)
		RenderingServer.force_draw(false, 0.0)
	view.get_texture().get_image()
	var took := Time.get_ticks_usec() - began
	_drop(view)
	await get_tree().process_frame
	return {"look": look, "canvas": "%dx%d" % [canvas.x, canvas.y], "copies": copies,
		"frame_ms": float(took) / TIMED_FRAMES / 1000.0}

## Per canvas and look, the median over the trials of a frame's time once and STACK times, one
## pass's cost (the difference over the extra copies) and what is left of the single copy once
## the empty frame and one pass are taken off (a live tile's own drawing, for one).
func _summary(trials: Array[Dictionary]) -> Dictionary:
	var summary := {}
	for canvas in CANVASES:
		var label := "%dx%d" % [canvas.x, canvas.y]
		var empty := _median(_times(trials, label, "empty", 0))
		var looks := {"empty_frame_ms": empty}
		for look in MEASURED_LOOKS:
			if look == "empty":
				continue
			var once := _median(_times(trials, label, look, 1))
			var stacked := _median(_times(trials, label, look, STACK))
			var per_pass := (stacked - once) / (STACK - 1)
			looks[look] = {"once_ms": once, "stacked_ms": stacked, "pass_ms": per_pass,
				"fixed_ms": once - empty - per_pass}
		summary[label] = looks
	return summary

static func _times(trials: Array[Dictionary], canvas: String, look: String,
		copies: int) -> Array[float]:
	var found: Array[float] = []
	for timing in trials:
		if timing["canvas"] == canvas and timing["look"] == look and timing["copies"] == copies:
			found.append(float(timing["frame_ms"]))
	return found

static func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	var middle := int(sorted.size() / 2.0)
	if sorted.size() % 2 == 1:
		return sorted[middle]
	return (sorted[middle - 1] + sorted[middle]) / 2.0

# ---------------------------------------------------------------- drawing ---

## A viewport of `size` pixels showing the game's view of the water at WORLD_ORIGIN, scaled to
## fill it, with `copies` of `look` drawn over each other. Added to the tree; `_drop()` frees.
func _water(look: String, size: Vector2i, copies: int) -> SubViewport:
	_clocked.clear()
	var view := SubViewport.new()
	view.name = "Water"
	view.size = size
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var view_area := Rect2(WORLD_ORIGIN, Tuning.VIEW_HALF_EXTENT * 2.0)
	var zoom := float(size.x) / view_area.size.x
	add_child(view)
	view.canvas_transform = Transform2D(0.0, Vector2(zoom, zoom), 0.0, -WORLD_ORIGIN * zoom)
	var picture: Texture2D = null
	var material: ShaderMaterial = null
	var tile_size := 0.0
	match look:
		"curved", "straight":
			material = _voronoi(1 if look == "straight" else 0, 0)
		"current":
			picture = ImageTexture.create_from_image(
					Image.load_from_file(ProjectSettings.globalize_path(CURRENT_TILE)))
			material = _current()
			tile_size = Tuning.TILE_SIZE
		"tile_prerendered", "tile_live":
			picture = _tile(view, look == "tile_live")
	for copy in copies:
		var surface := Surface.new()
		surface.name = "Surface%d" % copy
		surface.paint(view_area, picture, tile_size)
		surface.material = material
		view.add_child(surface)
	return view

## A seamless tile of TILE_CELLS cells, a texel a world pixel, drawn into a viewport of its own
## under `parent`: once for a prerendered tile, every frame for a live one.
func _tile(parent: SubViewport, live: bool) -> Texture2D:
	var cell_size: float = RenderingServer.shader_get_parameter_default(
			WATER_SHADER.get_rid(), &"cell_size")
	var side := roundi(cell_size * TILE_CELLS)
	var tile := SubViewport.new()
	tile.name = "Tile"
	tile.size = Vector2i(side, side)
	tile.disable_3d = true
	tile.render_target_update_mode = \
			SubViewport.UPDATE_ALWAYS if live else SubViewport.UPDATE_ONCE
	parent.add_child(tile)
	var surface := Surface.new()
	surface.name = "TileSurface"
	surface.paint(Rect2(Vector2.ZERO, Vector2(side, side)), null, 0.0)
	surface.material = _voronoi(0, TILE_CELLS)
	tile.add_child(surface)
	return tile.get_texture()

func _voronoi(metric: int, wrap_cells: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("metric", metric)
	material.set_shader_parameter("wrap_cells", wrap_cells)
	_clocked.append(material)
	return material

func _current() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = CURRENT_SHADER
	material.set_shader_parameter("region_uv", Vector4(0.0, 0.0, 1.0, 1.0))
	material.set_shader_parameter("page_pixel", Vector2.ONE / Tuning.TILE_SIZE)
	_clocked.append(material)
	return material

func _set_clock(seconds: float) -> void:
	for material in _clocked:
		material.set_shader_parameter("elapsed", seconds)

func _drop(view: SubViewport) -> void:
	remove_child(view)
	view.free()
	_clocked.clear()

## One water surface: a flat rectangle when it has no picture (a shader colours it), the picture
## repeated across it, or the picture drawn once a tile, as `SceneryWater` draws today's water.
class Surface extends Node2D:
	var _area := Rect2()
	var _picture: Texture2D = null
	var _tile_size := 0.0

	func paint(area: Rect2, picture: Texture2D, tile_size: float) -> void:
		_area = area
		_picture = picture
		_tile_size = tile_size
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		queue_redraw()

	func _draw() -> void:
		if _picture == null:
			draw_rect(_area, Color(0.129, 0.349, 0.475))
		elif _tile_size <= 0.0:
			draw_texture_rect(_picture, _area, true)
		else:
			var extent := Vector2(_tile_size, _tile_size)
			var corner := (_area.position / _tile_size).floor()
			var across := ceili(_area.size.x / _tile_size) + 1
			var down := ceili(_area.size.y / _tile_size) + 1
			for y in down:
				for x in across:
					draw_texture_rect(_picture, Rect2((corner + Vector2(x, y)) * extent, extent),
							false)
