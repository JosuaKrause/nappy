class_name EventBehaviour
extends RefCounted
## **One thing an event does, owning the state that thing changes**: a hold's clock, a flock's
## birds, a pursuer's chase, a car's give-way, a departure's way out. An `EventInstance` is the
## body every behaviour moves — its row, its place and heading, its phase, its notice clock, its
## field — and a catalogue row's data decides which behaviours it is composed of
## (`EventBehaviours.compose()`), so a row that needs two gets both and no class stands for one
## event type.
##
## **A behaviour is part of its event**, not a client of it: it reads and moves the event's body
## (`_heading`, `_path_travelled`, `_navigator`, `_mover`, `_obstruction`) as the event's own code
## did, and changes its phase only through `EventInstance.transition()`. What the rest of the game
## asks of a behaviour it asks of the event, which answers for it.
##
## **Each saves and restores its own state** (`save()`, `restore()`), so a plan streamed out and
## back in comes back as it was (`EventInstance.save_state()`). What cannot round-trip — another
## instance it holds, a node it built — is left out, and the behaviour says so where it keeps it.

## The event this behaviour is part of.
var event: EventInstance
## Whether `step()` runs in the event's ordinary tick. False for one the event runs in a tick of
## its own (`EventHold`, which freezes everything else while it runs).
var steps_each_tick := true

## Attaches this behaviour to `owner`, once, as the event is set up.
func attach(owner: EventInstance) -> void:
	event = owner

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
