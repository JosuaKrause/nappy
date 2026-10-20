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
	_test_the_escape_clock_moves_every_frame(t)
	_test_the_formatters(t)
	_test_an_escape_section_reads_its_clock_to_the_hundredth(t)
	_test_a_frozen_escape_clock_stays_silent(t)
	_test_each_section_is_won_at_its_own_goal(t)

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

## `--invincible` (`DayController.invincible`) freezes `time_remaining` outright (see
## `_process()`), so once the first second of a frozen day has been told, the value driving the
## gate never changes again -- the gate must not re-emit an unchanging number just because
## `_process()` keeps being called.
func _test_invincible_stops_emitting_once_the_first_second_is_told(t) -> void:
	var day := _rig(t)
	day.invincible = true
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

## The escape's clock reads to the hundredth and tells the HUD on every frame; a day's still emits
## once a second; the ending screens' formatter keeps three digits. *(inbox #746 in woolly-penguin.)*
func _test_the_escape_clock_moves_every_frame(t) -> void:
	var escape := _rig(t)
	escape.spec = DaySpec.for_section(DaySpec.Section.BUILDING, 180.0)
	var labels := []
	var on_emit := func(remaining: float, _total: float) -> void:
		labels.append(GameState.format_clock_hundredths(remaining))
	EventBus.day_time_changed.connect(on_emit)
	escape.start(180.0)
	labels.clear()
	for i in 10:
		escape._process(0.016)
	t.check(labels.size() == 10,
			"the escape's clock emits on each of ten frames inside one second (%d)" % labels.size())
	var distinct := {}
	for l in labels:
		distinct[l] = true
	t.check(distinct.size() == 10,
			"and the label differs on every one of them (%d distinct)" % distinct.size())
	EventBus.day_time_changed.disconnect(on_emit)
	escape.free()

	var day := _rig(t)
	var emits := [0]
	var count := func(_r: float, _tt: float) -> void:
		emits[0] += 1
	EventBus.day_time_changed.connect(count)
	day.start(10.5)
	emits[0] = 0
	for i in 10:
		day._process(0.016)
	t.check(emits[0] == 0, "a day's controller stays silent inside one second (%d)" % emits[0])
	EventBus.day_time_changed.disconnect(count)
	day.free()

func _test_the_formatters(t) -> void:
	t.check(GameState.format_clock_hundredths(179.43) == "2:59.43",
			"hundredths: 2:59.43 (%s)" % GameState.format_clock_hundredths(179.43))
	t.check(GameState.format_clock_hundredths(0.0) == "0:00.00", "hundredths at zero")
	t.check(GameState.format_clock(179.432) == "2:59.432",
			"the ending's run length keeps three digits (%s)" % GameState.format_clock(179.432))

## The escape's two sections say their clock reads to the hundredth (`DaySpec.clock_hundredths`),
## which is what the day's clock emits every frame by: drop it and the escape's label goes back to
## changing once a second. A day's spec, and a `DayController` handed none, read to the second.
func _test_an_escape_section_reads_its_clock_to_the_hundredth(t) -> void:
	for section: int in [DaySpec.Section.BUILDING, DaySpec.Section.CITY]:
		t.check(DaySpec.for_section(section, 180.0).clock_hundredths,
				"escape section %d's clock reads to the hundredth" % section)
	t.check(not DaySpec.for_day(3, 210.0).clock_hundredths, "a day's clock does not")
	var plain := DayController.new()
	t.check(not plain.spec.clock_hundredths, "nor does a DayController handed no spec")
	plain.free()

## A frozen `--invincible` escape clock has nothing new to tell the HUD, flag or not.
func _test_a_frozen_escape_clock_stays_silent(t) -> void:
	var escape := _rig(t)
	escape.invincible = true
	escape.spec = DaySpec.for_section(DaySpec.Section.CITY, 180.0)
	var emits := [0]
	var count := func(_r: float, _tt: float) -> void:
		emits[0] += 1
	EventBus.day_time_changed.connect(count)
	escape.start(180.0)
	emits[0] = 0
	for i in 10:
		escape._process(0.016)
	t.check(emits[0] == 0, "a frozen escape clock is silent (%d emits)" % emits[0])
	EventBus.day_time_changed.disconnect(count)
	escape.free()

## **Each section is won at its own goal, through the day's own `day_finished`** *(minty-lemur #785:
## "the escape is just like a normal day with some special settings")*: the building when the
## building says she is through its service exit (`reach_the_exit()`), the city when she reaches
## one of its two ways out, however the baby is — and which way is kept. A day is never won by
## either: its goal is her front door.
func _test_each_section_is_won_at_its_own_goal(t) -> void:
	var results: Array[int] = []
	var on_finished := func(result: GameEnums.DayResult) -> void:
		results.append(result)

	var building := _rig(t)
	building.spec = DaySpec.for_section(DaySpec.Section.BUILDING, 180.0)
	building.day_finished.connect(on_finished)
	building.start(180.0)
	building._process(0.016)
	t.check(results.is_empty(), "the building is not won by standing anywhere (%s)" % [results])
	building.reach_the_exit()
	t.check(results == [GameEnums.DayResult.WON] and not building.is_running(),
			"through its service exit, the building section is won (%s)" % [results])
	building.free()

	results.clear()
	var city := _rig(t)
	city.spec = DaySpec.for_section(DaySpec.Section.CITY, 180.0)
	city.spec.exits = {CityEdge.Kind.TUNNEL: Vector2(1000.0, 0.0),
			CityEdge.Kind.BRIDGE: Vector2(-1000.0, 0.0)}
	city.day_finished.connect(on_finished)
	city.start(180.0)
	city.reach_the_exit()
	city._process(0.016)
	t.check(results.is_empty(), "the city is won by neither its building's exit nor standing away "
			+ "from its two ways out (%s)" % [results])
	city._player.global_position = Vector2(-1000.0 + Tuning.FINALE_EXIT_REACH - 1.0, 0.0)
	city._process(0.016)
	t.check(results == [GameEnums.DayResult.WON] and city.exit_reached == CityEdge.Kind.BRIDGE,
			"at the bridge deck, awake, the city section is won by the bridge (%s, %d)"
			% [results, city.exit_reached])
	city.free()

	results.clear()
	var day := _rig(t)
	day.day_finished.connect(on_finished)
	day.start(210.0)
	day.reach_the_exit()
	day._process(0.016)
	t.check(results.is_empty(), "a day is won by neither (%s)" % [results])
	day.free()
