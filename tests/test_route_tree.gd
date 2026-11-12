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

func run(t: TestRunner) -> void:
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		for day: int in DAYS:
			_days.append(_plan(map, day))
	_test_a_route_is_a_walk_from_the_calm_to_the_door(t)
	_test_the_tree_only_uses_streets_that_are_there(t)
	_test_no_route_runs_along_the_main_road(t)
	_test_a_route_crosses_a_carriageway_only_at_a_junction(t)
	_test_the_two_routes_of_one_area_share_no_cell(t)
	_test_a_tile_says_which_branches_it_carries(t)
	_test_different_areas_share_ground(t)
	_test_every_reachable_calm_area_is_on_the_tree(t)
	_test_a_second_route_is_offered_where_the_map_allows_one(t)
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
func _test_a_route_is_a_walk_from_the_calm_to_the_door(t: TestRunner) -> void:
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
## **Not off every *absent* street any more.** The streets the tree walks (`streets_on_the_walk()`,
## the day's walk as `RouteSource` asks it) are every segment a cell of the tree resolves to,
## including one a calm zone painted over — and the tree can legitimately cut across exactly that
## ground now, since it is walkable park rather than a barrier. `planned.blocked`
## conflates absent and closed-today; only the closed half is still a real exclusion.
func _test_the_tree_only_uses_streets_that_are_there(t: TestRunner) -> void:
	for planned in _days:
		for segment in planned.tree.streets_on_the_walk():
			var key := segment.key()
			if not planned.map.has_street(key):
				continue
			t.check(not planned.blocked.has(key),
					"seed %d day %d: the tree stays off shut streets (%s)"
					% [planned.map.seed_used, planned.day, key])
			t.check(key != planned.home.key(),
					"seed %d day %d: and off the doorstep itself, which is not a route"
					% [planned.map.seed_used, planned.day])

## *(2026-09-03, playtest 22: "a path should never go alongside the main road — main road by
## itself can be considered a blocker — paths can only cross the main road"; 2026-09-14, the
## player: "why not just remove the street tiles and main street blocks from the graph entirely?")*
##
## The spine is out of the graph the growth walks, everywhere but at a junction — so the claim is
## no longer *no two consecutive cells step along it* but the stronger and simpler *no route cell
## stands on it at all unless it is inside a junction box*, which is where crossing is legal and
## where a zebra or a signalled line stands.
##
## **Restated independently of `RouteTree`'s own filter rather than calling it**, for the reason
## `_home_nodes` above is restated rather than exposed: a check that shares the rule's own code
## cannot catch the rule being wrong. Which corridor is the main road and which tiles are a
## junction box are asked of `CityMap.street_kind_at` and `CityMap.junction_at` directly, and every
## tile of a route's cell is asked rather than its origin alone, so a cell half on the spine could
## not slip through.
func _test_no_route_runs_along_the_main_road(t: TestRunner) -> void:
	for planned in _days:
		if planned.map.main_road < 0:
			continue
		for branch in planned.tree.branches:
			for route: Array in branch.routes:
				for cell: Vector2i in route:
					for offset in _CELL_TILE_OFFSETS:
						var tile: Vector2i = cell * ReachabilityGrid.CELL + offset
						if planned.map.street_kind_at(true, tile) != GameEnums.StreetKind.MAIN:
							continue
						t.check(CityMap.junction_at(tile) != Vector2i(-1, -1),
								("seed %d day %d: %s's route stands on the main road only where " +
								"it crosses at a junction (%s)")
								% [planned.map.seed_used, planned.day, branch.area, tile])

## **A route crosses a carriageway only at a junction.** *(2026-09-13, PLAYTEST-69: "the routing
## should only cross the street at intersections. in block crossings are possible in game but
## shouldn't be counted on by the routing algorithm"; 2026-09-14, the player: "why not just remove
## the street tiles and main street blocks from the graph entirely?")*
##
## **What is asserted is the ground, not the crossing**, which is how the rule is stated: a cell on
## a carriageway between two junctions is out of the graph the growth walks, so a route that never
## stands on one cannot cross mid-block whatever order its cells are in. Asking about the ground
## also catches the thing a crossing check would miss — a route running *along* a carriageway,
## which is worse than one crossing it.
##
## The carriageway is read off the tile's own type as well as its offset, because a four-block calm
## zone paints grass over the street between its blocks and those tiles sit at a road offset while
## being somewhere she walks; a precinct has no carriageway at all. Both are ground the corridor is
## meant to be able to take.
##
## **It cannot pass vacuously**: a sample whose routes never went near a street would satisfy it
## having checked nothing, so the tiles actually examined are counted and asserted.
func _test_a_route_crosses_a_carriageway_only_at_a_junction(t: TestRunner) -> void:
	var street_tiles := 0
	var on_a_carriageway := 0
	var first := ""
	for planned in _days:
		for branch in planned.tree.branches:
			for route: Array in branch.routes:
				for cell: Vector2i in route:
					for offset in _CELL_TILE_OFFSETS:
						var tile: Vector2i = cell * ReachabilityGrid.CELL + offset
						var segment := planned.map.network.segment_containing(tile)
						if not segment:
							continue   # a junction box, or ground off the lattice
						street_tiles += 1
						var across := CityMap.corridor_offset(
								tile.y if segment.horizontal else tile.x)
						if not CityMap.is_road_offset(across):
							continue
						var type := planned.map.tile_at(tile)
						if type != GameEnums.TileType.ROAD \
								and type != GameEnums.TileType.CROSSING:
							continue   # a calm zone's absorbed street, which is grass
						on_a_carriageway += 1
						if first == "":
							first = "seed %d day %d, %s, tile %s on street %s" \
									% [planned.map.seed_used, planned.day, branch.area, tile,
									segment.key()]
	t.check(street_tiles > 500,
			"the days sampled run their routes down streets at all (%d tiles)" % street_tiles)
	t.check(on_a_carriageway == 0,
			"and no route cell stands on a carriageway between two junctions (%d does%s)"
			% [on_a_carriageway, "" if first == "" else ": " + first])

## **Same colours may not merge.** The two probes from one area can never become one path, so
## where a second route exists at all the area is reached two genuinely distinct ways. This is
## the property the whole colour mechanism exists to maintain.
func _test_the_two_routes_of_one_area_share_no_cell(t: TestRunner) -> void:
	var pairs := 0
	for planned in _days:
		for branch in planned.tree.branches:
			if branch.routes.size() < 2:
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
func _test_a_tile_says_which_branches_it_carries(t: TestRunner) -> void:
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
func _test_different_areas_share_ground(t: TestRunner) -> void:
	var bundled := 0
	var cells := 0
	for planned in _days:
		cells += planned.tree.cells().size()
		var shared := _bundled_cells(planned)
		bundled += shared
		t.check(shared > 0,
				"seed %d day %d: some stretch is shared by two areas"
				% [planned.map.seed_used, planned.day])
	t.check(float(bundled) / maxf(1.0, float(cells)) > 0.2,
			"%d of %d corridor cells carry more than one area" % [bundled, cells])

## Everything the day can still reach gets a corridor, because the guidance is the **set** of
## offers and the player chooses. An area with no way in today legitimately has no branch —
## which is one a closure has sealed, or one whose ways in a calm zone absorbed, or one right
## next door to the home.
func _test_every_reachable_calm_area_is_on_the_tree(t: TestRunner) -> void:
	for planned in _days:
		var home_nodes := _home_nodes(planned)
		for area in planned.areas:
			if planned.map.network.route_count(planned.home, area.access, planned.blocked, 1) < 1:
				continue
			var branch := _branch_for(planned.tree, area.block)
			# A calm area next door to the home is arrived at without walking anywhere, so it has
			# no corridor and is not a branch. See `RouteTree._is_no_route`.
			if not branch:
				var access := _access_nodes(planned, area)
				var next_to_home := false
				for node: int in access:
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
func _test_a_second_route_is_offered_where_the_map_allows_one(t: TestRunner) -> void:
	var offered := 0
	var possible := 0
	for planned in _days:
		for branch in planned.tree.branches:
			var area := _area_of(planned, branch.area)
			if not area or planned.map.network.route_count(
					planned.home, area.access, planned.blocked, 2) < 2:
				continue
			possible += 1
			if branch.routes.size() >= 2:
				offered += 1
	t.check(possible > 0, "the map allowed a choice somewhere (%d)" % possible)
	t.check(float(offered) / maxf(1.0, float(possible)) > 0.6,
			"%d of %d areas that could have two routes were offered two" % [offered, possible])

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
func _test_a_gap_joins_two_parallel_strands(t: TestRunner) -> void:
	var total := 0
	for planned in _days:
		for key in planned.tree.gaps():
			total += 1
			var segment := planned.map.network.by_key(key)
			t.check(segment != null and not planned.tree.is_on_the_tree(key),
					"seed %d day %d: the gap %s is a street off the tree"
					% [planned.map.seed_used, planned.day, key])
			t.check(not planned.map.blocked_segments().has(key),
					"seed %d day %d: and one the city still has (%s)"
					% [planned.map.seed_used, planned.day, key])
			if not segment:
				continue
			for junction: Vector2i in [segment.a, segment.b]:
				t.check(_crossed_by_the_tree(planned, junction, key.z),
						"seed %d day %d: and a strand of corridor runs across %s of it"
						% [planned.map.seed_used, planned.day, junction])
	t.check(total > 50, "the days sampled have gaps in them at all (%d)" % total)

## **A gap is a hole in the middle of the rim, not most of it**, which is the whole reason it is
## worth weighting separately: a preference that applied to half the band it sits in would not be a
## preference.
func _test_a_gap_is_a_small_part_of_the_rim(t: TestRunner) -> void:
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
	for segment in planned.map.network.at_junction(junction):
		var key := segment.key()
		if key.z != along and planned.tree.is_on_the_tree(key):
			return true
	return false

# ------------------------------------------------------------- the same day ---

## A run is learnable or it is nothing, and the tree is now part of what a day *is*: the
## scheduler places against it and `TelemetryMap` draws it, so if the two grew different trees
## the picture would be of a plan nobody used.
func _test_the_same_day_grows_the_same_tree(t: TestRunner) -> void:
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
func _test_a_different_day_is_a_different_way(t: TestRunner) -> void:
	var moved := 0
	var compared := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		var first := _plan(map, 1)
		var later := _plan(map, 5)
		for branch in first.tree.branches:
			var other := _branch_for(later.tree, branch.area)
			if not other:
				continue
			compared += 1
			if _cells(branch) != _cells(other):
				moved += 1
	t.check(compared > 0, "the same calm areas exist on both days (%d)" % compared)
	t.check(float(moved) / maxf(1.0, float(compared)) > 0.5,
			"%d of %d areas are reached a different way on another day" % [moved, compared])

# ------------------------------------------------------------------ helpers ---

## The branch that reaches the calm area anchored at `area`, or null.
func _branch_for(tree: RouteTree, area: Vector2i) -> RouteTree.Branch:
	for branch in tree.branches:
		if branch.area == area:
			return branch
	return null

## How many cells of the day's tree more than one branch carries — the trunk, and any stretch
## several ways out of the city share before they separate. A bundle is what makes placement cheap:
## it narrows *how many places* a thing has to be in order to be met, and never to one.
func _bundled_cells(planned: Day) -> int:
	var found := 0
	for cell in planned.tree.cells():
		if planned.tree.branches_on(_walkable_tile_of_cell(planned, cell)).size() >= 2:
			found += 1
	return found

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
	planned.closures = ClosurePlanner.plan_day(map, DaySpec.for_day(day), rng, planned.tree)
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

