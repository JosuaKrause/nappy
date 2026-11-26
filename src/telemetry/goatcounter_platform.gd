class_name GoatCounterPlatform
extends RefCounted
## What the page counter asks the machine it runs on: whether this is the web, whether it is a
## debug build, which version the build is, and whether the page has a callable
## `window.goatcounter.count`. The counter is
## handed the answers (`VisitCounter.send_through()`) instead of asking the engine itself, so a
## suite hands the answers a released web page gives and drives the counter's real gate and send
## path on a desktop run. `main` hands `of_the_engine()`, the engine's own answers.

## Whether this runs in a browser, as the engine says.
var _on_web: bool
## Whether this is a debug build, as the engine says.
var _debug_build: bool
## Answers whether `window.goatcounter.count` is callable on the page right now; it answers
## differently a moment later, since `count.js` loads asynchronously.
var _present: Callable
## The build's version, as it was exported (`BuildInfo.exported_version()`).
var _version: String

## A platform that answers `on_web`, `debug_build` and `version` as given and asks `present` (a
## Callable returning a bool) whether the page's counter exists. `version` has no default, since a
## release's shape there would count.
func _init(on_web: bool, debug_build: bool, present: Callable, version: String) -> void:
	_on_web = on_web
	_debug_build = debug_build
	_present = present
	_version = version

## The engine's own answers: the web when the engine's name for the platform is `Web`, a debug
## build when the engine says so, the version the build was exported as
## (`BuildInfo.exported_version()`), and the page asked through `JavaScriptBridge`.
static func of_the_engine() -> GoatCounterPlatform:
	return GoatCounterPlatform.new(OS.get_name() == "Web", OS.is_debug_build(),
			_page_has_the_counter, BuildInfo.exported_version())

## Whether this runs on the web.
func is_on_the_web() -> bool:
	return _on_web

## Whether this is a debug build.
func is_a_debug_build() -> bool:
	return _debug_build

## The build's version, which names a release candidate on a candidate's page.
func build_version() -> String:
	return _version

## Whether the page has a callable `window.goatcounter.count` right now.
func has_the_counter() -> bool:
	return bool(_present.call())

## Whether the page actually has a callable `window.goatcounter.count` — `false` off the web
## without ever asking `JavaScriptBridge`, the same guard `DevFlags.page_query()` makes before its
## own `JavaScriptBridge.eval()`. **`bool(...)`, never `present is bool`**: a JS boolean crosses
## `JavaScriptBridge.eval()` as a GDScript `int` (`1`/`0`), not a `bool` — confirmed against a real
## export, where `present is bool` silently refused every event, gate closed, no error anywhere to
## say why. `bool()` reads true off that `int` the same as it would a native bool.
static func _page_has_the_counter() -> bool:
	if OS.get_name() != "Web":
		return false
	var present: Variant = JavaScriptBridge.eval(
			"(typeof window.goatcounter !== 'undefined' " +
			"&& typeof window.goatcounter.count === 'function')")
	return bool(present)
