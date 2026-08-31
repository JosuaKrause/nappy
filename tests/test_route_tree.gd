extends RefCounted
## The day's corridor: `RouteTree`.
##
## What this has to hold is the construction's own promises, because every one of them is a
## promise placement will lean on in step 2 and every one of them fails silently:
##
## - a branch **arrives** — its routes are connected chains of real streets from a way into the
##   calm area to the doorstep, and nothing else looks different from a chain that stops halfway;
## - the two routes of one area **share no street**, which is the whole of "same colours may not
##   merge" and the only reason a second route is worth offering at all;
## - different areas **do** share, because the sharing is what makes placement cheap and a tree
##   that has quietly become a star still passes everything else here;
## - the fan-out **meets every route**, not every branch — see `RouteTree.covering_sites`;
## - and the same day grows the same tree, twice, on a different afternoon.
##
## The numbers below are measurements taken with `tests/test_zz_tree_probe.gd` over 32 planned
## days, kept as floors with room under them rather than as the values themselves.

## Enough seeds to catch a layout that only goes wrong in one arrangement, few enough that the
## suite stays about a second. The work is per-day planning, not generation.
const SEEDS := 6
const BASE_SEED := 4400
const DAYS := [1, 5, 9, 14]

## One planned day, kept whole so every test below asks about the same thing.
class Day extends RefCounted:
	var map: CityMap
	var day: int
	var closures: Array[RoadClosure] = []
	var blocked := {}
	var home: StreetNetwork.Segment
	var areas: Array[ClosurePlanner.CalmArea] = []
	var tree: RouteTree
	## The same day grown a second time, taken **here** rather than in the test that compares
	## them: one `CityMap` is shared by every day of a seed and `repaint()` moves what is calm, so
	## asking a later test to re-grow day 1 asks it against day 14's city.
	var again: RouteTree

var _days: Array[Day] = []

func run(t) -> void:
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		for day in DAYS:
			_days.append(_plan(map, day))
	_test_a_route_is_a_walk_from_the_calm_to_the_door(t)
	_test_the_tree_only_uses_streets_that_are_there(t)
	_test_the_two_routes_of_one_area_share_no_street(t)
	_test_a_street_says_which_branches_it_carries(t)
	_test_different_areas_share_ground(t)
	_test_every_reachable_calm_area_is_on_the_tree(t)
	_test_a_second_route_is_offered_where_the_map_allows_one(t)
	_test_the_fan_out_meets_every_route(t)
	_test_the_fan_out_is_never_one_place(t)
	_test_the_same_day_grows_the_same_tree(t)
	_test_a_different_day_is_a_different_way(t)

# ----------------------------------------------------------------- the branch ---

## A route is an ordered chain of streets, and it goes from a way into the calm area to the
## street outside the front door. Checked by walking it: consecutive streets have to meet at a
## junction, the far end of the first has to be a way in, and the far end of the last has to be
## the doorstep. A route that merely *contains* the right streets would pass a set comparison.
func _test_a_route_is_a_walk_from_the_calm_to_the_door(t) -> void:
	var routes := 0
	for planned in _days:
		var home_nodes := _nodes_of(planned.home)
		for branch in planned.tree.branches:
			var access := _access_nodes(planned, branch.area)
			t.check(not access.is_empty(),
					"seed %d day %d: %s is a calm area with ways in"
					% [planned.map.seed_used, planned.day, branch.area])
			for route: Array in branch.routes:
				routes += 1
				var at := _start_of(route, access)
				t.check(at >= 0, "seed %d day %d: %s's route starts at a way in"
						% [planned.map.seed_used, planned.day, branch.area])
				var seen := {}
				for key: Vector3i in route:
					var ends := _nodes_of(StreetNetwork.by_key(key))
					t.check(ends.has(at), "seed %d day %d: %s's route runs street to street"
							% [planned.map.seed_used, planned.day, branch.area])
					t.check(not seen.has(key), "seed %d day %d: and never twice down one street"
							% [planned.map.seed_used, planned.day])
					seen[key] = true
					at = ends[1] if ends[0] == at else ends[0]
				t.check(home_nodes.has(at), "seed %d day %d: %s's route ends at the doorstep"
						% [planned.map.seed_used, planned.day, branch.area])
	t.check(routes > SEEDS * DAYS.size() * 4,
			"the days planned enough routes to be worth checking (%d)" % routes)

## The lattice has holes in it and a day shuts streets on top of them. A corridor down either is
## guidance to walk into a barrier.
func _test_the_tree_only_uses_streets_that_are_there(t) -> void:
	for planned in _days:
		for key in planned.tree.streets():
			t.check(not planned.blocked.has(key),
					"seed %d day %d: the tree stays off shut and absent streets (%s)"
					% [planned.map.seed_used, planned.day, key])
			t.check(key != planned.home.key(),
					"seed %d day %d: and off the doorstep itself, which is not a route"
					% [planned.map.seed_used, planned.day])

## **Same colours may not merge.** The two probes from one area can never become one path, so
## where a second route exists at all the area is reached two genuinely distinct ways. This is
## the property the whole colour mechanism exists to maintain, and it is what the fan-out's
## "at least two places" falls out of.
func _test_the_two_routes_of_one_area_share_no_street(t) -> void:
	var pairs := 0
	for planned in _days:
		for branch in planned.tree.branches:
			if not branch.has_a_choice():
				continue
			pairs += 1
			var first := {}
			for key: Vector3i in branch.routes[0]:
				first[key] = true
			for key: Vector3i in branch.routes[1]:
				t.check(not first.has(key),
						"seed %d day %d: %s's two routes share no street (%s)"
						% [planned.map.seed_used, planned.day, branch.area, key])
	t.check(pairs > 0, "some area was offered a choice (%d)" % pairs)

## **`branches_on` names what `colours_on` counts.** *(Playtest 17.)* The telemetry has to be able
## to say she left one route and joined another — *"technically it's leaving a path and entering a
## new path"* — and a count cannot: two streets each carrying one branch look identical whether it
## is the same branch or not. So the two answers have to agree about how many, and the named one has
## to be a set of real branch indices, or "she switched" would be reported off a number nobody could
## check.
func _test_a_street_says_which_branches_it_carries(t) -> void:
	var named := 0
	for planned in _days:
		for key in planned.tree.streets():
			var branches := planned.tree.branches_on(key)
			t.check(branches.size() == planned.tree.colours_on(key),
					"seed %d day %d: %s names as many branches as it counts (%d, %d)"
					% [planned.map.seed_used, planned.day, key, branches.size(),
					planned.tree.colours_on(key)])
			for colour in branches:
				t.check(colour >= 0 and colour < planned.tree.branches.size(),
						"seed %d day %d: %s carries a branch that exists (%d of %d)"
						% [planned.map.seed_used, planned.day, key, colour,
						planned.tree.branches.size()])
			named += 1
	t.check(named > 0, "there were streets to ask (%d)" % named)
	# A street off the tree carries nothing, which is what makes an empty answer meaningful.
	t.check(_days[0].tree.branches_on(Vector3i(-1, -1, 0)).is_empty(),
			"a street that is not on the tree carries no branch")

## **Different colours merge, and that is the point.** A tree whose branches share nothing is a
## star: no bundles, no chokepoints, and a fan-out as wide as the number of destinations. Every
## other test here passes on a star, which is why this one is stated as a proportion.
##
## Measured at 50% of tree streets bundled over 32 days; a third is a floor with room under it.
func _test_different_areas_share_ground(t) -> void:
	var bundled := 0
	var streets := 0
	for planned in _days:
		streets += planned.tree.streets().size()
		bundled += planned.tree.bundles().size()
		t.check(planned.tree.bundles().size() > 0,
				"seed %d day %d: some stretch is shared by two areas"
				% [planned.map.seed_used, planned.day])
	t.check(float(bundled) / maxf(1.0, float(streets)) > 0.33,
			"%d of %d corridor streets carry more than one area" % [bundled, streets])

## Everything the day can still reach gets a corridor, because the guidance is the **set** of
## offers and the player chooses. An area with no way in today legitimately has no branch —
## which is one a closure has sealed, or one whose ways in a calm zone absorbed.
func _test_every_reachable_calm_area_is_on_the_tree(t) -> void:
	for planned in _days:
		for area in planned.areas:
			if StreetNetwork.route_count(planned.home, area.access, planned.blocked, 1) < 1:
				continue
			var branch := planned.tree.branch_for(area.block)
			# A calm area next door to the home is arrived at without walking a street, so it has
			# no corridor and is not a branch. See `RouteTree._is_no_route`.
			if not branch and _access_nodes(planned, area.block).any(
					func(node: int) -> bool: return _nodes_of(planned.home).has(node)):
				continue
			t.check(branch != null,
					"seed %d day %d: calm area %s is reachable, so it is on the tree"
					% [planned.map.seed_used, planned.day, area.block])

## A second route is an **offer**, not a promise: probe one is a random walk, so it can spend the
## last streets some other way home needed. What is measured is how often that costs an area its
## choice — 241 of 241 branches got one over 32 planned days, so a real regression here would be
## the construction quietly turning into a bundle of shortest paths.
func _test_a_second_route_is_offered_where_the_map_allows_one(t) -> void:
	var offered := 0
	var possible := 0
	for planned in _days:
		for branch in planned.tree.branches:
			var area := _area_of(planned, branch.area)
			if not area or StreetNetwork.route_count(
					planned.home, area.access, planned.blocked, 2) < 2:
				continue
			possible += 1
			if branch.has_a_choice():
				offered += 1
	t.check(possible > 0, "the map allowed a choice somewhere (%d)" % possible)
	t.check(float(offered) / maxf(1.0, float(possible)) > 0.9,
			"%d of %d areas that could have two routes were offered two" % [offered, possible])

# ---------------------------------------------------------------- the fan-out ---

## What a set piece needs: a small set of streets such that whichever way she goes, she meets one.
func _test_the_fan_out_meets_every_route(t) -> void:
	for planned in _days:
		var sites := planned.tree.covering_sites()
		t.check(not sites.is_empty(), "seed %d day %d: the day has a fan-out at all"
				% [planned.map.seed_used, planned.day])
		for branch in planned.tree.branches:
			for route: Array in branch.routes:
				var met := false
				for key: Vector3i in route:
					if sites.has(key):
						met = true
						break
				t.check(met, "seed %d day %d: %s's route meets the fan-out"
						% [planned.map.seed_used, planned.day, branch.area])
		# Every site earns its place, or the answer is not a smallest one.
		for dropped in sites:
			var without: Array[Vector3i] = sites.duplicate()
			without.erase(dropped)
			t.check(not _covers_everything(planned.tree, without),
					"seed %d day %d: no street in the fan-out is spare"
					% [planned.map.seed_used, planned.day])

## **A bundle is a bundle and never a guarantee.** *"Anything that must be encountered has to
## exist in at least two places"*, even on a day with one perfect chokepoint — because a
## chokepoint on route one is not on route two, by construction. Any code that assumes a single
## site is wrong, and the first version of `covering_sites` assumed exactly that.
##
## Measured: two to six sites against about fifteen routes over 32 planned days, never one.
func _test_the_fan_out_is_never_one_place(t) -> void:
	for planned in _days:
		var choices := 0
		for branch in planned.tree.branches:
			if branch.has_a_choice():
				choices += 1
		if choices == 0:
			continue
		t.check(planned.tree.covering_sites().size() >= 2,
				"seed %d day %d: %d areas have a choice, so the fan-out is at least two places"
				% [planned.map.seed_used, planned.day, choices])

# ------------------------------------------------------------- the same day ---

## A run is learnable or it is nothing, and the tree is now part of what a day *is*: the
## scheduler places against it and `TelemetryMap` draws it, so if the two grew different trees
## the picture would be of a plan nobody used.
func _test_the_same_day_grows_the_same_tree(t) -> void:
	for planned in _days:
		var again := planned.again
		t.check(again.branches.size() == planned.tree.branches.size(),
				"seed %d day %d: the same day grows the same number of branches"
				% [planned.map.seed_used, planned.day])
		for i in mini(again.branches.size(), planned.tree.branches.size()):
			t.check(again.branches[i].area == planned.tree.branches[i].area
					and _keys(again.branches[i]) == _keys(planned.tree.branches[i]),
					"seed %d day %d: and the same streets for %s"
					% [planned.map.seed_used, planned.day, planned.tree.branches[i].area])

## *"A route to a calm area is not stable across days, and that is the mechanism rather than a
## side effect."* The hard blockers are what she learns; the day is what she reads.
func _test_a_different_day_is_a_different_way(t) -> void:
	var moved := 0
	var compared := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		var first := _plan(map, 1)
		var later := _plan(map, 5)
		for branch in first.tree.branches:
			var other := later.tree.branch_for(branch.area)
			if not other:
				continue
			compared += 1
			if _keys(branch) != _keys(other):
				moved += 1
	t.check(compared > 0, "the same calm areas exist on both days (%d)" % compared)
	t.check(float(moved) / maxf(1.0, float(compared)) > 0.5,
			"%d of %d areas are reached a different way on another day" % [moved, compared])

# ------------------------------------------------------------------ helpers ---

## A day, planned the way the game plans it: the city becomes today's city first, because which
## blocks are calm is what the tree is grown from.
func _plan(map: CityMap, day: int) -> Day:
	var planned := Day.new()
	planned.map = map
	planned.day = day
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
	# The tree first and the closures against it, which is the order `City.start_day` uses since M50
	# step 2 and the reason `planned.blocked` below can still include the closures: a wall is placed
	# off the corridor, so a corridor grown before the barriers went up is still walkable after.
	planned.tree = RouteTree.for_day(map, day)
	planned.again = RouteTree.for_day(map, day)
	planned.closures = ClosurePlanner.plan_day(map, day, rng, planned.tree)
	var closed := {}
	for closure in planned.closures:
		closed[closure.segment.key()] = true
	planned.blocked = map.blocked_segments(closed)
	planned.home = ClosurePlanner.home_street(map)
	planned.areas = ClosurePlanner.calm_areas(map)
	return planned

func _nodes_of(segment: StreetNetwork.Segment) -> Array[int]:
	var nodes: Array[int] = [StreetNetwork.node_of(segment.a), StreetNetwork.node_of(segment.b)]
	return nodes

func _access_nodes(planned: Day, block: Vector2i) -> Array[int]:
	var nodes: Array[int] = []
	var area := _area_of(planned, block)
	if not area:
		return nodes
	for segment in area.access:
		for node in _nodes_of(segment):
			if not nodes.has(node):
				nodes.append(node)
	return nodes

func _area_of(planned: Day, block: Vector2i) -> ClosurePlanner.CalmArea:
	for area in planned.areas:
		if area.block == block:
			return area
	return null

## Which end of a route's first street it was walked from: the one that is a way into the area
## and is not the junction shared with the second street.
func _start_of(route: Array, access: Array[int]) -> int:
	if route.is_empty():
		return -1
	var ends := _nodes_of(StreetNetwork.by_key(route[0]))
	if route.size() > 1:
		var next := _nodes_of(StreetNetwork.by_key(route[1]))
		var free: int = ends[1] if next.has(ends[0]) else ends[0]
		return free if access.has(free) else -1
	for node in ends:
		if access.has(node):
			return node
	return -1

func _keys(branch: RouteTree.Branch) -> Array:
	var found: Array = []
	for route: Array in branch.routes:
		found.append_array(route)
	return found

func _covers_everything(tree: RouteTree, sites: Array[Vector3i]) -> bool:
	for branch in tree.branches:
		for route: Array in branch.routes:
			var met := false
			for key: Vector3i in route:
				if sites.has(key):
					met = true
					break
			if not met:
				return false
	return true
