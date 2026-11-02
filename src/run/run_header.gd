class_name RunHeader
extends RunSubState
## Who and where a run is: its seed, the player's presentation, the calendar, nerves, how it ended
## and how long it has been played. Nothing here is spent by an attempt, so a lost day gives none
## of it back (the nerve a loss costs is `GameState.calendar.finish_day()`'s, not a give-back).

var run_seed: int = 0
## A run owns its presentation just as it owns its seed. Days and scene changes only read it.
var player_is_male := false
var day: int = 1
var nerves: int = Tuning.STARTING_NERVES
var ending: GameEnums.Ending = GameEnums.Ending.NONE
## Physics ticks the world has actually been moving this run — advanced by one a tick by exactly one
## owner, `main._physics_process()`, while a day — a section of the escape included — is walking or
## returning and the tree is not paused. **Counted in ticks, never in frame time** (inbox #866 in minty-dolphin): a
## frame drawn late runs no more ticks than the engine steps, so a lag spike slows the
## game rather than adding time, and two machines playing the same run read the same time. Never
## shown during play; the ending screen is the only place it is read, through `play_seconds()`.
var play_ticks: int = 0

## `play_ticks` in seconds, at the physics tick rate (`Engine.physics_ticks_per_second`): what the
## ending screen shows (`GameState.format_clock()`) and what the save holds. A function rather than
## a field, since a part declares each field once in its data (`tests/test_run_state.gd`).
func play_seconds() -> float:
	return float(play_ticks) / Engine.physics_ticks_per_second

## Back to day 1 with every nerve and no ending. The seed and the presentation are the run's
## identity and are set by `GameState.start_run()`, not here.
func reset() -> void:
	day = 1
	nerves = Tuning.STARTING_NERVES
	ending = GameEnums.Ending.NONE
	play_ticks = 0

func to_data() -> Dictionary:
	return {
		"run_seed": run_seed,
		"player_is_male": player_is_male,
		"day": day,
		"nerves": nerves,
		"ending": ending,
		"play_seconds": play_seconds(),
	}

func restore(data: Dictionary) -> void:
	run_seed = int(data["run_seed"])
	player_is_male = bool(data["player_is_male"])
	day = int(data["day"])
	nerves = int(data["nerves"])
	ending = int(data["ending"]) as GameEnums.Ending
	# Saved as seconds (`to_data()`), so any save's seconds load back to the nearest tick.
	play_ticks = roundi(float(data["play_seconds"]) * Engine.physics_ticks_per_second)
