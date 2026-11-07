class_name FakeEventManager
extends EventManager
## A stand-in for a day's events, handed to what is handed an `EventManager` (the resistance's
## happenings, `ResistanceHappenings.setup()`) in place of the real one, so the check builds no city
## and plans no day. It answers what those ask of it in the situations its suites set: a row
## spawned unplanned (`spawn_extra()`) is an instance of that row at the point and on the path asked,
## which is what the real manager hands back for a raid at her building (two `night_raid` vans and a
## pacing `police_patrol`, read off a real city once). The real manager's own logic is checked in
## its own suites (`tests/test_event_manager.gd` and the rest). A helper, not a suite: the runner
## loads only `test_*.gd`.
##
## **Never put in a world.** The parts `EventManager._init()` builds stay idle, so a call this does
## not override reaches a real part over an empty world, which a check would see as a wrong answer
## rather than a crash. A node: the suite frees it, and with it every instance it made.

## Every instance `spawn_extra()` made, freed with the manager: none is in a world either.
var _made: Array[EventInstance] = []

## An instance of `def` at `at`, on `path`, in no world.
##
## Overrides EventManager.spawn_extra.
func spawn_extra(def: EventDef, at: Vector2, path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	_made.append(instance)
	return instance

## Frees what `spawn_extra()` made, beside the manager's own letting go of its parts (the engine
## sends the notification to each script of the chain).
##
## Overrides EventManager._notification.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for instance in _made:
			if is_instance_valid(instance):
				instance.free()
		_made.clear()
