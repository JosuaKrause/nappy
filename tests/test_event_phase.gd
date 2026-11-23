extends RefCounted
## The event's stored phase and the one warning clock: `EventInstance.Phase` changed only by
## `transition()`, every row's telegraph and every waiting row's notice moving through it, a notice
## carried across a stream-out exactly as far run (held time included), and `Warning` itself — the
## clock an event's notice, a door crossing and a badge up alone all run on. A live event is built
## here by hand, with no scheduler, map or manager under it, and stepped through real seconds: what it
## charges through its phases (the telegraph's damping, a field's bound, a two-part field, a
## protest's swell), the collision shapes a crash registers, and that it leaves rather than vanishing.

const STEP := 0.1
const EMISSION_STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_a_warning_starts_holds_and_runs_out(t)
	_test_a_warning_ticks_into_its_action_or_is_called_off(t)
	_test_a_row_with_no_wait_is_in_its_telegraph_then_active(t)
	_test_a_waiting_row_notices_warns_and_waits_again(t)
	_test_a_departure_and_a_finish_are_phases(t)
	_test_a_dog_shaken_off_mid_telegraph_is_telegraphing_until_its_clock_runs(t)
	_test_a_held_notice_comes_back_as_far_run(t)
	_test_a_badge_up_alone_points_and_counts_down(t)
	_test_a_live_event_answers_for_its_row(t)
	_test_a_long_body_reaches_along_its_spine_the_way_its_field_does(t)
	_test_a_mover_reaches_as_the_ellipse_its_field_is(t)
	_test_a_flock_reaches_where_one_of_its_birds_does(t)
	_test_a_live_event_leaves_its_rows_spread_classification_alone(t)
	_test_a_live_crash_registers_a_collision_shape_per_car(t)
	_test_telegraph_damps_emission(t)
	_test_a_phase_damps_both_parts_of_a_two_part_field(t)
	_test_a_live_protest_swells_over_its_life(t)
	_test_the_rows_she_walks_up_to_pass_positively_awake(t)
	_test_the_loose_dog_costs_more_to_pass_than_the_dog_walker(t)
	_test_duration_and_finish(t)
	_test_an_event_leaves_rather_than_vanishing(t)
	_test_no_field_reaches_past_silent_beyond(t)
	_test_contribution_skips_only_silence(t)
	_test_flocks_are_not_skipped(t)
	_test_roadwork_barrier_follows_alley_axis(t)
	_test_an_event_is_silent_behind_a_wall(t)
	_test_an_event_expects_nothing_from_behind_a_wall(t)

# ------------------------------------------------------------------- the clock ---

func _test_a_warning_starts_holds_and_runs_out(t: TestRunner) -> void:
	var warning := Warning.new()
	t.check(not warning.is_running() and warning.elapsed(5.0) == 0.0,
			"a warning not started is not running and has run for nothing")
	warning.start(1.0, 2.0)
	t.check(warning.is_running(), "started, it runs")
	t.close_to(warning.elapsed(2.5), 1.5, "it has run for the clock since its start")
	t.check(not warning.has_run(2.5), "and has not run its two seconds by then")
	warning.hold(0.5)
	t.close_to(warning.elapsed(3.0), 1.5, "a held half second does not count")
	t.check(not warning.has_run(3.0), "so at 3.0 it still has half a second to run")
	t.close_to(warning.left(3.0), 0.5, "which is what is left")
	t.check(warning.has_run(3.5), "and at 3.5 it has run")
	t.close_to(warning.started_at(), 1.5, "its start, held time counted back in, is 1.5")
	warning.stop()
	t.check(not warning.is_running() and warning.started_at() == INF, "stopped, it is not running")

func _test_a_warning_ticks_into_its_action_or_is_called_off(t: TestRunner) -> void:
	var ran := [0]
	var off := [false]
	var warning := Warning.new()
	warning.call_off_when(func() -> bool: return off[0])
	warning.run_when_it_runs_out(func() -> void: ran[0] += 1)
	warning.start(0.0, 1.0)
	t.check(warning.tick(0.5) == Warning.Outcome.RUNNING, "half way, it is running")
	t.check(warning.tick(1.0) == Warning.Outcome.RAN_OUT and ran[0] == 1,
			"at its length it runs out into its action, once")
	t.check(warning.tick(1.5) == Warning.Outcome.NOT_RUNNING and ran[0] == 1,
			"and is not running after it")
	warning.start(2.0, 1.0)
	off[0] = true
	t.check(warning.tick(2.2) == Warning.Outcome.CALLED_OFF and ran[0] == 1,
			"called off, it never reaches its action")

# ------------------------------------------------------------------- the phase ---

func _test_a_row_with_no_wait_is_in_its_telegraph_then_active(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.phase == EventInstance.Phase.WARNING and instance.is_telegraphing(),
			"a row with no wait starts in its telegraph")
	var before := int(floor(instance.telegraphs_for() / STEP)) - 1
	for i in before:
		instance.step(STEP)
	t.check(instance.is_telegraphing(),
			"and is still in it a step before the %.2fs it says it telegraphs for"
			% instance.telegraphs_for())
	for i in int(ceil(instance.telegraphs_for() / STEP)) + 1 - before:
		instance.step(STEP)
	t.check(instance.phase == EventInstance.Phase.ACTIVE and not instance.is_telegraphing(),
			"and is active once its telegraph has run")
	instance.free()

func _test_a_waiting_row_notices_warns_and_waits_again(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(instance_where))
	t.check(instance.phase == EventInstance.Phase.WAITING and instance.is_waiting(),
			"a row that waits starts waiting")
	instance_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	instance.step(STEP)
	t.check(instance.phase == EventInstance.Phase.WARNING and not instance.is_waiting(),
			"inside its one radius it notices her and warns")
	t.check(instance.save().noticed_at() != INF, "and its notice has a start")
	instance_where.tell(Vector2(def.notice_within() + 40.0, 0.0))
	instance.step(STEP)
	t.check(instance.phase == EventInstance.Phase.WAITING and instance.is_waiting(),
			"back outside its radius, it waits again")
	t.check(instance.save().noticed_at() == INF, "with no notice left")
	instance_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	var frames := 0
	while instance.phase == EventInstance.Phase.WARNING or frames == 0:
		instance.step(STEP)
		frames += 1
		if frames > 200:
			break
	t.check(instance.phase == EventInstance.Phase.ACTIVE,
			"staying inside, it charges once its warning has run (%d frames)" % frames)
	t.close_to(frames * STEP, def.pursuit().warns_for(), "after its own warning", 2.0 * STEP)
	instance.free()

func _test_a_departure_and_a_finish_are_phases(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("dog_walker")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2(40.0, 0.0)]),
			Vector2.RIGHT,
			EventSurroundings.new().hearing(instance_where))
	instance_where.tell(Vector2(0.0, 2000.0))
	var frames := 0
	while not instance.is_on_its_way_out() and frames < 400:
		instance.step(STEP)
		frames += 1
	t.check(instance.phase == EventInstance.Phase.LEAVING and instance.is_on_its_way_out()
			and instance.is_on_its_way_out() and not instance.is_gone(),
			"off the end of its route it is leaving (%d frames)" % frames)
	t.check(instance.current_intensity() == 0.0, "and emits nothing while it goes")
	var leaving_ticks := 0
	while not instance.is_gone() and leaving_ticks < 400:
		instance.step(STEP)
		leaving_ticks += 1
	t.check(instance.phase == EventInstance.Phase.DONE and instance.is_gone()
			and instance.is_gone() and not instance.is_on_its_way_out() and not instance.is_on_its_way_out(),
			"finished, it is done, and only done")
	instance.free()

## **A telegraph is a promise about the clock, not the phase.** The day-3 lesson dog spends its
## 4.5s telegraph closing on her; once it is 1.5s in (`Tuning.PURSUIT_MIN_NOTICE`), running for
## `Tuning.PURSUIT_SHAKEN_OFF` shakes it off and it trots away while its telegraph is still running.
## It goes on answering `is_telegraphing()` until its clock runs out, as everything that reads it —
## the alert over her head, `event_activated`, its pictures — has always seen it.
func _test_a_dog_shaken_off_mid_telegraph_is_telegraphing_until_its_clock_runs(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	var dog_where := WhereSheIs.nowhere()
	var dog := EventInstance.new()
	dog.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(dog_where))
	var her := Vector2(400.0, 0.0)
	var clock := 0.0
	while not dog.is_on_its_way_out() and clock < def.telegraphs_for():
		if clock >= 1.2:
			dog_where.tell(dog_where.at(), Vector2.INF, Rect2(), true)
			her += Vector2(Tuning.RUN_SPEED * STEP, 0.0)
		dog_where.tell(her, Vector2.INF, Rect2(), dog_where.is_running())
		dog.step(STEP)
		clock += STEP
	t.check(dog.is_on_its_way_out() and dog.chase_age() < def.telegraphs_for(),
			"run from 1.2s, the lesson dog gives up %.1fs into its %.1fs telegraph"
			% [dog.chase_age(), def.telegraphs_for()])
	t.check(dog.is_telegraphing(), "and is still telegraphing as it leaves")
	t.check(dog.has_given_up(), "having given up: she shook it off, its clock did not run out")
	# She follows it at 100px, so it stays in her sight and in the world while its clock runs.
	while dog.chase_age() < def.telegraphs_for() - 2.0 * STEP and not dog.is_gone():
		dog_where.tell(dog.global_position + Vector2(100.0, 0.0), Vector2.INF, Rect2(),
				dog_where.is_running())
		dog.step(STEP)
		t.check(dog.is_telegraphing(), "every frame until its clock runs out (%.1fs)" % dog.chase_age())
	while dog.chase_age() < def.telegraphs_for() + STEP and not dog.is_gone():
		dog_where.tell(dog.global_position + Vector2(100.0, 0.0), Vector2.INF, Rect2(),
				dog_where.is_running())
		dog.step(STEP)
	t.check(not dog.is_gone() and dog.is_on_its_way_out(), "still in the world, leaving")
	t.check(not dog.is_telegraphing(), "and not once its %.1fs have run" % def.telegraphs_for())
	dog.free()

## A notice that was held (a held lunge with her inside its stand-off, a charger behind a wall at its
## warning's last moment, the masked man's wait) is carried across a stream-out held time and all, so
## the instance put back is exactly as far into its notice as the one taken away. The robber here is
## set on her inside his stand-off (`notice_her_at()`), which holds his lunge and so his notice's clock
## every tick (`_hold_the_notice_clock()`): a second of standing there has run none of his notice, and
## the second he waited is in the start the stream-out carries. A walk out of the stand-off cannot
## show the notice running afterwards, since he lunges the moment she is at the full stand-off.
func _test_a_held_notice_comes_back_as_far_run(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var first_where := WhereSheIs.nowhere()
	var first := EventInstance.new()
	first.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(first_where))
	var her := Vector2(60.0, 0.0)
	t.check(her.length() < first.charge_radius(), "she stands inside the robber's stand-off")
	first.notice_her_at(her, 5.0)
	var held_steps := 10
	for i in held_steps:
		first_where.tell(her)
		first.step(STEP)
	t.check(first.phase == EventInstance.Phase.WARNING, "set on her, he is warning")
	t.close_to(first.chase_age(), 0.0, "and his notice, held every tick, has not run", 0.0001)
	t.close_to(first.save().noticed_at(), held_steps * STEP,
			"the second he waited is counted into the start a stream-out carries", 0.0001)
	var second := EventInstance.new()
	second.setup(def, Vector2.ZERO)
	# Put back two seconds later: the notice has run those two seconds, and the second he waited held
	# is not counted as run. Started at the age it was put back at instead, it would have run none.
	second.restore(EventSave.new(first.age() + 2.0, 0.0, first.save().noticed_at()))
	t.close_to(second.chase_age(), 2.0, "streamed back in, it has run the two seconds since and not the held one", 0.0001)
	first.free()
	second.free()

# A hunting copy cannot write its pursuit onto its row, since a `PursuitSpec` has no setter.
# `tests/test_heat.gd` holds whether a hunting copy pursues; the chase speed and notice distance
# are settings, not read back by any suite.

# -------------------------------------------------------------- the badge alone ---

## A warning up before its thing exists points where the thing will come from, moving only with
## her, and counts down the row's own warning, on the clock above.
func _test_a_badge_up_alone_points_and_counts_down(t: TestRunner) -> void:
	var def := EventSpawner.as_warned(EventCatalogue.by_id("cyclist"))
	var arrived := [0]
	var where := func(her: Vector2) -> Vector2: return her + Vector2(600.0, 0.0)
	var arrive := func(_at: Vector2, _her: Vector2) -> bool:
		arrived[0] += 1
		return true
	var warning := PendingWarning.new(def, where, arrive)
	t.check(warning.row() == def, "it warns of the row it was made for")
	t.check(warning.points_at() == Vector2.INF, "and points nowhere before it is put up")
	warning.put_up(Vector2.ZERO)
	t.check(warning.points_at() == Vector2(600.0, 0.0), "put up, it points where the thing would come")
	t.close_to(warning.seconds_left(), def.warned_for(), "with the row's whole warning to run")
	warning.tick(STEP, Vector2(0.0, 50.0))
	t.check(warning.points_at() == Vector2(600.0, 50.0), "and the place moves only with her")
	t.close_to(warning.seconds_left(), def.warned_for() - STEP, "a step less to run after a step")
	var steps := 0
	while arrived[0] == 0 and steps < 100:
		warning.tick(STEP, Vector2(0.0, 50.0))
		steps += 1
	t.check(arrived[0] == 1 and warning.seconds_left() <= 0.0,
			"its thing comes once nothing is left of it")

## A live event made where it stands came under no warning, one that does not drive closes on
## nothing, and its field reaches exactly where its row's field is heard: the reach the run log's
## lines ask (`field_reaches()`) agrees with the field the meter is charged from.
func _test_a_live_event_answers_for_its_row(t: TestRunner) -> void:
	for id: String in ["alley_robbery", "police_patrol", "cafe_tables", "cyclist"]:
		var def := EventCatalogue.by_id(id)
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO)
		t.check(not instance.was_warned_of(), "'%s' made where it stands came under no warning" % id)
		if not instance.drives():
			t.check(not instance.closes_on(Vector2.ZERO),
					"'%s' drives nothing, so it closes on nothing" % id)
		for distance: float in [0.0, def.heard_within() - 1.0, def.heard_within() + 1.0, 2000.0]:
			var at := Vector2(0.0, distance)
			t.check(instance.field_reaches(at) == (def.emission_at_distance(distance) > 0.0),
					"'%s' reaches %.0fpx out exactly where its row's field is heard" % [id, distance])
		instance.free()

## **A row with a long body reaches as far along that body as its field runs**: the field is a capsule
## about the spine, so a point one pixel inside it past the row's outer radius from the centre is
## reached, and one a pixel outside it along the spine is not, where a disc of the outer radius says
## the reverse. Across the body the capsule and the disc agree.
func _test_a_long_body_reaches_along_its_spine_the_way_its_field_does(t: TestRunner) -> void:
	var tried := 0
	for def: EventDef in EventCatalogue.all():
		var body := def.datum()
		if body == null or not body.is_segment() or def.moves() or def.drives() \
				or def.pursues() or def.is_a_flock():
			continue
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO)
		var axis := instance.solid_axis()
		var along := body.spine_half_length() + def.heard_within()
		t.check(instance.field_reaches(axis * (along - 1.0)),
				"'%s' reaches a point just inside its capsule along its spine" % def.id())
		t.check(not instance.field_reaches(axis * (along + 1.0)),
				"'%s' does not reach one just outside its capsule along its spine" % def.id())
		var across := axis.orthogonal()
		t.check(instance.field_reaches(across * (def.heard_within() - 1.0))
				and not instance.field_reaches(across * (def.heard_within() + 1.0)),
				"'%s' reaches abeam of its body exactly as far as its row is heard" % def.id())
		instance.free()
		tried += 1
	t.check(tried > 0, "the catalogue has a stationary row with a long body to try")

## **A mover reaches as far ahead of itself as its field runs and as far behind**: the field is an
## ellipse with the mover at one focus, `outer radius / (1 - e)` dead ahead and
## `outer radius / (1 + e)` behind, and exactly outer radius abeam, where a disc says
## outer radius every way. The cyclist is given a route so that it moves.
func _test_a_mover_reaches_as_the_ellipse_its_field_is(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2(1000.0, 0.0)]))
	var velocity := instance.travel_velocity()
	t.check(not velocity.is_zero_approx(), "the cyclist given a route moves")
	var ahead := velocity.normalized()
	var e := Field.eccentricity(velocity.length())
	var outer := def.heard_within()
	t.check(instance.field_reaches(ahead * (outer / (1.0 - e) - 1.0)),
			"the cyclist reaches a point just inside its ellipse dead ahead, past its row's radius")
	t.check(not instance.field_reaches(ahead * (outer / (1.0 - e) + 1.0)),
			"and not one just outside it")
	t.check(instance.field_reaches(-ahead * (outer / (1.0 + e) - 1.0))
			and not instance.field_reaches(-ahead * (outer / (1.0 + e) + 1.0)),
			"behind it the ellipse is shorter than its row's radius")
	t.check(instance.field_reaches(ahead.orthogonal() * (outer - 1.0))
			and not instance.field_reaches(ahead.orthogonal() * (outer + 1.0)),
			"abeam of it the reach is its row's radius")
	instance.free()

## **A flock reaches where one of its birds' own fields does**, not within a disc about its centre:
## the birds' kernels (`bird_outer()` each, about where each bird is) cover less than the row's
## outer radius about the centre, so a point just inside that radius which no bird reaches is not
## reached, and the place a bird stands is.
func _test_a_flock_reaches_where_one_of_its_birds_does(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	instance.behaviours().flock().build()
	var any_bird := instance.birds()[0]
	t.check(instance.field_reaches(any_bird.at()), "a flock reaches the place one of its birds stands")
	var uncovered := Vector2(def.heard_within() - 1.0, 0.0)
	var covered_by_a_bird := false
	for bird in instance.birds():
		if bird.at().distance_to(uncovered) <= instance.behaviours().flock().bird_outer():
			covered_by_a_bird = true
	t.check(not covered_by_a_bird, "no bird's kernel covers a point just inside the flock's radius")
	t.check(not instance.field_reaches(uncovered),
			"so a flock does not reach it, though it is inside the disc its row is heard in")
	instance.free()

## **A live event leaves its row's classification as a spread alone**: crossing a phase and
## finishing are the instance's, and neither changes what the row it was set up from says it is,
## whatever geometry the row was reshaped to.
func _test_a_live_event_leaves_its_rows_spread_classification_alone(t: TestRunner) -> void:
	var cafe := EventCatalogue.by_id("cafe_tables")
	var reshaped := cafe.redraft()
	reshaped.body(cafe.body().reshaped(GroundShape.band(22.0)))
	reshaped.field(cafe.field().holding_to(15.0).reaching(90.0))
	reshaped.warning(WarningSpec.lasting(EMISSION_STEP))
	var def := reshaped.build()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	instance.step(EMISSION_STEP * 2.0)
	t.check(not instance.is_telegraphing() and def.lies_as_a_spread(),
			"crossing an instance phase leaves its definition's classification true")
	# The way the game ends one early: a resistance step's contact completing, which runs the
	# instance's own `_be_done()` and, for a café that has no departure speed, finishes it.
	instance.leave_for_a_completed_task()
	t.check(instance.is_gone() and def.lies_as_a_spread(),
			"finishing the instance leaves the classification true")
	instance.free()

## **A live crash registers one collision shape per car**, on either axis of the street it stands
## on (the pieces it stands are `tests/test_events_catalogue.gd`'s, asked of its stance). This
## fixture puts a live scenery-bearing instance in the tree without an EventManager, whose tree
## lifetime owns the events page in the game. Mirror that owner explicitly around the rig, on a
## library of the fixture's own that every instance is handed.
func _test_a_live_crash_registers_a_collision_shape_per_car(t: TestRunner) -> void:
	var map := CityMap.new()
	var crash := EventCatalogue.by_id("car_accident")
	var atlas := AtlasLibrary.new()
	atlas.acquire(EventPictures.ATLAS_GROUP)
	for vertical: bool in [false, true]:
		var tile := Vector2i(Tuning.STREET_WIDTH + 3, Tuning.STREET_WIDTH / 2) if vertical \
				else Vector2i(Tuning.STREET_WIDTH / 2, Tuning.STREET_WIDTH + 3)
		var instance := EventInstance.new()
		instance.setup(crash, map.tile_to_world(tile), PackedVector2Array(), Vector2.RIGHT,
				EventSurroundings.new().on(map) \
					.drawn_from(atlas))
		t.add_child(instance)
		instance.set_process(false)
		var bodies := DebugLayers.collision_nodes_under(instance)
		t.check(bodies.size() == 2,
				"on a %s street the crash registers one collision shape per car (%d)"
				% ["east-west" if vertical else "north-south", bodies.size()])
		instance.free()
	atlas.release(EventPictures.ATLAS_GROUP)

# ------------------------------------------------------------------- the meter ---

## What a live event charges as it moves through its phases, driven through real seconds by hand
## with no scheduler or city underneath it: the telegraph's damping, a field's bound, and the two states
## every instance owes regardless of kind (it finishes and it leaves rather than vanishing).

func _emission_instance(t: TestRunner, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array(), where: WhereSheIs = null) -> EventInstance:
	var instance := EventInstance.new()
	var surroundings := EventSurroundings.new()
	if where != null:
		surroundings.hearing(where)
	instance.setup(def, at, path, Vector2.RIGHT, surroundings)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _emission_advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / EMISSION_STEP)):
		instance.step(EMISSION_STEP)


func _test_telegraph_damps_emission(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var instance := _emission_instance(t, def)

	t.check(instance.is_telegraphing(), "an event starts in its telegraph phase")
	t.close_to(instance.current_intensity(), def.peak() * EventInstance.TELEGRAPH_INTENSITY_FRACTION,
			"a telegraphing event emits only a fraction of its intensity")
	t.close_to(instance.source().contribution_at(Vector2(1000.0, 0.0)), 0.0,
			"an event contributes nothing beyond its outer radius")

	_emission_advance(instance, def.telegraphs_for() + 0.05)
	t.check(not instance.is_telegraphing(), "the telegraph phase ends after telegraphs_for()")
	t.close_to(instance.current_intensity(), def.peak(),
			"an active event emits its full intensity", 0.05)
	t.close_to(instance.source().contribution_at(Vector2(def.core_within() * 0.5, 0.0)), def.peak(),
			"inside the inner radius the full intensity applies", 0.05)
	instance.free()

## **The phase damps both parts of a two-part field by the same fraction**: a quarter of a beat has to be
## a quarter of *both* parts, or a leaf blower between bursts is a full wall inside a quiet field.
## Stated as the fraction the phase put on the row's own peak, so it holds wherever in the telegraph
## and the pulse envelope this instance happens to be standing.
func _test_a_phase_damps_both_parts_of_a_two_part_field(t: TestRunner) -> void:
	var leaf := EventCatalogue.by_id("leaf_blower")
	var blower := _emission_instance(t, leaf)
	var near := Vector2(32.0, 0.0)
	t.check(blower.is_telegraphing(), "an instance starts in its telegraph")
	var fraction := blower.current_intensity() / leaf.peak()
	t.check(fraction < 1.0, "and is emitting less than its catalogued peak while it does")
	t.close_to(blower.source().contribution_at(near), leaf.field().core_rate() * fraction,
			"the phase damps the core by exactly the fraction it damps the field by")
	blower.free()

## **A live protest swells over its life.** Its ramp runs on the time since it noticed her, not on
## how old the event is, so this steps a real event: the peak it charges over one pulse right after its
## telegraph, against the same pulse three quarters of the way through its life, and never past the
## ceiling its row states. The row's own half of the swell (the peak it carries at each age) is
## `tests/test_acts.gd`'s.
func _test_a_live_protest_swells_over_its_life(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("protest")
	var instance := _emission_instance(t, def)
	_emission_advance(instance, def.telegraphs_for() + 0.05)

	# Sample across whole pulse periods so the ramp, not the pulse, is what is compared.
	var early := _emission_peak_over(instance, def.pulses_every())
	_emission_advance(instance, def.lasts_for() * 0.75)
	var late := _emission_peak_over(instance, def.pulses_every())
	t.check(late > early * 1.3, "a live protest is markedly worse later than when you saw it")
	t.check(late <= def.peak_through(0.0, def.lasts_for(), 1.0) + 0.01,
			"and a live one never exceeds its stated ceiling")
	instance.free()

## The highest intensity `instance` charges over the next `seconds`, stepped through.
func _emission_peak_over(instance: EventInstance, seconds: float) -> float:
	var peak := 0.0
	for i in int(round(seconds / EMISSION_STEP)):
		instance.step(EMISSION_STEP)
		peak = maxf(peak, instance.current_intensity())
	return peak

## M174 item 3: PLAYTEST-115 overturned the walk-beside target above (standing still at
## inner radius) for **the pass** — she and the row moving different directions, at the fixed
## lateral offsets an ordinary sidewalk actually allows. *(PLAYTEST-115: "what matters for the
## dogs is walking past them. and it shouldn't be free"; "walking past ... is what matters. in my
## playthrough I walked next to him without effect".)* `M174Pass.pass_net_averaged()` —
## `tests/probes/m174_pass.gd`'s own simulation, shared rather than duplicated here — walks a real
## `EventInstance` past her, moving as the row actually moves, averaged over its own pulse.
##
## **A relationship, not a pinned value.** What must never quietly go false is that a pass costs
## something awake at an offset a sidewalk allows — not the exact figure, which the probe prints
## and `docs/EVENTS.md` records, and which moves as the catalogue is rebalanced. `dog_walker` does
## not fully restore its pre-M117 pass without crossing `EventScheduler.WALL_WORTH_OF_COST` — see that
## row's own docstring — so this asserts only what these rows actually clear, not a target the
## `WALL` line refuses one of them.
##
## **The two rows she walks up to.** Both are `MAP` placements made at dawn, so the rig starts
## their pass after the telegraph because that is when she meets them. A row `EventDirector` sites
## down her own line is met inside its telegraph instead and is a different claim, made where its
## own siting is decided rather than folded in here.
func _test_the_rows_she_walks_up_to_pass_positively_awake(t: TestRunner) -> void:
	for id: String in ["homeless_yeller", "dog_walker"]:
		var def := EventCatalogue.by_id(id)
		for offset: float in [0.0, 20.0, 40.0]:
			var net := M174Pass.pass_net_averaged(def, offset, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
			t.check(net > 0.0,
					"%s: a pass at %.0fpx of an ordinary sidewalk nets %.2f/s awake, above zero"
					% [id, offset, net])

## **The loose dog stays above the dog walker**, which is the relation the player asked to be kept.
## *(2026-09-20: "unleashed dog still has too little influence -- needs to be more intense"; "but
## keep things in relation to each other".)* A dog running loose at 132px/s costs more to be passed
## by than a leashed one costs to walk past. Both figures come off `M174Pass`, the same simulation
## `docs/COSTS.md` prints, so the two can never disagree about what a pass is.
##
## That the loose dog meets her at that intensity at all — created with its warning over rather than
## still telegraphing at `EventInstance.TELEGRAPH_INTENSITY_FRACTION` — is asked of the game's own warning
## and creation, on a real city: `tests/test_event_manager.gd`,
## `_test_a_row_warned_down_her_line_arrives_at_its_own_intensity`.
func _test_the_loose_dog_costs_more_to_pass_than_the_dog_walker(t: TestRunner) -> void:
	var dog := EventCatalogue.by_id("loose_dog")
	var walker := EventCatalogue.by_id("dog_walker")
	for offset: float in [0.0, 20.0, 40.0]:
		var loose := M174Pass.pass_net_averaged(dog, offset, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
		var leashed := M174Pass.pass_net_averaged(walker, offset, Tuning.EXCITEMENT_DECAY_WALKING,
				1.0)
		t.check(loose > leashed,
				("a loose dog's pass at %.0fpx costs %.2f awake, above the %.2f a dog walker's "
				+ "does") % [offset, loose, leashed])

func _test_duration_and_finish(t: TestRunner) -> void:
	# An event that was a *place* is simply over. Nothing to leave, and nowhere to go.
	var def := EventCatalogue.by_id("abduction")
	t.check(def.departure_speed() <= 0.0, "the van that was parked there does not drive off")
	var instance := _emission_instance(t, def)
	_emission_advance(instance, def.telegraphs_for() + def.lasts_for() + 0.1)
	t.check(instance.is_gone(), "an event with a duration finishes")
	t.close_to(instance.source().contribution_at(Vector2.ZERO), 0.0,
			"a finished event contributes nothing")
	instance.free()

## **Nothing vanishes while you are looking at it.** *(M35, playtest 08 findings 2 and 3: "running
## dog events etc — things that move disappear on screen; they should at least run offscreen before
## despawning", and "pigeons are also completely ineffective", which is the same sentence about a
## flock that hangs in the air and then is not there.)*
##
## Three separate claims, and the middle one is the one that could have gone wrong quietly: an event
## on its way out is **over**. It emits nothing, it cannot end the day, and it carries no cue — or a
## cat that has finished its run would trail its whole field behind it for as long as it took to get
## off screen, which is a worse bug than the one being fixed.
func _test_an_event_leaves_rather_than_vanishing(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	t.check(def.departure_speed() > 0.0, "a flock has somewhere to go")
	var instance_where := WhereSheIs.nowhere()
	var instance := _emission_instance(t, def, Vector2.ZERO, PackedVector2Array(), instance_where)
	instance_where.tell(Vector2(60.0, 0.0))
	_emission_advance(instance, def.telegraphs_for() + def.lasts_for() + 0.1)
	t.check(not instance.is_gone(), "a flock that is done is not deleted where it stands")
	t.check(instance.is_on_its_way_out(), "it is leaving")
	t.close_to(instance.source().contribution_at(instance_where.at()), 0.0,
			"and it stops emitting the moment it does")

	# Away from her, since a flock has no route to carry on along.
	_emission_advance(instance, 0.5)
	t.check(instance.global_position.distance_to(instance_where.at()) > 60.0,
			"it goes away from her rather than in any direction it likes")
	_emission_advance(instance, Tuning.OUT_OF_SIGHT / def.departure_speed())
	t.check(instance.is_gone(), "and it is gone once it is out of sight")
	instance.free()

	# The backstop, for a rig or a streamed-out day where there is nobody to be out of sight of. One
	# frame with her standing in it is what starts the flock's own clock — it waits until it notices
	# her — and she is gone again for the whole of the rest of it.
	var alone_where := WhereSheIs.nowhere()
	var alone := _emission_instance(t, def, Vector2.ZERO, PackedVector2Array(), alone_where)
	alone_where.tell(Vector2.ZERO)
	alone.step(EMISSION_STEP)
	alone_where.tell(Vector2.INF)
	_emission_advance(alone, def.telegraphs_for() + def.lasts_for() + EventDeparture.LEAVING_GIVES_UP + 0.2)
	t.check(alone.is_gone(), "with nobody watching it leaves on a timer rather than for ever")
	alone.free()

## `EventExcitement`'s present rate answers zero for a point past `EventDef.silent_beyond()`
## without working the field out, so for every row in the catalogue the field itself has to be
## zero there: at every bearing, standing or at a speed past the most a field stretches, with the
## body lying either way, and at a peak no row carries. A row that adds a radius to its field and
## not to `silent_beyond()` fails here rather than going quiet a tile early. Flocks are left out,
## since a flock's birds are not at its node and the instance does not ask it of them.
func _test_no_field_reaches_past_silent_beyond(t: TestRunner) -> void:
	var heard_inside := 0
	var heard_past := 0
	var rows := 0
	for def: EventDef in EventCatalogue.all():
		if def.is_a_flock():
			continue
		rows += 1
		var peak := maxf(maxf(def.peak(), def.field().core_rate()), 1.0) * 2.0
		var past := def.silent_beyond() + 0.01
		for facing: Vector2 in [Vector2.RIGHT, Vector2(1.0, 1.0).normalized()]:
			var instance := EventInstance.new()
			instance.setup(def, Vector2.ZERO, PackedVector2Array(), facing)
			for heading in 8:
				var moving := Vector2.RIGHT.rotated(heading * TAU / 8.0) * 10000.0
				for velocity: Vector2 in [Vector2.ZERO, moving]:
					if instance.field_at(Vector2.ZERO, peak, velocity) > 0.0:
						heard_inside += 1
					for bearing in 24:
						var at := Vector2.RIGHT.rotated(bearing * TAU / 24.0) * past
						if instance.field_at(at, peak, velocity) != 0.0:
							heard_past += 1
			instance.free()
	t.check(rows > 0 and heard_inside > 0,
			"the sweep asked %d rows and heard them at their node" % rows)
	t.check(heard_past == 0,
			"no row's field reaches past its silent_beyond() (%d samples did)" % heard_past)

## The other half of the bound: `contribution_at()` itself, with its early-out, answers exactly what
## the field answers (`_field_at()`, nothing skipped; no wall grid, so no wall either) inside and
## just past `silent_beyond()`, for every non-flock row and for two made-up bodies long and wide
## enough that only the body's own reach in the bound keeps their far end heard. The node stands
## off the origin, so a bound measured from anywhere but the node the field is centred on fails.
func _test_contribution_skips_only_silence(t: TestRunner) -> void:
	var rows: Array[EventDef] = []
	for def: EventDef in EventCatalogue.all():
		if def.flock().count() <= 0:
			rows.append(def)
	for shape: GroundShape in [GroundShape.segment(500.0, 10.0),
			GroundShape.rect(Vector2(400.0, 300.0))]:
		var long_body := EventCatalogue.by_id("scaffolding").redraft()
		long_body.field(FieldSpec.of(10.0, 20.0, 60.0))
		long_body.body(BodySpec.solid(shape))
		rows.append(long_body.build())
	var node := Vector2(300.0, -200.0)
	var differed := 0
	var heard := 0
	var heard_by_its_body := 0
	for def in rows:
		var bodyless := (maxf(def.core_within(), def.heard_within()) + 1.0) \
				/ (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
		var instance := EventInstance.new()
		instance.setup(def, node, PackedVector2Array(), Vector2.RIGHT)
		var reach := def.silent_beyond()
		for bearing in 24:
			var direction := Vector2.RIGHT.rotated(bearing * TAU / 24.0)
			for share: float in [0.0, 0.3, 0.6, 0.8, 0.85, 0.9, 0.999, 1.001, 1.5]:
				var at := node + direction * reach * share
				for velocity: Vector2 in [Vector2.INF, direction * -10000.0,
						direction * 10000.0]:
					var field := instance.field_at(at, -1.0, velocity)
					if instance.field_at(at, -1.0, velocity) != field:
						differed += 1
					if field > 0.0:
						heard += 1
						if reach * share > bodyless:
							heard_by_its_body += 1
		instance.free()
	t.check(heard > 0 and heard_by_its_body > 0,
			"the parity hears rows (%d samples), some only through their body's reach (%d)"
			% [heard, heard_by_its_body])
	t.check(differed == 0,
			"contribution_at() answers what the field answers, skip or no skip (%d differed)"
			% differed)

## A flock's birds charge from away from the instance's node, so `contribution_at()` does not skip
## them by the node's distance: a bird put far past `silent_beyond()` is still heard where it is.
## (A roadblock's band, which a guard walking away leaves behind, has no field to hear.)
func _test_flocks_are_not_skipped(t: TestRunner) -> void:
	var flock := EventInstance.new()
	flock.setup(EventCatalogue.by_id("pigeon_flock"), Vector2.ZERO)
	flock.behaviours().flock().build()
	var far_bird := Vector2(flock.row().silent_beyond() * 3.0, 0.0)
	flock.birds()[0].place(far_bird)
	t.check(flock.source().contribution_at(far_bird) > 0.0,
			"a bird far past its flock's silent_beyond() is still heard where it is")
	flock.free()

## Alley mouths have no corridor band for an instance to read its spread's axis off. Their own
## rectangle supplies the axis instead: a horizontal alley is sealed by a vertical spread across
## its short side, while a vertical alley keeps the default horizontal spread. A roadworks
## barrier set up in a horizontal and a vertical alley of a generated map says which way it
## runs.
func _test_roadwork_barrier_follows_alley_axis(t: TestRunner) -> void:
	var map := CityGenerator.generate(4242)
	var horizontal := Rect2i()
	var vertical := Rect2i()
	for rect: Rect2i in map.alley_lots():
		# An alley the generator made solid has no ground to stand on (see `SealPlanner`).
		if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
			continue
		if rect.size.x > rect.size.y and not horizontal.has_area():
			horizontal = rect
		elif rect.size.y > rect.size.x and not vertical.has_area():
			vertical = rect
	t.check(horizontal.has_area() and vertical.has_area(),
			"the generated map has a horizontal and a vertical alley to put a barrier in")
	if not (horizontal.has_area() and vertical.has_area()):
		return
	var barrier := EventCatalogue.by_id("construction")
	var across_a_horizontal := EventInstance.new()
	across_a_horizontal.setup(barrier,
			map.tile_to_world(horizontal.position + horizontal.size / 2), PackedVector2Array(),
			Vector2.RIGHT,
			EventSurroundings.new().on(map))
	t.check(across_a_horizontal.runs_vertically(),
			"a horizontal alley gets a vertical barrier spread across its mouth")
	across_a_horizontal.free()
	var across_a_vertical := EventInstance.new()
	across_a_vertical.setup(barrier, map.tile_to_world(vertical.position + vertical.size / 2),
			PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().on(map))
	t.check(not across_a_vertical.runs_vertically(),
			"a vertical alley keeps a horizontal barrier spread across its mouth")
	across_a_vertical.free()

# ----------------------------------------------------------------- behind a wall ---

## A `width`×`height` map of sidewalk with the given tiles built on.
func _walled_map(buildings: Array[Vector2i], width := 12, height := 12) -> CityMap:
	var map := CityMap.new(Vector2i(width, height))
	map.fill_rect(Rect2i(0, 0, width, height), GameEnums.TileType.SIDEWALK)
	for tile in buildings:
		map.set_tile(tile, GameEnums.TileType.BUILDING)
	return map

func _wall_columns(first: int, count: int, height: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in height:
		for x in range(first, first + count):
			found.append(Vector2i(x, y))
	return found

## A row's instance standing at `at` past its telegraph, asking `map` about the ground — handed to
## `setup()` as the spawner hands it the world's, so both copies stand exactly where they were put.
func _musician(def: EventDef, at: Vector2, map: CityMap) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().on(map))
	instance.restore(EventSave.aged(def.telegraphs_for() + 1.0))
	return instance

## A street musician with a building between them: nothing on the meter's sum, while the same
## musician on open ground reaches her. The wall's own geometry is `test_wall_shield.gd`'s.
func _test_an_event_is_silent_behind_a_wall(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("busker")
	var her := Vector2(240.0, 176.0)
	var at := Vector2(112.0, 176.0)
	var walled := _walled_map(_wall_columns(5, 2, 12))
	var open := _walled_map([])
	var behind := _musician(def, at, walled)
	var beside := _musician(def, at, open)
	t.check(beside.source().contribution_at(her) > 0.0,
			"on open ground the musician's field reaches her (%.2f/s)" % beside.source().contribution_at(her))
	t.check(behind.source().contribution_at(her) == 0.0,
			"with a building between them it does not")
	t.check(behind.field_at(her, -1.0, Vector2.INF) == beside.source().contribution_at(her),
			"the field itself is unchanged; only what reaches her is")
	behind.free()
	beside.free()

## The caret projects the event forward and asks the wall where it will be, not at the translated
## point: her walking down a street with a long building between her and a musician expects nothing
## from him, and the same walk in the open does.
func _test_an_event_expects_nothing_from_behind_a_wall(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("busker")
	var walled := _walled_map(_wall_columns_across(4, 2, 24), 24, 12)
	var open := _walled_map([], 24, 12)
	var at := Vector2(400.0, 80.0)
	var her := Vector2(240.0, 208.0)
	var walk := Vector2(Tuning.WALK_SPEED, 0.0)
	for map: CityMap in [walled, open]:
		var musician := _musician(def, at, map)
		musician.source().set_her_motion(walk)
		var expected := musician.source().expected_gross_at(her)
		if map == walled:
			t.check(expected == 0.0, "walking past behind a building expects nothing (%.2f)"
					% expected)
		else:
			t.check(expected > 0.0, "the same walk in the open expects something (%.2f)"
					% expected)
		musician.free()

func _wall_columns_across(first_row: int, rows: int, width: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(first_row, first_row + rows):
		for x in width:
			found.append(Vector2i(x, y))
	return found
