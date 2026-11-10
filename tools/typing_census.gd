extends Node
## Loads every script named in a list file, once, so the engine parses and analyzes each. Run by
## `tools/typing_census.py`, which sets the typing warnings to the warn level and runs this scene
## under the local debugger (`-d`), the one mode that prints a warning with its file and line.
##
##     godot --headless -d --path . res://tools/typing_census.tscn -- <list file>
##
## A scene rather than `--script`, so the autoloads exist for the scripts that name them. The list
## file holds one `res://` path per line. Prints `CENSUS_LOADED <path>` or `CENSUS_FAILED <path>` (the
## script did not load, or did not parse) after each load, then `CENSUS_DONE`.


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
	for path: String in paths:
		var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		var script_resource: Script = script as Script
		if script == null or (script_resource != null and not script_resource.can_instantiate()):
			print("CENSUS_FAILED %s" % path)
		else:
			print("CENSUS_LOADED %s" % path)
	print("CENSUS_DONE")
	get_tree().quit()
