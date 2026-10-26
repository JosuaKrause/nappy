class_name Aftermath
extends Resource
## **The rows an event brings after it** (`EventDef.aftermath`): the scar it leaves on the run, the
## row it leaves where it ends, and the row it calls in once she has seen it. One resource because
## they are one thing to take away: the escape's rows and the seals' are made without them
## (`EventCatalogue.without_its_aftermath()`, `SealPlanner`), where the run has no mornings left
## for those marks to mean anything.

## Event id to leave permanently at this event's position for the rest of the run. A fire leaves a
## burnt-out shell; the shell is still there on day 12.
@export var scar := ""

## Event id to spawn where this one ends. How a military convoy leaves a barricade behind it.
@export var on_finish := ""

## Event id to spawn the moment this one is first seen: what arrives once she has found it, where
## `on_finish` names what it leaves behind when it is done. How the burning building calls in the
## fire engine — `EventManager` owns the trigger, since it already owns the successor mechanism and
## her position; see `EventManager._summon_what_has_been_sighted()`.
@export var on_sight := ""
