class_name DaySwitch
extends Resource
## **How a row is sited and noticed from the day after `after_day`**, for a row whose first
## appearance is different from every later one: `charging_dog` is sited dead ahead of her on
## `Tuning.RUN_TAUGHT_DAY`, the run's lesson, and from the day after it is a place on the map that
## waits for her (`notice`). Siting and notice change on the same day, so they are one switch.
##
## Never a mutation of the shared row: `EventDef.spawn_mode_on()` and `EventDef.notice_on()` answer
## by day, and a placement that needs the later notice is handed a copy carrying it
## (`EventScheduler._for_day()`), as a heated row is a copy.

## The last day the row's own `spawn_mode` and `notice` answer for.
@export var after_day := 0
## How the row is sited past `after_day`.
@export var spawn_mode := EventDef.SpawnMode.MAP
## How the row notices her past `after_day`, or null for no wait.
@export var notice: NoticeSpec = null
