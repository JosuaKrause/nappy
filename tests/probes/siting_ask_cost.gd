extends RefCounted
## What one `SpawnSiting.ask_of_ground()` costs at each day the region wall stands on, the call
## `ResistanceDirector._nearest_alley_within()` makes for every candidate tile of a relocation, and
## `region()`'s part of it: the median per-call time over a few thousand calls per day, one line a
## day (`SITING_ASK_COST_JSON`). Run in each revision's checkout and compare the times; the
## `bodies` count is what the day's region holds, and `same` that two asks in a row are handed the
## very same region (what a cache keeps), which is always false before there is one.
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const CITY_SEED := 478156010
const DAYS: Array[int] = [Tuning.REGION_WALL_FIRST_DAY, 10, 14]
const CALLS := 4000
const ROUNDS := 5

func run(t) -> void:
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(CITY_SEED))
	for day in DAYS:
		var state := CityState.new()
		state.begin_day(city.map.block_plans, day)
		var closures := RandomNumberGenerator.new()
		closures.seed = hash("siting-ask-cost:%d" % day)
		city.start_day(state, day, closures)
		var siting := city.spawn_siting
		var per_call: Array[float] = []
		for round in ROUNDS:
			var began := Time.get_ticks_usec()
			for i in CALLS:
				siting.ask_of_ground()
			per_call.append(float(Time.get_ticks_usec() - began) / float(CALLS))
		per_call.sort()
		var region := siting.region()
		print("SITING_ASK_COST_JSON " + JSON.stringify({"day": day,
				"bodies": region.centres.size() if region else 0,
				"same": is_same(siting.region(), siting.region()),
				"us_per_call": snappedf(per_call[ROUNDS / 2], 0.001)}))
	city.free()
	t.check(true, "ran")
