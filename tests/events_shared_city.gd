extends RefCounted
## The shared "one city, one day's plan" cache several `test_events_*.gd` suites need after M125's
## split by subject. Copied out of the original `test_events.gd` rather than composed, so a suite
## extends this script and keeps calling `_map()`/`_rng()`/`_planned()` completely unqualified,
## exactly as the tests already did before the split -- no call site below had to change.
##
## **The cache is not shared *across* suites.** `run_tests.gd` calls `.new()` once per `test_*.gd`
## file, so `test_events_fire.gd`, `test_events_scheduler.gd`, `test_events_solid.gd`,
## `test_events_pursuit.gd` and `test_events_scenery.gd` each build their own city and their own
## plan cache the first time one of their tests asks for it. Sharing the *code* still matters: the
## reasoning below is written once rather than five times, and there is one place to fix it.

## The suite's shared city, generated once.
##
## Seed 4242 is deliberately the same city for every check that does not name its own seed, so
## that the expensive part — generation, a quarter of a second — is paid once rather than at every
## call site that wants a real map to place things on. **It is handed out pristine and must stay
## that way**: a check that repaints it, closes streets on it or holds segments on it takes its own
## copy (`_test_the_day_is_placed_by_role` is the one that does), because the day plans cached
## below were built against this paint and a repaint underneath them would leave the rest of the
## file asserting about a city that no longer exists.
var _shared_map: CityMap

func _map() -> CityMap:
	if not _shared_map:
		_shared_map = CityGenerator.generate(4242)
	return _shared_map

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [4242, day])
	return rng

## The shared map's plan for `day`, memoized.
##
## **Ten checks below ask for exactly this** — `build_day(day, _rng(day), _map(), consumed)` with a
## fresh empty `consumed` — and `build_day` is the most expensive call in this suite at roughly two
## thirds of a second for an early day and a second for a late one. Planning the same fourteen days
## ten times over was six or seven minutes of re-deriving an answer that nothing between the calls
## had changed, and none of the ten was checking anything the first one had not already produced.
##
## Every caller reads the plans and none writes to them, which is what makes one copy safe to
## share. **Two callers go round this on purpose and both have to.**
## `_test_scheduler_is_deterministic` is *about* `build_day` repeating itself, so a cache hit would
## be the test asking a dictionary rather than the scheduler; and the calm-memory sweeps pass a
## `used` set as a further argument, so their plans are a different question.
var _plans := {}

func _planned(day: int) -> Array[EventScheduler.Planned]:
	if not _plans.has(day):
		var consumed: Array[String] = []
		_plans[day] = EventScheduler.build_day(day, _rng(day), _map(), consumed)
	var found: Array[EventScheduler.Planned] = _plans[day]
	return found
