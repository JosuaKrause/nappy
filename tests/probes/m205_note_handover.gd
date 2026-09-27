extends RefCounted
## Measurement probe for M205, "he keeps shouting for a bit": what day 6's note handover
## (`ResistanceSteps.by_index(2)`, the perform riding `homeless_yeller`) actually costs, from the
## instant she reaches him through the `ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS` he keeps
## shouting afterward. Not a suite -- prints numbers rather than asserting only relationships -- so
## it lives under `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m205_note_handover.gd
##
## **The rig.** A real `homeless_yeller` `EventInstance`, given a long straight path so `paces`
## moves it exactly as `EventScheduler` would. She starts `LEAD` px away and walks straight at its
## *current* position every tick, the way a player closing on a moving rider actually does --
## unlike `M174Pass`'s "the pass", which walks a fixed line past a row, this walks *up to* one and
## then past it, which is what handing over a note and walking on is. Averaged over
## `PHASE_SAMPLES` points in his own pulse, the same reason `M174Pass` does: starting at one instant
## of his beat prices whichever phase the sample happened to land on rather than the row.
##
## **The handover is instant; what follows it is not.** *(2026-09-26, the player, given a fork that
## proposed a dwell inside `inner_radius` before the note completes: "the player should stand for
## 2.5s? no way. the moment the player touches the inner circle it counts as delivered.")* The note
## still completes the instant she is within his `inner_radius` (45px, `ContactPoint.
## _physics_process()`) -- `_handover_net_averaged()` measures that alone, holding the old approach
## for comparison. *(2026-09-27, the player, asked whether he should keep shouting a while after the
## handover before he leaves, a fixed charge, or neither: "he keeps shouting for a bit.")*
## `ResistanceDirector` answers that by delaying `EventInstance.leave_for_a_completed_task()` by
## `NOTE_HANDOVER_LINGER_SECONDS` rather than calling it the instant the step completes, so his
## field keeps charging her exactly as any live `homeless_yeller`'s does for the whole delay --
## `_handover_then_linger_net_averaged()` measures the approach plus that delay, continuing to walk
## her past him in the direction she was already going (away, not back the way she came) the way an
## ordinary pass does.
##
## **The delay is chosen so the total lands near an ordinary pass, not so it exceeds it.** Walking
## away from `inner_radius` at `Tuning.WALK_SPEED` clears his `outer_radius` (210px) in a little
## over two seconds; past that point nothing more accrues, because `contribution_at()` answers zero
## outside it. `NOTE_HANDOVER_LINGER_SECONDS` (2.5s) sits past that clearing point with a margin, so
## the total plateaus at what it plateaus at rather than depending on catching the exact frame she
## clears the field -- measured at that plateau, `~11.1` awake and `~-3.2` asleep, against the
## `~11.1`/`~-3.2` an ordinary pass costs (`M174Pass.pass_net_averaged()` at 0px, the same
## simulation `docs/COSTS.md`'s "the pass" rows are generated from). Re-run rather than trust these
## numbers; the choice is open to overturn against a played day, not against this printout.

const STEP := 1.0 / 60.0
const PHASE_SAMPLES := 8
const LEAD := 500.0

func run(t) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	var reach_awake := _handover_net_averaged(def, false, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	var reach_asleep := _handover_net_averaged(def, false, Tuning.EXCITEMENT_DECAY_WALKING,
			Tuning.SLEEPING_SENSITIVITY)
	var inner_awake := _handover_net_averaged(def, true, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	var inner_asleep := _handover_net_averaged(def, true, Tuning.EXCITEMENT_DECAY_WALKING,
			Tuning.SLEEPING_SENSITIVITY)
	var linger := ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS
	var linger_awake := _handover_then_linger_net_averaged(def, Tuning.EXCITEMENT_DECAY_WALKING,
			1.0, linger)
	var linger_asleep := _handover_then_linger_net_averaged(def, Tuning.EXCITEMENT_DECAY_WALKING,
			Tuning.SLEEPING_SENSITIVITY, linger)
	# The ordinary full pass -- "what walking past him costs" -- is `M174Pass`'s own 0px figure,
	# the same simulation `docs/COSTS.md`'s "the pass — awake"/"the pass — asleep" rows are
	# generated from (re-run rather than trust a number quoted here).
	var pass_awake := M174Pass.pass_net_averaged(def, 0.0, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	var pass_asleep := M174Pass.pass_net_averaged(def, 0.0, Tuning.EXCITEMENT_DECAY_WALKING,
			Tuning.SLEEPING_SENSITIVITY)

	print("\n== homeless_yeller : the note handover ==")
	print("  %28s | %10s %10s" % ["", "awake", "asleep"])
	print("  %28s | %10.1f %10.1f" % ["at REACH", reach_awake, reach_asleep])
	print("  %28s | %10.1f %10.1f" % ["at inner_radius", inner_awake, inner_asleep])
	print("  %28s | %10.1f %10.1f" % ["+ %.1fs of him still shouting" % linger,
			linger_awake, linger_asleep])
	print("  %28s | %10.1f %10.1f" % ["ordinary pass", pass_awake, pass_asleep])

	t.check(reach_awake < pass_awake,
			("an instant handover at REACH lands under an ordinary pass (%.1f < %.1f) -- the bug " +
			"this row exists to pin") % [reach_awake, pass_awake])
	# inner_radius (45px) sits outside REACH (36px), so stopping there ends the approach a few
	# pixels earlier, not later -- this is not a bigger number than REACH's on its own; the linger
	# below is what actually closes the gap.
	t.check(inner_awake > 0.0,
			"the handover still lands something rather than nothing (%.1f)" % inner_awake)
	t.check(linger_awake > inner_awake,
			("him staying and shouting for %.1fs after the handover charges more than the instant " +
			"handover alone (%.1f > %.1f)") % [linger, linger_awake, inner_awake])
	t.check(absf(linger_awake - pass_awake) <= 0.15 * pass_awake,
			("the handover plus his %.1fs of shouting after lands near an ordinary pass (%.1f vs " +
			"%.1f)") % [linger, linger_awake, pass_awake])

func _handover_net_averaged(def: EventDef, at_inner_radius: bool, decay: float,
		sensitivity: float) -> float:
	var total := 0.0
	var phase_span: float = def.pulse_period if def.pulse_period > 0.0 else 1.0
	for i in PHASE_SAMPLES:
		total += _handover_net(def, at_inner_radius, decay, sensitivity,
				phase_span * float(i) / float(PHASE_SAMPLES))
	return total / PHASE_SAMPLES

func _handover_net(def: EventDef, at_inner_radius: bool, decay: float, sensitivity: float,
		phase_delay: float) -> float:
	var path := PackedVector2Array([Vector2(-4000.0, 0.0), Vector2(4000.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(def, path[0], path)

	# Past the telegraph, plus the requested phase offset — the same warm-up `M174Pass` gives every
	# row it measures, since a `MAP` row's telegraph is hours over by the time she reaches it.
	var warm_steps := int(ceil((def.telegraph_time + 0.05 + phase_delay) / STEP))
	for _i in warm_steps:
		instance._process(STEP)

	var her_pos: Vector2 = instance.global_position + Vector2(LEAD, 0.0)
	var incoming_sum := 0.0
	var decay_sum := 0.0
	# Long enough to close LEAD at WALK_SPEED with a margin -- overrunning costs nothing since both
	# sums stop the moment either stopping rule fires.
	var steps := int(ceil((LEAD / Tuning.WALK_SPEED) / STEP)) + 240
	for _i in steps:
		instance._process(STEP)
		var to_instance: Vector2 = instance.global_position - her_pos
		if to_instance.length() > 1.0:
			her_pos += to_instance.normalized() * Tuning.WALK_SPEED * STEP
		var distance := her_pos.distance_to(instance.global_position)
		if distance <= def.outer_radius:
			incoming_sum += instance.contribution_at(her_pos) * sensitivity * STEP
			decay_sum += decay * STEP
		var stop_radius := def.inner_radius if at_inner_radius else ContactPoint.REACH
		if distance <= stop_radius:
			break

	instance.free()
	return incoming_sum - decay_sum

## The approach exactly as `_handover_net()` walks it, continuing past `inner_radius` for
## `linger_seconds` more instead of stopping the sum there -- she keeps walking the direction she
## was already closing at, past him rather than back the way she came, while his field keeps
## charging her because he has not started leaving yet (`ResistanceDirector` delays
## `EventInstance.leave_for_a_completed_task()` by exactly this long). This is the total cost the
## shipped mechanism actually lands, not the approach alone.
func _handover_then_linger_net_averaged(def: EventDef, decay: float, sensitivity: float,
		linger_seconds: float) -> float:
	var total := 0.0
	var phase_span: float = def.pulse_period if def.pulse_period > 0.0 else 1.0
	for i in PHASE_SAMPLES:
		total += _handover_then_linger_net(def, decay, sensitivity,
				phase_span * float(i) / float(PHASE_SAMPLES), linger_seconds)
	return total / PHASE_SAMPLES

func _handover_then_linger_net(def: EventDef, decay: float, sensitivity: float,
		phase_delay: float, linger_seconds: float) -> float:
	var path := PackedVector2Array([Vector2(-4000.0, 0.0), Vector2(4000.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(def, path[0], path)

	var warm_steps := int(ceil((def.telegraph_time + 0.05 + phase_delay) / STEP))
	for _i in warm_steps:
		instance._process(STEP)

	var her_pos: Vector2 = instance.global_position + Vector2(LEAD, 0.0)
	var direction := Vector2(-1.0, 0.0)
	var incoming_sum := 0.0
	var decay_sum := 0.0
	var steps := int(ceil((LEAD / Tuning.WALK_SPEED) / STEP)) + 240
	var reached := false
	var linger_remaining := linger_seconds
	for _i in steps:
		instance._process(STEP)
		if not reached:
			var to_instance: Vector2 = instance.global_position - her_pos
			if to_instance.length() > 1.0:
				direction = to_instance.normalized()
		# He keeps shouting for the linger; she keeps walking the way she was already going --
		# past him, not back the way she came -- exactly like an ordinary pass.
		her_pos += direction * Tuning.WALK_SPEED * STEP
		var distance := her_pos.distance_to(instance.global_position)
		if distance <= def.outer_radius:
			incoming_sum += instance.contribution_at(her_pos) * sensitivity * STEP
			decay_sum += decay * STEP
		if not reached and distance <= def.inner_radius:
			reached = true
		if reached:
			linger_remaining -= STEP
			if linger_remaining <= 0.0:
				break

	instance.free()
	return incoming_sum - decay_sum
