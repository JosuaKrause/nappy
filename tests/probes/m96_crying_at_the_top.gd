extends RefCounted
## Measurement probe for M96, "the day ends crying only after a push at the top"
## (docs/playtests/PLAYTEST-126.md, statement 1). Not a suite: it prints numbers rather than
## asserting a relationship, so it lives under tests/probes/, where the runner never discovers it,
## and runs only by name:
##
##     tools/test.sh probes/m96_crying_at_the_top.gd
##
## **The rig mirrors tests/test_meters.gd's own `FakeWorld` and `_one_bump_from`** — a real
## `CrowdAgent.startle()` or a real `EventInstance` feeds `FakeWorld.noise`, and a bare
## `Baby`/`Stroller` pair is driven by hand at a fixed step, since a headless probe has no crowd to
## steer a body through.
##
## **`Baby._update_excitement()` is called directly rather than `_physics_process()`.** That skips
## `_update_state()`, so the live `Tuning.EXCITEMENT_OVERFLOW_TO_CRY`/`_WINDOW` never freeze the
## rig mid-scenario the way reaching a real `CRYING` state would — which would otherwise stop a
## setting *looser* than the shipped one from ever being measured, since the shared rig would have
## already latched. What each setting below actually decides is read back afterwards, from
## `Baby.overflow_mass(window)`'s own history — see that function's doc for why a window no wider
## than the shipped `Tuning.EXCITEMENT_OVERFLOW_WINDOW` (3s, the widest swept here) is always a
## true subset of what is stored, so this sweeps settings without ever touching `Tuning`.

const STEP := 1.0 / 60.0

## `[mass, window]` pairs to sweep, the player's own starting point first — "10 over 3s", then two
## settings either side of it to see how the shape moves.
const SETTINGS := [[10.0, 3.0], [5.0, 2.0], [15.0, 3.0]]

## The distinct windows the settings above actually need, so each scenario is simulated once and
## every setting is read back from the same run rather than re-simulated per setting.
const WINDOWS := [3.0, 2.0]

## The loudest rows by `docs/COSTS.md`'s `walk_through_cost`, restricted to ones with no `speed` of
## their own — a stationary field is a straight line to walk through or a point to stand in;
## a pursuer's own notice and chase state belong to `M174Pass`'s rig, not this one.
const LOUDEST_STATIONARY_ROWS := ["night_raid", "curfew_announce", "abduction"]

class FakeWorld extends WorldContext:
	var noise := 0.0
	func sleepiness_multiplier(_world_position: Vector2) -> float:
		return 1.0
	func is_alley(_world_position: Vector2) -> bool:
		return false
	func total_excitement_at(_world_position: Vector2) -> float:
		return noise
	func excitement_sources_at(_world_position: Vector2) -> Array:
		return [[self, noise]] if noise > 0.0 else []
	func accumulate_landed(_points: float) -> void:
		pass

var _world: FakeWorld
var _stroller: Stroller
var _baby: Baby

func run(t) -> void:
	print("\n== M96: the day ends crying only after a push at the top ==")
	print("(mass, window) settings swept: %s" % [SETTINGS])

	print("\n-- one walker's bump --")
	for start in [89.0, 95.0, 100.0]:
		var peaks := _one_bump_from(t, start)
		_report("  bump from %.0f -> %.2f" % [start, peaks["excitement"]], peaks["peak"])

	print("\n-- two bumps in quick succession at the top --")
	var two := _two_bumps_at_the_top(t)
	_report("  two bumps, 0.3s apart, starting at the cap", two["peak"])

	for id in LOUDEST_STATIONARY_ROWS:
		print("\n-- %s (docs/COSTS.md) --" % id)
		var walked := _walk_past_row(t, id)
		_report("  walking past, starting at the cap", walked["peak"])
		var stood := _stand_in_row(t, id, 3.0)
		_report("  standing in it for 3s, starting at the cap", stood["peak"])

	var fall := _fall_from_the_top(t)
	print("\n-- the fall --")
	print("  a baby at 100 with nothing near falls under the nearly-crying cue (%.0f) in %.2fs"
			% [Tuning.EXCITEMENT_NEARLY_CRYING, fall])

	t.check(true, "zz_m96 crying-at-the-top probe ran")

## Prints one scenario's peak overflow mass against every setting in `SETTINGS`, and whether it
## would have ended the day under each.
func _report(label: String, peak: Dictionary) -> void:
	print(label)
	for setting in SETTINGS:
		var mass: float = setting[0]
		var window: float = setting[1]
		var reached: float = peak.get(window, 0.0)
		print("    %.0f over %.0fs: mass %.2f -> %s"
				% [mass, window, reached, "CRIES" if reached >= mass else "awake"])

# ------------------------------------------------------------------------ the rig ---

## `_world` and `_stroller` are added to `t`'s own tree — like `tests/test_meters.gd`'s `_build` —
## because `Baby._ready()` only resolves its own `_stroller`/`_world` fields once it is actually
## inside a tree, and `_update_excitement()` reads those fields rather than this script's locals.
## Without this, `decay_rate()`'s own guard (`if not _stroller or not _world: return 0.0`) would
## silently zero every decay figure this probe measures.
func _build(t) -> void:
	_world = FakeWorld.new()
	t.add_child(_world)
	_stroller = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_stroller.add_child(camera)
	t.add_child(_stroller)
	_stroller.set_physics_process(false)
	_baby = Baby.new()
	_baby.name = "Baby"
	_stroller.add_child(_baby)
	_baby.set_physics_process(false)

func _teardown() -> void:
	_stroller.free()
	_world.free()

## The peak of `Baby.overflow_mass(window)`, for every `window` in `WINDOWS`, seen at any step
## where she was actually sitting at the cap — the same gate `_update_state()` itself checks.
func _new_peaks() -> Dictionary:
	var peaks := {}
	for w in WINDOWS:
		peaks[w] = 0.0
	return peaks

func _track_peaks(peaks: Dictionary) -> void:
	if _baby.excitement < Tuning.METER_MAX:
		return
	for w in WINDOWS:
		peaks[w] = maxf(peaks[w], _baby.overflow_mass(w))

# -------------------------------------------------------------------- one contact ---

## One whole `CrowdAgent` bump — the same jolt `Crowd._bump()` fires on a genuine contact — landed
## while walking, starting from `at`.
func _one_bump_from(t, at: float) -> Dictionary:
	_build(t)
	var agent := CrowdAgent.new()
	agent.global_position = _stroller.global_position
	agent.startle(Tuning.BUMP_INTENSITY, Tuning.BUMP_DURATION,
			Tuning.BUMP_INNER_RADIUS, Tuning.BUMP_OUTER_RADIUS)
	_baby.excitement = at
	_stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	var peaks := _new_peaks()
	var jolt := Tuning.BUMP_DURATION
	while jolt > 0.0:
		agent._jolt = jolt
		_world.noise = agent.contribution_at(_stroller.global_position)
		_baby._update_excitement(STEP, _stroller.global_position, false)
		_track_peaks(peaks)
		jolt -= STEP
	var result := {"excitement": _baby.excitement, "peak": peaks}
	agent.free()
	_teardown()
	return result

## Two bumps back to back, both landed while she is already sitting at the cap — the player's own
## "one bump into one pedestrian" turning into two before the mass has had a chance to drain.
func _two_bumps_at_the_top(t) -> Dictionary:
	_build(t)
	_baby.excitement = Tuning.METER_MAX
	_stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	var peaks := _new_peaks()
	var gap := 0.3
	for bump_start in [0.0, Tuning.BUMP_DURATION + gap]:
		var agent := CrowdAgent.new()
		agent.global_position = _stroller.global_position
		agent.startle(Tuning.BUMP_INTENSITY, Tuning.BUMP_DURATION,
				Tuning.BUMP_INNER_RADIUS, Tuning.BUMP_OUTER_RADIUS)
		var jolt := Tuning.BUMP_DURATION
		while jolt > 0.0:
			agent._jolt = jolt
			_world.noise = agent.contribution_at(_stroller.global_position)
			_baby._update_excitement(STEP, _stroller.global_position, false)
			_track_peaks(peaks)
			jolt -= STEP
		agent.free()
		if bump_start == 0.0:
			# The gap between the two contacts: nothing near her, ordinary ground.
			_world.noise = 0.0
			var gap_steps := int(round(gap / STEP))
			for _i in gap_steps:
				_baby._update_excitement(STEP, _stroller.global_position, false)
				_track_peaks(peaks)
	var result := {"excitement": _baby.excitement, "peak": peaks}
	_teardown()
	return result

# ---------------------------------------------------------------------- the rows ---

## Walking a straight line past a stationary row's own field, lateral to its centre by one lane's
## width, starting already at the cap.
func _walk_past_row(t, id: String) -> Dictionary:
	var def := EventCatalogue.by_id(id)
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2.ZERO]))
	# Past the telegraph, the same warm-up `M174Pass._pass_net()` gives a row met on the map.
	var warm_steps := int(ceil((def.telegraph_time + 0.05) / STEP))
	for _i in warm_steps:
		instance._process(STEP)

	_build(t)
	_baby.excitement = Tuning.METER_MAX
	var lead := def.outer_radius + 40.0
	var lateral := 40.0
	_stroller.global_position = Vector2(-lead, lateral)
	_stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	var peaks := _new_peaks()
	var steps := int(ceil((lead * 2.0) / Tuning.WALK_SPEED / STEP))
	for _i in steps:
		_stroller.global_position.x += Tuning.WALK_SPEED * STEP
		instance._process(STEP)
		_world.noise = instance.contribution_at(_stroller.global_position)
		_baby._update_excitement(STEP, _stroller.global_position, false)
		_track_peaks(peaks)
	var result := {"excitement": _baby.excitement, "peak": peaks}
	instance.free()
	_teardown()
	return result

## Standing at the row's own centre for `seconds`, starting already at the cap. `obstructs_radius`
## is ignored on purpose: this rig places her by hand rather than colliding her, and what a solid
## body costs is a route decision the fairness contract already prices elsewhere — the question
## here is only what standing inside the field itself does to the mass.
func _stand_in_row(t, id: String, seconds: float) -> Dictionary:
	var def := EventCatalogue.by_id(id)
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2.ZERO]))
	var warm_steps := int(ceil((def.telegraph_time + 0.05) / STEP))
	for _i in warm_steps:
		instance._process(STEP)

	_build(t)
	_baby.excitement = Tuning.METER_MAX
	_stroller.global_position = Vector2.ZERO
	_stroller.velocity = Vector2.ZERO
	var peaks := _new_peaks()
	var steps := int(round(seconds / STEP))
	for _i in steps:
		instance._process(STEP)
		_world.noise = instance.contribution_at(_stroller.global_position)
		_baby._update_excitement(STEP, _stroller.global_position, false)
		_track_peaks(peaks)
	var result := {"excitement": _baby.excitement, "peak": peaks}
	instance.free()
	_teardown()
	return result

# ---------------------------------------------------------------------- the fall ---

## Seconds for a baby at 100 with nothing near, walking ordinary ground, to fall under
## `Tuning.EXCITEMENT_NEARLY_CRYING` — independent of the two new constants, since nothing is
## adding to the mass once the source is gone.
func _fall_from_the_top(t) -> float:
	_build(t)
	_baby.excitement = Tuning.METER_MAX
	_world.noise = 0.0
	_stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	var elapsed := 0.0
	while _baby.excitement >= Tuning.EXCITEMENT_NEARLY_CRYING:
		_baby._update_excitement(STEP, _stroller.global_position, false)
		elapsed += STEP
	_teardown()
	return elapsed
