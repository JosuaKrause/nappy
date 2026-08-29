extends RefCounted
## The danger vocabulary: what M22 put in place of the aura rings.
##
## Almost none of this can be judged by a test — whether a caret reads from across a street is
## a question for a screenshot and a person. What *is* testable is the set of rules underneath
## it, and those are the part that would rot silently: which things get a mark and which do
## not, that the mark still breathes, which two levels the cue over the player has and that one
## system cannot clear another's warning, and which things earn an arrow at the screen edge.
##
## The standing decision this suite exists to keep, from `CLAUDE.md`:
##
##     How dangerous a thing is has to be visible from looking at *the thing*.

func run(t) -> void:
	_test_the_rings_are_gone(t)
	_test_scenery_gets_no_mark(t)
	_test_the_dangerous_things_do(t)
	_test_the_mark_still_breathes(t)
	_test_a_warning_cannot_be_cleared_by_somebody_who_cannot_see_it(t)
	_test_only_a_lethal_thing_puts_the_mark_over_her_head(t)
	_test_a_car_sounding_its_horn_carries_its_own_mark(t)
	_test_only_what_she_cannot_outwalk_earns_an_arrow(t)
	_test_the_badge_measures_the_things_own_speed(t)
	_test_a_source_can_take_down_its_own_warning_and_nobody_elses(t)
	_test_the_pram_says_how_the_baby_is(t)
	_test_the_babys_cue_only_steps_aside_for_something(t)

const STEP := 1.0 / 60.0

# ---------------------------------------------------------------- no circles ---

## Playtest 02 finding 8, restated by playtest 04 finding 2, and a standing decision in between:
## the rings are **deleted, not restyled**. A test rather than a note, because the failure mode
## is somebody reaching for a ring again when something new needs signalling — which is exactly
## what the decision exists to stop, and exactly what a comment in a deleted file cannot.
func _test_the_rings_are_gone(t) -> void:
	t.check(not ResourceLoader.exists("res://src/events/event_aura_layer.gd"),
			"the aura layer is deleted rather than disabled")
	t.check(not ClassDB.class_exists("EventAuraLayer"),
			"and nothing can construct one")
	# Asked of the script rather than of an instance: a `City` is a scene's worth of nodes and
	# building one to ask it a question about its own interface leaks the lot.
	var methods: Array[String] = []
	for entry in (load("res://src/city/city.gd") as GDScript).get_script_method_list():
		methods.append(String(entry["name"]))
	t.check(not ("add_aura_layer" in methods),
			"and the City has no layer left to hang a field on")

# ------------------------------------------------------------------- the mark ---

## The three the cost table already calls scenery, plus the large obvious obstacles. None of
## them is worth changing your route for: they are there, they stay there, and they are visibly
## what they are. A street where the notice board is marked as hard as the abduction is a street
## with no information on it, which is what the rings were.
##
## *(M39 dropped `checkpoint` from this list.* It costs +29 to walk through, which is above
## `MARK_WORTH_A_DETOUR`, and the whole of finding 9 is that the marked set has to be the top of the
## cost order rather than a list somebody curated. A street being *held* is a real detour.)*
func _test_scenery_gets_no_mark(t) -> void:
	for id in ["poster_crew", "barricade", "burnt_shell", "construction", "busker", "delivery_van"]:
		var def := EventCatalogue.by_id(id)
		t.check(def != null, "'%s' is in the catalogue" % id)
		if not def:
			continue
		var instance := _instance(def)
		_advance(instance, def.telegraph_time + 0.5)
		t.check(not instance.wants_a_mark(),
				"'%s' is scenery once it has arrived, and carries no mark" % id)
		instance.free()

func _test_the_dangerous_things_do(t) -> void:
	# Lethal, always, from the first frame — including while it is telegraphing, which is the
	# whole window the fairness contract gives her.
	var lethal := EventCatalogue.by_id("abduction")
	t.check(lethal != null and lethal.hard_fail, "the abduction is a hard fail")
	if lethal:
		var instance := _instance(lethal)
		t.check(instance.wants_a_mark(), "a lethal event is marked while it telegraphs")
		t.check(instance.mark_colour() == Palette.MARK_LETHAL,
				"and in the colour reserved for the things that end the day")
		_advance(instance, lethal.telegraph_time + 0.5)
		t.check(instance.wants_a_mark(), "and still marked once it is live")
		instance.free()

	# A loud row keeps its mark after the telegraph, and the **colour does not change** with the
	# phase. *(M39, playtest 10 finding 8.)* The flash is what says "not yet"; amber says "worth
	# going round" and deep red says "ends your day", and there is no third thing.
	var loud := EventCatalogue.by_id("leaf_blower")
	if loud:
		var instance := _instance(loud)
		t.check(instance.wants_a_mark() and instance.mark_colour() == Palette.MARK_COSTLY,
				"a loud event is marked in amber while it telegraphs")
		_advance(instance, loud.telegraph_time + 0.5)
		t.check(instance.wants_a_mark() and instance.mark_colour() == Palette.MARK_COSTLY,
				"and in the same amber once it arrives — the colour is the danger, not the phase")
		instance.free()

	# The rows that are cheap to walk through carry nothing, and the rows the player named carry
	# something. *(M39, findings 1 and 9: "there is no danger indicator over the homeless person",
	# and "some dangerous ones don't have indicators and some really benign ones do".)*
	for id in ["cafe_tables", "busker", "cat_dash", "construction", "police_patrol"]:
		var def := EventCatalogue.by_id(id)
		if not def:
			continue
		var instance := _instance(def)
		_advance(instance, def.telegraph_time + 0.5)
		t.check(not instance.wants_a_mark(),
				"'%s' costs %.1f to walk through, which is not a detour"
				% [id, def.walk_through_cost()])
		instance.free()
	for id in ["homeless_yeller", "dog_walker", "leaf_blower", "loose_dog", "fire_truck"]:
		var def := EventCatalogue.by_id(id)
		if not def:
			continue
		var instance := _instance(def)
		_advance(instance, def.telegraph_time + 0.5)
		t.check(instance.wants_a_mark(),
				"'%s' costs %.1f to walk through, so it is worth a mark"
				% [id, def.walk_through_cost()])
		instance.free()

	# **And the invariant underneath all of it, which is the whole of finding 9**: the marked set is
	# the *top of the cost order*. If A carries a mark and B does not, A costs more to walk through
	# than B — over the whole catalogue, so a new row cannot earn one by pulsing quickly and a
	# rebalance cannot silently take one away from the row above it.
	#
	# Lethal rows are exempt from the ordering and not from the rule: they are marked whatever they
	# cost, because *ends your day* is a different kind of thing rather than a larger amount of the
	# same thing. `charging_dog` is the case that proves it — 17 points, the cheapest lethal row in
	# the game, and the only one running is the answer to.
	var cheapest_marked := INF
	var dearest_unmarked := -INF
	var marked := 0
	var counted := 0
	for def in EventCatalogue.all():
		if def.city_wide or def.kind == GameEnums.EventKind.AMBIENT:
			continue
		counted += 1
		var instance := _instance(def)
		_advance(instance, def.telegraph_time + 0.05)
		if instance.wants_a_mark():
			marked += 1
			if not def.hard_fail:
				cheapest_marked = minf(cheapest_marked, def.walk_through_cost())
		else:
			dearest_unmarked = maxf(dearest_unmarked, def.walk_through_cost())
		instance.free()
	t.check(cheapest_marked > dearest_unmarked,
			"nothing unmarked costs more than something marked (%.1f unmarked vs %.1f marked)"
			% [dearest_unmarked, cheapest_marked])

	# And the whole catalogue is not marked. If it ever is, the vocabulary has stopped saying
	# anything and has become the rings again with a different shape.
	t.check(marked < counted,
			"only some of the catalogue carries a mark once it has arrived (%d of %d)"
			% [marked, counted])

	# Day 1 specifically, because that is the street the complaint was made about and the one a
	# player sees most. It comes out at six of nine, which is more than M33's two — and the count is
	# a *consequence* rather than a target: the threshold is pinned by `homeless_yeller` at +31,
	# which is the row the finding named, and the ordering rule then takes everything above it.
	# What has to stay true is that the cheap end of an ordinary street carries nothing, or the
	# caret is back to being a ring.
	var day_one_marked := 0
	var day_one := 0
	var cheapest: EventDef = null
	for def in EventCatalogue.available_on(1):
		if def.city_wide or def.kind == GameEnums.EventKind.AMBIENT:
			continue
		day_one += 1
		if not cheapest or def.walk_through_cost() < cheapest.walk_through_cost():
			cheapest = def
		var instance := _instance(def)
		_advance(instance, def.telegraph_time + 0.05)
		day_one_marked += 1 if instance.wants_a_mark() else 0
		instance.free()
	t.check(day_one_marked > 0 and day_one_marked < day_one,
			"day 1 marks some of its street and not all of it (%d of %d)"
			% [day_one_marked, day_one])
	if cheapest:
		var instance := _instance(cheapest)
		_advance(instance, cheapest.telegraph_time + 0.05)
		t.check(not instance.wants_a_mark(),
				"and the cheapest thing on it ('%s', %.1f) carries nothing"
				% [cheapest.id, cheapest.walk_through_cost()])
		instance.free()

## The one property the ring had that a symbol does not get for free. Without it a pulsing event
## stops being something to time a pass through and becomes something that hurts at random.
func _test_the_mark_still_breathes(t) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	t.check(def != null and def.pulse_period > 0.0, "the yeller pulses")
	if not def:
		return
	var instance := _instance(def)
	_advance(instance, def.telegraph_time + 0.1)

	var lowest := INF
	var highest := 0.0
	for i in int(round(def.pulse_period / STEP)):
		instance._process(STEP)
		lowest = minf(lowest, instance.mark_swell())
		highest = maxf(highest, instance.mark_swell())
	t.check(highest > lowest * 1.5,
			"the mark has a real swing between beats (%.2f to %.2f)" % [lowest, highest])
	t.check(lowest > 0.0, "and never shrinks to nothing, which would read as flickering")
	t.check(highest <= 1.0, "and never overstates what the event is emitting")
	instance.free()

# ------------------------------------------------------- the cue over the player ---

## The load-bearing cue, and the bug the two-level version could easily have had. The crowd and
## the events both watch the ground she is standing on, in the same frame. A setter lets
## whichever runs second clear what the first just said — so a lethal event on top of her would
## be silently downgraded to nothing by the traffic deciding there was no car coming.
func _test_a_warning_cannot_be_cleared_by_somebody_who_cannot_see_it(t) -> void:
	var rig := _rig(t)
	t.check(rig.alert_level() == Stroller.Alert.NONE, "nothing over her head to begin with")

	rig.warn(Stroller.Alert.NOW, 0.5)
	rig.warn(Stroller.Alert.SOON, 0.5)
	t.check(rig.alert_level() == Stroller.Alert.NOW,
			"the louder warning survives a quieter one raised in the same frame")

	# And it goes away on its own rather than needing to be told to.
	rig._physics_process(0.6)
	t.check(rig.alert_level() == Stroller.Alert.NONE, "a warning expires by itself")

	rig.warn(Stroller.Alert.SOON, 0.5)
	t.check(rig.alert_level() == Stroller.Alert.SOON,
			"and a quieter one can be raised once the loud one has gone")
	rig.free()

## **The mark over her head means: this will end your day.** *(M30, playtest 05 finding 3.)*
##
## It used to be raised for any telegraphing event whose radius reached her, and the player's
## verdict was *"it doesn't actually have an effect on gameplay — I can just keep doing what I
## was doing."* That was accurate for fifteen of the eighteen rows: for anything that is not a
## `hard_fail`, the mark meant *a number is about to move faster*, which the meter already says
## continuously and proportionally. This is the same rule the caret over an entity got right
## first time — a cue that marks everything says nothing — applied to the one cue that gives an
## instruction rather than information.
##
## Run through `EventManager` rather than through `Stroller.warn()`, because the thing that was
## wrong was *which events call it*, and no test in this suite could see that.
func _test_only_a_lethal_thing_puts_the_mark_over_her_head(t) -> void:
	var manager := EventManager.new()
	t.add_child(manager)
	var rig := _rig(t)
	rig.add_to_group("player")
	rig.global_position = Vector2(1000.0, 1000.0)

	# An ordinary telegraphing event, right on top of her. It costs her the meter and says so
	# through the meter; it is not an instruction.
	var ordinary := _instance(EventCatalogue.by_id("dog_walker"))
	ordinary.global_position = rig.global_position
	manager.add_child(ordinary)
	manager._instances.append(ordinary)
	_warn_through(manager)
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"a dog walker whose radius covers her raises nothing over her head")

	# A lethal one, still telegraphing: the contract is now about her and the clock has started.
	var lethal := _instance(EventCatalogue.by_id("abduction"))
	lethal.global_position = rig.global_position
	manager.add_child(lethal)
	manager._instances.append(lethal)
	_warn_through(manager)
	t.check(rig.alert_level() == Stroller.Alert.SOON,
			"an unmarked van telegraphing over her is the flashing mark")

	# And once it is live, the second level: one step left.
	_advance(lethal, lethal.def.telegraph_time + 0.2)
	_warn_through(manager)
	t.check(rig.alert_level() == Stroller.Alert.NOW,
			"and the same van live around her is the doubled one")

	# Far enough away and it is somebody else's problem again.
	rig.global_position = lethal.global_position + Vector2(lethal.def.outer_radius + 50.0, 0.0)
	rig._physics_process(1.0)
	_warn_through(manager)
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"outside its outer radius there is nothing over her head")

	# **And `NOW` is about the pair of them.** *(M39, playtest 10 finding 11: "when I'm walking
	# orthogonally away from the biker the double !! shouldn't show anymore since there is no way it
	# can affect me.")* Well inside the outer radius, well outside the lethal one, and not closing:
	# the strongest cue in the game has nothing to say about that.
	rig.global_position = lethal.global_position + Vector2(lethal.def.outer_radius - 20.0, 0.0)
	rig.velocity = Vector2.ZERO
	_warn_through(manager)
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"standing still inside a live lethal field but nowhere near it is not an instruction")

	# Walking into it is, once she is a step from the end of the day.
	rig.global_position = lethal.global_position + Vector2(lethal.def.inner_radius + 20.0, 0.0)
	rig.velocity = Vector2(-Tuning.WALK_SPEED, 0.0)
	_warn_through(manager)
	t.check(rig.alert_level() == Stroller.Alert.NOW,
			"walking the last step into it is")

	# And turning round takes it away again, from the same place, on the same frame.
	rig.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	rig._alert = Stroller.Alert.NONE
	rig._alert_left = 0.0
	_warn_through(manager)
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"and walking away from the same spot takes it down — the danger has been avoided")

	rig.free()
	manager.free()

## The traffic half of the same finding, and the one the vocabulary's first row was not paying
## for: *the entity itself carries most of it* — except a car, which carried nothing at all,
## because the caret is drawn by `EventInstance` and a car is not an event. A lethal thing bore
## down on the player and produced a mark over **her** head and nothing anywhere else.
func _test_a_car_sounding_its_horn_carries_its_own_mark(t) -> void:
	var methods: Array[String] = []
	for entry in (load("res://src/crowd/crowd_agent.gd") as GDScript).get_script_method_list():
		methods.append(String(entry["name"]))
	t.check("_draw_horn_mark" in methods, "a car draws a mark of its own")
	# The caret is one shape in one place, not two similar ones: a short vocabulary stays short
	# only if nobody hand-draws a second chevron.
	var shared: Array[String] = []
	for entry in (load("res://src/sprites.gd") as GDScript).get_script_method_list():
		shared.append(String(entry["name"]))
	t.check("draw_caret" in shared,
			"and it is the same caret the events draw, from one place")

# ------------------------------------------------------------- the screen edge ---

## The gap the ring never covered and could not: `fire_truck` does 190px/s with a 340px radius,
## and a ring is only useful once it is on screen, which at that speed is most of the warning
## gone. The rule is the same line the telegraph contract draws — what she cannot outwalk.
func _test_only_what_she_cannot_outwalk_earns_an_arrow(t) -> void:
	var edge := DangerEdge.new()
	var wanted := ["fire_truck", "military_convoy", "abduction", "alley_robbery"]
	var not_wanted := ["dog_walker", "cafe_tables", "poster_crew", "busker", "construction"]

	for id in wanted:
		var def := EventCatalogue.by_id(id)
		if not def:
			continue
		var instance := _instance(def)
		t.check(edge._is_worth_an_arrow(instance),
				"'%s' is announced from off-screen: it is lethal or faster than a walk" % id)
		instance.free()

	for id in not_wanted:
		var def := EventCatalogue.by_id(id)
		if not def:
			continue
		var instance := _instance(def)
		t.check(not edge._is_worth_an_arrow(instance),
				"'%s' is not, because turning round and leaving is enough" % id)
		instance.free()

	t.check(DangerEdge.MOST_AT_ONCE <= 3,
			"and at most a handful at once, or the edge of the screen becomes wallpaper")
	edge.free()

## **The badge measures the event's speed, not the gap's.** *(Playtest 06, finding 1: "they show
## events far away, and if you walk towards them they sometimes disappear; also they flicker a
## lot.")* All three symptoms are one line: the rate the gap was shrinking is her speed plus its
## speed, and she walks at 92 against a threshold of 20, so walking towards anything lethal
## raised its badge whether or not it was coming.
##
## Testable because the two questions are static functions with no viewport in them, which is
## most of why they are static functions.
func _test_the_badge_measures_the_things_own_speed(t) -> void:
	var step := 1.0 / 60.0
	var walk := Tuning.WALK_SPEED * step

	# A parked van and a player walking straight at it. The gap is closing at 92px/s and the van
	# is not coming at anybody: nothing to announce.
	var van := Vector2(600.0, 0.0)
	var her := Vector2(walk, 0.0)
	t.check(is_zero_approx(DangerEdge.approach_speed(van, van, her, step)),
			"a stationary event has no approach speed, however fast she walks towards it")

	# The same van, now driving at her while she walks the other way. Her own retreat does not
	# subtract from what it is doing either.
	var was := Vector2(600.0, 0.0)
	var now := was - Vector2(Tuning.WALK_SPEED * 2.0 * step, 0.0)
	var approach := DangerEdge.approach_speed(was, now, Vector2.ZERO, step)
	t.check(absf(approach - Tuning.WALK_SPEED * 2.0) < 1.0,
			"and a mover is measured at its own speed (%.0f px/s)" % approach)

	# The range cap, which is a window rather than a distance: the same 900px of clear ground is
	# a fire engine worth announcing and a dawdler that is somebody else's problem for now.
	t.check(DangerEdge.announces(190.0, 800.0),
			"something doing 190px/s at 800px is four seconds away and is announced")
	t.check(not DangerEdge.announces(40.0, 800.0),
			"the same distance at 40px/s is twenty seconds away and is not")
	t.check(not DangerEdge.announces(DangerEdge.CLOSING_SPEED - 1.0, 0.0),
			"and nothing slower than a stroll is announced at any distance")
	t.check(DangerEdge.HOLD > 0.0,
			"a raised badge is held, so a rate hovering on the threshold cannot strobe")

	# And the same thing through the real measurement, because the defect was in the plumbing
	# rather than in the arithmetic: what the two static functions above are *given*.
	var manager := EventManager.new()
	t.add_child(manager)
	var standing := Node2D.new()
	t.add_child(standing)
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.setup(manager, standing)

	var def := EventCatalogue.by_id("fire_truck")
	var engine := _instance(def)
	engine.global_position = Vector2(700.0, 0.0)
	manager.add_child(engine)
	manager._instances.append(engine)

	# A second of her walking straight at a stopped fire engine.
	for i in 60:
		standing.global_position += Vector2(walk, 0.0)
		edge._process(step)
	t.check(edge._coming.is_empty(),
			"walking towards something lethal does not announce it at the edge of the screen")

	# And a second of it driving at her while she stands still.
	for i in 60:
		engine.global_position -= Vector2(def.speed * step, 0.0)
		edge._process(step)
	t.check(edge._coming.size() == 1, "a fire engine actually coming down the street does")

	edge.free()
	standing.free()
	manager.free()

## The other half of the same shape, and the reason `warn()` is additive. *(Playtest 06, finding
## 3: "I get the flashing exclamation marks **after** the fact, at which point they're not
## useful.")* The hold on the traffic's warning is 1.4s and has a real job — surviving the gap
## between two cars in one lane — so the fix is a second condition rather than a shorter hold,
## and the condition belongs to the system that can see it.
func _test_a_source_can_take_down_its_own_warning_and_nobody_elses(t) -> void:
	var rig := _rig(t)

	rig.warn(Stroller.Alert.SOON, 1.4, Crowd.WARNING_SOURCE)
	rig.stand_down(EventManager.WARNING_SOURCE)
	t.check(rig.alert_level() == Stroller.Alert.SOON,
			"an event cannot take down a warning the traffic raised")
	rig.stand_down(Crowd.WARNING_SOURCE)
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"and the traffic can, the instant she is over the kerb")

	# And a source that has been outbid finds nothing of its own to lower, which is what keeps
	# this from being the setter the additive rule exists to prevent.
	rig.warn(Stroller.Alert.SOON, 1.4, Crowd.WARNING_SOURCE)
	rig.warn(Stroller.Alert.NOW, 0.35, EventManager.WARNING_SOURCE)
	rig.stand_down(Crowd.WARNING_SOURCE)
	t.check(rig.alert_level() == Stroller.Alert.NOW,
			"the traffic cannot clear a lethal event's mark by driving away")

	# An upgrade takes the new caller's hold rather than inheriting the old one's remainder,
	# or a second of leftover `SOON` outlives the `NOW` that replaced it.
	rig._physics_process(0.4)
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"and the doubled mark expires on its own hold, not on the one underneath it")
	rig.free()

## The baby's own cue. *(Playtest 06, finding 5.)* Four states, each a different instruction, and
## the test is that they are *states* — a mark that is up whenever a meter is moving is the HUD
## drawn over the pram, which is the rings' mistake arriving from the other direction.
func _test_the_pram_says_how_the_baby_is(t) -> void:
	var baby := Baby.new()

	baby.state = GameEnums.BabyState.AWAKE
	baby.excitement = Tuning.EXCITEMENT_CALM_THRESHOLD - 1.0
	t.check(baby.cue() == Baby.Cue.NONE,
			"an ordinary street says nothing over the pram")
	baby.excitement = Tuning.EXCITEMENT_CALM_THRESHOLD
	t.check(baby.cue() == Baby.Cue.UNSETTLED,
			"the moment the day stops progressing, it says so")
	baby.excitement = Tuning.EXCITEMENT_NEARLY_CRYING
	t.check(baby.cue() == Baby.Cue.NEARLY_CRYING,
			"and escalates before the day is lost rather than as it is lost")

	baby.state = GameEnums.BabyState.ASLEEP
	baby.excitement = 0.0
	t.check(baby.cue() == Baby.Cue.ASLEEP, "asleep is a state with a mark of its own")
	baby.excitement = Tuning.EXCITEMENT_WAKE_THRESHOLD - Tuning.EXCITEMENT_STIR_MARGIN
	t.check(baby.cue() == Baby.Cue.STIRRING,
			"and stirring is warned about before it costs half the bar")

	# The relationships, which are what a rebalance must not quietly break.
	t.check(Tuning.EXCITEMENT_NEARLY_CRYING > Tuning.EXCITEMENT_CALM_THRESHOLD
			and Tuning.EXCITEMENT_NEARLY_CRYING < Tuning.METER_MAX,
			"the last warning band sits between the freeze and the lost day")
	t.check(Tuning.EXCITEMENT_STIR_MARGIN > 0.0
			and Tuning.EXCITEMENT_STIR_MARGIN < Tuning.EXCITEMENT_WAKE_THRESHOLD,
			"and stirring starts before waking, not with it")
	baby.free()

## And **where** it goes, which is the half M32 got wrong. *(M37, playtest 07 finding 14: "the zzz
## is stepped aside from the pram".)*
##
## The step exists to keep the baby's cue out of the exclamation mark's column, and that column is
## only occupied when there is a mark in it — so an unconditional step is a cue dodging something
## that is not there, on the commonest picture in the game. It is the same shape as playtest 06's
## own two findings, which were both about *when* rather than *which*, and it reached a player for
## the same reason: nothing in this suite could see a `_draw`, so the decision is a function now.
func _test_the_babys_cue_only_steps_aside_for_something(t) -> void:
	var scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var rig: Stroller = scene.instantiate()

	rig.facing = Vector2.UP
	t.check(is_zero_approx(rig.baby_cue_aside()),
			"walking north with nothing happening, the cue stays over the pram")
	rig.warn(Stroller.Alert.SOON, 1.0, &"test")
	t.check(not is_zero_approx(rig.baby_cue_aside()),
			"and steps out of the exclamation mark's column the moment there is one")
	rig.stand_down(&"test")

	# *(M39, playtest 10 finding 3: "when walking downwards the zzz is still left of the stroller
	# while walking in any other direction it has the correct position.")* M37 made the north case
	# conditional and left this one unconditional, on the true observation that walking south "above
	# the pram" is over her own chest — which is an argument for **lifting** the cue over her head,
	# not for pushing it off the pram sideways.
	rig.facing = Vector2.DOWN
	t.check(is_zero_approx(rig.baby_cue_aside()),
			"walking south with nothing happening, the cue also stays over the pram")
	t.check(rig.baby_cue_lift() > Stroller.BABY_CUE_LIFT,
			"and is lifted clear of her instead, because the pram is in front of her and lower")
	rig.warn(Stroller.Alert.SOON, 1.0, &"test")
	t.check(not is_zero_approx(rig.baby_cue_aside()),
			"and it steps out of the mark's column there too, once there is a mark")
	rig.stand_down(&"test")

	rig.facing = Vector2.RIGHT
	t.check(is_zero_approx(rig.baby_cue_aside()),
			"and sideways there is nothing to step around at all")
	t.check(is_equal_approx(rig.baby_cue_lift(), Stroller.BABY_CUE_LIFT),
			"nor anything to be lifted over: the pram is out to one side of her")
	rig.free()

# ------------------------------------------------------------------- helpers ---

func _instance(def: EventDef) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	return instance

## Runs the one thing under test, rather than a whole `_physics_process`. A bare `EventManager`
## has no `EventDirector` — that is built when a day starts — and stepping the whole frame
## raises a script error inside `_place_what_is_owed_ahead` before ever reaching the mark.
##
## Worth the note: the error did not fail the suite. GDScript aborts the erroring *function* and
## carries on in the caller, so the assertions afterwards ran, passed, and the only sign was
## four stack traces in the middle of a green run.
func _warn_through(manager: EventManager) -> void:
	manager._find_player()
	manager._warn_about_the_ground_she_is_on()

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

## A Stroller with the camera it looks up by path, in the tree so its `@onready` actually runs
## and `_physics_process` can be stepped by hand. `SomeNode.new()` is not named `SomeNode`, so
## the camera has to be named explicitly or the lookup fails silently.
func _rig(t) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig
