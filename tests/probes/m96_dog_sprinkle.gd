extends RefCounted
## Measurement probe for M96, "the teaching day, and the dog after it" — the sprinkle's own rate.
## Not a suite: it prints rather than asserting, so it lives here under `tests/probes/`, where the
## runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m96_dog_sprinkle.gd
##
## `EventDirector._owe_the_sprinkled_dog()` rolls `Tuning.CHARGING_DOG_SPRINKLE_CHANCE` once a day
## past `Tuning.RUN_TAUGHT_DAY` and, on a hit, puts `charging_dog` at the **front** of its own queue
## in day 3's own shape — off her heading, already noticing her. This walks a whole run — every day
## past the teaching day, continuous walking on a real street, the same instrument `tests/probes/
## m99_caps.gd` uses for the director's own queue — and counts how many of those hits the queue
## actually **delivers** before the day ends against how often the die was rolled at all.
##
## **The front matters and this probe is why.** `tests/probes/m99_caps.gd` found a busy day's own
## `AHEAD_OF_PLAYER` pool (`cat_dash`, `cyclist`, `loose_dog`) queues dozens a day and the pacing
## only ever drains a handful — measured here first: an *appended* roll was met in zero of 88
## sampled days, however often it was rolled. Pushed to the front instead, every rolled hit is met,
## which is what makes "offered" and "met" the same column below. `docs/DECISIONS.md`, M96, records
## what a run against the current `Tuning.CHARGING_DOG_SPRINKLE_CHANCE` measured and why that rate
## was chosen.

const SEEDS := 8
const BASE_SEED := 771307
const STEP := 0.2

func run(t) -> void:
	_measure_sprinkle_rate()
	t.check(true, "zz_m96_dog_sprinkle probe ran")

func _measure_sprinkle_rate() -> void:
	print("\n== M96 dog sprinkle: %d seeds, days %d..%d, whole day of continuous walking, rate=%.2f =="
			% [SEEDS, Tuning.RUN_TAUGHT_DAY + 1, Tuning.RUN_LENGTH_DAYS,
					Tuning.CHARGING_DOG_SPRINKLE_CHANCE])
	var per_run: Array = []
	var offered_per_run: Array = []
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 37)
		var met_this_run := 0
		var offered_this_run := 0
		for day in range(Tuning.RUN_TAUGHT_DAY + 1, Tuning.RUN_LENGTH_DAYS + 1):
			var tree := RouteTree.for_day(map, day)
			var plan_rng := RandomNumberGenerator.new()
			plan_rng.seed = hash("m96:plan:%d:%d" % [map.seed_used, day])
			var planned: Array[EventScheduler.Planned] = EventScheduler.build_day(
					day, plan_rng, map, [], [], [], tree, 0)

			var director := EventDirector.new(map)
			var director_rng := RandomNumberGenerator.new()
			director_rng.seed = hash("m96:ahead:%d:%d" % [map.seed_used, day])
			director.start_day(day, planned, director_rng)
			for queued: EventDef in director._owed:
				if queued.id == "charging_dog":
					offered_this_run += 1

			var y_min := 0.0
			var y_max: float = map.world_size().y
			var pos := CrowdLanes.arterial_pavement(map)
			pos.y = y_max * 0.5
			var vel := Vector2(0.0, -Tuning.WALK_SPEED)

			var day_len := Tuning.day_length(day)
			var elapsed := 0.0
			while elapsed < day_len:
				var step := minf(STEP, day_len - elapsed)
				var due: Array = director.due(step, pos, vel)
				if not due.is_empty():
					var def: EventDef = due[0]
					if def.id == "charging_dog":
						met_this_run += 1
				pos += vel * step
				if pos.y < y_min or pos.y > y_max:
					vel.y = -vel.y
					pos.y = clampf(pos.y, y_min, y_max)
				elapsed += step
		per_run.append(met_this_run)
		offered_per_run.append(offered_this_run)
	print("  offered/run (rolled a hit): mean=%.2f  runs=%s" % [_mean(offered_per_run), offered_per_run])
	print("  met/run (queue delivered it before the day ended): mean=%.2f  min=%d  max=%d  runs=%s"
			% [_mean(per_run), _min(per_run), _max(per_run), per_run])

func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += float(v)
	return total / float(values.size())

func _min(values: Array) -> int:
	var found := 999999
	for v in values:
		found = mini(found, int(v))
	return found

func _max(values: Array) -> int:
	var found := -999999
	for v in values:
		found = maxi(found, int(v))
	return found
