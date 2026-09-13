extends SceneTree
## Renders the P1 and P2 pushing SVG sources with Godot's SVG parser for source review.

const VIEWS: Array[String] = ["front", "back", "side", "front_diagonal", "back_diagonal"]
const P1_FRAMES: Array[String] = ["a", "b"]
const P2_FRAMES: Array[String] = ["a", "c", "b"]
const SOURCE_ROOT := "res://docs/evidence/comic-pushing-strides-2026-09-12/source"

func _usage() -> String:
	return "Usage: godot --headless --path . --script %s -- --output-dir FRESH_DIRECTORY" % get_script().resource_path

func _is_help(arguments: PackedStringArray) -> bool:
	return arguments.size() == 1 and arguments[0] in ["--help", "-h"]

func _output_directory() -> String:
	var arguments := OS.get_cmdline_user_args()
	if _is_help(arguments):
		print(_usage())
		return ""
	if arguments.size() != 2 or arguments[0] != "--output-dir":
		push_error("Unknown or incomplete arguments. %s" % _usage())
		return ""
	var output := ProjectSettings.globalize_path(arguments[1])
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		push_error("Choose a fresh output directory: %s" % output)
		return ""
	return output

func _init() -> void:
	var root := _output_directory()
	if root.is_empty():
		quit(0 if _is_help(OS.get_cmdline_user_args()) else 2)
		return
	for version in ["p1", "p2"]:
		var output := "%s/%s" % [root, version]
		DirAccess.make_dir_recursive_absolute(output)
		var frames := P1_FRAMES if version == "p1" else P2_FRAMES
		for view in VIEWS:
			for frame in frames:
				var source := "%s/p1/mother_%s_%s.svg" % [SOURCE_ROOT, view, frame]
				if version == "p2":
					source = "res://assets/rig/mother_%s_%s.svg" % [view, frame]
				for scale in [1.0, 6.0]:
					var image := Image.new()
					var result := image.load_svg_from_string(
							FileAccess.get_file_as_string(source), scale)
					if result != OK:
						push_error("SVG render failed: %s" % source)
						quit(1)
						return
					var suffix := "native" if scale == 1.0 else "6x"
					var destination := "%s/%s_%s-%s.png" % [output, view, frame, suffix]
					if image.save_png(destination) != OK:
						push_error("PNG save failed: %s" % destination)
						quit(1)
						return
	var pram_output := "%s/pram" % root
	DirAccess.make_dir_recursive_absolute(pram_output)
	for view in VIEWS:
		var source := "res://assets/rig/pram_%s.svg" % view
		for scale in [1.0, 6.0]:
			var image := Image.new()
			var result := image.load_svg_from_string(FileAccess.get_file_as_string(source), scale)
			if result != OK:
				push_error("SVG render failed: %s" % source)
				quit(1)
				return
			var suffix := "native" if scale == 1.0 else "6x"
			var destination := "%s/%s-%s.png" % [pram_output, view, suffix]
			if image.save_png(destination) != OK:
				push_error("PNG save failed: %s" % destination)
				quit(1)
				return
	print("render-svg-sources: rendered P1 and P2 pushing sources at native and 6x")
	quit()
