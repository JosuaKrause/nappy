class_name FakeDaySpec
extends DaySpec
## A stand-in for a day's spec whose answer to whether the region wall stands a check sets: handed
## to what asks a `DaySpec` that (`ClosurePlanner.closures_wanted()`, `SealPlanner.plan_day()`) in
## place of the real one, so the check names the answer the planner is given rather than picking a
## day number that derives it. Every other setting is a day's, as `DaySpec.new()` holds it. The real
## derivation is checked once, in `tests/test_day_spec.gd`. A helper, not a suite: the runner loads
## only `test_*.gd`.

var _fake_wall_stands := false

## Sets the day it is, and whether the region wall stands on it.
func on(day: int, wall_stands: bool) -> FakeDaySpec:
	number = day
	_fake_wall_stands = wall_stands
	return self

## Overrides DaySpec.region_wall_stands.
func region_wall_stands() -> bool:
	return _fake_wall_stands
