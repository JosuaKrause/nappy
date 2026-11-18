class_name DayEnd
extends RefCounted
## What `DayDirector.finish_day()` settled about a day that just ended — the facts the screens and
## the save need, so `main` shows and writes them without re-deriving any of it.
##
## **A value handed on, asked through its methods.** The director builds it once: what the day ended
## with is handed to `new()`, and what the calendar does next is marked on it before it is handed
## on. Every fact is read through a getter, never a property, since a property reads like a plain
## field where it is used (designing-classes, "Fields are not API"). The day's number and what ended
## it are not kept here: `EventBus.day_ended` carries both to the run log and the page's counter.

var _result := GameEnums.DayResult.WON
## What the day's loss says (`DayController.loss_reason()`, from `Texts`), `""` for a win.
var _reason := ""
## The day's clock at the instant it ended, clamped to the day's length.
var _elapsed_seconds := 0.0
## Which way out of the city she took (`CityEdge.Kind`, as an `int`), or -1 when she took none.
var _exit_reached := -1
var _is_section := false
var _hands_over_to_the_escape := false
var _goes_back := false
var _run_over := false

## What the day ended with: its result, the loss's own sentence (`""` for a win), the clock it ended
## on in seconds, and the way out of the city she took (-1 for none).
func _init(result := GameEnums.DayResult.WON, reason := "", elapsed_seconds := 0.0,
		exit_reached := -1) -> void:
	_result = result
	_reason = reason
	_elapsed_seconds = elapsed_seconds
	_exit_reached = exit_reached

## An escape section: the director has ended the day (`day_ended` sent) and nothing more; the
## section's own cost and screen are `main`'s.
func mark_a_section() -> void:
	_is_section = true

## A won last day with every task done: the run goes on into the escape, so the calendar was not
## closed (`RunCalendar.finish_day()` not called) and the won day's nerve was given back.
func mark_continuing_into_the_escape() -> void:
	_hands_over_to_the_escape = true

## This loss spent a normal run's last nerve, so the run goes back to its checkpoint.
func mark_sending_the_run_back() -> void:
	_goes_back = true

## The run ended with this day (`RunCalendar.finish_day()` returned false).
func mark_ending_the_run() -> void:
	_run_over = true

## Whether the day was won, lost to the clock or lost to the baby (`GameEnums.DayResult`).
func outcome() -> GameEnums.DayResult:
	return _result

## What the day's loss says, `""` for a win.
func loss_reason() -> String:
	return _reason

## The day's clock at the instant it ended, in seconds.
func lasted_seconds() -> float:
	return _elapsed_seconds

## Which way out of the city she took (`CityEdge.Kind`, as an `int`), or -1 when she took none.
func exit_taken() -> int:
	return _exit_reached

## Whether this was the end of an escape section, whose cost and screen are `main`'s.
func ends_a_section() -> bool:
	return _is_section

## Whether the run goes on into the escape instead of closing the calendar.
func continues_into_the_escape() -> bool:
	return _hands_over_to_the_escape

## Whether this loss sends the run back to its checkpoint.
func sends_the_run_back() -> bool:
	return _goes_back

## Whether the run ended with this day.
func ends_the_run() -> bool:
	return _run_over
