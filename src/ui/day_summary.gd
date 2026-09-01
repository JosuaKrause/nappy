extends CanvasLayer
## The screen between days, and the one at the end of a run.
##
## Also the pause: the tree is paused while this is up, so the city keeps its state and the
## day can simply be restarted rather than rebuilt.

signal continued()

@onready var _root: Control = $Root
@onready var _heading: Label = $Root/Center/Lines/Heading
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

## The one line on the ending screen that is not writing.
##
## Every ending title in this file is a **sentence out of the fiction** — *"You stop going out."*,
## *"Silence."* — which is right for what they are and is exactly why they do not read as the end
## of anything on their own. A run that has finished has to say so before it says anything else.
##
## **It is not the same word for all three, and that is a decision rather than the request being
## trimmed.** The screen the complaint came off is the `BAD` one, where the nerves ran out, and
## `GAME OVER` is what that is. Stamping it over a run somebody *won* would be telling them they
## lost. `THE END` is the same size, the same weight and the same job on the other two.
const _ENDING_HEADING := {
	GameEnums.Ending.BAD: "GAME OVER",
	GameEnums.Ending.NEUTRAL: "THE END",
	GameEnums.Ending.GOOD: "THE END",
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
	# Coloured here rather than in the scene so `Palette` stays the one place a runtime colour is
	# decided — which is what its own class comment asks for.
	_heading.add_theme_color_override("font_color", Palette.GAME_OVER)
	_root.hide()

func show_day(day: int, result: GameEnums.DayResult, reason: String, nerves: int) -> void:
	# A lost *day* is not the end of a run — there are nerves left, and the screen says so two lines
	# down. The heading belongs to the screen that ends the run and to nothing else.
	_heading.hide()
	_title.text = _DAY_TITLE.get(result, "The day ends.")
	var lines: Array[String] = ["Day %d of %d" % [day, Tuning.RUN_LENGTH_DAYS]]
	if reason != "":
		lines.append("")
		lines.append(reason)
	lines.append("")
	var retrying := result != GameEnums.DayResult.WON and nerves > 0
	if result == GameEnums.DayResult.WON:
		lines.append("You got her home.")
	else:
		lines.append("Nerves left: %s" % ("*".repeat(nerves) if nerves > 0 else "none"))
	# The calendar does not move on a loss, so the screen says so rather than leaving the player
	# to notice tomorrow that it is still today.
	if retrying:
		lines.append("You try day %d again." % day)
	# The only place the subquest is ever spelled out. In the world it is chalk on a wall.
	if GameState.has_joined_resistance():
		lines.append("")
		lines.append(_resistance_line())
	_body.text = "\n".join(lines)
	_hint.text = "space to try again" if retrying else "space to go on"
	_present()

## The tally, and — the mechanism rather than a courtesy — the chalk mark's own words once a
## pickup has just been touched. Read once and cleared: `GameState.pending_resistance_brief` is
## how she learns what tomorrow wants, since there is no marker anywhere else that would.
func _resistance_line() -> String:
	var lines: Array[String] = []
	if GameState.sabotage_available():
		lines.append("You have done enough. There is one more night.")
	else:
		var done := GameState.resistance_progress
		var lost := GameState.failed_resistance_steps.size()
		var line := "Errands run: %d of %d" % [done, Tuning.RESISTANCE_GOAL]
		if lost > 0:
			line += "   (%d contact%s lost)" % [lost, "" if lost == 1 else "s"]
		lines.append(line)
	if GameState.pending_resistance_brief != "":
		lines.append(GameState.pending_resistance_brief)
		GameState.pending_resistance_brief = ""
	return "\n".join(lines)

## The last screen of a run. `space` goes back to the title, which is where the next one begins.
##
## **Not `esc to quit`**, which is not true from here: `Esc` opens the pause, and the pause offers
## `Esc` and `Q`, so a finished run becomes a cycle between two screens with closing the window as
## the only way out. Space dismisses every other screen in the game, so it is the key this one owes
## rather than a new one.
func show_ending(ending: GameEnums.Ending) -> void:
	_heading.text = _ENDING_HEADING.get(ending, "THE END")
	_heading.show()
	_title.text = _ENDING_TITLE.get(ending, "The end.")
	_body.text = _ENDING_BODY.get(ending, "")
	_hint.text = "space to start again"
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
