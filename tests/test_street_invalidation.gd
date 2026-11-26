extends RefCounted
## `StreetInvalidation`, the rules a walk composes, with each rule's own suite holding the rule. Here:
## a candidate a rule refuses has no room (`-INF`); one no rule refuses has the room round it, all
## of it (`INF`) where nothing stands near; the escape's flag adds one notice at a time; and a pacing
## man whose beat walls his sidewalk is given a wall's role. On a bare map with no route tree, so
## the route rules ask nothing. **Which rules a day and the escape compose**, on a hand-drawn map
## (`StreetMap.full()`) under a fake corridor that names the routes, and with a fake walk's ground
## that keeps nothing (the escape's own rule, `WalkGround`, has its suite): a day with a corridor
## asks the line rule and the one-sidewalk rule, each naming itself among the refusals, and a walk
## kept open asks the one-sidewalk rule nowhere.

## A walk's ground that keeps nothing, so only the rules round it refuse.
class _OpenWalk extends WalkGround:
	func _init(map: CityMap) -> void:
		super(map)

	## Overrides WalkGround.accepts.
	func accepts(_candidate: EventPlan) -> bool:
		return true

const NONE: Array[EventPlan] = []

func run(t: TestRunner) -> void:
	var map := CityMap.new()
	var cafe := Shipped.rows().by_id("cafe_tables")
	var calm := Rect2(Vector2(1000, 1000), Vector2(256, 256))
	var rules := StreetInvalidation.new(map, null, [calm] as Array[Rect2], PackedVector2Array(), null)
	var in_the_calm := EventPlan.new(cafe, calm.get_center())
	var clear := EventPlan.new(cafe, Vector2(3000, 3000))
	t.check(rules.room(in_the_calm, GameEnums.BlockerRole.FRICTION, Vector2i.ZERO, NONE, NONE) == -INF,
			"a candidate a rule refuses has no room")
	t.check(rules.room(clear, GameEnums.BlockerRole.FRICTION, Vector2i.ZERO, NONE, NONE) == INF,
			"one no rule refuses, with nothing near, has all the room there is")
	t.check(clear.role() == GameEnums.BlockerRole.FRICTION, "and keeps the role it was asked with")
	var flock := Shipped.rows().by_id("pigeon_flock")
	var placed: Array[EventPlan] = [EventPlan.new(flock, Vector2(5000, 5000))]
	var beside := EventPlan.new(flock, Vector2(5000 + flock.notice_within(), 5000))
	var day := StreetInvalidation.new(map, null, [] as Array[Rect2], PackedVector2Array(), null)
	var escape := StreetInvalidation.new(map, null, [] as Array[Rect2], PackedVector2Array(),
			GamePlanBuilder.over(map))
	t.check(day.room(beside, GameEnums.BlockerRole.FRICTION, Vector2i.ZERO, placed, placed) != -INF,
			"a day lets two waiting rows notice her from the same ground")
	t.check(escape.room(beside, GameEnums.BlockerRole.FRICTION, Vector2i.ZERO, placed, placed) == -INF,
			"the escape's walk, one notice at a time, does not")
	_test_a_day_and_the_escape_compose_their_rules(t)

## A route along the west street's south sidewalk of junction (3, 3), across its box and down the
## south street's east sidewalk; the street east of the box beside it. A robbery on the walked
## sidewalk is a body no line rule asks, so a stall across from it is the one-sidewalk rule's.
func _test_a_day_and_the_escape_compose_their_rules(t: TestRunner) -> void:
	var map := StreetMap.full()
	var tiles: Array[Vector2i] = []
	for x in range(34, 42):
		tiles.append_array([Vector2i(x, 46), Vector2i(x, 47)] as Array[Vector2i])
	for y in range(48, 56):
		tiles.append_array([Vector2i(46, y), Vector2i(47, y)] as Array[Vector2i])
	var corridor := FakeCorridor.new().set_routes(
			[Vector3i(2, 3, 0), Vector3i(3, 3, 1)] as Array[Vector3i],
			[Vector2i(3, 3)] as Array[Vector2i], tiles).set_beside([Vector3i(3, 3, 0)] as Array[Vector3i])
	var none: Array[Rect2] = []
	var day := StreetInvalidation.new(map, corridor, none, PackedVector2Array(), null)
	var escape := StreetInvalidation.new(map, corridor, none, PackedVector2Array(), null,
			_OpenWalk.new(map))
	var robbery := EventPlan.new(Shipped.rows().by_id("alley_robbery"),
			map.tile_to_world(Vector2i(37, 47)))
	var first: Array[EventPlan] = [robbery]
	var across := EventPlan.new(Shipped.rows().by_id("market_stall"),
			map.tile_to_world(Vector2i(37, 42)))
	t.check(robbery.obstructs() and not robbery.counts_against_the_line(),
			"the robbery is a body the line rules do not ask")
	t.check(day.room(across, GameEnums.BlockerRole.WALL, Vector2i(37, 42), first, first) == -INF
			and day.refusals().has("OneSidewalkOpenRule"),
			"a day refuses a stall across her route's street from a robbery, by the one-sidewalk rule")
	t.check(escape.room(across, GameEnums.BlockerRole.WALL, Vector2i(37, 42), first, first) != -INF,
			"a walk kept open by its own rule does not ask it")
	var blower := EventPlan.new(Shipped.rows().by_id("leaf_blower"),
			map.tile_to_world(Vector2i(51, 46)))
	t.check(day.room(blower, GameEnums.BlockerRole.WALL, Vector2i(51, 46), NONE, NONE) == -INF
			and day.refusals().has("RouteLineRule"),
			"a day refuses a leaf blower cutting her line at the box's seam, by the line rule")
