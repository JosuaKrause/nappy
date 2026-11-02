class_name RunStateRegistry
extends RefCounted
## The one list of a run's sub-states (`RunSubState`), in the order they are walked. Starting a run
## resets them, a dawn photographs them, a lost day gives them back and the save writes and reads
## them, each by walking this list — so a part on the list is in all four and a part not on it is
## in none, instead of a field being missed in one of six places by hand.
##
## **The save's shape is the parts' business, not this list's**: it asks each part for its slot
## (`RunSubState.Slot`) and merges. `GameSave` is the only caller that knows the file format.

var _parts: Array[RunSubState] = []

## Adds `part` to the end of the list and answers it, so a declaration can register as it builds.
## Refuses a part registered twice, and a nested part whose save key is already taken.
func register(part: RunSubState) -> RunSubState:
	assert(part not in _parts, "a run sub-state is registered once")
	if part.slot() == RunSubState.Slot.NESTED:
		for other in _parts:
			assert(other.slot() != RunSubState.Slot.NESTED or other.save_key() != part.save_key(),
					"two run sub-states are saved under %s" % part.save_key())
	_parts.append(part)
	return part

func parts() -> Array[RunSubState]:
	return _parts.duplicate()

func reset() -> void:
	for part in _parts:
		part.reset()

func photograph() -> void:
	for part in _parts:
		part.photograph()

func give_back() -> void:
	for part in _parts:
		part.give_back()

## The flat `"state"` snapshot: every `STATE` part's keys merged.
func state_data() -> Dictionary:
	var state := {}
	for part in _parts:
		if part.slot() == RunSubState.Slot.STATE:
			state.merge(part.to_data())
	return state

## The keys a `"state"` snapshot must carry to be complete: whatever the `STATE` parts write.
func state_keys() -> Array:
	return state_data().keys()

func restore_state(state: Dictionary) -> void:
	for part in _parts:
		if part.slot() == RunSubState.Slot.STATE:
			part.restore(state)

## What the save carries beside `"state"`: the `RIDER` parts' keys flat, the `NESTED` parts each
## under its own key.
func rider_data() -> Dictionary:
	var riders := {}
	for part in _parts:
		match part.slot():
			RunSubState.Slot.RIDER:
				riders.merge(part.to_data())
			RunSubState.Slot.NESTED:
				riders[part.save_key()] = part.to_data()
	return riders

## Puts the riders back, each part reset first so a save that never wrote its key leaves the part
## where a run that has not got that far holds it.
func restore_riders(data: Dictionary) -> void:
	for part in _parts:
		match part.slot():
			RunSubState.Slot.RIDER:
				part.reset()
				part.restore(data)
			RunSubState.Slot.NESTED:
				part.reset()
				var nested: Variant = data.get(part.save_key(), {})
				if nested is Dictionary:
					part.restore(nested)

## The names of `owner`'s properties that hold a `RunSubState` which is not on `registry`: the
## check that a part declared and left off the list is caught.
static func unregistered_in(owner: Object, registry: RunStateRegistry) -> Array[String]:
	var missing: Array[String] = []
	for property in owner.get_property_list():
		if not property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		var value: Variant = owner.get(property["name"])
		if value is RunSubState and value not in registry._parts:
			missing.append(property["name"])
	return missing

## The registry's parts in the shape a save carries them: `state_data()` under `"state"` and the
## riders beside it. This is also exactly what a checkpoint is, so the save and the checkpoint
## never carry two different ideas of what a run is (`GameSave.file_data()` adds the file's
## own keys).
func run_data() -> Dictionary:
	var data := rider_data()
	data["state"] = state_data()
	return data

## The other half of `run_data()`: puts every part back from a save read off disk or from a
## checkpoint alike. `data["state"]` must already carry every key `state_keys()` names. The riders
## are read after the snapshot, each with a default for its absence, so a save from a build that
## never wrote a key leaves that part where a run that has not got that far holds it.
func restore_run_data(data: Dictionary) -> void:
	restore_state(data["state"])
	restore_riders(data)
