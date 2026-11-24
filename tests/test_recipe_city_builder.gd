extends RefCounted
## What `RecipeCityBuilder` builds from a recipe: the tree a recipe relocates across the road is the
## planting's own (a pit moves, a road or an unrelated sidewalk is refused), and the title scene's
## capture stays in its park. The builder builds a map and nothing else, so no city, crowd or event
## is made here: what the city draws of the map is `tests/test_recipe_city_drawing.gd`'s and what the
## crowd does on it is `tests/test_crowd_coverage.gd`'s.

## The diagnostics a builder's answer carries.
func _errors(result: Dictionary) -> Array[String]:
	return result.errors

func run(t: TestRunner) -> void:
	_test_a_tree_moves_across_the_road_and_nothing_else(t)
	_test_the_titles_capture_stays_in_its_park(t)

func _test_a_tree_moves_across_the_road_and_nothing_else(t: TestRunner) -> void:
	var recipe: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-dog.json").data
	var built := RecipeCityBuilder.build(recipe)
	t.check(_errors(built).is_empty(), "opposite-curb tree recipe constructs: %s" % [built.errors])
	if not _errors(built).is_empty():
		return
	var source := Vector2i(50, 74)
	var destination := Vector2i(50, 71)
	var pits := {}
	for tree in StreetTrees.planted(built.map):
		pits[tree.tile] = tree
	t.check(not pits.has(source) and pits.has(destination), "planning moves the original tree pit across the road")
	for target: Array in [[50, 73], [51, 71]]:
		var invalid: Dictionary = recipe.duplicate(true)
		invalid.city.tree_moves[0].to = target
		t.check(not _errors(RecipeCityBuilder.build(invalid)).is_empty(),
				"tree relocation refuses road or unrelated sidewalk")

func _test_the_titles_capture_stays_in_its_park(t: TestRunner) -> void:
	var title: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-title.json").data
	var park := RecipeCityBuilder.build(title)
	var park_map: CityMap = park.map
	var anchors: Dictionary = park.anchors
	var at: Vector2 = anchors.start
	t.check(park_map.tile_at(park_map.world_to_tile(at)) == GameEnums.TileType.PARK,
			"title begins inside the existing park")
	var capture := at + Vector2.DOWN * Tuning.WALK_SPEED * float(title.playback.capture_at)
	t.check(park_map.tile_at(park_map.world_to_tile(capture)) == GameEnums.TileType.PARK,
			"title's moving capture remains inside the park")
