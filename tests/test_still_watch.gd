@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `StillWatch`, the stillness heuristic behind `--quit-when-still`, driven the way `main` builds it:
## handed a city, her, and the day's clock through `setup()`, standing in a tree, and fed her
## position tick by tick on real physics frames (the tick her position changes on). Armed only once
## she has moved, frozen rather than reset while the day is not running, and reset — not frozen —
## every tick she is held (a detention, a wait at a red light). What it does when it fires is
## observed as the game sees it: a picture is asked for by adding an `AutoScreenshot` beneath it, and
## the suite switches that child's frames off the moment it arrives, since a headless run can take no
## picture and would quit the process.
##
## The geometry and signal half of `held` — `StillWatch.facing_a_red_light()` — is also driven alone
## below, over a bare `CityMap` and `TrafficSignals`.
##
## The watch sits in a `SubViewport` of the suite's own so the screen it reads is one the suite
## sets (`canvas_transform`), and its hold is `Tuning`-independent: one second of ticks is
## `Engine.physics_ticks_per_second` of them, whatever the frames' lengths. A check about when it
## fires reads a window of ticks around the hold, not the tick to the unit.
##
## `StillWatch` is a `Node`, not `RefCounted`, so every node a test builds is freed explicitly or the
## suite reports it leaked at shutdown.

## The hold, in physics ticks. The watch is handed it in seconds: the ticks' count over their rate.
const _HOLD_TICKS := 30
## Ticks either side of the hold that a check reads.
const _MARGIN := 8
## The rate the suite's physics ticks pass at, ten times the game's, so a hold of ticks costs a tenth
## of the real time: the watch counts ticks and their length, so the checks do not change with it.
const _TICK_RATE := 600

## A folder of the suite's own that every picture goes into, removed with the suite (a `DirAccess`
## made by `create_temp()` removes its folder when it is released): nothing under `user://`.
var _scratch: DirAccess

func run(t) -> void:
	var tick_rate := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = _TICK_RATE
	_scratch = DirAccess.create_temp("still_watch")
	assert(_scratch != null, "a scratch folder for the pictures")
	await _test_the_opening_stand_never_triggers(t)
	await _test_a_move_past_the_radius_arms_it_without_triggering(t)
	await _test_holding_still_after_the_move_triggers_at_the_hold(t)
	await _test_a_further_move_restarts_the_hold_from_the_new_spot(t)
	await _test_jitter_inside_the_radius_does_not_reset_the_hold(t)
	await _test_a_day_not_running_freezes_the_hold_instead_of_resetting_it(t)
	await _test_held_ticks_never_trigger_however_long_they_run(t)
	await _test_release_from_a_hold_restarts_the_count_rather_than_resuming_it(t)
	await _test_a_red_light_on_screen_holds_the_watch_and_a_green_one_does_not(t)
	Engine.physics_ticks_per_second = tick_rate
	_scratch = null
	_test_facing_a_red_light_true_for_the_nearest_visible_junction_wherever_she_stands(t)
	_test_facing_a_red_light_false_when_the_visible_junction_shows_green(t)
	_test_facing_a_red_light_true_on_the_carriageway_now_that_her_tile_no_longer_matters(t)
	_test_facing_a_red_light_false_with_no_signalled_junction_on_screen(t)
	_test_facing_a_red_light_false_at_an_unsignalled_junction_on_screen(t)
	_test_facing_a_red_light_false_when_the_red_junction_is_off_screen(t)
	_test_the_nearest_of_two_disagreeing_visible_junctions_decides(t)

## A `StillWatch` built as `main` builds it, in a screen of its own: her, the day's clock, a city
## and a viewport whose view the suite places.
class Rig:
	var viewport := SubViewport.new()
	var city: City
	var player := Stroller.new()
	var day := DayController.new()
	var watch := StillWatch.new()
	var run := RunState.new()
	var ticks := 0
	## The tick the watch asked for its picture on, or -1 while it has not.
	var triggered_at := -1

	func _init(t, hold_seconds: float, map: CityMap, picture_dir: String) -> void:
		viewport.size = Vector2i(64, 64)
		t.add_child(viewport)
		# A screen far from every junction, until a test places one on it.
		viewport.canvas_transform = Transform2D(0.0, Vector2(-100000.0, -100000.0))
		city = City.new()
		city.map = map
		city.signals = TrafficSignals.new(map)
		# Her camera is switched off, so the screen stays where the suite puts it.
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		camera.enabled = false
		player.add_child(camera)
		viewport.add_child(player)
		player.set_physics_process(false)
		viewport.add_child(day)
		day.set_process(false)
		day.setup(run)
		day.use_the_walk(map, player)
		day.start(1000.0)
		watch.setup(city, player, day, hold_seconds, picture_dir)
		watch.child_entered_tree.connect(_the_picture_was_asked_for)
		viewport.add_child(watch)

	func _the_picture_was_asked_for(child: Node) -> void:
		if child is AutoScreenshot:
			# Its own `_ready()` switches its frames on after this signal; the end of this tick
			# switches them off again, before any frame has run.
			child.set_process.call_deferred(false)
			triggered_at = ticks

	func free_all() -> void:
		viewport.free()
		city.free()

## Lets `count` physics ticks pass with her standing at `at` for each. The coroutine resumes as a
## tick begins and before the nodes' own physics step of it, so the position set here is the one the
## watch reads on that tick.
func _stand(t, rig: Rig, at: Vector2, count: int) -> void:
	for i in count:
		rig.player.global_position = at
		await t.get_tree().physics_frame
		rig.ticks += 1

func _hold_seconds() -> float:
	return float(_HOLD_TICKS) / Engine.physics_ticks_per_second

## A rig whose first physics tick has begun, so `_stand()` is in step with the ticks.
func _rig(t) -> Rig:
	var rig := Rig.new(t, _hold_seconds(), _signalled_map(), _scratch.get_current_dir() + "/still")
	await t.get_tree().physics_frame
	return rig

## Standing exactly where she started — the doorstep, before she has ever moved — must never
## trigger, however long it is held: the flag is armed only once she has actually gone somewhere.
func _test_the_opening_stand_never_triggers(t) -> void:
	var rig := await _rig(t)
	await _stand(t, rig, Vector2.ZERO, _HOLD_TICKS * 3)
	t.check(rig.triggered_at < 0, "three holds at the start before any move never arms the flag")
	rig.free_all()

## The tick she moves past the radius is recognised as a move, not read as an instant trigger, and it
## arms the watch: standing there afterwards is what fires it.
func _test_a_move_past_the_radius_arms_it_without_triggering(t) -> void:
	var rig := await _rig(t)
	await _stand(t, rig, Vector2.ZERO, 2)
	var moved := Vector2(StillWatch.STILL_RADIUS + 1.0, 0.0)
	await _stand(t, rig, moved, 1)
	t.check(rig.triggered_at < 0, "the tick she moves is not itself a trigger")
	await _stand(t, rig, moved, _HOLD_TICKS + _MARGIN)
	t.check(rig.triggered_at >= 0, "and standing there afterwards fires it, so moving armed it")
	rig.free_all()

## The hold counts from the move, and fires when it reaches the given number of seconds: not half
## way, and not a margin past it.
func _test_holding_still_after_the_move_triggers_at_the_hold(t) -> void:
	var rig := await _rig(t)
	await _stand(t, rig, Vector2.ZERO, 2)
	await _stand(t, rig, Vector2(10, 0), 1)
	var moved_at := rig.ticks
	await _stand(t, rig, Vector2(10, 0), _HOLD_TICKS - _MARGIN)
	t.check(rig.triggered_at < 0, "a margin short of a half-second hold does not fire")
	await _stand(t, rig, Vector2(10, 0), 2 * _MARGIN)
	t.check(rig.triggered_at >= 0, "and a margin past it has")
	t.check(absi(rig.triggered_at - moved_at - _HOLD_TICKS) <= 2,
			"at the hold, to within a tick or two (%d ticks after the move)"
			% (rig.triggered_at - moved_at))
	t.check(DirAccess.dir_exists_absolute(_scratch.get_current_dir() + "/still"),
			"the picture's folder is made in the folder the watch was handed")
	rig.free_all()

## A second move mid-hold restarts the countdown from the new spot rather than finishing at the
## hold's own total counted across two different places she stood.
func _test_a_further_move_restarts_the_hold_from_the_new_spot(t) -> void:
	var rig := await _rig(t)
	await _stand(t, rig, Vector2.ZERO, 2)
	await _stand(t, rig, Vector2(10, 0), _HOLD_TICKS - _MARGIN)
	await _stand(t, rig, Vector2(40, 0), _HOLD_TICKS - _MARGIN)
	t.check(rig.triggered_at < 0,
			"a margin short of a fresh hold at the new spot does not fire, though two such stands "
			+ "together are past one")
	await _stand(t, rig, Vector2(40, 0), 2 * _MARGIN)
	t.check(rig.triggered_at >= 0, "a hold at the new spot fires, counted from when she arrived there")
	rig.free_all()

## Sub-radius wobble — the slide's own settling against a wall, not a real move — never resets the
## hold that is already counting.
func _test_jitter_inside_the_radius_does_not_reset_the_hold(t) -> void:
	var rig := await _rig(t)
	await _stand(t, rig, Vector2.ZERO, 2)
	await _stand(t, rig, Vector2(10, 0), 1)
	var jitter := StillWatch.STILL_RADIUS * 0.5
	for i in _HOLD_TICKS - _MARGIN:
		await _stand(t, rig, Vector2(10 + (jitter if i % 2 == 0 else -jitter), 0), 1)
	t.check(rig.triggered_at < 0, "a margin short of the hold of sub-radius wobble has not fired")
	await _stand(t, rig, Vector2(10, 0), 2 * _MARGIN)
	t.check(rig.triggered_at >= 0, "and it fires a margin past it — the wobble never reset the count")
	rig.free_all()

## A day that is not running — over, or the tree paused — freezes the hold rather than
## resetting it: resuming afterward picks the count back up from where it left off.
func _test_a_day_not_running_freezes_the_hold_instead_of_resetting_it(t) -> void:
	var rig := await _rig(t)
	await _stand(t, rig, Vector2.ZERO, 2)
	await _stand(t, rig, Vector2(10, 0), 1)
	await _stand(t, rig, Vector2(10, 0), _HOLD_TICKS / 2)
	rig.day.phase = GameEnums.DayPhase.OVER
	await _stand(t, rig, Vector2(10, 0), _HOLD_TICKS * 5)
	t.check(rig.triggered_at < 0, "ticks of a day not running never advance the hold, however many")
	rig.day.start(1000.0)
	await _stand(t, rig, Vector2(10, 0), _HOLD_TICKS / 2 - _MARGIN)
	t.check(rig.triggered_at < 0, "a margin short of the rest of the hold once running again, no fire")
	await _stand(t, rig, Vector2(10, 0), 2 * _MARGIN)
	t.check(rig.triggered_at >= 0, "the hold resumes once running, counted from before the pause")
	rig.free_all()

## A detention — held — never fires however long it runs, unlike a day that is not running, which
## only pauses a count already under way.
func _test_held_ticks_never_trigger_however_long_they_run(t) -> void:
	var rig := await _rig(t)
	await _stand(t, rig, Vector2.ZERO, 2)
	await _stand(t, rig, Vector2(10, 0), 1)
	rig.player.detain(1000000.0)
	await _stand(t, rig, Vector2(10, 0), _HOLD_TICKS * 5)
	t.check(rig.triggered_at < 0, "five holds of detention never fire")
	rig.free_all()

## The distinction from a plain pause: a hold **restarts** the count on release rather than
## resuming it. Without this, whatever had accumulated *before* the hold began survives it and
## fires the instant she is free to move again — exactly the checkpoint bug this exists to fix.
func _test_release_from_a_hold_restarts_the_count_rather_than_resuming_it(t) -> void:
	var rig := await _rig(t)
	var here := Vector2(10, 0)
	await _stand(t, rig, Vector2.ZERO, 2)
	await _stand(t, rig, here, 1)
	await _stand(t, rig, here, _HOLD_TICKS * 3 / 4)
	rig.player.detain(1000000.0)
	await _stand(t, rig, here, _HOLD_TICKS * 2)
	rig.player.reset_at(here)
	await _stand(t, rig, here, _HOLD_TICKS - _MARGIN)
	t.check(rig.triggered_at < 0,
			"a margin short of a fresh hold after the release does not fire — the three quarters "
			+ "from before the detention did not survive it")
	await _stand(t, rig, here, 2 * _MARGIN)
	t.check(rig.triggered_at >= 0, "a full fresh hold after the release fires")
	rig.free_all()

## The whole of `held`'s third case on a built city and a real screen: with the main road's light red
## for the pedestrian on a junction the screen shows, the watch never fires however long she stands;
## once the light is green for her, the hold fires.
func _test_a_red_light_on_screen_holds_the_watch_and_a_green_one_does_not(t) -> void:
	var rig := await _rig(t)
	var box := _junction_box(rig.city.map, _main_junction(rig.city.map, 0))
	rig.viewport.canvas_transform = Transform2D(0.0, -box.position + Vector2(8, 8))
	var here := box.get_center()
	var green := Tuning.signal_main_green_seconds() + Tuning.SIGNAL_AMBER_SECONDS + 0.1
	# She walks up to the junction with the light green for her, which arms the watch.
	rig.city.signals.elapsed = green
	await _stand(t, rig, here + Vector2(-20, 0), 2)
	await _stand(t, rig, here, 1)
	rig.city.signals.elapsed = 0.0
	await _stand(t, rig, here, _HOLD_TICKS * 3)
	t.check(rig.triggered_at < 0, "three holds in front of a red light never fire")
	rig.city.signals.elapsed = green
	await _stand(t, rig, here, _HOLD_TICKS + _MARGIN)
	t.check(rig.triggered_at >= 0, "and once the light is green for her the hold fires")
	rig.free_all()

## The suite's city: a generated one, whose main road is the corridor the generator picked, so the
## junction the lights stand on is `_main_junction(map, 0)` and not a corridor the suite chose.
const _SEED := 4242

## The generated map, made on first use and shared: no test writes to it.
var _map: CityMap

func _signalled_map() -> CityMap:
	if _map == null:
		_map = CityGenerator.generate(_SEED)
	return _map

## The signalled junction `row` blocks down the main road. At row 0 `TrafficSignals._offset()`
## answers zero, so `elapsed` alone drives the phase with nothing else to account for.
func _main_junction(map: CityMap, row: int) -> Vector2i:
	return Vector2i(map.main_road, row)

## The tile `offset` tiles into a junction's box from its corner. Offset (1, 1) sits on both
## corridors' sidewalk band (`SIDEWALK_WIDTH` is 2) and (3, 3) on both corridors' road band, the same
## corner and the same carriageway `route_tree.gd`'s own note keeps as one piece of ground, used to
## prove her own tile no longer decides anything.
func _tile_in(junction: Vector2i, offset: Vector2i) -> Vector2i:
	return junction * CityMap.period() + offset

## The world rect of a junction's own `Tuning.STREET_WIDTH` tile box.
func _junction_box(map: CityMap, junction: Vector2i) -> Rect2:
	return map.tile_rect_to_world(
			Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH))

func _test_facing_a_red_light_true_for_the_nearest_visible_junction_wherever_she_stands(
		t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	var view := _junction_box(map, _main_junction(map, 0)).grow(20.0)
	var far_away := map.tile_to_world(Vector2i(10, 10))
	t.check(StillWatch.facing_a_red_light(map, signals, far_away, view),
			"the main road's own green is a red light for the pedestrian crossing it, wherever " +
			"on screen she is standing")
	signals.elapsed = Tuning.signal_main_green_seconds() + 0.1
	t.check(StillWatch.facing_a_red_light(map, signals, far_away, view),
			"and so is its amber — the crossing arm stays red through the clearance period")

func _test_facing_a_red_light_false_when_the_visible_junction_shows_green(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = Tuning.signal_main_green_seconds() + Tuning.SIGNAL_AMBER_SECONDS + 0.1
	var view := _junction_box(map, _main_junction(map, 0)).grow(20.0)
	t.check(not StillWatch.facing_a_red_light(map, signals, map.tile_to_world(_tile_in(_main_junction(map, 0), Vector2i(1, 1))), view),
			"the side arm's own green is what lets her cross the main road")

## The old rule ended the hold the moment she stepped onto `ROAD` — the player asked for the watch
## off "wherever she stands" instead (PLAYTEST-128.md statement 13), so a red light still holds it
## from the carriageway.
func _test_facing_a_red_light_true_on_the_carriageway_now_that_her_tile_no_longer_matters(
		t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	var view := _junction_box(map, _main_junction(map, 0)).grow(20.0)
	t.check(StillWatch.facing_a_red_light(map, signals, map.tile_to_world(_tile_in(_main_junction(map, 0), Vector2i(3, 3))), view),
			"standing on the carriageway no longer ends the hold — only the light does")

func _test_facing_a_red_light_false_with_no_signalled_junction_on_screen(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	var far_away := map.tile_to_world(Vector2i(10, 10))
	var view := Rect2(far_away, Vector2(50.0, 50.0))
	t.check(not StillWatch.facing_a_red_light(map, signals, far_away,
			view), "no junction anywhere near what is on screen is never a red light")

func _test_facing_a_red_light_false_at_an_unsignalled_junction_on_screen(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	# The junction beside the main road's is an ordinary crossroads, but its box is on screen.
	var view := _junction_box(map, _main_junction(map, 0) + Vector2i(1, 0)).grow(20.0)
	t.check(not StillWatch.facing_a_red_light(map, signals, map.tile_to_world(_tile_in(_main_junction(map, 0), Vector2i(1, 1))), view),
			"an ordinary junction on screen has no light to wait at, whatever the phase clock reads")

func _test_facing_a_red_light_false_when_the_red_junction_is_off_screen(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	var box := _junction_box(map, _main_junction(map, 0))
	var view := Rect2(box.end + Vector2(500.0, 500.0), Vector2(50.0, 50.0))
	t.check(not StillWatch.facing_a_red_light(map, signals, map.tile_to_world(_tile_in(_main_junction(map, 0), Vector2i(1, 1))), view),
			"a red junction that is not on screen never holds the watch")

## `TrafficSignals` runs a green wave with a per-junction offset (`TrafficSignals._offset()`), so
## two junctions on screen can show different phases; the nearest one to her decides.
func _test_the_nearest_of_two_disagreeing_visible_junctions_decides(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	var red := _main_junction(map, 0)
	var green := Vector2i(-1, -1)
	for y in range(1, Tuning.CITY_BLOCKS.y + 1):
		var candidate := _main_junction(map, y)
		if not (signals.green_for(candidate, true) or signals.amber_for(candidate, true)):
			green = candidate
			break
	t.check(green != Vector2i(-1, -1),
			"a junction whose side arm is green while the first is red exists on the main road")
	var red_box := _junction_box(map, red)
	var green_box := _junction_box(map, green)
	var view := red_box.merge(green_box).grow(20.0)
	t.check(StillWatch.facing_a_red_light(map, signals, red_box.get_center(), view),
			"standing nearest the red junction, the disagreement resolves red")
	t.check(not StillWatch.facing_a_red_light(map, signals, green_box.get_center(), view),
			"standing nearest the green junction instead, the same two junctions resolve green")
