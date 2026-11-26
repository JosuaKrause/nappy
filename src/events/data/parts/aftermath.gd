class_name Aftermath
extends RefCounted
## **The rows an event brings after it** (a row's own, asked through `EventDef.scar_id()`,
## `EventDef.leaves_behind()` and `EventDef.calls_in()`): the scar it leaves on the run, the
## row it leaves where it goes off, and the row it calls in once she has seen it. One resource because
## they are one thing to take away: the escape's rows and the seals' are made without them
## (`EventCatalogue.without_its_aftermath()`, `SealPlanner`), where the run has no mornings left
## for those marks to mean anything.

## Event id to leave permanently at this event's position for the rest of the run. A fire leaves a
## burnt-out shell; the shell is still there on day 12.
var _scar := ""

## The row to spawn where this one goes off, the moment its telegraph is over
## (`EventInstance.take_what_it_leaves()`), or null for none. How the escape's explosion leaves
## its crater in the road as it bangs, so the crater stands wherever the bang could not be seen.
## The row itself, the catalogue's own, so what it leaves is known without a catalogue to look
## it up in.
var _on_finish: EventDef = null

## Event id to spawn the moment this one is first seen: what arrives once she has found it, where
## `on_finish` names what it leaves behind where it goes off. How the burning building calls in the
## fire engine — `EventManager` owns the trigger, since it already owns the successor mechanism and
## her position; see `EventSpawner.summon_what_has_been_sighted()`.
var _on_sight := ""

## **No aftermath**: no scar, nothing left where it goes off, nothing called in.
static func none() -> Aftermath:
	return Aftermath.new()

## The same aftermath leaving the scar `id` on the run.
func scarring(id: String) -> Aftermath:
	var after := _copy()
	after._scar = id
	return after

## The same aftermath spawning `row` where this one goes off.
func then(row: EventDef) -> Aftermath:
	var after := _copy()
	after._on_finish = row
	return after

## The same aftermath calling in row `id` the moment this one is first seen.
func calling_in(id: String) -> Aftermath:
	var after := _copy()
	after._on_sight = id
	return after

## The id of the row it leaves where it goes off (`then()`), or "" for none.
func leaves_behind() -> String:
	return _on_finish.id() if _on_finish else ""

## The row it leaves where it goes off (`then()`), or null for none.
func left_behind() -> EventDef:
	return _on_finish

## The id of the row it calls in the moment it is first seen (`calling_in()`), or "" for one that
## calls none.
func calls_in() -> String:
	return _on_sight

## The id of the scar it leaves on the run (`scarring()`), or "" for none.
func scar_id() -> String:
	return _scar

## Whether the scar it leaves is the one `scar_id` names.
func leaves_the_scar(scar_id: String) -> bool:
	return _scar == scar_id

func _copy() -> Aftermath:
	var after := Aftermath.new()
	after._scar = _scar
	after._on_finish = _on_finish
	after._on_sight = _on_sight
	return after
