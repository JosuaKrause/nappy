class_name ModeButton
extends Button
## A circular, icon-only button: a solid filled disc in a colour of its own, with a white glyph
## for the mode it selects and no text inside it at all.
##
## `Stick` and `Tap` under `Root/Bottom/Lines/Choice` in `scenes/ui/title_screen.tscn` first tried
## a 380x100 rectangle with the mode's own paragraph inside it and a small badge tucked into a
## corner. That collided by construction: the paragraph is three sentences of body copy dense
## enough that no corner of a 100px-tall button is ever entirely free of it, badge or no badge, so
## the button that was supposed to make the choice *more* obvious still buried a symbol under
## text. Moving the paragraph outside the button entirely — see `TitleScreen._stick_caption` and
## `_tap_caption`, plain `Label`s the scene places below each button rather than children of it —
## removes the collision at its root instead of laying icon and text out around each other: there
## is no text inside this control for a symbol to compete with.
##
## `flat = true` turns off Godot's own button theme, and `_draw()` supplies the whole of what this
## button looks like: a filled circle, darkened or lightened per `get_draw_mode()` for the
## pressed/hover feedback a flat control would otherwise drop, and the symbol on top of it.
##
## A small reusable control rather than a one-off inside `title_screen.gd`, because the pause
## screen and the day summary want the same button next, for `Symbol.RESTART` and
## `Symbol.CONTINUE` — reserved on the enum below and left undrawn, since building their behaviour
## is a later item in `docs/TODO.md`'s M76 queue and a second hand-drawn button style the day it
## arrives is the same failure the **cues** rule names for a second hand-drawn chevron.

## The mode this button's symbol names. `RESTART` and `CONTINUE` are reserved for the pause screen
## and the day summary and have no symbol drawn yet — see the class comment.
enum Symbol { STICK, TAP, RESTART, CONTINUE }
@export var symbol: Symbol = Symbol.STICK
## The disc's own colour, per instance rather than baked into this file: the four eventual modes
## each read as a different button (`Palette.MODE_STICK`, `Palette.MODE_TAP`, and — not yet
## assigned — a restart and a continue colour), which a single shared fill could not tell apart.
@export var fill_colour: Color = Palette.MODE_STICK

## `TouchControls`' own three catch radii are `STICK_CATCH_RADIUS` (100px), `RUN_CATCH_RADIUS`
## (76px) and `PAUSE_CATCH_RADIUS` (46px) — the smallest a thumb is ever asked to land inside
## during a run. This button is opened on the same phone, so its own radius is the floor of that
## set rather than a value chosen for a mouse: nothing on this screen may be harder to hit than
## the least generous control already in the game.
const _RADIUS := 46.0
const _DIAMETER := _RADIUS * 2.0
## Roughly half the disc's own diameter, matching the reference this button is drawn from ("the
## glyphs ... occupying maybe half the circle's diameter").
const _ICON_RADIUS := _RADIUS * 0.5
## About a tenth of the disc's radius, the reference's own stroke weight for the glyphs.
const _STROKE := _RADIUS * 0.1
const _ICON_COLOR := Color(0.97, 0.96, 0.94, 1.0)

func _ready() -> void:
	flat = true
	custom_minimum_size = Vector2(_DIAMETER, _DIAMETER)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var shade := fill_colour
	match get_draw_mode():
		DRAW_PRESSED:
			shade = fill_colour.darkened(0.2)
		DRAW_HOVER, DRAW_HOVER_PRESSED:
			shade = fill_colour.lightened(0.12)
	var centre := size * 0.5
	draw_circle(centre, _RADIUS, shade)
	match symbol:
		Symbol.STICK:
			_draw_stick(centre)
		Symbol.TAP:
			_draw_tap(centre)
		_:
			# Symbol.RESTART, Symbol.CONTINUE: reserved for the pause screen and the day summary —
			# see the class comment. Nothing to draw yet.
			pass

## A joystick, side-on: a small plinth, a stalk rising from it and a ball at the top — the
## reference's own "a ball on top of a vertical stalk rising from a small square plinth drawn in
## slight perspective". The plinth is a plain rectangle rather than a perspective quad: this file
## draws with `draw_circle`/`draw_arc`/`draw_line`/`draw_rect` only, the same primitives-only rule
## `TouchControls._draw()` follows, and a quad is not one of them.
func _draw_stick(centre: Vector2) -> void:
	var r := _ICON_RADIUS
	var plinth_size := Vector2(r * 1.1, r * 0.34)
	var plinth_rect := Rect2(
			centre + Vector2(-plinth_size.x * 0.5, r * 0.6 - plinth_size.y * 0.5), plinth_size)
	draw_rect(plinth_rect, _ICON_COLOR)
	var stalk_top := centre + Vector2(0.0, -r * 0.55)
	var stalk_bottom := centre + Vector2(0.0, plinth_rect.position.y)
	draw_line(stalk_bottom, stalk_top, _ICON_COLOR, _STROKE)
	draw_circle(stalk_top, r * 0.42, _ICON_COLOR)

## A pointing hand and the tap ripple above its fingertip — the reference's own "a hand in white
## silhouette with the index finger pointing up, and two concentric arcs above the fingertip".
## Simplified to a fist (a circle) and a raised index finger (a rectangle) rather than an
## articulated hand, for the same primitives-only reason `_draw_stick()` simplifies its plinth.
func _draw_tap(centre: Vector2) -> void:
	var r := _ICON_RADIUS
	var fist_radius := r * 0.42
	var fist_centre := centre + Vector2(0.0, r * 0.35)
	draw_circle(fist_centre, fist_radius, _ICON_COLOR)
	var finger_size := Vector2(r * 0.28, r * 0.75)
	var finger_rect := Rect2(
			fist_centre + Vector2(-finger_size.x * 0.5, -fist_radius - finger_size.y * 0.72),
			finger_size)
	draw_rect(finger_rect, _ICON_COLOR)
	var tip := Vector2(centre.x, finger_rect.position.y)
	draw_arc(tip, r * 0.4, PI * 1.15, PI * 1.85, 16, _ICON_COLOR, _STROKE)
	draw_arc(tip, r * 0.66, PI * 1.15, PI * 1.85, 16, _ICON_COLOR, _STROKE)
