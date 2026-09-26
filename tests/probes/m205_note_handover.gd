extends RefCounted
## Measurement probe for M205, "the note costs, and the ordinary day": what day 6's note handover
## (`ResistanceSteps.by_index(2)`, the perform riding `homeless_yeller`) actually costs, before and
## after `ResistanceSteps.Step.handover_dwell_seconds`. Not a suite -- prints numbers rather than
## asserting only relationships -- so it lives under `tests/probes/`, where the runner never
## discovers it, and runs only by name:
##
##     tools/test.sh probes/m205_note_handover.gd
##
## **The rig.** A real `homeless_yeller` `EventInstance`, given a long straight path so `paces`
## moves it exactly as `EventScheduler` would. She starts `LEAD` px away and walks straight at its
## *current* position every tick, the way a player closing on a moving rider actually does --
## unlike `M174Pass`'s "the pass", which walks a fixed line past a row, this walks *up to* one and
## stays, which is what handing over a note is. Averaged over `PHASE_SAMPLES` points in his own
## pulse, the same reason `M174Pass` does: starting at one instant of his beat prices whichever
## phase the sample happened to land on rather than the row.
##
## **"Before" (`dwelling = false`)** stops the walk, and the sum, the instant `ContactPoint.REACH`
## (36px) is reached -- the old code's own trigger, which sits inside his 45px `inner_radius`, so
## the old handover only ever charged the last few pixels of the approach. **"After" (`dwelling =
## true`)** keeps going past that point, now requiring a continuous `Tuning.
## NOTE_HANDOVER_DWELL_SECONDS` inside `inner_radius` before it stops -- the same condition
## `ContactPoint._physics_process()` checks, walked here rather than driven through a real node so
## many phases run in milliseconds rather than real seconds.

const STEP := 1.0 / 60.0
const PHASE_SAMPLES := 8
const LEAD := 500.0

func run(t) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	var before_awake := _handover_net_averaged(def, false, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	var before_asleep := _handover_net_averaged(def, false, Tuning.EXCITEMENT_DECAY_WALKING,
			Tuning.SLEEPING_SENSITIVITY)
	var after_awake := _handover_net_averaged(def, true, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	var after_asleep := _handover_net_averaged(def, true, Tuning.EXCITEMENT_DECAY_WALKING,
			Tuning.SLEEPING_SENSITIVITY)
	# The ordinary full pass -- "what walking past him costs" -- is `M174Pass`'s own 0px figure,
	# the same simulation `docs/COSTS.md`'s "the pass — awake"/"the pass — asleep" rows are
	# generated from (11.1 awake, -3.2 asleep as of this tree; re-run rather than trust the number).
	var pass_awake := M174Pass.pass_net_averaged(def, 0.0, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	var pass_asleep := M174Pass.pass_net_averaged(def, 0.0, Tuning.EXCITEMENT_DECAY_WALKING,
			Tuning.SLEEPING_SENSITIVITY)

	print("\n== homeless_yeller : the note handover ==")
	print("  %12s | %10s %10s" % ["", "awake", "asleep"])
	print("  %12s | %10.1f %10.1f" % ["before", before_awake, before_asleep])
	print("  %12s | %10.1f %10.1f" % ["after", after_awake, after_asleep])
	print("  %12s | %10.1f %10.1f" % ["ordinary pass", pass_awake, pass_asleep])

	t.check(before_awake < pass_awake * 0.5,
			"before the fix, an instant handover at REACH landed well under an ordinary pass (%.1f < %.1f)"
			% [before_awake, pass_awake * 0.5])
	t.check(after_awake >= pass_awake,
			"after the fix, the handover's own dwell costs at least an ordinary pass (%.1f >= %.1f)"
			% [after_awake, pass_awake])

func _handover_net_averaged(def: EventDef, dwelling: bool, decay: float,
		sensitivity: float) -> float:
	var total := 0.0
	var phase_span: float = def.pulse_period if def.pulse_period > 0.0 else 1.0
	for i in PHASE_SAMPLES:
		total += _handover_net(def, dwelling, decay, sensitivity,
				phase_span * float(i) / float(PHASE_SAMPLES))
	return total / PHASE_SAMPLES

func _handover_net(def: EventDef, dwelling: bool, decay: float, sensitivity: float,
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
	var dwell_seconds := 0.0
	# Long enough to close LEAD at WALK_SPEED and then dwell out the full requirement, with a
	# margin: overrunning costs nothing since both sums stop the moment either stopping rule fires.
	var steps := int(ceil((LEAD / Tuning.WALK_SPEED) / STEP)) \
			+ int(ceil(Tuning.NOTE_HANDOVER_DWELL_SECONDS / STEP)) + 240
	for _i in steps:
		instance._process(STEP)
		var to_instance: Vector2 = instance.global_position - her_pos
		if to_instance.length() > 1.0:
			her_pos += to_instance.normalized() * Tuning.WALK_SPEED * STEP
		var distance := her_pos.distance_to(instance.global_position)
		if distance <= def.outer_radius:
			incoming_sum += instance.contribution_at(her_pos) * sensitivity * STEP
			decay_sum += decay * STEP
		if not dwelling:
			if distance <= ContactPoint.REACH:
				break
			continue
		if distance <= def.inner_radius:
			dwell_seconds += STEP
			if dwell_seconds >= Tuning.NOTE_HANDOVER_DWELL_SECONDS:
				break
		else:
			dwell_seconds = 0.0

	instance.free()
	return incoming_sum - decay_sum
