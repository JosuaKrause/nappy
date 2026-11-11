extends RefCounted
## M171, "The unatlased leaf consumers": buildings, the street kit (the city edge, closure
## markers, traffic lights), the UI (`ModeButton`, `TouchControls`, `SaveIndicator`) and the
## interior (`InteriorScene`, `InteriorTileSet`) each draw from `AtlasLibrary` regions now instead
## of a `preload`ed texture. Two things a headless `check.sh`/`test.sh` boot cannot see on its own,
## because a headless draw pass makes no pixels (see the **verify** skill): a region name a
## consumer's drawing code holds a literal for that the bake never actually wrote, which would sit
## silent until somebody looked at a screenshot; and a group a freed consumer leaves acquired
## forever, which nothing else would ever notice either. This suite checks both, plus that every
## consumer sharing a group counts references rather than loading a second page — each check on a
## library of its own that it hands every consumer it builds, as the city and `main` hand theirs,
## and each lifetime read off the run log's load and release lines for the page
## (`tests/atlas_page_log.gd`): one load however many consumers share it, and one release, once the
## last of them is gone.

const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")
const BakedRegions := preload("res://tests/baked_regions.gd")
const PageLog := preload("res://tests/atlas_page_log.gd")

func run(t: TestRunner) -> void:
	_test_every_building_region_is_baked_on_its_group(t)
	_test_building_acquires_and_releases_buildings(t)
	_test_every_street_kit_region_is_baked_on_its_group(t)
	_test_street_kit_consumers_share_one_reference_count(t)
	_test_each_street_kit_consumer_holds_its_own_reference(t)
	_test_city_edge_also_holds_ground(t)
	_test_every_ui_region_is_baked_on_its_group(t)
	_test_ui_consumers_share_one_reference_count(t)
	_test_each_ui_consumer_holds_its_own_reference(t)
	_test_every_interior_region_is_baked_on_its_group(t)
	_test_interior_tileset_regions_are_baked_on_the_interior_group(t)
	_test_interior_scene_acquires_and_releases_interior(t)

# ------------------------------------------------------------------ helpers ---

## Every name in `names` is a region the bake actually wrote, and every one of them is on
## `group` — read off the bake's own table for every name a consumer can ask for, not only the ones
## a drawn frame happens to reach, and a region on the wrong group would still draw in any frame
## where that other group happened to be acquired.
func _check_regions(t: TestRunner, names: Array, group: StringName, label: String) -> void:
	var missing: Array[String] = []
	var misfiled: Array[String] = []
	for entry: Variant in names:
		var name := entry as StringName
		if not AtlasTable.baked().has_region(name):
			missing.append(String(name))
		elif AtlasTable.baked().group_of(name) != group:
			misfiled.append(String(name))
	t.check(missing.is_empty(), "%s: every region name resolves (missing %s)"
			% [label, ", ".join(missing.slice(0, 5))])
	t.check(misfiled.is_empty(), "%s: every region is on the '%s' group (%s)"
			% [label, group, ", ".join(misfiled.slice(0, 5))])
	t.check(names.size() > 0, "%s: there were names to check at all (%d)" % [label, names.size()])

# ------------------------------------------------------------------ buildings ---

func _test_every_building_region_is_baked_on_its_group(t: TestRunner) -> void:
	var names: Array = [
		Building.WALL, Building.WALL_BASE, Building.WALL_EDGE_W, Building.WALL_EDGE_E,
		Building.ROOF, Building.ROOF_EDGE_N, Building.ROOF_EDGE_S, Building.ROOF_EDGE_W,
		Building.ROOF_EDGE_E, Building.WINDOW_DARK, Building.WINDOW_LIT,
		Building.WINDOW_TALL_DARK, Building.WINDOW_TALL_LIT, Building.WINDOW_SHUTTERED_DARK,
		Building.WINDOW_SHUTTERED_LIT, Building.FIRE_ESCAPE_A, Building.FIRE_ESCAPE_B,
		Building.CIVIC_PORTICO, Building.VENT_HOUSING, Building.VENT_ROTOR,
		Building.VENT_ROTOR_B, Building.HVAC_A, Building.HVAC_B,
		Building.DUCT_RUN, Building.SKYLIGHT_A, Building.SKYLIGHT_B, Building.VENT_STACK,
		Building.WATER_TANK, Building.SERVICE_BULKHEAD, Building.EXHAUST_FAN,
		Building.PIPE_MANIFOLD,
	]
	names.append_array(Building.STOREFRONT_TEXTURES)
	names.append_array(Building.STOREFRONT_AWNING_TEXTURES)
	names.append_array(Building.STOREFRONT_SHUTTERED_TEXTURES)
	names.append_array([Building.WINDOW_BURNT, Building.ENTRANCE_DOOR_BURNT,
			Building.STOREFRONT_BURNT])
	names.append_array(Building.ROOF_EDGE_S_BURNT)
	# The posters a building's wall carries, every picture `PosterArt` can hand it.
	names.append_array(PosterArt.SHEETS.values())
	names.append(PosterArt.WANTED_CROSSED)
	names.append_array(PosterArt.TEAR_MASKS)
	names.append_array(PosterArt.TEAR_OVERLAYS)
	_check_regions(t, names, &"buildings", "Building")

## Acquired the moment a building enters the tree, shared by reference count rather than a page
## per building, and released only once the last one is gone.
func _test_building_acquires_and_releases_buildings(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var a := Building.new()
	a.atlas = atlas
	t.add_child(a)
	t.check(pages.held(&"buildings"), "the first building takes the page")
	var b := Building.new()
	b.atlas = atlas
	t.add_child(b)
	t.check(pages.loads(&"buildings") == 1,
			"a second building shares the page rather than reading a second one")
	a.free()
	t.check(pages.releases(&"buildings") == 0,
			"freeing one building leaves the page to the other")
	b.free()
	t.check(pages.releases(&"buildings") == 1,
			"freeing the last building releases the group, with no reference left over")
	pages.stop()

# ---------------------------------------------------------------- street kit ---

func _test_every_street_kit_region_is_baked_on_its_group(t: TestRunner) -> void:
	var names: Array = [
		ClosureMarker.FENCE_ACROSS, ClosureMarker.FENCE_ALONG, ClosureMarker.SIGN,
		ClosureMarker.POST,
		ParkFenceMarker.RAIL_ALONG, ParkFenceMarker.JOINT, ParkFenceMarker.MOUNTED_SIGN,
		TrafficLight.HEAD, TrafficLight.HEAD_BACK, TrafficLight.HEAD_SIDE,
		CityEdge.TUNNEL, CityEdge.BRIDGE, CityEdge.ROAD_ON,
	]
	names.append_array(ClosureMarker.CAUSES.values())
	names.append_array(ClosureMarker.CAUSES_VERTICAL.values())
	_check_regions(t, names, &"street_kit", "the street kit")
	t.check(AtlasTable.baked().group_of(CityEdge.MOUNTAIN) == &"ground",
			"the city edge's mountain tile is on the ground page, not street_kit")

## `ClosureMarker`, `TrafficLight`, `CityEdge`, `ParkFenceMarker` and `CordonTape` each acquire
## `street_kit` independently, from different files, and the group still counts references rather
## than loading five pages.
##
## Which consumers share it is this test; that each of them takes a reference of its own is
## `_test_each_street_kit_consumer_holds_its_own_reference`, since a release line comes only when
## the count reaches zero and a consumer that took none would go unseen here unless it were freed
## last.
func _test_street_kit_consumers_share_one_reference_count(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var marker := ClosureMarker.new()
	marker.atlas = atlas
	t.add_child(marker)
	t.check(pages.held(&"street_kit"), "the closure marker takes the page")
	var light := TrafficLight.new()
	light.atlas = atlas
	t.add_child(light)
	var edge := CityEdge.new()
	edge.atlas = atlas
	t.add_child(edge)
	var park := ParkFenceMarker.new()
	park.atlas = atlas
	t.add_child(park)
	var tape := CordonTape.new()
	tape.use_atlas(atlas)
	t.add_child(tape)
	t.check(pages.loads(&"street_kit") == 1,
			"the traffic light, the city edge, the park fence and the cordon tape share the same "
			+ "page rather than reading a second")
	park.free()
	marker.free()
	light.free()
	tape.free()
	t.check(pages.releases(&"street_kit") == 0,
			"freeing four of the five leaves the page to the one that remains")
	edge.free()
	t.check(pages.releases(&"street_kit") == 1,
			"freeing every street-kit consumer releases the group, with nothing left over")
	pages.stop()

## Each street-kit consumer, alone on a library of its own, takes the page when it enters the tree
## and gives it back when it leaves: one load, held, then exactly one release. A consumer that took
## no reference, and drew on a page somebody else held, is held by nothing here and fails.
func _test_each_street_kit_consumer_holds_its_own_reference(t: TestRunner) -> void:
	var makers := {
		"the closure marker": func(atlas: AtlasLibrary) -> Node:
			var node := ClosureMarker.new()
			node.atlas = atlas
			return node,
		"the traffic light": func(atlas: AtlasLibrary) -> Node:
			var node := TrafficLight.new()
			node.atlas = atlas
			return node,
		"the city edge": func(atlas: AtlasLibrary) -> Node:
			var node := CityEdge.new()
			node.atlas = atlas
			return node,
		"the park fence": func(atlas: AtlasLibrary) -> Node:
			var node := ParkFenceMarker.new()
			node.atlas = atlas
			return node,
		"the cordon tape": func(atlas: AtlasLibrary) -> Node:
			var node := CordonTape.new()
			node.use_atlas(atlas)
			return node,
	}
	for label: String in makers:
		_check_holds_its_own(t, makers[label], &"street_kit", label)

## One consumer alone on a fresh library and run log: it is seen to hold `group` on entering the
## tree, and the group's one release line comes when it leaves.
func _check_holds_its_own(t: TestRunner, make: Callable, group: StringName, label: String) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var node: Node = make.call(atlas)
	t.add_child(node)
	t.check(pages.held(group), "%s takes the '%s' page on its own" % [label, group])
	node.free()
	t.check(pages.releases(group) == 1,
			"%s gives its '%s' reference back when it leaves" % [label, group])
	pages.stop()

## The city edge is the one consumer with two groups — see `city_edge.gd`'s own doc for why it
## acquires `ground` itself rather than relying on anything else to have done so.
func _test_city_edge_also_holds_ground(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var edge := CityEdge.new()
	edge.atlas = atlas
	t.add_child(edge)
	t.check(pages.held(&"street_kit"), "the city edge holds street_kit on its own")
	t.check(pages.held(&"ground"), "and holds ground alongside it, for the mountain tile")
	edge.free()
	t.check(pages.releases(&"street_kit") == 1, "freeing it drops street_kit")
	t.check(pages.releases(&"ground") == 1, "and drops ground with it")
	pages.stop()

# ------------------------------------------------------------------------ ui ---

## The UI's pictures are the table's whole `ui/` family, swept by name rather than by each node's
## private constant: a picture a node draws is baked under `ui/` on the `ui` page or it is a bug, and
## a new one is covered without a line here. The mode button, whose symbol picks its picture, is also
## asked for each symbol, since `icon` is what it hands to the engine.
func _test_every_ui_region_is_baked_on_its_group(t: TestRunner) -> void:
	var names: Array = []
	for name in BakedRegions.names():
		if String(name).begins_with("ui/"):
			names.append(name)
	_check_regions(t, names, &"ui", "the UI")
	var atlas := AtlasLibrary.new()
	for symbol: ModeButton.Symbol in ModeButton.Symbol.values():
		var button := ModeButton.new()
		button.use_atlas(atlas)
		button.symbol = symbol
		t.add_child(button)
		t.check(button.icon != null, "the mode button's symbol %d has a picture from the page" % symbol)
		button.free()

## `ModeButton`, `TouchControls`, `SaveIndicator` and `HelpText` all acquire `ui` — the whole run's
## own group, including the title screen where no city exists — from four different files.
##
## This test is that they share one page and release it after the last; that each takes a reference
## of its own is `_test_each_ui_consumer_holds_its_own_reference`.
func _test_ui_consumers_share_one_reference_count(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var button := ModeButton.new()
	button.use_atlas(atlas)
	t.add_child(button)
	t.check(pages.held(&"ui"), "the mode button takes the page")
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	controls.atlas = atlas
	t.add_child(controls)
	var indicator := SaveIndicator.new()
	indicator.atlas = atlas
	t.add_child(indicator)
	var help := HelpText.new()
	help.use_atlas(atlas)
	t.add_child(help)
	t.check(pages.loads(&"ui") == 1,
			"touch controls, the save indicator and the help text share the same page rather than "
			+ "reading a second")
	button.free()
	controls.free()
	help.free()
	t.check(pages.releases(&"ui") == 0,
			"freeing three of the four leaves the page to the one that remains")
	indicator.free()
	t.check(pages.releases(&"ui") == 1,
			"freeing every UI consumer releases the group, with nothing left over")
	pages.stop()

## Each UI consumer, alone on a library of its own, takes `ui` on entering the tree and gives it
## back on leaving.
func _test_each_ui_consumer_holds_its_own_reference(t: TestRunner) -> void:
	var makers := {
		"the mode button": func(atlas: AtlasLibrary) -> Node:
			var node := ModeButton.new()
			node.use_atlas(atlas)
			return node,
		"touch controls": func(atlas: AtlasLibrary) -> Node:
			var node: TouchControls = TOUCH_CONTROLS.instantiate()
			node.atlas = atlas
			return node,
		"the save indicator": func(atlas: AtlasLibrary) -> Node:
			var node := SaveIndicator.new()
			node.atlas = atlas
			return node,
		"the help text": func(atlas: AtlasLibrary) -> Node:
			var node := HelpText.new()
			node.use_atlas(atlas)
			return node,
	}
	for label: String in makers:
		_check_holds_its_own(t, makers[label], &"ui", label)

# ------------------------------------------------------------------ interior ---

func _test_every_interior_region_is_baked_on_its_group(t: TestRunner) -> void:
	var names: Array = [
		InteriorScene.HALLWAY_WALL, InteriorScene.HALLWAY_WINDOW,
		InteriorScene.HALLWAY_WINDOW_FLASH, InteriorScene.WALL_LAMP_TEXTURE,
		InteriorScene.LIFT_DOOR_TEXTURE, InteriorScene.ENTRANCE_DOOR_TEXTURE,
		InteriorScene.ENTRANCE_BARRICADE_TEXTURE, InteriorScene.HALLWAY_RUBBLE_TEXTURE,
		InteriorScene.BRICK_WALL, InteriorScene.DOOR_TEXTURE,
		InteriorScene.APARTMENT_THRESHOLD_TEXTURE, InteriorScene.OPEN_THRESHOLD_TEXTURE,
		InteriorScene.EMERGENCY_EXIT_TEXTURE, InteriorScene.PUDDLE_TEXTURE,
		InteriorScene.DEBRIS_TEXTURE, InteriorScene.RAT_TEXTURE, InteriorScene.CHANDELIER_TEXTURE,
		InteriorScene.STAIRWELL_SEGMENT_BACKDROP, InteriorScene.STAIRWELL_SHAFT_CAP_TOP,
	]
	_check_regions(t, names, &"interior", "InteriorScene")

## Every ground kind the interior's `TileSet` carries a source for draws a region of the `interior`
## page: a source over the page that addresses exactly one of its regions. A region name the bake
## never wrote would leave its kind with no source at all, since `InteriorTileSet.build()` skips a
## region `AtlasLibrary.region()` cannot answer.
func _test_interior_tileset_regions_are_baked_on_the_interior_group(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"interior")
	var tile_set := InteriorTileSet.build(atlas)
	var rects: Dictionary = {}
	for name in BakedRegions.on(&"interior"):
		rects[AtlasTable.baked().region_rect(name)] = name
	var page: Texture2D = atlas.region(InteriorScene.BRICK_WALL).atlas
	var kinds := 0
	var strays: Array[String] = []
	for kind: InteriorTile.Kind in InteriorTile.Kind.values():
		var id := InteriorTileSet.source_id_for(kind)
		if id < 0:
			continue
		kinds += 1
		var source: TileSetAtlasSource = null
		if tile_set.has_source(id):
			source = tile_set.get_source(id) as TileSetAtlasSource
		if source == null or source.texture != page \
				or not rects.has(source.get_tile_texture_region(Vector2i.ZERO)):
			strays.append(str(InteriorTile.Kind.find_key(kind)))
	t.check(strays.is_empty(), "InteriorTileSet: every ground kind draws a region of the "
			+ "'interior' page (not: %s)" % ", ".join(strays.slice(0, 5)))
	t.check(kinds > 0, "InteriorTileSet: there were ground kinds to check at all (%d)" % kinds)
	tile_set = null
	atlas.release(&"interior")

## `InteriorScene` acquires `interior` in `_enter_tree()`, before `_ready()` builds anything that
## draws from it, and releases it in `_exit_tree()`.
##
## A second reference `build()` took and never gave back would leave the page held once the scene is
## freed, so the one release line at the end is what says building again took none.
func _test_interior_scene_acquires_and_releases_interior(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var scene := InteriorScene.new()
	scene.atlas = atlas
	t.add_child(scene)
	t.check(pages.held(&"interior"),
			"the interior scene acquires its group as it enters the tree")
	scene.build()
	t.check(pages.loads(&"interior") == 1 and pages.releases(&"interior") == 0,
			"building the map again keeps the page it holds, reading nothing more")
	scene.free()
	t.check(pages.releases(&"interior") == 1,
			"freeing the scene releases the group, with nothing left over")
	pages.stop()
