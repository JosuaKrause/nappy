extends RefCounted
## `EventDirector`'s siting of the rows it sends ahead of her (`EventDef.is_sent_ahead()`; inbox
## #1460 in silky-lemur): the dog walker down her own sidewalk toward her, the patrol down the
## carriageway lane that drives toward her, and the convoy in the lane beside her coming toward
## her, its first leg running past her and on by the way on's leg, on a street running
## north-south and on one running east-west, or, where that lane has no room, down the crossing
## street at the next box ahead of her, and for her standing in a junction box; a car's first leg
## sent only where the day's way on says a car may drive it and go on from its end; a sent row
## refused, and asked again, where its first leg starts within `EventScheduler.EVENT_SPACING_ANY`
## of a placed plan or runs through a field a plan keeps clear; and a marble of her route sent ahead of her that has no
## room, which waits for room and lets the marbles behind it through (calm-pelican-6); and its
## looks at what her walk lays (`site_what_is_on_her_way()`), handed a stand-in for the day's
## siting (`FakeWalkSiting`): a look asks each plan owed once, between one `begin_look()` and
## one `end_look()`, no oftener than once a walking second; a placed plan behind her for three
## walking seconds is asked again and one that has been in the world never; the next crew waits
## while one is laid and not yet real; and a place a rig puts on her route (`rig_her_route()`)
## is handed to her walk when its marble is drawn and not before, laid by
## `WalkSiting.lay_just_ahead()` where the rig asked for that and by `lay_ahead()` where it did
## not, joins the day's plan as a place from her route (`is_from_her_route()`), and is not
## rigged under `--force`; and the route a scene rigs (`start_recipe_route()`): it is owed the
## count the scene says, and the marbles it puts in the bag first are drawn first.
##
## On a hand-drawn map, one street running the whole length of the map (`_street()`, north-south or
## the same map turned; `_crossroads()` adds a street crossing it at the box ahead of her), with
## plans made by hand: plans and rows are data, built as they are, and the director is handed the
## map alone and moves by the map's navigator, as `tests/test_world_passability.gd` hands it. It is handed a fake way on (`FakeWayOn`), whose
## answers the test sets: on one street no stretch is a through road, and whether a car may drive a
## leg and go on from it is `WayOn`'s own suite's, `tests/test_way_on.gd`. Each siting check owes its row through `force()` (the
## `--force` flag, which `start_day()` takes up and which forces a sent row as the director sends
## it), so a check sees the siting of the one row it asks about; the waiting check rigs her route's
## bag instead, since a forced row is not a marble.

const TILE := Tuning.TILE_SIZE
## The map's length in tiles: six of the lattice's periods, so a street with junction boxes at
## every period's start either side of her.
const LENGTH := 84
## Her tile on the street running north-south: on its east sidewalk, between two junction boxes.
## On the street running east-west, the same tile turned (`_her()`).
const HER := Vector2i(4, 36)
## The day the rows are owed on: one the convoy comes on.
const DAY := 13

## **A way on whose answers the test sets** (`WayOn`): whether a car may drive a leg
## (`driven()`, the leg as it is handed in or none) and whether it has a next leg from where it stands (`next_leg()`), recording
## what it was asked and the day's rule it was told (`use_the_days_rule()`).
class FakeWayOn extends WayOn:
	var drives := true
	var goes_on := true
	var turns := false
	var asked_to_drive: Array[PackedVector2Array] = []
	var asked_on_from: Array[Array] = []
	var told_rule := Callable()

	func _init() -> void:
		super(null, null, null)

	## Overrides WayOn.use_the_days_rule.
	func use_the_days_rule(may_take: Callable) -> void:
		told_rule = may_take

	## Overrides WayOn.driven.
	func driven(_row: EventDef, path: PackedVector2Array) -> PackedVector2Array:
		asked_to_drive.append(path)
		return path if drives else PackedVector2Array()

	## Overrides WayOn.next_leg.
	func next_leg(_row: EventDef, at: Vector2, heading: Vector2,
			_her: Vector2) -> PackedVector2Array:
		asked_on_from.append([at, heading])
		return PackedVector2Array([at, at + heading * TILE]) if goes_on else PackedVector2Array()

	## Overrides WayOn.leg_out_by.
	func leg_out_by(_row: EventDef, at: Vector2, heading: Vector2, out: Vector2,
			_her: Vector2) -> PackedVector2Array:
		if not goes_on or not turns:
			return PackedVector2Array()
		return PackedVector2Array([at, at + heading * TILE, at + heading * TILE + out * TILE])

func run(t: TestRunner) -> void:
	_test_the_dog_walker_comes_down_her_sidewalk_toward_her(t)
	for vertical: bool in [true, false]:
		_test_the_patrol_comes_down_the_lane_that_drives_toward_her(t, vertical)
		_test_the_convoy_comes_in_the_lane_beside_her_toward_her(t, vertical)
	_test_a_convoy_is_sited_only_where_the_ground_holds_while_its_badge_is_up(t)
	_test_the_convoys_leg_crosses_the_box_behind_her_from_short_of_it(t)
	_test_the_convoy_comes_down_the_crossing_street_where_her_lane_has_no_room(t)
	_test_the_convoy_turns_round_the_corner_toward_her(t)
	_test_the_convoy_comes_for_her_standing_in_a_box(t)
	_test_a_car_is_sent_only_on_a_leg_it_may_drive_and_go_on_from(t)
	_test_a_sent_row_keeps_out_of_a_field_kept_clear(t)
	_test_a_further_leg_keeps_out_of_a_field_kept_clear_and_a_doors_ground(t)
	_test_a_sent_row_starts_clear_of_a_placed_plan(t)
	_test_a_sent_row_with_no_room_lets_the_next_marbles_through(t)
	_test_a_look_asks_each_owed_plan_once_between_one_begin_and_one_end(t)
	_test_a_placed_plan_behind_her_is_asked_again_and_one_that_was_live_never(t)
	_test_the_next_crew_waits_while_one_is_laid_and_not_yet_real(t)
	_test_a_place_rigged_just_ahead_is_handed_over_with_its_marble_and_laid_just_ahead(t)
	_test_a_place_rigged_without_the_setting_is_laid_past_the_band(t)
	_test_nothing_is_rigged_under_force(t)
	_test_the_copy_on_her_route_shares_its_rows_body(t)
	_test_a_rigged_route_is_owed_its_count_and_pre_bag(t)
	_test_a_walk_that_sends_its_own_trucks_is_owed_the_ones_its_plan_left_unplaced(t)
	_test_a_walk_lets_the_share_of_the_wait_it_names_pass_between_handouts(t)
	_test_a_walk_that_sends_nothing_has_nothing_to_hand_out(t)

## One street a period wide running north-south: its west sidewalk, its carriageway and its east
## sidewalk (`CityMap.corridor_offset()` 0 to 5), and building east of it. Turned where `vertical`
## is false: the same street running east-west, its north sidewalk, carriageway and south sidewalk.
static func _street(vertical := true) -> CityMap:
	var size := Vector2i(CityMap.period(), LENGTH)
	var map := CityMap.new(size if vertical else Vector2i(size.y, size.x))
	var bands: Array[Array] = [
		[0, Tuning.SIDEWALK_WIDTH, GameEnums.TileType.SIDEWALK],
		[Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH - 2 * Tuning.SIDEWALK_WIDTH,
				GameEnums.TileType.ROAD],
		[Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH, Tuning.SIDEWALK_WIDTH,
				GameEnums.TileType.SIDEWALK]]
	map.fill_rect(Rect2i(Vector2i.ZERO, map.size_in_tiles()), GameEnums.TileType.BUILDING)
	for band in bands:
		var from: int = band[0]
		var across: int = band[1]
		var kind: GameEnums.TileType = band[2]
		map.fill_rect(Rect2i(from, 0, across, LENGTH) if vertical
				else Rect2i(0, from, LENGTH, across), kind)
	return map

static func _her(vertical := true) -> Vector2:
	return _turned(HER, vertical)

## The middle of `tile` of the street running north-south, or of the same tile turned onto the
## street running east-west.
static func _turned(tile: Vector2i, vertical: bool) -> Vector2:
	var turned := tile if vertical else Vector2i(tile.y, tile.x)
	return (Vector2(turned) + Vector2(0.5, 0.5)) * TILE

## The way along the street she walks: north on the street running north-south, west on the one
## running east-west.
static func _walking(vertical := true) -> Vector2:
	return Vector2.UP if vertical else Vector2.LEFT

## A director over `map` owing `row` and nothing else, its day started over `plans` on a stream of
## `seed_value`, handed `way_on` (a fake that lets every leg go on unless one is handed).
static func _director(map: CityMap, row: String, plans: Array[EventPlan],
		seed_value := 1, way_on: WayOn = null) -> EventDirector:
	var director := EventDirector.new(map)
	director.use_way_on(way_on if way_on else FakeWayOn.new())
	director.force(row, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	director.start_day(DAY, plans, rng, DaySpec.DirectorSends.THE_DAYS_ROWS)
	return director

## What the director hands out once its wait has passed, with her at her tile walking along the
## street (`_walking()`).
static func _due(director: EventDirector, vertical := true) -> Array:
	return _due_at(director, _her(vertical), vertical)

## The same with her at `her`.
static func _due_at(director: EventDirector, her: Vector2, vertical := true) -> Array:
	return director.due(10.0, her, _walking(vertical) * Tuning.WALK_SPEED)

## How far `point` lies along the street from her, the way she walks.
static func _ahead_of_her(point: Vector2, vertical := true) -> float:
	return (point - _her(vertical)).dot(_walking(vertical))

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
	t.check(def.id() == "dog_walker" and def.comes_down_her_line() and not def.warns_before_it_exists(),
			"as the copy sent down her line, created at once with no warning first")
	t.check(map.tile_at(map.world_to_tile(path[0])) == GameEnums.TileType.SIDEWALK
			and path[0].y < _her().y - Tuning.VIEW_HALF_EXTENT.y,
			"it starts on a sidewalk ahead of her, out of her sight (%v)" % path[0])
	t.check(path[path.size() - 1].y > _her().y,
			"and walks toward her and past her (%v)" % path[path.size() - 1])

## The patrol is sent down the carriageway lane that drives toward her, never from behind her: its
## route runs from up the road ahead of her, out of sight, past her, in the lane driving toward her.
func _test_the_patrol_comes_down_the_lane_that_drives_toward_her(t: TestRunner,
		vertical: bool) -> void:
	var map := _street(vertical)
	var toward_her := -_walking(vertical)
	var lane := CrowdLanes.lane_centre(0, CrowdLanes.road_lane(vertical,
			toward_her.y if vertical else toward_her.x))
	var half := Tuning.VIEW_HALF_EXTENT.y if vertical else Tuning.VIEW_HALF_EXTENT.x
	var sited := 0
	var toward := 0
	for seed_value in range(1, 9):
		var due := _due(_director(map, "police_patrol", _no_plans(), seed_value),
				vertical)
		if due.size() < 2:
			continue
		sited += 1
		var path := due[1] as PackedVector2Array
		var across := path[0].x if vertical else path[0].y
		if _ahead_of_her(path[0], vertical) > half \
				and _ahead_of_her(path[path.size() - 1], vertical) < 0.0 \
				and is_equal_approx(across, lane):
			toward += 1
	t.check(sited > 0 and toward == sited,
			"on a street running %s, every patrol sent comes down the lane driving toward her from "
			% ("north-south" if vertical else "east-west")
			+ "out of sight up the road (%d of %d)" % [toward, sited])

## The convoy is warned of first in the lane beside her: its place is up the road out of sight,
## level with the lane its way drives in; its first leg runs down the lane to the point level with
## her and on by the way on's leg from there (`WayOn.next_leg()`, which carries it through the next
## junction box); and over the director's streams it always comes toward her, never from behind
## ("just ahead of the player", inbox #1460 in silky-lemur).
func _test_the_convoy_comes_in_the_lane_beside_her_toward_her(t: TestRunner,
		vertical: bool) -> void:
	var map := _street(vertical)
	var half := Tuning.VIEW_HALF_EXTENT.y if vertical else Tuning.VIEW_HALF_EXTENT.x
	var name := "north-south" if vertical else "east-west"
	var with_her := 0
	var at_her := 0
	var wrong: Array[String] = []
	for seed_value in range(1, 13):
		var due := _due(_director(map, "military_convoy", _no_plans(), seed_value),
				vertical)
		if due.size() < 2:
			wrong.append("seed %d: none sited" % seed_value)
			continue
		var def := due[0] as EventDef
		var path := due[1] as PackedVector2Array
		var last := path[path.size() - 1]
		var going := (last - path[0]).normalized()
		var lane := CrowdLanes.lane_centre(0, CrowdLanes.road_lane(vertical,
				going.y if vertical else going.x))
		var across := path[0].x if vertical else path[0].y
		var up_the_road := (path[0] - _her(vertical)).dot(going)
		var past_her := (last - _her(vertical)).dot(going)
		var level := Vector2(path[0].x, _her(vertical).y) if vertical \
				else Vector2(_her(vertical).x, path[0].y)
		var fine := def.is_warned_in_its_lane() and def.warns_before_it_exists() \
				and is_equal_approx(across, lane) and up_the_road < -half and past_her > 0.0 \
				and path.size() == 3 and path[1].is_equal_approx(level) \
				and last.is_equal_approx(level + going * TILE)
		if not fine:
			wrong.append("seed %d: %s" % [seed_value, path])
		if going.dot(_walking(vertical)) > 0.0:
			with_her += 1
		else:
			at_her += 1
	t.check(wrong.is_empty(), "on a street running %s, every convoy is warned of in its lane up "
			% name + "the road, out of sight, its leg to level with her and on by the way on's leg%s" % (
				"" if wrong.is_empty() else ": " + "; ".join(wrong)))
	t.check(with_her == 0 and at_her > 0,
			"and it comes toward her (%d toward her, %d from behind her)" % [at_her, with_her])

## **A convoy is sited only where it could be created from wherever the camera is once its badge
## has been up** (`EventDirector._holds_while_its_badge_is_up()`): its badge is up alone for
## `warned_for()` and the thing is created just out of sight of the camera then, a place that
## has moved along the road with her, so a start that is ground now and a break in the
## carriageway a second of her running on would take the badge down with nothing behind it. A
## way on that lets a car start only up to a cutoff down the road sites the convoy when the
## cutoff is further than she can run in that time and refuses it when it is nearer.
func _test_a_convoy_is_sited_only_where_the_ground_holds_while_its_badge_is_up(
		t: TestRunner) -> void:
	var map := _street()
	var plain := _due(_director(map, "military_convoy", _no_plans()))
	if plain.size() < 2:
		t.check(false, "the convoy is sited on the plain street")
		return
	var wanted := (plain[1] as PackedVector2Array)[0]
	var def := plain[0] as EventDef
	var reach := Tuning.RUN_SPEED * def.warned_for() + TILE
	for margin: float in [-TILE * 0.25, TILE * 0.5]:
		var way := _StartsAboveWayOn.new(wanted.y + reach + margin)
		var sited := _due(_director(map, "military_convoy", _no_plans(), 1, way)).size() >= 2
		t.check(sited == (margin > 0.0),
				("with ground to set off from %.0fpx %s than she runs in the badge's time, "
				+ "the convoy is %s")
				% [absf(margin), "further" if margin > 0.0 else "nearer",
				"sited" if margin > 0.0 else "refused"])

## **The convoy's leg past her crosses the box behind her from short of it** where the point level
## with her lies in that box or past it (`EventDirector.leg_in_the_lane()`): she may have walked back
## that far while its badge was up, and a walk that turned at that box has nothing straight on past
## it but a sealed street, so the way on is asked for the leg out of that box from just short of it,
## where it may turn, rather than from inside it or past it, where it can only drive straight on.
## With her where she was sited, the leg is asked from the point level with her.
func _test_the_convoys_leg_crosses_the_box_behind_her_from_short_of_it(t: TestRunner) -> void:
	var map := _street()
	var plain := _due(_director(map, "military_convoy", _no_plans()))
	if plain.size() < 2:
		t.check(false, "the convoy is sited on the plain street")
		return
	var def := plain[0] as EventDef
	var place := (plain[1] as PackedVector2Array)[0]
	var entry := float(3 * CityMap.period() * TILE)
	for case: Array in [[HER.y, _her().y], [3 * CityMap.period() + 2, entry - 1.0],
			[3 * CityMap.period() + Tuning.STREET_WIDTH + 2, entry - 1.0]]:
		var way := FakeWayOn.new()
		var director := _director(map, "military_convoy", _no_plans(), 1, way)
		var her := _turned(Vector2i(HER.x, int(case[0])), true)
		way.asked_on_from.clear()
		var leg := director.leg_in_the_lane(def, place, her, Vector2.DOWN, _her())
		var from: Vector2 = way.asked_on_from[0][0] if not way.asked_on_from.is_empty() \
				else Vector2.INF
		t.check(not leg.is_empty() and from.is_equal_approx(Vector2(place.x, float(case[1]))),
				"with her on tile row %d, the leg out of the box is asked from y %.0f (%s)"
				% [int(case[0]), float(case[1]), from])

## A way on that lets a car start only at or north of `cutoff` (up the road, away from her) and
## drive from there, as on a plain street.
class _StartsAboveWayOn extends FakeWayOn:
	var _cutoff := 0.0

	func _init(cutoff: float) -> void:
		super()
		_cutoff = cutoff

	## Overrides test_event_director.FakeWayOn.driven.
	func driven(_row: EventDef, path: PackedVector2Array) -> PackedVector2Array:
		return path if path.size() >= 2 and path[0].y <= _cutoff else PackedVector2Array()

## **Where the lane beside her has no room, the convoy comes down the crossing street at the next
## junction box ahead of her** (`EventDirector._across_the_next_box()`): on a street running
## north-south and its crossing street at the box north of her (`_crossroads()`), a way on that
## refuses every leg setting off in her own street (a crater or a seal there) sites it in the
## crossing street's lane out of sight up it, its leg crossing her street in the box ahead of her,
## asked of the way on from the edge of that box (the box she is beside, `_short_of_her_box()`), and
## going on where the way on lets it turn nowhere there; with the box ahead further than her view
## reaches along her street, none is sited.
func _test_the_convoy_comes_down_the_crossing_street_where_her_lane_has_no_room(
		t: TestRunner) -> void:
	var map := _crossroads()
	var due := _due(_director(map, "military_convoy", _no_plans(), 1, _OffHerStreetWayOn.new()))
	t.check(due.size() >= 2, "with her street refused, the convoy is sited (%d)" % due.size())
	if due.size() >= 2:
		var path := due[1] as PackedVector2Array
		var going := (path[1] - path[0]).normalized()
		var lane := CrowdLanes.lane_centre(CROSSING, CrowdLanes.road_lane(false, going.x))
		var out_of_sight := absf(path[0].x - _her().x) > Tuning.VIEW_HALF_EXTENT.x
		var box_edge := float(Tuning.STREET_WIDTH * TILE) + 1.0 if going.x < 0.0 else -1.0
		t.check(is_equal_approx(absf(going.x), 1.0) and is_equal_approx(path[0].y, lane) and out_of_sight
				and path[1].is_equal_approx(Vector2(box_edge, lane)),
				"down the crossing street's lane from out of sight, its leg crossing her street in "
				+ "the box ahead of her (%s)" % path)
	var far := _turned(Vector2i(HER.x, HER.y + 4), true)
	var refused := _due_at(_director(map, "military_convoy", _no_plans(), 1,
			_OffHerStreetWayOn.new()), far)
	t.check(refused.is_empty(),
			"and none where the box ahead lies further than her view along her street")

## **Down the crossing street, it turns at the box ahead of her into her street, toward her**
## (`EventDirector._round_the_corner_toward()`), where the way on lets it leave the box that way
## (`WayOn.leg_out_by()`): its leg runs down the crossing street's lane to just short of the box, is
## the way on's leg out of the box turning toward her, and goes on south down her street toward her
## by the way on's next leg. It is how a truck comes at her where her walk turns into that street.
func _test_the_convoy_turns_round_the_corner_toward_her(t: TestRunner) -> void:
	var way := _OffHerStreetWayOn.new()
	way.turns = true
	var due := _due(_director(_crossroads(), "military_convoy", _no_plans(), 1, way))
	t.check(due.size() >= 2, "with turns allowed, the convoy is sited (%d)" % due.size())
	if due.size() < 2:
		return
	var path := due[1] as PackedVector2Array
	var going := (path[1] - path[0]).normalized()
	var lane := CrowdLanes.lane_centre(CROSSING, CrowdLanes.road_lane(false, going.x))
	var box_edge := float(Tuning.STREET_WIDTH * TILE) + 1.0
	var last := path.size() - 1
	t.check(path.size() == 5 and is_equal_approx(path[0].y, lane)
			and path[1].is_equal_approx(Vector2(box_edge, lane))
			and (path[last] - path[last - 1]).normalized().is_equal_approx(Vector2.DOWN),
			"down the crossing street's lane to the box, round the corner, and on toward her (%s)"
			% path)

## **A convoy is sited for her standing in a junction box** (`EventDirector._stands_in_a_box()`), on
## a sidewalk corner of it where no single kerb says which street she is beside: in the lane of the
## street along her heading, coming toward her.
func _test_the_convoy_comes_for_her_standing_in_a_box(t: TestRunner) -> void:
	var map := _crossroads()
	var corner := _turned(Vector2i(Tuning.STREET_WIDTH - 1,
			CROSSING * CityMap.period() + Tuning.STREET_WIDTH - 1), true)
	var due := _due_at(_director(map, "military_convoy", _no_plans()), corner)
	t.check(due.size() >= 2, "with her on a box's corner, the convoy is sited (%d)" % due.size())
	if due.size() < 2:
		return
	var path := due[1] as PackedVector2Array
	var lane := CrowdLanes.lane_centre(0, CrowdLanes.road_lane(true, 1.0))
	t.check(is_equal_approx(path[0].x, lane) and path[0].y < corner.y - Tuning.VIEW_HALF_EXTENT.y,
			"in her street's lane driving south toward her, from out of sight up it (%s)" % path)

## The crossing street's corridor on `_crossroads()`: the box at its crossing is the next one north
## of her tile.
const CROSSING := 2

## The street of `_street()` running north-south on a square map, and a street the same width
## crossing it east-west at corridor `CROSSING`, its box the next one north of her.
static func _crossroads() -> CityMap:
	var map := CityMap.new(Vector2i(LENGTH, LENGTH))
	map.fill_rect(Rect2i(Vector2i.ZERO, map.size_in_tiles()), GameEnums.TileType.BUILDING)
	var from := CROSSING * CityMap.period()
	for vertical: bool in [true, false]:
		var start := 0 if vertical else from
		var bands: Array[Array] = [
			[0, Tuning.SIDEWALK_WIDTH, GameEnums.TileType.SIDEWALK],
			[Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH - 2 * Tuning.SIDEWALK_WIDTH,
					GameEnums.TileType.ROAD],
			[Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH, Tuning.SIDEWALK_WIDTH,
					GameEnums.TileType.SIDEWALK]]
		for band in bands:
			var offset: int = band[0]
			var across: int = band[1]
			var kind: GameEnums.TileType = band[2]
			map.fill_rect(Rect2i(start + offset, 0, across, LENGTH) if vertical
					else Rect2i(0, start + offset, LENGTH, across), kind)
	return map

## A way on that refuses every leg setting off in the street running north-south, as a crater or a
## seal in her street refuses it, and lets a car drive and go on from anywhere else.
class _OffHerStreetWayOn extends FakeWayOn:
	## Overrides test_event_director.FakeWayOn.driven.
	func driven(_row: EventDef, path: PackedVector2Array) -> PackedVector2Array:
		return path if path.size() >= 2 and path[0].x >= Tuning.STREET_WIDTH * TILE \
				else PackedVector2Array()

## **A car's first leg is sent only where the day's way on says a car may drive it and go on from its
## end** (`EventDirector.leg_in_the_lane()`): for the patrol and the convoy, a way on that refuses
## every leg (`driven()` empty) sites none, one with no next leg from any leg's end
## (`next_leg()` empty) sites none, and one that answers both sites one; and what it was asked is the
## leg handed out, and a next leg from that leg's end, going the way the leg goes.
func _test_a_car_is_sent_only_on_a_leg_it_may_drive_and_go_on_from(t: TestRunner) -> void:
	var map := _street()
	for row: String in ["police_patrol", "military_convoy"]:
		var undriven := 0
		var no_way_on := 0
		var sited := 0
		var asked_right := 0
		for seed_value in range(1, 9):
			var refuses := FakeWayOn.new()
			refuses.drives = false
			if _due(_director(map, row, _no_plans(), seed_value, refuses)).size() >= 2:
				undriven += 1
			var stub := FakeWayOn.new()
			stub.goes_on = false
			if _due(_director(map, row, _no_plans(), seed_value, stub)).size() >= 2:
				no_way_on += 1
			var both := FakeWayOn.new()
			var due := _due(_director(map, row, _no_plans(), seed_value, both))
			if due.size() < 2:
				continue
			sited += 1
			var leg := due[1] as PackedVector2Array
			var going := (leg[leg.size() - 1] - leg[0]).normalized()
			if both.asked_on_from.is_empty():
				continue
			var last_asked: Array = both.asked_on_from[both.asked_on_from.size() - 1]
			if both.asked_to_drive.has(leg) and (last_asked[0] as Vector2).is_equal_approx(
					leg[leg.size() - 1]) and (last_asked[1] as Vector2).is_equal_approx(going):
				asked_right += 1
		t.check(undriven == 0 and no_way_on == 0,
				"no %s is sited on a leg a car may not drive (%d of 8) or go on from (%d of 8)"
				% [row, undriven, no_way_on])
		t.check(sited > 0 and asked_right == sited,
				"and %d of 8 are where both answer, each asked of its own leg and a way on from its "
				% sited + "end (%d)" % asked_right)

## A row that ends the day at its core, its field holding to 30px and reaching `reach`, on a bare
## row's field otherwise.
func _lethal_by_hand(reach: float) -> EventDef:
	var bare := EventDraft.new("lethal_by_hand").build()
	var draft := bare.redraft()
	draft.lethal(LethalSpec.at_its_core())
	draft.field(bare.field().holding_to(30.0).reaching(reach))
	return draft.build()

## A lethal row standing on the dog walker's way keeps its field clear: the dog walker is refused
## while the plan stands, and handed out at the next ask once it is spent.
func _test_a_sent_row_keeps_out_of_a_field_kept_clear(t: TestRunner) -> void:
	var map := _street()
	var lethal := _lethal_by_hand(120.0)
	var plan := EventPlan.new(lethal, _her() + Vector2(TILE, -3.0 * TILE))
	t.check(plan.keeps_its_field_clear(), "a lethal row that is no wall keeps its field clear")
	var plans: Array[EventPlan] = [plan]
	var director := _director(map, "dog_walker", plans)
	t.check(_due(director).is_empty(),
			"the dog walker, whose way runs through that field, is refused")
	plan.spend()
	t.check(not _due(director).is_empty(), "and handed out once the plan is spent")

## **A further leg keeps out of a field a placed plan keeps clear and out of a region door's ground**
## (`EventDirector.clear_to_go_on()`), the day's rule the director tells the walk's way on as it is
## handed it (`use_way_on()`), asked here through the rule the fake way on was told, as `WayOn` asks
## it of every leg: a leg past a lethal row's field is refused while the plan stands and taken once it
## is spent, one clear of it is taken, and the same for a leg past a door and one clear of it. A placed
## plan that keeps no field clear (a café) refuses no leg, however near: the start's spacing is not
## this rule's.
func _test_a_further_leg_keeps_out_of_a_field_kept_clear_and_a_doors_ground(t: TestRunner) -> void:
	var map := _street()
	var lethal := _lethal_by_hand(120.0)
	# North of her is up the street; every place and leg below is in tiles north of her.
	var north := func(tiles: float, across := 0.0) -> Vector2:
		return _her() + Vector2(across, -tiles * TILE)
	var field := EventPlan.new(lethal, north.call(20.0, TILE))
	var cafe := EventPlan.new(EventCatalogue.by_id("cafe_tables"), north.call(31.0, TILE))
	var door := EventPlan.new(EventCatalogue.by_id("checkpoint_hut"), north.call(-40.0, TILE))
	door.stand_as_a_door()
	var plans: Array[EventPlan] = [field, cafe, door]
	var way_on := FakeWayOn.new()
	var director := _director(map, "police_patrol", plans, 1, way_on)
	t.check(director != null and way_on.told_rule.is_valid(), "the director tells the way on it is handed the day's rule")
	if not way_on.told_rule.is_valid():
		return
	var patrol := EventCatalogue.by_id("police_patrol").as_sent_ahead()
	var lane := -2.0 * TILE
	var takes := func(from_tiles: float, to_tiles: float) -> bool:
		var path := PackedVector2Array([north.call(from_tiles, lane), north.call(to_tiles, lane)])
		return bool(way_on.told_rule.call(path, patrol))
	t.check(not takes.call(14.0, 26.0) and takes.call(0.0, 10.0),
			"a leg past a lethal row's field is refused, and one clear of it taken")
	t.check(not takes.call(-34.0, -46.0) and takes.call(-4.0, -20.0),
			"a leg past a region door is refused, and one clear of its ground taken")
	t.check(takes.call(28.0, 34.0),
			"a leg past a café is taken: a plan that keeps no field clear refuses no further leg")
	field.spend()
	t.check(takes.call(14.0, 26.0), "and the leg past the lethal row's is taken once it is spent")

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

## **A marble of her route sent ahead of her that has no room does not hold the route**
## (calm-pelican-6): with a lethal row's kept-clear field over the street round her, her bag rigged
## so its next two marbles are patrols, the patrols wait and the marbles behind them are handed out;
## once the lethal row is spent the waiting patrols come. **And what waited takes the clock's turn**
## (board question sent-ahead-pace: in place of, at the same clock): nothing is handed out closer to
## the last than the clock's shortest wait (`EventDirector.AHEAD_INTERVAL`), before the lethal row is
## spent or after. **And a patrol with no room does not spend the turn it was drawn on**: the turn is
## asked again a second later (`EventDirector.SENT_RETRY`), so the first marble behind the two patrols
## comes before three of the clock's shortest waits have passed, where three whole waits, the first and
## one for each patrol, would come no sooner.
func _test_a_sent_row_with_no_room_lets_the_next_marbles_through(t: TestRunner) -> void:
	var map := _street()
	var lethal := _lethal_by_hand(600.0)
	var blocking := EventPlan.new(lethal, _her() + Vector2(-1.5 * TILE, 0.0))
	var plans: Array[EventPlan] = [blocking]
	for _i in 12:
		plans.append(EventPlan.new(EventCatalogue.by_id("cat_dash"), Vector2.INF))
	var director := EventDirector.new(map)
	director.use_way_on(FakeWayOn.new())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	director.start_day(DAY, plans, rng, DaySpec.DirectorSends.THE_DAYS_ROWS)
	var patrols: Array[String] = ["police_patrol", "police_patrol"]
	director.rig_her_route(patrols, 2)
	var step := 0.1
	var walked := 0.0
	var last_at := -INF
	var closest := INF
	var through := 0
	var sent_while_blocked := 0
	var first_at := INF
	for _step in 1200:
		walked += step
		var due := director.due(step, _her(), Vector2.UP * Tuning.WALK_SPEED)
		if due.is_empty():
			continue
		first_at = minf(first_at, walked)
		closest = minf(closest, walked - last_at)
		last_at = walked
		if (due[0] as EventDef).is_sent_ahead():
			sent_while_blocked += 1
		else:
			through += 1
	t.check(through > 0 and sent_while_blocked == 0,
			"with no room for the two patrols at the front of her bag, %d marbles behind them are "
			% through + "handed out and no sent row (%d)" % sent_while_blocked)
	t.check(first_at < 3.0 * EventDirector.AHEAD_INTERVAL.x,
			"and the first of them comes %.1fs into her walk, before three of the clock's shortest "
			% first_at + "waits (%.1fs): a patrol with no room does not spend its turn"
			% (3.0 * EventDirector.AHEAD_INTERVAL.x))
	blocking.spend()
	var patrols_came := 0
	for _step in 800:
		walked += step
		var due := director.due(step, _her(), Vector2.UP * Tuning.WALK_SPEED)
		if due.is_empty():
			continue
		closest = minf(closest, walked - last_at)
		last_at = walked
		if (due[0] as EventDef).id() == "police_patrol":
			patrols_came += 1
	t.check(patrols_came >= 2, "and once there is room the patrols that waited come (%d)" % patrols_came)
	t.check(closest >= EventDirector.AHEAD_INTERVAL.x - step,
			"and nothing is handed out closer to the last than the clock's shortest wait, %.1fs "
			% EventDirector.AHEAD_INTERVAL.x + "(the closest two %.1fs apart)" % closest)

## What `site_what_is_on_her_way()` hands the siting while she walks north from her tile for `seconds`
## of walking, one tenth of a second a tick; answers every plan it moved, in order.
static func _walk_for(director: EventDirector, seconds: float) -> Array[EventPlan]:
	var moved: Array[EventPlan] = []
	for _tick in int(seconds / 0.1):
		moved.append_array(director.site_what_is_on_her_way(0.1, _her(),
				Vector2.UP * Tuning.WALK_SPEED))
	return moved

## A director over the street owing `plans` to her walk, handed `siting`.
static func _director_with_a_siting(plans: Array[EventPlan], siting: FakeWalkSiting) -> EventDirector:
	var director := EventDirector.new(_street())
	director.use_way_on(FakeWayOn.new())
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	director.start_day(DAY, plans, rng, DaySpec.DirectorSends.THE_DAYS_ROWS, siting)
	return director

## **A look asks each plan owed once**, between one `begin_look()` and one `end_look()`, and no oftener
## than once a walking second (`EventDirector.ON_HER_WAY_LOOK`): none before she has walked
## `ON_HER_WAY_AFTER` seconds, then one look a second, each told where she is and her heading.
func _test_a_look_asks_each_owed_plan_once_between_one_begin_and_one_end(t: TestRunner) -> void:
	var fire := EventPlan.new(EventCatalogue.by_id("burning_building"), Vector2.INF)
	var crew := EventPlan.new(EventCatalogue.by_id("poster_crew"), Vector2.INF)
	var siting := FakeWalkSiting.new()
	var director := _director_with_a_siting([fire, crew] as Array[EventPlan], siting)
	_walk_for(director, EventDirector.ON_HER_WAY_AFTER - 1.0)
	t.check(siting.looks.is_empty(), "no look is made before she has walked %.0fs"
			% EventDirector.ON_HER_WAY_AFTER)
	var walked := 10.0
	_walk_for(director, 1.0 + walked)
	var looks := siting.looks.size()
	t.check(looks >= 1 and looks <= int(walked / EventDirector.ON_HER_WAY_LOOK) + 1,
			"after that, no more than one look a walking second (%d looks in %.0fs)" % [looks, walked])
	var shape := true
	var index := 0
	while index < siting.calls.size():
		var group: Array[String] = []
		var at := index
		while at < siting.calls.size() and (at == index or siting.calls[at] != "begin_look"):
			group.append(siting.calls[at])
			at += 1
		shape = shape and group.size() == 4 and group[0] == "begin_look" and group[3] == "end_look" \
				and group[1] == "lay_ahead" and group[2] == "lay_ahead"
		index = at
	t.check(shape, "each look begins once, asks each of the two plans owed once and ends once")
	t.check(siting.asked.count(fire) == looks and siting.asked.count(crew) == looks,
			"so each plan owed is asked once a look (%d, %d asks in %d looks)"
			% [siting.asked.count(fire), siting.asked.count(crew), looks])
	t.check((siting.looks[0][1] as Vector2).is_equal_approx(Vector2.UP)
			and (siting.looks[0][0] as Vector2).is_equal_approx(_her()),
			"and a look is told where she stands and the way she heads")

## A plan placed and still ahead of her is left alone; one the siting says is no longer ahead, for
## `ON_HER_WAY_TURNED_AWAY` seconds of walking, is asked again; one that has been in the world is
## never asked again.
func _test_a_placed_plan_behind_her_is_asked_again_and_one_that_was_live_never(t: TestRunner) -> void:
	var fire := EventPlan.new(EventCatalogue.by_id("burning_building"), Vector2.INF)
	var siting := FakeWalkSiting.new().set_place(fire.row_id(), _her() + Vector2.UP * 1500.0)
	var director := _director_with_a_siting([fire] as Array[EventPlan], siting)
	var moved := _walk_for(director, EventDirector.ON_HER_WAY_AFTER + 3.0)
	t.check(fire.is_placed() and moved.has(fire), "the fire is laid at its first look")
	var asks := siting.asked.size()
	_walk_for(director, 6.0)
	t.check(siting.asked.size() == asks,
			"while the siting says it is still ahead of her it is not asked again (%d asks)" % siting.asked.size())
	siting.set_still_ahead(false).set_place(fire.row_id(), _her() + Vector2.UP * 1800.0)
	_walk_for(director, EventDirector.ON_HER_WAY_TURNED_AWAY - 1.0)
	t.check(siting.asked.size() == asks,
			"nor before it has been behind her for %.0f walking seconds" % EventDirector.ON_HER_WAY_TURNED_AWAY)
	var again := _walk_for(director, 3.0)
	t.check(siting.asked.size() > asks and again.has(fire),
			"and after that it is asked again and moved (%d asks)" % siting.asked.size())
	fire.enter_the_world(WhereItStands.nowhere())
	asks = siting.asked.size()
	siting.set_place(fire.row_id(), _her() + Vector2.UP * 2100.0)
	_walk_for(director, 10.0)
	t.check(siting.asked.size() == asks, "one that has been in the world is never asked again")

## The next of a recurring row's copies waits while one is laid and not yet in the world, so the
## day's crews are spread along the walk.
func _test_the_next_crew_waits_while_one_is_laid_and_not_yet_real(t: TestRunner) -> void:
	var first := EventPlan.new(EventCatalogue.by_id("poster_crew"), Vector2.INF)
	var second := EventPlan.new(EventCatalogue.by_id("poster_crew"), Vector2.INF)
	var siting := FakeWalkSiting.new().set_place(first.row_id(), _her() + Vector2.UP * 1500.0)
	var director := _director_with_a_siting([first, second] as Array[EventPlan], siting)
	_walk_for(director, EventDirector.ON_HER_WAY_AFTER + 3.0)
	t.check(first.is_placed() and not second.is_placed() and not siting.asked.has(second),
			"the first crew is laid and the second is not even asked while it stands unreal")
	first.enter_the_world(WhereItStands.nowhere())
	_walk_for(director, 3.0)
	t.check(siting.asked.has(second) and second.is_placed(),
			"once the first is in the world the next is asked and laid")

## **A place a rig puts on her route is handed to her walk when its marble is drawn, not before,
## and laid just ahead where the rig asked for that** (`EventDirector.rig_her_route()` with
## `just_ahead`): rigged once she has walked past `EventDirector.ON_HER_WAY_AFTER`, the man shouting's
## marble is the next one handed out on her route, so the siting is asked nothing for the shortest
## wait the clock has (`EventDirector.AHEAD_INTERVAL`), and once it is drawn it is asked of
## `lay_just_ahead()` and never of `lay_ahead()`, is laid within a look, and is a place from her
## route, which joins the day's plan when first laid.
func _test_a_place_rigged_just_ahead_is_handed_over_with_its_marble_and_laid_just_ahead(
		t: TestRunner) -> void:
	var rig := _rigged_walk(true)
	t.check(rig["asked_before"] == 0,
			"the man's place is not asked of the siting before his marble is drawn (%d asks in %.0fs)"
			% [rig["asked_before"], EventDirector.AHEAD_INTERVAL.x - 1.0])
	var siting: FakeWalkSiting = rig["siting"]
	var moved: Array[EventPlan] = rig["moved"]
	t.check(moved.size() == 1 and moved[0].row_id() == "homeless_yeller" and moved[0].is_placed(),
			"once it is drawn he is laid within a look (%d moved)" % moved.size())
	t.check(siting.calls.has("lay_just_ahead") and not siting.calls.has("lay_ahead"),
			"by lay_just_ahead() and never lay_ahead() (%s)" % [siting.calls])
	var director: EventDirector = rig["director"]
	t.check(not moved.is_empty() and director.is_from_her_route(moved[0]),
			"and he joins the day's plan as a place from her route")

## **Without the setting the same place is laid by `lay_ahead()`**, past the streaming band.
func _test_a_place_rigged_without_the_setting_is_laid_past_the_band(t: TestRunner) -> void:
	var rig := _rigged_walk(false)
	var siting: FakeWalkSiting = rig["siting"]
	var moved: Array[EventPlan] = rig["moved"]
	t.check(moved.size() == 1 and moved[0].is_placed(), "it is laid (%d moved)" % moved.size())
	t.check(siting.calls.has("lay_ahead") and not siting.calls.has("lay_just_ahead"),
			"by lay_ahead() and never lay_just_ahead() (%s)" % [siting.calls])

## **Under `--force` nothing is rigged**: the queue is the forced row's alone, so the rig answers no
## marbles and her walk is handed no place to lay.
func _test_nothing_is_rigged_under_force(t: TestRunner) -> void:
	var siting := FakeWalkSiting.new().set_place("homeless_yeller", _her() + Vector2.UP * 500.0)
	var director := EventDirector.new(_street())
	director.use_way_on(FakeWayOn.new())
	director.force("dog_walker", 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	director.start_day(DAY, _no_plans(), rng, DaySpec.DirectorSends.THE_DAYS_ROWS, siting)
	var rigged := director.rig_her_route(["homeless_yeller"] as Array[String], 1, 0, siting, true)
	t.check(rigged.is_empty(), "a forced day rigs no marbles (%s)" % [rigged])
	for _tick in int((EventDirector.ON_HER_WAY_AFTER + 2.0 * EventDirector.AHEAD_INTERVAL.y) / 0.1):
		director.due(0.1, _her(), Vector2.UP * Tuning.WALK_SPEED)
		director.site_what_is_on_her_way(0.1, _her(), Vector2.UP * Tuning.WALK_SPEED)
	t.check(not siting.asked.any(func(plan: EventPlan) -> bool: return plan.row_id() == "homeless_yeller"),
			"and the siting is never asked to lay the man")

## **The copy the director hands out on her route shares its row's body**: a row with no ground of
## its own is offered the sidewalk and the square (`EventDirector._with_ground()`), a copy of the heated
## row, and the copy lies as the row does and stands on its shape. A copy that lost the body (a deep
## copy does, `BodySpec` holding a `GroundShape` no resource can store) has no shape. Rigged on a route here: the loudspeaker mast, whose row names no
## ground, and the car accident.
func _test_the_copy_on_her_route_shares_its_rows_body(t: TestRunner) -> void:
	var director := EventDirector.new(_street())
	director.use_way_on(FakeWayOn.new())
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	director.start_day(DAY, _no_plans(), rng, DaySpec.DirectorSends.THE_DAYS_ROWS)
	var ids: Array[String] = [EventCatalogue.mast().id(), "car_accident"]
	director.rig_her_route(ids, 2)
	for id in ids:
		var routed := director.route_row(id)
		t.check(routed != null, "'%s' is a row of her route's bag" % id)
		if routed == null:
			continue
		t.check(routed.body() == EventCatalogue.by_id(id).body(),
				"the copy of '%s' on her route is the row's own body" % id)
		t.check(routed.ground_shape() == EventCatalogue.by_id(id).ground_shape(),
				"and it stands on the row's own shape")

## **A scene rigs her route's bag** (`start_recipe_route()`, as a task scene's `setup.route_bag`
## does): she is owed the count the scene gives, whatever the bag holds, and the marble the
## scene put in the pre-bag is the first one drawn, before the ordinary marbles.
func _test_a_rigged_route_is_owed_its_count_and_pre_bag(t: TestRunner) -> void:
	var director := EventDirector.new(_street())
	director.use_way_on(FakeWayOn.new())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	director.start_day(7, _no_plans(), rng, DaySpec.DirectorSends.THE_DAYS_ROWS)
	director.start_recipe_route(["cyclist", "cyclist"], ["cat_dash"], 3, 2.0, 0)
	t.check(director.owed() == 3, "the route is owed what the recipe says")
	t.check(director.route_bag().peek() == "cat_dash", "and the pre-bag is drawn first")

## **A walk that sends its own trucks** (`DaySpec.DirectorSends.SENT_AHEAD_ROWS_OF_ITS_PLAN`,
## the escape city's) is owed one marble for each sent-ahead row its plan left unplaced, and
## none for a truck its plan placed or for a row it does not send: what she meets is the plan's
## trucks sent just ahead of her, and nothing else, whatever the day's number. The walk that
## sends nothing is owed none of the same plans, so the count is the setting's and not the
## plans'.
func _test_a_walk_that_sends_its_own_trucks_is_owed_the_ones_its_plan_left_unplaced(
		t: TestRunner) -> void:
	var truck := EventCatalogue.by_id("military_convoy")
	var plans: Array[EventPlan] = [EventPlan.new(truck, Vector2.INF),
			EventPlan.new(truck, Vector2.INF), EventPlan.new(truck, _her() + Vector2.UP * 900.0),
			EventPlan.new(EventCatalogue.by_id("cat_dash"), Vector2.INF)]
	for day: int in [1, Tuning.RUN_LENGTH_DAYS]:
		var sends := _started(day, plans, DaySpec.DirectorSends.SENT_AHEAD_ROWS_OF_ITS_PLAN)
		t.check(sends.owed() == 2,
				"day %d: she is owed the two trucks left unplaced (%d)" % [day, sends.owed()])
		var handed: Array[String] = []
		for _tick in 12:
			var due := sends.due(10.0, _her(), Vector2.UP * Tuning.WALK_SPEED)
			if not due.is_empty():
				var def: EventDef = due[0]
				handed.append(def.id())
		var expected: Array[String] = ["military_convoy", "military_convoy"]
		t.check(handed == expected,
				"day %d: what is sent ahead of her is those trucks and nothing else (%s)"
				% [day, handed])
		var nothing := _started(day, plans, DaySpec.DirectorSends.NOTHING)
		t.check(nothing.owed() == 0, "day %d: a walk that sends nothing is owed none of them" % day)

## A director on the street over `plans`, its day `day` started on a stream of its own as
## `sends` says what it may send.
static func _started(day: int, plans: Array[EventPlan], sends: DaySpec.DirectorSends,
		share := 1.0) -> EventDirector:
	var director := EventDirector.new(_street())
	director.use_way_on(FakeWayOn.new())
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	director.start_day(day, plans, rng, sends, null, 0, share)
	return director

## **The share of the usual wait a walk names is the share of it that passes before the first
## handout** (`DaySpec.handout_wait_share()`, `EventDirector.start_day()`): on one stream, the
## wait a director is handed half of is half the wait of one handed all of it, to a tick.
func _test_a_walk_lets_the_share_of_the_wait_it_names_pass_between_handouts(t: TestRunner) -> void:
	var truck := EventCatalogue.by_id("military_convoy")
	var plans: Array[EventPlan] = [EventPlan.new(truck, Vector2.INF)]
	var waits: Array[float] = []
	for share: float in [1.0, 0.5]:
		var director := _started(DAY, plans, DaySpec.DirectorSends.SENT_AHEAD_ROWS_OF_ITS_PLAN,
				share)
		var waited := 0.0
		while waited < EventDirector.AHEAD_INTERVAL.y + 1.0 \
				and director.due(0.25, _her(), Vector2.UP * Tuning.WALK_SPEED).is_empty():
			waited += 0.25
		waits.append(waited)
	t.check(waits[0] >= EventDirector.AHEAD_INTERVAL.x - 0.25,
			"with all of the usual wait the first handout waits it out (%.2fs)" % waits[0])
	t.check(absf(waits[1] - waits[0] * 0.5) <= 0.5,
			"and with half of it half as long (%.2fs against %.2fs)" % [waits[1], waits[0]])

## **A walk whose spec sends nothing** (`DaySpec.director_sends()`, the escape city's) hands the
## director no route bag, owes nothing, rigs nothing and rolls no sprinkled dog, **whatever its day
## number is**: day 1 is the direct boot's, whose ordinary day rigs two dog walkers among her first
## three handouts, and day 14 is a run's, whose ordinary day can owe the charging dog. The same days
## handed the ordinary setting do owe, so the check is not vacuous.
func _test_a_walk_that_sends_nothing_has_nothing_to_hand_out(t: TestRunner) -> void:
	var escape := DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
	var ordinary_owed := {}
	for day: int in [1, Tuning.RUN_LENGTH_DAYS]:
		ordinary_owed[day] = 0
		for seed_value in 12:
			var ordinary := _walked_director(day, seed_value, DaySpec.for_day(day))
			var sends_nothing := _walked_director(day, seed_value, escape)
			ordinary_owed[day] += 1 if ordinary.owed() > 0 else 0
			t.check(sends_nothing.owed() == 0,
					"the escape city owes the director nothing on day %d (seed %d)" % [day, seed_value])
			t.check(sends_nothing.rig_her_route(["dog_walker"] as Array[String], 3).is_empty(),
					"and has no route bag to rig on day %d" % day)
			var handed: Array = []
			for _tick in 30:
				handed.append_array(sends_nothing.due(10.0, _her(),
						Vector2.UP * Tuning.WALK_SPEED))
			t.check(handed.is_empty(),
					"and sends nothing in a long walk on day %d (seed %d)" % [day, seed_value])
	for day: int in ordinary_owed:
		t.check(int(ordinary_owed[day]) > 0,
				"an ordinary day %d owes her something on some seed, so there was one to refuse (%d)"
				% [day, ordinary_owed[day]])

## A director on the street with no plans, its day `day` started on a stream of `seed_value`, as
## `spec` says what it may send.
static func _walked_director(day: int, seed_value: int, spec: DaySpec) -> EventDirector:
	var director := EventDirector.new(_street())
	director.use_way_on(FakeWayOn.new())
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	director.start_day(day, _no_plans(), rng, spec.director_sends())
	return director

## Walks her on the street past `ON_HER_WAY_AFTER`, rigs the man shouting as the next marble on her
## route (`just_ahead` as given), and walks on, the clock and her walk's looks ticking together a
## tenth of a second a tick, until his place is laid. Answers `siting`, `director`, the plans her walk
## laid (`moved`) and how many asks the siting had in the first `AHEAD_INTERVAL.x - 1` seconds after the
## rig (`asked_before`).
static func _rigged_walk(just_ahead: bool) -> Dictionary:
	var siting := FakeWalkSiting.new().set_place("homeless_yeller", _her() + Vector2.UP * 500.0)
	var director := _director_with_a_siting(_no_plans(), siting)
	_walk_for(director, EventDirector.ON_HER_WAY_AFTER + 1.0)
	director.rig_her_route(["homeless_yeller"] as Array[String], 1, 0, siting, just_ahead)
	var moved: Array[EventPlan] = []
	var asked_before := 0
	var ticks := int(EventDirector.AHEAD_INTERVAL.x - 1.0) * 10
	for tick in int((EventDirector.AHEAD_INTERVAL.y + 3.0) * 10.0):
		director.due(0.1, _her(), Vector2.UP * Tuning.WALK_SPEED)
		moved.append_array(director.site_what_is_on_her_way(0.1, _her(),
				Vector2.UP * Tuning.WALK_SPEED))
		if tick == ticks - 1:
			asked_before = siting.asked.size()
	return {"siting": siting, "director": director, "moved": moved, "asked_before": asked_before}
