class_name GroundLayers
extends RefCounted
## Builds the ground's shared-base variants once per TileSet, leaving paint-time work to select cells.

const MANIFEST_PATH := "res://assets/illustrated/svg-transfer/tiles/layers/manifest.json"
const TILE_SIZE := Vector2i(32, 32)
const GRASS_SOURCE_ID := 12
const FOREST_SOURCE_ID := 17
const GRASS_VARIANTS := 8
const DAMAGE_VARIANTS := 6
const DAMAGE_SOURCE_IDS := [40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57]

## The curbstone's own fill in every `assets/tiles/sidewalk_kerb*.svg` — the road-side rect, whose
## `x`/`y` and `width`/`height` differ by direction but whose colour does not. SVG-mode route-kerb
## twins tint by this colour rather than by a rect per source, since the eight files already agree
## on it and a main kerb's red clearway line does not share it.
const SVG_KERB_STONE_COLOR := Color8(0xa4, 0x9b, 0x8c)
## How far a pixel may drift from `SVG_KERB_STONE_COLOR` (or any other target colour matched this
## way) and still count as it — wide enough for whatever antialiasing the SVG importer applies to a
## `shape-rendering="crispEdges"` rect, nowhere near the neighbouring paving (`#8b8478`) or dividing
## line (`#7a7469`) colours it must not also catch.
const _COLOR_MATCH_TOLERANCE := 0.03

## Duplicates `authored` before replacing its SVG transfers and composing the available layer set.
## A malformed or incomplete layer set leaves that source on the resolver's normal PNG/SVG fallback;
## an unfinished transfer therefore cannot erase a marking or change the TileSet's geometry.
static func build_tile_set(authored: TileSet) -> TileSet:
	if authored == null:
		return null
	var result := authored.duplicate(true) as TileSet
	_replace_svg_transfers(result)
	if TextureResolver.svg_requested():
		# SVG mode composes nothing, but the tint twins are registered either way so the route's
		# kerbs have a tinted source to be repainted onto (M145); the pack below takes them too.
		_register_route_kerb_twins(result, {})
	else:
		_compose_layers(result)
	# Last, once every source's own texture is final: the shelf pack below reads them and points
	# them all at one texture, so anything that replaces a source's picture has to have happened.
	pack_into_one_texture(result)
	return result

## Composes the manifest's shared bases and transparent overlays onto every source that has them.
## Split out of `build_tile_set()` so the packing pass can be the one thing that always runs last,
## whichever presentation mode composed — or did not compose — the pictures before it.
static func _compose_layers(result: TileSet) -> void:
	var manifest := _load_manifest()
	if manifest.is_empty() or int(manifest.get("tile_size", 0)) != TILE_SIZE.x:
		return
	for source_index in result.get_source_count():
		var source_id := result.get_source_id(source_index)
		var source := result.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		var replacement := _damage_atlas(source_id, manifest) if source_id in DAMAGE_SOURCE_IDS \
				else _composed_texture(source_id, manifest)
		if replacement != null:
			source.texture = replacement
			if source_id in DAMAGE_SOURCE_IDS:
				for variant in range(1, DAMAGE_VARIANTS):
					source.create_tile(Vector2i(variant, 0))
	var grass_atlas := _grass_atlas(manifest)
	if grass_atlas != null:
		for source_id in [GRASS_SOURCE_ID, FOREST_SOURCE_ID]:
			var grass := result.get_source(source_id) as TileSetAtlasSource
			if grass == null:
				continue
			grass.texture = grass_atlas
			for variant in range(1, GRASS_VARIANTS):
				grass.create_tile(Vector2i(variant, 0))
	_register_route_kerb_twins(result, manifest)

## Points every `TileSetAtlasSource` in `tile_set` at one shared texture, so the ground stops
## being thirty-odd separate image sources at draw time — the composite the player asked for
## *(Playtest 76: "it is good to have everything built into atlases so the composite doesn't have
## to deal with multiple image sources")*.
##
## **Every tile coordinate still lands on its own tile, and that is what `margins` is for.** A
## source's grid is read from `margins` at `texture_region_size` steps with `separation` between
## them; only the first of those moves here, to wherever the source's own picture was packed, so
## `texture_region_size` and `separation` are untouched and a painter asking for cell (3,0) gets
## exactly the pixels it got before. The texture is assigned before the margin, because assigning
## a margin that pushes a tile outside the texture currently set would drop that tile.
##
## **Synchronous, not a `WorkerThreadPool` task**, unlike every other atlas in the game: this runs
## inside `build_tile_set()`, which is called before the first day is drawn and again at each
## day's repaint, and the ground has no fallback to draw from in the meantime — a `TileSet` has
## one texture per source and no "until it is ready" state to be in. Its cost is a `texture` line
## in the run log for exactly that reason.
##
## Sources sharing one texture object are packed once and given the same margin, since two source
## IDs over one sheet is a thing the authored `TileSet` is allowed to do.
static func pack_into_one_texture(tile_set: TileSet) -> void:
	var started := Time.get_ticks_usec()
	var sources: Array[TileSetAtlasSource] = []
	var placement_of: Array[int] = []
	var by_texture: Dictionary = {}
	var images: Array[Image] = []
	var sizes: Array[Vector2i] = []
	for source_index in tile_set.get_source_count():
		var source := tile_set.get_source(tile_set.get_source_id(source_index)) as TileSetAtlasSource
		if source == null or source.texture == null:
			continue
		var texture := source.texture
		if not by_texture.has(texture):
			var image := texture.get_image()
			if image == null:
				continue
			image = image.duplicate()
			if image.is_compressed() and image.decompress() != OK:
				continue
			if image.get_format() != Image.FORMAT_RGBA8:
				image.convert(Image.FORMAT_RGBA8)
			by_texture[texture] = images.size()
			images.append(image)
			sizes.append(image.get_size())
		sources.append(source)
		placement_of.append(by_texture[texture])
	if sources.is_empty():
		return
	var layout := TextureAtlas.plan(sizes)
	assert(layout["fits"], "the ground is %s, over the %dpx phone-safe canvas side"
			% [layout["size"], TextureAtlas.MAX_ATLAS_SIDE])
	if not layout["fits"]:
		return
	var regions: Array = layout["regions"]
	var atlas_size: Vector2i = layout["size"]
	var atlas := Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGBA8)
	for index in images.size():
		var image: Image = images[index]
		atlas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()),
				(regions[index] as Rect2i).position)
	var shared := ImageTexture.create_from_image(atlas)
	for index in sources.size():
		var source: TileSetAtlasSource = sources[index]
		source.texture = shared
		source.margins = (regions[placement_of[index]] as Rect2i).position
	Telemetry.note("texture", "ground packed: %d sources over %d pictures into %dx%d in %.1f ms"
			% [sources.size(), images.size(), atlas_size.x, atlas_size.y,
			(Time.get_ticks_usec() - started) / 1000.0])

## Returns the atlas coordinate selected for a ground cell. The source ID stays the map's own ID;
## grass and damage sources add visual-only atlas cells, so collision and semantic selection stay
## unchanged while their shared details can vary by city seed and coordinate.
static func atlas_coords_for(source_id: int, city_seed: int, tile: Vector2i,
		tile_set: TileSet) -> Vector2i:
	if source_id in [GRASS_SOURCE_ID, FOREST_SOURCE_ID]:
		var grass := tile_set.get_source(source_id) as TileSetAtlasSource
		# The question is whether the variation cells were actually created, asked of the source's
		# own tiles rather than of its texture's width: every source shares one packed texture, so
		# a width is the whole ground's and says nothing about this source at all.
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

static func _replace_svg_transfers(tile_set: TileSet) -> void:
	for source_index in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(source_index)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source != null:
			source.texture = TextureResolver.resolve(source.texture)

static func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(MANIFEST_PATH)) != OK:
		push_warning("Ignoring invalid ground layer manifest: %s" % MANIFEST_PATH)
		return {}
	var data: Variant = parser.data
	return data if data is Dictionary and int(data.get("version", 0)) == 1 else {}

static func _composed_texture(source_id: int, manifest: Dictionary) -> Texture2D:
	if source_id in [GRASS_SOURCE_ID, FOREST_SOURCE_ID]:
		return null
	return _layered_texture(source_id, manifest, false)

## Builds a kerb source's tinted route twin: the same base and the same rotated components
## `_composed_texture` would use, except the `curbstone` component is blended toward
## `Palette.ROUTE_KERB_TINT` before it is composited — so the paving, and on a main-road kerb the
## `main_edge_red` clearway line, are untouched and only the stone carries the cast.
static func _composed_route_kerb_texture(source_id: int, manifest: Dictionary) -> Texture2D:
	return _layered_texture(source_id, manifest, true)

## Shared by `_composed_texture` and `_composed_route_kerb_texture`: composes `source_id`'s base and
## rotated components, tinting the `curbstone` component first when `tint_curbstone` asks for it.
static func _layered_texture(source_id: int, manifest: Dictionary, tint_curbstone: bool) -> Texture2D:
	var source_bases: Dictionary = manifest.get("source_bases", {})
	var base_name: String = source_bases.get(str(source_id), "")
	if base_name.is_empty():
		return null
	var base := _base_image(base_name, manifest)
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
		var overlay := _component_image(component_name, manifest)
		if overlay == null:
			return null
		var rotated := rotate_clockwise(overlay, int(record.get("rotation_degrees", 0)))
		if rotated == null:
			return null
		if tint_curbstone and component_name == "curbstone":
			rotated = _tint_opaque(rotated)
		overlays.append(rotated)
	var composed := compose_image(base, overlays)
	return ImageTexture.create_from_image(composed) if composed != null else null

## Builds an SVG-mode kerb source's tinted route twin: the authored kerb raster
## (`assets/tiles/sidewalk_kerb*.svg`, already resolved onto `source_texture` by
## `_replace_svg_transfers`) with every pixel matching the curbstone's own fill,
## `SVG_KERB_STONE_COLOR`, blended toward `Palette.ROUTE_KERB_TINT` — the paving and, on a
## main-road kerb, the clearway line keep their own colour and are untouched.
static func _svg_route_kerb_texture(source_texture: Texture2D) -> Texture2D:
	var image := _texture_to_rgba_image(source_texture)
	if image == null or image.get_size() != TILE_SIZE:
		return null
	return ImageTexture.create_from_image(_tint_matching(image, SVG_KERB_STONE_COLOR))

## Registers each of `GroundTiles.ROUTE_KERB_SOURCES`' tinted twins on `tile_set`, at the id
## `GroundTiles.route_twin_of` gives its source — one small atlas source per twin, matching the
## plain kerb sources' own single-cell shape. A source with no registered twin id, or whose twin
## texture cannot be built (a missing manifest entry, an unreadable SVG), is left without one:
## `City._tint_the_route_kerbs()` already skips a tile whose twin does not exist, the same
## graceful fallback the rest of this file gives an incomplete art drop.
static func _register_route_kerb_twins(tile_set: TileSet, manifest: Dictionary) -> void:
	var svg_mode := TextureResolver.svg_requested()
	for source_id in GroundTiles.ROUTE_KERB_SOURCES:
		var twin_id := GroundTiles.route_twin_of(source_id)
		if twin_id < 0 or tile_set.has_source(twin_id):
			continue
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		var twin_texture: Texture2D = _svg_route_kerb_texture(source.texture) if svg_mode \
				else _composed_route_kerb_texture(source_id, manifest)
		if twin_texture == null:
			continue
		var twin := TileSetAtlasSource.new()
		twin.texture_region_size = TILE_SIZE
		twin.texture = twin_texture
		twin.create_tile(Vector2i.ZERO)
		tile_set.add_source(twin, twin_id)

## Composes every accepted stencil in the source's severity pool over its own semantic base.
## The source ID still tells GroundTiles which material and severity it placed; only the atlas cell
## is visual variation, so an unavailable pool leaves the authored SVG source untouched.
static func _damage_atlas(source_id: int, manifest: Dictionary) -> Texture2D:
	var source_bases: Dictionary = manifest.get("source_bases", {})
	var base := _base_image(str(source_bases.get(str(source_id), "")), manifest)
	var damage_types: Dictionary = manifest.get("source_damage_types", {})
	var damage_type: String = str(damage_types.get(str(source_id), ""))
	var pools: Dictionary = manifest.get("damage_pools", {})
	var pool: Array = pools.get(damage_type, [])
	if base == null or pool.size() != DAMAGE_VARIANTS:
		return null
	var atlas := Image.create(TILE_SIZE.x * DAMAGE_VARIANTS, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	for variant in DAMAGE_VARIANTS:
		var overlay := _component_image(str(pool[variant]), manifest)
		var composed := compose_image(base, [overlay]) if overlay != null else null
		if composed == null:
			return null
		atlas.blit_rect(composed, Rect2i(Vector2i.ZERO, TILE_SIZE), Vector2i(variant * TILE_SIZE.x, 0))
	return ImageTexture.create_from_image(atlas)

static func _grass_atlas(manifest: Dictionary) -> Texture2D:
	var base := _base_image("grass", manifest)
	if base == null:
		return null
	var feature_names: Array = manifest.get("grass_features", [])
	if feature_names.is_empty():
		return null
	var features: Array[Image] = []
	for feature_name_value in feature_names:
		var feature := _component_image(str(feature_name_value).trim_suffix(".png"), manifest)
		if feature == null:
			return null
		features.append(feature)
	var atlas := Image.create(TILE_SIZE.x * GRASS_VARIANTS, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	for variant in GRASS_VARIANTS:
		var tile := _grass_variant(base, features, variant)
		atlas.blit_rect(tile, Rect2i(Vector2i.ZERO, TILE_SIZE), Vector2i(variant * TILE_SIZE.x, 0))
	return ImageTexture.create_from_image(atlas)

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

static func _base_image(name: String, manifest: Dictionary) -> Image:
	var bases: Dictionary = manifest.get("bases", {})
	return _load_image(str(bases.get(name, "")))

static func _component_image(name: String, manifest: Dictionary) -> Image:
	var components: Dictionary = manifest.get("components", {})
	return _load_image(str(components.get(name, "")))

static func _load_image(filename: String) -> Image:
	if filename.is_empty():
		return null
	var path := MANIFEST_PATH.get_base_dir().path_join(filename)
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	if texture == null or texture.get_size() != Vector2(TILE_SIZE):
		return null
	return _texture_to_rgba_image(texture)

## Shared by `_load_image` and the SVG-mode route-kerb twin, which reads an already-loaded
## `TileSetAtlasSource.texture` rather than a manifest filename.
static func _texture_to_rgba_image(texture: Texture2D) -> Image:
	if texture == null:
		return null
	var image: Image = texture.get_image()
	if image == null:
		return null
	if image.is_compressed() and image.decompress() != OK:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image

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
## `Palette.ROUTE_KERB_TINT` by `Tuning.ROUTE_KERB_TINT_ALPHA`, keeping each pixel's own alpha. Used
## for an SVG-mode kerb raster, where the stone is identified by its own authored fill colour
## rather than a separate component image.
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
