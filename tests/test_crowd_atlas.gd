extends RefCounted
## `CrowdAtlas`'s own packing contract — the shelf layout and the pixel-for-pixel fidelity of
## packing `CrowdAgent`'s six texture tables into one shared texture — apart from
## `test_crowd_bodies.gd`'s subject (obstruction and placement) and `test_visuals.gd`'s (the
## PNG/SVG transfer contract for the mother's and the props' own families): this suite is neither,
## and both of those files are already sized to their own subject.
##
## Run under both presentation modes, since the atlas packs whichever raster
## `TextureResolver.resolve()` currently chooses, and `CrowdAtlas.reset_for_tests()` is paired with
## every `TextureResolver.reset_for_tests()` call here so the atlas asked about is always the one
## the current mode would actually build.

func run(t) -> void:
	TextureResolver.reset_for_tests(false)
	CrowdAtlas.reset_for_tests()
	_check_pack(t, "default PNG transfers")

	TextureResolver.reset_for_tests(true)
	CrowdAtlas.reset_for_tests()
	_check_pack(t, "forced SVG rasters")

	TextureResolver.reset_for_tests(DevFlags.svg_requested())
	CrowdAtlas.reset_for_tests()

func _sources() -> Dictionary:
	return {
		"walker_body": CrowdAgent.WALKER_BODY_BY_VIEW,
		"walker_trim": CrowdAgent.WALKER_TRIM_BY_VIEW,
		"walker_body_b": CrowdAgent.WALKER_BODY_BY_VIEW_B,
		"walker_trim_b": CrowdAgent.WALKER_TRIM_BY_VIEW_B,
		"car_body": CrowdAgent.CAR_BODY_BY_VIEW,
		"car_trim": CrowdAgent.CAR_TRIM_BY_VIEW,
	}

## Packs the real crowd dictionaries once under the mode `TextureResolver` is already set to, and
## checks every region lies inside the atlas, no two regions overlap, each region's own pixels
## equal its source image's, and the atlas is inside the phone-safe cap.
func _check_pack(t, label: String) -> void:
	var sources := _sources()
	var packed := CrowdAtlas.pack(sources)
	t.check(packed.keys().size() == sources.keys().size(),
			"%s: every source group comes back packed" % label)

	# [group, view, region: Rect2i, source pixels: Image] — the source image converted the same
	# way `CrowdAtlas._build()` converts it, so the pixel comparison below is against exactly what
	# was blitted rather than against a source format that may disagree on channel layout.
	var regions: Array = []
	var atlas_texture: Texture2D
	for group: String in sources.keys():
		var views: Dictionary = sources[group]
		t.check(packed.has(group), "%s: group %s comes back at all" % [label, group])
		var packed_views: Dictionary = packed[group]
		t.check(packed_views.keys().size() == views.keys().size(),
				"%s: group %s keeps every view (%d against %d)"
				% [label, group, packed_views.keys().size(), views.keys().size()])
		for view in views.keys():
			var atlas_tex: Texture2D = packed_views[view]
			t.check(atlas_tex is AtlasTexture,
					"%s: %s/%s is packed as an AtlasTexture" % [label, group, view])
			if atlas_texture == null:
				atlas_texture = (atlas_tex as AtlasTexture).atlas
			t.check((atlas_tex as AtlasTexture).atlas == atlas_texture,
					"%s: %s/%s shares the one atlas texture every other view does"
					% [label, group, view])
			var source_texture: Texture2D = TextureResolver.resolve(views[view])
			t.check(atlas_tex.get_size() == source_texture.get_size(),
					"%s: %s/%s reports its source's own size (%s against %s)"
					% [label, group, view, atlas_tex.get_size(), source_texture.get_size()])
			var source_image: Image = source_texture.get_image().duplicate()
			if source_image.get_format() != Image.FORMAT_RGBA8:
				source_image.convert(Image.FORMAT_RGBA8)
			var region := Rect2i((atlas_tex as AtlasTexture).region)
			regions.append([group, view, region, source_image])

	t.check(atlas_texture != null, "%s: the atlas actually packed something" % label)
	if atlas_texture == null:
		return
	var atlas_size := Vector2i(atlas_texture.get_size())
	t.check(atlas_size.x <= CrowdAtlas.MAX_ATLAS_SIDE and atlas_size.y <= CrowdAtlas.MAX_ATLAS_SIDE,
			"%s: the atlas is inside the %dpx phone-safe side (got %s)"
			% [label, CrowdAtlas.MAX_ATLAS_SIDE, atlas_size])

	var atlas_image := atlas_texture.get_image()
	for entry in regions:
		var group: String = entry[0]
		var view = entry[1]
		var region: Rect2i = entry[2]
		t.check(region.position.x >= 0 and region.position.y >= 0
				and region.end.x <= atlas_size.x and region.end.y <= atlas_size.y,
				"%s: %s/%s's region lies inside the atlas (%s in %s)"
				% [label, group, view, region, atlas_size])
		var source_image: Image = entry[3]
		t.check(region.size == source_image.get_size(),
				"%s: %s/%s's region is exactly its source's own size (%s against %s)"
				% [label, group, view, region.size, source_image.get_size()])
		var mismatched := 0
		for y in region.size.y:
			for x in region.size.x:
				var atlas_pixel := atlas_image.get_pixel(region.position.x + x, region.position.y + y)
				var source_pixel := source_image.get_pixel(x, y)
				if atlas_pixel != source_pixel:
					mismatched += 1
		t.check(mismatched == 0,
				"%s: %s/%s's packed pixels equal its source image's (%d of %d px differ)"
				% [label, group, view, mismatched, region.size.x * region.size.y])

	for i in regions.size():
		var a: Rect2i = regions[i][2]
		for j in range(i + 1, regions.size()):
			var b: Rect2i = regions[j][2]
			t.check(not a.intersects(b),
					"%s: %s/%s and %s/%s do not overlap (%s against %s)"
					% [label, regions[i][0], regions[i][1], regions[j][0], regions[j][1], a, b])
