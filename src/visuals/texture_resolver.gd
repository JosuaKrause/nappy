class_name TextureResolver
extends RefCounted
## Selects a same-sized PNG transfer for an authored SVG texture, unless SVG is forced.

const TRANSFER_ROOT := "res://assets/illustrated/svg-transfer/"

static var _svg_requested := false
static var _initialized := false
static var _cache: Dictionary = {}

## How many transfer PNGs `resolve()` has actually loaded from disk this run — every `load()`
## below adds one, whether it ran inside `resolve()` itself or inside `warm()`, since `warm()`
## calls `resolve()` rather than duplicating its load. Read by `TelemetryObserver._spike_context`
## so a late load under `--spikes` names itself; reset only by `reset_for_tests`, never by the
## day turning over, since a picture loaded on day 3 does not load again on day 4.
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
		var started := Time.get_ticks_usec()
		var candidate := load(transfer_path) as Texture2D
		_load_count += 1
		# Where the load actually happens, which is the only place that can time it. A picture
		# read here rather than during `warm()` is one that arrived late, and the clock on the
		# line is what says which of the two it was.
		Telemetry.note("texture", "transfer %s read from disk in %.1f ms"
				% [transfer_path, (Time.get_ticks_usec() - started) / 1000.0])
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

## Loads every transfer PNG under `TRANSFER_ROOT` and caches it against its source SVG's path,
## exactly as `resolve()` would once that source is actually drawn — so nothing left for
## `resolve()` to load once the day starts, which is the whole of what "warm" means here. Returns
## how many it loaded; does nothing and returns 0 under `--svg`, since no picture is ever swapped
## for one and a cache full of PNGs nobody will ask for would only cost memory.
##
## **Enumerates the transfer root rather than trusting a manifest that does not cover it.**
## `GroundLayers._load_manifest()` lists the ground's own shared bases and overlay components,
## not every transfer — `assets/props/`, `assets/rig/` and every event picture have no entry in
## it at all — so a manifest-first read here would warm the ground and leave everything else for
## `resolve()` to find late. `DirAccess` over the whole tree is the one list that is actually
## complete.
##
## **Idempotent.** A second call finds every source already in `_cache` (`resolve()`'s own
## early return) and loads nothing further; the delta in `load_count()` across the call is what
## is returned, so calling this twice in a row returns the count and then 0.
static func warm() -> int:
	if not _initialized:
		_svg_requested = DevFlags.svg_requested()
		_initialized = true
	if _svg_requested:
		return 0
	var before := _load_count
	for transfer_path in _all_transfer_paths():
		var source_path := _source_path_for(transfer_path)
		if source_path.is_empty() or _cache.has(source_path):
			continue
		var source_texture := load(source_path) as Texture2D
		if source_texture == null:
			push_warning("Ignoring illustrated transfer with no source SVG: %s (expected %s)" % [
				transfer_path, source_path])
			continue
		resolve(source_texture)
	return _load_count - before

## The inverse of `transfer_path_for`: the authored SVG a transfer PNG stands in for. Returns ""
## for a path outside `TRANSFER_ROOT` or not ending `.png`, the same refusal shape as the forward
## direction.
static func _source_path_for(transfer_path: String) -> String:
	if not transfer_path.begins_with(TRANSFER_ROOT) or not transfer_path.ends_with(".png"):
		return ""
	return "res://assets/" + transfer_path.trim_prefix(TRANSFER_ROOT).trim_suffix(".png") + ".svg"

## Every transfer PNG under `TRANSFER_ROOT`, one entry each even where the directory lists both
## `name.png` and `name.png.import` — see `_collect_transfer_paths` for why both appear at all.
static func _all_transfer_paths() -> Array[String]:
	var result: Array[String] = []
	_collect_transfer_paths(TRANSFER_ROOT, result)
	return result

## **A `.png.import` sidecar is the only listing an exported pack keeps.** Confirmed by exporting
## this project's own "Web" preset to a `.pck` and walking it with `DirAccess` from a second,
## `--main-pack`-only process: `res://assets/illustrated/svg-transfer/props/bollard.png` itself
## does not appear in the pack's directory listing at all, only
## `.../bollard.png.import` — the source file is folded into the exported resource and
## addressed by its original path on `load()`, which is why `resolve()`'s own `load(transfer_path)`
## already works in the shipped web build, but a directory *listing* of that pack never shows the
## bare `.png` name. An editor checkout lists both names for the same file, so both are trimmed to
## the same candidate and de-duplicated per directory rather than assumed to be the export's shape
## alone.
static func _collect_transfer_paths(dir_path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var seen: Dictionary = {}
	var entry_name := dir.get_next()
	while not entry_name.is_empty():
		if entry_name == "." or entry_name == "..":
			entry_name = dir.get_next()
			continue
		var full_path := dir_path.path_join(entry_name)
		if dir.current_is_dir():
			_collect_transfer_paths(full_path + "/", result)
		else:
			var png_name := entry_name.trim_suffix(".import")
			if png_name.ends_with(".png") and not seen.has(png_name):
				seen[png_name] = true
				result.append(dir_path.path_join(png_name))
		entry_name = dir.get_next()
	dir.list_dir_end()

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
