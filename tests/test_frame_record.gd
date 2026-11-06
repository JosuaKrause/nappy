extends RefCounted
## The per-system frame record: every microsecond of a frame lands in exactly one bucket, so the
## buckets add up to the frame; a frame that ran into the next refresh is marked; the readout names
## the last slow frame's three largest costs; and the flag and its page word open only where the
## rest of the `?debug=1` bundle does, keeping the run off the save.

const Boot := preload("res://tests/booted_main.gd")
const UI := preload("res://tests/ui_screens.gd")
const STEP := 1.0 / 60.0
## How long a test holds the clock inside a bucket it wants to read back, in microseconds: long
## enough that the bucket's time cannot read as zero, whatever the timer's resolution.
const SPENT_US := 2000
## The save the real boot is handed, at a scratch path, so nothing it drives reaches the player's.
const _SCRATCH_SAVE := "user://test_frame_record_scratch.json"
## The folder the boot's recorder is handed to write its record in on the desktop.
const _SCRATCH_RECORDS := "user://test_frame_record_scratch_records"
## The folder the other recorders of this suite are handed, saved or on leaving the tree.
const _SCRATCH_RECORDERS := "user://test_frame_record_scratch_recorders"

func run(t) -> void:
	t.gives_back_observers()
	_test_a_frame_adds_up(t)
	_test_slow_frames_are_marked(t)
	_test_frames_outside_play_are_timed_but_not_kept(t)
	_test_a_headless_frame_draws_nothing(t)
	_test_draw_splits_at_the_renderers_pre_draw(t)
	_test_the_ring_keeps_the_latest_frames(t)
	_test_the_readout_line(t)
	_test_the_readout_says_the_view(t)
	_test_the_environment_carries_the_view_and_the_clock(t)
	_test_the_report_round_trips(t)
	_test_the_record_charges_its_ledger(t)
	_test_draws_are_counted_by_listening(t)
	_test_the_flag_and_its_page_word(t)
	_test_the_deferred_scenery_window(t)
	_test_slow_frames_outside_callbacks_and_with_scenery(t)
	await _test_the_recorder_in_a_real_main(t)
	await _test_a_timed_body_runs_once(t)

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
	t.check(ledger.report().slow_frames_ever == 1 and ledger.readout_line().begins_with("slow 40.0/"),
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
	t.check(first[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.SCENERY] == 2
			and first[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.HALOS] == 1
			and first[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_CROWD] == 0,
			"_draw() calls are counted by kind")
	t.check(second[FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.SCENERY] == 0
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
	t.check(long.rows().size() == 2 and long.report().overwritten == 38,
			"a full ring never grows: forty frames through two cells keep two and count thirty-eight over")
	t.check(rows.size() == 2 and ledger.report().overwritten == 1
			and rows[0][FrameLedger.START] == 10000 and rows[1][FrameLedger.START] == 21000,
			"a full ring keeps the latest frames, oldest first, and counts what it overwrote")

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
	t.check(_fits_the_readout(line), "and it fits the readout's width (%s)" % line)
	# The wait is not a cost: a slow frame that mostly waited names the three largest of what it did.
	var waited := FrameLedger.new(8, 16667)
	waited.process_start(0)
	waited.enter(FrameRecord.CROWD, 100)
	waited.switch_to(FrameRecord.EVENTS, 9100)
	waited.switch_to(FrameRecord.DRAW, 16100)
	waited.switch_to(FrameRecord.SCENERY, 21100)
	waited.switch_to(FrameRecord.PROCESS_REST, 23100)
	waited.keep = true
	waited.process_end(23200)
	waited.pre_draw(23300)
	waited.drawn(23400)
	waited.process_start(60000)
	var waiting_line := waited.readout_line()
	t.check(waiting_line.contains("crowd 9.0") and waiting_line.contains("events 7.0")
			and waiting_line.contains("draw 5.") and not waiting_line.contains("scenery")
			and not waiting_line.contains("wait"),
			"and the three largest costs leave the wait out (%s)" % waiting_line)
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
	var wide_record := FrameRecord.new()
	wide_record.start(wide)
	var rig := _rig(t, wide_record)
	var squeezed := rig.recorder.readout_line()
	t.check(_fits_the_readout(squeezed) and squeezed.contains("scenery 300.0")
			and squeezed.contains("events 200.0"),
			"a line too wide for three costs keeps the largest ones that fit (%s)" % squeezed)
	rig.free_all()

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
	var rig := _rig(t, record)
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
	t.check(drawn[counters + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.SCENERY] == 2 and drawn[counters + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.OTHER] == 1
			and drawn[counters + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.PLAYER] == 0,
			"a prop and a tagged canvas count as scenery, a marker as other, a label as nothing")
	t.remove_child(prop)
	t.add_child(prop)
	prop.draw.emit()
	t.check(_row_so_far(ledger)[counters + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.SCENERY] == 1,
			"a node that re-enters the tree is counted once")
	record.on = false
	prop.draw.emit()
	t.check(_row_so_far(ledger)[counters + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.SCENERY] == 0,
			"a record that is off counts nothing")
	record.on = true
	# Each node of a counted class lands on the counter of its kind when it draws; one that is
	# not counted (a label) lands on none. Every node enters the tree, as the game's do.
	var kinds := {Prop.new(): FrameTiming.Draw.SCENERY, SceneryLayer.new(): FrameTiming.Draw.SCENERY,
		SceneryWater.new(): FrameTiming.Draw.SCENERY, TrafficLight.new(): FrameTiming.Draw.OTHER,
		ParkFenceMarker.new(): FrameTiming.Draw.OTHER, MeterBar.new(): FrameTiming.Draw.OTHER,
		HomeArrow.new(): FrameTiming.Draw.OTHER, ModeButton.new(): FrameTiming.Draw.OTHER,
		DangerEdge.new(): FrameTiming.Draw.BADGES, Label.new(): -1}
	for node: Node in kinds:
		t.add_child(node)
		_row_so_far(ledger)
		node.draw.emit()
		var row := _row_so_far(ledger)
		var landed := -1
		for kind: String in FrameTiming.Draw.keys():
			if row[counters + FrameLedger.COUNTER_NAMES.find("draws_" + kind.to_lower())] > 0:
				landed = FrameTiming.Draw[kind]
		t.check(landed == kinds[node], "%s is counted as kind %d (landed on %d)"
				% [node.get_class(), kinds[node], landed])
		t.remove_child(node)
		node.free()
	rig.free_all()
	for node in [prop, label, chunk, marker]:
		node.free()

## The flag and its page word, read the way the game reads them: off the configuration
## `RunConfig.parse()` builds from the command line, the page's query and the build.
func _test_the_flag_and_its_page_word(t) -> void:
	t.check(_debug_build(["--frame-record"]).frame_record_requested,
			"the command line's --frame-record starts the record")
	t.check(_page("?debug=1&framerecord=1").frame_record_requested,
			"?framerecord=1 starts it on a page whose bundle is open")
	t.check(not _page("?framerecord=1").frame_record_requested,
			"a release page without ?debug=1 ignores ?framerecord=1")
	t.check(not _page("?debug=1&framerecord=0").frame_record_requested
			and not _page("?debug=1").frame_record_requested,
			"only the value 1 asks for it, and ?debug=1 alone does not")
	t.check(_page("?debug=1&framerecord=1").web_debug_flag_used,
			"a page that records stays off the save, like the bundle's other words")

## The configuration a release page whose address bar says `query` runs on.
func _page(query: String) -> RunConfig:
	return RunConfig.parse(PackedStringArray(), query, false)

## The configuration a debug build started with `words` runs on.
func _debug_build(words: Array) -> RunConfig:
	return RunConfig.parse(PackedStringArray(words), "", true)

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
## sets the recorder up from it before `_start_day()` makes the day's agents, as in the game. The
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
	sitting.frame_timing = record
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
	t.check(record.on and record.ledger == recorder.ledger and recorder.ledger == restarted,
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
	var ledger := recorder.ledger
	t.get_tree().paused = true
	await UI.frames(t, 3)
	var kept := ledger.count
	t.check(not ledger.keep, "a paused frame is not kept")
	await UI.frames(t)
	t.check(ledger.count == kept, "and closing it stores nothing")
	t.get_tree().paused = false
	await UI.frames(t)
	t.check(ledger.count > kept, "a played frame is kept")
	var row: PackedInt64Array = ledger.rows().back()
	t.check(row[FrameLedger.FIRST_COUNTER + FrameLedger.CROWD_AGENTS] == city.crowd.agent_count()
			and row[FrameLedger.FIRST_COUNTER + FrameLedger.DAY] == run.header.day,
			"with the world's counters read at the end of its process step")
	t.check(await _the_readout_shows(t, main, recorder), "the readout carries the record's line")
	await _check_the_crowd_is_timed_once(t, city.crowd, record, ledger)
	record.start(ledger)
	var written := recorder.save()
	t.check(written == ProjectSettings.globalize_path(sitting.frame_record_path)
			and sitting.frame_record_path.begins_with(_SCRATCH_RECORDS + "/"),
			"a desktop save writes the file its sitting keeps, which outlives the recorder")
	t.check(recorder.save() == written, "and every later save rewrites the same file")
	DirAccess.remove_absolute(written)
	booted.free_all()
	t.check(not record.on, "leaving the tree switches the timing off")
	t.check(FileAccess.get_file_as_string(sitting.frame_record_path).contains("nappy-frame-record"),
			"and writes the record on the desktop as the scene exits")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sitting.frame_record_path))
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
	var before := ledger.count
	await UI.frames(t, count + 1)
	return ledger.count - before

## The last `count` rows the ledger stored.
func _rows_over(ledger: FrameLedger, count: int) -> Array[PackedInt64Array]:
	var rows := ledger.rows()
	var last: Array[PackedInt64Array] = []
	for i in range(maxi(0, rows.size() - count), rows.size()):
		last.append(rows[i])
	return last

## A live event made with the record off is never timed, even once it is on; one made under it runs
## its drawn frame (its look's redraw) once a frame, inside `events`, and once the record stops, it
## still redraws and the record it ran under is not touched again. Its step times nothing of its
## own: the manager's physics tick that runs it is timed. Each event draws on real frames, one at
## a time (`_one_drawn_frame()`).
func _test_a_timed_body_runs_once(t) -> void:
	var record := FrameRecord.new()
	var def := EventCatalogue.by_id("protest")
	var untimed_event := _event(t, def)
	var untimed_look := _BucketLook.watching(untimed_event)
	var scratch := FrameLedger.new(4)
	record.start(scratch)
	scratch.process_start(Time.get_ticks_usec())
	await _one_drawn_frame(t, untimed_event)
	var untimed := _row_so_far(scratch)
	t.check(untimed[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 0 and untimed_look.redraws == 1,
			"an event handed no record is not timed while another is on")
	var event := _event(t, def)
	event.timing = record
	var look := _BucketLook.watching(event)
	await _one_drawn_frame(t, event)
	# Time spent after the frame, measured, lands in what was running before the event: had the
	# event left its bucket open, it would land in `events` on top of the redraw's own.
	var after_from := Time.get_ticks_usec()
	OS.delay_usec(4 * SPENT_US)
	var after := Time.get_ticks_usec() - after_from
	var timed := _row_so_far(scratch)
	t.check(look.redraws == 1 and timed[FrameLedger.FIRST_BUCKET + FrameRecord.EVENTS] >= SPENT_US,
			"a timed event's drawn frame redraws once a frame, inside the events bucket (%d redraws)"
			% look.redraws)
	t.check(timed[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 1
			and timed[FrameLedger.FIRST_BUCKET + FrameRecord.PROCESS_REST] >= after
			and timed[FrameLedger.FIRST_BUCKET + FrameRecord.EVENTS] < after,
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
	await _one_drawn_frame(t, event)
	var stopped := _row_so_far(scratch)
	t.check(look.redraws == 2
			and stopped[FrameLedger.FIRST_COUNTER + FrameLedger.TIMER_CALLS] == 0
			and stopped[FrameLedger.FIRST_BUCKET + FrameRecord.EVENTS] == 0,
			"once the record stops, an event made under it redraws once and times nothing")
	untimed_event.free()
	event.free()

## Lets `event` draw on exactly one real frame: its process callback is on from the start of one
## frame to the start of the next.
func _one_drawn_frame(t, event: EventInstance) -> void:
	await t.get_tree().process_frame
	event.set_process(true)
	await t.get_tree().process_frame
	event.set_process(false)

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

## A live event standing alone, its process callback off until the test lets it draw, as
## `tests/test_acts.gd` builds one.
func _event(t, def: EventDef) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)
	return instance

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


## The readout says the window and what is drawn, each line within the readout's width.
func _test_the_readout_says_the_view(t) -> void:
	var lines := FrameRecorder.view_lines()
	t.check(lines.size() == 2 and lines[0].begins_with("window") and lines[1].begins_with("drawn"),
			"the readout says the window and what is drawn")
	for line in lines:
		t.check(_fits_the_readout(line), "the line fits the readout: %s" % line)

## Whether `line` is no wider than the readout, at the font the readout uses.
func _fits_the_readout(line: String) -> bool:
	return ThemeDB.fallback_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1,
			FrameRecorder.READOUT_FONT_SIZE).x <= FrameRecorder.READOUT_WIDTH

## The record's environment carries the pixels the page draws, as the file a phone hands over, and
## what the timer costs on the device: the smallest step its clock takes and what a timing pair
## costs. Read off the file a save writes.
func _test_the_environment_carries_the_view_and_the_clock(t) -> void:
	var rig := _rig(t, FrameRecord.new())
	rig.recorder.save()
	var environment: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(rig.sitting.frame_record_path))["environment"]
	for key in ["window_width", "window_height", "device_pixel_ratio", "drawn_width", "drawn_height"]:
		# A headless window reports 0 by 0, so only the keys and the ratio are pinned.
		t.check(environment.has(key), "the record's environment carries %s" % key)
	t.check(environment["device_pixel_ratio"] > 0.0, "the ratio is never 0")
	var step: float = environment["timer_resolution_usec"]
	t.check(step >= 1 and step < 2000, "the clock's smallest step is measured (%.0fus)" % step)
	t.check(environment["timer_pair_usec"] >= 0.0, "and so is what a timing pair costs")
	rig.free_all()

## A recorder in the tree on `record`, set up as `main` sets one up with no world to count, and its
## sitting's records handed a scratch folder so that a save, or leaving the tree, writes there and not
## under the player's own records. `free_all()` frees it all and removes the file.
func _rig(t, record: FrameRecord) -> _Rig:
	var rig := _Rig.new()
	rig.sitting = Sitting.new()
	rig.sitting.frame_timing = record
	rig.recorder = FrameRecorder.new()
	t.add_child(rig.recorder)
	rig.recorder.setup(func() -> bool: return false, null, null, null, RunState.new(), rig.sitting,
			_SCRATCH_RECORDERS)
	return rig

class _Rig extends RefCounted:
	var recorder: FrameRecorder
	var sitting: Sitting

	func free_all() -> void:
		# Leaving the tree writes the record to the sitting's path.
		recorder.free()
		var written := sitting.frame_record_path
		sitting.free()
		if written != "":
			DirAccess.remove_absolute(ProjectSettings.globalize_path(written))
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_frame_record_scratch_recorders"))
