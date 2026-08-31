class_name TitleScreen
extends CanvasLayer
## The screen the game opens on, and the screen a finished run goes back to. *(M38.)*
##
## Two complaints, and they are the same one from both ends. *"The lost screen doesn't allow for
## restarting the game — you can just cycle between pause screen and loss screen at that point"*:
## the ending said `esc to quit`, `Esc` opened the pause, and the pause offered `Esc` and `Q`, so the
## only way out of a finished run was to close the window. And *"start on the pause screen, or
## create a game open screen"*: the game began mid-stride, on the doorstep, with the day already
## running and no moment to read the two lines that say what the controls are.
##
## One screen answers both, because a run that is over goes back to where a run begins. There is
## deliberately no separate "restart" screen and no menu: this is a title, three lines of controls
## and a key.
##
## **What is behind it is the game, running.** *("As title screen just use the home and street in
## front without player and let act I events play out.")* Not a still, not a menu over black: the
## doorstep the run starts on, with the traffic driving and the events playing out on it and nobody
## pushing a pram through them. The screen itself is therefore only two scrims and four labels — the
## title across the top half, the controls across the bottom, and the street visible through both.
## `main._open_the_title()` is the half that makes the city keep moving while everything that is a
## *day* stops; this class owns two keys and nothing else.
##
## What it is not is a main menu. `docs/TODO.md` has carried "there is no main menu" under
## known-shaky ground since M6 and it still does — options, a seed box and a load game are all still
## missing, and none of them is what either complaint was about.

signal start_requested()
signal quit_requested()

@onready var _name: Label = $Root/Top/Lines/Title
@onready var _hint: Label = $Root/Bottom/Lines/Hint

func _ready() -> void:
	# **The title has a colour of its own.** *(Playtest 15, finding 6: "on the title screen change
	# up the color of the game title".)* It was the same warm off-white as the line under it and the
	# controls below that, so the screen was four labels in one colour and the name of the game was
	# only the biggest of them. `Palette.TITLE_TEXT` is the doorstep it is standing in front of; see
	# the note there for why it is not one of the danger colours.
	_name.add_theme_color_override("font_color", Palette.TITLE_TEXT)
	# Above the pause screen: this is the outermost frame the game runs inside, and nothing should
	# ever be able to cover it.
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func is_open() -> bool:
	return visible

## Shows the screen. `again` is whether a run has just ended, which is the only difference between
## the two times it is shown.
##
## It does **not** touch `get_tree().paused`, which is where it differs from `PauseScreen` and why:
## a pause stops the world and this one deliberately does not. What stops, and what carries on
## behind the scrims, is `main`'s decision — see `main._open_the_title()`.
func open(again := false) -> void:
	visible = true
	_hint.text = "space to walk again     ·     q to quit" if again \
			else "space to begin     ·     q to quit"

func close() -> void:
	visible = false

## `Space` starts, `Q` leaves. `Esc` is deliberately not handled: `main` will not open the pause over
## this, because a pause over a game that has not started is a screen with nothing behind it to stop.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		start_requested.emit()
	elif event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		quit_requested.emit()
