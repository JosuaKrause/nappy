extends RefCounted
## The crowd against a real city: the field around the player, lanes and headways, the morning's unpacking and how the crowd is drawn.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/crowd_rig.gd`.
##
## And the field on a scene's stretch, which needs no city: the map is the one data a recipe
## builds (`RecipeCityBuilder.build()`, task 7's stretch), and the field is `CrowdField`'s own
## over it.

const Rig := preload("res://tests/crowd_rig.gd")
const SCENE := "res://scene-recipes/task-07-package.json"

## The diagnostics a builder's answer carries.
func _diagnostics(result: Dictionary) -> Array[String]:
	return result.errors

func run(t: TestRunner) -> void:
	var rig := Rig.new()
	await rig.run_part(t, "field")
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var built := RecipeCityBuilder.build(Shipped.rows(), data)
	t.check(_diagnostics(built).is_empty(),
			"day 7's stretch loads explicit context: %s" % [built.errors])
	if not _diagnostics(built).is_empty():
		return
	var map: CityMap = built.map
	_test_the_crowd_enters_at_the_ends(t, map)

func _test_the_crowd_enters_at_the_ends(t: TestRunner, map: CityMap) -> void:
	var field := CrowdField.new(map, Vector2.ZERO)
	field.use_stretch()
	var ends := field.ends_of_the_stretch()
	t.check(not ends.is_empty(), "the stretch has ends where its streets run into the void")
	var sound := true
	for end in ends:
		var step := Vector2i.DOWN if end.vertical else Vector2i.RIGHT
		var inward := step * int(end.direction)
		var lane_end := false
		for offset in Tuning.STREET_WIDTH:
			var cross := int(end.corridor) * CityMap.period() + offset
			var at := Vector2i(cross,
					int(end.along)) if end.vertical else Vector2i(int(end.along), cross)
			var run := 0
			while map.in_stretch(at + inward * run):
				run += 1
			lane_end = lane_end or (map.is_cut_off(at - inward) and run > Tuning.STREET_WIDTH)
		sound = sound and lane_end
	t.check(sound,
			"each end is a lane end with void beyond it and more than a junction behind it")
	var looking := Vector2(123, 456)
	field.centre_on(looking)
	t.check(field.has_stretch() and field.looking_at() == looking
			and field.centre_point() != looking,
			"the field stays over the whole stretch while the camera moves")
