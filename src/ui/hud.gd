extends CanvasLayer
## Meters, baby state and the run header.
##
## Meter values arrive over EventBus, so the HUD never holds a reference to the world or
## the event system. The one direct reference is to the Baby, for `stall_reason()` — a
## coaching hint that needs to ask "why", which a value signal cannot answer.

@onready var _sleepiness: MeterBar = $Meters/Sleepiness
@onready var _excitement: MeterBar = $Meters/Excitement
@onready var _state_label: Label = $Meters/State
@onready var _header: Label = $Header

var _baby: Baby

const _STATE_TEXT := {
	GameEnums.BabyState.AWAKE: "awake",
	GameEnums.BabyState.ASLEEP: "asleep - go home",
	GameEnums.BabyState.CRYING: "crying - day lost",
}

func _ready() -> void:
	_sleepiness.label = "SLEEPINESS"
	_sleepiness.fill_colour = Color("4a5f9e")
	_sleepiness.full_colour = Color("8fb4d9")

	_excitement.label = "EXCITEMENT"
	_excitement.fill_colour = Color("d9a648")
	_excitement.full_colour = Color("cf4436")
	_excitement.markers = [Tuning.EXCITEMENT_CALM_THRESHOLD, Tuning.EXCITEMENT_WAKE_THRESHOLD]

	EventBus.sleepiness_changed.connect(_on_sleepiness_changed)
	EventBus.excitement_changed.connect(_on_excitement_changed)
	EventBus.baby_state_changed.connect(_on_baby_state_changed)
	EventBus.nerves_changed.connect(func(_n: int) -> void: _refresh_header())

	_baby = get_tree().get_first_node_in_group("baby") as Baby
	if _baby:
		_sleepiness.value = _baby.sleepiness
		_excitement.value = _baby.excitement
	_refresh_header()
	_refresh_state()

func _process(_delta: float) -> void:
	_refresh_state()

func _on_sleepiness_changed(value: float) -> void:
	_sleepiness.value = value

func _on_excitement_changed(value: float) -> void:
	_excitement.value = value

func _on_baby_state_changed(_state: GameEnums.BabyState) -> void:
	_refresh_state()

func _refresh_state() -> void:
	if not _baby:
		return
	var text: String = _STATE_TEXT.get(_baby.state, "?")
	var reason := _baby.stall_reason()
	if reason != "":
		text += "   (not settling: %s)" % reason
	_state_label.text = text

func _refresh_header() -> void:
	_header.text = "day %d / %d      act %d      nerves %s" % [
		GameState.day, Tuning.RUN_LENGTH_DAYS, GameState.current_act(),
		"*".repeat(GameState.nerves) if GameState.nerves > 0 else "-",
	]
