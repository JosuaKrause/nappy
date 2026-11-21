class_name EventSave
extends RefCounted
## What a live event was in the middle of when it left the world, carried by its plan until it
## comes back: how far along its life it had got, how far along its route, where on its clock it
## noticed her, and each behaviour's own state. Never changed once made; `EventInstance.save()`
## makes it and a stream-in hands it to `EventInstance.restore()`.

## Seconds into its life.
var _age := 0.0
## Distance covered along its route.
var _travelled := 0.0
## Where on its own clock it noticed her, or `INF` for a row that had not.
var _noticed_at := INF
## Each behaviour's own state, keyed by the behaviour's global class name, with no entry for a
## behaviour that has nothing to carry.
var _behaviours := {}

func _init(age := 0.0, travelled := 0.0, noticed_at := INF, behaviours := {}) -> void:
	_age = age
	_travelled = travelled
	_noticed_at = noticed_at
	_behaviours = behaviours

## The save of an event that arrives `seconds` into its life with nothing else carried: what a
## plan that starts over, a warned row and a row the director sends are restored from.
static func aged(seconds: float) -> EventSave:
	return EventSave.new(seconds)

## A copy of this save at another age: a mast is restored at the broadcast clock, not its own age.
func at_age(seconds: float) -> EventSave:
	return EventSave.new(seconds, _travelled, _noticed_at, _behaviours)

## Seconds into its life.
func age() -> float:
	return _age

## Distance covered along its route.
func travelled() -> float:
	return _travelled

## Where on its own clock it noticed her, or `INF` for a row that had not.
func noticed_at() -> float:
	return _noticed_at

## One behaviour's own state, keyed by its class's global name; empty for one this save does not
## name.
func state_of(behaviour: String) -> Dictionary:
	var state: Dictionary = _behaviours.get(behaviour, {})
	return state
