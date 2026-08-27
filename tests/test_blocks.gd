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
		var reachable := map.walk_distances(map.home_rect.position)
		for rect in map.courtyard_rects:
			for tile in map.rect_tiles(rect):
				t.check(reachable.has(tile),
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
