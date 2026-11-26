extends RefCounted
## The parts a day's events are handed to, each driven on its own, made as
## `EventManager._init()` makes them (`_Parts`) over the one `EventWorld` every part is handed,
## rather than through the manager's tick: `EventStreaming` bringing a plan in and out with its
## state and telling whoever listens of a body it stands, `WarningBoard` creating what a warning
## was for once its time is up or withdrawing it, and raising the mark over her head for the live
## events that end the day (handed `FakeEvent`s over a world of its own, no manager),
## `EventSpawner` recording a scar once and drawing the pelican bag of the run it is handed, and
## `CheckpointController` saying what a door does to her as intents rather than moving her. And
## the manager seeing her once she is handed in, never by looking her up.

const STEP := 0.1
## One physics frame, the step the lesson's retry is driven at.
const FRAME := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_streaming_carries_a_plan_out_and_back_on_its_own(t)
	_test_a_warning_creates_its_row_once_its_time_is_up(t)
	_test_a_warning_with_nowhere_to_put_it_is_withdrawn(t)
	_test_a_scar_is_recorded_once_however_often_it_streams_in(t)
	_test_a_drawn_body_is_told_to_whoever_listens(t)
	_test_the_pelican_bag_is_the_handed_runs(t)
	_test_a_door_says_what_it_does_to_her_and_moves_nobody(t)
	_test_a_failed_lesson_retry_leaves_the_director_running(t)
	await _test_the_manager_sees_her_only_once_she_is_handed_in(t)
	_test_only_a_lethal_thing_puts_the_mark_over_her_head(t)

## The parts a case drives, made the way `EventManager._init()` makes them: one world over a map
## drawn in a world node (`EventSurroundings.on()`) with a run of its own, as the escape's
## building is set up, and the walk, board, spawner and streaming over it. Nothing ticks them.
class _Parts:
	var holder := WorldContext.new()
	var world: EventWorld
	var walk := WalkEvents.new()
	var board: WarningBoard
	var spawner: EventSpawner
	var streaming: EventStreaming

	func _init(t: TestRunner, on: CityMap = null) -> void:
		t.add_child(holder)
		world = EventWorld.new(EventSurroundings.new().reading(Shipped.rows())
				.on(on if on else CityMap.new())
				.drawn_in(holder))
		world.use_run(RunState.new())
		board = WarningBoard.new(world)
		spawner = EventSpawner.new(world, board)
		streaming = EventStreaming.new(world, spawner, walk)

	## Lets the warnings go, which hold the parts that raised them, and frees the node every
	## event is drawn under.
	func free_all() -> void:
		board.clear()
		holder.free()

func _parts(t: TestRunner, on: CityMap = null) -> _Parts:
	return _Parts.new(t, on)

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

func _test_streaming_carries_a_plan_out_and_back_on_its_own(t: TestRunner) -> void:
	var parts := _parts(t)
	var streaming := parts.streaming
	var def := Shipped.rows().by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var plan := EventPlan.new(def, at)
	var plans: Array[EventPlan] = [plan]
	parts.walk.take(plans)
	streaming.stream_around(at)
	t.check(plan.is_in_the_world() and parts.world.instances().has(streaming.event_of(plan)),
			"within reach, the plan is streamed in and joins the world's live instances")
	if not plan.is_in_the_world():
		parts.free_all()
		return
	parts.world.where_she_is().tell(at + Vector2(def.notice_within() - 10.0, 0.0))
	for _i in 3:
		streaming.event_of(plan).step(STEP)
	var age := streaming.event_of(plan).age()
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	var leaving := streaming.event_of(plan)
	streaming.stream_around(far)
	t.check(not plan.is_in_the_world() and not parts.world.instances().has(leaving),
			"out of reach, it is streamed out and leaves the live instances")
	t.close_to(plan.saved().age(), age, "its plan keeps how far it had run")
	t.check(not plan.saved().state_of("EventPursuit").is_empty(), "and its pursuit's state")
	streaming.stream_around(at)
	t.check(plan.is_in_the_world(), "back within reach, it is streamed in again")
	if streaming.event_of(plan):
		t.close_to(streaming.event_of(plan).age(), age, "picking up where it left off")
	streaming.clear()
	t.check(not plan.is_in_the_world() and parts.walk.plans().is_empty(),
			"cleared, the day's plan is gone")
	parts.free_all()

## **A body a draw stands is told on, tile for tile** (`EventStreaming.use_body_listener()`): the
## listener is called once for each placed plan whose row has a solid body, with
## `EventSpawner.footprint_of()` of it, and for no plan without one, and **after the body is
## recorded on the map**, so a car recycled for it is rolled with the body in the record. With no
## listener a draw says nothing and still stands its rows.
func _test_a_drawn_body_is_told_to_whoever_listens(t: TestRunner) -> void:
	var map := StreetMap.full()
	var parts := _parts(t, map)
	var told: Array[String] = []
	# Told tiles the map does not yet hold as a body's, asked as the listener is called: the body
	# is recorded before the crowd is told, so every tile told is one the map already holds.
	var not_yet_recorded: Array[Vector2i] = []
	parts.streaming.use_body_listener(func(tiles: Array[Vector2i]) -> void:
		told.append(str(tiles))
		for tile in tiles:
			if not map.is_obstructed(tile):
				not_yet_recorded.append(tile))
	# One row with a solid body and one without, stood on the sidewalk a block apart.
	var at := CrowdLanes.arterial_pavement(map)
	var drawn: Array[EventPlan] = [
		EventPlan.new(Shipped.rows().by_id("barricade"), at),
		EventPlan.new(Shipped.rows().by_id("cat_dash"), at + Vector2(0.0,
		CityMap.period() * Tuning.TILE_SIZE)),
	]
	var expected: Array[String] = []
	for plan in drawn:
		parts.streaming.add(plan)
		var tiles := EventSpawner.footprint_of(BodyStance.of(map, plan.row(), plan.placed_at(),
				plan.faces()))
		if not tiles.is_empty():
			expected.append(str(tiles))
	expected.sort()
	told.sort()
	t.check(not expected.is_empty() and expected.size() < drawn.size(),
			"the draw stands rows with a body and rows without one (%d of %d placed have one)"
			% [expected.size(), drawn.size()])
	t.check(told == expected,
			"the listener is told the footprint of each placed plan that has one, and no other"
			+ " (%d told, %d expected)" % [told.size(), expected.size()])
	t.check(not_yet_recorded.is_empty(),
			"and each is told after the body is recorded: the map holds every tile told as a body's"
			+ " (%d tiles it did not yet)" % not_yet_recorded.size())
	var told_so_far := told.size()
	parts.streaming.use_body_listener(Callable())
	var drawn_before := parts.walk.plans().size()
	parts.streaming.add(EventPlan.new(Shipped.rows().by_id("barricade"),
			at + Vector2(0.0, 2.0 * CityMap.period() * Tuning.TILE_SIZE)))
	t.check(told.size() == told_so_far and parts.walk.plans().size() > drawn_before,
			"with no listener a draw tells nobody and still stands its rows")
	parts.free_all()

func _test_a_warning_creates_its_row_once_its_time_is_up(t: TestRunner) -> void:
	var parts := _parts(t)
	var board := parts.board
	var def := Shipped.rows().by_id("cyclist")
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
	parts.free_all()

func _test_a_warning_with_nowhere_to_put_it_is_withdrawn(t: TestRunner) -> void:
	var parts := _parts(t)
	var board := parts.board
	var def := Shipped.rows().by_id("cyclist")
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
	parts.free_all()

func _test_a_scar_is_recorded_once_however_often_it_streams_in(t: TestRunner) -> void:
	var parts := _parts(t)
	var streaming := parts.streaming
	var def := Shipped.rows().by_id("burning_building")
	t.check(def.scar_id() != "", "the fire leaves a scar")
	t.check(parts.world.run().attempt_spend().scars().is_empty(),
			"and the run starts with none")
	var at := Vector2(6000.0, 6000.0)
	var plan := EventPlan.new(def, at)
	var plans: Array[EventPlan] = [plan]
	parts.walk.take(plans)
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	for _i in 3:
		streaming.stream_around(at)
		streaming.stream_around(far)
	var added := parts.world.run().attempt_spend().scars().size()
	t.check(added == 1, "three times in and out records the fire's scar once (%d)" % added)
	parts.free_all()

func _test_the_pelican_bag_is_the_handed_runs(t: TestRunner) -> void:
	var world := EventWorld.new(EventSurroundings.new().reading(Shipped.rows()))
	var run := RunState.new()
	run.header().use_seed(4242)
	world.use_run(run)
	var spawner := EventSpawner.new(world, WarningBoard.new(world))
	var cyclist := Shipped.rows().by_id("cyclist")
	for _i in 5:
		spawner.rolls_a_pelican(cyclist)
	t.check(run.pelican().draws() == 5, "five cyclists draw five marbles from the handed run's bag")
	spawner.rolls_a_pelican(Shipped.rows().by_id("loose_dog"))
	t.check(run.pelican().draws() == 5, "a dog draws nothing")

func _test_a_door_says_what_it_does_to_her_and_moves_nobody(t: TestRunner) -> void:
	var parts := _parts(t)
	var made: Array = []
	var spawn := func(def: EventDef, at: Vector2) -> EventInstance:
		made.append([def, at])
		return null
	var doors := CheckpointController.new(parts.world, spawn,
			Shipped.rows().door_guard(),
			Shipped.rows().charger_timing().warning())
	# A post is a plan the day's streaming brings in once she is near (`EventStreaming.add()`).
	var post_at := Vector2(3000.0, 3000.0)
	var post_plan := EventPlan.new(Shipped.rows().by_id("checkpoint_post"), post_at)
	parts.streaming.add(post_plan)
	parts.streaming.stream_around(post_at)
	var hut := parts.streaming.event_of(post_plan)
	var her := _her(t)
	her.global_position = hut.global_position + Vector2(0.0, 4.0)
	parts.world.use_player(her)
	var said: Array = []
	doors.takes_her_in.connect(func(at: Vector2) -> void: said.append(["in", at]))
	doors.holds_her.connect(func(seconds: float) -> void: said.append(["hold", seconds]))
	doors.lets_her_out.connect(func(at: Vector2) -> void: said.append(["out", at]))
	var standing := her.global_position
	parts.world.where_she_is().tell(standing)
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
	parts.world.use_player(null)
	her.free()
	parts.free_all()

func _test_the_manager_sees_her_only_once_she_is_handed_in(t: TestRunner) -> void:
	var holder := WorldContext.new()
	t.add_child(holder)
	var map := CityMap.new()
	var run := RunState.new()
	var manager := EventManager.new(EventSurroundings.new().reading(Shipped.rows())
			.on(map).drawn_in(holder))
	manager.setup(run)
	t.add_child(manager)
	var def := Shipped.rows().by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var plan := EventPlan.new(def, at)
	manager.walk_events().take([plan] as Array[EventPlan])
	var her := _her(t)
	# Off the robber's own heading and beyond his notice, so he stands as he was sited, and the side
	# a man would get out of him on is hers once he knows where she is
	# (`where_its_officer_may_get_out()`).
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
	var door := event.where_its_officer_may_get_out(row, 0, 1)[0] - event.global_position
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
		return [Shipped.rows().by_id("charging_dog"),
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
	var world := EventWorld.new(EventSurroundings.new().reading(Shipped.rows())
			.in_the_city(map)
			.tracing_to(RecordingTrace.new(told)))
	var walk := WalkEvents.new()
	var board := _CountingBoard.new(world)
	var spawner := EventSpawner.new(world, WarningBoard.new(world))
	var streaming := EventStreaming.new(world, spawner, walk)
	var lesson := EventsAhead.new(world, streaming, spawner, board, walk)
	var director := _RetryDirector.new(Shipped.rows(), map)
	lesson.use_director(director, null)
	var body := CharacterBody2D.new()
	body.velocity = Vector2.RIGHT * Tuning.WALK_SPEED
	world.use_player(body)
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
	var world := EventWorld.new(EventSurroundings.new().reading(Shipped.rows()))
	var board := WarningBoard.new(world)
	var rig := _her(t)
	world.use_player(rig)
	rig.global_position = Vector2(1000.0, 1000.0)

	# An ordinary telegraphing event, right on top of her. It costs her the meter and says so
	# through the meter; it is not an instruction.
	var ordinary := _a_live(Shipped.rows().by_id("dog_walker"), rig.global_position)
	world.take_in(ordinary)
	board.warn_about_the_ground_she_is_on()
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"a dog walker whose radius covers her raises nothing over her head")

	# A lethal one, still telegraphing: the contract is now about her and the clock has started.
	var lethal := _a_live(Shipped.rows().by_id("abduction"), rig.global_position)
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
	# The doubled mark raised above is the board's own, and hers to take down as she leaves.
	rig.stand_down(WarningBoard.WARNING_SOURCE)
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
