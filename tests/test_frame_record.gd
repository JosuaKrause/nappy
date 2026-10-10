extends RefCounted
## The per-system frame record: every microsecond of a frame lands in exactly one bucket, so the
## buckets add up to the frame; a frame that ran into the next refresh is marked; the readout names
## the last slow frame's three largest costs; and the flag and its page word open only where the
## rest of the `?debug=1` bundle does, keeping the run off the save.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_frame_adds_up(t)
	_test_slow_frames_are_marked(t)
	_test_frames_outside_play_are_timed_but_not_kept(t)
	_test_a_headless_frame_draws_nothing(t)
	_test_draw_splits_at_the_renderers_pre_draw(t)
	_test_the_ring_keeps_the_latest_frames(t)
	_test_top_costs_order_and_leave_out_the_wait(t)
	_test_the_readout_line(t)
	_test_the_report_round_trips(t)
	_test_the_static_switch_charges_the_ledger(t)
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
	var was_on := FrameRecord.on
	var was := FrameRecord.ledger
	var ledger := FrameLedger.new(8, 16667)
	FrameRecord.start(ledger)
	ledger.process_start(0)
	ledger.keep = true
	ledger.process_end(1000)
	FrameRecord.drew(FrameLedger.DRAWS_SCENERY)
	FrameRecord.drew(FrameLedger.DRAWS_SCENERY)
	FrameRecord.drew(FrameLedger.DRAWS_HALOS)
	ledger.pre_draw(2500)
	ledger.drawn(6000)
	ledger.process_start(16000)
	ledger.keep = true
	ledger.process_end(17000)
	ledger.process_start(32000)
	var first: PackedInt64Array = ledger.rows()[0]
	var second: PackedInt64Array = ledger.rows()[1]
	FrameRecord.on = was_on
	FrameRecord.ledger = was
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
func _test_the_static_switch_charges_the_ledger(t) -> void:
	var was_on := FrameRecord.on
	var was := FrameRecord.ledger
	var ledger := FrameLedger.new(8, 16667)
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
## off — which is what keeps the escape, which builds no recorder, from paying for it. Real frames
## cannot elapse inside a suite (`run_tests.gd` calls every suite synchronously), so the phases
## are driven by hand on the real tree's recorder, as `tests/test_camera_start.gd` drives its boot.
##
## The record is running before `main` is built, as it is in the game, where `main._ready()` sets
## the recorder up before `_start_day()` makes the day's agents: so the day's agents copy the switch
## on, and the timed path of each is checked on the real crowd (`_check_the_agents_are_timed_once`).
## The recorder itself is then set up from a switch left off, the way a held restart leaves it.
func _test_the_recorder_in_a_real_main(t) -> void:
	var saved := _save_game_state()
	var was_on := FrameRecord.on
	var was := FrameRecord.ledger
	var restarted := FrameLedger.new(8)
	FrameRecord.start(restarted)
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	main._on_title_start(ControlsMode.Mode.TAP)
	FrameRecord.on = false
	var recorder := FrameRecorder.new()
	recorder.save_on_exit = false
	main.add_child(recorder)
	recorder.setup(main, main._city, main._player, main._day)
	main._frame_recorder = recorder
	t.check(FrameRecord.on and FrameRecord.ledger == recorder.ledger
			and recorder.ledger == restarted,
			"setting up the recorder switches the timing on, keeping the record a restart left")
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
			and row[FrameLedger.FIRST_COUNTER + FrameLedger.DAY] == GameState.day,
			"with the world's counters read at the end of its process step")
	t.check(main._frame_record_lines().size() == 1, "the readout carries the record's line")
	_check_the_agents_are_timed_once(t, main._city.crowd.agents())
	FrameRecord.start(ledger)
	Telemetry.end_run()
	main.free()
	t.check(not FrameRecord.on, "leaving the tree switches the timing off")
	FrameRecord.ledger = was
	FrameRecord.on = was_on
	_restore_game_state(saved)
	t.check(_save_game_state() == saved,
			"the suite leaves every field a real main's run writes as it found it")

## The real day's agents, made under the record: each `_process()` runs its body once (its clock
## moves by one step, not two and not none), inside one timed call charged to `crowd`, and once the
## record stops, the body still runs once and the record it ran under is not touched again. A
## missing `return` after the timed call would walk every agent twice a frame, only while recording.
func _check_the_agents_are_timed_once(t, agents: Array[CrowdAgent]) -> void:
	var timed := agents.filter(func(agent: CrowdAgent) -> bool: return agent._timed)
	t.check(not agents.is_empty() and timed.size() == agents.size(),
			"every agent made under the record copies the switch on (%d of %d)"
			% [timed.size(), agents.size()])
	var scratch := FrameLedger.new(4)
	FrameRecord.start(scratch)
	scratch.process_start(Time.get_ticks_usec())
	var clocks: Array[float] = []
	for agent in agents:
		clocks.append(agent._clock)
	for agent in agents:
		agent._process(STEP)
	var once := true
	for i in agents.size():
		once = once and is_equal_approx(agents[i]._clock, clocks[i] + STEP)
	t.check(once, "a timed agent's body runs once a call, not twice and not never")
	t.check(scratch._counters[FrameLedger.TIMER_CALLS] == agents.size(),
			"each agent's call is one timed call (%d for %d agents)"
			% [scratch._counters[FrameLedger.TIMER_CALLS], agents.size()])
	t.check(scratch._spent[FrameRecord.CROWD] > 0
			and scratch._current == FrameRecord.PROCESS_REST,
			"their bodies are charged to crowd, and the clock goes back to what was running")
	FrameRecord.stop()
	var spent := scratch._spent.duplicate()
	for agent in agents:
		agent._process(STEP)
	once = true
	for i in agents.size():
		once = once and is_equal_approx(agents[i]._clock, clocks[i] + 2.0 * STEP)
	t.check(once and scratch._counters[FrameLedger.TIMER_CALLS] == agents.size()
			and scratch._spent == spent,
			"once the record stops, an agent made under it runs its body once and times nothing")

## A crowd agent and a live event made with the record off are never timed, even once it is on;
## a live event made under it runs its body once a call, inside `events`, and once the record
## stops, its body still runs once and the record it ran under is not touched again.
func _test_a_timed_body_runs_once(t) -> void:
	var was_on := FrameRecord.on
	var was := FrameRecord.ledger
	FrameRecord.stop()
	var untimed_agent := CrowdAgent.new()
	untimed_agent._skip_motion = true
	var def := EventCatalogue.by_id("protest")
	var untimed_event := _event(t, def)
	var scratch := FrameLedger.new(4)
	FrameRecord.start(scratch)
	scratch.process_start(Time.get_ticks_usec())
	var timed_agent := CrowdAgent.new()
	timed_agent._skip_motion = true
	t.check(not untimed_agent._timed and timed_agent._timed,
			"an agent copies the switch as it stands when it is made")
	untimed_agent._process(STEP)
	var age := untimed_event.age
	untimed_event._process(STEP)
	t.check(scratch._counters[FrameLedger.TIMER_CALLS] == 0
			and is_equal_approx(untimed_event.age, age + STEP),
			"an agent and an event made with the record off are not timed once it is on")
	timed_agent._process(STEP)
	t.check(scratch._counters[FrameLedger.TIMER_CALLS] == 1,
			"an agent made under the record is timed once a call")
	var event := _event(t, def)
	t.check(event._timed, "an event copies the switch as it stands when it is made")
	# Past its telegraph, so its first body announces it, and the announcement says which bucket
	# the body ran in.
	event.age = def.telegraph_time + 0.01
	age = event.age
	var charged: Array[int] = []
	var listen := func(_instance: Variant) -> void: charged.append(FrameRecord.ledger._current)
	EventBus.event_activated.connect(listen)
	event._process(STEP)
	EventBus.event_activated.disconnect(listen)
	t.check(is_equal_approx(event.age, age + STEP), "a timed event's body runs once a call")
	t.check(charged == [FrameRecord.EVENTS], "inside the events bucket (%s)" % [charged])
	t.check(scratch._counters[FrameLedger.TIMER_CALLS] == 2
			and scratch._current == FrameRecord.PROCESS_REST,
			"as one timed call, and the clock goes back to what was running")
	FrameRecord.stop()
	var spent := scratch._spent.duplicate()
	event._process(STEP)
	timed_agent._process(STEP)
	t.check(is_equal_approx(event.age, age + 2.0 * STEP)
			and scratch._counters[FrameLedger.TIMER_CALLS] == 2 and scratch._spent == spent,
			"once the record stops, an event made under it runs its body once and times nothing")
	untimed_agent.free()
	timed_agent.free()
	untimed_event.free()
	event.free()
	FrameRecord.ledger = was
	FrameRecord.on = was_on

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
## tiles — so the next suite in the process finds the run it left.
func _save_game_state() -> Dictionary:
	return {
		"snapshot": GameState.save_snapshot(),
		"escape_section": GameState.escape_section,
		"posters": GameState.posters.to_data(),
		"fenced_park": GameState.fenced_park,
		"fenced_park_act": GameState.fenced_park_act,
		"alley_tiles": GameState.completed_resistance_alley_tiles.duplicate(),
	}

func _restore_game_state(saved: Dictionary) -> void:
	GameState.restore_snapshot(saved["snapshot"])
	GameState.escape_section = saved["escape_section"]
	GameState.posters.restore(saved["posters"])
	GameState.fenced_park = saved["fenced_park"]
	GameState.fenced_park_act = saved["fenced_park_act"]
	GameState.completed_resistance_alley_tiles.assign(saved["alley_tiles"])

## One kept frame starting at `start` and lasting `length`, of which `spent` went to `bucket`.
func _drive(ledger: FrameLedger, start: int, length: int, bucket: int, spent: int) -> void:
	ledger.process_start(start)
	var outer := ledger.enter(bucket, start + 100)
	ledger.switch_to(outer, start + 100 + spent)
	ledger.keep = true
	ledger.process_end(start + 200 + spent)
