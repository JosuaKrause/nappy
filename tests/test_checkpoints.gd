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
## How close `_test_the_hold_charges_only_its_toll()` reads the toll — a frame or two of the
## Baby's own stepping either side of exactly `Tuning.CHAT_EXCITEMENT`. Named because the same
## number is what decides how loud the field beside the door has to be for that rig to be worth
## running: a leak smaller than this is one the assertion could not tell from a pass.
const TOLL_TOLERANCE := 1.5

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 251))
	_test_every_door_has_its_three_bodies(t)
	_test_door_bodies_stand_on_their_own_ground(t)
	_test_the_boom_bars_the_carriageway(t)
	_test_the_three_rows_validate_and_are_never_rolled(t)
	_test_the_manager_actually_places_the_door_structure(t)
	_test_nothing_the_day_places_reaches_into_a_doors_gap(t)
	_test_a_hut_detains_and_releases_on_the_other_side(t)
	_test_the_hold_charges_only_its_toll(t)
	_test_a_boundarys_structures_charge_as_one(t)
	_test_a_corner_of_two_doors_is_one_toll(t)
	_test_she_is_never_drawn_at_the_place_she_went_in(t)
	_test_the_ground_she_is_let_out_onto_is_survivable(t)
	_test_the_run_that_killed_her_five_times(t)
	_test_a_stroller_stopped_against_the_hut_is_detained(t)
	_test_she_and_the_guard_are_gone_during_the_hold(t)
	_test_the_whole_hold_reads_as_one_move(t)
	_test_crossing_the_street_at_the_door_still_puts_her_through_it(t)
	_test_the_release_latch(t)
	_test_walking_back_redetains_her(t)
	_test_the_chatting_mother_still_detains_once(t)
	_test_a_car_stops_at_a_closed_gate_and_passes_once_it_opens(t)
	_test_the_boom_never_inspects_her(t)
	_test_the_arm_never_comes_down_on_her(t)
	_test_a_walk_under_the_boom_is_seen(t)
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

## `RegionPlanner.plan_day()`'s own answer for a (map, day) pair, computed once and shared by the
## three shape tests below rather than once each. **M125: measured at 112ms a pair** — repainting
## the map and planning the day is real work, and asking the same 32 pairs three times over was
## three-quarters of what this suite's shape section cost (10.8s of its ~11s, against 3.6s once
## the plan is shared). Keyed on `map.seed_used`, which is distinct per generated map, rather than
## on the map object itself, so the cache reads the same regardless of which test asks first.
var _plan_cache: Dictionary = {}

func _plan_for(map: CityMap, day: int) -> RegionPlanner.RegionPlan:
	var key := "%d:%d" % [map.seed_used, day]
	if not _plan_cache.has(key):
		_repaint_for(map, day)
		var tree := RouteTree.for_day(map, day)
		_plan_cache[key] = RegionPlanner.plan_day(map, day, tree)
	return _plan_cache[key]

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
		var plan := _plan_for(map, day)
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
		var plan := _plan_for(map, day)

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
		var plan := _plan_for(map, day)
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

## The three rows exist and the ordinary catalogue roll never schedules one, over several days.
## What makes that true — `SCRIPTED`, `scripted_day 0`, like the seal pictures — is not
## restated: reading those two fields back off the row could only ever say somebody edited the
## catalogue, while the sweep below says whether a checkpoint can reach the map by the wrong door.
## Their fairness is `EventCatalogue.all()`'s own sweep in `tests/test_events.gd`.
##
## **One map, every sampled day — M125.** `build_day()`'s refusal to roll a `SCRIPTED` row is a
## property of the scheduler and the catalogue flag, not of any one city's shape, so a second seed
## tests the same mechanism against different noise for no extra confidence: measured, this loop
## was 25.5s of the suite's ~39s, all four seeds paying for the same question. The day still runs
## the full `REGION_WALL_FIRST_DAY..RUN_LENGTH_DAYS` range, because *that* axis is real — a
## scripted-availability window is a fact about the day, not the map.
func _test_the_three_rows_validate_and_are_never_rolled(t) -> void:
	for id in ["checkpoint_hut", "checkpoint_gate", "checkpoint_post"]:
		t.check(EventCatalogue.by_id(id) != null, "'%s' is in the catalogue" % id)

	var map := _maps[0]
	var rolled := 0
	var scheduled := 0
	for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("checkpoints:%d:%d" % [map.seed_used, day])
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, rng, map, consumed):
			scheduled += 1
			if plan.def.id.begins_with("checkpoint_"):
				rolled += 1
	t.check(scheduled > 0,
			"the scheduler actually placed something to ask the question of (%d plans)" % scheduled)
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

## **Nothing the day places reaches into a door's own clear ground** — *(2026-09-20, the player:
## "there should be a gap for events immediately surrounding the gates".)* Asked of the rule
## itself, `EventScheduler.clear_of_the_doors()`, over a whole planned day rather than over one
## contrived placement: the ways a row gets onto the map are several (the fill, a scripted row, a
## set piece and its fallback) and a check on one of them would say nothing about the rest.
##
## **And the same day planned with no doors is what says the sweep is not vacuous**, and what
## measures the price of the rule at the same time. The second call is the identical call with the
## argument empty, off the same seed and the same tree, so the only thing that differs between the
## two plans is which candidates were refused. The assertion on the cost is a relationship rather
## than a count: refusing this ground has to stay something a day absorbs by putting the row
## somewhere else, never something that empties it.
func _test_nothing_the_day_places_reaches_into_a_doors_gap(t) -> void:
	var days: Array[int] = [Tuning.REGION_WALL_FIRST_DAY, Tuning.REGION_WALL_FIRST_DAY + 4]
	var kept := 0
	var loose := 0
	var found_a_door := false
	for map: CityMap in _maps.slice(0, 2):
		for day in days:
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var doors := PackedVector2Array()
			for body in RegionPlanner.plan_day(map, day, tree).door_bodies:
				doors.append(body.position)
			if doors.is_empty():
				continue
			found_a_door = true
			var guarded := _planned_day(map, day, tree, doors)
			var ungraded := _planned_day(map, day, tree, PackedVector2Array())
			kept += _placed_count(guarded)
			loose += _placed_count(ungraded)
			var inside := 0
			for plan in guarded:
				if not plan.is_placed():
					continue
				if not EventScheduler.clear_of_the_doors(plan.position, plan.path, doors,
						plan.def.field_reach()):
					inside += 1
			var inside_before := 0
			for plan in ungraded:
				if not plan.is_placed():
					continue
				if not EventScheduler.clear_of_the_doors(plan.position, plan.path, doors,
						plan.def.field_reach()):
					inside_before += 1
			t.check(inside == 0,
					"seed %d day %d: nothing the day placed reaches inside a door's %.0fpx gap "
					% [map.seed_used, day, Tuning.CHECKPOINT_EVENT_GAP] + "(%d of %d)"
					% [inside, _placed_count(guarded)])
			t.check(inside_before > 0,
					("seed %d day %d: and the same day planned without the gap puts %d there — " +
					"otherwise this sweep is checking nothing")
					% [map.seed_used, day, inside_before])
	t.check(found_a_door, "the sampled days actually carry doors to keep clear of")
	t.check(kept >= int(round(0.9 * float(loose))),
			("the gap costs the day almost nothing: %d placed with it against %d without, and a " +
			"refusal that emptied a day would be a density change rather than a spacing rule")
			% [kept, loose])

## One day's catalogue placements against `doors`, with a rig's empty run history — the same call
## `EventManager.start_day()` makes, minus the scars and settled calm a real run carries.
func _planned_day(map: CityMap, day: int, tree: RouteTree,
		doors: PackedVector2Array) -> Array[EventScheduler.Planned]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("checkpoint-gap:%d:%d" % [map.seed_used, day])
	var consumed: Array[String] = []
	var scars: Array[Dictionary] = []
	var used_calm: Array[Vector2i] = []
	return EventScheduler.build_day(day, rng, map, consumed, scars, used_calm, tree, 0, doors)

func _placed_count(plans: Array[EventScheduler.Planned]) -> int:
	var total := 0
	for plan in plans:
		if plan.is_placed():
			total += 1
	return total

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

## A whole street door across an east-west street at (5200, 5200) — the northern hut, the gate and
## the southern hut, a tile apart across the street, the geometry `RegionPlanner._add_door_bodies`
## builds — in a manager with a real stroller. `_free_door_rig()` frees all of it.
func _door_rig(t) -> Dictionary:
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
	return {"manager": manager, "stroller": stroller, "doors": doors}

func _free_door_rig(rig: Dictionary) -> void:
	for door: EventInstance in rig["doors"]:
		door.free()
	(rig["stroller"] as Stroller).free()
	(rig["manager"] as EventManager).free()

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

## A `WorldContext` answering out of one `EventManager`, so a real `Baby` can be driven against the
## same sum the game's own `City` builds — `Baby._ready()` finds it by the `world` group, which
## `WorldContext._ready()` puts it in.
##
## **It forwards `excitement_sources_at()` rather than reimplementing it**, which is the whole
## point: the rule under test (a hold silences everything else) lives in that function, and a rig
## that summed the instances itself would pass whatever the game did.
class _DoorWorld extends WorldContext:
	var manager: EventManager
	func excitement_sources_at(world_position: Vector2) -> Array:
		return manager.excitement_sources_at(world_position)
	func total_excitement_at(world_position: Vector2) -> float:
		return manager.total_excitement_at(world_position)

## **The hold charges its toll and nothing else.** She is inside the hut for those two seconds, not
## on the pavement, so a door standing beside a loud field has to cost exactly what a door standing
## on a quiet street costs — *"it works in both directions with the same cost each time"*. A
## `roadblock` is parked across the corner at its full rate to make the rig mean something.
##
## **What makes it mean something is stated over what this rig could see**, not over the toll. With
## the fields left running through the hold, the roadblock alone would land its rate times the two
## seconds of the hold on top of the toll — and the assertion below reads the toll to within
## `TOLL_TOLERANCE`, so the leak has to be several times that or a rig that measured nothing would
## look identical to one that measured the rule. Said against the toll instead, the guard was
## really asking the roadblock to be louder than a door, which is a balance decision it has no
## business holding: it went red when `roadblock` dropped to 9/s on a leak it would still have
## caught twelve times over.
func _test_the_hold_charges_only_its_toll(t) -> void:
	var world := _DoorWorld.new()
	t.add_child(world)
	var manager := _manager(t)
	world.manager = manager
	var stroller := _real_stroller(t)
	manager._player = stroller
	var baby := stroller.get_node_or_null("Baby") as Baby
	t.check(baby != null, "the real stroller carries the Baby whose meter this reads")
	stroller.set_physics_process(false)
	baby.set_physics_process(false)

	var axis := Vector2.RIGHT
	var centre := Vector2(5200.0, 5200.0)
	var hut := _door_instance(t, "checkpoint_hut", centre, axis)
	manager._instances.append(hut)
	var loud := _door_instance(t, "roadblock", centre + Vector2(0.0, 72.0), axis)
	# Past its own telegraph, so the field it is standing there with is the field it declares.
	loud.age = loud.def.telegraph_time + 1.0
	manager._instances.append(loud)

	var entry := centre + axis * 60.0
	stroller.global_position = entry
	manager._tell_them_where_she_is()
	var beside_it := loud.contribution_at(entry)
	var would_leak := beside_it * Tuning.CHECKPOINT_DETAIN_SECONDS
	t.check(would_leak > TOLL_TOLERANCE * 4.0,
			("a leak would be worth %.1f points of the roadblock beside the door over the hold, " +
			"well past the %.1f this rig reads the toll to — otherwise it checks nothing")
			% [would_leak, TOLL_TOLERANCE])

	var before := baby.excitement
	manager._check_detentions()
	t.check(hut.is_chatting(), "walking up to the hut starts the hold")
	# The baby's own frame before the instances', so every frame the meter takes is a frame the
	# hold was actually running: the clock runs out inside `EventInstance._process()`, and a baby
	# stepped after it would spend its last frame outside a hold that had just ended.
	var guard := int(round(Tuning.CHECKPOINT_DETAIN_SECONDS / STEP)) + 10
	while hut.is_chatting() and guard > 0:
		guard -= 1
		baby._physics_process(STEP)
		for instance in manager._instances:
			instance._process(STEP)
	t.check(not hut.is_chatting() and guard > 0, "and it runs its own clock out")
	t.close_to(baby.excitement - before, Tuning.CHAT_EXCITEMENT,
			"the whole crossing costs the toll and nothing else (%.1f against %.0f)"
			% [baby.excitement - before, Tuning.CHAT_EXCITEMENT], TOLL_TOLERANCE)
	t.close_to(loud.landed(), 0.0,
			"and nothing of it is attributed to the roadblock beside the door (%.1f)"
			% loud.landed(), 0.01)

	# And the moment she is out, the street is back: the silence is a fact about being inside a
	# door, not a shield the door leaves behind it.
	manager._check_detentions()
	manager._tell_them_where_she_is()
	t.check(manager.total_excitement_at(stroller.global_position) > 0.0,
			"released, the fields around the door charge her again")

	hut.free()
	loud.free()
	stroller.free()
	world.free()
	manager.free()

## **A wall and the door beside it are one barrier, not five.** *(2026-09-20, the player: "since
## two gates can be adjacent to each other their influence shouldn't add up".)* The rig is the
## corner day 7 of the run died at: a region wall's three `roadblock` bodies a tile apart across
## one street, and a door's hut and gate across the cross street, with her standing where the
## release sets her down.
##
## Three things have to agree, and the point of holding them together is that they are three
## different code paths reading one answer: the meter's own sum, what each body's `landed()` says
## it did, and which of them the halo would draw a rim on.
func _test_a_boundarys_structures_charge_as_one(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller
	var axis := Vector2.RIGHT

	var here := Vector2(6400.0, 6400.0)
	var kit: Array[EventInstance] = []
	for i in 3:
		var block := _door_instance(t, "roadblock", here + Vector2(-56.0, -32.0 + i * 32.0), axis)
		block.age = block.def.telegraph_time + 1.0
		kit.append(block)
	kit.append(_door_instance(t, "checkpoint_hut", here + Vector2(0.0, 54.0), axis))
	kit.append(_door_instance(t, "checkpoint_gate", here + Vector2(64.0, 54.0), axis))
	var summed := 0.0
	var strongest := 0.0
	for body in kit:
		manager._instances.append(body)
		var rate := body.contribution_at(here)
		summed += rate
		strongest = maxf(strongest, rate)
	t.check(summed > strongest * 1.5,
			("the rig actually overlaps: summed %.1f/s against the strongest single %.1f/s — a " +
			"corner where nothing overlapped would pass this test with the rule deleted")
			% [summed, strongest])

	stroller.global_position = here
	manager._tell_them_where_she_is()
	t.close_to(manager.total_excitement_at(here), strongest,
			"the whole boundary kit charges the strongest of it and not the sum (%.1f/s against a "
			% manager.total_excitement_at(here) + "sum of %.1f/s)" % summed, 0.01)

	var landed_on: Array = []
	for pair in manager.excitement_sources_at(here):
		landed_on.append(pair[0])
	t.check(landed_on.size() == 1, "one source reaches the bar, not five (%d)" % landed_on.size())
	if landed_on.size() == 1:
		t.close_to(landed_on[0].contribution_at(here), strongest,
				"and it is the one that was the maximum, which is what its own landed() will "
				+ "carry and what the halo's colour is traced from", 0.01)

	var picked := ExcitementHalo.select_sources(kit, here)
	t.check(picked.size() == 1,
			("and the halo draws one rim, on that same body: a rim on a structure landing nothing " +
			"while its neighbour reads red is a cue disagreeing with the bar (%d picked)")
			% picked.size())

	# Walk her to the other end of the wall and the answer follows her: this is a maximum at a
	# position, not a body elected once.
	stroller.global_position = kit[0].global_position + Vector2(0.0, -24.0)
	manager._tell_them_where_she_is()
	var now_strongest := 0.0
	for body in kit:
		now_strongest = maxf(now_strongest, body.contribution_at(stroller.global_position))
	t.close_to(manager.total_excitement_at(stroller.global_position), now_strongest,
			"and a step along the wall re-asks it rather than keeping the first answer", 0.01)

	for body in kit:
		body.free()
	stroller.free()
	manager.free()

## **A corner where two doors meet is still one toll.** *"going into a hut at a corner with two
## huts double counts the influence"* — a street door on one street and another on the street
## crossing it stand their bodies a tile or two apart, so the ground the first one lets her out
## onto is inside the second one's trigger. `_latch_everything_she_was_let_out_into()` arms a
## latch for **every** redetaining body whose reach covers the release point, not only the door
## that let her out, and the other door is exactly the case that reads as being taken straight
## back in.
func _test_a_corner_of_two_doors_is_one_toll(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	# One door across an east-west street, and the corner door across the north-south street it
	# meets — its own huts facing along the other axis, the geometry `RegionPlanner._along_axis()`
	# gives a crossing on each.
	var corner := Vector2(6800.0, 6800.0)
	var near_hut := _door_instance(t, "checkpoint_hut", corner, Vector2.RIGHT)
	var cross_hut := _door_instance(t, "checkpoint_hut", corner + Vector2(0.0, -48.0), Vector2.DOWN)
	var cross_gate := _door_instance(t, "checkpoint_gate", corner + Vector2(0.0, -80.0), Vector2.DOWN)
	manager._instances.append(near_hut)
	manager._instances.append(cross_hut)
	manager._instances.append(cross_gate)

	stroller.global_position = corner + Vector2.RIGHT * 60.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(near_hut.is_chatting(), "walking into the near hut starts one hold")
	t.check(not cross_hut.is_chatting() and not cross_gate.is_chatting(),
			"and the corner door's own bodies do not start a second one on top of it")

	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS)
	var released := stroller.global_position
	var reached_by_the_other := cross_hut.global_position.distance_to(released) \
			<= cross_hut.def.detain_distance() \
			or cross_gate.global_position.distance_to(released) <= cross_gate.def.detain_distance()
	t.check(reached_by_the_other,
			("the release lands inside the corner door's own reach (%.1fpx from its hut, trigger " +
			"%.1fpx) — otherwise this test is not about a corner at all")
			% [cross_hut.global_position.distance_to(released), cross_hut.def.detain_distance()])

	_advance_chat(manager, Tuning.CHECKPOINT_DETAIN_SECONDS * 3.0)
	t.check(not cross_hut.is_chatting() and not cross_gate.is_chatting(),
			"and standing where she was let out is not a second toll paid to the door round the "
			+ "corner, however long she stands there")
	t.check(not near_hut.is_chatting(), "nor to the one that let her out")
	t.check(stroller.global_position.is_equal_approx(released),
			"and she is not moved again (%s)" % stroller.global_position)

	near_hut.free()
	cross_hut.free()
	cross_gate.free()
	stroller.free()
	manager.free()

## **She reappears where she is let out, never for a frame where she went in** — *(2026-09-20, the
## player: "when I reappear I briefly spawn at my old location before teleporting to the new
## location. I should directly spawn at the new location".)*
##
## The two halves ran on two clocks: a hold's own seconds run down in `EventInstance._process()`, a
## **drawn** frame, and the teleport is in `EventManager._physics_process()`. Un-hiding her where
## the clock ran out therefore put her back on the screen at the place she went in for every frame
## drawn before the next physics tick — at least one, and more the faster the machine draws.
##
## **So the rig drives the two clocks apart, which is the only way a test can see it.** Every other
## rig in this suite steps `_process()` and `_check_detentions()` together in one loop, where the
## fault is a frame wide and invisible; here the drawn frames run alone until the hold is over, and
## what is asserted is that no drawn frame in that gap has her visible anywhere.
func _test_she_is_never_drawn_at_the_place_she_went_in(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.RIGHT
	var centre := Vector2(7200.0, 7200.0)
	var hut := _door_instance(t, "checkpoint_hut", centre, axis)
	manager._instances.append(hut)

	var entry := centre + axis * 60.0 + Vector2(0.0, 16.0)
	stroller.global_position = entry
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(hut.is_chatting() and not stroller.visible, "she goes in for the hold")

	# Drawn frames only. The hold ends inside one of these and nothing here moves her.
	var drawn := int(round(Tuning.CHECKPOINT_DETAIN_SECONDS / STEP)) + 10
	var seen_visible_at_the_entry := false
	for i in drawn:
		hut._process(STEP)
		if stroller.visible and stroller.global_position.is_equal_approx(entry):
			seen_visible_at_the_entry = true
	t.check(not hut.is_chatting(), "the hold's own clock runs out on a drawn frame")
	t.check(not seen_visible_at_the_entry,
			"and no drawn frame between that and the release has her back at the place she went in")
	t.check(not stroller.visible, "she is still inside as far as the screen is concerned")
	t.check(stroller.global_position.is_equal_approx(entry),
			"and nothing has moved her yet, which is what makes the frame above worth checking")

	# The physics frame that owns the release: moved, then shown, in that order.
	manager._check_detentions()
	t.check(stroller.visible, "the release is what shows her again")
	t.check(not stroller.global_position.is_equal_approx(entry),
			"and she is already on the far side of the door the frame it does (%s against %s)"
			% [stroller.global_position, entry])
	t.check((stroller.global_position - centre).dot(axis) < 0.0,
			"on the side the release put her, not the one she walked in from")

	hut.free()
	stroller.free()
	manager.free()

# ------------------------------------------------- the ground she is let out onto ---
# **A door cannot be refused or moved, so what is checked is what stands beside it.** A door is
# exactly a boundary crossing the day's `RouteTree` uses — `RegionPlanner.plan_day()`, "the tree
# wins, unconditionally" — so refusing one turns it into a wall across a street a route needs, and
# a region edge may never affect a path. `docs/TODO.md`'s own item offers the other half as the
# alternative and that is what is built: *"or the things that make it so are not placed beside
# it"*, which is `Tuning.CHECKPOINT_EVENT_GAP`, plus the boundary kit charging as one source.
#
# With those two in, the release point is survivable **by construction**, and the sweep below is
# what proves it over real cities rather than by argument:
#
# - She arrives at the toll, `Tuning.CHAT_EXCITEMENT`, and nothing else was charged during the hold.
# - Out to the gap's edge, no catalogue row's field can reach her — that is what the gap *is*.
# - The only things that can reach her there are the boundary's own structures, and they charge as
#   one: the strongest is `roadblock` at `intensity` 13, so the ceiling is one row's peak.
# - Walking pays back `EXCITEMENT_DECAY_WALKING` times the ground, worst case the main road's
#   0.35 multiplier.
#
# **Deliberately conservative wherever it can be.** Full peak with no telegraph damping and no
# pulse envelope; the worst ground in the city under her the whole way; a mover treated as standing
# at the nearest point of its whole route; and a segment field read as a disc grown by its own
# `half_length`, which over-reads off the spine rather than under-reading along it. A bound that
# holds here holds for the real thing.

## The summed field of a day's plan at a point, with the boundary kit collapsed to its strongest —
## the same rule `EventManager.excitement_sources_at()` applies, read off plans rather than live
## instances so a whole day can be swept without streaming it in.
func _planned_field_at(plans: Array[EventScheduler.Planned], at: Vector2) -> float:
	var total := 0.0
	var strongest := 0.0
	for plan in plans:
		if not plan.is_placed() or plan.def.intensity <= 0.0:
			continue
		var gap := plan.distance_from(at)
		if plan.def.shape != null and plan.def.shape.kind == GroundShape.Kind.SEGMENT:
			# The field is a capsule about the body's own spine. Read as a disc grown by the spine's
			# half length, which is the conservative direction: too loud off the axis, never too
			# quiet along it.
			gap = maxf(0.0, gap - plan.def.shape.half_length)
		if gap > plan.def.outer_radius:
			continue
		var rate := plan.def.emission_at_distance(gap)
		if plan.def.barrier_structure:
			strongest = maxf(strongest, rate)
		else:
			total += rate
	return total + strongest

## Walks her out of a door from `from` along `heading`, starting at the toll, and answers the
## highest the meter ever reaches before she is clear of the door's own gap. Decay at the worst
## ground in the city, so the answer is a ceiling rather than a measurement of one street.
func _peak_walking_out(plans: Array[EventScheduler.Planned], from: Vector2,
		heading: Vector2) -> float:
	var decay := Tuning.EXCITEMENT_DECAY_WALKING * Tuning.EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER
	var step := 4.0
	var seconds_per_step := step / Tuning.WALK_SPEED
	# Only what could possibly reach any point of this walk. A whole day is several hundred plans
	# and the walk asks at forty-odd points; filtering once against the far end of the walk plus the
	# row's own reach costs one distance check each and leaves a handful.
	var near: Array[EventScheduler.Planned] = []
	for plan in plans:
		if not plan.is_placed() or plan.def.intensity <= 0.0:
			continue
		if plan.distance_from(from) <= Tuning.CHECKPOINT_EVENT_GAP + plan.def.field_reach():
			near.append(plan)
	var meter := Tuning.CHAT_EXCITEMENT
	var peak := meter
	var walked := 0.0
	while walked <= Tuning.CHECKPOINT_EVENT_GAP:
		var here := from + heading * walked
		meter = maxf(0.0, meter + (_planned_field_at(near, here) - decay) * seconds_per_step)
		peak = maxf(peak, meter)
		walked += step
	return peak

## The release points a door body has: `Tuning.CHECKPOINT_RELEASE_MARGIN` past its own solid edge
## on each side of the crossing, sampled across the pavement band because the release preserves
## whatever cross-street offset she walked in on.
func _release_points(body: EventScheduler.Planned) -> Array[Vector2]:
	var axis: Vector2 = body.facing
	var across := Vector2(-axis.y, axis.x)
	var clearance := body.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
			+ Tuning.CHECKPOINT_RELEASE_MARGIN
	var points: Array[Vector2] = []
	for side in [-1.0, 1.0]:
		for lane in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			points.append(body.position + axis * side * clearance
					+ across * lane * float(Tuning.TILE_SIZE))
	return points

## **A gate never lets her out into something that kills her at once.** Swept over real days: every
## door body, both sides, five lanes across, walked out of the door's own gap from the toll.
##
## **And the same days planned without the gap are what says the sweep is not vacuous.** The run
## this milestone comes from was let out at 72 and crying 0.4s later, so the unguarded number has to
## be able to break the same bound — a sweep whose "before" also passed would be measuring nothing.
func _test_the_ground_she_is_let_out_onto_is_survivable(t) -> void:
	var days: Array[int] = [Tuning.REGION_WALL_FIRST_DAY, Tuning.REGION_WALL_FIRST_DAY + 4]
	var worst_guarded := 0.0
	var worst_unguarded := 0.0
	var releases := 0
	var unguarded_over := 0
	for map: CityMap in _maps.slice(0, 2):
		for day in days:
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var region := RegionPlanner.plan_day(map, day, tree)
			if region.door_bodies.is_empty():
				continue
			var doors := PackedVector2Array()
			for body in region.door_bodies:
				doors.append(body.position)
			var guarded := _planned_day(map, day, tree, doors)
			var unguarded := _planned_day(map, day, tree, PackedVector2Array())
			# The wall and the door structure stand whatever the catalogue was allowed to place, so
			# both plans carry them — otherwise the "before" would be missing the very barriers the
			# non-additive rule is about.
			guarded.append_array(region.wall_bodies)
			guarded.append_array(region.door_bodies)
			unguarded.append_array(region.wall_bodies)
			unguarded.append_array(region.door_bodies)
			for body in region.door_bodies:
				for point in _release_points(body):
					var heading := (point - body.position).normalized()
					releases += 1
					worst_guarded = maxf(worst_guarded, _peak_walking_out(guarded, point, heading))
					var loose := _peak_walking_out(unguarded, point, heading)
					worst_unguarded = maxf(worst_unguarded, loose)
					if loose >= Tuning.METER_MAX:
						unguarded_over += 1
	print("[test_checkpoints] walking out of %d release points from the toll: peak %.1f with the "
			% [releases, worst_guarded] + "gap, %.1f without (%d of them over %.0f)"
			% [worst_unguarded, unguarded_over, Tuning.METER_MAX])
	t.check(releases > 0, "the sampled days put release points on the map to walk out of (%d)"
			% releases)
	t.check(worst_guarded < Tuning.METER_MAX,
			("walking out of every door on every sampled day, from the toll and on the worst " +
			"ground in the city, the meter peaks at %.1f against %.0f")
			% [worst_guarded, Tuning.METER_MAX])
	t.check(unguarded_over > 0,
			("and the same days without the gap put %d of %d release points over it, peaking at " +
			"%.1f — otherwise this sweep is checking nothing")
			% [unguarded_over, releases, worst_unguarded])

## **The shape of the run that ended day 7 five times, as a regression.** She was let out on the
## north side of a `checkpoint_hut` 57, 61 and 112px from three `roadblock`s of the region wall
## on the cross street, with a `police_patrol` 66px off, taking 54/s and crying within half a
## second.
##
## Two different rules answer the two halves of it, and the test holds both:
##
## - **The patrol is refused.** It is a catalogue placement, so the gap keeps it out — and the
##   check is asked of the rule itself, at the distance the run actually put it at.
## - **The barriers are not**, and cannot be: they are the region wall, they stand where the
##   boundary is, and dropping one opens a street the partition means to hold. What makes them
##   survivable is that all four bodies are one source.
func _test_the_run_that_killed_her_five_times(t) -> void:
	var axis := Vector2.RIGHT
	var hut_at := Vector2(8000.0, 8000.0)
	var hut := EventScheduler.Planned.new(EventCatalogue.by_id("checkpoint_hut"), hut_at)
	hut.facing = axis
	var clearance := hut.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
			+ Tuning.CHECKPOINT_RELEASE_MARGIN
	# Let out on the north side, the way the run was.
	var released := hut_at + Vector2(0.0, -clearance)

	var plans: Array[EventScheduler.Planned] = [hut]
	var wall := EventCatalogue.by_id("roadblock")
	for distance in [57.0, 61.0, 112.0]:
		plans.append(EventScheduler.Planned.new(wall,
				released + Vector2(-distance, 0.0)))

	var patrol := EventCatalogue.by_id("police_patrol")
	var patrol_at := released + Vector2(0.0, -66.0)
	var doors := PackedVector2Array([hut_at])
	t.check(not EventScheduler.clear_of_the_doors(patrol_at, PackedVector2Array(), doors,
			patrol.field_reach()),
			("a police_patrol 66px off the release point is refused at placement: %.0fpx from the " +
			"hut against a gap of %.0f plus its own %.0fpx of field")
			% [patrol_at.distance_to(hut_at), Tuning.CHECKPOINT_EVENT_GAP, patrol.field_reach()])

	var summed := 0.0
	for plan in plans:
		if plan.def.barrier_structure:
			summed += plan.def.emission_at_distance(maxf(0.0,
					plan.position.distance_to(released)
					- (plan.def.shape.half_length if plan.def.shape.kind
					== GroundShape.Kind.SEGMENT else 0.0)))
	var one_source := _planned_field_at(plans, released)
	t.check(summed > one_source * 1.8,
			("the four barriers summed are %.1f/s where the strongest alone is %.1f/s — the run " +
			"took the first number") % [summed, one_source])

	var peak := _peak_walking_out(plans, released, Vector2.UP)
	t.check(peak < Tuning.METER_MAX,
			("and walking straight out of it from the toll, on the worst ground in the city, the " +
			"meter peaks at %.1f against %.0f") % [peak, Tuning.METER_MAX])

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
	# docs/DECISIONS.md, M141, the physics tick at thirty: physics interpolation forces a
	# Camera2D onto the physics tick, and its screen centre reads the interpolated transform —
	# whose previous and current tick poses are never filled in a rig that runs no physics tick.
	# `reset_physics_interpolation()` alone did not take without one; there is no tick here for it
	# to matter to, so the camera opts out the same way an untouched `_process`-driven node does.
	stroller._camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

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

## The crossing walked **across** rather than along it: she comes up to a hut from the frontage
## behind it, so at the moment of capture she is exactly level with the body along the street.
## There is no "other side" in that direction, and the release used to multiply its clearance by
## `signf(0.0)` — which is zero, so it put her back down exactly where it found her, inside the
## trigger, to be held again the next frame for as long as she stood there. Level with the door is
## one of the two sides, picked the same way every time.
##
## Against a whole door — two huts and the gate between them — because the release has to land
## clear of every body of it: **one crossing has to be one toll**.
##
## **And stopped against the gate out on the carriageway, a few pixels off its centre line, nothing
## takes her in at all.** *(2026-09-24: "Boom shouldn't inspect her. It should block her.")* The
## huts' own triggers reach past the kerb into that road, so this is also the check that a hut does
## not reach into the carriageway its own boom spans — see `EventManager._on_a_booms_carriageway()`.
func _test_crossing_the_street_at_the_door_still_puts_her_through_it(t) -> void:
	var at_the_boom := _door_rig(t)
	var boom_manager: EventManager = at_the_boom["manager"]
	var boom_stroller: Stroller = at_the_boom["stroller"]
	boom_stroller.global_position = Vector2(5200.0, 5200.0) + Vector2(-46.0, -6.0)
	boom_manager._tell_them_where_she_is()
	boom_manager._check_detentions()
	for door: EventInstance in at_the_boom["doors"]:
		t.check(not door.is_chatting(),
				"stopped against the lowered boom on the carriageway, %s does not take her in"
				% door.def.id)
	t.check(not boom_stroller.is_detained(), "and nothing locks her controls there")
	_free_door_rig(at_the_boom)

	var entries: Array[Vector2] = [Vector2(0.0, -110.0)]
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
		var caught_by := doors[0]
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

## **The boom never inspects her, raised or lowered; it blocks her while it is down.**
## *(2026-09-24, the player: "Boom shouldn't inspect her. It should block her." · "I didn't say it
## should stay solid when it's open".)* Walked up the carriageway to the boom and stood under it in
## both positions: no hold starts at the gate or at either hut beside it, the body is solid while
## the arm is down and not while it is up — and a hut still takes her in from its own sidewalk, so
## the toll is where the guard is.
func _test_the_boom_never_inspects_her(t) -> void:
	var rig := _door_rig(t)
	var manager: EventManager = rig["manager"]
	var stroller: Stroller = rig["stroller"]
	var doors: Array[EventInstance] = []
	doors.assign(rig["doors"])
	var gate := doors[1]
	var state := RegionPlanner.GateState.new()
	state.position = gate.global_position
	gate.gate_state = state

	t.check(not gate.def.redetains and gate.def.detain_seconds <= 0.0,
			"checkpoint_gate carries no detention of its own")
	for raised: bool in [false, true]:
		state.raised = raised
		gate._let_the_body_follow_the_arm()
		t.check(gate.is_solid() == not raised,
				"the boom's body is %s while the arm is %s"
				% ["open" if raised else "solid", "up" if raised else "down"])
		for along: float in [-80.0, -46.0, -20.0, 0.0, 20.0]:
			for across: float in [-16.0, 0.0, 16.0]:
				stroller.global_position = gate.global_position + Vector2(along, across)
				manager._tell_them_where_she_is()
				manager._check_detentions()
				for door in doors:
					t.check(not door.is_chatting(),
							"arm %s, on the carriageway at (%.0f, %.0f) from the boom: %s does not "
							% ["up" if raised else "down", along, across, door.def.id]
							+ "take her in")
	t.check(not stroller.is_detained(), "and her controls are never locked there")

	stroller.global_position = doors[0].global_position + Vector2(-60.0, 0.0)
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(doors[0].is_chatting(), "while walking up the sidewalk to a hut is still its inspection")
	_free_door_rig(rig)

## **The arm never comes down on her.** A raised boom's body goes back down with the arm, so an arm
## lowered with her rig beneath it would put a solid body around her. `Crowd._stop_for_gates()`
## keeps a raised gate up while any of her rig is under it, as it does for a car within a length,
## and lowers it the moment the road and she are both clear.
func _test_the_arm_never_comes_down_on_her(t) -> void:
	var map := CityGenerator.generate(BASE_SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	var stroller := _real_stroller(t)
	city.crowd._player = stroller

	var gate := RegionPlanner.GateState.new()
	gate.position = Vector2(-5000.0, -5000.0)
	gate.raised = true
	var gates: Array[RegionPlanner.GateState] = [gate]
	city.crowd.set_gates(gates)

	stroller.global_position = gate.position + Vector2(40.0, 10.0)
	city.crowd._stop_for_gates(STEP)
	t.check(gate.raised, "with no car anywhere near it, the arm stays up while she is under it")
	stroller.global_position = gate.position + Vector2(200.0, 0.0)
	city.crowd._stop_for_gates(STEP)
	t.check(not gate.raised, "and comes down once she is out from under it")

	stroller.free()
	city.free()

## A raised boom opens the carriageway, never the hut: `checkpoint_gate` and `checkpoint_hut` share
## one crossing's `GateState` structurally (`RegionPlanner._add_door_bodies` builds one `GateState`
## per street door and hands it to the gate's own instance), but `EventManager._check_detentions()`
## never reads `gate_state` or `raised` at all — the hut's hold is `def.detain_seconds` and
## `detain_distance()` alone, so raising the boom for the cars must leave it exactly as long. Drives
## her into the hut along its own sidewalk with the door's real gate beside it marked raised and
## asserts the inspection still starts and still runs its full length.
func _test_a_raised_boom_does_not_open_the_checkpoint_for_her(t) -> void:
	var manager := _manager(t)
	var stroller := _real_stroller(t)
	manager._player = stroller

	var axis := Vector2.RIGHT
	var centre := Vector2(7000.0, 7000.0)
	var hut := _door_instance(t, "checkpoint_hut", centre, axis)
	var gate_instance := _door_instance(t, "checkpoint_gate", centre + Vector2(0.0, 64.0), axis)
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

# ------------------------------------------------------------------ under the boom ---

## A real street door — its gate and the two huts on its line, from `RegionPlanner.plan_day()` on
## a door day — stood up live in a real `City`'s manager, with a real stroller. A real city because
## what a walk under the boom sets off is added to it like any unplanned event, and asks its map for
## walkable ground.
func _street_door_rig(t) -> Dictionary:
	var day := Tuning.REGION_WALL_FIRST_DAY
	var map := CityGenerator.generate(BASE_SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	_repaint_for(map, day)
	var plan := RegionPlanner.plan_day(map, day, RouteTree.for_day(map, day))
	t.check(not plan.gates.is_empty(), "day %d on seed %d has a street door" % [day, BASE_SEED])
	var gate: EventInstance = null
	var huts: Array[EventInstance] = []
	if not plan.gates.is_empty():
		var state: RegionPlanner.GateState = plan.gates[0]
		for body in plan.door_bodies:
			if body.gate_state == state:
				gate = city.events._create(body.def, body.position, PackedVector2Array(), false,
						body.facing)
				gate.gate_state = state
				city.events._instances.append(gate)
		for body in plan.door_bodies:
			if gate and body.def.id == "checkpoint_hut" \
					and absf((body.position - gate.global_position).dot(body.facing)) <= 1.0:
				var hut := city.events._create(body.def, body.position, PackedVector2Array(),
						false, body.facing)
				city.events._instances.append(hut)
				huts.append(hut)
	var stroller := _real_stroller(t)
	city.events._player = stroller
	t.check(gate != null and huts.size() == 2,
			"the rig stood a gate and the two huts on its line (%d huts)" % huts.size())
	return {"city": city, "gate": gate, "huts": huts, "stroller": stroller}

func _free_street_door_rig(rig: Dictionary) -> void:
	(rig["stroller"] as Stroller).free()
	(rig["city"] as City).free()

## Puts her at `at` and has the manager look at the door lines, the once-a-frame check its physics
## tick runs.
func _step_her_to(rig: Dictionary, at: Vector2) -> void:
	(rig["stroller"] as Stroller).global_position = at
	(rig["city"] as City).events._watch_the_door_lines()

## **Walking under the boom is detected, not guessed.** *(2026-09-24: "The guards should start
## pursuing her in that case".)* She walks across the door's own line on the carriageway, raised
## or not — nothing asks the arm — and each crossing counts; standing short of it does not. The
## hut's own inspection, whose release sets her down across the same line, is a teleport and not a
## walk, so it counts nothing.
func _test_a_walk_under_the_boom_is_seen(t) -> void:
	var rig := _street_door_rig(t)
	var city: City = rig["city"]
	var gate: EventInstance = rig["gate"]
	var huts: Array[EventInstance] = []
	huts.assign(rig["huts"])
	if not gate or huts.size() != 2:
		_free_street_door_rig(rig)
		return
	var axis := gate.facing_now()
	var across := Vector2(-axis.y, axis.x)
	gate.gate_state.raised = true
	var lane := gate.global_position + across * 16.0
	_step_her_to(rig, lane - axis * 20.0)
	_step_her_to(rig, lane - axis * 2.0)
	t.check(city.events.walks_under_a_boom() == 0, "walking up to the line is nothing")
	_step_her_to(rig, lane + axis * 20.0)
	t.check(city.events.walks_under_a_boom() == 1, "walking across it under the boom is one")
	_step_her_to(rig, lane - axis * 20.0)
	t.check(city.events.walks_under_a_boom() == 2, "and walking back under it is another")

	var before := city.events.walks_under_a_boom()
	var hut := huts[0]
	var side := (hut.global_position - gate.global_position).normalized()
	_step_her_to(rig, hut.global_position - axis * 60.0 + side * 8.0)
	city.events._check_detentions()
	t.check(hut.is_chatting(), "walking up the sidewalk to a hut starts its inspection")
	for i in int(round(Tuning.CHECKPOINT_DETAIN_SECONDS / STEP)) + 5:
		hut._process(STEP)
		city.events._watch_the_door_lines()
		city.events._check_detentions()
	var released := (rig["stroller"] as Stroller).global_position
	t.check((released - hut.global_position).dot(axis) > 0.0, "the release sets her across the line")
	city.events._watch_the_door_lines()
	t.check(city.events.walks_under_a_boom() == before,
			"and being let through is not a walk under (%d, %d before)"
			% [city.events.walks_under_a_boom(), before])
	_free_street_door_rig(rig)
