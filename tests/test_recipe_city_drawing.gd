extends RefCounted
## **The real `City` draws the maps a recipe builds**: the power station recipes' bounded context and
## their two examples are built by `RecipeCityBuilder` (`tests/test_scene_recipe.gd`'s) and handed to
## a real `City`, which gives the exterior the plain ground, extends the hall roof over its adjoining
## wall and streams fallback ground beyond the original map. A suite that builds a real `City` and
## combines two modules for a guarantee that spans them: the builder's map is one the city can draw,
## which neither module's own suite can see (the builder has no city to hand it to, and the city's
## suites are handed maps the generator made).
const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2

## The diagnostics a builder's answer carries.
func _errors(result: Dictionary) -> Array[String]:
	return result.errors

func _recipe() -> Dictionary:
	return {"version": 1, "name": "construction check", "seed": 7,
			"extent": {"scope": "full"}, "city": {"context_seed": 1917501},
			"anchors": {"door": "power_station_door"}, "setup": {}, "playback": {}}

func run(t: TestRunner) -> void:
	_test_the_bounded_context(t)
	_test_the_examples(t)

func _test_the_bounded_context(t: TestRunner) -> void:
	var input := _recipe()
	input.extent = {"scope": "bounded", "bounds": [112, 0, 34, 56]}
	var bounded := RecipeCityBuilder.build(input)
	t.check(_errors(bounded).is_empty(), "bounded context retains whole footprints: %s" % [bounded.errors])
	if not _errors(bounded).is_empty():
		return
	var local: CityMap = bounded.map
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
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

func _test_the_examples(t: TestRunner) -> void:
	for side: String in ["hall", "yard"]:
		var loaded := SceneRecipe.load_file("res://scene-recipes/power-station-%s.json" % side)
		var built := RecipeCityBuilder.build(loaded.data)
		if not _errors(built).is_empty():
			t.check(false, "%s example builds: %s" % [side, built.errors])
			continue
		var map: CityMap = built.map
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		city.scenery_frame_locked = true
		t.add_child(city)
		city.build(map)
		var wall_tile := Vector2i(118 if side == "hall" else 132, 14)
		var found := false
		for building in city.buildings():
			if building.lot.position != wall_tile:
				continue
			found = true
			t.check(not building.covered_ground_cols.is_empty(), "%s renders adjoining facade columns" % side)
			for covered: bool in building.covered_ground_cols:
				t.check(covered == (side == "hall"), "%s adjoining column has a roof or keeps its facade" % side)
		t.check(found, "%s uses the generator's real adjoining dead-end building" % side)
		var exterior := Rect2(-20000, -20000, 640, 480)
		city.scenery.update(exterior)
		t.check(not city.scenery_ground.chunks.is_empty(), "fallback ground streams beyond the original map")
		t.check(city.scenery_ground.pending.is_empty(), "scripted scenery drains preparation independent of wall-clock budget")
		city.free()
