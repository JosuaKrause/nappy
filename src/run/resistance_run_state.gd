class_name ResistanceRunState
extends RunSubState
## What the resistance has done this run: the steps completed and failed, the progress they earned,
## whether the sabotage is done and whether the pram is carrying the package. **A lost day gives
## all of it back**, so the dawn copies are kept beside the live fields; `differs_from_dawn()` says
## whether a give-back would undo any of it, for the run log's line about the nerve.

var _completed_steps: Array[int] = []
var _failed_steps: Array[int] = []
var _progress: int = 0
## Whether the day-14 sabotage actually went through. Reaching `Tuning.RESISTANCE_GOAL` earns the
## chance at the good ending; this is doing it.
var _sabotage_done := false
## Whether the pram is carrying the package right now, for the rest of a day once it has been picked
## up: `City.decay_multiplier()` reads it, since the pram is heavier for every street after. Put down
## at each dawn (`RunCalendar.begin_day()`) so a loss gives back a pram that is not yet
## heavy.
var _carrying_package := false

var _dawn_completed_steps: Array[int] = []
var _dawn_failed_steps: Array[int] = []
var _dawn_progress := 0
var _dawn_sabotage_done := false
var _dawn_carrying_package := false

## The steps completed this run, in the order they were: the live list, which a reader does not
## change; `complete()` adds to it.
func completed_steps() -> Array[int]:
	return _completed_steps

func has_completed(step: int) -> bool:
	return step in _completed_steps

## The timed steps that expired this run, each a contact gone for the rest of it: the live list,
## which a reader does not change; `fail()` adds to it.
func failed_steps() -> Array[int]:
	return _failed_steps

## The steps completed that count toward `Tuning.RESISTANCE_GOAL`, which a pickup does not.
func progress() -> int:
	return _progress

## Puts the progress at `count`, as a scene recipe's last night does to offer the sabotage.
func set_progress(count: int) -> void:
	_progress = count

## Records `step` completed, and a point of progress with it when `counts_toward_goal`; false, and
## nothing changes, for a step already completed (`RunState.complete_resistance_step()`).
func complete(step: int, counts_toward_goal: bool) -> bool:
	if step in _completed_steps:
		return false
	_completed_steps.append(step)
	if counts_toward_goal:
		_progress += 1
	return true

## Records `step` failed; false, and nothing changes, for a step already failed
## (`RunState.fail_resistance_step()`).
func fail(step: int) -> bool:
	if step in _failed_steps:
		return false
	_failed_steps.append(step)
	return true

func sabotage_went_through() -> bool:
	return _sabotage_done

## The last night's sabotage done (`ResistanceDirector`).
func record_the_sabotage() -> void:
	_sabotage_done = true

func is_carrying_package() -> bool:
	return _carrying_package

func pick_up_package() -> void:
	_carrying_package = true

## The package put down: at each dawn (`RunCalendar.begin_day()`, `ResistanceDirector.start_day()`).
func put_down_package() -> void:
	_carrying_package = false

## A fresh run's dawn is its start: nothing done, and nothing to give back but nothing.
##
## Overrides RunSubState.reset.
func reset() -> void:
	_completed_steps.clear()
	_failed_steps.clear()
	_progress = 0
	_sabotage_done = false
	_carrying_package = false
	photograph()

## Overrides RunSubState.photograph.
func photograph() -> void:
	_dawn_completed_steps = _completed_steps.duplicate()
	_dawn_failed_steps = _failed_steps.duplicate()
	_dawn_progress = _progress
	_dawn_sabotage_done = _sabotage_done
	_dawn_carrying_package = _carrying_package

## Overrides RunSubState.give_back.
func give_back() -> void:
	_completed_steps = _dawn_completed_steps.duplicate()
	_failed_steps = _dawn_failed_steps.duplicate()
	_progress = _dawn_progress
	_sabotage_done = _dawn_sabotage_done
	_carrying_package = _dawn_carrying_package

## Whether `give_back()` would change anything.
func differs_from_dawn() -> bool:
	return _completed_steps != _dawn_completed_steps \
			or _failed_steps != _dawn_failed_steps \
			or _progress != _dawn_progress \
			or _sabotage_done != _dawn_sabotage_done \
			or _carrying_package != _dawn_carrying_package

## Overrides RunSubState.to_data.
func to_data() -> Dictionary:
	return {
		"resistance_progress": _progress,
		"completed_resistance_steps": _completed_steps.duplicate(),
		"failed_resistance_steps": _failed_steps.duplicate(),
		"sabotage_done": _sabotage_done,
		"resistance_carrying_package": _carrying_package,
		"_dawn_completed_steps": _dawn_completed_steps.duplicate(),
		"_dawn_failed_steps": _dawn_failed_steps.duplicate(),
		"_dawn_progress": _dawn_progress,
		"_dawn_sabotage_done": _dawn_sabotage_done,
		"_dawn_carrying_package": _dawn_carrying_package,
	}

## Overrides RunSubState.restore.
func restore(data: Dictionary) -> void:
	_progress = int(data["resistance_progress"])
	_completed_steps = _to_int_array(data["completed_resistance_steps"])
	_failed_steps = _to_int_array(data["failed_resistance_steps"])
	_sabotage_done = bool(data["sabotage_done"])
	_carrying_package = bool(data["resistance_carrying_package"])
	_dawn_completed_steps = _to_int_array(data["_dawn_completed_steps"])
	_dawn_failed_steps = _to_int_array(data["_dawn_failed_steps"])
	_dawn_progress = int(data["_dawn_progress"])
	_dawn_sabotage_done = bool(data["_dawn_sabotage_done"])
	_dawn_carrying_package = bool(data["_dawn_carrying_package"])

static func _to_int_array(raw: Array) -> Array[int]:
	var result: Array[int] = []
	for value: Variant in raw:
		result.append(int(value))
	return result
