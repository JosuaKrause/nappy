extends RefCounted
## Measurement probe for M205, "the note costs, and the ordinary day": what day 6's note handover
## (`ResistanceSteps.by_index(2)`, the perform riding `homeless_yeller`) actually costs, with
## `ResistanceSteps.Step.completes_at_inner_radius` on and off. Not a suite -- prints numbers
## rather than asserting only relationships -- so it lives under `tests/probes/`, where the runner
## never discovers it, and runs only by name:
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
## **Both stops are instant -- only the radius differs.** *(2026-09-26, the player, given a fork
## that proposed a dwell inside `inner_radius` first: "the player should stand for 2.5s? no way.
## the moment the player touches the inner circle it counts as delivered.")* **"REACH" stops the
## walk, and the sum, the instant `ContactPoint.REACH`** (36px) is reached -- the old code's own
## trigger, which sits inside his 45px `inner_radius`, so the old handover only ever charged the
## last few pixels of the approach. **"inner_radius" stops instead the instant she is within
## `inner_radius`** -- the fix `ContactPoint._physics_process()` actually ships.
##
## **Measured: this changes what the handover is tied to, not how much it costs.** REACH (36px)
## sits *inside* inner_radius (45px), so stopping at inner_radius actually ends the approach a
## few pixels earlier, not later -- `4.7` at REACH vs `4.1` at inner_radius, both awake, as of
## this tree (re-run rather than trust these). Both sit well under the `11.1` an ordinary pass
## costs. What the fix buys is not a bigger number: it is tying the handover to a fact about the
## row itself (his own full-strength field) instead of `REACH`, a fixed plumbing constant every
## task's contact shares regardless of what it rides on. The gap to an ordinary pass is left
## open, reported rather than re-litigated -- the player already answered the mechanism question
## this probe was built to measure.

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
	# The ordinary full pass -- "what walking past him costs" -- is `M174Pass`'s own 0px figure,
	# the same simulation `docs/COSTS.md`'s "the pass — awake"/"the pass — asleep" rows are
	# generated from (re-run rather than trust a number quoted here).
	var pass_awake := M174Pass.pass_net_averaged(def, 0.0, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	var pass_asleep := M174Pass.pass_net_averaged(def, 0.0, Tuning.EXCITEMENT_DECAY_WALKING,
			Tuning.SLEEPING_SENSITIVITY)

	print("\n== homeless_yeller : the note handover ==")
	print("  %14s | %10s %10s" % ["", "awake", "asleep"])
	print("  %14s | %10.1f %10.1f" % ["at REACH", reach_awake, reach_asleep])
	print("  %14s | %10.1f %10.1f" % ["at inner_radius", inner_awake, inner_asleep])
	print("  %14s | %10.1f %10.1f" % ["ordinary pass", pass_awake, pass_asleep])

	t.check(reach_awake < pass_awake,
			("an instant handover at REACH lands under an ordinary pass (%.1f < %.1f) -- the bug " +
			"this row exists to pin") % [reach_awake, pass_awake])
	# inner_radius (45px) sits outside REACH (36px), so stopping there ends the approach a few
	# pixels earlier, not later -- this is not a bigger number than REACH's, and is not asserted
	# to be one; see the class doc for what the fix actually buys instead.
	t.check(inner_awake > 0.0,
			"the handover still lands something rather than nothing (%.1f)" % inner_awake)

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
