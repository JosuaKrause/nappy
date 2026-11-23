extends RefCounted
## What the live event and the event manager hand the crowd's separation pass: the move each
## figure puts on its map's list (`WorldMap.moves`), which the pass reads and never the event
## behind it. A row's body's `is_walked_round()` and `parks()` reaching its move, an event
## leaving the list where it goes, and a placement not being a walk. The crowd's own half, how a
## walker and a car answer a move, is `test_crowd_yields.gd`'s, which puts moves on the list by
## hand. A real `EventInstance` and a real `EventManager` are built here because they are what
## is under test; each stands on a map of its own, never a city.

const SEED := 4242

func run(t: TestRunner) -> void:
	_test_a_row_hands_what_it_stands_as_to_its_move(t)
	_test_a_row_hands_whether_it_has_parked_to_its_move(t)
	_test_an_event_leaves_the_list_of_moves_where_it_goes(t)
	_test_a_placement_is_not_a_walk(t)

# ------------------------------------------------------- what a figure is ---

## An event of the row `id` set up over a map of its own (`EventInstance.setup()`'s map argument, as
## `EventSpawner.create()` hands it) and put in the tree, where it joins its move to that map's list as
## it does in the game (`EventInstance._enter_tree()`). The move is what the crowd's separation pass
## reads off the list (`ProposedMoves.keeping_their_course()`), so it is read there and not off the
## instance. `move` is null when the list does not hold exactly the one move.
func _a_row_on_a_map(t: TestRunner, id: String) -> Dictionary:
	var map := WorldMap.open_ground()
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id(id), Vector2(100.0, 100.0), PackedVector2Array(),
			Vector2.RIGHT,
			EventSurroundings.new().on(map) \
				.drawing_nothing())
	t.add_child(instance)
	var listed := map.moves.keeping_their_course()
	return {"instance": instance, "map": map,
			"move": listed[0] if listed.size() == 1 and map.moves.size() == 1 else null}

## **A row's body's `is_walked_round()` reaches its move** (`EventInstance.setup()`): the patrol car, a vehicle, is
## walked round while it stands; the charging dog, an animal, is not, so the dog waiting on the map
## before its charge may be walked through, as the player allowed. One row of each answer shows the
## declaration is handed over rather than fixed. That every row declares it is
## `EventDef.validate()`'s refusal to load without.
func _test_a_row_hands_what_it_stands_as_to_its_move(t: TestRunner) -> void:
	var expected := {"police_patrol": true, "charging_dog": false}
	for id: String in expected:
		var rig := _a_row_on_a_map(t, id)
		var move: MoveProposal = rig["move"]
		t.check(move != null, "%s puts one move on its map's list" % id)
		if move != null:
			t.check(move.is_walked_round() == expected[id],
					"%s's move says a walker goes round it while it stands: %s" % [id, expected[id]])
		var instance: EventInstance = rig["instance"]
		instance.free()

## **Each row's body's `parks()` reaches its move as whether it has parked** (`EventInstance`, inbox #909 in freckled-moose):
## a stall, which never moves, has parked from the start; the fire engine has not while it
## drives and has once it stops at its fire, and not once it leaves; the patrol car and the charging
## dog go on, so never. That every row declares it is `EventDef.validate()`'s refusal to load
## without.
func _test_a_row_hands_whether_it_has_parked_to_its_move(t: TestRunner) -> void:
	var stall := _a_row_on_a_map(t, "market_stall")
	var stall_move: MoveProposal = stall["move"]
	t.check(stall_move != null and stall_move.has_parked(),
			"a stall, which never moves, has parked from the start")
	var stall_instance: EventInstance = stall["instance"]
	stall_instance.free()
	var engine := _a_row_on_a_map(t, "fire_truck")
	var engine_move: MoveProposal = engine["move"]
	var engine_instance: EventInstance = engine["instance"]
	t.check(engine_move != null and not engine_move.has_parked(), "the fire engine has not parked while it drives")
	engine_instance.transition(EventInstance.Phase.PARKED)
	t.check(engine_move != null and engine_move.has_parked(),
			"and has once it stops at its fire")
	engine_instance.transition(EventInstance.Phase.LEAVING)
	t.check(engine_move != null and not engine_move.has_parked(),
			"and nothing leaving has parked")
	engine_instance.free()
	for id: String in ["police_patrol", "charging_dog"]:
		var rig := _a_row_on_a_map(t, id)
		var instance: EventInstance = rig["instance"]
		instance.transition(EventInstance.Phase.PARKED)
		var move: MoveProposal = rig["move"]
		t.check(move != null and not move.has_parked(), "%s goes on, so it never reads as parked" % id)
		instance.free()

# -------------------------------------------------- the list of moves keeps up ---

## An event manager over a bare map, with `alley_robbery` planned at `at` and streamed in: the rig
## `test_event_behaviours.gd` streams a plan with. The manager is set up as the escape's building
## is (`EventSurroundings.on()` a map, then `EventManager.setup()` a run of its own, here a fresh
## `RunState`), the plan joins the day's as one planned after dawn does (`EventStreaming.add()`,
## which the events ahead of her call) and is streamed in around `at`. `move` is the one move
## the streamed-in event put on the map's list.
func _a_manager_with_a_live_event(t: TestRunner, at: Vector2) -> Dictionary:
	var world := WorldContext.new()
	t.add_child(world)
	var run := RunState.new()
	run.start_run(SEED)
	var map := CityMap.new()
	var manager := EventManager.new(EventSurroundings.new().on(map).drawn_in(world))
	manager.setup(run)
	t.add_child(manager)
	var plan := EventPlan.new(EventCatalogue.by_id("alley_robbery"), at)
	manager.streaming.add(plan)
	manager.stream_around(at)
	var listed := map.moves.all()
	return {"world": world, "manager": manager, "plan": plan,
			"move": listed[0] if listed.size() == 1 else null}

func _free_the_manager(rig: Dictionary) -> void:
	var manager: EventManager = rig["manager"]
	var world: WorldContext = rig["world"]
	manager.free()
	world.free()

## **An event that goes leaves the list of moves at once** (minty-quail-34), not at the end of the
## frame when its node leaves the tree: a finished one, one streamed out, and every one `clear()`
## throws away. Nothing here ends a frame, as the probes' loops do not.
func _test_an_event_leaves_the_list_of_moves_where_it_goes(t: TestRunner) -> void:
	var at := Vector2(5000.0, 5000.0)
	var rig := _a_manager_with_a_live_event(t, at)
	var manager: EventManager = rig.manager
	var moves: ProposedMoves = manager.world.map().moves
	var live: EventInstance = manager.event_of(rig.plan)
	var move: MoveProposal = rig.move
	t.check(live != null and move != null and moves.has(move), "a streamed-in event is on the list")
	if live == null or move == null:
		_free_the_manager(rig)
		return
	live.transition(EventInstance.Phase.DONE)
	t.check(moves.has(move), "a finished event stays until the manager retires it")
	manager.streaming.retire_finished()
	t.check(not moves.has(move) and live.is_queued_for_deletion(),
			"retired once finished, it is off the list in the same call, with no frame between")
	_free_the_manager(rig)

	rig = _a_manager_with_a_live_event(t, at)
	manager = rig.manager
	moves = manager.world.map().moves
	live = manager.event_of(rig.plan)
	move = rig.move
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	manager.stream_around(far)
	var plan: EventPlan = rig.plan
	t.check(move != null and not plan.is_in_the_world() and not moves.has(move),
			"streamed out, it is off the list in the same call")
	_free_the_manager(rig)

	rig = _a_manager_with_a_live_event(t, at)
	manager = rig.manager
	moves = manager.world.map().moves
	move = rig.move
	t.check(move != null and moves.has(move), "a streamed-in event is on the list to be cleared")
	manager.clear()
	t.check(move != null and not moves.has(move) and moves.size() == 0,
			"EventManager.clear() empties the list (%d left)" % moves.size())
	_free_the_manager(rig)

## **A resting figure stood on other ground by hand is placed, not walked there**
## (`EventManager.move_extra()`, the task guard following her): the pass reads no velocity off a
## step longer than `SeparationPass.PLACEMENT_STEP`, and the figure does not count as under way.
func _test_a_placement_is_not_a_walk(t: TestRunner) -> void:
	var at := Vector2(5000.0, 5000.0)
	var rig := _a_manager_with_a_live_event(t, at)
	var manager: EventManager = rig.manager
	var moves: ProposedMoves = manager.world.map().moves
	var live: EventInstance = manager.event_of(rig.plan)
	var pass_over := SeparationPass.new(moves)
	var live_move: MoveProposal = rig.move
	t.check(live_move != null, "the streamed-in figure is on the list to be placed")
	if live_move == null:
		_free_the_manager(rig)
		return
	live_move.use_body_radius(EventInstance.FIGURE_RADIUS)
	pass_over.gather()
	manager.move_extra(live, at + Vector2(400.0, 0.0))
	pass_over.gather()
	t.check(pass_over.walker_keepers().is_empty() and not pass_over.has_keepers_for_cars(),
			"a 400px placement is no walk: no walker and no car gives way to the person put there")
	var walker := _a_figure_move_for_the_walk(moves, at)
	pass_over.gather()
	walker.place(at + Vector2(PLACEMENT_WALK, 0.0))
	pass_over.gather()
	for keeper in pass_over.walker_keepers():
		if keeper.move == walker:
			t.check(keeper.step == Vector2(PLACEMENT_WALK, 0.0) and keeper.ticks_still == 0,
					"a step under the placement limit is still a walk")
	_free_the_manager(rig)

const PLACEMENT_WALK := 8.0

func _a_figure_move_for_the_walk(moves: ProposedMoves, at: Vector2) -> MoveProposal:
	var move := MoveProposal.new()
	move.use_body_radius(EventInstance.FIGURE_RADIUS)
	moves.join(move, at)
	return move
