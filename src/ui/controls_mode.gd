class_name ControlsMode
extends RefCounted
## Which of the two ways to say where she goes is driving this run: the on-screen stick (and the
## keyboard and RUN button it mirrors) or a tap that walks her there in a straight line.
##
## Exactly one is active, read once the way `TouchInput.available()` already is, because
## `TouchControls` and `TapControls` are two different nodes rather than two branches of one --
## only one of them ever belongs in the tree at a time. See `main._add_touch_controls()`.
##
## Resolved in this order: the local command line first (`--controls tap|stick`), then the page's
## own URL (`?controls=tap`), then the stick, which is every build's own behaviour with neither
## asked. Both routes are gated behind `DevFlags.enabled()` (`OS.is_debug_build()`) — see
## `_url_word()`'s own doc for why the URL is no longer the exception.
##
## The command line wins over the URL because it is the more deliberate of the two — a debug Web
## build carrying both is somebody testing one channel against the other, and the one they typed
## for this run is the one they meant. **A release build carries no modifiers of any kind, and a
## debug build carries every one of them from the start**: the browser used to debug a web build is
## its own debug export (`tools/export-web.sh debug`), and the page a player actually opens is the
## release export `tools/export-web.sh` (no argument) produces — two different builds answering two
## different questions, never the same one asked twice.
enum Mode { STICK, TAP }

static func resolve() -> Mode:
	var word := DevFlags.controls_override()
	if word == "":
		word = _url_word()
	return from_word(word)

## Whether the command line or the URL has already answered the question, which is the one case a
## run started with one must not be asked — *"a flag is how you skip the question"*. `TitleScreen`
## reads this once at `_ready()` to decide whether it shows the two buttons or the single "space/tap
## to begin" hint it always used to.
static func is_forced() -> bool:
	return DevFlags.controls_override() != "" or _url_word() != ""

## The bare mapping from a raw word — `DevFlags.controls_override()`'s or `_url_word()`'s own —
## onto a `Mode`. Pulled out so a test can ask the mapping directly without a real command line or
## a Web export to answer through.
static func from_word(word: String) -> Mode:
	return Mode.TAP if word == "tap" else Mode.STICK

## The page's own `?controls=tap` or `?controls=stick`, read through
## `JavaScriptBridge.eval("window.location.search")` — the one place in the project that asks the
## browser's own address bar anything. "" outside a Web export, where the address bar does not
## exist to ask, "" for a page with no such parameter, and "" in a release build regardless of the
## query string.
##
## **Gated behind `DevFlags.enabled()`, not the exception it once was.** *(2026-09-06, the player:
## "for dev you need it to be controllable from the getgo -- for release there should be no
## modifiers".)* This used to answer on a release Web export on purpose — "a secret url flag for
## now", because the deployed page had no command line to ask through and the question had nowhere
## else to be answered. The title screen now asks the question outright (see `TitleScreen`), so the
## reason to reach a release build from its own address bar is gone, and this reads the same
## `OS.is_debug_build()` gate as `DevFlags.controls_override()` above it.
static func _url_word() -> String:
	if not DevFlags.enabled() or OS.get_name() != "Web":
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
