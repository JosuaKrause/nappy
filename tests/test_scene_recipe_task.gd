extends RefCounted
## A scene recipe's `setup.task`: what the schema accepts, its observations, and an authored mast's
## id. What the runtime installs of an authored mast (the ground the day's masts may stand on) is
## `tests/test_scene_recipe_install.gd`'s, and what the resistance director does with a pinned mark and
## a pinned neighbor is `tests/test_resistance_recipe_task.gd`'s. The scenes' own walks to their
## targets are `tools/scene-recipes.sh`'s headless assertions. Nothing here builds a city: the schema
## is checked through `load_recipe()`.

const RecipeErrors := preload("res://tests/recipe_runtime_errors.gd")
## The context city every task scene is built on, so a mark here is a mark there.
const CONTEXT := 1917501
## The seed `_recipe()` gives a scene, which a recipe boot starts its run on.
const RECIPE_SEED := 11

func run(t: TestRunner) -> void:
	_test_the_schema_names_a_mark_on_the_days_that_have_one(t)
	_test_the_task_observations_ask_about_the_task(t)
	_test_an_authored_mast_carries_its_own_id(t)

func _recipe(day: int, task: Variant, observations := []) -> Dictionary:
	var setup := {"day": day}
	if task != null:
		setup["task"] = task
	return {"version": 1, "name": "task", "seed": RECIPE_SEED, "extent": {"scope": "full"},
		"city": {"context_seed": CONTEXT}, "setup": setup,
		"playback": {"duration": 1, "observations": observations}}

## Where each recipe is written and loaded, and what loading it answers.
var _errors := RecipeErrors.new()

func _refused(t: TestRunner, recipe: Dictionary, words: String) -> bool:
	return _errors.refused(t, recipe, words)

func _test_the_schema_names_a_mark_on_the_days_that_have_one(t: TestRunner) -> void:
	t.check(_refused(t, _recipe(3, {}), "offers no resistance task"),
			"a day before the first mark has no task to start")
	t.check(_refused(t, _recipe(7, {}), "starts at a chalk mark"),
			"a day with a mark needs the mark's place")
	t.check(_errors.errors_of(t, _recipe(7, {"mark": [2960, 2224]})).is_empty(),
			"and accepts it")
	t.check(_refused(t, _recipe(14, {"mark": [2960, 2224]}), "has no chalk mark"),
			"the last night has no mark to place")
	t.check(_errors.errors_of(t, _recipe(14, {})).is_empty(),
			"and starts from its door alone")
	t.check(_refused(t, _recipe(7, {"mark": [2960, 2224], "neighbor": [1936, 4336]}),
			"only day 10's neighbor"), "only day 10's neighbor has a start to pin")
	t.check(_errors.errors_of(t, _recipe(10,
			{"mark": [2128, 4688], "neighbor": [1936, 4336]})).is_empty(), "which day 10 accepts")
	t.check(_refused(t, _recipe(7, {"mark": [2960, 2224], "target": [0, 0]}), "setup.task.target"),
			"an unknown task field is refused")

func _test_the_task_observations_ask_about_the_task(t: TestRunner) -> void:
	var on_the_task := [{"tick": 1, "subject": "task", "condition": "offered"},
			{"tick": 1, "subject": "mark", "condition": "done"},
			{"tick": 1, "subject": "rider", "condition": "beyond", "at": [0, 0], "distance": 576},
			{"tick": 1, "subject": "task", "condition": "off_screen"}]
	t.check(_errors.errors_of(t, _recipe(7, {"mark": [2960, 2224]}, on_the_task))
			.is_empty(), "the task names its mark, its contact and its rider")
	t.check(_refused(t, _recipe(9, {"mark": [2960, 2224]},
			[{"tick": 1, "subject": "rider", "condition": "visible"}]), "not a named actor"),
			"a task on a bare point has no rider")
	t.check(_refused(t, _recipe(7, null, [{"tick": 1, "subject": "player", "condition": "offered"}]),
			"asks about the task's mark or target"), "offered asks only about the task")
	t.check(_errors.errors_of(t, _recipe(3, null, [{"tick": 1, "subject": "player",
			"condition": "clear_of_both_views", "half": [160, 480]}])).is_empty(),
			"a box clear of her view, in either presentation, is asked with its half extents")
	t.check(_refused(t, _recipe(3, null, [{"tick": 1, "subject": "player",
			"condition": "clear_of_both_views"}]), "needs [half width, half height]"),
			"and a view check with no box is refused")
	t.check(_refused(t, _recipe(3, null, [{"tick": 1, "subject": "player", "condition": "visible",
			"half": [1, 1]}]), "belongs to clear_of_both_views"), "the half extents belong to it alone")
	t.check(_refused(t, _recipe(3, null, [{"tick": 1, "subject": "row:nothing", "condition": "visible"}]),
			"row:<catalogue id>"), "a row subject names a catalogue row")
	t.check(_errors.errors_of(t, _recipe(3, null,
			[{"tick": 1, "subject": "row:fire_truck", "condition": "visible"}])).is_empty(),
			"such as the engine a fire calls in")

## A scene recipe gives an authored loudspeaker a `mast_id`, the identity day 11's task and its red
## arrow answer to, so a scene can stand two masts and show the arrow move between them
## (`scene-recipes/task-11-two-masts.json`). Only a loudspeaker is a mast, and one id names one mast.
func _test_an_authored_mast_carries_its_own_id(t: TestRunner) -> void:
	var mast := func(name: String, row: String, id: Variant) -> Dictionary:
		var entry := {"name": name, "row": row, "at": [3440, 1936]}
		if id != null:
			entry["mast_id"] = id
		return entry
	var with := func(events: Array) -> Dictionary:
		var recipe := _recipe(11, {"mark": [2960, 2224]})
		recipe.setup["events"] = events
		return recipe
	t.check(_errors.errors_of(t, with.call([mast.call("a", "loudspeaker", "north"),
			mast.call("b", "loudspeaker", "south")])).is_empty(),
			"two loudspeakers with their own ids are accepted")
	t.check(_refused(t, with.call([mast.call("a", "charging_dog", "north")]),
			"belongs to a loudspeaker row"), "only a loudspeaker is given a mast id")
	t.check(_refused(t, with.call([mast.call("a", "loudspeaker", "north"),
			mast.call("b", "loudspeaker", "north")]), "unique nonempty string"),
			"two masts cannot share an id")
	t.check(_refused(t, with.call([mast.call("a", "loudspeaker", "")]), "unique nonempty string"),
			"an empty id names nothing")
