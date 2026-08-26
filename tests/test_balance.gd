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

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

var _city: City
var _stroller: Stroller
var _baby: Baby

func run(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

	_test_a_calm_park_still_settles_her(t)
	_test_the_arterial_never_settles_her(t)
	_test_every_day_keeps_a_park_quiet_enough_to_settle_in(t)

	_teardown_rig()
	_city.free()

func _start_day(day: int) -> void:
	var consumed: Array[String] = []
	_city.events.start_day(day, _rng(day, "events"), consumed)
	_city.crowd.start_day(day, _rng(day, "crowd"))

func _rng(day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, day, stream])
	return rng

## A rig standing at `at`, walking on the spot. The baby finds the City through the "world"
## group, so it is asking the real map and the real crowd.
func _build_rig(t, at: Vector2) -> void:
	_teardown_rig()
	_stroller = Stroller.new()
	# The name matters: Stroller's @onready looks the camera up by path.
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_stroller.add_child(camera)
	t.add_child(_stroller)
	_stroller.set_physics_process(false)
	_stroller.global_position = at
	_stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	_baby = Baby.new()
	_stroller.add_child(_baby)
	_baby.set_physics_process(false)

func _teardown_rig() -> void:
	if _stroller:
		_stroller.free()
		_stroller = null
		_baby = null

## Walks the rig on the spot for `seconds`, with the world running underneath it. Returns
## how long it took her to settle, or -1.0 if she never did.
func _walk_until_asleep(at: Vector2, seconds: float) -> float:
	_stroller.global_position = at
	for i in int(round(seconds / STEP)):
		for agent in _city.crowd.agents():
			agent._process(STEP)
		for instance in _city.events.instances():
			if not instance.is_finished:
				instance._process(STEP)
		_baby._physics_process(STEP)
		if _baby.state == GameEnums.BabyState.ASLEEP:
			return i * STEP
	return -1.0

# --------------------------------------------------------------------- calm ---

## The park has to be quiet enough that the meter never freezes in it, or the only place a
## day can be won is a place a day cannot be won.
func _test_a_calm_park_still_settles_her(t) -> void:
	_start_day(1)
	var park := _quietest_park()
	_build_rig(t, park)
	var settled := _walk_until_asleep(park, Tuning.day_length(1))
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
func _test_the_arterial_never_settles_her(t) -> void:
	_start_day(1)
	var street := CrowdLanes.arterial_pavement(_city.map)
	_build_rig(t, street)
	var settled := _walk_until_asleep(street, Tuning.day_length(1))
	t.check(settled < 0.0,
			"a whole day on the arterial never settles her (settled at %.0fs)" % settled)
	t.check(_baby.sleepiness < Tuning.METER_MAX,
			"and the meter is still short of full (%.0f)" % _baby.sleepiness)

## The scheduler promises one usable calm zone every day. Now that a day cannot be won
## anywhere else, that promise is the difference between a hard day and an impossible one,
## so it gets checked against the crowd and the events together rather than events alone.
func _test_every_day_keeps_a_park_quiet_enough_to_settle_in(t) -> void:
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		_start_day(day)
		var park := _quietest_park()
		_build_rig(t, park)
		var settled := _walk_until_asleep(park, Tuning.day_length(day))
		t.check(settled > 0.0, "day %d has a park she can actually settle in" % day)

## The calmest park centre this day, by the excitement standing there right now. This is the
## park the scheduler's "one usable calm zone" rule is protecting, found by measurement
## rather than by asking the scheduler which one it picked.
func _quietest_park() -> Vector2:
	var best := _city.map.home_world_position()
	var quietest := INF
	for block in _city.map.calm_blocks:
		var centre := _city.map.tile_rect_to_world(CityMap.block_rect(block)).get_center()
		var here := _city.total_excitement_at(centre)
		if here < quietest:
			quietest = here
			best = centre
	return best
