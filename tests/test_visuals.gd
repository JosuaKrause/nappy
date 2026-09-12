extends RefCounted
## Focused contracts for default PNG style transfer textures and explicit SVG fallback.

const MOTHER: Texture2D = preload("res://assets/rig/mother_side_a.svg")
## An SVG with no PNG transfer under `assets/illustrated/svg-transfer/`, for the fallback check:
## bollard remains outside the registered transfer catalogue.
const UNTRANSFERRED: Texture2D = preload("res://assets/props/bollard.svg")
const TRANSFER_ROOT := "res://assets/illustrated/svg-transfer"
const SOURCES: Array[Texture2D] = [
	preload("res://assets/rig/mother_front_a.svg"), preload("res://assets/rig/mother_front_b.svg"),
	preload("res://assets/rig/mother_back_a.svg"), preload("res://assets/rig/mother_back_b.svg"),
	preload("res://assets/rig/mother_side_a.svg"), preload("res://assets/rig/mother_side_b.svg"),
	preload("res://assets/rig/pram_front.svg"), preload("res://assets/rig/pram_back.svg"),
	preload("res://assets/rig/pram_side.svg")]

func run(t) -> void:
	TextureResolver.reset_for_tests(true)
	t.check(TextureResolver.resolve(MOTHER) == MOTHER, "explicit SVG mode keeps the authored SVG")
	t.check(TextureResolver.transfer_path_for(MOTHER) ==
		"res://assets/illustrated/svg-transfer/rig/mother_side_a.png",
		"transfers preserve the source path below the assets root")
	TextureResolver.reset_for_tests(false)
	var resolved: Texture2D = TextureResolver.resolve(MOTHER)
	t.check(resolved != MOTHER and resolved.get_size() == MOTHER.get_size(),
		"default mode loads the same-sized PNG transfer")
	t.check(TextureResolver.resolve(null) == null,
		"a missing source texture remains missing without constructing a transfer")
	for source: Texture2D in SOURCES:
		var transfer: Texture2D = TextureResolver.resolve(source)
		t.check(transfer != source and transfer.get_size() == source.get_size(),
			"each supplied transfer replaces its SVG at native dimensions")
		var source_image := source.get_image()
		var transfer_image := transfer.get_image()
		var alpha_matches := true
		for y in source_image.get_height():
			for x in source_image.get_width():
				if not is_equal_approx(source_image.get_pixel(x, y).a,
						transfer_image.get_pixel(x, y).a):
					alpha_matches = false
		t.check(alpha_matches, "transfer retains the SVG alpha mask")
	t.check(TextureResolver.resolve(UNTRANSFERRED) == UNTRANSFERRED,
		"a missing PNG transfer falls back to the authored SVG")
	t.check(TextureResolver.resolve(resolved) == resolved,
		"a resolved PNG is idempotent and does not construct a second transfer path")
	t.check(TextureResolver.resolve(MOTHER) == resolved,
		"resolved textures are cached rather than loaded repeatedly")
	_test_every_transfer_has_a_native_svg_pair(t)
	TextureResolver.reset_for_tests(DevFlags.svg_requested())

func _test_every_transfer_has_a_native_svg_pair(t) -> void:
	var transfer_paths: PackedStringArray = _transfer_paths(TRANSFER_ROOT)
	t.check(not transfer_paths.is_empty(), "the transfer audit discovers runtime PNG assets")
	for transfer_path: String in transfer_paths:
		var relative_path: String = transfer_path.trim_prefix(TRANSFER_ROOT + "/")
		var source_path: String = "res://assets/" + relative_path.trim_suffix(".png") + ".svg"
		var source: Texture2D = load(source_path) as Texture2D
		var transfer: Texture2D = load(transfer_path) as Texture2D
		t.check(source != null and transfer != null,
			"runtime PNG has a loadable SVG pair: %s" % relative_path)
		if source != null and transfer != null:
			var dimensions_match := transfer.get_size() == source.get_size()
			t.check(dimensions_match,
				"runtime PNG keeps native dimensions: %s" % relative_path)
			t.check(transfer.get_width() > 0 and transfer.get_height() > 0,
				"runtime PNG has nonempty dimensions: %s" % relative_path)
			if dimensions_match:
				var source_image := source.get_image()
				var transfer_image := transfer.get_image()
				var alpha_matches := true
				for y in source_image.get_height():
					for x in source_image.get_width():
						if not is_equal_approx(source_image.get_pixel(x, y).a,
								transfer_image.get_pixel(x, y).a):
							alpha_matches = false
				t.check(alpha_matches, "runtime PNG retains SVG alpha: %s" % relative_path)

func _transfer_paths(directory_path: String) -> PackedStringArray:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return PackedStringArray()
	directory.list_dir_begin()
	var paths := PackedStringArray()
	var filename: String = directory.get_next()
	while not filename.is_empty():
		var path: String = directory_path.path_join(filename)
		if directory.current_is_dir():
			paths.append_array(_transfer_paths(path))
		elif filename.ends_with(".png"):
			paths.append(path)
		filename = directory.get_next()
	directory.list_dir_end()
	paths.sort()
	return paths
