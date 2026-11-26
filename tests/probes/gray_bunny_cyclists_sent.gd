extends RefCounted
## Measurement probe for gray-bunny, nothing keeps a placed event out of a sent cyclist's lethal
## field. Not a suite: it prints rather than asserting, so it lives under `tests/probes/`, where the
## runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/gray_bunny_cyclists_sent.gd      (prints GB lines)
##
## **What it measures is how often the director sends a cyclist, and how often a placed plan
## stands inside the field of one it sends**, per day 1 to 14 over `SEEDS` cities. Each day is
## planned the way `tests/probes/olive_badger_route_mix.gd` plans it (the day's own paint, the day's
## tree, the city's mast sites handed in as the game hands them, `GameDawn`), and the director is
## handed the day's whole plan and walked the way that probe walks it: a whole day of continuous
## walking down the arterial's sidewalk (`CrowdLanes.arterial_pavement()`), bounced at the map's
## edges, so the count per day is the director's own pacing. A handed row's route has a placed plan
## inside its field where the row's plan keeps its field clear
## (`EventPlan.keeps_its_field_clear()`) and a placed, unspent plan of the day is nearer its route
## than its field reaches (`EventPlan.gap_to()` against `EventPlan.field_reach()`), the measure
## every dawn placement is held to (`StreetInvalidation.room_around()`).
##
## For each cyclist sent it asks too what his arrival asks: the route he would be created on once his
## warning is over, with her walked on (`_route_at_arrival()`), asked again of the director
## (`EventDirector.clear_to_send()`), a refusal withdrawing his warning.
##
## It prints first, per row the director sends, whether a sent plan of it keeps its field clear,
## since those are the rows the rule binds. Uses only `EventDirector.start_day()` and `due()`, so
## it measures the code before and after a change alike.

const SEEDS := 6
const BASE_SEED := 772041
const STEP := 0.2

func run(t: TestRunner) -> void:
	_rows_the_rule_binds()
	var sent := _measure()
	t.check(sent > 0, "zz_gray_bunny probe sent rows to count (%d)" % sent)

func _rows_the_rule_binds() -> void:
	var seen := {}
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		for id: String in EventDirector.ordinary_route_marbles(day, 0):
			if seen.has(id):
				continue
			seen[id] = true
			var def := EventCatalogue.by_id(id).as_sent_ahead()
			var plan := EventPlan.new(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO,
					Vector2.RIGHT * Tuning.TILE_SIZE * 10.0]))
			print("GB ROW %-16s from day %2d  ends the day %-5s pursues %-5s keeps its field clear %-5s reach %.0f"
					% [id, day, def.ends_the_day(), def.pursues(), plan.keeps_its_field_clear(),
					def.field_reach()])

func _measure() -> int:
	var by_day := {}
	var sent_total := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		var sites := MastSites.compute(map)
		var navigator := Navigator.new(map)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day, null)
			var plan_rng := RandomNumberGenerator.new()
			plan_rng.seed = hash("gray-bunny:plan:%d:%d" % [map.city_seed(), day])
			var consumed: Array[String] = []
			var planned: Array[EventPlan] = GameDawn.of(DaySpec.for_day(day), plan_rng, map) \
					.masts(sites).spent(consumed).on(tree).plan().placements()
			var director := EventDirector.new(map)
			var director_rng := RandomNumberGenerator.new()
			director_rng.seed = hash("gray-bunny:ahead:%d:%d" % [map.city_seed(), day])
			director.start_day(day, planned, director_rng, DaySpec.DirectorSends.THE_DAYS_ROWS)
			var counts := _walk_a_day(map, navigator, director, day, planned)
			sent_total += int(counts["all"])
			print("GB seed %d day %2d: sent %2d, cyclists %2d, in a field kept clear %2d, withdrawn %d (a plan in the field %d), other lethal %2d (in a field %d)"
					% [map.city_seed(), day, counts["all"], counts["cyclists"],
					counts["cyclists_in_a_field"], counts["withdrawn"], counts["withdrawn_by_a_plan"],
					counts["other_kept"], counts["other_in_a_field"]])
			var sum: Dictionary = by_day.get(day, {})
			for key: String in counts:
				sum[key] = int(sum.get(key, 0)) + int(counts[key])
			by_day[day] = sum
	print("GB -- per day over %d cities --" % SEEDS)
	var cyclists := 0
	var inside := 0
	var withdrawn := 0
	var by_a_plan := 0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var sum: Dictionary = by_day[day]
		cyclists += int(sum["cyclists"])
		inside += int(sum["cyclists_in_a_field"])
		withdrawn += int(sum["withdrawn"])
		by_a_plan += int(sum["withdrawn_by_a_plan"])
		print("GB DAY %2d: sent %3d, cyclists %3d (%.2f a day), with a placed plan in the field %3d, withdrawn at arrival %2d (by a plan in the field %2d)"
				% [day, sum["all"], sum["cyclists"], float(sum["cyclists"]) / SEEDS,
				sum["cyclists_in_a_field"], sum["withdrawn"], sum["withdrawn_by_a_plan"]])
	print("GB TOTAL cyclists %d over %d days, %d with a placed plan in the field, %d withdrawn at arrival (%d by a plan in the field)"
			% [cyclists, SEEDS * Tuning.RUN_LENGTH_DAYS, inside, withdrawn, by_a_plan])
	return sent_total

## What the director hands out over one day of walking: every row, the cyclists, the cyclists with
## a placed plan inside their field, and the same two for any other handed row whose plan keeps its
## field clear.
func _walk_a_day(map: CityMap, navigator: Navigator, director: EventDirector, day: int,
		planned: Array[EventPlan]) -> Dictionary:
	var counts := {"all": 0, "cyclists": 0, "cyclists_in_a_field": 0, "other_kept": 0,
			"other_in_a_field": 0, "withdrawn": 0, "withdrawn_by_a_plan": 0}
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
			var def := due[0] as EventDef
			var path := due[1] as PackedVector2Array
			counts["all"] += 1
			var sent := EventPlan.new(def, path[0], path)
			var inside := sent.keeps_its_field_clear() and _a_plan_inside(sent, planned)
			if def.id() == "cyclist":
				counts["cyclists"] += 1
				if inside:
					counts["cyclists_in_a_field"] += 1
				var arrival := _route_at_arrival(map, navigator, def, path, pos, vel)
				if arrival.size() < 2 or not director.clear_to_send(arrival, def):
					counts["withdrawn"] += 1
					if arrival.size() >= 2 and _a_plan_inside(
							EventPlan.new(def, arrival[0], arrival), planned):
						counts["withdrawn_by_a_plan"] += 1
			elif sent.keeps_its_field_clear():
				counts["other_kept"] += 1
				if inside:
					counts["other_in_a_field"] += 1
		pos += vel * step
		if pos.y < 0.0 or pos.y > y_max:
			vel.y = -vel.y
			pos.y = clampf(pos.y, 0.0, y_max)
		t += step
	return counts

## **The route a cyclist sited on `path` would be created on once his warning is over**, her having
## walked on at `vel` from `pos` for as long as it is up: what `EventsAhead._warn_down_her_line()`
## asks again of the director as he arrives, a refusal withdrawing the warning.
static func _route_at_arrival(map: CityMap, navigator: Navigator, def: EventDef,
		path: PackedVector2Array, pos: Vector2, vel: Vector2) -> PackedVector2Array:
	var direction := (path[0] - path[1]).normalized()
	var her := pos + vel * def.warned_for()
	var place := PendingWarning.down_her_line(map, def, her, direction)
	if place == Vector2.INF:
		return PackedVector2Array()
	return navigator.trim(PendingWarning.route_down_her_line(map, place, her, direction),
			EventInstance.mover_for(def))

## Whether a placed, unspent plan of the day stands nearer `sent`'s route than its field reaches.
static func _a_plan_inside(sent: EventPlan, planned: Array[EventPlan]) -> bool:
	for plan in planned:
		if plan.is_placed() and not plan.is_spent() and sent.gap_to(plan) < sent.field_reach():
			return true
	return false
