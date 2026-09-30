extends RefCounted
## Roof art that can reach a street lives in the city's y-sorted entity layer at its feet.

func run(t) -> void:
	_test_roof_objects_use_entities_and_have_no_body(t)
	_test_industrial_duct_is_one_three_cell_unit(t)
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
		t.check(object.get_child_count() == 0, "roof art has no collision child")
	building.free()
	fixture["root"].free()

func _test_industrial_duct_is_one_three_cell_unit(t) -> void:
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL)
	var building: Building = fixture["building"]
	var found := false
	for entry: Dictionary in building._roof_furniture:
		if entry["kind"] != Building._Furniture.DUCT_RUN:
			continue
		found = true
		var cells: Array = entry["cells"]
		t.check(cells.size() == 3, "the duct run consumes exactly three cells")
		t.check(cells[0] != cells[1] and cells[1] != cells[2] and cells[0] != cells[2],
			"the duct run footprint uses three distinct cells")
	t.check(found, "the industrial fixture carries a duct run")
	building.free()
	fixture["root"].free()

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
