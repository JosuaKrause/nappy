extends Node
## Loads every script named in a list file, once, so the engine parses and analyzes each. Run by
## `tools/typing_census.py`, which sets the typing warnings to the warn level and runs this scene
## under the local debugger (`-d`), the one mode that prints a warning with its file and line.
##
##     godot --headless -d --path . res://tools/typing_census.tscn -- <list file>
##
## A scene rather than `--script`, so the autoloads exist for the scripts that name them. The list
## file holds one `res://` path per line. Prints `CENSUS_LOADED <path>` or `CENSUS_FAILED <path>` (the
## script did not load, did not parse or did not compile) after each load, then `CENSUS_DONE <count>`.
## A script that depends on a failed one can still be reported loaded, so `tools/typing_census.py` does
## not trust a run in which a script others name failed.


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("typing_census.gd: expected one argument, the list file")
		get_tree().quit(2)
		return
	var list: FileAccess = FileAccess.open(args[0], FileAccess.READ)
	if list == null:
		printerr("typing_census.gd: cannot open %s" % args[0])
		get_tree().quit(2)
		return
	var paths: PackedStringArray = list.get_as_text().split("\n", false)
	var own: String = (get_script() as Script).resource_path
	for path: String in paths:
		if path == own:
			# Running, so not loaded again (which breaks the run); the engine analyzed it to start the scene.
			print("CENSUS_LOADED %s" % path)
			continue
		var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		var script_resource: Script = script as Script
		if script == null or (script_resource != null and not script_resource.can_instantiate()):
			print("CENSUS_FAILED %s" % path)
		else:
			print("CENSUS_LOADED %s" % path)
	print("CENSUS_DONE %d" % paths.size())
	get_tree().quit()
