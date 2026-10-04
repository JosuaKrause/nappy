extends RefCounted
## The per-system frame record: every microsecond of a frame lands in exactly one bucket, so the
## buckets add up to the frame; a frame that ran into the next refresh is marked; the readout names
## the last slow frame's three largest costs; and the flag and its page word open only where the
## rest of the `?debug=1` bundle does, keeping the run off the save.

func run(t) -> void:
	_test_a_frame_adds_up(t)
	_test_slow_frames_are_marked(t)
	_test_frames_outside_play_are_timed_but_not_kept(t)
	_test_a_headless_frame_draws_nothing(t)
	_test_the_ring_keeps_the_latest_frames(t)
	_test_top_costs_order_and_leave_out_the_wait(t)
	_test_the_readout_line(t)
	_test_the_report_round_trips(t)
	_test_the_static_switch_charges_the_ledger(t)
	_test_the_flag_and_its_page_word(t)

## One frame driven through every phase, with a timed system nested inside another: the inner
## one is charged to itself alone, and the nine buckets sum to the frame's length exactly.
func _test_a_frame_adds_up(t) -> void:
	var ledger := FrameLedger.new(8, 25000)
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
		FrameRecord.DRAW: 1000, FrameRecord.WAIT: 13000, FrameRecord.INFLUENCE: 0,
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
	var ledger := FrameLedger.new(8, 25000)
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
	var ledger := FrameLedger.new(8, 25000)
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
	var ledger := FrameLedger.new(8, 25000)
	ledger.process_start(0)
	ledger.keep = true
	ledger.process_end(3000)
	ledger.process_start(16000)
	var row: PackedInt64Array = ledger.rows()[0]
	t.check(row[FrameLedger.FIRST_BUCKET + FrameRecord.DRAW] == 13000
			and row[FrameLedger.FIRST_BUCKET + FrameRecord.WAIT] == 0
			and row[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWN] == 0,
			"without a draw callback the post-process span is draw, and drawn is 0")

func _test_the_ring_keeps_the_latest_frames(t) -> void:
	var ledger := FrameLedger.new(2, 25000)
	_drive(ledger, 0, 10000, FrameRecord.CROWD, 1000)
	_drive(ledger, 10000, 11000, FrameRecord.CROWD, 1000)
	_drive(ledger, 21000, 12000, FrameRecord.CROWD, 1000)
	ledger.process_start(33000)
	var rows := ledger.rows()
	t.check(ledger._rows.size() == 2 * FrameLedger.WIDTH, "a full ring never grows")
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
	t.check(top.size() == 3 and top[0][0] == "crowd" and top[1][0] == "events"
			and top[2][0] == "draw", "the three largest costs, largest first, without the wait")

func _test_the_readout_line(t) -> void:
	var ledger := FrameLedger.new(8, 25000)
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
	var rest := line.find("process_rest 9.0")
	t.check(line.begins_with("slow  40.0 ms") and crowd > 0 and draw > crowd and rest > draw
			and not line.contains("scenery"),
			"the readout names the slow frame and its three largest costs in order (%s)" % line)

func _test_the_report_round_trips(t) -> void:
	var ledger := FrameLedger.new(8, 25000)
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
func _test_the_static_switch_charges_the_ledger(t) -> void:
	var was_on := FrameRecord.on
	var was := FrameRecord.ledger
	var ledger := FrameLedger.new(8, 25000)
	FrameRecord.start(ledger)
	ledger.process_start(Time.get_ticks_usec())
	var outer := FrameRecord.enter(FrameRecord.INFLUENCE)
	t.check(outer == FrameRecord.PROCESS_REST and ledger._current == FrameRecord.INFLUENCE,
			"enter answers the bucket that was running and starts its own")
	FrameRecord.leave(outer)
	t.check(ledger._current == FrameRecord.PROCESS_REST, "leave goes back to it")
	t.check(FrameRecorder.calibrate() >= 0.0 and FrameRecord.ledger == ledger,
			"calibrating the timer's cost leaves the live record in place")
	FrameRecord.stop()
	FrameRecord.ledger = was
	FrameRecord.on = was_on

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

## One kept frame starting at `start` and lasting `length`, of which `spent` went to `bucket`.
func _drive(ledger: FrameLedger, start: int, length: int, bucket: int, spent: int) -> void:
	ledger.process_start(start)
	var outer := ledger.enter(bucket, start + 100)
	ledger.switch_to(outer, start + 100 + spent)
	ledger.keep = true
	ledger.process_end(start + 200 + spent)
