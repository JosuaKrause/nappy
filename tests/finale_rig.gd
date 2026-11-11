@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## **The cases behind `test_finale_a.gd`, `_b.gd` and `_c.gd`; not a suite itself.** Each part runs
## the cases it owns, so no suite runs two minutes serial; the parts together make every check the
## one suite made.
## The escape: the two chains through the city, the walls off them, the clock, and what a lost
## section costs.
##
## **What is asserted here is the shape of the walk rather than any number in it.** The chains are
## grown from the city's own lattice, so nothing about their length or their exact route is stable
## across a seed — what has to be true on every seed is that there are two of them, that they do
## not overlap, that each passes three distinct pieces of calm ground on its way to its own edge,
## and that everything off them is shut.
##
## **Its cities come from the cache of generated cities** (`tests/city_map_cache.gd`): each
## seed's city is generated once in the test process and every case is handed a copy of its own,
## the same city `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const RoadblockRig := preload("res://tests/escape_roadblock_rig.gd")
const Reach := preload("res://tests/seal_reach_rig.gd")
const GivenPlanner := preload("res://tests/given_planner.gd")
const Boot := preload("res://tests/booted_main.gd")
const UI := preload("res://tests/ui_screens.gd")
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

## Every case of the escape, in the order the one suite ran them.
const CASES: Array[String] = [
	"_test_the_two_chains_part_at_the_door_and_never_meet_again",
	"_test_each_chain_passes_three_distinct_calm_areas",
	"_test_each_chain_reaches_its_own_edge",
	"_test_every_street_off_the_chains_is_sealed",
	"_test_both_exits_are_reachable_through_the_open_cells_alone",
	"_test_both_exits_are_reachable_past_every_body_the_escape_stands",
	"_test_both_exits_are_reachable_past_every_standing_lethal_reach",
	"_test_a_street_of_vans_leaves_a_walk_past_every_reach",
	"_test_no_street_of_the_walk_stands_two_roadblocks",
	"_test_a_roadblock_band_costs_nothing",
	"_test_the_far_guard_leaves_with_his_partner",
	"_test_neither_guard_walks_off_over_a_building",
	"_test_a_lured_off_roadblock_raises_no_mark_over_her",
	"_test_luring_its_guard_off_is_the_way_past_a_roadblock",
	"_test_no_two_roadblocks_notice_her_from_the_same_ground",
	"_test_an_escape_guard_warns_on_the_screen_and_on_top",
	"_test_the_players_seed_is_winnable_past_its_roadblocks",
	"_test_the_escape_stands_its_rows_on_the_days_own_ground",
	"_test_an_alley_mouth_wall_fits_the_mouth",
	"_test_nothing_the_escape_stands_reaches_over_a_building",
	"_test_a_restart_plans_the_same_escape",
	"_test_the_escape_bag_keeps_the_players_order",
	"_test_every_street_draws_one_marble",
	"_test_the_game_draws_the_escape_from_tunings_bag",
	"_test_the_service_exit_is_beside_the_home_block",
	"_test_nothing_the_finale_places_stands_where_she_comes_out",
	"_test_no_lethal_field_covers_the_ground_she_comes_out_on",
	"_test_the_finale_city_grows_no_corridor",
	"_test_main_tints_the_escape_streets_on_its_first_plan_and_on_a_restart",
	"_test_a_burst_leaves_a_crater_as_wide_as_its_own_picture",
	"_test_the_clock_reads_hundredths_only_in_the_finale",
	"_test_each_section_opens_on_its_brief_and_a_loss_on_its_outcome",
	"_test_the_escape_counts_its_time_and_closes_its_charges",
	"_test_the_two_sections_are_the_two_days_after_the_last",
	"_test_only_a_won_last_day_with_every_task_done_hands_over",
	"_test_every_part_word_reaches_its_own_walkable_position",
	"_test_the_escape_owes_no_return_leg",
	"_test_a_day_owes_its_return_only_as_its_spec_says",
	"_test_nothing_the_escape_places_stands_in_a_street_tree",
	"_test_the_escape_pauses_the_same_way_a_day_does",
	"_test_pause_does_not_open_over_a_section_brief_or_the_epilogue",
	"_test_a_resumed_escape_opens_on_the_title_before_its_first_brief",
	"_test_a_route_rig_carries_the_building_on_into_the_city",
	"_test_a_route_rig_boots_the_city_section_and_walks",
	"_test_a_route_rig_presses_only_the_first_brief_of_a_section",
	"_test_a_handover_does_not_open_on_the_title",
	"_test_the_held_restart_from_the_escape_clears_the_section",
]

## The cases at `indices` of `CASES`, in the order given. A case may be a coroutine.
func run_cases(t, indices: Array[int]) -> void:
	for index in indices:
		await call(CASES[index], t)

# --------------------------------------------------------------- the chains ---

## Paints `map` as day 1 of a fresh run would find its blocks (`CityState.begin_day()`), the ground
## the escape is planned on.
static func _paint_day_one(map: CityMap) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, 1)
	map.repaint(state)

static func _plan_for(seed_value: int) -> Dictionary:
	var map := MapCache.of(seed_value)
	_paint_day_one(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var walk := FinalePlanner.route(map)
	return {"map": map, "plan": walk,
			"placements": DayPlanner.plan_the_escape_city(map, walk, rng, _city_spec())}

## *"No overlapping routes"*: the choice is made once, at the door, and is the game's verb. The
## cell she leaves from is the one exception, since both walks have to start somewhere.
func _test_the_two_chains_part_at_the_door_and_never_meet_again(t) -> void:
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var plan: FinalePlanner.Plan = built["plan"]
		t.check(plan.chains.size() == 2, "seed %d plans two chains" % seed_value)
		var exit_map: CityMap = built["map"]
		var door: Vector2i = exit_map.world_to_tile(FinalePlanner.service_exit_world_position(exit_map)) \
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
			t.check(chain.stops.size() == FinalePlanner.FINALE_PARKS_PER_CHAIN,
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
			# halves of what `DayController.FINALE_EXIT_REACH` has to be worth.
			var at := map.tile_to_world(exit)
			t.check(DayController.FINALE_EXIT_REACH > Tuning.PLAYER_BODY_RADIUS,
					"the exit's reach covers her whole body on the tile")
			t.check(at.distance_to(map.tile_to_world(exit + Vector2i(0, 2))) \
					> DayController.FINALE_EXIT_REACH,
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
		var placements: Array[EventScheduler.Planned] = built["placements"]
		var sealed_at := {}
		for placement: EventScheduler.Planned in placements:
			if placement.def.obstructs_radius > 0.0:
				sealed_at[map.world_to_tile(placement.position)] = true
		# The one exempt street is the one she is standing in, not the one the front door opens
		# onto: on the last night she comes out of the service exit and never uses that door.
		var hers := map.network.segment_containing(
				map.world_to_tile(FinalePlanner.service_exit_world_position(map)))
		var open_and_unsealed := 0
		var closed := 0
		for segment in map.network.segments():
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
		var start := grid.node_at(map.world_to_tile(FinalePlanner.service_exit_world_position(map)))
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
		var placements: Array[EventScheduler.Planned] = built["placements"]
		var blocked := {}
		bodies += _block_every_body(t, map, placements, blocked)
		var reached := _flood_past_the_bodies(map, blocked,
				FinalePlanner.service_exit_world_position(map))
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
		var placements: Array[EventScheduler.Planned] = built["placements"]
		var blocked := {}
		_block_every_body(t, map, placements, blocked)
		reaches += _block_every_standing_reach(t, map, placements, blocked)
		var reached := _flood_past_the_bodies(map, blocked,
				FinalePlanner.service_exit_world_position(map))
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

## **Where the reach is what decides it, the walk still gets through.** A bag of vans alone, a van on
## every street that takes one (`_escape_rows_from()` with a bag of `{"abduction": 1}`, one marble a
## street), packs the walk with parked vans; a placement that kept a sidewalk open past each van's
## 22px body but not past its 54px reach could cut the walk to one exit. So with the rule
## (`WalkGround.held_by()`), both exits are reached from the door past every body and every reach,
## and this is what fails if the walk is not kept open (`WalkOpenRule` answering yes leaves seed
## 39's tunnel unreached).
const VAN_STREET_SEEDS := [1, 8, 39]

func _test_a_street_of_vans_leaves_a_walk_past_every_reach(t) -> void:
	var vans := 0
	for seed_value in VAN_STREET_SEEDS:
		var map := MapCache.of(seed_value)
		_paint_day_one(map)
		var bare := _bare_plan(map, seed_value)
		var placed := _escape_rows_from(map, bare, {"abduction": 1})
		vans += placed.size()
		var whole: Array[EventScheduler.Planned] = []
		whole.assign((bare["seals"] as Array[EventScheduler.Planned]).duplicate())
		whole.append_array(placed)
		var blocked := {}
		_block_every_body(t, map, whole, blocked)
		_block_every_standing_reach(t, map, whole, blocked)
		var reached := _flood_past_the_bodies(map, blocked,
				FinalePlanner.service_exit_world_position(map))
		for kind in [CityEdge.Kind.TUNNEL, CityEdge.Kind.BRIDGE]:
			var exit := map.tile_to_world(FinalePlanner.exit_tile(map, kind))
			var at := Vector2i(roundi(exit.x / BODY_FLOOD_STEP), roundi(exit.y / BODY_FLOOD_STEP))
			var found := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if reached.has(at + Vector2i(dx, dy)):
						found = true
			t.check(found, "seed %d, a van a street: the %s is reached past every van's reach"
					% [seed_value, "tunnel" if kind == CityEdge.Kind.TUNNEL else "bridge"])
	t.check(vans > 80, "there were streets full of vans to walk past (%d)" % vans)

## Marks every grid point within the lethal reach of a row the plan stands that is not mobile, is
## `hard_fail` and does not pursue, measured from where its `EventInstance` stands, and answers how
## many reaches it marked.
static func _block_every_standing_reach(t, map: CityMap,
		placements: Array[EventScheduler.Planned], blocked: Dictionary) -> int:
	var stage := RoadblockRig.Stage.new(t, map)
	var count := 0
	for placement: EventScheduler.Planned in placements:
		var def := placement.def
		if def.mobile or not def.hard_fail or def.pursuit != null:
			continue
		var instance := stage.stand(placement)
		count += 1
		var centre := instance.global_position
		var reach := def.lethal_reach()
		for gy in range(floori((centre.y - reach) / BODY_FLOOD_STEP),
				ceili((centre.y + reach) / BODY_FLOOD_STEP) + 1):
			for gx in range(floori((centre.x - reach) / BODY_FLOOD_STEP),
					ceili((centre.x + reach) / BODY_FLOOD_STEP) + 1):
				if (Vector2(gx, gy) * BODY_FLOOD_STEP).distance_to(centre) <= reach:
					blocked[Vector2i(gx, gy)] = true
	stage.close()
	return count

## Marks every grid point a solid piece of the plan's bodies keeps her centre off, and answers how
## many bodies it built. Mobile rows have no body (a truck is traffic), and a row that leaves a
## solid successor is built as that successor where it stands (`EventSpawner.successor_of()`).
static func _block_every_body(t, map: CityMap, placements: Array[EventScheduler.Planned],
		blocked: Dictionary) -> int:
	var stage := RoadblockRig.Stage.new(t, map)
	var count := 0
	for placement: EventScheduler.Planned in placements:
		var standing := stage.stand(placement)
		for instance: EventInstance in [standing, stage.successor_of(standing)]:
			if instance == null or instance.def.mobile or instance.def.obstructs_radius <= 0.0:
				continue
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
	stage.close()
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
## plans, and of plans whose every street draws a roadblock marble: one draw a street holds it by
## construction, and the notice spacing holds it across streets.
func _test_no_street_of_the_walk_stands_two_roadblocks(t) -> void:
	var streets := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var placements: Array[EventScheduler.Planned] = built["placements"]
		for placed: Array[EventScheduler.Planned] in [placements,
				_roadblocks_everywhere(map, seed_value)]:
			for street: Array in RoadblockRig.roadblock_streets(map, plan, placed):
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
		# The band a plan stands on open ground, streamed in as a day's is.
		var stage := RoadblockRig.Stage.new(t, WorldMap.open_ground())
		var plan := EventScheduler.Planned.new(def, post)
		var guard := stage.stand(plan)
		var told := stage.manager.world.where_she_is()
		var strongest := guard.excitement.contribution_at(beside)
		# In inside his radius: he warns.
		told.tell(post + Vector2(0.0, def.notice_within() - 10.0))
		guard.step(step)
		var warned := guard.is_standing_for_its_notice()
		strongest = maxf(strongest, maxf(guard.excitement.contribution_at(beside),
				guard.excitement.contribution_at(told.at())))
		# She stays inside his radius until his warning has run: he charges. She runs; he gives up
		# and walks away.
		var waited := 0
		while guard.is_telegraphing() and waited < int((def.pursuit.warns_for + 1.0) / step):
			guard.step(step)
			waited += 1
		var charged := false
		var frames := 0
		while not guard.gave_up and frames < int(10.0 / step):
			told.tell(guard.global_position + Vector2(0.0, 300.0), Vector2.INF, Rect2(), true)
			guard.step(step)
			charged = charged or guard.is_chasing()
			if guard.is_chasing():
				strongest = maxf(strongest, maxf(guard.excitement.contribution_at(beside),
						guard.excitement.contribution_at(guard.global_position + Vector2(0.0, 40.0))))
			frames += 1
		var her := told.at()
		told.tell(her)
		var leaving := guard.is_leaving and guard.barrier_post.is_spent()
		strongest = maxf(strongest, guard.excitement.contribution_at(beside))
		frames = 0
		while guard.is_leaving and frames < int(30.0 / step):
			told.tell(her)
			guard.step(step)
			strongest = maxf(strongest, guard.excitement.contribution_at(beside))
			frames += 1
		var gone := guard.barrier_post.is_spent() and not guard.is_leaving and guard.is_solid()
		strongest = maxf(strongest, guard.excitement.contribution_at(beside))
		t.check(warned and charged and leaving and gone,
				"%s guard warns, charges, is shaken off and leaves the band standing solid" % name)
		t.check(strongest == 0.0,
				"%s band costs nothing posted, warning, charging, left or gone (%.1f/s at most)"
				% [name, strongest])
		# Streamed out and back in, the plan carries the spent guard and it comes back as only the barrier.
		stage.manager.streaming.stream_out(plan)
		stage.manager.streaming.stream_in(plan)
		var streamed := plan.live
		t.check(streamed.barrier_post.is_spent() and streamed.is_solid()
				and streamed.excitement.contribution_at(beside) == 0.0,
				"%s band streamed back in after its guard was spent is solid and silent" % name)
		stage.close()

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
	var step := 1.0 / 60.0
	var post := Vector2(400.0, 0.0)
	var atlas := AtlasLibrary.new()
	atlas.acquire(EventPictures.ATLAS_GROUP)
	# The band a plan stands on open ground, streamed in as a day's is, drawn on real frames.
	var stage := RoadblockRig.Stage.new(t, WorldMap.open_ground(), atlas)
	var plan := EventScheduler.Planned.new(def, post)
	var guard := stage.stand(plan)
	var told := stage.manager.world.where_she_is()
	guard.set_process(true)
	await RoadblockRig.settle(t)
	var posted_first := not guard.barrier_post.sides_still_posted().is_empty()
	told.tell(post + Vector2(0.0, def.notice_within() - 10.0))
	guard.step(step)
	var waited := 0
	while guard.is_telegraphing() and waited < int((def.pursuit.warns_for + 1.0) / step):
		guard.step(step)
		waited += 1
	var posted_through_the_chase := true
	var frames := 0
	while not guard.is_leaving and frames < int(10.0 / step):
		told.tell(guard.global_position + Vector2(0.0, 300.0), Vector2.INF, Rect2(), true)
		guard.step(step)
		if not guard.is_leaving:
			posted_through_the_chase = posted_through_the_chase \
					and not guard.barrier_post.sides_still_posted().is_empty()
		frames += 1
	var her := told.at()
	told.tell(her)
	t.check(posted_first and posted_through_the_chase,
			"the far guard stands at his post until his partner leaves")
	t.check(guard.is_leaving, "the guard on her side was shaken off and walks away")
	var set_off := guard.barrier_post.where_the_far_guard_walks()
	t.check(set_off != Vector2.INF and guard.barrier_post.sides_still_posted().is_empty(),
			"the far guard sets off from his post the frame his partner starts to leave")
	t.check(set_off.distance_to(her) > guard.body_position().distance_to(her),
			"and he sets off from the far post, beyond the band from her")
	# His node is the look's, made on the drawn frame after the step that sent him.
	await RoadblockRig.settle(t)
	var far_node := guard.get_parent().get_node_or_null("FarGuard")
	t.check(far_node != null and far_node.is_inside_tree(),
			"and walks on his own node beside the band's")
	# She has come back to stand beside the band, so he has a walk to make before he is out of
	# her sight.
	her = guard.body_position() + Vector2(0.0, 120.0)
	var paced := true
	var last := set_off
	var walked := 0
	while guard.barrier_post.where_the_far_guard_walks() != Vector2.INF and walked < int(30.0 / step):
		told.tell(her)
		guard.step(step)
		await t.get_tree().process_frame
		walked += 1
		var now := guard.barrier_post.where_the_far_guard_walks()
		if now == Vector2.INF:
			break
		paced = paced and now.distance_to(last) <= def.chase_speed() * step + 0.01 \
				and is_equal_approx(guard.barrier_post.how_far_the_far_guard_has_walked(), def.chase_speed() * step * walked)
		last = now
	t.check(last.distance_to(her) > set_off.distance_to(her) and paced,
			"he walks away from her at his partner's pace (%d frames)" % walked)
	t.check(guard.barrier_post.where_the_far_guard_walks() == Vector2.INF and guard.barrier_post.sides_still_posted().is_empty(),
			"and he is gone, and nobody stands at the band")
	t.check(last.distance_to(her) > Tuning.OUT_OF_SIGHT - def.chase_speed() * step,
			"only once he is out of her sight (%.0fpx from her)" % last.distance_to(her))
	await RoadblockRig.settle(t)
	t.check(guard.get_parent().get_node_or_null("FarGuard") == null, "his node goes with him")
	stage.manager.streaming.stream_out(plan)
	stage.manager.streaming.stream_in(plan)
	t.check(plan.live.barrier_post.sides_still_posted().is_empty(),
			"a band streamed back in after its guard was spent stands unmanned")
	stage.close()
	atlas.release(EventPictures.ATLAS_GROUP)

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
	var placements: Array[EventScheduler.Planned] = built["placements"]
	var walks := 0
	var far_walks := 0
	var bands := _escape_roadblocks(placements)
	for band_plan in bands:
		var group: Array[EventScheduler.Planned] = [band_plan]
		for bearing in 16:
			var made := RoadblockRig.build(t, map, group)
			var stage: RoadblockRig.Stage = made[0]
			var told := stage.manager.world.where_she_is()
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
					caught = RoadblockRig.tick(told, made[1], her, false)
				if caught:
					break
			var frames := 0
			while not caught and guard.is_chasing() and frames < int(10.0 / step):
				her += toward * Tuning.RUN_SPEED * step
				caught = RoadblockRig.tick(told, made[1], her, true)
				frames += 1
			if caught or not guard.is_leaving:
				made[0].close()
				continue
			walks += 1
			if _watch_them_walk_off(t, map, told, made[1], her, where):
				far_walks += 1
			made[0].close()
	t.check(walks > 0 and far_walks > 0,
			"there were guards walking off to watch (%d, %d with the far guard)" % [walks, far_walks])
	# The reviewed case: she stands at (70,50), west of the band on the open sidewalk, when the guard
	# on her side gives up, so both guards' ways are planned from there. The escape's plan for
	# this seed may stand no band on that tile (the case is one it once did), so the band is the
	# escape's row handed to the streaming at the tile when the plan has none there.
	var reviewed := Vector2i(73, 50)
	var reviewed_plan: EventScheduler.Planned = null
	for band_plan in bands:
		if map.world_to_tile(band_plan.position) == reviewed:
			reviewed_plan = band_plan
	if reviewed_plan == null:
		reviewed_plan = EventScheduler.Planned.new(EventCatalogue.escape_roadblock(),
				map.tile_to_world(reviewed))
	var group: Array[EventScheduler.Planned] = [reviewed_plan]
	var made := RoadblockRig.build(t, map, group)
	var stage: RoadblockRig.Stage = made[0]
	var told := stage.manager.world.where_she_is()
	var guard: EventInstance = made[1][0]
	var her := map.tile_to_world(Vector2i(70, 50))
	var frames := 0
	while guard.is_waiting() and frames < int(20.0 / step):
		RoadblockRig.tick(told, made[1], her, false)
		frames += 1
	t.check(not guard.is_waiting(), "the band at (73,50) notices her standing at (70,50)")
	guard.give_up_the_chase()
	t.check(guard.is_leaving, "and its guard gives up and walks away")
	t.check(_watch_them_walk_off(t, map, told, made[1], her,
			"the band at (73,50), with her at (70,50)"),
			"and the band at (73,50), with her at (70,50), sent its far guard off")
	made[0].close()

## Steps `instances` (one band, its guard on her side already walking away) with her standing at
## `her` until both guards are gone, and checks every frame either guard walks that he stands on a
## walkable tile of `map`; answers whether the far guard walked.
func _watch_them_walk_off(t: TestRunner, map: CityMap, told: WhereSheIs,
		instances: Array[EventInstance], her: Vector2,
		where: String) -> bool:
	var guard := instances[0]
	var far_walked := false
	var frames := 0
	while (guard.is_leaving or guard.barrier_post.where_the_far_guard_walks() != Vector2.INF) \
			and frames < int(30.0 / RoadblockRig.STEP):
		RoadblockRig.tick(told, instances, her, false)
		frames += 1
		var at: Array[Vector2] = []
		if guard.is_leaving:
			at.append(guard.global_position)
		if guard.barrier_post.where_the_far_guard_walks() != Vector2.INF:
			at.append(guard.barrier_post.where_the_far_guard_walks())
			far_walked = true
		for point in at:
			var tile := map.world_to_tile(point)
			if not map.is_walkable(tile):
				t.check(false, "%s: a guard walking off stands on %s, not walkable ground"
						% [where, tile])
				return far_walked
	return far_walked

## **And nothing over her head says otherwise.** A posted band's guard has not noticed her yet, so
## inside its outer radius it raises the `SOON` mark (`WarningBoard.warn_about_the_ground_she_is_on()`),
## as every `hard_fail` row waiting for her does. A band whose guard has left for good waits for
## nobody: he never notices her or charges again, so it raises nothing, or the walk past a band
## that costs nothing would be made under a warning of a catch that cannot come.
func _test_a_lured_off_roadblock_raises_no_mark_over_her(t) -> void:
	# A manager handed open ground drawn in a node of its own and a run (`EventManager.setup_world()`,
	# as the building is handed its world), with the band a plan the escape would have planned
	# (`EventStreaming.add()`), streamed in by the streaming the day runs.
	var holder := WorldContext.new()
	t.add_child(holder)
	var open_ground := WorldMap.open_ground()
	open_ground.world = holder
	var run := RunState.new()
	var manager := EventManager.new()
	manager.setup_world(open_ground, run)
	t.add_child(manager)
	var band_plan := EventScheduler.Planned.new(EventCatalogue.escape_roadblock(),
			Vector2(1000.0, 1000.0))
	manager.streaming.add(band_plan)
	manager.streaming.stream_around(band_plan.position)
	var band := band_plan.live
	var at: Vector2 = band.global_position + Vector2(0.0, band.def.outer_radius - 20.0)
	var first := _stand_her_at(t, manager, at)
	manager.warnings.warn_about_the_ground_she_is_on()
	t.check(first.alert_level() == Stroller.Alert.SOON,
			"a posted band's guard waiting for her raises the mark inside its outer radius")
	# Its guard noticing her, charging and shaken off, then the plan streamed out and in: the band
	# comes back as only the barrier (`EventBarrierPost`), no guard to notice her again.
	var step := RoadblockRig.STEP
	var told := manager.world.where_she_is()
	told.tell(band.global_position + Vector2(0.0, band.def.notice_within() - 10.0))
	band.step(step)
	var waited := 0
	while band.is_telegraphing() and waited < int((band.def.pursuit.warns_for + 1.0) / step):
		band.step(step)
		waited += 1
	var frames := 0
	while not band.gave_up and frames < int(60.0 / step):
		told.tell(band.global_position + Vector2(0.0, 300.0), Vector2.INF, Rect2(), true)
		band.step(step)
		frames += 1
	t.check(band.gave_up, "the band's guard charges and is shaken off")
	manager.streaming.stream_out(band_plan)
	manager.streaming.stream_in(band_plan)
	band = band_plan.live
	# A stroller of her own for the spent band, so no mark of the posted one's is still up on her
	# (a raised mark stays its hold, `WarningBoard.WARNING_HOLD`, a fresh one has none).
	var second := _stand_her_at(t, manager, at)
	manager.warnings.warn_about_the_ground_she_is_on()
	t.check(second.alert_level() == Stroller.Alert.NONE,
			"a band whose guard has left for good raises nothing over her head")
	for her in [first, second]:
		her.remove_from_group("player")
		her.free()
	manager.use_player(null)
	manager.free()
	holder.free()

## A stroller at `at` that `manager` watches (`EventManager.use_player()`), its own physics off.
func _stand_her_at(t, manager: EventManager, at: Vector2) -> Stroller:
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	her.add_child(camera)
	t.add_child(her)
	her.set_physics_process(false)
	her.add_to_group("player")
	her.global_position = at
	manager.use_player(her)
	return her

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
		var placements: Array[EventScheduler.Planned] = built["placements"]
		for street: Array in RoadblockRig.roadblock_streets(map, plan, placements):
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
## `EventDef.notice` round its band, never overlap (`OneNoticeRule._keeps_its_notice_to_itself()`).
## *(Inbox #771 in minty-lemur, 2026-10-18: "two roadblocks are right next to each other and the second guard is
## invisible (hidden) until it already charges".)* One a street keeps two off one street; this keeps
## two apart across a junction or a corner as well.
func _test_no_two_roadblocks_notice_her_from_the_same_ground(t) -> void:
	var pairs := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var placements: Array[EventScheduler.Planned] = built["placements"]
		# The game's plan, and the most bands the escape can stand: a roadblock drawn for every slot.
		for bands: Array[EventScheduler.Planned] in [_escape_roadblocks(placements),
				_roadblocks_everywhere(map, seed_value)]:
			var stands := _stand_points(t, map, bands)
			for i in bands.size():
				for j in range(i + 1, bands.size()):
					pairs += 1
					var gap := stands[i].distance_to(stands[j])
					var apart := bands[i].def.notice_within() + bands[j].def.notice_within()
					t.check(gap >= apart, "seed %d: the roadblocks at %s and %s stand %.0fpx apart, at least the %.0fpx their two notices take"
							% [seed_value, map.world_to_tile(bands[i].position),
							map.world_to_tile(bands[j].position), gap, apart])
	t.check(pairs > 0, "there were pairs of roadblocks to measure (%d)" % pairs)

## Whether `item` draws on `layer`: the absolute depth a node asked onto the layer
## (`DrawLayer.draw_on()`, which the event calls on its own node on the drawn frame) draws at.
func _is_drawn_on(item: CanvasItem, layer: int) -> bool:
	var reference := Node2D.new()
	DrawLayer.draw_on(reference, layer)
	var drawn := not item.z_as_relative and item.z_index == reference.z_index
	reference.free()
	return drawn

## Where each of `bands` stands once it is built: its body's place (`EventInstance.body_position()`),
## which is where its guard waits and notices her from. Built the way the game builds them
## (streamed in on the map) and read off the instance, then freed.
func _stand_points(t, map: CityMap, bands: Array[EventScheduler.Planned]) -> Array[Vector2]:
	var stage := RoadblockRig.Stage.new(t, map)
	var points: Array[Vector2] = []
	for band in bands:
		points.append(stage.stand(band).body_position())
	stage.close()
	return points

## **An escape guard warns on the screen and in front of everything round him.** *(Inbox #771 in minty-lemur,
## 2026-10-18: "the second guard is invisible (hidden) until it already charges"; inbox #788 in minty-lemur: the
## warning is visible on screen.)* Walked: she comes at each of the game's roadblocks on two seeds'
## cities, and at every roadblock the escape can stand there, in a straight line from all round it, with the camera's view led by her walk as `Stroller` leads it
## (`RoadblockRig.view_round()`), and on the frame his hand goes up the whole of his raised-hand
## picture at his post (`EventFootprints.warning_guard_rect()`) is inside that view, he is drawn above
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
	var atlas := AtlasLibrary.new()
	atlas.acquire(EventPictures.ATLAS_GROUP)
	for seed_value: int in [4242, 77]:
		var built := RoadblockRig.plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var placements: Array[EventScheduler.Planned] = built["placements"]
		# The game's own bands, and every band the escape can stand, a roadblock drawn for every
		# street's slot: the bag draws few, and only the second set is sure to hold a band on a
		# street running either way, and the approaches the radius alone would have warned from off
		# the view, which only a north-south street has.
		var bands := _escape_roadblocks(placements)
		bands.append_array(_roadblocks_everywhere(map, seed_value))
		for band_plan in bands:
			var group: Array[EventScheduler.Planned] = [band_plan]
			for bearing in 16:
				var made := RoadblockRig.build(t, map, group, atlas)
				var stage: RoadblockRig.Stage = made[0]
				var told := stage.manager.world.where_she_is()
				var guard: EventInstance = made[1][0]
				# Drawn on the real frames this loop waits for, which take the draw layer.
				guard.set_process(true)
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
						if not view.encloses(EventFootprints.warning_guard_rect(
								guard.runs_vertically(), band, her)):
							off_by_the_radius += 1
					RoadblockRig.tick(told, made[1], her, false, -toward)
					# The layer is taken on the drawn frame, from what the tick left: a real frame
					# where the draw layer is read, which is when his hand goes up and when he charges.
					if (was_waiting and guard.is_standing_for_its_notice()) or guard.is_chasing():
						await RoadblockRig.settle(t)
					if was_waiting and guard.is_standing_for_its_notice():
						warned += 1
						warned_here = true
						t.check(view.encloses(EventFootprints.warning_guard_rect(
								guard.runs_vertically(), band, her)),
								"%s: his raised hand goes up in her view" % where)
						t.check(_is_drawn_on(guard, DrawLayer.Layer.WARNING),
								"%s: and he is drawn above the street round him" % where)
						if open_walk:
							outside += 1
					if guard.is_chasing():
						charged = true
						charges += 1
						t.check(warned_here,
								"%s: his hand went up before he charged" % where)
						t.check(_is_drawn_on(guard, DrawLayer.Layer.ENTITIES),
								"%s: once he charges he sorts with the street again" % where)
				made[0].close()
	t.check(warned > 0 and outside > 0,
			"there were warnings to watch (%d, %d on open ground)" % [warned, outside])
	t.check(charges > 0, "and charges to ask about (%d)" % charges)
	t.check(off_by_the_radius > 0,
			"and approaches the radius alone would have warned from off the view (%d)"
			% off_by_the_radius)
	atlas.release(EventPictures.ATLAS_GROUP)

## The escape's roadblocks a plan of `seed_value` on `map` stands when every street draws a
## roadblock marble: every band the placement rules let the escape stand there.
static func _roadblocks_everywhere(map: CityMap, seed_value: int) -> Array[EventScheduler.Planned]:
	return _escape_rows_from(map, _bare_plan(map, seed_value), {"roadblock": 1})

## The plan's own roadblocks, the escape's copy of the row.
static func _escape_roadblocks(
		placements: Array[EventScheduler.Planned]) -> Array[EventScheduler.Planned]:
	var found: Array[EventScheduler.Planned] = []
	for placement in placements:
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
	var run := RunState.new()
	run.start_run(PLAYERS_SEED)
	run.header.day = 1
	run.facts.escape_section = DaySpec.Section.BUILDING
	var home := Boot.home_playing(t, run)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, Boot.config([]),
			func(main: Node) -> void: main.use_sitting_home(home))
	var main := booted.main
	await Boot.press_continue(t, main)
	Boot.interior(main).exit_requested.emit()
	await Boot.press_continue(t, main)
	var city := Boot.city(main)
	t.check(city != null and Boot.day(main).spec.section == DaySpec.Section.CITY,
			"seed %d: the service door puts her in the city" % PLAYERS_SEED)
	if city != null:
		var map: CityMap = city.map
		var plan := FinalePlanner.route(map)
		var placements := DayPlanner.plan_the_escape_city(map, plan,
				run.calendar.day_rng(run.header.day, "finale"), _city_spec())
		var bands := _escape_roadblocks(placements)
		var hers := map.network.segment_containing(WHERE_THE_PLAYER_WAS_CAUGHT)
		var on_her_street := 0
		for band_plan in bands:
			var street := map.network.segment_containing(map.world_to_tile(band_plan.position))
			if hers and street and street.key() == hers.key():
				on_her_street += 1
		t.check(hers != null and on_her_street <= 1,
				"seed %d: the street she was caught on stands one band at most (%d)"
				% [PLAYERS_SEED, on_her_street])
		var stands := _stand_points(t, map, bands)
		for i in bands.size():
			for j in range(i + 1, bands.size()):
				t.check(stands[i].distance_to(stands[j])
						>= bands[i].def.notice_within() + bands[j].def.notice_within(),
						"seed %d: the bands at %s and %s notice her from no common ground"
						% [PLAYERS_SEED, map.world_to_tile(bands[i].position),
						map.world_to_tile(bands[j].position)])
		var blocked := {}
		_block_every_body(t, map, placements, blocked)
		var reached := _flood_past_the_bodies(map, blocked,
				FinalePlanner.service_exit_world_position(map))
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
		for street: Array in RoadblockRig.roadblock_streets(map, plan, placements):
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
	booted.free_all()
	home.free()

# ------------------------------------------------------- the day's own rules ---

## **The escape's own rows stand on the day's own ground for them** (`EventScheduler.street_ground()`
## asks `open_ground_for()`): every truck, van, roadblock and burst on a tile a day would offer that
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
		var placements: Array[EventScheduler.Planned] = built["placements"]
		var offered := {}
		for placement in placements:
			if not ESCAPE_ROWS.has(placement.def.id):
				continue
			asked += 1
			var key := placement.def.get_instance_id()
			if not offered.has(key):
				var tiles := {}
				for tile in EventScheduler.open_ground_for(placement.def, map, {}, -1, false):
					tiles[tile] = true
				offered[key] = tiles
			var at := map.world_to_tile(placement.position)
			t.check(offered[key].has(at), "seed %d: the %s at %s stands on ground a day offers it"
					% [seed_value, placement.def.id, at])
	t.check(asked > 0, "there were escape rows to ask about (%d)" % asked)

## The escape's own rows, the four the city section's bag draws (`DaySpec.bag_rows`).
const ESCAPE_ROWS := ["military_convoy", "abduction", "roadblock", "finale_explosion"]

## **An alley's mouth wall fits the mouth**, on a day and in the escape: the widest row whose body
## is no wider than the alley (`SealPlanner.plan_day()` picks it). A day's soft rows always
## fitted; the escape's own list is street seals sized for a 192px street, and the widest of them
## stood across a 64px alley and two tiles into the buildings either side, over their roofs.
## *(Inbox #785 in minty-lemur, 2026-10-18: "I saw wood on the roof for example")* Asked of every alley-mouth wall
## the escape's plans stand, by its body: nothing of it reaches a building tile.
func _test_an_alley_mouth_wall_fits_the_mouth(t) -> void:
	var mouth := float(Tuning.ALLEY_WIDTH_TILES * Tuning.TILE_SIZE)
	# Every day's own seal plan, on a city each, asked for the walls it stands on an alley's mouth.
	var day_walls := 0
	var map_of_days := MapCache.of(SEEDS[0])
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var state := CityState.new()
		state.begin_day(map_of_days.block_plans, day)
		map_of_days.repaint(state)
		var tree := RouteTree.for_day(map_of_days, day)
		for roll in 4:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("mouths:%d:%d" % [day, roll])
			for seal in SealPlanner.plan_day(map_of_days, DaySpec.for_day(day), tree, rng):
				if map_of_days.tile_at(map_of_days.world_to_tile(seal.position)) \
						!= GameEnums.TileType.ALLEY:
					continue
				day_walls += 1
				t.check(seal.def.obstructs_radius * 2.0 <= mouth,
						"day %d's alley-mouth row %s fits the mouth" % [day, seal.def.id])
	t.check(day_walls > 0, "there were days' alley-mouth walls to ask about (%d)" % day_walls)
	var walls := 0
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var placements: Array[EventScheduler.Planned] = built["placements"]
		var ground := WalkGround.new(map)
		for placement in placements:
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
		var placements: Array[EventScheduler.Planned] = built["placements"]
		var ground := WalkGround.new(map)
		for placement in placements:
			if placement.def.id == "barricade":
				barricades += 1
			var body := Reach.body_overhang(map, ground, placement)
			var drawn := Reach.drawing_overhang(map, placement)
			t.check(body <= 0.5 and drawn <= 0.5,
					"seed %d: the %s at %s keeps off the buildings (body %.1fpx, drawing %.1fpx over)"
					% [seed_value, placement.def.id, map.world_to_tile(placement.position), body,
					drawn])
	t.check(barricades > 0, "there were barricade pieces among them (%d)" % barricades)

## **A restart plans the same escape.** A loss in the city replans it on the same city (the day
## director's start, `DayDirector.start()`, on the section's own stream), and the restart's plan is
## the first one, placement for placement.
func _test_a_restart_plans_the_same_escape(t) -> void:
	var map := MapCache.of(SEEDS[0])
	_paint_day_one(map)
	var plans: Array[Array] = []
	for attempt in 2:
		var rng := RandomNumberGenerator.new()
		rng.seed = SEEDS[0]
		plans.append(DayPlanner.plan_the_escape_city(map, FinalePlanner.route(map), rng, _city_spec()))
	var first: Array[EventScheduler.Planned] = []
	first.assign(plans[0])
	var second: Array[EventScheduler.Planned] = []
	second.assign(plans[1])
	var same := first.size() == second.size()
	for i in mini(first.size(), second.size()):
		var a := first[i]
		var b := second[i]
		same = same and a.def.id == b.def.id and a.position.is_equal_approx(b.position)
	t.check(same and first.size() > 0,
			"a restart plans the same %d placements as the first plan" % first.size())

## **The escape's bag holds its marbles in the player's order of how many, empty ones included.**
## *(Inbox #785 in minty-lemur: "a marble bag is absolutely needed with empty events (nothing
## happening) as well"; "frequency order is trucks > explosions > vans > barriers > empty".)*
func _test_the_escape_bag_keeps_the_players_order(t) -> void:
	t.check(DaySpec.FINALE_BAG_TRUCKS > DaySpec.FINALE_BAG_EXPLOSIONS
			and DaySpec.FINALE_BAG_EXPLOSIONS > DaySpec.FINALE_BAG_VANS
			and DaySpec.FINALE_BAG_VANS > DaySpec.FINALE_BAG_ROADBLOCKS
			and DaySpec.FINALE_BAG_ROADBLOCKS > DaySpec.FINALE_BAG_EMPTY,
			"the bag holds more trucks than explosions, than vans, than roadblocks, than empty marbles")

## **Every open street draws one marble, stands at most one of the escape's rows, and a marble no
## location of the street takes is spent unmet** (inbox #1185 in gentle-owl's board answer: "one per street. fill
## empty in if any segment or location in the street has an event"). The bag is drawn once a street
## whatever the draw finds, so a refused danger never moves on to the next street; a bag of empty
## marbles stands nothing; and a bag of roadblocks alone stands fewer than it drew, since no two bands
## may stand where both guards can notice her.
func _test_every_street_draws_one_marble(t) -> void:
	var unmet := 0
	for seed_value in SEEDS:
		var map := MapCache.of(seed_value)
		_paint_day_one(map)
		var bare := _bare_plan(map, seed_value)
		var streets: Array[StreetNetwork.Segment] = bare["streets"]
		var lines: Array[String] = []
		var placed := _escape_rows_traced(map, bare, _city_spec().bag, RunTrace.recording(lines))
		var untraced := _escape_rows_from(map, bare, _city_spec().bag)
		t.check(_same_rows(placed, untraced), "seed %d: the note changes nothing placed" % seed_value)
		var drew := _marbles_drawn_in(lines)
		t.check(drew == streets.size(), "seed %d: every street drew one marble (%d of %d)"
				% [seed_value, drew, streets.size()])
		var most := 0
		for segment in streets:
			var rect := map.tile_rect_to_world(segment.tile_rect()).grow(1.0)
			var here := 0
			for placement in placed:
				if rect.has_point(placement.position):
					here += 1
			most = maxi(most, here)
		t.check(most <= 1, "seed %d: no street stands more than one of the escape's rows (%d)"
				% [seed_value, most])
		t.check(_escape_rows_from(map, bare, {DaySpec.EMPTY_MARBLE: 1}).is_empty(),
				"seed %d: a bag of empty marbles stands nothing" % seed_value)
		var band_lines: Array[String] = []
		var stood := _escape_rows_traced(map, bare, {"roadblock": 1}, RunTrace.recording(band_lines))
		var band_draws := _marbles_drawn_in(band_lines)
		t.check(band_draws == streets.size(), "seed %d: a bag of roadblocks draws once a street (%d)"
				% [seed_value, band_draws])
		unmet += streets.size() - stood.size()
	t.check(unmet > 0, "and some roadblock marbles were spent unmet (%d)" % unmet)

## **The game's plan is `Tuning`'s bag, drawn on the street bag's own stream**: the city section's
## spec holds `Tuning`'s counts, and what the escape's plan stands is what the bag draw
## (`EventScheduler.build_day()`, handed those counts by a spec of the test's own)
## stands, placement for placement — the plan `tests/probes/escape_winnable.gd`
## measures other mixes against.
func _test_the_game_draws_the_escape_from_tunings_bag(t) -> void:
	for seed_value in SEEDS:
		var built := _plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var placements: Array[EventScheduler.Planned] = built["placements"]
		var bare := _bare_plan(map, seed_value)
		var placed := _escape_rows_from(map, bare, _city_spec().bag)
		var played: Array[EventScheduler.Planned] = []
		for placement in placements:
			if ESCAPE_ROWS.has(placement.def.id):
				played.append(placement)
		var same := played.size() == placed.size()
		for i in mini(played.size(), placed.size()):
			same = same and played[i].def.id == placed[i].def.id \
					and played[i].position.is_equal_approx(placed[i].position)
		t.check(same and played.size() > 0, "seed %d: the game's plan is Tuning's bag (%d and %d)"
				% [seed_value, played.size(), placed.size()])

## The plan `_plan_for()` builds with no events of the escape's own yet: its walk and streets, its
## seals and the rng where `DayPlanner.plan_the_escape_city()` hands it to
## `EventScheduler.build_day()`.
static func _bare_plan(map: CityMap, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var plan := FinalePlanner.route(map)
	var seals := DayPlanner.plan_the_escape_city(map, plan, rng, _city_spec(), false)
	return {"plan": plan, "streets": plan.open_streets, "seals": seals, "rng": rng,
			"state": rng.state}

## The escape's rows the bag draw (`EventScheduler.build_day()`, which a spec drawing from a bag of
## `counts` sends to the bag draw, one marble a street) stands on the bare plan, the rng put back
## where `DayPlanner.plan_the_escape_city()` would hand it over each time.
static func _escape_rows_from(map: CityMap, bare: Dictionary,
		counts: Dictionary) -> Array[EventScheduler.Planned]:
	var rng: RandomNumberGenerator = bare["rng"]
	rng.state = bare["state"]
	var seals: Array[EventScheduler.Planned] = bare["seals"]
	var spec := _city_spec()
	spec.bag = counts
	return EventScheduler.build_day(spec, rng, map, CalmAreas.of(map), MastSites.compute(map), [], [], bare["plan"], 0,
			PackedVector2Array(), seals).placements()

## Whether two plans stand the same rows in the same places.
static func _same_rows(a: Array[EventScheduler.Planned], b: Array[EventScheduler.Planned]) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i].def.id != b[i].def.id or a[i].position != b[i].position:
			return false
	return true

## The marbles a plan drew, as the plan reports them to the run log: `build_day()` is handed a
## trace that keeps every line, and the bag path notes `the escape's bag drew N marbles for M rows`.
## `-1` when no such line was written. The note's wording is the contract between the bag path and
## this reader: a change to one is a change to the other.
static func _marbles_drawn_in(lines: Array[String]) -> int:
	for line in lines:
		if line.begins_with("plan the escape's bag drew "):
			return int(line.trim_prefix("plan the escape's bag drew ").split(" ")[0])
	return -1

## `_escape_rows_from()` with a trace handed to `build_day()`, for the count of marbles drawn.
static func _escape_rows_traced(map: CityMap, bare: Dictionary, counts: Dictionary,
		trace: RunTrace) -> Array[EventScheduler.Planned]:
	var rng: RandomNumberGenerator = bare["rng"]
	rng.state = bare["state"]
	var seals: Array[EventScheduler.Planned] = bare["seals"]
	var spec := _city_spec()
	spec.bag = counts
	return EventScheduler.build_day(spec, rng, map, CalmAreas.of(map), MastSites.compute(map), [], [], bare["plan"], 0,
			PackedVector2Array(), seals, trace).placements()

## *"Emerging from the service exit on the side of the main building."* Beside the home block, on
## walkable ground, and never on the spine's own frontage.
func _test_the_service_exit_is_beside_the_home_block(t) -> void:
	for seed_value in SEEDS:
		var map := MapCache.of(seed_value)
		_paint_day_one(map)
		var tile := map.world_to_tile(FinalePlanner.service_exit_world_position(map))
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
## `service_exit_world_position()` answers with walkable ground, the boundary walls are outside the map, and
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
		var map := MapCache.of(seed_value)
		_paint_day_one(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var placements := DayPlanner.plan_the_escape_city(map, FinalePlanner.route(map), rng,
				_city_spec())
		var spawn := FinalePlanner.service_exit_world_position(map)
		t.check(map.is_walkable(map.world_to_tile(spawn)),
				"seed %d: she is put down on walkable ground" % seed_value)
		for placement: EventScheduler.Planned in placements:
			checked += 1
			for def in [placement.def, EventCatalogue.by_id(placement.def.aftermath.on_finish)]:
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
## `WarningBoard.warn_about_the_ground_she_is_on()` puts `Stroller.Alert.SOON` over her head for
## any `hard_fail` row that is still telegraphing, or still waiting to notice her, whose **outer**
## radius covers her — because that radius is exactly what the telegraph fairness contract promises
## her time to walk out of. On the first frame of section two every placement the finale made is in
## one of those two states, so that one inequality is the whole of the mark, and it is asked here
## as `distance > outer_radius` for every lethal row on the plan. `NOW` needs a live instance and
## cannot fire on the frame the section begins; `distance > inner_radius` falls out of the same
## check, since a row's outer radius is never under its inner one.
##
## **This is the confirmation, not the mechanism**, exactly as for the bodies above:
## `EventScheduler.clearance_around_her()` is never offered ground within a lethal row's own outer
## radius of her, so nothing is placed there to be cleared up afterwards.
##
## Seeds rather than one city, and the guard counts the lethal rows it actually found: an escape
## plan that happened to place none at all would otherwise pass this without checking anything.
func _test_no_lethal_field_covers_the_ground_she_comes_out_on(t) -> void:
	var lethal := 0
	var over_her := 0
	for seed_value in SPAWN_SEEDS:
		var map := MapCache.of(seed_value)
		_paint_day_one(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var placements := DayPlanner.plan_the_escape_city(map, FinalePlanner.route(map), rng,
				_city_spec())
		var spawn := FinalePlanner.service_exit_world_position(map)
		for placement: EventScheduler.Planned in placements:
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

## Dressing the city for the escape (`City.start_day()` under the city section's spec) grows no
## corridor and closes no street: its walk is handed in once it is planned. Nobody on its streets is
## the day director's start's (`DaySpec.crowd_density`), held where the real city section is booted
## (`_test_main_tints_the_escape_streets_on_its_first_plan_and_on_a_restart`).
func _test_the_finale_city_grows_no_corridor(t) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, SEEDS[0])
	var run := city.run
	t.add_child(city)
	city.build(MapCache.of(SEEDS[0]))
	run.attempt_spend.city_state.begin_day(city.map.block_plans, 1)
	var spec := _section(DaySpec.Section.CITY)
	city.start_day(run.attempt_spend.city_state, 1, run.calendar.day_rng(1, "closures"), spec)
	t.check(city.streets().route_tree() == null and city.streets().closures().is_empty(),
			"the escape grows no corridor and closes no street")
	# `.free()`, not `queue_free()`, so the city is gone before the next check rather than at a
	# frame that passes after this suite.
	city.free()

## *"Yes, of course the yellow tint. We spent the whole game establishing that why would it be
## different in the last section?"* (inbox #747). Both kerb lines of every street the chains run
## through carry the route twin of their kerb source, and no other street's kerb does — the paint
## asked through `City.scenery_ground_source()`, the one answer every ground chunk is painted from.
##
## **Driven through the booted `main`, because the wiring is what the player saw missing.** The
## escape boots on its city section (`_boot_the_escape()`), whose first plan the day director's start
## makes once `main` has built the city, and the tint is read off the booted city as it stands; the
## booted city is also where nobody being on the escape's streets is held. A day's route tinted before
## the escape starts must not show, so the city is handed a day's own tree as its tint
## (`City.tint_the_route()`, which a day's own closures do) after the first plan, then wiped, so a
## restart is checked painting it rather than inheriting it. The restart is the one a lost section's outcome screen continues into:
## the loss through the signal a real capture fires, the continue pressed through the viewport.
func _test_main_tints_the_escape_streets_on_its_first_plan_and_on_a_restart(t) -> void:
	var escape := await _boot_the_escape(t, DaySpec.Section.CITY)
	var main := escape.main
	var city := Boot.city(main)
	# *"No regular cars or regular people on the street"*: a crowd the start had started would be a
	# day's, hundreds strong.
	t.check(city.crowd.agent_count() == 0, "the escape's city, started as its spec says, has nobody in it")
	var day := escape.run.header.day
	var corridor := Corridor.of(RouteTree.for_day(city.map, day))
	var plan := FinalePlanner.route(city.map)
	var on_the_walk := {}
	for segment in plan.open_streets:
		on_the_walk[segment.key()] = true
	var first := _escape_tint(city, day, on_the_walk, corridor)
	t.check(first.x > 0 and first.y > 0,
			"there were kerbs on and off the escape's streets to ask about (%d and %d)"
			% [first.x, first.y])
	t.check(first.w > 0, "and kerbs the day would tint that the escape does not walk (%d)" % first.w)
	t.check(first.z == 0,
			"the first plan tints every kerb of the escape's streets and no other (%d wrong)"
			% first.z)

	city.tint_the_route(RouteTree.for_day(city.map, day))
	var on_the_day := 0
	for tile in _kerb_tiles(city, day):
		if corridor.depth(tile) == 0 and city.scenery_ground_source(tile) \
				== GroundTiles.route_twin_of(GroundTiles.source_for(city.map, tile, day)):
			on_the_day += 1
	t.check(on_the_day > 0, "a day's route tints its own kerbs (%d)" % on_the_day)

	city.tint_the_route(null)
	t.check(_escape_tint(city, day, on_the_walk, corridor).z == first.x,
			"wiping the tint leaves every kerb of the walk plain")
	await Boot.press_continue(t, main)
	EventBus.hard_fail_triggered.emit("abduction")
	await Boot.press_continue(t, main)
	t.check(Boot.summary(main).is_showing(), "the loss's continue is the section again, behind its brief")
	t.check(_escape_tint(city, day, on_the_walk, corridor).z == 0,
			"and a restart tints them again, and no other")
	_free_the_escape(t, escape)

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
		var segment := city.map.network.segment_containing(tile)
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
	# The width comes from the baked region table rather than from a loaded texture — the crater's
	# picture is a region of the `events` page now, and `AtlasTable.baked().native_size()` answers the
	# source picture's own size with nothing acquired.
	var picture := EventPictures.icon_for(crater.look)
	var drawn_width := EventPictures.native_size(picture).x
	t.check(is_equal_approx(crater.obstructs_radius, drawn_width * 0.5),
			"the crater obstructs %.0fpx against a %.0fpx picture"
			% [crater.obstructs_radius, drawn_width])

	# And the wiring: a burst that has run its course is replaced by a crater standing where it
	# was, through the row's `aftermath.on_finish`.
	var city: City = RunCity.with_own_run(CITY_SCENE, SEEDS[0])
	t.add_child(city)
	city.build(MapCache.of(SEEDS[0]))
	city.events.setup(city, city.map)
	city.events.stream_radius = INF
	var road := city.map.tiles_of_type(GameEnums.TileType.ROAD)[0]
	var plans: Array[EventScheduler.Planned] = [
		EventScheduler.Planned.new(burst, city.map.tile_to_world(road))]
	GivenPlanner.hand_in(city.events, plans)
	var none: Array[String] = []
	city.events.start_day(DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS),
			RandomNumberGenerator.new(), none)
	t.check(city.events.instances().size() == 1, "the burst is in the world")
	var live := city.events.instances()[0]
	var steps := 0
	while not live.is_finished and steps < 400:
		live.step(0.05)
		steps += 1
	t.check(live.is_finished, "the burst is over after %.1fs" % (steps * 0.05))
	# `EventStreaming.retire_finished()` runs inside the manager's own physics frame, which the city
	# in the tree is let have.
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
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
	var run := RunState.new()
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	hud.use_run(run)
	t.add_child(hud)
	hud.set_process(false)
	var clock: Label = hud.get_node("Root/Clock")
	EventBus.day_time_changed.emit(65.5, 180.0)
	t.check(clock.text == "1:05", "a day's clock reads to the second (got '%s')" % clock.text)
	hud.use_the_day(_section(DaySpec.Section.BUILDING))
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
## (the building as a won day 14 hands over, the city as a game closed in it opens again), with
## every brief and outcome screen continued through the viewport and the loss through the signal a
## real capture fires, so what is checked is the path the game takes: the day's own clock and
## finish path, not a call this test invented. A screen is told apart by what it says: the brief by
## the section's own words as its title, the outcome screen by the reason as its title.
func _test_each_section_opens_on_its_brief_and_a_loss_on_its_outcome(t) -> void:
	for section: int in [DaySpec.Section.BUILDING, DaySpec.Section.CITY]:
		var escape := await _boot_the_escape(t, section)
		var main := escape.main
		var summary := Boot.summary(main)
		var words := _section(section).title
		var nerves := escape.run.header.nerves
		var length: float = Boot.day(main).spec.length
		var title: Label = summary.get_node("Root/Center/Lines/Title")
		var body: Label = summary.get_node("Root/Center/Lines/Body")
		t.check(Boot.day(main).spec.section == section and summary.is_showing(),
				"section %d: it opens on its brief" % section)
		t.check(title.text == words,
				"section %d: titled with the section's own words ('%s')" % [section, title.text])
		if section == DaySpec.Section.CITY:
			# The player's own words for the second screen (*"something along 'Escape the
			# building' and ... 'Escape the city'"*), as a literal: the building's brief is
			# asserted so in the handover and booted-escape cases below.
			t.check(title.text == "Escape the city", "and the city's brief reads 'Escape the city'")
		t.check(body.text.contains("Nerves left: %s" % Texts.nerve_stars(nerves)),
				"section %d: and carrying the nerve line, as stars ('%s')" % [section, body.text])
		t.check(t.get_tree().paused and is_equal_approx(Boot.day(main).time_remaining, length),
				"section %d: with a full clock standing still behind it" % section)

		await Boot.press_continue(t, main)
		t.check(not summary.is_showing() and not t.get_tree().paused,
				"section %d: continuing takes the screen away and the walk begins" % section)
		t.check(Boot.hud(main).visible, "section %d: with the HUD back" % section)
		# *(2026-09-20, the player: "the escape shouldn't behave any different than the rest of the
		# game" — read here as the hint showing every time the section's clock starts, a fast click
		# through the brief included, not only on a first entry.)*
		var teach: HelpText = Boot.hud(main).get_node("Root/Teach")
		t.check(teach.line == words,
				"section %d: and the section's own words said once she is walking it" % section)

		Boot.day(main).time_remaining -= 30.0
		EventBus.hard_fail_triggered.emit("abduction")
		t.check(summary.is_showing() and title.text != words,
				"section %d: being taken comes up on the day's outcome screen" % section)
		t.check(title.text.replace("\n", " ").contains(Texts.HARD_FAIL_TEXT["abduction"]),
				"section %d: which states the reason, as a lost day's does ('%s')"
				% [section, title.text])
		t.check(body.text.contains(words) and body.text.contains(Texts.nerve_stars(nerves)),
				"section %d: under the section's own words, the nerves unchanged ('%s')"
				% [section, body.text])
		t.check(escape.run.header.nerves == nerves,
				"section %d: since a normal run's lost section spends none" % section)

		teach.text = ""
		await Boot.press_continue(t, main)
		t.check(Boot.day(main).spec.section == section and summary.is_showing()
				and title.text == words,
				"section %d: its continue is the same section again, behind its brief" % section)
		t.check(title.text == words and body.text.contains(Texts.nerve_stars(nerves)),
				"section %d: titled with its words and the nerves unchanged ('%s', '%s')"
				% [section, title.text, body.text])
		t.check(t.get_tree().paused and is_equal_approx(Boot.day(main).time_remaining, length),
				"section %d: with a full clock standing still behind it" % section)
		await Boot.press_continue(t, main)
		t.check(not summary.is_showing() and not t.get_tree().paused
				and Boot.day(main).is_running(),
				"section %d: the brief's continue is the walk" % section)
		t.check(teach.line == words,
				"section %d: and its words said again on the retry, not only the first entry"
				% section)

		if section == DaySpec.Section.BUILDING:
			# **Each section is a day, so each gets a day's clock** — what the building spent is
			# not the city's to make up. Twenty seconds are taken off the building's clock first,
			# so a city that carried it across would be visibly short here.
			Boot.day(main).time_remaining -= 20.0
			Boot.interior(main).exit_requested.emit()
			t.check(Boot.day(main).spec.section == DaySpec.Section.CITY and summary.is_showing(),
					"the service exit begins the second section, on its own brief")
			t.check(is_equal_approx(Boot.day(main).time_remaining, length),
					"on a full clock of its own, whatever the walk down the stairs cost")
		_free_the_escape(t, escape)

## **The escape is counted like a day** *(minty-lemur #785: "telemetry should work the same also in
## escape both apartment and city")*: the run's played time (`RunHeader.play_ticks`, which the
## ending screen shows) runs while a section is walked, and a charge still running when she gets
## out of the city is closed for the page's counter as cut short, before the section's own end is
## counted — through the day's own finish path, as a day's are. The played time is read across one
## real physics frame; the charge is a masked pursuer put on the city's street as a streamed-in row
## comes back (`EventInstance.resume()`, which the streaming calls: a row brought back after it had
## noticed her is still chasing), and she is put at the tunnel, where the day's own clock finds her
## on its next tick (`DayController.tick()`, which `main`'s physics tick calls). The charge is
## spawned by the city's manager (`EventManager.spawn_extra()`), which gives it the atlas the city's
## events draw from, so a real frame can draw it.
func _test_the_escape_counts_its_time_and_closes_its_charges(t) -> void:
	var escape := await _boot_the_escape(t, DaySpec.Section.CITY)
	var main := escape.main
	await Boot.press_continue(t, main)
	await t.get_tree().physics_frame
	var played := escape.run.header.play_ticks
	await t.get_tree().physics_frame
	t.check(escape.run.header.play_ticks == played + 1,
			"walking the city section counts toward the run's played time (%d, then %d ticks)"
			% [played, escape.run.header.play_ticks])

	var heard: Array[String] = []
	var on_cut_short := func(id: String) -> void:
		heard.append("cut short " + id)
	var on_ended := func(day: int, result: GameEnums.DayResult, _cause: String, _e: float) -> void:
		heard.append("day %d %s" % [day, GameEnums.DayResult.keys()[result]])
	EventBus.pursuit_cut_short.connect(on_cut_short)
	EventBus.day_ended.connect(on_ended)
	var her := Boot.player(main)
	var city := Boot.city(main)
	var guard := city.events.spawn_extra(EventCatalogue.by_id("masked_pursuer"), her.global_position,
			PackedVector2Array([her.global_position, her.global_position + Vector2(0.0, -400.0)]))
	guard.set_process(false)
	guard.resume(0.01, 0.0, 0.0)
	her.global_position = Boot.day(main).spec.exits[CityEdge.Kind.TUNNEL]
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check(heard == ["cut short masked_pursuer", "day %d WON" % DaySpec.CITY_DAY],
			"getting out closes the charge still running, then ends the city's day (%s)" % [heard])
	EventBus.pursuit_cut_short.disconnect(on_cut_short)
	EventBus.day_ended.disconnect(on_ended)
	_free_the_escape(t, escape)

## One of the escape's sections, a whole clock long, titled the way the run titles it.
static func _section(section: int) -> DaySpec:
	return DaySpec.for_section(section, RunConfig.FINALE_LENGTH_SECONDS,
			Texts.ESCAPE_BUILDING if section == DaySpec.Section.BUILDING else Texts.ESCAPE_CITY)

## A booted escape: the real `main.tscn`, the run of the test's own it plays (on seed `SEEDS[0]`
## and its last day, handed over to `section`), and the home its sitting is parked in. Freed
## together by `_free_the_escape()`.
class Escape:
	var booted: RefCounted
	var main: Node2D
	var run: RunState
	var home: Node

## Boots the real `main.tscn` on `section` of a normal run's own escape — the way a won day 14's
## handover and a game closed in a section both reach the boot — through `tests/booted_main.gd`, a
## debug configuration with `flags` and no save, handed a home with a sitting that holds a fresh run
## of the test's own, set on the last day with `section` its escape section. `before` is handed the
## unbooted `main` for anything else the test hands it (`use_quit()`, `use_reload()`). Returned
## with its first screen up.
func _boot_the_escape(t, section: int, flags: PackedStringArray = PackedStringArray(),
		before := Callable()) -> Escape:
	var escape := Escape.new()
	escape.run = RunState.new()
	escape.run.start_run(SEEDS[0])
	escape.run.header.day = Tuning.RUN_LENGTH_DAYS
	escape.run.facts.escape_section = section
	escape.home = Boot.home_playing(t, escape.run)
	var home := escape.home
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, Boot.config(Array(flags)),
			func(main: Node) -> void:
				main.use_sitting_home(home)
				if before.is_valid():
					before.call(main))
	escape.booted = booted
	escape.main = booted.main
	return escape

func _free_the_escape(t, escape: Escape) -> void:
	t.get_tree().paused = false
	(escape.booted as Boot.Booted).free_all()
	# A `--route` boot is a rig, whose `RigLock` erases every action's `InputMap` bindings; freeing
	# the scene must give them back, or every later suite in this process hears no key as an action.
	t.check(not InputMap.action_get_events(&"move_right").is_empty(),
			"freeing the escape leaves the keys bound to their actions")
	escape.home.free()

## `main` hands each section its `DaySpec`, read off the day's clock of a booted escape, and each
## section is counted as a day of its own after the last.
func _test_the_two_sections_are_the_two_days_after_the_last(t) -> void:
	var numbers: Array[int] = []
	for section: int in [DaySpec.Section.BUILDING, DaySpec.Section.CITY]:
		var escape := await _boot_the_escape(t, section)
		numbers.append(Boot.day(escape.main).spec.number)
		_free_the_escape(t, escape)
	t.check(numbers[0] == Tuning.RUN_LENGTH_DAYS + 1 and numbers[1] == numbers[0] + 1,
			"and they are the two days after the last (%d and %d)" % [numbers[0], numbers[1]])

## *"The escape the building starts when the player has completed all tasks by the end of day
## 14."* Every other way day 14 can end keeps the ending it already had, which is what the three
## negative rows are for: a won last day with the legwork but not the sabotage is the neutral
## ending and must not reach the escape, and neither must a won earlier day that happens to have
## finished every task early.
func _test_only_a_won_last_day_with_every_task_done_hands_over(t) -> void:
	var last := Tuning.RUN_LENGTH_DAYS
	t.check(_hands_over(t, GameEnums.DayResult.WON, last, Tuning.RESISTANCE_GOAL, true),
			"a won day 14 with every task complete hands over to the escape")
	t.check(not _hands_over(t, GameEnums.DayResult.LOST_CRYING, last, Tuning.RESISTANCE_GOAL, true),
			"a lost day 14 does not, however much was done")
	t.check(not _hands_over(t, GameEnums.DayResult.WON, last, Tuning.RESISTANCE_GOAL, false),
			"nor a won day 14 with the errands run and the last night skipped")
	t.check(not _hands_over(t, GameEnums.DayResult.WON, last, Tuning.RESISTANCE_GOAL - 1, true),
			"nor one short of the goal")
	t.check(not _hands_over(t, GameEnums.DayResult.WON, last - 1, Tuning.RESISTANCE_GOAL, true),
			"and nor does a won day before the last one")

## Whether ending a day of `day` with the given result, goal progress and sabotage hands over to the
## escape: the `DayEnd` a director of a run of its own, over a bare clock, returns (a run of its own,
## so nothing of the autoload's is touched; the clock is freed).
func _hands_over(t, result: GameEnums.DayResult, day: int, progress: int, sabotaged: bool) -> bool:
	var run := RunState.new()
	var director := DayDirector.new(run.calendar, run.facts, run.attempt_spend, RunConfig.parse(PackedStringArray(), "", true))
	run.start_run(9182)
	run.header.day = day
	run.resistance.progress = progress
	run.resistance.sabotage_done = sabotaged
	var clock := DayController.new()
	clock.set_process(false)
	t.add_child(clock)
	clock.start(300.0)
	director.use_the_world(null, null, null, null, null, clock)
	var handed := director.finish_day(result).hands_over_to_the_escape
	clock.free()
	return handed

## Every part word `--start-escape` recognises has to actually move her, onto ground she can
## stand on: the real `main` booted on each word, her position read off the building it builds.
func _test_every_part_word_reaches_its_own_walkable_position(t) -> void:
	for word in ["stairwell:left", "stairwell:right", "lobby", "basement", "floor:2", "floor:1"]:
		var escape := await _boot_the_escape(t, DaySpec.Section.BUILDING,
				PackedStringArray(["--start-escape", word]))
		var scene := Boot.interior(escape.main)
		var her := Boot.player(escape.main)
		var at := her.global_position
		t.check(at != scene.start_world_position(), "'%s' teleports away from her own door" % word)
		t.check(scene.map.is_walkable(scene.map.world_to_tile(at)),
				"'%s' lands on a walkable tile" % word)
		# **And one she stays on.** A part word puts her down with nothing armed, and
		# `process_player()` fires a transition on the frame she is standing on a door or the
		# service exit — so a waypoint that is a threshold shows her the part on the other side of
		# it rather than the part she asked for, silently, with the flag looking like it worked.
		t.check(scene.map.transition_at(scene.map.world_to_tile(at)).is_empty(),
				"'%s' lands somewhere that is not a door" % word)
		_free_the_escape(t, escape)

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
	var map := MapCache.of(SEEDS[0])
	var an_act_iv_day := 13
	t.check(Tuning.act_for_day(an_act_iv_day) >= 3
			and EventDirector.RETURN_PATROLS_PER_ACT[Tuning.act_for_day(an_act_iv_day) - 1] > 0,
			"day %d is a day that owes its return something" % an_act_iv_day)
	var bare := EventDirector.new(map)
	bare.owe_the_return(an_act_iv_day, 0)
	t.check(bare.owed() > 0, "a day's own director owes %d rows to the return" % bare.owed())

	var city: City = RunCity.with_own_run(CITY_SCENE, SEEDS[0])
	t.add_child(city)
	city.build(MapCache.of(SEEDS[0]))
	city.events.setup(city, city.map)
	city.run.header.day = an_act_iv_day
	GivenPlanner.hand_in(city.events, [] as Array[EventScheduler.Planned])
	var none: Array[String] = []
	city.events.start_day(DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS),
			RandomNumberGenerator.new(), none)
	EventBus.return_phase_started.emit()
	t.check(city.events.owed_ahead() == 0,
			"and the escape owes nothing to a return it does not have (got %d)"
					% city.events.owed_ahead())
	city.free()

## **The walk's settings are the spec's, handed in, not the manager's own**: on the same act IV day
## and the same city, a day's spec owes the return its rows and a spec that says it owes none
## (`DaySpec.owes_a_return` false) is owed none, by the same `start_day()`. So what decides it is the
## spec the run flow hands over (`EventManager.start_day()`), never a branch in the manager.
func _test_a_day_owes_its_return_only_as_its_spec_says(t) -> void:
	var an_act_iv_day := 13
	var city: City = RunCity.with_own_run(CITY_SCENE, SEEDS[0])
	t.add_child(city)
	city.build(MapCache.of(SEEDS[0]))
	city.events.setup(city, city.map)
	city.run.header.day = an_act_iv_day
	var owed := {}
	for owes: bool in [true, false]:
		var spec := DaySpec.for_day(an_act_iv_day, Tuning.DAY_LENGTH_SECONDS)
		spec.owes_a_return = owes
		var consumed: Array[String] = []
		city.events.start_day(spec, city.run.calendar.day_rng(an_act_iv_day), consumed)
		var before := city.events.owed_ahead()
		EventBus.return_phase_started.emit()
		owed[owes] = city.events.owed_ahead() - before
	t.check(int(owed[true]) > 0, "a day's spec owes its return rows (%d)" % owed[true])
	t.check(int(owed[false]) == 0,
			"and a spec that owes none is owed none on the same day (%d)" % owed[false])
	city.free()

## **A tree and an event never share ground** (`docs/CITY.md`, "Street trees"), and the escape's
## own plan is a second placement path that does not go through `EventScheduler.open_ground_for`
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
		# The two halves of the escape's placements are asked separately, because only one of them has a
		# licensed exception: they are re-planned here from the same inputs rather than told apart
		# by row id, since `barricade` and `impact_crater` are each both a seal picture and an
		# event's own row.
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for placement in EventScheduler.build_day(_city_spec(), rng, map, CalmAreas.of(map), MastSites.compute(map), [],
				[], plan).placements():
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

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event

## `Esc`, the pause button's own action and a window losing focus all reach the pause screen during
## a section exactly as they do during a day: the same continue, the same held restart, the same
## quit, and the same stashed heading through `TouchControls`. **Booted for real** on the building
## and walked out of its brief, with the quit and the reload handed to counters (`main.use_quit()`,
## `main.use_reload()`), since the real ones would take the runner's own scene away: the pause
## screen's own quit and restart signals are heard reaching them, the window's focus loss is the
## `ReturnWindow`'s own notification, `Esc` is pushed through the viewport as a key arrives, and her
## heading is held by the on-screen controls (a click east of her, what a tap locks in).
## `--no-focus-pause` is a second boot under that flag.
##
## **`Esc` over a pause already open is the pause screen's to answer**: it reaches the screen before
## `main` and closes it (`PauseScreen._unhandled_input()`), so what is checked is that it closes
## and no second pause opens over it; `main`'s own refusal to open over an open pause is not
## reachable by a real key while the screen answers first.
func _test_the_escape_pauses_the_same_way_a_day_does(t) -> void:
	var calls := {"quits": 0, "reloads": 0}
	var hand := func(main: Node) -> void:
		main.use_quit(func() -> void: calls["quits"] += 1)
		main.use_reload(func() -> void: calls["reloads"] += 1)
	var escape := await _boot_the_escape(t, DaySpec.Section.BUILDING, PackedStringArray(), hand)
	var main := escape.main
	var pause := Boot.pause(main)
	await Boot.press_continue(t, main)
	t.check(Boot.day(main).is_running(), "the section's clock is running")
	t.check(not pause.is_open(), "and nothing is paused yet")
	t.check(Boot.day(main).can_process() and Boot.interior(main).can_process(),
			"the section's clock and the building process while the tree is running")

	# The quit is pressed where the game fires it: with the pause open, as a `Q` through the viewport.
	t.get_viewport().push_input(_action("pause"))
	t.check(pause.is_open(), "Esc opens the pause")
	t.get_viewport().push_input(_key(KEY_Q))
	t.check(calls["quits"] == 1, "Q on the open pause reaches the same quit a day's pause reaches")
	pause.close()
	t.get_tree().paused = false

	# Her heading, held by the on-screen controls: let go while the pause is up, and given back by
	# the pause screen's close only if it stashed it in these same controls. The controls are let a
	# frame of the walk first, so they have seen the tree running since the brief.
	await UI.frames(t)
	var controls := Boot.touch_controls(main)
	var east: Vector2 = controls.get_viewport().get_canvas_transform() \
			* (Boot.player(main).global_position + Vector2(200.0, 0.0))
	UI.push(controls, UI.mouse_at(east, true))
	UI.push(controls, UI.mouse_at(east, false))
	var held := Input.is_action_pressed(&"move_right")
	var window := main.get_node("ReturnWindow") as ReturnWindow
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(pause.is_open(), "losing the window's focus opens the same pause a day's does")
	t.check(t.get_tree().paused, "and pauses the tree behind it")
	# *"Pause etc should exist the same way it does in the main game"* (PLAYTEST-114): the clock
	# and the building get their pausable mode from `main._pauses_with_the_game()` as the boot builds
	# them, and `Node.can_process()` is the question the engine asks before it delivers a callback.
	t.check(not Boot.day(main).can_process() and not Boot.interior(main).can_process(),
			"the section's clock and everything in the building stop while the pause screen is open")
	await UI.frames(t)
	var let_go := not Input.is_action_pressed(&"move_right")
	t.get_viewport().push_input(_action("pause"))
	t.check(not pause.is_open(), "Esc over the open pause closes it, and no second pause opens")
	t.check(held and let_go and Input.is_action_pressed(&"move_right"),
			"the pause screen can stash and restore her heading through the same touch controls")
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down", &"run"]:
		Input.action_release(action)
	t.get_tree().paused = false

	t.get_viewport().push_input(_action("pause"))
	t.get_viewport().push_input(_key(KEY_R))
	t.check(calls["reloads"] == 1, "and R on the open pause reaches the same restart a day's does")
	pause.close()
	t.get_tree().paused = false
	_free_the_escape(t, escape)

	var unpaused := await _boot_the_escape(t, DaySpec.Section.BUILDING,
			PackedStringArray(["--no-focus-pause"]))
	await Boot.press_continue(t, unpaused.main)
	(unpaused.main.get_node("ReturnWindow") as ReturnWindow).notification(
			Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not Boot.pause(unpaused.main).is_open(),
			"--no-focus-pause suppresses that during the escape too")
	_free_the_escape(t, unpaused)

## A section's brief and the epilogue are the one exception to an ordinary day's own "Esc opens over
## the summary too": each stands between her and a walk not yet begun, so a second screen stacked
## over it would answer a question nobody asked, the same reason focus loss never opens over any
## `_summary` at all. A lost section's outcome screen is the day's own screen, and Esc opens over it
## as over a lost day's *(minty-lemur #785: "nothing should be different")*; focus loss does not,
## as on a day. **Booted for real** on the city section and walked through each screen the way the
## game reaches it — the brief, the outcome screen of a loss, the retry's brief, the epilogue —
## with every `Esc` pushed through the viewport and every continue pressed there.
func _test_pause_does_not_open_over_a_section_brief_or_the_epilogue(t) -> void:
	var escape := await _boot_the_escape(t, DaySpec.Section.CITY)
	var main := escape.main
	var summary := Boot.summary(main)
	var pause := Boot.pause(main)
	var window := main.get_node("ReturnWindow") as ReturnWindow
	var title: Label = summary.get_node("Root/Center/Lines/Title")
	var words := _section(DaySpec.Section.CITY).title

	t.check(summary.is_showing() and title.text == words, "the section's brief is up")
	t.get_viewport().push_input(_action("pause"))
	t.check(not pause.is_open(), "Esc does not open the pause over a section's brief")
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not pause.is_open(), "and neither does losing focus")

	await Boot.press_continue(t, main)
	EventBus.hard_fail_triggered.emit("abduction")
	t.check(summary.is_showing() and title.text != words, "a lost section's outcome screen is up")
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not pause.is_open(), "losing focus does not open the pause over it")
	t.get_viewport().push_input(_action("pause"))
	t.check(pause.is_open(), "Esc does, as over a lost day's outcome screen")
	pause.close()
	t.check(t.get_tree().paused and summary.is_showing(),
			"and closing it leaves the outcome screen up and the tree paused")

	await Boot.press_continue(t, main)
	t.check(summary.is_showing() and title.text == words, "the retry's brief is up")
	t.get_viewport().push_input(_action("pause"))
	t.check(not pause.is_open(), "Esc does not open the pause over it")

	await Boot.press_continue(t, main)
	Boot.player(main).global_position = Boot.day(main).spec.exits[CityEdge.Kind.TUNNEL]
	for _frame in 3:
		await t.get_tree().physics_frame
	t.check(summary.is_showing() and title.text == Texts.FINALE_TITLE,
			"out of the city, the epilogue is up")
	t.get_viewport().push_input(_action("pause"))
	t.check(not pause.is_open(), "Esc does not open the pause over the epilogue")
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not pause.is_open(), "and neither does losing focus")
	_free_the_escape(t, escape)

# ------------------------------------------------------ a resumed escape, and a handover ---

## *(2026-09-20, the player, on a save closed inside a section: "if I load into the game and I'm at
## escape I see the title screen, then the brief".)* A genuinely resumed escape — a page with nothing
## of the escape on its run, opening a save closed inside a section — opens on the title, with the
## section's clock standing still behind it, and the title's start raises the section's brief, the
## resume gate a resumed day has too. **Booted for real from a save on disk** (a scratch file, a
## windowed release run), handed a fresh run of the test's own that the save is read into, so what
## is checked is the boot's own decision — whether the section came from the file — not a screen
## this test opened by hand; the title's start is a press on its Tap button through the viewport.
func _test_a_resumed_escape_opens_on_the_title_before_its_first_brief(t) -> void:
	var config := RunConfig.parse(PackedStringArray(["--no-telemetry"]), "", false, false, {}, false)
	var save := GameSave.new(_SCRATCH_SAVE)
	save.configure(config)
	var closed := RunState.new()
	closed.start_run(SEEDS[0])
	closed.header.day = Tuning.RUN_LENGTH_DAYS
	closed.facts.escape_section = DaySpec.Section.BUILDING
	t.check(save.write(closed, false) == GameSave.Result.CONFIRMED,
			"a save closed inside the building is on disk")
	save.free()
	# A fresh page: nothing of the escape on the run it plays, only in the file.
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, config,
			func(main: Node) -> void: main.use_sitting_home(home))
	var main := booted.main
	var day := Boot.day(main)
	var length: float = day.spec.length

	t.check(day.spec.section == DaySpec.Section.BUILDING,
			"the boot read the section off the save")
	t.check(Boot.title(main).is_open() and not Boot.summary(main).is_showing(),
			"a genuinely resumed escape opens on the title first, the section's brief not yet up")
	t.check(Boot.mode_name_drawn(Boot.title(main)) != "", "and names the mode, which the save already fixed")
	t.check(Boot.title(main).is_open() and t.get_tree().paused, "and the boot is behind its title")
	t.check(t.get_tree().paused and not day.can_process()
			and is_equal_approx(day.time_remaining, length),
			"with the section's whole clock standing still behind the title (%.2f of %.2f)"
			% [day.time_remaining, length])

	await Boot.press_title(t, main, "Tap")
	t.check(not Boot.title(main).is_open(), "pressing start closes the title")
	var title_label: Label = Boot.summary(main).get_node("Root/Center/Lines/Title")
	t.check(Boot.summary(main).is_showing() and title_label.text == "Escape the building",
			"and raises the section's own brief, in front of the section already built")
	t.check(not Boot.title(main).is_open(), "the title is behind her")
	t.check(t.get_tree().paused and is_equal_approx(day.time_remaining, length),
			"the clock still standing still behind the brief")

	(home.get_node(NodePath(Sitting.NODE_NAME)) as Sitting).atlas.close_loading_window()
	t.get_tree().paused = false
	booted.free_all()
	t.check(not InputMap.action_get_events(&"move_right").is_empty(),
			"freeing the escape leaves the keys bound to their actions")
	home.free()

## `--route` booted into the building: the building's own walker presses the building's brief
## (`BuildingWalker`, the rig a route builds with the building), there is no city rig yet, and once
## the building is won the city is built, its brief raised, and the route rig presses that brief's
## continue the way a key does — through the run flow's own continue, with no special case in `main`.
## The building is won by its service door's `exit_requested`, and the rig is found by the name
## `main` gives it. The building's brief is left to the walker rather than continued here: a second
## continue for it, still in flight when the city's brief comes up, would press the city's brief in
## the rig's place.
func _test_a_route_rig_carries_the_building_on_into_the_city(t) -> void:
	var escape := await _boot_the_escape(t, DaySpec.Section.BUILDING,
			PackedStringArray(["--route", "tunnel"]))
	var main := escape.main
	var summary := Boot.summary(main)
	await _let_frames_pass(t, 4)
	t.check(main.get_node_or_null("RouteRig") == null and not summary.is_showing()
			and Boot.day(main).spec.section == DaySpec.Section.BUILDING,
			"a route booted into the building has no city to walk yet, and its walker pressed the"
			+ " building's brief")
	Boot.interior(main).exit_requested.emit()
	t.check(main.get_node_or_null("RouteRig") != null, "winning the building builds the rig with the city")
	await _let_frames_pass(t, 4)
	t.check(Boot.day(main).spec.section == DaySpec.Section.CITY and Boot.day(main).is_running()
			and not summary.is_showing(),
			"the rig pressed the city brief's continue: the city is walked")
	t.check(not t.get_tree().paused, "and the tree runs")
	_free_the_escape(t, escape)

## held before the branch in `main` was removed, and guards that the removal changed nothing.
func _test_a_route_rig_boots_the_city_section_and_walks(t) -> void:
	var escape := await _boot_the_escape(t, DaySpec.Section.CITY,
			PackedStringArray(["--route", "tunnel"]))
	var main := escape.main
	await _let_frames_pass(t, 4)
	t.check(main.get_node_or_null("RouteRig") != null and Boot.day(main).is_running()
			and not Boot.summary(main).is_showing(),
			"a route booted into the city walks it with no one pressing the brief")
	_free_the_escape(t, escape)

## The rig presses a section's first brief only: a retry brief, raised after a loss, stays up, so a
## lost city section stops there instead of retrying forever. Fails without the `_pressed` guard.
func _test_a_route_rig_presses_only_the_first_brief_of_a_section(t) -> void:
	var rig := RouteRig.new()
	t.add_child(rig)
	var presses := [0]
	rig.use_continue(func(_raised_in: int) -> void: presses[0] += 1)
	var city := _section(DaySpec.Section.CITY)
	rig.press_the_brief(city)
	await _let_frames_pass(t, 2)
	rig.press_the_brief(city)
	await _let_frames_pass(t, 2)
	t.check(presses[0] == 1, "the city's first brief is pressed and its retry brief is not (%d)" % presses[0])
	rig.press_the_brief(_section(DaySpec.Section.BUILDING))
	await _let_frames_pass(t, 2)
	t.check(presses[0] == 2, "another section's first brief is pressed")
	rig.press_the_brief(DaySpec.new())
	await _let_frames_pass(t, 2)
	t.check(presses[0] == 2, "a day's brief is left alone")
	rig.free()

func _let_frames_pass(t, frames: int) -> void:
	for i in frames:
		await t.get_tree().process_frame

## The handover reload from a won day 14 reaches the boot with the run's escape section already
## set — it was set on the run the sitting carries across the reload — so the boot does not count
## it as read off a save, and it opens straight on the building's own brief, with no title in front
## of it and the section's clock standing still behind the brief. Booted for real, on a run of the
## test's own that holds the section as the handover leaves it.
func _test_a_handover_does_not_open_on_the_title(t) -> void:
	var escape := await _boot_the_escape(t, DaySpec.Section.BUILDING)
	var main := escape.main
	var title: Label = Boot.summary(main).get_node("Root/Center/Lines/Title")
	t.check(not Boot.title(main).is_open(), "a handover does not raise the title")
	t.check(Boot.summary(main).is_showing() and title.text == "Escape the building",
			"it opens straight on the section's own brief")
	t.check(t.get_tree().paused and not Boot.day(main).can_process()
			and is_equal_approx(Boot.day(main).time_remaining, Boot.day(main).spec.length),
			"with the section's whole clock standing still behind it")
	_free_the_escape(t, escape)

## *"the held restart from the escape ends in a fresh run with escape_section cleared"* — booted
## for real on the city section, with the reload handed to a counter (`main.use_reload()`), since a
## real one would throw away the runner's own scene. Both of the escape's own screens reach the
## restart, the same as a day's two: the pause screen's restart signal and the section brief's own
## restart button's (`DaySummary.restart_requested`); and each hands the sitting a fresh run, with
## no escape section, so the next boot starts it rather than opening the escape again. Its
## `_save.clear()` is exercised, at a scratch path, by `tests/test_save_wiring.gd`.
func _test_the_held_restart_from_the_escape_clears_the_section(t) -> void:
	var reloads := [0]
	var escape := await _boot_the_escape(t, DaySpec.Section.CITY, PackedStringArray(),
			func(main: Node) -> void: main.use_reload(func() -> void: reloads[0] += 1))
	var main := escape.main
	await Boot.press_continue(t, main)
	t.get_viewport().push_input(_action("pause"))
	t.get_viewport().push_input(_key(KEY_R))
	Boot.pause(main).close()
	t.get_tree().paused = false
	t.check(reloads[0] == 1, "the escape's own pause screen reaches the held restart, same as a day's")
	var sitting := escape.home.get_node(NodePath(Sitting.NODE_NAME)) as Sitting
	var after_the_pause := sitting.run
	Boot.summary(main).restart_requested.emit()
	t.check(reloads[0] == 2,
			"and so does the section brief's own restart button — the same DaySummary a day uses")
	t.check(sitting.run != escape.run and sitting.run != after_the_pause
			and sitting.run.facts.escape_section == DaySpec.Section.NONE,
			"each restart hands the sitting a fresh run, with no escape section — the run the "
			+ "next boot starts")
	_free_the_escape(t, escape)

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
