extends RefCounted
## `ExcitementHalo`: which live events earn a place in the halo.
##
## Whether the result *reads* — the colour, the softness, whether a ring picks an entity's own
## silhouette out of a busy corner — is a screenshot's question and is out of this suite on
## purpose, the same line `docs/DECISIONS.md`'s testing policy draws for every other cue: "not
## tested, checked by eye: layout, colour, readability." *(2026-09-07, the player, on this cue
## specifically: "proof for the UI is my playtest don't try to come up with a complicated rig to
## test it. that's wasted effort.")* That is why the size — a ring of offsets around each entity's
## own re-drawn body, in `EventInstance._draw_halo()` — has no test here: there is no arithmetic
## version of "does the rim hug the sprite," only a look.
##
## **What is left is what would rot silently.** The selection, `select_sources()`: a day plans
## several hundred bodies and only a handful may ever earn a halo, or the cue marks everything and
## says nothing. And `landed()`'s moving sum, because a sign error in an exponential decay is
## invisible until somebody stands next to a cyclist and a protest and cannot tell which one to
## run from.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_weak_source_is_left_out(t)
	_test_a_source_above_the_floor_is_selected(t)
	_test_it_goes_to_zero_out_of_reach(t)
	_test_a_city_wide_source_is_never_drawn_at_a_point(t)
	_test_the_cap_keeps_the_strongest(t)
	_test_landed_accumulates_and_decays(t)
	_test_colour_for_the_ramp_ends(t)
	_test_alpha_for_is_the_falloff_fraction(t)

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

## Runs the same three assertions against any duck-typed source — `EventInstance` and
## `CrowdAgent` both carry the same `accumulate_landed()`/`landed()` shape, so a bug in one and not
## the other is exactly what a single test could miss.
func _check_accumulate_and_decay(t, source, label: String) -> void:
	var r := 8.0
	var dt := 1.0 / 60.0
	# Eight time constants is deep enough into the steady state (exp(-8) ~ 0.03%) that the loop
	# count itself carries no risk of under-converging, whatever `dt` is chosen.
	var steps := int(ExcitementHalo.WINDOW * 8.0 / dt)
	for _i in steps:
		source.accumulate_landed(r, dt)
	var expected := r * ExcitementHalo.WINDOW
	var converged: float = source.landed()
	t.check(absf(converged - expected) < expected * 0.03,
			"%s: a constant rate converges to r*WINDOW within 3%% of a true five-second sum" % label)

	# One accumulate_landed() call at delta = WINDOW is "fed zero for WINDOW seconds" in a single
	# step rather than a real-time loop — the EMA's decay depends only on total elapsed time, not
	# on how it was chopped up, so this is the same result without the wall-clock wait.
	source.accumulate_landed(0.0, ExcitementHalo.WINDOW)
	var decayed_once: float = source.landed()
	t.check(absf(decayed_once - expected * exp(-1.0)) < expected * 0.03,
			"%s: fed zero for one WINDOW, landed() has decayed to about 1/e of what it was" % label)

	# The lazy read: nobody calls accumulate_landed() again, and landed() alone has to reflect a
	# WINDOW's worth of elapsed wall-clock time. Rewinding the stored timestamp is the same fact as
	# waiting WINDOW seconds and cheap to assert instead of slow to wait for.
	var before: float = source.landed()
	source._landed_updated_ms -= int(ExcitementHalo.WINDOW * 1000.0)
	var after: float = source.landed()
	t.check(absf(after - before * exp(-1.0)) < before * 0.05,
			"%s: nobody visited this source for a whole WINDOW, and landed() alone reflects it" % label)

func _test_landed_accumulates_and_decays(t) -> void:
	var instance := _instance_at(_def("landed_event", 10.0), Vector2.ZERO)
	_check_accumulate_and_decay(t, instance, "EventInstance")
	instance.free()

	var agent := CrowdAgent.new()
	_check_accumulate_and_decay(t, agent, "CrowdAgent")
	agent.free()

# ---------------------------------------------------------------- colour ---

func _test_colour_for_the_ramp_ends(t) -> void:
	t.check(ExcitementHalo.colour_for(0.0).is_equal_approx(Palette.HALO_WEAK),
			"no landed excitement reads as the weak end of the ramp")
	var saturated := ExcitementHalo.SATURATES_AT * ExcitementHalo.WINDOW
	t.check(ExcitementHalo.colour_for(saturated).is_equal_approx(Palette.HALO_STRONG),
			"landed excitement at the saturation point reads as the strong end")
	t.check(ExcitementHalo.colour_for(saturated * 10.0).is_equal_approx(Palette.HALO_STRONG),
			"well past saturation stays at the strong end rather than overshooting it")
	var half := ExcitementHalo.colour_for(saturated * 0.5)
	t.check(not half.is_equal_approx(Palette.HALO_WEAK) and not half.is_equal_approx(Palette.HALO_STRONG),
			"halfway to saturation reads as neither end of the ramp")

# ---------------------------------------------------------------- brightness ---

func _test_alpha_for_is_the_falloff_fraction(t) -> void:
	t.check(is_equal_approx(ExcitementHalo.alpha_for(10.0, 10.0), ExcitementHalo.MAX_ALPHA),
			"at a source's own peak, alpha is MAX_ALPHA")
	t.check(is_equal_approx(ExcitementHalo.alpha_for(1000.0, 1000.0), ExcitementHalo.MAX_ALPHA),
			"a source three orders of magnitude stronger reads exactly as bright at its own peak")
	var weak_near_rim := ExcitementHalo.alpha_for(0.5, 10.0)
	var strong_near_rim := ExcitementHalo.alpha_for(50.0, 1000.0)
	t.check(is_equal_approx(weak_near_rim, strong_near_rim),
			"a weak and a strong source at the same fraction of their own reach read equally " +
			"bright -- brightness is decoupled from strength, only colour tells them apart")
	t.check(weak_near_rim < 0.1 * ExcitementHalo.MAX_ALPHA,
			"just inside the rim (5% of a source's own peak) alpha is near zero")
	t.check(is_equal_approx(ExcitementHalo.alpha_for(5.0, 0.0), 0.0),
			"a non-positive peak never divides by zero")
