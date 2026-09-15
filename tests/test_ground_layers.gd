extends RefCounted
## Pixel and TileSet contracts for the one-time ground layer compositor.

const AUTHORED_GROUND: TileSet = preload("res://assets/ground_tileset.tres")
const CURBSTONE: Texture2D = preload("res://assets/illustrated/svg-transfer/tiles/layers/curbstone.png")
const SIDEWALK_BASE: Texture2D = preload("res://assets/illustrated/svg-transfer/tiles/layers/sidewalk_base.png")
const MANIFEST_PATH := "res://assets/illustrated/svg-transfer/tiles/layers/manifest.json"

func run(t) -> void:
	_test_transparent_pixels_leave_the_base_unchanged(t)
	_test_component_rotation_is_clockwise(t)
	_test_sparse_grass_selection_is_stable_and_varied(t)
	_test_manifest_covers_the_authored_ground_sources(t)
	_test_directional_component_pairs_match_ground_tiles(t)
	_test_damage_pools_are_shared_without_changing_source_semantics(t)
	_test_damage_atlas_selection_is_stable_and_shared(t)
	_test_composed_sources_keep_ids_and_visible_detail(t)
	_test_svg_override_and_repaint_source_are_idempotent(t)
	_test_route_kerb_twin_tints_the_stone_alone(t)
	_test_every_source_shares_one_texture_and_keeps_its_tiles(t)

func _test_transparent_pixels_leave_the_base_unchanged(t) -> void:
	var base := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	base.fill(Color("426a4c"))
	var overlay := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	overlay.set_pixel(2, 1, Color("d9b24c"))
	var composed := GroundLayers.compose_image(base, [overlay])
	for y in range(4):
		for x in range(4):
			if x != 2 or y != 1:
				t.check(composed.get_pixel(x, y) == base.get_pixel(x, y),
						"an empty overlay pixel preserves the shared base at %s" % Vector2i(x, y))
	t.check(composed.get_pixel(2, 1) == Color("d9b24c"),
			"a visible overlay pixel composites over the base")

func _test_component_rotation_is_clockwise(t) -> void:
	var source := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	source.set_pixel(0, 0, Color.WHITE)
	var rotated := GroundLayers.rotate_clockwise(source, 90)
	t.check(rotated.get_pixel(2, 0) == Color.WHITE,
			"a 90-degree layer declaration rotates its mark clockwise")
	t.check(GroundLayers.rotate_clockwise(source, 45) == null,
			"a non-right-angle layer declaration falls back instead of distorting the marking")

func _test_sparse_grass_selection_is_stable_and_varied(t) -> void:
	var tile_set := TileSet.new()
	var grass := TileSetAtlasSource.new()
	grass.texture_region_size = GroundLayers.TILE_SIZE
	var image := Image.create(GroundLayers.TILE_SIZE.x * GroundLayers.GRASS_VARIANTS,
			GroundLayers.TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	grass.texture = ImageTexture.create_from_image(image)
	for variant in GroundLayers.GRASS_VARIANTS:
		grass.create_tile(Vector2i(variant, 0))
	tile_set.add_source(grass, GroundLayers.GRASS_SOURCE_ID)
	var first := GroundLayers.atlas_coords_for(GroundLayers.GRASS_SOURCE_ID, 4242, Vector2i(3, 5), tile_set)
	var second := GroundLayers.atlas_coords_for(GroundLayers.GRASS_SOURCE_ID, 4242, Vector2i(3, 5), tile_set)
	t.check(first == second, "the same city seed and grass coordinate select the same atlas cell")
	var seen: Dictionary = {}
	for x in range(16):
		seen[GroundLayers.atlas_coords_for(GroundLayers.GRASS_SOURCE_ID, 4242, Vector2i(x, 5), tile_set)] = true
	t.check(seen.size() > 1, "nearby grass cells use more than one sparse feature variation")
	t.check(GroundLayers.atlas_coords_for(0, 4242, Vector2i(3, 5), tile_set) == Vector2i.ZERO,
			"non-grass sources retain their authored atlas coordinate")

func _test_damage_pools_are_shared_without_changing_source_semantics(t) -> void:
	var manifest := _layer_manifest(t)
	if manifest.is_empty():
		return
	var components: Dictionary = manifest.get("components", {})
	var pools: Dictionary = manifest.get("damage_pools", {})
	for damage_type in ["hairline", "cracked", "broken"]:
		var pool: Array = pools.get(damage_type, [])
		t.check(pool.size() == GroundLayers.DAMAGE_VARIANTS,
				"the shared %s pool retains all six accepted stencils" % damage_type)
		var provenance: Dictionary = {}
		for component_value in pool:
			var component: String = str(component_value)
			provenance[component.get_slice("_", 0)] = true
			t.check(components.has(component),
					"the shared %s pool names a published transparent component" % damage_type)
		t.check(provenance.has_all(["road", "sidewalk", "alley"]),
				"the shared %s pool makes every accepted surface drawing available on every base" % damage_type)
	var source_types: Dictionary = manifest.get("source_damage_types", {})
	var source_layers: Dictionary = manifest.get("source_layers", {})
	for first_source in [40, 46, 52]:
		for offset in range(6):
			var source_id: int = int(first_source) + offset
			var expected: String = ["hairline", "hairline", "cracked", "cracked", "broken", "broken"][offset]
			t.check(str(source_types.get(str(source_id), "")) == expected,
					"damage source %d retains its authored severity and A/B gameplay slot" % source_id)
			t.check(not source_layers.has(str(source_id)),
					"damage source %d selects a shared pool instead of a surface-bound layer" % source_id)
			t.check(AUTHORED_GROUND.get_source(source_id) != null,
					"damage source %d remains an authored GroundTiles source" % source_id)

func _test_directional_component_pairs_match_ground_tiles(t) -> void:
	var manifest := _layer_manifest(t)
	if manifest.is_empty():
		return
	var source_layers: Dictionary = manifest.get("source_layers", {})
	_check_directional_layers(t, source_layers, {
		8: ["curbstone", 0], 9: ["curbstone", 180],
		10: ["curbstone", 90], 11: ["curbstone", 270],
		26: ["curbstone", 0], 27: ["curbstone", 180],
		28: ["curbstone", 90], 29: ["curbstone", 270],
		1: ["yellow_half_line", 90], 2: ["yellow_half_line", 270],
		3: ["yellow_half_line", 0], 4: ["yellow_half_line", 180],
		22: ["yellow_main_line", 90], 23: ["yellow_main_line", 270],
		24: ["yellow_main_line", 0], 25: ["yellow_main_line", 180],
		5: ["crosswalk", 90], 6: ["crosswalk", 0],
		36: ["main_crosswalk", 0], 37: ["main_crosswalk", 180],
		38: ["main_crosswalk", 270], 39: ["main_crosswalk", 90],
	})

func _check_directional_layers(t, source_layers: Dictionary, expected: Dictionary) -> void:
	for source_id_value in expected:
		var source_id: int = source_id_value
		var contract: Array = expected[source_id]
		var layers: Array = source_layers.get(str(source_id), [])
		var component: String = ""
		var rotation := -1
		if not layers.is_empty() and layers[0] is Dictionary:
			var layer: Dictionary = layers[0]
			component = str(layer.get("component", ""))
			rotation = int(layer.get("rotation_degrees", -1))
		t.check(component == contract[0] and rotation == contract[1],
			"source %d has its GroundTiles direction and component rotation" % source_id)

func _test_manifest_covers_the_authored_ground_sources(t) -> void:
	var manifest := _layer_manifest(t)
	if manifest.is_empty():
		return
	var bases: Dictionary = manifest.get("bases", {})
	var source_bases: Dictionary = manifest.get("source_bases", {})
	var components: Dictionary = manifest.get("components", {})
	var source_layers: Dictionary = manifest.get("source_layers", {})
	for source_key_value in source_bases:
		var source_key: String = str(source_key_value)
		var source_id := int(source_key)
		var base_name: String = str(source_bases[source_key])
		t.check(AUTHORED_GROUND.get_source(source_id) != null,
			"layer manifest source %d remains a real authored TileSet source" % source_id)
		t.check(bases.has(base_name), "source %d names a declared shared base" % source_id)
	for source_key_value in source_layers:
		var source_key: String = str(source_key_value)
		var layers: Array = source_layers[source_key]
		for layer_value in layers:
			if layer_value is Dictionary:
				var component: String = str((layer_value as Dictionary).get("component", ""))
				t.check(components.has(component),
						"source %s names a declared transparent component" % source_key)
	var grass_features: Array = manifest.get("grass_features", [])
	for feature_value in grass_features:
		var feature_name: String = str(feature_value).trim_suffix(".png")
		t.check(components.has(feature_name),
			"grass feature %s names a declared transparent component" % feature_value)

func _layer_manifest(t) -> Dictionary:
	var parser := JSON.new()
	t.check(parser.parse(FileAccess.get_file_as_string(MANIFEST_PATH)) == OK,
		"the runtime layer manifest parses before source selection uses it")
	return parser.data if parser.data is Dictionary else {}

func _test_composed_sources_keep_ids_and_visible_detail(t) -> void:
	TextureResolver.reset_for_tests(false)
	var composed := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var curbed := composed.get_source(8) as TileSetAtlasSource
	var base_image := SIDEWALK_BASE.get_image()
	var detail_image := CURBSTONE.get_image()
	var curbed_image := _tile_image(curbed, Vector2i.ZERO)
	t.check(composed.get_source(8) == curbed and composed.get_source(39) != null,
			"compositing preserves every authored source ID used by GroundTiles")
	t.check(curbed_image.get_size() == GroundLayers.TILE_SIZE,
			"a composed ground source remains one native 32px tile")
	# Asked of the source's own tiles rather than of its texture's width: every source is packed
	# into one shared texture, so a width is the whole ground's and says nothing about this source.
	var grass := composed.get_source(GroundLayers.GRASS_SOURCE_ID) as TileSetAtlasSource
	t.check(grass.has_tile(Vector2i(GroundLayers.GRASS_VARIANTS - 1, 0)),
			"PNG ground mode installs the sparse grass variation atlas")
	var forest := composed.get_source(GroundLayers.FOREST_SOURCE_ID) as TileSetAtlasSource
	t.check(forest.has_tile(Vector2i(GroundLayers.GRASS_VARIANTS - 1, 0)),
			"PNG ground mode gives forest the same sparse grass variation atlas")
	var visible := false
	for y in GroundLayers.TILE_SIZE.y:
		for x in GroundLayers.TILE_SIZE.x:
			if detail_image.get_pixel(x, y).a > 0.01:
				visible = visible or curbed_image.get_pixel(x, y) != base_image.get_pixel(x, y)
			else:
				t.check(curbed_image.get_pixel(x, y) == base_image.get_pixel(x, y),
						"curbstone transparency leaves sidewalk base intact at %s" % Vector2i(x, y))
	t.check(visible, "the curbstone component remains visible in the engine-composed source")
	var manifest := _layer_manifest(t)
	var source_bases: Dictionary = manifest.get("source_bases", {})
	var pools: Dictionary = manifest.get("damage_pools", {})
	var source_types: Dictionary = manifest.get("source_damage_types", {})
	for source_id in [40, 46, 52]:
		var damage := composed.get_source(source_id) as TileSetAtlasSource
		t.check(damage != null and damage.has_tile(Vector2i(GroundLayers.DAMAGE_VARIANTS - 1, 0)),
				"damage source %d receives a six-cell shared-stencil atlas" % source_id)
		for variant in GroundLayers.DAMAGE_VARIANTS:
			t.check(damage.has_tile(Vector2i(variant, 0)),
					"damage source %d exposes atlas cell %d to TileMapLayer" % [source_id, variant])
		if damage == null:
			continue
		var base_name: String = str(source_bases.get(str(source_id), ""))
		var base_path: String = "res://assets/illustrated/svg-transfer/tiles/layers/%s_base.png" % base_name
		var base_texture: Texture2D = load(base_path) as Texture2D
		var pool: Array = pools.get(str(source_types.get(str(source_id), "")), [])
		for variant in GroundLayers.DAMAGE_VARIANTS:
			var overlay_path: String = "res://assets/illustrated/svg-transfer/tiles/layers/%s" % _components_filename(manifest, str(pool[variant]))
			var overlay_texture: Texture2D = load(overlay_path) as Texture2D
			_check_damage_base_pixels(t, _tile_image(damage, Vector2i(variant, 0)),
					base_texture.get_image(), overlay_texture.get_image(), source_id, variant)

func _test_damage_atlas_selection_is_stable_and_shared(t) -> void:
	TextureResolver.reset_for_tests(false)
	var composed := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var tile := Vector2i(3, 5)
	var road := GroundLayers.atlas_coords_for(40, 4242, tile, composed)
	t.check(road == GroundLayers.atlas_coords_for(40, 4242, tile, composed),
			"the same city seed and damage coordinate select the same shared atlas cell")
	for source_id in [46, 52]:
		t.check(road == GroundLayers.atlas_coords_for(source_id, 4242, tile, composed),
				"one seed and coordinate select the same shared variation regardless of its material")
	var seen: Dictionary = {}
	for x in range(16):
		var coords := GroundLayers.atlas_coords_for(40, 4242, Vector2i(x, 5), composed)
		seen[coords] = true
		t.check(coords.x >= 0 and coords.x < GroundLayers.DAMAGE_VARIANTS and coords.y == 0,
				"damage source 40 selects an atlas coordinate within its six available cells")
	t.check(seen.size() > 1, "nearby damage cells use more than one shared stencil variation")
	TextureResolver.reset_for_tests(DevFlags.svg_requested())

## One tile's own pixels, wherever the packing pass put its source's picture in the shared
## texture. `get_tile_texture_region()` is the engine's own answer to "where does cell (x,y) of
## this source live", built from `margins`, `texture_region_size` and `separation` — so reading
## through it is also what checks that the margin the pack wrote actually lands each coordinate on
## its own tile.
func _tile_image(source: TileSetAtlasSource, coords: Vector2i) -> Image:
	return source.texture.get_image().get_region(source.get_tile_texture_region(coords))

## The authored raster at `path`, converted the way the packing pass converts everything, so a
## pixel comparison is against what was blitted rather than against a format that disagrees on
## channel layout.
func _authored_pixels(path: String) -> PackedByteArray:
	var texture: Texture2D = load(path)
	var image := texture.get_image().duplicate()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image.get_data()

## The ground is one image source at draw time, in both presentation modes, and every tile
## coordinate still lands on its own tile: the margin moved and `texture_region_size` and
## `separation` did not. *(Playtest 76: "it is good to have everything built into atlases so the
## composite doesn't have to deal with multiple image sources.")*
##
## Each source's cell (0,0) is checked against the picture it had before the pack, which is the
## pixel-for-pixel half — an unpacked build of the same TileSet is the reference, since the
## composition that fed it differs by mode and by manifest.
func _test_every_source_shares_one_texture_and_keeps_its_tiles(t) -> void:
	for svg in [false, true]:
		TextureResolver.reset_for_tests(svg)
		var label := "forced SVG rasters" if svg else "default PNG transfers"
		var packed := GroundLayers.build_tile_set(AUTHORED_GROUND)
		var reference := _unpacked_tile_set(svg)
		var shared: Texture2D = null
		var seen := 0
		for index in packed.get_source_count():
			var id := packed.get_source_id(index)
			var source := packed.get_source(id) as TileSetAtlasSource
			var before := reference.get_source(id) as TileSetAtlasSource
			if source == null or source.texture == null or before == null:
				continue
			seen += 1
			if shared == null:
				shared = source.texture
			t.check(source.texture == shared,
					"%s: source %d draws from the one shared ground texture" % [label, id])
			t.check(source.texture_region_size == before.texture_region_size,
					"%s: source %d keeps its authored tile size (%s against %s)"
					% [label, id, source.texture_region_size, before.texture_region_size])
			t.check(source.separation == before.separation,
					"%s: source %d keeps its authored separation" % [label, id])
			t.check(source.get_tiles_count() == before.get_tiles_count(),
					"%s: source %d keeps every tile it had (%d against %d)"
					% [label, id, source.get_tiles_count(), before.get_tiles_count()])
			for tile in before.get_tiles_count():
				var coords := before.get_tile_id(tile)
				t.check(source.has_tile(coords),
						"%s: source %d still has cell %s" % [label, id, coords])
				if not source.has_tile(coords):
					continue
				t.check(_tile_image(source, coords).get_data()
						== _tile_image(before, coords).get_data(),
						"%s: source %d cell %s is the same picture it was before the pack"
						% [label, id, coords])
		t.check(seen > 20, "%s: there were sources to ask about (%d)" % [label, seen])
		t.check(shared != null and Vector2i(shared.get_size()).x <= TextureAtlas.MAX_ATLAS_SIDE
				and Vector2i(shared.get_size()).y <= TextureAtlas.MAX_ATLAS_SIDE,
				"%s: the ground fits the %dpx phone-safe side (%s)"
				% [label, TextureAtlas.MAX_ATLAS_SIDE, shared.get_size() if shared else Vector2.ZERO])
	TextureResolver.reset_for_tests(DevFlags.svg_requested())

## The same TileSet `build_tile_set()` would return with the packing pass left off — the
## reference every "unchanged by the pack" comparison above is made against.
func _unpacked_tile_set(svg: bool) -> TileSet:
	var result := AUTHORED_GROUND.duplicate(true) as TileSet
	for index in result.get_source_count():
		var source := result.get_source(result.get_source_id(index)) as TileSetAtlasSource
		if source != null:
			source.texture = TextureResolver.resolve(source.texture)
	if not svg:
		GroundLayers._compose_layers(result)
	return result

func _components_filename(manifest: Dictionary, component: String) -> String:
	var components: Dictionary = manifest.get("components", {})
	return str(components.get(component, ""))

func _check_damage_base_pixels(t, cell: Image, base: Image, overlay: Image, source_id: int,
		variant: int) -> void:
	for y in GroundLayers.TILE_SIZE.y:
		for x in GroundLayers.TILE_SIZE.x:
			if overlay.get_pixel(x, y).a <= 0.01:
				t.check(cell.get_pixel(x, y) == base.get_pixel(x, y),
						"damage atlas %d cell %d preserves its semantic base outside the stencil at %s" % [source_id, variant, Vector2i(x, y)])

func _test_svg_override_and_repaint_source_are_idempotent(t) -> void:
	TextureResolver.reset_for_tests(true)
	var svg := GroundLayers.build_tile_set(AUTHORED_GROUND)
	# Asserted against the authored raster's own pixels rather than against a `resource_path`:
	# every source is packed into one shared `ImageTexture`, which has no path, and the picture
	# is the thing the override is actually about.
	var svg_curb := svg.get_source(8) as TileSetAtlasSource
	t.check(_tile_image(svg_curb, Vector2i.ZERO).get_data()
			== _authored_pixels("res://assets/tiles/sidewalk_kerb_n.svg"),
			"the SVG override retains the authored ground source without a PNG composite")
	var svg_damage := svg.get_source(40) as TileSetAtlasSource
	t.check(_tile_image(svg_damage, Vector2i.ZERO).get_data()
			== _authored_pixels("res://assets/tiles/road_cracked_hairline_a.svg"),
			"the SVG override keeps the authored damage source instead of a shared PNG atlas")
	TextureResolver.reset_for_tests(false)
	var first := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var second := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var first_image := (first.get_source(8) as TileSetAtlasSource).texture.get_image()
	var second_image := (second.get_source(8) as TileSetAtlasSource).texture.get_image()
	t.check(first_image.get_data() == second_image.get_data(),
		"each repaint starts from authored ground, so layers cannot accumulate")
	TextureResolver.reset_for_tests(DevFlags.svg_requested())

## M145's correction: the twin tints the curbstone alone, in both presentations, never the paving
## beside it. Checked against `GroundTiles.SIDEWALK_KERB_N` in each mode, since its plain source's
## own image is what both `CURBSTONE` (PNG) and the authored SVG (SVG) put the stone in a known
## place: rows 0-2 of `curbstone.png` and `y=0 height=2` of `assets/tiles/sidewalk_kerb_n.svg`.
## A source's own first tile as an image. After `GroundLayers.pack_into_one_texture()` every
## source's `texture` is the shared sheet, so a pixel read from the texture's origin is some other
## source's pixel; the source's tile region, which carries its `margins`, is the picture it owns.
static func _own_tile_image(source: TileSetAtlasSource) -> Image:
	return source.texture.get_image().get_region(source.get_tile_texture_region(Vector2i.ZERO))

func _test_route_kerb_twin_tints_the_stone_alone(t) -> void:
	var tint := Palette.ROUTE_KERB_TINT
	var source_id := GroundTiles.SIDEWALK_KERB_N
	var twin_id := GroundTiles.route_twin_of(source_id)
	t.check(twin_id >= 0, "GroundTiles registers a route-kerb twin id for the north kerb source")

	TextureResolver.reset_for_tests(false)
	var png_set := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var plain_png := _own_tile_image(png_set.get_source(source_id) as TileSetAtlasSource)
	var twin_png_source := png_set.get_source(twin_id) as TileSetAtlasSource
	t.check(twin_png_source != null, "PNG mode registers the north kerb's route twin")
	var twin_png := _own_tile_image(twin_png_source)
	var detail := CURBSTONE.get_image()
	var stone_checked := false
	var paving_checked := false
	for y in GroundLayers.TILE_SIZE.y:
		for x in GroundLayers.TILE_SIZE.x:
			var plain_pixel := plain_png.get_pixel(x, y)
			var twin_pixel := twin_png.get_pixel(x, y)
			if detail.get_pixel(x, y).a > 0.01:
				stone_checked = true
				t.check(_color_distance(twin_pixel, tint) < _color_distance(plain_pixel, tint),
						"the PNG twin's curbstone pixel at %s moved toward the tint" % Vector2i(x, y))
			else:
				paving_checked = true
				t.check(twin_pixel == plain_pixel,
						"the PNG twin leaves a paving pixel at %s identical to the plain source's" % Vector2i(x, y))
	t.check(stone_checked and paving_checked,
			"the PNG pixel sweep found both a curbstone and a paving pixel to check")

	TextureResolver.reset_for_tests(true)
	var svg_set := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var plain_svg := _own_tile_image(svg_set.get_source(source_id) as TileSetAtlasSource)
	var twin_svg_source := svg_set.get_source(twin_id) as TileSetAtlasSource
	t.check(twin_svg_source != null, "SVG mode registers the north kerb's route twin")
	var twin_svg := _own_tile_image(twin_svg_source)
	# `sidewalk_kerb_n.svg` fills `y=0 width=32 height=2` with the stone; row 20 is well inside the
	# paving the two internal slab-joint lines (`y=15`, `y=16..32` verticals) leave alone.
	var stone_plain := plain_svg.get_pixel(5, 0)
	var stone_twin := twin_svg.get_pixel(5, 0)
	t.check(_color_distance(stone_twin, tint) < _color_distance(stone_plain, tint),
			"the SVG twin's curbstone-band pixel moved toward the tint")
	t.check(twin_svg.get_pixel(5, 20) == plain_svg.get_pixel(5, 20),
			"the SVG twin leaves a paving pixel identical to the plain source's")

	TextureResolver.reset_for_tests(DevFlags.svg_requested())

func _color_distance(a: Color, b: Color) -> float:
	return sqrt(pow(a.r - b.r, 2) + pow(a.g - b.g, 2) + pow(a.b - b.b, 2))
