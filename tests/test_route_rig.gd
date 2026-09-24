extends RefCounted
## `RouteRig` (`src/dev/route_rig.gd`) is `--route`'s own walker — docs/TODO.md, M184, "A rig
## walks the route". This suite drives its target resolution and its planning geometry directly
## against a real `City`, the way `tests/test_dev_rig.gd` already does for `DevRig`'s own
## flag-acting half, and one real leg end to end with a real `Stroller` and `Baby` so the whole
## loop — resolve, plan, walk, arrive — is proven and not only its pieces (the verify skill: "a
## rig that steps the parts is not running the whole, and the gap is silent both ways").

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
const SEED := 4242
## Day 6, "A chalk mark" — the first task day, and the smallest one whose mark is a pickup step
## rather than null, the same reason `tests/test_dev_rig.gd` picks it for `--spawn contact`.
const DAY := 6

var _city: City
var _resistance: ResistanceDirector
var _stroller: Stroller

var _saved_completed: Array[int]
var _saved_failed: Array[int]
var _saved_progress: int
var _saved_package: bool

func run(t) -> void:
	_build_day(t)
	_test_line_of_sight_refuses_a_true_diagonal(t)
	_test_line_of_sight_refuses_a_bare_road_tile(t)
	_test_line_of_sight_allows_a_crossing_tile(t)
	_test_plan_never_steps_on_a_plain_road_tile_when_the_sidewalk_reaches(t)
	_test_body_clearance_keeps_her_off_the_frontage_beside_a_kerbed_van(t)
	_test_a_replan_keeps_off_the_ground_round_what_caught_her(t)
	_test_unstick_tries_the_direction_away_from_what_caught_her_first(t)
	_test_a_door_between_two_lanes_opens_both_as_its_crossing(t)
	_test_a_plan_never_goes_through_the_boom(t)
	_test_reachable_point_near_returns_centre_when_already_open(t)
	_test_reachable_point_near_steps_off_obstructed_ground(t)
	_test_resolve_target_mark_is_todays_contact(t)
	_test_resolve_target_task_is_unavailable_before_the_mark_is_touched(t)
	_test_resolve_target_home_is_the_home_rects_centre(t)
	_test_resolve_target_spawn_reaches_devrig(t)
	_test_resolve_target_unknown_word_warns_and_answers_inf(t)
	_test_task_target_resolves_for_the_neighbor_task_on_day_10(t)
	_test_task_target_resolves_for_the_mast_task_on_day_11(t)
	_test_task_target_resolves_for_the_swing_task_on_day_12(t)
	_test_task_target_resolves_for_the_door_task_on_day_9(t)
	_test_task_target_resolves_for_the_station_door_on_the_last_night(t)
	_test_nearest_calm_excludes_ground_the_day_has_spoiled(t)
	_test_resolve_target_calm_home_prefers_the_combined_walk(t)
	_test_pace_does_not_advance_the_target(t)
	_test_check_settled_waits_for_asleep(t)
	_test_on_day_finished_won_still_finishes(t)
	_test_maybe_replan_waits_before_forcing_a_physical_maneuver(t)
	_test_a_mark_leg_follows_the_mark_when_it_moves(t)
	_test_a_mark_leg_ends_when_the_director_records_the_mark(t)
	_test_a_door_hold_is_not_a_stall_and_its_far_side_is_planned_from(t)
	_test_a_real_leg_walks_her_there_and_reports_it(t)
	_test_a_rig_run_never_walks_under_a_boom(t)
	_teardown(t)

func _rng(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, DAY, stream])
	return rng

## One day, built the way `main._start_day()` builds it — closures before events — with streaming
## off so a plan is placed with nobody near it, and the resistance run under a clean `GameState`,
## the same shape `tests/test_dev_rig.gd::_build_day()` already uses (see that file's own doc for
## why). A real `Stroller` scene is added too, parked on the doorstep — `RouteRig` reads
## `_player.global_position` for every target but `mark`/`home`, so a bare `Stroller.new()` with no
## `CollisionShape2D` would answer those honestly enough, but the one real leg this suite walks
## needs `move_and_slide()` to actually move it, which only the real scene does (see the verify
## skill).
func _build_day(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_city.events.stream_radius = INF

	var state := CityState.new()
	state.begin_day(_city.map.block_plans, DAY)
	_city.start_day(state, DAY, _rng("closures"))
	var consumed: Array[String] = []
	_city.events.start_day(DAY, _rng("events"), consumed)

	_saved_completed = GameState.completed_resistance_steps.duplicate()
	_saved_failed = GameState.failed_resistance_steps.duplicate()
	_saved_progress = GameState.resistance_progress
	_saved_package = GameState.resistance_carrying_package
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.resistance_carrying_package = false

	_resistance = ResistanceDirector.new()
	t.add_child(_resistance)
	_resistance.set_process(false)
	_resistance.setup(_city, _city.map)
	_resistance.start_day(DAY, _rng("resistance"), 300.0)

	var scene: PackedScene = STROLLER_SCENE
	_stroller = scene.instantiate()
	t.add_child(_stroller)
	_stroller.global_position = _city.map.doorstep_world_position()

func _teardown(t) -> void:
	GameState.completed_resistance_steps = _saved_completed
	GameState.failed_resistance_steps = _saved_failed
	GameState.resistance_progress = _saved_progress
	GameState.resistance_carrying_package = _saved_package
	TouchControls._set_axis(&"move_left", &"move_right", 0.0)
	TouchControls._set_axis(&"move_up", &"move_down", 0.0)
	_stroller.free()
	_resistance.free()
	_city.free()

## A bare `RouteRig` with only `_city` wired — enough for every planning-geometry method, none of
## which reads `_player`, `_baby`, `_resistance` or `_day`. `_cache_road_tiles()` is called by hand
## since `setup()` (which normally calls it) also wants a player, a baby, a resistance director and
## a day controller this suite has no use for here.
func _rig(t) -> RouteRig:
	var rig := RouteRig.new()
	t.add_child(rig)
	rig.set_physics_process(false)
	rig._city = _city
	rig._cache_road_tiles()
	return rig

## The first tile of `type` the map has, at least `margin` tiles clear of every edge, scanned
## rather than hard-coded, so a change to the generator's own layout cannot make this suite pass
## on a coincidence. The margin keeps `_line_of_sight()`'s own perpendicular clearance samples
## (`_LINE_OF_SIGHT_CLEARANCE`, 24px, under one tile) from stepping off the map, which reads as
## refused ground for the same reason a real wall would. `t.check`s that one exists rather than
## crashing on `Vector2i(-1, -1)` if a future seed or a future generator ever ran out.
func _find_tile(t, type: GameEnums.TileType, margin: int = 3) -> Vector2i:
	for y in range(margin, _city.map.size.y - margin):
		for x in range(margin, _city.map.size.x - margin):
			var tile := Vector2i(x, y)
			if _city.map.tile_at(tile) == type:
				return tile
	t.check(false, "seed %d day %d has a %s tile to test against, clear of the map edge"
			% [SEED, DAY, type])
	return Vector2i(-1, -1)

# ------------------------------------------------------------- _line_of_sight ---

## The structural guarantee itself: two tiles that differ on both axes are refused outright,
## whatever ground lies between them — see `_line_of_sight()`'s own doc for the corner a sampled
## diagonal cannot see (`ReachabilityGrid`'s own two-components case). Home's own doorstep and the
## tile diagonally next to it are both certainly open, which is what makes this a test of the rule
## and not of the ground.
func _test_line_of_sight_refuses_a_true_diagonal(t) -> void:
	var rig := _rig(t)
	var a := _city.map.world_to_tile(_city.map.doorstep_world_position())
	var b := a + Vector2i(1, 1)
	t.check(not rig._line_of_sight(a, b),
			"a true diagonal (%s to %s) is refused before anything is sampled" % [a, b])
	rig.free()

## A straight run onto a plain `ROAD` tile is refused even when every sampled point along it reads
## open — the rule is about the tile *type*, not about what is in the way of it.
func _test_line_of_sight_refuses_a_bare_road_tile(t) -> void:
	var rig := _rig(t)
	var road := _find_tile(t, GameEnums.TileType.ROAD)
	if road == Vector2i(-1, -1):
		rig.free()
		return
	# Along one axis only, so the diagonal refusal above cannot be what answers this.
	var beside := road + Vector2i(1, 0)
	t.check(not rig._line_of_sight(beside, road),
			"a straight cut onto a plain ROAD tile (%s) is refused" % road)
	rig.free()

## A `CROSSING` tile (a zebra) is not refused the way a plain `ROAD` tile is — crossing there is
## the legal way over the carriageway, which is the entire point of hugging the kerb rather than
## simply refusing every carriageway tile outright.
func _test_line_of_sight_allows_a_crossing_tile(t) -> void:
	var rig := _rig(t)
	var crossing := _find_tile(t, GameEnums.TileType.CROSSING)
	if crossing == Vector2i(-1, -1):
		rig.free()
		return
	var beside := crossing + Vector2i(1, 0)
	if _city.map.is_open(beside) and not _city.map.is_obstructed(beside) \
			and _city.map.tile_at(beside) != GameEnums.TileType.ROAD:
		t.check(rig._line_of_sight(beside, crossing),
				"a straight cut onto a CROSSING tile (%s) is not refused the way a ROAD tile is"
				% crossing)
	rig.free()

# ------------------------------------------------------------------- _plan ---

## `_plan()`'s own contract, checked end to end rather than by re-deriving the algorithm: every
## tile of the finished route from the doorstep to the nearest calm tile is either open ground that
## is not `ROAD`, or (where the sidewalk-only graph could not otherwise reach it) a tile the route
## has no choice about. On a seed with a calm tile ordinarily reachable on foot — every seed
## `tests/test_route_tree.gd` already requires one for — the sidewalk-only phase answers first, so
## nothing here should be `ROAD` at all.
func _test_plan_never_steps_on_a_plain_road_tile_when_the_sidewalk_reaches(t) -> void:
	var rig := _rig(t)
	var here := _city.map.world_to_tile(_city.map.doorstep_world_position())
	var calm := _city.map.calm_tiles()
	t.check(not calm.is_empty(), "day %d has calm ground to route to" % DAY)
	if calm.is_empty():
		rig.free()
		return
	var nearest := calm[0]
	var best := _city.map.distance_at(_city.map.walk_field(here), nearest)
	for tile in calm:
		var distance := _city.map.distance_at(_city.map.walk_field(here), tile)
		if distance >= 0 and (best < 0 or distance < best):
			best = distance
			nearest = tile
	var path := rig._plan(here, nearest)
	t.check(not path.is_empty(), "a path from the doorstep to the nearest calm tile exists")
	var road_steps := 0
	for tile in path:
		if _city.map.tile_at(tile) == GameEnums.TileType.ROAD:
			road_steps += 1
	t.check(road_steps == 0,
			"the route to calm ground takes no plain ROAD tile when the sidewalk graph reaches it (%d found)"
			% road_steps)
	rig.free()

# ---------------------------------------------------------------- bodies ---

## A kerb tile with a two-lane pavement behind it and a building behind that, the carriageway in
## front, and the same on the three tiles either side along the street — the site a `delivery_van`
## (`pavement_side = AT_THE_KERB`) is parked on — far enough from the doorstep that nothing this
## suite walks passes it, and with no live body's clearance already reaching its frontage tile.
## Scanned rather than hard-coded, like `_find_tile()`. Answers `Vector2i(-1, -1)` if none.
func _find_kerb_site(t, rig: RouteRig) -> Vector2i:
	var doorstep := _city.map.world_to_tile(_city.map.doorstep_world_position())
	var clear := rig._body_clear_tiles()
	for y in range(4, _city.map.size.y - 4):
		for x in range(4, _city.map.size.x - 4):
			var kerb := Vector2i(x, y)
			if absi(kerb.x - doorstep.x) + absi(kerb.y - doorstep.y) < 12:
				continue
			var inward := _city.map.pavement_inward(kerb)
			if inward == Vector2i.ZERO:
				continue
			if _kerb_site_fits(kerb, inward, clear):
				return kerb
	t.check(false, "seed %d day %d has a clear kerb with a two-lane pavement to park a van at"
			% [SEED, DAY])
	return Vector2i(-1, -1)

func _kerb_site_fits(kerb: Vector2i, inward: Vector2i, clear: Dictionary) -> bool:
	var along := Vector2i(inward.y, inward.x)
	for k in range(-3, 4):
		var here := kerb + along * k
		if _city.map.pavement_inward(here) != inward \
				or _city.map.tile_at(here - inward) != GameEnums.TileType.ROAD \
				or _city.map.tile_at(here - inward * 2) != GameEnums.TileType.ROAD \
				or _city.map.tile_at(here + inward) != GameEnums.TileType.SIDEWALK \
				or _city.map.is_walkable(here + inward * 2):
			return false
		for tile: Vector2i in [here, here + inward, here - inward, here - inward * 2]:
			if not _city.map.is_open(tile) or _city.map.is_obstructed(tile) or clear.has(tile):
				return false
	return true

## The chokepoint the rig stalled at: a kerbed `delivery_van` (22px) covers only its own kerb
## tile's centre, so `CityMap.obstructed_tiles` records that tile alone — yet the frontage tile
## beside it is 10px from the van's side, under her 14px radius, and so is the carriageway's first
## lane. `_body_clear_tiles()` must keep a plan off both, and off the kerb tiles either side, while
## leaving the carriageway's second lane open: that is the way past a van at the kerb.
func _test_body_clearance_keeps_her_off_the_frontage_beside_a_kerbed_van(t) -> void:
	var rig := _rig(t)
	var kerb := _find_kerb_site(t, rig)
	if kerb == Vector2i(-1, -1):
		rig.free()
		return
	var inward := _city.map.pavement_inward(kerb)
	var along := Vector2i(inward.y, inward.x)
	var van := _city.events.spawn_extra(EventCatalogue.by_id("delivery_van"),
			_city.map.tile_to_world(kerb))
	t.check(van.is_solid(), "the van stands with a solid body")
	var frontage := kerb + inward
	t.check(_city.map.is_obstructed(kerb) and not _city.map.is_obstructed(frontage),
			"the tile record has the van's kerb tile and not the frontage tile beside it")
	var clear := rig._body_clear_tiles()
	t.check(clear.has(frontage), "the frontage tile beside the van is kept clear of")
	t.check(clear.has(kerb - inward), "the carriageway's first lane beside the van is kept clear of")
	t.check(clear.has(kerb - along) and clear.has(kerb + along),
			"the kerb tiles either side of the van are kept clear of")
	t.check(not clear.has(kerb - inward * 2), "the carriageway's second lane stays open")
	var caught := rig._tiles_near_body(van, RouteRig._CAUGHT_CLEARANCE)
	t.check(caught.has(frontage + along) and caught.has(frontage - along),
			"the ground round a van that caught her reaches past its own clearance")
	t.check(not caught.has(kerb - inward * 2),
			"and still leaves the carriageway's second lane open past it")

	var from := frontage - along * 3
	var to := frontage + along * 3
	var path := rig._plan(from, to)
	t.check(not path.is_empty(), "a plan past the van along its own pavement exists")
	t.check(rig._plan_kept_clear, "and keeps clear of every body")
	var pressed := 0
	for tile in _walked(rig._to_world(path)):
		if clear.has(tile) and tile != from and tile != to:
			pressed += 1
	t.check(pressed == 0, "no step of the plan past the van is one she cannot stand in the middle"
			+ " of (%d found)" % pressed)
	_city.events.retire(van)
	_city.map.release_obstruction(van.get_instance_id())
	rig.free()

## Every tile a walk down `waypoints` passes through, in order — `_simplify()` keeps only the ends
## of a straight run, and every run is along one row or column (`_line_of_sight()` refuses a
## diagonal), so the tiles between two waypoints are a straight line of them.
func _walked(waypoints: Array[Vector2]) -> Array[Vector2i]:
	var walked: Array[Vector2i] = []
	for i in waypoints.size():
		var a := _city.map.world_to_tile(waypoints[i])
		if i == waypoints.size() - 1:
			walked.append(a)
			break
		var b := _city.map.world_to_tile(waypoints[i + 1])
		var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
		var tile := a
		while tile != b:
			walked.append(tile)
			tile += step
	return walked

## A re-plan keeps off `_leg_avoid`, the ground round what has caught her this leg, rather than
## ringing her own position and walking her straight back to the same pinch. Pinned directly on a
## tile the ordinary plan walks through, rather than by wedging a real body, since the claim under
## test is what `_replan()` does with the zone once `_note_what_caught_her()` has filled it.
func _test_a_replan_keeps_off_the_ground_round_what_caught_her(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	var calm := rig._resolve_target("calm")
	t.check(calm != Vector2.INF, "a calm target exists for this leg")
	if calm == Vector2.INF:
		rig.free()
		return
	rig._begin_leg(calm)
	var first := _walked(rig._waypoints)
	t.check(first.size() >= 5, "the ordinary plan to calm ground has a middle to take away")
	if first.size() < 5:
		rig.free()
		return
	var pinch := first[first.size() / 2]
	rig._leg_avoid = {pinch: true}
	rig._replan()
	t.check(not rig._waypoints.is_empty() and not _walked(rig._waypoints).has(pinch),
			"the re-plan walks round the ground round what caught her (%s)" % pinch)
	rig.free()

## The maneuver starts from the compass point pointing most directly away from what caught her,
## rather than always from north — pressing into the body first spends a whole
## `_UNSTICK_TRY_SECONDS` on the one direction that cannot work.
func _test_unstick_tries_the_direction_away_from_what_caught_her_first(t) -> void:
	var rig := _rig(t)
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	rig._caught_away = Vector2.LEFT
	rig._begin_unstick()
	t.check(rig._unstick_order[0] == Vector2.LEFT, "the first direction tried is away from the body")
	t.check(rig._unstick_order[rig._unstick_order.size() - 1] == Vector2.RIGHT,
			"the last is straight back into it")
	rig._caught_away = Vector2.ZERO
	rig._begin_unstick()
	t.check(rig._unstick_order == RouteRig._UNSTICK_DIRECTIONS,
			"with nothing solid touching her, the plain compass order")
	rig.free()

# --------------------------------------------------------- _reachable_point_near ---

## **The rig never goes through a street door's boom** *(2026-09-24, the player: "The bot shouldn't
## route through the boom either way.")*: a `checkpoint_gate` stood across a straight stretch of
## road, and a plan from four tiles on one side of it to four tiles on the other, which the bare
## grid walks straight down the road through it, never steps on ground where the boom — rather
## than a hut — would be the body to take her. The gate is added to the day's plan by hand, since
## this suite's day has no region door; it is the plan `RouteRig` reads doors from.
func _test_a_plan_never_goes_through_the_boom(t) -> void:
	var road := _find_straight_road(t)
	if road == Vector2i(-1, -1):
		return
	var from := road + Vector2i(0, -4)
	var to := road + Vector2i(0, 4)
	var bare := _city.map.walk_field(from, {})
	t.check(_city.map.distance_at(bare, to) == 8,
			"the bare grid walks straight down the road from one side of the gate to the other")
	var def := SealPlanner.sealed_variant(EventCatalogue.by_id("checkpoint_gate"), true)
	var gate := EventScheduler.Planned.new(def, _city.map.tile_to_world(road))
	gate.facing = Vector2.DOWN
	gate.gate_state = RegionPlanner.GateState.new()
	_city.events._plans.append(gate)
	var rig := _rig(t)
	var reach := def.detain_distance()
	var planned := rig._plan(from, to)
	t.check(not planned.is_empty() and not _passes_within(planned, gate.position, reach),
			"a plan past a street door's boom goes round it rather than through its trigger")
	# The last resort `_plan()` falls back to gives up the hazards, the clearance and the doors'
	# reach, and still never the boom.
	var last_resort := rig._shortest(from, to, false, {}, false)
	t.check(not last_resort.is_empty() and not _passes_within(last_resort, gate.position, reach),
			"even the plan that gives up every preference goes round the boom")
	_city.events._plans.erase(gate)
	rig.free()

## Whether any tile a path steps on — every tile of each straight run between two waypoints, since
## `_simplify()` keeps only the corners — has its centre within `reach` of `point`.
func _passes_within(path: Array[Vector2i], point: Vector2, reach: float) -> bool:
	for k in path.size():
		var tile := path[k]
		var stop := path[mini(k + 1, path.size() - 1)]
		var step := (stop - tile).sign()
		while true:
			if _city.map.tile_to_world(tile).distance_to(point) <= reach:
				return true
			if tile == stop:
				break
			tile += step
	return false

## A `ROAD` tile with eight more straight down its column either side — four north, four south —
## all `ROAD` or `CROSSING`, so a plan from one end to the other has an obvious straight line.
func _find_straight_road(t) -> Vector2i:
	for y in range(6, _city.map.size.y - 6):
		for x in range(3, _city.map.size.x - 3):
			var found := true
			for k in range(-4, 5):
				var type := _city.map.tile_at(Vector2i(x, y + k))
				if (type != GameEnums.TileType.ROAD and type != GameEnums.TileType.CROSSING) \
						or not _city.map.is_open(Vector2i(x, y + k)) \
						or _city.map.is_obstructed(Vector2i(x, y + k)):
					found = false
					break
			if found:
				return Vector2i(x, y)
	t.check(false, "seed %d day %d has a straight stretch of north-south road" % [SEED, DAY])
	return Vector2i(-1, -1)

## A door body stands in the middle of its two-lane sidewalk
## (`EventInstance._centred_on_the_pavement_band()`), on the line between two lanes, so each lane's
## centre is exactly half a tile off the body's crossing axis: both lanes are the crossing, and the
## lane beside them is door reach. Read as neither, a door left no open way through its wall, so
## the plan gave up every door's reach and walked her into the hut from the side.
func _test_a_door_between_two_lanes_opens_both_as_its_crossing(t) -> void:
	var rig := _rig(t)
	var tile := _find_tile(t, GameEnums.TileType.SIDEWALK)
	var door := _city.map.tile_to_world(tile) + Vector2(Tuning.TILE_SIZE * 0.5, 0.0)
	var near := {}
	var lines := {}
	rig._add_door_reach(door, Vector2.DOWN, 90.0, near, lines)
	var ahead := Vector2i(0, 2)
	t.check(lines.has(tile + ahead) and lines.has(tile + Vector2i.RIGHT + ahead),
			"both lanes either side of a door centred between them are its crossing line")
	t.check(near.has(tile + Vector2i.LEFT + ahead) and not near.has(tile + ahead),
			"the lane beyond them is the door's reach, and a crossing lane is not")
	rig.free()

## The common case, and every any-instance task but `roadblock`: nothing is obstructed, so the
## instance's own centre is handed straight back rather than searched for.
func _test_reachable_point_near_returns_centre_when_already_open(t) -> void:
	var rig := _rig(t)
	var here := _city.map.doorstep_world_position()
	t.check(rig._reachable_point_near(here) == here,
			"open ground is returned unchanged rather than nudged to a neighbour")
	rig.free()

## The day 13 "no path to 'task'" regression: a solid row's own centre (`roadblock`'s
## `obstructs_radius`, from `GroundShape.band(60.0)`) is exactly the ground `_plan()` refuses, so
## `_nearest_live_instance()` must never hand `_begin_leg()` a target sitting inside one.
## `CityMap.obstructed_tiles` is pinned directly here — `tests/probes/m110_bodies.gd` already reads
## and rewrites it the same way — rather than spawning a real solid `EventInstance`, since the
## claim under test is what `_reachable_point_near()` does with an obstructed centre, not how a
## body gets recorded there.
func _test_reachable_point_near_steps_off_obstructed_ground(t) -> void:
	var rig := _rig(t)
	var centre_tile := _city.map.world_to_tile(_city.map.doorstep_world_position())
	# Two tiles clear of the doorstep itself, so obstructing it cannot also touch the home block's
	# own exemptions.
	var obstructed_tile := centre_tile + Vector2i(2, 0)
	t.check(_city.map.is_open(obstructed_tile) and not _city.map.is_obstructed(obstructed_tile),
			"the tile this test obstructs starts out open, or the test proves nothing")
	_city.map.obstructed_tiles[obstructed_tile] = 1
	var centre := _city.map.tile_to_world(obstructed_tile)
	var reachable := rig._reachable_point_near(centre)
	var reachable_tile := _city.map.world_to_tile(reachable)
	t.check(reachable_tile != obstructed_tile,
			"an obstructed centre is never handed back as the reachable point")
	t.check(_city.map.is_open(reachable_tile) and not _city.map.is_obstructed(reachable_tile),
			"the point found near an obstructed centre is itself open, unobstructed ground")
	_city.map.obstructed_tiles.erase(obstructed_tile)
	rig.free()

# ---------------------------------------------------------- _resolve_target ---

## `mark` is today's own contact for exactly as long as the pickup step is still on offer — day 6's
## own mark, in this suite's fixture.
func _test_resolve_target_mark_is_todays_contact(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	var step := _resistance.current_step()
	t.check(step != null and step.is_pickup, "day %d's own step on offer is the pickup mark" % DAY)
	t.check(rig._resolve_target("mark") == _resistance.contact_position(),
			"'mark' resolves to the day's own contact position")
	rig.free()

## `task` answers `Vector2.INF` until the mark that unlocks it has actually been touched — the same
## reasoning `_task_target()`'s own doc gives.
func _test_resolve_target_task_is_unavailable_before_the_mark_is_touched(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	t.check(rig._resolve_target("task") == Vector2.INF,
			"'task' is unresolved while the mark is still the step on offer")
	rig.free()

func _test_resolve_target_home_is_the_home_rects_centre(t) -> void:
	var rig := _rig(t)
	t.check(rig._resolve_target("home") == _city.map.home_world_position(),
			"'home' resolves to CityMap.home_world_position()")
	rig.free()

## `spawn:<name>` is handed straight to `DevRig.for_spawn_target()`, the same lookup `--spawn`
## itself uses — `park` is one `tests/test_dev_rig.gd` already exercises directly.
func _test_resolve_target_spawn_reaches_devrig(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	var at := rig._resolve_target("spawn:park")
	t.check(at == DevRig.for_spawn_target("park", _city, _resistance),
			"'spawn:park' resolves exactly as DevRig.for_spawn_target('park', ...) does")
	rig.free()

func _test_resolve_target_unknown_word_warns_and_answers_inf(t) -> void:
	var rig := _rig(t)
	t.check(rig._resolve_target("not-a-real-target") == Vector2.INF,
			"an unrecognised --route word answers Vector2.INF rather than guessing")
	rig.free()

# ---------------------------------------------------- 'task' per bare-point shape ---

## docs/TODO.md, M181, "the late days are timed": one `--route task` resolution test per
## `ResistanceSteps` bare-point shape (`sits_on_a_bare_point()`'s `NARROW_KINDS` plus `MAST`) and per
## `NEIGHBOR`, since all six are `is_one_place` and reach `_task_target()`'s `contact_position()`
## branch rather than `_nearest_live_instance()`'s — a step this suite's own day 6 fixture (an
## `EVENT` any-instance task) never exercises. Each builds its own day, independent of the suite's
## shared day-6 fixture (`_city`/`_resistance`/`_stroller`), since a bare-point task's own day is
## fixed by the calendar (`ResistanceSteps._build()`) and cannot be asked of day 6.

## One day's own city, resistance director and parked `Stroller`, isolated from the suite's shared
## day-6 fixture and from `GameState`'s own resistance fields — freed and restored by
## `_free_target_shape_fixture()`. Built the same way `_build_day()` builds day 6's, with `day` in
## place of the module-level `DAY` constant. `progress_at_dawn` is what `GameState.
## resistance_progress` reads as `ResistanceDirector.start_day()` runs — 0 for every ordinary day,
## `Tuning.RESISTANCE_GOAL` for the last night's own finale test, which needs `sabotage_available()`
## to hold before the step is on offer at all.
func _build_target_shape_fixture(t, day: int, progress_at_dawn: int = 0) -> Dictionary:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	city.events.stream_radius = INF

	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _rng_for_day(day, "closures"))
	var consumed: Array[String] = []
	city.events.start_day(day, _rng_for_day(day, "events"), consumed)

	var saved := {
		"completed": GameState.completed_resistance_steps.duplicate(),
		"failed": GameState.failed_resistance_steps.duplicate(),
		"progress": GameState.resistance_progress,
		"package": GameState.resistance_carrying_package,
	}
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = progress_at_dawn
	GameState.resistance_carrying_package = false

	var stroller: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(stroller)
	stroller.global_position = city.map.doorstep_world_position()

	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city, city.map)
	resistance.start_day(day, _rng_for_day(day, "resistance"), Tuning.day_length(day))

	return {"city": city, "resistance": resistance, "stroller": stroller, "saved": saved}

## The same hashed stream `_rng()` builds for the suite's shared day, for an arbitrary `day` — see
## `_build_target_shape_fixture()`.
func _rng_for_day(day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, day, stream])
	return rng

func _free_target_shape_fixture(fixture: Dictionary) -> void:
	var saved: Dictionary = fixture["saved"]
	GameState.completed_resistance_steps = saved["completed"]
	GameState.failed_resistance_steps = saved["failed"]
	GameState.resistance_progress = saved["progress"]
	GameState.resistance_carrying_package = saved["package"]
	(fixture["stroller"] as Stroller).free()
	(fixture["resistance"] as ResistanceDirector).free()
	(fixture["city"] as City).free()

## A bare-point task's own `RouteRig` for `fixture`, the same shape `_rig()` gives the suite's
## shared day, wired to `fixture`'s own `_resistance` too, since `_task_target()` reads it.
func _target_shape_rig(t, fixture: Dictionary) -> RouteRig:
	var rig := RouteRig.new()
	t.add_child(rig)
	rig.set_physics_process(false)
	rig._city = fixture["city"]
	rig._cache_road_tiles()
	rig._resistance = fixture["resistance"]
	return rig

## Touches `fixture`'s own mark (`ResistanceDirector._on_contact_completed()`, the pattern
## `tests/test_resistance.gd` already drives a mark forward with) and answers the perform step it
## unlocks.
func _touch_the_mark(fixture: Dictionary) -> ResistanceSteps.Step:
	var resistance: ResistanceDirector = fixture["resistance"]
	var mark := resistance.current_step()
	resistance._on_contact_completed(mark.index if mark else -1)
	return resistance.current_step()

## Day 10, warn the neighbor: `TargetKind.NEIGHBOR` rides the neighbor out in the city
## (`ResistanceDirector._send_the_neighbor_home()`), and `_task_target()` follows it through
## `contact_position()` exactly as it follows a `mark` that has moved.
func _test_task_target_resolves_for_the_neighbor_task_on_day_10(t) -> void:
	var fixture := _build_target_shape_fixture(t, 10)
	var mark: ResistanceSteps.Step = (fixture["resistance"] as ResistanceDirector).current_step()
	t.check(mark != null and mark.is_pickup, "day 10 offers a mark")
	var task := _touch_the_mark(fixture)
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.NEIGHBOR
			and task.is_one_place, "touching it offers the neighbor, a one-place task")
	var rig := _target_shape_rig(t, fixture)
	var resolved := rig._resolve_target("task")
	t.check(resolved != Vector2.INF
			and resolved == (fixture["resistance"] as ResistanceDirector).contact_position(),
			"'task' resolves to the neighbor's own contact position")
	rig.free()
	_free_target_shape_fixture(fixture)

## Day 11, silence a mast: `TargetKind.MAST` sits beside a live mast's own foot
## (`ResistanceDirector._place_at_a_mast()`), a bare point this director computes rather than a
## rider — the "task unavailable" this suite guards now that the calendar actually offers it.
func _test_task_target_resolves_for_the_mast_task_on_day_11(t) -> void:
	var fixture := _build_target_shape_fixture(t, 11)
	var mark: ResistanceSteps.Step = (fixture["resistance"] as ResistanceDirector).current_step()
	t.check(mark != null and mark.is_pickup, "day 11 offers a mark")
	var task := _touch_the_mark(fixture)
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.MAST
			and task.is_one_place, "touching it offers the mast, a one-place task")
	var rig := _target_shape_rig(t, fixture)
	var resolved := rig._resolve_target("task")
	t.check(resolved != Vector2.INF
			and resolved == (fixture["resistance"] as ResistanceDirector).contact_position(),
			"'task' resolves to the ground beside the mast's own foot")
	rig.free()
	_free_target_shape_fixture(fixture)

## Day 12, the swing: `TargetKind.PARK_SWING` sits at the one park the city chose for it, a bare
## point `ResistanceSteps.target_candidates()` computes from today's city.
func _test_task_target_resolves_for_the_swing_task_on_day_12(t) -> void:
	var fixture := _build_target_shape_fixture(t, 12)
	var mark: ResistanceSteps.Step = (fixture["resistance"] as ResistanceDirector).current_step()
	t.check(mark != null and mark.is_pickup, "day 12 offers a mark")
	var task := _touch_the_mark(fixture)
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING
			and task.is_one_place, "touching it offers the swing, a one-place task")
	var rig := _target_shape_rig(t, fixture)
	var resolved := rig._resolve_target("task")
	t.check(resolved != Vector2.INF
			and resolved == (fixture["resistance"] as ResistanceDirector).contact_position(),
			"'task' resolves to the swing's own point")
	rig.free()
	_free_target_shape_fixture(fixture)

## Day 9, the crossing: `TargetKind.DOOR` sits at one of today's region-wall doors, the other bare
## point `target_candidates()` computes rather than a rider.
func _test_task_target_resolves_for_the_door_task_on_day_9(t) -> void:
	var fixture := _build_target_shape_fixture(t, 9)
	var mark: ResistanceSteps.Step = (fixture["resistance"] as ResistanceDirector).current_step()
	t.check(mark != null and mark.is_pickup, "day 9 offers a mark")
	var task := _touch_the_mark(fixture)
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.DOOR
			and task.is_one_place, "touching it offers the district door, a one-place task")
	var rig := _target_shape_rig(t, fixture)
	var resolved := rig._resolve_target("task")
	t.check(resolved != Vector2.INF
			and resolved == (fixture["resistance"] as ResistanceDirector).contact_position(),
			"'task' resolves to the district door's own crossing tile")
	rig.free()
	_free_target_shape_fixture(fixture)

## The last night: `TargetKind.STATION_DOOR` is the finale, offered with no mark of its own
## (`ResistanceSteps._finale()`) and only once `GameState.sabotage_available()` holds — set here so
## the step is on offer at all, the same gate `docs/TODO.md`, M181, "the late days are timed" found
## `--day 14` alone never carries. `mark` stays `Vector2.INF` on this day (the class doc's own note).
func _test_task_target_resolves_for_the_station_door_on_the_last_night(t) -> void:
	var fixture := _build_target_shape_fixture(t, Tuning.RUN_LENGTH_DAYS, Tuning.RESISTANCE_GOAL)
	var task: ResistanceSteps.Step = (fixture["resistance"] as ResistanceDirector).current_step()
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.STATION_DOOR
			and task.is_one_place and not task.is_pickup,
			"the finale is on offer directly, with no mark, once the goal is met")
	var rig := _target_shape_rig(t, fixture)
	t.check(rig._resolve_target("mark") == Vector2.INF,
			"'mark' is unavailable on the last night, which has none")
	var resolved := rig._resolve_target("task")
	t.check(resolved != Vector2.INF
			and resolved == (fixture["resistance"] as ResistanceDirector).contact_position(),
			"'task' resolves to the power station's own front door")
	rig.free()
	_free_target_shape_fixture(fixture)

# ------------------------------------------------------------------- calm ---

## `_nearest_calm()` reads `CityMap.calm_tiles()` live, so a tile spoiled after the fixture was
## built (the day 12 shape, once the swing is reached) is never offered — pinned directly with
## `set_tile()` rather than by playing a whole day forward to spoil one for real.
func _test_nearest_calm_excludes_ground_the_day_has_spoiled(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	var first := rig._resolve_target("calm")
	t.check(first != Vector2.INF, "a calm tile is reachable from the doorstep")
	if first == Vector2.INF:
		rig.free()
		return
	var spoiled_tile := _city.map.world_to_tile(first)
	var original := _city.map.tile_at(spoiled_tile)
	_city.map.set_tile(spoiled_tile, GameEnums.TileType.SPOILED)
	var second := rig._resolve_target("calm")
	t.check(second != first,
			"once the nearest calm tile is spoiled, 'calm' answers a different one (%s vs %s)"
			% [first, second])
	_city.map.set_tile(spoiled_tile, original)
	rig.free()

## `calm:home` — docs/TODO.md, M181, "the late days are timed", item 3's rig option — answers a real
## calm tile too, and one `_nearest_in_field_toward_home()` actually scored by the combined walk
## (hers to it, and its own walk home) rather than by her walk alone: pinned directly against two
## synthetic fields, the same way `_test_line_of_sight_refuses_a_true_diagonal` pins geometry rather
## than trusting a live city to happen to need the tie-break.
func _test_resolve_target_calm_home_prefers_the_combined_walk(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	var calm_tiles := _city.map.calm_tiles()
	t.check(calm_tiles.size() >= 1, "the fixture city has at least one calm tile")
	if calm_tiles.size() < 1:
		rig.free()
		return
	# A tile near her (distance 1) but far from home (distance 100), and — if the pool has a second
	# calm tile — one far from her (distance 100) but near home (distance 1): `toward_home` must
	# answer the second, where the plain, her-only reading (`_nearest_in_field`) would answer the
	# first every time.
	var near_her := calm_tiles[0]
	var width: int = _city.map.size.x
	var height: int = _city.map.size.y
	var field := PackedInt32Array()
	var home_field := PackedInt32Array()
	field.resize(width * height)
	home_field.resize(width * height)
	field.fill(-1)
	home_field.fill(-1)
	field[near_her.y * width + near_her.x] = 1
	home_field[near_her.y * width + near_her.x] = 100
	if calm_tiles.size() >= 2:
		var near_home: Vector2i = calm_tiles[1]
		field[near_home.y * width + near_home.x] = 50
		home_field[near_home.y * width + near_home.x] = 1
		t.check(rig._nearest_in_field_toward_home(field, home_field) == near_home,
				"the combined walk (50+1=51) beats the near-her tile's own (1+100=101)")
	t.check(rig._nearest_in_field(field) == near_her,
			"the plain reading still answers the tile nearest her, for the contrast")
	rig.free()

# ------------------------------------------------------------------ settling ---

## `_pace()` presses toward the far end of its own short walk and nothing else — the regression for
## a stray `_advance_target()` once left at the end of this function, which skipped the whole point
## of settling (waiting for `Baby.state == ASLEEP`, see `_check_settled()`'s own doc) the moment
## she took her very first step of it: `calm` would "settle" in one physics frame regardless of
## whether the baby was anywhere near asleep.
func _test_pace_does_not_advance_the_target(t) -> void:
	var rig := _rig(t)
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	rig._settle_anchor = _stroller.global_position
	rig._settle_forward = true
	var before := rig._target_index
	for i in 5:
		rig._pace()
	t.check(rig._target_index == before, "pacing never advances the target on its own (%d -> %d)"
			% [before, rig._target_index])
	rig.free()

## `_check_settled()` only advances once `Baby.state` reaches `ASLEEP`, and paces meanwhile rather
## than standing — the other half of the regression above: pacing alone must never finish the leg,
## and settling must actually wait for the state the meter reports rather than a fixed number of
## calls. `Baby.force_sleep()` is the same dev affordance `--spawn` rigs already use to skip walking
## the meter up by hand.
func _test_check_settled_waits_for_asleep(t) -> void:
	var baby: Baby = _stroller.get_node("Baby")
	baby.reset()
	var rig := _rig(t)
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	rig._baby = baby
	rig._targets = ["mark", "task", "calm", "home"]
	rig._target_index = 2
	rig._settling = true
	rig._settle_anchor = _stroller.global_position
	rig._settle_forward = true
	rig._check_settled()
	t.check(rig._settling and rig._target_index == 2, "still settling while the baby is awake")
	baby.force_sleep()
	rig._check_settled()
	t.check(not rig._settling and rig._target_index == 3,
			"settling ends and the target advances once the baby is asleep")
	rig.free()

## `_on_day_finished(WON)` finishes the rig rather than treating a win as a no-op — the regression
## for the race that function's own doc now names: `DayController`'s own `WON` can fire the moment
## she is anywhere on the `HOME` tile, a looser check than `_arrive()`'s own `_ARRIVE_RADIUS` of the
## exact doorstep point, so a day can win a few pixels before `_arrive()` would have. Only
## `get_tree().quit()`'s own side effect is left unchecked here — `run_tests.gd` already calls it
## once every suite has run, so a second, earlier request from this call is harmless.
func _test_on_day_finished_won_still_finishes(t) -> void:
	var rig := _rig(t)
	rig._current_word = "home"
	t.check(not rig._done, "not finished before the signal")
	rig._on_day_finished(GameEnums.DayResult.WON)
	t.check(rig._done, "WON finishes the rig rather than being ignored")
	rig.free()

# ------------------------------------------------------------ chokepoints ---

## The chokepoint fix (docs/TODO.md, M184, "the rig gets through chokepoints"): a second stall in
## a row waits for a crowd to clear rather than reaching straight for the eight-direction maneuver,
## and only a third stall right after waiting — proof that waiting alone did not answer it — reaches
## `_begin_unstick()`. Driven directly against `_maybe_replan()` with a real leg and a real
## `Stroller` that this test never actually moves, which is exactly what a physical wedge reads as
## to the tile grid: nothing wrong with the ground, and no progress since the last check.
func _test_maybe_replan_waits_before_forcing_a_physical_maneuver(t) -> void:
	var rig := RouteRig.new()
	t.add_child(rig)
	rig.set_physics_process(false)
	rig._city = _city
	rig._cache_road_tiles()
	rig._resistance = _resistance
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller

	var calm := rig._resolve_target("calm")
	t.check(calm != Vector2.INF, "a calm target exists for this leg")
	if calm == Vector2.INF:
		rig.free()
		return
	rig._begin_leg(calm)
	t.check(not rig._waypoints.is_empty(), "the leg starts with a real plan")

	# The first check only records where she is — nothing to compare against yet.
	rig._maybe_replan(RouteRig._REPLAN_INTERVAL)
	t.check(rig._stuck_streak == 0 and not rig._waiting and not rig._unsticking,
			"the first check has no stall to read yet")

	# Second check, same position: a first stall replans the ordinary way rather than waiting or
	# forcing anything.
	rig._maybe_replan(RouteRig._REPLAN_INTERVAL)
	t.check(rig._stuck_streak == 1 and not rig._waiting and not rig._unsticking,
			"a first stall replans rather than waiting or forcing a maneuver")

	# Third check, still the same position: the ordinary replan did not move her either, so a
	# second stall in a row waits rather than reaching straight for the physical maneuver.
	rig._maybe_replan(RouteRig._REPLAN_INTERVAL)
	t.check(rig._waiting and not rig._unsticking and rig._leg_stall_episodes == 1,
			"a second stall in a row waits for a crowd to clear rather than forcing a maneuver")

	rig._wait(RouteRig._STUCK_WAIT_SECONDS)
	t.check(not rig._waiting, "waiting ends once _STUCK_WAIT_SECONDS has elapsed")

	# Still the same position: waiting alone did not answer it, so the very next check escalates
	# straight to the physical maneuver — spending no second stall episode getting there.
	rig._maybe_replan(RouteRig._REPLAN_INTERVAL)
	t.check(rig._unsticking and rig._leg_stall_episodes == 1,
			"still stuck right after waiting escalates to the physical maneuver, not a second wait")

	rig.free()

## A mark nobody has seen is moved to an alley near her (`ResistanceDirector._move_the_mark()`),
## usually on the day's first frame, after the rig has planned to where it stood at dawn — the
## day 6 seed 1234567 leg that walked the other way across the city and stalled far from any mark.
## The contact is moved by hand here, the one field the director's own move writes.
func _test_a_mark_leg_follows_the_mark_when_it_moves(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	rig._current_word = "mark"
	var dawn := _resistance.contact_position()
	rig._begin_leg(dawn)
	t.check(rig._leg_step == _resistance.current_step(), "a mark leg remembers the step it walks to")
	t.check(not rig._retarget_if_moved(), "a mark still where the leg aimed is not re-planned to")
	var moved := _city.map.home_world_position()
	_resistance._contact.global_position = moved
	t.check(rig._retarget_if_moved() and rig._current_target_world == moved,
			"a mark that has moved is re-planned to where it is now")
	_resistance._contact.global_position = dawn
	rig.free()

## A `mark` leg ends when the director records the mark completed, whatever the waypoints say —
## `ContactPoint.REACH` (36px) completes it before the last waypoint, which a body beside the mark
## can keep her from.
func _test_a_mark_leg_ends_when_the_director_records_the_mark(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	rig._targets = ["mark", "home"]
	rig._target_index = 0
	rig._current_word = "mark"
	rig._begin_leg(_resistance.contact_position())
	t.check(not rig._waypoints.is_empty(), "the mark leg has waypoints left to walk")
	var step := _resistance.current_step()
	GameState.completed_resistance_steps.append(step.index)
	rig._follow(0.0)
	t.check(rig._target_index == 1 and rig._current_word == "home",
			"the leg ends once its step is recorded completed, and the next target begins")
	GameState.completed_resistance_steps.erase(step.index)
	rig.free()

## A door's hold (`Stroller.is_detained()`) is not a stall — she stands still because a checkpoint
## is talking to her — so the stall ladder stays at its first rung however long it lasts, and the
## door setting her down on its far side (`_teleported`, a jump no step covers) re-plans from where
## she lands rather than walking her back to the stale waypoints on the side she came from.
func _test_a_door_hold_is_not_a_stall_and_its_far_side_is_planned_from(t) -> void:
	var rig := _rig(t)
	rig._resistance = _resistance
	_stroller.global_position = _city.map.doorstep_world_position()
	rig._player = _stroller
	var calm := rig._resolve_target("calm")
	t.check(calm != Vector2.INF, "a calm target exists for this leg")
	if calm == Vector2.INF:
		rig.free()
		return
	rig._begin_leg(calm)
	rig._stuck_streak = 1
	_stroller.detain(2.0)
	t.check(rig._held_at_a_door() and rig._stuck_streak == 0 and rig._stuck_reference == Vector2.INF,
			"while a door holds her the rig waits it out without counting a stall")
	_stroller._detained_for = 0.0
	var landed := _city.map.tile_to_world(_city.map.world_to_tile(calm))
	_stroller.global_position = landed
	rig._teleported = true
	rig._held_at_a_door()
	t.check(not rig._held and not rig._teleported, "the release is consumed once")
	t.check(not rig._waypoints.is_empty()
			and rig._waypoints[0].distance_to(landed) <= Tuning.TILE_SIZE,
			"the plan after the door starts where the door set her down")
	rig.free()

# ------------------------------------------------------------ end to end ---

## The whole loop, once, with a real `Stroller` and `Baby`, driven the way `tests/test_checkpoints.gd`
## drives a real rig — `set_physics_process(false)` on every node and a manual step loop, so the
## suite controls the clock rather than waiting on real time. Proves the seam end to end: resolving
## the target, planning a path, pressing the ordinary input axes, and `_arrive()` firing.
##
## **Position is integrated by hand from `_stroller.velocity` rather than left to
## `move_and_slide()`.** `Stroller._physics_process()` does compute the right `velocity` every
## step here (`RouteRig`'s own presses reach it, which is what this test is actually for), but
## `move_and_slide()`'s own displacement depends on the body's collision shape already being
## synced to the physics server — a sync this suite's manual step loop, with no real engine frame
## ever let through (`run_tests.gd` calls every suite synchronously; see `tests/test_camera_start.gd`'s
## own doc on why an `await` here is not safe), never gives it the chance to do. The same
## reasoning the verify skill gives for a bare `Stroller.new()` ("assert on velocity, not on
## position") applies a second time here as "and integrate the velocity by hand", one step further
## down the same cause.
func _test_a_real_leg_walks_her_there_and_reports_it(t) -> void:
	const STEP := 1.0 / 30.0
	const MAX_SECONDS := 30.0

	var baby: Baby = _stroller.get_node("Baby")
	_stroller.set_physics_process(false)
	baby.set_physics_process(false)
	baby.reset()

	var day := DayController.new()
	t.add_child(day)
	day.setup(_city.map, _stroller)
	day.set_process(false)
	day.start(600.0)

	var rig := RouteRig.new()
	t.add_child(rig)
	rig.set_physics_process(false)
	# 'home' rather than 'calm': the doorstep sits right on the home block's own edge, so this leg
	# is short and has nothing left to prove about `_nearest_calm()` or the baby's own settle that
	# the dedicated tests above have not already covered — what is left to prove here is the seam:
	# resolving, planning, pressing the ordinary axes, and `_arrive()` firing for real.
	rig.setup(_city, _stroller, baby, _resistance, day)
	rig._targets = ["home"]
	rig.start_day()

	var start_position := _stroller.global_position
	var done := false
	var elapsed := 0.0
	while elapsed < MAX_SECONDS:
		rig._physics_process(STEP)
		# `_stroller._physics_process()` still runs in full — the acceleration ramp, the facing
		# turn, everything but the displacement `move_and_slide()` cannot deliver here — and the
		# position it would have produced is applied by hand from the `velocity` it computed.
		_stroller._physics_process(STEP)
		_stroller.global_position += _stroller.velocity * STEP
		baby._physics_process(STEP)
		day._process(STEP)
		elapsed += STEP
		if rig._done:
			done = true
			break
	t.check(done, "a short leg to 'home' reaches _done within %.0fs of simulated time" % MAX_SECONDS)
	t.check(_stroller.global_position.distance_to(start_position) > 1.0,
			"she actually moved from the doorstep rather than the leg completing vacuously")
	t.check(_city.map.tile_type_at_world(_stroller.global_position) == GameEnums.TileType.HOME,
			"she actually stands on HOME ground once the leg reports done")

	day.day_finished.disconnect(rig._on_day_finished)
	rig.free()
	day.free()

# ------------------------------------------------------------- never under the boom ---

## **A rig run through a street door goes through a hut, never under the boom.** *(2026-09-24, the
## player: "The bot shouldn't route through the boom either way".)* A day with doors — its own city,
## since this suite's day is before the wall stands — and one real leg along the carriageway from
## one side of a street door's boom to the other, walked end to end the way the leg above is:
## the rig's own presses, her own `_physics_process()` with the position integrated by hand, the
## door's own hold clock and `EventManager`'s once-a-frame door checks. Integrated by hand means no
## collision at all, so a plan under the boom — raised or lowered — would walk straight across the
## door's line there, and `EventManager.walks_under_a_boom()` would count it. It must stay at zero
## while she ends up on the far side, held by a hut on the way, which is what says the leg crossed.
func _test_a_rig_run_never_walks_under_a_boom(t) -> void:
	const STEP := 1.0 / 30.0
	const MAX_SECONDS := 60.0
	var door_day := Tuning.REGION_WALL_FIRST_DAY
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	city.events.stream_radius = INF
	var state := CityState.new()
	state.begin_day(city.map.block_plans, door_day)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:boom-closures" % [SEED, door_day])
	city.start_day(state, door_day, rng)
	var consumed: Array[String] = []
	rng.seed = hash("%d:%d:boom-events" % [SEED, door_day])
	city.events.start_day(door_day, rng, consumed)

	var gate: EventInstance = null
	var hut: EventInstance = null
	for instance in city.events.instances():
		if instance.def.lifts_for_traffic and not gate:
			gate = instance
	if gate:
		var axis_of_gate := gate.facing_now()
		for instance in city.events.instances():
			if instance.def.id == "checkpoint_hut" and absf(
					(instance.global_position - gate.global_position).dot(axis_of_gate)) <= 1.0:
				hut = instance
				break
	t.check(gate != null and hut != null,
			"seed %d day %d stands a street door to walk through" % [SEED, door_day])
	if not gate or not hut:
		city.free()
		return
	var axis := gate.facing_now()

	var baby: Baby = _stroller.get_node("Baby")
	_stroller.set_physics_process(false)
	baby.set_physics_process(false)
	baby.reset()
	var day := DayController.new()
	t.add_child(day)
	day.setup(city.map, _stroller)
	day.set_process(false)
	day.start(600.0)
	city.events._player = _stroller

	var rig := RouteRig.new()
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.setup(city, _stroller, baby, null, day)
	rig.start_day()
	var reach := float(Tuning.TILE_SIZE) * 5.0
	# On the carriageway either side of the boom, so the straight line — and the bare grid's
	# shortest walk — is under it, and going through a hut is the detour the rig has to choose.
	var from := rig._reachable_point_near(gate.global_position - axis * reach)
	var to := rig._reachable_point_near(gate.global_position + axis * reach)
	_stroller.reset_at(from)
	rig._targets = ["home"]
	rig._target_index = 0
	rig._current_word = "home"
	rig._done = false
	rig._begin_leg(to)
	t.check(not rig._waypoints.is_empty(), "the rig plans a leg through the door")

	var held := false
	var elapsed := 0.0
	while elapsed < MAX_SECONDS and not rig._done:
		rig._physics_process(STEP)
		_stroller._physics_process(STEP)
		_stroller.global_position += _stroller.velocity * STEP
		baby._physics_process(STEP)
		for instance in city.events.instances():
			if instance.def.redetains:
				instance._process(STEP)
		city.events._watch_the_door_lines()
		city.events._check_detentions()
		held = held or _stroller.is_detained()
		elapsed += STEP
	var crossed := (_stroller.global_position - gate.global_position).dot(axis) > 0.0
	print("[test_route_rig] through the door at %s: %s after %.1fs, held %s, %d walks under" % [
		TelemetryLog.tile(city.map.world_to_tile(gate.global_position)),
		"arrived" if rig._done else "still walking", elapsed, held,
		city.events.walks_under_a_boom()])
	t.check(crossed and held,
			"she ends the leg on the far side of the door, held by a hut on the way "
			+ "(far side %s, held %s) — otherwise this run never crossed a door" % [crossed, held])
	t.check(city.events.walks_under_a_boom() == 0,
			"and the rig never walked under the boom (%d walks under)"
			% city.events.walks_under_a_boom())
	# And the same check, in the same rig, sees a walk under this boom when there is one — so the
	# zero above is the rig's route and not a check that could not have counted anything.
	var lane := gate.global_position + Vector2(-axis.y, axis.x) * 16.0
	_stroller.reset_at(lane - axis * 20.0)
	city.events._watch_the_door_lines()
	_stroller.global_position = lane + axis * 20.0
	city.events._watch_the_door_lines()
	t.check(city.events.walks_under_a_boom() == 1,
			"while walking straight along the carriageway under it is counted (%d)"
			% city.events.walks_under_a_boom())

	day.day_finished.disconnect(rig._on_day_finished)
	rig.free()
	day.free()
	city.free()
