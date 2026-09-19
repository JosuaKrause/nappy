extends SceneTree
## Renders editable male player sources through the engine's SVG parser.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var usage := "Usage: godot --headless --path . --script render-sources.gd -- --output-dir FRESH_DIRECTORY"
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(usage)
		quit()
		return
	if args.size() != 2 or args[0] != "--output-dir":
		push_error(usage)
		quit(2)
		return
	var output := ProjectSettings.globalize_path(args[1])
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		push_error("Output must be fresh: " + output)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	for state in ["", "carrying_"]:
		for view in ["front", "back", "side", "front_diagonal", "back_diagonal"]:
			for pose in ["a", "c", "b"]:
				var name := "father_%s%s_%s" % [state, view, pose]
				var source := "res://assets/rig/%s.svg" % name
				for scale in [1.0, 3.0, 8.0]:
					var raster := Image.new()
					var error := raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale)
					if error != OK or raster.save_png("%s/%s-%dx.png" % [output, name, scale]) != OK:
						push_error("SVG render failed: " + source)
						quit(1)
						return
	quit()
