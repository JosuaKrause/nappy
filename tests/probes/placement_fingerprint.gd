extends RefCounted
## **Every placement a walk starts with, printed one line each**, so a change to how a walk is
## planned can be shown to place exactly what it placed before: the row, where it stands (tile and
## world point), its heading, its role, its clock (when it comes, how often it comes again, how aged
## it arrives) and its path. Not a suite: it prints rather than asserts. Run by name, before and
## after a change, and compare the two outputs:
##
##     tools/test.sh probes/placement_fingerprint.gd > before.txt
##     grep '^FP ' before.txt > before.fp     (and the same for after; `diff` the two)
##
## Three kinds of walk, each started the way the game starts it, through a real `City` or
## `InteriorScene` and the walk's `EventManager`:
##
## - **the escape's city** (`main._plan_the_finale_city()`) on the eight seeds record
##   minty-quail-8 fingerprinted, on the `--start-escape city` boot's stream (the run on day 1) and
##   on the stream a played run reaches it on (day 14);
## - **the building** (`main._start_section()`'s building half) on a few seeds;
## - **a day** (`DayDirector.start_day()`'s city and events half) on days 1, 4, 8, 9, 10, 12 and 14
##   of two seeds.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const BuildingEvents := preload("res://tests/building_events.gd")

const ESCAPE_SEEDS: Array[int] = [4242, 1, 77, 9001, 4216201080, 5, 23, 31337]
const ESCAPE_DAYS: Array[int] = [1, Tuning.RUN_LENGTH_DAYS]
const BUILDING_SEEDS: Array[int] = [4242, 1, 77]
const DAY_SEEDS: Array[int] = [4242, 77]
const DAYS: Array[int] = [1, 4, 8, 9, 10, 12, 14]

func run(t) -> void:
	var lines := 0
	for seed_value in ESCAPE_SEEDS:
		for day in ESCAPE_DAYS:
			lines += _the_escape_city(t, seed_value, day)
	for seed_value in BUILDING_SEEDS:
		lines += _the_building(t, seed_value)
	for seed_value in DAY_SEEDS:
		for day in DAYS:
			lines += _a_day(t, seed_value, day)
	print("FP_TOTAL %d placements" % lines)
	t.check(lines > 0, "there were placements to print (%d)" % lines)

## The escape's city, built and dressed as `main._build_the_finale_city()` does and planned as
## `main._plan_the_finale_city()` does.
func _the_escape_city(t, seed_value: int, day: int) -> int:
	GameState.start_run(seed_value)
	GameState.header.day = day
	var spec := DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	GameState.attempt_spend.city_state.begin_day(city.map.block_plans, day)
	city.start_day(GameState.attempt_spend.city_state, day, GameState.calendar.day_rng(day, "closures"),
			spec)
	var start := FinalePlanner.service_exit_world_position(city.map)
	var none: Array[String] = []
	city.events.start_day(spec, GameState.calendar.day_rng(day, "finale"), none, start)
	var printed := _print("escape seed %d day %d" % [seed_value, day], city.map,
			city.events.plans())
	city.free()
	return printed

## The building, with its events started as every entry into the section starts them.
func _the_building(t, seed_value: int) -> int:
	GameState.start_run(seed_value)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := GameState.calendar.day_rng(GameState.header.day, "finale-interior")
	var events := BuildingEvents.events_in(t, scene, rng)
	var printed := _print("building seed %d" % seed_value, scene.map, events.plans())
	events.free()
	scene.free()
	return printed

## A day, as `DayDirector.start_day()` plans it: the city's own morning, then the events.
func _a_day(t, seed_value: int, day: int) -> int:
	GameState.start_run(seed_value)
	GameState.header.day = day
	var spec := DaySpec.for_day(day)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	GameState.attempt_spend.city_state.begin_day(city.map.block_plans, day)
	city.start_day(GameState.attempt_spend.city_state, day, GameState.calendar.day_rng(day, "closures"),
			spec)
	var consumed: Array[String] = []
	city.events.start_day(spec, GameState.calendar.day_rng(day), consumed,
			city.map.doorstep_world_position())
	var printed := _print("day seed %d day %d" % [seed_value, day], city.map,
			city.events.plans())
	city.free()
	return printed

func _print(walk: String, map: WorldMap, plans: Array[EventScheduler.Planned]) -> int:
	print("FP_WALK %s | %d placements" % [walk, plans.size()])
	for i in plans.size():
		var plan := plans[i]
		var tile := map.world_to_tile(plan.position) if plan.is_placed() else Vector2i(-1, -1)
		print("FP %s | %d | %s | tile %s | at %s | facing %s | role %d | comes_in %.3f | every %.3f"
				% [walk, i, plan.def.id, tile, plan.position, plan.facing, plan.role,
				plan.comes_in, plan.repeat_every]
				+ " | after %.3f | aged %.3f | at_her %s | mast %s | path %s"
				% [plan.repeat_after, plan.arrives_aged, plan.at_her, plan.mast_id, plan.path])
	return plans.size()
