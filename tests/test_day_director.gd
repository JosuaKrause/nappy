extends RefCounted
## `DayDirector.finish_day()` on a bare world: a day clock and an event manager, no city, no player.
## What a day's end settles — the cause `day_ended` carries, the calendar, the hand-over to the escape
## — is decided there, so it is checked there. `DayDirector.start_day()` needs a city: its order is
## pinned in `tests/test_resistance.gd` (`_test_a_day_is_built_in_its_order`) on the light real world
## that suite builds.

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
	_test_a_won_day_with_a_player_and_no_city_ends(t)
	_test_a_section_is_ended_but_not_settled(t)

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
	var events := EventManager.new()
	t.add_child(events)
	var director := DayDirector.new(_run, RunConfig.parse(PackedStringArray(), "", true))
	director.use_the_world(null, events, null, null, null, clock)
	director.spec = spec
	_ended.clear()
	EventBus.day_ended.connect(_on_day_ended)
	return {"director": director, "nodes": [clock, events]}

func _put_away(rig: Dictionary) -> void:
	EventBus.day_ended.disconnect(_on_day_ended)
	for node: Node in rig["nodes"]:
		node.free()
	_run.free()

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
	t.check(director.loss_cause(GameEnums.DayResult.LOST_CRYING) == "self",
			"a crying day with nothing in the world that landed is her own")
	t.check(director.landed_by_group().is_empty(), "the bare world landed nothing")
	_put_away(rig)

## The pelican's share of the meter is its own group, never added to the cyclists' *(inbox #527 in
## azure-tapir)*, so a crying day it landed the most on is lost to the pelican.
func _test_a_day_lost_to_the_pelican_names_the_pelican(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var def := EventCatalogue.by_id("cyclist")
	var kid := EventInstance.new()
	kid.setup(def, Vector2.ZERO)
	var pelican := EventInstance.new()
	pelican.setup(def, Vector2.ZERO)
	pelican.is_pelican = true
	kid.accumulate_landed(3.0)
	pelican.accumulate_landed(5.0)
	director.events._instances.assign([kid, pelican])
	t.check(director.landed_by_group() == {"cyclist": 3.0, "pelican": 5.0},
			"the pelican's share is its own group (%s)" % [director.landed_by_group()])
	t.check(director.loss_cause(GameEnums.DayResult.LOST_CRYING) == "pelican",
			"so a crying day the pelican landed the most on is lost to the pelican")
	director.events._instances.clear()
	kid.free()
	pelican.free()
	_put_away(rig)

func _test_a_hard_fail_is_named_by_its_reason(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	director.day.hard_fail_reason = "charging_dog"
	t.check(director.loss_cause(GameEnums.DayResult.LOST_HARD_FAIL) == "charging-dog",
			"a hard fail is named by the row that struck her")
	t.check(director.loss_cause(GameEnums.DayResult.WON) == "", "a win is named by nothing")
	_put_away(rig)

func _test_a_won_day_moves_the_calendar_on(t) -> void:
	var rig := _rig(t)
	var director: DayDirector = rig["director"]
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(not end.hands_over_to_the_escape and not end.run_over and _run.header.day == 2,
			"a won day 1 is day 2 next")
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
	t.check(director.hands_over_to_the_escape(GameEnums.DayResult.WON),
			"a won last day with every task done hands over")
	director.escape_follows = false
	t.check(not director.hands_over_to_the_escape(GameEnums.DayResult.WON),
			"a scene recipe never does")
	director.escape_follows = true
	_run.header.nerves = Tuning.STARTING_NERVES - 2
	var end := director.finish_day(GameEnums.DayResult.WON)
	t.check(_run.header.nerves == Tuning.STARTING_NERVES - 1,
			"and the won day gives a nerve back, as every won day does")
	t.check(end.hands_over_to_the_escape and _run.header.day == Tuning.RUN_LENGTH_DAYS
			and not end.run_over, "and the calendar is left where it was for the escape to decide")
	_put_away(rig)

func _test_a_section_is_ended_but_not_settled(t) -> void:
	var spec := DaySpec.new()
	spec.section = DaySpec.Section.BUILDING
	spec.number = 15
	var rig := _rig(t, spec)
	var director: DayDirector = rig["director"]
	var end := director.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(end.is_section and end.finished_day == 15 and end.cause == "self",
			"a section sends day_ended under its own number and cause")
	t.check(_run.header.nerves == Tuning.STARTING_NERVES,
			"and leaves what it costs to the section's own flow")
	_put_away(rig)
