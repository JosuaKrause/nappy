extends RefCounted
## The per-system frame record: every microsecond of a frame lands in exactly one bucket, so the
## buckets add up to the frame; a frame that ran into the next refresh is marked; the readout names
## the last slow frame's three largest costs; and the flag and its page word open only where the
## rest of the `?debug=1` bundle does, keeping the run off the save.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const STEP := 1.0 / 60.0
## How long a test holds the clock inside a bucket it wants to read back, in microseconds: long
## enough that the bucket's time cannot read as zero, whatever the timer's resolution.
const SPENT_US := 2000
## The save the real boot is handed, at a scratch path, so nothing it drives reaches the player's.
const _SCRATCH_SAVE := "user://test_frame_record_scratch.json"

func run(t) -> void:
	t.gives_back_observers()
	_test_a_frame_adds_up(t)
	_test_slow_frames_are_marked(t)
	_test_frames_outside_play_are_timed_but_not_kept(t)
	_test_a_headless_frame_draws_nothing(t)
	_test_draw_splits_at_the_renderers_pre_draw(t)
	_test_the_ring_keeps_the_latest_frames(t)
	_test_top_costs_order_and_leave_out_the_wait(t)
	_test_the_readout_line(t)
	_test_the_view_size(t)
	_test_the_environment_carries_the_view(t)
	_test_the_report_round_trips(t)
	_test_the_record_charges_its_ledger(t)
	_test_draws_are_counted_by_listening(t)
	_test_the_flag_and_its_page_word(t)
	_test_the_deferred_scenery_window(t)
	_test_slow_frames_outside_callbacks_and_with_scenery(t)
	_test_the_clock_resolution(t)
	_test_the_recorder_in_a_real_main(t)
	_test_a_timed_body_runs_once(t)

## One frame driven through every phase, with a timed system nested inside another: the inner
## one is charged to itself alone, and the ten buckets sum to the frame's length exactly.
func _test_a_frame_adds_up(t) -> void:
	var ledger := FrameLedger.new(8, 16667)
	ledger.physics_step(1000)
	var outer := ledger.enter(FrameRecord.CROWD, 1100)
	ledger.switch_to(outer, 1600)
	ledger.process_start(2000)
	var before_scenery := ledger.enter(FrameRecord.SCENERY, 2100)
	var before_events := ledger.enter(FrameRecord.EVENTS, 2200)
	ledger.switch_to(before_events, 2300)
	ledger.switch_to(before_scenery, 2900)
	ledger.keep = true
	ledger.process_end(3000)
	ledger.add(FrameLedger.DRAWS_CROWD, 2)
	ledger.pre_draw(3500)
	ledger.drawn(4000)
	ledger.physics_step(17000)
	var rows := ledger.rows()
	t.check(rows.size() == 1, "a kept frame closes when the next one begins")
	var row: PackedInt64Array = rows[0]
	t.check(row.size() == FrameLedger.columns().size(), "a row has one value per column")
	t.check(row[FrameLedger.START] == 1000 and row[FrameLedger.FRAME] == 16000,
			"a frame runs from its first callback to the next frame's first callback")
	var expected := {FrameRecord.PHYSICS_REST: 500, FrameRecord.CROWD: 500,
		FrameRecord.PROCESS_REST: 200, FrameRecord.SCENERY: 700, FrameRecord.EVENTS: 100,
		FrameRecord.DRAW: 500, FrameRecord.RENDER: 500, FrameRecord.WAIT: 13000, FrameRecord.INFLUENCE: 0,
		FrameRecord.CUES: 0}
	var total := 0
	for bucket: int in expected:
		var spent := row[FrameLedger.FIRST_BUCKET + bucket]
		total += spent
		t.check(spent == expected[bucket], "%s holds %dus of the frame (got %d)"
				% [FrameRecord.BUCKET_NAMES[bucket], expected[bucket], spent])
	t.check(total == row[FrameLedger.FRAME], "the buckets add up to the frame exactly")
	var counters := FrameLedger.FIRST_COUNTER
	t.check(row[counters + FrameLedger.PHYSICS_STEPS] == 1
			and row[counters + FrameLedger.TIMER_CALLS] == 3
			and row[counters + FrameLedger.DRAWN] == 1,
			"the frame counts its physics steps, its timed entry points and its draw")
	t.check(row[FrameLedger.SLOW] == 0, "a frame inside its budget is not slow")

func _test_slow_frames_are_marked(t) -> void:
	var ledger := FrameLedger.new(8, 16667)
	_drive(ledger, 0, 16000, FrameRecord.CROWD, 2000)
	_drive(ledger, 16000, 40000, FrameRecord.SCENERY, 20000)
	_drive(ledger, 56000, 25000, FrameRecord.CROWD, 1000)
	ledger.process_start(81000)
	var rows := ledger.rows()
	t.check(rows.size() == 3, "three kept frames")
	t.check(rows[0][FrameLedger.SLOW] == 0 and rows[1][FrameLedger.SLOW] == 1
			and rows[2][FrameLedger.SLOW] == 0,
			"only the frame past one and a half budgets is slow; one exactly at it is not")
	t.check(ledger.slow_frames == 1 and ledger.last_slow[FrameLedger.FRAME] == 40000,
			"the last slow frame is kept for the readout")

func _test_frames_outside_play_are_timed_but_not_kept(t) -> void:
	var ledger := FrameLedger.new(8, 16667)
	ledger.process_start(0)
	ledger.keep = false
	ledger.process_end(5000)
	ledger.process_start(16000)
	ledger.keep = true
	ledger.process_end(20000)
	ledger.process_start(32000)
	var rows := ledger.rows()
	t.check(rows.size() == 1 and rows[0][FrameLedger.START] == 16000
			and rows[0][FrameLedger.FRAME] == 16000,
			"a paused or title frame is not kept, and the next one is still its own length")

## A headless run has no post-draw callback: the span after process is all `draw`, and the row
## says it drew nothing.
func _test_a_headless_frame_draws_nothing(t) -> void:
	var ledger := FrameLedger.new(8, 16667)
	ledger.process_start(0)
	ledger.keep = true
	ledger.process_end(3000)
	ledger.process_start(16000)
	var row: PackedInt64Array = ledger.rows()[0]
	t.check(row[FrameLedger.FIRST_BUCKET + FrameRecord.DRAW] == 13000
			and row[FrameLedger.FIRST_BUCKET + FrameRecord.WAIT] == 0
			and row[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWN] == 0,
			"without a draw callback the post-process span is draw, and drawn is 0")

## `draw` ends at the renderer's pre-draw callback and `render` runs to its post-draw one, so the
## two together are what `draw` was before the split; the game's own `_draw()` calls are counted by
## kind through the static switch, only while it is on, and a counter starts every frame at 0.
func _test_draw_splits_at_the_renderers_pre_draw(t) -> void:
	var record := FrameRecord.new()
	var ledger := FrameLedger.new(8, 16667)
	record.start(ledger)
	ledger.process_start(0)
	ledger.keep = true
	ledger.process_end(1000)
	record.drew(FrameTiming.Draw.SCENERY)
	record.drew(FrameTiming.Draw.SCENERY)
	record.drew(FrameTiming.Draw.HALOS)
	ledger.pre_draw(2500)
	ledger.drawn(6000)
	ledger.process_start(16000)
	ledger.keep = true
	ledger.process_end(17000)
	ledger.process_start(32000)
	var first: PackedInt64Array = ledger.rows()[0]
	var second: PackedInt64Array = ledger.rows()[1]
	t.check(first[FrameLedger.FIRST_BUCKET + FrameRecord.DRAW] == 1500
			and first[FrameLedger.FIRST_BUCKET + FrameRecord.RENDER] == 3500,
			"draw runs to the pre-draw callback and render from it to the post-draw one")
	t.check(first[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_SCENERY] == 2
			and first[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_HALOS] == 1
			and first[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_CROWD] == 0,
			"_draw() calls are counted by kind")
	t.check(second[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_SCENERY] == 0
			and second[FrameLedger.FIRST_BUCKET + FrameRecord.RENDER] == 0,
			"the next frame starts at zero, and a frame with no renderer has no render")

func _test_the_ring_keeps_the_latest_frames(t) -> void:
	var ledger := FrameLedger.new(2, 16667)
	_drive(ledger, 0, 10000, FrameRecord.CROWD, 1000)
	_drive(ledger, 10000, 11000, FrameRecord.CROWD, 1000)
	_drive(ledger, 21000, 12000, FrameRecord.CROWD, 1000)
	ledger.process_start(33000)
	var rows := ledger.rows()
	var long := FrameLedger.new(2, 16667)
	for i in 40:
		_drive(long, i * 20000, 10000, FrameRecord.CROWD, 1000)
	long.process_start(40 * 20000)
	t.check(long.rows().size() == 2 and long.overwritten == 38,
			"a full ring never grows: forty frames through two cells keep two and count thirty-eight over")
	t.check(rows.size() == 2 and ledger.overwritten == 1
			and rows[0][FrameLedger.START] == 10000 and rows[1][FrameLedger.START] == 21000,
			"a full ring keeps the latest frames, oldest first, and counts what it overwrote")

func _test_top_costs_order_and_leave_out_the_wait(t) -> void:
	var row := PackedInt64Array()
	row.resize(FrameLedger.WIDTH)
	row[FrameLedger.FIRST_BUCKET + FrameRecord.CROWD] = 9000
	row[FrameLedger.FIRST_BUCKET + FrameRecord.EVENTS] = 7000
	row[FrameLedger.FIRST_BUCKET + FrameRecord.DRAW] = 5000
	row[FrameLedger.FIRST_BUCKET + FrameRecord.SCENERY] = 2000
	row[FrameLedger.FIRST_BUCKET + FrameRecord.WAIT] = 20000
	var top := FrameLedger.top_costs(row)
	t.check(top.size() == 3 and top[0][0] == FrameRecord.CROWD and top[1][0] == FrameRecord.EVENTS
			and top[2][0] == FrameRecord.DRAW,
			"the three largest costs, largest first, without the wait")

func _test_the_readout_line(t) -> void:
	var ledger := FrameLedger.new(8, 16667)
	t.check(ledger.readout_line().contains("none yet"), "no slow frame yet says so")
	ledger.process_start(0)
	ledger.enter(FrameRecord.CROWD, 1000)
	ledger.switch_to(FrameRecord.SCENERY, 13000)
	ledger.switch_to(FrameRecord.CUES, 20000)
	ledger.switch_to(FrameRecord.PROCESS_REST, 21000)
	ledger.keep = true
	ledger.process_end(29000)
	ledger.process_start(40000)
	var line := ledger.readout_line()
	var crowd := line.find("crowd 12.0")
	var draw := line.find("draw 11.0")
	var rest := line.find("proc 9.0")
	t.check(line.begins_with("slow 40.0/40.0 ms") and crowd > 0 and draw > crowd
			and rest > draw and not line.contains("scenery"),
			"the readout names the slow frame, its work and its three largest costs in order (%s)"
			% line)
	t.check(FrameRecorder.fits_the_readout(line), "and it fits the readout's width (%s)" % line)
	# Three-digit costs under the longest short names: the line drops to the costs that fit.
	var wide := FrameLedger.new(8, 16667)
	wide.process_start(0)
	wide.enter(FrameRecord.SCENERY, 100)
	wide.switch_to(FrameRecord.EVENTS, 300100)
	wide.switch_to(FrameRecord.CROWD, 500100)
	wide.switch_to(FrameRecord.PROCESS_REST, 650100)
	wide.keep = true
	wide.process_end(650200)
	wide.process_start(650300)
	var squeezed := wide.readout_line(FrameRecorder.fits_the_readout)
	t.check(FrameRecorder.fits_the_readout(squeezed) and squeezed.contains("scenery 300.0")
			and squeezed.contains("events 200.0"),
			"a line too wide for three costs keeps the largest ones that fit (%s)" % squeezed)

func _test_the_report_round_trips(t) -> void:
	var ledger := FrameLedger.new(8, 16667)
	_drive(ledger, 0, 16000, FrameRecord.CROWD, 2000)
	_drive(ledger, 16000, 40000, FrameRecord.SCENERY, 20000)
	ledger.process_start(56000)
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(ledger.report()))
	t.check(decoded.columns.size() == FrameLedger.WIDTH and decoded.rows.size() == 2,
			"the file names every column and carries every kept frame")
	t.check(decoded.summary.slow_frames == 1
			and decoded.summary.largest_cost_in_slow_frames.get("scenery", 0) == 1,
			"the summary says which system was largest in the slow frames")

## The path the game's entry points take: `enter()` charges the ledger `start()` installed, and
## `leave()` goes back to what was running.
func _test_the_record_charges_its_ledger(t) -> void:
	var record := FrameRecord.new()
	var ledger := FrameLedger.new(8, 16667)
	record.start(ledger)
	t.check(record.on, "a started record is on")
	ledger.process_start(Time.get_ticks_usec())
	var outer := record.enter(FrameRecord.INFLUENCE)
	OS.delay_usec(SPENT_US)
	t.check(outer == FrameRecord.PROCESS_REST
			and _row_so_far(ledger)[FrameLedger.FIRST_BUCKET + FrameRecord.INFLUENCE] >= SPENT_US,
			"enter answers the bucket that was running and starts its own")
	ledger.process_start(Time.get_ticks_usec())
	outer = record.enter(FrameRecord.INFLUENCE)
	record.leave(outer)
	OS.delay_usec(SPENT_US)
	var after_leaving := _row_so_far(ledger)
	t.check(after_leaving[FrameLedger.FIRST_BUCKET + FrameRecord.PROCESS_REST] >= SPENT_US,
			"leave goes back to it: the time after it is charged to the bucket that was running")
	t.check(FrameRecorder.calibrate() >= 0.0 and record.ledger == ledger,
			"calibrating the timer's cost leaves the live record in place")
	record.stop()
	t.check(not record.on and record.ledger == ledger, "stopping switches it off and keeps its ledger")
	var none := FrameTiming.new()
	t.check(not none.on and none.enter(FrameTiming.CROWD) == 0, "the null sink is off and charges nothing")
	none.leave(0)
	none.drew(FrameTiming.Draw.OTHER)
	none.scenery_job(FrameTiming.Job.GUARD)
	var kinds_line_up := true
	for kind: String in FrameTiming.Draw.keys():
		var fresh := FrameLedger.new(1)
		var each := FrameRecord.new()
		each.start(fresh)
		fresh.process_start(0)
		each.drew(FrameTiming.Draw[kind])
		kinds_line_up = kinds_line_up and _row_so_far(fresh)[FrameLedger.FIRST_COUNTER
				+ FrameLedger.COUNTER_NAMES.find("draws_" + kind.to_lower())] == 1
	for kind: String in FrameTiming.Job.keys():
		var fresh := FrameLedger.new(1)
		var each := FrameRecord.new()
		each.start(fresh)
		fresh.process_start(0)
		each.scenery_job(FrameTiming.Job[kind])
		var counter := "guard_preparations" if kind == "GUARD" else "jobs_" + kind.to_lower()
		kinds_line_up = kinds_line_up and _row_so_far(fresh)[FrameLedger.FIRST_COUNTER
				+ FrameLedger.COUNTER_NAMES.find(counter)] == 1
	t.check(kinds_line_up, "every draw and job kind lands on the counter of its own name")

## The recorder counts the nodes' own `_draw()` calls by listening to their `draw` signal: a node of
## a counted class is connected as it enters the tree, whichever class it is, and only a running
## record counts; a node that is not one of those (a label) is not connected.
func _test_draws_are_counted_by_listening(t) -> void:
	var record := FrameRecord.new()
	var ledger := FrameLedger.new(2)
	record.start(ledger)
	ledger.process_start(0)
	var recorder := FrameRecorder.new()
	recorder.save_on_exit = false
	t.add_child(recorder)
	var sitting := Sitting.new()
	sitting.frame_timing = record
	recorder.setup(func() -> bool: return false, null, null, null, null, sitting)
	var prop := Prop.new()
	t.add_child(prop)
	var label := Label.new()
	t.add_child(label)
	var chunk := Node2D.new()
	chunk.set_meta(FrameTiming.DRAW_KIND_META, FrameTiming.Draw.SCENERY)
	t.add_child(chunk)
	var marker := ClosureMarker.new()
	t.add_child(marker)
	prop.draw.emit()
	chunk.draw.emit()
	label.draw.emit()
	marker.draw.emit()
	var drawn := _row_so_far(ledger)
	var counters := FrameLedger.FIRST_COUNTER
	t.check(drawn[counters + FrameLedger.DRAWS_SCENERY] == 2 and drawn[counters + FrameLedger.DRAWS_OTHER] == 1
			and drawn[counters + FrameLedger.DRAWS_PLAYER] == 0,
			"a prop and a tagged canvas count as scenery, a marker as other, a label as nothing")
	t.remove_child(prop)
	t.add_child(prop)
	prop.draw.emit()
	t.check(_row_so_far(ledger)[counters + FrameLedger.DRAWS_SCENERY] == 1,
			"a node that re-enters the tree is counted once")
	record.on = false
	prop.draw.emit()
	t.check(_row_so_far(ledger)[counters + FrameLedger.DRAWS_SCENERY] == 0,
			"a record that is off counts nothing")
	var kinds := {Prop.new(): FrameTiming.Draw.SCENERY, SceneryLayer.new(): FrameTiming.Draw.SCENERY,
		SceneryWater.new(): FrameTiming.Draw.SCENERY, TrafficLight.new(): FrameTiming.Draw.OTHER,
		ParkFenceMarker.new(): FrameTiming.Draw.OTHER, MeterBar.new(): FrameTiming.Draw.OTHER,
		HomeArrow.new(): FrameTiming.Draw.OTHER, ModeButton.new(): FrameTiming.Draw.OTHER,
		DangerEdge.new(): FrameTiming.Draw.BADGES, Label.new(): -1, Node.new(): -1}
	for node: Node in kinds:
		t.check(FrameRecorder.draw_kind(node) == kinds[node],
				"%s is counted as kind %d" % [node.get_class(), kinds[node]])
		node.free()
	recorder.free()
	sitting.free()
	for node in [prop, label, chunk, marker]:
		node.free()

func _test_the_flag_and_its_page_word(t) -> void:
	var none := PackedStringArray()
	t.check(DevFlags._frame_record_for(PackedStringArray(["--frame-record"]), "", false),
			"the command line's --frame-record starts the record")
	t.check(DevFlags._frame_record_for(none, "?debug=1&framerecord=1", true),
			"?framerecord=1 starts it on a page whose bundle is open")
	t.check(not DevFlags._frame_record_for(none, "?framerecord=1", false),
			"a release page without ?debug=1 ignores ?framerecord=1")
	t.check(not DevFlags._frame_record_for(none, "?debug=1&framerecord=0", true)
			and not DevFlags._frame_record_for(none, "?debug=1", true),
			"only the value 1 asks for it, and ?debug=1 alone does not")
	t.check(DevFlags._web_debug_flag_used_in_query("?debug=1&framerecord=1"),
			"a page that records stays off the save, like the bundle's other words")

## The scenery queue's deferred window: what its update left to the engine's flush is charged to
## `scenery` and counted apart, and the frame still adds up.
func _test_the_deferred_scenery_window(t) -> void:
	var ledger := FrameLedger.new(8, 16667)
	ledger.process_start(0)
	var outer := ledger.enter(FrameRecord.SCENERY, 100)
	ledger.switch_to(outer, 600)
	ledger.keep = true
	ledger.process_end(1000)
	ledger.deferred_scenery_begins(1500)
	ledger.deferred_scenery_ends(2500)
	ledger.drawn(4000)
	ledger.process_start(17000)
	var row: PackedInt64Array = ledger.rows()[0]
	var total := 0
	for i in FrameRecord.BUCKET_NAMES.size():
		total += row[FrameLedger.FIRST_BUCKET + i]
	t.check(row[FrameLedger.FIRST_BUCKET + FrameRecord.SCENERY] == 1500
			and row[FrameLedger.FIRST_BUCKET + FrameRecord.DRAW] == 2000
			and row[FrameLedger.FIRST_COUNTER + FrameLedger.SCENERY_DEFERRED] == 1000,
			"the flush's scenery work is scenery's, counted apart, and the rest of drawing is draw's")
	t.check(total == row[FrameLedger.FRAME], "and the frame still adds up")

## A slow frame whose callbacks fit in one budget was held up outside them; and the summary splits
## the slow frames by whether the scenery queue ran a job in them.
func _test_slow_frames_outside_callbacks_and_with_scenery(t) -> void:
	var ledger := FrameLedger.new(8, 16667)
	ledger.process_start(0)
	ledger.keep = true
	ledger.process_end(2000)
	ledger.drawn(3000)
	ledger.process_start(40000)
	t.check(ledger.readout_line().ends_with("outside callbacks")
			and ledger.readout_line().begins_with("slow 40.0/3.0 ms"),
			"a slow frame that was mostly waiting says so (%s)" % ledger.readout_line())
	var outer := ledger.enter(FrameRecord.SCENERY, 40100)
	ledger.add(FrameLedger.JOBS_GROUND, 1)
	ledger.switch_to(outer, 70100)
	ledger.keep = true
	ledger.process_end(70200)
	_drive(ledger, 80000, 40000, FrameRecord.CROWD, 30000)
	ledger.process_start(120000)
	var summary: Dictionary = ledger.report().summary
	t.check(summary.largest_cost_in_slow_frames.get(FrameLedger.OUTSIDE_CALLBACKS, 0) == 1
			and summary.slow_frames_with_scenery_jobs == 1
			and summary.largest_cost_in_slow_frames_with_scenery_jobs.get("scenery", 0) == 1
			and summary.slow_frames_without_scenery_jobs == 2
			and summary.largest_cost_in_slow_frames_without_scenery_jobs.get("crowd", 0) == 1,
			"the summary names waiting frames apart and splits slow frames by scenery jobs")

func _test_the_clock_resolution(t) -> void:
	var step := FrameRecorder.clock_resolution()
	t.check(step >= 1 and step < 2000, "the clock's smallest step is measured (%dus)" % step)

## The recorder in a real boot of `main`: its markers run first and last because no other node in
## the tree is prioritised past them, a paused frame is timed but not kept, a played one is kept
## with its world counters, the readout carries its line, and leaving the tree switches the timing
## off — which is what keeps the escape, which builds no recorder, from paying for it. This
## suite is a plain function that lets no frame elapse, so the phases are driven by hand on the
## real tree's recorder, as `tests/test_camera_start.gd` drives its boot.
##
## The record is running before `main` is built, as it is in the game, where `main._ready()` sets
## the recorder up before `_start_day()` makes the day's agents, and the crowd's timed tick, which
## steps them, is checked on the real crowd (`_check_the_crowd_is_timed_once`).
## The recorder itself is then set up from a switch left off, the way a held restart leaves it,
## and handed a sitting of the test's own, which keeps the one file a desktop save writes.
func _test_the_recorder_in_a_real_main(t) -> void:
	var saved := _save_game_state()
	var restarted := FrameLedger.new(8)
	var record := FrameRecord.new()
	record.start(restarted)
	var sitting := Sitting.new()
	sitting.frame_timing = record
	var save := GameSave.new(_SCRATCH_SAVE)
	var main: Node2D = MAIN_SCENE.instantiate()
	main.use_sitting(sitting)
	main.use_save(save)
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(main._city.frame_timing == record and main._city.scenery.timing == record
			and main._city.events.timing == record and main._baby.timing == record
			and main._edge.timing == record and main._halo.timing == record,
			"main hands the sitting's record to every system that is timed")
	record.stop()
	var recorder := FrameRecorder.new()
	recorder.save_on_exit = false
	main.add_child(recorder)
	recorder.setup(main._flow.in_the_title, main._city, main._player, main._day, main._run, sitting)
	main._frame_recorder = recorder
	main._readout.watch_frames(recorder)
	t.check(record.on and record.ledger == recorder.ledger and recorder.ledger == restarted,
			"setting up the recorder switches the timing on, keeping the record a restart left")
	restarted.process_start(Time.get_ticks_usec())
	var drawn_before := _row_so_far(restarted)[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_PLAYER]
	main._player.draw.emit()
	t.check(_row_so_far(restarted)[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_PLAYER] == drawn_before + 1,
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
	var ledger := recorder.ledger
	var kept := ledger.count
	ledger.process_start(Time.get_ticks_usec())
	t.get_tree().paused = true
	recorder.at_process_end()
	t.check(not ledger.keep, "a paused frame is not kept")
	ledger.process_start(Time.get_ticks_usec())
	t.check(ledger.count == kept, "and closing it stores nothing")
	t.get_tree().paused = false
	recorder.at_process_end()
	ledger.process_start(Time.get_ticks_usec())
	t.check(ledger.count == kept + 1, "a played frame is kept")
	var row: PackedInt64Array = ledger.rows().back()
	t.check(row[FrameLedger.FIRST_COUNTER + FrameLedger.CROWD_AGENTS]
				== main._city.crowd.agent_count()
			and row[FrameLedger.FIRST_COUNTER + FrameLedger.DAY] == GameState.header.day,
			"with the world's counters read at the end of its process step")
	t.check(main._readout._frame_record_lines().size() == 1, "the readout carries the record's line")
	_check_the_crowd_is_timed_once(t, main._city.crowd, record)
	var written := recorder.save()
	t.check(sitting.frame_record_path.begins_with("user://frame-records/")
			and written == ProjectSettings.globalize_path(sitting.frame_record_path),
			"a desktop save chooses its file on the sitting, which outlives the recorder")
	t.check(recorder.save() == written, "and every later save rewrites the same file")
	DirAccess.remove_absolute(written)
	record.start(ledger)
	Telemetry.end_run()
	main.free()
	t.check(not record.on, "leaving the tree switches the timing off")
	sitting.free()
	save.free()
	_restore_game_state(saved)
	t.check(_save_game_state() == saved,
			"the suite leaves every field a real main's run writes as it found it")

## The real day's crowd, ticked under the record: its physics tick steps every agent once (each
## clock moves by one step, not two and not none) inside one timed call charged to `crowd`, since an
## agent steps inside the crowd's tick and times nothing of its own; once the record stops, the tick
## still steps every agent once and the record it ran under is not touched again.
func _check_the_crowd_is_timed_once(t, crowd: Crowd, record: FrameRecord) -> void:
	var agents := crowd.agents()
	var scratch := FrameLedger.new(4)
	record.start(scratch)
	scratch.process_start(Time.get_ticks_usec())
	var clocks: Array[float] = []
	for agent in agents:
		clocks.append(agent.excitement._clock)
	crowd._physics_process(STEP)
	var once := not agents.is_empty()
	for i in agents.size():
		once = once and is_equal_approx(agents[i].excitement._clock, clocks[i] + STEP)
	t.check(once, "the crowd's timed tick steps every agent once, not twice and not never (%d agents)"
			% agents.size())
	OS.delay_usec(SPENT_US)
	var row := _row_so_far(scratch)
	t.check(row[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 1,
			"as one timed call for the whole crowd (%d)"
			% row[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS])
	t.check(row[FrameLedger.FIRST_BUCKET + FrameRecord.CROWD] > 0
			and row[FrameLedger.FIRST_BUCKET + FrameRecord.PROCESS_REST] >= SPENT_US,
			"charged to crowd, and the clock goes back to what was running")
	record.stop()
	crowd._physics_process(STEP)
	once = true
	for i in agents.size():
		once = once and is_equal_approx(agents[i].excitement._clock, clocks[i] + 2.0 * STEP)
	var stopped := _row_so_far(scratch)
	t.check(once and stopped[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 0
			and stopped[FrameLedger.FIRST_BUCKET + FrameRecord.CROWD] == 0,
			"once the record stops, the tick steps every agent once and times nothing")

## A live event made with the record off is never timed, even once it is on; one made under it runs
## its drawn frame (its look's redraw) once a call, inside `events`, and once the record stops, it
## still redraws and the record it ran under is not touched again. Its step times nothing of its
## own: the manager's physics tick that runs it is timed.
func _test_a_timed_body_runs_once(t) -> void:
	var record := FrameRecord.new()
	var def := EventCatalogue.by_id("protest")
	var untimed_event := _event(t, def)
	var untimed_look := _BucketLook.watching(untimed_event)
	var scratch := FrameLedger.new(4)
	record.start(scratch)
	scratch.process_start(Time.get_ticks_usec())
	untimed_event._process(STEP)
	var untimed := _row_so_far(scratch)
	t.check(untimed[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 0 and untimed_look.redraws == 1,
			"an event handed no record is not timed while another is on")
	var event := _event(t, def)
	event.timing = record
	var look := _BucketLook.watching(event)
	event._process(STEP)
	OS.delay_usec(SPENT_US)
	var timed := _row_so_far(scratch)
	t.check(look.redraws == 1 and timed[FrameLedger.FIRST_BUCKET + FrameRecord.EVENTS] >= SPENT_US,
			"a timed event's drawn frame redraws once a call, inside the events bucket (%d redraws)"
			% look.redraws)
	t.check(timed[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 1
			and timed[FrameLedger.FIRST_BUCKET + FrameRecord.PROCESS_REST] >= SPENT_US,
			"as one timed call, and the clock goes back to what was running")
	# Past its telegraph, so its first step announces it, in whatever bucket was running: its step
	# times nothing itself, so the time spent in the announcement is the rest of the process's.
	event.age = def.telegraph_time + 0.01
	var age := event.age
	var slept := func(_instance: Variant) -> void: OS.delay_usec(SPENT_US)
	EventBus.event_activated.connect(slept)
	event.step(STEP)
	EventBus.event_activated.disconnect(slept)
	var stepped := _row_so_far(scratch)
	t.check(is_equal_approx(event.age, age + STEP)
			and stepped[FrameLedger.FIRST_BUCKET + FrameRecord.PROCESS_REST] >= SPENT_US
			and stepped[FrameLedger.FIRST_BUCKET + FrameRecord.EVENTS] < SPENT_US
			and stepped[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 0,
			"its step runs once a call and times nothing of its own")
	record.stop()
	event._process(STEP)
	var stopped := _row_so_far(scratch)
	t.check(look.redraws == 2
			and stopped[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 0
			and stopped[FrameLedger.FIRST_BUCKET + FrameRecord.EVENTS] == 0,
			"once the record stops, an event made under it redraws once and times nothing")
	untimed_event.free()
	event.free()

## A look that only counts how many times its event's drawn frame asked it to redraw.
## `watching()` lets the event's own look go first, so nothing it built is left over.
class _BucketLook extends EventLook:
	var redraws := 0

	static func watching(instance: EventInstance) -> _BucketLook:
		instance.look.release_nodes()
		var look := _BucketLook.new(instance)
		instance.look = look
		return look

	func redraw_if_the_picture_changed() -> bool:
		redraws += 1
		OS.delay_usec(SPENT_US)
		return false

## A live event standing alone, its process callback left to the test, as `tests/test_acts.gd`
## builds one.
func _event(t, def: EventDef) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)
	return instance

## Everything `GameState.start_run()` and the boot's `begin_day()` write: the save's own fields
## through `save_snapshot()` (the dawn photograph included), and beside them the ones the save
## file keeps out of that snapshot — `escape_section`, the posters, the fenced park and the alley
## tiles — so the next suite in the process finds the run it left. A field the save snapshot
## gains is covered by the closing equality check; one written outside it has to join the
## hand-listed set here, which that check cannot see.
func _save_game_state() -> Dictionary:
	return {
		"snapshot": GameState.save_snapshot(),
		"escape_section": GameState.facts.escape_section,
		"posters": GameState.posters.to_data(),
		"pelican": GameState.pelican.to_data(),
		"fenced_park": GameState.facts.fenced_park,
		"fenced_park_act": GameState.facts.fenced_park_act,
		"alley_tiles": GameState.facts.completed_resistance_alley_tiles.duplicate(),
	}

func _restore_game_state(saved: Dictionary) -> void:
	GameState.restore_snapshot(saved["snapshot"])
	GameState.facts.escape_section = saved["escape_section"]
	GameState.posters.restore(saved["posters"])
	GameState.pelican.restore(saved["pelican"])
	GameState.facts.fenced_park = saved["fenced_park"]
	GameState.facts.fenced_park_act = saved["fenced_park_act"]
	GameState.facts.completed_resistance_alley_tiles.assign(saved["alley_tiles"])

## The frame the ledger is in the middle of, closed the way the next frame's first callback closes
## it, as the row it writes — what the ledger records of a frame is its rows, and a frame a test is
## partway through is read by ending it. The next frame starts at once, counters at zero.
func _row_so_far(ledger: FrameLedger) -> PackedInt64Array:
	ledger.keep = true
	var at := Time.get_ticks_usec()
	ledger.process_end(at)
	ledger.process_start(at + 1)
	var rows := ledger.rows()
	return rows[rows.size() - 1]

## One kept frame starting at `start` and lasting `length`, of which `spent` went to `bucket`.
func _drive(ledger: FrameLedger, start: int, length: int, bucket: int, spent: int) -> void:
	ledger.process_start(start)
	var outer := ledger.enter(bucket, start + 100)
	ledger.switch_to(outer, start + 100 + spent)
	ledger.keep = true
	ledger.process_end(start + 200 + spent)


func _test_the_view_size(t) -> void:
	var view := FrameRecorder.view_size()
	for key in ["window_width", "window_height", "device_pixel_ratio", "drawn_width", "drawn_height"]:
		# A headless window reports 0 by 0, so only the keys and the ratio are pinned.
		t.check(view.has(key), "the view size carries %s" % key)
	t.check(view["device_pixel_ratio"] > 0.0, "the ratio is never 0")
	var lines := FrameRecorder.view_lines()
	t.check(lines.size() == 2 and lines[0].begins_with("window") and lines[1].begins_with("drawn"),
			"the readout says the window and what is drawn")
	for line in lines:
		t.check(FrameRecorder.fits_the_readout(line), "the line fits the readout: %s" % line)

## The record's environment carries the pixels the page draws, as the file a phone hands over.
func _test_the_environment_carries_the_view(t) -> void:
	var recorder := FrameRecorder.new()
	recorder.save_on_exit = false
	t.add_child(recorder)
	var sitting := Sitting.new()
	sitting.frame_timing = FrameRecord.new()
	recorder.setup(func() -> bool: return false, null, null, null, GameState, sitting)
	var environment: Dictionary = JSON.parse_string(recorder.report_text())["environment"]
	for key in ["window_width", "window_height", "device_pixel_ratio", "drawn_width", "drawn_height"]:
		t.check(environment.has(key), "the record's environment carries %s" % key)
	recorder.free()
	sitting.free()
