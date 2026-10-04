extends RefCounted
## `main.gd`'s own pure halves behind `EventBus.day_lost_to` — the hard-fail cause and the crying
## cause, both named for `VisitCounter` before the signal ever fires. See M208, "The counter says
## what ended a day and what she actually met", and `EventBus.day_lost_to`'s own doc.
##
## `main.gd` is not an autoload, so — unlike `VisitCounter` — it could be reached by its bare
## `class_name` if it had one; it does not, so this preloads the file the same way
## `tests/test_debug_layers.gd` and `tests/test_burst_capture.gd` already reach its other pure
## statics.

const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

func run(t) -> void:
	_test_hard_fail_cause_suffix(t)
	_test_crying_cause_suffix(t)
	_test_a_day_lost_to_the_pelican_names_the_pelican(t)

## `car_strike` is the one hard fail that is not a catalogue row and gets its own short name;
## every other reason is a `def.id`, hyphenated the same way every other cause name in this file
## already is — `roadblock` and `night_raid` included, so a row that only turns lethal once the
## resistance's heat reaches it (`EventDef.at_heat()`) needs no entry of its own here. Raw, unprefixed
## — `VisitCounter._loss_event_suffix()` is what folds it onto `lost-hard-fail`.
func _test_hard_fail_cause_suffix(t) -> void:
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("car_strike") == "car",
		"the one hard fail that is not a catalogue row")
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("charging_dog") == "charging-dog",
		"a caught chase, hyphenated off its own catalogue id")
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("roadblock") == "roadblock",
		"a row whose id already has no underscore to hyphenate")
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("night_raid") == "night-raid",
		"a row that only turns lethal at heat, named off the same `def.id` either way")
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("alley_robbery") == "alley-robbery",
		"the chalk mark's own guard")

## The largest group in `landed_by_group` names the cause; ties and an empty window pick the
## alphabetically first key that is present, falling back to `self` when nothing landed anything
## in the window at all. Raw, unprefixed — `VisitCounter._loss_event_suffix()` is what folds it onto
## `lost-crying`.
func _test_crying_cause_suffix(t) -> void:
	t.check(MAIN_SCRIPT._crying_cause_suffix({"homeless_yeller": 12.0, "crowd": 4.0})
			== "homeless-yeller", "the largest group names the cause, hyphenated")
	t.check(MAIN_SCRIPT._crying_cause_suffix({"crowd": 6.0, "traffic": 9.0}) == "traffic",
		"traffic outweighing the crowd names traffic")
	t.check(MAIN_SCRIPT._crying_cause_suffix({"leaf_blower": 3.0}) == "leaf-blower",
		"a single group with an underscore in its own id")
	t.check(MAIN_SCRIPT._crying_cause_suffix({"crowd": 5.0, "construction": 5.0})
			== "construction",
		"a tie picks the alphabetically first key present, deterministic without a second rule")
	t.check(MAIN_SCRIPT._crying_cause_suffix({}) == "self",
		"an empty window falls back to her own unattributed share")

## The pelican is named `pelican` in the cause, never its row's `cyclist` *(inbox #527 in azure-tapir)*: a hard fail
## through `EventManager.what_struck_her()`'s own name, and a crying loss through the events half of
## the grouping, where a pelican's share is its own rather than added to the cyclists'.
func _test_a_day_lost_to_the_pelican_names_the_pelican(t) -> void:
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("cyclist", "pelican") == "pelican",
		"a day the pelican's reach ended is lost to the pelican")
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("cyclist", "cyclist") == "cyclist"
			and MAIN_SCRIPT._hard_fail_cause_suffix("cyclist") == "cyclist",
		"and one a cyclist's ended is lost to the cyclist")
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("car_strike") == "car",
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
	MAIN_SCRIPT._group_what_events_landed(instances, by_group)
	t.check(by_group == {"crowd": 4.0, "cyclist": 3.0, "pelican": 5.0},
		"the pelican's share of the meter is its own group (%s)" % [by_group])
	t.check(MAIN_SCRIPT._crying_cause_suffix(by_group) == "pelican",
		"so a crying day the pelican landed the most on is lost to the pelican")
	kid.free()
	pelican.free()
