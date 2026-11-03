extends RefCounted
## **A booted scene recipe runs under the walk its clock runs on**: `main` hands the authored scene
## (`SceneRecipeRuntime.install()`) the spec the run flow started — a day's
## (`DayDirector.start_authored_day()`), or the escape city's section (`main._begin_the_scene()`) —
## and the day's clock is started on that same spec. Read off the booted game: the clock's spec
## (`DayController.spec`) and its length, and the settings the scene's events took from the spec
## they were installed under (`EventManager.use_the_spec()`: whether a torn poster sends a pursuer,
## whether what is sited after dawn keeps off the home's streets). A suite that boots `main`: every
## boot is handed a scratch-path save (`tests/booted_main.gd`).

const Boot := preload("res://tests/booted_main.gd")
const DAY_RECIPE := "res://scene-recipes/power-station-hall.json"
const ESCAPE_RECIPE := "res://scene-recipes/trailer-chase.json"

func run(t) -> void:
	t.gives_back_observers()
	await _test_a_day_scene_runs_under_the_days_spec(t)
	await _test_an_escape_scene_runs_under_the_sections_spec(t)

func _test_a_day_scene_runs_under_the_days_spec(t) -> void:
	_a_fresh_run()
	var booted: Boot.Booted = await Boot.boot(t, _scratch("day"),
			Boot.config(["--recipe", DAY_RECIPE]))
	var day := Boot.day(booted.main)
	var city := Boot.city(booted.main)
	t.check(day != null and city != null and day.spec.number == 1 and day.spec.poster_pursuits
			and day.spec.holds_the_home_streets,
			"the authored day's clock runs on a day's spec (day %d)" % (day.spec.number if day else -1))
	if day and city:
		_check_the_events_run_under(t, day, city, "the day scene")
	booted.free_all()

func _test_an_escape_scene_runs_under_the_sections_spec(t) -> void:
	_a_fresh_run()
	var booted: Boot.Booted = await Boot.boot(t, _scratch("escape"),
			Boot.config(["--recipe", ESCAPE_RECIPE]))
	var day := Boot.day(booted.main)
	var city := Boot.city(booted.main)
	t.check(day != null and city != null and not day.spec.poster_pursuits
			and not day.spec.holds_the_home_streets,
			"the authored escape's clock runs on the city section's spec")
	if day and city:
		_check_the_events_run_under(t, day, city, "the escape scene")
	booted.free_all()
	# The section the escape boot left on the run is not handed to the suites after this one.
	GameState.facts.escape_section = DaySpec.Section.NONE

## The scene's events took their settings from the spec the clock runs on, and the clock was
## started for that spec's length.
func _check_the_events_run_under(t, day: DayController, city: City, scene: String) -> void:
	t.check(city.events.ahead.sends_poster_pursuits == day.spec.poster_pursuits
			and city.events.ahead.holds_the_home_streets == day.spec.holds_the_home_streets,
			"%s's events run under the spec its clock runs on" % scene)
	t.check(is_equal_approx(day.time_total, day.spec.length),
			"%s's clock is started for that spec's length (%.1fs of %.1fs)"
			% [scene, day.time_total, day.spec.length])

## A suite that boots `main` hands it the run `GameState` holds, so each boot starts that run afresh:
## an escape boot leaves its section on the run (`RunFacts.escape_section`), which the next boot
## would read as an escape to go on with.
func _a_fresh_run() -> void:
	GameState.start_run(4242)

func _scratch(which: String) -> String:
	return "user://test_scene_recipe_boot_%s_%d.json" % [which, OS.get_process_id()]
