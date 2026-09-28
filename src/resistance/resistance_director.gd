class_name ResistanceDirector
extends Node
## Places the day's resistance contact, and enforces the two things that make the subquest
## cost something: every contact is paid for in danger — a mark is guarded, and the man shouting's
## note or the van's package sets someone on her the moment it is handed over — and a timed step
## expires.
##
## Deterministic from the run seed and the day, like everything else, so an alley that was
## safe on day 9 of this run is safe on day 9 of this run every time you replay it. The
## pattern is learnable; that is the difference between risk and a coin flip.
##
## **A task is one day.** `start_day()` only ever offers a chalk mark (or the finale) —
## `ResistanceSteps.for_day()` never hands back a perform step — and the perform half is
## activated the instant the mark is touched, by `_begin_step()` again, from
## `_on_contact_completed()`. So a mark placed at dawn and the task it unlocks a few seconds
## later share one `start_day()`'s worth of RNG and guard bookkeeping; nothing here waits for
## tomorrow.
##
## **The mark itself needs no physics-interpolation opt-out.** `ContactPoint` follows a rider on
## the physics tick (correctly interpolated, like the player), and this director's own `_process`
## only ever relocates an unseen mark (`_move_the_mark()`) while it is beyond `NOTICE_RADIUS` —
## which exceeds the screen's own half-diagonal, so the jump is never on screen to be drawn
## sliding in the first place.

## The day the first chalk mark can appear, and so the first day anything is guarded or any
## robber is set on her — nothing is offered before it.
const TRAP_FIRST_DAY := 6

## A mark is "seen" once she has actually noticed it — see `SEEN_DISTANCE` and
## `SEEN_DWELL_SECONDS` for what that takes — and only then does it stop following the player.
## Below that, moving it only when she is this far from it is what turns *"placed but never
## on screen"* into *"placed just off screen"* rather than *"placed wherever is convenient
## right now"*.
##
## The camera sits on her at zoom 2 over a 1280x720 viewport, so the visible world is
## 640x360: 320px to the edge sideways, 180px vertically (docs/EVENTS.md, "Everything
## arrives from off screen"). The half-diagonal — the worst case, a corner of the screen —
## is `sqrt(320² + 180²)` ≈ 367px. 400px sits just past that, so a mark placed or re-placed
## at this distance walks into view rather than appearing in it, the same reasoning M77 uses
## to site every arrival off screen (docs/DECISIONS.md, M77). Smallest reading of the
## player's own sentence, open to overturn: a single constant here is one edit to move it.
const NOTICE_RADIUS := 400.0

## How close she has to stand to a mark — on top of it being on screen — before it counts as
## noticed (M177, playtest 116: a mark whose tile merely swept across the camera fifteen tiles
## from where she stood used to freeze on that one frame, which is not the same claim as having
## seen it). The distance half of "near enough, for long enough, that walking away from it is a
## choice", and also of the player's own second pass on this milestone: *"they should only get
## pinned whenever you see them (and not at the edge of the screen really)"*.
##
## **Chosen below 180, the visible world's own vertical half-extent** (`NOTICE_RADIUS`'s own doc:
## the camera at zoom 2 over a 1280x720 viewport shows 320px sideways and 180px vertically from
## her). A circle of this radius is the shape the euclidean check actually draws, so the binding
## constraint is the *shorter* axis: at 150, any point inside the circle is on screen on **every**
## bearing, not merely a favourable one — the corner case a distance under the wider, 320px
## sideways half-extent would still have let through, sitting right at the top or bottom edge with
## little sideways offset. That makes "well inside the view" a geometric guarantee rather than a
## typical case, which is what makes `_sight.call(at)` below redundant whenever this already holds
## and left in anyway, for a rig whose `_sight` answers something other than the real screen.
## Felt, open to overturn against a played day.
const SEEN_DISTANCE := 150.0

## How long she has to hold `SEEN_DISTANCE` and on screen, continuously, before the mark is
## noticed — the time half of the same rule. A single frame is a tile sweeping past at the edge of
## a running stride; a second is long enough that walking past would not trigger it by accident
## while stopping to read a wall would. Felt, open to overturn.
const SEEN_DWELL_SECONDS := 1.0

## How many bearings `_draw_guard_position` tries before giving up on the day's guard. A
## `barricade`-scale alley is 64px wide against a band that can reach past 150px out — most
## bearings land in the building on either side of it — so this is generous rather than tight;
## what bounds it at all is that a draw has to stop somewhere; see `_draw_guard_position`'s own
## doc for the fallback when it does.
const TRAP_DRAW_LIMIT := 24

## How many bearings `_reachable_offset` tries before it steps to the nearest walkable ground
## instead — a task's rider sits wherever `EventScheduler` put it, which can be flush against a
## building, so the fixed clearance distance can land inside that same building on some bearings
## and not others. The same shape of budget as `TRAP_DRAW_LIMIT`, for the same reason: a draw has
## to stop somewhere; see `_reachable_offset`'s own doc for the fallback when it does.
const REACHABLE_OFFSET_DRAW_LIMIT := 24

## How many times `_pick_reachable` redraws from its own pool when the draw itself lands on a
## solid body — checked after the draw rather than filtered out of the pool beforehand, so a pool
## with nothing obstructed in it draws exactly the index it always did; see `_pick_reachable`'s own
## doc for why. The same shape of budget as `TRAP_DRAW_LIMIT` and `REACHABLE_OFFSET_DRAW_LIMIT`.
const PICK_REACHABLE_REDRAW_LIMIT := 24

## The sentinel `_nearest_legal_in_pool()` and `_nearest_legal_tile()` answer for "nothing
## qualified" — off the grid, since every real tile this director ever asks about is non-negative.
const _NO_TILE := Vector2i(-1, -1)

## How long the man shouting stays and keeps shouting after day 6's note is handed over, before
## `_lingering_rider` actually leaves (M205, "the note costs, and the ordinary day" — the player,
## asked whether an instant handover should still cost something: "he keeps shouting for a bit").
## His field charges her exactly as any live `homeless_yeller`'s does for the whole delay, so
## walking away from him afterward costs rather than being free the instant the note changes hands.
##
## **Chosen so the total plateaus near an ordinary pass, not so it is timed to hit one.** Walking
## away from his `inner_radius` at `Tuning.WALK_SPEED` clears his `outer_radius` (210px, past which
## `EventInstance.contribution_at()` answers zero) in a little over two seconds; this sits past
## that clearing point with a margin, so the total lands wherever the field's own falloff already
## plateaus rather than depending on catching an exact frame.
## `tests/probes/m205_note_handover.gd` measures the plateau at ~11.1 points awake and ~-3.2 asleep
## against an ordinary pass's own ~11.1/~-3.2 (`M174Pass.pass_net_averaged()` at 0px) — felt, open
## to overturn against a played day rather than against that printout.
const NOTE_HANDOVER_LINGER_SECONDS := 2.5

var _city: City
var _map: CityMap
var _contact: ContactPoint
## The mark's own touched `ContactPoint`, once she has read it — kept alive rather than freed the
## instant `_begin_step()` activates the perform it unlocks, so `chalk_mark_touched.svg` keeps
## showing where she read it for the rest of the attempt (the player, asked whether a read mark
## should vanish at once or stay: "Stays crossed, until the day ends"), even when the task it
## unlocked expires. `start_day()` frees it, so it never survives a retry or the next day, and a
## day reads one mark at most, so no second one ever stands beside it. Null before a mark has been
## read this attempt.
var _read_mark: ContactPoint
## The `EventInstance` a perform step's contact rides on. Null for a pickup, the finale, or a
## `DOOR`/`PARK_SWING` step, all of which sit on a bare tile instead.
var _rider: EventInstance
var _step: ResistanceSteps.Step
## The `MastSites.Site.id` of the mast day 11's task was sent to, "" on every other step — kept so
## the touch silences the mast the arrow pointed at rather than whichever is nearest her then.
var _mast_id := ""
## The neighbor she did not reach, standing at her own door after the task expired — taken with the
## raid once she is not looking (`_take_the_neighbor_away()`). Null on every other day.
var _taken_neighbor: EventInstance
## Set only while a man shouting is lingering after the note is handed over — the delay before
## `EventInstance.leave_for_a_completed_task()` actually runs (M205, "he keeps shouting for a
## bit"). Null the rest of the time, including for every other kind of step.
var _lingering_rider: EventInstance
var _lingering_remaining := 0.0
var _elapsed := 0.0
var _day_length := 0.0
var _expired := false
var _day := 0

## Injected by `main` from the one rotation-aware "is this on screen" test the game already
## has, `DangerEdge.is_on_screen()`. A rig may leave this unset — with no predicate, nothing
## is ever seen and the re-placement rule below simply keeps running, which is also correct:
## a mark nobody is watching for should never stop moving because of it.
var _sight: Callable
## Whether the current pickup's mark has been seen this world-day. Sticky once true — see
## `_track_sight_and_reposition()`.
var _seen := false
## Seconds she has held `SEEN_DISTANCE` and on screen, continuously, toward `SEEN_DWELL_SECONDS`.
## Reset to zero the instant either condition breaks — see `_track_sight_and_reposition()`.
var _seen_dwell := 0.0
## The `alley_robbery` standing by the current mark, from `TRAP_FIRST_DAY`. Tracked so a
## relocation can retire it and `_maybe_set_a_trap` a fresh one near wherever the mark goes —
## never retired for any other reason: he stands until the day ends, whether or not the mark he
## guards has since been read, chased her or is merely standing there still asleep.
var _guard: EventInstance
## The guard a perform step sited on a bare point or a row sets over its own contact (a door, a
## mast's foot, a swing, the burnt shell, a roadblock) — tracked apart from `_guard` so activating
## it, right behind the mark in the same `_on_contact_completed()` call, never retires the mark's
## own guard by mistake. Set once a day and never replaced until the next `start_day()`, since
## none of these contacts ever relocates.
var _task_guard: EventInstance
## The `robber_giving_chase` or `van_guard_giving_chase` today's handed-over task set on her
## (`_set_the_trap_on_her()`), or null before a task is handed over. Nothing here steers him — he
## chases on his own — so this is kept only so what was set can be read back.
var _trap: EventInstance
## The RNG `start_day()` was handed, kept rather than re-drawn so a guard spawned later —
## when the mark moves, or when the mark's own touch activates today's perform step — still
## comes from the same day's stream a replay would reproduce.
var _rng: RandomNumberGenerator
var _player: Stroller
## What the story puts in the street besides the task — see `ResistanceHappenings`.
var _happenings := ResistanceHappenings.new()

## The day's own reachability answer, built lazily (`_ensure_reachability()`) the first time a
## placement asks it and kept for the rest of the day — cleared in `start_day()` so a new day
## never reads yesterday's obstruction. `ReachabilityGrid.build()` is cheap enough to do once a
## day (`EventScheduler._ensure_the_city_is_still_walkable()`'s own doc says the same); this
## director asks the same grid the same way, not a second implementation of it.
var _reach_grid: ReachabilityGrid
## `EventScheduler.blocked_by()`'s own set: today's closures plus every placed, obstructing or
## hard-fail plan's own disc — the whole day's obstruction, exactly as it stands when this
## director places, per M188's item 3.
var _reach_blocked: Dictionary
## `_reach_grid.flood()`'s own answer for `_reach_blocked`, from the home block — kept so
## `reaches()` never has to recompute the dirty-cell set flood() already built.
var _reach_reached: Dictionary
## `_through_alley_tiles()`'s own answer, and the map it was built for.
var _through_alleys: Array[Vector2i] = []
var _through_alleys_of: CityMap

func setup(city: City, map: CityMap) -> void:
	# The same self-registration `WorldContext` and `Stroller` use, so anything that needs to ask
	# this director a read-only question — `pointable_objective()`, for a protester — finds it
	# with `get_tree().get_first_node_in_group("resistance")` rather than being handed a reference
	# by whoever built the scene.
	add_to_group("resistance")
	_city = city
	_map = map
	_happenings.setup(city, map)

## Lets the danger edge's own screen test answer "has she seen this" for the resistance
## too, without the director holding a viewport of its own. See the class doc on `_sight`.
func set_sight(is_on_screen: Callable) -> void:
	_sight = is_on_screen

func start_day(day: int, rng: RandomNumberGenerator, day_length: float) -> void:
	_clear()
	# The mark she read, if any, stands crossed through until the day ends (`_read_mark`) — here,
	# and not in `_clear()`, which a task expiring mid-day also runs.
	if _read_mark and is_instance_valid(_read_mark):
		_read_mark.queue_free()
	_read_mark = null
	_elapsed = 0.0
	_day_length = day_length
	_expired = false
	_day = day
	_rng = rng
	_seen = false
	_seen_dwell = 0.0
	_guard = null
	_task_guard = null
	_trap = null
	_taken_neighbor = null
	# Rebuilt lazily on the first placement that asks — see `_ensure_reachability()` — rather than
	# here, so a rig that never places anything today never pays for a grid it never needed.
	_reach_grid = null
	_reach_blocked = {}
	_reach_reached = {}
	# A fresh attempt at the day starts without the package, whether this is the first try
	# or a retry after a nerve — see GameState.resistance_carrying_package.
	GameState.resistance_carrying_package = false
	_happenings.start_day(day)

	var step := ResistanceSteps.for_day(day, GameState.completed_resistance_steps,
			GameState.failed_resistance_steps, GameState.sabotage_available())
	_begin_step(step)

## Places `step`'s own contact and offers it — a mark at dawn, or the perform half it unlocks a
## moment after being touched (`_on_contact_completed()`), which is what makes a task one day
## instead of two. `ResistanceSteps.TargetKind` decides how a non-pickup, non-finale step finds
## its own place: a fresh rider (`EVENT`), the run's own recorded scar (`SCAR`, falling back to
## an ordinary placement of the same row when the run has none), or a bare point this director
## computes itself (`ResistanceSteps.sits_on_a_bare_point()`).
func _begin_step(step: ResistanceSteps.Step) -> void:
	_step = step
	if not _step:
		return

	var scar_instance: EventInstance = null
	if _step.target_kind == ResistanceSteps.TargetKind.SCAR:
		scar_instance = _find_scar_instance(_step.task_event_id)
		if not scar_instance:
			# The smallest honest stand-in for a run with no recorded scar: an ordinary
			# placement of the same row, on ground `_place()` would otherwise have chosen for
			# it — never a step with nowhere to go.
			Telemetry.note("contact", ("step %d: no recorded scar for '%s' — an ordinary " +
					"placement stands in for it") % [_step.index, _step.task_event_id])

	var neighbor: EventInstance = null
	if _step.target_kind == ResistanceSteps.TargetKind.NEIGHBOR:
		neighbor = _send_the_neighbor_home()
	var at: Vector2
	if scar_instance:
		at = scar_instance.global_position
	elif neighbor:
		at = neighbor.global_position
	elif _step.target_kind == ResistanceSteps.TargetKind.NEIGHBOR:
		at = Vector2.INF
	else:
		at = _place(_step, _rng)
	if at == Vector2.INF:
		push_warning("resistance step %d has nowhere to go in this city" % _step.index)
		_step = null
		return

	# The contact this replaces is only ever the mark she has just read, activating the task right
	# behind it in this same call (`start_day()` clears everything else first). It stays standing
	# as `_read_mark`, crossed through, rather than being freed: the player, asked whether a read
	# mark should vanish at once or stay, "Stays crossed, until the day ends". Anything else is
	# freed.
	if _contact and is_instance_valid(_contact):
		if _contact.step != null and _contact.step.is_pickup:
			_read_mark = _contact
		else:
			_contact.queue_free()
	_contact = ContactPoint.new()
	if neighbor:
		_rider = neighbor
		_contact.ride(_step, neighbor, Vector2.ZERO)
	elif scar_instance:
		var offset := _reachable_offset(scar_instance, _rng)
		_rider = scar_instance
		_contact.ride(_step, scar_instance, offset)
		at = scar_instance.global_position + offset
	elif _step.is_pickup or ResistanceSteps.sits_on_a_bare_point(_step):
		_contact.setup(_step, at)
	else:
		var task_def := EventCatalogue.by_id(_step.task_event_id)
		if not task_def:
			push_warning("resistance step %d rides on unknown event '%s'"
					% [_step.index, _step.task_event_id])
			_step = null
			_contact = null
			return
		_rider = _city.events.spawn_extra(task_def, at)
		var offset := _reachable_offset(_rider, _rng)
		_contact.ride(_step, _rider, offset)
		at = _rider.global_position + offset
	_contact.completed.connect(_on_contact_completed)
	_city.add_entity(_contact)
	EventBus.resistance_contact_available.emit(_step.index)
	Telemetry.note("contact", "step %d on offer at %s" % [
		_step.index, TelemetryLog.tile(_map.world_to_tile(at))])

	# A guard stands where a contact waits. The neighbor does not wait — they are walking home — so
	# a robber at the spot they set out from would guard nothing. The man shouting and the van are
	# not guarded where they wait at all: their trap comes to her once she has handed it over
	# (`sets_a_trap_on_her()`), from wherever she did. Every other task that rides on a row — the
	# burnt shell, a roadblock — keeps a guard waiting at the contact, exactly like a chalk mark.
	#
	# The mark's own guard (`_step.is_pickup`) is placed at dawn, before she is anywhere real
	# (`main.gd` starts the resistance before resetting her) — `Vector2.INF`/`false` skips both
	# her-position and on-screen checks, which a stale camera and a stale player position could
	# not answer honestly. A perform step's own guard is placed the instant she reads the mark
	# that unlocked it, live, so her position and the screen both matter here.
	if not neighbor and not sets_a_trap_on_her(_step):
		if _step.is_pickup:
			_maybe_set_a_trap(_day, _rng, at, true, Vector2.INF, false)
		else:
			_maybe_set_a_trap(_day, _rng, at, false, _player_position(), true)

## The live instance standing at the run's own recorded scar for `scar_id`, or null when the run
## never recorded one — a day 3 that never actually burned this run, or a fix for that landing on
## another branch. `GameState.scars` names the position the scar was recorded at; the scheduler
## re-places the same def there every day after `since_day` (`EventScheduler._place_scars()`), so
## the live instance is found by position rather than tracked by reference across days.
func _find_scar_instance(scar_id: String) -> EventInstance:
	if not _city or not _city.events:
		return null
	var at := Vector2.INF
	for scar: Dictionary in GameState.scars:
		if String(scar["id"]) == scar_id:
			at = scar["position"]
			break
	if at == Vector2.INF:
		return null
	# Under a tile's own width, not an exact match: the scheduler's own placement of a solid
	# shape can nudge it a few pixels off the recorded position (`EventScheduler._place_scars()`
	# hands the scar's own coordinate straight to `Planned`, but the def's own centring — see
	# `EventDef.solid()` — still applies once it becomes an `EventInstance`). Since `burnt_shell`
	# is `SCRIPTED` and only ever placed this way, the one instance of it a day carries is the
	# scar, whatever the exact offset.
	for instance in _city.events.instances():
		if instance.def.id == scar_id and instance.global_position.distance_to(at) < Tuning.TILE_SIZE:
			return instance
	return null

## The guard. From `TRAP_FIRST_DAY` no chalk mark is ever placed without one, nor a task that sits
## on a bare point (a door, a mast's foot, a swing, the last night's front door) or rides on a row
## without sending its own trap after her (the burnt shell, a roadblock) — a robber drawn
## from the band `alley_robbery`'s own numbers fix, so *always guarded* stays survivable
## instead of a guaranteed lost day. The man shouting and the van get `_set_the_trap_on_her()`
## instead, and the neighbor neither: see `_begin_step()`.
##
## **A chalk mark's own guard (`for_mark`) stands at the other end of its alley from `at`**
## (`_draw_guard_position_near_far_mouth()`), which is what the player's own words ask for twice: *"the rubber in the alley with the mark is too close to the
## mark. It's impossible to get the mark on most days. Let's always place the river at the other
## end of the alley"* (PLAYTEST-142 statement 5, "rubber"/"river" dictation for *robber*), and,
## asked whether he may then never wake at all, *"stands at the far end even where he then never
## wakes"* (PLAYTEST-144 statement 11). Every other guarded contact (a door, a mast's foot, a
## swing, the burnt shell, a roadblock) keeps a band between `inner_radius + ContactPoint.REACH`
## and `pursues_within + ContactPoint.REACH`, drawn from the whole circle around its own contact.
##
## **Retires only the guard of the same kind this replaces**, so a perform step whose contact is
## itself guarded (a door, a mast's foot, a swing, the burnt shell, a roadblock) never takes an
## awake or chasing mark's guard out of the day the instant its own `_begin_step()` activates,
## right behind the mark's own in the same `_on_contact_completed()` call: `_guard` (the mark's
## own) and `_task_guard` (the perform step's) are separate fields, each retired only by whatever
## replaces its own kind. The mark's own guard stands until the day ends however she leaves
## him — `_move_the_mark()`'s relocation is the one thing that ever retires him early, and it
## never runs while he is awake (`_track_sight_and_reposition()`'s own guard).
##
## **`her` and `on_screen_matters` are the caller's to give**, since only a caller placing a
## contact she is actually near has anything true to say about either. `_player_position()`
## answers wherever she is *right now*, which at dawn is still where the previous attempt left
## her — `main.gd` starts the resistance before resetting her — so a mark's own dawn placement
## passes `Vector2.INF`/`false` for both, keeping the draw deterministic from the run seed and the
## day alone; a perform step's own guard, placed the instant she reads the mark that unlocked it,
## and `_move_the_mark()`'s relocation both pass her live position and `true`, since she is
## genuinely there to be kept clear of and off screen from.
func _maybe_set_a_trap(day: int, rng: RandomNumberGenerator, at: Vector2, for_mark: bool,
		her: Vector2, on_screen_matters: bool) -> void:
	if day < TRAP_FIRST_DAY:
		return
	var robbery := EventCatalogue.by_id("alley_robbery")
	if not robbery:
		return
	var existing: EventInstance = _guard if for_mark else _task_guard
	if existing and is_instance_valid(existing):
		_city.events.retire(existing)
	if for_mark:
		_guard = null
	else:
		_task_guard = null
	var guard_at := _guard_position(rng, at, for_mark, her, on_screen_matters)
	var placement := "far end" if for_mark and _far_alley_mouth(at) != Vector2.INF else "band"
	var kind := "chalk mark" if for_mark else "task"
	if guard_at == Vector2.INF:
		# **No trap is better than a trap in a wall.** `TRAP_DRAW_LIMIT` bearings (or the far
		# mouth and every legal step in from it) found nowhere walkable at all — every one of them
		# a building, a held segment, the home block or in view of her — so the contact goes out
		# unguarded today rather than guarded by a robber stuck for ever where nobody can ever
		# meet him. `docs/DECISIONS.md`, M100, "The guard robber is placed inside a building,
		# where he is stuck for ever".
		Telemetry.note("roll", "%s unguarded: no walkable ground for the robber in %d draws"
				% [kind, TRAP_DRAW_LIMIT])
		return
	Telemetry.note("roll", "%s guarded (%s): robber %.0fpx away"
			% [kind, placement, at.distance_to(guard_at)])
	if for_mark:
		_guard = _city.events.spawn_extra(robbery, guard_at)
	else:
		_task_guard = _city.events.spawn_extra(robbery, guard_at)

## Where `_maybe_set_a_trap()` stands a guard for the contact at `at`, without spawning him:
## `_draw_guard_position_near_far_mouth()` for a chalk mark on a through-alley, the whole-circle
## band `_draw_guard_position()` draws for every other guarded contact. `Vector2.INF` when no
## candidate qualifies. Split out so a rig can ask where he would stand.
func _guard_position(rng: RandomNumberGenerator, at: Vector2, for_mark: bool, her: Vector2,
		on_screen_matters: bool) -> Vector2:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance := robbery.inner_radius + ContactPoint.REACH
	var max_distance := robbery.pursues_within + ContactPoint.REACH
	var walled_alleys := _walled_alleys()
	var her_refuse_within := robbery.pursues_within if her != Vector2.INF else 0.0
	var far := _far_alley_mouth(at) if for_mark else Vector2.INF
	if far != Vector2.INF:
		return _draw_guard_position_near_far_mouth(rng, at, far, min_distance, max_distance,
				walled_alleys, her, her_refuse_within, on_screen_matters)
	return _draw_guard_position(rng, at, Vector2.INF, min_distance, max_distance,
			walled_alleys, her, her_refuse_within, on_screen_matters)

## Whether `step`'s trap comes to her rather than waiting at its contact: the man shouting
## (`task_event_id` "homeless_yeller") and the van (`"delivery_van"`), the two tasks named at the
## keyboard — *"spawn the robber in pursuing mode offscreen when she interacts with the yeller"*
## for the first, PLAYTEST-144 statement 15 for the second: "After the van (day 7) a guard chases
## her; after the man shouting, the robber, which is fine only if he starts off screen." **Not the
## neighbor**, whose task has never been guarded — they are walking home, and a guard at the spot
## they set out from would guard nothing — and never a chalk mark, a bare-point task, the burnt
## shell, a roadblock or the last night, whose robber still waits at the contact
## (`_maybe_set_a_trap()`).
static func sets_a_trap_on_her(step: ResistanceSteps.Step) -> bool:
	return step != null and step.task_event_id in ["homeless_yeller", "delivery_van"]

## Which catalogue row `_set_the_trap_on_her()` spawns for `step`'s own task: the alley robber for
## the man shouting, the roadblock's own guard for the van. Only ever asked once
## `sets_a_trap_on_her(step)` is already true, so every other `task_event_id` would be a bug
## reaching here rather than a real third case. Takes the completed step its caller already holds
## rather than reading `_step`, so it names the right row by construction rather than by the
## coincidence that `_step` has not yet advanced when a perform step's own handover calls it.
func _trap_row_id(step: ResistanceSteps.Step) -> String:
	return "van_guard_giving_chase" if step and step.task_event_id == "delivery_van" \
			else "robber_giving_chase"

## **The trap comes to her.** *(2026-09-13, the player: "maybe spawn the robber in pursuing mode
## offscreen when she interacts with the yeller so it runs towards her from offscreen".)* The moment
## the man shouting's note or the van's package is handed over, `_trap_row_id()`'s row — the alley
## robber for the first, the roadblock's own guard for the second, awake from its first frame — is
## spawned off screen, usually `Tuning.TRAP_ARRIVAL_DISTANCE` (313px) above or
## below her, always far enough past the edge of the view that the screen-edge badge is up before it
## is in it (`_draw_arrival_position()`), and comes at her. So whichever look-alike she chose, the errand costs the same: the price is
## paid on the way out, from wherever she did it, rather than guarded at one seeded spot she could
## avoid by picking another. The screen-edge badge announces it while it is off screen, the same
## way it announces any pursuer (`DangerEdge._is_worth_an_arrow()`).
##
## From `TRAP_FIRST_DAY`, like the guard. Where she is, or the contact she has just touched when
## no player is in the tree (a bare director in a rig): she is within `ContactPoint.REACH` of it.
## Nothing is spawned when `_draw_arrival_position()` finds no ground, which the run log says.
func _set_the_trap_on_her(step: ResistanceSteps.Step) -> void:
	if _day < TRAP_FIRST_DAY or not _city or not _city.events:
		return
	var def := EventCatalogue.by_id(_trap_row_id(step))
	if not def:
		return
	var her := _player_position()
	if her == Vector2.INF:
		her = contact_position()
	if her == Vector2.INF:
		return
	var arrival := _draw_arrival_position(_rng, her, def)
	var at: Vector2 = arrival[0]
	if at == Vector2.INF:
		Telemetry.note("roll", ("task handed over unguarded: no walkable ground %.0fpx from her "
				+ "in %d draws") % [Tuning.TRAP_ARRIVAL_DISTANCE, TRAP_DRAW_LIMIT + 4])
		return
	_trap = _city.events.spawn_extra(def, at)
	var run := "no clear run at her"
	if arrival[1]:
		run = "a clear run at her along her street, beside her" if arrival[2] \
				else "a clear run at her"
	var sent := "a robber" if def.id == "robber_giving_chase" else "a guard"
	Telemetry.note("roll", "task handed over: %s sent after her from %s, %.0fpx off (%s)"
			% [sent, TelemetryLog.tile(_map.world_to_tile(at)), her.distance_to(at), run])

## Where the robber a handed-over task sets on her starts, past `badge_line()` so the screen-edge
## badge is up before he is on screen, on ground `_draw_guard_position()`'s own refusals leave alone
## (walkable, not behind a closure, not held, not the home block, not a walled-off alley) and off
## screen by `_sight` as well. Returns `[position, clear, beside]` — `Vector2.INF` when no start
## qualifies; `clear` when the straight line from there to her is walkable; `beside` when he starts
## to her side rather than above or below her.
##
## **Above or below her, `Tuning.TRAP_ARRIVAL_DISTANCE` (313px) out, by preference.** That is past
## the badge line vertically within `arrival_cone()` — about 17° for `robber_giving_chase`
## (`outer_radius` 200), about 13° for `van_guard_giving_chase` (`outer_radius` 120, a narrower
## field, so the badge needs longer to rise and the cone that stays past its line is tighter) — of
## straight up or down, and never sideways, where the view is wider — so those bearings are drawn
## inside the two cones rather than from the whole circle. Straight up and straight down first, in
## an order the day's RNG picks, then `TRAP_DRAW_LIMIT` bearings from the cones.
##
## **A clear run at her is what decides it**, since he chases in a straight line
## (`EventInstance._chase()`), sliding along whatever wall is in the way: a start behind a building
## is a man stuck against its back wall while the badge says he is coming. On a minority of
## handovers there is no clear run from above or below — she is on a street that runs sideways,
## with no crossing street near enough — and **then he comes along her own street**, straight left
## or right at `beside_distance()` (about 466px), past the badge line sideways. From there walking
## directly away outlasts his notice and chase, which is the price of a start the wider view needs;
## standing still or walking into him is still caught. Only when neither has a clear run does the
## first legal start of all of them stand in, and then he may never reach her — measured at 1 in
## 200 seeds for `robber_giving_chase`, never for `van_guard_giving_chase`
## (`tests/probes/m137_trap_arrival.gd`).
##
## **Measured over 200 seeds each with `tests/probes/m137_trap_arrival.gd`**, one handover per
## seed: the beside fallback fires for `robber_giving_chase` 40 times in 200 (20.0%) and for
## `van_guard_giving_chase` 54 times in 200 (27.0%) — the guard's narrower 120px field (against the
## robber's 200px) leaves a tighter vertical cone (`arrival_cone()`), so fewer of its bearings clear
## a wall along the way.
func _draw_arrival_position(rng: RandomNumberGenerator, her: Vector2, def: EventDef) -> Array:
	var walled_alleys := _walled_alleys()
	var cone := arrival_cone(def)
	var up := PI / 2.0 if rng.randf() < 0.5 else -PI / 2.0
	var starts: Array[Vector2] = [Vector2.RIGHT.rotated(up) * Tuning.TRAP_ARRIVAL_DISTANCE,
			Vector2.RIGHT.rotated(-up) * Tuning.TRAP_ARRIVAL_DISTANCE]
	for _attempt in TRAP_DRAW_LIMIT:
		var side := PI / 2.0 if rng.randf() < 0.5 else -PI / 2.0
		starts.append(Vector2.RIGHT.rotated(side + rng.randf_range(-cone, cone))
				* Tuning.TRAP_ARRIVAL_DISTANCE)
	var along := 1.0 if rng.randf() < 0.5 else -1.0
	var beside := beside_distance(def)
	starts.append(Vector2(along * beside, 0.0))
	starts.append(Vector2(-along * beside, 0.0))
	var fallback := Vector2.INF
	for offset in starts:
		if not is_past_the_badge_line(offset, def):
			continue
		var candidate := her + offset
		var tile := _map.world_to_tile(candidate)
		if not is_legal_ground(_map, tile, walled_alleys):
			continue
		if _sight.is_valid() and _sight.call(candidate):
			continue
		if _a_clear_run(candidate, her):
			return [candidate, true, is_zero_approx(offset.y)]
		if fallback == Vector2.INF:
			fallback = candidate
	return [fallback, false, false]

## How far from her, along each axis, a pursuer `def` started `distance` out has to be for
## `DangerEdge` to raise its badge before he is on screen, whatever the camera is doing. Per axis,
## in world px:
##
## - `Tuning.VIEW_HALF_EXTENT` (320 × 180), half the view;
## - plus the most the camera leads toward him — `Stroller.CAMERA_LOOK_AHEAD` (46px) sideways,
##   46 × `Stroller.OBLIQUE_Y` (32px) vertically, when she faces him;
## - plus `DangerEdge.SCREEN_MARGIN` (130 screen px, 65px of world at zoom 2), how far outside the
##   view a thing has to be before a badge is raised for it;
## - plus the ground the gap closes by while the badge rises (`badge_rise_time()`), at his speed and
##   hers together, since she may be walking into him.
##
## For `robber_giving_chase` at 313px, about 453 sideways and 299 vertically; for
## `van_guard_giving_chase` at the same 313px, about 459 sideways and 305 vertically — a few px
## more each way, since his narrower 120px `outer_radius` (against the robber's 200px) leaves more
## of the approach still to close and so costs the badge a little longer to rise.
static func badge_line(def: EventDef, distance: float) -> Vector2:
	var world_per_screen_px := Tuning.VIEW_HALF_EXTENT.x * 2.0 / ScreenOrientation.DESIGN_SIZE.x
	var lead := Vector2(Stroller.CAMERA_LOOK_AHEAD, Stroller.CAMERA_LOOK_AHEAD * Stroller.OBLIQUE_Y)
	var rising := (def.pursue_speed + Tuning.WALK_SPEED) \
			* badge_rise_time(def.pursue_speed, distance, def.outer_radius)
	return Tuning.VIEW_HALF_EXTENT + lead + Vector2.ONE \
			* (DangerEdge.SCREEN_MARGIN * world_per_screen_px + rising)

## How long `DangerEdge` takes to raise a badge for something closing at `speed` from `distance`
## out, with a field of `outer`: the approach it measures is smoothed (`DangerEdge.SMOOTHING`, 6/s,
## from zero), and it announces once that reaches `DangerEdge.announces()`'s own threshold at that
## range — `CLOSING_SPEED`, or the gap to the field over `LEAD_TIME`. Plus two frames at 30 frames a
## second, the slowest a phone runs it: the first, which has no earlier position to measure an
## approach from, and one of rounding. About 0.1s for the robber at 313px, 0.15s at his 466px
## beside distance; about 0.13s for the van's guard at 313px, 0.2s at his own 476px beside
## distance — his narrower field leaves more of the approach still to close either way.
static func badge_rise_time(speed: float, distance: float, outer: float) -> float:
	var needed := maxf(DangerEdge.CLOSING_SPEED, maxf(0.0, distance - outer) / DangerEdge.LEAD_TIME)
	if needed >= speed:
		return INF
	return 2.0 / 30.0 + log(speed / (speed - needed)) / DangerEdge.SMOOTHING

## Whether a start at `offset` from her is outside the view grown by `badge_line()` — past it on
## either axis is outside the box.
static func is_past_the_badge_line(offset: Vector2, def: EventDef) -> bool:
	var line := badge_line(def, offset.length())
	return absf(offset.x) >= line.x or absf(offset.y) >= line.y

## The half-angle, in radians, of the cone about straight up or straight down inside which a start
## `Tuning.TRAP_ARRIVAL_DISTANCE` out is past `badge_line()` vertically — zero if it never is.
static func arrival_cone(def: EventDef) -> float:
	var line := badge_line(def, Tuning.TRAP_ARRIVAL_DISTANCE)
	return acos(minf(1.0, line.y / Tuning.TRAP_ARRIVAL_DISTANCE))

## How far to her side he starts when he comes along her own street: the least distance past
## `badge_line()` sideways. The line moves out with the start, since a further start takes the badge
## longer to rise for, so it is walked out to where it stops moving and rounded up.
static func beside_distance(def: EventDef) -> float:
	var distance := badge_line(def, 0.0).x
	for _step in 6:
		distance = badge_line(def, distance).x
	return ceilf(distance)

## Whether every point on the straight line from `from` to `to` is walkable, sampled at a quarter
## tile — the question `EventInstance._walkable_step()` asks of each step a chaser takes.
func _a_clear_run(from: Vector2, to: Vector2) -> bool:
	var steps := ceili(from.distance_to(to) / (Tuning.TILE_SIZE * 0.25))
	for i in steps + 1:
		var point := from.lerp(to, float(i) / float(maxi(steps, 1)))
		if not _map.is_walkable(_map.world_to_tile(point)):
			return false
	return true

## A bearing and a distance from `at`, redrawn until the point is walkable ground the day's
## catalogue and the home-block exemption both leave alone — rejected rather than repaired, the
## same rule every other placement in this game keeps. `docs/DECISIONS.md`, M100, "The guard robber is
## placed inside a building": his lethal radius travels with him, so a bearing that lands him in
## a building is an invisible fatal spot rather than a cosmetic one.
##
## **Used for every guarded contact but a chalk mark's own**, drawn from the whole circle: the
## director always passes `toward` as `Vector2.INF` (a rig may pass a point to lean the bearing to
## the half-circle facing it), and `_guard_position()` sends a mark's own guard to
## `_draw_guard_position_near_far_mouth()` instead. An `ALLEY` tile by preference, since the
## row's own placement is `ALLEY`, but not a requirement: the band this draws from can reach well
## past a two-tile-wide alley's own building line, so an alley hit is kept the moment it is found
## and any other walkable, unheld, off-the-home-block tile is kept as a fallback in case the
## budget runs out first. `Vector2.INF` when `TRAP_DRAW_LIMIT` draws found neither — see the
## caller for what that means.
##
## `walled_alleys` defaults empty for the bare-map rigs several tests in `tests/test_resistance.gd`
## drive with no `_city` — see `_walled_alleys()`, which is what the real caller passes.
##
## **Never within `her_refuse_within` of `her`, and never where `_guard_shows()` calls him seen**
## (brisk-wombat, "a robber also appeared out of nowhere and instakilled me"): a candidate is
## drawn purely from the band around `at`, with no idea where she stands or what the camera can
## see, so both refusals are what keeps him off her — outside his own `pursues_within`, or worse
## his `inner_radius`, a `hard_fail` with no warning at all — and off screen, whichever contact
## `at` names. `her` is `Vector2.INF` and `on_screen_matters` is `false` for a caller with nothing
## live to keep away from — every bare-map rig in `tests/test_resistance.gd` that calls this
## directly, and a chalk mark's own dawn placement (see `_maybe_set_a_trap()`) — which never
## rejects anything on either count.
func _draw_guard_position(rng: RandomNumberGenerator, at: Vector2, toward: Vector2,
		min_distance: float, max_distance: float, walled_alleys: Array[Rect2i] = [],
		her: Vector2 = Vector2.INF, her_refuse_within: float = 0.0,
		on_screen_matters: bool = false) -> Vector2:
	var fallback := Vector2.INF
	for _attempt in TRAP_DRAW_LIMIT:
		# Hoisted so the draw can be written down. Which distance a mark got is the one random
		# outcome that decides a run without a route around it, and the only one whose
		# consequence otherwise looks like bad luck with the event scheduler.
		var distance := rng.randf_range(min_distance, max_distance)
		var angle: float
		if toward == Vector2.INF:
			angle = rng.randf() * TAU
		else:
			var facing_toward := (toward - at).angle()
			angle = facing_toward + rng.randf_range(-PI / 2.0, PI / 2.0)
		var candidate := at + Vector2.RIGHT.rotated(angle) * distance
		if her != Vector2.INF and candidate.distance_to(her) <= her_refuse_within:
			continue
		if on_screen_matters and _guard_shows(candidate):
			continue
		var tile := _map.world_to_tile(candidate)
		if not _map.is_walkable(tile) or _map.is_closed(tile) or _map.is_held_at(tile) \
				or _map.is_on_home_block(tile) or _map.is_in_walled_alley(tile, walled_alleys):
			continue
		if _map.tile_at(tile) == GameEnums.TileType.ALLEY:
			return candidate
		if fallback == Vector2.INF:
			fallback = candidate
	return fallback

## How far in from the far end a chalk mark's guard may stand, at most, where the alley leaves room
## beyond `max_distance` of the mark: enough that the exact spot varies from mark to mark, never
## so much that he stops reading as standing at that end. Three tiles.
const FAR_END_REACH_IN := 96.0

## Where a chalk mark's own guard stands: at the far end of `at`'s alley (`far`, from
## `_far_alley_mouth()`), or as near it as the alley allows — the player's own words, quoted on
## `_maybe_set_a_trap()`. His distance from the mark is whatever the alley leaves, not a band
## picked around the mark the way every other guarded contact's is.
##
## **Beyond `max_distance` of the mark wherever the alley is long enough for that** —
## `pursues_within` plus `ContactPoint.REACH`, so walking right over the mark leaves him asleep —
## drawn anywhere from the far end up to `FAR_END_REACH_IN` in from it but never nearer the mark
## than that. **Where the far end itself is nearer than that, he stands on the far end**: no
## farther place exists in the alley. A through-alley is `Tuning.BLOCK_SIZE` (8) tiles long, so its
## far end is at least four tiles (128px) from any mark in it, and a touch made from the near side,
## `ContactPoint.REACH` short of the mark, is then past his `pursues_within` (140px) of him: the
## near end always reaches the mark without waking him. "It's fine if the Robert doesn't get
## triggered every time" (PLAYTEST-144, statement 11; "Robert" is dictation for *robber*).
##
## **Never within `min_distance` of the mark**, whatever the alley: inside that, touching the mark
## is death. `Vector2.INF` then, and whenever every candidate is refused — the far end last of all,
## after `TRAP_DRAW_LIMIT` draws in from it.
func _draw_guard_position_near_far_mouth(rng: RandomNumberGenerator, at: Vector2, far: Vector2,
		min_distance: float, max_distance: float, walled_alleys: Array[Rect2i], her: Vector2,
		her_refuse_within: float, on_screen_matters: bool) -> Vector2:
	var span := at.distance_to(far)
	if span < min_distance:
		return Vector2.INF
	var direction := (at - far) / span
	var reach_in := clampf(span - max_distance, 0.0, FAR_END_REACH_IN)
	var candidates: Array[Vector2] = []
	if reach_in > 0.0:
		for _attempt in TRAP_DRAW_LIMIT:
			candidates.append(far + direction * rng.randf_range(0.0, reach_in))
	candidates.append(far)
	for candidate in candidates:
		if her != Vector2.INF and candidate.distance_to(her) <= her_refuse_within:
			continue
		if on_screen_matters and _guard_shows(candidate):
			continue
		var tile := _map.world_to_tile(candidate)
		if not _map.is_walkable(tile) or _map.is_closed(tile) or _map.is_held_at(tile) \
				or _map.is_on_home_block(tile) or _map.is_in_walled_alley(tile, walled_alleys):
			continue
		return candidate
	return Vector2.INF

## Half the chalk mark's own picture, around its centre: `chalk_mark.svg` is 32px square in the
## world, drawn centre-anchored (`ContactPoint._draw_chalk()`).
const MARK_HALF_EXTENT := Vector2(16.0, 16.0)
## The waiting robber's body around his feet, where `EventInstance` stands him: his pictures are 22
## by 44px, anchored at the middle of their bottom edge (`robber_waiting*.svg`), so the box is
## centred half his height above his feet and grown a few pixels each way for his shadow.
const GUARD_BODY_CENTRE := Vector2(0.0, -22.0)
const GUARD_HALF_EXTENT := Vector2(14.0, 26.0)

## Whether any part of a box `half` either side of `centre` is on screen right now: `_sight` asked
## of the centre and the four corners. The screen is a rectangle far larger than either box and
## only ever turned by quarter turns (`ScreenOrientation`), so a box that overlaps it has a corner
## inside it. A bare centre test is what lets a picture whose centre is one pixel past the edge
## show half of itself. The corners are asked through `_sight` itself rather than
## `DangerEdge.is_on_screen()`'s own `margin`, which is in screen pixels and not in the world's.
## `false` when `_sight` is unset: the bare-map rigs several tests in `tests/test_resistance.gd`
## drive have no camera to ask, so nothing they place is ever refused for being seen.
func _box_shows(centre: Vector2, half: Vector2) -> bool:
	if not _sight.is_valid():
		return false
	for corner: Vector2 in [centre, centre + half, centre - half, centre + Vector2(half.x, -half.y),
			centre + Vector2(-half.x, half.y)]:
		if _sight.call(corner):
			return true
	return false

## Whether any part of a chalk mark's picture at `at` would be on screen right now.
func _mark_shows(at: Vector2) -> bool:
	return _box_shows(at, MARK_HALF_EXTENT)

## Whether any part of a waiting robber standing at `feet` would be on screen right now.
func _guard_shows(feet: Vector2) -> bool:
	return _box_shows(feet + GUARD_BODY_CENTRE, GUARD_HALF_EXTENT)

## The mark's own alley, as `[nearer, farther]` — the end tiles of its long axis in the mark's own
## column or row, ordered by distance from `at` — or `[]` when `at` is on no through-alley.
## `CityMap.alley_rects` is one `Rect2i` per through-alley (`CityGenerator._alley_rect()`), always
## `ALLEY_WIDTH_TILES` (2) wide and the rest of the lot long, so the long axis — the one whose ends
## are its two mouths — is whichever of the rect's own dimensions is not that width.
func _alley_ends(at: Vector2) -> Array[Vector2]:
	var ends: Array[Vector2] = []
	if not _map:
		return ends
	var tile := _map.world_to_tile(at)
	for rect in _map.alley_rects:
		if not rect.has_point(tile):
			continue
		var a: Vector2
		var b: Vector2
		if rect.size.y >= rect.size.x:
			a = _map.tile_to_world(Vector2i(tile.x, rect.position.y))
			b = _map.tile_to_world(Vector2i(tile.x, rect.end.y - 1))
		else:
			a = _map.tile_to_world(Vector2i(rect.position.x, tile.y))
			b = _map.tile_to_world(Vector2i(rect.end.x - 1, tile.y))
		if at.distance_to(a) <= at.distance_to(b):
			ends.append(a)
			ends.append(b)
		else:
			ends.append(b)
			ends.append(a)
		return ends
	return ends

## Every `ALLEY` tile that lies in a through-alley, in `CityMap.tiles_of_type()`'s own order, built
## once per map — the only ground a chalk mark is drawn on or relocated to. **Not a courtyard's
## passage**, the other `ALLEY` ground the city builds (`CityGenerator._passage_rect()`): one tile
## wide, one to a few tiles long and closed at the courtyard, it has no far end to stand a robber
## at — any spot in it is within `inner_radius` plus `ContactPoint.REACH` of a mark in it, where
## touching the mark is death — and a robber stood in the courtyard beyond would stand in a calm
## area. So the player's "always place the robber at the other end of the alley" holds for every
## mark because every mark is in an alley with another end.
func _through_alley_tiles() -> Array[Vector2i]:
	if _through_alleys_of == _map:
		return _through_alleys
	_through_alleys_of = _map
	_through_alleys = []
	for tile in _map.tiles_of_type(GameEnums.TileType.ALLEY):
		for rect in _map.alley_rects:
			if rect.has_point(tile):
				_through_alleys.append(tile)
				break
	return _through_alleys

## The end of `at`'s own alley that is farther from it — see `_alley_ends()` — or `Vector2.INF`
## when `at` is on no through-alley, which a chalk mark's own contact always is on and every other
## guarded contact never is: `_maybe_set_a_trap()` stands a mark's guard there, or as near it as
## the alley allows, rather than in a band around the mark.
func _far_alley_mouth(at: Vector2) -> Vector2:
	var ends := _alley_ends(at)
	return ends[1] if not ends.is_empty() else Vector2.INF

## Clear of any obstruction the rider carries, in a direction the day's own RNG chose — a
## fixed offset rather than a re-rolled one, so a contact that has to clear a body sits at a
## learnable spot. Zero for a rider with no body at all, like the yeller.
##
## **Redrawn, up to `REACHABLE_OFFSET_DRAW_LIMIT` times, against the same ground-legality check
## every other placement in this file keeps** (`_pick_reachable()`'s five refusals, plus
## `is_obstructed()` — see `_draw_guard_position`, which circles a point the same way for the same
## reason): the fixed distance this draws at is clear of the rider's *own* body by construction,
## but a rider sited flush against a building or another body — `EventScheduler` never asked this
## question when it placed the rider, only whether the rider's own footprint fit — can still put
## some bearings inside a wall. Rejected rather than repaired, the same rule as everywhere else.
##
## **And, M188's item 3, reachable from home under the day's whole obstruction** — see
## `_reachable_from_home()`. A rider itself only has to fit its own footprint to be placed; the
## clearance point beside it can still sit in a pocket the day's events and parked vehicles have
## sealed off, which `is_obstructed()` alone cannot see since the tile itself is open ground.
##
## **If every bearing fails, this steps to the nearest walkable, unobstructed tile within
## `ContactPoint.REACH` of the last one drawn instead of standing the contact inside whatever that
## last bearing landed in** — `DevRig.nearest_walkable()`'s own ring search, for the same reason a
## screenshot rig needs somewhere to stand, bounded to the completion radius rather than left
## unbounded: a substitute this close is still a point beside the rider, not a point that merely
## happens to be legal somewhere else in the city. `_begin_step()` has no branch for "this step has
## no reachable ground" the way `_place()` does, so a step never gets nowhere at all; Telemetry
## notes it either way, since a task whose seeded rider is this thoroughly walled in is a placement
## bug worth seeing in play.
func _reachable_offset(instance: EventInstance, rng: RandomNumberGenerator) -> Vector2:
	var clearance: float = instance.def.obstructs_radius
	if clearance <= 0.0:
		return Vector2.ZERO
	var distance := clearance + Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH
	var walled_alleys := _walled_alleys()
	var last_candidate := instance.global_position
	for _attempt in REACHABLE_OFFSET_DRAW_LIMIT:
		var offset := Vector2.RIGHT.rotated(rng.randf() * TAU) * distance
		last_candidate = instance.global_position + offset
		var tile := _map.world_to_tile(last_candidate)
		if not _map.is_walkable(tile) or _map.is_closed(tile) or _map.is_held_at(tile) \
				or _map.is_on_home_block(tile) or _map.is_in_walled_alley(tile, walled_alleys) \
				or _map.is_obstructed(tile) or not _reachable_from_home(tile):
			continue
		return offset
	var stepped := _nearest_legal_tile(last_candidate,
			ceili(ContactPoint.REACH / float(Tuning.TILE_SIZE)))
	if stepped == Vector2.INF:
		Telemetry.note("contact", ("step %d: no reachable offset found for '%s' in %d draws, and " +
				"no walkable ground within %.0fpx of the last one either — it stands in anyway")
				% [_step.index if _step else -1, instance.def.id, REACHABLE_OFFSET_DRAW_LIMIT,
				ContactPoint.REACH])
		return last_candidate - instance.global_position
	Telemetry.note("contact", ("step %d: no reachable offset found for '%s' in %d draws — " +
			"stepped to the nearest walkable ground within %.0fpx instead")
			% [_step.index if _step else -1, instance.def.id, REACHABLE_OFFSET_DRAW_LIMIT,
			ContactPoint.REACH])
	return stepped - instance.global_position

## The nearest walkable, unobstructed, reachable-from-home tile to `at`, out to `tile_radius`
## tiles — the same ring-by-ring search `DevRig.nearest_walkable()` runs for a rig with nowhere
## else to stand, checked against the same seven-refusal ground-legality test every placement in
## this file keeps rather than `is_walkable()` alone. `Vector2.INF` if nothing in range qualifies.
func _nearest_legal_tile(at: Vector2, tile_radius: int) -> Vector2:
	var start := _map.world_to_tile(at)
	var walled_alleys := _walled_alleys()
	for radius in range(tile_radius + 1):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var tile := start + Vector2i(dx, dy)
				var world := _map.tile_to_world(tile)
				if at.distance_to(world) > ContactPoint.REACH:
					continue
				if not _map.is_walkable(tile) or _map.is_closed(tile) or _map.is_held_at(tile) \
						or _map.is_on_home_block(tile) or _map.is_in_walled_alley(tile, walled_alleys) \
						or _map.is_obstructed(tile) or not _reachable_from_home(tile):
					continue
				return world
	return Vector2.INF

## Where a step's contact — or, for an `EVENT`/`SCAR`-fallback perform step, the event it rides
## on — is sited. A pickup and an `EVENT` perform both name tile types in `placement`; `DOOR`,
## `PARK_SWING` and `STATION_DOOR` compute their own point from today's city, since none is a
## matter of picking a tile type.
func _place(step: ResistanceSteps.Step, rng: RandomNumberGenerator) -> Vector2:
	if step.target_kind == ResistanceSteps.TargetKind.STATION_DOOR:
		# The same pool the day's planning kept a route to (`target_ground()`), so the draw is
		# asked for reachability like every other pool and always finds some.
		return _pick_reachable(ResistanceSteps.target_candidates(step, _map, _region_plan()), rng,
				true)
	if step.target_kind == ResistanceSteps.TargetKind.DOOR:
		return _place_at_a_door(rng)
	if step.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		return _place_at_a_swing(rng)
	if step.target_kind == ResistanceSteps.TargetKind.MAST:
		return _place_at_a_mast(rng)
	var candidates: Array[Vector2i] = []
	if step.is_pickup:
		# A chalk mark goes on a through-alley only — see `_through_alley_tiles()`.
		candidates.append_array(_through_alley_tiles())
		return _pick_reachable(candidates, rng)
	for type in step.placement:
		candidates.append_array(_map.tiles_of_type(type as GameEnums.TileType))
	return _pick_reachable(candidates, rng)

## Where day 9's task points: one of today's region-wall doors — a `StreetNetwork.Segment` from
## `City.region_plan().doors` — at its own crossing tile, chosen the same reachable-among-
## candidates way `_pick_reachable()` already chooses a mark's alley. `Vector2.INF` if the city
## opened none, which does not happen on this task's own day: `Tuning.REGION_WALL_FIRST_DAY`
## equals the day this task is offered on. The pool is `ResistanceSteps.target_candidates()`,
## which leaves out any door on a street bordering the home block — see that function's own doc for
## why `allow_held` below would otherwise let one through.
func _place_at_a_door(rng: RandomNumberGenerator) -> Vector2:
	var candidates := ResistanceSteps.target_candidates(
			_step_of_kind(ResistanceSteps.TargetKind.DOOR), _map, _region_plan())
	if candidates.is_empty():
		return Vector2.INF
	# `allow_held` is not optional here, it is the whole placement: every remaining tile sits on
	# a segment `EventManager.start_day()` already held for the day (held so no catalogue row may
	# be sited on a door — see `CityMap.held_segments`), and this director runs after that. The
	# held filter would refuse the exact ground the task names: with it applied, every door
	# candidate read `held` and step 8 answered `Vector2.INF` in every run — "nowhere to go" — so
	# the crossing task never appeared at all. It does not reopen the home-block exemption: that
	# ground was filtered out of the pool, before `allow_held` ever gets a say.
	return _pick_reachable(candidates, rng, true)

## Where day 12's task points: the swing of the one park the city chose for it
## (`CityGenerator.swing_park()`), forced open today whatever its arc has reached
## (`CityState.purpose_of()`), at the same point `City._dress_block()` draws the swing frame at
## (`CityMap.swing_position()`). The pool is `ResistanceSteps.target_candidates()`, one tile, which
## the day's planning keeps reachable from home; `Vector2.INF` only on a day that park is not open,
## which on its own day is a city `CityGenerator.validate()` refused.
func _place_at_a_swing(rng: RandomNumberGenerator) -> Vector2:
	if not _map:
		return Vector2.INF
	return _pick_reachable(ResistanceSteps.target_candidates(
			_step_of_kind(ResistanceSteps.TargetKind.PARK_SWING), _map, null), rng)

## Where day 11's task points: beside the foot of one of today's live loudspeaker masts
## (`EventManager.mast_foot()`'s own point, the plan's position), drawn by the day's RNG among the
## masts she can reach, weighted toward the nearer ones (`_weighted_mast_index()`). `Vector2.INF`
## if today stands none, which from `Tuning.MAST_FIRST_DAY` on only a day whose holds took every
## site could do.
##
## **Reachable is asked of the ground beside the foot, not of the foot.** The pole is a body
## (`EventScheduler.blocked_by()` paints its disc over the foot's own tile), and she touches it
## from beside it the way she touches a chalk mark: `ContactPoint.REACH` (36px) is more than the
## pole's reach and her own body together, and a neighboring tile's centre is one tile (32px) from
## the foot. So a mast counts when one of the four tiles beside its foot is legal, unobstructed
## ground reachable from home — the same refusals every placement in this file keeps — and the
## contact stands on the first such tile, so it is on ground she can stand on like every other
## contact, a tile from the pole.
##
## **A mast already silenced is not offered again**, which only a run whose day 11 was replayed
## after a won attempt could meet; the draw is over the plans in the day's own order, so the same
## day draws the same mast every time.
func _place_at_a_mast(rng: RandomNumberGenerator) -> Vector2:
	_mast_id = ""
	if not _city or not _city.events:
		return Vector2.INF
	var walled_alleys := _walled_alleys()
	var offered: Array[EventScheduler.Planned] = []
	var beside: Array[Vector2i] = []
	for plan in _city.events.plans():
		if plan.mast_id == "" or plan.def.id != "loudspeaker" or plan.silenced \
				or not plan.is_placed():
			continue
		var foot := _map.world_to_tile(plan.position)
		if _map.is_closed(foot) or _map.is_on_home_block(foot):
			continue
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var tile := foot + side
			if is_legal_ground(_map, tile, walled_alleys) and not _map.is_obstructed(tile) \
					and _reachable_from_home(tile):
				offered.append(plan)
				beside.append(tile)
				break
	if offered.is_empty():
		return Vector2.INF
	var index := _weighted_mast_index(beside, rng)
	_mast_id = offered[index].mast_id
	return _map.tile_to_world(beside[index])

## The near mast's edge over the far one: index `i`'s weight is `1.0 / d^2`, `d` the straight-line
## distance from where she is when the task is placed (`_player_position()`, or the doorstep with
## no player in the tree, the shape every bare-director test in `tests/test_resistance.gd` builds)
## to `beside[i]`, the tile that draw would stand her on. Straight-line rather than a walked
## distance: `ReachabilityGrid` (`src/routes/reachability_grid.gd`) answers only whether a tile is
## reached, never how far, so there is no cheap walking distance on hand to weight by instead. `d`
## is floored at one tile (`Tuning.TILE_SIZE`, 32px) so a mast whose contact tile she already
## stands beside does not carry a near-infinite weight over every other. One `rng.randf()` call —
## the same single draw off the day's RNG `_kind_for()` in `poster_walls.gd` makes for a weighted
## pool — so the draw is still random and still exactly reproducible for the same seed and the same
## route: her position at the moment of the draw is itself determined by the route that got her
## there.
func _weighted_mast_index(beside: Array[Vector2i], rng: RandomNumberGenerator) -> int:
	var from := _player_position()
	if from == Vector2.INF:
		from = _map.doorstep_world_position()
	var weights: Array[float] = []
	var total := 0.0
	for tile in beside:
		var d := maxf(from.distance_to(_map.tile_to_world(tile)), float(Tuning.TILE_SIZE))
		var weight := 1.0 / (d * d)
		weights.append(weight)
		total += weight
	var pick := rng.randf() * total
	var chosen := 0
	for i in weights.size():
		chosen = i
		pick -= weights[i]
		if pick < 0.0:
			break
	return chosen

## Silences the mast day 11 sent her to, for the rest of the run: today through
## `EventManager.silence_mast()`, and every later day through the scar it leaves
## (`EventScheduler.SILENCED_MAST`), which `EventScheduler._place_masts()` reads before a mast's plan
## is ever made. A scar rather than a field of its own on `GameState` because it is exactly what a
## scar is — a permanent mark on the city left by what happened on an earlier day — and so it is
## saved, and given back with a lost day, by what already does both for the burnt shell.
func _silence_the_mast() -> void:
	if _mast_id == "" or not _city or not _city.events:
		return
	var foot := _city.events.mast_foot(_mast_id)
	_city.events.silence_mast(_mast_id)
	if foot != Vector2.INF:
		GameState.add_scar(EventScheduler.SILENCED_MAST, foot)
	Telemetry.note("contact", "mast %s is silenced for the rest of the run" % _mast_id)

## How far from where she touched the mark the neighbor has to start, at least: off screen, so they
## walk into view rather than appear in it — the same distance an unseen mark is kept at.
const NEIGHBOR_CLEAR_OF_HER := NOTICE_RADIUS
## How far either side of the walk `Tuning.NEIGHBOR_WALK_HOME_SECONDS` asks for a start may be, in
## tiles of walk: the band a draw is made from, rather than the one ring of tiles at exactly that
## distance, which a closure or a park can leave empty.
const NEIGHBOR_WALK_BAND_TILES := 8

## Day 10's neighbor, out in the city and walking home: spawned on a sidewalk about
## `Tuning.NEIGHBOR_WALK_HOME_SECONDS` of their own walk from her door, off screen from her, and
## given the walk itself as a path — down the day's own walking distance to the doorstep, over
## ground the day's closures and bodies leave open (`_reach_blocked`, the director's own
## reachability answer), on sidewalks and crossings where they reach and over any walkable ground
## where they do not. **The walk is the deadline**: `EventCatalogue.neighbor_heading_home()` stops
## at the door (`stops_where_it_arrives`), and `_process()` reads a parked neighbor as the task
## lost. Null when no start qualifies, which leaves the task with nowhere to go.
##
## The start is drawn by the day's RNG from the band of tiles `NEIGHBOR_WALK_BAND_TILES` either side
## of the walk asked for, in `tiles_of_type()`'s own order, so the same day draws the same start.
func _send_the_neighbor_home() -> EventInstance:
	if not _city or not _city.events:
		return null
	var def := EventCatalogue.neighbor_heading_home()
	var door := _map.world_to_tile(_map.doorstep_world_position())
	_ensure_reachability()
	var on_foot := _reach_blocked.duplicate()
	for tile in _map.tiles_of_type(GameEnums.TileType.ROAD):
		on_foot[tile] = true
	var wanted := roundi(Tuning.NEIGHBOR_WALK_HOME_SECONDS * def.speed / Tuning.TILE_SIZE)
	for blocked: Dictionary in [on_foot, _reach_blocked]:
		var field := _map.walk_field(door, blocked)
		var start := _a_neighbor_start(field, wanted)
		if start == _NO_TILE:
			continue
		var path := _walk_home(field, start)
		Telemetry.note("contact", "the neighbor is %d tiles of walk from home at %s"
				% [_map.distance_at(field, start), TelemetryLog.tile(start)])
		return _city.events.spawn_extra(def, path[0], path)
	return null

## A sidewalk tile whose walk home is within `NEIGHBOR_WALK_BAND_TILES` of `wanted`, off screen
## from her and on ground a contact may stand on, drawn by the day's RNG — or `_NO_TILE`.
func _a_neighbor_start(field: PackedInt32Array, wanted: int) -> Vector2i:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Stroller if is_inside_tree() \
				else null
	var her := _player.global_position if _player else Vector2.INF
	var walled_alleys := _walled_alleys()
	var offered: Array[Vector2i] = []
	for tile in _map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		var walk := _map.distance_at(field, tile)
		if walk < 0 or absi(walk - wanted) > NEIGHBOR_WALK_BAND_TILES:
			continue
		if her != Vector2.INF and _map.tile_to_world(tile).distance_to(her) < NEIGHBOR_CLEAR_OF_HER:
			continue
		if not is_legal_ground(_map, tile, walled_alleys) or _map.is_obstructed(tile):
			continue
		offered.append(tile)
	if offered.is_empty():
		return _NO_TILE
	return offered[_rng.randi_range(0, offered.size() - 1)]

## The walk from `start` down `field` to the doorstep, as the corners of it: each step goes to a
## neighbor one tile nearer home, keeping the heading it already has where that is one of them, so
## a walk is long straight runs down a sidewalk rather than a staircase. Ends on the doorstep's own
## point, where she starts and finishes her day.
func _walk_home(field: PackedInt32Array, start: Vector2i) -> PackedVector2Array:
	var corners := PackedVector2Array([_map.tile_to_world(start)])
	var at := start
	var heading := Vector2i.ZERO
	var steps: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	while _map.distance_at(field, at) > 0:
		var here := _map.distance_at(field, at)
		var next := heading
		if heading == Vector2i.ZERO or _map.distance_at(field, at + heading) != here - 1:
			next = Vector2i.ZERO
			for step in steps:
				if _map.distance_at(field, at + step) == here - 1:
					next = step
					break
		if next == Vector2i.ZERO:
			break
		if next != heading and heading != Vector2i.ZERO:
			corners.append(_map.tile_to_world(at))
		heading = next
		at += next
	corners.append(_map.doorstep_world_position())
	return corners

## Takes the neighbor she did not reach away with the raid, once she cannot see them — they walked
## home into the vans, and a figure that vanished in front of her would say something else.
func _take_the_neighbor_away() -> void:
	if not _taken_neighbor or not is_instance_valid(_taken_neighbor):
		_taken_neighbor = null
		return
	if _sight.is_valid() and _sight.call(_taken_neighbor.global_position):
		return
	_city.events.retire(_taken_neighbor)
	_taken_neighbor = null
	Telemetry.note("contact", "the neighbor is taken with the raid")

## The calendar's one step that places its contact `kind`'s way — `DOOR` or `PARK_SWING` — so the
## two placements above read their pool through `ResistanceSteps.target_candidates()`, the function
## the day's planning reads it through, rather than a copy of it. Null if the calendar has none.
static func _step_of_kind(kind: ResistanceSteps.TargetKind) -> ResistanceSteps.Step:
	for step in ResistanceSteps.all():
		if step.target_kind == kind:
			return step
	return null

## Today's region plan, or null for the bare-map rigs several tests in `tests/test_resistance.gd`
## build with no `_city` — the same null `_walled_alleys()` reads as "nothing walled today".
func _region_plan() -> RegionPlanner.RegionPlan:
	return _city.region_plan() if _city else null

## The day's narrow resistance target as the day's planning protects it: the tiles of day 9's door,
## day 12's swing or the power station's front door (`ResistanceSteps.target_candidates()`) that
## pass every
## refusal this director makes of a tile before it draws (`is_legal_ground()`), empty on every other
## day. `EventManager.start_day()` hands it to `EventScheduler.build_day()`, which keeps a route from
## home to one of these tiles among the day's own bodies — so the tile `_pick_reachable()` then
## draws, asked for reachability like every other pool, is always found. Asked once the day's holds
## are all on the map and before any body is, which is why `is_obstructed()` is not part of it:
## the scheduler's own discs stand in for the bodies, the same discs `_reachable_from_home()` asks.
static func target_ground(map: CityMap, day: int,
		region_plan: RegionPlanner.RegionPlan) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var step := ResistanceSteps.narrow_target_on(day)
	if not step:
		return found
	var walled: Array[Rect2i] = region_plan.alley_walls if region_plan else []
	var allow_held := ResistanceSteps.stands_on_held_ground(step)
	for tile in ResistanceSteps.target_candidates(step, map, region_plan):
		if is_legal_ground(map, tile, walled, allow_held):
			found.append(tile)
	return found

## The refusals `_pick_reachable()` makes of a candidate tile before it draws — walkable, not
## behind a closure, not on held ground unless `allow_held`, not on the home block's own lot, not in
## a walled-off crossing alley. Each is its own paragraph in `_pick_reachable()`'s doc. Static and
## shared with `target_ground()`, so the tiles the day's planning protects are exactly the ones the
## draw may land on.
static func is_legal_ground(map: CityMap, tile: Vector2i, walled_alleys: Array[Rect2i],
		allow_held := false) -> bool:
	return map.is_walkable(tile) and not map.is_closed(tile) \
			and (allow_held or not map.is_held_at(tile)) \
			and not map.is_on_home_block(tile) and not map.is_in_walled_alley(tile, walled_alleys)

## A contact behind a closed street is a step the player cannot take today, and the
## resistance has steps that expire — so this would silently cost a run its good ending.
##
## **Never on the home block's own ground, either.** Playtest 11's finding — "events/hazards
## should not spawn on the home block" — was built as one exempt street and reopened once an
## alley through the block (now impossible, `CityGenerator._build_block`) turned out to be the
## other half of it; `is_held_at` refuses a segment bordering the block, `is_on_home_block`
## refuses anything inside it. See `docs/DECISIONS.md`, M100, "Nothing on the home block".
##
## **Never inside a walled-off crossing alley, either.** PLAYTEST-57: "a blocked off alley must
## not have a chalk mark." An alley never sits on a `StreetNetwork` segment, so `is_held_at`
## cannot see one however its mouths stand, and a region wall is not a `RoadClosure`, so
## `is_closed` cannot either — `CityMap.is_in_walled_alley` is the refusal built for exactly this
## ground. See `docs/DECISIONS.md`, M100, "A blocked-off alley has no chalk mark".
##
## **Never on ground that is not actually walkable, either.** A guard against `DOOR` and
## `PARK_SWING` candidates, which are not drawn from `CityMap.tiles_of_type()` the way every
## other candidate here is and so are not walkable by construction of the query — a redundant
## check for a mark or an ordinary perform step's own tile types, and the one that matters for
## the two new placement kinds.
##
## **Never inside a solid event body, either — but checked after the draw, not folded into the
## pool.** `CityMap.is_obstructed()` is the day's own record of where a café's tables, a
## construction band, a kerbed van or any other stationary body stands, filled by
## `EventManager.start_day()` from the whole day's plan before this director ever runs — an open,
## walkable tile can still have a body parked on it, which `is_walkable()` has no way to see.
## **Filtering it into the pool before the draw would move a placement that was never
## obstructed**: the draw below is one uniform pick over the whole pool, so removing even one
## unrelated candidate shifts which index every other candidate answers to. Checking the single
## tile the draw actually lands on instead — and only then drawing again — is what keeps a valid
## placement exactly where it was and touches only the one a real body actually stands on.
##
## **Never sealed off from home by the day's whole obstruction, either — checked the same
## after-the-draw way as `is_obstructed()`, for the same reason.** A tile can be open, unheld,
## unwalled ground and still have every route to it closed by the union of today's events and
## seals, which none of the five pool refusals or `is_obstructed()` can see — each asks about the
## tile itself, not the streets between it and the doorstep. See `_reachable_from_home()`.
##
## **Two kinds of pool, and the check means something different in each.** A mark's alleys and a
## rider's sidewalks are hundreds of tiles across the whole city; the day's obstruction seals off
## some of them and never plausibly all, so for them the check is a filter. Day 9's door, day 12's
## swing and the station's front door are a handful of tiles in one place, which the day's own seals
## and bodies could ring entirely — so the day is planned to keep a route to one of them
## (`target_ground()`; `docs/CITY.md`, "Guarantees"), and for them the check finds the tile the
## planning kept rather than hoping one survived.
##
## **Avoids a tile a completed step already used, unless nothing else reachable is left (M177).**
## Landing a fresh mark back on the very alley an earlier step's mark stood at reads as the game
## reusing its own prop rather than "any alley she comes across" — but the avoidance never costs
## the placement guarantee itself: a candidate list whose only reachable tile happens to be a used
## one still returns it rather than `Vector2.INF`. `GameState.completed_resistance_alley_tiles`
## only ever holds `ALLEY` tiles (see `_on_contact_completed()`), so this filter is a silent no-op
## against every other kind of placement, none of which is ever an alley.
##
## **`allow_held` skips only the `is_held_at` refusal, and only the two door placements pass it**
## (`ResistanceSteps.stands_on_held_ground()`). Held ground means *no hazard or catalogue row may be
## sited here*; a contact is neither, and for a step whose candidates are the held region-door
## segments themselves (`_place_at_a_door()`), or the station's front door on a street the spur
## made a region door, the filter would refuse the very ground the task points at.
## The other refusals stand even then: a door on closed, unwalkable, obstructed or home-block-lot
## walled-alley ground is still a door she cannot cross today.
##
## **Not exempted: a door on a street bordering the home block.** `is_on_home_block` only refuses
## a tile inside the home block's own lot (its own doc says so); the streets around the block are
## the other half of "nothing on the home block", and normally that half is exactly what
## `is_held_at` catches — which `allow_held` would otherwise skip for a door candidate too.
## `ResistanceSteps.target_candidates()` drops those candidates from the door pool, before any
## candidate reaches this function, so `allow_held` never has to carry that exemption.
func _pick_reachable(candidates: Array[Vector2i], rng: RandomNumberGenerator,
		allow_held := false) -> Vector2:
	var walled_alleys := _walled_alleys()
	var reachable: Array[Vector2i] = []
	var unused: Array[Vector2i] = []
	for tile in candidates:
		if not is_legal_ground(_map, tile, walled_alleys, allow_held):
			continue
		reachable.append(tile)
		if tile not in GameState.completed_resistance_alley_tiles:
			unused.append(tile)
	var pool := unused if not unused.is_empty() else reachable
	if pool.is_empty():
		return Vector2.INF
	# One uniform draw over the whole pool, exactly as before `is_obstructed()` (or reachability)
	# was ever checked — so a pool with nothing obstructed or sealed off in it draws the same index
	# it always has. Only a drawn tile a real body actually stands on, or that the day's whole
	# obstruction seals off from home, is rejected and redrawn, up to `PICK_REACHABLE_REDRAW_LIMIT`
	# times, the nearest still-legal tile in the pool standing in if every redraw lands on another
	# one (`_nearest_legal_in_pool()`'s own doc).
	var drawn := pool[rng.randi_range(0, pool.size() - 1)]
	if not _map.is_obstructed(drawn) and _reachable_from_home(drawn):
		return _map.tile_to_world(drawn)
	for _attempt in PICK_REACHABLE_REDRAW_LIMIT:
		drawn = pool[rng.randi_range(0, pool.size() - 1)]
		if not _map.is_obstructed(drawn) and _reachable_from_home(drawn):
			return _map.tile_to_world(drawn)
	var nearest := _nearest_legal_in_pool(pool, drawn)
	return _map.tile_to_world(nearest) if nearest != _NO_TILE else Vector2.INF

## The pool's own nearest tile to `from` that is neither `CityMap.is_obstructed()` nor sealed off
## from home (`_reachable_from_home()`) — the fallback once `PICK_REACHABLE_REDRAW_LIMIT` redraws
## all landed on one or the other, which only ever happens on a pool where that is common: a narrow
## target whose planning kept a route to only a few of its tiles. `_NO_TILE` if every tile in
## `pool` fails, which `_pick_reachable` then reads the same way it reads an empty pool: nowhere to
## go today.
func _nearest_legal_in_pool(pool: Array[Vector2i], from: Vector2i) -> Vector2i:
	var nearest := _NO_TILE
	var nearest_distance := INF
	for tile in pool:
		if _map.is_obstructed(tile) or not _reachable_from_home(tile):
			continue
		var distance: float = (tile - from).length_squared()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = tile
	return nearest

## Today's crossing alleys that are wall rather than door — see `CityMap.is_in_walled_alley`.
## Read from the city's own region plan rather than tracked here, so a director never disagrees
## with whatever wall `EventManager` actually built bodies for; empty before `Tuning.
## REGION_WALL_FIRST_DAY`, and for the bare-map rigs (`_city == null`) several tests in
## `tests/test_resistance.gd` build, which never wall anything.
func _walled_alleys() -> Array[Rect2i]:
	var region_plan: RegionPlanner.RegionPlan = _city.region_plan() if _city else null
	if not region_plan:
		return []
	return region_plan.alley_walls

## Builds `_reach_grid`/`_reach_blocked`/`_reach_reached` the first time a placement in this file
## asks whether a tile is reachable, and never again this day. `_reach_grid` alone is the sentinel:
## a fresh `RandomNumberGenerator`-style build-once-per-day, not a per-call cost.
##
## **`EventScheduler.blocked_by()`, asked the same way `_ensure_the_city_is_still_walkable()` asks
## it** — every placed plan whose `obstructs_radius > 0.0` or `hard_fail` is true contributes its
## own disc, on top of `_map.closed_tiles` — so this director's answer to "can she get there" is
## never a second implementation of the city's own, only a second question put to it: that
## function asks whether *some* calm area, and on a narrow target's day *some* tile of the target,
## is still reachable, and drops the widest of the catalogue's obstructions until they are
## (`docs/CITY.md`, "Guarantees"); this asks whether *one specific tile* is, and never drops
## anything — a candidate that fails is redrawn, the same "reject rather than repair" rule
## `_pick_reachable()` already keeps for `is_obstructed()`. The blockers are the same list both
## times: the catalogue's own bodies, the seals and the region wall's, never a region door's.
##
## **Without a `_city` (the bare-map rigs several tests in this file build)**, `_reach_blocked` is
## built from an empty blocker list — today's closures alone, which is `{}` for the same rigs since
## nothing ever calls `City.start_day()` on them either — so every walkable tile answers reachable
## and this check is a silent no-op, exactly like `_walled_alleys()` above it.
func _ensure_reachability() -> void:
	if _reach_grid:
		return
	_reach_grid = ReachabilityGrid.build(_map)
	var blockers: Array[EventScheduler.Planned] = []
	if _city and _city.events:
		# A region door's own bodies are never a block — `event_scheduler.gd`'s own corridor-cost
		# rule already carries this exemption ("a region door costs by design ... `checkpoint_hut`
		# and `checkpoint_gate` are never a block. The region wall's own body is not a door and
		# still counts") and this check needs the same one, for the same reason. Found while
		# building this item: with every door body counted, `blocked_by()`'s disc approximation —
		# right for a point hazard, wrong for a hut-gate-hut door three tiles wide — closed every
		# door in the wall along with it, so day 9 onward answered every mark and contact
		# unreachable outside the home's own region, on a seed the real game's own route rig
		# crosses those same doors on. `region_plan.door_bodies` is exactly the set the wall
		# building code itself keeps apart from `wall_bodies` for this reason; excluded by identity
		# rather than by matching `def.id`, so a new door-body row never needs a second list here.
		var door_bodies: Array[EventScheduler.Planned] = []
		var region_plan: RegionPlanner.RegionPlan = _city.region_plan()
		if region_plan:
			door_bodies = region_plan.door_bodies
		for plan in _city.events.plans():
			if not plan.is_placed() or plan in door_bodies:
				continue
			if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
				blockers.append(plan)
	_reach_blocked = EventScheduler.blocked_by(_map, blockers)
	_reach_reached = _reach_grid.flood([_map.home_rect.position], _reach_blocked)

## Whether `tile` is reachable from home under the day's full obstruction, as it stands right now:
## closures alone can leave a mark's own alley reachable while the day's events and seals together
## seal every route to it. `docs/CITY.md`'s guarantees promise a route to a calm area and to one
## tile of the day's narrow resistance target (`target_ground()`), never to any one alley or
## sidewalk, so this is asked of every draw. See `_ensure_reachability()`.
func _reachable_from_home(tile: Vector2i) -> bool:
	_ensure_reachability()
	return _reach_grid.reaches(tile, _reach_blocked, _reach_reached)

func _process(delta: float) -> void:
	_happenings.tick(delta, _player_position(), _player_velocity(), _sight)
	if _taken_neighbor:
		_take_the_neighbor_away()
	if _lingering_rider:
		_tick_lingering_rider(delta)
	if not _step or _expired or not _contact or _contact.is_done:
		return
	_elapsed += delta
	if _rider and not _contact.rider_alive():
		_expire("lost its contact when the thing it rode on finished")
		return
	# Day 10's deadline: the neighbor reached the door before she reached them.
	if _rider and _rider.is_parked and _step.target_kind == ResistanceSteps.TargetKind.NEIGHBOR:
		_taken_neighbor = _rider
		_expire("expired: the neighbor walked home into the vans")
		return
	# A pickup is the only step subject to the re-placement rule; a one-place perform step is
	# never subject to it (its rider or its point is fixed for the day), and an any-instance
	# perform step follows her between look-alikes instead.
	if _step.is_pickup:
		_track_sight_and_reposition(delta)
	elif _rider and not _step.is_one_place:
		_follow_her_between_look_alikes()
	if _step.deadline_fraction <= 0.0 or _day_length <= 0.0:
		return
	if _elapsed / _day_length < _step.deadline_fraction:
		return
	_expire("expired at %.0f%% of the day" % (_step.deadline_fraction * 100.0))

## Counts down `_lingering_rider`'s stay and calls `EventInstance.leave_for_a_completed_task()`
## once `NOTE_HANDOVER_LINGER_SECONDS` is up — run every frame independently of `_step`/`_contact`,
## since the note task is already complete and cleared by the time this fires. Freed or otherwise
## finished early (the day ending under her) clears the wait rather than erroring on a dead
## instance; nothing else needs telling, since a day that has ended has nothing left to charge.
func _tick_lingering_rider(delta: float) -> void:
	if not is_instance_valid(_lingering_rider) or _lingering_rider.is_finished:
		_lingering_rider = null
		return
	_lingering_remaining -= delta
	if _lingering_remaining > 0.0:
		return
	_lingering_rider.leave_for_a_completed_task()
	Telemetry.note("contact", "he stops shouting and leaves")
	_lingering_rider = null

## *Asked for a hidden contact among look-alikes · overturned on 2026-09-13* (`docs/NARRATIVE.md`,
## "The any-instance contact is whichever look-alike the player hands the note to"): *"not the
## first yeller she reaches but the first yeller she interacts with. so the task is always solved
## by going to any yeller she notices."* An any-instance perform step's contact is not pinned to
## whichever instance `_begin_step()` happened to spawn — it rides onto whichever live instance
## sharing the step's own `task_event_id` she is nearest within reach of, seeded rider included,
## and follows her from one look-alike to the next: coming near one and walking on is not a
## choice, and the one she hands it to — the contact she actually touches — is the one that
## completes the step. A one-place step (`Step.is_one_place`) never runs this: its rider is the
## task.
##
## **Nothing guards the seeded rider, so nothing is lost by leaving it.** Such a task's trap comes
## to her at the handover from wherever it happens (`sets_a_trap_on_her()`), and `_process()`'s
## own deadline check reads `_elapsed` against `_day_length` — neither reads `_rider`'s identity,
## so retargeting onto a different look-alike changes nothing about either rule.
##
## Skipped while the nearest look-alike in reach is already the one it rides (`best == _rider`):
## the seeded rider's own fixed, replay-stable offset from `_reachable_offset()`, or the near-side
## offset a retarget gave, already has `ContactPoint`'s own distance check covered.
func _follow_her_between_look_alikes() -> void:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Stroller
	if not _player or not _city or not _city.events:
		return
	var here := _player.global_position
	var best: EventInstance = null
	var best_distance := INF
	for instance in _city.events.instances():
		if instance.def.id != _step.task_event_id or instance.is_finished:
			continue
		var distance := here.distance_to(instance.global_position)
		if distance > _reach_distance(instance) or distance >= best_distance:
			continue
		best_distance = distance
		best = instance
	if best == null or best == _rider:
		return
	_rider = best
	_contact.ride(_step, best, _near_side_offset(best, here))
	Telemetry.note("contact", "step %d retargeted onto the nearest look-alike in reach"
			% _step.index)

## The distance from `instance`'s own centre at which `ContactPoint.REACH` is actually reachable —
## the same sum `_reachable_offset()` places its fixed point at, asked here of an arbitrary
## look-alike rather than only the seeded rider, so a solid body's own clearance is respected
## whichever candidate this is asked about.
func _reach_distance(instance: EventInstance) -> float:
	return instance.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH

## The touch point on the side of `instance` facing `from` — used only when retargeting onto a
## look-alike she is already within reach of, where a fixed randomly-bearing offset (what the
## seeded rider keeps, for replay stability across an untouched day) would be the wrong question:
## nothing about this pairing needs to replay the same way twice, since it only ever happens once
## she is already standing close enough. Placing the offset toward her own current bearing instead
## is what makes the distance check in `_follow_her_between_look_alikes()` exactly correct for a
## body with any solid clearance, by the same triangle the caller already checked when it found
## this candidate.
func _near_side_offset(instance: EventInstance, from: Vector2) -> Vector2:
	var clearance: float = instance.def.obstructs_radius
	if clearance <= 0.0:
		return Vector2.ZERO
	var to_her := from - instance.global_position
	if to_her.length() < 0.001:
		to_her = Vector2.RIGHT
	return to_her.normalized() * (clearance + Tuning.PLAYER_BODY_RADIUS)

## "A mark that was never on screen was never placed" — playtest 19, verbatim, still the rule for
## what keeps a mark moving. **What changed (M177, playtest 116) is what counts as having actually
## seen it.** The old rule pinned a mark the first frame its position was inside the view — which
## also pinned it fifteen tiles from where she stood the moment its tile swept past the camera on
## the way to somewhere else, since "inside the view" says nothing about whether she was close
## enough to read it. Now it also has to be within `SEEN_DISTANCE` of her, continuously, for
## `SEEN_DWELL_SECONDS` — near enough, for long enough, that walking past it rather than to it is
## a choice. Seen is still sticky once reached: it never moves again that day, however far she
## walks from it afterwards.
##
## While unseen, walking away from it is corrected rather than left standing where she can
## no longer find it: if she is further than `NOTICE_RADIUS` from the mark and a reachable
## alley tile is within `NOTICE_RADIUS` of her, the mark jumps to the nearest eligible one — the
## alley's own mouth, which is "on the path where the player can see it". Staying within the
## mark's own radius does nothing, which is the hysteresis that stops it chasing her step by
## step.
func _track_sight_and_reposition(delta: float) -> void:
	if _seen:
		return
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Stroller
	var at := _contact.global_position
	var noticing: bool = _player != null \
			and _player.global_position.distance_to(at) <= SEEN_DISTANCE \
			and _sight.is_valid() and _sight.call(at)
	if noticing:
		_seen_dwell += delta
		if _seen_dwell >= SEEN_DWELL_SECONDS:
			_seen = true
			if _step.is_pickup:
				# `VisitCounter`'s own "mark-seen" — a perform step's own contact runs through this
				# same tracking and never fires it, since the counter asks about the chalk mark, not
				# about whatever the task rides on. See docs/TELEMETRY.md, "The page counts visits".
				EventBus.resistance_mark_seen.emit(_step.index)
			Telemetry.note("contact", "step %d seen at %s after %.1fs within %.0fpx" % [
				_step.index, TelemetryLog.tile(_map.world_to_tile(at)),
				SEEN_DWELL_SECONDS, SEEN_DISTANCE])
		return
	# Broke either condition this frame — on screen but too far, close but not on screen, or
	# simply not there yet — so the dwell starts over rather than merely pausing. A player who
	# walks up, glances off and away, then wanders back later has not been looking at it the
	# whole time in between.
	_seen_dwell = 0.0
	if not _player:
		return
	# A robber already awake and coming for her cannot lose his mark out from under him.
	# Unreachable given the geometry above — he only wakes within `pursues_within` (140px) of
	# the mark, and the mark only moves once she is beyond `NOTICE_RADIUS` (400px) of it, and
	# 400 > 140 — but checked here rather than assumed, because a defect in that geometry
	# would otherwise show up as a robber frozen over empty ground rather than as a test
	# failure.
	if _guard and is_instance_valid(_guard) and not _guard.is_waiting():
		return
	var here := _player.global_position
	if here.distance_to(at) <= NOTICE_RADIUS:
		return
	var nearest := _nearest_alley_within(here)
	if nearest == Vector2.INF:
		return
	_move_the_mark(nearest)

## The nearest through-alley tile (`_through_alley_tiles()`) to `here` that is not closed, is
## walkable, and is not held, on the home block, inside a walled-off crossing alley, standing on a
## solid event body, or sealed off from home by the day's whole obstruction (see
## `_pick_reachable`'s own doc — the relocation is the same placement question as the initial
## roll, asked again, and the same refusal has to hold or a mark could relocate into a sealed
## alley, a building or a pocket nothing can walk out of even though it is never placed there to
## start with), within `NOTICE_RADIUS` — or `Vector2.INF` if there is none. Linear over
## `_through_alley_tiles()`, built once per map; there is one active mark at a time, so this runs
## once a frame at most.
##
## **`is_obstructed()` was missing here even after M188 added it to `_pick_reachable()` and
## `_reachable_offset()`.** A `--day 9 --seed 4242 --route mark,task,calm,home --no-title` boot of
## the real game still stood day 9's mark inside a building: the dawn draw itself landed on legal
## ground at (108,67), but she starts at the doorstep, more than `NOTICE_RADIUS` from it, so
## `_track_sight_and_reposition()` relocated it on the very first frame — straight to (79,90), an
## obstructed tile this function had no refusal for. The dawn roll was never the bug on this seed;
## the relocation search silently undid it one frame later.
##
## **And `_reachable_from_home()` was still missing after that fix.** The same boot, rerun once
## `is_obstructed()` was added here, relocated the mark to (79,91) instead — open, unheld,
## unobstructed ground one tile over, and still sealed off from home by the day's own events and
## parked vehicles (M188, item 3). The relocation search draws from the same `ALLEY` pool the dawn
## roll does, so it needed the same seventh refusal.
##
## **Avoids a tile a completed step already used, the same rule and the same fallback
## `_pick_reachable()` applies to the dawn placement (M177):** the nearest eligible tile that is
## not in `GameState.completed_resistance_alley_tiles`, or the plain nearest eligible tile if
## avoiding them would leave nothing in reach at all — a relocation exists to keep the mark
## findable, and that guarantee outranks the avoidance.
##
## **Never a tile any part of the mark's own picture would show on, nor one whose guard would
## show** (brisk-wombat, "the mark and its robber never appear in front of her" — *"I just had one
## appear out of nowhere while I was walking through an alley and then a robber also appeared out
## of nowhere and instakilled me"*): the nearest reachable alley to `here` is, by construction,
## wherever she is standing or just beside it, which is on screen more often than not. The mark's
## picture is asked with its own size (`_mark_shows()`), and the far end of its alley, where
## `_move_the_mark()` stands the guard or which it falls back to, with his (`_guard_shows()`), so a
## relocation never lands where its guard could only be placed in view or not at all. Both are
## asked only of a tile nearer than the best found so far, which keeps this cheap enough for every
## frame.
func _nearest_alley_within(here: Vector2) -> Vector2:
	var walled_alleys := _walled_alleys()
	var used := GameState.completed_resistance_alley_tiles
	var nearest := Vector2.INF
	var nearest_distance := NOTICE_RADIUS
	var nearest_any := Vector2.INF
	var nearest_any_distance := NOTICE_RADIUS
	for tile in _through_alley_tiles():
		var world := _map.tile_to_world(tile)
		var distance := here.distance_to(world)
		var unused := tile not in used
		# Nothing to gain: no nearer than the nearest tile at all, and either used or no nearer
		# than the nearest unused one (`nearest_any_distance` is never above `nearest_distance`).
		if distance >= nearest_any_distance and (not unused or distance >= nearest_distance):
			continue
		if _map.is_closed(tile) or not _map.is_walkable(tile) \
				or _map.is_held_at(tile) or _map.is_on_home_block(tile) \
				or _map.is_in_walled_alley(tile, walled_alleys) or _map.is_obstructed(tile) \
				or not _reachable_from_home(tile):
			continue
		if _mark_shows(world) or _guard_shows(_far_alley_mouth(world)):
			continue
		if distance < nearest_any_distance:
			nearest_any_distance = distance
			nearest_any = world
		if not unused or distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest = world
	return nearest if nearest != Vector2.INF else nearest_any

## Moves an unseen mark to the alley she has just come near, and moves its guard with it —
## `_maybe_set_a_trap()` retires the one standing over the old spot itself rather than leaving a
## robber with nothing left to guard.
func _move_the_mark(new_world: Vector2) -> void:
	var old_tile := _map.world_to_tile(_contact.global_position)
	var new_tile := _map.world_to_tile(new_world)
	_contact.global_position = new_world
	Telemetry.note("contact", "step %d moved to %s: never seen at %s" % [
		_step.index, TelemetryLog.tile(new_tile), TelemetryLog.tile(old_tile)])
	_maybe_set_a_trap(_day, _rng, new_world, true, _player_position(), true)

## A warning delivered late is not a warning. The contact is gone for the rest of the run.
func _expire(message: String) -> void:
	_expired = true
	Telemetry.note("contact", "step %d %s; the contact is gone" % [_step.index, message])
	GameState.fail_resistance_step(_step.index)
	_clear()

## Records the step, and — for a mark — activates today's task right away, in the same
## `start_day()`'s RNG and guard state rather than waiting for tomorrow's dawn.
func _on_contact_completed(step_index: int) -> void:
	Telemetry.note("contact", "step %d completed" % step_index)
	var step := ResistanceSteps.by_index(step_index)
	GameState.complete_resistance_step(step_index, step == null or step.grants_progress)
	# Only a pickup's mark ever stands on an `ALLEY` tile — every other kind of contact sits on
	# a rider or a computed point — so this is the one completion worth recording for
	# `_pick_reachable()`/`_nearest_alley_within()` to avoid reusing later (M177).
	if step and step.is_pickup and _contact:
		GameState.record_completed_alley_tile(_map.world_to_tile(_contact.global_position))
	if step and step.is_pickup:
		# The task is announced at the mark and nowhere else: `GameState.complete_resistance_
		# step()` above already emitted `resistance_step_completed`, which is what `Hud` reads
		# to flash the mark's own words — see `Hud._on_resistance_step_completed()`. Activating
		# the perform half here, rather than waiting for a `start_day()` that will not come
		# until tomorrow, is what makes the task the same day as the mark.
		_begin_step(ResistanceSteps.by_index(step_index + 1))
		return
	if step and step.applies_package_weight:
		GameState.resistance_carrying_package = true
		Telemetry.note("contact", "the package is heavier now; the rest of today costs more")
	# A finished task is shown by the world, never by text: the man shouting she actually handed
	# it to — `_rider` after any retargeting in `_follow_her_between_look_alikes()` — stops
	# shouting and walks off screen, the same departure any finished event takes. Named by
	# `task_event_id` rather than "any rider with a completed step", so this call site does not
	# start silently giving the other perform steps a world-answer their own design has not chosen
	# yet.
	#
	# He does not leave the instant she hands it over: he stays and keeps shouting for
	# `NOTE_HANDOVER_LINGER_SECONDS` first, still charging her exactly as any live
	# `homeless_yeller` does, so walking away from him afterward costs (M205, "he keeps shouting
	# for a bit"). `_tick_lingering_rider()` actually calls `leave_for_a_completed_task()` once
	# the delay is up.
	if step and step.task_event_id == "homeless_yeller" and _rider and is_instance_valid(_rider):
		_lingering_rider = _rider
		_lingering_remaining = NOTE_HANDOVER_LINGER_SECONDS
		Telemetry.note("contact", "he took it; keeps shouting for %.1fs before he leaves"
				% NOTE_HANDOVER_LINGER_SECONDS)
	# Warned, the neighbor runs — away from her, and away from home.
	if step and step.target_kind == ResistanceSteps.TargetKind.NEIGHBOR and _rider \
			and is_instance_valid(_rider):
		_rider.leave_for_a_completed_task()
		Telemetry.note("contact", "the neighbor is warned and runs")
	# The mast she reached goes quiet where she stands: its lamp goes out and its arcs stop, which
	# is the world answering, and it stays quiet for the rest of the run.
	if step and step.target_kind == ResistanceSteps.TargetKind.MAST:
		_silence_the_mast()
	# Day 12's once-only happening: the park she was sent to starts to close the instant she has
	# reached the swing, and stays taken — see `ResistanceHappenings.take_the_park()`.
	if step and step.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		_happenings.take_the_park()
	# The man shouting and the van send a pursuer after her from off screen; every other task
	# that rides on a row keeps its guard waiting at the contact instead (`_begin_step()`).
	if step and sets_a_trap_on_her(step):
		_set_the_trap_on_her(step)
	if not (step and step.needs_goal):
		return

	GameState.sabotage_done = true
	# Nothing goes off here. The hand-over takes the man on the night shift minutes, so the city
	# goes dark once she has walked far enough from the station — every window, every light and
	# every mast at once, the masts because they run on the same power. That is `Blackout`'s, and
	# it watches the flag set above rather than this call.

func _clear() -> void:
	if _contact and is_instance_valid(_contact):
		_contact.queue_free()
	_contact = null
	_rider = null
	_mast_id = ""
	_lingering_rider = null
	_lingering_remaining = 0.0

# ------------------------------------------------------------------ queries ---

## Her velocity, or zero with no player in the tree. Read after `_player_position()`, which finds
## her.
func _player_velocity() -> Vector2:
	return _player.velocity if _player and is_instance_valid(_player) else Vector2.ZERO

## Where she is, or `Vector2.INF` with no player in the tree — a rig's bare director.
func _player_position() -> Vector2:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Stroller if is_inside_tree() \
				else null
	return _player.global_position if _player else Vector2.INF

## The step on offer today, or null.
func current_step() -> ResistanceSteps.Step:
	return _step if _contact and not _expired else null

func contact_position() -> Vector2:
	return _contact.global_position if _contact else Vector2.INF

## Where a protester should point, or `Vector2.INF` when there is nothing to point at: no step
## today, or today's step is a chalk-mark pickup. *(2026-09-11, the player: "the mark is
## findable now -- I don't think we need pointing for that. but the other tasks are not as easy
## and need pointing.")* A perform step's own contact already sits at the task, so this is
## `contact_position()` read back, never a placement or a move of its own.
func pointable_objective() -> Vector2:
	var step := current_step()
	if step == null or step.is_pickup:
		return Vector2.INF
	return contact_position()

## Where the red arrow should point, or `Vector2.INF` when nothing warrants one: no step today,
## today's step is the mark rather than the task, or the task is one any instance answers (the
## man shouting, a roadblock) — the two tasks that never earn an arrow. The last night's front
## door is one place and has it from dawn, since the finale has no mark. *(PLAYTEST-117: "a red
## arrow (like the blue home arrow but red) to point to tasks where we need to go to a specific
## location ... unlike the yeller task where we can just go to any yeller".)* **And none once the
## task is done**: the arrow is there until she has reached the place, and the world answers after
## that (`docs/NARRATIVE.md`: "A finished task is shown by the world and never by text"), not a pointer back at where she
## has just been.
##
## **The tip ends on the rider's own body when there is one, not on the touch point beside it**
## (M222, "the red arrow for the van does not end on the van"): a task performed at an event sits
## its contact at `_reachable_offset()`'s clearance from the rider, on purpose, so the touch point
## stays where she can actually reach it — but that offset is not where the task *is*. Reads
## `_rider.global_position` when this step has one (the van's drop, the burnt shell) and falls
## back to `contact_position()` for a bare-point task (a door, a mast's foot, a swing, the last
## night's front door) or the neighbor, whose own offset is zero and so already agrees with it.
func red_arrow_target() -> Vector2:
	var step := current_step()
	if step == null or step.is_pickup or not step.is_one_place or _contact.is_done:
		return Vector2.INF
	if _rider and is_instance_valid(_rider):
		return _rider.global_position
	return contact_position()
