extends RefCounted
## `BodyStance`: how a body built at a point stands on its street (`of()`, `of_plan()`): where its center
## stands, which way it lies, the side a vehicle standing still shows, and each of its pieces
## (`pieces()`), which every reader of a body's layout (the walk's ground, the map's record, the route
## rig, a live body and its look) takes from it.
##
## Rows are the catalogue's own, built as they are (data), except check 4's, a bare row with a shape and no body. The map is a stand-in per street axis
## (`tests/east_west_street.gd` and the north-south twin below), so no city is generated and the
## street a body lies along is the one the test says. The expected values are read off the rows'
## declared parts, so a redrawn crash picture does not break the suite.

## A map that answers every tile as on a north-south street and on no east-west one: a spread or a
## wide scene runs across the screen, as the twin of `EastWestStreet`.
class NorthSouthStreet extends WorldMap:
	## Overrides WorldMap.corridor_offsets.
	func corridor_offsets(_tile: Vector2i) -> Vector2i:
		return Vector2i(0, -1)

## A map of streets six tiles wide with a two-tile sidewalk each side, east-west when `across` is
## false and north-south when it is true, the corridor and pavement answers a city's streets give
## (`CityMap.corridor_offsets()`, `CityMap.pavement_inward()`) with no city generated.
class SidewalkStreets extends WorldMap:
	var _north_south := false

	func _init(north_south: bool) -> void:
		_north_south = north_south

	## Overrides WorldMap.corridor_offsets.
	func corridor_offsets(tile: Vector2i) -> Vector2i:
		if _north_south:
			return Vector2i(posmod(tile.x, Tuning.STREET_WIDTH), -1)
		return Vector2i(-1, posmod(tile.y, Tuning.STREET_WIDTH))

	## Overrides WorldMap.pavement_inward.
	func pavement_inward(tile: Vector2i) -> Vector2i:
		var offsets := corridor_offsets(tile)
		var offset := maxi(offsets.x, offsets.y)
		var step := Vector2i.RIGHT if _north_south else Vector2i.DOWN
		if offset < Tuning.SIDEWALK_WIDTH:
			return -step
		if offset >= Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH:
			return step
		return Vector2i.ZERO

const EastWestStreet = preload("res://tests/east_west_street.gd")

const _AT := Vector2(336.0, 336.0)

func run(t: TestRunner) -> void:
	_test_the_crash_lies_across_a_north_south_street(t)
	_test_the_crash_lies_down_an_east_west_street(t)
	_test_a_row_that_spans_the_street_stands_at_its_kerb(t)
	_test_a_shape_with_no_body_has_no_pieces(t)
	_test_the_crash_leaves_the_ground_between_its_cars_open(t)
	_test_a_stood_point_is_stood_where_it_is(t)
	_test_a_stood_body_lays_its_pieces_out_where_its_build_point_does(t)
	_test_a_planned_body_stands_where_its_plan_was_placed(t)
	_test_a_stance_lays_its_pieces_out_round_any_point(t)
	_test_only_a_car_that_drives_lies_along_its_heading(t)

func _test_the_crash_lies_across_a_north_south_street(t: TestRunner) -> void:
	var map := NorthSouthStreet.new()
	var row := EventCatalogue.by_id("car_accident")
	var stood := BodyStance.of(map, row, _AT, Vector2.RIGHT).center()
	var pieces := BodyStance.of(map, row, _AT, Vector2.RIGHT).pieces()
	var parts: Array[BodyPiece] = row.body().pieces()
	t.check(pieces.size() == parts.size() and parts.size() == 2,
			"the crash is two pieces on a north-south street (%d)" % pieces.size())
	for k in mini(pieces.size(), parts.size()):
		t.check(pieces[k].center().is_equal_approx(stood + Vector2(parts[k].offset_for(false), 0.0)),
				"piece %d stands across the screen by its own offset" % k)
		t.check(pieces[k].ground_shape() == parts[k].ground_shape(),
				"piece %d has its part's own ground shape" % k)
		t.check(pieces[k].axis().is_equal_approx(Vector2.RIGHT),
				"piece %d lies across the screen, the axis a spread lies along there" % k)

func _test_the_crash_lies_down_an_east_west_street(t: TestRunner) -> void:
	var map: WorldMap = EastWestStreet.new()
	var row := EventCatalogue.by_id("car_accident")
	var stood := BodyStance.of(map, row, _AT, Vector2.RIGHT).center()
	var pieces := BodyStance.of(map, row, _AT, Vector2.RIGHT).pieces()
	var parts: Array[BodyPiece] = row.body().pieces()
	t.check(pieces.size() == parts.size() and parts.size() == 2,
			"the crash is two pieces on an east-west street (%d)" % pieces.size())
	for k in mini(pieces.size(), parts.size()):
		t.check(pieces[k].center().is_equal_approx(stood + Vector2(0.0, parts[k].offset_for(true))),
				"piece %d stands down the screen by its own vertical offset" % k)
		t.check(pieces[k].axis().is_equal_approx(Vector2.DOWN),
				"piece %d lies down the screen" % k)

func _test_a_row_that_spans_the_street_stands_at_its_kerb(t: TestRunner) -> void:
	var row := EventCatalogue.by_id("roadblock")
	var lane := _carriageway_point()
	t.check(lane != Vector2.INF, "there is a carriageway point whose kerb is elsewhere")
	if lane == Vector2.INF:
		return
	var pieces := BodyStance.of(WorldMap.open_ground(), row, lane, Vector2.RIGHT).pieces()
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
	var draft := EventDraft.new("")
	draft.body(BodySpec.footprint(GroundShape.point(10.0)))
	var row := draft.build()
	t.check(not row.has_a_body(), "the row has a shape and no body")
	t.check(BodyStance.of(WorldMap.open_ground(), row, _AT, Vector2.RIGHT).pieces().is_empty(),
			"a row with no body answers no pieces")

func _test_the_crash_leaves_the_ground_between_its_cars_open(t: TestRunner) -> void:
	var map := NorthSouthStreet.new()
	var row := EventCatalogue.by_id("car_accident")
	var pieces := BodyStance.of(map, row, _AT, Vector2.RIGHT).pieces()
	var covered: Array[Vector2i] = []
	for piece in pieces:
		for tile in piece.tiles():
			if not covered.has(tile):
				covered.append(tile)
	var stood := BodyStance.of(map, row, _AT, Vector2.RIGHT).center()
	var whole := row.ground_shape().tiles_under(stood, pieces[0].axis())
	t.check(not covered.is_empty(), "the cars cover tiles")
	var inside := true
	for tile in covered:
		inside = inside and whole.has(tile)
	t.check(inside, "every tile a car covers is inside the crash's whole band")
	t.check(covered.size() < whole.size(),
			"the ground between the cars stays open (%d of %d tiles)" % [covered.size(), whole.size()])

## The rows `EventDef.stands_on_its_band_middle()` holds for, whichever the catalogue has.
func _rows_on_the_band_middle() -> Array[EventDef]:
	var rows: Array[EventDef] = []
	for row in EventCatalogue.all():
		if row.stands_on_its_band_middle():
			rows.append(row)
	return rows

## **Standing a stood point gives the same point**, for each row that stands on its band's middle, on
## both street axes, each of the street's six lanes and a point at the lane's middle and two off it:
## the middle lies on the line between the band's two lanes, and a second standing read the lane
## past that line and moved the point half a tile toward the other lane. A point not yet stood still
## moves to the middle.
func _test_a_stood_point_is_stood_where_it_is(t: TestRunner) -> void:
	var rows := _rows_on_the_band_middle()
	t.check(not rows.is_empty(), "there were rows to ask (%d)" % rows.size())
	var asked := 0
	var moved := 0
	var unstood := 0
	for north_south: bool in [false, true]:
		var map := SidewalkStreets.new(north_south)
		var across := Vector2.RIGHT if north_south else Vector2.DOWN
		for lane in Tuning.STREET_WIDTH:
			var tile := Vector2i(lane + 12, 20) if north_south else Vector2i(20, lane + 12)
			for from_the_middle: float in [0.0, 5.0, -9.0]:
				var built := map.tile_to_world(tile) + across * from_the_middle
				for row in rows:
					var once := BodyStance.of(map, row, built, Vector2.RIGHT).center()
					var twice := BodyStance.of(map, row, once, Vector2.RIGHT).center()
					asked += 1
					if not twice.is_equal_approx(once):
						moved += 1
					if from_the_middle == 0.0 and map.pavement_inward(tile) != Vector2i.ZERO \
							and once.is_equal_approx(built):
						unstood += 1
	# The one row that stands at its kerb is stood where it is as well.
	var lane := _carriageway_point()
	var roadblock := EventCatalogue.by_id("roadblock")
	var kerb := BodyStance.of(WorldMap.open_ground(), roadblock, lane, Vector2.RIGHT).center()
	t.check(lane != Vector2.INF and kerb != lane
			and BodyStance.of(WorldMap.open_ground(), roadblock, kerb, Vector2.RIGHT).center() \
					.is_equal_approx(kerb),
			"the roadblock stood at its kerb is stood where it is")
	t.check(asked == 2 * Tuning.STREET_WIDTH * 3 * rows.size() and moved == 0,
			"a stood point is stood where it is: %d of %d moved" % [moved, asked])
	# The four sidewalk lanes of a street each move to their band's middle, half a tile from where
	# they were built: the guard that the sweep above is not asking points that never move.
	t.check(unstood == 0, "a sidewalk point built at a lane's middle is moved (%d stayed)" % unstood)

## **A stance made from a point already stood lays its pieces out where its build point's does**:
## a stance is made from a build point and never from a stance, and where a caller holds only the
## point a live body stands at (a rig's, a test's) it still gets the body built at `at`.
func _test_a_stood_body_lays_its_pieces_out_where_its_build_point_does(t: TestRunner) -> void:
	var asked := 0
	var differ := 0
	for north_south: bool in [false, true]:
		var map := SidewalkStreets.new(north_south)
		for lane in Tuning.STREET_WIDTH:
			var tile := Vector2i(lane + 12, 20) if north_south else Vector2i(20, lane + 12)
			var built := map.tile_to_world(tile)
			for row in _rows_on_the_band_middle():
				var from_build := BodyStance.of(map, row, built, Vector2.RIGHT).pieces()
				var stood := BodyStance.of(map, row, built, Vector2.RIGHT).center()
				var from_stood := BodyStance.of(map, row, stood, Vector2.RIGHT).pieces()
				asked += 1
				var same := from_build.size() == from_stood.size()
				for k in mini(from_build.size(), from_stood.size()):
					same = same and from_build[k].center().is_equal_approx(from_stood[k].center())
				if not same:
					differ += 1
	t.check(asked > 0 and differ == 0,
			"a stood body's pieces are its build point's: %d of %d differ" % [differ, asked])

func _test_a_planned_body_stands_where_its_plan_was_placed(t: TestRunner) -> void:
	var map := SidewalkStreets.new(false)
	var at := map.tile_to_world(Vector2i(20, 12))
	for id: String in ["market_stall", "roadblock", "car_accident"]:
		var row := EventCatalogue.by_id(id)
		var plan := EventPlan.new(row, at)
		var from_plan := BodyStance.of_plan(map, plan)
		var from_row := BodyStance.of(map, row, at, plan.faces())
		t.check(from_plan.center() == from_row.center(),
				"%s's planned body stands where its row stands a body built at the plan's point" % id)
		t.check(from_plan.lies_vertically() == from_row.lies_vertically()
				and from_plan.stands_side_on() == from_row.stands_side_on(),
				"%s's planned body lies as a body built at the plan's point and facing does" % id)

## **A stance lays the one body out wherever it is asked**: round its own center (`pieces()`), round
## the origin (what a live body's collision body and shadow are made from) and round a point a live
## body has moved to are the same pieces, shifted, along the same spine, on both street axes.
func _test_a_stance_lays_its_pieces_out_round_any_point(t: TestRunner) -> void:
	var elsewhere := Vector2(120.0, -40.0)
	var asked := 0
	var differ := 0
	for map: WorldMap in [NorthSouthStreet.new(), EastWestStreet.new()]:
		for id: String in ["car_accident", "market_stall", "moving_van"]:
			var stance := BodyStance.of(map, EventCatalogue.by_id(id), _AT, Vector2.RIGHT)
			var own := stance.pieces()
			var round_the_origin := stance.pieces_at(Vector2.ZERO, Vector2.RIGHT)
			var moved := stance.pieces_at(elsewhere, Vector2.RIGHT)
			t.check(round_the_origin.size() == own.size() and moved.size() == own.size(),
					"%s lays the same pieces out round any point (%d, %d, %d)"
					% [id, own.size(), round_the_origin.size(), moved.size()])
			for k in mini(own.size(), mini(round_the_origin.size(), moved.size())):
				asked += 1
				var same := own[k].center().is_equal_approx(stance.center() + round_the_origin[k].center())
				same = same and moved[k].center().is_equal_approx(elsewhere + round_the_origin[k].center())
				same = same and own[k].axis() == round_the_origin[k].axis() \
						and own[k].axis() == moved[k].axis()
				if not same:
					differ += 1
			t.check(stance.round_the_origin().size() == own.size()
					and is_same(stance.round_the_origin(), stance.round_the_origin()),
					"%s keeps its pieces round the origin once they are made" % id)
	t.check(asked > 0 and differ == 0, "pieces round any point are shifted copies: %d of %d differ"
			% [differ, asked])

## **Only a car that drives lies along the heading it is asked with**; every other row lies along its
## street whatever it heads, which is why a live body that does not drive never lays its pieces out
## again.
func _test_only_a_car_that_drives_lies_along_its_heading(t: TestRunner) -> void:
	var map := NorthSouthStreet.new()
	var drivers := 0
	var stood_still := 0
	for row in EventCatalogue.all():
		if row.body() == null or row.ground_shape() == null:
			continue
		var stance := BodyStance.of(map, row, _AT, Vector2.RIGHT)
		var along_up := stance.spine_along(Vector2.UP)
		var along_down := stance.spine_along(Vector2.DOWN)
		if row.drives():
			drivers += 1
			t.check(along_up.is_equal_approx(Vector2.UP) and along_down.is_equal_approx(Vector2.DOWN),
					"%s, a car that drives, lies along the heading it is asked with" % row.id())
			t.check(stance.spine_along(Vector2.ZERO).is_equal_approx(Vector2.RIGHT),
					"%s with no heading lies along the right" % row.id())
		else:
			stood_still += 1
			t.check(along_up == along_down, "%s lies along its street whatever it heads" % row.id())
	t.check(drivers > 0 and stood_still > 0,
			"there were cars that drive and rows that do not (%d, %d)" % [drivers, stood_still])
