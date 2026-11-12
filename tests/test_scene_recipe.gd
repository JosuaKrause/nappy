extends RefCounted
## What `RecipeCityBuilder` and `SceneRecipe` accept and refuse, read off the map they answer with. The
## real `City` drawing a built map is `tests/test_recipe_city_drawing.gd`.

## The diagnostics a builder's or loader's answer carries.
func _errors(result: Dictionary) -> Array:
	return result.errors

func _recipe() -> Dictionary:
	return {"version": 1, "name": "construction check", "seed": 7,
			"extent": {"scope": "full"}, "city": {"context_seed": 1917501},
			"anchors": {"start": "doorstep"}, "setup": {}, "playback": {}}

func run(t: TestRunner) -> void:
	_test_fixture(t)
	_test_malformed_file(t)
	var input := _recipe()
	var original := RecipeCityBuilder.build(input)
	t.check(_errors(original).is_empty(), "ordinary context constructs: %s" % [original.errors])
	if not _errors(original).is_empty():
		return
	var map: CityMap = original.map
	_test_station_pins(t)
	_test_closures(t, map)
	var pinned := _recipe()
	pinned.city.dead_ends = [{"segment": [9, 1, 0], "end": "a"}]
	pinned.city.power_station = {"blocks": [8, 1, 2, 1], "door_block": [8, 1]}
	var yard := RecipeCityBuilder.build(pinned)
	t.check(_errors(yard).is_empty(), "directly pinned yard join passes production checks: %s" % [yard.errors])
	# A layout pin remains meaningful in both contexts. Structural pins can become
	# ineligible when unrelated calm/route geometry changes, and must then be refused.
	var layout_pin := _recipe()
	layout_pin.city.lots = [{"blocks": [5, 5, 1, 1], "purpose": "residential"}]
	layout_pin.city.layouts = [{"block": [5, 5], "seed": 123}]
	var first_context := RecipeCityBuilder.build(layout_pin)
	layout_pin.city.context_seed = 61400
	var other_context := RecipeCityBuilder.build(layout_pin)
	t.check(_errors(first_context).is_empty() and _errors(other_context).is_empty(),
			"different construction contexts accept the same explicit lot/layout: %s / %s" % [first_context.errors, other_context.errors])
	if _errors(first_context).is_empty() and _errors(other_context).is_empty():
		var first: Array[Rect2i] = []
		var other: Array[Rect2i] = []
		var first_map: CityMap = first_context.map
		var other_map: CityMap = other_context.map
		var lot := first_map.lot_rect(Vector2i(5, 5))
		for footprint: Rect2i in first_map.building_rects:
			if lot.encloses(footprint):
				first.append(footprint)
		for footprint: Rect2i in other_map.building_rects:
			if lot.encloses(footprint):
				other.append(footprint)
		t.check(not first.is_empty() and first == other,
				"explicit building layout survives changed random construction context")
		t.check(first_map.tiles != other_map.tiles, "unpinned construction changes with its context seed")
	pinned.city.context_seed = 61400
	t.check(not _errors(RecipeCityBuilder.build(pinned)).is_empty(),
			"changed context refuses ineligible station/dead-end pins instead of moving them")
	input["typo"] = true
	t.check(not SceneRecipe.validate(input).is_empty(), "unknown top-level data is rejected")
	input.erase("typo")
	var city: Dictionary = input.city
	city["tiles"] = []
	t.check(not SceneRecipe.validate(input).is_empty(), "post-generation tile patches are unsupported")
	city.erase("tiles")
	input.version = 99
	t.check(not SceneRecipe.validate(input).is_empty(), "unsupported versions fail before construction")
	input.version = 1
	input.classification = "fixture"
	input.expected_violations = ["city.guarantee:imaginary failure"]
	t.check(not _errors(RecipeCityBuilder.build(input)).is_empty(), "fixtures require every expected diagnostic")
	input.erase("classification")
	input.erase("expected_violations")
	input.seed = 9999
	var repeated := RecipeCityBuilder.build(input)
	t.check(repeated.map.tiles == map.tiles, "unrelated runtime seed cannot move construction pins")
	city.dead_ends = [{"segment": [5, 6, 0], "end": "a"}]
	t.check(not _errors(RecipeCityBuilder.build(input)).is_empty(), "home street cannot become an authored dead end")
	city.erase("dead_ends")
	input.extent = {"scope": "bounded", "bounds": [112, 0, 34, 56]}
	input.anchors = {"door": "power_station_door"}
	var bounded := RecipeCityBuilder.build(input)
	t.check(_errors(bounded).is_empty(), "bounded context retains whole footprints: %s" % [bounded.errors])
	if _errors(bounded).is_empty():
		var local: CityMap = bounded.map
		t.check(local.is_walkable(Vector2i(-100, -100)), "bounded exterior permits walking beyond the original world")
		t.check(not local.is_street(Vector2i(-100, -100)), "fallback ground never claims to be a generated street")
	_test_examples(t)

func _test_station_pins(t: TestRunner) -> void:
	var input := _recipe()
	input.city.power_station = {"blocks": [8, 1, 2, 1], "door_block": [9, 1]}
	var accepted := RecipeCityBuilder.build(input)
	t.check(_errors(accepted).is_empty(), "another eligible station door is honored: %s" % [accepted.errors])
	if _errors(accepted).is_empty():
		t.check(accepted.map.power_station_door_key == Vector3i(9, 2, 0),
				"requested east door owns the station street before region dependents")
	input.city.power_station.door_block = [7, 1]
	t.check(not _errors(RecipeCityBuilder.build(input)).is_empty(),
			"a door outside the station pair is refused without choosing another door")
	input.city.power_station = {"blocks": [2, 1, 2, 1], "door_block": [2, 1]}
	accepted = RecipeCityBuilder.build(input)
	t.check(_errors(accepted).is_empty(), "eligible authored pair overrides industrial preference: %s" % [accepted.errors])
	if _errors(accepted).is_empty():
		t.check(accepted.map.power_station == Rect2i(2, 1, 2, 1),
				"explicit station footprint survives candidate ranking")

func _test_fixture(t: TestRunner) -> void:
	var input := _recipe()
	input.city.lots = [
		{"blocks": [1, 1, 2, 1], "purpose": "park"},
		{"blocks": [8, 8, 2, 1], "purpose": "park"}]
	var refused := RecipeCityBuilder.build(input)
	t.check(not _errors(refused).is_empty(), "normal scenes refuse a context without the mandatory square zone")
	input.classification = "fixture"
	input.expected_violations = ["city.guarantee:no open calm zone is 2 blocks square"]
	var allowed := RecipeCityBuilder.build(input)
	t.check(_errors(allowed).is_empty(), "explicit fixture matches the exact violated production guarantee: %s" % [allowed.errors])
	if _errors(allowed).is_empty():
		var manifest: Dictionary = allowed.manifest
		var checks: Array = manifest.checks
		t.check(manifest.classification == "fixture" and not checks.has("full_context_guarantees"),
				"expected failures never receive a normal full-guarantee certificate")
		var expected: Array = input.expected_violations
		expected.append("city.guarantee:extra")
		t.check(not _errors(RecipeCityBuilder.build(input)).is_empty(), "extra expected failures cannot silently disappear")

func _test_malformed_file(t: TestRunner) -> void:
	var path := "user://scene-recipe-malformed-test.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\"version\":")
	file.close()
	t.check(not _errors(SceneRecipe.load_file(path)).is_empty(), "malformed JSON returns a diagnostic without engine errors")
	DirAccess.remove_absolute(path)
	t.check(not _errors(SceneRecipe.load_file(path)).is_empty(), "missing file returns a diagnostic without engine errors")

func _test_closures(t: TestRunner, map: CityMap) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var planned := ClosurePlanner.plan_day(map, DaySpec.for_day(1), rng)
	t.check(not planned.is_empty(), "closure comparison has a production-selected candidate")
	if planned.is_empty():
		return
	var key := planned[0].segment.key()
	var input := _recipe()
	input.setup.day = 1
	input.city.closures = [{"segment": [key.x, key.y, key.z], "kind": "roadworks"}]
	var accepted := RecipeCityBuilder.build(input)
	t.check(_errors(accepted).is_empty(), "authored closure uses the production candidate and invariant: %s" % [accepted.errors])
	input.city.closures[0].kind = "rubble"
	t.check(not _errors(RecipeCityBuilder.build(input)).is_empty(), "late-game closure cannot be pinned on day one")
	input.city.closures[0] = {"segment": [5, 6, 0], "kind": "roadworks"}
	t.check(not _errors(RecipeCityBuilder.build(input)).is_empty(), "the home closure exclusion still rejects an exact recipe pin")

func _test_examples(t: TestRunner) -> void:
	for side: String in ["hall", "yard"]:
		var loaded := SceneRecipe.load_file("res://scene-recipes/power-station-%s.json" % side)
		t.check(_errors(loaded).is_empty(), "%s example parses" % side)
		var built := RecipeCityBuilder.build(loaded.data)
		t.check(_errors(built).is_empty(), "%s example is a possible normal scene: %s" % [side, built.errors])
		if not _errors(built).is_empty():
			continue
		var map: CityMap = built.map
		t.check(map.is_walkable(map.world_to_tile(built.anchors.start)), "%s start is exactly walkable" % side)
