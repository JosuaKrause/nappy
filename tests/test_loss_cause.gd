extends RefCounted
## `LossCause`, the pure rules behind the cause `EventBus.day_ended` carries — the hard-fail cause
## and the crying cause, named where the day ended for the run log and the page's counter alike.
## See `EventBus.day_ended`'s own doc. Plain values in, a name out: no scene, no globals.

func run(t) -> void:
	_test_hard_fail_cause_suffix(t)
	_test_crying_cause_suffix(t)
	_test_a_day_lost_to_the_pelican_names_the_pelican(t)
	_test_the_cause_by_result(t)

## `car_strike` is the one hard fail that is not a catalogue row and gets its own short name;
## every other reason is a `def.id`, hyphenated the same way every other cause name in this file
## already is — `roadblock` included, so a row that turns lethal only once the resistance's heat
## reaches it (`EventDef.at_heat()`) needs no entry of its own here. Raw, unprefixed
## — `VisitCounter._loss_event_suffix()` is what folds it onto `lost-hard-fail`.
func _test_hard_fail_cause_suffix(t) -> void:
	t.check(LossCause.hard_fail_suffix("car_strike") == "car",
		"the one hard fail that is not a catalogue row")
	t.check(LossCause.hard_fail_suffix("charging_dog") == "charging-dog",
		"a caught chase, hyphenated off its own catalogue id")
	t.check(LossCause.hard_fail_suffix("roadblock") == "roadblock",
		"a row whose id already has no underscore to hyphenate")
	t.check(LossCause.hard_fail_suffix("night_raid") == "night-raid",
		"a row whose id has an underscore, named off the same `def.id` as every other")
	t.check(LossCause.hard_fail_suffix("alley_robbery") == "alley-robbery",
		"the chalk mark's own guard")

## The largest group in `landed_by_group` names the cause; ties and an empty window pick the
## alphabetically first key that is present, falling back to `self` when nothing landed anything
## in the window at all. Raw, unprefixed — `VisitCounter._loss_event_suffix()` is what folds it onto
## `lost-crying`.
func _test_crying_cause_suffix(t) -> void:
	t.check(LossCause.crying_suffix({"homeless_yeller": 12.0, "crowd": 4.0})
			== "homeless-yeller", "the largest group names the cause, hyphenated")
	t.check(LossCause.crying_suffix({"crowd": 6.0, "traffic": 9.0}) == "traffic",
		"traffic outweighing the crowd names traffic")
	t.check(LossCause.crying_suffix({"leaf_blower": 3.0}) == "leaf-blower",
		"a single group with an underscore in its own id")
	t.check(LossCause.crying_suffix({"crowd": 5.0, "construction": 5.0})
			== "construction",
		"a tie picks the alphabetically first key present, deterministic without a second rule")
	t.check(LossCause.crying_suffix({}) == "self",
		"an empty window falls back to her own unattributed share")

## The pelican is named `pelican` in the cause, never its row's `cyclist` *(inbox #527 in azure-tapir)*: a hard fail
## through `EventManager.what_struck_her()`'s own name, and a crying loss through the events half of
## the grouping, where a pelican's share is its own rather than added to the cyclists'.
func _test_a_day_lost_to_the_pelican_names_the_pelican(t) -> void:
	t.check(LossCause.hard_fail_suffix("cyclist", "pelican") == "pelican",
		"a day the pelican's reach ended is lost to the pelican")
	t.check(LossCause.hard_fail_suffix("cyclist", "cyclist") == "cyclist"
			and LossCause.hard_fail_suffix("cyclist") == "cyclist",
		"and one a cyclist's ended is lost to the cyclist")
	t.check(LossCause.hard_fail_suffix("car_strike") == "car",
		"a car is still a car")
	var def := EventCatalogue.by_id("cyclist")
	var kid := EventInstance.new()
	kid.setup(def, Vector2.ZERO)
	var pelican := EventInstance.new()
	pelican.setup(def, Vector2.ZERO)
	pelican.is_pelican = true
	kid.accumulate_landed(3.0)
	pelican.accumulate_landed(5.0)
	var by_group := {"crowd": 4.0}
	var instances: Array[EventInstance] = [kid, pelican]
	LossCause.add_what_events_landed(instances, by_group)
	t.check(by_group == {"crowd": 4.0, "cyclist": 3.0, "pelican": 5.0},
		"the pelican's share of the meter is its own group (%s)" % [by_group])
	t.check(LossCause.crying_suffix(by_group) == "pelican",
		"so a crying day the pelican landed the most on is lost to the pelican")
	kid.free()
	pelican.free()

## `LossCause.of()` is the one entry: a win and a timeout have no cause, a hard-fail day is named by
## what struck her, a crying day by what landed the most, and the inputs a result does not read
## are ignored.
func _test_the_cause_by_result(t) -> void:
	var landed := {"crowd": 2.0, "traffic": 7.0}
	t.check(LossCause.of(GameEnums.DayResult.WON, "car_strike", "x", landed) == "",
			"a win has no cause")
	t.check(LossCause.of(GameEnums.DayResult.LOST_TIMEOUT, "car_strike", "x", landed) == "",
			"a timeout has none either")
	t.check(LossCause.of(GameEnums.DayResult.LOST_HARD_FAIL, "car_strike", "", landed) == "car",
			"a hard fail reads its reason, not the landed shares")
	t.check(LossCause.of(GameEnums.DayResult.LOST_HARD_FAIL, "cyclist", "pelican") == "pelican",
			"and what struck her names it in place of the row")
	t.check(LossCause.of(GameEnums.DayResult.LOST_CRYING, "car_strike", "pelican", landed) == "traffic",
			"a crying day reads only the landed shares")
	t.check(LossCause.of(GameEnums.DayResult.LOST_CRYING) == "self",
			"and with nothing landed it was her own")
