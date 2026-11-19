class_name FakeWalkEvents
extends WalkEvents
## A stand-in for the walk's events whose answers a check sets: handed to a placement made while
## she walks (`WalkSiting`) in place of the real one, so the check plans no walk. It
## answers what a siting asks (the walk's plans, every plan but the one being sited, where today's
## doors stand, none, and the day's calm areas, none) and records the one write a placement makes (`add()`).
## The real object's own logic is checked once, in `tests/test_walk_events.gd`. A helper, not a
## suite: the runner loads only `test_*.gd`.

## The plans `add()` was handed, in order.
var added: Array[EventPlan] = []

var _fake_plans: Array[EventPlan] = []

## Sets the walk's plans.
func set_plans(plans: Array[EventPlan]) -> FakeWalkEvents:
	_fake_plans = plans.duplicate()
	return self

## Overrides WalkEvents.add.
func add(plan: EventPlan) -> void:
	added.append(plan)
	_fake_plans.append(plan)

## Overrides WalkEvents.plans.
func plans() -> Array[EventPlan]:
	return _fake_plans

## Overrides WalkEvents.everything_but.
func everything_but(besides: EventPlan = null) -> Array[EventPlan]:
	var others: Array[EventPlan] = []
	for plan in _fake_plans:
		if plan != besides:
			others.append(plan)
	return others

## Overrides WalkEvents.doors.
func doors() -> PackedVector2Array:
	return PackedVector2Array()

## Overrides WalkEvents.calm.
func calm() -> CalmAreas:
	return null
