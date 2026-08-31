extends RefCounted
## Road closures and the day-level route invariant.
##
## This is the suite that has to be right, because the failure it guards against is invisible
## until it ruins somebody's run: a set of closures that leaves the player one way to one
## park — or no way at all — looks exactly like a normal morning until they have walked
## across the city and found the barrier.
##
## The invariant, stated once here and enforced in `ClosurePlanner`:
##
##     at least two distinct routes to at least two distinct calm areas.
##
## "Distinct" means sharing no street. Everything below is a way of checking that a day the
## planner produced still satisfies it, on seeds the planner has never seen.

## Enough seeds to catch a layout that only goes wrong in one arrangement, few enough that
## the suite stays under a second: the work is per-day planning, not generation.
const SEEDS := 12
const BASE_SEED := 5150

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 13))
	_test_the_lattice_is_the_lattice(t)
	_test_a_calm_zone_takes_its_streets_out_of_the_lattice(t)
	_test_a_tile_knows_which_street_it_is_on(t)
	_test_an_open_city_can_reach_everywhere_calm(t)
	_test_no_single_street_cuts_off_all_the_calm(t)
	_test_a_doorway_is_not_a_route(t)
	_test_every_planned_day_keeps_the_invariant(t)
	_test_the_home_street_is_never_closed(t)
	_test_closures_are_deterministic(t)
	_test_closure_counts_follow_the_act(t)
	_test_a_closed_street_is_out_of_the_network(t)
	_test_calm_ground_is_still_walkable_to(t)
	_test_closures_land_on_streets_that_matter(t)

# ------------------------------------------------------------------ lattice ---

## 7x7 blocks is 8x8 junctions, 56 streets each way. If this is ever wrong every number
## below it is wrong too, so it is checked first and by construction.
func _test_the_lattice_is_the_lattice(t) -> void:
	var junctions := StreetNetwork.junction_count()
	t.check(junctions == Tuning.CITY_BLOCKS + Vector2i.ONE,
			"one more junction than blocks along each axis")
	var expected := junctions.y * (junctions.x - 1) + junctions.x * (junctions.y - 1)
	t.check(StreetNetwork.segments().size() == expected,
			"the lattice has %d streets" % expected)

	var map := _maps[0]
	for segment in StreetNetwork.segments():
		var rect := segment.tile_rect()
		t.check(rect.size == (Vector2i(Tuning.BLOCK_SIZE, Tuning.STREET_WIDTH)
				if segment.horizontal else Vector2i(Tuning.STREET_WIDTH, Tuning.BLOCK_SIZE)),
				"street %s is one block long and one corridor wide" % segment.key())
		if not map.has_street(segment.key()):
			continue   # absorbed into a calm zone; it is grass, and the next test says so
		# A street the player cannot walk down is not a street, and closing one would be a
		# closure nobody could see.
		var walkable := 0
		for tile in map.rect_tiles(rect):
			if map.is_walkable(tile):
				walkable += 1
		t.check(walkable == rect.size.x * rect.size.y,
				"every tile of street %s is walkable" % segment.key())

## M21. A four-block calm zone is painted over the corridors between its own blocks, so the
## lattice has holes in it and route redundancy stops being true by construction.
##
## Four things have to hold together for that to be a hole rather than a bug, and each is a
## different way it could quietly not be one: the streets have to be **gone from the graph**,
## their ground has to be **calm rather than closed** (the player walks over it — that is the
## whole point), the junction in the middle of the zone has to have **nothing reaching it**, and
## the four around it have to still be reachable, because they are the ways in.
func _test_a_calm_zone_takes_its_streets_out_of_the_lattice(t) -> void:
	var zones := 0
	for map in _maps:
		t.check(map.zone_rects.size() >= Tuning.MIN_CALM_ZONES,
				"seed %d has at least one four-block calm zone" % map.seed_used)
		for anchor: Vector2i in map.zone_rects:
			zones += 1
			var footprint: Rect2i = map.zone_rects[anchor]
			var absorbed := 2 * Tuning.CALM_ZONE_BLOCKS * (Tuning.CALM_ZONE_BLOCKS - 1)
			var found := 0
			for segment in StreetNetwork.segments():
				if map.has_street(segment.key()):
					continue
				var rect := segment.tile_rect()
				if not CityMap.blocks_tile_rect(footprint).encloses(rect):
					continue
				found += 1
				for tile in map.rect_tiles(rect):
					t.check(Tile.is_calm(map.tile_at(tile)),
							"seed %d: the street %s the zone took is calm ground at %s"
							% [map.seed_used, segment.key(), tile])
					t.check(not map.is_closed(tile),
							"seed %d: and is open — a zone is walked through, not walked round"
							% map.seed_used)
			t.check(found == absorbed,
					"seed %d zone %s absorbed its %d inside streets (found %d)"
					% [map.seed_used, anchor, absorbed, found])

			# The junction in the middle has nothing left reaching it; the four on the edges are
			# T-junctions, which is what the milestone is for.
			var middle := footprint.position + Vector2i.ONE
			t.check(StreetNetwork.junction_distances([middle],
					map.blocked_segments()).size() == 1,
					"seed %d: junction %s inside zone %s is cut off from the whole city"
					% [map.seed_used, middle, anchor])
			var ways_in := StreetNetwork.around_blocks(footprint)
			t.check(ways_in.size() == 4 * Tuning.CALM_ZONE_BLOCKS,
					"seed %d zone %s has %d streets round it, two to a side"
					% [map.seed_used, anchor, ways_in.size()])
			for segment in ways_in:
				t.check(map.has_street(segment.key()),
						"seed %d: the way in %s is a real street" % [map.seed_used, segment.key()])
	t.check(zones >= SEEDS, "every seed made a zone (%d over %d seeds)" % [zones, SEEDS])

## A junction belongs to no street on purpose: it is where the choice is made, so closing a
## street may never seal the corner it starts from.
func _test_a_tile_knows_which_street_it_is_on(t) -> void:
	var map := _maps[0]
	for segment in StreetNetwork.segments():
		for tile in map.rect_tiles(segment.tile_rect()):
			var found := StreetNetwork.segment_containing(tile)
			t.check(found != null and found.key() == segment.key(),
					"tile %s belongs to street %s" % [tile, segment.key()])
	for i in StreetNetwork.junction_count().x:
		var corner := Vector2i(i, i) * CityMap.period()
		t.check(StreetNetwork.segment_containing(corner) == null,
				"junction tile %s belongs to no street" % corner)

# ---------------------------------------------------------------- the routes ---

## The layout guarantee from docs/CITY.md, restated on the graph: with nothing closed, every
## piece of calm ground can be walked to. If this ever fails the *generator* is wrong, not the
## planner, and no closure set could rescue the day.
##
## **It asked for two ways in until 2026-08-31**, and the second is an offer now rather than a
## guarantee: *"the two routes guarantee is not a hard rule."* What replaces it here is not a
## weaker version of the same sentence but a different one — a hard blocker holds for the whole
## run, so what it may never do is make calm unreachable, and how many ways round it there are is
## the city's business. `tests/test_route_tree.gd` is where the second route is measured; the
## count below is what it came out as, kept as a floor rather than as the promise.
func _test_an_open_city_can_reach_everywhere_calm(t) -> void:
	var with_a_choice := 0
	var total := 0
	for map in _maps:
		var home := ClosurePlanner.home_street(map)
		t.check(home != null, "seed %d: the front door opens onto a street" % map.seed_used)
		for area in ClosurePlanner.calm_areas(map):
			t.check(StreetNetwork.route_count(home, area.access, map.blocked_segments(), 1) >= 1,
					"seed %d: calm area %s can be walked to before anything closes"
					% [map.seed_used, area.block])
			total += 1
			if StreetNetwork.route_count(home, area.access, map.blocked_segments(), 2) >= 2:
				with_a_choice += 1
	# Measured at 100% of areas on these seeds with the weaker gate in place. A floor well under
	# it, because the offer is allowed to fail on a map that cannot make it — what would be worth
	# knowing about is the offer quietly disappearing.
	t.check(float(with_a_choice) / float(total) >= 0.8,
			"and most of them still have a choice of ways in (%d of %d)" % [with_a_choice, total])

## Menger, the other way round, asked about the **city** rather than about one area: no single
## street may cut off *all* the calm. This is the winnability property the old edge-disjoint rule
## was standing in for, stated directly — by actually closing each street in turn, the same brute
## force `tests/test_generator.gd` uses on the tile grid, on one seed because it is
## O(streets x flow).
##
## **It used to be stated per area and cannot be any more.** *(2026-08-31.)* A calm area with one
## way in is legitimate — the design says so about courtyards and now about the tree's second
## probe — so *"this area survives any street being shut"* is false by construction the moment a
## dead end takes one of its ways in. What is not allowed to be false is that shutting one street
## leaves her nowhere to go, and that is the sentence worth holding: it is the one whose failure
## is an unwinnable run rather than a short day.
##
## The area's own access streets are excluded, and that exclusion is the doorway exemption rather
## than a convenience: a courtyard has one archway onto one street, so shutting that street does
## put it out of reach. `_test_a_doorway_is_not_a_route` below is the other half of this.
func _test_no_single_street_cuts_off_all_the_calm(t) -> void:
	var map := _maps[0]
	var home := ClosurePlanner.home_street(map)
	var areas := ClosurePlanner.calm_areas(map)
	for segment in StreetNetwork.segments():
		if segment.key() == home.key() or not map.has_street(segment.key()):
			continue
		var closed := map.blocked_segments()
		closed[segment.key()] = true
		var reachable := 0
		for area in areas:
			var doors := {}
			for door in area.access:
				doors[door.key()] = true
			# An area reached only through the street being shut is out of reach today, which is
			# the doorway exemption and not a failure.
			if doors.has(segment.key()) and area.access.size() == 1:
				continue
			if StreetNetwork.route_count(home, area.access, closed, 1) >= 1:
				reachable += 1
		t.check(reachable >= Tuning.MIN_CALM_AREAS_REACHABLE,
				"shutting %s still leaves %d calm areas to walk to, wanting %d"
				% [segment.key(), reachable, Tuning.MIN_CALM_AREAS_REACHABLE])

## The exemption, stated as a fact rather than left implicit: an area with one way in loses
## it if that way is shut, and it is the *invariant* — two other areas still reachable — that
## keeps the day winnable, not any promise about this one.
##
## A courtyard is the case that matters. If this ever stops finding one, the test has stopped
## checking anything and wants pointing at whatever replaced hidden calm.
func _test_a_doorway_is_not_a_route(t) -> void:
	var checked := 0
	for map in _maps:
		var home := ClosurePlanner.home_street(map)
		for area in ClosurePlanner.calm_areas(map):
			if area.access.size() != 1:
				continue
			checked += 1
			t.check(StreetNetwork.route_count(home, area.access, map.blocked_segments(), 1) >= 1,
					"seed %d: the one archway into %s can be walked to"
					% [map.seed_used, area.block])
			var closed := map.blocked_segments()
			closed[area.access[0].key()] = true
			t.check(StreetNetwork.route_count(home, area.access, closed, 1) == 0,
					"seed %d: and shutting that archway's street puts %s out of reach today"
					% [map.seed_used, area.block])
	t.check(checked > 0, "the city still has calm with a single way in (%d found)" % checked)

# --------------------------------------------------------------- the planner ---

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
func _test_closures_are_deterministic(t) -> void:
	for map in _maps:
		for day in [1, 7, 14]:
			var first := _plan(map, day)
			var second := _plan(map, day)
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

## The whole street comes out, not just the two ends. Anything choosing somewhere to put
## something asks `is_open`, and a street that is half closed would let it put an event in
## the middle of a place nobody can reach.
func _test_a_closed_street_is_out_of_the_network(t) -> void:
	var map := _maps[0]
	var closures := _plan(map, 12)
	map.close_streets(closures)
	t.check(not closures.is_empty(), "act IV shuts something")
	for closure in closures:
		for tile in closure.tiles(map):
			t.check(map.is_closed(tile), "tile %s of a closed street is closed" % tile)
			t.check(not map.is_open(tile), "and is not open, though it is still walkable")
			t.check(map.is_walkable(tile),
					"a closure never moves a walkable tile — it only shuts it")
	map.closed_tiles.clear()

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

## A closure in the far corner of the map is scenery, not a decision. The bias is what aims
## the mechanic at the route, so it is worth asserting that it lands — as a proportion over
## many days, because any single day may legitimately shut a street nobody wanted.
func _test_closures_land_on_streets_that_matter(t) -> void:
	var on_a_route := 0
	var total := 0
	for map in _maps:
		var home := ClosurePlanner.home_street(map)
		var areas := ClosurePlanner.calm_areas(map)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var useful := _useful_streets(map, home, areas)
			for closure in _plan(map, day):
				total += 1
				if useful.has(closure.segment.key()):
					on_a_route += 1
	t.check(total > 0, "the planner shuts streets at all (%d over %d seeds)" % [total, SEEDS])
	# The unweighted share would be whatever fraction of the lattice is on a route; the bias
	# has to beat that clearly. Half is a floor with plenty of room, not a measurement.
	t.check(float(on_a_route) / maxf(1.0, float(total)) > 0.5,
			"%d of %d closures landed on a street the player would have used"
			% [on_a_route, total])

# ------------------------------------------------------------------ helpers ---

## A day, planned the way the game plans it: the city becomes today's city first, because
## which blocks are calm is what the invariant is stated over.
func _plan(map: CityMap, day: int) -> Array[RoadClosure]:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
	return ClosurePlanner.plan_day(map, day, rng)

func _closed_set(closures: Array[RoadClosure]) -> Dictionary:
	var closed := {}
	for closure in closures:
		closed[closure.segment.key()] = true
	return closed

## The same "is this street on the way" question the planner asks, asked again here rather
## than exposed from the planner: a test that calls the code under test to decide what the
## right answer is has not checked anything.
func _useful_streets(map: CityMap, home: StreetNetwork.Segment,
		areas: Array[ClosurePlanner.CalmArea]) -> Dictionary:
	var useful := {}
	var absent := map.blocked_segments()
	var from_home := StreetNetwork.junction_distances([home.a, home.b], absent)
	for area in areas:
		var doorsteps: Array[Vector2i] = []
		for segment in area.access:
			doorsteps.append(segment.a)
			doorsteps.append(segment.b)
		var to_calm := StreetNetwork.junction_distances(doorsteps, absent)
		var best := INF
		for junction in doorsteps:
			var node := StreetNetwork.node_of(junction)
			if from_home.has(node):
				best = minf(best, float(from_home[node]))
		for segment in StreetNetwork.segments():
			if absent.has(segment.key()):
				continue
			var u := StreetNetwork.node_of(segment.a)
			var v := StreetNetwork.node_of(segment.b)
			for pair in [[u, v], [v, u]]:
				if not from_home.has(pair[0]) or not to_calm.has(pair[1]):
					continue
				if float(from_home[pair[0]]) + 1.0 + float(to_calm[pair[1]]) \
						<= best + Tuning.CLOSURE_ROUTE_SLACK:
					useful[segment.key()] = true
	return useful
