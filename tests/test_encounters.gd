@warning_ignore_start("unsafe_method_access")
extends RefCounted
## The page's counter's encounters and bouts of running (`EncounterWatch`) *(misty-newt, the
## player: "how frequent do certain events actually appear and are players avoiding them or
## ignoring them?" — "mostly I'm interested in the ratio of interacted/seen")*: what one encounter
## is, when it is seen and when it is meaningful, and what a bout of running is. The names
## `VisitCounter` sends for each are `tests/test_visit_counter.gd`'s.
##
## Most of it drives a watch directly with instances standing at known places and a view moved
## about them, which is the whole of what it reads; the last test drives a real `EventManager` with
## her in a real city, for the wiring.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2
const SEED := 4242
const STEP := 1.0 / 60.0
const DAY := 5
const VIEW_SIZE := Tuning.VIEW_HALF_EXTENT * 2.0

var _seen: Array[String] = []
var _influenced: Array[String] = []
var _ran: Array[int] = []

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	var on_seen := func(day: int, name: String) -> void: _seen.append("%d:%s" % [day, name])
	var on_influenced := func(day: int, name: String, seen: bool) -> void:
		_influenced.append("%d:%s:%s" % [day, name, "seen" if seen else "unseen"])
	var on_ran := func(day: int) -> void: _ran.append(day)
	EventBus.encounter_seen.connect(on_seen)
	EventBus.encounter_influenced.connect(on_influenced)
	EventBus.run_bout_began.connect(on_ran)

	_test_one_encounter_is_one_seen(t)
	_test_coming_back_after_the_gap_is_a_second_encounter(t)
	_test_coming_back_inside_the_gap_is_the_same_encounter(t)
	_test_a_sliver_at_the_edge_is_not_seen(t)
	_test_the_joystick_corners_are_not_visible(t)
	_test_a_thing_under_the_joystick_controls_is_not_seen(t)
	_test_a_tenth_of_the_meter_is_one_influence_per_encounter(t)
	_test_an_influence_from_off_screen_waits_to_be_seen(t)
	_test_a_chase_or_a_catch_is_always_an_influence(t)
	_test_influenced_follows_the_real_catch_and_hold(t)
	await _test_a_catch_on_the_frame_a_door_releases_her_counts(t)
	_test_a_static_row_is_seen_and_never_influenced(t)
	_test_two_instances_are_two_encounters(t)
	_test_runs_less_than_the_gap_apart_are_one_bout(t)
	await _test_the_manager_tells_the_encounter_under_its_day(t)
	await _test_the_manager_reads_the_controls_scheme(t)

	EventBus.encounter_seen.disconnect(on_seen)
	EventBus.encounter_influenced.disconnect(on_influenced)
	EventBus.run_bout_began.disconnect(on_ran)

func _clear() -> void:
	_seen.clear()
	_influenced.clear()
	_ran.clear()

## A manager over a bare map and a run of its own, handed in as the escape's building is handed its
## world (`EventManager.setup_world()`), in the tree. `_free_manager()` frees it.
func _manager(t: TestRunner) -> EventManager:
	var run := RunState.new()
	run.start_run(SEED)
	var map := CityMap.new()
	# The world the map is drawn in, as the city and the building hand theirs: the layer a
	# spawned event is added to (`WorldMap.add_entity()`).
	var holder := WorldContext.new()
	t.add_child(holder)
	map.world = holder
	var manager := EventManager.new()
	manager.setup_world(map, run)
	t.add_child(manager)
	return manager

func _free_manager(manager: EventManager) -> void:
	var holder := manager.world.map.world
	manager.free()
	holder.free()

## A watch for day `DAY`.
func _watch() -> EncounterWatch:
	var watch := EncounterWatch.new()
	watch.day = DAY
	return watch

## An instance of the row `id` standing at `at`, in the tree and never ticking on its own.
func _instance(t: TestRunner, id: String, at: Vector2) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id(id), at)
	t.add_child(instance)
	instance.set_process(false)
	return instance

## The view `Tuning.VIEW_HALF_EXTENT` about `centre`, as `EventManager` hands it over.
static func _view(centre: Vector2) -> Rect2:
	return Rect2(centre - Tuning.VIEW_HALF_EXTENT, VIEW_SIZE)

## `seconds` of frames of `watch`, with the view about `centre` and her standing at its centre.
func _run(watch: EncounterWatch, instances: Array[EventInstance], centre: Vector2, seconds: float,
		running := false, joystick := false) -> void:
	var visible := _visible(centre, joystick)
	for _i in int(round(seconds / STEP)):
		watch.tick(STEP, instances, visible, centre, running)

## What she can see with the view about `centre`, in the joystick scheme or not.
static func _visible(centre: Vector2, joystick := false) -> VisibleView:
	var visible := VisibleView.new()
	visible.look(_view(centre), TouchCover.joystick() if joystick else null)
	return visible

## Far enough from any instance near the origin that nothing of it is in view.
const AWAY := Vector2(2000.0, 0.0)

func _test_one_encounter_is_one_seen(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	_run(watch, instances, AWAY, 1.0)
	t.check(_seen.is_empty(), "nothing is seen while it is out of view")
	_run(watch, instances, Vector2.ZERO, 3.0)
	t.check(_seen == ["%d:homeless_yeller" % DAY],
			"three seconds in full view are one seen, carrying the day and the row (%s)" % [_seen])
	yeller.free()

func _test_coming_back_after_the_gap_is_a_second_encounter(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	_run(watch, instances, Vector2.ZERO, 1.0)
	_run(watch, instances, AWAY, EncounterWatch.ENCOUNTER_GAP + 1.0)
	_run(watch, instances, Vector2.ZERO, 1.0)
	t.check(_seen.size() == 2, "off screen for longer than the gap and back is a second seen (%d)"
			% _seen.size())
	yeller.free()

func _test_coming_back_inside_the_gap_is_the_same_encounter(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	_run(watch, instances, Vector2.ZERO, 1.0)
	_run(watch, instances, AWAY, EncounterWatch.ENCOUNTER_GAP - 1.0)
	_run(watch, instances, Vector2.ZERO, 1.0)
	t.check(_seen.size() == 1, "off screen for less than the gap and back sends nothing more (%d)"
			% _seen.size())
	yeller.free()

## The yeller's drawn box straddling the view's right edge: in view but mostly out of it is an
## encounter with nothing seen; then nearly all of it in view is seen.
func _test_a_sliver_at_the_edge_is_not_seen(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	var box := yeller.drawn_box()
	t.check(box.has_area(), "the yeller has a drawn box to measure (%s)" % box)
	# The view's right edge at `edge` crosses the box `share` of the way across it.
	var centre_for := func(share: float) -> Vector2:
		var edge := box.position.x + box.size.x * share
		return Vector2(edge - Tuning.VIEW_HALF_EXTENT.x, 0.0)
	_run(watch, instances, centre_for.call(0.3), 2.0)
	t.check(_seen.is_empty(), "with only 30% of it in view it is not seen")
	_run(watch, instances, centre_for.call(0.7), 2.0)
	t.check(_seen.is_empty(), "nor with 70% of it in view")
	_run(watch, instances, centre_for.call(0.9), 1.0)
	t.check(_seen.size() == 1, "with 90%% of it in view it is seen, once (%d)" % _seen.size())
	yeller.free()

## `VisibleView` *(inbox #581, the player: "remove the area at the bottom left and right up to the
## top of the joystick circle and horizontal extent of the speed button ... for the other mode those
## rectangles *do* count")*: each covered corner holds its own ring and run button whole, and
## reaches no higher than the ring's top; in the joystick scheme what lies in a corner is not
## visible, in the tap scheme it is, and the middle of the view is visible in both.
func _test_the_joystick_corners_are_not_visible(t: TestRunner) -> void:
	var left := TouchCover.joystick().left
	var right := TouchCover.joystick().right
	var ring := Vector2(TouchControls.RING_RADIUS, TouchControls.RING_RADIUS)
	var button := Vector2(TouchControls.RUN_RADIUS, TouchControls.RUN_RADIUS)
	t.check(left.encloses(Rect2(TouchControls.FOCUS_LEFT - ring, ring * 2.0))
			and left.encloses(Rect2(TouchControls.FOCUS_LEFT - button, button * 2.0)),
			"the left corner holds the left ring and its run button (%s)" % left)
	t.check(right.encloses(Rect2(TouchControls.FOCUS_RIGHT - ring, ring * 2.0))
			and right.encloses(Rect2(TouchControls.FOCUS_RIGHT - button, button * 2.0)),
			"the right corner holds the right ring and its run button (%s)" % right)
	t.check(is_equal_approx(left.position.y, TouchControls.FOCUS_LEFT.y - TouchControls.RUN_RADIUS)
			and is_equal_approx(left.end.x, TouchControls.FOCUS_LEFT.x + TouchControls.RUN_RADIUS)
			and is_equal_approx(left.end.y, ScreenOrientation.DESIGN_SIZE.y)
			and is_zero_approx(left.position.x),
			"and runs from the screen's side to the button's far edge, the ring's top to the bottom")
	t.check(not left.intersects(right), "the two corners do not overlap")

	var view := _view(Vector2.ZERO)
	var scale := view.size / ScreenOrientation.DESIGN_SIZE
	# A 10px square well inside each corner, at the bottom middle, and in the middle of the view.
	var in_left := Rect2(view.position + (left.get_center() * scale) - Vector2(5.0, 5.0),
			Vector2(10.0, 10.0))
	var in_right := Rect2(view.position + (right.get_center() * scale) - Vector2(5.0, 5.0),
			Vector2(10.0, 10.0))
	var bottom_middle := Rect2(Vector2(-5.0, view.end.y - 12.0), Vector2(10.0, 10.0))
	var middle := Rect2(Vector2(-5.0, -5.0), Vector2(10.0, 10.0))
	for rect: Rect2 in [in_left, in_right]:
		t.check(is_zero_approx(VisibleView.visible_share(rect, view, TouchCover.joystick()))
				and is_equal_approx(VisibleView.visible_share(rect, view, null), 1.0),
				"a thing in a bottom corner is hidden by the joystick scheme and seen in the tap one")
	for rect: Rect2 in [bottom_middle, middle]:
		t.check(is_equal_approx(VisibleView.visible_share(rect, view, TouchCover.joystick()), 1.0)
				and is_equal_approx(VisibleView.visible_share(rect, view, null), 1.0),
				"a thing between the corners or in the middle is visible in both schemes")
	var top := view.position.y + left.position.y * scale.y
	var straddling := Rect2(Vector2(view.position.x + 10.0, top - 5.0), Vector2(10.0, 10.0))
	t.check(is_equal_approx(VisibleView.visible_share(straddling, view, TouchCover.joystick()), 0.5),
			"one across the corner's top edge is half visible in the joystick scheme (%.2f)"
			% VisibleView.visible_share(straddling, view, TouchCover.joystick()))
	t.check(is_zero_approx(VisibleView.visible_share(Rect2(), view, null)),
			"a thing with no area is not visible")

## A yeller standing in the view's bottom-left corner: in the joystick scheme it is under the
## controls, so nothing is seen and no encounter opens; in the tap scheme it is seen.
func _test_a_thing_under_the_joystick_controls_is_not_seen(t: TestRunner) -> void:
	_clear()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	var view := _view(Vector2.ZERO)
	var corner := view.position + TouchCover.joystick().left.get_center() \
			* (view.size / ScreenOrientation.DESIGN_SIZE)
	# The view's centre that puts the yeller's drawn box in the middle of that corner.
	var centre := yeller.drawn_box().get_center() - corner
	t.check(is_zero_approx(VisibleView.visible_share(
			Rect2(yeller.drawn_box().position, yeller.drawn_box().size), _view(centre), TouchCover.joystick())),
			"the yeller's whole drawn box is under the joystick controls")
	var watch := _watch()
	_run(watch, instances, centre, 2.0, false, true)
	t.check(_seen.is_empty(), "with the joystick scheme it is not seen")
	_run(watch, instances, AWAY, EncounterWatch.ENCOUNTER_GAP + 1.0)
	_run(watch, instances, centre, 1.0, false, false)
	t.check(_seen.size() == 1, "with the tap scheme it is (%d)" % _seen.size())
	yeller.free()

func _test_a_tenth_of_the_meter_is_one_influence_per_encounter(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	var share := EncounterWatch.ENCOUNTER_INFLUENCE_POINTS
	_run(watch, instances, Vector2.ZERO, 1.0)
	yeller.excitement.accumulate_landed(share * 0.6)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced.is_empty(), "six tenths of the threshold is no influence")
	yeller.excitement.accumulate_landed(share * 0.5)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced == ["%d:homeless_yeller:seen" % DAY],
			"crossing it within the encounter is one influence, a seen one (%s)" % [_influenced])
	yeller.excitement.accumulate_landed(share * 3.0)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced.size() == 1, "and landing more in the same encounter sends nothing more")
	_run(watch, instances, AWAY, EncounterWatch.ENCOUNTER_GAP + 1.0)
	_run(watch, instances, Vector2.ZERO, 0.5)
	yeller.excitement.accumulate_landed(share * 0.6)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced.size() == 1,
			"a new encounter counts its own landing from nothing, not the last one's")
	yeller.excitement.accumulate_landed(share * 0.5)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced.size() == 2, "and crosses the threshold on its own (%d)" % _influenced.size())
	yeller.free()

## A landing from off screen opens an encounter. Its influence waits: seen later in the same
## encounter it goes out after the seen as an ordinary influence; over without being seen, it goes
## out as an unseen one.
func _test_an_influence_from_off_screen_waits_to_be_seen(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	_run(watch, instances, AWAY, 0.5)
	yeller.excitement.accumulate_landed(EncounterWatch.ENCOUNTER_INFLUENCE_POINTS * 1.2)
	_run(watch, instances, AWAY, 1.0)
	t.check(_influenced.is_empty(), "an influence from off screen is not sent at once")
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_seen.size() == 1 and _influenced == ["%d:homeless_yeller:seen" % DAY],
			"seen in the same encounter, it goes out as an ordinary influence (%s, %s)"
			% [_seen, _influenced])
	_run(watch, instances, AWAY, EncounterWatch.ENCOUNTER_GAP + 1.0)

	_clear()
	yeller.excitement.accumulate_landed(EncounterWatch.ENCOUNTER_INFLUENCE_POINTS * 1.2)
	_run(watch, instances, AWAY, 1.0)
	t.check(_influenced.is_empty(), "nothing while the encounter might still be seen")
	_run(watch, instances, AWAY, EncounterWatch.ENCOUNTER_GAP)
	t.check(_seen.is_empty() and _influenced == ["%d:homeless_yeller:unseen" % DAY],
			"over without being seen, it goes out as an unseen influence (%s)" % [_influenced])

	_clear()
	yeller.excitement.accumulate_landed(EncounterWatch.ENCOUNTER_INFLUENCE_POINTS * 1.2)
	_run(watch, instances, AWAY, 0.5)
	yeller.free()
	_run(watch, [] as Array[EventInstance], AWAY, 0.1)
	t.check(_influenced == ["%d:homeless_yeller:unseen" % DAY],
			"and an instance gone from the world ends its encounter at once (%s)" % [_influenced])

	_clear()
	var other := _instance(t, "homeless_yeller", Vector2.ZERO)
	other.excitement.accumulate_landed(EncounterWatch.ENCOUNTER_INFLUENCE_POINTS * 1.2)
	_run(watch, [other] as Array[EventInstance], AWAY, 0.5)
	watch.end_day()
	watch.day = DAY + 1
	t.check(_influenced == ["%d:homeless_yeller:unseen" % DAY],
			"the end of a day ends every encounter still open, under the day it happened on (%s)"
			% [_influenced])
	other.free()

## *(Inbox #577, the player: "let's count chases and catches as influenced always".)* A dog coming
## for her is an influence the moment it chases, with nothing landed; a lorry that can end the day
## is one the moment she is inside its reach, and a checkpoint post the moment she is inside its
## hold — neither with anything landed.
func _test_a_chase_or_a_catch_is_always_an_influence(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var dog := _chasing_dog(t, EventCatalogue.by_id("charging_dog"))
	_run(watch, [dog] as Array[EventInstance], Vector2.ZERO, 0.5)
	t.check(dog.is_chasing() and dog.excitement.landed_ever < EncounterWatch.ENCOUNTER_INFLUENCE_POINTS,
			"the dog is chasing her and has landed less than the threshold (%.1f)" % dog.excitement.landed_ever)
	t.check(_influenced == ["%d:charging_dog:seen" % DAY],
			"the chase is an influence all the same (%s)" % [_influenced])
	dog.free()

	# A lorry that can end the day: the catch is the game's own `is_lethal_at()`, so it counts once
	# the lorry is past its telegraph and not before, with her inside the same reach.
	_clear()
	var lorry := _instance(t, "reversing_lorry", Vector2.ZERO)
	var reach := lorry.def.lethal_reach()
	var outside := Vector2(0.0, reach + 40.0)
	_run(watch, [lorry] as Array[EventInstance], outside, 0.5)
	t.check(_seen.size() == 1 and _influenced.is_empty(),
			"reversing_lorry: seen outside its reach is no influence (%s)" % [_influenced])
	var inside := Vector2(0.0, reach - 2.0)
	_stand(watch, [lorry] as Array[EventInstance], inside)
	t.check(lorry.is_telegraphing() and _influenced.is_empty(),
			"reversing_lorry: inside its reach while still telegraphing is no catch (%s)"
			% [_influenced])
	lorry.resume(lorry.def.telegraph_time + 0.1, 0.0, 0.0)
	t.check(not lorry.is_telegraphing() and lorry.is_lethal_at(inside),
			"the lorry is now past its telegraph and the game's own test catches her")
	_stand(watch, [lorry] as Array[EventInstance], inside)
	t.check(_influenced.size() == 1 and lorry.excitement.landed_ever == 0.0,
			"reversing_lorry: her inside its reach is, with nothing landed (%d)" % _influenced.size())
	lorry.free()

	# A hold: the manager's own `CheckpointController.hold_that_would_begin()`, handed in as the
	# watch is given it.
	_clear()
	var manager := _manager(t)
	manager.set_physics_process(false)
	var post := manager.spawn_extra(EventCatalogue.by_id("checkpoint_post"), Vector2.ZERO)
	post.set_process(false)
	var hold_reach := post.def.detain_distance()
	_run(watch, [post] as Array[EventInstance], Vector2(0.0, hold_reach + 40.0), 0.5)
	t.check(_seen.size() == 1 and _influenced.is_empty(),
			"checkpoint_post: seen outside its hold is no influence (%s)" % [_influenced])
	var held := Vector2(0.0, hold_reach - 2.0)
	_stand(watch, [post] as Array[EventInstance], held, manager.checkpoints.hold_that_would_begin)
	t.check(_influenced.size() == 1 and post.excitement.landed_ever == 0.0,
			"checkpoint_post: her inside its hold is, with nothing landed (%d)" % _influenced.size())
	manager.clear()
	_free_manager(manager)

## Three frames with her standing at `at` and the view about her.
func _stand(watch: EncounterWatch, instances: Array[EventInstance], at: Vector2,
		hold_source := Callable()) -> void:
	for _i in 3:
		watch.tick(STEP, instances, _visible(at), at, false, hold_source)

## *(Inbox #586 in olive-hedgehog, the player: "use the real catch code".)* A guard within reach with a building's
## corner between them has not touched her, a cyclist still only warned has not reached her, and a
## hold the manager would not begin (another one already running) is not a hold.
func _test_influenced_follows_the_real_catch_and_hold(t: TestRunner) -> void:
	_clear()
	var map := CityMap.new(Vector2i(8, 8))
	map.fill_rect(Rect2i(0, 0, 8, 8), GameEnums.TileType.SIDEWALK)
	map.set_tile(Vector2i(4, 4), GameEnums.TileType.BUILDING)
	var guard := EventInstance.new()
	guard.setup(EventCatalogue.by_id("alley_robbery"), Vector2(122.0, 134.0),
			PackedVector2Array(), Vector2.RIGHT, map, Navigator.new(map))
	t.add_child(guard)
	guard.set_process(false)
	# Created where a warning pointed, so its chase has not been reported yet: this isolates the
	# reach, since a live pursuer that is chasing her counts by the chase arm whatever the wall.
	guard.came_under_a_warning = true
	guard.resume(guard.def.pursuit.warns_for + 0.1, 0.0, 0.0)
	var her := Vector2(134.0, 122.0)
	t.check(guard.def.hard_fail and not guard.is_telegraphing() and not guard.is_waiting()
			and not guard.is_chasing()
			and guard.global_position.distance_to(her) < guard.def.lethal_reach(),
			"the guard is past his telegraph, not yet reported chasing, and she is inside his reach")
	t.check(not guard.is_lethal_at(her), "but the game does not call it a catch, a corner between")
	var watch := _watch()
	var guards: Array[EventInstance] = [guard]
	# Her centre on the view's centre so the guard is seen and the encounter is open.
	_stand(watch, guards, her)
	t.check(_seen.size() == 1 and _influenced.is_empty(),
			"seen and inside his reach through the wall is no influence (%s)" % [_influenced])
	map.set_tile(Vector2i(4, 4), GameEnums.TileType.SIDEWALK)
	t.check(guard.is_lethal_at(her), "with the wall gone it is a catch")
	_stand(watch, guards, her)
	t.check(_influenced == ["%d:alley_robbery:seen" % DAY],
			"and then it counts (%s)" % [_influenced])
	guard.free()

	_clear()
	var cyclist := _instance(t, "cyclist", Vector2.ZERO)
	var warned: Array[EventInstance] = [cyclist]
	var near := Vector2(0.0, cyclist.def.lethal_reach() - 2.0)
	_stand(watch, warned, near)
	t.check(cyclist.is_telegraphing() and not cyclist.is_lethal_at(near) and _influenced.is_empty(),
			"a cyclist still only warned is not a catch, and not an influence (%s)" % [_influenced])
	cyclist.free()

	# A hold already running: the manager would begin no other, so the watch counts none.
	_clear()
	var manager := _manager(t)
	manager.set_physics_process(false)
	var mother := manager.spawn_extra(EventCatalogue.by_id("chatting_mother"), Vector2.ZERO)
	mother.set_process(false)
	var post := manager.spawn_extra(EventCatalogue.by_id("checkpoint_post"), Vector2(0.0, 500.0))
	post.set_process(false)
	mother.start_chat()
	var at_post := Vector2(0.0, 500.0 + post.def.detain_distance() - 2.0)
	var both: Array[EventInstance] = [mother, post]
	_stand(_watch(), both, at_post, manager.checkpoints.hold_that_would_begin)
	t.check(_influenced.is_empty(),
			"inside a post's reach while another hold runs is no hold (%s)" % [_influenced])
	manager.clear()
	_free_manager(manager)

## *(calm-pelican.)* A hut inspection sets her down within reach of a cyclist past its warning on
## the frame `check_hard_fails()` strikes her, after that frame's watch: the day ends and the game
## pauses before the watch looks again. The manager tells the watch of the catch itself. Played as
## the game plays it: she walks into a hut and is held (`CheckpointController.check_detentions()`),
## the cyclist waits past the hut where its release puts her down, and the manager's own physics
## ticks run the watch, the release and the hard fail in their order.
func _test_a_catch_on_the_frame_a_door_releases_her_counts(t: TestRunner) -> void:
	_clear()
	var manager := _manager(t)
	manager.start_recipe([] as Array[EventScheduler.Planned], DaySpec.for_day(DAY), DAY,
			Vector2.ZERO)
	var stroller: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	t.add_child(stroller)
	manager.use_player(stroller)
	var axis := Vector2.RIGHT
	var centre := Vector2(4000.0, 4000.0)
	var hut := manager.spawn_extra(EventCatalogue.by_id("checkpoint_hut"), centre)
	var entry := centre + axis * 40.0 + Vector2(0.0, 16.0)
	var clearance := hut.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
			+ CheckpointController.CHECKPOINT_RELEASE_MARGIN
	var released := centre - axis * maxf(40.0, clearance) + Vector2(0.0, 16.0)
	var cyclist := manager.spawn_extra(EventCatalogue.by_id("cyclist"), released)
	cyclist.set_process(false)
	cyclist.resume(cyclist.def.telegraph_time + 0.1, 0.0, 0.0)
	# Where the test puts it: the manager's tick does not step it off the place the door sets her.
	cyclist.held_by_hand = true
	var reach := cyclist.def.lethal_reach()
	t.check(entry.distance_to(cyclist.global_position) > reach
			and not cyclist.is_telegraphing(),
			"the cyclist is past its warning and out of reach of where she walks into the hut")
	stroller.reset_at(entry)

	# What had been counted on the very tick the hard fail was sent: the watch's frame is over
	# by then, so only the manager's own word to it can have counted the catch.
	var caught := "%d:cyclist:seen" % DAY
	var cyclist_seen_before_the_strike := false
	var counted_early := false
	var counted_when_struck: Array[Array] = []
	var on_fail := func(_id: String) -> void: counted_when_struck.append(_influenced.duplicate())
	EventBus.hard_fail_triggered.connect(on_fail)
	var ticks := 0
	var limit := PhysicsTicks.ticks_for(EventCatalogue.CHECKPOINT_DETAIN_SECONDS) + 20
	while counted_when_struck.is_empty() and ticks < limit:
		await PhysicsTicks.pass_ticks(t, 1)
		ticks += 1
		if _seen.has("%d:cyclist" % DAY) and counted_when_struck.is_empty():
			cyclist_seen_before_the_strike = true
			counted_early = counted_early or _influenced.has(caught)
	EventBus.hard_fail_triggered.disconnect(on_fail)
	t.check(cyclist_seen_before_the_strike and not counted_early,
			"held in the hut, the cyclist is seen and no catch is counted before the door lets her out")
	t.check(counted_when_struck.size() == 1 and manager.what_struck_her() == "cyclist",
			"the hut lets her out into the cyclist's reach and it strikes her (%s)"
			% manager.what_struck_her())
	t.check(not counted_when_struck.is_empty()
			and counted_when_struck[0].has(caught) and cyclist_seen_before_the_strike,
			"and the catch was counted on that tick, without another watch frame (%s)"
			% [counted_when_struck])
	manager.clear()
	manager.use_player(null)
	stroller.free()
	_free_manager(manager)

## *(Inbox #577: "the static things question was meant for telemetry. we need to record seen for
## them".)* Every row that draws something has a drawn box to be seen by, and a fallen tree in
## full view, with her beside it, is seen and never influenced.
func _test_a_static_row_is_seen_and_never_influenced(t: TestRunner) -> void:
	var boxless: Array[String] = []
	for def in EventCatalogue.all():
		if EventPictures.icon_for(def.look).is_empty():
			continue
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO)
		if not instance.drawn_box().has_area():
			boxless.append(def.id)
		instance.free()
	t.check(boxless.is_empty(), "every row that draws something has a drawn box (%s)" % [boxless])

	_clear()
	var watch := _watch()
	var tree := _instance(t, "fallen_tree", Vector2.ZERO)
	_run(watch, [tree] as Array[EventInstance], Vector2(0.0, 30.0), 3.0)
	t.check(_seen == ["%d:fallen_tree" % DAY] and _influenced.is_empty(),
			"a fallen tree in view is seen once and never influenced (%s, %s)" % [_seen, _influenced])
	tree.free()

## A dog of `def` that has been warned of and is coming for her at the origin, from 200px off.
func _chasing_dog(t: TestRunner, def: EventDef) -> EventInstance:
	var dog_where := WhereSheIs.nowhere()
	var dog := EventInstance.new()
	dog.setup(def, Vector2(200.0, 0.0), PackedVector2Array(), Vector2.RIGHT, null, null,
			dog_where)
	t.add_child(dog)
	dog.set_process(false)
	dog.came_under_a_warning = true
	dog.resume(def.telegraph_time, 0.0)
	for _i in 3:
		dog_where.tell(Vector2.ZERO)
		dog.step(STEP)
	return dog

func _test_two_instances_are_two_encounters(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var first := _instance(t, "homeless_yeller", Vector2(-60.0, 0.0))
	var second := _instance(t, "homeless_yeller", Vector2(60.0, 0.0))
	var instances: Array[EventInstance] = [first, second]
	_run(watch, instances, Vector2.ZERO, 1.0)
	t.check(_seen.size() == 2, "two yellers in view at once are two encounters (%d)" % _seen.size())
	first.free()
	second.free()

func _test_runs_less_than_the_gap_apart_are_one_bout(t: TestRunner) -> void:
	_clear()
	var watch := _watch()
	var none: Array[EventInstance] = []
	_run(watch, none, AWAY, 1.0)
	t.check(_ran.is_empty(), "walking is no bout")
	_run(watch, none, AWAY, 2.0, true)
	t.check(_ran == [DAY], "the day's first run is a bout, sent as it begins (%s)" % [_ran])
	_run(watch, none, AWAY, EncounterWatch.RUN_BOUT_GAP - 1.0)
	_run(watch, none, AWAY, 1.0, true)
	t.check(_ran.size() == 1, "running again less than the gap after stopping is the same bout")
	_run(watch, none, AWAY, EncounterWatch.RUN_BOUT_GAP + 0.5)
	_run(watch, none, AWAY, 1.0, true)
	t.check(_ran.size() == 2, "and the gap or more after stopping is a new one (%d)" % _ran.size())
	watch.end_day()
	_run(watch, none, AWAY, 0.5, true)
	t.check(_ran.size() == 3, "and a new day's first run is its own bout (%d)" % _ran.size())

## The manager reads the scheme off the on-screen controls: a yeller under the bottom-left
## controls is not seen while they are the joystick scheme, and is once they are the tap one — and a
## pelican under the bottom-right ones is the same for `pelican-seen` *(inbox #581: "yes,
## everything should follow this (and treat it depending on the input mode)")*.
func _test_the_manager_reads_the_controls_scheme(t: TestRunner) -> void:
	_clear()
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	city.events.start_day(DaySpec.for_day(DAY), rng, [] as Array[String])
	var events := city.events
	var stroller: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	t.add_child(stroller)
	var her := CrowdLanes.arterial_pavement(city.map)
	stroller.reset_at(her)
	events.use_player(stroller)
	var controls: TouchControls = load("res://scenes/ui/touch_controls.tscn").instantiate()
	t.add_child(controls)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	events.use_controls(controls.covering)
	var view := _view(stroller.camera_screen_center())
	var scale := view.size / ScreenOrientation.DESIGN_SIZE
	var corner := view.position + TouchCover.joystick().left.get_center() * scale
	var def := EventCatalogue.by_id("homeless_yeller")
	var yeller := events.spawn_extra(def, her)
	yeller.global_position = corner - yeller.drawn_box().get_center()
	var right_corner := view.position + TouchCover.joystick().right.get_center() * scale
	var cyclist := EventCatalogue.by_id("cyclist")
	# Warned of as a pelican, as the director's rider is (`spawn_warned()` makes the pelican of the
	# roll its warning made).
	var pelican := events.spawn_warned(cyclist,
			PackedVector2Array([right_corner, right_corner + Vector2(0.0, -300.0)]), true)
	# Held where the test puts it: the manager's tick does not step it off the corner.
	pelican.held_by_hand = true
	pelican.global_position = right_corner - pelican.drawn_box().get_center()
	var pelican_seen: Array[int] = [0]
	var on_pelican := func(_instance: Variant) -> void: pelican_seen[0] += 1
	EventBus.pelican_sighted.connect(on_pelican)
	await PhysicsTicks.pass_ticks(t, 30)
	t.check(not _seen.has("%d:homeless_yeller" % DAY),
			"under the joystick scheme's controls it is not seen (%s)" % [_seen])
	t.check(pelican_seen[0] == 0 and not _seen.has("%d:pelican" % DAY),
			"nor is the pelican, by either of its names")
	controls.set_mode(ControlsMode.Mode.TAP)
	await PhysicsTicks.pass_ticks(t, 30)
	t.check(_seen.has("%d:homeless_yeller" % DAY), "in the tap scheme it is (%s)" % [_seen])
	t.check(pelican_seen[0] == 1 and _seen.has("%d:pelican" % DAY),
			"and so is the pelican, once by each name (%d, %s)" % [pelican_seen[0], _seen])
	EventBus.pelican_sighted.disconnect(on_pelican)
	events.retire(pelican)
	events.retire(yeller)
	events.use_player(null)
	controls.free()
	stroller.free()
	city.free()

## The wiring: a real day's manager, with her on the street beside a yeller, tells the yeller seen
## under the day it was started for, and tells nothing while she is stood aside for the title. The
## check is on that outcome only: removing the `player` group return inside
## `_watch_the_encounters()` leaves it passing, so it does not name that guard.
func _test_the_manager_tells_the_encounter_under_its_day(t: TestRunner) -> void:
	_clear()
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	city.events.start_day(DaySpec.for_day(DAY), rng, [] as Array[String])
	var events := city.events
	var stroller: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	t.add_child(stroller)
	var her := CrowdLanes.arterial_pavement(city.map)
	stroller.reset_at(her)
	events.use_player(stroller)
	var yeller := events.spawn_extra(EventCatalogue.by_id("homeless_yeller"), her + Vector2(60.0, 0.0))

	stroller.stand_aside()
	await PhysicsTicks.pass_ticks(t, 30)
	var behind_the_title := _seen.has("%d:homeless_yeller" % DAY)
	stroller.step_back_in()
	await PhysicsTicks.pass_ticks(t, 30)
	t.check(not behind_the_title, "nothing is seen while she is stood aside for the title")
	t.check(_seen.has("%d:homeless_yeller" % DAY),
			"the yeller beside her is seen, under the day the manager was started for (%s)" % [_seen])
	events.retire(yeller)
	events.use_player(null)
	stroller.free()
	city.free()
