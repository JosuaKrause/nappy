extends RefCounted
## `BodyStance.pieces_at()`: where each piece of a body built at a point stands, which every reader of
## a planned body's layout (the walk's ground, the map's record, the route rig) takes from it.
##
## Rows are the catalogue's own, built as they are (data). The map is a stand-in per street axis
## (`tests/east_west_street.gd` and the north-south twin below), so no city is generated and the
## street a body lies along is the one the test says. The expected values are read off the rows'
## declared parts, so a redrawn crash picture does not break the suite.

## A map that answers every tile as on a north-south street and on no east-west one: a spread or a
## wide scene runs across the screen, as the twin of `EastWestStreet`.
class NorthSouthStreet extends WorldMap:
	## Overrides WorldMap.corridor_offsets.
	func corridor_offsets(_tile: Vector2i) -> Vector2i:
		return Vector2i(0, -1)

const EastWestStreet = preload("res://tests/east_west_street.gd")

const _AT := Vector2(336.0, 336.0)

func run(t: TestRunner) -> void:
	_test_the_crash_lies_across_a_north_south_street(t)
	_test_the_crash_lies_down_an_east_west_street(t)
	_test_a_row_that_spans_the_street_stands_at_its_kerb(t)
	_test_a_shape_with_no_body_has_no_pieces(t)
	_test_the_crash_leaves_the_ground_between_its_cars_open(t)

func _test_the_crash_lies_across_a_north_south_street(t: TestRunner) -> void:
	var map := NorthSouthStreet.new()
	var row := EventCatalogue.by_id("car_accident")
	var stood := BodyStance.stands_at(map, row, _AT)
	var pieces := BodyStance.pieces_at(map, row, stood, Vector2.RIGHT)
	var parts := row.body_pieces()
	t.check(pieces.size() == parts.size() and parts.size() == 2,
			"the crash is two pieces on a north-south street (%d)" % pieces.size())
	for k in mini(pieces.size(), parts.size()):
		t.check(pieces[k].center().is_equal_approx(stood + Vector2(parts[k].along, 0.0)),
				"piece %d stands across the screen by its own offset" % k)
		t.check(pieces[k].ground_shape() == parts[k].ground_shape(),
				"piece %d has its part's own ground shape" % k)
		t.check(pieces[k].axis().is_equal_approx(Vector2.RIGHT),
				"piece %d lies across the screen, the axis a spread lies along there" % k)

func _test_the_crash_lies_down_an_east_west_street(t: TestRunner) -> void:
	var map: WorldMap = EastWestStreet.new()
	var row := EventCatalogue.by_id("car_accident")
	var stood := BodyStance.stands_at(map, row, _AT)
	var pieces := BodyStance.pieces_at(map, row, stood, Vector2.RIGHT)
	var parts := row.body_pieces()
	t.check(pieces.size() == parts.size() and parts.size() == 2,
			"the crash is two pieces on an east-west street (%d)" % pieces.size())
	for k in mini(pieces.size(), parts.size()):
		t.check(pieces[k].center().is_equal_approx(stood + Vector2(0.0, parts[k].along_vertical)),
				"piece %d stands down the screen by its own vertical offset" % k)
		t.check(pieces[k].axis().is_equal_approx(Vector2.DOWN),
				"piece %d lies down the screen" % k)

func _test_a_row_that_spans_the_street_stands_at_its_kerb(t: TestRunner) -> void:
	var row := EventCatalogue.by_id("roadblock")
	var lane := _carriageway_point()
	t.check(lane != Vector2.INF, "there is a carriageway point whose kerb is elsewhere")
	if lane == Vector2.INF:
		return
	var pieces := BodyStance.pieces_at(WorldMap.open_ground(), row, lane, Vector2.RIGHT)
	t.check(pieces.size() == 1, "the roadblock is one piece (%d)" % pieces.size())
	if pieces.is_empty():
		return
	t.check(pieces[0].center().is_equal_approx(CityMap.kerb_beside(lane)),
			"it stands on the kerb beside its lane")
	t.check(not pieces[0].center().is_equal_approx(lane), "and not where it was built")

## A point in a carriageway lane, which the kerb beside it moves, or `Vector2.INF` when there is none.
func _carriageway_point() -> Vector2:
	for tile_x in range(0, 60):
		var at := Vector2((float(tile_x) + 0.5) * Tuning.TILE_SIZE, 336.0)
		if not CityMap.kerb_beside(at).is_equal_approx(at):
			return at
	return Vector2.INF

func _test_a_shape_with_no_body_has_no_pieces(t: TestRunner) -> void:
	var row := EventDef.new()
	row.shape = GroundShape.point(10.0)
	t.check(not row.has_a_body(), "the row has a shape and no body")
	t.check(BodyStance.pieces_at(WorldMap.open_ground(), row, _AT, Vector2.RIGHT).is_empty(),
			"a row with no body answers no pieces")

func _test_the_crash_leaves_the_ground_between_its_cars_open(t: TestRunner) -> void:
	var map := NorthSouthStreet.new()
	var row := EventCatalogue.by_id("car_accident")
	var pieces := BodyStance.pieces_at(map, row, _AT, Vector2.RIGHT)
	var covered: Array[Vector2i] = []
	for piece in pieces:
		for tile in piece.tiles():
			if not covered.has(tile):
				covered.append(tile)
	var stood := BodyStance.stands_at(map, row, _AT)
	var whole := row.ground_shape().tiles_under(stood, pieces[0].axis())
	t.check(not covered.is_empty(), "the cars cover tiles")
	var inside := true
	for tile in covered:
		inside = inside and whole.has(tile)
	t.check(inside, "every tile a car covers is inside the crash's whole band")
	t.check(covered.size() < whole.size(),
			"the ground between the cars stays open (%d of %d tiles)" % [covered.size(), whole.size()])
