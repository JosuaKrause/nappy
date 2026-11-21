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
	_test_what_it_says_of_its_live_event_is_its_handles_answer(t)
	_test_where_its_body_stands(t)
	_test_a_plan_stands_where_a_candidate_was_judged(t)
	_test_a_plan_turns_to_face(t)

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
	shell.make_permanent()
	t.check(not shell.is_a_fixed_part(), "and so is the burnt shell a fire left: a regular event")
	var seal := _sealed("barricade")
	seal.stand_as_a_seal()
	t.check(seal.is_a_fixed_part(), "a seal the day stood is a fixed part")
	var wall := _sealed("roadblock")
	wall.stand_in_the_wall()
	t.check(wall.is_a_fixed_part(), "and so is the region wall's body")
	t.check(_door("checkpoint_hut").is_a_fixed_part(), "and a door's")
	var mast := EventPlan.new(EventCatalogue.mast(), Vector2(320, 320))
	mast.stand_as_a_mast("a mast's site")
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

## **Whether its field reaches a point** (`field_reaches()`) is its live event's answer while it is
## in the world, whatever shape that field has, and false while it is not.
func _test_what_its_field_reaches(t: TestRunner) -> void:
	var plan := EventPlan.new(EventCatalogue.by_id("alley_robbery"), Vector2(320, 320))
	var point := Vector2(500, 40)
	t.check(not plan.field_reaches(point), "a plan out of the world reaches nothing")
	var standing := FakeStanding.new()
	plan.enter_the_world(standing)
	standing.field_answer = true
	t.check(plan.field_reaches(point), "in the world it reaches where its live event says its field does")
	t.check(standing.asked == point, "and it asks its live event about the point it was given")
	standing.field_answer = false
	t.check(not plan.field_reaches(point), "and not where its live event says it does not")
	plan.leave_the_world(EventSave.new())
	standing.field_answer = true
	t.check(not plan.field_reaches(point), "and once it has left the world it reaches nothing again")

## **A plan is in the world while the handle it was told says there is a live event there**
## (`enter_the_world()`), and says where it stands, which way it faces and whether it is over as that
## event does, until it is told it left (`leave_the_world()`), when it answers as it did before it
## entered: where its siting put it, facing as its siting decided, over for nobody. That it has been
## in the world is true from the first entering for good, and what it was in the middle of is kept.
func _test_what_it_says_of_its_live_event_is_its_handles_answer(t: TestRunner) -> void:
	var at := Vector2(320, 320)
	var plan := EventPlan.new(EventCatalogue.by_id("alley_robbery"), at)
	plan.face(Vector2.UP)
	t.check(not plan.is_in_the_world() and not plan.has_been_in_the_world(),
			"a new plan is not in the world and has not been")
	var standing := FakeStanding.new()
	plan.enter_the_world(standing)
	t.check(plan.is_in_the_world() and plan.has_been_in_the_world(),
			"told its event entered, it is in the world and has been")
	t.check(plan.where_it_stands_now() == standing.place and plan.faces_now() == standing.heading,
			"it stands where its live event stands and faces as it faces")
	t.check(not plan.its_event_is_gone(), "its live event is not over")
	standing.over = true
	t.check(plan.its_event_is_gone(), "and is over when its live event is")
	standing.there = false
	t.check(not plan.is_in_the_world() and plan.where_it_stands_now() == plan.body_at()
			and plan.faces_now() == Vector2.UP and not plan.its_event_is_gone(),
			"a live event that is no longer there leaves it answering from its siting")
	standing.there = true
	var save := EventSave.aged(4.0)
	plan.leave_the_world(save)
	t.check(not plan.is_in_the_world() and plan.has_been_in_the_world() and plan.saved() == save,
			"told it left, it is out of the world, has been in it, and keeps what it was in the middle of")
	t.check(plan.where_it_stands_now() == plan.body_at() and plan.faces_now() == Vector2.UP,
			"and it answers from its siting again")

## A live event's handle, answering as a test sets it: what a plan asks of the event it stands for.
class FakeStanding extends WhereItStands:
	var there := true
	var place := Vector2(11.0, 12.0)
	var heading := Vector2.LEFT
	var over := false
	var field_answer := false
	var asked := Vector2.INF

	## Overrides WhereItStands.is_there.
	func is_there() -> bool:
		return there

	## Overrides WhereItStands.at.
	func at() -> Vector2:
		return place

	## Overrides WhereItStands.facing.
	func facing() -> Vector2:
		return heading

	## Overrides WhereItStands.is_gone.
	func is_gone() -> bool:
		return over

	## Overrides WhereItStands.field_reaches.
	func field_reaches(point: Vector2) -> bool:
		asked = point
		return field_answer

## **Where a plan's body stands** (`EventPlan.body_at()`): a roadblock placed in a carriageway lane
## stands on the kerb beside it (`CityMap.kerb_beside()`), and its geometry reads it there; a
## sidewalk row and the region wall's pinned roadblock stand where they were placed. The lane is the
## inner one of a north-south street, three blocks of tiles past a corridor along it.
func _test_where_its_body_stands(t: TestRunner) -> void:
	var tile := float(Tuning.TILE_SIZE)
	var lane := Vector2((Tuning.SIDEWALK_WIDTH + 0.5) * tile, (Tuning.STREET_WIDTH + 3.5) * tile)
	var kerb := CityMap.kerb_beside(lane)
	t.check(kerb != lane, "the lane point has a kerb beside it")
	var roadblock := EventPlan.new(EventCatalogue.by_id("roadblock"), lane)
	t.check(roadblock.body_at() == kerb and roadblock.placed_at() == lane,
			"a roadblock placed in the lane stands on the kerb beside it, placed where it was put")
	t.check(roadblock.where_it_stands_now() == kerb and is_equal_approx(roadblock.distance_from(kerb), 0.0),
			"and its geometry reads it at the kerb")
	t.check(EventPlan.new(EventCatalogue.by_id("market_stall"), lane).body_at() == lane,
			"a sidewalk row stands where it was placed")
	t.check(_sealed("roadblock", lane).body_at() == lane,
			"and so does the region wall's pinned roadblock")

func _test_a_plan_stands_where_a_candidate_was_judged(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("poster_crew")
	var judged := EventPlan.new(def, Vector2(640, 96),
			PackedVector2Array([Vector2(640, 96), Vector2(704, 96)]))
	judged.face(Vector2.UP)
	judged.give_role(GameEnums.BlockerRole.WALL)
	var owed := EventPlan.new(def, Vector2.INF)
	t.check(not owed.is_placed(), "the plan her walk lays starts with no place")
	owed.stand_where(judged)
	t.check(owed.is_placed() and owed.placed_at() == Vector2(640, 96),
			"it takes the place the candidate was judged at")
	t.check(owed.walks() == judged.walks() and not owed.stands_still(),
			"and the route, so a beat that paces walks the stretch it was judged on")
	t.check(owed.facing == Vector2.UP, "and its facing")
	t.check(owed.role() == GameEnums.BlockerRole.WALL, "and the role the judge gave it")
	t.check(judged.position == Vector2(640, 96) and judged.role() == GameEnums.BlockerRole.WALL,
			"while the candidate is left as it was")

func _test_a_plan_turns_to_face(t: TestRunner) -> void:
	var plan := EventPlan.new(EventCatalogue.by_id("poster_crew"), Vector2(640, 96))
	plan.face(Vector2.UP)
	t.check(plan.facing == Vector2.UP, "a crew turned to face the wall it pastes faces it")
	plan.face(Vector2.LEFT)
	t.check(plan.facing == Vector2.LEFT, "and turns again where it is told to")
