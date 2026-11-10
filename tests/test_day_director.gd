extends RefCounted
## The day director alone: the one start every walk goes through (`DayDirector.start()`) and the one
## place a day ends (`finish_day()`).
##
## **The start on fakes.** The world comes from a `DayWorldSource` the director is handed, so a start
## here is handed a fake one standing a world of fakes — a city that records how it is dressed, events
## that record how they are planned, a crowd, a resistance, her and the baby — with the day's clock
## and the run's calendar real, since they are plain state. No city is generated and no day is
## planned: what is checked is the director's own order, what each of the spec's settings makes it
## do, for a day, an authored scene's day and both sections of the escape, and that what the world
## says the walk is won at reaches the spec and the clock. That the real worlds start
## (the escape's building and city booted, the day's city through its fourteen days) is the finale
## and full-run suites' to show.
##
## **The end on a bare world**: a day clock and an event manager, no city, no player. What a day's end
## settles — the cause `day_ended` carries, the calendar, the hand-over to the escape — is decided
## there, so it is checked there.

const SEED := 1717

var _ended: Array = []
## A fresh run for every rig, handed to the director in place of the autoload.
var _run: RunState

func run(t) -> void:
	_test_a_timeout_costs_a_nerve_and_names_no_cause(t)
	_test_a_crying_day_is_named_by_what_landed_the_most(t)
	_test_a_day_lost_to_the_pelican_names_the_pelican(t)
	_test_a_hard_fail_is_named_by_its_reason(t)
	_test_a_won_day_moves_the_calendar_on(t)
	_test_a_won_last_day_with_every_task_done_hands_over(t)
	_test_a_scene_recipe_never_hands_over(t)
	_test_a_won_day_with_a_player_and_no_city_ends(t)
	_test_a_section_is_ended_but_not_settled(t)
	_test_a_day_starts_in_its_order(t)
	_test_the_city_section_starts_on_its_settings(t)
	_test_the_building_section_starts_with_no_city(t)
	_test_an_authored_scene_installs_in_place_of_the_plan(t)
	_test_each_start_setting_does_what_it_says(t)
	_test_the_start_flags_decide_only_a_walk_from_her_doorstep(t)
	_test_the_start_hands_on_the_ways_out_of_the_world(t)
	_test_the_start_hands_the_clock_her_and_her_front_door(t)

func _on_day_ended(day: int, result: int, cause: String, elapsed: float) -> void:
	_ended.append([day, result, cause, elapsed])

## The director over a bare world, on a run of its own freshly started on `SEED`.
func _rig(t, spec := DaySpec.new()) -> Dictionary:
	_run = RunState.new()
	_run.start_run(SEED)
	var clock := DayController.new()
	clock.set_process(false)
	t.add_child(clock)
	clock.start(300.0)
	clock.time_remaining = 120.0
	# The events' world: open ground drawn in a node the manager holds, and the run's own state
	# (`EventManager.setup_world()`, as the escape's building is handed its world).
	var events := EventManager.new()
	var map := WorldMap.open_ground()
	var holder := WorldContext.new()
	events.add_child(holder)
	map.world = holder
	events.setup_world(map, _run)
	t.add_child(events)
	var director := DayDirector.new(_run.calendar, _run.facts, _run.attempt_spend, RunConfig.parse(PackedStringArray(), "", true))
	director.use_the_world(null, events, null, null, null, clock)
	director.spec = spec
	_ended.clear()
	EventBus.day_ended.connect(_on_day_ended)
	return {"director": director, "nodes": [clock, events]}

func _put_away(rig: Dictionary) -> void:
	EventBus.day_ended.disconnect(_on_day_ended)
	for node: Node in rig["nodes"]:
		node.free()

func _test_a_timeout_costs_a_nerve_and_names_no_cause(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var end := director.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	t.check(end.cause == "" and end.finished_day == 1 and not end.is_section,
			"a timeout on day 1 names no cause")
	t.check(is_equal_approx(end.elapsed_seconds, 180.0), "and reads the clock at the instant it ended")
	t.check(_ended == [[1, GameEnums.DayResult.LOST_TIMEOUT, "", 180.0]],
			"and sends day_ended once, with that cause and clock (%s)" % [_ended])
	t.check(_run.header.nerves == Tuning.STARTING_NERVES - 1 and not end.run_over
			and not end.goes_back, "the nerve is spent and the run goes on")
	_put_away(rig)

func _test_a_crying_day_is_named_by_what_landed_the_most(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	t.check(director.landed_by_group().is_empty(), "the bare world landed nothing")
	t.check(director.finish_day(GameEnums.DayResult.LOST_CRYING).cause == "self",
			"a crying day with nothing in the world that landed is her own")
	_put_away(rig)

## The pelican's share of the meter is its own group, never added to the cyclists' *(inbox #527 in
## azure-tapir)*, so a crying day it landed the most on is lost to the pelican.
func _test_a_day_lost_to_the_pelican_names_the_pelican(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var def := EventCatalogue.by_id("cyclist")
	var kid := director.events.spawn_extra(def, Vector2.ZERO)
	# Warned of as the pelican, as the director's rider is (`spawn_warned()` makes the pelican of the
	# roll its warning made).
	var pelican := director.events.spawn_warned(def,
			PackedVector2Array([Vector2.ZERO, Vector2(500.0, 0.0)]), true)
	t.check(pelican.is_pelican, "the rider warned of as the pelican is the pelican")
	kid.excitement.accumulate_landed(3.0)
	pelican.excitement.accumulate_landed(5.0)
	t.check(director.landed_by_group() == {"cyclist": 3.0, "pelican": 5.0},
			"the pelican's share is its own group (%s)" % [director.landed_by_group()])
	t.check(director.finish_day(GameEnums.DayResult.LOST_CRYING).cause == "pelican",
			"so a crying day the pelican landed the most on is lost to the pelican")
	director.events.clear()
	_put_away(rig)

func _test_a_hard_fail_is_named_by_its_reason(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	director.day.hard_fail_reason = "charging_dog"
	t.check(director.finish_day(GameEnums.DayResult.LOST_HARD_FAIL).cause == "charging-dog",
			"a hard fail is named by the row that struck her")
	_put_away(rig)

func _test_a_won_day_moves_the_calendar_on(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(not end.hands_over_to_the_escape and not end.run_over and _run.header.day == 2,
			"a won day 1 is day 2 next")
	t.check(end.cause == "", "and a win is named by nothing")
	_put_away(rig)

## `finish_day()` requires only the clock and the run: a won day walked home with a player but no
## city (nothing to light the unmet fire in) still ends.
func _test_a_won_day_with_a_player_and_no_city_ends(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var player := Stroller.new()
	director.player = player
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(end.finished_day == 1 and _run.header.day == 2, "the day ends and the calendar moves")
	player.free()
	_put_away(rig)

func _test_a_won_last_day_with_every_task_done_hands_over(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	_run.header.day = Tuning.RUN_LENGTH_DAYS
	_run.resistance.progress = Tuning.RESISTANCE_GOAL
	_run.resistance.sabotage_done = true
	_run.header.nerves = Tuning.STARTING_NERVES - 2
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(end.hands_over_to_the_escape, "a won last day with every task done hands over")
	t.check(_run.header.nerves == Tuning.STARTING_NERVES - 1,
			"and the won day gives a nerve back, as every won day does")
	t.check(_run.header.day == Tuning.RUN_LENGTH_DAYS and not end.run_over,
			"and the calendar is left where it was for the escape to decide")
	_put_away(rig)

func _test_a_scene_recipe_never_hands_over(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	_run.header.day = Tuning.RUN_LENGTH_DAYS
	_run.resistance.progress = Tuning.RESISTANCE_GOAL
	_run.resistance.sabotage_done = true
	director.escape_follows = false
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(not end.hands_over_to_the_escape, "a scene recipe's won last day never hands over")
	_put_away(rig)

func _test_a_section_is_ended_but_not_settled(t) -> void:
	var spec := DaySpec.new()
	spec.section = DaySpec.Section.BUILDING
	spec.number = 15
	var rig := _rig(t, spec)
	var director: DayDirector = rig["director"]
	director.day.failure_reason = "She started crying."
	director.day.exit_reached = CityEdge.Kind.TUNNEL
	var end := director.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(end.is_section and end.finished_day == 15 and end.cause == "self",
			"a section sends day_ended under its own number and cause")
	t.check(end.reason == "She started crying." and end.exit_reached == CityEdge.Kind.TUNNEL,
			"and its end carries the clock's own sentence and the way out, for the summary to say")
	t.check(_run.header.nerves == Tuning.STARTING_NERVES,
			"and leaves what it costs to the section's own flow")
	_put_away(rig)

# ------------------------------------------------------------------ the start ---

## The ways out of a fake city world a walk out of the city is won at, far from where she starts.
const EXITS := {CityEdge.Kind.TUNNEL: Vector2(900.0, 200.0), CityEdge.Kind.BRIDGE: Vector2(-900.0, 200.0)}

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

## A director handed a fake world source standing a world of fakes for `spec`: a city world, or with
## `in_building` the building's, which has no city. A city world is won where `spec`'s goal says, as
## the main scene's answers it: at her front door on the city's map on a walk home, at the two ways
## out (`EXITS`) on a walk out of the city. `scene` is an authored scene to play, or null. Returns the
## director and the parts a check reads.
func _start_rig(t, spec: DaySpec, in_building := false, scene: AuthoredScene = null) -> Dictionary:
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
	var city: _FakeCity = null
	var world: DayWorld
	if in_building:
		world = DayWorld.in_the_building(WorldMap.open_ground(), events, player, baby,
				Vector2(30.0, 40.0), Vector2.UP, _run.calendar.day_rng(1, "a seed of its own"))
	else:
		city = _FakeCity.new(_asked)
		city.name = "City"
		var home_map: CityMap = city.map if spec.goal_kind() == DaySpec.Goal.HOME else null
		var exits: Dictionary = EXITS if spec.goal_kind() == DaySpec.Goal.CITY_EDGE else {}
		world = DayWorld.in_the_city(city, city.map, events, player, baby, Vector2(100.0, 200.0),
				home_map, exits)
	var worlds := _FakeWorlds.new(world, _asked)
	var config := RunConfig.parse(PackedStringArray(), "", true)
	var director := DayDirector.new(_run.calendar, _run.facts, _run.attempt_spend, config)
	director.use_the_world(null, null, resistance, null, null, clock)
	director.use_worlds(worlds)
	director.use_the_scene(scene)
	var lines: Array[String] = []
	director.use_trace(RunTrace.recording(lines))
	var nodes: Array[Node] = [clock, events, player, baby, resistance]
	if city:
		nodes.append_array([city, city.crowd])
	return {"director": director, "events": events, "player": player, "baby": baby,
			"resistance": resistance, "city": city, "world": world, "clock": clock,
			"worlds": worlds, "lines": lines, "nodes": nodes, "spec": spec}

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
func _test_a_day_starts_in_its_order(t) -> void:
	var spec := DaySpec.for_day(1, 210.0)
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	_run.resistance.carrying_package = true
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
	t.check(events.planned_on.seed == _run.calendar.day_rng(1, "events").seed,
			"on the run's own events stream for the day")
	t.check(is_same(events.one_shots_spent, _run.attempt_spend.consumed_one_shots),
			"and they spend the run's one-shots")
	t.check(not _asked.has("baby force_sleep") and not _asked.has("tint"),
			"the baby starts awake and a grown tree is tinted as it grows, not here")
	t.check(not _run.resistance.carrying_package, "the dawn is photographed before it starts")
	var clock: DayController = rig["clock"]
	t.check(clock.is_running() and is_equal_approx(clock.seconds_total(), 210.0)
			and clock.spec == spec, "the clock runs the day's own spec and length")
	_put_the_start_away(rig)

## The escape's city starts on the city section's settings: no photograph, no resistance, nobody on
## its streets, the baby asleep, its events planned on the escape's stream with none of the run's
## one-shots, and its handed-in walk tinted and written to the run log; announced begun and stood
## the way a day is.
func _test_the_city_section_starts_on_its_settings(t) -> void:
	var spec := DaySpec.for_section(DaySpec.Section.CITY, 180.0)
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	_run.resistance.carrying_package = true
	_start(director, spec)
	var events: _FakeEvents = rig["events"]
	t.check(_asked_in_order(["started %d" % DaySpec.CITY_DAY, "stood", "dress start_day",
			"daylight 0.0", "plan %d" % DaySpec.CITY_DAY, "tint", "stream (100.0, 200.0)",
			"crowd clear", "reset_at (100.0, 200.0) (0.0, 1.0)", "baby reset", "baby force_sleep"]),
			"the city section is announced, dressed at night, planned, tinted, emptied and put down "
			+ "asleep (%s)" % [_asked])
	t.check(events.planned_on.seed == _run.calendar.day_rng(1, "finale").seed,
			"its events are planned on the escape's own stream of the run's day")
	t.check(not is_same(events.one_shots_spent, _run.attempt_spend.consumed_one_shots)
			and events.one_shots_spent.is_empty(), "from a list of its own, empty")
	var city: _FakeCity = rig["city"]
	t.check(city.tinted == events.walk(), "the kerb tint is the walk it planned")
	var lines: Array[String] = rig["lines"]
	t.check(lines == ["plan finale: 0 open streets, 0 placements"],
			"and the walk's shape is written to the run log (%s)" % [lines])
	t.check(not _asked.has("resistance 1 180") and _run.resistance.carrying_package,
			"no resistance runs and no dawn is photographed")
	_put_the_start_away(rig)

## The escape's building is a world with no city: nothing is dressed, no crowd is started, its events
## are planned on the building's own seed, and she is put down where the building says, facing its
## way, with the baby asleep.
func _test_the_building_section_starts_with_no_city(t) -> void:
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
func _test_an_authored_scene_installs_in_place_of_the_plan(t) -> void:
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
	t.check(scene.installed_with == [rig["city"], rig["player"], rig["baby"], spec, rig["resistance"]],
			"into the world stood for it, under the walk's spec")
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
func _test_each_start_setting_does_what_it_says(t) -> void:
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
func _started_on(t, spec: DaySpec) -> Dictionary:
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	_run.resistance.carrying_package = true
	director.start(spec)
	var events: _FakeEvents = rig["events"]
	var city: _FakeCity = rig["city"]
	var seen := {
		"photographs_the_dawn": not _run.resistance.carrying_package,
		"runs_the_resistance": _asked_any(["resistance"]),
		"starts_with_the_baby_asleep": _asked.has("baby force_sleep"),
		"spends_the_one_shots": is_same(events.one_shots_spent,
				_run.attempt_spend.consumed_one_shots),
		"events_stream": events.planned_on.seed == _run.calendar.day_rng(1, "events").seed,
		"shuts_the_spent_calm": (city.map as _FakeMap).handed_spent,
		"runs_the_daylight_down": not _asked.has("daylight 0.0"),
	}
	_put_the_start_away(rig)
	return seen

## `--spawn` decides where she starts on the boot's first walk from her doorstep, and on no walk that
## starts anywhere else.
func _test_the_start_flags_decide_only_a_walk_from_her_doorstep(t) -> void:
	for spec: DaySpec in [DaySpec.for_day(1, 210.0),
			DaySpec.for_section(DaySpec.Section.CITY, 210.0)]:
		var rig := _start_rig(t, spec)
		var director: DayDirector = rig["director"]
		director.first_day = true
		director.start(spec)
		var player: _FakeStroller = rig["player"]
		var city: _FakeCity = rig["city"]
		var doorstep := city.map.doorstep_world_position()
		if spec.start_point() == DaySpec.Start.DOORSTEP:
			t.check(player.put_at == doorstep, "the flag's spawn, its doorstep with no target, "
					+ "decides a walk from her doorstep (%s)" % [player.put_at])
		else:
			t.check(player.put_at == Vector2(100.0, 200.0),
					"and a walk from anywhere else starts where its world puts her (%s)"
					% [player.put_at])
		_put_the_start_away(rig)

## **The ways out the world answers are the walk's.** The escape's city is won only at a way out the
## spec holds (`DaySpec.exit_points()`, read by the day's clock), and the world it stands in is what
## knows where they are (`DayWorld.exits()`): the start hands them on, so the clock ends the section
## won by the tunnel once she stands at the tunnel the world named, and not before.
func _test_the_start_hands_on_the_ways_out_of_the_world(t) -> void:
	var spec := DaySpec.for_section(DaySpec.Section.CITY, 180.0)
	var rig := _start_rig(t, spec)
	var director: DayDirector = rig["director"]
	director.start(spec)
	var clock: DayController = rig["clock"]
	var player: _FakeStroller = rig["player"]
	player.position = Vector2(100.0, 200.0)
	clock.tick(0.01)
	t.check(clock.is_running(), "standing where she starts wins nothing")
	player.position = EXITS[CityEdge.Kind.TUNNEL]
	clock.tick(0.01)
	t.check(not clock.is_running() and clock.exit_taken() == CityEdge.Kind.TUNNEL,
			"at the tunnel the world names, the section is won by the tunnel (%s, %d)"
			% [clock.is_running(), clock.exit_taken()])
	_put_the_start_away(rig)

## **Her and her front door's map are the clock's from the world.** A day is won at her own front door
## with the baby asleep, checked by the day's clock on the map the door is on (`DayWorld.home_map()`):
## with the clock set up as the main scene sets it up, handed only the run, the start hands it her and
## that map, so the baby falling asleep with her on the door wins the day.
func _test_the_start_hands_the_clock_her_and_her_front_door(t) -> void:
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
	var city: _FakeCity = rig["city"]
	var player: _FakeStroller = rig["player"]
	(city.map as _FakeMap).home = Vector2(40.0, 40.0)
	player.position = Vector2(40.0, 40.0)
	EventBus.return_phase_started.emit()
	t.check(won == [GameEnums.DayResult.WON],
			"the baby asleep with her at the door on the map the world named wins the day (%s)"
			% [won])
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

## A city that notes how it is dressed and tinted, on a small map of its own and a crowd that notes
## how it is started. Never built or put in a world.
class _FakeCity extends City:
	var _asked: Array[String]
	var tinted: RouteSource

	func _init(asked: Array[String]) -> void:
		_asked = asked
		map = _FakeMap.new(Vector2i(8, 8))
		crowd = _FakeCrowd.new(asked)

	## Overrides City.start_day.
	func start_day(_state: CityState, _day: int, _rng: RandomNumberGenerator,
			_spec: DaySpec = null) -> void:
		_asked.append("dress start_day")

	## Overrides City.start_recipe_day.
	func start_recipe_day(_state: CityState, _day: int, _rng: RandomNumberGenerator,
			_spec: DaySpec = null) -> void:
		_asked.append("dress start_recipe_day")

	## Overrides City.set_act.
	func set_act(act: int) -> void:
		_asked.append("set_act %d" % act)

	## Overrides City.set_daylight.
	func set_daylight(fraction: float) -> void:
		_asked.append("daylight %.1f" % fraction)

	## Overrides City.refresh_street_trees.
	func refresh_street_trees() -> void:
		_asked.append("refresh_street_trees")

	## Overrides City.tint_the_route.
	func tint_the_route(route: RouteSource) -> void:
		tinted = route
		_asked.append("tint")

	## Overrides City.calm_summary.
	func calm_summary() -> String:
		return ""

	## Overrides City.closure_summary.
	func closure_summary() -> String:
		return ""

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
	func plans() -> Array[EventScheduler.Planned]:
		var none: Array[EventScheduler.Planned] = []
		return none

## A resistance that notes its day being started.
class _FakeResistance extends ResistanceDirector:
	var _asked: Array[String]

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides ResistanceDirector.start_day.
	func start_day(day: int, _rng: RandomNumberGenerator, day_length: float) -> void:
		_asked.append("resistance %d %d" % [day, roundi(day_length)])

## Her, noting where she is put down and facing which way.
class _FakeStroller extends Stroller:
	var _asked: Array[String]
	var put_at := Vector2.INF

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides Stroller.reset_at.
	func reset_at(where: Vector2, look: Vector2 = Vector2.DOWN) -> void:
		put_at = where
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

## An authored scene noting what it was installed into, and whether the clock was running then.
class _FakeScene extends AuthoredScene:
	var _asked: Array[String]
	var problems: Array[String] = []
	var installed_with: Array = []
	var clock: DayController

	func _init(asked: Array[String]) -> void:
		_asked = asked

	## Overrides AuthoredScene.install.
	func install(city: City, player: Stroller, baby: Baby, spec: DaySpec,
			resistance: ResistanceDirector = null) -> Array[String]:
		installed_with = [city, player, baby, spec, resistance]
		_asked.append("install %s" % ("running" if clock.is_running() else "stopped"))
		return problems
