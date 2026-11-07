extends RefCounted
## **What the resistance suites share** (`tests/test_resistance_*.gd`): the city each builds, the
## director over it, and the walks, views and sweeps more than one of them drives. A helper, not a
## suite: the runner loads only `test_*.gd`. Each suite extends this one and runs its own tests;
## `_city` is freed by whichever suite built it, at the end of its `run()` (`_free_city()`).
##
## **A test hands the director everything it reads** (minty-quail, tests through public seams):
## the city's parts and its run (`ResistanceDirector.setup()`: the map, the run, the events, the
## streets, the fronts, the city as the world and its siting), the day's stream (`start_day()`'s
## `rng`), the day's length and every tick (`tick()`), her (`use_player()`) and what she can see (`set_sight()`). A test that builds its city
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
const ContactTouches := preload("res://tests/contact_touches.gd")
const AlleyMarks := preload("res://tests/alley_marks.gd")


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
	var run := RunState.new()
	run.start_run(RUN_SEED)
	_city = CITY_SCENE.instantiate()
	_city.run = run
	t.add_child(_city)
	_city.build(CityGenerator.generate(seed_value))
	return run

## Frees the test city when the suite built it one.
func _free_city() -> void:
	if _city != null:
		_city.free()
	_city = null

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
	director.setup(_city.map, _city.run, _city.events, _city.streets(), _city.fronts(), _city, null,
			_city.spawn_siting)
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

## Every live instance in the test city's street. Taken before a happening runs, it says by
## difference what the happening put there (`_raid_since()`).
func _street() -> Array[EventInstance]:
	var found: Array[EventInstance] = []
	for instance in _city.events.instances():
		if not instance.is_finished:
			found.append(instance)
	return found

## Day 10's raid at her building as the street holds it: the night raid's vans and the patrol car
## pacing between them, among the live instances that were not in the street in `before` (an earlier
## `_street()`).
func _raid_since(before: Array[EventInstance]) -> Array[EventInstance]:
	var found: Array[EventInstance] = []
	for instance in _street():
		if instance in before:
			continue
		if instance.def.id == "night_raid" or (instance.def.id == "police_patrol" and instance.def.paces):
			found.append(instance)
	return found

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

## The cities a sweep relocates a mark over every mark tile of (`_relocations_over_the_marks()`): the
## six the sweeps over bare maps asked, kept whole since they found real bugs (brisk-moose #1130),
## 2295276695 among them, the seed M100's robber stuck in a building was found on. Between them they
## hold every kind of mark tile the game has — one in from either end of a through-alley, and the
## courtyard passages, of which a city has only two to four: a one-tile passage, whose mark stands on
## the courtyard's own first tile, and a passage into an apartment complex's wider court, which the
## courtyard sweep checks it met. A relocation is a tick, so the six cost a city build each.
const SWEEP_SEEDS: Array[int] = [4242, 90210, 2295276695, 314159, 271828, 555555]

## **A relocation, the way a played day makes one** (`ResistanceDirector.tick()`): her stroller set
## down at `here`, the day's mark unseen (the director is handed no sight, so nothing she passes is
## noticed) and more than `NOTICE_RADIUS` from her, and one tick, which moves the mark to the mark
## tile nearest her that every refusal of the day's placement leaves alone and stands its guard for
## her standing at `here`, or leaves it where it stood when no tile qualifies. Where the mark stands
## within `NOTICE_RADIUS` of `here`, she first stands at the first of `away` (world points) more than
## twice that from `here` whose tick moves it out there. Answers where the mark stands after her tick
## at `here`, or `Vector2.INF` when that tick did not move it.
func _relocate_round(director: ResistanceDirector, player: Stroller, here: Vector2,
		away: Array[Vector2]) -> Vector2:
	for far in away:
		if director.contact_position().distance_to(here) > ResistanceDirector.NOTICE_RADIUS:
			break
		if far.distance_to(here) > ResistanceDirector.NOTICE_RADIUS * 2.0:
			player.global_position = far
			director.tick(STEP)
	var before := director.contact_position()
	if before.distance_to(here) <= ResistanceDirector.NOTICE_RADIUS:
		return Vector2.INF
	player.global_position = here
	director.tick(STEP)
	var after := director.contact_position()
	return after if after.distance_to(before) > 0.5 else Vector2.INF

## The feet of the chalk mark's guard as the street has him (the live `EventCatalogue.mark_guard()`
## among the test city's instances), or `Vector2.INF` when none stands, or more than one.
func _marks_guard_feet() -> Vector2:
	var guards := _live(EventCatalogue.mark_guard().id)
	return guards[0].global_position if guards.size() == 1 else Vector2.INF

## **Every mark tile of the city of `seed_value`, relocated to in turn** (`_relocate_round()`), on
## day 7 in a run of its own with nothing in her view and no event of the day's own in the street, so
## the one robber there is the mark's guard: one entry per tile, `{"tile", "her", "mark", "guard"}`,
## where she stood for it (`her_at.call(map, tile)`), where her tick put the mark (`Vector2.INF` when
## it did not move) and the guard's feet after it (`_marks_guard_feet()`). The relocation is the one
## placement a tick makes, so a sweep asks the director's rule of a hundred tiles in a few
## milliseconds; the city is the test's, freed by the next build or `_free_city()`.
func _relocations_over_the_marks(t, seed_value: int, her_at: Callable) -> Array[Dictionary]:
	var run := _build_city_in_a_new_run(t, seed_value)
	run.resistance.completed_steps = _completed_through(2)
	_look_at(Rect2())
	var director := _director(t)
	director.start_day(7, _rng(7, "resistance", seed_value), 300.0)
	var player := _rig_player(t, director.contact_position())
	director.use_player(player)
	var tiles := _mark_tiles()
	var away: Array[Vector2] = []
	for tile in tiles:
		away.append(_city.map.tile_to_world(tile))
	var found: Array[Dictionary] = []
	for tile in tiles:
		var her: Vector2 = her_at.call(_city.map, tile)
		var mark := _relocate_round(director, player, her, away)
		found.append({"tile": tile, "her": her, "mark": mark, "guard": _marks_guard_feet()})
	player.free()
	director.free()
	return found

## Where she stands to have a mark relocated onto `tile` with nothing about her refusing its guard:
## four tiles out from it through its mouth, on the ground beyond the mouth, so the mark tile is the
## one nearest her (its twin across a two-tile alley is farther, another alley's across the street)
## and its guard, further in, is past his notice of her (`EventDef.notice`) even at a small
## courtyard's inner end. The tile's own centre when it has no mouth beside it.
static func _outside_its_mouth(map: CityMap, tile: Vector2i) -> Vector2:
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var mouth := tile + step
		if AlleyMarks.is_a_mouth(map, mouth) and AlleyMarks.mark_tile_of_mouth(map, mouth) == tile:
			return map.tile_to_world(tile + step * 4)
	return map.tile_to_world(tile)

## Where she stands to have a mark relocated onto `tile` with her on it: its own centre.
static func _on_the_tile(map: CityMap, tile: Vector2i) -> Vector2:
	return map.tile_to_world(tile)

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

## Every tile a chalk mark may stand on in the test city: one step in from each alley mouth
## (`AlleyMarks.mark_tile_of_mouth()`), in `CityMap.tiles_of_type()`'s own order. The director offers
## no list of them; it draws from the same walk over the map.
func _mark_tiles() -> Array[Vector2i]:
	var marks: Array[Vector2i] = []
	for tile in _city.map.tiles_of_type(GameEnums.TileType.ALLEY):
		if _is_a_mouth(_city.map, tile):
			marks.append(AlleyMarks.mark_tile_of_mouth(_city.map, tile))
	return marks

## Where the guard of a mark at `mark` stands before anything refuses his ground, worked out from the
## map alone (`AlleyMarks`): two-thirds through a through-alley, the courtyard's inner end past a
## passage, `Vector2.INF` off an alley.
static func _guard_spot_of(map: CityMap, mark: Vector2) -> Vector2:
	var tile := map.world_to_tile(mark)
	var robbery := EventCatalogue.mark_guard()
	var spot := AlleyMarks.expected_guard_spot(map, tile, mark,
			robbery.inner_radius + ContactPoint.REACH)
	if spot != Vector2.INF:
		return spot
	var court := AlleyMarks.courtyard_of(map, tile)
	return AlleyMarks.courtyard_inner_end(map, court, mark) if court.has_area() else Vector2.INF

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

## An alley's mouth, worked out from the map alone (`AlleyMarks.is_a_mouth()`).
static func _is_a_mouth(map: CityMap, tile: Vector2i) -> bool:
	return AlleyMarks.is_a_mouth(map, tile)

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
## reachable from home under the day's whole obstruction, `_day_reachability()`) and standing at its
## centre for a physics frame completes today's contact (`ContactTouches.touches_from()`). On
## `in_city`, or the test city.
func _touched_from_standable_ground(t, director: ResistanceDirector, item: Vector2,
		in_city: City = null) -> bool:
	var city := in_city if in_city else _city
	var map := city.map
	var reachability := _day_reachability(city)
	var grid: ReachabilityGrid = reachability[0]
	var blocked: Dictionary = reachability[1]
	var reached: Dictionary = reachability[2]
	var centre := map.world_to_tile(item)
	var places: Array[Vector2] = []
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var tile := centre + Vector2i(dx, dy)
			if not map.is_walkable(tile) or map.is_obstructed(tile) \
					or not grid.reaches(tile, blocked, reached):
				continue
			places.append(map.tile_to_world(tile))
	var touched := await ContactTouches.touches_from(t, director, places)
	return touched.has(true)

## The day's obstruction without the body of the task `director` offers (its contact's place and
## its rider's), which the day's first placement did not yet have.
func _obstruction_but_the_task(director: ResistanceDirector) -> Dictionary:
	var near: Array[Vector2] = [director.contact_position()]
	if director.rider() != null:
		near.append(director.rider().global_position)
	return preload("res://tests/resistance_reads.gd").day_reachability(_city, near)[1]

## `[edge, inside]`, each `tile -> true`: walked tile by tile from her tile at `her` over walkable
## ground the day's obstruction leaves open, going on only from a tile inside the `NEAR_THE_MARK`
## circle round her — a tile at or past its edge is where that path reaches the edge. The
## obstruction is the day's, built independently of the director (`_day_reachability()`).
func _edge_of_her_circle(director: ResistanceDirector, her: Vector2) -> Array:
	var map := _city.map
	var blocked: Dictionary = _obstruction_but_the_task(director)
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
## (`_day_reachability()`), walked on past the circle's edge. `tile -> true`.
## **A deliberate copy of the director's own walk** (`_paths_reach_between()` there), kept as a test
## oracle: day 13's check grades the director's roadblock against a walk the director does not run,
## so if the two drift that check fails rather than passing silently.
func _paths_reach_between(director: ResistanceDirector, her: Vector2, near: float,
		far: float) -> Dictionary:
	var map := _city.map
	var blocked: Dictionary = _obstruction_but_the_task(director)
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
## `[director with the task active, the mark's position, her rig]`. With `trace_into`, the director
## is handed a trace that records its lines there, from the day's start.
func _read_the_mark_on(t, day: int, seed_value: int, trace_into: Array[String] = []) -> Array:
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
	director.trace = RunTrace.recording(trace_into)
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

## The same hash the run calendar's `day_rng()` takes, built here without a run, whose
## `header.run_seed` this sweep has no other use for — same stream a played day actually draws from, for a seed and a day
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

## The day's reachability answer, built independently of the director (`ResistanceReads.day_reachability()`).
func _day_reachability(city: City) -> Array:
	return preload("res://tests/resistance_reads.gd").day_reachability(city)
