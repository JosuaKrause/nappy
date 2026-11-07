extends RefCounted
## `WinnableDay`, the two repairs that keep a planned day winnable: one calm area left clean, and a
## route from home to it kept open. Each is handed stand-ins for the day's events and calm areas
## with the answers set (`FakeDayEvents`, `FakeCalmAreas`), so no city is generated and no day is
## planned; which rows spoil which area, and which block the way, is `DayEvents`' to work out and is
## checked once in `tests/test_day_events.gd`.
##
## The clean-park checks take their areas and spoiler counts from what a real day answers: seed
## 4242's day 4 with every calm area used, as `CalmAreas.of()` and `build_day()` answer it. The
## walkable checks stand on a street laid out by hand, the map the repair floods.

## Calm areas of seed 4242 and how many rows spoil each on day 4 with every area used.
const SPOILED_COUNTS := {Vector2i(1, 6): 4, Vector2i(1, 9): 4, Vector2i(2, 2): 6, Vector2i(9, 9): 3}

func run(t) -> void:
	_test_a_day_with_a_clean_area_keeps_every_row(t)
	_test_every_area_used_clears_the_least_disturbed(t)
	_test_an_unused_area_is_cleared_whoever_else_is_spoiled(t)
	_test_the_area_set_aside_neither_counts_nor_is_cleared(t)
	_test_a_body_cutting_off_every_calm_area_is_dropped(t)
	_test_the_route_kept_is_to_clean_ground_when_one_area_is_set_aside(t)
	_test_a_target_the_seals_cut_off_asks_nothing_of_the_rows(t)

# ------------------------------------------------------------------ one park clean ---

## Rows of `id` standing on nothing in particular: the stand-in answers which area they spoil.
func _rows(id: String, count: int) -> Array[EventScheduler.Planned]:
	var rows: Array[EventScheduler.Planned] = []
	for i in count:
		rows.append(EventScheduler.Planned.new(EventCatalogue.by_id(id), Vector2(i * 64, 0)))
	return rows

## The areas of `SPOILED_COUNTS`, each `used`, and a stand-in plan in which each is spoiled by as
## many rows as the real day answered. Answers `[calm, events, spoilers by block]`.
func _all_spoiled(used: Array[Vector2i]) -> Array:
	var calm := FakeCalmAreas.new()
	var events := FakeDayEvents.new()
	var by_block := {}
	for block: Vector2i in SPOILED_COUNTS:
		calm.set_area(block, Rect2i(), Rect2(), [], used.has(block))
		var rows := _rows("leaf_blower", SPOILED_COUNTS[block])
		events.set_spoilers(block, rows)
		by_block[block] = rows
	return [calm, events, by_block]

func _test_a_day_with_a_clean_area_keeps_every_row(t) -> void:
	var calm := FakeCalmAreas.new() \
			.set_area(Vector2i(1, 4), Rect2i(), Rect2()) \
			.set_area(Vector2i(1, 6), Rect2i(), Rect2(), [], true)
	var events := FakeDayEvents.new().set_spoilers(Vector2i(1, 6), _rows("busker", 4))
	WinnableDay.ensure_one_usable_park(events, calm)
	t.check(events.removed.is_empty(), "a day that leaves one calm area clean loses no row")

func _test_every_area_used_clears_the_least_disturbed(t) -> void:
	var made := _all_spoiled([Vector2i(1, 6), Vector2i(1, 9), Vector2i(2, 2), Vector2i(9, 9)])
	var events: FakeDayEvents = made[1]
	WinnableDay.ensure_one_usable_park(events, made[0])
	t.check(events.removed == made[2][Vector2i(9, 9)],
			"with every area used and spoiled, the least disturbed one is cleared, and only it")
	t.check(not events.is_spoiled(Vector2i(9, 9)) and events.is_spoiled(Vector2i(1, 6)),
			"so the day has one clean area and the rest stand")

func _test_an_unused_area_is_cleared_whoever_else_is_spoiled(t) -> void:
	var made := _all_spoiled([Vector2i(1, 6), Vector2i(9, 9)])
	var events: FakeDayEvents = made[1]
	WinnableDay.ensure_one_usable_park(events, made[0])
	var expected: Array[EventScheduler.Planned] = []
	expected.append_array(made[2][Vector2i(1, 9)])
	expected.append_array(made[2][Vector2i(2, 2)])
	t.check(events.removed == expected,
			"every area she has not used is cleared, the more disturbed one too, and none she used")

func _test_the_area_set_aside_neither_counts_nor_is_cleared(t) -> void:
	var calm := FakeCalmAreas.new() \
			.set_area(Vector2i(1, 4), Rect2i(), Rect2(), [], true) \
			.set_area(Vector2i(1, 6), Rect2i(), Rect2(), [], true) \
			.set_area(Vector2i(2, 2), Rect2i(), Rect2(), [], true) \
			.set_besides(Vector2i(1, 4))
	var nearer := _rows("busker", 4)
	var events := FakeDayEvents.new() \
			.set_spoilers(Vector2i(1, 6), nearer) \
			.set_spoilers(Vector2i(2, 2), _rows("busker", 6))
	WinnableDay.ensure_one_usable_park(events, calm)
	t.check(events.removed == nearer,
			"the swing's clean park does not count as the clean one: the least disturbed other is "
			+ "cleared")
	var swing := _rows("busker", 1)
	events = FakeDayEvents.new() \
			.set_spoilers(Vector2i(1, 4), swing) \
			.set_spoilers(Vector2i(1, 6), _rows("busker", 4)) \
			.set_spoilers(Vector2i(2, 2), _rows("busker", 6))
	WinnableDay.ensure_one_usable_park(events, calm)
	t.check(not events.removed.has(swing[0]),
			"and the swing's park is never the one cleared, however little stands in it")

# ---------------------------------------------------------------- the city walkable ---

## Home at the west end of one sidewalk forty tiles long, a calm area on each side of it: `NEAR`
## north of its tenth to thirteenth tiles, `FAR` south of its thirtieth to thirty-third. A body on
## the sidewalk between them cuts `FAR` off from home and leaves `NEAR` reached.
const NEAR := Vector2i(1, 0)
const FAR := Vector2i(3, 0)
const SWING := Vector2i(5, 0)
const NEAR_GROUND := Rect2i(10, 0, 4, 4)
const FAR_GROUND := Rect2i(30, 8, 4, 4)

func _street() -> CityMap:
	var map := CityMap.new(Vector2i(40, 12))
	map.fill_rect(Rect2i(0, 0, 40, 12), GameEnums.TileType.BUILDING)
	map.fill_rect(Rect2i(0, 4, 40, 4), GameEnums.TileType.SIDEWALK)
	map.fill_rect(NEAR_GROUND, GameEnums.TileType.PARK)
	map.fill_rect(FAR_GROUND, GameEnums.TileType.PARK)
	map.home_rect = Rect2i(0, 4, 1, 1)
	return map

## A barricade standing across the sidewalk at tile column `x`, or another row's body (`id`).
func _barricade_at(map: CityMap, x: int, id := "barricade") -> EventScheduler.Planned:
	return EventScheduler.Planned.new(EventCatalogue.by_id(id),
			map.tile_to_world(Vector2i(x, 5)) + Vector2(0, Tuning.TILE_SIZE * 0.5))

func _street_calm(map: CityMap, besides := CalmAreas.NONE) -> FakeCalmAreas:
	return FakeCalmAreas.new() \
			.set_area(NEAR, NEAR_GROUND, map.tile_rect_to_world(NEAR_GROUND),
					map.rect_tiles(NEAR_GROUND)) \
			.set_area(FAR, FAR_GROUND, map.tile_rect_to_world(FAR_GROUND),
					map.rect_tiles(FAR_GROUND)) \
			.set_besides(besides)

func _test_a_body_cutting_off_every_calm_area_is_dropped(t) -> void:
	var map := _street()
	# The fallen tree is the wider body, so it is the first the repair drops.
	var across := _barricade_at(map, 6, "fallen_tree")
	var beyond := _barricade_at(map, 20)
	var events := FakeDayEvents.new() \
			.set_obstructions([beyond, across] as Array[EventScheduler.Planned])
	WinnableDay.ensure_the_city_is_still_walkable(map, events, _street_calm(map))
	t.check(events.removed == ([across] as Array[EventScheduler.Planned]),
			"a body between home and every calm area is dropped, widest first; one past the nearer "
			+ "area is not (%d dropped)" % events.removed.size())

func _test_the_route_kept_is_to_clean_ground_when_one_area_is_set_aside(t) -> void:
	var map := _street()
	var beyond := _barricade_at(map, 20)
	var events := FakeDayEvents.new() \
			.set_obstructions([beyond] as Array[EventScheduler.Planned]) \
			.set_spoilers(NEAR, _rows("busker", 2))
	WinnableDay.ensure_the_city_is_still_walkable(map, events, _street_calm(map, SWING))
	t.check(events.removed == ([beyond] as Array[EventScheduler.Planned]),
			"on the swing day the route kept is to the clean area: the body cutting it off goes, "
			+ "though the spoiled one is reached")
	var plain := FakeDayEvents.new() \
			.set_obstructions([beyond] as Array[EventScheduler.Planned]) \
			.set_spoilers(NEAR, _rows("busker", 2))
	WinnableDay.ensure_the_city_is_still_walkable(map, plain, _street_calm(map))
	t.check(plain.removed.is_empty(),
			"while on an ordinary day any calm ground reached is enough, and the body stays")

func _test_a_target_the_seals_cut_off_asks_nothing_of_the_rows(t) -> void:
	var map := _street()
	var target: Array[Vector2i] = [Vector2i(39, 5)]
	var beyond := _barricade_at(map, 20)
	var events := FakeDayEvents.new().set_obstructions([beyond] as Array[EventScheduler.Planned])
	WinnableDay.ensure_the_city_is_still_walkable(map, events, _street_calm(map), target)
	t.check(events.removed == ([beyond] as Array[EventScheduler.Planned]),
			"a body between home and the resistance's target is dropped")
	var seal := _barricade_at(map, 36)
	var sealed := FakeDayEvents.new() \
			.set_obstructions([beyond] as Array[EventScheduler.Planned]) \
			.set_standing([seal] as Array[EventScheduler.Planned],
					[seal] as Array[EventScheduler.Planned])
	WinnableDay.ensure_the_city_is_still_walkable(map, sealed, _street_calm(map), target)
	t.check(sealed.removed.is_empty(),
			"when the day's own seals cut the target off, no row is dropped for it")
