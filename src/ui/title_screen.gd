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
## and the three buttons that choose between them.
##
## **What is behind it is the game, running.** Not a still, not a menu over black: the
## doorstep the run starts on, with the traffic driving and the events playing out on it and nobody
## pushing a pram through them. The screen itself is therefore only two scrims, a handful of labels,
## the three `ModeButton`s and, for a new game, the Hard Mode checkbox: the title and the two lines
## of controls across the top half, the buttons and the checkbox across the bottom, and the street
## visible through both. `main._open_the_title()` is the
## half that makes the city keep moving while everything that is a *day* stops; this class owns
## its three buttons, the checkbox and a small handful of keys and nothing else.
##
## What it is not is a main menu. There is one option, no seed box and no load game, and none of
## those is what this screen exists for. **The one option is the Hard Mode checkbox**, shown only
## when the title begins a new game. *(gentle-osprey, the player: "a "Hard Mode" checkbox on the
## title screen (if new game) that decides whether checkpoints are available".)* Checked, the run
## has no checkpoints and its last nerve is the bad ending (`GameState.hard_mode`). It is quiet on
## purpose — Godot's own `CheckBox`, in the tagline's colour, under the hint — because it is
## a setting, not a way in: **pressing it never starts the run**, which still begins only from the
## three buttons or a key, so the box can be set and changed freely first. `H` toggles it from a
## keyboard, unnamed on screen like every other key here. It opens unchecked on every new game
## (it reads `GameState.hard_mode`, which a fresh run begins `false`, so only `--hard` opens it
## checked) and is never remembered between sittings: a mode kept outside the save would make a
## returning player's run depend on something the run does not hold.
##
## **Starting is also the controls question, and the buttons are how it is answered.**
## *(2026-09-07, the player: "let's make the controls a player choice and bring back the two
## buttons ... that should also solve the issue with the missing title screen since the only way to
## start the game will be clicking on one of the buttons".)* The joystick scheme's answer carries
## its steering side, and the buttons say which by where they stand: *(2026-10-10, the player: "the
## joystick select buttons move to where the joystick buttons will be. selecting the left one will
## make the left side permanently joystick and the right side permanently run button (permanently
## for the sitting). vice versa on the right side. the tap to play button goes in the center
## between both.")* `_left_button` and `_right_button` are `Symbol.JOYSTICK` discs centred on
## `TouchControls.FOCUS_LEFT` and `FOCUS_RIGHT`, the points that side's ring will stand on in play,
## and `_tap_button` is the `Symbol.TAP` disc midway between them. Each is named underneath —
## "On-screen Controls", "Tap to Go" — and nothing else. *(2026-09-07, the player: "call the modes
## 'On-screen Controls' and 'Tap to Go' no further explanations".)* The two joystick buttons share
## their caption, since the side is said by the button's place. "For the sitting" lasts until this
## screen asks again: the side is never saved, and every time the title opens it is chosen afresh.
## **A pointer press begins a run only when it lands on one of them**, never on the bare scrim: with
## the buttons as the only pointer way in, a stray tap that dismissed the ending screen a frame
## earlier can no longer restart the game just by landing anywhere on this one — the restart guard
## (`_RESTART_GUARD_SECONDS`) stays for the narrower case that remains, a stray press landing
## squarely on a button. A keyboard has no button to press, so
## `space` and every direction key still begin the run outright — see `_unhandled_input()`'s own
## doc for why that always chooses `Mode.TAP`.

## `mode` is the aiming origin the run begins in; `by_key` says a key began it rather than one of
## the buttons; `side` is the steering half in `Mode.JOYSTICK` (`Side.LEFT` wherever the scheme or
## a key named none). `mode` and `by_key` are separate because a key begins the run in `Mode.TAP`,
## and the counter reports a key player as a key player, never as the tap mode a key falls back to
## (`VisitCounter`'s `controls-keys`).
signal start_requested(mode: ControlsMode.Mode, by_key: bool, side: ControlsMode.Side)
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
@onready var _body: Label = $Root/Top/Lines/Body
@onready var _premise: Label = $Root/Top/Lines/Line
@onready var _left_caption: Label = $Root/Choice/LeftColumn/LeftCaption
@onready var _tap_caption: Label = $Root/Choice/TapColumn/TapCaption
@onready var _right_caption: Label = $Root/Choice/RightColumn/RightCaption
@onready var _left_button: ModeButton = $Root/Choice/LeftColumn/Left
@onready var _tap_button: ModeButton = $Root/Choice/TapColumn/Tap
@onready var _right_button: ModeButton = $Root/Choice/RightColumn/Right
@onready var _hint: Label = $Root/Hint
## The one line on this screen that is not addressed to the player, so it is small, dim and in the
## bottom corner rather than anywhere near the three lines that are — see the **cues** rule that a
## short vocabulary stays short, which this deliberately stays outside of: it is not a danger cue,
## just a label. It shows the version alone, `BuildInfo.version_text()`; the commit is a
## developer's number, and the debug note and the readout carry it (`BuildInfo.build_text()`).
@onready var _version: Label = $Root/Version
@onready var _hard_mode: CheckBox = $Root/HardMode
## The box's own edge, behind Godot's `unchecked` icon — which is a translucent dark square that
## disappears into the scrim and the cobbles behind it. A `StyleBoxFlat` in the title buttons' own
## fill and hover colours (`Palette.BUTTON_FILL`, `BUTTON_HOVER`), so the empty box reads as the
## same family as the three discs above it; the `checked` icon covers it whole. Engine data rather
## than anything drawn — see the **cues** rule, "Prefer the engine's data over any drawing at all".
@onready var _hard_mode_frame: Panel = $Root/HardMode/Frame
## The name of the run's mode, "Normal" or "Hard Mode", shown where the checkbox would stand when
## the mode is already decided (a save brought back): the checkbox and this label are never on
## screen together. A scene node beside the checkbox, in its colour, so it reads as the same line.
@onready var _mode_name: Label = $Root/ModeName

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


func _ready() -> void:
	# **The title has a colour of its own**, or the screen is four labels in one warm off-white and
	# the name of the game is only the biggest of them. `Palette.TITLE_TEXT` is the doorstep it is
	# standing in front of; see the note there for why it is not one of the danger colours.
	_name.add_theme_color_override("font_color", Palette.TITLE_TEXT)
	_name.text = Texts.TITLE_NAME
	_left_button.letter = Texts.TITLE_LETTER_LEFT
	_right_button.letter = Texts.TITLE_LETTER_RIGHT
	_premise.text = Texts.TITLE_PREMISE
	_left_caption.text = Texts.TITLE_CAPTION_JOYSTICK
	_tap_caption.text = Texts.TITLE_CAPTION_TAP
	_right_caption.text = Texts.TITLE_CAPTION_JOYSTICK
	_hint.text = Texts.TITLE_HINT_BEGIN
	_hard_mode.text = Texts.TITLE_HARD_MODE
	_refresh_body()
	_version.text = BuildInfo.version_text()
	# Above the pause screen: this is the outermost frame the game runs inside, and nothing should
	# ever be able to cover it.
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pinned to the fixed design box, not full-rect, so this layer's own rotation (applied in
	# `main._apply_orientation()`) has a stationary 1280x720 footprint to rotate — see
	# `ScreenOrientation.pin_to_design_box()`.
	ScreenOrientation.pin_to_design_box(_root)
	_place_column($Root/Choice/LeftColumn, TouchControls.FOCUS_LEFT)
	_place_column($Root/Choice/TapColumn, TAP_BUTTON_CENTRE)
	_place_column($Root/Choice/RightColumn, TouchControls.FOCUS_RIGHT)
	_hard_mode_frame.add_theme_stylebox_override("panel", _hard_mode_frame_style())
	_hard_mode.resized.connect(_place_the_hard_mode_frame)
	_place_the_hard_mode_frame()
	visible = false

## Where the tap button stands: midway between the two joystick buttons.
const TAP_BUTTON_CENTRE := (TouchControls.FOCUS_LEFT + TouchControls.FOCUS_RIGHT) * 0.5

## A column's width: its caption's, which is wider than the disc it centres under it.
const _COLUMN_WIDTH := 220.0

## Puts `column`'s disc centre on `centre`, in the design box `_root` is pinned to. The column is a
## disc with its caption under it, so the disc's centre is half the column's width across and one
## `ModeButton.RADIUS` down from its top-left corner.
static func _place_column(column: Control, centre: Vector2) -> void:
	column.position = centre - Vector2(_COLUMN_WIDTH * 0.5, ModeButton.RADIUS)
	column.size = Vector2(_COLUMN_WIDTH, column.size.y)

## Its own function, rather than inline in `_ready()`, matching `PauseScreen._refresh_body()` —
## kept even though `Texts.TITLE_BODY` no longer varies, so a test can call this again rather than reaching
## for a fresh scene.
func _refresh_body() -> void:
	_body.text = Texts.TITLE_BODY

## Whether the screen's own layer is presenting rotated — computed fresh rather than pushed in from
## `main`, the same reason `PauseScreen._wants_rotation()` and `DaySummary._wants_rotation()` are:
## `TouchControls` is the only file `main._apply_orientation()` reaches with a `rotated` property,
## and `ScreenOrientation.wants_rotation()` is a pure function of the same two facts `main` itself
## asks it with. Needed now that `_handle_mode_button_press()` reads a raw press position rather
## than only an action or a bare `TouchInput.is_press()`.
func _wants_rotation() -> bool:
	return ScreenOrientation.wants_rotation(get_window().size, _touch)

func is_open() -> bool:
	return visible

## Shows the screen. `again` is whether a run has just ended, which is the only difference between
## the two times it is shown — besides `new_game`, which is whether pressing a button begins a new
## run rather than one a save brought back, and is the only time the Hard Mode checkbox shows. It
## opens on the mode the run already holds, `GameState.hard_mode`: `false` for every fresh run, and
## `true` only under `--hard`.
##
## `mode_decided` is whether the mode is already fixed for this run, which is when a save brought
## it back (the title before a resumed day or a resumed escape): the checkbox has nothing to ask
## then, so the mode's name, "Normal" or "Hard Mode" (`GameState.hard_mode`), stands in its place.
## A new game shows the checkbox and no name; a title with neither (the escape flag's, which has
## no run) shows neither.
##
## It does **not** touch `get_tree().paused`, which is where it differs from `PauseScreen` and why:
## a pause stops the world and this one deliberately does not. What stops, and what carries on
## behind the scrims, is `main`'s decision — see `main._open_the_title()`.
##
## **The one hint in the game that is never empty, and it has to name the thing that actually
## works.** *(2026-09-07, on review: "a bare tap no longer begins anything ... the screen instructs
## the player to do the one thing that will not work".)* `tap to begin` was true when any press
## anywhere began a run; once only the buttons do, it sends a first-time player looking for
## something a tap on the scrim will never do. `press a button` is what is actually true and what
## still says nothing about a key, the same way `tap` never did *(2026-09-06: "never should it be
## mentioned to the user".)* — it also points the sentence at the discs themselves, which are
## otherwise the only thing on this screen that does anything. `q to quit` still does not appear
## here even though the key still works — `_can_quit` gates `_unhandled_input()` alone.
func open(again := false, new_game := false, mode_decided := false) -> void:
	visible = true
	if _hard_mode:
		_hard_mode.visible = new_game
		_hard_mode.button_pressed = new_game and GameState.hard_mode
		_place_the_hard_mode_frame()
	_mode_name.visible = mode_decided and not new_game
	_mode_name.text = Texts.TITLE_MODE_HARD if GameState.hard_mode else Texts.TITLE_MODE_NORMAL
	_hint.text = Texts.TITLE_HINT_AGAIN if again else Texts.TITLE_HINT_BEGIN
	# A press that closed this screen can leave a button's own forced-pressed look set — see
	# `_acknowledge_and_begin()`'s own doc for why the release that would otherwise clear it may
	# never reach `_unhandled_input()` at all, once `visible` has already gone false. Cleared here
	# rather than left to leak into whatever this screen shows next, the same reason
	# `PauseScreen.open()` calls `_restart_button.cancel_hold()`.
	for button: ModeButton in _buttons():
		button.clear_forced_press()
		button.set_hovered(false)

## The three buttons, in the order hover and press ask them.
func _buttons() -> Array[ModeButton]:
	return [_left_button, _tap_button, _right_button]

func close() -> void:
	visible = false

## Whether the Hard Mode checkbox is checked — read by `main._on_title_start()` as the title is
## dismissed, and only for a new game, the one time the box is shown. `false` for a `TitleScreen`
## built without its scene, which has no box to check — the bare rigs `tests/test_save.gd` drives
## `main._on_title_start()` through.
func hard_mode_checked() -> bool:
	return _hard_mode != null and _hard_mode.visible and _hard_mode.button_pressed

## The mode's name on screen, or `""` while it is not showing (a new game, where the checkbox asks).
func mode_name_shown() -> String:
	return _mode_name.text if _mode_name != null and _mode_name.visible else ""

## Whether the Hard Mode checkbox is on screen: only while the title begins a new game.
func hard_mode_shown() -> bool:
	return _hard_mode != null and _hard_mode.visible

## Flips the Hard Mode checkbox, if it is showing. Never starts the run.
func _toggle_hard_mode() -> void:
	if _hard_mode and _hard_mode.visible:
		_hard_mode.button_pressed = not _hard_mode.button_pressed

## The key that flips the checkbox from a keyboard — `H`, for hard — and, like every key here,
## never named on screen.
const _HARD_MODE_KEY := KEY_H

## How far past the checkbox's own rect a press still lands on it, on every side. The title is
## authored in the 1280x720 design box and scaled to fit, so a phone held landscape (about 393pt
## tall) shows it at about x0.55: this reach, in design px around the box at `_HARD_MODE_SCALE`,
## makes the target about 92 design px tall, about 50pt there, over the 44pt a finger needs. The space it reaches into holds nothing else a press can
## land on — the hint line above is not a target, and the buttons' catches end well above it. It is
## the floor under the 5% margin every button has (`ButtonGeometry.margin_rect()`, see
## `hard_mode_target()`), and at this size it is also the larger of the two each way.
const _HARD_MODE_REACH := 28.0

## How much larger than the theme's own the checkbox is drawn, box and label together — scaling the
## control rather than raising its font, since the theme's box icon has one size and would be left
## a small square beside a large label. On a landscape phone the label reads at about 12pt.
const _HARD_MODE_SCALE := 1.5

## A touch or a left click on the checkbox flips it and is used up there, so it can never fall
## through to `_handle_mode_button_press()` and begin the run — read off the raw press position in
## design space the way the three buttons are, since `mouse_filter` is `IGNORE` on it too and a
## rotated layer would otherwise put Godot's own hit test in the wrong place. On the press, like the
## buttons; the mouse branch is gated `not _touch` for the same doubled-press reason theirs is.
##
## **It is reached only because nothing on this screen stops a press first.** Godot's GUI pass runs
## before `_unhandled_input()` and ends a press at the topmost `Control` under it set to
## `MOUSE_FILTER_STOP`, the default for a bare `Control` or `ColorRect`; so every node in
## `title_screen.tscn` ignores the mouse or, as a container does by default, passes it on — the two
## scrims included, since the bottom one lies under this box and under the strip of each button's
## catch above its column. `tests/test_run_checkpoints.gd` holds both: it taps through the engine's
## own dispatch rather than calling this, and names any `Control` here left stopping a press.
func _handle_hard_mode_press(event: InputEvent) -> bool:
	if not hard_mode_shown():
		return false
	var position: Vector2
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		position = (event as InputEventScreenTouch).position
	elif not _touch and event is InputEventMouseButton \
			and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		position = (event as InputEventMouseButton).position
	else:
		return false
	var at := ScreenOrientation.to_design_space(position, _wants_rotation())
	if not hard_mode_contains_design_point(at):
		return false
	get_viewport().set_input_as_handled()
	_toggle_hard_mode()
	return true

## The frame's look: the buttons' dark fill, a hairline of their hover colour, corners rounded
## like the icon it sits behind.
static func _hard_mode_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BUTTON_FILL
	style.border_color = Palette.BUTTON_HOVER
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

## Puts the frame exactly where `CheckBox` draws its icon: past the normal stylebox's left margin,
## centred down the control, plus the theme's own `check_v_offset`. And scales the control about its
## own centre, which only its own minimum size says, and centres it across the design box. Not in a
## container, which would put its scale back to one every time it laid the control out.
func _place_the_hard_mode_frame() -> void:
	_hard_mode.size = _hard_mode.get_combined_minimum_size()
	_hard_mode.pivot_offset = _hard_mode.size * 0.5
	_hard_mode.scale = Vector2.ONE * _HARD_MODE_SCALE
	_hard_mode.position.x = (ScreenOrientation.DESIGN_SIZE.x - _hard_mode.size.x) * 0.5
	var icon := _hard_mode.get_theme_icon("unchecked")
	var style := _hard_mode.get_theme_stylebox("normal")
	_hard_mode_frame.position = Vector2(style.get_margin(SIDE_LEFT),
			(_hard_mode.size.y - icon.get_height()) * 0.5
			+ _hard_mode.get_theme_constant("check_v_offset"))
	_hard_mode_frame.size = icon.get_size()

## Whether `point`, in the 1280x720 design box, lands on the checkbox's catch (`hard_mode_target()`).
func hard_mode_contains_design_point(point: Vector2) -> bool:
	return hard_mode_target().has_point(point)

## The checkbox's tappable area in the 1280x720 design box: the box and its label as drawn, scale
## included, grown by the larger of two margins each way — the 5% every button catches beyond what
## it draws (`ButtonGeometry.margin_rect()`; *fluffy-kestrel, the player, #740: "Hard mode should
## have the same 5% extension over the box and text as other buttons"*) and `_HARD_MODE_REACH`, the
## catch it had before, which no margin may shrink (the calm-pelican record: "the 5% button reach is
## a minimum, and no catch shrank"). The two are centred on the same rect, so their merge is each
## axis's larger.
func hard_mode_target() -> Rect2:
	var transform := _hard_mode.get_global_transform()
	var drawn := transform * Rect2(Vector2.ZERO, _hard_mode.size)
	return drawn.grow(_HARD_MODE_REACH).merge(ButtonGeometry.margin_rect(drawn))

## `space` or a direction key begins the run **in `Mode.TAP`**, and a press on one of the
## buttons begins it in whichever mode — and, for a joystick, side — that button names. *(2026-09-07: "using awsd or arrow keys
## will start the game with tap mode".)* Read as *the keyboard is a desktop and a desktop is a
## mouse* — the same reasoning that makes `TAP` the mouse mode at all: a player pressing `space` or
## an arrow has told this screen nothing about a thumb either. The run still says a key began it
## (`start_requested`'s `by_key`), so the counter can tell a key player from a tap player
## (PLAYTEST-143: "is telemetry currently correctly identifying when a player plays with keys?").
## `Q` leaves, **except on the web**,
## where `QuitOption.available()` is false and the key is not handled at all — nothing on screen
## ever named it (see `open()`'s own doc), so there is no sentence to keep in step with the gate.
## `Esc` is deliberately not handled: `main` will not open the pause over this, because a pause
## over a game that has not started is a screen with nothing behind it to stop.
##
## **A pointer press that does not land on a button does nothing at all.** *(2026-09-07: "the
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
## the ending. A stray press can still land squarely on a button — they are drawn in the same
## screen region a catch-all used to cover — so the guard answers exactly that case now rather than
## every press on the screen. See `_restarted_at_msec`'s own doc for what survives the reload and
## `_RESTART_GUARD_SECONDS`'s for the window's own size.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or _is_a_walk_key(event):
		get_viewport().set_input_as_handled()
		_begin(ControlsMode.Mode.TAP, ControlsMode.Side.LEFT, true)
		return
	if event is InputEventKey and event.pressed and not (event as InputEventKey).echo \
			and (event as InputEventKey).keycode == _HARD_MODE_KEY and hard_mode_shown():
		get_viewport().set_input_as_handled()
		_toggle_hard_mode()
		return
	if _handle_hard_mode_press(event):
		return
	if _handle_mode_button_press(event):
		return
	if not _touch and event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
		return
	if _can_quit and event is InputEventKey and event.pressed \
			and (event as InputEventKey).keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		quit_requested.emit()

## A laptop's own question — there is no hover on a phone, which is why this is gated `not _touch`
## at the one call site above rather than inside here. *(Playtest 34 finding 1: "buttons still
## don't light up when pressed or hovered.")* `ModeButton.set_hovered()` is the answer
## `MOUSE_FILTER_IGNORE` already needs for a press, reused here since it silences
## `mouse_entered`/`mouse_exited` exactly as it silences a click — nothing native is left to ask.
func _update_hover(position: Vector2) -> void:
	var at := ScreenOrientation.to_design_space(position, _wants_rotation())
	for button: ModeButton in _buttons():
		button.set_hovered(button.contains_design_point(at))

## The four `move_*` actions — `WASD` and the arrows both, since each is bound to all four. Asked
## as a loop over the action list rather than four `or`ed `is_action_pressed()` calls, so a fifth
## walking action added later needs only a new entry in `_WALK_ACTIONS` here.
const _WALK_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

static func _is_a_walk_key(event: InputEvent) -> bool:
	for action in _WALK_ACTIONS:
		if event.is_action_pressed(action):
			return true
	return false

## A press landing inside one of the buttons' round catches — read by raw touch or mouse position, the way `PauseScreen._handle_restart_touch()` and
## `DaySummary._handle_restart_touch()` already read theirs, rather than through `Button.pressed`:
## `ModeButton._ready()` sets `mouse_filter = MOUSE_FILTER_IGNORE` on every symbol, so Godot's GUI
## layer never claims the event and a `Button`'s own signal never fires for a real touch.
##
## Unlike the restart button's hold, this fires on the press itself, not a matching release — there
## is no duration to track. **The mouse branch is gated on `not _touch`**, the same reason
## `TouchControls._input()`'s own is: a real touch device also emits an emulated mouse click from
## the same finger, and without the gate a single press on a button would be read twice.
##
## Returns whether the press belonged to a button at all, so `_unhandled_input()` knows not to fall
## through to the quit key check for the same event — though with no catch-all left on this screen,
## a press that misses every button simply does nothing, which is exactly what was asked for.
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
	for button: ModeButton in _buttons():
		if button.contains_design_point(at):
			get_viewport().set_input_as_handled()
			var mode := ControlsMode.Mode.TAP if button == _tap_button \
					else ControlsMode.Mode.JOYSTICK
			var side := ControlsMode.Side.RIGHT if button == _right_button \
					else ControlsMode.Side.LEFT
			_acknowledge_and_begin(mode, side, button)
			return true
	return false

## Whether an acknowledge-and-begin coroutine is already in flight — see `_acknowledge_and_begin()`.
var _starting := false

## Flashes `button` pressed for two frame boundaries before actually starting the run — the same
## shape `DaySummary._acknowledge_and_continue()` already uses and for the same reason. *(Playtest
## 34 finding 1: "buttons still don't light up when pressed or hovered.")* `_begin()` used to run
## synchronously inside the same input-processing pass that also closes this screen
## (`main._on_title_start()` → `_title.close()`), and Godot never draws a frame between one call and
## the next within a single input dispatch — so the pressed fill was set and then hidden again
## without a frame ever rendering it, the identical defect `DaySummary`'s own doc found for its
## continue button. Two `process_frame` awaits, not one, for the reason that doc gives:
## `SceneTree.process_frame` fires *before* the frame it names is drawn, so the second is what
## actually lands after the draw that happens between them.
func _acknowledge_and_begin(mode: ControlsMode.Mode, side: ControlsMode.Side,
		button: ModeButton) -> void:
	if _starting:
		return
	_starting = true
	button.force_pressed_look()
	await get_tree().process_frame
	await get_tree().process_frame
	button.clear_forced_press()
	_starting = false
	_begin(mode, side)

## The one place `start_requested` is actually emitted — a walk key, `space`, or one of the
## buttons, all funnelled through here so the restart guard is asked exactly once regardless of
## which of them fired. See `_unhandled_input()`'s own doc for what the guard still answers now
## that a bare press elsewhere on the screen can no longer reach this function at all.
func _begin(mode: ControlsMode.Mode, side: ControlsMode.Side, by_key := false) -> void:
	if (Time.get_ticks_msec() - _restarted_at_msec) / 1000.0 < _RESTART_GUARD_SECONDS:
		return
	start_requested.emit(mode, by_key, side)
