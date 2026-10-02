class_name SaveIndicator
extends CanvasLayer
## The small symbol that shows while a save is being kept and for a few seconds after — see
## docs/MECHANICS.md, "Saving and resuming". Saving itself is silent: there is no save button and
## no screen of its own, so this is the only thing that ever tells the player a save happened, or
## that it could not be kept.
##
## **It stays fully shown, with no timer running, until the save is confirmed.** *(cozy-pelican,
## 2026-10-02: "we should show it until it is fully confirmed saved. also, if saving is unavailable
## it should show up with a strike through".)* `begin()` raises it when a save starts and
## `settle()` answers it — on the web only once the browser has said whether IndexedDB kept the
## file, see `GameSave.write()` — and only then do the hold and the fade run. A save that was not
## kept shows `art/ui/save_unavailable.svg` instead, the same disk struck through, held and faded
## the same way.
##
## Its own `CanvasLayer` above every screen, rather than a node added to the pause screen, the day
## summary and the HUD separately — "on whatever screen is up" is exactly the property a
## screen-specific node cannot have without three copies of it. `process_mode = PROCESS_MODE_ALWAYS`,
## the same as `main` itself, because a save made as the tree pauses (the moment a day's own
## summary appears) still has to fade on the clock rather than freeze mid-fade until the tree
## resumes.
##
## Built once by `main._ready()` and never freed; `begin()` and `settle()` are the only things
## anything else calls on it. Not built at all under `--start-escape` — the finale never saves
## (see `GameSave`'s own doc on `uses_save()`; it is reachable only behind a dev flag today), so
## there is nothing for it to show there.

## How long the symbol stays fully shown once the save is settled, and how long it then takes to
## fade — three seconds together, chosen as long enough to be noticed once and gone well before the
## next glance at the screen. Two constants rather than one "how long" figure because a reviewer
## asking "does it fade too fast" and one asking "does it stay up too long" are two different
## questions.
const HOLD_SECONDS := 1.5
const FADE_SECONDS := 1.5
const _TOTAL := HOLD_SECONDS + FADE_SECONDS

## The fade's own peak alpha, once fully shown — the same figure `Palette.CHALK_DONE.a` carried
## back when this modulate also tinted the icon green. `art/ui/save.svg` now carries its own
## blue case, silver-gray shutter and paper label (PLAYTEST-95: "make it bluish and the metal
## parts should be silver/gray"), so this modulate only ever multiplies alpha: a colour here would
## multiply into the icon's own hues and turn the blue case back toward green-gray, which is the
## bug a shared tint constant would reintroduce.
const _PEAK_ALPHA := 0.9

## Above the title screen's own 95 (`TitleScreen.layer`), so a write mid-boot still shows through
## it rather than being hidden the moment the title opens over a fresh day 1.
const _LAYER := 100

## Bottom-right of the 1280x720 design box: clear of `TouchControls.PAUSE_CENTRE` (top-right) and
## the HUD's `Meters` column (bottom-left, or top-left once `_reposition_meters_for_touch()` moves
## it) — the two corners already claimed.
const _MARGIN := 24.0
const _SIZE := 48.0

## Region names on the `ui` atlas group; `_enter_tree()`/`_exit_tree()` acquire and release it.
## `_ICON_UNAVAILABLE` is the same disk struck through (`art/ui/save_unavailable.svg`), shown in
## place of `_ICON` when a save was not kept — a second picture rather than a strike drawn over the
## first, since a picture is an asset, never code (the **cues** skill).
const _ICON := &"ui/save"
const _ICON_UNAVAILABLE := &"ui/save_unavailable"

## The symbol's timeline apart from the node that draws it, so a test can drive every state
## without a tree, an atlas or a frame.
class Showing extends RefCounted:
	## Saves begun and not yet settled. While any is out the symbol is fully shown and no timer
	## runs, so a second save during a first keeps it up until both are answered.
	var pending := 0
	## Whether a save in this showing was not kept. Cleared when a save begins with nothing else
	## pending, since that save's own outcome is not known yet.
	var struck := false
	## Counts down through the hold and then the fade once nothing is pending. Negative means not
	## counting, which is where a symbol that has never shown starts.
	var remaining := -1.0

	func begin() -> void:
		if pending == 0:
			struck = false
		pending += 1
		remaining = -1.0

	## A settle with nothing pending is ignored rather than counted against a later save.
	func settle(kept: bool) -> void:
		if pending == 0:
			return
		pending -= 1
		if not kept:
			struck = true
		if pending == 0:
			remaining = _TOTAL

	func advance(delta: float) -> void:
		if pending > 0 or remaining < 0.0:
			return
		remaining -= delta
		if remaining <= 0.0:
			remaining = -1.0

	## How much of the symbol shows, from 0 to 1, before `_PEAK_ALPHA` scales it.
	func alpha() -> float:
		if pending > 0 or remaining > FADE_SECONDS:
			return 1.0
		if remaining > 0.0:
			return remaining / FADE_SECONDS
		return 0.0

	func is_idle() -> bool:
		return pending == 0 and remaining < 0.0

var _icon_rect: TextureRect
var _plain_texture: Texture2D
var _struck_texture: Texture2D
var _showing := Showing.new()

func _init() -> void:
	layer = _LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"ui")

func _exit_tree() -> void:
	AtlasLibrary.release(&"ui")

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
	_plain_texture = AtlasLibrary.region(_ICON)
	_struck_texture = AtlasLibrary.region(_ICON_UNAVAILABLE)
	_icon_rect.texture = _plain_texture
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
	_icon_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root.add_child(_icon_rect)

## Called by `main._save_now()` the moment a save starts — never for a run `GameSave.write()`
## refuses (a dev flag, a headless run, or one already ended), so the symbol is drawn on exactly
## the runs that save at all. Fully shown from here until `settle()`, even mid-fade.
func begin() -> void:
	_showing.begin()
	_apply()

## Answers one `begin()`: `kept` is whether the save was confirmed. The hold and the fade start
## once every save begun is answered, struck through if any of them was not kept.
func settle(kept: bool) -> void:
	_showing.settle(kept)
	_apply()

func _process(delta: float) -> void:
	if _showing.is_idle():
		return
	_showing.advance(delta)
	_apply()

func _apply() -> void:
	if not _icon_rect:
		return
	_icon_rect.modulate = Color(1.0, 1.0, 1.0, _PEAK_ALPHA * _showing.alpha())
	var texture := _struck_texture if _showing.struck else _plain_texture
	if _icon_rect.texture != texture:
		_icon_rect.texture = texture

## Whether the picture on screen is the struck-through one — what a test reads, since a headless
## run draws nothing to look at.
func shows_struck() -> bool:
	return _icon_rect != null and _icon_rect.texture == _struck_texture
