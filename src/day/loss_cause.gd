class_name LossCause
extends RefCounted
## What ended a day, as `EventBus.day_ended` carries it: a pure function of the day's result and what
## the day's world says about it. No nodes and no globals — the caller reads the world and hands
## the readings in (`DayDirector` does), so every rule here is checked on plain values
## (`tests/test_loss_cause.gd`).
##
## The cause is `""` for a win or a timeout, whose results already say everything. A hard-fail day
## is named by what struck her (`hard_fail_suffix()`), a crying day by whichever group landed the
## most on her over the crying window (`crying_suffix()`). GoatCounter's `lost-*` names and the run
## log read it; see `docs/TELEMETRY.md`.

## The cause of a day that ended with `result`. `hard_fail_reason` and `struck_by` are read only for
## a hard-fail day, `landed_by_group` only for a crying one; a result they do not belong to ignores
## them.
static func of(result: GameEnums.DayResult, hard_fail_reason := "", struck_by := "",
		landed_by_group := {}) -> String:
	match result:
		GameEnums.DayResult.LOST_HARD_FAIL:
			return hard_fail_suffix(hard_fail_reason, struck_by)
		GameEnums.DayResult.LOST_CRYING:
			return crying_suffix(landed_by_group)
	return ""

## What ended a hard-fail day: `car` for the one hard fail that is not a catalogue row
## (`EventBus.hard_fail_triggered("car_strike")`, `Crowd._strike()`), otherwise the id off whatever
## row actually struck her (`EventBus.hard_fail_triggered(instance.def.id)`,
## `EventManager._check_hard_fails()`) — hyphenated the same way every other cause name is, so a new
## hard-fail row is covered without a second list naming it here.
##
## `struck_by` is `EventManager.what_struck_her()` — the name the logs give the instance whose reach
## ended the day — and names it in place of `reason` when there is one, so a day lost to the
## pelican is `pelican` rather than its row's `cyclist` *(inbox #527 in azure-tapir)*. `reason` stays
## the row's id for `DayController`'s own sentence, which is the cyclist's either way.
static func hard_fail_suffix(reason: String, struck_by := "") -> String:
	if reason == "car_strike":
		return "car"
	return (struck_by if struck_by != "" else reason).replace("_", "-")

## What ended a crying day: whichever group in `landed_by_group` (see `landed_by_group()` in
## `DayDirector`) landed the most on her over the crying window — a catalogue id (hyphenated),
## `crowd` for walkers, `traffic` for cars, or `self` for her own running and standing in an alley.
##
## **Ties, and the window reading entirely empty, pick the alphabetically first key that is
## present** — deterministic without inventing a second "who landed first" rule, and stated here
## rather than left to whatever order a `Dictionary` happens to iterate in. An empty dictionary
## (nothing landed anything inside the window at all) falls back to `self`, the one group that
## always exists whether or not anything else ever did.
static func crying_suffix(landed_by_group: Dictionary) -> String:
	var names := landed_by_group.keys()
	names.sort()
	var best := ""
	var best_points := -1.0
	for name: String in names:
		var points: float = landed_by_group[name]
		if points > best_points:
			best = name
			best_points = points
	if best == "":
		best = "self"
	return String(best).replace("_", "-")

## The events' share of a crying day's groups, folded into `by_group`: each live event's own
## `landed()` under the name the logs give it (`EventInstance.logged_name()`), so a pelican's share is
## `pelican`'s rather than added to the cyclists' *(inbox #527 in azure-tapir)*. Only positive shares
## are kept.
static func add_what_events_landed(instances: Array[EventInstance], by_group: Dictionary) -> void:
	for instance in instances:
		var points := instance.landed()
		if points > 0.0:
			var name := instance.logged_name()
			by_group[name] = float(by_group.get(name, 0.0)) + points
