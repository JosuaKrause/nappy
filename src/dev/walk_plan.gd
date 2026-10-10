class_name WalkPlan
extends RefCounted
## What a movement script (`AutoScreenshot._parse_script()`'s steps) presses on each physics tick —
## abruptly, one step's direction after the next, or with its turns smoothed. `--walk` with
## `--smooth-walk` and a scene recipe's `playback.walk` with `playback.smooth` both read it, so the
## two drivers of a script cannot disagree about where a smoothed turn puts her.
##
## *(2026-10-10, dotted-wombat, inbox #633: "west 1s north 1s has a movement in 270 (left) then
## gradually going to 0 (north) in a way that the exact horizontal position ends up being the same
## as with the abrupt version … they should end up in the same exact place no matter whether smooth
## is on or off".)*
##
## **A smooth turn blends the pressed vector itself, not the heading.** Over a window of `N` ticks
## the press goes in a straight line from the old step's unit vector `a` to the new one's `b`
## (`a.lerp(b, s)`, `s` rising linearly from 0 to 1), so her heading sweeps gradually from one to
## the other through every bearing between them and her speed dips to `cos(Δ/2)` of full at the
## middle of a turn through `Δ` (0.71 for a right angle, nothing at all for a reversal, which is
## therefore a slow-down and turn rather than a sweep). Turning at full speed instead would cut the
## corner and land somewhere else; no full-speed turn that sweeps steadily from `a` to `b` can land
## where the abrupt script does, and a reversal at speed cannot avoid a sideways drift at all.
##
## **Why the blend lands exactly where the abrupt script does.** The stroller moves her velocity
## toward `input * speed` by at most `Tuning.ACCELERATION` a tick (`Stroller._physics_process()`),
## so an abrupt turn is itself a straight line in velocity from `a * speed` to `b * speed`, a few
## ticks long. The blend is the same straight line, slower; on that line only the *sum* of each
## tick's fraction of the way from `a` to `b` decides the displacement. The window is long enough
## that her velocity reaches every tick's target (`N` is at least the abrupt change's own length in
## ticks), and its centre is placed so its fractions sum to exactly the abrupt change's — the abrupt
## velocity's shortfall behind an instant switch, `D` ticks, read off a replay of the abrupt
## script's own velocity (`_replay_abrupt_velocity()`) — so from the window's end on, both scripts
## have her at the same point at the same speed. `tests/test_walk_plan.gd` holds that against a
## real `Stroller`.
##
## **A slower press is scripted only.** A press shorter than one is the slow walk the game does not
## have *(2026-09-06: "there is no way to walk slowly -- that is intentional -- there should only
## ever be one speed (plus a second via running)")*; this class lives under `src/dev/`, both of its
## callers are reachable only through a debug build's dev flags or a scene recipe, and no player's
## input path reads it. Smooth off presses exactly what the abrupt script always pressed.
##
## **What is never smoothed**, so it stays exactly as abrupt: a step into or out of a stand (`p`),
## a change between walking and running, a turn whose window cannot fit inside the half of each
## neighbouring step nearest it (with the velocity settled before it starts) while still being as
## long as the abrupt change itself, and a turn whose abrupt version has not settled to full speed
## by either of its step boundaries. The position guarantee is a guarantee for open ground: a wall,
## a stair flight or a shove from the crowd moves her differently on different paths.

## How long a smooth turn takes when both neighbouring steps have room for it. Shorter when they do
## not: a turn never reaches past half of either neighbouring step.
const TURN_SECONDS := 0.8

var _steps: Array[Dictionary] = []
var _ticks_per_second := 30
## One entry per smoothed turn: `{"from": Vector2, "to": Vector2, "centre": float, "width": int}`,
## `centre` and `width` in ticks. See `_plan_turns()`.
var _turns: Array[Dictionary] = []

## A plan for `steps` (`AutoScreenshot._parse_script()`'s shape) at `ticks_per_second`, smoothing
## its turns when `smooth` is true.
static func make(steps: Array[Dictionary], ticks_per_second: int, smooth: bool) -> WalkPlan:
	var plan := WalkPlan.new()
	plan._steps = steps
	plan._ticks_per_second = ticks_per_second
	if smooth:
		plan._plan_turns()
	return plan

## How many turns this plan smooths, for a caller to report and a test to read.
func smoothed_turns() -> int:
	return _turns.size()

## The step the abrupt script holds for the input sampled at `tick` (physics ticks since the script
## started), or `_steps.size()` once it has ended. The same subtraction a recipe's playback has
## always made, so smooth off is the same press on the same tick.
func step_at(tick: int) -> int:
	var remaining := float(tick) / _ticks_per_second
	for index in _steps.size():
		if remaining < float(_steps[index].seconds):
			return index
		remaining -= float(_steps[index].seconds)
	return _steps.size()

## What to press for the input sampled at `tick`: `{"direction": Vector2, "run": bool, "blending":
## bool}`. `direction` is the step's own unit vector, or nothing during a stand and after the end,
## except inside a smoothed turn's window, where it is the blend and `blending` is true.
func input_at(tick: int) -> Dictionary:
	var index := step_at(tick)
	var direction := Vector2.ZERO
	var running := false
	if index < _steps.size():
		direction = _steps[index].direction
		running = bool(_steps[index].get("run", false))
	for turn: Dictionary in _turns:
		var fraction := _fraction(turn, tick)
		if fraction > 0.0 and fraction < 1.0:
			var from: Vector2 = turn.from
			return {"direction": from.lerp(turn.to, fraction), "run": running, "blending": true}
	return {"direction": direction, "run": running, "blending": false}

## Presses `input` (`input_at()`'s answer) through the call the touch scheme presses through,
## `TouchControls._set_axis()` on both axes, and holds or lets go of `run` to match.
##
## **A blended press is lengthened by the deadzone first.** `Input.get_vector()`, which the stroller
## reads, maps a pressed length `L` between the actions' deadzone and one onto `(L - deadzone) / (1
## - deadzone)`, so pressing the blend as it is would walk her slower still than the blend asks
## for. The press is the length that mapping turns back into the blend's own. An unblended step is
## pressed untouched, bit for bit what the abrupt script presses.
static func press(input: Dictionary) -> void:
	var direction: Vector2 = input.direction
	if bool(input.get("blending", false)):
		direction = pressed_for(direction)
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)
	if bool(input.run):
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")

## The vector to press so that `Input.get_vector()` on the four `move_*` actions reads back
## `wanted`, whose length is below one. Nothing for nothing: a zero blend (the middle of a
## reversal) is a release, the same as a stand.
static func pressed_for(wanted: Vector2) -> Vector2:
	var length := wanted.length()
	if length == 0.0:
		return Vector2.ZERO
	# `Input.get_vector()` takes the mean of the four actions' own deadzones when it is given none.
	var deadzone := 0.25 * (InputMap.action_get_deadzone(&"move_left")
			+ InputMap.action_get_deadzone(&"move_right") + InputMap.action_get_deadzone(&"move_up")
			+ InputMap.action_get_deadzone(&"move_down"))
	return wanted * ((deadzone + length * (1.0 - deadzone)) / length)

## How far through `turn` the input sampled at `tick` is, from 0 (still the old step) to 1 (the new
## one). Linear in the tick across a window `width` ticks wide around `centre`.
static func _fraction(turn: Dictionary, tick: int) -> float:
	return clampf((float(tick) - float(turn.centre)) / float(turn.width) + 0.5, 0.0, 1.0)

## Finds every turn that can be smoothed and where its window goes.
##
## Ticks are counted by the input they sample: the stroller's velocity after reading the input
## sampled at tick `j` is `velocity[j + 1]`. `n0` is the first tick whose input is the new step's.
## For an abrupt change the shortfall behind an instant one is `D = Σ (1 - σ)` over the ticks after
## `n0`, `σ` being how far along from `a * speed` to `b * speed` her velocity has got. For the blend,
## whose velocity is its own fraction `s` every tick, the shortfall is `Σ (step - s)`, and with a
## whole number of ticks in the window that is exactly `centre - (n0 - 0.5)` wherever the centre
## sits — so `centre = n0 - 0.5 + D`.
func _plan_turns() -> void:
	var starts := _step_start_ticks()
	var velocity := _replay_abrupt_velocity(starts[_steps.size()] + 1)
	var dt := 1.0 / _ticks_per_second
	var wanted_width := roundi(TURN_SECONDS * _ticks_per_second)
	for k in range(1, _steps.size()):
		var before: Dictionary = _steps[k - 1]
		var after: Dictionary = _steps[k]
		var a: Vector2 = before.direction
		var b: Vector2 = after.direction
		if a == Vector2.ZERO or b == Vector2.ZERO or a.is_equal_approx(b) \
				or bool(before.get("run", false)) != bool(after.get("run", false)):
			continue
		var speed := Tuning.RUN_SPEED if bool(after.get("run", false)) else Tuning.WALK_SPEED
		var previous_start: int = starts[k - 1]
		var n0: int = starts[k]
		var next_start: int = starts[k + 1]
		if not _settled(velocity[n0], a * speed) or not _settled(velocity[next_start], b * speed):
			continue
		# The first tick from which her abrupt velocity holds at `a * speed` up to the turn: the
		# blend may start no earlier, or it would begin from a velocity it does not expect.
		var settled_from := n0
		while settled_from - 1 > previous_start and _settled(velocity[settled_from - 1], a * speed):
			settled_from -= 1
		var change := (b - a) * speed
		var shortfall := 0.0
		for j in range(n0 + 1, next_start + 1):
			shortfall += 1.0 - (velocity[j] - a * speed).dot(change) / change.length_squared()
		var centre := float(n0) - 0.5 + shortfall
		var earliest := maxf(0.5 * float(previous_start + n0), float(settled_from - 1))
		var latest := 0.5 * float(n0 + next_start)
		var width := mini(wanted_width, floori(2.0 * minf(centre - earliest, latest - centre)))
		# No faster than her velocity can follow: a blend that outran the acceleration would lag
		# behind its own fractions, and the sum the centre is placed by would no longer hold.
		var fastest := ceili(change.length() / (Tuning.ACCELERATION * dt) * (1.0 + 1e-6))
		if width < fastest:
			continue
		_turns.append({"from": a, "to": b, "centre": centre, "width": width})

## `starts[k]` is the first tick whose input is step `k`'s under the abrupt lookup, and
## `starts[_steps.size()]` the first tick after the script has ended. A step shorter than a tick
## starts where the next one does.
func _step_start_ticks() -> Array[int]:
	var total := 0.0
	for step: Dictionary in _steps:
		total += float(step.seconds)
	var starts: Array[int] = []
	var tick := 0
	var last := ceili(total * _ticks_per_second) + 2
	while starts.size() <= _steps.size() and tick <= last:
		var index := step_at(tick)
		while starts.size() <= index:
			starts.append(tick)
		tick += 1
	while starts.size() <= _steps.size():
		starts.append(last)
	return starts

## The stroller's velocity under the abrupt script from a standstill, `ticks + 1` entries long:
## `Stroller._physics_process()`'s own two lines for open ground, toward the pressed direction at
## `Tuning.ACCELERATION` a tick or toward rest at `Tuning.FRICTION` with nothing pressed.
func _replay_abrupt_velocity(ticks: int) -> Array[Vector2]:
	var dt := 1.0 / _ticks_per_second
	var velocity := Vector2.ZERO
	var replay: Array[Vector2] = [velocity]
	for tick in ticks:
		var index := step_at(tick)
		if index < _steps.size() and _steps[index].direction != Vector2.ZERO:
			var running := bool(_steps[index].get("run", false))
			var speed := Tuning.RUN_SPEED if running else Tuning.WALK_SPEED
			var direction: Vector2 = _steps[index].direction
			velocity = velocity.move_toward(direction * speed, Tuning.ACCELERATION * dt)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, Tuning.FRICTION * dt)
		replay.append(velocity)
	return replay

## Whether a replayed velocity has reached `target`, to well inside a thousandth of a pixel a second.
static func _settled(velocity: Vector2, target: Vector2) -> bool:
	return velocity.distance_to(target) < 0.001
