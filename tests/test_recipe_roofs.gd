extends RefCounted
## Authored units remain real production roof furniture through residency changes.
##
## The authored layout is read off what the roof draws, through a drawer handed in as the city hands
## one (`Building.equip()`): a recording one (`tests/recording_roof_drawer.gd`) where the check
## is what was drawn, the real one a building makes for itself where the check is the picture's
## own width or joint and the roof is read off where its objects stand (`tests/roof_reads.gd`).

const RecordingRoofDrawer := preload("res://tests/recording_roof_drawer.gd")
const RoofReads := preload("res://tests/roof_reads.gd")
const RecipeErrors := preload("res://tests/recipe_runtime_errors.gd")

## Where each recipe is written and loaded, and what loading it answers.
var _errors := RecipeErrors.new()

func run(t: TestRunner) -> void:
	_test_authored_fixtures_replace_the_roll(t)
	_displayed_reservations(t)
	_joined_authored_ducts(t)
	_test_malformed_recipes_fail_before_construction(t)

## A standalone production roof of `district`, drawn through `drawer` when one is handed, else
## through the real drawer it makes for itself.
func _roof(t: TestRunner, footprint: Vector2, height: float, district: int,
		drawer: RoofDrawer = null) -> Building:
	var building := Building.new()
	building.footprint = footprint
	building.height = height
	building.district = district
	if drawer != null:
		var atlas := AtlasLibrary.new()
		building.equip(atlas, drawer, FrontDrawer.new(atlas))
	t.add_child(building)
	if drawer != null:
		# Equipped as the city equips it, the building waits for the residency, which stands a
		# building in view up.
		building.residence().set_resident(true)
	return building

## The roof units standing on a standalone `building`, which parents them to itself.
func _roof_objects_on(building: Building) -> Array[Building.RoofObject]:
	var objects: Array[Building.RoofObject] = []
	for child in building.get_children():
		if child is Building.RoofObject:
			objects.append(child)
	return objects

func _test_authored_fixtures_replace_the_roll(t: TestRunner) -> void:
	var drawer := RecordingRoofDrawer.new()
	var building := _roof(t, Vector2(256, 256), 64, GameEnums.BlockPurpose.INDUSTRIAL, drawer)
	var fixtures := [{"cell": [1, 2], "kind": "duct_straight"},
		{"cell": [2, 3], "kind": "duct_corner"}, {"cell": [5, 1], "kind": "vent"}]
	t.check(building.author_roof_furniture(fixtures).is_empty(), "production interior accepts exact existing fixtures")
	var authored := drawer.layout()
	var drawn := drawer.drawn()
	t.check(authored.size() == 4 and authored[0].cell == Vector2i(2, 3),
			"requested fixtures replace random furniture in back-to-front painter order")
	for entry: Dictionary in authored:
		if entry.texture == Building.DUCT_RUN:
			t.check(entry.span == 1 and entry.links in [3, 9],
					"public duct names become supported horizontal spans and an elbow")
	t.check(_errors.errors_of(t, {"setup": {"roof_fixtures": [
		{"lot": [1, 2, 8, 8], "fixtures": fixtures}]}}).is_empty(),
			"saved public duct names pass the runtime schema before production placement")
	building.residence().set_resident(false)
	t.check(drawer.standing().is_empty(), "an evicted roof leaves nothing drawn")
	building.residence().set_resident(true)
	t.check(drawer.layout() == authored and drawer.drawn() == drawn,
			"streaming restores the authored fixtures exactly")
	for invalid: Array in [
		[{"cell": [0, 1], "kind": "vent"}],
		[{"cell": [6, 2], "kind": "duct_straight"}],
		[{"cell": [2, 2], "kind": "vent"}, {"cell": [2, 2], "kind": "hvac_a"}],
		[{"cell": [2, 2], "kind": "water_tank"}]]:
		t.check(not building.author_roof_furniture(invalid).is_empty(),
				"edge, duct span, overlap and district failures reject the complete replacement")
		t.check(drawer.layout() == authored and drawer.drawn() == drawn,
				"rejected fixtures do not mutate the valid roof")
	building.free()

func _displayed_reservations(t: TestRunner) -> void:
	for fixture: Array in [
		[GameEnums.BlockPurpose.CIVIC, "service_bulkhead"],
		[GameEnums.BlockPurpose.CIVIC, "skylight_a"],
		[GameEnums.BlockPurpose.RESIDENTIAL, "water_tank"],
		[GameEnums.BlockPurpose.INDUSTRIAL, "pipe_manifold"]]:
		var building := _roof(t, Vector2(256, 256), 64, fixture[0])
		var valid := [{"cell": [5, 1], "kind": fixture[1]}]
		t.check(_errors.errors_of(t, {"setup": {"roof_fixtures": [
			{"lot": [1, 2, 8, 8], "fixtures": valid}]}}).is_empty(),
				"current production fixtures pass the public recipe schema")
		t.check(building.author_roof_furniture(valid).is_empty(),
				"wide fixture fits the last two interior columns")
		var authored := RoofReads.units_of(building)
		var cells: Array[Vector2i] = authored[0].cells if authored.size() == 1 else ([] as Array[Vector2i])
		t.check(authored.size() == 1 and authored[0].span == 2 and cells.has(Vector2i(6, 1)),
				"displayed fixture reserves its full base including the east cell")
		var object: Building.RoofObject = _roof_objects_on(building)[0]
		var width := AtlasTable.baked().native_size(object.texture_key).x * object.scale.x
		# Node2D stores the 4/3 room transform in Vector2 float precision.
		t.check(width <= 64.0 or is_equal_approx(width, 64.0),
				"rendered width fits the accepted two-cell reservation")
		for invalid: Array in [[{"cell": [6, 1], "kind": fixture[1]}],
			[valid[0], {"cell": [6, 1], "kind": fixture[1]}]]:
			t.check(not building.author_roof_furniture(invalid).is_empty(),
					"wide fixtures reject edge overflow and east-cell overlap")
			t.check(RoofReads.units_of(building) == authored,
					"failed width validation leaves the complete authored roof unchanged")
		building.residence().set_resident(false)
		building.residence().set_resident(true)
		var standing := _roof_objects_on(building)
		t.check(RoofReads.units_of(building) == authored and standing.size() == 1
				and standing[0].texture_key == authored[0].texture,
				"streaming preserves the enlarged or wide fixture reservation")
		t.check(building.author_roof_furniture([]).is_empty()
				and _roof_objects_on(building).is_empty(), "explicit empty recipe clears all roof objects")
		building.free()

func _joined_authored_ducts(t: TestRunner) -> void:
	var building := _roof(t, Vector2(256, 128), 32, GameEnums.BlockPurpose.INDUSTRIAL)
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

func _test_malformed_recipes_fail_before_construction(t: TestRunner) -> void:
	for roof: Variant in [true, [{"lot": [1, 2], "fixtures": []}],
		[{"lot": [1, 2, 8, 8], "fixtures": [{"cell": [1.5, 2], "kind": "vent"}]}],
		[{"lot": [1, 2, 8, 8], "fixtures": [{"cell": [1, 2], "kind": "unknown"}]}]]:
		t.check(not _errors.errors_of(t, {"setup": {"roof_fixtures": roof}}).is_empty(),
				"malformed roof recipes fail before runtime construction")
	for kind: String in ["duct_run", "_unused_duct_corner"]:
		t.check(not _errors.errors_of(t, {"setup": {"roof_fixtures": [
			{"lot": [1, 2, 8, 8], "fixtures": [{"cell": [1, 2], "kind": kind}]}]}}).is_empty(),
				"internal duct enum values are not leaked into the public recipe schema")
