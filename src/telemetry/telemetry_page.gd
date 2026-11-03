class_name TelemetryPage
extends RefCounted
## What a deployed page may ask of the run log. `Telemetry` asks these two before it opens a log on
## the web, and a release build answers neither: the published page collecting from a stranger's
## browser because of a query string nobody documented is exactly what a release build carrying
## no modifiers rules out.

## The decision behind whether the page's query is read at all, a pure function of its two inputs
## so the promise is a truth table a test can check rather than a build type nothing can fake:
## debug and web is the one case `?telemetry=1` exists for; release and web — the published page —
## is the case the promise is actually about.
static func reads_the_url(is_debug: bool, on_web: bool) -> bool:
	return is_debug and on_web

## `"?telemetry=1"` (with or without a leading `?`, alongside any other parameter) reads as "log
## this run"; anything else — absent, or any other value — leaves the platform's own default in
## place. Pulled out so a test can ask the parsing question directly, without a Web export to
## produce a real `window.location.search` to parse.
static func asks_for_telemetry(query: String) -> bool:
	var trimmed := query.trim_prefix("?")
	for pair in trimmed.split("&"):
		var parts := pair.split("=")
		if parts.size() == 2 and parts[0] == "telemetry":
			return parts[1] == "1"
	return false
