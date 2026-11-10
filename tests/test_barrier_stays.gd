@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The barrier a roadblock's guard walks out of stays where it was built (spotted-wombat, "keep the
## barrier in place"). *"the guard pursuer makes his barrier jump up and down and then dissappear"*
## and *"the guarded barriers disappear after shaking off the pursuer. that doesn't make sense."*
##
## Two symptoms, one cause each: `_draw()` lifts the whole canvas by the chaser's stride bob and the
## barrier was drawn inside the lift; and a chase that ended finished the instance, which is the
## barrier's body and picture as well as the man. The barrier's picture is now its own node
## (`RoadblockLook.RoadblockBand`), standing at the body whatever the man does.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RoadblockRig := preload("res://tests/escape_roadblock_rig.gd")

const STEP := 1.0 / 60.0

func run(t) -> void:
	await _test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t)
	await _test_a_shaken_off_guard_leaves_the_barrier_standing(t)
	await _test_a_guard_whose_time_runs_out_leaves_the_barrier_standing(t)
	await _test_a_guard_who_is_gone_does_not_come_back(t)
	await _test_he_is_never_removed_in_view_while_she_stays_near(t)
	await _test_the_barrier_rim_survives_the_departure(t)
	await _test_a_streamed_out_barrier_comes_back_as_only_the_barrier(t)
	_test_a_posted_guard_sees_and_charges_her_across_his_own_band(t)
	_test_his_catch_does_not_reach_through_his_own_band(t)

func _hot_roadblock() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)

## A guard that has set off after her, her standing still beside the post: she comes inside his
## radius and he warns, and she stays inside it until his warning has run and he charges
## (`EventInstance.warns_by_radius()`, `PursuitSpec.warns_for`). The roadblock is a plan handed to a
## manager's streaming on open ground (`RoadblockRig.Stage`), as a day's is, and its band stands
## beside it once the idle frame has passed. Answers `[guard, her, stage]`; `stage.close()` frees it.
func _chasing(t, post: Vector2, atlas: AtlasLibrary = null) -> Array:
	var hot := _hot_roadblock()
	var stage := RoadblockRig.Stage.new(t, WorldMap.open_ground(), atlas)
	var guard := stage.stand(EventScheduler.Planned.new(hot, post))
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
	while guard.is_telegraphing() and frames < int((guard.def.pursuit.warns_for + 1.0) / STEP):
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

## The rim lit round the barrier's band while its guard walks away: the `EntityHalo` standing behind
## the band's picture (`RoadblockLook.band_rim_holder()`, where the instance builds it), or null.
func _band_halo(guard: EventInstance) -> EntityHalo:
	var holder := (guard.look as RoadblockLook).band_rim_holder()
	if holder == null:
		return null
	for child in holder.get_children():
		if child is EntityHalo:
			return child
	return null

## The picture is moved on the drawn frame, not the tick (`EventInstance._process()`), so the guard
## is stepped as his manager steps him and a real frame passes after each step.
func _test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t) -> void:
	var post := Vector2(400.0, 0.0)
	# The pictures a drawn frame redraws come from the atlas the manager hands every event.
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	var made := await _chasing(t, post, atlas)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	var her: Vector2 = made[1]
	t.check(guard.barrier_post.has_left_its_body(), "he has set off")
	var worst := 0.0
	var lifted := false
	guard.set_process(true)
	var band: Node2D = guard.look.band_node()
	t.check(band != null and band.is_inside_tree() and band.get_parent() == guard.get_parent(),
			"the band is its own node beside the guard, so it sorts at its own feet")
	for i in int(6.0 / STEP):
		her = guard.global_position + Vector2(0.0, 200.0) # keeps him walking, never catches her
		where.tell(her)
		guard.step(STEP)
		await t.get_tree().process_frame
		lifted = lifted or absf(guard.look.current_bob()) > 0.1
		worst = maxf(worst, band.global_position.distance_to(post))
		if guard.is_finished:
			break
	t.check(lifted, "the chaser's stride does lift his own canvas (the bob is the thing undone)")
	t.check(guard.global_position.distance_to(post) > 20.0, "and he has walked away from the post")
	t.check(worst < 0.001, "the band stays on its body on every frame (off by %.3fpx)" % worst)
	stage.close()
	atlas.release(&"events")

func _test_a_shaken_off_guard_leaves_the_barrier_standing(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	var frames := 0
	# She runs: outrunning him for `PURSUIT_SHAKEN_OFF` seconds ends the chase.
	while not guard.gave_up and frames < int(60.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 300.0), Vector2.INF, Rect2(), true)
		guard.step(STEP)
		frames += 1
	t.check(guard.gave_up, "she shakes him off (%d frames)" % frames)
	t.check(guard.is_leaving, "and he walks away")
	var barrier_held := true
	var body_held := true
	var walked := 0
	var stood := where.at()
	while guard.is_leaving and walked < int(30.0 / STEP):
		# She stands still; he walks out of her sight.
		where.tell(stood, Vector2.INF, Rect2(), where.is_running())
		guard.step(STEP)
		walked += 1
		var body := _its_body(guard)
		body_held = body_held and guard.is_solid() and body != null \
				and body.global_position.is_equal_approx(post)
		barrier_held = barrier_held and guard.body_position().is_equal_approx(post)
	t.check(body_held and barrier_held, "the barrier's body does not go with him as he leaves")
	t.check(not guard.is_leaving and not guard.is_finished,
			"his departure ends with the instance still there (%d frames)" % walked)
	t.check(guard.is_solid() and guard.body_position().is_equal_approx(post),
			"solid, where it was built")
	t.check(guard.global_position.is_equal_approx(post), "the node is back on the barrier")
	# The day carries on: it still stands a long time later.
	for i in int(120.0 / STEP):
		where.tell(post + Vector2(0.0, 90.0), Vector2.INF, Rect2(), where.is_running())
		guard.step(STEP)
	t.check(not guard.is_finished and guard.is_solid(), "it is still there two minutes on")
	stage.close()

func _test_a_guard_whose_time_runs_out_leaves_the_barrier_standing(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	var her: Vector2 = made[1]
	var frames := 0
	# She stands still out of his reach's way so the clock, not a catch, ends it.
	while not guard.is_leaving and not guard.is_finished and frames < int(120.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 400.0))
		guard.step(STEP)
		frames += 1
	t.check(guard.is_leaving and not guard.gave_up,
			"the clock, not her running, ends his chase (%d frames)" % frames)
	var walked := 0
	while guard.is_leaving and walked < int(30.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 400.0))
		guard.step(STEP)
		walked += 1
	t.check(not guard.is_finished and guard.is_solid()
			and guard.body_position().is_equal_approx(post), "the barrier stands after he goes")
	stage.close()

func _test_a_guard_who_is_gone_does_not_come_back(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	guard.give_up_the_chase()
	var walked := 0
	while guard.is_leaving and walked < int(30.0 / STEP):
		where.tell(post + Vector2(0.0, 500.0))
		guard.step(STEP)
		walked += 1
	t.check(not guard.is_leaving and guard.is_waiting(), "he is gone and the barrier waits")
	# She walks right up to it: nobody notices, nobody chases, nothing is lethal.
	where.tell(post + Vector2(0.0, 20.0))
	for i in 120:
		guard.step(STEP)
	t.check(guard.is_waiting(), "walking up to it again wakes nobody")
	t.check(not guard.is_lethal_at(where.at()), "and it takes nobody (%s)"
			% guard.is_lethal_at(where.at()))
	guard.give_up_the_chase()
	t.check(not guard.is_leaving and not guard.is_finished,
			"and a second give-up does not send the barrier away")
	stage.close()

## The sight rule: with her staying within ~300px of him the backstop (`EventDeparture.LEAVING_GIVES_UP`, 6s) must
## not remove him in view; he is still leaving after 8s, well away from the post.
func _test_he_is_never_removed_in_view_while_she_stays_near(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	guard.give_up_the_chase()
	var frames := 0
	var last_leaving_at := guard.global_position
	while guard.is_leaving and frames < int(8.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 250.0))
		last_leaving_at = guard.global_position
		guard.step(STEP)
		frames += 1
	t.check(frames == int(8.0 / STEP) and guard.is_leaving,
			"he is still leaving after eight seconds with her near him (%d frames)" % frames)
	t.check(last_leaving_at.distance_to(post) > 300.0 and not guard.is_waiting(),
			"still walking away in view, not put back on the barrier (%.0fpx from it)"
			% last_leaving_at.distance_to(post))
	stage.close()

## The band's rim is one object, lit on every frame he walks away, and the man holds none.
func _test_the_barrier_rim_survives_the_departure(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := await _chasing(t, post)
	var guard: EventInstance = made[0]
	var stage: RoadblockRig.Stage = made[2]
	var where := stage.manager.world.where_she_is()
	# What `ExcitementHalo` does to a source it picks: the strength it lights the source's rim with.
	var source := guard.excitement.rim
	source.set_strength(0.8, Color.RED) # the chase's own rim, on the man
	t.check(guard.rim() != null, "the man holds a rim while he chases")
	guard.give_up_the_chase()
	var beside := post + Vector2(0.0, 40.0)
	var rim: EntityHalo = null
	var same := true
	var lit := true
	var man_free := true
	var frames := 0
	while guard.is_leaving and frames < int(30.0 / STEP):
		where.tell(beside)
		source.set_strength(0.8, Color.RED)
		var banded := _band_halo(guard)
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
func _test_a_streamed_out_barrier_comes_back_as_only_the_barrier(t) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, 4242)
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	city.events.stream_radius = INF
	# A post on open street with a clear line to where she stands: the notice needs one.
	var post := Vector2.INF
	var reach := _hot_roadblock().notice_within() - 10.0
	var home := city.map.doorstep_world_position()
	for dy in range(-12, 13):
		for dx in range(-12, 13):
			var at: Vector2 = city.map.tile_to_world(city.map.world_to_tile(home) + Vector2i(dx, dy))
			if post == Vector2.INF and city.map.clear_line(at, at + Vector2(0.0, reach)) \
					and city.map.clear_line(at + Vector2(0.0, reach), at):
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
	var plan := EventScheduler.Planned.new(_hot_roadblock(), post)
	city.events.streaming.add(plan)
	city.events.streaming.stream_in(plan)
	var guard: EventInstance = plan.live
	t.check(guard != null, "the roadblock streams in")
	if guard == null:
		city.free()
		return
	await RoadblockRig.settle(t)
	var where := city.events.world.where_she_is()
	var her := post + Vector2(0.0, _hot_roadblock().notice_within() - 10.0)
	where.tell(her)
	guard.step(STEP)
	her = _charge(guard, where)
	t.check(not guard.is_telegraphing(), "she stays in his radius and he charges")
	t.check(guard.barrier_post.has_left_its_body() and not guard.is_waiting(), "he has set off (%s %s %s age %s)" % [guard.barrier_post.has_left_its_body(), guard.is_waiting(), guard.global_position, guard.age])
	var side := guard.barrier_post.chaser_side()
	# Stream out in the middle of his walking away.
	var frames := 0
	while not guard.is_leaving and frames < int(60.0 / STEP):
		where.tell(guard.global_position + Vector2(0.0, 300.0), Vector2.INF, Rect2(), true)
		guard.step(STEP)
		frames += 1
	t.check(guard.is_leaving, "she shook him off and he is walking away")
	city.events.streaming.stream_out(plan)
	var carried: Dictionary = plan.behaviours.get(&"EventBarrierPost", {})
	t.check(bool(carried.get("spent", false)) and int(carried.get("side", 0)) == side,
			"the plan carries the spent guard and the side he left (%s)" % [carried])
	city.events.streaming.stream_in(plan)
	var back: EventInstance = plan.live
	t.check(back != null and back != guard, "a fresh instance comes back")
	if back != null:
		t.check(back.is_waiting() and not back.is_leaving and not back.is_finished,
				"streamed out mid-walk, it comes back as the barrier and not as a chase")
		t.check(back.is_solid() and back.body_position().is_equal_approx(post),
				"solid where it was built")
		t.check(back.barrier_post.chaser_side() == side, "with his post still empty")
		t.check(back.departure.save().is_empty() and not back.departure.walks_a_way(),
				"and with nothing of the walk he was on when it streamed out")
		# She walks up to it: nobody notices.
		where.tell(post + Vector2(0.0, 20.0))
		for i in 120:
			back.step(STEP)
		t.check(back.is_waiting() and not back.is_lethal_at(where.at()),
				"she walks up to it and nothing sets off")
		# Streamed out once more, spent for good this time.
		city.events.streaming.stream_out(plan)
		city.events.streaming.stream_in(plan)
		t.check(plan.live != null and plan.live.is_waiting() and plan.live.barrier_post.is_spent(),
				"and a barrier streamed out and in again stays spent")
		city.events.end_the_charges_still_running()
		t.check(counted == ["warned:roadblock", "chased:roadblock", "shaken:roadblock"],
				"the page counts one warning, one charge and its one ending, nothing for the barrier "
				+ "streamed back in, the day's end included (%s)" % [counted])
	EventBus.pursuit_warned.disconnect(listen[0])
	EventBus.pursuit_began.disconnect(listen[1])
	EventBus.pursuit_caught.disconnect(listen[2])
	EventBus.pursuit_ended.disconnect(listen[3])
	EventBus.pursuit_cut_short.disconnect(listen[4])
	city.free()

## **A guard sees out of the band he belongs to, and only that one.** *(`EventInstance.clear_line_to()`:
## "a guard sees out of the band he stands in".)* A band streamed in as a day's is has its body on
## the map's record, and the guard who steps out to his post on her side is then off the band's
## tiles: she walks round to the band's far side while he warns, and the line to her crosses his own
## band. He still charges, and a second band's body between them still hides her.
func _test_a_posted_guard_sees_and_charges_her_across_his_own_band(t) -> void:
	var map: CityMap = RoadblockRig.plan_for(4242)["map"]
	var post := Vector2(2128.0, 80.0)
	var stage := RoadblockRig.Stage.new(t, map)
	var guard := stage.stand(EventScheduler.Planned.new(_hot_roadblock(), post))
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
	t.check(guard.clear_line_to(far),
			"and sees her on the band's far side across his own band's body")
	# A body of another band in the line still hides her: a second band stands beyond her.
	var second := stage.stand(EventScheduler.Planned.new(_hot_roadblock(),
			body + (far - body) * 2.0))
	t.check(second.body_position().distance_to(body) > 150.0
			and not guard.clear_line_to(body + (far - body) * 2.6),
			"a second band's body in the line still hides her")
	# She walks round to the far side while he warns, and he charges anyway.
	frames = 0
	while not guard.is_chasing() and frames < int((guard.def.pursuit.warns_for + 2.0) / STEP):
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
func _test_his_catch_does_not_reach_through_his_own_band(t) -> void:
	var map: CityMap = RoadblockRig.plan_for(4242)["map"]
	# The catalogue's own row, its arms lengthened for the case and put back after it.
	var def := _hot_roadblock()
	var arms := def.pursuit.catch_reach
	def.pursuit.catch_reach = 90.0
	var stage := RoadblockRig.Stage.new(t, map)
	var guard := stage.stand(EventScheduler.Planned.new(def, Vector2(2128.0, 80.0)))
	var body := guard.body_position()
	var near := _open_ground_either_side(map, body)
	t.check(near != Vector2.INF, "there is open ground either side of the band")
	if near == Vector2.INF:
		def.pursuit.catch_reach = arms
		stage.close()
		return
	var made: Array[EventInstance] = [guard]
	var where := stage.manager.world.where_she_is()
	var frames := 0
	while not guard.is_chasing() and frames < int((def.pursuit.warns_for + 3.0) / STEP):
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
	t.check(guard.clear_line_to(across), "he sees it across his own band")
	t.check(not guard.is_lethal_at(across), "and his catch does not reach through his own band")
	def.pursuit.catch_reach = arms
	stage.close()
