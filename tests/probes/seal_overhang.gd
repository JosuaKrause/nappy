extends RefCounted
## Measurement probe for the seals' reach over buildings (inbox #785 in minty-lemur, "I saw wood on the roof"):
## per row, how many pieces a day's seals (days 1 to 14) and the escape's plan stand, how many of
## them reach into a building tile with their body or with the ground their picture is drawn over,
## and the deepest, over the seeds below. Not a suite: it prints rather than asserts. Run by name:
##
##     tools/test.sh probes/seal_overhang.gd      (prints SEAL_OVERHANG lines)
##
## The measure is `tests/seal_reach_rig.gd`'s. A day's seals are `SealPlanner.plan_day()`'s, on
## `RouteTree.for_day()`'s tree and the rng `tests/test_seals.gd` seeds them with; the escape's are
## every placement `DayPlanner.plan_the_escape_city()` makes, built the way `tests/finale_rig.gd` (run by `test_finale_a.gd`, `_b.gd` and `_c.gd`) builds it.

const Reach := preload("res://tests/seal_reach_rig.gd")
const FIRST_SEED := 1
const LAST_SEED := 30

## The seed the run starts from: fixed, so the probe measures the same runs on every machine.
const RUN_SEED := 2

func run(t: TestRunner) -> void:
	var own_run := RunState.new()
	own_run.start_run(RUN_SEED)
	var day_rows := {}
	var escape_rows := {}
	for seed_value in range(FIRST_SEED, LAST_SEED + 1):
		var map := CityGenerator.generate(seed_value)
		var ground := WalkGround.new(map)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			for plan in SealPlanner.plan_day(map, DaySpec.for_day(day), RouteTree.for_day(map, day), rng):
				_count(day_rows, map, ground, plan)
		own_run.attempt_spend.city_state.begin_day(map.block_plans, 1)
		map.repaint(own_run.attempt_spend.city_state)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for plan in DayPlanner.plan_the_escape_city(map, FinalePlanner.route(map), rng,
				_city_spec(), GamePlanBuilder.over(map)):
			_count(escape_rows, map, ground, plan)
	_print("day", day_rows)
	_print("escape", escape_rows)
	t.check(true, "a probe asserts nothing")

static func _count(rows: Dictionary, map: CityMap, ground: WalkGround,
		plan: EventPlan) -> void:
	var row: Array = rows.get(plan.def.id, [0, 0, 0.0, 0, 0.0])
	row[0] += 1
	var body := Reach.body_overhang(map, ground, plan)
	if body > 0.5:
		row[1] += 1
		row[2] = maxf(row[2], body)
	var drawn := Reach.drawing_overhang(map, plan)
	if drawn > 0.5:
		row[3] += 1
		row[4] = maxf(row[4], drawn)
	rows[plan.def.id] = row

static func _print(where: String, rows: Dictionary) -> void:
	var ids := rows.keys()
	ids.sort()
	for id: String in ids:
		var row: Array = rows[id]
		print("SEAL_OVERHANG %s seeds %d-%d | %-20s | %5d pieces | body over a building %5d, deepest %4.1fpx | drawing over a building %5d, deepest %4.1fpx"
				% [where, FIRST_SEED, LAST_SEED, id, row[0], row[1], row[2], row[3], row[4]])

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
