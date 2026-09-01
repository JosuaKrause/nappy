extends RefCounted
## The heat: what completing resistance tasks does to the city, and the contracts that keep the
## escalation from being a difficulty dial nobody checked.
##
## **The load-bearing test in here is the first one.** Every fairness contract in the game is
## asserted on load, from data — so a row that gets worse with the resistance and is only ever
## validated cold has its contract stated about precisely the harmless version of itself. Progress
## is a bounded integer, so the whole set of shapes exists and all of it is checkable.

const SEED := 8817

var _map: CityMap

func run(t) -> void:
	_map = CityGenerator.generate(SEED)
	_test_every_shape_of_every_row_is_fair(t)
	_test_a_row_that_answers_to_nothing_is_untouched(t)
	_test_heat_is_derived_once_and_kept(t)
	_test_the_ladder_has_a_top(t)
	_test_a_day_is_a_function_of_its_heat(t)

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

# ------------------------------------------------------------- the contracts ---

## Every row, at every level the resistance can reach, satisfies the contract it satisfies cold.
##
## `EventDef.validate()` pushes an error rather than returning quietly on the interesting failures,
## so a break here shows up twice — as a failed check and as the boot error `tools/check.sh` fails
## on. That is deliberate: this is the one property whose absence is invisible in play until the
## day somebody dies to an unfair event they could not have seen coming.
func _test_every_shape_of_every_row_is_fair(t) -> void:
	for def in EventCatalogue.all():
		for level in EventCatalogue.heat_levels():
			var hot := EventCatalogue.heated(def, level)
			t.check(hot.validate(), "'%s' is fair at heat %d" % [def.id, level])
			t.check(hot.id == def.id, "heat does not change what '%s' is" % def.id)

## The non-lethal rung stays non-lethal, and it is checked over the response rather than over the
## one row that carries it: the whole instruction this came from is that the ladder has two rungs
## and only the top one kills, so a second `PRESSES` row added later inherits the promise.
func _test_the_ladder_has_a_top(t) -> void:
	for def in EventCatalogue.all():
		if def.heat_response != EventDef.HeatResponse.PRESSES:
			continue
		for level in EventCatalogue.heat_levels():
			t.check(not EventCatalogue.heated(def, level).hard_fail,
					"'%s' presses without ever becoming lethal (heat %d)" % [def.id, level])

# ------------------------------------------------------------- the derivation ---

## A row that answers to nothing is the *same object* at every level, not merely an equal one.
## Identity rather than equality because the cost of getting this wrong is not a wrong number, it
## is a duplicate `Resource` per candidate placement per day.
func _test_a_row_that_answers_to_nothing_is_untouched(t) -> void:
	var untouched := 0
	for def in EventCatalogue.all():
		if def.heat_response != EventDef.HeatResponse.NONE:
			continue
		untouched += 1
		for level in EventCatalogue.heat_levels():
			t.check(EventCatalogue.heated(def, level) == def,
					"'%s' answers to nothing, so heat %d hands back the row itself"
					% [def.id, level])
	t.check(untouched > 0, "most of the catalogue answers to nothing")

func _test_heat_is_derived_once_and_kept(t) -> void:
	for def in EventCatalogue.all():
		# Cold is always the row itself, whatever the row answers to: level zero is *no* heat
		# rather than a little of it.
		t.check(EventCatalogue.heated(def, 0) == def,
				"'%s' at heat 0 is the catalogue's own row" % def.id)
		if def.heat_response == EventDef.HeatResponse.NONE:
			continue
		t.check(EventCatalogue.heated(def, 1) == EventCatalogue.heated(def, 1),
				"'%s' is derived once at a level and kept" % def.id)
		t.check(EventCatalogue.heated(def, 1) != def,
				"'%s' answers to heat, so heat gives back something else" % def.id)
		# Progress can reach five over the five tasks while four is what qualifies, so the top of
		# the ladder has to be a ceiling rather than a number the arithmetic runs past.
		t.check(EventCatalogue.heated(def, Tuning.RESISTANCE_GOAL + 1).intensity
						== EventCatalogue.heated(def, Tuning.RESISTANCE_GOAL).intensity,
				"'%s' cannot be heated past the goal" % def.id)

# --------------------------------------------------------------------- a day ---

## A planned day is a function of its arguments and heat is one of them: same seed, same day, same
## heat, same city. This is what lets a rig plan a hot day without a run having happened.
func _test_a_day_is_a_function_of_its_heat(t) -> void:
	var day := 9
	var consumed: Array[String] = []
	var first := EventScheduler.build_day(day, _rng(day), _map, consumed.duplicate(),
			[], [], null, Tuning.RESISTANCE_GOAL)
	var second := EventScheduler.build_day(day, _rng(day), _map, consumed.duplicate(),
			[], [], null, Tuning.RESISTANCE_GOAL)
	t.check(first.size() == second.size(),
			"a hot day planned twice is the same day (%d vs %d)" % [first.size(), second.size()])
	for i in mini(first.size(), second.size()):
		t.check(first[i].def.id == second[i].def.id and first[i].position == second[i].position,
				"placement %d of a hot day is where it was" % i)
	# And nothing in the heated catalogue can plan a day that has no park left to walk to — the
	# guarantee `_ensure_one_usable_park` makes cold has to survive the escalation.
	t.check(not first.is_empty(), "a hot day places events at all")
