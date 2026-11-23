class_name FakeExcitement
extends EventExcitement
## A stand-in for an event's excitement source, handed to a `FakeEvent` to answer `source()` with,
## so a look reads the strength of its event's caret from what the suite set, not from a phase, a
## field and where she is. It answers the one question a look asks of it.

## The caret the event shows, what `caret_strength()` answers: 0 none, 1 costly, 2 lethal.
var caret := 0

func _init(owner: EventInstance) -> void:
	super(owner)

## Overrides ExcitementSource.caret_strength.
func caret_strength() -> int:
	return caret
