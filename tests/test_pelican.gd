extends RefCounted
## The pelican that about one cyclist in four hundred is instead *(minty-hedgehog, statement 8:
## "One in ~400 bikers should be a pelican riding a bicycle instead. Needs to be svg only")*.
##
## What a picture cannot show: that the share is the player's number over many runs and comes from
## the run's own seed, that the roll is one draw per cyclist from a stream nothing else touches, that
## a rider created as the pelican rides as one to the end, and that the pelican is the cyclist row in
## everything a player can feel — and that the telemetry tells the pelican apart from its warning to
## its hit, which the page's counter (`tests/test_visit_counter.gd`) and the loss cause
## (`tests/test_day_lost_to.gd`) then name. Whether it reads as a pelican is the drawing's review sheet,
## `docs/evidence/feathery-bison-pelican-2026-10-03/`. The view tables' completeness, their
## distinct pictures and the second pedal frame are `tests/test_event_views.gd` and
## `tests/test_event_strides.gd`; every picture being on the `events` page is
## `tests/test_atlas_events.gd`, through `EventInstance.family_sources()`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

## Run seeds and days the share is measured over, and the cyclists rolled on each of those days:
## 480,000 rolls, about 1,200 pelicans expected, with a standard deviation near 35.
const SHARE_SEEDS := 200
const SHARE_DAYS: Array[int] = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
const SHARE_ROLLS_PER_DAY := 200
## How far the measured share may sit from `EventManager.PELICAN_SHARE`, as a fraction of it —
## about three and a half standard deviations at the counts above.
const SHARE_TOLERANCE := 0.1

var _city: City

func run(t) -> void:
	_test_about_one_cyclist_in_400_is_a_pelican(t)
	_test_the_seed_decides_which_cyclist_is_the_pelican(t)
	_test_only_a_cyclist_draws_from_the_pelican_stream(t)
	_test_the_pelican_never_becomes_a_png(t)
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_city.events.start_day(Tuning.RUN_TAUGHT_DAY, _day_rng(), [] as Array[String])
	_test_a_pelican_rides_as_one_to_the_end(t)
	_test_a_pelican_is_the_cyclist_in_everything_but_the_picture(t)
	_test_the_pelican_is_named_and_told_from_its_warning_to_its_hit(t)
	_city.free()

func _day_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, Tuning.RUN_TAUGHT_DAY])
	return rng

## The share over many runs is the player's own, through the same stream and the same roll
## `EventManager.rolls_a_pelican()` uses — `GameState.day_rng()` under each run seed in turn, and
## `EventManager.pelican_roll()` against `PELICAN_SHARE`.
func _test_about_one_cyclist_in_400_is_a_pelican(t) -> void:
	var saved_seed := GameState.run_seed
	var rolls := 0
	var pelicans := 0
	var runs_with_one := 0
	for run_seed in range(1, SHARE_SEEDS + 1):
		GameState.run_seed = run_seed
		var this_run := 0
		for day in SHARE_DAYS:
			var rng := GameState.day_rng(day, EventManager.PELICAN_STREAM)
			for _i in SHARE_ROLLS_PER_DAY:
				rolls += 1
				if EventManager.pelican_roll(rng, EventManager.PELICAN_SHARE):
					this_run += 1
		pelicans += this_run
		if this_run > 0:
			runs_with_one += 1
	GameState.run_seed = saved_seed
	var share := float(pelicans) / float(rolls)
	t.check(absf(share - EventManager.PELICAN_SHARE) <= EventManager.PELICAN_SHARE * SHARE_TOLERANCE,
			"one cyclist in %.0f is a pelican over %d rolls, against the player's one in %.0f"
			% [1.0 / maxf(share, 0.000001), rolls, 1.0 / EventManager.PELICAN_SHARE])
	t.check(runs_with_one > SHARE_SEEDS / 2,
			("the pelicans are spread over the runs rather than bunched into a few: %d of %d runs "
			% [runs_with_one, SHARE_SEEDS]) + "of 2,400 cyclists meet at least one")

## Two managers on the same day of the same run roll the same riders, one draw per cyclist in the
## order they are created; another day rolls others.
func _test_the_seed_decides_which_cyclist_is_the_pelican(t) -> void:
	var cyclist := EventCatalogue.by_id("cyclist")
	var first := _rolls(5, [cyclist], 4000)
	var again := _rolls(5, [cyclist], 4000)
	var other_day := _rolls(6, [cyclist], 4000)
	t.check(first.has(true), "the day's 4,000 cyclists include a pelican (a guard that the "
			+ "comparisons below compare something)")
	t.check(first == again, "the same run and day make the same cyclists the pelican")
	t.check(first != other_day, "another day makes others the pelican")

## A row that is not a cyclist is never the pelican and draws nothing from its stream, so the loose
## dogs sent between two cyclists do not move which of them it is.
func _test_only_a_cyclist_draws_from_the_pelican_stream(t) -> void:
	var cyclist := EventCatalogue.by_id("cyclist")
	var dog := EventCatalogue.by_id("loose_dog")
	var cyclists_only := _rolls(5, [cyclist], 4000)
	var with_dogs := _rolls(5, [cyclist, dog, dog], 12000)
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

## *(minty-hedgehog: "converted to PNG during atlas creation but otherwise it will always stay SVG
## never become a converted PNG".)* The default bake takes an illustrated PNG wherever one stands
## beside its SVG (`docs/VISUALS.md`), so a transfer of the pelican placed there would quietly
## replace the drawing in the release; none may exist, for any picture the pelican draws.
func _test_the_pelican_never_becomes_a_png(t) -> void:
	var pictures: Array[String] = []
	for table: Dictionary in [EventInstance.PELICAN_BY_VIEW, EventInstance.PELICAN_BY_VIEW_B]:
		for view: String in table:
			pictures.append(str(table[view]))
	var sources := 0
	var converted: Array[String] = []
	for picture in pictures:
		if FileAccess.file_exists("res://art/%s.svg" % picture):
			sources += 1
		for png in ["res://art/illustrated/svg-transfer/%s.png" % picture,
				"res://art/illustrated/%s.png" % picture]:
			if FileAccess.file_exists(png):
				converted.append(png)
	t.check(sources == pictures.size(), "every pelican picture has its SVG under art/ (%d of %d)"
			% [sources, pictures.size()])
	t.check(converted.is_empty(), "and none has an illustrated PNG beside it (%s)"
			% ", ".join(converted))

## `count` answers of a fresh manager on `day` of the current run, asked for `defs` in turn.
func _rolls(day: int, defs: Array[EventDef], count: int) -> Array[bool]:
	var manager := EventManager.new()
	manager._day = day
	var answers: Array[bool] = []
	for i in count:
		answers.append(manager.rolls_a_pelican(defs[i % defs.size()]))
	manager.free()
	return answers

## A rider created as the pelican, through the path every cyclist takes (`spawn_warned()`, handed
## the roll its warning made), is drawn as the pelican on its first frame and on its last; one
## created as the kid stays the kid.
func _test_a_pelican_rides_as_one_to_the_end(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var events := _city.events
	var pelican := events.spawn_warned(def, _ride(), true)
	var kid := events.spawn_warned(def, _ride(), false)
	t.check(pelican.is_pelican and pelican.rider_pictures()[0] == EventInstance.PELICAN_BY_VIEW
			and pelican.rider_pictures()[1] == EventInstance.PELICAN_BY_VIEW_B,
			"a rider rolled as the pelican is drawn as the pelican from its first frame")
	t.check(not kid.is_pelican and kid.rider_pictures()[0] == EventInstance.CYCLIST_BY_VIEW,
			"and one rolled as the kid is drawn as the kid")
	var travelled := 0.0
	for _i in 600:
		if pelican.is_finished:
			break
		pelican._process(STEP)
		kid._process(STEP)
		travelled = pelican.path_travelled()
	t.check(travelled > 200.0, "the pelican rode %.0fpx of its 300px line" % travelled)
	t.check(pelican.is_pelican and pelican.rider_pictures()[0] == EventInstance.PELICAN_BY_VIEW,
			"and is still drawn as the pelican at the end of it")
	t.check(not kid.is_pelican, "and the kid is still the kid")
	var dog := events.spawn_warned(EventCatalogue.by_id("loose_dog"), _ride(), true)
	t.check(not dog.is_pelican, "a loose dog sent the same way is never the pelican, whatever its roll")
	for instance in [pelican, kid, dog]:
		events.retire(instance)

## The same ride, rolled both ways: the same row, the same field and the same lethal reach at every
## point around it, the same speed. Only `rider_pictures()` differs.
func _test_a_pelican_is_the_cyclist_in_everything_but_the_picture(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var events := _city.events
	var pelican := events.spawn_warned(def, _ride(), true)
	var kid := events.spawn_warned(def, _ride(), false)
	for _i in 30:
		pelican._process(STEP)
		kid._process(STEP)
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
			if pelican.contribution_at(at) != kid.contribution_at(at):
				same_field = false
			if pelican.is_lethal_at(at) != kid.is_lethal_at(at):
				same_reach = false
			if kid.is_lethal_at(at):
				lethal_points += 1
	t.check(same_field, "the pelican's field is the cyclist's at every point around him")
	t.check(same_reach and lethal_points > 0,
			"and so is the reach that ends the day (%d of the points asked are inside it)"
			% lethal_points)
	t.check(pelican.rider_pictures() != kid.rider_pictures(), "only the picture differs")
	for instance in [pelican, kid]:
		events.retire(instance)

## A straight 300px line up the arterial's sidewalk, the kind `spawn_warned()` is handed.
func _ride() -> PackedVector2Array:
	var from := CrowdLanes.arterial_pavement(_city.map)
	return PackedVector2Array([from, from + Vector2(0.0, -300.0)])

## *(Inbox #527 in azure-tapir, the player: "when the pelican spawns, when it's on screen, and when it's hitting the
## player ... logs should be correctly identifying it from the beginning".)* One pelican sent the
## way the director sends every cyclist (`_warn_down_her_line()`), from its warning to its hit:
##
## - **the roll is made as the warning goes up**, so the badge already names the pelican;
## - **its creation is told once** (`EventBus.pelican_spawned`), and the run log's `ahead` line for
##   it says `pelican`, with no line anywhere saying `cyclist`;
## - **its first frame on screen is told once**, however many frames it stays there;
## - **its first share of the meter is told once**, and a kid's never;
## - **its lethal reach covering her is told once**, ahead of the hard fail, and names the day's
##   loss `pelican` (`EventManager.what_struck_her()`), where a kid's names `cyclist`;
## - **the observer's own lines call it `pelican`**: on screen, struck, and nearest.
func _test_the_pelican_is_named_and_told_from_its_warning_to_its_hit(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var events := _city.events
	var map := _city.map
	var her := CrowdLanes.arterial_pavement(map)
	for _tile in map.size.y / 2:
		if PendingWarning.down_her_line(map, def, her, Vector2.UP) != Vector2.INF:
			break
		her.y += Tuning.TILE_SIZE
	var stroller: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	t.add_child(stroller)
	stroller.set_physics_process(false)
	stroller.reset_at(her)
	events._player = stroller
	var told := {"spawned": 0, "sighted": 0, "excited": 0, "struck": 0}
	var on_spawned := func(_instance: Variant) -> void: told["spawned"] += 1
	var on_sighted := func(_instance: Variant) -> void: told["sighted"] += 1
	var on_excited := func(_instance: Variant) -> void: told["excited"] += 1
	var on_struck := func(_instance: Variant) -> void: told["struck"] += 1
	EventBus.pelican_spawned.connect(on_spawned)
	EventBus.pelican_sighted.connect(on_sighted)
	EventBus.pelican_excited_her.connect(on_excited)
	EventBus.pelican_struck_her.connect(on_struck)
	t.check(EventBus.pelican_spawned.is_connected(VisitCounter._on_pelican_spawned)
			and EventBus.pelican_sighted.is_connected(VisitCounter._on_pelican_sighted)
			and EventBus.pelican_excited_her.is_connected(VisitCounter._on_pelican_excited_her)
			and EventBus.pelican_struck_her.is_connected(VisitCounter._on_pelican_struck_her),
			"the page's counter listens to all four of the pelican's signals")
	Telemetry.begin_memory_log()
	Telemetry.begin_day(Tuning.RUN_TAUGHT_DAY, 1, SEED, SEED, 180.0)

	var before := events.instances().size()
	events.pelican_share = 1.0
	events._warn_down_her_line(def, her, Vector2.UP)
	events.pelican_share = EventManager.PELICAN_SHARE
	var warning: PendingWarning = events.pending_warnings().back() \
			if not events.pending_warnings().is_empty() else null
	t.check(warning != null and warning.is_pelican and warning.logged_name() == "pelican",
			"the roll is made as the warning goes up, so the warning is already the pelican's")
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.setup(events, stroller)
	edge._measure(STEP)
	var badges: Array[String] = []
	for badge in edge.announcing():
		badges.append(str(badge["id"]))
	t.check(badges.has("pelican") and not badges.has("cyclist"),
			"and its badge's line names the pelican (%s)" % [badges])
	edge.free()

	var pelican: EventInstance = null
	var elapsed := 0.0
	while elapsed < def.telegraph_time + 3.0 and pelican == null:
		events._run_the_warnings(STEP, her)
		elapsed += STEP
		if events.instances().size() > before:
			pelican = events.instances().back()
	t.check(pelican != null and pelican.is_pelican,
			"the warning ends in a pelican, %.2fs after it went up" % elapsed)
	if pelican == null:
		_untangle(events, stroller, [on_spawned, on_sighted, on_excited, on_struck])
		return
	t.check(told["spawned"] == 1, "its creation is told once (%d)" % told["spawned"])

	events._report_the_pelicans_in_view()
	t.check(told["sighted"] == 0, "created just off screen, it is not yet seen")
	# `reset_at()` rather than a bare move, so the camera's screen centre, which a headless run never
	# smooths along, is on her: what counts as on screen is measured about it.
	stroller.reset_at(pelican.global_position + Vector2(200.0, 0.0))
	for _i in 3:
		events._physics_process(STEP)
	t.check(told["sighted"] == 1,
			"on screen for three physics frames, its first is told once (%d)" % told["sighted"])

	pelican.accumulate_landed(0.0)
	t.check(told["excited"] == 0, "nothing landed is nothing told")
	pelican.accumulate_landed(1.5)
	pelican.accumulate_landed(2.0)
	var kid := events.spawn_warned(def, _ride(), false)
	kid.accumulate_landed(4.0)
	t.check(told["excited"] == 1,
			"its first share of the meter is told once, and a kid's never (%d)" % told["excited"])

	var observer := TelemetryObserver.new()
	observer._city = _city
	observer._map = map
	observer._player = stroller
	observer._baby = stroller.get_node("Baby") as Baby
	observer._listen()
	EventBus.pelican_sighted.emit(pelican)

	stroller.global_position = pelican.global_position
	events._check_hard_fails()
	t.check(told["struck"] == 1 and events.what_struck_her() == "pelican",
			"its reach covering her is told once and names the day's loss the pelican's (%d, '%s')"
			% [told["struck"], events.what_struck_her()])
	t.check(observer._nearest().begins_with("pelican "),
			"and the nearest thing a lost line names is the pelican (%s)" % observer._nearest())
	observer.free()
	events._hard_failed = false
	events._struck_by = ""
	stroller.global_position = kid.global_position
	events.retire(pelican)
	events._retire_finished()
	events._check_hard_fails()
	t.check(events.what_struck_her() == "cyclist" and told["struck"] == 1,
			"where a kid's reach names the cyclist, and tells nothing of a pelican ('%s')"
			% events.what_struck_her())
	events._hard_failed = false
	events._struck_by = ""
	events.retire(kid)

	var lines: Array[String] = Telemetry.current_log().lines
	var ahead := false
	var on_screen := false
	var struck := false
	var cyclist_lines: Array[String] = []
	for line in lines:
		ahead = ahead or line.contains("pelican comes at her from")
		on_screen = on_screen or line.contains("pelican on screen at")
		struck = struck or line.contains("pelican struck her at")
		if line.contains("cyclist"):
			cyclist_lines.append(line)
	t.check(ahead, "the run log's line for its creation names the pelican")
	t.check(on_screen and struck, "and so do its lines for being seen and striking her")
	t.check(cyclist_lines.is_empty(),
			"and no line about it calls it a cyclist (%s)" % [cyclist_lines])
	_untangle(events, stroller, [on_spawned, on_sighted, on_excited, on_struck])

## Gives the city's manager back as the other tests left it, and lets go of the pelican signals.
func _untangle(events: EventManager, stroller: Stroller, listeners: Array) -> void:
	Telemetry.end_run()
	events._player = null
	stroller.free()
	var signals := [EventBus.pelican_spawned, EventBus.pelican_sighted, EventBus.pelican_excited_her,
			EventBus.pelican_struck_her]
	for i in signals.size():
		var told: Signal = signals[i]
		told.disconnect(listeners[i])
