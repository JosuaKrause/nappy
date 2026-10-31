class_name FrameTrace
extends Node
## Opt-in presentation-path observer, independent of the ordered telemetry log.
## frame_post_draw is a CPU callback after render submission, NOT a physical scanout timestamp
## or GPU duration. A threaded renderer may defer it; metadata names that limitation.
## Counters are sampled here with the raw clock, never on a later reporting frame.

const WARMUP_USEC := 5000000

var buffer := FrameTraceBuffer.new()
## What the screen is showing, asked of whoever runs it and handed in by `setup()`: whether the
## title is up (sampled frames stop there, since nobody is playing), and whether the readout's and
## the frame graph's layers are on (each sample records both, since either costs a frame).
var _in_the_title: Callable
var _readout_on: Callable
var _graph_on: Callable
var _city: City
var _player: Stroller
var _day: DayController
## The run whose seed names the trace and whose calendar day each sample records, handed in by
## `setup()`.
var _run: RunState
var _started_usec := -1
var _metadata: Dictionary = {}
## The developer flags the run was given, handed in by `main` from its `RunConfig`.
var _user_flags: Array = []

func setup(in_the_title: Callable, readout_on: Callable, graph_on: Callable, city: City,
		player: Stroller, day: DayController, user_flags: Array, run: RunState) -> void:
	_run = run
	_in_the_title = in_the_title
	_readout_on = readout_on
	_graph_on = graph_on
	_city = city
	_player = player
	_day = day
	_user_flags = user_flags
	process_mode = Node.PROCESS_MODE_ALWAYS
	_metadata = environment()
	_metadata["run_seed"] = _run.header.run_seed
	_metadata["build"] = BuildInfo.build_text()
	_metadata["warmup_usec"] = WARMUP_USEC
	RenderingServer.frame_post_draw.connect(_sample)

func _sample() -> void:
	var now := Time.get_ticks_usec()
	if get_tree().paused or _in_the_title.call() or not _day.is_running():
		buffer.break_interval()
		if buffer.count == 0:
			_started_usec = -1
		return
	if _started_usec < 0:
		_started_usec = now
	if now - _started_usec < WARMUP_USEC:
		return
	if buffer.count == FrameTraceBuffer.CAPACITY:
		buffer.dropped += 1
		return
	var live := _city.events.instances()
	var identities := 0
	for instance in live:
		identities += instance.get_instance_id()
	var here := _player.global_position
	var counters := PackedInt64Array([
		Engine.get_physics_frames(), FrameCost.draw_calls(), FrameCost.objects(),
		FrameCost.primitives(), live.size(), identities, _city.crowd.agent_count(),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		roundi(here.x * 1000.0), roundi(here.y * 1000.0), _run.header.day,
		int(_readout_on.call()), int(_graph_on.call()),
		int(Telemetry.is_active())])
	buffer.append(now, Engine.get_process_frames(), Engine.get_frames_drawn(), counters)

## Startup/export metadata uses the driver-reported VSync mode, not the project setting.
## The compositor may still pace presentation independently; it cannot be inferred here.
func environment() -> Dictionary:
	var headless := DisplayServer.get_name() == "headless"
	var window := get_window()
	return {"clock": "Time.get_ticks_usec", "callback": "RenderingServer.frame_post_draw",
		"physical_presentation_measured": false, "display_server": DisplayServer.get_name(),
		"refresh_hz": -1.0 if headless else DisplayServer.screen_get_refresh_rate(),
		"vsync_mode": -1 if headless else DisplayServer.window_get_vsync_mode(),
		"render_thread_model": ProjectSettings.get_setting("rendering/driver/threads/thread_model", 1),
		"main_thread_is_render_thread": RenderingServer.is_on_render_thread(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"viewport_size": [get_viewport().get_visible_rect().size.x,
			get_viewport().get_visible_rect().size.y],
		"window_size": [window.size.x, window.size.y],
		"engine": Engine.get_version_info(), "max_fps": Engine.max_fps,
		"engine_flags": Array(OS.get_cmdline_args()),
		"engine_flags_complete": false,
		"engine_flags_note": "Godot omits consumed startup switches; retain the launch command too",
		"user_flags": _user_flags}

func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_sample):
		RenderingServer.frame_post_draw.disconnect(_sample)
	# Scene exit is after play. No stringify, file open, print, or flush occurs in _sample().
	var report := buffer.report(float(_metadata.get("refresh_hz", -1.0)))
	report["environment_start"] = _metadata
	report["environment_end"] = environment()
	var directory := "user://frame-traces"
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("Cannot create frame trace directory")
		return
	var path := "%s/trace-%s-seed%d-%d.json" % [directory,
		Time.get_datetime_string_from_system().replace(":", "-"),
		_run.header.run_seed, Time.get_ticks_usec()]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write frame trace: %s" % path)
		return
	file.store_string(JSON.stringify(report))
	file.close()
	print("Frame trace: %s" % ProjectSettings.globalize_path(path))
