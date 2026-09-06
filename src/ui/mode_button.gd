class_name ModeButton
extends Button
## A circular, icon-only button: a round disc with a tinted glyph for the mode it selects and no
## text inside it at all.
##
## **No glyph is painted.** *(2026-09-06, the player: "never draw in code -- at the very least use
## svgs".)* The disc is a `StyleBoxFlat` per state (`normal`/`hover`/`pressed`), its
## `corner_radius_*` set to half the button's own size so a square `Button` renders as a circle,
## and every glyph is the button's own `icon` — a preloaded SVG under `assets/ui/`, tinted through
## `icon_normal_color` and its per-state siblings rather than drawn. Two earlier versions of this
## file painted the disc and the glyphs by hand in `_draw()`; both are gone, because a picture is
## an asset the moment a person could call it one, and evaluating one means opening
## `assets/ui/joystick.svg` or `tap.svg` directly rather than running the game to see what code
## produced.
##
## **`_draw()` is back, for exactly one thing that is not a picture: `RESTART`'s own hold-fill
## bar.** A rectangle whose width tracks `hold_progress` is layout the same way `MeterBar`'s own
## fill is — see the **cues** rule's own exception for a bar that is not a drawing of anything —
## and a `Button` has no stock control for "fills while held", so this is the one place the **cues**
## rule's own "prefer the engine's data" clause has nothing to prefer.
##
## **Every button shares one neutral fill (`Palette.BUTTON_FILL`/`BUTTON_HOVER`/`BUTTON_PRESSED`)
## rather than a colour per mode.** A hue in this project already means something
## (`Palette.SIGNAL_RED`/`AMBER`/`GREEN` are the lights, `MARK_COSTLY`/`MARK_LETHAL` are what an
## event costs), and a menu spending two more saturated hues on which button is which teaches a
## distinction that means nothing anywhere else in the game — the **cues** rule against a second
## hand-drawn vocabulary, aimed at colour instead of a shape. The glyph carries the whole
## difference between the two buttons.
##
## `Stick` and `Tap` under `Root/Bottom/Lines/Choice` in `scenes/ui/title_screen.tscn` first tried
## a 380x100 rectangle with the mode's own paragraph inside it. That collided by construction: the
## paragraph is three sentences of body copy dense enough that no corner of a 100px-tall button is
## ever entirely free of it. Moving the paragraph outside the button entirely — see
## `TitleScreen._stick_caption` and `_tap_caption`, plain `Label`s the scene places below each
## button rather than children of it — removes the collision at its root: there is no text inside
## this control for a glyph to compete with.
##
## A small reusable control rather than a one-off inside `title_screen.gd`, because the pause
## screen and the day summary share the same pair of buttons, for `Symbol.RESTART` and
## `Symbol.CONTINUE` — one interaction learned once rather than a different control on each
## screen. `RESTART`'s own hold-fill bar lives here too, so both screens drive the same drawing
## through `hold_progress` rather than each screen painting its own.

## The mode this button's icon names.
enum Symbol { STICK, TAP, RESTART, CONTINUE }
@export var symbol: Symbol = Symbol.STICK

const _STICK_ICON: Texture2D = preload("res://assets/ui/joystick.svg")
const _TAP_ICON: Texture2D = preload("res://assets/ui/tap.svg")
const _RESTART_ICON: Texture2D = preload("res://assets/ui/restart.svg")
const _CONTINUE_ICON: Texture2D = preload("res://assets/ui/continue.svg")

const _ICON_BY_SYMBOL := {
	Symbol.STICK: _STICK_ICON,
	Symbol.TAP: _TAP_ICON,
	Symbol.RESTART: _RESTART_ICON,
	Symbol.CONTINUE: _CONTINUE_ICON,
}

## `TouchControls`' own three catch radii are `STICK_CATCH_RADIUS` (100px), `RUN_CATCH_RADIUS`
## (76px) and `PAUSE_CATCH_RADIUS` (46px) — the smallest a thumb is ever asked to land inside
## during a run. This button is opened on the same phone, so its own radius is the floor of that
## set rather than a value chosen for a mouse: nothing on this screen may be harder to hit than
## the least generous control already in the game.
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

## Reserved below the disc for `RESTART`'s own hold-fill bar — see `_draw()`.
const _HOLD_BAR_GAP := 10.0
const _HOLD_BAR_HEIGHT := 6.0
const _HOLD_BAR_TRACK := Color(1.0, 1.0, 1.0, 0.22)

## About a second, per the design this milestone builds rather than invents — *(2026-09-06:
## "restart game (must be held down so a bar needs to fill up while pressing".)*
const RESTART_HOLD_SECONDS := 1.0

## The touch index currently holding this button, or -1 when nothing is — the same shape
## `TouchControls._stick_touch` and its siblings already track a touch by. Only ever non‑`-1` for
## `Symbol.RESTART`; the other three symbols never call `begin_hold()`.
var _held_by := -1
## `Time.get_ticks_msec() / 1000.0` when `_held_by` was grabbed, so `_process()` can measure the
## hold against `RESTART_HOLD_SECONDS` without keeping its own delta accumulator.
var _held_since := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(_DIAMETER,
			_DIAMETER + _HOLD_BAR_GAP + _HOLD_BAR_HEIGHT if symbol == Symbol.RESTART else _DIAMETER)
	_apply_disc_style()
	icon = _ICON_BY_SYMBOL.get(symbol)
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	expand_icon = true
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
			"icon_hover_pressed_color", "icon_focused_color", "icon_disabled_color"]:
		add_theme_color_override(state, Palette.BUTTON_SYMBOL)

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
	return held >= RESTART_HOLD_SECONDS

## Lets go of whatever this button is holding without completing it — for a screen that closes, or
## reopens, while a thumb is still down, the same reason `TouchControls._release_all()` exists.
func cancel_hold() -> void:
	_held_by = -1
	hold_progress = 0.0

## Shows this disc as pressed with no real press behind it — for a catch-all press that landed
## somewhere else on the screen entirely, which is most of them: `DaySummary`'s own continue never
## required landing on this button, so a `Button`'s native pressed state, which only ever answers
## for a press that actually hit it, covers the minority case and nothing else. Paired with
## `clear_forced_press()`, which every caller has to call before this button is shown again — this
## overrides the *resting* state itself rather than the momentary one, so it does not clear on its
## own the way a real press does.
func force_pressed_look() -> void:
	add_theme_stylebox_override("normal", _disc_style(Palette.BUTTON_PRESSED))

## Puts the disc back to its three ordinary states — `_apply_disc_style()` is idempotent, so this
## is that call again rather than a second implementation of what "normal" looks like.
func clear_forced_press() -> void:
	_apply_disc_style()

## The one thing this button paints — see the class comment for why a fill bar is not a picture.
## Drawn under the disc rather than around it, at the width `_HOLD_BAR_GAP`/`_HOLD_BAR_HEIGHT`
## already reserved in `custom_minimum_size`, so it never overlaps the glyph or the disc's own rim.
func _draw() -> void:
	if symbol != Symbol.RESTART:
		return
	var track := Rect2(0.0, _DIAMETER + _HOLD_BAR_GAP, _DIAMETER, _HOLD_BAR_HEIGHT)
	draw_rect(track, _HOLD_BAR_TRACK)
	if hold_progress > 0.0:
		draw_rect(Rect2(track.position, Vector2(track.size.x * hold_progress, track.size.y)),
				Palette.BUTTON_SYMBOL)

## A thumb does not land on a drawn disc to the pixel — every one of `TouchControls`' own catch
## radii is more generous than what is drawn, and this button already sits at that set's own floor
## (`_RADIUS`'s own doc). Grown by a third again for the same reason, in the coordinate space
## `PauseScreen`/`DaySummary` already convert a raw touch into: `get_global_rect()` on a `Control`
## under a `CanvasLayer` excludes that layer's own rotation transform, landing in the fixed
## 1280x720 design box every screen is authored against — the same box
## `ScreenOrientation.to_design_space()` converts a raw touch into, so the two are directly
## comparable with no further correction here.
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
	# Held down while still under the pointer reads as pressed, not as a third shade — the same
	# two states TouchControls._draw_run_button() varies between for held vs not.
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
