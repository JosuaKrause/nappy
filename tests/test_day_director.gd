extends RefCounted
## The day director alone: the one start every walk goes through (`DayDirector.start()`) and the one
## place a day ends (`finish_day()`).
##
## **The start on fakes.** The world comes from a `DayWorldSource` the director is handed, so a start
## here is handed a fake one standing a world of fakes — the city's dressing that records how it is
## dressed, a small map of its own, events that record how they are planned, a crowd, a resistance,
## her (stood in the tree with a real camera where a check reads the view she has) and the baby —
## with today's streets, the day's clock and the run's calendar real, since they
## are plain state. No city is generated and no day is planned, and the director is handed no
## `City`: an authored scene alone is handed one, a stand-in never built, to install itself into.
## What is checked is the director's own order, what each of the spec's settings makes it do, for a
## day, an authored scene's day and both sections of the escape, and that what the world says the
## walk is won at reaches the spec and the clock. That the real worlds start
## (the escape's building and city booted, the day's city through its fourteen days) is the finale
## and full-run suites' to show.
##
## **The end on a bare world**: a day clock and an event manager, no city, no player. The clock is
## `tests/ended_clock.gd`, the real countdown answering what ended the day as a case sets it, since
## its losing paths are the clock's own suite's. What a day's end
## settles — the cause `day_ended` carries, the calendar, the hand-over to the escape — is decided
## there, so it is checked there.

const SEED := 1717
const EndedClock := preload("res://tests/ended_clock.gd")

var _ended: Array = []
## A fresh run for every rig, handed to the director in place of the autoload.
var _run: RunState

func run(t: TestRunner) -> void:
	_test_a_timeout_costs_a_nerve_and_names_no_cause(t)
	_test_a_crying_day_is_named_by_what_landed_the_most(t)
	_test_a_day_lost_to_the_pelican_names_the_pelican(t)
	_test_a_hard_fail_is_named_by_its_reason(t)
	_test_a_won_day_moves_the_calendar_on(t)
	_test_a_won_last_day_with_every_task_done_hands_over(t)
	_test_a_scene_recipe_never_hands_over(t)
	_test_a_section_is_ended_but_not_settled(t)
	_test_a_city_section_won_carries_the_way_out(t)
	_test_a_day_starts_in_its_order(t)
	_test_the_city_section_starts_on_its_settings(t)
	_test_the_building_section_starts_with_no_city(t)
	_test_an_authored_scene_installs_in_place_of_the_plan(t)
	_test_each_start_setting_does_what_it_says(t)
	_test_the_start_flags_decide_only_a_walk_from_her_doorstep(t)
	_test_the_start_hands_on_the_ways_out_of_the_world(t)
	_test_the_start_hands_the_clock_her_and_her_front_door(t)
	_test_the_scenery_round_her_is_prepared_where_she_is_put_down(t)
	_test_a_won_walk_home_lights_the_fire_she_never_met(t)

func _on_day_ended(day: int, result: int, cause: String, elapsed: float) -> void:
	_ended.append([day, result, cause, elapsed])

## The day's number the last `day_ended` sent: a day's the calendar's, a section's its own.
func _day_sent() -> int:
	var sent: Array = _ended.back()
	return sent[0]

## What ended the day, as the last `day_ended` sent it (`LossCause`), `""` for a win or a timeout.
func _cause_sent() -> String:
	var sent: Array = _ended.back()
	return sent[2]

## The director over a bare world, on a run of its own freshly started on `SEED`, handed in the
## world as the game hands it (`use_the_world()`).
func _rig(t: TestRunner, spec := DaySpec.new()) -> Dictionary:
	_run = RunState.new()
	_run.start_run(SEED)
	var clock := EndedClock.new()
	clock.set_process(false)
	t.add_child(clock)
	clock.start(300.0)
	clock.tick(180.0)
	# The events' world: open ground drawn in a node the manager holds, and the run's own state
	# (`EventManager.setup_world()`, as the escape's building is handed its world).
	var events := EventManager.new()
	var map := WorldMap.open_ground()
	var holder := WorldContext.new()
	events.add_child(holder)
	map.world = holder
	events.setup_world(map, _run)
	t.add_child(events)
	var director := DayDirector.new(_run.calendar(), _run.facts(), _run.attempt_spend())
	# A world with no city: the open ground and its events, nobody in it.
	director.use_the_world(DayWorld.in_the_building(map, events, null, null, Vector2.ZERO,
			Vector2.DOWN, null), null, clock)
	director.use_the_spec(spec)
	_ended.clear()
	EventBus.day_ended.connect(_on_day_ended)
	return {"director": director, "clock": clock, "events": events, "nodes": [clock, events]}

func _put_away(rig: Dictionary) -> void:
	EventBus.day_ended.disconnect(_on_day_ended)
	for node: Node in rig["nodes"]:
		node.free()

func _test_a_timeout_costs_a_nerve_and_names_no_cause(t: TestRunner) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var end := director.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	t.check(_cause_sent() == "" and _day_sent() == 1 and not end.ends_a_section(),
			"a timeout on day 1 names no cause")
	t.check(is_equal_approx(end.lasted_seconds(), 180.0), "and reads the clock at the instant it ended")
	t.check(_ended == [[1, GameEnums.DayResult.LOST_TIMEOUT, "", 180.0]],
			"and sends day_ended once, with that cause and clock (%s)" % [_ended])
	t.check(_run.header().nerves() == Tuning.STARTING_NERVES - 1 and not end.ends_the_run()
			and not end.sends_the_run_back(), "the nerve is spent and the run goes on")
	_put_away(rig)

func _test_a_crying_day_is_named_by_what_landed_the_most(t: TestRunner) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	director.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(_cause_sent() == "self",
			"a crying day with nothing in the world that landed is her own")
	_put_away(rig)

## The pelican's share of the meter is its own group, never added to the cyclists' *(inbox #527 in
## azure-tapir)*, so a crying day it landed the most on is lost to the pelican, and one a cyclist
## landed the most on beside it is lost to the cyclist. Read off the cause `day_ended` carries: the
## two shares merged would name the cyclist both times, either one dropped would name the other
## both times.
func _test_a_day_lost_to_the_pelican_names_the_pelican(t: TestRunner) -> void:
	for case: Array in [[3.0, 5.0, "pelican"], [5.0, 3.0, "cyclist"]]:
		var rig := _rig(t)
		var director: DayDirector = rig["director"]
		var events: EventManager = rig["events"]
		var def := EventCatalogue.by_id("cyclist")
		var kid := events.spawn_extra(def, Vector2.ZERO)
		# Warned of as the pelican, as the director's rider is (`spawn_warned()` makes the
		# pelican of the roll its warning made).
		var pelican := events.spawn_warned(def,
				PackedVector2Array([Vector2.ZERO, Vector2(500.0, 0.0)]), true)
		t.check(pelican.is_pelican, "the rider warned of as the pelican is the pelican")
		var kid_landed: float = case[0]
		var pelican_landed: float = case[1]
		kid.excitement.accumulate_landed(kid_landed)
		pelican.excitement.accumulate_landed(pelican_landed)
		director.finish_day(GameEnums.DayResult.LOST_CRYING)
		t.check(_cause_sent() == case[2], ("with the cyclist landing %.0f and the pelican %.0f, "
				+ "the crying day is lost to the %s (got %s)") % [kid_landed, pelican_landed,
				case[2], _cause_sent()])
		events.clear()
		_put_away(rig)

func _test_a_hard_fail_is_named_by_its_reason(t: TestRunner) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var clock: EndedClock = rig["clock"]
	clock.struck_by = "charging_dog"
	director.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(_cause_sent() == "charging-dog",
			"a hard fail is named by the row that struck her")
	_put_away(rig)

func _test_a_won_day_moves_the_calendar_on(t: TestRunner) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(not end.continues_into_the_escape() and not end.ends_the_run() and _run.header().day() == 2,
			"a won day 1 is day 2 next")
	t.check(_cause_sent() == "", "and a win is named by nothing")
	_put_away(rig)

func _test_a_won_last_day_with_every_task_done_hands_over(t: TestRunner) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	_run.header().set_day(Tuning.RUN_LENGTH_DAYS)
	_run.resistance().set_progress(Tuning.RESISTANCE_GOAL)
	_run.resistance().record_the_sabotage()
	_run.header().set_nerves(Tuning.STARTING_NERVES - 2)
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(end.continues_into_the_escape(), "a won last day with every task done hands over")
	t.check(_run.header().nerves() == Tuning.STARTING_NERVES - 1,
			"and the won day gives a nerve back, as every won day does")
	t.check(_run.header().day() == Tuning.RUN_LENGTH_DAYS and not end.ends_the_run(),
			"and the calendar is left where it was for the escape to decide")
	_put_away(rig)

func _test_a_scene_recipe_never_hands_over(t: TestRunner) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	_run.header().set_day(Tuning.RUN_LENGTH_DAYS)
	_run.resistance().set_progress(Tuning.RESISTANCE_GOAL)
	_run.resistance().record_the_sabotage()
	director.use_escape_follows(false)
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(not end.continues_into_the_escape(), "a scene recipe's won last day never hands over")
	_put_away(rig)

func _test_a_section_is_ended_but_not_settled(t: TestRunner) -> void:
	var spec := DaySpec.for_section(DaySpec.Section.BUILDING, 300.0)
	var rig := _rig(t, spec)
	var director: DayDirector = rig["director"]
	var clock: EndedClock = rig["clock"]
	clock.says = "She started crying."
	var end := director.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(end.ends_a_section() and _day_sent() == 15 and _cause_sent() == "self",
			"a section sends day_ended under its own number and cause")
	t.check(end.loss_reason() == "She started crying.",
			"and its end carries the clock's own sentence, for the summary to say")
	t.check(_run.header().nerves() == Tuning.STARTING_NERVES,
			"and leaves what it costs to the section's own flow")
	_put_away(rig)

## The way she left the city, as the clock recorded it, is carried on the end: the page's `out` count
## and the epilogue's tunnel-or-bridge line read it there (`main._finish_the_section()`,
## `SummaryModel.epilogue()`).
func _test_a_city_section_won_carries_the_way_out(t: TestRunner) -> void:
	for way: int in [CityExit.Kind.TUNNEL, CityExit.Kind.BRIDGE]:
		var rig := _rig(t, DaySpec.for_section(DaySpec.Section.CITY, 60.0))
		var director: DayDirector = rig["director"]
		var clock: EndedClock = rig["clock"]
		clock.way_out = way
		var end := director.finish_day(GameEnums.DayResult.WON)
		t.check(end.ends_a_section() and end.exit_taken() == way and end.loss_reason() == ""
				and _cause_sent() == "", ("a city section won by way %d carries it on its end, named"
				+ " by no loss (got %d)") % [way, end.exit_taken()])
		_put_away(rig)

# ------------------------------------------------------------------ the start ---

## The ways out of a fake city world a walk out of the city is won at, far from where she starts.
const EXITS := {CityExit.Kind.TUNNEL: Vector2(900.0, 200.0), CityExit.Kind.BRIDGE: Vector2(-900.0, 200.0)}

## Everything the fakes below are asked, in the order they are asked, as `"what detail"` lines.
var _asked: Array[String] = []

## The world the start's `stood` callback was handed, for a check that it is the one stood.
var _stood: DayWorld

## Starts `spec` on `director` handed the two callbacks the run flow hands it, each noting itself
## among what the fakes are asked: `started N` once the walk is begun, `stood` once its world stands.
func _start(director: DayDirector, spec: DaySpec) -> Array[String]:
	_stood = null
	return director.start(spec, func() -> void: _asked.append("started %d" % spec.day_number()),
			func(world: DayWorld) -> void:
				_stood = world
				_asked.append("stood"))

## A director handed a fake world source standing a world of fakes for `spec`: a city world, its
## parts each a fake of its own (the dressing, the map, the crowd) and today's streets as data, or
## with `in_building` the building's, which has no city. A city world is won where `spec`'s goal
## says, as the main scene's answers it: at her front door on the city's map on a walk home, at the
## two ways out (`EXITS`) on a walk out of the city. `scene` is an authored scene to play, or null;
## a city world it is played in hands it a stand-in for the whole city, as the main scene hands the
## real one only where a scene is played. Returns the director and the parts a check reads.
func _start_rig(t: TestRunner, spec: DaySpec, in_building := false, scene: AuthoredScene = null) -> Dictionary:
	_run = RunState.new()
	_run.start_run(SEED)
	_asked.clear()
	var clock := DayController.new()
	clock.set_process(false)
	t.add_child(clock)
	var events := _FakeEvents.new(_asked)
	events.name = "Events"
	var player := _FakeStroller.new(_asked)
	var baby := _FakeBaby.new(_asked)
	var resistance := _FakeResistance.new(_asked)
	var city: _FakeDressing = null
	var map: _FakeMap = null
	var crowd: _FakeCrowd = null
	var scene_city: _SceneCity = null
	var world: DayWorld
	if in_building:
		world = DayWorld.in_the_building(WorldMap.open_ground(), events, player, baby,
				Vector2(30.0, 40.0), Vector2.UP, _run.calendar().day_rng(1, "a seed of its own"))
	else:
		city = _FakeDressing.new(_asked)
		city.name = "City"
		map = _FakeMap.new(Vector2i(8, 8))
		crowd = _FakeCrowd.new(_asked)
		if scene:
			scene_city = _SceneCity.new()
		var home_map: CityMap = map if spec.goal_kind() == DaySpec.Goal.HOME else null
		var exits: Dictionary = EXITS if spec.goal_kind() == DaySpec.Goal.CITY_EDGE else {}
		world = DayWorld.in_the_city(city, map, DayStreets.new(), crowd, events, player, baby,
				Vector2(100.0, 200.0), home_map, exits, Vector2.DOWN, scene_city)
	var worlds := _FakeWorlds.new(world, _asked)
	var director := DayDirector.new(_run.calendar(), _run.facts(), _run.attempt_spend())
	director.use_the_world(null, resistance, clock)
	director.use_worlds(worlds)
	director.use_the_scene(scene)
	var lines: Array[String] = []
	director.use_trace(RecordingTrace.new(lines))
	# What `main._new_director()` hands, the run's `--spawn` target and `--meters` override bound
	# in: where the developer's flags start her, and what they do to the bars. Here a start on the
	# city map's doorstep, as `--spawn` with no target answers, and no change to the bars.
	# The meters callable notes itself with whether the day's clock is already running.
	director.use_the_flags(
			func() -> Vector2: return map.doorstep_world_position(),
			func(_the_baby: Baby) -> void:
				_asked.append("meters %s" % (clock.seconds_total() > 0.0)))
	var nodes: Array[Node] = [clock, events, player, baby, resistance]
	if city:
		nodes.append_array([city, crowd])
	if scene_city:
		nodes.append(scene_city)
	return {"director": director, "events": events, "player": player, "baby": baby,
			"resistance": resistance, "city": city, "map": map, "scene_city": scene_city,
			"world": world, "clock": clock, "worlds": worlds, "lines": lines, "nodes": nodes,
			"spec": spec}

func _put_the_start_away(rig: Dictionary) -> void:
	for node: Node in rig["nodes"]:
		node.free()

## Whether `_asked` holds every line of `expected` in that order, others allowed between.
func _asked_in_order(expected: Array[String]) -> bool:
	var at := 0
	for line in _asked:
		if at < expected.size() and line == expected[at]:
			at += 1
	return at == expected.size()

## Whether any line of `_asked` begins with one of `prefixes`.
func _asked_any(prefixes: Array[String]) -> bool:
	for line in _asked:
		for prefix in prefixes:
			if line.begins_with(prefix):
				return true
	return false

## A day's start: announced begun, its world stood and announced, the city dressed, the events
## planned round her start on the run's own stream and one-shots, the resistance's day, the events
## streamed round her, the day's crowd, her put down facing the street with the baby awake, and the
## clock running. The dawn is photographed before any of it.
func _test_a_day_starts_in_its_order(t: TestRunner) -> void:
	var spec := DaySpec.for_day(1, 210.0)
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	_run.resistance().pick_up_package()
	var errors := _start(director, spec)
	t.check(errors.is_empty(), "a day's start stands")
	t.check(_asked_in_order(["started 1", "stand %d" % spec.number, "stood", "dress start_day",
			"set_act 1", "plan %s" % spec.number, "refresh_street_trees", "resistance 1 210",
			"stream (100.0, 200.0)", "crowd start_day", "reset_at (100.0, 200.0) (0.0, 1.0)",
			"baby reset"]),
			"a day is announced, stood, dressed, planned, peopled and put down in that order (%s)"
			% [_asked])
	t.check(_stood == rig["world"], "the world announced as it stands is the one the source stood")
	var events: _FakeEvents = rig["events"]
	t.check(events.planned_with == spec and events.planned_around == Vector2(100.0, 200.0),
			"its events are planned on its own spec round where the world puts her")
	t.check(events.planned_on.seed == _run.calendar().day_rng(1, "events").seed,
			"on the run's own events stream for the day")
	t.check(is_same(events.one_shots_spent, _run.attempt_spend().consumed_one_shots()),
			"and they spend the run's one-shots")
	t.check(not _asked.has("baby force_sleep") and not _asked.has("tint"),
			"the baby starts awake and a grown tree is tinted as it grows, not here")
	t.check(not _run.resistance().is_carrying_package(), "the dawn is photographed before it starts")
	var clock: DayController = rig["clock"]
	t.check(clock.is_running() and is_equal_approx(clock.seconds_total(), 210.0)
			and clock.spec() == spec, "the clock runs the day's own spec and length")
	_put_the_start_away(rig)

## The escape's city starts on the city section's settings: no photograph, no resistance, nobody on
## its streets, the baby asleep, its events planned on the escape's stream with none of the run's
## one-shots, and its handed-in walk tinted and written to the run log; announced begun and stood
## the way a day is.
func _test_the_city_section_starts_on_its_settings(t: TestRunner) -> void:
	var spec := DaySpec.for_section(DaySpec.Section.CITY, 180.0)
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	_run.resistance().pick_up_package()
	_start(director, spec)
	var events: _FakeEvents = rig["events"]
	t.check(_asked_in_order(["started %d" % DaySpec.CITY_DAY, "stood", "dress start_day",
			"daylight 0.0", "plan %d" % DaySpec.CITY_DAY, "tint", "stream (100.0, 200.0)",
			"crowd clear", "reset_at (100.0, 200.0) (0.0, 1.0)", "baby reset", "baby force_sleep"]),
			"the city section is announced, dressed at night, planned, tinted, emptied and put down "
			+ "asleep (%s)" % [_asked])
	t.check(events.planned_on.seed == _run.calendar().day_rng(1, "finale").seed,
			"its events are planned on the escape's own stream of the run's day")
	t.check(not is_same(events.one_shots_spent, _run.attempt_spend().consumed_one_shots())
			and events.one_shots_spent.is_empty(), "from a list of its own, empty")
	var city: _FakeDressing = rig["city"]
	t.check(city.tinted == events.walk(), "the kerb tint is the walk it planned")
	var lines: Array[String] = rig["lines"]
	t.check(lines == ["plan finale: 0 open streets, 0 placements"],
			"and the walk's shape is written to the run log (%s)" % [lines])
	t.check(not _asked.has("resistance 1 180") and _run.resistance().is_carrying_package(),
			"no resistance runs and no dawn is photographed")
	_put_the_start_away(rig)

## The escape's building is a world with no city: nothing is dressed, no crowd is started, its events
## are planned on the building's own seed, and she is put down where the building says, facing its
## way, with the baby asleep.
func _test_the_building_section_starts_with_no_city(t: TestRunner) -> void:
	var spec := DaySpec.for_section(DaySpec.Section.BUILDING, 180.0)
	var rig := _start_rig(t, spec, true)
	var director: DayDirector = rig["director"]
	_start(director, spec)
	var events: _FakeEvents = rig["events"]
	var world: DayWorld = rig["world"]
	t.check(events.planned_on == world.plan_rng(), "its events are planned on the building's own seed")
	t.check(_asked_in_order(["started %d" % DaySpec.BUILDING_DAY, "stood",
			"plan %d" % DaySpec.BUILDING_DAY, "stream (30.0, 40.0)",
			"reset_at (30.0, 40.0) (0.0, -1.0)", "baby reset", "baby force_sleep"]),
			"the building is announced, planned and put down facing up with the baby asleep (%s)"
			% [_asked])
	t.check(not _asked_any(["dress", "crowd"]),
			"and nothing is dressed and nobody is on its streets")
	var clock: DayController = rig["clock"]
	t.check(clock.is_running() and is_equal_approx(clock.seconds_total(), 180.0),
			"its clock runs the section's length")
	_put_the_start_away(rig)

## An authored scene's day is the same start with the scene's install in place of the plan: the city
## dressed with the recipe's own closures, the clock already running as the scene installs over it,
## no plan, no resistance's day and nobody put down by the director. It is announced begun and stood
## as every walk is. What the install could not stand is handed back.
func _test_an_authored_scene_installs_in_place_of_the_plan(t: TestRunner) -> void:
	var spec := DaySpec.for_day(1, 210.0)
	var scene := _FakeScene.new(_asked)
	scene.problems.assign(["setup.player.at must be open ground"])
	var rig := _start_rig(t, spec, false, scene)
	var director: DayDirector = rig["director"]
	scene.clock = rig["clock"]
	var errors := _start(director, spec)
	t.check(errors == scene.problems, "the scene's problems are the start's")
	t.check(_asked_in_order(["started 1", "stood", "dress start_recipe_day", "install running"]),
			"the city is dressed with the recipe's closures and the scene installs over a running "
			+ "clock (%s)" % [_asked])
	t.check(rig["scene_city"] != null and scene.installed_with == [rig["scene_city"], rig["player"],
			rig["baby"], spec, rig["resistance"]],
			"into the world stood for it, the city whole among it, under the walk's spec")
	t.check(not _asked_any(["plan", "resistance", "reset_at"]),
			"and nothing is planned, started or put down for it (%s)" % [_asked])
	_put_the_start_away(rig)
	scene.free()

## **Each of the start's own settings does what it says.** A day and the escape's city section
## differ in every one of them, so each is read off the two starts side by side: the dawn
## photographed (`photographs_the_dawn()`), the resistance's day (`runs_the_resistance()`), the baby
## asleep (`starts_with_the_baby_asleep()`), the run's one-shots spent (`spends_the_one_shots()`),
## the stream the plan is drawn on (`events_stream()`), the act's spent calm handed over
## (`shuts_the_spent_calm()`) and the night held (`runs_the_daylight_down()`). Where she starts
## (`start_point()`) is `_test_the_start_flags_decide_only_a_walk_from_her_doorstep`'s.
func _test_each_start_setting_does_what_it_says(t: TestRunner) -> void:
	var day := _started_on(t, DaySpec.for_day(1, 210.0))
	var section := _started_on(t, DaySpec.for_section(DaySpec.Section.CITY, 210.0))
	var said := {
		"photographs_the_dawn": "the dawn is photographed",
		"runs_the_resistance": "the resistance's day runs",
		"starts_with_the_baby_asleep": "the baby starts asleep",
		"spends_the_one_shots": "the run's one-shots are spent",
		"events_stream": "the plan's stream is the run's events stream",
		"shuts_the_spent_calm": "the act's spent calm is handed over",
		"runs_the_daylight_down": "the light is left to run down",
	}
	for setting: String in said:
		var on_a_day: bool = day[setting]
		var in_the_escape: bool = section[setting]
		t.check(on_a_day == _says(DaySpec.for_day(1, 210.0), setting)
				and in_the_escape == _says(DaySpec.for_section(DaySpec.Section.CITY, 210.0), setting)
				and on_a_day != in_the_escape,
				"%s exactly where the spec says so (%s on a day, %s in the escape)"
				% [said[setting], on_a_day, in_the_escape])

## What `spec`'s `setting` says, as the yes or no `_started_on()` reads: the stream's is whether it
## is the run's events stream.
func _says(spec: DaySpec, setting: String) -> bool:
	var answer: Variant = spec.call(setting)
	if answer is String:
		return answer == "events"
	return answer

## What one start on `spec` did that each start setting decides, keyed by the setting's method.
func _started_on(t: TestRunner, spec: DaySpec) -> Dictionary:
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	_run.resistance().pick_up_package()
	director.start(spec)
	var events: _FakeEvents = rig["events"]
	var map: _FakeMap = rig["map"]
	var seen := {
		"photographs_the_dawn": not _run.resistance().is_carrying_package(),
		"runs_the_resistance": _asked_any(["resistance"]),
		"starts_with_the_baby_asleep": _asked.has("baby force_sleep"),
		"spends_the_one_shots": is_same(events.one_shots_spent,
				_run.attempt_spend().consumed_one_shots()),
		"events_stream": events.planned_on.seed == _run.calendar().day_rng(1, "events").seed,
		"shuts_the_spent_calm": map.handed_spent,
		"runs_the_daylight_down": not _asked.has("daylight 0.0"),
	}
	_put_the_start_away(rig)
	return seen

## `--spawn` decides where she starts on the boot's first walk from her doorstep, and on no walk that
## starts anywhere else.
func _test_the_start_flags_decide_only_a_walk_from_her_doorstep(t: TestRunner) -> void:
	for spec: DaySpec in [DaySpec.for_day(1, 210.0),
			DaySpec.for_section(DaySpec.Section.CITY, 210.0)]:
		var rig := _start_rig(t, spec)
		var director: DayDirector = rig["director"]
		director.use_first_day(true)
		director.start(spec)
		var player: _FakeStroller = rig["player"]
		var map: _FakeMap = rig["map"]
		var doorstep := map.doorstep_world_position()
		var meters := _asked.filter(func(line: String) -> bool: return line.begins_with("meters"))
		if spec.start_point() == DaySpec.Start.DOORSTEP:
			t.check(meters == ["meters true"], "the bars' override is asked once, with the day "
					+ "running, on a walk from her doorstep (%s)" % [meters])
			t.check(player.put_at == doorstep, "the flag's spawn, its doorstep with no target, "
					+ "decides a walk from her doorstep (%s)" % [player.put_at])
		else:
			t.check(meters.is_empty(), "and no walk that starts anywhere else asks it")
			t.check(player.put_at == Vector2(100.0, 200.0),
					"and a walk from anywhere else starts where its world puts her (%s)"
					% [player.put_at])
		_put_the_start_away(rig)
	var later := _start_rig(t, DaySpec.for_day(1, 210.0))
	(later["director"] as DayDirector).start(later["spec"])
	t.check(not _asked.any(func(line: String) -> bool: return line.begins_with("meters")),
			"and a walk that is not the boot's first never asks the bars' override")
	_put_the_start_away(later)

## **The ways out the world answers are the walk's.** The escape's city is won only at a way out the
## spec holds (`DaySpec.exit_points()`, read by the day's clock), and the world it stands in is what
## knows where they are (`DayWorld.exits()`): the start hands them on, so the clock ends the section
## won by the tunnel once she stands at the tunnel the world named, and not before.
func _test_the_start_hands_on_the_ways_out_of_the_world(t: TestRunner) -> void:
	var spec := DaySpec.for_section(DaySpec.Section.CITY, 180.0)
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	director.start(spec)
	var clock: DayController = rig["clock"]
	var player: _FakeStroller = rig["player"]
	player.position = Vector2(100.0, 200.0)
	clock.tick(0.01)
	t.check(clock.is_running(), "standing where she starts wins nothing")
	player.position = EXITS[CityExit.Kind.TUNNEL]
	clock.tick(0.01)
	t.check(not clock.is_running() and clock.exit_taken() == CityExit.Kind.TUNNEL,
			"at the tunnel the world names, the section is won by the tunnel (%s, %d)"
			% [clock.is_running(), clock.exit_taken()])
	_put_the_start_away(rig)

## **Her and her front door's map are the clock's from the world.** A day is won at her own front door
## with the baby asleep, checked by the day's clock on the map the door is on (`DayWorld.home_map()`):
## with the clock set up as the main scene sets it up, handed only the run, the start hands it her and
## that map, so the baby falling asleep with her on the door wins the day.
func _test_the_start_hands_the_clock_her_and_her_front_door(t: TestRunner) -> void:
	var spec := DaySpec.for_day(1, 210.0)
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	var clock: DayController = rig["clock"]
	clock.setup(_run)
	var won: Array[int] = []
	var note_won := func(result: GameEnums.DayResult) -> void:
		won.append(result)
	clock.day_finished.connect(note_won)
	director.start(spec)
	var map: _FakeMap = rig["map"]
	var player: _FakeStroller = rig["player"]
	map.home = Vector2(40.0, 40.0)
	player.position = Vector2(40.0, 40.0)
	EventBus.return_phase_started.emit()
	t.check(won == [GameEnums.DayResult.WON],
			"the baby asleep with her at the door on the map the world named wins the day (%s)"
			% [won])
	_put_the_start_away(rig)

## **The scenery round where she is put down is ready for the walk's first frame.** Once she is put
## down, and before the clock runs, the city's dressing is asked to prepare its scenery over what her
## camera shows (`CityDressing.prepare_scenery_in()`): the world her camera sees at its zoom, centred
## where she stands. An authored scene's day asks the same once the scene has installed itself; the
## stand-in scene places nobody, so she is where the test stood her. Her camera is a real one under
## the fake her, current, in the tree, as the game's own is.
func _test_the_scenery_round_her_is_prepared_where_she_is_put_down(t: TestRunner) -> void:
	for scene_day: bool in [false, true]:
		var spec := DaySpec.for_day(1, 210.0)
		var scene: _FakeScene = _FakeScene.new(_asked) if scene_day else null
		var rig := _start_rig(t, spec, false, scene)
		if scene:
			scene.clock = rig["clock"]
		var camera := _stand_her_in_the_tree(t, rig)
		var player: _FakeStroller = rig["player"]
		player.position = Vector2(300.0, 420.0)
		_start(rig["director"], spec)
		var city: _FakeDressing = rig["city"]
		var where := player.global_position
		var shown := player.get_viewport_rect().size / camera.zoom
		var walk := "an authored scene's day" if scene_day else "a day"
		t.check(city.prepared.size() == 1 and city.prepared[0].get_center().is_equal_approx(where)
				and city.prepared[0].size.is_equal_approx(shown),
				"on %s the scenery is prepared once, over the %s her camera shows round %s (%s)"
				% [walk, shown, where, city.prepared])
		var order: Array[String] = ["reset_at (100.0, 200.0) (0.0, 1.0)", "prepare", "baby reset"]
		if scene_day:
			order.assign(["install running", "prepare"])
		t.check(_asked_in_order(order), "%s: after she is put down and before the day runs (%s)"
				% [walk, _asked])
		_put_the_start_away(rig)
		if scene:
			scene.free()

## Stands the rig's her in the tree with a camera of her own, named as her scene names it, at the
## scene's zoom and current, as the game's own her stands: the view the start prepares round her is
## read off it. **Not interpolated**: the real her resets her camera's interpolation when she is put
## down (`Stroller.reset_at()`), so it draws from where she now stands; the fake her does not, and a
## camera off interpolation is the same answer without it.
func _stand_her_in_the_tree(t: TestRunner, rig: Dictionary) -> Camera2D:
	var player: _FakeStroller = rig["player"]
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(2.0, 2.0)
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.add_child(camera)
	t.add_child(player)
	camera.make_current()
	return camera

## **A won walk home lights the fire she never met, where she stands; nothing else does.** Day 3's
## fire burns on a won day it was never met on (`EventManager.light_what_she_never_met()`), asked at
## her position when the day ends, so a won day leaves the run its fire, scar and shell. A lost day
## gives everything back, so it asks nothing, and the escape's city section, won at a way out rather
## than at her door, asks nothing either. Each is a start in a city world, then its end.
func _test_a_won_walk_home_lights_the_fire_she_never_met(t: TestRunner) -> void:
	var cases: Array[Array] = [
		[DaySpec.for_day(1, 210.0), GameEnums.DayResult.WON, true, "a won day walked home"],
		[DaySpec.for_day(1, 210.0), GameEnums.DayResult.LOST_TIMEOUT, false, "a lost day"],
		[DaySpec.for_section(DaySpec.Section.CITY, 180.0), GameEnums.DayResult.WON, false,
				"the escape's city section won"],
	]
	for case: Array in cases:
		var spec: DaySpec = case[0]
		var rig := _start_rig(t, spec)
		_stand_her_in_the_tree(t, rig)
		var director: DayDirector = rig["director"]
		director.start(spec)
		var player: _FakeStroller = rig["player"]
		player.position = Vector2(640.0, 96.0)
		director.finish_day(case[1])
		var lit := _asked.filter(func(line: String) -> bool: return line.begins_with("light"))
		var wanted: Array = []
		if case[2]:
			wanted.append("light (640.0, 96.0)")
		t.check(lit == wanted, "%s asks %s to be lit (%s)"
				% [case[3], "what she never met" if case[2] else "nothing", lit])
		_put_the_start_away(rig)

# ------------------------------------------------------------------- fakes ---

## Stands the one world it is handed, for every spec, and notes each ask.
class _FakeWorlds extends DayWorldSource:
	var _world: DayWorld
	var _asked: Array[String]

	func _init(world: DayWorld, asked: Array[String]) -> void:
		_world = world
		_asked = asked

	## Overrides DayWorldSource.stand.
	func stand(spec: DaySpec) -> DayWorld:
		_asked.append("stand %d" % spec.number)
		return _world

## The city's dressing, noting how it is dressed, tinted and prepared. No `City`: what the director asks of
## the city scene is all it answers.
class _FakeDressing extends CityDressing:
	var _asked: Array[String]
	var tinted: RouteSource
	## Every view the scenery was asked to be prepared over, in order.
	var prepared: Array[Rect2] = []

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides CityDressing.start_day.
	func start_day(_state: CityState, _day: int, _rng: RandomNumberGenerator,
			_spec: DaySpec = null) -> void:
		_asked.append("dress start_day")

	## Overrides CityDressing.start_recipe_day.
	func start_recipe_day(_state: CityState, _day: int, _rng: RandomNumberGenerator,
			_spec: DaySpec = null) -> void:
		_asked.append("dress start_recipe_day")

	## Overrides CityDressing.set_act.
	func set_act(act: int) -> void:
		_asked.append("set_act %d" % act)

	## Overrides CityDressing.set_daylight.
	func set_daylight(fraction: float) -> void:
		_asked.append("daylight %.1f" % fraction)

	## Overrides CityDressing.refresh_street_trees.
	func refresh_street_trees() -> void:
		_asked.append("refresh_street_trees")

	## Overrides CityDressing.tint_the_route.
	func tint_the_route(route: RouteSource) -> void:
		tinted = route
		_asked.append("tint")

	## Overrides CityDressing.prepare_scenery_in.
	func prepare_scenery_in(view: Rect2) -> void:
		prepared.append(view)
		_asked.append("prepare")

## A map that notes whether the act's spent calm was handed to it, and whose one home tile is at
## `home`, every other point a road.
class _FakeMap extends CityMap:
	var handed_spent := false
	var home := Vector2.INF

	## Overrides CityMap.tile_type_at_world.
	func tile_type_at_world(world_position: Vector2) -> GameEnums.TileType:
		if world_position.distance_to(home) < 1.0:
			return GameEnums.TileType.HOME
		return GameEnums.TileType.ROAD

	## Overrides CityMap.set_spent_calm.
	func set_spent_calm(_blocks: Array[Vector2i]) -> void:
		handed_spent = true

	## Overrides CityMap.set_fenced_park_state.
	func set_fenced_park_state(_block: Vector2i, _act: int, _today_act: int) -> void:
		handed_spent = true

## A crowd that notes whether it was started or cleared.
class _FakeCrowd extends Crowd:
	var _asked: Array[String]

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides Crowd.start_day.
	func start_day(_day: int, _rng: RandomNumberGenerator, _focus := Vector2.INF,
			_populate := true, _city_view := false, _uniform_walkers := false,
			_walker_multiplier := 1.0, _car_multiplier := 1.0) -> void:
		_asked.append("crowd start_day")

	## Overrides Crowd.clear.
	func clear() -> void:
		_asked.append("crowd clear")

	## Overrides Crowd.agent_count.
	func agent_count() -> int:
		return 0

## Events that note how they are planned and streamed, and plan nothing.
class _FakeEvents extends EventManager:
	var _asked: Array[String]
	var planned_with: DaySpec
	var planned_on: RandomNumberGenerator
	var one_shots_spent: Array[String] = []
	var planned_around := Vector2.INF
	var _the_walk := FinalePlanner.Plan.new()

	## The real manager's parts, idle over an empty world, so what this does not override answers as
	## a manager with nothing planned.
	func _init(asked: Array[String]) -> void:
		super()
		_asked = asked

	## Overrides EventManager.start_day.
	func start_day(spec: DaySpec, rng: RandomNumberGenerator, consumed_one_shots: Array[String],
			focus := Vector2.ZERO) -> void:
		planned_with = spec
		planned_on = rng
		one_shots_spent = consumed_one_shots
		planned_around = focus
		_asked.append("plan %d" % spec.number)

	## Overrides EventManager.stream_around.
	func stream_around(at: Vector2) -> void:
		_asked.append("stream %s" % at)

	## Overrides EventManager.walk.
	func walk() -> RouteSource:
		return _the_walk

	## Overrides EventManager.plans.
	func plans() -> Array[EventPlan]:
		var none: Array[EventPlan] = []
		return none

	## Overrides EventManager.light_what_she_never_met.
	func light_what_she_never_met(at: Vector2) -> bool:
		_asked.append("light %s" % at)
		return false

## A resistance that notes its day being started.
class _FakeResistance extends ResistanceDirector:
	var _asked: Array[String]

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides ResistanceDirector.start_day.
	func start_day(day: int, _rng: RandomNumberGenerator, day_length: float) -> void:
		_asked.append("resistance %d %d" % [day, roundi(day_length)])

## Her, noting where she is put down and facing which way, and standing there.
class _FakeStroller extends Stroller:
	var _asked: Array[String]
	var put_at := Vector2.INF

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides Stroller.reset_at.
	func reset_at(where: Vector2, look: Vector2 = Vector2.DOWN) -> void:
		put_at = where
		position = where
		_asked.append("reset_at %s %s" % [where, look])

## The baby, noting being reset and put to sleep.
class _FakeBaby extends Baby:
	var _asked: Array[String]

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides Baby.reset.
	func reset() -> void:
		_asked.append("baby reset")

	## Overrides Baby.force_sleep.
	func force_sleep() -> void:
		_asked.append("baby force_sleep")

## The city whole an authored scene is installed into, standing for the real one the main scene
## hands a scene; never built or put in a world, and asked nothing by the director.
class _SceneCity extends City:
	pass

## An authored scene noting what it was installed into, and whether the clock was running then.
class _FakeScene extends AuthoredScene:
	var _asked: Array[String]
	var problems: Array[String] = []
	var installed_with: Array = []
	var clock: DayController

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides AuthoredScene.install.
	func install(city: City, _simulation: WorldSimulation, player: Stroller, baby: Baby,
			spec: DaySpec, resistance: ResistanceDirector = null) -> Array[String]:
		installed_with = [city, player, baby, spec, resistance]
		_asked.append("install %s" % ("running" if clock.is_running() else "stopped"))
		return problems
