@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## **What the suites that check a recipe's runtime rules share; not a suite.** A recipe is judged
## the way the game judges one: written to a file and loaded by `SceneRecipeRuntime.load_recipe()`,
## which answers the schema's errors, then the runtime's own (setup and playback), and builds the
## recipe's city only if there are none. A test hands in just the part of a recipe it is about, and
## this fills in the rest the schema asks of every recipe.

const _DEFAULT_BOUNDS := [20, 52, 22, 18]

var _written := 0

## The errors loading `recipe` raises: `[]` for a recipe the game would play. The recipe must pass
## the schema (`SceneRecipe.validate()`), so that what a test sees refused was refused by the runtime
## and not by a missing field; that is one check of `t`'s.
func errors_of(t, recipe: Dictionary) -> Array:
	var full := {"version": 1, "name": "probe", "seed": 1, "extent": {"scope": "full"},
			"city": {"context_seed": 1}}
	full.merge(recipe, true)
	var city: Dictionary = full.city
	if not city.has("context_seed"):
		city = city.duplicate()
		city["context_seed"] = 1
		full["city"] = city
	var extent: Dictionary = full.extent
	if extent.get("scope") == "bounded" and not extent.has("bounds"):
		full["extent"] = {"scope": "bounded", "bounds": _DEFAULT_BOUNDS}
	var schema := SceneRecipe.validate(full)
	t.check(schema.is_empty(), "the recipe under test passes the schema: %s" % [schema])
	_written += 1
	var path := "user://recipe_runtime_errors_%d_%d.json" % [OS.get_process_id(), _written]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(full))
	file.close()
	var loaded := SceneRecipeRuntime.load_recipe(path, PackedStringArray())
	DirAccess.remove_absolute(path)
	return loaded.errors

## Whether loading `recipe` raises an error that reads `words`.
func refused(t, recipe: Dictionary, words: String) -> bool:
	return "\n".join(errors_of(t, recipe)).contains(words)
