extends Node
## One bounded rendered pass through both real boot paths while their shader probes are live.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const DEADLINE_SECONDS := 30.0

var _output := OS.get_environment("SCENERY_CAPTURE_OUTPUT")
var _started_msec := 0
var _finished := false
var _result := {
	"schema_version": 1,
	"ordinary": {},
	"escape": {},
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_started_msec = Time.get_ticks_msec()
	if _output.is_empty() or not "--no-save" in OS.get_cmdline_user_args():
		_fail("SCENERY_CAPTURE_OUTPUT and --no-save are required")
		return
	if not "--no-telemetry" in OS.get_cmdline_user_args():
		_fail("--no-telemetry is required; this probe owns its complete output")
		return
	if DirAccess.make_dir_recursive_absolute(_output) != OK:
		_fail("cannot create the capture output")
		return
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	call_deferred("_run")

func _process(_delta: float) -> void:
	if not _finished and Time.get_ticks_msec() - _started_msec > int(DEADLINE_SECONDS * 1000.0):
		_fail("both boot paths did not render before the wall-clock deadline")

func _run() -> void:
	var ordinary := MAIN_SCENE.instantiate()
	ordinary.set("_escape_scene_requested", false)
	add_child(ordinary)
	_result.ordinary = await _observe_boot(ordinary, &"_player", "ordinary-boot.png")
	if not _result.ordinary.get("complete", false):
		_fail("ordinary boot did not complete its rendered warmup")
		return
	ordinary.free()
	get_tree().paused = false
	await get_tree().process_frame
	await get_tree().process_frame

	var escape := MAIN_SCENE.instantiate()
	escape.set("_escape_scene_requested", true)
	add_child(escape)
	_result.escape = await _observe_boot(escape, &"_hud", "escape-boot.png")
	if not _result.escape.get("complete", false):
		_fail("escape boot did not complete its rendered warmup")
		return
	escape.free()
	get_tree().paused = false
	await get_tree().process_frame
	_finish()

func _observe_boot(main: Node, ready_member: StringName, filename: String) -> Dictionary:
	var probes_before_draw := main.get_node_or_null("HaloWarm") != null \
			and main.get_node_or_null("WaterWarm") != null
	# The render loop's own frame, not `AutoScreenshot.drawn_frame()`, on purpose: what this probe
	# measures is the engine's warmup draw, which a forced frame would stand in for. Run it with its
	# window in view.
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	var probes_during_draw := main.get_node_or_null("HaloWarm") != null \
			and main.get_node_or_null("WaterWarm") != null
	while is_instance_valid(main) and main.get(ready_member) == null:
		if Time.get_ticks_msec() - _started_msec > int(DEADLINE_SECONDS * 1000.0):
			return {"complete": false, "reason": "deadline"}
		await get_tree().process_frame
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	var saved := true
	if DisplayServer.get_name() != "headless":
		saved = get_viewport().get_texture().get_image().save_png(
				_output.path_join(filename)) == OK
	return {
		"complete": probes_before_draw and probes_during_draw and saved,
		"warm_nodes_present_before_frame": probes_before_draw,
		"warm_nodes_present_at_frame_post_draw": probes_during_draw,
		"frame": filename if DisplayServer.get_name() != "headless" else "",
	}

func _finish() -> void:
	_finished = true
	_result["status"] = "complete"
	_result["display_server"] = DisplayServer.get_name()
	_result["rendering_method"] = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	_result["rendering_driver"] = RenderingServer.get_current_rendering_driver_name()
	_result["adapter"] = RenderingServer.get_video_adapter_name()
	_result["engine"] = Engine.get_version_info()
	_result["arguments"] = Array(OS.get_cmdline_args())
	_result["user_arguments"] = Array(OS.get_cmdline_user_args())
	_result["elapsed_wall_seconds"] = float(Time.get_ticks_msec() - _started_msec) / 1000.0
	var file := FileAccess.open(_output.path_join("capture.json"), FileAccess.WRITE)
	if file == null:
		_fail("cannot write capture metadata")
		return
	file.store_string(JSON.stringify(_result, "  ") + "\n")
	file.close()
	print("SCENERY_WARMUP " + JSON.stringify(_result))
	get_tree().quit()

func _fail(reason: String) -> void:
	if _finished:
		return
	_finished = true
	push_error(reason)
	get_tree().quit(1)
