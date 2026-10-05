extends RefCounted
## Measurement probe for olive-badger: how many charging dogs she meets on day 3, now that the
## lesson is a rigged bag of one in front of the route's bag and the ordinary bag holds
## `Tuning.ROUTE_BAG_MARBLES_OF` dogs (inbox #566 in feathery-stork). Not a suite: it prints rather than asserting, so
## it lives under `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/olive_badger_day3_dogs.gd
##
## Drives the director the way `tests/probes/olive_badger_route_mix.gd` does — a whole day of
## continuous walking down a real pavement, bounced at the map's edges — over `SEEDS` cities, and
## prints the dogs met a day, split into the lesson and the ones after it, the share of days on which
## `charging_dog`'s `max_per_day` was reached, and the route events met a day. Uses only
## `EventDirector.start_day()` and `due()`, so it measures the code before and after a change alike.

const SEEDS := 120
const BASE_SEED := 772041
const STEP := 0.2
const DOG := "charging_dog"

func run(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	var cap := EventCatalogue.by_id(DOG).max_per_day
	var dogs_sum := 0
	var lessons := 0
	var at_cap := 0
	var met_sum := 0
	var no_dog_bought := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var plan_rng := RandomNumberGenerator.new()
		plan_rng.seed = hash("olive-badger:plan:%d:%d" % [map.seed_used, day])
		var planned: Array[EventScheduler.Planned] = EventScheduler.build_day(
				day, plan_rng, map, [], [], [], RouteTree.for_day(map, day), 0)
		var bought_a_dog := false
		for plan in planned:
			if plan.def.id == DOG:
				bought_a_dog = true
		if not bought_a_dog:
			no_dog_bought += 1
		var director := EventDirector.new(map)
		var director_rng := RandomNumberGenerator.new()
		director_rng.seed = hash("olive-badger:ahead:%d:%d" % [map.seed_used, day])
		director.start_day(day, planned, director_rng)
		var met := _walk_a_day(map, director, day)
		var dogs := met.count(DOG)
		dogs_sum += dogs
		if not met.is_empty() and met[0] == DOG:
			lessons += 1
		if dogs >= cap:
			at_cap += 1
		met_sum += met.size()
	var n := float(SEEDS)
	print("\n== olive-badger day %d dogs: %d seeds, a whole day of continuous walking ==" % [day,
			SEEDS])
	print("  dogs met/day %.2f: the lesson %.2f, after it %.2f" % [dogs_sum / n, lessons / n,
			(dogs_sum - lessons) / n])
	print("  days reaching the cap of %d: %.0f%%; route events met/day %.1f; days whose dawn bought no dog %d"
			% [cap, at_cap / n * 100.0, met_sum / n, no_dog_bought])
	t.check(true, "zz_olive_badger_day3_dogs probe ran")

## Every row the director hands out over one day of walking, in order.
func _walk_a_day(map: CityMap, director: EventDirector, day: int) -> Array[String]:
	var met: Array[String] = []
	var y_max: float = map.world_size().y
	var pos := CrowdLanes.arterial_pavement(map)
	pos.y = y_max * 0.5
	var vel := Vector2(0.0, -Tuning.WALK_SPEED)
	var day_len := Tuning.day_length(day)
	var t := 0.0
	while t < day_len:
		var step := minf(STEP, day_len - t)
		var due: Array = director.due(step, pos, vel)
		if not due.is_empty():
			met.append((due[0] as EventDef).id)
		pos += vel * step
		if pos.y < 0.0 or pos.y > y_max:
			vel.y = -vel.y
			pos.y = clampf(pos.y, 0.0, y_max)
		t += step
	return met
