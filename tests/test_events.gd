extends RefCounted
## The event system: the fairness contract, the emission model, and the scheduler's
## determinism and safety rules.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_catalogue_is_fair(t)
	_test_a_spread_body_fits_the_ground_it_stands_on(t)
	_test_a_kerbed_body_still_pins_the_frontage(t)
	_test_a_spread_rotates_with_the_street(t)
	_test_a_spread_never_lands_on_a_corner(t)
	_test_a_spread_cap_matches_what_it_obstructs(t)
	_test_telegraph_damps_emission(t)
	_test_pulse_envelope(t)
	_test_a_pursuer_leaves_room_to_answer(t)
	_test_the_answer_is_priced_by_how_soon_it_is_given(t)
	_test_a_pursuer_is_sited_where_it_can_be_seen(t)
	_test_a_pursuer_can_wait(t)
	_test_a_pursuer_stops_at_walls(t)
	_test_a_retried_day_is_the_same_day(t)
	_test_the_run_is_always_taught(t)
	_test_a_paced_event_walks_a_beat(t)
	_test_duration_and_finish(t)
	_test_an_event_leaves_rather_than_vanishing(t)
	_test_a_flock_is_birds_rather_than_one_bird_drawn_often(t)
	_test_mobile_follows_its_path(t)
	_test_a_crouching_event_holds_still_until_it_bolts(t)
	_test_the_director_puts_it_in_front_of_her(t)
	_test_a_rig_meets_the_three_things_that_arrive(t)
	_test_hard_fail_only_when_active(t)
	_test_scheduler_is_deterministic(t)
	_test_scheduler_respects_placement_and_caps(t)
	_test_one_shots_fire_once_per_run(t)
	_test_one_park_stays_usable(t)
	_test_calm_she_has_not_used_is_left_alone(t)
	_test_successors_resolve(t)
	_test_burning_building_is_never_scheduled(t)
	_test_fire_truck_is_a_day_three_one_shot(t)
	_test_along_street_paths_stay_in_bounds(t)
	_test_nothing_is_cheaper_to_walk_through_than_around(t)
	_test_running_is_the_answer_to_exactly_one_kind_of_thing(t)
	_test_nothing_chases_her_before_the_run_is_taught(t)
	_test_the_pavement_can_be_blocked_from_day_one(t)
	_test_a_day_has_enough_in_it_to_meet(t)
	_test_danger_arrives_before_act_three(t)
	_test_the_caps_can_spend_the_budget(t)
	_test_the_named_decisions_arrive(t)
	_test_two_of_a_kind_are_not_the_same_incident(t)
	_test_nothing_happens_inside_a_lethal_field(t)
	_test_a_pursuer_keeps_no_field_clear(t)
	_test_the_city_remembers_where_she_went(t)
	_test_everything_that_stands_still_is_solid(t)
	_test_a_lethal_thing_can_still_be_reached(t)
	_test_the_pram_is_the_size_the_rules_think_it_is(t)
	_test_a_parked_van_is_at_the_kerb(t)
	_test_a_lorry_has_a_wall_to_back_into(t)
	_test_nothing_stands_on_the_doorstep_street(t)
	_test_no_two_rows_draw_the_same_picture(t)
	_test_every_look_carries_its_own_silhouette(t)
	_test_the_day_is_placed_by_role(t)
	_test_a_conversation_locks_her_and_releases(t)
	_test_a_conversation_prices_by_the_babys_state(t)
	_test_a_conversation_only_starts_inside_detain_radius(t)
	_test_a_conversation_happens_once_per_instance(t)
	_test_the_take_begins_only_once_she_is_close(t)
	_test_a_completed_take_is_logged_exactly_once(t)
	_test_a_hunting_van_draws_no_victim(t)
	_test_the_obstruction_comes_down_once_it_stops_waiting(t)

# ------------------------------------------------------------------ fairness ---

## The contract from docs/EVENTS.md: a player who starts walking away the instant an event
## becomes visible clears its outer radius before it reaches full strength. A violation is
## a bug, not a difficulty setting, so the whole catalogue is checked.
func _test_catalogue_is_fair(t) -> void:
	var defs := EventCatalogue.all()
	t.check(not defs.is_empty(), "the catalogue is not empty")
	for def in defs:
		t.check(def.id != "", "every event has an id")
		t.check(def.validate(), "event '%s' gives the player time to walk clear" % def.id)
		if def.kind != GameEnums.EventKind.AMBIENT:
			t.check(def.telegraph_time >= def.minimum_telegraph(),
					"event '%s' telegraph %.2fs >= minimum %.2fs"
					% [def.id, def.telegraph_time, def.minimum_telegraph()])
		t.check(def.outer_radius > def.inner_radius,
				"event '%s' has a falloff band to fade across" % def.id)

	# Ambient events are exempt because they never "appear"; assert that is deliberate.
	var playground := EventCatalogue.by_id("playground")
	t.check(playground.kind == GameEnums.EventKind.AMBIENT,
			"the playground is ambient, so its zero telegraph is intended")

## Which looks draw a body at `max(11, obstructs_radius) * 2` wide, in `EventInstance._draw_spread`
## or one of its cousins (`_draw_cafe`, `_draw_protest`, `_draw_firefight`) — as opposed to a fixed
## sprite whose own pixel size has nothing to do with `obstructs_radius`, which is every other
## row's collision radius alone.
const _SPREAD_LOOKS: Array[EventDef.Look] = [
	EventDef.Look.ROADWORKS, EventDef.Look.STALL, EventDef.Look.CHECKPOINT,
	EventDef.Look.BARRICADE, EventDef.Look.BURNT_SHELL, EventDef.Look.CAFE,
	EventDef.Look.PROTEST, EventDef.Look.FIREFIGHT,
]

## A `SIDEWALK` tile is one lane of a two-lane pavement, `SIDEWALK_WIDTH * TILE_SIZE` (64px) wide
## in total, and it is one piece of walkable ground rather than two lanes a body has to fit inside
## one of. `EventInstance._centred_on_the_pavement_band()` moves a stationary, unpinned
## (`pavement_side == ANY`) body from the lane tile `EventScheduler` chose to the middle of that
## whole band, so this is half of the *band*, not half of a *lane*.
const _SIDEWALK_SPREAD_CLEARANCE := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 0.5
## A `ROAD` or `CROSSING` tile sits much further from a building line: `(SIDEWALK_WIDTH + 0.5) *
## TILE_SIZE`, worst case, because it is one of the carriageway tiles in the middle of the
## corridor rather than at either edge of it — which is why a street-spanning row like
## `checkpoint` is allowed a far wider body than a sidewalk obstruction is. Nothing re-centres a
## `ROAD`/`CROSSING` body — `CityMap.pavement_inward()` answers zero for either, by design, so
## `_centred_on_the_pavement_band()` leaves them exactly where the scheduler put them.
const _CARRIAGEWAY_SPREAD_CLEARANCE := (Tuning.SIDEWALK_WIDTH + 0.5) * Tuning.TILE_SIZE

## **A body on a pavement has to fit on the pavement — the whole of it, not the lane it happened to
## be planned on.** `_draw_spread` and its cousins draw a body at exactly the width `obstructs_radius`
## says, and `EventInstance.setup()` centres a stationary, unpinned body on the pavement band before
## either the drawing or `_build_obstruction()`'s collision circle ever reads its position — so the
## width is a promise about where she can walk and the promise is kept against the band a `SIDEWALK`
## placement actually offers, not against whichever of its two lanes the scheduler rolled. `SQUARE`,
## `PARK` and `ALLEY` are wide open and carry no bound here; a tile type with no clearance defined is
## skipped rather than treated as a failure.
##
## **Blind spot, not a hole this test can close:** `burnt_shell` and `barricade` carry no
## `def.placement` of their own — both are scars/spawns sited wherever `burning_building` /
## `military_convoy` stopped rather than placed by `def.placement` — so the loop below never sees
## them and a future regression on either row's `obstructs_radius` would pass silently. Checked by
## hand instead: both actually land on `ROAD` (their spawning row's own placement), and 36px /
## 62px both sit inside `_CARRIAGEWAY_SPREAD_CLEARANCE`.
func _test_a_spread_body_fits_the_ground_it_stands_on(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if not _SPREAD_LOOKS.has(def.look) or def.placement.is_empty():
			continue
		var half := maxf(11.0, def.obstructs_radius)
		for tile_type in def.placement:
			var clearance := INF
			if tile_type == GameEnums.TileType.SIDEWALK:
				clearance = _SIDEWALK_SPREAD_CLEARANCE
			elif tile_type == GameEnums.TileType.ROAD or tile_type == GameEnums.TileType.CROSSING:
				clearance = _CARRIAGEWAY_SPREAD_CLEARANCE
			if clearance == INF:
				continue
			checked += 1
			t.check(half <= clearance,
					"'%s' draws %.0fpx wide, which fits the %.0fpx that a %d-type tile clears"
					% [def.id, half * 2.0, clearance * 2.0, tile_type])
	t.check(checked >= 6, "and the rule covers the catalogue's spread rows (%d checks)" % checked)

## **The kerb exception must not silently regress.** `delivery_van` and `ice_cream_van` are
## `pavement_side == AT_THE_KERB` on purpose — `EventCatalogue`'s own docstring is "a parked van
## belongs at the kerb" — so `_centred_on_the_pavement_band()` must leave them flush against it
## rather than re-centring them onto the pavement band the way `construction` is. A kerb-parked
## `VEHICLE_BODY` (44px across) still has to leave a gap to the frontage narrower than the pram, or
## the row stops being an obstacle: `docs/HANDOFF.md`'s own reading of that placement is that the
## gap "is intended and is also the exact shape of 'no line to walk.'"
func _test_a_kerbed_body_still_pins_the_frontage(t) -> void:
	var kerb_edge := Tuning.TILE_SIZE * 0.5
	var band := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE
	var frontage_gap := (band - kerb_edge) - EventCatalogue.VEHICLE_BODY
	t.check(frontage_gap < Tuning.PLAYER_BODY_RADIUS * 2.0,
			"a %.0fpx VEHICLE_BODY at the kerb leaves %.0fpx to the frontage, narrower than the "
			% [EventCatalogue.VEHICLE_BODY, frontage_gap]
			+ "%.0fpx pram" % (Tuning.PLAYER_BODY_RADIUS * 2.0))

	var map := CityMap.new()
	# The kerb lane of a north-south street's near-start pavement pair — offset `SIDEWALK_WIDTH - 1`
	# is the tile whose road-side neighbour is the carriageway.
	var kerb_tile := Vector2i(Tuning.SIDEWALK_WIDTH - 1, Tuning.STREET_WIDTH + 3)
	map.set_tile(kerb_tile, GameEnums.TileType.SIDEWALK)

	var van := EventCatalogue.by_id("delivery_van")
	var parked := EventInstance.new()
	parked.setup(van, map.tile_to_world(kerb_tile), PackedVector2Array(), Vector2.RIGHT, map)
	t.check(parked.position.is_equal_approx(map.tile_to_world(kerb_tile)),
			"'delivery_van' (AT_THE_KERB) is left exactly where it was placed, not re-centred")
	parked.free()

	# The exemption is meaningful, not a no-op: an ANY-`pavement_side` body sited on the very same
	# tile does get moved, onto the middle of the two-lane band — half a tile from the tile centre,
	# in the direction `CityMap.pavement_inward()` already answers for this lane.
	var barrier := EventCatalogue.by_id("construction")
	var centred := EventInstance.new()
	centred.setup(barrier, map.tile_to_world(kerb_tile), PackedVector2Array(), Vector2.RIGHT, map)
	var band_centre := map.tile_to_world(kerb_tile) \
			+ Vector2(map.pavement_inward(kerb_tile)) * (Tuning.TILE_SIZE * 0.5)
	t.check(centred.position.is_equal_approx(band_centre),
			"'construction' (pavement_side ANY) is re-centred onto the pavement band")
	centred.free()

	# And the payoff, stated as the arithmetic that decides it rather than as a distance: with
	# `construction` centred on the band, no point on the pavement is far enough from it to clear
	# `obstructs_radius + PLAYER_BODY_RADIUS` — the pram cannot pass on either lane, which is what
	# "the only Act I event that is physically in the way" means.
	var half_band := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 0.5
	t.check(barrier.obstructs_radius + Tuning.PLAYER_BODY_RADIUS > half_band,
			"a centred 'construction' (%.0fpx + %.0fpx pram) reaches past either edge of the %.0fpx "
			% [barrier.obstructs_radius, Tuning.PLAYER_BODY_RADIUS, half_band * 2.0]
			+ "band, so it seals the whole pavement rather than one lane of it")

## **A spread's rotation is a property of the street it stands on.** Playtest 13 and 19 both report
## it from play: *"they're always horizontal even when they should be vertical."* A tile whose `x`
## sits inside a corridor band and whose `y` does not is on a north-south street, where the default
## lay (along local X) already blocks the traffic; a tile whose `y` is inside a band and `x` is not
## is on an east-west street, where the spread has to rotate onto local Y to block anything at all.
## A bare `CityMap.new()` needs no generation for this — `corridor_offset` is arithmetic over
## `Tuning`'s constants alone.
func _test_a_spread_rotates_with_the_street(t) -> void:
	var map := CityMap.new()

	var ns_tile := Vector2i(Tuning.STREET_WIDTH / 2, Tuning.STREET_WIDTH + 3)
	t.check(CityMap.corridor_offset(ns_tile.x) >= 0 and CityMap.corridor_offset(ns_tile.y) < 0,
			"tile %s sits on a north-south street" % ns_tile)
	t.check(not EventInstance._spread_is_vertical(map, map.tile_to_world(ns_tile)),
			"a north-south street keeps the spread's default lay along local X")

	var ew_tile := Vector2i(Tuning.STREET_WIDTH + 3, Tuning.STREET_WIDTH / 2)
	t.check(CityMap.corridor_offset(ew_tile.y) >= 0 and CityMap.corridor_offset(ew_tile.x) < 0,
			"tile %s sits on an east-west street" % ew_tile)
	t.check(EventInstance._spread_is_vertical(map, map.tile_to_world(ew_tile)),
			"an east-west street rotates the spread onto local Y")

	# A junction belongs to both corridors at once, and ground off any corridor belongs to
	# neither — neither has one street to lie across, so both keep the default lay.
	var junction_tile := Vector2i(Tuning.STREET_WIDTH / 2, Tuning.STREET_WIDTH / 2)
	t.check(CityMap.corridor_offset(junction_tile.x) >= 0
			and CityMap.corridor_offset(junction_tile.y) >= 0,
			"tile %s is a junction, on both corridors at once" % junction_tile)
	t.check(not EventInstance._spread_is_vertical(map, map.tile_to_world(junction_tile)),
			"a junction has no single street to be wrong about")

	var block_tile := Vector2i(Tuning.STREET_WIDTH + 3, Tuning.STREET_WIDTH + 3)
	t.check(CityMap.corridor_offset(block_tile.x) < 0 and CityMap.corridor_offset(block_tile.y) < 0,
			"tile %s is off any corridor — a square, a park, a courtyard" % block_tile)
	t.check(not EventInstance._spread_is_vertical(map, map.tile_to_world(block_tile)),
			"ground that was never a street keeps the default lay too")

	t.check(not EventInstance._spread_is_vertical(null, Vector2.ZERO),
			"a data-level rig with no map at all gets the unrotated default")

## **A spread never lands on a corner.** `EventScheduler._is_a_corner` refuses any tile whose two
## coordinates are both inside a corridor band to a row `EventInstance.has_a_spread()` names — see
## `docs/TODO.md`, M64, "a spread on a corner is placed as if the corner were nothing": such a tile
## has no single street for `_spread_is_vertical` or `_centred_on_the_pavement_band` to answer about.
## Walked over the **planned** placements of several seeds and every day of a run, rather than over
## the candidate pool directly, because a clean pool and a roll that still lands on a stale entry
## are two different bugs.
func _test_a_spread_never_lands_on_a_corner(t) -> void:
	var checked := 0
	for run_seed in [4242, 2102613802, 90210]:
		var map := CityGenerator.generate(run_seed)
		var consumed: Array[String] = []
		for day in range(1, 15):
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d" % [run_seed, day])
			for plan in EventScheduler.build_day(day, rng, map, consumed):
				if not plan.is_placed() or not EventInstance.has_a_spread(plan.def):
					continue
				checked += 1
				var tile := map.world_to_tile(plan.position)
				var on_corner := CityMap.corridor_offset(tile.x) >= 0 \
						and CityMap.corridor_offset(tile.y) >= 0
				t.check(not on_corner,
						"seed %d day %d: '%s' at tile %s is not on a corner"
						% [run_seed, day, plan.def.id, tile])
	t.check(checked > 0, "some run placed a spread to check (%d)" % checked)

## **A spread's end cap is drawn at exactly the width it obstructs, not past it.**
## `EventInstance._draw_spread`'s own docstring is the contract; the repeated segments already meet
## it, and the cap is the half that used to break it — centred at `±half`, `barrier_end.svg` (6px
## wide) hung 3px past each end of a `construction` barrier's 64px obstruction.
## `EventInstance._cap_offset` is the pure arithmetic the drawing calls, so this asserts the outer
## edge it produces against the real asset size and the real `obstructs_radius`, for the one row
## that carries a cap.
func _test_a_spread_cap_matches_what_it_obstructs(t) -> void:
	var def := EventCatalogue.by_id("construction")
	var half := maxf(11.0, def.obstructs_radius)
	var cap_along := EventInstance.BARRIER_END.get_size().x
	var offset := EventInstance._cap_offset(half, cap_along, 1.0)
	t.check(is_equal_approx(offset + cap_along * 0.5, half),
			"the cap's outer edge (%.1f) lands on the %.1fpx obstruction, not past it"
			% [offset + cap_along * 0.5, half])
	t.check(not is_equal_approx(offset, half),
			"and it is not simply centred at ±half any more (%.1f)" % offset)

# ------------------------------------------------------------------ emission ---

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

## **The one encounter in the game with a right answer, walked three ways.** *(M35, playtest 08
## finding 4: "I like the running tutorial on day 3 but I don't know how to solve it yet — I died
## every time.")*
##
## `validate_pursuit` passed every line of itself while the dog was killing people, because every
## line of it was about **speeds and durations** and a pursuit is played out in **distances**. This
## is the same contract walked rather than asserted, and the three walks are the three answers a
## player can give: into it, away from it at a walk, and away from it at a run. What each one has to
## produce is different, and the first one is the one that was broken — she is *sited walking into
## it*, because the director puts it where she was already going.
##
## *(M36 turned it from a test about the dog into a test about the **catalogue**, because there are
## two pursuers now and the second one arrives as a place rather than a moment. Everything below is
## true of both; what differs is only where she is standing when it starts.)*
func _test_a_pursuer_leaves_room_to_answer(t) -> void:
	var pursuers := 0
	for def in EventCatalogue.all():
		if not def.pursues:
			continue
		pursuers += 1
		var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
		t.check(standoff > def.inner_radius,
				"'%s' holds off outside the radius that ends the day" % def.id)

		# Into it. The geometry the day-3 lesson actually produces, and the one that killed a run
		# three times: it keeps its distance while it is only telegraphing, however far she walks in.
		var walked_in := _chase_rig(def, -Tuning.WALK_SPEED)
		t.close_to(walked_in["at_the_lunge"], standoff,
				"walking into '%s' still leaves the whole stand-off when it goes lethal" % def.id,
				8.0)
		t.check(not walked_in["lethal_while_telegraphing"],
				"and nothing '%s' does during its own telegraph can end the day" % def.id)

		# Away from it at a walk. Walking has to lose, or the mechanic teaches nothing.
		var walked_off := _chase_rig(def, Tuning.WALK_SPEED)
		t.check(walked_off["caught"], "walking away from '%s' is not enough" % def.id)
		t.check(not walked_off["gave_up"],
				"so '%s' never has to give up on somebody walking" % def.id)

		# Away from it at a run. Running has to win, and it has to *end* it: the price of the right
		# answer is fourteen points a second, so a chase that runs its full clock however well it is
		# played is a toll rather than a lesson. Both facts follow from the speed clauses alone —
		# nothing slower than the pursuer can open the gap and nothing faster can fail to — which is
		# why `PURSUIT_SHAKEN_OFF` is stated as a rate and there is no distance to get wrong.
		var ran := _chase_rig(def, Tuning.RUN_SPEED)
		t.check(not ran["caught"], "running away from '%s' works" % def.id)
		t.check(ran["gave_up"],
				"and '%s' breaks off rather than tailing her for the whole chase" % def.id)
		t.check(ran["ended_at"] < def.telegraph_time + def.duration,
				"which ends '%s' early: %.1fs against a %.1fs chase"
				% [def.id, ran["ended_at"], def.telegraph_time + def.duration])
		var cost: float = ran["ended_at"] * Tuning.EXCITEMENT_FROM_RUNNING
		t.check(cost < Tuning.METER_MAX * 0.6,
				"and running from '%s' costs %.0f of a %.0f meter rather than the day"
				% [def.id, cost, Tuning.METER_MAX])
	t.check(pursuers >= 2, "there is more than one kind of thing that comes after her")

## **The answer is priced by how soon it is given, and the rig has to turn round to find out.**
## *(Playtest 10, finding 13: "the running tutorial dog is impossible to escape at the moment",
## clarified as "the issue was that the dog kept following for too long".)*
##
## The three walks above hold a constant speed from the first frame, and all three passed while a
## player was reporting the encounter as unplayable — because nobody can turn round in nought
## seconds and nothing said she had to. Reversing a walk into a run takes
## `(WALK_SPEED + RUN_SPEED) / ACCELERATION` = 0.37s, and the thing keeps coming through all of it.
##
## What is asserted is the shape rather than any one number: **it can be answered, answering sooner
## costs strictly less, and doing nothing still loses.** The cost is bounded by
## `PURSUIT_SHAKEN_OFF` plus the about-turn rather than by the chase clock, which is the whole
## difference between a lesson and a toll.
##
## **The measured number this reports rather than asserts is the window at the lunge**, and it is
## the open half of finding 13. She is walking *into* the thing at that instant — it is sited in
## front of her and holds its distance by backing off — so the gap closes at `pursue_speed +
## WALK_SPEED` and the stand-off is worth about a third of the `PURSUIT_REACTION` it was bought
## with. A player answers during the **telegraph**, where the dog is visible and closing for two and
## a half seconds, and that answer is cheap; the lunge is the worst case rather than the expected
## one. Widening it means a wider stand-off, and a wider stand-off is a dog that visibly reverses.
func _test_the_answer_is_priced_by_how_soon_it_is_given(t) -> void:
	for def in EventCatalogue.all():
		if not def.pursues:
			continue
		var at_once := _answer_rig(def, 0.0)
		t.check(not at_once["caught"],
				"'%s' can be answered at the lunge (closest %.0fpx)" % [def.id, at_once["closest"]])
		t.check(at_once["closest"] > def.inner_radius,
				"and answering it clears the %.0fpx that ends the day by %.0fpx"
				% [def.inner_radius, at_once["closest"] - def.inner_radius])

		# The price is the about-turn plus being visibly outrun, and nothing else. A chase that ran
		# its clock however well it was played would cost `PURSUIT_TIME` here instead.
		var turn := (Tuning.WALK_SPEED + Tuning.RUN_SPEED) / Tuning.ACCELERATION
		t.check(at_once["running"] < Tuning.PURSUIT_SHAKEN_OFF + turn + 0.5,
				"and it costs %.1fs of running rather than the %.1fs chase"
				% [at_once["running"], def.duration])
		t.check(at_once["running"] * Tuning.EXCITEMENT_FROM_RUNNING < Tuning.METER_MAX * 0.3,
				"which is %.0f of a %.0f meter"
				% [at_once["running"] * Tuning.EXCITEMENT_FROM_RUNNING, Tuning.METER_MAX])

		# Answering during the telegraph — what a player who reads the cue actually does — is cheaper
		# still, and that gradient is the reason the break-off is a rate rather than a clock.
		var early := _chase_rig(def, Tuning.RUN_SPEED)
		t.check(early["gave_up"] and not early["caught"],
				"running from '%s' the moment it appears shakes it off" % def.id)

		# And doing nothing still loses, which is the whole reason any of this is a mechanic.
		t.check(_answer_rig(def, 1.0)["caught"],
				"'%s' still catches somebody who leaves it far too long" % def.id)

		# Reported, not asserted: the widest reaction at the lunge that still survives. See above.
		var window := 0.0
		for i in 12:
			var reaction := i * 0.05
			if _answer_rig(def, reaction)["caught"]:
				break
			window = reaction
		t.check(window > 0.0,
				"the window to answer '%s' at the lunge itself is %.2fs" % [def.id, window])

## **A pursuer has to be sited where it can be seen doing it.** *(M39, finding 13.)*
##
## Three things have to agree and none of them knows about the other two: the stand-off is where it
## stops, the director decides where it starts, and the viewport decides what is on screen. If the
## stand-off ever grows past the lead the director gives it, a pursuer *backs away* through its own
## telegraph instead of closing; if the lead grows past `SIGHT_AHEAD`, the whole telegraph happens
## off the top of the screen when she walks north or south, and the notice is the sight of it.
##
## M39 moved the stand-off from 104px to 174 and would have broken the first of those silently — the
## dog was sited at 184 — so the relationship is asserted rather than left as a coincidence.
func _test_a_pursuer_is_sited_where_it_can_be_seen(t) -> void:
	for def in EventCatalogue.all():
		if not def.pursues:
			continue
		var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
		t.check(standoff < Tuning.SIGHT_AHEAD,
				"'%s' stands off at %.0fpx, inside the %.0fpx that is still on screen"
				% [def.id, standoff, Tuning.SIGHT_AHEAD])
		if def.pursues_within > 0.0:
			# A place, not a moment: the director never sites it, so what has to hold is that its
			# trigger is outside its stand-off — which `validate_pursuit` also checks, from the
			# other side and for a different reason.
			t.check(def.pursues_within > standoff,
					"'%s' notices her before it has stopped coming" % def.id)
			continue
		t.check(_sited_at(def) >= standoff,
				"'%s' is sited at %.0fpx, at or beyond the %.0fpx it stops at, so it closes rather "
				% [def.id, _sited_at(def), standoff] + "than backing away through its own telegraph")

## **A retried day is the same day.** *(M39, playtest 10 finding 5: "the tutorial dog on day 3 only
## appeared once (I died) then it didn't appear again.")*
##
## `docs/TODO.md` has claimed this since M32 and it was not true: `build_day` ran six phases off one
## RNG, and a one-shot the run had already spent was skipped *before* its `randf()` was drawn, so the
## second attempt at day 3 — the day the fire engine runs — started the recurring fill one value
## earlier and produced a different city's worth of events. The trace has `homeless_yeller` going
## from two to eight and `cyclist` from none to three between two consecutive attempts at the same
## day.
##
## **What is asserted is the day's *composition*, not every coordinate**, and the difference is the
## measurement rather than a hedge. A spent one-shot is genuinely gone, and `fire_truck`'s route is
## sixty tiles — nineteen hundred pixels of corridor that the recurring fill had to keep
## `EVENT_SPACING_ANY` clear of. With it gone, the long mobile rows whose own routes brushed that
## corridor now fit where they did not, so they start a few tiles along the street they were always
## going to be on. Measured over three seeds: the multiset of event **kinds** is identical every
## time, and the positions that move are `dog_walker` and `reversing_lorry` — the sited, route rows
## still left. `cyclist` and `loose_dog` are `TOWARD_PLAYER` now: the scheduler never gives either a
## coordinate at all, so neither can appear in that count regardless of what a spent one-shot frees.
##
## A dog walker starting three tiles further up the same street is not a different day. Eight
## shouting men where there were two is, and that is what this stops.
func _test_a_retried_day_is_the_same_day(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	for run_seed in [4242, 90210, 1234567]:
		var map := CityGenerator.generate(run_seed)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d:events" % [run_seed, day])

		var consumed: Array[String] = []
		var first := EventScheduler.build_day(day, rng, map, consumed)
		t.check(not consumed.is_empty(), "day %d spends a one-shot on seed %d" % [day, run_seed])
		var again := RandomNumberGenerator.new()
		again.seed = rng.seed
		var second := EventScheduler.build_day(day, again, map, consumed.duplicate())

		# The one-shot itself is the one thing that must differ: it fired yesterday and is spent, so
		# the retry plans **none** of it. *(Since M50 step 2 that is "none" rather than "one fewer":
		# a set piece is offered at every site of a covering set and the whole group goes with it.)*
		#
		# **And nothing else moves at all**, which is stronger than what M39 could promise. It used
		# to allow one instance of drift, because the ground a spent one-shot freed let a placement
		# that had failed now fit; an offer costs no room since M50 step 2 — see `_room_around` —
		# so the fill is identical between attempts rather than merely close. What is *not* closed
		# is still not closed: a **scar** genuinely occupies ground and still moves what stood
		# there, which is the run's own history showing through and is the answer that should.
		var before := _kinds_in(first)
		var after := _kinds_in(second)
		var changed := 0
		for id: String in before.keys() + after.keys():
			var expected: int = 0 if id in consumed else int(before.get(id, 0))
			t.check(int(after.get(id, 0)) == expected,
					"seed %d: the retry has %d '%s' where the day had %d"
					% [run_seed, int(after.get(id, 0)), id, expected])
			changed += 1 if int(after.get(id, 0)) != expected else 0
		t.check(changed == 0,
				"seed %d: and nothing else moves at all (%d kinds did)" % [run_seed, changed])

## The multiset of event ids in a plan: what the day is *made of*, with the geometry thrown away.
func _kinds_in(plans: Array[EventScheduler.Planned]) -> Dictionary:
	var counts := {}
	for plan in plans:
		counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
	return counts

## **The day the run is taught always has something to teach it with.** *(M39, finding 5.)*
##
## `charging_dog` is weight 1.4 of a day-3 pool and `EventDirector._teach_the_run` says outright what
## happens when the dice disagree — *"if the day happened not to buy one, there is nothing to teach
## and nothing happens"* — so a player could reach act II never having been shown the one control the
## game will later require. A lesson that only happens on some seeds is not a lesson.
func _test_the_run_is_always_taught(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	for run_seed in [4242, 90210, 1234567, 31337]:
		var map := CityGenerator.generate(run_seed)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d:events" % [run_seed, day])
		var consumed: Array[String] = []
		var pursuits := 0
		for plan in EventScheduler.build_day(day, rng, map, consumed):
			pursuits += 1 if plan.def.pursues else 0
		t.check(pursuits > 0,
				"seed %d: day %d has something that has to be run from" % [run_seed, day])

## Walks the encounter the way it is actually played: she is walking into it when it lunges, dithers
## for `reaction` seconds, then turns and runs — accelerating, rather than changing speed instantly.
##
## Reports how close it got and how long she spent running, because those are the two numbers the
## contract is about: one is whether the answer works and the other is what it costs.
##
## The running stops being counted the moment the thing gives up, which is not fussiness: an event
## that is over still exists for several seconds while it leaves, and a rig that kept holding the
## key down through that would price the answer at whatever `departs_at` happens to be.
func _answer_rig(def: EventDef, reaction: float) -> Dictionary:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	var her := Vector2(_sited_at(def), 0.0)
	# Positive is away from it, matching `_chase_rig`. She starts walking in.
	var speed := -Tuning.WALK_SPEED
	var elapsed := 0.0
	var since_the_lunge := INF
	var result := {"caught": false, "closest": INF, "running": 0.0}
	while elapsed < 14.0 and not instance.is_leaving and not result["caught"]:
		if not instance.is_telegraphing() and not instance.is_waiting() and since_the_lunge == INF:
			since_the_lunge = 0.0
		var wanted := -Tuning.WALK_SPEED
		if since_the_lunge != INF and since_the_lunge >= reaction:
			wanted = Tuning.RUN_SPEED
		speed = move_toward(speed, wanted, Tuning.ACCELERATION * STEP)
		if speed > Tuning.WALK_SPEED:
			result["running"] = float(result["running"]) + STEP
		her.x += speed * STEP
		instance.player_at = her
		instance.player_running = speed > Tuning.WALK_SPEED
		instance._process(STEP)
		elapsed += STEP
		if since_the_lunge != INF:
			since_the_lunge += STEP
		result["closest"] = minf(float(result["closest"]),
				instance.global_position.distance_to(her))
		if instance.is_lethal_at(her):
			result["caught"] = true
	instance.free()
	return result

## Where the encounter actually starts, in px: where the director sites something that comes at her,
## or just inside the trigger for something that has been standing there.
##
## *(M39.)* It was `AHEAD_LEAD_DISTANCE` for the first case, which stopped being true when the
## stand-off grew past it — the director sites a pursuer beyond its own stand-off now, and a rig
## measuring from the cat's lead would have been measuring an encounter the game cannot produce.
##
## *(M43.)* And it is `SIGHT_AHEAD` flat now rather than a clamp, because the notice a pursuit
## gives is exactly the ground between the siting and the stand-off. It has to keep matching
## `EventDirector._crossing_ahead_of`, which is the reason this is one line and not a formula.
func _sited_at(def: EventDef) -> float:
	if def.pursues_within > 0.0:
		return def.pursues_within - 10.0
	return Tuning.SIGHT_AHEAD

## Walks one answer to a pursuit and reports what happened. `player_speed` is along the line between
## them: positive is away from it, negative is into it.
func _chase_rig(def: EventDef, player_speed: float) -> Dictionary:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	var from := _sited_at(def)
	var her := Vector2(from, 0.0)
	var elapsed := 0.0
	var result := {"caught": false, "gave_up": false, "lethal_while_telegraphing": false,
			"at_the_lunge": INF, "ended_at": INF}
	var was_telegraphing := true
	while elapsed < 12.0 and not instance.is_finished and not result["caught"]:
		her.x += player_speed * STEP
		instance.player_at = her
		# The break-off is a fact about *her* since playtest 14, so a rig that only moves her is
		# not running the rule. See `Tuning.PURSUIT_SHAKEN_OFF`.
		instance.player_running = player_speed > Tuning.WALK_SPEED
		instance._process(STEP)
		elapsed += STEP
		if was_telegraphing and not instance.is_telegraphing():
			result["at_the_lunge"] = instance.global_position.distance_to(her)
			was_telegraphing = false
		if instance.is_lethal_at(her):
			result["caught"] = true
			result["lethal_while_telegraphing"] = was_telegraphing
		if instance.gave_up and result["ended_at"] == INF:
			result["gave_up"] = true
			result["ended_at"] = elapsed
	if result["ended_at"] == INF:
		result["ended_at"] = elapsed
	instance.free()
	return result

## **A beat rather than a journey.** *(M36, playtest 09: "who is the person killing me? It didn't
## move… if it's the homeless person it needs to walk up and down the sidewalk.")*
##
## The thing that could go quietly wrong is not the turning round, it is what a paced event does at
## the end of its path: everything else in the catalogue that reaches one is **over**, and since M35
## it leaves. A fixture that walks must do neither, or the man shouting outside the home block would
## stroll off down the street eight seconds into every day.
func _test_a_paced_event_walks_a_beat(t) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	t.check(def.paces and def.mobile, "the man shouting walks a beat")
	t.check(def.obstructs_radius <= 0.0,
			"and has no body, because a moving wall pins her — the dog_walker decision")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(256.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)

	var out := 256.0 / def.speed
	_advance(instance, out - 0.2)
	t.close_to(instance.position.x, 256.0, "it walks to the far end of its beat", 8.0)
	t.check(instance._heading.x > 0.0, "facing the way it is going")

	_advance(instance, out)
	t.close_to(instance.position.x, 0.0, "and back again", 8.0)
	t.check(instance._heading.x < 0.0, "facing the other way on the way back")
	t.check(not instance.is_finished and not instance.is_leaving,
			"a fixture that moves neither finishes nor leaves at the end of its path")

	# And it is still there four beats later, which is most of a day.
	_advance(instance, out * 8.0)
	t.check(not instance.is_finished, "and it is still there a day later")
	instance.free()

## **A pursuer can be a place before it is a moment.** *(M36, playtest 09: "a robber should increase
## excitement on sight and getting close to them should be day ending", and "if you get close they
## should start moving towards you".)*
##
## Three states, and the two that are new are the ones worth asserting: while it is **waiting** it
## emits at full strength and cannot end the day, and its telegraph and its chase are both measured
## from the moment it **notices** rather than from the moment the day put it there. A robbery whose
## telegraph ran at dawn, four streets away, would arrive with no notice in it at all.
func _test_a_pursuer_can_wait(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	t.check(def.pursues_within > 0.0, "the robber waits")
	var instance := _instance(t, def, Vector2.ZERO)

	# Standing there, all day, at full strength.
	instance.player_at = Vector2(def.pursues_within + 40.0, 0.0)
	_advance(instance, 30.0)
	t.check(instance.is_waiting(), "he is still standing there half a minute later")
	t.check(not instance.is_finished, "and his duration has not been running")
	t.close_to(instance.position.x, 0.0, "he has not moved", 0.5)
	t.close_to(instance.current_intensity(), def.intensity,
			"he is loud from the moment she can see him, not damped to a telegraph", 0.05)
	t.check(not instance.is_lethal_at(instance.player_at), "and he cannot end the day yet")
	t.check(instance.contribution_at(Vector2(def.outer_radius - 10.0, 0.0)) > 0.0,
			"his field reaches the far end of the alley")

	# She steps inside the trigger: the notice starts *now*.
	instance.player_at = Vector2(def.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "he notices her")
	t.check(instance.is_telegraphing(), "and the notice starts when he does, not at dawn")
	t.check(not instance.is_lethal_at(instance.player_at), "still not lethal during the notice")

	_advance(instance, def.telegraph_time + 0.1)
	t.check(not instance.is_telegraphing(), "then the notice is over")
	instance.free()

## **The robber stops at walls.** A pursuing `EventInstance` moves by setting its own position, and
## nothing in the event system has ever collided with the city — harmless while every mobile row
## travelled a route the scheduler had already checked, and not harmless the moment something
## steers freely at the player.
##
## A real building corner, chased round: she walks from its north face to its east face, and a dog
## aimed straight at wherever she currently is would cut across the building itself to follow her —
## exactly the shape of the bug. `EventInstance._walkable_step` is the fix, and this is what it
## has to hold true of every frame regardless of the geometry, which is why the check runs the
## whole walk rather than sampling the end of it.
func _test_a_pursuer_stops_at_walls(t) -> void:
	var map := _map()
	var corner := _a_building_corner(map)
	t.check(not corner.is_empty(), "the sampled map has a building corner to chase round")
	if corner.is_empty():
		return
	var north: Vector2i = corner["north"]
	var east: Vector2i = corner["east"]

	var def := EventCatalogue.by_id("charging_dog")
	var instance := EventInstance.new()
	instance.setup(def, map.tile_to_world(north) + Vector2(-96.0, 0.0))
	t.add_child(instance)
	instance.set_process(false)
	instance._map = map

	# Clear the telegraph with her held far off, so what follows is about the wall and not about
	# the stand-off.
	instance.player_at = map.tile_to_world(north) + Vector2(-4000.0, 0.0)
	_advance(instance, def.telegraph_time + 0.1)
	t.check(not instance.is_telegraphing(), "the dog is chasing by the time she rounds the corner")

	# She walks from the building's north face round to its east face — the corner a straight
	# line to her would cut across — and the dog is told to chase wherever she currently is,
	# every frame, the way `EventManager` actually drives it.
	var her := map.tile_to_world(north)
	var target := map.tile_to_world(east)
	var elapsed := 0.0
	var checked := 0
	while her.distance_to(target) > 4.0 and elapsed < 15.0:
		her = her.move_toward(target, Tuning.WALK_SPEED * STEP)
		instance.player_at = her
		instance._process(STEP)
		elapsed += STEP
		var tile := map.world_to_tile(instance.global_position)
		checked += 1
		t.check(map.is_walkable(tile),
				"the pursuer never stands on the building at %s (t=%.2fs)" % [tile, elapsed])
	t.check(checked > 0, "the walk round the corner actually ran")
	instance.free()

## A real building tile with open pavement on two adjacent sides — the outward corner every
## rectangular building has at least one of. `{}` would mean the generator changed shape rather
## than that the test picked badly.
func _a_building_corner(map: CityMap) -> Dictionary:
	for tile in map.tiles_of_type(GameEnums.TileType.BUILDING):
		var north := tile + Vector2i(0, -1)
		var east := tile + Vector2i(1, 0)
		if map.in_bounds(north) and map.in_bounds(east) \
				and map.is_walkable(north) and map.is_walkable(east):
			return {"building": tile, "north": north, "east": east}
	return {}

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

	# The backstop, for a rig or a streamed-out day where there is nobody to be out of sight of.
	var alone := _instance(t, def, Vector2.ZERO)
	_advance(alone, def.telegraph_time + def.duration + EventInstance.LEAVING_GIVES_UP + 0.2)
	t.check(alone.is_finished, "with nobody watching it leaves on a timer rather than for ever")
	alone.free()

## **The birds move, one at a time, and they stay inside their own event.** *(M38: "the birds are
## broken — they start the flying animation but then freeze. Turn them into individual entities and
## let each fly and make them dangerous.")*
##
## Three claims, and the middle one is the one that could go wrong silently. A flock used to be one
## sprite drawn seven times at offsets derived from the instance's own position, sharing a single
## rise term — so the seven birds *could not* move relative to each other and the whole animation was
## over at the end of the telegraph. Nothing could see that: it has a duration, it emits, it departs,
## and every test it had passed while it hung in the air.
##
## - **They move apart**, which is the difference between eleven birds and one bird drawn eleven
##   times, and it is checked during the burst rather than the departure — a flock that only comes
##   alive on its way out is the original bug with a longer fuse.
## - **They stay inside `flock_spread`.** The telegraph fairness contract is stated over
##   `outer_radius` *from the instance*, so eleven moving emitters are only legal while their union
##   is inside the disc `validate_event` checked. This is the assertion that says so.
## - **The middle costs and the rim does not**, which is the whole reason a flock is worth eleven
##   sources: the price of one depends on whether you went through it or round it.
func _test_a_flock_is_birds_rather_than_one_bird_drawn_often(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	t.check(def.flock_size > 1 and def.flock_spread > 0.0, "a flock is more than one body")
	t.check(def.flock_spread < def.outer_radius,
			"and the room it takes up comes out of the field it emits over, not on top of it")
	var instance := _instance(t, def, Vector2.ZERO)
	_advance(instance, def.telegraph_time + 0.2)
	t.check(not instance.is_telegraphing() and not instance.is_leaving, "the flock is up")

	var spread_before := _widest_gap_between_birds(instance)
	_advance(instance, 1.0)
	var spread_after := _widest_gap_between_birds(instance)
	t.check(not is_equal_approx(spread_before, spread_after),
			"the birds move relative to each other rather than as one shape (%.1f then %.1f)"
			% [spread_before, spread_after])

	# Two full seconds of wheeling: whatever they do, they may not leave the event. Reported as one
	# check with the worst reading in it, rather than one per bird per frame — thirteen hundred
	# identical passes tell a reader nothing and the one number that matters does.
	var furthest := 0.0
	for i in int(2.0 / STEP):
		instance._process(STEP)
		if instance.is_leaving:
			break
		for bird in instance._flock:
			furthest = maxf(furthest, bird.at.length())
	t.check(furthest <= def.flock_spread + 2.0,
			"every bird stayed inside the %.0fpx flock for the whole burst (furthest %.0fpx)"
			% [def.flock_spread, furthest])

	var middle := instance.contribution_at(Vector2.ZERO)
	var rim := instance.contribution_at(Vector2(def.outer_radius - 6.0, 0.0))
	t.check(middle > rim * 4.0,
			"walking through the middle of a flock (%.1f/s) costs far more than skirting it (%.1f/s)"
			% [middle, rim])
	t.check(rim >= 0.0 and instance.contribution_at(Vector2(def.outer_radius + 80.0, 0.0)) == 0.0,
			"and nothing at all reaches past the radius the contract was checked against")
	instance.free()

## The greatest distance between any two birds, which is the cheapest single number that changes
## when they move independently and does not when they move as one shape.
func _widest_gap_between_birds(instance: EventInstance) -> float:
	var widest := 0.0
	for a in instance._flock:
		for b in instance._flock:
			widest = maxf(widest, a.at.distance_to(b.at))
	return widest

func _test_mobile_follows_its_path(t) -> void:
	var def := EventCatalogue.by_id("fire_truck")
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(300.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)
	t.check(instance.position == Vector2.ZERO, "a mobile event starts at its first waypoint")

	_advance(instance, 0.5)
	t.close_to(instance.position.x, def.speed * 0.5, "a mobile event travels at its speed", 5.0)
	t.close_to(instance.position.y, 0.0, "a mobile event stays on its path")

	# Off the end of the route is over, whatever the nominal duration says.
	_advance(instance, 3.0)
	t.check(instance.is_finished, "a mobile event finishes at the end of its path")
	instance.free()

## The other kind of mobile event, and the reason the field exists. A telegraph that is an
## *approach* has to travel — a fire engine warns you by being audible three streets away. A
## telegraph that is a *posture* must not: the cat crouches, then bolts.
##
## Playtest 04 found the cat doing nothing, and this is half of why. Its route is one street
## wide, so at 240px/s it finished the whole crossing inside its own 1.6s telegraph — it never
## reached full intensity, and the running sprite never drew once in six milestones.
func _test_a_crouching_event_holds_still_until_it_bolts(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	t.check(def.still_while_telegraphing, "the cat crouches rather than creeping")
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(400.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)

	_advance(instance, def.telegraph_time - 0.1)
	t.check(instance.position == Vector2.ZERO, "it has not moved while telegraphing")
	t.check(instance.is_telegraphing(), "and it is still telegraphing")

	_advance(instance, 0.5)
	t.check(not instance.is_telegraphing(), "then the telegraph ends")
	t.close_to(instance.position.x, def.speed * 0.4,
			"and it bolts at its full speed from where it was crouched", 20.0)

	# The duration has to outlast the crossing, or it expires in the middle of the road.
	var crossing := float(EventDirector.CROSSING_REACH_TILES * Tuning.TILE_SIZE) * 2.0
	t.check(def.duration >= crossing / def.speed,
			"it lives long enough (%.2fs) to cross the whole street (%.2fs)"
			% [def.duration, crossing / def.speed])
	instance.free()

## Playtest 04: *"the cat is ineffective since it happens when it spawns — the cat should get
## spawned in in front of the player while they walk, so it happens directly in front of them
## every time."*
##
## The three properties that make an interruption legal, in the order they matter. It has to be
## *in front of her*, or it is not the thing that was asked for. It has to start *outside its
## own outer radius*, or an event with no telegraph phase is being dropped on top of her. And
## the clock has to run on walking, not on wall time, or a player who stops in a park to let the
## meter recover comes back to the pavement owing four cats.
func _test_the_director_puts_it_in_front_of_her(t) -> void:
	var map := _map()
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var plans: Array[EventScheduler.Planned] = [
		EventScheduler.Planned.new(EventCatalogue.by_id("cat_dash"), Vector2.INF),
		EventScheduler.Planned.new(EventCatalogue.by_id("cat_dash"), Vector2.INF),
	]
	director.start_day(1, plans, rng)
	t.check(director.owed() == 2, "the day's budget is what the director gets to spend")

	# Somewhere on a street, walking north. `arterial_pavement` is a pavement lane by
	# construction, so the lead lands on walkable ground.
	var at := CrowdLanes.arterial_pavement(map)
	at.y = map.world_size().y * 0.5
	var north := Vector2(0.0, -Tuning.WALK_SPEED)

	# Standing still owes nothing, however long she stands there.
	var fired := false
	for i in int(round(60.0 / STEP)):
		fired = fired or not director.due(STEP, at, Vector2.ZERO).is_empty()
	t.check(not fired, "nothing crosses in front of somebody who is not going anywhere")
	t.check(director.owed() == 2, "so a minute of standing still spends none of the day")

	# Walking does.
	var due: Array = []
	for i in int(round(Tuning.AHEAD_INTERVAL.y * 2.0 / STEP)):
		due = director.due(STEP, at, north)
		if not due.is_empty():
			break
	t.check(not due.is_empty(), "walking for the length of the interval brings one out")
	if due.is_empty():
		return

	var path := due[1] as PackedVector2Array
	t.check(path.size() == 2, "it is given a route across her line")
	var def := due[0] as EventDef
	# The cat is `still_while_telegraphing`, so its lead is `EventDef.ahead_of_player_lead()` —
	# longer than the flat `AHEAD_LEAD_DISTANCE` by exactly the ground she covers while it holds
	# its crouch — rather than the constant every other crossing row is sited at.
	var lead := def.ahead_of_player_lead()
	t.check(lead > Tuning.AHEAD_LEAD_DISTANCE,
			"the cat's own lead (%.0fpx) accounts for its held crouch, not just a flat reaction "
			% lead + "window (%.0fpx)" % Tuning.AHEAD_LEAD_DISTANCE)
	var crossing := (path[0] + path[1]) * 0.5
	t.close_to(crossing.distance_to(at), lead,
			"it crosses where she is about to be, not where she is", 1.0)
	t.check((crossing - at).normalized().dot(north.normalized()) > 0.99,
			"and that is in front of her rather than beside or behind her")
	t.close_to((path[1] - path[0]).normalized().dot(north.normalized()), 0.0,
			"the run is square across her line", 0.01)

	# The fairness half. It starts at one end of that run, and both ends are further from her
	# than the field it will emit — so she is outside it the whole time it is telegraphing, and
	# the reaction window is real rather than nominal.
	for end in [path[0], path[1]]:
		t.check(at.distance_to(end) > def.outer_radius,
				"she is outside its reach (%.0fpx) when it appears (%.0fpx away)"
				% [def.outer_radius, at.distance_to(end)])
	t.check(lead / Tuning.WALK_SPEED >= 1.5,
			"and the lead is %.1fs of walking, which is time to do something about it"
			% (lead / Tuning.WALK_SPEED))
	t.check(director.owed() == 1, "and the day is one cat poorer")

## **The three rows that never had an impact, meeting the rig they were designed for.** The bike,
## the loose dog and the cat were each sited in a way that meant she could walk the whole day
## without ever crossing paths with one — `cyclist` and `loose_dog` on a street the day chose at
## dawn, `cat_dash` aimed at where she was rather than where she would be. This is the point of
## fixing all three: not that the siting geometry is fair on paper, but that a rig walking a real
## street actually **meets** each of them — comes within its own `outer_radius`, the same measure
## the fairness contract and the cost table are both stated over.
##
## Driven through `EventDirector` exactly as `EventManager` drives it in play, on a real generated
## map, walking continuously the way `due()` requires before it will ever site anything.
func _test_a_rig_meets_the_three_things_that_arrive(t) -> void:
	for id in ["cat_dash", "cyclist", "loose_dog"]:
		var def := EventCatalogue.by_id(id)
		var map := _map()
		var director := EventDirector.new(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var plans: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(def, Vector2.INF)]
		director.start_day(def.first_day, plans, rng)

		# Somewhere on a street, walking north — the same rig `_test_the_director_puts_it_in_front_
		# of_her` walks, so a real street is guaranteed long enough for this.
		var at := CrowdLanes.arterial_pavement(map)
		at.y = map.world_size().y * 0.5
		var north := Vector2(0.0, -Tuning.WALK_SPEED)

		var due: Array = []
		for i in int(round(Tuning.AHEAD_INTERVAL.y * 2.0 / STEP)):
			due = director.due(STEP, at, north)
			at += north * STEP
			if not due.is_empty():
				break
		t.check(not due.is_empty(), "'%s' is sited while she walks a real street" % id)
		if due.is_empty():
			continue

		var path := due[1] as PackedVector2Array
		var instance := EventInstance.new()
		instance.setup(def, path[0], path)
		t.add_child(instance)
		instance.set_process(false)

		var closest := INF
		for i in int(round(15.0 / STEP)):
			at += north * STEP
			instance.player_at = at
			instance._process(STEP)
			closest = minf(closest, instance.global_position.distance_to(at))
			if instance.is_finished:
				break
		t.check(closest <= def.outer_radius,
				"'%s' actually meets the rig (closest %.0fpx of a %.0fpx reach)"
				% [id, closest, def.outer_radius])
		instance.free()

func _test_hard_fail_only_when_active(t) -> void:
	var def := EventDef.new()
	def.id = "test_hard_fail"
	def.intensity = 20.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.hard_fail = true
	def.telegraph_time = def.minimum_telegraph()
	t.check(def.validate(), "a hard-fail event with the doubled margin is fair")

	var instance := _instance(t, def)
	t.check(not instance.is_lethal_at(Vector2.ZERO),
			"a telegraphing hard-fail event is not yet lethal - that is the warning")
	_advance(instance, def.telegraph_time + 0.05)
	t.check(instance.is_lethal_at(Vector2(10.0, 0.0)),
			"an active hard-fail event is lethal inside its inner radius")
	t.check(not instance.is_lethal_at(Vector2(100.0, 0.0)),
			"a hard-fail event is not lethal outside its inner radius")
	instance.free()

	var safe := EventCatalogue.by_id("cat_dash")
	var harmless := _instance(t, safe)
	_advance(harmless, safe.telegraph_time + 0.05)
	t.check(not harmless.is_lethal_at(Vector2.ZERO), "an ordinary event is never lethal")
	harmless.free()

# ----------------------------------------------------------------- scheduler ---

func _map() -> CityMap:
	return CityGenerator.generate(4242)

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [4242, day])
	return rng

func _signature(planned: Array) -> String:
	var parts: Array[String] = []
	for plan in planned:
		parts.append("%s@%.1f,%.1f" % [plan.def.id, plan.position.x, plan.position.y])
	return "|".join(parts)

func _test_scheduler_is_deterministic(t) -> void:
	var map := _map()
	for day in [1, 5, 14]:
		var consumed_a: Array[String] = []
		var consumed_b: Array[String] = []
		var first := EventScheduler.build_day(day, _rng(day), map, consumed_a)
		var second := EventScheduler.build_day(day, _rng(day), map, consumed_b)
		t.check(_signature(first) == _signature(second),
				"day %d replans identically from the same seed" % day)

	var consumed: Array[String] = []
	var day_one := EventScheduler.build_day(1, _rng(1), map, consumed)
	consumed.clear()
	var day_two := EventScheduler.build_day(2, _rng(2), map, consumed)
	t.check(_signature(day_one) != _signature(day_two), "different days plan differently")

func _test_scheduler_respects_placement_and_caps(t) -> void:
	var map := _map()
	for day in range(1, 15):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
		var counts := {}
		for plan in planned:
			counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
			# An `AHEAD_OF_PLAYER` event has no tile: the day budgets it and the director sites
			# it in front of the player later. The cap above still applies to it, which is the
			# point of costing it here rather than giving the director its own allowance.
			if plan.def.placement.is_empty() or not plan.is_placed():
				continue
			var tile := map.world_to_tile(plan.position)
			t.check(map.tile_at(tile) in plan.def.placement,
					"day %d: '%s' was placed on an allowed tile type" % [day, plan.def.id])
		for id in counts:
			var def: EventDef = EventCatalogue.by_id(id)
			# A one-shot is exempt because since M50 step 2 it is planned at **every** site of a
			# covering set and only one of them ever happens — so the count here is how many places
			# the day offered it in, not how many of it there are. `max_per_day` is a cap on
			# instances and the group is one instance by construction; the count that would break
			# it is asserted in `tests/test_event_manager.gd`, where an instance actually exists.
			if def.kind == GameEnums.EventKind.AMBIENT \
					or def.kind == GameEnums.EventKind.ONE_SHOT:
				continue
			t.check(counts[id] <= def.max_per_day,
					"day %d: '%s' respects max_per_day" % [day, id])

## **A one-shot is planned on at most one day of a run, at a covering set of sites, and exactly one
## of those sites happens.** *(M50 step 2 split this sentence in two; it used to be one clause.)*
##
## The day half is asserted here, over the plan. The *site* half cannot be — a plan is a set of
## offers and which one is taken is decided by where she walks — so it is asserted where it is
## decided: `tests/test_event_manager.gd`, against a real `EventManager` with the plans streamed in.
func _test_one_shots_fire_once_per_run(t) -> void:
	var narrow := 0
	var groups_seen := 0
	# One run has exactly one one-shot to count, so the "how often does the covering set narrow to
	# one place" question below needs more than the file's shared seed to answer — several maps
	# rather than the one every other test here deliberately shares.
	for seed_value in [4242, 5150, 6060, 7070, 8080, 9090]:
		var map := CityGenerator.generate(seed_value)
		var consumed: Array[String] = []
		var seen := {}
		var rng_for := func(day: int) -> RandomNumberGenerator:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d" % [seed_value, day])
			return rng
		for day in range(1, 15):
			var groups := {}
			for plan in EventScheduler.build_day(day, rng_for.call(day), map, consumed):
				if plan.def.kind != GameEnums.EventKind.ONE_SHOT:
					continue
				t.check(int(seen.get(plan.def.id, day)) == day,
						"one-shot '%s' is planned on one day of a run" % plan.def.id)
				seen[plan.def.id] = day
				groups[plan.def.id] = int(groups.get(plan.def.id, 0)) + 1
				t.check(plan.set_piece_group != "",
						"one-shot '%s' is planned as one of a group" % plan.def.id)
			for id: String in groups:
				groups_seen += 1
				# Usually two: two distinct routes to one area share no *cell* by construction, so
				# a site placed on the exact cell one route stands on is never on the other. Since
				# M69 a site is still a whole street, though, and it is possible — rare, not ruled
				# out — for the two routes to use different cells of the very same street, which
				# one site then covers after all. That is the covering set collapsing to the
				# fallback the comment above used to say could not happen; it is legal, just not
				# the common case.
				if groups[id] < 2:
					narrow += 1
	t.check(groups_seen > 0, "some run had a one-shot to check (%d)" % groups_seen)
	t.check(float(narrow) / maxf(1.0, float(groups_seen)) < 0.4,
			"%d of %d one-shot runs offered only one place" % [narrow, groups_seen])

## The rule that keeps a day winnable: however bad it gets, one calm zone stays usable.
##
## "Usable" is the calm **ground**, not the whole block lot, and the distinction is M15's:
## a courtyard's calm is a four-tile court inside a residential block, so an event on the
## street outside spoils the lot and not the court. This test used to measure the lot, which
## asserted more than `_ensure_one_usable_park` has ever promised — invisible at thirteen
## events a day and false on nine days out of fourteen at M28's density, where every block
## has something on the street beside it. The guarantee it exists to protect is unchanged:
## somewhere in the city there is calm ground with nothing emitting into it.
func _test_one_park_stays_usable(t) -> void:
	var map := _map()
	for day in range(1, 15):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
		var clean := 0
		for block in map.calm_blocks:
			var lot := map.tile_rect_to_world(_calm_rect(map, block))
			var spoiled := false
			for plan in planned:
				if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
					continue
				var grown := lot.grow(plan.def.outer_radius)
				if grown.has_point(plan.position):
					spoiled = true
					break
				for point in plan.path:
					if grown.has_point(point):
						spoiled = true
						break
				if spoiled:
					break
			if not spoiled:
				clean += 1
		t.check(clean >= 1, "day %d leaves at least one park unspoiled" % day)

## **Nothing is placed near calm she has not used this act.** *(2026-08-31: "why are 7-9 unvisited
## calm areas spoiled? Just don't place events there!")*
##
## The stronger half of the rule above, and the one that is easy to lose: `_test_one_park_stays_usable`
## asks whether *some* area survived the day, which was satisfied for fourteen milestones by one
## area out of nine coming up clean by luck. This asks whether **every** area she has not settled in
## is untouched, which is the guarantee playtest 14's arithmetic is stated over — `MIN_CALM_BLOCKS`
## is an act's worth of days plus one on the assumption that only *going* to an area burns it.
##
## Walked over a whole run rather than over a list of days, because the used set is what the rule is
## stated against and it only exists as a run: it grows through an act, empties at the boundary, and
## the day after it empties is the day the rule protects the most ground. The exemptions are named
## rather than inferred — an `AMBIENT` event is a permanent feature of the map and a scar already
## burnt, and both are why a park can still be *contested*.
func _test_calm_she_has_not_used_is_left_alone(t) -> void:
	for run_seed in [4242, 90210, 1234567]:
		var map := CityGenerator.generate(run_seed)
		var used_this_act: Array[Vector2i] = []
		var act := 0
		var consumed: Array[String] = []
		for day in range(1, 15):
			if Tuning.act_for_day(day) != act:
				act = Tuning.act_for_day(day)
				used_this_act = []
			var planned := EventScheduler.build_day(day, _rng(day), map, consumed, [],
					used_this_act)
			for block in map.calm_blocks:
				if used_this_act.has(block):
					continue
				var lot := map.tile_rect_to_world(_calm_rect(map, block))
				for plan in planned:
					if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
						continue
					if plan.permanent:
						continue
					t.check(not _reaches(plan, lot),
							"seed %d day %d: %s is not near the unused calm at %s"
							% [run_seed, day, plan.def.id, block])
			used_this_act.append(_quietest_calm_block(map, planned))

## Whether a plan's field reaches a rect — mirrors `EventScheduler._reaches_rect`.
func _reaches(plan, rect: Rect2) -> bool:
	var grown := rect.grow(plan.def.outer_radius)
	if grown.has_point(plan.position):
		return true
	for point in plan.path:
		if grown.has_point(point):
			return true
	return false

## The calm ground of a calm block — mirrors `EventScheduler._calm_rect`, which is the
## definition the guarantee is actually written over.
func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var layout: BlockLayout = map.block_layouts.get(block)
	if layout and BlockLayout.has(layout.open_rect):
		return layout.open_rect
	return CityMap.block_rect(block)

# -------------------------------------------------------------- act I content ---

func _test_successors_resolve(t) -> void:
	for def in EventCatalogue.all():
		if def.spawns_on_finish == "":
			continue
		t.check(EventCatalogue.by_id(def.spawns_on_finish) != null,
				"'%s' spawns '%s', which exists in the catalogue"
				% [def.id, def.spawns_on_finish])

## It has no scheduled day at all, so nothing but the fire engine can put one in the world.
func _test_burning_building_is_never_scheduled(t) -> void:
	var fire := EventCatalogue.by_id("burning_building")
	t.check(fire != null, "the burning building exists")
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(not fire.available_on(day),
				"the burning building is not schedulable on day %d" % day)

func _test_fire_truck_is_a_day_three_one_shot(t) -> void:
	var truck := EventCatalogue.by_id("fire_truck")
	t.check(truck.kind == GameEnums.EventKind.ONE_SHOT, "the fire engine is a one-shot")
	t.check(not truck.available_on(2), "the fire engine cannot come on day 2")
	t.check(truck.available_on(3), "the fire engine can come on day 3")
	t.check(not truck.available_on(4), "the fire engine never comes again")

	# It outruns a walk, so the fairness rule must demand the full radius of clearance.
	t.check(truck.speed > Tuning.WALK_SPEED, "the fire engine is faster than walking")
	t.close_to(truck.minimum_telegraph(), truck.outer_radius / Tuning.WALK_SPEED,
			"a fast mover must be clearable across its whole radius, not just its band")
	t.check(truck.telegraph_time >= truck.minimum_telegraph(),
			"the fire engine gives that much warning")

	# A dog walker is slower than walking, so the ordinary band rule applies to it.
	var dog := EventCatalogue.by_id("dog_walker")
	t.check(dog.speed < Tuning.WALK_SPEED, "the dog walker is slower than walking")
	t.close_to(dog.minimum_telegraph(), (dog.outer_radius - dog.inner_radius) / Tuning.WALK_SPEED,
			"a slow mover can simply be walked away from")

func _test_along_street_paths_stay_in_bounds(t) -> void:
	var map := _map()
	var extent := map.world_size()
	for day in range(1, 15):
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed):
			if plan.def.path_mode != EventDef.PathMode.ALONG_STREET:
				continue
			t.check(plan.path.size() == 2, "an along-street route has two waypoints")
			# The route must not finish jammed against the boundary along the axis it
			# travels: a fire engine that always stops at the wall leaves its fire there
			# too. The perpendicular axis is wherever it was placed and is not our business.
			var margin := float(CityMap.period() * Tuning.TILE_SIZE) * 0.5
			var finish: Vector2 = plan.path[1]
			var travel: Vector2 = plan.path[1] - plan.path[0]
			var along_x := absf(travel.x) > absf(travel.y)
			var at_end := finish.x if along_x else finish.y
			var limit := extent.x if along_x else extent.y
			t.check(at_end > margin and at_end < limit - margin,
					"day %d: '%s' route ends inside the city along its travel axis"
					% [day, plan.def.id])
			for point in plan.path:
				t.check(point.x >= 0.0 and point.y >= 0.0
						and point.x <= extent.x and point.y <= extent.y,
						"day %d: '%s' route stays inside the map" % [day, plan.def.id])
			# The route runs along one axis, never diagonally across blocks.
			var delta: Vector2 = plan.path[1] - plan.path[0]
			t.check(is_zero_approx(delta.x) or is_zero_approx(delta.y),
					"day %d: '%s' route follows a single corridor" % [day, plan.def.id])

# ------------------------------------------------------- what a street costs (M19) ---

## Events that are deliberately scenery: they are there so the street *looks* different, not
## so it costs something. Everything else has to cost something to walk through — an obstacle
## that is cheaper to walk into than to walk around is a bribe, and the player learns to take
## it. Naming them explicitly is the point: one more has to be a decision.
##
## **Down to one row in playtest 07.** `falloff`'s new shoulder lifted `poster_crew` to +0.7 and
## `barricade` to +3.0, so neither needs the exemption any more — both are still nearly free to
## walk through, which is all the design ever asked of them. A burnt-out shell is the last row
## that is genuinely cheaper to walk through than around, and it is a reminder rather than an
## obstacle. (`loudspeaker` is `city_wide` and has no line to walk through at all.)
const _SCENERY := ["burnt_shell"]

## Net excitement from walking straight through the centre of an event at walking pace, in
## points of a hundred-point meter. This is what produced the table in docs/EVENTS.md, and the
## measurement behind playtest 02's finding 7.
##
## **It lives on `EventDef` since M39** and this is a one-line forwarder. The game itself now asks
## the question — the danger caret is raised by what a row costs — and two implementations of a
## number the vocabulary depends on is exactly the defect M37 found in `DangerEdge`: a second table
## of which picture a look meant, and a fire engine drawn as a delivery van. A test that keeps its
## own copy would go on passing while the game used a different one.
func _cost_to_walk_through(def: EventDef) -> float:
	return def.walk_through_cost()

## The same integral at running pace, with the running penalty in place of the walking decay.
func _cost_to_run_through(def: EventDef) -> float:
	var seconds := def.outer_radius * 2.0 / Tuning.RUN_SPEED
	return (def.mean_emission_along_the_line() - Tuning.EXCITEMENT_DECAY_RUNNING
			+ Tuning.EXCITEMENT_FROM_RUNNING) * seconds

## **Running is wrong against everything you route around, and right against the thing that
## follows.** Two halves of one rule, and playtest 07 is where the second half arrived: *"the run
## button is a trap shouldn't be an invariant — there should be legitimate cases where running is
## required."*
##
## The first half is the older decision and it still holds for every row but one. An event that
## merely emits is a *place*; the answer to a place is a route, and `EXCITEMENT_FROM_RUNNING`
## outweighs the shorter exposure every time, so sprinting through one is strictly worse than
## walking through it. That had never been asserted — only measured and written into a document —
## and playtest 07 is what that cost: `falloff`'s new shoulder makes time-in-field matter more, and
## running quietly became a point or two *cheaper* than walking through the four widest fields in
## the game. Not "running works" but "running is a coin flip", which was nobody's design.
##
## The second half is why an exception has to be a **mechanic** rather than a number. A pursuer
## cannot be routed around, because it goes where she goes, so the only question it asks is how
## fast — and the two answers give opposite outcomes rather than the same outcome at two prices.
## `Tuning.validate_pursuit` is the contract and it runs on load; this is the part of it that is
## about the *catalogue* rather than about one row.
func _test_running_is_the_answer_to_exactly_one_kind_of_thing(t) -> void:
	var pursuers := 0
	for def in EventCatalogue.all():
		if def.city_wide:
			continue   # No line through it, so no crossing to compare.
		if def.pursues:
			pursuers += 1
			# Walking loses ground and running gains it. Everything else about a pursuit follows
			# from this one line, including why it is the only place running can be correct.
			t.check(def.pursue_speed > Tuning.WALK_SPEED,
					"'%s' catches somebody who walks away from it" % def.id)
			t.check(def.pursue_speed < Tuning.RUN_SPEED,
					"'%s' does not catch somebody who runs" % def.id)
			t.check(def.hard_fail,
					"'%s' has to be lethal, or running from it is just an expensive walk" % def.id)
			t.check((Tuning.RUN_SPEED - def.pursue_speed) * def.duration >= def.inner_radius,
					"'%s' can be outrun by more than the radius that ends the day" % def.id)
			t.check(def.duration <= Tuning.PURSUIT_TIME,
					"'%s' gives up before the run costs more than the day it saves" % def.id)
			continue
		t.check(_cost_to_run_through(def) > _cost_to_walk_through(def),
				"running through '%s' (%.1f) costs more than walking (%.1f)"
				% [def.id, _cost_to_run_through(def), _cost_to_walk_through(def)])
	t.check(pursuers > 0, "and there is something in the game that running is the answer to")

## *(Playtest 07: "on day 3 we introduce the running key (it is possible to run before but not
## required)" and "so on day 1 we only introduce arrow keys".)*
##
## The two halves of that are a gate and a promise, and both are properties of the catalogue
## rather than of any one day's rolls, so they are checked here rather than left to a playtest.
func _test_nothing_chases_her_before_the_run_is_taught(t) -> void:
	for day in range(1, Tuning.RUN_TAUGHT_DAY):
		for def in EventCatalogue.available_on(day):
			t.check(not def.pursues,
					"day %d has nothing that has to be outrun ('%s')" % [day, def.id])
	var chasers := 0
	for def in EventCatalogue.available_on(Tuning.RUN_TAUGHT_DAY):
		chasers += 1 if def.pursues else 0
	t.check(chasers > 0, "and the day the run is taught has something to teach it with")

## The measured failure playtest 02 found and M19 fixes: at intensity 7 the dog walker cost
## −0.1 points to walk straight through, so the correct play was to plough into it.
func _test_nothing_is_cheaper_to_walk_through_than_around(t) -> void:
	for def in EventCatalogue.all():
		if def.city_wide or def.intensity <= 0.0 or def.id in _SCENERY:
			continue
		t.check(_cost_to_walk_through(def) > 0.0,
				"walking through '%s' costs more than walking around it (%.1f)"
				% [def.id, _cost_to_walk_through(def)])
	# And the specific one, stated as itself so the reason survives a rebalance.
	var dog := EventCatalogue.by_id("dog_walker")
	t.check(_cost_to_walk_through(dog) > Tuning.EXCITEMENT_CALM_THRESHOLD * 0.4,
			"a dog walker is a real reason to cross the street (%.1f of a %.0f freeze)"
			% [_cost_to_walk_through(dog), Tuning.EXCITEMENT_CALM_THRESHOLD])

## Playtest 02, finding 3: *"there should be things that force me to cross the street."*
## Day one included — decision 9 says the beginning is challenging too, and until M19 the
## first event that was physically in the way arrived on day 2.
func _test_the_pavement_can_be_blocked_from_day_one(t) -> void:
	var blockers: Array[EventDef] = []
	for def in EventCatalogue.available_on(1):
		if def.obstructs_radius > 0.0 and def.placement.has(GameEnums.TileType.SIDEWALK):
			blockers.append(def)
	t.check(not blockers.is_empty(),
			"something can be in the way of a pavement on day 1")
	# Sidewalk is two tiles; an obstruction wider than that would seal the pavement outright
	# rather than making it the wrong side of the street.
	for def in blockers:
		t.check(def.obstructs_radius * 2.0 < Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 2.0,
				"'%s' takes the pavement without sealing the street" % def.id)
		t.check(not def.mobile,
				"'%s' does not walk toward her: a moving wall on a two-tile pavement pins"
				% def.id)

## Playtest 03, finding 1: day 1 placed four events across a 7x7-block city and the traced
## player met none of them. Playtest 05, finding 6, made it a number: **one event per block**.
##
## The budget is checked against what a day actually *places*, not against the formula, because
## a budget the catalogue cannot spend is not density — which is exactly what M28 found: the
## day-1 pool's `max_per_day` values summed to 18, so the budget could be anything at all and
## the day still held thirteen events.
func _test_a_day_has_enough_in_it_to_meet(t) -> void:
	var map := _map()
	var blocks := Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y
	for day in [1, 3, 7, 14]:
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
		var real := 0
		for plan in planned:
			if plan.def.kind != GameEnums.EventKind.AMBIENT:
				real += 1
		# Stated as a fraction of a block each way rather than as a count, so it survives the
		# city changing size — which M21 is about to do.
		t.check(real >= blocks * 4 / 5,
				"day %d puts %d events across %d blocks — about one each"
				% [day, real, blocks])
	t.check(EventScheduler.budget_for(14) > EventScheduler.budget_for(1) * 3 / 2,
			"and a late day is still markedly denser than an early one")

## Playtest 05, finding 5: *"day two doesn't feel more difficult than day one. Having day one
## relatively easy is okay if the difficulty increases. But right now there is never any
## danger."* It was true by construction and this is the construction, asserted.
##
## Two claims, and they are the two halves of the finding. **Danger exists before day 8** — it
## used to start there and nothing lethal was reachable before it. And **the escalation is a
## change of kind rather than of count**: day 1 has nothing that can end the day, day 2 does.
## A budget that goes up by two events is not something a person can feel; the first day the
## streets acquire something lethal is.
##
## Deliberately not asserted: that day 1 is safe *forever*. If a later milestone wants a lethal
## thing on day 1 that is a decision somebody takes, and this test is where they will find out
## they are taking it.
func _test_danger_arrives_before_act_three(t) -> void:
	var map := _map()
	var lethal_on := {}
	for day in range(1, 15):
		var consumed: Array[String] = []
		var count := 0
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed):
			if plan.def.hard_fail:
				count += 1
		lethal_on[day] = count

	t.check(int(lethal_on[1]) == 0,
			"day 1 has nothing that can end the day (%s)" % lethal_on[1])
	t.check(int(lethal_on[2]) > 0,
			"and day 2 does, which is an escalation a person can feel (%s)" % lethal_on[2])
	for day in range(3, 15):
		t.check(int(lethal_on[day]) > 0, "day %d keeps something lethal on the map" % day)

	# The catalogue half of the same claim, stated over the rows rather than over one seed's
	# plan: something lethal has to be *available* in act I at all, which is what was wrong.
	var early: Array[String] = []
	for def in EventCatalogue.available_on(2):
		if def.hard_fail:
			early.append(def.id)
	t.check(not early.is_empty(),
			"act I has lethal events in its pool by day 2 (%s)" % ", ".join(early))
	# And they are fair, which for a lethal thing is the doubled margin. `validate()` covers the
	# whole catalogue; this names the new ones so a rebalance cannot quietly break act I only.
	for id in early:
		var def := EventCatalogue.by_id(id)
		t.check(def.telegraph_time >= def.minimum_telegraph(),
				"'%s' telegraphs for %.2fs against a required %.2fs"
				% [id, def.telegraph_time, def.minimum_telegraph()])

## The caps have to leave room for the density, or the budget is decoration. Stated over the
## day-1 pool because that is where it was actually wrong: three dog walkers and three cafés
## on a forty-nine-block city, of which only the ~23% near her is ever instantiated.
func _test_the_caps_can_spend_the_budget(t) -> void:
	var blocks := Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y
	var ceiling := 0
	for def in EventCatalogue.available_on(1):
		if def.kind == GameEnums.EventKind.RECURRING:
			ceiling += def.max_per_day
	t.check(ceiling >= blocks,
			"day 1's caps allow at least one event per block (%d against %d)" % [ceiling, blocks])

## The two events playtest 05 named, and the reason it named them: the dog-walker decision
## has to arrive more than once, and the café that exists to force a crossing has to be
## findable at all. Both are counted over the whole map, since what she meets on a route is
## a fraction of it.
##
## Stated as a **per-seed floor plus an average** since M31, and the reason is worth keeping:
## the density is a fixed number of events, so every row added to the day-1 pool takes a share
## of it. Seven new rows arrived at once and these two thinned out immediately. Their weights
## went *up* to compensate — dog walkers and café frontages are what an ordinary street is
## mostly made of — but a single total across three seeds is a tight enough sample to fail on
## noise, which it did, at 17 against a bar of 18.
func _test_the_named_decisions_arrive(t) -> void:
	var map := _map()
	var totals := {}
	var seeds := [4242, 77, 1301]
	for city_seed in seeds:
		var seeded := CityGenerator.generate(city_seed)
		var consumed: Array[String] = []
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:1" % city_seed)
		var counts := {}
		for plan in EventScheduler.build_day(1, rng, seeded, consumed):
			counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
			totals[plan.def.id] = int(totals.get(plan.def.id, 0)) + 1
		# No day-1 map may be without either of them at all, which is the failure the player
		# actually reported: *"a restaurant — I never saw one."*
		t.check(int(counts.get("dog_walker", 0)) >= 4,
				"seed %d: day 1 carries %s dog walkers"
				% [city_seed, counts.get("dog_walker", 0)])
		t.check(int(counts.get("cafe_tables", 0)) >= 2,
				"seed %d: day 1 carries %s cafés" % [city_seed, counts.get("cafe_tables", 0)])
	t.check(totals.get("dog_walker", 0) >= seeds.size() * 7,
			"day 1 averages enough dog walkers to meet two on a route (%s over three seeds)"
			% totals.get("dog_walker", 0))
	t.check(totals.get("cafe_tables", 0) >= seeds.size() * 5,
			"day 1 averages enough cafés to find one (%s over three seeds)"
			% totals.get("cafe_tables", 0))
	t.check(map.calm_blocks.size() > 0, "and the map still has calm ground on it")

## What `max_per_day` was quietly doing before M28, now doing it on purpose. The fallback in
## `_roomiest_of_several` can still put two of a kind closer than `EVENT_SPACING_SAME` on a
## full map, so this is stated as "almost never" plus a hard floor that nothing may cross.
func _test_two_of_a_kind_are_not_the_same_incident(t) -> void:
	var map := _map()
	for day in [1, 8, 14]:
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
		var same_pairs := 0
		var crowded := 0
		for i in planned.size():
			for j in range(i + 1, planned.size()):
				var a: EventScheduler.Planned = planned[i]
				var b: EventScheduler.Planned = planned[j]
				if not a.is_placed() or not b.is_placed():
					continue
				if a.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				if b.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				var gap := a.position.distance_to(b.position)
				t.check(gap >= Tuning.EVENT_SPACING_ANY - 0.5,
						"day %d: '%s' and '%s' are not drawn inside each other (%.0fpx)"
						% [day, a.def.id, b.def.id, gap])
				if a.def.id != b.def.id:
					continue
				same_pairs += 1
				if gap < Tuning.EVENT_SPACING_SAME:
					crowded += 1
		t.check(crowded * 20 <= same_pairs,
				"day %d: %d of %d same-kind pairs share a stretch of pavement"
				% [day, crowded, same_pairs])

## Playtest 05's first named risk: the fairness contract is stated per event and the player
## experiences the sum, so at one event per block walking out of one field can mean walking
## into another. Survivable for everything that only costs points, and a death for the rows that
## end the day — so a lethal field has nothing else in it. Unlike the other spacing rules this one
## has no fallback, which is why it is asserted absolutely.
##
## **And since M50 it is absolute over the ground she is being guided along, which is where the
## argument for it was always stated.** *(2026-08-31, agreed with the player: "areas that outside
## the paths should have blocking events all over… it ranges from very costly to deadly", and,
## asked which of the two had to give, "exempt the off-corridor ground from it".)* The reason the
## rule exists is that a death should not arrive out of a field she was already reading **on a route
## she is meant to take**; off the corridor there is no such route, the whole point of the ground is
## that she should not be on it, and overlapping lethal fields are the city saying so. Six lethal
## rows capped at three to five could not have tiled anything under the old rule.
##
## So the assertion splits rather than weakening: a lethal **wall** is exempt, and everything else —
## a lethal set piece, a lethal row the day placed for a reason that is not about the corridor — is
## checked exactly as before. `EventScheduler._keeps_its_field_clear` is the one place that decides,
## and this asserts its consequence rather than restating it.
func _test_nothing_happens_inside_a_lethal_field(t) -> void:
	var map := _map()
	var lethal_days := 0
	var exempt := 0
	for day in range(1, 15):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
		for plan in planned:
			if not plan.def.hard_fail or not plan.is_placed():
				continue
			if plan.role == GameEnums.BlockerRole.WALL:
				exempt += 1
				continue
			lethal_days += 1
			for other in planned:
				if other == plan or not other.is_placed():
					continue
				if other.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				t.check(other.distance_from(plan.position) >= plan.def.outer_radius,
						"day %d: nothing shares '%s'’s lethal field ('%s' at %.0fpx of %.0f)"
						% [day, plan.def.id, other.def.id,
						other.distance_from(plan.position), plan.def.outer_radius])
	# The exemption is not a way of asserting nothing: a run has to contain lethal placements of
	# both kinds, or this test passes on a day with no lethal rows in it at all.
	t.check(exempt > 0, "a run places lethal walls, which are the exempt ones (%d)" % exempt)
	t.check(lethal_days >= 0, "and the rest are checked (%d)" % lethal_days)

## **The third case of the clearance rule, pinned over `pursues` rather than over either row that
## carries it today.** A lethal field that follows her is neither on the corridor nor off it, so
## placement cannot keep it clear of anything — `charging_dog` never reaches `_room_around` at
## all (it is `AHEAD_OF_PLAYER`, sited with no tile) and `alley_robbery` is exempt today only
## because `hard_fail` always classifies a `MAP`-placed `RECURRING`/`SCRIPTED` row `WALL` before
## `_role_for` ever asks whether it pursues. Forcing the role off `WALL` here is what tells the two
## reasons apart, and it is why a third pursuer — one a future `_role_for` change routes through
## `SET_PIECE` or `FRICTION` instead — inherits the exemption without anybody adding a case for it.
func _test_a_pursuer_keeps_no_field_clear(t) -> void:
	var pursuer := EventCatalogue.by_id("alley_robbery")
	t.check(pursuer.hard_fail and pursuer.pursues, "alley_robbery is lethal and pursues")
	var off_wall := EventScheduler.Planned.new(pursuer, Vector2.ZERO)
	off_wall.role = GameEnums.BlockerRole.FRICTION
	t.check(not EventScheduler._keeps_its_field_clear(off_wall),
			"a lethal pursuer keeps nothing clear even when it is not classified a wall")

	# The control: an otherwise identical lethal row that does not pursue still owes the rule off
	# the `WALL` role — the exemption is `pursues`, not "the role happens not to be WALL".
	var stationary := EventCatalogue.by_id("reversing_lorry")
	t.check(stationary.hard_fail and not stationary.pursues,
			"reversing_lorry is lethal and does not pursue, the contrast this needs")
	var off_wall_stationary := EventScheduler.Planned.new(stationary, Vector2.ZERO)
	off_wall_stationary.role = GameEnums.BlockerRole.FRICTION
	t.check(EventScheduler._keeps_its_field_clear(off_wall_stationary),
			"and a lethal row that does not pursue keeps its field clear off the WALL role too")

## Playtest 05, finding 4: *"I was able to go to the same park on day one and two — this
## shouldn't be possible."* The complaint is not about repetition, it is that the game's only
## verb stopped being a decision on day two.
##
## Three things are checked, and the third is the one that makes it fair rather than punishing:
## the park she used gets something in it, the day still guarantees a *different* usable one,
## and what gets put there can never take the day or the ground away.
func _test_the_city_remembers_where_she_went(t) -> void:
	var map := _map()
	t.check(map.calm_blocks.size() >= 2,
			"the map has calm ground to choose between (%d blocks)" % map.calm_blocks.size())

	var used: Vector2i = map.calm_blocks[0]
	var used_set: Array[Vector2i] = [used]
	var lot := map.tile_rect_to_world(_calm_rect(map, used))
	var allowed := maxf(Tuning.OBSTRUCTION_A_PARK_CAN_HOLD,
			minf(lot.size.x, lot.size.y) / 16.0)
	var spoiled_days := 0
	for day in range(2, 15):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed, [], used_set)

		var on_her_park := 0
		var clean_elsewhere := 0
		for block in map.calm_blocks:
			var here := map.tile_rect_to_world(_calm_rect(map, block))
			var spoilers := 0
			for plan in planned:
				if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
					continue
				if here.grow(plan.def.outer_radius).has_point(plan.position):
					spoilers += 1
			if block == used:
				on_her_park = spoilers
			elif spoilers == 0:
				clean_elsewhere += 1
		if on_her_park > 0:
			spoiled_days += 1
		t.check(clean_elsewhere >= 1,
				"day %d still leaves a *different* calm block clean" % day)

		# Nothing sitting in yesterday's park may end the day or close the ground: she has to be
		# able to see it from the street and walk away, which is what keeps it from being a
		# punishment for having played well.
		#
		# "Close the ground" is the test, not "have a body at all" — the two were the same thing
		# until M34 made everything that stands still solid, and reading it as the stricter one
		# would have emptied the pool of loud harmless things and retired this rule by accident.
		# A busker is 22px of a 704px lot. See `Tuning.OBSTRUCTION_A_PARK_CAN_HOLD`.
		#
		# And the allowance is the lot's, not a constant: `_things_to_put_in_a_park` lets a
		# bigger park hold a bigger thing, because what matters is the share of the ground it
		# takes. Asserting the constant instead passed for as long as `calm_blocks[0]` happened
		# to be a single block, and failed the day a city had enough calm areas for a four-block
		# zone to come first — which is the test restating a rule the scheduler owns rather than
		# asking it.
		for plan in planned:
			if not plan.is_placed() or not lot.has_point(plan.position):
				continue
			t.check(not plan.def.hard_fail and plan.def.obstructs_radius <= allowed,
					"day %d puts '%s' in her park, which is loud rather than lethal"
					% [day, plan.def.id])

	t.check(spoiled_days >= 10,
			"the park she used yesterday is reliably spoiled (%d of 13 days)" % spoiled_days)

	# And a day that knows nothing about yesterday plans exactly as it always did.
	var forgetful: Array[String] = []
	var remembering: Array[String] = []
	var a := EventScheduler.build_day(3, _rng(3), map, forgetful)
	var nothing: Array[Vector2i] = []
	var b := EventScheduler.build_day(3, _rng(3), map, remembering, [], nothing)
	t.check(_signature(a) == _signature(b),
			"and a day with nothing to remember is unchanged by the rule")

	# The whole run, played the way a player plays it: settle in the quietest calm block, and
	# the next day is planned knowing that. Measured over five seeds while this was built, the
	# repeat rate goes from 28% of days to 0 — this asserts the claim rather than the number.
	# Since playtest 12 the memory is the whole **act**, not the night before, so this walks the
	# run the way `GameState.settled_this_act` does: the used set grows through an act and is
	# emptied at the boundary. A day must send her somewhere she has not been this act.
	var used_this_act: Array[Vector2i] = []
	var act := 0
	for day in range(1, 15):
		if Tuning.act_for_day(day) != act:
			act = Tuning.act_for_day(day)
			used_this_act = []
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed, [], used_this_act)
		var quietest := _quietest_calm_block(map, planned)
		t.check(not used_this_act.has(quietest),
				"day %d sends her somewhere she has not used this act" % day)
		used_this_act.append(quietest)

## The calm block with the least reaching it — the one a player would find and settle in.
func _quietest_calm_block(map: CityMap, planned: Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var fewest := 1 << 30
	for block in map.calm_blocks:
		var lot := map.tile_rect_to_world(_calm_rect(map, block))
		var spoilers := 0
		for plan in planned:
			if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
				continue
			if lot.grow(plan.def.outer_radius).has_point(plan.position):
				spoilers += 1
		if spoilers < fewest:
			fewest = spoilers
			best = block
	return best

# ------------------------------------------------- solid things are solid (M34) ---
# Playtest 07, findings 16 and 13: *"none of the non-moving obstacles do anything — I can freely
# walk over them"*, and *"I can walk over the robber and he doesn't do anything"*. The answer is
# a rule rather than a list of rows, and these are the three ways it can quietly stop being one.

## **Anything that stands still is solid.** Every exemption is named here rather than left to be
## inferred from a zero, because the failure this catches is the one that happened: a field that
## is only set where somebody remembered to set it, on five rows out of thirty, for six
## milestones.
func _test_everything_that_stands_still_is_solid(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		# A moving wall pins her against a building on a two-tile pavement, which is a different
		# game from being priced out of a street. See `dog_walker`.
		if def.mobile or def.pursues:
			continue
		# Nothing checks that a thing sited out of where she happens to be walking leaves a route
		# to a park, so `EventDef.validate()` refuses a body on one outright.
		if def.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER:
			continue
		# Nothing drawn, nothing to bump into: a city-wide announcement, a playground the park
		# itself draws.
		if def.city_wide or def.look == EventDef.Look.NONE:
			continue
		checked += 1
		t.check(def.obstructs_radius > 0.0,
				"'%s' stands still, so it is solid" % def.id)
	t.check(checked >= 15,
			"and the rule covers most of the catalogue (%d rows)" % checked)

## **A lethal radius and a solid body are the same mechanism**, so an event carrying both can
## turn its own kill off. She is stopped `obstructs_radius + PLAYER_BODY_RADIUS` from the centre;
## if that reaches the inner radius, no amount of carelessness ever ends the day there.
##
## This is `alley_robbery`'s bug in the abstract: at an inner radius of 22 against a man 11 wide,
## the pram would have been held three pixels outside the thing that takes the baby.
func _test_a_lethal_thing_can_still_be_reached(t) -> void:
	var lethal := 0
	for def in EventCatalogue.all():
		if not def.hard_fail or def.obstructs_radius <= 0.0:
			continue
		lethal += 1
		t.check(def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS < def.inner_radius,
				"'%s' is solid to %.0f and lethal inside %.0f, so touching it still ends the day"
				% [def.id, def.obstructs_radius, def.inner_radius])
	t.check(lethal > 0, "and there are lethal solid things to check")

## `Tuning.PLAYER_BODY_RADIUS` is a copy of a number authored in the player's scene, and the rule
## above is arithmetic on it. A copy nothing checks is a lie waiting to happen.
func _test_the_pram_is_the_size_the_rules_think_it_is(t) -> void:
	var scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var stroller: Node = scene.instantiate()
	var shape := (stroller.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
	t.check(shape != null and is_equal_approx(shape.radius, Tuning.PLAYER_BODY_RADIUS),
			"the pram's own body is PLAYER_BODY_RADIUS (%.1f in the scene, %.1f in Tuning)"
			% [shape.radius if shape else -1.0, Tuning.PLAYER_BODY_RADIUS])
	stroller.free()

## Playtest 07, finding 7: *"there is also a car obstacle on the road that is basically a still
## car standing on the road doing nothing."* A parked van belongs against a kerb — on the
## pavement she is walking down, and out of a traffic lane the crowd drives straight through.
func _test_a_parked_van_is_at_the_kerb(t) -> void:
	var map := _map()
	var parked := 0
	for day in range(1, 15):
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed):
			if plan.def.pavement_side != EventDef.Pavement.AT_THE_KERB:
				continue
			parked += 1
			var tile := map.world_to_tile(plan.position)
			var inward := map.pavement_inward(tile)
			t.check(inward != Vector2i.ZERO,
					"day %d: '%s' is on a pavement with a kerb on one side" % [day, plan.def.id])
			if inward == Vector2i.ZERO:
				continue
			var beside := map.tile_at(tile - inward)
			t.check(beside == GameEnums.TileType.ROAD or beside == GameEnums.TileType.CROSSING,
					"day %d: '%s' has the carriageway on the other side of it (%d)"
					% [day, plan.def.id, beside])
	t.check(parked > 0, "and a run parks something (%d over 14 days)" % parked)

## Playtest 07, finding 15: *"the backing out lorry does not connect to the building making it
## hard to visually read."* The danger is the gap behind a wall of metal, so there has to be a
## wall — and it has to be east or west of it, because the silhouette is drawn side-on.
func _test_a_lorry_has_a_wall_to_back_into(t) -> void:
	var map := _map()
	var backing := 0
	for day in range(3, 15):
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed):
			if plan.def.pavement_side != EventDef.Pavement.AGAINST_THE_BUILDING:
				continue
			backing += 1
			var tile := map.world_to_tile(plan.position)
			var inward := map.pavement_inward(tile)
			t.check(inward != Vector2i.ZERO and inward.y == 0,
					"day %d: '%s' backs into a frontage it can be drawn facing" % [day, plan.def.id])
			if inward == Vector2i.ZERO:
				continue
			t.check(map.tile_at(tile + inward) == GameEnums.TileType.BUILDING,
					"day %d: '%s' has a real building behind it" % [day, plan.def.id])
			# Facing *out* of the wall, so the box end is the end that is in the yard.
			t.check(plan.facing == -Vector2(inward),
					"day %d: '%s' is turned to reverse into it" % [day, plan.def.id])
	t.check(backing > 0, "and a run sites one (%d over days 3-14)" % backing)

## Playtest 11, finding 1: *"events/hazards should not spawn on the home block."* The home is a
## notch with one exit, so the walk from the doorstep to the first junction is the one stretch of
## a day she does not choose to be on — and a thing standing on it is a tax rather than a route
## decision. `ClosurePlanner` has refused to close that same street since M16, for the same reason.
##
## Measured before the exemption, eight seeds over days 1, 3, 7 and 14: **0.47 events a day** stood
## on it, which is one morning in two starting with something on the doorstep. The share is exactly
## the share of the pavement the street is (0.30% of both), which is placement being uniform and is
## why this needed a rule rather than a weighting.
##
## The last two checks are the ones that keep it from passing vacuously: an exemption over ground
## nothing could have stood on is not an exemption, and a day that stopped placing events would
## satisfy the first check perfectly.
func _test_nothing_stands_on_the_doorstep_street(t) -> void:
	var map := _map()
	var home := ClosurePlanner.home_street(map)
	t.check(home != null, "the front door opens onto a street")
	if not home:
		return
	var rect := home.tile_rect()
	var placed := 0
	for day in range(1, 15):
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed):
			if plan.position == Vector2.INF:
				continue   # an `AHEAD_OF_PLAYER` row, sited by the director while she walks
			placed += 1
			t.check(not rect.has_point(map.world_to_tile(plan.position)),
					"day %d: '%s' is not standing on the street she starts the day on"
					% [day, plan.def.id])

	var pavement := 0
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if rect.has_point(tile):
			pavement += 1
	t.check(pavement > 0,
			"and the exempt street is pavement something could otherwise have stood on (%d tiles)"
			% pavement)
	t.check(placed > 14, "and the days it was checked over still place events (%d)" % placed)

# ------------------------------------------------------- one picture per row ---
# *(M37, playtest 07 finding 2: "not sure what that person was supposed to be".)* The vocabulary's
# first row is that **the entity itself carries most of it**, and the catalogue had been quietly
# failing it since M5: five category looks — `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL`, `FIRE` —
# were drawing sixteen of the twenty-eight visible rows between them.
#
# It cost two findings before anybody wrote it down, and neither reads as an art problem. M34
# fixed `alley_robbery` for a complaint about `homeless_yeller`, because a player can only say
# "the robber" and the two drew the same man; and playtest 09 asked *"who is the person killing
# me?"*, which is a question the screen is supposed to answer. So this is two assertions rather
# than a to-do list, for the same reason `obstructs_radius` became a rule in M34: a field that is
# only ever *reached for* is a list wearing a rule's clothes.

## No two rows draw the same picture, and the rows that draw nothing are named.
##
## The `NONE` exemption is spelled out rather than skipped, because `look` has no useful default
## any more — a row that forgets to choose one is invisible, which is the quietest way for an
## event to stop working.
func _test_no_two_rows_draw_the_same_picture(t) -> void:
	# Three rows are legitimately invisible: something else already draws the ground they stand
	# on, or there is nothing to draw because the whole city is inside them.
	var invisible := ["playground", "loudspeaker", "curfew_announce"]
	var owner_of := {}
	for def in EventCatalogue.all():
		if def.look == EventDef.Look.NONE:
			t.check(invisible.has(def.id), "'%s' draws nothing on purpose" % def.id)
			continue
		t.check(not owner_of.has(def.look),
				"'%s' has a picture of its own (else shared with '%s')"
				% [def.id, owner_of.get(def.look, "")])
		owner_of[def.look] = def.id
	for id in invisible:
		var def := EventCatalogue.by_id(id)
		t.check(def != null and def.look == EventDef.Look.NONE,
				"'%s' is still one of the invisible ones" % id)
	t.check(owner_of.size() >= 25,
			"and the catalogue draws %d different things" % owner_of.size())

## And no two of those pictures are the same texture.
##
## The half a `look` field cannot enforce by itself: two looks whose `_draw_*` reach for the same
## sprite are the old failure with more enum rows in front of it. `EventInstance.icon_for()` is
## the one table of what a look *is*, and it is also what the screen-edge badge draws — so this
## asserts the badge can never again show a delivery van for a fire engine.
func _test_every_look_carries_its_own_silhouette(t) -> void:
	var seen := {}
	for def in EventCatalogue.all():
		if def.look == EventDef.Look.NONE:
			continue
		var icon := EventInstance.icon_for(def.look)
		t.check(icon != null, "'%s' has a silhouette a badge could draw" % def.id)
		if not icon:
			continue
		var path := icon.resource_path
		t.check(not seen.has(path),
				"'%s' draws %s, which nothing else draws (else '%s')"
				% [def.id, path.get_file(), seen.get(path, "")])
		seen[path] = def.id

# --------------------------------------------------- placement by role (M50) ---

## The two halves of `EventScheduler._role_for`, checked in one pass over the days because each of
## them costs a whole `build_day` and the suite is already the slowest thing in this project.
##
## **A lethal event is a wall, and a wall is never inside the corridor.** *(`docs/CITY.md`: "hard
## and lethal blockers form the paths — they are the walls… the route is what is left between
## them.")* This is the one absolute in `_copies_of` and it is what the milestone can most easily
## get wrong: a lethal row on the route she is being guided down is not a wall in the wrong place,
## it is the guidance pointing at the thing it exists to point away from.
##
## **Friction is aimed at the route**, which is the other half of the same sentence: *"benign
## blockers go on the route… to make it more challenging."* That one is a **weight** and is
## asserted as a proportion. About a third of the ground is on the corridor, so an unweighted day
## lands about a third of its costly rows there — measured at 34% with `EVENT_CORRIDOR_WEIGHT`
## flattened to 1, against 64% at 4. Half is a floor with room in it rather than a measurement, and
## the upper bound matters as much: a corridor carrying nearly all of it would mean every street
## off the route is empty, which reads as a set rather than as a city.
##
## An `AHEAD_OF_PLAYER` row is exempt from the first half and the exemption is the design rather
## than a hole: the charging dog is sited by `EventDirector` in front of wherever she turns out to
## be walking, so it is by construction on her route and the scheduler never chose a tile for it.
## That is why `_role_for` calls it `NONE` — see the note there.
##
## Five days rather than fourteen. What is being checked is a property of the construction, and the
## days are sampled across the acts so that the catalogue's lethal rows (none before day 5) and its
## late density are both in the sample.
func _test_the_day_is_placed_by_role(t) -> void:
	var map := _map()
	var walls := 0
	var friction_on_the_route := 0
	var friction := 0
	var deep := {true: 0, false: 0}
	var placed := {true: 0, false: 0}
	# Every gap of every day sampled, and which of them a wall was put in. Keyed by day as well as
	# by street, because the same street is a gap on one day and ordinary ground on another.
	var gaps := {}
	var gaps_walled := {}
	for day in [1, 5, 8, 11, 14]:
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var corridor := Corridor.of(tree)
		for key in tree.gaps():
			gaps["%d:%s" % [day, key]] = true
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
			if not plan.is_placed():
				continue
			var tile := map.world_to_tile(plan.position)
			var away := corridor.depth(tile)
			if plan.role == GameEnums.BlockerRole.WALL and corridor.is_in_a_gap(tile):
				var segment := StreetNetwork.segment_containing(tile)
				if segment:
					gaps_walled["%d:%s" % [day, segment.key()]] = true
			if plan.role == GameEnums.BlockerRole.WALL:
				walls += 1
				t.check(plan.def.hard_fail
						or plan.def.walk_through_cost() >= Tuning.WALL_WORTH_OF_COST,
						"day %d: '%s' is a wall because it is very costly or worse"
						% [day, plan.def.id])
				t.check(away > 0, "day %d: the wall '%s' at %s is off the corridor"
						% [day, plan.def.id, TelemetryLog.tile(tile)])
				placed[plan.def.hard_fail] += 1
				if away >= 2:
					deep[plan.def.hard_fail] += 1
			elif plan.role == GameEnums.BlockerRole.FRICTION:
				friction += 1
				if away == 0:
					friction_on_the_route += 1
	# A sample with no walls in it would pass every assertion above and mean nothing.
	t.check(walls > 20, "the days sampled place walls at all (%d)" % walls)
	t.check(friction > 0, "and friction at all (%d)" % friction)
	var share := float(friction_on_the_route) / maxf(1.0, float(friction))
	t.check(share > 0.45, "%d of %d costly rows are on the corridor" % [friction_on_the_route, friction])
	t.check(share < 0.9, "and the streets off it are not empty (%.0f%% on it)" % (share * 100.0))

	# **The range, as a relationship rather than as two numbers.** *"It ranges from very costly to
	# deadly"* is a claim about which of the two is further from the routes, so that is what is
	# asserted: a day where both bands happened to be equally deep would satisfy any pair of
	# thresholds and would not be a gradient. `dog_walker` staying friction is the other half and is
	# checked where the constant is set — see `Tuning.WALL_WORTH_OF_COST`.
	t.check(placed[true] > 10 and placed[false] > 10,
			"the sample has both kinds of wall in it (%d lethal, %d very costly)"
			% [placed[true], placed[false]])
	var deadly_deep := float(deep[true]) / maxf(1.0, float(placed[true]))
	var costly_deep := float(deep[false]) / maxf(1.0, float(placed[false]))
	t.check(deadly_deep > costly_deep,
			"and the deadly end of the range sits further off the routes than the costly end "
			+ "(%.0f%% against %.0f%% two turnings out)" % [deadly_deep * 100.0, costly_deep * 100.0])

	# **A gap is sometimes closed and sometimes open, and both halves are the instruction.** *(M55,
	# playtest 17 finding 2: "sometimes put a blocker between (wall or event) and sometimes leave it
	# open".)* Asserted as a band rather than a number, because `EVENT_WALL_GAP_WEIGHT` is a weight
	# and the exact share moves with the catalogue — what may not move is that neither end is empty.
	# A day that walled every gap would have turned one corridor into several separate ones, which
	# is the shape `RouteTree` deliberately does not grow; a day that walled none is the finding.
	#
	# **The floor is 0.2 because a precinct is safe ground and a wall is danger.** A precinct's box
	# carries no `ROAD` or `CROSSING` tile, so the rows that place on a carriageway — the patrol, the
	# checkpoint — cannot sit in a gap that runs through one. The `SIDEWALK`-placed rows still can,
	# which is why this is a smaller pool of candidates rather than a gap nothing may ever wall, and
	# why the denominator is still every gap: measured over the same map and the same sampled days,
	# 26 of 89 gaps carried a wall before the precinct's box was paved and 21 of 89 after it — the
	# count of gaps itself does not move, because which segments qualify is `RouteTree`'s business
	# and nothing here touches it. Five gaps, all of them through the one stretch of the city whose
	# design is that it is the safest ground in it. The band is what the check is for; the exact
	# share moves with the catalogue.
	t.check(gaps.size() > 20, "the days sampled have gaps between adjacent strands (%d)" % gaps.size())
	var walled_share := float(gaps_walled.size()) / maxf(1.0, float(gaps.size()))
	t.check(walled_share > 0.2, "%d of %d gaps carry a wall" % [gaps_walled.size(), gaps.size()])
	t.check(walled_share < 0.85,
			"and the rest are left open (%.0f%% walled)" % (walled_share * 100.0))

# -------------------------------------------------------------- chatting_mother (M59) ---
# The one row whose whole mechanic is time under compulsion rather than a field: entering
# `detain_radius` locks the player's own movement input, and what she is charged while it holds
# depends on the baby's state rather than on anything the def can see. An `EventManager` is built
# by hand — nothing here needs a real `City` — and its trigger (`_check_detentions()`) and its
# per-frame handoff (`_tell_them_where_she_is()`) are driven directly, the same shape
# `test_danger.gd` drives `_warn_about_the_ground_she_is_on()` in: a per-frame method with no
# signal of its own to trigger from outside.

## A `WorldContext` whose `total_excitement_at` reads straight off a hand-built `EventManager`,
## the same question `City` answers for real. Lets a real `Baby` be driven against the chat's own
## math without pulling in a whole generated city.
class _ChatWorld extends WorldContext:
	var manager: EventManager
	func total_excitement_at(world_position: Vector2) -> float:
		return manager.total_excitement_at(world_position)

## A manager with nothing in it but the map arithmetic `_check_detentions()`'s own telemetry line
## needs — see `TelemetryObserver._blocked_rig()` in `tests/test_telemetry.gd` for the same trick.
func _chat_manager() -> EventManager:
	var manager := EventManager.new()
	manager._map = CityMap.new()
	return manager

## A bare `Stroller`, in the tree so `_ready()` has run and its `@onready` camera lookup resolves.
func _chat_stroller(t) -> Stroller:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)
	return stroller

func _test_a_conversation_locks_her_and_releases(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(2000.0, 2000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])
	var mother := _instance(t, def, at, path)
	var manager := _chat_manager()
	manager._instances.append(mother)
	var stroller := _chat_stroller(t)
	manager._player = stroller

	stroller.global_position = at
	stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(stroller.is_detained(), "entering detain_radius locks her input")
	t.check(mother.is_chatting(), "and starts the instance's one conversation")

	# Read off `velocity` rather than `global_position`: this rig has no collision shape for
	# `move_and_slide()` to test motion against, and the mechanism under test is entirely in
	# `_physics_process` deciding what `input_dir` is, which `velocity` shows directly.
	Input.action_press("move_right")
	for i in 10:
		stroller._physics_process(STEP)
	t.close_to(stroller.velocity.length(), 0.0,
			"holding a direction through the lock runs velocity out through friction, not held "
			+ "at speed", 1.0)

	for i in 280:
		stroller._physics_process(STEP)
	t.check(stroller.is_detained(), "still locked a few frames before detain_seconds is up")
	t.close_to(stroller.velocity.length(), 0.0, "and stays at rest for the whole lock", 1.0)

	for i in 25:
		stroller._physics_process(STEP)
	Input.action_release("move_right")
	t.check(not stroller.is_detained(), "and releases once detain_seconds has run")
	t.check(stroller.velocity.length() > 10.0,
			"and the same held key moves her again the instant it does")
	mother.free()
	stroller.free()
	manager.free()

func _test_a_conversation_prices_by_the_babys_state(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(3000.0, 3000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])

	for awake in [true, false]:
		var world := _ChatWorld.new()
		t.add_child(world)
		var stroller := Stroller.new()
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		stroller.add_child(camera)
		var baby := Baby.new()
		# Named explicitly: `Stroller`'s own `@onready var _baby := get_node_or_null("Baby")`
		# needs the child present under that exact name before `Stroller._ready()` runs, and a
		# bare `Baby.new()` cannot be relied on to default to it.
		baby.name = "Baby"
		stroller.add_child(baby)
		t.add_child(stroller)
		stroller.set_physics_process(false)
		baby.set_physics_process(false)

		var mother := _instance(t, def, at, path)
		var manager := _chat_manager()
		world.manager = manager
		manager._instances.append(mother)
		manager._player = stroller
		stroller.global_position = at

		if not awake:
			baby.force_sleep()
		var starting_excitement := baby.excitement

		manager._tell_them_where_she_is()
		manager._check_detentions()
		t.check(stroller.is_detained(), "a capture starts whether she is awake or asleep")

		for i in int(round(def.detain_seconds / STEP)) + 5:
			mother._process(STEP)
			manager._tell_them_where_she_is()
			baby._physics_process(STEP)

		if awake:
			t.close_to(baby.excitement, starting_excitement + Tuning.CHAT_EXCITEMENT,
					"an awake conversation adds %.0f points" % Tuning.CHAT_EXCITEMENT, 2.0)
		else:
			t.close_to(baby.excitement, starting_excitement,
					"asleep, the same conversation is a pure time loss: the meter does not move",
					0.5)
			t.close_to(baby.sleepiness, 100.0, "and sleepiness stays pinned at 100 asleep", 0.01)

		mother.free()
		stroller.free()
		world.free()
		manager.free()

func _test_a_conversation_only_starts_inside_detain_radius(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(4000.0, 4000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])
	var mother := _instance(t, def, at, path)
	var manager := _chat_manager()
	manager._instances.append(mother)
	var stroller := _chat_stroller(t)
	manager._player = stroller

	# The far lane of a two-tile pavement — `Tuning.TILE_SIZE` (32px) off, outside `detain_radius`
	# but well inside `inner_radius`, so the ambient field still reaches her and only the
	# conversation must not.
	stroller.global_position = at + Vector2(0.0, Tuning.TILE_SIZE)
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not stroller.is_detained(),
			"passing the far lane, outside detain_radius, never starts a conversation")
	t.check(not mother.is_chatting() and not mother.has_chatted(),
			"and the instance is untouched by it")
	mother.free()
	stroller.free()
	manager.free()

func _test_a_conversation_happens_once_per_instance(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(5000.0, 5000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])
	var mother := _instance(t, def, at, path)
	var manager := _chat_manager()
	manager._instances.append(mother)
	var stroller := _chat_stroller(t)
	manager._player = stroller
	stroller.global_position = at

	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(mother.is_chatting(), "the first approach starts the conversation")

	_advance(mother, def.detain_seconds + 0.1)
	t.check(mother.has_chatted() and not mother.is_chatting() and mother.is_leaving,
			"it ends, and she is spent as a detainer — see 'departs like dog_walker'")

	# The lock from the first approach was never run down by a physics tick here, so it has to be
	# cleared by hand to ask the real question: does *this* call detain her again.
	stroller._detained_for = 0.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not stroller.is_detained(), "a second approach to the same instance never re-triggers")
	mother.free()
	stroller.free()
	manager.free()

# --------------------------------------------------------------- the van's victim ---
# `abduction` draws its own scripted victim rather than touching a real `CrowdAgent` — see
# docs/TODO.md, M56. Drawing and telemetry only, so a data-level rig can drive the whole scene by
# hand: `player_at` is the same write `EventManager` makes every frame in the real game.

## The design's own sentence is that the take "only means anything where she can see it happen" —
## a van she never comes near takes nobody, and it begins the moment she does.
func _test_the_take_begins_only_once_she_is_close(t) -> void:
	var def := EventCatalogue.by_id("abduction")
	var instance := _instance(t, def, Vector2.ZERO)
	instance.player_at = Vector2(def.outer_radius + 40.0, 0.0)
	_advance(instance, 2.0)
	t.check(not instance.is_taking_a_victim(), "outside the field, nothing has started")

	instance.player_at = Vector2(def.outer_radius - 20.0, 0.0)
	instance._process(STEP)
	t.check(instance.is_taking_a_victim(), "and it begins the frame she comes inside it")
	instance.free()

## One telemetry entry, written once — not per frame, and not before the walk actually finishes.
func _test_a_completed_take_is_logged_exactly_once(t) -> void:
	Telemetry.begin_memory_log()
	var def := EventCatalogue.by_id("abduction")
	var instance := _instance(t, def, Vector2.ZERO)
	instance.player_at = Vector2(def.outer_radius - 20.0, 0.0)
	_advance(instance, EventInstance.VICTIM_TAKEN_OVER * 0.5)
	var mid_way := 0
	for line in Telemetry.current_log().lines:
		mid_way += 1 if line.contains("taken") else 0
	t.check(mid_way == 0, "nothing is logged while the walk is still happening")

	_advance(instance, EventInstance.VICTIM_TAKEN_OVER)
	var finished := 0
	for line in Telemetry.current_log().lines:
		finished += 1 if line.contains("taken") else 0
	t.check(finished == 1, "exactly one entry once it completes (%d)" % finished)

	# Long past the completion, the count must not grow — the flag latches rather than re-firing.
	_advance(instance, 5.0)
	var later := 0
	for line in Telemetry.current_log().lines:
		later += 1 if line.contains("taken") else 0
	t.check(later == 1, "and it never logs a second time (%d)" % later)
	instance.free()
	Telemetry.end_run()

# ------------------------------------------------------- the van, once it hunts ---
# `heat_response = HUNTS` turns the same row into a pursuer past `Tuning.HEAT_HUNTS_LEVEL` — see
# docs/EVENTS.md, "The heat". Stated against the fully heated copy, the way `tests/test_heat.gd`'s
# own pursuit tests are.

func _hunting_abduction() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("abduction"), Tuning.RESISTANCE_GOAL)

## A hunting van has other business: the moment it stops waiting, an in-progress take is
## abandoned rather than finished — no victim drawn again, taken or not, and nothing logged for a
## take that never completed.
func _test_a_hunting_van_draws_no_victim(t) -> void:
	Telemetry.begin_memory_log()
	var hot := _hunting_abduction()
	var instance := _instance(t, hot, Vector2.ZERO)
	# Inside the field but outside the trigger, so it is only waiting — the take may begin exactly
	# as it would for a cold van.
	instance.player_at = Vector2(hot.pursues_within + 20.0, 0.0)
	instance._process(STEP)
	t.check(instance.is_taking_a_victim(), "waiting, it takes a bystander exactly like a cold van")

	# Now she comes inside the trigger: it notices her and stops waiting, in the same frame.
	instance.player_at = Vector2(hot.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "she is inside the trigger, so it turns and notices her")
	t.check(not instance.is_taking_a_victim(), "and the take it was running is abandoned")

	_advance(instance, 5.0)
	var entries := 0
	for line in Telemetry.current_log().lines:
		entries += 1 if line.contains("taken") else 0
	t.check(entries == 0, "nothing is ever logged for a take that never finished")
	instance.free()
	Telemetry.end_run()

## Anything that stands still is solid at the width it is drawn, and a hunting van is the first
## row in the catalogue where that stops being true the instant it moves. `_walkable_step`'s own
## note is why a moving pursuer may not keep one: a moving wall on a two-tile pavement pins her
## against a building.
func _test_the_obstruction_comes_down_once_it_stops_waiting(t) -> void:
	var hot := _hunting_abduction()
	var instance := _instance(t, hot, Vector2.ZERO)
	t.check(instance.is_solid(), "a hunting van still parked is solid, exactly like a cold one")

	instance.player_at = Vector2(hot.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "she is inside the trigger, so it stops waiting")
	t.check(not instance.is_solid(), "and the body comes down the same frame")
	instance.free()
