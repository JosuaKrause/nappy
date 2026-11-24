class_name RecipeManifest
extends RefCounted
## **What a suite reads of a scene recipe's runtime from outside**: the manifest the runtime writes
## to the file `--recipe-manifest PATH` names (`RunConfig.recipe_manifest_path()`), a JSON object it
## rewrites at `begin()`, at a capture, at the end, when the task's mark is read or expires, and at
## every failure, and its clock (`SceneRecipeRuntime.elapsed()`). A helper, not a suite: the runner
## loads only `test_*.gd`.

## A scratch path for a manifest, one per process and `label`, in the user folder the suites share
## and never the player's save.
static func scratch_path(label: String) -> String:
	return "user://recipe_manifest_%s_%d.json" % [label, OS.get_process_id()]

## The manifest at `path`, or an empty dictionary where there is none yet or it is not an object.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed := JSON.new()
	if parsed.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var data: Variant = parsed.data
	return data if data is Dictionary else {}

## Takes the manifest at `path` away, so a suite leaves the user folder as it found it.
static func remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## The physics ticks `runtime` has counted, off its clock.
static func ticks_of(runtime: SceneRecipeRuntime) -> int:
	return roundi(runtime.elapsed() * Engine.physics_ticks_per_second)
