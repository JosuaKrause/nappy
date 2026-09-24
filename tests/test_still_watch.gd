extends RefCounted
## `StillWatch._feed()`, the pure stillness heuristic behind `--quit-when-still`: positions,
## deltas, an `active` flag and a `held` flag in, a trigger out. Armed only once she has moved,
## frozen rather than reset while inactive (paused, or the day not running), and reset — not
## frozen — every frame `held` is true (a detention, a checkpoint's hold, a wait at a red light).
## No `City`, `Stroller` or running day anywhere here — a bare `StillWatch.new()` off the tree
## drives it directly, the same way `tests/test_auto_screenshot.gd` calls
## `AutoScreenshot._parse_script()` without ever adding that node to a tree either. The geometry and
## signal half of `held` — `StillWatch.facing_a_red_light()` — is pure too, over a bare `CityMap`
## and `TrafficSignals` with no `City` around either.
##
## Every step below uses a `0.25` delta rather than the more obvious `0.1`: ten additions of `0.1`
## land on `0.9999999999999999` in double precision, one tick short of the `1.0` hold this suite
## means to cross, and `0.25` is exactly representable so four ticks land on exactly `1.0` with no
## such trap.
##
## `StillWatch` is a `Node`, not `RefCounted`, so every instance is freed explicitly or the suite
## reports it leaked at shutdown.

const _TICK := 0.25

func run(t) -> void:
	_test_the_opening_stand_never_triggers(t)
	_test_a_move_past_the_radius_arms_it_without_triggering(t)
	_test_holding_still_after_the_move_triggers_at_the_hold(t)
	_test_a_further_move_restarts_the_hold_from_the_new_spot(t)
	_test_jitter_inside_the_radius_does_not_reset_the_hold(t)
	_test_inactive_frames_freeze_the_hold_instead_of_resetting_it(t)
	_test_held_frames_never_trigger_however_long_they_run(t)
	_test_release_from_a_hold_restarts_the_count_rather_than_resuming_it(t)
	_test_facing_a_red_light_on_the_main_arms_green_or_amber(t)
	_test_facing_a_red_light_false_once_the_side_arm_has_green(t)
	_test_facing_a_red_light_false_off_the_sidewalk(t)
	_test_facing_a_red_light_false_away_from_any_junction(t)
	_test_facing_a_red_light_false_at_an_unsignalled_junction(t)

func _watch(hold_seconds := 1.0) -> StillWatch:
	var w := StillWatch.new()
	w._seconds = hold_seconds
	return w

## Standing exactly where she started — the doorstep, before she has ever moved — must never
## trigger, however long it is held: the flag is armed only once she has actually gone somewhere.
func _test_the_opening_stand_never_triggers(t: Object) -> void:
	var w := _watch()
	var triggered := false
	for i in 40:
		triggered = w._feed(Vector2.ZERO, _TICK, true) or triggered
	t.check(not triggered, "ten seconds at the start before any move never arms the flag")
	w.free()

## The frame she moves past the radius is recognised as a move, not read as an instant trigger.
func _test_a_move_past_the_radius_arms_it_without_triggering(t: Object) -> void:
	var w := _watch()
	w._feed(Vector2.ZERO, _TICK, true)
	var moved := Vector2(StillWatch.STILL_RADIUS + 1.0, 0.0)
	var triggered := w._feed(moved, _TICK, true)
	t.check(not triggered, "the frame she moves is not itself a trigger")
	t.check(w._armed, "moving past the radius arms the detector")
	w.free()

## The hold counts from the move, and fires the instant it reaches the given number of seconds.
func _test_holding_still_after_the_move_triggers_at_the_hold(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	var triggered := false
	for i in 3:
		triggered = w._feed(Vector2(10, 0), _TICK, true) or triggered
	t.check(not triggered, "0.75s of holding still is short of a 1.0s hold")
	triggered = w._feed(Vector2(10, 0), _TICK, true)
	t.check(triggered, "the fourth tick reaches exactly 1.0s and fires")
	w.free()

## A second move mid-hold restarts the countdown from the new spot rather than finishing at the
## hold's own total counted across two different places she stood.
func _test_a_further_move_restarts_the_hold_from_the_new_spot(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	for i in 2:
		w._feed(Vector2(10, 0), _TICK, true)
	w._feed(Vector2(40, 0), _TICK, true)
	var triggered := false
	for i in 3:
		triggered = w._feed(Vector2(40, 0), _TICK, true) or triggered
	t.check(not triggered, "0.75s at the new spot is short of a fresh 1.0s hold")
	triggered = w._feed(Vector2(40, 0), _TICK, true)
	t.check(triggered, "1.0s at the new spot fires, counted from when she arrived there")
	w.free()

## Sub-radius wobble — the slide's own settling against a wall, not a real move — never resets the
## hold that is already counting.
func _test_jitter_inside_the_radius_does_not_reset_the_hold(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	var jitter := StillWatch.STILL_RADIUS * 0.5
	var triggered := false
	for i in 3:
		var wobble := Vector2(10 + (jitter if i % 2 == 0 else -jitter), 0)
		triggered = w._feed(wobble, _TICK, true) or triggered
	t.check(not triggered, "three ticks of sub-radius wobble have not reached the hold yet")
	triggered = w._feed(Vector2(10, 0), _TICK, true)
	t.check(triggered, "the fourth tick fires — the wobble never reset the count")
	w.free()

## `active` false — the day not running, or the tree paused — freezes the hold rather than
## resetting it: resuming afterward picks the count back up from where it left off.
func _test_inactive_frames_freeze_the_hold_instead_of_resetting_it(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	var triggered := false
	for i in 20:
		triggered = w._feed(Vector2(10, 0), _TICK, false) or triggered
	t.check(not triggered, "inactive frames never advance the hold, however many of them there are")
	for i in 3:
		triggered = w._feed(Vector2(10, 0), _TICK, true) or triggered
	t.check(not triggered, "0.75s active since the move is still short of the hold")
	triggered = w._feed(Vector2(10, 0), _TICK, true)
	t.check(triggered, "the hold resumes once active again, counted from before the pause")
	w.free()

## `held` true — a detention, a checkpoint's hold or a wait at a red light — never fires however
## long it runs, unlike an inactive frame, which only pauses a count already under way.
func _test_held_frames_never_trigger_however_long_they_run(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	var triggered := false
	for i in 40:
		triggered = w._feed(Vector2(10, 0), _TICK, true, true) or triggered
	t.check(not triggered, "ten seconds held never fires, whatever was held")
	w.free()

## The distinction from a plain pause: a hold **restarts** the count on release rather than
## resuming it. Without this, whatever had accumulated *before* the hold began survives it and
## fires the instant she is free to move again — exactly the checkpoint bug this exists to fix.
func _test_release_from_a_hold_restarts_the_count_rather_than_resuming_it(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	for i in 3:
		w._feed(Vector2(10, 0), _TICK, true)
	# 0.75s accumulated here — one more active tick would fire on its own.
	for i in 5:
		w._feed(Vector2(10, 0), _TICK, true, true)
	var triggered := false
	for i in 3:
		triggered = w._feed(Vector2(10, 0), _TICK, true) or triggered
	t.check(not triggered, "0.75s after release is short of a fresh 1.0s hold — the pre-hold " +
			"0.75s did not survive it")
	triggered = w._feed(Vector2(10, 0), _TICK, true)
	t.check(triggered, "the fourth tick after release fires — a full fresh hold, not the leftover " +
			"0.25s a resume would have needed")
	w.free()

## Junction (0, 0): the main road's own corridor and, once the map says so, the signalled one —
## `CityMap.junction_at()` and `TrafficSignals._offset()` both answer zero there, so `elapsed`
## alone drives the phase with nothing else to account for. Tile (1, 1) sits inside the box on
## both corridors' sidewalk band (`SIDEWALK_WIDTH` is 2), and tile (3, 3) sits in the box on both
## corridors' road band — the same corner and the same carriageway `route_tree.gd`'s own note
## keeps as one piece of ground.
func _signalled_map(main_road_index := 0) -> CityMap:
	var map := CityMap.new()
	map.main_road = main_road_index
	map.set_tile(Vector2i(1, 1), GameEnums.TileType.SIDEWALK)
	map.set_tile(Vector2i(3, 3), GameEnums.TileType.ROAD)
	map.set_tile(Vector2i(10, 10), GameEnums.TileType.SIDEWALK)
	return map

func _test_facing_a_red_light_on_the_main_arms_green_or_amber(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	var kerb := map.tile_to_world(Vector2i(1, 1))
	signals.elapsed = 0.0
	t.check(StillWatch.facing_a_red_light(map, signals, kerb),
			"the main road's own green is a red light for the pedestrian crossing it")
	signals.elapsed = Tuning.signal_main_green_seconds() + 0.1
	t.check(StillWatch.facing_a_red_light(map, signals, kerb),
			"and so is its amber — the crossing arm stays red through the clearance period")

func _test_facing_a_red_light_false_once_the_side_arm_has_green(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = Tuning.signal_main_green_seconds() + Tuning.SIGNAL_AMBER_SECONDS + 0.1
	t.check(not StillWatch.facing_a_red_light(map, signals, map.tile_to_world(Vector2i(1, 1))),
			"the side arm's own green is what lets her cross the main road")

func _test_facing_a_red_light_false_off_the_sidewalk(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	t.check(not StillWatch.facing_a_red_light(map, signals, map.tile_to_world(Vector2i(3, 3))),
			"standing on the carriageway is committing to cross, not waiting for a light")

func _test_facing_a_red_light_false_away_from_any_junction(t: Object) -> void:
	var map := _signalled_map()
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	t.check(not StillWatch.facing_a_red_light(map, signals, map.tile_to_world(Vector2i(10, 10))),
			"a sidewalk tile with no junction near it is never a red light")

func _test_facing_a_red_light_false_at_an_unsignalled_junction(t: Object) -> void:
	var map := _signalled_map(5)
	var signals := TrafficSignals.new(map)
	signals.elapsed = 0.0
	t.check(not StillWatch.facing_a_red_light(map, signals, map.tile_to_world(Vector2i(1, 1))),
			"an ordinary junction has no light to wait at, whatever the phase clock reads")
