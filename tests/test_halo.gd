@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `ExcitementHalo`: which live sources earn a place in the halo.
##
## Whether the result *reads* — the colour, the softness, whether a ring picks an entity's own
## silhouette out of a busy corner — is a screenshot's question and is out of this suite on
## purpose, the same line the **writing-tests** skill draws for every other cue: "not
## tested, checked by eye: layout, colour, readability." *(2026-09-07, the player, on this cue
## specifically: "proof for the UI is my playtest don't try to come up with a complicated rig to
## test it. that's wasted effort.")* That is why the size — a ring of offsets around each entity's
## own re-drawn body, in `EntityHalo` — has no test here: there is no arithmetic version of "does
## the rim hug the sprite," only a look.
##
## **What is left is what would rot silently.** The selection, which sources the halo lights: a day plans
## several hundred bodies and only a handful may ever earn a halo, or the cue marks everything and
## says nothing. And `landed()`'s sliding sum, because a sign error there is invisible until
## somebody stands next to a cyclist and a protest and cannot tell which one to run from. Neither
## test drives `accumulate_landed()` through `Baby._update_excitement()` — that attribution is a
## question about the meter, and this suite calls `accumulate_landed()` directly to hold `landed()`
## in isolation from it.
##
## **The halo and its rims run on real frames.** `ExcitementHalo` picks and every `EntityHalo` eases
## on its own `_process()`, which the engine calls; nothing here calls a frame function. A rim eases
## by the frame's own `delta`, so time in a check is the frame time the rims were handed, summed by a
## node of the suite's own that the engine processes beside them (`HaloRig.FrameClock`); it is not
## physics ticks, which no rim reads. What a rim was told is read through the rim a body hands its
## source (`ExcitementSource.rim`, wrapped in a `HaloRig.ToldRim`), what it draws through the
## renderer's own channel (`halo_colour`, the instance parameter the shader reads) and the engine's
## `draw` signal, which a headless run emits like any other.

const HaloRig = preload("res://tests/halo_rig.gd")
const STEP := 1.0 / 60.0
## The fewest frames the rim-budget walk takes, so it fills the budget at any frame length.
const WALK_FRAMES := 40

## The events' atlas page, held for the suite: an event in the tree is drawn on real frames, and the
## game hands every one it places its world's library (`EventInstance.atlas`).
var _atlas := AtlasLibrary.new()

func run(t) -> void:
	_atlas.acquire(&"events")
	await _test_a_weak_source_is_left_out(t)
	await _test_a_source_above_the_floor_is_selected(t)
	await _test_it_goes_to_zero_out_of_reach(t)
	await _test_the_cap_keeps_the_strongest(t)
	_test_landed_accumulates_and_decays(t)
	_test_net_landed_shares_decay_by_proportion(t)
	_test_net_landed_never_below_zero_and_floors_together(t)
	_test_net_landed_sums_to_the_bars_rise_while_climbing(t)
	await _test_process_reads_net_shared_by_baby_decay(t)
	await _test_the_rim_colour_ramp_ends(t)
	await _test_the_rim_brightness_emphasises_low_values(t)
	await _test_entity_halo_eases_toward_its_target(t)
	await _test_a_fade_leaving_a_hair_of_alpha_arrives_at_zero(t)
	_test_a_startled_car_clears_the_floor_at_its_horn_inner_radius(t)
	await _test_an_ordinary_walker_is_a_candidate(t)
	await _test_the_halo_takes_a_mixed_candidate_set(t)
	await _test_process_picks_the_same_sources_the_linear_scan_did(t)
	_test_event_instance_contribution_is_cached_per_frame_per_position(t)
	_test_finishing_outside_process_invalidates_the_contribution_cache(t)
	await _test_a_cat_dash_is_selected_and_lands(t)
	await _test_a_flock_is_selected_and_lands(t)
	await _test_a_flocks_rim_has_a_new_body_to_trace_every_frame(t)
	_test_the_rims_mirrored_copies_land_on_the_ring(t)
	await _test_an_event_holds_no_rim_until_it_is_picked(t)
	_test_the_lit_rims_always_fit_the_budget(t)
	await _test_live_rims_stay_within_what_the_web_can_read(t)
	await _test_a_retired_holder_gives_its_block_back_before_a_new_rim_is_built(t)
	await _test_a_stronger_new_pick_is_lit_before_a_weaker_one_that_began_waiting_earlier(t)
	await _test_a_repicked_fading_rim_is_lit_again_at_once(t)
	await _test_a_weak_pick_is_lit_within_one_fade_of_the_stronger_ones_stopping(t)
	await _test_a_holder_dropped_from_the_candidates_fades_and_gives_its_block_back(t)
	_atlas.release(&"events")

## A meter whose decay over the window is a number the test sets (`tests/halo_rig.gd`).
const DecayedBaby := HaloRig.DecayedBaby

## What `halo` draws: the colour and alpha its shader is handed (`halo_colour`), transparent before
## it has eased at all.
static func _drawn(halo: EntityHalo) -> Color:
	var drawn: Variant = halo.get_instance_shader_parameter("halo_colour")
	return drawn if drawn is Color else Color(1.0, 1.0, 1.0, 0.0)

## Whether `halo` draws exactly `alpha` now, which is where a glow told `alpha` stops easing: the
## fade-in has arrived.
static func _is_drawn_at(halo: EntityHalo, alpha: float) -> bool:
	return is_equal_approx(_drawn(halo).a, alpha)

## Lets real frames pass until `done` answers true or `seconds` of frame time have passed on
## `clock`, and answers whether `done` came true. Bounded in frames too, so a tree that stopped
## processing ends the wait rather than hanging the suite.
static func _frames_until(t, clock: HaloRig.FrameClock, done: Callable, seconds: float) -> bool:
	var from := clock.elapsed
	var frames := 0
	while not done.call():
		if clock.elapsed - from > seconds or frames > 20000:
			return false
		await t.get_tree().process_frame
		frames += 1
	return true

## Lets real frames pass until `seconds` of frame time have passed on `clock`.
static func _frames_for(t, clock: HaloRig.FrameClock, seconds: float) -> void:
	var from := clock.elapsed
	while clock.elapsed - from < seconds:
		await t.get_tree().process_frame

func _def(id: String, intensity: float, inner := 40.0, outer := 150.0) -> EventDef:
	var def := EventDef.new()
	def.id = id
	def.intensity = intensity
	def.inner_radius = inner
	def.outer_radius = outer
	# No telegraph damping to reason about: `is_telegraphing()` is `age < telegraph_time`, and
	# age starts at 0.0, so a zero telegraph is never true.
	def.telegraph_time = 0.0
	return def

## A manager over open ground and a run of its own, handed in as the escape's building is handed its
## world (`EventManager.setup_world()`), in the tree; the events it spawns stand in the world node
## its map is drawn in, a child of the manager. `_free_manager()` frees it.
func _manager(t) -> EventManager:
	var run := RunState.new()
	run.start_run(1)
	# Open ground, so no wall keeps a field from her (`ExcitementSource.contribution_at()`).
	var map := WorldMap.open_ground()
	var manager := EventManager.new()
	var holder := WorldContext.new()
	manager.add_child(holder)
	map.world = holder
	manager.setup_world(map, run)
	t.add_child(manager)
	return manager

func _free_manager(manager: EventManager) -> void:
	manager.free()

func _instance_at(def: EventDef, at: Vector2) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at)
	return instance

## A catalogue row's instance, live in the tree so `_ready()` actually runs — which is what
## builds a flock row's birds, and what a rim needs to be a child in the tree of, neither of
## which `_instance_at()` above gets, since it never calls `setup()` through a parent. Mirrors
## `tests/test_events.gd`'s own `_instance()` helper, kept local here rather than shared, because
## the two suites hold different halves of this class and neither should have to know the other's
## rig.
func _rig_instance(t: TestRunner, def: EventDef, at: Vector2,
		where: WhereSheIs = null) -> EventInstance:
	var instance := EventInstance.new()
	instance.atlas = _atlas
	instance.setup(def, at, PackedVector2Array(), Vector2.RIGHT, null, null, where)
	t.add_child(instance)
	instance.set_process(false)
	return instance

# ------------------------------------------------------------------- the floor ---

func _test_a_weak_source_is_left_out(t) -> void:
	var weak := _instance_at(_def("weak", 0.5), Vector2.ZERO)
	t.check((await HaloRig.lit_among(t, [weak.excitement], Vector2.ZERO)).is_empty(),
			"a source under CONTRIBUTION_FLOOR at her own position earns no halo")
	weak.free()

func _test_a_source_above_the_floor_is_selected(t) -> void:
	var strong := _instance_at(_def("strong", 10.0), Vector2.ZERO)
	var picked := await HaloRig.lit_among(t, [strong.excitement], Vector2.ZERO)
	t.check(picked.size() == 1 and picked[0] == strong.excitement,
			"a source clearing the floor at her own position is drawn")
	strong.free()

func _test_it_goes_to_zero_out_of_reach(t) -> void:
	var def := _def("reach", 10.0)
	var instance := _instance_at(def, Vector2.ZERO)
	var far := Vector2(def.outer_radius + 1.0, 0.0)
	t.check((await HaloRig.lit_among(t, [instance.excitement], far)).is_empty(),
			"a field she has walked out of contributes nothing, so nothing is drawn for it")
	instance.free()

# ------------------------------------------------------------------- the cap ---

func _test_the_cap_keeps_the_strongest(t) -> void:
	var instances: Array[EventInstance] = []
	var expected_ids: Array[String] = []
	var total := ExcitementHalo.MAX_SOURCES + 3
	for i in total:
		# Distinct, well-spread intensities at the same point (distance 0, so contribution_at
		# is exactly the intensity) — there is no ambiguity about which ones are strongest.
		var intensity := 5.0 * float(total - i)
		var def := _def("source_%d" % i, intensity)
		instances.append(_instance_at(def, Vector2.ZERO))
		if i < ExcitementHalo.MAX_SOURCES:
			expected_ids.append(def.id)

	var candidates: Array = []
	for instance in instances:
		candidates.append(instance.excitement)
	var picked := await HaloRig.lit_among(t, candidates, Vector2.ZERO)
	t.check(picked.size() == ExcitementHalo.MAX_SOURCES,
			"the cap is honoured even when far more sources clear the floor")

	var picked_ids: Array[String] = []
	for source in picked:
		picked_ids.append((source.body as EventInstance).def.id)
	picked_ids.sort()
	expected_ids.sort()
	t.check(picked_ids == expected_ids,
			"past the cap the weakest contributors are dropped, not the newest or the furthest")

	for instance in instances:
		instance.free()

# --------------------------------------------------------------- landed() ---

## Runs the same assertions against any duck-typed source — `EventInstance` and `CrowdAgent` both
## carry the same `accumulate_landed()`/`landed()` shape, so a bug in one and not the other is
## exactly what a single test could miss.
##
## **A true sum, not a decayed average.** *(2026-09-08, the player: "if a honking car caused 35
## excitement to the player that's the number that informs the color of the halo".)* A burst has
## to read as itself for the whole `WINDOW`, not fade from the instant it landed — the opposite of
## what an exponential moving average would give the same call.
##
## **Measured on the source's own simulation clock (`clock()`), not on wall time.** Neither rig is in
## a running tree here (`_instance_at()` never calls `setup()` through a parent, and a bare
## `CrowdAgent.new()` is never added), so nothing moves the clock but `advance`: the call the game
## moves each one's clock by — an event's tick (`EventInstance.step()`, which its manager runs) or a
## crowd body's (`CrowdExcitement.advance()`, which the agent's own tick calls) — standing in for
## that many seconds of simulated time elapsing.
func _check_accumulates_and_decays(t, source, advance: Callable, label: String) -> void:
	source.excitement.accumulate_landed(35.0)
	t.check(is_equal_approx(source.excitement.landed(), 35.0),
			"%s: a burst reads as itself, not decayed from the frame it landed" % label)

	# Wall time passing does nothing on its own -- landed() is measured against the source's own
	# clock, and nothing has advanced it, so asking again with no tick reads the same.
	t.check(is_equal_approx(source.excitement.landed(), 35.0),
			("%s: landed() still reads 35 with no tick, because the window is " +
					"measured on simulation time, not wall time") % label)

	# Advancing the source's own simulation clock past WINDOW is the same fact as WINDOW seconds
	# of simulated time elapsing, and does not need the test to sleep.
	advance.call(ExcitementSource.WINDOW + 0.1)
	t.check(is_equal_approx(source.excitement.landed(), 0.0),
			("%s: once WINDOW has fully elapsed on the simulation clock the burst reads as " +
					"~0, not merely faded") % label)

	# A second burst, only partially aged out, has to keep exactly what is still inside the
	# window and drop exactly what is not -- proving the sum is over entries, not a single scalar.
	# The 10 lands 0.6 of a window before the 20, and after another 0.6 it is past the window's
	# end while the 20 is still inside it.
	source.excitement.accumulate_landed(10.0)
	advance.call(ExcitementSource.WINDOW * 0.6)
	source.excitement.accumulate_landed(20.0)
	advance.call(ExcitementSource.WINDOW * 0.6)
	t.check(is_equal_approx(source.excitement.landed(), 20.0),
			"%s: an aged-out entry drops on its own; a fresh one beside it still counts" % label)

func _test_landed_accumulates_and_decays(t) -> void:
	var instance := _instance_at(_def("landed_event", 10.0), Vector2.ZERO)
	_check_accumulates_and_decays(t, instance, instance.step, "EventInstance")
	instance.free()

	var agent := CrowdAgent.new()
	_check_accumulates_and_decays(t, agent, agent.excitement.advance, "CrowdAgent")
	agent.free()

# ------------------------------------------------------------- net, not gross ---
# M174: overturns *(2026-09-08: "trace an increase in excitement back to its constituents")* only
# in what the traced number counts. `landed()` above is still the gross trace; `net_landed()` is
# what the halo actually reads now — see that function's own doc.

func _test_net_landed_shares_decay_by_proportion(t) -> void:
	t.check(is_equal_approx(ExcitementSource.net_landed(30.0, 40.0, 20.0), 15.0),
			"a source that landed 30 of a 40-point window keeps 30 less its 3/4 share of a " +
			"20-point decay (15)")
	t.check(is_equal_approx(ExcitementSource.net_landed(10.0, 40.0, 20.0), 5.0),
			"and a second source, 10 of the same 40, keeps 10 less its 1/4 share (5) -- the " +
			"decay is shared by proportion, not split evenly")
	t.check(is_equal_approx(ExcitementSource.net_landed(30.0, 40.0, 0.0), 30.0),
			"no decay taken in the window leaves gross and net the same")
	t.check(is_equal_approx(ExcitementSource.net_landed(5.0, 0.0, 10.0), 0.0),
			"nothing landed from anybody: nothing to share the decay against, so net is zero " +
			"rather than dividing by zero")

func _test_net_landed_never_below_zero_and_floors_together(t) -> void:
	# decay (50) exceeds total_landed (40): the bar is not climbing at all over the window, and
	# every source's share scales by the identical factor past one, so every source floors to
	# zero together -- never one source reading negative while another stays positive.
	t.check(is_equal_approx(ExcitementSource.net_landed(30.0, 40.0, 50.0), 0.0),
			"the larger source floors at zero rather than reading negative")
	t.check(is_equal_approx(ExcitementSource.net_landed(10.0, 40.0, 50.0), 0.0),
			"and the smaller one floors at zero too -- a source is red only while the bar is " +
			"climbing because of it, and here it is not climbing at all")

func _test_net_landed_sums_to_the_bars_rise_while_climbing(t) -> void:
	var landed_by_source := [12.0, 8.0, 5.0]
	var total := 25.0
	var decay := 9.0
	var summed_net := 0.0
	for landed in landed_by_source:
		summed_net += ExcitementSource.net_landed(landed, total, decay)
	t.close_to(summed_net, total - decay,
			"the halos together add up to the bar's own rise over the window (total landed less " +
			"decay) -- the sentence item (b) states as the target, held here as a sum rather than " +
			"a single source's own arithmetic", 0.001)

## Wires the same sharing through the halo's own frame, with a baby whose decay over the window is
## twenty points standing in for the meter's own decay (`DecayedBaby`: the halo asks it nothing
## else). Proof the regression this overturns would be caught: the strong source's own target
## colour is asserted to differ from what its *gross* landed value would have coloured it, not only
## to equal its net.
func _test_process_reads_net_shared_by_baby_decay(t) -> void:
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	var manager := _manager(t)
	var crowd := Crowd.new()
	t.add_child(crowd)
	var player := Node2D.new()
	t.add_child(player)
	var baby := DecayedBaby.new()
	baby.decay = 20.0
	var halo := ExcitementHalo.new()
	halo.setup(_sets(manager, crowd), player, baby)

	var strong := manager.spawn_extra(_def("strong_net", 40.0), Vector2.ZERO)
	strong.excitement.accumulate_landed(30.0)
	var strong_rim := HaloRig.told(strong)

	var weak := manager.spawn_extra(_def("weak_net", 40.0), Vector2.ZERO)
	weak.excitement.accumulate_landed(10.0)
	var weak_rim := HaloRig.told(weak)

	t.add_child(halo)
	var told := await _frames_until(t, clock,
			func() -> bool: return strong_rim.told > 0 and weak_rim.told > 0, 1.0)
	t.check(told, "the halo's own frame told both rims something")

	# What the halo tells a source that landed exactly the net, with no decay to share.
	var expected_strong: Color = (await _told_for(t, ExcitementSource.net_landed(30.0, 40.0, 20.0)))[1] # 15.0
	var expected_weak: Color = (await _told_for(t, ExcitementSource.net_landed(10.0, 40.0, 20.0)))[1] # 5.0
	var gross: Color = (await _told_for(t, 30.0))[1]
	t.check(strong_rim.colour.is_equal_approx(expected_strong),
			"the source that landed 30 of a 40-point window is coloured by its net 15, not its " +
			"gross 30")
	t.check(weak_rim.colour.is_equal_approx(expected_weak),
			"and the other, net 5 of a gross 10, reads paler than its own gross would have")
	t.check(not strong_rim.colour.is_equal_approx(gross),
			"proof the regression is caught: colouring by the gross 30 would be a visibly " +
			"different colour from the net's")

	halo.free()
	_free_manager(manager)
	crowd.free()
	player.free()
	baby.free()
	clock.free()

# ---------------------------------------------------------------- colour ---

func _test_the_rim_colour_ramp_ends(t) -> void:
	t.check((await _told_for(t, 0.0))[1].is_equal_approx(Palette.HALO_WEAK),
			"no landed excitement reads as the weak end of the ramp")
	var saturated := Tuning.EXPECTED_IMPACT_POINTS
	t.check((await _told_for(t, saturated))[1].is_equal_approx(Palette.HALO_STRONG),
			"landed excitement at the saturation point reads as the strong end")
	t.check((await _told_for(t, saturated * 10.0))[1].is_equal_approx(Palette.HALO_STRONG),
			"well past saturation stays at the strong end rather than overshooting it")
	var half: Color = (await _told_for(t, saturated * 0.5))[1]
	t.check(not half.is_equal_approx(Palette.HALO_WEAK) and not half.is_equal_approx(Palette.HALO_STRONG),
			"halfway to saturation reads as neither end of the ramp")
	t.check(half.is_equal_approx(Palette.HALO_MID),
			"and it is the chosen midpoint exactly, not a desaturated average of the two ends " +
			"(playtest 38: 'no real fade from yellow to red')")

## What the halo tells the rim of a source that has landed `net` points and shares no decay (strength,
## then colour): one source in the world, at her own position, on real frames.
func _told_for(t, net: float) -> Array:
	var instance := _instance_at(_def("net_probe", 10.0), Vector2.ZERO)
	instance.excitement.accumulate_landed(net)
	await HaloRig.lit_among(t, [instance.excitement], Vector2.ZERO)
	var rim := instance.excitement.rim as HaloRig.ToldRim
	var told := [rim.strength, rim.colour]
	instance.free()
	return told

# ---------------------------------------------------------------- brightness ---
# *(2026-09-08, the player, dropping the "how far away" read `alpha_for()` used to give:
# "the transparency shouldn't show distance since distance actually doesn't matter ... this frees
# up transparency for also encoding magnitude. transparency can be used to emphasize low values".)*
# The brightness a rim is told reads `landed()` -- the same number its colour reads -- on a curve that
# rises fast and saturates by `LOW_EMPHASIS_POINTS`, so transparency does the work at the low end
# that a straight line to `Tuning.EXPECTED_IMPACT_POINTS` would leave flat.

func _test_the_rim_brightness_emphasises_low_values(t) -> void:
	var floor_alpha := ExcitementHalo.MIN_MAGNITUDE * EntityHalo.MAX_ALPHA
	t.check(is_equal_approx((await _told_for(t, 0.0))[0], floor_alpha),
			"nothing landed yet reads at the floor, not at zero -- a picked source is never " +
			"invisible while it is still earning its first point")
	var one: float = (await _told_for(t, 1.0))[0]
	var five: float = (await _told_for(t, 5.0))[0]
	var fifteen: float = (await _told_for(t, 15.0))[0]
	var forty: float = (await _told_for(t, 40.0))[0]
	t.check(one > floor_alpha, "one point already reads above the floor -- faint but present")
	t.check(one < five and five < fifteen,
			"the curve rises fast through the low end, which is the whole point of it")
	t.check(is_equal_approx((await _told_for(t, ExcitementHalo.LOW_EMPHASIS_POINTS))[0],
			EntityHalo.MAX_ALPHA),
			"LOW_EMPHASIS_POINTS is where the curve saturates")
	t.check(is_equal_approx(forty, EntityHalo.MAX_ALPHA),
			"well past LOW_EMPHASIS_POINTS stays solid rather than overshooting -- colour, not " +
			"transparency, is what carries the difference between fifteen and forty")

# ------------------------------------------------------------------- easing ---
# *(2026-09-08, the player: "fade in and fade out smoothly using transparency ... all changes
# should transition (hue and transparency) instead of immediately showing the actual value".)*
# `EntityHalo` is the natural home for the eased state, since both `EventInstance` and `CrowdAgent`
# already own one -- see its class doc.

func _test_entity_halo_eases_toward_its_target(t) -> void:
	var traced := [0]
	var drawn_frames := [0]
	var halo := EntityHalo.new(func(_canvas: CanvasItem) -> void: traced[0] += 1,
			func() -> float: return 0.0)
	halo.draw.connect(func() -> void: drawn_frames[0] += 1)
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	t.add_child(halo)
	# The frame the two entered on passes first, so every frame after the glow is set is one both
	# were processed on.
	await t.get_tree().process_frame
	halo.set_glow(EntityHalo.MAX_ALPHA, Palette.HALO_STRONG)
	var from := clock.elapsed
	var on_the_line := true
	var part_way := false
	while clock.elapsed - from < EntityHalo.FADE_IN_SECONDS:
		await t.get_tree().process_frame
		var alpha := _drawn(halo).a
		var share := minf((clock.elapsed - from) / EntityHalo.FADE_IN_SECONDS, 1.0)
		on_the_line = on_the_line and absf(alpha - EntityHalo.MAX_ALPHA * share) < 0.001
		part_way = part_way or (alpha > 0.0 and alpha < EntityHalo.MAX_ALPHA)
	t.check(on_the_line and part_way,
			"on every frame of FADE_IN_SECONDS the rim draws the share of its target the frames so far "
			+ "have covered, part way up between -- never a jump from nothing to the target in one frame")
	t.close_to(_drawn(halo).a, EntityHalo.MAX_ALPHA,
			"a target held for the whole of FADE_IN_SECONDS is reached", 0.01)
	var colour := _drawn(halo)
	t.check(Color(colour.r, colour.g, colour.b).is_equal_approx(Palette.HALO_STRONG),
			"colour eases to its own target on the same clock as alpha, not left to jump on its own")
	var traced_before: int = traced[0]
	var frames_before := clock.frames
	await _frames_for(t, clock, 0.05)
	var frames := clock.frames - frames_before
	t.check(_is_drawn_at(halo, EntityHalo.MAX_ALPHA) and halo.is_showing() and frames > 0
			and traced[0] - traced_before == frames * EntityHalo.HALO_OFFSETS,
			"a rim holding a steady target is settled *and* drawn, and traced afresh every frame "
			+ "(%d copies over %d frames), because the body under a steady glow moves"
			% [traced[0] - traced_before, frames])

	halo.set_glow(0.0, Palette.HALO_WEAK)
	await _frames_for(t, clock, EntityHalo.FADE_OUT_SECONDS)
	t.close_to(_drawn(halo).a, 0.0,
			"told a target of zero and given the whole of FADE_OUT_SECONDS, the rim decays to zero " +
			"rather than being switched off", 0.01)
	t.check(halo.is_faded_out(),
			"is_faded_out() agrees once the fade is actually over, which is what lets CrowdAgent " +
			"free the halo without cutting a fade off mid-way")
	# The frame the fade reaches zero still redraws once, to clear the last rim off the screen.
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	var drawn_before: int = drawn_frames[0]
	traced_before = traced[0]
	await _frames_for(t, clock, 0.05)
	t.check(not halo.is_showing() and drawn_frames[0] == drawn_before and traced[0] == traced_before,
			"and a rim drawing nothing stops asking to be traced, so the per-frame trace is paid "
			+ "for by the handful of sources that are actually lit rather than by every body")
	halo.free()
	clock.free()

## A rim reads a hair of alpha above a target of zero as arrived, so a rim whose fade-out stopped a
## hair short -- which the frame lengths a fade is stepped by can leave -- would be left showing, and
## re-traced every frame, for good. The hair is reached with real frames and public calls: fade in,
## a target of 5e-6 (which `move_toward` lands on exactly), then zero in the same colour, so the
## rim reads arrived while it is still showing.
func _test_a_fade_leaving_a_hair_of_alpha_arrives_at_zero(t) -> void:
	var traced := [0]
	var halo := EntityHalo.new(func(_canvas: CanvasItem) -> void: traced[0] += 1,
			func() -> float: return 0.0)
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	t.add_child(halo)
	await t.get_tree().process_frame
	halo.set_glow(EntityHalo.MAX_ALPHA, Palette.HALO_STRONG)
	await _frames_for(t, clock, EntityHalo.FADE_IN_SECONDS + STEP)
	halo.set_glow(5e-6, Palette.HALO_STRONG)
	await _frames_for(t, clock, EntityHalo.FADE_OUT_SECONDS + STEP)
	halo.set_glow(0.0, Palette.HALO_STRONG)
	await _frames_for(t, clock, 0.2)
	var traced_before: int = traced[0]
	await _frames_for(t, clock, 0.05)
	t.check(not halo.is_showing() and traced[0] == traced_before,
			"a rim left a hair above zero reaches zero and stops being traced, not left showing")
	halo.free()
	clock.free()

# ------------------------------------------------------------ the crowd joins ---
# *(2026-09-08, the player: "a busy street is noisy because of cars and a busy sidewalk is noisy
# because of people ... that will allow us to attribute the source exactly".)* The whole crowd is
# a candidate now, not only a startled body -- CONTRIBUTION_FLOOR and MAX_SOURCES are what keep a
# busy pavement legible.

func _test_a_startled_car_clears_the_floor_at_its_horn_inner_radius(t) -> void:
	# `CrowdExcitement`'s field reads only global_position, kind and the jolt fields -- none of
	# which setup() touches -- so a bare .new() is enough, verified by reading the function rather
	# than assumed.
	var car := CrowdAgent.new()
	car.kind = CrowdAgent.Kind.CAR
	car.excitement.startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION,
			Tuning.CAR_HORN_INNER_RADIUS, Tuning.CAR_HORN_OUTER_RADIUS)
	var at_inner_radius := Vector2(Tuning.CAR_HORN_INNER_RADIUS, 0.0)
	t.check(car.excitement.contribution_at(at_inner_radius) > ExcitementHalo.CONTRIBUTION_FLOOR,
			"a startled car clears the halo's floor at its own horn's inner radius -- a caret " +
			"means a halo, and this still holds now that every car is a candidate")
	car.free()

func _test_an_ordinary_walker_is_a_candidate(t) -> void:
	# No startle at all -- just the ambient PEDESTRIAN_INTENSITY, which is what "the crowd is the
	# noise, and the noise is attributable" means in arithmetic.
	var walker := CrowdAgent.new()
	walker.kind = CrowdAgent.Kind.WALKER
	var at_inner_radius := Vector2(Tuning.PEDESTRIAN_INNER_RADIUS, 0.0)
	t.check(walker.excitement.contribution_at(at_inner_radius) > ExcitementHalo.CONTRIBUTION_FLOOR,
			"an ordinary, unstartled walker clears the floor at its own inner radius")
	var picked := await HaloRig.lit_among(t, [walker.excitement], at_inner_radius)
	t.check(picked.size() == 1 and picked[0] == walker.excitement,
			"and is therefore picked -- the whole crowd is a candidate, not only a caret-worthy body")
	walker.free()

func _test_the_halo_takes_a_mixed_candidate_set(t) -> void:
	var instance := _instance_at(_def("busker", 10.0), Vector2.ZERO)
	var car := CrowdAgent.new()
	car.kind = CrowdAgent.Kind.CAR
	car.position = Vector2(20.0, 0.0)
	car.excitement.startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION,
			Tuning.CAR_HORN_INNER_RADIUS, Tuning.CAR_HORN_OUTER_RADIUS)
	var picked := await HaloRig.lit_among(t, [instance.excitement, car.excitement], Vector2.ZERO)
	t.check(picked.size() == 2,
			"the halo takes an event's source and a crowd agent's in the same set -- " +
			"both are an ExcitementSource")
	instance.free()
	car.free()

# --------------------------------------------------------- the per-frame lookup ---
# `docs/TODO.md`, M124: `_process()` used to test `source in picked` -- a linear scan of an Array
# up to `MAX_SOURCES` long, run for every one of ~275 candidates. It now builds a `Dictionary`
# keyed by the picked objects themselves once, and tests membership in that instead. The set of
# who gets a nonzero target and who gets zero must come out exactly the same either way.

func _test_process_picks_the_same_sources_the_linear_scan_did(t) -> void:
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	var manager := _manager(t)
	var crowd := Crowd.new()
	t.add_child(crowd)
	var player := Node2D.new()
	t.add_child(player)
	var halo := ExcitementHalo.new()
	var baby := DecayedBaby.new()
	halo.setup(_sets(manager, crowd), player, baby)

	var strong := manager.spawn_extra(_def("strong_halo", 30.0), Vector2.ZERO)
	var strong_rim := HaloRig.told(strong)
	# Out of reach at her position (400px against a 150px outer radius), so it clears neither the
	# floor nor the halo's cap -- the case the old `in` scan and the new lookup both have
	# to answer "no" to.
	var weak := manager.spawn_extra(_def("weak_halo", 20.0), Vector2(400.0, 0.0))

	t.add_child(halo)
	await _frames_until(t, clock, func() -> bool: return strong_rim.told > 0, 1.0)

	t.check(strong_rim.strength > 0.0 and strong_rim.is_held(),
			"a source above the floor at her position is picked and told a nonzero target")
	t.check(weak.rim() == null and not weak.excitement.rim.is_held(),
			"a source out of reach is told zero, so it never builds a rim at all -- the same answer " +
			"the linear `in` scan gave before the picked set became a Dictionary lookup")

	# Freeing the manager frees `strong` and `weak` with the world node it holds, rather than freeing
	# them directly and leaving `manager` to tick a dangling reference in its list next frame.
	halo.free()
	_free_manager(manager)
	crowd.free()
	player.free()
	baby.free()
	clock.free()

# ------------------------------------------------------ contribution_at is cached ---
# `docs/TODO.md`, M124: `Baby._update_excitement()` (physics rate) and
# the halo's selection (frame rate) both ask every live event for its
# `contribution_at()` at essentially the same point, most frames -- so an event's source caches the
# plain query once per frame, the same `age`-keyed shape `caret_strength()` already uses. The
# cache must never answer for the *wrong* point or the *wrong* frame: two different positions in
# the same tick still have to answer independently, and a new frame must never hand back last
# frame's number for a source that has since moved.
#
# ``CrowdExcitement`'s field` deliberately has no such cache -- see that method's own doc for
# why (its position and jolt are written from outside its own `_process()`, by `Crowd`, so a
# `_clock`-keyed cache would miss a fresh bump or startle for the rest of the tick it landed on);
# `tests/crowd_rig.gd`'s `_test_walking_into_somebody_displaces_and_startles_them` is the check
# that would have caught it, and did, while this fix was still on `CrowdAgent`.

func _test_event_instance_contribution_is_cached_per_frame_per_position(t) -> void:
	var instance := _instance_at(_def("cached_event", 20.0, 40.0, 150.0), Vector2.ZERO)

	var near := instance.excitement.contribution_at(Vector2(10.0, 0.0))
	var far := instance.excitement.contribution_at(Vector2(140.0, 0.0))
	t.check(near > far,
			"two different points asked in the same tick both answer for their own position -- the " +
			"cache is keyed on where it was asked, not just on when")

	# A new frame (`age` advances the way `_process()` advances it) with the source moved away: the
	# old position must be recomputed, not answered from a stale cache built for last frame's spot.
	instance.age += 1.0
	instance.global_position = Vector2(5000.0, 5000.0)
	t.check(is_zero_approx(instance.excitement.contribution_at(Vector2(10.0, 0.0))),
			"a new frame recomputes rather than serving last frame's cached contribution")
	instance.free()

## The CI failure this guards against, reproduced directly: `EventManager.retire()` finishes an
## instance straight from outside, with no tick of the instance's own in between -- so `age` never
## moves, and a cache keyed only on `(age, world_position)` went on answering the pre-finish
## contribution for the rest of that tick. `_be_done()`'s `is_leaving = true` branch is the other
## half of the same guard `contribution_at()`'s early return reads, and gets the same check.
func _test_finishing_outside_process_invalidates_the_contribution_cache(t) -> void:
	var def := _def("finishable", 40.0)
	var instance := _instance_at(def, Vector2(400.0, 400.0))
	var nearby := Vector2(400.0, 300.0)
	t.check(instance.excitement.contribution_at(nearby) > 0.0,
			"a live source reaches a point inside its own field, which the cache now holds")

	var manager := EventManager.new()
	manager.retire(instance)
	t.check(instance.is_finished, "retired by its manager, the way the director retires one")
	t.close_to(instance.excitement.contribution_at(nearby), 0.0,
			"finishing outside _process() invalidates the cache rather than leaving the pre-" +
			"finish answer standing for the rest of the tick")
	instance.free()
	manager.free()

	# The other flag `contribution_at()`'s early return reads, flipped outside a tick the way a
	# completed task sends a figure off (`leave_for_a_completed_task()`, through `_be_done()`'s
	# leaving branch when a mobile row has somewhere to go).
	var leaving_def := _def("leaving", 40.0, 40.0, 400.0)
	leaving_def.departs_at = 10.0 # departure_speed() > 0, so _be_done() takes the leaving branch
	var leaving := _instance_at(leaving_def, Vector2.ZERO)
	t.check(leaving.excitement.contribution_at(Vector2(10.0, 0.0)) > 0.0,
			"a live row reaches a point inside its own field, which the cache now holds")
	leaving.leave_for_a_completed_task()
	t.check(leaving.is_leaving, "departure_speed > 0 takes the leaving branch, not straight to finished")
	t.close_to(leaving.excitement.contribution_at(Vector2(10.0, 0.0)), 0.0,
			"is_leaving flipping outside _process() invalidates the cache the same way finishing does")
	leaving.free()

# ------------------------------------------------------------ two rows that read as nothing ---
# *(Playtest 38, finding 1: "cats and birds have zero effect right now according to halos".)*
# Both cost her -- `cat_dash` 17/s over 30/120px for 1.8s, a flock +35 through the middle -- so
# the question was whether they were reaching the halo's selection and `landed()` at all, before
# touching a number. They were: a `cat_dash` and a `pigeon_flock` instance standing on her clear
# the floor and accumulate `landed()` through their whole telegraph and their whole burst, exactly
# like every other row. **What was actually thin was `alpha_for()`'s brightness, not this
# pipeline** -- see the brightness the halo tells a rim, which reads `landed()` rather than a
# fraction of a source's own peak and is what the player's later words in the same session, *(2026-
# 09-08: "the transparency shouldn't show distance since distance actually doesn't matter ... only
# the actual received amount counts")*, actually fixed. This rig stays as the regression: the two
# rows a player once reported as invisible still reach the meter.

## `cat_dash` is `AHEAD_OF_PLAYER` and `mobile`, but a rig instance built with no route never
## enters `EventRouteWalk.advance()` (`path.size() > 1` is false), so it holds still at `at` for its
## whole life -- exactly what "standing on her" needs to hold the distance at zero throughout.
func _test_a_cat_dash_is_selected_and_lands(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var cat := _rig_instance(t, def, Vector2.ZERO)

	# Mid-telegraph: `TELEGRAPH_INTENSITY_FRACTION` (0.15) damps 17/s to 2.55/s, still comfortably
	# above `CONTRIBUTION_FLOOR` (1.0) at zero distance.
	cat.step(def.telegraph_time * 0.5)
	t.check((await HaloRig.lit_among(t, [cat.excitement], Vector2.ZERO)).size() == 1,
			"a cat_dash instance standing on her clears the floor while still telegraphing")

	var elapsed := def.telegraph_time * 0.5
	while elapsed < def.telegraph_time + def.duration:
		cat.step(STEP)
		elapsed += STEP
		var contribution: float = cat.excitement.contribution_at(Vector2.ZERO)
		if contribution > 0.0:
			cat.excitement.accumulate_landed(contribution * STEP)
	t.check(cat.excitement.landed() > 10.0,
			"a cat_dash that stood over her whole telegraph and whole dash lands well above zero")
	cat.free()

## A flock's own `global_position` never moves (only its birds do), so "standing on her" is simply
## siting it at `Vector2.ZERO` and reading `contribution_at()` there for the whole burst.
func _test_a_flock_is_selected_and_lands(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var flock_where := WhereSheIs.nowhere()
	var flock := _rig_instance(t, def, Vector2.ZERO, flock_where)
	t.check(flock.flock.birds.size() == def.flock_size,
			"_ready() (live in the tree) built the flock, unlike a bare _instance_at()")
	# Standing in it: a flock waits on the pavement until she is inside `EventDef.notice`, and both
	# the telegraph and the burst below are measured from the moment it notices her — which is the
	# end of a frame, so the notice gets a frame of its own before the telegraph is stepped.
	flock_where.tell(Vector2.ZERO)
	flock.step(STEP)

	flock.step(def.telegraph_time * 0.5)
	t.check((await HaloRig.lit_among(t, [flock.excitement], Vector2.ZERO)).size() == 1,
			"a flock standing on her clears the floor while still on the ground telegraphing")

	var elapsed := def.telegraph_time * 0.5
	while elapsed < def.telegraph_time + def.duration:
		flock.step(STEP)
		elapsed += STEP
		var contribution: float = flock.excitement.contribution_at(Vector2.ZERO)
		if contribution > 0.0:
			flock.excitement.accumulate_landed(contribution * STEP)
	t.check(flock.excitement.landed() > 10.0,
			"a flock that stood over her whole telegraph and whole burst lands well above zero")
	flock.free()

## *(2026-09-12, the player: "the halo issue is not specific to cars you can see the same for when
## you walk close to birds you will get a freeze frame of their position as halo while they keep
## flying".)* A flock is the clearest case of a body that moves under a perfectly steady glow: the
## instance's own `global_position` never changes, so nothing about the owner looks like it is
## moving, while every bird is somewhere new every frame. `_draw()` is retained, so a rim traced
## once is that frame's birds until something asks for another trace — which `EntityHalo._process()`
## now does on every frame the rim is showing at all, easing or not.
##
## What is asserted is both halves: the bird positions `EventLook.draw_body()` traces really are
## different one frame on, and the rim over them, settled and lit -- the pair the old rule threw the
## frame away on -- is drawn again on every frame (the engine's `draw` signal, which a headless run
## emits like any other).
func _test_a_flocks_rim_has_a_new_body_to_trace_every_frame(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var flock_where := WhereSheIs.nowhere()
	var flock := _rig_instance(t, def, Vector2.ZERO, flock_where)
	# Standing in it, so it notices her and starts — the notice lands at the end of a frame, so it
	# gets one of its own — then past the telegraph, so the birds are up and flying rather than
	# pecking about on the ground.
	flock_where.tell(Vector2.ZERO)
	flock.step(STEP)
	flock.step(def.telegraph_time + 0.1)

	var before: Array[Vector2] = []
	for bird in flock.flock.birds:
		before.append(bird.at)
	flock.step(STEP)
	var moved := 0
	for i in flock.flock.birds.size():
		if not flock.flock.birds[i].at.is_equal_approx(before[i]):
			moved += 1
	t.check(flock.flock.birds.size() > 0 and moved == flock.flock.birds.size(),
			"every one of the %d birds is somewhere new one frame on, so the silhouette the rim "
			% flock.flock.birds.size()
			+ "traces is a different silhouette every frame")

	# And the rim over them is exactly the state that used to stop re-tracing.
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	flock.excitement.rim.set_strength(EntityHalo.MAX_ALPHA, Palette.HALO_STRONG)
	var halo: EntityHalo = flock.rim()
	await _frames_until(t, clock, func() -> bool:
		return _is_drawn_at(halo, EntityHalo.MAX_ALPHA), EntityHalo.FADE_IN_SECONDS + 1.0)
	var drawn := [0]
	halo.draw.connect(func() -> void: drawn[0] += 1)
	var frames_before := clock.frames
	await _frames_for(t, clock, 0.05)
	var frames := clock.frames - frames_before
	t.check(_is_drawn_at(halo, EntityHalo.MAX_ALPHA) and halo.is_showing() and frames > 0
			and drawn[0] == frames,
			"the flock's own rim is settled, lit and drawn again on every frame (%d of %d) while "
			% [drawn[0], frames] + "its birds keep moving, where it once held the freeze frame the "
			+ "player reported")
	flock.free()
	clock.free()

# ------------------------------------------------------- the mirrored half of the ring ---

## **A rim has to survive being drawn through a mirror**, and for half of every eight-view family it
## did not. `Sprites.draw_standing()`'s flipped branch is the only mirrored draw path in the game —
## the mother, the crowd's walkers and cars and every eight-view event family all reach it — and it
## sets an *absolute* canvas transform, because `draw_set_transform` replaces rather than composes
## and Godot exposes no way to read back what it replaced. So each of `EntityHalo`'s twelve ring
## offsets was thrown away on a mirrored view: twelve copies landed on one another at the body, and
## the three west-facing sectors of every family drew no rim at all.
##
## The composition is asserted where it is computed rather than on pixels: `EntityHalo.trace_offsets()` is the ring and `Sprites.mirrored_transform()` (given the canvas) is what the
## flipped branch actually sets. Both are pure, and between them they are the whole of where a
## mirrored copy lands.
##
## The assertions are the two things that were false: every copy lands somewhere of its own, and the
## mirrored ring covers the same ground as the unmirrored one. **A distinctness check alone would
## not hold it** — a ring that composed the offset the wrong way round is still twelve distinct
## points, just not around the body.
func _test_the_rims_mirrored_copies_land_on_the_ring(t) -> void:
	var bob := -2.5
	var anchor := Vector2(0.0, 26.0)
	var ring := EntityHalo.trace_offsets(bob)

	var canvas := Node2D.new()
	var other := Node2D.new()
	var landed := {}
	for offset in ring:
		Sprites.set_base_transform(canvas, Transform2D(0.0, offset))
		var mirrored := Sprites.mirrored_transform(canvas, anchor)
		# The flipped branch draws its rect in the mirrored frame, so where the sprite's own anchor
		# ends up is that frame's origin: the ring offset plus the anchor, and nothing else.
		t.check(mirrored.origin.is_equal_approx(offset + anchor),
				"a mirrored copy at ring offset %s lands at %s, the offset the unmirrored copy "
				% [offset, mirrored.origin] + "lands at too")
		t.check(is_equal_approx(mirrored.x.x, -1.0) and is_equal_approx(mirrored.y.y, 1.0),
				"and it is still mirrored on x only — composing the offset in may not undo the flip")
		landed[mirrored.origin.snapped(Vector2.ONE * 0.001)] = true
	t.check(Sprites.mirrored_transform(other, anchor).origin.is_equal_approx(anchor),
			"a canvas never told a transform mirrors about its own anchor, whatever another canvas was told")
	canvas.free()
	other.free()
	t.check(landed.size() == ring.size(),
			("all %d mirrored copies land on points of their own (%d distinct), which is what makes "
			+ "a rim rather than one silhouette re-drawn on itself") % [ring.size(), landed.size()])

# --------------------------------------------------------- what the web can read ---
# On the Compatibility renderer, only `EntityHalo.COMPATIBILITY_RIM_BLOCKS` canvas items can hold an
# `instance uniform` block the canvas shader declares, and in a browser one handed a block past
# that reads its colour as zero for as long as it lives -- see `EntityHalo`'s class doc. A headless
# run has no renderer to see a rim that draws nothing, so what is held here is the count that
# decides it, in the order the engine sees it: `RimProbe`.

## Counts rims the way the renderer counts blocks: from the moment a rim enters the tree (its
## material, set in `EntityHalo._init()`, has already queued it for a block) to the moment it leaves
## it (`EntityHalo.release()`, or the deletion of a node queued for deletion). Nothing queued for
## deletion is deleted inside a synchronous test, so a rim given back with `queue_free()` stays
## counted here as its block stays held in the engine while that frame's new rims take theirs —
## and, with no frame end to flush it, for the rest of the test too: stricter than the engine, and
## exactly the thing the budget must never lean on. `most` is the peak in the order things happened
## — rims held at a frame's start, less those freed on the spot, plus those built — which is what
## decides whether a new rim's block is one the shader can read. `given_back_unfaded` counts rims
## that left while still showing or still told to show: a fade cut short. `events` is every rim's
## coming and going in order, `["in", id]` or `["out", id]` by its instance id, which a test may
## add its own to.
class RimProbe:
	var held := 0
	var most := 0
	var given_back_unfaded := 0
	var events: Array = []
	var tree: SceneTree

	func _init(the_tree: SceneTree) -> void:
		tree = the_tree
		tree.node_added.connect(_on_node_added)

	## Stops counting new rims. Called once every rim it counted is gone, since each one's
	## `tree_exiting` still calls back into this probe.
	func stop() -> void:
		tree.node_added.disconnect(_on_node_added)

	func _on_node_added(node: Node) -> void:
		if node is EntityHalo:
			held += 1
			most = maxi(most, held)
			events.append(["in", node.get_instance_id()])
			node.tree_exiting.connect(_on_rim_exiting.bind(node))

	func _on_rim_exiting(rim: EntityHalo) -> void:
		held -= 1
		events.append(["out", rim.get_instance_id()])
		if not rim.is_faded_out():
			given_back_unfaded += 1

	## Where `[what, id]` stands in `events`, or -1.
	func when(what: String, id: int) -> int:
		for i in events.size():
			if events[i][0] == what and events[i][1] == id:
				return i
		return -1

## A live event holds no rim until `ExcitementHalo` picks it, and gives it back on the spot once
## faded. A rim built in `_ready()` for every live event is what filled the web's blocks at dawn
## and left the man shouting beside her doorstep dark however hard he was charging her.
func _test_an_event_holds_no_rim_until_it_is_picked(t) -> void:
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	var instance := _rig_instance(t, EventCatalogue.by_id("homeless_yeller"), Vector2.ZERO)
	var rim_of := instance.excitement.rim
	t.check(instance.rim() == null and not rim_of.is_held(),
			"a live event holds no rim before anything has picked it")
	rim_of.set_strength(EntityHalo.MAX_ALPHA, Palette.HALO_STRONG)
	t.check(instance.rim() != null and rim_of.is_held(),
			"its first nonzero glow builds the rim")
	var rim: EntityHalo = instance.rim()
	await _frames_until(t, clock, func() -> bool:
		return _is_drawn_at(rim, EntityHalo.MAX_ALPHA), EntityHalo.FADE_IN_SECONDS + 1.0)
	rim_of.set_strength(0.0, Palette.HALO_WEAK)
	t.check(instance.rim() == rim,
			"told zero, the rim stays to fade out rather than vanishing on the spot")
	await _frames_until(t, clock, rim.is_faded_out, EntityHalo.FADE_OUT_SECONDS + 1.0)
	rim_of.set_strength(0.0, Palette.HALO_WEAK)
	t.check(instance.rim() == null and not is_instance_valid(rim),
			"once the fade is over the rim is freed on the spot, not queued, so its block is back "
			+ "before anything later this frame builds a rim")
	instance.free()
	clock.free()

## The relationship the budget rests on: every source the halo can pick fits under the
## budget with room to spare, so the picked set alone never fills it and a wait for a block always
## ends with a fade; and the warm pass's own quad fits on top.
func _test_the_lit_rims_always_fit_the_budget(t) -> void:
	t.check(ExcitementHalo.MAX_SOURCES < EntityHalo.RIM_BUDGET,
			"MAX_SOURCES (%d) stays under RIM_BUDGET (%d)"
			% [ExcitementHalo.MAX_SOURCES, EntityHalo.RIM_BUDGET])
	t.check(EntityHalo.RIM_BUDGET < EntityHalo.COMPATIBILITY_RIM_BLOCKS,
			"and the budget leaves a block for the warm pass under the renderer's own ceiling")

## **However many events are live and however fast the picked set turns over, the rims held at any
## moment stay within `EntityHalo.RIM_BUDGET`, and no fade is cut short to keep them there.** Forty
## events in a row, a tile apart, and her stepping along them faster than a rim can fade, so each
## frame drops sources out of the picked set while their rims are still fading and the budget
## fills. Counted by `RimProbe`, in the order rims are built and freed, so a rim freed at the end
## of the frame still counts while the frame's new rims are built. A picked source that finds the
## budget full waits, and the walk checks that it waits only then.
func _test_live_rims_stay_within_what_the_web_can_read(t) -> void:
	var probe := RimProbe.new(t.get_tree())
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	var manager := _manager(t)
	var player := Node2D.new()
	t.add_child(player)
	var baby := DecayedBaby.new()
	var halo := ExcitementHalo.new()
	halo.setup(_sets(manager), player, baby)
	var count := 40
	var rims: Array[HaloRig.ToldRim] = []
	for i in count:
		rims.append(HaloRig.told(manager.spawn_extra(_def("row_%d" % i, 20.0), Vector2(32.0 * float(i), 0.0))))
	t.add_child(halo)

	var ever_lit := {}
	var waits := 0
	var waits_with_room := 0
	# The walk is laid out in frames, a jump a frame, so that however long the engine's frames are
	# each one turns the picked set over: laid out in time, a frame of 200 ms would jump a whole lap
	# of the row and land beside where the last one did, and no pick would ever wait for a block. The
	# walk runs for the rims' time (the fades are in frame time) and for enough frames to fill the
	# budget however long they are.
	var from := clock.elapsed
	var frames_from := clock.frames
	while clock.elapsed - from < EntityHalo.FADE_OUT_SECONDS * 3.0 or clock.frames - frames_from < WALK_FRAMES:
		var step := clock.frames - frames_from
		# 352px a frame along the row: past the picked set's whole reach every frame.
		player.global_position = Vector2(fmod(352.0 * float(step), 32.0 * float(count)), 0.0)
		var told_before: Array[int] = []
		var held_before: Array[bool] = []
		for rim in rims:
			told_before.append(rim.told)
			held_before.append(rim.is_held())
		await t.get_tree().process_frame
		# What the halo picked on that frame: a pick is told a nonzero strength once it holds a rim,
		# and told zero, with no rim held before or after, while it waits for a block (a rim not held
		# is told nothing unless it is picked).
		for i in count:
			var rim := rims[i]
			if rim.strength > 0.0:
				ever_lit[i] = true
			elif rim.told > told_before[i] and not held_before[i] and not rim.is_held():
				ever_lit[i] = true
				waits += 1
				if probe.held < EntityHalo.RIM_BUDGET:
					waits_with_room += 1
	t.check(ever_lit.size() > EntityHalo.RIM_BUDGET,
			"the walk lit %d different sources, more than the budget of %d, so the cap was tested"
			% [ever_lit.size(), EntityHalo.RIM_BUDGET])
	t.check(probe.most <= EntityHalo.RIM_BUDGET,
			"at most %d rims were held at any moment among %d live events, within the budget of %d"
			% [probe.most, count, EntityHalo.RIM_BUDGET])
	t.check(probe.given_back_unfaded == 0,
			"every rim given back had finished its fade: none was cut short (%d were)"
			% probe.given_back_unfaded)
	t.check(waits > 0,
			("the walk filled the budget, so a new pick had to wait for a block (%d picked frames "
			+ "without a rim)") % waits)
	t.check(waits_with_room == 0,
			"a picked source waited only while the budget was full (%d waits with room)"
			% waits_with_room)
	halo.free()
	_free_manager(manager)
	probe.stop()
	player.free()
	baby.free()
	clock.free()

## **A holder queued for deletion gives its block back before a new rim is built.** A source taken
## out during a frame leaves the candidates and is queued for deletion, but its rim — still fading —
## would keep its block until the end of the frame, after that frame's new rims have taken theirs.
## With the budget full and a new pick to light in the same frame, that is one block more than the
## budget. `ExcitementHalo` frees such a rim on the spot first: the body goes before the next frame
## is drawn either way, so nothing on screen changes any sooner. (The manager's own retirement,
## `EventStreaming.retire_finished()`, runs in the physics step, whose end deletes what it queued
## before the halo's pass; this is the net for a body queued between that and the pass.)
##
## Read in the order the rims and the body come and go (`RimProbe.events`): the retired event's rim
## leaves, the new pick's rim is built, and only then does the retired body leave the tree. A rim
## left to go with its body would leave beside it, after the new pick had found the budget full.
func _test_a_retired_holder_gives_its_block_back_before_a_new_rim_is_built(t) -> void:
	var probe := RimProbe.new(t.get_tree())
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	var manager := _manager(t)
	var player := Node2D.new()
	t.add_child(player)
	player.global_position = Vector2(-10000.0, 0.0)
	var baby := DecayedBaby.new()
	var halo := ExcitementHalo.new()
	halo.setup(_sets(manager), player, baby)
	var held: Array[EventInstance] = []
	for i in EntityHalo.RIM_BUDGET:
		var instance := manager.spawn_extra(_def("held_%d" % i, 20.0), Vector2(32.0 * float(i), 0.0))
		instance.excitement.rim.set_strength(EntityHalo.MAX_ALPHA, Palette.HALO_STRONG)
		held.append(instance)
	# Lit fully before the halo is in the tree, so each fade is a whole FADE_OUT_SECONDS.
	await _frames_until(t, clock, func() -> bool:
		for instance in held:
			if not _is_drawn_at(instance.rim(), EntityHalo.MAX_ALPHA):
				return false
		return true, EntityHalo.FADE_IN_SECONDS + 1.0)
	# Far from every one of them: all told zero, all still fading, all counted.
	t.add_child(halo)
	await t.get_tree().process_frame
	t.check(probe.held == EntityHalo.RIM_BUDGET,
			"the budget is full of fading rims (%d held)" % probe.held)

	# Taken out the way the manager takes a retired event out (`EventManager.retire()` finishes it,
	# `EventStreaming.retire_finished()` takes it out of the list and `take_out()`s it, which queues
	# it for deletion) -- here between the frame's physics step and the halo's pass, where nothing
	# deletes it before the pass.
	var retired: EventInstance = held[0]
	var retired_rim := retired.rim().get_instance_id()
	var retired_id := retired.get_instance_id()
	var retired_rim_of := retired.excitement.rim
	# Whether the retired event still held its rim as its body left the tree: a rim that goes with
	# its body has left the tree a moment before (children leave first) but is still held.
	var held_as_the_body_left := [true]
	retired.tree_exiting.connect(func() -> void:
		held_as_the_body_left[0] = retired_rim_of.is_held()
		probe.events.append(["body", retired_id]))
	manager.retire(retired)
	manager.streaming.retire_finished()
	var fresh := manager.spawn_extra(_def("fresh", 20.0), Vector2(5000.0, 0.0))
	player.global_position = fresh.global_position
	await _frames_until(t, clock, func() -> bool: return probe.when("body", retired_id) >= 0, 1.0)
	var fresh_rim := fresh.rim().get_instance_id() if fresh.rim() != null else 0
	t.check(not held_as_the_body_left[0] and probe.when("out", retired_rim) >= 0
			and probe.when("out", retired_rim) < probe.when("body", retired_id),
			"the retired event's rim is freed on the spot, ahead of its own deletion")
	t.check(fresh_rim != 0 and fresh.excitement.rim.is_held()
			and probe.when("out", retired_rim) < probe.when("in", fresh_rim)
			and probe.when("in", fresh_rim) < probe.when("body", retired_id),
			"the new pick builds its rim the same frame, in the block the retired one gave back")
	t.check(probe.most <= EntityHalo.RIM_BUDGET,
			"and at most %d rims were held at any moment, within the budget of %d"
			% [probe.most, EntityHalo.RIM_BUDGET])
	halo.free()
	_free_manager(manager)
	probe.stop()
	player.free()
	baby.free()
	clock.free()

## A body whose source is nothing but an `ExcitementSource`, for a picked set a test turns over by
## hand: `strength` is its excitement/s anywhere, and it holds its rim through a `SourceRim` as every
## body does — built on its first nonzero glow, freed on the spot once faded. It has landed enough
## that a lit rim reads at `EntityHalo.MAX_ALPHA`, so every fade out is a whole
## `EntityHalo.FADE_OUT_SECONDS`, the longest a rim can hold its block after it is dropped.
class ChurnSource extends Node2D:
	var strength := 0.0
	var excitement := Excitement.new(self)
	## Its rim, as every body holds one (`SourceRim`), wrapped so a test reads what it was told.
	var rim := HaloRig.ToldRim.new(SourceRim.new(_build_rim))

	func _init() -> void:
		excitement.rim = rim

	## Whether its rim is lit — told a nonzero target — rather than absent or fading.
	func is_lit() -> bool:
		return rim.is_lit()

	func _build_rim() -> EntityHalo:
		var halo := EntityHalo.new(_draw_nothing, _no_bob)
		add_child(halo)
		return halo

	func _draw_nothing(_canvas: CanvasItem) -> void:
		pass

	func _no_bob() -> float:
		return 0.0

	## `strength` everywhere, and always enough landed for a full-alpha rim.
	class Excitement extends ExcitementSource:
		## Overrides ExcitementSource._field.
		func _field(_at: Vector2) -> float:
			return (body as ChurnSource).strength

		## Overrides ExcitementSource.landed.
		func landed() -> float:
			return ExcitementHalo.LOW_EMPHASIS_POINTS

## The one set `ExcitementHalo.setup()` is handed, over a list of bodies a test edits.
class ChurnEvents extends Node:
	var list: Array = []
	var _set := ChurnSet.new(self)

	func sets() -> Array[ExcitementSources]:
		var sets: Array[ExcitementSources] = [_set]
		return sets

	class ChurnSet extends ExcitementSources:
		var _events: ChurnEvents

		func _init(events: ChurnEvents) -> void:
			_events = events

		## Overrides ExcitementSources.every_source.
		func every_source(into: Array) -> void:
			for body: ChurnSource in _events.list:
				into.append(body.excitement)

## The halo's sets for a manager's events and, where there is one, a crowd.
static func _sets(manager: EventManager, crowd: Crowd = null) -> Array[ExcitementSources]:
	var sets: Array[ExcitementSources] = [manager.sources]
	if crowd:
		sets.append(crowd.sources)
	return sets

## Fifteen sources each holding a rim, lit to staggered strengths in the upper half of the ramp and
## eased all the way there on real frames before any halo is in the tree: once a halo enters and
## tells each zero (none is picked yet), the budget is full of fading rims, one finishing every few
## frames from the shortest fade on, which is still over half of `EntityHalo.FADE_OUT_SECONDS`.
## Returns the sources.
func _fill_the_budget_with_fading_rims(t, events: ChurnEvents, clock: HaloRig.FrameClock) -> Array:
	var fading: Array = []
	var told: Array[float] = []
	for i in EntityHalo.RIM_BUDGET:
		var source := ChurnSource.new()
		events.add_child(source)
		events.list.append(source)
		told.append(EntityHalo.MAX_ALPHA * float(EntityHalo.RIM_BUDGET + i + 1)
				/ float(2 * EntityHalo.RIM_BUDGET))
		source.rim.set_strength(told[i], Palette.HALO_STRONG)
		fading.append(source)
	await _frames_until(t, clock, func() -> bool:
		for i in fading.size():
			if not _is_drawn_at(fading[i].rim.entity_halo(), told[i]):
				return false
		return true, EntityHalo.FADE_IN_SECONDS + 1.0)
	return fading

## **With the budget full, the strongest pick is lit first, not the one that began waiting first.**
## *(2026-10-04, the player: "if we have a limit with number of halos the selection should be by
## intensity so only the top k most intensive halos show at any one time".)* A weak source is picked
## into a budget full of fading rims and waits; `MAX_SOURCES - 1` stronger ones, all the picked set
## has room for beside it, are picked a few frames later. The rims finish a few at a time, and no block goes to the
## weaker pick while a stronger, newer one is still waiting: on no frame is the weak pick lit and a
## strong one not.
func _test_a_stronger_new_pick_is_lit_before_a_weaker_one_that_began_waiting_earlier(t) -> void:
	var probe := RimProbe.new(t.get_tree())
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	var events := ChurnEvents.new()
	t.add_child(events)
	var player := Node2D.new()
	t.add_child(player)
	var baby := DecayedBaby.new()
	var halo := ExcitementHalo.new()
	halo.setup(events.sets(), player, baby)
	var _fading := await _fill_the_budget_with_fading_rims(t, events, clock)
	var weak := ChurnSource.new()
	events.add_child(weak)
	events.list.append(weak)
	# As many stronger picks as fit beside the weak one in the picked set, so a frame that hands back
	# fewer blocks than that has a strong pick for every one of them.
	var strong: Array[ChurnSource] = []
	for i in ExcitementHalo.MAX_SOURCES - 1:
		var source := ChurnSource.new()
		events.add_child(source)
		events.list.append(source)
		strong.append(source)
	var strong_waiting := func() -> int:
		var waiting := 0
		for source in strong:
			if not source.rim.is_held():
				waiting += 1
		return waiting
	weak.strength = 3.0
	t.add_child(halo)
	var frames := 0
	var weak_waited := 0
	var weak_before_strong := 0
	var from := clock.elapsed
	while strong_waiting.call() > 0 and clock.elapsed - from < EntityHalo.FADE_OUT_SECONDS * 2.0:
		if frames == 2:
			for i in strong.size():
				strong[i].strength = 30.0 + float(i)
		await t.get_tree().process_frame
		if not weak.rim.is_held():
			weak_waited += 1
		elif strong_waiting.call() > 0:
			weak_before_strong += 1
		frames += 1
	# The rule is read on every frame rather than as the order within one: a frame long enough for
	# several fades to end hands back several blocks at once, and the weak pick is rightly lit on it
	# once every strong pick has one.
	t.check(strong_waiting.call() == 0 and weak_waited >= 2 and weak_before_strong == 0,
			("the %d strong picks, picked after the weak one had waited %d frames, were all lit no "
			+ "later than it (%d frames with the weak one lit and a strong one waiting)")
			% [strong.size(), weak_waited, weak_before_strong])
	t.check(probe.most <= EntityHalo.RIM_BUDGET,
			"at most %d rims were held at any moment, within the budget of %d"
			% [probe.most, EntityHalo.RIM_BUDGET])
	halo.free()
	events.free()
	probe.stop()
	player.free()
	baby.free()
	clock.free()

## **A pick that still holds a fading rim is lit at once, in the rim it has, with the budget full
## and a rimless pick waiting.** Relighting needs no new block, and it is the player's "only the top
## k most intensive show" that says the weaker newcomer does not get in ahead of it.
func _test_a_repicked_fading_rim_is_lit_again_at_once(t) -> void:
	var probe := RimProbe.new(t.get_tree())
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	var events := ChurnEvents.new()
	t.add_child(events)
	var player := Node2D.new()
	t.add_child(player)
	var baby := DecayedBaby.new()
	var halo := ExcitementHalo.new()
	halo.setup(events.sets(), player, baby)
	var fading := await _fill_the_budget_with_fading_rims(t, events, clock)
	var newcomer := ChurnSource.new()
	events.add_child(newcomer)
	events.list.append(newcomer)
	newcomer.strength = 40.0
	var again: ChurnSource = fading[EntityHalo.RIM_BUDGET - 1]
	var rim: EntityHalo = again.rim.entity_halo()
	again.strength = 5.0
	t.add_child(halo)
	await t.get_tree().process_frame
	t.check(again.is_lit() and again.rim.entity_halo() == rim,
			"the re-picked fading rim is lit again the same frame, in place")
	t.check(not newcomer.rim.is_held(),
			"while the stronger newcomer, with no rim, finds the budget full and waits")
	t.check(probe.most <= EntityHalo.RIM_BUDGET,
			"and at most %d rims were held, within the budget of %d"
			% [probe.most, EntityHalo.RIM_BUDGET])
	halo.free()
	events.free()
	probe.stop()
	player.free()
	baby.free()
	clock.free()

## **Under constant turnover a weak pick has no bound on its wait, and is lit within one fade once
## the stronger picks stop.** That is what "only the top k" asks: a weak source is shown only when
## nothing stronger wants its block, and no fade is cut short to make room, so while stronger picks
## keep arriving it is lit only on a frame a block is free and no stronger pick is waiting for it.
## Two turnovers, each keeping the budget full of rims for stronger picks:
##
## - **A new strong pick every three frames**, seven at a time: each strong source is picked for 21
##   frames and never again, so more strong sources want a rim than the budget holds and the
##   budget is full of their rims. A block a finished fade gives back goes to a rimless strong pick
##   if one is waiting. The weak pick joins late in the churn. Read on every frame: it is never
##   given a block on a frame a strong pick is left waiting for one. (A frame long enough for
##   several fades to end hands back more blocks than there are strong picks waiting, and then the
##   weak pick is rightly lit in one of them, so its state on the churn's last frame is not the rule.)
## - **The same fifteen strong sources in turn**, seven at a time, the turn moving on every three
##   frames: each is dropped for 24 frames, less than a fade, so it is picked again while its rim is
##   still fading and lit again in place, and all fifteen blocks stay held. No block ever comes back,
##   so the weak pick, which joins a fade's length into the churn, is still unlit when it stops.
##
## "Frames" in the turnovers are STEPs of frame time, so each is the same turnover however long the
## engine's frames are. The bound that holds is the other half: once every strong source stops being picked, the weak one is lit within
## `EntityHalo.FADE_OUT_SECONDS` and the frame or two it takes to see the fade end, whatever it was
## doing before. No fade is cut short and no block goes past the budget throughout.
func _test_a_weak_pick_is_lit_within_one_fade_of_the_stronger_ones_stopping(t) -> void:
	var fade_frames := int(ceil(EntityHalo.FADE_OUT_SECONDS / STEP))
	var fresh := func(pool: Array, step: int) -> void:
		for i in pool.size():
			var first := 3 * i
			pool[i].strength = 50.0 \
					if step >= first and step < first + 3 * (ExcitementHalo.MAX_SOURCES - 1) else 0.0
	var in_turn := func(pool: Array, step: int) -> void:
		for i in pool.size():
			var place := posmod(i - floori(step / 3.0), pool.size())
			pool[i].strength = 50.0 if place < ExcitementHalo.MAX_SOURCES - 1 else 0.0
	var churn_until := fade_frames * 3
	for turnover in [["a new strong pick every three frames", 80, fresh, churn_until - 12, false],
			["the same fifteen picked in turn", EntityHalo.RIM_BUDGET, in_turn, fade_frames, true]]:
		var name: String = turnover[0]
		var pool_size: int = turnover[1]
		var set_strengths: Callable = turnover[2]
		var weak_from: int = turnover[3]
		var no_block_comes_back: bool = turnover[4]
		var probe := RimProbe.new(t.get_tree())
		var clock := HaloRig.FrameClock.new()
		t.add_child(clock)
		var events := ChurnEvents.new()
		t.add_child(events)
		var player := Node2D.new()
		t.add_child(player)
		var baby := DecayedBaby.new()
		var halo := ExcitementHalo.new()
		halo.setup(events.sets(), player, baby)
		var pool: Array = []
		for i in pool_size:
			var source := ChurnSource.new()
			events.add_child(source)
			events.list.append(source)
			pool.append(source)
		var weak := ChurnSource.new()
		events.add_child(weak)
		events.list.append(weak)
		t.add_child(halo)

		# The turnover is laid out in STEPs of frame time rather than in frames, so it is the same
		# turnover however long the engine's frames are: `step` is how many STEPs the rims have
		# been handed.
		var from := clock.elapsed
		var stopped_at := -1.0
		var lit_after := -1.0
		var weak_was_held := false
		var lit_past_a_waiting_strong := 0
		var contended := 0
		var lit_at_the_churns_end := false
		while true:
			var step := floori((clock.elapsed - from) / STEP)
			if step < churn_until:
				set_strengths.call(pool, step)
			else:
				if stopped_at < 0.0:
					stopped_at = clock.elapsed
				for source in pool:
					source.strength = 0.0
			weak.strength = 3.0 if step >= weak_from else 0.0
			await t.get_tree().process_frame
			# Every strong source told a strength this frame was picked (`MAX_SOURCES - 1` at a
			# time), so one with no rim after the frame is a strong pick the halo left waiting.
			var strong_waiting := 0
			for source in pool:
				if source.strength > 0.0 and not source.rim.is_held():
					strong_waiting += 1
			var weak_held: bool = weak.rim.is_held()
			if weak_held and not weak_was_held and strong_waiting > 0:
				lit_past_a_waiting_strong += 1
			if stopped_at < 0.0:
				if strong_waiting > 0:
					contended += 1
				lit_at_the_churns_end = weak.is_lit()
			weak_was_held = weak_held
			if stopped_at >= 0.0 and weak.is_lit():
				lit_after = clock.elapsed - stopped_at
				break
			if stopped_at >= 0.0 and clock.elapsed - stopped_at > EntityHalo.FADE_OUT_SECONDS * 2.0:
				break
		if no_block_comes_back:
			t.check(not lit_at_the_churns_end,
					"%s: the weak source is still unlit on the last frame of the churn" % name)
		else:
			t.check(contended > 0 and lit_past_a_waiting_strong == 0,
					("%s: strong picks were left waiting for a block on %d frames of the churn, and "
					+ "the weak source was never given one on a frame a strong pick was left waiting "
					+ "(%d times)") % [name, contended, lit_past_a_waiting_strong])
		var bound := EntityHalo.FADE_OUT_SECONDS + 2.0 * clock.longest
		t.check(lit_after >= 0.0 and lit_after <= bound + 0.000001,
				"%s: the weak source is lit within one fade and two frames (%.3f s) of the stronger "
				% [name, bound] + "picks stopping (%.3f s)" % lit_after)
		t.check(probe.most <= EntityHalo.RIM_BUDGET,
				"%s: at most %d rims were held at any moment, within the budget of %d"
				% [name, probe.most, EntityHalo.RIM_BUDGET])
		t.check(probe.given_back_unfaded == 0,
				"%s: every rim given back had finished its fade, none cut short (%d were)"
				% [name, probe.given_back_unfaded])
		halo.free()
		events.free()
		probe.stop()
		player.free()
		baby.free()
		clock.free()

## **A holder that leaves the candidate set without being freed is told zero, still counted while it
## fades, and freed once the fade is over.** Every source that leaves today is queued for deletion
## as it goes (`EventManager`'s retirement, `EventManager.stand_down()`, `Crowd.clear()`), so this
## is the net for a later path that takes a source out of `instances()` and keeps it: without it,
## such a source is never told zero, so its rim stays lit on a thing that is no longer charging her,
## and holds a block nothing counts against the budget.
##
## **Counted is read where it shows, in the budget.** Fourteen other rims fade beside it, so with
## it the budget is full, and a new pick wants a block the whole time: a dropped holder the halo did
## not count would let that pick in at once, one rim past the budget.
func _test_a_holder_dropped_from_the_candidates_fades_and_gives_its_block_back(t) -> void:
	var probe := RimProbe.new(t.get_tree())
	var clock := HaloRig.FrameClock.new()
	t.add_child(clock)
	var events := ChurnEvents.new()
	t.add_child(events)
	var player := Node2D.new()
	t.add_child(player)
	var baby := DecayedBaby.new()
	var halo := ExcitementHalo.new()
	halo.setup(events.sets(), player, baby)
	# The holder dropped is one of the suite's own bodies, kept alive by the test: the game takes
	# no event out of its list without queueing its body for deletion (`EventInstance.take_out()`),
	# and the case is a holder that stays after it leaves the candidates.
	var instance := ChurnSource.new()
	instance.strength = 20.0
	events.add_child(instance)
	events.list.append(instance)
	var rim := instance.rim
	var others: Array = []
	for i in EntityHalo.RIM_BUDGET - 1:
		var source := ChurnSource.new()
		events.add_child(source)
		events.list.append(source)
		source.rim.set_strength(EntityHalo.MAX_ALPHA, Palette.HALO_STRONG)
		others.append(source)
	await _frames_until(t, clock, func() -> bool:
		for source: ChurnSource in others:
			if not _is_drawn_at(source.rim.entity_halo(), EntityHalo.MAX_ALPHA):
				return false
		return true, EntityHalo.FADE_IN_SECONDS + 1.0)
	t.add_child(halo)
	await _frames_until(t, clock, rim.is_lit, EntityHalo.FADE_IN_SECONDS + 1.0)
	# Its glow eases in from the frame it is lit: a whole fade-in later it has arrived.
	await _frames_for(t, clock, EntityHalo.FADE_IN_SECONDS + STEP)
	t.check(rim.is_lit(), "picked beside her, the event holds a lit rim")

	# Out of the list, but not freed and not queued for deletion; and a new pick that wants a block.
	var newcomer := ChurnSource.new()
	events.add_child(newcomer)
	events.list.append(newcomer)
	newcomer.strength = 30.0
	events.list.erase(instance)
	await t.get_tree().process_frame
	t.check(rim.is_held() and is_zero_approx(rim.strength),
			"no longer a candidate, it is told zero and its rim starts to fade")
	var counted_while_fading := true
	var from := clock.elapsed
	while rim.is_held() and clock.elapsed - from < EntityHalo.FADE_OUT_SECONDS * 2.0:
		var others_held := true
		for source: ChurnSource in others:
			others_held = others_held and source.rim.is_held()
		counted_while_fading = counted_while_fading \
				and not (others_held and newcomer.rim.is_held())
		await t.get_tree().process_frame
	var took := clock.elapsed - from
	t.check(counted_while_fading and probe.most <= EntityHalo.RIM_BUDGET,
			"every frame its rim was fading, it was counted against the budget: the new pick waited "
			+ "and at most %d rims were held (budget %d)" % [probe.most, EntityHalo.RIM_BUDGET])
	await t.get_tree().process_frame
	t.check(not rim.is_held() and newcomer.rim.is_held(),
			"once the fade was over its rim was freed and no longer counted: its block went to the "
			+ "new pick (%.3f s)" % took)
	t.check(took <= EntityHalo.FADE_OUT_SECONDS + 2.0 * clock.longest + 0.000001,
			"and that took one fade: %.3f s" % took)
	t.check(probe.given_back_unfaded == 0,
			"the rim was given back only after its fade (%d cut short)" % probe.given_back_unfaded)
	halo.free()
	events.free()
	probe.stop()
	player.free()
	baby.free()
	clock.free()
