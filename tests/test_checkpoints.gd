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
	_test_the_three_rows_validate_and_are_never_rolled(t)
	_test_the_manager_actually_places_the_door_structure(t)
	_test_a_hut_detains_and_releases_on_the_other_side(t)
	_test_she_and_the_guard_are_gone_during_the_hold(t)
	_test_the_camera_eases_onto_the_hut_and_back(t)
	_test_walking_back_redetains_her(t)
	_test_the_chatting_mother_still_detains_once(t)
	_test_a_car_stops_at_a_closed_gate_and_passes_once_it_opens(t)
	_test_a_raised_gate_still_detains_her_at_the_bar(t)

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
## stood, reflected through the crossing's own cross-street line and pushed clear of
## `detain_radius`. See `EventManager._release_finished_door_detentions()`.
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
	t.check(stroller.is_detained(), "entering detain_radius locks her input")
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
			"and clear of the body and of detain_radius (%.1f against %.1f)"
			% [absf(released_along), clearance])
	t.check(absf(released_along) > hut.def.detain_radius,
			"clear enough that the same approach cannot re-trigger it (%.1f > %.1f)"
			% [absf(released_along), hut.def.detain_radius])
	t.check(released_cross.is_equal_approx(Vector2(0.0, 16.0)),
			"on the same pavement lane she arrived on (%s)" % released_cross)
	t.check(stroller.velocity == Vector2.ZERO, "the teleport zeroes her velocity")

	# The moment of release does not re-trigger the same frame: she is already outside
	# detain_radius by construction.
	manager._check_detentions()
	t.check(not hut.is_chatting(), "released, and not immediately re-captured")

	hut.free()
	stroller.free()
	manager.free()

## M113, the inspection reads as one — *(2026-09-10, playtest 55: "both the guard and the player
## should disappear during the inspection ... after the inspection the player and the guard should
## reappear".)* Neither `Stroller.visible` nor `EventInstance._draw()`'s own early return is
## reachable from a test that never calls `_draw()` (headless runs never call it — see the
## **verify** skill), so the state each of them reads is asserted directly instead.
##
## The halo goes with the guard too — the checkpoint's own `EntityHalo` ring stayed up through the
## hold in an earlier capture, which contradicted "both the guard and the player should disappear."
## `is_suppressed_by_its_own_hold()` is the one condition `_draw()` and `_draw_body()` (the halo's
## own re-draw entry point) both gate on, so asserting it here is asserting what the halo actually
## does without a canvas.
func _test_she_and_the_guard_are_gone_during_the_hold(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.RIGHT
	var centre := Vector2(4200.0, 4200.0)
	var hut := _door_instance(t, "checkpoint_hut", centre, axis)
	manager._instances.append(hut)

	t.check(stroller.visible, "she is visible before the hold starts")
	t.check(not hut.is_suppressed_by_its_own_hold(), "and the hut's own halo is not suppressed yet")
	stroller.global_position = centre + axis * 40.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(hut.is_chatting(), "the hold starts")
	t.check(not stroller.visible, "and she is hidden the instant it does")
	t.check(hut.is_suppressed_by_its_own_hold(),
			"and the hut's own halo is suppressed the same instant, with the guard")

	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	t.check(not hut.is_chatting(), "the hold ends")
	t.check(stroller.visible, "and she is visible again the same frame")
	t.check(not hut.is_suppressed_by_its_own_hold(),
			"and the halo is no longer suppressed, with the guard")

	hut.free()
	stroller.free()
	manager.free()

## *"The camera should center on the hut ... use a smooth ease in out for non player caused camera
## movement."* Drives `Stroller._update_camera()` directly, the same private-method stepping
## `_advance_chat()` above already uses for `EventInstance._process()`, so the ease is checked
## without also exercising `move_and_slide()` against the hut's own obstruction body.
func _test_the_camera_eases_onto_the_hut_and_back(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.RIGHT
	var centre := Vector2(4400.0, 4400.0)
	var hut := _door_instance(t, "checkpoint_hut", centre, axis)
	manager._instances.append(hut)

	stroller.global_position = centre + axis * 40.0
	var camera_before := stroller._camera.global_position
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(hut.is_chatting(), "the hold starts")

	for i in int(round(Tuning.CAMERA_EASE_SECONDS / STEP)) + 5:
		stroller._update_camera(STEP)
	var eased_distance := stroller._camera.global_position.distance_to(hut.global_position)
	t.check(eased_distance < 1.0,
			"the camera arrives at the hut once the ease has run its course (%.1fpx away)"
			% eased_distance)
	t.check(stroller._camera.global_position.distance_to(camera_before) > 1.0,
			"and it actually moved to get there, rather than having started there")

	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	t.check(not hut.is_chatting(), "the hold ends")
	var released_position := stroller.global_position

	for i in int(round(Tuning.CAMERA_EASE_SECONDS / STEP)) + 5:
		stroller._update_camera(STEP)
	var returned_distance := stroller._camera.global_position.distance_to(released_position)
	t.check(returned_distance < 1.0,
			"and eases back to her, on the released side of the door (%.1fpx away)"
			% returned_distance)

	hut.free()
	stroller.free()
	manager.free()

## *"It works in both directions with the same cost each time."* Having just been released on the
## far side, walking back into the same hut detains her again, for the same `detain_seconds`, and
## returns her to (the clearance distance on) the original side.
func _test_walking_back_redetains_her(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.DOWN
	var centre := Vector2(5000.0, 5000.0)
	var post := _door_instance(t, "checkpoint_post", centre, axis)
	manager._instances.append(post)

	stroller.global_position = centre + axis * 30.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(post.is_chatting(), "the first approach detains her")
	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	var first_release := stroller.global_position
	t.check((first_release - centre).dot(axis) < 0.0, "released on the far side, first crossing")

	# Walk back in from the side she is now on.
	stroller.global_position = centre + (first_release - centre).normalized() * 30.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(post.is_chatting(), "the return approach detains her again — redetains, in either "
			+ "direction")
	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	var second_release := stroller.global_position
	t.check((second_release - centre).dot(axis) > 0.0,
			"and returns her to the original side on the way back")

	post.free()
	stroller.free()
	manager.free()

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
## checkpoint inspection".)* The gate now detains exactly like a hut, `redetains` included, so the
## vanish (`Stroller.hide_for_inspection()`) and the halo suppression
## (`is_suppressed_by_its_own_hold()`) both apply here too, the same way
## `_test_she_and_the_guard_are_gone_during_the_hold` above checks them against a hut.
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
	t.check(gate.is_suppressed_by_its_own_hold(), "and the gate's own halo is suppressed too")

	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	t.check(not gate.is_chatting(), "the hold ends")
	t.check(stroller.visible, "and she is visible again")
	t.check(not gate.is_suppressed_by_its_own_hold(), "with the halo no longer suppressed")

	car_stand_in.free()
	gate.free()
	stroller.free()
	manager.free()
