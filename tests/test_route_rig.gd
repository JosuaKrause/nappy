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
	_test_avoid_zone_excludes_only_its_own_centre(t)
	_test_resolve_target_mark_is_todays_contact(t)
	_test_resolve_target_task_is_unavailable_before_the_mark_is_touched(t)
	_test_resolve_target_home_is_the_home_rects_centre(t)
	_test_resolve_target_spawn_reaches_devrig(t)
	_test_resolve_target_unknown_word_warns_and_answers_inf(t)
	_test_nearest_calm_excludes_ground_the_day_has_spoiled(t)
	_test_pace_does_not_advance_the_target(t)
	_test_check_settled_waits_for_asleep(t)
	_test_on_day_finished_won_still_finishes(t)
	_test_a_real_leg_walks_her_there_and_reports_it(t)
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

# --------------------------------------------------------------- _avoid_zone ---

func _test_avoid_zone_excludes_only_its_own_centre(t) -> void:
	var rig := _rig(t)
	var centre := Vector2i(10, 10)
	var zone := rig._avoid_zone(centre, 2)
	t.check(not zone.has(centre), "the avoid zone never blocks the tile she is standing on")
	t.check(zone.size() == 24, "a radius-2 ring is the 5x5 block minus its own centre (got %d)"
			% zone.size())
	t.check(zone.has(centre + Vector2i(2, 2)) and zone.has(centre + Vector2i(-2, -2)),
			"the ring reaches its full radius")
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
