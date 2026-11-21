extends RefCounted
## `EventDirector`'s siting of the rows it sends ahead of her (`EventDef.is_sent_ahead()`; inbox
## #1460 in silky-lemur): the dog walker down her own sidewalk toward her, the patrol down the
## carriageway lane that drives toward her, and the convoy in the lane beside her coming toward
## her, its first leg
## running past her to the far edge of the next junction box, on a street running north-south and
## on one running east-west; a car's first leg sent only where the day's way on says a car may drive
## it and go on from its end; a sent row refused, and asked again, where its first leg starts within
## `EventScheduler.EVENT_SPACING_ANY` of a placed plan or runs through a field a plan keeps clear;
## and a marble of her route sent ahead of her that has no room, which waits for room and lets the
## marbles behind it through (calm-pelican-6); and its looks at what her walk lays (`site_what_is_on_her_way()`),
## handed a stand-in for the day's siting (`FakeWalkSiting`): a look asks each plan owed once,
## between one `begin_look()` and one `end_look()`, no oftener than once a walking second; a placed plan behind her
## for three walking seconds is asked again and one that has been in the world never; the next crew waits
## while one is laid and not yet real; and a row a mark rigs (`rig_the_next_draw()`) is laid at the
## next look by `WalkSiting.lay_just_ahead()`, never `lay_ahead()`, and joins the day's plan as a
## place from her route (`is_from_her_route()`).
##
## On a hand-drawn map, one street running the whole length of the map (`_street()`, north-south or
## the same map turned), with plans made by hand: plans and rows are data, built as they are, and
## the director is handed the map alone and moves by the map's navigator, as
## `tests/test_world_passability.gd` hands it. It is handed a fake way on (`FakeWayOn`), whose
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
## (`drives_clear()`) and whether it has a next leg from where it stands (`next_leg()`), recording
## what it was asked and the day's rule it was told (`use_the_days_rule()`).
class FakeWayOn extends WayOn:
	var drives := true
	var goes_on := true
	var asked_to_drive: Array[PackedVector2Array] = []
	var asked_on_from: Array[Array] = []
	var told_rule := Callable()

	func _init() -> void:
		super(null, null, null)

	## Overrides WayOn.use_the_days_rule.
	func use_the_days_rule(may_take: Callable) -> void:
		told_rule = may_take

	## Overrides WayOn.drives_clear.
	func drives_clear(_row: EventDef, path: PackedVector2Array) -> bool:
		asked_to_drive.append(path)
		return drives

	## Overrides WayOn.next_leg.
	func next_leg(_row: EventDef, at: Vector2, heading: Vector2,
			_her: Vector2) -> PackedVector2Array:
		asked_on_from.append([at, heading])
		return PackedVector2Array([at, at + heading * TILE]) if goes_on else PackedVector2Array()

func run(t: TestRunner) -> void:
	_test_the_dog_walker_comes_down_her_sidewalk_toward_her(t)
	for vertical: bool in [true, false]:
		_test_the_patrol_comes_down_the_lane_that_drives_toward_her(t, vertical)
		_test_the_convoy_comes_in_the_lane_beside_her_toward_her(t, vertical)
	_test_a_car_is_sent_only_on_a_leg_it_may_drive_and_go_on_from(t)
	_test_a_sent_row_keeps_out_of_a_field_kept_clear(t)
	_test_a_further_leg_keeps_out_of_a_field_kept_clear_and_a_doors_ground(t)
	_test_a_sent_row_starts_clear_of_a_placed_plan(t)
	_test_a_sent_row_with_no_room_lets_the_next_marbles_through(t)
	_test_a_look_asks_each_owed_plan_once_between_one_begin_and_one_end(t)
	_test_a_placed_plan_behind_her_is_asked_again_and_one_that_was_live_never(t)
	_test_the_next_crew_waits_while_one_is_laid_and_not_yet_real(t)
	_test_a_row_a_mark_rigs_is_laid_just_ahead_at_the_next_look(t)

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
## junction box; and over the director's streams it always comes toward her, never from behind
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
	t.check(with_her == 0 and at_her > 0,
			"and it comes toward her (%d toward her, %d from behind her)" % [at_her, with_her])

## **A car's first leg is sent only where the day's way on says a car may drive it and go on from its
## end** (`EventDirector.leg_in_the_lane()`): for the patrol and the convoy, a way on that refuses
## every leg (`drives_clear()` false) sites none, one with no next leg from any leg's end
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

## A lethal row standing on the dog walker's way keeps its field clear: the dog walker is refused
## while the plan stands, and handed out at the next ask once it is spent.
func _test_a_sent_row_keeps_out_of_a_field_kept_clear(t: TestRunner) -> void:
	var map := _street()
	var lethal := EventDef.new()
	lethal.id = "lethal_by_hand"
	lethal.hard_fail = true
	lethal.use_field(lethal.field().holding_to(30.0).reaching(120.0))
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
	var lethal := EventDef.new()
	lethal.id = "lethal_by_hand"
	lethal.hard_fail = true
	lethal.use_field(lethal.field().holding_to(30.0).reaching(120.0))
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
	var lethal := EventDef.new()
	lethal.id = "lethal_by_hand"
	lethal.hard_fail = true
	lethal.use_field(lethal.field().holding_to(30.0).reaching(600.0))
	var blocking := EventPlan.new(lethal, _her() + Vector2(-1.5 * TILE, 0.0))
	var plans: Array[EventPlan] = [blocking]
	for _i in 12:
		plans.append(EventPlan.new(EventCatalogue.by_id("cat_dash"), Vector2.INF))
	var director := EventDirector.new(map)
	director.use_way_on(FakeWayOn.new())
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
	director.start_day(DAY, plans, rng, siting)
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

## **A row a mark rigs is laid just ahead of her at the next look**: rigged once she has walked past
## `EventDirector.ON_HER_WAY_AFTER`, the man shouting is asked of `lay_just_ahead()` and never of
## `lay_ahead()`, is laid within a look, and is a place from her route, which joins the day's plan
## when first laid.
func _test_a_row_a_mark_rigs_is_laid_just_ahead_at_the_next_look(t: TestRunner) -> void:
	var siting := FakeWalkSiting.new().set_place("homeless_yeller", _her() + Vector2.UP * 500.0)
	var director := _director_with_a_siting([] as Array[EventPlan], siting)
	_walk_for(director, EventDirector.ON_HER_WAY_AFTER + 1.0)
	director.rig_the_next_draw([EventCatalogue.by_id("homeless_yeller")] as Array[EventDef], siting)
	var moved := _walk_for(director, EventDirector.ON_HER_WAY_LOOK + 0.2)
	t.check(moved.size() == 1 and moved[0].row_id() == "homeless_yeller" and moved[0].is_placed(),
			"the man is laid within a look of the rig (%d moved)" % moved.size())
	t.check(siting.calls.has("lay_just_ahead") and not siting.calls.has("lay_ahead"),
			"by lay_just_ahead() and never lay_ahead() (%s)" % [siting.calls])
	t.check(not moved.is_empty() and director.is_from_her_route(moved[0]),
			"and he joins the day's plan as a place from her route")
