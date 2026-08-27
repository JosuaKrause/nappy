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
	_test_only_what_she_cannot_outwalk_earns_an_arrow(t)

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
## them changes over time: they are there, they stay there, and they are visibly what they are.
## A street where the notice board is marked as hard as the abduction is a street with no
## information on it, which is what the rings were.
func _test_scenery_gets_no_mark(t) -> void:
	for id in ["poster_crew", "barricade", "burnt_shell", "construction", "checkpoint"]:
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

	# Loud, so it is marked; and marked in the telegraph colour first, which is the difference
	# between "this is about to happen" and "this is happening".
	var loud := EventCatalogue.by_id("homeless_yeller")
	if loud:
		var instance := _instance(loud)
		t.check(instance.wants_a_mark() and instance.mark_colour() == Palette.MARK_TELEGRAPH,
				"a loud event telegraphs in amber")
		_advance(instance, loud.telegraph_time + 0.5)
		t.check(instance.wants_a_mark() and instance.mark_colour() == Palette.MARK_ACTIVE,
				"and turns red when it arrives")
		instance.free()

	# The line between the two groups, stated rather than assumed. Anything the mark shows once
	# its telegraph is over has to be a thing that *changes* — that is what a mark is for, and
	# a steady one is a ring with fewer pixels.
	for def in EventCatalogue.all():
		if def.city_wide or def.kind == GameEnums.EventKind.AMBIENT:
			continue
		var instance := _instance(def)
		_advance(instance, def.telegraph_time + 0.05)
		if not instance.wants_a_mark():
			instance.free()
			continue
		var changes := def.hard_fail or def.pulse_period > 0.0 \
				or not is_equal_approx(def.intensity_ramp, 1.0)
		t.check(changes,
				"'%s' is only marked after its telegraph because it changes over time" % def.id)
		instance.free()

	# And the whole catalogue is not marked. If it ever is, the vocabulary has stopped saying
	# anything and has become the rings again with a different shape.
	var marked := 0
	var counted := 0
	for def in EventCatalogue.all():
		if def.city_wide or def.kind == GameEnums.EventKind.AMBIENT:
			continue
		counted += 1
		var instance := _instance(def)
		_advance(instance, def.telegraph_time + 0.05)
		marked += 1 if instance.wants_a_mark() else 0
		instance.free()
	t.check(marked < counted,
			"only some of the catalogue carries a mark once it has arrived (%d of %d)"
			% [marked, counted])

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

# ------------------------------------------------------------------- helpers ---

func _instance(def: EventDef) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	return instance

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
