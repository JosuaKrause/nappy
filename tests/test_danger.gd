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
	_test_a_stationary_thing_she_stands_in_is_unmarked(t)
	_test_walking_toward_a_stationary_thing_earns_a_caret(t)
	_test_the_caret_matches_the_halo_after_the_horizon(t)
	_test_the_caret_follows_a_pulse_across_its_horizon(t)
	_test_two_sources_share_the_decay_the_way_the_halo_does(t)
	_test_a_cat_dashing_at_her_is_unmarked(t)
	_test_a_cyclist_on_course_is_red_one_passing_wide_is_not(t)
	_test_a_telegraphing_lethal_thing_on_course_is_still_red(t)
	_test_a_car_on_course_is_red_one_beside_her_line_is_not(t)
	_test_a_walker_brushing_past_is_unmarked(t)
	_test_the_arterial_at_ordinary_density_marks_nobody(t)
	_test_the_mark_still_breathes(t)
	_test_a_warning_cannot_be_cleared_by_somebody_who_cannot_see_it(t)
	_test_only_a_lethal_thing_puts_the_mark_over_her_head(t)
	_test_a_car_sounding_its_horn_carries_its_own_mark(t)
	_test_only_what_she_cannot_outwalk_earns_an_arrow(t)
	_test_a_director_sited_pursuer_earns_an_arrow(t)
	_test_the_screen_edge_is_the_same_size_for_everyone(t)
	_test_the_badge_measures_the_things_own_speed(t)
	_test_the_watch_keeps_a_live_entry_and_drops_a_gone_one(t)
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

## **Both held still, a stationary thing earns no caret** — neither its own field nor her own
## motion changes under the projection, which is the halo's job to report from the moment she is
## in reach at all. `set_player_at()`'s default velocity is `Vector2.ZERO`, so a caller that gives
## no velocity at all is exactly this case. See `_test_walking_toward_a_stationary_thing_earns_a_
## caret` for the one PLAYTEST-115 overturned: the same café, her walking toward it.
func _test_a_stationary_thing_she_stands_in_is_unmarked(t) -> void:
	var def := EventCatalogue.by_id("cafe_tables")
	t.check(def != null and not def.mobile, "cafe_tables is a stationary row")
	if not def:
		return
	var instance := _instance(def)
	instance.set_player_at(instance.global_position)
	t.check(not instance.wants_a_mark(),
			"a café she is standing in front of carries no caret at all")
	instance.free()

## *(2026-09-20, overturning 2026-09-08's "I don't want a caret when walking into a car from the
## side": "caret communicates anticipated net gain. basically if I keep doing what I'm doing I
## very likely get that amount in net gain".)* The same stationary café as the test above, her
## position no longer held fixed: walking straight at it from outside its own field, at
## `Tuning.WALK_SPEED` and no decay given back, the projection now nets something, because in five
## seconds of carrying on she really is about to be inside it.
func _test_walking_toward_a_stationary_thing_earns_a_caret(t) -> void:
	var def := EventCatalogue.by_id("cafe_tables")
	if not def:
		return
	var instance := _instance(def)
	var approach := Vector2(-def.outer_radius - 30.0, 0.0)
	instance.set_player_at(approach, Vector2(Tuning.WALK_SPEED, 0.0), 0.0, 1.0)
	t.check(instance.expected_impact_at(approach) > 0.0,
			"walking straight at a stationary café five seconds out nets something, unlike " +
			"standing in front of it")
	instance.free()

## The test of done PLAYTEST-115 states directly: *"if I keep doing what I'm doing I very likely
## get that amount in net gain (so the halo will match roughly the caret if that happens)".* A
## single stationary, unpulsed source — no telegraph and no pulse to keep the comparison to the
## one thing under test, since the caret's own projection freezes the row's rate at the moment it
## is asked and a live pulse or telegraph evolving underneath the walk is a second variable this
## test does not want — a straight pass at a constant `Tuning.WALK_SPEED` for the whole horizon,
## exactly what the projection assumes. The halo's own backward-looking `ExcitementHalo.net_landed()`,
## read after the horizon has actually elapsed, comes out close to what `expected_impact_at()`
## said at the start of it. `total_landed` is `landed` itself: one source, so its whole share of
## the decay is its own, the same simplification `expected_impact_at()`'s own doc names.
func _test_the_caret_matches_the_halo_after_the_horizon(t) -> void:
	var def := EventDef.new()
	def.id = "caret_matches_halo"
	def.intensity = 30.0
	def.inner_radius = 40.0
	def.outer_radius = 200.0
	def.telegraph_time = 0.0
	var instance := _instance(def)
	var player_velocity := Vector2(Tuning.WALK_SPEED, 0.0)
	var decay := Tuning.EXCITEMENT_DECAY_WALKING
	var lead := player_velocity.length() * Tuning.EXPECTED_IMPACT_HORIZON * 0.5
	var player_pos := Vector2(-lead, 20.0)
	instance.set_player_at(player_pos, player_velocity, decay, 1.0)
	var caret_now := instance.expected_impact_at(player_pos)
	t.check(caret_now > 0.0, "a pass through the field projects a positive net gain")

	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / STEP))
	for i in steps:
		instance._process(STEP)
		player_pos += player_velocity * STEP
		var contribution := instance.contribution_at(player_pos)
		if contribution > 0.0:
			instance.accumulate_landed(contribution * STEP)
	var landed := instance.landed()
	var halo_net := ExcitementHalo.net_landed(landed, landed, decay * Tuning.EXPECTED_IMPACT_HORIZON)
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
## projects the identical flat mean (`0.625` of `def.intensity`), checked directly rather than only
## through its own later average. `busker`'s 7s pulse against the same 5s horizon does not share
## that coincidence, so its four phases are expected to differ from each other.
func _test_the_caret_follows_a_pulse_across_its_horizon(t) -> void:
	var horizon := Tuning.EXPECTED_IMPACT_HORIZON
	var phases := 4
	for id: String in ["homeless_yeller", "busker"]:
		var def: EventDef = EventCatalogue.by_id(id)
		t.check(def != null and def.pulse_period > 0.0, "%s pulses" % id)
		if not def:
			continue
		var carets: Array[float] = []
		var reals: Array[float] = []
		for phase_i in phases:
			var start_age := def.pulse_period * float(phase_i) / float(phases)
			var instance := _instance(def)
			# Past the row's own telegraph first — `_caret_intensity_over_horizon()` already reads
			# the live, undamped rate through the telegraph (`_test_a_cyclist_on_course_is_red_one_
			# passing_wide_is_not` holds that promise elsewhere), but the real walk below has no
			# such exemption: catching a still-telegraphing row for real genuinely nets 15% of it,
			# which is a second variable this test does not want mixed into the pulse comparison.
			_advance(instance, def.telegraph_time + start_age)
			var player_velocity := Vector2(Tuning.WALK_SPEED, 0.0)
			var decay := Tuning.EXCITEMENT_DECAY_WALKING
			var lead := player_velocity.length() * horizon * 0.5
			var player_pos := Vector2(-lead, 20.0)
			instance.set_player_at(player_pos, player_velocity, decay, 1.0)
			var caret_now := instance.expected_impact_at(player_pos)
			t.check(caret_now > 0.0,
					"%s at phase %.2fs still projects a positive net gain" % [id, start_age])
			carets.append(caret_now)

			var steps := int(round(horizon / STEP))
			for i in steps:
				instance._process(STEP)
				player_pos += player_velocity * STEP
				var contribution := instance.contribution_at(player_pos)
				if contribution > 0.0:
					instance.accumulate_landed(contribution * STEP)
			var landed := instance.landed()
			reals.append(ExcitementHalo.net_landed(landed, landed, decay * horizon))
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
## instance told the frame's total (`player_expected_total_gross` at its `-1.0` default) still nets
## the whole projected decay against each source alone; summing the two double-counts the decay the
## bar can only actually take once, which is exactly the "reads low" the player named.
##
## **The shared sum is checked directly against what the two actually land.** `expected_gross_at()`
## gathered over both sources first, told back with `set_expected_total_gross()`, is the same
## once-a-frame shape `ExcitementHalo._process()` runs; summing `ExcitementHalo.net_landed()`'s own
## arithmetic across every source reproduces the total gross less the whole decay exactly (its own
## doc proves this for the backward-looking halo), so the sum of the two shared carets is checked
## against `total_landed − decay` after the walk rather than against each source's own halo in
## isolation.
func _test_two_sources_share_the_decay_the_way_the_halo_does(t) -> void:
	var horizon := Tuning.EXPECTED_IMPACT_HORIZON

	var def_a := EventDef.new()
	def_a.id = "share_decay_a"
	def_a.intensity = 30.0
	def_a.inner_radius = 40.0
	def_a.outer_radius = 200.0
	def_a.telegraph_time = 0.0
	var def_b := EventDef.new()
	def_b.id = "share_decay_b"
	def_b.intensity = 30.0
	def_b.inner_radius = 40.0
	def_b.outer_radius = 200.0
	def_b.telegraph_time = 0.0

	var a := _instance(def_a)
	a.global_position = Vector2(0.0, 20.0)
	var b := _instance(def_b)
	b.global_position = Vector2(0.0, -20.0)

	var player_velocity := Vector2(Tuning.WALK_SPEED, 0.0)
	var decay := Tuning.EXCITEMENT_DECAY_WALKING
	var lead := player_velocity.length() * horizon * 0.5
	var player_pos := Vector2(-lead, 0.0)
	a.set_player_at(player_pos, player_velocity, decay, 1.0)
	b.set_player_at(player_pos, player_velocity, decay, 1.0)

	var solo_sum := a.expected_impact_at(player_pos) + b.expected_impact_at(player_pos)

	var gross_a := a.expected_gross_at(player_pos)
	var gross_b := b.expected_gross_at(player_pos)
	var total_gross := gross_a + gross_b
	a.set_expected_total_gross(total_gross)
	b.set_expected_total_gross(total_gross)
	var shared_sum := a.expected_impact_at(player_pos) + b.expected_impact_at(player_pos)
	t.check(shared_sum > solo_sum,
			("sharing the decay reads higher in total than each netting the whole of it (%.1f " +
					"solo vs %.1f shared)") % [solo_sum, shared_sum])

	var steps := int(round(horizon / STEP))
	for i in steps:
		a._process(STEP)
		b._process(STEP)
		player_pos += player_velocity * STEP
		var contribution_a := a.contribution_at(player_pos)
		if contribution_a > 0.0:
			a.accumulate_landed(contribution_a * STEP)
		var contribution_b := b.contribution_at(player_pos)
		if contribution_b > 0.0:
			b.accumulate_landed(contribution_b * STEP)
	var total_landed := a.landed() + b.landed()
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
func _test_a_cat_dashing_at_her_is_unmarked(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	t.check(def != null, "cat_dash is in the catalogue")
	if not def:
		return
	var instance := _instance(def, PackedVector2Array([Vector2.ZERO, Vector2(1000.0, 0.0)]))
	# One frame past the telegraph is enough to turn the crouch into a heading — `cat_dash` is
	# `still_while_telegraphing`, so `travel_velocity()` is zero until then.
	_advance(instance, def.telegraph_time + STEP)
	instance.set_player_at(Vector2(def.outer_radius, 0.0))
	t.check(not instance.wants_a_mark(),
			"a cat driving straight at a standing player still lands under the line")
	instance.free()

## The doubled caret's own question, on the row the vocabulary keeps the doubling for: a hard-fail
## row on a course that reaches her lethal radius is red, and the same row on a course that misses
## it — however loud its field still reads along the way — carries nothing at all.
func _test_a_cyclist_on_course_is_red_one_passing_wide_is_not(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	t.check(def != null and def.hard_fail, "cyclist is a hard-fail row")
	if not def:
		return
	var route := PackedVector2Array([Vector2.ZERO, Vector2(1000.0, 0.0)])

	# `cyclist` is not `still_while_telegraphing`, so it is already riding its route through the
	# whole telegraph — the player is placed relative to wherever it actually is once the
	# telegraph clears rather than at a fixed point its own approach may have already ridden past.
	# (A telegraphing cyclist is its own scenario below — `_caret_strength()` no longer needs the
	# telegraph to be over to read red.)
	var on_course := _instance(def, route)
	_advance(on_course, def.telegraph_time + STEP)
	on_course.set_player_at(on_course.global_position + Vector2(def.outer_radius, 0.0))
	t.check(on_course.wants_a_mark() and on_course.mark_colour() == Palette.MARK_LETHAL,
			"a cyclist whose line reaches her lethal radius is the doubled red caret")
	on_course.free()

	var wide := _instance(def, route)
	_advance(wide, def.telegraph_time + STEP)
	# 60px off its own line, inside the outer radius (90) so its field still reads along the way,
	# but past the inner radius (33) it would have to cross to end the day.
	wide.set_player_at(wide.global_position + Vector2(0.0, 60.0))
	t.check(not wide.will_be_lethal(wide.player_at),
			"the same cyclist passing 60px wide of her own line never reaches her lethal radius")
	wide.free()

## **A telegraph is not an alibi.** `is_lethal_at()` refuses the whole of a telegraph because it
## answers *is this lethal right now*; `will_be_lethal()` answers a different question — is this
## row's own course, once the telegraph clears, one that ends her day — and a `hard_fail` row
## riding straight at her through the telegraph has to read red for the whole of it, or the
## doubled caret only ever appears in the fraction of a second the telegraph has left. Three
## scenarios, one for each way a lethal row can be *not yet arrived* and still owe her the mark:
## a mobile row already riding its route, a pursuer that has noticed her and is holding its
## stand-off, and a pursuer that has not noticed anything yet.
func _test_a_telegraphing_lethal_thing_on_course_is_still_red(t) -> void:
	var cyclist_def := EventCatalogue.by_id("cyclist")
	if cyclist_def:
		# No `_advance()` at all: still inside its own 2.0s telegraph, and already moving —
		# `cyclist` is not `still_while_telegraphing`, so `_caret_velocity()` reads its route speed
		# from age zero.
		var cyclist := _instance(cyclist_def,
				PackedVector2Array([Vector2.ZERO, Vector2(1000.0, 0.0)]))
		t.check(cyclist.is_telegraphing(), "the cyclist is still telegraphing at age zero")
		cyclist.set_player_at(cyclist.global_position + Vector2(cyclist_def.outer_radius, 0.0))
		t.check(cyclist.wants_a_mark() and cyclist.mark_colour() == Palette.MARK_LETHAL,
				"a telegraphing cyclist on a course that reaches her lethal radius is already " +
						"the doubled red caret")
		t.check(cyclist.mark_swell() < 1.0,
				"and the swell still reads the telegraph's own damping — the flash, not the " +
						"colour, is what says this has not happened yet")
		cyclist.free()

	var dog_def := EventCatalogue.by_id("charging_dog")
	if dog_def:
		t.check(dog_def.hard_fail and dog_def.pursues and dog_def.pursues_within <= 0.0,
				"charging_dog is a hard-fail pursuer sited already noticing her")
		var dog := _instance(dog_def)
		t.check(dog.is_telegraphing() and not dog.is_waiting(),
				"the day-3 dog has already noticed her and is still telegraphing its charge")
		dog.set_player_at(dog.global_position + Vector2(60.0, 0.0))
		t.check(dog.wants_a_mark() and dog.mark_colour() == Palette.MARK_LETHAL,
				"a noticed dog holding its stand-off through the telegraph is already the " +
						"doubled red caret")
		dog.free()

	var robber_def := EventCatalogue.by_id("alley_robbery")
	if robber_def:
		t.check(robber_def.pursues_within > 0.0, "alley_robbery waits for a trigger")
		var robber := _instance(robber_def)
		t.check(robber.is_waiting(), "and nobody has come near it yet")
		robber.set_player_at(robber.global_position + Vector2(1000.0, 1000.0))
		t.check(not robber.wants_a_mark(),
				"a waiting robber in an alley she is not in carries no mark at all")
		robber.free()

## A car's own equivalent, over the strike box `Crowd._strike()` actually collides against rather
## than a def's `inner_radius`.
func _test_a_car_on_course_is_red_one_beside_her_line_is_not(t) -> void:
	var ahead := CrowdAgent.new()
	ahead.kind = CrowdAgent.Kind.CAR
	ahead._speed = 100.0
	ahead.set_player_at(Vector2(60.0, 0.0))
	t.check(ahead.will_be_lethal(ahead.player_at),
			"a car whose strike box reaches the lane she is standing in front of is red")
	ahead.free()

	var beside := CrowdAgent.new()
	beside.kind = CrowdAgent.Kind.CAR
	beside._speed = 100.0
	beside.set_player_at(Vector2(60.0, 50.0))
	t.check(not beside.will_be_lethal(beside.player_at),
			"the same car passing beside her — she would have to step into it herself — is not")
	beside.free()

## `PEDESTRIAN_INTENSITY` (4.2/s) times `Tuning.EXPECTED_IMPACT_HORIZON` (5s) is 21, under
## `Tuning.EXPECTED_IMPACT_POINTS` (40) by construction, so no ordinary walker can ever earn a
## caret on its own field — only a jolt (a bump, a horn) could add enough, and this one carries
## none.
func _test_a_walker_brushing_past_is_unmarked(t) -> void:
	var walker := CrowdAgent.new()
	walker.kind = CrowdAgent.Kind.WALKER
	walker._speed = 60.0
	walker.set_player_at(Vector2(20.0, 25.0))
	t.check(walker._caret_strength() == 0,
			"an ordinary walker brushing past her carries no caret at all")
	walker.free()

## **The line this milestone cannot merge on the wrong side of.** *(2026-09-08, on the one
## measurement rather than an argument: "the answer has to be none at ordinary density, or the
## line moves before this merges".)* A real generated city, a real `Crowd.step()` — "a rig that
## steps the parts is not running the whole" (`.claude/skills/crowd-traffic/SKILL.md`) — at
## ordinary arterial density, for the same forty-second walk `docs/EVENTS.md`'s own cost-table
## measurement uses, with the player standing still on the pavement rather than walking it: not
## one amber caret over the whole of it.
func _test_the_arterial_at_ordinary_density_marks_nobody(t) -> void:
	var city_scene: PackedScene = load("res://scenes/world/city.tscn")
	var city: City = city_scene.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(9137))
	var standing_at := CrowdLanes.arterial_pavement(city.map)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("test_danger:arterial")
	city.crowd.start_day(1, rng, standing_at)

	var amber := 0
	for i in int(round(40.0 / STEP)):
		city.crowd.step(STEP)
		for agent in city.crowd.agents():
			agent.set_player_at(standing_at)
			if agent._caret_strength() == 1:
				amber += 1
	t.check(amber == 0,
			("a crowd at ordinary arterial density around a standing player marks nobody " +
					"(%d amber frames over the walk)") % amber)
	city.free()

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
	t.check("_draw_mark" in methods, "a car draws a mark of its own")
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
	var not_wanted := ["dog_walker", "cafe_tables", "poster_crew", "poster_crew_square", "busker",
			"construction"]

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

## **A pursuer sited off screen has to have something announcing it while it is off screen.**
## `charging_dog` carries `spawn_mode == AHEAD_OF_PLAYER`, the same as the cat's three-second
## crossing that the badge deliberately never announces — but `EventDirector` now sites the dog
## outside the view and lets it close in, so unlike the cat it has an offscreen phase worth
## something to warn about. A row moved further out without the badge following it would have
## *less* warning than the old close siting gave, not more.
func _test_a_director_sited_pursuer_earns_an_arrow(t) -> void:
	var edge := DangerEdge.new()
	var dog := EventCatalogue.by_id("charging_dog")
	t.check(dog != null and dog.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER and dog.pursues,
			"charging_dog is still a director-sited pursuer")
	if dog:
		var instance := _instance(dog)
		t.check(edge._is_worth_an_arrow(instance),
				"the day-3 dog is announced off screen once it is sited there")
		instance.free()

	# And the cat it shares a spawn mode with still is not — the exemption is for a pursuer only,
	# not for the whole spawn mode.
	var cat := EventCatalogue.by_id("cat_dash")
	if cat:
		var instance := _instance(cat)
		t.check(not edge._is_worth_an_arrow(instance),
				"a three-second crossing still has nothing to announce before it arrives")
		instance.free()
	edge.free()

## `MARGIN` and `SCREEN_MARGIN` are screen px, which is only a fair unit if every player's screen
## shows the same slice of world. `"expand"` would let a wide monitor see more city than a laptop
## before the same margin fires, buying it more warning for nothing the player did — `"keep"` holds
## the viewport at a fixed 1280×720 and bars the rest, so this is the setting the badge's whole
## unit of measurement depends on.
func _test_the_screen_edge_is_the_same_size_for_everyone(t) -> void:
	t.check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep",
			"the window letterboxes instead of showing more or less city on a different screen")

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

## `docs/TODO.md`, M124: `_measure()` used to rebuild `_watch` from scratch every frame — a fresh
## outer `Dictionary` plus one per live instance. It now mutates each instance's own entry in place
## and only erases the ids `_events.instances()` stopped carrying, so this holds the two halves of
## that promise: an instance still around keeps its own entry (same object, not a look-alike
## rebuilt fresh), and one that left is actually gone from `_watch` rather than accumulating.
func _test_the_watch_keeps_a_live_entry_and_drops_a_gone_one(t) -> void:
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
	var id := engine.get_instance_id()

	edge._process(STEP)
	t.check(edge._watch.has(id), "a live instance gets an entry in _watch")
	var entry: Dictionary = edge._watch[id]
	edge._process(STEP)
	t.check(edge._watch[id] == entry,
			"the same instance's entry is the same Dictionary object next frame, mutated in " +
			"place rather than torn down and rebuilt")

	manager._instances.erase(engine)
	edge._process(STEP)
	t.check(not edge._watch.has(id),
			"an instance _events.instances() no longer carries is pruned from _watch, not left " +
			"to sit there forever")

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
		t.check(is_equal_approx(rig.baby_cue_lift(),
						Stroller.BABY_CUE_LIFT + Stroller.FIGURE_HEIGHT)
				== (in_column and facing.y > 0.0),
				"facing %v is lifted over her only when the pram is due south of her" % facing)
		rig.warn(Stroller.Alert.SOON, 1.0, &"test")
		t.check(not is_zero_approx(rig.baby_cue_aside()) == in_column,
				"facing %v steps out of the mark's column only when it shares one" % facing)
		rig.stand_down(&"test")
	rig.free()

# ------------------------------------------------------------------- helpers ---

func _instance(def: EventDef, route := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, route)
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
