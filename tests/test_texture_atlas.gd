extends RefCounted
## `TextureAtlas`'s own contract — the shelf layout, the pixel-for-pixel fidelity of what it
## packs, and the three answers `texture_for()` gives across a group's life: the source before the
## atlas is collected, the region after it, and the source again once it is released.
##
## The café event family (`EventDef.Look.CAFE`) is the set packed here, because it is a real group
## with a real spread of canvas sizes rather than a fixture invented for the suite, and events are
## the one family still packed by this class through every pull request of M171, build-time
## atlases: `test_crowd_atlas.gd` holds the same contract for the crowd's nested shape, and
## `test_ground_layers.gd` holds the ground's, which is packed a different way.
##
## Run under both presentation modes, since the atlas packs whichever raster
## `TextureResolver.resolve()` currently chooses, and `TextureAtlas.reset_for_tests()` is paired
## with every `TextureResolver.reset_for_tests()` call here so the atlas asked about is always the
## one the current mode would actually build.

const NAME := "test_decoration"

func run(t) -> void:
	_check_plan(t)
	_check_phase_trace(t)

	TextureResolver.reset_for_tests(false)
	TextureAtlas.reset_for_tests()
	_check_pack(t, "default PNG transfers")

	TextureResolver.reset_for_tests(true)
	TextureAtlas.reset_for_tests()
	_check_pack(t, "forced SVG rasters")

	TextureResolver.reset_for_tests(DevFlags.svg_requested())
	TextureAtlas.reset_for_tests()

## Both join paths publish the task's own timing once; disabled recording leaves no payload.
func _check_phase_trace(t) -> void:
	TextureAtlas.reset_for_tests()
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	var source := ImageTexture.create_from_image(image)
	AtlasPhaseTrace.reset(false)
	TextureAtlas.request(NAME, {"picture": source})
	TextureAtlas.collect(NAME, true)
	TextureAtlas.release(NAME)
	t.check(AtlasPhaseTrace.report().spans.is_empty(), "disabled atlas tracing retains no spans")
	AtlasPhaseTrace.reset(true)
	TextureAtlas.request(NAME, {"picture": source})
	TextureAtlas.collect(NAME, true)
	TextureAtlas.collect(NAME, true)
	TextureAtlas.release(NAME)
	var report := AtlasPhaseTrace.report()
	var phases: Array = []
	for row: Array in report.spans:
		phases.append(row[1])
		t.check(row[2] <= row[3], "%s has ordered raw clock endpoints" % row[1])
		if not row[4]:
			t.check(row[5] == -1, "worker work does not borrow the collection frame's ID")
	t.check(phases.count("blit") == 1 and phases.has("source_resolve_readback_copy")
		and phases.has("texture_create_submit") and phases.has("regions_and_cpu_image_release")
		and phases.has("collect_wait") and phases.has("release_wait"),
		"a collected and released atlas exports distinct CPU phases without duplicate blits")
	AtlasPhaseTrace.reset(true)
	TextureAtlas.request(NAME, {"picture": source})
	TextureAtlas.release(NAME)
	var release_phases: Array = []
	for row: Array in AtlasPhaseTrace.report().spans:
		release_phases.append(row[1])
	t.check(release_phases.count("blit") == 1 and release_phases.has("release_wait")
		and not release_phases.has("texture_create_submit"),
		"release before collection retains task timing without inventing GPU collection")
	# A caller-thread execution is how a threadless build runs the same pool callable.
	var pack := TextureAtlas.Pack.new()
	pack.target = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	pack.images.append(image)
	pack.regions.append(Rect2i(0, 0, 8, 8))
	TextureAtlas._blit(pack)
	t.check(pack.blit_on_main_thread and pack.blit_process_frame >= 0,
		"a caller-thread blit is identified from its actual thread, not the platform")
	AtlasPhaseTrace.reset(true)
	for i in AtlasPhaseTrace.CAPACITY + 1:
		AtlasPhaseTrace.record("bounded", "test", i, i + 1)
	var bounded := AtlasPhaseTrace.report()
	t.check(bounded.spans.size() == AtlasPhaseTrace.CAPACITY
		and bounded.dropped_after_capacity == 1 and bounded.spans[0][2] == 0,
		"a full phase buffer preserves its beginning and counts its omitted tail")
	AtlasPhaseTrace.reset(false)
	TextureAtlas.reset_for_tests()

## Key -> source texture, the shape `TextureAtlas.request()` takes. Keyed by the source texture
## itself, which is how every drawing user in the game indexes its own pictures: a `_draw()` has
## the constant in hand and wants the region standing in for it. The café family
## (`EventInstance.family_sources(EventDef.Look.CAFE)`) is a real group with a real spread of
## canvas sizes — both sitter views and the table — rather than a fixture invented for the suite.
func _sources() -> Dictionary:
	return EventInstance.family_sources(EventDef.Look.CAFE)

## The layout on its own, which is the only part of the packing a suite can ask about a set that
## cannot fit: `request()` asserts on `fits`, and an assertion aborts the run rather than
## returning something to check.
func _check_plan(t) -> void:
	var small: Array[Vector2i] = [Vector2i(40, 60), Vector2i(20, 20), Vector2i(64, 10)]
	var fitting: Dictionary = TextureAtlas.plan(small)
	t.check(fitting["fits"], "a handful of small pictures fits the %dpx side"
			% TextureAtlas.MAX_ATLAS_SIDE)
	var regions: Array = fitting["regions"]
	t.check(regions.size() == small.size(), "every size asked about comes back with a region")
	for index in regions.size():
		var region: Rect2i = regions[index]
		t.check(region.size == small[index],
				"the region for size %s is that size (%s)" % [small[index], region.size])
	for i in regions.size():
		for j in range(i + 1, regions.size()):
			t.check(not (regions[i] as Rect2i).intersects(regions[j] as Rect2i),
					"planned regions %s and %s do not overlap" % [regions[i], regions[j]])

	# One row of full-width pictures per shelf, more shelves than the cap has room for: the set
	# `request()`'s own assertion exists to refuse.
	var huge: Array[Vector2i] = []
	for index in 40:
		huge.append(Vector2i(TextureAtlas.MAX_ATLAS_SIDE - 2 * TextureAtlas.PADDING, 100))
	var overflowing: Dictionary = TextureAtlas.plan(huge)
	t.check(not overflowing["fits"],
			"a set that cannot fit reports so rather than being packed (%s against %dpx)"
			% [overflowing["size"], TextureAtlas.MAX_ATLAS_SIDE])

## Requests the café group once under the mode `TextureResolver` is already set to, and
## checks what `texture_for()` answers before the collect, after it and after the release, and
## that every region lies inside the atlas, no two overlap, and each region's own pixels equal its
## source image's.
func _check_pack(t, label: String) -> void:
	var sources := _sources()
	t.check(TextureAtlas.texture_for(NAME, EventInstance.CAFE_TABLE, EventInstance.CAFE_TABLE)
			== EventInstance.CAFE_TABLE,
			"%s: a group nobody has requested answers the source it was handed" % label)

	t.check(TextureAtlas.request(NAME, sources), "%s: the request is the one that starts the pack"
			% label)
	t.check(not TextureAtlas.request(NAME, {}), "%s: a second request for the same name is ignored"
			% label)
	t.check(not TextureAtlas.is_ready(NAME), "%s: the atlas is not ready before it is collected"
			% label)
	for key: Texture2D in sources.keys():
		var before: Texture2D = TextureAtlas.texture_for(NAME, key)
		t.check(not (before is AtlasTexture),
				"%s: %s draws its own source until the atlas is collected"
				% [label, key.resource_path.get_file()])
		t.check(before == TextureResolver.resolve(key),
				"%s: and the source it draws is the raster the resolver chose for this mode (%s)"
				% [label, key.resource_path.get_file()])

	t.check(TextureAtlas.collect(NAME, true), "%s: the pack collects" % label)
	t.check(TextureAtlas.is_ready(NAME), "%s: and reports itself ready" % label)

	# [key, region: Rect2i, source pixels: Image] — the source image converted the same way
	# `TextureAtlas.request()` converts it, so the pixel comparison below is against exactly what
	# was blitted rather than against a source format that may disagree on channel layout.
	var entries: Array = []
	var atlas_texture: Texture2D = null
	for key: Texture2D in sources.keys():
		var region_texture: Texture2D = TextureAtlas.texture_for(NAME, key)
		var name := key.resource_path.get_file()
		t.check(region_texture is AtlasTexture, "%s: %s comes back as an AtlasTexture"
				% [label, name])
		if not region_texture is AtlasTexture:
			continue
		var as_atlas := region_texture as AtlasTexture
		if atlas_texture == null:
			atlas_texture = as_atlas.atlas
		t.check(as_atlas.atlas == atlas_texture,
				"%s: %s shares the one atlas texture every other picture does" % [label, name])
		var source_texture: Texture2D = TextureResolver.resolve(key)
		t.check(as_atlas.get_size() == source_texture.get_size(),
				"%s: %s reports its source's own size (%s against %s)"
				% [label, name, as_atlas.get_size(), source_texture.get_size()])
		var source_image: Image = source_texture.get_image().duplicate()
		if source_image.get_format() != Image.FORMAT_RGBA8:
			source_image.convert(Image.FORMAT_RGBA8)
		entries.append([name, Rect2i(as_atlas.region), source_image])

	t.check(atlas_texture != null, "%s: the atlas actually packed something" % label)
	if atlas_texture == null:
		return
	var atlas_size := Vector2i(atlas_texture.get_size())
	t.check(atlas_size.x <= TextureAtlas.MAX_ATLAS_SIDE
			and atlas_size.y <= TextureAtlas.MAX_ATLAS_SIDE,
			"%s: the atlas is inside the %dpx phone-safe side (got %s)"
			% [label, TextureAtlas.MAX_ATLAS_SIDE, atlas_size])

	var atlas_image := atlas_texture.get_image()
	for entry in entries:
		var name: String = entry[0]
		var region: Rect2i = entry[1]
		var source_image: Image = entry[2]
		t.check(region.position.x >= 0 and region.position.y >= 0
				and region.end.x <= atlas_size.x and region.end.y <= atlas_size.y,
				"%s: %s's region lies inside the atlas (%s in %s)"
				% [label, name, region, atlas_size])
		t.check(region.size == source_image.get_size(),
				"%s: %s's region is exactly its source's own size (%s against %s)"
				% [label, name, region.size, source_image.get_size()])
		var mismatched := 0
		for y in region.size.y:
			for x in region.size.x:
				if atlas_image.get_pixel(region.position.x + x, region.position.y + y) \
						!= source_image.get_pixel(x, y):
					mismatched += 1
		t.check(mismatched == 0,
				"%s: %s's packed pixels equal its source image's (%d of %d px differ)"
				% [label, name, mismatched, region.size.x * region.size.y])

	for i in entries.size():
		for j in range(i + 1, entries.size()):
			var a: Rect2i = entries[i][1]
			var b: Rect2i = entries[j][1]
			t.check(not a.intersects(b), "%s: %s and %s do not overlap (%s against %s)"
					% [label, entries[i][0], entries[j][0], a, b])

	TextureAtlas.release(NAME)
	t.check(not TextureAtlas.is_ready(NAME), "%s: the released group is not ready any more" % label)
	for key: Texture2D in sources.keys():
		t.check(TextureAtlas.texture_for(NAME, key, key) == key,
				"%s: %s draws its own source again once the group is released"
				% [label, key.resource_path.get_file()])
