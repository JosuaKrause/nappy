class_name TitleScreen
extends CanvasLayer
## The screen the game opens on, and the screen a finished run goes back to.
##
## It answers the same problem from both ends. Without somewhere for a finished run to go, the only
## way out is to close the window — the ending offers `Esc`, `Esc` opens the pause, and the pause
## offers `Esc` and `Q`. And without it the game begins mid-stride, on the doorstep, with the day
## already running and no moment to read the two lines that say what the controls are.
##
## One screen answers both, because a run that is over goes back to where a run begins. There is
## deliberately no separate "restart" screen and no menu: this is a title, three lines of controls
## and a key.
##
## **What is behind it is the game, running.** Not a still, not a menu over black: the
## doorstep the run starts on, with the traffic driving and the events playing out on it and nobody
## pushing a pram through them. The screen itself is therefore only two scrims and four labels — the
## title across the top half, the controls across the bottom, and the street visible through both.
## `main._open_the_title()` is the half that makes the city keep moving while everything that is a
## *day* stops; this class owns two keys and nothing else.
##
## What it is not is a main menu. There are no options, no seed box and no load game, and none of
## those is what this screen exists for.

signal start_requested()
signal quit_requested()

@onready var _name: Label = $Root/Top/Lines/Title
@onready var _hint: Label = $Root/Bottom/Lines/Hint

## Whether `Q` does anything on this platform. Read once from `QuitOption` rather than asked at
## each use site, so a test — never itself a web export — can set this and drive both shapes.
var _can_quit := QuitOption.available()

func _ready() -> void:
	# **The title has a colour of its own**, or the screen is four labels in one warm off-white and
	# the name of the game is only the biggest of them. `Palette.TITLE_TEXT` is the doorstep it is
	# standing in front of; see the note there for why it is not one of the danger colours.
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
	var start := "space to walk again" if again else "space to begin"
	_hint.text = "%s     ·     q to quit" % start if _can_quit else start

func close() -> void:
	visible = false

## `Space` starts, and so does a tap — handled as the touch event itself rather than as a synthetic
## click, so a mouse is not taught a gesture nobody asked it to have and the desktop is unchanged.
## `Q` leaves, **except on the web**, where `QuitOption.available()` is false and the key is not
## offered or handled at all — pressing it on a platform where quitting is impossible would be a
## key the hint never even mentions doing nothing. `Esc` is deliberately not handled: `main` will
## not open the pause over this, because a pause over a game that has not started is a screen with
## nothing behind it to stop.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") \
			or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed):
		get_viewport().set_input_as_handled()
		start_requested.emit()
	elif _can_quit and event is InputEventKey and event.pressed \
			and (event as InputEventKey).keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		quit_requested.emit()
