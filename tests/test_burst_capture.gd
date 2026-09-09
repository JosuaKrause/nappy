extends RefCounted
## The capture control and manifest lifecycle that remain observable without a renderer.

const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

func run(t) -> void:
	_test_b_and_the_rig_action_choose_the_burst(t)
	_test_headless_and_overlapping_requests_refuse_before_a_capture_wait(t)
	_test_unique_paths_and_manifest_timing(t)
	_test_cancellation_and_stale_callbacks_cannot_cross_sequences(t)
	_test_metadata_write_failure_stops_without_claiming_success(t)

## The input map binds B through a physical key, so these are real `InputEventKey` shapes
## rather than action names invented by the test. The named action is the shape `--press` sends.
func _test_b_and_the_rig_action_choose_the_burst(t) -> void:
	var single := _p_key(false)
	var old_burst := _p_key(true)
	var burst := _b_key(false)
	var shifted_burst := _b_key(true)
	var echo := _b_key(false, true)
	var rig_action := InputEventAction.new()
	rig_action.action = &"snapshot_burst"
	rig_action.pressed = true

	t.check(MAIN_SCRIPT._debug_snapshot_action(single) == &"snapshot",
			"an unmodified physical P remains the single-snapshot action")
	t.check(MAIN_SCRIPT._debug_snapshot_action(old_burst) == &"snapshot",
			"Shift+P stays a single snapshot and no longer starts a burst")
	t.check(MAIN_SCRIPT._debug_snapshot_action(burst) == &"snapshot_burst",
			"an unmodified physical B selects the burst action")
	t.check(MAIN_SCRIPT._debug_snapshot_action(shifted_burst) == &"snapshot_burst",
			"Shift+B also selects the burst action")
	t.check(not burst.is_action_pressed("run"),
			"the burst key is not the run action")
	t.check(MAIN_SCRIPT._debug_snapshot_action(echo) == &"",
			"a held B echo cannot make another capture")
	t.check(MAIN_SCRIPT._debug_snapshot_action(rig_action) == &"snapshot_burst",
			"the named action used by the scripted rig follows the burst branch")

func _test_headless_and_overlapping_requests_refuse_before_a_capture_wait(t) -> void:
	Telemetry.begin_memory_log()
	t.check(not Telemetry.start_burst("headless test"),
			"headless capture refuses without beginning a renderer wait")
	t.check(Telemetry._burst.is_empty(), "headless refusal leaves no active recorder")

	Telemetry._burst = _burst_state("user://burst-overlap", 41)
	t.check(not Telemetry.start_burst("overlap test"),
			"a second request is refused before it can replace the active recorder")
	t.check(int(Telemetry._burst["token"]) == 41,
			"the refused request leaves the original recorder intact")
	Telemetry._burst.clear()
	Telemetry.end_run()

## The manifest is the handoff to `clip.py`: it must describe frame order and actual elapsed times,
## while path allocation must refuse both an existing directory and an existing file.
func _test_unique_paths_and_manifest_timing(t) -> void:
	var root := _temporary_directory("paths")
	var first := Telemetry._next_burst_path(root)
	t.check(DirAccess.make_dir_recursive_absolute(first) == OK,
			"the first generated burst directory can be created")
	var second := Telemetry._next_burst_path(root)
	t.check(second != first and not DirAccess.dir_exists_absolute(second),
			"a previous sequence directory is never selected again")
	var collision := FileAccess.open(second, FileAccess.WRITE)
	if collision:
		collision.close()
	var third := Telemetry._next_burst_path(root)
	t.check(third != second, "an existing file also cannot become a burst directory")

	Telemetry._burst = _burst_state(first, 42, [
		{"file": "frame-0001.png", "elapsed_seconds": 0.04},
		{"file": "frame-0002.png", "elapsed_seconds": 0.17},
	])
	t.check(Telemetry._write_burst_metadata(), "a writable sequence gets its initial manifest")
	var parsed := JSON.new()
	t.check(parsed.parse(FileAccess.get_file_as_string("%s/burst.json" % first)) == OK,
			"the manifest is valid JSON")
	var manifest: Dictionary = parsed.data
	t.check(manifest.get("schema_version") == 1 and not manifest.has("version"),
			"the manifest uses the converter's one-version schema")
	var frames: Array = manifest.get("frames", [])
	t.check(frames.size() == 2 and frames[0]["file"] == "frame-0001.png"
				and float(frames[0]["elapsed_seconds"]) < float(frames[1]["elapsed_seconds"]),
			"manifest frames remain numbered and strictly ordered by their capture timestamps")
	t.check(float(manifest["duration_seconds"]) > float(frames[1]["elapsed_seconds"]),
			"the actual burst duration is after its final readable frame")
	t.check(Telemetry._burst_finish_reason(3.0, Telemetry.BURST_MAX_FRAMES) == "duration"
				and Telemetry._burst_finish_reason(2.9, Telemetry.BURST_MAX_FRAMES) == "frame_cap",
			"duration and frame cap bound the recorder without allowing a thirty-seventh frame")
	Telemetry._burst.clear()
	_delete_recursive(root)

func _test_cancellation_and_stale_callbacks_cannot_cross_sequences(t) -> void:
	var root := _temporary_directory("lifecycle")
	Telemetry.begin_memory_log()
	Telemetry._burst = _burst_state(root, 51, [{"file": "frame-0001.png", "elapsed_seconds": 0.1}])
	Telemetry.end_day()
	t.check(Telemetry._burst.is_empty(), "ending a day cancels its active burst")
	var parsed := JSON.new()
	parsed.parse(FileAccess.get_file_as_string("%s/burst.json" % root))
	var cancelled: Dictionary = parsed.data
	t.check(cancelled.get("status") == "cancelled" and cancelled.get("reason") == "day ended",
			"a cancelled sequence records why its partial frames ended")
	Telemetry._burst = _burst_state(root, 52)
	Telemetry._on_burst_deadline(52)
	parsed.parse(FileAccess.get_file_as_string("%s/burst.json" % root))
	var empty_deadline: Dictionary = parsed.data
	t.check(empty_deadline.get("status") == "cancelled"
				and empty_deadline.get("reason") == "no frames captured before deadline",
			"a renderer that never draws leaves a cancelled, not complete, zero-frame sequence")

	Telemetry._burst = _burst_state(root, 53)
	Telemetry._on_burst_deadline(51)
	Telemetry._finish_burst(51, "duration")
	t.check(Telemetry._burst.get("status") == "active" and int(Telemetry._burst.get("token")) == 53,
			"an old timer or post-draw coroutine cannot finalize a newer sequence")
	Telemetry._burst.clear()
	Telemetry.end_run()
	_delete_recursive(root)

func _test_metadata_write_failure_stops_without_claiming_success(t) -> void:
	var root := _temporary_directory("write-failure")
	var blocked_manifest := "%s/burst.json" % root
	DirAccess.make_dir_recursive_absolute(blocked_manifest)
	Telemetry.begin_memory_log()
	Telemetry._burst = _burst_state(root, 61)
	t.check(not Telemetry._write_burst_metadata(),
			"a manifest path occupied by a directory reports its write failure")
	Telemetry._finish_burst(61, "duration")
	t.check(Telemetry._burst.is_empty(), "a metadata failure always terminates the recorder")
	var lines: Array = Telemetry.current_log().lines
	t.check(not lines.is_empty() and lines.back().contains("burst abandoned")
				and not lines.back().contains("finished"),
			"a failed final write is never logged as a successful burst")
	Telemetry.end_run()
	_delete_recursive(root)

func _p_key(shift: bool, repeated := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_P
	event.keycode = KEY_P
	event.shift_pressed = shift
	event.echo = repeated
	event.pressed = true
	return event

func _b_key(shift: bool, repeated := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_B
	event.keycode = KEY_B
	event.shift_pressed = shift
	event.echo = repeated
	event.pressed = true
	return event

func _burst_state(path: String, token: int, frames: Array = []) -> Dictionary:
	return {
		"dir": path,
		"context": "test",
		"started_usec": Time.get_ticks_usec() - 1000000,
		"frames": frames,
		"status": "active",
		"reason": "",
		"token": token,
	}

func _temporary_directory(name: String) -> String:
	var path := ProjectSettings.globalize_path("user://burst-test-%s-%d" % [name, Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(path)
	return path

func _delete_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir:
		for child in dir.get_directories():
			_delete_recursive("%s/%s" % [path, child])
		for file in dir.get_files():
			DirAccess.remove_absolute("%s/%s" % [path, file])
	DirAccess.remove_absolute(path)
