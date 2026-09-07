class_name ModeButton
extends Button
## A circular, icon-only button: a round disc with a tinted glyph for what it does and no text
## inside it at all.
##
## **No glyph is painted.** *(2026-09-06, the player: "never draw in code -- at the very least use
## svgs".)* The disc is a `StyleBoxFlat` per state (`normal`/`hover`/`pressed`), its
## `corner_radius_*` set to half the button's own size so a square `Button` renders as a circle,
## and every glyph is the button's own `icon` — a preloaded SVG under `assets/ui/`, tinted through
## `icon_normal_color` and its per-state siblings rather than drawn. Two earlier versions of this
## file painted the disc and the glyphs by hand in `_draw()`; both are gone, because a picture is
## an asset the moment a person could call it one.
##
## **`_draw()` is back, for exactly one thing that is not a picture: `RESTART`'s own hold fill.**
## *(Playtest 29 finding 5: "the hold button should fill up in its entirety while holding, not
## have a separate bar.")* A radial sweep tracking `hold_progress` is layout the same way
## `MeterBar`'s own fill is — see the **cues** rule's own exception for a fill that is not a
## drawing of anything — and a `Button` has no stock control for "fills while held", so this is the
## one place the **cues** rule's own "prefer the engine's data" clause has nothing to prefer.
##
## **Every button shares one neutral fill (`Palette.BUTTON_FILL`/`BUTTON_HOVER`/`BUTTON_PRESSED`)
## rather than a colour per symbol.** A hue in this project already means something
## (`Palette.SIGNAL_RED`/`AMBER`/`GREEN` are the lights, `MARK_COSTLY`/`MARK_LETHAL` are what an
## event costs), and spending a saturated hue on which button is which teaches a distinction that
## means nothing anywhere else in the game — the **cues** rule against a second hand-drawn
## vocabulary, aimed at colour instead of a shape. The glyph carries the whole difference.
##
## A small reusable control rather than a one-off, because the pause screen and the day summary
## share the same pair of buttons, for `Symbol.RESTART` and `Symbol.CONTINUE` — one interaction
## learned once rather than a different control on each screen. `RESTART`'s own hold fill lives
## here too, so both screens drive the same drawing through `hold_progress` rather than each screen
## painting its own.
##
## `Symbol.JOYSTICK` and `Symbol.TAP` are the title screen's own pair, one per aiming origin —
## see `TitleScreen` and `ControlsMode`. Neither ever holds: a press chooses the mode outright, so
## `hold_progress` and the `_draw()` sweep below stay meaningful only for `RESTART`.
##
## **Pressed and hovered are driven from outside, not from `Button`'s own draw state.**
## *(Playtest 34 finding 1: "buttons still don't light up when pressed or hovered.")* `_ready()`'s
## own `mouse_filter = MOUSE_FILTER_IGNORE` — load-bearing, see its own comment — means Godot's GUI
## layer never claims an event for this control, so `Button` never enters its own hover or pressed
## draw mode and the `hover`/`pressed`/`hover_pressed` styleboxes `_apply_disc_style()` installs are
## never selected. `force_pressed_look()`/`clear_forced_press()` and `set_hovered()` below answer
## both questions from the same raw-touch and raw-mouse reading the owning screen already does
## through `catch_rect()` — `begin_hold()`/`end_hold()`/`cancel_hold()` route through the first pair
## too, so `RESTART`'s own timed hold gets the same fill as an ordinary press with no second
## mechanism. Hover is a laptop's question — there is no hover on a phone — and answered by the same
## `InputEventMouseMotion` a screen reads for nothing else, since `MOUSE_FILTER_IGNORE` also
## silences `mouse_entered`/`mouse_exited`.

## The mode this button's icon names. **`JOYSTICK` and `TAP` are appended after the other two,
## not inserted before them** — `RESTART` and `CONTINUE` are serialized as bare ints
## (`symbol = 0`/`symbol = 1`) in `pause_screen.tscn` and `day_summary.tscn`, and M82's own note on
## this enum names exactly this trap: re-indexing it changes what an already-saved `symbol = N`
## means everywhere it is used, caught only by a screenshot rather than by anything in the suite.
enum Symbol { RESTART, CONTINUE, JOYSTICK, TAP }
@export var symbol: Symbol = Symbol.RESTART

const _RESTART_ICON: Texture2D = preload("res://assets/ui/restart.svg")
const _CONTINUE_ICON: Texture2D = preload("res://assets/ui/continue.svg")
const _JOYSTICK_ICON: Texture2D = preload("res://assets/ui/joystick.svg")
const _TAP_ICON: Texture2D = preload("res://assets/ui/tap.svg")

const _ICON_BY_SYMBOL := {
	Symbol.RESTART: _RESTART_ICON,
	Symbol.CONTINUE: _CONTINUE_ICON,
	Symbol.JOYSTICK: _JOYSTICK_ICON,
	Symbol.TAP: _TAP_ICON,
}

## `TouchControls.PAUSE_CATCH_RADIUS` (46px) is the one catch radius left in the game, now that the
## drag stick and the `RUN` button are gone — a thumb is never asked to land inside anything
## smaller during a run. This button is opened on the same phone, so its own radius matches it
## rather than a value chosen for a mouse: nothing on this screen may be harder to hit than the
## one control already in the game.
const _RADIUS := 46.0
const _DIAMETER := _RADIUS * 2.0
## The glyph reads best at roughly half the disc's own diameter — big enough to read at this
## button's 46px radius, short of the rim so it never touches the disc's own edge.
const _ICON_SIZE := _DIAMETER * 0.5
const _ICON_INSET := (_DIAMETER - _ICON_SIZE) * 0.5

## Only meaningful for `Symbol.RESTART`: the fraction (0..1) of the current hold. Set by
## `begin_hold()`/`_process()`/`end_hold()` below rather than by the screen that owns the touch —
## unlike the disc and the glyph, which are static, this is the one piece of the button that moves,
## and centralising it here is what lets `PauseScreen` and `DaySummary` share one implementation of
## "held for about a second" instead of each keeping its own touch index and clock.
var hold_progress := 0.0:
	set(value):
		hold_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

## The disc's own fill, while held — see `_draw()`. Translucent rather than opaque: a script
## `_draw()` on a `Button` paints over the stylebox and the icon, and a fully opaque fill would
## hide the glyph underneath it as the sweep passed over it.
const _HOLD_FILL := Color(1.0, 1.0, 1.0, 0.4)
## How many wedges make up a full-circle sweep — the same order of segment count `TouchControls`'
## own now-deleted rim arc and `DangerEdge`'s circular badges use for a smooth curve at this size.
const _HOLD_FILL_SEGMENTS := 48

## About a second, per the design this milestone builds rather than invents — *(2026-09-06:
## "restart game (must be held down so a bar needs to fill up while pressing".)*
const RESTART_HOLD_SECONDS := 1.0

## The touch index currently holding this button, or -1 when nothing is — the same shape
## `TouchControls._pause_touch` already tracks a touch by. Only ever non‑`-1` for
## `Symbol.RESTART`; the other symbol never calls `begin_hold()`.
var _held_by := -1
## `Time.get_ticks_msec() / 1000.0` when `_held_by` was grabbed, so `_process()` can measure the
## hold against `RESTART_HOLD_SECONDS` without keeping its own delta accumulator.
var _held_since := 0.0

func _ready() -> void:
	# A plain diameter square for both symbols — the extra height `RESTART`'s own hold bar used to
	# reserve below the disc is gone along with the bar itself; the fill now lives inside the disc.
	custom_minimum_size = Vector2(_DIAMETER, _DIAMETER)
	_apply_disc_style()
	icon = _ICON_BY_SYMBOL.get(symbol)
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	expand_icon = true
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
			"icon_hover_pressed_color", "icon_focused_color", "icon_disabled_color"]:
		add_theme_color_override(state, Palette.BUTTON_SYMBOL)
	# **The bug, and the fix.** *(Playtest 29 finding 2: "the buttons do *not* work at all... the
	# buttons themselves do nothing.")* A `Control`'s own `mouse_filter` defaults to `STOP`, and
	# Godot's GUI layer — which runs between `_input` and `_unhandled_input` — consumes a raw
	# `InputEventScreenTouch` that lands on a `STOP` control. `PauseScreen` and `DaySummary` read
	# every press in `_unhandled_input()`, which a `STOP` button never lets the touch reach. This
	# button is driven entirely by the screens' own raw-touch reading — `catch_rect()` plus
	# `begin_hold()`/`end_hold()` above — never by `Button`'s own `pressed` signal, so it must not
	# claim the event at all: `IGNORE` lets it fall straight through to the screen underneath.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if _held_by == -1:
		return
	hold_progress = (Time.get_ticks_msec() / 1000.0 - _held_since) / RESTART_HOLD_SECONDS

## Starts tracking a hold from `touch_index`, unless something else already holds this button.
## Returns whether it was accepted — the caller (`PauseScreen`/`DaySummary`) treats a `false` here
## exactly as "this touch is none of this button's business" and lets it fall through to its own
## catch-all, the same as a press that missed `catch_rect()` entirely.
func begin_hold(touch_index: int) -> bool:
	if _held_by != -1:
		return false
	_held_by = touch_index
	_held_since = Time.get_ticks_msec() / 1000.0
	hold_progress = 0.0
	force_pressed_look()
	return true

## Whether `touch_index` is the one currently holding this button — what the caller checks on a
## release to decide whether it belongs here at all before calling `end_hold()`.
func is_held_by(touch_index: int) -> bool:
	return _held_by == touch_index

## Ends the hold `touch_index` started and answers whether it lasted long enough. Safe to call
## whether or not `touch_index` is actually the one held — a mismatched index simply changes
## nothing and answers `false`, so a caller that already checked `is_held_by()` never has to guard
## twice.
func end_hold(touch_index: int) -> bool:
	if _held_by != touch_index:
		return false
	var held := Time.get_ticks_msec() / 1000.0 - _held_since
	_held_by = -1
	hold_progress = 0.0
	clear_forced_press()
	return held >= RESTART_HOLD_SECONDS

## Lets go of whatever this button is holding without completing it — for a screen that closes, or
## reopens, while a thumb is still down, the same reason `TouchControls._release_all()` exists.
func cancel_hold() -> void:
	_held_by = -1
	hold_progress = 0.0
	clear_forced_press()

## Whether a real press or `RESTART`'s own timed hold currently forces the pressed fill, and
## whether the mouse currently sits over this button — the two inputs `_refresh_look()` resolves
## into the one stylebox `Button` will actually draw. Pressed beats hovered beats resting, the same
## precedence a native `Button` would give its own draw modes if `MOUSE_FILTER_IGNORE` ever let it
## reach them.
var _pressed_look := false
var _hovered_look := false

## Shows this disc as pressed with no real press behind it — for a catch-all press that landed
## somewhere else on the screen entirely, which is most of them: `DaySummary`'s own continue never
## required landing on this button, so a `Button`'s native pressed state, which only ever answers
## for a press that actually hit it, covers the minority case and nothing else. Paired with
## `clear_forced_press()`, which every caller has to call before this button is shown again.
## `begin_hold()` calls this too, so `RESTART`'s own timed hold gets the fill immediately rather
## than waiting on `hold_progress` to paint anything.
func force_pressed_look() -> void:
	_pressed_look = true
	_refresh_look()

## Puts the disc back to whichever of resting or hovered `_hovered_look` still says is true —
## `clear_forced_press()` is not `_apply_disc_style()` again, because a mouse can still be sitting
## over the button the instant a press on it ends.
func clear_forced_press() -> void:
	_pressed_look = false
	_refresh_look()

## Whether the mouse currently sits over this button — a laptop's own question, answered by the
## same raw `InputEventMouseMotion` the owning screen reads for nothing else, since
## `MOUSE_FILTER_IGNORE` silences `mouse_entered`/`mouse_exited` the same way it silences a click.
## A pressed look still wins over this one — see `_refresh_look()`.
func set_hovered(hovered: bool) -> void:
	if hovered == _hovered_look:
		return
	_hovered_look = hovered
	_refresh_look()

## The one place the disc's own resting stylebox is written, so pressed and hovered can never
## clobber each other the way two independent `add_theme_stylebox_override("normal", ...)` calls
## would. Only `"normal"` is ever selected for drawing — `Button`'s own `hover`/`pressed`/
## `hover_pressed` styleboxes are installed by `_apply_disc_style()` for completeness but never
## reached, since `MOUSE_FILTER_IGNORE` keeps this control out of `Button`'s own draw-mode switch.
func _refresh_look() -> void:
	var fill := Palette.BUTTON_FILL
	if _pressed_look:
		fill = Palette.BUTTON_PRESSED
	elif _hovered_look:
		fill = Palette.BUTTON_HOVER
	add_theme_stylebox_override("normal", _disc_style(fill))

## The one thing this button paints — see the class comment for why a fill that is not a drawing
## of anything is not a picture. A radial sweep from 12 o'clock clockwise, drawn as a triangle fan
## (`draw_colored_polygon`) clipped to `_RADIUS` rather than a full opaque disc, so the SVG glyph
## underneath still reads through the translucent `_HOLD_FILL` even once `hold_progress` reaches
## 1.0 and the sweep has closed the whole circle. Segment count scales with `hold_progress` rather
## than always drawing `_HOLD_FILL_SEGMENTS` wedges, so a `hold_progress` of 0 needs no fan at all.
func _draw() -> void:
	if symbol != Symbol.RESTART or hold_progress <= 0.0:
		return
	var centre := Vector2(_RADIUS, _RADIUS)
	# -PI/2 is straight up in this control's own local space (y grows downward), so the sweep
	# starts at 12 o'clock; increasing the angle from there moves toward 3, 6 and 9 o'clock in
	# turn, which is clockwise once y is flipped back the way a player actually sees it.
	var start := -PI / 2.0
	var sweep := TAU * hold_progress
	var segments := maxi(1, ceili(_HOLD_FILL_SEGMENTS * hold_progress))
	var points := PackedVector2Array()
	points.append(centre)
	for i in segments + 1:
		var angle := start + sweep * (float(i) / float(segments))
		points.append(centre + Vector2(cos(angle), sin(angle)) * _RADIUS)
	draw_colored_polygon(points, _HOLD_FILL)

## A thumb does not land on a drawn disc to the pixel — `TouchControls.PAUSE_CATCH_RADIUS` is more
## generous than what is drawn, and this button already matches that radius (`_RADIUS`'s own doc).
## Grown by a third again for the same reason, in the coordinate space `PauseScreen`/`DaySummary`
## already convert a raw touch into: `get_global_rect()` on a `Control` under a `CanvasLayer`
## excludes that layer's own rotation transform, landing in the fixed 1280x720 design box every
## screen is authored against — the same box `ScreenOrientation.to_design_space()` converts a raw
## touch into, so the two are directly comparable with no further correction here.
func catch_rect() -> Rect2:
	return get_global_rect().grow(_RADIUS / 3.0)

## The disc itself: one `StyleBoxFlat` per visual state, so the fill comes from data Godot already
## knows how to switch on rather than from a paint call keyed off `get_draw_mode()`.
## `corner_radius_*` at `_RADIUS` — half this button's own `_DIAMETER` — turns the square `Button`
## rect into a circle, the same way rounding a square's corners by half its side always does.
## `content_margin_*` at `_ICON_INSET` is what makes the icon read at `_ICON_SIZE` instead of
## filling the whole disc: `expand_icon` scales the glyph to fill whatever content area the active
## stylebox leaves after its own margins, so the margin is the sizing knob.
func _apply_disc_style() -> void:
	add_theme_stylebox_override("normal", _disc_style(Palette.BUTTON_FILL))
	add_theme_stylebox_override("hover", _disc_style(Palette.BUTTON_HOVER))
	add_theme_stylebox_override("pressed", _disc_style(Palette.BUTTON_PRESSED))
	# Held down while still under the pointer reads as pressed, not as a third shade.
	add_theme_stylebox_override("hover_pressed", _disc_style(Palette.BUTTON_PRESSED))

static func _disc_style(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.corner_radius_top_left = int(_RADIUS)
	box.corner_radius_top_right = int(_RADIUS)
	box.corner_radius_bottom_left = int(_RADIUS)
	box.corner_radius_bottom_right = int(_RADIUS)
	box.content_margin_left = _ICON_INSET
	box.content_margin_right = _ICON_INSET
	box.content_margin_top = _ICON_INSET
	box.content_margin_bottom = _ICON_INSET
	return box
