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
## pushing a pram through them. The screen itself is therefore only two scrims and a handful of
## labels: the title across the top half, the controls across the bottom, and the street visible
## through both. `main._open_the_title()` is the half that makes the city keep moving while
## everything that is a *day* stops; this class owns one key and nothing else.
##
## What it is not is a main menu. There are no options, no seed box and no load game, and none of
## those is what this screen exists for.
##
## **There is one control scheme, so there is no question to ask.** A press — a tap, a mouse click
## or `space` — begins the run in it.

signal start_requested()
signal quit_requested()

@onready var _root: Control = $Root
@onready var _name: Label = $Root/Top/Lines/Title
@onready var _body: Label = $Root/Bottom/Lines/Body
@onready var _hint: Label = $Root/Bottom/Lines/Hint
@onready var _version: Label = $Root/Version

## Whether `Q` does anything on this platform. Read once from `QuitOption` rather than asked at
## each use site, so a test — never itself a web export — can set this and drive both shapes.
## Gates only whether the key is **handled** in `_unhandled_input()` below; it no longer names
## itself on screen — see `open()`'s own doc.
var _can_quit := QuitOption.available()

## One body for every device — see `PauseScreen._BODY`'s own doc for the same collapse made
## there. *(2026-09-06, the player: "in fact I said to remove the keyboard inputs altogether but
## I'm willing to compromise on letting them stay silently".)* The keyboard still walks and runs;
## nothing on screen names a key for it any more. `TouchInput.available()` used to choose between
## this and a keyboard body — with only one body left, this screen has no more use for that fact
## and keeps no member for it.
const _BODY := "Tap to walk that way, tap her to stop, double tap to run.\n" \
		+ "Walk to calm ground and stay moving; standing still settles nothing."

func _ready() -> void:
	# **The title has a colour of its own**, or the screen is four labels in one warm off-white and
	# the name of the game is only the biggest of them. `Palette.TITLE_TEXT` is the doorstep it is
	# standing in front of; see the note there for why it is not one of the danger colours.
	_name.add_theme_color_override("font_color", Palette.TITLE_TEXT)
	_refresh_body()
	_version.text = version_text()
	# Above the pause screen: this is the outermost frame the game runs inside, and nothing should
	# ever be able to cover it.
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pinned to the fixed design box, not full-rect, so this layer's own rotation (applied in
	# `main._apply_orientation()`) has a stationary 1280x720 footprint to rotate — see
	# `ScreenOrientation.pin_to_design_box()`.
	ScreenOrientation.pin_to_design_box(_root)
	visible = false

## Its own function, rather than inline in `_ready()`, matching `PauseScreen._refresh_body()` —
## kept even though `_BODY` no longer varies, so a test can call this again rather than reaching
## for a fresh scene.
func _refresh_body() -> void:
	_body.text = _BODY

## The one line on this screen that is not addressed to the player, so it is small, dim and in the
## bottom corner rather than anywhere near the three lines that are — see the **cues** rule that a
## short vocabulary stays short, which this deliberately stays outside of: it is not a danger cue,
## just a label.
##
## Prefers `Telemetry.source_version()`, `git describe`'s form (`v0.0.0-49-gab12cd3`), because a
## developer wants to know exactly what is running; an exported build has no repository to ask,
## which is when this falls back to `application/config/version` — the setting
## `.github/workflows/deploy.yml` writes into the export before it is built — so a player sees the
## release rather than "unknown". A function rather than inline in `_ready()` so a test can call it
## without instancing the whole scene.
static func version_text() -> String:
	var from_git := Telemetry.source_version()
	if from_git != "unknown":
		return from_git
	return ProjectSettings.get_setting("application/config/version", "unknown")

func is_open() -> bool:
	return visible

## Shows the screen. `again` is whether a run has just ended, which is the only difference between
## the two times it is shown.
##
## It does **not** touch `get_tree().paused`, which is where it differs from `PauseScreen` and why:
## a pause stops the world and this one deliberately does not. What stops, and what carries on
## behind the scrims, is `main`'s decision — see `main._open_the_title()`.
##
## **The one hint in the game that is never empty.** This screen has no buttons — there is nothing
## else on it to press — so unlike `PauseScreen`/`DaySummary`'s now-always-blank hint, it still
## needs to say *press to begin*. `tap`, on every device: *(2026-09-06: "never should it be
## mentioned to the user".)* `q to quit` no longer appears here even though the key still works —
## `_can_quit` now gates `_unhandled_input()` alone.
func open(again := false) -> void:
	visible = true
	_hint.text = "tap to walk again" if again else "tap to begin"

func close() -> void:
	visible = false

## `space`, a tap or a left click begins the run — the one thing this screen offers, since there is
## only one control scheme to begin it in. `Q` leaves, **except on the web**, where
## `QuitOption.available()` is false and the key is not handled at all — nothing on screen ever
## named it (see `open()`'s own doc), so there is no sentence to keep in step with the gate. `Esc`
## is deliberately not handled: `main` will not open the pause over this, because a pause over a
## game that has not started is a screen with nothing behind it to stop.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or TouchInput.is_press(event):
		get_viewport().set_input_as_handled()
		start_requested.emit()
		return
	if _can_quit and event is InputEventKey and event.pressed \
			and (event as InputEventKey).keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		quit_requested.emit()
