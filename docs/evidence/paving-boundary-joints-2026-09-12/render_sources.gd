extends SceneTree
## Renders the current paving SVG layout authorities for native and repeated review.

const NAMES := ["sidewalk", "quiet_square", "plaza", "precinct", "courtyard", "alley", "stoop"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print("usage: render_sources.gd -- --output-dir DIRECTORY")
		quit()
		return
	if args.size() != 2 or args[0] != "--output-dir":
		printerr("usage: render_sources.gd -- --output-dir DIRECTORY")
		quit(2)
		return
	var output := args[1]
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		printerr("refusing existing output: %s" % output)
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(2)
		return
	var hashes := {}
	for name in NAMES:
		var path: String = "res://assets/tiles/%s.svg" % name
		var picture := Image.new()
		if picture.load_svg_from_string(FileAccess.get_file_as_string(path)) != OK:
			quit(2)
			return
		hashes[path] = FileAccess.get_sha256(path)
		picture.save_png(output.path_join("%s-native.png" % name))
		var repeated := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		for y in range(4):
			for x in range(4):
				repeated.blit_rect(picture, Rect2i(0, 0, 32, 32), Vector2i(x * 32, y * 32))
		repeated.resize(512, 512, Image.INTERPOLATE_NEAREST)
		repeated.save_png(output.path_join("%s-repeat-4x.png" % name))
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"svg_hashes": hashes,
		"engine": Engine.get_version_info()["string"]}, "\t") + "\n")
	quit()
