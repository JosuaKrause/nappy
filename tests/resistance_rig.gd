extends RefCounted
## **What the resistance suites share** (`tests/test_resistance_*.gd`): the city each builds, the
## director over it, and the walks, views and sweeps more than one of them drives. A helper, not a
## suite: the runner loads only `test_*.gd`. Each suite extends this one and runs its own tests;
## `_city` is freed by whichever suite built it, at the end of its `run()` (`_free_city()`).
##
## **A test hands the director everything it reads** (minty-quail, tests through public seams):
## the city, and with it the run (`City.run`, which `ResistanceDirector.setup()` takes when it is
## handed none), the day's stream (`start_day()`'s `rng`), the day's length and every tick
## (`tick()`), her (`use_player()`) and what she can see (`set_sight()`). A test that builds its city
## with `_build_city_in_a_new_run()` owns the run that city stands in, so the state it needs — the
## steps done, the alleys used, the scars — is set on that run, by the test, and gone with it.
##
## **What the director has put in the street is read from the street**: the contact she touches
## (`ResistanceDirector.contact()`), what its task rides on (`rider()`), and every guard and pursuer
## from the city's live instances (`_live()`, `_new_one()`), never from the director's fields. Her
## touch is a real physics frame with her standing on the contact (`_step_a_frame()`), and a read
## that is only setup for what a test asks, not a touch it measures, completes the contact as an
## action does (`ContactPoint.complete_now()`), which runs the same completion a touch runs.

const CITY_SCENE := preload("res://scenes/world/city.tscn")

const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

const SEED := 4242

const STEP := 1.0 / 60.0

## Maps for a sweep that asks about a *rule* rather than a *layout* — the same distinction and the
## same name `tests/test_routes.gd` and `tests/test_regions.gd` use: "no scheduled placement ever
## lands near the doorstep" is enforced by construction the same way on every city, so a second
## city tests the same guarantee against different noise rather than a different shape of it.
const RULE_SEEDS := 3

## The seed of a run a test builds its own city in (`_build_city_in_a_new_run()`): fixed, so the
## posters pasted from it are the same on every run, and the one the runner starts the live run on
## between suites. Nothing the director places reads it: each day's stream is handed in (`_rng()`).
const RUN_SEED := 2

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

## One real physics frame, and the process frame after it: every node in the tree takes its
## `_physics_process()` once — a contact asks whether she is touching it — before the test reads on.
## `physics_frame` is emitted before the nodes take their step, so the process frame is what says
## the step has been taken.
func _step_a_frame(t) -> void:
	await t.get_tree().physics_frame
	await t.get_tree().process_frame

var _city: City
## The run `_city` stands in (`_build_city_in_a_new_run()`), freed with the city.
var _own_run: RunState

## Freed rather than left standing: `City.build()` adds an `EventManager` child that acquires the
## "events" `AtlasLibrary` group in its own `_enter_tree()` and only gives it back in
## `_exit_tree()` (`src/events/event_manager.gd`). A suite builds a city many times over, so a
## `_city` never freed between two builds would leave every earlier one standing, each holding
## "events" resident for the rest of the process; `run()` frees whichever one is still around after
## the last.
##
## The city of `seed_value` in a run of its own, which it hands to every director built over it
## (`_director()`): the run starts fresh, with no step done, no alley used and no scar, and the test
## sets whatever else the day it asks about needs on it. Returns the run.
func _build_city_in_a_new_run(t, seed_value := SEED) -> RunState:
	_free_city()
	_own_run = RunState.new()
	_own_run.start_run(RUN_SEED)
	_city = CITY_SCENE.instantiate()
	_city.run = _own_run
	t.add_child(_city)
	_city.build(CityGenerator.generate(seed_value))
	return _own_run

## Frees the test city and the run it stands in when the suite built it one.
func _free_city() -> void:
	if _city != null:
		_city.free()
	_city = null
	if _own_run != null:
		_own_run.free()
	_own_run = null

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
## the director with step 2 (the yeller perform) already active: the mark is read with nobody in
## the world (`_read_the_mark()`).
func _director_on_the_yeller_perform(t, seed_value := SEED) -> ResistanceDirector:
	var director := _director(t)
	director.start_day(6, _rng(6, "resistance", seed_value), 300.0)
	_read_the_mark(director)
	return director

## Completes the contact on offer, which reads a mark and activates the task it unlocks, the way an
## action completes a step (`ContactPoint.complete_now()`): the same completion her touch runs,
## from wherever she is — or, with no player handed to the director, from nowhere, the way a rig's
## bare director reads it.
func _read_the_mark(director: ResistanceDirector) -> void:
	var contact := director.contact()
	if contact:
		contact.complete_now()

## The live instances of the row `id` in the test city's street (`EventManager.instances()`): the
## guards and pursuers the director has put there, read from the world rather than its fields.
func _live(id: String) -> Array[EventInstance]:
	var found: Array[EventInstance] = []
	for instance in _city.events.instances():
		if instance.def.id == id and not instance.is_finished:
			found.append(instance)
	return found

## The live instance of `id` that is not among `before` (an earlier `_live(id)`), or null: what was
## put in the street since.
func _new_one(id: String, before: Array[EventInstance]) -> EventInstance:
	for instance in _live(id):
		if instance not in before:
			return instance
	return null

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
	if mark:
		_read_the_mark(director)
	return director

## The warning `events` has up for the row `id`, or null.
func _warning_for(events: EventManager, id: String) -> PendingWarning:
	for warning in events.pending_warnings():
		if warning.def.id == id:
			return warning
	return null

## Whether some tile within three of `item` is ground she can stand on (walkable, no body,
## reachable from home under the day's whole obstruction, `_day_reachability()`) and its centre
## completes today's contact (`ContactPoint.would_complete_at()`). On `in_city`, or the test city.
func _touched_from_standable_ground(director: ResistanceDirector, item: Vector2,
		in_city: City = null) -> bool:
	var city := in_city if in_city else _city
	var map := city.map
	var reachability := _day_reachability(city)
	var grid: ReachabilityGrid = reachability[0]
	var blocked: Dictionary = reachability[1]
	var reached: Dictionary = reachability[2]
	var centre := map.world_to_tile(item)
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var tile := centre + Vector2i(dx, dy)
			if not map.is_walkable(tile) or map.is_obstructed(tile) \
					or not grid.reaches(tile, blocked, reached):
				continue
			if director.contact().would_complete_at(map.tile_to_world(tile)):
				return true
	return false

## `[edge, inside]`, each `tile -> true`: walked tile by tile from her tile at `her` over walkable
## ground the day's obstruction leaves open, going on only from a tile inside the `NEAR_THE_MARK`
## circle round her — a tile at or past its edge is where that path reaches the edge. The
## obstruction is the director's own as it placed the day's first contact
## (`ResistanceDirector.reach_obstruction()`), so a task's own body placed after it (day 11's mast)
## does not shut its own tile.
func _edge_of_her_circle(director: ResistanceDirector, her: Vector2) -> Array:
	var map := _city.map
	var blocked := director.reach_obstruction()
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
					or blocked.has(next):
				continue
			if map.tile_to_world(next).distance_to(centre) >= ResistanceDirector.NEAR_THE_MARK:
				edge[next] = true
			else:
				inside[next] = true
				queue.append(next)
	return [edge, inside]

## The tiles her paths from `her` reach at least `near` and less than `far` from her own tile's
## centre, over walkable ground the day's obstruction leaves open
## (`ResistanceDirector.reach_obstruction()`), walked on past the circle's edge. `tile -> true`.
## **A deliberate copy of the director's own walk** (`_paths_reach_between()` there), kept as a test
## oracle: day 13's check grades the director's roadblock against a walk the director does not run,
## so if the two drift that check fails rather than passing silently.
func _paths_reach_between(director: ResistanceDirector, her: Vector2, near: float,
		far: float) -> Dictionary:
	var map := _city.map
	var blocked := director.reach_obstruction()
	var found := {}
	var start := map.world_to_tile(her)
	if not map.is_walkable(start):
		return found
	var centre := map.tile_to_world(start)
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + step
			if seen.has(next) or not map.is_walkable(next) or blocked.has(next):
				continue
			seen[next] = true
			var distance := map.tile_to_world(next).distance_to(centre)
			if distance >= far:
				continue
			if distance >= near:
				found[next] = true
			queue.append(next)
	return found

## Plans `day` on the test city in the real day order (closures, events, resistance) for
## `seed_value`, and reads the day's mark standing on it with her screen the view around her:
## `[director with the task active, the mark's position, her rig]`.
func _read_the_mark_on(t, day: int, seed_value: int) -> Array:
	var run: RunState = _city.run
	run.resistance.completed_steps = _completed_through(2 * (day - 6))
	run.facts.completed_resistance_alley_tiles = []
	var state := CityState.new()
	run.attempt_spend.city_state = state
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
		_read_the_mark(director)
	# The view was the mark's for placing the task; what the test does next looks through her own.
	_look_at(Rect2())
	return [director, mark, player]

const REACHABILITY_SWEEP_DAYS := [6, 7, 8, 9, 10, 11, 12, 13]

## the run calendar's `day_rng()` own hash, built without a run's `header.run_seed` this
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
