extends RefCounted
## What the resistance director does with a scene recipe's pinned task (`start_recipe_task()`): the
## mark stands unread and its task is placed with the director's own placement when it is read, a
## mark is touched only from inside its alley, its guard keeps the mouth's distance, a mark off the
## tile in from an alley mouth is refused rather than moved, a neighbor start the day could not draw
## is refused, and day 11 puts up a mast where none stands. What a recipe's schema accepts and what
## the runtime installs are `tests/test_scene_recipe_task.gd`'s.
##
## **The director stands on its own parts and no city**: a real recipe map (the context city of a
## recipe, built by `RecipeCityBuilder`: where a mark may stand is the map's alleys, and a mark is
## pinned to a tile of that city), today's streets begun from the day's own planners
## (`RouteTree`, the recipe's closures; model data built as it is), a stand-in for the day's events
## (`FakeEventManager`, which answers the guard and the rider the director spawns, and for day 11 a
## mast the director asks it to queue, `MastQueue`), a bare world to stand the contact in
## (`WorldContext`) and no fronts, atlas or crowd. A fresh map each case, since a day's closures are
## recorded on it.

const AlleyMarks := preload("res://tests/alley_marks.gd")
const ContactTouches := preload("res://tests/contact_touches.gd")
const ResistanceReads := preload("res://tests/resistance_reads.gd")
## The context city every task scene is built on, so a mark here is a mark there.
const CONTEXT := 1917501
## An alley mouth of that city, the mark most task scenes start at.
const MOUTH := Vector2i(92, 69)
## The tile one step into that alley from the mouth, where its mark stands.
const MARK := Vector2i(92, 68)
## The seed a recipe boot starts its run on.
const RECIPE_SEED := 11

## The stand-in for the day's events on day 11: the mast the director asks it to queue
## (`queue_a_mast()`), which it lays on the first tile offered and then answers as the day's plan
## (`plans()`) and a foot (`mast_foot()`), the way the real manager does once it accepts a tile.
## What the real manager accepts is `tests/test_masts.gd`'s.
class MastQueue:
	extends FakeEventManager

	var _map: CityMap
	var _masts: Array[EventPlan] = []

	func _init(on: CityMap) -> void:
		super()
		_map = on

	## Lays a mast on the first of `offered`, null when nothing is offered.
	##
	## Overrides EventManager.queue_a_mast.
	func queue_a_mast(offered: Array[Vector2i]) -> EventPlan:
		if offered.is_empty():
			return null
		var plan := EventPlan.new(EventCatalogue.shipped().mast(), _map.tile_to_world(offered[0]))
		plan.stand_as_a_mast(DawnMasts.added_mast_id(plan.placed_at()))
		_masts.append(plan)
		return plan

	## Overrides FakeEventManager.plans.
	func plans() -> Array[EventPlan]:
		return _masts

	## Overrides EventManager.mast_foot.
	func mast_foot(mast_id: String) -> Vector2:
		for plan in _masts:
			if plan.mast_id() == mast_id:
				return plan.placed_at()
		return Vector2.INF

## A day's stand: the map, the run, the events, the world and the director over them.
class Stand:
	var map: CityMap
	var run: RunState
	var events: MastQueue
	var world: WorldContext
	var director: ResistanceDirector

	func free_all() -> void:
		director.free()
		events.free()
		world.free()

func run(t: TestRunner) -> void:
	_test_a_pinned_mark_is_read_and_its_task_placed_near_it(t)
	await _test_a_mark_is_touched_only_from_inside_its_alley(t)
	_test_a_mark_one_tile_in_keeps_its_guard_as_far_as_at_the_mouth(t)
	_test_a_mark_off_the_tile_in_from_a_mouth_is_refused_not_moved(t)
	_test_a_neighbor_start_the_day_could_not_draw_is_refused(t)
	_test_day_eleven_puts_up_a_mast_where_no_mast_stands_at_all(t)

## The context city on `day` as a recipe starts it (the authored closures, no catalogue fill), in a
## run of its own on that day, and a director over it. The recipe stands no region wall, as
## `SceneRecipeRuntime._select_structures()` leaves the day's plan when it selects no gate or barrier.
## `Stand.free_all()` frees the director, the events and the world.
func _day(t: TestRunner, day: int) -> Stand:
	var built := RecipeCityBuilder.build(EventCatalogue.shipped(), {"version": 1, "name": "task", "seed": RECIPE_SEED,
			"extent": {"scope": "full"}, "city": {"context_seed": CONTEXT}})
	var errors: Array[String] = built.errors
	t.check(errors.is_empty(), "the context city builds: %s" % [errors])
	var stand := Stand.new()
	stand.map = built.map
	stand.run = RunState.new()
	stand.run.start_run(RECIPE_SEED)
	stand.run.header().set_day(day)
	var state := stand.run.attempt_spend().block_arcs()
	state.reset()
	state.begin_day(stand.map.plans_by_block(), day)
	stand.map.repaint(state)
	var edges := stand.map.witness_only()
	var tree := RouteTree.for_day(stand.map, day, null)
	stand.map.restore_edges(edges)
	var closures: Array[RoadClosure] = stand.map.recipe_road_closures().duplicate()
	var streets := DayStreets.new()
	streets.begin_day(tree, RegionPlan.new(), closures)
	stand.map.close_streets(closures)
	stand.events = MastQueue.new(stand.map)
	stand.world = WorldContext.new()
	t.add_child(stand.world)
	stand.director = ResistanceDirector.new()
	t.add_child(stand.director)
	stand.director.set_process(false)
	stand.director.setup(EventCatalogue.shipped(), stand.map, stand.run, stand.events, streets, null, stand.world)
	return stand

func _test_a_pinned_mark_is_read_and_its_task_placed_near_it(t: TestRunner) -> void:
	var stand := _day(t, 7)
	var director := stand.director
	var own_run := stand.run
	var map := stand.map
	var mark := map.tile_to_world(MARK)
	var errors := director.start_recipe_task(7, own_run.calendar().day_rng(7, "resistance"), 300.0, mark)
	t.check(errors.is_empty(), "a mark one tile in from an alley mouth is accepted: %s" % [errors])
	# *(Inbox #555, "Unread, walk to it".)* The scene begins with the mark standing unread and no
	# task on offer; a touch reads it and the task is placed then.
	t.check(director.read_mark() == null and director.contact() != null
			and director.contact().task_step().is_pickup and not director.contact().is_finished()
			and director.contact().global_position == mark,
			"the mark stands where the recipe put it, unread")
	t.check(director.current_step().is_pickup and director.red_arrow_target() == Vector2.INF
			and director.contact_position() == mark,
			"no task is on offer and no arrow is drawn before she reads it")
	t.check(not own_run.resistance().completed_steps().has(director.current_step().index),
			"nothing is completed at the start")
	director.contact().complete_now()
	var task := director.current_step()
	t.check(director.read_mark() != null and director.read_mark().global_position == mark
			and director.read_mark().is_finished(), "reading it leaves the mark standing, read")
	t.check(task != null and task.task_event_id == "delivery_van" and not task.is_pickup,
			"and the day's task is on offer")
	var target := director.contact_position()
	t.check(target.distance_to(mark) >= ResistanceDirector.NEAR_THE_MARK
			and target.distance_to(mark) < ResistanceDirector.NEAR_THE_MARK + Tuning.TILE_SIZE,
			"placed where a path from the mark first reaches the circle round her (%.0fpx)"
			% target.distance_to(mark))
	t.check(director.red_arrow_target() == target, "with its arrow on the van")
	stand.free_all()

## *(feathery-hare; azure-puffin, inbox #664: "let's move the chalk mark one tile into the alley so
## I actually have to enter the alley to activate it".)* The mark's centre is 48px in from the
## street's edge and a touch reaches 36px: her centre 14px inside the alley (her body wholly past the
## edge) touches it, standing on the pavement at the mouth, body wholly outside, does not, nor does
## the centre on the street's edge.
func _test_a_mark_is_touched_only_from_inside_its_alley(t: TestRunner) -> void:
	var stand := _day(t, 7)
	var director := stand.director
	var own_run := stand.run
	var map := stand.map
	var mark := map.tile_to_world(MARK)
	var errors := director.start_recipe_task(7, own_run.calendar().day_rng(7, "resistance"), 300.0, mark)
	t.check(errors.is_empty(), "the mark is accepted: %s" % [errors])
	var outward := Vector2(MOUTH - MARK)
	var street_edge := mark + outward * Tuning.TILE_SIZE * 1.5
	var body := Tuning.PLAYER_BODY_RADIUS
	var touched := ContactTouches.touches_from(director, [street_edge - outward * body,
			street_edge + outward * body, street_edge] as Array[Vector2])
	t.check(touched[0],
			"standing in the alley, her body wholly past the street's edge, touches the mark")
	t.check(not touched[1],
			"standing on the pavement at the mouth, her body wholly outside it, does not")
	t.check(not touched[2],
			"nor does her centre on the street's edge")
	stand.free_all()

## The guard keeps his distance from the mark (M213's floor and quiet-yak's "Two-thirds wins" weigh
## exactly as before): a mark one tile in has him one tile further in than two-thirds through from the
## mouth, the spot a mark on the mouth would have had, worked out from the map (`AlleyMarks`), so he
## stands as far from the mark as he would from a mark on the mouth. The mark is pinned and its guard,
## stood with it at dawn, read off the street.
func _test_a_mark_one_tile_in_keeps_its_guard_as_far_as_at_the_mouth(t: TestRunner) -> void:
	var stand := _day(t, 7)
	var director := stand.director
	var own_run := stand.run
	var map := stand.map
	var at_mouth := map.tile_to_world(MOUTH)
	var at_mark := map.tile_to_world(MARK)
	var errors := director.start_recipe_task(7, own_run.calendar().day_rng(7, "resistance"), 300.0, at_mark)
	t.check(errors.is_empty(), "the mark is accepted: %s" % [errors])
	var guards: Array[Vector2] = []
	for instance in stand.events.instances():
		if instance.row_id() == EventCatalogue.shipped().mark_guard().id() and not instance.is_gone():
			guards.append(instance.global_position)
	var robbery := EventCatalogue.shipped().mark_guard()
	var for_the_mouth := AlleyMarks.expected_guard_spot(map, MOUTH, at_mouth,
			robbery.core_within() + ContactPoint.REACH)
	t.check(guards.size() == 1 and for_the_mouth != Vector2.INF, "the mark's guard stands in the street")
	if guards.size() != 1:
		stand.free_all()
		return
	var from_mark := guards[0]
	t.check(absf(for_the_mouth.distance_to(at_mouth) - from_mark.distance_to(at_mark)) < 0.5,
			"at the same distance from the mark as from a mark on the mouth (%.1fpx, %.1fpx)"
			% [for_the_mouth.distance_to(at_mouth), from_mark.distance_to(at_mark)])
	t.check(absf(from_mark.distance_to(for_the_mouth) - Tuning.TILE_SIZE) < 0.5
			and (from_mark - for_the_mouth).dot(at_mark - at_mouth) > 0.0,
			"one tile further in")
	stand.free_all()

func _test_a_mark_off_the_tile_in_from_a_mouth_is_refused_not_moved(t: TestRunner) -> void:
	var stand := _day(t, 7)
	var director := stand.director
	var own_run := stand.run
	var map := stand.map
	var inside := MOUTH + Vector2i.UP * 3
	t.check(map.tile_at(inside) == GameEnums.TileType.ALLEY
			and not AlleyMarks.is_a_mouth(map, inside),
			"the probe stands inside the mark's own alley, not at its mouth")
	var errors := director.start_recipe_task(7, own_run.calendar().day_rng(7, "resistance"), 300.0,
			map.tile_to_world(inside))
	t.check("\n".join(errors).contains("is not one tile in from an alley mouth"),
			"a mark in the middle of an alley is refused: %s" % [errors])
	t.check(director.current_step() == null, "and nothing is offered in its place")
	errors = director.start_recipe_task(7, own_run.calendar().day_rng(7, "resistance"), 300.0,
			map.tile_to_world(MOUTH))
	t.check("\n".join(errors).contains("is not one tile in from an alley mouth"),
			"and so is one on the mouth's own tile: %s" % [errors])
	stand.free_all()

func _test_a_neighbor_start_the_day_could_not_draw_is_refused(t: TestRunner) -> void:
	var stand := _day(t, 10)
	var director := stand.director
	var own_run := stand.run
	var map := stand.map
	var mark := map.tile_to_world(AlleyMarks.mark_tile_of_mouth(map, Vector2i(66, 146)))
	# A sidewalk a block from her door: a few tiles of walk from home, nowhere near the band of
	# about `ResistanceDirector.NEIGHBOR_WALK_HOME_SECONDS` of walk the day draws a start from.
	var near_home := Vector2i(62, 84)
	t.check(map.tile_at(near_home) == GameEnums.TileType.SIDEWALK, "the probe stands on a sidewalk")
	var errors := director.start_recipe_task(10, own_run.calendar().day_rng(10, "resistance"), 300.0, mark,
			map.tile_to_world(near_home))
	t.check(errors.is_empty(), "the mark is accepted; the neighbor is drawn when she reads it")
	director.contact().complete_now()
	errors = director.scene_task_errors()
	t.check("\n".join(errors).contains("is not a start the day could draw"),
			"a neighbor start the day's draw could not make is refused: %s" % [errors])
	t.check(director.current_step() == null or director.current_step().is_pickup
			or director.rider() == null, "and no neighbor is sent home in its place")
	stand.free_all()

## *(Inbox #486: "Now just add a new mast close by".)* A recipe installs no mast it does not name, so
## day 11 meets a city with no live mast at all — which is still no mast near her, and one is put up
## where her path first reaches the circle round her.
func _test_day_eleven_puts_up_a_mast_where_no_mast_stands_at_all(t: TestRunner) -> void:
	var stand := _day(t, 11)
	var director := stand.director
	var own_run := stand.run
	var mark := stand.map.tile_to_world(MARK)
	var errors := director.start_recipe_task(11, own_run.calendar().day_rng(11, "resistance"), 300.0, mark)
	t.check(errors.is_empty(), "day 11's mark is accepted: %s" % [errors])
	director.contact().complete_now()
	t.check(director.scene_task_errors().is_empty() and director.current_step() != null
			and not director.current_step().is_pickup,
			"and its task finds a mast with none standing: %s" % [director.scene_task_errors()])
	var mast := ResistanceReads.mast_at(director, stand.events)
	var foot := stand.events.mast_foot(mast)
	t.check(mast != "" and foot != Vector2.INF
			and foot.distance_to(mark) >= ResistanceDirector.NEAR_THE_MARK,
			"a mast put up for it on the circle round her")
	stand.free_all()
