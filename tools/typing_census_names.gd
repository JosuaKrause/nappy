extends SceneTree
## Prints the name of every GDScript warning the engine has a project setting for, one
## `CENSUS_WARNING <name>` per line. Run by `tools/typing_census.py` with `--script`.


func _init() -> void:
	var prefix: String = "debug/gdscript/warnings/"
	for info: Dictionary in ProjectSettings.get_property_list():
		var setting: String = info["name"]
		if setting.begins_with(prefix) and not setting.ends_with("exclude_addons") \
				and not setting.ends_with("enable") and not setting.ends_with("directory_rules"):
			print("CENSUS_WARNING %s" % setting.trim_prefix(prefix))
	quit()
