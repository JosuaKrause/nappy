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
## **What is left is the one thing here that is not that, and would rot silently.** The selection,
## `select_sources()`: a day plans several hundred bodies and only a handful may ever earn a halo,
## or the cue marks everything and says nothing.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_weak_source_is_left_out(t)
	_test_a_source_above_the_floor_is_selected(t)
	_test_it_goes_to_zero_out_of_reach(t)
	_test_a_city_wide_source_is_never_drawn_at_a_point(t)
	_test_the_cap_keeps_the_strongest(t)

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
