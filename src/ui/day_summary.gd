extends CanvasLayer
## The screen between days, and the one at the end of a run.
##
## Also the pause: the tree is paused while this is up, so the city keeps its state and the
## day can simply be restarted rather than rebuilt.

signal continued()

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Center/Lines/Title
@onready var _body: Label = $Root/Center/Lines/Body
@onready var _hint: Label = $Root/Center/Lines/Hint

const _DAY_TITLE := {
	GameEnums.DayResult.WON: "She's asleep.",
	GameEnums.DayResult.LOST_CRYING: "Not tonight.",
	GameEnums.DayResult.LOST_TIMEOUT: "Too late.",
	GameEnums.DayResult.LOST_HARD_FAIL: "The day ends here.",
}

const _ENDING_TITLE := {
	GameEnums.Ending.BAD: "You stop going out.",
	GameEnums.Ending.NEUTRAL: "The city is quiet now.",
	GameEnums.Ending.GOOD: "Silence.",
}

const _ENDING_BODY := {
	GameEnums.Ending.BAD:
		"There is nothing left in you for another walk.\n"
		+ "The city goes on without the two of you in it.",
	GameEnums.Ending.NEUTRAL:
		"She sleeps through most nights now.\n"
		+ "The streets you learned to avoid are empty of everything worth avoiding.\n"
		+ "Nobody is out.",
	GameEnums.Ending.GOOD:
		"The loudspeakers cut out mid-sentence.\n"
		+ "For the first time since the masts went up, you walk home in the quiet.",
}

func _ready() -> void:
	# The summary has to keep running while it pauses everything behind it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.hide()

func show_day(day: int, result: GameEnums.DayResult, reason: String, nerves: int) -> void:
	_title.text = _DAY_TITLE.get(result, "The day ends.")
	var lines: Array[String] = ["Day %d of %d" % [day, Tuning.RUN_LENGTH_DAYS]]
	if reason != "":
		lines.append("")
		lines.append(reason)
	lines.append("")
	if result == GameEnums.DayResult.WON:
		lines.append("You got her home.")
	else:
		lines.append("Nerves left: %s" % ("*".repeat(nerves) if nerves > 0 else "none"))
	# The only place the subquest is ever spelled out. In the world it is chalk on a wall.
	if GameState.has_joined_resistance():
		lines.append("")
		lines.append(_resistance_line())
	_body.text = "\n".join(lines)
	_hint.text = "space to go on"
	_present()

func _resistance_line() -> String:
	var done := GameState.resistance_progress
	if GameState.sabotage_available():
		return "You have done enough. There is one more night."
	var lost := GameState.failed_resistance_steps.size()
	var line := "Errands run: %d of %d" % [done, Tuning.RESISTANCE_GOAL]
	if lost > 0:
		line += "   (%d contact%s lost)" % [lost, "" if lost == 1 else "s"]
	return line

func show_ending(ending: GameEnums.Ending) -> void:
	_title.text = _ENDING_TITLE.get(ending, "The end.")
	_body.text = _ENDING_BODY.get(ending, "")
	_hint.text = "esc to quit"
	_present()

func _present() -> void:
	_root.show()
	get_tree().paused = true

func dismiss() -> void:
	_root.hide()
	get_tree().paused = false

func is_showing() -> bool:
	return _root.visible

func _unhandled_input(event: InputEvent) -> void:
	if is_showing() and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		continued.emit()
