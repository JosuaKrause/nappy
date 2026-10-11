extends RefCounted
## The barrier a roadblock's guard walks out of stays where it was built (spotted-wombat, "keep the
## barrier in place"). *"the guard pursuer makes his barrier jump up and down and then dissappear"*
## and *"the guarded barriers disappear after shaking off the pursuer. that doesn't make sense."*
##
## Two symptoms, one cause each: `_draw()` lifts the whole canvas by the chaser's stride bob and the
## barrier was drawn inside the lift; and a chase that ended finished the instance, which is the
## barrier's body and picture as well as the man.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_the_barrier_is_drawn_at_its_body_on_every_frame_of_the_chase(t)
	_test_a_shaken_off_guard_leaves_the_barrier_standing(t)
	_test_a_guard_whose_time_runs_out_leaves_the_barrier_standing(t)
	_test_a_guard_who_is_gone_does_not_come_back(t)

func _hot_roadblock() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)

## A guard that has set off after her, her standing still beside the post.
func _chasing(t, post: Vector2) -> Array:
	var hot := _hot_roadblock()
	var guard := EventInstance.new()
	guard.setup(hot, post)
	t.add_child(guard)
	guard.set_process(false)
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
	for i in int(6.0 / STEP):
		her = guard.global_position + Vector2(0.0, 200.0) # keeps him walking, never catches her
		guard.player_at = her
		guard._process(STEP)
		var bob := guard._current_bob()
		lifted = lifted or absf(bob) > 0.1
		# The canvas is lifted by `bob` and the band is drawn at `_roadblock_band_at()` inside it.
		var on_screen := guard.global_position + Vector2(0.0, bob) + guard._roadblock_band_at()
		worst = maxf(worst, on_screen.distance_to(post))
		if guard.is_finished:
			break
	t.check(lifted, "the chaser's stride does lift the canvas (the bob is the thing being undone)")
	t.check(worst < 0.001, "the barrier is drawn on its body on every frame (off by %.3fpx)" % worst)
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
	while guard.is_leaving and walked < int(30.0 / STEP):
		guard.player_at = guard.global_position + Vector2(0.0, 300.0)
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
	t.check(guard.is_leaving or not guard.is_finished, "his chase ends (%d frames)" % frames)
	guard.give_up_the_chase() # a no-op once he is leaving; the departure below is the test
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
