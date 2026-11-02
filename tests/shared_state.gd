class_name SharedState
extends RefCounted
## What the test runner records before and after each suite, so that a suite which leaves
## shared state changed fails by name instead of failing some other suite later, in an order
## nobody chose (`tests/run_tests.gd` calls `snapshot()` and `diff()`).
##
## Shared state is everything one suite can change and another can see, which is not the
## suite's own objects:
##   - the tree's `paused`, `Engine.time_scale`, `Input.mouse_mode`, and the nodes under the root and
##     under the runner;
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
## The runner resets some of this on purpose before every suite (`_reset_globals`); the check does
## not look past that, so a field the runner resets and a suite changes is named in `EXEMPT` with
## that as its reason, and every other field is the suite's own to give back.

const DEPTH := 3
const MAX_ITEMS := 64
const AUTOLOADS: Array[String] = ["Tuning", "EventBus", "Telemetry", "GameState", "VisitCounter"]

## The only fields whose change is not a leak, each named with the one-line reason. A field is
## exempt by its own name, never its owner: a new field of the same script is checked until it is
## listed here. A key is `<script file name without .gd>.<field>` (or the autoload's name).
##
## Memoised from constant data or files, filled by whichever suite first needs it, and read as the
## same answer ever after:
const EXEMPT: Dictionary[String, String] = {
	"atlas_library._regions": "atlas regions, read from the baked table on first use",
	"atlas_library._pages": "atlas page textures, loaded on first use",
	"atlas_library._mode": "which atlas format the files are in, read on first use",
	"atlas_library._table_loaded": "set once the baked table is read",
	"atlas_library._moments_claimed": "set once the load moments are claimed",
	"atlas_library._window": "the group window the loader is in, a function of what has been loaded",
	"atlas_library._resident": "which groups are loaded, filled on first use",
	"atlas_library._load_moments": "when each group loads, filled on first use",
	"street_network._segments": "the lattice's street segments, built from the fixed lattice size",
	"street_network._by_key": "the same segments by key",
	"street_network._adjacency": "the same segments' adjacency",
	"resistance_steps._all": "the step table, built from constants on first use",
	"reachability_grid._mask_components": "component tables per wall mask, a pure function of the mask",
	"poster_art._torn": "torn poster textures, drawn from fixed seeds on first use",
	"ground_layers._manifest": "the ground manifest, read from its file on first use",
	"ground_layers._manifest_read": "set once the manifest is read",
	"ground_layers._manifest_reads": "counts the reads; read by tests only as a difference",
	"event_catalogue._all": "the catalogue rows, built from code on first use",
	"event_catalogue._hot": "the catalogue's hot-row index, built with it",
	"event_catalogue._building_fire": "a catalogue row, built on first use",
	"event_catalogue._explosion_outside": "a catalogue row, built on first use",
	"event_catalogue._lesson_dog": "a catalogue row, built on first use",
	"event_catalogue._task_guard": "a catalogue row, built on first use",
	"event_catalogue._task_guard_sent": "a catalogue row, built on first use",
	"event_catalogue._out_of_the_car": "catalogue rows, built on first use",
	"seal_planner._candidates": "seal candidates, a pure function of the lattice, built on first use",
	"seal_planner._escape_candidates": "escape candidates, a pure function of the lattice, built on first use",
	"event_scheduler._kept_ground_of": "the siting memo's owner, replaced when the ground changes",
	"event_scheduler._kept_ground_stamp": "the siting memo's stamp, replaced with its ground",
	"event_scheduler._kept_ground_answers": "the siting memo's answers, replaced with its ground",
	"event_scheduler.judgements": "a counter that tests read only as a difference",
	"event_footprints._warning_sizes": "warning sizes, a pure function of the footprint tables",
	"event_footprints._warning_guard": "the memo's guard for those sizes",
	"entity_halo._shared_material": "the shared halo material, created on first use",
	"mover._shared": "movers shared by their flags, a pure function of the flags",
	"drawn_view._frame": "the per-frame view box cache, replaced each frame",
	"drawn_view._viewport_id": "the per-frame view box cache, replaced each frame",
	"drawn_view._box": "the per-frame view box cache, replaced each frame",
	"run_config._at_boot": "the parse of the command line and page query, fixed for the process",
	"Telemetry._config": "handed by a booted main; the runner hands it back with `Telemetry.configure(null)`",
	"VisitCounter._config": "handed by a booted main; the runner hands it back with `VisitCounter.configure(null, ...)`",
	"VisitCounter._run": "handed by a booted main; the runner hands it back with `VisitCounter.configure(null, ...)`",
	"game_save._config": "handed by a booted main; the runner hands it back with `GameSave.configure(null)`",
	"controls_mode._remembered": "the title's answer, set by a booted main; the runner calls `ControlsMode.forget()`",
	"controls_mode._remembered_mode": "the title's answer, set by a booted main; the runner calls `ControlsMode.forget()`",
	"controls_mode._remembered_side": "the title's answer, set by a booted main; the runner calls `ControlsMode.forget()`",
}

## The fields a suite that boots `main` (or drives a run the observers watch) moves on: the
## observers' count of the run so far. A suite that does so declares it with
## `t.gives_back_observers()` as its first line, and the runner puts these back to what they were
## then once the suite is over; any other suite that changes one fails.
const OBSERVER_FIELDS: Dictionary[String, Array] = {
	"Telemetry": ["_run_dir", "_day_attempts", "_attempt", "_burst_serial"],
	"VisitCounter": ["_day", "_open_tasks", "_reported_run_begun"],
	"GameSave": ["_last_operation"],
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
	if owner == "GameSave":
		return GameSave
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
## time scale, the mouse mode, and the names of the nodes under the root and under the runner.
static func _engine(out: Dictionary[String, String], runner: Node) -> void:
	var tree := runner.get_tree()
	out["engine.paused"] = str(tree.paused)
	out["engine.time_scale"] = str(Engine.time_scale)
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
