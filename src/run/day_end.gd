class_name DayEnd
extends RefCounted
## What `DayDirector.finish_day()` settled about a day that just ended — the facts the screens and
## the save need, so `main` shows and writes them without re-deriving any of it.

## The calendar's day number, or a section's own after the last day.
var finished_day := 0
var result := GameEnums.DayResult.WON
## What ended a crying or hard-fail day (`LossCause`), `""` otherwise.
var cause := ""
## What the day's loss says (`DayController.failure_reason`, from `Texts`), `""` for a win.
var reason := ""
## The day's clock at the instant it ended, clamped to the day's length.
var elapsed_seconds := 0.0
## Which way out of the city she took (`CityEdge.Kind`, as an `int`), or -1 when she took none.
var exit_reached := -1
## An escape section: the director has ended the day (`day_ended` sent) and nothing more; the
## section's own cost and screen are `main`'s.
var is_section := false
## A won last day with every task done: the run goes on into the escape, so the calendar was not
## closed (`GameState.calendar.finish_day()` not called) and the won day's nerve was given back.
var hands_over_to_the_escape := false
## Whether this loss spent a normal run's last nerve, so the run goes back to its checkpoint.
var goes_back := false
## Whether the run ended with this day (`GameState.calendar.finish_day()` returned false).
var run_over := false
