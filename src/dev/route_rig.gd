class_name RouteRig
extends Node
## `--route <target>[,<target>...]` walks her to each named target in turn, along a real path's
## edges, with no scripted inputs — see docs/TODO.md, M184, "A rig walks the route". Where
## `--walk`'s own script (`AutoScreenshot`) holds a fixed direction or replays a fixed timing, this
## re-aims at the next step of a live path every physics frame, through the exact same
## `TouchControls.set_axis()` press every other dev-rig direction already goes through — so the
## meter, the events, the crowd, the closures, the doors and the clock all run exactly as they do
## for a player, at `Tuning.WALK_SPEED`. Only the source of the heading is a plan instead of a
## finger.
##
## **Never a player control.** See docs/DECISIONS.md, M88, "the player chooses the controls" —
## *"a tap that pathfinds hands the route decision to the game and the route decision is the
## design"* — for why a pathfinding walk answers only to a dev flag, behind the same debug-build
## gate `--walk` and `--flee` answer to; nothing outside a dev flag ever reaches it.
##
## **Targets**, `--route`'s comma-separated words, handed to `setup()` in order:
## - `mark` — today's chalk mark, while it is still the step on offer (`ResistanceDirector`'s own
##   pickup). Unavailable once it has been touched, or on a day with no mark at all.
## - `task` — the red arrow's own point for a one-place task, or the nearest **live** instance of
##   an any-instance task (the one who won't stop shouting, a roadblock's band). Unavailable until
##   the mark that unlocks it has actually been reached.
## - `calm` — the nearest calm area she can settle the baby in, by walking distance rather than a
##   straight line. She stops and presses nothing once she is there, and stays until the baby is
##   asleep, however long that takes — the day's own clock is what answers whether that fits.
## - `home` — the doorstep's own block, the centre of `CityMap.home_rect`.
## - `tunnel` and `bridge` — the escape city's two ways out (`DaySpec.exits`, the last walkable tile
##   of the spine at each end), where reaching one wins the section. Unavailable on a day.
## - `spawn:<name>` — whatever `DevRig.for_spawn_target()` already knows how to find.
##
## **The escape's city is walked the same way** (`--start-escape city --route tunnel`): `main` builds
## the rig when the city section starts, with no `ResistanceDirector` (the escape has no subquest, so
## `mark` and `task` are unavailable there), and the rig presses the section brief's continue itself
## (`press_the_brief()`), as a key would. A building won by other means builds the city and its brief
## is answered the same way; the rig is not built before the city, and the building is walked before it
## by `BuildingWalker` (`src/dev/building_walker.gd`).
##
## An unresolved target (nothing to walk to yet, or nothing found within `_RESOLVE_TIMEOUT`) and an
## unreachable one (no path exists) are both logged and skipped rather than hung on forever — see
## `_try_resolve()` and `_begin_leg()`. **Day 14's `mark` and `task` are unavailable on a bare
## `--day 14` run with nothing else played first** — the last night has no mark of its own
## (`ResistanceSteps._finale()`) and is only offered once `RunState.sabotage_available()` holds
## (`Tuning.RESISTANCE_GOAL`, 5 earlier tasks done), which an isolated day never carries. That is a
## measurement fact about the calendar, not a bug in this rig: `calm` and `home` still resolve and
## time normally, and the finale's own leg needs the goal met to be timed at all.
##
## **Where each target is and the walk there are the planner's** (`RouteRigPlanner`,
## `src/dev/route_rig_planner.gd`), which this rig builds in `setup()` and asks at every leg,
## re-plan and stall: a target word's point now (`RouteRigPlanner.resolve()`), the cheapest walk
## that hugs the kerb and keeps a body's width off every solid body and out of every door's reach
## (`plan()`), and the ground a stall says to go round. What stays here is the walking: pressing
## toward the next waypoint, noticing when the way ahead has changed or she has stopped covering
## ground, waiting out a door, and settling the baby.
##
## **Re-plans when the way ahead closes, or turns dangerous — and the re-plan actually routes
## around what it found**, rather than recomputing the same path onto the same ground.
## `_maybe_replan()` checks the remaining waypoints against `CityMap.is_open()`,
## `CityMap.is_obstructed()` and the planner's `is_hazardous()` every `_REPLAN_INTERVAL` seconds —
## closures are
## fixed for the day (see the city skill), but an obstruction (a fire's own spread, a parked van, a
## roadblock's own band) moves while the day is live and a hazard's own guard can start a pursuit
## mid-leg, and this is what catches either landing on a step already planned. Every plan folds
## `CityMap.obstructed_tiles` in for exactly this reason (`RouteRigPlanner`'s class doc). And it
## re-plans when she has simply stopped covering ground even though the tiles read fine — a body
## she has fetched up against, or standing *inside* an obstruction's own collision — which a second
## stall in a row escalates first to `_begin_wait()`, standing her still long enough for a crowd's
## own flow to open a gap the way a person eases up rather than shoves, and only once that alone has
## not moved her to `_begin_unstick()`, a short maneuver through the eight compass points that works
## her physically clear of a body waiting cannot do anything about.
##
## **Routes around the body that caught her, and backs away from it.** A stall reads her own slide
## collisions (`_note_what_caught_her()`): the ground round whatever she is pressed against — a
## body's whole outline, or the spot on a wall she touched — is kept off for the rest of the leg
## (`_leg_avoid`, the planner's `ground_round_body()` and `ground_round_point()`), so a re-plan goes
## round it rather than straight back to the same pinch, and `_begin_unstick()` tries the compass
## points in the order that points away from it (`RouteRigPlanner.unstick_order()`).
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

## World-space half-length of `_pace()`'s own back-and-forth walk while settling at `calm` —
## comfortably inside half `Tuning.TILE_SIZE` (16px) even measured from the tile's own centre, so a
## lap can never carry her onto a neighbouring tile's own `sleepiness_multiplier()` or off calm
## ground entirely. See `_pace()`'s own doc for why she paces instead of standing.
const _SETTLE_PACE_HALF := 10.0

## How close counts as "reached this end of the pace" — well under `_SETTLE_PACE_HALF` so the walk
## actually covers most of it before turning, unlike `RouteRigPlanner.ARRIVE_RADIUS`, which is sized against
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
## exact calm point the planner resolved (`_current_target_world`), not wherever
## `RouteRigPlanner.ARRIVE_RADIUS` let her stop short of it, so the pace never carries the slop of one radius into
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
## The run whose completed steps say a `mark` or `task` leg has been reached — see
## `_step_completed()`. Handed in by `setup()`.
var _run: RunState
## Whether a door was holding her at the last walking frame — see `_held_at_a_door()`.
var _held := false
## Where she stood at the last physics frame, and whether she has moved further than
## `_TELEPORT_DISTANCE` since — which walking never does, and a door setting her down on its far
## side always does. `Vector2.INF` before the day's first frame.
var _last_position := Vector2.INF
var _teleported := false
## The day this rig's queue was started for, read once in `start_day()` off the spec it is handed
## (`DaySpec.number`: 1 to 14, or the escape's city, 16). The run's `header.day` has already moved to the
## next day by the time `DayController.day_finished` reports a win, so a line written from
## `_on_day_finished()` would otherwise name the wrong day.
var _day_number := 0

## Where each target is and the walk there (`RouteRigPlanner`), built in `setup()` over the city
## and her.
var _planner: RouteRigPlanner
## Where its `route` lines go: the boot's run trace, which `main` hands it before `setup()`; one
## nobody handed writes nowhere.
var trace := RunTrace.new()

var _done := false

func setup(city: City, player: Stroller, baby: Baby, resistance: ResistanceDirector,
		day: DayController, targets: Array[String], run: RunState) -> void:
	_run = run
	_city = city
	_player = player
	_baby = baby
	_resistance = resistance
	_day = day
	_targets = targets
	_planner = RouteRigPlanner.new(city, player, resistance, day, run)
	_day.day_finished.connect(_on_day_finished)

## The day `spec` has been planned (`RunFlow.day_planned`, which `main` connects) — resets the
## queue for the day just built, so a run that plays more than one day under this flag (a nerve, or
## a probe that simply keeps going) starts the new day's targets fresh rather than chasing
## yesterday's mark.
func start_day(spec: DaySpec) -> void:
	_day_number = spec.number
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
	_planner.start_day()
	_held = false
	_last_position = Vector2.INF
	_teleported = false
	_release()
	_done = _targets.is_empty()
	if not _done:
		_begin_resolving(_targets[0])

## Answers the escape's briefs (`press_the_brief()`): what a continue on a screen does is handed by
## `main` (`use_continue()`).
var _brief := BriefPresser.new([DaySpec.Section.BUILDING, DaySpec.Section.CITY])

func use_continue(continue_from: Callable) -> void:
	_brief.use_continue(continue_from)

## The run flow has raised a brief (`RunFlow.brief_opened`): the first brief of an escape section is
## pressed (`BriefPresser`); a day's brief and a section's retry brief are left alone.
func press_the_brief(spec: DaySpec) -> void:
	await _brief.press(get_tree(), spec)

func _begin_resolving(word: String) -> void:
	_current_word = word
	_resolving = true
	_resolve_elapsed = 0.0
	_release()

func _physics_process(delta: float) -> void:
	if _done or not _day or not _day.is_running():
		return
	_elapsed_seconds += delta
	if _day.invincible and _elapsed_seconds > _day.time_total:
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
	# A door that takes her while she waits or works herself free is a crossing like any other: the
	# hold is counted and the far side planned from (`_held_at_a_door()`), rather than the maneuver
	# reading the jump as having come free and planning on as if nothing had happened.
	if (_waiting or _unsticking) and _player.is_detained():
		_waiting = false
		_unsticking = false
		_unstick_cycles = 0
	if _waiting:
		_wait(delta)
		return
	if _unsticking:
		_unstick(delta)
		return
	_follow(delta)

# --------------------------------------------------------------- resolving ---

func _try_resolve(delta: float) -> void:
	var target := _planner.resolve(_current_word)
	if target != Vector2.INF:
		_resolving = false
		_begin_leg(target)
		return
	_resolve_elapsed += delta
	if _resolve_elapsed >= _RESOLVE_TIMEOUT:
		trace.note("route", "day %d: '%s' unavailable, skipping" % [_day_number, _current_word])
		_advance_target()

func _begin_leg(target_world: Vector2) -> void:
	_leg_avoid = {}
	_door_holds = {}
	_caught_away = Vector2.ZERO
	_leg_step = null
	if (_current_word == "mark" or _current_word == "task") and _resistance:
		_leg_step = _resistance.current_step()
	var here_tile := _planner.standing_tile()
	var target_tile := _city.map.world_to_tile(target_world)
	var path := _planner.plan(here_tile, target_tile)
	if path.is_empty():
		trace.note("route", "day %d: no path to '%s', skipping" % [_day_number, _current_word])
		_advance_target()
		return
	_current_target_tile = target_tile
	_current_target_world = target_world
	_waypoints = _planner.to_world(path)
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
## `--invincible`, which `DayController.tick()` (`src/day/day_controller.gd`) stands still on
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
	# A check that has just started a wait or the maneuver presses nothing more this frame: a press
	# made here would be held through the whole wait, walking her on into the crowd the wait is
	# meant to let pass.
	if _waypoints.is_empty() or _resolving or _waiting or _unsticking:
		return
	var target := _waypoints[0]
	var offset := target - _player.global_position
	if offset.length() <= RouteRigPlanner.ARRIVE_RADIUS:
		_waypoints.remove_at(0)
		_follow(delta)
		return
	var direction := offset.normalized()
	TouchControls.set_axis(&"move_left", &"move_right", direction.x)
	TouchControls.set_axis(&"move_up", &"move_down", direction.y)

## Whether a door is holding her (`Stroller.is_detained()` — a `checkpoint_hut` or `checkpoint_post`
## she walked into, which talks to her for `EventCatalogue.CHECKPOINT_DETAIN_SECONDS` and then sets her down
## on its far side), and the re-plan from wherever it set her down once it lets go. **A hold is not
## a stall**: she stands still because the door is doing what a door does, so the stall ladder is
## held at its first rung for as long as it lasts rather than spending the leg's episodes on it.
## **And the plan made before the door is stale once she is through it** — its next waypoints are
## still on the side she came from, and walking back to them took her into the same door from the
## far side, which set her down where she started, over and over. The hold ends a frame before
## `EventManager` sets her down (`Stroller.teleport_to()`), so the re-plan that counts is the one
## made once `_teleported` sees her land. Each re-plan first notes which door bodies are latched round where
## she stands (`RouteRigPlanner.latch_the_doors_round_her()`), so the plan walks her away through their reach
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
		_planner.latch_the_doors_round_her()
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
	_caught_by = "the door at %s, holding her %d times" % [RunTrace.tile(door), holds]
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
	# Not over the ground the live plan chose to cross: it would be re-planned onto the same ground
	# every check.
	var clear := _planner.body_clear_tiles()
	clear.merge(_planner.door_tiles())
	for tile: Vector2i in _planner.crossed():
		clear.erase(tile)
	for i in _waypoints.size():
		var point: Vector2 = _waypoints[i]
		var tile := _city.map.world_to_tile(point)
		if not _city.map.is_open(tile) or _city.map.is_obstructed(tile):
			_replan()
			return
		# The first remaining waypoint is wherever she already legally is (about to be popped this
		# same `_follow()` call), and the last is the exact target — every plan exempts both of
		# those tiles from hazard blocking, for the reason its own doc gives (a guard's margin can
		# brush a spot she is already standing on safely, or the exact contact point a mark's own
		# fairness contract keeps just inside the margin). Checking either against the raw,
		# unexempted `is_hazardous()` here would replan forever over ground already accepted as
		# safe enough to stand on, rather than catching a hazard newly astride ground *between* the
		# two she has not reached yet. A body's clearance is exempted for the same two ends.
		if i > 0 and i < _waypoints.size() - 1 and (clear.has(tile) or _planner.is_hazardous(point)):
			_replan()
			return

## Whether this `mark` or `task` leg's own step has been recorded completed — the director's own
## answer to whether she reached it (`ContactPoint.REACH`, 36px, or an any-instance task's wider
## reach), which is what the leg is timing.
func _step_completed() -> bool:
	return _leg_step != null and _run.resistance.completed_steps.has(_leg_step.index)

## A `mark` or `task` target further than this from where the leg is aimed has moved: a tile, so a
## pacing any-instance task drifting inside its own tile does not re-plan every check.
const _RETARGET_DISTANCE := Tuning.TILE_SIZE * 1.0

## Re-reads `mark` and `task` and re-plans to where they are now once they have moved — see the
## class doc, "Follows a target that moves". Answers whether it re-planned.
func _retarget_if_moved() -> bool:
	if _current_word != "mark" and _current_word != "task":
		return false
	var now := _planner.resolve(_current_word)
	if now == Vector2.INF or now.distance_to(_current_target_world) <= _RETARGET_DISTANCE:
		return false
	_current_target_world = now
	_current_target_tile = _city.map.world_to_tile(now)
	trace.note("route", "day %d: '%s' moved to %s, re-planning"
			% [_day_number, _current_word, RunTrace.tile(_current_target_tile)])
	_replan()
	return true

## Reads what she is pressed against from her own slide collisions, at the moment a stall is
## found — see `_leg_avoid`, `_caught_away` and `_caught_by`. A solid event's whole outline is kept
## off (`RouteRigPlanner.ground_round_body()`); anything else she touched — a building, a
## closure's barrier, the map's edge — has no outline to ask for, so the ground round the point
## she touched it at is kept off instead (`ground_round_point()`). Nothing solid touching her is the crowd she is pressing
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
			_leg_avoid.merge(_planner.ground_round_body(body))
			_caught_by = body.def.id
		else:
			_leg_avoid.merge(_planner.ground_round_point(hit.get_position()))
			if _caught_by == "":
				# A pixel inside whatever she touched, since the contact point is on its surface.
				var inside := _city.map.world_to_tile(hit.get_position() - hit.get_normal())
				_caught_by = "a closure" if _city.map.is_closed(inside) \
						else RunTrace.tile_type(_city.map.tile_at(inside))
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
	trace.note("route", "day %d: '%s' stuck fast at %s against %s, skipping"
			% [_day_number, _current_word, RunTrace.tile(_caught_tile), _caught_by])
	_release()
	_advance_target()

## The plan from wherever she actually is, keeping off `_leg_avoid` — the ground round every body
## that has caught her this leg — as every plan in a leg does. Called on a first stall, once
## `_end_wait()` has let a crowd flow past, and once `_unstick()` has worked her clear: see those
## functions' own docs for why a plan alone cannot answer either of the last two.
func _replan() -> void:
	var here_tile := _planner.standing_tile()
	var path := _planner.plan(here_tile, _current_target_tile, _leg_avoid)
	if path.is_empty():
		trace.note("route", "day %d: '%s' no longer reachable from %s, skipping"
				% [_day_number, _current_word, RunTrace.tile(here_tile)])
		_release()
		_advance_target()
		return
	_waypoints = _planner.to_world(path)
	_waypoints[_waypoints.size() - 1] = _current_target_world
	trace.note("route", "day %d: re-planned to '%s' (%.1fs, %d waypoints)"
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
## crowd is not a tile-level change a plan would otherwise have any reason to notice. **Sets
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
## The eight compass points in the order this maneuver tries them — see `_begin_unstick()`.
var _unstick_order: Array[Vector2] = []
var _unstick_index := 0
var _unstick_elapsed := 0.0
var _unstick_anchor := Vector2.INF
var _unstick_cycles := 0
## Reset in `_begin_leg()`; counts every stuck-encounter this leg has needed a `_begin_wait()` for,
## settled by waiting alone or not — see `_LEG_MAX_STALL_EPISODES`.
var _leg_stall_episodes := 0

## Starts working her physically clear, trying the eight compass points in the planner's order
## (`RouteRigPlanner.unstick_order()`): away from what caught her (`_caught_away`) first, and any
## direction that would carry her `_UNSTICK_CLEAR_DISTANCE` into a door's circle last.
func _begin_unstick() -> void:
	_unsticking = true
	_unstick_order = _planner.unstick_order(_caught_away, _UNSTICK_CLEAR_DISTANCE)
	_unstick_index = 0
	_unstick_elapsed = 0.0
	_unstick_anchor = _player.global_position

## Holds each of `_unstick_order` in turn until she has actually moved `_UNSTICK_CLEAR_DISTANCE`
## from where the maneuver began, or every direction has had its turn without one working.
func _unstick(delta: float) -> void:
	var direction := _unstick_order[_unstick_index]
	TouchControls.set_axis(&"move_left", &"move_right", direction.x)
	TouchControls.set_axis(&"move_up", &"move_down", direction.y)
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
	trace.note("route", "day %d: reached '%s' at %.1fs (day time), %.0fpx walked"
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
## instead, at `Baby.SLEEPINESS_DRAIN_IDLE` (1.0/s) — faster than walking on calm ground fills it
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
		trace.note("route", "day %d: baby settled at 'calm', %.1fs (day time)"
				% [_day_number, _elapsed()])
		_advance_target()
		return
	if not Tile.is_calm(_city.map.tile_type_at_world(_settle_anchor)):
		# The ground she is pacing on has gone — see `RouteRigPlanner.resolve()`'s `calm`, which offers only ground still calm — so she looks again.
		_settling = false
		_settle_anchor = Vector2.INF
		trace.note("route", "day %d: the calm ground at %s is gone, looking again, %.1fs"
				% [_day_number, RunTrace.tile(_current_target_tile), _elapsed()]
				+ " (day time)")
		_begin_resolving(_current_word)
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
	TouchControls.set_axis(&"move_left", &"move_right", direction.x)
	TouchControls.set_axis(&"move_up", &"move_down", direction.y)

func _advance_target() -> void:
	_target_index += 1
	if _target_index >= _targets.size():
		_finish()
		return
	_begin_resolving(_targets[_target_index])

## Ends the process. A test substitutes a rig that does not, because the runner lets frames pass
## after a suite and a pending quit would end the whole run there (`tests/route_rig_no_quit.gd`).
func _quit() -> void:
	get_tree().quit()

func _finish() -> void:
	_done = true
	_release()
	trace.note("route", "day %d: route done, %.1fs (day time)" % [_day_number, _elapsed()])
	_quit()

## The day's own length gone by on this rig's clock under `--invincible`, which stands the day's
## clock still (see `_elapsed()`), so nothing else ever ends a route that does not fit its day: a
## leg still walking, re-planning or waiting at that point would walk on for as long as the process
## was allowed to run, and the timing probe could only kill it and report nothing. Past the day's
## length the answer to "does this route fit the clock" is already no, so the run ends there and
## says which target it was still walking to.
func _out_of_day() -> void:
	_done = true
	_release()
	trace.note("route", "day %d: the day's %.0fs ran out before reaching '%s', %.1fs (day time)"
			% [_day_number, _day.time_total, _current_word, _elapsed()])
	_quit()

## Any day ending — a loss, or a win — is logged and quit rather than left to sit at a day summary
## nobody headless is going to dismiss.
##
## **`WON` is not a no-op here, and finding out why it has to be one is worth keeping.** A won day
## can only follow *this* node walking her onto a `HOME` tile while `DayController.phase` is
## `RETURNING`, which reads as `_arrive()`'s own `home` case — so the first build of this class
## left `WON` unhandled, on the reasoning that `_arrive()` already reports and quits before this
## signal could add anything to it. That reasoning assumes the two checks agree on the instant
## "home" happens, and they do not: `DayController`'s own `WON` fires the moment she is anywhere
## on the `HOME` tile, while `_arrive()`'s own arrival is `RouteRigPlanner.ARRIVE_RADIUS` (10px) of
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
		trace.note("route", "day %d: day won at %.1fs (day time), still walking to '%s'"
				% [_day_number, _elapsed(), _current_word])
	else:
		trace.note("route", "day %d: day ended (%s) before reaching '%s', %.1fs (day time)"
				% [_day_number, GameEnums.DayResult.keys()[result], _current_word, _elapsed()])
	_quit()

func _release() -> void:
	TouchControls.set_axis(&"move_left", &"move_right", 0.0)
	TouchControls.set_axis(&"move_up", &"move_down", 0.0)
