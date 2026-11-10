class_name EventBehaviour
extends RefCounted
## **One thing an event does, owning the state that thing changes**: a hold's clock, a flock's
## birds, a pursuer's chase, a car's give-way, a departure's way out. An `EventInstance` is the
## body every behaviour moves — its place and heading, its phase, its notice clock, its field — and
## a catalogue row's data decides which behaviours it is composed of (`EventBehaviours.compose()`),
## so a row that needs two gets both and no class stands for one event type.
##
## **A behaviour is a part of its event, and asks it through one narrow interface**: what changes
## (its place, heading, way covered, clocks and phase) through the figure it moves
## (`EventInstance.Figure`), told what happened rather than written field by field, and the phase
## changed only through `EventInstance.transition()`, which it asks for with `Figure.begin()`. What
## never changes under it — its settings (the row, where its part has no settings class of its
## own), the map, the navigator, what it walks as, where she is, and the behaviours beside it it
## works with — it is handed by the composer and holds. What the rest of the game asks of a
## behaviour it asks of the event, which answers for it.
##
## **The pursuit, the man on foot, the barrier post, the investigation and the car still hold their
## event** (`event`, given by `attach()`) and read its fields; every other behaviour is handed its
## figure and never holds the event.
##
## **Each saves and restores its own state** (`save()`, `restore()`), so a plan streamed out and
## back in comes back as it was (`EventInstance.save_behaviours()`). What cannot round-trip — another
## instance it holds, a node it built — is left out, and the behaviour says so where it keeps it.

## The event this behaviour is part of, for a behaviour that still holds it (`attach()`); null for
## one handed its figure.
var event: EventInstance
## The figure it moves (`EventInstance.Figure`), handed in as the event is set up; null for a
## behaviour that still holds its event.
var _figure: EventInstance.Figure
## Where she is (`WhereSheIs`): its event's own handle, handed in as the event is set up, so the
## behaviour and its event ask one object.
var _where := WhereSheIs.nowhere()
## Whether `step()` runs in the event's ordinary tick. False for one the event runs in a tick of
## its own (`EventHold`, which freezes everything else while it runs).
var steps_each_tick := true

## Attaches a behaviour that still holds its event to `owner`, once, as the event is set up, with
## where she is as `owner` hears it.
func attach(owner: EventInstance, where: WhereSheIs) -> void:
	event = owner
	_where = where

## One tick of what it does while its event is neither leaving nor held in a conversation.
func step(_delta: float) -> void:
	pass

## One tick while its event is leaving.
func step_leaving(_delta: float) -> void:
	pass

## Its own state, as plain values a plan can carry while its event is out of the world.
func save() -> Dictionary:
	return {}

## Puts back what `save()` gave.
func restore(_state: Dictionary) -> void:
	pass
