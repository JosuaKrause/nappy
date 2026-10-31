extends RefCounted
## The parts a day's events are handed to, each driven on its own through the one `EventWorld` it
## is handed rather than through `EventManager`: `EventStreaming` bringing a plan in and out with its
## state, `WarningBoard` creating what a warning was for once its time is up or withdrawing it,
## `EventSpawner` recording a scar once and drawing the pelican bag of the run it is handed, and
## `CheckpointController` saying what a door does to her as intents rather than moving her. And the
## manager seeing her once she is handed in, never by looking her up.

const STEP := 0.1

func run(t) -> void:
	_test_streaming_carries_a_plan_out_and_back_on_its_own(t)
	_test_a_warning_creates_its_row_once_its_time_is_up(t)
	_test_a_warning_with_nowhere_to_put_it_is_withdrawn(t)
	_test_a_scar_is_recorded_once_however_often_it_streams_in(t)
	_test_the_pelican_bag_is_the_handed_runs(t)
	_test_a_door_says_what_it_does_to_her_and_moves_nobody(t)
	_test_the_manager_sees_her_only_once_she_is_handed_in(t)

## An `EventWorld` on fresh open ground drawn in `holder`, belonging to the live run.
func _world(t) -> EventWorld:
	var holder := WorldContext.new()
	t.add_child(holder)
	var world := EventWorld.new()
	world.map = CityMap.new()
	world.map.world = holder
	world.run = GameState
	return world

## A Stroller with the camera it looks up by path, in the tree, its physics stepped by nobody.
func _her(t) -> Stroller:
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	her.add_child(camera)
	t.add_child(her)
	her.set_physics_process(false)
	return her

func _free_world(world: EventWorld) -> void:
	for instance in world.instances:
		if is_instance_valid(instance):
			instance.free()
	world.instances.clear()
	if world.map.has_world():
		world.map.world.free()

func _test_streaming_carries_a_plan_out_and_back_on_its_own(t) -> void:
	var world := _world(t)
	var spawner := EventSpawner.new(world, WarningBoard.new(world))
	var streaming := EventStreaming.new(world, spawner)
	var def := EventCatalogue.by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var plan := EventScheduler.Planned.new(def, at)
	var plans: Array[EventScheduler.Planned] = [plan]
	streaming.take(plans)
	streaming.stream_around(at)
	t.check(plan.live != null and world.instances.has(plan.live),
			"within reach, the plan is streamed in and joins the world's live instances")
	if plan.live == null:
		_free_world(world)
		return
	plan.live.player_at = at + Vector2(def.notice.within - 10.0, 0.0)
	for _i in 3:
		plan.live.step(STEP)
	var age := plan.live.age
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	var leaving := plan.live
	streaming.stream_around(far)
	t.check(plan.live == null and not world.instances.has(leaving),
			"out of reach, it is streamed out and leaves the live instances")
	t.close_to(plan.age, age, "its plan keeps how far it had run")
	t.check(plan.behaviours.has(&"EventPursuit"), "and its pursuit's state")
	streaming.stream_around(at)
	t.check(plan.live != null, "back within reach, it is streamed in again")
	if plan.live:
		t.close_to(plan.live.age, age, "picking up where it left off")
	streaming.clear()
	t.check(plan.live == null and streaming.plans().is_empty(), "cleared, the day's plan is gone")
	if is_instance_valid(leaving):
		leaving.free()
	_free_world(world)

func _test_a_warning_creates_its_row_once_its_time_is_up(t) -> void:
	var world := _world(t)
	var board := WarningBoard.new(world)
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
	_free_world(world)

func _test_a_warning_with_nowhere_to_put_it_is_withdrawn(t) -> void:
	var world := _world(t)
	var board := WarningBoard.new(world)
	var def := EventCatalogue.by_id("cyclist")
	var asked := [0]
	var where := func(_her: Vector2) -> Vector2:
		asked[0] += 1
		return Vector2(800.0, 0.0) if asked[0] == 1 else Vector2.INF
	var arrive := func(_at: Vector2, _her: Vector2) -> bool: return true
	var withdrawn := [false]
	var warning := board.warn_first(def, Vector2.ZERO, where, arrive)
	warning.on_withdrawn = func() -> void: withdrawn[0] = true
	for _i in 60:
		board.run(STEP, Vector2.ZERO)
	t.check(warning.withdrawn and withdrawn[0] and board.pending_warnings().is_empty(),
			"a warning whose ground has no place for its row when its time is up is withdrawn, " +
			"and its caller is told")
	t.check(board.warn_first(def, Vector2.ZERO, func(_her: Vector2) -> Vector2: return Vector2.INF,
			arrive) == null and board.pending_warnings().is_empty(),
			"and one with no place at all is never put up")
	_free_world(world)

func _test_a_scar_is_recorded_once_however_often_it_streams_in(t) -> void:
	var world := _world(t)
	var spawner := EventSpawner.new(world, WarningBoard.new(world))
	var streaming := EventStreaming.new(world, spawner)
	var def := EventCatalogue.by_id("burning_building")
	t.check(def.aftermath.scar != "", "the fire leaves a scar")
	var scars_before := GameState.attempt_spend.scars.duplicate()
	var at := Vector2(6000.0, 6000.0)
	var plan := EventScheduler.Planned.new(def, at)
	var plans: Array[EventScheduler.Planned] = [plan]
	streaming.take(plans)
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	for _i in 3:
		streaming.stream_around(at)
		streaming.stream_around(far)
	var added := GameState.attempt_spend.scars.size() - scars_before.size()
	t.check(added == 1, "three times in and out records the fire's scar once (%d)" % added)
	GameState.attempt_spend.scars = scars_before
	_free_world(world)

func _test_the_pelican_bag_is_the_handed_runs(t) -> void:
	var world := EventWorld.new()
	var run := RunState.new()
	run.header.run_seed = 4242
	world.run = run
	var spawner := EventSpawner.new(world, WarningBoard.new(world))
	var cyclist := EventCatalogue.by_id("cyclist")
	var draws := GameState.pelican.draws
	for _i in 5:
		spawner.rolls_a_pelican(cyclist)
	t.check(run.pelican.draws == 5, "five cyclists draw five marbles from the handed run's bag")
	t.check(GameState.pelican.draws == draws, "and none from the game's own run")
	spawner.rolls_a_pelican(EventCatalogue.by_id("loose_dog"))
	t.check(run.pelican.draws == 5, "a dog draws nothing")
	run.free()

func _test_a_door_says_what_it_does_to_her_and_moves_nobody(t) -> void:
	var world := _world(t)
	var made: Array = []
	var spawn := func(def: EventDef, at: Vector2) -> EventInstance:
		made.append([def, at])
		return null
	var doors := CheckpointController.new(world, spawn, EventBus, EventCatalogue.door_guard())
	var hut := EventInstance.new()
	hut.setup(EventCatalogue.by_id("checkpoint_post"), Vector2(3000.0, 3000.0), PackedVector2Array(),
			Vector2.RIGHT, world.map)
	world.map.add_entity(hut)
	world.instances.append(hut)
	var her := _her(t)
	her.global_position = hut.global_position + Vector2(0.0, 4.0)
	world.player = her
	var said: Array = []
	doors.takes_her_in.connect(func(at: Vector2) -> void: said.append(["in", at]))
	doors.holds_her.connect(func(seconds: float) -> void: said.append(["hold", seconds]))
	doors.lets_her_out.connect(func(at: Vector2) -> void: said.append(["out", at]))
	var standing := her.global_position
	hut.player_at = standing
	doors.check_detentions()
	t.check(said.size() == 2 and said[0][0] == "in" and said[0][1] == hut.global_position
			and said[1][0] == "hold" and is_equal_approx(said[1][1], hut.def.detain_seconds),
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
	her.free()
	_free_world(world)

func _test_the_manager_sees_her_only_once_she_is_handed_in(t) -> void:
	var holder := WorldContext.new()
	t.add_child(holder)
	var manager := EventManager.new()
	manager.world.map = CityMap.new()
	manager.world.map.world = holder
	manager.use_run(GameState)
	t.add_child(manager)
	var def := EventCatalogue.by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var plan := EventScheduler.Planned.new(def, at)
	manager.streaming.take([plan] as Array[EventScheduler.Planned])
	var her := _her(t)
	her.global_position = at
	manager._physics_process(STEP)
	t.check(plan.live == null,
			"a player in the tree's `player` group but never handed in is nobody the events see")
	manager.use_player(her)
	manager._physics_process(STEP)
	t.check(plan.live != null and plan.live.player_at == at,
			"handed in, the events around her stream in and are told where she is")
	# Stood aside for the title, she is handed in and still nobody the events see.
	her.stand_aside()
	plan.live.player_at = Vector2.ZERO
	manager._physics_process(STEP)
	t.check(not manager.world.has_player() and plan.live.player_at == Vector2.ZERO,
			"stood aside for the title, she is told nothing and nothing can strike her")
	manager.use_player(null)
	manager.free()
	her.free()
	holder.free()
