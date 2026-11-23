extends RefCounted
## The danger vocabulary: what M22 put in place of the aura rings.
##
## Almost none of this can be judged by a test — whether a caret reads from across a street is
## a question for a screenshot and a person. What *is* testable is the set of rules underneath
## it, and those are the part that would rot silently: which things get a mark and which do
## not, that the mark still breathes, which two levels the cue over the player has and that one
## system cannot clear another's warning, and what the screen edge hands its badges on real frames.
## Which rows earn an arrow is the row's own question (`EventDef.announces_its_coming()`), checked
## in `tests/test_events_catalogue.gd`; that the edge asks it is checked here. The mark a live event
## carries on itself (its caret and the projection behind it) is `tests/test_event_carets.gd`'s.
##
## **Nothing here stands a real `EventManager`.** The screen edge is handed the manager and reads
## its live events, so the three badge cases that put a fire engine or a cat on the street hand it
## a `FakeEventManager` holding what they spawn. The real manager's street, read by a real
## `DangerEdge`, is `tests/test_event_manager.gd`'s. Which live events raise which level of the cue
## over her head is the warning board's rule, held in `tests/test_event_parts.gd`.
##
## The standing decision this suite exists to keep, from `CLAUDE.md`:
##
##     How dangerous a thing is has to be visible from looking at *the thing*.

func run(t: TestRunner) -> void:
	_atlas.acquire(&"events")
	_test_a_car_on_course_is_red_one_beside_her_line_is_not(t)
	_test_a_walker_brushing_past_is_unmarked(t)
	_test_the_arterial_at_ordinary_density_marks_nobody(t)
	await _test_a_warning_cannot_be_cleared_by_somebody_who_cannot_see_it(t)
	_test_a_car_sounding_its_horn_carries_its_own_mark(t)
	_test_the_screen_edge_is_the_same_size_for_everyone(t)
	await _test_the_badge_measures_the_things_own_speed(t)
	await _test_the_edge_badges_only_what_the_row_announces(t)
	await _test_a_live_instance_keeps_its_badge_and_a_gone_one_loses_it(t)
	await _test_a_source_can_take_down_its_own_warning_and_nobody_elses(t)
	_test_the_pram_says_how_the_baby_is(t)
	_test_the_babys_cue_only_steps_aside_for_something(t)
	_test_the_carried_babys_cue_stays_over_her_head(t)
	_atlas.release(&"events")

const MapCache := preload("res://tests/city_map_cache.gd")
const CrowdStreetRig := preload("res://tests/crowd_street_rig.gd")

const STEP := 1.0 / 60.0

## The events' atlas page, held for the suite: an event or a badge in the tree is drawn on real
## frames, and the game hands each the library it draws from.
var _atlas := AtlasLibrary.new()

# ------------------------------------------------------------------- the mark ---

## A car's own equivalent, over the strike box `Crowd._strike()` actually collides against rather
## than a def's inner radius. The car is one the crowd's own entry places on a straight stretch of
## a real city (`Crowd.add_recipe_actor()`), driving down its lane at the slowest speed a car is
## generated at.
func _test_a_car_on_course_is_red_one_beside_her_line_is_not(t: TestRunner) -> void:
	var street := _a_street(t)
	if street.is_empty():
		return
	var crowd: Crowd = street.crowd
	var car: CrowdAgent = _street_rig.place_on(crowd, street.map, CrowdAgent.Kind.CAR, street.corridor,
			CrowdLanes.road_lane(true, 1.0), street.along, 1.0, true, CrowdLanes.SIDEWALK_OFFSETS,
			Tuning.CAR_SPEED.x)
	var in_its_lane := car.global_position + Vector2(0.0, 60.0)
	car.mood().set_her_at(in_its_lane)
	t.check(car.mood().will_be_lethal(in_its_lane),
			"a car whose strike box reaches the lane she is standing in front of is red")
	var beside_its_line := car.global_position + Vector2(50.0, 60.0)
	car.mood().set_her_at(beside_its_line)
	t.check(not car.mood().will_be_lethal(beside_its_line),
			"the same car passing beside her — she would have to step into it herself — is not")
	_street_rig.free_crowd(crowd)

## `PEDESTRIAN_INTENSITY` (4.2/s) times `Tuning.EXPECTED_IMPACT_HORIZON` (5s) is 21, under
## `Tuning.EXPECTED_IMPACT_POINTS` (40) by construction, so no ordinary walker can ever earn a
## caret on its own field — only a jolt (a bump, a horn) could add enough, and this one carries
## none.
func _test_a_walker_brushing_past_is_unmarked(t: TestRunner) -> void:
	var street := _a_street(t)
	if street.is_empty():
		return
	var crowd: Crowd = street.crowd
	var walker: CrowdAgent = _street_rig.place_on(crowd, street.map, CrowdAgent.Kind.WALKER, street.corridor,
			0, street.along, 1.0)
	walker.mood().set_her_at(walker.global_position + Vector2(20.0, 25.0))
	t.check(walker.mood().caret_strength() == 0,
			"an ordinary walker brushing past her carries no caret at all")
	_street_rig.free_crowd(crowd)

## A crowd over a real generated map, emptied (no city is built around it: this suite asks the crowd's
## bodies), with a straight stretch of ordinary street to place a body on: `{crowd, map, corridor,
## along}`, or an empty dictionary (and a failed check) when the map has none.
func _a_street(t: TestRunner) -> Dictionary:
	var map := MapCache.of(STREET_SEED)
	var crowd := _street_rig.a_crowd(t, map)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("test_danger:street")
	crowd.start_day(1, rng, Vector2.ZERO)
	crowd.clear()
	var run: Vector2i = _street_rig.a_straight_run(map, Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a straight stretch of street to place a body on")
	if run.x < 0:
		_street_rig.free_crowd(crowd)
		return {}
	return {"crowd": crowd, "map": map, "corridor": run.x,
			"along": float(run.y + 2) * Tuning.TILE_SIZE}

const STREET_SEED := 4242
## The street rig (`tests/crowd_street_rig.gd`): places a car or a walker through the crowd's own entry.
var _street_rig := CrowdStreetRig.new()

## **The line this milestone cannot merge on the wrong side of.** *(2026-09-08, on the one
## measurement rather than an argument: "the answer has to be none at ordinary density, or the
## line moves before this merges".)* A real generated map, a real `Crowd.step()` — "a rig that
## steps the parts is not running the whole" (`.claude/skills/crowd-traffic/SKILL.md`) — at
## ordinary arterial density, for the same forty-second walk `docs/EVENTS.md`'s own cost-table
## measurement uses, with the player standing still on the pavement rather than walking it: not
## one amber caret over the whole of it.
func _test_the_arterial_at_ordinary_density_marks_nobody(t: TestRunner) -> void:
	var map := MapCache.of(9137)
	var crowd := _street_rig.a_crowd(t, map)
	var standing_at := CrowdLanes.arterial_pavement(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("test_danger:arterial")
	crowd.start_day(1, rng, standing_at)

	var amber := 0
	for i in int(round(40.0 / STEP)):
		crowd.step(STEP)
		for agent in crowd.agents():
			agent.mood().set_her_at(standing_at)
			if agent.mood().caret_strength() == 1:
				amber += 1
	t.check(amber == 0,
			("a crowd at ordinary arterial density around a standing player marks nobody " +
					"(%d amber frames over the walk)") % amber)
	_street_rig.free_crowd(crowd)

# ------------------------------------------------------- the cue over the player ---

## The load-bearing cue, and the bug the two-level version could easily have had. The crowd and
## the events both watch the ground she is standing on, in the same frame. A setter lets
## whichever runs second clear what the first just said — so a lethal event on top of her would
## be silently downgraded to nothing by the traffic deciding there was no car coming.
func _test_a_warning_cannot_be_cleared_by_somebody_who_cannot_see_it(t: TestRunner) -> void:
	var rig := _rig(t)
	t.check(rig.alert_level() == Stroller.Alert.NONE, "nothing over her head to begin with")

	rig.warn(Stroller.Alert.NOW, 0.5)
	rig.warn(Stroller.Alert.SOON, 0.5)
	t.check(rig.alert_level() == Stroller.Alert.NOW,
			"the louder warning survives a quieter one raised in the same frame")

	# And it goes away on its own rather than needing to be told to.
	await _physics_ticks(t, rig, 0.6)
	t.check(rig.alert_level() == Stroller.Alert.NONE, "a warning expires by itself")

	rig.warn(Stroller.Alert.SOON, 0.5)
	t.check(rig.alert_level() == Stroller.Alert.SOON,
			"and a quieter one can be raised once the loud one has gone")
	rig.free()

## The traffic half of the same finding, and the one the vocabulary's first row was not paying
## for: *the entity itself carries most of it* — except a car, which carried nothing at all,
## because the caret is drawn by `EventInstance` and a car is not an event. A lethal thing bore
## down on the player and produced a mark over **her** head and nothing anywhere else.
func _test_a_car_sounding_its_horn_carries_its_own_mark(t: TestRunner) -> void:
	var methods: Array[String] = []
	for entry in (load("res://src/crowd/crowd_agent.gd") as GDScript).get_script_method_list():
		methods.append(String(entry["name"]))
	t.check("_draw_mark" in methods, "a car draws a mark of its own")
	# The caret is one shape in one place, not two similar ones: a short vocabulary stays short
	# only if nobody hand-draws a second chevron.
	var shared: Array[String] = []
	for entry in (load("res://src/sprites.gd") as GDScript).get_script_method_list():
		shared.append(String(entry["name"]))
	t.check("draw_caret" in shared,
			"and it is the same caret the events draw, from one place")

# ------------------------------------------------------------- the screen edge ---

## `MARGIN` and `SCREEN_MARGIN` are screen px, which is only a fair unit if every player's screen
## shows the same slice of world. `"expand"` would let a wide monitor see more city than a laptop
## before the same margin fires, buying it more warning for nothing the player did — `"keep"` holds
## the viewport at a fixed 1280×720 and bars the rest, so this is the setting the badge's whole
## unit of measurement depends on.
func _test_the_screen_edge_is_the_same_size_for_everyone(t: TestRunner) -> void:
	t.check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep",
			"the window letterboxes instead of showing more or less city on a different screen")

## **The badge measures the event's speed, not the gap's.** *(Playtest 06, finding 1: "they show
## events far away, and if you walk towards them they sometimes disappear; also they flicker a
## lot.")* All three symptoms are one line: the rate the gap was shrinking is her speed plus its
## speed, and she walks at 92 against a threshold of 20, so walking towards anything lethal
## raised its badge whether or not it was coming.
##
## The arithmetic of the window (a time to arrive, not a distance) is `tests/test_badge_model.gd`'s;
## this runs the plumbing, what the edge hands the model, on real frames.
func _test_the_badge_measures_the_things_own_speed(t: TestRunner) -> void:
	# The edge runs its own frames, and each thing moves by hand at its own speed over the frame's
	# own length: a stationary fire engine with her walking at it, then the same one driving at her.
	var manager := FakeEventManager.new()
	var standing := Node2D.new()
	t.add_child(standing)
	var edge := DangerEdge.new()
	edge.use_atlas(_atlas)
	edge.setup(manager, standing)
	t.add_child(edge)

	var def := EventCatalogue.by_id("fire_truck")
	var engine := manager.spawn_extra(def, Vector2(700.0, 0.0))

	# A second of her walking straight at a stopped fire engine.
	var announced_while_walking := false
	var walked := 0.0
	while walked < 1.0:
		var delta: float = t.get_process_delta_time()
		standing.global_position += Vector2(Tuning.WALK_SPEED * delta, 0.0)
		walked += delta
		await t.get_tree().process_frame
		announced_while_walking = announced_while_walking or not edge.badges().announcing().is_empty()
	t.check(not announced_while_walking,
			"walking towards something lethal does not announce it at the edge of the screen")

	# And a second of it driving at her while she stands still.
	var driven := 0.0
	while driven < 1.0:
		var delta: float = t.get_process_delta_time()
		engine.global_position -= Vector2(def.speed() * delta, 0.0)
		driven += delta
		await t.get_tree().process_frame
	t.check(edge.badges().announcing().size() == 1, "a fire engine actually coming down the street does")

	edge.free()
	standing.free()
	manager.free()

## **The edge badges what the row announces, and nothing else that comes fast.** Whether a row's
## coming is worth an arrow is the row's own answer (`EventDef.announces_its_coming()`); this is
## that the edge asks it. The crossing cat comes at 240px/s, fast enough to be badged on its speed
## alone, and its row does not announce it (it does not telegraph its coming, PLAYTEST-145 20), so
## a second of it running at her from off screen puts nothing on the edge.
func _test_the_edge_badges_only_what_the_row_announces(t: TestRunner) -> void:
	var manager := FakeEventManager.new()
	var standing := Node2D.new()
	t.add_child(standing)
	var edge := DangerEdge.new()
	edge.use_atlas(_atlas)
	edge.setup(manager, standing)
	t.add_child(edge)

	var def := EventCatalogue.by_id("cat_dash")
	t.check(not def.announces_its_coming(Tuning.WALK_SPEED),
			"the cat's row does not announce its coming, so the check below is about the edge")
	var cat := manager.spawn_extra(def, Vector2(700.0, 0.0))
	var ran := 0.0
	var announced := false
	while ran < 1.0:
		var delta: float = t.get_process_delta_time()
		cat.global_position -= Vector2(def.approach_speed() * delta, 0.0)
		ran += delta
		await t.get_tree().process_frame
		announced = announced or not edge.badges().announcing().is_empty()
	t.check(not announced, "a cat running at her from off screen gets no badge at the edge")

	edge.free()
	standing.free()
	manager.free()

## An instance still around keeps its badge frame to frame, and one `_events.instances()` stopped
## carrying loses it rather than leaving it up forever.
func _test_a_live_instance_keeps_its_badge_and_a_gone_one_loses_it(t: TestRunner) -> void:
	var manager := FakeEventManager.new()
	var standing := Node2D.new()
	t.add_child(standing)
	var edge := DangerEdge.new()
	edge.use_atlas(_atlas)
	edge.setup(manager, standing)
	t.add_child(edge)

	var def := EventCatalogue.by_id("fire_truck")
	var engine := manager.spawn_extra(def, Vector2(700.0, 0.0))
	var driven := 0.0
	while driven < 1.0:
		var delta: float = t.get_process_delta_time()
		engine.global_position -= Vector2(def.speed() * delta, 0.0)
		driven += delta
		await t.get_tree().process_frame
	t.check(edge.badges().announcing().size() == 1, "a live instance closing from off screen is badged")
	# Ended where it stands, then let go of, as the manager's streaming does with what it retires.
	manager.retire(engine)
	engine.free()
	await t.get_tree().process_frame
	t.check(edge.badges().announcing().is_empty(),
			"an instance _events.instances() no longer carries loses its badge, not left to sit there forever")

	edge.free()
	standing.free()
	manager.free()

## The other half of the same shape, and the reason `warn()` is additive. *(Playtest 06, finding
## 3: "I get the flashing exclamation marks **after** the fact, at which point they're not
## useful.")* The hold on the traffic's warning is 1.4s and has a real job — surviving the gap
## between two cars in one lane — so the fix is a second condition rather than a shorter hold,
## and the condition belongs to the system that can see it.
func _test_a_source_can_take_down_its_own_warning_and_nobody_elses(t: TestRunner) -> void:
	var rig := _rig(t)

	rig.warn(Stroller.Alert.SOON, 1.4, Crowd.WARNING_SOURCE)
	rig.stand_down(WarningBoard.WARNING_SOURCE)
	t.check(rig.alert_level() == Stroller.Alert.SOON,
			"an event cannot take down a warning the traffic raised")
	rig.stand_down(Crowd.WARNING_SOURCE)
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"and the traffic can, the instant she is over the kerb")

	# And a source that has been outbid finds nothing of its own to lower, which is what keeps
	# this from being the setter the additive rule exists to prevent.
	rig.warn(Stroller.Alert.SOON, 1.4, Crowd.WARNING_SOURCE)
	rig.warn(Stroller.Alert.NOW, 0.35, WarningBoard.WARNING_SOURCE)
	rig.stand_down(Crowd.WARNING_SOURCE)
	t.check(rig.alert_level() == Stroller.Alert.NOW,
			"the traffic cannot clear a lethal event's mark by driving away")

	# An upgrade takes the new caller's hold rather than inheriting the old one's remainder,
	# or a second of leftover `SOON` outlives the `NOW` that replaced it.
	await _physics_ticks(t, rig, 0.4)
	t.check(rig.alert_level() == Stroller.Alert.NONE,
			"and the doubled mark expires on its own hold, not on the one underneath it")
	rig.free()

## The baby's own cue. *(Playtest 06, finding 5.)* Four states, each a different instruction, and
## the test is that they are *states* — a mark that is up whenever a meter is moving is the HUD
## drawn over the pram, which is the rings' mistake arriving from the other direction.
func _test_the_pram_says_how_the_baby_is(t: TestRunner) -> void:
	var baby := Baby.new()

	baby.reset()
	baby.seed_meters(baby.sleepiness_level(), Tuning.EXCITEMENT_CALM_THRESHOLD - 1.0)
	t.check(baby.cue() == Baby.Cue.NONE,
			"an ordinary street says nothing over the pram")
	baby.seed_meters(baby.sleepiness_level(), Tuning.EXCITEMENT_CALM_THRESHOLD)
	t.check(baby.cue() == Baby.Cue.UNSETTLED,
			"the moment the day stops progressing, it says so")
	baby.seed_meters(baby.sleepiness_level(), Baby.EXCITEMENT_NEARLY_CRYING)
	t.check(baby.cue() == Baby.Cue.NEARLY_CRYING,
			"and escalates before the day is lost rather than as it is lost")

	baby.force_sleep()
	baby.seed_meters(baby.sleepiness_level(), 0.0)
	t.check(baby.cue() == Baby.Cue.ASLEEP, "asleep is a state with a mark of its own")
	baby.seed_meters(baby.sleepiness_level(), Tuning.EXCITEMENT_WAKE_THRESHOLD - Baby.EXCITEMENT_STIR_MARGIN)
	t.check(baby.cue() == Baby.Cue.STIRRING,
			"and stirring is warned about before it costs half the bar")

	# The relationships, which are what a rebalance must not quietly break.
	t.check(Baby.EXCITEMENT_NEARLY_CRYING > Tuning.EXCITEMENT_CALM_THRESHOLD
			and Baby.EXCITEMENT_NEARLY_CRYING < Tuning.METER_MAX,
			"the last warning band sits between the freeze and the lost day")
	t.check(Baby.EXCITEMENT_STIR_MARGIN > 0.0
			and Baby.EXCITEMENT_STIR_MARGIN < Tuning.EXCITEMENT_WAKE_THRESHOLD,
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
func _test_the_babys_cue_only_steps_aside_for_something(t: TestRunner) -> void:
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
	# *(playtest freckled-goose, inbox #545: "when going south the zzz jumps up a full stroller gap
	# above the player".)* Measured from her feet the cue clears her head by what the other facings
	# clear the pram art by, not by a second stroller length.
	t.check(is_equal_approx(rig.pram_draw_offset().y - rig.baby_cue_lift(),
					-(Stroller.FIGURE_HEIGHT + Stroller.BABY_CUE_LIFT - Stroller.PRAM_ART_HEIGHT)),
			"the cue is just over her head, with the gap the pram art gets elsewhere")
	rig.warn(Stroller.Alert.SOON, 1.0, &"test")
	t.check(not is_zero_approx(rig.baby_cue_aside()),
			"and it steps out of the mark's column there too, once there is a mark")
	rig.stand_down(&"test")

	rig.facing = Vector2.RIGHT
	t.check(is_zero_approx(rig.baby_cue_aside()),
			"and sideways there is nothing to step around at all")
	t.check(is_equal_approx(rig.baby_cue_lift(), Stroller.BABY_CUE_LIFT),
			"nor anything to be lifted over: the pram is out to one side of her")

	# *(M43, playtest 11 finding 9: "the diagonal zzz got moved up like the downward zzz.")* Both
	# cues used to ask *which axis is she mostly facing*, which puts a diagonal on the vertical
	# side of the line — so south-east and south-west took the southward lift off a pram that was
	# 24px to one side of her and never behind anything.
	#
	# All eight are held here rather than the three that have been reported, because this cue has
	# been adjusted in M32, M37, M39 and now M43, and each of the last three was a facing the
	# previous fix had not been asked about.
	for facing: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
			Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
			Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]:
		rig.facing = facing
		var in_column := is_zero_approx(facing.x)
		t.check(is_zero_approx(rig.baby_cue_aside()),
				"facing %v with nothing happening, the cue sits on the pram" % facing)
		t.check((rig.baby_cue_lift() > Stroller.BABY_CUE_LIFT)
				== (in_column and facing.y > 0.0),
				"facing %v is lifted over her only when the pram is due south of her" % facing)
		rig.warn(Stroller.Alert.SOON, 1.0, &"test")
		t.check(not is_zero_approx(rig.baby_cue_aside()) == in_column,
				"facing %v steps out of the mark's column only when it shares one" % facing)
		rig.stand_down(&"test")
	rig.free()

## Carrying, the cue sits over her head on all eight facings and steps aside to one fixed shoulder,
## so a run that turns does not move it (inbox #778 in minty-lemur: the zzz "moves around wildly").
func _test_the_carried_babys_cue_stays_over_her_head(t: TestRunner) -> void:
	var scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var rig: Stroller = scene.instantiate()
	rig.carrying = true
	# Just over her head: her height plus the clearance the cue keeps over a pram's art, 52px, and
	# not a pram's height more (82px, where it floated with nothing under it).
	var lift := Stroller.FIGURE_HEIGHT + (Stroller.BABY_CUE_LIFT - Stroller.PRAM_ART_HEIGHT)
	t.check(is_equal_approx(lift, 52.0), "the carried cue sits 52px above her feet")
	for facing: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
			Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
			Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]:
		rig.facing = facing
		t.check(is_equal_approx(rig.baby_cue_lift(), lift),
				"carrying, facing %v the cue is over her head" % facing)
		t.check(is_zero_approx(rig.baby_cue_aside()),
				"carrying, facing %v with nothing happening the cue is not stepped aside" % facing)
		rig.warn(Stroller.Alert.SOON, 1.0, &"test")
		t.check(is_equal_approx(rig.baby_cue_aside(), Stroller.BABY_CUE_ASIDE),
				"carrying, facing %v the cue steps to the same shoulder" % facing)
		rig.stand_down(&"test")
	rig.free()

# ------------------------------------------------------------------- helpers ---

## A Stroller with the camera it looks up by path, in the tree so its `@onready` actually runs, its
## own tick off until a test lets real ticks pass (`_physics_ticks()`). `SomeNode.new()` is not
## named `SomeNode`, so the camera has to be named explicitly or the lookup fails silently.
func _rig(t: TestRunner) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig

## Lets `seconds` of the stroller's own physics ticks pass for real, counted in ticks, one tick a
## frame (record busy-puffin: a slow frame would pack several), its tick switched on only for them.
## Ends on the frame after the last tick, so the rig has run every one of them.
func _physics_ticks(t: TestRunner, rig: Stroller, seconds: float) -> void:
	var steps := Engine.max_physics_steps_per_frame
	Engine.max_physics_steps_per_frame = 1
	rig.set_physics_process(true)
	var ticks := ceili(seconds * Engine.physics_ticks_per_second - 0.001)
	var ran := 0
	while ran < ticks:
		var before := Engine.get_physics_frames()
		await t.get_tree().physics_frame
		ran += Engine.get_physics_frames() - before
	await t.get_tree().process_frame
	rig.set_physics_process(false)
	Engine.max_physics_steps_per_frame = steps
