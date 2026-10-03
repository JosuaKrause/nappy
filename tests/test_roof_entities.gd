extends RefCounted
## Roof art that can reach a street lives in the city's y-sorted entity layer at its feet.

func run(t) -> void:
	_test_roof_objects_use_entities_and_have_no_body(t)
	_test_reserved_cells_hold_native_base_widths(t)
	_test_narrow_and_fragmented_roofs_keep_their_unit_count(t)
	_test_industrial_networks_fit_and_connect(t)
	_test_networks_on_narrow_and_shallow_roofs(t)
	_test_rebuild_releases_external_roof_objects(t)

func _new_fixture(t, district: int) -> Dictionary:
	var root := Node2D.new()
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	root.add_child(entities)
	t.add_child(root)
	var building := Building.new()
	building.name = "Building"
	building.position = Vector2(320.0, 320.0)
	building.footprint = Vector2(256.0, 256.0)
	building.height = 64.0
	building.district = district
	building.roof_object_parent = entities
	root.add_child(building)
	return {"root": root, "entities": entities, "building": building}

func _test_roof_objects_use_entities_and_have_no_body(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL)
	var entities: Node2D = fixture["entities"]
	var building: Building = fixture["building"]
	t.check(not building._roof_objects.is_empty(), "a full residential roof creates entity roof art")
	for i in building._roof_objects.size():
		var object: Building.RoofObject = building._roof_objects[i]
		var entry: Dictionary = building._roof_furniture[i]
		var cell: Vector2i = entry["cell"]
		var span: int = entry["span"]
		var expected := building.position + building._cell(cell.x, building.wall_tiles() + cell.y) \
				+ Vector2(Building.TILE * span * 0.5, Building.TILE)
		t.check(object.position.is_equal_approx(expected), "roof art uses the furniture foot anchor")
		t.check(object.get_parent() == entities, "roof art is parented under Entities")
		for child in object.get_children():
			t.check(not child is CollisionObject2D and not child is CollisionShape2D,
					"roof art has no collision child")
		t.check(not object.is_processing(), "stationary roof housing has no per-frame callback")
	building.free()
	fixture["root"].free()

func _test_industrial_networks_fit_and_connect(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL)
	var building: Building = fixture["building"]
	var signatures := {}
	var branched := false
	for variant in 40:
		building.variant = variant
		building.roof_extension_rows = [0, 0, 1, 3, 3, 1, 0, 0]
		var eligible := building.roof_interior_cells()
		var network := {}
		var used := {}
		var signature := ""
		for entry: Dictionary in building._roof_furniture:
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
		t.check(building._roof_furniture.size() > network.size(),
				"the network leaves room for ordinary roof equipment")
	t.check(signatures.size() > 2 and branched, "roof layouts vary in topology and include junctions")
	building.free()
	fixture["root"].free()

func _test_reserved_cells_hold_native_base_widths(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL)
	var building: Building = fixture["building"]
	var used := {}
	for entry: Dictionary in building._roof_furniture:
		var cells: Array = entry["cells"]
		for cell: Vector2i in cells:
			t.check(not used.has(cell), "roof equipment reservations never share a cell")
			used[cell] = true
		var width := 32 if entry.has("links") else AtlasLibrary.native_size(
				building._furniture_texture(entry["kind"])).x
		var horizontal_cells: int = entry["span"]
		t.check(cells.size() >= horizontal_cells,
				"a roof object's foot is centered in every reserved horizontal cell")
		t.check(width <= horizontal_cells * Building.TILE,
				"a roof object's %dpx base fits its reserved %dpx horizontal footprint"
				% [width, horizontal_cells * Building.TILE])
	building.free()
	fixture["root"].free()

func _test_networks_on_narrow_and_shallow_roofs(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL)
	var building: Building = fixture["building"]
	var vertical := false
	for size: Vector2 in [Vector2(96, 448), Vector2(128, 128), Vector2(160, 192),
			Vector2(288, 160), Vector2(192, 320)]:
		building.footprint = size
		for variant in 12:
			building.variant = variant
			var interior := building.roof_interior_cells()
			var occupied := {}
			var network := {}
			for entry: Dictionary in building._roof_furniture:
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
				t.check(building._roof_furniture.size() > network.size(),
						"narrow and shallow roof layouts retain ordinary compact equipment")
	t.check(vertical, "the narrow fixture exercises a generated purely vertical network")
	building.free()
	fixture["root"].free()

func _test_narrow_and_fragmented_roofs_keep_their_unit_count(t) -> void:
	for district in [GameEnums.BlockPurpose.INDUSTRIAL, GameEnums.BlockPurpose.CIVIC,
			GameEnums.BlockPurpose.RESIDENTIAL, GameEnums.BlockPurpose.COMMERCIAL]:
		var fixture := _new_fixture(t, district)
		var building: Building = fixture["building"]
		building.footprint = Vector2(3 * Building.TILE, 5 * Building.TILE)
		var wanted := clampi(roundi(building.roof_interior_cells().size()
				* Building._FURNITURE_DENSITY[district]), 1, building.roof_interior_cells().size())
		t.check(building._roof_furniture.size() == wanted,
				"a three-column roof keeps its %d ordinary-unit roll in district %d"
				% [wanted, district])
		for entry: Dictionary in building._roof_furniture:
			t.check(entry["span"] == 1, "a one-interior-column roof uses a compact one-cell unit")
		building.free()
		fixture["root"].free()

	var wider := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL)
	var building: Building = wider["building"]
	building.footprint = Vector2(5 * Building.TILE, 7 * Building.TILE)
	var witnessed_east_fallback := false
	for variant in 24:
		building.variant = variant
		var wanted := clampi(roundi(building.roof_interior_cells().size()
				* Building._FURNITURE_DENSITY[building.district]), 1,
				building.roof_interior_cells().size())
		t.check(building._roof_furniture.size() == wanted,
				"shuffled wider roof variant %d realizes its full ordinary-unit count" % variant)
		for entry: Dictionary in building._roof_furniture:
			if entry["span"] == 1 \
					and (entry["cell"] as Vector2i).x == building.columns() - 2:
				witnessed_east_fallback = true
	t.check(witnessed_east_fallback,
			"a wide roll at an east edge falls back to a compact unit instead of disappearing")
	building.free()
	wider["root"].free()

func _test_rebuild_releases_external_roof_objects(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL)
	var entities: Node2D = fixture["entities"]
	var building: Building = fixture["building"]
	var old_objects: Array[WeakRef] = []
	for object: Building.RoofObject in building._roof_objects:
		old_objects.append(weakref(object))
	building.variant += 1
	for object: WeakRef in old_objects:
		t.check(object.get_ref() == null, "rebuild frees superseded entity roof art")
	var replacements_in_entities := true
	for object: Building.RoofObject in building._roof_objects:
		if object.get_parent() != entities:
			replacements_in_entities = false
	t.check(replacements_in_entities, "rebuild keeps replacement roof art in Entities")
	building.free()
	fixture["root"].free()
