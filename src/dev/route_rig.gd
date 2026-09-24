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
## `_try_resolve()` and `_begin_leg()`. **Day 14's `mark` and `task` are unavailable on a bare
## `--day 14` run with nothing else played first** — the last night has no mark of its own
## (`ResistanceSteps._finale()`) and is only offered once `GameState.sabotage_available()` holds
## (`Tuning.RESISTANCE_GOAL`, 5 earlier tasks done), which an isolated day never carries. That is a
## measurement fact about the calendar, not a bug in this rig: `calm` and `home` still resolve and
## time normally, and the finale's own leg needs the goal met to be timed at all.
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
## **Keeps clear of a solid body by the body's own outline, not by the tile it stands on.**
## `CityMap.obstructed_tiles` records a tile only where a body covers the tile's centre — right for
## the crowd, which walks a lane's centre line, and not enough for her: a kerbed `delivery_van`
## (22px) covers only its own kerb tile, yet leaves the frontage tile beside it a 26px gap to the
## wall for her 28px body, so a plan that read only the record walked her flush into the van.
## `_body_clear_tiles()` adds every tile whose centre lies within `Tuning.PLAYER_BODY_RADIUS` of a
## stationary body's own surface, measured against the body's real shape, and every plan keeps off
## those first (see `_plan()` for the order it gives each preference up in). **Every body and every
## door the day has sited counts, not only the ones streamed in near her** — see
## `_body_clear_tiles()` and `_door_tiles()`.
##
## **Routes around the body that caught her, and backs away from it.** A stall reads her own slide
## collisions (`_note_what_caught_her()`): the ground round whatever she is pressed against — a
## body's whole outline, or the spot on a wall she touched — is kept off for the rest of the leg
## (`_leg_avoid`), so a re-plan goes round it rather than straight back to the same pinch, and
## `_begin_unstick()` tries the compass points in the order that points away from it.
##
## **Follows a target that moves, and counts a mark as reached when it is.** A mark nobody has seen
## is moved to an alley near her (`ResistanceDirector._move_the_mark()`), usually on the day's first
## frame — after this rig has already planned to where it stood at dawn — so `_retarget_if_moved()`
## re-reads `mark` and `task` at every check. A `mark` or `task` leg ends the moment the director
## records its step completed, which is what reaching it means, rather than at a point 10px from
## its centre that a body beside it may keep her from.
##
## **Waits out a door and plans from its far side.** A checkpoint holding her is not a stall, and
## the door sets her down on its far side, where the plan made before it is stale — see
## `_held_at_a_door()`.
##
## **Quits the run once it is done**, win or lose — a rig meant to be driven from a headless process
## by `tests/probes/` cannot wait at a day summary screen for a button nobody is going to press;
## see `_finish()` and `_on_day_finished()` — and, under `--invincible`, once its own clock passes
## the day's length (`_out_of_day()`).

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

## Further than this in one physics frame is a teleport, not a step — a tile, where walking covers
## `Tuning.WALK_SPEED` (92px/s) over a sixtieth of a second, about a pixel and a half.
const _TELEPORT_DISTANCE := Tuning.TILE_SIZE * 1.0

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

## The ground round every body that has caught her this leg, kept off by every plan the leg makes
## after — see `_note_what_caught_her()`. Cleared when a leg begins, since a body that pinned her on
## the way to the mark says nothing about the walk to the park.
var _leg_avoid := {}
## How many times each door has held her this leg, by the door's own tile — see
## `_held_at_a_door()`.
var _door_holds := {}
## Which way is away from whatever caught her last — the sum of her slide collisions' own normals,
## each of which points from the thing she touched toward her. `Vector2.ZERO` when nothing solid
## was touching her (a crowd she was pressing into, or a hold), which leaves `_begin_unstick()` its
## plain compass order.
var _caught_away := Vector2.ZERO
## What caught her last, for the "stuck fast" line: an event row's id, the tile type of a wall, or
## a sentence for a stall with nothing solid touching her.
var _caught_by := ""
## Where she stood when it did, for the same line.
var _caught_tile := Vector2i.ZERO
## The resistance step on offer when a `mark` or `task` leg began, so the leg can end when the
## director records it completed — see `_step_completed()`. `null` on every other leg.
var _leg_step: ResistanceSteps.Step
## Whether the live plan was made keeping clear of every body (`_body_clear_tiles()`), which is
## what lets `_maybe_replan()` re-plan when a body the director sites from her walk reaches over a
## waypoint, without re-planning every check onto a plan that had to give the clearance up to find
## a way at all.
var _plan_kept_clear := false
## The same for the doors' reach (`_door_tiles()`).
var _plan_kept_doors := false
## Whether a door was holding her at the last walking frame — see `_held_at_a_door()`.
var _held := false
## Where she stood at the last physics frame, and whether she has moved further than
## `_TELEPORT_DISTANCE` since — which walking never does, and a door setting her down on its far
## side always does. `Vector2.INF` before the day's first frame.
var _last_position := Vector2.INF
var _teleported := false
## The day this rig's queue was started for, read once in `start_day()`. `GameState.day` has
## already moved to the next day by the time `DayController.day_finished` reports a win, so a line
## written from `_on_day_finished()` would otherwise name the wrong day.
var _day_number := 0

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
	_day_number = GameState.day
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
	_leg_avoid = {}
	_door_holds = {}
	_caught_away = Vector2.ZERO
	_leg_step = null
	_task_instance = null
	_planned_clear = {}
	_latched_doors = {}
	_gate_ground_ready = false
	_held = false
	_last_position = Vector2.INF
	_teleported = false
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
	if DevFlags.invincible() and _elapsed_seconds > _day.time_total:
		_out_of_day()
		return
	var here := _player.global_position
	_teleported = _last_position != Vector2.INF and here.distance_to(_last_position) > _TELEPORT_DISTANCE
	_last_position = here
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
		Telemetry.note("route", "day %d: '%s' unavailable, skipping" % [_day_number, _current_word])
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
		"calm:home":
			return _nearest_calm(true)
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

## The live instance an any-instance `task` is walking to, kept for as long as it lasts — see
## `_nearest_live_instance()`. Cleared in `start_day()`.
var _task_instance: EventInstance = null

## The nearest live instance of `event_id` when the task is first resolved, and **that same one
## after**, for as long as it is live and unfinished. Asking afresh at every check handed a leg
## walking between two roadblocks the nearer of the two each time she drew level with the middle,
## so the target swapped back and forth for the rest of the day. An instance that has finished or
## streamed out (freed) is let go, and the nearest live one answers again.
func _nearest_live_instance(event_id: String) -> Vector2:
	if _task_instance != null and (not is_instance_valid(_task_instance)
			or _task_instance.is_finished or _task_instance.def.id != event_id):
		_task_instance = null
	if _task_instance == null:
		var best_distance := INF
		for instance: EventInstance in _city.events.instances():
			if instance.def.id != event_id or instance.is_finished:
				continue
			var distance := _player.global_position.distance_squared_to(instance.global_position)
			if distance < best_distance:
				best_distance = distance
				_task_instance = instance
	if _task_instance == null:
		return Vector2.INF
	return _reachable_point_near(_task_instance.global_position)

## How far outward `_reachable_point_near()` searches, in tiles, before giving up and handing back
## `centre` unchanged — past `roadblock`'s own solid reach (`obstructs_radius` 60px, under two
## tiles) with room to spare, so a body this catalogue actually places is always found well inside
## the budget and only a malformed future row would ever exhaust it.
const _NEAREST_OPEN_SEARCH_RADIUS := 6

## The walkable, unobstructed ground nearest `centre`, or `centre` itself when it already qualifies
## — every any-instance task but `roadblock` has no body at all (`homeless_yeller`'s own
## `obstructs_radius` is 0), so this is a no-op for them and changes nothing about how they resolve.
##
## **A solid row's own centre is exactly the ground `_plan()` refuses.** `roadblock` carries
## `def.solid(GroundShape.band(60.0))`, so `EventManager` rasterises its footprint into
## `CityMap.obstructed_tiles` the same way any parked body is (`_blocked_for_phase()`'s own doc),
## and unlike a hazard's own margin — which `_shortest()` explicitly drops for the tile a leg is
## walking to — an obstructed tile is never exempted for either end of a plan, because a body is
## really standing there. Handing `_begin_leg()` a target sitting inside one is a target no path
## can ever end on, which is the day 13 "no path to 'task'" this function exists to fix (a `--route`
## measurement found a live `roadblock` instance whose centre was its own solid band).
##
## **Walking to the nearest open ground next to the body reaches the row exactly as reliably as
## the real game's own random-bearing offset does, without reproducing its RNG draw.**
## `ResistanceDirector._reach_distance()` completes an any-instance task from `obstructs_radius +
## Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH` of the instance's centre (110px for `roadblock`,
## 60 + 14 + 36) — comfortably past where the solid edge itself sits (60px) — so standing on the
## closest ground the body actually leaves open is always well inside that reach, whichever side
## of it she approaches from.
##
## **Clear of the body's own outline too, not only off its recorded tiles**, since a tile beside a
## body can be one she cannot stand in the middle of (`_body_clear_tiles()`): a leg aimed there
## would press her against the body for its last few pixels. Where the clearance leaves nothing
## inside `_NEAREST_OPEN_SEARCH_RADIUS`, the nearest open, unrecorded tile answers instead.
func _reachable_point_near(centre: Vector2) -> Vector2:
	var centre_tile := _city.map.world_to_tile(centre)
	var clear := _body_clear_tiles()
	if _stands_open(centre_tile, clear):
		return centre
	for keep_clear: Dictionary in [clear, {}]:
		for radius in range(1, _NEAREST_OPEN_SEARCH_RADIUS + 1):
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					if maxi(absi(dx), absi(dy)) != radius:
						continue
					var tile := centre_tile + Vector2i(dx, dy)
					if _stands_open(tile, keep_clear):
						return _city.map.tile_to_world(tile)
	return centre

func _stands_open(tile: Vector2i, keep_clear: Dictionary) -> bool:
	return _city.map.is_open(tile) and not _city.map.is_obstructed(tile) and not keep_clear.has(tile)

## The nearest calm tile by walking distance, sidewalks, hazard-free ground and ground clear of
## every body preferred exactly as `_plan()` prefers them — see `_blocked_for_phase()` and
## `_body_clear_tiles()`, the second of which also keeps the calm tile itself off ground beside a
## body. `CityMap.calm_tiles()` is read live, so a park the day has already spoiled (day 12, once
## the swing is reached) is never offered back. Her own tile is never blocked, for the reason
## `_shortest()` gives: a sweep seeded on blocked ground reaches nothing at all.
##
## **`toward_home`, the `calm:home` target word** — docs/TODO.md, M181, "the late days are timed",
## item 3: day 9 on seed 90210 does not fit its clock (`tests/probes/m184_route_timing.gd`), and one
## of the two readings the queue names is that the plain nearest-to-her calm area can sit off the
## way home rather than on it. With this set, the pool is scored by her walk to the tile *plus* the
## tile's own walk home (`_nearest_in_field_toward_home()`), so the leg still settles the baby
## without adding a detour the walk home would otherwise have to undo. **The default stays plain
## `calm`** — nearest to her — since nothing in the calendar but this one day and seed needed the
## other reading; `calm:home` is here for a caller (a probe, a future measurement) that wants it.
func _nearest_calm(toward_home: bool = false) -> Vector2:
	var here := _city.map.world_to_tile(_player.global_position)
	var home := _city.map.world_to_tile(_city.map.home_world_position())
	var hazards := _hazard_tiles()
	var guarded := hazards.duplicate()
	guarded.merge(_body_clear_tiles())
	var phases: Array[Dictionary] = [_blocked_for_phase(true, {}, guarded),
			_blocked_for_phase(false, {}, guarded), _blocked_for_phase(false, {}, hazards),
			_blocked_for_phase(false)]
	for blocked in phases:
		blocked.erase(here)
		var field := _city.map.walk_field(here, blocked)
		var best: Vector2i
		if toward_home:
			var home_blocked: Dictionary = blocked.duplicate()
			home_blocked.erase(home)
			best = _nearest_in_field_toward_home(field, _city.map.walk_field(home, home_blocked))
		else:
			best = _nearest_in_field(field)
		if best != Vector2i(-1, -1):
			return _city.map.tile_to_world(best)
	return Vector2.INF

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

## `_nearest_in_field()`'s own pool, scored by her own walk to the tile plus that tile's walk home
## (`home_field`, `CityMap.walk_field()` from the doorstep over the same blocked ground) rather than
## by her own walk alone — see `_nearest_calm()`'s doc on `toward_home`. A tile either field cannot
## reach is skipped, the same as a negative `distance_at()` already means for the plain reading.
func _nearest_in_field_toward_home(field: PackedInt32Array, home_field: PackedInt32Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_total := -1
	for tile in _city.map.calm_tiles():
		var distance := _city.map.distance_at(field, tile)
		if distance < 0:
			continue
		var home_distance := _city.map.distance_at(home_field, tile)
		if home_distance < 0:
			continue
		var total := distance + home_distance
		if best_total == -1 or total < best_total:
			best_total = total
			best = tile
	return best

# ----------------------------------------------------------------- planning ---

## Today's `closed_tiles`, `CityMap.obstructed_tiles`, today's soft-sealed pavement
## (`CityMap.soft_sealed_tiles`) and the ground a street door's boom would take her on
## (`_gate_ground()`), which block a plan whatever else it asks, plus `_road_tiles` while
## `sidewalk_only`; `hazards` (see `_hazard_tiles()`) and `avoid` (ground the tile grid calls open
## but she cannot stand in the middle of or should keep off, see `_plan()`) are added on top of all
## of that. Built fresh every call since `closed_tiles`, every live obstruction's own footprint and
## every live hazard's own position genuinely change day to day and frame to frame, and a stale copy
## would let a plan walk through today's own barrier, a body parked since the last check, or
## yesterday's guard. `CityMap.obstructed_tiles` (`src/city/ city_map.gd`) is what
## `_maybe_replan()`'s own `is_obstructed()` check reads — folding it in here too is what makes a
## replan actually route around the thing it just detected, rather than recomputing the identical
## path onto the same obstruction and re-detecting it forever; a plan that never looked at
## `obstructed_tiles` at all was the shape of that bug. `hazards` is taken as a dictionary rather
## than computed here so a caller can drop the one tile it is actually trying to reach from it first
## — see `_shortest()`.
##
## **A soft seal (`skip`/`scaffolding`, `moving_van`) shuts its pavement to a walker whatever tier
## this is, never only while `sidewalk_only`.** `CrowdAgent._cannot_go_on()` already refuses
## `CityMap.is_soft_sealed(tile)` for `Kind.WALKER` — "a soft seal takes both pavements and leaves
## the carriageway to the cars" — which a plan never asked before this: the ground either side of a
## soft seal's own body reads as open, unobstructed ground (the seal shuts the whole *pavement*, not
## only the body's own footprint), so a plan could aim her down a lane the day has already closed to
## her rather than crossing to the carriageway where the seal means her to go. Found timing day 11's
## mast task on seed 1234567, where it lengthens the plan by the detour onto the road, though a
## separate, narrower stall against the same `scaffolding` body's own outline on that seed and day is
## still open (`docs/TODO.md`, M181, "the late days are timed").
func _blocked_for_phase(sidewalk_only: bool, avoid: Dictionary = {},
		hazards: Dictionary = {}) -> Dictionary:
	var blocked := {}
	if sidewalk_only:
		for tile: Vector2i in _road_tiles:
			blocked[tile] = true
	for tile: Vector2i in _city.map.closed_tiles:
		blocked[tile] = true
	for tile: Vector2i in _city.map.soft_sealed_tiles:
		blocked[tile] = true
	for tile: Vector2i in _city.map.obstructed_tiles:
		blocked[tile] = true
	for tile: Vector2i in _gate_ground():
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

## How near a tile's centre may come to a solid body's own surface and still be planned through —
## her own `Tuning.PLAYER_BODY_RADIUS` (14px). A plan walks her down tile centres, so a centre
## nearer a body than her radius is a step she can only take by pressing into it: the frontage tile
## beside a kerbed `delivery_van` is 10px from the van's side, and so is the first lane of road
## beside it. Her pram (`Stroller.PRAM_BODY_RADIUS`, 8px, on her circumference ahead of her) adds
## nothing sideways, and ahead of her `_ARRIVE_RADIUS` (10px) already turns her toward the next
## waypoint before it could touch.
const _BODY_CLEARANCE := Tuning.PLAYER_BODY_RADIUS

## How far round the body that caught her a leg keeps off afterwards, measured the same way — her
## radius plus half a tile (30px). Wider than `_BODY_CLEARANCE` because a stall proves the ordinary
## clearance was not enough here, and narrow enough to leave a street's second lane open past a
## kerbed van: that lane's centre is 42px from the van's side.
const _CAUGHT_CLEARANCE := Tuning.PLAYER_BODY_RADIUS + Tuning.TILE_SIZE * 0.5

## Every tile whose centre lies within `_BODY_CLEARANCE` of a standing body's own surface — see that
## constant for why `CityMap.obstructed_tiles` alone is not enough for her.
##
## **Every body the day has, not only the ones streamed in near her.** `EventManager` builds an
## instance only once she is within `EventManager.stream_radius` of its plan and takes it away
## again once she leaves, but it records every planned body in `obstructed_tiles` at dawn, because
## "a body is a body whether or not the player has come near enough to stream it in". A plan that
## knew only the live ones kept meeting a van streaming in over a waypoint a few tiles ahead, and
## re-planned onto a street whose own van streamed in next. So each placed, unspent plan answers
## from where its instance will stand (`_planned_body_tiles()`), and a live instance from where it
## does stand, which also covers a body the director sites from her walk and has no plan position
## at dawn.
func _body_clear_tiles() -> Dictionary:
	var near := {}
	for plan: EventScheduler.Planned in _city.events.plans():
		if plan.live == null and plan.is_placed() and not plan.spent and _is_planned_body(plan.def):
			near.merge(_planned_body_tiles(plan))
	for instance: EventInstance in _city.events.instances():
		if _is_standing_body(instance):
			near.merge(_tiles_near_body(instance, _BODY_CLEARANCE))
	return near

## `_body_clear_tiles()`'s answer for one plan, worked out once a day — a planned body never moves.
## Cleared in `start_day()`.
var _planned_clear := {}

func _planned_body_tiles(plan: EventScheduler.Planned) -> Dictionary:
	if _planned_clear.has(plan):
		return _planned_clear[plan]
	var at := _planned_position(plan)
	var vertical := EventInstance._spread_is_vertical(_city.map, at)
	var centres := PackedVector2Array()
	var shapes: Array[GroundShape] = []
	for piece in plan.def.parts():
		var offset := piece.offset_for(vertical)
		centres.append(at + (Vector2(0.0, offset) if vertical else Vector2(offset, 0.0)))
		shapes.append(piece.shape)
	var axis := EventManager._body_axis(_city.map, plan.def, at, plan.facing)
	var tiles := _tiles_near_pieces(centres, shapes, axis, _BODY_CLEARANCE)
	_planned_clear[plan] = tiles
	return tiles

## Where a plan's instance will stand once it is built — `EventInstance.setup()`'s own reading: the
## first point of its path or its position, moved to the middle of the sidewalk band for a
## stationary solid row that `pavement_side` does not pin to an edge.
func _planned_position(plan: EventScheduler.Planned) -> Vector2:
	var at := plan.path[0] if plan.path.size() > 0 else plan.position
	if not plan.def.mobile and plan.def.obstructs_radius > 0.0 \
			and plan.def.pavement_side == EventDef.Pavement.ANY:
		at = EventInstance._centred_on_the_pavement_band(_city.map, at)
	return at

## The planned rows `CityMap.obstructed_tiles` records a body for
## (`EventManager.obstructed_footprint()`): solid, and neither `mobile` — somewhere else by the time
## a plan gets there, the reason `_is_stationary_hazard()` gives — nor a door body, which is a
## crossing the day keeps open: a hut or a post (`detain_seconds`) or the boom
## (`EventDef.lifts_for_traffic`), whose ground `_gate_ground()` keeps off instead.
func _is_planned_body(def: EventDef) -> bool:
	return def.shape != null and def.obstructs_radius > 0.0 and not def.mobile \
			and def.detain_seconds <= 0.0 and not def.lifts_for_traffic

## Every tile whose centre lies within a door's reach — `EventDef.detain_distance()` from a
## `checkpoint_hut` or `checkpoint_post` (the `redetains` rows, the two that inspect her), plus
## `_ARRIVE_RADIUS` for the corner she cuts at a waypoint — except the tiles on any door body's own
## crossing line, the row or column through it along its facing, which is the axis the door sets her
## down across. Every door of the day, for the streaming reason `_body_clear_tiles()` gives: a door
## is planned at dawn with the region wall it stands in.
##
## **A door takes her in whether or not she meant to cross it**, and sets her down on its far side:
## a plan down the next column of tiles past a door, crossing the street two tiles from it, was
## taken in by one hut and set down on the wrong side of the wall, crossed back through the door,
## and taken in again by the hut on the far sidewalk, until the leg gave up. **And the crossing
## line stays open** because a door is the only way through its wall: keeping out of the whole
## reach sent a plan across the city to a door it had not seen yet, where it met that door's reach
## and set off for the next one. Doors can stand close together — two meeting at a corner — so one
## body's crossing line can lie inside another body's reach: the lines are taken out of every door
## body's reach, not only out of their own body's.
##
## **Two exceptions, both about where she already stands.** A door body that has just let her out
## cannot take her again until she has walked out of its circle (`_latched_doors`), so its reach is
## hers to walk away through. And standing in the `_ARRIVE_RADIUS` margin of a door she is not
## inside — a park beside a door — keeps only the true reach off for that door, since every step
## out of the margin would otherwise read as blocked and the plan would give up the doors' reach
## altogether. `chatting_mother` detains too but walks, so she is left to the hold handling, the
## way `_is_stationary_hazard()` leaves a mobile hazard. **A street door's boom (`checkpoint_gate`)
## is not a door body here**: it inspects nobody, so it has no reach and opens no line, and the
## ground under it is never planned at all (`_gate_ground()`).
func _door_tiles() -> Dictionary:
	# A rig built without her, as a test of the planning geometry is, stands nowhere near a door.
	var here := _player.global_position if _player else Vector2.INF
	var near := {}
	var lines := {}
	for plan: EventScheduler.Planned in _city.events.plans():
		if not plan.is_placed() or plan.spent or not plan.def.redetains:
			continue
		var door := _planned_position(plan)
		var facing := plan.facing
		if plan.live != null:
			if plan.live.is_finished:
				continue
			door = plan.live.global_position
			facing = plan.live.facing_now()
		var trigger := plan.def.detain_distance()
		var distance := here.distance_to(door)
		if _latched_doors.has(plan):
			if distance <= trigger:
				continue
			_latched_doors.erase(plan)
		var reach := trigger if distance <= trigger + _ARRIVE_RADIUS else trigger + _ARRIVE_RADIUS
		_add_door_reach(door, facing, reach, near, lines)
	for tile: Vector2i in lines:
		near.erase(tile)
	return near

## The door bodies that have just let her out and cannot take her again until she walks out of
## their circle — the rig's copy of `EventManager._latch_everything_she_was_let_out_into()`, which
## latches **every** door body whose trigger holds the point she is set down at. Filled by
## `_latch_the_doors_round_her()`, keyed by plan; a body is let go by `_door_tiles()` the first time
## it finds her outside its circle, which is when the game's own latch lets go too.
var _latched_doors := {}

func _latch_the_doors_round_her() -> void:
	_latched_doors = {}
	var here := _player.global_position
	for plan: EventScheduler.Planned in _city.events.plans():
		if not plan.is_placed() or plan.spent or not plan.def.redetains:
			continue
		var door := plan.live.global_position if plan.live != null else _planned_position(plan)
		if here.distance_to(door) <= plan.def.detain_distance():
			_latched_doors[plan] = true

## Every tile under a street door's boom (`checkpoint_gate`, the plan carrying a
## `RegionPlanner.GateState`): within reach of her body touching the boom's — its own
## `solid_reach()` plus `Tuning.PLAYER_BODY_RADIUS`, plus `_ARRIVE_RADIUS` for the corner she cuts
## at a waypoint — and nearer the boom than any other door body. Always blocked, in every tier of
## every plan (`_blocked_for_phase()`), because **the rig never goes through the boom**, raised or
## lowered *(2026-09-24, the player: "The bot shouldn't route through the boom either way.")*: a
## raised boom is ground she may walk under, and the walk sets a guard on her (`EventManager.
## _watch_the_door_lines()`), so a door is crossed at a hut or an alley post. Stated over the bodies
## rather than over a trigger, since the boom inspects nobody. A hut stands on each sidewalk a lane's
## width from the road, so both of its crossing lanes are nearer the hut than the boom and stay
## open. Worked out once a day, since doors do not move.
func _gate_ground() -> Dictionary:
	if _gate_ground_ready:
		return _gate_ground_tiles
	_gate_ground_ready = true
	_gate_ground_tiles = {}
	var doors: Array[EventScheduler.Planned] = []
	# Every door body — the huts and posts by `redetains`, the boom by its `GateState` — since the
	# ground kept off is the ground nearer the boom than any of the others.
	for plan: EventScheduler.Planned in _city.events.plans():
		if plan.is_placed() and not plan.spent and (plan.def.redetains or plan.gate_state != null):
			doors.append(plan)
	for gate in doors:
		if gate.gate_state == null:
			continue
		var at := _planned_position(gate)
		var reach := gate.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS + _ARRIVE_RADIUS
		var centre_tile := _city.map.world_to_tile(at)
		var span := ceili(reach / Tuning.TILE_SIZE) + 1
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var tile := centre_tile + Vector2i(dx, dy)
				var point := _city.map.tile_to_world(tile)
				var distance := point.distance_to(at)
				if distance > reach:
					continue
				var nearest_is_gate := true
				for other in doors:
					if other != gate and point.distance_to(_planned_position(other)) < distance:
						nearest_is_gate = false
						break
				if nearest_is_gate:
					_gate_ground_tiles[tile] = true
	return _gate_ground_tiles

## `_gate_ground()`'s answer for the day, and whether it has been worked out yet — cleared in
## `start_day()`.
var _gate_ground_tiles := {}
var _gate_ground_ready := false

func _add_door_reach(door: Vector2, facing: Vector2, reach: float, near: Dictionary,
		lines: Dictionary) -> void:
	var axis := facing.normalized()
	var centre_tile := _city.map.world_to_tile(door)
	var span := ceili(reach / Tuning.TILE_SIZE) + 1
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var tile := centre_tile + Vector2i(dx, dy)
			var offset := _city.map.tile_to_world(tile) - door
			if offset.length() > reach:
				continue
			# At most half a tile, not under it: a door body stands in the middle of its two-lane
			# sidewalk or its carriageway, on the line between two lanes, so both lanes' centres
			# are exactly half a tile off it and both are the crossing.
			if axis != Vector2.ZERO and absf(offset.cross(axis)) <= Tuning.TILE_SIZE * 0.5 + 0.01:
				lines[tile] = true
			else:
				near[tile] = true

## A live instance `_body_clear_tiles()` keeps clear of — the same rows `_is_planned_body()` names,
## while the instance is solid (`EventInstance.is_solid()`: a pursuer that has stopped waiting, or
## a `solid_once_it_starts` row still in its notice, is not).
func _is_standing_body(instance: EventInstance) -> bool:
	return not instance.is_finished and instance.is_solid() and _is_planned_body(instance.def)

## The tiles whose centre lies within `margin` of `instance`'s own solid pieces — its
## `EventInstance.solid_part_centres()` and `solid_part_shapes()`, the same pieces its collision is
## built from, along `solid_axis()`.
func _tiles_near_body(instance: EventInstance, margin: float) -> Dictionary:
	return _tiles_near_pieces(instance.solid_part_centres(), instance.solid_part_shapes(),
			instance.solid_axis(), margin)

## The tiles whose centre lies within `margin` of any of a body's pieces, each measured against its
## real shape: a segment turned along `axis` the way `EventInstance._build_obstruction()` turns its
## capsule, and a rectangle left square.
func _tiles_near_pieces(centres: PackedVector2Array, shapes: Array[GroundShape], axis: Vector2,
		margin: float) -> Dictionary:
	var near := {}
	for k in centres.size():
		var shape := shapes[k]
		var angle := axis.angle() if shape.half_length > 0.0 else 0.0
		var centre_tile := _city.map.world_to_tile(centres[k])
		var span := ceili((shape.reach() + margin) / Tuning.TILE_SIZE) + 1
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var tile := centre_tile + Vector2i(dx, dy)
				var local := (_city.map.tile_to_world(tile) - centres[k]).rotated(-angle)
				if shape.distance_to_spine(local) - shape.radius < margin:
					near[tile] = true
	return near

## The tiles whose centre lies within `margin` of `point` — the ground round a spot on a wall or a
## barrier she was pressed against, which has no outline this rig can ask for.
func _tiles_near_point(point: Vector2, margin: float) -> Dictionary:
	var near := {}
	var centre_tile := _city.map.world_to_tile(point)
	var span := ceili(margin / Tuning.TILE_SIZE) + 1
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var tile := centre_tile + Vector2i(dx, dy)
			if _city.map.tile_to_world(tile).distance_to(point) < margin:
				near[tile] = true
	return near

## The shortest walk that keeps to the sidewalk where it can (see the class doc, "Hugs the kerb"),
## off every live hazard, clear of every body (`_body_clear_tiles()`), out of every door's reach
## (`_door_tiles()`, which leaves each door's own crossing line open) and off `avoid` — the ground
## round what has already caught her this leg, `_leg_avoid`, `{}` for a first plan. Each preference
## is given up, one at a time and weakest first, only where keeping it finds no way at all: `avoid`
## first, since it is a detour of choice; then the doors' reach; then the body clearance, since a
## plan through a gap her body does not fit is at least a plan the stall handling can work on; and
## only then the hazards, so a guard that has boxed in the only way through skips the target rather
## than reporting one unreachable that a wider margin merely made look that way. Smoothed by
## `_simplify()` either way. Records which it kept in `_plan_kept_clear` and `_plan_kept_doors`.
func _plan(from_tile: Vector2i, to_tile: Vector2i, avoid: Dictionary = {}) -> Array[Vector2i]:
	var clear := _body_clear_tiles()
	var doors := _door_tiles()
	var clear_and_doors := clear.duplicate()
	clear_and_doors.merge(doors)
	var everything := clear_and_doors.duplicate()
	everything.merge(avoid)
	# Each tier: what it keeps off, whether that includes the bodies' clearance, and the doors'.
	var tiers: Array = [[everything, true, true]]
	if not avoid.is_empty():
		tiers.append([clear_and_doors, true, true])
	if not doors.is_empty():
		tiers.append([clear, true, false])
	if not clear.is_empty():
		tiers.append([{}, false, false])
	for tier: Array in tiers:
		var keep_off: Dictionary = tier[0]
		var path := _shortest(from_tile, to_tile, true, keep_off)
		if path.is_empty():
			path = _shortest(from_tile, to_tile, false, keep_off)
		if not path.is_empty():
			_plan_kept_clear = tier[1] or clear.is_empty()
			_plan_kept_doors = tier[2] or doors.is_empty()
			return _simplify(path)
	_plan_kept_clear = clear.is_empty()
	_plan_kept_doors = doors.is_empty()
	return _simplify(_shortest(from_tile, to_tile, false, {}, false))

## `to_tile` is dropped from the hazard set before it blocks anything — the fairness contract that
## guards a mark (`docs/DECISIONS.md`, "The guard robber is placed inside a building": the least a
## guarded mark's own contact point is ever placed from its guard is `alley_robbery.inner_radius +
## ContactPoint.REACH`, 66px) already keeps the exact point she is walking to outside the true kill
## radius; `_HAZARD_MARGIN`'s own slack can still read the target's own tile as blocked without
## this, which would report a guarded mark unreachable rather than merely guarded. `from_tile` is
## dropped from the **whole** blocked set, hazard and obstruction and closure alike, because
## `CityMap.walk_field_from()` reads a
## blocked seed as nothing to sweep from at all, so anything that merely brushes wherever she
## already legally is (a hazard's own margin close by but outside the true kill radius, since she
## is walking and not dead; a fresh obstruction that has just closed in around her) would report
## *every* tile unreached rather than a detour away from it — the shape of bug that turned a walk
## past a stationary guard, at a safe distance a margin's own slack still read as blocked, into a
## replan every check for the rest of the run rather than a route that ever got past it. The
## ground *around* either tile keeps its ordinary rules — only the one tile she is actually
## standing on, or the one she is actually trying to reach, is ever exempted. `keep_off` (the body
## clearance and the ground round what caught her, see `_plan()`) gives `to_tile` up the way the
## hazards do: a mark beside a parked van is still a mark, and `ContactPoint.REACH` (36px) completes
## it before she is near enough to press against the van.
func _shortest(from_tile: Vector2i, to_tile: Vector2i, sidewalk_only: bool,
		keep_off: Dictionary = {}, avoid_hazards: bool = true) -> Array[Vector2i]:
	var hazards := _hazard_tiles() if avoid_hazards else {}
	hazards.merge(keep_off)
	hazards.erase(to_tile)
	var blocked := _blocked_for_phase(sidewalk_only, {}, hazards)
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

## The tile a plan starts from: the one she stands on, or — where that is not open ground at all —
## the nearest open tile to her. A door can set her down on a tile that is not ground
## (`EventManager._release_finished_door_detentions()` mirrors her through the door without
## asking what is there), and a sweep seeded on a building reaches nothing, which read as every
## target unreachable from there.
##
## **Outside a door's reach where there is such a tile near her.** The door that set her down there
## let her out beside its own body, and the nearest open tile can lie back inside its trigger: a
## plan starting there walked her straight back in, and the door took her across again.
func _standing_tile() -> Vector2i:
	var here := _player.global_position
	var tile := _city.map.world_to_tile(here)
	if _city.map.is_open(tile):
		return tile
	var doors := _door_tiles()
	var best := tile
	var best_distance := INF
	for keep_off: Dictionary in [doors, {}]:
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var near := tile + Vector2i(dx, dy)
				var distance := _city.map.tile_to_world(near).distance_to(here)
				if _city.map.is_open(near) and not keep_off.has(near) and distance < best_distance:
					best = near
					best_distance = distance
		if best_distance < INF:
			return best
	return best

func _to_world(path: Array[Vector2i]) -> Array[Vector2]:
	var world: Array[Vector2] = []
	for tile in path:
		world.append(_city.map.tile_to_world(tile))
	return world

func _begin_leg(target_world: Vector2) -> void:
	_leg_avoid = {}
	_door_holds = {}
	_caught_away = Vector2.ZERO
	_leg_step = null
	if (_current_word == "mark" or _current_word == "task") and _resistance:
		_leg_step = _resistance.current_step()
	var here_tile := _standing_tile()
	var target_tile := _city.map.world_to_tile(target_world)
	var path := _plan(here_tile, target_tile)
	if path.is_empty():
		Telemetry.note("route", "day %d: no path to '%s', skipping" % [_day_number, _current_word])
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
	if _waypoints.is_empty() or _step_completed():
		_arrive()
		return
	if _held_at_a_door():
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

## Whether a door is holding her (`Stroller.is_detained()` — a `checkpoint_hut` or `checkpoint_post`
## she walked into, which talks to her for `Tuning.CHECKPOINT_DETAIN_SECONDS` and then sets her down
## on its far side), and the re-plan from wherever it set her down once it lets go. **A hold is not
## a stall**: she stands still because the door is doing what a door does, so the stall ladder is
## held at its first rung for as long as it lasts rather than spending the leg's episodes on it.
## **And the plan made before the door is stale once she is through it** — its next waypoints are
## still on the side she came from, and walking back to them took her into the same door from the
## far side, which set her down where she started, over and over. The hold ends a frame before
## `EventManager` sets her down (`Stroller.teleport_to()`), so the re-plan that counts is the one
## made once `_teleported` sees her land. Each re-plan first notes which door bodies are latched round where
## she stands (`_latch_the_doors_round_her()`), so the plan walks her away through their reach
## rather than giving up every door's reach because every step out of this one read as blocked.
func _held_at_a_door() -> bool:
	if _player.is_detained():
		if not _held and _count_the_door():
			return true
		_held = true
		_release()
		_stuck_reference = Vector2.INF
		_stuck_streak = 0
		_replan_elapsed = 0.0
		return true
	if _held or _teleported:
		# Consumed here: `_follow()` calls itself once per waypoint it pops, and a flag left up
		# would re-plan on every one of those calls within the same frame.
		_held = false
		_teleported = false
		_latch_the_doors_round_her()
		_replan()
		return _waypoints.is_empty() or _resolving
	return false

## How many times one door may hold her in a leg before the leg is given up on. Twice is an
## ordinary crossing and a crossing back — a plan that has to come back through the door it just
## used — while a third is a loop: the plan through one door leading round to another whose far
## side leads back to the first, which no count of stalls ever ended, because a hold is not a
## stall.
const _DOOR_HOLDS_PER_LEG := 2

## Counts a new hold against the door holding her — the nearest live door body that inspects her,
## a hut or a post (`detain_seconds`) — and gives the leg up once one door has held her more than `_DOOR_HOLDS_PER_LEG` times.
## Answers whether it gave up.
func _count_the_door() -> bool:
	var here := _player.global_position
	var door := Vector2i(-1, -1)
	var nearest := INF
	for instance: EventInstance in _city.events.instances():
		if instance.is_finished or instance.def.detain_seconds <= 0.0:
			continue
		var distance := here.distance_to(instance.global_position)
		if distance < nearest:
			nearest = distance
			door = _city.map.world_to_tile(instance.global_position)
	var holds: int = _door_holds.get(door, 0) + 1
	_door_holds[door] = holds
	if holds <= _DOOR_HOLDS_PER_LEG:
		return false
	_held = false
	_caught_tile = _city.map.world_to_tile(here)
	_caught_by = "the door at %s, holding her %d times" % [TelemetryLog.tile(door), holds]
	_give_up_stuck()
	return true

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
		# Every stall first notes what caught her, so whichever answer follows — the re-plan, the
		# re-plan after waiting, the maneuver — goes round that body and backs away from it.
		_note_what_caught_her()
		if _stuck_streak == 1:
			_replan()
		elif _stuck_streak == 2:
			if _leg_stall_episodes >= _LEG_MAX_STALL_EPISODES:
				_give_up_stuck()
			else:
				_leg_stall_episodes += 1
				_begin_wait()
		else:
			_begin_unstick()
		return
	_stuck_streak = 0
	if _retarget_if_moved():
		return
	# Only while the live plan kept clear: a plan that had to give the clearance up to find a way at
	# all would be re-planned onto the same ground every check.
	var clear := _body_clear_tiles() if _plan_kept_clear else {}
	if _plan_kept_doors:
		clear.merge(_door_tiles())
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
		# two she has not reached yet. A body's clearance is exempted for the same two ends.
		if i > 0 and i < _waypoints.size() - 1 and (clear.has(tile) or _is_hazardous(point)):
			_replan()
			return

## Whether this `mark` or `task` leg's own step has been recorded completed — the director's own
## answer to whether she reached it (`ContactPoint.REACH`, 36px, or an any-instance task's wider
## reach), which is what the leg is timing.
func _step_completed() -> bool:
	return _leg_step != null and GameState.completed_resistance_steps.has(_leg_step.index)

## A `mark` or `task` target further than this from where the leg is aimed has moved: a tile, so a
## pacing any-instance task drifting inside its own tile does not re-plan every check.
const _RETARGET_DISTANCE := Tuning.TILE_SIZE * 1.0

## Re-reads `mark` and `task` and re-plans to where they are now once they have moved — see the
## class doc, "Follows a target that moves". Answers whether it re-planned.
func _retarget_if_moved() -> bool:
	if _current_word != "mark" and _current_word != "task":
		return false
	var now := _resolve_target(_current_word)
	if now == Vector2.INF or now.distance_to(_current_target_world) <= _RETARGET_DISTANCE:
		return false
	_current_target_world = now
	_current_target_tile = _city.map.world_to_tile(now)
	Telemetry.note("route", "day %d: '%s' moved to %s, re-planning"
			% [_day_number, _current_word, TelemetryLog.tile(_current_target_tile)])
	_replan()
	return true

## Reads what she is pressed against from her own slide collisions, at the moment a stall is
## found — see `_leg_avoid`, `_caught_away` and `_caught_by`. A solid event's whole outline is kept
## off (`_tiles_near_body()`, `_CAUGHT_CLEARANCE`); anything else she touched — a building, a
## closure's barrier, the map's edge — has no outline to ask for, so the ground round the point
## she touched it at is kept off instead. Nothing solid touching her is the crowd she is pressing
## into, or a hold (`Stroller.is_detained()`), neither of which a detour or a direction answers.
func _note_what_caught_her() -> void:
	_caught_tile = _city.map.world_to_tile(_player.global_position)
	_caught_by = ""
	var away := Vector2.ZERO
	for i in _player.get_slide_collision_count():
		var hit := _player.get_slide_collision(i)
		away += hit.get_normal()
		var body := _event_owning(hit.get_collider())
		if body:
			_leg_avoid.merge(_tiles_near_body(body, _CAUGHT_CLEARANCE))
			_caught_by = body.def.id
		else:
			_leg_avoid.merge(_tiles_near_point(hit.get_position(), _CAUGHT_CLEARANCE))
			if _caught_by == "":
				# A pixel inside whatever she touched, since the contact point is on its surface.
				var inside := _city.map.world_to_tile(hit.get_position() - hit.get_normal())
				_caught_by = "a closure" if _city.map.is_closed(inside) \
						else TelemetryLog.tile_type(_city.map.tile_at(inside))
	_caught_away = away.normalized()
	if _caught_by == "":
		_caught_by = "a hold" if _player.is_detained() else "nothing solid (the crowd)"

## The `EventInstance` whose solid body `collider` is, or `null` — `EventInstance._build_obstruction()`
## adds its `StaticBody2D` as a direct child.
func _event_owning(collider: Object) -> EventInstance:
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent is EventInstance:
			return parent as EventInstance
	return null

## A leg given up on after too many stalls, logged with where she was and what held her there.
func _give_up_stuck() -> void:
	Telemetry.note("route", "day %d: '%s' stuck fast at %s against %s, skipping"
			% [_day_number, _current_word, TelemetryLog.tile(_caught_tile), _caught_by])
	_release()
	_advance_target()

## The plan from wherever she actually is, keeping off `_leg_avoid` — the ground round every body
## that has caught her this leg — as every plan in a leg does. Called on a first stall, once
## `_end_wait()` has let a crowd flow past, and once `_unstick()` has worked her clear: see those
## functions' own docs for why a plan alone cannot answer either of the last two.
func _replan() -> void:
	var here_tile := _standing_tile()
	var path := _plan(here_tile, _current_target_tile, _leg_avoid)
	if path.is_empty():
		Telemetry.note("route", "day %d: '%s' no longer reachable from %s, skipping"
				% [_day_number, _current_word, TelemetryLog.tile(here_tile)])
		_release()
		_advance_target()
		return
	_waypoints = _to_world(path)
	_waypoints[_waypoints.size() - 1] = _current_target_world
	Telemetry.note("route", "day %d: re-planned to '%s' (%.1fs, %d waypoints)"
			% [_day_number, _current_word, _elapsed(), _waypoints.size()])

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

## The eight compass points — an escape direction is found by trying one, not by reasoning about
## the obstruction's own shape, which this class has no way to ask about; `_begin_unstick()` only
## decides which is tried first, from which way her slide collisions said was away from it.
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
## waiting alone or has to go on to `_begin_unstick()` too. `_end_unstick(true)` clears *this*
## wedge and re-plans round the body that caused it (`_leg_avoid`), but a chokepoint with no way
## round at all — every other way through closed or held too — still sends her back at it, and
## three separate encounters is the whole leg giving up on a spot that keeps re-catching her rather
## than retrying it forever.
const _LEG_MAX_STALL_EPISODES := 3

var _unsticking := false
## `_UNSTICK_DIRECTIONS` in the order this maneuver tries them — see `_begin_unstick()`.
var _unstick_order: Array[Vector2] = []
var _unstick_index := 0
var _unstick_elapsed := 0.0
var _unstick_anchor := Vector2.INF
var _unstick_cycles := 0
## Reset in `_begin_leg()`; counts every stuck-encounter this leg has needed a `_begin_wait()` for,
## settled by waiting alone or not — see `_LEG_MAX_STALL_EPISODES`.
var _leg_stall_episodes := 0

## The eight compass points, sorted so the one pointing most directly away from what caught her
## (`_caught_away`) is tried first, or in `_UNSTICK_DIRECTIONS`' own order when nothing solid was
## touching her. Pressing into the body first spends a whole `_UNSTICK_TRY_SECONDS` on the one
## direction that cannot work.
func _begin_unstick() -> void:
	_unsticking = true
	_unstick_order = _UNSTICK_DIRECTIONS.duplicate()
	if _caught_away != Vector2.ZERO:
		var away := _caught_away
		_unstick_order.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return a.dot(away) > b.dot(away))
	_unstick_index = 0
	_unstick_elapsed = 0.0
	_unstick_anchor = _player.global_position

## Holds each of `_UNSTICK_DIRECTIONS` in turn until she has actually moved `_UNSTICK_CLEAR_DISTANCE`
## from where the maneuver began, or every direction has had its turn without one working.
func _unstick(delta: float) -> void:
	var direction := _unstick_order[_unstick_index]
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
	if _unstick_index >= _unstick_order.size():
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
		_give_up_stuck()
		return
	_unstick_cycles = 0
	_replan()

func _arrive() -> void:
	_release()
	var distance := _leg_start_position.distance_to(_player.global_position)
	Telemetry.note("route", "day %d: reached '%s' at %.1fs (day time), %.0fpx walked"
			% [_day_number, _current_word, _elapsed(), distance])
	if _current_word.begins_with("calm"):
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
				% [_day_number, _elapsed()])
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
	Telemetry.note("route", "day %d: route done, %.1fs (day time)" % [_day_number, _elapsed()])
	get_tree().quit()

## The day's own length gone by on this rig's clock under `--invincible`, which stands the day's
## clock still (see `_elapsed()`), so nothing else ever ends a route that does not fit its day: a
## leg still walking, re-planning or waiting at that point would walk on for as long as the process
## was allowed to run, and the timing probe could only kill it and report nothing. Past the day's
## length the answer to "does this route fit the clock" is already no, so the run ends there and
## says which target it was still walking to.
func _out_of_day() -> void:
	_done = true
	_release()
	Telemetry.note("route", "day %d: the day's %.0fs ran out before reaching '%s', %.1fs (day time)"
			% [_day_number, _day.time_total, _current_word, _elapsed()])
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
				% [_day_number, _elapsed(), _current_word])
	else:
		Telemetry.note("route", "day %d: day ended (%s) before reaching '%s', %.1fs (day time)"
				% [_day_number, GameEnums.DayResult.keys()[result], _current_word, _elapsed()])
	get_tree().quit()

func _release() -> void:
	TouchControls._set_axis(&"move_left", &"move_right", 0.0)
	TouchControls._set_axis(&"move_up", &"move_down", 0.0)
