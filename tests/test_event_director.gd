extends RefCounted
## `EventDirector`'s siting of the rows it sends ahead of her (`EventDef.is_sent_ahead()`; inbox
## #1460): the dog walker down her own sidewalk toward her, the patrol down the carriageway lane
## that drives toward her, and the convoy in the lane beside her from either end, its first leg
## running past her to the far edge of the next junction box, on a street running north-south and
## on one running east-west; a sent row refused, and asked again, where its first leg starts within
## `EventScheduler.EVENT_SPACING_ANY` of a placed plan or runs through a field a plan keeps clear;
## and a marble of her route sent ahead of her that has no room, which waits for room and lets the
## marbles behind it through (calm-pelican-6).
##
## On a hand-drawn map, one street running the whole length of the map (`_street()`, north-south or
## the same map turned), with plans made by hand: plans and rows are data, built as they are, and
## the director is handed the map alone and moves by the map's navigator, as
## `tests/test_world_passability.gd` hands it. Each siting check owes its row through `force()` (the
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
## The first tile along the street of the junction box the paving checks pave: the next box past her
## the way she does not walk.
const PAVED_BOX_TILE := 42
## Her tile along the street running north-south where the paved box begins between half of
## `Tuning.OUT_OF_SIGHT` and the whole of it past her, beyond where the patrol's leg toward it ends.
const WAY_OUT_TILE := 34

func run(t: TestRunner) -> void:
	_test_the_dog_walker_comes_down_her_sidewalk_toward_her(t)
	for vertical: bool in [true, false]:
		_test_the_patrol_comes_down_the_lane_that_drives_toward_her(t, vertical)
		_test_the_convoy_comes_in_the_lane_beside_her_from_either_end(t, vertical)
		_test_no_leg_where_the_car_would_drive_onto_paving_in_her_sight(t, vertical)
	_test_no_leg_whose_way_out_runs_onto_paving_in_her_sight(t)
	_test_no_leg_where_the_car_would_drive_into_a_closure_in_her_sight(t)
	_test_no_leg_where_the_car_would_drive_off_the_map_in_her_sight(t)
	_test_a_sent_row_keeps_out_of_a_field_kept_clear(t)
	_test_a_sent_row_starts_clear_of_a_placed_plan(t)
	_test_a_sent_row_with_no_room_lets_the_next_marbles_through(t)

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
## `seed_value`.
static func _director(map: CityMap, row: String, plans: Array[EventPlan],
		seed_value := 1) -> EventDirector:
	var director := EventDirector.new(map)
	director.force(row, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	director.start_day(DAY, plans, rng)
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
	t.check(def.id == "dog_walker" and def.comes_down_her_line() and not def.warns_before_it_exists(),
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
## level with the lane its way drives in; its first leg runs past her to the far edge of the next
## junction box; and over the director's streams it comes from either end.
func _test_the_convoy_comes_in_the_lane_beside_her_from_either_end(t: TestRunner,
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
		var end_tile := int(roundf((last.y if vertical else last.x) / TILE))
		var forward := (going.y if vertical else going.x) > 0.0
		var box_edge := Tuning.STREET_WIDTH if forward else 0
		var fine := def.is_warned_in_its_lane() and def.warns_before_it_exists() \
				and is_equal_approx(across, lane) and up_the_road < -half and past_her > 0.0 \
				and posmod(end_tile, CityMap.period()) == box_edge
		if not fine:
			wrong.append("seed %d: %s" % [seed_value, path])
		if going.dot(_walking(vertical)) > 0.0:
			with_her += 1
		else:
			at_her += 1
	t.check(wrong.is_empty(), "on a street running %s, every convoy is warned of in its lane up "
			% name + "the road, out of sight, its leg past her to the far edge of the next box%s" % (
				"" if wrong.is_empty() else ": " + "; ".join(wrong)))
	t.check(with_her > 0 and at_her > 0,
			"and it comes from either end (%d from behind her, %d toward her)" % [with_her, at_her])

## **No car is sent where its drive in her sight would run onto ground no car may be on**: with the
## junction box past her paved (the next box the way she does not walk, tiles 42 to 47 of her street,
## paved by a precinct on the street that crosses there, `CityMap.add_precinct()`: its blocks -1 and 0,
## so it runs through the box from off the map's edge, and a precinct on either street paves the box),
## no patrol or convoy is sited with her six tiles from it, since a car whose leg ended short of the
## box would drive on over it as it left (`EventDeparture.begin()`). On the street unpaved the same
## rows are sited, so the check is not vacuous. With her twenty tiles from the box, further than a
## car leaving is in her sight (`Tuning.OUT_OF_SIGHT`), they are sited again: the refusal reaches
## only as far as that.
func _test_no_leg_where_the_car_would_drive_onto_paving_in_her_sight(t: TestRunner,
		vertical: bool) -> void:
	var name := "north-south" if vertical else "east-west"
	var paved := _street(vertical)
	paved.add_precinct(Vector4i(0 if vertical else 1, 3, -1, 0))
	var further := _turned(HER + Vector2i(0, -14), vertical)
	for row: String in ["police_patrol", "military_convoy"]:
		var unpaved := 0
		var beside := 0
		var away := 0
		for seed_value in range(1, 9):
			if _due(_director(_street(vertical), row, _no_plans(), seed_value), vertical).size() >= 2:
				unpaved += 1
			if _due(_director(paved, row, _no_plans(), seed_value), vertical).size() >= 2:
				beside += 1
			if _due_at(_director(paved, row, _no_plans(), seed_value), further,
					vertical).size() >= 2:
				away += 1
		t.check(unpaved > 0 and beside == 0,
				"on the street running %s, a %s is sited %d of 8 times unpaved and " % [name, row, unpaved]
				+ "%d with the box six tiles past her paved" % beside)
		t.check(away > 0, "and %d of 8 times with her twenty tiles from it" % away)

## **Nor where the leg ends short of the paving and the car's way out runs onto it in her sight**:
## on the street running north-south, with her at `WAY_OUT_TILE`, the paved box (from
## `PAVED_BOX_TILE`, as above) begins further past her than half of `Tuning.OUT_OF_SIGHT` and
## nearer than the whole of it. On the street unpaved the patrol is sited, its leg ending short of
## where the box begins, so the check is about the way out and not the leg. With the box paved none
## is sited: its way out, straight on until it is `Tuning.OUT_OF_SIGHT` from her
## (`EventDeparture.leave()`), would cross the box while she stands there. It is asked of the patrol
## on a street running north-south because only there does a leg end short of a box its way out
## reaches: on a street running east-west the patrol's place, and so its leg past her, reaches past
## the next box, and the convoy's leg always runs on to that box's far edge, from where the box after
## it is further than `Tuning.OUT_OF_SIGHT` from her.
func _test_no_leg_whose_way_out_runs_onto_paving_in_her_sight(t: TestRunner) -> void:
	var paved := _street()
	paved.add_precinct(Vector4i(0, 3, -1, 0))
	var her := _turned(Vector2i(HER.x, WAY_OUT_TILE), true)
	var box_begins := float(PAVED_BOX_TILE * TILE)
	var from_her := box_begins - her.y
	t.check(from_her > Tuning.OUT_OF_SIGHT * 0.5 and from_her < Tuning.OUT_OF_SIGHT,
			"the box begins %.0fpx past her" % from_her)
	var ends_short := 0
	var ends_past := 0
	var sited := 0
	for seed_value in range(1, 9):
		var unpaved := _due_at(_director(_street(), "police_patrol", _no_plans(), seed_value), her)
		if unpaved.size() >= 2:
			var leg := unpaved[1] as PackedVector2Array
			if leg[leg.size() - 1].y < box_begins:
				ends_short += 1
			else:
				ends_past += 1
		if _due_at(_director(paved, "police_patrol", _no_plans(), seed_value), her).size() >= 2:
			sited += 1
	t.check(ends_short > 0 and ends_past == 0,
			"unpaved, a patrol is sited %d of 8 times, its leg ending short of the box " % ends_short
			+ "(%d past it)" % ends_past)
	t.check(sited == 0, "and paved, %d of 8 times, its way out in her sight onto the box" % sited)

## **Nor where it would drive into a closed street in her sight**: with the carriageway closed four
## tiles past her (`CityMap.closed_tiles`, which a car is stopped by, `Mover.vehicle()`), a car would
## stop at the closure and turn onto a way out in her view, so no patrol or convoy is sited.
func _test_no_leg_where_the_car_would_drive_into_a_closure_in_her_sight(t: TestRunner) -> void:
	var map := _street()
	var closed := {}
	for x in range(Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH):
		closed[Vector2i(x, HER.y + 4)] = true
	map.closed_tiles = closed
	for row: String in ["police_patrol", "military_convoy"]:
		var sited := 0
		for seed_value in range(1, 9):
			if _due(_director(map, row, _no_plans(), seed_value)).size() >= 2:
				sited += 1
		t.check(sited == 0, "with the carriageway closed four tiles past her, no %s is sited (%d of 8)"
				% [row, sited])

## **Nor where it would drive off the map in her sight**: six tiles from the map's south end,
## walking north, a car driving south would reach the end and turn onto a way out in her view, so no
## patrol or convoy is sited.
func _test_no_leg_where_the_car_would_drive_off_the_map_in_her_sight(t: TestRunner) -> void:
	var map := _street()
	var her := _turned(Vector2i(HER.x, LENGTH - 6), true)
	for row: String in ["police_patrol", "military_convoy"]:
		var sited := 0
		for seed_value in range(1, 9):
			if _due_at(_director(map, row, _no_plans(), seed_value), her, true).size() >= 2:
				sited += 1
		t.check(sited == 0, "six tiles from the map's end, no %s is sited (%d of 8)" % [row, sited])

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
	var lethal := EventDef.new()
	lethal.id = "lethal_by_hand"
	lethal.hard_fail = true
	lethal.inner_radius = 30.0
	lethal.outer_radius = 600.0
	var blocking := EventPlan.new(lethal, _her() + Vector2(-1.5 * TILE, 0.0))
	var plans: Array[EventPlan] = [blocking]
	for _i in 12:
		plans.append(EventPlan.new(EventCatalogue.by_id("cat_dash"), Vector2.INF))
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	director.start_day(DAY, plans, rng)
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
		if (due[0] as EventDef).id == "police_patrol":
			patrols_came += 1
	t.check(patrols_came >= 2, "and once there is room the patrols that waited come (%d)" % patrols_came)
	t.check(closest >= EventDirector.AHEAD_INTERVAL.x - step,
			"and nothing is handed out closer to the last than the clock's shortest wait, %.1fs "
			% EventDirector.AHEAD_INTERVAL.x + "(the closest two %.1fs apart)" % closest)
