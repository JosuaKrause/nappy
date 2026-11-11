extends RefCounted
## `EventPlan`, one placed event: what it says about itself to whoever reads the day,
## checked here once on rows built by hand, with no city generated and no day planned. A region
## door's bodies are made the way `RegionPlanner` makes them, the row its sealed variant and the
## body stood as a door (`EventPlan.stand_as_a_door()`); the region wall's own body is the
## `roadblock` the wall stands, which is not a door.

func run(t: TestRunner) -> void:
	_test_a_door_body_is_never_against_the_line(t)
	_test_a_door_body_never_blocks_the_way(t)
	_test_the_wall_s_body_says_so(t)
	_test_what_stands_clear_of_it(t)
	_test_which_plans_are_fixed_parts(t)
	_test_a_walker_is_held_at_the_hut_and_never_at_the_boom(t)
	_test_what_its_field_reaches(t)

## A body of the row `id` as the region planner stands it, at `at`.
func _sealed(id: String, at := Vector2(320, 320)) -> EventPlan:
	return EventPlan.new(SealPlanner.sealed_variant(EventCatalogue.by_id(id), true), at)

## A region door's body: `id` stood as a door.
func _door(id: String) -> EventPlan:
	var body := _sealed(id)
	body.stand_as_a_door()
	return body

func _test_a_door_body_is_never_against_the_line(t: TestRunner) -> void:
	for id: String in ["checkpoint_hut", "checkpoint_gate", "checkpoint_post"]:
		var door := _door(id)
		t.check(door.is_door(), "a %s the region planner stands at a door is a door" % id)
		t.check(not door.counts_against_the_line(),
				"and the zero-cost line never has to get past it: a door costs by design (%s)" % id)
	var wall := _sealed("roadblock")
	t.check(not wall.is_door(), "the region wall's own body is not a door")
	t.check(wall.counts_against_the_line(), "and it still counts against the line")
	var unplaced := EventPlan.new(EventCatalogue.by_id("roadblock"), Vector2.INF)
	t.check(not unplaced.counts_against_the_line(),
			"a row not yet placed stands nowhere, so it counts against nothing")

func _test_a_door_body_never_blocks_the_way(t: TestRunner) -> void:
	for id: String in ["checkpoint_hut", "checkpoint_gate", "checkpoint_post"]:
		t.check(not _door(id).obstructs(),
				"a %s stood at a door is a crossing she walks through, not a block" % id)
	t.check(_sealed("roadblock").obstructs(), "while the region wall's own body blocks the way")
	t.check(not EventPlan.new(EventCatalogue.by_id("roadblock"), Vector2.INF).obstructs(),
			"and a row not yet placed blocks nothing")

func _test_the_wall_s_body_says_so(t: TestRunner) -> void:
	var wall := _sealed("roadblock")
	t.check(not wall.is_in_the_wall(), "a body is not the wall's until it is stood in it")
	wall.stand_in_the_wall()
	t.check(wall.is_in_the_wall() and not wall.is_door(), "and then it is, and still not a door")
	var still := EventPlan.new(EventCatalogue.by_id("roadblock"), Vector2(320, 320))
	t.check(still.stands_still() and not still.is_in_the_world(),
			"a roadblock placed at a point stands still and is not in the world yet")
	var moving := EventPlan.new(EventCatalogue.by_id("roadblock"), Vector2(320, 320),
			PackedVector2Array([Vector2(320, 320), Vector2(640, 320)]))
	t.check(not moving.stands_still(), "while a plan with a route moves")

func _test_what_stands_clear_of_it(t: TestRunner) -> void:
	var her := 14.0
	var nothing := EventPlan.new(EventDef.new(), Vector2(320, 320))
	t.check(nothing.clearance(her) == 0.0, "an event with no body and no hard fail asks no clearance")
	var body_def := EventDef.new()
	body_def.obstructs_radius = 40.0
	body_def.intensity = 0.0
	var body := EventPlan.new(body_def, Vector2(320, 320))
	t.check(is_equal_approx(body.clearance(her), 54.0),
			"a silent body asks its own radius and her whole shape (%.0fpx)" % body.clearance(her))
	var field_def := EventDef.new()
	field_def.obstructs_radius = 40.0
	field_def.intensity = 10.0
	field_def.outer_radius = 200.0
	var field := EventPlan.new(field_def, Vector2(320, 320))
	t.check(field.clearance(her) >= field_def.field_reach() and field.clearance(her) > 54.0,
			"a body with a field asks its field (%.0fpx)" % field.clearance(her))
	t.check(body.where_it_stands_now() == Vector2(320, 320),
			"and it stands where it was placed while it is not in the world")


## **Which plans are the city's fixed parts rather than the day's events** (`is_a_fixed_part()`,
## inbox #1185 in gentle-owl): the region wall's body, a door's, a seal, a loudspeaker mast and an ambient row,
## whose sections day 13's swap never takes; the day's cafe tables, a barricade it rolled rather than
## sealed with, and the burnt shell a fire left, which the player called a regular event, are not.
func _test_which_plans_are_fixed_parts(t: TestRunner) -> void:
	var tables := EventPlan.new(EventCatalogue.by_id("cafe_tables"), Vector2(320, 320))
	t.check(not tables.is_a_fixed_part(), "the day's cafe tables are the day's own")
	t.check(not _sealed("barricade").is_a_fixed_part(),
			"and so is a barricade the seal planner did not stand")
	var shell := EventPlan.new(EventCatalogue.by_id("burnt_shell"), Vector2(320, 320))
	shell.permanent = true
	t.check(not shell.is_a_fixed_part(), "and so is the burnt shell a fire left: a regular event")
	var seal := _sealed("barricade")
	seal.stand_as_a_seal()
	t.check(seal.is_a_fixed_part(), "a seal the day stood is a fixed part")
	var wall := _sealed("roadblock")
	wall.stand_in_the_wall()
	t.check(wall.is_a_fixed_part(), "and so is the region wall's body")
	t.check(_door("checkpoint_hut").is_a_fixed_part(), "and a door's")
	var mast := EventPlan.new(EventCatalogue.mast(), Vector2(320, 320))
	mast.mast_id = "a mast's site"
	t.check(mast.is_a_fixed_part(), "and a loudspeaker mast")
	var playground := EventPlan.new(EventCatalogue.by_id("playground"), Vector2(320, 320))
	t.check(playground.is_a_fixed_part(), "and an ambient row")

## **A walker the crowd holds at a door is held at the gatehouse on its own sidewalk, like her, and
## never on the road** (PLAYTEST-58; `docs/MECHANICS.md`, "The crowd is held at the same
## gatehouses"): `Crowd` builds a walker's door hold at each door body that `detains_her()`, so of a
## door's bodies the hut on each sidewalk and the alley door's post hold a walker, and the boom over
## the road holds nobody, since what stops at it is the cars.
func _test_a_walker_is_held_at_the_hut_and_never_at_the_boom(t: TestRunner) -> void:
	t.check(_door("checkpoint_hut").detains_her() and _door("checkpoint_post").detains_her(),
			"a door's hut and an alley door's post hold a walker")
	t.check(not _door("checkpoint_gate").detains_her(), "the boom over the road holds nobody")

## **Whether its field reaches a point** (`field_reaches()`), from where it stands now: where it was
## placed while it is not in the world, and **measured from its centre**, out to where its row is
## heard.
func _test_what_its_field_reaches(t: TestRunner) -> void:
	var row := EventCatalogue.by_id("alley_robbery")
	var plan := EventPlan.new(row, Vector2(320, 320))
	t.check(plan.field_reaches(Vector2(320, 320) + Vector2(row.heard_within() - 1.0, 0.0)),
			"its field reaches a point just inside where its row is heard")
	t.check(not plan.field_reaches(Vector2(320, 320) + Vector2(row.heard_within() + 1.0, 0.0)),
			"and not one just outside")
