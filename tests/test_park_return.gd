extends RefCounted
## Day 12's walk home after the park is taken, played through the real transitions: the swing
## touched on a booted `Main`, the cordon closing round the park, the baby asleep, the day won or
## lost, the day's summary, and the next morning. *(azure-koala, finding 9: "day 12 after closing
## the park and walking back with sleeping baby softlocks the game".)*
##
## `tools/run.sh --route mark,task,calm,home` stops at the win, so it never shows the summary or the
## next dawn; this suite carries on through the day's end and the summary's continue, pressed
## through the viewport as a player presses it (`tests/booted_main.gd`), and asks what a softlock would be: the day that cannot end, the
## summary that cannot be left, or a morning that does not start (no running clock, a baby that is
## not awake, a cordon left from yesterday). Three cases, on a sweep of seeds:
## she asleep inside the park and leaving through the last gap with the baby asleep, the baby put to
## sleep elsewhere with the park taped behind her, and shut in with the baby asleep.
##
## **Each case boots `main` on a run of its own** (`RunState`, parked in a sitting of the suite's
## own, `Boot.home_playing()`) with a save at a scratch path, so nothing here leaks into the next
## suite or reaches the player's save, and nothing is put back afterwards.
##
## **Who takes the park.** The two cases that walk out through the last gap need to know where it
## is, which only the cordon holds (`ParkCordon.last_gap`, kept public for it; the world shows the gap
## only once it has closed), so they take the park with happenings of their own, handed the day's obstruction as the director
## hands it to its own at the swing (`ResistanceReads.day_reachability()`) and ticked by the suite with the
## day's clock; the director's own task for the swing is left open, since finishing it would send
## the task's pursuer after her too. The case that stands in the park until the day is lost has no
## use for the gap, so it finishes the swing's task as she does and ticks the director
## (`ResistanceDirector.tick()`, which runs the director's own happenings), and everything it asks
## of the cordon it reads off the world (`tests/cordon_in_the_world.gd`): the officers, and the
## park shut or not. That is also the only case in which the game clears the cordon when the lost
## day is played again, which is what it checks.
##
## **Combined by composition, for this reason:** the softlock it guards against is a chain across
## modules (the cordon closing, the baby asleep, the day ending, the summary, the next dawn), so the
## whole real `main` is played through it on a sweep of seeds; each boot is on a cached generated
## city (`tests/city_map_cache.gd`).

const Boot := preload("res://tests/booted_main.gd")
const MapCache := preload("res://tests/city_map_cache.gd")
const CordonInTheWorld := preload("res://tests/cordon_in_the_world.gd")
const ResistanceReads := preload("res://tests/resistance_reads.gd")
const SEEDS: Array[int] = [4242, 11, 13]
const STEP := 1.0 / 60.0
## How long a check lets the cordon work before calling it stuck, in seconds of day.
const PATIENCE := 40.0
## How long after the swing she sets off, in the walking cases: time to see the officers.
const REACTION := 2.0
const _SCRATCH_PATH := "user://test_park_return_scratch.json"

## What the case in progress booted (`_day_twelve()`): the boot with its scratch save, the home the
## suite's sitting is parked in, and the run that sitting holds; `_finish()` frees the boot and the
## home.
var _booted: Boot.Booted
var _home: Node
var _run: RunState
## The happenings of the suite's own that took the park (`_touch_the_swing()`), or null when the
## director took it.
var _happenings: ResistanceHappenings
## Where the swing is, set by `_touch_the_swing()`.
var _swing := Vector2.INF

func run(t) -> void:
	for seed_value in SEEDS:
		await _test_asleep_in_the_park_and_out_through_the_gap(t, seed_value)
		await _test_asleep_elsewhere_with_the_park_taped_behind_her(t, seed_value)
		await _test_shut_in_with_the_baby_asleep(t, seed_value)

# ------------------------------------------------------------------ fixture ---

## A booted `Main` standing at day 12's dawn on `seed_value`, a normal run, with the mark read and
## the swing offered. The run is the suite's own, in a sitting of its own the boot takes
## (`Boot.home_playing()`), so the game plays that seed at that day; the save is at a scratch path.
func _day_twelve(t, seed_value: int) -> Node2D:
	# `Main` rolls its own seed unless a command line or a save gives one: a save of this seed's run,
	# standing at day 12's dawn, is the way a test gives it, written to the scratch path the boot
	# reads. The run the boot plays is the sitting's, a fresh one the resume reads that save into.
	var written := RunState.new()
	written.start_run(seed_value)
	written.header.day = ResistanceSteps.swing_day()
	var save := GameSave.new(_SCRATCH_PATH)
	save.configure(RunConfig.parse(PackedStringArray(), "", false, false, {}, false))
	save.write(written, true)
	save.free()
	_run = RunState.new()
	_home = Boot.home_playing(t, _run)
	# A windowed release run whose only flag is the player's opt-out of the run log, whatever this
	# process's own command line says: any dev flag would refuse the save the resume reads.
	_booted = await Boot.boot(t, _SCRATCH_PATH,
			RunConfig.parse(PackedStringArray(["--no-telemetry"]), "", false, false, {}, false),
			func(unbooted: Node) -> void: unbooted.use_sitting_home(_home), false, MapCache.source())
	var main := _booted.main
	await Boot.press_title(t, main, "Right")
	t.check(Boot.city(main).map.seed_used == seed_value, "seed %d is the city under test (%d)"
			% [seed_value, Boot.city(main).map.seed_used])
	t.check(_run.header.day == ResistanceSteps.swing_day(), "booted at day %d (day %d)"
			% [ResistanceSteps.swing_day(), _run.header.day])
	# A resumed run opens on the day's brief; leaving it is what puts her on the street.
	if Boot.summary(main).is_showing():
		await Boot.press_continue(t, main)
	t.check(Boot.day(main).is_running() and not Boot.summary(main).is_showing(),
			"seed %d: day %d is under way" % [seed_value, _run.header.day])
	_touch_the_contact(Boot.resistance(main))
	return main

func _touch_the_contact(director: ResistanceDirector) -> void:
	var contact := director.contact()
	if contact:
		contact.complete_now()

## Puts her at the swing and answers where it is. The park is then taken either by the director,
## as the swing's task being done takes it (`through_the_director`: the cordon is the director's
## own, read off the world), or by happenings of the suite's own, handed the day's obstruction as the director hands it to its own at the touch, whose `cordon` says where its last
## gap is: the one thing a walk out through the gap needs, which nothing in the world shows before
## the gap closes.
func _touch_the_swing(t, main: Node2D, through_the_director := false) -> Vector2:
	var director := Boot.resistance(main)
	var swing := director.contact_position()
	Boot.player(main).global_position = swing
	_swing = swing
	_happenings = null
	if through_the_director:
		_touch_the_contact(director)
		return swing
	var city := Boot.city(main)
	_happenings = ResistanceHappenings.new()
	_happenings.setup(city.map, city.run, city.events, city.streets(), city.fronts(), city,
			city.atlas, null, city.spawn_siting)
	_happenings.start_day(_run.header.day, false)
	t.check(_happenings.take_the_park(ResistanceReads.day_reachability(Boot.city(main))[1]),
			"reaching the swing takes the park")
	return swing

func _camera_on(main: Node2D) -> Callable:
	return func(row: EventDef, feet: Vector2) -> bool:
		var centre: Vector2 = Boot.player(main).global_position
		var view := Rect2(centre - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
		var box := EventFootprints.footprint_of(row)
		if not box.has_area():
			return view.has_point(feet)
		return view.intersects(Rect2(feet + box.position, box.size))

## The city's own view looked through about her, as the game's camera does, or about nothing: what
## the cordon's officers are placed out of sight of (`SpawnSiting`'s).
func _look(main: Node2D, camera: bool) -> void:
	var at: Vector2 = Boot.player(main).global_position
	Boot.city(main).events.visible_view().look(
			Rect2(at - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0) if camera
			else Rect2(), null)

## One frame of the day: the happenings that hold the cordon (the suite's own, or the director's
## tick that runs the director's) and the day's own clock and win check.
func _frame(main: Node2D, shows: Callable) -> void:
	_look(main, shows.is_valid())
	if _happenings:
		_happenings.tick(STEP, Boot.player(main).global_position, Vector2.ZERO)
	else:
		Boot.resistance(main).tick(STEP)
	Boot.day(main).tick(STEP)

## Walks her toward `to` at the walking speed for `seconds`, a frame at a time.
func _walk(main: Node2D, to: Vector2, seconds: float, shows: Callable) -> void:
	var frames := int(seconds / STEP)
	for i in frames:
		if not Boot.day(main).is_running():
			return
		var here: Vector2 = Boot.player(main).global_position
		Boot.player(main).global_position = here.move_toward(to, Tuning.WALK_SPEED * STEP)
		_frame(main, shows)

## Waits out the cordon with her where she stands, until it closes (the suite's own happenings say
## so; the director's cordon ends the day with her inside it) or `PATIENCE` runs out.
func _wait_for_the_close(main: Node2D, shows: Callable) -> void:
	var waited := 0.0
	while (_happenings == null or (_happenings.cordon != null
			and not _happenings.cordon.is_closed())) and Boot.day(main).is_running() \
			and waited < PATIENCE:
		_frame(main, shows)
		waited += STEP

## Out through the last gap, `REACTION` after the touch, and on a tile's width past the tape.
func _walk_out_through_the_gap(main: Node2D, swing: Vector2, shows: Callable) -> void:
	_walk(main, swing, REACTION, shows)
	var exit := _happenings.cordon.last_gap
	var out := exit + (exit - swing).normalized() \
			* (Tuning.CLOSURE_BARRIER_DEPTH + Tuning.TILE_SIZE)
	_walk(main, out, 20.0, shows)

## The day's end seen from the summary: it comes up, is left with one press, and the next morning
## is a running day 13 with everything of the cordon gone.
func _check_the_next_morning(t, main: Node2D, label: String) -> void:
	t.check(Boot.summary(main).is_showing(), "%s: the won day's summary is up" % label)
	var map: CityMap = Boot.city(main).map
	await Boot.press_continue(t, main)
	t.check(_run.header.day == ResistanceSteps.swing_day() + 1,
			"%s: leaving the summary starts day %d (day %d)"
			% [label, ResistanceSteps.swing_day() + 1, _run.header.day])
	t.check(not Boot.summary(main).is_showing() and not t.get_tree().paused,
			"%s: with the summary gone and the tree running" % label)
	t.check(Boot.day(main).is_running() and Boot.day(main).phase == GameEnums.DayPhase.WALKING,
			"%s: the new day is running and she is walking" % label)
	t.check(Boot.baby(main).state == GameEnums.BabyState.AWAKE,
			"%s: the baby wakes with the day" % label)
	_check_no_cordon_stands(t, main, label, "the new day")
	var here: Vector2 = Boot.player(main).global_position
	t.check(here.distance_to(map.doorstep_world_position()) < Tuning.TILE_SIZE * 3.0,
			"%s: she stands at her own door (%s)" % [label, here])
	# And the day moves: a second of it ticks the clock down.
	var before: float = Boot.day(main).time_remaining
	Boot.day(main).tick(1.0)
	t.check(Boot.day(main).time_remaining < before, "%s: the clock runs" % label)

## Nothing of yesterday's cordon is left in the world: no officer on the city's entities, and the
## park no longer shut to anyone walking.
func _check_no_cordon_stands(t, main: Node2D, label: String, when: String) -> void:
	var city := Boot.city(main)
	t.check(CordonInTheWorld.officers(city).is_empty()
			and not CordonInTheWorld.is_shut(city.map, _swing),
			"%s: no cordon stands in %s" % [label, when])

func _finish(t) -> void:
	t.get_tree().paused = false
	_booted.free_all()
	_home.free()

# -------------------------------------------------------------------- cases ---

## The baby falls asleep inside the park, the cordon still closing; she walks out through the last
## gap with her asleep, and home.
func _test_asleep_in_the_park_and_out_through_the_gap(t, seed_value: int) -> void:
	var label := "seed %d, asleep in the park" % seed_value
	var main: Node2D = await _day_twelve(t, seed_value)
	var shows := _camera_on(main)
	var swing := _touch_the_swing(t, main)
	t.check(_happenings.cordon != null, "%s: reaching the swing starts the cordon" % label)
	_frame(main, shows)
	Boot.baby(main).force_sleep()
	t.check(Boot.day(main).phase == GameEnums.DayPhase.RETURNING,
			"%s: asleep, the day is the walk home" % label)
	var results: Array = []
	Boot.day(main).day_finished.connect(func(r: GameEnums.DayResult) -> void: results.append(r))
	_walk_out_through_the_gap(main, swing, shows)
	_wait_for_the_close(main, shows)
	t.check(_happenings.cordon.is_closed() and Boot.day(main).is_running(),
			"%s: the gap closes behind her, with her outside, and the day goes on" % label)
	t.check(Boot.day(main).is_running() and results.is_empty(),
			"%s: the day is still on, the baby asleep (%s)" % [label, results])
	t.check(Boot.baby(main).state == GameEnums.BabyState.ASLEEP, "%s: and still asleep" % label)
	Boot.player(main).global_position = Boot.city(main).map.home_world_position()
	_frame(main, shows)
	t.check(results == [GameEnums.DayResult.WON], "%s: home with her asleep wins (%s)"
			% [label, results])
	await _check_the_next_morning(t, main, label)
	_finish(t)

## Out first, settled elsewhere with the park taped behind her, then home: the rig's own route, on
## to the summary and the next morning.
func _test_asleep_elsewhere_with_the_park_taped_behind_her(t, seed_value: int) -> void:
	var label := "seed %d, settled outside" % seed_value
	var main: Node2D = await _day_twelve(t, seed_value)
	var shows := _camera_on(main)
	var swing := _touch_the_swing(t, main)
	_walk_out_through_the_gap(main, swing, shows)
	_wait_for_the_close(main, shows)
	t.check(_happenings.cordon.is_closed() and Boot.day(main).is_running(),
			"%s: the park is taped with her outside, and the day goes on" % label)
	var results: Array = []
	Boot.day(main).day_finished.connect(func(r: GameEnums.DayResult) -> void: results.append(r))
	Boot.baby(main).force_sleep()
	Boot.player(main).global_position = Boot.city(main).map.home_world_position()
	_frame(main, shows)
	t.check(results == [GameEnums.DayResult.WON], "%s: home asleep wins (%s)" % [label, results])
	await _check_the_next_morning(t, main, label)
	_finish(t)

## Standing in the park with the baby asleep as the last gap is taped: the day is lost to the
## cordon, the summary is left, and the day is played again from its dawn, with a cordon to come.
func _test_shut_in_with_the_baby_asleep(t, seed_value: int) -> void:
	var label := "seed %d, shut in asleep" % seed_value
	var main: Node2D = await _day_twelve(t, seed_value)
	var shows := _camera_on(main)
	_touch_the_swing(t, main, true)
	_frame(main, shows)
	t.check(not CordonInTheWorld.officers(Boot.city(main)).is_empty(),
			"%s: reaching the swing sends the police" % label)
	Boot.baby(main).force_sleep()
	var results: Array = []
	Boot.day(main).day_finished.connect(func(r: GameEnums.DayResult) -> void: results.append(r))
	_wait_for_the_close(main, shows)
	t.check(results == [GameEnums.DayResult.LOST_HARD_FAIL]
			and Boot.day(main).hard_fail_reason == ParkCordon.TRAPPED,
			"%s: shut in, the day is lost to the cordon (%s)" % [label, results])
	t.check(Boot.summary(main).is_showing(), "%s: the lost day's summary is up" % label)
	var day := _run.header.day
	await Boot.press_continue(t, main)
	t.check(_run.header.day == day and not Boot.summary(main).is_showing()
			and not t.get_tree().paused,
			"%s: leaving it plays day %d again (day %d)" % [label, day, _run.header.day])
	t.check(Boot.day(main).is_running() and Boot.day(main).phase == GameEnums.DayPhase.WALKING
			and Boot.baby(main).state == GameEnums.BabyState.AWAKE,
			"%s: the retry runs with the baby awake" % label)
	_check_no_cordon_stands(t, main, label, "the retry's dawn")
	_finish(t)
