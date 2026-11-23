extends RefCounted
## The behaviours an event is composed of (`EventBehaviours.compose()`): that each one's own state
## survives a stream-out — saved off one instance (`save()`), put
## back on a fresh one of the same row (`restore()`), and then the same
## state and the same next tick. One test per behaviour that keeps state, one for the route walk,
## which keeps none of its own, and one through the manager's own streaming.

const STEP := 0.1

func run(t: TestRunner) -> void:
	_test_the_pursuit_round_trips(t)
	_test_a_robber_out_of_his_radius_keeps_waiting(t)
	_test_a_robber_who_notices_her_turns_to_face_her_exactly(t)
	_test_the_masked_mans_warning_round_trips(t)
	_test_the_masked_man_waits_again_once_she_leaves_after_his_warning_ran(t)
	_test_the_hold_round_trips(t)
	_test_the_flock_round_trips(t)
	_test_the_investigation_round_trips(t)
	_test_the_officer_round_trips(t)
	_test_the_departure_round_trips(t)
	_test_the_unreachable_dog_round_trips(t)
	_test_the_take_round_trips(t)
	_test_the_barrier_post_round_trips(t)
	_test_a_car_is_composed_of_its_vehicle(t)
	_test_the_route_walk_has_no_state_of_its_own(t)
	_test_a_departure_begun_on_resume_is_not_written_over(t)
	_test_the_manager_streams_a_behaviours_state(t)

## An instance of `def` out of the tree, stepped by hand: nothing here draws.
func _instance(_t: TestRunner, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array(), where: WhereSheIs = null) -> EventInstance:
	var instance := EventInstance.new()
	var surroundings := EventSurroundings.new()
	if where != null:
		surroundings.hearing(where)
	instance.setup(def, at, path, Vector2.RIGHT, surroundings)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance.step(STEP)

## A fresh instance of `first`'s row and path, put back where `first` had got to as
## `EventStreaming.stream_in()` does; checks the state names the behaviour under test (`behaviour`,
## its class name) and comes back whole. It hears where she is from `where`, as `first` may.
func _round_trip(t: TestRunner, first: EventInstance, what: String, behaviour: StringName,
		where: WhereSheIs = null) -> EventInstance:
	var state := first.save()
	t.check(not state.state_of(behaviour).is_empty(), "%s: there is state to carry" % what)
	var second := _instance(t, first.row(), first.global_position, first.walks(), where)
	second.restore(state)
	_check_the_same_save(t, second.save(), state,
			"%s: streamed back in" % what)
	return second

## Every behaviour that keeps state (each class with a `save()`), so a row composing several, such as a
## heated roadblock's barrier post and pursuit, has every one compared.
const STATEFUL := [
	"EventPursuit", "EventNoticeRun", "EventHold", "EventFlock", "EventInvestigation",
	"EventOfficer", "EventDeparture", "EventUnreachable", "EventAbduction", "EventBarrierPost",
]

## Whether `back` is `saved`: the same age, distance and notice, and the same state of every
## behaviour that keeps one.
func _check_the_same_save(t: TestRunner, back: EventSave, saved: EventSave, what: String) -> void:
	t.close_to(back.age(), saved.age(), "%s: its age is what was saved" % what, 0.0001)
	t.close_to(back.travelled(), saved.travelled(), "%s: so is its distance" % what, 0.0001)
	t.check(back.noticed_at() == saved.noticed_at(),
			"%s: and where it noticed her" % what)
	for behaviour: String in STATEFUL:
		t.check(back.state_of(behaviour) == saved.state_of(behaviour),
				"%s: and %s's state" % [what, behaviour])

# -------------------------------------------------------------------- pursuit ---

func _test_the_pursuit_round_trips(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	first_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	_advance(first, 0.3)
	t.check(first.phase == EventInstance.Phase.WARNING, "the robber has noticed her")
	# His held lunge is his own state, so it is set the one way the game sets it from outside: the
	# state a stream-out carries, put back (`EventPursuit.restore()`).
	var state := first.behaviours().pursuit().save()
	state["lunge_held"] = true
	state["outrun_for"] = 0.4
	first.behaviours().pursuit().restore(state)
	var second := _round_trip(t, first, "pursuit", &"EventPursuit")
	var carried := second.behaviours().pursuit().save()
	var run := second.behaviours().pursuit().outrun_for
	t.check(bool(carried["lunge_held"]) and is_equal_approx(run, 0.4),
			"his held lunge and his running clock come back")
	t.check(second.phase == EventInstance.Phase.WARNING, "and he is still warning")
	first.free()
	second.free()

## Stood inside his run distance as he notices her, he runs once his warning has run, and one
## streamed out half way through it runs on the same tick as one that never left.
func _test_the_masked_mans_warning_round_trips(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("masked_pursuer")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -600.0)])
	var her := Vector2(def.notice().runs_within() - 20.0, 0.0)
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, path, first_where)
	first_where.tell(her)
	_advance(first, 0.5)
	t.check(first.phase == EventInstance.Phase.WARNING, "inside his run distance, he warns first")
	var second := _round_trip(t, first, "the masked man's warning", &"EventNoticeRun",
			first_where)
	first_where.tell(her)
	var first_ran := -1
	var second_ran := -1
	for i in int(Tuning.WARNING_ALONE_MAX / STEP) + 3:
		first.step(STEP)
		second.step(STEP)
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
func _test_the_masked_man_waits_again_once_she_leaves_after_his_warning_ran(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("masked_pursuer")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -600.0)])
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, path, instance_where)
	instance_where.tell(Vector2((def.notice().runs_within() + def.notice_within()) * 0.5, 0.0))
	_advance(instance, Tuning.WARNING_ALONE_MAX + 0.5)
	t.check(instance.phase == EventInstance.Phase.WARNING,
			"outside his run distance he is still warning after his warning's length")
	instance_where.tell(Vector2(def.notice_within() + 50.0, 0.0))
	instance.step(STEP)
	t.check(instance.phase == EventInstance.Phase.WAITING and instance.is_waiting(),
			"she leaving his notice has him wait again")
	instance.free()

# ----------------------------------------------------------------------- hold ---

func _test_the_hold_round_trips(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(2000.0, 2000.0)
	var first := _instance(t, def, at, PackedVector2Array([at, at + Vector2(256.0, 0.0)]))
	first.start_chat()
	_advance(first, 0.5)
	t.check(first.is_chatting() and first.has_chatted(), "the conversation is under way")
	var second := _round_trip(t, first, "hold", &"EventHold")
	t.check(second.has_chatted(), "streamed back in, she has already held her")
	first.free()
	second.free()

# ---------------------------------------------------------------------- flock ---

## Built by hand on both, as `_ready()` builds them in the tree, and once they have flown: a
## restore that put nothing back leaves the second flock where `build()` scattered it.
func _test_the_flock_round_trips(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	first.behaviours().flock().build()
	t.check(first.birds().size() == def.flock().count(),
			"the flock has its %d birds" % def.flock().count())
	var scattered := first.flock_offsets()
	first_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	_advance(first, def.telegraphs_for() + 1.0)
	t.check(first.flock_offsets() != scattered, "and they have moved from where they were built")
	var state := first.save()
	var second := _instance(t, def, first.global_position, first.walks())
	second.behaviours().flock().build()
	t.check(second.flock_offsets() == scattered, "a fresh flock stands where the first was built")
	second.restore(state)
	_check_the_same_save(t, second.save(), state, "flock: streamed back in")
	t.check(second.flock_offsets() == first.flock_offsets(), "every bird comes back where it was")
	t.check(second.flock_velocities() == first.flock_velocities(), "and going the way it was")
	first.free()
	second.free()

# -------------------------------------------------------------- investigation ---

func _test_the_investigation_round_trips(t: TestRunner) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"), Tuning.RESISTANCE_GOAL)
	var first := _instance(t, hot)
	first.restore(EventSave.aged(2.0))
	var state := {"seen_her": true, "officers_owed": 1, "investigated": true, "left_her_once": true}
	first.behaviours().investigation().restore(state)
	var second := _round_trip(t, first, "investigation", &"EventInvestigation")
	t.check(second.behaviours().investigation().save() == state,
			"every field of its state survives the trip")
	t.check(second.officers_owed() == 1, "and it still owes its man")
	first.free()
	second.free()

# -------------------------------------------------------------------- officer ---

func _test_the_officer_round_trips(t: TestRunner) -> void:
	var first := _instance(t, EventCatalogue.by_id("policeman_giving_chase"))
	first.restore(EventSave.aged(3.0))
	var state := {"trail": PackedVector2Array([Vector2(10.0, 0.0), Vector2(20.0, 0.0)]),
			"stopped_ago": 1.0}
	first.behaviours().on_foot().restore(state)
	var second := _round_trip(t, first, "officer", &"EventOfficer")
	var man := second.behaviours().on_foot()
	t.check(man.save() == state, "every field of its state survives the trip")
	t.check(man.trail == first.behaviours().on_foot().trail, "his trail back comes back")
	t.check(second.has_stopped_her() and is_equal_approx(man.stopped_for(), 1.0),
			"and so does his stop, as far into it")
	first.free()
	second.free()

# ------------------------------------------------------------------ departure ---

func _test_the_departure_round_trips(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	first_where.tell(Vector2(200.0, 0.0))
	first.restore(EventSave.aged(1.0))
	first.give_up_the_chase()
	t.check(first.is_on_its_way_out(), "given up, the dog leaves")
	_advance(first, 0.5)
	var second := _round_trip(t, first, "departure", &"EventDeparture")
	first.free()
	second.free()

# ---------------------------------------------------------------- unreachable ---

func _test_the_unreachable_dog_round_trips(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("loose_dog")
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	first_where.tell(Vector2(Tuning.OUT_OF_SIGHT + 400.0, 0.0))
	var state := {"gap_looked_at": Tuning.OUT_OF_SIGHT + 380.0, "look_clock": 0.3,
			"not_closing_for": 1.0}
	first.restore(EventSave.new(0.0, 0.0, INF, {"EventUnreachable": state}))
	t.check(first.save().state_of("EventUnreachable") == state,
			"the loose dog carries the state of its unreachable behaviour")
	var second := _round_trip(t, first, "unreachable", &"EventUnreachable")
	t.check(second.save().state_of("EventUnreachable") == state,
			"every field of its state survives the trip")
	first.free()
	second.free()

# ----------------------------------------------------------------------- take ---

func _test_the_take_round_trips(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("abduction")
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	first_where.tell(Vector2(def.heard_within() - 20.0, 0.0))
	_advance(first, 0.5)
	t.check(first.is_taking_a_victim(), "she is close, and the take is under way")
	var second := _round_trip(t, first, "take", &"EventAbduction")
	t.check(second.is_taking_a_victim(), "streamed back in, it is still under way")
	first.free()
	second.free()

# ----------------------------------------------------------------- route walk ---

## The route and how far along it are the event's own body, which `restore()` carries; the walk
## itself keeps nothing.
func _test_the_route_walk_has_no_state_of_its_own(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("dog_walker")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	var first := _instance(t, def, Vector2.ZERO, path)
	_advance(first, def.telegraphs_for() + 2.0)
	t.check(first.behaviours().route().save().is_empty(),
			"the route walk saves nothing of its own")
	var second := _instance(t, def, Vector2.ZERO, path)
	second.restore(first.save())
	t.check(second.global_position.is_equal_approx(first.global_position),
			"restored, it stands where it had walked to")
	first.free()
	second.free()

## **A departure that never began carries nothing**, so a stream-in's restore cannot write over one
## its own `restore()` began: a route cut since by something solid ends there (`EventRouteWalk.
## _keep_to()`), and a car that leaves is held to her sight (`EventDeparture.begin()`). The car
## streamed out was not leaving, so what it saved must not put that back to the fresh default. The
## cut is a body put down on its road behind where it had got to, on the map both cars drive, as
## `tests/test_world_passability.gd` puts one down, so `restore()` itself is what begins the departure.
func _test_a_departure_begun_on_resume_is_not_written_over(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("police_patrol")
	var tile := float(Tuning.TILE_SIZE)
	var map := CityMap.new(Vector2i(24, 3))
	map.fill_rect(Rect2i(0, 0, 24, 3), GameEnums.TileType.ROAD)
	var path := PackedVector2Array([Vector2(0.5, 1.5) * tile, Vector2(20.5, 1.5) * tile])
	var first_where := WhereSheIs.nowhere()
	var first := EventInstance.new()
	first.setup(def, path[0], path, Vector2.RIGHT,
			EventSurroundings.new().on(map) \
				.hearing(first_where))
	first_where.tell(Vector2(0.0, 400.0))
	_advance(first, 1.5)
	t.check(not first.is_on_its_way_out() and first.path_travelled() > 2.0 * tile,
			"the car is driving its route, not leaving (%.0fpx along it)" % first.path_travelled())
	var state := first.save()
	t.check(state.state_of("EventDeparture").is_empty(), "a departure that never began saves nothing")
	var behind: Array[Vector2i] = [Vector2i(1, 1)]
	map.obstruct_tiles(1, behind)
	var second_where := WhereSheIs.nowhere()
	var second := EventInstance.new()
	second.setup(def, path[0], path, Vector2.RIGHT,
			EventSurroundings.new().on(map) \
				.hearing(second_where))
	second_where.tell(first_where.at())
	second.restore(state)
	t.check(second.is_on_its_way_out() and second.behaviours().departure().save().get("must_clear_sight", false),
			"restored once, as the stream-in does, with its road cut behind where it had got to, the car "
			+ "is leaving, held to her sight, and the restore of its behaviours leaves the departure as it began")
	first.free()
	second.free()

# ------------------------------------------------------------------ streaming ---

## Through `EventManager`'s own streaming on a plan, the way a day puts it in the world: what the
## behaviours saved going out is on the plan, and comes back on the instance that streams in.
func _test_the_manager_streams_a_behaviours_state(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var world := WorldContext.new()
	t.add_child(world)
	var map := WorldMap.open_ground()
	var run := RunState.new()
	var manager := EventManager.new(EventSurroundings.new().on(map).drawn_in(world))
	manager.setup(run)
	t.add_child(manager)
	var plan := EventPlan.new(def, at)
	manager.streaming.add(plan)
	manager.stream_around(at)
	var robber := manager.event_of(plan)
	t.check(robber != null, "he is streamed in where the day planned him")
	if robber == null:
		manager.free()
		world.free()
		return
	manager.world.where_she_is().tell(at + Vector2(def.notice_within() - 10.0, 0.0))
	_advance(robber, 0.3)
	var held := robber.behaviours().pursuit().save()
	held["lunge_held"] = true
	robber.behaviours().pursuit().restore(held)
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	manager.stream_around(far)
	t.check(not plan.is_in_the_world() and not plan.saved().state_of("EventPursuit").is_empty(),
			"streamed out, his plan carries his pursuit's state")
	manager.stream_around(at)
	t.check(plan.is_in_the_world() and bool(manager.event_of(plan).behaviours().pursuit().save()["lunge_held"]),
			"and streamed back in, his lunge is still held")
	manager.free()
	world.free()

# ---------------------------------------------------------------- barrier post ---

## **A roadblock's spent guard and the post he left come back across a stream-out**
## (`EventBarrierPost`), as only the barrier; a barrier whose guards both stand carries nothing.
func _test_the_barrier_post_round_trips(t: TestRunner) -> void:
	var def := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), EventDef.HEAT_HUNTS_LEVEL)
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	var carried := first.save().state_of("EventBarrierPost")
	t.check(carried.is_empty(),
			"both guards at their posts, there is nothing to carry")
	first_where.tell(Vector2(0.0, 120.0))
	first.behaviours().barrier_post().leave_the_body()
	var side := first.behaviours().barrier_post().chaser_side()
	first.behaviours().barrier_post().stand_as_the_barrier()
	t.check(side != 0 and first.has_lost_its_guard(), "his guard set off from his post and is spent")
	var second := _round_trip(t, first, "barrier post", &"EventBarrierPost")
	var post := second.behaviours().barrier_post()
	t.check(second.has_lost_its_guard() and post.chaser_side() == side
			and second.phase == EventInstance.Phase.SPENT
			and second.behaviours().barrier_post().sides_still_posted().is_empty(),
			"it comes back as only the barrier, his post empty and the far guard gone")
	first.free()
	second.free()

## A row that drives is composed of a car's driving (`EventCarDriving`), which is not driving until
## it is let go; nothing else is.
func _test_a_car_is_composed_of_its_vehicle(t: TestRunner) -> void:
	var patrol_where := WhereSheIs.nowhere()
	var patrol := _instance(t, EventCatalogue.by_id("police_patrol"), Vector2.ZERO,
			PackedVector2Array(), patrol_where)
	var robber := _instance(t, EventCatalogue.by_id("alley_robbery"))
	patrol_where.tell(Vector2(0.0, 5000.0))
	_advance(patrol, 0.5)
	t.check(patrol.behaviours().car() != null and robber.behaviours().car() == null and patrol.global_position == Vector2.ZERO,
			"a patrol car drives, but stays put with no route to drive; a robber does not drive")
	patrol.free()
	robber.free()

## A waiting robber stays waiting at any bearing while she is outside his notice radius
## (`EventDef.notice_within()`, 180px): he is only watching the street, not noticing her.
func _test_a_robber_out_of_his_radius_keeps_waiting(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(instance_where))
	t.check(instance.is_waiting(), "nobody has come near him yet")
	for sector in range(8):
		instance_where.tell(Vector2.from_angle(deg_to_rad(sector * 45.0)) * (def.notice_within() + 40.0))
		t.check(instance.is_waiting(), "still only waiting at sector %d" % sector)
	instance.free()

## Once she is inside the notice radius one step of the pursuit has him notice her and turn to face
## her exactly, which every later picture of him reads (`tests/test_event_views.gd`, the robber
## who lunges faces her through the chase).
func _test_a_robber_who_notices_her_turns_to_face_her_exactly(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(instance_where))
	# Southeast of him and inside `EventDef.notice_within()`, so one `EventPursuit` step notices
	# her and turns to face her.
	var her := Vector2.from_angle(deg_to_rad(45.0)) * (def.notice_within() - 10.0)
	instance_where.tell(her)
	instance.step(STEP)
	t.check(not instance.is_waiting(), "he has noticed her")
	var expected := (her - instance.global_position).normalized()
	t.check(instance.facing_now().is_equal_approx(expected), "he turned to face her exactly")
	instance.free()
