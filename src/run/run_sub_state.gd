class_name RunSubState
extends RefCounted
## One part of what a run keeps — the interface `PosterState` and `PelicanState` already had, made
## the contract of every part, so the run's state is declared once per field in the part that owns
## it and the places that used to name each field by hand (the dawn photograph, a lost day's
## give-back, the snapshot, the save) walk the registered list instead (`RunStateRegistry`).
##
## A part owns its live fields, its dawn copies of them and their JSON-safe shape:
## - `reset()` puts the part where a run that has just begun holds it, the dawn copies included.
## - `photograph()` copies what a lost attempt would have to give back; a part that nothing spends
##   leaves the default, which does nothing.
## - `give_back()` puts the photograph back; the default does nothing, which is also right for a
##   part the attempt cannot spend.
## - `to_data()` is everything the save carries for the part, the photograph included, as plain
##   JSON-safe values; `restore()` is its other half and casts every number, because JSON has no
##   integer type.

## Where the save puts a part's `to_data()`:
## - `STATE`: its keys sit flat in the save's `"state"` snapshot, and a save without every one of
##   them is refused (`RunStateRegistry.state_keys()`).
## - `RIDER`: its keys sit flat beside `"state"`, and a save without them loads with the values a
##   run that has not got that far holds (`restore()` is handed what the save has).
## - `NESTED`: its whole `to_data()` sits under `save_key()`, read back with a default the same way.
enum Slot { STATE, RIDER, NESTED }

func slot() -> Slot:
	return Slot.STATE

## The key a `NESTED` part is saved under.
func save_key() -> String:
	return ""

func reset() -> void:
	pass

func photograph() -> void:
	pass

func give_back() -> void:
	pass

func to_data() -> Dictionary:
	return {}

func restore(_data: Dictionary) -> void:
	pass
