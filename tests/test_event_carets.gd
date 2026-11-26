extends RefCounted
## The danger mark a live event carries on itself: the caret above it (`EventInstance`'s own
## drawing, asked of the recording drawer it is handed), and what decides it, the net the event's
## source projects for her (`expected_impact_at()`, `will_be_lethal()`) over the same field the
## present rate is. Which things get a mark and which do not: a stationary thing she stands in is
## unmarked, walking toward one earns a caret, the caret follows the pulse and agrees with the halo
## past its horizon, two sources share the decay the way the halo does, a cat dashing at her is
## unmarked, a cyclist or a thing telegraphing on course is the doubled red and one passing wide is
## not, the mark still breathes, and a figure drawn as layers of its own carries it over them. The danger vocabulary's other half (the crowd's marks, the cue
## over the player, the screen edge and the pram) is `test_danger.gd`'s.
##
## Each event is a real `EventInstance` of its row, set up with no manager and no map and handed a
## recording drawer before `setup()`, as the spawner hands the real one: the mark is the event's own
## drawing and projection, so a stand-in would answer nothing.

const DrawnEvent := preload("res://tests/drawn_event.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")

const STEP := 1.0 / 60.0

## The events' atlas page, held for the suite: an event in the tree is drawn on real frames, and the
## game hands each the library it draws from.
var _atlas := AtlasLibrary.new()

func run(t: TestRunner) -> void:
	_atlas.acquire(&"events")
	await _test_a_stationary_thing_she_stands_in_is_unmarked(t)
	_test_walking_toward_a_stationary_thing_earns_a_caret(t)
	_test_the_caret_matches_the_halo_after_the_horizon(t)
	_test_the_caret_follows_a_pulse_across_its_horizon(t)
	_test_two_sources_share_the_decay_the_way_the_halo_does(t)
	await _test_a_cat_dashing_at_her_is_unmarked(t)
	await _test_a_cyclist_on_course_is_red_one_passing_wide_is_not(t)
	await _test_a_telegraphing_lethal_thing_on_course_is_still_red(t)
	await _test_the_mark_still_breathes(t)
	await _test_a_figure_in_parts_carries_its_caret_over_them(t)
	_atlas.release(&"events")

# ------------------------------------------------------------------- the mark ---

## **Both held still, a stationary thing earns no caret** — neither its own field nor her own
## motion changes under the projection, which is the halo's job to report from the moment she is
## in reach at all. A source never told her motion (`set_her_motion()`) has her held still, so the
## test, which tells it none, is exactly this case. See `_test_walking_toward_a_stationary_thing_earns_a_
## caret` for the one PLAYTEST-115 overturned: the same café, her walking toward it.
func _test_a_stationary_thing_she_stands_in_is_unmarked(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("cafe_tables")
	t.check(def != null and not def.moves(), "cafe_tables is a stationary row")
	if not def:
		return
	var where := WhereSheIs.nowhere()
	var instance := _instance(def, PackedVector2Array(), where)
	where.tell(instance.global_position)
	t.check((await _carets(t, instance)).is_empty(),
			"a café she is standing in front of carries no caret at all")
	instance.free()

## *(2026-09-20, overturning 2026-09-08's "I don't want a caret when walking into a car from the
## side": "caret communicates anticipated net gain. basically if I keep doing what I'm doing I
## very likely get that amount in net gain".)* The same stationary café as the test above, her
## position no longer held fixed: walking straight at it from outside its own field, at
## `Tuning.WALK_SPEED` and no decay given back, the projection now nets something, because in five
## seconds of carrying on she really is about to be inside it.
func _test_walking_toward_a_stationary_thing_earns_a_caret(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("cafe_tables")
	if not def:
		return
	var instance := _instance(def)
	var approach := Vector2(-def.heard_within() - 30.0, 0.0)
	instance.source().set_her_motion(Vector2(Tuning.WALK_SPEED, 0.0), 0.0, 1.0)
	t.check(instance.source().expected_impact_at(approach) > 0.0,
			"walking straight at a stationary café five seconds out nets something, unlike " +
			"standing in front of it")
	instance.free()

## The test of done PLAYTEST-115 states directly: *"if I keep doing what I'm doing I very likely
## get that amount in net gain (so the halo will match roughly the caret if that happens)".* A
## single stationary, unpulsed source — no telegraph and no pulse to keep the comparison to the
## one thing under test, since the caret's own projection freezes the row's rate at the moment it
## is asked and a live pulse or telegraph evolving underneath the walk is a second variable this
## test does not want — a straight pass at a constant `Tuning.WALK_SPEED` for the whole horizon,
## exactly what the projection assumes. The halo's own backward-looking `ExcitementSource.net_landed()`,
## read after the horizon has actually elapsed, comes out close to what `expected_impact_at()`
## said at the start of it. `total_landed` is `landed` itself: one source, so its whole share of
## the decay is its own, the same simplification `expected_impact_at()`'s own doc names.
func _test_the_caret_matches_the_halo_after_the_horizon(t: TestRunner) -> void:
	var draft := EventDraft.new("caret_matches_halo")
	draft.field(FieldSpec.of(30.0, 40.0, 200.0))
	draft.warning(WarningSpec.lasting(0.0))
	var def := draft.build()
	var instance := _instance(def)
	var player_velocity := Vector2(Tuning.WALK_SPEED, 0.0)
	var decay := Tuning.EXCITEMENT_DECAY_WALKING
	var lead := player_velocity.length() * Tuning.EXPECTED_IMPACT_HORIZON * 0.5
	var player_pos := Vector2(-lead, 20.0)
	instance.source().set_her_motion(player_velocity, decay, 1.0)
	var caret_now := instance.source().expected_impact_at(player_pos)
	t.check(caret_now > 0.0, "a pass through the field projects a positive net gain")

	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / STEP))
	for i in steps:
		instance.step(STEP)
		player_pos += player_velocity * STEP
		var contribution := instance.source().contribution_at(player_pos)
		if contribution > 0.0:
			instance.source().accumulate_landed(contribution * STEP)
	var landed := instance.source().landed()
	var halo_net := ExcitementSource.net_landed(landed, landed, decay * Tuning.EXPECTED_IMPACT_HORIZON)
	t.close_to(halo_net, caret_now,
			"the halo's net after the horizon matches what the caret projected at the start of " +
			"it, within a few points of a hundred-point bar", 3.0)
	instance.free()

## The two faults `TODO.md`'s "the caret follows a pulse across its horizon" opened against:
## `homeless_yeller`'s pulse (5s) and `busker`'s (7s) both turn over inside
## `Tuning.EXPECTED_IMPACT_HORIZON` (5s), so freezing "as it stands now" for the whole projection
## could read anywhere from a quarter to the full peak of the beat depending on which instant the
## caret happens to be asked on. `EventInstance._pulse_mean_multiplier()` projects the envelope's
## own mean over the horizon instead, from this instant's own phase.
##
## **One starting phase is the wrong thing to check the mean against.** A single pass's own real
## outcome is dominated by whichever beat happens to land on its *closest approach* — walked by
## hand across a whole period, `homeless_yeller`'s own net after the horizon ranges from about 3 to
## about 20 points depending only on where in the beat she happens to start, because the field's
## own falloff weights the moment closest to her far more than the moments either side of it. The
## projected mean was never a promise about that one instant; it is a promise about what the
## *average* pass nets, which is the only thing "if I keep doing what I'm doing" can honestly mean
## for a rate that will not sit still. So this checks four passes, their starting phases spread
## evenly across one whole period, against the average of what each actually landed — the
## correlation between beat and closest approach cancels over a full period and what is left is the
## mean the projection is actually for.
##
## **`homeless_yeller`'s own pulse period equals the horizon exactly**, so a cosine integrated over
## any whole number of its own periods is zero however it is entered — every one of the four phases
## projects the identical flat mean (`0.625` of the field's peak, `def.peak()`), checked directly rather than only
## through its own later average. `busker`'s 7s pulse against the same 5s horizon does not share
## that coincidence, so its four phases are expected to differ from each other.
func _test_the_caret_follows_a_pulse_across_its_horizon(t: TestRunner) -> void:
	var horizon := Tuning.EXPECTED_IMPACT_HORIZON
	var phases := 4
	for id: String in ["homeless_yeller", "busker"]:
		var def: EventDef = EventCatalogue.shipped().by_id(id)
		t.check(def != null and def.pulses_every() > 0.0, "%s pulses" % id)
		if not def:
			continue
		var carets: Array[float] = []
		var reals: Array[float] = []
		for phase_i in phases:
			var start_age := def.pulses_every() * float(phase_i) / float(phases)
			var instance := _instance(def)
			# Past the row's own telegraph first — `_caret_intensity_over_horizon()` already reads
			# the live, undamped rate through the telegraph (`_test_a_cyclist_on_course_is_red_one_
			# passing_wide_is_not` holds that promise elsewhere), but the real walk below has no
			# such exemption: catching a still-telegraphing row for real genuinely nets 15% of it,
			# which is a second variable this test does not want mixed into the pulse comparison.
			_advance(instance, def.telegraphs_for() + start_age)
			var player_velocity := Vector2(Tuning.WALK_SPEED, 0.0)
			var decay := Tuning.EXCITEMENT_DECAY_WALKING
			var lead := player_velocity.length() * horizon * 0.5
			var player_pos := Vector2(-lead, 20.0)
			instance.source().set_her_motion(player_velocity, decay, 1.0)
			var caret_now := instance.source().expected_impact_at(player_pos)
			t.check(caret_now > 0.0,
					"%s at phase %.2fs still projects a positive net gain" % [id, start_age])
			carets.append(caret_now)

			var steps := int(round(horizon / STEP))
			for i in steps:
				instance.step(STEP)
				player_pos += player_velocity * STEP
				var contribution := instance.source().contribution_at(player_pos)
				if contribution > 0.0:
					instance.source().accumulate_landed(contribution * STEP)
			var landed := instance.source().landed()
			reals.append(ExcitementSource.net_landed(landed, landed, decay * horizon))
			instance.free()

		var caret_average := 0.0
		for caret in carets:
			caret_average += caret
		caret_average /= carets.size()
		var real_average := 0.0
		for real in reals:
			real_average += real
		real_average /= reals.size()
		# The unpulsed test's own 3.0 (a single pass, no pulse to average away) plus a point for the
		# residual bias four samples still carry — `busker`'s own average is off by about 1.8 to 2.2
		# points at four to twelve phases, well short of converging to zero, since the falloff's own
		# weighting is not perfectly even across a period.
		var message := ("%s, averaged over four evenly spaced starting phases: the halo after " +
				"the horizon roughly matches the mean-projected caret (caret avg %.2f, halo avg " +
				"%.2f)") % [id, caret_average, real_average]
		t.close_to(real_average, caret_average, message, 4.0)
		if id == "homeless_yeller":
			for caret in carets:
				t.close_to(caret, caret_average,
						"homeless_yeller's pulse period equals the horizon, so every starting " +
						"phase projects the identical mean, whatever beat the caret happened to " +
						"be asked on", 0.1)

## PLAYTEST-115: "with two sources near her every caret reads low" when each nets the whole of her
## decay against itself rather than sharing it the way the halo does. Two identical stationary
## fields straddling her line, both worth a mark on the same pass — no pulse, no telegraph, so the
## only thing under test is the sharing.
##
## **The unshared sum is the regression this replaces.** `expected_impact_at()` with neither
## instance told the frame's total (`set_expected_total_gross()` never called, its `-1.0`
## default) still nets the whole projected decay against each source alone; summing the two
## double-counts the decay the bar can only actually take once, which is exactly the "reads
## low" the player named.
##
## **The shared sum is checked directly against what the two actually land.** `expected_gross_at()`
## gathered over both sources first, told back with `set_expected_total_gross()`, is the same
## once-a-frame shape `ExcitementHalo._process()` runs; summing `ExcitementSource.net_landed()`'s own
## arithmetic across every source reproduces the total gross less the whole decay exactly (its own
## doc proves this for the backward-looking halo), so the sum of the two shared carets is checked
## against `total_landed − decay` after the walk rather than against each source's own halo in
## isolation.
func _test_two_sources_share_the_decay_the_way_the_halo_does(t: TestRunner) -> void:
	var horizon := Tuning.EXPECTED_IMPACT_HORIZON

	var draft_a := EventDraft.new("share_decay_a")
	draft_a.field(FieldSpec.of(30.0, 40.0, 200.0))
	draft_a.warning(WarningSpec.lasting(0.0))
	var def_a := draft_a.build()
	var draft_b := EventDraft.new("share_decay_b")
	draft_b.field(FieldSpec.of(30.0, 40.0, 200.0))
	draft_b.warning(WarningSpec.lasting(0.0))
	var def_b := draft_b.build()

	var a := _instance(def_a)
	a.global_position = Vector2(0.0, 20.0)
	var b := _instance(def_b)
	b.global_position = Vector2(0.0, -20.0)

	var player_velocity := Vector2(Tuning.WALK_SPEED, 0.0)
	var decay := Tuning.EXCITEMENT_DECAY_WALKING
	var lead := player_velocity.length() * horizon * 0.5
	var player_pos := Vector2(-lead, 0.0)
	a.source().set_her_motion(player_velocity, decay, 1.0)
	b.source().set_her_motion(player_velocity, decay, 1.0)

	var solo_sum := a.source().expected_impact_at(player_pos) + b.source().expected_impact_at(player_pos)

	var gross_a := a.source().expected_gross_at(player_pos)
	var gross_b := b.source().expected_gross_at(player_pos)
	var total_gross := gross_a + gross_b
	a.source().set_expected_total_gross(total_gross)
	b.source().set_expected_total_gross(total_gross)
	var shared_sum := a.source().expected_impact_at(player_pos) + b.source().expected_impact_at(player_pos)
	t.check(shared_sum > solo_sum,
			("sharing the decay reads higher in total than each netting the whole of it (%.1f " +
					"solo vs %.1f shared)") % [solo_sum, shared_sum])

	var steps := int(round(horizon / STEP))
	for i in steps:
		a.step(STEP)
		b.step(STEP)
		player_pos += player_velocity * STEP
		var contribution_a := a.source().contribution_at(player_pos)
		if contribution_a > 0.0:
			a.source().accumulate_landed(contribution_a * STEP)
		var contribution_b := b.source().contribution_at(player_pos)
		if contribution_b > 0.0:
			b.source().accumulate_landed(contribution_b * STEP)
	var total_landed := a.source().landed() + b.source().landed()
	var actual_net := maxf(total_landed - decay * horizon, 0.0)
	t.close_to(actual_net, shared_sum,
			"the two shared carets sum to roughly what the bar actually nets from both sources " +
			"over the same horizon, within a few points of a hundred-point bar", 6.0)
	a.free()
	b.free()

## *(2026-09-08, the player, opening the milestone that replaced the old catalogue-wide rule:
## "carets shouldn't be chosen by source value but by expected impact value" — and, confirming the
## consequence of it: "a cat's dash on a standing player lands about 30 and is not marked".)* A cat
## driving straight at a standing player still lands under `Tuning.EXPECTED_IMPACT_POINTS`.
func _test_a_cat_dashing_at_her_is_unmarked(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("cat_dash")
	t.check(def != null, "cat_dash is in the catalogue")
	if not def:
		return
	var where := WhereSheIs.nowhere()
	var instance := _instance(def, PackedVector2Array([Vector2.ZERO, Vector2(1000.0, 0.0)]), where)
	# One frame past the telegraph is enough to turn the crouch into a heading — `cat_dash` is
	# `holds_still()`, so `travel_velocity()` is zero until then.
	_advance(instance, def.telegraphs_for() + STEP)
	where.tell(Vector2(def.heard_within(), 0.0))
	t.check((await _carets(t, instance)).is_empty(),
			"a cat driving straight at a standing player still lands under the line")
	instance.free()

## The doubled caret's own question, on the row the vocabulary keeps the doubling for: a hard-fail
## row on a course that reaches her lethal radius is red, and the same row on a course that misses
## it — however loud its field still reads along the way — carries nothing at all.
func _test_a_cyclist_on_course_is_red_one_passing_wide_is_not(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("cyclist")
	t.check(def != null and def.ends_the_day(), "cyclist is a hard-fail row")
	if not def:
		return
	var route := PackedVector2Array([Vector2.ZERO, Vector2(1000.0, 0.0)])

	# `cyclist` is not `holds_still()`, so it is already riding its route through the
	# whole telegraph — the player is placed relative to wherever it actually is once the
	# telegraph clears rather than at a fixed point its own approach may have already ridden past.
	# (A telegraphing cyclist is its own scenario below — `caret_strength()` no longer needs the
	# telegraph to be over to read red.)
	var on_course_where := WhereSheIs.nowhere()
	var on_course := _instance(def, route, on_course_where)
	_advance(on_course, def.telegraphs_for() + STEP)
	on_course_where.tell(on_course.global_position + Vector2(def.heard_within(), 0.0))
	t.check(_is_the_doubled_red(await _carets(t, on_course)),
			"a cyclist whose line reaches her lethal radius is the doubled red caret")
	on_course.free()

	var wide := _instance(def, route)
	_advance(wide, def.telegraphs_for() + STEP)
	# 60px off its own line, inside the outer radius (90) so its field still reads along the way,
	# but past the inner radius (33) it would have to cross to end the day.
	var her := wide.global_position + Vector2(0.0, 60.0)
	t.check(not wide.source().will_be_lethal(her),
			"the same cyclist passing 60px wide of her own line never reaches her lethal radius")
	wide.free()

## **A telegraph is not an alibi.** `is_lethal_at()` refuses the whole of a telegraph because it
## answers *is this lethal right now*; `will_be_lethal()` answers a different question — is this
## row's own course, once the telegraph clears, one that ends her day — and a lethal row
## riding straight at her through the telegraph has to read red for the whole of it, or the
## doubled caret only ever appears in the fraction of a second the telegraph has left. Three
## scenarios, one for each way a lethal row can be *not yet arrived* and still owe her the mark:
## a mobile row already riding its route, a pursuer that has noticed her and is holding its
## stand-off, and a pursuer that has not noticed anything yet.
func _test_a_telegraphing_lethal_thing_on_course_is_still_red(t: TestRunner) -> void:
	var cyclist_def := EventCatalogue.shipped().by_id("cyclist")
	if cyclist_def:
		# No `_advance()` at all: still inside its own 2.0s telegraph, and already moving —
		# `cyclist` is not `holds_still()`, so `_caret_velocity()` reads its route speed
		# from age zero.
		var cyclist_where := WhereSheIs.nowhere()
		var cyclist := _instance(cyclist_def,
				PackedVector2Array([Vector2.ZERO, Vector2(1000.0, 0.0)]), cyclist_where)
		t.check(cyclist.is_telegraphing(), "the cyclist is still telegraphing at age zero")
		cyclist_where.tell(cyclist.global_position + Vector2(cyclist_def.heard_within(), 0.0))
		t.check(_is_the_doubled_red(await _carets(t, cyclist)),
				"a telegraphing cyclist on a course that reaches her lethal radius is already " +
						"the doubled red caret")
		t.check((await _carets(t, cyclist))[0]["size"].x < EventPictures.MARK_WIDTH,
				"and the swell still reads the telegraph's own damping — the flash, not the " +
						"colour, is what says this has not happened yet")
		cyclist.free()

	var dog_def := EventCatalogue.shipped().by_id("charging_dog")
	if dog_def:
		t.check(dog_def.ends_the_day() and dog_def.pursues() and dog_def.notice_within() <= 0.0,
				"charging_dog is a hard-fail pursuer sited already noticing her")
		var dog_where := WhereSheIs.nowhere()
		var dog := _instance(dog_def, PackedVector2Array(), dog_where)
		t.check(dog.is_telegraphing() and not dog.is_waiting(),
				"the day-3 dog has already noticed her and is still telegraphing its charge")
		dog_where.tell(dog.global_position + Vector2(60.0, 0.0))
		t.check(_is_the_doubled_red(await _carets(t, dog)),
				"a noticed dog holding its stand-off through the telegraph is already the " +
						"doubled red caret")
		dog.free()

	var robber_def := EventCatalogue.shipped().by_id("alley_robbery")
	if robber_def:
		t.check(robber_def.notice_within() > 0.0, "alley_robbery waits for a trigger")
		var robber_where := WhereSheIs.nowhere()
		var robber := _instance(robber_def, PackedVector2Array(), robber_where)
		t.check(robber.is_waiting(), "and nobody has come near it yet")
		robber_where.tell(robber.global_position + Vector2(1000.0, 1000.0))
		t.check((await _carets(t, robber)).is_empty(),
				"a waiting robber in an alley she is not in carries no mark at all")
		robber.free()

## The one property the ring had that a symbol does not get for free. Without it a pulsing event
## stops being something to time a pass through and becomes something that hurts at random.
func _test_the_mark_still_breathes(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("homeless_yeller")
	t.check(def != null and def.pulses_every() > 0.0, "the yeller pulses")
	if not def:
		return
	var where := WhereSheIs.nowhere()
	var instance := _instance(def, PackedVector2Array(), where)
	_advance(instance, def.telegraphs_for() + 0.1)

	var lowest := INF
	var highest := 0.0
	var approach := Vector2(-def.heard_within() - 30.0, 0.0)
	for i in int(round(def.pulses_every() / STEP)):
		instance.step(STEP)
		where.tell(approach)
		instance.source().set_her_motion(Vector2(Tuning.WALK_SPEED, 0.0), 0.0, 1.0)
		var carets := await _carets(t, instance)
		var width: float = carets[0]["size"].x if not carets.is_empty() else 0.0
		lowest = minf(lowest, width)
		highest = maxf(highest, width)
	t.check(highest > lowest * 1.2,
			"the mark has a real swing between beats (%.2f to %.2f px wide)" % [lowest, highest])
	t.check(lowest > 0.0, "and never shrinks to nothing, which would read as flickering")
	t.check(highest <= EventPictures.MARK_WIDTH,
			"and never overstates what the event is emitting")
	instance.free()

## **A figure drawn as layers of its own carries its caret over them** (`FigureLook`): the
## busker's layers are children of his event and are painted after its own canvas, so a caret
## drawn there would be under his head as the chevron shrinks between beats. Walked toward until
## he earns a caret, sited facing east and facing west (the mirrored view): every chevron is drawn
## on a child of the event that comes after his layers in the tree, the order the engine paints
## siblings in, and none on the event's own canvas.
func _test_a_figure_in_parts_carries_its_caret_over_them(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("busker")
	for heading: Vector2 in [Vector2.RIGHT, Vector2.LEFT]:
		var where := WhereSheIs.nowhere()
		var instance := _instance(def, PackedVector2Array(), where, heading)
		_advance(instance, def.telegraphs_for() + 0.1)
		var approach := Vector2(-def.heard_within() - 30.0, 0.0)
		var carets: Array[Dictionary] = []
		for i in int(round(def.pulses_every() / STEP)):
			instance.step(STEP)
			where.tell(approach)
			instance.source().set_her_motion(Vector2(Tuning.WALK_SPEED, 0.0), 0.0, 1.0)
			carets = await _carets(t, instance)
			if not carets.is_empty():
				break
		var parts_at := -1
		for child in instance.get_children():
			if child is EventScenery:
				parts_at = child.get_index()
		t.check(parts_at >= 0 and not carets.is_empty(),
				"the busker facing %s stands as layers and earns a caret walked toward" % heading)
		var over := carets.all(func(entry: Dictionary) -> bool:
				var canvas := entry["canvas"] as Node
				return canvas != instance and canvas.get_parent() == instance \
						and canvas.get_index() > parts_at)
		var on_the_event := DrawnEvent.drawer_of(instance).shown_on(instance) \
				.filter(func(entry: Dictionary) -> bool: return entry["kind"] == &"caret")
		t.check(over and on_the_event.is_empty(),
				"and its caret is drawn over his layers, never under them on the event (%d over, %d under)"
						% [carets.size() if over else 0, on_the_event.size()])
		instance.free()

## The danger carets `instance` asks its drawer for, drawn in a real frame: it is put in the tree,
## asked to redraw, and what the recording drawer it was handed before `setup()` (`_instance()`)
## holds for that draw is read back. One entry for a costly mark, two stacked for a lethal one
## (`colour`, and `size.x` its width), none when no mark is wanted.
func _carets(t: TestRunner, instance: EventInstance) -> Array[Dictionary]:
	var drawer := DrawnEvent.drawer_of(instance)
	if not instance.is_inside_tree():
		t.add_child(instance)
	instance.queue_redraw()
	await t.get_tree().process_frame
	var found: Array[Dictionary] = []
	for entry in drawer.shown():
		if entry["kind"] == &"caret":
			found.append(entry)
	return found

## Whether `carets` are the doubled red: two chevrons, both the lethal colour.
func _is_the_doubled_red(carets: Array[Dictionary]) -> bool:
	return carets.size() == 2 and carets.all(func(each: Dictionary) -> bool:
			return each["colour"] == Palette.MARK_LETHAL)

## `def` live at the origin along `route`, handed a recording drawer before `setup()`, as its
## manager's spawner hands the real one, so `_carets()` reads what its look draws. `where` is the
## word on where she is it hears, which the manager tells in the game: a test that puts her
## somewhere tells it.
func _instance(def: EventDef, route := PackedVector2Array(),
		where: WhereSheIs = null, heading := Vector2.RIGHT) -> EventInstance:
	var instance := EventInstance.new()
	var surroundings := EventSurroundings.new().reading(EventCatalogue.shipped()).drawn_from(_atlas) \
			.drawing_through(DrawnEvent.recording(instance, RecordingEventDrawer.new(_atlas)))
	if where != null:
		surroundings.hearing(where)
	instance.setup(def, Vector2.ZERO, route, heading, surroundings)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance.step(STEP)
