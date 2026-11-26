extends RefCounted
## Measurement probe for grassy-beaver's day two (the dead end met early, and day 1's walk left
## open): on each city, day 1's tutorial route (`TutorialRoute.for_city()`), then day 2 planned
## the way its dawn plans it after she settled in the tutorial park (the park handed to
## `CityMap.set_spent_calm()` and the map repainted, the tree grown with no tutorial route, the
## closures, the holds and the seals planned with the walk handed in as `City` and `DayPlanner`
## hand it, then the dawn's rows on what stands, every unit drawn, `GameDawn`), and per city:
##
## - **the dead ends at the doorstep**: the side streets at the doorstep street's two junctions,
##   day 1's walk aside, whose **both sidewalks** are shut, the player's own words for a dead end
##   *(curly-moose #819: "a deadend / both sidewalks are blocked")*: by the seals' bodies alone, or
##   by a road closure. A thinned soft pair leaves one sidewalk open and a car accident's two cars
##   leave its gaps, so neither counts. Each sidewalk is asked as the day's own rules ask one
##   (`RouteSidewalkRule.closes_a_walked_sidewalk_band()`), past each body's pieces where they
##   stand and the ground its catch shuts (`WalkGround.held_by()`). A precinct's paved street has
##   no sidewalk band to shut, so it is never counted;
## - **the walk left open**: how many of the route's lesson streets are off day 2's tree, how many
##   seals and closures stand on them without the walk handed in, and how many with it (zero);
## - **the rows on the walk**: the dawn's rows standing on a lesson street, by role, and the lesson
##   streets whose both sidewalks the day's bodies shut, rows and seals together. The dawn is handed
##   the walk as `DayPlanner` hands it (`DawnContext.use_the_walk_left_open()`), so its rules keep
##   one sidewalk of each lesson street open (`OneSidewalkOpenRule`); `HAND_THE_WALK_TO_THE_ROWS`
##   false plans the rows without it, for the count the rule answers;
## - **the streets of her routes** shut the same way, for comparison, since the same rule keeps one
##   sidewalk of each open;
## - whether the tutorial park was taken off day 2's tree (`CityMap.shut_calm()`).
##
## Not a suite: it prints rather than asserts. Run by name:
##
##     tools/test.sh probes/grassy_beaver_day_two.gd      (prints DAY_TWO lines)

const FIRST_SEED := 1
const LAST_SEED := 30
const DAY := 2
## Whether the dawn's rows are handed the walk left open, as the game hands it.
const HAND_THE_WALK_TO_THE_ROWS := true

var _cities := 0
var _no_route := 0
var _park_shut := 0
var _dead_ends := 0
var _with_a_dead_end := 0
var _fewest_dead_ends := -1
var _dead_ends_by_closure := 0
var _opened := 0
var _sealed_before := 0
var _closed_before := 0
var _left_on_the_walk := 0
var _rows_on_the_walk := 0
var _cities_with_rows_on_the_walk := 0
var _rows_by_role := {}
var _shut_lesson_streets := 0
var _shut_off_the_tree := 0
var _cities_with_the_walk_shut := 0
var _route_streets := 0
var _shut_route_streets := 0

func run(t: TestRunner) -> void:
	var spec := DaySpec.for_day(DAY)
	for seed_value in range(FIRST_SEED, LAST_SEED + 1):
		_measure(seed_value, spec)
	print("DAY_TWO seeds %d-%d | cities with a route %d, none %d | park off day 2's tree %d"
			% [FIRST_SEED, LAST_SEED, _cities, _no_route, _park_shut])
	print("DAY_TWO dead ends at the doorstep (both sidewalks shut) | cities with one %d of %d,"
			% [_with_a_dead_end, _cities]
			+ " with none %d | fewest in a city %d | in all %d, of them by a closure %d"
			% [_cities - _with_a_dead_end, _fewest_dead_ends, _dead_ends, _dead_ends_by_closure])
	print("DAY_TWO lesson streets off day 2's tree %d | sealed without the walk %d, closed %d"
			% [_opened, _sealed_before, _closed_before]
			+ " | seals or closures on it with the walk %d" % _left_on_the_walk)
	print("DAY_TWO rows on the walk %d, in %d cities | by role %s"
			% [_rows_on_the_walk, _cities_with_rows_on_the_walk, _rows_by_role])
	print("DAY_TWO lesson streets with both sidewalks shut %d (off the tree %d), in %d cities"
			% [_shut_lesson_streets, _shut_off_the_tree, _cities_with_the_walk_shut])
	print("DAY_TWO streets of her routes with both sidewalks shut %d of %d"
			% [_shut_route_streets, _route_streets])
	t.check(true, "a probe asserts nothing")

func _measure(seed_value: int, spec: DaySpec) -> void:
	var map := CityGenerator.generate(seed_value)
	var route := TutorialRoute.for_city(map)
	if route == null:
		_no_route += 1
		return
	_cities += 1
	var spent: Array[Vector2i] = [route.park_block()]
	map.set_spent_calm(spent)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), DAY)
	map.repaint(state)
	if map.shut_calm().has(route.park_block()):
		_park_shut += 1
	var tree := RouteTree.for_day(map, DAY, null)
	var walk := {}
	for segment in route.lesson_streets():
		walk[segment.key()] = true
		if not tree.is_on_the_tree(segment.key()):
			_opened += 1
	# Without the walk handed in, for the counts it changes.
	var unspared := _streets_of(map, SealPlanner.plan_day(map, spec, tree, _rng(map, "seals"),
			{}, null, null, null))
	for key: Vector3i in walk:
		if unspared.has(key):
			_sealed_before += 1
	for closure in ClosurePlanner.plan_day(map, spec, _rng(map, "closures"), tree):
		if walk.has(closure.street_key()):
			_closed_before += 1
	# The day as the game plans it, the walk handed in (`City._close_streets()`,
	# `DayPlanner._plan_a_day()`).
	var region_plan := RegionPlanner.plan_day(map, spec, tree)
	var closures := ClosurePlanner.plan_day(map, spec, _rng(map, "closures"), tree, region_plan,
			null, route)
	for closure in closures:
		if walk.has(closure.street_key()):
			_left_on_the_walk += 1
	map.close_streets(closures)
	map.clear_day_holds()
	for closure in closures:
		map.hold_segment(closure.street_key(), HeldStreets.Why.CLOSURE)
	if spec.keeps_the_home_streets_clear():
		for segment in map.street_network().around_blocks(
				Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
			map.hold_segment(segment.key(), HeldStreets.Why.HOME)
	var seals := SealPlanner.plan_day(map, spec, tree, _rng(map, "seals"), {}, map.held_streets(),
			null, route)
	for seal in seals:
		seal.stand_as_a_seal()
	var sealed := _streets_of(map, seals)
	for key: Vector3i in walk:
		if sealed.has(key):
			_left_on_the_walk += 1
	var settled: Array[Vector2i] = [route.park_block()]
	var target := ResistanceDirector.target_ground(map, DAY, region_plan)
	var handed := route if HAND_THE_WALK_TO_THE_ROWS else null
	var rows := GameDawn.of(spec, _rng(map, "dawn"), map).on(tree).standing(seals) \
			.calm(CalmAreas.of(map, settled, DAY, target)).walk_left_open(handed).plan().placements()
	var ground := WalkGround.new(map)
	# The dead ends at the doorstep, by the seals and the closures alone.
	var home := ClosurePlanner.home_street(map)
	var here := 0
	for junction: Vector2i in [home.a, home.b]:
		for arm in map.street_network().at_junction(junction):
			if arm.key() == home.key() or walk.has(arm.key()) or not map.has_street(arm.key()):
				continue
			if _both_sidewalks_shut(map, ground, arm, seals):
				here += 1
				if _closed_by(closures, arm):
					_dead_ends_by_closure += 1
	_dead_ends += here
	if here > 0:
		_with_a_dead_end += 1
	_fewest_dead_ends = here if _fewest_dead_ends < 0 else mini(_fewest_dead_ends, here)
	# The rows on the walk, and the lesson streets the day's bodies shut.
	var on_the_walk := 0
	for plan in rows:
		if not plan.is_placed():
			continue
		var segment := map.street_network().segment_containing(map.world_to_tile(plan.placed_at()))
		if segment == null or not walk.has(segment.key()):
			continue
		on_the_walk += 1
		var role: String = GameEnums.BlockerRole.keys()[plan.role()]
		var key := "%s %s" % [role, plan.row_id()]
		_rows_by_role[key] = int(_rows_by_role.get(key, 0)) + 1
	_rows_on_the_walk += on_the_walk
	if on_the_walk > 0:
		_cities_with_rows_on_the_walk += 1
	var everything: Array[EventPlan] = []
	everything.append_array(seals)
	everything.append_array(rows)
	var shut := 0
	for segment in route.lesson_streets():
		if _both_sidewalks_shut(map, ground, segment, everything):
			shut += 1
			if not tree.is_on_the_tree(segment.key()):
				_shut_off_the_tree += 1
	_shut_lesson_streets += shut
	if shut > 0:
		_cities_with_the_walk_shut += 1
	# The streets of her routes, which the day's rules keep one sidewalk of open, for comparison.
	var corridor := Corridor.of(tree)
	for segment in map.street_network().segments():
		if not map.has_street(segment.key()) or walk.has(segment.key()) \
				or corridor.view_of(segment) != PlacementView.View.ON_THE_ROUTE:
			continue
		_route_streets += 1
		if _both_sidewalks_shut(map, ground, segment, everything):
			_shut_route_streets += 1
	print("DAY_TWO seed %d | dead ends at the doorstep %d | lesson streets off the tree %d"
			% [seed_value, here, _off_the_tree(route, tree)]
			+ " | rows on the walk %d | lesson streets shut %d" % [on_the_walk, shut])

## Whether neither sidewalk of `street` can be walked junction to junction past the bodies of
## `plans` and the closed ground (`RouteSidewalkRule.closes_a_walked_sidewalk_band()`).
static func _both_sidewalks_shut(map: CityMap, ground: WalkGround, street: StreetNetwork.Segment,
		plans: Array[EventPlan]) -> bool:
	var rect := street.tile_rect()
	var bodies: Array = []
	var near := map.tile_rect_to_world(rect).grow(Tuning.PLAYER_BODY_RADIUS)
	for plan in plans:
		if not plan.is_placed() or plan.row().moves():
			continue
		for solid in ground.held_by(plan):
			if not solid.reaches(near, 0.0):
				continue
			for disc in solid.discs():
				bodies.append(disc)
	for band in Corridor.sidewalk_bands(rect, street.horizontal):
		if not RouteSidewalkRule.closes_a_walked_sidewalk_band(map, band, street.horizontal,
				bodies):
			return false
	return true

static func _closed_by(closures: Array[RoadClosure], street: StreetNetwork.Segment) -> bool:
	for closure in closures:
		if closure.street_key() == street.key():
			return true
	return false

static func _off_the_tree(route: TutorialRoute, tree: RouteTree) -> int:
	var count := 0
	for segment in route.lesson_streets():
		if not tree.is_on_the_tree(segment.key()):
			count += 1
	return count

static func _rng(map: CityMap, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%d" % [stream, map.city_seed(), DAY])
	return rng

## The streets the plans stand on, by segment key; an alley mouth stands on none.
static func _streets_of(map: CityMap, plans: Array[EventPlan]) -> Dictionary:
	var found := {}
	for plan in plans:
		var segment := map.street_network().segment_containing(map.world_to_tile(plan.placed_at()))
		if segment:
			found[segment.key()] = true
	return found
