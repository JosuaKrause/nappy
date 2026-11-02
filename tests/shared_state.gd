class_name SharedState
extends RefCounted
## What the test runner records before and after each suite, so that a suite which leaves
## shared state changed fails by name instead of failing some other suite later, in an order
## nobody chose (`tests/run_tests.gd` calls `snapshot()` and `diff()`).
##
## Shared state is everything one suite can change and another can see, which is not the
## suite's own objects:
##   - `InputMap`: each action's deadzone and events, and whether `Input` holds it pressed;
##   - every autoload's script variables, and every connection on its signals;
##   - every `static var` declared under `src/`, found by reading the sources, so a new one is
##     checked without anybody adding it to a list.
##
## A snapshot is a flat `Dictionary` from a field's name to a string describing its value, so a
## difference reads as "field: before -> after". Objects are described by class and instance id
## (a replaced object is a change; a mutated one is seen through its own fields only when it is
## an autoload), arrays and dictionaries by their contents down to `DEPTH` levels.
##
## **`RESET_BY_RUNNER` is not an allow-list of leaks.** It names what `_reset_globals` puts back
## before every suite on purpose, because a suite is meant to start runs and write saves; a
## field there is compared by the runner anyway only through the reset, so a suite cannot hide
## behind it. Anything else a suite changes is its own to give back.

const DEPTH := 3
const MAX_ITEMS := 64
const AUTOLOADS: Array[String] = ["Tuning", "EventBus", "Telemetry", "GameState", "VisitCounter"]

## Fields whose change is expected, each with the reason, which the runner resets before the next
## suite (`_reset_globals`) or which no suite can observe. A key is `Owner.field`, an autoload's
## name or a script's file name without `.gd`.
const EXPECTED: Dictionary[String, String] = {}

## Scripts whose static fields are memoised from constant data or from the files on disk, each
## filled on first use and never read as anything but the same answer: a suite that is the first
## to need one fills it, and the fill is not a leak. A field of one of these changes without
## failing the suite; the reason is why that is safe, and a cache that held anything a suite sets
## would not belong here.
const MEMOS: Dictionary[String, String] = {
	"atlas_library": "texture atlas pages and regions, read from the baked files on first use",
	"street_network": "the lattice's street segments, built from the fixed lattice size",
	"resistance_steps": "the step table, built from constants",
	"reachability_grid": "component tables for each wall mask, a pure function of the mask",
	"poster_art": "torn poster textures, drawn from fixed seeds",
	"ground_layers": "the ground manifest, read from its file",
	"event_catalogue": "the catalogue rows, built from code on first use",
	"seal_planner": "candidate tables, a pure function of the lattice",
	"event_scheduler": "the siting memo keyed by the ground it answered for, and the judgement counter, which tests read only as a difference",
	"event_footprints": "warning sizes, a pure function of the footprint tables",
	"entity_halo": "the shared halo material",
	"mover": "movers shared by their flags, a pure function of the flags",
	"drawn_view": "the per-frame view box, replaced when the frame or viewport changes",
	"city_map": "tile lookup tables, a pure function of the tile kinds",
	"run_config": "the parse of the command line and page query, which does not change in a process",
}

## What booting `main` hands on, by owner: the observers of a run take the run configuration and
## log the run they are given, and the title's controls answer is remembered for the sitting. A
## suite that boots `main` changes every one of them, which is the point of booting it. The runner
## puts them back before the next suite (`_reset_globals`), so they are named here as handed on by
## design, not as leaks, and the reset is what keeps the next suite from meeting them.
const BOOTED_MAIN: Dictionary[String, String] = {
	"Telemetry": "takes the run configuration and opens the run's log folder",
	"VisitCounter": "takes the run configuration and counts the run's days and open tasks",
	"game_save": "takes the run configuration",
	"controls_mode": "remembers the title's controls answer for the sitting",
}

static var _static_fields: Array[Array] = []
static var _static_scanned := false

## The snapshot of the shared state as it is now.
static func snapshot() -> Dictionary[String, String]:
	var out: Dictionary[String, String] = {}
	_input(out)
	for autoload in AUTOLOADS:
		_autoload(out, autoload)
	_statics(out)
	return out

## The lines naming each field that differs between two snapshots.
static func diff(before: Dictionary[String, String], after: Dictionary[String, String]) -> Array[String]:
	var lines: Array[String] = []
	var keys := {}
	for key in before:
		keys[key] = true
	for key in after:
		keys[key] = true
	var names: Array = keys.keys()
	names.sort()
	for key: String in names:
		var was: String = before.get(key, "<absent>")
		var now: String = after.get(key, "<absent>")
		if was == now:
			continue
		if EXPECTED.has(key) or MEMOS.has(key.get_slice(".", 0)) or BOOTED_MAIN.has(key.get_slice(".", 0)):
			continue
		lines.append("%s: %s -> %s" % [key, _clip(was), _clip(now)])
	return lines

static func _clip(text: String) -> String:
	return text if text.length() <= 160 else text.substr(0, 157) + "..."

static func _input(out: Dictionary[String, String]) -> void:
	for action in InputMap.get_actions():
		var events: Array[String] = []
		for event in InputMap.action_get_events(action):
			events.append(event.as_text() + (" [%s]" % event.get_class()))
		out["InputMap.%s" % action] = "deadzone=%s events=%s" % [InputMap.action_get_deadzone(action), events]
		out["Input.pressed.%s" % action] = str(Input.is_action_pressed(action))

static func _autoload(out: Dictionary[String, String], autoload: String) -> void:
	var node: Node = Engine.get_main_loop().root.get_node_or_null(autoload)
	if node == null:
		return
	for property in node.get_property_list():
		if not (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var name: String = property["name"]
		out["%s.%s" % [autoload, name]] = _describe(node.get(name), DEPTH)
	for info in node.get_signal_list():
		var signal_name: String = info["name"]
		var targets: Array[String] = []
		for connection in node.get_signal_connection_list(signal_name):
			var callable: Callable = connection["callable"]
			# A connection made to a script rather than to an object is a static handler that a
			# guarded `is_connected` check connects once for the process (`GameSave`'s).
			if callable.get_object() is GDScript:
				continue
			targets.append("%s.%s" % [_describe(callable.get_object(), 0), callable.get_method()])
		targets.sort()
		out["%s.signal.%s" % [autoload, signal_name]] = str(targets)

static func _statics(out: Dictionary[String, String]) -> void:
	if not _static_scanned:
		_static_scanned = true
		_scan("res://src")
	for entry in _static_fields:
		var script: GDScript = load(entry[0])
		var name: String = entry[1]
		out["%s.%s" % [(entry[0] as String).get_file().get_basename(), name]] = _describe(script.get(name), DEPTH)

## Every `static var` under `src/`, read from the sources: the script path and field name.
static func _scan(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	var subdirs: Array[String] = []
	var files: Array[String] = []
	for sub in dir.get_directories():
		subdirs.append(sub)
	for file in dir.get_files():
		if file.ends_with(".gd"):
			files.append(file)
	subdirs.sort()
	files.sort()
	for sub in subdirs:
		_scan(dir_path + "/" + sub)
	var pattern := RegEx.create_from_string("(?m)^static var (\\w+)")
	for file in files:
		var path := dir_path + "/" + file
		var source := FileAccess.get_file_as_string(path)
		for found in pattern.search_all(source):
			_static_fields.append([path, found.get_string(1)])

static func _describe(value: Variant, depth: int) -> String:
	if value is Object:
		if not is_instance_valid(value):
			return "<freed>"
		var object: Object = value
		var script: Script = object.get_script()
		return "<%s#%d>" % [script.resource_path.get_file().get_basename() if script != null else object.get_class(), object.get_instance_id()]
	if value is Array or value is Dictionary:
		if depth <= 0:
			return "<%s of %d>" % [type_string(typeof(value)), value.size()]
		var parts: Array[String] = []
		if value is Array:
			for item in value:
				parts.append(_describe(item, depth - 1))
				if parts.size() >= MAX_ITEMS:
					parts.append("...")
					break
			return "[%d: %s]" % [value.size(), ", ".join(parts)]
		var keys: Array = value.keys()
		for key in keys:
			parts.append("%s=%s" % [_describe(key, 0), _describe(value[key], depth - 1)])
			if parts.size() >= MAX_ITEMS:
				parts.append("...")
				break
		return "{%d: %s}" % [value.size(), ", ".join(parts)]
	return var_to_str(value)
