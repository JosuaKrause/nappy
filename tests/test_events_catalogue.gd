extends RefCounted
## The catalogue's own fairness contract: the physical and visual shape every row keeps regardless
## of where the scheduler places it -- the geometry a `spread` body draws at, that it fits the
## ground it stands on (a `SIDEWALK` band or a carriageway tile), that it rotates to the street it
## is on, that a crash is solid only where its cars actually are, and that no two rows share a
## picture or a silhouette a badge could draw.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again" -- this half is the
## catalogue's own static contract, checked without a generated city or a live `EventManager`.
##
## *(M37, playtest 07 finding 2: "not sure what that person was supposed to be".)* The vocabulary's
## first row is that **the entity itself carries most of it**, and the catalogue had been quietly
## failing it since M5: five category looks -- `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL`, `FIRE` --
## were drawing sixteen of the twenty-eight visible rows between them.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_protest_stays_something_she_can_be_routed_through(t)
	_test_one_barrier_costs_less_than_the_hold_it_stands_at(t)
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
	_test_no_two_rows_draw_the_same_picture(t)
	_test_every_look_carries_its_own_silhouette(t)


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
## `EventInstance._cap_offset` and `_cap_along` are the pure arithmetic the drawing calls, so this
## asserts the outer edge they produce against the real asset size and the real `obstructs_radius`
## of `construction`, broadside and end-on.
func _test_a_spread_cap_matches_what_it_obstructs(t) -> void:
	var def := EventCatalogue.by_id("construction")
	var half := maxf(11.0, def.obstructs_radius)
	var cap_size := EventInstance._native_size(EventInstance.BARRIER_END)
	var cap_along := EventInstance._cap_along(cap_size)
	var offset := EventInstance._cap_offset(half, cap_along, 1.0)
	t.check(is_equal_approx(offset + cap_along * 0.5, half),
			"the cap's outer edge (%.1f) lands on the %.1fpx obstruction, not past it"
			% [offset + cap_along * 0.5, half])
	t.check(not is_equal_approx(offset, half),
			"and it is not simply centred at ±half any more (%.1f)" % offset)
	# End-on, the extent along the run is the post's picture height; what it covers of the run is
	# still its width. The near post's feet stand within that width of the barrier's near end —
	# inside the last segment's own slice of ground, which ends at the end of the body — rather
	# than half a post's height in toward the middle.
	var segment := EventInstance._native_size(EventInstance.BARRIER_SEGMENT_VERTICAL)
	var segments := maxi(1, ceili(half * 2.0 / segment.y))
	var width := half * 2.0 / segments
	var last_slice_starts := EventInstance._spread_slice_feet(true, half, width, segments - 1) - width
	t.check(cap_size.y > cap_size.x * 2.0,
			"the post is an upright picture (%s), so its height and width are different questions"
			% cap_size)
	t.check(half - offset <= cap_size.x and offset > last_slice_starts,
			"end-on, the near post stands at the barrier's end (%.1f of %.1f), inside the last"
			% [offset, half] + " segment's slice (from %.1f)" % last_slice_starts)
	# The spread is one node, so draw order is its only depth. End-on, the side drawn behind the
	# board has to be the far end, up the screen (`_spread_at` puts side −1 at negative y), and
	# the near end is the only one drawn over it; broadside, both stand level with the board.
	var behind := EventInstance._cap_sides(true, true)
	var in_front := EventInstance._cap_sides(true, false)
	t.check(behind.size() == 1 and behind[0] < 0.0 and in_front.size() == 1 and in_front[0] > 0.0,
			"end-on, the far post is drawn behind the board (%s) and only the near one over it (%s)"
			% [behind, in_front])
	t.check(EventInstance._cap_sides(false, true).is_empty()
			and EventInstance._cap_sides(false, false).size() == 2,
			"broadside, both posts are drawn over the board")

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

## No two rows draw the same picture, and the rows that draw nothing are named.
##
## The `NONE` exemption is spelled out rather than skipped, because `look` has no useful default
## any more — a row that forgets to choose one is invisible, which is the quietest way for an
## event to stop working.
func _test_no_two_rows_draw_the_same_picture(t) -> void:
	# Three rows are legitimately invisible: something else already draws the ground they stand
	# on, a mast's own picture carries its curfew announcement too (`EventCatalogue.
	# _curfew_announce()`), or — the finale's explosion — the whole of the row is that it happens
	# somewhere she cannot see, and what it leaves behind is a different row.
	var invisible := ["playground", "curfew_announce", "finale_explosion"]
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
