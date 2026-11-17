class_name FakeSitingMaker
extends SitingMaker
## A stand-in for what makes a day's siting (`SitingMaker`) whose answer a check sets: it makes
## nothing from a world and answers the siting it was handed, and it records each ask, so a check
## sees what `EventsAhead` asks for a siting and with what, without growing a city. A helper, not a
## suite: the runner loads only `test_*.gd`.

## What each ask was given, in order, as `[day, tree, ground]`.
var made: Array[Array] = []

var _fake_siting: EventScheduler.WalkSiting

## A maker that answers `siting` to every ask.
func _init(siting: EventScheduler.WalkSiting) -> void:
	super(null, null)
	_fake_siting = siting

## Overrides SitingMaker.make.
func make(day: int, tree: RouteTree, ground: RowGround) -> EventScheduler.WalkSiting:
	made.append([day, tree, ground])
	return _fake_siting
