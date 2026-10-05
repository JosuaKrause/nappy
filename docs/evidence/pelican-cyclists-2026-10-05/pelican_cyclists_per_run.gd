extends RefCounted
## Probe: cyclists met per day (days 2-14) over SEEDS cities. Prints CSV lines `CYC seed day rolls
## created total_rows`. tools/test.sh probes/pelican_cyclists_per_run.gd

const SEEDS := 120
const BASE_SEED := 772041
const STEP := 0.2

func run(t) -> void:
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		for day in range(2, 15):
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var plan_rng := RandomNumberGenerator.new()
			plan_rng.seed = hash("pelican:plan:%d:%d" % [map.seed_used, day])
			var planned: Array[EventScheduler.Planned] = EventScheduler.build_day(
					day, plan_rng, map, [], [], [], RouteTree.for_day(map, day), 0)
			var director := EventDirector.new(map)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("pelican:ahead:%d:%d" % [map.seed_used, day])
			director.start_day(day, planned, rng)
			var r := _walk(map, director, day)
			print("CYC %d %d %d %d %d %s" % [map.seed_used, day, r[0], r[1], r[2], r[3]])
	t.check(true, "pelican probe ran")

func _walk(map: CityMap, director: EventDirector, day: int) -> Array:
	var rolls := 0
	var created := 0
	var total := 0
	var others := {}
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
			total += 1
			if def.id == "cyclist":
				rolls += 1
				var path := due[1] as PackedVector2Array
				var dir := (path[0] - path[1]).normalized()
				var place := PendingWarning.down_her_line(map, def, pos, dir)
				if place != Vector2.INF:
					var route := PendingWarning.route_down_her_line(map, place, pos, dir)
					if director.clear_of_the_doors(route, def):
						created += 1
			else:
				others[def.id] = int(others.get(def.id, 0)) + 1
		pos += vel * step
		if pos.y < 0.0 or pos.y > y_max:
			vel.y = -vel.y
			pos.y = clampf(pos.y, 0.0, y_max)
		t += step
	var s := []
	for k in others:
		s.append("%s=%d" % [k, others[k]])
	return [rolls, created, total, ",".join(s)]
