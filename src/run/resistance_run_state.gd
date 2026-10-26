class_name ResistanceRunState
extends RunSubState
## What the resistance has done this run: the steps completed and failed, the progress they earned,
## whether the sabotage is done and whether the pram is carrying the package. **A lost day gives
## all of it back**, so the dawn copies are kept beside the live fields; `differs_from_dawn()` says
## whether a give-back would undo any of it, for the run log's line about the nerve.

var completed_steps: Array[int] = []
var failed_steps: Array[int] = []
var progress: int = 0
## Whether the day-14 sabotage actually went through. Reaching `Tuning.RESISTANCE_GOAL` earns the
## chance at the good ending; this is doing it.
var sabotage_done := false
## Whether the pram is carrying the package right now, for the rest of a day once it has been picked
## up: `City.decay_multiplier()` reads it, since the pram is heavier for every street after. Put down
## at each dawn (`GameState.begin_day()`) so a loss gives back a pram that is not yet heavy.
var carrying_package := false

var _dawn_completed_steps: Array[int] = []
var _dawn_failed_steps: Array[int] = []
var _dawn_progress := 0
var _dawn_sabotage_done := false
var _dawn_carrying_package := false

## A fresh run's dawn is its start: nothing done, and nothing to give back but nothing.
func reset() -> void:
	completed_steps.clear()
	failed_steps.clear()
	progress = 0
	sabotage_done = false
	carrying_package = false
	photograph()

func photograph() -> void:
	_dawn_completed_steps = completed_steps.duplicate()
	_dawn_failed_steps = failed_steps.duplicate()
	_dawn_progress = progress
	_dawn_sabotage_done = sabotage_done
	_dawn_carrying_package = carrying_package

func give_back() -> void:
	completed_steps = _dawn_completed_steps.duplicate()
	failed_steps = _dawn_failed_steps.duplicate()
	progress = _dawn_progress
	sabotage_done = _dawn_sabotage_done
	carrying_package = _dawn_carrying_package

## Whether `give_back()` would change anything.
func differs_from_dawn() -> bool:
	return completed_steps != _dawn_completed_steps \
			or failed_steps != _dawn_failed_steps \
			or progress != _dawn_progress \
			or sabotage_done != _dawn_sabotage_done \
			or carrying_package != _dawn_carrying_package

func to_data() -> Dictionary:
	return {
		"resistance_progress": progress,
		"completed_resistance_steps": completed_steps.duplicate(),
		"failed_resistance_steps": failed_steps.duplicate(),
		"sabotage_done": sabotage_done,
		"resistance_carrying_package": carrying_package,
		"_dawn_completed_steps": _dawn_completed_steps.duplicate(),
		"_dawn_failed_steps": _dawn_failed_steps.duplicate(),
		"_dawn_progress": _dawn_progress,
		"_dawn_sabotage_done": _dawn_sabotage_done,
		"_dawn_carrying_package": _dawn_carrying_package,
	}

func restore(data: Dictionary) -> void:
	progress = int(data["resistance_progress"])
	completed_steps = _to_int_array(data["completed_resistance_steps"])
	failed_steps = _to_int_array(data["failed_resistance_steps"])
	sabotage_done = bool(data["sabotage_done"])
	carrying_package = bool(data["resistance_carrying_package"])
	_dawn_completed_steps = _to_int_array(data["_dawn_completed_steps"])
	_dawn_failed_steps = _to_int_array(data["_dawn_failed_steps"])
	_dawn_progress = int(data["_dawn_progress"])
	_dawn_sabotage_done = bool(data["_dawn_sabotage_done"])
	_dawn_carrying_package = bool(data["_dawn_carrying_package"])

static func _to_int_array(raw: Array) -> Array[int]:
	var result: Array[int] = []
	for value in raw:
		result.append(int(value))
	return result
