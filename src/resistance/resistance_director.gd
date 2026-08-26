class_name ResistanceDirector
extends Node
## Places the day's resistance contact, and enforces the two things that make the subquest
## cost something: the alleys are sometimes a trap, and one of the steps expires.
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

	_step = ResistanceSteps.for_day(day, GameState.completed_resistance_steps,
			GameState.failed_resistance_steps, GameState.sabotage_available())
	if not _step:
		return

	var at := _place(rng)
	if at == Vector2.INF:
		push_warning("resistance step %d has nowhere to go in this city" % _step.index)
		_step = null
		return

	_contact = ContactPoint.new()
	_contact.setup(_step, at, _city.events)
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

func _place(rng: RandomNumberGenerator) -> Vector2:
	var candidates: Array[Vector2i] = []
	if _step.district >= 0:
		candidates = _map.purpose_tiles(_step.district as GameEnums.BlockPurpose)
	else:
		for type in _step.placement:
			candidates.append_array(_map.tiles_of_type(type as GameEnums.TileType))
	# A contact behind a closed street is a step the player cannot take today, and the
	# resistance has steps that expire — so this would silently cost a run its good ending.
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
	if _step.deadline_fraction <= 0.0 or _day_length <= 0.0:
		return
	if _elapsed / _day_length < _step.deadline_fraction:
		return
	# A warning delivered late is not a warning. The contact is gone for the rest of the run.
	_expired = true
	Telemetry.note("contact", "step %d expired at %.0f%% of the day; the contact is gone"
			% [_step.index, _step.deadline_fraction * 100.0])
	GameState.fail_resistance_step(_step.index)
	_clear()

func _on_contact_completed(step_index: int) -> void:
	Telemetry.note("contact", "step %d completed" % step_index)
	GameState.complete_resistance_step(step_index)
	var step := ResistanceSteps.by_index(step_index)
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

# ------------------------------------------------------------------ queries ---

## The step on offer today, or null.
func current_step() -> ResistanceSteps.Step:
	return _step if _contact and not _expired else null

func contact_position() -> Vector2:
	return _contact.global_position if _contact else Vector2.INF
