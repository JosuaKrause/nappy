extends Node
## Loads every script under `src/`, `tests/` and `tools/` once, so the engine's parser
## reports each one that fails. Run by `tools/field_to_method.py` in a scratch copy, as the
## scene `res://tools/field_to_method_probe.tscn`; prints `PROBE_FAILED <path>` for each script
## that does not load and then `PROBE_DONE <count> <failed>`.


func _ready() -> void:
	var files: Array[String] = []
	for root: String in ["res://src", "res://tests", "res://tools"]:
		_walk(root, files)
	var failed := 0
	for path: String in files:
		var script := load(path) as Script
		if script == null or not script.can_instantiate():
			failed += 1
			print("PROBE_FAILED ", path)
	print("PROBE_DONE ", files.size(), " ", failed)
	get_tree().quit()


func _walk(dir_path: String, files: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		if file_name.ends_with(".gd"):
			files.append(dir_path + "/" + file_name)
	for sub: String in dir.get_directories():
		_walk(dir_path + "/" + sub, files)
