extends RefCounted
## The behaviours an event is composed of (`EventBehaviours.compose()`): that each one's own state
## survives a stream-out — saved off one instance (`save()`), put
## back on a fresh one of the same row (`restore()`), and then the same
## state and the same next tick. One test per behaviour that keeps state, one for the route walk,
## which keeps none of its own, and one through the manager's own streaming.

const STEP := 0.1
## One frame at the game's sixty a second, the step a pursuit's notice is read at.
const ONE_FRAME := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_the_pursuit_round_trips(t)
	_test_a_robber_out_of_his_radius_keeps_waiting(t)
	_test_a_robber_who_notices_her_turns_to_face_her_exactly(t)
	_test_the_set_off_run_has_no_state_of_its_own(t)
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
	var surroundings := EventSurroundings.new().reading(Shipped.rows())
	if where != null:
		surroundings.hearing(where)
	instance.setup(def, at, path, Vector2.RIGHT, surroundings)
	return instance

## The behaviours a row's event is composed of, composed as `EventInstance.setup()` composes
## them over open ground and handed the figure of `host`, the event they would move.
func _composed_of(def: EventDef, host: EventInstance) -> EventBehaviours:
	var surroundings := EventSurroundings.new().reading(Shipped.rows())
	return EventBehaviours.compose(def, WhereSheIs.nowhere(), EventInstance.Figure.new(host),
			surroundings.map(), surroundings.navigator(), EventInstance.mover_for(def),
			surroundings.trace(), surroundings.lights(), MoveProposal.new())

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance.step(STEP)

## Puts `state` back on `instance` as a stream-in puts a behaviour's saved state back
## (`EventInstance.restore()`): a save of age 0, which restores no moment, only the behaviours it
## names, here the one called `behaviour` by its class.
func _put_back(instance: EventInstance, behaviour: String, state: Dictionary) -> void:
	instance.restore(EventSave.new(0.0, 0.0, INF, {behaviour: state}))

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
	var def := Shipped.rows().by_id("alley_robbery")
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	first_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	_advance(first, 0.3)
	t.check(_is_warning(first), "the robber has noticed her")
	# His held lunge is his own state, so it is set the one way the game sets it from outside: the
	# state a stream-out carries, put back (`EventPursuit.restore()`).
	var state := first.save().state_of("EventPursuit")
	state["lunge_held"] = true
	state["outrun_for"] = 0.4
	_put_back(first, "EventPursuit", state)
	var second := _round_trip(t, first, "pursuit", &"EventPursuit")
	var carried := second.save().state_of("EventPursuit")
	t.check(bool(carried["lunge_held"]) and is_equal_approx(float(carried["outrun_for"]), 0.4),
			"his held lunge and his running clock come back")
	t.check(_is_warning(second), "and he is still warning")
	first.free()
	second.free()

## Whether it is in its warning and nowhere else. Telegraphing alone also answers yes for a row that
## has left, parked, stopped her or finished inside its warning's clock.
func _is_warning(instance: EventInstance) -> bool:
	return instance.is_telegraphing() and not instance.is_waiting() \
			and not instance.is_on_its_way_out() and not instance.is_gone() \
			and not instance.has_parked() and not instance.is_only_its_barrier() \
			and not instance.has_stopped_her()

## **A row a place set off runs its line from its first tick and keeps no state of its own**
## (`EventSetOffRun`, the masked man): created as `EventStreaming.set_off()` creates it, its telegraph
## spent, it has moved along his line after one tick, saves nothing of its own, and one restored
## where it had got to stands there.
func _test_the_set_off_run_has_no_state_of_its_own(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("masked_pursuer")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -600.0)])
	var first := _instance(t, def, Vector2.ZERO, path)
	first.arrive_from_its_warning()
	first.restore(EventSave.aged(EventSpawner.age_when_warned(def)))
	first.step(STEP)
	t.check(first.global_position.y < 0.0 and not first.is_telegraphing(),
			"on his first tick he runs his line (%.1fpx up it)" % -first.global_position.y)
	_advance(first, 1.0)
	t.check(first.save().state_of("EventSetOffRun").is_empty(),
			"the run saves nothing of its own")
	var second := _instance(t, def, Vector2.ZERO, path)
	second.restore(first.save())
	t.check(second.global_position.is_equal_approx(first.global_position),
			"restored, he stands where he had run to")
	first.free()
	second.free()

# ----------------------------------------------------------------------- hold ---

func _test_the_hold_round_trips(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("chatting_mother")
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

## Both in the tree, where `_ready()` builds the flock as the game does, and once they have flown: a
## restore that put nothing back leaves the second flock where `build()` scattered it.
func _test_the_flock_round_trips(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("pigeon_flock")
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	t.add_child(first)
	first.set_process(false)
	t.check(first.birds().size() == def.flock().count(),
			"the flock has its %d birds" % def.flock().count())
	var scattered := first.flock_offsets()
	first_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	_advance(first, def.telegraphs_for() + 1.0)
	t.check(first.flock_offsets() != scattered, "and they have moved from where they were built")
	var state := first.save()
	var second := _instance(t, def, first.global_position, first.walks())
	t.add_child(second)
	second.set_process(false)
	t.check(second.flock_offsets() == scattered, "a fresh flock stands where the first was built")
	second.restore(state)
	_check_the_same_save(t, second.save(), state, "flock: streamed back in")
	t.check(second.flock_offsets() == first.flock_offsets(), "every bird comes back where it was")
	t.check(second.flock_velocities() == first.flock_velocities(), "and going the way it was")
	first.free()
	second.free()

# -------------------------------------------------------------- investigation ---

func _test_the_investigation_round_trips(t: TestRunner) -> void:
	var hot := Shipped.rows().heated(Shipped.rows().by_id("police_patrol"),
			Tuning.RESISTANCE_GOAL)
	var first := _instance(t, hot)
	first.restore(EventSave.aged(2.0))
	var state := {"officers_owed": 1, "investigated": true, "left_her_once": true}
	_put_back(first, "EventInvestigation", state)
	var second := _round_trip(t, first, "investigation", &"EventInvestigation")
	t.check(second.save().state_of("EventInvestigation") == state,
			"every field of its state survives the trip")
	t.check(second.officers_owed() == 1, "and it still owes its man")
	first.free()
	second.free()

# -------------------------------------------------------------------- officer ---

func _test_the_officer_round_trips(t: TestRunner) -> void:
	var first := _instance(t, Shipped.rows().by_id("policeman_giving_chase"))
	first.restore(EventSave.aged(3.0))
	var state := {"trail": PackedVector2Array([Vector2(10.0, 0.0), Vector2(20.0, 0.0)]),
			"stopped_ago": 1.0}
	_put_back(first, "EventOfficer", state)
	var second := _round_trip(t, first, "officer", &"EventOfficer")
	var man := second.save().state_of("EventOfficer")
	t.check(man == state, "every field of its state survives the trip")
	t.check(man["trail"] == first.save().state_of("EventOfficer")["trail"],
			"his trail back comes back")
	t.check(second.has_stopped_her() and is_equal_approx(float(man["stopped_ago"]), 1.0),
			"and so does his stop, as far into it")
	first.free()
	second.free()

# ------------------------------------------------------------------ departure ---

func _test_the_departure_round_trips(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("charging_dog")
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
	var def := Shipped.rows().by_id("loose_dog")
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
	var def := Shipped.rows().by_id("abduction")
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
	var def := Shipped.rows().by_id("dog_walker")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	var first := _instance(t, def, Vector2.ZERO, path)
	_advance(first, def.telegraphs_for() + 2.0)
	t.check(first.save().state_of("EventRouteWalk").is_empty(),
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
	var def := Shipped.rows().by_id("police_patrol")
	var tile := float(Tuning.TILE_SIZE)
	var map := CityMap.new(Vector2i(24, 3))
	map.fill_rect(Rect2i(0, 0, 24, 3), GameEnums.TileType.ROAD)
	var path := PackedVector2Array([Vector2(0.5, 1.5) * tile, Vector2(20.5, 1.5) * tile])
	var first_where := WhereSheIs.nowhere()
	var first := EventInstance.new()
	first.setup(def, path[0], path, Vector2.RIGHT,
			EventSurroundings.new().reading(Shipped.rows()).on(map) \
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
			EventSurroundings.new().reading(Shipped.rows()).on(map) \
				.hearing(second_where))
	second_where.tell(first_where.at())
	second.restore(state)
	t.check(second.is_on_its_way_out()
			and second.save().state_of("EventDeparture").get("must_clear_sight", false),
			"restored once, as the stream-in does, with its road cut behind where it had got to, the car "
			+ "is leaving, held to her sight, and the restore of its behaviours leaves the departure as it began")
	first.free()
	second.free()

# ------------------------------------------------------------------ streaming ---

## Through `EventManager`'s own streaming on a plan, the way a day puts it in the world: what the
## behaviours saved going out is on the plan, and comes back on the instance that streams in.
func _test_the_manager_streams_a_behaviours_state(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("alley_robbery")
	var at := Vector2(5000.0, 5000.0)
	var world := WorldContext.new()
	t.add_child(world)
	var map := WorldMap.open_ground()
	var run := RunState.new()
	var manager := EventManager.new(Shipped.rows(), EventSurroundings.new()
			.on(map).drawn_in(world))
	manager.setup(run)
	t.add_child(manager)
	var plan := EventPlan.new(def, at)
	var planned: Array[EventPlan] = [plan]
	manager.start_recipe(planned, DaySpec.for_day(1), 1, at)
	var robber := manager.event_of(plan)
	t.check(robber != null, "he is streamed in where the day planned him")
	if robber == null:
		manager.free()
		world.free()
		return
	manager.world.where_she_is().tell(at + Vector2(def.notice_within() - 10.0, 0.0))
	_advance(robber, 0.3)
	var held := robber.save().state_of("EventPursuit")
	held["lunge_held"] = true
	_put_back(robber, "EventPursuit", held)
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	manager.stream_around(far)
	t.check(not plan.is_in_the_world() and not plan.saved().state_of("EventPursuit").is_empty(),
			"streamed out, his plan carries his pursuit's state")
	manager.stream_around(at)
	t.check(plan.is_in_the_world()
			and bool(manager.event_of(plan).save().state_of("EventPursuit")["lunge_held"]),
			"and streamed back in, his lunge is still held")
	manager.free()
	world.free()

# ---------------------------------------------------------------- barrier post ---

## **A roadblock's spent guard and the post he left come back across a stream-out**
## (`EventBarrierPost`), as only the barrier; a barrier whose guards both stand carries nothing.
func _test_the_barrier_post_round_trips(t: TestRunner) -> void:
	var def := Shipped.rows().heated(Shipped.rows().by_id("roadblock"),
			EventDef.HEAT_HUNTS_LEVEL)
	var first_where := WhereSheIs.nowhere()
	var first := _instance(t, def, Vector2.ZERO, PackedVector2Array(), first_where)
	# In the tree, where its band's body is put down and its guard can walk out of it.
	t.add_child(first)
	first.set_process(false)
	var carried := first.save().state_of("EventBarrierPost")
	t.check(carried.is_empty(),
			"both guards at their posts, there is nothing to carry")
	# The guard on her side sets off, is shaken off and walks out of her sight, the one way the game
	# spends a guard: his event then stands as only the barrier.
	var her := Vector2(0.0, 120.0)
	first_where.tell(her)
	first.step(STEP)
	t.check(not first.is_waiting(), "he has noticed her and set off from his post")
	var side := EventFootprints.guard_side_toward(first.runs_vertically(),
			her - first.body_position())
	first.give_up_the_chase()
	var walked := 0.0
	while first.is_on_its_way_out() and walked < 60.0:
		first_where.tell(her)
		first.step(STEP)
		walked += STEP
	t.check(first.is_only_its_barrier() and first.has_lost_its_guard(),
			"his guard set off from his post, walked out of her sight and is spent")
	t.check(int(first.save().state_of("EventBarrierPost").get("side", 0)) == side,
			"and the plan carries the side he left")
	var second := _round_trip(t, first, "barrier post", &"EventBarrierPost")
	t.check(second.has_lost_its_guard()
			and int(second.save().state_of("EventBarrierPost").get("side", 0)) == side
			and second.is_only_its_barrier(),
			"it comes back as only the barrier, his post empty")
	first.free()
	second.free()

## A row that drives is composed of a car's driving (`EventCarDriving`), which is not driving until
## it is let go; nothing else is.
func _test_a_car_is_composed_of_its_vehicle(t: TestRunner) -> void:
	var patrol_where := WhereSheIs.nowhere()
	var patrol := _instance(t, Shipped.rows().by_id("police_patrol"), Vector2.ZERO,
			PackedVector2Array(), patrol_where)
	var robber := _instance(t, Shipped.rows().by_id("alley_robbery"))
	patrol_where.tell(Vector2(0.0, 5000.0))
	_advance(patrol, 0.5)
	t.check(patrol.drives() and not robber.drives() and patrol.global_position == Vector2.ZERO,
			"a patrol car drives, but stays put with no route to drive; a robber does not drive")
	t.check(_composed_of(patrol.row(), patrol).car() != null
			and _composed_of(robber.row(), robber).car() == null,
			"and the composer makes a car's driving for the patrol car and none for the robber")
	patrol.free()
	robber.free()

## A waiting robber stays waiting at any bearing while she is outside his notice radius
## (`EventDef.notice_within()`, 180px): he is only watching the street, not noticing her.
func _test_a_robber_out_of_his_radius_keeps_waiting(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("alley_robbery")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().reading(Shipped.rows()).hearing(instance_where))
	t.check(instance.is_waiting(), "nobody has come near him yet")
	for sector in range(8):
		instance_where.tell(Vector2.from_angle(deg_to_rad(sector * 45.0))
				* (def.notice_within() + 40.0))
		instance.step(ONE_FRAME)
		t.check(instance.is_waiting(), "still only waiting at sector %d" % sector)
	instance.free()

## Once she is inside the notice radius one step of the pursuit has him notice her and turn to
## face her exactly, which every later picture of him reads.
func _test_a_robber_who_notices_her_turns_to_face_her_exactly(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("alley_robbery")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().reading(Shipped.rows()).hearing(instance_where))
	# Southeast of him and inside `EventDef.notice_within()`, so one `EventPursuit` step notices
	# her and turns to face her.
	var her := Vector2.from_angle(deg_to_rad(45.0)) * (def.notice_within() - 10.0)
	instance_where.tell(her)
	instance.step(ONE_FRAME)
	t.check(not instance.is_waiting(), "he has noticed her")
	var expected := (her - instance.global_position).normalized()
	t.check(instance.facing_now().is_equal_approx(expected), "he turned to face her exactly")
	instance.free()
