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
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

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
	_test_the_service_exit_is_beside_the_home_block(t)
	_test_the_finale_city_has_nobody_in_it(t)
	_test_a_burst_leaves_a_crater_as_wide_as_its_own_picture(t)
	_test_the_clock_reads_milliseconds_only_in_the_finale(t)
	_test_a_lost_section_starts_again_and_costs_no_nerve(t)
	_test_the_city_word_boots_the_second_section(t)
	_test_the_escape_owes_no_return_leg(t)
	_test_nothing_the_escape_places_stands_in_a_street_tree(t)

# --------------------------------------------------------------- the chains ---

static func _plan_for(seed_value: int) -> Dictionary:
	var map := CityGenerator.generate(seed_value)
	GameState.city_state.begin_day(map.block_plans, 1)
	map.repaint(GameState.city_state)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return {"map": map, "plan": FinalePlanner.plan(map, rng)}

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
		var home := ClosurePlanner.home_street(map)
		var open_and_unsealed := 0
		var closed := 0
		for segment in StreetNetwork.segments():
			if not map.has_street(segment.key()):
				continue
			if SealPlanner.runs_through(segment, plan.open_cells):
				continue
			if home and segment.key() == home.key():
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

# ------------------------------------------------------------------ the city ---

## *"No regular cars or regular people on the street."* Non-vacuous on purpose: the crowd is
## populated first, so what is asserted is that clearing it and dressing the city for the escape
## leaves it empty rather than that it started that way.
func _test_the_finale_city_has_nobody_in_it(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEEDS[0]))
	GameState.city_state.begin_day(city.map.block_plans, 1)
	city.crowd.start_day(1, GameState.day_rng(1, "crowd"), city.map.doorstep_world_position())
	t.check(city.crowd.agent_count() > 0, "a day's crowd is a crowd")
	city.start_finale(GameState.city_state, 1)
	city.crowd.clear()
	t.check(city.crowd.agent_count() == 0, "and the escape's city has nobody in it")
	t.check(city.route_tree() == null and city.closures().is_empty(),
			"the escape grows no corridor and closes no street")
	city.queue_free()

## *"Explosions happen off screen (but loud enough to cause excitement) leaving craters on the
## street."* Both halves: the row names its successor, and what the successor obstructs is exactly
## half of the picture it draws — *anything that stands still is solid at the width it is drawn*.
func _test_a_burst_leaves_a_crater_as_wide_as_its_own_picture(t) -> void:
	var burst := EventCatalogue.by_id("finale_explosion")
	var crater := EventCatalogue.by_id("impact_crater")
	t.check(burst != null and crater != null, "both finale rows are in the catalogue")
	t.check(burst.spawns_on_finish == crater.id, "the burst names the crater it leaves")
	t.check(burst.look == EventDef.Look.NONE, "and draws nothing itself")
	var picture := EventInstance.icon_for(crater.look)
	t.check(is_equal_approx(crater.obstructs_radius, picture.get_width() * 0.5),
			"the crater obstructs %.0fpx against a %.0fpx picture"
			% [crater.obstructs_radius, picture.get_width()])

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
	city.events.start_finale(plans)
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
	city.queue_free()

# ------------------------------------------------------------------ the clock ---

## *"The timer also shows milliseconds. This makes the timer appear faster than just the seconds
## alone which adds additional tension."* The only thing that changes, so both shapes are checked
## off the same signal and the same time.
func _test_the_clock_reads_milliseconds_only_in_the_finale(t) -> void:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)
	var clock: Label = hud.get_node("Root/Clock")
	EventBus.day_time_changed.emit(65.5, 180.0)
	t.check(clock.text == "1:05", "a day's clock reads to the second (got '%s')" % clock.text)
	hud.set_finale(true)
	EventBus.day_time_changed.emit(65.5, 180.0)
	t.check(clock.text == "1:05.500",
			"the escape's clock reads to the millisecond (got '%s')" % clock.text)
	hud.queue_free()

# ------------------------------------------------------------- the sections ---

## *"Losing the finale restarts the section, at no Nerve cost"* — *"sounds good at that point you
## earned it."* Driven through the signal a real capture fires, so what is checked is the path the
## game takes rather than a call this test invented.
func _test_a_lost_section_starts_again_and_costs_no_nerve(t) -> void:
	DevFlags._invincible_override = false
	var finale := FinaleController.new()
	t.add_child(finale)
	var started: Array = []
	finale.section_started.connect(func(section: int, restarted: bool) -> void:
		started.append([section, restarted]))

	finale.begin(FinaleController.Section.BUILDING)
	t.check(started.size() == 1 and not started[0][1], "the first section starts fresh")
	var nerves := GameState.nerves
	# Half a minute off the clock, so a restart putting it back is visible.
	finale._clock.time_remaining -= 30.0

	EventBus.hard_fail_triggered.emit("abduction")
	t.check(started.size() == 2, "being taken starts the section again")
	t.check(started[1][0] == FinaleController.Section.BUILDING and started[1][1],
			"and it is the same section, marked as a retry")
	t.check(is_equal_approx(finale.time_remaining(), FinaleController.length()),
			"with the clock back at full length")
	t.check(GameState.nerves == nerves, "and no Nerve spent")

	# Crossing into the city keeps the clock the first section was spending: one clock, both halves.
	finale._clock.time_remaining -= 20.0
	var carried := finale.time_remaining()
	finale.enter_city()
	t.check(started.size() == 3 and started[2][0] == FinaleController.Section.CITY,
			"the service exit begins the second section")
	t.check(is_equal_approx(finale.time_remaining(), carried),
			"on the same clock, not a fresh one")
	finale.queue_free()
	DevFlags._invincible_override = null

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
	city.events.start_finale([] as Array[EventScheduler.Planned])
	EventBus.return_phase_started.emit()
	t.check(city.events.owed_ahead() == 0,
			"and the escape owes nothing to a return it does not have (got %d)"
					% city.events.owed_ahead())
	GameState.day = was_the_day
	city.queue_free()

## **A tree and an event never share ground** (`docs/CITY.md`, "Street trees"), and the escape's
## own plan is a second placement path that does not go through `EventScheduler._open_ground_for`
## or `SealPlanner.plan_day` — so the rule is asserted on this side too, over the whole plan: the
## trucks, vans, masked men and bursts on the open streets, and every seal body off them.
##
## **The one licensed exception is a seal that could not step off a tree without stepping onto the
## chain.** `SealPlanner.plan_finale` refuses that move, because a picture overlapping a picture is
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
		for placement in EventScheduler.build_finale(map, rng, plan.open_streets):
			var tile := map.world_to_tile(placement.position)
			t.check(not trees.has(tile),
					"seed %d: the escape's '%s' stands in a street tree at %s"
							% [seed_value, placement.def.id, tile])
			checked += 1
		rng.seed = seed_value
		for seal in SealPlanner.plan_finale(map, plan.open_cells, rng):
			if trees.has(map.world_to_tile(seal.position)):
				in_a_tree += 1
			checked += 1
	t.check(checked > 0, "there were escape placements to ask about (%d)" % checked)
	t.check(in_a_tree * 20 < checked,
			"and seals held against a tree by the chain stay rare (%d of %d bodies)"
					% [in_a_tree, checked])
