extends RefCounted
## M171, "the ground": `assets/ground_tileset.tres` carries no picture of its own any more, and
## `GroundLayers` builds every ground tile out of the baked `ground` page.
##
## **The reference is rebuilt from the page and the manifest, never from the compositor.** Every
## expected picture here is fetched by region name out of `AtlasLibrary.page_image(&"ground")` and
## composed with `Image`'s own `blend_rect`/`rotate_90`, so a compositor that read the wrong
## region, rotated a component the wrong way, or wrote a margin that lands a coordinate on its
## neighbour's pixels fails by name. Calling `GroundLayers`' own helpers to build the reference
## would make every one of those green.
##
## **M163's rule holds here** (`docs/DECISIONS.md`, M163, the ground atlas test builds the same
## reference it compares): the source counts are asserted, `has_source()` is asked before
## `get_source()` — which prints an engine error and answers null for an id it does not have — and
## every sweep says how many sources it actually looked at, so a comparison that silently skipped
## the generated route-kerb twins cannot pass.
##
## **The presentation mode is the bake's**, so this asks whatever question the tree's own bake
## answers. A default bake gives a page of illustrated components and most sources compose from
## them; `tools/bake-atlases.sh --svg` gives a page of whole authored tiles and nothing composes
## but the route-kerb tint. There is no runtime switch between the two to drive from a test.

const AUTHORED_PATH := "res://assets/ground_tileset.tres"
const AUTHORED_GROUND: TileSet = preload(AUTHORED_PATH)
const MANIFEST_PATH := "res://assets/illustrated/svg-transfer/tiles/layers/manifest.json"
## Where a manifest component filename comes from as authored art, the one rule
## `GroundLayers._layer_image()` applies: `curbstone.png` is `assets/tiles/layers/curbstone.svg`,
## whose region is `tiles/layers/curbstone`.
const LAYER_SOURCE_ROOT := "assets/tiles/layers/"
## Below this the sweep has stopped asking about the ground at all rather than found it correct.
const FEWEST_CREDIBLE_SOURCES := 50

func run(t) -> void:
	AtlasLibrary.reset_for_tests()
	_test_the_authored_tile_set_names_regions_instead_of_pictures(t)
	_test_the_ground_is_one_composed_sheet(t)
	_test_every_tile_is_the_page_the_manifest_asked_for(t)
	_test_a_repaint_composes_the_same_pixels_again(t)
	AtlasLibrary.reset_for_tests()

# ------------------------------------------------------------- the authored file ---

## The authored TileSet is an id, a cell size and a region name per source, and nothing else: no
## `ext_resource`, no texture, and every name a region the bake actually wrote on the `ground`
## group. A `.tres` cannot carry tiles for a source with no texture, so the cells are created by
## `GroundLayers._upload_one_sheet()` once the composed sheet exists — which is why the counts
## below are asserted against the composed TileSet rather than against this one.
func _test_the_authored_tile_set_names_regions_instead_of_pictures(t) -> void:
	var text := FileAccess.get_file_as_string(AUTHORED_PATH)
	t.check(not text.is_empty(), "the authored ground TileSet reads back as text")
	t.check(not text.contains("ext_resource"),
			"the authored ground TileSet references no picture of its own")
	var named := 0
	var unnamed: Array[String] = []
	var missing: Array[String] = []
	var misfiled: Array[String] = []
	var textured: Array[String] = []
	for index in AUTHORED_GROUND.get_source_count():
		var id := AUTHORED_GROUND.get_source_id(index)
		var source := AUTHORED_GROUND.get_source(id) as TileSetAtlasSource
		if source == null:
			continue
		if source.texture != null:
			textured.append(str(id))
		var name := StringName(source.resource_name)
		if name.is_empty():
			unnamed.append(str(id))
			continue
		named += 1
		if not AtlasLibrary.has_region(name):
			missing.append("%d -> %s" % [id, name])
		elif AtlasLibrary.group_of(name) != GroundLayers.ATLAS_GROUP:
			misfiled.append("%d -> %s (on '%s')" % [id, name, AtlasLibrary.group_of(name)])
	t.check(textured.is_empty(), "no authored ground source still holds a texture (%s)"
			% ", ".join(textured.slice(0, 5)))
	t.check(unnamed.is_empty(), "every authored ground source names its region (%s unnamed)"
			% ", ".join(unnamed.slice(0, 5)))
	t.check(missing.is_empty(), "every named region is one the bake wrote (%d missing: %s)"
			% [missing.size(), ", ".join(missing.slice(0, 5))])
	t.check(misfiled.is_empty(), "every named region is on the '%s' group (%d elsewhere: %s)"
			% [GroundLayers.ATLAS_GROUP, misfiled.size(), ", ".join(misfiled.slice(0, 5))])
	t.check(named >= FEWEST_CREDIBLE_SOURCES,
			"there were authored ground sources to ask about (%d)" % named)

# ------------------------------------------------------------------- the sheet ---

## One composed image goes to the GPU and every source draws from it, which is what replaced the
## second runtime packer. The sheet is built here rather than read from disk, so it carries no
## `resource_path` — the check that distinguishes "composed from the page" from "a picture that
## was loaded".
func _test_the_ground_is_one_composed_sheet(t) -> void:
	var composed := GroundLayers.build_tile_set(AUTHORED_GROUND)
	t.check(composed != null, "the ground TileSet composes at all")
	if composed == null:
		return
	var shared: Texture2D = null
	var seen := 0
	var strangers: Array[String] = []
	for index in composed.get_source_count():
		var id := composed.get_source_id(index)
		var source := composed.get_source(id) as TileSetAtlasSource
		if source == null or source.texture == null:
			strangers.append("%d has no picture" % id)
			continue
		seen += 1
		if shared == null:
			shared = source.texture
		elif source.texture != shared:
			strangers.append("%d draws from a second texture" % id)
	t.check(strangers.is_empty(), "every ground source draws from the one composed sheet (%s)"
			% ", ".join(strangers.slice(0, 5)))
	t.check(seen >= FEWEST_CREDIBLE_SOURCES, "there were composed sources to ask about (%d)" % seen)
	t.check(shared is ImageTexture,
			"the sheet is an image composed here rather than a texture loaded from disk")
	t.check(shared != null and shared.resource_path.is_empty(),
			"the composed sheet has no resource path of its own (%s)"
			% (shared.resource_path if shared != null else "no sheet"))
	var size := Vector2i(shared.get_size()) if shared != null else Vector2i.ZERO
	t.check(size.x <= AtlasLibrary.MAX_ATLAS_SIDE and size.y <= AtlasLibrary.MAX_ATLAS_SIDE,
			"the composed ground fits the %dpx phone-safe canvas side (%s)"
			% [AtlasLibrary.MAX_ATLAS_SIDE, size])
	# The authored ids all survive with their authored geometry, and the route-kerb twins are on
	# top of them — asked with `has_source()` first, so a missing id fails by name here instead of
	# printing an engine error the runner never counts (M163).
	var lost: Array[String] = []
	var reshaped: Array[String] = []
	for index in AUTHORED_GROUND.get_source_count():
		var id := AUTHORED_GROUND.get_source_id(index)
		if not composed.has_source(id):
			lost.append(str(id))
			continue
		var before := AUTHORED_GROUND.get_source(id) as TileSetAtlasSource
		var after := composed.get_source(id) as TileSetAtlasSource
		if before == null or after == null:
			continue
		if after.texture_region_size != before.texture_region_size \
				or after.separation != before.separation:
			reshaped.append("%d (%s/%s against %s/%s)" % [id, after.texture_region_size,
					after.separation, before.texture_region_size, before.separation])
	t.check(lost.is_empty(), "composing keeps every authored source id (%s lost)"
			% ", ".join(lost.slice(0, 5)))
	t.check(reshaped.is_empty(), "composing keeps every source's authored cell geometry (%s)"
			% ", ".join(reshaped.slice(0, 5)))
	var twins := 0
	for source_id in GroundTiles.ROUTE_KERB_SOURCES:
		var twin_id := GroundTiles.route_twin_of(source_id)
		if twin_id >= 0 and composed.has_source(twin_id):
			twins += 1
	t.check(twins == GroundTiles.ROUTE_KERB_SOURCES.size(),
			"every route-kerb source has its tinted twin registered (%d of %d)"
			% [twins, GroundTiles.ROUTE_KERB_SOURCES.size()])
	t.check(composed.get_source_count() == AUTHORED_GROUND.get_source_count() + twins,
			"the composed TileSet is the authored sources plus their twins and nothing else (%d against %d + %d)"
			% [composed.get_source_count(), AUTHORED_GROUND.get_source_count(), twins])

# -------------------------------------------------------------- the pixels ---

## Every tile is the picture the page carries, composed the way the manifest says — rebuilt here
## out of the page rather than out of `GroundLayers`, so a wrong region, a wrong rotation or a
## margin that misses its cell is a named failure.
##
## The route-kerb twins are left to `tests/test_ground_layers.gd`, which owns the tint's own
## contract; the cells checked here are the untinted ones.
func _test_every_tile_is_the_page_the_manifest_asked_for(t) -> void:
	var page := AtlasLibrary.page_image(GroundLayers.ATLAS_GROUP)
	t.check(page != null, "the baked ground page reads back as an image")
	if page == null:
		return
	var manifest := _composition_recipe()
	var composed := GroundLayers.build_tile_set(AUTHORED_GROUND)
	if composed == null:
		return
	var twin_ids: Dictionary = {}
	for source_id in GroundTiles.ROUTE_KERB_SOURCES:
		twin_ids[GroundTiles.route_twin_of(source_id)] = true
	var wrong: Array[String] = []
	var miscounted: Array[String] = []
	var checked := 0
	for index in AUTHORED_GROUND.get_source_count():
		var id := AUTHORED_GROUND.get_source_id(index)
		if twin_ids.has(id) or not composed.has_source(id):
			continue
		var source := composed.get_source(id) as TileSetAtlasSource
		var authored := AUTHORED_GROUND.get_source(id) as TileSetAtlasSource
		if source == null or authored == null or source.texture == null:
			continue
		var expected := _expected_cells(page, manifest, id, StringName(authored.resource_name))
		if expected.is_empty():
			continue
		if source.get_tiles_count() != expected.size():
			miscounted.append("%d has %d cells, the recipe wants %d"
					% [id, source.get_tiles_count(), expected.size()])
			continue
		for cell in expected.size():
			var coords := Vector2i(cell, 0)
			if not source.has_tile(coords):
				wrong.append("%d is missing cell %s" % [id, coords])
				continue
			checked += 1
			if _cell_image(source, coords).get_data() != (expected[cell] as Image).get_data():
				wrong.append("%d cell %s" % [id, coords])
	t.check(miscounted.is_empty(), "every source has the cells its recipe asks for (%s)"
			% ", ".join(miscounted.slice(0, 5)))
	t.check(wrong.is_empty(), "every ground cell is the page composed by the manifest (%d wrong: %s)"
			% [wrong.size(), ", ".join(wrong.slice(0, 5))])
	t.check(checked >= FEWEST_CREDIBLE_SOURCES, "there were ground cells to compare (%d)" % checked)

## Two builds of the same authored TileSet are the same pixels: the day repaint starts from the
## authored file every time, so layers can never accumulate across days.
func _test_a_repaint_composes_the_same_pixels_again(t) -> void:
	var first := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var second := GroundLayers.build_tile_set(AUTHORED_GROUND)
	if first == null or second == null:
		t.check(false, "both repaints compose a TileSet")
		return
	var first_sheet := _sheet_of(first)
	var second_sheet := _sheet_of(second)
	t.check(first_sheet != null and second_sheet != null, "both repaints produce a sheet")
	if first_sheet == null or second_sheet == null:
		return
	t.check(first_sheet.get_image().get_data() == second_sheet.get_image().get_data(),
			"a repaint composes the same sheet, so nothing accumulates across a day")

# ------------------------------------------------------------------ the reference ---

## What the recipe wants each cell of `source_id` to be, rebuilt from the page: the whole authored
## tile for a source the manifest says nothing about (and for every source in an SVG bake), the
## base alone where there are no components, base plus rotated components where there are, the six
## damage stencils over their own base, and the grass base as the grass atlas's first cell — the
## one grass variant that places no features, and so the one this can state without repeating the
## feature scatter's own RNG.
##
## `[]` for a cell set this cannot state independently, which is only the seven remaining grass
## cells; `tests/test_ground_layers.gd` holds what those owe.
func _expected_cells(page: Image, manifest: Dictionary, source_id: int, name: StringName) -> Array:
	if source_id in [GroundLayers.GRASS_SOURCE_ID, GroundLayers.FOREST_SOURCE_ID]:
		return []
	if manifest.is_empty():
		var whole := _region(page, name)
		return [whole] if whole != null else []
	var bases: Dictionary = manifest.get("bases", {})
	var source_bases: Dictionary = manifest.get("source_bases", {})
	var base_name := str(source_bases.get(str(source_id), ""))
	if base_name.is_empty():
		var authored := _region(page, name)
		return [authored] if authored != null else []
	var base := _layer(page, manifest, str(bases.get(base_name, "")))
	if base == null:
		return []
	if source_id in GroundLayers.DAMAGE_SOURCE_IDS:
		var damage_types: Dictionary = manifest.get("source_damage_types", {})
		var pools: Dictionary = manifest.get("damage_pools", {})
		var pool: Array = pools.get(str(damage_types.get(str(source_id), "")), [])
		if pool.size() != GroundLayers.DAMAGE_VARIANTS:
			return []
		var cells: Array = []
		for stencil in pool:
			var overlay := _component(page, manifest, str(stencil))
			if overlay == null:
				return []
			cells.append(_over(base, [overlay]))
		return cells
	var source_layers: Dictionary = manifest.get("source_layers", {})
	var overlays: Array[Image] = []
	for record_value in source_layers.get(str(source_id), []):
		if not record_value is Dictionary:
			return []
		var record: Dictionary = record_value
		var overlay := _component(page, manifest, str(record.get("component", "")))
		if overlay == null:
			return []
		overlays.append(_turned(overlay, int(record.get("rotation_degrees", 0))))
	return [_over(base, overlays)]

## The recipe the compositor is working from: the manifest for a default bake, `{}` for an SVG
## bake, whose page already carries whole authored tiles. Mirrors `GroundLayers._layer_recipe()`'s
## own branch rather than the run's `--svg` flag, which no longer decides anything here.
func _composition_recipe() -> Dictionary:
	if AtlasLibrary.bake_mode() == "svg":
		return {}
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(MANIFEST_PATH)) != OK:
		return {}
	var data: Variant = parser.data
	if not data is Dictionary or int((data as Dictionary).get("version", 0)) != 1:
		return {}
	var manifest: Dictionary = data
	return manifest if int(manifest.get("tile_size", 0)) == GroundLayers.TILE_SIZE.x else {}

func _layer(page: Image, _manifest: Dictionary, filename: String) -> Image:
	if filename.is_empty():
		return null
	var name := AtlasLibrary.region_name_for(
			LAYER_SOURCE_ROOT + filename.trim_suffix(".png") + ".svg")
	var image := _region(page, name)
	return image if image != null and image.get_size() == GroundLayers.TILE_SIZE else null

func _component(page: Image, manifest: Dictionary, name: String) -> Image:
	var components: Dictionary = manifest.get("components", {})
	return _layer(page, manifest, str(components.get(name, "")))

func _region(page: Image, name: StringName) -> Image:
	if name.is_empty() or not AtlasLibrary.has_region(name):
		return null
	var rect := AtlasLibrary.region_rect(name)
	if not rect.has_area() or not Rect2i(Vector2i.ZERO, page.get_size()).encloses(rect):
		return null
	return page.get_region(rect)

## Alpha-composited here with `Image`'s own call rather than through `GroundLayers.compose_image`,
## so this stays a reference and not a second reading of the code under test.
func _over(base: Image, overlays: Array[Image]) -> Image:
	var result := base.duplicate()
	for overlay in overlays:
		result.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), Vector2i.ZERO)
	return result

func _turned(image: Image, degrees: int) -> Image:
	var result := image.duplicate()
	match posmod(degrees, 360):
		90:
			result.rotate_90(false)
		180:
			result.rotate_180()
		270:
			result.rotate_90(true)
	return result

## One cell's own pixels, read the way the engine reads them: `get_tile_texture_region()` builds
## the rect from the source's `margins`, `texture_region_size` and `separation`, so going through
## it is also what checks that the margin the upload wrote lands each coordinate on its own tile
## rather than on a neighbour's.
func _cell_image(source: TileSetAtlasSource, coords: Vector2i) -> Image:
	return source.texture.get_image().get_region(source.get_tile_texture_region(coords))

func _sheet_of(tile_set: TileSet) -> Texture2D:
	for index in tile_set.get_source_count():
		var source := tile_set.get_source(tile_set.get_source_id(index)) as TileSetAtlasSource
		if source != null and source.texture != null:
			return source.texture
	return null
