extends RefCounted
## **What the resistance suites share** (`tests/test_resistance_*.gd`): the city each builds, the
## director over it, and the walks, views and sweeps more than one of them drives. A helper, not a
## suite: the runner loads only `test_*.gd`. Each suite extends this one and runs its own tests;
## `_city` is freed by whichever suite built it, at the end of its `run()`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")

const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

const SEED := 4242

const STEP := 1.0 / 60.0

## Maps for a sweep that asks about a *rule* rather than a *layout* — the same distinction and the
## same name `tests/test_routes.gd` and `tests/test_regions.gd` use: "no scheduled placement ever
## lands near the doorstep" is enforced by construction the same way on every city, so a second
## city tests the same guarantee against different noise rather than a different shape of it.
const RULE_SEEDS := 3

var _player: Stroller

var _contact: ContactPoint

func _build_pickup(t, step_index: int) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_player.add_child(camera)
	t.add_child(_player)
	_player.set_physics_process(false)
	_player.global_position = Vector2.ZERO

	_contact = ContactPoint.new()
	_contact.setup(ResistanceSteps.by_index(step_index), Vector2.ZERO)
	_contact.use_player(_player)
	t.add_child(_contact)
	_contact.set_physics_process(false)

var _city: City

## Freed rather than left standing: `City.build()` adds an `EventManager` child that acquires the
## "events" `AtlasLibrary` group in its own `_enter_tree()` and only gives it back in
## `_exit_tree()` (`src/events/event_manager.gd`). This suite calls `_build_city()` many times
## over, so a `_city` never freed between two calls would leave every earlier one standing —
## sixteen abandoned `City` nodes in a suite that only ever needs the latest, each holding "events"
## resident for the rest of the process. `run()` frees whichever one is still around after the
## last call.
func _build_city(t, seed_value := SEED) -> void:
	if _city != null:
		_city.free()
	_city = RunCity.of_the_run(CITY_SCENE)
	t.add_child(_city)
	_city.build(CityGenerator.generate(seed_value))

## The day's one view looked at `rect` with no corner covered, which is what the director's
## `set_sight(_city.events.sees)` and the city's siting (`DRAWING_OFF_THE_VIEW`) both read.
func _look_at(rect: Rect2) -> void:
	_city.events.visible_view().look(rect, null)

## Looks the day's view at the unrotated 640x360 screen round `her` (in the tap scheme the visible
## area is the whole view) and hands the director what she can see.
func _watch_the_screen_round(director: ResistanceDirector, her: Vector2) -> void:
	_look_at(Rect2(her - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0))
	director.set_sight(_city.events.sees)

## Today's walled-off crossing alleys, as the city's siting has them.
func _walled_alleys() -> Array[Rect2i]:
	var region := _city.spawn_siting.region()
	return region.walled_alleys if region else ([] as Array[Rect2i])

## Whether a drawing of `box` about its feet, standing at `at`, would be drawn in the camera's view.
func _would_show(box: Rect2, at: Vector2) -> bool:
	return not _city.spawn_siting.allows(SpawnSiting.Rule.DRAWING_OFF_THE_VIEW,
			_city.spawn_siting.ask_of_drawing(box), at)

func _director(t) -> ResistanceDirector:
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city, _city.map)
	return director

func _rng(day: int, stream: String, seed_value := SEED) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

func _with_clean_run(action: Callable) -> void:
	var saved_completed := GameState.resistance.completed_steps.duplicate()
	var saved_failed := GameState.resistance.failed_steps.duplicate()
	var saved_progress := GameState.resistance.progress
	var saved_package := GameState.resistance.carrying_package
	GameState.resistance.completed_steps = []
	GameState.resistance.failed_steps = []
	GameState.resistance.progress = 0
	GameState.resistance.carrying_package = false
	action.call()
	GameState.resistance.completed_steps = saved_completed
	GameState.resistance.failed_steps = saved_failed
	GameState.resistance.progress = saved_progress
	GameState.resistance.carrying_package = saved_package

## The perform step on `day` — named by its day rather than by its index, so a task added earlier
## in the calendar does not renumber every test after it.
func _perform_on(day: int) -> ResistanceSteps.Step:
	for step in ResistanceSteps.all():
		if step.day == day and not step.is_pickup and not step.needs_goal:
			return step
	return null

func _completed_through(last_index: int) -> Array[int]:
	var done: Array[int] = []
	done.assign(range(1, last_index + 1))
	return done

## Day 6's mark, started and touched — the shape most of this suite's perform-step tests now
## need, since `start_day()` alone only ever offers a mark (`ResistanceSteps.for_day()`). Returns
## the director with step 2 (the yeller perform) already active.
func _director_on_the_yeller_perform(t, seed_value := SEED) -> ResistanceDirector:
	var director := _director(t)
	director.start_day(6, _rng(6, "resistance", seed_value), 300.0)
	director._on_contact_completed(1)
	return director

func _all_but_the_finale() -> Array[int]:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if not step.needs_goal:
			done.append(step.index)
	return done

## Same shape `_build_pickup` uses for a bare `ContactPoint` — a real `Stroller`, physics off,
## which the caller hands to its director (`ResistanceDirector.use_player()`), as `main` does.
func _rig_player(t, at: Vector2) -> Stroller:
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	return player

## The world position of a through-alley tile where a mark stands (one in from a mouth) more than
## `min_distance` from `at`, or `Vector2.INF`
## if the test city has none. Used to put her far enough from the mark that the re-placement
## rule has to fire.
func _alley_farther_than(min_distance: float, at: Vector2) -> Vector2:
	for tile in _through_alleys():
		if not _is_one_in_from_a_mouth(_city.map, tile):
			continue
		var world := _city.map.tile_to_world(tile)
		if world.distance_to(at) > min_distance:
			return world
	return Vector2.INF

## The test city's through-alley tiles — see `_through_alley_tiles()`.
func _through_alleys() -> Array[Vector2i]:
	return _through_alley_tiles(_city.map)

## Every `ALLEY` tile of `map` that lies in a through-alley (`CityMap.alley_rects`), in
## `CityMap.tiles_of_type()`'s own order: the marks whose robber stands at the alley's far end,
## rather than in a courtyard past a passage. The director never needs the split; the sweeps here
## ask each kind its own question.
static func _through_alley_tiles(map: CityMap) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
		for rect in map.alley_rects:
			if rect.has_point(tile):
				tiles.append(tile)
				break
	return tiles

## The two through-alley tiles closest together in the built test city — `[player_at, nearer,
## other]`, `player_at` sitting exactly on `nearer` so it is always the globally nearest one to
## itself, and `other` confirmed within `ResistanceDirector.NOTICE_RADIUS` of it. Empty if the city has no pair
## that close, which the relocation test below skips on rather than asserting through.
func _two_nearby_alleys() -> Array:
	var alleys := _through_alleys()
	for tile in alleys:
		var at := _city.map.tile_to_world(tile)
		for other in alleys:
			if other == tile:
				continue
			if at.distance_to(_city.map.tile_to_world(other)) <= ResistanceDirector.NOTICE_RADIUS:
				return [at, tile, other]
	return []

## Whether `tile` is the one a mark stands on, worked out from the map alone: the second or the
## second-to-last tile of a through-alley along its long axis, or the walkable alley or courtyard
## tile beside a courtyard passage's mouth that is not itself a mouth.
static func _is_one_in_from_a_mouth(map: CityMap, tile: Vector2i) -> bool:
	for rect in map.alley_rects:
		if rect.has_point(tile):
			var vertical := rect.size.y >= rect.size.x
			var along := tile.y - rect.position.y if vertical else tile.x - rect.position.x
			var length := rect.size.y if vertical else rect.size.x
			return along == 1 or along == length - 2
	var type := map.tile_at(tile)
	if not map.is_walkable(tile) or (type != GameEnums.TileType.ALLEY \
			and type != GameEnums.TileType.COURTYARD):
		return false
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var beside := tile + step
		if map.tile_at(beside) == GameEnums.TileType.ALLEY and _is_a_mouth(map, beside) \
				and not _is_a_mouth(map, tile):
			return true
	return false

## An alley's mouth, worked out from the map alone: the end tile of a through-alley along its long
## axis, or a courtyard passage's tile beside walkable ground that is neither alley nor courtyard.
static func _is_a_mouth(map: CityMap, tile: Vector2i) -> bool:
	for rect in map.alley_rects:
		if rect.has_point(tile):
			var vertical := rect.size.y >= rect.size.x
			var along := tile.y - rect.position.y if vertical else tile.x - rect.position.x
			var length := rect.size.y if vertical else rect.size.x
			return along == 0 or along == length - 1
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var type := map.tile_at(tile + step)
		if map.is_walkable(tile + step) and type != GameEnums.TileType.ALLEY \
				and type != GameEnums.TileType.COURTYARD:
			return true
	return false

## Runs the warning the trap row `row_id` is under to its end, frame by frame, with her standing at
## `her`, the way `EventManager._physics_process` runs it. Returns how long it was up, or `INF` when
## none was.
func _run_the_traps_warning(row_id: String, her: Vector2) -> float:
	var warning := _warning_for(_city.events, row_id)
	if warning == null:
		return INF
	while _city.events.pending_warnings().has(warning) and warning.shown < 5.0:
		_city.events.warnings.run(STEP, her)
	return warning.shown

## A day-10 director with the mark touched: the neighbor out in the city, walking home. Planned
## through the real day order, since the walk is stated over the day's own closures and bodies.
func _director_on_the_neighbor(t) -> ResistanceDirector:
	var day := ResistanceHappenings.NEIGHBOR_DAY
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(DaySpec.for_day(day), _rng(day, "events"), [], _city.map.doorstep_world_position())
	var director := _director(t)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var mark := director.current_step()
	t.check(mark != null and mark.is_pickup, "day 10 offers a mark")
	director._on_contact_completed(mark.index if mark else -1)
	return director

## The warning `events` has up for the row `id`, or null.
func _warning_for(events: EventManager, id: String) -> PendingWarning:
	for warning in events.pending_warnings():
		if warning.def.id == id:
			return warning
	return null

## Whether some tile within three of `item` is ground she can stand on (walkable, no body,
## reachable from home) and its centre completes today's contact (`ContactPoint.would_complete_at()`).
func _touched_from_standable_ground(director: ResistanceDirector, item: Vector2,
		on: CityMap = null) -> bool:
	var map := on if on else _city.map
	var centre := map.world_to_tile(item)
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var tile := centre + Vector2i(dx, dy)
			if not map.is_walkable(tile) or map.is_obstructed(tile) \
					or not director._reachable_from_home(tile):
				continue
			if director._contact.would_complete_at(map.tile_to_world(tile)):
				return true
	return false

## `[edge, inside]`, each `tile -> true`: walked tile by tile from her tile at `her` over walkable
## ground the day's obstruction (`director._reach_blocked`) leaves open, going on only from a tile
## inside the `NEAR_THE_MARK` circle round her — a tile at or past its edge is where that path
## reaches the edge.
func _edge_of_her_circle(director: ResistanceDirector, her: Vector2) -> Array:
	var map := _city.map
	var start := map.world_to_tile(her)
	var centre := map.tile_to_world(start)
	var edge := {}
	var inside := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + step
			if inside.has(next) or edge.has(next) or not map.is_walkable(next) \
					or director._reach_blocked.has(next):
				continue
			if map.tile_to_world(next).distance_to(centre) >= ResistanceDirector.NEAR_THE_MARK:
				edge[next] = true
			else:
				inside[next] = true
				queue.append(next)
	return [edge, inside]

## Plans `day` on the test city in the real day order (closures, events, resistance) for
## `seed_value`, and reads the day's mark standing on it with her screen the view around her:
## `[director with the task active, the mark's position, her rig]`.
func _read_the_mark_on(t, day: int, seed_value: int) -> Array:
	GameState.resistance.completed_steps = _completed_through(2 * (day - 6))
	GameState.facts.completed_resistance_alley_tiles = []
	var state := CityState.new()
	GameState.attempt_spend.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures", seed_value))
	_city.events.start_day(DaySpec.for_day(day), _rng(day, "events", seed_value), [],
			_city.map.doorstep_world_position())
	var director := _director(t)
	director.start_day(day, _rng(day, "resistance", seed_value), 300.0)
	var mark := director.contact_position()
	var player := _rig_player(t, mark)
	director.use_player(player)
	_watch_the_screen_round(director, mark)
	var step := director.current_step()
	if step != null and step.is_pickup:
		director._on_contact_completed(step.index)
	# The view was the mark's for placing the task; what the test does next looks through her own.
	_look_at(Rect2())
	return [director, mark, player]

const REACHABILITY_SWEEP_DAYS := [6, 7, 8, 9, 10, 11, 12, 13]

## `GameState.calendar.day_rng()`'s own hash, built without touching the `GameState.header.run_seed` global this
## sweep has no other use for — same stream a played day actually draws from, for a seed and a day
## this test chooses rather than the run's own.
func _production_rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

## Every refusal `_pick_reachable()` checks — `is_held_at`
## excepted for the one task deliberately sited on held ground, the crossing at a region door
## (`_place_at_a_door()`'s own `allow_held`). `grid`/`blocked`/`reached` are one day's own
## `ReachabilityGrid.flood()` answer, built by the caller once per (seed, day) rather than per tile
## — see `_day_reachability()` — so this stays a pure predicate rather than a second place that
## builds the grid.
func _stands_on_legal_ground(map: CityMap, tile: Vector2i, walled_alleys: Array[Rect2i],
		allow_held: bool, grid: ReachabilityGrid, blocked: Dictionary, reached: Dictionary) -> bool:
	return map.is_walkable(tile) and not map.is_closed(tile) \
			and (allow_held or not map.is_held_at(tile)) and not map.is_on_home_block(tile) \
			and not map.is_in_walled_alley(tile, walled_alleys) and not map.is_obstructed(tile) \
			and grid.reaches(tile, blocked, reached)

## The day's reachability answer as `ResistanceDirector._reachable_from_home()` builds it
## (`EventScheduler.blocked_by()` over every placed, obstructing or hard-fail plan, flooded from
## home), built independently here so a sweep is not just asking the director to grade its own
## homework. A region door's own bodies are excluded, the same way `_ensure_reachability()`
## excludes them and for the same reason — see that function's own doc. The soft seals' bands
## (`CityMap.soft_sealed_tiles`) are blocked on top, as the director blocks them: the red arrow
## reads a band as ground she cannot walk, so a place reached only through one is not a place the
## arrow can lead her to. `[grid, blocked, reached]`.
func _day_reachability(city: City) -> Array:
	var region_plan: RegionPlanner.RegionPlan = city.region_plan()
	var door_bodies: Array[EventScheduler.Planned] = region_plan.door_bodies if region_plan else []
	var blockers: Array[EventScheduler.Planned] = []
	for plan in city.events.plans():
		if not plan.is_placed() or plan in door_bodies:
			continue
		if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
			blockers.append(plan)
	var grid := ReachabilityGrid.build(city.map)
	var blocked := EventScheduler.blocked_by(city.map, blockers)
	blocked.merge(city.map.soft_sealed_tiles)
	return [grid, blocked, grid.flood([city.map.home_rect.position], blocked)]
