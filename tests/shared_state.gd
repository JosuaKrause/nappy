class_name SharedState
extends RefCounted
## What the test runner records before and after each suite, so that a suite which leaves
## shared state changed fails by name instead of failing some other suite later, in an order
## nobody chose (`tests/run_tests.gd` calls `snapshot()` and `diff()`).
##
## Shared state is everything one suite can change and another can see, which is not the
## suite's own objects:
##   - the tree's `paused`, `Engine.time_scale`, `Engine.max_physics_steps_per_frame`,
##     `Engine.physics_ticks_per_second`, `Input.mouse_mode`, and the nodes under the root and
##     under the runner;
##   - `InputMap`: each action's deadzone and events, and whether `Input` holds it pressed;
##   - every autoload's script variables, the script variables of each `RefCounted` it holds in
##     one, and every connection on its signals;
##   - every `static var` declared under `src/`, found by reading the sources, so a new one is
##     checked without anybody adding it to a list.
##
## A snapshot is a flat `Dictionary` from a field's name to a string describing its value, so a
## difference reads as "field: before -> after". Objects are described by class and instance id
## (a replaced object is a change; a mutated one is seen through its own fields only when it is
## an autoload or a `RefCounted` an autoload holds, as `<autoload>.<field>.<its field>`), arrays and
## dictionaries by their contents down to `DEPTH` levels.
##
## Every field is the suite's own to give back, except the memoised ones in `EXEMPT`.

const DEPTH := 3
const MAX_ITEMS := 64
const AUTOLOADS: Array[String] = ["Tuning", "EventBus", "Telemetry", "VisitCounter"]

## The only fields whose change is not a leak, each named with the one-line reason. A field is
## exempt by its own name, never its owner: a new field of the same script is checked until it is
## listed here. A key is `<script file name without .gd>.<field>` (or the autoload's name), and
## `<autoload>.<field>.<its field>` for a part an autoload holds.
##
## Memoised from constant data or files, filled by whichever suite first needs it, and read as the
## same answer ever after:
const EXEMPT: Dictionary[String, String] = {
	"atlas_table._baked": "the baked atlas region table, read from its file on first use",
	"resistance_steps._all": "the step table, built from constants on first use",
	"event_catalogue._all": "the catalogue rows, built from code on first use",
	"event_catalogue._hot": "the catalogue's hot-row index, built with it",
	"event_catalogue._building_fire": "a catalogue row, built on first use",
	"event_catalogue._explosion_outside": "a catalogue row, built on first use",
	"event_catalogue._lesson_dog": "a catalogue row, built on first use",
	"event_catalogue._task_guard": "a catalogue row, built on first use",
	"event_catalogue._task_guard_sent": "a catalogue row, built on first use",
	"event_catalogue._out_of_the_car": "catalogue rows, built on first use",
	"event_footprints._warning_sizes": "warning sizes, a pure function of the footprint tables",
	"event_footprints._warning_guard": "the memo's guard for those sizes",
	"entity_halo._shared_material": "the shared halo material, created on first use",
	"mover._shared": "movers shared by their flags, a pure function of the flags",
}

## The fields a suite that boots `main` (or drives a run the observers watch) moves on: the
## configuration `main` hands the observers, and the observers' count of the run so far. A suite
## that does so declares it with `t.gives_back_observers()` as its first line, and the runner puts
## these back to what they were then once the suite is over; any other suite that changes one
## fails.
const OBSERVER_FIELDS: Dictionary[String, Array] = {
	"Telemetry": ["_config", "_run_dir", "_day_attempts", "_attempt"],
	"VisitCounter": ["_config", "_run", "_day", "_open_tasks", "_reported_run_begun"],
}

## The values of `OBSERVER_FIELDS` now, copied.
static func observers() -> Dictionary:
	var held := {}
	for owner: String in OBSERVER_FIELDS:
		for field: String in OBSERVER_FIELDS[owner]:
			var value: Variant = _observer_get(owner, field)
			held["%s.%s" % [owner, field]] = value.duplicate(true) if value is Dictionary or value is Array else value
	return held

## Puts the fields of `held` (from `observers()`) back.
static func put_back_observers(held: Dictionary) -> void:
	for key: String in held:
		var value: Variant = held[key]
		_observer_set(key.get_slice(".", 0), key.get_slice(".", 1),
				value.duplicate(true) if value is Dictionary or value is Array else value)

static func _observer_target(owner: String) -> Object:
	return Engine.get_main_loop().root.get_node(owner)

static func _observer_get(owner: String, field: String) -> Variant:
	return _observer_target(owner).get(field)

static func _observer_set(owner: String, field: String, value: Variant) -> void:
	_observer_target(owner).set(field, value)

static var _static_fields: Array[Array] = []
static var _static_scanned := false

## The snapshot of the shared state as it is now.
static func snapshot(runner: Node) -> Dictionary[String, String]:
	var out: Dictionary[String, String] = {}
	_engine(out, runner)
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
		if EXEMPT.has(key):
			continue
		lines.append("%s: %s -> %s" % [key, _clip(was), _clip(now)])
	return lines

static func _clip(text: String) -> String:
	return text if text.length() <= 160 else text.substr(0, 157) + "..."

## The engine's own globals and the nodes a suite left standing: whether the tree is paused, the
## time scale, how many physics ticks one frame may run, the mouse mode, and the names of the nodes
## under the root and under the runner.
static func _engine(out: Dictionary[String, String], runner: Node) -> void:
	var tree := runner.get_tree()
	out["engine.paused"] = str(tree.paused)
	out["engine.time_scale"] = str(Engine.time_scale)
	out["engine.max_physics_steps_per_frame"] = str(Engine.max_physics_steps_per_frame)
	out["engine.physics_ticks_per_second"] = str(Engine.physics_ticks_per_second)
	out["engine.mouse_mode"] = str(Input.mouse_mode)
	var under_root: Array[String] = []
	for child in tree.root.get_children():
		under_root.append(str(child.name))
	under_root.sort()
	out["nodes.root"] = str(under_root)
	var under_runner: Array[String] = []
	for child in runner.get_children():
		under_runner.append("%s:%s" % [child.name, child.get_class()])
	under_runner.sort()
	out["nodes.runner"] = str(under_runner)

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
		var value: Variant = node.get(name)
		out["%s.%s" % [autoload, name]] = _describe(value, DEPTH)
		_held(out, "%s.%s" % [autoload, name], value)
	for info in node.get_signal_list():
		var signal_name: String = info["name"]
		var targets: Array[String] = []
		for connection in node.get_signal_connection_list(signal_name):
			var callable: Callable = connection["callable"]
			# A connection made to a script rather than to an object is a static handler that a
			# guarded `is_connected` check connects once for the process.
			if callable.get_object() is GDScript:
				continue
			targets.append("%s.%s" % [_describe(callable.get_object(), 0), callable.get_method()])
		targets.sort()
		out["%s.signal.%s" % [autoload, signal_name]] = str(targets)

## The script variables of a `RefCounted` an autoload holds in `value`, each under `key` and its own
## name, so a part an autoload keeps its state in (a queue, a counter) is compared as the
## autoload's own fields are. One level deep: what such a part holds in turn is described by class
## and instance id, as any other object is. A `Node` an autoload holds is not followed, since it is
## not the autoload's to give back.
static func _held(out: Dictionary[String, String], key: String, value: Variant) -> void:
	if not (value is RefCounted) or not is_instance_valid(value):
		return
	var part: RefCounted = value
	if part.get_script() == null:
		return
	for property in part.get_property_list():
		if not (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var name: String = property["name"]
		out["%s.%s" % [key, name]] = _describe(part.get(name), DEPTH)

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
