class_name GroundLayers
extends RefCounted
## Builds the ground's presentation TileSet out of the baked `ground` page, once per repaint.
##
## **Every picture comes out of one image, and one image goes back to the GPU.**
## `AtlasLibrary.page_image(ATLAS_GROUP)` is read once per build; each base, overlay, damage
## stencil, grass feature and whole authored tile is a `get_region()` of it, addressed by the
## region name `assets/ground_tileset.tres` carries on each source. Nothing here loads a picture
## from disk and nothing reads a texture back from the GPU per picture.
##
## **The composition stays at runtime, and that is a decision rather than an accident.**
## *(PLAYTEST-108, on baking the grass variants and the route-curb tint as pages of their own:
## "no, we bake each individual item and the composite at runtime. this is not a bottleneck and it
## allows for variety. if we baked everything either we would need to make the atlas huge or we
## would lose variety.")* So the bases, the transparent overlays, the six damage stencils, the
## eight sparse grass variants and the route kerbs' tinted twins are all composed here, per build.
##
## **The presentation mode is the bake's.** A page baked from the illustrated PNGs composes; a
## page baked from the authored SVG rasters (`tools/bake-atlases.sh --svg`) carries whole tiles
## already drawn and composes nothing but the route-kerb tint, which it takes by matching the
## stone's own fill colour. There is no runtime switch between the two: the pixels on the page are
## the ones the build chose.

## The composition recipe: which shared base and which transparent overlays each source id wants,
## which severity pool each damage source draws from, and the grass features. Its filenames are
## the illustrated PNGs' — `_layer_image()` turns each one back into its authored SVG's region
## name, so the recipe is read from the file it has always been read from and the pixels come off
## the page.
const MANIFEST_PATH := "res://assets/illustrated/svg-transfer/tiles/layers/manifest.json"
## Where the manifest's component filenames come from as authored art. A manifest naming
## `curbstone.png` means `assets/tiles/layers/curbstone.svg`, whose region is `tiles/layers/
## curbstone` — the one rule, applied through `AtlasLibrary.region_name_for()` rather than spelt
## out a second time.
const LAYER_SOURCE_ROOT := "assets/tiles/layers/"
## The baked page every ground picture is a region of. Held from startup by `main.gd`, so reading
## it here never touches the disk in a played frame.
const ATLAS_GROUP := &"ground"

const TILE_SIZE := Vector2i(32, 32)
const GRASS_SOURCE_ID := 12
const FOREST_SOURCE_ID := 17
const GRASS_VARIANTS := 8
const DAMAGE_VARIANTS := 6
const DAMAGE_SOURCE_IDS := [40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57]

## The curbstone's own fill in every `assets/tiles/sidewalk_kerb*.svg` — the road-side rect, whose
## `x`/`y` and `width`/`height` differ by direction but whose colour does not. An SVG bake's
## route-kerb twins tint by this colour rather than by a rect per source, since the eight files
## already agree on it and a main kerb's red clearway line does not share it.
const SVG_KERB_STONE_COLOR := Color8(0xa4, 0x9b, 0x8c)
## How far a pixel may drift from `SVG_KERB_STONE_COLOR` (or any other target colour matched this
## way) and still count as it — wide enough for whatever antialiasing the SVG rasterizer applies to
## a `shape-rendering="crispEdges"` rect, nowhere near the neighbouring paving (`#8b8478`) or
## dividing line (`#7a7469`) colours it must not also catch.
const _COLOR_MATCH_TOLERANCE := 0.03

# ------------------------------------------------------------------ the build ---

## Duplicates `authored` and gives every source its picture, composed out of the baked page.
##
## An incomplete recipe — a missing manifest, a component the bake does not carry — leaves that
## source on its own authored picture rather than half-composed, so an unfinished art drop cannot
## erase a marking or change the TileSet's geometry. A source whose picture cannot be found at all
## is left out of the sheet and keeps no tiles, which is the same graceful fallback one level down:
## `GroundTiles` still names it and `TileMapLayer` draws nothing for it — and it is an engine error,
## since every authored name is a member of the group and the test gate is red for one.
static func build_tile_set(authored: TileSet) -> TileSet:
	if authored == null:
		return null
	var started := Time.get_ticks_usec()
	var page := AtlasLibrary.page_image(ATLAS_GROUP)
	if page == null:
		push_error("The baked '%s' page did not read back; the ground cannot be composed"
				% ATLAS_GROUP)
		return null
	var result := authored.duplicate(true) as TileSet
	var manifest := _layer_recipe()
	# Built once and shared by both grass sources, exactly as the authored TileSet shares one
	# picture between two source ids — `_upload_one_sheet` places a shared image once.
	var grass: Image = _grass_atlas(manifest, page) if not manifest.is_empty() else null
	var pictures: Dictionary = {}
	for source_index in result.get_source_count():
		var source_id := result.get_source_id(source_index)
		var source := result.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		var picture: Image = null
		if not manifest.is_empty():
			if source_id in DAMAGE_SOURCE_IDS:
				picture = _damage_atlas(source_id, manifest, page)
			elif source_id in [GRASS_SOURCE_ID, FOREST_SOURCE_ID]:
				picture = grass
			else:
				picture = _layered_image(source_id, manifest, page, false)
		if picture == null:
			picture = _source_image(page, source)
		if picture != null:
			pictures[source_id] = picture
		else:
			# Every authored name is a member of the `ground` group, so this is a membership
			# mistake rather than an unfinished art drop, and the test gate is red for an engine
			# error where a tile that draws nothing would pass unseen.
			push_error("Ground source %d names '%s', which is not a region of the baked '%s' page"
					% [source_id, source.resource_name, ATLAS_GROUP])
	_register_route_kerb_twins(result, manifest, page, pictures)
	_upload_one_sheet(result, pictures, started)
	return result

## The composition recipe, or `{}` for "compose nothing and draw the authored tiles".
##
## An SVG bake is the second case: its page carries each tile as its author drew it, markings
## included, so composing a kerb over a paving base there would draw the kerb twice.
static func _layer_recipe() -> Dictionary:
	if AtlasLibrary.bake_mode() == "svg":
		return {}
	var manifest := _load_manifest()
	if manifest.is_empty() or int(manifest.get("tile_size", 0)) != TILE_SIZE.x:
		return {}
	return manifest

## Lays every picture into one image, uploads that image once, and points every source at it.
##
## **Every tile coordinate still lands on its own tile, and that is what `margins` is for.** A
## source's grid is read from `margins` at `texture_region_size` steps with `separation` between
## them; only the first of those is set here, to wherever this source's picture was laid down, so
## a painter asking for cell (3,0) gets the fourth 32px cell of that source's own picture. The
## texture is assigned before the margin and the tiles are created last, because a tile can only
## be created where the texture currently set actually has room for it.
##
## **How many cells a source has is its picture's own width.** The damage atlases are six tiles
## wide and the grass atlas eight; everything else is one. That is why the authored TileSet
## declares no tiles at all — a source's cells follow the picture it is given, and the picture is
## not known until here.
##
## **One upload, synchronous, not a `WorkerThreadPool` task.** This runs inside `build_tile_set()`,
## which is called before the first day is drawn and again at each day's repaint, and a `TileSet`
## has no "until it is ready" state to draw from in the meantime. Its cost is a `texture` line in
## the run log for exactly that reason.
##
## Two source ids sharing one picture — grass and forest — are laid down once and given the same
## margin, since the authored TileSet is allowed to give two ids the same art.
static func _upload_one_sheet(tile_set: TileSet, pictures: Dictionary, started: int) -> void:
	var ids: Array[int] = []
	for source_id: int in pictures.keys():
		ids.append(source_id)
	ids.sort()
	var placement_of: Dictionary = {}
	var of_image: Dictionary = {}
	var images: Array[Image] = []
	var sizes: Array[Vector2i] = []
	for source_id in ids:
		var picture: Image = pictures[source_id]
		if not of_image.has(picture):
			of_image[picture] = images.size()
			images.append(picture)
			sizes.append(picture.get_size())
		placement_of[source_id] = of_image[picture]
	if images.is_empty():
		return
	# The same packer the bake uses, so the ground has one idea of "fits" and the milestone's own
	# runtime packer has one consumer fewer.
	var layout := AtlasLibrary.plan(sizes)
	var sheet_size: Vector2i = layout["size"]
	if not layout["fits"]:
		push_error("The composed ground is %s, over the %dpx phone-safe canvas side"
				% [sheet_size, AtlasLibrary.MAX_ATLAS_SIDE])
		return
	var regions: Array = layout["regions"]
	var sheet := Image.create(sheet_size.x, sheet_size.y, false, Image.FORMAT_RGBA8)
	for index in images.size():
		var picture: Image = images[index]
		sheet.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()),
				(regions[index] as Rect2i).position)
	var shared := ImageTexture.create_from_image(sheet)
	for source_id in ids:
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		var picture: Image = pictures[source_id]
		source.texture = shared
		source.margins = (regions[placement_of[source_id]] as Rect2i).position
		for cell in picture.get_width() / TILE_SIZE.x:
			source.create_tile(Vector2i(cell, 0))
	Telemetry.note("texture", "ground composed: %d sources over %d pictures into %dx%d in %.1f ms"
			% [ids.size(), images.size(), sheet_size.x, sheet_size.y,
			(Time.get_ticks_usec() - started) / 1000.0])

# ---------------------------------------------------------------- the picture ---

## Returns the atlas coordinate selected for a ground cell. The source ID stays the map's own ID;
## grass and damage sources add visual-only atlas cells, so collision and semantic selection stay
## unchanged while their shared details can vary by city seed and coordinate.
static func atlas_coords_for(source_id: int, city_seed: int, tile: Vector2i,
		tile_set: TileSet) -> Vector2i:
	if source_id in [GRASS_SOURCE_ID, FOREST_SOURCE_ID]:
		var grass := tile_set.get_source(source_id) as TileSetAtlasSource
		# The question is whether the variation cells were actually created, asked of the source's
		# own tiles rather than of its texture's width: every source shares one sheet, so a width is
		# the whole ground's and says nothing about this source at all.
		if grass == null or not grass.has_tile(Vector2i(GRASS_VARIANTS - 1, 0)):
			return Vector2i.ZERO
		return Vector2i(posmod(hash("grass:%d:%d:%d" % [city_seed, tile.x, tile.y]), GRASS_VARIANTS), 0)
	if source_id in DAMAGE_SOURCE_IDS:
		var damage := tile_set.get_source(source_id) as TileSetAtlasSource
		# Its own tiles, not its texture's width — see the grass guard above.
		if damage == null or not damage.has_tile(Vector2i(DAMAGE_VARIANTS - 1, 0)):
			return Vector2i.ZERO
		# Surface and A/B source IDs retain GroundTiles' placement semantics; this seed/cell hash only
		# selects the shared drawing, so one coordinate has the same variation on every material.
		return Vector2i(posmod(hash("damage:%d:%d:%d" % [city_seed, tile.x, tile.y]), DAMAGE_VARIANTS), 0)
	return Vector2i.ZERO

## Alpha-composites opaque `base` and transparent layers without changing base pixels where an
## overlay is empty. Public for the focused pixel-level contract tests.
static func compose_image(base: Image, overlays: Array[Image]) -> Image:
	var result := base.duplicate()
	for overlay in overlays:
		if overlay == null or overlay.get_size() != result.get_size():
			return null
		result.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), Vector2i.ZERO)
	return result

## Rotates a component clockwise in the manifest's declared coordinate system.
static func rotate_clockwise(image: Image, degrees: int) -> Image:
	var result := image.duplicate()
	match posmod(degrees, 360):
		0:
			return result
		90:
			result.rotate_90(false)
		180:
			result.rotate_180()
		270:
			result.rotate_90(true)
		_:
			return null
	return result

static func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(MANIFEST_PATH)) != OK:
		push_warning("Ignoring invalid ground layer manifest: %s" % MANIFEST_PATH)
		return {}
	var data: Variant = parser.data
	return data if data is Dictionary and int(data.get("version", 0)) == 1 else {}

## Composes `source_id`'s base and rotated components, tinting the `curbstone` component first
## when `tint_curbstone` asks for it — which is the route's own cast (M145's trial): the paving,
## and on a main-road kerb the `main_edge_red` clearway line, are untouched and only the stone
## carries it.
static func _layered_image(source_id: int, manifest: Dictionary, page: Image,
		tint_curbstone: bool) -> Image:
	if source_id in [GRASS_SOURCE_ID, FOREST_SOURCE_ID]:
		return null
	var source_bases: Dictionary = manifest.get("source_bases", {})
	var base_name: String = source_bases.get(str(source_id), "")
	if base_name.is_empty():
		return null
	var base := _base_image(base_name, manifest, page)
	if base == null:
		return null
	var source_layers: Dictionary = manifest.get("source_layers", {})
	var records: Array = source_layers.get(str(source_id), [])
	var overlays: Array[Image] = []
	for record_value in records:
		if not record_value is Dictionary:
			return null
		var record: Dictionary = record_value
		var component_name: String = record.get("component", "")
		var overlay := _component_image(component_name, manifest, page)
		if overlay == null:
			return null
		var rotated := rotate_clockwise(overlay, int(record.get("rotation_degrees", 0)))
		if rotated == null:
			return null
		if tint_curbstone and component_name == "curbstone":
			rotated = _tint_opaque(rotated)
		overlays.append(rotated)
	return compose_image(base, overlays)

## Registers each of `GroundTiles.ROUTE_KERB_SOURCES`' tinted twins on `tile_set`, at the id
## `GroundTiles.route_twin_of` gives its source, and hands its picture to the sheet — one
## single-cell source per twin, matching the plain kerb sources' own shape.
##
## Where the page carries composed layers the twin is the same composition with the `curbstone`
## component tinted; where it carries whole authored tiles (an SVG bake) there is no separate
## stone to tint, so the stone is found by its own fill colour instead. A source with no
## registered twin id, or whose twin cannot be built, is left without one:
## `City._tint_the_route_kerbs()` already skips a tile whose twin does not exist, the same
## graceful fallback the rest of this file gives an incomplete art drop.
static func _register_route_kerb_twins(tile_set: TileSet, manifest: Dictionary, page: Image,
		pictures: Dictionary) -> void:
	for source_id in GroundTiles.ROUTE_KERB_SOURCES:
		var twin_id := GroundTiles.route_twin_of(source_id)
		if twin_id < 0 or tile_set.has_source(twin_id):
			continue
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		var twin: Image = null
		if manifest.is_empty():
			# Its size is asked before the tint, because a twin that is not one whole tile would be
			# given `picture.get_width() / TILE_SIZE.x` cells by `_upload_one_sheet()` — a kerb with
			# two cells or none rather than a source left without a twin, which is the fallback
			# `City._tint_the_route_kerbs()` is written against.
			var plain := _source_image(page, source)
			if plain != null and plain.get_size() == TILE_SIZE:
				twin = _tint_matching(plain, SVG_KERB_STONE_COLOR)
		else:
			twin = _layered_image(source_id, manifest, page, true)
		if twin == null:
			continue
		var twin_source := TileSetAtlasSource.new()
		twin_source.texture_region_size = TILE_SIZE
		tile_set.add_source(twin_source, twin_id)
		pictures[twin_id] = twin

## Composes every accepted stencil in the source's severity pool over its own semantic base, six
## cells in a row. The source ID still tells `GroundTiles` which material and severity it placed;
## only the atlas cell is visual variation, so an unavailable pool leaves the authored picture
## untouched.
static func _damage_atlas(source_id: int, manifest: Dictionary, page: Image) -> Image:
	var source_bases: Dictionary = manifest.get("source_bases", {})
	var base := _base_image(str(source_bases.get(str(source_id), "")), manifest, page)
	var damage_types: Dictionary = manifest.get("source_damage_types", {})
	var damage_type: String = str(damage_types.get(str(source_id), ""))
	var pools: Dictionary = manifest.get("damage_pools", {})
	var pool: Array = pools.get(damage_type, [])
	if base == null or pool.size() != DAMAGE_VARIANTS:
		return null
	var atlas := Image.create(TILE_SIZE.x * DAMAGE_VARIANTS, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	for variant in DAMAGE_VARIANTS:
		var overlay := _component_image(str(pool[variant]), manifest, page)
		var composed := compose_image(base, [overlay]) if overlay != null else null
		if composed == null:
			return null
		atlas.blit_rect(composed, Rect2i(Vector2i.ZERO, TILE_SIZE), Vector2i(variant * TILE_SIZE.x, 0))
	return atlas

static func _grass_atlas(manifest: Dictionary, page: Image) -> Image:
	var base := _base_image("grass", manifest, page)
	if base == null:
		return null
	var feature_names: Array = manifest.get("grass_features", [])
	if feature_names.is_empty():
		return null
	var features: Array[Image] = []
	for feature_name_value in feature_names:
		var feature := _component_image(str(feature_name_value).trim_suffix(".png"), manifest, page)
		if feature == null:
			return null
		features.append(feature)
	var atlas := Image.create(TILE_SIZE.x * GRASS_VARIANTS, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	for variant in GRASS_VARIANTS:
		var tile := _grass_variant(base, features, variant)
		atlas.blit_rect(tile, Rect2i(Vector2i.ZERO, TILE_SIZE), Vector2i(variant * TILE_SIZE.x, 0))
	return atlas

static func _grass_variant(base: Image, features: Array[Image], variant: int) -> Image:
	var result := base.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("grass-variant:%d" % variant)
	var count := variant % 3
	for index in count:
		var feature: Image = features[rng.randi_range(0, features.size() - 1)]
		var visible := feature.get_used_rect()
		if not visible.has_area():
			continue
		# Whole clumps stay inside their cell; clipping a feature at its own edge reads as noise.
		var max_at := TILE_SIZE - visible.size
		var at := Vector2i(rng.randi_range(0, max_at.x), rng.randi_range(0, max_at.y))
		result.blend_rect(feature, visible, at)
	return result

# --------------------------------------------------------------- off the page ---

## The picture `source` was authored with, read off the page.
##
## **`resource_name` on each `TileSetAtlasSource` in `assets/ground_tileset.tres` is its region
## name**, which is how that file names a picture now that it references no texture at all: a
## `.tres` can only carry tiles for a source that already has a texture, and the texture is the
## composed sheet, which does not exist until `_upload_one_sheet()`. So the authored file carries
## the id, the cell size and the name, and everything else follows from the page.
static func _source_image(page: Image, source: TileSetAtlasSource) -> Image:
	return _region_image(page, StringName(source.resource_name))

## One region of the page as its own image, or null where the bake does not carry that name.
static func _region_image(page: Image, name: StringName) -> Image:
	if name.is_empty() or not AtlasLibrary.has_region(name):
		return null
	var rect := AtlasLibrary.region_rect(name)
	if not rect.has_area() or not Rect2i(Vector2i.ZERO, page.get_size()).encloses(rect):
		return null
	return page.get_region(rect)

static func _base_image(name: String, manifest: Dictionary, page: Image) -> Image:
	var bases: Dictionary = manifest.get("bases", {})
	return _layer_image(str(bases.get(name, "")), page)

static func _component_image(name: String, manifest: Dictionary, page: Image) -> Image:
	var components: Dictionary = manifest.get("components", {})
	return _layer_image(str(components.get(name, "")), page)

## A manifest filename (`curbstone.png`) is the leaf of the SVG it was drawn from
## (`assets/tiles/layers/curbstone.svg`), and the region is that path's own name. A component the
## bake does not carry, or one that is not a whole tile, answers null and leaves its source on the
## authored picture.
static func _layer_image(filename: String, page: Image) -> Image:
	if filename.is_empty():
		return null
	var name := AtlasLibrary.region_name_for(LAYER_SOURCE_ROOT + filename.trim_suffix(".png") + ".svg")
	var image := _region_image(page, name)
	return image if image != null and image.get_size() == TILE_SIZE else null

# ----------------------------------------------------------------- the tinting ---

## Blends every opaque pixel of `image` toward `Palette.ROUTE_KERB_TINT` by
## `Tuning.ROUTE_KERB_TINT_ALPHA`, keeping each pixel's own alpha. Used for the curbstone
## component, whose opaque pixels are the whole of the drawing.
static func _tint_opaque(image: Image) -> Image:
	var result := image.duplicate()
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			result.set_pixel(x, y, _tinted_pixel(pixel))
	return result

## Blends every pixel of `image` within `_COLOR_MATCH_TOLERANCE` of `target` toward
## `Palette.ROUTE_KERB_TINT` by `Tuning.ROUTE_KERB_TINT_ALPHA`, keeping each pixel's own alpha.
## Used for an SVG bake's kerb tile, where the stone is identified by its own authored fill colour
## rather than by a separate component picture.
static func _tint_matching(image: Image, target: Color) -> Image:
	var result := image.duplicate()
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0 or not _close_enough(pixel, target):
				continue
			result.set_pixel(x, y, _tinted_pixel(pixel))
	return result

static func _close_enough(pixel: Color, target: Color) -> bool:
	return absf(pixel.r - target.r) < _COLOR_MATCH_TOLERANCE \
			and absf(pixel.g - target.g) < _COLOR_MATCH_TOLERANCE \
			and absf(pixel.b - target.b) < _COLOR_MATCH_TOLERANCE

static func _tinted_pixel(pixel: Color) -> Color:
	var blended := pixel.lerp(Palette.ROUTE_KERB_TINT, Tuning.ROUTE_KERB_TINT_ALPHA)
	blended.a = pixel.a
	return blended
