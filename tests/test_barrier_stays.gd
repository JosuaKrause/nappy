extends RefCounted
## The barrier a roadblock's guard walks out of stays where it was built (spotted-wombat, "keep the
## barrier in place"). *"the guard pursuer makes his barrier jump up and down and then dissappear"*
## and *"the guarded barriers disappear after shaking off the pursuer. that doesn't make sense."*
##
## Two symptoms, one cause each: `_draw()` lifts the whole canvas by the chaser's stride bob and the
## barrier was drawn inside the lift; and a chase that ended finished the instance, which is the
## barrier's body and picture as well as the man. The barrier's picture is now its own node
## (`EventInstance.RoadblockBand`), standing at the body whatever the man does.

const CITY_SCENE := preload("res://scenes/world/city.tscn")

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t)
	_test_a_shaken_off_guard_leaves_the_barrier_standing(t)
	_test_a_guard_whose_time_runs_out_leaves_the_barrier_standing(t)
	_test_a_guard_who_is_gone_does_not_come_back(t)
	_test_the_barrier_keeps_its_field_while_he_walks_away(t)
	_test_a_streamed_out_barrier_comes_back_as_only_the_barrier(t)

func _hot_roadblock() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)

## A guard that has set off after her, her standing still beside the post.
func _chasing(t, post: Vector2) -> Array:
	var hot := _hot_roadblock()
	var guard := EventInstance.new()
	guard.setup(hot, post)
	t.add_child(guard)
	guard.set_process(false)
	guard._attach_the_band()
	var her := post + Vector2(0.0, hot.pursues_within - 10.0)
	guard.player_at = her
	guard._process(STEP)
	return [guard, her]

func _test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	var her: Vector2 = made[1]
	t.check(guard.has_left_its_body_behind(), "he has set off")
	var worst := 0.0
	var lifted := false
	var band: Node2D = guard._band
	t.check(band != null and band.is_inside_tree() and band.get_parent() == guard.get_parent(),
			"the band is its own node beside the guard, so it sorts at its own feet")
	for i in int(6.0 / STEP):
		her = guard.global_position + Vector2(0.0, 200.0) # keeps him walking, never catches her
		guard.player_at = her
		guard._process(STEP)
		lifted = lifted or absf(guard._current_bob()) > 0.1
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
		guard._process(STEP)
		frames += 1
	t.check(guard.gave_up, "she shakes him off (%d frames)" % frames)
	t.check(guard.is_leaving, "and he walks away")
	var barrier_held := true
	var body_held := true
	var walked := 0
	var stood := guard.player_at
	while guard.is_leaving and walked < int(30.0 / STEP):
		guard.player_at = stood # she stands still; he walks out of her sight
		guard._process(STEP)
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
	t.check(guard.current_intensity() > 0.0, "and it costs what a barrier costs")
	# The day carries on: it still stands a long time later.
	for i in int(120.0 / STEP):
		guard.player_at = post + Vector2(0.0, 90.0)
		guard._process(STEP)
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
		guard._process(STEP)
		frames += 1
	t.check(guard.is_leaving and not guard.gave_up,
			"the clock, not her running, ends his chase (%d frames)" % frames)
	var walked := 0
	while guard.is_leaving and walked < int(30.0 / STEP):
		guard.player_at = guard.global_position + Vector2(0.0, 400.0)
		guard._process(STEP)
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
		guard._process(STEP)
		walked += 1
	t.check(not guard.is_leaving and guard.is_waiting(), "he is gone and the barrier waits")
	# She walks right up to it: nobody notices, nobody chases, nothing is lethal.
	guard.player_at = post + Vector2(0.0, 20.0)
	for i in 120:
		guard._process(STEP)
	t.check(guard.is_waiting(), "walking up to it again wakes nobody")
	t.check(not guard.is_lethal_at(guard.player_at), "and it takes nobody (%s)"
			% guard.is_lethal_at(guard.player_at))
	guard.give_up_the_chase()
	t.check(not guard.is_leaving and not guard.is_finished,
			"and a second give-up does not send the barrier away")
	guard.free()

func _test_the_barrier_keeps_its_field_while_he_walks_away(t) -> void:
	var post := Vector2(400.0, 0.0)
	var made := _chasing(t, post)
	var guard: EventInstance = made[0]
	guard.give_up_the_chase()
	t.check(guard.is_leaving, "he is walking away")
	var beside := post + Vector2(0.0, 40.0)
	var leaving_frames := 0
	var dark_frames := 0
	# She stands beside the barrier, inside the 420px he must clear, so the departure lasts.
	while guard.is_leaving and leaving_frames < int(30.0 / STEP):
		guard.player_at = beside
		if guard.contribution_at(beside) <= 0.0:
			dark_frames += 1
		leaving_frames += 1
		guard._process(STEP)
	t.check(leaving_frames > 60, "the departure lasts (%d frames)" % leaving_frames)
	t.check(dark_frames == 0, "the barrier costs what it costs beside it on every leaving frame (%d dark)"
			% dark_frames)
	t.check(guard.contribution_at(beside) > 0.0, "and after it")
	t.check(guard.global_position.distance_to(beside) > Tuning.OUT_OF_SIGHT or guard.is_waiting(),
			"he does not vanish beside her: he is out of sight before the barrier stands alone")
	guard.free()

## A heated roadblock streamed through `EventManager` itself, the only place the plan carries what
## the instance forgets: shaken off and streamed out, it comes back as only the barrier.
func _test_a_streamed_out_barrier_comes_back_as_only_the_barrier(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	city.events.stream_radius = INF
	# A post on open street with a clear line to where she stands: the notice needs one.
	var post := Vector2.INF
	var reach := _hot_roadblock().pursues_within - 10.0
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
	var plan := EventScheduler.Planned.new(_hot_roadblock(), post)
	city.events._stream_in(plan)
	var guard: EventInstance = plan.live
	t.check(guard != null, "the roadblock streams in")
	if guard == null:
		city.free()
		return
	guard._attach_the_band()
	var her := post + Vector2(0.0, _hot_roadblock().pursues_within - 10.0)
	guard.player_at = her
	guard._process(STEP)
	t.check(guard.has_left_its_body_behind() and not guard.is_waiting(), "he has set off (%s %s %s age %s)" % [guard.has_left_its_body_behind(), guard.is_waiting(), guard.global_position, guard.age])
	var side := guard.chaser_side()
	# Stream out in the middle of his walking away.
	var frames := 0
	while not guard.is_leaving and frames < int(60.0 / STEP):
		guard.player_at = guard.global_position + Vector2(0.0, 300.0)
		guard.player_running = true
		guard._process(STEP)
		frames += 1
	t.check(guard.is_leaving, "she shook him off and he is walking away")
	city.events._stream_out(plan)
	t.check(plan.guard_spent and plan.chaser_side == side,
			"the plan carries the spent guard and the side he left")
	city.events._stream_in(plan)
	var back: EventInstance = plan.live
	t.check(back != null and back != guard, "a fresh instance comes back")
	if back != null:
		t.check(back.is_waiting() and not back.is_leaving and not back.is_finished,
				"streamed out mid-walk, it comes back as the barrier and not as a chase")
		t.check(back.is_solid() and back.body_position().is_equal_approx(post),
				"solid where it was built")
		t.check(back.chaser_side() == side, "with his post still empty")
		# She walks up to it: nobody notices.
		back.player_at = post + Vector2(0.0, 20.0)
		for i in 120:
			back._process(STEP)
		t.check(back.is_waiting() and not back.is_lethal_at(back.player_at),
				"she walks up to it and nothing sets off")
		# Streamed out once more, spent for good this time.
		city.events._stream_out(plan)
		city.events._stream_in(plan)
		t.check(plan.live != null and plan.live.is_waiting() and plan.live.is_a_spent_guard(),
				"and a barrier streamed out and in again stays spent")
	city.free()
