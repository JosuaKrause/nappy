extends RefCounted
## `EventScheduler.RuledLocationGround` once it judges against the walk (`judge_against()`): what the
## day's rules are handed at each ask is the walk's plans as they stand then. Run with stand-ins for
## what it is handed: the rules (`_Rules`, which refuse a candidate within
## `EventScheduler.EVENT_SPACING_ANY` of any plan they are handed as placed, the refusal that never
## bends), a location's own ground (`_Fit`, every tile of the location, the candidate built in the
## tile's middle) and the walk (`FakeWalkEvents`); the locations are built by hand. What the day's
## real rules refuse is theirs, checked in `tests/test_route_rules.gd` and the placement suites.
##
## - **A plan her walk sites on a plan the walk already holds is read by the next ask**: a poster
##   crew the walk holds with no position, given one in the middle of an undrawn location
##   (`EventDirector.site_what_is_on_her_way()` writes the place into the plan the walk holds), leaves
##   no tile of that location offered on the next ask, though the walk gained no plan.
## - **A plan the ground stands is read before the walk takes it**: of two locations drawn in one
##   batch, the second is judged with the first standing, before the walk has been handed it.

const ROW := "dog_walker"

## Rules that refuse a candidate within the any-two spacing of a plan handed in as placed, and
## otherwise stand it clear.
class _Rules extends StreetInvalidation:
	func _init() -> void:
		super(CityMap.new(), null, {}, [] as Array[Rect2], PackedVector2Array(), false)

	## Overrides StreetInvalidation.room.
	func room(candidate: EventScheduler.Planned, _role: GameEnums.BlockerRole, _tile: Vector2i,
			placed: Array[EventScheduler.Planned], _around: Array[EventScheduler.Planned]) -> float:
		for plan in placed:
			if plan.placed_at().distance_to(candidate.placed_at()) < EventScheduler.EVENT_SPACING_ANY:
				return -INF
		return INF

## A location's own ground: every tile of it, the candidate built in the middle of the tile.
class _Fit extends LocationFit:
	func _init() -> void:
		super(1, CityMap.new(), {}, null, false)

	## Overrides LocationFit.tiles.
	func tiles(_def: EventDef, location: Location) -> Array[Vector2i]:
		var found: Array[Vector2i] = []
		var rect := location.tiles()
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				found.append(Vector2i(x, y))
		return found

	## Overrides LocationFit.build.
	func build(def: EventDef, tile: Vector2i, _rng: RandomNumberGenerator) -> EventScheduler.Planned:
		return EventScheduler.Planned.new(def, (Vector2(tile) + Vector2.ONE * 0.5) * Tuning.TILE_SIZE)

func run(t) -> void:
	_test_a_plan_sited_in_place_is_read_by_the_next_ask(t)
	_test_a_plan_stood_is_read_before_the_walk_takes_it(t)

func _ground() -> EventScheduler.RuledLocationGround:
	return EventScheduler.RuledLocationGround.new(1, 0, CityMap.new(), DayEvents.new(), null,
			_Fit.new(), _Rules.new())

## A sidewalk location `size` tiles square at `x` along an east-west street: at two by two, every
## tile of it is within the any-two spacing of its middle.
static func _location(x: int, size := 2) -> Location:
	var tiles := Rect2i(Vector2i(x, 0), Vector2i(size, size))
	return Location.new(StreetNetwork.Segment.new(Vector2i(0, 0), true), 0, tiles,
			Vector2(tiles.get_center()) * Tuning.TILE_SIZE, PlacementView.View.ON_THE_ROUTE, true,
			Location.Kind.SIDEWALK)

func _test_a_plan_sited_in_place_is_read_by_the_next_ask(t) -> void:
	var crew := EventScheduler.Planned.new(EventCatalogue.by_id("poster_crew"), Vector2.INF)
	var walk := FakeWalkEvents.new().set_plans([crew] as Array[EventScheduler.Planned])
	var ground := _ground()
	ground.judge_against(walk)
	var location := _location(0)
	var row := EventCatalogue.by_id(ROW)
	t.check(ground.offer(row, location) != null,
			"with the crew placed nowhere, the location is offered the dog walker")
	# Her walk sites the crew in the middle of the location, on the plan the walk already holds.
	crew.position = location.centre()
	var after := ground.offer(row, location)
	t.check(after == null,
			"sited in its middle, the crew leaves no tile of the location offered, though the walk gained no plan (%s)"
			% ["nothing" if after == null else "%.0fpx from the crew" % after.placed_at().distance_to(crew.placed_at())])

func _test_a_plan_stood_is_read_before_the_walk_takes_it(t) -> void:
	var walk := FakeWalkEvents.new()
	var ground := _ground()
	ground.judge_against(walk)
	var row := EventCatalogue.by_id(ROW)
	var first := ground.offer(row, _location(0, 1))
	t.check(first != null, "the first location of the batch is offered the dog walker")
	if first == null:
		return
	ground.stand(first)
	var second := ground.offer(row, _location(1, 1))
	t.check(second == null and walk.plans().is_empty(),
			"the location next to it, a tile on, drawn in the same batch, is judged with the first standing before the walk holds it (%s)"
			% ["nothing offered" if second == null else "%.0fpx apart" % second.placed_at().distance_to(first.placed_at())])
