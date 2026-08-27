extends CanvasLayer
## Meters, baby state and the run header.
##
## Meter values arrive over EventBus, so the HUD never holds a reference to the world or
## the event system. The one direct reference is to the Baby, for `stall_reason()` — a
## coaching hint that needs to ask "why", which a value signal cannot answer.

@onready var _sleepiness: MeterBar = $Meters/Sleepiness
@onready var _excitement: MeterBar = $Meters/Excitement
@onready var _state_label: Label = $Meters/State
@onready var _resistance_label: Label = $Meters/Resistance
@onready var _header: Label = $Header
@onready var _clock: Label = $Clock
@onready var _home_arrow: HomeArrow = $HomeArrow

var _baby: Baby
var _contact_step := 0
var _hold := 0.0
var _seen_for := 0.0
var _announcement := ""
var _announcement_for := 0.0
## What is holding a floor under the whole city, or "" for nothing. M22: this is the only cue
## for a source with no position, and until it existed the loudspeaker masts held the meter up
## from day 5 with nothing on screen to say why.
var _city_wide := ""

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
	EventBus.day_started.connect(func(_d: int) -> void: _refresh_header())
	EventBus.day_time_changed.connect(_on_day_time_changed)
	EventBus.resistance_progress_changed.connect(func(_v: int) -> void: _refresh_resistance())
	EventBus.resistance_contact_available.connect(_on_contact_available)
	EventBus.resistance_hold_changed.connect(_on_hold_changed)
	EventBus.resistance_seen.connect(_on_seen)
	EventBus.city_went_quiet.connect(_on_city_went_quiet)
	EventBus.city_wide_changed.connect(_on_city_wide_changed)
	EventBus.day_started.connect(func(_d: int) -> void:
		_contact_step = 0
		_hold = 0.0
		_seen_for = 0.0
		_refresh_resistance())

	_baby = get_tree().get_first_node_in_group("baby") as Baby
	if _baby:
		_sleepiness.value = _baby.sleepiness
		_excitement.value = _baby.excitement
	_refresh_header()
	_refresh_state()
	_refresh_resistance()

func _process(delta: float) -> void:
	_refresh_state()
	if _seen_for > 0.0:
		_seen_for = maxf(0.0, _seen_for - delta)
		_refresh_resistance()
	if _announcement_for > 0.0:
		_announcement_for = maxf(0.0, _announcement_for - delta)

func _on_sleepiness_changed(value: float) -> void:
	_sleepiness.value = value

func _on_excitement_changed(value: float) -> void:
	_excitement.value = value

func _on_baby_state_changed(_state: GameEnums.BabyState) -> void:
	_refresh_state()

func _refresh_state() -> void:
	if not _baby:
		return
	if _announcement_for > 0.0:
		_state_label.text = _announcement
		return
	var text: String = _STATE_TEXT.get(_baby.state, "?")
	var reason := _baby.stall_reason()
	if reason != "":
		text += "   (not settling: %s)" % reason
	# Last, and phrased as a place rather than as a source: a player cannot walk away from this
	# one, and the useful thing to tell them is that walking away is not the move.
	if _city_wide != "":
		text += "   [%s - nowhere is quiet]" % _city_wide.to_lower()
	_state_label.text = text

func _on_day_time_changed(remaining: float, total: float) -> void:
	_clock.text = "%d:%02d" % [int(remaining) / 60, int(remaining) % 60]
	# The last minute is the one worth panicking about.
	var urgent := remaining < 60.0 and total > 0.0
	_clock.modulate = Color("e5765f") if urgent else Color(1, 1, 1)

func _on_contact_available(step: int) -> void:
	_contact_step = step
	_refresh_resistance()

func _on_hold_changed(progress: float) -> void:
	if is_equal_approx(progress, _hold):
		return
	_hold = progress
	_refresh_resistance()

func _on_seen() -> void:
	_seen_for = 2.5
	_refresh_resistance()

## Deliberately terse. There is no quest log — the subquest is chalk on a wall, and the HUD
## says only how far in you are and, while you are actually holding, how much is left.
func _refresh_resistance() -> void:
	if not GameState.has_joined_resistance() and _contact_step == 0:
		_resistance_label.text = ""
		return

	var marks := "*".repeat(GameState.resistance_progress) \
			+ ".".repeat(maxi(0, Tuning.RESISTANCE_GOAL - GameState.resistance_progress))
	var line := "resistance %s" % marks
	if _seen_for > 0.0:
		line += "   seen - wait for it to pass"
	elif _hold > 0.0:
		line += "   holding %d%%" % roundi(_hold * 100.0)
	elif _contact_step > 0:
		var step := ResistanceSteps.by_index(_contact_step)
		if step:
			line += "   somewhere out there: %s" % step.title.to_lower()
	_resistance_label.text = line

## The one moment the game says something out loud.
## Shown only while she is carrying a sleeping baby home.
func set_home_guidance(showing: bool, home: Vector2) -> void:
	if showing:
		_home_arrow.show_toward(home)
	else:
		_home_arrow.hide_arrow()

func _on_city_wide_changed(what: String) -> void:
	_city_wide = what
	_refresh_state()

func _on_city_went_quiet() -> void:
	_announcement = "The loudspeakers cut out mid-sentence."
	_announcement_for = 7.0
	_refresh_state()

func _refresh_header() -> void:
	_header.text = "day %d / %d      act %d      nerves %s" % [
		GameState.day, Tuning.RUN_LENGTH_DAYS, GameState.current_act(),
		"*".repeat(GameState.nerves) if GameState.nerves > 0 else "-",
	]
