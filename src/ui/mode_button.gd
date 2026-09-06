class_name ModeButton
extends Button
## A circular, icon-only button: a round disc with a tinted glyph for the mode it selects and no
## text inside it at all.
##
## **Nothing here is painted.** *(2026-09-06, the player: "never draw in code -- at the very least
## use svgs".)* The disc is a `StyleBoxFlat` per state (`normal`/`hover`/`pressed`), its
## `corner_radius_*` set to half the button's own size so a square `Button` renders as a circle,
## and the glyph is the button's own `icon` — a preloaded SVG under `assets/ui/`, tinted through
## `icon_normal_color` and its per-state siblings rather than drawn. Two earlier versions of this
## file painted the disc and the glyphs by hand in `_draw()`; both are gone, along with `_draw()`
## itself, because a picture is an asset the moment a person could call it one, and evaluating one
## means opening `assets/ui/joystick.svg` or `tap.svg` directly rather than running the game to see
## what code produced.
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
## screen and the day summary want the same button next, for `Symbol.RESTART` and
## `Symbol.CONTINUE` — reserved on the enum below and left with no icon, since building their
## behaviour is a later item in `docs/TODO.md`'s M76 queue.

## The mode this button's icon names. `RESTART` and `CONTINUE` are reserved for the pause screen
## and the day summary and have no icon assigned yet — see the class comment.
enum Symbol { STICK, TAP, RESTART, CONTINUE }
@export var symbol: Symbol = Symbol.STICK

const _STICK_ICON: Texture2D = preload("res://assets/ui/joystick.svg")
const _TAP_ICON: Texture2D = preload("res://assets/ui/tap.svg")

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

func _ready() -> void:
	custom_minimum_size = Vector2(_DIAMETER, _DIAMETER)
	_apply_disc_style()
	icon = _STICK_ICON if symbol == Symbol.STICK else (_TAP_ICON if symbol == Symbol.TAP else null)
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	expand_icon = true
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
			"icon_hover_pressed_color", "icon_focused_color", "icon_disabled_color"]:
		add_theme_color_override(state, Palette.BUTTON_SYMBOL)

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
