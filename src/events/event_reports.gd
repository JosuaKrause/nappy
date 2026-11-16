class_name EventReports
extends RefCounted
## **What a day's events report to whoever listens**: the one place the events' signals go out on
## the bus the manager was handed (`EventManager.use_bus()`). One object for a manager's whole
## life, made by its `EventWorld` (`EventWorld.reports()`) and shared by every part that has
## something to say: the manager, its encounter watch, its spawner, `EventsAhead`, the doors'
## controller, each live event and its charge's record. So the bus is handed in once, at any time,
## and reaches every one of them, a live event made before it included.
##
## **With no bus handed in, nothing is told**: a manager a suite makes on its own, or a live event
## made by hand (`EventInstance.new()`), reports to nobody and plays the same. Nothing here decides
## anything, and no part reads back what it reported.
##
## **One teller a signal, named `tell_` and the signal's own name** (`EventBus`'s own doc on each
## says when it is sent and who listens), so a search for a signal's name finds its sender, its
## teller here and its listeners.

## The event bus script, so the bus handed in has a class and a signal named here is checked when
## this file is parsed.
const _BUS := preload("res://src/autoload/event_bus.gd")

## The bus the reports go out on, handed in by `use_bus()`; none, and they go nowhere.
var _bus: _BUS

## Hands in the bus every report goes out on from now on, or null for none.
func use_bus(bus: _BUS) -> void:
	_bus = bus

# ------------------------------------------------------------- a live event ---

func tell_event_telegraphed(instance: EventInstance) -> void:
	if _bus:
		_bus.event_telegraphed.emit(instance)

func tell_event_activated(instance: EventInstance) -> void:
	if _bus:
		_bus.event_activated.emit(instance)

func tell_hard_fail_triggered(reason: String) -> void:
	if _bus:
		_bus.hard_fail_triggered.emit(reason)

func tell_event_sighted(id: String) -> void:
	if _bus:
		_bus.event_sighted.emit(id)

func tell_event_lit_unmet(id: String) -> void:
	if _bus:
		_bus.event_lit_unmet.emit(id)

func tell_player_detained(id: String) -> void:
	if _bus:
		_bus.player_detained.emit(id)

func tell_poster_pursuit_sent() -> void:
	if _bus:
		_bus.poster_pursuit_sent.emit()

# ----------------------------------------------------------------- a charge ---

func tell_pursuit_warned(id: String) -> void:
	if _bus:
		_bus.pursuit_warned.emit(id)

func tell_pursuit_began(id: String) -> void:
	if _bus:
		_bus.pursuit_began.emit(id)

func tell_pursuit_caught(id: String) -> void:
	if _bus:
		_bus.pursuit_caught.emit(id)

func tell_pursuit_cut_short(id: String) -> void:
	if _bus:
		_bus.pursuit_cut_short.emit(id)

func tell_pursuit_ended(id: String, shaken_off: bool) -> void:
	if _bus:
		_bus.pursuit_ended.emit(id, shaken_off)

# ----------------------------------------------- encounters and her running ---

func tell_encounter_seen(day: int, name: String) -> void:
	if _bus:
		_bus.encounter_seen.emit(day, name)

func tell_encounter_influenced(day: int, name: String, seen: bool) -> void:
	if _bus:
		_bus.encounter_influenced.emit(day, name, seen)

func tell_run_bout_began(day: int) -> void:
	if _bus:
		_bus.run_bout_began.emit(day)

# -------------------------------------------------------------- the pelican ---

func tell_pelican_spawned(instance: EventInstance) -> void:
	if _bus:
		_bus.pelican_spawned.emit(instance)

func tell_pelican_sighted(instance: EventInstance) -> void:
	if _bus:
		_bus.pelican_sighted.emit(instance)

func tell_pelican_excited_her(instance: EventInstance) -> void:
	if _bus:
		_bus.pelican_excited_her.emit(instance)

func tell_pelican_struck_her(instance: EventInstance) -> void:
	if _bus:
		_bus.pelican_struck_her.emit(instance)
