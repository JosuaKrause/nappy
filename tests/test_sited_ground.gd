extends RefCounted
## `SitedGround`, the tiles a row her walk lays may stand on: a crew her walk lays is offered only
## the tiles of the `AT_THE_FRONT` lane that are fronts (in front of a blank wall it can paste), a
## mast only tiles a mast site may be (`MastSites.is_eligible()`), and any other row what the walk's
## ground offers it; its one-time scan is done by `prepare()`, after which no ask reaches the ground.
##
## Run with a stand-in for the walk's ground (`_Ground`, whose answers a check sets and which counts
## its asks); the map is a generated city handed as data, since which tile a mast site may be is
## what the generator and the home street decide (`MastSites`), and the one thing the mast check
## reads that a hand-drawn map would not hold.

func run(t: TestRunner) -> void:
	_test_a_crew_is_offered_only_the_fronts_of_its_lane(t)
	_test_a_mast_is_offered_only_what_a_mast_site_may_be(t)
	_test_any_other_row_is_offered_what_the_ground_offers(t)
	_test_prepare_asks_the_ground_once_and_a_later_ask_asks_no_more(t)

const SEED := 4242

## The walk's ground as a check sets it: the set each question (`row id:side`, side -1 for the
## row's own) answers, and how many questions were asked.
class _Ground extends RowGround:
	var answers := {}
	var asks := 0

	func _init() -> void:
		super(null, null, true, RowGround.Weights.new(), func(_row: EventDef) -> bool: return false)

	## Overrides RowGround.offers_for.
	func offers_for(def: EventDef, side: int = -1) -> Dictionary:
		asks += 1
		var answer: Dictionary = answers.get("%s:%d" % [def.id(), side], {})
		return answer

static func _set_of(tiles: Array[Vector2i]) -> Dictionary:
	var found := {}
	for tile in tiles:
		found[tile] = 1
	return found

## A crew stands in front of a blank wall: of the tiles its lane offers, the ones that are fronts.
func _test_a_crew_is_offered_only_the_fronts_of_its_lane(t: TestRunner) -> void:
	var crew := Shipped.rows().by_id("poster_crew")
	var lane: Array[Vector2i] = [Vector2i(10, 10), Vector2i(11, 10), Vector2i(12, 10), Vector2i(13, 10)]
	var ground := _Ground.new()
	ground.answers["%s:%d" % [crew.id(), EventDef.Pavement.AT_THE_FRONT]] = _set_of(lane)
	var fronts := {Vector2i(11, 10): true, Vector2i(13, 10): true, Vector2i(40, 40): true}
	var sited := SitedGround.new(Shipped.rows(), null, ground, fronts)
	var offered := sited.tiles_of(crew)
	t.check(crew.stands_at_a_front() and offered.size() == 2 and offered.has(Vector2i(11, 10))
			and offered.has(Vector2i(13, 10)),
			"a crew is offered the tiles of its lane that are fronts (%s)" % [offered.keys()])
	t.check(not sited.takes(crew, Vector2i(10, 10)) and sited.takes(crew, Vector2i(13, 10)),
			"a tile of the lane that is no front is refused, a front accepted")
	t.check(not sited.takes(crew, Vector2i(40, 40)),
			"and a front outside the lane is no tile of its ground")
	var none := SitedGround.new(Shipped.rows(), null, ground, {})
	t.check(none.tiles_of(crew).is_empty(), "with no fronts handed over a crew is offered nowhere")

## A mast is offered a tile of its ground only where `MastSites.is_eligible()` says a mast site may
## be: every tile the narrowing accepts is one, and the ground holds tiles it refuses.
func _test_a_mast_is_offered_only_what_a_mast_site_may_be(t: TestRunner) -> void:
	var map := CityGenerator.generate(SEED)
	var mast := Shipped.rows().mast()
	var sidewalks: Array[Vector2i] = []
	var every := 0
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		every += 1
		if every % 9 == 0:
			sidewalks.append(tile)
	var ground := _Ground.new()
	ground.answers["%s:%d" % [mast.id(), -1]] = _set_of(sidewalks)
	var sited := SitedGround.new(Shipped.rows(), map, ground, {})
	var doors := MastSites.possible_door_points(map)
	var accepted := 0
	var refused := 0
	var disagreed := 0
	for tile in sidewalks:
		var may := MastSites.is_eligible(Shipped.rows(), map.tile_to_world(tile), map,
				doors)
		if sited.takes(mast, tile) != may:
			disagreed += 1
		if may:
			accepted += 1
		else:
			refused += 1
	t.check(accepted > 0 and refused > 0,
			"the ground holds tiles a mast site may be and tiles it may not (%d, %d)" % [accepted, refused])
	t.check(disagreed == 0, "every tile a mast is offered is one a mast site may be (%d differ)" % disagreed)
	t.check(not sited.takes(mast, Vector2i(-5, -5)), "a tile off the mast's ground is refused")

## Any other row is offered its ground as the walk gives it.
func _test_any_other_row_is_offered_what_the_ground_offers(t: TestRunner) -> void:
	var tables := Shipped.rows().by_id("cafe_tables")
	var ground := _Ground.new()
	ground.answers["%s:%d" % [tables.id(), -1]] = _set_of([Vector2i(3, 4), Vector2i(5, 6)] as Array[Vector2i])
	var sited := SitedGround.new(Shipped.rows(), null, ground, {Vector2i(3, 4): true})
	t.check(sited.takes(tables, Vector2i(3, 4)) and sited.takes(tables, Vector2i(5, 6))
			and not sited.takes(tables, Vector2i(7, 7)),
			"a row that is neither a crew nor a mast takes exactly what its ground offers, fronts or no")

## `prepare()` does the row's one scan now; every later ask, of the set or of a tile, reaches the
## ground no more.
func _test_prepare_asks_the_ground_once_and_a_later_ask_asks_no_more(t: TestRunner) -> void:
	var tables := Shipped.rows().by_id("cafe_tables")
	var ground := _Ground.new()
	ground.answers["%s:%d" % [tables.id(), -1]] = _set_of([Vector2i(3, 4)] as Array[Vector2i])
	var sited := SitedGround.new(Shipped.rows(), null, ground, {})
	sited.prepare(tables)
	var after_prepare := ground.asks
	sited.takes(tables, Vector2i(3, 4))
	sited.tiles_of(tables)
	t.check(after_prepare == 1 and ground.asks == 1,
			"prepare asks the ground once and a later ask asks no more (%d, %d)" % [after_prepare, ground.asks])
