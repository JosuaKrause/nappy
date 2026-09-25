extends RefCounted
## The emission model: the meter arithmetic a live `EventInstance` charges as she moves past it --
## telegraph damping, the pulse envelope, a two-part field's core against its outer radius, that
## adding a second part never moves the first -- plus the two states every instance owes regardless
## of kind: it is awake (or asleep) at the right moment, it finishes and leaves rather than
## vanishing mid-frame.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again" -- this half keeps
## `_instance()`/`_advance()`, the two helpers that drive a bare `EventInstance` through real
## seconds without a scheduler or a city underneath it.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_telegraph_damps_emission(t)
	_test_pulse_envelope(t)
	_test_the_leaf_blowers_core_is_in_the_meter(t)
	_test_no_other_rows_field_moved(t)
	_test_the_rows_she_walks_up_to_pass_positively_awake(t)
	_test_a_row_that_comes_at_her_is_done_telegraphing_when_it_arrives(t)
	_test_duration_and_finish(t)
	_test_an_event_leaves_rather_than_vanishing(t)


func _instance(t, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

func _test_telegraph_damps_emission(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var instance := _instance(t, def)

	t.check(instance.is_telegraphing(), "an event starts in its telegraph phase")
	t.close_to(instance.current_intensity(), def.intensity * Tuning.TELEGRAPH_INTENSITY_FRACTION,
			"a telegraphing event emits only a fraction of its intensity")
	t.close_to(instance.contribution_at(Vector2(1000.0, 0.0)), 0.0,
			"an event contributes nothing beyond its outer radius")

	_advance(instance, def.telegraph_time + 0.05)
	t.check(not instance.is_telegraphing(), "the telegraph phase ends after telegraph_time")
	t.close_to(instance.current_intensity(), def.intensity,
			"an active event emits its full intensity", 0.05)
	t.close_to(instance.contribution_at(Vector2(def.inner_radius * 0.5, 0.0)), def.intensity,
			"inside the inner radius the full intensity applies", 0.05)
	instance.free()

func _test_pulse_envelope(t) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	t.check(def.pulse_period > 0.0, "the yeller pulses rather than holding")
	var instance := _instance(t, def)
	_advance(instance, def.telegraph_time + 0.05)

	var lowest := INF
	var highest := -INF
	for i in int(def.pulse_period / STEP):
		instance._process(STEP)
		lowest = minf(lowest, instance.current_intensity())
		highest = maxf(highest, instance.current_intensity())

	t.check(highest > lowest * 2.0, "the pulse envelope has a real swing between beats")
	t.check(lowest > 0.0, "a pulsing event never goes completely silent")
	t.check(highest <= def.intensity + 0.001, "the pulse never exceeds the stated intensity")
	instance.free()

## **A two-part field is two parts in the meter, not only in the cost table.** The leaf blower is a
## wall close in and a busker further out (`EventDef.core_intensity` / `core_radius`), and the thing
## that makes that a *field* rather than a price is that an instance charges for it — walked past,
## against the row the outer half was copied from.
##
## Both are asked through a real `EventInstance`, at the peak each catalogues, so what is compared is
## the query the baby makes. 32px is inside the leaf blower's core and 100px is well outside it,
## where the two rows are the same numbers and have to answer the same rate.
func _test_the_leaf_blowers_core_is_in_the_meter(t) -> void:
	var leaf := EventCatalogue.by_id("leaf_blower")
	var busker := EventCatalogue.by_id("busker")
	t.check(leaf.core_intensity > 0.0 and leaf.core_radius > 0.0,
			"the leaf blower carries a core")
	t.check(busker.core_intensity == 0.0,
			"the busker is one field, which is what makes it the row to compare against")
	t.check(is_equal_approx(leaf.intensity, busker.intensity)
			and is_equal_approx(leaf.outer_radius, busker.outer_radius),
			"away from the core the leaf blower is the busker, number for number")

	var blower := _instance(t, leaf)
	var player := _instance(t, busker)
	var near := Vector2(32.0, 0.0)
	var far := Vector2(100.0, 0.0)
	t.check(near.length() < leaf.core_radius and far.length() > leaf.core_radius,
			"32px is inside the core and 100px is outside it")

	var blower_near := blower.contribution_at(near, leaf.intensity)
	var busker_near := player.contribution_at(near, busker.intensity)
	t.check(blower_near > busker_near + 1.0,
			"a leaf blower charges more than a busker inside its core (%.2f/s against %.2f/s)"
			% [blower_near, busker_near])
	t.close_to(blower_near, leaf.core_intensity,
			"and what it charges there is the core's own rate")
	t.close_to(blower.contribution_at(far, leaf.intensity),
			player.contribution_at(far, busker.intensity),
			"past the core the two rows charge the same rate")

	# The damping is the half a def-level check cannot see: a quarter of a beat has to be a quarter
	# of *both* parts, or a leaf blower between bursts is a full wall inside a quiet field. Stated
	# as the fraction the phase put on the row's own peak, so it holds wherever in the telegraph and
	# the pulse envelope this instance happens to be standing.
	t.check(blower.is_telegraphing(), "an instance starts in its telegraph")
	var fraction := blower.current_intensity() / leaf.intensity
	t.check(fraction < 1.0, "and is emitting less than its catalogued peak while it does")
	t.close_to(blower.contribution_at(near), leaf.core_intensity * fraction,
			"the phase damps the core by exactly the fraction it damps the field by")
	blower.free()
	player.free()

## **Adding a second part to the field may not have moved the first one**, and "may not" here means
## bit for bit rather than nearly: every cost in `docs/EVENTS.md`, every denial radius the placement
## rules invert, and every balance number anyone has measured was taken against
## `Tuning.falloff(d, intensity, inner_radius, outer_radius)` on a plain disc.
##
## So every uncored row — which is all of them but one — is walked out past its own rim in 16px
## steps and has to answer exactly that, at its catalogued peak and at a damped one. Exact equality
## on purpose: `is_equal_approx` would pass a change of a tenth, and the whole claim being made is
## that nothing moved at all.
func _test_no_other_rows_field_moved(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.core_intensity > 0.0:
			continue
		var damped := def.intensity * Tuning.TELEGRAPH_INTENSITY_FRACTION
		var d := 0.0
		while d <= def.outer_radius + 32.0:
			checked += 1
			t.check(def.emission_at_distance(d) == Tuning.falloff(d, def.intensity,
					def.inner_radius, def.outer_radius),
					"'%s' emits what a plain field emits at %.0fpx" % [def.id, d])
			t.check(def.emission_at_distance(d, damped) == Tuning.falloff(d, damped,
					def.inner_radius, def.outer_radius),
					"'%s' damps to what a plain field damps to at %.0fpx" % [def.id, d])
			d += 16.0
	t.check(checked > 0, "there were rows and distances to ask (%d)" % checked)

## M174 item 3: PLAYTEST-115 overturned the walk-beside target above (standing still at
## `inner_radius`) for **the pass** — she and the row moving different directions, at the fixed
## lateral offsets an ordinary sidewalk actually allows. *(PLAYTEST-115: "what matters for the
## dogs is walking past them. and it shouldn't be free"; "walking past ... is what matters. in my
## playthrough I walked next to him without effect".)* `M174Pass.pass_net_averaged()` —
## `tests/probes/m174_pass.gd`'s own simulation, shared rather than duplicated here — walks a real
## `EventInstance` past her, moving as the row actually moves, averaged over its own pulse.
##
## **A relationship, not a pinned value.** What must never quietly go false is that a pass costs
## something awake at an offset a sidewalk allows — not the exact figure, which the probe prints
## and `docs/EVENTS.md` records, and which moves as the catalogue is rebalanced. `dog_walker` does
## not fully restore its pre-M117 pass without crossing `Tuning.WALL_WORTH_OF_COST` — see that
## row's own docstring — so this asserts only what these rows actually clear, not a target the
## `WALL` line refuses one of them.
##
## **The two rows she walks up to.** Both are `MAP` placements made at dawn, so the rig starts
## their pass after the telegraph because that is when she meets them. A row `EventDirector` sites
## down her own line is met inside its telegraph instead and is a different claim, made where its
## own siting is decided rather than folded in here.
func _test_the_rows_she_walks_up_to_pass_positively_awake(t) -> void:
	for id in ["homeless_yeller", "dog_walker"]:
		var def := EventCatalogue.by_id(id)
		for offset in [0.0, 20.0, 40.0]:
			var net := M174Pass.pass_net_averaged(def, offset, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
			t.check(net > 0.0,
					"%s: a pass at %.0fpx of an ordinary sidewalk nets %.2f/s awake, above zero"
					% [id, offset, net])

## **A row that comes at her has to finish telegraphing before it arrives, or the telegraph is the
## whole encounter.** *(2026-09-20: "unleashed dog still has too little influence -- needs to be
## more intense"; "but keep things in relation to each other".)* `EventInstance.is_lethal_at()`
## refuses the whole telegraph and `_notice_damping()` holds the field at
## `Tuning.TELEGRAPH_INTENSITY_FRACTION` for it, so a row sited too close rides past her unable to
## do the one thing it is for — the kill for a `hard_fail` row, the noise for a loud one.
##
## Two claims, and the first is the general one. **The siting outlasts the telegraph by the row's
## own arrival distance**: nothing for a lethal row, where arriving is touching her, and
## `field_reach()` for anything else, where arriving is its field reaching her. Stated over
## `min_toward_player_lead()`, the closest the director could ever put it, so a heading that gives
## it more room cannot rescue a row that fails here.
##
## **And the loose dog stays above the dog walker**, which is the relation the player asked to be
## kept: a dog running loose at 132px/s costs more to be passed by than a leashed one costs to walk
## past. Both figures come off `M174Pass`, the same simulation `docs/COSTS.md` prints, so the two
## can never disagree about what a pass is.
func _test_a_row_that_comes_at_her_is_done_telegraphing_when_it_arrives(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.spawn_mode != EventDef.SpawnMode.TOWARD_PLAYER:
			continue
		checked += 1
		var closing := def.speed + Tuning.WALK_SPEED
		var arrival: float = 0.0 if def.hard_fail else def.field_reach()
		var gap_at_the_end := def.min_toward_player_lead() - def.telegraph_time * closing
		t.check(gap_at_the_end >= arrival,
				("'%s' is sited %.0fpx out and has closed to %.0fpx by the end of its %.1fs "
				+ "telegraph, which has to clear the %.0fpx at which it arrives")
				% [def.id, def.min_toward_player_lead(), gap_at_the_end, def.telegraph_time,
				arrival])
	t.check(checked > 0, "there were rows that come at her to ask (%d)" % checked)

	var dog := EventCatalogue.by_id("loose_dog")
	var walker := EventCatalogue.by_id("dog_walker")
	for offset in [0.0, 20.0, 40.0]:
		var loose := M174Pass.pass_net_averaged(dog, offset, Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
		var leashed := M174Pass.pass_net_averaged(walker, offset, Tuning.EXCITEMENT_DECAY_WALKING,
				1.0)
		t.check(loose > leashed,
				("a loose dog's pass at %.0fpx costs %.2f awake, above the %.2f a dog walker's "
				+ "does") % [offset, loose, leashed])

func _test_duration_and_finish(t) -> void:
	# An event that was a *place* is simply over. Nothing to leave, and nowhere to go.
	var def := EventCatalogue.by_id("abduction")
	t.check(def.departure_speed() <= 0.0, "the van that was parked there does not drive off")
	var instance := _instance(t, def)
	_advance(instance, def.telegraph_time + def.duration + 0.1)
	t.check(instance.is_finished, "an event with a duration finishes")
	t.close_to(instance.contribution_at(Vector2.ZERO), 0.0,
			"a finished event contributes nothing")
	instance.free()

## **Nothing vanishes while you are looking at it.** *(M35, playtest 08 findings 2 and 3: "running
## dog events etc — things that move disappear on screen; they should at least run offscreen before
## despawning", and "pigeons are also completely ineffective", which is the same sentence about a
## flock that hangs in the air and then is not there.)*
##
## Three separate claims, and the middle one is the one that could have gone wrong quietly: an event
## on its way out is **over**. It emits nothing, it cannot end the day, and it carries no cue — or a
## cat that has finished its run would trail its whole field behind it for as long as it took to get
## off screen, which is a worse bug than the one being fixed.
func _test_an_event_leaves_rather_than_vanishing(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	t.check(def.departure_speed() > 0.0, "a flock has somewhere to go")
	var instance := _instance(t, def, Vector2.ZERO)
	instance.player_at = Vector2(60.0, 0.0)
	_advance(instance, def.telegraph_time + def.duration + 0.1)
	t.check(not instance.is_finished, "a flock that is done is not deleted where it stands")
	t.check(instance.is_leaving, "it is leaving")
	t.close_to(instance.contribution_at(instance.player_at), 0.0,
			"and it stops emitting the moment it does")

	# Away from her, since a flock has no route to carry on along.
	_advance(instance, 0.5)
	t.check(instance.global_position.distance_to(instance.player_at) > 60.0,
			"it goes away from her rather than in any direction it likes")
	_advance(instance, Tuning.OUT_OF_SIGHT / def.departure_speed())
	t.check(instance.is_finished, "and it is gone once it is out of sight")
	instance.free()

	# The backstop, for a rig or a streamed-out day where there is nobody to be out of sight of. One
	# frame with her standing in it is what starts the flock's own clock — it waits until it notices
	# her — and she is gone again for the whole of the rest of it.
	var alone := _instance(t, def, Vector2.ZERO)
	alone.player_at = Vector2.ZERO
	alone._process(STEP)
	alone.player_at = Vector2.INF
	_advance(alone, def.telegraph_time + def.duration + EventInstance.LEAVING_GIVES_UP + 0.2)
	t.check(alone.is_finished, "with nobody watching it leaves on a timer rather than for ever")
	alone.free()
