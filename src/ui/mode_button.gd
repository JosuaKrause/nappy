class_name ModeButton
extends Button
## A button that reads as one and carries the symbol for the mode it selects.
##
## `Stick` and `Tap` under `Root/Bottom/Lines/Choice` in `scenes/ui/title_screen.tscn` were plain
## `Button` nodes with only a minimum size, a font size and wrapping — nothing to make them read
## as more than the label text above them. `flat = true` turns Godot's own button theme off
## entirely and leaves the fill, the border and the two pressed/hover states to this file's
## `_draw()` instead, drawn with the same primitives and the same `2.0`-weight stroke
## `TouchControls._draw()` already uses for the on-screen stick, `RUN` and pause, so a control
## drawn here and one drawn on the touch HUD read as one hand rather than two.
##
## A small reusable control rather than a one-off inside `title_screen.gd`, because the pause
## screen and the day summary want the same two buttons next — see `docs/TODO.md`'s M76 queue —
## and a second hand-drawn button style the day this reaches those screens is the same failure
## the **cues** rule names for a second hand-drawn chevron: a short, deliberate vocabulary is how
## it stays short.

## The mode this button's symbol names. Set per instance by the scene that places it.
enum Symbol { STICK, TAP }
@export var symbol: Symbol = Symbol.STICK

## Matches `TouchControls`' own outline weight (`_draw_stick()`, `_draw_run_button()`,
## `_draw_pause_button()`) so this button and the touch HUD's controls read as one vocabulary.
const _STROKE := 2.0
## Both symbols share one radius, so neither reads as the more important half of the choice. Kept
## small and tucked into the corner rather than centred, because the label text this button
## already carries (`TitleScreen._refresh_choice()`) is centred across the same box and a bigger
## badge would sit on top of it rather than beside it.
const _SYMBOL_RADIUS := 13.0
const _SYMBOL_INSET := 11.0

func _ready() -> void:
	# Godot's own flat theme is what made these read as label text — see the class comment. With
	# it off, `_draw()` below is the whole of what this button looks like.
	flat = true
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var fill := Palette.BUTTON_FILL
	match get_draw_mode():
		DRAW_PRESSED:
			fill = Palette.BUTTON_FILL_PRESSED
		DRAW_HOVER, DRAW_HOVER_PRESSED:
			fill = Palette.BUTTON_FILL_HOVER
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, fill)
	draw_rect(rect, Palette.BUTTON_BORDER, false, _STROKE)
	var centre := Vector2(_SYMBOL_INSET + _SYMBOL_RADIUS, _SYMBOL_INSET + _SYMBOL_RADIUS)
	if symbol == Symbol.STICK:
		_draw_stick(centre)
	else:
		_draw_tap(centre)

## A joystick: a base ring, a short stalk and a knob offset from centre — the shape of the stick
## scheme whichever device actually plays it, keyboard or the on-screen stick alike.
func _draw_stick(centre: Vector2) -> void:
	draw_arc(centre, _SYMBOL_RADIUS, 0.0, TAU, 24, Palette.BUTTON_SYMBOL, _STROKE)
	var knob := centre + Vector2(_SYMBOL_RADIUS, -_SYMBOL_RADIUS) * 0.4
	draw_line(centre, knob, Palette.BUTTON_SYMBOL, _STROKE)
	draw_circle(knob, _SYMBOL_RADIUS * 0.34, Palette.BUTTON_SYMBOL)

## A contact dot with two ripples opening from it — the shape a tap actually makes on the ground,
## rather than a finger or a hand.
func _draw_tap(centre: Vector2) -> void:
	draw_circle(centre, _SYMBOL_RADIUS * 0.2, Palette.BUTTON_SYMBOL)
	draw_arc(centre, _SYMBOL_RADIUS * 0.58, 0.0, TAU, 24, Palette.BUTTON_SYMBOL, _STROKE)
	draw_arc(centre, _SYMBOL_RADIUS, 0.0, TAU, 24, Palette.BUTTON_SYMBOL, _STROKE)
