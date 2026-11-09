extends RefCounted
## `OneNoticeRule`: no two waiting rows notice her from the same ground. A pigeon flock (it notices
## her within 150px) beside one already placed, their notices overlapping, is refused; one twice
## that apart is allowed; a row that notices nobody is allowed anywhere. On a bare map: where a
## flock stands is where it was built.

const NONE: Array[EventScheduler.Planned] = []

func run(t) -> void:
	var map := CityMap.new()
	var flock := EventCatalogue.by_id("pigeon_flock")
	var reach := flock.notice_within()
	var placed: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(flock, Vector2(800, 800))]
	var rule := OneNoticeRule.new(map)
	var overlapping := EventScheduler.Planned.new(flock, Vector2(800 + reach, 800))
	var apart := EventScheduler.Planned.new(flock, Vector2(800 + 2.0 * reach + 32.0, 800))
	var cafe := EventScheduler.Planned.new(EventCatalogue.by_id("cafe_tables"), Vector2(800 + reach, 800))
	t.check(reach > 0.0, "the flock notices her from a distance (%.0fpx)" % reach)
	t.check(not rule.allows(overlapping, Vector2i.ZERO, placed, placed),
			"a flock whose notice overlaps another's is refused")
	t.check(rule.allows(apart, Vector2i.ZERO, placed, placed),
			"one whose notice stays clear of it is allowed")
	t.check(rule.allows(cafe, Vector2i.ZERO, placed, placed),
			"and a row that notices nobody is allowed beside it")
	t.check(rule.allows(overlapping, Vector2i.ZERO, NONE, NONE),
			"and the overlapping flock is allowed where nothing waits")
