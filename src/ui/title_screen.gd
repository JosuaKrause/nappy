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
## deliberately no separate "restart" screen and no menu: this is a title, two lines of controls,
## and the two buttons that choose between them.
##
## **What is behind it is the game, running.** Not a still, not a menu over black: the
## doorstep the run starts on, with the traffic driving and the events playing out on it and nobody
## pushing a pram through them. The screen itself is therefore only two scrims, a handful of labels
## and the two `ModeButton`s: the title across the top half, the controls across the bottom, and
## the street visible through both. `main._open_the_title()` is the half that makes the city keep
## moving while everything that is a *day* stops; this class owns its two buttons and a small
## handful of keys and nothing else.
##
## What it is not is a main menu. There are no options, no seed box and no load game, and none of
## those is what this screen exists for.
##
## **Starting is also the controls question, and the two buttons are how it is answered.**
## *(2026-09-07, the player: "let's make the controls a player choice and bring back the two
## buttons ... that should also solve the issue with the missing title screen since the only way to
## start the game will be clicking on one of the buttons".)* `_joystick_button` and `_tap_button`
## are `ModeButton`s with `Symbol.JOYSTICK`/`Symbol.TAP` and their own two captions underneath —
## see `_handle_mode_button_press()`. **A pointer press begins a run only when it lands on one of
## them**, never on the bare scrim: with the buttons as the only pointer way in, a stray tap that
## dismissed the ending screen a frame earlier can no longer restart the game just by landing
## anywhere on this one — the restart guard (`_RESTART_GUARD_SECONDS`) stays for the narrower case
## that remains, a stray press landing squarely on a button. A keyboard has no button to press, so
## `space` and every direction key still begin the run outright — see `_unhandled_input()`'s own
## doc for why that always chooses `Mode.TAP`.

signal start_requested(mode: ControlsMode.Mode)
signal quit_requested()

## The instant `main._restart_run()` last asked for a scene reload, or `-INF` before the first one
## this process. A `static var` on the class rather than a member on the node: `reload_current_scene()`
## frees this screen's own instance and builds a fresh one, but the script class itself is never
## unloaded, so this is the one place a fact can survive the freeing that crosses it — the same
## thing an autoload would give, with no autoload added to hold it. See `_unhandled_input()`'s own
## doc for what it guards.
static var _restarted_at_msec := -INF

## Called by `main._restart_run()`, immediately before it defers the reload — see that function's
## own doc and this class's `_unhandled_input()`.
static func note_restart_requested() -> void:
	_restarted_at_msec = Time.get_ticks_msec()

## How long after a restart-triggered reload a press is swallowed rather than started — see
## `_unhandled_input()`'s own doc. Reuses `TouchControls.DOUBLE_TAP_SECONDS` rather than a number
## invented for this file, since both ask the same question of a press this close in time to
## another: is this the same gesture as the one just before it.
const _RESTART_GUARD_SECONDS := TouchControls.DOUBLE_TAP_SECONDS

@onready var _root: Control = $Root
@onready var _name: Label = $Root/Top/Lines/Title
@onready var _body: Label = $Root/Bottom/Lines/Body
@onready var _joystick_button: ModeButton = $Root/Bottom/Lines/Choice/JoystickColumn/Joystick
@onready var _tap_button: ModeButton = $Root/Bottom/Lines/Choice/TapColumn/Tap
@onready var _hint: Label = $Root/Bottom/Lines/Hint
@onready var _version: Label = $Root/Version

## Whether `Q` does anything on this platform. Read once from `QuitOption` rather than asked at
## each use site, so a test — never itself a web export — can set this and drive both shapes.
## Gates only whether the key is **handled** in `_unhandled_input()` below; it no longer names
## itself on screen — see `open()`'s own doc.
var _can_quit := QuitOption.available()

## Whether this device has touch hardware — read once the same way `PauseScreen._touch` and
## `DaySummary._touch` are, so `_handle_mode_button_press()` can gate its own mouse branch on
## `not _touch` for the same reason theirs do: a real touch device also emits an emulated mouse
## click from the same finger, and without the gate a single press on a button would be read twice.
var _touch := TouchInput.available()

## One body for every device — see `PauseScreen._BODY`'s own doc for the same collapse made
## there. *(2026-09-06, the player: "in fact I said to remove the keyboard inputs altogether but
## I'm willing to compromise on letting them stay silently".)* The keyboard still walks and runs;
## nothing on screen names a key for it any more. `TouchInput.available()` used to choose between
## this and a keyboard body — with only one body left, this screen has no more use for that fact
## and keeps no member for it.
##
## **Says two things and nothing else.** *(2026-09-07: "the movement tutorial should just say 'Tap
## to walk' and 'Double tap to run'. no mention of tapping her or 'that way'.")* The struck clauses
## named a stop she can still ask for — a press within `STOP_RADIUS` of a focal point, or a mouse
## click on her — the same way nothing here has ever named a key: stopping still works, and the
## game simply stops teaching it, exactly as `HUD._teach_the_day()`'s own day-1 line already reads.
const _BODY := "Tap to walk, double tap to run.\n" \
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

## Whether the screen's own layer is presenting rotated — computed fresh rather than pushed in from
## `main`, the same reason `PauseScreen._wants_rotation()` and `DaySummary._wants_rotation()` are:
## `TouchControls` is the only file `main._apply_orientation()` reaches with a `rotated` property,
## and `ScreenOrientation.wants_rotation()` is a pure function of the same two facts `main` itself
## asks it with. Needed now that `_handle_mode_button_press()` reads a raw press position rather
## than only an action or a bare `TouchInput.is_press()`.
func _wants_rotation() -> bool:
	return ScreenOrientation.wants_rotation(get_window().size, _touch)

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
## **The one hint in the game that is never empty.** Unlike `PauseScreen`/`DaySummary`'s
## now-always-blank hint, this one still needs to say *press to begin* — the two buttons are the
## only pointer way in, but a keyboard has neither to press, so the hint still speaks for it.
## `tap`, on every device: *(2026-09-06: "never should it be mentioned to the user".)* `q to quit`
## no longer appears here even though the key still works — `_can_quit` now gates
## `_unhandled_input()` alone.
func open(again := false) -> void:
	visible = true
	_hint.text = "tap to walk again" if again else "tap to begin"

func close() -> void:
	visible = false

## `space` or a direction key begins the run **in `Mode.TAP`**, and a press on one of the two
## buttons begins it in whichever mode that button names. *(2026-09-07: "using awsd or arrow keys
## will start the game with tap mode".)* Read as *the keyboard is a desktop and a desktop is a
## mouse* — the same reasoning that makes `TAP` the mouse mode at all: a player pressing `space` or
## an arrow has told this screen nothing about a thumb either. `Q` leaves, **except on the web**,
## where `QuitOption.available()` is false and the key is not handled at all — nothing on screen
## ever named it (see `open()`'s own doc), so there is no sentence to keep in step with the gate.
## `Esc` is deliberately not handled: `main` will not open the pause over this, because a pause
## over a game that has not started is a screen with nothing behind it to stop.
##
## **A pointer press that does not land on either button does nothing at all.** *(2026-09-07: "the
## only way to start the game will be clicking on one of the buttons".)* This is the property that
## makes the ending-screen leak M85 patched with a guard structurally impossible instead: a bare
## tap or click anywhere on the scrim used to begin a run outright, which is exactly what let a
## press dismissing the day summary land here a frame later and read as a fresh one. With no
## catch-all left, that particular race is gone by construction — see `_handle_mode_button_press()`.
##
## **The restart guard still stays, for the narrower case that remains.** A press within
## `_RESTART_GUARD_SECONDS` of the last scene reload is swallowed rather than started — the route is
## `DaySummary` emitting `continued` → `main._on_summary_continued()` → `_restart_run()` →
## `get_tree().call_deferred("reload_current_scene")` → this screen's own fresh `_ready()` →
## `main._open_the_title()`, and this screen is up within a frame or two of the press that dismissed
## the ending. A stray press can still land squarely on a button — the two are drawn in the same
## screen region a catch-all used to cover — so the guard answers exactly that case now rather than
## every press on the screen. See `_restarted_at_msec`'s own doc for what survives the reload and
## `_RESTART_GUARD_SECONDS`'s for the window's own size.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or _is_a_walk_key(event):
		get_viewport().set_input_as_handled()
		_begin(ControlsMode.Mode.TAP)
		return
	if _handle_mode_button_press(event):
		return
	if _can_quit and event is InputEventKey and event.pressed \
			and (event as InputEventKey).keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		quit_requested.emit()

## The four `move_*` actions — `WASD` and the arrows both, since each is bound to all four. Asked
## as a loop over the action list rather than four `or`ed `is_action_pressed()` calls, so a fifth
## walking action added later needs only a new entry in `_WALK_ACTIONS` here.
const _WALK_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

static func _is_a_walk_key(event: InputEvent) -> bool:
	for action in _WALK_ACTIONS:
		if event.is_action_pressed(action):
			return true
	return false

## A press landing inside `_joystick_button.catch_rect()` or `_tap_button.catch_rect()` — read by
## raw touch or mouse position, the way `PauseScreen._handle_restart_touch()` and
## `DaySummary._handle_restart_touch()` already read theirs, rather than through `Button.pressed`:
## `ModeButton._ready()` sets `mouse_filter = MOUSE_FILTER_IGNORE` on every symbol, so Godot's GUI
## layer never claims the event and a `Button`'s own signal never fires for a real touch.
##
## Unlike the restart button's hold, this fires on the press itself, not a matching release — there
## is no fill to track and nothing to cancel. **The mouse branch is gated on `not _touch`**, the
## same reason `TouchControls._input()`'s own is: a real touch device also emits an emulated mouse
## click from the same finger, and without the gate a single press on a button would be read twice.
##
## Returns whether the press belonged to a button at all, so `_unhandled_input()` knows not to fall
## through to the quit key check for the same event — though with no catch-all left on this screen,
## a press that misses both buttons simply does nothing, which is exactly what was asked for.
func _handle_mode_button_press(event: InputEvent) -> bool:
	var position: Vector2
	var pressed: bool
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		position = touch.position
		pressed = touch.pressed
	elif not _touch and event is InputEventMouseButton \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var click := event as InputEventMouseButton
		position = click.position
		pressed = click.pressed
	else:
		return false
	if not pressed:
		return false
	var at := ScreenOrientation.to_design_space(position, _wants_rotation())
	if _joystick_button.catch_rect().has_point(at):
		get_viewport().set_input_as_handled()
		_begin(ControlsMode.Mode.JOYSTICK)
		return true
	if _tap_button.catch_rect().has_point(at):
		get_viewport().set_input_as_handled()
		_begin(ControlsMode.Mode.TAP)
		return true
	return false

## The one place `start_requested` is actually emitted — a walk key, `space`, or one of the two
## buttons, all funnelled through here so the restart guard is asked exactly once regardless of
## which of them fired. See `_unhandled_input()`'s own doc for what the guard still answers now
## that a bare press elsewhere on the screen can no longer reach this function at all.
func _begin(mode: ControlsMode.Mode) -> void:
	if (Time.get_ticks_msec() - _restarted_at_msec) / 1000.0 < _RESTART_GUARD_SECONDS:
		return
	start_requested.emit(mode)
