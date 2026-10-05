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
const SEED := 4242
const STEP := 1.0 / 60.0
const DAY := 5
const VIEW_SIZE := Tuning.VIEW_HALF_EXTENT * 2.0

var _seen: Array[String] = []
var _influenced: Array[String] = []
var _ran: Array[int] = []

func run(t) -> void:
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
	_test_a_chase_is_an_influence_for_a_row_that_does_not_excite(t)
	_test_two_instances_are_two_encounters(t)
	_test_runs_less_than_the_gap_apart_are_one_bout(t)
	_test_the_manager_watches_only_while_she_is_playing(t)
	_test_the_manager_reads_the_controls_scheme(t)

	EventBus.encounter_seen.disconnect(on_seen)
	EventBus.encounter_influenced.disconnect(on_influenced)
	EventBus.run_bout_began.disconnect(on_ran)

func _clear() -> void:
	_seen.clear()
	_influenced.clear()
	_ran.clear()

## A watch for day `DAY`.
func _watch() -> EncounterWatch:
	var watch := EncounterWatch.new()
	watch.day = DAY
	return watch

## An instance of the row `id` standing at `at`, in the tree and never ticking on its own.
func _instance(t, id: String, at: Vector2) -> EventInstance:
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
	for _i in int(round(seconds / STEP)):
		watch.tick(STEP, instances, _view(centre), joystick, centre, running)

## Far enough from any instance near the origin that nothing of it is in view.
const AWAY := Vector2(2000.0, 0.0)

func _test_one_encounter_is_one_seen(t) -> void:
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

func _test_coming_back_after_the_gap_is_a_second_encounter(t) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	_run(watch, instances, Vector2.ZERO, 1.0)
	_run(watch, instances, AWAY, Tuning.ENCOUNTER_GAP + 1.0)
	_run(watch, instances, Vector2.ZERO, 1.0)
	t.check(_seen.size() == 2, "off screen for longer than the gap and back is a second seen (%d)"
			% _seen.size())
	yeller.free()

func _test_coming_back_inside_the_gap_is_the_same_encounter(t) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	_run(watch, instances, Vector2.ZERO, 1.0)
	_run(watch, instances, AWAY, Tuning.ENCOUNTER_GAP - 1.0)
	_run(watch, instances, Vector2.ZERO, 1.0)
	t.check(_seen.size() == 1, "off screen for less than the gap and back sends nothing more (%d)"
			% _seen.size())
	yeller.free()

## The yeller's drawn box straddling the view's right edge: in view but mostly out of it is an
## encounter with nothing seen; then nearly all of it in view is seen.
func _test_a_sliver_at_the_edge_is_not_seen(t) -> void:
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
func _test_the_joystick_corners_are_not_visible(t) -> void:
	var left := VisibleView.covered_left()
	var right := VisibleView.covered_right()
	var ring := Vector2(TouchControls.STOP_RADIUS, TouchControls.STOP_RADIUS)
	var button := Vector2(TouchControls.RUN_RADIUS, TouchControls.RUN_RADIUS)
	t.check(left.encloses(Rect2(TouchControls.FOCUS_LEFT - ring, ring * 2.0))
			and left.encloses(Rect2(TouchControls.RUN_CENTRE_LEFT - button, button * 2.0)),
			"the left corner holds the left ring and its run button (%s)" % left)
	t.check(right.encloses(Rect2(TouchControls.FOCUS_RIGHT - ring, ring * 2.0))
			and right.encloses(Rect2(TouchControls.RUN_CENTRE_RIGHT - button, button * 2.0)),
			"the right corner holds the right ring and its run button (%s)" % right)
	t.check(is_equal_approx(left.position.y, TouchControls.FOCUS_LEFT.y - TouchControls.STOP_RADIUS)
			and is_equal_approx(left.end.x, TouchControls.RUN_CENTRE_LEFT.x + TouchControls.RUN_RADIUS)
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
		t.check(is_zero_approx(VisibleView.visible_share(rect, view, true))
				and is_equal_approx(VisibleView.visible_share(rect, view, false), 1.0),
				"a thing in a bottom corner is hidden by the joystick scheme and seen in the tap one")
	for rect: Rect2 in [bottom_middle, middle]:
		t.check(is_equal_approx(VisibleView.visible_share(rect, view, true), 1.0)
				and is_equal_approx(VisibleView.visible_share(rect, view, false), 1.0),
				"a thing between the corners or in the middle is visible in both schemes")
	var top := view.position.y + left.position.y * scale.y
	var straddling := Rect2(Vector2(view.position.x + 10.0, top - 5.0), Vector2(10.0, 10.0))
	t.check(is_equal_approx(VisibleView.visible_share(straddling, view, true), 0.5),
			"one across the corner's top edge is half visible in the joystick scheme (%.2f)"
			% VisibleView.visible_share(straddling, view, true))
	t.check(is_zero_approx(VisibleView.visible_share(Rect2(), view, false)),
			"a thing with no area is not visible")

## A yeller standing in the view's bottom-left corner: in the joystick scheme it is under the
## controls, so nothing is seen and no encounter opens; in the tap scheme it is seen.
func _test_a_thing_under_the_joystick_controls_is_not_seen(t) -> void:
	_clear()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	var view := _view(Vector2.ZERO)
	var corner := view.position + VisibleView.covered_left().get_center() \
			* (view.size / ScreenOrientation.DESIGN_SIZE)
	# The view's centre that puts the yeller's drawn box in the middle of that corner.
	var centre := yeller.drawn_box().get_center() - corner
	t.check(is_zero_approx(VisibleView.visible_share(
			Rect2(yeller.drawn_box().position, yeller.drawn_box().size), _view(centre), true)),
			"the yeller's whole drawn box is under the joystick controls")
	var watch := _watch()
	_run(watch, instances, centre, 2.0, false, true)
	t.check(_seen.is_empty(), "with the joystick scheme it is not seen")
	_run(watch, instances, AWAY, Tuning.ENCOUNTER_GAP + 1.0)
	_run(watch, instances, centre, 1.0, false, false)
	t.check(_seen.size() == 1, "with the tap scheme it is (%d)" % _seen.size())
	yeller.free()

func _test_a_tenth_of_the_meter_is_one_influence_per_encounter(t) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	t.check(EncounterWatch.excites(yeller.def), "the yeller is a row that excites her")
	var share := Tuning.ENCOUNTER_INFLUENCE_POINTS
	_run(watch, instances, Vector2.ZERO, 1.0)
	yeller.accumulate_landed(share * 0.6)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced.is_empty(), "six tenths of the threshold is no influence")
	yeller.accumulate_landed(share * 0.5)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced == ["%d:homeless_yeller:seen" % DAY],
			"crossing it within the encounter is one influence, a seen one (%s)" % [_influenced])
	yeller.accumulate_landed(share * 3.0)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced.size() == 1, "and landing more in the same encounter sends nothing more")
	_run(watch, instances, AWAY, Tuning.ENCOUNTER_GAP + 1.0)
	_run(watch, instances, Vector2.ZERO, 0.5)
	yeller.accumulate_landed(share * 0.6)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced.size() == 1,
			"a new encounter counts its own landing from nothing, not the last one's")
	yeller.accumulate_landed(share * 0.5)
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_influenced.size() == 2, "and crosses the threshold on its own (%d)" % _influenced.size())
	yeller.free()

## A landing from off screen opens an encounter. Its influence waits: seen later in the same
## encounter it goes out after the seen as an ordinary influence; over without being seen, it goes
## out as an unseen one.
func _test_an_influence_from_off_screen_waits_to_be_seen(t) -> void:
	_clear()
	var watch := _watch()
	var yeller := _instance(t, "homeless_yeller", Vector2.ZERO)
	var instances: Array[EventInstance] = [yeller]
	_run(watch, instances, AWAY, 0.5)
	yeller.accumulate_landed(Tuning.ENCOUNTER_INFLUENCE_POINTS * 1.2)
	_run(watch, instances, AWAY, 1.0)
	t.check(_influenced.is_empty(), "an influence from off screen is not sent at once")
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(_seen.size() == 1 and _influenced == ["%d:homeless_yeller:seen" % DAY],
			"seen in the same encounter, it goes out as an ordinary influence (%s, %s)"
			% [_seen, _influenced])
	_run(watch, instances, AWAY, Tuning.ENCOUNTER_GAP + 1.0)

	_clear()
	yeller.accumulate_landed(Tuning.ENCOUNTER_INFLUENCE_POINTS * 1.2)
	_run(watch, instances, AWAY, 1.0)
	t.check(_influenced.is_empty(), "nothing while the encounter might still be seen")
	_run(watch, instances, AWAY, Tuning.ENCOUNTER_GAP)
	t.check(_seen.is_empty() and _influenced == ["%d:homeless_yeller:unseen" % DAY],
			"over without being seen, it goes out as an unseen influence (%s)" % [_influenced])

	_clear()
	yeller.accumulate_landed(Tuning.ENCOUNTER_INFLUENCE_POINTS * 1.2)
	_run(watch, instances, AWAY, 0.5)
	yeller.free()
	_run(watch, [] as Array[EventInstance], AWAY, 0.1)
	t.check(_influenced == ["%d:homeless_yeller:unseen" % DAY],
			"and an instance gone from the world ends its encounter at once (%s)" % [_influenced])

	_clear()
	var other := _instance(t, "homeless_yeller", Vector2.ZERO)
	other.accumulate_landed(Tuning.ENCOUNTER_INFLUENCE_POINTS * 1.2)
	_run(watch, [other] as Array[EventInstance], AWAY, 0.5)
	watch.end_day()
	watch.day = DAY + 1
	t.check(_influenced == ["%d:homeless_yeller:unseen" % DAY],
			"the end of a day ends every encounter still open, under the day it happened on (%s)"
			% [_influenced])
	other.free()

## A row whose field does not excite her is influenced by being chased, or by her inside its reach:
## a dog that charges with no field of its own stands in for one. A dog that does excite her is
## judged by its landing alone, chase or no chase.
func _test_a_chase_is_an_influence_for_a_row_that_does_not_excite(t) -> void:
	_clear()
	var watch := _watch()
	var quiet_def := EventCatalogue._charging_dog()
	quiet_def.intensity = 0.0
	quiet_def.core_intensity = 0.0
	t.check(not EncounterWatch.excites(quiet_def) and quiet_def.pursues,
			"the stand-in is a pursuer that does not excite")
	var quiet := _chasing_dog(t, quiet_def)
	var loud := _chasing_dog(t, EventCatalogue.by_id("charging_dog"))
	var instances: Array[EventInstance] = [quiet, loud]
	_run(watch, instances, Vector2.ZERO, 0.5)
	t.check(quiet.is_chasing() and loud.is_chasing(), "both dogs are chasing her")
	t.check(_influenced == ["%d:charging_dog:seen" % DAY],
			"the chase is an influence for the dog with no field, and not for the one with a field "
			+ "that has landed nothing (%s)" % [_influenced])
	quiet.free()
	loud.free()

	_clear()
	var lethal_def := EventCatalogue._charging_dog()
	lethal_def.intensity = 0.0
	lethal_def.pursues = false
	var standing := _instance(t, "homeless_yeller", Vector2.ZERO)
	standing.def = lethal_def
	_run(watch, [standing] as Array[EventInstance], Vector2(0.0, lethal_def.lethal_reach() + 40.0),
			0.5)
	t.check(_seen.size() == 1 and _influenced.is_empty(), "seen outside its reach is no influence")
	var inside := Vector2(0.0, lethal_def.lethal_reach() - 2.0)
	for _i in 3:
		watch.tick(STEP, [standing] as Array[EventInstance], _view(inside), false, inside, false)
	t.check(_influenced.size() == 1, "her inside its reach is (%d)" % _influenced.size())
	standing.free()

## A dog of `def` that has been warned of and is coming for her at the origin, from 200px off.
func _chasing_dog(t, def: EventDef) -> EventInstance:
	var dog := EventInstance.new()
	dog.setup(def, Vector2(200.0, 0.0))
	t.add_child(dog)
	dog.set_process(false)
	dog.came_under_a_warning = true
	dog.resume(def.telegraph_time, 0.0)
	for _i in 3:
		dog.player_at = Vector2.ZERO
		dog._process(STEP)
	return dog

func _test_two_instances_are_two_encounters(t) -> void:
	_clear()
	var watch := _watch()
	var first := _instance(t, "homeless_yeller", Vector2(-60.0, 0.0))
	var second := _instance(t, "homeless_yeller", Vector2(60.0, 0.0))
	var instances: Array[EventInstance] = [first, second]
	_run(watch, instances, Vector2.ZERO, 1.0)
	t.check(_seen.size() == 2, "two yellers in view at once are two encounters (%d)" % _seen.size())
	first.free()
	second.free()

func _test_runs_less_than_the_gap_apart_are_one_bout(t) -> void:
	_clear()
	var watch := _watch()
	var none: Array[EventInstance] = []
	_run(watch, none, AWAY, 1.0)
	t.check(_ran.is_empty(), "walking is no bout")
	_run(watch, none, AWAY, 2.0, true)
	t.check(_ran == [DAY], "the day's first run is a bout, sent as it begins (%s)" % [_ran])
	_run(watch, none, AWAY, Tuning.RUN_BOUT_GAP - 1.0)
	_run(watch, none, AWAY, 1.0, true)
	t.check(_ran.size() == 1, "running again less than the gap after stopping is the same bout")
	_run(watch, none, AWAY, Tuning.RUN_BOUT_GAP + 0.5)
	_run(watch, none, AWAY, 1.0, true)
	t.check(_ran.size() == 2, "and the gap or more after stopping is a new one (%d)" % _ran.size())
	watch.end_day()
	_run(watch, none, AWAY, 0.5, true)
	t.check(_ran.size() == 3, "and a new day's first run is its own bout (%d)" % _ran.size())

## The manager reads the scheme off the on-screen controls: a yeller under the bottom-left
## controls is not seen while they are the joystick scheme, and is once they are the tap one.
func _test_the_manager_reads_the_controls_scheme(t) -> void:
	_clear()
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	city.events.start_day(DAY, rng, [] as Array[String])
	var events := city.events
	var stroller: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	t.add_child(stroller)
	stroller.set_physics_process(false)
	var her := CrowdLanes.arterial_pavement(city.map)
	stroller.reset_at(her)
	events._player = stroller
	var controls: TouchControls = load("res://scenes/ui/touch_controls.tscn").instantiate()
	t.add_child(controls)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var view := _view(stroller.camera_screen_center())
	var scale := view.size / ScreenOrientation.DESIGN_SIZE
	var corner := view.position + VisibleView.covered_left().get_center() * scale
	var def := EventCatalogue.by_id("homeless_yeller")
	var yeller := events.spawn_extra(def, her)
	yeller.global_position = corner - yeller.drawn_box().get_center()
	for _i in 30:
		events._physics_process(STEP)
	t.check(not _seen.has("%d:homeless_yeller" % DAY),
			"under the joystick scheme's controls it is not seen (%s)" % [_seen])
	controls.set_mode(ControlsMode.Mode.TAP)
	for _i in 30:
		events._physics_process(STEP)
	t.check(_seen.has("%d:homeless_yeller" % DAY), "in the tap scheme it is (%s)" % [_seen])
	events.retire(yeller)
	events._player = null
	controls.free()
	stroller.free()
	city.free()

## The wiring: a real day's manager, with her on the street beside a yeller, tells the yeller seen
## under the day it was started for — and tells nothing while she is stood aside for the title.
func _test_the_manager_watches_only_while_she_is_playing(t) -> void:
	_clear()
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	city.events.start_day(DAY, rng, [] as Array[String])
	var events := city.events
	var stroller: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	t.add_child(stroller)
	stroller.set_physics_process(false)
	var her := CrowdLanes.arterial_pavement(city.map)
	stroller.reset_at(her)
	events._player = stroller
	var yeller := events.spawn_extra(EventCatalogue.by_id("homeless_yeller"), her + Vector2(60.0, 0.0))

	stroller.stand_aside()
	for _i in 30:
		events._physics_process(STEP)
	var behind_the_title := _seen.has("%d:homeless_yeller" % DAY)
	stroller.step_back_in()
	for _i in 30:
		events._physics_process(STEP)
	t.check(not behind_the_title, "nothing is seen while she is stood aside for the title")
	t.check(_seen.has("%d:homeless_yeller" % DAY),
			"the yeller beside her is seen, under the day the manager was started for (%s)" % [_seen])
	events.retire(yeller)
	events._player = null
	stroller.free()
	city.free()
