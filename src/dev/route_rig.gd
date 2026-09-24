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
## asks for the shortest walk on a graph with every plain `ROAD` tile and every live hazard's own
## kill reach removed (`_hazard_tiles()`) — so a route always prefers the pavement, crosses only at
## a `CROSSING` (a zebra) it passes on the way, and keeps off a guard's own reach the way a player
## backs off once the meter spikes — and only falls back to the unrestricted graph, carriageway and
## hazard ground both included, when nothing safer can reach the target at all (the day 13
## roadblock's own band is `ROAD`/`CROSSING` ground, so its own last step always does; see
## `_HAZARD_MARGIN`'s own doc for why a guarded mark's own contact point never needs this). A
## hazard the plan cannot get around at all — an unlikely last resort, not the ordinary case — is
## walked through with hazards ignored entirely, rather than the target being reported unreachable
## for a margin that merely made it look that way. `_simplify()` then collapses a straight run
## along one row or column into its two ends, dropping the redundant waypoints in between — see
## `_line_of_sight()`'s own doc for why a true diagonal cut is refused outright rather than
## sampled: it can cross a 2x2 corner the raw 4-connected walk never actually crossed.
##
## **Re-plans when the way ahead closes, or turns dangerous — and the re-plan actually routes
## around what it found**, rather than recomputing the same path onto the same ground.
## `_maybe_replan()` checks the remaining waypoints against `CityMap.is_open()`,
## `CityMap.is_obstructed()` and `_is_hazardous()` every `_REPLAN_INTERVAL` seconds — closures are
## fixed for the day (see the city skill), but an obstruction (a fire's own spread, a parked van, a
## roadblock's own band) moves while the day is live and a hazard's own guard can start a pursuit
## mid-leg, and this is what catches either landing on a step already planned.
## `_blocked_for_phase()` folds `CityMap.obstructed_tiles` into every plan for exactly this reason:
## a `_plan()` that never looked at it would recompute the identical route onto the same
## obstruction and have `_maybe_replan()` catch the same thing again next check, forever. And it
## re-plans when she has simply stopped covering ground even though the tiles read fine — a body
## she has fetched up against, or standing *inside* an obstruction's own collision — which a second
## stall in a row escalates first to `_begin_wait()`, standing her still long enough for a crowd's
## own flow to open a gap the way a person eases up rather than shoves, and only once that alone has
## not moved her to `_begin_unstick()`, a short maneuver through the eight compass points that works
## her physically clear of a body waiting cannot do anything about.
##
## **Quits the run once it is done**, win or lose — a rig meant to be driven from a headless process
## by `tests/probes/` cannot wait at a day summary screen for a button nobody is going to press;
## see `_finish()` and `_on_day_finished()`.

## World-space arrival radius for a waypoint — comfortably inside `ContactPoint.REACH` (36px), so a
## mark or a task's own contact always completes on the way in, and small enough (under a third of
## `Tuning.TILE_SIZE`, 32px) that switching to the next waypoint never visibly overshoots the line
## `_simplify()` drew.
const _ARRIVE_RADIUS := 10.0

## World-space half-length of `_pace()`'s own back-and-forth walk while settling at `calm` —
## comfortably inside half `Tuning.TILE_SIZE` (16px) even measured from the tile's own centre, so a
## lap can never carry her onto a neighbouring tile's own `sleepiness_multiplier()` or off calm
## ground entirely. See `_pace()`'s own doc for why she paces instead of standing.
const _SETTLE_PACE_HALF := 10.0

## How close counts as "reached this end of the pace" — well under `_SETTLE_PACE_HALF` so the walk
## actually covers most of it before turning, unlike `_ARRIVE_RADIUS`, which is sized against
## `ContactPoint.REACH` for a different kind of arrival entirely.
const _SETTLE_ARRIVE_RADIUS := 3.0

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

## This rig's own running total of every `_physics_process(delta)` it has been given since
## `start_day()`, which is what `_elapsed()` reports rather than `_day.time_total -
## _day.time_remaining` — see that function's own doc for why.
var _elapsed_seconds := 0.0

var _resolving := false
var _resolve_elapsed := 0.0
var _settling := false
## Where `_pace()` centres the little back-and-forth walk `_check_settled()` keeps her on — the
## exact calm point `_nearest_calm()` verified (`_current_target_world`), not wherever
## `_ARRIVE_RADIUS` let her stop short of it, so the pace never carries the slop of one radius into
## the other. `Vector2.INF` outside a settle. See `_pace()`'s own doc for why she paces at all.
var _settle_anchor := Vector2.INF
## Which end of the pace she is walking toward — flips every time she reaches one.
var _settle_forward := true
var _replan_elapsed := 0.0
## Where she stood at the last `_maybe_replan()` check — `Vector2.INF` right after a leg begins,
## so the very first check has nothing to compare against yet. See `_STUCK_DISTANCE`.
var _stuck_reference := Vector2.INF
## How many `_maybe_replan()` checks in a row have found her stuck — reset to 0 the moment one
## does not. A first stall replans the ordinary way, since the tile grid may simply have changed;
## a second in a row means the grid says nothing is wrong and the ordinary replan already tried
## and failed to move her, so `_maybe_replan()` escalates to `_begin_wait()`; a third — still stuck
## right after waiting — escalates again, to a physical detour around wherever she actually is.
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
	_elapsed_seconds = 0.0
	_waypoints.clear()
	_resolving = false
	_settling = false
	_settle_anchor = Vector2.INF
	_waiting = false
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
	_elapsed_seconds += delta
	if _resolving:
		_try_resolve(delta)
		return
	if _settling:
		_check_settled()
		return
	if _waiting:
		_wait(delta)
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

## The nearest calm tile by walking distance, sidewalks and hazard-free ground preferred exactly as
## `_plan()` prefers them — see `_blocked_for_phase()`. `CityMap.calm_tiles()` is read live, so a
## park the day has already spoiled (day 12, once the swing is reached) is never offered back.
func _nearest_calm() -> Vector2:
	var here := _city.map.world_to_tile(_player.global_position)
	var hazards := _hazard_tiles()
	var best := _nearest_in_field(_city.map.walk_field(here, _blocked_for_phase(true, {}, hazards)))
	if best == Vector2i(-1, -1):
		best = _nearest_in_field(_city.map.walk_field(here, _blocked_for_phase(false, {}, hazards)))
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

## `_road_tiles` on top of today's `closed_tiles` and `CityMap.obstructed_tiles` while
## `sidewalk_only`... no — `closed_tiles` and `obstructed_tiles` block a plan regardless of
## `sidewalk_only`; `hazards` (see `_hazard_tiles()`) and `avoid` (a temporary detour around a tile
## the tile grid calls open but she cannot actually stand on or pass, see `_avoid_zone()`) are
## added on top of all of that. Built fresh every call since `closed_tiles`, every live
## obstruction's own footprint and every live hazard's own position genuinely change day to day
## and frame to frame, and a stale copy would let a plan walk through today's own barrier, a body
## parked since the last check, or yesterday's guard. `CityMap.obstructed_tiles` (`src/city/
## city_map.gd`) is what `_maybe_replan()`'s own `is_obstructed()` check reads — folding it in here
## too is what makes a replan actually route around the thing it just detected, rather than
## recomputing the identical path onto the same obstruction and re-detecting it forever; a plan
## that never looked at `obstructed_tiles` at all was the shape of that bug. `hazards` is taken as
## a dictionary rather than computed here so a caller can drop the one tile it is actually trying
## to reach from it first — see `_shortest()`.
func _blocked_for_phase(sidewalk_only: bool, avoid: Dictionary = {},
		hazards: Dictionary = {}) -> Dictionary:
	var blocked := {}
	if sidewalk_only:
		for tile: Vector2i in _road_tiles:
			blocked[tile] = true
	for tile: Vector2i in _city.map.closed_tiles:
		blocked[tile] = true
	for tile: Vector2i in _city.map.obstructed_tiles:
		blocked[tile] = true
	for tile: Vector2i in hazards:
		blocked[tile] = true
	for tile: Vector2i in avoid:
		blocked[tile] = true
	return blocked

## Margin added past a live hard_fail event's own `lethal_reach()` when deciding what ground to
## keep off — `Tuning.PLAYER_BODY_RADIUS` (14px), the width of the body actually walking the
## boundary `_hazard_tiles()` draws. `_hazard_tiles()` tests each tile's own **nearest point**
## against the reach, not its centre, so this margin does not also have to cover a tile's own
## half-diagonal the way a centre-distance test would — a nearest-point test already sees a tile's
## corner for what it is. A bigger margin here (an earlier build used the half-diagonal-plus-body
## sum, 38px, over a centre-distance test) blocks a wider ring than the true kill radius needs,
## and on a two-tile-wide alley — the guard's own placement, `alley_robbery.placement = [ALLEY]`,
## and *"a robber who never moves is avoidable by walking two tiles wide of him"* — a wide enough
## ring can span the whole width and leave no tile within one hop of wherever she is already
## standing that is not itself still "blocked", which is a plan that can never get out from
## wherever it started rather than one that avoids the guard. See `_hazard_tiles()`'s own doc.
const _HAZARD_MARGIN := Tuning.PLAYER_BODY_RADIUS

## Whether `instance` is a hard_fail row worth planning a route around at all — live, and
## `not def.mobile`. A stationary kill (the guard `alley_robbery` places over every mark, an
## idling `abduction` van, `reversing_lorry`, `car_accident`) is exactly the shape a route can
## detour once and stay clear of for the whole leg, the same as a parked obstruction. A `mobile`
## one (`cyclist`, `masked_pursuer`) is somewhere else by the time a replan's own path would get
## there — blocking around its instantaneous position chases a moving point with a stale detour,
## which is what turned day 6 seed 4242's 'task' leg (homeless_yeller's own pacing crossing a
## cyclist's route) into a replan every `_REPLAN_INTERVAL` for the rest of the run rather than a
## leg that ever finished. A moving hard_fail hazard is exactly what the excitement meter and the
## screen-edge badge already warn a player to react to as it closes, not something a route is
## planned around from a distance; this rig has no reactive dodge, so it leaves a mobile hazard to
## `_maybe_replan()`'s ordinary stuck/obstruction handling instead of a dedicated avoidance.
func _is_stationary_hazard(instance: EventInstance) -> bool:
	return not instance.is_finished and instance.def.hard_fail and not instance.def.mobile

## Whether `point` sits within a live stationary hard_fail event's own kill reach plus
## `_HAZARD_MARGIN` — every mark is guarded (`docs/DECISIONS.md`, "every mark is guarded"), and the
## guard carries no body for `is_obstructed()` to see, only a radius that ends the day. A player
## backs off the instant the excitement meter spikes; this is what the same caution reads as for a
## rig with no meter to watch.
func _is_hazardous(point: Vector2) -> bool:
	for instance: EventInstance in _city.events.instances():
		if not _is_stationary_hazard(instance):
			continue
		if point.distance_to(instance.global_position) <= instance.def.lethal_reach() + _HAZARD_MARGIN:
			return true
	return false

## Every tile within a live stationary hard_fail event's own kill reach plus `_HAZARD_MARGIN`,
## tested against each candidate tile's own **nearest point** to the hazard rather than its
## centre — see `_HAZARD_MARGIN`'s own doc for why a centre-distance test blocks a wider ring than
## the true kill radius needs. Cheap: a handful of hard_fail instances are ever live at once, each
## with a two-or-three-tile reach.
func _hazard_tiles() -> Dictionary:
	var blocked := {}
	for instance: EventInstance in _city.events.instances():
		if not _is_stationary_hazard(instance):
			continue
		var reach := instance.def.lethal_reach() + _HAZARD_MARGIN
		var centre := _city.map.world_to_tile(instance.global_position)
		var radius_tiles := ceili(reach / Tuning.TILE_SIZE) + 1
		for dy in range(-radius_tiles, radius_tiles + 1):
			for dx in range(-radius_tiles, radius_tiles + 1):
				var tile := centre + Vector2i(dx, dy)
				if _tile_nearest_distance(tile, instance.global_position) <= reach:
					blocked[tile] = true
	return blocked

## The shortest distance from `point` to any point inside `tile`'s own square — `0.0` when `point`
## is over the tile at all, otherwise the distance to whichever edge or corner is nearest. The test
## `_hazard_tiles()` needs: not whether the tile's *centre* is far enough from a hazard, but
## whether *any ground on the tile* is close enough to end the day.
func _tile_nearest_distance(tile: Vector2i, point: Vector2) -> float:
	var centre := _city.map.tile_to_world(tile)
	var half := Tuning.TILE_SIZE / 2.0
	var dx := maxf(absf(point.x - centre.x) - half, 0.0)
	var dy := maxf(absf(point.y - centre.y) - half, 0.0)
	return Vector2(dx, dy).length()

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

## The sidewalk-only shortest walk keeping off every live hazard, or the unrestricted one where
## the first finds nothing — see the class doc, "Hugs the kerb" — or, only once both of those find
## nothing, the unrestricted walk with hazards ignored, so a guard that has boxed in the only way
## through skips the target rather than reporting one unreachable that a wider margin merely made
## look that way. Smoothed by `_simplify()` either way. `avoid` is `_avoid_zone()`'s own detour,
## `{}` for an ordinary plan.
func _plan(from_tile: Vector2i, to_tile: Vector2i, avoid: Dictionary = {}) -> Array[Vector2i]:
	var path := _shortest(from_tile, to_tile, true, avoid)
	if path.is_empty():
		path = _shortest(from_tile, to_tile, false, avoid)
	if path.is_empty():
		path = _shortest(from_tile, to_tile, false, avoid, false)
	return _simplify(path)

## `to_tile` is dropped from the hazard set before it blocks anything — the fairness contract that
## guards a mark (`docs/DECISIONS.md`, "The guard robber is placed inside a building": the least a
## guarded mark's own contact point is ever placed from its guard is `alley_robbery.inner_radius +
## ContactPoint.REACH`, 66px) already keeps the exact point she is walking to outside the true kill
## radius; `_HAZARD_MARGIN`'s own slack can still read the target's own tile as blocked without
## this, which would report a guarded mark unreachable rather than merely guarded. `from_tile` is
## dropped from the **whole** blocked set, hazard and obstruction and closure alike — the failure
## `_avoid_zone()`'s own doc names for her own standing tile: `CityMap.walk_field_from()` reads a
## blocked seed as nothing to sweep from at all, so anything that merely brushes wherever she
## already legally is (a hazard's own margin close by but outside the true kill radius, since she
## is walking and not dead; a fresh obstruction that has just closed in around her) would report
## *every* tile unreached rather than a detour away from it — the shape of bug that turned a walk
## past a stationary guard, at a safe distance a margin's own slack still read as blocked, into a
## replan every check for the rest of the run rather than a route that ever got past it. The
## ground *around* either tile keeps its ordinary rules — only the one tile she is actually
## standing on, or the one she is actually trying to reach, is ever exempted.
func _shortest(from_tile: Vector2i, to_tile: Vector2i, sidewalk_only: bool,
		avoid: Dictionary = {}, avoid_hazards: bool = true) -> Array[Vector2i]:
	var hazards := _hazard_tiles() if avoid_hazards else {}
	hazards.erase(to_tile)
	var blocked := _blocked_for_phase(sidewalk_only, avoid, hazards)
	blocked.erase(from_tile)
	var field := _city.map.walk_field(from_tile, blocked)
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
## either side of it, stays on open, unobstructed, non-`ROAD`, non-hazardous ground the whole way —
## `CROSSING` (a zebra) is fine, since crossing there is legal; a bare `ROAD` tile is refused even
## if the raw walk touched one nearby, so smoothing can never introduce a fresh stretch of
## carriageway the kerb-preferring plan did not already decide it needed. Checked against
## `_is_hazardous()` too — the raw walk already kept off a live guard's own reach (`_hazard_tiles()`
## in `_blocked_for_phase()`); a straight cut refusing the same ground is what keeps a corner-cut
## from putting that ground back.
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
			if _is_hazardous(point):
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
	_waiting = false
	_unsticking = false
	_unstick_cycles = 0
	_leg_stall_episodes = 0

## Elapsed day time, in simulated seconds — this rig's own `_elapsed_seconds`, not
## `_day.time_total - _day.time_remaining`. The two agree while the day is played straight, since
## both are the same sum of physics deltas since the day began; they part company under
## `--invincible`, which `DayController._process()` (`src/day/day_controller.gd`) stands still on
## purpose — *"the clock never moves"*, so the capture it exists for never runs out of day — which
## is exactly wrong for the number this class exists to report. A `--route` run *under*
## `--invincible` (the only way to measure whether a day fits its clock without the meter or an
## event ending it first) would otherwise log every target reached at a flat 0.0s, which answers
## nothing. `Time.get_ticks_msec()` was the other candidate and is wrong for a different reason:
## headless Godot runs unthrottled, so real wall-clock seconds and simulated seconds are not the
## same number, and `Tuning.day_length()` is stated in simulated seconds.
func _elapsed() -> float:
	return _elapsed_seconds

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
		# already tried and failed to move her, which a crowd she cannot yet press through and a
		# body she has fetched up against both read as — `is_obstructed()` true for her own tile,
		# or simply true for every neighbour that leads toward the target. The two want different
		# answers, cheapest first: `_begin_wait()` stands her still long enough for a crowd's own
		# flow to open a gap, the way a person eases off a crush rather than shoving through it,
		# and only a THIRD stall in a row — still stuck right after waiting, so waiting alone was
		# not the answer — escalates to `_begin_unstick()`'s physical maneuver, for a body no
		# amount of waiting moves aside. One `_leg_stall_episodes` spent either way, so a
		# chokepoint that keeps re-catching her still gives up after `_LEG_MAX_STALL_EPISODES`
		# encounters rather than trying forever.
		if _stuck_streak == 1:
			_replan()
		elif _stuck_streak == 2:
			if _leg_stall_episodes >= _LEG_MAX_STALL_EPISODES:
				Telemetry.note("route", "day %d: '%s' stuck fast, skipping" % [GameState.day, _current_word])
				_release()
				_advance_target()
			else:
				_leg_stall_episodes += 1
				_begin_wait()
		else:
			_begin_unstick()
		return
	_stuck_streak = 0
	for i in _waypoints.size():
		var point: Vector2 = _waypoints[i]
		var tile := _city.map.world_to_tile(point)
		if not _city.map.is_open(tile) or _city.map.is_obstructed(tile):
			_replan()
			return
		# The first remaining waypoint is wherever she already legally is (about to be popped this
		# same `_follow()` call), and the last is the exact target — `_shortest()` exempts both of
		# those tiles from hazard blocking, for the reason its own doc gives (a guard's margin can
		# brush a spot she is already standing on safely, or the exact contact point a mark's own
		# fairness contract keeps just inside the margin). Checking either against the raw,
		# unexempted `_is_hazardous()` here would replan forever over ground already accepted as
		# safe enough to stand on, rather than catching a hazard newly astride ground *between* the
		# two she has not reached yet.
		if i > 0 and i < _waypoints.size() - 1 and _is_hazardous(point):
			_replan()
			return

## The ordinary plan from wherever she actually is, or a detour around it (`_avoid_zone()`, two
## tiles out) once `_unstick()` has just worked her clear, or `_end_wait()` has just let a crowd
## flow past — see those functions' own docs for why a plan alone cannot answer either on its own.
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

# --------------------------------------------------------------------- waiting ---

## Standing still, pressing nothing, before the second stall in a row tries to force a way
## through — long enough for a crowd's own flow to open a gap (a lane a couple of pedestrians wide
## clears in a couple of their own strides), short enough that a genuine physical wedge (a body she
## is fetched up against, which waiting cannot fix) still reaches `_begin_unstick()` well inside a
## leg's own budget. **A player facing a crowd crush eases off and lets it pass rather than
## shoving through it immediately**; this is what that caution looks like with no meter or eyes to
## judge the gap by, and it is cheap enough to try before ever reaching for the eight-direction
## maneuver that `_begin_unstick()` is.
const _STUCK_WAIT_SECONDS := 3.0

var _waiting := false
var _wait_elapsed := 0.0

func _begin_wait() -> void:
	_waiting = true
	_wait_elapsed = 0.0
	_release()

func _wait(delta: float) -> void:
	_wait_elapsed += delta
	if _wait_elapsed >= _STUCK_WAIT_SECONDS:
		_end_wait()

## Resumes the leg with a fresh plan — cheap, and correct even where nothing needed it, since a
## crowd is not a tile-level change `_plan()` would otherwise have any reason to notice. **Sets
## `_stuck_reference` to right now, not `Vector2.INF`.** `_begin_leg()`'s own `Vector2.INF` means
## "nothing to compare against yet"; here there is something to compare against — wherever she
## already was throughout the wait — and comparing against that stale position would read three
## motionless seconds as a fresh stall the instant the next check runs, which is exactly the loop
## `_stuck_streak` staying untouched here is for: the ladder in `_maybe_replan()` already advanced
## it to 2 on the way in, so a genuine still-stuck reading on the very next check is what reaches
## `_begin_unstick()` rather than another wait.
func _end_wait() -> void:
	_waiting = false
	_stuck_reference = _player.global_position
	_replan()

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

## Separate stuck-encounters given to one leg before it is given up on — not the same count as
## `_UNSTICK_MAX_CYCLES`, which bounds one continuous wedge. Spent in `_maybe_replan()` the moment
## a second stall in a row reaches for `_begin_wait()`, whether that encounter is settled by
## waiting alone or has to go on to `_begin_unstick()` too — `_end_unstick(true)` clears *this*
## wedge and immediately `_replan(true)`s, so a chokepoint she cannot actually get past (a parked
## van's own lane with the carriageway detour around it also busy, on a street with no third way
## through) reads as "cleared" every time and sends her straight back at it — three separate
## encounters is the whole leg giving up on a spot that keeps re-catching her rather than retrying
## it forever.
const _LEG_MAX_STALL_EPISODES := 3

var _unsticking := false
var _unstick_index := 0
var _unstick_elapsed := 0.0
var _unstick_anchor := Vector2.INF
var _unstick_cycles := 0
## Reset in `_begin_leg()`; counts every stuck-encounter this leg has needed a `_begin_wait()` for,
## settled by waiting alone or not — see `_LEG_MAX_STALL_EPISODES`.
var _leg_stall_episodes := 0

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
		_settle_anchor = _current_target_world
		_settle_forward = true
		return
	_advance_target()

## `calm` keeps her pacing rather than standing, until `Baby.state` reaches `ASLEEP` — **standing
## still is the wrong way to settle her.** `Baby._update_sleepiness()` (`src/player/baby.gd`) only
## fills the sleepiness meter while she is walking, scaled by the ground's own
## `sleepiness_multiplier()` (`Tuning.SLEEPINESS_GAIN_WALKING`, 0.42/s); standing idle *drains* it
## instead, at `Tuning.SLEEPINESS_DRAIN_IDLE` (1.0/s) — faster than walking on calm ground fills it
## at any lot size under the multiplier's own cap. An earlier build of this class had her stop and
## wait the way a played day's own doorstep return does, which cannot reach `ASLEEP` from any
## sleepiness below the max: the meter only ever drains from there, so she stood at a park forever.
## `_pace()` is what being "at" `calm` and not idle looks like for a rig with no thumb to rock the
## pram with. Read every physics frame rather than on the `baby_state_changed` signal: this node is
## already ticking every frame it is not walking a leg, and a poll costs nothing a signal
## connection would not have, without a second lifetime to manage.
func _check_settled() -> void:
	if _baby.state == GameEnums.BabyState.ASLEEP:
		_settling = false
		_settle_anchor = Vector2.INF
		_release()
		Telemetry.note("route", "day %d: baby settled at 'calm', %.1fs (day time)"
				% [GameState.day, _elapsed()])
		_advance_target()
		return
	_pace()

## A short walk between two points `_SETTLE_PACE_HALF` either side of `_settle_anchor`, turning
## around at `_SETTLE_ARRIVE_RADIUS` of whichever end is currently ahead — see `_check_settled()`'s
## own doc for why standing still cannot settle the baby at all. Along the world X axis only,
## which is the ordinary case for open calm ground; a calm tile narrow enough on that axis to catch
## her mid-pace is the same shape of edge case `_begin_unstick()` already exists to work her clear
## of.
func _pace() -> void:
	var target := _settle_anchor + (Vector2.RIGHT if _settle_forward else Vector2.LEFT) * _SETTLE_PACE_HALF
	var offset := target - _player.global_position
	if offset.length() <= _SETTLE_ARRIVE_RADIUS:
		_settle_forward = not _settle_forward
		return
	var direction := offset.normalized()
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)

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

## Any day ending — a loss, or a win — is logged and quit rather than left to sit at a day summary
## nobody headless is going to dismiss.
##
## **`WON` is not a no-op here, and finding out why it has to be one is worth keeping.** A won day
## can only follow *this* node walking her onto a `HOME` tile while `DayController.phase` is
## `RETURNING`, which reads as `_arrive()`'s own `home` case — so the first build of this class
## left `WON` unhandled, on the reasoning that `_arrive()` already reports and quits before this
## signal could add anything to it. That reasoning assumes the two checks agree on the instant
## "home" happens, and they do not: `DayController`'s own `WON` fires the moment she is anywhere
## on the `HOME` tile, while `_arrive()`'s own arrival is `_ARRIVE_RADIUS` (10px) of
## `CityMap.home_world_position()` specifically, a tighter target inside the same tile she can
## still be a few pixels short of. A day that wins on that gap ends — `_day.is_running()` false —
## before `_arrive()` ever fires, and `_physics_process()`'s own first line already returns without
## reaching it, so nothing downstream was ever going to catch the miss: the rig sat there for the
## rest of whatever timeout was watching it, headless and silent. Seed 4242, day 6, `mark,task,
## calm,home` is the reproduction — `task` gives up, `calm` settles, and the walk home wins the day
## a few pixels before `_arrive()`'s own check would have.
func _on_day_finished(result: GameEnums.DayResult) -> void:
	if _done:
		return
	_done = true
	_release()
	if result == GameEnums.DayResult.WON:
		Telemetry.note("route", "day %d: day won at %.1fs (day time), still walking to '%s'"
				% [GameState.day, _elapsed(), _current_word])
	else:
		Telemetry.note("route", "day %d: day ended (%s) before reaching '%s', %.1fs (day time)"
				% [GameState.day, GameEnums.DayResult.keys()[result], _current_word, _elapsed()])
	get_tree().quit()

func _release() -> void:
	TouchControls._set_axis(&"move_left", &"move_right", 0.0)
	TouchControls._set_axis(&"move_up", &"move_down", 0.0)
