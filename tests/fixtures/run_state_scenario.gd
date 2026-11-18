extends RefCounted
## One run with a value in every field the save carries, built on a `RunState` the caller made and
## hands in. The calls are the operations on the parts that own the fields (`run.header().day()`,
## `run.attempt_spend().scars()`, `run.facts().remember_fenced_park()`), the same values the build that
## kept the state by hand wrote. `tests/test_run_state.gd`
## replays it and compares the result with `tests/fixtures/run_state_saved_by_main.json`, which this
## scenario wrote on the build that kept the run's state by hand (see that suite's header).

const SEED := 20261025

## Day 6 of a normal run: some of everything spent and done before the dawn the retry would return
## to, `begin_day()` photographing it, and then more of everything after the dawn.
static func build(run: RunState) -> void:
	run.start_run(SEED)
	run.calendar().choose_mode(false)
	run.header().set_day(4)
	run.calendar().begin_day()
	run.header().set_day(6)
	run.header().set_nerves(3)
	run.header().set_play_ticks(9645)  # 321.5 s at 30 ticks a second
	run.complete_resistance_step(0)
	run.complete_resistance_step(1)
	run.fail_resistance_step(2)
	run.attempt_spend().consumed_one_shots().append("spent_before_the_dawn")
	run.add_scar("scarred_before_the_dawn", Vector2(10.5, 20.25))
	_burn(run, Vector2i(30, 30))
	run.posters().paste(Vector2i(4, 5), 0, false, 1)
	GivenRun.tears(run, run.posters().tears_made() + 1)
	GivenRun.pasted_through(run, 5)
	GivenRun.pelican_draws(run, 3)
	GivenRun.settled(run, 5, Vector2i(7, 8))
	run.calendar().begin_day()
	run.complete_resistance_step(3)
	run.fail_resistance_step(4)
	run.resistance().record_the_sabotage()
	run.resistance().pick_up_package()
	run.attempt_spend().consumed_one_shots().append("spent_after_the_dawn")
	run.add_scar("scarred_after_the_dawn", Vector2(120.0, 80.0))
	_burn(run, Vector2i(31, 31))
	run.posters().paste(Vector2i(9, 9), 1, true, -1)
	GivenRun.pasted_through(run, 6)
	GivenRun.pelican_draws(run, 11)
	GivenRun.settled(run, 6, Vector2i(2, 3))
	run.facts().remember_fenced_park(Vector2i(2, 3), 2)
	run.facts().record_completed_alley_tile(Vector2i(77, 78))
	run.facts().set_escape_section(1)

static func _burn(run: RunState, block: Vector2i) -> void:
	var plan := BlockPlan.of(GameEnums.BlockPurpose.RESIDENTIAL).then(GameEnums.BlockPurpose.BURNT_OUT,
			1, GameEnums.BlockCause.FIRE)
	run.attempt_spend().block_arcs().apply_cause({block: plan}, block, GameEnums.BlockCause.FIRE, 6)

## The day lost on the run: it is given back to its dawn, a nerve spent.
static func lose_a_day(run: RunState) -> void:
	run.calendar().finish_day(GameEnums.DayResult.LOST_CRYING)
