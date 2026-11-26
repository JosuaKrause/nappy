class_name Shipped
extends RefCounted
## **The catalogue at the shipped charger timing**, the one the game plays a run on when it
## plays every charger as shipped (`EventCatalogue.for_run()` of
## `EventCatalogue.shipped_charger_timing()`), built and validated once a process: what every
## suite, rig and probe hands the pieces it builds where the game hands the run's catalogue. A
## suite asking what another timing builds makes a catalogue of its own
## (`EventCatalogue.new()`). A helper, not a suite: the runner loads only `test_*.gd`.

## The shipped catalogue.
static func rows() -> EventCatalogue:
	return EventCatalogue.for_run(EventCatalogue.shipped_charger_timing())
