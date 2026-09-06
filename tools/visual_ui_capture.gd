extends Node
## Bounded visual review harness for the screen furniture.
##
## Run from the project root with the companion scene:
## `godot --path . --resolution 1280x720 --scene res://tools/visual_ui_capture.tscn -- --touch`
##
## It captures each state after a rendered frame rather than guessing from a timer. The deadline
## is wall-clock based so a window that loses focus cannot leave a capture run alive indefinitely.

const DEADLINE_SECONDS := 24.0
const WAIT_SECONDS := 0.45

var _started_at := 0
var _phase := 0
var _phase_started := 0
var _busy := false
var _main: Node

func _ready() -> void:
	_started_at = Time.get_ticks_msec()
	_phase_started = _started_at
	process_mode = Node.PROCESS_MODE_ALWAYS
	_main = get_node_or_null("Main")
	if not _main:
		push_error("visual capture needs a Main child")
		get_tree().quit(2)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if float(now - _started_at) / 1000.0 > DEADLINE_SECONDS:
		push_error("visual capture timed out")
		get_tree().quit(2)
		return
	if _busy:
		return
	if float(now - _phase_started) / 1000.0 < WAIT_SECONDS:
		return
	_run_phase()

func _run_phase() -> void:
	_busy = true
	match _phase:
		0:
			await _capture("/private/tmp/nappy-ui-title.png")
			_send_key(KEY_SPACE)
		1:
			await _capture("/private/tmp/nappy-ui-gameplay.png")
			_send_pause()
		2:
			await _capture("/private/tmp/nappy-ui-pause.png")
			_send_key(KEY_SPACE)
			await get_tree().process_frame
			_show_summary()
		3:
			await _capture("/private/tmp/nappy-ui-summary.png")
			_close_summary()
			await get_tree().process_frame
			get_window().size = Vector2i(720, 1280)
		4:
			await _capture("/private/tmp/nappy-ui-portrait-touch.png")
			get_tree().quit()
	_phase += 1
	_phase_started = now
	_busy = false

func _send_pause() -> void:
	var event := InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	Input.parse_input_event(event)

func _send_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = false
	Input.parse_input_event(event)

func _show_summary() -> void:
	var summary: Node = _main.get("_summary")
	assert(summary != null and summary.has_method("show_day"), "Main must expose DaySummary")
	summary.call("show_day", GameState.day, GameEnums.DayResult.LOST_TIMEOUT,
			"The clock runs out before the city quiets.", GameState.nerves)

func _close_summary() -> void:
	var summary: Node = _main.get("_summary")
	assert(summary != null and summary.has_method("dismiss"), "Main must expose DaySummary")
	summary.call("dismiss")

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("could not save %s (error %d)" % [path, error])
	else:
		print("[visual-ui] wrote %s (%dx%d)" % [path, image.get_width(), image.get_height()])
