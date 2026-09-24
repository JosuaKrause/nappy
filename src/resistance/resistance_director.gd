class_name ResistanceDirector
extends Node
## Places the day's resistance contact, and enforces the two things that make the subquest
## cost something: every mark is guarded, and a timed step expires.
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

## The day the first chalk mark can appear, and so the first day anything is guarded — nothing
## is offered before it.
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

## How many bearings `_reachable_offset` tries before it settles for the last one drawn — a task's
## rider sits wherever `EventScheduler` put it, which can be flush against a building, so the fixed
## clearance distance can land inside that same building on some bearings and not others. The same
## shape of budget as `TRAP_DRAW_LIMIT`, for the same reason: a draw has to stop somewhere; see
## `_reachable_offset`'s own doc for the fallback when it does.
const REACHABLE_OFFSET_DRAW_LIMIT := 24

var _city: City
var _map: CityMap
var _contact: ContactPoint
## The `EventInstance` a perform step's contact rides on. Null for a pickup, the finale, or a
## `DOOR`/`PARK_SWING` step, all of which sit on a bare tile instead.
var _rider: EventInstance
var _step: ResistanceSteps.Step
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
## move can retire it and `_maybe_set_a_trap` a fresh one near wherever the mark goes.
var _guard: EventInstance
## The RNG `start_day()` was handed, kept rather than re-drawn so a guard spawned later —
## when the mark moves, or when the mark's own touch activates today's perform step — still
## comes from the same day's stream a replay would reproduce.
var _rng: RandomNumberGenerator
var _player: Stroller

func setup(city: City, map: CityMap) -> void:
	# The same self-registration `WorldContext` and `Stroller` use, so anything that needs to ask
	# this director a read-only question — `pointable_objective()`, for a protester — finds it
	# with `get_tree().get_first_node_in_group("resistance")` rather than being handed a reference
	# by whoever built the scene.
	add_to_group("resistance")
	_city = city
	_map = map

## Lets the danger edge's own screen test answer "has she seen this" for the resistance
## too, without the director holding a viewport of its own. See the class doc on `_sight`.
func set_sight(is_on_screen: Callable) -> void:
	_sight = is_on_screen

func start_day(day: int, rng: RandomNumberGenerator, day_length: float) -> void:
	_clear()
	_elapsed = 0.0
	_day_length = day_length
	_expired = false
	_day = day
	_rng = rng
	_seen = false
	_seen_dwell = 0.0
	_guard = null
	# A fresh attempt at the day starts without the package, whether this is the first try
	# or a retry after a nerve — see GameState.resistance_carrying_package.
	GameState.resistance_carrying_package = false

	var step := ResistanceSteps.for_day(day, GameState.completed_resistance_steps,
			GameState.failed_resistance_steps, GameState.sabotage_available())
	_begin_step(step)

## Places `step`'s own contact and offers it — a mark at dawn, or the perform half it unlocks a
## moment after being touched (`_on_contact_completed()`), which is what makes a task one day
## instead of two. `ResistanceSteps.TargetKind` decides how a non-pickup, non-finale step finds
## its own place: a fresh rider (`EVENT`), the run's own recorded scar (`SCAR`, falling back to
## an ordinary placement of the same row when the run has none), or a bare point this director
## computes itself (`DOOR`, `PARK_SWING`).
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

	var at: Vector2 = scar_instance.global_position if scar_instance else _place(_step, _rng)
	if at == Vector2.INF:
		push_warning("resistance step %d has nowhere to go in this city" % _step.index)
		_step = null
		return

	_contact = ContactPoint.new()
	if scar_instance:
		var offset := _reachable_offset(scar_instance, _rng)
		_rider = scar_instance
		_contact.ride(_step, scar_instance, offset)
		at = scar_instance.global_position + offset
	elif _step.is_pickup or _step.district >= 0 or _step.target_kind in [
			ResistanceSteps.TargetKind.DOOR, ResistanceSteps.TargetKind.PARK_SWING]:
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

	_maybe_set_a_trap(_day, _rng, at)

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

## The guard. From `TRAP_FIRST_DAY` no contact is ever placed without one — a robber drawn
## from the band `alley_robbery`'s own numbers fix, so *always guarded* stays survivable
## instead of a guaranteed lost day. See docs/DECISIONS.md, "the guard, worked out from the
## numbers rather than chosen": below the band touching the mark is death, always; above it
## he is scenery; between them which side she approaches from decides whether he wakes.
##
## `away_from` is set only when this guard is replacing one whose mark just moved — see
## `_move_the_mark()`. A moved mark sits up to `NOTICE_RADIUS` (400px) from her, and a
## bearing drawn from the full circle could land him toward her at as little as ~224px
## (400 − 176, the band's own far edge) — on screen, appearing out of nothing. Restricted to
## the half-circle facing away from her instead, the worst case — perpendicular to the away
## direction — puts him at `sqrt(400² + 176²)` ≈ 437px, past the 367px half-diagonal that
## makes a point off screen at this zoom (see `NOTICE_RADIUS`'s own doc), so he is never
## drawn appearing from nothing.
func _maybe_set_a_trap(day: int, rng: RandomNumberGenerator, at: Vector2,
		away_from: Vector2 = Vector2.INF) -> void:
	if day < TRAP_FIRST_DAY:
		return
	var robbery := EventCatalogue.by_id("alley_robbery")
	if not robbery:
		return
	var min_distance := robbery.inner_radius + ContactPoint.REACH
	var max_distance := robbery.pursues_within + ContactPoint.REACH
	var guard_at := _draw_guard_position(rng, at, away_from, min_distance, max_distance,
			_walled_alleys())
	if guard_at == Vector2.INF:
		# **No trap is better than a trap in a wall.** `TRAP_DRAW_LIMIT` bearings found nowhere
		# walkable at all — every one of them a building, a held segment or the home block — so
		# the mark goes out unguarded today rather than guarded by a robber stuck for ever where
		# nobody can ever meet him. `docs/DECISIONS.md`, M100, "The guard robber is placed inside a
		# building, where he is stuck for ever".
		Telemetry.note("roll", "chalk mark unguarded: no walkable ground for the robber in %d draws"
				% TRAP_DRAW_LIMIT)
		return
	Telemetry.note("roll", "chalk mark guarded: robber %.0fpx away (band %.0f-%.0f)"
			% [at.distance_to(guard_at), min_distance, max_distance])
	_guard = _city.events.spawn_extra(robbery, guard_at)

## A bearing and a distance from `at`, redrawn until the point is walkable ground the day's
## catalogue and the home-block exemption both leave alone — rejected rather than repaired, the
## same rule every other placement in this game keeps. `docs/DECISIONS.md`, M100, "The guard robber is
## placed inside a building": his lethal radius travels with him, so a bearing that lands him in
## a building is an invisible fatal spot rather than a cosmetic one.
##
## **An `ALLEY` tile by preference, since the row's own placement is `ALLEY`**, but not a
## requirement: the band this draws from can reach well past a two-tile-wide alley's own building
## line, so an alley hit is kept the moment it is found and any other walkable, unheld, off-the-
## home-block tile is kept as a fallback in case the budget runs out first. `Vector2.INF` when
## `TRAP_DRAW_LIMIT` draws found neither — see the caller for what that means.
##
## `away_from` is set only when this guard is replacing one whose mark just moved — see
## `_move_the_mark()`. A moved mark sits up to `NOTICE_RADIUS` (400px) from her, and a bearing
## drawn from the full circle could land him toward her at as little as ~224px (400 − 176, the
## band's own far edge) — on screen, appearing out of nothing. Restricted to the half-circle
## facing away from her instead, the worst case — perpendicular to the away direction — puts him
## at `sqrt(400² + 176²)` ≈ 437px, past the 367px half-diagonal that makes a point off screen at
## this zoom (see `NOTICE_RADIUS`'s own doc), so he is never drawn appearing from nothing.
##
## `walled_alleys` defaults empty for the bare-map rigs several tests in `tests/test_resistance.gd`
## drive with no `_city` — see `_walled_alleys()`, which is what the real caller passes.
func _draw_guard_position(rng: RandomNumberGenerator, at: Vector2, away_from: Vector2,
		min_distance: float, max_distance: float,
		walled_alleys: Array[Rect2i] = []) -> Vector2:
	var fallback := Vector2.INF
	for _attempt in TRAP_DRAW_LIMIT:
		# Hoisted so the draw can be written down. Which distance a mark got is the one random
		# outcome that decides a run without a route around it, and the only one whose
		# consequence otherwise looks like bad luck with the event scheduler.
		var distance := rng.randf_range(min_distance, max_distance)
		var angle: float
		if away_from == Vector2.INF:
			angle = rng.randf() * TAU
		else:
			var facing_away := (at - away_from).angle()
			angle = facing_away + rng.randf_range(-PI / 2.0, PI / 2.0)
		var candidate := at + Vector2.RIGHT.rotated(angle) * distance
		var tile := _map.world_to_tile(candidate)
		if not _map.is_walkable(tile) or _map.is_closed(tile) or _map.is_held_at(tile) \
				or _map.is_on_home_block(tile) or _map.is_in_walled_alley(tile, walled_alleys):
			continue
		if _map.tile_at(tile) == GameEnums.TileType.ALLEY:
			return candidate
		if fallback == Vector2.INF:
			fallback = candidate
	return fallback

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
## **The last bearing drawn stands in if every attempt fails** rather than leaving the contact with
## nowhere at all: `_begin_step()` has no branch for "this step has no reachable ground" the way
## `_place()` does, and a task whose seeded rider is that thoroughly walled in is a placement bug
## worth seeing in play (Telemetry notes it) rather than a step silently dropped.
func _reachable_offset(instance: EventInstance, rng: RandomNumberGenerator) -> Vector2:
	var clearance: float = instance.def.obstructs_radius
	if clearance <= 0.0:
		return Vector2.ZERO
	var distance := clearance + Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH
	var walled_alleys := _walled_alleys()
	var offset := Vector2.ZERO
	for attempt in REACHABLE_OFFSET_DRAW_LIMIT:
		offset = Vector2.RIGHT.rotated(rng.randf() * TAU) * distance
		var tile := _map.world_to_tile(instance.global_position + offset)
		if not _map.is_walkable(tile) or _map.is_closed(tile) or _map.is_held_at(tile) \
				or _map.is_on_home_block(tile) or _map.is_in_walled_alley(tile, walled_alleys) \
				or _map.is_obstructed(tile):
			if attempt == REACHABLE_OFFSET_DRAW_LIMIT - 1:
				Telemetry.note("contact", ("step %d: no reachable offset found for '%s' in %d " +
						"draws — the last bearing drawn stands in") % [_step.index if _step else -1,
						instance.def.id, REACHABLE_OFFSET_DRAW_LIMIT])
			continue
		return offset
	return offset

## Where a step's contact — or, for an `EVENT`/`SCAR`-fallback perform step, the event it rides
## on — is sited. A pickup and a `district`-less perform both name tile types in `placement`;
## the finale names a `district` instead; `DOOR` and `PARK_SWING` compute their own point from
## today's city, since neither is a matter of picking a tile type.
func _place(step: ResistanceSteps.Step, rng: RandomNumberGenerator) -> Vector2:
	if step.district >= 0:
		return _pick_reachable(_map.purpose_tiles(step.district as GameEnums.BlockPurpose), rng)
	if step.target_kind == ResistanceSteps.TargetKind.DOOR:
		return _place_at_a_door(rng)
	if step.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		return _place_at_a_swing(rng)
	var candidates: Array[Vector2i] = []
	for type in step.placement:
		candidates.append_array(_map.tiles_of_type(type as GameEnums.TileType))
	return _pick_reachable(candidates, rng)

## Where day 9's task points: one of today's region-wall doors — a `StreetNetwork.Segment` from
## `City.region_plan().doors` — at its own crossing tile, chosen the same reachable-among-
## candidates way `_pick_reachable()` already chooses a mark's alley. `Vector2.INF` if the city
## opened none, which does not happen on this task's own day: `Tuning.REGION_WALL_FIRST_DAY`
## equals the day this task is offered on.
##
## **Dropped before `_pick_reachable()` sees them: doors whose own segment borders the home
## block.** `RegionPlanner._union_atoms()` only atomises the one street the doorstep notch opens
## onto (`ClosurePlanner.home_street()`), so the block's other bordering segments are ordinary
## boundary segments and can become doors like any other, on a city where the day's tree happens
## to cross one. `allow_held` below skips `is_held_at()` outright, and `is_held_at()` is the half
## of "nothing on the home block" that covers these streets (`CityMap.is_on_home_block`'s own doc
## names `is_held_at` as the other half) — so without this filter a door on that ground would pass
## through the held carve-out it was never meant to cover.
func _place_at_a_door(rng: RandomNumberGenerator) -> Vector2:
	var plan: RegionPlanner.RegionPlan = _city.region_plan() if _city else null
	if not plan or plan.doors.is_empty():
		return Vector2.INF
	var home_border := {}
	for segment in StreetNetwork.around_blocks(Rect2i(_map.home_block, Vector2i.ONE)):
		home_border[segment.key()] = true
	var candidates: Array[Vector2i] = []
	for segment in plan.doors:
		if home_border.has(segment.key()):
			continue
		var rect := segment.tile_rect()
		candidates.append(rect.position + rect.size / 2)
	# `allow_held` is not optional here, it is the whole placement: every remaining tile sits on
	# a segment `EventManager.start_day()` already held for the day (held so no catalogue row may
	# be sited on a door — see `CityMap.held_segments`), and this director runs after that. The
	# held filter would refuse the exact ground the task names: with it applied, every door
	# candidate read `held` and step 8 answered `Vector2.INF` in every run — "nowhere to go" — so
	# the crossing task never appeared at all. It does not reopen the home-block exemption: that
	# ground was filtered out above, before `allow_held` ever gets a say.
	return _pick_reachable(candidates, rng, true)

## Where day 12's task points: the swing of one specific park's playground —
## `CityMap.playgrounds`, which already names only the parks currently open (a requisitioned
## park has none, see that field's own doc), at the same point `City._dress_block()` draws the
## swing frame at (`CityMap.swing_position()`). **Not "forced open whatever its state"**: that
## would mean overriding a requisitioned park's own arc, which touches `EventScheduler`/
## `ClosurePlanner` and is out of this slice's scope fence — picking only among parks the city
## has already left open is the smallest honest stand-in, and the run's own guarantee of at
## least one reachable calm area a day (`docs/CITY.md`, "Every day stays winnable") means there
## is almost always one to choose from. `Vector2.INF` on the day nothing qualifies.
func _place_at_a_swing(rng: RandomNumberGenerator) -> Vector2:
	if not _map or _map.playgrounds.is_empty():
		return Vector2.INF
	var candidates: Array[Vector2i] = []
	for rect in _map.playgrounds:
		candidates.append(_map.world_to_tile(_map.swing_position(rect)))
	return _pick_reachable(candidates, rng)

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
## **Never inside a solid event body, either.** `CityMap.is_obstructed()` is the day's own record
## of where a café's tables, a construction band, a kerbed van or any other stationary body
## stands, filled by `EventManager.start_day()` from the whole day's plan before this director
## ever runs — an open, walkable tile can still have a body parked on it, which `is_walkable()`
## has no way to see. Rejected rather than repaired, the same rule every other placement in this
## file keeps.
##
## **Avoids a tile a completed step already used, unless nothing else reachable is left (M177).**
## Landing a fresh mark back on the very alley an earlier step's mark stood at reads as the game
## reusing its own prop rather than "any alley she comes across" — but the avoidance never costs
## the placement guarantee itself: a candidate list whose only reachable tile happens to be a used
## one still returns it rather than `Vector2.INF`. `GameState.completed_resistance_alley_tiles`
## only ever holds `ALLEY` tiles (see `_on_contact_completed()`), so this filter is a silent no-op
## against every other kind of placement, none of which is ever an alley.
##
## **`allow_held` skips only the `is_held_at` refusal, and only one caller passes it.** Held
## ground means *no hazard or catalogue row may be sited here*; a contact is neither, and for a
## step whose candidates are the held region-door segments themselves (`_place_at_a_door()`) the
## filter would refuse the very ground the task points at. It did — see that call's own note.
## The other five refusals stand even then: a door on closed, unwalkable, obstructed, home-block-lot
## or walled-alley ground is still a door she cannot cross today.
##
## **Not exempted: a door on a street bordering the home block.** `is_on_home_block` only refuses
## a tile inside the home block's own lot (its own doc says so); the streets around the block are
## the other half of "nothing on the home block", and normally that half is exactly what
## `is_held_at` catches — which `allow_held` would otherwise skip for a door candidate too.
## `_place_at_a_door()` drops those candidates itself, before any candidate reaches this function,
## so `allow_held` never has to carry that exemption.
func _pick_reachable(candidates: Array[Vector2i], rng: RandomNumberGenerator,
		allow_held := false) -> Vector2:
	var walled_alleys := _walled_alleys()
	var reachable: Array[Vector2i] = []
	var unused: Array[Vector2i] = []
	for tile in candidates:
		if not _map.is_walkable(tile) or _map.is_closed(tile) \
				or (not allow_held and _map.is_held_at(tile)) \
				or _map.is_on_home_block(tile) or _map.is_in_walled_alley(tile, walled_alleys) \
				or _map.is_obstructed(tile):
			continue
		reachable.append(tile)
		if tile not in GameState.completed_resistance_alley_tiles:
			unused.append(tile)
	var pool := unused if not unused.is_empty() else reachable
	if pool.is_empty():
		return Vector2.INF
	return _map.tile_to_world(pool[rng.randi_range(0, pool.size() - 1)])

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

func _process(delta: float) -> void:
	if not _step or _expired or not _contact or _contact.is_done:
		return
	_elapsed += delta
	if _rider and not _contact.rider_alive():
		_expire("lost its contact when the thing it rode on finished")
		return
	# A pickup is the only step subject to the re-placement rule; a one-place perform step is
	# never subject to it (its rider or its point is fixed for the day), and an any-instance
	# perform step is subject to the first-reached rule instead.
	if _step.is_pickup:
		_track_sight_and_reposition(delta)
	elif _rider and not _step.is_one_place:
		_track_first_reached()
	if _step.deadline_fraction <= 0.0 or _day_length <= 0.0:
		return
	if _elapsed / _day_length < _step.deadline_fraction:
		return
	_expire("expired at %.0f%% of the day" % (_step.deadline_fraction * 100.0))

## *Asked for a hidden contact among look-alikes · overturned on 2026-09-13* (`docs/NARRATIVE.md`,
## "The contact is whichever look-alike she reaches first"): *"we cannot expect the player to do
## an exhaustive check ... so if the solution is the yeller it's always the first yeller you come
## close enough to hand the note."* An any-instance perform step's contact is not pinned to
## whichever instance `_begin_step()` happened to spawn — it rides onto whichever live instance
## sharing the step's own `task_event_id` she comes within reach of first, seeded rider included.
## A one-place step (`Step.is_one_place`) never runs this: its rider is the task.
##
## **The seeded rider's own guard and deadline are untouched.** `_maybe_set_a_trap()` still stands
## a robber near the position `_begin_step()` rolled, and `_process()`'s own deadline check still
## reads `_elapsed` against `_day_length` — neither reads `_rider`'s identity, so retargeting onto
## a different look-alike changes nothing about either rule. What it does mean: a look-alike she
## reaches before the seeded one is never guarded by that trap, which is the point rather than a
## gap — there is no candidate left to get wrong, so there is nothing left to guard against
## picking one.
##
## Skipped once she has already reached the seeded rider itself (`best == _rider`): its own fixed,
## replay-stable offset from `_reachable_offset()` already has `ContactPoint`'s own distance check
## covered, so nothing here needs to move it.
func _track_first_reached() -> void:
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
	Telemetry.note("contact", "step %d retargeted onto the nearest look-alike reached first"
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
## is what makes the distance check in `_track_first_reached()` exactly correct for a body with any
## solid clearance, by the same triangle the caller already checked when it found this candidate.
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
	_move_the_mark(nearest, here)

## The nearest `ALLEY` tile to `here` that is not closed, is walkable, and is not held, on the
## home block or inside a walled-off crossing alley (see `_pick_reachable`'s own doc — the M78
## relocation is the same placement question as the initial roll, asked again, and the same
## refusal has to hold or a mark could relocate into a sealed alley even though it is never placed
## there to start with), within `NOTICE_RADIUS` — or `Vector2.INF` if there is none. Linear over
## `tiles_of_type()`, which is already cached; there is one active mark at a time, so this runs
## once a frame at most.
##
## **Avoids a tile a completed step already used, the same rule and the same fallback
## `_pick_reachable()` applies to the dawn placement (M177):** the nearest eligible tile that is
## not in `GameState.completed_resistance_alley_tiles`, or the plain nearest eligible tile if
## avoiding them would leave nothing in reach at all — a relocation exists to keep the mark
## findable, and that guarantee outranks the avoidance.
func _nearest_alley_within(here: Vector2) -> Vector2:
	var walled_alleys := _walled_alleys()
	var used := GameState.completed_resistance_alley_tiles
	var nearest := Vector2.INF
	var nearest_distance := NOTICE_RADIUS
	var nearest_any := Vector2.INF
	var nearest_any_distance := NOTICE_RADIUS
	for tile in _map.tiles_of_type(GameEnums.TileType.ALLEY):
		if _map.is_closed(tile) or not _map.is_walkable(tile) \
				or _map.is_held_at(tile) or _map.is_on_home_block(tile) \
				or _map.is_in_walled_alley(tile, walled_alleys):
			continue
		var world := _map.tile_to_world(tile)
		var distance := here.distance_to(world)
		if distance < nearest_any_distance:
			nearest_any_distance = distance
			nearest_any = world
		if tile in used or distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest = world
	return nearest if nearest != Vector2.INF else nearest_any

## Moves an unseen mark to the alley she has just come near, and moves its guard with it —
## retiring the one standing over the old spot rather than leaving a robber with nothing
## left to guard.
func _move_the_mark(new_world: Vector2, here: Vector2) -> void:
	var old_tile := _map.world_to_tile(_contact.global_position)
	var new_tile := _map.world_to_tile(new_world)
	_contact.global_position = new_world
	Telemetry.note("contact", "step %d moved to %s: never seen at %s" % [
		_step.index, TelemetryLog.tile(new_tile), TelemetryLog.tile(old_tile)])
	if _guard and is_instance_valid(_guard):
		_city.events.retire(_guard)
		_guard = null
	_maybe_set_a_trap(_day, _rng, new_world, here)

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
	# A finished task is shown by the world, never by text: the man shouting she actually
	# reached — `_rider` after any retargeting in `_track_first_reached()` — stops shouting and
	# walks off screen, the same departure any finished event takes. Named by `task_event_id`
	# rather than "any rider with a completed step", so this call site does not start silently
	# giving the other perform steps a world-answer their own design has not chosen yet.
	if step and step.task_event_id == "homeless_yeller" and _rider and is_instance_valid(_rider):
		_rider.leave_for_a_completed_task()
		Telemetry.note("contact", "he took it and is leaving")
	# Day 12's once-only happening — the park she was sent to starts to close once she has
	# reached the swing — is a later slice's, on the same fork `_place_at_a_swing()` names: it
	# needs `EventScheduler`/`ClosurePlanner`, out of this slice's scope fence. This is the hook:
	# `step.target_kind == ResistanceSteps.TargetKind.PARK_SWING` is true exactly once, the
	# instant she reaches the swing, and nothing downstream of it is built yet.
	if not (step and step.needs_goal):
		return

	GameState.sabotage_done = true
	# The reward for the whole subquest is quiet. Whatever is left of the last day is walked with
	# every mast off — no field, no arcs — rather than under whatever each one happened to be
	# speaking when the sabotage landed.
	if _city and _city.events and _city.events.silence_all_masts() > 0:
		EventBus.city_went_quiet.emit()

func _clear() -> void:
	if _contact and is_instance_valid(_contact):
		_contact.queue_free()
	_contact = null
	_rider = null

# ------------------------------------------------------------------ queries ---

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
## man shouting, a roadblock) — the two tasks that never earn an arrow. *(PLAYTEST-117: "a red
## arrow (like the blue home arrow but red) to point to tasks where we need to go to a specific
## location ... unlike the yeller task where we can just go to any yeller".)*
func red_arrow_target() -> Vector2:
	var step := current_step()
	if step == null or step.is_pickup or not step.is_one_place:
		return Vector2.INF
	return contact_position()
