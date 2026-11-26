extends RefCounted
## M108, "every living thing that moves has a stride" — the event half. `tests/test_event_views.gd`
## already pins each family's own five-view table and heading source; this suite pins the second
## frame every listed family gained beside it, and the alternation that picks between the two —
## `EventInstance._advance_gait()`, and the look's `EventLook.gait_is_stepping()`,
## `victim_gait_is_stepping()` and `idle_is_stepping()`.
##
## **The look's queries are asked of a look made round a fake event** (`FakeEvent.look_for()`),
## its stride set to what a real dog walker answers at that ground (`WALK`, read off one walked on
## open ground, as `tests/test_event_redraw.gd` reads it). A real event is set up where the
## question is the event's own (whether its stride runs while it waits, is held in a conversation
## or covers ground) and where what it draws is the question, read off a recording drawer handed
## to it in its setup call.
##
## Consistent with `test_event_views.gd`, nothing here calls a `_draw_*` function directly —
## `Sprites.draw_standing()` inside them is only valid from an actual draw pass. What is tested
## instead is the query every `_draw_*` reads to choose a frame, which is exactly what the halo
## needs to agree with the body about — see `_test_gait_query_is_stable_within_a_tick`. The
## rendered evidence is `docs/evidence/m108-event-strides-2026-09-12/`, native and 3x sheets of
## every family's frame a beside frame b, and a burst capturing an actual flip in play.

const STEP := 1.0 / 60.0
const DrawnEvent := preload("res://tests/drawn_event.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")

## What a real dog walker answers walking its route, read off one set up on open ground and walked
## eight and three-quarter pixels at a time (half a beat of its stride, `PI / 2 / GAIT_RATE` being
## a beat): the ground covered (x) and the stride's phase it reads (y), the first point the event
## standing still. Every point after the first is one it has set off to, so it is striding.
const WALK: PackedVector2Array = [
	Vector2(0.0, 0.0), Vector2(8.75, 0.7875), Vector2(17.5, 1.575), Vector2(26.25, 2.3625),
	Vector2(35.0, 3.15), Vector2(43.75, 3.9375), Vector2(52.5, 4.725), Vector2(61.25, 5.5125),
	Vector2(70.0, 0.0168), Vector2(78.75, 0.8043), Vector2(87.5, 1.5918),
	Vector2(96.25, 2.3793), Vector2(105.0, 3.1668), Vector2(113.75, 3.9543),
	Vector2(122.5, 4.7418), Vector2(131.25, 5.5293), Vector2(140.0, 0.0336),
]

## Every family that gained a stride this round, its "a" and "b" tables paired so the
## completeness, distinctness and "differs from a" checks below run once over the whole set.
## Neither `cafe_sitter` nor `busker` is here: their own idle-timer alternation is checked in its
## own section rather than folded into the distance-driven gait checks every entry here shares.
const GAIT_FAMILY_DICTS := {
	"person": [EventPictures.PERSON_BY_VIEW, EventPictures.PERSON_BY_VIEW_B],
	"yeller": [EventPictures.YELLER_BY_VIEW, EventPictures.YELLER_BY_VIEW_B],
	"robber_lunging": [EventPictures.ROBBER_LUNGING_BY_VIEW, EventPictures.ROBBER_LUNGING_BY_VIEW_B],
	"robber_alert": [EventPictures.ROBBER_ALERT_BY_VIEW, EventPictures.ROBBER_ALERT_BY_VIEW_B],
	"protester": [EventPictures.PROTESTER_BY_VIEW, EventPictures.PROTESTER_BY_VIEW_B],
	"leaf_blower": [EventPictures.LEAF_BLOWER_BY_VIEW, EventPictures.LEAF_BLOWER_BY_VIEW_B],
	"van_victim": [EventPictures.VAN_VICTIM_BY_VIEW, EventPictures.VAN_VICTIM_BY_VIEW_B],
	"chatting_mother_walking":
			[EventPictures.CHATTING_MOTHER_WALKING_BY_VIEW, EventPictures.CHATTING_MOTHER_WALKING_BY_VIEW_B],
	"cat_running": [EventPictures.CAT_RUNNING_BY_VIEW, EventPictures.CAT_RUNNING_BY_VIEW_B],
	"dog": [EventPictures.DOG_BY_VIEW, EventPictures.DOG_BY_VIEW_B],
	"charging_dog": [EventPictures.CHARGING_DOG_BY_VIEW, EventPictures.CHARGING_DOG_BY_VIEW_B],
	"cyclist": [EventPictures.CYCLIST_BY_VIEW, EventPictures.CYCLIST_BY_VIEW_B],
	"pelican_cyclist": [EventPictures.PELICAN_BY_VIEW, EventPictures.PELICAN_BY_VIEW_B],
	"mouse": [EventPictures.MOUSE_BY_VIEW, EventPictures.MOUSE_BY_VIEW_B],
}

const IDLE_FAMILY_DICTS := {
	"cafe_sitter": [EventPictures.CAFE_SITTER_BY_VIEW, EventPictures.CAFE_SITTER_BY_VIEW_B],
	"busker": [EventPictures.BUSKER_BY_VIEW, EventPictures.BUSKER_BY_VIEW_B],
}

const VIEWS: Array[String] = ["front", "back", "side", "front_diagonal", "back_diagonal"]

func run(t: TestRunner) -> void:
	_test_b_tables_are_complete(t)
	_test_b_tables_differ_from_a_per_view(t)
	_test_moving_instance_alternates_gait_frames(t)
	_test_waiting_robber_holds_frame_a(t)
	_test_chatting_mother_freezes_gait_when_talking(t)
	await _test_crouched_cat_never_reads_the_running_b_frame(t)
	_test_dog_walker_and_dog_share_one_phase(t)
	_test_the_normal_dog_has_three_pictures_in_four_beats(t)
	_test_a_walking_normal_dog_steps_rests_and_steps_the_other_way(t)
	await _test_a_standing_normal_dog_rests(t)
	_test_victim_gait_starts_on_frame_a_and_later_steps(t)
	_test_idle_families_alternate_on_time_without_moving(t)
	_test_idle_phase_offset_differs_by_siting(t)
	_test_gait_and_idle_phase_reset_on_setup(t)
	_test_gait_query_is_stable_within_a_tick(t)

# ------------------------------------------------------------------- the tables ---

func _test_b_tables_are_complete(t: TestRunner) -> void:
	for name: String in GAIT_FAMILY_DICTS:
		var by_view_b: Dictionary = GAIT_FAMILY_DICTS[name][1]
		t.check(by_view_b.size() == 5, "%s carries exactly five b-frame views" % name)
		for view in VIEWS:
			t.check(by_view_b.has(view) and by_view_b[view] != null,
					"%s has a resolving b-frame %s view" % [name, view])
	for name: String in IDLE_FAMILY_DICTS:
		var by_view_b: Dictionary = IDLE_FAMILY_DICTS[name][1]
		t.check(by_view_b.size() == 5, "%s carries exactly five idle-frame views" % name)
		for view in VIEWS:
			t.check(by_view_b.has(view) and by_view_b[view] != null,
					"%s has a resolving idle-frame %s view" % [name, view])

## Every family with a b table draws something different from its own a frame at every view — the
## walker precedent's own "legs and shoes cross" (or the sitters' lean, or the busker's raised
## hand) has to actually be a different picture, not a second preload of the same source.
func _test_b_tables_differ_from_a_per_view(t: TestRunner) -> void:
	for name: String in GAIT_FAMILY_DICTS:
		var by_view: Dictionary = GAIT_FAMILY_DICTS[name][0]
		var by_view_b: Dictionary = GAIT_FAMILY_DICTS[name][1]
		for view in VIEWS:
			t.check(by_view[view] != by_view_b[view],
					"%s's %s view differs between frame a and frame b" % [name, view])
	for name: String in IDLE_FAMILY_DICTS:
		var by_view: Dictionary = IDLE_FAMILY_DICTS[name][0]
		var by_view_b: Dictionary = IDLE_FAMILY_DICTS[name][1]
		for view in VIEWS:
			t.check(by_view[view] != by_view_b[view],
					"%s's %s view differs between its two idle frames" % [name, view])

# ------------------------------------------------------------------- the gait ---

func _heading_for_sector(sector: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(sector * 45.0))

## A moving event alternates: starts on frame a before it has covered any ground, crosses into
## the mid-stride frame as it walks, and returns to the rest frame later in the same stride — the
## walker's own `sin(phase * 2.0) > 0.0` shape, read here through `gait_is_stepping()` rather than
## re-derived, exactly as `_draw_dog_walker()` reads it. The look is asked round a fake event
## walked through `WALK`.
func _test_moving_instance_alternates_gait_frames(t: TestRunner) -> void:
	var event := FakeEvent.new()
	var look := event.look_for(Shipped.rows().by_id("dog_walker"))
	t.check(not look.gait_is_stepping(), "starts on frame a before it has moved at all")
	var saw_b := false
	var saw_a_again := false
	for point: Vector2 in WALK.slice(1):
		_walk_to(event, point)
		if look.gait_is_stepping():
			saw_b = true
		elif saw_b:
			saw_a_again = true
	t.check(saw_b, "crosses into the mid-stride frame as it walks (dog_walker at 32px/s)")
	t.check(saw_a_again, "and back to the rest frame later in the same walk")
	event.free()

## `alley_robbery`'s waiting posture never covers ground — `EventPursuit` only turns `_heading` toward
## her while `is_waiting()`, it does not move — so its stride is stopped for as long as it waits,
## whatever `_gait_phase` happens to be sitting on, and a look asked on a stopped stride holds
## frame a however far through a step its phase is.
func _test_waiting_robber_holds_frame_a(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("alley_robbery")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().reading(Shipped.rows()).hearing(instance_where))
	# Well outside `EventDef.notice_within()`, so he stays `is_waiting()` for the whole run.
	instance_where.tell(Vector2(9999.0, 9999.0))
	for i in 120:
		instance.step(STEP)
		t.check(instance.is_waiting(), "still only waiting at tick %d" % i)
		t.check(not instance.gait_is_moving(), "a waiting robber's stride is stopped (tick %d)" % i)
	instance.free()
	var event := FakeEvent.new()
	event.waiting = true
	event.stride = WALK[1].y
	event.striding = false
	var look := event.look_for(def)
	t.check(not look.gait_is_stepping(),
			"a stopped stride holds frame a, whatever step its phase is on")
	event.free()

## `chatting_mother`'s pacing beat gets a stride; her conversation freezes `_process()` entirely
## (see that function's own `is_chatting()` branch), so the stride stops with it rather than
## continuing to alternate on whatever phase it had reached the moment she stopped; a look asked on
## a stopped stride holds frame a (`_test_waiting_robber_holds_frame_a()`).
func _test_chatting_mother_freezes_gait_when_talking(t: TestRunner) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(Shipped.rows().by_id("chatting_mother"), Vector2.ZERO, route,
			Vector2.RIGHT)
	for i in 60:
		instance.step(STEP)
	t.check(instance.gait_is_moving(), "she is striding on her beat before the conversation")
	instance.start_chat()
	t.check(instance.is_chatting(), "the conversation is running")
	for i in 30:
		instance.step(STEP)
		t.check(not instance.gait_is_moving(), "frozen mid-conversation holds still (tick %d)" % i)
	instance.free()

## The crouch is the telegraph, held still by construction (`holds_still()`) — it must
## never draw the running family's own b frame, whatever `gait_is_stepping()` says, since crouched
## has no second frame of its own at all. A cat the game would never see striding while it crouches
## is walked on by hand, as a scene recipe's held event is (`walk_on_by_hand()`, which advances the
## stride by the ground covered), until its stride is on a step, and drawn on real frames: the
## pictures it tells its drawer to stand are the crouched ones. The hand stays here: a crouching
## cat covers no ground under its manager's step, so no step the game takes puts its stride on a
## step, and the guard is for the state the game cannot reach.
func _test_crouched_cat_never_reads_the_running_b_frame(t: TestRunner) -> void:
	var instance: EventInstance = await DrawnEvent.stand(t,
			Shipped.rows().by_id("cat_dash"), false)
	t.check(instance.is_telegraphing(), "a cat starts in its crouch")
	instance.hold_by_hand()
	var walked := 0
	while not _on_a_step(instance, false) and walked < 600:
		instance.walk_on_by_hand(STEP)
		walked += 1
	t.check(_on_a_step(instance, false) and instance.is_telegraphing(),
			"the stride is on a step while it still crouches (walked %d ticks)" % walked)
	await DrawnEvent.frames(t)
	var crouched := EventPictures.CAT_CROUCHED_BY_VIEW.values()
	var running_b := EventPictures.CAT_RUNNING_BY_VIEW_B.values()
	var shown := DrawnEvent.shown(instance)
	t.check(not shown.is_empty(), "the cat is drawn")
	for entry in shown:
		t.check(entry.picture in crouched and not entry.picture in running_b,
				"it draws a crouched picture, never the running b frame (%s)" % entry.picture)
	t.check(EventPictures.CAT_CROUCHED_BY_VIEW["side"] != EventPictures.CAT_RUNNING_BY_VIEW_B["side"],
			"the crouch and the running b frame are not the same picture regardless")
	instance.free()

## "Actor and held thing swap frames together": the dog walker's person and dog read one shared
## `_gait_phase`, so the dog is on one of its two steps exactly while the walker is mid-stride and
## on its rest exactly while he is on his rest frame — asked here through the same two queries
## `_draw_dog_walker()` reads, over a walk long enough to pass through every beat.
func _test_dog_walker_and_dog_share_one_phase(t: TestRunner) -> void:
	var event := FakeEvent.new()
	var look := event.look_for(Shipped.rows().by_id("dog_walker"))
	var rest: String = EventPictures.dog_picture("side", false, false)
	var agreed := true
	for point: Vector2 in WALK.slice(1):
		_walk_to(event, point)
		var stepping := look.gait_is_stepping()
		var person_frame: String = EventPictures.PERSON_BY_VIEW_B["side"] if stepping \
				else EventPictures.PERSON_BY_VIEW["side"]
		var dog_frame := EventPictures.dog_picture("side", stepping, look.gait_is_second_half())
		if (person_frame == EventPictures.PERSON_BY_VIEW_B["side"]) == (dog_frame == rest):
			agreed = false
	t.check(agreed, "the walker is mid-stride exactly while the dog is on a step, never on its rest")
	event.free()

## The normal dog walks step, rest, opposite step, rest on three pictures per view *(2026-09-27,
## teal-marmot: "the normal dog should have three frames. we have the resting one now and one leg
## forward. now we need one frame with the other leg forward")*. The side and diagonals rest on b
## and take the opposite step on c; front and back rest on their neutral c and take the opposite
## step on b, because their a and b already reach with opposite leg pairs.
func _test_the_normal_dog_has_three_pictures_in_four_beats(t: TestRunner) -> void:
	var expected := {
		"side": ["events/dog", "events/dog_b", "events/dog_c", "events/dog_b"],
		"front_diagonal": ["events/dog_front_diagonal", "events/dog_front_diagonal_b",
				"events/dog_front_diagonal_c", "events/dog_front_diagonal_b"],
		"back_diagonal": ["events/dog_back_diagonal", "events/dog_back_diagonal_b",
				"events/dog_back_diagonal_c", "events/dog_back_diagonal_b"],
		"front": ["events/dog_front", "events/dog_front_c", "events/dog_front_b",
				"events/dog_front_c"],
		"back": ["events/dog_back", "events/dog_back_c", "events/dog_back_b", "events/dog_back_c"],
	}
	t.check(expected.size() == VIEWS.size(), "every view is asked about")
	for view in VIEWS:
		var beats: Array = expected[view]
		var drawn := [
			EventPictures.dog_picture(view, true, false),
			EventPictures.dog_picture(view, false, false),
			EventPictures.dog_picture(view, true, true),
			EventPictures.dog_picture(view, false, true),
		]
		t.check(drawn == beats, "the %s dog walks %s (got %s)" % [view, beats, drawn])
		var distinct := {}
		for picture: String in drawn:
			distinct[picture] = true
		t.check(distinct.size() == 3, "the %s dog draws three different pictures" % view)

## A walking dog walker's dog goes through the four beats in order — step, rest, opposite step,
## rest — and each beat lasts the same ground, a quarter of a turn of `_gait_phase` at
## `GAIT_RATE`, which is when the walker's own two frames swap as well. The loose dog reads the
## same queries at its own speed. The order is the look's, asked round a fake event walked through
## `WALK`; the beat's ground is the event's own stride, read off a real dog walker walked tick by
## tick.
func _test_a_walking_normal_dog_steps_rests_and_steps_the_other_way(t: TestRunner) -> void:
	var beat := PI / 2.0 / EventInstance.GAIT_RATE
	var cycle := ["events/dog", "events/dog_b", "events/dog_c", "events/dog_b"]
	var event := FakeEvent.new()
	var look := event.look_for(Shipped.rows().by_id("dog_walker"))
	var shown: Array[String] = []
	for point: Vector2 in WALK.slice(1):
		_walk_to(event, point)
		var now := EventPictures.dog_picture("side", look.gait_is_stepping(),
				look.gait_is_second_half())
		if shown.is_empty() or shown[-1] != now:
			shown.append(now)
	t.check(shown.size() >= 9, "the walk passed through two whole cycles (%d beats)" % shown.size())
	t.check(not shown.is_empty() and shown[0] == cycle[0], "the first step comes first")
	var in_order := true
	for k in shown.size():
		if shown[k] != cycle[k % 4]:
			in_order = false
	t.check(in_order, "the beats run step, rest, opposite step, rest (%s)" % [shown])
	event.free()
	var route := PackedVector2Array([Vector2.ZERO, Vector2(900.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(Shipped.rows().by_id("dog_walker"), Vector2.ZERO, route,
			Vector2.RIGHT)
	var beats: Array[int] = []
	var changed_at: Array[float] = []
	for i in 900:
		instance.step(STEP)
		var quarter := int(instance.gait_phase() / (PI / 2.0))
		if beats.is_empty() or beats[-1] != quarter:
			beats.append(quarter)
			changed_at.append(instance.path_travelled())
	var even := true
	for k in range(1, changed_at.size() - 1):
		if absf(changed_at[k + 1] - changed_at[k] - beat) > 1.0:
			even = false
	t.check(changed_at.size() >= 9, "the stride passed through two whole cycles of beats")
	t.check(even, "each beat is %.1fpx of ground" % beat)
	instance.free()

## Standing still is the rest pose, not a step held mid-air: before a dog walker has covered any
## ground, and whenever the last tick saw none, whatever half of the stride the phase happens to be
## sitting in. The walker is sent off (`leave_for_a_completed_task()`) and stepped the way its
## manager steps it until its stride is on a step in each half, then given a tick that covers no
## ground (a step of no time), and the dog it draws on real frames is on its rest picture.
func _test_a_standing_normal_dog_rests(t: TestRunner) -> void:
	# The heading each view is drawn from.
	var headings := {"side": Vector2.RIGHT, "front": Vector2.DOWN, "back": Vector2.UP,
			"front_diagonal": Vector2(1.0, 1.0).normalized(),
			"back_diagonal": Vector2(1.0, -1.0).normalized()}
	for view: String in headings:
		var instance: EventInstance = await DrawnEvent.stand(t,
				Shipped.rows().by_id("dog_walker"),
				false, null, null, DrawnEvent.AT, headings[view])
		instance.leave_for_a_completed_task()
		var rest: String = EventPictures.dog_picture(view, false, false)
		t.check(_the_dog_drawn(instance) == [rest],
				"a %s dog that has not moved stands in its rest pose" % view)
		for second_half: bool in [false, true]:
			var half := "second" if second_half else "first"
			var walked := 0
			while not _on_a_step(instance, second_half) and walked < 2000:
				instance.step(STEP)
				walked += 1
			t.check(_on_a_step(instance, second_half),
					"the %s stride is on a step in its %s half" % [view, half])
			await DrawnEvent.frames(t)
			t.check(not _the_dog_drawn(instance).has(rest),
					"a %s dog mid-step in the %s half is not on its rest picture" % [view, half])
			instance.step(0.0)
			await DrawnEvent.frames(t)
			t.check(not instance.gait_is_moving(), "a tick with no ground covered is not a step")
			t.check(_the_dog_drawn(instance) == [rest],
					"a %s dog stopped in the %s half stands in its rest pose" % [view, half])
		instance.free()

## The pictures of the dog (`events/dog…`) that `instance` was last drawn with.
func _the_dog_drawn(instance: EventInstance) -> Array[String]:
	var pictures: Array[String] = []
	for entry in DrawnEvent.shown(instance):
		var picture: String = entry.picture
		if picture.begins_with("events/dog"):
			pictures.append(picture)
	return pictures

## The victim's own scripted walk to the van is a straight lerp over `AbductionSpec.taken_over()` seconds
## rather than anything that touches `_path_travelled`, so it gets its own derived query
## (`victim_gait_is_stepping()`) instead of sharing `_gait_phase` — see that function's own doc. It
## must start on frame a (`sin(0) == 0`) and later step, the same shape the distance-driven gait
## has, over the fixed walk rather than an open-ended one.
func _test_victim_gait_starts_on_frame_a_and_later_steps(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("abduction")
	var event := FakeEvent.new()
	# A third of the way into the walk, so a look that ignored whether a take is running would be
	# stepping.
	event.victim_walked = def.takes_a_victim_by().taken_over() * 0.37
	var look := event.look_for(def)
	t.check(not look.victim_gait_is_stepping(), "no take is running yet")
	event.taking_a_victim = true
	event.victim_walked = 0.0
	t.check(not look.victim_gait_is_stepping(), "the walk starts on frame a")
	var saw_b := false
	var steps := int(def.takes_a_victim_by().taken_over() / STEP)
	for i in steps:
		event.victim_walked += STEP
		if look.victim_gait_is_stepping():
			saw_b = true
	t.check(saw_b, "the walk steps into its own mid-stride frame before it finishes")
	event.free()

# ------------------------------------------------------------------- the idle timer ---

## Neither the café sitters nor the busker ever move — `EventCatalogue._cafe_tables()`
## and `_busker()` are both stationary rows — so their own alternation has to come from
## `idle_is_stepping()`'s timer rather than any distance covered, and it does actually flip both
## ways over a long enough run.
func _test_idle_families_alternate_on_time_without_moving(t: TestRunner) -> void:
	var periods := {
		"cafe_tables": EventPictures.SITTER_IDLE_PERIOD,
		"busker": EventPictures.BUSKER_STRUM_PERIOD,
	}
	for def_id: String in periods:
		var period: float = periods[def_id]
		var ticks := int(period / STEP) * 3 + 10
		var instance := EventInstance.new()
		instance.setup(Shipped.rows().by_id(def_id), Vector2.ZERO)
		var start := instance.global_position
		for i in ticks:
			instance.step(STEP)
		t.check(instance.global_position == start, "%s never moves" % def_id)
		instance.free()
		var event := FakeEvent.new()
		var look := event.look_for(Shipped.rows().by_id(def_id))
		var saw_true := false
		var saw_false := false
		for i in ticks:
			event.tick(STEP, 0.0)
			if look.idle_is_stepping(period):
				saw_true = true
			else:
				saw_false = true
		t.check(saw_true and saw_false, "%s's idle timer alternates over %d ticks" % [def_id, ticks])
		event.free()

## "A per-instance phase offset from the instance's own RNG stream so a row of sitters does not
## lean in unison": two cafés sited at different positions must draw different offsets.
func _test_idle_phase_offset_differs_by_siting(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("cafe_tables")
	var a := EventInstance.new()
	a.setup(def, Vector2(0.0, 0.0))
	var b := EventInstance.new()
	b.setup(def, Vector2(517.0, 233.0))
	t.check(a.idle_offset() != b.idle_offset(),
			"two different sitings draw two different idle-phase offsets")
	a.free()
	b.free()

# ------------------------------------------------------------------- resets ---

## "A stride never starts mid-cycle": both `setup()` and `restore()` reset the gait phase to zero.
func _test_gait_and_idle_phase_reset_on_setup(t: TestRunner) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(Shipped.rows().by_id("dog_walker"), Vector2.ZERO, route,
			Vector2.RIGHT)
	for i in 40:
		instance.step(STEP)
	t.check(instance.gait_phase() != 0.0, "the phase has moved on from its starting value")
	instance.setup(Shipped.rows().by_id("dog_walker"), Vector2.ZERO, route,
			Vector2.RIGHT)
	t.check(instance.gait_phase() == 0.0 and not instance.gait_is_moving(),
			"a fresh setup() resets the phase rather than carrying it over")
	instance.restore(EventSave.new(5.0, 30.0))
	t.check(instance.gait_phase() == 0.0 and not instance.gait_is_moving(),
			"restore() resets the phase too, so a restored instance never starts mid-cycle")
	instance.free()

# ------------------------------------------------------------------- the halo ---

## "One lookup picks the frame for the whole draw, as the walker does": `gait_is_stepping()` is a
## pure read of state `_process()` already settled this tick, so the main draw and every halo ring
## calling it again within the same frame must all agree — exactly the property that keeps a
## walking entity's halo from showing a different frame than its own body.
func _test_gait_query_is_stable_within_a_tick(t: TestRunner) -> void:
	var event := FakeEvent.new()
	var look := event.look_for(Shipped.rows().by_id("dog_walker"))
	_walk_to(event, WALK[5])
	var first := look.gait_is_stepping()
	for i in 5:
		t.check(look.gait_is_stepping() == first,
				"repeated calls within the same tick agree, the way a halo ring's own re-draw needs")
	event.free()

# ------------------------------------------------------------------- helpers ---

## `event` walked on to `point` (ground covered, the stride's phase there), striding as a real one
## is once it has set off.
static func _walk_to(event: FakeEvent, point: Vector2) -> void:
	event.tick(STEP, point.x - event.travelled)
	event.stride = point.y
	event.striding = point.x > 0.0

## Whether `instance`'s stride is on a step in the half of its turn `second_half` names: moving, and
## well inside the first quarter of that half's turn, where a stride is a step (`sin(phase * 2.0)`
## is positive on the first quarter of each half and negative on the second).
static func _on_a_step(instance: EventInstance, second_half: bool) -> bool:
	var turn := instance.gait_phase() - (PI if second_half else 0.0)
	return instance.gait_is_moving() and turn > 0.2 and turn < PI / 2.0 - 0.2
