@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## What the `TelemetryObserver` notes of a walk, read off a recording run log
## (`tests/recording_log.gd`) and not off a file: the escape's sections, a stuck walk, the trail
## and the events she met, and the frame line.
##
## The observer is handed the log it writes into (`TelemetryObserver.new(run_log)`), so every case
## here hands it the recording fake and asserts the lines it was handed, in the fake's shape
## (`"<clock> <kind> <text>"`). How the real log lays a line out on disk, and the pictures it
## writes, are `tests/test_telemetry.gd`'s. The observer is the one object under test, with real
## frames passing so its per-frame watchers run as they do in play.
##
## **The player, the baby and the day's clock are built bare** (`Stroller.new()`, `Baby.new()`,
## `DayController.new()`) and not faked: the observer is typed against those classes and has no
## narrower interface to hand a fake, and what it reads off them (a position, a velocity, the
## meters, the clock's reading) is state a case sets on the real node, as the game does. The
## event source it watches is a stand-in where a case needs one (`StandInSource`, holding one plain
## `EventInstance` set up with a catalogue row), since the observer asks it only for `instances()` and its `sources`.
##
## **No case builds a real `City`**: the observer is handed the run, the city's map, its events,
## today's streets and the crowd's sources (`setup()`, `watch_city()`), and the cases hand it a
## `RunState`, a map, a `StandInEvents` (a `FakeEventManager` that answers a day's plans as the case
## sets them), a `DayStreets` of no day (`DayStreets.new()`, which holds a null tree and no closures
## as a day with none does) and the base `ExcitementSources`, which answers nothing. A map is a
## hand-drawn one (`StreetMap.full()`) for a case that needs only streets under her feet, and a
## generated one (`CityMapCache.of()`, a copy of a city built once per process, no `City` node) for
## the one case that plans a day from it.
##
## The case that plans a day beside the observer
## (`_test_the_trail_and_the_met_events_scan_do_not_touch_gameplay`) is a combined suite for a
## stated reason: it pins a guarantee between the observer and the planner, that four hundred frames
## of the observer's watchers leave the map a later day is planned from as it was, so that day plans
## identically. Only the planner's input can show it, so that case plans a day over a generated map
## (a hand-drawn one has no calm ground or home for a day to plan on); the observer is handed no
## random stream, so it has none to disturb.

const PlanSignature := preload("res://tests/plan_signature.gd")
const CityMapCache := preload("res://tests/city_map_cache.gd")
const RecordingLog := preload("res://tests/recording_log.gd")
## The seed of the run the observer is handed, a run of the test's own.
const RUN_SEED := 2
## The seed of the generated city the one planning case runs on.
const CITY_SEED := 4242

## One observer in the tree watching a running day clock, with the player, the baby and the clock
## it is handed — what `main` hands a day's observer (`world` given: `setup()`) or the escape's
## (`setup_escape()`, then the building's map or none). A test places the player, lets time pass
## through `frame()`, which moves the day's clock on and waits for a real frame — the observer
## mirrors that clock into the run log's as every real frame does — and reads the run log or the
## observer's own queries. The observer writes into the recording log it is handed (`_fresh_log()`); the
## test opens that log and its day itself.
class Rig extends RefCounted:
	const LENGTH := 180.0
	## How much of the day each real frame stands for: a tenth of a second, so a two-second hold is
	## twenty frames and not a hundred and twenty.
	const STEP := 0.1
	var observer: TelemetryObserver
	var player := Stroller.new()
	var baby := Baby.new()
	var clock := DayController.new()
	var tree: SceneTree
	var elapsed := 0.0

	func _init(parent: Node, run_log: Telemetry, map: WorldMap = null, day: WatchedDayParts = null,
			spikes := false) -> void:
		observer = TelemetryObserver.new(run_log)
		tree = parent.get_tree()
		if day != null:
			observer.setup(day.run, day.map, day.events, day.streets, day.crowd,
					player, baby, clock, null, spikes)
		else:
			observer.setup_escape(null, player, baby, clock, spikes)
			if map != null:
				observer.watch_building(map, null)
		parent.add_child(observer)
		clock.start(LENGTH)

	## Lets `seconds` of the day pass in one real frame.
	func frame(seconds := STEP) -> void:
		elapsed += seconds
		clock.tick(seconds)
		await tree.process_frame

	func free_all() -> void:
		for node: Node in [observer, player, baby, clock]:
			node.free()

## What a day's observer is handed besides her, the baby and the clock: the run, the city's map, the
## day's events, today's streets and the crowd's sources, each a plain value or a stand-in.
class WatchedDayParts extends RefCounted:
	var run := RunState.new()
	var map: CityMap
	var events := StandInEvents.new()
	var streets := DayStreets.new()
	var crowd := ExcitementSources.new()

	func _init(a_map: CityMap) -> void:
		run.start_run(RUN_SEED)
		map = a_map

	## Frees the stand-in events and every instance a case set up on them.
	func free_all() -> void:
		for plan in events.placed:
			if is_instance_valid(plan.live):
				plan.live.free()
		events.free()

## A day's events as the observer asks them (`plans()`): the plans a case sets, each placed with its
## instance live where the case put it. The base fake answers nothing else, and the real manager's
## streaming, which makes a plan live, is `tests/test_event_manager.gd`'s.
class StandInEvents extends FakeEventManager:
	var placed: Array[EventScheduler.Planned] = []

	## A plan of `row` placed at `at`, its instance live there.
	func place(row: String, at: Vector2) -> EventScheduler.Planned:
		var plan := EventScheduler.Planned.new(EventCatalogue.by_id(row), at)
		plan.live = EventInstance.new()
		plan.live.setup(plan.def, at)
		placed.append(plan)
		return plan

	## Overrides EventManager.plans.
	func plans() -> Array[EventScheduler.Planned]:
		return placed

## The recording log the case in hand writes into, made by `_fresh_log()` so no case reads another's
## lines. Freed with the suite.
var _log: CountingLog
var _made: Array[CountingLog] = []

## The recording log, counting how often the observer restarts a section's clock through
## `restart_section_clock()`, which also restarts the real log's snapshot schedule, as against
## `set_clock(0.0)`, which moves the clock alone.
class CountingLog extends RecordingLog:
	var restarts := 0

	## Overrides recording_log.restart_section_clock.
	func restart_section_clock() -> void:
		restarts += 1
		super()

## The lines of `kind`, by the kind field the log keeps them in (`"<clock> <kind> <text>"`), so a
## word in a line's text is never taken for its kind.
func _lines_of(kind: String) -> Array[String]:
	var found: Array[String] = []
	for line in _log.lines:
		if line.get_slice(" ", 1) == kind:
			found.append(line)
	return found

## The sum of the event fields at a point, which the stand-in source answers as nothing.
class NoFields:
	func total_at(_at: Vector2) -> float:
		return 0.0

## The event source of a building with one live event, as `EventManager` answers the observer.
class StandInSource extends Node:
	var live: Array[EventInstance] = []
	var sources := NoFields.new()

	func instances() -> Array[EventInstance]:
		return live

func run(t) -> void:
	await _test_the_escape_is_in_the_run_log_as_a_day_is(t)
	_test_a_retried_section_restarts_the_clock(t)
	await _test_a_stuck_player_is_logged_once(t)
	await _test_a_free_walk_is_never_logged_as_blocked(t)
	await _test_idling_with_no_input_is_never_logged_as_blocked(t)
	await _test_a_capture_is_never_logged_as_blocked(t)
	await _test_the_trail_is_sampled_by_distance_not_by_frame(t)
	await _test_the_trail_carries_whether_she_was_running(t)
	await _test_a_lost_day_restarts_the_trail(t)
	await _test_met_means_entering_the_outer_radius_not_merely_being_streamed_in(t)
	await _test_the_trail_and_the_met_events_scan_do_not_touch_gameplay(t)
	await _test_the_observer_watches_its_frames_on_real_frames(t)
	for made in _made:
		made.free()

## Makes a recording log and makes it the one the next case writes into.
func _fresh_log() -> void:
	_log = CountingLog.new()
	_made.append(_log)

## A retried section's clock starts at zero, and it gets there through the log's
## `restart_section_clock()`, which clears the automatic-snapshot schedule the real log keeps
## (`tests/test_telemetry.gd` asserts what that call does to the schedule).
func _test_a_retried_section_restarts_the_clock(t) -> void:
	_fresh_log()
	var player := Stroller.new()
	var baby := Baby.new()
	var clock := DayController.new()
	var observer := TelemetryObserver.new(_log)
	observer.setup_escape(null, player, baby, clock, false)
	_log.begin_run(0)
	_log.begin_section(DaySpec.BUILDING_DAY, "Escape the building", 4242, 180.0)
	_log.set_clock(45.0)
	observer.start_section(true)
	t.check(_log.restarts == 1,
			"a retry puts the clock back through restart_section_clock(), which restarts the "
			+ "snapshot schedule with it, and not through set_clock(0.0) (%d calls)" % _log.restarts)
	t.check(_log.clock() == 0.0, "a retry's clock starts over at zero, as it always did")
	t.check(_log.lines.back().begins_with("0.0 start restarted"),
			"and the start line says it began again, timed from its own start (got '%s')"
			% _log.lines.back())
	observer.free()
	clock.free()
	baby.free()
	player.free()

## A point on the first sidewalk tile of `map`, where she can stand for a case that needs only a
## street under her feet.
func _on_a_sidewalk(map: CityMap) -> Vector2:
	for y in map.size.y:
		for x in map.size.x:
			if map.tile_at(Vector2i(x, y)) == GameEnums.TileType.SIDEWALK:
				return map.tile_to_world(Vector2i(x, y))
	return Vector2.ZERO

## *"The escape shouldn't behave any different than the rest of the game."* Both sections are
## watched by the day's own observer, handed the day's clock and told which world she is in — so
## this drives the calls the run session makes, in its order, against a building of one masked man
## (a plain `EventInstance` set up with the catalogue's `masked_pursuer` row, as the real building's
## answers: waiting, not telegraphing, warning by radius) and a city of streets only: a section entered, a frame of every watcher, the masked man met, the section lost through
## the day's own `day_finished()`, the same section again, then the city entered and left by the
## tunnel. What a day writes that a section has nothing to say about — the corridor, the chalk
## mark — must stay silent rather than crash.
func _test_the_escape_is_in_the_run_log_as_a_day_is(t) -> void:
	var start := Vector2(100.0, 100.0)
	var man := EventInstance.new()
	man.setup(EventCatalogue.by_id("masked_pursuer"), start + Vector2(0.0, -200.0))
	var events := StandInSource.new()
	events.live.append(man)
	var player := Stroller.new()
	player.global_position = start
	player.facing = Vector2.UP
	var baby := Baby.new()
	var clock := DayController.new()
	_fresh_log()
	# The run the escape's city stands in, handed to the observer as the session hands it the boot's.
	var day := WatchedDayParts.new(StreetMap.full())
	var observer := TelemetryObserver.new(_log)
	observer.setup_escape(day.run, player, baby, clock, false)
	t.add_child(observer)

	_log.begin_run(0)
	_log.begin_section(DaySpec.BUILDING_DAY, "Escape the building", 4242, 180.0)
	observer.watch_building(CityMap.new(), events)
	observer.start_section(false)
	clock.start(180.0)
	# One frame of every watcher a day runs, in a building with no map, no corridor, no crowd and
	# no resistance: the ones with nothing to ask have to say nothing rather than fail.
	await t.get_tree().process_frame
	player.global_position = man.global_position + Vector2(man.def.outer_radius * 0.5, 0.0)
	clock.tick(12.5)
	await t.get_tree().process_frame
	clock.failure_reason = "They were on the stairs."
	observer.day_finished(GameEnums.DayResult.LOST_HARD_FAIL, "masked-pursuer")
	player.global_position = start
	observer.start_section(true)

	player.global_position = _on_a_sidewalk(day.map)
	observer.watch_city(day.map, day.events, day.streets, day.crowd)
	observer.start_section(false)
	clock.start(180.0)
	await t.get_tree().process_frame
	_log.set_clock(40.0)
	clock.tick(40.0)
	clock.exit_reached = CityEdge.Kind.TUNNEL
	observer.day_finished(GameEnums.DayResult.WON)

	_log.end_run()
	var starts := _lines_of("start")
	var losts := _lines_of("lost")
	var lost := losts[0] if losts.size() == 1 else ""
	var nears := _lines_of("near")
	var near := nears[0] if not nears.is_empty() else ""
	var homes := _lines_of("home")
	var home := homes[0] if homes.size() == 1 else ""
	t.check(losts.size() == 1 and homes.size() == 1,
			"one lost line and one home line (%d, %d)" % [losts.size(), homes.size()])
	t.check(starts.size() == 3, "each section start writes a start line (%d)" % starts.size())
	if starts.size() == 3:
		t.check(starts[0].contains("entered the building at ("),
				"the building is entered at one of its own tiles (got '%s')" % starts[0])
		t.check(starts[1].begins_with("0.0 ") and starts[1].contains("restarted the building"),
				"a retry says so, timed from its own start (got '%s')" % starts[1])
		t.check(starts[2].contains("entered the city at ("),
				"and the city is entered the same way (got '%s')" % starts[2])
	t.check(near.contains("masked_pursuer"),
			"meeting the masked man is a near line, as meeting a dog is (got '%s')" % near)
	t.check(lost.begins_with("12.5 ")
			and lost.contains("lost_hard_fail in the building after 12.5s to masked-pursuer")
			and lost.contains("They were on the stairs.") and lost.contains("near: masked_pursuer"),
			"losing the section names the result, the section, the cause, the reason and what was "
			+ "near (got '%s')" % lost)
	t.check(lost.contains("exc ") and lost.contains("events "),
			"with the meter breakdown a day's losing line carries (got '%s')" % lost)
	t.check(home.contains("escaped by the tunnel, 140.0s to spare"),
			"and getting out is a home line with the way out and the margin (got '%s')" % home)
	t.check(_lines_of("path").is_empty() and _lines_of("contact").is_empty(),
			"no corridor and no chalk mark are written for a walk that has neither")

	observer.free()
	clock.free()
	baby.free()
	player.free()
	day.free_all()
	man.free()
	events.free()

## A bare observer in the tree on a running day clock, with a map of no streets for the tile in the
## sentence: `Rig.new(t, _log, CityMap.new())` hands the observer what `main` hands the escape's —
## the player, the baby, the day's clock and the world — and every test lets real frames pass.
## `CityMap.new()` is a real map with nothing generated onto it — `world_to_tile` is arithmetic on
## `Tuning.TILE_SIZE` and asks the generator for nothing.
func _blocked_rig(t) -> Rig:
	_fresh_log()
	return Rig.new(t, _log, CityMap.new())

## Holds `action` for `hold` seconds of real frames — `Input.action_press`, the same call
## `src/dev/auto_screenshot.gd` uses for `--walk`, so this is the polled state `Stroller` itself
## reads and not a shortcut invented for the test. `here` is where she stands throughout, which is
## the rig's stand-in for a wall: displacement is exactly zero rather than merely small.
func _hold_against_a_wall(rig: Rig, action: String, here: Vector2, hold: float) -> void:
	rig.player.global_position = here
	Input.action_press(action)
	for i in int(round(hold / Rig.STEP)):
		await rig.frame()
	Input.action_release(action)

func _blocked_lines() -> Array[String]:
	_log.end_run()
	return _lines_of("blocked")

## Held for a couple of seconds against a wall that never gives: one line, not one a frame, and
## it is not written until the hold has actually run past `BLOCKED_HOLD_TIME`.
func _test_a_stuck_player_is_logged_once(t) -> void:
	var rig := _blocked_rig(t)
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, 180.0)

	await _hold_against_a_wall(rig, "move_right", Vector2(100.0, 100.0), 2.0)

	var blocked := _blocked_lines()
	t.check(blocked.size() == 1,
			"pressing into a wall for 2s writes exactly one blocked entry (got %d)"
			% blocked.size())
	if not blocked.is_empty():
		t.check(blocked[0].contains("90°"),
				"and it names the bearing pressed (got '%s')" % blocked[0])
	rig.free_all()

## The same held key, but she is actually covering ground — her position advances every frame by
## more than `TelemetryObserver.BLOCKED_DRIFT` before the hold ever reaches
## `TelemetryObserver.BLOCKED_HOLD_TIME`. A run this ordinary must never read as stuck.
func _test_a_free_walk_is_never_logged_as_blocked(t) -> void:
	var rig := _blocked_rig(t)
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, 180.0)

	Input.action_press("move_right")
	var here := Vector2(100.0, 100.0)
	for i in int(round(3.0 / Rig.STEP)):
		here.x += Tuning.WALK_SPEED * Rig.STEP
		rig.player.global_position = here
		await rig.frame()
	Input.action_release("move_right")

	t.check(_blocked_lines().is_empty(), "walking freely for 3s is never logged as blocked")
	rig.free_all()

## `Stroller.is_idle()`, which the observer's idling watch reads, is the legitimate stand-still,
## and a different condition from this one on purpose: idling asks nothing about input at all, so a player who
## simply lets go of every key must never be told she is blocked.
func _test_idling_with_no_input_is_never_logged_as_blocked(t) -> void:
	var rig := _blocked_rig(t)
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, 180.0)

	rig.player.global_position = Vector2(100.0, 100.0)
	for i in int(round(3.0 / Rig.STEP)):
		await rig.frame()

	t.check(_blocked_lines().is_empty(),
			"standing idle with no direction held is never logged as blocked")
	rig.free_all()

## M59's own interaction: `chatting_mother` locks input with `Stroller.detain()`, and a captured
## player may well be holding a key the whole way through it — which is exactly what
## the blocked watcher reads. Without the gate on `_player.is_detained()` a capture would write
## itself down twice: once as `chat`, by `EventManager`, and once as `blocked`, by the observer, for
## the same held key. And the gate has to let go the instant the capture ends, or a real stall
## picked up right after one hides behind a stale anchor.
func _test_a_capture_is_never_logged_as_blocked(t) -> void:
	var rig := _blocked_rig(t)
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, 180.0)

	# A conversation running: holding a direction the whole way through it must never surface as
	# a stall, whatever `BLOCKED_HOLD_TIME` says.
	rig.player.detain(2.0)
	await _hold_against_a_wall(rig, "move_right", Vector2(100.0, 100.0), 2.5)

	# The capture is over — a Stroller out of the tree has no physics frames to count it down, so
	# she is put back where she stands the way `main` puts her back (`reset_at()` ends a detention)
	# — and the same held key against the same wall is a genuine stall again.
	var during := _lines_of("blocked").size()
	t.check(during == 0, "a held key through the capture itself writes no blocked entry (got %d)" % during)
	rig.player.reset_at(Vector2(100.0, 100.0))
	await _hold_against_a_wall(rig, "move_right", Vector2(100.0, 100.0), 1.5)

	var blocked := _blocked_lines()
	t.check(blocked.size() == 1,
			"the capture writes nothing, and a real stall right after it is still caught (got %d)"
			% blocked.size())
	rig.free_all()


## An observer on a running day clock with the player standing where a test places her. The trail
## is the observer's own record of the frames that passed, so the frames are real ones.
func _trail_rig(t) -> Rig:
	_fresh_log()
	return Rig.new(t, _log)

## Distance sampling, not frame sampling: many small steps inside one tile must leave the trail
## alone, and the first step to cross a tile of distance — however many frames it took — must add
## exactly one point.
func _test_the_trail_is_sampled_by_distance_not_by_frame(t) -> void:
	var rig := _trail_rig(t)
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, 180.0)
	var here := Vector2(100.0, 100.0)

	rig.player.global_position = here
	await rig.frame()
	t.check(rig.observer.trail().size() == 1, "the very first sample always leaves a point")

	for i in 20:
		here.x += 1.0
		rig.player.global_position = here
		await rig.frame()
	t.check(rig.observer.trail().size() == 1,
			"twenty one-pixel steps inside a tile leave the trail at one point (got %d)"
			% rig.observer.trail().size())

	here.x += TelemetryObserver.TRAIL_SAMPLE_DISTANCE
	rig.player.global_position = here
	await rig.frame()
	t.check(rig.observer.trail().size() == 2,
			"crossing a tile of distance writes exactly one more point, however many frames it took")

	_log.end_run()
	rig.free_all()

## The third component of a sample is `Stroller.run_excess_ratio()` at the moment it was taken —
## 0.0 at a walk, above 0.0 the instant she is running faster than a walk — so the dusk map can
## colour a run stretch differently from a walked one without a second trail to keep in step.
func _test_the_trail_carries_whether_she_was_running(t) -> void:
	var rig := _trail_rig(t)
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, 180.0)
	rig.player.velocity = Vector2.ZERO
	rig.player.global_position = Vector2.ZERO
	await rig.frame()
	t.check(rig.observer.trail()[0].z == 0.0, "a sample taken at a walk carries no run ratio")

	rig.player.velocity = Vector2(Tuning.RUN_SPEED, 0.0)
	rig.player.global_position = Vector2(TelemetryObserver.TRAIL_SAMPLE_DISTANCE, 0.0)
	await rig.frame()
	t.check(rig.observer.trail()[1].z > 0.0,
			"and a sample taken at a sprint carries its run_excess_ratio (got %.2f)"
			% rig.observer.trail()[1].z)

	_log.end_run()
	rig.free_all()

## `start_day()` resets everything else about yesterday, and the trail is no exception: a rewound
## day was not walked, so the picture of it must start from nothing rather than carrying the
## abandoned attempt's trail into the retry.
func _test_a_lost_day_restarts_the_trail(t) -> void:
	var day := WatchedDayParts.new(StreetMap.full())
	_fresh_log()
	var rig := Rig.new(t, _log, null, day)
	# Not added to the tree: a bare `Stroller.new()` has no `Camera2D` child, which only the scene
	# it is normally instanced from provides, and `start_day()` reads nothing that needs one.
	rig.player.global_position = _on_a_sidewalk(day.map)
	rig.player.facing = Vector2.DOWN
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, 180.0)

	rig.observer.start_day()
	rig.player.global_position += Vector2(200.0, 0.0)
	await rig.frame()
	t.check(not rig.observer.trail().is_empty(), "the trail records a point during the day")

	rig.observer.start_day()
	t.check(rig.observer.trail().is_empty(),
			"a new day's start — including a rewound day's — starts the trail over from nothing")

	_log.end_run()
	rig.free_all()
	day.free_all()

## The dusk map's whole reason to exist: `was_live` marks a plan the moment
## `EventManager.stream_around` loads it at `Tuning.EVENT_STREAM_RADIUS` (900px), which is more
## than twice the reach (`def.outer_radius`, typically 150px) of a row that has not telegraphed
## anything yet. "Met" has to be the narrower, honest question — did the field that actually costs
## her something ever reach her — or a day that met eight of forty events would read as forty.
func _test_met_means_entering_the_outer_radius_not_merely_being_streamed_in(t) -> void:
	var day := WatchedDayParts.new(StreetMap.full())
	var at := _on_a_sidewalk(day.map)
	# A plan live where it was placed, as streaming leaves one that has not telegraphed: in the
	# world, with her still outside its reach.
	var plan := day.events.place("loudspeaker", at)

	_fresh_log()
	var rig := Rig.new(t, _log, null, day)
	_log.begin_run(0)
	_log.begin_day(3, 1, 1, 1, 180.0)

	rig.player.global_position = at + Vector2(plan.def.outer_radius + 200.0, 0.0)
	await rig.frame()
	t.check(not rig.observer.met_events().has(plan),
			"being streamed in is not being met — she has not come within the outer radius yet")

	rig.player.global_position = at + Vector2(plan.def.outer_radius - 10.0, 0.0)
	await rig.frame()
	t.check(rig.observer.met_events().has(plan),
			"entering the outer radius — the field she can actually feel — is what counts as met")

	_log.end_run()
	rig.free_all()
	day.free_all()

## `_test_tracing_a_day_does_not_change_it` is the invariant's own test, and it does not reach
## either of these two: it calls `EventScheduler.build_day` directly and never instantiates an
## observer at all, so it says nothing about the trail or the met-events watcher — the two
## per-frame watchers M66 added, both of which run every frame the observer is alive and both of
## which read live gameplay objects (the player's position; every event instance's
## `global_position`). Neither takes a `RandomNumberGenerator` — there is no `rng` parameter to
## consume from, unlike the hoisted-roll systems the invariant's comment warns about — and neither
## writes anywhere but the observer's own trail and met events. That is a claim about the
## code, and this is the test that would catch it being wrong: it drives both across four hundred
## real frames of a real day, with the log on, and requires the day after to plan exactly as it
## would have if the drive had never happened — the only way that can hold is if nothing either
## watcher did changed `map`, the one input the next day's plan reads here (the plan is made from
## a fresh random stream, so what the check pins is the map).
func _test_the_trail_and_the_met_events_scan_do_not_touch_gameplay(t) -> void:
	var map := CityMapCache.of(CITY_SEED)
	var day := WatchedDayParts.new(map)
	var at := map.doorstep_world_position()
	var plan := day.events.place("loudspeaker", at)

	# What day 4 plans, computed before the trail is ever walked.
	var quiet := PlanSignature.of(map, 4)

	_fresh_log()
	var rig := Rig.new(t, _log, null, day)
	rig.player.global_position = at + Vector2(plan.def.outer_radius + 200.0, 0.0)

	_log.begin_run(0)
	_log.begin_day(3, 1, 1, 1, 180.0)
	var here: Vector2 = rig.player.global_position
	var towards := (at - here).normalized()
	for i in 400:
		here += towards * TelemetryObserver.TRAIL_SAMPLE_DISTANCE
		rig.player.global_position = here
		await rig.frame()
	_log.end_run()

	t.check(rig.observer.trail().size() > 300,
			"the drive actually sampled the trail, not a vacuous pass (got %d points)"
			% rig.observer.trail().size())
	t.check(not rig.observer.met_events().is_empty(),
			"and walked close enough to mark the plan met, so the scan actually ran")

	var traced := PlanSignature.of(map, 4)
	t.check(quiet == traced, "four hundred frames of trail sampling and met-events scanning, "
			+ "with the log on, leave what day 4 plans untouched")

	rig.free_all()
	day.free_all()

## The observer on real frames, `--spikes` given, on the bare map rig: it hands its frame watch each
## frame's length and, for the spike line, her tile and the live events (none), so a `frame` line
## reaches the run log once a second of frames has passed. The engine's time scale makes that
## second a handful of frames, and is put back after.
func _test_the_observer_watches_its_frames_on_real_frames(t) -> void:
	_fresh_log()
	var rig := Rig.new(t, _log, CityMap.new(), null, true)
	rig.player.global_position = Vector2(100.0, 100.0)
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, Rig.LENGTH)
	var scale := Engine.time_scale
	Engine.time_scale = 50.0
	var framed := false
	for i in 400:
		await rig.frame()
		framed = not _lines_of("frame").is_empty()
		if framed:
			break
	Engine.time_scale = scale
	t.check(framed, "the observer's frames write the frame line once a second of them has passed")
	_log.end_run()
	rig.free_all()
