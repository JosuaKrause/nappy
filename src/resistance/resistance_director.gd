class_name ResistanceDirector
extends Node
## Places the day's resistance contact, and enforces the two things that make the subquest
## cost something: every mark is guarded, and a timed step expires.
##
## Deterministic from the run seed and the day, like everything else, so an alley that was
## safe on day 9 of this run is safe on day 9 of this run every time you replay it. The
## pattern is learnable; that is the difference between risk and a coin flip.

## The day the first chalk mark can appear. Nothing is guarded before it, because nothing is
## offered before it.
const TRAP_FIRST_DAY := 4

## A mark is "seen" once its own world position has been inside the camera's view, and only
## then does it stop following the player. Below that, moving it only when she is this far
## from it is what turns *"placed but never on screen"* into *"placed just off screen"*
## rather than *"placed wherever is convenient right now"*.
##
## The camera sits on her at zoom 2 over a 1280x720 viewport, so the visible world is
## 640x360: 320px to the edge sideways, 180px vertically (docs/EVENTS.md, "Everything
## arrives from off screen"). The half-diagonal — the worst case, a corner of the screen —
## is `sqrt(320² + 180²)` ≈ 367px. 400px sits just past that, so a mark placed or re-placed
## at this distance walks into view rather than appearing in it, the same reasoning M77 uses
## to site every arrival off screen (docs/DECISIONS.md, M77). Smallest reading of the
## player's own sentence, open to overturn: a single constant here is one edit to move it.
const NOTICE_RADIUS := 400.0

var _city: City
var _map: CityMap
var _contact: ContactPoint
## The `EventInstance` a perform step's contact rides on. Null for a pickup or the finale,
## which sit on a bare tile instead.
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
## The `alley_robbery` standing by the current mark, from `TRAP_FIRST_DAY`. Tracked so a
## move can retire it and `_maybe_set_a_trap` a fresh one near wherever the mark goes.
var _guard: EventInstance
## The RNG `start_day()` was handed, kept rather than re-drawn so a guard spawned later —
## when the mark moves — still comes from the same day's stream a replay would reproduce.
var _rng: RandomNumberGenerator
var _player: Stroller

func setup(city: City, map: CityMap) -> void:
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
	_guard = null
	# A fresh attempt at the day starts without the package, whether this is the first try
	# or a retry after a nerve — see GameState.resistance_carrying_package.
	GameState.resistance_carrying_package = false

	_step = ResistanceSteps.for_day(day, GameState.completed_resistance_steps,
			GameState.failed_resistance_steps, GameState.sabotage_available())
	if not _step:
		return

	var at := _place(_step, rng)
	if at == Vector2.INF:
		push_warning("resistance step %d has nowhere to go in this city" % _step.index)
		_step = null
		return

	_contact = ContactPoint.new()
	if _step.task_event_id == "":
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
		var offset := _reachable_offset(_rider, rng)
		_contact.ride(_step, _rider, offset)
		at = _rider.global_position + offset
	_contact.completed.connect(_on_contact_completed)
	_city.add_entity(_contact)
	EventBus.resistance_contact_available.emit(_step.index)
	Telemetry.note("contact", "step %d on offer at %s" % [
		_step.index, TelemetryLog.tile(_map.world_to_tile(at))])

	_maybe_set_a_trap(day, rng, at)

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
	var guard_at := at + Vector2.RIGHT.rotated(angle) * distance
	Telemetry.note("roll", "chalk mark guarded: robber %.0fpx away (band %.0f-%.0f)"
			% [distance, min_distance, max_distance])
	_guard = _city.events.spawn_extra(robbery, guard_at)

## Clear of any obstruction the rider carries, in a direction the day's own RNG chose — a
## fixed offset rather than a re-rolled one, so a contact that has to clear a body sits at a
## learnable spot. Zero for a rider with no body at all, like the yeller.
func _reachable_offset(instance: EventInstance, rng: RandomNumberGenerator) -> Vector2:
	var clearance: float = instance.def.obstructs_radius
	if clearance <= 0.0:
		return Vector2.ZERO
	var distance := clearance + Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH
	return Vector2.RIGHT.rotated(rng.randf() * TAU) * distance

## Where a step's contact — or, for a perform step, the event it rides on — is sited.
## Pickup and perform steps both name tile types in `placement`; only the finale names a
## `district` instead.
func _place(step: ResistanceSteps.Step, rng: RandomNumberGenerator) -> Vector2:
	if step.district >= 0:
		return _pick_reachable(_map.purpose_tiles(step.district as GameEnums.BlockPurpose), rng)
	var candidates: Array[Vector2i] = []
	for type in step.placement:
		candidates.append_array(_map.tiles_of_type(type as GameEnums.TileType))
	return _pick_reachable(candidates, rng)

## A contact behind a closed street is a step the player cannot take today, and the
## resistance has steps that expire — so this would silently cost a run its good ending.
func _pick_reachable(candidates: Array[Vector2i], rng: RandomNumberGenerator) -> Vector2:
	var reachable: Array[Vector2i] = []
	for tile in candidates:
		if not _map.is_closed(tile):
			reachable.append(tile)
	if reachable.is_empty():
		return Vector2.INF
	return _map.tile_to_world(reachable[rng.randi_range(0, reachable.size() - 1)])

func _process(delta: float) -> void:
	if not _step or _expired or not _contact or _contact.is_done:
		return
	_elapsed += delta
	if _rider and not _contact.rider_alive():
		_expire("lost its contact when the thing it rode on finished")
		return
	# Perform steps ride on their own `EventInstance` and the finale sits in a district;
	# neither is a chalk mark, so only a pickup is ever subject to the re-placement rule.
	if _step.is_pickup:
		_track_sight_and_reposition()
	if _step.deadline_fraction <= 0.0 or _day_length <= 0.0:
		return
	if _elapsed / _day_length < _step.deadline_fraction:
		return
	_expire("expired at %.0f%% of the day" % (_step.deadline_fraction * 100.0))

## "A mark that was never on screen was never placed" — playtest 19, verbatim. Seen is
## sticky for the day: once `_sight` has answered true for the mark's own position it never
## moves again, however far she walks from it afterwards.
##
## While unseen, walking away from it is corrected rather than left standing where she can
## no longer find it: if she is further than `NOTICE_RADIUS` from the mark and a reachable
## alley tile is within `NOTICE_RADIUS` of her, the mark jumps to the nearest one — the
## alley's own mouth, which is "on the path where the player can see it". Staying within the
## mark's own radius does nothing, which is the hysteresis that stops it chasing her step by
## step.
func _track_sight_and_reposition() -> void:
	if _seen:
		return
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Stroller
	var at := _contact.global_position
	if _sight.is_valid() and _sight.call(at):
		_seen = true
		Telemetry.note("contact", "step %d seen at %s" % [
			_step.index, TelemetryLog.tile(_map.world_to_tile(at))])
		return
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

## The nearest `ALLEY` tile to `here` that is not closed and is walkable, within
## `NOTICE_RADIUS` — or `Vector2.INF` if there is none. Linear over `tiles_of_type()`, which
## is already cached; there is one active mark at a time, so this runs once a frame at most.
func _nearest_alley_within(here: Vector2) -> Vector2:
	var nearest := Vector2.INF
	var nearest_distance := NOTICE_RADIUS
	for tile in _map.tiles_of_type(GameEnums.TileType.ALLEY):
		if _map.is_closed(tile) or not _map.is_walkable(tile):
			continue
		var world := _map.tile_to_world(tile)
		var distance := here.distance_to(world)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = world
	return nearest

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

func _on_contact_completed(step_index: int) -> void:
	Telemetry.note("contact", "step %d completed" % step_index)
	var step := ResistanceSteps.by_index(step_index)
	GameState.complete_resistance_step(step_index, step == null or step.grants_progress)
	if step and step.applies_package_weight:
		GameState.resistance_carrying_package = true
		Telemetry.note("contact", "the package is heavier now; the rest of today costs more")
	if not (step and step.needs_goal):
		return

	GameState.sabotage_done = true
	# The reward for the whole subquest is quiet. Whatever is left of the last day is
	# walked without the floor the masts have been holding under the meter since day 5.
	if _city and _city.events and _city.events.silence_city_wide() > 0:
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
