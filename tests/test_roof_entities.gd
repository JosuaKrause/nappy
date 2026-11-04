extends RefCounted
## Roof art that can reach a street lives in the city's y-sorted entity layer at its feet.
##
## Three things are tested apart. Where a roof's units stand is decided by its random draws, so the
## layout (`Building.roof_layout()`) is checked on its own as a function of the seed and the lot.
## The roof that holds them is checked with a drawer that records what it is told to draw
## (`tests/recording_roof_drawer.gd`), handed in through `Building.roof_drawer` as the city hands the
## real one: every unit the layout places is drawn, at its foot, in the layer the city gave it. And
## what the real drawer (`RoofDrawer`) stands in that layer is read off the layer itself.

const RecordingRoofDrawer := preload("res://tests/recording_roof_drawer.gd")

func run(t) -> void:
	_test_every_placed_unit_is_drawn_at_its_foot_in_entities(t)
	_test_the_real_drawer_stands_bodiless_still_units_in_entities(t)
	_test_the_layout_is_a_function_of_the_seed_and_the_lot(t)
	_test_reserved_cells_hold_native_base_widths(t)
	_test_narrow_and_fragmented_roofs_keep_their_unit_count(t)
	_test_industrial_networks_fit_and_connect(t)
	_test_networks_on_narrow_and_shallow_roofs(t)
	_test_rebuild_releases_external_roof_objects(t)

## A building standing at the same place on the same lot as the city builds one, its roof drawn
## into an `Entities` layer through `drawer` (a recording one, or the real one over its own atlas
## when null), handed in before it enters the tree as `City._spawn_buildings()` hands them.
func _new_fixture(t, district: int, drawer: RoofDrawer = null) -> Dictionary:
	var root := Node2D.new()
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	root.add_child(entities)
	t.add_child(root)
	var building := Building.new()
	building.name = "Building"
	building.atlas = AtlasLibrary.new()
	building.roof_drawer = drawer if drawer != null else RoofDrawer.new(building.atlas)
	building.position = Vector2(320.0, 320.0)
	building.footprint = Vector2(256.0, 256.0)
	building.height = 64.0
	building.district = district
	building.roof_object_parent = entities
	root.add_child(building)
	return {"root": root, "entities": entities, "building": building}

func _free(fixture: Dictionary) -> void:
	(fixture["building"] as Building).free()
	(fixture["root"] as Node).free()

## The roof units standing in `entities`, in the order they were added.
func _roof_objects_in(entities: Node) -> Array[Building.RoofObject]:
	var objects: Array[Building.RoofObject] = []
	for child in entities.get_children():
		if child is Building.RoofObject:
			objects.append(child)
	return objects

# ------------------------------------------------------------------ the holder ---

func _test_every_placed_unit_is_drawn_at_its_foot_in_entities(t) -> void:
	var drawer := RecordingRoofDrawer.new()
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL, drawer)
	var entities: Node2D = fixture["entities"]
	var building: Building = fixture["building"]
	var layout := building.roof_layout()
	t.check(not layout.is_empty(), "a full residential roof places roof units")
	var standing := drawer.standing()
	t.check(standing.size() == layout.size() and drawer.draws.size() == layout.size(),
			"every unit the layout places is drawn once, and nothing else is (%d placed, %d drawn)"
			% [layout.size(), drawer.draws.size()])
	for i in mini(layout.size(), standing.size()):
		var unit := layout[i]
		var drawn := standing[i]
		t.check(drawn.cell == unit.cell and drawn.texture == unit.texture
				and drawn.links == unit.get("links", -1),
				"units are drawn as placed, farthest first")
		t.check(drawn.layer == entities, "roof art is drawn into Entities")
		var at: Vector2 = drawn.at
		t.check(at.is_equal_approx(building.position + RecordingRoofDrawer.foot_of(building, unit)),
				"roof art uses the furniture foot anchor")
	_free(fixture)

## Over several seeds, so a vent housing is among the units and its rotor is checked too.
func _test_the_real_drawer_stands_bodiless_still_units_in_entities(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL)
	var entities: Node2D = fixture["entities"]
	var building: Building = fixture["building"]
	var vents := 0
	for variant in 6:
		building.variant = variant
		var layout := building.roof_layout()
		var objects := _roof_objects_in(entities)
		t.check(not objects.is_empty() and objects.size() == layout.size(),
				"the real drawer stands one roof object in Entities per placed unit")
		for i in mini(layout.size(), objects.size()):
			var object := objects[i]
			t.check(object.texture_key == layout[i].texture and object.position.is_equal_approx(
					building.position + RecordingRoofDrawer.foot_of(building, layout[i])),
					"each roof object shows its unit's picture at its foot")
			for child in object.get_children():
				t.check(not child is CollisionObject2D and not child is CollisionShape2D,
						"roof art has no collision child")
			t.check(not object.is_processing(), "stationary roof housing has no per-frame callback")
			if object.texture_key == Building.VENT_HOUSING:
				vents += 1
				t.check(object.rotor != null and object.rotor.get_parent() == object,
						"a vent housing stands with its turning rotor")
	t.check(vents > 0, "the residential fixture draws a vent housing, so its rotor is checked")
	_free(fixture)

# ------------------------------------------------------------------ the layout ---

func _test_the_layout_is_a_function_of_the_seed_and_the_lot(t) -> void:
	var drawer := RecordingRoofDrawer.new()
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, drawer)
	var twin := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL)
	var building: Building = fixture["building"]
	var other: Building = twin["building"]
	var differs := false
	for variant in 8:
		building.variant = variant
		other.variant = variant
		var draws := drawer.draws.size()
		var layout := building.roof_layout()
		t.check(building.roof_layout() == layout and drawer.draws.size() == draws,
				"asking for the layout again gives the same one and draws nothing")
		t.check(other.roof_layout() == layout,
				"the same seed on the same lot lays the same roof on another building")
		t.check(RecordingRoofDrawer.placed(layout) == drawer.drawn(),
				"the roof drawn is the layout placed")
		building.variant = variant + 100
		differs = differs or building.roof_layout() != layout
	t.check(differs, "another seed lays another roof on the same lot")
	_free(fixture)
	_free(twin)

func _test_industrial_networks_fit_and_connect(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, RecordingRoofDrawer.new())
	var building: Building = fixture["building"]
	var signatures := {}
	var branched := false
	for variant in 40:
		building.variant = variant
		building.roof_extension_rows = [0, 0, 1, 3, 3, 1, 0, 0]
		var eligible := building.roof_interior_cells()
		var layout := building.roof_layout()
		var network := {}
		var used := {}
		var signature := ""
		for entry: Dictionary in layout:
			for cell: Vector2i in entry["cells"]:
				t.check(eligible.has(cell) and not used.has(cell),
						"every duct and equipment foot fits free interior roof, extensions included")
				used[cell] = true
			if entry.has("links"):
				network[entry["cell"]] = entry["links"]
				signature += str(entry["links"]) + ","
		t.check(not network.is_empty(), "the industrial fixture has a connected network")
		if network.is_empty():
			continue
		signatures[signature] = true
		var reached := {network.keys()[0]: true}
		var pending: Array = reached.keys()
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			var degree := 0
			for index in 4:
				var direction: Vector2i = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN][index]
				var neighbor := cell + direction
				var linked: bool = (network[cell] & (1 << index)) != 0
				t.check(linked == network.has(neighbor), "rendered duct links match actual adjacent cells")
				if linked:
					degree += 1
					if not reached.has(neighbor):
						reached[neighbor] = true
						pending.append(neighbor)
			branched = branched or degree >= 3
		t.check(reached.size() == network.size(), "all duct cells belong to one traversable network")
		t.check(layout.size() > network.size(),
				"the network leaves room for ordinary roof equipment")
	t.check(signatures.size() > 2 and branched, "roof layouts vary in topology and include junctions")
	_free(fixture)

func _test_reserved_cells_hold_native_base_widths(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, RecordingRoofDrawer.new())
	var building: Building = fixture["building"]
	var used := {}
	for entry: Dictionary in building.roof_layout():
		var cells: Array = entry["cells"]
		for cell: Vector2i in cells:
			t.check(not used.has(cell), "roof equipment reservations never share a cell")
			used[cell] = true
		var key: StringName = entry["texture"]
		var width := 32.0 if entry.has("links") else AtlasTable.baked().native_size(key).x \
				* Building.roof_equipment_scale(key)
		var horizontal_cells: int = entry["span"]
		t.check(cells.size() >= horizontal_cells,
				"a roof object's foot is centered in every reserved horizontal cell")
		t.check(width <= horizontal_cells * Building.TILE,
				"a roof object's %dpx base fits its reserved %dpx horizontal footprint"
				% [width, horizontal_cells * Building.TILE])
	_free(fixture)

func _test_networks_on_narrow_and_shallow_roofs(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, RecordingRoofDrawer.new())
	var building: Building = fixture["building"]
	var vertical := false
	for size: Vector2 in [Vector2(96, 448), Vector2(128, 128), Vector2(160, 192),
			Vector2(288, 160), Vector2(192, 320)]:
		building.footprint = size
		for variant in 12:
			building.variant = variant
			var interior := building.roof_interior_cells()
			var layout := building.roof_layout()
			var occupied := {}
			var network := {}
			for entry: Dictionary in layout:
				for cell: Vector2i in entry["cells"]:
					t.check(interior.has(cell) and not occupied.has(cell),
							"narrow and shallow roofs never reserve a lip, absent cell or occupied base")
					occupied[cell] = true
				if entry.has("links"):
					network[entry["cell"]] = entry["links"]
			if size.x == 96 and not network.is_empty():
				vertical = true
				for links: int in network.values():
					t.check((links & 3) == 0, "a one-column network uses only north/south links")
			if not interior.is_empty():
				t.check(layout.size() > network.size(),
						"narrow and shallow roof layouts retain ordinary compact equipment")
	t.check(vertical, "the narrow fixture exercises a generated purely vertical network")
	_free(fixture)

## The share of interior cells a district's roof fills is the class's own design constant
## (`Building._FURNITURE_DENSITY`), read here because what is checked is that a fallback to a
## compact unit keeps the count that share rolled; no game class reads it from outside.
func _test_narrow_and_fragmented_roofs_keep_their_unit_count(t) -> void:
	for district in [GameEnums.BlockPurpose.INDUSTRIAL, GameEnums.BlockPurpose.CIVIC,
			GameEnums.BlockPurpose.RESIDENTIAL, GameEnums.BlockPurpose.COMMERCIAL]:
		var fixture := _new_fixture(t, district, RecordingRoofDrawer.new())
		var building: Building = fixture["building"]
		building.footprint = Vector2(3 * Building.TILE, 5 * Building.TILE)
		var wanted := clampi(roundi(building.roof_interior_cells().size()
				* Building._FURNITURE_DENSITY[district]), 1, building.roof_interior_cells().size())
		var layout := building.roof_layout()
		t.check(layout.size() == wanted,
				"a three-column roof keeps its %d ordinary-unit roll in district %d"
				% [wanted, district])
		for entry: Dictionary in layout:
			t.check(entry["span"] == 1, "a one-interior-column roof uses a compact one-cell unit")
		_free(fixture)

	var wider := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL, RecordingRoofDrawer.new())
	var building: Building = wider["building"]
	building.footprint = Vector2(5 * Building.TILE, 7 * Building.TILE)
	var witnessed_east_fallback := false
	for variant in 24:
		building.variant = variant
		var wanted := clampi(roundi(building.roof_interior_cells().size()
				* Building._FURNITURE_DENSITY[building.district]), 1,
				building.roof_interior_cells().size())
		var layout := building.roof_layout()
		t.check(layout.size() == wanted,
				"shuffled wider roof variant %d realizes its full ordinary-unit count" % variant)
		for entry: Dictionary in layout:
			if entry["span"] == 1 \
					and (entry["cell"] as Vector2i).x == building.columns() - 2:
				witnessed_east_fallback = true
	t.check(witnessed_east_fallback,
			"a wide roll at an east edge falls back to a compact unit instead of disappearing")
	_free(wider)

# ------------------------------------------------------------- the real drawer ---

func _test_rebuild_releases_external_roof_objects(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL)
	var entities: Node2D = fixture["entities"]
	var building: Building = fixture["building"]
	var old_objects: Array[WeakRef] = []
	for object in _roof_objects_in(entities):
		old_objects.append(weakref(object))
	t.check(not old_objects.is_empty(), "the roof had objects to release")
	building.variant += 1
	for object: WeakRef in old_objects:
		t.check(object.get_ref() == null, "rebuild frees superseded entity roof art")
	var replacements := _roof_objects_in(entities)
	t.check(not replacements.is_empty() and replacements.size() == entities.get_child_count()
			and replacements.size() == building.roof_layout().size(),
			"rebuild keeps replacement roof art in Entities")
	_free(fixture)
