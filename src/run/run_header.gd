class_name RunHeader
extends RunSubState
## Who and where a run is: its seed, the player's presentation, the calendar, nerves, how it ended
## and how long it has been played. Nothing here is spent by an attempt, so a lost day gives none
## of it back (the nerve a loss costs is `RunCalendar.finish_day()`'s, not a give-back).

var _run_seed: int = 0
## A run owns its presentation just as it owns its seed. Days and scene changes only read it.
var _player_is_male := false
var _day: int = 1
var _nerves: int = Tuning.STARTING_NERVES
var _ending: GameEnums.Ending = GameEnums.Ending.NONE
## Physics ticks the world has actually been moving this run — advanced by one a tick by exactly one
## owner, `main._physics_process()`, while a day — a section of the escape included — is walking or
## returning and the tree is not paused. **Counted in ticks, never in frame time** (inbox #866 in minty-dolphin): a
## frame drawn late runs no more ticks than the engine steps, so a lag spike slows the
## game rather than adding time, and two machines playing the same run read the same time. Never
## shown during play; the ending screen is the only place it is read, through `play_seconds()`.
## **Only ever grows during a run**: a lost day's retry does not give it back (the header is not
## spent by an attempt) and going back to a checkpoint, zero included, keeps it instead of taking
## the dawn's value; only a new game from the title starts it at zero (inbox #920 in plaid-penguin). A save holds
## and loads it as it is.
var _play_ticks: int = 0

## The seed the city and every day's streams are drawn from (`RunCalendar.day_rng()`,
## `RunState.run_rng()`).
func run_seed() -> int:
	return _run_seed

## Makes `seed_value` the run's seed. `RunState.start_run()` is what begins a run on one.
func use_seed(seed_value: int) -> void:
	_run_seed = seed_value

## Whether the parent pushing the pram is the father, drawn from the run's own stream at its start or
## chosen by `--parent`.
func parent_is_father() -> bool:
	return _player_is_male

func set_parent_is_father(father: bool) -> void:
	_player_is_male = father

## The calendar day, 1 to `Tuning.RUN_LENGTH_DAYS`; it stays on the last one while the escape is
## walked.
func day() -> int:
	return _day

## Puts the run on `for_day`: the calendar's won day (`RunCalendar.finish_day()`) and `--day`.
func set_day(for_day: int) -> void:
	_day = for_day

func nerves() -> int:
	return _nerves

## The nerves left: what a loss spends and a won day gives back (`RunCalendar`), and `--nerves`.
func set_nerves(count: int) -> void:
	_nerves = count

## How the run ended, `NONE` while it goes on.
func ending() -> GameEnums.Ending:
	return _ending

func set_ending(which: GameEnums.Ending) -> void:
	_ending = which

## The physics ticks the world has moved this run (`_play_ticks` says how they are counted).
func play_ticks() -> int:
	return _play_ticks

## One more tick of a day walking, from its one owner, `main._physics_process()`.
func count_a_play_tick() -> void:
	_play_ticks += 1

## Puts back the ticks a run had played, which going back to a checkpoint keeps
## (`RunCalendar._go_back_to_the_checkpoint()`).
func set_play_ticks(ticks: int) -> void:
	_play_ticks = ticks

## `play_ticks()` in seconds, at the physics tick rate (`Engine.physics_ticks_per_second`): what the
## ending screen shows (`RunState.format_clock()`) and what the save holds. A function rather than
## a field, since a part declares each field once in its data (`tests/test_run_state.gd`).
func play_seconds() -> float:
	return float(_play_ticks) / Engine.physics_ticks_per_second

## Back to day 1 with every nerve and no ending. The seed and the presentation are the run's
## identity and are set by `RunState.start_run()`, not here.
##
## Overrides RunSubState.reset.
func reset() -> void:
	_day = 1
	_nerves = Tuning.STARTING_NERVES
	_ending = GameEnums.Ending.NONE
	_play_ticks = 0

## Overrides RunSubState.to_data.
func to_data() -> Dictionary:
	return {
		"run_seed": _run_seed,
		"player_is_male": _player_is_male,
		"day": _day,
		"nerves": _nerves,
		"ending": _ending,
		"play_seconds": play_seconds(),
	}

## Overrides RunSubState.restore.
func restore(data: Dictionary) -> void:
	_run_seed = int(data["run_seed"])
	_player_is_male = bool(data["player_is_male"])
	_day = int(data["day"])
	_nerves = int(data["nerves"])
	_ending = int(data["ending"]) as GameEnums.Ending
	# Saved as seconds (`to_data()`), so any save's seconds load back to the nearest tick.
	_play_ticks = roundi(float(data["play_seconds"]) * Engine.physics_ticks_per_second)
