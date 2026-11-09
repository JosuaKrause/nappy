class_name RoadblockGround
extends RefCounted
## **What the roadblock phase asks of the day it places into** (`RoadblockPhase`): the route tiles a
## roadblock is to be close by, the roadblock a section would take, the route tiles one would be
## close by, how far round one standing its offers can change, and standing one in the day. The phase decides which sections take one; this answers
## for the day's ground, so the phase is handed it (dependency injection) and a test hands a
## stand-in holding the answers it sets.
##
## The day's own is `EventScheduler.RuledRoadblockGround`: today's placement rules and the walk
## along her paths the task measures close by with. Every method here is to be overridden.

## The route tiles the phase aims to leave none of without a roadblock close by.
func route_tiles() -> Array[Vector2i]:
	assert(false, "RoadblockGround.route_tiles() is overridden by every implementation")
	return []

## The roadblock `section` would take, stood where it fits inside the section, or null where it
## fits nowhere in it or the day's rules leave it invalid there given what already stands.
func offer(_section: Location) -> EventScheduler.Planned:
	assert(false, "RoadblockGround.offer() is overridden by every implementation")
	return null

## The route tiles `plan` would be close by, given what already stands.
func covers(_plan: EventScheduler.Planned) -> Array[Vector2i]:
	assert(false, "RoadblockGround.covers() is overridden by every implementation")
	return []

## How far round a roadblock just stood an offer can change: the farthest the ground's rules reach
## between two rows. The phase asks again every offer of a section within it.
func reoffer_within() -> float:
	assert(false, "RoadblockGround.reoffer_within() is overridden by every implementation")
	return 0.0

## Stands `plan` in the day, so what is offered and covered after it is asked with it standing.
func stand(_plan: EventScheduler.Planned) -> void:
	assert(false, "RoadblockGround.stand() is overridden by every implementation")
