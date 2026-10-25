extends RefCounted
## `BadgeModel` stepped on its own: fakes for the dangers, a rectangle for the view, a number for the
## clock — no scene, no camera, no frame timing. Which dangers get a screen-edge badge, when it goes
## up and when it comes down is decided there, so it is checked there.

const STEP := 1.0 / 60.0
## The camera's view about her at (0, 0): the world the badge asks "in sight?" of.
const VIEW := Rect2(-320.0, -180.0, 640.0, 360.0)

func run(t) -> void:
	_test_a_danger_closing_from_off_screen_gets_its_badge_at_the_announce_line(t)
	_test_a_danger_walking_away_or_too_slow_gets_none(t)
	_test_the_badge_holds_after_the_condition_lapses_and_not_longer(t)
	_test_something_seen_and_sitting_in_the_margin_band_is_not_badged_fresh(t)
	_test_a_charger_setting_off_inside_the_band_is_badged_from_that_frame(t)
	_test_the_masked_mans_run_from_each_start_keeps_the_badge_until_he_is_in_view(t)
	_test_a_masked_man_running_after_her_as_she_walks_away_keeps_the_badge_past_the_hold(t)
	_test_a_thing_that_arrives_under_its_warning_keeps_its_badge(t)
	_test_a_pending_warning_is_announced_for_its_whole_warning(t)
	_test_three_at_once_soonest_arrival_first(t)
	_test_a_subject_no_longer_handed_over_is_forgotten(t)
	_test_what_is_worth_an_arrow(t)

## The view as the model asks it: `margin_px` screen px past the edge are in sight too, at the
## camera's zoom of 2 (half a world px per screen px).
static func _sees(point: Vector2, margin_px: float) -> bool:
	return VIEW.grow(margin_px * 0.5).has_point(point)

static func _vehicle(key: int, at: Vector2, speed := 190.0) -> BadgeModel.Subject:
	var s := BadgeModel.Subject.new()
	s.key = key
	s.position = at
	s.speed = speed
	s.chase_speed = speed
	s.hard_fail = true
	s.mobile = true
	return s

static func _step(model: BadgeModel, subjects: Array) -> void:
	for s: BadgeModel.Subject in subjects:
		s.shown = VIEW.has_point(s.position)
	model.step(STEP, Vector2.ZERO, subjects, _sees, Tuning.WALK_SPEED)

static func _up(model: BadgeModel, id: String) -> bool:
	for b in model.announcing():
		if b["id"] == id:
			return true
	return false

func _test_a_danger_closing_from_off_screen_gets_its_badge_at_the_announce_line(t) -> void:
	var model := BadgeModel.new()
	var truck := _vehicle(1, Vector2(2000.0, 0.0))
	truck.logged_name = "fire_truck"
	var first_up := -1
	var frames := 0
	while truck.position.x > VIEW.end.x - 1.0 and frames < 2000:
		truck.position.x -= truck.speed * STEP
		_step(model, [truck])
		frames += 1
		if first_up < 0 and _up(model, "fire_truck"):
			first_up = frames
			# 190 px/s for LEAD_TIME seconds is the line (the smoothed approach is within a frame of it).
			t.check(truck.position.x - 0.0 <= 190.0 * BadgeModel.LEAD_TIME + 4.0,
					"the badge goes up inside the lead window (at %.0fpx)" % truck.position.x)
		elif first_up >= 0 and not truck.shown:
			t.check(_up(model, "fire_truck"), "and stays up on frame %d until it is in view" % frames)
	t.check(first_up > 0, "a fire-engine-fast thing closing from off screen is announced")
	t.check(not _up(model, "fire_truck"), "and the badge is off once it is in view")

func _test_a_danger_walking_away_or_too_slow_gets_none(t) -> void:
	var model := BadgeModel.new()
	var away := _vehicle(1, Vector2(500.0, 0.0))
	var slow := _vehicle(2, Vector2(0.0, 500.0), 10.0)
	for i in 120:
		away.position.x += away.speed * STEP
		slow.position.y -= slow.speed * STEP
		_step(model, [away, slow])
	t.check(model.coming.is_empty(), "a thing going away, and one closing slower than 20px/s, get no badge")

func _test_the_badge_holds_after_the_condition_lapses_and_not_longer(t) -> void:
	var model := BadgeModel.new()
	var truck := _vehicle(1, Vector2(1000.0, 0.0))
	truck.logged_name = "truck"
	for i in 30:
		truck.position.x -= truck.speed * STEP
		_step(model, [truck])
	t.check(_up(model, "truck"), "up while closing")
	var held := 0
	while _up(model, "truck") and held < 200:
		_step(model, [truck])
		held += 1
	t.check(absf(held * STEP - BadgeModel.HOLD) < 0.05,
			"standing still it holds for HOLD (%.2fs), then comes down" % (held * STEP))

func _test_something_seen_and_sitting_in_the_margin_band_is_not_badged_fresh(t) -> void:
	# Seen, then out past the edge but inside the margin band: the band is the hysteresis for a
	# badge already up, so a non-charging thing closing from inside it raises none.
	var model := BadgeModel.new()
	var truck := _vehicle(1, Vector2(300.0, 0.0))
	truck.logged_name = "truck"
	_step(model, [truck])
	truck.position.x = VIEW.end.x + 30.0
	for i in 5:
		truck.position.x -= truck.speed * STEP
		_step(model, [truck])
	t.check(not _up(model, "truck"), "a seen thing closing inside the band is not badged until it is past it")
	model = BadgeModel.new()
	truck.position.x = VIEW.end.x + 200.0
	for i in 12:
		truck.position.x -= truck.speed * STEP
		_step(model, [truck])
	t.check(_up(model, "truck"), "past the band it is")

func _test_a_charger_setting_off_inside_the_band_is_badged_from_that_frame(t) -> void:
	var model := BadgeModel.new()
	var man := _vehicle(1, Vector2(300.0, 0.0), 112.0)
	man.logged_name = "man"
	_step(model, [man])
	man.position.x = VIEW.end.x + 30.0
	for i in 20:
		_step(model, [man])
	t.check(not _up(model, "man"), "standing in the band: nothing yet")
	man.position.x -= 112.0 * STEP
	man.charging = true
	_step(model, [man])
	t.check(_up(model, "man"), "the first frame he runs, from inside the band, his badge is up")

func _test_the_masked_mans_run_from_each_start_keeps_the_badge_until_he_is_in_view(t) -> void:
	# Four starts in and around the band (px past the view's right edge), the way the camera's
	# position decides where the stairwell lies against the view.
	for start: float in [5.0, 25.0, 45.0, 64.0, 90.0]:
		var model := BadgeModel.new()
		var man := _vehicle(1, Vector2(VIEW.end.x - 20.0, 0.0), 112.0)
		man.logged_name = "masked_pursuer"
		_step(model, [man])
		man.position.x = VIEW.end.x + start
		for i in 30:
			_step(model, [man])
		var dropped := 0
		var first := -1
		var frame := 0
		man.charging = true
		while not VIEW.has_point(man.position) and frame < 600:
			man.position.x -= 112.0 * STEP
			_step(model, [man])
			if not man.shown:
				if _up(model, "masked_pursuer"):
					if first < 0:
						first = frame
				else:
					dropped += 1
			frame += 1
		t.check(first == 0 and dropped == 0,
				"a masked man running from %.0fpx past the view: badge from frame 0, down on %d frames (first up %d)"
				% [start, dropped, first])

## **CI's shape.** The badge is up on his first frame (he starts beyond the margin band), and then he
## runs into the band while still out of sight: she walks away at 92 px/s, he runs at 112, so the
## view recedes from him at nearly his own pace and he stays in the band for longer than `HOLD`
## (0.8s). Held to the band, only `HOLD` kept the badge and it came down ("first up 0 frames in, down
## on N"); a charger's margin is 0 until he is in sight, so it stays. The view moves with her.
func _test_a_masked_man_running_after_her_as_she_walks_away_keeps_the_badge_past_the_hold(t) -> void:
	var model := BadgeModel.new()
	var here := Vector2.ZERO
	var man := _vehicle(1, Vector2(VIEW.end.x + 100.0, 0.0), 112.0)
	man.logged_name = "masked_pursuer"
	# A lambda captures by value, so the view reads her position from a holder it shares.
	var her := {"at": Vector2.ZERO}
	var in_view := func(p: Vector2, m: float) -> bool: return VIEW.grow(m * 0.5).has_point(p - her["at"])
	for i in 10:
		man.shown = VIEW.has_point(man.position - here)
		model.step(STEP, here, [man], in_view, Tuning.WALK_SPEED)
	man.charging = true
	var first := -1
	var dropped := 0
	var frame := 0
	var in_band_frames := 0
	while frame < 1500:
		man.position.x -= 112.0 * STEP
		here.x -= 92.0 * STEP
		her["at"] = here
		man.shown = VIEW.has_point(man.position - here)
		model.step(STEP, here, [man], in_view, Tuning.WALK_SPEED)
		if man.shown:
			break
		var rel := man.position.x - here.x
		if rel < VIEW.end.x + 65.0:
			in_band_frames += 1
		if _up(model, "masked_pursuer"):
			if first < 0:
				first = frame
		else:
			dropped += 1
		frame += 1
	t.check(in_band_frames * STEP > BadgeModel.HOLD,
			"he is out of sight in the band for longer than HOLD (%.2fs)" % (in_band_frames * STEP))
	t.check(first == 0 and dropped == 0,
			"and the badge is up from the frame he runs until he is in view (first up %d, down on %d of %d frames)"
			% [first, dropped, frame])

func _test_a_thing_that_arrives_under_its_warning_keeps_its_badge(t) -> void:
	var model := BadgeModel.new()
	var dog := _vehicle(1, Vector2(VIEW.end.x + 20.0, 0.0), 100.0)
	dog.logged_name = "dog"
	dog.warned = true
	_step(model, [dog])
	t.check(_up(model, "dog"), "created just out of sight under its warning, it is badged at once")
	for i in 20:
		dog.position.x -= 100.0 * STEP
		_step(model, [dog])
		if not dog.shown:
			t.check(_up(model, "dog"), "and keeps it on frame %d until it is in sight" % i)

func _test_a_pending_warning_is_announced_for_its_whole_warning(t) -> void:
	var model := BadgeModel.new()
	var w := _vehicle(0, Vector2(0.0, 0.0), 190.0)
	w.pending = true
	w.position = Vector2(100.0, 0.0)  # in view: still announced, nothing there to see
	w.left = 0.7
	w.logged_name = "cyclist"
	model.step(STEP, Vector2.ZERO, [w], _sees, Tuning.WALK_SPEED)
	t.check(_up(model, "cyclist"), "a warning with nothing in the world yet is up, on screen or off")
	t.check(is_equal_approx(float(model.coming[0][0]), 0.7), "sorted by the seconds its warning has left")

func _test_three_at_once_soonest_arrival_first(t) -> void:
	var model := BadgeModel.new()
	var subjects: Array = []
	for i in 5:
		var v := _vehicle(i + 1, Vector2(500.0 + 100.0 * i, 0.0))
		v.logged_name = "v%d" % i
		subjects.append(v)
	for f in 20:
		for v: BadgeModel.Subject in subjects:
			v.position.x -= v.speed * STEP
		_step(model, subjects)
	var names := []
	for b in model.announcing():
		names.append(b["id"])
	t.check(names == ["v0", "v1", "v2"], "at most three, the soonest to arrive first (%s)" % str(names))

func _test_a_subject_no_longer_handed_over_is_forgotten(t) -> void:
	var model := BadgeModel.new()
	var truck := _vehicle(7, Vector2(800.0, 0.0))
	_step(model, [truck])
	t.check(model.watch.has(7), "a handed-over subject has state")
	_step(model, [])
	t.check(not model.watch.has(7), "one no longer handed over is pruned")

func _test_what_is_worth_an_arrow(t) -> void:
	var walk := Tuning.WALK_SPEED
	var s := _vehicle(1, Vector2.ZERO)
	t.check(s.worth_an_arrow(walk), "lethal and fast")
	s.telegraphs = false
	t.check(not s.worth_an_arrow(walk), "a thing that does not telegraph is outside the badge")
	s.telegraphs = true
	s.has_icon = false
	t.check(not s.worth_an_arrow(walk), "no silhouette, nothing to say")
	s.has_icon = true
	s.ahead_of_player = true
	t.check(not s.worth_an_arrow(walk), "an ahead-of-her crossing is its own moment")
	s.pursues = true
	t.check(s.worth_an_arrow(walk), "except a pursuer")
	var cyclist := _vehicle(2, Vector2.ZERO, walk + 10.0)
	cyclist.hard_fail = false
	t.check(cyclist.worth_an_arrow(walk), "faster than a walk")
	cyclist.speed = walk - 10.0
	t.check(not cyclist.worth_an_arrow(walk), "slower than a walk, not lethal: she can turn round")
