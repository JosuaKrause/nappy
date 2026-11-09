extends RefCounted
## **The frame recorder wired into a real boot of `main`**, which is the combination this suite is
## for: the sitting's record handed to every timed system, the recorder's markers first and last in
## a tree no other node is prioritised past, a paused frame timed but not kept, the crowd's tick timed
## once on real physics ticks, and a desktop save and leaving the tree writing the file. Each is a fact
## about `main` composing the recorder with the world it times, and no fake of the world shows
## whether the wiring reaches it; the record, ledger and recorder in themselves are
## `tests/test_frame_record.gd`'s.

const Boot := preload("res://tests/booted_main.gd")
const UI := preload("res://tests/ui_screens.gd")
## How long a test holds the clock inside a bucket it wants to read back, in microseconds: long
## enough that the bucket's time cannot read as zero, whatever the timer's resolution.
const SPENT_US := 2000
## The save the real boot is handed, at a scratch path, so nothing it drives reaches the player's.
const _SCRATCH_SAVE := "user://test_frame_record_scratch.json"
## The folder the boot's recorder is handed to write its record in on the desktop.
const _SCRATCH_RECORDS := "user://test_frame_record_scratch_records"

func run(t) -> void:
	await _test_the_recorder_in_a_real_main(t)

## The recorder in a real boot of `main` (`tests/booted_main.gd`) under `--frame-record`: `main`
## hands the sitting's record to every timed system and sets the recorder up from it, its markers
## run first and last because no other node in the tree is prioritised past them, a paused frame is
## timed but not kept, a played one is kept with its world counters, the readout carries its line,
## the crowd's tick is timed once on real physics ticks, a desktop save writes the file the sitting
## keeps, and leaving the tree switches the timing off — which is what keeps the escape, which
## builds no recorder, from paying for it — and writes the record.
##
## The sitting is the test's own, parked in a home of its own (`Boot.home_playing()`) with a run of
## its own, which `main` plays and the day counter reads. Its record was started and then stopped
## before the boot, the switch a held restart leaves off with its ledger kept, so `main._ready()`
## sets the recorder up from it before `_start()` makes the day's agents, as in the game. The
## file a desktop save writes is a scratch path the sitting already keeps, so nothing reaches the
## player's own records.
func _test_the_recorder_in_a_real_main(t) -> void:
	var restarted := FrameLedger.new(FrameLedger.CAPACITY)
	var record := FrameRecord.new()
	record.start(restarted)
	record.stop()
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var sitting: Sitting = home.get_node(Sitting.NODE_NAME)
	sitting.use_frame_timing(record)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, Boot.config(["--frame-record"]),
			func(unbooted: Node) -> void:
				unbooted.use_sitting_home(home)
				unbooted.use_frame_records_dir(_SCRATCH_RECORDS))
	var main := booted.main
	await Boot.press_title(t, main)
	var city := Boot.city(main)
	var edge: DangerEdge = main.get_node("DangerEdge/Edge")
	var halo: ExcitementHalo = main.get_node("ExcitementHalo")
	t.check(city.frame_timing == record and city.scenery.timing == record
			and city.events.timing == record and Boot.baby(main).timing == record
			and edge.timing == record and halo.timing == record,
			"main hands the sitting's record to every system that is timed")
	var recorder: FrameRecorder = main.get_node("FrameRecorder")
	t.check(record.is_on() and record.frame_ledger() == restarted,
			"setting up the recorder switches the timing on, keeping the record a restart left")
	await t.get_tree().process_frame
	Boot.player(main).queue_redraw()
	# The redraw lands in one of the next stored frames, not necessarily the last: some frames
	# hold no physics tick, and her stroller draws in the one that does.
	var drawn_in := _rows_over(restarted, await _frames_counted(t, restarted, 3))
	var drew_her := false
	for row in drawn_in:
		drew_her = drew_her or row[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.PLAYER] >= 1
	t.check(drew_her and drawn_in.size() >= 2,
			"her stroller's drawn frame is counted by the recorder's listening")
	var end := recorder.get_node("ProcessEnd")
	var nodes := 0
	var first := true
	var last := true
	var stack: Array[Node] = [main]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		nodes += 1
		if node == recorder or node == end:
			continue
		first = first and node.process_priority > FrameRecorder.PRIORITY_FIRST \
				and node.process_physics_priority > FrameRecorder.PRIORITY_FIRST
		last = last and node.process_priority < FrameRecorder.PRIORITY_LAST
	t.check(nodes > 100, "the real tree was walked (%d nodes)" % nodes)
	t.check(first and last, "no node in the real tree is prioritised past the recorder's markers")
	t.check(recorder.process_mode == Node.PROCESS_MODE_ALWAYS
			and end.process_mode == Node.PROCESS_MODE_ALWAYS, "both markers run through a pause")
	# A frame is stored as the next one begins (its first physics tick or its process step, which
	# comes first depends on the frame's length), so a frame is read once the one after it has begun.
	var ledger := record.frame_ledger()
	t.get_tree().paused = true
	await UI.frames(t, 3)
	var kept := ledger.rows().size()
	t.check(not ledger.is_keeping(), "a paused frame is not kept")
	await UI.frames(t)
	t.check(ledger.rows().size() == kept, "and closing it stores nothing")
	t.get_tree().paused = false
	await UI.frames(t)
	t.check(ledger.rows().size() > kept, "a played frame is kept")
	var row: PackedInt64Array = ledger.rows().back()
	t.check(row[FrameLedger.FIRST_COUNTER + FrameLedger.CROWD_AGENTS] == city.crowd.agent_count()
			and row[FrameLedger.FIRST_COUNTER + FrameLedger.DAY] == run.header.day,
			"with the world's counters read at the end of its process step")
	t.check(await _the_readout_shows(t, main, recorder), "the readout carries the record's line")
	await _check_the_crowd_is_timed_once(t, city.crowd, record, ledger)
	record.start(ledger)
	var written := recorder.save()
	t.check(written == ProjectSettings.globalize_path(sitting.frame_record_file())
			and sitting.frame_record_file().begins_with(_SCRATCH_RECORDS + "/"),
			"a desktop save writes the file its sitting keeps, which outlives the recorder")
	t.check(recorder.save() == written, "and every later save rewrites the same file")
	DirAccess.remove_absolute(written)
	booted.free_all()
	t.check(not record.is_on(), "leaving the tree switches the timing off")
	t.check(FileAccess.get_file_as_string(sitting.frame_record_file()).contains("nappy-frame-record"),
			"and writes the record on the desktop as the scene exits")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sitting.frame_record_file()))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_SCRATCH_RECORDS))
	home.free()

## Whether the readout's label, which the readout fills a few times a second while the day is
## walked, shows the recorder's line, the one that begins `slow` (what follows it changes with each
## slow frame); the engine's time scale is raised so a refresh comes within a few frames, and put
## back.
func _the_readout_shows(t, main: Node, recorder: FrameRecorder) -> bool:
	var label: Label = main.get_node("CanvasLayer/Status")
	var scale := Engine.time_scale
	Engine.time_scale = 5.0
	var shown := false
	for i in 60:
		await t.get_tree().process_frame
		shown = recorder.readout_line().begins_with("slow ") and Array(label.text.split("\n")).any(
				func(line: String) -> bool: return line.begins_with("slow "))
		if shown:
			break
	Engine.time_scale = scale
	return shown

## The real day's crowd, ticked under the record on real physics ticks, one a frame: each tick steps
## every agent once (each clock moves by one tick, not two and not none), charged to `crowd` as one
## timed call, since an agent steps inside the crowd's tick and times nothing of its own, so no
## frame makes as many timed calls as there are agents; once the record stops, each tick still
## steps every agent once and the record is not touched again.
func _check_the_crowd_is_timed_once(t, crowd: Crowd, record: FrameRecord,
		ledger: FrameLedger) -> void:
	var steps := Engine.max_physics_steps_per_frame
	Engine.max_physics_steps_per_frame = 1
	var agents := crowd.agents()
	var once := not agents.is_empty() and await _one_tick_steps_each_once(t, crowd, agents)
	t.check(once, "the crowd's timed tick steps every agent once, not twice and not never (%d agents)"
			% agents.size())
	# A node of the test's own ticks after the crowd and spends a measured time: had the crowd left
	# its bucket open, that time would land in `crowd`; given back, it lands in the physics steps'
	# rest, so the stored frame it ran in must show at least the span measured, however slow the
	# frame was.
	var later := _LaterTick.new()
	later.process_physics_priority = 1000
	t.get_tree().root.add_child(later)
	var timed := _rows_over(ledger, await _frames_counted(t, ledger, 6))
	later.queue_free()
	var charged := false
	var fewest := true
	var given_back := true
	var matched := 0
	for row in timed:
		charged = charged or row[FrameLedger.FIRST_BUCKET + FrameRecord.CROWD] > 0
		fewest = fewest and row[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] < agents.size()
		for i in later.frames.size():
			if row[FrameLedger.FIRST_COUNTER + FrameLedger.PROCESS_FRAME] == later.frames[i]:
				matched += 1
				given_back = given_back and row[FrameLedger.FIRST_BUCKET + FrameRecord.PHYSICS_REST] \
						>= later.spent_us[i]
	t.check(not timed.is_empty() and fewest,
			"as one timed call for the whole crowd, never one an agent")
	t.check(charged, "charged to crowd")
	t.check(matched > 0 and given_back, "and the clock goes back to what was running (%d ticks matched to their frames)"
			% matched)
	record.stop()
	await t.get_tree().process_frame
	once = await _one_tick_steps_each_once(t, crowd, agents)
	var stopped := _rows_over(ledger, await _frames_counted(t, ledger, 4))
	var untouched := not stopped.is_empty()
	for row in stopped:
		untouched = untouched and row[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 0 \
				and row[FrameLedger.FIRST_BUCKET + FrameRecord.CROWD] == 0
	t.check(once and untouched,
			"once the record stops, the tick steps every agent once and times nothing")
	Engine.max_physics_steps_per_frame = steps

## A node whose physics tick runs after the crowd's and spends at least 10 `SPENT_US`, measured, each tick.
class _LaterTick extends Node:
	## The engine frame each tick ran in, and the time it spent, measured.
	var frames: Array[int] = []
	var spent_us: Array[int] = []

	func _physics_process(_delta: float) -> void:
		var from := Time.get_ticks_usec()
		OS.delay_usec(10 * SPENT_US)
		frames.append(Engine.get_process_frames())
		spent_us.append(Time.get_ticks_usec() - from)

## Whether one physics tick moves every agent's clock by exactly that tick's length.
func _one_tick_steps_each_once(t, crowd: Crowd, agents: Array[CrowdAgent]) -> bool:
	await t.get_tree().physics_frame
	var clocks: Array[float] = []
	for agent in agents:
		clocks.append(agent.excitement.clock())
	await t.get_tree().physics_frame
	var tick := crowd.get_physics_process_delta_time()
	for i in agents.size():
		if not is_equal_approx(agents[i].excitement.clock(), clocks[i] + tick):
			return false
	return true

## Lets `count` frames pass and be stored, and answers how many rows the ledger stored meanwhile.
func _frames_counted(t, ledger: FrameLedger, count: int) -> int:
	var before := ledger.rows().size()
	await UI.frames(t, count + 1)
	return ledger.rows().size() - before

## The last `count` rows the ledger stored.
func _rows_over(ledger: FrameLedger, count: int) -> Array[PackedInt64Array]:
	var rows := ledger.rows()
	var last: Array[PackedInt64Array] = []
	for i in range(maxi(0, rows.size() - count), rows.size()):
		last.append(rows[i])
	return last
