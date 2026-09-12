extends RefCounted
## The meter rules from docs/MECHANICS.md.
##
## These are the numbers the whole game is balanced on and none of them are visible in a
## screenshot, so they get asserted rather than eyeballed.

const STEP := 1.0 / 60.0

## Stands in for the city: the baby only ever asks these three questions.
class FakeWorld extends WorldContext:
	var calm := false
	var alley := false
	var noise := 0.0

	# The ground answers with a **rate** since M52, and a fake that answers with a bool would be
	# testing an interface the baby no longer has. `calm` stands for the base four-block zone;
	# nothing here is about size, which is `City`'s question and `test_generator`'s to check.
	func sleepiness_multiplier(_world_position: Vector2) -> float:
		return Tuning.sleepiness_calm_multiplier(Tuning.CALM_ZONE_BLOCKS ** 2) if calm else 1.0

	func is_alley(_world_position: Vector2) -> bool:
		return alley

	func total_excitement_at(_world_position: Vector2) -> float:
		return noise

	## `Baby` now sums `excitement_sources_at()` rather than calling `total_excitement_at()`
	## directly, and traces each pair's own share back to `accumulate_landed()`. This fake has no
	## real body to attribute `noise` to, so it hands out itself and answers the call with nothing —
	## no test here reads a colour, only the meter arithmetic `noise` feeds.
	func excitement_sources_at(_world_position: Vector2) -> Array:
		return [[self, noise]] if noise > 0.0 else []

	func accumulate_landed(_points: float) -> void:
		pass

var _world: FakeWorld
var _stroller: Stroller
var _baby: Baby

func run(t) -> void:
	_test_falloff(t)
	_test_telegraph_contract(t)
	_test_walking_fills_sleepiness(t)
	_test_a_day_cannot_be_won_on_street_gain_alone(t)
	_test_one_calm_stretch_wins_a_day(t)
	_test_a_day_is_a_minute_of_play_with_a_grace_of_three(t)
	_test_standing_still_is_worse_than_walking_but_affordable(t)
	_test_a_street_day_never_settles_and_a_park_day_does(t)
	_test_calm_zone_speeds_sleep(t)
	_test_idle_drains_sleepiness(t)
	_test_running_blocks_sleep_and_excites(t)
	_test_calm_threshold_freezes_sleepiness(t)
	_test_only_motion_settles_her(t)
	_test_alley_trickle(t)
	_test_falls_asleep(t)
	_test_sleeping_baby_is_less_sensitive(t)
	_test_wakes_up_with_penalty(t)
	_test_full_excitement_cries(t)
	_test_one_bump_near_the_ceiling(t)

# ------------------------------------------------------------- pure numbers ---

func _test_falloff(t) -> void:
	t.close_to(Tuning.falloff(0.0, 10.0, 40.0, 150.0), 10.0, "falloff at centre is full")
	t.close_to(Tuning.falloff(40.0, 10.0, 40.0, 150.0), 10.0, "falloff at inner edge is full")
	t.close_to(Tuning.falloff(150.0, 10.0, 40.0, 150.0), 0.0, "falloff at outer edge is zero")
	t.close_to(Tuning.falloff(200.0, 10.0, 40.0, 150.0), 0.0, "falloff beyond outer is zero")
	# `1 - t^2`, so the midpoint sits at three quarters rather than at the quarter the old
	# quadratic gave. *(Playtest 07, finding 18.)* The shape is the design — an obstacle has to
	# cost something from a distance or it is a thing to bump into rather than to route around —
	# so this is asserted as the number it is, and the note on `Tuning.falloff` says why.
	t.close_to(Tuning.falloff(95.0, 10.0, 40.0, 150.0), 7.5, "falloff midpoint is three quarters")
	t.check(Tuning.falloff(130.0, 10.0, 40.0, 150.0) > 2.0,
			"and three quarters of the way out it is still worth more than the walking decay")

	var previous := 11.0
	for d in range(0, 160, 5):
		var value := Tuning.falloff(float(d), 10.0, 40.0, 150.0)
		t.check(value <= previous + 0.0001, "falloff never rises with distance (d=%d)" % d)
		previous = value

func _test_telegraph_contract(t) -> void:
	# A player walking away the instant an event appears must clear the outer radius.
	var required := Tuning.required_telegraph_time(40.0, 150.0, false)
	t.close_to(required, 110.0 / Tuning.WALK_SPEED, "telegraph time covers the escape distance")
	t.close_to(Tuning.required_telegraph_time(40.0, 150.0, true), required * 2.0,
			"hard-fail events need double the margin")
	t.check(Tuning.validate_event("fair", required + 0.5, 40.0, 150.0, false),
			"a generous telegraph validates")

# ------------------------------------------------------------------ the rig ---

func _build(t) -> void:
	_world = FakeWorld.new()
	t.add_child(_world)
	_stroller = Stroller.new()
	# The name matters: Stroller's @onready looks the camera up by path.
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_stroller.add_child(camera)
	t.add_child(_stroller)
	_stroller.set_physics_process(false)
	_baby = Baby.new()
	_stroller.add_child(_baby)
	_baby.set_physics_process(false)

func _teardown() -> void:
	_stroller.free()
	_world.free()

## Drives the baby by hand at a fixed step so results do not depend on frame timing.
func _simulate(seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		_baby._physics_process(STEP)

func _walk() -> void:
	_stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)

func _sprint() -> void:
	_stroller.velocity = Vector2(Tuning.RUN_SPEED, 0.0)

func _stand() -> void:
	_stroller.velocity = Vector2.ZERO

# ------------------------------------------------------------- sleepiness ---

func _test_walking_fills_sleepiness(t) -> void:
	_build(t)
	_walk()
	_simulate(10.0)
	t.close_to(_baby.sleepiness, Tuning.SLEEPINESS_GAIN_WALKING * 10.0,
			"walking fills sleepiness at the base rate", 0.1)
	_teardown()

## Finding 2: circling the starting block filled the meter, so the city was decoration.
## The guarantee has to be arithmetic rather than a hope about how loud the streets are — a
## quiet back street never freezes the meter, so nothing else stops a player walking in
## circles all day.
func _test_a_day_cannot_be_won_on_street_gain_alone(t) -> void:
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var whole_day := Tuning.SLEEPINESS_GAIN_WALKING * Tuning.day_length(day)
		t.check(whole_day < Tuning.METER_MAX,
				"day %d cannot be won on street walking alone (%.0f of %.0f)"
				% [day, whole_day, Tuning.METER_MAX])
		t.check(whole_day > Tuning.METER_MAX * 0.5,
				"day %d still makes real progress on the way (%.0f of %.0f)"
				% [day, whole_day, Tuning.METER_MAX])

## The other half of the pitch: calm ground has to finish a day comfortably, not barely.
## Measured against the *short* day, because the curfew one is the strict case.
func _test_one_calm_stretch_wins_a_day(t) -> void:
	var stretch := Tuning.METER_MAX / Tuning.sleepiness_gain_calm()
	var short_day := Tuning.day_length(Tuning.RUN_LENGTH_DAYS)
	t.check(stretch < short_day * 0.6,
			"a calm stretch fills the meter in %.0fs, well inside the %.0fs day"
			% [stretch, short_day])

## M18's target, as arithmetic: **a day walked well is about a minute, and dusk is a grace
## of three.** Measured on the friendliest day the generator can produce — the nearest legal
## calm ground, walked to in a straight line with nothing in the way — so this is the floor
## a real day is measured up from, not a prediction of one.
##
## It is a relationship and not a stopwatch on purpose. What has to stay true is that the
## clock is *slack* for a well-walked day and the meter is not the thing standing in the way;
## the difficulty is supposed to be the walk. Both halves matter: a floor under 30s would
## mean the day is over before it starts, and a floor over the grace would mean dusk is the
## real opponent again, which is what M18 was undoing.
func _test_a_day_is_a_minute_of_play_with_a_grace_of_three(t) -> void:
	var leg := Tuning.MIN_HOME_TO_PARK_TILES * float(Tuning.TILE_SIZE) / Tuning.WALK_SPEED
	var banked := Tuning.SLEEPINESS_GAIN_WALKING * leg
	var stretch := (Tuning.METER_MAX - banked) / Tuning.sleepiness_gain_calm()
	var shortest := leg + stretch + leg
	t.check(shortest > 30.0,
			"the shortest possible day is %.0fs, which is still a walk" % shortest)
	t.check(shortest < 90.0,
			"the shortest possible day is %.0fs, near the minute it is aimed at" % shortest)
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(shortest < Tuning.day_length(day) * 0.6,
				"day %d's %.0fs of dusk is a grace, not the target (floor %.0fs)"
				% [day, Tuning.day_length(day), shortest])

func _test_standing_still_is_worse_than_walking_but_affordable(t) -> void:
	t.check(Tuning.SLEEPINESS_DRAIN_IDLE > Tuning.SLEEPINESS_GAIN_WALKING,
			"standing still loses ground rather than merely failing to gain it")
	t.check(Tuning.SLEEPINESS_DRAIN_IDLE < Tuning.sleepiness_gain_calm(),
			"a pause in a park costs less than the park gives, so stopping stays a move")

## The claim end to end, on a fake world where nothing is happening at all. Even with no
## events and no crowd — the friendliest possible day — the street cannot finish it and one
## calm stretch can, with time left over to walk home.
func _test_a_street_day_never_settles_and_a_park_day_does(t) -> void:
	_build(t)
	_walk()
	_simulate(Tuning.day_length(1))
	t.check(_baby.state == GameEnums.BabyState.AWAKE,
			"a whole day of undisturbed street walking still does not settle her")
	_teardown()

	_build(t)
	_walk()
	_simulate(45.0)          # the walk out to the park
	_world.calm = true
	var elapsed := 45.0
	var short_day := Tuning.day_length(Tuning.RUN_LENGTH_DAYS)
	while _baby.state != GameEnums.BabyState.ASLEEP and elapsed < short_day:
		_simulate(1.0)
		elapsed += 1.0
	t.check(_baby.state == GameEnums.BabyState.ASLEEP,
			"a walk out plus one calm stretch does settle her")
	t.check(elapsed < short_day * 0.75,
			"and settles her by %.0fs, leaving the walk home inside the %.0fs day"
			% [elapsed, short_day])
	_teardown()

func _test_calm_zone_speeds_sleep(t) -> void:
	_build(t)
	_world.calm = true
	_walk()
	_simulate(10.0)
	t.close_to(_baby.sleepiness,
			Tuning.SLEEPINESS_GAIN_WALKING * Tuning.SLEEPINESS_CALM_ZONE_MULTIPLIER * 10.0,
			"a calm zone multiplies the sleepiness gain", 0.1)
	_teardown()

func _test_idle_drains_sleepiness(t) -> void:
	_build(t)
	_baby.sleepiness = 50.0
	_stand()
	_simulate(10.0)
	t.close_to(_baby.sleepiness, 50.0 - Tuning.SLEEPINESS_DRAIN_IDLE * 10.0,
			"standing still drains sleepiness", 0.1)
	_teardown()

func _test_running_blocks_sleep_and_excites(t) -> void:
	_build(t)
	_baby.sleepiness = 50.0
	_sprint()
	_simulate(1.0)
	t.close_to(_baby.sleepiness, 50.0, "running neither fills nor drains sleepiness", 0.1)
	t.close_to(_baby.excitement,
			(Tuning.EXCITEMENT_FROM_RUNNING - Tuning.EXCITEMENT_DECAY_RUNNING) * 1.0,
			"a full sprint raises excitement at the net rate", 0.15)
	_teardown()

func _test_calm_threshold_freezes_sleepiness(t) -> void:
	_build(t)
	_baby.sleepiness = 40.0
	_baby.excitement = Tuning.EXCITEMENT_CALM_THRESHOLD + 5.0
	# Noise exactly cancels the walking decay, so excitement holds above the threshold.
	_world.noise = Tuning.EXCITEMENT_DECAY_WALKING
	_walk()
	_simulate(4.0)
	t.close_to(_baby.sleepiness, 40.0,
			"sleepiness is frozen, not drained, above the calm threshold", 0.05)
	t.close_to(_baby.excitement, Tuning.EXCITEMENT_CALM_THRESHOLD + 5.0,
			"excitement holds when incoming equals decay", 0.05)
	_teardown()

# ------------------------------------------------------------- excitement ---

## *(Playtest 07, finding 3.)* Standing still used to be the fastest recovery in the game, which
## made "stop in the middle of the street and wait until everything is good" the strongest move
## there was. What settles a baby is being pushed, so the ordering is motion-shaped now: walking
## calms most, running calms a little, standing calms nothing at all.
##
## Asserted as a **relationship** rather than as the three numbers, because the ordering is the
## design and the values are not.
func _test_only_motion_settles_her(t) -> void:
	t.check(Tuning.EXCITEMENT_DECAY_IDLE <= 0.0,
			"standing still does not settle her at all")
	t.check(Tuning.EXCITEMENT_DECAY_WALKING > Tuning.EXCITEMENT_DECAY_RUNNING,
			"walking settles her faster than running does")
	t.check(Tuning.EXCITEMENT_DECAY_RUNNING > Tuning.EXCITEMENT_DECAY_IDLE,
			"even running is motion, so it settles her more than standing does")

	# **And the other axis of the same table: what she is standing on.** *(Playtest 63.)* Five
	# grounds, best to worst, asserted as the ordering rather than as five numbers — the absolute
	# rates are what a rig measures and this is what the route decision is made of. A ground that
	# swapped places with its neighbour would make some street the wrong answer everywhere.
	t.check(Tuning.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER
			> Tuning.EXCITEMENT_DECAY_PRECINCT_MULTIPLIER,
			"a park settles her faster than a precinct")
	t.check(Tuning.EXCITEMENT_DECAY_PRECINCT_MULTIPLIER > 1.0,
			"and a precinct faster than an ordinary street, which is why it is worth walking to")
	t.check(1.0 > Tuning.EXCITEMENT_DECAY_ALLEY_MULTIPLIER,
			"an ordinary street is better ground than an alley")
	t.check(Tuning.EXCITEMENT_DECAY_ALLEY_MULTIPLIER
			> Tuning.EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER,
			"and an alley better than the main road, which stays the worst ground in the city")

	_build(t)
	_baby.excitement = 50.0
	_stand()
	_simulate(5.0)
	t.close_to(_baby.excitement, 50.0,
			"a quiet spot with nobody moving holds the meter where it is", 0.1)
	_teardown()

	_build(t)
	_baby.excitement = 50.0
	_walk()
	_simulate(5.0)
	t.close_to(_baby.excitement, 50.0 - Tuning.EXCITEMENT_DECAY_WALKING * 5.0,
			"walking the same quiet spot is what brings it down", 0.1)
	_teardown()

func _test_alley_trickle(t) -> void:
	_build(t)
	_world.alley = true
	_walk()
	# **Against the decay on an alley's own ground, not against the flat walking rate.** *(Playtest
	# 63.)* An alley has a multiplier of its own — 3.5/s against an ordinary street's 6.0 — and the
	# trickle is set just under it: comparing it to the unmultiplied rate would call an alley safe
	# on the strength of a number that is never applied in one. What has to stay true is that an
	# empty alley is very nearly flat: it cannot build excitement on its own, and it is never quite
	# recovery either, which is the pressure the row is for.
	var alley_decay := Tuning.EXCITEMENT_DECAY_WALKING * Tuning.EXCITEMENT_DECAY_ALLEY_MULTIPLIER
	t.check(Tuning.EXCITEMENT_FROM_ALLEY < alley_decay,
			"walking an empty alley should not by itself build excitement (%.1f against %.1f)"
			% [Tuning.EXCITEMENT_FROM_ALLEY, alley_decay])
	t.check(Tuning.EXCITEMENT_FROM_ALLEY > alley_decay * 0.5,
			"but it is close enough underneath that an alley is not somewhere she recovers")
	# And the ordering the ground table is made of: an alley is worse ground than the street it
	# cuts between and better than the spine.
	t.check(Tuning.EXCITEMENT_DECAY_ALLEY_MULTIPLIER < 1.0
			and Tuning.EXCITEMENT_DECAY_ALLEY_MULTIPLIER
			> Tuning.EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER,
			"an alley sits between an ordinary street and the main road")
	_simulate(1.0)
	t.close_to(_baby.last_incoming, Tuning.EXCITEMENT_FROM_ALLEY,
			"an alley contributes its trickle to incoming excitement")
	_teardown()

# ------------------------------------------------------------------ states ---

func _test_falls_asleep(t) -> void:
	_build(t)
	var announced := [false]
	var handler := func() -> void: announced[0] = true
	EventBus.return_phase_started.connect(handler)
	# Half a second of walking away from asleep, expressed as a rate rather than a number,
	# so re-pitching the fill cannot silently stop this test reaching the threshold.
	_baby.sleepiness = Tuning.METER_MAX - Tuning.SLEEPINESS_GAIN_WALKING * 0.5
	_walk()
	_simulate(1.0)
	EventBus.return_phase_started.disconnect(handler)
	t.check(_baby.state == GameEnums.BabyState.ASLEEP, "a full sleepiness meter puts the baby to sleep")
	t.check(announced[0], "falling asleep starts the return phase")
	_teardown()

func _test_sleeping_baby_is_less_sensitive(t) -> void:
	_build(t)
	_baby.state = GameEnums.BabyState.ASLEEP
	_world.noise = 20.0
	_walk()
	_simulate(STEP)
	t.close_to(_baby.last_incoming, 20.0 * Tuning.SLEEPING_SENSITIVITY,
			"incoming excitement is damped while the baby sleeps")
	_teardown()

func _test_wakes_up_with_penalty(t) -> void:
	_build(t)
	_baby.state = GameEnums.BabyState.ASLEEP
	_baby.sleepiness = Tuning.METER_MAX
	_baby.excitement = Tuning.EXCITEMENT_WAKE_THRESHOLD - 2.0
	_world.noise = 40.0
	_walk()
	_simulate(0.5)
	t.check(_baby.state == GameEnums.BabyState.AWAKE, "loud enough noise wakes a sleeping baby")
	t.close_to(_baby.sleepiness, Tuning.WAKE_SLEEPINESS_PENALTY,
			"waking costs the sleepiness penalty")
	_teardown()

func _test_full_excitement_cries(t) -> void:
	_build(t)
	_baby.excitement = Tuning.METER_MAX - 1.0
	_world.noise = 60.0
	_walk()
	_simulate(0.5)
	t.check(_baby.state == GameEnums.BabyState.CRYING, "a full excitement meter loses the day")
	# Crying is terminal for the day: nothing moves after it.
	var frozen := _baby.excitement
	_stand()
	_simulate(2.0)
	t.close_to(_baby.excitement, frozen, "the meters stop once the baby is crying")
	_teardown()

## M96, the teaching day and the dog after it: where one contact on an otherwise empty street
## becomes a cliff. **Measured, not designed** — a real `CrowdAgent`'s own `startle()`, the same
## call `Crowd._bump()` makes on a genuine contact, driven by hand since a bare agent has no lane
## to steer in.
##
## **Stated as where the cliff is rather than as what happens at 90**, because the height of one
## contact is the difference between what the jolt lands and what the ground gives back over the
## same second and a bit, and the second of those is a balance number that moves. *(Playtest 63
## raised the walking decay and one contact from 90 stopped ending the day — at 90 it now reaches
## 98.8, a point and a bit short.)* What the number was ever worth knowing for is the relationship
## below it: **a single contact may only be fatal from inside the band the pram is already
## warning about.** A contact that killed from under `EXCITEMENT_NEARLY_CRYING` would be a death
## with no cue in front of it, which is the one thing this suite exists to refuse.
func _test_one_bump_near_the_ceiling(t) -> void:
	var landed := _one_bump_from(t, 90.0) - 90.0
	t.check(landed > 0.0,
			"one contact still puts the meter up on an empty street (%.2f)" % landed)
	var fatal_from := Tuning.METER_MAX - landed
	t.check(fatal_from > Tuning.EXCITEMENT_NEARLY_CRYING,
			"one contact ends the day only from %.1f up, which is inside the nearly-crying band "
			% fatal_from + "(%.0f) the pram is already showing"
			% Tuning.EXCITEMENT_NEARLY_CRYING)
	t.check(fatal_from < Tuning.METER_MAX,
			"and there is a height from which it does end the day, so a contact stays a cliff")
	# The other end, walked rather than derived: from just inside that height it really does cry.
	t.check(_one_bump_from(t, fatal_from + 1.0) >= Tuning.METER_MAX,
			"and one contact from %.1f ends it" % (fatal_from + 1.0))

## The meter after one whole contact, starting from `at` and walking ordinary ground.
func _one_bump_from(t, at: float) -> float:
	_build(t)
	var agent := CrowdAgent.new()
	agent.global_position = _stroller.global_position
	agent.startle(Tuning.BUMP_INTENSITY, Tuning.BUMP_DURATION,
			Tuning.BUMP_INNER_RADIUS, Tuning.BUMP_OUTER_RADIUS)
	_baby.excitement = at
	_walk()
	var jolt := Tuning.BUMP_DURATION
	while jolt > 0.0:
		agent._jolt = jolt
		_world.noise = agent.contribution_at(_stroller.global_position)
		_baby._physics_process(STEP)
		jolt -= STEP
	var reached := _baby.excitement
	agent.free()
	_teardown()
	return reached
