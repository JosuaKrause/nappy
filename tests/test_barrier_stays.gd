extends RefCounted
## The barrier a roadblock's guard walks out of stays where it was built (spotted-wombat, "keep the
## barrier in place"). *"the guard pursuer makes his barrier jump up and down and then dissappear"*
## and *"the guarded barriers disappear after shaking off the pursuer. that doesn't make sense."*
##
## Two symptoms, one cause each: `_draw()` lifts the whole canvas by the chaser's stride bob and the
## barrier was drawn inside the lift; and a chase that ended finished the instance, which is the
## barrier's body and picture as well as the man. The barrier's picture is now its own node
## (`RoadblockLook.RoadblockBand`), standing at the body whatever the man does. And what the
## hunting roadblock's guard does at his post: the barrier he leaves is not a second killer, he catches
## at a man's reach, and only the guard on her side sets off, from his own post.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RoadblockRig := preload("res://tests/escape_roadblock_rig.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")
const DrawnEvent := preload("res://tests/drawn_event.gd")
const EastWestStreet := preload("res://tests/east_west_street.gd")

const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	await _test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t)
	await _test_a_shaken_off_guard_leaves_the_barrier_standing(t)
	await _test_a_guard_whose_time_runs_out_leaves_the_barrier_standing(t)
	await _test_a_guard_who_is_gone_does_not_come_back(t)
	await _test_he_is_never_removed_in_view_while_she_stays_near(t)
	await _test_the_barrier_rim_survives_the_departure(t)
	await _test_a_streamed_out_barrier_comes_back_as_only_the_barrier(t)
	_test_a_posted_guard_sees_and_charges_her_across_his_own_band(t)
	_test_his_catch_does_not_reach_through_his_own_band(t)
	await _test_the_guard_leaves_the_barrier_standing_and_catches_at_a_mans_reach(t)
	_test_only_the_guard_on_her_side_sets_off_from_his_post(t)

## Whether the guard on her side has set off from his post: he stands somewhere other than where
## the barrier's body stands, which is where it was built (`body_position()`).
func _has_set_off(guard: EventInstance) -> bool:
	return not guard.global_position.is_equal_approx(guard.body_position())

## Which side of the band, `-1` or `1`, her standing at `her` puts the guard who sets off on.
func _side_she_is_on(guard: EventInstance, her: Vector2) -> int:
	return EventFootprints.guard_side_toward(guard.runs_vertically(), her - guard.body_position())

func _hot_roadblock() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)

## A guard that has set off after her, her standing still beside the post: she comes inside his
## radius and he warns, and she stays inside it until his warning has run and he charges
## (`EventInstance.warns_by_radius()`, `PursuitSpec.warns_for()`). The roadblock is a plan handed to a
## manager's streaming on open ground (`RoadblockRig.Stage`), as a day's is, and its band stands
## beside it once the idle frame has passed. Everything it is drawn with goes to `drawer`. Answers
## `[guard, her, stage]`; `stage.close()` frees it.
func _chasing(t: TestRunner, post: Vector2, atlas: AtlasLibrary = null,
		drawer: RecordingEventDrawer = null) -> Array:
	var hot := _hot_roadblock()
	var stage := RoadblockRig.Stage.new(t, WorldMap.open_ground(), atlas, drawer)
	var guard := stage.stand(EventPlan.new(hot, post))
	await RoadblockRig.settle(t)
	var where := stage.manager.world.where_she_is()
	var her := post + Vector2(0.0, hot.notice_within() - 10.0)
	where.tell(her)
	guard.step(STEP)
	her = _charge(guard, where)
	return [guard, her, stage]

## Holds her where she stands, inside the radius of a guard who is warning her, until his warning
## has run and he charges; answers where she stands.
func _charge(guard: EventInstance, where: WhereSheIs) -> Vector2:
	var her := where.at()
	var frames := 0
	while guard.is_telegraphing() and frames < int((guard.row().pursuit().warns_for() + 1.0) / STEP):
		where.tell(her)
		guard.step(STEP)
		frames += 1
	return her

## The solid body that stops her, found as the debug view's walk of the physics tree finds it: the
## `StaticBody2D` standing under the instance, or null.
func _its_body(guard: EventInstance) -> StaticBody2D:
	for child in guard.get_children():
		if child is StaticBody2D and not child.is_queued_for_deletion():
			return child
	return null

## The barrier's own node, which its look stands beside the guard (`RoadblockLook.RoadblockBand`),
## as the recording drawer saw it drawn on, or null.
func _band_of(drawer: RecordingEventDrawer) -> Node2D:
	for canvas in drawer.canvases():
		if canvas is RoadblockLook.RoadblockBand:
			return canvas as Node2D
	return null

## The rim lit round the barrier's band while its guard walks away: the `EntityHalo` standing behind
## the band's picture, on the band's first slice or on the band when it has no slice (the nodes the
## drawer saw it drawn on), or null.
func _band_halo(drawer: RecordingEventDrawer) -> EntityHalo:
	var holder := _band_of(drawer)
	for canvas in drawer.canvases():
		if canvas is SpreadLook.Slice and canvas.is_inside_tree():
			holder = canvas as Node2D
			break
	if holder == null:
		return null
	for child in holder.get_children():
		if child is EntityHalo:
			return child
	return null

## The picture is moved on the drawn frame, not the tick (`EventInstance._process()`), so the guard
## is stepped as his manager steps him and a real frame passes after each step.
func _test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t: TestRunner) -> void:
	var post := Vector2(400.0, 0.0)
	# The pictures a drawn frame redraws come from the atlas the manager hands every event.
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	var recording := RecordingEventDrawer.new(atlas)
	var made := await _chasing(t, post, atlas, recording)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	var her: Vector2 = made[1]
	t.check(_has_set_off(guard), "he has set off")
	var worst := 0.0
	var lifted := false
	guard.set_process(true)
	var band := _band_of(recording)
	t.check(band != null and band.is_inside_tree() and band.get_parent() == guard.get_parent(),
			"the band is its own node beside the guard, so it sorts at its own feet")
	# What the look lifts his canvas by is asked of a look made round a fake event that answers, each
	# frame, whether the guard pursues and is on his way out, and the ground he has covered.
	var fake := FakeEvent.new()
	var lift := fake.look_for(guard.row())
	for i in int(6.0 / STEP):
		her = guard.global_position + Vector2(0.0, 200.0) # keeps him walking, never catches her
		where.tell(her)
		guard.step(STEP)
		await t.get_tree().process_frame
		fake.travelled = guard.path_travelled()
		fake.pursuing = guard.pursues()
		fake.on_its_way_out = guard.is_on_its_way_out()
		lifted = lifted or absf(lift.current_bob()) > 0.1
		worst = maxf(worst, band.global_position.distance_to(post))
		if guard.is_gone():
			break
	t.check(lifted, "the chaser's stride does lift his own canvas (the bob is the thing undone)")
	t.check(guard.global_position.distance_to(post) > 20.0, "and he has walked away from the post")
	t.check(worst < 0.001, "the band stays on its body on every frame (off by %.3fpx)" % worst)
	fake.free()
	stage.close()
	atlas.release(&"events")

func _test_a_shaken_off_guard_leaves_the_barrier_standing(t: TestRunner) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	var frames := 0
	# She runs: outrunning him for `PURSUIT_SHAKEN_OFF` seconds ends the chase.
	while not guard.has_given_up() and frames < int(60.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 300.0), Vector2.INF, Rect2(), true)
		guard.step(STEP)
		frames += 1
	t.check(guard.has_given_up(), "she shakes him off (%d frames)" % frames)
	t.check(guard.is_on_its_way_out(), "and he walks away")
	var barrier_held := true
	var body_held := true
	var walked := 0
	var stood := where.at()
	while guard.is_on_its_way_out() and walked < int(30.0 / STEP):
		# She stands still; he walks out of her sight.
		where.tell(stood, Vector2.INF, Rect2(), where.is_running())
		guard.step(STEP)
		walked += 1
		var body := _its_body(guard)
		body_held = body_held and guard.is_solid() and body != null \
				and body.global_position.is_equal_approx(post)
		barrier_held = barrier_held and guard.body_position().is_equal_approx(post)
	t.check(body_held and barrier_held, "the barrier's body does not go with him as he leaves")
	t.check(not guard.is_on_its_way_out() and not guard.is_gone(),
			"his departure ends with the instance still there (%d frames)" % walked)
	t.check(guard.is_solid() and guard.body_position().is_equal_approx(post),
			"solid, where it was built")
	t.check(guard.global_position.is_equal_approx(post), "the node is back on the barrier")
	# The day carries on: it still stands a long time later.
	for i in int(120.0 / STEP):
		where.tell(post + Vector2(0.0, 90.0), Vector2.INF, Rect2(), where.is_running())
		guard.step(STEP)
	t.check(not guard.is_gone() and guard.is_solid(), "it is still there two minutes on")
	stage.close()

func _test_a_guard_whose_time_runs_out_leaves_the_barrier_standing(t: TestRunner) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	var her: Vector2 = made[1]
	var frames := 0
	# She stands still out of his reach's way so the clock, not a catch, ends it.
	while not guard.is_on_its_way_out() and not guard.is_gone() and frames < int(120.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 400.0))
		guard.step(STEP)
		frames += 1
	t.check(guard.is_on_its_way_out() and not guard.has_given_up(),
			"the clock, not her running, ends his chase (%d frames)" % frames)
	var walked := 0
	while guard.is_on_its_way_out() and walked < int(30.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 400.0))
		guard.step(STEP)
		walked += 1
	t.check(not guard.is_gone() and guard.is_solid()
			and guard.body_position().is_equal_approx(post), "the barrier stands after he goes")
	stage.close()

func _test_a_guard_who_is_gone_does_not_come_back(t: TestRunner) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	guard.give_up_the_chase()
	var walked := 0
	while guard.is_on_its_way_out() and walked < int(30.0 / STEP):
		where.tell(post + Vector2(0.0, 500.0))
		guard.step(STEP)
		walked += 1
	t.check(not guard.is_on_its_way_out() and guard.is_waiting(), "he is gone and the barrier waits")
	# She walks right up to it: nobody notices, nobody chases, nothing is lethal.
	where.tell(post + Vector2(0.0, 20.0))
	for i in 120:
		guard.step(STEP)
	t.check(guard.is_waiting(), "walking up to it again wakes nobody")
	t.check(not guard.is_lethal_at(where.at()), "and it takes nobody (%s)"
			% guard.is_lethal_at(where.at()))
	guard.give_up_the_chase()
	t.check(not guard.is_on_its_way_out() and not guard.is_gone(),
			"and a second give-up does not send the barrier away")
	stage.close()

## The sight rule: with her staying within ~300px of him the backstop (`EventDeparture.LEAVING_GIVES_UP`, 6s) must
## not remove him in view; he is still leaving after 8s, well away from the post.
func _test_he_is_never_removed_in_view_while_she_stays_near(t: TestRunner) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	guard.give_up_the_chase()
	var frames := 0
	var last_leaving_at := guard.global_position
	while guard.is_on_its_way_out() and frames < int(8.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 250.0))
		last_leaving_at = guard.global_position
		guard.step(STEP)
		frames += 1
	t.check(frames == int(8.0 / STEP) and guard.is_on_its_way_out(),
			"he is still leaving after eight seconds with her near him (%d frames)" % frames)
	t.check(last_leaving_at.distance_to(post) > 300.0 and not guard.is_waiting(),
			"still walking away in view, not put back on the barrier (%.0fpx from it)"
			% last_leaving_at.distance_to(post))
	stage.close()

## The band's rim is one object, lit on every frame he walks away, and the man holds none.
func _test_the_barrier_rim_survives_the_departure(t: TestRunner) -> void:
	var post := Vector2(400.0, 0.0)
	var recording := RecordingEventDrawer.new()
	var made := await _chasing(t, post, null, recording)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	# What `ExcitementHalo` does to a source it picks: the strength it lights the source's rim with.
	var source := guard.source().rim()
	source.set_strength(0.8, Color.RED) # the chase's own rim, on the man
	t.check(guard.rim() != null, "the man holds a rim while he chases")
	guard.give_up_the_chase()
	var beside := post + Vector2(0.0, 40.0)
	var rim: EntityHalo = null
	var same := true
	var lit := true
	var man_free := true
	var frames := 0
	while guard.is_on_its_way_out() and frames < int(30.0 / STEP):
		where.tell(beside)
		source.set_strength(0.8, Color.RED)
		var banded := _band_halo(recording)
		if rim == null:
			rim = banded
		same = same and rim != null and banded == rim
		lit = lit and banded != null and not banded.is_faded_out()
		man_free = man_free and guard.rim() == null
		# What `ExcitementHalo` does to an unpicked source in between.
		source.set_strength(0.8, Color.RED)
		frames += 1
		guard.step(STEP)
	t.check(frames > 60, "the departure lasts (%d frames)" % frames)
	t.check(same and lit, "the band's rim is the same object and lit on every frame of it")
	t.check(man_free, "and the instance never holds a second rim beside it")
	stage.close()

## A heated roadblock streamed through `EventManager` itself, the only place the plan carries what
## the instance forgets: shaken off and streamed out, it comes back as only the barrier.
func _test_a_streamed_out_barrier_comes_back_as_only_the_barrier(t: TestRunner) -> void:
	var run := RunCity.started_run(4242)
	var city: City = RunCity.in_run(CITY_SCENE, run)
	t.add_child(city)
	RunCity.build(city, run, CityGenerator.generate(4242))
	# A post on open street with a clear line to where she stands: the notice needs one.
	var post := Vector2.INF
	var reach := _hot_roadblock().notice_within() - 10.0
	var home := city.map().doorstep_world_position()
	for dy in range(-12, 13):
		for dx in range(-12, 13):
			var at: Vector2 = city.map().tile_to_world(city.map().world_to_tile(home) + Vector2i(dx, dy))
			if post == Vector2.INF and city.map().clear_line(at, at + Vector2(0.0, reach)) \
					and city.map().clear_line(at + Vector2(0.0, reach), at):
				post = at
	t.check(post != Vector2.INF, "the city has an open stretch to stand a roadblock on")
	if post == Vector2.INF:
		city.free()
		return
	# The page's charging counter, read off the signals: one warning, one charge, one ending, and
	# nothing more for the barrier streamed back in, at the day's end included.
	var counted: Array[String] = []
	var listen: Array[Callable] = [
		func(id: String) -> void: counted.append("warned:" + id),
		func(id: String) -> void: counted.append("chased:" + id),
		func(id: String) -> void: counted.append("caught:" + id),
		func(id: String, shaken_off: bool) -> void:
			counted.append(("shaken:" if shaken_off else "outlasted:") + id),
		func(id: String) -> void: counted.append("ended:" + id)]
	EventBus.pursuit_warned.connect(listen[0])
	EventBus.pursuit_began.connect(listen[1])
	EventBus.pursuit_caught.connect(listen[2])
	EventBus.pursuit_ended.connect(listen[3])
	EventBus.pursuit_cut_short.connect(listen[4])
	var plan := EventPlan.new(_hot_roadblock(), post)
	var planned: Array[EventPlan] = [plan]
	RunCity.events(city).start_recipe(planned, DaySpec.for_day(1), 1, post)
	var guard: EventInstance = RunCity.events(city).event_of(plan)
	t.check(guard != null, "the roadblock streams in")
	if guard == null:
		city.free()
		return
	await RoadblockRig.settle(t)
	var where := RunCity.events(city).world.where_she_is()
	var her := post + Vector2(0.0, _hot_roadblock().notice_within() - 10.0)
	where.tell(her)
	guard.step(STEP)
	her = _charge(guard, where)
	t.check(not guard.is_telegraphing(), "she stays in his radius and he charges")
	t.check(_has_set_off(guard) and not guard.is_waiting(), "he has set off (%s %s %s age %s)" % [_has_set_off(guard), guard.is_waiting(), guard.global_position, guard.age()])
	var side := _side_she_is_on(guard, her)
	# Stream out in the middle of his walking away.
	var frames := 0
	while not guard.is_on_its_way_out() and frames < int(60.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 300.0), Vector2.INF, Rect2(), true)
		guard.step(STEP)
		frames += 1
	t.check(guard.is_on_its_way_out(), "she shook him off and he is walking away")
	_stream_out(city, post)
	var carried := plan.saved().state_of("EventBarrierPost")
	t.check(bool(carried.get("spent", false)) and int(carried.get("side", 0)) == side,
			"the plan carries the spent guard and the side he left (%s)" % [carried])
	_stream_in(city, post)
	var back: EventInstance = RunCity.events(city).event_of(plan)
	t.check(back != null and back != guard, "a fresh instance comes back")
	if back != null:
		t.check(back.is_waiting() and not back.is_on_its_way_out() and not back.is_gone(),
				"streamed out mid-walk, it comes back as the barrier and not as a chase")
		t.check(back.is_solid() and back.body_position().is_equal_approx(post),
				"solid where it was built")
		t.check(int(back.save().state_of("EventBarrierPost").get("side", 0)) == side,
				"with the side he left still his")
		t.check(back.save().state_of("EventDeparture").is_empty(),
				"and with nothing of the walk he was on when it streamed out")
		# She walks up to it: nobody notices.
		where.tell(post + Vector2(0.0, 20.0))
		for i in 120:
			back.step(STEP)
		t.check(back.is_waiting() and not back.is_lethal_at(where.at()),
				"she walks up to it and nothing sets off")
		# Streamed out once more, spent for good this time.
		_stream_out(city, post)
		_stream_in(city, post)
		var again := RunCity.events(city).event_of(plan)
		t.check(again != null and again.is_waiting() and again.has_lost_its_guard(),
				"and a barrier streamed out and in again stays spent")
		RunCity.events(city).end_the_charges_still_running()
		t.check(counted == ["warned:roadblock", "chased:roadblock", "shaken:roadblock"],
				"the page counts one warning, one charge and its one ending, nothing for the barrier "
				+ "streamed back in, the day's end included (%s)" % [counted])
	EventBus.pursuit_warned.disconnect(listen[0])
	EventBus.pursuit_began.disconnect(listen[1])
	EventBus.pursuit_caught.disconnect(listen[2])
	EventBus.pursuit_ended.disconnect(listen[3])
	EventBus.pursuit_cut_short.disconnect(listen[4])
	city.free()

## Streams the plan standing at `post` out, the way the game's own streaming does it
## (`EventManager.stream_around()`): her taken to a point beyond the stream radius, its
## hysteresis and the distance a live event is kept for her.
func _stream_out(city: City, post: Vector2) -> void:
	RunCity.events(city).stream_around(post + Vector2(Tuning.EVENT_STREAM_RADIUS
			+ Tuning.EVENT_STREAM_HYSTERESIS + Tuning.OUT_OF_SIGHT + 100.0, 0.0))

## Streams the plan standing at `post` back in, her taken back to it.
func _stream_in(city: City, post: Vector2) -> void:
	RunCity.events(city).stream_around(post)

## **A guard sees out of the band he belongs to, and only that one.** *(The comment of
## `EventInstance`'s own sight line, `_clear_line_to()`: "a guard sees out of the band he stands
## in".)* A band streamed in as a day's is has its body on the map's record, and the guard who steps
## out to his post on her side is then off the band's tiles: she walks round to the band's far side
## while he warns, and the line to her crosses his own band. He still charges, and a second band's
## body between them still hides her.
func _test_a_posted_guard_sees_and_charges_her_across_his_own_band(t: TestRunner) -> void:
	var map: CityMap = RoadblockRig.plan_for(4242)["map"]
	var post := Vector2(2128.0, 80.0)
	var stage := RoadblockRig.Stage.new(t, map)
	var guard := stage.stand(EventPlan.new(_hot_roadblock(), post))
	var body := guard.body_position()
	t.check(map.is_obstructed(map.world_to_tile(body)), "the band's body is on the map's record")
	var near := _open_ground_either_side(map, body)
	t.check(near != Vector2.INF, "there is open ground either side of the band")
	if near == Vector2.INF:
		stage.close()
		return
	var far := body * 2.0 - near
	var made: Array[EventInstance] = [guard]
	var where := stage.manager.world.where_she_is()
	var frames := 0
	while guard.is_waiting() and frames < int(5.0 / STEP):
		RoadblockRig.tick(where, made, near, false)
		frames += 1
	t.check(guard.is_telegraphing(), "he notices her on the near side and warns")
	t.check(guard.global_position.distance_to(body) > 1.0, "from his post, off the band's middle")
	where.tell(far)
	t.check(guard.sight_line_to_her() != Vector2.ZERO,
			"and sees her on the band's far side across his own band's body")
	# A body of another band in the line still hides her: a second band stands beyond her.
	var second := stage.stand(EventPlan.new(_hot_roadblock(),
			body + (far - body) * 2.0))
	where.tell(body + (far - body) * 2.6)
	t.check(second.body_position().distance_to(body) > 150.0
			and guard.sight_line_to_her() == Vector2.ZERO,
			"a second band's body in the line still hides her")
	# She walks round to the far side while he warns, and he charges anyway.
	frames = 0
	while not guard.is_chasing() and frames < int((guard.row().pursuit().warns_for() + 2.0) / STEP):
		RoadblockRig.tick(where, made, far, false)
		frames += 1
	t.check(guard.is_chasing(), "he charges her across his own band (%d frames)" % frames)
	stage.close()

## A bearing from the band's body along which 100px either way is open, walkable ground it has a
## clear line to, and no body's: the point on one side (the other is its mirror), or `INF`.
func _open_ground_either_side(map: CityMap, body: Vector2) -> Vector2:
	for bearing in 16:
		var toward := Vector2.from_angle(TAU * float(bearing) / 16.0) * 100.0
		var a := body + toward
		var b := body - toward
		if map.is_walkable(map.world_to_tile(a)) and map.is_walkable(map.world_to_tile(b)) \
				and not map.is_obstructed(map.world_to_tile(a)) \
				and not map.is_obstructed(map.world_to_tile(b)) \
				and map.clear_line(body, a) and map.clear_line(body, b):
			return a
	return Vector2.INF

## **His catch reaches through nothing, his own band included.** The sight above is exempt from his
## own band's body; the catch is not (`EventInstance.is_lethal_at()`). A roadblock's arms are
## shorter than its band is thick, so the case gives the row longer arms: a point within them, on
## the far side of the band's body from his post, is no catch while the sight across it is clear.
func _test_his_catch_does_not_reach_through_his_own_band(t: TestRunner) -> void:
	var map: CityMap = RoadblockRig.plan_for(4242)["map"]
	# The catalogue's own row with its arms lengthened for the case, a row of its own.
	var lengthening := _hot_roadblock().redraft()
	lengthening.lethal(LethalSpec.within(90.0))
	var def := lengthening.build()
	var stage := RoadblockRig.Stage.new(t, map)
	var guard := stage.stand(EventPlan.new(def, Vector2(2128.0, 80.0)))
	var body := guard.body_position()
	var near := _open_ground_either_side(map, body)
	t.check(near != Vector2.INF, "there is open ground either side of the band")
	if near == Vector2.INF:
		stage.close()
		return
	var made: Array[EventInstance] = [guard]
	var where := stage.manager.world.where_she_is()
	var frames := 0
	while not guard.is_chasing() and frames < int((def.pursuit().warns_for() + 3.0) / STEP):
		RoadblockRig.tick(where, made, near, false)
		frames += 1
	t.check(guard.is_chasing(), "he charges (%d frames)" % frames)
	var reach := def.lethal_reach()
	var across := guard.global_position + (body - guard.global_position).normalized() * (reach - 1.0)
	t.check(guard.global_position.distance_to(across) < reach
			and not map.is_obstructed(map.world_to_tile(across))
			and not map.is_obstructed(map.world_to_tile(guard.global_position))
			and guard.global_position.distance_to(across) > guard.global_position.distance_to(body) + 16.0,
			"the point is within his reach and beyond his band's body")
	where.tell(across)
	t.check(guard.sight_line_to_her() != Vector2.ZERO, "he sees it across his own band")
	t.check(not guard.is_lethal_at(across), "and his catch does not reach through his own band")
	stage.close()

## *"I just saw a barrier turn into a mask men (the barrier disappeared and the masked man
## appeared) and the pursuit ended way too early (I got caught when I was still very visibly away
## from him)."* — and, on how it should work: *"the guard needs to be at the barrier from the
## beginning, standing. only then does it make sense for it to start pursuing. 86px is huge why is
## that the fix for the problem that the radius is too big?"*
##
## Four things, and each is one half of what the player reported.
##
## - **A cold roadblock is a barrier and nothing else**: solid, never lethal, catching nobody at
##   any distance. The guard standing at it is a drawing, which is why he costs nothing here.
## - **Nothing disappears when he sets off.** The body is still there and it is still at the place
##   the barrier was built, not wherever the man has walked to.
## - **The catch is measured from the man**, at `masked_pursuer`'s own reach — so she is taken
##   when he is on her, not when he is two and a half tiles away.
## - **The barrier catches nobody.** Standing right against it, at the distance the old lethal
##   radius would have fired from, ends nothing while the man is elsewhere.
func _test_the_guard_leaves_the_barrier_standing_and_catches_at_a_mans_reach(t: TestRunner) -> void:
	var reach: float = EventCatalogue.by_id("masked_pursuer").core_within()
	var cold := EventCatalogue.by_id("roadblock")
	var post := Vector2(400.0, 0.0)

	var band_where := WhereSheIs.nowhere()
	var band := EventInstance.new()
	# Drawn through a drawer that records what it is told instead of painting it, since this rig
	# holds no atlas, handed before `setup()` as its manager's spawner hands the real one.
	band.setup(cold, post, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(band_where) \
				.drawing_through(DrawnEvent.recording(band, RecordingEventDrawer.new())))
	t.add_child(band)
	band_where.tell(post + Vector2(cold.obstructs_within() + Tuning.PLAYER_BODY_RADIUS, 0.0))
	# A drawn frame passes with it in the tree, its own `_process()` and drawing with it.
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	var segments := 0
	for entry in DrawnEvent.drawer_of(band).draws:
		if entry.picture == EventPictures.roadblock_segment_texture(band.runs_vertically()):
			segments += 1
	t.check(segments > 0, "the band was drawn in the frames that passed (%d segments)" % segments)
	t.check(band.is_solid(), "a cold roadblock is a solid band")
	t.check(not band.is_lethal_at(band_where.at()) and not band.is_lethal_at(post),
			"and it takes nobody, at its own edge or standing in it")
	band.free()

	var hot := EventCatalogue.heated(cold, Tuning.RESISTANCE_GOAL)
	var guard_where := WhereSheIs.nowhere()
	var guard := EventInstance.new()
	guard.setup(hot, post, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(guard_where))
	t.add_child(guard)
	guard.set_process(false)
	t.check(guard.is_solid(), "a hunting one is the same band until it notices her")
	t.check(not _has_set_off(guard), "with its body still under its own feet")

	var her := post + Vector2(hot.notice_within() - 10.0, 0.0)
	guard_where.tell(her)
	guard.step(STEP)
	t.check(not guard.is_waiting(), "she comes inside the trigger and the guard notices her")
	t.check(guard.is_solid() and _has_set_off(guard),
			"he sets off and the barrier stays solid behind him")
	t.check(guard.body_position().is_equal_approx(post),
			"exactly where it was built (%s against %s)" % [guard.body_position(), post])

	# He warns, standing where she can see him, for his `PursuitSpec.warns_for()` while she stays
	# in his radius, and nothing is lethal during it (`EventInstance.warns_by_radius()`); then
	# he charges.
	var frames := 0
	while guard.is_telegraphing() and frames < int((hot.pursuit().warns_for() + 1.0) / STEP):
		t.check(not guard.is_lethal_at(guard.global_position),
				"nothing is lethal while he warns")
		guard_where.tell(her)
		guard.step(STEP)
		frames += 1
	t.check(absf(frames * STEP - hot.pursuit().warns_for()) <= 2.0 * STEP,
			"he warns her for %.2fs, his %.1fs warning" % [frames * STEP, hot.pursuit().warns_for()])
	t.check(not guard.is_telegraphing() and not guard.is_waiting(),
			"and then, she still inside his radius, he charges")

	# The reach is a man's, measured from him.
	var on_him := guard.global_position + Vector2(reach - 1.0, 0.0)
	var just_clear := guard.global_position + Vector2(reach + 2.0, 0.0)
	t.check(guard.is_lethal_at(on_him), "he takes her at %.0fpx, a man's own reach" % reach)
	t.check(not guard.is_lethal_at(just_clear),
			"and not a pixel past it (%.0fpx is clear)" % (reach + 2.0))
	t.check(not guard.is_lethal_at(guard.global_position
			+ Vector2(hot.obstructs_within() + Tuning.PLAYER_BODY_RADIUS, 0.0)),
			"never at the %.0fpx the band's own body would have forced"
			% (hot.obstructs_within() + Tuning.PLAYER_BODY_RADIUS))

	# And the barrier he left behind is not a second killer: she can stand against it. She holds
	# still while he closes, so what this measures is him leaving rather than her drawing him off.
	var chased := 0.0
	while chased < 2.0:
		guard_where.tell(her)
		guard.step(STEP)
		chased += STEP
	t.check(guard.body_position().is_equal_approx(post),
			"the barrier has not followed him (%s)" % guard.body_position())
	t.check(guard.global_position.distance_to(post) > reach,
			"he has actually walked away from the post (%.0fpx)"
			% guard.global_position.distance_to(post))
	t.check(not guard.is_lethal_at(post)
			and not guard.is_lethal_at(post + Vector2(0.0, hot.obstructs_within())),
			"and the barrier standing there takes nobody")
	guard.free()

## *"have one guard on each side?"* · *"only the guard on her side can chase since the other one
## will be blocked"* — and he sets off from his own post, beside the band, rather than from its
## centre. That post is nearer her than the centre where his notice is measured: she comes straight
## across the band, the approach that puts his post nearest her, and stands still once he has
## noticed her. He warns for his row's `PursuitSpec.warns_for()` with nothing lethal in it and
## charges when it has run, she still inside his radius *(inbox #788 in minty-lemur: one radius,
## a warning inside it)*, not on the frame he notices her. Both street axes, both sides.
func _test_only_the_guard_on_her_side_sets_off_from_his_post(t: TestRunner) -> void:
	var hot := _hot_roadblock()
	t.check(hot.pursuit().warns_for() >= Tuning.OFFSCREEN_WARNING_MIN,
			"the hunting guard warns for %.1fs before he charges" % hot.pursuit().warns_for())
	var post := Vector2(400.0, 0.0)
	for vertical: bool in [false, true]:
		for side: int in [-1, 1]:
			var what := "%s, side %d" % ["end-on" if vertical else "broadside", side]
			var guard_where := WhereSheIs.nowhere()
			var guard := EventInstance.new()
			# End-on, he stands on an east-west street, which his band reads its axis off as it
			# does in a city; broadside, on open ground.
			guard.setup(hot, post, PackedVector2Array(), Vector2.RIGHT,
					EventSurroundings.new().on(EastWestStreet.new() if vertical else null) \
						.hearing(guard_where))
			t.check(guard.runs_vertically() == vertical, "%s: the band runs %s" % [what,
					"down the screen" if vertical else "across it"])
			t.add_child(guard)
			guard.set_process(false)
			var across := Vector2(1.0, 0.0) if vertical else Vector2(0.0, 1.0)
			var her := post + across * side * (hot.notice_within() - 1.0)
			guard_where.tell(her)
			guard.step(STEP)
			t.check(_has_set_off(guard), "%s: the guard on her side sets off" % what)
			var his_post := post + EventFootprints.guard_post_offset(vertical, side)
			t.check(guard.global_position.is_equal_approx(his_post),
					"%s: from his own post (%s, the post %s)" % [what, guard.global_position, his_post])
			t.check(guard.body_position().is_equal_approx(post),
					"%s: the band stays where it was built" % what)
			var frames := 0
			var lethal := false
			while guard.is_telegraphing() and frames < int(10.0 / STEP):
				lethal = lethal or guard.is_lethal_at(her)
				guard_where.tell(her)
				guard.step(STEP)
				frames += 1
			t.check(not lethal and absf(frames * STEP - hot.pursuit().warns_for()) <= 2.0 * STEP,
					"%s: he warns her for %.2fs, nothing lethal in it, then charges"
					% [what, frames * STEP])
			t.check(guard.is_chasing(), "%s: and he charges, she still inside his radius" % what)
			guard.free()
