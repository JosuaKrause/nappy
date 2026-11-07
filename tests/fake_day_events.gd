class_name FakeDayEvents
extends DayEvents
## A stand-in for the day's planned events whose answers a check sets: handed to `DayRepairs`'
## two repairs in place of the real one, so the check builds no city and plans no day. It
## answers what the repairs ask (which rows spoil an area, which block the way) and takes the
## one write they make (`remove()`). The real object's own logic is checked once, in
## `tests/test_day_events.gd`.
##
## A removal is recorded (`removed`) and takes the row out of every answer the check set, so a
## repair that drops a body and asks again sees its own drop, as it does of the real object. A
## helper, not a suite: the runner loads only `test_*.gd`.

## The rows `remove()` was asked to take out, in order.
var removed: Array[EventScheduler.Planned] = []

var _fake_spoilers := {}
var _fake_obstructions: Array[EventScheduler.Planned] = []
var _fake_standing_obstructions: Array[EventScheduler.Planned] = []

## Sets the rows spoiling `block`.
func set_spoilers(block: Vector2i, rows: Array[EventScheduler.Planned]) -> FakeDayEvents:
	_fake_spoilers[block] = rows.duplicate()
	return self

## Sets the rows that block the way, in plan order.
func set_obstructions(rows: Array[EventScheduler.Planned]) -> FakeDayEvents:
	_fake_obstructions = rows.duplicate()
	return self

## Sets the bodies standing for the whole plan that block the way: the day's seals and wall.
func set_standing_obstructions(rows: Array[EventScheduler.Planned]) -> FakeDayEvents:
	_fake_standing_obstructions = rows.duplicate()
	return self

## Overrides DayEvents.remove.
func remove(row: EventScheduler.Planned) -> void:
	removed.append(row)
	_fake_obstructions.erase(row)
	for block: Vector2i in _fake_spoilers:
		(_fake_spoilers[block] as Array).erase(row)

## Overrides DayEvents.standing_obstructions.
func standing_obstructions() -> Array[EventScheduler.Planned]:
	return _fake_standing_obstructions.duplicate()

## Overrides DayEvents.spoilers_of.
func spoilers_of(block: Vector2i) -> Array[EventScheduler.Planned]:
	var found: Array[EventScheduler.Planned] = []
	found.assign(_fake_spoilers.get(block, []))
	return found

## Overrides DayEvents.is_spoiled.
func is_spoiled(block: Vector2i) -> bool:
	return not spoilers_of(block).is_empty()

## Overrides DayEvents.obstructions.
func obstructions() -> Array[EventScheduler.Planned]:
	return _fake_obstructions.duplicate()
