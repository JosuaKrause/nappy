class_name BurstRecorder
extends RefCounted
## One bounded animation sequence at a time, asked for by a person (`B`): frames read off a screen
## into a folder of their own, with the `burst.json` manifest `tools/clip.py` turns into a video.
##
## **Handed everything it touches.** `Telemetry` builds the one a run uses and hands it the screen
## it photographs (`TelemetryScreen`), the clock its timestamps and waits run on (`Clock`) and the
## run log's `note`; each `start()` is handed the folder the sequence goes under. It asks the
## display server, the tree and the wall clock nothing itself, so a test hands it a screen whose
## frames it draws, a clock it moves and a scratch folder.
##
## The sequence is serialized one frame at a time, so a slow PNG write cannot create an unbounded
## backlog, and the timestamps record what the capture actually achieved rather than claiming the
## target rate. Every callback carries the token of the sequence it belongs to, so a deadline or a
## post-draw wait left over from a sequence that already ended cannot finish a newer one.

const VERSION := 1
const TARGET_FPS := 12
const DURATION_SECONDS := 3.0
const MAX_FRAMES := 36

## The time a sequence is measured against and the waits it takes: the engine's clock and the
## tree's timers in a game, a clock of its own in a test.
class Clock extends RefCounted:
	var _node: Node

	## `node` is any node in the tree whose timers the waits run on.
	func _init(node: Node = null) -> void:
		_node = node

	## Microseconds since some fixed moment; only differences are read.
	func usec() -> int:
		return Time.get_ticks_usec()

	## A signal emitted once `seconds` have passed, paused or not.
	func after(seconds: float) -> Signal:
		return _node.get_tree().create_timer(seconds, true).timeout

var _screen: TelemetryScreen
var _clock: Clock
var _note: Callable
var _burst: Dictionary = {}
var _serial := 0
var _token := 0

## `note` is called with a kind and a sentence for each line the run log gets about a sequence.
func _init(screen: TelemetryScreen, clock: Clock, note: Callable) -> void:
	_screen = screen
	_clock = clock
	_note = note

## Whether a sequence is being captured now.
func _is_active() -> bool:
	return _burst.size() > 0

## Starts a sequence in a new folder under `directory`, which is "" when the run has nowhere to put
## one. Refused while another is active, when the screen cannot draw or there is no folder, and when
## the folder or its first manifest cannot be written; each refusal is a line in the run log.
func start(directory: String, context: String) -> bool:
	if _is_active():
		_note.call("shot", "burst refused: another burst is active")
		return false
	if directory == "" or not _screen.can_draw():
		_note.call("shot", "burst refused: no drawable viewport")
		print("[Telemetry] burst refused: no drawable viewport")
		return false
	var burst_path := _next_path(directory)
	if DirAccess.make_dir_recursive_absolute(burst_path) != OK:
		_note.call("shot", "burst refused: could not create %s" % burst_path)
		push_warning("telemetry: could not create burst directory %s" % burst_path)
		return false
	_token += 1
	_burst = {
		"dir": burst_path,
		"context": context,
		"started_usec": _clock.usec(),
		"frames": [],
		"status": "active",
		"reason": "",
		"token": _token,
	}
	if not _write_metadata():
		_burst.clear()
		_note.call("shot", "burst refused: could not write metadata")
		push_warning("telemetry: burst metadata could not be written")
		return false
	_note.call("shot", "burst started: %s | %s/%s"
			% [context, directory.get_file(), burst_path.get_file()])
	print("[Telemetry] burst started: %s" % ProjectSettings.globalize_path(burst_path))
	_clock.after(DURATION_SECONDS).connect(_finish.bind(_token, "duration"), CONNECT_ONE_SHOT)
	_capture(_token)
	return true

## Ends the active sequence, if any, keeping its frames and a manifest that says it was cut short
## and why. A day or a run ending calls this.
func cancel(reason: String) -> void:
	if _is_active():
		_finish(int(_burst["token"]), "cancelled", reason)

## A folder under `directory` no sequence has used: an existing folder and an existing file are
## both passed over.
func _next_path(directory: String) -> String:
	_serial += 1
	var stamp := _clock.usec()
	var candidate := "%s/burst-%d-%03d" % [directory, stamp, _serial]
	while DirAccess.dir_exists_absolute(candidate) or FileAccess.file_exists(candidate):
		_serial += 1
		candidate = "%s/burst-%d-%03d" % [directory, stamp, _serial]
	return candidate

func _is_current(token: int) -> bool:
	return _burst.size() > 0 and int(_burst.get("token", -1)) == token

func _elapsed() -> float:
	return float(_clock.usec() - int(_burst["started_usec"])) / 1000000.0

## Chooses the terminal condition before a render wait, so a stalled renderer cannot add a frame
## beyond either bound. Duration wins at the shared boundary because it describes the elapsed run.
static func _finish_reason(elapsed: float, frame_count: int) -> String:
	if elapsed >= DURATION_SECONDS:
		return "duration"
	if frame_count >= MAX_FRAMES:
		return "frame_cap"
	return ""

func _capture(token: int) -> void:
	var burst_dir := str(_burst.get("dir", ""))
	while _is_current(token):
		var frames: Array = _burst["frames"]
		var finish_reason := _finish_reason(_elapsed(), frames.size())
		if finish_reason != "":
			_finish(token, finish_reason)
			return
		await _screen.drawn()
		if not _is_current(token):
			return
		if _elapsed() >= DURATION_SECONDS:
			_finish(token, "duration")
			return
		var image := _screen.picture()
		if image == null:
			_finish(token, "write_failed", "viewport disappeared")
			return
		var elapsed := _elapsed()
		frames = _burst["frames"]
		var file_name := "frame-%04d.png" % (frames.size() + 1)
		if image.save_png("%s/%s" % [burst_dir, file_name]) != OK:
			_finish(token, "write_failed", "could not write %s" % file_name)
			return
		frames.append({"file": file_name, "elapsed_seconds": elapsed})
		if not _write_metadata():
			_finish(token, "write_failed", "could not update burst metadata")
			return
		if not _is_current(token):
			return
		var wait_seconds := (float(frames.size()) / float(TARGET_FPS)) - elapsed
		if wait_seconds > 0.0:
			await _clock.after(wait_seconds)

func _finish(token: int, reason: String, detail := "") -> void:
	if not _is_current(token):
		return
	var path := str(_burst["dir"])
	var count: int = (_burst["frames"] as Array).size()
	var finished_with_frames := (reason == "duration" or reason == "frame_cap") and count > 0
	var ending := detail if detail != "" else reason
	if not finished_with_frames and count == 0 and reason == "duration":
		ending = "no frames captured before deadline"
	_burst["status"] = "complete" if finished_with_frames else "cancelled"
	_burst["reason"] = ending
	var outcome := str(_burst["status"])
	var wrote_metadata := _write_metadata()
	_burst.clear()
	if not wrote_metadata:
		_note.call("shot", "burst abandoned: metadata write failed")
		push_warning("telemetry: burst metadata could not be finalized")
		return
	_note.call("shot", "burst %s: %d frames | %s" % [outcome, count, ending])
	print("[Telemetry] burst %s: %s (%d frames)"
			% [outcome, ProjectSettings.globalize_path(path), count])

func _write_metadata() -> bool:
	if _burst.size() == 0:
		return false
	var metadata := {
		"schema_version": VERSION,
		"frames": _burst["frames"],
		"duration_seconds": _elapsed(),
		"target_fps": TARGET_FPS,
		"context": _burst["context"],
		"status": _burst["status"],
		"reason": _burst["reason"],
	}
	var file := FileAccess.open("%s/burst.json" % _burst["dir"], FileAccess.WRITE)
	if not file:
		push_warning("telemetry: could not write burst metadata")
		return false
	file.store_string(JSON.stringify(metadata, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_warning("telemetry: could not flush burst metadata")
		return false
	return true
