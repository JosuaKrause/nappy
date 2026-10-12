class_name WebDisplay
extends RefCounted
## How the web build puts its frame on the screen. Nothing here runs outside a Web export.
##
## **Direct to screen** (`RenderingServer.viewport_set_render_direct_to_screen()` on the root
## viewport) removes the engine's own full-screen copy from its render target to the canvas, one
## of the two copies the page makes each frame (the other is the browser glue's, which is the
## engine's template and is left alone). The cost is that nothing can read the root viewport's
## texture: `Telemetry`'s snapshot and burst (`P`/`B` under `?telemetry=1`) and `AutoScreenshot`
## read it, and on a page they would read nothing. Native builds keep the texture and every one of
## those paths.
##
## **It is asked for with `?direct=1`, not on by default**, because the desktop Chrome it was
## built against shows a black page with it on (the game runs, nothing reaches the canvas; the
## same page without it draws). A debug build reads the parameter always and a release page once
## its own `?debug=1` has asked (`DevFlags.live_debug_requested()`), the same gate `?controls=`
## has, so a phone can be compared with and without it on the same page.

## Whether the root viewport renders straight to the screen: on a page, and asked for.
static func direct_to_screen_wanted(on_web: bool, asked: bool) -> bool:
	return on_web and asked

## Applies the page's choices to the root viewport. Called once at boot.
static func apply(root: Viewport) -> void:
	var on_web := OS.has_feature("web")
	if direct_to_screen_wanted(on_web, on_web and _direct_asked()):
		RenderingServer.viewport_set_render_direct_to_screen(root.get_viewport_rid(), true)

## Whether the page's query asks for `?direct=1`, behind the gate above.
static func _direct_asked() -> bool:
	if not _reads_the_url(DevFlags.live_debug_requested(), OS.get_name() == "Web"):
		return false
	var search: Variant = JavaScriptBridge.eval("window.location.search")
	if typeof(search) != TYPE_STRING:
		return false
	return _direct_from_query(search)

## The decision behind the gate, a pure function of its two inputs so a test can drive the table
## (the same shape as `ControlsMode._reads_the_url()`).
static func _reads_the_url(flags_open: bool, on_web: bool) -> bool:
	return flags_open and on_web

## `"?direct=1&seed=4"` (the leading `?` optional) to true; anything else to false.
static func _direct_from_query(query: String) -> bool:
	for pair in query.trim_prefix("?").split("&"):
		var parts := pair.split("=")
		if parts.size() == 2 and parts[0] == "direct":
			return parts[1] == "1"
	return false
