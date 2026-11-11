extends RefCounted
## Protester pointing (M65): which of the eight `protester_point_*` poses a protest rank draws,
## and when it stays the plain `protester.svg` instead. See `docs/EVENTS.md`, the `protest` row,
## and `EventPictures.protester_texture()`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")
const SEED := 4242

var _city: City

func run(t: TestRunner) -> void:
	var standing: Array[Node] = t.get_children()
	_test_bearing_sectors_pick_the_matching_pose(t)
	_test_a_bearing_off_centre_still_rounds_to_its_sector(t)
	_test_plain_pose_with_no_objective(t)
	_test_plain_pose_on_a_mark_step(t)
	_test_pointing_pose_on_a_perform_step(t)
	await _test_a_protest_the_city_makes_points_where_its_director_does(t)
	await _test_a_protest_with_no_director_points_at_nothing(t)
	if _city != null:
		_city.free()
	for child in t.get_children():
		if not child in standing:
			child.free()

# ---------------------------------------------------------------- bearing ---

## The exact inverse of `protester_texture()`'s own `atan2(toward.x, -toward.y)`, so feeding a
## bearing in and reading it back out is round-trip rather than a second formula to disagree with
## the first.
func _at_bearing(degrees: float, distance: float) -> Vector2:
	var radians := deg_to_rad(degrees)
	return Vector2(sin(radians), -cos(radians)) * distance

## One sample squarely inside each of the eight 45° sectors, so a swapped table entry shows up as
## a specific wrong pose rather than a single "not plain" check any of the eight would pass.
func _test_bearing_sectors_pick_the_matching_pose(t: TestRunner) -> void:
	var from := Vector2(100.0, 100.0)
	var sectors := [
		[0.0, EventPictures.PROTESTER_POINT_N, "north"],
		[45.0, EventPictures.PROTESTER_POINT_NE, "north-east"],
		[90.0, EventPictures.PROTESTER_POINT_E, "east"],
		[135.0, EventPictures.PROTESTER_POINT_SE, "south-east"],
		[180.0, EventPictures.PROTESTER_POINT_S, "south"],
		[225.0, EventPictures.PROTESTER_POINT_SW, "south-west"],
		[270.0, EventPictures.PROTESTER_POINT_W, "west"],
		[315.0, EventPictures.PROTESTER_POINT_NW, "north-west"],
	]
	for sector: Array in sectors:
		var objective: Vector2 = from + _at_bearing(sector[0], 200.0)
		t.check(EventPictures.protester_texture(from, objective) == sector[1],
				"bearing %.0f° points %s" % [sector[0], sector[2]])

## A bearing 20° either side of a sector's own centre is still well inside its 45°-wide band —
## the pose is picked by nearest, not by an exact match.
func _test_a_bearing_off_centre_still_rounds_to_its_sector(t: TestRunner) -> void:
	var from := Vector2.ZERO
	for offset: float in [-20.0, 20.0]:
		var objective := from + _at_bearing(90.0 + offset, 150.0)
		t.check(EventPictures.protester_texture(from, objective) == EventPictures.PROTESTER_POINT_E,
				"%.0f° off east still rounds to the east pose" % offset)

# ---------------------------------------------------------------- no objective ---

func _test_plain_pose_with_no_objective(t: TestRunner) -> void:
	t.check(EventPictures.protester_texture(Vector2.ZERO, Vector2.INF) == EventPictures.PROTESTER,
			"no objective at all draws the plain rank")
	t.check(EventPictures.protester_texture(Vector2(5.0, 5.0), Vector2(5.0, 5.0))
			== EventPictures.PROTESTER,
			"an objective on top of the protester draws the plain rank rather than dividing by zero")

# ---------------------------------------------------------------- the resistance's own steps ---
# The same city-and-director rig `tests/resistance_rig.gd` builds `ResistanceDirector` with, kept
# separate rather than shared so this file never writes to one the resistance suite also owns.

## The city of `SEED` in a run of its own (`RunCity.with_own_run()`), which every director built over
## it is handed (`ResistanceDirector.setup()`'s `run`): the run starts fresh, with no step done and
## nothing carried, and goes with the city.
##
## Freed rather than left standing: `City.build()` adds an `EventManager` child that acquires
## the "events" `AtlasLibrary` group in its own `_enter_tree()` and only gives it back in
## `_exit_tree()` (`src/events/event_manager.gd`). Several tests here each call this once, so a
## `_city` never freed would leave the group resident for the rest of the process — a suite
## sharing a later shard with `tests/test_telemetry.gd` then finds "events" already held before
## its own load/release test even starts.
func _build_city(t: TestRunner) -> void:
	if _city != null:
		_city.free()
	_city = RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

func _director(t: TestRunner) -> ResistanceDirector:
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city.map, _city.run, _city.events, _city.streets(), _city.fronts(), _city, null,
			_city.spawn_siting)
	return director

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:resistance" % [SEED, day])
	return rng

## Hands the city's events a recording drawer to give every instance they make from here on, as
## `tests/test_pelican.gd` does: a look is handed its drawer as it is made.
func _record_the_drawing() -> void:
	_city.events.world.drawer = RecordingEventDrawer.new()

## The pictures a protest the city's events made stands its rank in, drawn: it was handed the
## recording drawer its manager's spawner hands every instance (`_record_the_drawing()`), and real
## frames pass so its slices are put in beside it and drawn, one protester each. Only what is drawn
## on the protest and its slices is read, since the drawer is every later instance's too.
func _rank_drawn(t: TestRunner, protest: EventInstance) -> Array[String]:
	var drawer := protest.drawer as RecordingEventDrawer
	for i in 3:
		await t.get_tree().process_frame
	var pictures: Array[String] = []
	var slices := (protest.look as SpreadLook).slices()
	for entry in drawer.shown():
		var slice := entry.canvas as SpreadLook.Slice
		var its_own: bool = entry.canvas == protest or (slice != null and slices.has(slice))
		if entry.kind == &"stand" and its_own:
			pictures.append(entry.picture)
	return pictures

## *(2026-09-11, the player: "the mark is findable now -- I don't think we need pointing for
## that.")* A pickup gives the protests' pointing hand-in (`EventManager.points_at`) nothing to hand back.
func _test_plain_pose_on_a_mark_step(t: TestRunner) -> void:
	_build_city(t)
	var director := _director(t)
	director.start_day(6, _rng(6), 300.0)
	var step := director.current_step()
	t.check(step != null and step.is_pickup, "day 6 offers the first chalk mark")
	t.check(_city.events.points_at.call() == Vector2.INF,
			"a mark step gives a protester nothing to point at")
	t.check(EventPictures.protester_texture(Vector2.ZERO, _city.events.points_at.call())
			== EventPictures.PROTESTER,
			"...so a protester anywhere in the city draws the plain rank")

## *(2026-09-11, the player: "but the other tasks are not as easy and need pointing.")* A perform
## step activates the protester's objective the moment the mark it belongs to is touched rather
## than waiting for a `start_day()` that does not come until tomorrow. Before the first arrow field
## settles, that objective is the contact `_begin_step()` already placed.
func _test_pointing_pose_on_a_perform_step(t: TestRunner) -> void:
	_build_city(t)
	var director := _director(t)
	director.start_day(6, _rng(6), 300.0)
	director.contact().complete_now()
	var step := director.current_step()
	t.check(step != null and not step.is_pickup, "the yeller perform is active")

	var objective: Vector2 = _city.events.points_at.call()
	t.check(objective != Vector2.INF, "a perform step gives a protester somewhere to point")
	t.check(objective == director.contact_position(),
			"before its first arrow choice, it is the step's own contact")

	var texture := EventPictures.protester_texture(objective + Vector2(0.0, 300.0), objective)
	t.check(texture != EventPictures.PROTESTER,
			"a protester standing away from the objective points rather than standing plain")

# ---------------------------------------------------------------- the wiring ---

## A protest the city's events make asks the director it was handed (`ResistanceDirector.setup()`
## hands `EventManager.points_at` its objective), not a node it looks up: its rank
## points where the director's objective is, every protester drawn in the pose that points there.
func _test_a_protest_the_city_makes_points_where_its_director_does(t: TestRunner) -> void:
	_build_city(t)
	var director := _director(t)
	director.start_day(6, _rng(6), 300.0)
	director.contact().complete_now()
	var objective: Vector2 = _city.events.points_at.call()
	t.check(objective != Vector2.INF, "the perform step gives the protest somewhere to point")
	_record_the_drawing()
	var protest := _city.events.spawn_extra(EventCatalogue.by_id("protest"),
			objective + Vector2(0.0, 300.0))
	t.check(protest.points_at.call() == objective,
			"a protest the city's events make asks the director it was handed")
	t.check(protest.drawer != null and protest.drawer == _city.events.world.drawer,
			"and draws through the drawer its manager's spawner hands every instance it makes")
	var expected := EventPictures.protester_texture(protest.global_position, objective)
	var rank: Array[String] = await _rank_drawn(t, protest)
	var pointing := rank.size() > 1 and expected != EventPictures.PROTESTER
	for picture in rank:
		pointing = pointing and picture == expected
	t.check(pointing, "and its rank of %d points at the objective (%s, drew %s)"
			% [rank.size(), expected.get_file(), rank])

## With no director handed in (the escape building, a bare rig) a protest has nothing to point at
## and stands its rank plain.
func _test_a_protest_with_no_director_points_at_nothing(t: TestRunner) -> void:
	_build_city(t)
	_record_the_drawing()
	var protest := _city.events.spawn_extra(EventCatalogue.by_id("protest"), Vector2(300.0, 300.0))
	t.check(not protest.points_at.is_valid() or protest.points_at.call() == Vector2.INF,
			"a protest with no director handed in has nothing to point at")
	var rank: Array[String] = await _rank_drawn(t, protest)
	var plain := rank.size() > 1
	for picture in rank:
		plain = plain and not EventPictures.POINTING_POSES.has(picture)
	t.check(plain, "and stands its rank of %d plain rather than pointing (%s)" % [rank.size(), rank])
