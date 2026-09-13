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

## Duplicates `authored` before replacing its SVG transfers and composing the available layer set.
## A malformed or incomplete layer set leaves that source on the resolver's normal PNG/SVG fallback;
## an unfinished transfer therefore cannot erase a marking or change the TileSet's geometry.
static func build_tile_set(authored: TileSet) -> TileSet:
	if authored == null:
		return null
	var result := authored.duplicate(true) as TileSet
	_replace_svg_transfers(result)
	if TextureResolver.svg_requested():
		return result
	var manifest := _load_manifest()
	if manifest.is_empty() or int(manifest.get("tile_size", 0)) != TILE_SIZE.x:
		return result
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
	return result

## Returns the atlas coordinate selected for a ground cell. The source ID stays the map's own ID;
## grass and damage sources add visual-only atlas cells, so collision and semantic selection stay
## unchanged while their shared details can vary by city seed and coordinate.
static func atlas_coords_for(source_id: int, city_seed: int, tile: Vector2i,
		tile_set: TileSet) -> Vector2i:
	if source_id in [GRASS_SOURCE_ID, FOREST_SOURCE_ID]:
		var grass := tile_set.get_source(source_id) as TileSetAtlasSource
		if grass == null or grass.texture == null or grass.texture.get_width() < TILE_SIZE.x * 2:
			return Vector2i.ZERO
		return Vector2i(posmod(hash("grass:%d:%d:%d" % [city_seed, tile.x, tile.y]), GRASS_VARIANTS), 0)
	if source_id in DAMAGE_SOURCE_IDS:
		var damage := tile_set.get_source(source_id) as TileSetAtlasSource
		if damage == null or damage.texture == null or damage.texture.get_width() < TILE_SIZE.x * DAMAGE_VARIANTS \
				or not damage.has_tile(Vector2i(DAMAGE_VARIANTS - 1, 0)):
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
		overlays.append(rotated)
	var composed := compose_image(base, overlays)
	return ImageTexture.create_from_image(composed) if composed != null else null

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
	var image: Image = texture.get_image()
	if image == null:
		return null
	if image.is_compressed() and image.decompress() != OK:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image
