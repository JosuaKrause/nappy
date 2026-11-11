@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The pelican, drawn from one shared bag of 399 cyclists and 1 pelican per run *(minty-hedgehog,
## statement 8: "One in ~400 bikers should be a pelican riding a bicycle instead. Needs to be svg
## only"; pebbly-ibis, inbox #575 in feathery-lynx: "have one shared biker/pelican marble bag with
## 399 bikers and 1 pelican and the same bag is used throughout the run")*.
##
## What a picture cannot show: that a run meets at most one pelican, that the bag is the run's own
## and comes from its seed, that a lost day and a resumed save draw the same cyclists and pelican the
## day first did, that the draw is one marble per cyclist from a bag nothing else touches, that a
## rider created as the pelican rides as one throughout, and that the pelican is the cyclist row in
## everything a player can feel — and that the telemetry tells the pelican apart from its warning to
## its hit, which the page's counter (`tests/test_visit_counter.gd`) and the loss cause
## (`tests/test_loss_cause.gd`) then name. Whether it reads as a pelican is the drawing's review sheet,
## `docs/evidence/feathery-bison-pelican-2026-10-03/`. The view tables' completeness, their
## distinct pictures and the second pedal frame are `tests/test_event_views.gd` and
## `tests/test_event_strides.gd`; every picture being on the `events` page is
## `tests/test_atlas_events.gd`, through `EventPictures.family_sources()`.
##
## **No city is built.** The events are the subject, so an `EventManager` stands over a copy of the
## generated city's map in a run of its own (`tests/fixtures/street_events.gd`), the way a rig that builds
## no city hands it. **One case combines modules, for a stated reason**
## (`_test_the_pelican_is_named_and_told_from_its_warning_to_its_hit`): the guarantee is that the
## pelican is named the same from its warning to the page's counter and the run log, a claim about the
## manager, the danger edge, the observer and the log together, so each is real in it, over the observer's
## own stand-ins for the streets and the crowd (`DayStreets.new()`, the base `ExcitementSources`).

const RecordingLog := preload("res://tests/recording_log.gd")
const MapCache := preload("res://tests/city_map_cache.gd")
const DrawnEvent := preload("res://tests/drawn_event.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")
const SEED := 4242
const STEP := 1.0 / 60.0

## Run seeds the bag is measured over, and the cyclists a run is given in the measurement: a little
## over the 26 a run meets on average (`docs/evidence/pelican-cyclists-2026-10-05/README.md`), so the share of
## runs with a pelican is near 30/400, 7.5%: 400 runs, 30 expected, a standard deviation near 5.3.
const SHARE_SEEDS := 400
const CYCLISTS_PER_RUN := 30

var _events: EventManager
var _map: CityMap

## The run every test of this suite draws from: made here and freed at the end, so the suite plays
## no run but its own. `_new_run()` puts it back to a fresh bag of a seed's own.
var _run: RunState

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	_run = RunState.new()
	_run.start_run(1)
	_test_a_run_meets_at_most_one_pelican_and_about_one_cyclist_in_400_is_it(t)
	_test_the_seed_decides_which_cyclist_is_the_pelican(t)
	_test_only_a_cyclist_draws_from_the_bag(t)
	_test_the_bag_follows_the_run_and_the_count(t)
	_test_the_dev_flag_makes_every_cyclist_a_pelican(t)
	_test_a_lost_day_and_a_resumed_save_draw_the_same_cyclists(t)
	_map = MapCache.of(SEED)
	_events = StreetEvents.over(t, _map, _run)
	_events.start_day(DaySpec.for_day(Tuning.RUN_TAUGHT_DAY), _day_rng(), [] as Array[String])
	# The rides run on a quiet day: a body the day's draw stands on the arterial's sidewalk would turn
	# the rider off the line these checks ride, and what the draw stands there is not theirs to ask.
	_quiet_day(_events)
	_record_the_drawing()
	await _test_a_pelican_rides_as_one_throughout(t)
	await _test_a_pelican_is_the_cyclist_in_everything_but_the_picture(t)
	await _test_the_pelican_is_named_and_told_from_its_warning_to_its_hit(t)
	_events.free()

## The city's events paint through a recording drawer from here on, handed to the world the way
## the manager hands the real one, so a check reads the pictures an event was drawn with.
func _record_the_drawing() -> void:
	_events.world.drawer = RecordingEventDrawer.new(_events.atlas)

func _day_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, Tuning.RUN_TAUGHT_DAY])
	return rng

## The run's bag holds 399 cyclists and 1 pelican, so 400 cyclists in a run are exactly one pelican
## and 800 are exactly two; and over many runs of about a run's cyclists the share of runs with a
## pelican is the cyclists drawn over 400.
func _test_a_run_meets_at_most_one_pelican_and_about_one_cyclist_in_400_is_it(t: TestRunner) -> void:
	_new_run(1)
	var all := _rolls_for(1, [EventCatalogue.by_id("cyclist")], 800)
	var first := all.slice(0, 400)
	var second := all.slice(400)
	t.check(first.count(true) == 1 and second.count(true) == 1,
			"a bag of 400 holds exactly one pelican, and is filled again after them: %d, %d"
			% [first.count(true), second.count(true)])
	var runs_with_one := 0
	var two_in_a_run := 0
	for run_seed in range(1, SHARE_SEEDS + 1):
		var this_run := _rolls_for(run_seed, [EventCatalogue.by_id("cyclist")], CYCLISTS_PER_RUN)
		if this_run.has(true):
			runs_with_one += 1
		if this_run.count(true) > 1:
			two_in_a_run += 1
	t.check(two_in_a_run == 0, "no run of %d cyclists meets two pelicans (%d of %d did)"
			% [CYCLISTS_PER_RUN, two_in_a_run, SHARE_SEEDS])
	var expected := SHARE_SEEDS * CYCLISTS_PER_RUN / 400.0
	t.check(absf(runs_with_one - expected) <= 4.0 * sqrt(expected),
			"%d of %d runs meet a pelican, against %.0f expected from %d cyclists in 400"
			% [runs_with_one, SHARE_SEEDS, expected, CYCLISTS_PER_RUN])

## Two managers on the same run roll the same riders, one draw per cyclist in the order they are
## created, whatever the day; another run rolls others.
func _test_the_seed_decides_which_cyclist_is_the_pelican(t: TestRunner) -> void:
	var cyclist := EventCatalogue.by_id("cyclist")
	var first := _rolls_for(5, [cyclist], 400)
	var again := _rolls_for(5, [cyclist], 400)
	var other_run := _rolls_for(6, [cyclist], 400)
	t.check(first.has(true), "the run's 400 cyclists include a pelican (a guard that the "
			+ "comparisons below compare something)")
	t.check(first == again, "the same run makes the same cyclists the pelican")
	t.check(first != other_run, "another run makes others the pelican")

## The bag is rebuilt when the run's seed or the count it was left at disagrees with it, and only
## then: one manager kept across a new run, and across a count a lost day put back, draws what a
## fresh manager would.
func _test_the_bag_follows_the_run_and_the_count(t: TestRunner) -> void:
	var cyclist := EventCatalogue.by_id("cyclist")
	var manager := EventManager.new()
	manager.use_run(_run)
	_new_run(11)
	var first: Array[bool] = []
	for _i in 400:
		first.append(manager.spawner.rolls_a_pelican(cyclist))
	var fresh_11 := _rolls_for(11, [cyclist], 400)
	t.check(first == fresh_11, "a manager's draws are a fresh manager's")
	_new_run(12)
	var other: Array[bool] = []
	for _i in 400:
		other.append(manager.spawner.rolls_a_pelican(cyclist))
	t.check(other == _rolls_for(12, [cyclist], 400) and other != first,
			"the same manager on another run's seed draws that run's bag")
	_new_run(12)
	_run.pelican.draws = 0
	var again: Array[bool] = []
	for _i in 400:
		again.append(manager.spawner.rolls_a_pelican(cyclist))
	t.check(again == other, "and a count put back to 0 starts that bag again")
	_run.pelican.draws = 100
	var from_100: Array[bool] = []
	for _i in 300:
		from_100.append(manager.spawner.rolls_a_pelican(cyclist))
	t.check(from_100 == other.slice(100), "and put back to 100 carries on from the hundredth")
	manager.free()

## `--pelican`, as the run hands it on: the configuration reads the flag, and the manager it reaches
## (`PelicanRig.ALWAYS`, which the city sets from it) makes every cyclist the pelican while a loose
## dog still is not, and the bag draws what it would have.
func _test_the_dev_flag_makes_every_cyclist_a_pelican(t: TestRunner) -> void:
	var cyclist := EventCatalogue.by_id("cyclist")
	var plain := _rolls_for(5, [cyclist], 40)
	t.check(RunConfig.parse(PackedStringArray(["--pelican"]), "", true).pelican,
			"the flag is read from the command line")
	t.check(not RunConfig.parse(PackedStringArray(["--pelican"]), "", false).pelican,
			"and answers nothing on a release build")
	var flagged := _rolls_for(5, [cyclist], 40, EventSpawner.PelicanRig.ALWAYS)
	var dog := _rolls_for(5, [EventCatalogue.by_id("loose_dog")], 5, EventSpawner.PelicanRig.ALWAYS)
	t.check(flagged.count(true) == 40 and dog.count(true) == 0,
			"with it every cyclist is a pelican and no dog is")
	t.check(_run.pelican.draws == 0 and _rolls_for(5, [cyclist], 40) == plain,
			"and without it the same run draws as before")

## A row that is not a cyclist is never the pelican and draws nothing from the bag, so the loose
## dogs sent between two cyclists do not move which of them it is.
func _test_only_a_cyclist_draws_from_the_bag(t: TestRunner) -> void:
	var cyclist := EventCatalogue.by_id("cyclist")
	var dog := EventCatalogue.by_id("loose_dog")
	var cyclists_only := _rolls_for(5, [cyclist], 400)
	var with_dogs := _rolls_for(5, [cyclist, dog, dog], 1200)
	var cyclists_among_dogs: Array[bool] = []
	var any_dog_pelican := false
	for i in with_dogs.size():
		if i % 3 == 0:
			cyclists_among_dogs.append(with_dogs[i])
		elif with_dogs[i]:
			any_dog_pelican = true
	t.check(not any_dog_pelican, "a loose dog is never the pelican")
	t.check(cyclists_among_dogs == cyclists_only,
			"the dogs sent between them do not change which cyclist is the pelican")
	t.check(_run.pelican.draws == 400, "and the count the save keeps is cyclists only (%d)"
			% _run.pelican.draws)

## *(inbox #575: "save it in the standard save file to reset the bag to the beginning of the day on
## a lost day".)* A lost day gives the count back to the day's dawn and a save written mid-day reads
## it back, and a manager that meets either draws the cyclists, and the pelican, the day first drew.
func _test_a_lost_day_and_a_resumed_save_draw_the_same_cyclists(t: TestRunner) -> void:
	var cyclist := EventCatalogue.by_id("cyclist")
	# Some run whose pelican is among the day's cyclists, so the comparison compares one.
	# The day is draws 7 to 26, so the window searched is that one.
	var seed_value := 1
	for candidate in range(1, 2000):
		if _rolls_for(candidate, [cyclist], 27).slice(7).has(true):
			seed_value = candidate
			break
	_new_run(seed_value)
	var yesterday := _rolls(cyclist, 7, seed_value)
	t.check(yesterday.size() == 7 and _run.pelican.draws == 7, "a run's earlier day draws 7")
	_run.run_parts.photograph()
	var day := _rolls(cyclist, 20, seed_value)
	t.check(day.has(true), "the day holds the pelican (a guard that the comparisons compare one)")
	var saved := _run.pelican.to_data()
	_run.run_parts.give_back()
	t.check(_run.pelican.draws == 7, "a lost day sets the count back to the day's dawn")
	t.check(_rolls(cyclist, 20, seed_value) == day,
			"and the retry draws the same cyclists and pelican the day first did")
	t.check(_run.run_parts.run_data().has("pelican")
			and int(_run.run_parts.run_data()["pelican"]["draws"]) == _run.pelican.draws,
			"the standard save carries the count under its own key")
	_run.pelican.reset()
	_run.pelican.restore(JSON.parse_string(JSON.stringify(saved)))
	t.check(_run.pelican.draws == 27,
			"a save read back keeps the count (%d)" % _run.pelican.draws)
	_run.pelican.give_back()
	t.check(_rolls(cyclist, 20, seed_value) == day,
			"and keeps the dawn too: a day lost after a resume draws the same again")
	_run.pelican.reset()
	t.check(_run.pelican.draws == 0 and _run.pelican.to_data().get("draws") == 0,
			"a new run starts from the full bag")
	_run.pelican.restore({})
	t.check(_run.pelican.draws == 0, "and a save written before the bag loads at 0")

## Starts a run of `run_seed` with the full bag.
func _new_run(run_seed: int) -> void:
	_run.header.run_seed = run_seed
	_run.pelican.reset()

## `count` answers of a fresh manager on run `run_seed`, asked for `defs` in turn, from a full bag.
func _rolls_for(run_seed: int, defs: Array[EventDef], count: int,
		rig := EventSpawner.PelicanRig.BAG) -> Array[bool]:
	_new_run(run_seed)
	var manager := EventManager.new()
	manager.use_run(_run)
	manager.pelican_rig = rig
	var answers: Array[bool] = []
	for i in count:
		answers.append(manager.spawner.rolls_a_pelican(defs[i % defs.size()]))
	manager.free()
	return answers

## `count` answers of a fresh manager for the cyclist `def`, from wherever `_run.pelican` stands.
func _rolls(def: EventDef, count: int, run_seed: int) -> Array[bool]:
	_run.header.run_seed = run_seed
	var manager := EventManager.new()
	manager.use_run(_run)
	var answers: Array[bool] = []
	for _i in count:
		answers.append(manager.spawner.rolls_a_pelican(def))
	manager.free()
	return answers

## A rider created as the pelican, through the path every cyclist takes (`spawn_warned()`, handed
## the roll its warning made), is drawn as the pelican on its first frame and late in its ride; one
## created as the kid stays the kid.
func _test_a_pelican_rides_as_one_throughout(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var events := _events
	var pelican := events.spawn_warned(def, _ride(), true)
	var kid := events.spawn_warned(def, _ride(), false)
	t.check(pelican.is_pelican and _is_drawn_from(await _drawn_from(t, pelican),
			EventPictures.PELICAN_BY_VIEW, EventPictures.PELICAN_BY_VIEW_B),
			"a rider rolled as the pelican is drawn as the pelican from its first frame")
	t.check(not kid.is_pelican and _is_drawn_from(await _drawn_from(t, kid),
			EventPictures.CYCLIST_BY_VIEW, EventPictures.CYCLIST_BY_VIEW_B),
			"and one rolled as the kid is drawn as the kid")
	var travelled := 0.0
	for _i in 600:
		if pelican.is_finished or travelled > 250.0:
			break
		pelican.step(STEP)
		kid.step(STEP)
		travelled = pelican.path_travelled()
	t.check(travelled > 200.0, "the pelican rode %.0fpx of its 300px line" % travelled)
	t.check(pelican.is_pelican and _is_drawn_from(await _drawn_from(t, pelican),
			EventPictures.PELICAN_BY_VIEW, EventPictures.PELICAN_BY_VIEW_B),
			"and is still drawn as the pelican late in its ride")
	t.check(not kid.is_pelican, "and the kid is still the kid")
	var dog := events.spawn_warned(EventCatalogue.by_id("loose_dog"), _ride(), true)
	t.check(not dog.is_pelican, "a loose dog sent the same way is never the pelican, whatever its roll")
	for instance in [pelican, kid, dog]:
		events.retire(instance)

## The same ride, rolled both ways: the same row, the same field and the same lethal reach at every
## point around it, the same speed. Only the pictures it is drawn with differ.
func _test_a_pelican_is_the_cyclist_in_everything_but_the_picture(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var events := _events
	var pelican := events.spawn_warned(def, _ride(), true)
	var kid := events.spawn_warned(def, _ride(), false)
	for _i in 30:
		pelican.step(STEP)
		kid.step(STEP)
	t.check(pelican.def == kid.def, "both are the catalogue's own cyclist row")
	t.check(pelican.global_position == kid.global_position
			and pelican.travel_velocity() == kid.travel_velocity(),
			"they ride the same line at the same speed")
	var same_field := true
	var same_reach := true
	var lethal_points := 0
	for ring in [0.0, 20.0, 40.0, 60.0, 85.0, 120.0]:
		for step in 8:
			var at: Vector2 = kid.global_position + Vector2.from_angle(TAU * step / 8.0) * ring
			if pelican.excitement.contribution_at(at) != kid.excitement.contribution_at(at):
				same_field = false
			if pelican.is_lethal_at(at) != kid.is_lethal_at(at):
				same_reach = false
			if kid.is_lethal_at(at):
				lethal_points += 1
	t.check(same_field, "the pelican's field is the cyclist's at every point around him")
	t.check(same_reach and lethal_points > 0,
			"and so is the reach that ends the day (%d of the points asked are inside it)"
			% lethal_points)
	var pelican_pictures := await _drawn_from(t, pelican)
	var kid_pictures := await _drawn_from(t, kid)
	t.check(not pelican_pictures.is_empty() and not kid_pictures.is_empty()
			and pelican_pictures != kid_pictures, "only the picture differs")
	for instance in [pelican, kid]:
		events.retire(instance)

## The pictures `instance` is drawn with on its own canvas once drawn frames have passed: what its
## look asked its drawer to stand. The city's events are drawn through a recording drawer
## (`_record_the_drawing()`).
func _drawn_from(t: TestRunner, instance: EventInstance) -> Array[String]:
	await DrawnEvent.frames(t)
	var found: Array[String] = []
	for entry in DrawnEvent.shown(instance):
		if entry.canvas == instance and entry.kind == &"stand":
			found.append(entry.picture)
	return found

## Whether `pictures` are some, and only, of the views in `by_view` and `also_by_view`.
func _is_drawn_from(pictures: Array[String], by_view: Dictionary, also_by_view: Dictionary) -> bool:
	return not pictures.is_empty() and pictures.all(func(picture: String) -> bool:
			return by_view.values().has(picture) or also_by_view.values().has(picture))

## A straight 300px line up the arterial's sidewalk, the kind `spawn_warned()` is handed.
func _ride() -> PackedVector2Array:
	var from := CrowdLanes.arterial_pavement(_map)
	return PackedVector2Array([from, from + Vector2(0.0, -300.0)])

## *(Inbox #527 in azure-tapir, the player: "when the pelican spawns, when it's on screen, and when it's hitting the
## player ... logs should be correctly identifying it from the beginning".)* One pelican sent the
## way the director sends every cyclist (she walks, and `EventManager`'s ticks warn of the one she is owed), from its warning to its hit:
##
## - **the roll is made as the warning goes up**, so the badge already names the pelican;
## - **its creation is told once** (`EventBus.pelican_spawned`), and the run log's `ahead` line for
##   it says `pelican`, with no line anywhere saying `cyclist`;
## - **its first frame on screen is told once**, however many frames it stays there;
## - **its first share of the meter is told once**, and a kid's never;
## - **its lethal reach covering her is told once**, ahead of the hard fail, and names the day's
##   loss `pelican` (`EventManager.what_struck_her()`), where a kid's names `cyclist`;
## - **the observer's own lines call it `pelican`**: on screen, struck, and nearest.
func _test_the_pelican_is_named_and_told_from_its_warning_to_its_hit(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var events := _events
	var map := _map
	# Nothing but what this test sends is in the world: the day's plan is let go and nothing is sited
	# ahead of her, so the manager's own ticks, which run with her in the tree, act on the pelican
	# and the kid alone.
	_quiet_day(events)
	var her := CrowdLanes.arterial_pavement(map)
	for _tile in map.size.y / 2:
		if PendingWarning.down_her_line(map, def, her, Vector2.UP) != Vector2.INF:
			break
		her.y += Tuning.TILE_SIZE
	var stroller: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	t.add_child(stroller)
	stroller.reset_at(her)
	events.use_player(stroller)
	var told := {"spawned": 0, "sighted": 0, "excited": 0, "struck": 0}
	var on_spawned := func(_instance: Variant) -> void: told["spawned"] += 1
	var on_sighted := func(_instance: Variant) -> void: told["sighted"] += 1
	var on_excited := func(_instance: Variant) -> void: told["excited"] += 1
	var on_struck := func(_instance: Variant) -> void: told["struck"] += 1
	EventBus.pelican_spawned.connect(on_spawned)
	EventBus.pelican_sighted.connect(on_sighted)
	EventBus.pelican_excited_her.connect(on_excited)
	EventBus.pelican_struck_her.connect(on_struck)
	var run_log := RecordingLog.new()
	run_log.begin_run(SEED, false)
	run_log.begin_day(Tuning.RUN_TAUGHT_DAY, 1, SEED, SEED, 180.0)
	# The manager's own lines reach the run log through the trace a booted city hands it.
	events.trace = RunTrace.new(run_log.note)
	# The observer is handed what `main` hands it, and hears the pelican's moments as they happen.
	var baby := stroller.get_node("Baby") as Baby
	var clock := DayController.new()
	clock.start(180.0)
	var observer := TelemetryObserver.new(run_log)
	observer.setup(_run, clock, null, false)
	observer.watch(_map, _events, stroller, baby, _map, DayStreets.new(), ExcitementSources.new(),
			"")

	# The director owes her one cyclist from a route bag holding nothing else, as a scene's recipe
	# hands it (`EventManager.start_recipe_route()`), due as soon as she is walking. She walks up the
	# sidewalk by hand (the rig's own physics is off), and the manager's own ticks send it:
	# `place_what_is_owed_ahead()` warns of it down her line, the roll made as the warning goes up.
	stroller.set_physics_process(false)
	var owed := events.start_recipe_route(["cyclist"], ["cyclist"], 1, 0.0)
	t.check(owed == 1, "the director owes her the one cyclist (%d)" % owed)
	var before := events.instances().size()
	events.pelican_rig = EventSpawner.PelicanRig.ALWAYS
	# A lambda holds its own copy of a local, so the warning is carried out in an array.
	var sent: Array[PendingWarning] = []
	var walk := func(_n: int) -> void:
		if not sent.is_empty():
			return
		if not events.pending_warnings().is_empty():
			sent.append(events.pending_warnings().back())
			stroller.velocity = Vector2.ZERO
			return
		stroller.velocity = Vector2.UP * Tuning.WALK_SPEED
		stroller.global_position += stroller.velocity * STEP
	var walked := 0
	while sent.is_empty() and walked < PhysicsTicks.ticks_for(10.0):
		await PhysicsTicks.pass_ticks(t, 1, walk)
		walked += 1
	var warning: PendingWarning = sent[0] if not sent.is_empty() else null
	events.pelican_rig = EventSpawner.PelicanRig.BAG
	stroller.velocity = Vector2.ZERO
	t.check(warning != null and warning.is_pelican and warning.logged_name() == "pelican",
			"the roll is made as the warning goes up, so the warning is already the pelican's")
	# The danger edge measures on a real frame, as it does in play.
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	var edge := DangerEdge.new()
	edge.atlas = atlas
	t.add_child(edge)
	edge.setup(events, stroller)
	await t.get_tree().process_frame
	var badges: Array[String] = []
	for badge in edge.announcing():
		badges.append(str(badge["id"]))
	t.check(badges.has("pelican") and not badges.has("cyclist"),
			"and its badge's line names the pelican (%s)" % [badges])
	edge.free()
	atlas.release(&"events")

	# The warning runs down on the manager's own ticks, with her standing where she is.
	var pelican: EventInstance = null
	var ticks := 0
	var limit := PhysicsTicks.ticks_for(def.telegraph_time + 3.0)
	while pelican == null and ticks < limit:
		await PhysicsTicks.pass_ticks(t, 1)
		ticks += 1
		if events.instances().size() > before:
			pelican = events.instances().back()
	t.check(pelican != null and pelican.is_pelican,
			"the warning ends in a pelican, %.2fs after it went up" % (ticks * STEP))
	if pelican == null:
		_untangle(events, stroller, [on_spawned, on_sighted, on_excited, on_struck], observer, clock,
				run_log)
		return
	t.check(told["spawned"] == 1, "its creation is told once (%d)" % told["spawned"])

	await PhysicsTicks.pass_ticks(t, 1)
	t.check(told["sighted"] == 0, "created just off screen, it is not yet seen")

	# `reset_at()` rather than a bare move, so the camera's screen centre, which a headless run never
	# smooths along, is on her: what counts as on screen is measured about it.
	stroller.reset_at(pelican.global_position + Vector2(200.0, 0.0))
	await PhysicsTicks.pass_ticks(t, 3)
	t.check(told["sighted"] == 1,
			"on screen for three physics frames, its first is told once (%d)" % told["sighted"])

	pelican.excitement.accumulate_landed(0.0)
	t.check(told["excited"] == 0, "nothing landed is nothing told")
	pelican.excitement.accumulate_landed(1.5)
	pelican.excitement.accumulate_landed(2.0)
	var kid := events.spawn_warned(def, _ride(), false)
	kid.excitement.accumulate_landed(4.0)
	t.check(told["excited"] == 1,
			"its first share of the meter is told once, and a kid's never (%d)" % told["excited"])

	# Her centre on the pelican's: its reach covers her on the next tick, the manager's own check.
	stroller.reset_at(pelican.global_position)
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(told["struck"] == 1 and events.what_struck_her() == "pelican",
			"its reach covering her is told once and names the day's loss the pelican's (%d, '%s')"
			% [told["struck"], events.what_struck_her()])
	# The day's end as the director writes it (`DayDirector`): the cause is what struck her, and the
	# lost line names what was nearest.
	observer.day_finished(GameEnums.DayResult.LOST_HARD_FAIL,
			LossCause.of(GameEnums.DayResult.LOST_HARD_FAIL, def.id,
				events.what_struck_her()))

	var lines: Array[String] = run_log.lines
	var ahead := false
	var on_screen := false
	var struck := false
	var nearest := false
	var cyclist_lines: Array[String] = []
	for line in lines:
		ahead = ahead or line.contains("pelican comes at her from")
		on_screen = on_screen or line.contains("pelican on screen at")
		struck = struck or line.contains("pelican struck her at")
		nearest = nearest or (line.contains("lost") and line.contains("near: pelican "))
		if line.contains("cyclist"):
			cyclist_lines.append(line)
	t.check(ahead, "the run log's line for its creation names the pelican")
	t.check(on_screen and struck, "and so do its lines for being seen and striking her")
	t.check(nearest, "and the nearest thing a lost line names is the pelican")
	t.check(cyclist_lines.is_empty(),
			"and no line about it calls it a cyclist (%s)" % [cyclist_lines])

	# A new day, as the game starts one: the kid's reach names the cyclist and tells nothing of a
	# pelican. Silent now, so the day's own plan lines are not read as the pelican's.
	events.trace = RunTrace.new()
	_quiet_day(events)
	var kid_again := events.spawn_warned(def, _ride(), false)
	stroller.reset_at(kid_again.global_position)
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(events.what_struck_her() == "cyclist" and told["struck"] == 1,
			"where a kid's reach names the cyclist, and tells nothing of a pelican ('%s')"
			% events.what_struck_her())
	_untangle(events, stroller, [on_spawned, on_sighted, on_excited, on_struck], observer, clock,
				run_log)

## Starts the day again as a scene's walk starts it (`EventManager.start_recipe()`, which
## `SceneRecipeRuntime` calls): nothing planned and nothing sited ahead of her, while warnings keep
## their production behavior.
func _quiet_day(events: EventManager) -> void:
	var nothing: Array[EventScheduler.Planned] = []
	events.start_recipe(nothing, DaySpec.for_day(Tuning.RUN_TAUGHT_DAY), Tuning.RUN_TAUGHT_DAY,
			Vector2.ZERO)

## Gives the city's manager back as the other tests left it, and lets go of the pelican signals.
func _untangle(events: EventManager, stroller: Stroller, listeners: Array,
		observer: TelemetryObserver, clock: DayController, run_log: Telemetry) -> void:
	run_log.free()
	events.trace = RunTrace.new()
	events.use_player(null)
	observer.free()
	clock.free()
	stroller.free()
	var signals := [EventBus.pelican_spawned, EventBus.pelican_sighted, EventBus.pelican_excited_her,
			EventBus.pelican_struck_her]
	for i in signals.size():
		var told: Signal = signals[i]
		told.disconnect(listeners[i])
