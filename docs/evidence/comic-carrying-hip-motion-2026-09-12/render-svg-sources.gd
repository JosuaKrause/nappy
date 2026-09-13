extends SceneTree
## Renders F's frozen carrying SVG sources with Godot's own SVG parser.

const VIEWS: Array[String] = ["front", "back", "side", "front_diagonal", "back_diagonal"]
const FRAMES: Array[String] = ["a", "c", "b"]
const INPUT := "res://docs/evidence/comic-carrying-hip-motion-2026-09-12/source/svg"
const USAGE := "Usage: render-svg-sources.gd -- --output-dir NEW_DIRECTORY\nExample: --output-dir /tmp/f-source-renders"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(USAGE)
		quit()
		return
	if args.size() != 2 or args[0] != "--output-dir" or args[1].begins_with("-"):
		printerr(USAGE)
		quit(2)
		return
	var output := ProjectSettings.globalize_path(args[1])
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		printerr("Refusing existing output: " + output)
		quit(2)
		return
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output)
	if mkdir_error != OK:
		printerr("Cannot create output: " + output)
		quit(2)
		return
	for view in VIEWS:
		for frame in FRAMES:
			var filename := "mother_carrying_%s_%s.svg" % [view, frame]
			var source := "%s/%s" % [INPUT, filename]
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
	print("render-svg-sources: rendered 15 frozen A/C/B sources at native and 6x")
	quit()
