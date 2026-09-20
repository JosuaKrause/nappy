extends RefCounted
## Pixel and TileSet contracts for the one-time ground layer compositor.
##
## **What the atlas owes is next door.** `tests/test_atlas_ground.gd` holds the contracts the
## baked page brought: the authored TileSet naming regions instead of pictures, one composed
## sheet, and every cell being the page composed by the manifest. This suite keeps the
## composition's own rules — what an empty overlay pixel may not do, which component belongs on
## which direction, how a variation cell is chosen, and the route tint landing on the stone alone.
##
## **The presentation mode is the bake's.** A default bake gives a page of illustrated components
## and the sources compose from them; `tools/bake-atlases.sh --svg` gives a page of whole authored
## tiles and only the route-kerb tint is composed. The checks below that only mean something under
## one of the two say so and stand down under the other, rather than forcing a mode that no longer
## exists at runtime.

const AUTHORED_GROUND: TileSet = preload("res://assets/ground_tileset.tres")
const MANIFEST_PATH := "res://assets/ground_layers.json"
## The region prefix a manifest component filename sits under — see
## `GroundLayers.LAYER_REGION_ROOT`, which applies the same one rule.
const LAYER_REGION_ROOT := "tiles/layers/"

func run(t) -> void:
	AtlasLibrary.reset_for_tests()
	_test_transparent_pixels_leave_the_base_unchanged(t)
	_test_component_rotation_is_clockwise(t)
	_test_sparse_grass_selection_is_stable_and_varied(t)
	_test_manifest_covers_the_authored_ground_sources(t)
	_test_directional_component_pairs_match_ground_tiles(t)
	_test_damage_pools_are_shared_without_changing_source_semantics(t)
	_test_damage_atlas_selection_is_stable_and_shared(t)
	_test_composed_sources_keep_ids_and_visible_detail(t)
	_test_the_grass_atlas_scatters_whole_features_over_one_base(t)
	_test_route_kerb_twin_tints_the_stone_alone(t)
	AtlasLibrary.reset_for_tests()

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
	# Every picture the recipe names has to be on the page now, or the source it belongs to falls
	# back to its whole authored tile without a word. A headless run cannot see that happen.
	var filenames: Array[String] = []
	for value in bases.values():
		filenames.append(str(value))
	for value in components.values():
		filenames.append(str(value))
	var unbaked: Array[String] = []
	for filename in filenames:
		var name := _region_name_of(filename)
		if not AtlasLibrary.has_region(name) \
				or AtlasLibrary.group_of(name) != GroundLayers.ATLAS_GROUP:
			unbaked.append(filename)
	t.check(unbaked.is_empty(), "every base and component the recipe names is on the '%s' page (%s)"
			% [GroundLayers.ATLAS_GROUP, ", ".join(unbaked.slice(0, 5))])
	t.check(filenames.size() > 20, "there were recipe pictures to look for (%d)" % filenames.size())

func _layer_manifest(t) -> Dictionary:
	var parser := JSON.new()
	t.check(parser.parse(FileAccess.get_file_as_string(MANIFEST_PATH)) == OK,
		"the runtime layer manifest parses before source selection uses it")
	return parser.data if parser.data is Dictionary else {}

func _test_composed_sources_keep_ids_and_visible_detail(t) -> void:
	if _svg_bake():
		return
	var page := _page(t)
	if page == null:
		return
	var composed := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var curbed := composed.get_source(8) as TileSetAtlasSource
	var base_image := _layer_image(page, "sidewalk_base.png")
	var detail_image := _layer_image(page, "curbstone.png")
	t.check(base_image != null and detail_image != null,
			"the sidewalk base and the curbstone are both regions of the ground page")
	if base_image == null or detail_image == null:
		return
	var curbed_image := _cell_image(curbed, Vector2i.ZERO)
	t.check(composed.get_source(8) == curbed and composed.get_source(39) != null,
			"compositing preserves every authored source ID used by GroundTiles")
	t.check(curbed_image.get_size() == GroundLayers.TILE_SIZE,
			"a composed ground source remains one native 32px tile")
	# Asked of the source's own tiles rather than of its texture's width: every source is laid into
	# one shared sheet, so a width is the whole ground's and says nothing about this source.
	var grass := composed.get_source(GroundLayers.GRASS_SOURCE_ID) as TileSetAtlasSource
	t.check(grass.has_tile(Vector2i(GroundLayers.GRASS_VARIANTS - 1, 0)),
			"a default bake installs the sparse grass variation atlas")
	var forest := composed.get_source(GroundLayers.FOREST_SOURCE_ID) as TileSetAtlasSource
	t.check(forest.has_tile(Vector2i(GroundLayers.GRASS_VARIANTS - 1, 0)),
			"a default bake gives forest the same sparse grass variation atlas")
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
		if damage == null:
			continue
		for variant in GroundLayers.DAMAGE_VARIANTS:
			t.check(damage.has_tile(Vector2i(variant, 0)),
					"damage source %d exposes atlas cell %d to TileMapLayer" % [source_id, variant])
		var base := _layer_image(page, str(source_bases.get(str(source_id), "")) + "_base.png")
		var pool: Array = pools.get(str(source_types.get(str(source_id), "")), [])
		if base == null or pool.size() != GroundLayers.DAMAGE_VARIANTS:
			t.check(false, "damage source %d's base and stencil pool are both on the page" % source_id)
			continue
		for variant in GroundLayers.DAMAGE_VARIANTS:
			var overlay := _layer_image(page, _components_filename(manifest, str(pool[variant])))
			if overlay == null:
				t.check(false, "damage stencil %s is on the page" % pool[variant])
				continue
			_check_damage_base_pixels(t, _cell_image(damage, Vector2i(variant, 0)), base, overlay,
					source_id, variant)

## The eight grass cells share one base and differ only where a feature was scattered, and every
## feature lands whole inside its own cell — the half `tests/test_atlas_ground.gd` cannot state,
## because the scatter is its own RNG rather than something the manifest says.
func _test_the_grass_atlas_scatters_whole_features_over_one_base(t) -> void:
	if _svg_bake():
		return
	var page := _page(t)
	if page == null:
		return
	var composed := GroundLayers.build_tile_set(AUTHORED_GROUND)
	var grass := composed.get_source(GroundLayers.GRASS_SOURCE_ID) as TileSetAtlasSource
	var base := _layer_image(page, "grass_base.png")
	t.check(grass != null and base != null, "the grass source and its base are both available")
	if grass == null or base == null:
		return
	var distinct: Dictionary = {}
	var plain := 0
	for variant in GroundLayers.GRASS_VARIANTS:
		if not grass.has_tile(Vector2i(variant, 0)):
			t.check(false, "the grass atlas has cell %d" % variant)
			continue
		var cell := _cell_image(grass, Vector2i(variant, 0))
		t.check(cell.get_size() == GroundLayers.TILE_SIZE,
				"grass cell %d is one native 32px tile" % variant)
		distinct[cell.get_data()] = true
		if cell.get_data() == base.get_data():
			plain += 1
	t.check(distinct.size() > 1, "the grass atlas is more than one repeated cell (%d distinct)"
			% distinct.size())
	t.check(plain > 0, "at least one grass cell is the bare base, so a feature is what differs")
	t.check(plain < GroundLayers.GRASS_VARIANTS,
			"not every grass cell is the bare base, so features are actually scattered")

func _test_damage_atlas_selection_is_stable_and_shared(t) -> void:
	var composed := GroundLayers.build_tile_set(AUTHORED_GROUND)
	if _svg_bake():
		# An SVG bake draws the authored damage tiles as they were drawn, one cell each, so there
		# is no shared variation to select between — the selector's own answer is then cell zero.
		t.check(GroundLayers.atlas_coords_for(40, 4242, Vector2i(3, 5), composed) == Vector2i.ZERO,
				"an SVG bake's damage source keeps its authored cell")
		return
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

## M145's correction: the twin tints the curbstone alone, never the paving beside it. Checked
## against `GroundTiles.SIDEWALK_KERB_N`, whose plain source puts the stone in a place each bake
## names differently — the `curbstone` component's own alpha in a default bake, the authored
## kerb's `y=0 height=2` band in an SVG bake.
func _test_route_kerb_twin_tints_the_stone_alone(t) -> void:
	var page := _page(t)
	if page == null:
		return
	var tint := Palette.ROUTE_KERB_TINT
	var source_id := GroundTiles.SIDEWALK_KERB_N
	var twin_id := GroundTiles.route_twin_of(source_id)
	t.check(twin_id >= 0, "GroundTiles registers a route-kerb twin id for the north kerb source")
	var composed := GroundLayers.build_tile_set(AUTHORED_GROUND)
	t.check(composed.has_source(twin_id), "the north kerb's route twin is registered")
	if not composed.has_source(twin_id):
		return
	var plain := _cell_image(composed.get_source(source_id) as TileSetAtlasSource, Vector2i.ZERO)
	var twin := _cell_image(composed.get_source(twin_id) as TileSetAtlasSource, Vector2i.ZERO)
	if _svg_bake():
		# `sidewalk_kerb_n.svg` fills `y=0 width=32 height=2` with the stone; row 20 is well inside
		# the paving the two internal slab-joint lines (`y=15`, `y=16..32` verticals) leave alone.
		t.check(_color_distance(twin.get_pixel(5, 0), tint)
				< _color_distance(plain.get_pixel(5, 0), tint),
				"the SVG bake's twin moved its curbstone-band pixel toward the tint")
		t.check(twin.get_pixel(5, 20) == plain.get_pixel(5, 20),
				"the SVG bake's twin leaves a paving pixel identical to the plain source's")
		return
	var detail := _layer_image(page, "curbstone.png")
	t.check(detail != null, "the curbstone component is a region of the ground page")
	if detail == null:
		return
	var stone_checked := false
	var paving_checked := false
	for y in GroundLayers.TILE_SIZE.y:
		for x in GroundLayers.TILE_SIZE.x:
			var plain_pixel := plain.get_pixel(x, y)
			var twin_pixel := twin.get_pixel(x, y)
			if detail.get_pixel(x, y).a > 0.01:
				stone_checked = true
				t.check(_color_distance(twin_pixel, tint) < _color_distance(plain_pixel, tint),
						"the twin's curbstone pixel at %s moved toward the tint" % Vector2i(x, y))
			else:
				paving_checked = true
				t.check(twin_pixel == plain_pixel,
						"the twin leaves a paving pixel at %s identical to the plain source's" % Vector2i(x, y))
	t.check(stone_checked and paving_checked,
			"the pixel sweep found both a curbstone and a paving pixel to check")

func _color_distance(a: Color, b: Color) -> float:
	return sqrt(pow(a.r - b.r, 2) + pow(a.g - b.g, 2) + pow(a.b - b.b, 2))

# ------------------------------------------------------------------ off the page ---

## Which bake the tree carries. There is no runtime override left to force the other one with: a
## page baked from the authored SVG rasters is what `tools/bake-atlases.sh --svg` writes, and the
## compositor reads that off the region table rather than off a flag.
func _svg_bake() -> bool:
	return AtlasLibrary.bake_mode() == "svg"

func _page(t) -> Image:
	var page := AtlasLibrary.page_image(GroundLayers.ATLAS_GROUP)
	t.check(page != null, "the baked ground page reads back as an image")
	return page

func _region_name_of(filename: String) -> StringName:
	return StringName(LAYER_REGION_ROOT + filename.trim_suffix(".png"))

## A manifest component, as a region of the page: `curbstone.png` is the picture baked under
## `tiles/layers/curbstone`, which is where the compositor takes it from too.
func _layer_image(page: Image, filename: String) -> Image:
	if filename.is_empty():
		return null
	var name := _region_name_of(filename)
	if not AtlasLibrary.has_region(name):
		return null
	var rect := AtlasLibrary.region_rect(name)
	if not rect.has_area() or not Rect2i(Vector2i.ZERO, page.get_size()).encloses(rect):
		return null
	var image := page.get_region(rect)
	return image if image.get_size() == GroundLayers.TILE_SIZE else null

## One cell's own pixels, wherever the upload put its source's picture in the shared sheet.
## `get_tile_texture_region()` is the engine's own answer to "where does cell (x,y) of this source
## live", built from `margins`, `texture_region_size` and `separation` — so reading through it is
## also what checks that the margin the upload wrote lands each coordinate on its own tile.
func _cell_image(source: TileSetAtlasSource, coords: Vector2i) -> Image:
	return source.texture.get_image().get_region(source.get_tile_texture_region(coords))
