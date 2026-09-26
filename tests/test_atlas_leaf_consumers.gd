extends RefCounted
## M171, "The unatlased leaf consumers": buildings, the street kit (the city edge, closure
## markers, traffic lights), the UI (`ModeButton`, `TouchControls`, `SaveIndicator`) and the
## interior (`InteriorScene`, `InteriorTileSet`) each draw from `AtlasLibrary` regions now instead
## of a `preload`ed texture. Two things a headless `check.sh`/`test.sh` boot cannot see on its own,
## because headless never calls `_draw()` (see the **verify** skill): a region name a consumer's
## drawing code holds a literal for that the bake never actually wrote, which would sit silent
## until somebody looked at a screenshot; and a group a freed consumer leaves acquired forever,
## which nothing else would ever notice either. This suite checks both, plus that every consumer
## sharing a group counts references rather than loading a second page.

const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")

func run(t) -> void:
	AtlasLibrary.reset_for_tests()
	_test_every_building_region_is_baked_on_its_group(t)
	_test_building_acquires_and_releases_buildings(t)
	_test_every_street_kit_region_is_baked_on_its_group(t)
	_test_street_kit_consumers_share_one_reference_count(t)
	_test_city_edge_also_holds_ground(t)
	_test_every_ui_region_is_baked_on_its_group(t)
	_test_ui_consumers_share_one_reference_count(t)
	_test_every_interior_region_is_baked_on_its_group(t)
	_test_interior_tileset_regions_are_baked_on_the_interior_group(t)
	_test_interior_scene_acquires_and_releases_interior(t)
	AtlasLibrary.reset_for_tests()

# ------------------------------------------------------------------ helpers ---

## Every name in `names` is a region the bake actually wrote, and every one of them is on
## `group` — the check a headless run cannot make by actually drawing one.
func _check_regions(t, names: Array, group: StringName, label: String) -> void:
	var missing: Array[String] = []
	var misfiled: Array[String] = []
	for entry in names:
		var name := entry as StringName
		if not AtlasLibrary.has_region(name):
			missing.append(String(name))
		elif AtlasLibrary.group_of(name) != group:
			misfiled.append(String(name))
	t.check(missing.is_empty(), "%s: every region name resolves (missing %s)"
			% [label, ", ".join(missing.slice(0, 5))])
	t.check(misfiled.is_empty(), "%s: every region is on the '%s' group (%s)"
			% [label, group, ", ".join(misfiled.slice(0, 5))])
	t.check(names.size() > 0, "%s: there were names to check at all (%d)" % [label, names.size()])

# ------------------------------------------------------------------ buildings ---

func _test_every_building_region_is_baked_on_its_group(t) -> void:
	var names: Array = [
		Building.WALL, Building.WALL_BASE, Building.WALL_EDGE_W, Building.WALL_EDGE_E,
		Building.ROOF, Building.ROOF_EDGE_N, Building.ROOF_EDGE_S, Building.ROOF_EDGE_W,
		Building.ROOF_EDGE_E, Building.WINDOW_DARK, Building.WINDOW_LIT,
		Building.WINDOW_TALL_DARK, Building.WINDOW_TALL_LIT, Building.WINDOW_SHUTTERED_DARK,
		Building.WINDOW_SHUTTERED_LIT, Building.FIRE_ESCAPE_A, Building.FIRE_ESCAPE_B,
		Building.CIVIC_PORTICO, Building.VENT_A, Building.VENT_B, Building.HVAC_A,
		Building.HVAC_B, Building.DUCT_STRAIGHT, Building.DUCT_CORNER, Building.SKYLIGHT_A,
		Building.SKYLIGHT_B, Building.VENT_STACK, Building.WATER_TANK,
	]
	names.append_array(Building.STOREFRONT_TEXTURES)
	names.append_array(Building.STOREFRONT_AWNING_TEXTURES)
	names.append_array(Building.STOREFRONT_SHUTTERED_TEXTURES)
	names.append_array(PosterArt.region_names())
	_check_regions(t, names, &"buildings", "Building")

## Acquired the moment a building enters the tree, shared by reference count rather than a page
## per building, and released only once the last one is gone.
func _test_building_acquires_and_releases_buildings(t) -> void:
	t.check(not AtlasLibrary.is_acquired(&"buildings"),
			"nothing holds the buildings group before any building exists")
	var a := Building.new()
	t.add_child(a)
	t.check(AtlasLibrary.reference_count(&"buildings") == 1, "the first building counts one")
	var b := Building.new()
	t.add_child(b)
	t.check(AtlasLibrary.reference_count(&"buildings") == 2,
			"a second building sharing the group counts two, not a second page")
	a.free()
	t.check(AtlasLibrary.reference_count(&"buildings") == 1, "freeing one building drops one reference")
	b.free()
	t.check(AtlasLibrary.reference_count(&"buildings") == 0,
			"freeing the last building releases the group")
	t.check(not AtlasLibrary.is_acquired(&"buildings"),
			"and the group holds nothing once its last user is gone")

# ---------------------------------------------------------------- street kit ---

func _test_every_street_kit_region_is_baked_on_its_group(t) -> void:
	var names: Array = [
		ClosureMarker.FENCE_ACROSS, ClosureMarker.FENCE_ALONG, ClosureMarker.SIGN,
		ClosureMarker.POST,
		ParkFenceMarker.RAIL_ALONG, ParkFenceMarker.JOINT,
		TrafficLight.HEAD, TrafficLight.HEAD_BACK, TrafficLight.HEAD_SIDE,
		CityEdge.TUNNEL, CityEdge.BRIDGE, CityEdge.ROAD_ON,
	]
	names.append_array(ClosureMarker.CAUSES.values())
	names.append_array(ClosureMarker.CAUSES_VERTICAL.values())
	_check_regions(t, names, &"street_kit", "the street kit")
	t.check(AtlasLibrary.group_of(CityEdge.MOUNTAIN) == &"ground",
			"the city edge's mountain tile is on the ground page, not street_kit")

## `ClosureMarker`, `TrafficLight` and `CityEdge` each acquire `street_kit` independently, from
## three different files, and the group still counts references rather than loading three pages.
func _test_street_kit_consumers_share_one_reference_count(t) -> void:
	t.check(not AtlasLibrary.is_acquired(&"street_kit"),
			"nothing holds street_kit before any of its consumers exist")
	var marker := ClosureMarker.new()
	t.add_child(marker)
	t.check(AtlasLibrary.reference_count(&"street_kit") == 1, "the closure marker counts one")
	var light := TrafficLight.new()
	t.add_child(light)
	t.check(AtlasLibrary.reference_count(&"street_kit") == 2,
			"the traffic light shares the same group rather than acquiring a second page")
	var edge := CityEdge.new()
	t.add_child(edge)
	t.check(AtlasLibrary.reference_count(&"street_kit") == 3,
			"the city edge is a third reference on the same group")
	var park := ParkFenceMarker.new()
	t.add_child(park)
	t.check(AtlasLibrary.reference_count(&"street_kit") == 4,
			"the park fence shares the street kit through its inherited lifecycle")
	park.free()
	marker.free()
	light.free()
	edge.free()
	t.check(AtlasLibrary.reference_count(&"street_kit") == 0,
			"freeing every street-kit consumer releases the group")
	t.check(not AtlasLibrary.is_acquired(&"street_kit"), "and it holds nothing left over")

## The city edge is the one consumer with two groups — see `city_edge.gd`'s own doc for why it
## acquires `ground` itself rather than relying on anything else to have done so.
func _test_city_edge_also_holds_ground(t) -> void:
	t.check(not AtlasLibrary.is_acquired(&"ground"),
			"nothing holds ground before any city edge exists")
	var edge := CityEdge.new()
	t.add_child(edge)
	t.check(AtlasLibrary.reference_count(&"street_kit") == 1,
			"the city edge holds street_kit on its own")
	t.check(AtlasLibrary.reference_count(&"ground") == 1,
			"and holds ground alongside it, for the mountain tile")
	edge.free()
	t.check(AtlasLibrary.reference_count(&"street_kit") == 0, "freeing it drops street_kit")
	t.check(AtlasLibrary.reference_count(&"ground") == 0, "and drops ground with it")

# ------------------------------------------------------------------------ ui ---

func _test_every_ui_region_is_baked_on_its_group(t) -> void:
	var names: Array = [ModeButton._RESTART_ICON, ModeButton._CONTINUE_ICON,
			ModeButton._JOYSTICK_ICON, ModeButton._TAP_ICON, TouchControls._PAUSE_ICON,
			SaveIndicator._ICON]
	_check_regions(t, names, &"ui", "the UI")

## `ModeButton`, `TouchControls` and `SaveIndicator` all acquire `ui` — the whole run's own group,
## including the title screen where no city exists — from three different files.
func _test_ui_consumers_share_one_reference_count(t) -> void:
	t.check(not AtlasLibrary.is_acquired(&"ui"), "nothing holds ui before any of its consumers exist")
	var button := ModeButton.new()
	t.add_child(button)
	t.check(AtlasLibrary.reference_count(&"ui") == 1, "the mode button counts one")
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	t.add_child(controls)
	t.check(AtlasLibrary.reference_count(&"ui") == 2,
			"touch controls share the same group rather than acquiring a second page")
	var indicator := SaveIndicator.new()
	t.add_child(indicator)
	t.check(AtlasLibrary.reference_count(&"ui") == 3, "the save indicator is a third reference")
	button.free()
	controls.free()
	indicator.free()
	t.check(AtlasLibrary.reference_count(&"ui") == 0, "freeing every UI consumer releases the group")
	t.check(not AtlasLibrary.is_acquired(&"ui"), "and it holds nothing left over")

# ------------------------------------------------------------------ interior ---

func _test_every_interior_region_is_baked_on_its_group(t) -> void:
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

func _test_interior_tileset_regions_are_baked_on_the_interior_group(t) -> void:
	var names: Array = []
	for kind in InteriorTile.Kind.values():
		var name := InteriorTileSet.region_name_for(kind)
		if name != &"":
			names.append(name)
	_check_regions(t, names, &"interior", "InteriorTileSet")

## `InteriorScene` acquires `interior` in `_enter_tree()`, before `_ready()` builds anything that
## draws from it, and releases it in `_exit_tree()`.
func _test_interior_scene_acquires_and_releases_interior(t) -> void:
	t.check(not AtlasLibrary.is_acquired(&"interior"),
			"nothing holds interior before any InteriorScene exists")
	var scene := InteriorScene.new()
	t.add_child(scene)
	t.check(AtlasLibrary.reference_count(&"interior") == 1,
			"the interior scene acquires its group as it enters the tree")
	scene.build()
	t.check(AtlasLibrary.reference_count(&"interior") == 1,
			"building the map again does not acquire a second reference")
	scene.free()
	t.check(AtlasLibrary.reference_count(&"interior") == 0,
			"freeing the scene releases the group")
	t.check(not AtlasLibrary.is_acquired(&"interior"), "and it holds nothing left over")
