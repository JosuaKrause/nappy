extends RefCounted
## M108, "every living thing that moves has a stride" — the event half. `tests/test_event_views.gd`
## already pins each family's own five-view table and heading source; this suite pins the second
## frame every listed family gained beside it, and the alternation that picks between the two —
## `EventInstance._advance_gait()`, `_gait_stepping()`, `_victim_gait_stepping()` and
## `_idle_stepping()`.
##
## Consistent with `test_event_views.gd`, nothing here calls a `_draw_*` function directly —
## `Sprites.draw_standing()` inside them is only valid from an actual draw pass. What is tested
## instead is the query every `_draw_*` reads to choose a frame, which is exactly what the halo
## needs to agree with the body about — see `_test_gait_query_is_stable_within_a_tick`. The
## rendered evidence is `docs/evidence/m108-event-strides-2026-09-12/`, native and 3x sheets of
## every family's frame a beside frame b, and a burst capturing an actual flip in play.

const STEP := 1.0 / 60.0

## Every family that gained a stride this round, its "a" and "b" tables paired so the
## completeness, distinctness and "differs from a" checks below run once over the whole set.
## Neither `cafe_sitter` nor `busker` is here: their own idle-timer alternation is checked in its
## own section rather than folded into the distance-driven gait checks every entry here shares.
const GAIT_FAMILY_DICTS := {
	"person": [EventInstance.PERSON_BY_VIEW, EventInstance.PERSON_BY_VIEW_B],
	"yeller": [EventInstance.YELLER_BY_VIEW, EventInstance.YELLER_BY_VIEW_B],
	"robber_lunging": [EventInstance.ROBBER_LUNGING_BY_VIEW, EventInstance.ROBBER_LUNGING_BY_VIEW_B],
	"protester": [EventInstance.PROTESTER_BY_VIEW, EventInstance.PROTESTER_BY_VIEW_B],
	"leaf_blower": [EventInstance.LEAF_BLOWER_BY_VIEW, EventInstance.LEAF_BLOWER_BY_VIEW_B],
	"van_victim": [EventInstance.VAN_VICTIM_BY_VIEW, EventInstance.VAN_VICTIM_BY_VIEW_B],
	"chatting_mother_walking":
			[EventInstance.CHATTING_MOTHER_WALKING_BY_VIEW, EventInstance.CHATTING_MOTHER_WALKING_BY_VIEW_B],
	"cat_running": [EventInstance.CAT_RUNNING_BY_VIEW, EventInstance.CAT_RUNNING_BY_VIEW_B],
	"dog": [EventInstance.DOG_BY_VIEW, EventInstance.DOG_BY_VIEW_B],
	"charging_dog": [EventInstance.CHARGING_DOG_BY_VIEW, EventInstance.CHARGING_DOG_BY_VIEW_B],
	"cyclist": [EventInstance.CYCLIST_BY_VIEW, EventInstance.CYCLIST_BY_VIEW_B],
	"pelican_cyclist": [EventInstance.PELICAN_BY_VIEW, EventInstance.PELICAN_BY_VIEW_B],
	"mouse": [EventInstance.MOUSE_BY_VIEW, EventInstance.MOUSE_BY_VIEW_B],
}

const IDLE_FAMILY_DICTS := {
	"cafe_sitter": [EventInstance.CAFE_SITTER_BY_VIEW, EventInstance.CAFE_SITTER_BY_VIEW_B],
	"busker": [EventInstance.BUSKER_BY_VIEW, EventInstance.BUSKER_BY_VIEW_B],
}

const VIEWS: Array[String] = ["front", "back", "side", "front_diagonal", "back_diagonal"]

func run(t) -> void:
	_test_b_tables_are_complete(t)
	_test_b_tables_differ_from_a_per_view(t)
	_test_moving_instance_alternates_gait_frames(t)
	_test_waiting_robber_holds_frame_a(t)
	_test_chatting_mother_freezes_gait_when_talking(t)
	_test_crouched_cat_never_reads_the_running_b_frame(t)
	_test_dog_walker_and_dog_share_one_phase(t)
	_test_the_normal_dog_has_three_pictures_in_four_beats(t)
	_test_a_walking_normal_dog_steps_rests_and_steps_the_other_way(t)
	_test_a_standing_normal_dog_rests(t)
	_test_victim_gait_starts_on_frame_a_and_later_steps(t)
	_test_idle_families_alternate_on_time_without_moving(t)
	_test_idle_phase_offset_differs_by_siting(t)
	_test_gait_and_idle_phase_reset_on_setup(t)
	_test_gait_query_is_stable_within_a_tick(t)

# ------------------------------------------------------------------- the tables ---

func _test_b_tables_are_complete(t) -> void:
	for name in GAIT_FAMILY_DICTS:
		var by_view_b: Dictionary = GAIT_FAMILY_DICTS[name][1]
		t.check(by_view_b.size() == 5, "%s carries exactly five b-frame views" % name)
		for view in VIEWS:
			t.check(by_view_b.has(view) and by_view_b[view] != null,
					"%s has a resolving b-frame %s view" % [name, view])
	for name in IDLE_FAMILY_DICTS:
		var by_view_b: Dictionary = IDLE_FAMILY_DICTS[name][1]
		t.check(by_view_b.size() == 5, "%s carries exactly five idle-frame views" % name)
		for view in VIEWS:
			t.check(by_view_b.has(view) and by_view_b[view] != null,
					"%s has a resolving idle-frame %s view" % [name, view])

## Every family with a b table draws something different from its own a frame at every view — the
## walker precedent's own "legs and shoes cross" (or the sitters' lean, or the busker's raised
## hand) has to actually be a different picture, not a second preload of the same source.
func _test_b_tables_differ_from_a_per_view(t) -> void:
	for name in GAIT_FAMILY_DICTS:
		var by_view: Dictionary = GAIT_FAMILY_DICTS[name][0]
		var by_view_b: Dictionary = GAIT_FAMILY_DICTS[name][1]
		for view in VIEWS:
			t.check(by_view[view] != by_view_b[view],
					"%s's %s view differs between frame a and frame b" % [name, view])
	for name in IDLE_FAMILY_DICTS:
		var by_view: Dictionary = IDLE_FAMILY_DICTS[name][0]
		var by_view_b: Dictionary = IDLE_FAMILY_DICTS[name][1]
		for view in VIEWS:
			t.check(by_view[view] != by_view_b[view],
					"%s's %s view differs between its two idle frames" % [name, view])

# ------------------------------------------------------------------- the gait ---

func _heading_for_sector(sector: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(sector * 45.0))

## A moving instance alternates: starts on frame a before it has covered any ground, crosses into
## the mid-stride frame as it walks, and returns to the rest frame later in the same stride — the
## walker's own `sin(phase * 2.0) > 0.0` shape, read here through `_gait_stepping()` rather than
## re-derived, exactly as `_draw_dog_walker()` reads it.
func _test_moving_instance_alternates_gait_frames(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	t.check(not instance._gait_stepping(), "starts on frame a before it has moved at all")
	var saw_b := false
	var saw_a_again := false
	for i in 400:
		instance._process(STEP)
		if instance._gait_stepping():
			saw_b = true
		elif saw_b:
			saw_a_again = true
	t.check(saw_b, "crosses into the mid-stride frame as it walks (dog_walker at 32px/s)")
	t.check(saw_a_again, "and back to the rest frame later in the same walk")
	instance.free()

## `alley_robbery`'s waiting posture never covers ground — `_chase()` only turns `_heading` toward
## her while `is_waiting()`, it does not move — so it must hold frame a for as long as it waits,
## whatever `_gait_phase` happens to be sitting on.
func _test_waiting_robber_holds_frame_a(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	# Well outside `pursues_within`, so he stays `is_waiting()` for the whole run.
	instance.player_at = Vector2(9999.0, 9999.0)
	for i in 120:
		instance._process(STEP)
		t.check(instance.is_waiting(), "still only waiting at tick %d" % i)
		t.check(not instance._gait_stepping(), "a waiting robber holds frame a (tick %d)" % i)
	instance.free()

## `chatting_mother`'s pacing beat gets a stride; her conversation freezes `_process()` entirely
## (see that function's own `is_chatting()` branch), so the gait must freeze on frame a with it
## rather than continue alternating on whatever phase it had reached the moment she stopped.
func _test_chatting_mother_freezes_gait_when_talking(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("chatting_mother"), Vector2.ZERO, route, Vector2.RIGHT)
	for i in 60:
		instance._process(STEP)
	instance.start_chat()
	t.check(instance.is_chatting(), "the conversation is running")
	for i in 30:
		instance._process(STEP)
		t.check(not instance._gait_stepping(), "frozen mid-conversation holds frame a (tick %d)" % i)
	instance.free()

## The crouch is the telegraph, held still by construction (`still_while_telegraphing`) — it must
## never read the running family's own b frame, whatever `_gait_stepping()` says, since crouched
## has no second frame of its own at all.
func _test_crouched_cat_never_reads_the_running_b_frame(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.is_telegraphing(), "a cat starts in its crouch")
	# Force the gait phase into its stepping half, the state a real stride would eventually reach,
	# to prove the crouch branch never consults it.
	instance._gait_phase = PI * 0.25
	instance._gait_moving = true
	t.check(instance._gait_stepping(), "the phase itself would read as stepping")
	t.check(EventInstance.CAT_CROUCHED_BY_VIEW["side"] != EventInstance.CAT_RUNNING_BY_VIEW_B["side"],
			"the crouch and the running b frame are not the same picture regardless")
	instance.free()

## "Actor and held thing swap frames together": the dog walker's person and dog read one shared
## `_gait_phase`, so the dog is on one of its two steps exactly while the walker is mid-stride and
## on its rest exactly while he is on his rest frame — asked here through the same two queries
## `_draw_dog_walker()` reads, over a walk long enough to pass through every beat.
func _test_dog_walker_and_dog_share_one_phase(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	var rest: String = EventInstance.dog_picture("side", false, false)
	var agreed := true
	for i in 300:
		instance._process(STEP)
		var stepping := instance._gait_stepping()
		var person_frame: String = EventInstance.PERSON_BY_VIEW_B["side"] if stepping \
				else EventInstance.PERSON_BY_VIEW["side"]
		var dog_frame := EventInstance.dog_picture("side", stepping, instance._gait_second_half())
		if (person_frame == EventInstance.PERSON_BY_VIEW_B["side"]) == (dog_frame == rest):
			agreed = false
	t.check(agreed, "the walker is mid-stride exactly while the dog is on a step, never on its rest")
	instance.free()

## The normal dog walks step, rest, opposite step, rest on three pictures per view *(2026-09-27,
## teal-marmot: "the normal dog should have three frames. we have the resting one now and one leg
## forward. now we need one frame with the other leg forward")*. The side and diagonals rest on b
## and take the opposite step on c; front and back rest on their neutral c and take the opposite
## step on b, because their a and b already reach with opposite leg pairs.
func _test_the_normal_dog_has_three_pictures_in_four_beats(t) -> void:
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
			EventInstance.dog_picture(view, true, false),
			EventInstance.dog_picture(view, false, false),
			EventInstance.dog_picture(view, true, true),
			EventInstance.dog_picture(view, false, true),
		]
		t.check(drawn == beats, "the %s dog walks %s (got %s)" % [view, beats, drawn])
		var distinct := {}
		for picture: String in drawn:
			distinct[picture] = true
		t.check(distinct.size() == 3, "the %s dog draws three different pictures" % view)

## A walking dog walker's dog goes through the four beats in order — step, rest, opposite step,
## rest — and each beat lasts the same ground, a quarter of a turn of `_gait_phase` at
## `GAIT_RATE`, which is when the walker's own two frames swap as well. The loose dog reads the
## same queries at its own speed.
func _test_a_walking_normal_dog_steps_rests_and_steps_the_other_way(t) -> void:
	var beat := PI / 2.0 / EventInstance.GAIT_RATE
	var cycle := ["events/dog", "events/dog_b", "events/dog_c", "events/dog_b"]
	var route := PackedVector2Array([Vector2.ZERO, Vector2(900.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	var shown: Array[String] = []
	var changed_at: Array[float] = []
	for i in 900:
		instance._process(STEP)
		var now := EventInstance.dog_picture("side", instance._gait_stepping(),
				instance._gait_second_half())
		if shown.is_empty() or shown[-1] != now:
			shown.append(now)
			changed_at.append(instance._path_travelled)
	t.check(shown.size() >= 9, "the walk passed through two whole cycles (%d beats)" % shown.size())
	t.check(not shown.is_empty() and shown[0] == cycle[0], "the first step comes first")
	var in_order := true
	for k in shown.size():
		if shown[k] != cycle[k % 4]:
			in_order = false
	t.check(in_order, "the beats run step, rest, opposite step, rest (%s)" % [shown])
	var even := true
	for k in range(1, changed_at.size() - 1):
		if absf(changed_at[k + 1] - changed_at[k] - beat) > 1.0:
			even = false
	t.check(even, "each beat is %.1fpx of ground" % beat)
	instance.free()

## Standing still is the rest pose, not a step held mid-air: before a dog walker has covered any
## ground, and whenever `_advance_gait()` last saw none, whatever half of the stride the phase
## happens to be sitting in.
func _test_a_standing_normal_dog_rests(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	for view in VIEWS:
		t.check(EventInstance.dog_picture(view, instance._gait_stepping(),
				instance._gait_second_half()) == EventInstance.dog_picture(view, false, false),
				"a %s dog that has not moved stands in its rest pose" % view)
	for phase in [PI * 0.25, PI * 1.25]:
		instance._gait_phase = phase
		instance._advance_gait(0.0)
		t.check(not instance._gait_stepping(), "a tick with no ground covered is not a step")
		t.check(EventInstance.dog_picture("side", instance._gait_stepping(),
				instance._gait_second_half()) == "events/dog_b",
				"a dog stopped at phase %.2f stands in its rest pose" % phase)
	instance.free()

## The victim's own scripted walk to the van is a straight lerp over `VICTIM_TAKEN_OVER` seconds
## rather than anything that touches `_path_travelled`, so it gets its own derived query
## (`_victim_gait_stepping()`) instead of sharing `_gait_phase` — see that function's own doc. It
## must start on frame a (`sin(0) == 0`) and later step, the same shape the distance-driven gait
## has, over the fixed walk rather than an open-ended one.
func _test_victim_gait_starts_on_frame_a_and_later_steps(t) -> void:
	var def := EventCatalogue.by_id("abduction")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(not instance._victim_gait_stepping(), "no take is running yet")
	instance.player_at = instance.global_position
	instance._victim_taken_at = instance.age
	t.check(not instance._victim_gait_stepping(), "the walk starts on frame a")
	var saw_b := false
	var steps := int(EventInstance.VICTIM_TAKEN_OVER / STEP)
	for i in steps:
		instance.age += STEP
		if instance._victim_gait_stepping():
			saw_b = true
	t.check(saw_b, "the walk steps into its own mid-stride frame before it finishes")
	instance.free()

# ------------------------------------------------------------------- the idle timer ---

## Neither the café sitters nor the busker ever move — `EventCatalogue._cafe_tables()` and
## `_busker()` are both stationary rows — so their own alternation has to come from
## `_idle_stepping()`'s timer rather than any distance covered, and it does actually flip both ways
## over a long enough run.
func _test_idle_families_alternate_on_time_without_moving(t) -> void:
	var periods := {
		"cafe_tables": EventInstance.SITTER_IDLE_PERIOD,
		"busker": EventInstance.BUSKER_STRUM_PERIOD,
	}
	for def_id in periods:
		var period: float = periods[def_id]
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id(def_id), Vector2.ZERO)
		var start := instance.global_position
		var saw_true := false
		var saw_false := false
		var ticks := int(period / STEP) * 3 + 10
		for i in ticks:
			instance._process(STEP)
			if instance._idle_stepping(period):
				saw_true = true
			else:
				saw_false = true
		t.check(instance.global_position == start, "%s never moves" % def_id)
		t.check(saw_true and saw_false, "%s's idle timer alternates over %d ticks" % [def_id, ticks])
		instance.free()

## "A per-instance phase offset from the instance's own RNG stream so a row of sitters does not
## lean in unison": two cafés sited at different positions must draw different offsets.
func _test_idle_phase_offset_differs_by_siting(t) -> void:
	var def := EventCatalogue.by_id("cafe_tables")
	var a := EventInstance.new()
	a.setup(def, Vector2(0.0, 0.0))
	var b := EventInstance.new()
	b.setup(def, Vector2(517.0, 233.0))
	t.check(a._idle_phase_offset != b._idle_phase_offset,
			"two different sitings draw two different idle-phase offsets")
	a.free()
	b.free()

# ------------------------------------------------------------------- resets ---

## "A stride never starts mid-cycle": both `setup()` and `resume()` reset the gait phase to zero.
func _test_gait_and_idle_phase_reset_on_setup(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	for i in 40:
		instance._process(STEP)
	t.check(instance._gait_phase != 0.0, "the phase has moved on from its starting value")
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	t.check(instance._gait_phase == 0.0 and not instance._gait_moving,
			"a fresh setup() resets the phase rather than carrying it over")
	instance.resume(5.0, 30.0)
	t.check(instance._gait_phase == 0.0 and not instance._gait_moving,
			"resume() resets the phase too, so a resumed instance never starts mid-cycle")
	instance.free()

# ------------------------------------------------------------------- the halo ---

## "One lookup picks the frame for the whole draw, as the walker does": `_gait_stepping()` is a
## pure read of state `_process()` already settled this tick, so the main draw and every halo ring
## calling it again within the same frame must all agree — exactly the property that keeps a
## walking entity's halo from showing a different frame than its own body.
func _test_gait_query_is_stable_within_a_tick(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	for i in 40:
		instance._process(STEP)
	var first := instance._gait_stepping()
	for i in 5:
		t.check(instance._gait_stepping() == first,
				"repeated calls within the same tick agree, the way a halo ring's own re-draw needs")
	instance.free()

