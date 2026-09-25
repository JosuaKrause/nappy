extends "res://tests/events_shared_city.gd"
## Playtest 07, findings 16 and 13: *"none of the non-moving obstacles do anything -- I can freely
## walk over them"*, and *"I can walk over the robber and he doesn't do anything"*. The answer is a
## rule rather than a list of rows, and these are the three ways it can quietly stop being one:
## anything that stands still has to be solid, a lethal thing still has to be reachable, and the
## pram's own size has to match what the rules think it is -- plus the placements the catalogue
## actually produces: a parked van at the kerb, a lorry with a wall to back into, nothing on the
## doorstep street, nothing on ground a route holds, no body closing a walked sidewalk.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again". Extends
## `events_shared_city.gd` for the three placement tests that ask what the scheduler actually put
## on the shared city's own streets.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_everything_that_stands_still_is_solid(t)
	_test_a_lethal_thing_can_still_be_reached(t)
	_test_the_pram_is_the_size_the_rules_think_it_is(t)
	_test_a_parked_van_is_at_the_kerb(t)
	_test_a_lorry_has_a_wall_to_back_into(t)
	_test_nothing_stands_on_the_doorstep_street(t)
	_test_nothing_the_catalogue_places_stands_on_held_ground(t)
	_test_no_body_closes_a_walked_sidewalk(t)


## **Anything that stands still is solid.** Every exemption is named here rather than left to be
## inferred from a zero, because the failure this catches is the one that happened: a field that
## is only set where somebody remembered to set it, on five rows out of thirty, for six
## milestones.
func _test_everything_that_stands_still_is_solid(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		# A moving wall pins her against a building on a two-tile pavement, which is a different
		# game from being priced out of a street. See `dog_walker`.
		if def.mobile or def.pursues:
			continue
		# Nothing checks that a thing sited out of where she happens to be walking leaves a route
		# to a park, so `EventDef.validate()` refuses a body on one outright.
		if def.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER:
			continue
		# Nothing drawn, nothing to bump into: a curfew announcement carried by a mast that is
		# already solid on its own, a playground the park itself draws.
		if def.look == EventDef.Look.NONE:
			continue
		# A flock is several bodies wheeling inside one disc with pavement between them, so there is
		# no silhouette for a body to be half of — and being walked into is the whole event, which a
		# body would stop at the rim. `EventDef.validate()` refuses one that obstructs.
		if def.flock_size > 0:
			continue
		checked += 1
		t.check(def.obstructs_radius > 0.0,
				"'%s' stands still, so it is solid" % def.id)
	t.check(checked >= 15,
			"and the rule covers most of the catalogue (%d rows)" % checked)

## **A lethal radius and a solid body are the same mechanism**, so an event carrying both can
## turn its own kill off. She is stopped `obstructs_radius + PLAYER_BODY_RADIUS` from the centre;
## if that reaches the inner radius, no amount of carelessness ever ends the day there.
##
## This is `alley_robbery`'s bug in the abstract: at an inner radius of 22 against a man 11 wide,
## the pram would have been held three pixels outside the thing that takes the baby.
func _test_a_lethal_thing_can_still_be_reached(t) -> void:
	var lethal := 0
	for def in EventCatalogue.all():
		if not def.hard_fail or def.obstructs_radius <= 0.0:
			continue
		lethal += 1
		t.check(def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS < def.inner_radius,
				"'%s' is solid to %.0f and lethal inside %.0f, so touching it still ends the day"
				% [def.id, def.obstructs_radius, def.inner_radius])
	t.check(lethal > 0, "and there are lethal solid things to check")

## `Tuning.PLAYER_BODY_RADIUS` is a copy of a number authored in the player's scene, and the rule
## above is arithmetic on it. A copy nothing checks is a lie waiting to happen.
func _test_the_pram_is_the_size_the_rules_think_it_is(t) -> void:
	var scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var stroller: Node = scene.instantiate()
	var shape := (stroller.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
	t.check(shape != null and is_equal_approx(shape.radius, Tuning.PLAYER_BODY_RADIUS),
			"the pram's own body is PLAYER_BODY_RADIUS (%.1f in the scene, %.1f in Tuning)"
			% [shape.radius if shape else -1.0, Tuning.PLAYER_BODY_RADIUS])
	stroller.free()

## Playtest 07, finding 7: *"there is also a car obstacle on the road that is basically a still
## car standing on the road doing nothing."* A parked van belongs against a kerb — on the
## pavement she is walking down, and out of a traffic lane the crowd drives straight through.
func _test_a_parked_van_is_at_the_kerb(t) -> void:
	var map := _map()
	var parked := 0
	for day in range(1, 15):
		for plan in _planned(day):
			if plan.def.pavement_side != EventDef.Pavement.AT_THE_KERB:
				continue
			parked += 1
			var tile := map.world_to_tile(plan.position)
			var inward := map.pavement_inward(tile)
			t.check(inward != Vector2i.ZERO,
					"day %d: '%s' is on a pavement with a kerb on one side" % [day, plan.def.id])
			if inward == Vector2i.ZERO:
				continue
			var beside := map.tile_at(tile - inward)
			t.check(beside == GameEnums.TileType.ROAD or beside == GameEnums.TileType.CROSSING,
					"day %d: '%s' has the carriageway on the other side of it (%d)"
					% [day, plan.def.id, beside])
	t.check(parked > 0, "and a run parks something (%d over 14 days)" % parked)

## Playtest 07, finding 15: *"the backing out lorry does not connect to the building making it
## hard to visually read."* The danger is the gap behind a wall of metal, so there has to be a
## wall — and it has to be east or west of it, because the silhouette is drawn side-on.
func _test_a_lorry_has_a_wall_to_back_into(t) -> void:
	var map := _map()
	var backing := 0
	for day in range(3, 15):
		for plan in _planned(day):
			if plan.def.pavement_side != EventDef.Pavement.AGAINST_THE_BUILDING:
				continue
			# A place the day owes her walk has no tile yet to have a frontage behind it — day 3's
			# fire is sited later, against the same `_wants_this_side` rule this asks about, and
			# where it lands is asked of a real walk in `tests/test_event_manager.gd`.
			if not plan.is_placed():
				continue
			backing += 1
			var tile := map.world_to_tile(plan.position)
			var inward := map.pavement_inward(tile)
			t.check(inward != Vector2i.ZERO and inward.y == 0,
					"day %d: '%s' backs into a frontage it can be drawn facing" % [day, plan.def.id])
			if inward == Vector2i.ZERO:
				continue
			t.check(map.tile_at(tile + inward) == GameEnums.TileType.BUILDING,
					"day %d: '%s' has a real building behind it" % [day, plan.def.id])
			# Facing *out* of the wall, so the box end is the end that is in the yard.
			t.check(plan.facing == -Vector2(inward),
					"day %d: '%s' is turned to reverse into it" % [day, plan.def.id])
	t.check(backing > 0, "and a run sites one (%d over days 3-14)" % backing)

## Playtest 11, finding 1: *"events/hazards should not spawn on the home block."* The home is a
## notch with one exit, so the walk from the doorstep to the first junction is the one stretch of
## a day she does not choose to be on — and a thing standing on it is a tax rather than a route
## decision. `ClosurePlanner` has refused to close that same street since M16, for the same reason.
##
## Measured before the exemption, eight seeds over days 1, 3, 7 and 14: **0.47 events a day** stood
## on it, which is one morning in two starting with something on the doorstep. The share is exactly
## the share of the pavement the street is (0.30% of both), which is placement being uniform and is
## why this needed a rule rather than a weighting.
##
## The last two checks are the ones that keep it from passing vacuously: an exemption over ground
## nothing could have stood on is not an exemption, and a day that stopped placing events would
## satisfy the first check perfectly.
func _test_nothing_stands_on_the_doorstep_street(t) -> void:
	var map := _map()
	var home := ClosurePlanner.home_street(map)
	t.check(home != null, "the front door opens onto a street")
	if not home:
		return
	var rect := home.tile_rect()
	var placed := 0
	for day in range(1, 15):
		for plan in _planned(day):
			if plan.position == Vector2.INF:
				continue   # an `AHEAD_OF_PLAYER` row, sited by the director while she walks
			placed += 1
			t.check(not rect.has_point(map.world_to_tile(plan.position)),
					"day %d: '%s' is not standing on the street she starts the day on"
					% [day, plan.def.id])

	var pavement := 0
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if rect.has_point(tile):
			pavement += 1
	t.check(pavement > 0,
			"and the exempt street is pavement something could otherwise have stood on (%d tiles)"
			% pavement)
	t.check(placed > 14, "and the days it was checked over still place events (%d)" % placed)

## `plan` as `[position.x, position.y, obstructs_radius]`, appended to `bodies` — or not, for the
## same two exemptions the rule and its own probe make: a `checkpoint_hut`/`checkpoint_gate` door
## body costs by design, and a `scenery` row has no ground to keep clear of.
func _add_a_physical_body(bodies: Array, plan: EventScheduler.Planned) -> void:
	if not plan.is_placed() or plan.def.obstructs_radius <= 0.0:
		return
	if plan.def.scenery or plan.def.id.begins_with("checkpoint"):
		return
	bodies.append(Vector3(plan.position.x, plan.position.y, plan.def.obstructs_radius))

## `docs/DECISIONS.md`, M100, "Events spawn inside a fully blocked street" and "Nothing on the home block":
## a catalogue placement is refused a candidate tile whose street segment is held today — a
## closure, a hard seal, a region wall or door, or a segment bordering the home block
## (`CityMap.held_segments`) — or that lies inside the home block's own lot
## (`CityMap.is_on_home_block`). Replicates `EventManager.start_day`'s own ordering: the seals and
## the region plan are known, and `held_segments` is filled, before `EventScheduler.build_day`
## rolls a single candidate.
##
## **And the fifth refusal, a standing street tree's own ground** (`docs/CITY.md`, "Street trees"):
## every catalogue placement and every seal body on these same full days is asked whether it stands
## on a tile `StreetTrees.footprint_tiles` covers. The seals are asked here rather than only in
## `tests/test_seals.gd` because they are the half that does **not** go through
## `EventScheduler._open_ground_for` — `SealPlanner._seal_along_tile` is a second implementation of
## one rule, and a day's plan is where the two have to agree. `fallen_tree` is the single exception
## and is excluded by name: it is the body that stands in a pit and empties it.
##
## **The seals' own bodies, the closure marker and the checkpoint rows are placed by their
## planners, not by the catalogue roll, so they are unaffected** — asserted by comparison rather
## than against a remembered count: the seals are planned twice on the same seeded stream, once
## with `SealPlanner.plan_day`'s `held` out-param wired in exactly as `EventManager.start_day`
## wires it and once without, and the two plans must be the same size, since `held` is written
## by the planner and read by nobody in it; closures, walls, doors and checkpoint bodies never
## read the holds at all, so they only have to exist across the sampled days (day 7 and day 10
## are in the sample for the regions). A remembered total would fail on every unrelated change to
## the generator — it did, twice, the day this was written — and say nothing about holds.
## **Two seeds and five days.** A (seed, day) here is the most expensive unit anywhere in this
## suite — a `RouteTree`, a region plan, a closure plan, two seal plans and a `build_day` — and
## what it proves is that five refusals inside `_open_ground_for` fire, which every single pair
## exercises over its whole day's worth of candidates. The days stay five rather than one because
## holds come from four different planners and each has its own first day (region walls from
## `REGION_WALL_FIRST_DAY`, closures from act I), so the sample has to span the acts; the seeds
## drop to two because the second is there to keep the sample from being one street plan and the
## third and fourth were asking the same question a third and fourth time.
func _test_nothing_the_catalogue_places_stands_on_held_ground(t) -> void:
	const SEEDS := 2
	const BASE_SEED := 314159
	const DAYS := [1, 4, 7, 10, 14]
	var total_closures := 0
	var total_boundary := 0
	var total_checkpoints := 0
	var total_seals := 0
	var checked := 0
	var checked_trees := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 137)
		for day in DAYS:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var region_plan := RegionPlanner.plan_day(map, day, tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree, region_plan)
			map.close_streets(closures)

			# The same population `EventManager.start_day` performs, before `build_day` runs.
			map.clear_day_holds()
			for closure in closures:
				map.hold_segment(closure.segment.key())
			for segment in region_plan.walls:
				map.hold_segment(segment.key())
			for segment in region_plan.doors:
				map.hold_segment(segment.key())
			for segment in StreetNetwork.around_blocks(Rect2i(map.home_block, Vector2i.ONE)):
				map.hold_segment(segment.key())

			var boundary := {}
			for segment in region_plan.walls:
				boundary[segment.key()] = true
			for segment in region_plan.doors:
				boundary[segment.key()] = true
			for rect in region_plan.alley_walls:
				boundary[rect.position] = true
			for rect in region_plan.alley_doors:
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			var seals := SealPlanner.plan_day(map, day, tree, seal_rng, boundary, map.held_segments)
			var unheld_rng := RandomNumberGenerator.new()
			unheld_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			var seals_unheld := SealPlanner.plan_day(map, day, tree, unheld_rng, boundary)
			t.check(seals.size() == seals_unheld.size(),
					"seed %d day %d: holding the hard seals' ground plans the same seals (%d vs %d)"
					% [map.seed_used, day, seals.size(), seals_unheld.size()])

			# **A tree and an event never share ground** — `docs/CITY.md`, "Street trees". Checked
			# over the same full days, against the tree footprints themselves rather than against
			# the pit tiles, since the refusal is stated over the ground the shadow reaches.
			var trees := StreetTrees.footprint_tiles(map)
			for seal in seals:
				if seal.def.id == "fallen_tree":
					continue   # the one body that stands in a pit, and empties it; see below
				var seal_tile := map.world_to_tile(seal.position)
				t.check(not trees.has(seal_tile),
						"seed %d day %d: seal '%s' stands in a street tree at %s"
						% [map.seed_used, day, seal.def.id, seal_tile])
				checked_trees += 1

			var consumed: Array[String] = []
			for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
				if not plan.is_placed():
					continue
				checked += 1
				var tile := map.world_to_tile(plan.position)
				t.check(not map.is_closed(tile),
						"seed %d day %d: '%s' does not stand on a closed tile"
						% [map.seed_used, day, plan.def.id])
				t.check(not map.is_held_at(tile),
						"seed %d day %d: '%s' does not stand on a held segment"
						% [map.seed_used, day, plan.def.id])
				t.check(not map.is_on_home_block(tile),
						"seed %d day %d: '%s' does not stand inside the home block"
						% [map.seed_used, day, plan.def.id])
				t.check(not trees.has(tile),
						"seed %d day %d: '%s' stands in a street tree at %s"
						% [map.seed_used, day, plan.def.id, tile])
				checked_trees += 1

			total_closures += closures.size()
			total_boundary += region_plan.walls.size() + region_plan.doors.size()
			total_checkpoints += region_plan.door_bodies.size()
			total_seals += seals.size()

	t.check(checked > 0, "the catalogue placed something to check across every sampled day (%d)"
			% checked)
	t.check(total_closures > 0, "the sampled days closed streets to hold (%d)" % total_closures)
	t.check(total_boundary > 0, "the sampled days had walls and doors to hold (%d)" % total_boundary)
	t.check(total_checkpoints > 0,
			"the sampled days stood checkpoint bodies on their doors (%d)" % total_checkpoints)
	t.check(total_seals > 0, "the sampled days sealed streets (%d)" % total_seals)
	t.check(checked_trees > 0,
			"and every one of those bodies was asked whether it stands in a tree (%d)"
			% checked_trees)

## **No solid body, alone or together, closes a walked sidewalk.** *(PLAYTEST-94, 2026-09-19: "I
## still get hard walls on the side of the sidewalk that is on the path -- how can this be so hard
## to do correctly?")* `tests/probes/m129_walked_sidewalk_walls.gd` measures the same question at
## zero over a wider sample; this asks it of `EventScheduler.closes_a_walked_sidewalk_band`
## directly, the one function both the probe and this test call, so neither can drift from what
## the other means by *closed*. Every solid body that day stands — the candidate loop's own rows,
## the seals, and the region wall's and doors' bodies, gathered the way
## `_test_nothing_the_catalogue_places_stands_on_held_ground` already assembles a full day — is
## checked cumulatively against every walked-sidewalk band, the way the width rule itself asks it.
##
## **Two seeds and three days, a quarter of the probe's own 24.** A (seed, day) here assembles the
## same expensive unit that test already prices at the suite's own budget — a tree, a region plan,
## closures, a seal plan and a `build_day` — so this asks one more question of it rather than
## building a second assembly; the probe is where the wider sample already lives if this suite's
## own finding ever needs a closer look.
func _test_no_body_closes_a_walked_sidewalk(t) -> void:
	const SEEDS := 2
	const BASE_SEED := 271828
	const DAYS := [1, 8, 13]
	var bands_checked := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 173)
		for day in DAYS:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var region_plan := RegionPlanner.plan_day(map, day, tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree, region_plan)
			map.close_streets(closures)

			map.clear_day_holds()
			for closure in closures:
				map.hold_segment(closure.segment.key())
			for segment in region_plan.walls:
				map.hold_segment(segment.key())
			for segment in region_plan.doors:
				map.hold_segment(segment.key())
			for segment in StreetNetwork.around_blocks(Rect2i(map.home_block, Vector2i.ONE)):
				map.hold_segment(segment.key())

			var boundary := {}
			for segment in region_plan.walls:
				boundary[segment.key()] = true
			for segment in region_plan.doors:
				boundary[segment.key()] = true
			for rect in region_plan.alley_walls:
				boundary[rect.position] = true
			for rect in region_plan.alley_doors:
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			var seals := SealPlanner.plan_day(map, day, tree, seal_rng, boundary, map.held_segments)

			var consumed: Array[String] = []
			var bodies: Array = []
			for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
				_add_a_physical_body(bodies, plan)
			for plan in seals:
				_add_a_physical_body(bodies, plan)
			for plan in region_plan.wall_bodies:
				_add_a_physical_body(bodies, plan)
			for plan in region_plan.door_bodies:
				_add_a_physical_body(bodies, plan)

			var corridor := Corridor.of(tree)
			var ground := {}
			for entry: Array in EventScheduler._route_sidewalks(map, ground, corridor):
				var segment: StreetNetwork.Segment = entry[0]
				var band: Rect2i = entry[1]
				bands_checked += 1
				t.check(not EventScheduler.closes_a_walked_sidewalk_band(
						map, band, segment.horizontal, bodies, map.closed_tiles),
						"seed %d day %d: street %s's walked sidewalk keeps a lane she fits through"
						% [map.seed_used, day, segment.key()])
	t.check(bands_checked > 50,
			"and the days sampled have walked-sidewalk bands to ask it of (%d)" % bands_checked)
