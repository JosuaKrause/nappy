class_name DawnPhase
extends RefCounted
## **One phase of a dawn**: a step of planning a day, which reads the dawn's context
## (`DawnContext`) and writes what it plans into it, the day's plan (`DawnContext.events()`)
## above all. `EventScheduler.build_day()` runs the day's phases in order and hands each the same
## context, so a phase is told nothing else: what it needs it asks the context, and what an
## earlier phase planned it reads there. A phase keeps nothing from one dawn to the next.
##
## A test hands `run()` a stand-in context that answers the questions it sets, with no city
## built. Model: no node. Every phase overrides `run()`.

## Plans this phase's part of the dawn into `context`.
func run(_context: DawnContext) -> void:
	assert(false, "DawnPhase.run() is overridden by every phase")
