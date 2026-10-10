class_name ResistanceDirector
extends Node
## Places the day's resistance contact, and enforces the two things that make the subquest
## cost something: every contact is paid for in danger — a mark and a roadblock are guarded where
## they wait, and every other task but the neighbor's sets someone on her the moment she has done
## it — and a timed step expires.
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
## little sideways offset. That makes "well inside the camera's view" a geometric guarantee rather
## than a typical case. It is not a guarantee of being in sight: in the joystick scheme a mark down
## and to one side within 150px can be under a corner its controls cover, which is what
## `_sight.call(at)` below (the visible area) answers, so the dwell does not run there.
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

## How many times `_pick_reachable` redraws from its own pool when the draw itself lands on a
## solid body — checked after the draw rather than filtered out of the pool beforehand, so a pool
## with nothing obstructed in it draws exactly the index it always did; see `_pick_reachable`'s own
## doc for why. The same shape of budget as `TRAP_DRAW_LIMIT`.
const PICK_REACHABLE_REDRAW_LIMIT := 24

## The sentinel `_nearest_legal_in_pool()` answers for "nothing
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

## **Two tests, for two questions** *(olive-hedgehog, inbox #598, the player: "off screen is not
## the same as visible -- the corners get removed for visible not for off screen")*, both injected
## by `main` (`set_sight()`) from the day's one view, so the director holds no camera of its own.
##
## `_sight` answers **"has she seen it"**, and only for a chalk mark's notice dwell
## (`_track_sight_and_reposition()`): `EventManager.sees()`, what she can see (`VisibleView`), the
## camera's view less, in the joystick scheme, the two bottom corners its controls cover *(inbox
## #581, the player: "everything should follow this (and treat it depending on the input
## mode)")*. So a chalk mark under a covered corner is not seen, and its notice does not run there.
## A rig may leave it unset — with no predicate, nothing is ever seen and the re-placement rule
## simply keeps running, which is also correct: a mark nobody is watching for should never stop
## moving because of it.
var _sight: Callable
## `_on_screen` answers **"would it be drawn in front of her"**, for everything the director places
## or removes: where a relocated mark, a waiting robber, a task target, a pursuer sent after her and
## day 10's raid may appear, and when a waiting robber or the taken neighbor may vanish
## (`_box_shows()`, `_drawing_shows()` and their callers, and `_draw_arrival_position()`).
## `EventManager.on_screen()`, the camera's whole view, corners included in either scheme: a thing
## under a covered corner is still drawn there, under the controls, so appearing or vanishing there
## is pop-in *(the same note: "I don't want any pop in")*. A rig may leave it unset, and then
## nothing is ever refused for being on screen.
var _on_screen: Callable
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
## The guard day 13's roadblock task sets over its own contact (`keeps_a_waiting_guard()`, the one
## task that does) — tracked apart from `_guard` so activating it, right behind the mark in the
## same `_on_contact_completed()` call, never retires the mark's own guard by mistake. Set once a
## day and never replaced until the next `start_day()`, since the contact never relocates.
var _task_guard: EventInstance
## The `robber_giving_chase` or `van_guard_giving_chase` today's done task set on her
## (`_set_the_trap_on_her()`), or null before a task is done. Nothing here steers him — he
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
## Every alley mouth of `_mouths_of` (`_alley_mouths()`), built the first time a mark asks.
var _mouths: Array[Vector2i] = []
var _mouths_of: CityMap

func setup(city: City, map: CityMap) -> void:
	# The same self-registration `WorldContext` and `Stroller` use, so anything that needs to ask
	# this director a read-only question — `pointable_objective()`, for a protester — finds it
	# with `get_tree().get_first_node_in_group("resistance")` rather than being handed a reference
	# by whoever built the scene.
	add_to_group("resistance")
	_city = city
	_map = map
	if city and city.events and not city.events.door_crossed.is_connected(_on_door_crossed):
		city.events.door_crossed.connect(_on_door_crossed)
	_happenings.setup(city, map)

## Hands the director the day's two answers about her view: `sees`, whether she can see a world
## point (the notice dwell's), and `on_screen`, whether a world point is anywhere in the camera's
## whole view (placing and removing's). Both are asked of every caller at once, so a test of one
## is never wired where the other belongs. See the docs on `_sight` and `_on_screen`.
func set_sight(sees: Callable, on_screen: Callable) -> void:
	_sight = sees
	_on_screen = on_screen

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
	_happenings.start_day(day, not _scene_task)

	var step := ResistanceSteps.for_day(day, GameState.completed_resistance_steps,
			GameState.failed_resistance_steps, GameState.sabotage_available())
	_begin_step(step, true)

## **A scene recipe's task** (`SceneRecipeRuntime`, `setup.task`; `docs/SCENE_RECIPES.md`): the
## day's own step, offered the way `start_day()` offers it, except that the chalk mark stands at
## `mark` rather than where the day's draw would put it. The mark stands **unread**: a scene starts
## her a short walk from it, and her touch reads it, so the task it unlocks is placed by the same
## `_begin_step()` a played day runs, from where she stands, with every refusal and every guard a
## played day has, and its arrow is drawn from that moment. *(The player, inbox #513, asked how a
## scene is built: "Recipes with live tasks"; inbox #555: "make them not start *on* the mark",
## answered "Unread, walk to it".)*
##
## `mark` is `Vector2.INF` on the last night, whose finale has no mark and is offered from dawn.
## `neighbor_start` pins day 10's neighbor's start to a tile the day's own draw
## (`_a_neighbor_start()`) could have made: the one target whose place is a draw over the whole city
## rather than a place near the mark or a fixed one, so a scene could not otherwise put it at the
## distance it means to test. `Vector2.INF` leaves the draw to the day.
##
## **What the day brings besides the task is not brought** (`ResistanceHappenings.start_day()`'s
## `with_its_events`): a recipe installs only what it selects, and the task is what this selects —
## the mark, its target, whatever the target rides on, the guards and the trap the task sets. The
## neighbor walking to work, the raid, the market and the column stay out; the park day 12's swing
## closes is the task's own answer and still closes.
##
## Answers every reason the request was refused, empty when the mark (or, on the last night, the
## task) is on offer.
func start_recipe_task(day: int, rng: RandomNumberGenerator, day_length: float, mark: Vector2,
		neighbor_start := Vector2.INF) -> Array[String]:
	_scene_task = true
	_scene_task_errors = []
	_pinned_mark = mark
	_pinned_neighbor = neighbor_start
	start_day(day, rng, day_length)
	_pinned_mark = Vector2.INF
	# The mark stands unread: reading it is her touch, which `_on_contact_completed()` answers by
	# placing the task exactly as a played day does. What that placement refuses is answered by
	# `scene_task_errors()`, since it happens after this returns.
	var errors := _scene_task_errors.duplicate()
	if errors.is_empty() and current_step() == null:
		errors.append("setup.task: day %d's task has nowhere to go in this scene" % day)
	return errors

## What a scene's task refused after `start_recipe_task()` returned: the placement of the task a read
## mark unlocks, which happens when she touches the mark. Empty while nothing is refused.
func scene_task_errors() -> Array[String]:
	return _scene_task_errors

## Set for the length of `start_recipe_task()`'s own `start_day()`, and kept for the day it starts:
## a scene's day is the authored one, never the day's own happenings.
var _scene_task := false
## What `start_recipe_task()` refused, filled while it runs.
var _scene_task_errors: Array[String] = []
## The mark `start_recipe_task()` pins, `Vector2.INF` once the mark is placed, and the neighbor's
## start it pins, kept until she reads the mark and the task draws the neighbor.
var _pinned_mark := Vector2.INF
var _pinned_neighbor := Vector2.INF

## A scene's mark at `_pinned_mark`, on the same ground the day's own draw keeps a mark to
## (`_pick_reachable()` over `_alley_mouths()`): the centre of an alley mouth's tile that is legal,
## unobstructed ground reachable from home. `Vector2.INF`, with the reason recorded, otherwise —
## a recipe's pin is refused rather than moved.
func _the_pinned_mark() -> Vector2:
	var tile := _map.world_to_tile(_pinned_mark)
	var refusal := ""
	if not _map.tile_to_world(tile).is_equal_approx(_pinned_mark):
		refusal = "is not a tile centre"
	elif not is_alley_mouth(_map, tile):
		refusal = "is not an alley mouth"
	elif not is_legal_ground(_map, tile, _walled_alleys()) or _map.is_obstructed(tile) \
			or not _reachable_from_home(tile):
		refusal = "is not open ground reachable from home today"
	if refusal != "":
		_scene_task_errors.append("setup.task.mark %s %s" % [_pinned_mark, refusal])
		return Vector2.INF
	return _pinned_mark

## Places `step`'s own contact and offers it — a mark at dawn, or the perform half it unlocks a
## moment after being touched (`_on_contact_completed()`), which is what makes a task one day
## instead of two. `ResistanceSteps.TargetKind` decides how a non-pickup, non-finale step finds
## its own place: a fresh rider (`EVENT`), the run's own recorded scar (`SCAR`, falling back to
## a front day 3's fire could have caught on, burnt for it, when the run has none —
## `_burn_a_front_for_the_task()`), or a bare point this director
## computes itself (`ResistanceSteps.sits_on_a_bare_point()`).
##
## `at_dawn` is true from `start_day()` and false for the task a read mark activates, and decides
## what the guard's draw is kept clear of — see the comment above `_maybe_set_a_trap()`'s call.
func _begin_step(step: ResistanceSteps.Step, at_dawn: bool) -> void:
	_step = step
	_forget_the_arrow()
	if not _step:
		return

	var scar_instance: EventInstance = null
	var no_recorded_scar := false
	if _step.target_kind == ResistanceSteps.TargetKind.SCAR:
		# Decided from the run's own record, never from what happens to be streamed in: a scar
		# farther than `EVENT_STREAM_RADIUS` from wherever she reads the mark is not in the world
		# yet, and a dusk fire is always sited at least that far from where she finished day 3.
		no_recorded_scar = _recorded_scar(_step.task_event_id) == Vector2.INF
		scar_instance = _ride_the_recorded_scar(_step.task_event_id)
		if no_recorded_scar:
			# A run with no recorded scar still has a burnt building to go to: `_place()` picks
			# a front day 3's fire could have caught on, and `_burn_a_front_for_the_task()`
			# below records the scar there and burns the building behind it — never a step with
			# nowhere to go, and never bare sidewalk.
			Telemetry.note("contact", ("step %d: no recorded scar for '%s' — a front the " +
					"fire could have caught on stands in for it") % [_step.index,
					_step.task_event_id])

	var neighbor: EventInstance = null
	if _step.target_kind == ResistanceSteps.TargetKind.NEIGHBOR:
		neighbor = _send_the_neighbor_home()
	# The mark she has just read, when this is the task it unlocks: the task is placed near it
	# (`NEAR_THE_MARK`). `Vector2.INF` at dawn, for a mark or the last night, which have none.
	var mark := Vector2.INF
	if _contact and is_instance_valid(_contact) and _contact.step != null \
			and _contact.step.is_pickup:
		mark = _contact.global_position
	var at: Vector2
	if scar_instance:
		at = scar_instance.global_position
	elif neighbor:
		at = neighbor.global_position
	elif _step.target_kind == ResistanceSteps.TargetKind.NEIGHBOR:
		at = Vector2.INF
	else:
		at = _place(_step, _rng, mark)
	if at == Vector2.INF:
		# A scene's task says why in what `start_recipe_task()` answers instead.
		if not _scene_task:
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
		_rider = scar_instance
		_ride_to_the_door(scar_instance)
		at = _contact.global_position
	elif _step.is_pickup or ResistanceSteps.sits_on_a_bare_point(_step):
		_contact.setup(_step, at)
		_shape_the_touch(_contact, _step)
	else:
		var task_def := EventCatalogue.by_id(_step.task_event_id)
		if not task_def:
			push_warning("resistance step %d rides on unknown event '%s'"
					% [_step.index, _step.task_event_id])
			_step = null
			_contact = null
			return
		_rider = _city.events.spawn_extra(task_def, at)
		if no_recorded_scar:
			_burn_a_front_for_the_task(_rider)
		if _step.target_kind == ResistanceSteps.TargetKind.SCAR:
			_ride_to_the_door(_rider)
		else:
			_contact.ride(_step, _rider, Vector2.ZERO)
		at = _contact.global_position
	_contact.completed.connect(_on_contact_completed)
	_city.add_entity(_contact)
	# Where several places answer, the arrow starts on the one the contact was placed on, and
	# `_process()` moves it to the closest on foot once the first sweep has finished.
	if ResistanceSteps.answers_at_several_places(_step):
		_arrow_key = _contact_key()
	EventBus.resistance_contact_available.emit(_step.index)
	Telemetry.note("contact", "step %d on offer at %s" % [
		_step.index, TelemetryLog.tile(_map.world_to_tile(at))])
	if mark != Vector2.INF:
		var target := red_arrow_target()
		if target == Vector2.INF:
			target = _rider.global_position if _rider else at
		Telemetry.note("contact", "step %d stands %.0fpx from the mark it was read at" % [
			_step.index, mark.distance_to(target)])

	# A guard stands where a mark or a roadblock waits (`keeps_a_waiting_guard()`). Every other task
	# but the neighbor's is not guarded where it waits at all: its trap comes to her once she has
	# done it (`sets_a_trap_on_her()`), from wherever she did. The neighbor does not wait — they are
	# walking home — so a robber at the spot they set out from would guard nothing.
	#
	# **At dawn her position is not yet today's.** `main.gd` starts the resistance before it resets
	# her, so `_player_position()` still answers where the previous attempt left her — often right
	# beside this same mark, if its robber caught her — and the camera `_on_screen` asks is still
	# there too. A candidate refused on either still spends its draws from `_rng`, which moves the
	# guard and every later draw of the day, the task her reading the mark places included. So
	# a dawn guard — only ever a mark's, since the last night's door, the one task offered at dawn,
	# is not guarded — is kept clear of the doorstep, where the day starts her, and never asked
	# about the screen: the day's draws follow from the run seed and the day alone, a retry
	# included. A guard placed the instant she reads a mark asks her live position and the screen,
	# which the route she walked decides.
	#
	# **A roadblock is guarded from its body, not from the point beside it**: she completes it from
	# anywhere within `_body_touch_reach()` of the body's own centre
	# (`ContactPoint.touches_the_body()`), and the guard's band is worked out from that.
	if keeps_a_waiting_guard(_step):
		var guarded_at := at
		var guarded_reach := _contact.reach
		if _rider and ContactPoint.has_a_body(_rider) and _step.target_kind \
				== ResistanceSteps.TargetKind.EVENT:
			guarded_at = _rider.body_position()
			guarded_reach = _body_touch_reach(_rider)
		if at_dawn:
			_maybe_set_a_trap(_day, _rng, guarded_at, _step.is_pickup,
					_map.doorstep_world_position(), false, guarded_reach)
		else:
			_maybe_set_a_trap(_day, _rng, guarded_at, _step.is_pickup, _player_position(), true,
					guarded_reach)

## How far from a body's own centre a touch of it counts (`ContactPoint.body_reach()`): 110px for a
## roadblock (60 + 14 + 36), 72px for the van (22 + 14 + 36).
static func _body_touch_reach(instance: EventInstance) -> float:
	return ContactPoint.body_reach(instance)

## **Every task's contact stands on the thing itself, and the red arrow ends there** *(the player:
## "the red arrows should point to the actual item -- however, the radius of acceptance should be
## big enough to be possible to do" · "No! Never besides the item! Where does that come from? This
## doesn't make any sense")*, replacing M181 slice two's contacts beside the item — a mast's foot
## touched from the tile beside it, the station door from the pavement in front of it, the swing's
## tile centre, a district door's middle tile. How a bare-point task is touched, per kind:
##
## - **day 9's district door** is crossed, not touched (`ContactPoint.by_crossing`;
##   `_on_door_crossed()`): *"Should trigger on the action not on a proximity test"*;
## - **day 11's mast** within its body reach (`ContactPoint.body_reach()`'s sum for the pole: 6 + 14
##   + 36 = 56px from the foot), so she completes it from any side before she is stopped by it;
## - **day 12's swing** by her body overlapping the ellipse at its base (`swing_base()`): *"Place an
##   ellipse at its base. That's the area to touch"*;
## - **the last night's station door** within `DOOR_REACH` of the door point on the facade, the rule
##   every door takes (sandy-egret: "the acceptance radius centered at the door should have a large
##   enough radius for half the sidewalk to be covered"; merry-koala).
func _shape_the_touch(contact: ContactPoint, step: ResistanceSteps.Step) -> void:
	match step.target_kind:
		ResistanceSteps.TargetKind.DOOR:
			contact.by_crossing = true
		ResistanceSteps.TargetKind.MAST:
			contact.reach = EventCatalogue.by_id("loudspeaker").solid_reach() \
					+ Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH
		ResistanceSteps.TargetKind.PARK_SWING:
			contact.touch_ellipse = swing_base()
			contact.reach = contact.touch_ellipse.x + Tuning.PLAYER_BODY_RADIUS
		ResistanceSteps.TargetKind.STATION_DOOR:
			contact.reach = DOOR_REACH

## **The ground ellipse at the swing frame's base** that day 12's task is touched at: semi-axes in
## px, centred on `CityMap.swing_position()`, the bottom-centre the frame is drawn standing on. Read
## off the shadow the frame casts there (`Prop._playground_frame_shape()`, drawn by
## `GroundShape.draw_shadow()`), so what she touches is what she sees: that shadow is a capsule as
## wide as the frame's picture and as deep as its height, from the region table, so the ellipse is
## half its width across and its rounding up and down — 28 by 17px for `swing_frame.svg`'s 56 by 34.
## *(The player: "Not the drawn swing. Place an ellipse at its base. That's the area to touch".)*
static func swing_base() -> Vector2:
	var shadow := Prop._playground_frame_shape()
	return Vector2(shadow.half_length + shadow.radius, shadow.radius)

## Where the run recorded its scar `scar_id` (`GameState.scars`), or `Vector2.INF` when it never
## recorded one — a run started at a later day (`--day 8`), or a day 3 whose fire found no site
## even at dusk.
static func _recorded_scar(scar_id: String) -> Vector2:
	for scar: Dictionary in GameState.scars:
		if String(scar["id"]) == scar_id:
			return scar["position"]
	return Vector2.INF

## The instance standing at the run's own recorded scar for `scar_id`, put in the world now and kept
## there for the rest of the day wherever she walks, or null when the run never recorded one
## (`_recorded_scar()`). The scheduler re-places the same def at the scar every day after
## `since_day` (`EventScheduler._place_scars()`), and that plan is what this rides
## (`EventManager.keep_live()`): she may read the mark from anywhere in the city, far outside the
## streaming radius, and walk away from the shell again afterwards, and neither may leave the
## contact riding nothing. A scar today has no plan for (one recorded on this same day) gets an
## instance of its own at the recorded position instead.
func _ride_the_recorded_scar(scar_id: String) -> EventInstance:
	var at := _recorded_scar(scar_id)
	if at == Vector2.INF or not _city or not _city.events:
		return null
	var shell := _city.events.keep_live(scar_id, at)
	if shell:
		return shell
	var def := EventCatalogue.by_id(scar_id)
	return _city.events.spawn_extra(def, at) if def else null

## Day 8's task on a run with no recorded scar, once its `burnt_shell` stands at a front
## (`_fronts_a_fire_catches_on()`): records the scar there, exactly as day 3's fire would have, and
## has `City.mark_the_burnt_frontage()` burn the building behind it now, so the building she is
## sent to is burnt when she gets there. Nothing else a fire does is done: no block moves along its
## arc, since no fire burned.
##
## **Safe on a retry.** A lost day gives the scars back to their dawn copy
## (`GameState._give_back_what_the_attempt_spent()`), and the retry's dawn dresses every building
## again before this runs, so a lost attempt leaves neither a scar nor a burnt building behind it.
## On a won day the scar is kept, stamped with day 8 (`GameState.add_scar()`), so the scheduler
## stands the shell there again from day 9 on and every later dawn burns the same building, as it
## would after a real fire.
func _burn_a_front_for_the_task(shell: EventInstance) -> void:
	GameState.add_scar(_step.task_event_id, shell.global_position)
	_city.mark_the_burnt_frontage()

## How far day 8's touch reaches from the burnt building's door: the whole tile of sidewalk in
## front of the door, its bottom corners included. *(sandy-egret: "or better to the door but the
## acceptance radius centered at the door should have a large enough radius for half the sidewalk
## to be covered".)* The sidewalk is two tiles (`Tuning.SIDEWALK_WIDTH`), so its near half is the
## one frontage-lane tile below the door; the door's point (`City.way_in_behind()`) is the middle
## of the ground-floor tile above it, so that tile's far corners are half a tile across and a tile
## and a half down — √(16² + 48²) ≈ 50.6px. Straight in front of the door that reaches 2.6px
## past the line between the frontage lane and the kerb lane and no further, so the kerb lane's far
## side and the street never count. A way in on a column line rather than a column's middle (a
## storefront pair, a portico on an even-width front) covers the frontage lane a tile either side
## of the line, less those two tiles' outer far corners.
const DOOR_REACH := Tuning.TILE_SIZE * sqrt(0.5 * 0.5 + 1.5 * 1.5)

## Day 8's contact: it rides the burnt shell `shell` (so `rider_alive()` keeps answering for it) but
## stands on the door of the building behind it (`City.way_in_behind()`) and reaches `DOOR_REACH`
## from there. The shell has no body and draws nothing, so the door is where the task *is* — *"the
## building is what needs to be burnt, not an object next to the building"*. **The door's own
## frontage tile must be ground she can stand on**, the same refusals every contact here keeps
## (`is_legal_ground()`, unobstructed, reachable from home): a door whose frontage something solid
## stands on today gives way to the facade point straight behind the shell, one tile north of it,
## which `DOOR_REACH` covers from the shell's own frontage-lane tile the same way. Draws nothing
## from `_rng`, so the day's later draws are unmoved.
func _ride_to_the_door(shell: EventInstance) -> void:
	var door := _city.way_in_behind(shell.global_position) if _city else Vector2.INF
	if door != Vector2.INF:
		var frontage := _map.world_to_tile(door) + Vector2i.DOWN
		if not is_legal_ground(_map, frontage, _walled_alleys()) or _map.is_obstructed(frontage) \
				or not _reachable_from_home(frontage):
			Telemetry.note("contact", ("step %d: the burnt building's door at %s has no ground " +
					"in front of it today — the facade behind the shell stands in")
					% [_step.index, TelemetryLog.tile(_map.world_to_tile(door))])
			door = Vector2.INF
	if door == Vector2.INF:
		door = shell.global_position + Vector2.UP * Tuning.TILE_SIZE
	_contact.ride(_step, shell, door - shell.global_position)
	_contact.reach = DOOR_REACH

## Day 3's fire, whose own siting rules `_fronts_a_fire_catches_on()` reuses.
const FIRE_ROW := "burning_building"

## The ground day 8's task stands on when the run never recorded a scar: every front day 3's fire
## itself could be sited on (`EventScheduler._open_ground_for()` with `burning_building`'s own
## `AT_THE_FRONT`), each with a building directly north of it to burn. A fresh ground cache, since
## the scheduler's own is the day's and this asks once.
func _fronts_a_fire_catches_on() -> Array[Vector2i]:
	var fire := EventCatalogue.by_id(FIRE_ROW)
	if not fire:
		return []
	return EventScheduler._open_ground_for(fire, _map, {})

## The guard. From `TRAP_FIRST_DAY` no chalk mark is ever placed without one, nor day 13's
## roadblock (`keeps_a_waiting_guard()`) — a robber drawn from the band `alley_robbery`'s own
## numbers fix, so *always guarded* stays survivable instead of a guaranteed lost day. Every other
## task but the neighbor's gets `_set_the_trap_on_her()` instead, and the neighbor neither: see
## `_begin_step()`.
##
## **A chalk mark's own guard (`for_mark`) stands about two-thirds through its alley**, counted
## from the end nearer the mark (`_guard_two_thirds_through()`): *"the robber should be 2/3rds
## through the alley not pressed against the edge of it"* · *"the main reason for this is so the
## robber is not at the edge of the alley which makes him easier visible and easier to avoid"*
## (minty-hedgehog, statement 3), and, asked where he stands in an alley too short for two-thirds
## and 176px from the mark both, *"Two-thirds wins"* (quiet-yak, inbox #471). In a courtyard's passage he
## stands at the courtyard's inner end (`_draw_guard_position_near_far_mouth()`). The roadblock's
## guard keeps a band between `inner_radius + reach` and `pursues_within + reach`, drawn from the
## whole circle around its own contact. **`reach` is the contact's own**: a roadblock is touched
## from any side of its body, so it is guarded from the body's centre with `_body_touch_reach()`
## (`_begin_step()`). The band is worked out from the reach — nearer than
## `inner_radius + reach` a touch from the edge of the reach can land her inside his catch, and
## past `pursues_within + reach` no touch can wake him — so a wider reach with a narrower one's band
## is a guard standing nearer the ground she completes from than the band means.
##
## **Retires only the guard of the same kind this replaces.** `_guard` (the mark's own) and
## `_task_guard` (the roadblock's, at its own contact) are separate, so reading the mark, which
## activates the task right behind it in the same `_on_contact_completed()` call, never takes the
## mark's guard
## out of the day: he stays, asleep, awake or chasing, until the day ends. A relocation of an unread
## mark (`_move_the_mark()`) is the one thing that retires him early, and it never runs while he is
## awake or any part of him is on her screen (`_track_sight_and_reposition()`). A task's guard is
## placed once a day and never replaced.
##
## **`her` and `on_screen_matters` are the caller's to give**: at dawn the doorstep and `false`,
## since her own position and the camera are still the previous attempt's (`_begin_step()`); in
## the day, her live position and `true`, for the roadblock's guard placed as she reads its mark and for
## `_move_the_mark()`'s relocation.
func _maybe_set_a_trap(day: int, rng: RandomNumberGenerator, at: Vector2, for_mark: bool,
		her: Vector2, on_screen_matters: bool, reach := ContactPoint.REACH) -> void:
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
	var guard_at := _guard_position(rng, at, for_mark, her, on_screen_matters, reach)
	var placement := "band"
	if for_mark and not _through_alley_span(at).is_empty():
		placement = "two-thirds in"
	elif for_mark and _far_alley_mouth(at) != Vector2.INF:
		placement = "courtyard's inner end"
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
## `_draw_guard_position_near_far_mouth()` for a chalk mark, the whole-circle
## band `_draw_guard_position()` draws for the roadblock, both measured from the
## contact's own `reach` (see `_maybe_set_a_trap()`). `Vector2.INF` when no candidate qualifies.
## Split out so a rig can ask where he would stand.
func _guard_position(rng: RandomNumberGenerator, at: Vector2, for_mark: bool, her: Vector2,
		on_screen_matters: bool, reach := ContactPoint.REACH) -> Vector2:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance := robbery.inner_radius + reach
	var max_distance := robbery.pursues_within + reach
	var walled_alleys := _walled_alleys()
	var her_refuse_within := robbery.pursues_within if her != Vector2.INF else 0.0
	if for_mark:
		var span := _through_alley_span(at)
		if not span.is_empty():
			return _guard_two_thirds_through(at, span, min_distance, walled_alleys, her,
					her_refuse_within, on_screen_matters)
	var far := _far_alley_mouth(at) if for_mark else Vector2.INF
	if far != Vector2.INF:
		return _draw_guard_position_near_far_mouth(rng, at, far, min_distance, max_distance,
				walled_alleys, her, her_refuse_within, on_screen_matters)
	return _draw_guard_position(rng, at, Vector2.INF, min_distance, max_distance,
			walled_alleys, her, her_refuse_within, on_screen_matters)

## Whether `step` is guarded where it waits rather than sending its trap after her: a chalk mark,
## whose robber stands in its alley (`_maybe_set_a_trap()`), and day 13's roadblock, a guarded place
## by nature whose own robber waits in a band around it. *(grassy-goose, inbox #556, asked which
## tasks switch to a robber arriving off screen: "Every guarded target (Recommended)" — the option
## that kept the roadblock's guard and the marks' two-thirds-in robber as they are.)*
static func keeps_a_waiting_guard(step: ResistanceSteps.Step) -> bool:
	return step != null and (step.is_pickup or step.task_event_id == "roadblock")

## Whether `step`'s trap comes to her rather than waiting at its contact: **every task but the
## roadblock and the neighbor**, the last night's front door included — the man shouting, the van,
## the burnt shell, the district door, a mast's foot, the swing and the station's door. The man
## shouting and the van first, the two named at the keyboard — *"spawn the robber in pursuing mode
## offscreen when she interacts with the yeller"*, and PLAYTEST-144 statement 15: "After the van
## (day 7) a guard chases her; after the man shouting, the robber, which is fine only if he starts
## off screen" — then every other guarded target: *"the robber should spawn in off-screen already
## pursuing when I touch the goal"*, and, asked which, "Every guarded target (Recommended)"
## (grassy-goose, inbox #556). **Not a mark or the roadblock** (`keeps_a_waiting_guard()`), and
## **not the neighbor**, whose task has never been guarded — they are walking home, and a guard at
## the spot they set out from would guard nothing.
static func sets_a_trap_on_her(step: ResistanceSteps.Step) -> bool:
	return step != null and not keeps_a_waiting_guard(step) \
			and step.target_kind != ResistanceSteps.TargetKind.NEIGHBOR

## Which catalogue row `_set_the_trap_on_her()` spawns for `step`'s own task: the roadblock's own
## guard for the van, whose package is what he comes for, and the alley robber for every other —
## the man shouting, the burnt shell, the district door, a mast's foot, the swing and the station's
## door. Only ever asked once `sets_a_trap_on_her(step)` is already true. Takes the completed step
## its caller already holds rather than reading `_step`, so it names the right row by construction
## rather than by the coincidence that `_step` has not yet advanced when a perform step's own
## completion calls it.
func _trap_row_id(step: ResistanceSteps.Step) -> String:
	return "van_guard_giving_chase" if step and step.task_event_id == "delivery_van" \
			else "robber_giving_chase"

## **The trap comes to her.** *(2026-09-13, the player: "maybe spawn the robber in pursuing mode
## offscreen when she interacts with the yeller so it runs towards her from offscreen"; 2026-10-04,
## grassy-goose: "the robber should spawn in off-screen already pursuing when I touch the goal".)*
## The moment she completes a task `sets_a_trap_on_her()` answers for — hands over the note or the
## package, reaches the burnt building's door, crosses the district door, reaches a mast's foot or
## the swing, or hands the key over at the station's door — `_trap_row_id()`'s row is sent at her
## from off screen, and comes at her, awake from its first frame. On day 9 only an inspected
## crossing sends him (`_on_door_crossed()`). So the errand's price is paid on the way out, from
## wherever she did it, rather than guarded at one seeded spot she could walk round — and for the
## man shouting, whichever look-alike she chose costs the same.
##
## **Warned first, like everything else that arrives from off screen** *(M226: the resistance's own
## pursuers come off the "not warned first" exception, the player's "A, remove the exemption";
## calm-kestrel, inbox #559, and busy-quail, inbox #569, "1s warning should be enough -- let's apply
## that to the others as well")*: the screen-edge badge goes up alone at once, with nothing in the
## world, pointing at where he will start (`_draw_arrival_position()`), for the row's own
## `offscreen_notice` (`EventDef.warned_for()`, at most `Tuning.WARNING_ALONE_MAX`); then he is
## created just out of sight that way from where she is by then, already chasing
## (`EventManager.spawn_warned()`), and the badge goes off as he comes into
## view. The badge's place moves only with her, so it never jumps (`PendingWarning`).
##
## **On the last night it chases her away from the station.** The hand-over is the sabotage, and
## the day still has to be won by walking home under the blackout before it goes on to the escape
## (`GameState.earned_good_ending()`), so being caught there loses day 14 like any other catch,
## and a lost day gives the sabotage back with the rest of what the attempt spent, so the retry
## starts at the station's door again.
##
## From `TRAP_FIRST_DAY`, like the guard. Where she is, or the contact she has just touched when
## no player is in the tree (a bare director in a rig): she is within the contact's own reach of
## it, or crossing its door. Nothing is sent when `_draw_arrival_position()` finds no ground, then
## or when the badge's time is up, which the run log says.
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
	var front_door := is_at_a_front_door(step)
	var first := _draw_arrival_position(_rng, her, def, front_door)
	if first[0] == Vector2.INF:
		Telemetry.note("roll", "task handed over unguarded: no walkable ground out of sight of her "
				+ "in %d draws" % (TRAP_DRAW_LIMIT + 4))
		return
	# The bearing the badge points along, fixed now; where he is created is asked again along it
	# when the badge's time is up, from wherever she is then.
	var bearing: Vector2 = (first[0] - her).normalized()
	var drawn: Array = [first]
	var putting_up := [true]
	var where := func(standing: Vector2) -> Vector2:
		# Only put_up may reuse the initial draw: the camera can settle while she stands still.
		if putting_up[0]:
			putting_up[0] = false
			return first[0]
		var again := _draw_arrival_position(_rng, standing, def, front_door, bearing)
		drawn[0] = again
		return again[0]
	var arrive := func(place: Vector2, standing: Vector2) -> bool:
		_trap = _city.events.spawn_warned(def, PackedVector2Array([place]))
		_note_the_trap(def, place, standing, drawn[0])
		return true
	_city.events.warn_first(def, her, where, arrive)

## The run log's line for the pursuer a task has just sent at her, created at `at` with her at `her`,
## from the `_draw_arrival_position()` answer `arrival` that placed it.
func _note_the_trap(def: EventDef, at: Vector2, her: Vector2, arrival: Array) -> void:
	var run := "no clear run at her"
	if arrival[3]:
		run = "a walk at her from across the street"
	elif arrival[1]:
		run = "a clear run at her along her street, beside her" if arrival[2] \
				else "a clear run at her"
	var sent := "a robber" if def.id == "robber_giving_chase" else "a guard"
	Telemetry.note("roll", "task handed over: %s sent after her from %s, %.0fpx off (%s)"
			% [sent, TelemetryLog.tile(_map.world_to_tile(at)), her.distance_to(at), run])

## What she can see this frame — the day's own view (`EventManager.visible_view()`), or, in a rig
## that has never looked through a camera, the tap scheme's view about her
## (`PendingWarning.seen_from()`).
func _view_from(her: Vector2) -> VisibleView:
	var view: VisibleView = _city.events.visible_view() if _city and _city.events else null
	return PendingWarning.seen_from(view, her)

## Where the pursuer a handed-over task sets on her starts: **just out of sight of her** along its
## bearing (`PendingWarning.just_out_of_sight()`, the row's own drawn box clear of what she can see
## and never nearer than the view's half height), on ground `_draw_guard_position()`'s own refusals
## leave alone (walkable, not behind a closure, not held, not the home block, not a walled-off
## alley), and off the camera's whole view by `_shows()` as well. Returns `[position, clear, beside, across]` —
## `Vector2.INF` when no start qualifies; `clear` when the straight line from there to her is
## walkable; `beside` when he starts to her side rather than above or below her; `across` when he
## comes from across the street at a front door (`_across_the_street()`). `prefer`, when given, is a
## bearing tried before any other: the one his badge already points along.
##
## **At a front door, across the street first when choosing the badge's bearing** (`front_door` — the burnt building's, the
## station's: `is_at_a_front_door()`). *(2026-10-04, the player, asked "at a front door, prefer a
## start on the far side of the street that's out of view and has a walkable way to you; if there's
## none, fall back to today's rule. Is that what you mean?": "yes, to your proposal about front
## doors".)* Only when `_across_the_street()` finds no such start does the rule below decide.
##
## **Never through the region's wall or a door** (`_runs_through_the_boundary()`): a start whose
## straight run at her passes through a body of the day's region wall or of a district door is
## refused outright, as a fallback too. He chases in a straight line and nothing solid in the wall
## or the door stops him, so such a start is a man walking through the checkpoint she has just been
## inspected at — on day 9 she is let out 54px past the door's line, where a start straight above,
## below or beside her is often on the door's far side.
##
## **The badge's own bearing first, when it is asked again** (`prefer`): once the badge has been up,
## he is created along the way it pointed if that start still qualifies — at a front door too, ahead
## of the search across the street — so he comes from where the badge said.
##
## **Above or below her by preference**, since the view is shorter that way and a start there is
## nearer. Straight up and straight down first, in an order the day's RNG picks, then
## `TRAP_DRAW_LIMIT` bearings within `ARRIVAL_CONE` of either.
##
## **A clear run at her is what decides it**, since he chases in a straight line
## (`EventInstance._chase()`), sliding along whatever wall is in the way: a start behind a building
## is a man stuck against its back wall while the badge says he is coming. Where there is no clear
## run from above or below — she is on a street that runs sideways, with no crossing street near
## enough — and at a front door with no start across the street, where the building stands straight
## above her (`tests/probes/grassy_goose_target_traps.gd` measures how often), **he comes along her
## own street**, straight left or right just out of sight. Only when neither has a clear run does the
## first legal start of all of them stand in, and then he may never reach her.
##
## **He arrives chasing** (`EventDef.arrives_chasing`, amendment 7 of M226), so from any start here
## walking straight away is caught within his long `Tuning.PURSUIT_TIME` cap, as are standing still
## and walking into him (`tools/test.sh probes/m207_warning_lead.gd` measures each answer).
func _draw_arrival_position(rng: RandomNumberGenerator, her: Vector2, def: EventDef,
		front_door := false, prefer := Vector2.ZERO) -> Array:
	var view := _view_from(her)
	var walled_alleys := _walled_alleys()
	var beside := beside_distance(view, def, her)
	var boundary := _boundary_bodies_near(her, beside)
	if prefer != Vector2.ZERO:
		var kept := PendingWarning.just_out_of_sight(view, def, her, prefer)
		if is_legal_ground(_map, _map.world_to_tile(kept), walled_alleys) \
				and not _shows(kept) \
				and not _runs_through_the_boundary(kept, her, boundary):
			if _a_clear_run(kept, her):
				return [kept, true, is_zero_approx(prefer.y), false]
			if front_door and kept.y > her.y and _his_walk_reaches_her(kept, her, beside, boundary):
				return [kept, false, false, true]
	if front_door:
		var across := _across_the_street(her, def, walled_alleys, boundary, view)
		if across != Vector2.INF:
			return [across, _a_clear_run(across, her), false, true]
	var bearings: Array[Vector2] = []
	var up := PI / 2.0 if rng.randf() < 0.5 else -PI / 2.0
	bearings.append(Vector2.RIGHT.rotated(up))
	bearings.append(Vector2.RIGHT.rotated(-up))
	for _attempt in TRAP_DRAW_LIMIT:
		var side := PI / 2.0 if rng.randf() < 0.5 else -PI / 2.0
		bearings.append(Vector2.RIGHT.rotated(side + rng.randf_range(-ARRIVAL_CONE, ARRIVAL_CONE)))
	var along := 1.0 if rng.randf() < 0.5 else -1.0
	bearings.append(Vector2(along, 0.0))
	bearings.append(Vector2(-along, 0.0))
	var fallback := Vector2.INF
	for bearing in bearings:
		var candidate := PendingWarning.just_out_of_sight(view, def, her, bearing)
		var sideways := is_zero_approx(bearing.y)
		var tile := _map.world_to_tile(candidate)
		if not is_legal_ground(_map, tile, walled_alleys):
			continue
		if _shows(candidate):
			continue
		if _runs_through_the_boundary(candidate, her, boundary):
			continue
		if _a_clear_run(candidate, her):
			return [candidate, true, sideways, false]
		if fallback == Vector2.INF:
			fallback = candidate
	return [fallback, false, false, false]

## How far either side of straight up or straight down `_draw_arrival_position()` draws a start's
## bearing, in radians. Chosen, not measured: a start just out of sight within it is nearer her than
## one beside her, since the view is shorter than it is wide.
const ARRIVAL_CONE := PI / 6.0

## Whether `step`'s target is a door on a building's front — the burnt building's (day 8) or the
## power station's (the last night) — where she stands on the sidewalk below the facade and the
## building fills the view above her. Every front in this city faces south, the way the oblique view
## looks at it (`City.way_in_behind()`, `station_door_point()`), so the far side of her street is
## always straight below her.
static func is_at_a_front_door(step: ResistanceSteps.Step) -> bool:
	return step != null and (step.target_kind == ResistanceSteps.TargetKind.STATION_DOOR
			or step.task_event_id == "burnt_shell")

## Where he starts at a front door: on the far side of her street, below her, out of view, with a
## walk at her — he comes out of the block opposite and crosses at her. The nearest tile centre that
## is:
##
## - below her and wholly out of sight (`PendingWarning.is_out_of_sight()`, his drawn box against
##   what she can see, never nearer than the view's half height), and off the camera's whole
##   view by `_shows()`;
## - legal ground (`is_legal_ground()`);
## - one his own chase walks to her (`_his_walk_reaches_her()`) in no more ground than the start
##   beside her (`beside_distance()`), so he is never later than the start along her street he
##   replaces, and never through the region's wall or a door.
##
## The walk is his chase's, not a path: straight at her, sliding along whatever wall is in the way
## (`EventInstance.walkable_step_on()`), so a start in an alley or a courtyard of the block opposite
## counts when sliding up it brings him out onto her street. Nearest first, ties broken by being
## nearer straight below her, so nothing is drawn from the day's RNG. `Vector2.INF` when no tile
## qualifies.
func _across_the_street(her: Vector2, def: EventDef, walled_alleys: Array[Rect2i],
		boundary: Array[EventScheduler.Planned], view: VisibleView) -> Vector2:
	var furthest := beside_distance(view, def, her)
	var reach := ceili(furthest / Tuning.TILE_SIZE) + 1
	var at := _map.world_to_tile(her)
	var candidates: Array[Vector2] = []
	for dy in range(1, reach + 1):
		for dx in range(-reach, reach + 1):
			var centre := _map.tile_to_world(at + Vector2i(dx, dy))
			var offset := centre - her
			if offset.y <= 0.0 or offset.length() > furthest:
				continue
			if not PendingWarning.is_out_of_sight(view, def, her, centre):
				continue
			candidates.append(centre)
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var da := a.distance_squared_to(her)
		var db := b.distance_squared_to(her)
		if not is_equal_approx(da, db):
			return da < db
		return absf(a.x - her.x) < absf(b.x - her.x))
	for candidate in candidates:
		if not is_legal_ground(_map, _map.world_to_tile(candidate), walled_alleys):
			continue
		if _shows(candidate):
			continue
		if _his_walk_reaches_her(candidate, her, furthest, boundary):
			return candidate
	return Vector2.INF

## The step `_his_walk_reaches_her()` walks a chase in, in px: an eighth of a tile, finer than a
## chase's own step at 30 frames a second (130px/s, about 4.3px).
const WALK_PROBE_STEP := Tuning.TILE_SIZE / 8.0

## Whether a chase started at `from` reaches her at `her` — walked the way `EventInstance._chase()`
## walks it, straight at her and sliding along walls (`EventInstance.walkable_step_on()`) — within
## `limit` px of ground, never stuck against a wall and never through a body of `boundary`. **Stuck
## includes creeping**: a slide along a wall he meets nearly square-on keeps only the sliver of the
## step that runs along it, so a step that keeps under a quarter of its length is a man standing at
## the wall, not one coming round it.
func _his_walk_reaches_her(from: Vector2, her: Vector2, limit: float,
		boundary: Array[EventScheduler.Planned]) -> bool:
	var at := from
	var walked := 0.0
	while walked <= limit:
		var toward := her - at
		if toward.length() <= WALK_PROBE_STEP:
			return true
		var moved := EventInstance.walkable_step_on(_map, at, toward.normalized() * WALK_PROBE_STEP)
		if moved.length() < WALK_PROBE_STEP * 0.25 \
				or _runs_through_the_boundary(at, at + moved, boundary):
			return false
		at += moved
		walked += moved.length()
	return false

## The day's region wall and district-door bodies (`RegionPlanner.RegionPlan.wall_bodies`,
## `door_bodies`) whose body could stand in a run at `her` from `within` px away. Empty before
## `Tuning.REGION_WALL_FIRST_DAY` and in a bare-map rig with no `_city`.
func _boundary_bodies_near(her: Vector2, within: float) -> Array[EventScheduler.Planned]:
	var near: Array[EventScheduler.Planned] = []
	var plan := _region_plan()
	if not plan:
		return near
	var bodies: Array[EventScheduler.Planned] = []
	bodies.append_array(plan.wall_bodies)
	bodies.append_array(plan.door_bodies)
	for body in bodies:
		if body.position.distance_to(her) <= within + body.def.obstructs_radius:
			near.append(body)
	return near

## Whether the straight line from `from` to `to` passes through one of `boundary`'s bodies — within
## its own `obstructs_radius` of its centre. A street door's three bodies, and a wall's, stand a
## body's width apart across the street, kerb to kerb (`RegionPlanner._add_door_bodies()`,
## `SealPlanner.place_hard_on()`), so a line through the door or the wall passes through one of them
## wherever it crosses.
static func _runs_through_the_boundary(from: Vector2, to: Vector2,
		boundary: Array[EventScheduler.Planned]) -> bool:
	for body in boundary:
		var nearest := Geometry2D.get_closest_point_to_segment(body.position, from, to)
		if nearest.distance_to(body.position) <= body.def.obstructs_radius:
			return true
	return false

## How far to her side he starts when he comes along her own street: just out of sight sideways, his
## drawn box clear of what she can see (`PendingWarning.just_out_of_sight()`), on whichever side is
## further, so a start either side is covered. About 340px with the camera on her.
static func beside_distance(view: VisibleView, def: EventDef, her: Vector2) -> float:
	var right := PendingWarning.just_out_of_sight(view, def, her, Vector2.RIGHT).distance_to(her)
	var left := PendingWarning.just_out_of_sight(view, def, her, Vector2.LEFT).distance_to(her)
	return ceilf(maxf(right, left))

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
## **Used for the roadblock's guard, the one guarded contact that is not a chalk mark**, drawn
## from the whole circle: the director always passes `toward` as `Vector2.INF` (a rig may pass a
## point to lean the bearing to the half-circle facing it), and `_guard_position()` sends a mark's
## own guard two-thirds through its alley or to `_draw_guard_position_near_far_mouth()` instead,
## falling back here only for a mark with neither. An `ALLEY` tile by preference, since the
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
## to keep away from — the bare-map rigs in `tests/test_resistance.gd` that call this directly —
## which never rejects anything on either count; a dawn placement passes the doorstep and `false`
## (`_begin_step()`).
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

## How far along a through-alley a chalk mark's guard stands, from the end nearer the mark:
## two-thirds of its length (`_guard_two_thirds_through()`).
const THROUGH_THE_ALLEY := 2.0 / 3.0

## How far in from a courtyard's inner end a guard may stand, at most, where the courtyard leaves
## room beyond `max_distance` of the mark: enough that the exact spot varies from mark to mark, never
## so much that he stops reading as standing at that end. Three tiles.
const FAR_END_REACH_IN := 96.0

## The mark's own through-alley, as `[nearer edge, farther edge]` along its long axis in the mark's
## own column or row — the outer edges of its two end tiles, so the span is the alley's whole length
## (`Tuning.BLOCK_SIZE`, 8 tiles, 256px, for a one-block lot) — or `[]` when `at` is in no
## through-alley (`CityMap.alley_rects`): a courtyard's passage, or not an alley at all.
func _through_alley_span(at: Vector2) -> Array[Vector2]:
	var span: Array[Vector2] = []
	if not _map:
		return span
	var tile := _map.world_to_tile(at)
	for rect in _map.alley_rects:
		if not rect.has_point(tile):
			continue
		var ends := _alley_ends(at)
		if ends.size() < 2:
			return span
		var axis := (ends[1] - ends[0]).normalized()
		var half := Tuning.TILE_SIZE * 0.5
		span.append(ends[0] - axis * half)
		span.append(ends[1] + axis * half)
		return span
	return span

## Where a chalk mark's guard stands in a through-alley whose edges are `span`
## (`_through_alley_span()`): **two-thirds of the way through it**, from the edge nearer the mark at
## `at` (`THROUGH_THE_ALLEY`), so he is inside the alley rather than at its edge, the player's own
## reason. Where that point is `pursues_within + ContactPoint.REACH` (176px) or more from the mark,
## a touch of the mark from its own end never wakes him; in an alley too short for both — every
## one-block alley: a mark stands on its end tile (`_alley_mouths()`), 16px in, so he stands about
## 155px from it — he still stands two-thirds in, and reading the mark may wake him: *"Two-thirds
## wins"* (quiet-yak, inbox #471), which overturns M213's floor of 176px for those alleys.
##
## **Never within `min_distance` of the mark** — `inner_radius`, his catch, plus
## `ContactPoint.REACH`, 62px — kept as a floor that a mark at a mouth never reaches (two-thirds of
## any alley is far past 62px from its end tile), so it changes nothing for a mark; it holds for any
## other point a caller asks about.
##
## Refused, as every guard is, on ground he may not stand on, within `her_refuse_within` of `her`
## or on screen: then the nearest acceptable point along the alley's axis, a quarter tile at a time,
## toward the far edge first and then back toward the mark, never nearer it than `min_distance` and
## never past the far end tile's centre. `Vector2.INF` when none qualifies. Draws nothing from the
## day's RNG.
func _guard_two_thirds_through(at: Vector2, span: Array[Vector2], min_distance: float,
		walled_alleys: Array[Rect2i], her: Vector2, her_refuse_within: float,
		on_screen_matters: bool) -> Vector2:
	var near: Vector2 = span[0]
	var far: Vector2 = span[1]
	var axis := (far - near).normalized()
	var lowest := (at - near).dot(axis) + min_distance
	var highest := near.distance_to(far) - Tuning.TILE_SIZE * 0.5
	var wanted := clampf(maxf(near.distance_to(far) * THROUGH_THE_ALLEY, lowest), lowest,
			maxf(highest, lowest))
	var step := Tuning.TILE_SIZE * 0.25
	var offsets: Array[float] = [wanted]
	var further := wanted + step
	while further <= highest + 0.01:
		offsets.append(further)
		further += step
	var nearer := wanted - step
	while nearer >= lowest - 0.01:
		offsets.append(nearer)
		nearer -= step
	for offset in offsets:
		var candidate := near + axis * offset
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

## Where the guard a mark at `at` sets would stand before anything refused his ground: two-thirds
## through a through-alley (`_guard_two_thirds_through()`), the courtyard's inner end past a
## passage, `Vector2.INF` off an alley. What a relocation asks the screen about
## (`_nearest_alley_within()`).
func _guard_spot(at: Vector2) -> Vector2:
	var span := _through_alley_span(at)
	if span.is_empty():
		return _far_alley_mouth(at)
	var robbery := EventCatalogue.by_id("alley_robbery")
	var axis := (span[1] - span[0]).normalized()
	var along := maxf(span[0].distance_to(span[1]) * THROUGH_THE_ALLEY,
			(at - span[0]).dot(axis) + robbery.inner_radius + ContactPoint.REACH)
	return span[0] + axis * along

## Where a mark's guard stands in a courtyard's passage: at the courtyard's inner end (`far`, from
## `_far_alley_mouth()`), or as near it as the courtyard allows. *(2026-09-27, the player: "robber at
## inner end of the courtyard is fine. I encountered it in game and it worked well for me. you just
## have to lure the robber out first.")* His distance from the mark is whatever the courtyard leaves.
##
## **Beyond `max_distance` of the mark wherever the courtyard is deep enough for that** —
## `pursues_within` plus `ContactPoint.REACH`, so reading the mark leaves him asleep — drawn
## anywhere from the inner end up to `FAR_END_REACH_IN` in from it but never nearer the mark than
## that. **Where the inner end itself is nearer than that, he stands on it**: no farther place
## exists. An ordinary courtyard is four tiles square, so he is often inside `max_distance` and may
## wake as she reads the mark; she lures him out, as the player found in play.
##
## **Never within `min_distance` of the mark**, whatever the ground — `inner_radius`, his catch
## (`EventDef.lethal_reach()`), plus `ContactPoint.REACH`: a touch from anywhere within reach of
## the mark never lands her inside his catch. `Vector2.INF` then, and whenever every candidate is
## refused — the inner end last of all, after `TRAP_DRAW_LIMIT` draws in from it.
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

## Whether any part of a box `half` either side of `centre` is on screen right now: `_shows()`
## asked of the centre and the four corners. The screen is the camera's whole view
## (`_on_screen`), a rectangle far larger than either box and the same world box however the
## window is turned (`VisibleView`'s own doc), so a box that overlaps it has a corner inside it. A
## bare centre test is what lets a picture whose centre is one pixel past the edge show half of
## itself. The corners are asked through `_shows()` itself rather than a margin on it, since a
## margin grows every side of the box alike and the box is not square. A covered corner's area is
## not left out: what is placed there is drawn there, under the controls.
## `false` when `_on_screen` is unset: the bare-map rigs several tests in `tests/test_resistance.gd`
## drive have no camera to ask, so nothing they place is ever refused for being on screen.
func _box_shows(centre: Vector2, half: Vector2) -> bool:
	if not _on_screen.is_valid():
		return false
	for corner: Vector2 in [centre, centre + half, centre - half, centre + Vector2(half.x, -half.y),
			centre + Vector2(-half.x, half.y)]:
		if _on_screen.call(corner):
			return true
	return false

## Whether a world point is anywhere in the camera's whole view right now (`_on_screen`), covered
## corners included — what placing and removing ask. `false` when `_on_screen` is unset.
func _shows(point: Vector2) -> bool:
	return _on_screen.is_valid() and _on_screen.call(point)

## Whether any of what `row` can draw, standing at `feet`, would be on screen right now: its
## footprint (`EventInstance.footprint_of()`, every picture its look can draw, its shadow, bob and
## halo rim, and the caret of a row that can be marked — what `PendingWarning` places outside the
## view by) asked through `_box_shows()`. A row that draws nothing of its own is its feet. What an
## event the director brings in or takes away asks, so nothing of it appears or vanishes in view.
func _drawing_shows(row: EventDef, feet: Vector2) -> bool:
	var box := EventInstance.footprint_of(row)
	if not box.has_area():
		return _shows(feet)
	return _box_shows(feet + box.get_center(), box.size * 0.5)

## Whether any part of a chalk mark's picture at `at` would be on screen right now.
func _mark_shows(at: Vector2) -> bool:
	return _box_shows(at, MARK_HALF_EXTENT)

## Whether any part of a waiting robber standing at `feet` would be on screen right now.
func _guard_shows(feet: Vector2) -> bool:
	return _box_shows(feet + GUARD_BODY_CENTRE, GUARD_HALF_EXTENT)

## The mark's own alley, as `[nearer, farther]`, or `[]` when `at` is on no `ALLEY` ground.
##
## **A through-alley** (`CityMap.alley_rects`, one `Rect2i` each from `CityGenerator._alley_rect()`,
## always `ALLEY_WIDTH_TILES` (2) wide and the rest of the lot long): the end tiles of its long axis
## in the mark's own column or row, ordered by distance from `at`.
##
## **A courtyard's passage** (`CityGenerator._passage_rect()`, the other `ALLEY` ground the city
## builds: one tile wide, closed at the courtyard): `[its street end, the courtyard's inner end]` —
## see `_courtyard_inner_end()`. The passage's own far end is within `inner_radius` plus
## `ContactPoint.REACH` of a mark in it, so the robber stands in the courtyard beyond. *(2026-09-27,
## the player: "robber at inner end of the courtyard is fine. I encountered it in game and it worked
## well for me. you just have to lure the robber out first.")*
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
	if _map.tile_at(tile) != GameEnums.TileType.ALLEY:
		return ends
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var inner := tile
		while _map.tile_at(inner + step) == GameEnums.TileType.ALLEY:
			inner += step
		if _map.tile_at(inner + step) != GameEnums.TileType.COURTYARD:
			continue
		var far := _courtyard_inner_end(at, inner + step)
		if far == Vector2.INF:
			continue
		var street := tile
		while _map.tile_at(street - step) == GameEnums.TileType.ALLEY:
			street -= step
		ends.append(_map.tile_to_world(street))
		ends.append(far)
		return ends
	return ends

## The courtyard's inner end from a mark at `at` in its passage: the centre of the courtyard tile
## farthest from the mark, in the courtyard whose rect (`CityMap.courtyard_rects`) holds `entrance`,
## the first courtyard tile past the passage — "as far from the mark as the courtyard allows".
## Ties go to the first tile in row order, so the answer is the same every time it is asked.
## `Vector2.INF` when no courtyard rect holds `entrance`.
func _courtyard_inner_end(at: Vector2, entrance: Vector2i) -> Vector2:
	for court in _map.courtyard_rects:
		if not court.has_point(entrance):
			continue
		var farthest := Vector2.INF
		var farthest_distance := -1.0
		for y in range(court.position.y, court.end.y):
			for x in range(court.position.x, court.end.x):
				var world := _map.tile_to_world(Vector2i(x, y))
				var distance := at.distance_to(world)
				if distance > farthest_distance:
					farthest_distance = distance
					farthest = world
		return farthest
	return Vector2.INF

## The far end of the mark's alley from `at` — the far end tile of a through-alley, or the inner
## end of a courtyard past a passage (`_alley_ends()`) — or `Vector2.INF` when `at` is on no
## `ALLEY` ground, which a mark never is and the roadblock always is. A courtyard
## mark's guard stands there, or as near it as the ground allows
## (`_draw_guard_position_near_far_mouth()`); a through-alley mark's stands two-thirds through
## (`_guard_two_thirds_through()`).
func _far_alley_mouth(at: Vector2) -> Vector2:
	var ends := _alley_ends(at)
	return ends[1] if not ends.is_empty() else Vector2.INF

## Where a step's contact — or, for an `EVENT`/`SCAR`-fallback perform step, the event it rides
## on — is sited. A pickup and an `EVENT` perform both name tile types in `placement`; `DOOR`,
## `PARK_SWING`, `MAST` and `STATION_DOOR` compute their own point from today's city, since none is
## a matter of picking a tile type, and a `SCAR` fallback stands on a front day 3's fire could have
## caught on (`_fronts_a_fire_catches_on()`), since a building has to be behind it to burn.
##
## **A task is placed near the mark that unlocked it** (`mark`; `_pick_near()`), where one of her
## paths from where she read it first reaches the edge of a `NEAR_THE_MARK` circle round her
## (`_follow_the_paths_to_the_edge()`): the man shouting, the van, a roadblock, day 11's mast and
## day 8's burnt building when the run has no fire of its own. *(feathery-marmot: "the van should spawn close to the mark not across the
## city" · "this applies to almost all tasks".)* The ones whose place is fixed keep it: day 9's
## district door, day 12's swing park and the last night's station door are drawn from their own
## pools as before, day 10's neighbor walks home from wherever `_send_the_neighbor_home()` starts
## them, and day 8's burnt building is where day 3's fire burned whenever the run has one.
func _place(step: ResistanceSteps.Step, rng: RandomNumberGenerator,
		mark := Vector2.INF) -> Vector2:
	if step.target_kind == ResistanceSteps.TargetKind.STATION_DOOR:
		# The same pool the day's planning kept a route to (`target_ground()`), so the draw is
		# asked for reachability like every other pool and always finds some — the pavement she
		# stands on to touch the door. The contact itself is the door, on the facade above it.
		var pavement := _pick_reachable(ResistanceSteps.target_candidates(step, _map,
				_region_plan()), rng, true)
		return Vector2.INF if pavement == Vector2.INF else station_door_point(_map)
	if step.target_kind == ResistanceSteps.TargetKind.DOOR:
		return _place_at_a_door(rng)
	if step.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		return _place_at_a_swing(rng)
	if step.target_kind == ResistanceSteps.TargetKind.MAST:
		return _place_at_a_mast(rng, mark)
	if step.target_kind == ResistanceSteps.TargetKind.SCAR:
		return _pick_near(_fronts_a_fire_catches_on(), rng, mark)
	if step.is_pickup:
		if _pinned_mark != Vector2.INF:
			return _the_pinned_mark()
		return _pick_reachable(_alley_mouths(), rng)
	var candidates: Array[Vector2i] = []
	for type in step.placement:
		candidates.append_array(_map.tiles_of_type(type as GameEnums.TileType))
	return _pick_near(candidates, rng, mark)

## **A chalk mark only ever sits at an alley's mouth**: every tile the dawn draw (`_place()`) and
## every relocation (`_nearest_alley_within()`) may put a mark on. *(2026-10-03, quiet-yak, inbox #486, the
## player, asked whether a mark may sit in the middle of its alley: "Mouth only".)* A through-alley's mouths are
## its end tiles along its long axis, both of them across its two-tile width
## (`CityMap.alley_rects`), so four to an alley; a courtyard passage's is its tile that opens onto
## ground that is neither alley nor courtyard — the street end. In `CityMap.tiles_of_type()`'s own
## order, so a seeded draw over them is the same every time. Built once per map and kept.
func _alley_mouths() -> Array[Vector2i]:
	if _mouths_of == _map and not _mouths.is_empty():
		return _mouths
	_mouths = []
	_mouths_of = _map
	for tile in _map.tiles_of_type(GameEnums.TileType.ALLEY):
		if is_alley_mouth(_map, tile):
			_mouths.append(tile)
	return _mouths

## Whether `tile` is an alley's mouth — see `_alley_mouths()`.
static func is_alley_mouth(map: CityMap, tile: Vector2i) -> bool:
	if map.tile_at(tile) != GameEnums.TileType.ALLEY:
		return false
	for rect in map.alley_rects:
		if not rect.has_point(tile):
			continue
		if rect.size.y >= rect.size.x:
			return tile.y == rect.position.y or tile.y == rect.end.y - 1
		return tile.x == rect.position.x or tile.x == rect.end.x - 1
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var next := tile + step
		var type := map.tile_at(next)
		if type != GameEnums.TileType.ALLEY and type != GameEnums.TileType.COURTYARD \
				and map.is_walkable(next):
			return true
	return false

## The radius of the circle round her a task is placed on the edge of: one block and the street
## beside it (`Tuning.BLOCK_SIZE` + `Tuning.STREET_WIDTH`, 14 tiles) plus half a block, 18 tiles,
## 576px — the mark's own block or the next one. *(The player: "576px and larger".)*
const NEAR_THE_MARK := (Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH + Tuning.BLOCK_SIZE / 2.0) \
		* Tuning.TILE_SIZE

## **Where her paths first reach the edge of the circle** of `NEAR_THE_MARK` round `her`, where she
## read the mark, and the ground inside it they cross on the way: walked tile by tile from her own
## tile over walkable ground the day's obstruction leaves open (`_reach_blocked`), going on only
## from a tile inside the circle, so each tile at or past its edge is the first a path reaches it
## at. *(The player, quiet-yak, inbox #500: "create a circle around the current player position with the
## radius of the desired distance -- then follow the path until it reaches the edge of the circle";
## and 2026-10-03, in conversation, right after inbox #500 in quiet-yak: "no need to special case straight runs or
## anything like that".)* `_circle_edge` and `_circle_inside` hold the
## answer for the placement that follows; both are empty before one is measured.
func _follow_the_paths_to_the_edge(her: Vector2) -> void:
	_ensure_reachability()
	_circle_edge = {}
	_circle_inside = {}
	var start := _map.world_to_tile(her)
	if not _map.is_walkable(start):
		return
	var centre := _map.tile_to_world(start)
	_circle_inside[start] = true
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + step
			if _circle_inside.has(next) or _circle_edge.has(next):
				continue
			if not _map.is_walkable(next) or _reach_blocked.has(next):
				continue
			if _map.tile_to_world(next).distance_to(centre) >= NEAR_THE_MARK:
				_circle_edge[next] = true
				continue
			_circle_inside[next] = true
			queue.append(next)

## The tiles where a path from her first reaches the circle's edge (`_follow_the_paths_to_the_edge()`)
## and the tiles inside it those paths cross. `tile -> true`.
var _circle_edge := {}
var _circle_inside := {}

## Half the box a task's rider is kept out of her view by when it is placed, around the tile it
## stands on: three tiles either side and four up and down — more than a roadblock's 60px band and
## its guards, a van, or the burnt building the day-8 fallback burns behind its front, whose wall
## rises above the tile. She reads the mark standing on it, so a task placed near it could
## otherwise be put in the world, or a building burnt, in front of her. `docs/EVENTS.md`'s rule,
## "Nothing may be seen to appear", and the player's own choice for a task placed near its mark:
## asked whether to keep it, at the cost of most tasks landing at the far edge of `NEAR_THE_MARK`
## rather than nearer, "Keep off-screen" (2026-10-03, quiet-yak, inbox #486).
const TASK_HALF_EXTENT := Vector2(3.0, 4.0) * Tuning.TILE_SIZE

## A tile from `candidates` where one of her paths first reaches the edge of the circle round her
## (`_follow_the_paths_to_the_edge()`), off her screen (`TASK_HALF_EXTENT`), drawn as
## `_pick_reachable()` draws, with every refusal it makes. When no candidate stands on the edge, the
## qualifying tile nearest the mark anywhere in `candidates` stands in (`_nearest_to_the_mark()`),
## so a task is never left with nowhere to go. With no mark (`Vector2.INF`: a rig that places a task
## without reading one) the whole pool is drawn from, as before.
func _pick_near(candidates: Array[Vector2i], rng: RandomNumberGenerator, mark: Vector2) -> Vector2:
	if mark == Vector2.INF:
		return _pick_reachable(candidates, rng)
	_follow_the_paths_to_the_edge(_where_she_read_it(mark))
	var near: Array[Vector2i] = []
	for tile in candidates:
		if not _circle_edge.has(tile) or _box_shows(_map.tile_to_world(tile), TASK_HALF_EXTENT):
			continue
		near.append(tile)
	var at := _pick_reachable(near, rng)
	_fell_back = at == Vector2.INF
	if at != Vector2.INF:
		return at
	var nearest := _nearest_to_the_mark(candidates, mark)
	Telemetry.note("contact", ("nothing qualifies where a path reaches the %.0fpx circle round her; " +
			"the nearest that does is %s") % [NEAR_THE_MARK, "none" if nearest == Vector2.INF
			else "%.0fpx away" % nearest.distance_to(mark)])
	return nearest

## Where she stands as she reads the mark at `mark`: her own position, or the mark with no player in
## the tree (a bare director in a rig).
func _where_she_read_it(mark: Vector2) -> Vector2:
	var her := _player_position()
	return her if her != Vector2.INF else mark

## Whether the last task placed near a mark fell back to the nearest place, no candidate standing
## where a path reaches the circle's edge — for the run log and the tests.
var _fell_back := false

## The tile of `candidates` nearest `mark` that every placement refusal here leaves alone — legal
## ground (`is_legal_ground()`), no body on it, reachable from home, off her screen — or
## `Vector2.INF` when none does. `_pick_near()`'s fallback.
func _nearest_to_the_mark(candidates: Array[Vector2i], mark: Vector2) -> Vector2:
	var walled_alleys := _walled_alleys()
	var nearest := Vector2.INF
	var nearest_distance := INF
	for tile in candidates:
		var world := _map.tile_to_world(tile)
		var distance := world.distance_to(mark)
		if distance >= nearest_distance:
			continue
		if not is_legal_ground(_map, tile, walled_alleys) or _map.is_obstructed(tile) \
				or not _reachable_from_home(tile) or _box_shows(world, TASK_HALF_EXTENT):
			continue
		nearest_distance = distance
		nearest = world
	return nearest

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
	var tile := _pick_reachable(candidates, rng, true)
	if tile == Vector2.INF:
		return Vector2.INF
	return _a_gatehouse_of_the_door_at(_map.world_to_tile(tile), rng)

## The door's line the crossing is watched on (`_on_door_crossed()`): the position of the door
## today's day-9 task names (its gate, over the road) and the street's own axis, which every body
## of the door shares. `Vector2.INF` on every other day.
var _door_at := Vector2.INF
var _door_axis := Vector2.ZERO

## One of the two gatehouses of the district door whose segment holds `tile` (its
## `checkpoint_hut`s, one on each pavement, `RegionPlanner._add_door_bodies()`), drawn once by the
## day's RNG and fixed for the day — the arrow ends on it. *(The player: "The gate crossing task
## should point the arrow on the gatehouse and crossing should be the test no proximity" · "No it
## should choose one".)* Records the door's line for the crossing. `tile` itself when the door
## has no bodies today, which a door on its own day always has.
func _a_gatehouse_of_the_door_at(tile: Vector2i, rng: RandomNumberGenerator) -> Vector2:
	_door_at = Vector2.INF
	_door_axis = Vector2.ZERO
	var region_plan := _region_plan()
	if not region_plan:
		return _map.tile_to_world(tile)
	for segment in region_plan.doors:
		if not segment.tile_rect().has_point(tile):
			continue
		var area := _map.tile_rect_to_world(segment.tile_rect())
		var houses: Array[EventScheduler.Planned] = []
		for body in region_plan.door_bodies:
			if not area.has_point(body.position):
				continue
			if body.def.lifts_for_traffic:
				_door_at = body.position
				_door_axis = body.facing
			elif body.def.redetains:
				houses.append(body)
		if houses.is_empty():
			return _map.tile_to_world(tile)
		houses.sort_custom(func(a: EventScheduler.Planned, b: EventScheduler.Planned) -> bool:
			return a.position.x < b.position.x \
					or (a.position.x == b.position.x and a.position.y < b.position.y))
		# A door with no boom today: its line is one of its own gatehouses' — this door's own
		# bodies share its street's axis, where another door's need not.
		if _door_at == Vector2.INF:
			_door_at = houses[0].position
			_door_axis = houses[0].facing
		return houses[rng.randi_range(0, houses.size() - 1)].position
	return _map.tile_to_world(tile)

## **Day 9 is done by crossing the door, never by standing near it** *(the player: "Cross at this
## district door" · "Should trigger on the action not on a proximity test")*: `EventManager`'s
## `door_crossed` — she was let out on the far side after the inspection, or walked through the
## door's line — completes the task when it is the named door, in either direction. A crossing of
## any other door does nothing.
##
## **Only an inspected crossing sends the trap.** Walked under a raised boom (`inspected` false), the
## door sets its own guard on her (`EventManager._set_a_guard_on_her()`), and that guard is the whole
## of the crossing's price: no robber comes from off screen as well. *(2026-10-04, the player, asked
## whether both should come at once: "(a)" — under the boom only the guard, the robber only after an
## inspected crossing.)* `_walked_under_the_door` carries that into `_on_contact_completed()`, which
## `complete_now()` calls before it returns.
func _on_door_crossed(at: Vector2, axis: Vector2, inspected: bool) -> void:
	if not _step or _step.target_kind != ResistanceSteps.TargetKind.DOOR or not _contact \
			or _contact.is_done or _door_at == Vector2.INF:
		return
	if absf((at - _door_at).dot(_door_axis)) > 1.0 or absf(axis.dot(_door_axis)) < 0.99 \
			or at.distance_to(_door_at) > Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5:
		return
	Telemetry.note("contact", "step %d: she crossed the district door at %s, %s" % [_step.index,
			TelemetryLog.tile(_map.world_to_tile(_door_at)),
			"let through after the inspection" if inspected else "under the boom, not inspected"])
	_walked_under_the_door = not inspected
	_contact.complete_now()
	_walked_under_the_door = false

## Set only while `_on_door_crossed()` completes day 9's task from a walk under the boom, so the
## completion it calls sends no trap: the door's own guard is already after her.
var _walked_under_the_door := false

## Where day 12's task points: the swing of the one park the city chose for it
## (`CityGenerator.swing_park()`), forced open today whatever its arc has reached
## (`CityState.purpose_of()`), at the same point `City._dress_block()` draws the swing frame at
## (`CityMap.swing_position()`). The pool is `ResistanceSteps.target_candidates()`, one tile, which
## the day's planning keeps reachable from home; `Vector2.INF` only on a day that park is not open,
## which on its own day is a city `CityGenerator.validate()` refused.
func _place_at_a_swing(rng: RandomNumberGenerator) -> Vector2:
	if not _map:
		return Vector2.INF
	var tile := _pick_reachable(ResistanceSteps.target_candidates(
			_step_of_kind(ResistanceSteps.TargetKind.PARK_SWING), _map, null), rng)
	if tile == Vector2.INF:
		return Vector2.INF
	var layout: BlockLayout = _map.block_layouts.get(CityGenerator.swing_park(_map))
	return _map.swing_position(layout.playground) if layout else tile

## **The station's door point on its facade**: the middle of the drawn door
## (`Building._draw_front_overlay()`, centred on the two pavement tiles of
## `CityMap.power_station_door`), half a tile up the ground floor — the same point
## `City.way_in_behind()` gives a building's door, so the same `DOOR_REACH` covers the pavement in
## front of it the same way. One tile above the pavement rect's centre, which is half a tile below
## the wall line.
static func station_door_point(map: CityMap) -> Vector2:
	return map.power_station_door_position() + Vector2.UP * Tuning.TILE_SIZE

## Where day 11's task points: beside the foot of one of today's live loudspeaker masts
## (`EventManager.mast_foot()`'s own point, the plan's position), drawn by the day's RNG among the
## masts she can reach, weighted toward the nearer ones (`_weighted_mast_index()`). `Vector2.INF`
## when no mast stands near her and none can be put up there, and none stands anywhere else either —
## from `Tuning.MAST_FIRST_DAY` on, only a day whose holds took every site, or a scene recipe, which
## installs no mast it does not name.
##
## **Reachable is asked of the ground beside the foot, not of the foot.** The pole is a body
## (`EventScheduler.blocked_by()` paints its disc over the foot's own tile), and she touches it
## from beside it. So a mast counts when one of the four tiles beside its foot is legal,
## unobstructed ground reachable from home — the same refusals every placement in this file keeps.
## The contact stands on the foot itself, where the arrow ends (`_shape_the_touch()`), and a touch
## counts within 56px of it, which the tile beside it (32px) is well inside.
##
## **A mast already silenced is not offered again**, which only a run whose day 11 was replayed
## after a won attempt could meet; the draw is over the plans in the day's own order, so the same
## day draws the same mast every time.
##
## **Near the mark she read** (`mark`; `_place()` says why): only the masts she reaches by following
## a path from where she read it to the edge of the circle round her (`_follow_the_paths_to_the_edge()`,
## the tile beside the foot inside the circle or on its edge) are drawn among. **When none is, a mast is queued as the next event the day generates** near her
## (`_add_a_mast_near()`, `EventManager.queue_a_mast()`) — the city's six fixed sites (M180's "the
## same sites every day") leave most marks with no mast near, and the player chose a new mast over a
## far one: *"The 6 masts rule is stupid anyway. It doesn't come from me. And it actually makes it
## harder to encounter masts. We need to discuss this again but not now. Now just add a new mast
## close by"* (2026-10-03, quiet-yak, inbox #486). Only where no ground near the mark can take one is the offered mast
## nearest the mark the one. **No live mast anywhere is no mast near her**, so a mark still has one
## put up beside it. `Vector2.INF` for `mark` (a rig placing the task without a mark) draws among
## them all.
func _place_at_a_mast(rng: RandomNumberGenerator, mark := Vector2.INF) -> Vector2:
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
	# No live mast anywhere is no mast near, so a mark still has one put up beside it below — a day
	# whose holds took every site, or a scene recipe, which installs no mast it does not name.
	if offered.is_empty() and mark == Vector2.INF:
		return Vector2.INF
	if mark != Vector2.INF:
		_follow_the_paths_to_the_edge(_where_she_read_it(mark))
		var near_plans: Array[EventScheduler.Planned] = []
		var near_beside: Array[Vector2i] = []
		var nearest := 0
		for i in offered.size():
			var distance := _map.tile_to_world(beside[i]).distance_to(mark)
			if distance < _map.tile_to_world(beside[nearest]).distance_to(mark):
				nearest = i
			if _circle_inside.has(beside[i]) or _circle_edge.has(beside[i]):
				near_plans.append(offered[i])
				near_beside.append(beside[i])
		_fell_back = false
		if near_plans.is_empty():
			var added := _add_a_mast_near(mark, rng)
			if not added.is_empty():
				_mast_id = EventScheduler.added_mast_id(_map.tile_to_world(added[0]))
				return _map.tile_to_world(added[0])
			_fell_back = true
			if offered.is_empty():
				return Vector2.INF
			near_plans.append(offered[nearest])
			near_beside.append(beside[nearest])
		offered = near_plans
		beside = near_beside
	var index := _weighted_mast_index(beside, rng)
	_mast_id = offered[index].mast_id
	return offered[index].position

## Queues one more mast near `mark` for day 11's task, when no live mast stands where her paths
## reach within the circle round her (`_place_at_a_mast()`), and answers `[its foot, the tile beside
## it she touches it from]`, or `[]` when nothing near her can take one. The director only offers
## the ground; the mast is generated by the scheduler's own acceptance among it
## (`EventManager.queue_a_mast()`, *"if there is a mast queued up that will be the next event to be
## generated"*). The ground offered is sidewalk or square, where `MastSites` stands every mast:
##
## - where one of her paths first reaches the edge of the circle round her (`_circle_edge`), with a
##   tile beside it reached too, and out of her view (`TASK_HALF_EXTENT`), so it is never seen to
##   appear;
## - passing every refusal a contact's ground passes (`is_legal_ground()`, no body on it, reachable
##   from home);
## - ground a site would be offered on (`MastSites._is_eligible()`: off the home street, its field
##   off a calm interior and off every place a region door could stand).
func _add_a_mast_near(mark: Vector2, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var added: Array[Vector2i] = []
	if not _city or not _city.events:
		return added
	var walled_alleys := _walled_alleys()
	var feet: Array[Vector2i] = []
	var beside_of := {}
	for type: GameEnums.TileType in [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]:
		for tile in _map.tiles_of_type(type):
			var world := _map.tile_to_world(tile)
			if not _circle_edge.has(tile) or _box_shows(world, TASK_HALF_EXTENT):
				continue
			if not is_legal_ground(_map, tile, walled_alleys) or _map.is_obstructed(tile) \
					or not _reachable_from_home(tile) or not MastSites._is_eligible(world, _map):
				continue
			for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next := tile + side
				if is_legal_ground(_map, next, walled_alleys) and not _map.is_obstructed(next) \
						and _reachable_from_home(next) \
						and (_circle_edge.has(next) or _circle_inside.has(next)):
					feet.append(tile)
					beside_of[tile] = next
					break
	var plan := _city.events.queue_a_mast(feet, rng)
	if not plan:
		Telemetry.note("contact", "no ground where her paths reach the %.0fpx circle can take a mast"
				% NEAR_THE_MARK)
		return added
	var foot := _map.world_to_tile(plan.position)
	Telemetry.note("contact", "a mast is generated at %s for the task, %.0fpx from the mark"
			% [TelemetryLog.tile(foot), plan.position.distance_to(mark)])
	added.append(foot)
	added.append(beside_of.get(foot, foot))
	return added

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
	if _pinned_neighbor != Vector2.INF:
		_scene_task_errors.append(("setup.task.neighbor %s is not a start the day could draw: a " +
				"sidewalk tile centre %d±%d tiles of walk from home, %.0fpx or more from her")
				% [_pinned_neighbor, wanted, NEIGHBOR_WALK_BAND_TILES, NEIGHBOR_CLEAR_OF_HER])
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
	if _pinned_neighbor != Vector2.INF:
		# A scene's pin (`start_recipe_task()`): one of the starts the draw below chooses among, or
		# none — never the nearest one standing in for it.
		var pinned := _map.world_to_tile(_pinned_neighbor)
		return pinned if pinned in offered \
				and _map.tile_to_world(pinned).is_equal_approx(_pinned_neighbor) else _NO_TILE
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

## Takes the neighbor she did not reach away with the raid, once nothing of them is on her screen
## (`_drawing_shows()`: everything they draw, against the camera's whole view, covered corners
## included) — they walked home into the vans, and a figure that vanished in front of her would say
## something else. Their feet alone are not enough: their picture stands above them, so feet just
## past the bottom edge leave most of the figure in view.
func _take_the_neighbor_away() -> void:
	if not _taken_neighbor or not is_instance_valid(_taken_neighbor):
		_taken_neighbor = null
		return
	if _drawing_shows(_taken_neighbor.def, _taken_neighbor.global_position):
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
	_happenings.tick(delta, _player_position(), _player_velocity(), _drawing_shows)
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
	if ResistanceSteps.answers_at_several_places(_step):
		# Chosen again twice a second, and at once when what it points at has gone — finished, or
		# freed as it streamed out — rather than leaving the arrow on nothing until the next tick.
		_arrow_clock += delta
		if _arrow_clock >= ARROW_RETARGET_SECONDS \
				or (_arrow_key != null and _arrow_position() == Vector2.INF):
			_arrow_clock = 0.0
			retarget_the_arrow()
		_sweep_the_arrow_fields(ARROW_SWEEP_TILES_PER_FRAME)
		if _step.target_kind == ResistanceSteps.TargetKind.MAST:
			_follow_her_between_masts()
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
## **Retargeting changes neither price.** The man shouting's trap comes to her at the handover
## from wherever it happens (`sets_a_trap_on_her()`); the roadblock's guard stands where the
## seeded one put him (`keeps_a_waiting_guard()`) and is not moved when she picks another; and
## `_process()`'s own deadline check reads `_elapsed` against `_day_length` — none of them reads
## `_rider`'s identity.
##
## Skipped while the nearest look-alike in reach is already the one it rides (`best == _rider`):
## a rider with a body is touched from any side of it (`ContactPoint.touches_the_body()`), and one
## without is touched where it stands, so the contact already answers for wherever she is round it.
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
	_contact.ride(_step, best, Vector2.ZERO)
	Telemetry.note("contact", "step %d retargeted onto the nearest look-alike in reach"
			% _step.index)

## The distance from `instance`'s own centre within which she can touch it: every point a touch of
## a body counts from (`ContactPoint.touches_the_body()`) lies inside it (`_body_touch_reach()`), and
## for a figure with no body it is `ContactPoint.REACH` past her own body. Asked of an arbitrary
## look-alike rather than only the seeded rider, so a solid body's own clearance is respected
## whichever candidate this is asked about.
func _reach_distance(instance: EventInstance) -> float:
	return _body_touch_reach(instance) if ContactPoint.has_a_body(instance) \
			else Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH

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
	# A relocation retires the guard over the old spot (`_maybe_set_a_trap()`), and a robber never
	# vanishes where she can see it or out of a chase: while he is awake — she can wake him deep in
	# the alley and run on past `NOTICE_RADIUS` of the mark — or any part of him is on her
	# screen, the mark stays where it is and he stays with it.
	if _guard and is_instance_valid(_guard) \
			and (not _guard.is_waiting() or _guard_shows(_guard.global_position)):
		return
	var here := _player.global_position
	if here.distance_to(at) <= NOTICE_RADIUS:
		return
	var nearest := _nearest_alley_within(here)
	if nearest == Vector2.INF:
		return
	_move_the_mark(nearest)

## The nearest alley mouth to `here` (`_alley_mouths()`), a through-alley's or a courtyard
## passage's, that is not closed, is walkable, and is not held, on the home block, inside a walled-off crossing alley,
## standing on a solid event body, or sealed off from home by the day's whole obstruction (see
## `_pick_reachable`'s own doc — the relocation is the same placement question as the initial
## roll, asked again, and the same refusal has to hold or a mark could relocate into a sealed
## alley, a building or a pocket nothing can walk out of even though it is never placed there to
## start with), within `NOTICE_RADIUS` — or `Vector2.INF` if there is none. Linear over
## `CityMap.tiles_of_type()`, which is cached; there is one active mark at a time, so this runs
## once a frame at most.
##
## **`is_obstructed()` was missing here even after M188 added it to `_pick_reachable()`.** A `--day 9 --seed 4242 --route mark,task,calm,home --no-title` boot of
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
## picture is asked with its own size (`_mark_shows()`), and the spot in its alley where
## `_move_the_mark()` would stand the guard (`_guard_spot()`), with his (`_guard_shows()`), so a
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
	for tile in _alley_mouths():
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
		if _mark_shows(world) or _guard_shows(_guard_spot(world)):
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
		var task := ResistanceSteps.by_index(step_index + 1)
		_begin_step(task, false)
		_rig_her_route_for(task)
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
	# Every task but the roadblock and the neighbor sends a pursuer after her from off screen; the
	# roadblock keeps its guard waiting at the contact instead (`_begin_step()`). Day 9's door sends
	# none when she walked under its boom, whose own guard is already after her (`_on_door_crossed()`).
	if step and sets_a_trap_on_her(step) and not _walked_under_the_door:
		_set_the_trap_on_her(step)
	elif step and sets_a_trap_on_her(step):
		Telemetry.note("roll", "task done under the boom: the door's own guard is after her, "
				+ "and nobody else is sent")
	if not (step and step.needs_goal):
		return

	GameState.sabotage_done = true
	# Nothing goes off here. The hand-over takes the man on the night shift minutes, so the city
	# goes dark once she has walked far enough from the station — every window, every light and
	# every mast at once, the masts because they run on the same power. That is `Blackout`'s, and
	# it watches the flag set above rather than this call.

## **After a mark, the task's own row is rigged onto her route** — the man shouting on day 6 and a
## loudspeaker mast on day 11. *(olive-koala, statement 2: "right now the first mark I almost never
## see a yeller. after touching the mark a marble bag with 1/3 chance of yeller should be put in so
## the yeller is guaranteed to encounter a yeller in the next three events" · inbox #561 in coral-bunny: "day 11 is
## going to be a x=3", then "let's make the other rigged bags smaller, too".)* The route's bag is
## rigged with a bag of `Tuning.TASK_CONTACT_WITHIN_THE_NEXT` (`MAST_WITHIN_THE_NEXT` for the mast)
## marbles, the row and the rest drawn from the bag she was drawing from
## (`EventManager.rig_her_route()`), and the place it names is put ahead of her on the branch she is
## walking. It is **besides** the contact `_begin_step()` placed near the mark, never instead of it:
## the man shouting is a look-alike the any-instance contact follows her onto
## (`_follow_her_between_look_alikes()`), and the mast is a second one on her way while the task's
## arrow points at the one near the mark first (inbox #561 in coral-bunny: "let it point to the closest one first").
func _rig_her_route_for(task: ResistanceSteps.Step) -> void:
	if not task or not _city or not _city.events:
		return
	var row := ""
	var size := 0
	if task.task_event_id == YELLER_ROW:
		row = YELLER_ROW
		size = Tuning.TASK_CONTACT_WITHIN_THE_NEXT
	elif task.target_kind == ResistanceSteps.TargetKind.MAST:
		row = MAST_ROW
		size = Tuning.MAST_WITHIN_THE_NEXT
	if row == "":
		return
	var ids: Array[String] = [row]
	var rigged := _city.events.rig_her_route(ids, size)
	if rigged.is_empty():
		return
	# Which marbles the rest of the rigged bag took depends on how far into her bag the day had got,
	# which the walk decides.
	var names: Array[String] = []
	for marble: Variant in rigged:
		names.append(str(marble))
	Telemetry.note("roll", "the next %d on her route are drawn from a rigged bag: %s"
			% [rigged.size(), ", ".join(names)])

## The rows a task's mark rigs onto her route — see `_rig_her_route_for()`.
const YELLER_ROW := "homeless_yeller"
const MAST_ROW := "loudspeaker"

func _clear() -> void:
	if _contact and is_instance_valid(_contact):
		_contact.queue_free()
	_contact = null
	_rider = null
	_mast_id = ""
	_forget_the_arrow()
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
## the same read-only destination as the red arrow where several places answer, and otherwise
## `contact_position()` read back. The protest rank and arrow therefore never contradict each
## other about which roadblock answers day 13.
func pointable_objective() -> Vector2:
	var step := current_step()
	if step == null or step.is_pickup:
		return Vector2.INF
	return red_arrow_target() if ResistanceSteps.answers_at_several_places(step) \
			else contact_position()

## Where the red arrow should point, or `Vector2.INF` when nothing warrants one: no step today,
## today's step is the mark rather than the task, or the task is done. **Every task has one**
## *(the player, playtest busy-quail: "yeah let's just always do arrows")*, the tasks several places
## answer included — any man shouting, any roadblock, any of day 11's live masts. The last
## night's front door has it from dawn, since the finale has no mark. *(PLAYTEST-117: "a red arrow
## (like the blue home arrow but red) to point to tasks where we need to go to a specific
## location".)* **And none once the task is done**: the arrow is there until she has reached the
## place, and the world answers after that (`docs/NARRATIVE.md`: "A finished task is shown by the
## world and never by text"), not a pointer back at where she has just been.
##
## **The tip ends on the item, where its contact stands** (`_shape_the_touch()`; *"No! Never
## besides the item!"*): the van and the neighbor themselves, the burnt building's door on its
## facade (`_ride_to_the_door()`; sandy-egret: "or better to the door"), the district door's
## chosen gatehouse, the mast's foot, the swing's base and the station's door on its facade —
## `contact_position()`, which every one of them is.
##
## **Where several places answer the task** (`ResistanceSteps.answers_at_several_places()`) the tip
## is the one `retarget_the_arrow()` last chose, the closest on foot. **Asking is a read**: this
## never chooses, never sweeps and never moves the contact, since `main.gd` asks it every frame and
## a scene recipe's `arrowed` check and `_begin_step()`'s run-log line ask it too. So in the frame
## between the chosen man shouting or roadblock going (finished, or freed as it streams out) and
## `_process()` choosing again, it answers the contact's own position, which is always a place that
## answers the task, and never a freed one's. On day 11 the contact moves with the arrow
## (`_point_the_arrow_at()`), so the contact's position is the arrow's.
func red_arrow_target() -> Vector2:
	var step := current_step()
	if step == null or step.is_pickup or _contact.is_done:
		return Vector2.INF
	if not ResistanceSteps.answers_at_several_places(step) \
			or step.target_kind == ResistanceSteps.TargetKind.MAST:
		return contact_position()
	var at := _arrow_position()
	return at if at != Vector2.INF else contact_position()

## How often the arrow of a task several places answer is chosen again: twice a second. **A choice
## is a lookup**: her tile read in two finished fields (`ArrowField`), plus a scan of the live
## targets to see whether they are still the ones the fields were swept from. The sweeps behind the
## fields run apart from it, a slice a frame (`ARROW_SWEEP_TILES_PER_FRAME`), and only when the
## targets or what blocks her have changed. `tests/probes/plush_moose_arrow_cost.gd` measures both.
const ARROW_RETARGET_SECONDS := 0.5
## How many tiles of walking closer another target has to be, at least, before the arrow leaves
## the one it points at — four tiles closer moves it, three do not — so it does not flicker between
## two that are about as near as each other. *(Proposed, not asked for: plush-moose's entry.)*
const ARROW_HOLD_TILES := 4
## How many tiles of a sweep (`ArrowField.advance()`) one frame runs. A whole sweep of a city's
## open ground at once is a long frame, so it is spread: at this size a slice is a small part of a
## frame, and one field is done in about twenty frames, a third of a second at 60fps, while the
## arrow reads the field it replaces. `tests/probes/plush_moose_arrow_cost.gd` measures the slice,
## the tick and the whole sweep.
const ARROW_SWEEP_TILES_PER_FRAME := 1000

## What the red arrow points at right now, for a task several places answer: the instance id of a
## man shouting or a roadblock (an id rather than the `EventInstance`, so a freed one is never
## touched — `instance_from_id()` answers null for it), or the mast id of a mast. Null before the
## task is placed.
var _arrow_key: Variant = null
var _arrow_clock := 0.0
## The finished fields the arrow reads (`ArrowField`): `_arrow_nearest` swept from every target at
## once, which says which is closest from any tile and how far; `_arrow_own` swept from the one the
## arrow points at alone, which says how far that one is when another is closest — what the hold
## compares. Null until the first of each finishes.
var _arrow_nearest: ArrowField
var _arrow_own: ArrowField
## The sweeps under way that will replace them, or null when none is.
var _arrow_nearest_next: ArrowField
var _arrow_own_next: ArrowField
## `_ground_for_the_arrow()`'s layout, and the state of what blocks her it was laid out for.
var _arrow_ground := PackedInt32Array()
var _arrow_ground_versions := Vector2i(-1, -1)

## Clears every choice and field of the arrow: a new step, or the day's end.
func _forget_the_arrow() -> void:
	_arrow_key = null
	_arrow_clock = 0.0
	_arrow_nearest = null
	_arrow_own = null
	_arrow_nearest_next = null
	_arrow_own_next = null
	_arrow_ground = PackedInt32Array()

## Where `_arrow_key` stands now, or `Vector2.INF` when nothing is chosen or it is gone: an instance
## finished or freed, or a mast no longer the day's.
func _arrow_position() -> Vector2:
	if _arrow_key is int:
		var found := instance_from_id(_arrow_key)
		if is_instance_valid(found) and found is EventInstance \
				and not (found as EventInstance).is_finished:
			return (found as EventInstance).global_position
	elif _arrow_key is String and _city and _city.events:
		return _city.events.mast_foot(_arrow_key)
	return Vector2.INF

## The key of the target the contact itself is on: the mast it was sent to, or the instance it
## rides. Null when it rides nothing.
func _contact_key() -> Variant:
	if _step and _step.target_kind == ResistanceSteps.TargetKind.MAST:
		return _mast_id if _mast_id != "" else null
	if _rider and is_instance_valid(_rider):
		return _rider.get_instance_id()
	return null

## Whether two keys name the same target. Keys of one day are all ids or all mast ids, but a
## comparison of an int with a String is an error rather than false, so the type is asked first.
static func _same_key(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b

## Every place that answers today's task, as `{key, at, reach, beat}` (`ArrowField.start()`): `reach`
## is how far from `at` a touch counts, and `beat` the path a man shouting paces, so a tile beside
## any of his beat is beside him.
func _arrow_candidates(step: ResistanceSteps.Step) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if not _city or not _city.events or not _map:
		return found
	if step.target_kind == ResistanceSteps.TargetKind.MAST:
		var walled_alleys := _walled_alleys()
		for plan in _city.events.plans():
			if _mast_answers(plan, walled_alleys):
				found.append({"key": plan.mast_id, "at": plan.position, "reach": _mast_reach(),
						"beat": PackedVector2Array()})
		return found
	for instance in _city.events.instances():
		if instance.def.id == step.task_event_id and not instance.is_finished:
			found.append({"key": instance.get_instance_id(), "at": instance.global_position,
					"reach": _reach_distance(instance),
					"beat": instance.path if instance.def.paces else PackedVector2Array()})
	return found

## Whether `plan` is a mast that answers day 11's task: **any live mast does** *(the player, asked
## whether only the mast near the mark and the one rigged onto her route should: "why limit
## artificially to two arbitrary masts")* — the mast near the mark, the one rigged onto her route
## and every other. Live means the same offer `_place_at_a_mast()` makes: a placed, unsilenced mast
## off the home block whose foot has legal, unobstructed ground beside it that is reachable from
## home, so the arrow never moves the task onto a mast she cannot touch.
func _mast_answers(plan: EventScheduler.Planned, walled_alleys: Array[Rect2i]) -> bool:
	if plan.mast_id == "" or plan.def.id != MAST_ROW or plan.silenced or not plan.is_placed():
		return false
	var foot := _map.world_to_tile(plan.position)
	if _map.is_closed(foot) or _map.is_on_home_block(foot):
		return false
	for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var tile := foot + side
		if is_legal_ground(_map, tile, walled_alleys) and not _map.is_obstructed(tile) \
				and _reachable_from_home(tile):
			return true
	return false

## How far from a mast's foot a touch counts (`_shape_the_touch()`).
static func _mast_reach() -> float:
	return EventCatalogue.by_id(MAST_ROW).solid_reach() + Tuning.PLAYER_BODY_RADIUS \
			+ ContactPoint.REACH

## The ground every sweep of the arrow starts from (`ArrowField.advance()`): each tile
## `ArrowField.UNREACHED`, or `ArrowField.BLOCKED` where she cannot walk right now — today's
## closures (`CityMap.closed_tiles`, the fenced park's ground included), the soft seals shut to
## walkers (`soft_sealed_tiles`) and the tile under every stationary solid body standing
## (`obstructed_tiles`), which holds what was put down after dawn too: a body rigged onto her route,
## the task's own rider, a roadblock put on her route after the mark. What that record leaves out
## she walks through here as she does in the street: a mobile row, which moves out of her way, and a
## door's own bodies, which let a walker through.
##
## **Read live, and laid out once for each state of them**: rebuilt the first time a sweep asks after
## any of the three has changed (`CityMap.day_record_version`, `CityMap.obstruction_version`), and
## copied whole by every sweep started under the same state. A sweep already finished keeps what
## blocked her when it began; a change starts a new one (`retarget_the_arrow()`).
func _ground_for_the_arrow() -> PackedInt32Array:
	var versions := Vector2i(_map.day_record_version, _map.obstruction_version)
	if versions == _arrow_ground_versions and not _arrow_ground.is_empty():
		return _arrow_ground
	_arrow_ground_versions = versions
	var width := _map.size.x
	var ground := PackedInt32Array()
	ground.resize(width * _map.size.y)
	ground.fill(ArrowField.UNREACHED)
	# The authored scene's void is BUILDING to every live walking query. ArrowField reads the
	# saved context's raw tile array for its inner loop, so put that same boundary into the ground
	# it receives rather than letting the red arrow measure a route the player cannot walk.
	if _map.stretch_active:
		for y in _map.size.y:
			for x in _map.size.x:
				var tile := Vector2i(x, y)
				if not _map.in_stretch(tile):
					ground[y * width + x] = ArrowField.BLOCKED
	for blocked: Dictionary in [_map.closed_tiles, _map.soft_sealed_tiles, _map.obstructed_tiles]:
		for tile: Vector2i in blocked:
			if _map.in_bounds(tile):
				ground[tile.y * width + tile.x] = ArrowField.BLOCKED
	_arrow_ground = ground
	return _arrow_ground

## Chooses the target the red arrow points at, for a task several places answer, by **walking
## distance and never straight-line**: the closest on foot from where she stands, read at her tile
## from the finished fields (`ArrowField`). It stays on the one it points at until another is at
## least `ARROW_HOLD_TILES` closer, whether she is heading for that one or has walked on past the
## task; it leaves at once a target that has gone or that she can no longer walk to. Before the
## first sweep has finished it stays on the contact's own target (`_contact_key()`).
##
## Also starts a sweep wherever the targets, or what blocks her (`CityMap.day_record_version`,
## `CityMap.obstruction_version`), are no longer what a field was swept for. Run by `_process()`
## every `ARROW_RETARGET_SECONDS`, at once when the target has gone, and when a sweep finishes. On
## day 11 the contact moves with the arrow, so the mast the arrow points at is the one a touch
## silences.
func retarget_the_arrow() -> void:
	var step := current_step()
	if not ResistanceSteps.answers_at_several_places(step):
		return
	var found := _arrow_candidates(step)
	var versions := Vector2i(_map.day_record_version, _map.obstruction_version)
	var newest := _arrow_nearest_next if _arrow_nearest_next else _arrow_nearest
	if found.is_empty():
		_arrow_nearest_next = null
	elif not _swept_for(newest, found, versions):
		_arrow_nearest_next = ArrowField.start(_map, found, versions)
	var chosen: Variant = _choose_the_arrow(found)
	if chosen == null:
		if _arrow_position() == Vector2.INF:
			_arrow_key = null
		return
	if not _same_key(chosen, _arrow_key):
		for target in found:
			if _same_key(target["key"], chosen):
				_point_the_arrow_at(chosen, target["at"], step)
	# The field of the one it points at, alone, for the hold.
	var own_newest := _arrow_own_next if _arrow_own_next else _arrow_own
	for target in found:
		if _same_key(target["key"], _arrow_key):
			var alone: Array[Dictionary] = [target]
			if not _swept_for(own_newest, alone, versions):
				_arrow_own_next = ArrowField.start(_map, alone, versions)

## The key `retarget_the_arrow()` points the arrow at from `found`, or null to leave it: see there.
func _choose_the_arrow(found: Array[Dictionary]) -> Variant:
	if found.is_empty():
		return null
	var live := {}
	for target in found:
		live[target["key"]] = true
	var current: Variant = _arrow_key if _arrow_key != null and live.has(_arrow_key) else null
	var here := _player_position()
	var nearest: Variant = null
	var nearest_length := -1
	var tile := _map.world_to_tile(here) if here != Vector2.INF else Vector2i(-1, -1)
	if _arrow_nearest and here != Vector2.INF:
		nearest = _arrow_nearest.nearest_at(tile)
		if nearest != null and live.has(nearest):
			nearest_length = _arrow_nearest.length_at(tile)
		else:
			nearest = null
	if current == null:
		if nearest != null:
			return nearest
		var own: Variant = _contact_key()
		return own if own != null and live.has(own) else null
	if nearest == null or _same_key(nearest, current):
		return current
	if not _arrow_own:
		# The first choice of the task: there is nothing yet for the arrow to flicker away from.
		return nearest
	if not _same_key(_arrow_own.keys[0], current):
		# How far the one it points at is has not been swept yet: it holds until it has.
		return current
	var current_length := _arrow_own.length_at(tile)
	if current_length < 0:
		return nearest
	return nearest if nearest_length <= current_length - ARROW_HOLD_TILES else current

## Whether `field` (finished or under way) was swept from exactly `found`, each standing where it
## stood then (`ArrowField.anchor_of()`), under the blocking `versions` name.
func _swept_for(field: ArrowField, found: Array[Dictionary], versions: Vector2i) -> bool:
	if field == null or field.versions != versions or field.anchors.size() != found.size():
		return false
	for target in found:
		var key: Variant = target["key"]
		if not field.anchors.has(key) or field.anchors[key] != ArrowField.anchor_of(_map, target):
			return false
	return true

## Runs `budget` tiles of the sweeps under way, the field of every target first, and chooses again
## the moment one finishes. A frame that lays out the ground (`_ground_for_the_arrow()`) or a field
## (`ArrowField.advance()`'s first call) does that alone.
func _sweep_the_arrow_fields(budget: int) -> void:
	if not _arrow_nearest_next and not _arrow_own_next:
		return
	# Laying out what blocks her afresh is a frame's work of its own, like a field's own layout.
	if Vector2i(_map.day_record_version, _map.obstruction_version) != _arrow_ground_versions \
			or _arrow_ground.is_empty():
		_ground_for_the_arrow()
		return
	var finished := false
	if _arrow_nearest_next:
		budget -= _arrow_nearest_next.advance(_map, _ground_for_the_arrow(), budget)
		if _arrow_nearest_next.done:
			_arrow_nearest = _arrow_nearest_next
			_arrow_nearest_next = null
			finished = true
	if _arrow_own_next and budget > 0:
		_arrow_own_next.advance(_map, _ground_for_the_arrow(), budget)
		if _arrow_own_next.done:
			_arrow_own = _arrow_own_next
			_arrow_own_next = null
			finished = true
	if finished:
		retarget_the_arrow()

## Runs every sweep to its end and chooses, all at once: what a rig with no frames to spread it over
## asks for (`tests/test_resistance.gd`, the cost probe). Bounded, though a sweep finishing starts at
## most the one field of whatever it chose.
func _settle_the_arrow() -> void:
	retarget_the_arrow()
	for i in 16:
		if not _arrow_nearest_next and not _arrow_own_next:
			return
		_sweep_the_arrow_fields(1 << 30)

## Points the arrow at `key`, and a mast's contact with it.
func _point_the_arrow_at(key: Variant, at: Vector2, step: ResistanceSteps.Step) -> void:
	if not _same_key(key, _arrow_key) and _arrow_key != null:
		Telemetry.note("contact", "step %d: the red arrow moves to a closer target on foot"
				% step.index)
	_arrow_key = key
	if step.target_kind == ResistanceSteps.TargetKind.MAST and key is String \
			and _contact and not _contact.is_done:
		_mast_id = key
		_contact.global_position = at

## Day 11: a mast she is within touching reach of is the one a touch silences, however the arrow
## last chose — the arrow is chosen twice a second, and she covers ground in that time.
func _follow_her_between_masts() -> void:
	var here := _player_position()
	if here == Vector2.INF or not _city or not _city.events:
		return
	var reach := _mast_reach()
	if _contact.global_position.distance_to(here) <= reach:
		return
	var walled_alleys := _walled_alleys()
	for plan in _city.events.plans():
		if plan.mast_id == _mast_id or plan.position.distance_to(here) > reach:
			continue
		if _mast_answers(plan, walled_alleys):
			_point_the_arrow_at(plan.mast_id, plan.position, _step)
			return
