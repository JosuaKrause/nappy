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

## An authored scene's saved context restored, saved again and restored once more saves the same
## context.
func _test_a_saved_context_restores_and_saves_the_same(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var map := RecipeCityContext.restore(data["context"])
	var saved := RecipeCityContext.capture(map)
	t.check(RecipeCityContext.validate(saved).is_empty(), "the saved context passes validation")
	t.check(RecipeCityContext.capture(RecipeCityContext.restore(saved)) == saved,
			"the saved context restores and saves the same")
