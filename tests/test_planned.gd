extends RefCounted
## `EventScheduler.Planned`, one placed event: what it says about itself to whoever reads the day,
## checked here once on rows built by hand, with no city generated and no day planned. A region
## door's bodies are made the way `RegionPlanner` makes them, the row its sealed variant and the
## body stood as a door (`Planned.stand_as_a_door()`); the region wall's own body is the
## `roadblock` the wall stands, which is not a door.

func run(t) -> void:
	_test_a_door_body_is_never_against_the_line(t)
	_test_a_door_body_never_blocks_the_way(t)
	_test_the_wall_s_body_says_so(t)
	_test_what_stands_clear_of_it(t)
	_test_which_plans_are_fixed_parts(t)

## A body of the row `id` as the region planner stands it, at `at`.
func _sealed(id: String, at := Vector2(320, 320)) -> EventScheduler.Planned:
	return EventScheduler.Planned.new(SealPlanner.sealed_variant(EventCatalogue.by_id(id), true), at)

## A region door's body: `id` stood as a door.
func _door(id: String) -> EventScheduler.Planned:
	var body := _sealed(id)
	body.stand_as_a_door()
	return body

func _test_a_door_body_is_never_against_the_line(t) -> void:
	for id: String in ["checkpoint_hut", "checkpoint_gate", "checkpoint_post"]:
		var door := _door(id)
		t.check(door.is_door(), "a %s the region planner stands at a door is a door" % id)
		t.check(not door.counts_against_the_line(),
				"and the zero-cost line never has to get past it: a door costs by design (%s)" % id)
	var wall := _sealed("roadblock")
	t.check(not wall.is_door(), "the region wall's own body is not a door")
	t.check(wall.counts_against_the_line(), "and it still counts against the line")
	var unplaced := EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"), Vector2.INF)
	t.check(not unplaced.counts_against_the_line(),
			"a row not yet placed stands nowhere, so it counts against nothing")

func _test_a_door_body_never_blocks_the_way(t) -> void:
	for id: String in ["checkpoint_hut", "checkpoint_gate", "checkpoint_post"]:
		t.check(not _door(id).obstructs(),
				"a %s stood at a door is a crossing she walks through, not a block" % id)
	t.check(_sealed("roadblock").obstructs(), "while the region wall's own body blocks the way")
	t.check(not EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"), Vector2.INF).obstructs(),
			"and a row not yet placed blocks nothing")

func _test_the_wall_s_body_says_so(t) -> void:
	var wall := _sealed("roadblock")
	t.check(not wall.is_in_the_wall(), "a body is not the wall's until it is stood in it")
	wall.stand_in_the_wall()
	t.check(wall.is_in_the_wall() and not wall.is_door(), "and then it is, and still not a door")
	var still := EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"), Vector2(320, 320))
	t.check(still.stands_still() and not still.is_in_the_world() and not still.is_permanent(),
			"a roadblock placed at a point stands still, is not in the world yet and is not a scar")
	var moving := EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"), Vector2(320, 320),
			PackedVector2Array([Vector2(320, 320), Vector2(640, 320)]))
	t.check(not moving.stands_still(), "while a plan with a route moves")

func _test_what_stands_clear_of_it(t) -> void:
	var her := 14.0
	var nothing := EventScheduler.Planned.new(EventDef.new(), Vector2(320, 320))
	t.check(nothing.clearance(her) == 0.0, "an event with no body and no hard fail asks no clearance")
	var body_def := EventDef.new()
	body_def.obstructs_radius = 40.0
	body_def.intensity = 0.0
	var body := EventScheduler.Planned.new(body_def, Vector2(320, 320))
	t.check(is_equal_approx(body.clearance(her), 54.0),
			"a silent body asks its own radius and her whole shape (%.0fpx)" % body.clearance(her))
	var field_def := EventDef.new()
	field_def.obstructs_radius = 40.0
	field_def.intensity = 10.0
	field_def.outer_radius = 200.0
	var field := EventScheduler.Planned.new(field_def, Vector2(320, 320))
	t.check(field.clearance(her) >= field_def.field_reach() and field.clearance(her) > 54.0,
			"a body with a field asks its field (%.0fpx)" % field.clearance(her))
	t.check(body.where_it_stands_now() == Vector2(320, 320),
			"and it stands where it was placed while it is not in the world")


## **Which plans are the city's fixed parts rather than the day's events** (`is_a_fixed_part()`):
## a scar the run left and a loudspeaker mast, whose sections day 13's swap never takes; the day's
## cafe tables and a seal it stood are the day's own.
func _test_which_plans_are_fixed_parts(t) -> void:
	var tables := EventScheduler.Planned.new(EventCatalogue.by_id("cafe_tables"), Vector2(320, 320))
	t.check(not tables.is_a_fixed_part(), "the day's cafe tables are the day's own")
	t.check(not _sealed("barricade").is_a_fixed_part(), "and so is a seal the day stood")
	var scar := _sealed("barricade")
	scar.permanent = true
	t.check(scar.is_a_fixed_part(), "a scar the run left is a fixed part")
	var mast := EventScheduler.Planned.new(EventCatalogue.mast(), Vector2(320, 320))
	mast.mast_id = "a mast's site"
	t.check(mast.is_a_fixed_part(), "and so is a loudspeaker mast")
