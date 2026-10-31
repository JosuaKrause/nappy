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

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t)
	_test_a_shaken_off_guard_leaves_the_barrier_standing(t)
	_test_a_guard_whose_time_runs_out_leaves_the_barrier_standing(t)
	_test_a_guard_who_is_gone_does_not_come_back(t)
	_test_the_barrier_costs_nothing_while_he_walks_away(t)
	_test_he_is_never_removed_in_view_while_she_stays_near(t)
	_test_the_barrier_rim_survives_the_departure(t)
	_test_a_streamed_out_barrier_comes_back_as_only_the_barrier(t)

func _hot_roadblock() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)

## A guard that has set off after her, her standing still beside the post: she comes inside his
## radius and he warns, and she stays inside it until his warning has run and he charges
## (`EventInstance.warns_by_radius()`, `PursuitSpec.warns_for`).
func _chasing(t, post: Vector2) -> Array:
	var hot := _hot_roadblock()
	var guard := EventInstance.new()
	guard.setup(hot, post)
	t.add_child(guard)
	guard.set_process(false)
	guard.look.attach_nodes()
	var her := post + Vector2(0.0, hot.notice_within() - 10.0)
	guard.player_at = her
	guard.step(STEP)
	her = _charge(guard)
	return [guard, her]

## Holds her where she stands, inside the radius of a guard who is warning her, until his warning
## has run and he charges; answers where she stands.
func _charge(guard: EventInstance) -> Vector2:
	var her := guard.player_at
	var frames := 0
	while guard.is_telegraphing() and frames < int((guard.def.pursuit.warns_for + 1.0) / STEP):
		guard.player_at = her
		guard.step(STEP)
		frames += 1
	return her

func _test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	var her: Vector2 = made[1]
	t.check(guard.barrier_post.has_left_its_body(), "he has set off")
	var worst := 0.0
	var lifted := false
	var band: Node2D = (guard.look as RoadblockLook)._band
	t.check(band != null and band.is_inside_tree() and band.get_parent() == guard.get_parent(),
			"the band is its own node beside the guard, so it sorts at its own feet")
	for i in int(6.0 / STEP):
		her = guard.global_position + Vector2(0.0, 200.0) # keeps him walking, never catches her
		guard.player_at = her
		guard.step(STEP)
		lifted = lifted or absf(guard.look.current_bob()) > 0.1
		worst = maxf(worst, band.global_position.distance_to(post))
		if guard.is_finished:
			break
	t.check(lifted, "the chaser's stride does lift his own canvas (the bob is the thing undone)")
	t.check(guard.global_position.distance_to(post) > 20.0, "and he has walked away from the post")
	t.check(worst < 0.001, "the band stays on its body on every frame (off by %.3fpx)" % worst)
	guard.free()

func _test_a_shaken_off_guard_leaves_the_barrier_standing(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	var frames := 0
	# She runs: outrunning him for `PURSUIT_SHAKEN_OFF` seconds ends the chase.
	while not guard.gave_up and frames < int(60.0 / STEP):
		guard.player_at = guard.global_position + Vector2(0.0, 300.0)
		guard.player_running = true
		guard.step(STEP)
		frames += 1
	t.check(guard.gave_up, "she shakes him off (%d frames)" % frames)
	t.check(guard.is_leaving, "and he walks away")
	var barrier_held := true
	var body_held := true
	var walked := 0
	var stood := guard.player_at
	while guard.is_leaving and walked < int(30.0 / STEP):
		guard.player_at = stood # she stands still; he walks out of her sight
		guard.step(STEP)
		walked += 1
		body_held = body_held and guard.is_solid() \
				and guard._obstruction.global_position.is_equal_approx(post)
		barrier_held = barrier_held and guard.body_position().is_equal_approx(post)
	t.check(body_held and barrier_held, "the barrier's body does not go with him as he leaves")
	t.check(not guard.is_leaving and not guard.is_finished,
			"his departure ends with the instance still there (%d frames)" % walked)
	t.check(guard.is_solid() and guard.body_position().is_equal_approx(post),
			"solid, where it was built")
	t.check(guard.global_position.is_equal_approx(post), "the node is back on the barrier")
	t.check(guard.current_intensity() == 0.0, "and it costs nothing, as a roadblock's band never does")
	# The day carries on: it still stands a long time later.
	for i in int(120.0 / STEP):
		guard.player_at = post + Vector2(0.0, 90.0)
		guard.step(STEP)
	t.check(not guard.is_finished and guard.is_solid(), "it is still there two minutes on")
	guard.free()

func _test_a_guard_whose_time_runs_out_leaves_the_barrier_standing(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	var her: Vector2 = made[1]
	var frames := 0
	# She stands still out of his reach's way so the clock, not a catch, ends it.
	while not guard.is_leaving and not guard.is_finished and frames < int(120.0 / STEP):
		guard.player_at = guard.global_position + Vector2(0.0, 400.0)
		guard.step(STEP)
		frames += 1
	t.check(guard.is_leaving and not guard.gave_up,
			"the clock, not her running, ends his chase (%d frames)" % frames)
	var walked := 0
	while guard.is_leaving and walked < int(30.0 / STEP):
		guard.player_at = guard.global_position + Vector2(0.0, 400.0)
		guard.step(STEP)
		walked += 1
	t.check(not guard.is_finished and guard.is_solid()
			and guard.body_position().is_equal_approx(post), "the barrier stands after he goes")
	guard.free()

func _test_a_guard_who_is_gone_does_not_come_back(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	guard.give_up_the_chase()
	var walked := 0
	while guard.is_leaving and walked < int(30.0 / STEP):
		guard.player_at = post + Vector2(0.0, 500.0)
		guard.step(STEP)
		walked += 1
	t.check(not guard.is_leaving and guard.is_waiting(), "he is gone and the barrier waits")
	# She walks right up to it: nobody notices, nobody chases, nothing is lethal.
	guard.player_at = post + Vector2(0.0, 20.0)
	for i in 120:
		guard.step(STEP)
	t.check(guard.is_waiting(), "walking up to it again wakes nobody")
	t.check(not guard.is_lethal_at(guard.player_at), "and it takes nobody (%s)"
			% guard.is_lethal_at(guard.player_at))
	guard.give_up_the_chase()
	t.check(not guard.is_leaving and not guard.is_finished,
			"and a second give-up does not send the barrier away")
	guard.free()

func _test_the_barrier_costs_nothing_while_he_walks_away(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	guard.give_up_the_chase()
	t.check(guard.is_leaving, "he is walking away")
	var beside := post + Vector2(0.0, 40.0)
	var leaving_frames := 0
	var lit_frames := 0
	# She stands beside the barrier, inside the 420px he must clear, so the departure lasts.
	while guard.is_leaving and leaving_frames < int(30.0 / STEP):
		guard.player_at = beside
		if guard.contribution_at(beside) > 0.0:
			lit_frames += 1
		leaving_frames += 1
		guard.step(STEP)
	t.check(leaving_frames > 60, "the departure lasts (%d frames)" % leaving_frames)
	t.check(lit_frames == 0, "the barrier costs nothing beside it on any leaving frame (%d lit)"
			% lit_frames)
	t.check(guard.contribution_at(beside) == 0.0, "nor after it, as a roadblock's band never does")
	t.check(guard.global_position.distance_to(beside) > Tuning.OUT_OF_SIGHT or guard.is_waiting(),
			"he does not vanish beside her: he is out of sight before the barrier stands alone")
	guard.free()

## The sight rule: with her staying within ~300px of him the backstop (`EventDeparture.LEAVING_GIVES_UP`, 6s) must
## not remove him in view; he is still leaving after 8s, well away from the post.
func _test_he_is_never_removed_in_view_while_she_stays_near(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	guard.give_up_the_chase()
	var frames := 0
	var last_leaving_at := guard.global_position
	while guard.is_leaving and frames < int(8.0 / STEP):
		guard.player_at = guard.global_position + Vector2(0.0, 250.0)
		last_leaving_at = guard.global_position
		guard.step(STEP)
		frames += 1
	t.check(frames == int(8.0 / STEP) and guard.is_leaving,
			"he is still leaving after eight seconds with her near him (%d frames)" % frames)
	t.check(last_leaving_at.distance_to(post) > 300.0 and not guard.is_waiting(),
			"still walking away in view, not put back on the barrier (%.0fpx from it)"
			% last_leaving_at.distance_to(post))
	guard.free()

## The band's rim is one object, lit on every frame he walks away, and the man holds none.
func _test_the_barrier_rim_survives_the_departure(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	guard.set_halo_strength(0.8, Color.RED) # the chase's own rim, on the man
	t.check(guard._halo != null, "the man holds a rim while he chases")
	guard.give_up_the_chase()
	var beside := post + Vector2(0.0, 40.0)
	var rim: EntityHalo = null
	var same := true
	var lit := true
	var man_free := true
	var frames := 0
	while guard.is_leaving and frames < int(30.0 / STEP):
		guard.player_at = beside
		guard.set_halo_strength(0.8, Color.RED)
		if rim == null:
			rim = guard._band_halo
		same = same and rim != null and guard._band_halo == rim
		lit = lit and guard._band_halo != null and guard._band_halo._target_alpha > 0.0
		man_free = man_free and guard._halo == null
		# What `ExcitementHalo` does to an unpicked source in between.
		guard.set_halo_strength(0.8, Color.RED)
		frames += 1
		guard.step(STEP)
	t.check(frames > 60, "the departure lasts (%d frames)" % frames)
	t.check(same and lit, "the band's rim is the same object and lit on every frame of it")
	t.check(man_free, "and the instance never holds a second rim beside it")
	guard.free()

## A heated roadblock streamed through `EventManager` itself, the only place the plan carries what
## the instance forgets: shaken off and streamed out, it comes back as only the barrier.
func _test_a_streamed_out_barrier_comes_back_as_only_the_barrier(t) -> void:
	var city: City = RunCity.of_the_run(CITY_SCENE)
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
	city.events._stream_in(plan)
	var guard: EventInstance = plan.live
	t.check(guard != null, "the roadblock streams in")
	if guard == null:
		city.free()
		return
	guard.look.attach_nodes()
	var her := post + Vector2(0.0, _hot_roadblock().notice_within() - 10.0)
	guard.player_at = her
	guard.step(STEP)
	her = _charge(guard)
	t.check(not guard.is_telegraphing(), "she stays in his radius and he charges")
	t.check(guard.barrier_post.has_left_its_body() and not guard.is_waiting(), "he has set off (%s %s %s age %s)" % [guard.barrier_post.has_left_its_body(), guard.is_waiting(), guard.global_position, guard.age])
	var side := guard.barrier_post.chaser_side()
	# Stream out in the middle of his walking away.
	var frames := 0
	while not guard.is_leaving and frames < int(60.0 / STEP):
		guard.player_at = guard.global_position + Vector2(0.0, 300.0)
		guard.player_running = true
		guard.step(STEP)
		frames += 1
	t.check(guard.is_leaving, "she shook him off and he is walking away")
	city.events._stream_out(plan)
	var carried: Dictionary = plan.behaviours.get(&"EventBarrierPost", {})
	t.check(bool(carried.get("spent", false)) and int(carried.get("side", 0)) == side,
			"the plan carries the spent guard and the side he left (%s)" % [carried])
	city.events._stream_in(plan)
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
		back.player_at = post + Vector2(0.0, 20.0)
		for i in 120:
			back.step(STEP)
		t.check(back.is_waiting() and not back.is_lethal_at(back.player_at),
				"she walks up to it and nothing sets off")
		# Streamed out once more, spent for good this time.
		city.events._stream_out(plan)
		city.events._stream_in(plan)
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
