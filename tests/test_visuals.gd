extends RefCounted
## Focused contracts for default PNG style transfer textures and explicit SVG fallback.

const MOTHER: Texture2D = preload("res://assets/rig/mother_side_a.svg")
## An SVG with no PNG transfer under `assets/illustrated/svg-transfer/`, for the fallback check:
## bollard remains outside the registered transfer catalogue.
const UNTRANSFERRED: Texture2D = preload("res://assets/props/bollard.svg")
const TRANSFER_ROOT := "res://assets/illustrated/svg-transfer"
const ANCHOR_TOLERANCE := 1.5
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
				var transfer_image := transfer.get_image()
				if relative_path.begins_with("rig/"):
					_check_redrawn_rig_alpha(t, transfer_image, relative_path)
				elif relative_path.begins_with("props/"):
					_check_redrawn_prop_alpha(t, transfer_image, relative_path)
				elif relative_path.begins_with("tiles/"):
					_check_opaque_ground_tile(t, transfer_image, relative_path)
				else:
					_check_redrawn_alpha(t, transfer_image, relative_path)

func _check_redrawn_rig_alpha(t, image: Image, relative_path: String) -> void:
	var bounds := _check_redrawn_alpha(t, image, relative_path)
	if not bounds.has_area():
		return
	_check_bottom_center_anchor(t, image, bounds, relative_path)
	var has_clear_gap := false
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			if image.get_pixel(x, y).a <= 0.01:
				has_clear_gap = true
	t.check(has_clear_gap,
		"redrawn rig PNG keeps real transparency within its artwork bounds: %s" % relative_path)

func _check_redrawn_prop_alpha(t, image: Image, relative_path: String) -> void:
	var bounds := _check_redrawn_alpha(t, image, relative_path)
	if not bounds.has_area():
		return
	if relative_path.get_file().begins_with("garbage_"):
		_check_bottom_center_anchor(t, image, bounds, relative_path)
	else:
		var visible_center := Vector2(bounds.position) + Vector2(bounds.size) / 2.0
		var canvas_center := Vector2(image.get_size()) / 2.0
		t.check(visible_center.distance_to(canvas_center) <= ANCHOR_TOLERANCE,
			"redrawn litter PNG stays centered on its ground-decal anchor: %s" % relative_path)

func _check_redrawn_alpha(t, image: Image, relative_path: String) -> Rect2i:
	var bounds := _visible_bounds(image)
	t.check(bounds.has_area(), "redrawn PNG contains visible artwork: %s" % relative_path)
	var has_opaque := false
	var has_clear := false
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			has_opaque = has_opaque or alpha >= 0.95
			has_clear = has_clear or alpha <= 0.01
	t.check(has_opaque and has_clear,
		"redrawn PNG contains opaque art and genuine transparency: %s" % relative_path)
	return bounds

func _check_opaque_ground_tile(t, image: Image, relative_path: String) -> void:
	var is_opaque := true
	for y in image.get_height():
		for x in image.get_width():
			is_opaque = is_opaque and image.get_pixel(x, y).a >= 0.99
	t.check(is_opaque, "ground tile covers its full opaque canvas: %s" % relative_path)

func _check_bottom_center_anchor(
		t, image: Image, bounds: Rect2i, relative_path: String) -> void:
	t.check(bounds.end.y == image.get_height(),
		"redrawn PNG keeps its canvas-bottom ground anchor: %s" % relative_path)
	var visible_center := float(bounds.position.x) + float(bounds.size.x) / 2.0
	t.check(absf(visible_center - float(image.get_width()) / 2.0) <= ANCHOR_TOLERANCE,
		"redrawn PNG stays centered on its ground anchor: %s" % relative_path)

func _visible_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.01:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

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
