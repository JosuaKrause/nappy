class_name RunHeader
extends RunSubState
## Who and where a run is: its seed, the player's presentation, the calendar, nerves, how it ended
## and how long it has been played. Nothing here is spent by an attempt, so a lost day gives none
## of it back (the nerve a loss costs is `GameState.finish_day()`'s, not a give-back).

var run_seed: int = 0
## A run owns its presentation just as it owns its seed. Days and scene changes only read it.
var player_is_male := false
var day: int = 1
var nerves: int = Tuning.STARTING_NERVES
var ending: GameEnums.Ending = GameEnums.Ending.NONE
var play_seconds: float = 0.0

## Back to day 1 with every nerve and no ending. The seed and the presentation are the run's
## identity and are set by `GameState.start_run()`, not here.
func reset() -> void:
	day = 1
	nerves = Tuning.STARTING_NERVES
	ending = GameEnums.Ending.NONE
	play_seconds = 0.0

func to_data() -> Dictionary:
	return {
		"run_seed": run_seed,
		"player_is_male": player_is_male,
		"day": day,
		"nerves": nerves,
		"ending": ending,
		"play_seconds": play_seconds,
	}

func restore(data: Dictionary) -> void:
	run_seed = int(data["run_seed"])
	player_is_male = bool(data["player_is_male"])
	day = int(data["day"])
	nerves = int(data["nerves"])
	ending = int(data["ending"]) as GameEnums.Ending
	play_seconds = float(data["play_seconds"])
