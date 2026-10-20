class_name WebDisplay
extends RefCounted
## How the web build's pixel count is chosen. Nothing here runs outside a Web export.
##
## **`?dpr=<x>`** caps the device pixel ratio the page reports, so the canvas — the window times
## the ratio — draws fewer pixels. For testing only: there is no default cap, the value is the
## player's after two phone frame records. Read in the release-safe bundle `?debug=1` opens
## (`RunConfig.live_debug`), from the query the run read at boot. The page's own
## `window.devicePixelRatio` is what is capped, so the frame record and the readout report the
## capped ratio and the drawn size that results.

## The smallest cap taken: below it the canvas is a few pixels wide, and the value is a typo.
const MIN_DPR := 0.25

## Applies the page's `?dpr=` cap. Called once at boot, with the run's configuration.
static func apply(config: RunConfig) -> void:
	var cap := dpr_cap(config)
	if cap > 0.0:
		_cap_the_ratio(cap)

## The page's `?dpr=` cap, or 0.0 for none: not on a page, not asked for, or not asked of this
## page (see the gate above).
static func dpr_cap(config: RunConfig) -> float:
	if not _reads_the_url(config.live_debug, OS.get_name() == "Web"):
		return 0.0
	return _cap_from_query(config.page_query)

## The decision behind the gate, a pure function of its two inputs so a test can drive the table
## (the same shape as `Telemetry._reads_the_url()`).
static func _reads_the_url(flags_open: bool, on_web: bool) -> bool:
	return flags_open and on_web

## `"?dpr=1.5&seed=4"` (the leading `?` optional) to `1.5`; 0.0 for no `dpr` key, a value that is
## not a number, or one below `MIN_DPR`.
static func _cap_from_query(query: String) -> float:
	for pair in query.trim_prefix("?").split("&"):
		var parts := pair.split("=")
		if parts.size() == 2 and parts[0] == "dpr":
			if not parts[1].is_valid_float():
				return 0.0
			var value := parts[1].to_float()
			return value if value >= MIN_DPR else 0.0
	return 0.0

## Makes `window.devicePixelRatio` report the smaller of the browser's own ratio and `cap`, then
## dispatches a resize. The engine re-reads `window.devicePixelRatio` on its per-frame canvas-size
## check, which is what resizes the canvas; the synthetic resize is harmless, not the reason it works.
static func _cap_the_ratio(cap: float) -> void:
	JavaScriptBridge.eval("""(function (cap) {
		var own = Object.getOwnPropertyDescriptor(window, 'devicePixelRatio');
		var real = own && own.get ? own.get.bind(window) : (function (v) { return function () { return v }; })(window.devicePixelRatio);
		Object.defineProperty(window, 'devicePixelRatio', {configurable: true, get: function () { return Math.min(real(), cap) }});
		window.dispatchEvent(new Event('resize'));
	})(%s)""" % String.num(cap, 3))
