@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `UnusedCalmRule`: no field reaches the calm ground she has not used. A candidate whose field
## reaches a calm area's rect is refused, one standing clear of it is allowed, and a rule handed no
## calm ground allows anything. Candidates built by hand from a catalogue row; no map, no city.

const PLACED: Array[EventScheduler.Planned] = []

func run(t) -> void:
	var cafe := EventCatalogue.by_id("cafe_tables")
	var calm := Rect2(Vector2(1000, 1000), Vector2(256, 256))
	var rule := UnusedCalmRule.new([calm] as Array[Rect2])
	var reach := cafe.field_reach()
	var inside := EventScheduler.Planned.new(cafe, calm.position - Vector2(reach * 0.5, 0.0))
	var clear := EventScheduler.Planned.new(cafe, calm.position - Vector2(reach + 64.0, 0.0))
	t.check(reach > 0.0, "the cafe has a field to reach with (%.0fpx)" % reach)
	t.check(not rule.allows(inside, Vector2i.ZERO, PLACED, PLACED),
			"a cafe whose field reaches the calm she has not used is refused")
	t.check(rule.allows(clear, Vector2i.ZERO, PLACED, PLACED),
			"one standing clear of it, its field short of the calm, is allowed")
	t.check(UnusedCalmRule.new([] as Array[Rect2]).allows(inside, Vector2i.ZERO, PLACED, PLACED),
			"and with no calm ground to keep, the same cafe is allowed")
