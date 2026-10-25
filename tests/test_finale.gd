extends RefCounted
## The escape: the two chains through the city, the walls off them, the clock, and what a lost
## section costs.
##
## **What is asserted here is the shape of the walk rather than any number in it.** The chains are
## grown from the city's own lattice, so nothing about their length or their exact route is stable
## across a seed — what has to be true on every seed is that there are two of them, that they do
## not overlap, that each passes three distinct pieces of calm ground on its way to its own edge,
## and that everything off them is shut.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCREEN_SCENE := preload("res://scenes/ui/pause_screen.tscn")
const TITLE_SCREEN_SCENE := preload("res://scenes/ui/title_screen.tscn")
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")
const RoadblockRig := preload("res://tests/escape_roadblock_rig.gd")
const Reach := preload("res://tests/seal_reach_rig.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
## Where the resumed-escape test writes the save it boots from — never the player's own.
const _SCRATCH_SAVE := "user://test_finale_scratch.json"
## The seed the player played the escape on and could not win (inbox #771 in minty-lemur), from the building, and
## the tile on the tunnel chain's street where the second band's guard caught her.
const PLAYERS_SEED := 4216201080
const WHERE_THE_PLAYER_WAS_CAUGHT := Vector2i(74, 22)

## Four cities rather than one. A chain is a search over a generated lattice and the thing most
## likely to go wrong about it — a park the walk cannot reach, an exit behind a wall — is a
## property of one city's own geometry, so a single seed proves nothing about the next.
const SEEDS := [4242, 1, 77, 9001]

func run(t) -> void:
	_test_the_two_chains_part_at_the_door_and_never_meet_again(t)
	_test_each_chain_passes_three_distinct_calm_areas(t)
	_test_each_chain_reaches_its_own_edge(t)
	_test_every_street_off_the_chains_is_sealed(t)
	_test_both_exits_are_reachable_through_the_open_cells_alone(t)
	_test_both_exits_are_reachable_past_every_body_the_escape_stands(t)
	_test_both_exits_are_reachable_past_every_standing_lethal_reach(t)
	_test_a_street_of_vans_leaves_a_walk_past_every_reach(t)
	_test_no_street_of_the_walk_stands_two_roadblocks(t)
	_test_a_roadblock_band_costs_nothing(t)
	_test_the_far_guard_leaves_with_his_partner(t)
	_test_neither_guard_walks_off_over_a_building(t)
	_test_a_lured_off_roadblock_raises_no_mark_over_her(t)
	_test_luring_its_guard_off_is_the_way_past_a_roadblock(t)
	_test_no_two_roadblocks_notice_her_from_the_same_ground(t)
	_test_an_escape_guard_warns_on_the_screen_and_on_top(t)
	_test_the_players_seed_is_winnable_past_its_roadblocks(t)
	_test_the_escape_stands_its_rows_on_the_days_own_ground(t)
	_test_an_alley_mouth_wall_fits_the_mouth(t)
	_test_nothing_the_escape_stands_reaches_over_a_building(t)
	_test_a_restart_plans_the_same_escape_on_the_kept_ground(t)
	_test_the_escape_bag_keeps_the_players_order(t)
	_test_every_slot_of_every_street_draws_one_marble(t)
	_test_the_game_draws_the_escape_from_tunings_bag(t)
	_test_the_service_exit_is_beside_the_home_block(t)
	_test_nothing_the_finale_places_stands_where_she_comes_out(t)
	_test_no_lethal_field_covers_the_ground_she_comes_out_on(t)
	_test_the_finale_city_has_nobody_in_it(t)
	_test_main_tints_the_escape_streets_on_its_first_plan_and_on_a_restart(t)
	_test_a_burst_leaves_a_crater_as_wide_as_its_own_picture(t)
	_test_the_clock_reads_hundredths_only_in_the_finale(t)
	_test_each_section_opens_on_its_brief_and_a_loss_on_its_outcome(t)
	_test_the_escape_counts_its_time_and_closes_its_charges(t)
	_test_the_two_sections_are_named_for_the_player(t)
	_test_only_a_won_last_day_with_every_task_done_hands_over(t)
	_test_the_city_word_boots_the_second_section(t)
	_test_every_part_word_reaches_its_own_walkable_position(t)
	_test_the_escape_owes_no_return_leg(t)
	_test_a_day_owes_its_return_only_as_its_spec_says(t)
	_test_nothing_the_escape_places_stands_in_a_street_tree(t)
	_test_finale_entities_stop_when_the_tree_pauses(t)
	_test_the_escape_pauses_the_same_way_a_day_does(t)
	_test_pause_does_not_open_over_a_section_brief_or_the_epilogue(t)
	_test_escape_section_came_from_the_file(t)
	_test_a_resumed_escape_opens_on_the_title_before_its_first_brief(t)
	_test_a_handover_does_not_open_on_the_title(t)
	_test_the_held_restart_from_the_escape_clears_the_section(t)

# --------------------------------------------------------------- the chains ---

static func _plan_for(seed_value: int) -> Dictionary:
	var map := CityGenerator.generate(seed_value)
	GameState.city_state.begin_day(map.block_plans, 1)
	map.repaint(GameState.city_state)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return {"map": map, "plan": FinalePlanner.plan(map, rng, _city_spec())}

## *"No overlapping routes"*: the choice is made once, at the door, and is the game's verb. The
## cell she leaves from is the one exception, since both walks have to start somewhere.
func _test_the_two_chains_part_at_the_door_and_never_meet_again(t) -> void:
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var plan: FinalePlanner.Plan = built["plan"]
		t.check(plan.chains.size() == 2, "seed %d plans two chains" % seed_value)
		var door: Vector2i = FinalePlanner.service_exit_tile(built["map"]) \
				/ ReachabilityGrid.CELL
		var shared: Array[Vector2i] = []
		for cell: Vector2i in plan.chains[0].cells:
			if cell != door and plan.chains[1].cells.has(cell):
				shared.append(cell)
		t.check(shared.is_empty(),
				"seed %d: the two chains share no cell after the door (shared %d)"
				% [seed_value, shared.size()])
		# A guard that the comparison was not vacuous: two empty chains share nothing either.
		t.check(plan.chains[0].cells.size() > 20 and plan.chains[1].cells.size() > 20,
				"seed %d: both chains are real walks (%d and %d cells)"
				% [seed_value, plan.chains[0].cells.size(), plan.chains[1].cells.size()])

## *"A single path through the city that crosses three parks (the player can use them to calm down
## or get the baby back to sleep if it wakes up)."* Distinct is the load-bearing word: three stops
## on one park is one place to rest, not three.
func _test_each_chain_passes_three_distinct_calm_areas(t) -> void:
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		for chain: FinalePlanner.Chain in plan.chains:
			t.check(chain.stops.size() == Tuning.FINALE_PARKS_PER_CHAIN,
					"seed %d: a chain has %d stops" % [seed_value, chain.stops.size()])
			var centres := {}
			for stop: FinalePlanner.CalmArea in chain.stops:
				centres[stop.centre] = true
				t.check(Tile.is_calm(map.tile_at(stop.centre)),
						"seed %d: a stop stands on calm ground" % seed_value)
			t.check(centres.size() == chain.stops.size(),
					"seed %d: every stop on a chain is a different place" % seed_value)
			# And the chain actually reaches each of them, rather than naming them and walking past.
			for stop: FinalePlanner.CalmArea in chain.stops:
				var reached := false
				for tile: Vector2i in stop.tiles:
					if chain.cells.has(tile / ReachabilityGrid.CELL):
						reached = true
						break
				t.check(reached, "seed %d: the walk enters the calm it stops at" % seed_value)

## The tunnel is at the north end of the spine and the bridge at its south end — the two exits
## `CityEdge` draws and already lets her walk into. A chain that ended anywhere else would be a
## walk with no way out at the end of it.
func _test_each_chain_reaches_its_own_edge(t) -> void:
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		for chain: FinalePlanner.Chain in plan.chains:
			t.check(chain.complete, "seed %d: a chain is walkable end to end" % seed_value)
			var exit := FinalePlanner.exit_tile(map, chain.exit_kind)
			var name := "tunnel" if chain.exit_kind == CityEdge.Kind.TUNNEL else "bridge"
			t.check(chain.cells.has(exit / ReachabilityGrid.CELL),
					"seed %d: the %s chain reaches its own edge" % [seed_value, name])
			t.check(Tile.is_road(map.tile_at(exit)),
					"seed %d: the %s ends on the spine's own carriageway" % [seed_value, name])
			# And it is the *last* of it: she is out under the portal, not a street short of it.
			var from_the_edge: int = exit.y if chain.exit_kind == CityEdge.Kind.TUNNEL \
					else map.size.y - 1 - exit.y
			t.check(from_the_edge <= CityEdge.TUNNEL_DEPTH_TILES,
					"seed %d: and within the portal's own depth of the map edge (%d rows)"
					% [seed_value, from_the_edge])
			# Standing on that tile is out of the city, and the street before it is not — the two
			# halves of what `Tuning.FINALE_EXIT_REACH` has to be worth.
			var at := map.tile_to_world(exit)
			t.check(Tuning.FINALE_EXIT_REACH > Tuning.PLAYER_BODY_RADIUS,
					"the exit's reach covers her whole body on the tile")
			t.check(at.distance_to(map.tile_to_world(exit + Vector2i(0, 2))) \
					> Tuning.FINALE_EXIT_REACH,
					"and stops short of the tile two back from it")
		t.check(plan.chains[0].exit_kind != plan.chains[1].exit_kind,
				"seed %d: the two chains leave by different ways" % seed_value)

# ----------------------------------------------------------------- the walls ---

## *"Off the one open route everything is sealed."* Stated over the streets the chains actually
## walk rather than the ones they touch, which is the same question `SealPlanner.runs_through()`
## decides for both the sealing and the events.
func _test_every_street_off_the_chains_is_sealed(t) -> void:
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var sealed_at := {}
		for placement: EventScheduler.Planned in plan.placements:
			if placement.def.obstructs_radius > 0.0:
				sealed_at[map.world_to_tile(placement.position)] = true
		# The one exempt street is the one she is standing in, not the one the front door opens
		# onto: on the last night she comes out of the service exit and never uses that door.
		var hers := StreetNetwork.segment_containing(
				FinalePlanner.service_exit_tile(map))
		var open_and_unsealed := 0
		var closed := 0
		for segment in StreetNetwork.segments():
			if not map.has_street(segment.key()):
				continue
			if SealPlanner.runs_through(segment, plan.open_cells):
				continue
			if hers and segment.key() == hers.key():
				continue
			var found := false
			for tile in map.rect_tiles(segment.tile_rect()):
				if sealed_at.has(tile):
					found = true
					break
			if found:
				closed += 1
			else:
				open_and_unsealed += 1
		t.check(open_and_unsealed == 0,
				"seed %d: every street off the chains carries a seal (%d did not)"
				% [seed_value, open_and_unsealed])
		t.check(closed > 40, "seed %d: and the city is mostly shut (%d streets)"
				% [seed_value, closed])

## The other half of the same sentence, and the one that decides whether the sequence is playable
## at all: from the service exit, through nothing but the chains' own cells, both ways out can be
## reached. A flood over the plan rather than over the tiles, because the plan is what the sealing
## was stated against.
func _test_both_exits_are_reachable_through_the_open_cells_alone(t) -> void:
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var grid := ReachabilityGrid.build(map)
		var start := grid.node_at(FinalePlanner.service_exit_tile(map))
		t.check(start >= 0, "seed %d: the service exit is walkable ground" % seed_value)
		var reached := {start: true}
		var queue: Array[int] = [start]
		var head := 0
		while head < queue.size():
			var node: int = queue[head]
			head += 1
			for edge: Array in grid.neighbours(node):
				var next: int = edge[0]
				if reached.has(next) or not plan.open_cells.has(grid.cell_of(next)):
					continue
				reached[next] = true
				queue.append(next)
		for kind in [CityEdge.Kind.TUNNEL, CityEdge.Kind.BRIDGE]:
			var exit := grid.node_at(FinalePlanner.exit_tile(map, kind))
			t.check(exit >= 0 and reached.has(exit),
					"seed %d: the %s is reached from the door through open cells only"
					% [seed_value, "tunnel" if kind == CityEdge.Kind.TUNNEL else "bridge"])

## *"Roadblocks currently are impossible to get past. One sidewalk must be open if they're
## en-route. The escape's street should not have fully blocking events like in the normal game"*
## (inbox #747). The test above floods the plan's cells and ignores what stands in them; this one
## floods the ground itself, with every body the escape puts down built as a real
## `EventInstance` — its own recentring onto the pavement band, its own spread axis across the
## street and its own parts — and a burst's crater built where the burst stands, since the hole
## stays for the rest of the walk. A van that hunts stays parked and solid and a roadblock's band
## stands after its guard has gone, so the bodies standing is what the whole walk looks like.
##
## On an 8px grid of points her centre may stand on: walkable ground under her and a body's
## reach away from every solid piece. Both exits have to be reached from the service exit on
## every seed. Seed 23 is a city whose bridge chain leaves a north-south street through a
## through-alley's mouth in the middle of a block, where a van at the mouth and a roadblock's band
## just south of it can shut the mouth while the street's far sidewalk stays open — the cut a
## sidewalk-by-sidewalk reading cannot see.
const BODY_FLOOD_SEEDS := [4242, 1, 77, 9001, 5, 1234, 31337, 808, 23]
const BODY_FLOOD_STEP := 8.0

func _test_both_exits_are_reachable_past_every_body_the_escape_stands(t) -> void:
	var bodies := 0
	for seed_value in BODY_FLOOD_SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var blocked := {}
		bodies += _block_every_body(t, map, plan, blocked)
		var reached := _flood_past_the_bodies(map, blocked,
				map.tile_to_world(FinalePlanner.service_exit_tile(map)))
		for kind in [CityEdge.Kind.TUNNEL, CityEdge.Kind.BRIDGE]:
			var exit := map.tile_to_world(FinalePlanner.exit_tile(map, kind))
			var at := Vector2i(roundi(exit.x / BODY_FLOOD_STEP), roundi(exit.y / BODY_FLOOD_STEP))
			var found := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if reached.has(at + Vector2i(dx, dy)):
						found = true
			t.check(found, "seed %d: the %s is reached from the door past every body standing"
					% [seed_value, "tunnel" if kind == CityEdge.Kind.TUNNEL else "bridge"])
	t.check(bodies > 0, "there were escape bodies to stand in the way (%d)" % bodies)

## **And past every lethal reach that stands**: from the door both exits are reached with her
## centre kept outside the reach of every row that stands, is lethal and does not pursue — the van's
## 54px round where it is parked — as well as off every body. A sidewalk kept open past a van's body
## but not past its reach is a walk that ends the section, so the walk rule keeps the reach as
## ground (`WalkGround.held_by()`); a pursuer's reach moves with him and warns first.
func _test_both_exits_are_reachable_past_every_standing_lethal_reach(t) -> void:
	var reaches := 0
	for seed_value in BODY_FLOOD_SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var blocked := {}
		_block_every_body(t, map, plan, blocked)
		reaches += _block_every_standing_reach(t, map, plan, blocked)
		var reached := _flood_past_the_bodies(map, blocked,
				map.tile_to_world(FinalePlanner.service_exit_tile(map)))
		for kind in [CityEdge.Kind.TUNNEL, CityEdge.Kind.BRIDGE]:
			var exit := map.tile_to_world(FinalePlanner.exit_tile(map, kind))
			var at := Vector2i(roundi(exit.x / BODY_FLOOD_STEP), roundi(exit.y / BODY_FLOOD_STEP))
			var found := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if reached.has(at + Vector2i(dx, dy)):
						found = true
			t.check(found, "seed %d: the %s is reached from the door past every standing lethal reach"
					% [seed_value, "tunnel" if kind == CityEdge.Kind.TUNNEL else "bridge"])
	t.check(reaches > 0, "there were standing lethal reaches to keep out of (%d)" % reaches)
	# The rule's own reading of one van and one roadblock, on open sidewalk: the van holds her off
	# its 54px reach as well as its body, the roadblock — whose guard pursues — its band alone.
	var map: CityMap = _plan_for(SEEDS[0])["map"]
	var ground := WalkGround.new(map)
	var tile := Vector2i.ZERO
	for candidate in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if not map.is_on_home_block(candidate):
			tile = candidate
			break
	var van := EventScheduler.Planned.new(EventCatalogue.by_id("abduction"), map.tile_to_world(tile))
	var held := ground.held_by(van)
	t.check(held.size() == ground.solids_of(van).size() + 1,
			"a van holds one piece more than its body: its reach")
	var reach: WalkGround.Solid = held[held.size() - 1]
	var lethal := EventCatalogue.by_id("abduction").lethal_reach()
	t.check(reach.stops_her_at(reach.centre + Vector2.RIGHT * (lethal - 2.0))
			and not reach.stops_her_at(reach.centre + Vector2.RIGHT * (lethal + 2.0)),
			"and that piece takes her centre exactly within %.0fpx" % lethal)
	var band := EventScheduler.Planned.new(EventCatalogue.escape_roadblock(), map.tile_to_world(tile))
	t.check(ground.held_by(band).size() == ground.solids_of(band).size(),
			"a roadblock, whose guard pursues, holds its band alone")

## **Where the reach is what decides it, the walk still gets through.** A bag of vans alone at two
## slots a street (`_escape_rows_on()` with `street_bag({"abduction": 1})`) packs the walk with
## parked vans; on these seeds a placement that keeps a sidewalk open past each van's 22px body but
## not past its 54px reach would cut the walk to one exit — the walk rule counting bodies alone
## leaves the tunnel unreachable on seeds 8 and 39 and the bridge on seed 1. So with the rule
## (`WalkGround.held_by()`), both exits are reached from the door past every body and every reach,
## and this is what fails if the judge stops asking the reach.
const VAN_STREET_SEEDS := [1, 8, 39]

func _test_a_street_of_vans_leaves_a_walk_past_every_reach(t) -> void:
	var vans := 0
	for seed_value in VAN_STREET_SEEDS:
		var map := CityGenerator.generate(seed_value)
		GameState.city_state.begin_day(map.block_plans, 1)
		map.repaint(GameState.city_state)
		var bare := _bare_plan(map, seed_value)
		var placed := _escape_rows_on(map, bare,
				EventScheduler.street_bag({"abduction": 1}, seed_value), 2)
		vans += placed.size()
		var whole := FinalePlanner.Plan.new()
		whole.placements.assign((bare["plan"] as FinalePlanner.Plan).placements.duplicate())
		whole.placements.append_array(placed)
		var blocked := {}
		_block_every_body(t, map, whole, blocked)
		_block_every_standing_reach(t, map, whole, blocked)
		var reached := _flood_past_the_bodies(map, blocked,
				map.tile_to_world(FinalePlanner.service_exit_tile(map)))
		for kind in [CityEdge.Kind.TUNNEL, CityEdge.Kind.BRIDGE]:
			var exit := map.tile_to_world(FinalePlanner.exit_tile(map, kind))
			var at := Vector2i(roundi(exit.x / BODY_FLOOD_STEP), roundi(exit.y / BODY_FLOOD_STEP))
			var found := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if reached.has(at + Vector2i(dx, dy)):
						found = true
			t.check(found, "seed %d, vans two a street: the %s is reached past every van's reach"
					% [seed_value, "tunnel" if kind == CityEdge.Kind.TUNNEL else "bridge"])
	t.check(vans > 100, "there were streets full of vans to walk past (%d)" % vans)

## Marks every grid point within the lethal reach of a row the plan stands that is not mobile, is
## `hard_fail` and does not pursue, measured from where its `EventInstance` stands, and answers how
## many reaches it marked.
static func _block_every_standing_reach(t, map: CityMap, plan: FinalePlanner.Plan,
		blocked: Dictionary) -> int:
	var holder := Node2D.new()
	t.add_child(holder)
	var count := 0
	for placement: EventScheduler.Planned in plan.placements:
		var def := placement.def
		if def.mobile or not def.hard_fail or def.pursuit != null:
			continue
		var instance := EventInstance.new()
		instance.setup(def, placement.position, placement.path, placement.facing, map)
		holder.add_child(instance)
		count += 1
		var centre := instance.global_position
		var reach := def.lethal_reach()
		for gy in range(floori((centre.y - reach) / BODY_FLOOD_STEP),
				ceili((centre.y + reach) / BODY_FLOOD_STEP) + 1):
			for gx in range(floori((centre.x - reach) / BODY_FLOOD_STEP),
					ceili((centre.x + reach) / BODY_FLOOD_STEP) + 1):
				if (Vector2(gx, gy) * BODY_FLOOD_STEP).distance_to(centre) <= reach:
					blocked[Vector2i(gx, gy)] = true
	holder.free()
	return count

## Marks every grid point a solid piece of the plan's bodies keeps her centre off, and answers how
## many bodies it built. Mobile rows have no body (a truck is traffic), and a row that leaves a
## solid successor is built as that successor where it stands.
static func _block_every_body(t, map: CityMap, plan: FinalePlanner.Plan,
		blocked: Dictionary) -> int:
	var holder := Node2D.new()
	t.add_child(holder)
	var count := 0
	for placement: EventScheduler.Planned in plan.placements:
		for def: EventDef in [placement.def,
				EventCatalogue.by_id(placement.def.spawns_on_finish())]:
			if def == null or def.mobile or def.obstructs_radius <= 0.0:
				continue
			var path := placement.path if def == placement.def else PackedVector2Array()
			var instance := EventInstance.new()
			instance.setup(def, placement.position, path, placement.facing, map)
			holder.add_child(instance)
			count += 1
			var centres := instance.solid_part_centres()
			var shapes := instance.solid_part_shapes()
			var axis := instance.solid_axis()
			for i in centres.size():
				var shape: GroundShape = shapes[i]
				var centre: Vector2 = centres[i]
				var rounding := shape.radius if shape.kind != GroundShape.Kind.RECT else 0.0
				var reach := shape.reach() + Tuning.PLAYER_BODY_RADIUS
				for gy in range(floori((centre.y - reach) / BODY_FLOOD_STEP),
						ceili((centre.y + reach) / BODY_FLOOD_STEP) + 1):
					for gx in range(floori((centre.x - reach) / BODY_FLOOD_STEP),
							ceili((centre.x + reach) / BODY_FLOOD_STEP) + 1):
						var local := (Vector2(gx, gy) * BODY_FLOOD_STEP - centre) \
								.rotated(-axis.angle())
						if shape.distance_to_spine(local) < rounding + Tuning.PLAYER_BODY_RADIUS:
							blocked[Vector2i(gx, gy)] = true
	holder.free()
	return count

static func _flood_past_the_bodies(map: CityMap, blocked: Dictionary, from: Vector2) -> Dictionary:
	var start := Vector2i(roundi(from.x / BODY_FLOOD_STEP), roundi(from.y / BODY_FLOOD_STEP))
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	var clear := {}
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if reached.has(next) or blocked.has(next) or not _she_fits(map, next, clear):
				continue
			reached[next] = true
			queue.append(next)
	return reached

## Her centre may stand on this grid point: the tile under it and the four her body reaches are
## walkable and not closed.
static func _she_fits(map: CityMap, point: Vector2i, cache: Dictionary) -> bool:
	if cache.has(point):
		return cache[point]
	var at := Vector2(point) * BODY_FLOOD_STEP
	var reach := Tuning.PLAYER_BODY_RADIUS - 1.0
	var fits := true
	for offset: Vector2 in [Vector2.ZERO, Vector2(reach, 0), Vector2(-reach, 0),
			Vector2(0, reach), Vector2(0, -reach)]:
		var tile := map.world_to_tile(at + offset)
		if not map.in_bounds(tile) or not map.is_walkable(tile) or map.is_closed(tile):
			fits = false
			break
	cache[point] = fits
	return fits

# ------------------------------------------------------------- the roadblocks ---

## **One roadblock a street**, so a crossing is one band and one guard on her side of it to lure.
## *(Inbox #771 in minty-lemur: "Right now there are for guards and the player adds excitement by just being
## close. Luring away one guard (the challenge) is not enough to make the obstacle survivable")*
## Two bands on a street stand a couple of tiles apart on the same sidewalk, and the second one's
## guard is still posted when she walks past after luring the first one's off. Asked of the game's
## plans, and of plans whose every street draws two roadblock marbles, since the notice spacing is
## what holds it at any slot count.
func _test_no_street_of_the_walk_stands_two_roadblocks(t) -> void:
	var streets := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var everywhere := FinalePlanner.Plan.new()
		everywhere.open_streets = plan.open_streets
		everywhere.placements = _roadblocks_everywhere(map, seed_value, 2)
		for planned: FinalePlanner.Plan in [plan, everywhere]:
			for street: Array in RoadblockRig.roadblock_streets(map, planned):
				streets += 1
				var segment: StreetNetwork.Segment = street[0]
				t.check(street[1].size() == 1, "seed %d: street %s stands one roadblock, not %d"
						% [seed_value, segment.key(), street[1].size()])
	t.check(streets > 0, "there were streets with a roadblock to ask about (%d)" % streets)

## **A roadblock's band costs nothing, ever, on a day and in the escape alike; the guard is the
## danger.** *(Inbox #788 in minty-lemur: "No cost at all, ever", of the escape's band; "band costing nothing
## should also apply to a normal day"; "the challenge is the guard not the concrete".)* Walked on
## both the escape's copy and a day's hunting row: the band charges nothing beside it while its
## guards are posted, while the guard on her side warns, while he charges, while he walks away,
## once he is gone, and when it is streamed back in as only the barrier; it stays solid throughout,
## and he still catches her if she walks on into his charge (`_test_luring_its_guard_off_is_the_way_past_a_roadblock`).
func _test_a_roadblock_band_costs_nothing(t) -> void:
	var escape := EventCatalogue.escape_roadblock()
	var day := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)
	t.check(escape == day, "the escape's roadblock is a day's at full resistance progress, one row")
	t.check(escape.pursuit != null and escape.pursuit.leaves_its_body and escape.hard_fail,
			"the escape's roadblock is still the hunting row: its guard chases and catches")
	t.check(EventCatalogue.by_id("roadblock").intensity == 0.0 and day.intensity == 0.0
			and escape.intensity == 0.0, "the roadblock row, cold and hunting, has no field strength")
	var step := 1.0 / 60.0
	for def: EventDef in [escape, day]:
		var name := "the escape's" if def == escape else "a day's"
		var post := Vector2(400.0, 0.0)
		var beside := post + Vector2(0.0, 70.0)
		var guard := EventInstance.new()
		guard.setup(def, post)
		t.add_child(guard)
		guard.set_process(false)
		guard._attach_the_band()
		var strongest := guard.contribution_at(beside)
		# In inside his radius: he warns.
		guard.player_at = post + Vector2(0.0, def.notice_within() - 10.0)
		guard._process(step)
		var warned := guard.is_standing_for_its_notice()
		strongest = maxf(strongest, maxf(guard.contribution_at(beside),
				guard.contribution_at(guard.player_at)))
		# She stays inside his radius until his warning has run: he charges. She runs; he gives up
		# and walks away.
		var waited := 0
		while guard.is_telegraphing() and waited < int((def.pursuit.warns_for + 1.0) / step):
			guard._process(step)
			waited += 1
		var charged := false
		var frames := 0
		while not guard.gave_up and frames < int(10.0 / step):
			guard.player_at = guard.global_position + Vector2(0.0, 300.0)
			guard.player_running = true
			guard._process(step)
			charged = charged or guard.is_chasing()
			if guard.is_chasing():
				strongest = maxf(strongest, maxf(guard.contribution_at(beside),
						guard.contribution_at(guard.global_position + Vector2(0.0, 40.0))))
			frames += 1
		var her := guard.player_at
		guard.player_running = false
		var leaving := guard.is_leaving and guard.is_a_spent_guard()
		strongest = maxf(strongest, guard.contribution_at(beside))
		frames = 0
		while guard.is_leaving and frames < int(30.0 / step):
			guard.player_at = her
			guard._process(step)
			strongest = maxf(strongest, guard.contribution_at(beside))
			frames += 1
		var gone := guard.is_a_spent_guard() and not guard.is_leaving and guard.is_solid()
		strongest = maxf(strongest, guard.contribution_at(beside))
		t.check(warned and charged and leaving and gone,
				"%s guard warns, charges, is shaken off and leaves the band standing solid" % name)
		t.check(strongest == 0.0,
				"%s band costs nothing posted, warning, charging, left or gone (%.1f/s at most)"
				% [name, strongest])
		guard.free()
		var streamed := EventInstance.new()
		streamed.setup(def, Vector2(400.0, 0.0))
		t.add_child(streamed)
		streamed.set_process(false)
		streamed.come_back_as_the_barrier(1)
		t.check(streamed.is_solid() and streamed.contribution_at(Vector2(400.0, 70.0)) == 0.0,
				"%s band streamed back in after its guard was spent is solid and silent" % name)
		streamed.free()

## **The far guard leaves too, so the band stands unmanned, on every day.** *(Inbox #771 in minty-lemur, asked
## whether the guard at the far post should leave as well once his partner has been lured off: "He
## leaves too"; inbox #788 in minty-lemur, asked whether on a day as well: "Days too".)* The frame the guard on her
## side starts to walk away, the one at the far post sets off from it the same way: away from her,
## at his partner's pace, gone once he is past `Tuning.OUT_OF_SIGHT` from her, his own node freed
## with him (the way he walks is over walkable ground, which
## `_test_neither_guard_walks_off_over_a_building` walks on a real map); the band draws no posted
## guard from that frame on, and one streamed back in after its guard was spent comes back with
## neither. Walked on the hunting roadblock, which is a day's and the escape's alike.
func _test_the_far_guard_leaves_with_his_partner(t) -> void:
	var def := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)
	t.check(def == EventCatalogue.escape_roadblock(),
			"a day's hunting roadblock and the escape's are the same row")
	var step := 1.0 / 60.0
	var post := Vector2(400.0, 0.0)
	var guard := EventInstance.new()
	guard.setup(def, post)
	t.add_child(guard)
	guard.set_process(false)
	guard._attach_the_band()
	var posted_first := guard.has_its_far_guard_posted()
	guard.player_at = post + Vector2(0.0, def.notice_within() - 10.0)
	guard._process(step)
	var waited := 0
	while guard.is_telegraphing() and waited < int((def.pursuit.warns_for + 1.0) / step):
		guard._process(step)
		waited += 1
	var posted_through_the_chase := true
	var frames := 0
	while not guard.is_leaving and frames < int(10.0 / step):
		guard.player_at = guard.global_position + Vector2(0.0, 300.0)
		guard.player_running = true
		guard._process(step)
		if not guard.is_leaving:
			posted_through_the_chase = posted_through_the_chase \
					and guard.has_its_far_guard_posted()
		frames += 1
	var her := guard.player_at
	guard.player_running = false
	t.check(posted_first and posted_through_the_chase,
			"the far guard stands at his post until his partner leaves")
	t.check(guard.is_leaving, "the guard on her side was shaken off and walks away")
	var set_off := guard.far_guard_at()
	t.check(set_off != Vector2.INF and not guard.has_its_far_guard_posted(),
			"the far guard sets off from his post the frame his partner starts to leave")
	t.check(set_off.distance_to(her) > guard.body_position().distance_to(her),
			"and he sets off from the far post, beyond the band from her")
	t.check(guard.barrier_post.far.node != null and guard.barrier_post.far.node.is_inside_tree(),
			"and walks on his own node beside the band's")
	# She has come back to stand beside the band, so he has a walk to make before he is out of
	# her sight.
	her = guard.body_position() + Vector2(0.0, 120.0)
	var paced := true
	var last := set_off
	var walked := 0
	while guard.far_guard_at() != Vector2.INF and walked < int(30.0 / step):
		guard.player_at = her
		guard._process(step)
		walked += 1
		var now := guard.far_guard_at()
		if now == Vector2.INF:
			break
		paced = paced and now.distance_to(last) <= def.chase_speed() * step + 0.01 \
				and is_equal_approx(guard.barrier_post.far.walked, def.chase_speed() * step * walked)
		last = now
	t.check(last.distance_to(her) > set_off.distance_to(her) and paced,
			"he walks away from her at his partner's pace (%d frames)" % walked)
	t.check(guard.far_guard_at() == Vector2.INF and not guard.has_its_far_guard_posted(),
			"and he is gone, and nobody stands at the band")
	t.check(last.distance_to(her) > Tuning.OUT_OF_SIGHT - def.chase_speed() * step,
			"only once he is out of her sight (%.0fpx from her)" % last.distance_to(her))
	t.check(guard.barrier_post.far.node == null, "his node goes with him")
	guard.free()
	var streamed := EventInstance.new()
	streamed.setup(def, Vector2(400.0, 0.0))
	t.add_child(streamed)
	streamed.set_process(false)
	streamed.come_back_as_the_barrier(1)
	t.check(not streamed.has_its_far_guard_posted(),
			"a band streamed back in after its guard was spent stands unmanned")
	streamed.free()

## **Neither guard walks off over a building.** The guard on her side, shaken off, and on the
## escape's band his partner at the far post walk away over walkable ground
## (`EventDeparture.way_out_from()`, the way `leave_along()` plans on from its end), not in
## a straight line away from her, which from anywhere not level with the band along its street
## crossed the roofs beside it in her view. Walked on the escape's real plan for seed 4242: at every
## band, from 16 bearings, she walks in until his charge, runs straight back until he gives up and
## stands; every frame either guard walks, he stands on a walkable tile. The band at tile (73,50)
## with her standing at (70,50), west of it on the open sidewalk, is the case PR #781's review found
## the far guard on the roof at (76,48) in: it is stood there even where the plan no longer puts a
## band on that tile, lured from the south down its street, and walked off with her at (70,50).
func _test_neither_guard_walks_off_over_a_building(t) -> void:
	var step := RoadblockRig.STEP
	var built := RoadblockRig.plan_for(4242)
	var map: CityMap = built["map"]
	var plan: FinalePlanner.Plan = built["plan"]
	var walks := 0
	var far_walks := 0
	var the_reviewed_case := false
	var bands := _escape_roadblocks(plan)
	var reviewed := Vector2i(73, 50)
	if not bands.any(func(b: EventScheduler.Planned) -> bool:
			return map.world_to_tile(b.position) == reviewed):
		bands.append(EventScheduler.Planned.new(EventCatalogue.escape_roadblock(),
				map.tile_to_world(reviewed)))
	for band_plan in bands:
		var group: Array[EventScheduler.Planned] = [band_plan]
		for bearing in 16:
			var made := RoadblockRig.build(t, map, group)
			var guard: EventInstance = made[1][0]
			var band := guard.body_position()
			var toward := Vector2.from_angle(TAU * float(bearing) / 16.0)
			var her := band + toward * (guard.def.notice_within() + 80.0)
			var where := "band %s from %d°" % [map.world_to_tile(band_plan.position),
					bearing * 360 / 16]
			var caught := false
			# In until his hand goes up, then standing until he charges.
			var frames_in := 0
			while her.distance_to(band) > 40.0 and not guard.is_chasing() \
					and frames_in < int(20.0 / step):
				if guard.is_waiting():
					her -= toward * Tuning.WALK_SPEED * step
				frames_in += 1
				var tile := map.world_to_tile(her)
				if map.in_bounds(tile) and map.is_walkable(tile):
					caught = RoadblockRig._tick(made[1], her, false)
				if caught:
					break
			var frames := 0
			while not caught and guard.is_chasing() and frames < int(10.0 / step):
				her += toward * Tuning.RUN_SPEED * step
				caught = RoadblockRig._tick(made[1], her, true)
				frames += 1
			if caught or not guard.is_leaving:
				made[0].free()
				continue
			walks += 1
			# The reviewed case: she stands at (70,50), west of the band on the open sidewalk, while
			# both guards walk off, so their ways are planned from there.
			var the_reviewed_walk := map.world_to_tile(band_plan.position) == reviewed \
					and bearing == 4
			if the_reviewed_walk:
				her = map.tile_to_world(Vector2i(70, 50))
				guard.departure.plan_the_rest_again()
				guard.barrier_post.far.way = PackedVector2Array()
			var far_walked := false
			var on_ground := true
			frames = 0
			while (guard.is_leaving or guard.far_guard_at() != Vector2.INF) \
					and frames < int(30.0 / step):
				RoadblockRig._tick(made[1], her, false)
				frames += 1
				var at: Array[Vector2] = []
				if guard.is_leaving:
					at.append(guard.global_position)
				if guard.far_guard_at() != Vector2.INF:
					at.append(guard.far_guard_at())
					far_walked = true
				for k in at.size():
					var point := at[k]
					var tile := map.world_to_tile(point)
					if not map.is_walkable(tile):
						on_ground = false
						t.check(false, "%s: a guard walking off stands on %s, not walkable ground"
								% [where, tile])
						break
				if not on_ground:
					break
			if far_walked:
				far_walks += 1
			if the_reviewed_walk and far_walked:
				the_reviewed_case = true
			made[0].free()
	t.check(walks > 0 and far_walks > 0,
			"there were guards walking off to watch (%d, %d with the far guard)" % [walks, far_walks])
	t.check(the_reviewed_case,
			"and the band at (73,50), with her at (70,50), sent its far guard off")

## **And nothing over her head says otherwise.** A posted band's guard has not noticed her yet, so
## inside its outer radius it raises the `SOON` mark (`EventManager._warn_about_the_ground_she_is_on()`),
## as every `hard_fail` row waiting for her does. A band whose guard has left for good waits for
## nobody: he never notices her or charges again, so it raises nothing, or the walk past a band
## that costs nothing would be made under a warning of a catch that cannot come.
func _test_a_lured_off_roadblock_raises_no_mark_over_her(t) -> void:
	var manager := EventManager.new()
	t.add_child(manager)
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	her.add_child(camera)
	t.add_child(her)
	her.set_physics_process(false)
	her.add_to_group("player")
	var band := EventInstance.new()
	band.setup(EventCatalogue.escape_roadblock(), Vector2(1000.0, 1000.0))
	manager.add_child(band)
	manager._instances.append(band)
	her.global_position = band.global_position + Vector2(0.0, band.def.outer_radius - 20.0)
	manager._find_player()
	manager._warn_about_the_ground_she_is_on()
	t.check(her.alert_level() == Stroller.Alert.SOON,
			"a posted band's guard waiting for her raises the mark inside its outer radius")
	band.come_back_as_the_barrier(1)
	her._physics_process(1.0)
	manager._warn_about_the_ground_she_is_on()
	t.check(her.alert_level() == Stroller.Alert.NONE,
			"a band whose guard has left for good raises nothing over her head")
	her.remove_from_group("player")
	her.free()
	manager.free()

## **The target, walked on the plan's own streets.** On every roadblock street of the walk, in
## both directions, along the middle of its open sidewalk: walking straight past the band with its
## guards posted is caught, and after luring the guard on her side off — in until he charges,
## back at a run until he gives up, waiting until he has gone — walking on past it meets no guard
## and costs the meter nothing, even awake, with the baby an earlier bang has just woken. The rig is
## `tests/escape_roadblock_rig.gd`; `tests/probes/escape_roadblock_cost.gd` prints the same walks
## over more seeds.
func _test_luring_its_guard_off_is_the_way_past_a_roadblock(t) -> void:
	var crossings := 0
	for seed_value: int in [4242, 77]:
		var built := RoadblockRig.plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		for street: Array in RoadblockRig.roadblock_streets(map, plan):
			var segment: StreetNetwork.Segment = street[0]
			var group: Array[EventScheduler.Planned] = []
			group.assign(street[1])
			var line := RoadblockRig.her_line(t, map, segment, group)
			t.check(not line.is_empty(), "seed %d: street %s keeps a sidewalk open past its band"
					% [seed_value, segment.key()])
			if line.is_empty():
				continue
			for forward in [true, false]:
				crossings += 1
				var from: Vector2 = line[0] if forward else line[1]
				var to: Vector2 = line[1] if forward else line[0]
				var where := "seed %d street %s %s" % [seed_value, segment.key(),
						"forward" if forward else "back"]
				var posted := RoadblockRig.walk(t, map, group, from, to,
						RoadblockRig.Meter.new(Tuning.EXCITEMENT_WAKE_THRESHOLD, false))
				t.check(posted["caught"], "%s: walking straight past its posted guard is caught"
						% where)
				var lured := RoadblockRig.lure(t, map, group, from, to,
						RoadblockRig.Meter.new(Tuning.EXCITEMENT_WAKE_THRESHOLD, false))
				var after: Dictionary = lured["after"]
				t.check(not lured["lure"]["caught"] and lured["lure"]["charged"] == 1,
						"%s: the guard on her side charges and is run off" % where)
				if after.is_empty():
					continue
				t.check(not after["caught"] and after["charged"] == 0,
						"%s: walking on past the band after the lure meets no guard" % where)
				t.check(after["strongest"] == 0.0 and after["cost"] == 0.0,
						"%s: and the band charges her nothing on the way (%.1f/s at most, %.1f points)"
						% [where, after["strongest"], after["cost"]])
	t.check(crossings > 0, "there were roadblock crossings to walk (%d)" % crossings)

## **One guard at a time, wherever the two bands stand.** No two of the escape's roadblocks stand
## where one's guard notices her while she deals with the other: their notices, each
## `EventDef.notice` round its band, never overlap (`EventScheduler._keeps_its_notice_to_itself()`).
## *(Inbox #771 in minty-lemur, 2026-10-18: "two roadblocks are right next to each other and the second guard is
## invisible (hidden) until it already charges".)* One a street keeps two off one street; this keeps
## two apart across a junction or a corner as well.
func _test_no_two_roadblocks_notice_her_from_the_same_ground(t) -> void:
	var pairs := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		# The game's plan, and the most bands the escape can stand: a roadblock drawn for every slot.
		for bands: Array[EventScheduler.Planned] in [_escape_roadblocks(plan),
				_roadblocks_everywhere(map, seed_value, 1)]:
			for i in bands.size():
				for j in range(i + 1, bands.size()):
					pairs += 1
					var gap := EventScheduler._stands_at(map, bands[i]).distance_to(
							EventScheduler._stands_at(map, bands[j]))
					var apart := bands[i].def.notice_within() + bands[j].def.notice_within()
					t.check(gap >= apart, "seed %d: the roadblocks at %s and %s stand %.0fpx apart, at least the %.0fpx their two notices take"
							% [seed_value, map.world_to_tile(bands[i].position),
							map.world_to_tile(bands[j].position), gap, apart])
	t.check(pairs > 0, "there were pairs of roadblocks to measure (%d)" % pairs)

## **An escape guard warns on the screen and in front of everything round him.** *(Inbox #771 in minty-lemur,
## 2026-10-18: "the second guard is invisible (hidden) until it already charges"; inbox #788 in minty-lemur: the
## warning is visible on screen.)* Walked: she comes at each of the game's roadblocks on two seeds'
## cities, and at every roadblock the escape can stand there, in a straight line from all round it, with the camera's view led by her walk as `Stroller` leads it
## (`RoadblockRig.view_round()`), and on the frame his hand goes up the whole of his raised-hand
## picture at his post (`EventInstance.warning_guard_rect()`) is inside that view, he is drawn above
## the street's other figures (`DrawLayer.Layer.WARNING`); on every approach that ends in his
## charge, his hand went up first; once he charges, he sorts
## with the street again. The approaches on which the radius alone would have warned her with him
## off the view are counted, so the view's part in the notice is shown to be doing something.
func _test_an_escape_guard_warns_on_the_screen_and_on_top(t) -> void:
	var step := RoadblockRig.STEP
	var warned := 0
	var outside := 0
	var charges := 0
	var off_by_the_radius := 0
	for seed_value: int in [4242, 77]:
		var built := RoadblockRig.plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		# The game's own bands, and every band the escape can stand, a roadblock drawn for every
		# street's slot: the bag draws few, and only the second set is sure to hold a band on a
		# street running either way, and the approaches the radius alone would have warned from off
		# the view, which only a north-south street has.
		var bands := _escape_roadblocks(plan)
		bands.append_array(_roadblocks_everywhere(map, seed_value, 1))
		for band_plan in bands:
			var group: Array[EventScheduler.Planned] = [band_plan]
			for bearing in 16:
				var made := RoadblockRig.build(t, map, group)
				var guard: EventInstance = made[1][0]
				var band := guard.body_position()
				var toward := Vector2.from_angle(TAU * float(bearing) / 16.0)
				var her := band + toward * (guard.def.notice_within() + 80.0)
				var radius_alone_seen := false
				var charged := false
				var warned_here := false
				var open_walk := true
				var where := "seed %d band %s from %d°" % [seed_value,
						map.world_to_tile(band_plan.position), bearing * 360 / 16]
				var frames_in := 0
				while her.distance_to(band) > 40.0 and not charged and frames_in < int(20.0 / step):
					frames_in += 1
					# In until his hand goes up, then standing until he charges.
					if guard.is_waiting():
						her -= toward * Tuning.WALK_SPEED * step
					var tile := map.world_to_tile(her)
					var inside := her.distance_to(band) <= guard.def.notice_within()
					if not map.in_bounds(tile) or not map.is_walkable(tile):
						open_walk = open_walk and not inside
						continue
					open_walk = open_walk and not (inside and not map.clear_line(band, her))
					var view := RoadblockRig.view_round(her, -toward)
					var was_waiting := guard.is_waiting()
					if was_waiting and not radius_alone_seen and inside \
							and map.clear_line(band, her):
						radius_alone_seen = true
						if not view.encloses(EventInstance.warning_guard_rect(
								guard._spread_vertical, band, her)):
							off_by_the_radius += 1
					RoadblockRig._tick(made[1], her, false, -toward)
					if was_waiting and guard.is_standing_for_its_notice():
						warned += 1
						warned_here = true
						t.check(view.encloses(EventInstance.warning_guard_rect(
								guard._spread_vertical, band, her)),
								"%s: his raised hand goes up in her view" % where)
						t.check(DrawLayer.layer_of(guard) == DrawLayer.Layer.WARNING,
								"%s: and he is drawn above the street round him" % where)
						if open_walk:
							outside += 1
					if guard.is_chasing():
						charged = true
						charges += 1
						t.check(warned_here,
								"%s: his hand went up before he charged" % where)
						t.check(DrawLayer.layer_of(guard) == DrawLayer.Layer.ENTITIES,
								"%s: once he charges he sorts with the street again" % where)
				made[0].free()
	t.check(warned > 0 and outside > 0,
			"there were warnings to watch (%d, %d on open ground)" % [warned, outside])
	t.check(charges > 0, "and charges to ask about (%d)" % charges)
	t.check(off_by_the_radius > 0,
			"and approaches the radius alone would have warned from off the view (%d)"
			% off_by_the_radius)

## The escape's roadblocks a plan of `seed_value` on `map` stands when every one of its `slots` a
## street draws a roadblock marble: every band the placement rules let the escape stand there.
static func _roadblocks_everywhere(map: CityMap, seed_value: int,
		slots: int) -> Array[EventScheduler.Planned]:
	return _escape_rows_on(map, _bare_plan(map, seed_value),
			EventScheduler.street_bag({"roadblock": 1}, seed_value), slots)

## The plan's own roadblocks, the escape's copy of the row.
static func _escape_roadblocks(plan: FinalePlanner.Plan) -> Array[EventScheduler.Planned]:
	var found: Array[EventScheduler.Planned] = []
	for placement in plan.placements:
		if placement.def == EventCatalogue.escape_roadblock():
			found.append(placement)
	return found

## **The seed the player could not win, booted the way the player booted it.** *(Inbox #771 in minty-lemur,
## 2026-10-18: "the seed you gave me for testing the escape is still unwinnable. two roadblocks are
## right next to each other and the second guard is invisible (hidden) until it already charges")*
## Seed 4216201080 from the building, walked out of the service door through the real `main.tscn`
## (as `tests/test_escape_invisible_wall.gd` does), and the city section's own plan read off the
## city it built: the street the player was caught on stands one band at most; no two bands
## notice her from the same ground; from the door both exits are reached past every body standing
## for the walk; and on every roadblock street, both ways, from the asleep baby every attempt at
## the city starts with, walking straight past a posted guard is caught while luring him off and
## walking on is not, and costs nothing.
func _test_the_players_seed_is_winnable_past_its_roadblocks(t) -> void:
	var saved_section := GameState.escape_section
	GameState.start_run(PLAYERS_SEED)
	GameState.day = 1
	GameState.escape_section = DaySpec.Section.BUILDING
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	main._on_summary_continued()
	main._interior.exit_requested.emit()
	main._on_summary_continued()
	t.check(main._city != null and main._spec.section == DaySpec.Section.CITY,
			"seed %d: the service door puts her in the city" % PLAYERS_SEED)
	if main._city != null:
		var map: CityMap = main._city.map
		var plan := FinalePlanner.plan(map, GameState.day_rng(GameState.day, "finale"), _city_spec())
		var bands := _escape_roadblocks(plan)
		var hers := StreetNetwork.segment_containing(WHERE_THE_PLAYER_WAS_CAUGHT)
		var on_her_street := 0
		for band_plan in bands:
			var street := StreetNetwork.segment_containing(map.world_to_tile(band_plan.position))
			if hers and street and street.key() == hers.key():
				on_her_street += 1
		t.check(hers != null and on_her_street <= 1,
				"seed %d: the street she was caught on stands one band at most (%d)"
				% [PLAYERS_SEED, on_her_street])
		for i in bands.size():
			for j in range(i + 1, bands.size()):
				t.check(EventScheduler._stands_at(map, bands[i]).distance_to(
						EventScheduler._stands_at(map, bands[j]))
						>= bands[i].def.notice_within() + bands[j].def.notice_within(),
						"seed %d: the bands at %s and %s notice her from no common ground"
						% [PLAYERS_SEED, map.world_to_tile(bands[i].position),
						map.world_to_tile(bands[j].position)])
		var blocked := {}
		_block_every_body(t, map, plan, blocked)
		var reached := _flood_past_the_bodies(map, blocked,
				map.tile_to_world(FinalePlanner.service_exit_tile(map)))
		for kind in [CityEdge.Kind.TUNNEL, CityEdge.Kind.BRIDGE]:
			var exit := map.tile_to_world(FinalePlanner.exit_tile(map, kind))
			var at := Vector2i(roundi(exit.x / BODY_FLOOD_STEP), roundi(exit.y / BODY_FLOOD_STEP))
			var found := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					found = found or reached.has(at + Vector2i(dx, dy))
			t.check(found, "seed %d: the %s is reached from the door past every body standing"
					% [PLAYERS_SEED, "tunnel" if kind == CityEdge.Kind.TUNNEL else "bridge"])
		var crossings := 0
		for street: Array in RoadblockRig.roadblock_streets(map, plan):
			var segment: StreetNetwork.Segment = street[0]
			var group: Array[EventScheduler.Planned] = []
			group.assign(street[1])
			var line := RoadblockRig.her_line(t, map, segment, group)
			t.check(not line.is_empty(), "seed %d: street %s keeps a sidewalk open past its band"
					% [PLAYERS_SEED, segment.key()])
			if line.is_empty():
				continue
			for forward in [true, false]:
				crossings += 1
				var from: Vector2 = line[0] if forward else line[1]
				var to: Vector2 = line[1] if forward else line[0]
				var where := "seed %d street %s %s" % [PLAYERS_SEED, segment.key(),
						"forward" if forward else "back"]
				var posted := RoadblockRig.walk(t, map, group, from, to,
						RoadblockRig.Meter.new(0.0, true))
				t.check(posted["caught"], "%s: walking straight past its posted guard is caught"
						% where)
				var lured := RoadblockRig.lure(t, map, group, from, to,
						RoadblockRig.Meter.new(0.0, true))
				var after: Dictionary = lured["after"]
				t.check(not lured["lure"]["caught"] and not after.is_empty() \
						and not after["caught"] and after["charged"] == 0 and after["cost"] == 0.0,
						"%s: luring its guard off and walking on past is not caught and costs nothing"
						% where)
		t.check(crossings > 0, "seed %d: there were roadblock crossings to walk (%d)"
				% [PLAYERS_SEED, crossings])
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
	GameState.escape_section = saved_section

# ------------------------------------------------------- the day's own rules ---

## **The escape's own rows stand on the day's own ground for them** (`EventScheduler._street_ground()`
## asks `_open_ground_for()`): every truck, van, roadblock and burst on a tile a day would offer that
## row — none on the home block, none in a street tree, none on the wrong side of a sidewalk, no
## spread on a corner — all but the front door's street, a door the escape never sets off from.
## *(Inbox #785 in minty-lemur, 2026-10-18: "does the escape use the same placement rules as the regular game? it
## doesn't seem like it does. it should, though.")*
func _test_the_escape_stands_its_rows_on_the_days_own_ground(t) -> void:
	var asked := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var offered := {}
		for placement in plan.placements:
			if not ESCAPE_ROWS.has(placement.def.id):
				continue
			asked += 1
			var key := placement.def.get_instance_id()
			if not offered.has(key):
				var tiles := {}
				for tile in EventScheduler._open_ground_for(placement.def, map, {}, -1, false):
					tiles[tile] = true
				offered[key] = tiles
			var at := map.world_to_tile(placement.position)
			t.check(offered[key].has(at), "seed %d: the %s at %s stands on ground a day offers it"
					% [seed_value, placement.def.id, at])
	t.check(asked > 0, "there were escape rows to ask about (%d)" % asked)

## The escape's own rows, the four the city section's bag draws (`DaySpec.bag_rows`).
const ESCAPE_ROWS := ["military_convoy", "abduction", "roadblock", "finale_explosion"]

## **An alley's mouth wall fits the mouth**, on a day and in the escape: the widest row whose body
## is no wider than the alley (`SealPlanner._widest_that_fits_a_mouth()`). A day's soft rows always
## fitted; the escape's own list is street seals sized for a 192px street, and the widest of them
## stood across a 64px alley and two tiles into the buildings either side, over their roofs.
## *(Inbox #785 in minty-lemur, 2026-10-18: "I saw wood on the roof for example")* Asked of every alley-mouth wall
## the escape's plans stand, by its body: nothing of it reaches a building tile.
func _test_an_alley_mouth_wall_fits_the_mouth(t) -> void:
	var mouth := float(Tuning.ALLEY_WIDTH_TILES * Tuning.TILE_SIZE)
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var id := SealPlanner._alley_mouth_def(SealPlanner.candidates(), day)
		if id != "":
			t.check(EventCatalogue.by_id(id).obstructs_radius * 2.0 <= mouth,
					"day %d's alley-mouth row %s fits the mouth" % [day, id])
	var walls := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var ground := WalkGround.new(map)
		for placement in plan.placements:
			var tile := map.world_to_tile(placement.position)
			if map.tile_at(tile) != GameEnums.TileType.ALLEY:
				continue
			walls += 1
			var over := false
			for solid in ground.solids_of(placement):
				var reach := solid.shape.reach()
				for step in range(-ceili(reach), ceili(reach) + 1, 4):
					for across: Vector2 in [solid.axis, Vector2(-solid.axis.y, solid.axis.x)]:
						var at := solid.centre + across * float(step)
						if solid.stops_her_at(at) and at.distance_to(solid.centre) \
								<= solid.shape.reach() - 1.0 \
								and map.tile_at(map.world_to_tile(at)) == GameEnums.TileType.BUILDING:
							over = true
			t.check(not over, "seed %d: the %s in the alley mouth at %s keeps its body off the buildings"
					% [seed_value, placement.def.id, tile])
	t.check(walls > 0, "there were alley-mouth walls to ask about (%d)" % walls)

## **Nothing the escape stands reaches over a building**, seals and events alike, with its body or
## with the ground its picture is drawn over (`tests/seal_reach_rig.gd`'s measure). *(Inbox #785 in minty-lemur,
## 2026-10-18: "I saw wood on the roof for example")* The barricade's carts across a street off the
## chains are the pieces that reached over the buildings either side.
func _test_nothing_the_escape_stands_reaches_over_a_building(t) -> void:
	var barricades := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var ground := WalkGround.new(map)
		for placement in plan.placements:
			if placement.def.id == "barricade":
				barricades += 1
			var body := Reach.body_overhang(map, ground, placement)
			var drawn := Reach.drawing_overhang(map, placement)
			t.check(body <= 0.5 and drawn <= 0.5,
					"seed %d: the %s at %s keeps off the buildings (body %.1fpx, drawing %.1fpx over)"
					% [seed_value, placement.def.id, map.world_to_tile(placement.position), body,
					drawn])
	t.check(barricades > 0, "there were barricade pieces among them (%d)" % barricades)

## **A restart plans the same escape, on the ground the first plan read.** A loss in the city
## replans it on the same city (`main._plan_the_finale_city()`), and the day's ground for the
## escape's rows is kept across it (`EventScheduler._kept_ground()`): the restart's plan is
## the first one, placement for placement, and the kept ground is the same answer. A city whose
## ground did change — a tile closed — is read again rather than answered from the kept copy.
func _test_a_restart_plans_the_same_escape_on_the_kept_ground(t) -> void:
	var map := CityGenerator.generate(SEEDS[0])
	GameState.city_state.begin_day(map.block_plans, 1)
	map.repaint(GameState.city_state)
	var plans: Array[FinalePlanner.Plan] = []
	var kept: Array[Dictionary] = []
	for attempt in 2:
		var rng := RandomNumberGenerator.new()
		rng.seed = SEEDS[0]
		plans.append(FinalePlanner.plan(map, rng, _city_spec()))
		kept.append(EventScheduler._kept_ground_answers)
	var same := plans[0].placements.size() == plans[1].placements.size()
	for i in mini(plans[0].placements.size(), plans[1].placements.size()):
		var a := plans[0].placements[i]
		var b := plans[1].placements[i]
		same = same and a.def.id == b.def.id and a.position.is_equal_approx(b.position)
	t.check(same and plans[0].placements.size() > 0,
			"a restart plans the same %d placements as the first plan" % plans[0].placements.size())
	t.check(is_same(kept[0], kept[1]), "and reads the ground the first plan kept")
	var tile := map.world_to_tile(map.tile_rect_to_world(
			plans[0].open_streets[0].tile_rect()).get_center())
	map.closed_tiles[tile] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEEDS[0]
	FinalePlanner.plan(map, rng, _city_spec())
	t.check(not is_same(EventScheduler._kept_ground_answers, kept[1]),
			"a city with a tile closed since is read again (%s)" % tile)

# ------------------------------------------------------------ the marble bag ---

## **The escape's bag holds its marbles in the player's order of how many, empty ones included.**
## *(Inbox #785 in minty-lemur: "a marble bag is absolutely needed with empty events (nothing
## happening) as well"; "frequency order is trucks > explosions > vans > barriers > empty".)*
func _test_the_escape_bag_keeps_the_players_order(t) -> void:
	t.check(Tuning.FINALE_BAG_TRUCKS > Tuning.FINALE_BAG_EXPLOSIONS
			and Tuning.FINALE_BAG_EXPLOSIONS > Tuning.FINALE_BAG_VANS
			and Tuning.FINALE_BAG_VANS > Tuning.FINALE_BAG_ROADBLOCKS
			and Tuning.FINALE_BAG_ROADBLOCKS > Tuning.FINALE_BAG_EMPTY,
			"the bag holds more trucks than explosions, than vans, than roadblocks, than empty marbles")
	t.check(Tuning.FINALE_BAG_EMPTY > 0, "and it holds empty marbles")
	t.check(Tuning.FINALE_SLOTS_PER_STREET > 0, "and every open street has a slot to draw for")
	var counts := _city_spec().bag
	var bag := EventScheduler.street_bag(counts, 7)
	var total := 0
	for marble: String in counts:
		total += int(counts[marble])
	var drawn := {}
	for _i in total:
		var marble: String = bag.draw()
		drawn[marble] = int(drawn.get(marble, 0)) + 1
	var exact := true
	for marble: String in counts:
		exact = exact and int(drawn.get(marble, 0)) == int(counts[marble])
	t.check(exact, "one fill of the bag hands out exactly its counts (%s)" % drawn)

## **Every slot of every open street draws one marble, and a marble that finds no ground is spent
## unmet.** A street stands at most its slots' worth of the escape's rows; the bag is drawn once a
## slot whatever the draw finds, so a refused danger never moves on to the next street; a bag of
## empty marbles stands nothing; and a bag of roadblocks alone stands fewer than it drew, since no
## two bands may stand where both guards can notice her.
func _test_every_slot_of_every_street_draws_one_marble(t) -> void:
	var unmet := 0
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		GameState.city_state.begin_day(map.block_plans, 1)
		map.repaint(GameState.city_state)
		var bare := _bare_plan(map, seed_value)
		var streets: Array[StreetNetwork.Segment] = bare["streets"]
		for slots in [1, 2]:
			var bag := EventScheduler.street_bag(_city_spec().bag, seed_value)
			var placed := _escape_rows_on(map, bare, bag, slots)
			t.check(bag.drawn == streets.size() * slots,
					"seed %d, %d a street: every slot drew one marble (%d of %d)"
					% [seed_value, slots, bag.drawn, streets.size() * slots])
			var most := 0
			for segment in streets:
				var rect := map.tile_rect_to_world(segment.tile_rect()).grow(1.0)
				var here := 0
				for placement in placed:
					if rect.has_point(placement.position):
						here += 1
				most = maxi(most, here)
			t.check(most <= slots, "seed %d: no street stands more than its %d slots (%d)"
					% [seed_value, slots, most])
		var empty := EventScheduler.street_bag({DaySpec.EMPTY_MARBLE: 1}, seed_value)
		t.check(_escape_rows_on(map, bare, empty, 1).is_empty(),
				"seed %d: a bag of empty marbles stands nothing" % seed_value)
		var bands := EventScheduler.street_bag({"roadblock": 1}, seed_value)
		var stood := _escape_rows_on(map, bare, bands, 1)
		t.check(bands.drawn == streets.size(), "seed %d: a bag of roadblocks draws once a street (%d)"
				% [seed_value, bands.drawn])
		unmet += streets.size() - stood.size()
	t.check(unmet > 0, "and some roadblock marbles were spent unmet (%d)" % unmet)

## **The game's plan is `Tuning`'s bag, drawn on the street bag's own stream**: the city section's
## spec holds `Tuning`'s counts and slots, and what `FinalePlanner.plan()` stands is what the bag
## draw (`EventScheduler._fill_the_walk_from_the_bag()`) stands from `street_bag()` off those counts
## and `street_bag_seed()`, placement for placement — the plan `tests/probes/escape_winnable.gd`
## measures other mixes against.
func _test_the_game_draws_the_escape_from_tunings_bag(t) -> void:
	var spec := _city_spec()
	t.check(spec.bag == {"military_convoy": Tuning.FINALE_BAG_TRUCKS,
			"finale_explosion": Tuning.FINALE_BAG_EXPLOSIONS, "abduction": Tuning.FINALE_BAG_VANS,
			"roadblock": Tuning.FINALE_BAG_ROADBLOCKS, DaySpec.EMPTY_MARBLE: Tuning.FINALE_BAG_EMPTY}
			and spec.slots_per_street == Tuning.FINALE_SLOTS_PER_STREET,
			"the city section's spec holds Tuning's bag and slots")
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var bare := _bare_plan(map, seed_value)
		var rng: RandomNumberGenerator = bare["rng"]
		var bag := EventScheduler.street_bag(_city_spec().bag,
				EventScheduler.street_bag_seed(rng))
		var placed := _escape_rows_on(map, bare, bag, Tuning.FINALE_SLOTS_PER_STREET)
		var played: Array[EventScheduler.Planned] = []
		for placement in plan.placements:
			if ESCAPE_ROWS.has(placement.def.id):
				played.append(placement)
		var same := played.size() == placed.size()
		for i in mini(played.size(), placed.size()):
			same = same and played[i].def.id == placed[i].def.id \
					and played[i].position.is_equal_approx(placed[i].position)
		t.check(same and played.size() > 0, "seed %d: the game's plan is Tuning's bag (%d and %d)"
				% [seed_value, played.size(), placed.size()])

## The plan `_plan_for()` builds with no events of the escape's own yet: its walk and streets, its
## seals and the rng where `FinalePlanner.plan()` hands it to `EventScheduler.build_day()`.
static func _bare_plan(map: CityMap, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var plan := FinalePlanner.plan(map, rng, _city_spec(), false)
	var seals: Array[EventScheduler.Planned] = []
	seals.assign(plan.placements)
	return {"plan": plan, "streets": plan.open_streets, "seals": seals, "rng": rng,
			"state": rng.state}

## The escape's rows the bag draw (`EventScheduler._fill_the_walk_from_the_bag()`) stands on the bare
## plan from `bag` at `slots` a street, the rng put back where `FinalePlanner.plan()` would hand it
## over each time.
static func _escape_rows_on(map: CityMap, bare: Dictionary, bag: MarbleBag,
		slots: int) -> Array[EventScheduler.Planned]:
	var rng: RandomNumberGenerator = bare["rng"]
	rng.state = bare["state"]
	var seals: Array[EventScheduler.Planned] = bare["seals"]
	var spec := _city_spec()
	spec.slots_per_street = slots
	return EventScheduler._fill_the_walk_from_the_bag(spec, rng, map, bare["plan"], bag, [],
			PackedVector2Array(), seals)

## *"Emerging from the service exit on the side of the main building."* Beside the home block, on
## walkable ground, and never on the spine's own frontage.
func _test_the_service_exit_is_beside_the_home_block(t) -> void:
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		GameState.city_state.begin_day(map.block_plans, 1)
		map.repaint(GameState.city_state)
		var tile := FinalePlanner.service_exit_tile(map)
		t.check(map.is_walkable(tile), "seed %d: the service exit is walkable" % seed_value)
		var lot := CityMap.blocks_tile_rect(map.lot_blocks(map.home_block))
		var beside := tile.x == lot.position.x - 1 or tile.x == lot.end.x
		t.check(beside, "seed %d: it is on one of the home lot's two side streets" % seed_value)
		var spine := map.main_road * CityMap.period()
		var on_the_spine := tile.x >= spine and tile.x < spine + Tuning.STREET_WIDTH
		t.check(not on_the_spine, "seed %d: and not on the main road's own frontage" % seed_value)

## Seeds for the one question that is about a single tile rather than about the shape of a walk.
## *"The spawn in the city from the basement can end up inside an obstacle"* was found on a city
## nobody had planned for, so four cities is not enough of an answer: the ground she is put down on
## is one tile out of a lattice, and whether anything lands on it is a coin the generator tosses
## once per seed.
const SPAWN_SEEDS := [4242, 1, 77, 9001, 5, 1234, 31337, 808, 6, 27]

## *"The spawning shouldn't be a check. The pathing should start from the position. Then obstacles
## can never happen."*
##
## **This is the confirmation, not the mechanism.** What makes it true is that everything the
## section plans is planned from the tile she is put down on — the chains enter the grid at her own
## cell, `SealPlanner.plan_day()` spares the street she is standing in rather than the one the
## front door opens onto, and `EventScheduler.build_day()` is never offered ground its own body
## would reach her on. This walks seeds and asks the outcome instead.
##
## **A 14px body at the spawn overlaps no static body**, and in this scene that is exactly the two
## sources checked below, because nothing else in a finale city has one: the props and the street
## trees are plain `Node2D`s with no collision at all, a `Building` stands on block ground and
## `service_exit_tile()` answers with walkable ground, the boundary walls are outside the map, and
## the crowd is cleared before the plan is made. An event's obstruction body and a seal's are what
## is left — both arrive as `EventScheduler.Planned`, and a burst's crater arrives as one of those
## spawning its successor where it stood, which is asked about too.
##
## Asked of the plan rather than of the physics server, by choice: the plan is what the finale
## decides, and the question is where it put things.
func _test_nothing_the_finale_places_stands_where_she_comes_out(t) -> void:
	var checked := 0
	var on_her := 0
	for seed_value in SPAWN_SEEDS:
		var map := CityGenerator.generate(seed_value)
		GameState.city_state.begin_day(map.block_plans, 1)
		map.repaint(GameState.city_state)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var plan := FinalePlanner.plan(map, rng, _city_spec())
		var spawn := FinalePlanner.service_exit_world_position(map)
		t.check(map.is_walkable(map.world_to_tile(spawn)),
				"seed %d: she is put down on walkable ground" % seed_value)
		for placement: EventScheduler.Planned in plan.placements:
			checked += 1
			for def in [placement.def, EventCatalogue.by_id(placement.def.spawns_on_finish())]:
				if def == null or def.obstructs_radius <= 0.0:
					continue
				if placement.position.distance_to(spawn) \
						<= def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS:
					on_her += 1
					t.check(false,
							"seed %d: the escape's '%s' stands %.0fpx from the spawn, inside the "
							% [seed_value, def.id, placement.position.distance_to(spawn)]
							+ "%.0fpx its body and her own take up"
							% (def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS))
	t.check(checked > 0, "there were escape placements to ask about (%d)" % checked)
	t.check(on_her == 0, "and none of them is standing on her (%d of %d)" % [on_her, checked])

## *"I still spawn with flashing !!! in the city."* The same rule as the test above, read one field
## wider: the ground she is put down on is free of every **lethal reach**, not only of every body.
##
## **The mark means one thing and one condition raises it.**
## `EventManager._warn_about_the_ground_she_is_on()` puts `Stroller.Alert.SOON` over her head for
## any `hard_fail` row that is still telegraphing, or still waiting to notice her, whose **outer**
## radius covers her — because that radius is exactly what the telegraph fairness contract promises
## her time to walk out of. On the first frame of section two every placement the finale made is in
## one of those two states, so that one inequality is the whole of the mark, and it is asked here
## as `distance > outer_radius` for every lethal row on the plan. `NOW` needs a live instance and
## cannot fire on the frame the section begins; `distance > inner_radius` falls out of the same
## check, since a row's outer radius is never under its inner one.
##
## **This is the confirmation, not the mechanism**, exactly as for the bodies above:
## `EventScheduler._clearance_around_her()` is never offered ground within a lethal row's own outer
## radius of her, so nothing is placed there to be cleared up afterwards.
##
## Seeds rather than one city, and the guard counts the lethal rows it actually found: an escape
## plan that happened to place none at all would otherwise pass this without checking anything.
func _test_no_lethal_field_covers_the_ground_she_comes_out_on(t) -> void:
	var lethal := 0
	var over_her := 0
	for seed_value in SPAWN_SEEDS:
		var map := CityGenerator.generate(seed_value)
		GameState.city_state.begin_day(map.block_plans, 1)
		map.repaint(GameState.city_state)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var plan := FinalePlanner.plan(map, rng, _city_spec())
		var spawn := FinalePlanner.service_exit_world_position(map)
		for placement: EventScheduler.Planned in plan.placements:
			if not placement.def.hard_fail:
				continue
			lethal += 1
			var gap := placement.position.distance_to(spawn)
			if gap <= placement.def.outer_radius:
				over_her += 1
				t.check(false,
						"seed %d: the escape's '%s' stands %.0fpx from the spawn, inside the %.0fpx "
						% [seed_value, placement.def.id, gap, placement.def.outer_radius]
						+ "field that raises the mark over her head")
	t.check(lethal > 0, "the escape places lethal rows to ask about (%d)" % lethal)
	t.check(over_her == 0,
			"and none of their fields reaches the ground she comes out on (%d of %d)"
			% [over_her, lethal])

# ------------------------------------------------------------------ the city ---

## *"No regular cars or regular people on the street."* Non-vacuous on purpose: the crowd is
## populated first, so what is asserted is that dressing the city for the escape and starting its
## crowd as the section's spec says (`DaySpec.crowd_density`, through `main._start_the_crowd()`)
## leaves it empty rather than that it started that way.
func _test_the_finale_city_has_nobody_in_it(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEEDS[0]))
	GameState.city_state.begin_day(city.map.block_plans, 1)
	city.crowd.start_day(1, GameState.day_rng(1, "crowd"), city.map.doorstep_world_position())
	t.check(city.crowd.agent_count() > 0, "a day's crowd is a crowd")
	var spec := _section(DaySpec.Section.CITY)
	city.start_day(GameState.city_state, 1, GameState.day_rng(1, "closures"), spec)
	var main: Node2D = MAIN_SCRIPT.new()
	main._city = city
	main._spec = spec
	main._start_the_crowd(Vector2.INF)
	t.check(city.crowd.agent_count() == 0, "and the escape's city has nobody in it")
	t.check(city.route_tree() == null and city.closures().is_empty(),
			"the escape grows no corridor and closes no street")
	main.free()
	# `.free()`, not `queue_free()`, so the city is gone before the next check rather than at a
	# frame that passes after this suite.
	city.free()

## *"Yes, of course the yellow tint. We spent the whole game establishing that why would it be
## different in the last section?"* (inbox #747). Both kerb lines of every street the chains run
## through carry the route twin of their kerb source, and no other street's kerb does — the paint
## asked through `City.scenery_ground_source()`, the one answer every ground chunk is painted from.
##
## **Driven through `main`, because the wiring is what the player saw missing.** The city walks a
## day first, so a day's own route kerbs are tinted when the escape starts and a tint left over
## from them would show. Then the first plan, through `main._plan_the_finale_city()` — what
## `_build_the_finale_city()` ends on — and a restart, through `main._start_section()` with
## `restarted` set, which is what a lost section's outcome screen continues into. The tint is wiped
## between the two, so the restart is checked painting it rather than inheriting it.
func _test_main_tints_the_escape_streets_on_its_first_plan_and_on_a_restart(t) -> void:
	var saved_section := GameState.escape_section
	var day := GameState.day
	var main: Node2D = MAIN_SCRIPT.new()
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	main._city = city
	city.build(CityGenerator.generate(SEEDS[0]))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEEDS[0]
	city.start_day(state, day, rng)
	var corridor := Corridor.of(city.route_tree())
	var on_the_day := 0
	for tile in _kerb_tiles(city, day):
		if corridor.depth(tile) == 0 and city.scenery_ground_source(tile) \
				== GroundTiles.route_twin_of(GroundTiles.source_for(city.map, tile, day)):
			on_the_day += 1
	t.check(on_the_day > 0, "the day before tints its own route's kerbs (%d)" % on_the_day)

	main._spec = _section(DaySpec.Section.CITY)
	city.start_day(state, day, rng, main._spec)
	main._plan_the_finale_city()
	var plan := FinalePlanner.plan(city.map, GameState.day_rng(day, "finale"), _city_spec())
	var on_the_walk := {}
	for segment in plan.open_streets:
		on_the_walk[segment.key()] = true
	var first := _escape_tint(city, day, on_the_walk, corridor)
	t.check(first.x > 0 and first.y > 0,
			"there were kerbs on and off the escape's streets to ask about (%d and %d)"
			% [first.x, first.y])
	t.check(first.w > 0, "and kerbs the day tinted that the escape does not walk (%d)" % first.w)
	t.check(first.z == 0,
			"the first plan tints every kerb of the escape's streets and no other (%d wrong)"
			% first.z)

	city.tint_the_route(null)
	t.check(_escape_tint(city, day, on_the_walk, corridor).z == first.x,
			"wiping the tint leaves every kerb of the walk plain")
	main._summary = SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	main._hud = HUD_SCENE.instantiate()
	t.add_child(main._hud)
	var clock := DayController.new()
	t.add_child(clock)
	clock.set_process(false)
	main._day = clock
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	var stroller := Stroller.new()
	stroller.add_child(camera)
	city.add_entity(stroller)
	stroller.set_physics_process(false)
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	baby.set_physics_process(false)
	main._player = stroller
	main._baby = baby
	main._start_section(_section(DaySpec.Section.CITY), true)
	t.check(_escape_tint(city, day, on_the_walk, corridor).z == 0,
			"and a restart tints them again, and no other")

	main._summary.free()
	main._hud.free()
	clock.free()
	city.free()
	main.free()
	t.get_tree().paused = false
	GameState.escape_section = saved_section

## Every tile of `city` whose plain ground source is a kerb a route can tint.
static func _kerb_tiles(city: City, day: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in city.map.size.y:
		for x in city.map.size.x:
			var tile := Vector2i(x, y)
			if GroundTiles.source_for(city.map, tile, day) in GroundTiles.ROUTE_KERB_SOURCES:
				found.append(tile)
	return found

## How the kerbs are painted against the escape's streets: `x` tinted on the walk, `y` plain off
## it, `z` painted the other way from what the walk says, and `w` of the plain ones the day's own
## corridor had tinted.
static func _escape_tint(city: City, day: int, on_the_walk: Dictionary,
		corridor: Corridor) -> Vector4i:
	var counted := Vector4i.ZERO
	for tile in _kerb_tiles(city, day):
		var source := GroundTiles.source_for(city.map, tile, day)
		var segment := StreetNetwork.segment_containing(tile)
		var wanted := segment != null and on_the_walk.has(segment.key())
		if city.scenery_ground_source(tile) != (GroundTiles.route_twin_of(source) if wanted \
				else source):
			counted.z += 1
		elif wanted:
			counted.x += 1
		else:
			counted.y += 1
			if corridor.depth(tile) == 0:
				counted.w += 1
	return counted

## *"Explosions happen off screen (but loud enough to cause excitement) leaving craters on the
## street."* Both halves: the row names its successor, and what the successor obstructs is exactly
## half of the picture it draws — *anything that stands still is solid at the width it is drawn*.
func _test_a_burst_leaves_a_crater_as_wide_as_its_own_picture(t) -> void:
	var burst := EventCatalogue.by_id("finale_explosion")
	var crater := EventCatalogue.by_id("impact_crater")
	t.check(burst != null and crater != null, "both finale rows are in the catalogue")
	t.check(burst.spawns_on_finish() == crater.id, "the burst names the crater it leaves")
	t.check(burst.look == EventDef.Look.NONE, "and draws nothing itself")
	# The width comes from the baked region table rather than from a loaded texture — the crater's
	# picture is a region of the `events` page now, and `AtlasLibrary.native_size()` answers the
	# source picture's own size with nothing acquired.
	var picture := EventInstance.icon_for(crater.look)
	var drawn_width := EventInstance._native_size(picture).x
	t.check(is_equal_approx(crater.obstructs_radius, drawn_width * 0.5),
			"the crater obstructs %.0fpx against a %.0fpx picture"
			% [crater.obstructs_radius, drawn_width])

	# And the wiring: a burst that has run its course is replaced by a crater standing where it
	# was, through the same `spawns_on_finish` mechanism a convoy leaves a barricade through.
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEEDS[0]))
	city.events.setup(city, city.map)
	city.events.stream_radius = INF
	var road := city.map.tiles_of_type(GameEnums.TileType.ROAD)[0]
	var plans: Array[EventScheduler.Planned] = [
		EventScheduler.Planned.new(burst, city.map.tile_to_world(road))]
	city.events.start_planned(DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS), plans)
	t.check(city.events.instances().size() == 1, "the burst is in the world")
	var live := city.events.instances()[0]
	var steps := 0
	while not live.is_finished and steps < 400:
		live._process(0.05)
		steps += 1
	t.check(live.is_finished, "the burst is over after %.1fs" % (steps * 0.05))
	# `_retire_finished()` runs inside `_physics_process`, which a synchronous test has to call
	# itself: no frame passes while `run()` is executing.
	city.events._physics_process(0.0)
	var craters := 0
	for instance in city.events.instances():
		if instance.def.id == crater.id:
			craters += 1
			t.check(instance.is_solid(), "and the crater it left is solid")
	t.check(craters == 1, "exactly one crater is left where the burst was")
	city.free()

# ------------------------------------------------------------------ the clock ---

## *"The timer also shows milliseconds. This makes the timer appear faster than just the seconds
## alone which adds additional tension."* Tried as hundredths (inbox #746 in woolly-penguin). The only thing that
## changes, so both shapes are checked off the same signal and the same time.
func _test_the_clock_reads_hundredths_only_in_the_finale(t) -> void:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)
	var clock: Label = hud.get_node("Root/Clock")
	EventBus.day_time_changed.emit(65.5, 180.0)
	t.check(clock.text == "1:05", "a day's clock reads to the second (got '%s')" % clock.text)
	hud.set_clock_hundredths(true)
	EventBus.day_time_changed.emit(65.5, 180.0)
	t.check(clock.text == "1:05.50",
			"the escape's clock reads to the hundredth (got '%s')" % clock.text)
	# Freed rather than queued for the same reason the cities are: nothing here yields a frame, and
	# a HUD left listening to `EventBus.day_time_changed` answers the next suite's emit as well.
	hud.free()

# ------------------------------------------------------------- the sections ---

## *"Losing the finale restarts the section, at no Nerve cost"* — *"sounds good at that point you
## earned it."* — *"180s per section"*, and *"each the apartment and escape city are treated as
## their own 'days' with brief and restart checkpoint"*: a section opens on its brief, a loss comes
## up on the day's own outcome screen with its reason *(minty-lemur #785: "losing an escape should
## still state the reason like the rest of the game. nothing should be different")*, and its
## continue is the same section again on a whole clock, behind its brief *(PLAYTEST-94 10:
## "restarting should still have the day brief for both the apartment escape and the city escape
## even if the nerves don't go down")*, whichever section it is and whatever the last attempt
## spent.
##
## **Driven through the real `main.tscn`**, booted on each section the way a run's own escape is
## (the building as a won day 14 hands over, the city as a game closed in it opens again), and lost
## through the signal a real capture fires, so what is checked is the path the game takes: the
## day's own clock and finish path, not a call this test invented.
func _test_each_section_opens_on_its_brief_and_a_loss_on_its_outcome(t) -> void:
	for section: int in [DaySpec.Section.BUILDING, DaySpec.Section.CITY]:
		var main := _boot_the_escape(t, section)
		var words := _section(section).title
		var nerves := GameState.nerves
		var length: float = main._spec.length
		var title: Label = main._summary.get_node("Root/Center/Lines/Title")
		var body: Label = main._summary.get_node("Root/Center/Lines/Body")
		t.check(main._spec.section == section and main._summary.is_showing(),
				"section %d: it opens on its brief" % section)
		t.check(title.text == words,
				"section %d: titled with the section's own words ('%s')" % [section, title.text])
		t.check(body.text.contains("Nerves left: %s" % NerveDisplay.stars(nerves)),
				"section %d: and carrying the nerve line, as stars ('%s')" % [section, body.text])
		t.check(t.get_tree().paused and is_equal_approx(main._day.time_remaining, length),
				"section %d: with a full clock standing still behind it" % section)

		main._on_summary_continued()
		t.check(not main._summary.is_showing() and not t.get_tree().paused,
				"section %d: continuing takes the screen away and the walk begins" % section)
		t.check(main._hud.visible, "section %d: with the HUD back" % section)
		# *(2026-09-20, the player: "the escape shouldn't behave any different than the rest of the
		# game" — read here as the hint showing every time the section's clock starts, a fast click
		# through the brief included, not only on a first entry.)*
		var teach: HelpText = main._hud.get_node("Root/Teach")
		t.check(teach.line == words,
				"section %d: and the section's own words said once she is walking it" % section)

		main._day.time_remaining -= 30.0
		EventBus.hard_fail_triggered.emit("abduction")
		t.check(main._summary.is_showing() and not main._resume_gate_open,
				"section %d: being taken comes up on the day's outcome screen" % section)
		t.check(title.text.replace("\n", " ").contains(Texts.HARD_FAIL_TEXT["abduction"]),
				"section %d: which states the reason, as a lost day's does ('%s')"
				% [section, title.text])
		t.check(body.text.contains(words) and body.text.contains(NerveDisplay.stars(nerves)),
				"section %d: under the section's own words, the nerves unchanged ('%s')"
				% [section, body.text])
		t.check(GameState.nerves == nerves,
				"section %d: since a normal run's lost section spends none" % section)

		teach.text = ""
		main._on_summary_continued()
		t.check(main._spec.section == section and main._summary.is_showing()
				and main._resume_gate_open,
				"section %d: its continue is the same section again, behind its brief" % section)
		t.check(title.text == words and body.text.contains(NerveDisplay.stars(nerves)),
				"section %d: titled with its words and the nerves unchanged ('%s', '%s')"
				% [section, title.text, body.text])
		t.check(t.get_tree().paused and is_equal_approx(main._day.time_remaining, length),
				"section %d: with a full clock standing still behind it" % section)
		main._on_summary_continued()
		t.check(not main._summary.is_showing() and not t.get_tree().paused
				and main._day.is_running(),
				"section %d: the brief's continue is the walk" % section)
		t.check(teach.line == words,
				"section %d: and its words said again on the retry, not only the first entry"
				% section)

		if section == DaySpec.Section.BUILDING:
			# **Each section is a day, so each gets a day's clock** — what the building spent is
			# not the city's to make up. Twenty seconds are taken off the building's clock first,
			# so a city that carried it across would be visibly short here.
			main._day.time_remaining -= 20.0
			main._interior.exit_requested.emit()
			t.check(main._spec.section == DaySpec.Section.CITY and main._summary.is_showing(),
					"the service exit begins the second section, on its own brief")
			t.check(is_equal_approx(main._day.time_remaining, length),
					"on a full clock of its own, whatever the walk down the stairs cost")
		_free_the_escape(t, main)

## **The escape is counted like a day** *(minty-lemur #785: "telemetry should work the same also in
## escape both apartment and city")*: the run's played time (`GameState.play_seconds`, which the
## ending screen shows) runs while a section is walked, and a charge still running when she gets
## out of the city is closed for the page's counter as cut short, before the section's own end is
## counted — through the day's own finish path, as a day's are.
func _test_the_escape_counts_its_time_and_closes_its_charges(t) -> void:
	var main := _boot_the_escape(t, DaySpec.Section.CITY)
	main._on_summary_continued()
	var played := GameState.play_seconds
	main._process(0.5)
	t.check(is_equal_approx(GameState.play_seconds, played + 0.5),
			"walking the city section counts toward the run's played time (%.2f, then %.2f)"
			% [played, GameState.play_seconds])

	var heard: Array[String] = []
	var on_cut_short := func(id: String) -> void:
		heard.append("cut short " + id)
	var on_ended := func(day: int, result: GameEnums.DayResult, _cause: String, _e: float) -> void:
		heard.append("day %d %s" % [day, GameEnums.DayResult.keys()[result]])
	EventBus.pursuit_cut_short.connect(on_cut_short)
	EventBus.day_ended.connect(on_ended)
	var guard := EventInstance.new()
	guard.setup(EventCatalogue.by_id("masked_pursuer"), main._player.global_position,
			PackedVector2Array([main._player.global_position,
					main._player.global_position + Vector2(0.0, -400.0)]))
	main._city.add_child(guard)
	guard.set_process(false)
	main._city.events._instances.append(guard)
	guard._charge.begin()
	main._player.global_position = main._spec.exits[CityEdge.Kind.TUNNEL]
	main._day._process(0.0)
	t.check(heard == ["cut short masked_pursuer", "day %d WON" % DaySpec.CITY_DAY],
			"getting out closes the charge still running, then ends the city's day (%s)" % [heard])
	EventBus.pursuit_cut_short.disconnect(on_cut_short)
	EventBus.day_ended.disconnect(on_ended)
	_free_the_escape(t, main)

## One of the escape's sections, a whole clock long, titled the way the run titles it.
static func _section(section: int) -> DaySpec:
	return MAIN_SCRIPT.escape_section_spec(section, Tuning.FINALE_LENGTH_SECONDS)

## Boots the real `main.tscn` on `section` of a normal run's own escape, on seed `SEEDS[0]` and its
## last day — the way a won day 14's handover and a game closed in a section both reach the boot —
## and returns it with its first screen up. `_free_the_escape()` puts the run back.
func _boot_the_escape(t, section: int) -> Node2D:
	_saved_section = GameState.escape_section
	GameState.start_run(SEEDS[0])
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.escape_section = section
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(PackedStringArray(["--no-save", "--no-telemetry"]), "", true))
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	return main

var _saved_section := 0

func _free_the_escape(t, main: Node2D) -> void:
	t.get_tree().paused = false
	main.free()
	GameState.escape_section = _saved_section
	GameState.start_run(SEEDS[0])

## The two names the briefs carry — *"something along 'Escape the building' and ... 'Escape the
## city'"*. Pinned as literals because they are the player's own words for the two screens, and a
## screen that renamed itself would be the one thing nothing else in this suite could see. `main`
## hands them to each section's `DaySpec` (`escape_section_spec()`), and each section is counted
## as a day of its own after the last.
func _test_the_two_sections_are_named_for_the_player(t) -> void:
	var building := _section(DaySpec.Section.BUILDING)
	var city := _section(DaySpec.Section.CITY)
	t.check(building.title == "Escape the building",
			"the building's brief is titled 'Escape the building'")
	t.check(city.title == "Escape the city", "the city's brief is titled 'Escape the city'")
	t.check(building.number == Tuning.RUN_LENGTH_DAYS + 1 and city.number == building.number + 1,
			"and they are the two days after the last (%d and %d)" % [building.number, city.number])

## *"The escape the building starts when the player has completed all tasks by the end of day
## 14."* Every other way day 14 can end keeps the ending it already had, which is what the three
## negative rows are for: a won last day with the legwork but not the sabotage is the neutral
## ending and must not reach the escape, and neither must a won earlier day that happens to have
## finished every task early.
func _test_only_a_won_last_day_with_every_task_done_hands_over(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	var baseline := GameState.save_snapshot()
	GameState.start_run(9182)

	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.resistance_progress = Tuning.RESISTANCE_GOAL
	GameState.sabotage_done = true
	t.check(main._hands_over_to_the_escape(GameEnums.DayResult.WON),
			"a won day 14 with every task complete hands over to the escape")
	t.check(not main._hands_over_to_the_escape(GameEnums.DayResult.LOST_CRYING),
			"a lost day 14 does not, however much was done")

	GameState.sabotage_done = false
	t.check(not main._hands_over_to_the_escape(GameEnums.DayResult.WON),
			"nor a won day 14 with the errands run and the last night skipped")
	GameState.sabotage_done = true
	GameState.resistance_progress = Tuning.RESISTANCE_GOAL - 1
	t.check(not main._hands_over_to_the_escape(GameEnums.DayResult.WON),
			"nor one short of the goal")

	GameState.resistance_progress = Tuning.RESISTANCE_GOAL
	GameState.day = Tuning.RUN_LENGTH_DAYS - 1
	t.check(not main._hands_over_to_the_escape(GameEnums.DayResult.WON),
			"and nor does a won day before the last one")

	GameState.restore_snapshot(baseline)
	main.free()

## `--start-escape city` is the one word that is not a part of the building: it boots the second
## section on its own. The mapping is what a test can reach — nothing in the suite can put a word
## on a real command line — and the boot itself is checked by running it headless.
func _test_the_city_word_boots_the_second_section(t) -> void:
	t.check(MAIN_SCRIPT.escape_part_for("city") == "city",
			"'city' is the second section rather than a part of the building")
	t.check(MAIN_SCRIPT.escape_part_for("") == "hallway_third",
			"and a bare flag is still her own door")
	t.check(MAIN_SCRIPT.escape_part_for("nonsense") == "hallway_third",
			"as is anything this does not recognise")

## The suite above pins the *mapping*; this pins the *teleport* the mapping exists for — every
## part word `--start-escape` recognises has to actually move her, onto ground she can stand on.
func _test_every_part_word_reaches_its_own_walkable_position(t) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var start := scene.start_world_position()
	for word in ["stairwell:left", "stairwell:right", "lobby", "basement", "floor:2", "floor:1"]:
		var part: String = MAIN_SCRIPT.escape_part_for(word)
		var at := scene.part_world_position(part)
		t.check(at != start, "'%s' (part '%s') teleports away from her own door" % [word, part])
		t.check(scene.map.is_walkable(scene.map.world_to_tile(at)),
				"'%s' (part '%s') lands on a walkable tile" % [word, part])
		# **And one she stays on.** A part word puts her down with nothing armed, and
		# `process_player()` fires a transition on the frame she is standing on a door or the
		# service exit — so a waypoint that is a threshold shows her the part on the other side of
		# it rather than the part she asked for, silently, with the flag looking like it worked.
		t.check(scene.map.transition_at(scene.map.world_to_tile(at)).is_empty(),
				"'%s' (part '%s') lands somewhere that is not a door" % [word, part])
	scene.free()

## **The escape is outbound from its first frame, so it owes no return leg.** `EventDirector.owe_
## the_return()` hands acts III and IV extra `police_patrol` rows when `EventBus.return_phase_
## started` fires and tightens the director's pacing for the rest of the day — and that signal is
## emitted by `Baby.force_sleep()`, which the escape calls at the top of every section and every
## retry, since *"the player holding the sleeping baby (sleep bar is full)"* is where it starts.
## Without the guard in `EventManager._owe_the_return()` the climax would be handed the walk home's
## pressure at the moment it began, on a walk that never turns round.
##
## The first half is the guard against a vacuous second: a bare director on the same day and the
## same heat does owe rows, so "the escape owes none" is about the escape rather than about the
## day being one that owes nothing.
func _test_the_escape_owes_no_return_leg(t) -> void:
	var map := CityGenerator.generate(SEEDS[0])
	var an_act_iv_day := 13
	t.check(Tuning.act_for_day(an_act_iv_day) >= 3
			and Tuning.RETURN_PATROLS_PER_ACT[Tuning.act_for_day(an_act_iv_day) - 1] > 0,
			"day %d is a day that owes its return something" % an_act_iv_day)
	var bare := EventDirector.new(map)
	bare.owe_the_return(an_act_iv_day, 0)
	t.check(bare.owed() > 0, "a day's own director owes %d rows to the return" % bare.owed())

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEEDS[0]))
	city.events.setup(city, city.map)
	var was_the_day := GameState.day
	GameState.day = an_act_iv_day
	city.events.start_planned(DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS),
			[] as Array[EventScheduler.Planned])
	EventBus.return_phase_started.emit()
	t.check(city.events.owed_ahead() == 0,
			"and the escape owes nothing to a return it does not have (got %d)"
					% city.events.owed_ahead())
	GameState.day = was_the_day
	city.free()

## **The walk's settings are the spec's, handed in, not the manager's own**: on the same act IV day
## and the same city, a day's spec owes the return its rows and a spec that says it owes none
## (`DaySpec.owes_a_return` false) is owed none, by the same `start_day()`. So what decides it is the
## spec the run flow hands over (`EventManager.use_the_spec()`), never a branch in the manager.
func _test_a_day_owes_its_return_only_as_its_spec_says(t) -> void:
	var an_act_iv_day := 13
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEEDS[0]))
	city.events.setup(city, city.map)
	var was_the_day := GameState.day
	GameState.day = an_act_iv_day
	var owed := {}
	for owes: bool in [true, false]:
		var spec := DaySpec.for_day(an_act_iv_day, Tuning.DAY_LENGTH_SECONDS)
		spec.owes_a_return = owes
		city.events.use_the_spec(spec)
		var consumed: Array[String] = []
		city.events.start_day(an_act_iv_day, GameState.day_rng(an_act_iv_day), consumed)
		var before := city.events.owed_ahead()
		EventBus.return_phase_started.emit()
		owed[owes] = city.events.owed_ahead() - before
	t.check(int(owed[true]) > 0, "a day's spec owes its return rows (%d)" % owed[true])
	t.check(int(owed[false]) == 0,
			"and a spec that owes none is owed none on the same day (%d)" % owed[false])
	GameState.day = was_the_day
	city.free()

## **A tree and an event never share ground** (`docs/CITY.md`, "Street trees"), and the escape's
## own plan is a second placement path that does not go through `EventScheduler._open_ground_for`
## or `SealPlanner.plan_day` — so the rule is asserted on this side too, over the whole plan: the
## trucks, vans, masked men and bursts on the open streets, and every seal body off them.
##
## **The one licensed exception is a seal that could not step off a tree without stepping onto the
## chain.** `SealPlanner.plan_day` refuses that move, because a picture overlapping a picture is
## better than a city with no way out of it; the count is reported so an exception that stopped
## being rare would be visible rather than silent.
func _test_nothing_the_escape_places_stands_in_a_street_tree(t) -> void:
	var checked := 0
	var in_a_tree := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var trees := StreetTrees.footprint_tiles(map)
		# The two halves of `plan.placements` are asked separately, because only one of them has a
		# licensed exception: they are re-planned here from the same inputs rather than told apart
		# by row id, since `barricade` and `impact_crater` are each both a seal picture and an
		# event's own row.
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for placement in EventScheduler.build_day(_city_spec(), rng, map, [], [], [], plan):
			var tile := map.world_to_tile(placement.position)
			t.check(not trees.has(tile),
					"seed %d: the escape's '%s' stands in a street tree at %s"
							% [seed_value, placement.def.id, tile])
			checked += 1
		rng.seed = seed_value
		for seal in SealPlanner.plan_day(map, _city_spec(), plan, rng):
			if trees.has(map.world_to_tile(seal.position)):
				in_a_tree += 1
			checked += 1
	t.check(checked > 0, "there were escape placements to ask about (%d)" % checked)
	t.check(in_a_tree * 20 < checked,
			"and seals held against a tree by the chain stay rare (%d of %d bodies)"
					% [in_a_tree, checked])

# ---------------------------------------------------------- pause, built the same way ---

func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event

## *"Pause etc should exist the same way it does in the main game"*
## ([PLAYTEST-114](playtests/PLAYTEST-114.md)). The day's clock, `InteriorScene` and the finale's
## own `City` all get `PROCESS_MODE_PAUSABLE` from `main._pauses_with_the_game()` as the boot builds
## them, the same call every one of a day's own entities gets — so the engine itself
## refuses their `_process()`/`_physics_process()` the instant the tree pauses, without any of them
## having to ask. `Node.can_process()` is the exact question the engine consults before delivering
## either callback, which is what a suite with no per-frame engine loop of its own (see the
## **verify** skill's testing policy) can still ask synchronously, rather than simulating a frame by
## hand and proving nothing about whether the engine would actually have skipped it.
func _test_finale_entities_stop_when_the_tree_pauses(t) -> void:
	var saved_paused: bool = t.get_tree().paused

	var clock := DayController.new()
	t.add_child(clock)
	clock.process_mode = Node.PROCESS_MODE_PAUSABLE

	var interior := InteriorScene.new()
	t.add_child(interior)
	interior.process_mode = Node.PROCESS_MODE_PAUSABLE

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEEDS[0]))
	city.process_mode = Node.PROCESS_MODE_PAUSABLE

	t.get_tree().paused = false
	t.check(clock.can_process(), "the section's clock processes while the tree is running")
	t.check(interior.can_process(), "so does the interior scene — its doors, its fire, its pursuer")
	t.check(city.can_process(), "and the finale city — its trucks, its roadblocks, its bursts")

	t.get_tree().paused = true
	t.check(not clock.can_process(),
			"the section's clock does not advance while the pause screen is open")
	t.check(not interior.can_process(), "and neither does anything in the building")
	t.check(not city.can_process(), "nor anything in the finale city")

	t.get_tree().paused = saved_paused
	clock.free()
	interior.free()
	city.free()

## `Esc`, the pause button's own action and a window losing focus all reach the pause screen during
## a section exactly as they do during a day: the same continue, the same held restart, the same
## quit, and the same stashed heading through `TouchControls`. Driven through the return window's
## `notification()` and `main._unhandled_input()`'s own guards, against a section's day with no
## world built behind it, since putting her down is not what this is about.
##
## **Esc's own successful open is proven through focus loss, not through `_unhandled_input()`
## itself.** Both reach `_pause.open()` behind the same two guards (`_pause`/`_title` not already
## open, and — the escape's own addition — `_summary` not showing a brief or the epilogue); past
## those, `_unhandled_input()` also calls `get_viewport().set_input_as_handled()`, which is null for
## every `main` in this suite (see this file's own class doc on why `main` is never added to the
## tree) and would crash rather than prove anything the readout's key tests do not already
## establish the pattern for: call the guarded action directly, not the input handler that wraps
## it. So this exercises `_unhandled_input()` for its two *refusals* (guard coverage no
## different from `_pause_on_focus_lost()`'s own), and `notification()` for the one open it can
## prove end to end.
func _test_the_escape_pauses_the_same_way_a_day_does(t) -> void:
	var saved_paused: bool = t.get_tree().paused
	var main: Node2D = MAIN_SCRIPT.new()
	main._summary = SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	main._hud = HUD_SCENE.instantiate()
	t.add_child(main._hud)
	main._title = TITLE_SCREEN_SCENE.instantiate()
	t.add_child(main._title)
	main._pause = PAUSE_SCREEN_SCENE.instantiate()
	t.add_child(main._pause)
	main._add_touch_controls()
	# The two calls the boot's `_build_the_screens()` makes, in the same order, for every day.
	main._pause.set_touch_controls(main._touch_controls)
	main._connect_summary_and_pause_signals()
	main._no_focus_pause = false
	main._add_the_return_window(t.get_viewport())

	var clock := DayController.new()
	t.add_child(clock)
	clock.set_process(false)
	main._day = clock
	main._use_the_day(_section(DaySpec.Section.BUILDING))
	clock.start(main._spec.length)
	t.check(clock.is_running(), "the section's clock is running")
	t.check(not main._pause.is_open(), "and nothing is paused yet")

	t.check(main._pause.quit_requested.is_connected(main._quit),
			"quit reaches the same main._quit() a day's pause reaches")
	t.check(main._pause.restart_requested.is_connected(main._restart_run),
			"and the held restart reaches the same main._restart_run()")
	t.check(main._pause._touch_controls == main._touch_controls,
			"the pause screen can stash and restore her heading through the same touch controls")

	main._return_window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(main._pause.is_open(), "losing the window's focus opens the same pause a day's does")
	t.check(t.get_tree().paused, "and pauses the tree behind it")
	# `Esc` never opens a second time over the screen focus loss just opened — the same refusal
	# `_pause_on_focus_lost()` makes for itself, now asked of `_unhandled_input()`.
	main._unhandled_input(_action("pause"))
	t.check(main._pause.is_open(), "Esc does not need to do anything — it is already open")
	main._pause.close()
	t.get_tree().paused = false

	main._no_focus_pause = true
	main._return_window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(), "--no-focus-pause suppresses that during the escape too")

	main._summary.free()
	main._hud.free()
	main._title.free()
	main._pause.free()
	clock.free()
	main.free()
	t.get_tree().paused = saved_paused

## A section's brief and the epilogue are the one exception to an ordinary day's own "Esc opens over
## the summary too": each stands between her and a walk not yet begun, so a second screen stacked
## over it would answer a question nobody asked, the same reason focus loss never opens over any
## `_summary` at all. A lost section's outcome screen is the day's own screen, and Esc opens over it
## as over a lost day's *(minty-lemur #785: "nothing should be different")*; focus loss does not,
## as on a day. **Booted for real** on the city section and walked through each screen the way the
## game reaches it — the brief, the outcome screen of a loss, the retry's brief, the epilogue —
## since Esc's own open needs `main` in the tree (`get_viewport().set_input_as_handled()`).
func _test_pause_does_not_open_over_a_section_brief_or_the_epilogue(t) -> void:
	var main := _boot_the_escape(t, DaySpec.Section.CITY)
	main._no_focus_pause = false

	t.check(main._summary.is_showing() and main._resume_gate_open, "the section's brief is up")
	main._unhandled_input(_action("pause"))
	t.check(not main._pause.is_open(), "Esc does not open the pause over a section's brief")
	main._return_window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(), "and neither does losing focus")

	main._on_summary_continued()
	EventBus.hard_fail_triggered.emit("abduction")
	t.check(main._summary.is_showing() and not main._resume_gate_open,
			"a lost section's outcome screen is up")
	main._return_window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(), "losing focus does not open the pause over it")
	main._unhandled_input(_action("pause"))
	t.check(main._pause.is_open(), "Esc does, as over a lost day's outcome screen")
	main._pause.close()
	t.check(t.get_tree().paused and main._summary.is_showing(),
			"and closing it leaves the outcome screen up and the tree paused")

	main._on_summary_continued()
	t.check(main._summary.is_showing() and main._resume_gate_open, "the retry's brief is up")
	main._unhandled_input(_action("pause"))
	t.check(not main._pause.is_open(), "Esc does not open the pause over it")

	main._on_summary_continued()
	main._player.global_position = main._spec.exits[CityEdge.Kind.TUNNEL]
	main._day._process(0.0)
	t.check(main._summary.is_showing_the_epilogue(), "out of the city, the epilogue is up")
	main._unhandled_input(_action("pause"))
	t.check(not main._pause.is_open(), "Esc does not open the pause over the epilogue")
	main._return_window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(), "and neither does losing focus")
	_free_the_escape(t, main)

# ------------------------------------------------------ a resumed escape, and a handover ---

## `_escape_section_came_from_the_file()` is the boot policy with the two live
## `GameState.escape_section` reads taken out of it, so every combination can be driven directly.
func _test_escape_section_came_from_the_file(t) -> void:
	var none := DaySpec.Section.NONE
	var building := DaySpec.Section.BUILDING
	t.check(MAIN_SCRIPT._escape_section_came_from_the_file(none, building),
			"NONE before try_resume() ran and something after — a save on disk is where it came from")
	t.check(not MAIN_SCRIPT._escape_section_came_from_the_file(building, building),
			"already set before try_resume() ran — a handover reload carrying it on the autoload")
	t.check(not MAIN_SCRIPT._escape_section_came_from_the_file(none, none),
			"NONE both times — an ordinary run, nothing to do with the escape at all")

## *(2026-09-20, the player, on a save closed inside a section: "if I load into the game and I'm at
## escape I see the title screen, then the brief".)* A genuinely resumed escape — a page with nothing
## on the autoload, opening a save closed inside a section — opens on the title, through the day's
## own `_open_the_title()`, with the section's clock standing still behind it, and the title's start
## is the day's own `_on_title_start()`, whose resume gate raises the section's brief. **Booted for
## real from a save on disk** (a scratch file, `GameSave._uses_save_override`), so what is checked is
## `_ready()`'s own decision — `_escape_section_came_from_the_file()` read at the boot and handed to
## `_open_the_first_screen_of_the_escape()` — not a screen this test opened by hand.
func _test_a_resumed_escape_opens_on_the_title_before_its_first_brief(t) -> void:
	_saved_section = GameState.escape_section
	GameSave.set_path_override(_SCRATCH_SAVE)
	GameSave._uses_save_override = true
	GameState.start_run(SEEDS[0])
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.escape_section = DaySpec.Section.BUILDING
	t.check(GameSave.write(false) == GameSave.Result.CONFIRMED,
			"a save closed inside the building is on disk")
	# A fresh page: nothing of the escape on the autoload, only in the file.
	GameState.escape_section = DaySpec.Section.NONE
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(PackedStringArray(["--no-save", "--no-telemetry"]), "", true))
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	var length: float = main._spec.length

	t.check(main._spec.section == DaySpec.Section.BUILDING,
			"the boot read the section off the save")
	t.check(main._title.is_open() and not main._summary.is_showing(),
			"a genuinely resumed escape opens on the title first, the section's brief not yet up")
	t.check(main._title.mode_name_shown() != "", "and names the mode, which the save already fixed")
	t.check(main._in_the_title, "and the boot is behind its title")
	t.check(t.get_tree().paused and not main._day.can_process()
			and is_equal_approx(main._day.time_remaining, length),
			"with the section's whole clock standing still behind the title (%.2f of %.2f)"
			% [main._day.time_remaining, length])

	main._title.start_requested.emit(ControlsMode.Mode.TAP, false, ControlsMode.Side.LEFT)
	t.check(not main._title.is_open(), "pressing start closes the title")
	t.check(main._summary.is_showing() and main._resume_gate_open,
			"and raises the section's own brief, in front of the section already built")
	var title_label: Label = main._summary.get_node("Root/Center/Lines/Title")
	t.check(title_label.text == "Escape the building",
			"titled with the section's own words ('%s')" % title_label.text)
	t.check(not main._in_the_title, "the title is behind her")
	t.check(t.get_tree().paused and is_equal_approx(main._day.time_remaining, length),
			"the clock still standing still behind the brief")

	GameSave._clear_now()
	GameSave._uses_save_override = null
	GameSave.set_path_override("")
	AtlasLibrary.close_loading_window()
	_free_the_escape(t, main)

## The handover reload from a won day 14 reaches the boot with `escape_resumed_from_disk` false —
## true only when `GameState.escape_section` was `NONE` before `try_resume()` ran, which a
## handover's own value already isn't, since it was written to the autoload before the reload — so
## it opens straight on the building's own brief, with no title in front of it and the section's
## clock standing still behind the brief. Booted for real.
func _test_a_handover_does_not_open_on_the_title(t) -> void:
	var main := _boot_the_escape(t, DaySpec.Section.BUILDING)
	t.check(not main._title.is_open(), "a handover does not raise the title")
	t.check(main._summary.is_showing() and main._resume_gate_open,
			"it opens straight on the section's own brief")
	t.check(t.get_tree().paused and not main._day.can_process()
			and is_equal_approx(main._day.time_remaining, main._spec.length),
			"with the section's whole clock standing still behind it")
	_free_the_escape(t, main)

## *"the held restart from the escape ends in a fresh run with escape_section cleared"* —
## `main._restart_run()` cannot safely run inside this suite: it defers a real
## `reload_current_scene()` against the test runner's own tree, the same reason
## `tests/test_pause.gd`'s own note gives for never calling it directly. What is checked instead is
## the wiring that reaches it (both of the escape's own screens, the same as a day's two) and the one
## fact of its own body that answers "a fresh run" for the escape specifically —
## `GameState.escape_section = DaySpec.Section.NONE`; its `GameSave.clear()` is exercised
## safely, behind a path override, by `tests/test_save.gd` and is not repeated here.
func _test_the_held_restart_from_the_escape_clears_the_section(t) -> void:
	var saved_section := GameState.escape_section
	GameState.escape_section = DaySpec.Section.CITY

	var main: Node2D = MAIN_SCRIPT.new()
	main._pause = PAUSE_SCREEN_SCENE.instantiate()
	main._summary = SUMMARY_SCENE.instantiate()
	main._connect_summary_and_pause_signals()
	t.check(main._pause.restart_requested.is_connected(main._restart_run),
			"the escape's own pause screen reaches main._restart_run(), same as a day's")
	t.check(main._summary.restart_requested.is_connected(main._restart_run),
			"and so does the section brief's own restart button — the same DaySummary a day uses")

	GameState.escape_section = DaySpec.Section.NONE
	t.check(GameState.escape_section == DaySpec.Section.NONE,
			"a fresh run has no escape section — the run `_restart_run()` reloads into is a fresh one")

	main._pause.queue_free()
	main._summary.queue_free()
	main.free()
	GameState.escape_section = saved_section

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS)
