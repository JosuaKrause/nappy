extends RefCounted
## The gate that stops an event rebuilding a draw list it does not need —
## `EventInstance._redraw_if_the_picture_changed()`, `_picture_key()` and
## `_picture_never_settles()`. The crowd has had the same gate for a long time
## (`CrowdAgent._redraw_if_the_picture_changed()`); events did not, and at about forty live
## instances a day that was the largest drawing cost in a frame
## (`docs/evidence/m124-frame-cost-2026-09-13/README.md`).
##
## **What a suite can hold here is the key, not the drawing.** `_draw()` never runs headless, and
## nothing exposes whether a `queue_redraw()` is pending — so what is asserted is the value the gate
## compares, which is the whole of its decision: a key that does not move is a draw list that is not
## rebuilt, and a key that moves while the picture does is the guarantee that nothing animated was
## frozen by the gate. The rendered half is the bursts in
## `docs/evidence/m124-frame-fixes-2026-09-13/`.
##
## Nothing here calls a `_draw_*` function — `Sprites.draw_standing()` inside them is only valid
## from an actual draw pass, the same rule `tests/test_event_strides.gd` and
## `tests/test_event_views.gd` both follow.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_standing_seal_holds_one_key_for_its_whole_life(t)
	_test_the_gate_stores_the_key_it_compared(t)
	_test_a_striding_event_moves_its_key(t)
	_test_a_bobbing_event_moves_its_key(t)
	_test_a_telegraphing_cat_moves_its_key_when_the_crouch_ends(t)
	_test_the_marks_flash_is_in_the_key(t)
	_test_the_caret_strength_is_in_the_key(t)
	_test_the_buskers_strum_moves_the_key_without_him_moving(t)
	_test_the_cafe_sitters_lean_moves_the_key(t)
	_test_a_waiting_robber_turning_to_face_her_moves_the_key(t)
	_test_a_chatting_mother_moves_her_key_while_frozen(t)
	_test_a_raised_boom_moves_the_gates_key(t)
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
func _test_a_standing_seal_holds_one_key_for_its_whole_life(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("barricade"), Vector2.ZERO)
	instance._process(STEP)
	var key := instance._picture_key()
	var changes := 0
	for i in 300:
		instance._process(STEP)
		var now := instance._picture_key()
		if now != key:
			changes += 1
		key = now
	t.check(changes <= 1,
			"a barricade's picture key changes at most once in three hundred ticks (%d)" % changes)
	t.check(not instance._picture_never_settles(),
			"and a barricade is not one of the looks that are never gated at all")
	instance.free()

## Runs `instance` forward until its telegraph is over, so a test about something else is not also
## reading the one-off key change that crossing carries. Bounded, and says so if the crossing never
## happened, because a loop that silently ran out would leave the test asserting nothing.
func _past_the_telegraph(t, instance: EventInstance, what: String) -> void:
	for i in 2000:
		if not instance.is_telegraphing():
			return
		instance._process(STEP)
	t.check(false, "%s finished telegraphing inside the window the test walked" % what)

## The gate stores whatever it compared, every tick, whether or not it asked for a draw — which is
## what lets the *transition out of* a never-settling state still register as a change.
func _test_the_gate_stores_the_key_it_compared(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("barricade"), Vector2.ZERO)
	t.check(instance._picture.x == -1,
			"before its first tick an instance holds a key nothing can equal, so the first draw is asked for")
	instance._process(STEP)
	t.check(instance._picture == instance._picture_key(),
			"after a tick the stored key is the one the gate just computed")
	instance.free()

# ------------------------------------------------------------- what still moves ---

## `dog_walker` at 32px/s crosses into its mid-stride frame and back within a few seconds of walking
## (`tests/test_event_strides.gd` pins the alternation itself). Every one of those flips has to
## reach the screen, so every one of them has to move the key.
func _test_a_striding_event_moves_its_key(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	var stepping_changed_the_key := true
	var was_stepping := instance._gait_stepping()
	var key := instance._picture_key()
	var flips := 0
	for i in 600:
		instance._process(STEP)
		var now_stepping := instance._gait_stepping()
		var now_key := instance._picture_key()
		if now_stepping != was_stepping:
			flips += 1
			if now_key == key:
				stepping_changed_the_key = false
		was_stepping = now_stepping
		key = now_key
	t.check(flips > 0, "the walk actually swapped stride frames (%d times)" % flips)
	t.check(stepping_changed_the_key, "every stride-frame swap moved the picture key")
	instance.free()

## The bob is a translation of the whole body, so a walking event redraws for it as well as for its
## stride — that is correct rather than a miss, and it is the reason the win is the scenery rather
## than the traffic. Asserted over a tick where the stride frame did *not* change, so the only
## thing left that could have moved the key is the lift.
func _test_a_bobbing_event_moves_its_key(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	instance._process(STEP)
	var moved_on_bob_alone := false
	var was_stepping := instance._gait_stepping()
	var key := instance._picture_key()
	for i in 300:
		instance._process(STEP)
		var now_stepping := instance._gait_stepping()
		var now_key := instance._picture_key()
		if now_stepping == was_stepping and now_key.z != key.z and now_key != key:
			moved_on_bob_alone = true
		was_stepping = now_stepping
		key = now_key
	t.check(moved_on_bob_alone,
			"a walking event's lift moves the key on a tick where its stride frame did not")
	t.check(absf(instance._current_bob()) > 0.0, "and the walker was actually bobbing")
	instance.free()

## The crouch *is* the telegraph (`_draw_cat` swaps the whole family at `is_telegraphing()`), so the
## tick the dash starts has to move the key even though nothing about the cat has moved yet.
func _test_a_telegraphing_cat_moves_its_key_when_the_crouch_ends(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, route, Vector2.RIGHT)
	instance._process(STEP)
	t.check(instance.is_telegraphing(), "a cat starts crouched in its telegraph")
	var crouched := instance._picture_key()
	var crossed := false
	var ticks := int(ceil(def.telegraph_time / STEP)) + 10
	for i in ticks:
		instance._process(STEP)
		if not instance.is_telegraphing():
			crossed = true
			break
	t.check(crossed, "the telegraph ended inside the window the test walked")
	t.check(instance._picture_key() != crouched,
			"the crouch giving way to the dash moves the picture key")
	instance.free()

# --------------------------------------------------------------------- the mark ---

## The caret flashes while the thing it stands over is still telegraphing — `_draw_mark()` draws
## nothing for the part of every beat past 0.55 — so the flash is part of the picture rather than
## of the mark's size, and the key has to carry it or a caret would freeze on whichever half of the
## beat it was last drawn in.
##
## The strength is written straight into the per-frame cache `_caret_strength()` keeps against
## `age`, the same way `tests/test_event_strides.gd` writes `_gait_phase` to reach a state a rig
## cannot otherwise stand in: what is under test is the key, not the projection that feeds it.
func _test_the_marks_flash_is_in_the_key(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	var seen := {}
	# One whole flash beat, sampled tick by tick.
	for i in int(ceil(1.0 / EventInstance.MARK_FLASHES_PER_SECOND / STEP)) + 2:
		instance._process(STEP)
		if not instance.is_telegraphing():
			break
		instance._caret_strength_age = instance.age
		instance._caret_strength_cache = 1
		seen[instance._picture_key()] = true
	t.check(seen.size() >= 2,
			"a marked, telegraphing event takes more than one key across one flash beat (%d)"
					% seen.size())
	instance.free()

## The caret's own 0/1/2 strength is a picture — no mark, one mark, a doubled mark — so the same
## instance in the same state reads three different keys for the three strengths.
func _test_the_caret_strength_is_in_the_key(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("barricade"), Vector2.ZERO)
	instance._process(STEP)
	var keys := {}
	for strength in [0, 1, 2]:
		instance._caret_strength_age = instance.age
		instance._caret_strength_cache = strength
		keys[instance._picture_key()] = true
	t.check(keys.size() == 3, "no caret, a caret and a doubled caret are three different keys")
	instance.free()

# ---------------------------------------------------------- the idle animations ---

## The busker never moves an inch and never covers any ground, so his strum is driven by
## `_idle_stepping(BUSKER_STRUM_PERIOD)` rather than by the gait — the one animation in the game a
## distance-driven key would have silenced outright.
func _test_the_buskers_strum_moves_the_key_without_him_moving(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("busker"), Vector2.ZERO)
	_past_the_telegraph(t, instance, "the busker")
	var start := instance.position
	var keys := {}
	var swaps := 0
	var was := instance._idle_stepping(EventInstance.BUSKER_STRUM_PERIOD)
	for i in int(ceil(EventInstance.BUSKER_STRUM_PERIOD * 3.0 / STEP)):
		instance._process(STEP)
		var now := instance._idle_stepping(EventInstance.BUSKER_STRUM_PERIOD)
		if now != was:
			swaps += 1
		was = now
		keys[instance._picture_key()] = true
	t.check(instance.position == start, "the busker did not move at all")
	t.check(swaps >= 2, "his strum swapped frames over three periods (%d)" % swaps)
	t.check(keys.size() == 2, "and the key takes exactly the two values his two frames are")
	instance.free()

## The same for the café frontage's lean, on its own slower timer — the whole row leans together,
## so one instance's key carries it for every sitter.
func _test_the_cafe_sitters_lean_moves_the_key(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("cafe_tables"), Vector2.ZERO)
	_past_the_telegraph(t, instance, "the café frontage")
	var keys := {}
	for i in int(ceil(EventInstance.SITTER_IDLE_PERIOD * 2.5 / STEP)):
		instance._process(STEP)
		keys[instance._picture_key()] = true
	t.check(keys.size() == 2, "a café frontage's key takes exactly its two lean frames")
	instance.free()

# ------------------------------------------------------- what turns without moving ---

## `_draw_robber()` picks a waiting man's view from `_robber_waiting_heading()` — where she is —
## rather than from the alley he was sited facing, so he turns to watch her while standing perfectly
## still. Nothing else in the game changes its picture with neither a step nor a clock behind it,
## and a key reading `_heading` alone would have frozen him facing his siting for ever.
func _test_a_waiting_robber_turning_to_face_her_moves_the_key(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("alley_robbery"), Vector2.ZERO, PackedVector2Array(),
			Vector2.RIGHT)
	# Far enough out that he never stops waiting, in two places 180° apart.
	instance.player_at = Vector2(9000.0, 0.0)
	instance._process(STEP)
	t.check(instance.is_waiting(), "he is only waiting, from the east")
	var facing_east := instance._picture_key()
	instance.player_at = Vector2(-9000.0, 0.0)
	instance._process(STEP)
	t.check(instance.is_waiting(), "he is still only waiting, from the west")
	t.check(instance._picture_key() != facing_east,
			"a waiting robber turning to face her moves the key with no step taken")
	instance.free()

## Her conversation freezes `_process()` — no distance, no gait — and the posture swap is the only
## telegraph that mechanic has, so it must move the key from inside the frozen branch.
func _test_a_chatting_mother_moves_her_key_while_frozen(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("chatting_mother"), Vector2.ZERO, route, Vector2.RIGHT)
	for i in 30:
		instance._process(STEP)
	var strolling := instance._picture_key()
	instance.start_chat()
	instance._process(STEP)
	t.check(instance.is_chatting(), "the conversation is running")
	t.check(instance._picture_key() != strolling,
			"the talking posture moves the key although she has stopped dead")
	instance.free()

## A boom gate's whole picture is one bit somebody else owns — `RegionPlanner.GateState.raised`,
## advanced by `Crowd` — and the gate never moves, never strides and never telegraphs, so that bit
## is the only thing between a raised boom and a lowered one reaching the screen.
func _test_a_raised_boom_moves_the_gates_key(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("checkpoint_gate"), Vector2.ZERO, PackedVector2Array(),
			Vector2.DOWN)
	instance._process(STEP)
	var lowered := instance._picture_key()
	var state := RegionPlanner.GateState.new()
	state.raised = true
	instance.gate_state = state
	instance._process(STEP)
	t.check(instance._picture_key() != lowered, "raising the boom moves the gate's key")
	instance.free()

## An event that is over leaves rather than vanishing, and it bobs on the way out
## (`_current_bob()`'s own `is_leaving` branch) — so the departure is drawn rather than held on the
## last frame the event was still an event.
func _test_a_leaving_event_moves_its_key(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("loose_dog"), Vector2.ZERO, PackedVector2Array(),
			Vector2.RIGHT)
	instance.player_at = Vector2(-400.0, 0.0)
	instance._process(STEP)
	var live := instance._picture_key()
	instance._be_done()
	instance._process(STEP)
	t.check(instance.is_leaving, "it is on its way out")
	t.check(instance._picture_key() != live, "the departure moves the key")
	instance.free()

# --------------------------------------------------- what is never gated at all ---

## Four pictures are continuous functions of the clock rather than a frame chosen from a set, and
## the gate steps aside for all four rather than pretending a key could name them.
func _test_the_flock_and_the_drawn_flames_are_never_gated(t) -> void:
	var flock := EventInstance.new()
	flock.setup(EventCatalogue.by_id("pigeon_flock"), Vector2.ZERO)
	# `_ready()` is what builds the birds in a real scene; a bare rig has to ask for them.
	flock._build_the_flock()
	t.check(not flock._flock.is_empty(), "the flock has birds")
	t.check(flock._picture_never_settles(), "a flock is never gated — every bird moves every tick")
	flock.free()

	var fire := EventInstance.new()
	fire.setup(EventCatalogue.by_id("burning_building"), Vector2.ZERO)
	t.check(fire._picture_never_settles(), "a burning building's flames are never gated")
	fire.free()

	var firefight := EventInstance.new()
	firefight.setup(EventCatalogue.by_id("firefight"), Vector2.ZERO)
	t.check(firefight._picture_never_settles(), "a firefight's muzzle flashes are never gated")
	firefight.free()

	var stall := EventInstance.new()
	stall.setup(EventCatalogue.by_id("market_stall"), Vector2.ZERO)
	t.check(not stall._picture_never_settles(), "and a market stall is gated like any other scenery")
	stall.free()

## The van's victim slides to the van over `VICTIM_TAKEN_OVER` seconds, so it is never gated while
## the take runs — and the *end* of the take is a change the key itself has to carry, or the last
## frame of the walk would stay on the screen with nobody in it.
func _test_a_van_mid_take_is_never_gated_and_says_so_afterwards(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("abduction"), Vector2.ZERO, PackedVector2Array(),
			Vector2.RIGHT)
	t.check(not instance._picture_never_settles(), "an idle van is gated like any other vehicle")
	instance._victim_taken_at = instance.age
	instance._process(STEP)
	t.check(instance.is_taking_a_victim(), "the take is running")
	t.check(instance._picture_never_settles(), "a van mid-take is never gated")
	var during := instance._picture_key()
	instance._victim_taken_at = INF
	instance._process(STEP)
	t.check(not instance.is_taking_a_victim(), "the take is over")
	t.check(instance._picture_key() != during,
			"and the end of the take is a key change, so the victim is actually cleared")
	instance.free()

# ------------------------------------------------------------------ consistency ---

## The key is a pure query on state `_process()` has already settled, so asking twice inside one
## tick always answers the same way — the same contract `_gait_stepping()` owes the halo, which
## re-runs `_draw_body()` a dozen times per frame of its own.
func _test_the_key_is_stable_within_a_tick(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	for i in 90:
		instance._process(STEP)
		t.check(instance._picture_key() == instance._picture_key(),
				"the key answers the same way twice inside tick %d" % i)
	instance.free()
