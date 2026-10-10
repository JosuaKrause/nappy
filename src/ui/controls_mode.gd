class_name ControlsMode
extends RefCounted
## The player's choice of aiming origin, and in joystick mode of the side that steers. Both modes
## lock a heading from a press, run on a double press and re-aim while dragging.
##
## - JOYSTICK aims from the steering focus on the chosen `Side`; the other focus is Run, from the
##   first frame of play. The side is chosen on the title and never swaps during play *(2026-10-10,
##   the player: "selecting the left one will make the left side permanently joystick and the right
##   side permanently run button (permanently for the sitting)")*. See `TouchControls`.
## - TAP aims from her world position, stopping within TouchControls.TAP_STOP_RADIUS of her.
##
## **Neither is tied to a device.** *(2026-09-07, the player: "both modes for in both settings so
## let's let the player choose instead of forcing one ... independent of whether tap is available".)*
## A touchscreen can be set to `TAP` and a mouse can be set to `JOYSTICK` — `TouchInput.available()`
## still answers whether this device has touch hardware, and nothing here reads it any more.
##
## `resolve()` is asked once, before the title screen exists, for the mode a rig gets if it skips
## the title screen entirely (`--no-title`, a screenshot rig): the command line first
## (`--controls joystick|joystick-right|tap`), then the page's own URL (`?controls=`, the same
## words), then `TAP` — the
## wording every existing capture and `--walk` script was taken under, so a rig's back catalogue
## keeps reproducing. **The title screen's own two buttons are not a third step in this order**:
## they are what decides instead of it, every time the title is actually shown — see `TitleScreen`,
## whose buttons are the only pointer way in and always answer the question, the side included,
## rather than deferring to whatever `resolve()` already set. `main._add_touch_controls()` is
## `resolve()`'s and `resolve_side()`'s only caller, and `main._on_title_start()` overrides both the
## moment a player actually presses a button.

enum Mode { JOYSTICK, TAP }
## Which half of the screen steers in `Mode.JOYSTICK`; the other half is Run. Meaningless in
## `Mode.TAP`, where nothing is drawn to choose between.
enum Side { LEFT, RIGHT }

## The title's last answer this sitting, kept across a scene reload. `static var`s on the class
## rather than members on a node, for the reason `TitleScreen._restarted_at_msec` is one:
## `reload_current_scene()` frees every node, and the script class is never unloaded, so this is the
## one place the answer survives the day-14 hand-over to the escape, whose boot builds its controls
## afresh *(2026-10-10, the player: "permanently for the sitting")*. Process memory only, never saved:
## a page opened again asks on its title. `remember()` writes it; `main._add_touch_controls()` reads
## it on the escape's hand-over boot alone, since every other boot's title asks anyway.
static var _remembered := false
static var _remembered_mode := Mode.TAP
static var _remembered_side := Side.LEFT

## Keeps the title's answer for the rest of the sitting — see `_remembered`.
static func remember(mode: ControlsMode.Mode, side: ControlsMode.Side) -> void:
	_remembered = true
	_remembered_mode = mode
	_remembered_side = side

## Whether the title has answered this sitting — see `_remembered`.
static func has_remembered() -> bool:
	return _remembered

static func remembered_mode() -> ControlsMode.Mode:
	return _remembered_mode

static func remembered_side() -> ControlsMode.Side:
	return _remembered_side

static func resolve() -> Mode:
	var word := DevFlags.controls_override()
	if word == "":
		word = _url_word()
	return from_word(word)

## The bare mapping from a raw word — `DevFlags.controls_override()`'s or `_url_word()`'s own —
## onto a `Mode`. Pulled out so a test can ask the mapping directly without a real command line or
## a Web export to answer through. `"joystick"`, `"joystick-left"` and `"joystick-right"` select
## it; anything else, including an empty string, is `TAP`.
static func from_word(word: String) -> Mode:
	return Mode.JOYSTICK if word in ["joystick", "joystick-left", "joystick-right"] else Mode.TAP

## The steering side a rig gets with the mode `resolve()` answers: `joystick-right` steers from the
## right, and every other word — `joystick` and `joystick-left` included — from the left. Only a
## rig that skips the title reads it; the title's two joystick buttons choose the side themselves.
static func resolve_side() -> ControlsMode.Side:
	var word := DevFlags.controls_override()
	if word == "":
		word = _url_word()
	return side_from_word(word)

## The bare mapping behind `resolve_side()`, for a test to ask without a command line.
static func side_from_word(word: String) -> ControlsMode.Side:
	return Side.RIGHT if word == "joystick-right" else Side.LEFT

## The page's own `?controls=joystick` or `?controls=tap`, read through
## `JavaScriptBridge.eval("window.location.search")` — the one place in the project that asks the
## browser's own address bar anything. "" outside a Web export, where the address bar does not
## exist to ask, "" for a page with no such parameter, and "" on a release page nobody asked
## `?debug=1` of.
##
## **Gated behind `DevFlags.live_debug_requested()`.** *(2026-09-06, the player: "for dev you need
## it to be controllable from the getgo -- for release there should be no modifiers"; overturned
## 2026-09-25 for this flag among others, docs/DECISIONS.md, M193, "the live page's ?debug=1 reaches the
## debug flags": "on the published site behind debug=1 we'd want some of the debug flags ... so
## debugging the live build is easier".)* A debug build carries the query read immediately, with or
## without `?debug=1`; a release page carries it only once its own `?debug=1` has asked for it.
## Through `_reads_the_url()` below, so the promise is a truth table a test can check rather than
## two live reads nothing in a test process can fake at once.
static func _url_word() -> String:
	if not _reads_the_url(DevFlags.live_debug_requested(), OS.get_name() == "Web"):
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search")
	if typeof(search) != TYPE_STRING:
		return ""
	return _word_from_query(search)

## The decision behind `_url_word()`'s own gate, pulled out to a pure function of its two inputs
## rather than welded into the `if` as `DevFlags.live_debug_requested() or OS.get_name() != "Web"`
## — a build type and a live page query are exactly the two things a test cannot fake at once, so
## the untestable half of the gate would otherwise be the promise itself. With the predicate
## exposed, a test drives the whole table directly: `flags_open` and web is the one case the flag
## exists for; neither `flags_open`-not-web nor closed-not-web ever had a `window.location.search`
## to ask in the first place.
static func _reads_the_url(flags_open: bool, on_web: bool) -> bool:
	return flags_open and on_web

## `"?controls=joystick&seed=4"` (or without the leading `?`) to `"joystick"`, or `""` for a query
## with no `controls` key. Pulled out from `_url_word()` so a test can ask the parsing question
## directly, without a Web export to produce a real `window.location.search` to parse.
static func _word_from_query(query: String) -> String:
	var trimmed := query.trim_prefix("?")
	for pair in trimmed.split("&"):
		var parts := pair.split("=")
		if parts.size() == 2 and parts[0] == "controls":
			return parts[1]
	return ""
