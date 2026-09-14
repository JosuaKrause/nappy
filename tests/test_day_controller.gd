extends RefCounted
## `DayController`'s clock: the countdown itself, and how often it tells anyone about it.
##
## `docs/TODO.md`, M124: `_process()` used to emit `EventBus.day_time_changed` every frame, sixty
## times a second, for a label (`hud.gd`'s `_on_day_time_changed()`) that only reads to the whole
## second and only changes its urgency colour at the same boundary. It now emits only when the
## whole second actually displayed has changed, which this suite holds from the emitting side —
## `hud.gd` itself belongs to a different milestone and is read only.

func run(t) -> void:
	_test_the_clock_emits_once_per_second_crossed(t)
	_test_a_day_starting_is_its_own_emit(t)
	_test_invincible_stops_emitting_once_the_first_second_is_told(t)

func _rig(t) -> DayController:
	var player := Node2D.new()
	t.add_child(player)
	var day := DayController.new()
	t.add_child(day)
	day.set_process(false)
	# No map: `_is_home()` guards on it being null, and nothing in this suite reaches the return
	# phase, so a real `CityMap` would only cost time nothing here asks about.
	day.setup(null, player)
	return day

func _test_the_clock_emits_once_per_second_crossed(t) -> void:
	var day := _rig(t)
	var emits := [0]
	var on_emit := func(_remaining: float, _total: float) -> void:
		emits[0] += 1
	EventBus.day_time_changed.connect(on_emit)

	# Starting at a half second (rather than a whole one) keeps every check below a comfortable
	# margin away from a boundary, so float accumulation over many small `delta` steps can never
	# land a check exactly on one -- the plain source of a flaky off-by-one here.
	day.start(10.5)
	emits[0] = 0 # start()'s own emit is the next test's question, not this one's.
	var step := 1.0 / 60.0

	# A dozen frames, comfortably inside the same whole second (10.5 down to 10.3): nothing to
	# tell the HUD that it has not already been told.
	for i in 12:
		day._process(step)
	t.check(emits[0] == 0,
			"frames that stay inside the same whole second do not re-emit (%d emits)" % emits[0])

	# Forty-eight more frames (a second in total, so down to 9.5) cross exactly one whole-second
	# boundary (10 -> 9), comfortably clear of 10.0 and 9.0 either side -- one emit is owed for
	# it, not one per frame the crossing happened to take.
	for i in 48:
		day._process(step)
	t.check(emits[0] == 1,
			"crossing one whole-second boundary is told exactly once (%d emits)" % emits[0])

	EventBus.day_time_changed.disconnect(on_emit)
	day.free()

func _test_a_day_starting_is_its_own_emit(t) -> void:
	var day := _rig(t)
	var emits := [0]
	var on_emit := func(_remaining: float, _total: float) -> void:
		emits[0] += 1
	EventBus.day_time_changed.connect(on_emit)

	day.start(300.0)
	t.check(emits[0] == 1,
			"starting a day is a change in its own right and is always told, whatever the " +
			"countdown does on the frames after")

	EventBus.day_time_changed.disconnect(on_emit)
	day.free()

## `--invincible` freezes `time_remaining` outright (`DevFlags.invincible()`'s own doc in
## `_process()`), so once the first second of a frozen day has been told, the value driving the
## gate never changes again -- the gate must not re-emit an unchanging number just because
## `_process()` keeps being called.
func _test_invincible_stops_emitting_once_the_first_second_is_told(t) -> void:
	# `DevFlags._invincible_override` is the seam `tests/test_invincible.gd` already uses instead
	# of a real command line -- see that suite's own doc.
	DevFlags._invincible_override = true
	var day := _rig(t)
	var emits := [0]
	var on_emit := func(_remaining: float, _total: float) -> void:
		emits[0] += 1
	EventBus.day_time_changed.connect(on_emit)

	day.start(10.0)
	emits[0] = 0
	for i in 120:
		day._process(1.0 / 60.0)
	t.check(emits[0] == 0,
			"a frozen clock has nothing new to tell the HUD after its first frame, so it stays " +
			"silent rather than repeating the same number 120 times (%d emits)" % emits[0])

	EventBus.day_time_changed.disconnect(on_emit)
	day.free()
	DevFlags._invincible_override = null
