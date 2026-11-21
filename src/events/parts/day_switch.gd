class_name DaySwitch
extends Resource
## **How a row is sited and noticed from the day after `after_day`**, for a row whose first
## appearance is different from every later one: `charging_dog` is sited dead ahead of her on
## `Tuning.RUN_TAUGHT_DAY`, the run's lesson, and from the day after it is a place on the map that
## waits for her (`notice`). Siting and notice change on the same day, so they are one switch.
##
## Never a mutation of the shared row: `EventDef.spawn_mode_on()` and `EventDef._notice_on()` answer
## by day, and a placement that needs the later notice is handed a copy carrying it
## (`EventDef.for_day()`), as a heated row is a copy.

## The last day the row's own `spawn_mode` and `notice` answer for.
var _after_day := 0
## How the row is sited past `after_day`.
var _spawn_mode := EventDef.SpawnMode.MAP
## How the row notices her past `after_day`, or null for no wait.
var _notice: NoticeSpec = null

## The switch past `day`: the row is sited as `mode` says and notices her as `how` says (null for no wait).
static func after(day: int, mode: EventDef.SpawnMode, how: NoticeSpec) -> DaySwitch:
	var switch := DaySwitch.new()
	switch._after_day = day
	switch._spawn_mode = mode
	switch._notice = how
	return switch

## The last day the row's own `spawn_mode` and `notice` answer for.
func after_day() -> int:
	return _after_day

## How the row is sited past `after_day()`.
func spawn_mode() -> EventDef.SpawnMode:
	return _spawn_mode

## How the row notices her past `after_day()`, or null for no wait.
func notice() -> NoticeSpec:
	return _notice
