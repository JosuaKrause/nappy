extends RefCounted
## **Where something sent at her may start, on ground this suite builds by hand** (`SpawnSiting`):
## each rule by its name against a yard of sidewalk with a building, a walled alley and a region
## body put where a test needs them, the day's view a fake the test looks wherever it likes; the
## chase a start is sited for (`Navigator.reaches()`); and the one search a task's trap and a torn
## poster's pursuer both start from, answering each caller's own bearings by the same rules.

const TILE := float(Tuning.TILE_SIZE)
## Where she stands in every yard: far from the home block, with the whole view and a start just out
## of sight on every side inside the map.
const HER_TILE := Vector2i(40, 20)
## What the thing sent at her draws about its feet: a figure's box, taller than it is wide.
const BOX := Rect2(-10.0, -40.0, 20.0, 44.0)

func run(t) -> void:
	_test_legal_ground(t)
	_test_out_of_sight_and_off_the_view(t)
	_test_clear_of_the_boundary_and_a_clear_run(t)
	_test_a_chase_reaches_her_or_does_not(t)
	_test_one_search_answers_both_callers(t)
	_test_the_boundary_refuses_a_start_even_as_the_fallback(t)
	_test_across_the_street(t)

static func _yard(size := Vector2i(60, 40)) -> CityMap:
	var map := CityMap.new(size)
	map.fill_rect(Rect2i(Vector2i.ZERO, size), GameEnums.TileType.SIDEWALK)
	return map

static func _centre(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE

## A siting over `map` against a view the test holds (`view`, looked by the test) and the region
## `region` (null for none).
static func _siting(map: CityMap, view: VisibleView,
		region: SpawnSiting.Region = null) -> SpawnSiting:
	return SpawnSiting.new(map, Navigator.new(map), func() -> VisibleView: return view,
			func() -> SpawnSiting.Region: return region)

static func _view_about(at: Vector2) -> VisibleView:
	return VisibleView.around(at)

## Legal ground is walkable ground off the home block and outside a walled-off alley.
func _test_legal_ground(t) -> void:
	var map := _yard()
	var her := _centre(HER_TILE)
	var region := SpawnSiting.Region.new()
	var walled := Rect2i(Vector2i(10, 30), Vector2i(2, 4))
	region.walled_alleys = [walled]
	var siting := _siting(map, _view_about(her), region)
	var asked := siting.ask(BOX, Mover.on_foot(EventInstance.FIGURE_RADIUS), her)
	var open := Vector2i(30, 30)
	t.check(siting.allows(SpawnSiting.Rule.LEGAL_GROUND, asked, _centre(open)),
			"open sidewalk is legal ground")
	map.set_tile(Vector2i(31, 30), GameEnums.TileType.BUILDING)
	t.check(not siting.allows(SpawnSiting.Rule.LEGAL_GROUND, asked, _centre(Vector2i(31, 30))),
			"a building is not")
	t.check(not siting.allows(SpawnSiting.Rule.LEGAL_GROUND, asked, _centre(walled.position)),
			"nor is a walled-off alley")
	t.check(SpawnSiting.is_legal_ground(map, walled.position, []),
			"which is legal again on a day that walls nothing")
	var home := Vector2i(-1, -1)
	for y in map.size.y:
		for x in map.size.x:
			if home == Vector2i(-1, -1) and map.is_on_home_block(Vector2i(x, y)):
				home = Vector2i(x, y)
	t.check(home != Vector2i(-1, -1)
			and not siting.allows(SpawnSiting.Rule.LEGAL_GROUND, asked, _centre(home)),
			"nor is the home block's own ground (%s)" % home)

## Out of sight is the whole drawing outside the view and at least the least distance from her; off
## the view is the point itself nowhere on it, and nothing is on a view never looked through.
func _test_out_of_sight_and_off_the_view(t) -> void:
	var map := _yard()
	var her := _centre(HER_TILE)
	var view := _view_about(her)
	var siting := _siting(map, view)
	var asked := siting.ask(BOX, Mover.on_foot(), her)
	var above := SpawnSiting.just_out_of_sight(asked.view, BOX, her, Vector2.UP)
	t.check(siting.allows(SpawnSiting.Rule.OUT_OF_SIGHT, asked, above),
			"just out of sight above her is out of sight (%.1fpx up)" % (her.y - above.y))
	t.check(above.y + BOX.end.y < view.view.position.y + 0.001,
			"and his whole drawing, feet and shadow, is above the view's top edge")
	t.check(not siting.allows(SpawnSiting.Rule.OUT_OF_SIGHT, asked, above + Vector2(0.0, 6.0)),
			"a step down, his shadow shows")
	t.check(not siting.allows(SpawnSiting.Rule.OFF_THE_VIEW, asked, her + Vector2(300.0, 0.0)),
			"a point inside the view is on it")
	t.check(siting.allows(SpawnSiting.Rule.OFF_THE_VIEW, asked, her + Vector2(330.0, 0.0)),
			"a point past its edge is off it")
	view.look(Rect2(her + Vector2(100.0, 0.0) - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2.0), true)
	t.check(not siting.allows(SpawnSiting.Rule.OFF_THE_VIEW, asked, her + Vector2(330.0, 0.0)),
			"the view is asked as it is now: the camera led right puts that point back on it")
	var corner := view.view.end - Vector2(4.0, 4.0)
	t.check(not view.sees(corner)
			and not siting.allows(SpawnSiting.Rule.OFF_THE_VIEW, asked, corner),
			"a point under a covered corner is unseen, but on the view, since it is drawn there")
	var blind := _siting(map, null)
	t.check(blind.allows(SpawnSiting.Rule.OFF_THE_VIEW, blind.ask(BOX, Mover.on_foot(), her), her),
			"with no view, nothing is on it")
	var near := SpawnSiting.least_distance() - 10.0
	var around_her := SpawnSiting.seen_from(null, her)
	t.check(not SpawnSiting.is_out_of_sight(around_her, Rect2(), her, her + Vector2(0.0, -near)),
			"nothing is out of sight nearer her than the least distance")

## A run at her is refused through a region body's disc, and is clear only over ground he may walk.
func _test_clear_of_the_boundary_and_a_clear_run(t) -> void:
	var map := _yard()
	var her := _centre(HER_TILE)
	var region := SpawnSiting.Region.new()
	region.centres.append(her + Vector2(0.0, -100.0))
	region.radii.append(20.0)
	region.centres.append(her + Vector2(2000.0, 0.0))
	region.radii.append(20.0)
	var siting := _siting(map, _view_about(her), region)
	var asked := siting.ask(BOX, Mover.on_foot(EventInstance.FIGURE_RADIUS), her)
	t.check(asked.centres.size() == 1, "only a body that could stand in a run at her is asked")
	var above := her + Vector2(0.0, -220.0)
	var beside := her + Vector2(-340.0, 0.0)
	t.check(not siting.allows(SpawnSiting.Rule.CLEAR_OF_THE_BOUNDARY, asked, above),
			"a run through the body's disc is refused")
	t.check(siting.allows(SpawnSiting.Rule.CLEAR_OF_THE_BOUNDARY, asked, beside),
			"one past it is not")
	t.check(siting.allows(SpawnSiting.Rule.CLEAR_RUN, asked, beside), "open ground is a clear run")
	map.set_tile(HER_TILE + Vector2i(-4, 0), GameEnums.TileType.BUILDING)
	t.check(not siting.allows(SpawnSiting.Rule.CLEAR_RUN, asked, beside),
			"a building on the line is not")

## A chase straight at her that slides along walls reaches her round a wall it meets at a slant,
## not through one it meets square-on, not through a region body, and not past its limit.
func _test_a_chase_reaches_her_or_does_not(t) -> void:
	var map := _yard()
	var her := _centre(HER_TILE)
	var navigator := Navigator.new(map)
	var walker := Mover.on_foot(EventInstance.FIGURE_RADIUS)
	var from := her + Vector2(-120.0, 200.0)
	t.check(navigator.reaches(from, her, walker, 400.0), "across open ground he reaches her")
	t.check(not navigator.reaches(from, her, walker, 100.0), "but not within less ground than that")
	for x in range(HER_TILE.x - 5, HER_TILE.x - 1):
		map.set_tile(Vector2i(x, HER_TILE.y + 3), GameEnums.TileType.BUILDING)
	t.check(not navigator.clear_line(from, her, walker) and navigator.reaches(from, her, walker,
			400.0), "a short wall in his way, met at a slant, he slides along and comes round")
	for x in range(HER_TILE.x - 8, HER_TILE.x + 8):
		map.set_tile(Vector2i(x, HER_TILE.y + 3), GameEnums.TileType.BUILDING)
	t.check(not navigator.reaches(her + Vector2(0.0, 200.0), her, walker, 400.0),
			"a long wall met square-on stops him")
	var open := _yard()
	var disc := her + Vector2(0.0, 100.0)
	var through_the_disc := func(a: Vector2, b: Vector2) -> bool:
		return Geometry2D.get_closest_point_to_segment(disc, a, b).distance_to(disc) <= 20.0
	t.check(not Navigator.new(open).reaches(her + Vector2(0.0, 200.0), her, walker, 400.0,
			through_the_disc), "a step the caller refuses ends the chase")

## The one search: a task's trap tries straight up and down in the order its stream drew and then
## its drawn cone, a torn poster's pursuer up or down by a hash and then a stepped cone, and both
## are answered by the same rules — the first start with a clear run, the first legal one standing
## in.
func _test_one_search_answers_both_callers(t) -> void:
	var map := _yard()
	var her := _centre(HER_TILE)
	var siting := _siting(map, _view_about(her))
	var asked := siting.ask(BOX, Mover.on_foot(EventInstance.FIGURE_RADIUS), her)
	# A building band across the way up: the start above stands on open ground, but has no run.
	for x in range(HER_TILE.x - 3, HER_TILE.x + 4):
		map.set_tile(Vector2i(x, HER_TILE.y - 3), GameEnums.TileType.BUILDING)
	var drawn: Array[Vector2] = [Vector2.RIGHT.rotated(-PI / 2.0), Vector2.RIGHT.rotated(PI / 2.0)]
	var hashed: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.UP.rotated(PI / 6.0),
			Vector2.RIGHT, Vector2.LEFT]
	var trap := siting.start_out_of_sight(asked, drawn)
	var poster := siting.start_out_of_sight(asked, hashed)
	t.check(trap.clear and trap.at.y > her.y and not trap.beside,
			"the trap's search passes over the start above with no run and takes the one below")
	t.check(poster.clear and poster.at.is_equal_approx(trap.at),
			"the poster's search, asking up first too, lands on the same start below")
	for x in range(HER_TILE.x - 3, HER_TILE.x + 4):
		map.set_tile(Vector2i(x, HER_TILE.y + 3), GameEnums.TileType.BUILDING)
	var sideways := siting.start_out_of_sight(asked, hashed)
	t.check(sideways.clear and sideways.beside and is_equal_approx(sideways.at.y, her.y),
			"walled above and below, he comes along her street beside her")
	var only_up: Array[Vector2] = [Vector2.UP, Vector2.DOWN]
	var stood_in := siting.start_out_of_sight(asked, only_up)
	t.check(not stood_in.clear and stood_in.at.is_equal_approx(
			SpawnSiting.just_out_of_sight(asked.view, BOX, her, Vector2.UP)),
			"with no clear run on any bearing asked, the first legal start stands in")
	map.fill_rect(Rect2i(Vector2i.ZERO, map.size), GameEnums.TileType.BUILDING)
	map.set_tile(HER_TILE, GameEnums.TileType.SIDEWALK)
	t.check(siting.start_out_of_sight(asked, hashed).at == Vector2.INF,
			"with no legal start at all, nothing is sent")

## A start whose run at her goes through the boundary is refused outright, so it never stands in
## either: a torn poster's pursuer takes the trap's rule here.
func _test_the_boundary_refuses_a_start_even_as_the_fallback(t) -> void:
	var map := _yard()
	var her := _centre(HER_TILE)
	var region := SpawnSiting.Region.new()
	region.centres.append(her + Vector2(0.0, -100.0))
	region.radii.append(20.0)
	var siting := _siting(map, _view_about(her), region)
	var asked := siting.ask(BOX, Mover.on_foot(EventInstance.FIGURE_RADIUS), her)
	for x in range(HER_TILE.x - 3, HER_TILE.x + 4):
		map.set_tile(Vector2i(x, HER_TILE.y + 3), GameEnums.TileType.BUILDING)
	var bearings: Array[Vector2] = [Vector2.UP, Vector2.DOWN]
	var start := siting.start_out_of_sight(asked, bearings)
	t.check(not start.clear and start.at.y > her.y,
			"through the door above he is never sent; the start below, with no run, stands in")

## Across the street at a front door: the nearest start below her, out of sight, whose own chase
## reaches her; nothing where the ground below is all building.
func _test_across_the_street(t) -> void:
	var map := _yard()
	var her := _centre(HER_TILE)
	var siting := _siting(map, _view_about(her))
	var asked := siting.ask(BOX, Mover.on_foot(EventInstance.FIGURE_RADIUS), her)
	var across := siting.across_the_street(asked)
	t.check(across != Vector2.INF and across.y > her.y
			and siting.allows(SpawnSiting.Rule.OUT_OF_SIGHT, asked, across)
			and siting.allows(SpawnSiting.Rule.REACHES_HER, asked, across),
			"on open ground the nearest tile below her and out of sight is his start (%s)" % across)
	t.check(is_equal_approx(across.x, her.x), "straight below her, the tie broken toward her")
	var below := Rect2i(0, HER_TILE.y + 1, map.size.x, map.size.y - HER_TILE.y - 1)
	map.fill_rect(below, GameEnums.TileType.BUILDING)
	t.check(siting.across_the_street(asked) == Vector2.INF,
			"with nothing but building below her, there is no start across the street")
