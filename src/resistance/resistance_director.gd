class_name ResistanceDirector
extends Node
## Places the day's resistance contact, and enforces the two things that make the subquest
## cost something: the alleys are sometimes a trap, and a timed step expires.
##
## Deterministic from the run seed and the day, like everything else, so an alley that was
## safe on day 9 of this run is safe on day 9 of this run every time you replay it. The
## pattern is learnable; that is the difference between risk and a coin flip.

## Chance that an alley contact has a robbery waiting at it instead of a friend.
## Only from Act III, when alleys stop being merely unpleasant.
const TRAP_CHANCE := 0.3
const TRAP_FIRST_DAY := 8

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

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map

func start_day(day: int, rng: RandomNumberGenerator, day_length: float) -> void:
	_clear()
	_elapsed = 0.0
	_day_length = day_length
	_expired = false
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

## The alley roulette. The contact is still there — the robbery is waiting at it. Going for
## the step is the gamble, which is the point: the resistance costs you the thing you are
## trying to protect.
func _maybe_set_a_trap(day: int, rng: RandomNumberGenerator, at: Vector2) -> void:
	if day < TRAP_FIRST_DAY or _step.district >= 0:
		return
	# Hoisted so the roll can be written down. Which alleys were a trap is the third of the
	# random outcomes that branch a run, and the only one whose consequence — the day the
	# player lost to a robbery — otherwise looks like bad luck with the event scheduler.
	var roll := rng.randf()
	if roll >= TRAP_CHANCE:
		Telemetry.note("roll", "alley trap: %.2f >= %.2f — the contact is a friend"
				% [roll, TRAP_CHANCE])
		return
	var robbery := EventCatalogue.by_id("alley_robbery")
	if robbery:
		Telemetry.note("roll", "alley trap: %.2f < %.2f — a robbery is waiting at the contact"
				% [roll, TRAP_CHANCE])
		_city.events.spawn_extra(robbery, at)

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
	if _step.deadline_fraction <= 0.0 or _day_length <= 0.0:
		return
	if _elapsed / _day_length < _step.deadline_fraction:
		return
	_expire("expired at %.0f%% of the day" % (_step.deadline_fraction * 100.0))

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
