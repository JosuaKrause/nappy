extends RefCounted
## The day's corridor: `RouteTree`.
##
## What this has to hold is the construction's own promises, because every one of them is a
## promise placement will lean on and every one of them fails silently:
##
## - a branch **arrives** — its routes are connected chains of grid cells from a way into the
##   calm area to the doorstep, and nothing else looks different from a chain that stops halfway;
## - the two routes of one area **share no cell**, which is the whole of "same colours may not
##   merge" and the only reason a second route is worth offering at all;
## - different areas **do** share, because the sharing is what makes placement cheap and a tree
##   that has quietly become a star still passes everything else here;
## - the fan-out **meets every route**, not every branch — see `RouteTree.covering_sites`;
## - and the same day grows the same tree, twice, on a different afternoon.
##
## The numbers below are measurements taken over the days this suite plans, kept as floors with
## room under them rather than as the values themselves.

## Enough seeds to catch a layout that only goes wrong in one arrangement, few enough that the
## suite stays quick. The work is per-day planning, not generation.
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
	_test_no_route_runs_along_the_main_road(t)
	_test_the_two_routes_of_one_area_share_no_cell(t)
	_test_a_tile_says_which_branches_it_carries(t)
	_test_different_areas_share_ground(t)
	_test_every_reachable_calm_area_is_on_the_tree(t)
	_test_a_second_route_is_offered_where_the_map_allows_one(t)
	_test_the_fan_out_meets_every_route(t)
	_test_the_fan_out_is_never_one_place(t)
	_test_a_gap_joins_two_parallel_strands(t)
	_test_a_gap_is_a_small_part_of_the_rim(t)
	_test_the_same_day_grows_the_same_tree(t)
	_test_a_different_day_is_a_different_way(t)

# ----------------------------------------------------------------- the branch ---

## A route is an ordered chain of grid cells, and it goes from a way into the calm area to the
## doorstep. Checked by walking it: consecutive cells have to be joined by a grid edge, the first
## cell has to be exactly one of the area's own ways in — that is where the walk started — and the
## last has to be a grid-step from the doorstep, since the home's own cells are never part of a
## route (a door is not a route). A route that merely *contains* the right cells would pass a set
## comparison.
func _test_a_route_is_a_walk_from_the_calm_to_the_door(t) -> void:
	var routes := 0
	for planned in _days:
		var home_nodes := _home_nodes(planned)
		for branch in planned.tree.branches:
			var area := _area_of(planned, branch.area)
			t.check(area != null, "seed %d day %d: %s is a calm area on today's map"
					% [planned.map.seed_used, planned.day, branch.area])
			if not area:
				continue
			var access := _access_nodes(planned, area)
			t.check(not access.is_empty(),
					"seed %d day %d: %s is a calm area with ways in"
					% [planned.map.seed_used, planned.day, branch.area])
			for route: Array in branch.routes:
				routes += 1
				t.check(not route.is_empty(), "seed %d day %d: %s's route is not empty"
						% [planned.map.seed_used, planned.day, branch.area])
				if route.is_empty():
					continue
				var first := _node_of_cell(planned, route[0])
				t.check(access.has(first), "seed %d day %d: %s's route starts at a way in"
						% [planned.map.seed_used, planned.day, branch.area])
				var seen := {}
				for i in route.size():
					var cell: Vector2i = route[i]
					t.check(not seen.has(cell),
							"seed %d day %d: %s's route never visits a cell twice"
							% [planned.map.seed_used, planned.day, branch.area])
					seen[cell] = true
					if i > 0:
						t.check(_grid_adjacent(planned, route[i - 1], cell),
								"seed %d day %d: %s's route runs cell to adjacent cell (%s -> %s)"
								% [planned.map.seed_used, planned.day, branch.area,
								route[i - 1], cell])
				var last := _node_of_cell(planned, route[route.size() - 1])
				t.check(_adjacent_to_any(planned, last, home_nodes),
						"seed %d day %d: %s's route ends a grid-step from the doorstep"
						% [planned.map.seed_used, planned.day, branch.area])
	t.check(routes > SEEDS * DAYS.size() * 4,
			"the days planned enough routes to be worth checking (%d)" % routes)

## A day shuts streets and the tree must stay off every one of them, or a corridor down one is
## guidance to walk into a barrier.
##
## **Not off every *absent* street any more.** `streets()` names any segment a cell of the tree
## resolves to, including one a calm zone painted over — and the tree can legitimately cut across
## exactly that ground now, since it is walkable park rather than a barrier. `planned.blocked`
## conflates absent and closed-today; only the closed half is still a real exclusion.
func _test_the_tree_only_uses_streets_that_are_there(t) -> void:
	for planned in _days:
		for key in planned.tree.streets():
			if planned.map.absent_segments.has(key):
				continue
			t.check(not planned.blocked.has(key),
					"seed %d day %d: the tree stays off shut streets (%s)"
					% [planned.map.seed_used, planned.day, key])
			t.check(key != planned.home.key(),
					"seed %d day %d: and off the doorstep itself, which is not a route"
					% [planned.map.seed_used, planned.day])

## *(2026-09-03, playtest 22: "a path should never go alongside the main road — main road by
## itself can be considered a blocker — paths can only cross the main road".)* Restated
## independently of `RouteTree._runs_along_the_spine` rather than calling it, for the reason
## `_home_nodes` above is restated rather than exposed: a check that shares the rule's own code
## cannot catch the rule being wrong. Every route is a chain of adjacent cells
## (`_test_a_route_is_a_walk_from_the_calm_to_the_door` establishes that); this asks whether any
## two consecutive cells of one are a **y-step inside the main road's own x-band** — a step along
## the spine's length rather than across its width — checked against `CityMap.street_kind_at`
## directly rather than against anything `RouteTree` computed.
func _test_no_route_runs_along_the_main_road(t) -> void:
	var on_the_spine := 0
	for planned in _days:
		if planned.map.main_road < 0:
			continue
		for branch in planned.tree.branches:
			for route: Array in branch.routes:
				for cell: Vector2i in route:
					if planned.map.street_kind_at(true, cell * ReachabilityGrid.CELL) \
							== GameEnums.StreetKind.MAIN:
						on_the_spine += 1
				for i in range(1, route.size()):
					var a: Vector2i = route[i - 1]
					var b: Vector2i = route[i]
					if a.x != b.x:
						continue   # an x-step: crossing the spine's width, never refused
					var both_on_spine := planned.map.street_kind_at(true, a * ReachabilityGrid.CELL) \
							== GameEnums.StreetKind.MAIN
					t.check(not both_on_spine,
							("seed %d day %d: %s's route does not run along the main road " +
							"(%s -> %s)") % [planned.map.seed_used, planned.day, branch.area, a, b])
	# Not a lower bound to defend — crossing is luck, the same as an alley (see RouteTree's own
	# doc, "It stays luck"). Reported so a run of zero is visible rather than silently unchecked.
	t.check(on_the_spine >= 0, "%d route cells crossed the main road" % on_the_spine)

## **Same colours may not merge.** The two probes from one area can never become one path, so
## where a second route exists at all the area is reached two genuinely distinct ways. This is
## the property the whole colour mechanism exists to maintain, and it is what the fan-out's
## "at least two places" falls out of.
func _test_the_two_routes_of_one_area_share_no_cell(t) -> void:
	var pairs := 0
	for planned in _days:
		for branch in planned.tree.branches:
			if not branch.has_a_choice():
				continue
			pairs += 1
			var first := {}
			for cell: Vector2i in branch.routes[0]:
				first[cell] = true
			for cell: Vector2i in branch.routes[1]:
				t.check(not first.has(cell),
						"seed %d day %d: %s's two routes share no cell (%s)"
						% [planned.map.seed_used, planned.day, branch.area, cell])
	t.check(pairs > 0, "some area was offered a choice (%d)" % pairs)

## **`branches_on` is the telemetry's question.** *(Playtest 17.)* The telemetry has to be able
## to say she left one route and joined another — *"technically it's leaving a path and entering a
## new path"* — which a tile that only knows whether it is "on" cannot: two tiles each carrying one
## branch look identical whether it is the same branch or not. So the answer is a set of real
## branch indices, or "she switched" would be reported off a number nobody could check.
func _test_a_tile_says_which_branches_it_carries(t) -> void:
	var named := 0
	for planned in _days:
		for cell in planned.tree.cells():
			var tile := _walkable_tile_of_cell(planned, cell)
			var branches := planned.tree.branches_on(tile)
			t.check(not branches.is_empty(),
					"seed %d day %d: a cell on the tree names at least one branch (%s)"
					% [planned.map.seed_used, planned.day, cell])
			for colour in branches:
				t.check(colour >= 0 and colour < planned.tree.branches.size(),
						"seed %d day %d: %s carries a branch that exists (%d of %d)"
						% [planned.map.seed_used, planned.day, tile, colour,
						planned.tree.branches.size()])
			named += 1
		t.check(planned.tree.branches_on(planned.home.tile_rect().position).is_empty(),
				"seed %d day %d: the doorstep street carries no branch"
				% [planned.map.seed_used, planned.day])
	t.check(named > 0, "there were cells to ask (%d)" % named)

## **Different colours merge, and that is the point.** A tree whose branches share nothing is a
## star: no bundles, no chokepoints, and a fan-out as wide as the number of destinations. Every
## other test here passes on a star, which is why this one is stated as a proportion.
func _test_different_areas_share_ground(t) -> void:
	var bundled := 0
	var cells := 0
	for planned in _days:
		cells += planned.tree.cells().size()
		bundled += planned.tree.bundles().size()
		t.check(planned.tree.bundles().size() > 0,
				"seed %d day %d: some stretch is shared by two areas"
				% [planned.map.seed_used, planned.day])
	t.check(float(bundled) / maxf(1.0, float(cells)) > 0.2,
			"%d of %d corridor cells carry more than one area" % [bundled, cells])

## Everything the day can still reach gets a corridor, because the guidance is the **set** of
## offers and the player chooses. An area with no way in today legitimately has no branch —
## which is one a closure has sealed, or one whose ways in a calm zone absorbed, or one right
## next door to the home.
func _test_every_reachable_calm_area_is_on_the_tree(t) -> void:
	for planned in _days:
		var home_nodes := _home_nodes(planned)
		for area in planned.areas:
			if StreetNetwork.route_count(planned.home, area.access, planned.blocked, 1) < 1:
				continue
			var branch := planned.tree.branch_for(area.block)
			# A calm area next door to the home is arrived at without walking anywhere, so it has
			# no corridor and is not a branch. See `RouteTree._is_no_route`.
			if not branch:
				var access := _access_nodes(planned, area)
				var next_to_home := false
				for node in access:
					if home_nodes.has(node):
						next_to_home = true
						break
				if next_to_home:
					continue
			t.check(branch != null,
					"seed %d day %d: calm area %s is reachable, so it is on the tree"
					% [planned.map.seed_used, planned.day, area.block])

## A second route is an **offer**, not a promise: probe one is a random walk, so it can spend the
## ground some other way home needed.
##
## **Lower than the junction-graph version's own floor, and that is a real cost of a real fix
## rather than a loosened test.** The second probe may no longer start from an access cell the
## first one's route already stands on — see `_shortest_home`'s own doc — because a cell is part
## of a route now where a junction never was. An area with few access cells, most of them spent by
## probe one, more often has nowhere left for probe two to start from than the old graph did.
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
	t.check(float(offered) / maxf(1.0, float(possible)) > 0.6,
			"%d of %d areas that could have two routes were offered two" % [offered, possible])

# ---------------------------------------------------------------- the fan-out ---

## What a set piece needs: a small set of streets such that whichever way she goes, she meets one.
## `covering_sites()` stays segment-keyed, so a route (a chain of cells) meets a site when one of
## its cells resolves to that street.
func _test_the_fan_out_meets_every_route(t) -> void:
	for planned in _days:
		var sites := planned.tree.covering_sites()
		t.check(not sites.is_empty(), "seed %d day %d: the day has a fan-out at all"
				% [planned.map.seed_used, planned.day])
		for branch in planned.tree.branches:
			for route: Array in branch.routes:
				t.check(_route_meets(route, sites), "seed %d day %d: %s's route meets the fan-out"
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
## **A proportion rather than an absolute, since the move to cells.** "Share no cell" is a weaker
## promise than "share no street": two routes can use different cells of the very same street —
## opposite ends of it, say — that a segment-keyed covering site cannot tell apart, so a single
## street can end up covering both after all. That is a real, if rare, consequence of routes being
## finer-grained than the sites placed against them, not a bug in either — a set piece sited there
## is still met by both routes, which is a fairness contract nobody breaks.
func _test_the_fan_out_is_never_one_place(t) -> void:
	var narrow := 0
	var with_a_choice := 0
	for planned in _days:
		var choices := 0
		for branch in planned.tree.branches:
			if branch.has_a_choice():
				choices += 1
		if choices == 0:
			continue
		with_a_choice += 1
		if planned.tree.covering_sites().size() < 2:
			narrow += 1
	t.check(with_a_choice > 0, "some day had a choice to check (%d)" % with_a_choice)
	t.check(float(narrow) / maxf(1.0, float(with_a_choice)) < 0.15,
			"%d of %d days with a choice narrowed the fan-out to one place" % [narrow, with_a_choice])

# ------------------------------------------------------------------- the gaps ---

## **A gap is the one street between two strands of corridor that run alongside each other.**
## *(M55, playtest 17 finding 2.)* The definition is re-derived here from `StreetNetwork` and
## `is_on_the_tree` rather than from the grid `gaps()` walks, so the two have to agree by meaning
## and not merely by sharing an implementation. Unaffected by the move to cells: a gap is still a
## whole street, found and checked at the segment level.
##
## Three clauses, and each is a way the answer could be quietly useless. It is **off the tree** —
## a placement on it would otherwise be a wall across the route. It is a **real street today**, or
## it is somewhere a calm zone absorbed and nothing can stand there. And a street of the tree
## **crosses each of its two ends**, which is the whole of *"only directly adjacent paths (with a
## single street connecting both) counts"* — at right angles, because a tree street running
## straight on through the junction is one strand carrying on rather than two lying alongside.
func _test_a_gap_joins_two_parallel_strands(t) -> void:
	var total := 0
	for planned in _days:
		for key in planned.tree.gaps():
			total += 1
			var segment := StreetNetwork.by_key(key)
			t.check(segment != null and not planned.tree.is_on_the_tree(key),
					"seed %d day %d: the gap %s is a street off the tree"
					% [planned.map.seed_used, planned.day, key])
			t.check(not planned.map.blocked_segments().has(key),
					"seed %d day %d: and one the city still has (%s)"
					% [planned.map.seed_used, planned.day, key])
			if not segment:
				continue
			for junction in [segment.a, segment.b]:
				t.check(_crossed_by_the_tree(planned, junction, key.z),
						"seed %d day %d: and a strand of corridor runs across %s of it"
						% [planned.map.seed_used, planned.day, junction])
	t.check(total > 50, "the days sampled have gaps in them at all (%d)" % total)

## **A gap is a hole in the middle of the rim, not most of it**, which is the whole reason it is
## worth weighting separately: a preference that applied to half the band it sits in would not be a
## preference.
func _test_a_gap_is_a_small_part_of_the_rim(t) -> void:
	for planned in _days:
		var rim := {}
		for key in planned.tree.rim():
			rim[key] = true
		var gaps := planned.tree.gaps()
		for key in gaps:
			t.check(rim.has(key), "seed %d day %d: the gap %s is on the rim"
					% [planned.map.seed_used, planned.day, key])
		t.check(gaps.size() * 2 < maxi(1, rim.size()),
				"seed %d day %d: and the rim is mostly not gaps (%d of %d)"
				% [planned.map.seed_used, planned.day, gaps.size(), rim.size()])

## Whether a street of the tree meets this junction at right angles to a street running `along`.
func _crossed_by_the_tree(planned: Day, junction: Vector2i, along: int) -> bool:
	for segment in StreetNetwork.at_junction(junction):
		var key := segment.key()
		if key.z != along and planned.tree.is_on_the_tree(key):
			return true
	return false

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
					and _cells(again.branches[i]) == _cells(planned.tree.branches[i]),
					"seed %d day %d: and the same cells for %s"
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
			if _cells(branch) != _cells(other):
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

const _NEIGHBOUR_OFFSETS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

## Every grid node bordering the home street's own tiles — restated independently of
## `RouteTree.grow`, which computes the same thing, rather than exposed from it.
func _home_nodes(planned: Day) -> Dictionary:
	var found := {}
	for tile in planned.map.rect_tiles(planned.home.tile_rect()):
		var node := planned.tree.grid.node_at(tile)
		if node >= 0:
			found[node] = true
	return found

## Every grid node bordering `area`'s own calm ground from outside it — restated independently of
## `RouteTree._access_nodes` for the same reason.
##
## **Reads `planned.tree.grid` and nothing off `planned.map` itself.** `_plan()` shares one `map`
## across every day of a seed and repaints it for each in turn, so by the time the tests run it
## holds whichever day was planned last — `Tile.is_calm(planned.map.tile_at(tile))` would ask
## today's question of a map painted for a different day. `area` already being in `planned.areas`
## is the day-correct fact that every tile of `area.rect` was calm the day it was planned; the
## frozen grid built at that same moment is what answers "walkable" without asking the map again.
func _access_nodes(planned: Day, area: ClosurePlanner.CalmArea) -> Dictionary:
	var found := {}
	for tile in planned.map.rect_tiles(area.rect):
		for offset in _NEIGHBOUR_OFFSETS:
			var neighbour := tile + offset
			if area.rect.has_point(neighbour):
				continue
			var node := planned.tree.grid.node_at(neighbour)
			if node >= 0:
				found[node] = true
	return found

func _area_of(planned: Day, block: Vector2i) -> ClosurePlanner.CalmArea:
	for area in planned.areas:
		if area.block == block:
			return area
	return null

const _CELL_TILE_OFFSETS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1),
		Vector2i(1, 1)]

## A walkable tile of `cell`, whichever one it is. **Never assume the origin (north-west) tile is
## the walkable one** — a one-tile building sliver can sit in any corner, and a cell whose sliver
## happens to be its own north-west tile would otherwise look unwalkable from every check here.
func _walkable_tile_of_cell(planned: Day, cell: Vector2i) -> Vector2i:
	var origin := cell * ReachabilityGrid.CELL
	for offset in _CELL_TILE_OFFSETS:
		var tile := origin + offset
		if planned.tree.grid.node_at(tile) >= 0:
			return tile
	return origin

func _node_of_cell(planned: Day, cell: Vector2i) -> int:
	return planned.tree.grid.node_at(_walkable_tile_of_cell(planned, cell))

func _grid_adjacent(planned: Day, a: Vector2i, b: Vector2i) -> bool:
	var target := _node_of_cell(planned, b)
	for edge: Array in planned.tree.grid.neighbours(_node_of_cell(planned, a)):
		if (edge[0] as int) == target:
			return true
	return false

func _adjacent_to_any(planned: Day, node: int, targets: Dictionary) -> bool:
	for edge: Array in planned.tree.grid.neighbours(node):
		if targets.has(edge[0]):
			return true
	return false

func _cells(branch: RouteTree.Branch) -> Array:
	var found: Array = []
	for route: Array in branch.routes:
		found.append_array(route)
	return found

func _route_meets(route: Array, sites: Array[Vector3i]) -> bool:
	for cell: Vector2i in route:
		var segment := StreetNetwork.segment_containing(cell * ReachabilityGrid.CELL)
		if segment and sites.has(segment.key()):
			return true
	return false

func _covers_everything(tree: RouteTree, sites: Array[Vector3i]) -> bool:
	for branch in tree.branches:
		for route: Array in branch.routes:
			if not _route_meets(route, sites):
				return false
	return true
