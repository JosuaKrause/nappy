class_name FakeWalkEvents
extends WalkEvents
## A stand-in for the walk's events whose answers a check sets: handed to a placement made while
## she walks (`EventScheduler.WalkSiting`) in place of the real one, so the check plans no walk. It
## answers what a siting asks (the walk's plans, every plan but the one being sited, where today's
## doors stand and the day's calm areas) and records the one write a placement makes (`add()`).
## The real object's own logic is checked once, in `tests/test_walk_events.gd`. A helper, not a
## suite: the runner loads only `test_*.gd`.

## The plans `add()` was handed, in order.
var added: Array[EventScheduler.Planned] = []

var _fake_plans: Array[EventScheduler.Planned] = []
var _fake_calm: CalmAreas = null
var _fake_doors := PackedVector2Array()

## Sets the walk's plans.
func set_plans(plans: Array[EventScheduler.Planned]) -> FakeWalkEvents:
	_fake_plans = plans.duplicate()
	return self

## Sets the day's calm areas.
func set_calm(calm: CalmAreas) -> FakeWalkEvents:
	_fake_calm = calm
	return self

## Sets where today's doors stand.
func set_doors(doors: PackedVector2Array) -> FakeWalkEvents:
	_fake_doors = doors
	return self

## Overrides WalkEvents.add.
func add(plan: EventScheduler.Planned) -> void:
	added.append(plan)
	_fake_plans.append(plan)

## Overrides WalkEvents.plans.
func plans() -> Array[EventScheduler.Planned]:
	return _fake_plans

## Overrides WalkEvents.everything_but.
func everything_but(besides: EventScheduler.Planned = null) -> Array[EventScheduler.Planned]:
	var others: Array[EventScheduler.Planned] = []
	for plan in _fake_plans:
		if plan != besides:
			others.append(plan)
	return others

## Overrides WalkEvents.doors.
func doors() -> PackedVector2Array:
	return _fake_doors

## Overrides WalkEvents.calm.
func calm() -> CalmAreas:
	return _fake_calm
