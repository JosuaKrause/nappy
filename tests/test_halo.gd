extends RefCounted
## `ExcitementHalo`: which live sources earn a place in the halo.
##
## Whether the result *reads* — the colour, the softness, whether a ring picks an entity's own
## silhouette out of a busy corner — is a screenshot's question and is out of this suite on
## purpose, the same line `docs/DECISIONS.md`'s testing policy draws for every other cue: "not
## tested, checked by eye: layout, colour, readability." *(2026-09-07, the player, on this cue
## specifically: "proof for the UI is my playtest don't try to come up with a complicated rig to
## test it. that's wasted effort.")* That is why the size — a ring of offsets around each entity's
## own re-drawn body, in `EntityHalo` — has no test here: there is no arithmetic version of "does
## the rim hug the sprite," only a look.
##
## **What is left is what would rot silently.** The selection, `select_sources()`: a day plans
## several hundred bodies and only a handful may ever earn a halo, or the cue marks everything and
## says nothing. And `landed()`'s sliding sum, because a sign error there is invisible until
## somebody stands next to a cyclist and a protest and cannot tell which one to run from. Neither
## test drives `accumulate_landed()` through `Baby._update_excitement()` — that attribution is a
## question about the meter, and this suite calls `accumulate_landed()` directly to hold `landed()`
## in isolation from it.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_weak_source_is_left_out(t)
	_test_a_source_above_the_floor_is_selected(t)
	_test_it_goes_to_zero_out_of_reach(t)
	_test_a_city_wide_source_is_never_drawn_at_a_point(t)
	_test_the_cap_keeps_the_strongest(t)
	_test_landed_accumulates_and_decays(t)
	_test_colour_for_the_ramp_ends(t)
	_test_magnitude_for_emphasises_low_values(t)
	_test_entity_halo_eases_toward_its_target(t)
	_test_a_startled_car_clears_the_floor_at_its_horn_inner_radius(t)
	_test_an_ordinary_walker_is_a_candidate(t)
	_test_select_sources_takes_a_mixed_candidate_set(t)
	_test_process_picks_the_same_sources_the_linear_scan_did(t)
	_test_event_instance_contribution_is_cached_per_frame_per_position(t)
	_test_finishing_outside_process_invalidates_the_contribution_cache(t)
	_test_a_cat_dash_is_selected_and_lands(t)
	_test_a_flock_is_selected_and_lands(t)
	_test_a_flocks_rim_has_a_new_body_to_trace_every_frame(t)
	_test_the_rims_mirrored_copies_land_on_the_ring(t)

func _def(id: String, intensity: float, inner := 40.0, outer := 150.0) -> EventDef:
	var def := EventDef.new()
	def.id = id
	def.intensity = intensity
	def.inner_radius = inner
	def.outer_radius = outer
	# No telegraph damping to reason about: `is_telegraphing()` is `age < telegraph_time`, and
	# age starts at 0.0, so a zero telegraph is never true.
	def.telegraph_time = 0.0
	return def

func _instance_at(def: EventDef, at: Vector2) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at)
	return instance

## A catalogue row's instance, live in the tree so `_ready()` actually runs — which is what
## builds `_flock` for a flock row and `_halo` for every row, neither of which `_instance_at()`
## above gets, since it never calls `setup()` through a parent. Mirrors `tests/test_events.gd`'s
## own `_instance()` helper, kept local here rather than shared, because the two suites hold
## different halves of this class and neither should have to know the other's rig.
func _rig_instance(t, def: EventDef, at: Vector2) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at)
	t.add_child(instance)
	instance.set_process(false)
	return instance

# ------------------------------------------------------------------- the floor ---

func _test_a_weak_source_is_left_out(t) -> void:
	var weak := _instance_at(_def("weak", 0.5), Vector2.ZERO)
	t.check(ExcitementHalo.select_sources([weak], Vector2.ZERO).is_empty(),
			"a source under CONTRIBUTION_FLOOR at her own position earns no halo")
	weak.free()

func _test_a_source_above_the_floor_is_selected(t) -> void:
	var strong := _instance_at(_def("strong", 10.0), Vector2.ZERO)
	var picked := ExcitementHalo.select_sources([strong], Vector2.ZERO)
	t.check(picked.size() == 1 and picked[0] == strong,
			"a source clearing the floor at her own position is drawn")
	strong.free()

func _test_it_goes_to_zero_out_of_reach(t) -> void:
	var def := _def("reach", 10.0)
	var instance := _instance_at(def, Vector2.ZERO)
	var far := Vector2(def.outer_radius + 1.0, 0.0)
	t.check(ExcitementHalo.select_sources([instance], far).is_empty(),
			"a field she has walked out of contributes nothing, so nothing is drawn for it")
	instance.free()

# -------------------------------------------------------------- city-wide ---

func _test_a_city_wide_source_is_never_drawn_at_a_point(t) -> void:
	var def := _def("loudspeaker", 40.0)
	def.city_wide = true
	var instance := _instance_at(def, Vector2(2000.0, 2000.0))
	# `contribution_at()` answers this one from anywhere in the city — there is no falloff to
	# draw a localised field for, and the vocabulary already has its answer for it (a HUD line).
	t.check(instance.contribution_at(Vector2.ZERO) > ExcitementHalo.CONTRIBUTION_FLOOR,
			"a city-wide source is genuinely above the floor everywhere, which is the point")
	t.check(ExcitementHalo.select_sources([instance], Vector2.ZERO).is_empty(),
			"but it has no position to draw a halo around, so the halo excludes it by kind")
	instance.free()

# ------------------------------------------------------------------- the cap ---

func _test_the_cap_keeps_the_strongest(t) -> void:
	var instances: Array[EventInstance] = []
	var expected_ids: Array[String] = []
	var total := ExcitementHalo.MAX_SOURCES + 3
	for i in total:
		# Distinct, well-spread intensities at the same point (distance 0, so contribution_at
		# is exactly the intensity) — there is no ambiguity about which ones are strongest.
		var intensity := 5.0 * float(total - i)
		var def := _def("source_%d" % i, intensity)
		instances.append(_instance_at(def, Vector2.ZERO))
		if i < ExcitementHalo.MAX_SOURCES:
			expected_ids.append(def.id)

	var picked := ExcitementHalo.select_sources(instances, Vector2.ZERO)
	t.check(picked.size() == ExcitementHalo.MAX_SOURCES,
			"the cap is honoured even when far more sources clear the floor")

	var picked_ids: Array[String] = []
	for instance in picked:
		picked_ids.append(instance.def.id)
	picked_ids.sort()
	expected_ids.sort()
	t.check(picked_ids == expected_ids,
			"past the cap the weakest contributors are dropped, not the newest or the furthest")

	for instance in instances:
		instance.free()

# --------------------------------------------------------------- landed() ---

## Runs the same assertions against any duck-typed source — `EventInstance` and `CrowdAgent` both
## carry the same `accumulate_landed()`/`landed()` shape, so a bug in one and not the other is
## exactly what a single test could miss.
##
## **A true sum, not a decayed average.** *(2026-09-08, the player: "if a honking car caused 35
## excitement to the player that's the number that informs the color of the halo".)* A burst has
## to read as itself for the whole `WINDOW`, not fade from the instant it landed — the opposite of
## what an exponential moving average would give the same call.
##
## **Measured on the source's own simulation clock, `_clock`, not on wall time.** Neither rig is in
## a running tree here (`_instance_at()` never calls `setup()` through a parent, and a bare
## `CrowdAgent.new()` is never added), so nothing is ticking `_process()` — advancing `_clock`
## directly is what stands in for `WINDOW` seconds of simulated time elapsing.
func _check_accumulates_and_decays(t, source, label: String) -> void:
	source.accumulate_landed(35.0)
	t.check(is_equal_approx(source.landed(), 35.0),
			"%s: a burst reads as itself, not decayed from the frame it landed" % label)

	# Wall time passing does nothing on its own -- landed() is measured against the source's own
	# _clock, and nothing has advanced it, so asking again with no _process tick reads the same.
	t.check(is_equal_approx(source.landed(), 35.0),
			("%s: landed() still reads 35 with no _process tick, because the window is " +
					"measured on simulation time, not wall time") % label)

	# Advancing the source's own simulation clock past WINDOW is the same fact as WINDOW seconds
	# of simulated time elapsing, and does not need the test to actually tick _process() or sleep.
	source._clock += ExcitementHalo.WINDOW + 0.1
	t.check(is_equal_approx(source.landed(), 0.0),
			("%s: once WINDOW has fully elapsed on the simulation clock the burst reads as " +
					"~0, not merely faded") % label)

	# A second burst, only partially aged out, has to keep exactly what is still inside the
	# window and drop exactly what is not -- proving the sum is over entries, not a single scalar.
	source.accumulate_landed(10.0)
	source.accumulate_landed(20.0)
	for entry in source._landed_history:
		if is_equal_approx(entry[1], 10.0):
			entry[0] -= ExcitementHalo.WINDOW + 0.1
	t.check(is_equal_approx(source.landed(), 20.0),
			"%s: an aged-out entry drops on its own; a fresh one beside it still counts" % label)

func _test_landed_accumulates_and_decays(t) -> void:
	var instance := _instance_at(_def("landed_event", 10.0), Vector2.ZERO)
	_check_accumulates_and_decays(t, instance, "EventInstance")
	instance.free()

	var agent := CrowdAgent.new()
	_check_accumulates_and_decays(t, agent, "CrowdAgent")
	agent.free()

# ---------------------------------------------------------------- colour ---

func _test_colour_for_the_ramp_ends(t) -> void:
	t.check(ExcitementHalo.colour_for(0.0).is_equal_approx(Palette.HALO_WEAK),
			"no landed excitement reads as the weak end of the ramp")
	var saturated := Tuning.EXPECTED_IMPACT_POINTS
	t.check(ExcitementHalo.colour_for(saturated).is_equal_approx(Palette.HALO_STRONG),
			"landed excitement at the saturation point reads as the strong end")
	t.check(ExcitementHalo.colour_for(saturated * 10.0).is_equal_approx(Palette.HALO_STRONG),
			"well past saturation stays at the strong end rather than overshooting it")
	var half := ExcitementHalo.colour_for(saturated * 0.5)
	t.check(not half.is_equal_approx(Palette.HALO_WEAK) and not half.is_equal_approx(Palette.HALO_STRONG),
			"halfway to saturation reads as neither end of the ramp")
	t.check(half.is_equal_approx(Palette.HALO_MID),
			"and it is the chosen midpoint exactly, not a desaturated average of the two ends " +
			"(playtest 38: 'no real fade from yellow to red')")

# ---------------------------------------------------------------- brightness ---
# *(2026-09-08, the player, dropping the "how far away" read `alpha_for()` used to give:
# "the transparency shouldn't show distance since distance actually doesn't matter ... this frees
# up transparency for also encoding magnitude. transparency can be used to emphasize low values".)*
# `magnitude_for()` reads `landed()` -- the same number `colour_for()` reads -- on a curve that
# rises fast and saturates by `LOW_EMPHASIS_POINTS`, so transparency does the work at the low end
# that a straight line to `Tuning.EXPECTED_IMPACT_POINTS` would leave flat.

func _test_magnitude_for_emphasises_low_values(t) -> void:
	var floor_alpha := ExcitementHalo.MIN_MAGNITUDE * ExcitementHalo.MAX_ALPHA
	t.check(is_equal_approx(ExcitementHalo.magnitude_for(0.0), floor_alpha),
			"nothing landed yet reads at the floor, not at zero -- a picked source is never " +
			"invisible while it is still earning its first point")
	var one := ExcitementHalo.magnitude_for(1.0)
	var five := ExcitementHalo.magnitude_for(5.0)
	var fifteen := ExcitementHalo.magnitude_for(15.0)
	var forty := ExcitementHalo.magnitude_for(40.0)
	t.check(one > floor_alpha, "one point already reads above the floor -- faint but present")
	t.check(one < five and five < fifteen,
			"the curve rises fast through the low end, which is the whole point of it")
	t.check(is_equal_approx(fifteen, ExcitementHalo.MAX_ALPHA),
			"fifteen points is already solid -- LOW_EMPHASIS_POINTS is where the curve saturates")
	t.check(is_equal_approx(forty, ExcitementHalo.MAX_ALPHA),
			"well past LOW_EMPHASIS_POINTS stays solid rather than overshooting -- colour, not " +
			"transparency, is what carries the difference between fifteen and forty")

# ------------------------------------------------------------------- easing ---
# *(2026-09-08, the player: "fade in and fade out smoothly using transparency ... all changes
# should transition (hue and transparency) instead of immediately showing the actual value".)*
# `EntityHalo` is the natural home for the eased state, since both `EventInstance` and `CrowdAgent`
# already own one -- see its class doc.

func _test_entity_halo_eases_toward_its_target(t) -> void:
	var halo := EntityHalo.new(Callable(), Callable())
	var steps_in := int(round(EntityHalo.FADE_IN_SECONDS / STEP))
	halo.set_glow(ExcitementHalo.MAX_ALPHA, Palette.HALO_STRONG)
	for i in steps_in / 2:
		halo._process(STEP)
	t.check(halo._alpha > 0.0 and halo._alpha < ExcitementHalo.MAX_ALPHA,
			"half way through FADE_IN_SECONDS the rim is part way up -- never a jump from nothing " +
			"to the target in one frame")
	for i in steps_in - steps_in / 2:
		halo._process(STEP)
	t.close_to(halo._alpha, ExcitementHalo.MAX_ALPHA,
			"a target held for the whole of FADE_IN_SECONDS is reached", 0.01)
	t.check(halo._colour.is_equal_approx(Palette.HALO_STRONG),
			"colour eases to its own target on the same clock as alpha, not left to jump on its own")
	t.check(halo.has_settled() and halo.is_showing(),
			"a rim holding a steady target is settled *and* drawn — the pair `_process()` still asks "
			+ "for a fresh trace on, because the body under a steady glow moves")

	halo.set_glow(0.0, Palette.HALO_WEAK)
	var steps_out := int(round(EntityHalo.FADE_OUT_SECONDS / STEP))
	for i in steps_out:
		halo._process(STEP)
	t.close_to(halo._alpha, 0.0,
			"told a target of zero and given the whole of FADE_OUT_SECONDS, the rim decays to zero " +
			"rather than being switched off", 0.01)
	t.check(halo.is_faded_out(),
			"is_faded_out() agrees once the fade is actually over, which is what lets CrowdAgent " +
			"free the halo without cutting a fade off mid-way")
	t.check(not halo.is_showing(),
			"and a rim drawing nothing stops asking to be traced, so the per-frame trace is paid "
			+ "for by the handful of sources that are actually lit rather than by every body")
	halo.free()

# ------------------------------------------------------------ the crowd joins ---
# *(2026-09-08, the player: "a busy street is noisy because of cars and a busy sidewalk is noisy
# because of people ... that will allow us to attribute the source exactly".)* The whole crowd is
# a candidate now, not only a startled body -- CONTRIBUTION_FLOOR and MAX_SOURCES are what keep a
# busy pavement legible.

func _test_a_startled_car_clears_the_floor_at_its_horn_inner_radius(t) -> void:
	# CrowdAgent.contribution_at() reads only global_position, kind and the jolt fields -- none of
	# which setup() touches -- so a bare .new() is enough, verified by reading the function rather
	# than assumed.
	var car := CrowdAgent.new()
	car.kind = CrowdAgent.Kind.CAR
	car.startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION,
			Tuning.CAR_HORN_INNER_RADIUS, Tuning.CAR_HORN_OUTER_RADIUS)
	var at_inner_radius := Vector2(Tuning.CAR_HORN_INNER_RADIUS, 0.0)
	t.check(car.contribution_at(at_inner_radius) > ExcitementHalo.CONTRIBUTION_FLOOR,
			"a startled car clears the halo's floor at its own horn's inner radius -- a caret " +
			"means a halo, and this still holds now that every car is a candidate")
	car.free()

func _test_an_ordinary_walker_is_a_candidate(t) -> void:
	# No startle at all -- just the ambient PEDESTRIAN_INTENSITY, which is what "the crowd is the
	# noise, and the noise is attributable" means in arithmetic.
	var walker := CrowdAgent.new()
	walker.kind = CrowdAgent.Kind.WALKER
	var at_inner_radius := Vector2(Tuning.PEDESTRIAN_INNER_RADIUS, 0.0)
	t.check(walker.contribution_at(at_inner_radius) > ExcitementHalo.CONTRIBUTION_FLOOR,
			"an ordinary, unstartled walker clears the floor at its own inner radius")
	var picked := ExcitementHalo.select_sources([walker], at_inner_radius)
	t.check(picked.size() == 1 and picked[0] == walker,
			"and is therefore picked -- the whole crowd is a candidate, not only a caret-worthy body")
	walker.free()

func _test_select_sources_takes_a_mixed_candidate_set(t) -> void:
	var instance := _instance_at(_def("busker", 10.0), Vector2.ZERO)
	var car := CrowdAgent.new()
	car.kind = CrowdAgent.Kind.CAR
	car.position = Vector2(20.0, 0.0)
	car.startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION,
			Tuning.CAR_HORN_INNER_RADIUS, Tuning.CAR_HORN_OUTER_RADIUS)
	var picked := ExcitementHalo.select_sources([instance, car], Vector2.ZERO)
	t.check(picked.size() == 2,
			"select_sources() takes an event and a crowd agent in the same untyped array -- the " +
			"duck type, not a shared base class, is what makes both candidates")
	instance.free()
	car.free()

# --------------------------------------------------------- the per-frame lookup ---
# `docs/TODO.md`, M124: `_process()` used to test `source in picked` -- a linear scan of an Array
# up to `MAX_SOURCES` long, run for every one of ~275 candidates. It now builds a `Dictionary`
# keyed by the picked objects themselves once, and tests membership in that instead. The set of
# who gets a nonzero target and who gets zero must come out exactly the same either way.

func _test_process_picks_the_same_sources_the_linear_scan_did(t) -> void:
	var manager := EventManager.new()
	t.add_child(manager)
	var crowd := Crowd.new()
	t.add_child(crowd)
	var player := Node2D.new()
	t.add_child(player)
	var halo := ExcitementHalo.new()
	t.add_child(halo)
	halo.setup(manager, crowd, player)

	var strong := EventInstance.new()
	strong.setup(_def("strong_halo", 30.0), Vector2.ZERO)
	manager.add_child(strong)
	strong.set_process(false)
	manager._instances.append(strong)
	# Out of reach at her position (400px against a 150px outer radius), so it clears neither the
	# floor nor `select_sources()`'s cap -- the case the old `in` scan and the new lookup both have
	# to answer "no" to.
	var weak := EventInstance.new()
	weak.setup(_def("weak_halo", 20.0), Vector2(400.0, 0.0))
	manager.add_child(weak)
	weak.set_process(false)
	manager._instances.append(weak)

	halo._process(STEP)

	t.check(strong._halo._target_alpha > 0.0,
			"a source above the floor at her position is picked and told a nonzero target")
	t.check(is_zero_approx(weak._halo._target_alpha),
			"a source out of reach is told zero -- the same answer the linear `in` scan gave before " +
			"the picked set became a Dictionary lookup")

	# `manager.free()` frees `strong` and `weak` as its own children, rather than freeing them
	# directly and leaving `manager` to tick a dangling reference in `_instances` next frame.
	manager.free()
	crowd.free()
	player.free()
	halo.free()

# ------------------------------------------------------ contribution_at is cached ---
# `docs/TODO.md`, M124: `Baby._update_excitement()` (physics rate) and
# `ExcitementHalo.select_sources()` (frame rate) both ask every live event for its
# `contribution_at()` at essentially the same point, most frames -- so `EventInstance` caches the
# plain query once per frame, the same `age`-keyed shape `_caret_strength()` already uses. The
# cache must never answer for the *wrong* point or the *wrong* frame: two different positions in
# the same tick still have to answer independently, and a new frame must never hand back last
# frame's number for a source that has since moved.
#
# `CrowdAgent.contribution_at()` deliberately has no such cache -- see that method's own doc for
# why (its position and jolt are written from outside its own `_process()`, by `Crowd`, so a
# `_clock`-keyed cache would miss a fresh bump or startle for the rest of the tick it landed on);
# `tests/test_crowd.gd`'s `_test_walking_into_somebody_displaces_and_startles_them` is the check
# that would have caught it, and did, while this fix was still on `CrowdAgent`.

func _test_event_instance_contribution_is_cached_per_frame_per_position(t) -> void:
	var instance := _instance_at(_def("cached_event", 20.0, 40.0, 150.0), Vector2.ZERO)

	var near := instance.contribution_at(Vector2(10.0, 0.0))
	var far := instance.contribution_at(Vector2(140.0, 0.0))
	t.check(near > far,
			"two different points asked in the same tick both answer for their own position -- the " +
			"cache is keyed on where it was asked, not just on when")

	# A new frame (`age` advances the way `_process()` advances it) with the source moved away: the
	# old position must be recomputed, not answered from a stale cache built for last frame's spot.
	instance.age += 1.0
	instance.global_position = Vector2(5000.0, 5000.0)
	t.check(is_zero_approx(instance.contribution_at(Vector2(10.0, 0.0))),
			"a new frame recomputes rather than serving last frame's cached contribution")
	instance.free()

## The CI failure this guards against, reproduced directly: `EventManager.retire()` and
## `.silence_city_wide()` (the resistance's own masts going quiet on the last walk home) both call
## `_finish()` straight from outside, with no `_process()` tick of the instance's own in between --
## so `age` never moves, and a cache keyed only on `(age, world_position)` went on answering the
## pre-finish contribution for the rest of that tick. `_be_done()`'s `is_leaving = true` branch is
## the other half of the same guard `contribution_at()`'s early return reads, and gets the same
## check.
func _test_finishing_outside_process_invalidates_the_contribution_cache(t) -> void:
	var def := _def("mast", 40.0)
	def.city_wide = true
	var instance := _instance_at(def, Vector2(400.0, 400.0))
	var somewhere := Vector2(9000.0, 9000.0)
	t.check(instance.contribution_at(somewhere) > 0.0,
			"a live city-wide source reaches anywhere in the city, which the cache now holds")

	instance._finish() # the exact call EventManager.retire()/silence_city_wide() makes
	t.close_to(instance.contribution_at(somewhere), 0.0,
			"finishing outside _process() invalidates the cache rather than leaving the pre-" +
			"finish answer standing for the rest of the tick (this is the resistance's masts " +
			"going quiet, tests/test_resistance.gd's own scenario)")
	instance.free()

	# The other flag `contribution_at()`'s early return reads, forced the same way `_be_done()`
	# forces it when a mobile row has somewhere to go.
	var leaving_def := _def("leaving", 40.0, 40.0, 400.0)
	leaving_def.departs_at = 10.0 # departure_speed() > 0, so _be_done() takes the leaving branch
	var leaving := _instance_at(leaving_def, Vector2.ZERO)
	t.check(leaving.contribution_at(Vector2(10.0, 0.0)) > 0.0,
			"a live row reaches a point inside its own field, which the cache now holds")
	leaving._be_done()
	t.check(leaving.is_leaving, "departure_speed > 0 takes the leaving branch, not straight to finished")
	t.close_to(leaving.contribution_at(Vector2(10.0, 0.0)), 0.0,
			"is_leaving flipping outside _process() invalidates the cache the same way finishing does")
	leaving.free()

# ------------------------------------------------------------ two rows that read as nothing ---
# *(Playtest 38, finding 1: "cats and birds have zero effect right now according to halos".)*
# Both cost her -- `cat_dash` 17/s over 30/120px for 1.8s, a flock +35 through the middle -- so
# the question was whether they were reaching `select_sources()` and `landed()` at all, before
# touching a number. They were: a `cat_dash` and a `pigeon_flock` instance standing on her clear
# the floor and accumulate `landed()` through their whole telegraph and their whole burst, exactly
# like every other row. **What was actually thin was `alpha_for()`'s brightness, not this
# pipeline** -- see `ExcitementHalo.magnitude_for()`, which reads `landed()` rather than a
# fraction of a source's own peak and is what the player's later words in the same session, *(2026-
# 09-08: "the transparency shouldn't show distance since distance actually doesn't matter ... only
# the actual received amount counts")*, actually fixed. This rig stays as the regression: the two
# rows a player once reported as invisible still reach the meter.

## `cat_dash` is `AHEAD_OF_PLAYER` and `mobile`, but a rig instance built with no route never
## enters `_advance_along_path()` (`path.size() > 1` is false), so it holds still at `at` for its
## whole life -- exactly what "standing on her" needs to hold the distance at zero throughout.
func _test_a_cat_dash_is_selected_and_lands(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var cat := _rig_instance(t, def, Vector2.ZERO)

	# Mid-telegraph: `TELEGRAPH_INTENSITY_FRACTION` (0.15) damps 17/s to 2.55/s, still comfortably
	# above `CONTRIBUTION_FLOOR` (1.0) at zero distance.
	cat._process(def.telegraph_time * 0.5)
	t.check(ExcitementHalo.select_sources([cat], Vector2.ZERO).size() == 1,
			"a cat_dash instance standing on her clears the floor while still telegraphing")

	var elapsed := def.telegraph_time * 0.5
	while elapsed < def.telegraph_time + def.duration:
		cat._process(STEP)
		elapsed += STEP
		var contribution: float = cat.contribution_at(Vector2.ZERO)
		if contribution > 0.0:
			cat.accumulate_landed(contribution * STEP)
	t.check(cat.landed() > 10.0,
			"a cat_dash that stood over her whole telegraph and whole dash lands well above zero")
	cat.free()

## A flock's own `global_position` never moves (only its birds do), so "standing on her" is simply
## siting it at `Vector2.ZERO` and reading `contribution_at()` there for the whole burst.
func _test_a_flock_is_selected_and_lands(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var flock := _rig_instance(t, def, Vector2.ZERO)
	t.check(flock._flock.size() == def.flock_size,
			"_ready() (live in the tree) built the flock, unlike a bare _instance_at()")
	# Standing in it: a flock waits on the pavement until she is inside `pursues_within`, and both
	# the telegraph and the burst below are measured from the moment it notices her — which is the
	# end of a frame, so the notice gets a frame of its own before the telegraph is stepped.
	flock.player_at = Vector2.ZERO
	flock._process(STEP)

	flock._process(def.telegraph_time * 0.5)
	t.check(ExcitementHalo.select_sources([flock], Vector2.ZERO).size() == 1,
			"a flock standing on her clears the floor while still on the ground telegraphing")

	var elapsed := def.telegraph_time * 0.5
	while elapsed < def.telegraph_time + def.duration:
		flock._process(STEP)
		elapsed += STEP
		var contribution: float = flock.contribution_at(Vector2.ZERO)
		if contribution > 0.0:
			flock.accumulate_landed(contribution * STEP)
	t.check(flock.landed() > 10.0,
			"a flock that stood over her whole telegraph and whole burst lands well above zero")
	flock.free()

## *(2026-09-12, the player: "the halo issue is not specific to cars you can see the same for when
## you walk close to birds you will get a freeze frame of their position as halo while they keep
## flying".)* A flock is the clearest case of a body that moves under a perfectly steady glow: the
## instance's own `global_position` never changes, so nothing about the owner looks like it is
## moving, while every bird is somewhere new every frame. `_draw()` is retained, so a rim traced
## once is that frame's birds until something asks for another trace — which `EntityHalo._process()`
## now does on every frame the rim is showing at all, easing or not.
##
## Headless never calls `_draw()`, so what is asserted is the state the drawing reads: the bird
## positions `EventInstance._draw_body()` traces really are different one frame on, and the rim over
## them is settled and lit — the pair the old rule threw the frame away on.
func _test_a_flocks_rim_has_a_new_body_to_trace_every_frame(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var flock := _rig_instance(t, def, Vector2.ZERO)
	# Standing in it, so it notices her and starts — the notice lands at the end of a frame, so it
	# gets one of its own — then past the telegraph, so the birds are up and flying rather than
	# pecking about on the ground.
	flock.player_at = Vector2.ZERO
	flock._process(STEP)
	flock._process(def.telegraph_time + 0.1)

	var before: Array[Vector2] = []
	for bird in flock._flock:
		before.append(bird.at)
	flock._process(STEP)
	var moved := 0
	for i in flock._flock.size():
		if not flock._flock[i].at.is_equal_approx(before[i]):
			moved += 1
	t.check(flock._flock.size() > 0 and moved == flock._flock.size(),
			"every one of the %d birds is somewhere new one frame on, so the silhouette the rim "
			% flock._flock.size()
			+ "traces is a different silhouette every frame")

	# And the rim over them is exactly the state that used to stop re-tracing.
	flock.set_halo_strength(ExcitementHalo.MAX_ALPHA, Palette.HALO_STRONG)
	var halo: EntityHalo = flock._halo
	for i in int(round(EntityHalo.FADE_IN_SECONDS / STEP)) + 2:
		halo._process(STEP)
	t.check(halo.has_settled() and halo.is_showing(),
			"the flock's own rim is settled and drawn while its birds keep moving, which is the "
			+ "freeze frame the player reported")
	flock.free()

# ------------------------------------------------------- the mirrored half of the ring ---

## **A rim has to survive being drawn through a mirror**, and for half of every eight-view family it
## did not. `Sprites.draw_standing()`'s flipped branch is the only mirrored draw path in the game —
## the mother, the crowd's walkers and cars and every eight-view event family all reach it — and it
## sets an *absolute* canvas transform, because `draw_set_transform` replaces rather than composes
## and Godot exposes no way to read back what it replaced. So each of `EntityHalo`'s twelve ring
## offsets was thrown away on a mirrored view: twelve copies landed on one another at the body, and
## the three west-facing sectors of every family drew no rim at all.
##
## Headless never calls `_draw()`, so the composition is asserted where it is computed rather than
## on pixels: `EntityHalo.trace_offsets()` is the ring and `Sprites.mirrored_transform()` is what the
## flipped branch actually sets. Both are pure, and between them they are the whole of where a
## mirrored copy lands.
##
## The assertions are the two things that were false: every copy lands somewhere of its own, and the
## mirrored ring covers the same ground as the unmirrored one. **A distinctness check alone would
## not hold it** — a ring that composed the offset the wrong way round is still twelve distinct
## points, just not around the body.
func _test_the_rims_mirrored_copies_land_on_the_ring(t) -> void:
	var bob := -2.5
	var anchor := Vector2(0.0, 26.0)
	var ring := EntityHalo.trace_offsets(bob)
	t.check(ring.size() == EntityHalo.HALO_OFFSETS,
			"the ring is the whole of `HALO_OFFSETS` (%d) rather than a subset" % ring.size())

	var landed := {}
	for offset in ring:
		Sprites.set_base_transform(Transform2D(0.0, offset))
		var mirrored := Sprites.mirrored_transform(anchor)
		# The flipped branch draws its rect in the mirrored frame, so where the sprite's own anchor
		# ends up is that frame's origin: the ring offset plus the anchor, and nothing else.
		t.check(mirrored.origin.is_equal_approx(offset + anchor),
				"a mirrored copy at ring offset %s lands at %s, the offset the unmirrored copy "
				% [offset, mirrored.origin] + "lands at too")
		t.check(is_equal_approx(mirrored.x.x, -1.0) and is_equal_approx(mirrored.y.y, 1.0),
				"and it is still mirrored on x only — composing the offset in may not undo the flip")
		landed[mirrored.origin.snapped(Vector2.ONE * 0.001)] = true
	Sprites.set_base_transform(Transform2D.IDENTITY)
	t.check(landed.size() == ring.size(),
			("all %d mirrored copies land on points of their own (%d distinct), which is what makes "
			+ "a rim rather than one silhouette re-drawn on itself") % [ring.size(), landed.size()])

	# And the ring itself is a ring: every offset exactly `HALO_MARGIN` from the body's own lift,
	# which is what "a few pixels out and no further" means in arithmetic.
	for offset in ring:
		var out := (offset - Vector2(0.0, bob)).length()
		t.check(is_equal_approx(out, EntityHalo.HALO_MARGIN),
				"every copy sits exactly HALO_MARGIN (%.1fpx) out from the bobbing body (%.3f)"
				% [EntityHalo.HALO_MARGIN, out])
