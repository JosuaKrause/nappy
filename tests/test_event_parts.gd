extends RefCounted
## The parts a day's events are handed to, each driven on its own, as the `EventManager` that owns
## it holds it (`streaming`, `spawner`, `warnings`) over the one `EventWorld` the manager hands every
## part, rather than through the manager's tick: `EventStreaming` bringing a plan in and out with its
## state, `WarningBoard` creating what a warning was for once its time is up or withdrawing it, and
## raising the mark over her head for the live events that end the day (handed `FakeEvent`s over a
## world of its own, no manager), `EventSpawner` recording a scar once and drawing the pelican bag of the run it is handed, and
## `CheckpointController` saying what a door does to her as intents rather than moving her. And the
## manager seeing her once she is handed in, never by looking her up.

const STEP := 0.1
## One physics frame, the step the lesson's retry is driven at.
const FRAME := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_streaming_carries_a_plan_out_and_back_on_its_own(t)
	_test_a_warning_creates_its_row_once_its_time_is_up(t)
	_test_a_warning_with_nowhere_to_put_it_is_withdrawn(t)
	_test_a_scar_is_recorded_once_however_often_it_streams_in(t)
	_test_the_pelican_bag_is_the_handed_runs(t)
	_test_a_door_says_what_it_does_to_her_and_moves_nobody(t)
	_test_a_failed_lesson_retry_leaves_the_director_running(t)
	await _test_the_manager_sees_her_only_once_she_is_handed_in(t)
	await _test_only_a_lethal_thing_puts_the_mark_over_her_head(t)

## A manager handed a map drawn in a world node and a run of its own (`EventSurroundings.on()`,
## then `EventManager.setup()`, as the escape's building is set up), out of the tree so that
## nothing ticks it: the parts under test are its own (`streaming`, `spawner`, `warnings`) and its
## `world` is the one every part is handed. `_free_manager()` frees it with the node.
func _manager(t: TestRunner) -> EventManager:
	var holder := WorldContext.new()
	t.add_child(holder)
	var map := CityMap.new()
	var run := RunState.new()
	var manager := EventManager.new(EventSurroundings.new().on(map).drawn_in(holder))
	manager.setup(run)
	return manager

## A Stroller with the camera it looks up by path, in the tree, its physics stepped by nobody.
func _her(t: TestRunner) -> Stroller:
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	her.add_child(camera)
	t.add_child(her)
	her.set_physics_process(false)
	return her

func _free_manager(manager: EventManager) -> void:
	var holder := manager.world.drawn_in()
	manager.free()
	holder.free()

func _test_streaming_carries_a_plan_out_and_back_on_its_own(t: TestRunner) -> void:
	var manager := _manager(t)
	var streaming := manager.streaming
	var def := EventCatalogue.by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var plan := EventPlan.new(def, at)
	var plans: Array[EventPlan] = [plan]
	manager.walk_events().take(plans)
	streaming.stream_around(at)
	t.check(plan.is_in_the_world() and manager.instances().has(manager.event_of(plan)),
			"within reach, the plan is streamed in and joins the world's live instances")
	if not plan.is_in_the_world():
		_free_manager(manager)
		return
	manager.world.where_she_is().tell(at + Vector2(def.notice_within() - 10.0, 0.0))
	for _i in 3:
		manager.event_of(plan).step(STEP)
	var age := manager.event_of(plan).age()
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	var leaving := manager.event_of(plan)
	streaming.stream_around(far)
	t.check(not plan.is_in_the_world() and not manager.instances().has(leaving),
			"out of reach, it is streamed out and leaves the live instances")
	t.close_to(plan.saved().age(), age, "its plan keeps how far it had run")
	t.check(not plan.saved().state_of("EventPursuit").is_empty(), "and its pursuit's state")
	streaming.stream_around(at)
	t.check(plan.is_in_the_world(), "back within reach, it is streamed in again")
	if manager.event_of(plan):
		t.close_to(manager.event_of(plan).age(), age, "picking up where it left off")
	streaming.clear()
	t.check(not plan.is_in_the_world() and manager.walk_events().plans().is_empty(),
			"cleared, the day's plan is gone")
	_free_manager(manager)

func _test_a_warning_creates_its_row_once_its_time_is_up(t: TestRunner) -> void:
	var manager := _manager(t)
	var board := manager.warnings
	var def := EventCatalogue.by_id("cyclist")
	var place := Vector2(800.0, 0.0)
	var arrived: Array = []
	var where := func(_her: Vector2) -> Vector2: return place
	var arrive := func(at: Vector2, _her: Vector2) -> bool:
		arrived.append(at)
		return true
	var warning := board.warn_first(def, Vector2.ZERO, where, arrive)
	t.check(warning != null and board.pending_warnings().has(warning),
			"a warning with a place to point at is up")
	var shown := 0.0
	while arrived.is_empty() and shown < 5.0:
		board.run(STEP, Vector2.ZERO)
		shown += STEP
	t.check(arrived.size() == 1 and arrived[0] == place,
			"once its time is up its row is created where it points, once")
	t.check(shown >= EventSpawner.as_warned(def).warned_for() - 0.001,
			"and not before its badge has been up for the row's own warning (%.2fs)" % shown)
	t.check(board.pending_warnings().is_empty(), "and the warning is taken down")
	_free_manager(manager)

func _test_a_warning_with_nowhere_to_put_it_is_withdrawn(t: TestRunner) -> void:
	var manager := _manager(t)
	var board := manager.warnings
	var def := EventCatalogue.by_id("cyclist")
	var asked := [0]
	var where := func(_her: Vector2) -> Vector2:
		asked[0] += 1
		return Vector2(800.0, 0.0) if asked[0] == 1 else Vector2.INF
	var arrive := func(_at: Vector2, _her: Vector2) -> bool: return true
	var withdrawn := [false]
	var warning := board.warn_first(def, Vector2.ZERO, where, arrive)
	warning.when_withdrawn(func() -> void: withdrawn[0] = true)
	for _i in 60:
		board.run(STEP, Vector2.ZERO)
	t.check(warning.was_withdrawn() and withdrawn[0] and board.pending_warnings().is_empty(),
			"a warning whose ground has no place for its row when its time is up is withdrawn, " +
			"and its caller is told")
	t.check(board.warn_first(def, Vector2.ZERO, func(_her: Vector2) -> Vector2: return Vector2.INF,
			arrive) == null and board.pending_warnings().is_empty(),
			"and one with no place at all is never put up")
	_free_manager(manager)

func _test_a_scar_is_recorded_once_however_often_it_streams_in(t: TestRunner) -> void:
	var manager := _manager(t)
	var streaming := manager.streaming
	var def := EventCatalogue.by_id("burning_building")
	t.check(def.scar_id() != "", "the fire leaves a scar")
	t.check(manager.world.run().attempt_spend().scars().is_empty(), "and the run starts with none")
	var at := Vector2(6000.0, 6000.0)
	var plan := EventPlan.new(def, at)
	var plans: Array[EventPlan] = [plan]
	manager.walk_events().take(plans)
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	for _i in 3:
		streaming.stream_around(at)
		streaming.stream_around(far)
	var added := manager.world.run().attempt_spend().scars().size()
	t.check(added == 1, "three times in and out records the fire's scar once (%d)" % added)
	_free_manager(manager)

func _test_the_pelican_bag_is_the_handed_runs(t: TestRunner) -> void:
	var manager := EventManager.new()
	var run := RunState.new()
	run.header().use_seed(4242)
	manager.setup(run)
	var spawner := manager.spawner
	var cyclist := EventCatalogue.by_id("cyclist")
	for _i in 5:
		spawner.rolls_a_pelican(cyclist)
	t.check(run.pelican().draws() == 5, "five cyclists draw five marbles from the handed run's bag")
	spawner.rolls_a_pelican(EventCatalogue.by_id("loose_dog"))
	t.check(run.pelican().draws() == 5, "a dog draws nothing")
	manager.free()

func _test_a_door_says_what_it_does_to_her_and_moves_nobody(t: TestRunner) -> void:
	var manager := _manager(t)
	var made: Array = []
	var spawn := func(def: EventDef, at: Vector2) -> EventInstance:
		made.append([def, at])
		return null
	var doors := CheckpointController.new(manager.world, spawn, EventCatalogue.door_guard())
	# A post is a plan the day's streaming brings in once she is near (`EventStreaming.add()`).
	var post_at := Vector2(3000.0, 3000.0)
	var post_plan := EventPlan.new(EventCatalogue.by_id("checkpoint_post"), post_at)
	manager.streaming.add(post_plan)
	manager.streaming.stream_around(post_at)
	var hut := manager.event_of(post_plan)
	var her := _her(t)
	her.global_position = hut.global_position + Vector2(0.0, 4.0)
	manager.use_player(her)
	var said: Array = []
	doors.takes_her_in.connect(func(at: Vector2) -> void: said.append(["in", at]))
	doors.holds_her.connect(func(seconds: float) -> void: said.append(["hold", seconds]))
	doors.lets_her_out.connect(func(at: Vector2) -> void: said.append(["out", at]))
	var standing := her.global_position
	manager.world.where_she_is().tell(standing)
	doors.check_detentions()
	t.check(said.size() == 2 and said[0][0] == "in" and said[0][1] == hut.global_position
			and said[1][0] == "hold" and is_equal_approx(said[1][1], hut.detains_for()),
			"a post that takes her in says so, then that she is held for its seconds: %s" % [said])
	t.check(her.visible and not her.is_detained() and her.global_position == standing,
			"and nothing is done to her by the controller itself")
	var guard := 0
	while hut.is_chatting() and guard < 200:
		hut.step(STEP)
		guard += 1
	said.clear()
	doors.check_detentions()
	t.check(said.size() == 1 and said[0][0] == "out"
			and (said[0][1] as Vector2).distance_to(standing) > 1.0,
			"once its hold has run it says where she is let out, on the far side: %s" % [said])
	t.check(her.global_position == standing, "and leaves moving her to whoever carries it out")
	manager.use_player(null)
	her.free()
	_free_manager(manager)

func _test_the_manager_sees_her_only_once_she_is_handed_in(t: TestRunner) -> void:
	var holder := WorldContext.new()
	t.add_child(holder)
	var map := CityMap.new()
	var run := RunState.new()
	var manager := EventManager.new(EventSurroundings.new().on(map).drawn_in(holder))
	manager.setup(run)
	t.add_child(manager)
	var def := EventCatalogue.by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var plan := EventPlan.new(def, at)
	manager.walk_events().take([plan] as Array[EventPlan])
	var her := _her(t)
	# Off the robber's own heading and beyond his notice, so he stands as he was sited, and the side
	# a man would get out of him on is hers once he knows where she is (`door_for_its_officer()`).
	var off := Vector2(def.notice_within(), def.notice_within())
	her.global_position = at + off
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check(not plan.is_in_the_world(),
			"a player in the tree's `player` group but never handed in is nobody the events see")
	manager.use_player(her)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check(plan.is_in_the_world() and _her_side(manager.event_of(plan), def) > 0.0,
			"handed in, the events around her stream in and are told where she is")
	# Stood aside for the title, she is handed in and still nobody the events see.
	her.stand_aside()
	# Moved to his other side, so a manager that told the events anything about her shows in it;
	# the check above is what proves frames run.
	her.global_position = at - off
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check(not manager.world.has_player() and _her_side(manager.event_of(plan), def) > 0.0,
			"stood aside for the title, she is told nothing and nothing can strike her")
	manager.use_player(null)
	manager.free()
	her.free()
	holder.free()

## Which side of `event` a man would get out on, toward where it was last told she was: positive
## for the side of `at + off` in `_test_the_manager_sees_her_only_once_she_is_handed_in()`.
func _her_side(event: EventInstance, row: EventDef) -> float:
	var door := event.door_for_its_officer(row) - event.global_position
	return door.dot(Vector2.ONE)

## A director that hands the day-3 dog out once, then nothing, and counts the time it is given: a
## placement that fails must not starve its independent clock.
class _RetryDirector extends EventDirector:
	var elapsed := 0.0
	var handed := false
	## Overrides EventDirector.due.
	func due(delta: float, _at: Vector2, _velocity: Vector2, _view: VisibleView = null) -> Array:
		elapsed += delta
		if handed:
			return []
		handed = true
		return [EventCatalogue.by_id("charging_dog"),
				PackedVector2Array([Vector2(400.0, 0.0), Vector2(300.0, 0.0)])]

## The board the lesson puts its warning up on, counting how often it is asked to; on the empty
## ground below there is nowhere off screen to stand, so every ask is refused.
class _CountingBoard extends WarningBoard:
	var asked := 0
	## Overrides WarningBoard.warn_first.
	func warn_first(def: EventDef, her: Vector2, where: Callable,
			arrive: Callable) -> PendingWarning:
		asked += 1
		return super(def, her, where, arrive)

func _test_a_failed_lesson_retry_leaves_the_director_running(t: TestRunner) -> void:
	# An empty city map: the director owes its retry the same way with nothing on the ground.
	var map := CityMap.new()
	var told: Array[String] = []
	var manager := EventManager.new(EventSurroundings.new().in_the_city(map)
			.tracing_to(RecordingTrace.new(told)))
	manager.setup(null)
	var board := _CountingBoard.new(manager.world)
	var lesson := EventsAhead.new(manager.world, manager.streaming, manager.spawner, board,
			manager.walk_events())
	var director := _RetryDirector.new(map)
	lesson.use_director(director, null)
	var body := CharacterBody2D.new()
	body.velocity = Vector2.RIGHT * Tuning.WALK_SPEED
	manager.use_player(body)
	for frame in 150:
		lesson.place_what_is_owed_ahead(FRAME)
	t.check(board.asked == 3,
			"a blocked lesson is asked at once, then retried twice in 2.5s, rather than every frame (%d)"
			% board.asked)
	t.check(told.any(func(line: String) -> bool:
			return line.contains("has nowhere off screen to stand")),
			"and the run log says the lesson is owed again")
	t.close_to(director.elapsed, 2.5, "other director events receive every elapsed frame", 0.001)
	lesson.clear()
	board.clear()
	manager.free()
	body.free()

## **The mark over her head means: this will end your day.** *(M30, playtest 05 finding 3.)*
##
## It used to be raised for any telegraphing event whose radius reached her, and the player's
## verdict was *"it doesn't actually have an effect on gameplay — I can just keep doing what I
## was doing."* That was accurate for fifteen of the eighteen rows: for anything that is not a
## lethal, the mark meant *a number is about to move faster*, which the meter already says
## continuously and proportionally. This is the same rule the caret over an entity got right
## first time — a cue that marks everything says nothing — applied to the one cue that gives an
## instruction rather than information.
##
## Run through the warning board rather than through `Stroller.warn()`, because the thing that was
## wrong was *which events call it*, and nothing that raised the cue by hand could see that.
func _test_only_a_lethal_thing_puts_the_mark_over_her_head(t: TestRunner) -> void:
	# The board is handed the world it asks for the player and the live events: no manager is
	# asked anything.
	var world := EventWorld.new()
	var board := WarningBoard.new(world)
	var rig := _her(t)
	world.use_player(rig)
	rig.global_position = Vector2(1000.0, 1000.0)

	# An ordinary telegraphing event, right on top of her. It costs her the meter and says so
	# through the meter; it is not an instruction.
	var ordinary := _a_live(EventCatalogue.by_id("dog_walker"), rig.global_position)
	world.take_in(ordinary)
	board.warn_about_the_ground_she_is_on()
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"a dog walker whose radius covers her raises nothing over her head")

	# A lethal one, still telegraphing: the contract is now about her and the clock has started.
	var lethal := _a_live(EventCatalogue.by_id("abduction"), rig.global_position)
	world.take_in(lethal)
	board.warn_about_the_ground_she_is_on()
	t.check(rig.alert_level() == Stroller.Alert.SOON,
			"an unmarked van telegraphing over her is the flashing mark")

	# And once it is live, the second level: one step left.
	lethal.telegraphing = false
	board.warn_about_the_ground_she_is_on()
	t.check(rig.alert_level() == Stroller.Alert.NOW,
			"and the same van live around her is the doubled one")

	# Far enough away and it is somebody else's problem again.
	rig.global_position = lethal.global_position + Vector2(lethal.heard_within() + 50.0, 0.0)
	await _physics_ticks(t, rig, 1.0)
	board.warn_about_the_ground_she_is_on()
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"outside its outer radius there is nothing over her head")

	# **And `NOW` is about the pair of them.** *(M39, playtest 10 finding 11: "when I'm walking
	# orthogonally away from the biker the double !! shouldn't show anymore since there is no way it
	# can affect me.")* Well inside the outer radius, well outside the lethal one, and not closing:
	# the strongest cue in the game has nothing to say about that.
	rig.global_position = lethal.global_position + Vector2(lethal.heard_within() - 20.0, 0.0)
	rig.velocity = Vector2.ZERO
	board.warn_about_the_ground_she_is_on()
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"standing still inside a live lethal field but nowhere near it is not an instruction")

	# Walking into it is, once she is a step from the end of the day.
	rig.global_position = lethal.global_position + Vector2(lethal.core_within() + 20.0, 0.0)
	rig.velocity = Vector2(-Tuning.WALK_SPEED, 0.0)
	board.warn_about_the_ground_she_is_on()
	t.check(rig.alert_level() == Stroller.Alert.NOW,
			"walking the last step into it is")

	# And turning round takes it away again, from the same place, on the same frame.
	rig.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	# The doubled mark the step before raised is the warnings' own, and theirs to take down.
	rig.stand_down(WarningBoard.WARNING_SOURCE)
	board.warn_about_the_ground_she_is_on()
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"and walking away from the same spot takes it down — the danger has been avoided")

	world.let_go_of_every_event()
	ordinary.free()
	lethal.free()
	rig.free()

## A live event of `row` standing at `at`, just made and so telegraphing. It answers what its row
## says of it (whether it ends the day, how far its core reaches and how far it is heard) and the
## quiet answer otherwise, which is what a real dog walker or van answers where it stands: not
## waiting, not driving, not travelling, no guard to lose (read off the real events once). It is
## in no tree.
func _a_live(row: EventDef, at: Vector2) -> FakeEvent:
	var live := FakeEvent.new()
	live.of_row = row
	live.position = at
	live.telegraphing = true
	live.lethal = row.ends_the_day()
	live.core = row.core_within()
	live.heard = row.heard_within()
	return live

## Lets `seconds` of the stroller's own physics ticks pass for real, counted in ticks, one tick a
## frame (record busy-puffin: a slow frame would pack several), its tick switched on only for them.
## Ends on the frame after the last tick, so the rig has run every one of them.
func _physics_ticks(t: TestRunner, rig: Stroller, seconds: float) -> void:
	var steps := Engine.max_physics_steps_per_frame
	Engine.max_physics_steps_per_frame = 1
	rig.set_physics_process(true)
	var ticks := ceili(seconds * Engine.physics_ticks_per_second - 0.001)
	var ran := 0
	while ran < ticks:
		var before := Engine.get_physics_frames()
		await t.get_tree().physics_frame
		ran += Engine.get_physics_frames() - before
	await t.get_tree().process_frame
	rig.set_physics_process(false)
	Engine.max_physics_steps_per_frame = steps
