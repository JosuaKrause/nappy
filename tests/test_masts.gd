extends RefCounted
## The masts: fixed sites from `Tuning.MAST_FIRST_DAY`, a field like any other row's, a broadcast
## clock every mast reads rather than a clock of its own, and an id that survives silencing. See
## `docs/TODO.md`, M180, "Posters she notices, and loudspeakers that are somewhere".

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0
## A handful of seeds, for the one guarantee that has to hold on more than the seed the rest of
## this suite happens to use — `docs/EVENTS.md`'s "checked before it is accepted" — the same reason
## a city guarantee is measured across several seeds rather than trusted from one.
const SITE_SEEDS := [4242, 1, 90210, 778812345]

var _map: CityMap
var _city: City

func run(t) -> void:
	_map = CityGenerator.generate(SEED)
	_test_no_row_is_city_wide(t)
	_test_masts_appear_from_day_5_at_the_same_sites_every_day(t)
	_test_a_mast_never_reaches_the_doorstep_or_a_calm_interior(t)
	_test_the_field_is_zero_outside_its_reach_and_falls_off_inside_it(t)
	_build_city(t)
	_test_they_all_speak_together(t)
	_test_silencing_one_mast_works_for_the_rest_of_the_day(t)
	_test_silencing_every_mast_works_for_the_rest_of_the_day(t)
	_teardown()

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

func _mast_plans(day: int) -> Array[EventScheduler.Planned]:
	var consumed: Array[String] = []
	var planned := EventScheduler.build_day(day, _rng(day), _map, consumed)
	var found: Array[EventScheduler.Planned] = []
	for plan in planned:
		if plan.mast_id != "":
			found.append(plan)
	return found

# ---------------------------------------------------------------- no floor ---

## The property itself is gone, checked the one way that cannot fail to compile against a field
## that no longer exists: `Object.get()` is the dynamic accessor, and it answers `null` for a
## property nobody declared rather than raising the parse error a static `def.city_wide` would.
func _test_no_row_is_city_wide(t) -> void:
	t.check(EventDef.new().get("city_wide") == null,
			"EventDef carries no city_wide field any more")
	var loudspeaker := EventCatalogue.by_id("loudspeaker")
	var curfew := EventCatalogue.by_id("curfew_announce")
	t.check(loudspeaker.outer_radius > loudspeaker.inner_radius,
			"the loudspeaker has an edge a route can go round")
	t.check(curfew.outer_radius > curfew.inner_radius,
			"so does the curfew announcement it carries on Tuning.CURFEW_ANNOUNCE_DAY")

# ------------------------------------------------------------------- sites ---

func _test_masts_appear_from_day_5_at_the_same_sites_every_day(t) -> void:
	t.check(_mast_plans(Tuning.MAST_FIRST_DAY - 1).is_empty(),
			"no mast stands the day before Tuning.MAST_FIRST_DAY")

	var by_day := {}
	for day in [Tuning.MAST_FIRST_DAY, Tuning.MAST_FIRST_DAY + 2, Tuning.RUN_LENGTH_DAYS]:
		var by_id := {}
		for plan in _mast_plans(day):
			if plan.def.id != "loudspeaker":
				continue
			by_id[plan.mast_id] = plan.position
		t.check(by_id.size() == Tuning.MAST_COUNT,
				"day %d carries all %d masts (%d)" % [day, Tuning.MAST_COUNT, by_id.size()])
		by_day[day] = by_id
	var first: Dictionary = by_day[Tuning.MAST_FIRST_DAY]
	for day in by_day:
		var here: Dictionary = by_day[day]
		for id in first:
			t.check(here.has(id) and here[id].distance_to(first[id]) < 0.01,
					"mast '%s' stands at the same place on day %d as on day %d"
					% [id, day, Tuning.MAST_FIRST_DAY])

	# Pure geometry, called twice: MastSites.compute() takes no day and no RNG, so "the same
	# places every day" is true of the function itself and not only of what build_day did with it.
	var once := MastSites.compute(_map)
	var again := MastSites.compute(_map)
	t.check(once.size() == Tuning.MAST_COUNT and again.size() == Tuning.MAST_COUNT,
			"MastSites.compute() always answers Tuning.MAST_COUNT sites (%d, %d)"
			% [once.size(), again.size()])
	for i in once.size():
		t.check(once[i].id == again[i].id and once[i].foot.distance_to(again[i].foot) < 0.01,
				"site %d is the same site both times" % i)

## Checked over several seeds — the one guarantee here that a single lucky map cannot stand for.
func _test_a_mast_never_reaches_the_doorstep_or_a_calm_interior(t) -> void:
	var checked := 0
	for seed_value in SITE_SEEDS:
		var map := CityGenerator.generate(seed_value)
		var reach := EventCatalogue.by_id("loudspeaker").outer_radius
		var doorstep := map.doorstep_world_position()
		var home := map.home_world_position()
		var home_margin := Tuning.MAST_HOME_STREET_MARGIN * float(CityMap.period()) * Tuning.TILE_SIZE
		for site in MastSites.compute(map):
			checked += 1
			t.check(site.foot.distance_to(doorstep) >= reach,
					"seed %d: '%s' does not reach the doorstep (%.0fpx away, reach %.0fpx)"
					% [seed_value, site.id, site.foot.distance_to(doorstep), reach])
			t.check(site.foot.distance_to(home) >= home_margin,
					"seed %d: '%s' is not on the home street" % [seed_value, site.id])
			var seen := {}
			for block in map.calm_blocks:
				var anchor := map.anchor_of(block)
				if seen.has(anchor):
					continue
				seen[anchor] = true
				var interior := map.tile_rect_to_world(map.lot_rect(block)).grow(
						-Tuning.MAST_CALM_INTERIOR_MARGIN)
				if not interior.has_area():
					continue
				var closest := Vector2(clampf(site.foot.x, interior.position.x, interior.end.x),
						clampf(site.foot.y, interior.position.y, interior.end.y))
				t.check(site.foot.distance_to(closest) >= reach,
						"seed %d: '%s' does not reach the interior of the calm block at %s"
						% [seed_value, site.id, block])
	t.check(checked == Tuning.MAST_COUNT * SITE_SEEDS.size(),
			"and every mast on every seed was actually checked (%d)" % checked)

# ------------------------------------------------------------------- field ---

func _test_the_field_is_zero_outside_its_reach_and_falls_off_inside_it(t) -> void:
	var def := EventCatalogue.by_id("loudspeaker")
	t.check(is_zero_approx(def.emission_at_distance(def.outer_radius + 1.0)),
			"the field is zero just past its own outer radius")
	var at_inner := def.emission_at_distance(def.inner_radius)
	var at_middle := def.emission_at_distance((def.inner_radius + def.outer_radius) * 0.5)
	var at_outer := def.emission_at_distance(def.outer_radius - 1.0)
	t.check(at_inner > at_middle and at_middle > at_outer and at_outer > 0.0,
			"the field falls away between the inner and outer radius (%.2f > %.2f > %.2f > 0)"
			% [at_inner, at_middle, at_outer])
	t.check(is_equal_approx(def.emission_at_distance(0.0), at_inner),
			"and is flat inside the inner radius, like any other row's")

# -------------------------------------------------------------- the broadcast ---

func _build_city(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(_map)
	# No player in this rig, so nothing streams on its own — `EventManager._physics_process()`
	# skips streaming when `_find_player()` fails, the same reason `test_event_manager.gd` gives.
	# Streaming below is driven by hand, at whatever real moment each check wants a mast live.
	_city.events.stream_radius = 10.0

func _sites() -> Array[MastSites.Site]:
	return MastSites.compute(_map)

func _advance(seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		_city.events._physics_process(STEP)

func _plan_for(mast_id: String, row_id: String = "loudspeaker") -> EventScheduler.Planned:
	for plan in _city.events.plans():
		if plan.mast_id == mast_id and plan.def.id == row_id:
			return plan
	return null

## Two masts, met minutes apart, still read the same broadcast clock — the mechanism behind "all
## masts speak at once". `age` is set from `EventManager._broadcast_clock` at the moment each one
## streams in (`_stream_in()`'s own doc), not from zero, so a mast met later in the day is not a
## mast that is "younger" — it is telling the same time as every other one.
func _test_they_all_speak_together(t) -> void:
	_city.events.start_day(Tuning.MAST_FIRST_DAY, _rng(Tuning.MAST_FIRST_DAY), [])
	var sites := _sites()
	t.check(sites.size() >= 2, "there are at least two masts to compare")
	if sites.size() < 2:
		return
	var a := sites[0]
	var b := sites[1]

	_advance(9.0)
	var clock_a: float = _city.events._broadcast_clock
	_city.events.stream_around(a.foot)
	var plan_a := _plan_for(a.id)
	t.check(plan_a != null and plan_a.live != null, "the first mast is live")
	if plan_a and plan_a.live:
		t.close_to(plan_a.live.age, clock_a,
				"a mast's age is the broadcast clock at the moment it streams in", 0.05)

	_advance(6.0)
	var clock_b: float = _city.events._broadcast_clock
	_city.events.stream_around(b.foot)
	var plan_b := _plan_for(b.id)
	t.check(plan_b != null and plan_b.live != null, "the second mast is live")
	if plan_b and plan_b.live:
		t.close_to(plan_b.live.age, clock_b,
				"so is the second mast, met minutes later — the same clock", 0.05)

	t.check(clock_b > clock_a + 5.0,
			"and time genuinely passed between the two (%.1fs)" % (clock_b - clock_a))
	if plan_a and plan_a.live and plan_b and plan_b.live:
		t.check(not is_equal_approx(plan_a.live.age, plan_b.live.age),
				"they were not both stamped the instant they happened to stream in")

# -------------------------------------------------------------- silencing ---

func _test_silencing_one_mast_works_for_the_rest_of_the_day(t) -> void:
	_city.events.start_day(Tuning.MAST_FIRST_DAY, _rng(Tuning.MAST_FIRST_DAY), [])
	var target := _sites()[0]
	_city.events.stream_around(target.foot)
	var plan := _plan_for(target.id)
	t.check(plan != null and plan.live != null, "the mast is live before it is silenced")
	if not (plan and plan.live):
		return
	t.check(plan.live.current_intensity() > 0.0, "and it is actually speaking")

	t.check(_city.events.silence_mast(target.id), "silencing a mast by id finds it")
	t.check(is_zero_approx(plan.live.current_intensity()), "a silenced mast's field is gone")
	t.check(not plan.live.is_finished, "but the mast still stands — it has not left")

	# Streamed out and back in, the silence holds.
	_city.events.stream_around(Vector2(-99999.0, -99999.0))
	t.check(plan.live == null, "walking away streams it back out")
	_city.events.stream_around(target.foot)
	t.check(plan.live != null, "and walking back streams it in again")
	if plan.live:
		t.check(plan.live.silenced, "still silenced — for the rest of the day")
		t.check(is_zero_approx(plan.live.current_intensity()), "still no field")

func _test_silencing_every_mast_works_for_the_rest_of_the_day(t) -> void:
	_city.events.start_day(Tuning.CURFEW_ANNOUNCE_DAY, _rng(Tuning.CURFEW_ANNOUNCE_DAY), [])
	for site in _sites():
		_city.events.stream_around(site.foot)
	var silenced := _city.events.silence_all_masts()
	t.check(silenced == Tuning.MAST_COUNT,
			("silencing every mast silences exactly Tuning.MAST_COUNT of them (%d wanted, %d "
			% [Tuning.MAST_COUNT, silenced])
			+ "got) — one per site, not one per row sharing that site on the curfew day")
	var mast_plans_checked := 0
	for plan in _city.events.plans():
		if plan.mast_id == "":
			continue
		mast_plans_checked += 1
		t.check(plan.silenced, "'%s' at '%s' is silenced" % [plan.def.id, plan.mast_id])
		if plan.live:
			t.check(is_zero_approx(plan.live.current_intensity()),
					"'%s' at '%s' has no field" % [plan.def.id, plan.mast_id])
	t.check(mast_plans_checked == Tuning.MAST_COUNT * 2,
			("and both of the day's own mast rows were checked (%d): the ordinary broadcast and "
			% mast_plans_checked) + "the curfew announcement, one pair per site")

func _teardown() -> void:
	if _city:
		_city.free()
