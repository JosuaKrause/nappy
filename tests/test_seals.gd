extends RefCounted
## `SealPlanner`: every street off the day's tree carries a seal, the tree and the doorstep never
## do, and sealing never breaks the day's own winnability.
##
## `docs/TODO.md`, M64, "Place a seal off the tree, on every segment" is the design;
## `src/routes/seal_planner.gd` is the implementation. The winnability check here is a hard
## assertion rather than a measurement on purpose — `SealPlanner`'s own class doc explains why: a
## seal never stands on tree ground or the doorstep, so nothing it does can cut the one route the
## day already guarantees, and a failure here would mean that construction itself is broken rather
## than an unlucky placement to repair.

const SEEDS := 6
const BASE_SEED := 71717

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 91))
	_test_every_off_tree_street_is_sealed(t)
	_test_the_tree_and_the_doorstep_are_never_sealed(t)
	_test_the_tree_itself_is_untouched(t)
	_test_the_doorstep_reaches_the_corridor(t)
	_test_a_day_is_still_winnable_under_every_seal(t)
	_test_alley_mouths_sealed_only_when_disconnected_from_the_tree(t)
	_test_candidate_shapes(t)
	_test_day_one_has_a_working_soft_pair(t)

# ------------------------------------------------------------------------ setup ---

func _repaint_for(map: CityMap, day: int) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)

func _seal_rng(map: CityMap, day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
	return rng

## Every real, non-home, off-tree street — what a day's seals are supposed to cover exactly.
func _candidate_segments(map: CityMap, tree: RouteTree,
		home: StreetNetwork.Segment) -> Dictionary:
	var found := {}
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if not map.has_street(key) or tree.is_on_the_tree(key):
			continue
		if home and key == home.key():
			continue
		found[key] = true
	return found

## Every street a plan's position actually resolves to. A plan whose position is not on any
## street — an alley mouth — contributes nothing here on purpose; see `_sealed_alley_tiles`.
func _sealed_segments(map: CityMap, planned: Array[EventScheduler.Planned]) -> Dictionary:
	var found := {}
	for plan in planned:
		var segment := StreetNetwork.segment_containing(map.world_to_tile(plan.position))
		if segment:
			found[segment.key()] = true
	return found

# ---------------------------------------------------------------------- the core ---

## The whole point: a seal stands on every off-tree, real, non-home street, and nowhere else.
func _test_every_off_tree_street_is_sealed(t) -> void:
	for map in _maps:
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var home := ClosurePlanner.home_street(map)
			var candidates := _candidate_segments(map, tree, home)
			var planned := SealPlanner.plan_day(map, day, tree, _seal_rng(map, day))
			var sealed := _sealed_segments(map, planned)

			var missing := 0
			for key in candidates:
				if not sealed.has(key):
					missing += 1
			t.check(missing == 0,
					"seed %d day %d: %d off-tree streets carry no seal (of %d candidates)"
					% [map.seed_used, day, missing, candidates.size()])

			var extra := 0
			for key in sealed:
				if not candidates.has(key):
					extra += 1
			t.check(extra == 0,
					"seed %d day %d: %d seals stand on a street that was never a candidate"
					% [map.seed_used, day, extra])

func _test_the_tree_and_the_doorstep_are_never_sealed(t) -> void:
	for map in _maps:
		for day in [1, 7, 14]:
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var home := ClosurePlanner.home_street(map)
			var planned := SealPlanner.plan_day(map, day, tree, _seal_rng(map, day))
			for plan in planned:
				var segment := StreetNetwork.segment_containing(map.world_to_tile(plan.position))
				if not segment:
					continue
				t.check(not tree.is_on_the_tree(segment.key()),
						"seed %d day %d: a seal stands on the corridor itself, at %s"
						% [map.seed_used, day, segment.key()])
				t.check(not (home != null and segment.key() == home.key()),
						"seed %d day %d: a seal stands on the doorstep's own street"
						% [map.seed_used, day])

## `SealPlanner` only ever reads `tree.is_on_the_tree()` — it must never grow, shrink or move what
## the tree itself carries.
func _test_the_tree_itself_is_untouched(t) -> void:
	for map in _maps:
		var day := 5
		_repaint_for(map, day)
		var tree := RouteTree.for_day(map, day)
		var before := tree.cells()
		SealPlanner.plan_day(map, day, tree, _seal_rng(map, day))
		var after := tree.cells()
		t.check(before.size() == after.size(),
				"seed %d: sealing does not add or remove tree cells (%d before, %d after)"
				% [map.seed_used, before.size(), after.size()])
		var before_set := {}
		for cell in before:
			before_set[cell] = true
		var moved := 0
		for cell in after:
			if not before_set.has(cell):
				moved += 1
		t.check(moved == 0,
				"seed %d: sealing does not change which cells the tree carries" % map.seed_used)

# ------------------------------------------------------------------- the doorstep ---

## Playtest 22, finding 5: `SealPlanner.plan_day` exempts the home street itself, but nothing used
## to protect the join between it and the rest of the tree — every street the home street led to
## could be off-tree and therefore sealed. `RouteTree._grow_the_trunk()` is the fix: it always
## finds a way from the home street to a cell already on the tree, so at least one of the streets
## meeting the home street's own two junctions is `is_on_the_tree()` — which is exactly the ground
## `SealPlanner` never seals. Checked directly against `is_on_the_tree()` rather than against
## `SealPlanner`'s output, because the guarantee belongs to the tree and holds before any seal is
## placed at all.
func _test_the_doorstep_reaches_the_corridor(t) -> void:
	var used_the_spine := 0
	var total := 0
	for map in _maps:
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			_repaint_for(map, day)
			var home := ClosurePlanner.home_street(map)
			var tree := RouteTree.for_day(map, day)
			if tree.branches.is_empty():
				continue
			total += 1
			if tree.trunk_used_the_spine:
				used_the_spine += 1
			var joined := false
			for junction in [home.a, home.b]:
				for segment in StreetNetwork.at_junction(junction):
					if segment.key() != home.key() and tree.is_on_the_tree(segment.key()):
						joined = true
			t.check(joined,
					"seed %d day %d: a street meeting the doorstep's own junctions is on the tree"
					% [map.seed_used, day])
	# Not a pass/fail bound — the fraction is a fact about the map (whether home was generated
	# beside the main road), not about a defect: the trunk falls back to it only where every other
	# way out of the home street is unreachable without it. Reported so the rate is visible.
	t.check(total > 0, "%d of %d sampled days needed the main road to join the doorstep to the tree"
			% [used_the_spine, total])

# ------------------------------------------------------------------ winnability ---

func _add_circle(map: CityMap, blocked: Dictionary, at: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	var reach := ceili(radius / float(Tuning.TILE_SIZE))
	var centre := map.world_to_tile(at)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if map.tile_to_world(tile).distance_to(at) <= radius:
				blocked[tile] = true

## The guarantee `EventScheduler._ensure_the_city_is_still_walkable` used to repair for the
## catalogue's own placements, checked here for `SealPlanner`'s instead — see the class doc.
func _test_a_day_is_still_winnable_under_every_seal(t) -> void:
	for map in _maps:
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree)
			map.close_streets(closures)
			var seals := SealPlanner.plan_day(map, day, tree, _seal_rng(map, day))

			var grid := ReachabilityGrid.build(map)
			var blocked := map.closed_tiles.duplicate()
			for plan in seals:
				_add_circle(map, blocked, plan.position, plan.def.obstructs_radius)

			var reached := grid.flood([map.home_rect.position], blocked)
			var reachable := false
			for tile in map.calm_tiles():
				if grid.reaches(tile, blocked, reached):
					reachable = true
					break
			t.check(reachable,
					"seed %d day %d: some calm area is still reachable with every seal in place"
					% [map.seed_used, day])

# ------------------------------------------------------------------------ alleys ---

## An alley that touches the tree at either end is left open; one that touches it at neither is
## walled at both mouths. Re-derives the same rule `SealPlanner._seal_alley_mouths` uses and
## checks the plans agree with it, which is what catches the rule and the placement drifting
## apart from each other rather than only catching one of them being wrong on its own.
func _test_alley_mouths_sealed_only_when_disconnected_from_the_tree(t) -> void:
	for map in _maps:
		var day := 6
		_repaint_for(map, day)
		var tree := RouteTree.for_day(map, day)
		var planned := SealPlanner.plan_day(map, day, tree, _seal_rng(map, day))
		var off_street_tiles := {}
		for plan in planned:
			var tile := map.world_to_tile(plan.position)
			if not StreetNetwork.segment_containing(tile):
				off_street_tiles[tile] = true

		var checked := 0
		for rect in map.alley_rects:
			if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
				continue
			checked += 1
			var vertical := rect.size.x < rect.size.y
			var block := map.block_at(map.tile_rect_to_world(rect).get_center())
			var side_a: int = StreetNetwork.Side.NORTH if vertical else StreetNetwork.Side.WEST
			var side_b: int = StreetNetwork.Side.SOUTH if vertical else StreetNetwork.Side.EAST
			var segment_a := StreetNetwork.beside_block(block, side_a)
			var segment_b := StreetNetwork.beside_block(block, side_b)
			var rejoins := (segment_a != null and tree.is_on_the_tree(segment_a.key())) \
					or (segment_b != null and tree.is_on_the_tree(segment_b.key()))
			var sealed_here := false
			for tile in off_street_tiles:
				if rect.has_point(tile):
					sealed_here = true
					break
			t.check(sealed_here != rejoins,
					"seed %d day %d: alley at %s sealed=%s rejoins the tree=%s (should differ)"
					% [map.seed_used, day, rect.position, sealed_here, rejoins])
		t.check(checked >= 0, "seed %d day %d: %d through-alleys checked" % [map.seed_used, day, checked])

# --------------------------------------------------------------------- candidates ---

func _test_candidate_shapes(t) -> void:
	for candidate in SealPlanner.candidates():
		var wanted := 1 if candidate.strength == SealPlanner.Strength.HARD else 2
		t.check(candidate.def_ids.size() == wanted,
				"seal candidate %s names %d def(s), want %d for its strength"
				% [candidate.id, candidate.def_ids.size(), wanted])
		for id in candidate.def_ids:
			var def := EventCatalogue.by_id(id)
			t.check(def != null, "seal candidate %s names an unknown row %s" % [candidate.id, id])
			if def:
				t.check(def.obstructs_radius > 0.0,
						"seal candidate %s's row %s obstructs nothing, so it cannot seal anything"
						% [candidate.id, id])

## The milestone's own requirement: the catalogue can seal a street from day 1, with nothing new
## drawn. `SealPlanner._eligible` is the same check `_pick_candidate` uses at dawn, asked here
## directly rather than re-derived, so this fails the day the candidate list stops honouring it.
func _test_day_one_has_a_working_soft_pair(t) -> void:
	var has_soft := false
	for candidate in SealPlanner.candidates():
		if candidate.strength == SealPlanner.Strength.SOFT and SealPlanner._eligible(candidate, 1):
			has_soft = true
	t.check(has_soft, "day 1 has at least one working soft seal pair")
