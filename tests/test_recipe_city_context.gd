extends RefCounted
## The scene recipe file's form of a city map (`RecipeCityContext`): that an authored scene's saved
## context restores to a map and saves again as the same context, and that what it saves passes
## its own `validate()`.
##
## **Builds the real `CityMap` the task-07 scene's context restores to, because `restore()` answers
## one through the static `CityMap.restored()`, which has no seam for a fake, and the round trip
## `capture(restore(saved))` runs through that map.** The boxing, the run-length tiles and the block
## rows are written from what the real map captures. The map's own capture and restore are
## `tests/test_city_map.gd`'s.

## The authored scene whose saved context is restored and saved again.
const SCENE := "res://scene-recipes/task-07-package.json"

func run(t: TestRunner) -> void:
	_test_a_saved_context_restores_and_saves_the_same(t)
	_test_a_context_carries_no_fact_nothing_reads(t)

## An authored scene's saved context restored, saved again and restored once more saves the same
## context.
func _test_a_saved_context_restores_and_saves_the_same(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var map := RecipeCityContext.restore(data["context"])
	var saved := RecipeCityContext.capture(map)
	t.check(RecipeCityContext.validate(saved).is_empty(), "the saved context passes validation")
	t.check(RecipeCityContext.capture(RecipeCityContext.restore(saved)) == saved,
			"the saved context restores and saves the same")

## A saved context carries only what a map is restored from: a file still holding the power
## station's industrial-block count or the map's own set of dead ends is refused as an unknown field,
## so a stale file fails before it is read.
func _test_a_context_carries_no_fact_nothing_reads(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	for field: String in ["power_station_industrial_blocks", "dead_ends"]:
		var context: Dictionary = (data["context"] as Dictionary).duplicate(true)
		context[field] = 0 if field == "power_station_industrial_blocks" else []
		t.check(RecipeCityContext.validate(context).has("context.%s: unknown field" % field),
				"a saved context holding %s is refused as an unknown field" % field)
