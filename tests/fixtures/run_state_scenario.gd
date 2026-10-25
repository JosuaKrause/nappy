extends RefCounted
## One run with a value in every field the save carries, built only through `GameState`'s public
## fields and methods so it builds the same on any build of the game. `tests/test_run_state.gd`
## replays it and compares the result with `tests/fixtures/run_state_saved_by_main.json`, which this
## scenario wrote on the build that kept the run's state by hand (see that suite's header).

const SEED := 20261025

## Day 6 of a normal run: some of everything spent and done before the dawn the retry would return
## to, `begin_day()` photographing it, and then more of everything after the dawn.
static func build() -> void:
	GameState.start_run(SEED)
	GameState.choose_mode(false)
	GameState.day = 4
	GameState.begin_day()
	GameState.day = 6
	GameState.nerves = 3
	GameState.play_seconds = 321.5
	GameState.complete_resistance_step(0)
	GameState.complete_resistance_step(1)
	GameState.fail_resistance_step(2)
	GameState.consumed_one_shots.append("spent_before_the_dawn")
	GameState.add_scar("scarred_before_the_dawn", Vector2(10.5, 20.25))
	_burn(Vector2i(30, 30))
	GameState.posters.paste(Vector2i(4, 5), 0, false, 1)
	GameState.posters.tears += 1
	GameState.posters.pasted_through = 5
	GameState.pelican.draws = 3
	GameState.settled_in[5] = Vector2i(7, 8)
	GameState.begin_day()
	GameState.complete_resistance_step(3)
	GameState.fail_resistance_step(4)
	GameState.sabotage_done = true
	GameState.resistance_carrying_package = true
	GameState.consumed_one_shots.append("spent_after_the_dawn")
	GameState.add_scar("scarred_after_the_dawn", Vector2(120.0, 80.0))
	_burn(Vector2i(31, 31))
	GameState.posters.paste(Vector2i(9, 9), 1, true, -1)
	GameState.posters.pasted_through = 6
	GameState.pelican.draws = 11
	GameState.settled_in[6] = Vector2i(2, 3)
	GameState.remember_fenced_park(Vector2i(2, 3), 2)
	GameState.record_completed_alley_tile(Vector2i(77, 78))
	GameState.escape_section = 1

static func _burn(block: Vector2i) -> void:
	var plan := BlockPlan.new()
	plan.steps = [
		BlockPlan.Step.new(GameEnums.BlockPurpose.RESIDENTIAL, 1, GameEnums.BlockCause.SCHEDULED),
		BlockPlan.Step.new(GameEnums.BlockPurpose.BURNT_OUT, 1, GameEnums.BlockCause.FIRE),
	]
	GameState.city_state.apply_cause({block: plan}, block, GameEnums.BlockCause.FIRE, 6)

## What the save file holds, as JSON-safe values (what a read back from disk is).
static func written() -> Dictionary:
	return JSON.parse_string(JSON.stringify(GameSave.file_data(true)))

## What the save file holds after the day was lost: the run given back to its dawn, a nerve spent.
static func after_a_loss() -> Dictionary:
	GameState.finish_day(GameEnums.DayResult.LOST_CRYING)
	return JSON.parse_string(JSON.stringify(GameSave.file_data(false)))
