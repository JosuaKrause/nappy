extends RefCounted
## The day's pitch, measured against the real world rather than against the numbers.
##
## `test_meters.gd` asserts the arithmetic: a day's worth of street gain falls short of the
## meter and a calm stretch clears it. That is necessary and not sufficient, because both
## halves depend on how loud the ground actually is — the crowd can push a street over the
## calm threshold and freeze the meter, and it could just as easily creep into a park and
## stop one filling. Neither is visible to a data-level test.
##
## So this runs a real `Baby` against a real `City`, with that day's crowd and events, at a
## fixed place on the map. Walking on the spot is the right abstraction here: what is being
## measured is what the ground and the noise do, not the locomotion.
##
## Each day is started the way the game starts one (`DayDirector.start_day()`, handed the city, its
## events, the resistance, her, the baby and the day's clock), so the day's closures stand, its city
## is painted, and a calm area she settled in earlier in the act reads spent.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed of the run the city is handed (`RunCity.with_own_run()`), whose calendar draws each
## day's streams.
const RUN_SEED := 2
## The seed the city itself is generated from.
const SEED := 4242
const STEP := 1.0 / 60.0

## How many times real time the walks run at (`PhysicsTicks.pass_ticks()`'s `scale`).
const TIME_SCALE := 4.0

## How long `_test_the_arterial_never_settles_her` walks the arterial for — see that test's own
## docstring for the measurement behind the number.
const ARTERIAL_WINDOW := 60.0

var _city: City
var _stroller: Stroller
var _baby: Baby
var _resistance: ResistanceDirector
var _clock: DayController
var _config := RunConfig.parse(PackedStringArray(), "", true)
var _days: DayDirector

func run(t) -> void:
	await PhysicsTicks.settle(t)
	_city = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_build_rig(t)

	await _test_a_calm_park_still_settles_her(t)
	await _test_the_arterial_never_settles_her(t)
	await _test_every_day_keeps_a_park_quiet_enough_to_settle_in(t)
	await _test_the_playground_itself_settles_her(t)

	_clock.free()
	_stroller.free()
	_resistance.free()
	_city.free()

## A fresh run on `RUN_SEED`, at day 1: each test plays its days from the start of a run of its own,
## so none inherits the calm areas an earlier one used.
func _new_run() -> void:
	_city.run.start_run(RUN_SEED)

## Starts the run's current day, which is `day`, the way the game does (`DayDirector.start_day()`).
func _start_day(t, day: int) -> void:
	t.check(_city.run.header.day == day, "the run is on day %d (%d)" % [day, _city.run.header.day])
	_days.start_day(DaySpec.for_day(day, _config.day_length_for(day)))

## Puts the world around a point the way it would be for a player standing there.
##
## Since M27 the crowd and the events are both built around the player, so a rig that teleports
## to a park and starts measuring is measuring an empty city unless it says where it is. This
## is the rig's stand-in for having walked there — and it is also the honest version of what
## these tests ask, which was never "what is the excitement at this coordinate" but "what does
## a player standing on this ground have to survive".
##
## The crowd is today's (`DayDirector.start_the_crowd()`, as dense as the day's spec says), rebuilt
## round `at` rather than round the doorstep the day began at.
func _stand_at(at: Vector2) -> void:
	_city.events.stream_around(at)
	_days.start_the_crowd(at)

## The rig, built once: her, walking on the spot, with the baby riding; the day's clock, set up the
## way `main` sets it up, so the calm she falls asleep on is remembered where the game remembers it
## (`DayController._remember_the_calm_she_found()`) and tomorrow reads it spent; the resistance the
## day places its mark for; and the day director handed all of them. The City is the world the baby
## is handed, so it is asking the real map and the real crowd. Nothing ticks the clock — `main` is
## what does — so no day here ends on its own.
func _build_rig(t) -> void:
	_stroller = Stroller.new()
	# The name matters: Stroller's @onready looks the camera up by path. Matches the real
	# camera's own scene (`process_callback = 0` in `stroller.tscn`) rather than leaving the
	# default idle callback for physics interpolation to override with a warning.
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_stroller.add_child(camera)
	t.add_child(_stroller)
	_stroller.set_physics_process(false)
	_baby = Baby.new()
	_stroller.add_child(_baby)
	_baby.set_world(_city)
	_clock = DayController.new()
	t.add_child(_clock)
	_clock.setup(_city.map, _stroller, _city.run)
	_resistance = ResistanceDirector.new()
	t.add_child(_resistance)
	_resistance.set_process(false)
	_resistance.setup(_city.map, _city.run, _city.events, _city.streets(), _city.fronts(), _city, null,
			_city.spawn_siting)
	_days = DayDirector.new(_city.run.calendar, _city.run.facts, _city.run.attempt_spend, _config)
	_days.use_the_world(_city, _city.events, _resistance, _stroller, _baby, _clock)

## Puts her at `at`, walking on the spot: the day's start stood her still on the doorstep.
func _place_rig(at: Vector2) -> void:
	_stroller.global_position = at
	_stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)

## Walks the rig on the spot for `seconds` of game time on real physics ticks, one a rendered frame
## (`PhysicsTicks`), with the world running underneath it: the city's crowd and events take their
## own live ticks and the baby takes its own, as in play. The ticks run at `TIME_SCALE` times real
## time, each `TIME_SCALE` times as long as a tick, so a day's seconds take a quarter of the
## frames; what is measured is what the ground and the noise do, and a longer step does not change
## it. Returns how long it took her to settle in game seconds, or -1.0 if she never did.
func _walk_until_asleep(t, at: Vector2, seconds: float) -> float:
	_stroller.global_position = at
	var total := PhysicsTicks.ticks_for(seconds, TIME_SCALE)
	# A lambda copies a local number, so the tick she fell asleep on is kept in an array.
	var settled: Array[float] = [-1.0]
	var ticked := 0
	# Fifteen ticks at a time, the settling tick noted on the tick it happens; the walk ends at the
	# end of the chunk she fell asleep in.
	while ticked < total and settled[0] < 0.0:
		var chunk := mini(15, total - ticked)
		var before := ticked
		var note := func(ran: int) -> void:
			if settled[0] < 0.0 and _baby.state == GameEnums.BabyState.ASLEEP:
				settled[0] = (before + ran) * STEP * TIME_SCALE
		await PhysicsTicks.pass_ticks_faster(t, chunk, PhysicsTicks.FASTER, note, TIME_SCALE)
		ticked += chunk
	return settled[0]

# --------------------------------------------------------------------- calm ---

## The park has to be quiet enough that the meter never freezes in it, or the only place a
## day can be won is a place a day cannot be won.
func _test_a_calm_park_still_settles_her(t) -> void:
	_new_run()
	_start_day(t, 1)
	var park := _quietest_park()
	_stand_at(park)
	_place_rig(park)
	var settled := await _walk_until_asleep(t, park, Tuning.day_length(1))
	t.check(settled > 0.0, "a calm park settles her at all")
	# Better than "inside the day": inside *half* of the short day, so the other half is
	# there for the walk out and the walk home. That is what "comfortably winnable" has to
	# mean when the park is the only place a day can be won.
	t.check(settled < Tuning.day_length(Tuning.RUN_LENGTH_DAYS) * 0.55,
			"a calm park settles her in %.0fs, leaving the short day room to walk"
			% settled)

## Finding 4: standing on an ordinary street cannot be a strategy. On the arterial it is not
## even close — between the crowd freezing the meter and the day running out, she never goes
## down there, which is what makes the walk to the park the decision the game is about.
##
## **M125: walked for `ARTERIAL_WINDOW` (60s), not the whole day.** Measured first: printing
## `_baby.sleepiness` every ten seconds over a full day-1 walk (`Tuning.day_length(1)`, 210s)
## showed it climb to ~3.2 by t=10s and then hold there, unmoved, through t=210s — the arterial's
## noise floor is stationary for the whole of a day with one act and no scheduled lull, so a
## longer walk than the plateau itself takes to reach is not a longer look at anything, only more
## frames of the same reading. Sixty seconds is six times that settling time, which is margin
## against the plateau being reached slower on a seed or a day this test does not use.
func _test_the_arterial_never_settles_her(t) -> void:
	_new_run()
	_start_day(t, 1)
	var street := CrowdLanes.arterial_pavement(_city.map)
	_stand_at(street)
	_place_rig(street)
	var settled := await _walk_until_asleep(t, street, ARTERIAL_WINDOW)
	t.check(settled < 0.0,
			"%.0fs on the arterial never settles her (settled at %.0fs)"
			% [ARTERIAL_WINDOW, settled])
	t.check(_baby.sleepiness < Tuning.METER_MAX,
			"and the meter is still short of full (%.0f)" % _baby.sleepiness)

## The scheduler promises one usable calm zone every day. Now that a day cannot be won
## anywhere else, that promise is the difference between a hard day and an impossible one,
## so it gets checked against the crowd and the events together rather than events alone.
##
## The days are one run's, each banked as won before the next begins, so where she settled is
## remembered and the act's later days read it spent: the park she used is spoiled and off the
## day's tree, and the quietest park is found among what is left.
func _test_every_day_keeps_a_park_quiet_enough_to_settle_in(t) -> void:
	_new_run()
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		_start_day(t, day)
		var park := _quietest_park()
		_stand_at(park)
		_place_rig(park)
		var settled := await _walk_until_asleep(t, park, Tuning.day_length(day))
		t.check(settled > 0.0, "day %d has a park she can actually settle in" % day)
		_city.run.calendar.finish_day(GameEnums.DayResult.WON)

## M128: the playground itself costs nothing, or a one-block park with one in it has no ground
## left to settle her on — `outer_radius` (150) reaches past half of a 256px block. Standing
## exactly on the ambient source's own centre, where `EventScheduler._place_ambient` puts it, is
## the worst point in any park it is in, so if she settles there she settles everywhere else in
## the same park too.
func _test_the_playground_itself_settles_her(t) -> void:
	_new_run()
	_start_day(t, 1)
	if _city.map.playgrounds.is_empty():
		return  # This city rolled no PARK-purpose block; nothing here to check.
	var at: Vector2 = _city.map.tile_rect_to_world(_city.map.playgrounds[0]).get_center()
	_stand_at(at)
	_place_rig(at)
	var settled := await _walk_until_asleep(t, at, Tuning.day_length(1))
	t.check(settled > 0.0, "she settles standing on the playground's own ambient source")

## The calmest calm ground this day, by the excitement a player standing there would be under.
## This is the park the scheduler's "one usable calm zone" rule is protecting, found by
## measurement rather than by asking the scheduler which one it picked.
##
## Each area is measured where she would stand to settle in it, on its own calm ground
## (`CalmSpot.of()`): a courtyard block's centre is a building, and a day whose first calm block in
## the list is a courtyard would otherwise send her to stand on a roof.
##
## Each candidate is streamed in before it is measured, or the answer would be "whichever park
## the last measurement happened to leave the world around". The crowd is left out of it on
## purpose: it lives on the street lattice, so what separates one park from another is the
## events on it, which is exactly what the rule protects.
func _quietest_park() -> Vector2:
	var best := _city.map.home_world_position()
	var quietest := INF
	for block in _city.map.calm_blocks:
		var spot := CalmSpot.of(_city.map, block)
		if spot == Vector2.INF:
			continue
		_city.events.stream_around(spot)
		var here := _city.events.sources.total_at(spot)
		if here < quietest:
			quietest = here
			best = spot
	return best
