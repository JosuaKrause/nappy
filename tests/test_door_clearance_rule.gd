extends RefCounted
## `DoorClearanceRule`: nothing's field comes within `Tuning.CHECKPOINT_EVENT_GAP` of a region door.
## A candidate closer than the gap and its own reach is refused, one past it allowed, and a day with
## no doors refuses nothing. Candidates built by hand; no map.

const PLACED: Array[EventScheduler.Planned] = []

func run(t) -> void:
	var cafe := EventCatalogue.by_id("cafe_tables")
	var door := Vector2(2000, 2000)
	var rule := DoorClearanceRule.new(PackedVector2Array([door]))
	var limit := Tuning.CHECKPOINT_EVENT_GAP + cafe.field_reach()
	var near := EventScheduler.Planned.new(cafe, door + Vector2(limit - 16.0, 0.0))
	var far := EventScheduler.Planned.new(cafe, door + Vector2(limit + 16.0, 0.0))
	t.check(not rule.allows(near, Vector2i.ZERO, PLACED, PLACED),
			"a cafe whose field comes inside the door's clear ground is refused")
	t.check(rule.allows(far, Vector2i.ZERO, PLACED, PLACED), "one past the gap is allowed")
	t.check(DoorClearanceRule.new(PackedVector2Array()).allows(near, Vector2i.ZERO, PLACED, PLACED),
			"and on a day with no doors the same cafe is allowed")
