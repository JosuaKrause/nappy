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
	_test_a_tenth_of_the_meter_is_one_influence_per_encounter(t)
	_test_an_influence_from_off_screen_waits_to_be_seen(t)
	_test_a_chase_is_an_influence_for_a_row_that_does_not_excite(t)
	_test_two_instances_are_two_encounters(t)
	_test_runs_less_than_the_gap_apart_are_one_bout(t)
	_test_the_manager_watches_only_while_she_is_playing(t)

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
		running := false) -> void:
	for _i in int(round(seconds / STEP)):
		watch.tick(STEP, instances, _view(centre), centre, running)

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
		watch.tick(STEP, [standing] as Array[EventInstance], _view(inside), inside, false)
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
