extends RefCounted
## The behaviours an event is composed of (`EventBehaviours.compose()`): which a row gets, and that
## each one's own state survives a stream-out — saved off one instance (`save_behaviours()`), put
## back on a fresh one of the same row after `resume()` (`restore_behaviours()`), and then the same
## state and the same next tick. One test per behaviour that keeps state, one for the route walk,
## which keeps none of its own, and one through the manager's own streaming.

const STEP := 0.1

func run(t) -> void:
	_test_a_row_is_composed_of_what_its_data_says(t)
	_test_the_pursuit_round_trips(t)
	_test_the_masked_mans_warning_round_trips(t)
	_test_the_masked_man_waits_again_once_she_leaves_after_his_warning_ran(t)
	_test_the_hold_round_trips(t)
	_test_the_flock_round_trips(t)
	_test_the_investigation_round_trips(t)
	_test_the_officer_round_trips(t)
	_test_the_departure_round_trips(t)
	_test_the_unreachable_dog_round_trips(t)
	_test_the_take_round_trips(t)
	_test_the_route_walk_has_no_state_of_its_own(t)
	_test_the_manager_streams_a_behaviours_state(t)

## An instance of `def` out of the tree, stepped by hand: nothing here draws.
func _instance(_t, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

## A fresh instance of `first`'s row and path, put back where `first` had got to as
## `EventManager._stream_in()` does; checks its saved state comes back whole.
func _round_trip(t, first: EventInstance, what: String) -> EventInstance:
	var state := first.save_behaviours()
	t.check(not state.is_empty(), "%s: there is state to carry" % what)
	var second := _instance(t, first.def, first.global_position, first.path)
	second.resume(first.age, first.path_travelled(), first.noticed_at())
	second.restore_behaviours(state)
	t.check(second.save_behaviours() == state,
			"%s: streamed back in, every behaviour's state is what was saved" % what)
	return second

# ----------------------------------------------------------------- composition ---

func _test_a_row_is_composed_of_what_its_data_says(t) -> void:
	var robber := _instance(t, EventCatalogue.by_id("alley_robbery"))
	t.check(robber.pursuit != null and robber.on_foot != null and robber.notice_run == null,
			"a pursuer chases and has a man's stop; it does not run a line of its own")
	var masked := _instance(t, EventCatalogue.by_id("masked_pursuer"))
	t.check(masked.notice_run != null and masked.pursuit == null,
			"the masked man waits and runs his line, and does not chase")
	var flock := _instance(t, EventCatalogue.by_id("pigeon_flock"))
	t.check(flock.flock != null and flock.notice_run != null,
			"a flock has its birds and waits for her, both")
	var mother := _instance(t, EventCatalogue.by_id("chatting_mother"))
	t.check(mother.hold != null and mother.pursuit == null, "a mother holds her and does not chase")
	for one in [robber, masked, flock, mother]:
		t.check(one.departure != null, "%s can leave" % one.def.id)
		one.free()

# -------------------------------------------------------------------- pursuit ---

func _test_the_pursuit_round_trips(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var first := _instance(t, def)
	first.player_at = Vector2(def.notice.within - 10.0, 0.0)
	_advance(first, 0.3)
	t.check(first.phase == EventInstance.Phase.WARNING, "the robber has noticed her")
	first.pursuit.lunge_held = true
	first.pursuit.outrun_for = 0.4
	var second := _round_trip(t, first, "pursuit")
	t.check(second.pursuit.lunge_held and is_equal_approx(second.pursuit.outrun_for, 0.4),
			"his held lunge and his running clock come back")
	t.check(second.phase == EventInstance.Phase.WARNING, "and he is still warning")
	first.free()
	second.free()

## Stood inside his run distance as he notices her, he runs once his warning has run, and one
## streamed out half way through it runs on the same tick as one that never left.
func _test_the_masked_mans_warning_round_trips(t) -> void:
	var def := EventCatalogue.by_id("masked_pursuer")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -600.0)])
	var her := Vector2(def.notice.runs_within - 20.0, 0.0)
	var first := _instance(t, def, Vector2.ZERO, path)
	first.player_at = her
	_advance(first, 0.5)
	t.check(first.phase == EventInstance.Phase.WARNING, "inside his run distance, he warns first")
	var second := _round_trip(t, first, "the masked man's warning")
	second.player_at = her
	var first_ran := -1
	var second_ran := -1
	for i in int(Tuning.WARNING_ALONE_MAX / STEP) + 3:
		first._process(STEP)
		second._process(STEP)
		if first_ran < 0 and first.phase == EventInstance.Phase.ACTIVE:
			first_ran = i
		if second_ran < 0 and second.phase == EventInstance.Phase.ACTIVE:
			second_ran = i
	t.check(first_ran >= 0, "he runs once his warning has run")
	t.check(second_ran == first_ran,
			"and streamed back in he runs on the same tick (%d, %d)" % [first_ran, second_ran])
	first.free()
	second.free()

## His warning, run out with her outside his run distance, is still called off by her leaving his
## notice: he waits again rather than standing warning for ever.
func _test_the_masked_man_waits_again_once_she_leaves_after_his_warning_ran(t) -> void:
	var def := EventCatalogue.by_id("masked_pursuer")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -600.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)
	instance.player_at = Vector2((def.notice.runs_within + def.notice.within) * 0.5, 0.0)
	_advance(instance, Tuning.WARNING_ALONE_MAX + 0.5)
	t.check(instance.phase == EventInstance.Phase.WARNING,
			"outside his run distance he is still warning after his warning's length")
	instance.player_at = Vector2(def.notice.within + 50.0, 0.0)
	instance._process(STEP)
	t.check(instance.phase == EventInstance.Phase.WAITING and instance.is_waiting(),
			"she leaving his notice has him wait again")
	instance.free()

# ----------------------------------------------------------------------- hold ---

func _test_the_hold_round_trips(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(2000.0, 2000.0)
	var first := _instance(t, def, at, PackedVector2Array([at, at + Vector2(256.0, 0.0)]))
	first.start_chat()
	_advance(first, 0.5)
	t.check(first.is_chatting() and first.has_chatted(), "the conversation is under way")
	var second := _round_trip(t, first, "hold")
	t.check(second.has_chatted(), "streamed back in, she has already held her")
	first.free()
	second.free()

# ---------------------------------------------------------------------- flock ---

func _test_the_flock_round_trips(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var first := _instance(t, def)
	first.player_at = Vector2(def.notice.within - 10.0, 0.0)
	_advance(first, def.telegraph_time + 1.0)
	var second := _round_trip(t, first, "flock")
	t.check(second.flock.offsets() == first.flock.offsets(), "every bird comes back where it was")
	t.check(second.flock.velocities() == first.flock.velocities(), "and going the way it was")
	first.free()
	second.free()

# -------------------------------------------------------------- investigation ---

func _test_the_investigation_round_trips(t) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"), Tuning.RESISTANCE_GOAL)
	var first := _instance(t, hot)
	first.age = 2.0
	first.investigation._seen_her = true
	first.investigation._investigated = true
	first.investigation._officers_owed = 1
	var second := _round_trip(t, first, "investigation")
	t.check(second.officers_owed() == 1, "the man it still owes comes back with it")
	first.free()
	second.free()

# -------------------------------------------------------------------- officer ---

func _test_the_officer_round_trips(t) -> void:
	var first := _instance(t, EventCatalogue.by_id("policeman_giving_chase"))
	first.age = 3.0
	first.on_foot.trail = PackedVector2Array([Vector2(10.0, 0.0), Vector2(20.0, 0.0)])
	first.on_foot._stopped_her_at = 2.0
	var second := _round_trip(t, first, "officer")
	t.check(second.on_foot.trail == first.on_foot.trail, "his trail back comes back")
	t.check(second.has_stopped_her() and is_equal_approx(second.on_foot.stopped_for(), 1.0),
			"and so does his stop, as far into it")
	first.free()
	second.free()

# ------------------------------------------------------------------ departure ---

func _test_the_departure_round_trips(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	var first := _instance(t, def)
	first.player_at = Vector2(200.0, 0.0)
	first.age = 1.0
	first.give_up_the_chase()
	t.check(first.is_leaving, "given up, the dog leaves")
	_advance(first, 0.5)
	var second := _round_trip(t, first, "departure")
	first.free()
	second.free()

# ---------------------------------------------------------------- unreachable ---

func _test_the_unreachable_dog_round_trips(t) -> void:
	var def := EventCatalogue.by_id("loose_dog")
	var first := _instance(t, def)
	t.check(first.unreachable != null, "the loose dog is retired once it cannot reach her")
	first.player_at = Vector2(Tuning.OUT_OF_SIGHT + 400.0, 0.0)
	first.unreachable._look_clock = 0.3
	first.unreachable._gap_looked_at = Tuning.OUT_OF_SIGHT + 380.0
	first.unreachable._not_closing_for = 1.0
	var second := _round_trip(t, first, "unreachable")
	first.free()
	second.free()

# ----------------------------------------------------------------------- take ---

func _test_the_take_round_trips(t) -> void:
	var def := EventCatalogue.by_id("abduction")
	var first := _instance(t, def)
	first.player_at = Vector2(def.outer_radius - 20.0, 0.0)
	_advance(first, 0.5)
	t.check(first.is_taking_a_victim(), "she is close, and the take is under way")
	var second := _round_trip(t, first, "take")
	t.check(second.is_taking_a_victim(), "streamed back in, it is still under way")
	first.free()
	second.free()

# ----------------------------------------------------------------- route walk ---

## The route and how far along it are the event's own body, which `resume()` carries; the walk
## itself keeps nothing.
func _test_the_route_walk_has_no_state_of_its_own(t) -> void:
	var def := EventCatalogue.by_id("dog_walker")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	var first := _instance(t, def, Vector2.ZERO, path)
	_advance(first, def.telegraph_time + 2.0)
	t.check(first.route.save().is_empty(), "the route walk saves nothing of its own")
	var second := _instance(t, def, Vector2.ZERO, path)
	second.resume(first.age, first.path_travelled(), first.noticed_at())
	t.check(second.global_position.is_equal_approx(first.global_position),
			"resumed, it stands where it had walked to")
	first.free()
	second.free()

# ------------------------------------------------------------------ streaming ---

## Through `EventManager`'s own streaming on a plan, the way a day puts it in the world: what the
## behaviours saved going out is on the plan, and comes back on the instance that streams in.
func _test_the_manager_streams_a_behaviours_state(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var world := WorldContext.new()
	t.add_child(world)
	var manager := EventManager.new()
	manager._map = CityMap.new()
	manager._map.world = world
	t.add_child(manager)
	var plan := EventScheduler.Planned.new(def, at)
	manager._plans = [plan] as Array[EventScheduler.Planned]
	manager.stream_around(at)
	var robber := plan.live
	t.check(robber != null, "he is streamed in where the day planned him")
	if robber == null:
		manager.free()
		world.free()
		return
	robber.player_at = at + Vector2(def.notice.within - 10.0, 0.0)
	_advance(robber, 0.3)
	robber.pursuit.lunge_held = true
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	manager.stream_around(far)
	t.check(plan.live == null and plan.behaviours.has(&"EventPursuit"),
			"streamed out, his plan carries his pursuit's state")
	manager.stream_around(at)
	t.check(plan.live != null and plan.live.pursuit.lunge_held,
			"and streamed back in, his lunge is still held")
	manager.free()
	world.free()
