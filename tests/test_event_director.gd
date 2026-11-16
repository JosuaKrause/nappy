extends RefCounted
## `EventDirector`'s siting of the rows it sends ahead of her (`EventDef.is_sent_ahead()`; inbox
## #1460): the dog walker down her own sidewalk toward her, the patrol down the carriageway lane
## that drives toward her, and the convoy in the lane beside her from either end, its first leg
## running past her to the far edge of the next junction box; and a sent row refused, and asked
## again, where its first leg starts within `EventScheduler.EVENT_SPACING_ANY` of a placed plan or
## runs through a field a plan keeps clear.
##
## On a hand-drawn map, one street running north-south the whole length of the map (`_street()`),
## with plans made by hand: plans and rows are data, built as they are, and the director is handed
## the map alone and moves by the map's navigator, as `tests/test_world_passability.gd` hands it.
## Each row is owed through `force()` (the `--force` flag, which `start_day()` takes up and which
## forces a sent row as the director sends it), so a check sees the siting of the one row it asks
## about.

const TILE := Tuning.TILE_SIZE
## The map's length in tiles: six of the lattice's periods, so a street with junction boxes at
## every period's start either side of her.
const LENGTH := 84
## Her tile: on the street's east sidewalk, between two junction boxes.
const HER := Vector2i(4, 36)
## The day the rows are owed on: one the convoy comes on.
const DAY := 13

func run(t: TestRunner) -> void:
	_test_the_dog_walker_comes_down_her_sidewalk_toward_her(t)
	_test_the_patrol_comes_down_the_lane_that_drives_toward_her(t)
	_test_the_convoy_comes_in_the_lane_beside_her_from_either_end(t)
	_test_a_sent_row_keeps_out_of_a_field_kept_clear(t)
	_test_a_sent_row_starts_clear_of_a_placed_plan(t)

## One street a period wide running north-south: its west sidewalk, its carriageway and its east
## sidewalk (`CityMap.corridor_offset()` 0 to 5), and building east of it.
static func _street() -> CityMap:
	var size := Vector2i(CityMap.period(), LENGTH)
	var map := CityMap.new(size)
	map.fill_rect(Rect2i(Vector2i.ZERO, size), GameEnums.TileType.BUILDING)
	map.fill_rect(Rect2i(0, 0, Tuning.SIDEWALK_WIDTH, LENGTH), GameEnums.TileType.SIDEWALK)
	map.fill_rect(Rect2i(Tuning.SIDEWALK_WIDTH, 0, Tuning.STREET_WIDTH - 2 * Tuning.SIDEWALK_WIDTH,
			LENGTH), GameEnums.TileType.ROAD)
	map.fill_rect(Rect2i(Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH, 0, Tuning.SIDEWALK_WIDTH,
			LENGTH), GameEnums.TileType.SIDEWALK)
	return map

static func _her() -> Vector2:
	return (Vector2(HER) + Vector2(0.5, 0.5)) * TILE

## A director over `map` owing `row` and nothing else, its day started over `plans` on a stream of
## `seed_value`.
static func _director(map: CityMap, row: String, plans: Array[EventPlan],
		seed_value := 1) -> EventDirector:
	var director := EventDirector.new(map)
	director.force(row, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	director.start_day(DAY, plans, rng)
	return director

## What the director hands out once its wait has passed, with her at her tile walking north.
static func _due(director: EventDirector) -> Array:
	return director.due(10.0, _her(), Vector2.UP * Tuning.WALK_SPEED)

static func _no_plans() -> Array[EventPlan]:
	var none: Array[EventPlan] = []
	return none

## The dog walker is sent as the loose dog is: created at once (no warning first) just out of sight
## down her own sidewalk, walking toward her and past her.
func _test_the_dog_walker_comes_down_her_sidewalk_toward_her(t: TestRunner) -> void:
	var map := _street()
	var due := _due(_director(map, "dog_walker", _no_plans()))
	t.check(due.size() >= 2, "the dog walker is handed out (%d)" % due.size())
	if due.size() < 2:
		return
	var def := due[0] as EventDef
	var path := due[1] as PackedVector2Array
	t.check(def.id == "dog_walker" and def.comes_down_her_line() and not def.warns_before_it_exists(),
			"as the copy sent down her line, created at once with no warning first")
	t.check(map.tile_at(map.world_to_tile(path[0])) == GameEnums.TileType.SIDEWALK
			and path[0].y < _her().y - Tuning.VIEW_HALF_EXTENT.y,
			"it starts on a sidewalk ahead of her, out of her sight (%v)" % path[0])
	t.check(path[path.size() - 1].y > _her().y,
			"and walks toward her and past her (%v)" % path[path.size() - 1])

## The patrol is sent down the carriageway lane that drives toward her, never from behind her: its
## route runs from up the road ahead of her, past her, in the lane driving south.
func _test_the_patrol_comes_down_the_lane_that_drives_toward_her(t: TestRunner) -> void:
	var map := _street()
	var lane := CrowdLanes.lane_centre(0, CrowdLanes.road_lane(true, 1.0))
	var sited := 0
	var toward := 0
	for seed_value in range(1, 9):
		var due := _due(_director(map, "police_patrol", _no_plans(), seed_value))
		if due.size() < 2:
			continue
		sited += 1
		var path := due[1] as PackedVector2Array
		if path[0].y < _her().y and path[path.size() - 1].y > _her().y \
				and is_equal_approx(path[0].x, lane):
			toward += 1
	t.check(sited > 0 and toward == sited,
			"every patrol sent comes down the lane driving toward her (%d of %d)" % [toward, sited])

## The convoy is warned of first in the lane beside her: its place is up the road out of sight,
## level with the lane its way drives in; its first leg runs past her to the far edge of the next
## junction box; and over the director's streams it comes from either end.
func _test_the_convoy_comes_in_the_lane_beside_her_from_either_end(t: TestRunner) -> void:
	var map := _street()
	var south := 0
	var north := 0
	var wrong: Array[String] = []
	for seed_value in range(1, 13):
		var due := _due(_director(map, "military_convoy", _no_plans(), seed_value))
		if due.size() < 2:
			wrong.append("seed %d: none sited" % seed_value)
			continue
		var def := due[0] as EventDef
		var path := due[1] as PackedVector2Array
		var going := 1.0 if path[path.size() - 1].y > path[0].y else -1.0
		var lane := CrowdLanes.lane_centre(0, CrowdLanes.road_lane(true, going))
		var end_tile := int(roundf(path[path.size() - 1].y / TILE))
		var box_edge := Tuning.STREET_WIDTH if going > 0.0 else 0
		var fine := def.is_warned_in_its_lane() and def.warns_before_it_exists() \
				and is_equal_approx(path[0].x, lane) \
				and absf(path[0].y - _her().y) > Tuning.VIEW_HALF_EXTENT.y \
				and (path[path.size() - 1].y - _her().y) * going > 0.0 \
				and posmod(end_tile, CityMap.period()) == box_edge
		if not fine:
			wrong.append("seed %d: %s" % [seed_value, path])
		if going > 0.0:
			south += 1
		else:
			north += 1
	t.check(wrong.is_empty(), "every convoy is warned of in its lane up the road, out of sight, its "
			+ "leg past her to the far edge of the next box%s" % (
				"" if wrong.is_empty() else ": " + "; ".join(wrong)))
	t.check(south > 0 and north > 0,
			"and it comes from either end (%d driving south, %d north)" % [south, north])

## A lethal row standing on the dog walker's way keeps its field clear: the dog walker is refused
## while the plan stands, and handed out at the next ask once it is spent.
func _test_a_sent_row_keeps_out_of_a_field_kept_clear(t: TestRunner) -> void:
	var map := _street()
	var lethal := EventDef.new()
	lethal.id = "lethal_by_hand"
	lethal.hard_fail = true
	lethal.inner_radius = 30.0
	lethal.outer_radius = 120.0
	var plan := EventPlan.new(lethal, _her() + Vector2(TILE, -3.0 * TILE))
	t.check(plan.keeps_its_field_clear(), "a lethal row that is no wall keeps its field clear")
	var plans: Array[EventPlan] = [plan]
	var director := _director(map, "dog_walker", plans)
	t.check(_due(director).is_empty(),
			"the dog walker, whose way runs through that field, is refused")
	plan.spend()
	t.check(not _due(director).is_empty(), "and handed out once the plan is spent")

## A sent row starts no nearer a placed plan than `EventScheduler.EVENT_SPACING_ANY`: a café right
## by the place the dog walker starts refuses it, and one further off does not.
func _test_a_sent_row_starts_clear_of_a_placed_plan(t: TestRunner) -> void:
	var map := _street()
	var open := _due(_director(map, "dog_walker", _no_plans()))
	if open.size() < 2:
		t.check(false, "the dog walker is handed out with nothing standing")
		return
	var start := (open[1] as PackedVector2Array)[0]
	var cafe := EventCatalogue.by_id("cafe_tables")
	var near: Array[EventPlan] = [EventPlan.new(cafe, start + Vector2(0.0, -TILE))]
	t.check(_due(_director(map, "dog_walker", near)).is_empty(),
			"a café a tile from where it starts refuses it")
	var far: Array[EventPlan] = [EventPlan.new(cafe,
			start + Vector2(0.0, -EventScheduler.EVENT_SPACING_ANY - 2.0 * TILE))]
	t.check(not _due(_director(map, "dog_walker", far)).is_empty(),
			"and one further off than the spacing does not")
