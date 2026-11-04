extends RefCounted
## `WalkPlan`, a movement script's smooth option: a turn sweeps her heading gradually from one
## step's direction to the next and still leaves her exactly where the abrupt script does.
## *(2026-10-10, dotted-wombat, inbox #633: "west 1s north 1s has a movement in 270 (left) then
## gradually going to 0 (north) in a way that the exact horizontal position ends up being the same
## as with the abrupt version … they should end up in the same exact place no matter whether smooth
## is on or off".)*
##
## Every walk here drives a real `Stroller` in the tree through the real input actions —
## `WalkPlan.press()` into `Input.get_vector()`, the acceleration ramp, the facing turn — on real
## physics ticks, one a frame (`tests/physics_ticks.gd`), and reads where she stands after each. What
## presses is the rig a player types the words for: `AutoScreenshot.from_config()` on `--walk`, with
## `--smooth-walk` for the smoothed one, so the order is the game's own (the input pressed for tick
## `n` is read on tick `n + 1`). The abrupt rig reads a clock handed to it that counts physics ticks
## (`simulation_clock`, the one a scene recipe hands its screenshot), so its steps change on the same
## tick the plan's do.
##
## **Equal means within `TOLERANCE`**, a hundredth of a pixel: the construction is exact on open
## ground, and what is left is the single-precision rounding of the pressed strengths and of
## `Vector2` arithmetic over a few hundred ticks.

const UI := preload("res://tests/ui_screens.gd")
const TOLERANCE := 0.01
## Ticks walked past the end of a script, so both versions have come to rest.
const RUN_OUT := 30

func run(t) -> void:
	await PhysicsTicks.settle(t)
	await _test_west_then_north_ends_where_the_abrupt_script_does(t)
	await _test_the_turn_sweeps_through_the_bearings_between(t)
	await _test_an_oblique_bearing_turn_ends_where_the_abrupt_script_does(t)
	await _test_a_reversal_slows_through_a_stop_and_ends_where_the_abrupt_script_does(t)
	await _test_a_running_turn_and_a_turn_after_a_short_lead_in(t)
	_test_smooth_off_presses_exactly_the_abrupt_script(t)
	_test_what_is_never_smoothed_presses_exactly_the_abrupt_script(t)
	_test_a_blended_press_reads_back_as_the_blend(t)
	await _test_a_smooth_walk_rig_presses_the_plan_tick_by_tick(t)
	await _test_the_step_clock_never_advances_a_smooth_script(t)
	_test_a_recipe_says_smooth_with_a_boolean(t)

# ----------------------------------------------------------------- the walks ---

## A Stroller with the camera it looks up by path, in the tree so its `@onready` runs and its own
## physics ticks move her — the same rig `tests/test_danger.gd` builds.
func _rig(t) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	return rig

## The seconds a rig's script has run, counted in the physics ticks the walk has let pass (the
## walk sets `ticks` after each one, before the frame's `_process()` runs).
class TickClock extends RefCounted:
	var ticks := 0

	func read() -> float:
		return float(ticks) / Engine.physics_ticks_per_second

## The rig a player gets from `--walk script` (and `--smooth-walk`), built by the game's own
## `from_config()`. `--after 600` keeps it from ever reaching its capture, which quits a headless
## process.
func _walk_rig(script: String, smooth: bool, clock: TickClock) -> AutoScreenshot:
	var words := ["--screenshot", "scratch_unused.png", "--after", "600", "--walk", script]
	if smooth:
		words.append("--smooth-walk")
	var rig := AutoScreenshot.from_config(RunConfig.parse(PackedStringArray(words), "", true))
	rig.simulation_clock = clock.read
	return rig

## Walks `script` from a standstill at the origin, smooth or abrupt, and returns where she is after
## every tick (`positions[n]` after `n` ticks), her velocity after every tick, and the plan.
func _walk(t, script: String, smooth: bool) -> Dictionary:
	var steps := AutoScreenshot.parse_script(script)
	var plan := WalkPlan.make(steps, Engine.physics_ticks_per_second, smooth)
	var total := 0.0
	for step: Dictionary in steps:
		total += float(step.seconds)
	var stroller := _rig(t)
	var clock := TickClock.new()
	var rig := _walk_rig(script, smooth, clock)
	t.add_child(rig)
	var positions: Array[Vector2] = [stroller.global_position]
	var velocities: Array[Vector2] = [Vector2.ZERO]
	var after_a_tick := func(ran: int) -> void:
		clock.ticks = ran
		positions.append(stroller.global_position)
		velocities.append(stroller.velocity)
	await PhysicsTicks.pass_ticks(t, ceili(total * Engine.physics_ticks_per_second) + RUN_OUT,
			after_a_tick)
	rig.free()
	_release()
	stroller.free()
	return {"positions": positions, "velocities": velocities, "plan": plan}

func _release() -> void:
	TouchControls.set_axis(&"move_left", &"move_right", 0.0)
	TouchControls.set_axis(&"move_up", &"move_down", 0.0)
	Input.action_release(&"run")

## The two walks of `script` agree wherever her velocity does — before a turn, and from the moment
## the smoothed turn has caught up with the abrupt one — and end at rest at the same point. The
## count of agreeing ticks after the first turn keeps "wherever" from being vacuous.
func _check_same_place(t, script: String, smoothed: int) -> Dictionary:
	var abrupt: Dictionary = await _walk(t, script, false)
	var smooth: Dictionary = await _walk(t, script, true)
	var plan: WalkPlan = smooth.plan
	t.check(plan.smoothed_turns() == smoothed,
			"'%s' smooths %d turn(s) (got %d)" % [script, smoothed, plan.smoothed_turns()])
	var a_positions: Array[Vector2] = abrupt.positions
	var s_positions: Array[Vector2] = smooth.positions
	var a_velocities: Array[Vector2] = abrupt.velocities
	var s_velocities: Array[Vector2] = smooth.velocities
	var last := a_positions.size() - 1
	t.check(a_positions[last].distance_to(s_positions[last]) <= TOLERANCE,
			"'%s' ends at the same point smooth or abrupt (abrupt %s, smooth %s)"
					% [script, a_positions[last], s_positions[last]])
	t.check(a_velocities[last] == Vector2.ZERO and s_velocities[last] == Vector2.ZERO,
			"'%s' has come to rest by the end of both walks" % script)
	var apart := 0
	var agreeing_after_apart := 0
	var worst := 0.0
	for n in a_positions.size():
		if a_velocities[n].distance_to(s_velocities[n]) > 0.001:
			apart += 1
			continue
		if apart > 0:
			agreeing_after_apart += 1
			worst = maxf(worst, a_positions[n].distance_to(s_positions[n]))
	t.check(apart > 0, "'%s' does walk a different path through its turns smooth" % script)
	t.check(agreeing_after_apart > RUN_OUT, "'%s' has ticks after a turn to compare (%d)"
			% [script, agreeing_after_apart])
	t.check(worst <= TOLERANCE,
			"'%s' is at the same point whenever the two walks are moving alike (worst %.5fpx)"
					% [script, worst])
	return {"abrupt": abrupt, "smooth": smooth}

## The player's own case: one second west, one second north, from one spot.
func _test_west_then_north_ends_where_the_abrupt_script_does(t) -> void:
	await _check_same_place(t, "1w1n", 1)
	# And with a turn on each side of a middle step, so a position after one turn and before the
	# next is compared, not only the end.
	await _check_same_place(t, "1w1n1e", 2)

## "Gradually": the smooth walk heads through bearings strictly between west and north, which
## the abrupt one only crosses in the few ticks its velocity takes to swing.
func _test_the_turn_sweeps_through_the_bearings_between(t) -> void:
	var walks: Dictionary = await _check_same_place(t, "1w1n", 1)
	var smooth_between := 0
	var abrupt_between := 0
	for pair in [["smooth", walks.smooth], ["abrupt", walks.abrupt]]:
		var velocities: Array[Vector2] = pair[1].velocities
		var count := 0
		for velocity in velocities:
			# Bearing clockwise from north: west is 270, north is 0/360.
			var bearing := fposmod(rad_to_deg(atan2(velocity.x, -velocity.y)), 360.0)
			if velocity.length() > 1.0 and bearing > 280.0 and bearing < 350.0:
				count += 1
		if pair[0] == "smooth":
			smooth_between = count
		else:
			abrupt_between = count
	t.check(smooth_between >= 3 * maxi(abrupt_between, 1),
			"the smooth turn spends several times as long between west and north as the abrupt one (%d ticks against %d)"
					% [smooth_between, abrupt_between])

## Two bearings neither of which is an axis, through an angle that is not a right angle.
func _test_an_oblique_bearing_turn_ends_where_the_abrupt_script_does(t) -> void:
	await _check_same_place(t, "1.5@30@1.5@145@", 1)

## A reversal cannot sweep without drifting sideways, so it slows to a stop and walks back.
func _test_a_reversal_slows_through_a_stop_and_ends_where_the_abrupt_script_does(t) -> void:
	var walks: Dictionary = await _check_same_place(t, "1e1w", 1)
	var velocities: Array[Vector2] = walks.smooth.velocities
	var sideways := 0.0
	for velocity in velocities:
		sideways = maxf(sideways, absf(velocity.y))
	t.check(sideways == 0.0, "a smoothed reversal never drifts off its line (most %.5f)" % sideways)

## A turn at a run, and a turn after a lead-in too short for the full window, which a trailer
## shot's first legs are.
func _test_a_running_turn_and_a_turn_after_a_short_lead_in(t) -> void:
	await _check_same_place(t, "1.5W1.5N", 1)
	await _check_same_place(t, "0.3s2w", 1)

# --------------------------------------------------------------- unchanged ---

## Smooth off presses on every tick exactly the step that tick falls in — the step's own vector and
## run, bit for bit, never a blend.
func _test_smooth_off_presses_exactly_the_abrupt_script(t) -> void:
	var steps := AutoScreenshot.parse_script("1w0.5p1.2@45@0.6S1n")
	var plan := WalkPlan.make(steps, Engine.physics_ticks_per_second, false)
	var mismatches := 0
	var ticks := 0
	var elapsed := 0
	for step: Dictionary in steps:
		var ticks_in := roundi(float(step.seconds) * Engine.physics_ticks_per_second)
		# The tick in the middle of the step, clear of any boundary's rounding.
		var input := plan.input_at(elapsed + ticks_in / 2)
		ticks += 1
		if input.direction != step.direction or input.run != step.run or input.blending:
			mismatches += 1
		elapsed += ticks_in
	t.check(mismatches == 0 and ticks == steps.size(),
			"smooth off presses each step's own vector and run (%d of %d differ)" % [mismatches, ticks])
	t.check(plan.input_at(elapsed + 5).direction == Vector2.ZERO and not plan.input_at(elapsed + 5).run,
			"and nothing once the script has ended")

## A stand, a change between walking and running, and a turn with no room on either side are left
## abrupt: the smooth plan presses on every tick what the abrupt one does.
func _test_what_is_never_smoothed_presses_exactly_the_abrupt_script(t) -> void:
	for script in ["1e1W", "1e0.5p1w", "1e0.1n1w"]:
		var steps := AutoScreenshot.parse_script(script)
		var abrupt := WalkPlan.make(steps, Engine.physics_ticks_per_second, false)
		var smooth := WalkPlan.make(steps, Engine.physics_ticks_per_second, true)
		var differ := 0
		for tick in 100:
			var a := abrupt.input_at(tick)
			var s := smooth.input_at(tick)
			if a.direction != s.direction or a.run != s.run or s.blending:
				differ += 1
		t.check(smooth.smoothed_turns() == 0 and differ == 0,
				"'%s' has no turn to smooth and presses exactly the abrupt script (%d ticks differ)"
						% [script, differ])

## The deadzone `Input.get_vector()` applies is undone before the press, so what she reads is the
## blend itself, not a slower walk still.
func _test_a_blended_press_reads_back_as_the_blend(t) -> void:
	for wanted: Vector2 in [Vector2(-0.5, -0.5), Vector2(0.1, 0.0), Vector2(0.3, -0.6)]:
		WalkPlan.press({"direction": wanted, "run": false, "blending": true})
		var read := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		t.check(read.distance_to(wanted) < 0.0001,
				"a blended press of %s reads back as itself (got %s)" % [wanted, read])
	_release()

# ------------------------------------------------------------------ callers ---

## `--smooth-walk`: the rig presses the plan from its physics tick, not the script's step clock. The
## rig stands in the tree and its own ticks run; what it pressed is read off `Input` after each.
func _test_a_smooth_walk_rig_presses_the_plan_tick_by_tick(t) -> void:
	var node := _walk_rig("1w1n", true, TickClock.new())
	t.add_child(node)
	var read := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	t.check(read == Vector2.LEFT, "a smooth script starts on its first step's own press")
	var blended := [0]
	var last := [Vector2.ZERO]
	# Fifty ticks: past the turn's window, and short of the script's end at sixty.
	var after_a_tick := func(_ran: int) -> void:
		var pressed := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		last[0] = pressed
		if pressed.x < -0.01 and pressed.y < -0.01:
			blended[0] += 1
	await PhysicsTicks.pass_ticks(t, 50, after_a_tick)
	t.check(blended[0] > 6, "and presses between west and north through the turn (%d ticks)"
			% blended[0])
	t.check((last[0] as Vector2).is_equal_approx(Vector2.UP), "and north once the turn is over")
	node.free()
	_release()

## Reads what is pressed after the rig's own `_process()` of every frame (a probe that runs later in
## the frame), since a step clock's press is overwritten by the plan's on the next tick.
class Probe extends Node:
	var seen: Array[Vector2] = []

	func _init() -> void:
		process_priority = 100

	func _process(_delta: float) -> void:
		seen.append(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down"))

## A step clock reading past the first one-second step would advance an abrupt script to north; a
## smooth script is pressed by its plan alone, so with the clock read at 1.5s while the plan is
## still on its first step the press stays west on every frame.
func _test_the_step_clock_never_advances_a_smooth_script(t) -> void:
	var clock := UI.FakeClock.new()
	var node := _walk_rig("1w1n", true, TickClock.new())
	node.simulation_clock = clock.read
	t.add_child(node)
	var probe := Probe.new()
	t.add_child(probe)
	await PhysicsTicks.pass_ticks(t, 4)
	clock.now = 1.5
	probe.seen.clear()
	await PhysicsTicks.pass_ticks(t, 4)
	var west := 0
	for pressed in probe.seen:
		if pressed == Vector2.LEFT:
			west += 1
	t.check(probe.seen.size() >= 4 and west == probe.seen.size(),
			"the step clock never advances a smooth script (west on %d of %d frames)"
					% [west, probe.seen.size()])
	node.free()
	probe.free()
	_release()

## `playback.smooth` is a boolean or the recipe is refused, like every other playback switch.
func _test_a_recipe_says_smooth_with_a_boolean(t) -> void:
	var recipe := {"playback": {"walk": "1w1n", "smooth": true}}
	t.check(not "\n".join(SceneRecipeRuntime.validate_runtime(recipe)).contains("smooth"),
			"a boolean smooth is accepted")
	recipe.playback.smooth = "yes"
	t.check("\n".join(SceneRecipeRuntime.validate_runtime(recipe)).contains("playback.smooth"),
			"anything else is refused by name")
