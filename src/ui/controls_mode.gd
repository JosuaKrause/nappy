class_name ControlsMode
extends RefCounted
## Which of the two ways to say where she goes is driving this run: the on-screen stick (and the
## keyboard and RUN button it mirrors) or a tap that walks her there in a straight line.
##
## Exactly one is active, read once the way `TouchInput.available()` already is, because
## `TouchControls` and `TapControls` are two different nodes rather than two branches of one --
## only one of them ever belongs in the tree at a time. See `main._add_touch_controls()`.
##
## Resolved in this order: the local command line first (`--controls tap|stick`, gated behind
## `DevFlags.enabled()` like every other developer flag), then the page's own URL
## (`?controls=tap`), then the stick, which is every build's own behaviour with neither asked.
##
## The command line wins over the URL because it is the more deliberate of the two — a debug Web
## build carrying both is somebody testing one channel against the other, and the one they typed
## for this run is the one they meant. **The URL is the one flag in the project not gated behind
## `DevFlags.enabled()`, and that is the point rather than an oversight**: that gate is
## `OS.is_debug_build()`, `false` for the exported release template `tools/export-web.sh` produces,
## and the deployed page is precisely where the command line cannot reach — "a secret url flag for
## now", in the player's own words. What keeps it safe is its scope, not a build gate: it chooses
## between two control schemes that both ship and are both playable, and it can reach nothing else.
enum Mode { STICK, TAP }

static func resolve() -> Mode:
	var word := DevFlags.controls_override()
	if word == "":
		word = _url_word()
	return from_word(word)

## The bare mapping from a raw word — `DevFlags.controls_override()`'s or `_url_word()`'s own —
## onto a `Mode`. Pulled out so a test can ask the mapping directly without a real command line or
## a Web export to answer through.
static func from_word(word: String) -> Mode:
	return Mode.TAP if word == "tap" else Mode.STICK

## The page's own `?controls=tap` or `?controls=stick`, read through
## `JavaScriptBridge.eval("window.location.search")` — the one place in the project that asks the
## browser's own address bar anything. "" outside a Web export, where the address bar does not
## exist to ask, and "" for a page with no such parameter.
static func _url_word() -> String:
	if OS.get_name() != "Web":
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search")
	if typeof(search) != TYPE_STRING:
		return ""
	return _word_from_query(search)

## `"?controls=tap&seed=4"` (or without the leading `?`) to `"tap"`, or `""` for a query with no
## `controls` key. Pulled out from `_url_word()` so a test can ask the parsing question directly,
## without a Web export to produce a real `window.location.search` to parse.
static func _word_from_query(query: String) -> String:
	var trimmed := query.trim_prefix("?")
	for pair in trimmed.split("&"):
		var parts := pair.split("=")
		if parts.size() == 2 and parts[0] == "controls":
			return parts[1]
	return ""
