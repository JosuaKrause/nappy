extends RefCounted
## Block purposes and the arcs they travel.
##
## This is where the invariant M15 replaced gets checked. The old rule was that the
## `CityMap` is immutable for the run; the new one is weaker and still load-bearing:
##
##     the street lattice and the block boundaries are fixed for the run;
##     what a block *is* may change, and only ever along the arc the generator planned.
##
## The first half is testable and is tested here, hard: pushing every block to the end of
## its arc must not move a single walkable tile. The geometry the player learns stays true
## whatever happens to the city on top of it.

const SEEDS := 24
const BASE_SEED := 90210
const CITY_SCENE := preload("res://scenes/world/city.tscn")

## Generated once and shared. Each of these tests wants the same sweep, and generating a
## city is the expensive part of this suite by a wide margin.
var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 7))
	_test_every_block_has_an_arc(t)
	_test_arcs_only_move_forward(t)
	_test_enough_calm_survives_the_whole_run(t)
	_test_a_cause_only_fires_where_the_arc_expects_it(t)
	_test_purposes_never_change_what_is_walkable(t)
	_test_a_requisitioned_block_stops_being_calm(t)
	_test_a_courtyard_can_be_reached(t)
	_test_the_same_seed_plans_the_same_arcs(t)
	_test_park_trees_keep_their_distance(t)
	_test_tree_runs_are_straight_runs_of_three_to_five(t)
	_test_tree_runs_are_fixed_for_the_seed(t)
	_test_tree_lined_streets_stay_rare(t)
	_test_pits_keep_their_spacing_across_a_whole_run(t)
	_test_a_pit_is_never_on_a_junction_or_a_mouth(t)
	_test_the_planner_and_the_prop_agree_on_a_tree_footprint(t)

func _map(index: int = 0) -> CityMap:
	return _maps[index]

## Every block belongs to exactly one lot, and every lot has a plan starting on day 1.
##
## Since M21 a lot is not always a block: a four-block calm zone is one entry in `block_plans`
## and four blocks of ground, and the three it absorbed appear only in `zone_anchor`. The two
## sets have to partition the city between them — a block in neither is ground nothing paints,
## and a block in both is a park with a building in the middle of it.
func _test_every_block_has_an_arc(t) -> void:
	var map := _map()
	var absorbed := map.zone_anchor.size() - map.zone_rects.size()
	t.check(map.block_plans.size() + absorbed == Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y,
			"every block is in exactly one lot (%d lots, %d absorbed)"
			% [map.block_plans.size(), absorbed])
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			t.check(map.block_plans.has(map.anchor_of(block)),
					"block %s belongs to a lot with an arc" % block)
	for block: Vector2i in map.block_plans:
		var plan: BlockPlan = map.block_plans[block]
		t.check(plan.steps.size() >= 1, "block %s has at least a starting purpose" % block)
		t.check(plan.steps[0].from_day == 1, "block %s starts on day 1" % block)
		t.check(plan.steps[0].cause == GameEnums.BlockCause.SCHEDULED,
				"block %s does not need a cause to be what it starts as" % block)

## An arc is a line, not a tree: it never goes backwards in time, so a player who learns
## that a boarded-up street is on its way to something worse is never wrong about the order.
func _test_arcs_only_move_forward(t) -> void:
	for i in SEEDS:
		var map := _map(i)
		for block: Vector2i in map.block_plans:
			var plan: BlockPlan = map.block_plans[block]
			var previous := 0
			for step: BlockPlan.Step in plan.steps:
				t.check(step.from_day >= previous,
						"seed %d block %s: arc days never go backwards" % [map.seed_used, block])
				previous = step.from_day
				t.check(step.from_day <= Tuning.RUN_LENGTH_DAYS,
						"seed %d block %s: no step is scheduled past the run"
						% [map.seed_used, block])

## The hard floor. A day can only be won on calm ground, so an arc set that takes all of it
## makes an unwinnable run rather than a hard one. Checked on the *last* day, with every
## scheduled step taken and every event-caused one forced, which is the worst case.
func _test_enough_calm_survives_the_whole_run(t) -> void:
	for i in SEEDS:
		var map := _map(i)
		var state := _worst_case(map)
		var calm := state.calm_blocks(map.block_plans)
		t.check(calm.size() >= Tuning.MIN_CALM_BLOCKS_AT_END,
				"seed %d ends the run with %d calm blocks, needs %d"
				% [map.seed_used, calm.size(), Tuning.MIN_CALM_BLOCKS_AT_END])

## A fire in a block whose plan has no fire in it leaves the shell and changes nothing else.
## Without this a scar anywhere would drag every block it touched along somebody else's arc.
func _test_a_cause_only_fires_where_the_arc_expects_it(t) -> void:
	var map := _map()
	var state := CityState.new()
	state.begin_day(map.block_plans, 1)

	var unmoved := 0
	for block: Vector2i in map.block_plans:
		var before := state.purpose_of(map.block_plans, block)
		# Day 1 is before every fire step's from_day, so nothing may move.
		state.apply_cause(map.block_plans, block, GameEnums.BlockCause.FIRE, 1)
		if state.purpose_of(map.block_plans, block) == before:
			unmoved += 1
	t.check(unmoved == map.block_plans.size(),
			"a cause before its arc's day moves nothing (%d of %d moved)"
			% [map.block_plans.size() - unmoved, map.block_plans.size()])

	# And a calm block has no fire step at all, whatever day it is.
	var calm_unmoved := true
	for block in map.calm_blocks:
		var before := state.purpose_of(map.block_plans, block)
		state.apply_cause(map.block_plans, block, GameEnums.BlockCause.FIRE,
				Tuning.RUN_LENGTH_DAYS)
		if state.purpose_of(map.block_plans, block) != before:
			calm_unmoved = false
	t.check(calm_unmoved, "a fire in a park does not turn the park into a burnt-out block")

## The replacement invariant, stated as a test. Push every block to the end of its arc and
## the set of walkable tiles must be identical, tile for tile. No requisition, boarding or
## fire can seal a street, open a shortcut, or move the route the player learned on day 1.
func _test_purposes_never_change_what_is_walkable(t) -> void:
	for i in SEEDS:
		var map := _map(i)
		var before := _walkable_set(map)
		map.repaint(_worst_case(map))
		var after := _walkable_set(map)
		t.check(before == after,
				"seed %d: the whole run's worth of change moves no walkable tile"
				% map.seed_used)

## Requisitioning is the point of the whole mechanism: the same ground, no longer calm.
func _test_a_requisitioned_block_stops_being_calm(t) -> void:
	var found := false
	for i in SEEDS:
		var map := _map(i)
		var state := _worst_case(map)
		map.repaint(state)
		for block: Vector2i in map.block_plans:
			if state.purpose_of(map.block_plans, block) \
					!= GameEnums.BlockPurpose.REQUISITIONED:
				continue
			found = true
			var layout: BlockLayout = map.block_layouts[block]
			for tile in map.rect_tiles(layout.open_rect):
				t.check(not Tile.is_calm(map.tile_at(tile)),
						"seed %d: requisitioned block %s has no calm ground left"
						% [map.seed_used, block])
				t.check(map.is_walkable(tile),
						"seed %d: requisitioned block %s is still walkable"
						% [map.seed_used, block])
		if found:
			return
	t.check(found, "at least one seed in the sweep requisitions something")

## A court with no way in is a hole in the map. The first version of courtyards was exactly
## that and failed the connectivity check on every seed; the archway is why it does not.
func _test_a_courtyard_can_be_reached(t) -> void:
	for i in SEEDS:
		var map := _map(i)
		var reachable := map.walk_field(map.home_rect.position)
		for rect in map.courtyard_rects:
			for tile in map.rect_tiles(rect):
				t.check(map.reaches(reachable, tile),
						"seed %d: courtyard tile %s is reachable from home"
						% [map.seed_used, tile])

func _test_the_same_seed_plans_the_same_arcs(t) -> void:
	var first := CityGenerator.generate(BASE_SEED + 21)
	var second := CityGenerator.generate(BASE_SEED + 21)
	var same := first.block_plans.size() == second.block_plans.size()
	for block: Vector2i in first.block_plans:
		var a: BlockPlan = first.block_plans[block]
		var b: BlockPlan = second.block_plans.get(block)
		if not b or a.steps.size() != b.steps.size():
			same = false
			break
		for step in a.steps.size():
			if a.steps[step].purpose != b.steps[step].purpose \
					or a.steps[step].from_day != b.steps[step].from_day \
					or a.steps[step].cause != b.steps[step].cause:
				same = false
	t.check(same, "the same seed plans the same arcs")

## Rejection sampling with no spacing test let two trees land close enough to read as one canopy.
## `_dress_block` now rejects a candidate within `City.MIN_TREE_SPACING` of one it already planted
## in the same lot, so this drives the real placement pipeline — a built `City`, a real `start_day`
## — across a few seeds and checks every pair of trees `CityMap.anchor_of` puts in the same lot,
## which is what the clump would actually have been caught by rather than a unit test of the
## rejection alone.
func _test_park_trees_keep_their_distance(t) -> void:
	var checked_any_pair := false
	for seed_value in [BASE_SEED, BASE_SEED + 7, BASE_SEED + 14]:
		var map := CityGenerator.generate(seed_value)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var state := CityState.new()
		state.begin_day(map.block_plans, 1)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("m100-tree-spacing:%d" % seed_value)
		city.start_day(state, 1, rng)

		# Grouped by the lot's own anchor (`CityMap.anchor_of`), not by which of a zone's four
		# blocks a tree happens to sit on — a four-block calm zone is one lot, and `_dress_block`'s
		# own spacing check only ever compares trees it placed in the same call.
		var by_lot := {}
		for prop in city.props():
			if prop.kind != Prop.Kind.TREE:
				continue
			var anchor: Vector2i = map.anchor_of(map.block_at(prop.position))
			var lot: Array = by_lot.get(anchor, [])
			lot.append(prop.position)
			by_lot[anchor] = lot

		for anchor in by_lot:
			var trees: Array = by_lot[anchor]
			for i in trees.size():
				for j in range(i + 1, trees.size()):
					checked_any_pair = true
					var apart: float = trees[i].distance_to(trees[j])
					t.check(apart >= City.MIN_TREE_SPACING,
							"seed %d lot %s: two trees %.1fpx apart, under the %.1fpx floor"
							% [seed_value, anchor, apart, City.MIN_TREE_SPACING])
		city.free()
	t.check(checked_any_pair, "at least one lot across these seeds had more than one tree to check")

# -------------------------------------------------------------- street trees ---

## The shape the player asked for: *"continuous segments of 3/4/5 blocks randomly placed on the
## map in both directions"*. A run is straight by construction — one corridor index, consecutive
## blocks — so what is worth asserting is that construction holds against a real lattice: every
## street of every run is a real ordinary street, no run is shorter or longer than the bounds, no
## two runs share a street, and both directions actually occur across a sweep.
func _test_tree_runs_are_straight_runs_of_three_to_five(t) -> void:
	var horizontal_seen := false
	var vertical_seen := false
	var total := 0
	for map in _maps:
		var taken := {}
		for run in StreetTrees.runs(map):
			total += 1
			horizontal_seen = horizontal_seen or run.horizontal
			vertical_seen = vertical_seen or not run.horizontal
			t.check(run.length >= Tuning.STREET_TREE_RUN_MIN_BLOCKS \
					and run.length <= Tuning.STREET_TREE_RUN_MAX_BLOCKS,
					"seed %d: a run is %d blocks long, outside %d-%d"
					% [map.seed_used, run.length, Tuning.STREET_TREE_RUN_MIN_BLOCKS,
					Tuning.STREET_TREE_RUN_MAX_BLOCKS])
			var keys := run.segment_keys()
			t.check(keys.size() == run.length, "seed %d: a run names one street per block"
					% map.seed_used)
			for i in keys.size():
				var key: Vector3i = keys[i]
				t.check(not taken.has(key),
						"seed %d: street %s is in two runs at once" % [map.seed_used, key])
				taken[key] = true
				t.check(map.has_street(key),
						"seed %d: a run covers %s, which is not a street this city has"
						% [map.seed_used, key])
				var segment := StreetNetwork.by_key(key)
				t.check(segment != null and segment.horizontal == run.horizontal,
						"seed %d: a run's streets all run the same way" % map.seed_used)
				if i > 0:
					var previous: Vector3i = keys[i - 1]
					var step := Vector2i(key.x, key.y) - Vector2i(previous.x, previous.y)
					t.check(step == (Vector2i.RIGHT if run.horizontal else Vector2i.DOWN),
							"seed %d: a run's blocks are consecutive along one line" % map.seed_used)
	t.check(total > 0, "there were runs to check (%d across %d seeds)" % [total, SEEDS])
	t.check(horizontal_seen and vertical_seen,
			"runs are placed in both directions across the sweep")

## Trees are geometry she learns, so they are fixed for the run like a building: the same seed
## has to give the same runs and the same pits, whatever order anybody asks in.
func _test_tree_runs_are_fixed_for_the_seed(t) -> void:
	var map := CityGenerator.generate(BASE_SEED)
	var again := CityGenerator.generate(BASE_SEED)
	var first := StreetTrees.planted(map)
	var second := StreetTrees.planted(again)
	var third := StreetTrees.planted(map)
	t.check(first.size() == second.size() and first.size() == third.size(),
			"the same seed plants the same number of trees (%d, %d, %d)"
			% [first.size(), second.size(), third.size()])
	var same := true
	for i in mini(first.size(), second.size()):
		if first[i].position != second[i].position or first[i].segment_key != second[i].segment_key:
			same = false
	t.check(same, "the same seed plants the same trees in the same pits")

## **Rare, in the player's word** *(2026-09-12: "trees must be quite rare to be able to still place
## vans restaurants etc.")*. This is the ceiling `Tuning.STREET_TREE_RUNS` is chosen under, not a
## restatement of it: raising the run count is allowed right up to the point where a tree-lined
## street stops being the exception, and this is the point.
func _test_tree_lined_streets_stay_rare(t) -> void:
	var worst := 0.0
	var ordinary_total := 0
	for map in _maps:
		var ordinary := 0
		for segment in StreetNetwork.segments():
			if map.has_street(segment.key()) \
					and StreetTrees._street_kind_of(map, segment) == GameEnums.StreetKind.ORDINARY:
				ordinary += 1
		ordinary_total += ordinary
		var lined := StreetTrees.segment_keys_with_trees(map).size()
		var fraction := float(lined) / float(maxi(1, ordinary))
		worst = maxf(worst, fraction)
		t.check(fraction <= Tuning.STREET_TREE_MAX_LINED_FRACTION,
				"seed %d: %d of %d ordinary streets are tree-lined (%.1f%%), over the %.0f%% cap"
				% [map.seed_used, lined, ordinary, 100.0 * fraction,
				100.0 * Tuning.STREET_TREE_MAX_LINED_FRACTION])
	t.check(ordinary_total > 0, "there were ordinary streets to ask about (%d)" % ordinary_total)
	t.check(worst > 0.0, "and at least one seed had trees at all (worst %.3f)" % worst)

## The spacing is measured over the **run**, not over one street — which is the whole difference
## between "a pit every other lot-length" and "a pit every other lot-length within each block".
## Checked per kerb line, since the two kerbs of a street are two independent rows.
func _test_pits_keep_their_spacing_across_a_whole_run(t) -> void:
	var pairs := 0
	for map in _maps:
		var by_line := {}
		for tree in StreetTrees.planted(map):
			var horizontal := tree.segment_key.z == 0
			# One key per kerb line: the axis, the cross coordinate the row stands on, and nothing
			# about which street of the run a given pit belongs to.
			var line := Vector3i(1 if horizontal else 0,
					tree.tile.y if horizontal else tree.tile.x, 0)
			var row: Array = by_line.get(line, [])
			row.append(tree.position.x if horizontal else tree.position.y)
			by_line[line] = row
		for line in by_line:
			var row: Array = by_line[line]
			row.sort()
			for i in range(row.size() - 1):
				pairs += 1
				var apart: float = row[i + 1] - row[i]
				t.check(apart >= Tuning.STREET_TREE_PIT_SPACING,
						"seed %d: two pits on one kerb line %.0fpx apart, under the %.0fpx floor"
						% [map.seed_used, apart, Tuning.STREET_TREE_PIT_SPACING])
	t.check(pairs > 0, "there were neighbouring pits to measure (%d)" % pairs)

## The mouth margin is what keeps a pit off a crossing and off a checkpoint's own doorway, and it
## has to keep holding inside a run — a run's junctions are the places two of its streets meet, so
## they are exactly where a naive walk along the line would plant one.
func _test_a_pit_is_never_on_a_junction_or_a_mouth(t) -> void:
	var checked := 0
	for map in _maps:
		for tree in StreetTrees.planted(map):
			checked += 1
			var horizontal := tree.segment_key.z == 0
			var along: int = tree.tile.x if horizontal else tree.tile.y
			var within := posmod(along, CityMap.period())
			t.check(within >= Tuning.STREET_WIDTH,
					"seed %d: a pit at %s stands in a junction" % [map.seed_used, tree.tile])
			var into_block := within - Tuning.STREET_WIDTH
			t.check(into_block >= 1 and into_block <= Tuning.BLOCK_SIZE - 2,
					"seed %d: a pit at %s stands in a street mouth" % [map.seed_used, tree.tile])
	t.check(checked > 0, "there were pits to check (%d)" % checked)

## `StreetTrees.footprint_radius()` is what the scheduler and the seals keep clear, and it is
## computed from `Prop`'s own textures rather than read off a live prop, because every caller is a
## headless planner with no scene. This is the thing that stops the copy drifting: a real street
## tree, built by a real `City`, has to carry exactly the shape the planners assumed.
func _test_the_planner_and_the_prop_agree_on_a_tree_footprint(t) -> void:
	var map := CityGenerator.generate(BASE_SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	var checked := 0
	for prop in city.props():
		if prop.kind != Prop.Kind.STREET_TREE:
			continue
		checked += 1
		t.check(prop.shape != null and prop.shape.reach() <= StreetTrees.footprint_radius() + 0.001,
				"a street tree reaches %.2fpx, over the %.2fpx the planners keep clear"
				% [prop.shape.reach() if prop.shape else -1.0, StreetTrees.footprint_radius()])
	t.check(checked > 0, "the city built street trees to check (%d)" % checked)
	city.free()

# ------------------------------------------------------------------ helpers ---

## The end of the run with everything that could happen having happened: every scheduled
## step taken and every event-caused step forced.
func _worst_case(map: CityMap) -> CityState:
	var state := CityState.new()
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		state.begin_day(map.block_plans, day)
		for block: Vector2i in map.block_plans:
			state.apply_cause(map.block_plans, block, GameEnums.BlockCause.FIRE, day)
			state.apply_cause(map.block_plans, block, GameEnums.BlockCause.MILITARY, day)
	return state

func _walkable_set(map: CityMap) -> Dictionary:
	var walkable := {}
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.is_walkable(tile):
				walkable[tile] = true
	return walkable
