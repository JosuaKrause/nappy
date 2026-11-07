extends RefCounted
## `CalmAreas`, the day's calm areas as dawn sees them: the one place what a calm area's ground and
## calm tiles are, and which of them she has used this act, is worked out, checked here once on a
## map laid out by hand with known answers. Everything else that needs these facts is handed the
## object, or a stand-in with the answers set (`tests/fake_calm_areas.gd`).
##
## The map is two blocks: a park filling its block's lot, and a courtyard whose calm is the court
## alone (`BlockLayout.open_rect`), the case a whole-lot reading gets wrong. A tile of each lot is
## left not calm, so the calm tiles are the area's own and not its rect's.

## The park's block, whose calm ground is its whole lot: tiles (6, 6) to (13, 13).
const PARK := Vector2i(0, 0)
## The courtyard's block, whose calm ground is its court: tiles (22, 8) to (25, 11).
const COURT := Vector2i(1, 0)
## A block she settled in that is not calm today, as a requisitioned park is.
const TAKEN := Vector2i(2, 0)

func run(t) -> void:
	_test_each_area_answers_its_own_calm_ground(t)
	_test_the_calm_tiles_are_the_calm_ones_of_that_ground(t)
	_test_used_and_unused_are_read_off_the_act(t)
	_test_the_area_set_aside_is_the_one_handed_in(t)

## Two calm blocks, the second a courtyard with a four-tile court.
func _map() -> CityMap:
	var map := CityMap.new(Vector2i(50, 20))
	map.fill_rect(CityMap.block_rect(PARK), GameEnums.TileType.PARK)
	map.set_tile(Vector2i(6, 6), GameEnums.TileType.SIDEWALK)
	var court := Rect2i(22, 8, 4, 4)
	map.fill_rect(court, GameEnums.TileType.COURTYARD)
	map.set_tile(Vector2i(25, 11), GameEnums.TileType.BUILDING)
	var layout := BlockLayout.new()
	layout.open_rect = court
	map.block_layouts[COURT] = layout
	map.calm_blocks = [PARK, COURT] as Array[Vector2i]
	return map

func _test_each_area_answers_its_own_calm_ground(t) -> void:
	var calm := CalmAreas.of(_map())
	t.check(calm.blocks() == ([PARK, COURT] as Array[Vector2i]),
			"the calm areas are the map's calm blocks, in its order")
	t.check(calm.rect_of(PARK) == Rect2i(6, 6, 8, 8),
			"a park's calm ground is its whole lot")
	t.check(calm.rect_of(COURT) == Rect2i(22, 8, 4, 4),
			"a courtyard's calm ground is its court alone, not its lot")
	t.check(calm.ground_of(COURT) == Rect2(704, 256, 128, 128),
			"and the same ground in world space, 32px a tile")
	t.check(calm.rect_of(TAKEN) == Rect2i() and calm.ground_of(TAKEN) == Rect2(),
			"a block that is not calm has no calm ground")

func _test_the_calm_tiles_are_the_calm_ones_of_that_ground(t) -> void:
	var calm := CalmAreas.of(_map())
	var court := calm.calm_tiles_of(COURT)
	t.check(court.size() == 15 and not court.has(Vector2i(25, 11)),
			"the court's calm tiles are its fifteen calm ones, not the built tile in it (%d)"
			% court.size())
	t.check(court[0] == Vector2i(22, 8), "walked row by row from the court's corner")
	var park := calm.calm_tiles_of(PARK)
	t.check(park.size() == 63 and not park.has(Vector2i(6, 6)),
			"the park's are its sixty-three calm ones, not the sidewalk tile on its corner (%d)"
			% park.size())

func _test_used_and_unused_are_read_off_the_act(t) -> void:
	var used: Array[Vector2i] = [TAKEN, COURT]
	var calm := CalmAreas.of(_map(), used)
	t.check(calm.used() == used, "the areas she used this act, most recent first, as handed in")
	t.check(calm.unused() == ([PARK] as Array[Vector2i]),
			"the calm areas she has not used are the rest, and a block no longer calm is not one")
	t.check(calm.unused_ground() == ([Rect2(192, 192, 256, 256)] as Array[Rect2]),
			"and the ground nothing may be placed near is theirs")
	var fresh := CalmAreas.of(_map())
	t.check(fresh.unused().size() == 2 and fresh.used().is_empty(),
			"with nothing used this act, every calm area is unused")

func _test_the_area_set_aside_is_the_one_handed_in(t) -> void:
	t.check(CalmAreas.of(_map()).besides() == CalmAreas.NONE,
			"on an ordinary day no calm area is set aside")
	t.check(CalmAreas.of(_map(), [], PARK).besides() == PARK,
			"and on the swing day the swing's park is")
