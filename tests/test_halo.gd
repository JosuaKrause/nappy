extends RefCounted
## `ExcitementHalo`: which live events earn a place in the halo, and how big each one is drawn.
##
## Whether the result *reads* — the colour, the softness, whether a glow picks an entity out of a
## busy corner — is a screenshot's question and is out of this suite on purpose, the same line
## `docs/DECISIONS.md`'s testing policy draws for every other cue: "not tested, checked by eye:
## layout, colour, readability."
##
## **Two things here are not that, and both would rot silently.** The selection
## (`select_sources()`), because a day plans several hundred bodies and only a handful may ever earn
## a glow or the cue marks everything and says nothing. And the size (`glow_radius()`), because the
## whole of this cue's licence to exist is that it draws the *thing* rather than the thing's
## *reach* — a size that crept out toward `outer_radius` would be the ring the **cues** rule
## refuses, and nothing on screen would announce it as one.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_weak_source_is_left_out(t)
	_test_a_source_above_the_floor_is_selected(t)
	_test_it_goes_to_zero_out_of_reach(t)
	_test_a_city_wide_source_is_never_drawn_at_a_point(t)
	_test_the_cap_keeps_the_strongest(t)
	_test_a_glow_is_the_outline_plus_a_few_pixels(t)
	_test_a_bodyless_row_glows_at_a_persons_size(t)
	_test_a_big_body_glows_big(t)
	_test_no_row_in_the_catalogue_glows_as_far_as_it_reaches(t)

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

# ------------------------------------------------------------------- the size ---
# `glow_radius()` is pure and takes a def, so all four of these are arithmetic with no viewport,
# no rig and no instance — the cheap half of a cue whose expensive half is a screenshot.

func _test_a_glow_is_the_outline_plus_a_few_pixels(t) -> void:
	var def := _def("busker", 9.0)
	def.obstructs_radius = 11.0
	t.check(is_equal_approx(ExcitementHalo.glow_radius(def), 15.0),
			"a person-sized body glows at its own 11px outline plus the 4px margin")

func _test_a_bodyless_row_glows_at_a_persons_size(t) -> void:
	# Every `mobile` row is exempt from carrying an `obstructs_radius`, so this is most pursuers
	# and every walker — they are drawn as people and glow as people rather than at zero.
	var def := _def("dog_walker", 9.0)
	def.obstructs_radius = 0.0
	t.check(is_equal_approx(ExcitementHalo.glow_radius(def),
			ExcitementHalo.GLOW_BODYLESS_RADIUS + ExcitementHalo.GLOW_BODY_MARGIN),
			"a row with no outline to trace glows at a person's size, not at nothing")

func _test_a_big_body_glows_big(t) -> void:
	# The reason there is no ceiling: a clamp would draw a barricade's halo *inside* the barricade,
	# which is the one shape a cue meaning "this thing" is not allowed to be.
	var def := _def("barricade", 20.0)
	def.obstructs_radius = 62.0
	t.check(is_equal_approx(ExcitementHalo.glow_radius(def), 66.0),
			"a wide body glows wide — the outline decides the size, with nothing capping it")

func _test_no_row_in_the_catalogue_glows_as_far_as_it_reaches(t) -> void:
	# The whole licence this cue has to exist is that it draws the *thing* and not the thing's
	# *reach*. Nothing on screen would announce a size that crept out toward `outer_radius`, so it
	# is asserted over every row rather than trusted to stay true as rows are added.
	var worst := ""
	var worst_ratio := 0.0
	for def in EventCatalogue.all():
		if def.city_wide:
			# No position to draw a halo around, so `select_sources()` excludes it by kind.
			continue
		var ratio := ExcitementHalo.glow_radius(def) / maxf(def.outer_radius, 0.001)
		if ratio > worst_ratio:
			worst_ratio = ratio
			worst = def.id
	t.check(worst_ratio < 1.0,
			"every row's glow stays inside its own outer_radius — worst is %s at %.2f of it"
					% [worst, worst_ratio])
