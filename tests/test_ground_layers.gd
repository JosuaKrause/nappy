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
	var curbed_image := curbed.texture.get_image()
	t.check(composed.get_source(8) == curbed and composed.get_source(39) != null,
			"compositing preserves every authored source ID used by GroundTiles")
	t.check(curbed_image.get_size() == GroundLayers.TILE_SIZE,
			"a composed ground source remains one native 32px tile")
	var grass := composed.get_source(GroundLayers.GRASS_SOURCE_ID) as TileSetAtlasSource
	t.check(grass.texture.get_width() == GroundLayers.TILE_SIZE.x * GroundLayers.GRASS_VARIANTS,
			"PNG ground mode installs the sparse grass variation atlas")
	var forest := composed.get_source(GroundLayers.FOREST_SOURCE_ID) as TileSetAtlasSource
	t.check(forest.texture.get_width() == GroundLayers.TILE_SIZE.x * GroundLayers.GRASS_VARIANTS,
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
		var damage_image := damage.texture.get_image() if damage and damage.texture else null
		t.check(damage_image != null and damage_image.get_width() == GroundLayers.TILE_SIZE.x * GroundLayers.DAMAGE_VARIANTS,
				"damage source %d receives a six-cell shared-stencil atlas" % source_id)
		for variant in GroundLayers.DAMAGE_VARIANTS:
			t.check(damage.has_tile(Vector2i(variant, 0)),
					"damage source %d exposes atlas cell %d to TileMapLayer" % [source_id, variant])
		if damage_image == null:
			continue
		var base_name: String = str(source_bases.get(str(source_id), ""))
		var base_path: String = "res://assets/illustrated/svg-transfer/tiles/layers/%s_base.png" % base_name
		var base_texture: Texture2D = load(base_path) as Texture2D
		var pool: Array = pools.get(str(source_types.get(str(source_id), "")), [])
		for variant in GroundLayers.DAMAGE_VARIANTS:
			var overlay_path: String = "res://assets/illustrated/svg-transfer/tiles/layers/%s" % _components_filename(manifest, str(pool[variant]))
			var overlay_texture: Texture2D = load(overlay_path) as Texture2D
			_check_damage_base_pixels(t, damage_image, base_texture.get_image(), overlay_texture.get_image(), source_id, variant)

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

func _components_filename(manifest: Dictionary, component: String) -> String:
	var components: Dictionary = manifest.get("components", {})
	return str(components.get(component, ""))

func _check_damage_base_pixels(t, atlas: Image, base: Image, overlay: Image, source_id: int,
		variant: int) -> void:
	for y in GroundLayers.TILE_SIZE.y:
		for x in GroundLayers.TILE_SIZE.x:
			if overlay.get_pixel(x, y).a <= 0.01:
				t.check(atlas.get_pixel(x + variant * GroundLayers.TILE_SIZE.x, y) == base.get_pixel(x, y),
						"damage atlas %d cell %d preserves its semantic base outside the stencil at %s" % [source_id, variant, Vector2i(x, y)])

func _test_svg_override_and_repaint_source_are_idempotent(t) -> void:
	TextureResolver.reset_for_tests(true)
	var svg := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var svg_curb := svg.get_source(8) as TileSetAtlasSource
	t.check(svg_curb.texture.resource_path.ends_with("assets/tiles/sidewalk_kerb_n.svg"),
			"the SVG override retains the authored ground source without a PNG composite")
	var svg_damage := svg.get_source(40) as TileSetAtlasSource
	t.check(svg_damage.texture.resource_path.ends_with("assets/tiles/road_cracked_hairline_a.svg"),
			"the SVG override keeps the authored damage source instead of a shared PNG atlas")
	TextureResolver.reset_for_tests(false)
	var first := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var second := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var first_image := (first.get_source(8) as TileSetAtlasSource).texture.get_image()
	var second_image := (second.get_source(8) as TileSetAtlasSource).texture.get_image()
	t.check(first_image.get_data() == second_image.get_data(),
		"each repaint starts from authored ground, so layers cannot accumulate")
	TextureResolver.reset_for_tests(DevFlags.svg_requested())
