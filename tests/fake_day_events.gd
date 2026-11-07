class_name FakeDayEvents
extends DayEvents
## A stand-in for the day's planned events whose answers a check sets: handed to whatever is handed
## `DayEvents` (`WinnableDay`'s repairs) in place of the real one, so the check builds no city and
## plans no day. The real object's own logic is checked once, in `tests/test_day_events.gd`.
##
## Its writes record what they were asked (`removed`, `added`), and a removal takes the row out of
## every answer the check set, so a consumer that drops a body and asks again sees its own drop, as
## it does of the real object.
## A helper, not a suite: the runner loads only `test_*.gd`.

## The rows `remove()` was asked to take out, in order.
var removed: Array[EventScheduler.Planned] = []
## The rows `add()` was asked to put in, in order.
var added: Array[EventScheduler.Planned] = []

var _fake_rows: Array[EventScheduler.Planned] = []
var _fake_standing: Array[EventScheduler.Planned] = []
var _fake_standing_obstructions: Array[EventScheduler.Planned] = []
var _fake_spoilers := {}
var _fake_obstructions: Array[EventScheduler.Planned] = []
var _fake_pursuit := false

## Sets the rows, in plan order.
func set_placements(rows: Array[EventScheduler.Planned]) -> FakeDayEvents:
	_fake_rows = rows.duplicate()
	return self

## Sets the rows spoiling `block`.
func set_spoilers(block: Vector2i, rows: Array[EventScheduler.Planned]) -> FakeDayEvents:
	_fake_spoilers[block] = rows.duplicate()
	return self

## Sets the rows that block the way, in plan order.
func set_obstructions(rows: Array[EventScheduler.Planned]) -> FakeDayEvents:
	_fake_obstructions = rows.duplicate()
	return self

## Sets the bodies standing for the whole plan, and those of them that block the way.
func set_standing(rows: Array[EventScheduler.Planned],
		obstructing: Array[EventScheduler.Planned] = []) -> FakeDayEvents:
	_fake_standing = rows.duplicate()
	_fake_standing_obstructions = obstructing.duplicate()
	return self

## Sets whether a row is a pursuit.
func set_pursuit(is_one: bool) -> FakeDayEvents:
	_fake_pursuit = is_one
	return self

## Overrides DayEvents.add.
func add(row: EventScheduler.Planned) -> void:
	added.append(row)
	_fake_rows.append(row)

## Overrides DayEvents.add_all.
func add_all(rows: Array[EventScheduler.Planned]) -> void:
	for row in rows:
		add(row)

## Overrides DayEvents.remove.
func remove(row: EventScheduler.Planned) -> void:
	removed.append(row)
	_fake_rows.erase(row)
	_fake_obstructions.erase(row)
	for block: Vector2i in _fake_spoilers:
		(_fake_spoilers[block] as Array).erase(row)

## Overrides DayEvents.replace.
func replace(old: EventScheduler.Planned, new: EventScheduler.Planned) -> void:
	var at := _fake_rows.find(old)
	if at >= 0:
		_fake_rows[at] = new

## Overrides DayEvents.placements.
func placements() -> Array[EventScheduler.Planned]:
	return _fake_rows.duplicate()

## Overrides DayEvents.size.
func size() -> int:
	return _fake_rows.size()

## Overrides DayEvents.standing.
func standing() -> Array[EventScheduler.Planned]:
	return _fake_standing.duplicate()

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

## Overrides DayEvents.has_a_pursuit.
func has_a_pursuit() -> bool:
	return _fake_pursuit
