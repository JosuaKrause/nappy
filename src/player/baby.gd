class_name Baby
extends Node
## The two meters and the sleep state machine. See docs/MECHANICS.md.
##
## This node knows about exactly two things: the rig it rides in (for speed) and the
## WorldContext (for how loud it is here). It has no idea what an event or a tile is, so
## new event types in M4-M7 never require touching this file.

signal fell_asleep()
signal woke_up()
signal started_crying()

## Debug affordance: lets the debug world start a session mid-way for UI checks.
@export_range(0.0, 100.0) var starting_sleepiness := 0.0

var sleepiness := 0.0
var excitement := 0.0
var state := GameEnums.BabyState.AWAKE

## Last frame's breakdown, for the debug overlay.
var last_incoming := 0.0
var last_decay := 0.0

var _stroller: Stroller
var _world: WorldContext

func _ready() -> void:
	add_to_group("baby")
	_stroller = get_parent() as Stroller
	assert(_stroller != null, "Baby must be a child of the Stroller rig")
	_world = get_tree().get_first_node_in_group("world") as WorldContext
	sleepiness = starting_sleepiness

func _physics_process(delta: float) -> void:
	if state == GameEnums.BabyState.CRYING:
		return

	var here := _stroller.global_position
	var in_calm_zone := _world.is_calm_zone(here) if _world else false
	var in_alley := _world.is_alley(here) if _world else false

	_update_excitement(delta, here, in_calm_zone, in_alley)
	_update_sleepiness(delta, in_calm_zone)
	_update_state()

# --------------------------------------------------------------- excitement ---

func _update_excitement(delta: float, here: Vector2, in_calm_zone: bool, in_alley: bool) -> void:
	var incoming := _world.total_excitement_at(here) if _world else 0.0
	incoming += Tuning.EXCITEMENT_FROM_RUNNING * _stroller.run_excess_ratio()
	if in_alley:
		incoming += Tuning.EXCITEMENT_FROM_ALLEY
	# A sleeping baby is harder to disturb, but not immune.
	if state == GameEnums.BabyState.ASLEEP:
		incoming *= Tuning.SLEEPING_SENSITIVITY

	var decay := _decay_rate(in_calm_zone)
	last_incoming = incoming
	last_decay = decay

	# Net rate, so that decay always counts: standing still fights a loud event, and
	# sprinting past one (decay ~0) makes it far worse than walking past it.
	var before := excitement
	excitement = clampf(excitement + (incoming - decay) * delta, 0.0, Tuning.METER_MAX)
	if not is_equal_approx(before, excitement):
		EventBus.excitement_changed.emit(excitement)

func _decay_rate(in_calm_zone: bool) -> float:
	var rate := Tuning.EXCITEMENT_DECAY_WALKING
	if _stroller.is_idle():
		rate = Tuning.EXCITEMENT_DECAY_IDLE
	elif _stroller.run_excess_ratio() > 0.0:
		rate = Tuning.EXCITEMENT_DECAY_RUNNING
	if in_calm_zone:
		rate *= Tuning.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER
	return rate

# --------------------------------------------------------------- sleepiness ---

func _update_sleepiness(delta: float, in_calm_zone: bool) -> void:
	if state == GameEnums.BabyState.ASLEEP:
		return

	var before := sleepiness
	if excitement >= Tuning.EXCITEMENT_CALM_THRESHOLD:
		# Too interested in the world to settle — frozen, but it does not slip back either.
		pass
	elif _stroller.is_idle():
		sleepiness -= Tuning.SLEEPINESS_DRAIN_IDLE * delta
	elif _stroller.run_excess_ratio() > 0.0:
		# Never fills while running, at any excitement level.
		pass
	else:
		var gain := Tuning.SLEEPINESS_GAIN_WALKING
		if in_calm_zone:
			gain *= Tuning.SLEEPINESS_CALM_ZONE_MULTIPLIER
		sleepiness += gain * delta

	sleepiness = clampf(sleepiness, 0.0, Tuning.METER_MAX)
	if not is_equal_approx(before, sleepiness):
		EventBus.sleepiness_changed.emit(sleepiness)

# -------------------------------------------------------------------- state ---

func _update_state() -> void:
	if excitement >= Tuning.METER_MAX:
		_set_state(GameEnums.BabyState.CRYING)
		started_crying.emit()
		return

	match state:
		GameEnums.BabyState.AWAKE:
			if sleepiness >= Tuning.METER_MAX:
				_set_state(GameEnums.BabyState.ASLEEP)
				fell_asleep.emit()
				EventBus.return_phase_started.emit()
		GameEnums.BabyState.ASLEEP:
			if excitement >= Tuning.EXCITEMENT_WAKE_THRESHOLD:
				sleepiness = Tuning.WAKE_SLEEPINESS_PENALTY
				EventBus.sleepiness_changed.emit(sleepiness)
				_set_state(GameEnums.BabyState.AWAKE)
				woke_up.emit()

func _set_state(next: GameEnums.BabyState) -> void:
	if state == next:
		return
	state = next
	EventBus.baby_state_changed.emit(state)

# ------------------------------------------------------------------ queries ---

## Why sleepiness is not currently rising, or "" if it is. Drives the HUD hint.
func stall_reason() -> String:
	if state == GameEnums.BabyState.ASLEEP:
		return ""
	if excitement >= Tuning.EXCITEMENT_CALM_THRESHOLD:
		return "too excited"
	if _stroller.is_idle():
		return "standing still"
	if _stroller.run_excess_ratio() > 0.0:
		return "running"
	return ""
