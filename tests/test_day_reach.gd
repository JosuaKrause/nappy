extends RefCounted
## `DayReach`, where she can get to from home as the walk was planned: what shuts the way and what
## does not, checked here once on a street laid out by hand — a sidewalk two tiles wide and forty
## long, home at its west end — with rows built by hand. Everything that asks whether a place can be
## reached (the resistance's placements, the park cordon's last gap) is handed the object.

## The sidewalk's tile column a body stands across, and one beyond it.
const ACROSS := 20
const BEYOND := Vector2i(30, 5)

func run(t) -> void:
	_test_a_body_across_the_street_shuts_the_way(t)
	_test_a_door_body_shuts_nothing(t)
	_test_a_plan_not_placed_shuts_nothing(t)
	_test_a_soft_seal_band_and_a_closure_are_shut(t)
	_test_her_paths_stop_at_the_circle_and_at_what_is_shut(t)

func _street() -> CityMap:
	var map := CityMap.new(Vector2i(40, 12))
	map.fill_rect(Rect2i(0, 0, 40, 12), GameEnums.TileType.BUILDING)
	map.fill_rect(Rect2i(0, 5, 40, 2), GameEnums.TileType.SIDEWALK)
	map.home_rect = Rect2i(0, 5, 1, 1)
	return map

## `id` standing across the sidewalk at tile column `x`.
func _across(map: CityMap, x: int, id := "barricade") -> EventScheduler.Planned:
	return EventScheduler.Planned.new(EventCatalogue.by_id(id),
			map.tile_to_world(Vector2i(x, 5)) + Vector2(0, Tuning.TILE_SIZE * 0.5))

func _test_a_body_across_the_street_shuts_the_way(t) -> void:
	var map := _street()
	var open := DayReach.of(map, [] as Array[EventScheduler.Planned])
	t.check(open.reaches(BEYOND), "with nothing standing, the far end of the street is reached")
	var reach := DayReach.of(map, [_across(map, ACROSS)] as Array[EventScheduler.Planned])
	t.check(not reach.reaches(BEYOND), "a barricade across the street cuts off the ground beyond it")
	t.check(reach.is_shut(Vector2i(ACROSS, 5)) and reach.shut().has(Vector2i(ACROSS, 5)),
			"and the ground under it is shut")
	t.check(reach.reaches(Vector2i(10, 5)), "while the ground on home's side of it is still reached")

func _test_a_door_body_shuts_nothing(t) -> void:
	var map := _street()
	var hut := _across(map, ACROSS, "checkpoint_hut")
	t.check(not DayReach.of(map, [hut] as Array[EventScheduler.Planned]).reaches(BEYOND),
			"a hut that is not a door's body stands in the way like any other body")
	hut.stand_as_a_door()
	t.check(DayReach.of(map, [hut] as Array[EventScheduler.Planned]).reaches(BEYOND),
			"and the same hut stood at a region door shuts nothing: a door is a crossing")

func _test_a_plan_not_placed_shuts_nothing(t) -> void:
	var map := _street()
	var unplaced := EventScheduler.Planned.new(EventCatalogue.by_id("barricade"), Vector2.INF)
	t.check(DayReach.of(map, [unplaced] as Array[EventScheduler.Planned]).reaches(BEYOND),
			"a row the day budgeted but has not sited stands nowhere")

func _test_a_soft_seal_band_and_a_closure_are_shut(t) -> void:
	var map := _street()
	var band := {}
	for y in range(5, 7):
		band[Vector2i(ACROSS, y)] = true
	map.soft_sealed_tiles = band
	t.check(not DayReach.of(map, [] as Array[EventScheduler.Planned]).reaches(BEYOND),
			"a soft seal's band across the sidewalk shuts it: the red arrow cannot walk it")
	map.soft_sealed_tiles = {}
	map.closed_tiles = band.duplicate()
	t.check(not DayReach.of(map, [] as Array[EventScheduler.Planned]).reaches(BEYOND),
			"and so does today's closure")

## **Close by is a walk inside a circle** (`DayReach.paths_over()`, the measure day 13's dawn and its
## task both take): from a seed, tile by tile along the sidewalk, every tile reached is nearer the
## centre than the radius, the walk stops at shut ground even where the circle goes on, and a seed
## standing on shut ground still walks out of it, as she may stand inside a body's disc.
func _test_her_paths_stop_at_the_circle_and_at_what_is_shut(t) -> void:
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
