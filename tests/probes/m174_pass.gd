class_name M174Pass
extends RefCounted
## Measurement probe for M174, item 3, "the pass": the net points a real pass lands, walking at
## `Tuning.WALK_SPEED` past `homeless_yeller`, `loose_dog` or `dog_walker` while it moves the way
## the game actually moves it — not the static walk-beside figure `m174_walk_beside.gd` measures.
## Not a suite: it prints numbers rather than asserting relationships, so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m174_pass.gd
##
## PLAYTEST-115: *"what matters for the dogs is walking past them. and it shouldn't be free. at
## the very least restore the net gain if not a bit more"* — and, of the man shouting: *"the same
## ... walking past (where both have different directions) is what matters. in my playthrough I
## walked next to him without effect which highlights an even worse drop in effect".*
##
## **The rig.** A real `EventInstance` (`EventCatalogue`'s own def, or a historical copy — see
## `_historical_def()`), given a long straight two-point path so `_advance_along_path()` — the
## same function the scheduler's placement drives — carries it at its own `speed`, pacing back
## and forth if `def.paces`. Never added to a tree: `contribution_at()`, `accumulate_landed()` and
## `_process()` all work on a bare `.setup()` instance, the same convention
## `tests/test_halo.gd`'s `_instance_at()` uses. Her line is parallel to the instance's own path,
## offset in Y by a fixed lateral distance, and her direction is fixed **opposite the instance's
## own heading at the moment she starts** — "different directions" made exact rather than left to
## whichever way a paced row happens to be walking when the sample starts.
##
## **The window.** She starts and ends `LEAD` px either side of the instance in the direction of
## travel — comfortably past any `outer_radius` in the catalogue plus the ground either body
## covers during the crossing — and every tick inside `outer_radius` of the instance's *live*
## position (not a fixed line: a paced or reversing row moves under her the whole time) adds its
## `contribution_at()` times `delta` times sleep sensitivity to the incoming side, and the given
## decay rate times `delta` to the other. Net is incoming minus decay, summed over the whole pass.
##
## **Averaged over the pulse.** `PHASE_SAMPLES` starting points, evenly spread over one
## `pulse_period`, each pre-ticks the instance that far (moving it for real, nobody watching) before
## her line is drawn — the same "walked up on him at a different moment of his breath" idea
## `m174_walk_beside.gd`'s closed-form 0.625 mean stands in for there; here the pulse interacts
## with real movement (how far he has paced, which way he is facing) so it is walked rather than
## integrated.

const STEP := 1.0 / 60.0
## Same offsets for every row, "0 where possible" plus the width a sidewalk band and a crossed
## street actually offer — 0/20/40 is one lane's width of give, 80/120 is stepping toward or past
## the far lane. None of the three rows obstruct (mobile is exempt from "solid things are solid"),
## so 0 is always geometrically walkable for all three.
const OFFSETS := [0.0, 20.0, 40.0, 80.0, 120.0]
const PHASE_SAMPLES := 8
## Well past the widest `outer_radius` in the catalogue (`car_accident`'s field aside, which is
## not one of these three) plus a margin for how far either body moves during the crossing.
const LEAD := 500.0

func run(t) -> void:
	_row("homeless_yeller")
	_row("loose_dog")
	_row("dog_walker")
	t.check(true, "zz_m174 pass probe ran")

func _row(id: String) -> void:
	var historical := historical_def(id)
	var current := EventCatalogue.by_id(id)
	print("\n== %s : the pass ==" % id)
	print("  %6s | %20s %20s | %20s %20s"
			% ["offset", "old 3.5/s (historical)", "today 6.0/s (historical)",
			"old 3.5/s (proposed)", "proposed 6.0/s (proposed)"])
	print("  %6s | %9s %9s | %9s %9s | %9s %9s | %9s %9s"
			% ["px", "awake", "asleep", "awake", "asleep", "awake", "asleep", "awake", "asleep"])
	for offset in OFFSETS:
		var old_hist_awake := pass_net_averaged(historical, offset, 3.5, 1.0)
		var old_hist_asleep := pass_net_averaged(historical, offset, 3.5, Tuning.SLEEPING_SENSITIVITY)
		var today_hist_awake := pass_net_averaged(historical, offset, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
		var today_hist_asleep := pass_net_averaged(historical, offset, Tuning.EXCITEMENT_DECAY_WALKING, Tuning.SLEEPING_SENSITIVITY)
		var old_now_awake := pass_net_averaged(current, offset, 3.5, 1.0)
		var old_now_asleep := pass_net_averaged(current, offset, 3.5, Tuning.SLEEPING_SENSITIVITY)
		var proposed_awake := pass_net_averaged(current, offset, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
		var proposed_asleep := pass_net_averaged(current, offset, Tuning.EXCITEMENT_DECAY_WALKING, Tuning.SLEEPING_SENSITIVITY)
		print("  %6.0f | %9.2f %9.2f | %9.2f %9.2f | %9.2f %9.2f | %9.2f %9.2f"
				% [offset, old_hist_awake, old_hist_asleep, today_hist_awake, today_hist_asleep,
				old_now_awake, old_now_asleep, proposed_awake, proposed_asleep])

## The three rows' fields as they stood before this milestone touched them — `homeless_yeller`
## with no core and his old 210px `outer_radius`, all three read at the decay they were tuned
## against (3.5) as well as today's (6.0), so "restore what the decay took" has a real baseline to
## restore to. **Every field this milestone might move is pinned here explicitly** rather than
## read off the live catalogue and selectively overridden — a duplicate that only overrides
## `intensity` silently inherits whatever `outer_radius` the catalogue holds *today*, which drifted
## the moment `homeless_yeller`'s own `outer_radius` changed and made this probe compare the old
## intensity against the new reach instead of the old one. `loose_dog` and `dog_walker` never
## changed, so their "historical" and "current" columns are the same def; kept as two lookups
## rather than one so a future change to either only has to touch the live catalogue. Static and
## public (`M174Pass.historical_def()`) so `tests/test_events.gd` shares this rather than keeping
## a second copy that could drift from it.
static func historical_def(id: String) -> EventDef:
	var d: EventDef = EventCatalogue.by_id(id).duplicate()
	if id == "homeless_yeller":
		d.intensity = 14.0
		d.inner_radius = 45.0
		d.outer_radius = 210.0
		d.core_intensity = 0.0
		d.core_radius = 0.0
	elif id == "dog_walker":
		d.intensity = 26.0
	elif id == "loose_dog":
		d.intensity = 32.0
	return d

## The pass, averaged over `PHASE_SAMPLES` points in the row's own pulse — see the class doc.
## Static and public so the relationship test in `tests/test_events.gd` runs the identical
## simulation this probe prints, rather than a second copy of it that could silently disagree.
static func pass_net_averaged(def: EventDef, offset: float, decay: float, sensitivity: float) -> float:
	var total := 0.0
	var phase_span: float = def.pulse_period if def.pulse_period > 0.0 else 1.0
	for i in PHASE_SAMPLES:
		var phase_delay := phase_span * float(i) / float(PHASE_SAMPLES)
		total += _pass_net(def, offset, decay, sensitivity, phase_delay)
	return total / PHASE_SAMPLES

static func _pass_net(def: EventDef, offset: float, decay: float, sensitivity: float,
		phase_delay: float) -> float:
	var path := PackedVector2Array([Vector2(-4000.0, 0.0), Vector2(4000.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(def, path[0], path)

	# Past the telegraph, plus the requested phase offset -- moved for real, nobody watching.
	var warm := def.telegraph_time + 0.05 + phase_delay
	var warm_steps := int(ceil(warm / STEP))
	for _i in warm_steps:
		instance._process(STEP)

	# "Different directions" made exact: she starts on the side the instance is currently heading
	# toward and walks straight at it, offset in Y by the lane she is giving it.
	var heading_x := signf(instance._heading.x)
	if is_zero_approx(heading_x):
		heading_x = 1.0
	var her_pos := instance.position + Vector2(heading_x * LEAD, offset)
	var her_velocity := Vector2(-heading_x * Tuning.WALK_SPEED, 0.0)

	var incoming_sum := 0.0
	var decay_sum := 0.0
	var steps := int(ceil((LEAD * 2.0 / Tuning.WALK_SPEED) / STEP)) + 120
	for _i in steps:
		instance._process(STEP)
		her_pos += her_velocity * STEP
		if her_pos.distance_to(instance.position) <= def.outer_radius:
			incoming_sum += instance.contribution_at(her_pos) * sensitivity * STEP
			decay_sum += decay * STEP

	instance.free()
	return incoming_sum - decay_sum
