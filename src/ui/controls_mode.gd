class_name ControlsMode
extends RefCounted
## Which of the two aiming origins `TouchControls` measures a press from — not two mechanisms any
## more, since the drag stick and the destination-walking tap are both gone (see `docs/DECISIONS.md`
## under M82). Both modes share everything else: one press sets a direction, held until the next
## press changes it; a double press runs; a held pointer re-aims. They differ only in **where** a
## press is measured from:
##
## - `JOYSTICK` aims from the nearer of `TouchControls.FOCUS_LEFT`/`FOCUS_RIGHT`, draws both focal
##   circles, and is stopped by a press on a focus or in the stop band down the middle of the screen.
## - `TAP` aims from her own world position, draws nothing, and is stopped by a press within
##   `TouchControls.STOP_RADIUS` of her.
##
## **Neither is tied to a device.** *(2026-09-07, the player: "both modes for in both settings so
## let's let the player choose instead of forcing one ... independent of whether tap is available".)*
## A touchscreen can be set to `TAP` and a mouse can be set to `JOYSTICK` — `TouchInput.available()`
## still answers whether this device has touch hardware, and nothing here reads it any more.
##
## `resolve()` is asked once, before the title screen exists, for the mode a rig gets if it skips
## the title screen entirely (`--no-title`, a screenshot rig): the command line first
## (`--controls joystick|tap`), then the page's own URL (`?controls=joystick|tap`), then `TAP` — the
## wording every existing capture and `--walk` script was taken under, so a rig's back catalogue
## keeps reproducing. **The title screen's own two buttons are not a third step in this order**:
## they are what decides instead of it, every time the title is actually shown — see `TitleScreen`,
## whose buttons are the only pointer way in and always answer the question themselves rather than
## deferring to whatever `resolve()` already set. `main._add_touch_controls()` is `resolve()`'s only
## caller, and `main._on_title_start()` overrides it the moment a player actually presses a button.

enum Mode { JOYSTICK, TAP }

static func resolve() -> Mode:
	var word := DevFlags.controls_override()
	if word == "":
		word = _url_word()
	return from_word(word)

## The bare mapping from a raw word — `DevFlags.controls_override()`'s or `_url_word()`'s own —
## onto a `Mode`. Pulled out so a test can ask the mapping directly without a real command line or
## a Web export to answer through. `"joystick"` is the only word that ever selects it; anything
## else, including an empty string, is `TAP` — the default this milestone settled on.
static func from_word(word: String) -> Mode:
	return Mode.JOYSTICK if word == "joystick" else Mode.TAP

## The page's own `?controls=joystick` or `?controls=tap`, read through
## `JavaScriptBridge.eval("window.location.search")` — the one place in the project that asks the
## browser's own address bar anything. "" outside a Web export, where the address bar does not
## exist to ask, "" for a page with no such parameter, and "" in a release build regardless of the
## query string.
##
## **Gated behind `DevFlags.enabled()`.** *(2026-09-06, the player: "for dev you need it to be
## controllable from the getgo -- for release there should be no modifiers".)* A release build
## carries no modifiers of any kind; a debug build carries every one of them immediately. Through
## `_reads_the_url()` below, so the promise is a truth table a test can check rather than a build
## type nothing can fake.
static func _url_word() -> String:
	if not _reads_the_url(DevFlags.enabled(), OS.get_name() == "Web"):
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search")
	if typeof(search) != TYPE_STRING:
		return ""
	return _word_from_query(search)

## The decision behind `_url_word()`'s own gate, pulled out to a pure function of its two inputs
## rather than welded into the `if` as `DevFlags.enabled() or OS.get_name() != "Web"` — a build type
## and a platform are exactly the two things a test cannot fake, so the untestable half of "a
## release build carries no modifiers" would otherwise be the promise itself. With the predicate
## exposed, a test drives the whole table directly: debug and web is the one case the flag exists
## for; release and web — the deployed page — is the case the promise is actually about; neither
## debug-not-web nor release-not-web ever had a `window.location.search` to ask in the first place.
static func _reads_the_url(is_debug: bool, on_web: bool) -> bool:
	return is_debug and on_web

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
