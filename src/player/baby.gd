class_name Baby
extends Node
## The two meters and the sleep state machine. See docs/MECHANICS.md.
##
## This node knows about exactly two things: the rig it rides in (for speed) and the
## WorldContext (for how loud it is here). It has no idea what an event or a tile is, so a new
## kind of event never requires touching this file.

## Debug affordance: lets the debug world start a session mid-way for UI checks.
@export_range(0.0, 100.0) var starting_sleepiness := 0.0

## What the pram is saying about her.
##
## Four states and no gauge. Every other cue in `docs/EVENTS.md` says something about the *world* —
## a thing is dangerous, something is coming, this spot is about to be bad — and none of them says
## anything about the baby, who is the only thing the player is trying to change. Two bars
## in the corner of a game whose camera is on the pram asks a person to read a number about the
## thing they are looking at from somewhere else on the screen.
##
## The two rules it is built to, both from the **cues** skill's standing decisions:
##
## - **Stages, not a gauge.** A meter drawn over her head is the HUD moved. What earns a place
##   in the vocabulary is a small number of states, each of which is a different instruction:
##   *the day has stopped progressing*, *the day is about to end*, *you are on the way home*,
##   *she is about to wake and it will cost you half the bar*.
## - **It is not the exclamation mark.** That one means "this will end your day" and means only
##   that. Different shape, different anchor — the pram, not her head — and `Stroller` keeps them
##   out of each other's way when the pram is behind her.
enum Cue {
	NONE,
	## Over the calm threshold and awake: sleepiness is frozen, so the day is not progressing.
	UNSETTLED,
	## Close enough to `METER_MAX` that the next loud thing ends the day.
	NEARLY_CRYING,
	## Asleep. The one state with the most consequence attached and the least on-screen presence.
	ASLEEP,
	## Asleep and nearly awake again, which costs `WAKE_SLEEPINESS_PENALTY`.
	STIRRING,
}

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

## Back to the start of a day. The baby does not carry yesterday's mood.
func reset() -> void:
	sleepiness = starting_sleepiness
	excitement = 0.0
	last_incoming = 0.0
	last_decay = 0.0
	_set_state(GameEnums.BabyState.AWAKE)
	EventBus.sleepiness_changed.emit(sleepiness)
	EventBus.excitement_changed.emit(excitement)

## Dev affordance: straight to sleep, so the return phase and the way home can be
## inspected without walking the whole meter up first.
func force_sleep() -> void:
	sleepiness = Tuning.METER_MAX
	EventBus.sleepiness_changed.emit(sleepiness)
	_set_state(GameEnums.BabyState.ASLEEP)
	EventBus.return_phase_started.emit()

func _physics_process(delta: float) -> void:
	if state == GameEnums.BabyState.CRYING:
		return

	var here := _stroller.global_position
	var calm_gain := _world.sleepiness_multiplier(here) if _world else 1.0
	var in_alley := _world.is_alley(here) if _world else false

	_update_excitement(delta, here, in_alley)
	_update_sleepiness(delta, calm_gain)
	_update_state()

# --------------------------------------------------------------- excitement ---

func _update_excitement(delta: float, here: Vector2, in_alley: bool) -> void:
	var incoming := _world.total_excitement_at(here) if _world else 0.0
	incoming += Tuning.EXCITEMENT_FROM_RUNNING * _stroller.run_excess_ratio()
	if in_alley:
		incoming += Tuning.EXCITEMENT_FROM_ALLEY
	# A sleeping baby is harder to disturb, but not immune.
	if state == GameEnums.BabyState.ASLEEP:
		incoming *= Tuning.SLEEPING_SENSITIVITY

	var decay := _decay_rate()
	last_incoming = incoming
	last_decay = decay

	# Net rate, so that decay always counts: standing still fights a loud event, and
	# sprinting past one (decay ~0) makes it far worse than walking past it.
	var before := excitement
	excitement = clampf(excitement + (incoming - decay) * delta, 0.0, Tuning.METER_MAX)
	if not is_equal_approx(before, excitement):
		EventBus.excitement_changed.emit(excitement)

## How fast the meter falls: what she is doing, times what she is standing on.
##
## The ground half is a **rate** the world answers with rather than a bool — calm, precinct,
## ordinary street, main road, best to worst. The two halves multiply rather than adding, so
## *walking somewhere better* is always worth something and running is always worth little,
## whichever ground she does it on.
func _decay_rate() -> float:
	var rate := Tuning.EXCITEMENT_DECAY_WALKING
	if _stroller.is_idle():
		rate = Tuning.EXCITEMENT_DECAY_IDLE
	elif _stroller.run_excess_ratio() > 0.0:
		rate = Tuning.EXCITEMENT_DECAY_RUNNING
	return rate * _world.decay_multiplier(_stroller.global_position)

# --------------------------------------------------------------- sleepiness ---

func _update_sleepiness(delta: float, calm_gain: float) -> void:
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
		# One multiplier rather than a branch: the ground answers with a **rate** —
		# 1.0 anywhere ordinary, more on calm, more again on a calm area that is one block — so
		# there is nothing here to ask about what kind of place she is standing in.
		sleepiness += Tuning.SLEEPINESS_GAIN_WALKING * calm_gain * delta

	sleepiness = clampf(sleepiness, 0.0, Tuning.METER_MAX)
	if not is_equal_approx(before, sleepiness):
		EventBus.sleepiness_changed.emit(sleepiness)

# -------------------------------------------------------------------- state ---

func _update_state() -> void:
	if excitement >= Tuning.METER_MAX:
		_set_state(GameEnums.BabyState.CRYING)
		return

	match state:
		GameEnums.BabyState.AWAKE:
			if sleepiness >= Tuning.METER_MAX:
				_set_state(GameEnums.BabyState.ASLEEP)
				EventBus.return_phase_started.emit()
		GameEnums.BabyState.ASLEEP:
			if excitement >= Tuning.EXCITEMENT_WAKE_THRESHOLD:
				sleepiness = Tuning.WAKE_SLEEPINESS_PENALTY
				EventBus.sleepiness_changed.emit(sleepiness)
				_set_state(GameEnums.BabyState.AWAKE)

func _set_state(next: GameEnums.BabyState) -> void:
	if state == next:
		return
	state = next
	EventBus.baby_state_changed.emit(state)

# ------------------------------------------------------------------ queries ---

## Which of the four states the pram is showing, or `NONE` while there is nothing to say.
##
## A pure query, like everything else the rig asks of the baby: the drawing lives in `Stroller`
## because the rig draws itself, and the decision lives here because this is where the meters
## are. Nothing about it is a threshold `_update_state()` does not already turn the day on.
func cue() -> Cue:
	match state:
		GameEnums.BabyState.CRYING:
			return Cue.NEARLY_CRYING
		GameEnums.BabyState.ASLEEP:
			if excitement >= Tuning.EXCITEMENT_WAKE_THRESHOLD - Tuning.EXCITEMENT_STIR_MARGIN:
				return Cue.STIRRING
			return Cue.ASLEEP
	if excitement >= Tuning.EXCITEMENT_NEARLY_CRYING:
		return Cue.NEARLY_CRYING
	if excitement >= Tuning.EXCITEMENT_CALM_THRESHOLD:
		return Cue.UNSETTLED
	return Cue.NONE

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
