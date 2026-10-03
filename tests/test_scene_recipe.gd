extends RefCounted
const CITY_SCENE := preload("res://scenes/world/city.tscn")

func _recipe() -> Dictionary:
	return {"version": 1, "name": "construction check", "seed": 7,
			"extent": {"scope": "full"}, "city": {"context_seed": 1917501},
			"anchors": {"start": "doorstep"}, "setup": {}, "playback": {}}

func run(t) -> void:
	_test_fixture(t)
	_test_malformed_file(t)
	var input := _recipe()
	var original := RecipeCityBuilder.build(input)
	t.check(original.errors.is_empty(), "ordinary context constructs: %s" % [original.errors])
	if not original.errors.is_empty():
		return
	var map: CityMap = original.map
	_test_closures(t, map)
	var pinned := _recipe()
	pinned.city.dead_ends = [{"segment": [9, 1, 0], "end": "a"}]
	pinned.city.power_station = {"blocks": [8, 1, 2, 1], "door_block": [8, 1]}
	var yard := RecipeCityBuilder.build(pinned)
	t.check(yard.errors.is_empty(), "directly pinned yard join passes production checks: %s" % [yard.errors])
	input["typo"] = true
	t.check(not SceneRecipe.validate(input).is_empty(), "unknown top-level data is rejected")
	input.erase("typo")
	input.city["tiles"] = []
	t.check(not SceneRecipe.validate(input).is_empty(), "post-generation tile patches are unsupported")
	input.city.erase("tiles")
	input.version = 99
	t.check(not SceneRecipe.validate(input).is_empty(), "unsupported versions fail before construction")
	input.version = 1
	input.classification = "fixture"
	input.expected_violations = ["city.guarantee:imaginary failure"]
	t.check(not RecipeCityBuilder.build(input).errors.is_empty(), "fixtures require every expected diagnostic")
	input.erase("classification")
	input.erase("expected_violations")
	input.seed = 9999
	var repeated := RecipeCityBuilder.build(input)
	t.check(repeated.map.tiles == map.tiles, "unrelated runtime seed cannot move construction pins")
	input.city.dead_ends = [{"segment": [5, 6, 0], "end": "a"}]
	t.check(not RecipeCityBuilder.build(input).errors.is_empty(), "home street cannot become an authored dead end")
	input.city.erase("dead_ends")
	input.extent = {"scope": "bounded", "bounds": [112, 0, 34, 56]}
	input.anchors = {"door": "power_station_door"}
	var bounded := RecipeCityBuilder.build(input)
	t.check(bounded.errors.is_empty(), "bounded context retains whole footprints: %s" % [bounded.errors])
	if bounded.errors.is_empty():
		var local: CityMap = bounded.map
		t.check(local.is_walkable(Vector2i(-100, -100)), "bounded exterior permits walking beyond the original world")
		t.check(not local.is_street(Vector2i(-100, -100)), "fallback ground never claims to be a generated street")
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(local)
		t.check(city.scenery_ground_source(Vector2i(-100, -100)) == GroundTiles.ALLEY,
				"exterior uses the plain documented ground texture")
		var station: Building = null
		for building in city.buildings():
			if building.power_station:
				station = building
		t.check(station != null, "bounded rendering includes the real power station")
		if station:
			var extended := 0
			for rows: int in station.roof_extension_rows:
				extended += rows
			t.check(extended > 0, "actual City construction extends the hall roof over its adjoining wall")
		city.free()
	_test_examples(t)

func _test_fixture(t) -> void:
	var input := _recipe()
	input.city.lots = [
		{"blocks": [1, 1, 2, 1], "purpose": "park"},
		{"blocks": [8, 8, 2, 1], "purpose": "park"}]
	var refused := RecipeCityBuilder.build(input)
	t.check(not refused.errors.is_empty(), "normal scenes refuse a context without the mandatory square zone")
	input.classification = "fixture"
	input.expected_violations = ["city.guarantee:no open calm zone is 2 blocks square"]
	var allowed := RecipeCityBuilder.build(input)
	t.check(allowed.errors.is_empty(), "explicit fixture matches the exact violated production guarantee: %s" % [allowed.errors])
	if allowed.errors.is_empty():
		t.check(allowed.manifest.classification == "fixture" and not allowed.manifest.checks.has("full_context_guarantees"),
				"expected failures never receive a normal full-guarantee certificate")
		input.expected_violations.append("city.guarantee:extra")
		t.check(not RecipeCityBuilder.build(input).errors.is_empty(), "extra expected failures cannot silently disappear")

func _test_malformed_file(t) -> void:
	var path := "user://scene-recipe-malformed-test.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\"version\":")
	file.close()
	t.check(not SceneRecipe.load_file(path).errors.is_empty(), "malformed JSON returns a diagnostic without engine errors")
	DirAccess.remove_absolute(path)
	t.check(not SceneRecipe.load_file(path).errors.is_empty(), "missing file returns a diagnostic without engine errors")

func _test_closures(t, map: CityMap) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var planned := ClosurePlanner.plan_day(map, 1, rng)
	t.check(not planned.is_empty(), "closure comparison has a production-selected candidate")
	if planned.is_empty():
		return
	var key := planned[0].segment.key()
	var input := _recipe()
	input.setup.day = 1
	input.city.closures = [{"segment": [key.x, key.y, key.z], "kind": "roadworks"}]
	var accepted := RecipeCityBuilder.build(input)
	t.check(accepted.errors.is_empty(), "authored closure uses the production candidate and invariant: %s" % [accepted.errors])
	input.city.closures[0].kind = "rubble"
	t.check(not RecipeCityBuilder.build(input).errors.is_empty(), "late-game closure cannot be pinned on day one")
	input.city.closures[0] = {"segment": [5, 6, 0], "kind": "roadworks"}
	t.check(not RecipeCityBuilder.build(input).errors.is_empty(), "the home closure exclusion still rejects an exact recipe pin")

func _test_examples(t) -> void:
	for side in ["hall", "yard"]:
		var loaded := SceneRecipe.load_file("res://scene-recipes/power-station-%s.json" % side)
		t.check(loaded.errors.is_empty(), "%s example parses" % side)
		var built := RecipeCityBuilder.build(loaded.data)
		t.check(built.errors.is_empty(), "%s example is a possible normal scene: %s" % [side, built.errors])
		if not built.errors.is_empty():
			continue
		var map: CityMap = built.map
		t.check(map.is_walkable(map.world_to_tile(built.anchors.start)), "%s start is exactly walkable" % side)
		map.recipe_frame_locked = true
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var wall_tile := Vector2i(118 if side == "hall" else 132, 14)
		var found := false
		for building in city.buildings():
			if building.lot.position != wall_tile:
				continue
			found = true
			for covered: bool in building.covered_ground_cols:
				t.check(covered == (side == "hall"), "%s adjoining column has a roof or keeps its facade" % side)
		t.check(found, "%s uses the generator's real adjoining dead-end building" % side)
		var exterior := Rect2(-20000, -20000, 640, 480)
		city.scenery.update(exterior)
		t.check(not city._ground.chunks.is_empty(), "fallback ground streams beyond the original map")
		t.check(city._ground.pending.is_empty(), "scripted scenery drains preparation independent of wall-clock budget")
		city.free()
