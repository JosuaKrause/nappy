extends DayController
## A day's clock that answers what ended its day as the test holding it sets: the loss's sentence,
## what struck her, the way out of the city. Its losing paths are never walked, so a suite of
## something that reads a clock once a day has ended (the day director, the run log's observer)
## hands it this, rather than raising a hard fail on the bus every listener hears. Everything else,
## its countdown included, is the real clock's.

## What the day's loss says, `""` for none: what `loss_reason()` answers.
var says := ""
## The raw reason of the hard fail that ended the day, `""` for none: what `hard_fail_reason()`
## answers.
var struck_by := ""
## The way out of the city she took (`CityExit.Kind`), -1 for none: what `exit_taken()` answers.
var way_out := -1

## Overrides DayController.loss_reason.
func loss_reason() -> String:
	return says

## Overrides DayController.hard_fail_reason.
func hard_fail_reason() -> String:
	return struck_by

## Overrides DayController.exit_taken.
func exit_taken() -> int:
	return way_out
