extends RefCounted
## The escalation: act gating, the mechanics the later acts introduced, and the invariants
## that stop a late day from being quietly unwinnable.

const SEED := 4242
const STEP := 1.0 / 60.0

var _map: CityMap

func run(t) -> void:
	_map = CityGenerator.generate(SEED)
	_test_acts_are_gated_by_day(t)
	_test_the_arterial_hands_over_cleanly(t)
	_test_city_wide_sources_have_no_edge(t)
	_test_a_protest_grows(t)
	_test_scars_outlive_the_day_that_made_them(t)
	_test_a_park_stays_reachable_every_day(t)
	_test_act_tints_differ(t)

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

# -------------------------------------------------------------------- gating ---

func _test_acts_are_gated_by_day(t) -> void:
	t.check(Tuning.act_for_day(1) == 1, "day 1 is act I")
	t.check(Tuning.act_for_day(3) == 1, "day 3 is still act I")
	t.check(Tuning.act_for_day(4) == 2, "day 4 opens act II")
	t.check(Tuning.act_for_day(8) == 3, "day 8 opens act III")
	t.check(Tuning.act_for_day(12) == 4, "day 12 opens act IV")
	t.check(Tuning.act_for_day(Tuning.RUN_LENGTH_DAYS) == 4, "the last day is act IV")

	# Nothing from a later act may leak into an earlier day.
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var act := Tuning.act_for_day(day)
		for def in EventCatalogue.available_on(day):
			t.check(def.act_tag <= act,
					"day %d (act %d) does not offer '%s' from act %d"
					% [day, act, def.id, def.act_tag])

	# And the marquee beats land where the narrative says they do.
	for id in ["police_patrol", "poster_crew"]:
		t.check(not EventCatalogue.by_id(id).available_on(3),
				"'%s' does not appear before act II" % id)
	for id in ["abduction", "alley_robbery"]:
		t.check(not EventCatalogue.by_id(id).available_on(7),
				"'%s' does not appear before act III" % id)
	for id in ["military_convoy", "protest"]:
		t.check(not EventCatalogue.by_id(id).available_on(11),
				"'%s' does not appear before act IV" % id)

## Two ambient defs share the arterial corridors, one loud and one quiet. If their day
## ranges ever overlapped the main roads would silently carry both bands at once.
func _test_the_arterial_hands_over_cleanly(t) -> void:
	var loud := EventCatalogue.by_id("busy_road")
	var quiet := EventCatalogue.by_id("quiet_road")
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(not (loud.available_on(day) and quiet.available_on(day)),
				"day %d has exactly one arterial noise band" % day)
		t.check(loud.available_on(day) or quiet.available_on(day),
				"day %d has an arterial noise band at all" % day)
	t.check(quiet.intensity < loud.intensity,
			"the streets get quieter in act III, not louder - that is the point")

# ------------------------------------------------------------------ mechanics ---

func _instance(t, def: EventDef, at := Vector2.ZERO) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

func _test_city_wide_sources_have_no_edge(t) -> void:
	var def := EventCatalogue.by_id("loudspeaker")
	t.check(def.city_wide, "the loudspeaker is city-wide")
	t.check(def.validate(), "a city-wide event is exempt from the escape-distance rule")
	t.check(def.intensity < Tuning.EXCITEMENT_DECAY_WALKING,
			"the loudspeaker cannot raise the meter on its own, only stall recovery")

	var instance := _instance(t, def)
	_advance(instance, def.telegraph_time + 0.05)
	var here := instance.contribution_at(Vector2.ZERO)
	var far := instance.contribution_at(Vector2(50000.0, 50000.0))
	t.close_to(far, here, "a city-wide source reaches the far side of the map undiminished")
	t.check(here > 0.0, "and it is actually contributing something")
	instance.free()

func _test_a_protest_grows(t) -> void:
	var def := EventCatalogue.by_id("protest")
	t.check(def.intensity_ramp > 1.0, "a protest swells rather than holding")
	var instance := _instance(t, def)
	_advance(instance, def.telegraph_time + 0.05)

	# Sample across whole pulse periods so the ramp, not the pulse, is what is compared.
	var early := _peak_over(instance, def.pulse_period)
	_advance(instance, def.duration * 0.75)
	var late := _peak_over(instance, def.pulse_period)
	t.check(late > early * 1.3, "a protest is markedly worse later than when you saw it")
	t.check(late <= def.intensity * def.intensity_ramp + 0.01,
			"and never exceeds its stated ceiling")
	instance.free()

func _peak_over(instance: EventInstance, seconds: float) -> float:
	var peak := 0.0
	for i in int(round(seconds / STEP)):
		instance._process(STEP)
		peak = maxf(peak, instance.current_intensity())
	return peak

## The burnt-out shell is on the same corner on day 12 as it was the morning after the fire.
func _test_scars_outlive_the_day_that_made_them(t) -> void:
	var saved := GameState.scars.duplicate(true)
	var saved_day := GameState.day

	GameState.day = 3
	GameState.scars = []
	var where := _map.tile_to_world(Vector2i(40, 40))
	GameState.add_scar("burnt_shell", where)
	GameState.add_scar("burnt_shell", where)
	t.check(GameState.scars.size() == 1, "the same scar is not recorded twice")

	var consumed: Array[String] = []
	var same_day := EventScheduler.build_day(3, _rng(3), _map, consumed, GameState.scars)
	t.check(not _contains(same_day, "burnt_shell"),
			"a scar does not double up on the day it was made")

	for day in [4, 9, 14]:
		var later: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), _map, later, GameState.scars)
		t.check(_contains(planned, "burnt_shell"),
				"the burnt-out shell is still there on day %d" % day)
		for plan in planned:
			if plan.def.id == "burnt_shell":
				t.close_to(plan.position.distance_to(where), 0.0,
						"and it is on the same corner", 1.0)

	GameState.scars = saved
	GameState.day = saved_day

func _contains(planned: Array, id: String) -> bool:
	for plan in planned:
		if plan.def.id == id:
			return true
	return false

# ----------------------------------------------------------------- invariants ---

## From act II onwards several events physically close streets, and from act IV a run can
## accumulate permanent barricades. Any combination that seals the home off from every park
## makes the day unwinnable in a way the player cannot see coming.
func _test_a_park_stays_reachable_every_day(t) -> void:
	var saved := GameState.scars.duplicate(true)
	# Stack the deck: pretend several convoys have already left barricades around.
	GameState.scars = []
	for tile in [Vector2i(20, 45), Vector2i(45, 20), Vector2i(70, 45), Vector2i(45, 70)]:
		GameState.scars.append({
			"id": "barricade", "position": _map.tile_to_world(tile), "since_day": 1,
		})

	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), _map, consumed, GameState.scars)
		# Typed deliberately: passing a bare `Array` here makes GDScript coerce it at the
		# call boundary, and that coercion leaves the CityMap alive at shutdown ("N
		# ObjectDB instances were leaked"). Declaring the real element type avoids it.
		var blockers: Array[EventScheduler.Planned] = []
		for plan in planned:
			if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
				blockers.append(plan)
		t.check(EventScheduler._park_is_reachable(_map, blockers),
				"day %d leaves a walkable route from home to a park" % day)

	GameState.scars = saved

func _test_act_tints_differ(t) -> void:
	var seen: Array[Color] = []
	for act in [1, 2, 3, 4]:
		var tint := Palette.act_tint(act)
		for other in seen:
			t.check(not tint.is_equal_approx(other), "act %d has its own cast" % act)
		seen.append(tint)
	# The city gets colder, not warmer: blue rises relative to red across the run.
	var first := Palette.act_tint(1)
	var third := Palette.act_tint(3)
	t.check(third.b / third.r > first.b / first.r,
			"act III is cooler than act I")
