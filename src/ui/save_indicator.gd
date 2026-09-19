class_name SaveIndicator
extends CanvasLayer
## The small symbol that shows for a few seconds after each write `GameSave` actually makes — see
## docs/MECHANICS.md, "Saving and resuming". Saving itself is silent: there is no save button and
## no screen of its own, so this is the only thing that ever tells the player a write happened.
##
## Its own `CanvasLayer` above every screen, rather than a node added to the pause screen, the day
## summary and the HUD separately — "on whatever screen is up" is exactly the property a
## screen-specific node cannot have without three copies of it. `process_mode = PROCESS_MODE_ALWAYS`,
## the same as `main` itself, because a write during a paused day (a focus loss, or the moment a
## day's own summary appears) still has to fade on the clock rather than freeze mid-fade until the
## tree resumes.
##
## Built once by `main._ready()` and never freed; `flash()` is the only thing anything else calls
## on it. Not built at all under `--start-escape` — the finale never saves (see `GameSave`'s own
## doc on `uses_save()`; it is reachable only behind a dev flag today), so there is nothing for it
## to show there.

## How long the symbol stays fully shown, and how long it then takes to fade — three seconds
## together, chosen as long enough to be noticed once and gone well before the next glance at the
## screen. Two constants rather than one "how long" figure because a reviewer asking "does it fade
## too fast" and one asking "does it stay up too long" are two different questions.
const HOLD_SECONDS := 1.5
const FADE_SECONDS := 1.5
const _TOTAL := HOLD_SECONDS + FADE_SECONDS

## The glyph's own colour — `Palette.CHALK_DONE`, the same soft confirming green a touched chalk
## mark turns, reused rather than invented: this is a confirmation, not a danger cue, and the
## **cues** skill's vocabulary already has a colour for "this went well".
const _TINT := Palette.CHALK_DONE

## Above the title screen's own 95 (`TitleScreen.layer`), so a write mid-boot still shows through
## it rather than being hidden the moment the title opens over a fresh day 1.
const _LAYER := 100

## Bottom-right of the 1280x720 design box: clear of `TouchControls.PAUSE_CENTRE` (top-right) and
## the HUD's `Meters` column (bottom-left, or top-left once `_reposition_meters_for_touch()` moves
## it) — the two corners already claimed.
const _MARGIN := 24.0
const _SIZE := 48.0

const _ICON: Texture2D = preload("res://assets/ui/save.svg")

var _icon_rect: TextureRect

## Counts down through `HOLD_SECONDS` at full opacity and then through `FADE_SECONDS` to none.
## Negative means nothing is showing, which is where a run that has never written yet starts.
var _remaining := -1.0

func _init() -> void:
	layer = _LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# Fixed to the 1280x720 box every screen is authored against, the same as every other rotating
	# layer's own root — see `ScreenOrientation.pin_to_design_box()`'s own doc.
	ScreenOrientation.pin_to_design_box(root)
	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_icon_rect.texture = _ICON
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.anchor_left = 1.0
	_icon_rect.anchor_top = 1.0
	_icon_rect.anchor_right = 1.0
	_icon_rect.anchor_bottom = 1.0
	_icon_rect.offset_left = -_MARGIN - _SIZE
	_icon_rect.offset_top = -_MARGIN - _SIZE
	_icon_rect.offset_right = -_MARGIN
	_icon_rect.offset_bottom = -_MARGIN
	_icon_rect.modulate = Color(_TINT.r, _TINT.g, _TINT.b, 0.0)
	root.add_child(_icon_rect)

## Called by `main._save_now()` once a write actually happened — never on a run `GameSave.write()`
## already refused (a dev flag, a headless run, or one already ended), so the symbol is drawn on
## exactly the runs that draw it at all. Restarts the hold from full even mid-fade, so two writes
## close together (a dawn write immediately followed by a focus-loss write) read as one continuous
## mark rather than a flicker.
func flash() -> void:
	_remaining = _TOTAL
	_apply_alpha()

func _process(delta: float) -> void:
	if _remaining < 0.0:
		return
	_remaining -= delta
	_apply_alpha()
	if _remaining <= 0.0:
		_remaining = -1.0

func _apply_alpha() -> void:
	var alpha := 0.0
	if _remaining > FADE_SECONDS:
		alpha = 1.0
	elif _remaining > 0.0:
		alpha = _remaining / FADE_SECONDS
	_icon_rect.modulate = Color(_TINT.r, _TINT.g, _TINT.b, _TINT.a * alpha)
