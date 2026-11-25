extends SceneTree
## Renders the thought-bubble sources, and the figures the review sheet stands them over, through
## the engine's own SVG parser, at the scales the sheet reads (1, 2, 4 and 8).

const SOURCES: Array[String] = [
	"art/ui/thought_bubble.svg",
	"art/ui/hint_arrow.svg",
	"art/ui/hint_park.svg",
	"art/ui/hint_back_to_route.svg",
	"art/ui/hint_crosswalk.svg",
	"art/ui/hint_cross_street.svg",
	"art/ui/hint_turn_back.svg",
	"art/ui/hint_noise.svg",
	"art/ui/hint_chalk.svg",
	"art/ui/hint_hut.svg",
	"art/rig/mother_front_a.svg",
	"art/rig/pram_front.svg",
	"art/props/alert.svg",
]
const SCALES: Array[float] = [1.0, 2.0, 4.0, 8.0]
const USAGE := "Usage: godot --headless --path <any project> --script render-sources.gd -- --checkout CHECKOUT --output-dir FRESH_DIRECTORY"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(USAGE)
		quit()
		return
	if args.size() != 4 or args[0] != "--checkout" or args[2] != "--output-dir":
		push_error(USAGE)
		quit(2)
		return
	var checkout: String = args[1]
	var output: String = args[3]
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		push_error("Output must be fresh: " + output)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	for source: String in SOURCES:
		var path: String = checkout.path_join(source)
		for scale: float in SCALES:
			var raster := Image.new()
			var error: Error = raster.load_svg_from_string(FileAccess.get_file_as_string(path), scale)
			var name: String = "%s@%dx.png" % [source.get_file().get_basename(), int(scale)]
			if error != OK or raster.save_png(output.path_join(name)) != OK:
				push_error("SVG render failed: " + path)
				quit(1)
				return
	quit()
