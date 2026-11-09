extends RefCounted
## **What a planned day is, as one comparable string**: what the scheduler placed, where, and in what
## order. Positions are to the pixel, because a shifted random stream moves an event without
## changing the set of events, which is the divergence the telemetry suites look for. A helper, not a suite: the runner loads
## only `test_*.gd`. Shared by `tests/test_telemetry.gd` (a trace on or off must not change a day)
## and `tests/test_telemetry_observer.gd` (the observer's watchers must not change the map a day
## is planned from).

const DrawnDay := preload("res://tests/drawn_day.gd")

## The signature of `day` planned over `map`, with `trace` (none by default) handed to the
## scheduler.
static func of(map: CityMap, day: int, trace: RunTrace = null) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("telemetry:%d:%d" % [map.seed_used, day])
	var consumed: Array[String] = []
	var parts: Array[String] = []
	for plan in DrawnDay.everywhere(EventScheduler.build_day(DaySpec.for_day(day), rng, map, CalmAreas.of(map), MastSites.compute(map),
			consumed, [], null, 0,
			PackedVector2Array(), [], trace)).placements():
		parts.append("%s@%.2f,%.2f" % [plan.def.id, plan.position.x, plan.position.y])
	return "|".join(parts)
