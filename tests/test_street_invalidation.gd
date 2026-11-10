@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `StreetInvalidation`, the rules a walk composes, with each rule's own suite holding the rule. Here:
## a candidate a rule refuses has no room (`-INF`); one no rule refuses has the room round it, all
## of it (`INF`) where nothing stands near; the escape's flag adds one notice at a time; and a pacing
## man whose beat walls his sidewalk is given a wall's role. On a bare map with no route tree, so
## the route rules ask nothing.

const NONE: Array[EventScheduler.Planned] = []

func run(t) -> void:
	var map := CityMap.new()
	var cafe := EventCatalogue.by_id("cafe_tables")
	var calm := Rect2(Vector2(1000, 1000), Vector2(256, 256))
	var rules := StreetInvalidation.new(map, null, {}, [calm] as Array[Rect2], PackedVector2Array(),
			false)
	var in_the_calm := EventScheduler.Planned.new(cafe, calm.get_center())
	var clear := EventScheduler.Planned.new(cafe, Vector2(3000, 3000))
	t.check(rules.room(in_the_calm, GameEnums.BlockerRole.FRICTION, Vector2i.ZERO, NONE, NONE) == -INF,
			"a candidate a rule refuses has no room")
	t.check(rules.room(clear, GameEnums.BlockerRole.FRICTION, Vector2i.ZERO, NONE, NONE) == INF,
			"one no rule refuses, with nothing near, has all the room there is")
	t.check(clear.role == GameEnums.BlockerRole.FRICTION, "and keeps the role it was asked with")
	var flock := EventCatalogue.by_id("pigeon_flock")
	var placed: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(flock, Vector2(5000, 5000))]
	var beside := EventScheduler.Planned.new(flock, Vector2(5000 + flock.notice_within(), 5000))
	var day := StreetInvalidation.new(map, null, {}, [] as Array[Rect2], PackedVector2Array(), false)
	var escape := StreetInvalidation.new(map, null, {}, [] as Array[Rect2], PackedVector2Array(), true)
	t.check(day.room(beside, GameEnums.BlockerRole.FRICTION, Vector2i.ZERO, placed, placed) != -INF,
			"a day lets two waiting rows notice her from the same ground")
	t.check(escape.room(beside, GameEnums.BlockerRole.FRICTION, Vector2i.ZERO, placed, placed) == -INF,
			"the escape's walk, one notice at a time, does not")
