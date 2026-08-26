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

	func is_calm_zone(_world_position: Vector2) -> bool:
		return calm

	func is_alley(_world_position: Vector2) -> bool:
		return alley

	func total_excitement_at(_world_position: Vector2) -> float:
		return noise

var _world: FakeWorld
var _stroller: Stroller
var _baby: Baby

func run(t) -> void:
	_test_falloff(t)
	_test_telegraph_contract(t)
	_test_walking_fills_sleepiness(t)
	_test_calm_zone_speeds_sleep(t)
	_test_idle_drains_sleepiness(t)
	_test_running_blocks_sleep_and_excites(t)
	_test_calm_threshold_freezes_sleepiness(t)
	_test_excitement_decays(t)
	_test_alley_trickle(t)
	_test_falls_asleep(t)
	_test_sleeping_baby_is_less_sensitive(t)
	_test_wakes_up_with_penalty(t)
	_test_full_excitement_cries(t)

# ------------------------------------------------------------- pure numbers ---

func _test_falloff(t) -> void:
	t.close_to(Tuning.falloff(0.0, 10.0, 40.0, 150.0), 10.0, "falloff at centre is full")
	t.close_to(Tuning.falloff(40.0, 10.0, 40.0, 150.0), 10.0, "falloff at inner edge is full")
	t.close_to(Tuning.falloff(150.0, 10.0, 40.0, 150.0), 0.0, "falloff at outer edge is zero")
	t.close_to(Tuning.falloff(200.0, 10.0, 40.0, 150.0), 0.0, "falloff beyond outer is zero")
	# Quadratic, so the midpoint sits at a quarter, not a half.
	t.close_to(Tuning.falloff(95.0, 10.0, 40.0, 150.0), 2.5, "falloff midpoint is quarter")

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

func _test_excitement_decays(t) -> void:
	_build(t)
	_baby.excitement = 50.0
	_stand()
	_simulate(5.0)
	t.close_to(_baby.excitement, 50.0 - Tuning.EXCITEMENT_DECAY_IDLE * 5.0,
			"excitement decays fastest while standing still", 0.1)
	_teardown()

func _test_alley_trickle(t) -> void:
	_build(t)
	_world.alley = true
	_walk()
	# Alley trickle is below the walking decay, so an alley alone cannot raise excitement.
	t.check(Tuning.EXCITEMENT_FROM_ALLEY < Tuning.EXCITEMENT_DECAY_WALKING,
			"walking an empty alley should not by itself build excitement")
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
	_baby.sleepiness = Tuning.METER_MAX - 1.0
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
