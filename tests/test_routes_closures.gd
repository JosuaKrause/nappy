extends RefCounted
## Road closures and the day-level route invariant: at least two distinct routes to at least two
## distinct calm areas, "distinct" meaning sharing no street -- stated once here and enforced in
## `ClosurePlanner`. This is the suite that has to be right, because the failure it guards against
## is invisible until it ruins somebody's run: a set of closures that leaves the player one way to
## one park -- or no way at all -- looks exactly like a normal morning until they have walked across
## the city and found the barrier.
##
## Split from `tests/test_routes.gd` under M125, "the test suite is slow again" -- this half is
## every check that plans an actual day of closures (`ClosurePlanner.plan_day`) and the fallen-tree
## rule that rides on top of it; `test_routes_lattice.gd` keeps the open lattice's own shape and
## `test_routes_kerb_tint.gd` keeps the one test that needs a real scene tree.

## Enough seeds to catch a layout that only goes wrong in one arrangement.
##
## **Twelve is the count `_test_every_planned_day_keeps_the_invariant` needs and it does not
## shrink.** That check is the reason this file exists -- a day that leaves nowhere to walk to is
## unwinnable and invisible until somebody has crossed the city -- and it is a property of a
## *layout* against a *plan*, so a seed is a genuinely new question rather than the same question
## asked again. It is the minutes this suite is worth spending.
##
## Nothing else here is stated over layouts that way, and the loops that are not say so in their
## own docstrings and use fewer. A sweep that wants all twelve takes `_maps`; one that wants a
## handful slices it.
const SEEDS := 12
## How many maps the sweeps that are about a *rule* rather than a *layout* walk. Six is a floor
## with room in it for the proportions those checks assert, and half the wall clock of twelve.
const RULE_SEEDS := 6
const BASE_SEED := 5150

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 13))
	_test_every_planned_day_keeps_the_invariant(t)
	_test_the_home_street_is_never_closed(t)
	_test_closures_are_deterministic(t)
	_test_closure_counts_follow_the_act(t)
	_test_a_closed_street_is_out_of_the_network(t)
	_test_most_of_a_closed_streets_ground_stays_closed(t)
	_test_a_mid_segment_opening_stays_reachable_from_its_own_side(t)
	_test_calm_ground_is_still_walkable_to(t)
	_test_closures_land_where_a_wall_belongs(t)
	_test_a_closure_never_lands_on_a_calm_areas_own_access(t)
	_test_a_wall_off_the_corridor_never_fails_the_invariant(t)
	_test_a_fallen_tree_only_falls_where_a_tree_stood(t)
	_test_a_day_with_no_tree_lined_street_still_closes_its_quota(t)


## The whole point. Every seed, every day, after the planner has taken what it wants.
func _test_every_planned_day_keeps_the_invariant(t) -> void:
	for map in _maps:
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var closures := _plan(map, day)
			var home := ClosurePlanner.home_street(map)
			var reachable := 0
			var closed := map.blocked_segments(_closed_set(closures))
			for area in ClosurePlanner.calm_areas(map):
				if StreetNetwork.route_count(home, area.access, closed, 1) >= 1:
					reachable += 1
			t.check(reachable >= Tuning.MIN_CALM_AREAS_REACHABLE,
					"seed %d day %d: %d calm areas can still be walked to, need %d"
					% [map.seed_used, day, reachable, Tuning.MIN_CALM_AREAS_REACHABLE])

## docs/CITY.md's oldest exemption: the home is a notch in a block with one exit, so sealing
## the street outside it seals the player in however well connected the rest of the city is.
func _test_the_home_street_is_never_closed(t) -> void:
	for map in _maps:
		var home := ClosurePlanner.home_street(map)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			for closure in _plan(map, day):
				t.check(closure.segment.key() != home.key(),
						"seed %d day %d does not shut the street outside the front door"
						% [map.seed_used, day])

## A run is learnable or it is nothing: the same seed and day must shut the same streets.
##
## **Four maps, three days, and the two calls have to be uncached** — determinism is a property of
## `ClosurePlanner.plan_day` repeating itself, so this is the one caller that must pay for two real
## plans of everything it asks about. That doubling is what sizes it: a planner that consumed its
## RNG differently on a second call would differ on the first map and the first day, and what more
## maps buy is the chance that some *layout* makes it non-deterministic where another does not —
## which is not a thing a seeded RNG can do. Four rather than one so a single unlucky city cannot
## be the whole evidence.
func _test_closures_are_deterministic(t) -> void:
	for map: CityMap in _maps.slice(0, 4):
		for day in [1, 7, 14]:
			var first := _plan_uncached(map, day)
			var second := _plan_uncached(map, day)
			t.check(first.size() == second.size(),
					"seed %d day %d shuts the same number of streets twice"
					% [map.seed_used, day])
			for i in mini(first.size(), second.size()):
				t.check(first[i].segment.key() == second[i].segment.key()
						and first[i].kind == second[i].kind,
						"seed %d day %d shuts the same streets in the same way"
						% [map.seed_used, day])

## The count is the act's, unless the invariant would not let the planner have that many —
## which is a floor it may fall short of, never a ceiling it may exceed.
func _test_closure_counts_follow_the_act(t) -> void:
	for map in _maps:
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var closures := _plan(map, day)
			t.check(closures.size() <= Tuning.closures_for_day(day),
					"seed %d day %d shuts at most the act's %d streets"
					% [map.seed_used, day, Tuning.closures_for_day(day)])
			for closure in closures:
				t.check(day >= int(RoadClosure.KINDS[closure.kind]["first_day"]),
						"seed %d day %d: %s cannot happen yet"
						% [map.seed_used, day, RoadClosure.display_name(closure.kind)])

## Both mouths always come out, and nothing a closure marks closed ever stops being walkable —
## `close_streets` narrows *how much* of a street is unreachable, never whether the ground itself
## is still there.
func _test_a_closed_street_is_out_of_the_network(t) -> void:
	var map := _maps[0]
	var closures := _plan(map, 12)
	map.close_streets(closures)
	t.check(not closures.is_empty(), "act IV shuts something")
	for closure in closures:
		for at_a in [true, false]:
			for tile in map.rect_tiles(closure.segment.mouth_rect(at_a)):
				t.check(map.is_closed(tile), "the mouth tile %s of a closed street is closed" % tile)
		for tile in closure.tiles(map):
			if map.is_closed(tile):
				t.check(not map.is_open(tile), "and is not open, though it is still walkable")
			t.check(map.is_walkable(tile),
					"a closure never moves a walkable tile — it only shuts it")
	map.closed_tiles.clear()

## How much of a closed street's own ground stays genuinely unreachable, on one (map, day) rather
## than the sweep below: a single street can go either way, since which of its cells sit beside an
## alley or a courtyard archway is a fact about that one street, not about closures in general —
## see `_test_a_mid_segment_opening_stays_reachable_from_its_own_side` for the bypass itself. Only
## the sweep's aggregate is the thing this milestone promises: most of a closed street's ground
## stays closed, and a bypass is the exception it exists to let through, not the rule.
##
## Measured over every seed and every day this suite already plans (the loop below costs nothing
## `_plan`'s cache has not already paid for): 168 (map, day) pairs, aggregate ratio 0.81 — a floor
## with room under it, not the number itself, because the aggregate moves with which candidates
## `RouteTree.for_day` leaves off the tree and is not the milestone's own promise.
func _test_most_of_a_closed_streets_ground_stays_closed(t) -> void:
	var sum_closed := 0
	var sum_total := 0
	for map in _maps:
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var closures := _plan(map, day)
			map.close_streets(closures)
			for closure in closures:
				for tile in closure.tiles(map):
					sum_total += 1
					if map.is_closed(tile):
						sum_closed += 1
			map.closed_tiles.clear()
	t.check(float(sum_closed) / maxf(1.0, float(sum_total)) > 0.75,
			"most of a closed street's own ground is still closed, aggregated (%d of %d tiles)"
			% [sum_closed, sum_total])

## The bypass itself, found on real generated seeds rather than engineered by hand — the full
## `StreetNetwork.Segment` lattice a `RoadClosure` needs only exists at the generated city's own
## scale. Independent of `close_streets` and of home: given a segment whose side opens onto
## walkable ground partway along it (an alley mouth or a courtyard archway), barricading both of
## that segment's mouths still leaves the street tile beside the opening in the same component as
## the opening — the exact fact `CityMap.close_streets` relies on to leave that tile out of
## `closed_tiles`.
## Capped per seed rather than exhaustive: a park's every bordering street qualifies as an
## opening, so an uncapped scan floods dozens of times per city for a fact the first handful
## already establish.
const _OPENINGS_PER_SEED := 6

func _test_a_mid_segment_opening_stays_reachable_from_its_own_side(t) -> void:
	var openings := 0
	for map in _maps:
		var grid := ReachabilityGrid.build(map)
		var found_this_seed := 0
		for segment in StreetNetwork.segments():
			if found_this_seed >= _OPENINGS_PER_SEED:
				break
			if not map.has_street(segment.key()):
				continue
			var found := _mid_segment_opening(map, segment)
			if found.is_empty():
				continue
			openings += 1
			found_this_seed += 1
			var opening: Vector2i = found[0]
			var street_side: Vector2i = found[1]
			var barrier := {}
			for at_a in [true, false]:
				for tile in map.rect_tiles(segment.mouth_rect(at_a)):
					barrier[tile] = true
			var reached := grid.flood([opening], barrier)
			t.check(grid.reaches(street_side, barrier, reached),
					"seed %d: %s stays reachable from the opening at %s beside it, though both "
					% [map.seed_used, street_side, opening]
					+ "mouths of %s are barricaded" % segment.key())
	t.check(openings > 0,
			"some generated street has a mid-segment opening to test (%d found)" % openings)

## A tile strictly between `segment`'s two mouths whose side opens onto walkable ground one step
## into the block — normally a building frontage, so a walkable tile there is an alley mouth or a
## courtyard archway landing mid-street. Returns `[the opening, the street tile beside it]`, or an
## empty array where the street has no such side.
func _mid_segment_opening(map: CityMap, segment: StreetNetwork.Segment) -> Array:
	var rect := segment.tile_rect()
	if segment.horizontal:
		for x in range(rect.position.x + 1, rect.end.x - 1):
			if map.is_walkable(Vector2i(x, rect.position.y - 1)):
				return [Vector2i(x, rect.position.y - 1), Vector2i(x, rect.position.y)]
			if map.is_walkable(Vector2i(x, rect.end.y)):
				return [Vector2i(x, rect.end.y), Vector2i(x, rect.end.y - 1)]
	else:
		for y in range(rect.position.y + 1, rect.end.y - 1):
			if map.is_walkable(Vector2i(rect.position.x - 1, y)):
				return [Vector2i(rect.position.x - 1, y), Vector2i(rect.position.x, y)]
			if map.is_walkable(Vector2i(rect.end.x, y)):
				return [Vector2i(rect.end.x, y), Vector2i(rect.end.x - 1, y)]
	return []

## The tile-level version of the promise, which is what the player actually experiences:
## with today's streets shut, walking from the doorstep still reaches calm ground.
func _test_calm_ground_is_still_walkable_to(t) -> void:
	for map in _maps:
		for day in [1, 6, 11, 14]:
			map.close_streets(_plan(map, day))
			var reached := map.walk_field(
					map.world_to_tile(map.doorstep_world_position()), map.closed_tiles)
			var found := false
			for tile in map.calm_tiles():
				if map.reaches(reached, tile):
					found = true
					break
			t.check(found, "seed %d day %d: calm ground can still be walked to"
					% [map.seed_used, day])
			map.closed_tiles.clear()

## A closure is a **wall**, so it is placed off the day's corridor and preferentially on a turning
## off it. *(M50 step 2: "a road block becomes guidance and is not a hindrance. It flips its
## role.")*
##
## Two assertions and they are deliberately of different strengths, because the two halves of the
## rule are of different strengths. **Never on the corridor** is absolute — a wall across the route
## is not a worse wall, it is the opposite of one — and it is what lets the rest of the day be
## planned against a tree that is still walkable once the barriers are up. **On the rim** is a
## preference, `CLOSURE_WALL_BIAS`, so it is asserted as a proportion over a run's worth of days.
##
## This test used to say the opposite in both halves — *"%d of %d closures landed on a street the
## player would have used"* — and it passed for thirty-four milestones while doing so. It is worth
## keeping that in view: the assertion was not wrong then and is not right now for any reason a
## test could have found. The design changed, and a test that encodes a design has to be read as
## one of the places the design is written down.
##
## **`RULE_SEEDS` maps, every day of each.** Both halves are proportions over closures, so what
## sizes this is the number of *closures* rather than the number of cities: six maps through
## fourteen days is upwards of two hundred of them, which is a wide enough sample for bounds set at
## 0.5 and at 0.15/0.7 that noise cannot reach either. The days stay whole because the act decides
## how many streets a day shuts, so sampling days would sample the proportion unevenly. The
## absolute half — never on the corridor — is asked once per closure either way.
func _test_closures_land_where_a_wall_belongs(t) -> void:
	var on_the_rim := 0
	var in_a_gap := 0
	var gaps := 0
	var total := 0
	for map: CityMap in _maps.slice(0, RULE_SEEDS):
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			# Today's city before today's corridor: which blocks are calm is what the tree grows
			# from, and a repaint moves them. Growing one against yesterday's paint is a tree the
			# planner has never seen, which is what the first version of this test did.
			var tree := _todays_tree(map, day)
			var rim := {}
			for key in tree.rim():
				rim[key] = true
			var gap := {}
			for key in tree.gaps():
				gap[key] = true
			gaps += gap.size()
			for closure in _plan(map, day):
				total += 1
				t.check(not tree.is_on_the_tree(closure.segment.key()),
						"seed %d day %d: the closure at %s is off the corridor"
						% [map.seed_used, day, closure.segment.key()])
				if rim.has(closure.segment.key()):
					on_the_rim += 1
				if gap.has(closure.segment.key()):
					in_a_gap += 1
	t.check(total > 0, "the planner shuts streets at all (%d over %d seeds)" % [total, SEEDS])
	# The rim is a minority of the off-tree lattice — measured at about a third of it — so an
	# unweighted planner would land there about a third of the time. Half is a floor with room in
	# it rather than a measurement, which is the same shape the old assertion had.
	t.check(float(on_the_rim) / maxf(1.0, float(total)) > 0.5,
			"%d of %d closures landed on a turning off the corridor" % [on_the_rim, total])

	# **A gap gets the impassable half of *"wall or event"*, and the quota is what keeps it a
	# "sometimes".** *(M55, playtest 17 finding 2.)* `CLOSURE_GAP_BIAS` aims a closure at the one
	# street two adjacent strands are joined by; a day shuts one street in act I and four in act IV,
	# so it can never shut the fifteen a day has. Both bounds are the instruction: an unweighted
	# planner lands in a gap about a twelfth of the time, and a planner that only ever shut gaps
	# would have stopped being a wall round the corridor and become a fence down the middle of it.
	var gap_share := float(in_a_gap) / maxf(1.0, float(total))
	t.check(gaps > total * 4,
			"a day has many more gaps than it has closures to spend (%d against %d)"
			% [gaps, total])
	t.check(gap_share > 0.15, "%d of %d closures landed in one of them" % [in_a_gap, total])
	t.check(gap_share < 0.7, "and most of the rim is still ordinary ground (%.0f%% in a gap)"
			% (gap_share * 100.0))

## **The payoff rule.** A closure never lands on a calm area's own access street: never beside a
## park, since a barrier there closes nothing the ground itself does not already leave open on
## every other side; never on a courtyard's one archway street, since that is the one street
## closing it seals the courtyard for real rather than merely making the walk longer.
func _test_a_closure_never_lands_on_a_calm_areas_own_access(t) -> void:
	var checked := 0
	for map in _maps:
		var access := {}
		for area in ClosurePlanner.calm_areas(map):
			for segment in area.access:
				access[segment.key()] = true
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			for closure in _plan(map, day):
				checked += 1
				t.check(not access.has(closure.segment.key()),
						"seed %d day %d: closure at %s is not a calm area's own access street"
						% [map.seed_used, day, closure.segment.key()])
	t.check(checked > 0, "some closures were planned to check (%d)" % checked)

## `ClosurePlanner._invariant_holds`, restated here rather than exposed from it: a test that asks
## the code under test what the right answer is has not checked anything. `closed` is the
## candidate street on its own — the streets a calm zone absorbed need no barrier of their own,
## since their ground is already reflected as calm in the grid `map` was built into.
func _enough_calm_is_reachable(map: CityMap, grid: ReachabilityGrid,
		areas: Array[ClosurePlanner.CalmArea], closed: Dictionary) -> bool:
	var blocked := {}
	for key: Vector3i in closed:
		var segment := StreetNetwork.by_key(key)
		if not segment:
			continue
		for at_a in [true, false]:
			for tile in map.rect_tiles(segment.mouth_rect(at_a)):
				blocked[tile] = true
	var home_tile := map.world_to_tile(map.doorstep_world_position())
	var reached := grid.flood([home_tile], blocked)
	var reachable := 0
	for area in areas:
		var found := false
		for tile in map.rect_tiles(area.rect):
			if Tile.is_calm(map.tile_at(tile)) and grid.reaches(tile, blocked, reached):
				found = true
				break
		if found:
			reachable += 1
			if reachable >= Tuning.MIN_CALM_AREAS_REACHABLE:
				return true
	return false

## **A closure never cuts the corridor, so the day-level invariant should never have to refuse
## one.** `ClosurePlanner` still checks each candidate and still skips a failure, because two
## independent mechanisms is what M50 kept deliberately rather than trusting the placement alone —
## but a skip means the wall and the tree disagree about where she is going, and that is a bug
## rather than a near miss. This is the assertion the planner's telemetry note stands in for at
## runtime: over a run's worth of days on every seed, every candidate the planner reaches is legal.
##
## Every off-corridor street is tried rather than only the handful a day happens to reach, which
## is what makes the planner's `else` branch provably dead rather than merely unvisited. Two seeds
## and three days rather than twelve and fourteen: a grid flood is a real BFS over thousands of
## nodes rather than a max flow over a couple of hundred, so trying every street of every day of
## every seed costs minutes rather than seconds. The property is about the construction rather
## than about a layout, so a sample of days still exercises it.
func _test_a_wall_off_the_corridor_never_fails_the_invariant(t) -> void:
	for i in 2:
		var map := _maps[i]
		var home := ClosurePlanner.home_street(map)
		var grid := ReachabilityGrid.build(map)
		for day in [1, 7, 14]:
			var tree := _todays_tree(map, day)
			var areas := ClosurePlanner.calm_areas(map)
			var closed := {}
			var refused := 0
			for segment in StreetNetwork.segments():
				var key := segment.key()
				if key == home.key() or not map.has_street(key) or tree.is_on_the_tree(key):
					continue
				closed[key] = true
				if not _enough_calm_is_reachable(map, grid, areas, closed):
					refused += 1
				closed.erase(key)
			t.check(refused == 0,
					"seed %d day %d: %d off-corridor streets would have cut the calm"
					% [map.seed_used, day, refused])

## A day, planned the way the game plans it: the city becomes today's city first, because
## which blocks are calm is what the invariant is stated over.
##
## **Memoized per (seed, day).** `ClosurePlanner.plan_day` now builds a `ReachabilityGrid` and
## floods it rather than asking a couple-hundred-node max flow, and a dozen functions in this file
## each plan every day of every seed independently — recomputing the same plan eight times over
## turned this suite from seconds into minutes without checking anything an eighth time did not
## already check. `_test_closures_are_deterministic` is the one caller that has to see two genuinely
## independent calls and goes round this cache on purpose.
var _plan_cache := {}

func _plan(map: CityMap, day: int) -> Array[RoadClosure]:
	_repaint_for(map, day)
	var key := "%d:%d" % [map.seed_used, day]
	if not _plan_cache.has(key):
		_plan_cache[key] = _plan_uncached(map, day)
	return _plan_cache[key]

func _repaint_for(map: CityMap, day: int) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)

## The real thing, with no memory of having been asked before — what `_test_closures_are_
## deterministic` calls twice to find out whether `ClosurePlanner.plan_day` itself repeats itself,
## rather than whether a cache does.
func _plan_uncached(map: CityMap, day: int) -> Array[RoadClosure]:
	_repaint_for(map, day)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
	return ClosurePlanner.plan_day(map, day, rng)

## Today's city, and then today's corridor grown on it — the order `City.start_day` uses.
## Memoized for the same reason `_plan` is: several functions below ask for the same seed's same
## day.
var _tree_cache := {}

func _todays_tree(map: CityMap, day: int) -> RouteTree:
	_repaint_for(map, day)
	var key := "%d:%d" % [map.seed_used, day]
	if not _tree_cache.has(key):
		_tree_cache[key] = RouteTree.for_day(map, day)
	return _tree_cache[key]

func _closed_set(closures: Array[RoadClosure]) -> Dictionary:
	var closed := {}
	for closure in closures:
		closed[closure.segment.key()] = true
	return closed

## *(2026-09-11, the player: "fallen trees should only be possible on streets with trees and one
## spot should be empty (the fallen tree's spot)".)* Two claims, and the gate is the weaker of
## them: a weight would have made this test pass for eleven seeds out of twelve.
##
## Planned uncached, because the pit record lives on the map and is written by the call — a cache
## hit would leave the map holding some other day's answer and the assertions below would be about
## nothing.
##
## **Four maps, and that uncached re-plan is exactly why.** Every other sweep of every day of every
## seed in this file is answered out of `_plan`'s cache; this one cannot be, so it is the only
## place where a seed costs a full fourteen days of real planning a second time. Four is enough for
## the guard at the bottom — some day across the sweep has to have felled a tree — many times over,
## and what the loop is actually checking is a **gate** inside `_pick_kind`, asked once per
## closure: a weight rather than a gate would have shown up on the first map that felled one.
func _test_a_fallen_tree_only_falls_where_a_tree_stood(t) -> void:
	var felled := 0
	for map: CityMap in _maps.slice(0, 4):
		var lined := StreetTrees.segment_keys_with_trees(map)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			for closure in _plan_uncached(map, day):
				if closure.kind != RoadClosure.Kind.FALLEN_TREE:
					continue
				felled += 1
				var key := closure.segment.key()
				t.check(lined.has(key),
						"seed %d day %d: a tree fell across %s, which never had one on it"
						% [map.seed_used, day, key])
				# Exactly one pit of that street is empty, and it is the one nearest the middle of
				# the street — the tree that fell is the one that is missing, and only that one.
				var centre := map.tile_rect_to_world(closure.segment.tile_rect()).get_center()
				var wanted := StreetTrees.pit_nearest(map, key, centre)
				var empty := 0
				for pit in StreetTrees.planted(map):
					if pit.segment_key == key and map.is_tree_pit_emptied(pit.tile):
						empty += 1
						t.check(wanted != null and pit.tile == wanted.tile,
								"seed %d day %d: %s's empty pit is %s, not the one nearest the wreck"
								% [map.seed_used, day, key, pit.tile])
				t.check(empty == 1,
						"seed %d day %d: %s has %d empty pits, want exactly one"
						% [map.seed_used, day, key, empty])
	t.check(felled > 0, "some day across the sweep felled a tree (%d)" % felled)

## The fork the gate could have opened: a day whose closable streets are all bare has no
## `FALLEN_TREE` to offer, and must still shut its act's quota rather than coming up short.
##
## `RoadClosure.KINDS` keeps `ROADWORKS` and `CRASH` available from day 1, so the kind roll can
## never run out — asked of `_pick_kind` directly as well as of whole days, because a day that
## happens never to reach a bare street would pass the second half vacuously.
func _test_a_day_with_no_tree_lined_street_still_closes_its_quota(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("bare-street kinds")
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var kinds := RoadClosure.kinds_on(day)
		for _try in 30:
			var kind := ClosurePlanner._pick_kind(kinds, rng, false)
			t.check(kind != RoadClosure.Kind.FALLEN_TREE,
					"day %d: a bare street is never closed by a fallen tree" % day)
			t.check(RoadClosure.KINDS.has(kind),
					"day %d: a bare street still has something to have happened to it" % day)
	var bare_days := 0
	for map in _maps:
		var lined := StreetTrees.segment_keys_with_trees(map)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var closures := _plan(map, day)
			var any_lined := false
			for closure in closures:
				any_lined = any_lined or lined.has(closure.segment.key())
			if any_lined:
				continue
			bare_days += 1
			t.check(closures.size() == Tuning.closures_for_day(day),
					"seed %d day %d closed %d of its %d streets with no tree-lined one among them"
					% [map.seed_used, day, closures.size(), Tuning.closures_for_day(day)])
	t.check(bare_days > 0,
			"the sweep had days whose closures were all on bare streets (%d)" % bare_days)
