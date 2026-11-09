@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The parts a day's events are handed to, each driven on its own, as the `EventManager` that owns
## it holds it (`streaming`, `spawner`, `warnings`) over the one `EventWorld` the manager hands every
## part, rather than through the manager's tick: `EventStreaming` bringing a plan in and out with its
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
	await _test_the_manager_sees_her_only_once_she_is_handed_in(t)

## A manager handed a map drawn in a world node and a run of its own (`EventManager.setup_world()`,
## the entry the escape's building is handed its world through), out of the tree so that nothing
## ticks it: the parts under test are its own (`streaming`, `spawner`, `warnings`) and its `world`
## is the one every part is handed. `_free_manager()` frees it with the node.
func _manager(t) -> EventManager:
	var holder := WorldContext.new()
	t.add_child(holder)
	var map := CityMap.new()
	map.world = holder
	var run := RunState.new()
	var manager := EventManager.new()
	manager.setup_world(map, run)
	return manager

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

func _free_manager(manager: EventManager) -> void:
	var holder := manager.world.map.world
	manager.free()
	holder.free()

func _test_streaming_carries_a_plan_out_and_back_on_its_own(t) -> void:
	var manager := _manager(t)
	var streaming := manager.streaming
	var def := EventCatalogue.by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var plan := EventScheduler.Planned.new(def, at)
	var plans: Array[EventScheduler.Planned] = [plan]
	manager.walk_events().take(plans)
	streaming.stream_around(at)
	t.check(plan.live != null and manager.instances().has(plan.live),
			"within reach, the plan is streamed in and joins the world's live instances")
	if plan.live == null:
		_free_manager(manager)
		return
	plan.live.player_at = at + Vector2(def.notice.within - 10.0, 0.0)
	for _i in 3:
		plan.live.step(STEP)
	var age := plan.live.age
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	var leaving := plan.live
	streaming.stream_around(far)
	t.check(plan.live == null and not manager.instances().has(leaving),
			"out of reach, it is streamed out and leaves the live instances")
	t.close_to(plan.age, age, "its plan keeps how far it had run")
	t.check(plan.behaviours.has(&"EventPursuit"), "and its pursuit's state")
	streaming.stream_around(at)
	t.check(plan.live != null, "back within reach, it is streamed in again")
	if plan.live:
		t.close_to(plan.live.age, age, "picking up where it left off")
	streaming.clear()
	t.check(plan.live == null and manager.walk_events().plans().is_empty(),
			"cleared, the day's plan is gone")
	_free_manager(manager)

func _test_a_warning_creates_its_row_once_its_time_is_up(t) -> void:
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

func _test_a_warning_with_nowhere_to_put_it_is_withdrawn(t) -> void:
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
	warning.on_withdrawn = func() -> void: withdrawn[0] = true
	for _i in 60:
		board.run(STEP, Vector2.ZERO)
	t.check(warning.withdrawn and withdrawn[0] and board.pending_warnings().is_empty(),
			"a warning whose ground has no place for its row when its time is up is withdrawn, " +
			"and its caller is told")
	t.check(board.warn_first(def, Vector2.ZERO, func(_her: Vector2) -> Vector2: return Vector2.INF,
			arrive) == null and board.pending_warnings().is_empty(),
			"and one with no place at all is never put up")
	_free_manager(manager)

func _test_a_scar_is_recorded_once_however_often_it_streams_in(t) -> void:
	var manager := _manager(t)
	var streaming := manager.streaming
	var def := EventCatalogue.by_id("burning_building")
	t.check(def.aftermath.scar != "", "the fire leaves a scar")
	t.check(manager.world.run.attempt_spend.scars.is_empty(), "and the run starts with none")
	var at := Vector2(6000.0, 6000.0)
	var plan := EventScheduler.Planned.new(def, at)
	var plans: Array[EventScheduler.Planned] = [plan]
	manager.walk_events().take(plans)
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	for _i in 3:
		streaming.stream_around(at)
		streaming.stream_around(far)
	var added := manager.world.run.attempt_spend.scars.size()
	t.check(added == 1, "three times in and out records the fire's scar once (%d)" % added)
	_free_manager(manager)

func _test_the_pelican_bag_is_the_handed_runs(t) -> void:
	var manager := EventManager.new()
	var run := RunState.new()
	run.header.run_seed = 4242
	manager.use_run(run)
	var spawner := manager.spawner
	var cyclist := EventCatalogue.by_id("cyclist")
	for _i in 5:
		spawner.rolls_a_pelican(cyclist)
	t.check(run.pelican.draws == 5, "five cyclists draw five marbles from the handed run's bag")
	spawner.rolls_a_pelican(EventCatalogue.by_id("loose_dog"))
	t.check(run.pelican.draws == 5, "a dog draws nothing")
	manager.free()

func _test_a_door_says_what_it_does_to_her_and_moves_nobody(t) -> void:
	var manager := _manager(t)
	var made: Array = []
	var spawn := func(def: EventDef, at: Vector2) -> EventInstance:
		made.append([def, at])
		return null
	var doors := CheckpointController.new(manager.world, spawn, EventBus, EventCatalogue.door_guard())
	# A post is a plan the day's streaming brings in once she is near (`EventStreaming.add()`).
	var post_at := Vector2(3000.0, 3000.0)
	var post_plan := EventScheduler.Planned.new(EventCatalogue.by_id("checkpoint_post"), post_at)
	manager.streaming.add(post_plan)
	manager.streaming.stream_around(post_at)
	var hut := post_plan.live
	var her := _her(t)
	her.global_position = hut.global_position + Vector2(0.0, 4.0)
	manager.use_player(her)
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
	manager.use_player(null)
	her.free()
	_free_manager(manager)

func _test_the_manager_sees_her_only_once_she_is_handed_in(t) -> void:
	var holder := WorldContext.new()
	t.add_child(holder)
	var map := CityMap.new()
	map.world = holder
	var run := RunState.new()
	var manager := EventManager.new()
	manager.setup_world(map, run)
	t.add_child(manager)
	var def := EventCatalogue.by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var plan := EventScheduler.Planned.new(def, at)
	manager.walk_events().take([plan] as Array[EventScheduler.Planned])
	var her := _her(t)
	her.global_position = at
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check(plan.live == null,
			"a player in the tree's `player` group but never handed in is nobody the events see")
	manager.use_player(her)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check(plan.live != null and plan.live.player_at == at,
			"handed in, the events around her stream in and are told where she is")
	# Stood aside for the title, she is handed in and still nobody the events see.
	her.stand_aside()
	# A position that is neither hers nor the default, so a manager that told the events anything
	# about her, or reset what they hold, shows in it; the check above is what proves frames run.
	var untold := Vector2(7.0, 7.0)
	plan.live.player_at = untold
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check(not manager.world.has_player() and plan.live.player_at == untold,
			"stood aside for the title, she is told nothing and nothing can strike her")
	manager.use_player(null)
	manager.free()
	her.free()
	holder.free()
