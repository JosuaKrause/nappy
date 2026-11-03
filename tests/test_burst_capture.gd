extends RefCounted
## The capture keys, and the animation burst's lifecycle and manifest.
##
## The keys are pushed through the viewport to the readout and read back from the run log. The
## lifecycle is the `BurstRecorder` `Telemetry` builds, handed what the game hands it: a screen
## (here `Screen`, whose frames the test draws), a clock (here `Clock`, which the test moves and
## whose waits it ends) and a folder (a scratch one under `user://`, removed afterwards). What a
## sequence did is read where `tools/clip.py` reads it, in the folder and its `burst.json`, and in
## the lines it hands the run log.


func run(t) -> void:
	t.gives_back_observers()
	_test_b_and_the_rig_action_choose_the_burst(t)
	_test_a_release_build_ignores_the_capture_keys(t)
	_test_headless_and_overlapping_requests_refuse_before_a_capture_wait(t)
	_test_unique_paths_and_manifest_timing(t)
	_test_cancellation_and_stale_callbacks_cannot_cross_sequences(t)
	_test_metadata_write_failure_stops_without_claiming_success(t)

const UI := preload("res://tests/ui_screens.gd")

## The readout the way `main` sets it up on a debug build, handed a `RunSession` over the run log
## (a log held in memory), in a tree where the viewport delivers it keys.
class Rig:
	var readout := DebugReadout.new()
	var label := Label.new()
	var layer := CanvasLayer.new()
	var session := RunSession.new()
	var run := RunState.new()

	func _init(t, debug_build := true) -> void:
		Telemetry.begin_memory_log()
		t.add_child(layer)
		layer.add_child(label)
		var config := RunConfig.parse(PackedStringArray(), "", debug_build)
		session.setup(Telemetry, config, EventBus, run)
		readout.setup(config, label, layer, run.header, session, Callable())
		t.add_child(readout)

	## The run log's lines that begin a picture or a burst the key asked for.
	func asked() -> Array[String]:
		var found: Array[String] = []
		for line: String in Telemetry.current_log().lines:
			if line.contains("asked for a picture") or line.contains("burst"):
				found.append(line)
		return found

	func free_all() -> void:
		readout.free()
		layer.free()
		session.free()
		run.free()
		Telemetry.end_run()

## The input map binds B through a physical key, so these are real `InputEventKey` shapes
## rather than action names invented by the test. The named action is the shape `--press` sends.
## Each is pushed through the viewport to the readout, and what it chose is read from the run log:
## a picture writes the line "asked for a picture", a burst the line the headless refusal writes
## ("burst refused"), since a headless run has no drawable viewport to capture.
func _test_b_and_the_rig_action_choose_the_burst(t) -> void:
	var rig := Rig.new(t)
	var rig_action := InputEventAction.new()
	rig_action.action = &"snapshot_burst"
	rig_action.pressed = true

	UI.push(rig.readout, _p_key(false))
	t.check(_pictures(rig) == 1 and _bursts(rig) == 0,
			"an unmodified physical P remains the single-snapshot action")
	UI.push(rig.readout, _p_key(true))
	t.check(_pictures(rig) == 2 and _bursts(rig) == 0,
			"Shift+P stays a single snapshot and no longer starts a burst")
	UI.push(rig.readout, _b_key(false))
	t.check(_pictures(rig) == 2 and _bursts(rig) == 1,
			"an unmodified physical B selects the burst action")
	UI.push(rig.readout, _b_key(true))
	t.check(_pictures(rig) == 2 and _bursts(rig) == 2, "Shift+B also selects the burst action")
	t.check(not _b_key(false).is_action_pressed("run"), "the burst key is not the run action")
	UI.push(rig.readout, _b_key(false, true))
	t.check(_pictures(rig) == 2 and _bursts(rig) == 2, "a held B echo cannot make another capture")
	UI.push(rig.readout, rig_action)
	t.check(_pictures(rig) == 2 and _bursts(rig) == 3,
			"the named action used by the scripted rig follows the burst branch")
	rig.free_all()

func _test_a_release_build_ignores_the_capture_keys(t) -> void:
	var rig := Rig.new(t, false)
	UI.push(rig.readout, _p_key(false))
	UI.push(rig.readout, _b_key(false))
	t.check(rig.asked().is_empty(), "the capture keys do nothing outside a debug build")
	rig.free_all()

func _pictures(rig: Rig) -> int:
	return rig.asked().filter(func(line: String) -> bool: return line.contains("asked for a picture")).size()

func _bursts(rig: Rig) -> int:
	return rig.asked().filter(func(line: String) -> bool: return line.contains("burst refused")).size()

## A screen whose frames the test draws: `draw()` ends the wait for a drawn frame, and the picture is
## a small blank image.
class Screen extends TelemetryScreen:
	signal drew
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)

	func can_draw() -> bool:
		return true

	func drawn() -> void:
		await drew

	func picture() -> Image:
		return image

## One wait on `Clock`, ended by the test.
class Wait extends RefCounted:
	signal done
	var due := 0
	var ended := false

	func _init(at: int) -> void:
		due = at

	func end() -> void:
		if not ended:
			ended = true
			done.emit()

## A clock the test moves. Every wait the recorder takes is kept in `waits`, the first being the
## sequence's deadline, which `start()` takes before anything else.
class Clock extends BurstRecorder.Clock:
	var now := 5000000
	var waits: Array[Wait] = []

	func usec() -> int:
		return now

	func after(seconds: float) -> Signal:
		var wait := Wait.new(now + roundi(seconds * 1000000.0))
		waits.append(wait)
		return wait.done

	## Moves the clock on by `seconds` and ends every wait due by then, oldest first.
	func advance(seconds: float) -> void:
		now += roundi(seconds * 1000000.0)
		for wait: Wait in waits.duplicate():
			if wait.due <= now:
				wait.end()

	## Ends every wait but the deadlines in `kept`, whatever the clock says: a renderer the pacing
	## does not hold back.
	func end_waits_but(kept: Array[Wait]) -> void:
		for wait: Wait in waits.duplicate():
			if not wait in kept:
				wait.end()

## A recorder with its screen, clock and scratch folder, and the run log lines it wrote.
class Bench:
	var screen := Screen.new()
	var clock := Clock.new()
	var lines: Array[String] = []
	var root := ""
	var recorder: BurstRecorder

	func _init(name: String) -> void:
		root = ProjectSettings.globalize_path("user://burst-test-%s-%d" % [name, Time.get_ticks_usec()])
		DirAccess.make_dir_recursive_absolute(root)
		recorder = BurstRecorder.new(screen, clock, noted)

	func noted(kind: String, text: String) -> void:
		lines.append("%s %s" % [kind, text])

	## Starts a sequence under the scratch folder and returns its own folder, read off the line the
	## start wrote ("" when refused).
	func start(context: String) -> String:
		if not recorder.start(root, context):
			return ""
		var line := lines.back() as String
		return "%s/%s" % [root, line.get_slice("/", line.get_slice_count("/") - 1)]

	## Draws one frame on the screen.
	func draw() -> void:
		screen.drew.emit()

	## The manifest in `folder`, or an empty dictionary when it is not valid JSON.
	func manifest(folder: String) -> Dictionary:
		var parsed := JSON.new()
		if parsed.parse(FileAccess.get_file_as_string("%s/burst.json" % folder)) != OK:
			return {}
		return parsed.data

	## Ends whatever is left — a sequence, a pending wait, a coroutine waiting on a frame — and
	## removes the scratch folder.
	func close() -> void:
		recorder.cancel("test over")
		clock.advance(60.0)
		screen.drew.emit()
		_delete_recursive(root)

	static func _delete_recursive(path: String) -> void:
		var dir := DirAccess.open(path)
		if dir:
			for child in dir.get_directories():
				_delete_recursive("%s/%s" % [path, child])
			for file in dir.get_files():
				DirAccess.remove_absolute("%s/%s" % [path, file])
		DirAccess.remove_absolute(path)

## `Telemetry`'s own burst refuses in a headless run, where its screen draws nothing, and on a log
## with no run folder; the refusal starts nothing, so a second request is refused the same way and
## not as an overlap. A recorder with a sequence running refuses a second before it can replace it.
func _test_headless_and_overlapping_requests_refuse_before_a_capture_wait(t) -> void:
	Telemetry.begin_memory_log()
	t.check(not Telemetry.start_burst("headless test"),
			"headless capture refuses without beginning a renderer wait")
	t.check(not Telemetry.start_burst("headless again")
				and _count(Telemetry.current_log().lines, "burst refused: no drawable viewport") == 2
				and _count(Telemetry.current_log().lines, "another burst is active") == 0,
			"headless refusal leaves no active recorder")
	Telemetry.end_run()

	var bench := Bench.new("overlap")
	var first := bench.start("first")
	t.check(first != "" and not bench.recorder.start(bench.root, "overlap test")
				and bench.lines.back().contains("burst refused: another burst is active"),
			"a second request is refused before it can replace the active recorder")
	bench.draw()
	var manifest := bench.manifest(first)
	t.check(DirAccess.get_directories_at(bench.root).size() == 1
				and manifest.get("context") == "first" and manifest.get("status") == "active"
				and (manifest.get("frames", []) as Array).size() == 1,
			"the refused request leaves the original recorder intact")
	bench.close()

## The manifest is the handoff to `clip.py`: it must describe frame order and actual elapsed times,
## while path allocation must refuse both an existing directory and an existing file. Every folder
## is named from the clock, which stands still here, so each new one has to step past the others.
func _test_unique_paths_and_manifest_timing(t) -> void:
	var bench := Bench.new("paths")
	var first := bench.start("first")
	t.check(first != "" and DirAccess.dir_exists_absolute(first),
			"the first generated burst directory can be created")
	var opened := bench.manifest(first)
	t.check(opened.get("status") == "active" and (opened.get("frames", [1]) as Array).is_empty(),
			"a writable sequence gets its initial manifest")
	bench.recorder.cancel("next")
	var taken := first.get_base_dir() + "/" + first.get_file().left(-3) + "002"
	var collision := FileAccess.open(taken, FileAccess.WRITE)
	if collision:
		collision.close()
	var after_the_file := bench.start("after the file")
	t.check(after_the_file != "" and after_the_file != taken
				and DirAccess.dir_exists_absolute(after_the_file) and FileAccess.file_exists(taken),
			"an existing file also cannot become a burst directory")
	bench.recorder.cancel("next")
	# A second recorder counts its folders from the start again, at the same moment on the clock.
	var again := BurstRecorder.new(bench.screen, bench.clock, bench.noted)
	t.check(again.start(bench.root, "second recorder")
				and DirAccess.get_directories_at(bench.root).size() == 3
				and bench.manifest(first).get("context") == "first"
				and bench.manifest(after_the_file).get("context") == "after the file",
			"a previous sequence directory is never selected again")
	again.cancel("test over")
	bench.close()

	var timed := Bench.new("timing")
	var folder := timed.start("timing")
	timed.clock.advance(0.04)
	timed.draw()
	timed.clock.advance(0.13)
	timed.draw()
	timed.clock.advance(BurstRecorder.DURATION_SECONDS)
	var manifest := timed.manifest(folder)
	t.check(not manifest.is_empty(), "the manifest is valid JSON")
	t.check(manifest.get("schema_version") == 1 and not manifest.has("version"),
			"the manifest uses the converter's one-version schema")
	var frames: Array = manifest.get("frames", [])
	t.check(frames.size() == 2 and frames[0]["file"] == "frame-0001.png"
				and frames[1]["file"] == "frame-0002.png"
				and FileAccess.file_exists("%s/frame-0002.png" % folder)
				and float(frames[0]["elapsed_seconds"]) < float(frames[1]["elapsed_seconds"]),
			"manifest frames remain numbered and strictly ordered by their capture timestamps")
	t.check(frames.size() == 2
				and float(manifest.get("duration_seconds", 0.0)) > float(frames[1]["elapsed_seconds"])
				and manifest.get("status") == "complete" and manifest.get("reason") == "duration",
			"the actual burst duration is after its final readable frame")
	timed.close()

	t.check(_frames_until_the_end(2.9) == ["frame_cap", 36],
			"the frame cap ends a sequence at its thirty-sixth frame, and a thirty-seventh is never drawn in")
	t.check(_frames_until_the_end(BurstRecorder.DURATION_SECONDS)[0] == "duration",
			"at both bounds at once, the duration is what ended it")

## A sequence whose pacing never holds it back draws thirty-six frames with the clock still, then
## waits out its last pacing wait with the clock moved to `seconds` after the start, the deadline
## left pending; and one more frame is drawn. The manifest's reason and frame count are returned.
func _frames_until_the_end(seconds: float) -> Array:
	var bench := Bench.new("cap")
	var folder := bench.start("cap")
	var deadline: Array[Wait] = [bench.clock.waits[0]]
	for i in BurstRecorder.MAX_FRAMES:
		bench.draw()
		if i < BurstRecorder.MAX_FRAMES - 1:
			bench.clock.end_waits_but(deadline)
	bench.clock.now += roundi(seconds * 1000000.0)
	bench.clock.end_waits_but(deadline)
	bench.draw()
	var manifest := bench.manifest(folder)
	var drawn_in := (manifest.get("frames", []) as Array).size()
	if FileAccess.file_exists("%s/frame-0037.png" % folder):
		drawn_in += 1
	var found := [manifest.get("reason"), drawn_in]
	bench.close()
	return found

## A day or a run ending cancels the sequence; a deadline with nothing drawn cancels it too. And a
## deadline or a frame wait left over from a sequence that has ended does nothing to the next one.
func _test_cancellation_and_stale_callbacks_cannot_cross_sequences(t) -> void:
	var bench := Bench.new("lifecycle")
	var cut := bench.start("cut short")
	bench.clock.advance(0.1)
	bench.draw()
	bench.clock.advance(0.1)
	bench.recorder.cancel("day ended")
	t.check(not bench.recorder.is_active(), "ending a day cancels its active burst")
	var cancelled := bench.manifest(cut)
	t.check(cancelled.get("status") == "cancelled" and cancelled.get("reason") == "day ended"
				and (cancelled.get("frames", []) as Array).size() == 1,
			"a cancelled sequence records why its partial frames ended")

	var empty := bench.start("never drawn")
	bench.clock.advance(BurstRecorder.DURATION_SECONDS)
	var empty_deadline := bench.manifest(empty)
	t.check(empty_deadline.get("status") == "cancelled"
				and empty_deadline.get("reason") == "no frames captured before deadline",
			"a renderer that never draws leaves a cancelled, not complete, zero-frame sequence")

	# The old sequence is waiting on a frame when it is cut; its deadline is still pending when the
	# new one, started a second later, is drawn.
	var old := bench.start("old")
	bench.recorder.cancel("day ended")
	bench.clock.advance(1.0)
	var newer := bench.start("newer")
	bench.clock.advance(BurstRecorder.DURATION_SECONDS - 0.5)
	bench.draw()
	var current := bench.manifest(newer)
	t.check(bench.recorder.is_active() and current.get("status") == "active"
				and (current.get("frames", []) as Array).size() == 1
				and bench.manifest(old).get("reason") == "day ended"
				and (bench.manifest(old).get("frames", [1]) as Array).is_empty(),
			"an old timer or post-draw coroutine cannot finalize a newer sequence")
	bench.close()

## A manifest that can no longer be written ends the sequence, and the log never calls it a
## finished burst: blocked before a frame is drawn, and blocked before the deadline closes it.
func _test_metadata_write_failure_stops_without_claiming_success(t) -> void:
	var bench := Bench.new("write-failure")
	_block_the_manifest(bench.start("blocked on a frame"))
	bench.draw()
	t.check(not bench.recorder.is_active()
				and bench.lines.back().contains("burst abandoned: metadata write failed"),
			"a manifest path occupied by a directory reports its write failure")
	_block_the_manifest(bench.start("blocked at the deadline"))
	bench.clock.advance(BurstRecorder.DURATION_SECONDS)
	t.check(not bench.recorder.is_active(), "a metadata failure always terminates the recorder")
	t.check(bench.lines.back().contains("burst abandoned")
				and _count(bench.lines, "burst complete") == 0,
			"a failed final write is never logged as a successful burst")
	bench.close()

## Puts a directory where the manifest in `folder` is written.
func _block_the_manifest(folder: String) -> void:
	DirAccess.remove_absolute("%s/burst.json" % folder)
	DirAccess.make_dir_recursive_absolute("%s/burst.json" % folder)

func _count(lines: Array, text: String) -> int:
	return lines.filter(func(line: String) -> bool: return line.contains(text)).size()

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
