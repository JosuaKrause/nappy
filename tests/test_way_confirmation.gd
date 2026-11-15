extends RefCounted
## `WayConfirmation`, whether a place fixed from her walk stands with a way to it from home that
## nothing drawn later can reach: checked on a loop of sidewalk laid out by hand, home at one
## corner and the place half way down the far side, so there are two ways to it, a short one along
## the top and a long one along the bottom, further apart than a draw reaches. The reach is real
## (`DayReach`, on the hand-drawn map); the draw is a stand-in (`_Draw`) that holds units by hand,
## each a point and the body it draws there, draws the ones an ask reaches, and tells the reach,
## as the manager's draw does; and tables by hand, which stand on a tile and shut no way.

## The loop's rows and columns, in tiles: a sidewalk two tiles wide along each.
const TOP := 3
const BOTTOM := 20
const LEFT := 0
const RIGHT := 38
## The column a body stands across a row at, and the place, half way down the far side.
const ACROSS := 20
const PLACE := Vector2i(39, 12)

func run(t: TestRunner) -> void:
	_test_a_place_with_nothing_left_to_draw_stands_after_one_pass(t)
	_test_a_body_drawn_on_the_way_sends_the_next_pass_down_another(t)
	_test_a_place_every_way_to_which_a_draw_shuts_is_refused(t)
	_test_a_place_with_no_way_is_refused_and_nothing_draws(t)
	_test_a_draw_that_never_settles_is_given_up(t)
	_test_a_place_a_drawn_unit_stands_on_is_refused(t)

## The units of a day, by hand: asked to draw round a point, it draws each undrawn unit within the
## reach of it (a body standing across the loop at the unit's own point), tells the walk's reach,
## and answers whether it drew any. `never_settles` makes it answer that it drew on every ask.
class _Draw extends RefCounted:
	var reach: DayReach
	## The bodies not yet drawn, each where it stands.
	var undrawn: Array[EventPlan] = []
	## Every point asked, in order.
	var asked: Array[Vector2] = []
	var never_settles := false
	## The map a tile is found on, and where tables that shut no way stand: the ones whose unit
	## has not drawn, and the ones whose unit has.
	var map: CityMap
	var undrawn_tables: Array[Vector2i] = []
	var tables: Array[Vector2i] = []

	func draws_round(at: Vector2, within: float) -> bool:
		asked.append(at)
		var drew := never_settles
		for table: Vector2i in undrawn_tables.duplicate():
			if map.tile_to_world(table).distance_to(at) <= within:
				undrawn_tables.erase(table)
				tables.append(table)
				drew = true
		for body: EventPlan in undrawn.duplicate():
			if body.placed_at().distance_to(at) > within:
				continue
			undrawn.erase(body)
			reach.shut_more([body] as Array[EventPlan])
			drew = true
		return drew

	## Whether no drawn table stands on `tile`: what the confirmation asks of the place once its
	## ground has drawn.
	func leaves_free(tile: Vector2i) -> bool:
		return not tables.has(tile)

func _loop() -> CityMap:
	var map := CityMap.new(Vector2i(40, 24))
	map.fill_rect(Rect2i(0, 0, 40, 24), GameEnums.TileType.BUILDING)
	map.fill_rect(Rect2i(LEFT, TOP, 40, 2), GameEnums.TileType.SIDEWALK)
	map.fill_rect(Rect2i(LEFT, BOTTOM, 40, 2), GameEnums.TileType.SIDEWALK)
	map.fill_rect(Rect2i(LEFT, TOP, 2, BOTTOM - TOP + 2), GameEnums.TileType.SIDEWALK)
	map.fill_rect(Rect2i(RIGHT, TOP, 2, BOTTOM - TOP + 2), GameEnums.TileType.SIDEWALK)
	map.home_rect = Rect2i(LEFT, TOP, 1, 1)
	return map

## A barricade standing across the row at `row`, at tile column `ACROSS`.
func _across(map: CityMap, row: int) -> EventPlan:
	return EventPlan.new(EventCatalogue.by_id("barricade"),
			map.tile_to_world(Vector2i(ACROSS, row)) + Vector2(0, Tuning.TILE_SIZE * 0.5))

## The draw over `map` with `bodies` still to draw, and its reach with nothing standing.
func _draw(map: CityMap, bodies: Array[EventPlan]) -> _Draw:
	var draw := _Draw.new()
	draw.map = map
	draw.reach = DayReach.of(map, [] as Array[EventPlan])
	draw.undrawn = bodies
	return draw

## Whether `way` runs along the row `row`.
static func _runs_along(way: Array[Vector2i], row: int) -> bool:
	for tile in way:
		if tile.x == ACROSS and (tile.y == row or tile.y == row + 1):
			return true
	return false

func _test_a_place_with_nothing_left_to_draw_stands_after_one_pass(t: TestRunner) -> void:
	var map := _loop()
	var draw := _draw(map, [] as Array[EventPlan])
	var way := draw.reach.way_from_home(PLACE)
	var stands := WayConfirmation.new(map, draw.reach, draw.draws_round).confirms(PLACE, draw.leaves_free)
	t.check(stands and _runs_along(way, TOP),
			"with nothing left to draw, the place stands, on the short way along the top")
	var every_step := true
	for k in range(0, way.size(), WayConfirmation.STEP):
		every_step = every_step and draw.asked.has(map.tile_to_world(way[k]))
	t.check(every_step and draw.asked.back() == map.tile_to_world(PLACE)
			and draw.asked.size() == ceili(way.size() / float(WayConfirmation.STEP)) + 1,
			"after one pass, which asked for the ground round the way step by step and round the "
			+ "place (%d asks over %d tiles)" % [draw.asked.size(), way.size()])

func _test_a_body_drawn_on_the_way_sends_the_next_pass_down_another(t: TestRunner) -> void:
	var map := _loop()
	var draw := _draw(map, [_across(map, TOP)] as Array[EventPlan])
	var stands := WayConfirmation.new(map, draw.reach, draw.draws_round).confirms(PLACE, draw.leaves_free)
	var way := draw.reach.way_from_home(PLACE)
	t.check(stands and draw.undrawn.is_empty() and draw.reach.is_shut(Vector2i(ACROSS, TOP)),
			"a unit on the short way draws a body across it, and the place still stands")
	t.check(_runs_along(way, BOTTOM) and not _runs_along(way, TOP),
			"on the long way along the bottom, which the next pass walked and found nothing to "
			+ "draw near")

func _test_a_place_every_way_to_which_a_draw_shuts_is_refused(t: TestRunner) -> void:
	var map := _loop()
	var draw := _draw(map, [_across(map, TOP), _across(map, BOTTOM)] as Array[EventPlan])
	t.check(draw.reach.reaches(PLACE), "before anything draws, the place is reached from home")
	var stands := WayConfirmation.new(map, draw.reach, draw.draws_round).confirms(PLACE, draw.leaves_free)
	t.check(not stands and draw.undrawn.is_empty() and not draw.reach.reaches(PLACE),
			"a body drawn across the short way and then one across the long way leave no way, "
			+ "and the place is refused")

func _test_a_place_with_no_way_is_refused_and_nothing_draws(t: TestRunner) -> void:
	var map := _loop()
	var draw := _draw(map, [] as Array[EventPlan])
	draw.reach.shut_more([_across(map, TOP), _across(map, BOTTOM)] as Array[EventPlan])
	var stands := WayConfirmation.new(map, draw.reach, draw.draws_round).confirms(PLACE, draw.leaves_free)
	t.check(not stands and draw.asked.is_empty(),
			"a place cut off from home is refused without a draw being asked for")

func _test_a_draw_that_never_settles_is_given_up(t: TestRunner) -> void:
	var map := _loop()
	var draw := _draw(map, [] as Array[EventPlan])
	draw.never_settles = true
	var per_pass := ceili(draw.reach.way_from_home(PLACE).size() / float(WayConfirmation.STEP)) + 1
	var stands := WayConfirmation.new(map, draw.reach, draw.draws_round).confirms(PLACE, draw.leaves_free)
	t.check(not stands and draw.asked.size() == per_pass * WayConfirmation.PASSES,
			"a place every pass of which draws again is refused once the passes run out "
			+ "(%d asks)" % draw.asked.size())

func _test_a_place_a_drawn_unit_stands_on_is_refused(t: TestRunner) -> void:
	var map := _loop()
	var draw := _draw(map, [] as Array[EventPlan])
	draw.undrawn_tables = [PLACE]
	t.check(draw.leaves_free(PLACE), "before its unit draws, nothing stands on the place")
	var stands := WayConfirmation.new(map, draw.reach, draw.draws_round) \
			.confirms(PLACE, draw.leaves_free)
	t.check(not stands and draw.tables == [PLACE] and draw.reach.reaches(PLACE),
			"a place a unit drawn round it stood its tables on is refused, though the way to it "
			+ "is open")
