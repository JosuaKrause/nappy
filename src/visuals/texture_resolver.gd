class_name TextureResolver
extends RefCounted
## Selects a same-sized PNG transfer for an authored SVG texture, unless SVG is forced.

const TRANSFER_ROOT := "res://assets/illustrated/svg-transfer/"

static var _svg_requested := false
static var _initialized := false
static var _cache: Dictionary = {}

## How many transfer PNGs `resolve()` has actually loaded from disk this run — every `load()`
## below adds one. Read by `TelemetryObserver._spike_context` so a late load under `--spikes`
## names itself; reset only by `reset_for_tests`, never by the day turning over, since a picture
## loaded on day 3 does not load again on day 4.
static var _load_count := 0

## Returns a cached PNG transfer by default when the replacement is valid.
## Missing or mismatched transfers preserve the original SVG so an incomplete art drop cannot
## change the simulation's presentation geometry.
static func resolve(texture: Texture2D) -> Texture2D:
	if not _initialized:
		_svg_requested = DevFlags.svg_requested()
		_initialized = true
	if _svg_requested or texture == null:
		return texture
	var source_path := texture.resource_path
	if source_path.is_empty() or not source_path.begins_with("res://assets/") \
			or not source_path.ends_with(".svg"):
		return texture
	if _cache.has(source_path):
		return _cache[source_path]
	var transfer_path := TRANSFER_ROOT + source_path.trim_prefix("res://assets/").trim_suffix(".svg") + ".png"
	var replacement: Texture2D = texture
	if ResourceLoader.exists(transfer_path):
		var candidate := load(transfer_path) as Texture2D
		_load_count += 1
		if candidate != null and candidate.get_size() == texture.get_size():
			replacement = candidate
		elif candidate != null:
			push_warning("Ignoring illustrated transfer with wrong size: %s (expected %s, got %s)" % [
				transfer_path, texture.get_size(), candidate.get_size()])
	_cache[source_path] = replacement
	return replacement

## How many transfer PNGs have been loaded from disk this run. A static counter rather than a
## per-frame hook on a gameplay class, per the **telemetry** rule — `TelemetryObserver` reads it,
## it does not compute it.
static func load_count() -> int:
	return _load_count

## Reports the resolved presentation mode so composite callers can keep an authored SVG intact.
static func svg_requested() -> bool:
	if not _initialized:
		_svg_requested = DevFlags.svg_requested()
		_initialized = true
	return _svg_requested

static func transfer_path_for(texture: Texture2D) -> String:
	if texture == null or not texture.resource_path.begins_with("res://assets/") \
			or not texture.resource_path.ends_with(".svg"):
		return ""
	return TRANSFER_ROOT + texture.resource_path.trim_prefix("res://assets/").trim_suffix(".svg") + ".png"

static func reset_for_tests(requested: bool) -> void:
	_svg_requested = requested
	_initialized = true
	_cache.clear()
	_load_count = 0
