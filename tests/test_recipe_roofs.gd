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
	t.check(authored.size() == 3 and authored[0].cell == Vector2i(2, 3),
			"requested fixtures replace random furniture in back-to-front painter order")
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
	for roof in [true, [{"lot": [1, 2], "fixtures": []}],
		[{"lot": [1, 2, 8, 8], "fixtures": [{"cell": [1.5, 2], "kind": "vent"}]}],
		[{"lot": [1, 2, 8, 8], "fixtures": [{"cell": [1, 2], "kind": "unknown"}]}]]:
		t.check(not SceneRecipeRuntime.validate_runtime({"setup": {"roof_fixtures": roof}}).is_empty(),
				"malformed roof recipes fail before runtime construction")
