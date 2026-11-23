extends RefCounted
## The gate that stops an event rebuilding a draw list it does not need —
## `EventLook.redraw_if_the_picture_changed()`, the picture key behind it and
## `_picture_never_settles()`. The crowd has had the same gate for a long time
## (`CrowdAgent.end_the_frame()`); events did not, and at about forty live
## instances a day that was the largest drawing cost in a frame
## (`docs/evidence/m124-frame-cost-2026-09-13/README.md`).
##
## **What this suite holds is the gate's answer, because the answer is the decision.** What is
## asserted is what `redraw_if_the_picture_changed()` answers each time the game's `_process()`
## would ask it, which is the whole of its decision: a gate that does not ask is a draw list that is
## not rebuilt, and a gate that asks while the picture moves is the guarantee that nothing animated
## was frozen by it. A headless run does draw, so a count of `draw` signals could hold the same
## thing, but it says nothing about what was drawn, and the key the gate compares does. The rendered half is the bursts in
## `docs/evidence/m124-frame-fixes-2026-09-13/`.
##
## Nothing here calls a `_draw_*` function — `Sprites.draw_standing()` inside them is only valid
## from an actual draw pass, the same rule `tests/test_event_strides.gd` and
## `tests/test_event_views.gd` both follow.
##
## **The gate is asked of a look made round a fake event** (`FakeEvent.look_for()`): the suite
## writes what the event would answer after each tick (its age, its clock, the ground it has
## covered, and the stride that ground makes, `WALK`) and reads whether the gate asks for a
## draw, so a live event, its row's behaviours and its street are no part of what is tested. Two
## cases ask a real event over real frames, because what they hold is what the game's own frames
## do: `_test_the_gate_stores_the_key_it_compared` (after a settled draw the frames after it
## draw nothing) and `_test_the_normal_dogs_opposite_step_is_another_picture` (which pictures a
## real dog is told to stand in the two halves of its stride).

const STEP := 1.0 / 60.0
const DrawnEvent := preload("res://tests/drawn_event.gd")

## What a real dog walker answers walking its route, read off one set up on open ground and
## walked eight and three-quarter pixels at a time (half a beat of its stride, `PI / 2 /
## GAIT_RATE` being a beat): the ground covered (x) and the stride's phase it reads (y), the
## first point the event standing still. Every point after the first is one it has set off to,
## so it is striding.
const WALK: PackedVector2Array = [
	Vector2(0.0, 0.0), Vector2(8.75, 0.7875), Vector2(17.5, 1.575), Vector2(26.25, 2.3625),
	Vector2(35.0, 3.15), Vector2(43.75, 3.9375), Vector2(52.5, 4.725), Vector2(61.25, 5.5125),
	Vector2(70.0, 0.0168), Vector2(78.75, 0.8043), Vector2(87.5, 1.5918),
	Vector2(96.25, 2.3793), Vector2(105.0, 3.1668), Vector2(113.75, 3.9543),
	Vector2(122.5, 4.7418), Vector2(131.25, 5.5293), Vector2(140.0, 0.0336),
]

## What a real dog sent off (`leave_for_a_completed_task()`) answers once it has walked to the
## top of a step's bob (17px) and to the opposite step (51.9px, half a turn of the stride
## further), the same for the normal dog, the loose dog and the charging dog: the ground covered
## (x) and the stride's phase (y).
const TOP_OF_THE_BOB := Vector2(17.0, 1.53)
const OPPOSITE_STEP := Vector2(51.907, 4.6716)

func run(t: TestRunner) -> void:
	_test_a_standing_seal_holds_one_key_for_its_whole_life(t)
	await _test_the_gate_stores_the_key_it_compared(t)
	_test_a_striding_event_moves_its_key(t)
	_test_a_bobbing_event_moves_its_key(t)
	_test_the_normal_dogs_opposite_step_moves_its_key(t)
	await _test_the_normal_dogs_opposite_step_is_another_picture(t)
	_test_a_telegraphing_cat_moves_its_key_when_the_crouch_ends(t)
	_test_the_marks_flash_is_in_the_key(t)
	_test_the_caret_strength_is_in_the_key(t)
	_test_the_buskers_strum_moves_the_key_without_him_moving(t)
	_test_the_cafe_sitters_lean_moves_the_key(t)
	_test_separated_details_keep_the_owner_key_stable(t)
	_test_a_waiting_robber_turning_to_face_her_moves_the_key(t)
	_test_a_chatting_mother_moves_her_key_while_frozen(t)
	_test_a_raised_boom_moves_the_gates_key(t)
	_test_a_masts_lamp_and_its_silence_move_its_key(t)
	_test_a_leaving_event_moves_its_key(t)
	_test_the_flock_and_the_drawn_flames_are_never_gated(t)
	_test_a_van_mid_take_is_never_gated_and_says_so_afterwards(t)
	_test_the_key_is_stable_within_a_tick(t)

# ------------------------------------------------------------------ the still ---

## The whole point of the gate, stated as the ratio it is worth: a barricade is a pile in the road
## that never moves, never strides and carries no caret, and it produced a fresh draw list at the
## tick rate for every tick of its life.
##
## **At most one change in five seconds, not none**, and the one is its telegraph ending. The key
## carries `is_telegraphing()` for every row rather than only for the three whose picture reads it
## (`_draw_cat`, `_draw_roadblock`, `_draw_masked_pursuer`, and the mark's own flash), because a
## term a picture does not read costs exactly one redraw in an instance's whole life and a term a
## picture *does* read and the key does not is a frozen picture.
func _test_a_standing_seal_holds_one_key_for_its_whole_life(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("barricade")
	var event := FakeEvent.new()
	event.telegraph_length = def.telegraphs_for()
	var look := event.look_for(def)
	event.telegraphing = true
	_asks(look)
	var changes := 0
	for i in 300:
		event.tick(STEP, 0.0)
		event.telegraphing = event.age() < event.telegraph_length
		if _asks(look):
			changes += 1
	t.check(changes <= 1,
			"a barricade's picture key changes at most once in three hundred ticks (%d)" % changes)
	t.check(not _never_settles(look),
			"and a barricade is not one of the looks that are never gated at all")
	event.free()

## The gate stores whatever it compared, every drawn frame, whether or not it asked for a draw —
## which is what lets the *transition out of* a never-settling state still register as a change.
## What the first asks of a fresh look answer is the look's own; that the game's own frames then
## leave a settled event undrawn is read off a real event over real frames, as its drawer sees
## it.
func _test_the_gate_stores_the_key_it_compared(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("loose_dog")
	var fresh := FakeEvent.new()
	var look := fresh.look_for(def)
	t.check(_asks(look),
			"before its first drawn frame an instance holds a key nothing can equal, so the first draw is asked for")
	t.check(not _asks(look), "and asking again with nothing changed is not a draw")
	fresh.free()
	var instance: EventInstance = await DrawnEvent.stand(t, def, false)
	var drawn := [0]
	instance.draw.connect(func() -> void: drawn[0] += 1)
	await DrawnEvent.frames(t)
	t.check(drawn[0] == 0,
			"after a drawn frame the stored key is the one the gate just computed, so the "
					+ "frames after it draw nothing (%d)" % drawn[0])
	instance.free()

# ------------------------------------------------------------- what still moves ---

## `dog_walker` at 32px/s crosses into its mid-stride frame and back within a few seconds of walking
## (`tests/test_event_strides.gd` pins the alternation itself). Every one of those flips has to
## reach the screen, so every one of them has to move the key.
func _test_a_striding_event_moves_its_key(t: TestRunner) -> void:
	var event := _walker("dog_walker")
	var look := event.look_for(EventCatalogue.by_id("dog_walker"))
	var stepping_changed_the_key := true
	var was_stepping := look.gait_is_stepping()
	_asks(look)
	var flips := 0
	for point: Vector2 in WALK.slice(1):
		_walk_to(event, point)
		var now_stepping := look.gait_is_stepping()
		var asked := _asks(look)
		if now_stepping != was_stepping:
			flips += 1
			if not asked:
				stepping_changed_the_key = false
		was_stepping = now_stepping
	t.check(flips > 0, "the walk actually swapped stride frames (%d times)" % flips)
	t.check(stepping_changed_the_key, "every stride-frame swap moved the picture key")
	event.free()

## The bob is a translation of the whole body, so a walking event redraws for it as well as for its
## stride — that is correct rather than a miss, and it is the reason the win is the scenery rather
## than the traffic. Asserted over a tick where the stride frame did *not* change, so the only
## thing left that could have moved the key is the lift.
func _test_a_bobbing_event_moves_its_key(t: TestRunner) -> void:
	var event := _walker("dog_walker")
	var look := event.look_for(EventCatalogue.by_id("dog_walker"))
	_walk_to(event, WALK[1])
	var moved_on_bob_alone := false
	var was_stepping := look.gait_is_stepping()
	var bob := look.current_bob()
	_asks(look)
	for point: Vector2 in WALK.slice(2):
		_walk_to(event, point)
		var now_stepping := look.gait_is_stepping()
		var now_bob := look.current_bob()
		var asked := _asks(look)
		if now_stepping == was_stepping and not is_equal_approx(now_bob, bob) and asked:
			moved_on_bob_alone = true
		was_stepping = now_stepping
		bob = now_bob
	t.check(moved_on_bob_alone,
			"a walking event's lift moves the key on a tick where its stride frame did not")
	t.check(absf(look.current_bob()) > 0.0, "and the walker was actually bobbing")
	event.free()

## The normal dog's first and opposite steps are both `gait_is_stepping()` and can sit on the same
## bob, so the half of the stride is its own term in the key (`EventPictures.dog_picture()`): two
## states that differ in nothing else still draw different pictures and must not share a key. The
## charging dog has one stepping picture per view, so the same two states are one key for it.
##
## **The two states are the ground a half-stride apart whose bobs are the same**: the bob is
## `|sin|` of the ground covered over 34px, so a walk that ends at the top of the bob (17px) and
## one that goes on a half-turn of the stride further (`PI / GAIT_RATE`, 34.9px) both lift the
## body the same, to the eighth of a pixel the key reads it. The gate is asked of a look made
## round a fake event standing at those two places with the stride a real dog answers there
## (`TOP_OF_THE_BOB`, `OPPOSITE_STEP`); the pictures each state is drawn with are what the real
## dog, walked to the same two places and drawn over real frames, is told to stand.
func _test_the_normal_dogs_opposite_step_moves_its_key(t: TestRunner) -> void:
	for id: String in ["dog_walker", "loose_dog", "charging_dog"]:
		var def := EventCatalogue.by_id(id)
		var event := _walker(id)
		var look := event.look_for(def)
		_asks(look)
		_walk_to(event, TOP_OF_THE_BOB)
		var asked_first := _asks(look)
		var bob := look.current_bob()
		var first_half := look.gait_is_second_half()
		var stepping := look.gait_is_stepping()
		_walk_to(event, OPPOSITE_STEP)
		var asked_opposite := _asks(look)
		t.check(stepping and look.gait_is_stepping()
				and look.gait_is_second_half() != first_half,
				"%s is on a step in both states, in the two halves of the stride" % id)
		t.check(roundi(look.current_bob() * EventLook.BOB_STEPS_PER_PX)
				== roundi(bob * EventLook.BOB_STEPS_PER_PX),
				"%s's two states lift the body the same" % id)
		if id == "charging_dog":
			t.check(not asked_opposite,
					"the charging dog's two halves of a stride are one key (%s, %s)"
							% [asked_first, asked_opposite])
		else:
			t.check(asked_opposite,
					"%s's first step and opposite step are two keys" % id)
		event.free()

## The pictures a normal dog and a charging dog are told to stand in the two states above, read
## off a real one walked to the same two places (`leave_for_a_completed_task()`, then `step()`
## as its manager steps it) and drawn over real frames, which the recording drawer holds: the
## first step and the opposite step are two pictures, and two draws, for the normal dog; the
## charging dog has one stepping picture per view, so its two states are one picture and no
## second draw. The engine's own count of times it drew the event (its `draw` signal) is what is
## counted.
func _test_the_normal_dogs_opposite_step_is_another_picture(t: TestRunner) -> void:
	var to_the_top_of_the_bob := PI / EventPictures.BOB_PER_PX * 0.5
	var half_a_turn := PI / EventInstance.GAIT_RATE
	for id: String in ["dog_walker", "loose_dog", "charging_dog"]:
		var instance: EventInstance = await DrawnEvent.stand(t, EventCatalogue.by_id(id), false)
		var drawn := [0]
		instance.draw.connect(func() -> void: drawn[0] += 1)
		instance.leave_for_a_completed_task()
		var speed := instance.departure_speed()
		t.check(speed > 0.0, "%s walks on once sent off" % id)
		if speed <= 0.0:
			instance.free()
			continue
		instance.step(to_the_top_of_the_bob / speed)
		await DrawnEvent.frames(t)
		var first := _the_dog_drawn(instance)
		var before: int = drawn[0]
		instance.step(half_a_turn / speed)
		await DrawnEvent.frames(t)
		var opposite := _the_dog_drawn(instance)
		var moved_it: bool = drawn[0] > before
		if id == "charging_dog":
			t.check(not moved_it and opposite == first,
					"the charging dog's two halves of a stride are one picture and one key")
		else:
			t.check(moved_it and opposite != first,
					"%s's first step and opposite step are two keys, and two pictures (%s, %s)"
							% [id, first, opposite])
		instance.free()

## The pictures of the dog (`events/dog…`) that `instance` was last drawn with.
func _the_dog_drawn(instance: EventInstance) -> Array[String]:
	var pictures: Array[String] = []
	for entry in DrawnEvent.shown(instance):
		var picture: String = entry.picture
		if picture.begins_with("events/dog") or picture.begins_with("events/charging_dog"):
			pictures.append(picture)
	return pictures

## The crouch *is* the telegraph (`_draw_cat` swaps the whole family at `is_telegraphing()`), so the
## tick the dash starts has to move the key even though nothing about the cat has moved yet.
func _test_a_telegraphing_cat_moves_its_key_when_the_crouch_ends(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var event := _walker("cat_dash")
	event.telegraph_length = def.telegraphs_for()
	event.telegraphing = true
	var look := event.look_for(def)
	event.tick(STEP, 0.0)
	_asks(look)
	# The crouch is over from the next tick on.
	event.telegraphing = false
	event.tick(STEP, 0.0)
	t.check(_asks(look),
			"the crouch giving way to the dash moves the picture key")
	event.free()

# --------------------------------------------------------------------- the mark ---

## The caret flashes while the thing it stands over is still telegraphing — `_draw_mark()` draws
## nothing for the part of every beat past 0.55 — so the flash is part of the picture rather than
## of the mark's size, and the key has to carry it or a caret would freeze on whichever half of the
## beat it was last drawn in.
##
## A cyclist carrying the doubled red caret for as long as it telegraphs, at a swell its
## telegraph holds constant, so the flash is the only thing that can move its key across a beat;
## the gate's own asks are what is counted, one tick at a time. The same cyclist carrying no
## caret is asked for on none of them.
func _test_the_marks_flash_is_in_the_key(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var marked := _walker("cyclist")
	marked.telegraph_length = def.telegraphs_for()
	marked.telegraphing = true
	marked.excitement.caret = 2
	var unmarked := _walker("cyclist")
	unmarked.telegraph_length = def.telegraphs_for()
	unmarked.telegraphing = true
	var marked_look := marked.look_for(def)
	var unmarked_look := unmarked.look_for(def)
	# The ask that puts the caret up is the change from no caret, not the flash.
	_asks(marked_look)
	_asks(unmarked_look)
	var ticks := int(ceil(1.0 / EventPictures.MARK_FLASHES_PER_SECOND / STEP)) + 2
	var changes := 0
	var unmarked_asks := 0
	for i in ticks:
		marked.tick(STEP, 0.0)
		unmarked.tick(STEP, 0.0)
		if _asks(marked_look):
			changes += 1
		if _asks(unmarked_look):
			unmarked_asks += 1
	t.check(changes >= 2,
			"a marked, telegraphing event is drawn again for the flash going off and on across one beat (%d changes)"
					% changes)
	t.check(unmarked_asks == 0,
			"and an unmarked one is drawn on none of those ticks (%d)" % unmarked_asks)
	marked.free()
	unmarked.free()

## The caret's own 0/1/2 strength is a picture — no mark, one mark, a doubled mark — so the same
## look in the same state reads three different keys for the three strengths: each change of the
## strength is drawn on the next ask, and a strength that is the same as the last one is not.
func _test_the_caret_strength_is_in_the_key(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("loose_dog")
	var event := _walker("loose_dog")
	var look := event.look_for(def)
	_asks(look)
	var moved := []
	for strength: int in [0, 1, 2, 0]:
		event.excitement.caret = strength
		moved.append(_asks(look))
	t.check(moved == [false, true, true, true],
			"no caret, a caret, a doubled caret and no caret again each draw it again (%s)" % [moved])
	event.free()

# ---------------------------------------------------------- the idle animations ---

## The busker never moves an inch and never covers any ground, so his strum is driven by
## `idle_is_stepping(BUSKER_STRUM_PERIOD)` rather than by the gait — the one animation in the game a
## distance-driven key would have silenced outright.
func _test_the_buskers_strum_moves_the_key_without_him_moving(t: TestRunner) -> void:
	var event := FakeEvent.new()
	var look := event.look_for(EventCatalogue.by_id("busker"))
	_asks(look)
	var asked := 0
	var swaps := 0
	var was := look.idle_is_stepping(EventPictures.BUSKER_STRUM_PERIOD)
	for i in int(ceil(EventPictures.BUSKER_STRUM_PERIOD * 3.0 / STEP)):
		event.tick(STEP, 0.0)
		var now := look.idle_is_stepping(EventPictures.BUSKER_STRUM_PERIOD)
		if now != was:
			swaps += 1
		was = now
		if _asks(look):
			asked += 1
	t.check(swaps >= 2, "his strum swapped frames over three periods (%d)" % swaps)
	t.check(asked == swaps, "and the key moves exactly when his frame swaps (%d, %d)" % [asked, swaps])
	event.free()

## The same for the café frontage's lean, on its own slower timer — the whole row leans together,
## so one instance's key carries it for every sitter.
func _test_the_cafe_sitters_lean_moves_the_key(t: TestRunner) -> void:
	var event := FakeEvent.new()
	var look := event.look_for(EventCatalogue.by_id("cafe_tables"))
	var asked := 0
	var swaps := 0
	_asks(look)
	var was := look.idle_is_stepping(EventPictures.SITTER_IDLE_PERIOD)
	for i in int(ceil(EventPictures.SITTER_IDLE_PERIOD * 2.5 / STEP)):
		event.tick(STEP, 0.0)
		var now := look.idle_is_stepping(EventPictures.SITTER_IDLE_PERIOD)
		if now != was:
			swaps += 1
		was = now
		if _asks(look):
			asked += 1
	t.check(swaps >= 1 and asked == swaps,
			"a café frontage's key moves exactly when its lean frame swaps (%d, %d)" % [asked, swaps])
	event.free()

## The crash's smoke, the burst main's fountain and the basement vent's steam alternate two frames
## off `idle_is_stepping()` while standing perfectly still. The cloud-only steam moves its owner's
## key; the other two scenes keep theirs stable because their small detail layers own each swap.
func _test_separated_details_keep_the_owner_key_stable(t: TestRunner) -> void:
	var periods := {
		"car_accident": EventPictures.CAR_ACCIDENT_SMOKE_PERIOD,
		"burst_water_main": EventPictures.BURST_MAIN_SPLASH_PERIOD,
		"basement_steam": EventPictures.STEAM_BILLOW_PERIOD,
	}
	for id: String in periods:
		var period: float = periods[id]
		var event := FakeEvent.new()
		var look := event.look_for(EventCatalogue.by_id(id))
		event.tick(STEP, 0.0)
		var was := look.idle_is_stepping(period)
		_asks(look)
		var swaps := 0
		var silent_swaps := 0
		for i in int(ceil(period * 3.0 / STEP)):
			event.tick(STEP, 0.0)
			var now := look.idle_is_stepping(period)
			var asked := _asks(look)
			if now != was:
				swaps += 1
				if not asked:
					silent_swaps += 1
			was = now
		t.check(swaps >= 2, "%s swapped frames at least twice while live (%d)" % [id, swaps])
		if id == "basement_steam":
			t.check(silent_swaps == 0, "every cloud-only steam swap moves its owner's key")
		else:
			t.check(silent_swaps == swaps, "%s's small-detail swaps leave its owner key alone" % id)
		event.free()
	# The crash's two frames stand on the same ground contacts, so the second frame keeps the shadow.
	for vertical: bool in [false, true]:
		var a := EventPictures.wide_scene_texture(EventDef.Look.CAR_ACCIDENT, vertical)
		var b := EventPictures.wide_scene_texture(EventDef.Look.CAR_ACCIDENT, vertical, true)
		t.check(a != b, "the crash has its own second frame (vertical %s)" % vertical)
		t.check(EventPictures.wide_scene_shadow(b) == EventPictures.wide_scene_shadow(a),
				"and it draws the first frame's shadow (vertical %s)" % vertical)
		t.check(EventPictures.wide_scene_texture(EventDef.Look.BURST_MAIN, vertical, true)
				!= EventPictures.wide_scene_texture(EventDef.Look.BURST_MAIN, vertical),
				"the burst main has its own second frame (vertical %s)" % vertical)

# ------------------------------------------------------- what turns without moving ---

## `_draw_robber()` picks a waiting man's view from `robber_waiting_heading()` — where she is —
## rather than from the alley he was sited facing, so he turns to watch her while standing perfectly
## still. Nothing else in the game changes its picture with neither a step nor a clock behind it,
## and a key reading `_heading` alone would have frozen him facing his siting for ever.
func _test_a_waiting_robber_turning_to_face_her_moves_the_key(t: TestRunner) -> void:
	var event := FakeEvent.new()
	event.waiting = true
	var look := event.look_for(EventCatalogue.by_id("alley_robbery"))
	# He waits, and the line to her is turned half a turn from one tick to the next.
	event.line_to_her = Vector2(9000.0, 0.0)
	event.tick(STEP, 0.0)
	_asks(look)
	event.line_to_her = Vector2(-9000.0, 0.0)
	event.tick(STEP, 0.0)
	t.check(_asks(look),
			"a waiting robber turning to face her moves the key with no step taken")
	event.free()

## Her conversation freezes `_process()` — no distance, no gait — and the posture swap is the only
## telegraph that mechanic has, so it must move the key from inside the frozen branch.
func _test_a_chatting_mother_moves_her_key_while_frozen(t: TestRunner) -> void:
	var event := _walker("chatting_mother")
	var look := event.look_for(EventCatalogue.by_id("chatting_mother"))
	# On a resting beat of her stride, which a stop leaves resting too, so the posture is all
	# that changes.
	_walk_to(event, WALK[3])
	_asks(look)
	event.chatting = true
	event.striding = false
	event.tick(STEP, 0.0)
	t.check(_asks(look),
			"the talking posture moves the key although she has stopped dead")
	event.free()

## A boom gate's whole picture is one bit somebody else owns — `GateState.is_boom_up()`,
## advanced by `Crowd` — and the gate never moves, never strides and never telegraphs, so that bit
## is the only thing between a raised boom and a lowered one reaching the screen.
func _test_a_raised_boom_moves_the_gates_key(t: TestRunner) -> void:
	var event := FakeEvent.new()
	event.heading = Vector2.DOWN
	var look := event.look_for(EventCatalogue.by_id("checkpoint_gate"))
	event.tick(STEP, 0.0)
	_asks(look)
	event.raised = true
	event.tick(STEP, 0.0)
	t.check(_asks(look), "raising the boom moves the gate's key")
	event.free()

## An event that is over leaves rather than vanishing, and it bobs on the way out
## (`current_bob()`'s own `is_on_its_way_out()` branch) — so the departure is drawn rather than held on the
## last frame the event was still an event.
func _test_a_leaving_event_moves_its_key(t: TestRunner) -> void:
	var event := _walker("loose_dog")
	var look := event.look_for(EventCatalogue.by_id("loose_dog"))
	event.tick(STEP, 0.0)
	_asks(look)
	event.on_its_way_out = true
	event.tick(STEP, 0.0)
	t.check(_asks(look), "the departure moves the key")
	event.free()

# --------------------------------------------------- what is never gated at all ---

## Four pictures are continuous functions of the clock rather than a frame chosen from a set, and
## the gate steps aside for all four rather than pretending a key could name them.
func _test_the_flock_and_the_drawn_flames_are_never_gated(t: TestRunner) -> void:
	var flock := FakeEvent.new()
	flock.flock.append(EventFlock.Bird.new())
	var flock_look := flock.look_for(EventCatalogue.by_id("pigeon_flock"))
	t.check(_never_settles(flock_look),
			"a flock is never gated — every bird moves every tick")
	flock.free()

	var fire := FakeEvent.new()
	fire.map = WorldMap.open_ground()
	t.check(_never_settles(fire.look_for(EventCatalogue.by_id("burning_building"))),
			"a burning building's flames are never gated")
	fire.free()

	var firefight := FakeEvent.new()
	firefight.map = WorldMap.open_ground()
	t.check(_never_settles(firefight.look_for(EventCatalogue.by_id("firefight"))),
			"a firefight's muzzle flashes are never gated")
	firefight.free()

	var stall := FakeEvent.new()
	t.check(not _never_settles(stall.look_for(EventCatalogue.by_id("market_stall"))),
			"and a market stall is gated like any other scenery")
	stall.free()

## The van's victim slides to the van over `AbductionSpec.taken_over()` seconds, so it is never gated while
## the take runs — and the *end* of the take is a change the key itself has to carry, or the last
## frame of the walk would stay on the screen with nobody in it.
func _test_a_van_mid_take_is_never_gated_and_says_so_afterwards(t: TestRunner) -> void:
	var event := FakeEvent.new()
	var look := event.look_for(EventCatalogue.by_id("abduction"))
	t.check(not _never_settles(look), "an idle van is gated like any other vehicle")
	event.taking_a_victim = true
	event.tick(STEP, 0.0)
	t.check(_never_settles(look), "a van mid-take is never gated")
	event.taking_a_victim = false
	event.tick(STEP, 0.0)
	t.check(_asks(look),
			"and the end of the take is a key change, so the victim is actually cleared")
	event.free()

# ------------------------------------------------------------------ consistency ---

## The key is a pure query on state the tick has already settled, so asking twice inside one
## tick always answers the same way — the same contract `gait_is_stepping()` owes the halo, which
## re-runs `draw_body()` a dozen times per frame of its own.
func _test_the_key_is_stable_within_a_tick(t: TestRunner) -> void:
	var event := _walker("dog_walker")
	var look := event.look_for(EventCatalogue.by_id("dog_walker"))
	for i in WALK.size():
		_walk_to(event, WALK[i])
		_asks(look)
		t.check(not _asks(look),
				"the key answers the same way twice inside tick %d" % i)
	event.free()

# ------------------------------------------------------------------ the mast ---

## A mast's picture is its broadcast cycle — the amber lamp of the telegraph that opens every
## period, then the green lamp and the arcs while it speaks — and nothing at all on top of the pole
## once silenced (`FigureLook._draw_mast()`). Both are clocks the ordinary key terms never see:
## the cycle runs on the city's broadcast clock (`mast_is_telegraphing_now()`) long after the
## once-at-creation `is_telegraphing()` has gone false, and silencing flips a flag without moving
## anything. A key without them keeps the arcs on a mast day 11's task has just silenced.
func _test_a_masts_lamp_and_its_silence_move_its_key(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("loudspeaker")
	var event := FakeEvent.new()
	event.pulse_length = def.pulses_every()
	event.telegraph_length = def.telegraphs_for()
	var look := event.look_for(def)
	event.lived = def.pulses_every() + def.telegraphs_for() + 1.0
	_asks(look)
	event.lived = 2.0 * def.pulses_every() + 0.5
	t.check(look.mast_is_telegraphing_now() and _asks(look),
			"the next cycle's telegraph moves the mast's key")
	event.lived = 2.0 * def.pulses_every() + def.telegraphs_for() + 1.0
	_asks(look)
	event.silenced = true
	t.check(_asks(look), "silencing the mast moves its key")
	event.free()

## A fake event of `id`'s row at rest on open ground, past its telegraph, that walks the row's
## own route at the row's own pace: what the real one answers once it has set off. A check walks
## it with `_walk_to()`.
func _walker(id: String) -> FakeEvent:
	var def := EventCatalogue.by_id(id)
	var event := FakeEvent.new()
	event.travels = true
	event.approaching_at = def.approach_speed()
	event.route = PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	return event

## `event` walked on to `point` (ground covered, the stride's phase there), striding as a real
## one is once it has set off.
static func _walk_to(event: FakeEvent, point: Vector2) -> void:
	event.tick(STEP, point.x - event.travelled)
	event.stride = point.y
	event.striding = point.x > 0.0

## Whether the redraw gate asks for a draw now: what `_process()` gets from it, and the one thing the
## picture key decides.
static func _asks(look: EventLook) -> bool:
	return look.redraw_if_the_picture_changed()

## Whether the gate steps aside for `look`: it asks again with nothing between the two asks.
static func _never_settles(look: EventLook) -> bool:
	_asks(look)
	return _asks(look)
