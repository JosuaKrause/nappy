class_name Aftermath
extends Resource
## **The rows an event brings after it** (`EventDef.aftermath`): the scar it leaves on the run, the
## row it leaves where it ends, and the row it calls in once she has seen it. One resource because
## they are one thing to take away: the escape's rows and the seals' are made without them
## (`EventCatalogue.without_its_aftermath()`, `SealPlanner`), where the run has no mornings left
## for those marks to mean anything.

## Event id to leave permanently at this event's position for the rest of the run. A fire leaves a
## burnt-out shell; the shell is still there on day 12.
var _scar := ""

## Event id to spawn where this one ends. How the escape's explosion leaves its crater in the road.
var _on_finish := ""

## Event id to spawn the moment this one is first seen: what arrives once she has found it, where
## `on_finish` names what it leaves behind when it is done. How the burning building calls in the
## fire engine — `EventManager` owns the trigger, since it already owns the successor mechanism and
## her position; see `EventSpawner.summon_what_has_been_sighted()`.
var _on_sight := ""

## **No aftermath**: no scar, nothing left where it ends, nothing called in.
static func none() -> Aftermath:
	return Aftermath.new()

## The same aftermath leaving the scar `id` on the run.
func scarring(id: String) -> Aftermath:
	var after := _copy()
	after._scar = id
	return after

## The same aftermath spawning row `id` where this one ends.
func then(id: String) -> Aftermath:
	var after := _copy()
	after._on_finish = id
	return after

## The same aftermath calling in row `id` the moment this one is first seen.
func calling_in(id: String) -> Aftermath:
	var after := _copy()
	after._on_sight = id
	return after

## The id of the row it leaves where it ends (`then()`), or "" for none.
func leaves_behind() -> String:
	return _on_finish

## The id of the row it calls in the moment it is first seen (`calling_in()`), or "" for one that
## calls none.
func calls_in() -> String:
	return _on_sight

## The id of the scar it leaves on the run (`scarring()`), or "" for none.
func scar_id() -> String:
	return _scar

## Whether the scar it leaves is the one `scar_id` names.
func leaves_the_scar(id: String) -> bool:
	return _scar == id

func _copy() -> Aftermath:
	var after := Aftermath.new()
	after._scar = _scar
	after._on_finish = _on_finish
	after._on_sight = _on_sight
	return after
