extends RefCounted
## Protester pointing (M65): which of the eight `protester_point_*` poses a protest rank draws,
## and when it stays the plain `protester.svg` instead. See `docs/EVENTS.md`, the `protest` row,
## and `EventPictures.protester_texture()`.
##
## A live protest is stood on open ground and drawn through a recording drawer, handed what its
## manager hands every event it makes (`EventSurroundings.pointing_protests_with()`); the director
## whose objective that is has its own cases in `tests/test_resistance_steps.gd`.

const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")

func run(t: TestRunner) -> void:
	var standing: Array[Node] = t.get_children()
	_test_bearing_sectors_pick_the_matching_pose(t)
	_test_a_bearing_off_centre_still_rounds_to_its_sector(t)
	_test_plain_pose_with_no_objective(t)
	await _test_a_protest_points_where_it_was_told_to(t)
	await _test_a_protest_with_nothing_to_point_at_stands_plain(t)
	for child in t.get_children():
		if not child in standing:
			child.free()

# ---------------------------------------------------------------- bearing ---

## The exact inverse of `protester_texture()`'s own `atan2(toward.x, -toward.y)`, so feeding a
## bearing in and reading it back out is round-trip rather than a second formula to disagree with
## the first.
func _at_bearing(degrees: float, distance: float) -> Vector2:
	var radians := deg_to_rad(degrees)
	return Vector2(sin(radians), -cos(radians)) * distance

## One sample squarely inside each of the eight 45° sectors, so a swapped table entry shows up as
## a specific wrong pose rather than a single "not plain" check any of the eight would pass.
func _test_bearing_sectors_pick_the_matching_pose(t: TestRunner) -> void:
	var from := Vector2(100.0, 100.0)
	var sectors := [
		[0.0, EventPictures.PROTESTER_POINT_N, "north"],
		[45.0, EventPictures.PROTESTER_POINT_NE, "north-east"],
		[90.0, EventPictures.PROTESTER_POINT_E, "east"],
		[135.0, EventPictures.PROTESTER_POINT_SE, "south-east"],
		[180.0, EventPictures.PROTESTER_POINT_S, "south"],
		[225.0, EventPictures.PROTESTER_POINT_SW, "south-west"],
		[270.0, EventPictures.PROTESTER_POINT_W, "west"],
		[315.0, EventPictures.PROTESTER_POINT_NW, "north-west"],
	]
	for sector: Array in sectors:
		var objective: Vector2 = from + _at_bearing(sector[0], 200.0)
		t.check(EventPictures.protester_texture(from, objective) == sector[1],
				"bearing %.0f° points %s" % [sector[0], sector[2]])

## A bearing 20° either side of a sector's own centre is still well inside its 45°-wide band —
## the pose is picked by nearest, not by an exact match.
func _test_a_bearing_off_centre_still_rounds_to_its_sector(t: TestRunner) -> void:
	var from := Vector2.ZERO
	for offset: float in [-20.0, 20.0]:
		var objective := from + _at_bearing(90.0 + offset, 150.0)
		t.check(EventPictures.protester_texture(from, objective) == EventPictures.PROTESTER_POINT_E,
				"%.0f° off east still rounds to the east pose" % offset)

# ---------------------------------------------------------------- no objective ---

func _test_plain_pose_with_no_objective(t: TestRunner) -> void:
	t.check(EventPictures.protester_texture(Vector2.ZERO, Vector2.INF) == EventPictures.PROTESTER,
			"no objective at all draws the plain rank")
	t.check(EventPictures.protester_texture(Vector2(5.0, 5.0), Vector2(5.0, 5.0))
			== EventPictures.PROTESTER,
			"an objective on top of the protester draws the plain rank rather than dividing by zero")
# ---------------------------------------------------------------- the wiring ---

## A protest on open ground, in the tree and drawn through `recorded`, pointing its placards where
## `where` says when one is given, as its manager's surroundings are handed
## (`EventSurroundings.pointing_protests_with()`) and nothing otherwise.
func _protest(t: TestRunner, at: Vector2, recorded: RecordingEventDrawer,
		where := Callable()) -> EventInstance:
	var surroundings := EventSurroundings.new().drawing_through(recorded)
	if where.is_valid():
		surroundings.pointing_protests_with(where)
	var protest := EventInstance.new()
	protest.setup(EventCatalogue.by_id("protest"), at, PackedVector2Array(), Vector2.RIGHT,
			surroundings)
	t.add_child(protest)
	return protest

## The pictures the protest stood its rank in, drawn: real frames pass so its slices are put in
## beside it and drawn, one protester each. The drawer is this protest's alone, so every picture it
## recorded is one of the rank.
func _rank_drawn(t: TestRunner, recorded: RecordingEventDrawer) -> Array[String]:
	for i in 3:
		await t.get_tree().process_frame
	var pictures: Array[String] = []
	for entry in recorded.shown():
		if entry.kind == &"stand":
			pictures.append(entry.picture)
	return pictures

## A protest asks what it was handed where its placards point, and its rank is drawn in the pose
## that points there.
func _test_a_protest_points_where_it_was_told_to(t: TestRunner) -> void:
	var objective := Vector2(300.0, 100.0)
	var recorded := RecordingEventDrawer.new()
	var protest := _protest(t, objective + Vector2(0.0, 300.0), recorded,
			func() -> Vector2: return objective)
	t.check(protest.where_its_placards_point() == objective,
			"a protest asks the surroundings it was handed where its placards point")
	var expected := EventPictures.protester_texture(protest.global_position, objective)
	var rank: Array[String] = await _rank_drawn(t, recorded)
	t.check(not rank.is_empty(),
			"and draws through the drawer it was handed")
	var pointing := rank.size() > 1 and expected != EventPictures.PROTESTER
	for picture in rank:
		pointing = pointing and picture == expected
	t.check(pointing, "and its rank of %d points at the objective (%s, drew %s)"
			% [rank.size(), expected.get_file(), rank])
	protest.free()

## With nothing handed in (the escape building, a bare rig) a protest has nothing to point at and
## stands its rank plain.
func _test_a_protest_with_nothing_to_point_at_stands_plain(t: TestRunner) -> void:
	var recorded := RecordingEventDrawer.new()
	var protest := _protest(t, Vector2(300.0, 300.0), recorded)
	t.check(protest.where_its_placards_point() == Vector2.INF,
			"a protest handed nothing to point at has nothing to point at")
	var rank: Array[String] = await _rank_drawn(t, recorded)
	var plain := rank.size() > 1
	for picture in rank:
		plain = plain and not EventPictures.POINTING_POSES.has(picture)
	t.check(plain, "and stands its rank of %d plain rather than pointing (%s)" % [rank.size(), rank])
	protest.free()
