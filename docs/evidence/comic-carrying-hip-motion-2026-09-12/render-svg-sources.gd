extends SceneTree
## Renders F's frozen carrying SVG sources with Godot's own SVG parser.

const VIEWS: Array[String] = ["front", "back", "side", "front_diagonal", "back_diagonal"]
const FRAMES: Array[String] = ["a", "c", "b"]
const INPUT := "res://docs/evidence/comic-carrying-hip-motion-2026-09-12/source/svg"
const OUTPUT := "res://docs/evidence/comic-carrying-hip-motion-2026-09-12/source/rendered"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
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
				var destination := "%s/%s_%s-%s.png" % [OUTPUT, view, frame, suffix]
				if image.save_png(destination) != OK:
					push_error("PNG save failed: %s" % destination)
					quit(1)
					return
	print("render-svg-sources: rendered 15 frozen A/C/B sources at native and 6x")
	quit()
