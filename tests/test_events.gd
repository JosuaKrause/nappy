extends RefCounted
## The event system: the fairness contract, the emission model, and the scheduler's
## determinism and safety rules.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_the_rows_she_walks_up_to_pass_positively_awake(t)
	_test_a_row_that_comes_at_her_is_done_telegraphing_when_it_arrives(t)
	_test_catalogue_is_fair(t)
	_test_a_spread_body_fits_the_ground_it_stands_on(t)
	_test_a_kerbed_body_still_pins_the_frontage(t)
	_test_a_spread_rotates_with_the_street(t)
	_test_stationary_vehicles_face_their_street(t)
	_test_a_spread_never_lands_on_a_corner(t)
	_test_a_spread_cap_matches_what_it_obstructs(t)
	_test_a_wide_scene_faces_its_street(t)
	_test_a_crash_is_solid_only_where_its_cars_are(t)
	_test_every_other_row_is_one_body(t)
	_test_telegraph_damps_emission(t)
	_test_pulse_envelope(t)
	_test_the_leaf_blowers_core_is_in_the_meter(t)
	_test_no_other_rows_field_moved(t)
	_test_a_pursuer_leaves_room_to_answer(t)
	_test_the_answer_is_priced_by_how_soon_it_is_given(t)
	_test_a_pursuer_is_sited_where_it_can_be_seen(t)
	_test_a_hard_fail_toward_player_row_is_lethal_by_the_time_it_reaches_her(t)
	_test_a_pursuer_can_wait(t)
	_test_a_pursuer_stops_at_walls(t)
	_test_a_retried_day_is_the_same_day(t)
	_test_the_run_is_always_taught(t)
	_test_a_paced_event_walks_a_beat(t)
	_test_duration_and_finish(t)
	_test_an_event_leaves_rather_than_vanishing(t)
	_test_a_flock_is_birds_rather_than_one_bird_drawn_often(t)
	_test_a_flock_goes_up_when_she_reaches_the_birds(t)
	_test_a_flock_walked_through_stays_in_relation_to_what_else_she_meets(t)
	_test_a_flock_is_a_place_she_can_see(t)
	_test_mobile_follows_its_path(t)
	_test_a_crouching_event_holds_still_until_it_bolts(t)
	_test_the_director_puts_it_in_front_of_her(t)
	_test_the_fire_follows_her_walk_until_it_is_real(t)
	_test_a_corner_is_not_a_change_of_mind(t)
	_test_the_fire_is_the_days_only_unsited_place(t)
	_test_the_engine_parks_at_the_fire(t)
	_test_a_site_that_shuts_her_out_is_refused(t)
	_test_a_rig_meets_the_three_things_that_arrive(t)
	_test_hard_fail_only_when_active(t)
	_test_scheduler_is_deterministic(t)
	_test_scheduler_respects_placement_and_caps(t)
	_test_one_shots_fire_once_per_run(t)
	_test_alley_robbery_never_lands_on_a_required_alley(t)
	_test_the_mouse_crosses_the_alleys_own_short_axis(t)
	_test_the_mouse_waits_until_she_is_near(t)
	_test_one_park_stays_usable(t)
	_test_calm_she_has_not_used_is_left_alone(t)
	_test_successors_resolve(t)
	_test_sighted_successors_resolve(t)
	_test_fire_truck_is_never_scheduled(t)
	_test_the_fire_engine_is_fair_from_the_worst_position_on_the_street(t)
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
	_test_nothing_the_catalogue_places_stands_on_held_ground(t)
	_test_no_two_rows_draw_the_same_picture(t)
	_test_every_look_carries_its_own_silhouette(t)
	_test_the_day_is_placed_by_role(t)
	_test_friction_on_a_sidewalk_can_be_walked_past(t)
	_test_a_pinned_row_is_only_offered_ground_it_can_be_pinned_on(t)
	_test_the_square_poster_crew_only_ever_stands_on_a_square(t)
	_test_a_pacing_row_on_the_routes_sidewalk_can_be_left(t)
	_test_a_routes_junctions_stay_clear(t)
	_test_nothing_takes_the_routes_own_sidewalk(t)
	_test_a_pacing_rows_opening_stays_open(t)
	_test_a_flock_is_scenery(t)
	_test_a_conversation_locks_her_and_releases(t)
	_test_a_conversation_prices_by_the_babys_state(t)
	_test_a_conversation_only_starts_inside_detain_radius(t)
	_test_a_conversation_happens_once_per_instance(t)
	_test_the_take_begins_only_once_she_is_close(t)
	_test_a_completed_take_is_logged_exactly_once(t)
	_test_a_hunting_van_draws_no_victim(t)
	_test_the_obstruction_comes_down_once_it_stops_waiting(t)
	_test_a_protest_stays_something_she_can_be_routed_through(t)
	_test_one_barrier_costs_less_than_the_hold_it_stands_at(t)

# ------------------------------------------------------------------ fairness ---

## **A protest has to stay `FRICTION`, and its intensity sits close enough to the line that this
## is the check rather than a formality.** *(2026-09-20: "also protesters have very little
## excitement?"; "should be a bit more".)* A wide field at a moderate rate loses more of its price
## to the walking decay than a narrow fierce one does, so buying back what the decay took pushes
## `walk_through_cost()` toward `Tuning.WALL_WORTH_OF_COST` — and a `WALL` is given zero copies on
## any cell a route runs along (`EventScheduler._copies_of`), which would put a protest off every
## route a day plans rather than on one she can be sent to walk through.
##
## Not "the intensity is 19.5", which would be the catalogue read back to itself: what would tell
## you something is that the row changed role.
func _test_a_protest_stays_something_she_can_be_routed_through(t) -> void:
	var def := EventCatalogue.by_id("protest")
	t.check(EventScheduler._role_for(def) == GameEnums.BlockerRole.FRICTION,
			"a protest is friction, so the day may put one on a route she walks (%.1f against "
			% def.walk_through_cost() + "the %.1f that makes a wall)" % Tuning.WALL_WORTH_OF_COST)

## **A door's price is the detention, not the field, and that has to stay true of the one source a
## door charges as.** *(2026-09-20: "guard posts should emit less excitement by themselves, too";
## "since there can be other obstacles around".)* Every `EventDef.barrier_structure` row collapses
## to the strongest of them at her position (`EventManager.excitement_sources_at()`), so a hut, a
## gate and a wall's roadblocks at one corner charge one rate between them. What that rate has to
## stay under is the **toll the hold itself charges**: a detention is spent standing still, where
## `Tuning.EXCITEMENT_DECAY_IDLE` is zero and nothing is earned back, so the field bills for every
## second of it on top of `Tuning.CHAT_EXCITEMENT`. Once the field over one hold outweighs the
## toll, the field is what a door costs and the detention is the decoration — which is the
## arrangement the player met coming out of a gate into three roadblocks and a patrol.
##
## The three detainers are already exempt from "nothing is cheaper to walk through than around" for
## exactly this reason, `_PRICED_BY_THEIR_CAPTURE`; this is the same sentence said about the
## strongest thing standing at the same place, which is the one that actually bills her.
func _test_one_barrier_costs_less_than_the_hold_it_stands_at(t) -> void:
	var barriers := 0
	for def in EventCatalogue.all():
		if not def.barrier_structure:
			continue
		barriers += 1
		var over_a_hold := def.intensity * Tuning.CHECKPOINT_DETAIN_SECONDS
		t.check(over_a_hold < Tuning.CHAT_EXCITEMENT,
				("one '%s' bills %.1f over a %.0fs hold at its core rate, under the %.1f the hold "
				+ "itself charges") % [def.id, over_a_hold, Tuning.CHECKPOINT_DETAIN_SECONDS,
				Tuning.CHAT_EXCITEMENT])
	t.check(barriers > 0, "there were barrier structures to ask (%d)" % barriers)

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
	EventDef.Look.ROADWORKS, EventDef.Look.STALL, EventDef.Look.ROADBLOCK,
	EventDef.Look.BARRICADE, EventDef.Look.BURNT_SHELL, EventDef.Look.CAFE,
	EventDef.Look.PROTEST, EventDef.Look.FIREFIGHT,
	EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN,
	EventDef.Look.SCAFFOLDING, EventDef.Look.COLLAPSED_FRONTAGE,
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
## `roadblock` is allowed a far wider body than a sidewalk obstruction is. Nothing re-centres a
## `ROAD`/`CROSSING` body — `CityMap.pavement_inward()` answers zero for either, by design, so
## `_centred_on_the_pavement_band()` leaves them exactly where the scheduler put them.
const _CARRIAGEWAY_SPREAD_CLEARANCE := (Tuning.SIDEWALK_WIDTH + 0.5) * Tuning.TILE_SIZE

## **A body on a pavement has to fit on the pavement — the whole of it, not the lane it happened to
## be planned on.** `_draw_spread` and its cousins draw a body at exactly the width `obstructs_radius`
## says, and `EventInstance.setup()` centres a stationary, unpinned body on the pavement band before
## either the drawing or `_build_obstruction()`'s collision shape ever reads its position — so the
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
##
## **The same blind spot covers every seal-only row** (`fallen_tree`, `car_accident`,
## `skip`, `scaffolding`, `burst_water_main`, `moving_van`, `burnt_out_car`,
## `collapsed_frontage`) — none carries a `def.placement` either, since `SealPlanner` sites them
## directly from the street lattice rather than through `EventScheduler`'s tile pool. Their
## clearance is checked in `tests/test_seals.gd` instead, against the street's own 192px width
## rather than a single tile's, which is the ground they actually stand on.
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

## Stationary seal vehicles use the street axis even though their default facing is right. The van
## faces along it and the burnt car lies across it. Side art fits the circular body's diameter,
## while end art keeps the narrower projection instead of stretching into a square.
func _test_stationary_vehicles_face_their_street(t) -> void:
	var map := CityMap.new()
	var ns_tile := Vector2i(Tuning.STREET_WIDTH / 2, Tuning.STREET_WIDTH + 3)
	var ew_tile := Vector2i(Tuning.STREET_WIDTH + 3, Tuning.STREET_WIDTH / 2)
	t.check(not EventInstance._stationary_vehicle_uses_side(EventDef.Look.MOVING_VAN,
			map, map.tile_to_world(ns_tile), Vector2.RIGHT),
			"a moving van on a north-south street uses its end view")
	t.check(EventInstance._stationary_vehicle_uses_side(EventDef.Look.MOVING_VAN,
			map, map.tile_to_world(ew_tile), Vector2.RIGHT),
			"a moving van on an east-west street uses its side view")
	t.check(EventInstance._stationary_vehicle_uses_side(EventDef.Look.BURNT_OUT_CAR,
			map, map.tile_to_world(ns_tile), Vector2.RIGHT),
			"a burnt car across a north-south street uses its side view")
	t.check(not EventInstance._stationary_vehicle_uses_side(EventDef.Look.BURNT_OUT_CAR,
			map, map.tile_to_world(ew_tile), Vector2.RIGHT),
			"a burnt car across an east-west street uses its end view")
	t.check(EventInstance._stationary_vehicle_uses_side(
			EventDef.Look.MOVING_VAN, null, Vector2.ZERO, Vector2.RIGHT),
			"off-street or data-level placement follows the vehicle's own default facing")

	var vehicle_looks: Array[EventDef.Look] = [
		EventDef.Look.MOVING_VAN,
		EventDef.Look.BURNT_OUT_CAR,
	]
	for look in vehicle_looks:
		var id := "moving_van" if look == EventDef.Look.MOVING_VAN else "burnt_out_car"
		var def := EventCatalogue.by_id(id)
		var side := EventInstance._stationary_vehicle_texture(look, true)
		var end := EventInstance._stationary_vehicle_texture(look, false)
		var side_extent := EventInstance._stationary_vehicle_extent(
				side, true, def.obstructs_radius * 2.0)
		var end_extent := EventInstance._stationary_vehicle_extent(
				end, false, def.obstructs_radius * 2.0)
		t.check(side != end, "'%s' has distinct side and end artwork" % def.id)
		t.check(is_equal_approx(side_extent.x, def.obstructs_radius * 2.0),
				"'%s' side view fits the diameter of its solid body" % def.id)
		t.check(end_extent.is_equal_approx(EventInstance._native_size(end))
				and end_extent.x < side_extent.x,
				"'%s' end view keeps its narrower authored projection" % def.id)

## **A spread never lands on a corner.** `EventScheduler._is_a_corner` refuses any tile whose two
## coordinates are both inside a corridor band to a row `EventInstance.has_a_spread()` names — see
## `docs/DECISIONS.md`, "a spread on a corner is placed as if the corner were nothing": such a tile
## has no single street for `_spread_is_vertical` or `_centred_on_the_pavement_band` to answer about.
## Walked over the **planned** placements of several seeds and every day of a run, rather than over
## the candidate pool directly, because a clean pool and a roll that still lands on a stale entry
## are two different bugs.
## **One seed, all fourteen days.** The refusal is a filter on the candidate pool rather than
## anything about a layout, so what a second city adds is more draws from the same rule — and a
## day's worth of draws is already hundreds. The days stay whole because a run is what carries the
## `consumed` set forward, which is what makes a later day's pool different from an earlier one's.
func _test_a_spread_never_lands_on_a_corner(t) -> void:
	var checked := 0
	for run_seed in [4242]:
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
	var cap_along := EventInstance._native_size(EventInstance.BARRIER_END).x
	var offset := EventInstance._cap_offset(half, cap_along, 1.0)
	t.check(is_equal_approx(offset + cap_along * 0.5, half),
			"the cap's outer edge (%.1f) lands on the %.1fpx obstruction, not past it"
			% [offset + cap_along * 0.5, half])
	t.check(not is_equal_approx(offset, half),
			"and it is not simply centred at ±half any more (%.1f)" % offset)

## **A whole-scene hard seal has to use a distinct authored picture on either axis and span its
## obstruction at the ground point.** `EventInstance._wide_scene_texture` is the pure selector
## this pins: on an east-west street (`vertical` true) it returns the directional asset, while
## `_wide_scene_anchor` and the fitted extent keep the drawn body aligned with the obstruction.
## The bounds are checked against the real asset sizes and `fallen_tree`'s own obstruction radius,
## so the test covers the geometry that `_draw_wide_scene` sends to `Sprites.draw_standing` without
## rendering a frame.
func _test_a_wide_scene_faces_its_street(t) -> void:
	var horizontal := EventInstance._wide_scene_texture(EventDef.Look.FALLEN_TREE, false)
	var vertical := EventInstance._wide_scene_texture(EventDef.Look.FALLEN_TREE, true)
	t.check(horizontal == EventInstance.FALLEN_TREE,
			"a north-south street draws the horizontally-composed picture")
	t.check(vertical == EventInstance.FALLEN_TREE_VERTICAL,
			"an east-west street draws its directional picture, not the same one relabelled")
	t.check(horizontal != vertical, "and the two are not the same asset")

	var half := maxf(11.0, EventCatalogue.by_id("fallen_tree").obstructs_radius)
	for is_vertical in [false, true]:
		var texture := EventInstance._wide_scene_texture(EventDef.Look.FALLEN_TREE, is_vertical)
		var size := EventInstance._native_size(texture)
		var anchor := EventInstance._wide_scene_anchor(is_vertical, half)
		var extent := Vector2(size.x, half * 2.0) if is_vertical \
				else Vector2(half * 2.0, size.y)
		var drawn := Rect2(anchor - Vector2(extent.x * 0.5, extent.y), extent)
		if is_vertical:
			t.check(is_equal_approx(drawn.position.y, -half)
					and is_equal_approx(drawn.end.y, half),
					"'%s' vertical body spans the obstruction from -%.0f to %.0f"
					% [texture.get_file(), half, half])
		else:
			t.check(is_equal_approx(drawn.position.x, -half)
					and is_equal_approx(drawn.end.x, half),
					"'%s' horizontal body spans the obstruction from -%.0f to %.0f"
					% [texture.get_file(), half, half])

	# The other two whole-scene rows carry the same guarantee — checked once each rather than
	# re-running the segment arithmetic, since `_wide_scene_texture`'s own match is what could
	# regress silently if a future picture forgot its vertical sibling.
	for look in [EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN]:
		var wide := EventInstance._wide_scene_texture(look, false)
		var tall := EventInstance._wide_scene_texture(look, true)
		t.check(not wide.is_empty() and not tall.is_empty() and wide != tall,
				"look %d has two distinct assets, one per street orientation" % look)

	# `""`, not `null`: a picture is a repository path here, and "no authored contact art" is an
	# empty one. Asked as `is_empty()` rather than against `null`, which a `String` is never equal
	# to — the shape that made the fallen tree's check below fail and the crash's pass vacuously.
	var crash_wide := EventInstance._wide_scene_texture(EventDef.Look.CAR_ACCIDENT, false)
	var crash_tall := EventInstance._wide_scene_texture(EventDef.Look.CAR_ACCIDENT, true)
	t.check(not EventInstance._wide_scene_shadow(crash_wide).is_empty()
			and not EventInstance._wide_scene_shadow(crash_tall).is_empty(),
			"both crash directions carry contact shadows instead of a street-wide slab")
	t.check(EventInstance._wide_scene_shadow(
			EventInstance._wide_scene_texture(EventDef.Look.FALLEN_TREE, false)).is_empty(),
			"a continuous fallen tree keeps the generic wide-scene shadow")

## **A crash is solid only where the cars are.** *(2026-09-12: "a car crash right now has a full
## bounding box even though there are gaps in the sprite. the bounding box should only be the
## crashed cars".)*
##
## Stated as what the player asked for rather than as the offsets themselves: a body at the two
## cars leaves a lane she can walk on each pavement and holds the middle of the road, and a body
## spanning the street leaves neither. The offsets those lanes fall out of are read off the two
## pictures (`EventCatalogue._car_accident_parts`) and checked by eye with the bounding-box layer
## (`--layers 3`); what this holds is the thing that would be wrong if they drifted.
func _test_a_crash_is_solid_only_where_its_cars_are(t) -> void:
	var map := CityMap.new()
	var crash := EventCatalogue.by_id("car_accident")
	t.check(crash.solid_parts.size() == 2, "a crash is two cars, so it puts down two bodies")
	t.check(crash.solid_reach() < crash.obstructs_radius,
			"and it is solid to %.0fpx inside the %.0fpx of street it closes"
			% [crash.solid_reach(), crash.obstructs_radius])

	var carriageway := (float(Tuning.STREET_WIDTH) * 0.5 - Tuning.SIDEWALK_WIDTH) * Tuning.TILE_SIZE
	for vertical in [false, true]:
		var tile := Vector2i(Tuning.STREET_WIDTH + 3, Tuning.STREET_WIDTH / 2) if vertical \
				else Vector2i(Tuning.STREET_WIDTH / 2, Tuning.STREET_WIDTH + 3)
		var instance := EventInstance.new()
		instance.setup(crash, map.tile_to_world(tile), PackedVector2Array(), Vector2.RIGHT, map)
		t.add_child(instance)
		instance.set_process(false)
		var street := "east-west" if vertical else "north-south"

		var bodies := DebugLayers.collision_nodes_under(instance)
		t.check(bodies.size() == 2,
				"on a %s street the crash registers one collision shape per car (%d)"
				% [street, bodies.size()])

		var half: float = crash.obstructs_radius
		var offsets := _lateral_offsets(instance)
		for offset in offsets:
			t.check(absf(offset) < carriageway,
					"a wrecked car sits on the carriageway, not on a %s pavement (%.1fpx of %.0f)"
					% [street, offset, carriageway])
		t.check(_walkable_lane_beside(instance, half, -1.0) >= 2.0 * Tuning.PLAYER_BODY_RADIUS,
				"a %s crash leaves her a lane on one side (%.0fpx)"
				% [street, _walkable_lane_beside(instance, half, -1.0)])
		t.check(_walkable_lane_beside(instance, half, 1.0) >= 2.0 * Tuning.PLAYER_BODY_RADIUS,
				"and one on the other (%.0fpx)" % _walkable_lane_beside(instance, half, 1.0))
		t.check(_is_blocked_at(instance, 0.0),
				"while the middle of the road, where the cars are, is still shut on a %s street"
				% street)
		instance.free()

## Every other row is exactly one piece at its own origin, so nothing but the crash changed shape.
func _test_every_other_row_is_one_body(t) -> void:
	var several := 0
	for def in EventCatalogue.all():
		if def.solid_parts.size() > 1:
			several += 1
			continue
		t.check(def.parts().size() == 1, "'%s' is one body" % def.id)
		if def.obstructs_radius > 0.0:
			t.check(is_equal_approx(def.solid_reach(), def.obstructs_radius),
					("'%s' is solid exactly as far as it closes ground (%.1f vs %.1f): the two "
					+ "readings of a body only come apart for a row that is several")
					% [def.id, def.solid_reach(), def.obstructs_radius])
	t.check(several == 1,
			"exactly one row in the catalogue is solid in parts (%d) — a second is a decision"
			% several)

## Where each of an instance's solid pieces sits along its own spread axis, in px from the scene's
## centre.
func _lateral_offsets(instance: EventInstance) -> PackedFloat32Array:
	var vertical := instance.solid_axis() == Vector2.DOWN
	var found := PackedFloat32Array()
	for centre in instance.solid_part_centres():
		var offset := centre - instance.global_position
		found.append(offset.y if vertical else offset.x)
	return found

## Whether her centre may stand at `offset` along the spread axis — clear of every piece by her own
## body radius.
func _is_blocked_at(instance: EventInstance, offset: float) -> bool:
	var offsets := _lateral_offsets(instance)
	var shapes := instance.solid_part_shapes()
	for i in offsets.size():
		if absf(offset - offsets[i]) < shapes[i].reach() + Tuning.PLAYER_BODY_RADIUS:
			return true
	return false

## How much walkable width the crash leaves on one side of itself (`side` −1 or +1), measured from
## the far edge of the scene inward to the first body she cannot pass.
func _walkable_lane_beside(instance: EventInstance, half: float, side: float) -> float:
	var width := 0.0
	var offset := side * (half - Tuning.PLAYER_BODY_RADIUS)
	while absf(offset) <= half and not _is_blocked_at(instance, offset):
		width += 1.0
		offset -= side
	return width

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

## **A pursuer has to be sited where it actually closes on her rather than backing away.**
##
## Two things have to agree and neither knows about the other: the stand-off is where it stops, and
## the director decides where it starts. If the stand-off ever grows past the least the director
## could ever site it at — `Tuning.min_offscreen_lead()`, the worst case over every heading she
## might be walking — a pursuer *backs away* through its own telegraph instead of closing, which is
## a dog that visibly reverses down the street in front of her.
##
## The relationship is asserted rather than left as a coincidence: a change to the stand-off, to
## `VIEW_HALF_EXTENT` or to `OFFSCREEN_NOTICE` has moved these numbers before without anybody
## checking they still agree.
func _test_a_pursuer_is_sited_where_it_can_be_seen(t) -> void:
	for def in EventCatalogue.all():
		if not def.pursues:
			continue
		var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
		var floor_lead := Tuning.min_offscreen_lead(def.pursue_speed + Tuning.WALK_SPEED,
				def.offscreen_notice)
		t.check(standoff < floor_lead,
				"'%s' stands off at %.0fpx, inside the %.0fpx it is sited at even on the worst axis"
				% [def.id, standoff, floor_lead])
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

## **A row declared lethal has to actually get the chance to be lethal.** *(2026-09-07: "also a
## biker hit should be lethal.")* `cyclist` carries `hard_fail = true`, but
## `EventInstance.is_lethal_at()` returns false for the whole of `is_telegraphing()` — so a
## `TOWARD_PLAYER` row sited close enough to reach her before its own telegraph ends rides straight
## through, declared lethal and never once able to fire. `EventDirector._toward_her()` sites a
## `hard_fail` row at `Tuning.outlasting_telegraph_lead()` rather than the plain offscreen margin
## precisely so this cannot happen; this checks the contract directly, at the instance level, rather
## than trusting the siting alone.
##
## Walks every `hard_fail` `TOWARD_PLAYER` row in the catalogue rather than naming `cyclist`, so a
## second row of the same shape is covered by construction rather than by remembering to add it.
func _test_a_hard_fail_toward_player_row_is_lethal_by_the_time_it_reaches_her(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.spawn_mode != EventDef.SpawnMode.TOWARD_PLAYER or not def.hard_fail:
			continue
		checked += 1
		var closing := def.speed + Tuning.WALK_SPEED
		var lead := Tuning.outlasting_telegraph_lead(Vector2.RIGHT, closing, def.telegraph_time,
				def.offscreen_notice)
		# The same construction `_toward_her` uses: sited `lead` ahead along the heading, routed the
		# same distance behind so it is still going somewhere when it reaches her.
		var path := PackedVector2Array([Vector2(lead, 0.0), Vector2(-lead, 0.0)])
		var instance := EventInstance.new()
		instance.setup(def, path[0], path)
		var her := Vector2.ZERO
		var was_lethal := false
		var elapsed := 0.0
		# Generous over the time they would meet at, so a regression that undershoots the lead only
		# a little still gets caught rather than timing the loop out first.
		var limit := lead / closing * 1.5
		while elapsed < limit and not instance.is_finished:
			her.x += Tuning.WALK_SPEED * STEP
			instance._process(STEP)
			if instance.is_lethal_at(her):
				was_lethal = true
				break
			elapsed += STEP
		t.check(was_lethal,
				"'%s' is declared hard_fail but the approach never once outlasts its own %.1fs "
				% [def.id, def.telegraph_time] + "telegraph before it reaches her")
		instance.free()
	t.check(checked > 0, "there is at least one hard_fail TOWARD_PLAYER row to check ('cyclist')")

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
## measurement rather than a hedge: the multiset of event **kinds** has to be identical, and a
## `dog_walker` starting three tiles further up the same street is not a different day. Eight
## shouting men where there were two is, and that is what this stops.
##
## **Two directions, because a lost day gives the fire back altogether.** *("a retry always rolls
## new -- nothing that happened on the day that got retried can influence the next repeat")* —
## whether or not she ever reached it, so the ordinary retry is the same day down to the fire
## itself; a day planned after it actually burned on a day she **won** has none of it and nothing
## else different. The second is the one M39 was written against and it is asked here with an
## explicitly spent list, since a retry can no longer produce one.
func _test_a_retried_day_is_the_same_day(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	for run_seed in [4242, 90210, 1234567]:
		var map := CityGenerator.generate(run_seed)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d:events" % [run_seed, day])

		var consumed: Array[String] = []
		var first := EventScheduler.build_day(day, rng, map, consumed)
		# **Planning day 3 spends nothing**, because its one-shot is owed to her walk and is spent
		# where it becomes real — `EventScheduler._place_one_shots`. And a lost day gives back what
		# it spent (`GameState.finish_day`), so every retry is the same day down to the fire itself.
		# The other direction, the day after it burned on a day she won, is the loop below this one.
		t.check(consumed.is_empty(),
				"seed %d: planning day %d spends nothing on its own" % [run_seed, day])
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

		# And the day *after* the fire actually burned: the one-shot is gone and nothing else is.
		# This is the half of the property a retry can no longer ask, since a lost day gives the
		# fire back — and it is the half M39 was written for, so it is asked here instead.
		var spent: Array[String] = ["burning_building"]
		var third_rng := RandomNumberGenerator.new()
		third_rng.seed = rng.seed
		var third := _kinds_in(EventScheduler.build_day(day, third_rng, map, spent))
		for id: String in before.keys() + third.keys():
			var expected: int = 0 if id in spent else int(before.get(id, 0))
			t.check(int(third.get(id, 0)) == expected,
					"seed %d: a day after the fire burned has %d '%s' where the day had %d"
					% [run_seed, int(third.get(id, 0)), id, expected])

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
## The director's own siting depends on the heading she happens to be walking
## (`Tuning.offscreen_lead(heading, closing_speed, def.offscreen_notice)`), so this asks for the
## worst case over every heading rather than one of them — `Tuning.min_offscreen_lead()`, the
## vertical axis plus the row's own notice of closing at its `pursue_speed` against `WALK_SPEED`,
## which is the least ground the contract can ever rely on. A rig checked against a more generous
## heading would pass on an encounter the game can still produce on a worse one.
func _sited_at(def: EventDef) -> float:
	if def.pursues_within > 0.0:
		return def.pursues_within - 10.0
	return Tuning.min_offscreen_lead(def.pursue_speed + Tuning.WALK_SPEED, def.offscreen_notice)

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
	# Standing in it, so it notices her on the first step and the telegraph is the 1.7s it spends on
	# the ground about to go. Without a player position a flock waits for ever and every assertion
	# below would be made about eleven birds pecking — see `_test_a_flock_is_a_place_she_can_see`.
	instance.player_at = Vector2.ZERO
	_advance(instance, def.telegraph_time + 0.2)
	t.check(not instance.is_waiting() and not instance.is_telegraphing() and not instance.is_leaving,
			"the flock is up")

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

## **A flock goes up when she reaches the birds, and a clock cannot know when that is.**
## *(2026-09-20: "birds are also very late to start. they shouldn't prematurely start but they
## should basically start fluttering when I touch them not after".)* The birds are on the ground for
## the whole telegraph by construction — `EventInstance._fly_the_flock()` has them pecking while
## `is_telegraphing()` — so under the clock alone a walk straight in put them up well past her.
##
## Two claims, and the second is what stops the fix being a way of deleting the telegraph. **Walked
## into, it flushes at the birds** — `flock_spread` plus her own body, the distance at which she is
## among them rather than near them — within a frame of her reaching that distance and not before
## it. **Walked past without being reached, it still goes up on its clock**, so a flock she skirted
## is startled rather than ignored, and `telegraph_time` still means something.
##
## Stated over the walk rather than over the numbers it was written from: the rig sets `player_at`
## every tick, which is the one thing the pass rig behind `docs/COSTS.md` never does and the reason
## that table dashes this row.
func _test_a_flock_goes_up_when_she_reaches_the_birds(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var touch := def.flock_spread + Tuning.PLAYER_BODY_RADIUS
	t.check(touch < def.pursues_within,
			"she is inside the trigger (%.0fpx) well before she is among the birds (%.0fpx)"
			% [def.pursues_within, touch])

	var straight_in := _flock_flushes_at(t, def, 0.0)
	t.check(not is_inf(straight_in), "a flock walked straight into goes up at all")
	t.close_to(straight_in, touch,
			"it goes up as she reaches the birds (%.0fpx out, against a %.0fpx flock)"
			% [straight_in, touch], Tuning.WALK_SPEED * STEP * 2.0)

	# Past the edge of the wheel and never among them: nothing fires the flush, so the telegraph is
	# what ends the wait, and it still does.
	var skirted := _flock_flushes_at(t, def, touch + 30.0)
	t.check(not is_inf(skirted) and skirted > touch,
			"a flock she skirted still goes up, on its own clock, at %.0fpx" % skirted)

## Walks her past a flock at `offset` px to one side at `Tuning.WALK_SPEED`, telling the instance
## where she is every tick the way the world does, and answers how far from the middle she was on
## the first frame the birds were off the ground — `INF` if they never left it.
func _flock_flushes_at(t, def: EventDef, offset: float) -> float:
	var instance := _instance(t, def, Vector2.ZERO)
	var her := Vector2(-def.outer_radius - 120.0, offset)
	var answer := INF
	for _i in int(ceil(((def.outer_radius + 240.0) * 2.0 / Tuning.WALK_SPEED) / STEP)):
		instance.player_at = her
		instance._process(STEP)
		if not instance.is_waiting() and not instance.is_telegraphing():
			answer = her.distance_to(instance.position)
			break
		her.x += Tuning.WALK_SPEED * STEP
	instance.free()
	return answer

## **What a flock costs is what walking through one costs, and only a walked instance can say.**
## *(2026-09-20: "but keep things in relation to each other".)* The rate on the def is shared out
## between eleven birds and the burst starts when she reaches them, so neither
## `EventDef.walk_through_cost()` nor `docs/COSTS.md` prices this row — the table dashes its pass
## columns for exactly that reason. The number is set by walking it, which makes this the place the
## relationship has to be held.
##
## **And the instance has to be in the tree.** A bare `EventInstance.new()` never gets `_ready()`,
## so `_build_the_flock()` never runs, `_flock` stays empty and `contribution_at()` falls back to
## the modelled ring on the def — which reads far higher than eleven birds that fly up and away
## from her actually charge. `_instance()` adds it, which is the whole reason this is a suite and
## not arithmetic.
##
## **Above a loose dog's pass**, because a flock going up in a pram's face is the louder of the two
## encounters and the rate is easy to cut too far while chasing something else. There is no upper
## bound: *"not following the procedure should be costly"* — the procedure being to wait the birds
## out, which is free — so what walking into them costs is the player's to set by feel.
func _test_a_flock_walked_through_stays_in_relation_to_what_else_she_meets(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var through := _flock_walked_through(t, def, 0.0)
	var dog := M174Pass.pass_net_averaged(EventCatalogue.by_id("loose_dog"), 0.0,
			Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	t.check(through > dog,
			"walking through a flock costs %.1f, above the %.1f a loose dog's pass costs"
			% [through, dog])
	# The rim is the other half of what a flock is for: a hot spot with a wide quiet margin, which
	# is the whole reason it is eleven sources rather than one. Outside the birds the flush never
	# fires at all, so what is left out there is a fraction of the rate against a decay she is
	# earning the whole way — the line can and does come out negative, and the claim is the gap
	# rather than its sign.
	var skirted := _flock_walked_through(t, def, def.flock_spread + Tuning.PLAYER_BODY_RADIUS + 30.0)
	t.check(skirted < through * 0.5,
			"skirting one costs %.1f, far less than the %.1f of walking through it"
			% [skirted, through])

## Net points from walking a straight line past a flock at `offset` px to one side, at
## `Tuning.WALK_SPEED`, telling the instance where she is every tick the way the world does — the
## one thing `M174Pass`'s rig never does, and why `docs/COSTS.md` cannot price this row.
func _flock_walked_through(t, def: EventDef, offset: float) -> float:
	var instance := _instance(t, def, Vector2.ZERO)
	var her := Vector2(-def.outer_radius - 120.0, offset)
	var net := 0.0
	for _i in int(ceil(((def.outer_radius + 240.0) * 2.0 / Tuning.WALK_SPEED) / STEP)):
		instance.player_at = her
		instance._process(STEP)
		if her.distance_to(instance.position) <= def.outer_radius:
			net += (instance.contribution_at(her) - Tuning.EXCITEMENT_DECAY_WALKING) * STEP
		her.x += Tuning.WALK_SPEED * STEP
	instance.free()
	return net

## **A flock exists before it is seen, and the first frame of one is never inside the view around
## her.** *(PLAYTEST-69: "pigeons pop in on screen — they should exist before they are visible.")*
##
## The pop-in is a siting question rather than a drawing one, so this is stated over both halves of
## the siting and over the live row:
##
## - **Nothing sites it near her, on any day of the run.** A director-sited row is created at
##   `Tuning.AHEAD_LEAD_DISTANCE` (184px) in front of her, which is inside the 320px half-view on
##   every sideways heading — right for a cat, whose whole content is the three seconds it is there,
##   and the pop-in itself for eleven birds that are meant to be a patch of pavement. Checked over
##   `spawn_mode_on(day)`, the one query every placement asks, rather than over `spawn_mode` alone.
## - **The day gives it a tile**, so it is streamed in at `Tuning.EVENT_STREAM_RADIUS` — further
##   from her than the corner of the view even after the frame in which she crosses that boundary
##   at a run, which is what makes "the first drawn frame is off screen" true rather than likely.
## - **And it is on the ground, quiet, until she walks up to it.** A flock that streamed in already
##   bursting would have spent its whole event two screens away; one that emitted its full 42/s
##   while pecking would be a place nobody can walk past. The birds leave the ground only once she
##   is inside `pursues_within`, which is the telegraph contract paid in geometry.
func _test_a_flock_is_a_place_she_can_see(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(def.spawn_mode_on(day) == EventDef.SpawnMode.MAP,
				"day %d sites a flock on a tile rather than in front of her" % day)
	t.check(def.pursues_within > 0.0 and def.pursues_within < def.outer_radius,
			"it waits for her inside its own %.0fpx field (trigger %.0fpx)"
			% [def.outer_radius, def.pursues_within])

	var planned_flocks := 0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		for plan in _planned(day):
			if plan.def.id != def.id:
				continue
			planned_flocks += 1
			t.check(plan.is_placed(), "day %d's flock has ground of its own" % day)
	t.check(planned_flocks > 0, "the run's days plan flocks at all (%d)" % planned_flocks)

	# The far corner of the view, which is the furthest anything on screen can be from her.
	var corner := Tuning.VIEW_HALF_EXTENT.length()
	t.check(Tuning.EVENT_STREAM_RADIUS - Tuning.RUN_SPEED * STEP > corner,
			"a streamed row's first frame is %.0fpx away, outside the %.0fpx corner of the view"
			% [Tuning.EVENT_STREAM_RADIUS - Tuning.RUN_SPEED * STEP, corner])

	# As far off as `EventManager` ever first builds one, and five seconds of it.
	var instance := _instance(t, def, Vector2.ZERO)
	instance.player_at = Vector2(Tuning.EVENT_STREAM_RADIUS, 0.0)
	_advance(instance, 5.0)
	t.check(instance.is_waiting() and not instance.is_finished,
			"five seconds out of reach and the flock is still standing there")
	var still_grounded := true
	for bird in instance._flock:
		still_grounded = still_grounded and is_zero_approx(bird.lift)
	t.check(still_grounded, "every bird is on the pavement, which is what she can see from there")
	t.close_to(instance.current_intensity(),
			def.intensity * Tuning.TELEGRAPH_INTENSITY_FRACTION,
			"and pecking costs a fraction of what going up does", 0.1)

	# She comes inside the trigger: the notice starts here rather than at dawn.
	instance.player_at = Vector2(def.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting() and instance.is_telegraphing(),
			"walking up to it is what starts it")
	for bird in instance._flock:
		still_grounded = still_grounded and is_zero_approx(bird.lift)
	t.check(still_grounded, "and the telegraph is still eleven birds on the ground")
	# Read at the flock's own middle rather than at her: every bird is inside `flock_spread` of it
	# whatever the wheel is doing, so the two readings differ by the damping rather than by where
	# eleven birds happened to be on the frame each was taken.
	var on_the_ground := instance.contribution_at(Vector2.ZERO)

	_advance(instance, def.telegraph_time + 0.2)
	var up := 0
	for bird in instance._flock:
		if bird.lift > 0.0:
			up += 1
	t.check(up == instance._flock.size(), "then all %d of them are up" % instance._flock.size())
	t.check(instance.contribution_at(Vector2.ZERO) > on_the_ground * 3.0,
			"and the burst is what costs (%.1f/s through the middle against %.1f/s while they peck)"
			% [instance.contribution_at(Vector2.ZERO), on_the_ground])
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
	# `military_convoy` rather than the fire engine: this is about the generic path-following
	# mechanic, not about fire, and it needs a row whose `_be_done()` finishes immediately rather
	# than driving on until it is out of sight — `spawns_on_finish` is what does that, which the
	# fire engine no longer carries now that `burning_building` calls it in rather than the other
	# way round (`EventDef.spawns_on_sight`).
	var def := EventCatalogue.by_id("military_convoy")
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

# --------------------------------------- the place the day owes her walk (M179) ---
# Day 3's fire is budgeted at dawn with no position and sited by `EventDirector` from the walk she
# turns out to take — *"the fire should come first and be on your way guaranteed (a dynamic event
# dependent on the route you chose that day)"* (PLAYTEST-117).
#
# These drive the director directly, with her position and velocity written rather than walked, so
# the geometry is the test's own: what a city's borders happen to leave room for is the integration
# question and it is asked in `tests/test_event_manager.gd`, against a real manager and a real
# player. What is asked here is the rule.

## Walks a synthetic player down `route` from `at`, stepping the director every frame, and returns
## where she finished. She moves at `Tuning.WALK_SPEED` because the director's own clock only runs
## while she is actually going somewhere, and the heading it reads is the direction of the next
## point of the route — so the walk is a walk of the day's own corridor rather than a line through
## the lattice, which is what the siting is stated over.
##
## `_last_heading` carries the direction of the last step out, for a caller that needs to ask what
## she was travelling on the frame something happened.
var _last_heading := Vector2.RIGHT

func _walk_the_director(director: EventDirector, plans: Array[EventScheduler.Planned],
		at: Vector2, route: PackedVector2Array, seconds: float, until := Callable()) -> Vector2:
	var left := seconds
	for i in range(_nearest_on(route, at), route.size()):
		var toward := route[i] - at
		while toward.length() > Tuning.WALK_SPEED * STEP and left > 0.0:
			_last_heading = toward.normalized()
			var velocity := _last_heading * Tuning.WALK_SPEED
			at += velocity * STEP
			left -= STEP
			director.site_what_is_on_her_way(STEP, at, velocity, plans)
			if until.is_valid() and until.call():
				return at
			toward = route[i] - at
		if left <= 0.0:
			return at
	return at

func _nearest_on(route: PackedVector2Array, at: Vector2) -> int:
	var best := 0
	var best_distance := INF
	for i in route.size():
		var distance := route[i].distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best

## A way out of the doorstep that does not carry `unlike` — the other side of a fork, for the check
## that an unseen fire follows the branch she actually took.
func _another_branch(day: int, unlike: Vector2) -> PackedVector2Array:
	var tree := RouteTree.for_day(_map(), day)
	var carries := tree.branches_on(_map().world_to_tile(unlike))
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() < 8:
				continue
			var shares := false
			for colour in carries:
				shares = shares or branch.routes.size() > 0 and colour == tree.branches.find(branch)
			if shares:
				continue
			var points := PackedVector2Array()
			for i in route.size():
				points.append(EventScheduler.WalkSiting._cell_centre(_map(),
						route[route.size() - 1 - i]))
			return points
	return PackedVector2Array()

## The day's longest route as the line she walks — out from the doorstep to the calm area when
## `outward`, home again when not. A route is grown from the area to the doorstep, so the walk out
## is the array reversed.
func _fire_route(day: int, outward := true) -> PackedVector2Array:
	var tree := RouteTree.for_day(_map(), day)
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	for i in best.size():
		var cell: Vector2i = best[best.size() - 1 - i] if outward else best[i]
		points.append(EventScheduler.WalkSiting._cell_centre(_map(), cell))
	return points

## Day 3's plan, built fresh rather than taken from `_planned()`. These tests site the fire, which
## writes a position into the plan — and the memoized copy is shared with every other check in this
## suite on the understanding that nothing writes to it.
func _fire_day_plans() -> Array[EventScheduler.Planned]:
	var consumed: Array[String] = []
	return EventScheduler.build_day(Tuning.RUN_TAUGHT_DAY, _rng(Tuning.RUN_TAUGHT_DAY), _map(),
			consumed)

## The day-3 fire, and the whole rig it needs: the day's own plan, a placement context built the way
## `EventManager.start_day` builds one, and a director started on both.
func _fire_director(day: int, plans: Array[EventScheduler.Planned]) -> EventDirector:
	var director := EventDirector.new(_map())
	director.start_day(day, plans, _rng(day), _fire_siting(day))
	return director

## The placement context the director above is started on, built the way `EventManager.start_day`
## builds one. Kept as its own function so a check can ask it the same questions the director does —
## `still_ahead_of()`, which is what "on the branch she is walking" means.
var _shared_fire_siting: EventScheduler.WalkSiting = null

func _fire_siting(day: int) -> EventScheduler.WalkSiting:
	if not _shared_fire_siting:
		_shared_fire_siting = EventScheduler.WalkSiting.new(day, _map(),
				RouteTree.for_day(_map(), day), [] as Array[Vector2i], PackedVector2Array())
	return _shared_fire_siting

func _fire_in(plans: Array[EventScheduler.Planned]) -> EventScheduler.Planned:
	for plan in plans:
		if plan.def.id == "burning_building":
			return plan
	return null

## **It is sited from her walk, it may be moved while it is nobody's memory yet, and it is fixed the
## moment it is real.**
##
## The third of those is the one with teeth. `EventManager._stream_in` records the scar and moves the
## block along its arc the first time a plan enters the world, so the city already remembers this
## fire burning *there* — and a rule that moved it afterwards would be repairing a fact rather than
## checking one before accepting it. `Planned.was_live` is where the line is drawn, and it is drawn
## at the streaming radius rather than at the screen edge, which is six seconds of walking earlier.
func _test_the_fire_follows_her_walk_until_it_is_real(t) -> void:
	var map := _map()
	var day := Tuning.RUN_TAUGHT_DAY
	var plans := _fire_day_plans()
	var fire := _fire_in(plans)
	t.check(fire != null and not fire.is_placed(),
			"day 3 budgets the fire and leaves it with no position at all")
	if not fire:
		return
	var director := _fire_director(day, plans)
	var siting := _fire_siting(day)

	var out := _fire_route(day)
	var at := _walk_the_director(director, plans, out[0], out, 120.0,
			func() -> bool: return fire.is_placed())
	t.check(fire.is_placed(), "walking the day's own route out of the doorstep sites it")
	if not fire.is_placed():
		return
	var first := fire.position
	t.check(not RouteTree.for_day(map, day).branches_on(map.world_to_tile(first)).is_empty(),
			"on the path she is on: the day's route tree carries the tile it stands on")
	t.check(siting.still_ahead_of(at, _last_heading, first),
			"and ahead of her along the branch she is walking, rather than merely ahead of her")
	t.check(first.distance_to(at) > Tuning.EVENT_STREAM_RADIUS,
			"and outside the streaming band (%.0fpx), so it is neither seen nor real yet"
			% first.distance_to(at))

	# Home and out again the other way. It was never in the world, so it follows her onto the branch
	# she actually took — which is the whole of what a fork owes, and the one case a rule stated only
	# over "is it behind her" cannot answer: the way out she abandoned stays a few degrees off
	# square from the way she took, for the rest of the day.
	at = _walk_the_director(director, plans, at, _fire_route(day, false), 200.0)
	var other := _another_branch(day, first)
	t.check(not other.is_empty(), "the day offers a second way out to change her mind to")
	at = _walk_the_director(director, plans, at, other, 200.0,
			func() -> bool: return fire.position != first)
	t.check(fire.position != first, "taking a different way out before it is ever seen moves it")
	t.check(siting.still_ahead_of(at, _last_heading, fire.position),
			"and it lands ahead of her on the branch she took instead")

	# Real. From here it is where the city remembers it burning, and nothing moves it.
	var burning_at := fire.position
	fire.was_live = true
	_walk_the_director(director, plans, at, _fire_route(day), 30.0)
	t.check(fire.position == burning_at,
			"once it has been in the world, walking away from it for half a minute leaves it "
			+ "exactly where it burned")

## **A corner is not a change of mind.** A route turns every block or two, and each turning leaves
## the fire a little behind square — a rule that moved it there would move it at every junction,
## which is a day spent chasing something that is always the same distance ahead.
## `EventDirector.ON_HER_WAY_BEHIND` is the coarse half of what makes the two cases different and
## `WalkSiting.still_ahead_of()` the fine one, and this is the half of it that would otherwise never
## be noticed: the *absence* of a move.
##
## **The walk has to actually turn**, or the check passes by walking in a straight line and proves
## nothing; the corner it took is measured and asserted alongside.
func _test_a_corner_is_not_a_change_of_mind(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	var plans := _fire_day_plans()
	var fire := _fire_in(plans)
	if not fire:
		t.check(false, "day 3 budgets a fire to turn a corner past")
		return
	var director := _fire_director(day, plans)
	var out := _fire_route(day)
	var at := _walk_the_director(director, plans, out[0], out, 120.0,
			func() -> bool: return fire.is_placed())
	if not fire.is_placed():
		t.check(false, "walking the day's route sites the fire")
		return
	var sited := fire.position

	# On down the same branch for twice the patience the rule has, which is several turnings.
	var before := _last_heading
	var sharpest := 1.0
	var patience := EventDirector.ON_HER_WAY_TURNED_AWAY * 2.0
	for i in int(round(patience / STEP)):
		at = _walk_the_director(director, plans, at, out, STEP)
		sharpest = minf(sharpest, before.dot(_last_heading))
	t.check(fire.position == sited,
			"carrying on down the same branch for %.0fs leaves the fire where it is" % patience)
	t.check(sharpest < 0.7,
			"and the walk really did turn a corner in that time (%.0f degrees off where it started)"
			% rad_to_deg(acos(clampf(sharpest, -1.0, 1.0))))

## **The engine parks at the fire and stays there for the rest of the day.** *(2026-09-20, the
## player, asked whether it parks, waits twenty seconds or passes through: "option A -- a fire engine
## has a high cost"; "you're not supposed to go past it".)* Driven here rather than in a city,
## because what is under test is what an instance does when its route runs out — which needs a route
## and a clock and nothing else.
##
## Four things are checked and every one of them was wrong before the flag existed. It **stops**
## where the route ended rather than driving on out of sight. It is **not over**: it still emits,
## which is the entire cost the player asked for, where `is_leaving` would have silenced it. It
## **answers zero for its travel**, which is what the screen-edge badge reads as a closing speed.
## And the distance it has covered **stops growing**, because the gait is driven by distance and a
## parked engine would otherwise bob at the kerb for ever.
func _test_the_engine_parks_at_the_fire(t) -> void:
	var def := EventCatalogue.by_id("fire_truck")
	t.check(def != null and def.stops_where_it_arrives,
			"the fire engine is the row that stops where it arrives")
	if not def:
		return
	var kerb := Vector2(def.speed * 2.0, 0.0)
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, kerb]))
	# Past the end of a two-second route by a good margin, and then a while longer.
	_advance(instance, 4.0)
	t.check(instance.is_parked, "it parks when its route runs out")
	t.check(not instance.is_leaving and not instance.is_finished,
			"and parking is not an ending: it has neither left nor finished")
	t.close_to(instance.global_position.distance_to(kerb), 0.0,
			"it is standing at the end of its route, the near kerb across from the fire", 1.0)
	t.close_to(instance.travel_velocity().length(), 0.0,
			"and it answers zero for how fast it is travelling, so nothing reads it as closing",
			0.001)
	t.check(instance.contribution_at(kerb + Vector2(def.inner_radius * 0.5, 0.0)) > 0.0,
			"it is still emitting where it stands, which is the cost the pair is made of")
	var travelled := instance.path_travelled()
	_advance(instance, 6.0)
	t.close_to(instance.path_travelled(), travelled,
			"and ten seconds later it has covered no more ground, so the gait it is drawn with "
			+ "has stopped too", 0.001)
	t.check(instance.is_parked and not instance.is_finished,
			"and it is still standing there, for the rest of the day")
	instance.free()

## **A site is accepted only where the day still works around it.** The fire and the engine parked
## across from it are meant to close the street she is on, so the thing that has to be checked is the
## other direction: from where she is, with both fields taken as closed ground, the home and a calm
## area she has not used are still reachable. Checked before accepting; a refusal is a second of
## walking and another attempt.
##
## Both directions are asked, because a check that refused everything would pass the interesting half
## of this on its own. The refusal case is a fire sited on the doorstep itself, whose field swallows
## the one way out of the home — the shape the check exists for, and the one no amount of walking
## could answer.
func _test_a_site_that_shuts_her_out_is_refused(t) -> void:
	var map := _map()
	var day := Tuning.RUN_TAUGHT_DAY
	var def := EventCatalogue.by_id("burning_building")
	var siting := EventScheduler.WalkSiting.new(day, map, RouteTree.for_day(map, day),
			[] as Array[Vector2i], PackedVector2Array())
	var nothing_else: Array[EventScheduler.Planned] = []
	var route := _fire_route(day)
	t.check(route.size() > 8, "the day has a route out of the doorstep to stand on")
	if route.size() <= 8:
		return
	var at: Vector2 = route[route.size() / 2]

	var far_off := EventScheduler.Planned.new(def, route[route.size() - 2])
	t.check(siting._still_leaves_a_park_reachable(nothing_else, far_off, at),
			"a fire at the far end of the branch she is walking leaves the day working around it")

	var on_the_doorstep := EventScheduler.Planned.new(def, map.doorstep_world_position())
	t.check(not siting._still_leaves_a_park_reachable(nothing_else, on_the_doorstep, at),
			"and a fire whose field swallows the doorstep is refused, because the way home is what "
			+ "she would have no way round")

## **One plan, and the day is otherwise exactly the day it was.** A set piece the day owes her walk
## is budgeted like any other one-shot — one plan, tagged as its own group — and nothing else in the
## catalogue is left for the walk to site, so no other day changes shape because of this one.
func _test_the_fire_is_the_days_only_unsited_place(t) -> void:
	var owed := 0
	for day in range(1, 15):
		for plan in _planned(day):
			if not plan.def.sited_on_her_way:
				continue
			owed += 1
			t.check(day == Tuning.RUN_TAUGHT_DAY and plan.def.id == "burning_building",
					"day %d: the only place the day leaves for her walk is day 3's fire, not '%s'"
					% [day, plan.def.id])
			t.check(not plan.is_placed() and plan.set_piece_group != "",
					"day %d: it is planned with no position and tagged as a set piece" % day)
			t.check(plan.def.spawn_mode == EventDef.SpawnMode.MAP and not plan.def.mobile,
					"day %d: and it is a place that stands still, not a director's moment" % day)
	t.check(owed == 1, "exactly one plan in a fourteen-day run is owed to her walk (%d)" % owed)

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

## The suite's shared city, generated once.
##
## Seed 4242 is deliberately the same city for every check that does not name its own seed, so
## that the expensive part — generation, a quarter of a second — is paid once rather than at every
## call site that wants a real map to place things on. **It is handed out pristine and must stay
## that way**: a check that repaints it, closes streets on it or holds segments on it takes its own
## copy (`_test_the_day_is_placed_by_role` is the one that does), because the day plans cached
## below were built against this paint and a repaint underneath them would leave the rest of the
## file asserting about a city that no longer exists.
var _shared_map: CityMap

func _map() -> CityMap:
	if not _shared_map:
		_shared_map = CityGenerator.generate(4242)
	return _shared_map

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [4242, day])
	return rng

## The shared map's plan for `day`, memoized.
##
## **Ten checks below ask for exactly this** — `build_day(day, _rng(day), _map(), consumed)` with a
## fresh empty `consumed` — and `build_day` is the most expensive call in this suite at roughly two
## thirds of a second for an early day and a second for a late one. Planning the same fourteen days
## ten times over was six or seven minutes of re-deriving an answer that nothing between the calls
## had changed, and none of the ten was checking anything the first one had not already produced.
##
## Every caller reads the plans and none writes to them, which is what makes one copy safe to
## share. **Two callers go round this on purpose and both have to.**
## `_test_scheduler_is_deterministic` is *about* `build_day` repeating itself, so a cache hit would
## be the test asking a dictionary rather than the scheduler; and the calm-memory sweeps pass a
## `used` set as a further argument, so their plans are a different question.
var _plans := {}

func _planned(day: int) -> Array[EventScheduler.Planned]:
	if not _plans.has(day):
		var consumed: Array[String] = []
		_plans[day] = EventScheduler.build_day(day, _rng(day), _map(), consumed)
	var found: Array[EventScheduler.Planned] = _plans[day]
	return found

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
		var planned := _planned(day)
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
##
## **Two seeds, both runs whole.** Fourteen days is the unit and cannot shrink — "planned on one
## day of a *run*" is a statement about carrying `consumed` across the whole calendar, and a
## sampled day cannot say it. The seed count can: six were here to answer a *rate* question about
## how often the covering set narrows to one site, and that question is no longer asked (the rate
## is in `docs/DECISIONS.md` under M64, measured over forty-six seeds, which is the sample size it
## actually needs). What is left is true of every run rather than of the average, so a second city
## is there to keep it from being a fact about one layout and a third would add nothing.
func _test_one_shots_fire_once_per_run(t) -> void:
	var groups_seen := 0
	for seed_value in [4242, 5150]:
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
	t.check(groups_seen > 0, "some run had a one-shot to check (%d)" % groups_seen)

## **No robber stands in an alley she has to walk down.** *(2026-09-03: "alley robber should not
## happen on required alleys".)* `EventScheduler._refuses_required_alleys` excludes `alley_robbery`
## from any `ALLEY` tile the day's corridor runs through — `corridor.depth(tile) == 0` — because its
## own design note is that "a robbery has no telegraph you could see coming, and it never did": a
## risk with no warning is only fair on ground she chose to enter. See `docs/DECISIONS.md`, "and no
## robber stands in an alley she has to walk down."
##
## Walked over the **planned** placements and every day the row is eligible on (`first_day` 8
## onward), the same reason the corner test is over placements rather than the pool directly: a
## clean pool and a roll that still lands on a stale entry are two different bugs.
##
## **One seed.** Each day here costs a `RouteTree` as well as a `build_day`, and what a second city
## adds is more draws from one refusal rather than a layout the refusal could be wrong about — the
## corridor a candidate is tested against is grown afresh for every one of the seven days either
## way, so the sample is already seven different corridors.
func _test_alley_robbery_never_lands_on_a_required_alley(t) -> void:
	var checked := 0
	for run_seed in [4242]:
		var map := CityGenerator.generate(run_seed)
		var consumed: Array[String] = []
		for day in range(8, 15):
			var tree := RouteTree.for_day(map, day)
			var corridor := Corridor.of(tree)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d" % [run_seed, day])
			for plan in EventScheduler.build_day(day, rng, map, consumed, [], [], tree):
				if plan.def.id != "alley_robbery" or not plan.is_placed():
					continue
				checked += 1
				var tile := map.world_to_tile(plan.position)
				t.check(corridor.depth(tile) != 0,
						"seed %d day %d: 'alley_robbery' at tile %s is not on the day's corridor"
						% [run_seed, day, tile])
	t.check(checked > 0, "some run placed alley_robbery to check (%d)" % checked)

## Not the ordinary placement check — `_test_scheduler_respects_placement_and_caps` already holds
## `alley_mouse` to landing on an `ALLEY` tile, the same as every other `MAP` row. What nothing else
## checks is `EventInstance._alley_crossing_path()`'s own reason for existing: that the two-point
## dash it builds runs across whichever side of the alley is narrower, never along it. Read straight
## off `CityMap.alley_rects` rather than off a scheduled placement, so it holds for every alley a
## seed generates rather than only the ones a roll happens to use that day.
func _test_the_mouse_crosses_the_alleys_own_short_axis(t) -> void:
	var checked := 0
	for run_seed in [4242, 2102613802, 90210]:
		var map := CityGenerator.generate(run_seed)
		for rect: Rect2i in map.alley_rects:
			checked += 1
			var vertical := rect.size.y > rect.size.x
			var at := map.tile_to_world(rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2))
			var path := EventInstance._alley_crossing_path(map, at)
			t.check(path.size() == 2,
					"seed %d alley %s: the crossing path has exactly two points" % [run_seed, rect])
			var delta: Vector2 = path[1] - path[0]
			t.check(not is_zero_approx(delta.x) or not is_zero_approx(delta.y),
					"seed %d alley %s: the crossing path actually moves" % [run_seed, rect])
			if vertical:
				t.check(is_zero_approx(delta.y),
						"seed %d alley %s: a vertical alley (%dx%d) is crossed along X, not Y"
						% [run_seed, rect, rect.size.x, rect.size.y])
			else:
				t.check(is_zero_approx(delta.x),
						"seed %d alley %s: a horizontal alley (%dx%d) is crossed along Y, not X"
						% [run_seed, rect, rect.size.x, rect.size.y])
			# `Rect2.has_point` excludes the far edge, and the dash's whole point is to reach it —
			# the wall the alley's own width ends at — so the bound is checked directly rather
			# than with `has_point`, which would fail on the one edge that matters most here.
			var world_rect := map.tile_rect_to_world(rect)
			for point in path:
				t.check(point.x >= world_rect.position.x and point.x <= world_rect.end.x
						and point.y >= world_rect.position.y and point.y <= world_rect.end.y,
						"seed %d alley %s: the dash stays inside the alley it crosses" % [run_seed, rect])
	t.check(checked > 0, "some seed generated an alley to check (%d)" % checked)

## The review finding on M100, a mouse in the alley: `alley_mouse` is `MAP`-placed at dawn,
## `Tuning.EVENT_STREAM_RADIUS` (900px) outside the view and far past `Tuning.VIEW_HALF_EXTENT`, so
## a row that started telegraphing the moment it existed dashed and finished off screen before she
## ever walked into the alley — nothing happened, from where she was standing. `pursues_within`
## without `pursues` (`EventDef.pursues_within`'s own note, `EventInstance._check_for_notice()`) is
## the fix: this holds the whole sequence end to end, on a real generated alley, rather than only
## the crossing axis `_test_the_mouse_crosses_the_alleys_own_short_axis` already checks in
## isolation.
func _test_the_mouse_waits_until_she_is_near(t) -> void:
	var def := EventCatalogue.by_id("alley_mouse")
	t.check(def.pursues_within > 0.0 and not def.pursues,
			"alley_mouse waits like a pursuer without becoming one")

	var map: CityMap
	var rect: Rect2i
	for run_seed in [4242, 2102613802, 90210, 37, 38]:
		var candidate := CityGenerator.generate(run_seed)
		if not candidate.alley_rects.is_empty():
			map = candidate
			rect = candidate.alley_rects[0]
			break
	t.check(map != null, "some seed generated an alley to place the mouse on")
	if map == null:
		return

	var at := map.tile_to_world(rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2))
	var instance := EventInstance.new()
	instance.setup(def, at, PackedVector2Array(), Vector2.RIGHT, map)
	t.add_child(instance)
	instance.set_process(false)

	# Far away — well past the trigger, and past where `EventManager` actually streams a `MAP` row
	# in from (`EVENT_STREAM_RADIUS`, 900px).
	instance.player_at = at + Vector2(def.pursues_within + 400.0, 0.0)
	_advance(instance, 5.0)
	t.check(instance.is_waiting(), "far away, it is still only waiting several seconds later")
	t.check(not instance.is_telegraphing(), "and has not started telegraphing")
	t.close_to(instance.global_position.distance_to(at), 0.0, "and has not moved", 0.5)
	t.check(not instance.is_finished, "and has not finished")

	# She steps inside the trigger: the notice, and the clock, start now.
	instance.player_at = at + Vector2(def.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "she notices it")
	t.check(instance.is_telegraphing(), "and it starts telegraphing from the notice, not from dawn")

	_advance(instance, def.telegraph_time + 0.05)
	t.check(not instance.is_telegraphing(), "the telegraph ends")
	t.check(not instance.is_finished, "and the dash runs rather than the event already being over")

	# Mid-crossing (half the narrower side's own travel time, not half of `duration`, which
	# outlasts the physical crossing on purpose — see the row's own docstring): still inside the
	# alley, and it has actually moved along the axis that alley's short side is on.
	var world_rect := map.tile_rect_to_world(rect)
	var vertical := rect.size.y > rect.size.x
	var narrow_px := float(mini(rect.size.x, rect.size.y)) * Tuning.TILE_SIZE
	var crossing_time := narrow_px / def.speed
	_advance(instance, crossing_time * 0.5)
	t.check(instance.global_position.x >= world_rect.position.x - 1.0
			and instance.global_position.x <= world_rect.end.x + 1.0
			and instance.global_position.y >= world_rect.position.y - 1.0
			and instance.global_position.y <= world_rect.end.y + 1.0,
			"mid-dash it is still inside the alley it crosses")
	if vertical:
		t.check(not is_equal_approx(instance.global_position.x, at.x),
				"a vertical alley's mouse has moved across X, not Y")
	else:
		t.check(not is_equal_approx(instance.global_position.y, at.y),
				"a horizontal alley's mouse has moved across Y, not X")

	_advance(instance, crossing_time * 0.5 + 0.5)
	t.check(instance.is_finished or instance.is_leaving,
			"and the dash finishes once it has crossed")
	instance.free()

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
		var planned := _planned(day)
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
##
## **One seed, the run whole.** The run is the unit for the same reason the docstring above gives —
## the used set only exists as a run — while the seed is not: the rule is a refusal inside
## `build_day`, asked once per candidate per unused area, so one city's fourteen days already asks
## it tens of thousands of times. A second city asked the same question again on a different
## street plan and cost two and a half minutes to do it.
func _test_calm_she_has_not_used_is_left_alone(t) -> void:
	for run_seed in [4242]:
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

## The opposite direction: `spawns_on_sight` names what arrives once a row has been seen,
## `spawns_on_finish`'s own check above, mirrored. `burning_building` is the only row that
## carries one today.
func _test_sighted_successors_resolve(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.spawns_on_sight == "":
			continue
		checked += 1
		t.check(EventCatalogue.by_id(def.spawns_on_sight) != null,
				"'%s' summons '%s' on sight, which exists in the catalogue"
				% [def.id, def.spawns_on_sight])
	t.check(checked > 0, "there is at least one row with a spawns_on_sight ('burning_building')")

## It has no scheduled day at all, so nothing but `EventManager._summon_the_sighted_row()` can
## put one in the world — see `EventDef.spawns_on_sight` on `burning_building`.
func _test_fire_truck_is_never_scheduled(t) -> void:
	var truck := EventCatalogue.by_id("fire_truck")
	t.check(truck != null, "the fire engine exists")
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(not truck.available_on(day),
				"the fire engine is not schedulable on day %d" % day)

## The engine's own contract, re-proven for the new siting. `EventManager._summon_the_sighted_
## row()` sites it `maxf(Tuning.offscreen_lead(...), summoned.field_reach() + Tuning.
## VIEW_HALF_EXTENT.length())` up the street from wherever the fire stopped it — the second term
## is the one this test exists for: the trigger only bounds her distance from the fire to the
## half diagonal of the view (`ResistanceDirector.NOTICE_RADIUS`'s own reasoning), not to zero,
## so the siting has to clear the engine's own forward reach from *that* worst case, not just
## from directly underneath it.
func _test_the_fire_engine_is_fair_from_the_worst_position_on_the_street(t) -> void:
	var truck := EventCatalogue.by_id("fire_truck")
	var heading := Vector2.DOWN
	var closing := truck.speed + Tuning.WALK_SPEED
	var reach := truck.field_reach()
	var worst_sight := Tuning.VIEW_HALF_EXTENT.length()
	var lead := maxf(Tuning.offscreen_lead(heading, closing, truck.offscreen_notice),
			reach + worst_sight)
	t.check(lead >= reach + worst_sight,
			"the siting clears the engine's own forward reach (%.0fpx) from the worst distance "
			% reach + "she could already be from the fire when it is first seen (%.0fpx)" % worst_sight)

	# The same construction `EventManager._summon_the_sighted_row()` uses: sited `lead` up the
	# street from the point the engine stops at, travelling the same line down to it.
	var road_at := Vector2(2000.0, 2000.0)
	var entry := road_at + heading * lead
	var instance := EventInstance.new()
	instance.setup(truck, entry, PackedVector2Array([entry, road_at]))

	# The worst position on the street: standing exactly `worst_sight` up the street from the
	# fire, as far as she could be and still have triggered the summons by seeing it — the point
	# with the least possible head start on the engine's approach.
	var her := road_at + heading * worst_sight
	t.check(instance.contribution_at(her) <= 0.001,
			"the worst position on the street is already inside the engine's field at the "
			+ "moment it is created, before she has had any warning at all")
	instance.free()

func _test_along_street_paths_stay_in_bounds(t) -> void:
	var map := _map()
	var extent := map.world_size()
	for day in range(1, 15):
		for plan in _planned(day):
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
## **Three rows, and all of them are meant to be free.** A burnt-out shell is a reminder rather
## than an obstacle, and a poster crew — on a sidewalk against a wall, or on a square at its
## advertising column — is there so a street *looks* like a city under a curfew. The two crews are
## one decision: `poster_crew_square` is the sidewalk row's own field on the ground a row pinned
## against a building cannot stand on, so exempting one and charging the other would price the
## same event by where it happens. Neither
## has ever been more than nearly free to walk through, which is all the design asked of them.
## *(Playtest 63 raised the walking decay past what a poster crew emits, so "nearly free" became
## "free" and the row needs the exemption it used to sit just above. Nothing about the row moved;
## the ground under it did.)* (`barricade` and the other pure obstructions emit nothing at all and
## are covered by the blanket `intensity <= 0.0` exemption; `loudspeaker` is `city_wide` and has
## no line to walk through at all.)
const _SCENERY := ["burnt_shell", "poster_crew", "poster_crew_square"]

## The other exemption, and it is a different sentence: these rows are not cheap, they are **not
## priced by their field at all**. A detainer's cost is `Tuning.CHAT_EXCITEMENT` charged flat over
## the seconds it holds her still, through the conversation mechanism — the ambient disc around it
## is atmosphere, and the catalogue's own notes on `chatting_mother` and `checkpoint_hut` say so.
##
## *(Playtest 63 is what made it visible: with the walking decay raised to 6.0/s their fields no
## longer clear the ground they stand on, and the rule above called four rows a bribe. Sizing a
## detainer's field to clear the decay would have been charging the same body twice, at a number
## driven by a test rather than by what the row is.)* The exemption is not a hole because the
## check below replaces it: a row that is excused from costing something to walk past has to
## actually cost something to walk **into**.
const _PRICED_BY_THEIR_CAPTURE := ["chatting_mother", "checkpoint_hut", "checkpoint_post"]

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
##
## **`car_accident` is named as the one row where running is cheaper, and it is arithmetic rather
## than taste.** Running beats walking on any field whose mean emission along the line clears about
## 24/s: `EXCITEMENT_FROM_RUNNING` (14.0) plus the collapsed decay is a fixed price per second, so
## past that rate the shorter exposure wins. The crash was asked to cost more than half the meter to
## squeeze past (`tests/test_seals.gd`), and no field short and fierce enough to do that inside its
## own short shoulder sits under that rate — a field wide enough to charge fifty points at a walk
## would be felt from down the street, which is the thing the row's own design refuses. **So the
## choice was made by the entry's contract rather than by retuning something else**: sprinting past
## a crash costs 54 where walking costs 63, nine points of a hundred, against a field she is meant
## to route around rather than push through. It is open to overturn — the alternative is a wider,
## quieter field, and the cost of that is a sealed street announcing itself half a block away.
const _RUNNING_IS_CHEAPER := ["car_accident"]

func _test_running_is_the_answer_to_exactly_one_kind_of_thing(t) -> void:
	var pursuers := 0
	var running_is_cheaper := 0
	for def in EventCatalogue.all():
		if def.id in _RUNNING_IS_CHEAPER:
			running_is_cheaper += 1
			t.check(_cost_to_run_through(def) < _cost_to_walk_through(def),
					("'%s' is named as the row running is cheaper on (%.1f running, %.1f walking) — "
					+ "if that has stopped being true, take it off the list rather than keeping it")
					% [def.id, _cost_to_run_through(def), _cost_to_walk_through(def)])
			continue
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
	t.check(running_is_cheaper == _RUNNING_IS_CHEAPER.size(),
			"every row named as a running exemption is still in the catalogue (%d of %d)"
			% [running_is_cheaper, _RUNNING_IS_CHEAPER.size()])
	t.check(_RUNNING_IS_CHEAPER.size() == 1,
			"and there is exactly one of them (%d): a second is a decision somebody takes"
			% _RUNNING_IS_CHEAPER.size())

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
		if def.id in _PRICED_BY_THEIR_CAPTURE:
			# The exemption owes its own check, or it is a way of not being tested: a row excused
			# from costing something to walk past has to cost something to walk into.
			t.check(def.detain_seconds > 0.0 and Tuning.CHAT_EXCITEMENT > 0.0,
					"'%s' is excused the field because the detention is what it charges (%.1f "
					% [def.id, Tuning.CHAT_EXCITEMENT]
					+ "over %.1fs)" % def.detain_seconds)
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
	var blocks := Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y
	for day in [1, 3, 7, 14]:
		var planned := _planned(day)
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
	var lethal_on := {}
	for day in range(1, 15):
		var count := 0
		for plan in _planned(day):
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
	for day in [1, 8, 14]:
		var planned := _planned(day)
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
	var lethal_days := 0
	var exempt := 0
	for day in range(1, 15):
		var planned := _planned(day)
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
## placement cannot keep it clear of anything — `charging_dog` never reaches `_room_around` at all
## on `Tuning.RUN_TAUGHT_DAY`, when it is still `AHEAD_OF_PLAYER` and sited with no tile, and
## `alley_robbery` (and `charging_dog` again, past the teaching day, once `spawn_mode_on()` answers
## `MAP`) is exempt only because `hard_fail` always classifies a `MAP`-placed `RECURRING`/`SCRIPTED`
## row `WALL` before `_role_for` ever asks whether it pursues. Forcing the role off `WALL` here is
## what tells the two reasons apart, and it is why a third pursuer — one a future `_role_for` change
## routes through `SET_PIECE` or `FRICTION` instead — inherits the exemption without anybody adding
## a case for it.
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
		# A flock is several bodies wheeling inside one disc with pavement between them, so there is
		# no silhouette for a body to be half of — and being walked into is the whole event, which a
		# body would stop at the rim. `EventDef.validate()` refuses one that obstructs.
		if def.flock_size > 0:
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
		for plan in _planned(day):
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
		for plan in _planned(day):
			if plan.def.pavement_side != EventDef.Pavement.AGAINST_THE_BUILDING:
				continue
			# A place the day owes her walk has no tile yet to have a frontage behind it — day 3's
			# fire is sited later, against the same `_wants_this_side` rule this asks about, and
			# where it lands is asked of a real walk in `tests/test_event_manager.gd`.
			if not plan.is_placed():
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
		for plan in _planned(day):
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

## `docs/DECISIONS.md`, M100, "Events spawn inside a fully blocked street" and "Nothing on the home block":
## a catalogue placement is refused a candidate tile whose street segment is held today — a
## closure, a hard seal, a region wall or door, or a segment bordering the home block
## (`CityMap.held_segments`) — or that lies inside the home block's own lot
## (`CityMap.is_on_home_block`). Replicates `EventManager.start_day`'s own ordering: the seals and
## the region plan are known, and `held_segments` is filled, before `EventScheduler.build_day`
## rolls a single candidate.
##
## **And the fifth refusal, a standing street tree's own ground** (`docs/CITY.md`, "Street trees"):
## every catalogue placement and every seal body on these same full days is asked whether it stands
## on a tile `StreetTrees.footprint_tiles` covers. The seals are asked here rather than only in
## `tests/test_seals.gd` because they are the half that does **not** go through
## `EventScheduler._open_ground_for` — `SealPlanner._seal_along_tile` is a second implementation of
## one rule, and a day's plan is where the two have to agree. `fallen_tree` is the single exception
## and is excluded by name: it is the body that stands in a pit and empties it.
##
## **The seals' own bodies, the closure marker and the checkpoint rows are placed by their
## planners, not by the catalogue roll, so they are unaffected** — asserted by comparison rather
## than against a remembered count: the seals are planned twice on the same seeded stream, once
## with `SealPlanner.plan_day`'s `held` out-param wired in exactly as `EventManager.start_day`
## wires it and once without, and the two plans must be the same size, since `held` is written
## by the planner and read by nobody in it; closures, walls, doors and checkpoint bodies never
## read the holds at all, so they only have to exist across the sampled days (day 7 and day 10
## are in the sample for the regions). A remembered total would fail on every unrelated change to
## the generator — it did, twice, the day this was written — and say nothing about holds.
## **Two seeds and five days.** A (seed, day) here is the most expensive unit anywhere in this
## suite — a `RouteTree`, a region plan, a closure plan, two seal plans and a `build_day` — and
## what it proves is that five refusals inside `_open_ground_for` fire, which every single pair
## exercises over its whole day's worth of candidates. The days stay five rather than one because
## holds come from four different planners and each has its own first day (region walls from
## `REGION_WALL_FIRST_DAY`, closures from act I), so the sample has to span the acts; the seeds
## drop to two because the second is there to keep the sample from being one street plan and the
## third and fourth were asking the same question a third and fourth time.
func _test_nothing_the_catalogue_places_stands_on_held_ground(t) -> void:
	const SEEDS := 2
	const BASE_SEED := 314159
	const DAYS := [1, 4, 7, 10, 14]
	var total_closures := 0
	var total_boundary := 0
	var total_checkpoints := 0
	var total_seals := 0
	var checked := 0
	var checked_trees := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 137)
		for day in DAYS:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var region_plan := RegionPlanner.plan_day(map, day, tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree, region_plan)
			map.close_streets(closures)

			# The same population `EventManager.start_day` performs, before `build_day` runs.
			map.clear_day_holds()
			for closure in closures:
				map.hold_segment(closure.segment.key())
			for segment in region_plan.walls:
				map.hold_segment(segment.key())
			for segment in region_plan.doors:
				map.hold_segment(segment.key())
			for segment in StreetNetwork.around_blocks(Rect2i(map.home_block, Vector2i.ONE)):
				map.hold_segment(segment.key())

			var boundary := {}
			for segment in region_plan.walls:
				boundary[segment.key()] = true
			for segment in region_plan.doors:
				boundary[segment.key()] = true
			for rect in region_plan.alley_walls:
				boundary[rect.position] = true
			for rect in region_plan.alley_doors:
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			var seals := SealPlanner.plan_day(map, day, tree, seal_rng, boundary, map.held_segments)
			var unheld_rng := RandomNumberGenerator.new()
			unheld_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			var seals_unheld := SealPlanner.plan_day(map, day, tree, unheld_rng, boundary)
			t.check(seals.size() == seals_unheld.size(),
					"seed %d day %d: holding the hard seals' ground plans the same seals (%d vs %d)"
					% [map.seed_used, day, seals.size(), seals_unheld.size()])

			# **A tree and an event never share ground** — `docs/CITY.md`, "Street trees". Checked
			# over the same full days, against the tree footprints themselves rather than against
			# the pit tiles, since the refusal is stated over the ground the shadow reaches.
			var trees := StreetTrees.footprint_tiles(map)
			for seal in seals:
				if seal.def.id == "fallen_tree":
					continue   # the one body that stands in a pit, and empties it; see below
				var seal_tile := map.world_to_tile(seal.position)
				t.check(not trees.has(seal_tile),
						"seed %d day %d: seal '%s' stands in a street tree at %s"
						% [map.seed_used, day, seal.def.id, seal_tile])
				checked_trees += 1

			var consumed: Array[String] = []
			for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
				if not plan.is_placed():
					continue
				checked += 1
				var tile := map.world_to_tile(plan.position)
				t.check(not map.is_closed(tile),
						"seed %d day %d: '%s' does not stand on a closed tile"
						% [map.seed_used, day, plan.def.id])
				t.check(not map.is_held_at(tile),
						"seed %d day %d: '%s' does not stand on a held segment"
						% [map.seed_used, day, plan.def.id])
				t.check(not map.is_on_home_block(tile),
						"seed %d day %d: '%s' does not stand inside the home block"
						% [map.seed_used, day, plan.def.id])
				t.check(not trees.has(tile),
						"seed %d day %d: '%s' stands in a street tree at %s"
						% [map.seed_used, day, plan.def.id, tile])
				checked_trees += 1

			total_closures += closures.size()
			total_boundary += region_plan.walls.size() + region_plan.doors.size()
			total_checkpoints += region_plan.door_bodies.size()
			total_seals += seals.size()

	t.check(checked > 0, "the catalogue placed something to check across every sampled day (%d)"
			% checked)
	t.check(total_closures > 0, "the sampled days closed streets to hold (%d)" % total_closures)
	t.check(total_boundary > 0, "the sampled days had walls and doors to hold (%d)" % total_boundary)
	t.check(total_checkpoints > 0,
			"the sampled days stood checkpoint bodies on their doors (%d)" % total_checkpoints)
	t.check(total_seals > 0, "the sampled days sealed streets (%d)" % total_seals)
	t.check(checked_trees > 0,
			"and every one of those bodies was asked whether it stands in a tree (%d)"
			% checked_trees)

## **No solid body, alone or together, closes a walked sidewalk.** *(PLAYTEST-94, 2026-09-19: "I
## still get hard walls on the side of the sidewalk that is on the path -- how can this be so hard
## to do correctly?")* `tests/probes/m129_walked_sidewalk_walls.gd` measures the same question at
## zero over a wider sample; this asks it of `EventScheduler.closes_a_walked_sidewalk_band`
## directly, the one function both the probe and this test call, so neither can drift from what
## the other means by *closed*. Every solid body that day stands — the candidate loop's own rows,
## the seals, and the region wall's and doors' bodies, gathered the way
## `_test_nothing_the_catalogue_places_stands_on_held_ground` already assembles a full day — is
## checked cumulatively against every walked-sidewalk band, the way the width rule itself asks it.
##
## **Two seeds and three days, a quarter of the probe's own 24.** A (seed, day) here assembles the
## same expensive unit that test already prices at the suite's own budget — a tree, a region plan,
## closures, a seal plan and a `build_day` — so this asks one more question of it rather than
## building a second assembly; the probe is where the wider sample already lives if this suite's
## own finding ever needs a closer look.
func _test_no_body_closes_a_walked_sidewalk(t) -> void:
	const SEEDS := 2
	const BASE_SEED := 271828
	const DAYS := [1, 8, 13]
	var bands_checked := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 173)
		for day in DAYS:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var region_plan := RegionPlanner.plan_day(map, day, tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree, region_plan)
			map.close_streets(closures)

			map.clear_day_holds()
			for closure in closures:
				map.hold_segment(closure.segment.key())
			for segment in region_plan.walls:
				map.hold_segment(segment.key())
			for segment in region_plan.doors:
				map.hold_segment(segment.key())
			for segment in StreetNetwork.around_blocks(Rect2i(map.home_block, Vector2i.ONE)):
				map.hold_segment(segment.key())

			var boundary := {}
			for segment in region_plan.walls:
				boundary[segment.key()] = true
			for segment in region_plan.doors:
				boundary[segment.key()] = true
			for rect in region_plan.alley_walls:
				boundary[rect.position] = true
			for rect in region_plan.alley_doors:
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			var seals := SealPlanner.plan_day(map, day, tree, seal_rng, boundary, map.held_segments)

			var consumed: Array[String] = []
			var bodies: Array = []
			for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
				_add_a_physical_body(bodies, plan)
			for plan in seals:
				_add_a_physical_body(bodies, plan)
			for plan in region_plan.wall_bodies:
				_add_a_physical_body(bodies, plan)
			for plan in region_plan.door_bodies:
				_add_a_physical_body(bodies, plan)

			var corridor := Corridor.of(tree)
			var ground := {}
			for entry: Array in EventScheduler._route_sidewalks(map, ground, corridor):
				var segment: StreetNetwork.Segment = entry[0]
				var band: Rect2i = entry[1]
				bands_checked += 1
				t.check(not EventScheduler.closes_a_walked_sidewalk_band(
						map, band, segment.horizontal, bodies, map.closed_tiles),
						"seed %d day %d: street %s's walked sidewalk keeps a lane she fits through"
						% [map.seed_used, day, segment.key()])
	t.check(bands_checked > 50,
			"and the days sampled have walked-sidewalk bands to ask it of (%d)" % bands_checked)

## `plan` as `[position.x, position.y, obstructs_radius]`, appended to `bodies` — or not, for the
## same three exemptions the rule and its own probe make: a `checkpoint_hut`/`checkpoint_gate`
## door body costs by design, `city_wide` and `scenery` rows have no ground to keep clear of.
func _add_a_physical_body(bodies: Array, plan: EventScheduler.Planned) -> void:
	if not plan.is_placed() or plan.def.obstructs_radius <= 0.0:
		return
	if plan.def.city_wide or plan.def.scenery or plan.def.id.begins_with("checkpoint"):
		return
	bodies.append(Vector3(plan.position.x, plan.position.y, plan.def.obstructs_radius))

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
	# Four rows are legitimately invisible: something else already draws the ground they stand
	# on, the whole city is inside them, or — the finale's explosion — the whole of the row is that
	# it happens somewhere she cannot see, and what it leaves behind is a different row.
	var invisible := ["playground", "loudspeaker", "curfew_announce", "finale_explosion"]
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
		t.check(not icon.is_empty(), "'%s' has a silhouette a badge could draw" % def.id)
		if icon.is_empty():
			continue
		t.check(not seen.has(icon),
				"'%s' draws %s, which nothing else draws (else '%s')"
				% [def.id, icon.get_file(), seen.get(icon, "")])
		seen[icon] = def.id

# --------------------------------------------------- placement by role (M50) ---

## The two halves of `EventScheduler._role_for`, checked in one pass over the days because each of
## them costs a whole `build_day` and the suite is already the slowest thing in this project.
##
## **A lethal event is a wall, and a wall never stands on ground a route runs along.**
## *(`docs/CITY.md`: "hard and lethal blockers form the paths — they are the walls… the route is
## what is left between them.")* This is the one absolute in `_copies_of` and it is what the
## milestone can most easily get wrong: a lethal row on the route she is being guided down is not a
## wall in the wrong place, it is the guidance pointing at the thing it exists to point away from.
##
## **Asked per sidewalk, which is why the far side of a route's own street is counted separately
## below rather than treated as a failure.** A branch runs along one sidewalk of a street, so the
## other one is ground no route walks and is where a wall belongs — *"the market stall should appear
## on the other side of the street"*. `corridor.depth()` cannot tell those two apart, so the
## assertion asks `carries_a_route()` and the count is what shows the distinction is live.
##
## **Friction is aimed at the route**, which is the other half of the same sentence: *"benign
## blockers go on the route… to make it more challenging."* That one is a **weight** and is
## asserted as a proportion. About a third of the ground is on the corridor, so an unweighted day
## lands about a third of its costly rows there — `EVENT_CORRIDOR_WEIGHT` (four copies of an
## on-corridor tile in the roll) is what lifts it. The upper bound matters as much as the floor: a
## corridor carrying nearly all of it would mean every street off the route is empty, which reads
## as a set rather than as a city.
##
## **The floor is stated twice, because three rules take corridor ground away from a row.** A
## junction is the only place a line may change pavement, so a row whose reach covers a whole
## crossing is refused it (`EventScheduler._leaves_the_route_junctions_open`), and every corridor
## street has a route junction at each end; a row that would close the sidewalk the route is walked
## along is refused that band, cumulatively with what is already down
## (`_leaves_the_routes_sidewalk_open`); and a pacing row whose beat passes no way off its sidewalk
## is a wall and is refused the walked band outright (`_a_pacing_beat_walls_a_sidewalk`). All three
## bite on the corridor and nowhere else, so the share they leave is what the weight shows *through*
## them rather than the weight's own answer.
##
## The **narrow** share — the rows small enough to stand beside a crossing without taking it — is
## still the one to state a floor over, because it is the part the junction rule cannot touch and
## the part a reader would expect to be unaffected. What the floor defends is that the four-to-one
## corridor weight still shows through all three rules; it is not a claim that nothing diminishes
## it.
##
## **The whole share sits under its own natural ceiling because `delivery_van` counts as a wall in
## this tally while its own ground is weighted exactly like friction.** `delivery_van` is a wall by
## fit (`_closes_the_band_by_its_own_placement`) and is refused every route-carrying cell like any
## other wall, so it never shows up as `friction_on_the_route` even though `_copies_of`'s `by_cost`
## clause spreads its ground the same way friction's is spread. That gap between what the tally
## counts as friction and what the corridor weight actually reaches is real and current, not a bug
## this test papers over.
##
## **A floor is kept at the highest of the share's own ceiling (0.35 whole, 0.40 narrow) or a lower
## number the measurement clears by at least 1.5 points**, so a small future regression fails loudly
## rather than drifting under a floor nobody re-measured. Measured over the days sampled here, after
## M174's `Tuning.WALL_WORTH_OF_COST` moved from 35 to 48: the whole share stands at 33.04%, under
## its own 0.35 ceiling, so the floor is the lower number it clears by 1.5 points, rounded down —
## 0.31. The narrow share stands at 42.25%, clearing 0.40 by 2.25 points, comfortably past the
## 1.5-point bar, so its floor stays at its own ceiling, 0.40. Re-measure rather than trust either
## number if the catalogue's `pavement_side`/`obstructs_radius` pairing, `Tuning.WALL_WORTH_OF_COST`,
## or which walls get `EVENT_WALL_RIM_WEIGHT`, moves again.
##
## An `AHEAD_OF_PLAYER` row is exempt from the first half and the exemption is the design rather
## than a hole: the charging dog is sited by `EventDirector` in front of wherever she turns out to
## be walking, so it is by construction on her route and the scheduler never chose a tile for it.
## That is why `_role_for` calls it `NONE` — see the note there.
##
## Five days rather than fourteen. What is being checked is a property of the construction, and the
## days are sampled across the acts so that the catalogue's lethal rows (none before day 5) and its
## late density are both in the sample.
##
## **Its own city rather than the shared `_map()`**, because it repaints one — which blocks and
## arcs are calm is what a `RouteTree` grows from, so the tree has to be grown against today's
## paint. The shared map is handed out pristine and the day plans memoized against it would be
## answers about a city that no longer existed if this repainted underneath them.
## Half the width of a junction box (`Tuning.STREET_WIDTH` tiles square, 192px), which is the reach
## below which a row standing on a street beside a crossing cannot cover the box's own six-tile arm
## however close it stands. Used to split the friction into the rows the junction rule can refuse
## corridor ground and the rows it cannot.
const _A_JUNCTION_BOXES_HALF_WIDTH := Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5

func _test_the_day_is_placed_by_role(t) -> void:
	var map := CityGenerator.generate(4242)
	var walls := 0
	var walls_across_the_street := 0
	var friction_on_the_route := 0
	var friction := 0
	var narrow_on_the_route := 0
	var narrow := 0
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
						or plan.def.walk_through_cost() >= Tuning.WALL_WORTH_OF_COST
						or EventScheduler._takes_a_whole_sidewalk(plan.def)
						or EventScheduler._a_pacing_beat_walls_a_sidewalk(plan, map),
						"day %d: '%s' is a wall because it is lethal, very costly, leaves no line"
						% [day, plan.def.id] + " past it on a sidewalk, or paces one with no"
						+ " crossing in its beat")
				t.check(not corridor.carries_a_route(tile),
						"day %d: the wall '%s' at %s stands on no ground a route runs along"
						% [day, plan.def.id, TelemetryLog.tile(tile)])
				if away == 0:
					walls_across_the_street += 1
				placed[plan.def.hard_fail] += 1
				if away >= 2:
					deep[plan.def.hard_fail] += 1
			elif plan.role == GameEnums.BlockerRole.FRICTION:
				friction += 1
				if away == 0:
					friction_on_the_route += 1
				# The rows small enough to stand beside a crossing without taking it: the junction
				# rule cannot refuse one of these its corridor ground, so their share is the
				# weight's own answer with nothing subtracted from it. See the docstring.
				if EventScheduler._line_reach_of(plan.def) <= _A_JUNCTION_BOXES_HALF_WIDTH:
					narrow += 1
					if away == 0:
						narrow_on_the_route += 1
	# A sample with no walls in it would pass every assertion above and mean nothing.
	t.check(walls > 20, "the days sampled place walls at all (%d)" % walls)
	# And a sample where no wall ever landed across the street from a route would satisfy the
	# per-sidewalk assertion above with nothing but ordinary off-corridor ground under it — the
	# refusal would read the same whether it was stated per street or per sidewalk. *"The market
	# stall should appear on the other side of the street where for some reason no event was
	# chosen"* is the placement that had to become possible, so it is counted.
	t.check(walls_across_the_street > 0,
			"and some of them stand on a route street's far sidewalk (%d)" % walls_across_the_street)
	t.check(friction > 0, "and friction at all (%d)" % friction)
	t.check(narrow > 50, "and enough of it narrow enough to stand beside a crossing (%d)" % narrow)
	var share := float(friction_on_the_route) / maxf(1.0, float(friction))
	t.check(share > 0.31, "%d of %d costly rows are on the corridor" % [friction_on_the_route, friction])
	t.check(share < 0.9, "and the streets off it are not empty (%.0f%% on it)" % (share * 100.0))
	var narrow_share := float(narrow_on_the_route) / maxf(1.0, float(narrow))
	t.check(narrow_share > 0.40,
			"and the corridor weight still shows through the three rules that can refuse a narrow "
			+ "row (%d of %d narrow rows on the corridor)" % [narrow_on_the_route, narrow])

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
	# roadblock — cannot sit in a gap that runs through one. The `SIDEWALK`-placed rows still can,
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

## **Anything the day still aims at the route can be walked past on the route's own sidewalk.**
## *(PLAYTEST-77: "on the side of the street where the path was chosen only obstacles that can be
## bypassed should be possible.")* Friction is the role weighted *onto* the corridor
## (`Tuning.EVENT_CORRIDOR_WEIGHT`, four copies of an on-corridor tile in the roll), so what stays
## friction is what the guidance walks her into — and a sidewalk is two lanes of tile, so a row
## reaching across both of them from either has taken the last line along it.
##
## **This asserts the consequence rather than the clause.** `EventScheduler._role_for` answers
## `WALL` for a row that leaves no line; what has to be true afterwards is that every row still
## aimed at the route leaves one, which is the sentence the player wrote and the thing that would
## go red if the clause were weakened or if a new catalogue row were given a wider field than its
## role can carry.
##
## Asked on two days because a role can move with the day: `charging_dog` is director-sited on
## `Tuning.RUN_TAUGHT_DAY` and map-placed after it.
##
## **A pacing row is not one of the rows this is about**, and the exclusion is the design rather
## than a hole: a beat takes its ground in time, so what a walk needs past one is a phase rather
## than a lane. `_test_a_pacing_row_on_the_routes_sidewalk_can_be_left` is its half of the same
## question, and this count would be the wrong instrument for it.
##
## **A body narrow enough to move off the wall's own middle can still stay friction**, and
## `poster_crew` is the row that proves it: `AGAINST_THE_BUILDING` rather than `ANY` (a crew pastes
## posters at the wall it works on, not in the middle of the pavement) pins its 11px body to the
## frontage lane's own tile centre, `TILE_SIZE * 0.5` from the wall, spanning 5-27px of the 64px
## band and leaving 37px to the kerb — over the 28px she needs — where centred it would have left
## only 21px on each side. So the population below is one row across two days rather than the two
## rows (`delivery_van` and `poster_crew`) it used to be before either was read against the
## physical clause at all; `delivery_van` stays a wall by the same reading
## (`_closes_the_band_by_its_own_placement`'s own doc has its arithmetic).
##
## **The second loop is independent of `_role_for` on purpose**, re-deriving the edge-to-edge gap
## by hand rather than calling the function under test, so a future row narrow enough to slip both
## readings is caught by its own numbers rather than assumed impossible. `burning_building`
## (`ONE_SHOT`) is excluded from it since a set piece is never asked the friction-or-wall question.
func _test_friction_on_a_sidewalk_can_be_walked_past(t) -> void:
	var checked := 0
	for day in [1, 8]:
		for def in EventCatalogue.all():
			if not def.placement.has(GameEnums.TileType.SIDEWALK) or def.paces:
				continue
			if EventScheduler._role_for(def, day) != GameEnums.BlockerRole.FRICTION:
				continue
			if not EventScheduler._a_line_has_to_avoid(def):
				continue
			checked += 1
			t.check(EventScheduler._line_reach_of(def) < EventScheduler._THE_FAR_LANE,
					"day %d: '%s' is friction on a sidewalk and denies %.1fpx of it, so the far"
					% [day, def.id, EventScheduler._line_reach_of(def)]
					+ " lane (%.0fpx out) is still a line" % EventScheduler._THE_FAR_LANE)
	t.check(checked >= 2,
			"and the catalogue has rows on a sidewalk to ask it of (%d)" % checked)

	var solid_on_a_sidewalk := 0
	var band := float(Tuning.SIDEWALK_WIDTH) * Tuning.TILE_SIZE
	for def in EventCatalogue.all():
		if not def.placement.has(GameEnums.TileType.SIDEWALK) or def.paces or def.mobile:
			continue
		if def.obstructs_radius <= 0.0:
			continue
		# A `ONE_SHOT` is a set piece, not asked the friction-or-wall question at all
		# (`EventScheduler._role_for` answers it before the cost or physical clause ever runs) —
		# `burning_building` is `AGAINST_THE_BUILDING` and physically closes its own band exactly
		# like a wall would, and is still placed at every site of its covering set on purpose.
		if def.kind == GameEnums.EventKind.ONE_SHOT:
			continue
		solid_on_a_sidewalk += 1
		var pos: float
		match def.pavement_side:
			EventDef.Pavement.AT_THE_KERB:
				pos = Tuning.TILE_SIZE * 0.5
			EventDef.Pavement.AGAINST_THE_BUILDING:
				pos = band - Tuning.TILE_SIZE * 0.5
			_:
				pos = band * 0.5
		var gap := maxf(pos - def.obstructs_radius, band - (pos + def.obstructs_radius))
		var her_clearance := 2.0 * Tuning.PLAYER_BODY_RADIUS
		if gap < her_clearance:
			t.check(EventScheduler._role_for(def, 8) == GameEnums.BlockerRole.WALL,
					"'%s' leaves %.1fpx where she needs %.0f (obstructs %.1fpx, %s), so it has to"
					% [def.id, gap, her_clearance, def.obstructs_radius,
					EventDef.Pavement.keys()[def.pavement_side]]
					+ " be a wall rather than friction")
	t.check(solid_on_a_sidewalk >= 4,
			"and the catalogue has solid, non-pacing sidewalk rows to ask this of (%d)"
			% solid_on_a_sidewalk)

## **A row pinned to one side of a pavement may not be offered ground that has no sides.**
## *(2026-09-19: "we need a separate square poster crew entity for this", PLAYTEST-107.)* A square
## answers no `CityMap.pavement_inward`, so `EventScheduler._wants_this_side` refuses every square
## tile to a row carrying `AT_THE_KERB` or `AGAINST_THE_BUILDING` — and a `placement` entry whose
## every tile is refused is not a placement, it is a kind of ground the row silently stopped
## appearing on. That is exactly what happened to the poster crew when it moved against the
## building, and it is invisible in the def: the list still reads as though squares were offered.
##
## Asked of the whole catalogue against a real city rather than of the one row, so the next row
## given a pavement side is held to it without anybody adding an id to a list. Rows with an empty
## `placement` are the seal pictures, sited by `SealPlanner` on ground it picks itself.
func _test_a_pinned_row_is_only_offered_ground_it_can_be_pinned_on(t) -> void:
	var map := CityGenerator.generate(4242)
	var ground := {}
	var asked := 0
	for def in EventCatalogue.all():
		if def.pavement_side == EventDef.Pavement.ANY or def.placement.is_empty():
			continue
		for type in def.placement:
			var wanted := 0
			for tile in map.tiles_of_type(type as GameEnums.TileType):
				if EventScheduler._wants_this_side(def, map, tile):
					wanted += 1
			asked += 1
			t.check(wanted > 0,
					"'%s' is pinned %s, and the %s ground it lists has %d tiles that side exists on"
					% [def.id, EventDef.Pavement.keys()[def.pavement_side],
					GameEnums.TileType.keys()[type], wanted])
	t.check(asked >= 4, "and the catalogue has pinned rows to ask it of (%d)" % asked)
	# The pool the roll actually draws from, for the one row the player asked about: `poster_crew`
	# is a sidewalk row now, and the square crew is the row that stands on squares.
	t.check(not EventScheduler._open_ground_for(EventCatalogue.by_id("poster_crew"), map,
			ground).is_empty(), "and the sidewalk crew still has ground of its own to stand on")

## **The square's poster crew stands on squares and on nothing else.** *(2026-09-19: "we need a
## separate square poster crew entity for this", PLAYTEST-107.)* The sidewalk crew pastes against
## a building and the square crew at the column a square has instead of one; what makes them two
## rows rather than one is the ground, so the ground is what this asserts.
##
## **The sweep places the row rather than waiting for the dice to offer it.** Its weight is a
## hundredth of the sidewalk crew's — the square's share of the old row's own placements, measured
## — so it arrives well under once a day, and a sweep that planned whole days would be asking
## nothing at all on most of them and would go red on a reseed rather than on a defect.
## `EventScheduler._place_one` is the one function that chooses a tile for a row, so the sweep
## asks it directly, over seeds and over days spanning the acts, and reads back the ground it
## picked. The count at the end is what stops it passing having placed nothing.
func _test_the_square_poster_crew_only_ever_stands_on_a_square(t) -> void:
	var def := EventCatalogue.by_id("poster_crew_square")
	t.check(def != null and def.first_day <= 14, "the square poster crew is in the catalogue")
	if not def:
		return
	var placed := 0
	for i in 3:
		var map := CityGenerator.generate(4242 + i * 97)
		for day in [4, 9, 14]:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var corridor := Corridor.of(tree)
			var ground := {}
			var already: Array[EventScheduler.Planned] = []
			for copy in 3:
				var plan := EventScheduler._place_one(def, day, _rng(day + copy * 31), map,
						already, ground, [], corridor)
				if not plan:
					continue
				already.append(plan)
				placed += 1
				var type := map.tile_at(map.world_to_tile(plan.position))
				t.check(type == GameEnums.TileType.SQUARE,
						"day %d: the square crew stands on %s"
						% [day, GameEnums.TileType.keys()[type]])
	t.check(placed >= 1, "and the sweep actually placed one (%d)" % placed)

## **A man pacing the route's own sidewalk can always be left at a crossing, and one who cannot be
## left is never on it.** *(PLAYTEST-77, 2026-09-19: "if the yeller paces across a crosswalk then
## there is a way to avoid them. if they stay on the segment for the whole time with no side route
## then there is no way to avoid them. distinguish those cases when deciding whether the yeller is a
## wall".)*
##
## Both halves of that sentence are asserted over the finished day, because it is one rule read from
## its two sides: a pacing row whose field leaves no line along a sidewalk may stand on the route's
## own side **only** where its beat passes a way out, and where it passes none, it is a wall and
## stands anywhere but there. A way out is a **junction box** — the ground every crosswalk in the
## city is painted on — or a **side route**, ground off the street opening off the sidewalk's own
## side, which is the *"no side route"* half of the same sentence.
##
## The beat's own geometry is written out here rather than borrowed from the scheduler, for the
## reason the junction check gives: only the reading of which rows the question is about
## (`_counts_against_the_line`) and what the corridor walks (`Corridor.carries_a_route`) is shared.
##
## **Its non-vacuity is three counts**, because each could pass having seen nothing: a sample with no
## pacing row on a route sidewalk, one where no beat was ever walled, and one where the side-route
## half of the reading never saw a side route at all. The third is reported with the number of beats
## the side route answers for **on its own** beside it, which is the interesting one: where that is
## zero, every beat with a side route also reaches a junction and the half changes no placement in
## this sample — it is still what a beat truncated beside a park would be answered by.
##
## **The walled count is small, and the arithmetic says it has to be.** `homeless_yeller` paces
## `path_length_tiles` (8) against a block of `Tuning.BLOCK_SIZE` (8), so a beat laid anywhere on a
## street runs into the junction box at one end of it unless `_along_street_path` truncates it —
## at a closure, at a calm zone's absorbed corridor, or against the map's own margin. The walled
## case is that truncation, which is why the floor under it is *one* rather than a share: what it
## guards is that the sweep can still produce the case at all.
func _test_a_pacing_row_on_the_routes_sidewalk_can_be_left(t) -> void:
	var map := CityGenerator.generate(4242)
	var on_the_route := 0
	var walled := 0
	var by_a_side_route := 0
	var passes_a_side_route := 0
	var unavoidable_on_the_route := 0
	var first := ""
	for day in [1, 5, 8, 11, 14]:
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var corridor := Corridor.of(tree)
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
			if not plan.def.paces or not EventScheduler._counts_against_the_line(plan):
				continue
			if EventScheduler._line_reach_of(plan.def) < EventScheduler._THE_FAR_LANE:
				continue
			var crossed := _a_beat_touches_a_junction(map, plan)
			var sideways := _a_beat_passes_a_side_route(map, plan)
			if sideways:
				passes_a_side_route += 1
				if not crossed:
					by_a_side_route += 1
			if not crossed and not sideways:
				walled += 1
			if not corridor.carries_a_route(map.world_to_tile(plan.position)):
				continue
			on_the_route += 1
			if crossed or sideways:
				continue
			unavoidable_on_the_route += 1
			if first == "":
				first = "day %d, '%s' at %s" \
						% [day, plan.def.id, TelemetryLog.tile(map.world_to_tile(plan.position))]
	t.check(on_the_route > 5,
			"the days sampled pace a row along the route's own sidewalk (%d)" % on_the_route)
	t.check(walled >= 1,
			"and pace one whose beat passes no way off its sidewalk (%d)" % walled)
	t.check(passes_a_side_route >= 1,
			"and pace one whose beat passes a side route off its sidewalk (%d, of which %d have no"
			% [passes_a_side_route, by_a_side_route] + " junction in the beat either)")
	t.check(unavoidable_on_the_route == 0,
			"and every one on the route's own sidewalk has a way out inside its beat (%d does not%s)"
			% [unavoidable_on_the_route, "" if first == "" else ": " + first])

## Whether a beat's straight run touches a junction box, which is the only ground in the city a
## crosswalk is painted on (`CityGenerator._street_tile`).
func _a_beat_touches_a_junction(map: CityMap, plan: EventScheduler.Planned) -> bool:
	for at in _beat_tiles(map, plan):
		if CityMap.junction_at(at) != Vector2i(-1, -1):
			return true
	return false

## Whether a beat's straight run passes ground off the street opening off the sidewalk's own side —
## an alley mouth, a park or square edge, a courtyard. Two tiles deep, so a doorway notch is not a
## way out; written out here rather than borrowed for the reason the walk below is.
func _a_beat_passes_a_side_route(map: CityMap, plan: EventScheduler.Planned) -> bool:
	for at in _beat_tiles(map, plan):
		var inward := map.pavement_inward(at)
		if inward == Vector2i.ZERO:
			continue
		var edge := at
		for _across in Tuning.SIDEWALK_WIDTH:
			edge += inward
			if map.tile_at(edge) != GameEnums.TileType.SIDEWALK:
				break
		if map.is_open(edge) and not map.is_street(edge) \
				and map.is_open(edge + inward) and not map.is_street(edge + inward):
			return true
	return false

## The tiles a beat's straight run covers, ends included.
func _beat_tiles(map: CityMap, plan: EventScheduler.Planned) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	if plan.path.size() < 2:
		return found
	var from := map.world_to_tile(plan.path[0])
	var to := map.world_to_tile(plan.path[plan.path.size() - 1])
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var at := from
	while true:
		found.append(at)
		if at == to or step == Vector2i.ZERO:
			return found
		at += step
	return found

## **A route's junctions stay clear.** *(PLAYTEST-69: "a path through the city must never hit
## excitement — so all obstacles should be routable around by eg crossing to the other side of the
## street".)* A junction is the only place a line along a route may change pavement, so a crossing
## the day's rows have closed between them is a cut that the ground on either side of it cannot
## answer: `tests/probes/m129_zero_cost_line.gd` measured it as the shape breaking more routes than
## every other shape put together.
##
## **The assertion is about the finished day rather than about the refusal**, which is what keeps it
## from being the rule read back to itself. `EventScheduler._leaves_the_route_junctions_open` refuses
## one candidate at a time, against what is already down; what has to be true afterwards is that
## nothing *else* the morning does — a scar prepended, an ambient placed, a park spoiled, the
## walkability strip — has left a crossing closed. Measured over the five sampled days of seed 4242:
## 50 of 360 route junctions were closed before the rule existed and none are with it.
##
## **The geometry is stated here rather than borrowed**, for the same reason: the box's own flood
## fill is written out below, so a change to the scheduler's private helper cannot quietly change
## what this file claims. Only the primitives are shared — which junctions the routes cross
## (`RouteTree.junctions()`), which streets are on the corridor (`Corridor.depth`), and what a row
## denies (`EventScheduler._counts_against_the_line` and `_line_reach_of`, the reading PLAYTEST-71
## settled and the one place it is written down).
##
## **And it cannot pass vacuously**: a day where no counted row ever stood within reach of a route
## junction would satisfy it with nothing checked, so the rows that do are counted and asserted.
func _test_a_routes_junctions_stay_clear(t) -> void:
	var map := CityGenerator.generate(4242)
	var junctions := 0
	var in_reach := 0
	var closed := 0
	var first := ""
	for day in [1, 5, 9, 14]:
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var corridor := Corridor.of(tree)
		var consumed: Array[String] = []
		var counted: Array[EventScheduler.Planned] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
			if EventScheduler._counts_against_the_line(plan):
				counted.append(plan)
		for junction in tree.junctions():
			junctions += 1
			var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
			var world := map.tile_rect_to_world(box)
			var here: Array[EventScheduler.Planned] = []
			for plan in counted:
				var reach := EventScheduler._line_reach_of(plan.def)
				if plan.distance_from(world.get_center()) <= reach + world.size.length() * 0.5:
					here.append(plan)
			in_reach += here.size()
			if here.is_empty():
				continue
			if _the_crossing_is_walkable(map, corridor, junction, box, here):
				continue
			closed += 1
			if first == "":
				var ids := {}
				for plan in here:
					ids[plan.def.id] = true
				first = "day %d, junction %s, covered by [%s]" \
						% [day, junction, ", ".join(PackedStringArray(ids.keys()))]
	t.check(junctions > 100, "the days sampled plan routes across junctions (%d)" % junctions)
	t.check(in_reach > 100,
			"and place rows within reach of them, so the check is not vacuous (%d)" % in_reach)
	t.check(closed == 0, "no route junction is closed by what the day placed (%d closed%s)"
			% [closed, "" if first == "" else ": " + first])

## The test's own statement of *a line can still cross here*: take every row's reach off the
## junction box and ask whether the box's remaining ground joins every route street that meets it.
##
## Both halves matter. A box with somewhere free left in it is not a crossing if the free ground is
## a corner cut off from the streets, and a box whose two arms are each free is not a crossing if
## nothing joins them — which is why this is a flood fill rather than a count.
func _the_crossing_is_walkable(map: CityMap, corridor: Corridor, junction: Vector2i, box: Rect2i,
		rows: Array[EventScheduler.Planned]) -> bool:
	var free := {}
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var tile := Vector2i(x, y)
			if not map.is_open(tile):
				continue
			var taken := false
			for plan in rows:
				if EventScheduler._denies(plan, map.tile_to_world(tile),
						EventScheduler._line_reach_of(plan.def)):
					taken = true
					break
			if not taken:
				free[tile] = true
	if free.is_empty():
		return false
	var arms: Array = []
	for segment in StreetNetwork.at_junction(junction):
		if corridor.depth(segment.tile_rect().position) != 0:
			continue
		var open_here: Array[Vector2i] = []
		var step := segment.other_end(junction) - junction
		for i in Tuning.STREET_WIDTH:
			var tile := box.position + Vector2i(i, i)
			if step.x > 0:
				tile = box.position + Vector2i(Tuning.STREET_WIDTH - 1, i)
			elif step.x < 0:
				tile = box.position + Vector2i(0, i)
			elif step.y > 0:
				tile = box.position + Vector2i(i, Tuning.STREET_WIDTH - 1)
			else:
				tile = box.position + Vector2i(i, 0)
			if free.has(tile):
				open_here.append(tile)
		if open_here.is_empty():
			return false
		arms.append(open_here)
	if arms.size() < 2:
		return true
	var reached := {}
	var queue: Array[Vector2i] = []
	for tile: Vector2i in arms[0]:
		reached[tile] = true
		queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if free.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	for i in range(1, arms.size()):
		var joined := false
		for tile: Vector2i in arms[i]:
			if reached.has(tile):
				joined = true
				break
		if not joined:
			return false
	return true

## **Nothing takes the sidewalk a route is walked along.** *(PLAYTEST-69: "all obstacles should be
## routable around by eg crossing to the other side of the street, which in turn means the other
## side of the street must be open enough so we can walk on it unimpeded"; PLAYTEST-77: "on the side
## of the street where the path was chosen only obstacles that can be bypassed should be
## possible".)* A branch runs down one sidewalk of a street and the kerb tint marks that one, so the
## far side staying open answers a van and does not answer a row standing on the route's own side.
##
## **It is a shape the numbers make rather than a rare accident**, which is why it is worth a check
## of its own: a sidewalk is 64px and most of the catalogue denies more than that from wherever it
## stands. The probe measured a row spanning a whole street breaking 39 routes in 97 cuts before any
## of these rules existed.
##
## Asserted over the finished day and over **every row reaching the band at once**, which is the
## rule's own wording — a band closed by a pair is the shape the measurement found. What that
## catches beyond the refusal itself is anything the morning does outside `_place_one`'s candidate
## loop: a scar prepended, an ambient placed, a park spoiled.
##
## **Its non-vacuity has two halves**, because a sweep that found no walked sidewalks, or found them
## and had no row standing anywhere near one, would pass having checked nothing. Both are counted.
##
## The walk is written out here rather than borrowed from the scheduler, for the reason the junction
## check gives — only the reading of what a row denies is shared, since there is one place that is
## written down.
func _test_nothing_takes_the_routes_own_sidewalk(t) -> void:
	var map := CityGenerator.generate(4242)
	var bands := 0
	var bands_with_a_row := 0
	var closed := 0
	var first := ""
	for day in [1, 5, 9, 14]:
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var corridor := Corridor.of(tree)
		var consumed: Array[String] = []
		var counted: Array[EventScheduler.Planned] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
			# A pacing row is left out for the reason the rule leaves it out: a beat is passed by
			# waiting rather than by a lane, and its own two rules are what govern it.
			if EventScheduler._counts_against_the_line(plan) and not plan.def.paces:
				counted.append(plan)
		for segment in StreetNetwork.segments():
			var rect := segment.tile_rect()
			if corridor.depth(rect.position) != 0:
				continue
			for band in _sidewalk_bands_of(rect, segment.horizontal):
				if not _a_route_is_walked_along(corridor, band):
					continue
				bands += 1
				var world := map.tile_rect_to_world(band)
				var standing: Array[EventScheduler.Planned] = []
				for plan in counted:
					if EventScheduler._reach_touches(plan, world,
							EventScheduler._line_reach_of(plan.def)):
						standing.append(plan)
				if standing.is_empty():
					continue
				bands_with_a_row += 1
				if _a_walk_along(map, band, segment.horizontal, standing):
					continue
				closed += 1
				if first == "":
					var ids := {}
					for plan in standing:
						ids[plan.def.id] = true
					first = "day %d, street %s, held by [%s]" \
							% [day, segment.key(), ", ".join(PackedStringArray(ids.keys()))]
	t.check(bands > 50, "the days sampled walk routes along sidewalks (%d)" % bands)
	t.check(bands_with_a_row > 20,
			"and rows stand within reach of them (%d of %d)" % [bands_with_a_row, bands])
	t.check(closed == 0, "and a line survives along every one of them (%d closed%s)"
			% [closed, "" if first == "" else ": " + first])

## The two sidewalk bands of a street's tile rect, written out here rather than borrowed for the
## reason the walk below is.
func _sidewalk_bands_of(rect: Rect2i, horizontal: bool) -> Array[Rect2i]:
	var across := Vector2i.DOWN if horizontal else Vector2i.RIGHT
	var size := Vector2i(rect.size.x, Tuning.SIDEWALK_WIDTH) if horizontal \
			else Vector2i(Tuning.SIDEWALK_WIDTH, rect.size.y)
	var far := across * (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH)
	return [Rect2i(rect.position, size), Rect2i(rect.position + far, size)]

func _a_route_is_walked_along(corridor: Corridor, band: Rect2i) -> bool:
	for y in range(band.position.y, band.end.y):
		for x in range(band.position.x, band.end.x):
			if corridor.carries_a_route(Vector2i(x, y)):
				return true
	return false

## Whether a walk exists from one end of a street to the other with these rows standing on it: the
## street's own ground, both pavements, the carriageway between the kerbs left out because a line
## may not cross there anyway, four-connected so a barrier laid diagonally counts as closing it.
func _a_walk_along_the_street(map: CityMap, segment: StreetNetwork.Segment,
		rows: Array[EventScheduler.Planned]) -> bool:
	return _a_walk_along(map, segment.tile_rect(), segment.horizontal, rows)

## The same walk over an arbitrary run of a street's ground — one sidewalk band of it, or the whole
## street — from one end of `rect` to the other along `horizontal`.
func _a_walk_along(map: CityMap, rect: Rect2i, horizontal: bool,
		rows: Array[EventScheduler.Planned]) -> bool:
	var free := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not map.is_open(tile):
				continue
			var across := CityMap.corridor_offset(tile.y if horizontal else tile.x)
			var type := map.tile_at(tile)
			if CityMap.is_road_offset(across) and (type == GameEnums.TileType.ROAD
					or type == GameEnums.TileType.CROSSING):
				continue
			var taken := false
			for plan in rows:
				if EventScheduler._denies(plan, map.tile_to_world(tile),
						EventScheduler._line_reach_of(plan.def)):
					taken = true
					break
			if not taken:
				free[tile] = true
	var last := (rect.end.x - 1) if horizontal else (rect.end.y - 1)
	var seen := {}
	var queue: Array[Vector2i] = []
	for tile: Vector2i in free:
		var at_the_start := tile.x == rect.position.x if horizontal \
				else tile.y == rect.position.y
		if at_the_start:
			seen[tile] = true
			queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		if (at.x if horizontal else at.y) == last:
			return true
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if free.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return false

## **A pacing row leaves the line open for part of its beat.** *(PLAYTEST-71: "time pass — don't
## route around them".)* A man walking a footway and back is passed by waiting, so the ground his
## beat denies is the ground it never leaves free — and what the probe finds broken is never the
## beat by itself but the beat's one open end with something else standing in it.
##
## So the claim is about a **street carrying a pacing row**, asked of every row reaching that street
## at once: a walk from one of its junctions to the other has to survive all of them together. That
## is what `EventScheduler._leaves_a_pacing_beats_opening` refuses a placement for, and asserting it
## over the finished day is what catches anything a later pass adds without asking.
##
## **It cannot pass vacuously**: a sample where no pacing row ever stood on a route street would
## satisfy it having checked nothing, so those streets are counted and asserted. `homeless_yeller`
## (14.0 over 210px, no body, paces) is the row the sample is really about.
func _test_a_pacing_rows_opening_stays_open(t) -> void:
	var map := CityGenerator.generate(4242)
	var paced_streets := 0
	var closed := 0
	var first := ""
	# Five days, the ones `_test_the_day_is_placed_by_role` samples. A pacing row is one row of the
	# catalogue and the junction and width rules have taken most of the corridor away from it, so
	# the sample turns up a handful of paced route streets rather than dozens — which is why the
	# guard below is a floor with room under it rather than a measurement to keep in step. What it
	# is for is only that the check ran against real ground at all.
	for day in [1, 5, 8, 11, 14]:
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var corridor := Corridor.of(tree)
		var consumed: Array[String] = []
		var counted: Array[EventScheduler.Planned] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree):
			if EventScheduler._counts_against_the_line(plan):
				counted.append(plan)
		var streets := {}
		for plan in counted:
			if not plan.def.paces:
				continue
			var segment := StreetNetwork.segment_containing(map.world_to_tile(plan.position))
			if segment and corridor.depth(segment.tile_rect().position) == 0:
				streets[segment.key()] = segment
		for key: Vector3i in streets:
			var segment: StreetNetwork.Segment = streets[key]
			paced_streets += 1
			var rect := map.tile_rect_to_world(segment.tile_rect())
			var standing: Array[EventScheduler.Planned] = []
			for plan in counted:
				if EventScheduler._reach_touches(plan, rect,
						EventScheduler._line_reach_of(plan.def)):
					standing.append(plan)
			if _a_walk_along_the_street(map, segment, standing):
				continue
			closed += 1
			if first == "":
				var ids := {}
				for plan in standing:
					ids[plan.def.id] = true
				first = "day %d, street %s, held by [%s]" \
						% [day, key, ", ".join(PackedStringArray(ids.keys()))]
	t.check(paced_streets >= 3,
			"the days sampled pace a row along the route's own streets (%d)" % paced_streets)
	t.check(closed == 0, "and the beat's opening is left open on every one (%d closed%s)"
			% [closed, "" if first == "" else ": " + first])

## **A flock is scenery — overturned on 2026-09-13**, PLAYTEST-71: *"flocks are basically free
## already — don't count it as block, just count is scenery."* Under the plain cost rule a
## 42-over-168px field crosses `Tuning.WALL_WORTH_OF_COST`, so without `EventDef.scenery`
## `_role_for` would call `pigeon_flock` a `WALL` and `_copies_of` would pull it off every route
## corridor the way any other expensive row is. `scenery` is checked first and answers `NONE`.
##
## Two claims. The role is a fact about the def, checked directly on every placement the day
## makes. Whether one actually **lands** on the corridor is a fact about the roll rather than
## about the rule, so it is checked the way `_test_alley_robbery_never_lands_on_a_required_alley`
## checks the opposite claim — over several days on a real generated map, until at least one
## placement turns up at `corridor.depth(tile) == 0`. A check that never saw an on-corridor flock
## would hold whether the exemption worked or not.
func _test_a_flock_is_scenery(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	t.check(def.scenery, "the flock def is marked scenery")

	var on_corridor := 0
	var off_corridor := 0
	var map := CityGenerator.generate(4242)
	var consumed: Array[String] = []
	for day in [1, 4, 8, 11, 14]:
		var tree := RouteTree.for_day(map, day)
		var corridor := Corridor.of(tree)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d" % [4242, day])
		for plan in EventScheduler.build_day(day, rng, map, consumed, [], [], tree):
			if plan.def.id != "pigeon_flock" or not plan.is_placed():
				continue
			t.check(plan.role == GameEnums.BlockerRole.NONE,
					"day %d: a placed flock carries no role, not a wall's" % day)
			var tile := map.world_to_tile(plan.position)
			if corridor.depth(tile) == 0:
				on_corridor += 1
			else:
				off_corridor += 1
	t.check(on_corridor > 0,
			"a flock lands on the day's own corridor at least once (%d on, %d off)"
			% [on_corridor, off_corridor])

# -------------------------------------------------------------- chatting_mother (M59) ---
# The one row whose whole mechanic is time under compulsion rather than a field: entering
# `detain_radius` locks the player's own movement input, and what she is charged while it holds
# depends on the baby's state rather than on anything the def can see. An `EventManager` is built
# by hand — nothing here needs a real `City` — and its trigger (`_check_detentions()`) and its
# per-frame handoff (`_tell_them_where_she_is()`) are driven directly, the same shape
# `test_danger.gd` drives `_warn_about_the_ground_she_is_on()` in: a per-frame method with no
# signal of its own to trigger from outside.

## A `WorldContext` whose `excitement_sources_at`/`total_excitement_at` read straight off a
## hand-built `EventManager`, the same questions `City` answers for real. Lets a real `Baby` be
## driven against the chat's own math without pulling in a whole generated city. `Baby` now sums
## `excitement_sources_at()` rather than calling `total_excitement_at()` directly, so both have to
## be forwarded or the mother's own conversation is invisible to a baby driven against this double.
class _ChatWorld extends WorldContext:
	var manager: EventManager
	func excitement_sources_at(world_position: Vector2) -> Array:
		return manager.excitement_sources_at(world_position)
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
			# Playtest 38, finding 4: "there is also no real fade from yellow to red (eg when
			# standing next to the other baby lady". Holding this first is what tells the ramp's own
			# shape (`ExcitementHalo.colour_for()`) apart from an attribution bug: the chat's flat
			# rate does reach `contribution_at()` inside her field and land on the mother's own
			# `landed()`, past `Tuning.EXPECTED_IMPACT_POINTS`'s own midpoint, so a dull colour on
			# screen would have been the ramp and not the meter.
			t.close_to(mother.landed(), Tuning.CHAT_EXCITEMENT,
					"and the mother's own landed() carries the same points, which is what " +
					"colour_for() reads", 2.0)
		else:
			t.close_to(baby.excitement, starting_excitement,
					"asleep, the same conversation is a pure time loss: the meter does not move",
					0.5)
			t.close_to(baby.sleepiness, 100.0, "and sleepiness stays pinned at 100 asleep", 0.01)

		mother.free()
		stroller.free()
		world.free()
		manager.free()

## `chatting_mother`'s capture reaches *past* `Tuning.TILE_SIZE` (32px), the spacing between the
## two lanes of a pavement the row used to be tucked under — see
## `EventCatalogue._chatting_mother`, "the far-lane rule is overturned". So the far lane catches
## her, and this checks both halves of that geometry: the far lane triggers, and a point just
## outside `EventDef.detain_distance()` but still inside `inner_radius` does not — the ambient
## field reaches her there and only the conversation must not. She paces, so she carries no body
## and her reach is measured from her own centre.
func _test_a_conversation_only_starts_inside_detain_radius(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(4000.0, 4000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])

	var far_lane := _instance(t, def, at, path)
	var far_manager := _chat_manager()
	far_manager._instances.append(far_lane)
	var far_stroller := _chat_stroller(t)
	far_manager._player = far_stroller
	far_stroller.global_position = at + Vector2(0.0, Tuning.TILE_SIZE)
	far_manager._tell_them_where_she_is()
	far_manager._check_detentions()
	t.check(far_stroller.is_detained(),
			"the far lane of a two-tile pavement now starts a conversation too")
	far_lane.free()
	far_stroller.free()
	far_manager.free()

	var mother := _instance(t, def, at, path)
	var manager := _chat_manager()
	manager._instances.append(mother)
	var stroller := _chat_stroller(t)
	manager._player = stroller

	# Just outside the capture and well inside inner_radius: the ambient field still reaches her
	# and only the conversation must not.
	t.check(def.detain_distance() < def.inner_radius,
			"there is ground outside her capture and inside her field to stand on (%.1f < %.1f)"
			% [def.detain_distance(), def.inner_radius])
	stroller.global_position = at + Vector2(0.0, def.detain_distance() + 0.5)
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not stroller.is_detained(),
			"just outside the capture, no conversation starts")
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
