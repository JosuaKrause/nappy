class_name FrameRecorder
extends Node
## Keeps every frame's time by system for the last few minutes of play, and gets the record off
## the device. *(2026-10-03, inbox #510, asked which frames to break down and how the record
## should get off the phone: "Every frame, slow ones marked" and "Download plus readout line".)*
##
## Built by `main` under `--frame-record` or the page's `?framerecord=1` (`DevFlags.
## frame_record_requested()`). It marks the engine's phases for `FrameLedger`: its own physics and
## process callbacks run first in their step (`PRIORITY_FIRST`), a child's process callback runs
## last (`PRIORITY_LAST`), and the renderer's post-draw callback ends the drawing. The named
## systems mark themselves through `FrameRecord`.
##
## **On the web, a button the page itself draws saves the record** through the browser's own
## download: a DOM element over the canvas rather than a game control, so a tap on it never also
## steers her, and the download starts inside the tap that asked for it, which is what a phone's
## browser requires. **On the desktop the record is written under `user://frame-records/`** on
## every scene exit, the same file each time, so a quit or a restart leaves the whole record.
##
## Frames are kept only while a day is being played — not paused, not the title, not a summary —
## but every frame is timed, so the phases stay in step across a pause. The record survives a
## restart (`FrameRecord.ledger` is static), so a recording that caught a stutter is not lost to
## the restart that followed it.

const PRIORITY_FIRST := -1000000000
const PRIORITY_LAST := 1000000000
## How many enter/leave pairs `calibrate()` times, once, at setup.
const CALIBRATION_PAIRS := 2000

## The child whose process callback runs after every other one.
class ProcessEnd extends Node:
	var recorder: FrameRecorder

	func _process(_delta: float) -> void:
		recorder.at_process_end()

var ledger: FrameLedger
var _main: Node
var _city: City
var _player: Stroller
var _day: DayController
var _metadata: Dictionary = {}

## Where a native record is written, chosen once per process so every scene exit rewrites the
## same file.
static var _native_path := ""
## The page button's callback into the recorder. See `_add_page_button()`.
static var _save_callback: JavaScriptObject

func setup(main: Node, city: City, player: Stroller, day: DayController) -> void:
	assert("_in_the_title" in main, "FrameRecorder reads main._in_the_title")
	_main = main
	_city = city
	_player = player
	_day = day
	name = "FrameRecorder"
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = PRIORITY_FIRST
	process_physics_priority = PRIORITY_FIRST
	var refresh := _refresh_hz()
	var budget_usec := roundi(1000000.0 / (refresh if refresh > 0.0 else 60.0))
	if FrameRecord.ledger == null:
		FrameRecord.start(FrameLedger.new(FrameLedger.CAPACITY, budget_usec * 3 / 2))
	ledger = FrameRecord.ledger
	_metadata = {"refresh_hz": refresh, "refresh_assumed": refresh <= 0.0,
		"display_budget_usec": budget_usec, "timer_pair_usec": calibrate()}
	var end := ProcessEnd.new()
	end.name = "ProcessEnd"
	end.recorder = self
	end.process_mode = Node.PROCESS_MODE_ALWAYS
	end.process_priority = PRIORITY_LAST
	add_child(end)
	RenderingServer.frame_post_draw.connect(_at_post_draw)
	if OS.get_name() == "Web":
		_add_page_button()

func _physics_process(_delta: float) -> void:
	ledger.physics_step(Time.get_ticks_usec())

func _process(_delta: float) -> void:
	ledger.process_start(Time.get_ticks_usec())

## The last process callback of the frame: the frame's world counters, whether it is kept, and
## the start of drawing. The counters are read here, before the clock moves to `draw`, so their
## own cost is the process step's.
func at_process_end() -> void:
	ledger.keep = not get_tree().paused and not _main.get("_in_the_title") and _day.is_running()
	if ledger.keep:
		var here := _player.global_position
		ledger.set_counter(FrameLedger.CROWD_AGENTS, _city.crowd.agent_count())
		ledger.set_counter(FrameLedger.LIVE_EVENTS, _city.events.active_count())
		ledger.set_counter(FrameLedger.PLAYER_X, roundi(here.x))
		ledger.set_counter(FrameLedger.PLAYER_Y, roundi(here.y))
		ledger.set_counter(FrameLedger.DAY, GameState.day)
		ledger.set_counter(FrameLedger.PROCESS_FRAME, Engine.get_process_frames())
	ledger.process_end(Time.get_ticks_usec())

func _at_post_draw() -> void:
	ledger.drawn(Time.get_ticks_usec())
	ledger.set_counter(FrameLedger.DRAW_CALLS, FrameCost.draw_calls())
	ledger.set_counter(FrameLedger.RENDER_OBJECTS, FrameCost.objects())
	ledger.set_counter(FrameLedger.PRIMITIVES, FrameCost.primitives())

## What one `FrameRecord.enter()`/`leave()` pair costs on this device, in microseconds, timed over
## `CALIBRATION_PAIRS` pairs on a scratch ledger through the same two calls the game makes. A
## frame's `timer_calls` times this is the record's own cost in that frame.
static func calibrate() -> float:
	var live := FrameRecord.ledger
	var was_on := FrameRecord.on
	FrameRecord.start(FrameLedger.new(1))
	var started := Time.get_ticks_usec()
	for _i in CALIBRATION_PAIRS:
		var outer := FrameRecord.enter(FrameRecord.CROWD)
		FrameRecord.leave(outer)
	var elapsed := Time.get_ticks_usec() - started
	FrameRecord.ledger = live
	FrameRecord.on = was_on
	return float(elapsed) / CALIBRATION_PAIRS

## The readout's line. See `FrameLedger.readout_line()`.
func readout_line() -> String:
	return ledger.readout_line()

## The whole record as the file's text.
func report_text() -> String:
	var report := ledger.report()
	report["schema"] = "nappy-frame-record"
	report["schema_version"] = 1
	report["gpu_time"] = "not measured: a phone's browser offers no GPU timing, so draw_usec " \
			+ "is the CPU side of drawing only"
	report["buckets"] = _bucket_notes()
	var metadata := _metadata.duplicate()
	metadata["build"] = TitleScreen.build_text()
	metadata["run_seed"] = GameState.run_seed
	metadata["ground_mode"] = DevFlags.ground_mode()
	metadata["scenery_budget_usec"] = SceneryResidency.BUDGET_USEC
	metadata["engine"] = Engine.get_version_info()
	metadata["renderer"] = RenderingServer.get_current_rendering_method()
	metadata["rendering_driver"] = RenderingServer.get_current_rendering_driver_name()
	metadata["video_adapter"] = RenderingServer.get_video_adapter_name()
	metadata["display_server"] = DisplayServer.get_name()
	metadata["main_thread_is_render_thread"] = RenderingServer.is_on_render_thread()
	metadata["saved_at"] = Time.get_datetime_string_from_system()
	if OS.get_name() == "Web":
		var agent: Variant = JavaScriptBridge.eval("navigator.userAgent")
		metadata["user_agent"] = agent if agent is String else ""
	report["environment"] = metadata
	return JSON.stringify(report)

## Saves the record: through the browser's download on the web, to `user://frame-records/` on
## the desktop. Answers where it went. The frame this runs in is not kept, since building the
## file is the slowest thing in it.
func save() -> String:
	var text := report_text()
	ledger.keep = false
	if OS.get_name() == "Web":
		var file_name := "nappy-frames-seed%d-%s.json" % [GameState.run_seed,
			Time.get_datetime_string_from_system().replace(":", "-")]
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, "application/json")
		return file_name
	if _native_path == "":
		_native_path = "user://frame-records/record-%s-seed%d.json" % [
			Time.get_datetime_string_from_system().replace(":", "-"), GameState.run_seed]
	if DirAccess.make_dir_recursive_absolute(_native_path.get_base_dir()) != OK:
		push_error("Cannot create the frame record directory")
		return ""
	var file := FileAccess.open(_native_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write the frame record: %s" % _native_path)
		return ""
	file.store_string(text)
	file.close()
	var written := ProjectSettings.globalize_path(_native_path)
	print("Frame record: %s" % written)
	return written

func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_at_post_draw):
		RenderingServer.frame_post_draw.disconnect(_at_post_draw)
	if OS.get_name() != "Web":
		save()

## The page's own button, added once per page: a reload of the scene hands the button the new
## recorder's callback rather than adding a second button. Focus goes back to the canvas after
## the tap, so the keyboard keeps steering in a desktop browser. The callback is held in a static,
## the way `GameSave` holds its own, because a callback GDScript lets go of stops answering.
func _add_page_button() -> void:
	JavaScriptBridge.eval(_BUTTON_JS)
	_save_callback = JavaScriptBridge.create_callback(_on_page_save)
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		push_error("FrameRecorder: the page's JavaScript is not reachable, so no save button")
		return
	window.call("nappyFrameRecordButton", _save_callback)

const _BUTTON_JS := """window.nappyFrameRecordButton = function (save) {
	window.nappyFrameRecordSave = save;
	if (document.getElementById('nappy-frame-record')) { return; }
	var button = document.createElement('button');
	button.id = 'nappy-frame-record';
	button.textContent = 'save frames';
	button.style.cssText = 'position:fixed;top:4px;left:50%;transform:translateX(-50%);'
		+ 'z-index:10;font:13px sans-serif;padding:6px 10px;opacity:0.75;';
	button.addEventListener('click', function (event) {
		event.stopPropagation();
		window.nappyFrameRecordSave();
		var canvas = document.querySelector('canvas');
		if (canvas) { canvas.focus(); }
	});
	document.body.appendChild(button);
};"""

func _on_page_save(_arguments: Array) -> void:
	save()

func _refresh_hz() -> float:
	if DisplayServer.get_name() == "headless":
		return -1.0
	return DisplayServer.screen_get_refresh_rate()

## What each bucket holds, written into the file so it reads without this source beside it.
static func _bucket_notes() -> Dictionary:
	return {
		"physics_rest": "physics steps' work no named system claims: her movement, the physics "
			+ "server's step, _draw() callbacks queued during physics",
		"process_rest": "process work no named system claims: main, HUD, day clock, resistance, "
			+ "scenery animation, the debug readout",
		"scenery": "SceneryResidency.update(): the scenery queue under its 2ms budget, guard "
			+ "preparations included",
		"crowd": "the crowd's pathing: Crowd._physics_process() and every CrowdAgent._process()",
		"influence": "the baby's influence sweep: Baby._physics_process()",
		"events": "event updates: EventManager._physics_process() and every "
			+ "EventInstance._process()",
		"cues": "danger cues: ExcitementHalo._process() and DangerEdge._process()",
		"draw": "CPU side of drawing: deferred calls and _draw() callbacks after the last "
			+ "_process(), then the renderer's sync and submit; no GPU time",
		"wait": "after the post-draw callback until the next frame: idle until the refresh, "
			+ "plus input and window events; not a cost",
	}
