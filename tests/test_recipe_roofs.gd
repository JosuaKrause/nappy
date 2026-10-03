extends RefCounted
## Authored units remain real production roof furniture through residency changes.

func run(t) -> void:
	var building := Building.new()
	building.footprint = Vector2(256, 256)
	building.height = 64
	building.district = GameEnums.BlockPurpose.INDUSTRIAL
	t.add_child(building)
	var fixtures := [{"cell": [1, 2], "kind": "duct_straight"},
		{"cell": [2, 3], "kind": "duct_corner"}, {"cell": [5, 1], "kind": "vent"}]
	t.check(building.author_roof_furniture(fixtures).is_empty(), "production interior accepts exact existing fixtures")
	var authored := building._roof_furniture.duplicate(true)
	t.check(authored.size() == 4 and authored[0].cell == Vector2i(2, 3),
			"requested fixtures replace random furniture in back-to-front painter order")
	for entry: Dictionary in authored:
		t.check(entry.cells.size() == entry.span, "authored reservations retain current cell metadata")
		if entry.kind == Building._Furniture.DUCT_RUN:
			t.check(entry.span == 1 and entry.links in [3, 9],
					"public duct names become supported horizontal spans and an elbow")
	t.check(SceneRecipeRuntime.validate_runtime({"setup": {"roof_fixtures": [
		{"lot": [1, 2, 8, 8], "fixtures": fixtures}]}}).is_empty(),
			"saved public duct names pass the runtime schema before production placement")
	building.set_scenery_resident(false)
	building.set_scenery_resident(true)
	t.check(building._roof_furniture == authored, "streaming restores the authored fixtures exactly")
	for invalid in [
		[{"cell": [0, 1], "kind": "vent"}],
		[{"cell": [6, 2], "kind": "duct_straight"}],
		[{"cell": [2, 2], "kind": "vent"}, {"cell": [2, 2], "kind": "hvac_a"}],
		[{"cell": [2, 2], "kind": "water_tank"}]]:
		t.check(not building.author_roof_furniture(invalid).is_empty(),
				"edge, duct span, overlap and district failures reject the complete replacement")
		t.check(building._roof_furniture == authored, "rejected fixtures do not mutate the valid roof")
	building.free()
	_displayed_reservations(t)
	_joined_authored_ducts(t)
	for roof in [true, [{"lot": [1, 2], "fixtures": []}],
		[{"lot": [1, 2, 8, 8], "fixtures": [{"cell": [1.5, 2], "kind": "vent"}]}],
		[{"lot": [1, 2, 8, 8], "fixtures": [{"cell": [1, 2], "kind": "unknown"}]}]]:
		t.check(not SceneRecipeRuntime.validate_runtime({"setup": {"roof_fixtures": roof}}).is_empty(),
				"malformed roof recipes fail before runtime construction")
	for kind in ["duct_run", "_unused_duct_corner"]:
		t.check(not SceneRecipeRuntime.validate_runtime({"setup": {"roof_fixtures": [
			{"lot": [1, 2, 8, 8], "fixtures": [{"cell": [1, 2], "kind": kind}]}]}}).is_empty(),
				"internal duct enum values are not leaked into the public recipe schema")

func _displayed_reservations(t) -> void:
	for fixture in [
		[GameEnums.BlockPurpose.CIVIC, "service_bulkhead"],
		[GameEnums.BlockPurpose.CIVIC, "skylight_a"],
		[GameEnums.BlockPurpose.RESIDENTIAL, "water_tank"],
		[GameEnums.BlockPurpose.INDUSTRIAL, "pipe_manifold"]]:
		var building := Building.new()
		building.footprint = Vector2(256, 256)
		building.height = 64
		building.district = fixture[0]
		t.add_child(building)
		var valid := [{"cell": [5, 1], "kind": fixture[1]}]
		t.check(SceneRecipeRuntime.validate_runtime({"setup": {"roof_fixtures": [
			{"lot": [1, 2, 8, 8], "fixtures": valid}]}}).is_empty(),
				"current production fixtures pass the public recipe schema")
		t.check(building.author_roof_furniture(valid).is_empty(),
				"wide fixture fits the last two interior columns")
		var authored := building._roof_furniture.duplicate(true)
		t.check(authored[0].span == 2 and authored[0].cells.has(Vector2i(6, 1)),
				"displayed fixture reserves its full base including the east cell")
		var object: Building.RoofObject = building._roof_objects[0]
		var width := AtlasLibrary.native_size(object.texture_key).x * object.scale.x
		# Node2D stores the 4/3 room transform in Vector2 float precision.
		t.check(width <= 64.0 or is_equal_approx(width, 64.0),
				"rendered width fits the accepted two-cell reservation")
		for invalid in [[{"cell": [6, 1], "kind": fixture[1]}],
			[valid[0], {"cell": [6, 1], "kind": fixture[1]}]]:
			t.check(not building.author_roof_furniture(invalid).is_empty(),
					"wide fixtures reject edge overflow and east-cell overlap")
			t.check(building._roof_furniture == authored,
					"failed width validation leaves the complete authored roof unchanged")
		building.set_scenery_resident(false)
		building.set_scenery_resident(true)
		t.check(building._roof_furniture == authored,
				"streaming preserves the enlarged or wide fixture reservation")
		t.check(building.author_roof_furniture([]).is_empty()
				and building._roof_objects.is_empty(), "explicit empty recipe clears all roof objects")
		building.free()

func _joined_authored_ducts(t) -> void:
	var building := Building.new()
	building.footprint = Vector2(256, 128)
	building.height = 32
	building.district = GameEnums.BlockPurpose.INDUSTRIAL
	t.add_child(building)
	var fixtures := [{"cell": [1, 1], "kind": "duct_straight"},
		{"cell": [3, 1], "kind": "duct_corner"}]
	t.check(building.author_roof_furniture(fixtures).is_empty(),
			"trailer bird roof accepts its adjacent straight and elbow")
	var straight: Building.RoofObject = building.get_node("RoofObject_2_1")
	var elbow: Building.RoofObject = building.get_node("RoofObject_3_1")
	t.check((straight.duct_links & 2) != 0 and (elbow.duct_links & 1) != 0
			and (elbow.duct_links & 8) != 0
			and straight.position + Vector2(16, 0) == elbow.position - Vector2(16, 0),
			"authored straight reaches the elbow boundary without an endpoint gap")
	building.free()
