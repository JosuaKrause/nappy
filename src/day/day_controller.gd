class_name DayController
extends Node
## One day: the clock, the two phases, and the four ways a day can end.
##
## Owns no rules about *why* the baby is asleep or crying — it listens to EventBus and
## decides what that means for the day. See docs/DESIGN.md for the win/lose table.

signal day_finished(result: GameEnums.DayResult)

var phase := GameEnums.DayPhase.OVER
var time_remaining := 0.0
var time_total := 0.0
## Set when the day ends badly, for the summary screen to explain itself.
var failure_reason := ""

var _map: CityMap
var _player: Node2D
var _connected := false

func setup(map: CityMap, player: Node2D) -> void:
	_map = map
	_player = player
	if _connected:
		return
	_connected = true
	EventBus.return_phase_started.connect(_on_baby_asleep)
	EventBus.baby_state_changed.connect(_on_baby_state_changed)
	EventBus.hard_fail_triggered.connect(_on_hard_fail)

func start(length: float) -> void:
	time_total = length
	time_remaining = length
	phase = GameEnums.DayPhase.WALKING
	failure_reason = ""
	EventBus.day_time_changed.emit(time_remaining, time_total)

func stop() -> void:
	phase = GameEnums.DayPhase.OVER

## 1.0 at dawn, 0.0 at dusk. Drives the light.
func fraction_remaining() -> float:
	if time_total <= 0.0:
		return 1.0
	return clampf(time_remaining / time_total, 0.0, 1.0)

func is_running() -> bool:
	return phase != GameEnums.DayPhase.OVER

func _process(delta: float) -> void:
	if not is_running():
		return

	time_remaining -= delta
	EventBus.day_time_changed.emit(maxf(time_remaining, 0.0), time_total)
	if time_remaining <= 0.0:
		failure_reason = "Dusk. You are still out."
		_end(GameEnums.DayResult.LOST_TIMEOUT)
		return

	if phase == GameEnums.DayPhase.RETURNING and _is_home():
		_end(GameEnums.DayResult.WON)

func _is_home() -> bool:
	if not _map or not _player:
		return false
	return _map.tile_type_at_world(_player.global_position) == GameEnums.TileType.HOME

# ------------------------------------------------------------------- signals ---

func _on_baby_asleep() -> void:
	if phase == GameEnums.DayPhase.WALKING:
		phase = GameEnums.DayPhase.RETURNING
		# Falling asleep on the doorstep should not need a lap of the block to register.
		if _is_home():
			_end(GameEnums.DayResult.WON)

func _on_baby_state_changed(state: GameEnums.BabyState) -> void:
	if not is_running():
		return
	match state:
		GameEnums.BabyState.CRYING:
			failure_reason = "She started crying. There is no settling her now."
			_end(GameEnums.DayResult.LOST_CRYING)
		GameEnums.BabyState.AWAKE:
			# Woken on the way home: back to walking her down again.
			if phase == GameEnums.DayPhase.RETURNING:
				phase = GameEnums.DayPhase.WALKING

func _on_hard_fail(reason: String) -> void:
	if not is_running():
		return
	failure_reason = _HARD_FAIL_TEXT.get(reason, "It went wrong.")
	_end(GameEnums.DayResult.LOST_HARD_FAIL)

const _HARD_FAIL_TEXT := {
	"abduction": "The van door opened. Nobody saw where you went.",
	"alley_robbery": "They were waiting in the alley.",
	"firefight": "You walked into the middle of it.",
	# Not an event, and the only hard fail the player can walk into rather than be caught by.
	"car_strike": "It never slowed down. You were in the road.",
}

func _end(result: GameEnums.DayResult) -> void:
	if not is_running():
		return
	phase = GameEnums.DayPhase.OVER
	day_finished.emit(result)
