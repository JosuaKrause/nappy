class_name RouteRig
extends Node
## `--route <target>[,<target>...]` walks her to each named target in turn, along a real path's
## edges, with no scripted inputs — see docs/TODO.md, M184, "A rig walks the route". Where
## `--walk`'s own script (`AutoScreenshot`) holds a fixed direction or replays a fixed timing, this
## re-aims at the next step of a live path every physics frame, through the exact same
## `TouchControls._set_axis()` press every other dev-rig direction already goes through — so the
## meter, the events, the crowd, the closures, the doors and the clock all run exactly as they do
## for a player, at `Tuning.WALK_SPEED`. Only the source of the heading is a plan instead of a
## finger.
##
## **Never a player control.** See docs/DECISIONS.md, M88, "the player chooses the controls" —
## *"a tap that pathfinds hands the route decision to the game and the route decision is the
## design"* — for why a pathfinding walk answers only to `DevFlags`, the same gate `--walk` and
## `--flee` already answer to on a debug build; nothing outside a dev flag ever reaches it.
##
## **Targets**, split on commas by `DevFlags.route_targets()`:
## - `mark` — today's chalk mark, while it is still the step on offer (`ResistanceDirector`'s own
##   pickup). Unavailable once it has been touched, or on a day with no mark at all.
## - `task` — the red arrow's own point for a one-place task, or the nearest **live** instance of
##   an any-instance task (the one who won't stop shouting, a roadblock's band). Unavailable until
##   the mark that unlocks it has actually been reached.
## - `calm` — the nearest calm area she can settle the baby in, by walking distance rather than a
##   straight line. She stops and presses nothing once she is there, and stays until the baby is
##   asleep, however long that takes — the day's own clock is what answers whether that fits.
## - `home` — the doorstep's own block, the centre of `CityMap.home_rect`.
## - `spawn:<name>` — whatever `DevRig.for_spawn_target()` already knows how to find.
##
## An unresolved target (nothing to walk to yet, or nothing found within `_RESOLVE_TIMEOUT`) and an
## unreachable one (no path exists) are both logged and skipped rather than hung on forever — see
## `_try_resolve()` and `_begin_leg()`. Days 10 and 11 have no mark this slice
## (`ResistanceSteps._unavailable()`), so `mark` and `task` skip cleanly on them; that is the
## measurement, not a bug in it.
##
## **Hugs the kerb by keeping off the carriageway, not by hand-drawn geometry.** `_plan()` first
## asks for the shortest walk on a graph with every plain `ROAD` tile removed — so a route always
## prefers the pavement and crosses only at a `CROSSING` (a zebra) it passes on the way — and only
## falls back to the unrestricted graph, carriageway included, when the sidewalk-only one cannot
## reach the target at all (the day 13 roadblock's own band is `ROAD`/`CROSSING` ground, so its own
## last step always does). `_simplify()` then collapses a straight run along one row or column into
## its two ends, dropping the redundant waypoints in between — see `_line_of_sight()`'s own doc for
## why a true diagonal cut is refused outright rather than sampled: it can cross a 2x2 corner the
## raw 4-connected walk never actually crossed.
##
## **Re-plans when the way ahead closes.** `_maybe_replan()` checks the remaining waypoints against
## `CityMap.is_open()` and `CityMap.is_obstructed()` every `_REPLAN_INTERVAL` seconds — closures are
## fixed for the day (see the city skill), but an obstruction (a fire's own spread, a parked van, a
## roadblock's own band) moves while the day is live, and this is what catches one landing on a
## step already planned. And it re-plans when she has simply stopped covering ground even though the
## tiles read fine — a body she has fetched up against, or standing *inside* an obstruction's own
## collision — which a second stall in a row escalates from a fresh plan to `_begin_unstick()`, a
## short maneuver through the eight compass points that works her physically clear before the next
## plan is asked for.
##
## **Quits the run once it is done**, win or lose — a rig meant to be driven from a headless process
## by `tests/probes/` cannot wait at a day summary screen for a button nobody is going to press;
## see `_finish()` and `_on_day_finished()`.

## World-space arrival radius for a waypoint — comfortably inside `ContactPoint.REACH` (36px), so a
## mark or a task's own contact always completes on the way in, and small enough (under a third of
## `Tuning.TILE_SIZE`, 32px) that switching to the next waypoint never visibly overshoots the line
## `_simplify()` drew.
const _ARRIVE_RADIUS := 10.0

## How long an unresolved target (no mark today, the task not yet unlocked, an any-instance task
## with nothing live yet) is given before it is logged and skipped — long enough that a task
## unlocked a frame after the mark is touched is never mistaken for one that never will be.
const _RESOLVE_TIMEOUT := 2.0

## Seconds between checks that the remaining path is still open. Short enough that an obstruction
## landing mid-leg is caught well inside the few seconds it takes to walk one, cheap enough (one
## `is_open()`/`is_obstructed()` pair per waypoint still ahead) to ask for on every frame.
const _REPLAN_INTERVAL := 0.5

## Below this in one `_REPLAN_INTERVAL` is "not really moving" — a sixth of `Tuning.WALK_SPEED`
## (92px/s) times the interval, well under what an unobstructed leg covers, so a genuine stall
## (a crowd she cannot press through, a body she has fetched up against) is caught within a couple
## of checks even where every tile involved still answers `is_open()`.
const _STUCK_DISTANCE := 8.0

const _STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

## World px sampled along a candidate straight-line cut in `_line_of_sight()` — a quarter of
## `Tuning.TILE_SIZE`, fine enough that a cut cannot skip clean over a one-tile obstruction.
const _LINE_OF_SIGHT_STEP := 8.0

var _city: City
var _player: Stroller
var _baby: Baby
var _resistance: ResistanceDirector
var _day: DayController

var _targets: Array[String] = []
var _target_index := 0
var _current_word := ""
## Remaining waypoints of the current leg, nearest first — world space, the last one the exact
## target position rather than its tile's centre. Empty means either nothing planned yet or the
## leg is complete; `_arrive()` is what tells the two apart.
var _waypoints: Array[Vector2] = []
var _current_target_tile := Vector2i.ZERO
var _current_target_world := Vector2.INF
var _leg_start_elapsed := 0.0
var _leg_start_position := Vector2.ZERO

var _resolving := false
var _resolve_elapsed := 0.0
var _settling := false
var _replan_elapsed := 0.0
## Where she stood at the last `_maybe_replan()` check — `Vector2.INF` right after a leg begins,
## so the very first check has nothing to compare against yet. See `_STUCK_DISTANCE`.
var _stuck_reference := Vector2.INF
## How many `_maybe_replan()` checks in a row have found her stuck — reset to 0 the moment one
## does not. A first stall replans the ordinary way, since the tile grid may simply have changed;
## a second in a row means the grid says nothing is wrong and the ordinary replan already tried
## and failed to move her, so `_replan()` escalates to a detour around wherever she actually is.
var _stuck_streak := 0

## Every `ROAD` tile in the map, built once — the lattice itself never changes within a run, only
## which blocks are calm and which streets are closed today, neither of which moves a `ROAD` tile.
## Kept out of `_blocked_for_phase()`'s own per-call cost, which only has `closed_tiles` (small,
## and genuinely different every day) left to copy.
var _road_tiles: Dictionary = {}

var _done := false

func setup(city: City, player: Stroller, baby: Baby, resistance: ResistanceDirector,
		day: DayController) -> void:
	_city = city
	_player = player
	_baby = baby
	_resistance = resistance
	_day = day
	_targets = DevFlags.route_targets()
	_cache_road_tiles()
	_day.day_finished.connect(_on_day_finished)

func _cache_road_tiles() -> void:
	for y in _city.map.size.y:
		for x in _city.map.size.x:
			var tile := Vector2i(x, y)
			if _city.map.tile_at(tile) == GameEnums.TileType.ROAD:
				_road_tiles[tile] = true

## Called from `main._start_day()`, the same place `TelemetryObserver.start_day()` is — resets the
## queue for the day just built, so a run that plays more than one day under this flag (a nerve, or
## a probe that simply keeps going) starts the new day's targets fresh rather than chasing
## yesterday's mark.
func start_day() -> void:
	_target_index = 0
	_waypoints.clear()
	_resolving = false
	_settling = false
	_unsticking = false
	_unstick_cycles = 0
	_stuck_streak = 0
	_stuck_reference = Vector2.INF
	_release()
	_done = _targets.is_empty()
	if not _done:
		_begin_resolving(_targets[0])

func _begin_resolving(word: String) -> void:
	_current_word = word
	_resolving = true
	_resolve_elapsed = 0.0
	_release()

func _physics_process(delta: float) -> void:
	if _done or not _day or not _day.is_running():
		return
	if _resolving:
		_try_resolve(delta)
		return
	if _settling:
		_check_settled()
		return
	if _unsticking:
		_unstick(delta)
		return
	_follow(delta)

# --------------------------------------------------------------- resolving ---

func _try_resolve(delta: float) -> void:
	var target := _resolve_target(_current_word)
	if target != Vector2.INF:
		_resolving = false
		_begin_leg(target)
		return
	_resolve_elapsed += delta
	if _resolve_elapsed >= _RESOLVE_TIMEOUT:
		Telemetry.note("route", "day %d: '%s' unavailable, skipping" % [GameState.day, _current_word])
		_advance_target()

## Where `word` names, or `Vector2.INF` when it names nothing right now — see the class doc's own
## list of targets for what each one means and why it can be unresolved.
func _resolve_target(word: String) -> Vector2:
	match word:
		"mark":
			var step := _resistance.current_step()
			return _resistance.contact_position() if step != null and step.is_pickup else Vector2.INF
		"task":
			return _task_target()
		"calm":
			return _nearest_calm()
		"home":
			return _city.map.home_world_position()
		_:
			if word.begins_with("spawn:"):
				return DevRig.for_spawn_target(word.get_slice(":", 1), _city, _resistance)
			push_warning("--route: unknown target '%s'" % word)
			return Vector2.INF

## `task`'s own resolution: the step the mark just unlocked, which is null until the mark is
## actually touched (see `ResistanceDirector._on_contact_completed()`) — so this answers `INF`
## for exactly as long as `mark` itself would have, on a day with a task still to walk to.
func _task_target() -> Vector2:
	var step := _resistance.current_step()
	if step == null or step.is_pickup:
		return Vector2.INF
	if step.is_one_place:
		return _resistance.contact_position()
	return _nearest_live_instance(step.task_event_id)

func _nearest_live_instance(event_id: String) -> Vector2:
	var best := Vector2.INF
	var best_distance := INF
	for instance: EventInstance in _city.events.instances():
		if instance.def.id != event_id or instance.is_finished:
			continue
		var distance := _player.global_position.distance_squared_to(instance.global_position)
		if distance < best_distance:
			best_distance = distance
			best = instance.global_position
	return best

## The nearest calm tile by walking distance, sidewalks preferred exactly as `_plan()` prefers them
## — see `_blocked_for_phase()`. `CityMap.calm_tiles()` is read live, so a park the day has already
## spoiled (day 12, once the swing is reached) is never offered back.
func _nearest_calm() -> Vector2:
	var here := _city.map.world_to_tile(_player.global_position)
	var best := _nearest_in_field(_city.map.walk_field(here, _blocked_for_phase(true)))
	if best == Vector2i(-1, -1):
		best = _nearest_in_field(_city.map.walk_field(here, _blocked_for_phase(false)))
	return _city.map.tile_to_world(best) if best != Vector2i(-1, -1) else Vector2.INF

func _nearest_in_field(field: PackedInt32Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := -1
	for tile in _city.map.calm_tiles():
		var distance := _city.map.distance_at(field, tile)
		if distance < 0:
			continue
		if best_distance == -1 or distance < best_distance:
			best_distance = distance
			best = tile
	return best

# ----------------------------------------------------------------- planning ---

## `_road_tiles` on top of today's `closed_tiles` while `sidewalk_only`, plus `avoid` — a
## temporary detour around a tile the tile grid calls open but she cannot actually stand on or
## pass, see `_avoid_zone()` — built fresh every call since `closed_tiles` genuinely changes day
## to day and a stale copy would let a plan walk through today's own barrier.
func _blocked_for_phase(sidewalk_only: bool, avoid: Dictionary = {}) -> Dictionary:
	var blocked := {}
	if sidewalk_only:
		for tile: Vector2i in _road_tiles:
			blocked[tile] = true
	for tile: Vector2i in _city.map.closed_tiles:
		blocked[tile] = true
	for tile: Vector2i in avoid:
		blocked[tile] = true
	return blocked

## A ring of tiles `radius` out from `centre`, `centre` itself deliberately excluded — folding it
## in would mark her own standing tile `BLOCKED`, which `CityMap.walk_field_from()` reads as
## nothing to seed the sweep from at all, so a plan asked to avoid where she is now would find
## every tile unreached rather than a detour around it.
func _avoid_zone(centre: Vector2i, radius: int) -> Dictionary:
	var avoid := {}
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx == 0 and dy == 0:
				continue
			avoid[centre + Vector2i(dx, dy)] = true
	return avoid

## The sidewalk-only shortest walk, or the unrestricted one where the first finds nothing —
## see the class doc, "Hugs the kerb" — smoothed by `_simplify()` either way. `avoid` is
## `_avoid_zone()`'s own detour, `{}` for an ordinary plan.
func _plan(from_tile: Vector2i, to_tile: Vector2i, avoid: Dictionary = {}) -> Array[Vector2i]:
	var path := _shortest(from_tile, to_tile, true, avoid)
	if path.is_empty():
		path = _shortest(from_tile, to_tile, false, avoid)
	return _simplify(path)

func _shortest(from_tile: Vector2i, to_tile: Vector2i, sidewalk_only: bool,
		avoid: Dictionary = {}) -> Array[Vector2i]:
	var field := _city.map.walk_field(from_tile, _blocked_for_phase(sidewalk_only, avoid))
	if _city.map.distance_at(field, to_tile) < 0:
		return []
	var reversed: Array[Vector2i] = [to_tile]
	var current := to_tile
	while current != from_tile:
		var next := _smaller_neighbour(field, current)
		if next == current:
			return [] # unreachable by construction of the check above; refuse rather than loop
		reversed.append(next)
		current = next
	reversed.reverse()
	return reversed

func _smaller_neighbour(field: PackedInt32Array, tile: Vector2i) -> Vector2i:
	var best := tile
	var best_distance := _city.map.distance_at(field, tile)
	for step in _STEPS:
		var neighbour := tile + step
		var distance := _city.map.distance_at(field, neighbour)
		if distance >= 0 and distance < best_distance:
			best = neighbour
			best_distance = distance
	return best

## String-pulling: a straight line from `path[anchor]` to `path[probe]` replaces every tile between
## them wherever `_line_of_sight()` allows it, so a corner is cut the way a person walks it rather
## than traced stair-step tile by tile.
func _simplify(path: Array[Vector2i]) -> Array[Vector2i]:
	if path.size() <= 2:
		return path
	var simplified: Array[Vector2i] = [path[0]]
	var anchor := 0
	var probe := 2
	while probe < path.size():
		if _line_of_sight(path[anchor], path[probe]):
			probe += 1
		else:
			simplified.append(path[probe - 1])
			anchor = probe - 1
			probe += 1
	simplified.append(path[path.size() - 1])
	return simplified

## A straight cut's own clearance either side of its centre line — comfortably past
## `Tuning.PLAYER_BODY_RADIUS` (14px), which is what a bare centreline sample cannot see: a line
## that only ever grazes a building's corner reads as clear tile by tile while her own collision
## shape still catches on the corner and stalls dead, pressing a heading that goes nowhere. Checked
## either side of the line rather than only widened at each sample point, so a cut still refuses a
## building that sits square against the line without ever being the line's own nearest tile.
const _LINE_OF_SIGHT_CLEARANCE := 24.0

## Whether the straight world-space line between two tile centres, with `_LINE_OF_SIGHT_CLEARANCE`
## either side of it, stays on open, unobstructed, non-`ROAD` ground the whole way — `CROSSING` (a
## zebra) is fine, since crossing there is legal; a bare `ROAD` tile is refused even if the raw
## walk touched one nearby, so smoothing can never introduce a fresh stretch of carriageway the
## kerb-preferring plan did not already decide it needed.
##
## **Refuses a true diagonal outright, before sampling anything.** `a` and `b` differing on both
## axes means the cut would cross a 2x2 corner the raw 4-connected walk never actually crossed —
## `ReachabilityGrid`'s own doc calls the case out by name: a cell can split into two components
## that do not connect to each other across exactly that corner, so open ground on both of the
## corner's *other* two tiles proves nothing about whether the fifth point, the corner itself, is
## walkable at all. A straight run along one row or one column carries no such gap — every tile it
## passes through was already a single 4-connected step somewhere in the raw walk — so smoothing
## only ever removes a redundant waypoint from a corridor already proven walkable tile by tile.
func _line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x and a.y != b.y:
		return false
	var start := _city.map.tile_to_world(a)
	var stop := _city.map.tile_to_world(b)
	var offset := stop - start
	if offset.length() < 0.001:
		return true
	var perpendicular := Vector2(-offset.y, offset.x).normalized() * _LINE_OF_SIGHT_CLEARANCE
	var steps := maxi(1, ceili(offset.length() / _LINE_OF_SIGHT_STEP))
	for i in steps + 1:
		var centre := start.lerp(stop, float(i) / float(steps))
		for point in [centre, centre + perpendicular, centre - perpendicular]:
			var tile := _city.map.world_to_tile(point)
			if not _city.map.is_open(tile) or _city.map.is_obstructed(tile):
				return false
			if _city.map.tile_at(tile) == GameEnums.TileType.ROAD:
				return false
	return true

func _to_world(path: Array[Vector2i]) -> Array[Vector2]:
	var world: Array[Vector2] = []
	for tile in path:
		world.append(_city.map.tile_to_world(tile))
	return world

func _begin_leg(target_world: Vector2) -> void:
	var here_tile := _city.map.world_to_tile(_player.global_position)
	var target_tile := _city.map.world_to_tile(target_world)
	var path := _plan(here_tile, target_tile)
	if path.is_empty():
		Telemetry.note("route", "day %d: no path to '%s', skipping" % [GameState.day, _current_word])
		_advance_target()
		return
	_current_target_tile = target_tile
	_current_target_world = target_world
	_waypoints = _to_world(path)
	# The exact point, not its tile's centre — a task's own contact or the calm tile she is meant
	# to stand in may sit off-centre within its tile.
	_waypoints[_waypoints.size() - 1] = target_world
	_leg_start_elapsed = _elapsed()
	_leg_start_position = _player.global_position
	_replan_elapsed = 0.0
	_stuck_reference = Vector2.INF
	_stuck_streak = 0
	_unsticking = false
	_unstick_cycles = 0

func _elapsed() -> float:
	return _day.time_total - _day.time_remaining

# ----------------------------------------------------------------- walking ---

func _follow(delta: float) -> void:
	if _waypoints.is_empty():
		_arrive()
		return
	_maybe_replan(delta)
	if _waypoints.is_empty() or _resolving:
		return
	var target := _waypoints[0]
	var offset := target - _player.global_position
	if offset.length() <= _ARRIVE_RADIUS:
		_waypoints.remove_at(0)
		_follow(delta)
		return
	var direction := offset.normalized()
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)

## Checked every `_REPLAN_INTERVAL`: a remaining waypoint that has closed or is now obstructed, or
## — whatever the tiles say — that she has covered less than `_STUCK_DISTANCE` since the last
## check, which is what a stall against a crowd or a body reads as when nothing overlaying the
## tiles has actually changed.
func _maybe_replan(delta: float) -> void:
	_replan_elapsed += delta
	if _replan_elapsed < _REPLAN_INTERVAL:
		return
	_replan_elapsed = 0.0
	var here := _player.global_position
	var stuck := _stuck_reference != Vector2.INF \
			and here.distance_to(_stuck_reference) < _STUCK_DISTANCE
	_stuck_reference = here
	if stuck:
		_stuck_streak += 1
		# A first stall replans the ordinary way, since the tile grid may simply have moved under
		# her. A second in a row means the grid says nothing changed and the ordinary replan
		# already tried and failed to move her — which is what standing *inside* an obstruction's
		# own collision reads as, `is_obstructed()` true for her own tile and no route out of one
		# tile changes that a step toward any of them is a step into the same solid body. Physically
		# working clear of it is `_begin_unstick()`'s job, not another plan.
		if _stuck_streak == 1:
			_replan()
		else:
			_begin_unstick()
		return
	_stuck_streak = 0
	for point in _waypoints:
		var tile := _city.map.world_to_tile(point)
		if not _city.map.is_open(tile) or _city.map.is_obstructed(tile):
			_replan()
			return

## The ordinary plan from wherever she actually is, or a detour around it (`_avoid_zone()`, two
## tiles out) once `_unstick()` has just worked her clear — see that function's own doc for why a
## plan alone cannot answer a physical wedge, only what to do once she is out of one.
func _replan(avoid_here: bool = false) -> void:
	var here_tile := _city.map.world_to_tile(_player.global_position)
	var path: Array[Vector2i] = []
	if avoid_here:
		path = _plan(here_tile, _current_target_tile, _avoid_zone(here_tile, 2))
	if path.is_empty():
		path = _plan(here_tile, _current_target_tile)
	if path.is_empty():
		Telemetry.note("route", "day %d: '%s' no longer reachable, skipping"
				% [GameState.day, _current_word])
		_release()
		_advance_target()
		return
	_waypoints = _to_world(path)
	_waypoints[_waypoints.size() - 1] = _current_target_world
	Telemetry.note("route", "day %d: re-planned to '%s' (%.1fs, %d waypoints)"
			% [GameState.day, _current_word, _elapsed(), _waypoints.size()])

# ----------------------------------------------------------------- unsticking ---

## The eight compass points, tried in turn — an escape direction is found by trying one, not by
## reasoning about the obstruction's own shape, which this class has no way to ask about; the tile
## grid already said the ground all round her reads open (`_maybe_replan()`'s own check on the
## remaining waypoints is what already ruled out a closed or obstructed *waypoint*, so what is left
## unexplained is her own footing).
## The diagonals are `sqrt(0.5)` a side rather than `.normalized()` at the call site, since a
## `const` initialiser has to be a constant expression and cannot call a method — `Input.get_vector`
## clamps to unit length regardless, so the two are the same press either way.
const _UNSTICK_DIRECTIONS: Array[Vector2] = [
	Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
	Vector2(0.7071067811865476, -0.7071067811865476), Vector2(-0.7071067811865476, -0.7071067811865476),
	Vector2(0.7071067811865476, 0.7071067811865476), Vector2(-0.7071067811865476, 0.7071067811865476),
]
## How long one direction is held before the next is tried — long enough to actually work a tight
## wedge loose. A collision response against two solid bodies at once can yield only a pixel or
## two per physics tick, so a short hold reads a direction that is genuinely working as a failure
## and moves on before it has covered anything.
const _UNSTICK_TRY_SECONDS := 2.0
## Clear of the wedge once she has covered this much from where the maneuver began — a full tile
## past `Tuning.TILE_SIZE` (32px), so sliding a few px along whatever she is wedged against is
## never mistaken for having come free of it.
const _UNSTICK_CLEAR_DISTANCE := 48.0
## Full eight-direction cycles tried before the target itself is given up on rather than tried
## again — a wedge that survives three full cycles (up to 48s, well inside a day's own length) is
## not one more heading going to answer.
const _UNSTICK_MAX_CYCLES := 3

var _unsticking := false
var _unstick_index := 0
var _unstick_elapsed := 0.0
var _unstick_anchor := Vector2.INF
var _unstick_cycles := 0

func _begin_unstick() -> void:
	_unsticking = true
	_unstick_index = 0
	_unstick_elapsed = 0.0
	_unstick_anchor = _player.global_position

## Holds each of `_UNSTICK_DIRECTIONS` in turn until she has actually moved `_UNSTICK_CLEAR_DISTANCE`
## from where the maneuver began, or every direction has had its turn without one working.
func _unstick(delta: float) -> void:
	var direction := _UNSTICK_DIRECTIONS[_unstick_index]
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)
	if _player.global_position.distance_to(_unstick_anchor) >= _UNSTICK_CLEAR_DISTANCE:
		_end_unstick(true)
		return
	_unstick_elapsed += delta
	if _unstick_elapsed < _UNSTICK_TRY_SECONDS:
		return
	_unstick_elapsed = 0.0
	_unstick_index += 1
	if _unstick_index >= _UNSTICK_DIRECTIONS.size():
		_unstick_index = 0
		_unstick_cycles += 1
		if _unstick_cycles >= _UNSTICK_MAX_CYCLES:
			_end_unstick(false)

func _end_unstick(cleared: bool) -> void:
	_unsticking = false
	_release()
	_stuck_streak = 0
	_stuck_reference = Vector2.INF
	if not cleared:
		Telemetry.note("route", "day %d: '%s' stuck fast, skipping" % [GameState.day, _current_word])
		_advance_target()
		return
	_unstick_cycles = 0
	_replan(true)

func _arrive() -> void:
	_release()
	var distance := _leg_start_position.distance_to(_player.global_position)
	Telemetry.note("route", "day %d: reached '%s' at %.1fs (day time), %.0fpx walked"
			% [GameState.day, _current_word, _elapsed(), distance])
	if _current_word == "calm":
		_settling = true
		return
	_advance_target()

## `calm` presses nothing and waits — the same standing still a played day's own settle is — until
## `Baby.state` reaches `ASLEEP`. Read every physics frame rather than on the `baby_state_changed`
## signal: this node is already ticking every frame it is not walking, and a poll costs nothing a
## signal connection would not have, without a second lifetime to manage.
func _check_settled() -> void:
	if _baby.state != GameEnums.BabyState.ASLEEP:
		return
	_settling = false
	Telemetry.note("route", "day %d: baby settled at 'calm', %.1fs (day time)"
			% [GameState.day, _elapsed()])
	_advance_target()

func _advance_target() -> void:
	_target_index += 1
	if _target_index >= _targets.size():
		_finish()
		return
	_begin_resolving(_targets[_target_index])

func _finish() -> void:
	_done = true
	_release()
	Telemetry.note("route", "day %d: route done, %.1fs (day time)" % [GameState.day, _elapsed()])
	get_tree().quit()

## A loss ends the measurement the same way reaching the last target does — logged and quit,
## rather than left to sit at a day summary nobody headless is going to dismiss. A `WON` result is
## deliberately not handled here: it can only ever follow *this* node walking her onto a `HOME`
## tile while `DayController.phase` is `RETURNING`, which is exactly `_arrive()`'s own `home` case,
## so that path already reports and quits before this signal could add anything to it.
func _on_day_finished(result: GameEnums.DayResult) -> void:
	if _done or result == GameEnums.DayResult.WON:
		return
	_done = true
	_release()
	Telemetry.note("route", "day %d: day ended (%s) before reaching '%s', %.1fs (day time)"
			% [GameState.day, GameEnums.DayResult.keys()[result], _current_word, _elapsed()])
	get_tree().quit()

func _release() -> void:
	TouchControls._set_axis(&"move_left", &"move_right", 0.0)
	TouchControls._set_axis(&"move_up", &"move_down", 0.0)
