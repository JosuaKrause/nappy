extends RefCounted
## **The cases behind `test_crowd_closures_a.gd`, `_b.gd` and `_c.gd`; not a suite itself.** Each
## part runs the scenarios and the door-day cases it owns, so no suite runs two minutes serial; the
## three together make every check the one suite made.
## The crowd against a closed or shaped street: hard and soft seals, sealed junctions (pockets),
## region walls and their carved doors, bridges, tunnels and the map's own outer edges.
##
## Split from a single `test_crowd.gd` under M125 -- "the test suite is slow again" -- by
## subject rather than trimmed: this half is simulation-bound the same way the other half is, so
## nothing here shrinks for speed. It keeps everything about what a placed obstruction does to
## the crowd once the lattice underneath it stops being plain open street. `test_crowd_traffic.gd`, `_field.gd` and `_streets.gd` keep
## the crowd as ordinary traffic -- population, contact, and the street hierarchy.
##
## This runs against a real generated City, for the same reason `crowd_rig.gd` does: these
## failures are geometric and invisible to a data-level test.
##
## **Its cities come from the cache of generated cities** (`tests/city_map_cache.gd`): each
## seed's city is generated once in the test process and every case is handed a copy of its own,
## the same city `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0
## The rig of `test_crowd_bodies.gd`: agents placed on the street through `Crowd.add_recipe_actor()`.
const RIG := preload("res://tests/test_crowd_bodies.gd")

var _city: City
var _rig: RIG = RIG.new()

## The scenarios in the order the one suite ran them; each stands in a city of its own, built over
## a run of its own, so none leans on the closures, seals and days an earlier one left behind.
func scenarios() -> Array[Callable]:
	return [
		_test_a_hard_seal_shuts_its_street_to_the_crowd,
		_test_nobody_is_placed_in_a_sealed_junction,
		_test_a_pocket_empties_once_it_is_out_of_view,
		_test_a_walker_turns_into_a_street_sealed_further_along,
		_test_a_turn_around_commits_to_its_new_heading,
		_test_no_car_in_sight_ever_moves_further_than_it_drove,
		_test_a_soft_seal_shuts_both_pavements_to_walkers_only,
		_test_the_doorstep_street_is_not_shut_by_its_own_hold,
		_test_only_cars_go_over_the_bridge,
		_test_the_crowd_agrees_a_zone_absorbed_the_corridor,
		_test_agents_do_not_overrun_an_ordinary_edge,
		_test_out_of_bounds_is_blocked_except_a_car_on_the_spine,
		_test_cars_come_out_of_the_tunnel_and_off_the_bridge,
		_test_cars_do_not_drive_on_across_the_mountain,
		_test_spine_cars_are_put_out_of_sight,
		_test_nobody_enters_across_a_plain_edge,
		_test_the_entry_roll_is_kept_inside_its_own_room,
		_test_an_entry_beside_a_plain_edge_keeps_room_for_its_own_picture,
	]

## The scenarios of `scenarios()` at `indices`, in the order given.
func run_scenarios(t: TestRunner, indices: Array[int]) -> void:
	var all := scenarios()
	for index in indices:
		var scenario := all[index]
		_city = RunCity.with_own_run(CITY_SCENE, SEED)
		t.add_child(_city)
		_city.build(MapCache.of(SEED))
		scenario.call(t)
		_city.free()

func run_region_wall(t: TestRunner) -> void:
	_test_a_region_wall_is_shut_and_a_door_is_carved_out(t)

func run_day_start(t: TestRunner) -> void:
	_test_day_start_keeps_room_for_its_own_picture(t)

## One door day, shared: building a city and planning days until one carries a door, and every test
## below places its own bodies at the same hut anyway.
func run_door_day(t: TestRunner) -> void:
	var door_day := _open_a_door_day(t)
	_test_a_walker_is_held_at_a_door_in_four_states(t, door_day)
	_test_a_line_at_a_door_stays_short(t, door_day)
	_test_a_car_still_stops_for_the_boom(t, door_day)
	if not door_day.is_empty():
		var door_city: City = door_day["city"]
		door_city.free()

## Where a hard seal stands its bodies across `segment`: `SealPlanner.positions_across()` over the
## segment's whole cross-section, at the seal's own body radius, as the planner places a seal.
func _across(segment: StreetNetwork.Segment, def: EventDef) -> Array[Vector2]:
	return SealPlanner.positions_across(_city.map.tile_rect_to_world(segment.tile_rect()),
			segment.horizontal, def.obstructs_radius)

## One stride of `agent` in seconds at the fastest its kind goes: its strategy's stride length
## over the top of its kind's speed range.
func _stride_seconds(agent: CrowdAgent) -> float:
	return agent.lane().strategy().stride_length() / maxf(agent.lane().strategy().speed_range().y, 1.0)

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd:%d:%d" % [SEED, day])
	return rng

## Runs the crowd forward. Stepped by hand rather than by the tree, so a suite can cover a
## minute of traffic without waiting a minute -- but a whole frame of it, separation pass
## included, because a crowd without one is not the crowd the game runs. See `Crowd.step`.
func _advance(seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		_city.crowd.step(STEP)

# --------------------------------------------------------------- M110: seals ---
# "also I noticed that objects like fallen trees don't stop/redirect traffic or pedestrians"
# (playtest 55, 2026-09-10). `CrowdAgent.strategy.cannot_go_on` used to know about a closure and about
# nothing else that stands in a street, so a walker or a car passed straight through a hard seal,
# a region wall, or a soft seal's own bodies. The three tests below are the shape
# `_test_nothing_walks_into_a_hard_blocker` above already asks about the built-over kind, asked of
# the day's own placed seals instead — see `docs/DECISIONS.md`, M100, "Events spawn inside a fully
# blocked street", for `CityMap.held` itself, which these read rather than duplicate.

## M110, item 2, as M156 leaves it: a hard seal shuts its street to the **traffic**, and a walker
## walks up to the seal's own bodies and no further.
##
## **The two halves are read off two different records and that is the finding.** The hold on the
## segment is what turns a car, a junction early, because a car cannot turn round against a barrier;
## the seal's bodies in `CityMap.obstructed_tiles` are what stops a walker, where they stand.
## *(2026-09-19: "pedestrians should only avoid the area if they cannot reach it physically … they
## should only give up if they touch an impassable wall".)* So a car is asked about the whole
## segment and a walker only about the tiles the bodies are on — and the street is asked to carry
## walkers at all, since a sealed street with nobody on it was the complaint.
##
## The seal is stood here the way `SealPlanner` stands one — the same `sealed_variant` and the same
## `positions_across()` across the street — rather than by planning a day, so the segment under test is
## this one and not whatever the seed rolled.
func _test_a_hard_seal_shuts_its_street_to_the_crowd(t: TestRunner) -> void:
	var segment: StreetNetwork.Segment = null
	for candidate in _city.map.network.segments():
		if _city.map.has_street(candidate.key()):
			segment = candidate
			break
	t.check(segment != null, "this city has an ordinary street to seal")
	if not segment:
		return

	_city.map.clear_day_holds()
	_city.map.clear_day_obstructions()
	_city.map.hold_segment(segment.key(), HeldStreets.Why.SEAL)
	var def := SealPlanner.sealed_variant(EventCatalogue.by_id("fallen_tree"), true)
	var body_tiles := {}
	var owner := 1
	for at_body: Vector2 in _across(segment, def):
		var covered := EventSpawner.obstructed_footprint(_city.map, def, at_body, Vector2.RIGHT)
		_city.map.obstruct_tiles(owner, covered)
		owner += 1
		for tile: Vector2i in covered:
			body_tiles[tile] = true
	t.check(body_tiles.size() >= Tuning.STREET_WIDTH,
			"the seal's bodies stand across the whole street (%d tiles)" % body_tiles.size())

	var rect := segment.tile_rect()
	var at := _city.map.tile_rect_to_world(rect).get_center()
	_city.crowd.start_day(1, _rng(1), at)

	var in_the_bodies := 0
	var cars_on_the_street := 0
	var walkers_on_the_street := 0
	for frame in int(round(20.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent: CrowdAgent in _city.crowd.agents():
			var tile := _city.map.world_to_tile(agent.position)
			if body_tiles.has(tile):
				in_the_bodies += 1
			if not rect.has_point(tile):
				continue
			if agent.lane().kind() == CrowdAgent.Kind.CAR:
				cars_on_the_street += 1
			else:
				walkers_on_the_street += 1
	t.check(in_the_bodies == 0,
			"nobody ever stands inside the seal's own bodies (%d frames somebody did)"
			% in_the_bodies)
	t.check(cars_on_the_street == 0,
			"and the sealed street carries no traffic at all (%d car-frames it did)"
			% cars_on_the_street)
	t.check(walkers_on_the_street > 0,
			"while people still walk it up to the seal (%d walker-frames)" % walkers_on_the_street)

	_city.map.clear_day_holds()
	_city.map.clear_day_obstructions()

# ------------------------------------------------------------- M119: pockets ---
# "pedestrians with nowhere to go (all four sides of the intersection are blocked off) should just
# despawn (or never spawn in the first place) right now they're accumulating in one place and move
# back and forth or worth flicker … the same with cars" (playtest 66, 2026-09-12). A junction whose
# every arm is held is a **pocket** to a *car*: roadway with no street out of it, and a car cannot
# turn round against a barrier. The three tests below are the three parts of the answer — no car is
# put in one, a car in one stands exactly where the seal caught it and leaves once nobody is
# watching, and an about-face still costs a stride wherever an agent is trapped on ground that is
# not itself a pocket.
#
# **The same ground carries walkers, and that is the 2026-09-19 correction to the reading above.**
# *("the pacing back and forth I complained about was because walkers never actually tried walking
# to the edge … they should still go into the section until they cannot continue.")* A person turns
# round in a stride, so a sealed-off crossing is somewhere to walk into, down each stub to the
# barrier on the end of it and back — which is what the first test asks for now, in the same breath
# as asking that no car is there.

## M119, item 1, as M156 leaves it: no car is placed inside a junction sealed on every side, on the
## morning or on any recycle after it — and the walkers are in there walking.
func _test_nobody_is_placed_in_a_sealed_junction(t: TestRunner) -> void:
	var sealed := _a_junction_to_seal(t)
	if sealed.is_empty():
		return
	var rect: Rect2i = sealed["rect"]
	var at: Vector2 = sealed["at"]
	_city.map.clear_day_holds()
	for arm: StreetNetwork.Segment in sealed["arms"]:
		_city.map.hold_segment(arm.key(), HeldStreets.Why.SEAL)
	_city.crowd.start_day(1, _rng(1), at)
	_city.crowd.set_focus(at)

	var pockets := _city.crowd.pockets()
	# The guard against a vacuous sweep: "no car stands in a pocket" passes on its own where the
	# seals made no pocket at all.
	t.check(pockets.tile_count() > 0,
			"sealing every arm of a junction pockets roadway (%d tiles)" % pockets.tile_count())
	t.check(pockets.holds(rect.get_center()),
			"and the junction box itself is inside the pocket")

	var cars_inside := 0
	var walkers_sealed_in := 0
	var arm_rects: Array[Rect2i] = []
	for arm: StreetNetwork.Segment in sealed["arms"]:
		arm_rects.append(arm.tile_rect())
	for agent: CrowdAgent in _city.crowd.agents():
		var tile := _city.map.world_to_tile(agent.position)
		if agent.lane().kind() == CrowdAgent.Kind.CAR and rect.has_point(tile):
			cars_inside += 1
		elif agent.lane().kind() == CrowdAgent.Kind.WALKER and _on_any_rect(arm_rects, tile):
			walkers_sealed_in += 1
	t.check(cars_inside == 0, "no car is placed inside it on the morning (%d were)" % cars_inside)
	# Placement treats sealed-in ground like any other street: "they should be able to spawn inside
	# a closed off section but shouldn't stand in one place".
	t.check(walkers_sealed_in > 0,
			"and the morning places walkers on the sealed-off arms like any street (%d of them)"
			% walkers_sealed_in)

	var car_frames := 0
	var walkers_moving := 0
	var walker_positions := {}
	for frame in int(round(20.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent: CrowdAgent in _city.crowd.agents():
			if not rect.has_point(_city.map.world_to_tile(agent.position)):
				continue
			if agent.lane().kind() == CrowdAgent.Kind.CAR:
				car_frames += 1
				continue
			var id := agent.get_instance_id()
			if walker_positions.has(id) \
					and agent.position.distance_to(walker_positions[id]) > 0.1:
				walkers_moving += 1
			walker_positions[id] = agent.position
	t.check(car_frames == 0,
			("and no car is recycled into it over twenty seconds of the field sitting on it "
			+ "(%d car-frames inside)") % car_frames)
	# The other half, and the one the 2026-09-19 correction asks for: the sealed crossing is not
	# empty, and nobody in it is standing still. Frames rather than bodies, because a walker leaves
	# by walking out of the box the way it walked in.
	t.check(walkers_moving > 0,
			"while walkers walk through the sealed crossing (%d walker-frames of movement in it)"
			% walkers_moving)

	_city.map.clear_day_holds()

## M119, item 2: a car sealed in leaves — but not while she is looking at it. And while she is
## looking, it stands rather than pacing (M146, "a pocketed agent stands, then leaves unseen" —
## the player's own *"it looks very weird otherwise"* about the pacing this replaces).
##
## The crowd is placed first and the seals go up under it, which is the one case a placement cannot
## prevent and is also the only way to get a car into a pocket now that `setup()` refuses to.
##
## **Cars only, because there is no walker pocket**: a walker caught by the same seals walks the
## stubs and turns at the barrier on the end of each, which is the test above.
func _test_a_pocket_empties_once_it_is_out_of_view(t: TestRunner) -> void:
	var sealed := _a_junction_to_seal(t)
	if sealed.is_empty():
		return
	var rect: Rect2i = sealed["rect"]
	var at: Vector2 = sealed["at"]
	_city.map.clear_day_holds()
	_city.crowd.start_day(1, _rng(2), at)
	_advance_watching(4.0, at)
	for arm: StreetNetwork.Segment in sealed["arms"]:
		_city.map.hold_segment(arm.key(), HeldStreets.Why.SEAL)
	_city.crowd.step(STEP)

	var watched := _inside(rect, CrowdAgent.Kind.CAR)
	t.check(watched > 0,
			"there were cars standing in the junction when it was sealed (%d)" % watched)
	# Positions recorded here, right after the seal and one crowd step, and compared once more
	# below after the whole watch — a standing body's position is what M146 asks for, not merely
	# that the count holds, which a body pacing the box from one seal to the other would pass too.
	var standing_at := {}
	for agent: CrowdAgent in _city.crowd.agents():
		if agent.lane().kind() == CrowdAgent.Kind.CAR \
				and rect.has_point(_city.map.world_to_tile(agent.position)):
			standing_at[agent.get_instance_id()] = agent.position
	var lowest := watched
	for frame in int(round(3.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		lowest = mini(lowest, _inside(rect, CrowdAgent.Kind.CAR))
	t.check(lowest == watched,
			("no car sealed into it disappears while the view is on it — %d were there and the "
			+ "count never fell below %d") % [watched, lowest])

	var moved := 0
	for agent: CrowdAgent in _city.crowd.agents():
		var id := agent.get_instance_id()
		if standing_at.has(id) and agent.position.distance_to(standing_at[id]) > 1.0:
			moved += 1
	t.check(moved == 0,
			("and every one of the %d cars caught in it stands within a pixel of where the seal "
			+ "caught it across the watched seconds (%d moved further than that)")
			% [standing_at.size(), moved])

	# Far enough that the junction is off camera (`Tuning.OUT_OF_SIGHT`, 420px) and well inside the
	# crowd's own box (`CROWD_FIELD_RADIUS`, 800px), so what empties it is the pocket rule and not
	# the field's ordinary edge. Pointed at the middle of the map so the box does not hang over the
	# boundary.
	var inward := signf(_city.map.world_size().x * 0.5 - at.x)
	var away := at + Vector2(620.0 * (inward if inward != 0.0 else 1.0), 0.0)
	for frame in int(round(3.0 / STEP)):
		_city.crowd.set_focus(away)
		_city.crowd.step(STEP)
	t.check(_inside(rect, CrowdAgent.Kind.CAR) == 0,
			"and every one of them is gone once the view has moved off it (%d left)"
			% _inside(rect, CrowdAgent.Kind.CAR))

	_city.map.clear_day_holds()

## M156: a walker turns into a street that is sealed further along, rather than reading it as shut
## from the junction. *(2026-09-19: "they should still go into the section until they cannot
## continue. this should also happen from inside the path since right now we have offshoots that are
## clear because nobody attempts to go in".)*
##
## **One arm, not four**, so the junction itself stays open and the crowd walks through it the way
## it walks through any junction — what is being asked is whether anybody turns *into* the sealed
## arm, which a pocketed crossing would not answer.
##
## **Counted as an entry rather than as presence**, because placement also puts walkers on sealed-in
## ground now (the test above) and a count of who is standing there cannot tell the two apart. A
## walker counts once it has been seen outside the arm and is then seen inside it.
func _test_a_walker_turns_into_a_street_sealed_further_along(t: TestRunner) -> void:
	var sealed := _a_junction_to_seal(t)
	if sealed.is_empty():
		return
	var arms: Array = sealed["arms"]
	var arm: StreetNetwork.Segment = arms[0]
	var at: Vector2 = sealed["at"]
	_city.map.clear_day_holds()
	_city.map.clear_day_obstructions()
	_city.map.hold_segment(arm.key(), HeldStreets.Why.SEAL)
	var def := SealPlanner.sealed_variant(EventCatalogue.by_id("fallen_tree"), true)
	var owner := 1
	for at_body: Vector2 in _across(arm, def):
		_city.map.obstruct_tiles(owner, EventSpawner.obstructed_footprint(_city.map, def, at_body,
				Vector2.RIGHT))
		owner += 1
	_city.crowd.start_day(1, _rng(4), at)

	var arm_rect := arm.tile_rect()
	var seen_outside := {}
	var entered := 0
	for frame in int(round(20.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent: CrowdAgent in _city.crowd.agents():
			if agent.lane().kind() != CrowdAgent.Kind.WALKER:
				continue
			var id := agent.get_instance_id()
			if not arm_rect.has_point(_city.map.world_to_tile(agent.position)):
				seen_outside[id] = true
			elif seen_outside.has(id):
				entered += 1
				seen_outside.erase(id)
	t.check(entered > 0,
			"walkers turn into a street that is sealed further along (%d of them walked in)"
			% entered)

	_city.map.clear_day_holds()
	_city.map.clear_day_obstructions()

## M119, item 3: an about-face commits to its new heading for a stride, so a body with a seal at
## each end of it paces rather than facing two ways at sixty frames a second — still true wherever
## an agent is already standing on ground that becomes shut at both ends, which the arms of this
## same sealed junction still are.
##
## **Asked on the arms rather than in the box.** The box itself is a pocket to a car once all four
## arms are held (`CrowdPockets`), and a pocketed car stands rather than reversing — that is the
## whole of M146, "a pocketed agent stands, then leaves unseen". Each arm's own segment is held in
## full, both ends, and is not pocketed ground, so whoever is walking or driving one finds the way
## ahead **and** the way behind shut and reverses — which is the single-seal-on-open-ground case
## this milestone leaves standing, and the one the stride is measured against.
##
## The floor is each agent's own stride (`stride_length()`) over the fastest its kind goes
## (`speed_range()`) rather than a number, so it survives any rebalancing of walking speed or of the
## gait — what it pins is that a reversal is worth a stride, not that a stride is 35px.
func _test_a_turn_around_commits_to_its_new_heading(t: TestRunner) -> void:
	var sealed := _a_junction_to_seal(t)
	if sealed.is_empty():
		return
	var at: Vector2 = sealed["at"]
	var arm_rects: Array[Rect2i] = []
	for arm: StreetNetwork.Segment in sealed["arms"]:
		arm_rects.append(arm.tile_rect())
	_city.map.clear_day_holds()
	_city.crowd.start_day(1, _rng(3), at)
	_advance_watching(3.0, at)
	for arm: StreetNetwork.Segment in sealed["arms"]:
		_city.map.hold_segment(arm.key(), HeldStreets.Why.SEAL)

	var facing := {}
	var since := {}
	var turning := {}
	var reversals := 0
	var too_soon := 0
	var soonest := INF
	for frame in int(round(8.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent: CrowdAgent in _city.crowd.agents():
			var id := agent.get_instance_id()
			var heading := agent.heading()
			# `INF` until this agent has actually been seen to turn round once: the first about-face
			# of the run says nothing, since whatever came before it happened before the measurement
			# started.
			since[id] = float(since.get(id, INF)) + STEP
			# A car coming off an arc reverses its heading over the whole length of that arc, which
			# is M111's own manoeuvre and the opposite of the thing being measured. It is the only
			# other way a heading flips on one axis.
			var landed: bool = bool(turning.get(id, false)) and not agent.is_turning()
			turning[id] = agent.is_turning()
			# Only the bodies actually standing on one of the four now-shut arms are counted.
			# Everybody else is subject to a recycle, which is a teleport into a fresh lane and a
			# fresh direction at the far edge of the field — a reading about a different person
			# rather than an about-face. Their clock keeps running rather than being restarted,
			# because an agent that walks onto a shut arm and turns round a moment later has still
			# only turned round once; a recycled one cannot walk the eight hundred pixels back
			# inside this measurement, so it never returns to be miscounted.
			if landed or not _on_any_rect(arm_rects, _city.map.world_to_tile(agent.position)):
				facing[id] = heading
				continue
			var before: Vector2 = facing.get(id, heading)
			facing[id] = heading
			# An about-face only: a turn at a junction swaps the axis, which is a different decision
			# with nothing here to say about it. The clock is **not** restarted for one, because what
			# is being measured is the gap between two about-faces and a turn in between is not a
			# reason to allow the second one sooner.
			if not before.is_equal_approx(-heading):
				continue
			reversals += 1
			var waited: float = since[id]
			since[id] = 0.0
			# A whole frame of slack: the stride is run down by `delta` and the reversal is taken on
			# the frame after it reaches zero.
			if waited < _stride_seconds(agent) - STEP:
				too_soon += 1
				soonest = minf(soonest, waited)
	t.check(reversals > 0, "the sealed junction turns somebody round to ask about (%d reversals)"
			% reversals)
	t.check(too_soon == 0,
			("no agent reverses twice inside one of its own strides (%d of %d did, the quickest "
			+ "after %.3fs)") % [too_soon, reversals, 0.0 if soonest == INF else soonest])

	_city.map.clear_day_holds()

# ------------------------------------------------- M152: no teleport in sight ---
# "cars are super buggy now. when they turn in the final stretch the teleport a car length somewhere
# else. also in some case instead of routing a turn (or u turn) they just teleport" (playtest 76,
# 2026-09-15). A recycle is a teleport by construction and the design allows exactly one of them —
# the one nobody can see. Everything else that moves a car further than it drove is a placement
# repairing something after the fact, and the place that did it was the end of a turn.

## How far a car may move in one frame and still have driven there: twice the fastest car's own
## step, so the cross-steer (`CrowdAgent.STEER_SPEED`) and the separation pass's ordinary few pixels
## are both comfortably inside it and nothing but a *placement* clears it. The same bound
## `tests/probes/m152_car_jumps.gd` measures the whole city with.
static func _drivable_step() -> float:
	return 2.0 * Tuning.CAR_SPEED.y * STEP

## The play viewport around the field's centre — 1280x720 design pixels at the play zoom of 2, which
## is `Tuning.VIEW_HALF_EXTENT` of world either way. `CrowdField.centre` is the camera, which is what
## `CrowdAgent._out_of_view()` already measures against, and `Tuning.OUT_OF_SIGHT` (420px) is the
## radius outside this box's own far corner (367px) — so a legal recycle is always outside it.
func _on_screen(at: Vector2, focus: Vector2) -> bool:
	var offset := at - focus
	return absf(offset.x) <= Tuning.VIEW_HALF_EXTENT.x \
			and absf(offset.y) <= Tuning.VIEW_HALF_EXTENT.y

## M152: **a car the player can see never moves further than it drove.**
##
## A day with a seal the traffic reaches, so cars actually turn: one arm of a four-armed junction is
## held while the crowd is already on the road, which is what makes every car coming down that
## street plan an arc, an about-face or a turnaround at the junction — and the view is held on that
## junction throughout, so the turns happen in front of the camera.
##
## **What this is for is the end of a turn.** A landing whose booked spot has been closed up on from
## behind used to be dropped a gap behind the *rearmost* car in the whole exit lane — the merge a
## recycled car makes at the entry band, where further back is more off-screen road, applied at a
## junction where further back is most of a street. See `CarStrategy._land_the_turn()`.
##
## **Every landing in the window is contended, and waiting for one is what does not work.** The
## follower that closes up on a booked landing is rare — it needs a brake that has undershot by a
## few pixels at the exact moment an arc ends — so a plain twenty-second watch reports a clean bill
## of health on a build that teleports, which is the one failure a test like this must not have.
## What the follower *is*, to the landing, is an entry in `TrafficIndex` just behind the spot, so the
## rig puts one there itself: every frame, for every car on an arc, half a `Tuning.CAR_GAP_MIN`
## behind wherever that arc ends. The booking is still the entry nearest the landing, so
## `TrafficIndex.give_back()` still takes the right one back — what changes is that the arrival then
## finds the spot occupied, which is exactly the state the retreat fired in.
##
## **The morning is deliberately outside the window.** The crowd is placed without consulting itself
## and the first separation pass unpacks it, which is the one large correction that is right — so the
## watch starts after the crowd has settled, which is also when the seal goes up.
##
## Two guards against a vacuous sweep, because "nothing jumped" passes on its own where nothing was
## on screen and nothing turned: the agent-frames actually inside the viewport are counted, and so
## are the contended turns that actually ended in front of the camera.
func _test_no_car_in_sight_ever_moves_further_than_it_drove(t: TestRunner) -> void:
	var sealed := _a_junction_to_seal(t)
	if sealed.is_empty():
		return
	var at: Vector2 = sealed["at"]
	var arms: Array = sealed["arms"]
	_city.map.clear_day_holds()
	var traffic := TrafficIndex.new()
	_city.crowd.use_traffic(traffic)
	_city.crowd.start_day(1, _rng(4), at)
	_advance_watching(3.0, at)
	# **One arm, and the count matters in both directions.** Holding every arm is what the pocket
	# tests above want and it is useless here: the traffic is then held off the whole junction and
	# its four approaches, which is the entire viewport, so there is nothing on screen left to watch
	# at all. Holding two empties enough of it that the turns that do happen land off screen, which
	# the second guard below catches. One shut street leaves the box full of cars and puts the turns
	# it forces in front of the camera.
	var shut: StreetNetwork.Segment = arms[0]
	_city.map.hold_segment(shut.key(), HeldStreets.Why.SEAL)

	var watched_frames := 0
	var landings := 0
	var landings_in_sight := 0
	var jumps := 0
	var worst := 0.0
	var worst_line := ""
	var before := {}
	for frame in int(round(30.0 / STEP)):
		before.clear()
		for agent: CrowdAgent in _city.crowd.agents():
			if agent.lane().kind() == CrowdAgent.Kind.CAR:
				before[agent.get_instance_id()] = [agent.position, agent.is_turning()]
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		# After the step, because `Crowd.space_out_the_traffic()` rebuilds the index at the end of one
		# and a claim only has to outlive the frame it was made in — so this is the follower the next
		# frame's landing sees. See `TrafficIndex.claim()`.
		for agent: CrowdAgent in _city.crowd.agents():
			if agent.is_turning():
				traffic.claim(agent.turn_lane_key(),
						agent.turn_landing() - Tuning.CAR_GAP_MIN * 0.5)
		for agent: CrowdAgent in _city.crowd.agents():
			var was: Array = before.get(agent.get_instance_id(), [])
			if was.is_empty():
				continue
			var from: Vector2 = was[0]
			var seen := _on_screen(from, at) or _on_screen(agent.position, at)
			if bool(was[1]) and not agent.is_turning():
				landings += 1
				if seen:
					landings_in_sight += 1
			if seen:
				watched_frames += 1
			var moved := from.distance_to(agent.position)
			if not seen or moved <= _drivable_step():
				continue
			jumps += 1
			if moved > worst:
				worst = moved
				worst_line = "%.0fpx, %s -> %s" % [moved, from, agent.position]

	t.check(watched_frames > 0,
			"there were cars on screen to watch at the sealed junction (%d car-frames)"
			% watched_frames)
	t.check(landings_in_sight > 0,
			("and contended turns actually ended in front of the camera, which is the case the bound "
			+ "is for (%d of %d landings were on screen)") % [landings_in_sight, landings])
	t.check(jumps == 0,
			("no car in sight ever moves further than %.1fpx in a frame, which is further than it "
			+ "could have driven (%d did over %d car-frames on screen; worst %s)")
			% [_drivable_step(), jumps, watched_frames,
			"none" if worst_line == "" else worst_line])

	_city.map.clear_day_holds()

## Whether a tile falls inside any of a handful of tile rects — the four arms of a sealed junction,
## asked once per agent per frame rather than folded into one `Rect2i` union, since arms on
## opposite sides of a junction do not share an axis.
func _on_any_rect(rects: Array[Rect2i], tile: Vector2i) -> bool:
	for rect in rects:
		if rect.has_point(tile):
			return true
	return false

## How many agents are standing inside a tile rect right now, of one kind or of both.
func _inside(rect: Rect2i, kind := -1) -> int:
	var count := 0
	for agent: CrowdAgent in _city.crowd.agents():
		if kind >= 0 and agent.lane().kind() != kind:
			continue
		if rect.has_point(_city.map.world_to_tile(agent.position)):
			count += 1
	return count

## Runs the crowd with the view held on one spot, which is what a rig has instead of a player: the
## field's centre is where the camera is. See `CrowdAgent._out_of_view()`.
func _advance_watching(seconds: float, at: Vector2) -> void:
	for i in int(round(seconds / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)

## One ordinary junction to seal: its four arms, its own box as a tile rect, and the centre of that
## box in world coordinates.
##
## Picked rather than taken: a junction on the spine has the tunnel and the bridge past the end of
## it, one bordering the home block has a carve-out on one arm, and one on a precinct's own corridor
## is not ground a car may be on in the first place — none of the three is the plain four-armed
## crossroads the finding is about. Empty, with a failed check, where this city has none.
func _a_junction_to_seal(t: TestRunner) -> Dictionary:
	var home := {}
	for segment in _city.map.network.around_blocks(Rect2i(_city.map.home_block, Vector2i.ONE)):
		home[segment.key()] = true
	var count := StreetNetwork.junction_count()
	for y in range(1, count.y - 1):
		for x in range(1, count.x - 1):
			var junction := Vector2i(x, y)
			if junction.x == _city.map.main_road:
				continue
			var arms := _city.map.network.at_junction(junction)
			if arms.size() != 4:
				continue
			var ordinary := true
			for arm in arms:
				if not _city.map.has_street(arm.key()) or home.has(arm.key()):
					ordinary = false
					break
			if not ordinary:
				continue
			var rect := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
			var centre := rect.get_center()
			if not _city.map.is_street(centre) or not _city.map.is_driveable_at(true, centre):
				continue
			return {"arms": arms, "rect": rect,
					"at": _city.map.tile_rect_to_world(rect).get_center()}
	t.check(false, "this city has a plain four-armed junction to seal")
	return {}

## M110, item 1: a region wall is shut to the crowd the way a hard seal is, and a region door is
## carved out of the same check — a car still brakes and queues for the gate
## (`Crowd._stop_for_gates()`, built for M62) and a walker still passes the hut, rather than either
## turning away at the last junction. Driven off a real day (`City.start_day` then
## `EventManager.start_day`), the only way to get an actual `RegionPlanner.RegionPlan` with real
## wall and door segments on it, over however many sampled days it takes this seed's tree to cross
## its own boundary at least once.
func _test_a_region_wall_is_shut_and_a_door_is_carved_out(t: TestRunner) -> void:
	var map := MapCache.of(SEED)
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(city)
	city.build(map)

	var wall_segment: StreetNetwork.Segment = null
	var door_segment: StreetNetwork.Segment = null
	var used_day := -1
	for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		var closures_rng := RandomNumberGenerator.new()
		closures_rng.seed = hash("crowd-wall-closures:%d:%d" % [SEED, day])
		city.start_day(state, day, closures_rng)
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = hash("crowd-wall-events:%d:%d" % [SEED, day])
		var consumed: Array[String] = []
		city.events.start_day(DaySpec.for_day(day), events_rng, consumed)
		var plan := city.streets().region_plan()
		if not plan.walls.is_empty() and not plan.doors.is_empty():
			wall_segment = plan.walls[0]
			door_segment = plan.doors[0]
			used_day = day
			break
	t.check(wall_segment != null and door_segment != null,
			"at least one sampled day carries both a wall segment and a door segment")
	if not wall_segment or not door_segment:
		city.free()
		return

	var wall_rect := wall_segment.tile_rect()
	# Focused on the wall's own mouth — where its bodies actually stand, one tile deep — rather
	# than the middle of the whole segment: a field centred on the full length of a long held
	# segment can leave a corridor with almost no open ground anywhere in view, which is a field
	# placement nothing in `setup()`'s own retry budget promises to solve and not the property this
	# test is about. `_test_nothing_walks_into_a_hard_blocker` above stands at a dead end's own
	# (much shorter) rect for the same reason and the same way.
	var default_at_a := RegionPlanner.region_of_junction(map, wall_segment.a) \
			< RegionPlanner.region_of_junction(map, wall_segment.b)
	var at_a: bool = map.boundary_wall_at_a.get(wall_segment.key(), default_at_a)
	var mouth := wall_segment.mouth_rect(at_a)
	var at := map.tile_rect_to_world(mouth).get_center()
	city.crowd.start_day(used_day, _rng(used_day), at)
	city.crowd.set_gates(city.streets().region_plan().gates)

	var frames_inside := 0
	var walkers_on_the_segment := 0
	for frame in int(round(20.0 / STEP)):
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		for agent: CrowdAgent in city.crowd.agents():
			var tile := map.world_to_tile(agent.position)
			if mouth.has_point(tile):
				frames_inside += 1
			elif agent.lane().kind() == CrowdAgent.Kind.WALKER and wall_rect.has_point(tile):
				walkers_on_the_segment += 1
	# The **mouth** rather than the whole segment: the wall's bodies stand one tile deep across the
	# street there, and the rest of the segment is ordinary pavement a walker may now walk right up
	# to the wall along. What stops it is the bodies, which is the same sentence the hard-seal test
	# above holds.
	t.check(frames_inside == 0,
			"nobody ever stands on today's region wall itself (%d frames it did)" % frames_inside)
	t.check(walkers_on_the_segment > 0,
			"and the street it stands in still carries people up to it (%d walker-frames)"
			% walkers_on_the_segment)

	# The door carve-out, checked directly against the predicate rather than by waiting for a
	# random walker or car to wander onto the exact tile inside a short simulated window — the
	# question is whether `LaneStrategy.cannot_go_on()` refuses the door, not whether the day's population
	# happens to visit it.
	var door_tile := door_segment.tile_rect().get_center()
	var vertical := not door_segment.horizontal
	city.crowd.clear()
	var walker: CrowdAgent = _rig.any_agent(city.crowd, map, CrowdAgent.Kind.WALKER, _rig.seed_for_door_answer(WalkerStrategy.DoorAnswer.HELD))
	var car: CrowdAgent = _rig.any_agent(city.crowd, map, CrowdAgent.Kind.CAR)
	# One whose answer at a door is to turn back: the first roll of its seed gives it.
	var turner: CrowdAgent = _rig.any_agent(city.crowd, map, CrowdAgent.Kind.WALKER,
			_rig.seed_for_door_answer(WalkerStrategy.DoorAnswer.TURNS_BACK))
	t.check(walker != null and car != null and turner != null,
			"the crowd takes a walker, a car and a walker that turns back on some open street")
	if walker == null or car == null or turner == null:
		city.free()
		return
	map.hold_segment(door_segment.key(), HeldStreets.Why.DOOR)
	t.check(not walker.lane().strategy().cannot_go_on(vertical, door_tile),
			"a walker is not turned away from today's region door")
	t.check(not car.lane().strategy().cannot_go_on(vertical, door_tile),
			"and neither is a car — it brakes and queues for the gate instead of diverting")
	# And the carve-out is the walker's own rather than the day's: one whose answer at a door is to
	# turn back sees the same tile as wall, which is the whole of turning back — the machinery that
	# turns it at the last junction is the one a wall already uses.
	t.check(turner.lane().strategy().cannot_go_on(vertical, door_tile),
			"a walker that turns back at doors reads today's door as wall")
	city.free()

## A city, a day whose region wall has an open door in it, and an **empty** crowd centred on that
## door's mouth — the rig the walker-at-a-door tests below drive.
##
## Emptied on purpose. The day's own two hundred walkers are exactly what makes a queue at a door
## unrepeatable, and every property here is about *which* walker is let in and *when*; the agents
## put back are placed by hand, one at a time, on the lane the hut stands beside. `start_day` still
## runs first, because that is what builds the day's huts out of the region plan.
func _open_a_door_day(t: TestRunner) -> Dictionary:
	var map := MapCache.of(SEED)
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(city)
	city.build(map)
	var door: StreetNetwork.Segment = null
	var used_day := -1
	for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		var closures_rng := RandomNumberGenerator.new()
		closures_rng.seed = hash("crowd-door-closures:%d:%d" % [SEED, day])
		city.start_day(state, day, closures_rng)
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = hash("crowd-door-events:%d:%d" % [SEED, day])
		var consumed: Array[String] = []
		city.events.start_day(DaySpec.for_day(day), events_rng, consumed)
		if not city.streets().region_plan().doors.is_empty():
			door = city.streets().region_plan().doors[0]
			used_day = day
			break
	t.check(door != null, "a sampled day carries a region door for the crowd to cross")
	if not door:
		city.free()
		return {}
	var default_at_a := RegionPlanner.region_of_junction(map, door.a) \
			< RegionPlanner.region_of_junction(map, door.b)
	var at_a: bool = map.boundary_wall_at_a.get(door.key(), default_at_a)
	var mouth := map.tile_rect_to_world(door.mouth_rect(at_a))
	city.crowd.start_day(used_day, _rng(used_day), mouth.get_center())
	city.crowd.set_gates(city.streets().region_plan().gates)
	city.crowd.clear()

	var vertical := not door.horizontal
	var scene := {"city": city, "map": map, "day": used_day, "door": door, "at_a": at_a,
			"vertical": vertical, "mouth": mouth}
	# The huts are the day's detaining door bodies on the sidewalks (the plan's `door_bodies`), and
	# each one's hold is what a walker walking at it is handed (`door_ahead`): a probe walker is set
	# walking at each and the hold read off it after one frame.
	var huts: Array[WalkerDoorHold] = []
	for body in city.streets().region_plan().door_bodies:
		if body.def.detain_seconds <= 0.0 or not mouth.has_point(body.position):
			continue
		var across: float = body.position.x if vertical else body.position.y
		if CityMap.is_road_offset(
				CityMap.corridor_offset(floori(across / float(Tuning.TILE_SIZE)))):
			continue    # the boom over the roadway, which is the cars' own
		var probe := _walker_approaching(scene, body.position, 160.0,
				WalkerStrategy.DoorAnswer.PASSES)
		city.crowd.step(STEP)
		if probe.lane().door_ahead() != null:
			huts.append(probe.lane().door_ahead())
		city.crowd.clear()
	t.check(huts.size() == 2, "the door stands a hut on each of its two sidewalks (%d)"
			% huts.size())
	scene["huts"] = huts
	return scene

## Puts a walker on the sidewalk lane the hut at `hut_at` stands beside, `back` px short of it and walking at it,
## with the answer it is to have at the door. Added to the day's own (emptied) crowd, so
## `Crowd.step()` walks it exactly as it walks anybody.
func _walker_approaching(scene: Dictionary, hut_at: Vector2, back: float,
		answer: int, inward := false) -> CrowdAgent:
	var city: City = scene["city"]
	var map: CityMap = scene["map"]
	var vertical: bool = scene["vertical"]
	var hut_across: float = hut_at.x if vertical else hut_at.y
	var hut_along: float = hut_at.y if vertical else hut_at.x
	var corridor := CrowdLanes.corridor_at(hut_across)
	var lane := CrowdLanes.nearest_sidewalk(corridor, hut_across)
	# Toward the mouth from inside the door's own segment, whichever end the mouth is at.
	var direction := -1.0 if scene["at_a"] else 1.0
	if inward:
		direction = -direction
	var centre := CrowdLanes.walker_lane_centre(corridor, lane, CrowdLanes.SIDEWALK_OFFSETS)
	var along := hut_along - direction * back
	var heading := Vector2(0.0, direction) if vertical else Vector2(direction, 0.0)
	# The entry a task scene's pinned actor takes (`Crowd.add_recipe_actor()`); the seed is one whose
	# first roll gives the walker the answer it is to have at the door.
	var placed := city.crowd.add_recipe_actor("walker-%d" % city.crowd.agent_count(),
			CrowdAgent.Kind.WALKER, Vector2(centre, along) if vertical else Vector2(along, centre),
			heading, 60.0, _rig.seed_for_door_answer(answer))
	assert(placed["error"] == "", "the walker is placed: %s" % placed["error"])
	return placed["actor"]

## How far past a hut a walker has got, along its own line of travel: negative while it is still
## coming, positive once it is through.
func _past_the_hut(agent: CrowdAgent, hut: WalkerDoorHold) -> float:
	return (agent.global_position - hut.stands_at()).dot(agent.heading())

## M110, the last item: a walker held at a door goes through the player's four states in order —
## *("walking -> waiting -> inspection -> emerging on the other side (with cooldown to not go back
## again) -> walking")* — the hut is occupied exactly while it is inside, and a walker whose answer
## is to walk through does not stop at all.
func _test_a_walker_is_held_at_a_door_in_four_states(t: TestRunner, scene: Dictionary) -> void:
	if scene.is_empty():
		return
	var city: City = scene["city"]
	city.crowd.clear()
	var hut: WalkerDoorHold = scene["huts"][0]
	var walker := _walker_approaching(scene, hut.stands_at(), 160.0, WalkerStrategy.DoorAnswer.HELD)
	# The way it points as it starts, kept for the whole crossing: "past the hut" is measured
	# along that axis, because the walker's own heading flips the moment it turns round — and a
	# walker that came out and then walked back would read as one that never came out at all.
	# The line test below already guards its `crossed` against the same flip the same way.
	var approach := walker.heading()
	# Where the door let it go, measured on the first frame it is clear of the hut's cooldown area
	# (`WalkerStrategy.WALKER_DOOR_COOLDOWN_RADIUS`) after being inside — the release is by
	# distance, so this is the walker clear of the hut under its own steam rather than the spot it
	# was put on coming out. Stays -INF if it never gets clear inside the window, which the
	# sequence check reports first.
	var came_out_at := -INF

	# The four states as the hut and the walker show them: walking (on its way, in the line or not),
	# waiting (in the hut's line and standing), inspection (inside the hut, which is what the hut
	# says it holds) and out (it has been inside, and is not now).
	var seen: Array[int] = [_door_phase(walker, hut, false)]
	var been_inside := false
	var occupied_off_inspection := 0
	var drawn_during_inspection := 0
	var waited_at := INF
	for frame in int(round(8.0 / STEP)):
		city.crowd.step(STEP)
		var inspecting := hut.inside == walker
		been_inside = been_inside or inspecting
		var phase := _door_phase(walker, hut, been_inside)
		# The hut holds somebody exactly while that walker is hidden in it.
		if inspecting == walker.visible:
			occupied_off_inspection += 1
		if inspecting and walker.visible:
			drawn_during_inspection += 1
		if phase == DoorPhase.WAITING:
			waited_at = minf(waited_at, -_past_the_hut(walker, hut))
		if been_inside and not inspecting and came_out_at == -INF \
				and walker.global_position.distance_to(hut.stands_at()) \
				> WalkerStrategy.WALKER_DOOR_COOLDOWN_RADIUS:
			came_out_at = (walker.global_position - hut.stands_at()).dot(approach)
		if phase != seen[seen.size() - 1]:
			seen.append(phase)
	t.check(seen == [DoorPhase.WALKING, DoorPhase.WAITING, DoorPhase.INSPECTION, DoorPhase.OUT],
			"a held walker goes walking, waiting, inspection, out (got %s)" % [seen])
	t.check(occupied_off_inspection == 0,
			"the hut is occupied exactly while somebody is hidden in it (%d frames it was not)"
			% occupied_off_inspection)
	t.check(drawn_during_inspection == 0,
			"and nobody is drawn while they are inside it (%d frames somebody was)"
			% drawn_during_inspection)
	# Beside the hut rather than inside its footprint, and short of the body that would otherwise
	# stop her — a frame of travel either side of the distance it aims at.
	t.check(absf(waited_at - WalkerStrategy.WALKER_DOOR_STOP_DISTANCE) < 4.0,
			"it stops short of the hut's own body (%.1fpx against %.1f)"
			% [waited_at, WalkerStrategy.WALKER_DOOR_STOP_DISTANCE])
	t.check(came_out_at > 0.0,
			"and it comes out on the far side of the door (%.1fpx)" % came_out_at)
	t.check(hut.inside == null and hut.waiting() == 0,
			"the hut is free again once it has let somebody through")

	# The cooldown: the same hut may not take it again until it has actually left the hut's area,
	# which is why the flag is cleared by distance rather than by a clock. What it rules out is a
	# walker turned round by the crowd's own steering a few pixels past the door, so a solid body
	# is stood across the walker's footway beyond the hut, where the walker meets it and turns back
	# to the hut: nothing but the hut's own lines shows the walker is being let out and not taken in
	# again (`WalkerDoorHold.inside`, and which of them it is in the line of, `place_of()`).
	var inside_the_area := _times_the_hut_takes_a_walker_turned_round_beyond_it(scene, hut,
			WalkerStrategy.WALKER_DOOR_COOLDOWN_RADIUS * 0.8)
	t.check(inside_the_area == 1,
			"a walker that has just come out is not taken again when it is turned round at the door "
			+ "(taken %d times)" % inside_the_area)
	var outside_the_area := _times_the_hut_takes_a_walker_turned_round_beyond_it(scene, hut,
			WalkerStrategy.WALKER_DOOR_COOLDOWN_RADIUS * 2.0)
	t.check(outside_the_area == 2,
			"and it is taken again once it has left the hut's area and come back (taken %d times)"
			% outside_the_area)

	# And the answer the player asked to keep: a small fraction walk through as they always did.
	var passing := _walker_approaching(scene, hut.stands_at(), 160.0,
			WalkerStrategy.DoorAnswer.PASSES)
	var stopped := 0
	for frame in int(round(5.0 / STEP)):
		city.crowd.step(STEP)
		if hut.place_of(passing) >= 0 or hut.inside == passing \
				or passing.velocity().is_zero_approx():
			stopped += 1
	t.check(stopped == 0,
			"a walker that walks through a door never stops at the hut (%d frames it did)"
			% stopped)
	t.check(_past_the_hut(passing, hut) > 0.0, "and it is through the door")

## How many times `hut` takes a walker in (`WalkerDoorHold.inside` becoming it) that is held at the hut
## and then meets a body standing across its footway `beyond` px past the hut: the body turns it round
## once it is out (`WalkerStrategy.divert()`), so it walks back toward the hut. The body is stood
## in the tiles of the footway the walker is on, the way a stationary solid body is
## (`WorldMap.obstruct_tiles()`, which an event's body fills), and taken away again.
func _times_the_hut_takes_a_walker_turned_round_beyond_it(scene: Dictionary, hut: WalkerDoorHold,
		beyond: float) -> int:
	var city: City = scene["city"]
	var map: CityMap = scene["map"]
	var vertical: bool = scene["vertical"]
	city.crowd.clear()
	var hut_across: float = hut.stands_at().x if vertical else hut.stands_at().y
	var hut_along: float = hut.stands_at().y if vertical else hut.stands_at().x
	var corridor := CrowdLanes.corridor_at(hut_across)
	var first := 0 if CrowdLanes.nearest_sidewalk(corridor, hut_across) < 2 else 2
	var direction := 1.0 if scene["at_a"] else -1.0
	var body_along := floori((hut_along + direction * beyond) / float(Tuning.TILE_SIZE))
	var body: Array[Vector2i] = []
	for offset: int in [CrowdLanes.SIDEWALK_OFFSETS[first], CrowdLanes.SIDEWALK_OFFSETS[first + 1]]:
		var across_tile := corridor * CityMap.period() + offset
		body.append(Vector2i(across_tile, body_along) if vertical else Vector2i(body_along, across_tile))
	var owner := 987654
	map.obstruct_tiles(owner, body)
	var walker := _walker_approaching(scene, hut.stands_at(), 100.0, WalkerStrategy.DoorAnswer.HELD, true)
	var takes := 0
	var was_inside := false
	for frame in int(round(14.0 / STEP)):
		city.crowd.step(STEP)
		var inside := hut.inside == walker
		if inside and not was_inside:
			takes += 1
		was_inside = inside
	map.release_obstruction(owner)
	city.crowd.clear()
	return takes

## What a walker held at a door is doing, read off the hut and the walker: inside the hut, standing
## in its line, out again after being inside, or on its way (in the line or not).
enum DoorPhase { WALKING, WAITING, INSPECTION, OUT }

func _door_phase(walker: CrowdAgent, hut: WalkerDoorHold, been_inside: bool) -> int:
	if hut.inside == walker:
		return DoorPhase.INSPECTION
	if been_inside:
		return DoorPhase.OUT
	if hut.place_of(walker) >= 0 and walker.velocity().is_zero_approx():
		return DoorPhase.WAITING
	return DoorPhase.WALKING

## M110, the last item's own third clause: *"don't want a queue that is long"*. A door's line is
## short **by construction** — one walker inside, `WalkerStrategy.WALKER_DOOR_QUEUE_MAX` standing behind it,
## and the next walker to see the door turns away at the door rather than joining. The line is
## asserted against the constant rather than against a count, so moving the cap moves the test with
## it; what would fail is a line that grows past whatever the cap says.
func _test_a_line_at_a_door_stays_short(t: TestRunner, scene: Dictionary) -> void:
	if scene.is_empty():
		return
	var city: City = scene["city"]
	city.crowd.clear()
	var hut: WalkerDoorHold = scene["huts"][0]
	# One at the hut, `WALKER_DOOR_QUEUE_MAX` behind it, and one more than the door will take.
	var line: Array[CrowdAgent] = []
	for i in WalkerStrategy.WALKER_DOOR_QUEUE_MAX + 2:
		line.append(_walker_approaching(scene, hut.stands_at(), 60.0 + 40.0 * float(i),
				WalkerStrategy.DoorAnswer.HELD))
	var turned_away: CrowdAgent = line[line.size() - 1]
	var away_at_the_start := turned_away.global_position.distance_to(hut.stands_at())
	# Measured against the way it was **originally** pointing, because turning away reverses its
	# heading: "how far past the door" read off the current heading flips sign the moment it turns
	# round, and a walker that correctly went home would read as one that sailed through.
	var approach := turned_away.heading()

	var longest := 0
	var ever_joined := false
	var ever_turned := false
	var crossed := false
	var spacing_seen := 0
	for frame in int(round(6.0 / STEP)):
		city.crowd.step(STEP)
		longest = maxi(longest, hut.committed())
		if hut.place_of(turned_away) >= 0:
			ever_joined = true
		if turned_away.heading().dot(approach) < 0.5:
			ever_turned = true
		if (turned_away.global_position - hut.stands_at()).dot(approach) > 0.0:
			crossed = true
		# Two waiting behind somebody inside: the second of them stands one spacing further back
		# than the first, which is what makes a line a line rather than a heap.
		if hut.inside != null and hut.waiting() >= 2:
			var first: CrowdAgent = hut.queue[0]
			var second: CrowdAgent = hut.queue[1]
			if first.velocity().is_zero_approx() and second.velocity().is_zero_approx():
				var gap := absf(_past_the_hut(second, hut)) - absf(_past_the_hut(first, hut))
				if absf(gap - WalkerStrategy.WALKER_DOOR_QUEUE_SPACING) < 6.0:
					spacing_seen += 1
	t.check(longest <= WalkerStrategy.WALKER_DOOR_QUEUE_MAX + 1,
			"a door never holds more than one walker inside and WALKER_DOOR_QUEUE_MAX behind it "
			+ "(the most it held was %d)" % longest)
	t.check(longest == WalkerStrategy.WALKER_DOOR_QUEUE_MAX + 1,
			"and it does fill up, so the cap above was actually asked about (%d)" % longest)
	t.check(not ever_joined, "the walker the door has no room for never joins the line")
	t.check(ever_turned, "it decides against that door rather than walking up to the queue")
	t.check(not crossed, "and it never reaches the door, let alone crosses it")
	t.check(turned_away.global_position.distance_to(hut.stands_at()) > away_at_the_start,
			"it is walking away from the door by the end")
	t.check(spacing_seen > 0,
			"a second walker waits behind the first at a walker's spacing (%d frames)"
			% spacing_seen)

## The boom over the roadway is the cars' own and is untouched by any of the above: a car still
## comes to a full stop at a lowered gate and the gate still raises for it once it has been stopped
## for `Crowd.GATE_STOP_SECONDS`. *(2026-09-02, the player: "cars need to slow down to a full stop
## before the gate opens and they can go ahead again.")*
func _test_a_car_still_stops_for_the_boom(t: TestRunner, scene: Dictionary) -> void:
	if scene.is_empty():
		return
	var city: City = scene["city"]
	city.crowd.clear()
	var map: CityMap = scene["map"]
	var vertical: bool = scene["vertical"]
	var gate: RegionPlanner.GateState = city.streets().region_plan().gates[0]
	var gate_across: float = gate.position.x if vertical else gate.position.y
	var gate_along: float = gate.position.y if vertical else gate.position.x
	var corridor := CrowdLanes.corridor_at(gate_across)
	var direction := -1.0 if scene["at_a"] else 1.0
	var lane := CrowdLanes.road_lane(vertical, direction)
	var car: CrowdAgent = _rig.agent_on(city, map, CrowdAgent.Kind.CAR, corridor, lane,
			gate_along - direction * 180.0, direction, vertical, CrowdLanes.SIDEWALK_OFFSETS,
			Tuning.CAR_SPEED.x, 7)

	# Watched against the moment the boom first goes up rather than against its state at the end:
	# it comes back down behind a car that has gone through (`Crowd._stop_for_gates()` keeps it up
	# only while somebody is within a car's length of it), so the final state of a gate says
	# nothing about whether it ever opened.
	var came_to_a_stop := false
	var ever_raised := false
	var crossed_before_it_raised := false
	for frame in int(round(8.0 / STEP)):
		city.crowd.step(STEP)
		if gate.raised:
			ever_raised = true
			continue
		if car.speed() < Tuning.CAR_STOPPED_SPEED and car.lane().gate_hold() < INF:
			came_to_a_stop = true
		if not ever_raised and (car.global_position - gate.position).dot(car.heading()) > 0.0:
			crossed_before_it_raised = true
	t.check(came_to_a_stop, "a car comes to a full stop at a lowered boom")
	t.check(ever_raised, "and the boom then raises for it")
	t.check(not crossed_before_it_raised, "and nothing drives under a boom that is still down")

## M110, item 3: a soft seal takes both pavements from the walkers and leaves the carriageway to
## the cars. `SealPlanner.plan_day` is driven directly here, off a real tree, since
## `CityMap.soft_sealed_tiles` and `CrowdAgent.strategy.cannot_go_on` are what is being asked about rather
## than the whole day's pipeline — checked against the predicate directly, for the same reason the
## door carve-out above is: whether a random walker wanders onto one particular tile inside a short
## window is a question about the day's population, not about this rule.
func _test_a_soft_seal_shuts_both_pavements_to_walkers_only(t: TestRunner) -> void:
	var day := 3
	var tree := RouteTree.for_day(_city.map, day)
	var seal_rng := RandomNumberGenerator.new()
	seal_rng.seed = hash("crowd-soft-seal:%d:%d" % [SEED, day])
	SealPlanner.plan_day(_city.map, DaySpec.for_day(day), tree, seal_rng)
	t.check(not _city.map.soft_sealed_tiles.is_empty(),
			"today's tree leaves at least one street soft-sealed (%d tiles)"
			% _city.map.soft_sealed_tiles.size())

	var both_sealed: StreetNetwork.Segment = null
	var thinned: StreetNetwork.Segment = null
	var thinned_open: Array[Vector2i] = []
	for segment in _city.map.network.segments():
		if not _city.map.has_street(segment.key()):
			continue
		# Ordinary streets only: a precinct has no pavement/carriageway split for a soft seal to
		# take one side of, and asking a car to drive across one is a question this test does not
		# mean to be asking.
		var road_tile := _cross_section_tiles(segment)[2]
		if not _city.map.is_driveable_at(not segment.horizontal, road_tile):
			continue
		var near := _sidewalk_side_tiles(segment, true)
		var far := _sidewalk_side_tiles(segment, false)
		var near_sealed := _all_soft_sealed(near)
		var far_sealed := _all_soft_sealed(far)
		if near_sealed and far_sealed and not both_sealed:
			both_sealed = segment
		elif near_sealed != far_sealed and not thinned:
			thinned = segment
			thinned_open = far if near_sealed else near
		if both_sealed and thinned:
			break
	t.check(both_sealed != null, "at least one street has both pavements soft-sealed today")
	t.check(thinned != null, "and at least one has only one — the thinning pass's own mark")
	if not both_sealed or not thinned:
		return

	_city.crowd.clear()
	var walker: CrowdAgent = _rig.any_agent(_city.crowd, _city.map, CrowdAgent.Kind.WALKER)
	var car: CrowdAgent = _rig.any_agent(_city.crowd, _city.map, CrowdAgent.Kind.CAR)
	t.check(walker != null and car != null, "the crowd takes a walker and a car on some open street")
	if walker == null or car == null:
		return
	var vertical := not both_sealed.horizontal

	for tile in _sidewalk_side_tiles(both_sealed, true) + _sidewalk_side_tiles(both_sealed, false):
		t.check(walker.lane().strategy().cannot_go_on(vertical, tile),
				"a walker turns away from a fully soft-sealed pavement tile %s" % tile)
		t.check(not car.lane().strategy().cannot_go_on(vertical, tile),
				("and a car still drives straight through the same tile %s — the carriageway is " +
				"never sealed") % tile)

	for tile in thinned_open:
		t.check(not walker.lane().strategy().cannot_go_on(not thinned.horizontal, tile),
				"the thinned pair's open pavement stays open to a walker at %s" % tile)

	_city.crowd.clear()
	_city.map.clear_day_soft_seals()

## The street's own cross-section, one tile per lane, at the middle of the block — the same layout
## `SealPlanner._cross_section_tiles` places a soft seal's bodies against, duplicated here (it is
## file-private there) rather than reached into.
func _cross_section_tiles(segment: StreetNetwork.Segment) -> Array[Vector2i]:
	var rect := segment.tile_rect()
	var tiles: Array[Vector2i] = []
	if segment.horizontal:
		var mid_x := rect.position.x + rect.size.x / 2
		for row in Tuning.STREET_WIDTH:
			tiles.append(Vector2i(mid_x, rect.position.y + row))
	else:
		var mid_y := rect.position.y + rect.size.y / 2
		for column in Tuning.STREET_WIDTH:
			tiles.append(Vector2i(rect.position.x + column, mid_y))
	return tiles

## Both walker-lane tiles of one pavement side of `segment` — `Tuning.SIDEWALK_WIDTH` of them, the
## whole footway rather than only the one lane a soft seal's own body happens to stand on.
func _sidewalk_side_tiles(segment: StreetNetwork.Segment, near: bool) -> Array[Vector2i]:
	var tiles := _cross_section_tiles(segment)
	if near:
		return tiles.slice(0, Tuning.SIDEWALK_WIDTH)
	return tiles.slice(Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH)

func _all_soft_sealed(tiles: Array[Vector2i]) -> bool:
	for tile in tiles:
		if _city.map.passable(tile, Mover.of(Mover.SOFT_SEALS)):
			return false
	return true

## M110: the streets bordering the home block are held the same way a hard seal's own segment is
## (`EventManager.start_day` holds them so no catalogue row lands there — `docs/DECISIONS.md`, M100,
## "Nothing on the home block") but carry no body across them at all: she walks out onto one of them
## every morning, and the home is a notch with one exit, so shutting it to the crowd the way item 2
## shuts a hard seal's street would be wrong. `HeldStreets.Why.HOME` is the carve-out, the same
## shape a region door's is. Driven off a real day — `held` has to be genuinely
## non-empty around the home block for this to test anything rather than pass vacuously.
func _test_the_doorstep_street_is_not_shut_by_its_own_hold(t: TestRunner) -> void:
	var map := MapCache.of(SEED)
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(city)
	city.build(map)

	var day := 1
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	var closures_rng := RandomNumberGenerator.new()
	closures_rng.seed = hash("crowd-home-closures:%d:%d" % [SEED, day])
	city.start_day(state, day, closures_rng)
	var events_rng := RandomNumberGenerator.new()
	events_rng.seed = hash("crowd-home-events:%d:%d" % [SEED, day])
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_day(day), events_rng, consumed)

	var home_segments := map.network.around_blocks(Rect2i(map.home_block, Vector2i.ONE))
	t.check(not home_segments.is_empty(), "the home block has bordering streets")
	var home_keys := {}
	var held_home := false
	for segment in home_segments:
		home_keys[segment.key()] = true
		if map.is_held(segment):
			held_home = true
	t.check(held_home,
			"at least one of them is held today, or this test is not exercising the carve-out")

	var at := map.doorstep_world_position()
	city.crowd.start_day(day, _rng(day), at)

	# Twelve seconds. The two checks below are *presence* — somebody uses these streets, and so does
	# something on four wheels — so what the loop needs is long enough for either to be seen, not a
	# rate. The field is centred on the doorstep and the home block's own bordering streets are
	# inside it from the first frame, so both are answered in the first second or two on a street
	# that is open at all; the rest is margin for a morning whose placement started everybody
	# further up the corridor.
	var walkers_seen := 0
	var cars_seen := 0
	for frame in int(round(12.0 / STEP)):
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		for agent in city.crowd.agents():
			var segment := map.network.segment_containing(map.world_to_tile(agent.position))
			if segment == null or not home_keys.has(segment.key()):
				continue
			if agent.lane().kind() == CrowdAgent.Kind.WALKER:
				walkers_seen += 1
			else:
				cars_seen += 1
	t.check(walkers_seen > 0,
			"walkers still use the home block's own bordering streets (%d frames)" % walkers_seen)
	t.check(cars_seen > 0, "and so do cars (%d frames)" % cars_seen)

	city.free()

## M53: **the overrun permission was narrowed to a car on the spine, and the lane was not** — the
## entry-side fallback (`CrowdAgent._keep_within_the_room_beyond_the_map`) used to hand every kind
## the same `ENTRY_SPREAD` reach past the true edge, so a walker whose six recycle rolls all missed
## could appear already standing on the bridge. The bridge is not made safe by this: a car on the
## spine still overruns the map's south edge, by up to `CarStrategy.BRIDGE_RUN` (the bridge deck's
## length less a car) on its way out and at least `CarStrategy.BRIDGE_ENTRY_MIN` (past the camera's
## reach beyond the edge) on its way in, which is the whole of how it looks like it drives across
## rather than stopping dead at the kerb.
func _test_only_cars_go_over_the_bridge(t: TestRunner) -> void:
	var spine_x := (_city.map.main_road * CityMap.period() + Tuning.STREET_WIDTH * 0.5) \
			* float(Tuning.TILE_SIZE)
	var limit := _city.map.world_size().y
	var at := Vector2(spine_x, limit - Tuning.TILE_SIZE)
	_city.crowd.start_day(1, _rng(1), at)

	var worst_walker := 0.0
	var worst_car := 0.0
	for frame in int(round(30.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent in _city.crowd.agents():
			var overrun: float = agent.position.y - limit
			if agent.lane().kind() == CrowdAgent.Kind.WALKER:
				worst_walker = maxf(worst_walker, overrun)
			else:
				worst_car = maxf(worst_car, overrun)

	t.check(worst_walker <= Tuning.TILE_SIZE + 1.0,
			"no walker overruns the map's south edge by more than a tile (worst %.0fpx)"
			% worst_walker)
	t.check(worst_car > Tuning.TILE_SIZE * 2.0,
			"and a car on the spine still overruns it — the bridge is not made safe (worst %.0fpx)"
			% worst_car)

## M53: **the crowd has to agree with the drawing.** A T-junction the paint knows about and
## `WalkerStrategy.divert()` does not is the same bug in the other direction — so this checks the
## crowd's own notion of a street (`CityMap.is_street`, which is what `LaneStrategy.cannot_go_on()` reads) against
## a calm zone's absorbed corridor the same way `tests/test_generator.gd` checks the paint.
##
## A car never belongs on a zone's absorbed corridor — `is_street()` is false there, park or not,
## which is the one check `LaneStrategy.cannot_go_on()` makes that does not care *why* a tile stopped being a
## street. A walker legitimately does: a zone is calm ground as well as a shortcut, and standing on
## it is correct rather than a leak. So the property is asked only of cars, over a real zone with
## real traffic around it rather than by re-deriving what `LaneStrategy.cannot_go_on()` already computes.
func _test_the_crowd_agrees_a_zone_absorbed_the_corridor(t: TestRunner) -> void:
	if _city.map.zone_rects.is_empty():
		return
	var anchor: Vector2i = _city.map.zone_rects.keys()[0]
	var footprint := CityMap.blocks_tile_rect(_city.map.zone_rects[anchor])
	var at := _city.map.tile_rect_to_world(footprint).get_center()
	_city.crowd.start_day(1, _rng(1), at)

	# Fifteen seconds of the field sitting on the zone: every car in the box is recycled or drives
	# past the absorbed corridor several times over in that, which is what gives the count
	# something to be zero about. A longer watch is the same refusal asked again.
	var cars_inside := 0
	for frame in int(round(15.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent in _city.crowd.agents():
			if agent.lane().kind() != CrowdAgent.Kind.CAR:
				continue
			if footprint.has_point(_city.map.world_to_tile(agent.position)):
				cars_inside += 1
	t.check(cars_inside == 0,
			"no car ever stands on the zone's absorbed corridor at %s (%d frames it did)"
			% [footprint, cars_inside])

## M53: **cars and people still go off the map.** Two candidates: the agent is recycled on screen,
## or a junction exists somewhere it should not. The generation side was checked directly —
## `StreetNetwork.segments()` never enumerates a junction or a segment outside `junction_count()`,
## and every boundary junction is a genuine T or L by construction, since there is no tile grid
## beyond it for a fourth arm to point into. Not reproduced there.
##
## The recycle side was: `_keep_within_the_room_beyond_the_map` (checked at the spine in
## `_test_only_cars_go_over_the_bridge`) is not spine-specific, so an **ordinary** boundary gets the
## same guarantee for free. Checked here at the east edge, on a corridor that is not the spine, so
## the fix is asserted as the general one it is rather than as a property of the bridge alone.
func _test_agents_do_not_overrun_an_ordinary_edge(t: TestRunner) -> void:
	var limit := _city.map.world_size().x
	var at := Vector2(limit - Tuning.TILE_SIZE, _city.map.world_size().y * 0.5)
	_city.crowd.start_day(1, _rng(2), at)

	var worst := 0.0
	for frame in int(round(20.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent in _city.crowd.agents():
			worst = maxf(worst, agent.position.x - limit)
	t.check(worst <= Tuning.TILE_SIZE + 1.0,
			"nobody overruns an ordinary edge by more than a tile (worst %.0fpx)" % worst)

## Playtest 37, finding 4: **out of bounds is blocked**, not merely limited to within a tile the
## way `_test_only_cars_go_over_the_bridge` and `_test_agents_do_not_overrun_an_ordinary_edge`
## already check — `CrowdAgent.strategy.cannot_go_on` now refuses every out-of-bounds tile outright, with
## one exception, so the new claim is that nobody else reaches one **at all**. Checked directly
## against `CityMap.in_bounds` rather than by a pixel tolerance: the spine's own band (north and
## south) may still carry a car past it, and nowhere else may carry anybody.
##
## **The two edges the spine runs off, and only those.** The exception is what this test is for,
## and it exists nowhere else — so the plain west and east edges it used to stand on as well are
## exactly the two that `_test_nobody_enters_across_a_plain_edge` below stands on, at the same two
## coordinates, for half the time, asserting a strictly stronger version of the same
## sentence (nobody at all, rather than no walker and no off-spine car). Running both was the same
## refusal paid for twice.
func _test_out_of_bounds_is_blocked_except_a_car_on_the_spine(t: TestRunner) -> void:
	var spine_lo := _city.map.main_road * CityMap.period() * float(Tuning.TILE_SIZE)
	var spine_hi := spine_lo + Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE)
	var size := _city.map.world_size()
	var edges: Array[Vector2] = [
		Vector2((spine_lo + spine_hi) * 0.5, Tuning.TILE_SIZE),
		Vector2((spine_lo + spine_hi) * 0.5, size.y - Tuning.TILE_SIZE),
	]
	for i in edges.size():
		var at: Vector2 = edges[i]
		_city.crowd.start_day(1, _rng(10 + i), at)
		var walkers_out := 0
		var off_spine_cars_out := 0
		for frame in int(round(20.0 / STEP)):
			_city.crowd.set_focus(at)
			_city.crowd.step(STEP)
			for agent in _city.crowd.agents():
				if _city.map.in_bounds(_city.map.world_to_tile(agent.position)):
					continue
				if agent.lane().kind() == CrowdAgent.Kind.WALKER:
					walkers_out += 1
				elif agent.position.x < spine_lo or agent.position.x >= spine_hi:
					off_spine_cars_out += 1
		t.check(walkers_out == 0,
				"edge %d: no walker ever stands out of bounds (%d frames it did)"
				% [i, walkers_out])
		t.check(off_spine_cars_out == 0,
				"edge %d: no car off the spine ever stands out of bounds (%d frames it did)"
				% [i, off_spine_cars_out])

## Which of a crowd's bodies has been put down somewhere new since it was last asked about: one that
## has moved further in a frame than any body drives or walks in one was recycled, which is the only
## way the crowd moves a body that far (`LaneMover.step()` recycles one that has left the crowd's
## field). Asked of each body once a frame, after the frame's step.
class Landings extends RefCounted:
	const JUMP := 100.0
	var _was := {}

	func _init(crowd: Crowd) -> void:
		for agent in crowd.agents():
			_was[agent.get_instance_id()] = agent.position

	func landed(agent: CrowdAgent) -> bool:
		var id := agent.get_instance_id()
		var before: Vector2 = _was.get(id, agent.position)
		_was[id] = agent.position
		return before.distance_to(agent.position) > JUMP

## A spine car that is put into the world past the map's edge is put out of anybody's sight: coming
## out of the tunnel it is wholly inside the opaque dark and no deeper than the mountain roof, and
## coming onto the bridge it is beyond the camera's reach from the map's edge. Stood at each end,
## the crowd's own spine cars are recycled as they leave the field, and the landings past the edge
## are read.
func _test_spine_cars_are_put_out_of_sight(t: TestRunner) -> void:
	var spine_lo := _city.map.main_road * CityMap.period() * float(Tuning.TILE_SIZE)
	var spine_hi := spine_lo + Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE)
	var size := _city.map.world_size()
	var ends := {
		"tunnel": Vector2((spine_lo + spine_hi) * 0.5, Tuning.TILE_SIZE),
		"bridge": Vector2((spine_lo + spine_hi) * 0.5, size.y - Tuning.TILE_SIZE),
	}
	var i := 0
	for name: String in ends:
		var at: Vector2 = ends[name]
		_city.crowd.start_day(1, _rng(60 + i), at)
		i += 1
		var landings := Landings.new(_city.crowd)
		var landed := 0
		var in_view := 0
		var too_deep := 0
		for frame in int(round(40.0 / STEP)):
			_city.crowd.set_focus(at)
			_city.crowd.step(STEP)
			for agent in _city.crowd.agents():
				if agent.lane().kind() != CrowdAgent.Kind.CAR or not _city.map.is_main_road(
						true, CrowdLanes.corridor_at(agent.position.x)):
					continue
				if not landings.landed(agent):
					continue
				var y: float = agent.position.y
				if name == "tunnel" and y < 0.0:
					landed += 1
					if y > -CarStrategy.TUNNEL_ROOM:
						in_view += 1
					if y < -CarStrategy.TUNNEL_ENTRY_ROOM:
						too_deep += 1
				elif name == "bridge" and y > size.y:
					landed += 1
					if y < size.y + CarStrategy.BRIDGE_ENTRY_MIN:
						in_view += 1
		t.check(landed > 0, "%s: spine cars were put past the edge, so the check is not vacuous" % name)
		t.check(in_view == 0 and too_deep == 0,
				"%s: no spine car comes into existence in view (%d of %d did; %d too deep)"
				% [name, in_view, landed, too_deep])

## A car driving into the tunnel stops existing once its whole body is inside the mouth, so it
## never visibly drives on across the mountain over it, and the bridge is long enough that a car
## never drives off the end of its deck. Stood at each end, the furthest any spine car gets past the
## map edge is measured over thirty seconds, by which time the furthest has settled.
func _test_cars_do_not_drive_on_across_the_mountain(t: TestRunner) -> void:
	var spine_lo := _city.map.main_road * CityMap.period() * float(Tuning.TILE_SIZE)
	var spine_hi := spine_lo + Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE)
	var size := _city.map.world_size()
	var ends := {
		"tunnel": Vector2((spine_lo + spine_hi) * 0.5, Tuning.TILE_SIZE),
		"bridge": Vector2((spine_lo + spine_hi) * 0.5, size.y - Tuning.TILE_SIZE),
	}
	var i := 0
	for name: String in ends:
		var at: Vector2 = ends[name]
		_city.crowd.start_day(1, _rng(40 + i), at)
		i += 1
		var furthest_north := 0.0
		var departing_north := 0.0
		var furthest_south := 0.0
		var seen_past_the_edge := 0
		for frame in int(round(30.0 / STEP)):
			_city.crowd.set_focus(at)
			_city.crowd.step(STEP)
			for agent in _city.crowd.agents():
				if agent.lane().kind() != CrowdAgent.Kind.CAR:
					continue
				furthest_north = maxf(furthest_north, -agent.position.y)
				if agent.heading().y < 0.0:
					departing_north = maxf(departing_north, -agent.position.y)
				furthest_south = maxf(furthest_south, agent.position.y - size.y)
				if agent.position.y < 0.0 or agent.position.y > size.y:
					seen_past_the_edge += 1
		t.check(furthest_north <= CarStrategy.TUNNEL_ENTRY_ROOM + Tuning.CAR_STRIKE_HALF_LENGTH,
				"%s: arrivals stay beneath the tunnel roof (furthest %.0fpx)"
				% [name, furthest_north])
		t.check(departing_north <= CarStrategy.TUNNEL_ROOM + Tuning.CAR_STRIKE_HALF_LENGTH,
				"%s: departures vanish inside the dark before reaching the mountain (%.0fpx)"
				% [name, departing_north])
		t.check(furthest_south <= CityEdge.BRIDGE_DECK_PX,
				"%s: no car leaves the bridge deck (furthest %.0fpx)" % [name, furthest_south])
		t.check(seen_past_the_edge > 0, "%s: cars were past the edge, so the check is not vacuous"
				% name)

## Playtest 47: **"no car ever comes *out* of the tunnel or from the bridge."** A car on the spine
## overruns the edge by its exit's room on its way out (`CarStrategy.TUNNEL_ROOM`,
## `CarStrategy.BRIDGE_RUN`), and the entry side has to grant the same room: `CrowdAgent._entry_band_fits` otherwise refuses every band lying past the edge, which
## beside the tunnel is the only place a southbound spine car can start. So stand at each end of
## the spine and count spine cars seen out of bounds by which way they are pointing. Asserted as a
## ratio rather than a count, because the population and the re-roll odds both move: traffic
## through a hole in the border is two-way when the inbound frames are a real fraction of the
## outbound ones, and a handful — the fallback of six missed rolls, which is the reported state —
## is what the check has to refuse.
func _test_cars_come_out_of_the_tunnel_and_off_the_bridge(t: TestRunner) -> void:
	var spine_lo := _city.map.main_road * CityMap.period() * float(Tuning.TILE_SIZE)
	var spine_hi := spine_lo + Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE)
	var size := _city.map.world_size()
	var ends := {
		"tunnel": Vector2((spine_lo + spine_hi) * 0.5, Tuning.TILE_SIZE),
		"bridge": Vector2((spine_lo + spine_hi) * 0.5, size.y - Tuning.TILE_SIZE),
	}
	var i := 0
	for name: String in ends:
		var at: Vector2 = ends[name]
		_city.crowd.start_day(1, _rng(20 + i), at)
		i += 1
		var inbound := 0
		var outbound := 0
		for frame in int(round(20.0 / STEP)):
			_city.crowd.set_focus(at)
			_city.crowd.step(STEP)
			for agent in _city.crowd.agents():
				if agent.lane().kind() != CrowdAgent.Kind.CAR:
					continue
				if _city.map.in_bounds(_city.map.world_to_tile(agent.position)):
					continue
				# Out of bounds on the spine is the tunnel or the bridge; inward is toward the map.
				var outside_north := agent.position.y < 0.0
				var inward := agent.heading().y > 0.0 if outside_north else agent.heading().y < 0.0
				if inward:
					inbound += 1
				else:
					outbound += 1
		t.check(outbound > 0, "%s: cars still leave by it (%d frames out of bounds heading out)"
				% [name, outbound])
		# A car enters at most `ENTRY_SPREAD` out but leaves by the whole of the exit's room (the
		# deck is longer than the entry band), so the fraction asked for is scaled by that.
		var room := CarStrategy.BRIDGE_RUN if name == "bridge" else CarStrategy.TUNNEL_ENTRY_ROOM
		var exposure := minf(CrowdAgent.ENTRY_SPREAD, room) / room
		t.check(float(inbound) >= float(outbound) * exposure / 4.0,
				"%s: cars come in by it too (%d frames heading in against %d heading out)"
				% [name, inbound, outbound])

## M120: **entry is where exit is.** A recycled walker or off-spine car may not land past the true
## edge at all — `LaneStrategy.entry_room()` grants it none, where `LaneStrategy.has_left_the_map()` still
## grants a departing one a tile so it does not blip out exactly on the kerb. Stood at all four
## plain edges (north, south, east and west, each away from the spine so the tunnel and the bridge
## are not what is being asked about here — `_test_cars_come_out_of_the_tunnel_and_off_the_bridge`
## already covers that pair) and read the same way `_test_out_of_bounds_is_blocked_except_a_car_
## on_the_spine` does: against `CityMap.in_bounds`, not a pixel tolerance, so a walker standing on
## the mountain, the forest or the water band is exactly what fails this.
func _test_nobody_enters_across_a_plain_edge(t: TestRunner) -> void:
	var spine_lo := _city.map.main_road * CityMap.period() * float(Tuning.TILE_SIZE)
	var away_from_spine := spine_lo * 0.5
	var size := _city.map.world_size()
	var edges := {
		"north": Vector2(away_from_spine, Tuning.TILE_SIZE),
		"south": Vector2(away_from_spine, size.y - Tuning.TILE_SIZE),
		"west": Vector2(Tuning.TILE_SIZE, size.y * 0.5),
		"east": Vector2(size.x - Tuning.TILE_SIZE, size.y * 0.5),
	}
	var i := 0
	for name: String in edges:
		var at: Vector2 = edges[name]
		_city.crowd.start_day(1, _rng(30 + i), at)
		i += 1
		var out_of_bounds := 0
		for frame in int(round(10.0 / STEP)):
			_city.crowd.set_focus(at)
			_city.crowd.step(STEP)
			for agent in _city.crowd.agents():
				if _city.map.in_bounds(_city.map.world_to_tile(agent.position)):
					continue
				out_of_bounds += 1
		t.check(out_of_bounds == 0,
				"%s: nobody enters from the mountain, forest or water band (%d frames somebody did)"
				% [name, out_of_bounds])

## M120: **the entry roll itself, not only its final position.** A full `Crowd` never shows the
## difference above by itself — `LaneMover._stands_on_a_street()` already pulled a stray recycle back onto
## the map's own last row before M120, so *"nobody is ever out of bounds"* was already true and the
## test above cannot tell this fix from its absence. What changed is *how* a fresh entry lands there
## when the field's own edge (`CrowdField.along_bounds`) is already flush with the true one —
## `bounds.x - ENTRY_SPREAD` is then nowhere near a real street, so the un-clipped roll used to fail
## `LaneMover._entry_band_fits()` on every attempt bar the rare one that also finds a legal spot the other way
## round, and the state a recycle was left holding when none did was whichever `_choose_lane()`
## last rolled — almost never this axis and direction at all, because the other one kept winning the
## early exit. Read off the recycles the crowd makes itself, as the bodies that leave a field narrowed
## to 250px land again, with the field's own edge pinned 50px from the true one so an entry aimed
## this way has exactly that much real room and no more.
func _test_the_entry_roll_is_kept_inside_its_own_room(t: TestRunner) -> void:
	# The crowd's own field is a box of `Tuning.CROWD_FIELD_RADIUS` round the focus, so a focus that
	# far and 50px in from the west edge puts the box's west edge 50px from the true one: what leaves
	# the box is recycled and lands again at its west edge heading east.
	var at := Vector2(Tuning.CROWD_FIELD_RADIUS + 50.0, _city.map.world_size().y * 0.5)
	_city.crowd.start_day(1, _rng(50), at)
	var field := _city.crowd.field()
	var bounds := field.along_bounds(false)
	t.check(is_equal_approx(bounds.x, 50.0),
			"the field's own edge sits 50px from the true one, or the rig below is not testing it")

	var landings := Landings.new(_city.crowd)
	var landed_walkers := 0
	var lo := INF
	var hi := -INF
	var samples := 0
	for frame in int(round(30.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent in _city.crowd.agents():
			if not landings.landed(agent) or agent.lane().kind() != CrowdAgent.Kind.WALKER:
				continue
			landed_walkers += 1
			if agent.travelling_vertically() or agent.heading().x <= 0.0:
				continue
			samples += 1
			lo = minf(lo, agent.position.x)
			hi = maxf(hi, agent.position.x)
	# About a quarter of the walkers put down land heading east at the west edge; a fresh entry that
	# is refused its room there settles on another axis instead, which thins this share out.
	t.check(samples > 20 and samples * 8 > landed_walkers,
			"a fair share of the walkers put down land heading into this axis (%d of %d)"
			% [samples, landed_walkers])
	t.check(lo >= 0.0, "never past the true edge (worst %.1fpx)" % lo)
	t.check(hi - lo > 20.0,
			"and spread across the 50px of real room rather than pinned to one point (spread %.1fpx)"
			% (hi - lo))

## M100: **the picture, not only the centre.** PLAYTEST-69 re-reported "people still come out from
## outside the map" on top of M120's own fix, and this is the shape of it:
## `LaneStrategy.entry_room()` (M120) grants an ordinary walker or off-spine car nothing past the true edge, but
## nothing past the line still let the roll land exactly *on* it — a legal centre by
## `LaneMover._entry_band_fits()`'s old words — with the picture straddling the boundary regardless, since a
## walker's canvas rises `Sprites.draw_standing` bottom-anchored from its own position with nothing
## drawn south of it. Pinned flush with the true edge itself (`CrowdField.along_bounds`'s own clamp,
## not a field radius chosen to make it so), the same way `_test_nobody_enters_across_a_plain_edge`
## stands there — so there is no real room to spread rolls across at all, which is exactly the case
## `_entry_picture_clearance()` exists for. **Fails without the fix**: before it, every entry here
## lands with its centre on the line and its whole picture past it.
##
## Pinned like M120's own `_test_the_entry_roll_is_kept_inside_its_own_room` — a real but partial
## 45px of room, past the picture clearance (`AgentLook.entry_clearance()`)'s reach for a walker (38px) and for an off-spine
## car (26-28px), rather than flush with zero room. A flush field proves too much *and* too little
## at once here: with the fix, that axis and direction can never succeed at all — every attempt is
## refused and the loop always settles somewhere else — so a flush rig collects zero samples for the
## very case this test is about and cannot tell the fix from its own absence. With real room to
## spread across, some rolls still land inside the clearance and are refused, and the ones that are
## not prove the guarantee rather than assume it: **fails without the fix**, since before it every
## roll in `[0, 45)` was accepted rather than only `[38, 45)` (or `[26-ish, 45)` for a car).
##
## Read off the recycles the crowd makes itself, as the bodies that leave a box with its north edge
## 45px from the true one land again; a city of this test's own, so no other test's closures or seals
## can shut the corridors it stands beside and starve it of samples.
func _test_an_entry_beside_a_plain_edge_keeps_room_for_its_own_picture(t: TestRunner) -> void:
	# The box's north edge 45px from the true one, as the west edge is 50px in the test above; the
	# focus is in from the west and east edges as well, so the box is not grown to make up for ground
	# it hangs over.
	var at := Vector2(_city.map.world_size().x * 0.5, Tuning.CROWD_FIELD_RADIUS + 45.0)
	_city.crowd.start_day(1, _rng(51), at)
	var field := _city.crowd.field()
	var bounds := field.along_bounds(true)
	t.check(is_equal_approx(bounds.x, 45.0),
			"the field's own edge sits 45px from the true one, or the rig below is not testing it")
	var landings := Landings.new(_city.crowd)
	var worst := {CrowdAgent.Kind.WALKER: INF, CrowdAgent.Kind.CAR: INF}
	var samples := {CrowdAgent.Kind.WALKER: 0, CrowdAgent.Kind.CAR: 0}
	for frame in int(round(60.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent in _city.crowd.agents():
			if not landings.landed(agent) or not agent.travelling_vertically() \
					or agent.heading().y <= 0.0:
				continue
			# The spine's own tunnel exception (M94), not the guarantee this test holds.
			var agent_kind := agent.lane().kind()
			if agent_kind == CrowdAgent.Kind.CAR and _city.map.is_main_road(
					true, CrowdLanes.corridor_at(agent.position.x)):
				continue
			samples[agent_kind] += 1
			worst[agent_kind] = minf(worst[agent_kind],
					agent.position.y - _entry_clearance(agent))
	for kind: CrowdAgent.Kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		var label := "car" if kind == CrowdAgent.Kind.CAR else "walker"
		t.check(samples[kind] > 5,
				"%s: enough landings come into this axis to say anything (%d)"
				% [label, samples[kind]])
		t.check(worst[kind] >= 0.0,
				"%s: the picture never reaches past the true edge (worst %.1fpx short of its own "
				% [label, worst[kind]] + "clearance)")

## How far past an agent's coordinate along its axis its picture reaches: the figure its look gives
## the agent (`AgentLook.entry_clearance()`, which `CrowdAgent` asks when it places a body).
func _entry_clearance(agent: CrowdAgent) -> float:
	var look: AgentLook = CarLook.new(agent) if agent.lane().kind() == CrowdAgent.Kind.CAR \
			else WalkerLook.new(agent)
	return look.entry_clearance(agent.travelling_vertically())

## M100: **the same question at the morning's own placement.** `Crowd.start_day()` places every
## agent through `CrowdAgent.setup()`, which rolls freely across `CrowdField.along_bounds()` with no
## room question asked at all — and that box is already clamped flush to the true edge near one, so
## a roll can land as close to it as the continuous draw happens to put it. Read directly off a real
## day rather than off a pinned rig, because `setup()`'s own retries depend on the corridors actually
## in view rather than on a hand-placed field. A city of its own for the same reason the test above
## has one: nothing another test closed or sealed stands in it.
func _test_day_start_keeps_room_for_its_own_picture(t: TestRunner) -> void:
	var map := MapCache.of(SEED)
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(city)
	city.build(map)
	var size := map.world_size()
	var at := Vector2(Tuning.TILE_SIZE, size.y * 0.5)
	city.crowd.start_day(1, _rng(40), at)
	var worst := INF
	for agent in city.crowd.agents():
		var limit: float = size.y if agent.travelling_vertically() else size.x
		var clearance := _entry_clearance(agent)
		var along := agent.position.y if agent.travelling_vertically() else agent.position.x
		worst = minf(worst, minf(along - clearance, limit - clearance - along))
	t.check(worst >= 0.0,
			"every agent placed this morning keeps its own picture inside the map (worst %.1fpx "
			% worst + "short of its own clearance)")
	city.free()
