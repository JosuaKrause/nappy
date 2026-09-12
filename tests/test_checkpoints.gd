extends RefCounted
## The region door's own structure: `checkpoint_hut`/`checkpoint_gate`/`checkpoint_post`, placed by
## `RegionPlanner._add_door_bodies`/`_add_alley_door_bodies`, detained and released by
## `EventManager`, and the gate a car stops for in `Crowd._stop_for_gates()`.
##
## `docs/CITY.md`, "Regions and the wall" and `docs/EVENTS.md`, "Checkpoints" are the design;
## `tests/test_regions.gd` is the model this suite's data-level half follows — a segment-level
## check cannot see an alley mouth or a wall body bleeding sideways, so the shape checks below walk
## real tiles the same way that suite's own flood check does.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 60.0
const SEEDS := 4
const BASE_SEED := 771103

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 251))
	_test_every_door_has_its_three_bodies(t)
	_test_door_bodies_stand_on_their_own_ground(t)
	_test_the_boom_bars_the_carriageway(t)
	_test_the_three_rows_validate_and_are_never_rolled(t)
	_test_the_manager_actually_places_the_door_structure(t)
	_test_a_hut_detains_and_releases_on_the_other_side(t)
	_test_a_stroller_stopped_against_the_hut_is_detained(t)
	_test_she_and_the_guard_are_gone_during_the_hold(t)
	_test_the_whole_hold_reads_as_one_move(t)
	_test_crossing_the_street_at_the_door_still_puts_her_through_it(t)
	_test_the_release_latch(t)
	_test_walking_back_redetains_her(t)
	_test_the_chatting_mother_still_detains_once(t)
	_test_a_car_stops_at_a_closed_gate_and_passes_once_it_opens(t)
	_test_a_raised_gate_still_detains_her_at_the_bar(t)
	_test_a_raised_boom_does_not_open_the_checkpoint_for_her(t)

# ------------------------------------------------------------------------ setup ---

func _repaint_for(map: CityMap, day: int) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)

## Every (map, day) pair worth sampling: `Tuning.REGION_WALL_FIRST_DAY` through the end of the run,
## on every seed this suite generated.
func _sampled_days() -> Array:
	var found: Array = []
	for map in _maps:
		for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
			found.append([map, day])
	return found

# ------------------------------------------------------------------- the shape ---

## Every street door stands exactly three bodies — two `checkpoint_hut` and one `checkpoint_gate`
## — at its own mouth; every alley door stands exactly two `checkpoint_post`, one at each mouth.
## Also the measurement the report asked for: doors and bodies per sampled day.
func _test_every_door_has_its_three_bodies(t) -> void:
	var sampled := 0
	var total_doors := 0
	var total_alley_doors := 0
	var total_huts := 0
	var total_gates := 0
	var total_posts := 0
	for pair in _sampled_days():
		var map: CityMap = pair[0]
		var day: int = pair[1]
		_repaint_for(map, day)
		var tree := RouteTree.for_day(map, day)
		var plan := RegionPlanner.plan_day(map, day, tree)
		sampled += 1
		total_doors += plan.doors.size()
		total_alley_doors += plan.alley_doors.size()

		var counts := {}
		for body in plan.door_bodies:
			counts[body.def.id] = int(counts.get(body.def.id, 0)) + 1
		var huts: int = counts.get("checkpoint_hut", 0)
		var gates: int = counts.get("checkpoint_gate", 0)
		var posts: int = counts.get("checkpoint_post", 0)
		total_huts += huts
		total_gates += gates
		total_posts += posts

		t.check(huts == plan.doors.size() * 2,
				"seed %d day %d: two huts per street door (%d doors, %d huts)"
				% [map.seed_used, day, plan.doors.size(), huts])
		t.check(gates == plan.doors.size(),
				"seed %d day %d: one gate per street door (%d doors, %d gates)"
				% [map.seed_used, day, plan.doors.size(), gates])
		t.check(posts == plan.alley_doors.size() * 2,
				"seed %d day %d: two posts per alley door (%d alley doors, %d posts)"
				% [map.seed_used, day, plan.alley_doors.size(), posts])
		t.check(plan.gates.size() == plan.doors.size(),
				"seed %d day %d: one GateState per street door (%d doors, %d gates)"
				% [map.seed_used, day, plan.doors.size(), plan.gates.size()])
	t.check(sampled > 0, "at least one (seed, day) pair was sampled (%d)" % sampled)
	print(("[test_checkpoints] over %d sampled (seed, day) pairs: %d street doors (%d huts, " +
			"%d gates), %d alley doors (%d posts)")
			% [sampled, total_doors, total_huts, total_gates, total_alley_doors, total_posts])

## No door body stands on tree ground other than the door's own segment: a street door's three
## bodies land on tiles belonging to that segment and no other, and an alley door's two posts land
## in that alley's own rect. The check a segment-level assertion alone cannot make — see
## `tests/test_regions.gd`, "The check a segment-level rule cannot do" — is that a body's own
## `obstructs_radius` circle never reaches a *different* boundary crossing's ground either.
func _test_door_bodies_stand_on_their_own_ground(t) -> void:
	var checked := 0
	for pair in _sampled_days():
		var map: CityMap = pair[0]
		var day: int = pair[1]
		_repaint_for(map, day)
		var tree := RouteTree.for_day(map, day)
		var plan := RegionPlanner.plan_day(map, day, tree)

		# Every door body's own tile belongs to the segment or the alley it was built for.
		for segment in plan.doors:
			var default_at_a := RegionPlanner.region_of_junction(map, segment.a) \
					< RegionPlanner.region_of_junction(map, segment.b)
			var at_a: bool = map.boundary_wall_at_a.get(segment.key(), default_at_a)
			var mouth := map.tile_rect_to_world(segment.mouth_rect(at_a))
			for body in plan.door_bodies:
				if body.def.id != "checkpoint_hut" and body.def.id != "checkpoint_gate":
					continue
				if not mouth.has_point(body.position):
					continue
				checked += 1
				var tile := map.world_to_tile(body.position)
				var containing := StreetNetwork.segment_containing(tile)
				t.check(containing != null and containing.key() == segment.key(),
						"seed %d day %d: door body %s at %s stands on its own segment %s (got %s)"
						% [map.seed_used, day, body.def.id, body.position, segment.key(),
						containing.key() if containing else "none"])

		# And every wall body never reaches inside a door's own mouth, the same direction
		# `test_regions.gd`'s own alley-mouth check runs.
		for wall_body in plan.wall_bodies:
			for segment in plan.doors:
				var default_at_a := RegionPlanner.region_of_junction(map, segment.a) \
						< RegionPlanner.region_of_junction(map, segment.b)
				var at_a: bool = map.boundary_wall_at_a.get(segment.key(), default_at_a)
				var mouth_centre := map.tile_rect_to_world(segment.mouth_rect(at_a)).get_center()
				var distance := wall_body.position.distance_to(mouth_centre)
				t.check(distance > wall_body.def.obstructs_radius,
						("seed %d day %d: a wall body at %s (radius %.0f) does not reach the door " +
						"at %s (%.0fpx away)") % [map.seed_used, day, wall_body.position,
						wall_body.def.obstructs_radius, segment.key(), distance])
	t.check(checked > 0, "at least one door body was checked against its own segment (%d)" % checked)

## *(PLAYTEST-57: "the gate for the cars is too high up. it needs to be further down".)* The boom
## is the one body at a door whose picture is much wider than the body under it, so where the bar
## actually lands is a question only the drawing can answer — and a headless run never calls
## `_draw()` (see the **verify** skill), which is why `EventInstance.boom_arm_span()` states the
## arm's own reach as a number the drawing and this check share.
##
## Three things about a street door, over every sampled day: the gate stands level with its two
## huts along the street, its own ground point is on the carriageway's centre line, and the arm it
## draws crosses the whole carriageway rather than lying along a kerb. The last one is what the
## picture got wrong: hung from the near post, the arm sat entirely to one side of the ground
## point, at the height of the road's upper kerb with the lanes open under it.
func _test_the_boom_bars_the_carriageway(t) -> void:
	var checked := 0
	for pair in _sampled_days():
		var map: CityMap = pair[0]
		var day: int = pair[1]
		_repaint_for(map, day)
		var tree := RouteTree.for_day(map, day)
		var plan := RegionPlanner.plan_day(map, day, tree)
		for segment in plan.doors:
			var default_at_a := RegionPlanner.region_of_junction(map, segment.a) \
					< RegionPlanner.region_of_junction(map, segment.b)
			var at_a: bool = map.boundary_wall_at_a.get(segment.key(), default_at_a)
			var mouth := map.tile_rect_to_world(segment.mouth_rect(at_a))
			var gate: EventScheduler.Planned = null
			var huts: Array[EventScheduler.Planned] = []
			for body in plan.door_bodies:
				if not mouth.has_point(body.position):
					continue
				if body.def.id == "checkpoint_gate":
					gate = body
				elif body.def.id == "checkpoint_hut":
					huts.append(body)
			if not gate or huts.size() != 2:
				continue
			checked += 1

			# The cross-street axis, and the carriageway band on it: the middle of the street's own
			# cross-section, with `Tuning.SIDEWALK_WIDTH` tiles of pavement on either side of it.
			var across_low: float = (mouth.position.y if segment.horizontal else mouth.position.x) \
					+ Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE
			var road_width: float = (Tuning.STREET_WIDTH - 2 * Tuning.SIDEWALK_WIDTH) \
					* Tuning.TILE_SIZE
			var across_high := across_low + road_width
			var gate_across: float = gate.position.y if segment.horizontal else gate.position.x
			var gate_along: float = gate.position.x if segment.horizontal else gate.position.y

			for hut in huts:
				var hut_along: float = hut.position.x if segment.horizontal else hut.position.y
				t.check(is_equal_approx(hut_along, gate_along),
						"seed %d day %d: the gate stands level with its huts along the street "
						% [map.seed_used, day] + "(gate %.1f, hut %.1f)" % [gate_along, hut_along])
			t.check(gate_across > across_low and gate_across < across_high,
					"seed %d day %d: the gate's ground point is on the carriageway, not a kerb "
					% [map.seed_used, day] + "(%.1f in %.1f..%.1f)"
					% [gate_across, across_low, across_high])

			var span := EventInstance.boom_arm_span(
					EventInstance.gate_runs_north_south(gate.facing))
			var arm_near := gate_across + span.x
			var arm_far := gate_across + span.y
			t.check(arm_near <= across_low and arm_far >= across_high,
					("seed %d day %d: the lowered arm crosses the whole carriageway (%.1f..%.1f " +
					"over %.1f..%.1f)")
					% [map.seed_used, day, arm_near, arm_far, across_low, across_high])
			var arm_middle := 0.5 * (arm_near + arm_far)
			t.check(arm_middle > across_low and arm_middle < across_high,
					"seed %d day %d: and the middle of the bar is over the lanes, not a kerb "
					% [map.seed_used, day] + "(%.1f in %.1f..%.1f)"
					% [arm_middle, across_low, across_high])

			# And the picture stays over ground the door is actually solid on: the three bodies
			# tile the street edge to edge at `Tuning.TILE_SIZE` spacing, so an arm that reaches
			# past the gate's own body is still over a hut's.
			var solid_low := gate_across - gate.def.obstructs_radius
			var solid_high := gate_across + gate.def.obstructs_radius
			for hut in huts:
				var hut_across: float = hut.position.y if segment.horizontal else hut.position.x
				solid_low = minf(solid_low, hut_across - hut.def.obstructs_radius)
				solid_high = maxf(solid_high, hut_across + hut.def.obstructs_radius)
			t.check(arm_near >= solid_low and arm_far <= solid_high,
					("seed %d day %d: the arm never reaches past the door's own solid line " +
					"(%.1f..%.1f over %.1f..%.1f)")
					% [map.seed_used, day, arm_near, arm_far, solid_low, solid_high])
	t.check(checked > 0, "at least one street door's boom was measured (%d)" % checked)

## The three rows are `SCRIPTED`, `scripted_day 0`, like the seal pictures — so they validate on
## boot (already checked by `EventCatalogue.all()`, restated here explicitly) and the ordinary
## catalogue roll never schedules one, over several seeds and days.
func _test_the_three_rows_validate_and_are_never_rolled(t) -> void:
	for id in ["checkpoint_hut", "checkpoint_gate", "checkpoint_post"]:
		var def := EventCatalogue.by_id(id)
		t.check(def != null, "'%s' is in the catalogue" % id)
		t.check(def.validate(), "'%s' gives the player time to walk clear" % id)
		t.check(def.kind == GameEnums.EventKind.SCRIPTED and def.scripted_day == 0,
				"'%s' is SCRIPTED, scripted_day 0, like the seal pictures" % id)

	var rolled := 0
	for pair in _sampled_days():
		var map: CityMap = pair[0]
		var day: int = pair[1]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("checkpoints:%d:%d" % [map.seed_used, day])
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, rng, map, consumed):
			if plan.def.id.begins_with("checkpoint_"):
				rolled += 1
	t.check(rolled == 0,
			"the ordinary scheduler roll never places a checkpoint_hut/gate/post (%d)" % rolled)

## The wiring bug a data-level test cannot see: `RegionPlanner.plan_day()` building the right
## bodies is not the same as `EventManager` ever placing them. `region_plan.door_bodies` has to be
## appended to `EventManager._plans` in `start_day()`, the same way `wall_bodies` already is, or
## the whole structure is correct data nobody ever meets — see `tests/test_event_manager.gd`'s own
## class doc on why this suite exists at all: "the bugs that live here are wiring bugs."
func _test_the_manager_actually_places_the_door_structure(t) -> void:
	var day := Tuning.REGION_WALL_FIRST_DAY
	var map := CityGenerator.generate(BASE_SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	# No player in this rig, so nothing would ever stream in on its own — see
	# `test_event_manager.gd`'s own `_build_city()` for the same reasoning.
	city.events.stream_radius = INF
	# `city.start_day()` first, unlike `test_event_manager.gd`'s own rigs — this test is
	# specifically about `EventManager.start_day()` reading a real `City.region_plan()` rather
	# than growing its own fallback one (`_city.route_tree()` reads null before `City.start_day()`
	# has ever run, which silently empties `RegionPlanner.plan_day()` — a gap real play never
	# hits, since `main._start_day()` always calls `_city.start_day()` first).
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	var closures_rng := RandomNumberGenerator.new()
	closures_rng.seed = hash("checkpoint-wiring-closures:%d:%d" % [BASE_SEED, day])
	city.start_day(state, day, closures_rng)
	var events_rng := RandomNumberGenerator.new()
	events_rng.seed = hash("checkpoint-wiring-events:%d:%d" % [BASE_SEED, day])
	var consumed: Array[String] = []
	city.events.start_day(day, events_rng, consumed)

	var region_plan := city.region_plan()
	t.check(region_plan.door_bodies.size() > 0,
			"day %d generated a door structure to place (%d bodies)"
			% [day, region_plan.door_bodies.size()])

	var planned_ids := {}
	for plan in city.events.plans():
		if plan.def.id.begins_with("checkpoint_"):
			planned_ids[plan.def.id] = int(planned_ids.get(plan.def.id, 0)) + 1
	t.check(int(planned_ids.get("checkpoint_hut", 0)) > 0,
			"the day's own plan carries checkpoint_hut, not just RegionPlanner's own list")
	t.check(int(planned_ids.get("checkpoint_gate", 0)) > 0,
			"and checkpoint_gate")

	var live_gate: EventInstance = null
	var live_hut: EventInstance = null
	for instance in city.events.instances():
		if instance.def.id == "checkpoint_gate" and not live_gate:
			live_gate = instance
		if instance.def.id == "checkpoint_hut" and not live_hut:
			live_hut = instance
	t.check(live_hut != null, "with streaming off, a checkpoint_hut actually goes live")
	t.check(live_gate != null, "and a checkpoint_gate actually goes live")
	if live_gate:
		t.check(live_gate.gate_state != null,
				"the live gate instance carries the shared GateState, not a null default")

	city.free()

# ------------------------------------------------------------------- the detention ---
# A manager with nothing in it but the map arithmetic `_check_detentions()`'s own telemetry line
# needs, the same shape `tests/test_events.gd`'s own `_chat_manager()` is built. The stroller is
# the *real* scene rather than a bare `Stroller.new()`, so `global_position` — what the teleport
# actually moves — is meaningful: a bare rig has no `CollisionShape2D`, so `move_and_slide()`
# never moves it and only `velocity` is trustworthy. Its `Baby` child needs `name = "Baby"` set
# for the same reason `Stroller.baby_is_awake()`'s lookup finds it at all — see the verify skill.

func _manager(t) -> EventManager:
	var manager := EventManager.new()
	manager._map = CityMap.new()
	t.add_child(manager)
	manager.set_physics_process(false)
	return manager

func _real_stroller(t) -> Stroller:
	var scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var stroller: Stroller = scene.instantiate()
	t.add_child(stroller)
	stroller.set_physics_process(false)
	t.check(stroller.get_node_or_null("CollisionShape2D") != null,
			"the real stroller scene carries a CollisionShape2D")
	var baby := stroller.get_node_or_null("Baby")
	t.check(baby != null and baby.name == "Baby",
			"and a Baby named 'Baby', the name Stroller.baby_is_awake() looks up by")
	return stroller

## A door instance built by hand at a known position and along-axis, the same shape
## `RegionPlanner._add_door_bodies` gives one — `face` carries the street's own axis, which
## `EventInstance.facing_now()` and `EventManager`'s detention teleport both read back.
func _door_instance(t, id: String, at: Vector2, face: Vector2) -> EventInstance:
	var def := EventCatalogue.by_id(id)
	var instance := EventInstance.new()
	instance.setup(def, at, PackedVector2Array(), face)
	t.add_child(instance)
	instance.set_process(false)
	return instance

## Steps every live instance's own clock (`_chat_seconds_left` only runs down inside
## `EventInstance._process()`) alongside the manager's own trigger, the same pairing
## `_test_the_chatting_mother_still_detains_once` below drives by hand.
func _advance_chat(manager: EventManager, seconds: float) -> void:
	for i in int(round(seconds / STEP)) + 5:
		for instance in manager._instances:
			instance._process(STEP)
		manager._check_detentions()

## The core rig: she walks into a hut, is detained for `Tuning.CHECKPOINT_DETAIN_SECONDS`, and
## comes out the other side, outside the band, on the same pavement lane — the mirror of where she
## stood, reflected through the crossing's own cross-street line and pushed clear of the hold's own
## trigger. See `EventManager._release_finished_door_detentions()`.
func _test_a_hut_detains_and_releases_on_the_other_side(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.RIGHT
	var centre := Vector2(4000.0, 4000.0)
	var hut := _door_instance(t, "checkpoint_hut", centre, axis)
	manager._instances.append(hut)

	# On the positive side of the crossing, 16px off the axis — the "same pavement lane" the
	# release has to preserve.
	var entry := centre + axis * 40.0 + Vector2(0.0, 16.0)
	stroller.global_position = entry
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(stroller.is_detained(), "coming inside the hold's own trigger locks her input")
	t.check(hut.is_chatting(), "and starts a conversation")
	t.check(hut.has_chatted(), "which marks it as having chatted at least once")

	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	t.check(not hut.is_chatting(), "the conversation has ended")
	t.check(not hut.is_finished and not hut.is_leaving,
			"and the hut stays put — redetains, it does not depart like chatting_mother")

	var released := stroller.global_position
	var released_offset := released - centre
	var released_along := released_offset.dot(axis)
	var released_cross := released_offset - axis * released_along
	t.check(released_along < 0.0,
			"released on the opposite side of the crossing from where she went in (%.1f)"
			% released_along)
	var clearance := hut.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
			+ Tuning.CHECKPOINT_RELEASE_MARGIN
	t.check(absf(released_along) >= clearance - 0.5,
			"and just clear of its body, as close to the door as she can stand (%.1f against %.1f)"
			% [absf(released_along), clearance])
	t.check(absf(released_along) < hut.def.detain_distance(),
			("which is *inside* the hold's own trigger, because the far side of a door is — the " +
			"latch is what keeps her from being taken straight back in (%.1f against %.1f)")
			% [absf(released_along), hut.def.detain_distance()])
	t.check(released_cross.is_equal_approx(Vector2(0.0, 16.0)),
			"on the same pavement lane she arrived on (%s)" % released_cross)
	t.check(stroller.velocity == Vector2.ZERO, "the teleport zeroes her velocity")

	# And she stands there, inside the trigger, for as long as she likes.
	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS * 3.0)
	t.check(not hut.is_chatting(),
			"released, and standing still is not taken in again however long she stands there")
	t.check(stroller.global_position.is_equal_approx(released),
			"without having been moved again (%s)" % stroller.global_position)

	hut.free()
	stroller.free()
	manager.free()

## How far her own outline reaches ahead of her centre while she faces `facing` — her own body's
## radius, or the pram's own body when that is what is between her and whatever she is walking at.
## **Read off the real scene rather than restated here**: where the pram's body sits is another
## milestone's number, and a rig that copied it would go on passing after it moved, which is the
## exact shape of the defect this suite is checking. `Stroller._physics_process()` is the one place
## that positions the pram's shape, so the rig drives one frame of it and measures the result.
func _reach_ahead(t, stroller: Stroller, facing: Vector2) -> float:
	stroller.facing = facing
	stroller._physics_process(STEP)
	var reach := Tuning.PLAYER_BODY_RADIUS
	var pram := stroller.get_node_or_null("PramCollisionShape2D") as CollisionShape2D
	t.check(pram != null, "the real stroller scene carries the pram's own collision shape")
	if pram and not pram.disabled:
		var circle := pram.shape as CircleShape2D
		t.check(circle != null, "and it is a circle, so a reach can be read off it")
		if circle:
			reach = maxf(reach, pram.position.dot(facing) + circle.radius)
	return reach

## *(PLAYTEST-57: "the checkpoint should activate when I get close. with the new stroller hitbox I
## cannot reach the checkpoint entrance".)* The hold used to start inside a radius measured from
## the hut's centre, which meant the number had to be larger than whatever she was pushing in front
## of her — so the pram's body stopped her outside a trigger she could then never reach, and the
## door became a wall with no error anywhere.
##
## The assertion is the relationship rather than either number: **wherever she comes to rest
## against the hut's body, that place is inside the trigger.** Both approaches are checked, because
## the pram reaches further ahead of her along a street than across one (`Stroller.OBLIQUE_Y`
## foreshortens the vertical component of everything she is drawn and shaped with).
func _test_a_stroller_stopped_against_the_hut_is_detained(t) -> void:
	var axis := Vector2.RIGHT
	var centre := Vector2(4800.0, 4800.0)
	# North is out of the carriageway and onto the pavement the hut stands on; east is along the
	# street, straight at it.
	var approaches: Array[Vector2] = [Vector2.UP, Vector2.RIGHT]
	for approach in approaches:
		var manager := _manager(t)
		var stroller := _real_stroller(t)
		manager._player = stroller
		var hut := _door_instance(t, "checkpoint_hut", centre, axis)
		manager._instances.append(hut)

		var reach := _reach_ahead(t, stroller, approach)
		t.check(reach > Tuning.PLAYER_BODY_RADIUS,
				"walking %s she pushes something further ahead of her than her own body "
				% approach + "(%.1f against %.1f) — otherwise this rig checks nothing"
				% [reach, Tuning.PLAYER_BODY_RADIUS])
		var stopped_at := hut.def.obstructs_radius + reach
		t.check(stopped_at < hut.def.detain_distance(),
				("walking %s, where the hut's body stops her (%.1fpx from its centre) is inside " +
				"the trigger (%.1fpx)") % [approach, stopped_at, hut.def.detain_distance()])

		stroller.global_position = centre - approach * stopped_at
		manager._tell_them_where_she_is()
		manager._check_detentions()
		t.check(hut.is_chatting(),
				"and stopped there, walking %s, the inspection actually starts" % approach)
		t.check(stroller.is_detained(), "with her input locked")

		hut.free()
		stroller.free()
		manager.free()

## M113, the inspection reads as one — *(2026-09-10, playtest 55: "both the guard and the player
## should disappear during the inspection ... after the inspection the player and the guard should
## reappear".)* Neither `Stroller.visible` nor `EventInstance._draw()`'s own early return is
## reachable from a test that never calls `_draw()` (headless runs never call it — see the
## **verify** skill), so the state each of them reads is asserted directly instead.
##
## **The hut is not the guard, and only the guard goes in** — *(PLAYTEST-57: "the checkpoint house
## disappears ... all this is incorrect".)* A building that blinks out while she is inside it reads
## as the door having been taken away rather than as her having gone through it. An alley post is
## the one row where the two are the same thing: he is all it draws, so when he goes in there is
## nothing left. `is_its_guard_inside()` and `is_suppressed_by_its_own_hold()` are the two
## conditions `_draw_checkpoint_hut()`, `_draw()` and `_draw_body()` (the halo's own re-draw entry
## point) gate on, so asserting them here is asserting what the halo and the picture actually do
## without a canvas.
func _test_she_and_the_guard_are_gone_during_the_hold(t) -> void:
	var ids: Array[String] = ["checkpoint_hut", "checkpoint_post"]
	for id in ids:
		var manager := _manager(t)
		var stroller := _real_stroller(t)
		manager._player = stroller

		var axis := Vector2.RIGHT
		var centre := Vector2(4200.0, 4200.0)
		var door := _door_instance(t, id, centre, axis)
		manager._instances.append(door)
		var is_a_guard_alone: bool = id == "checkpoint_post"

		t.check(stroller.visible, "%s: she is visible before the hold starts" % id)
		t.check(not door.is_its_guard_inside(), "%s: and its guard is outside" % id)
		t.check(not door.is_suppressed_by_its_own_hold(), "%s: and it is drawn" % id)
		stroller.global_position = centre + axis * 60.0
		manager._tell_them_where_she_is()
		manager._check_detentions()
		t.check(door.is_chatting(), "%s: the hold starts" % id)
		t.check(not stroller.visible, "%s: and she is hidden the instant it does" % id)
		t.check(door.is_its_guard_inside(), "%s: with the guard, who takes her in" % id)
		t.check(door.is_suppressed_by_its_own_hold() == is_a_guard_alone,
				("%s: and the rest of it stays exactly where it is, unless the guard was the " +
				"whole of it") % id)

		_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
		t.check(not door.is_chatting(), "%s: the hold ends" % id)
		t.check(stroller.visible, "%s: and she is visible again the same frame" % id)
		t.check(not door.is_its_guard_inside(), "%s: with the guard back at his post" % id)
		t.check(not door.is_suppressed_by_its_own_hold(), "%s: and the whole of it drawn" % id)

		door.free()
		stroller.free()
		manager.free()

## One frame of the whole hold: every live instance's own clock, the manager's trigger and release,
## and her camera, in the order a real frame runs them. `_advance_chat()` above drives the first
## two only; a camera fault is invisible to it.
func _advance_hold(manager: EventManager, stroller: Stroller, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		for instance in manager._instances:
			instance._process(STEP)
		manager._check_detentions()
		stroller._update_camera(STEP)

## The whole hold, end to end, against the four faults PLAYTEST-57 reported in it: *"the camera
## makes a huge jump from somewhere to the checkpoint. the checkpoint house disappears. the camera
## doesn't move at all after the 2s. also, if I don't move I get sent back afterwards. all this is
## incorrect."*
##
## It stands a real street door — two huts and the gate between them, a tile apart across the
## street, the geometry `RegionPlanner._add_door_bodies` builds — and walks her into it from where
## her own body actually stops, so the approach, the trigger, the two seconds, the camera and the
## release are all one run rather than four checks of four pieces.
func _test_the_whole_hold_reads_as_one_move(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller
	stroller._camera.make_current()

	var axis := Vector2.RIGHT
	var road := Vector2(5600.0, 5600.0)
	var hut := _door_instance(t, "checkpoint_hut", road - Vector2(0.0, 64.0), axis)
	var gate := _door_instance(t, "checkpoint_gate", road, axis)
	var far_hut := _door_instance(t, "checkpoint_hut", road + Vector2(0.0, 64.0), axis)
	manager._instances.append(hut)
	manager._instances.append(gate)
	manager._instances.append(far_hut)

	# Walking east along the northern pavement, stopped where the hut's own body stops her.
	var heading := Vector2.RIGHT
	var reach := _reach_ahead(t, stroller, heading)
	stroller.global_position = hut.global_position - heading * (hut.def.obstructs_radius + reach)
	# A camera that has been following her all morning, in a rig that is drawn no frames: smoothing
	# is applied in the camera's **own** process callback, which never runs here, so its smoothed
	# position would otherwise still be sitting at the world origin it was born at. `reset_smoothing()`
	# is what "it has already caught up with her" looks like, and `force_update_scroll()` is what
	# asks for the screen centre a drawn frame would have computed.
	stroller._camera.reset_smoothing()
	stroller._camera.force_update_scroll()
	var drawn_before := stroller.camera_screen_center()
	t.check(drawn_before.distance_to(stroller.global_position) < Tuning.TILE_SIZE,
			"the rig's camera is looking at her (%s against %s) — otherwise the continuity check "
			% [drawn_before, stroller.global_position] + "below has nothing to be continuous with")

	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(hut.is_chatting(), "walking up to the hut starts the inspection")
	t.check(not gate.is_chatting() and not far_hut.is_chatting(),
			"and only the nearest of the door's three bodies starts one")
	t.check(not stroller.visible, "she goes inside for it")
	# And no second body picks the hold up on the next frame, which is a different rule from the
	# tie above and the one that was actually charging her twice for one crossing.
	manager._check_detentions()
	t.check(not gate.is_chatting() and not far_hut.is_chatting(),
			"and nothing else takes her in on top of it the frame after")

	# **The camera jump.** `top_level` hands the camera its own transform and Godot keeps the
	# node's *local* position when it does — `Vector2.ZERO`, a whole city away — so the ease has to
	# put the camera where it was drawing from in the same breath, or every frame before the first
	# `_update_camera()` is drawn from the corner of the map.
	t.check(stroller._camera.top_level, "the camera comes off her for the hold")
	t.check(stroller._camera.global_position.distance_to(drawn_before) < 1.0,
			"and starts the ease from where it was drawing, not from wherever the switch left it "
			+ "(%s against %s)" % [stroller._camera.global_position, drawn_before])
	t.check(not stroller._camera.position_smoothing_enabled,
			"with the camera's own smoothing off for the duration, so it is not chasing the ease "
			+ "that is already smoothing the move")

	# **The hut vanishing.** Only the guard goes in with her.
	t.check(not hut.is_suppressed_by_its_own_hold(), "the hut is still drawn through the hold")
	t.check(hut.is_its_guard_inside(), "and its guard is not")

	_advance_hold(manager, stroller, Tuning.CAMERA_EASE_SECONDS)
	var onto := stroller._camera.global_position.distance_to(hut.global_position)
	t.check(onto < 1.0, "the camera arrives on the hut (%.1fpx away)" % onto)
	t.check(hut.is_chatting(), "with time left on the hold once it gets there")

	# **The camera not coming back.** The rest of the hold, then the ease home.
	_advance_hold(manager, stroller, Tuning.CHECKPOINT_DETAIN_SECONDS + Tuning.CAMERA_EASE_SECONDS)
	t.check(not hut.is_chatting(), "the hold ends on its own clock")
	t.check(stroller.visible, "and she comes back out")
	var released := stroller.global_position
	t.check((released - hut.global_position).dot(axis) > 0.0,
			"on the far side of the crossing from where she went in")
	var home := stroller._camera.global_position.distance_to(released)
	t.check(home < 1.0, "and the camera comes back onto her, wherever the release put her "
			+ "(%.1fpx away)" % home)
	t.check(not stroller._camera.top_level, "handed back to her own transform")
	t.check(stroller._camera.position_smoothing_enabled, "with its own smoothing back on")

	# **Sent back without moving.** She is set down just clear of the hut's body, which is well
	# inside the trigger — the far side of a door is a body's width away and the trigger reaches
	# further than that — so what keeps her out of it is the `ReleaseLatch` armed on the way out,
	# not distance. Standing there for several times the length of the hold itself costs nothing.
	t.check(released.distance_to(hut.global_position) < hut.def.detain_distance(),
			"she is standing inside the trigger she was just let out of (%.1f against %.1f)"
			% [released.distance_to(hut.global_position), hut.def.detain_distance()])
	_advance_hold(manager, stroller, Tuning.CHECKPOINT_DETAIN_SECONDS * 4.0)
	t.check(not hut.is_chatting() and not gate.is_chatting() and not far_hut.is_chatting(),
			"and standing there is not another inspection, however long she stands — and not by "
			+ "the gate beside the hut either: one crossing is one toll")
	t.check(stroller.global_position.is_equal_approx(released),
			"nor is she moved again (%s)" % stroller.global_position)

	# And walking out of the door's reach and back in pays the toll again, which is the whole of
	# what a door is.
	var away := (released - hut.global_position).normalized()
	stroller.global_position = hut.global_position + away * (hut.def.detain_distance() + 8.0)
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not hut.is_chatting(), "one step outside its reach is not a toll")
	stroller.global_position = released
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(hut.is_chatting(), "but stepping back in from there is")

	hut.free()
	gate.free()
	far_hut.free()
	stroller.free()
	manager.free()

## The crossing walked **across** rather than along it: she comes up out of the carriageway at a
## hut, or straight up the middle of the road at the gate, so at the moment of capture she is
## exactly level with the body along the street. There is no "other side" in that direction, and
## the release used to multiply its clearance by `signf(0.0)` — which is zero, so it put her back
## down exactly where it found her, inside the trigger, to be held again the next frame for as long
## as she stood there. Level with the door is one of the two sides, picked the same way every time.
##
## Against a whole door — two huts and the gate between them — because that is also where the other
## half of the rule is checked: a door's three reaches overlap, so being let out of one of them puts
## her inside another, and **one crossing has to be one toll** whichever body took her in.
func _test_crossing_the_street_at_the_door_still_puts_her_through_it(t) -> void:
	# Two approaches, each the same door: stopped against the northern hut from the frontage behind
	# it, dead level with it along the street; and stopped against the gate out on the carriageway,
	# a few pixels off its centre line, which is the one that lands her release inside a *hut's*
	# reach rather than the gate's.
	var entries: Array[Vector2] = [Vector2(0.0, -110.0), Vector2(-46.0, -6.0)]
	for from_road in entries:
		var manager := _manager(t)
		var stroller := _real_stroller(t)
		manager._player = stroller

		var axis := Vector2.RIGHT
		var road := Vector2(5200.0, 5200.0)
		var doors: Array[EventInstance] = [
			_door_instance(t, "checkpoint_hut", road - Vector2(0.0, 64.0), axis),
			_door_instance(t, "checkpoint_gate", road, axis),
			_door_instance(t, "checkpoint_hut", road + Vector2(0.0, 64.0), axis)]
		for door in doors:
			manager._instances.append(door)
		var caught_by := doors[0] if is_zero_approx(from_road.x) else doors[1]
		var entry := road + from_road

		stroller.global_position = entry
		manager._tell_them_where_she_is()
		manager._check_detentions()
		t.check(caught_by.is_chatting(),
				"crossing the street at %s starts the hold" % caught_by.def.id)

		_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
		var released := stroller.global_position
		var crossed := (released - caught_by.global_position).dot(axis)
		t.check(absf(crossed) > 1.0,
				("%s: the release carries her across the crossing (%.1f along it) rather than " +
				"setting her down exactly where it found her") % [caught_by.def.id, crossed])

		_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS * 3.0)
		for door in doors:
			t.check(not door.is_chatting(),
					"%s: nothing at the door holds her again where it let her out" % door.def.id)

		for door in doors:
			door.free()
		stroller.free()
		manager.free()

## *"It works in both directions with the same cost each time."* Having just been released on the
## far side, **leaving** the post's own reach re-arms it, and walking back in costs her the same
## hold and returns her to the original side. The two halves are the whole of the latch's contract:
## standing where she was let out is free, and the walk out and back is what pays again.
func _test_walking_back_redetains_her(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.DOWN
	var centre := Vector2(5000.0, 5000.0)
	var post := _door_instance(t, "checkpoint_post", centre, axis)
	manager._instances.append(post)

	stroller.global_position = centre + axis * 60.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(post.is_chatting(), "the first approach detains her")
	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	var first_release := stroller.global_position
	var out_side := (first_release - centre).normalized()
	t.check((first_release - centre).dot(axis) < 0.0, "released on the far side, first crossing")

	# Standing where she was let out, inside the post's own reach, is free for as long as she likes.
	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS * 3.0)
	t.check(not post.is_chatting(), "and standing there is not a second toll")

	# Walking out of its reach re-arms it, and walking back in pays again.
	stroller.global_position = centre + out_side * (post.def.detain_distance() + 4.0)
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not post.is_chatting(), "one step outside its reach is not a toll either")
	stroller.global_position = centre + out_side * 60.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(post.is_chatting(), "but walking back in from there detains her again — redetains, in "
			+ "either direction")
	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	var second_release := stroller.global_position
	t.check((second_release - centre).dot(axis) > 0.0,
			"and returns her to the original side on the way back")

	post.free()
	stroller.free()
	manager.free()

## `ReleaseLatch` on its own, without a door around it — the one rule the escape scene will reuse
## for its own doors *(2026-09-12: "same mechanism can be reused in the escape scene when going
## through doors")*, so it is checked here as a thing rather than only through the checkpoint that
## first needed it.
func _test_the_release_latch(t) -> void:
	var latch := ReleaseLatch.new()
	t.check(not latch.holds(), "a fresh latch holds nothing")

	var at := Vector2(100.0, 100.0)
	latch.arm(at, 48.0)
	t.check(latch.holds(), "armed, it holds")

	latch.update(at)
	t.check(latch.holds(), "and standing exactly where she was let out keeps holding it")
	latch.update(at + Vector2(47.0, 0.0))
	t.check(latch.holds(), "as does anywhere else inside the circle it was armed with")

	latch.update(at + Vector2(49.0, 0.0))
	t.check(not latch.holds(), "one step outside it clears the latch")
	latch.update(at)
	t.check(not latch.holds(),
			"and walking back in does not re-hold it — that is the door's job, not the latch's")

	latch.arm(at, 48.0)
	t.check(latch.holds(), "which the door does by arming it again")

## The one row that keeps its old, once-only behaviour: `redetains` defaults to `false`, and
## `chatting_mother` never sets it, so a second approach to the same instance never starts a
## second conversation — restated here beside the redetaining rows so the new gate in
## `EventManager._check_detentions()` (`not instance.def.redetains and instance.has_chatted()`) is
## checked against both branches in the same suite.
func _test_the_chatting_mother_still_detains_once(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var def := EventCatalogue.by_id("chatting_mother")
	t.check(not def.redetains, "chatting_mother does not redetain")
	var at := Vector2(6000.0, 6000.0)
	var mother := EventInstance.new()
	mother.setup(def, at, PackedVector2Array([at, at + Vector2(256.0, 0.0)]))
	t.add_child(mother)
	mother.set_process(false)
	manager._instances.append(mother)

	stroller.global_position = at
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(mother.is_chatting(), "the first approach starts the one conversation")
	for i in int(round(def.detain_seconds / STEP)) + 5:
		mother._process(STEP)
		manager._check_detentions()
	t.check(mother.has_chatted() and not mother.is_chatting(),
			"spent as a detainer once the conversation ends")

	# Back at the same spot: no second conversation, whatever `_check_detentions()` does now.
	stroller.global_position = at
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not mother.is_chatting(), "a second approach to the same instance never re-triggers")

	mother.free()
	stroller.free()
	manager.free()

# ------------------------------------------------------------------------ the gate ---

## A real car, a synthetic `GateState` sited directly ahead of it on its own lane — deterministic
## rather than searching the day's traffic for one that happens to be aligned with a real door, the
## same way a real car still exercises the real `Crowd._stop_for_gates()`/`CrowdAgent._give_way()`
## machinery `_test_a_car_can_always_stop_for_a_zebra_it_can_see` trusts for the zebra. Reports the
## stop duration and the pass, per the milestone's own request.
func _test_a_car_stops_at_a_closed_gate_and_passes_once_it_opens(t) -> void:
	var map := CityGenerator.generate(BASE_SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("checkpoint-gate-rig:%d" % BASE_SEED)
	city.crowd.start_day(1, rng, CrowdLanes.arterial_pavement(map))

	var car: CrowdAgent = null
	for agent in city.crowd.agents():
		if agent.kind == CrowdAgent.Kind.CAR:
			car = agent
			break
	t.check(car != null, "there is a car on the spine to test the gate against")
	if not car:
		city.free()
		return
	city.crowd.set_focus(car.global_position)

	var gate := RegionPlanner.GateState.new()
	gate.position = car.global_position + car.heading() * 150.0
	var gates: Array[RegionPlanner.GateState] = [gate]
	city.crowd.set_gates(gates)

	var stopped_seconds := 0.0
	var ever_stopped := false
	var passed_at := INF
	var raised_while_passing := false
	var elapsed := 0.0
	while elapsed < 20.0 and passed_at == INF:
		city.crowd.step(STEP)
		elapsed += STEP
		var ahead := (gate.position - car.global_position).dot(car.heading())
		if ahead > 0.0 and ahead < Tuning.CAR_STOP_LINE_SETBACK + 20.0:
			if car.speed() < Tuning.CAR_STOPPED_SPEED:
				ever_stopped = true
				stopped_seconds += STEP
		if ahead <= 0.0:
			passed_at = elapsed
			raised_while_passing = gate.raised

	t.check(ever_stopped, "the car comes to a full stop before the gate opens (%.1fs held)"
			% stopped_seconds)
	t.check(stopped_seconds >= Tuning.GATE_STOP_SECONDS - STEP,
			"held for at least Tuning.GATE_STOP_SECONDS before the gate could have opened for it "
			+ "(%.2fs held, %.2fs required)" % [stopped_seconds, Tuning.GATE_STOP_SECONDS])
	t.check(passed_at < INF, "and it eventually passes the gate (at %.1fs)" % passed_at)
	t.check(raised_while_passing, "the gate reads raised while it passes")

	var cleared := false
	elapsed = 0.0
	while elapsed < 5.0 and not cleared:
		city.crowd.step(STEP)
		elapsed += STEP
		cleared = not gate.raised
	t.check(cleared, "and lowers again once the road either side of it is clear")
	print("[test_checkpoints] gate rig: %.2fs stopped, passed at %.2fs, cleared by %.2fs"
			% [stopped_seconds, passed_at, elapsed])

	city.free()

## *"A raised bar is not a way past for her, at the bar itself."* Found building M110, the crowd's
## own seal-avoidance: `checkpoint_gate` carried no `detain_seconds`/`detain_radius` of its own, so
## stepping onto the boom's own tiles while it stood up for a car started nothing — only the huts
## detained. *(2026-09-10, the player: "attempting to do that should just start a regular
## checkpoint inspection".)* The gate now detains exactly like a hut, `redetains` included, so her
## own vanish (`Stroller.hide_for_inspection()`) applies here too — and, exactly as at a hut, the
## structure does not go with her: a boom is a bar across a road, and the guard who takes her in is
## at the hut. See `_test_she_and_the_guard_are_gone_during_the_hold` above for the same split.
##
## `gate_state.raised` is set here and never read anywhere in the detain path — only by the gate's
## own drawing (`_draw_checkpoint_gate()`) — so triggering the hold with it `true` is the whole of
## "whatever the bar is doing." A stand-in for a car queued at the line, sited close to where she
## is walking but far from the gate's own centre and never added to `manager._instances`, is the
## proof that proximity to it could never matter: `_check_detentions()` only ever measures
## `instance.global_position.distance_to(body.global_position)` over live `EventInstance`s, so
## nothing that is not one can ever be examined at all, whatever it is standing in for.
func _test_a_raised_gate_still_detains_her_at_the_bar(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.RIGHT
	var centre := Vector2(4600.0, 4600.0)
	var gate := _door_instance(t, "checkpoint_gate", centre, axis)
	gate.gate_state = RegionPlanner.GateState.new()
	gate.gate_state.raised = true
	manager._instances.append(gate)

	var car_stand_in := Node2D.new()
	car_stand_in.global_position = centre + axis * 300.0
	t.add_child(car_stand_in)

	stroller.global_position = centre + axis * 200.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not gate.is_chatting(),
			"well short of the gate's own detain_radius (near the car stand-in instead), nothing "
			+ "starts")

	stroller.global_position = centre + axis * 20.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(gate.is_chatting(), "inside the gate's own detain_radius, the hold starts")
	t.check(gate.gate_state.raised, "with the bar still reading raised the whole time")
	t.check(not stroller.visible, "and she is hidden, the same as at a hut")
	t.check(not gate.is_suppressed_by_its_own_hold(),
			"while the boom itself stays drawn — it is a bar across a road, not a man who can go "
			+ "inside")

	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	t.check(not gate.is_chatting(), "the hold ends")
	t.check(stroller.visible, "and she is visible again")

	car_stand_in.free()
	gate.free()
	stroller.free()
	manager.free()

## M110, the crowd goes round a seal: *(2026-09-10: "attempting to do that should just start a
## regular checkpoint inspection")* — a raised boom is a fact about the car queue, and must not be
## a way past her too. `checkpoint_gate` and `checkpoint_hut` share one crossing's `GateState`
## structurally (`RegionPlanner._add_door_bodies` builds one `GateState` per street door and hands
## it to the gate's own instance), but `EventManager._check_detentions()` never reads `gate_state`
## or `raised` at all — the hut's hold is `def.detain_seconds` and `detain_distance()` alone, so
## raising the boom for the cars must leave it exactly as long. Drives her into the hut with the
## door's real gate marked raised and asserts the inspection still starts and still runs its full
## length. She stands on the hut's far side from the gate, since only the nearest eligible body
## captures her and this check is about the hut's own hold.
func _test_a_raised_boom_does_not_open_the_checkpoint_for_her(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.RIGHT
	var centre := Vector2(7000.0, 7000.0)
	var hut := _door_instance(t, "checkpoint_hut", centre, axis)
	var gate_instance := _door_instance(t, "checkpoint_gate", centre + axis * 64.0, axis)
	manager._instances.append(hut)
	manager._instances.append(gate_instance)

	var gate := RegionPlanner.GateState.new()
	gate.position = gate_instance.global_position
	gate.raised = true
	gate_instance.gate_state = gate

	stroller.global_position = centre - axis * 60.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(stroller.is_detained(),
			"the boom standing raised for the cars does not wave her past the hut")
	t.check(hut.is_chatting(), "she still starts the ordinary inspection")

	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	t.check(not hut.is_chatting(), "and it runs its full ordinary length regardless of the boom")
	t.check(gate.raised, "raising the boom for the cars is a fact about the queue, not about her")

	hut.free()
	gate_instance.free()
	stroller.free()
	manager.free()
