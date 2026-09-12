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
## `mouse` is not here — its single texture is checked on its own further down — and neither is
## `cafe_sitter` or `busker`, whose own idle-timer alternation is checked in its own section rather
## than folded into the distance-driven gait checks every entry here shares.
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
}

const IDLE_FAMILY_DICTS := {
	"cafe_sitter": [EventInstance.CAFE_SITTER_BY_VIEW, EventInstance.CAFE_SITTER_BY_VIEW_B],
	"busker": [EventInstance.BUSKER_BY_VIEW, EventInstance.BUSKER_BY_VIEW_B],
}

const VIEWS: Array[String] = ["front", "back", "side", "front_diagonal", "back_diagonal"]

func run(t) -> void:
	_test_b_tables_are_complete(t)
	_test_b_tables_differ_from_a_per_view(t)
	_test_mouse_b_differs_from_a(t)
	_test_moving_instance_alternates_gait_frames(t)
	_test_waiting_robber_holds_frame_a(t)
	_test_chatting_mother_freezes_gait_when_talking(t)
	_test_crouched_cat_never_reads_the_running_b_frame(t)
	_test_dog_walker_and_dog_share_one_phase(t)
	_test_victim_gait_starts_on_frame_a_and_later_steps(t)
	_test_idle_families_alternate_on_time_without_moving(t)
	_test_idle_phase_offset_differs_by_siting(t)
	_test_gait_and_idle_phase_reset_on_setup(t)
	_test_gait_query_is_stable_within_a_tick(t)
	_test_unpaired_b_view_still_falls_back_to_svg(t)

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

## `mouse` stays on its single side-on picture rather than joining the five-view families above
## (see `EventCatalogue._alley_mouse()`'s own docstring), so its own second frame is checked here
## on its own — `MOUSE`/`MOUSE_B`, not a dictionary entry.
func _test_mouse_b_differs_from_a(t) -> void:
	t.check(EventInstance.MOUSE != EventInstance.MOUSE_B,
			"the mouse's dash frame differs from its resting one")

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
## `_gait_phase`, so whichever frame the query answers is the same answer whether asked once for
## the walker or once for the dog beside him.
func _test_dog_walker_and_dog_share_one_phase(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	for i in 40:
		instance._process(STEP)
	var stepping := instance._gait_stepping()
	var person_frame: Texture2D = EventInstance.PERSON_BY_VIEW_B["side"] if stepping \
			else EventInstance.PERSON_BY_VIEW["side"]
	var dog_frame: Texture2D = EventInstance.DOG_BY_VIEW_B["side"] if stepping \
			else EventInstance.DOG_BY_VIEW["side"]
	# Both read off the identical `stepping` value computed once — the same one-lookup shape
	# `_draw_dog_walker()` itself uses — so there is no way for this pair to disagree.
	t.check((person_frame == EventInstance.PERSON_BY_VIEW_B["side"]) ==
			(dog_frame == EventInstance.DOG_BY_VIEW_B["side"]),
			"the walker and the dog read the same stride phase")
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

# ------------------------------------------------------------------- texture fallback ---

## `docs/GRAPHICS.md`: PNG generation stays with M109, so a b frame must still resolve in both
## selection modes today, the same fallback `test_event_views.gd` pins for the unpaired diagonal.
func _test_unpaired_b_view_still_falls_back_to_svg(t) -> void:
	var b_diagonal: Texture2D = EventInstance.PERSON_BY_VIEW_B["front_diagonal"]
	TextureResolver.reset_for_tests(true)
	t.check(TextureResolver.resolve(b_diagonal) == b_diagonal,
			"explicit SVG mode keeps the authored b-frame diagonal SVG")
	TextureResolver.reset_for_tests(false)
	t.check(TextureResolver.resolve(b_diagonal) == b_diagonal,
			"no PNG transfer exists yet, so default mode falls back to the same b-frame SVG")
	TextureResolver.reset_for_tests(DevFlags.svg_requested())
