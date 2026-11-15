extends RefCounted
## `DayReach`, where she can get to from home: what shuts the way and what does not, what a unit
## draws later shutting more, and a shortest way from home, checked here once on a street laid out by hand — a sidewalk two tiles wide and forty
## long, home at its west end — with rows built by hand. Everything that asks whether a place can be
## reached (the resistance's placements, the park cordon's last gap) is handed the object.

## The sidewalk's tile column a body stands across, and one beyond it.
const ACROSS := 20
const BEYOND := Vector2i(30, 5)

func run(t: TestRunner) -> void:
	_test_a_body_across_the_street_shuts_the_way(t)
	_test_a_door_body_shuts_nothing(t)
	_test_a_plan_not_placed_shuts_nothing(t)
	_test_a_soft_seal_band_and_a_closure_are_shut(t)
	_test_her_paths_stop_at_the_circle_and_at_what_is_shut(t)
	_test_a_body_drawn_later_shuts_the_way_once_told(t)
	_test_the_way_from_home_walks_the_open_ground(t)
	_test_the_way_from_home_goes_round_by_the_shortest(t)
	_test_a_tile_found_by_a_longer_walk_is_walked_to_by_the_shorter(t)

func _street() -> CityMap:
	var map := CityMap.new(Vector2i(40, 12))
	map.fill_rect(Rect2i(0, 0, 40, 12), GameEnums.TileType.BUILDING)
	map.fill_rect(Rect2i(0, 5, 40, 2), GameEnums.TileType.SIDEWALK)
	map.home_rect = Rect2i(0, 5, 1, 1)
	return map

## `id` standing across the sidewalk at tile column `x`.
func _across(map: CityMap, x: int, id := "barricade") -> EventPlan:
	return EventPlan.new(EventCatalogue.by_id(id),
			map.tile_to_world(Vector2i(x, 5)) + Vector2(0, Tuning.TILE_SIZE * 0.5))

func _test_a_body_across_the_street_shuts_the_way(t: TestRunner) -> void:
	var map := _street()
	var open := DayReach.of(map, [] as Array[EventPlan])
	t.check(open.reaches(BEYOND), "with nothing standing, the far end of the street is reached")
	var reach := DayReach.of(map, [_across(map, ACROSS)] as Array[EventPlan])
	t.check(not reach.reaches(BEYOND), "a barricade across the street cuts off the ground beyond it")
	t.check(reach.is_shut(Vector2i(ACROSS, 5)) and reach.shut().has(Vector2i(ACROSS, 5)),
			"and the ground under it is shut")
	t.check(reach.reaches(Vector2i(10, 5)), "while the ground on home's side of it is still reached")

func _test_a_door_body_shuts_nothing(t: TestRunner) -> void:
	var map := _street()
	var hut := _across(map, ACROSS, "checkpoint_hut")
	t.check(not DayReach.of(map, [hut] as Array[EventPlan]).reaches(BEYOND),
			"a hut that is not a door's body stands in the way like any other body")
	hut.stand_as_a_door()
	t.check(DayReach.of(map, [hut] as Array[EventPlan]).reaches(BEYOND),
			"and the same hut stood at a region door shuts nothing: a door is a crossing")

func _test_a_plan_not_placed_shuts_nothing(t: TestRunner) -> void:
	var map := _street()
	var unplaced := EventPlan.new(EventCatalogue.by_id("barricade"), Vector2.INF)
	t.check(DayReach.of(map, [unplaced] as Array[EventPlan]).reaches(BEYOND),
			"a row the day budgeted but has not sited stands nowhere")

func _test_a_soft_seal_band_and_a_closure_are_shut(t: TestRunner) -> void:
	var map := _street()
	var band := {}
	for y in range(5, 7):
		band[Vector2i(ACROSS, y)] = true
	map.soft_sealed_tiles = band
	t.check(not DayReach.of(map, [] as Array[EventPlan]).reaches(BEYOND),
			"a soft seal's band across the sidewalk shuts it: the red arrow cannot walk it")
	map.soft_sealed_tiles = {}
	map.closed_tiles = band.duplicate()
	t.check(not DayReach.of(map, [] as Array[EventPlan]).reaches(BEYOND),
			"and so does today's closure")

## **Close by is a walk inside a circle** (`DayReach.paths_over()`, the measure day 13's dawn and its
## task both take): from a seed, tile by tile along the sidewalk, every tile reached is nearer the
## centre than the radius, the walk stops at shut ground even where the circle goes on, and a seed
## standing on shut ground still walks out of it, as she may stand inside a body's disc.
func _test_her_paths_stop_at_the_circle_and_at_what_is_shut(t: TestRunner) -> void:
	var map := _street()
	var from := Vector2i(5, 5)
	var centre := map.tile_to_world(from)
	var radius := Tuning.TILE_SIZE * 9.5
	var open := DayReach.paths_over(map, {}, [from] as Array[Vector2i], centre, radius)
	t.check(open.has(Vector2i(14, 5)) and not open.has(Vector2i(15, 5)),
			"along an open sidewalk the walk reaches nine tiles east and stops at the circle")
	t.check(is_equal_approx(float(open[Vector2i(14, 6)]),
			map.tile_to_world(Vector2i(14, 6)).distance_to(centre)),
			"and each tile it reaches carries its distance from the centre")
	var shut := {Vector2i(8, 5): true, Vector2i(8, 6): true}
	var cut := DayReach.paths_over(map, shut, [from] as Array[Vector2i], centre, radius)
	t.check(cut.has(Vector2i(7, 5)) and not cut.has(Vector2i(8, 5)) and not cut.has(Vector2i(9, 5)),
			"ground shut across the sidewalk ends the walk there, though the circle goes on")
	var inside := DayReach.paths_over(map, shut, [Vector2i(8, 5)] as Array[Vector2i],
			map.tile_to_world(Vector2i(8, 5)), radius)
	t.check(inside.has(Vector2i(7, 5)) and inside.has(Vector2i(9, 5))
			and not inside.has(Vector2i(8, 6)),
			"a seed on shut ground walks out of it onto the open ground either side, never onto more of it")

## **What a unit draws as she walks shuts the way once the reach is told** (`shut_more()`): the
## next question floods again, over the ground the new body stands on, and a row that obstructs
## nothing changes nothing.
func _test_a_body_drawn_later_shuts_the_way_once_told(t: TestRunner) -> void:
	var map := _street()
	var reach := DayReach.of(map, [] as Array[EventPlan])
	t.check(reach.reaches(BEYOND), "with nothing standing, the far end of the street is reached")
	reach.shut_more([EventPlan.new(EventCatalogue.by_id("barricade"), Vector2.INF)]
			as Array[EventPlan])
	t.check(reach.reaches(BEYOND), "a drawn row with no place shuts nothing")
	reach.shut_more([_across(map, ACROSS)] as Array[EventPlan])
	t.check(not reach.reaches(BEYOND) and reach.is_shut(Vector2i(ACROSS, 5)),
			"told of a barricade drawn across the street, the ground beyond it is cut off")
	t.check(reach.reaches(Vector2i(10, 5)), "and home's side of it is still reached")

## **A shortest way from home** (`way_from_home()`): home first and the tile last, a tile a step,
## over open ground only, as short as the street allows; none where a body cuts the tile off.
func _test_the_way_from_home_walks_the_open_ground(t: TestRunner) -> void:
	var map := _street()
	var way := DayReach.of(map, [] as Array[EventPlan]).way_from_home(BEYOND)
	var steps_ok := not way.is_empty()
	for k in range(1, way.size()):
		var step := way[k] - way[k - 1]
		steps_ok = steps_ok and absi(step.x) + absi(step.y) == 1 and map.is_walkable(way[k])
	t.check(steps_ok and way[0] == map.home_tile() and way[-1] == BEYOND,
			"a way from home to the far end walks the sidewalk a tile a step, home to the tile")
	var shortest := absi(BEYOND.x - map.home_tile().x) + absi(BEYOND.y - map.home_tile().y) + 1
	t.check(way.size() == shortest, "and is as short as the street allows (%d tiles of %d)"
			% [way.size(), shortest])
	var cut := DayReach.of(map, [_across(map, ACROSS)] as Array[EventPlan])
	t.check(cut.way_from_home(BEYOND).is_empty(), "a barricade across the street leaves no way")
	t.check(not cut.way_from_home(Vector2i(10, 5)).is_empty(), "while home's side still has one")

## **And the shortest round what is shut**: with the street cut and a second sidewalk four tiles
## south of it, joined to it either side of the cut, the way walks away from the tile to go round,
## and takes no more steps than going round asks: thirty east, and five south and five north again.
func _test_the_way_from_home_goes_round_by_the_shortest(t: TestRunner) -> void:
	var map := _street()
	map.fill_rect(Rect2i(8, 10, 24, 2), GameEnums.TileType.SIDEWALK)
	map.fill_rect(Rect2i(8, 7, 2, 3), GameEnums.TileType.SIDEWALK)
	map.fill_rect(Rect2i(26, 7, 2, 3), GameEnums.TileType.SIDEWALK)
	var reach := DayReach.of(map, [_across(map, ACROSS)] as Array[EventPlan])
	var way := reach.way_from_home(BEYOND)
	var steps_ok := not way.is_empty()
	var south := 0
	for k in range(1, way.size()):
		var step := way[k] - way[k - 1]
		steps_ok = steps_ok and absi(step.x) + absi(step.y) == 1 and map.is_walkable(way[k]) \
				and not reach.is_shut(way[k])
		south = maxi(south, way[k].y)
	t.check(steps_ok and south == 10 and way[0] == map.home_tile() and way[-1] == BEYOND,
			"with the street cut, a way from home goes round by the sidewalk south of it")
	t.check(way.size() == 30 + 5 + 5 + 1,
			"and is as short as going round allows (%d tiles of %d)" % [way.size(), 41])

## **A tile the search finds twice is walked to by the shorter walk.** A sidewalk five tiles by
## three, home at its north-west corner and the tile at its south-east, two tiles of it built on
## (marked `#`), so the one shortest way runs along the middle row:
##
##     H . . # .
##     . . n . .
##     . . a # T
##
## The search runs south and then east to `a`, which is shut in, and finds `n` from there, a step
## back north, five steps from home; `n` is three steps from home along the middle row, and the
## way through it is the six steps the corner-to-corner walk asks.
func _test_a_tile_found_by_a_longer_walk_is_walked_to_by_the_shorter(t: TestRunner) -> void:
	var map := CityMap.new(Vector2i(6, 6))
	map.fill_rect(Rect2i(0, 0, 6, 6), GameEnums.TileType.BUILDING)
	map.fill_rect(Rect2i(0, 1, 5, 3), GameEnums.TileType.SIDEWALK)
	map.fill_rect(Rect2i(3, 1, 1, 1), GameEnums.TileType.BUILDING)
	map.fill_rect(Rect2i(3, 3, 1, 1), GameEnums.TileType.BUILDING)
	map.home_rect = Rect2i(0, 1, 1, 1)
	var way := DayReach.of(map, [] as Array[EventPlan]).way_from_home(Vector2i(4, 3))
	t.check(way.size() == 4 + 2 + 1 and way.has(Vector2i(2, 2)),
			"a tile first found by a walk of five steps is walked to by the walk of three, and the "
			+ "way through it is the shortest (%d tiles of 7)" % way.size())
