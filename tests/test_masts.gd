extends RefCounted
## The masts: fixed sites from `Tuning.MAST_FIRST_DAY`, a field like any other row's, a broadcast
## clock every mast reads rather than a clock of its own, and an id that survives silencing. See
## `docs/TODO.md`, M180, "Posters she notices, and loudspeakers that are somewhere".
##
## The sites and the field are asked of `MastSites` and the row alone, and the points a day's
## street doors stand on of `MastSites` against `RegionPlanner`'s own plan, run real because the
## guarantee is between the two. The broadcast clock, streaming, mast_foot() and silencing are
## the event manager's, so a real manager is built, over the cached generated map of its seed
## with no city round it, and handed mast plans made by hand as the dawn makes them
## (`DawnMasts`). What the dawn plans (the same sites every day from the first mast day, the
## scar a silenced mast leaves) is `test_events_scheduler.gd`'s. The scheduler's acceptance of a
## mast queued for day 11 (`EventManager.queue_a_mast()`) is asked of a manager of its own,
## handed the cached map as the city's (`EventSurroundings.in_the_city()`), which is what siting
## a mast asks of it; no day is planned, since planning one would also ask for the city's route
## tree.

const MapCache := preload("res://tests/city_map_cache.gd")
const SEED := 4242
## The seed of the city every task scene is built on.
const CONTEXT_SEED := 1917501
const FAST_SCALE := 5.0
## A handful of seeds, for the one guarantee that has to hold on more than the seed the rest of
## this suite happens to use — `docs/EVENTS.md`'s "checked before it is accepted" — the same reason
## a city guarantee is measured across several seeds rather than trusted from one.
const SITE_SEEDS := [4242, 1, 90210, 778812345]

var _map: CityMap
var _world: WorldContext
var _manager: EventManager

func run(t: TestRunner) -> void:
	_map = MapCache.of(SEED)
	_test_no_row_is_city_wide(t)
	_test_the_sites_are_the_same_geometry_every_time(t)
	_test_a_mast_never_reaches_the_doorstep_or_a_calm_interior(t)
	_test_a_door_a_recipe_stands_is_a_point_a_mast_keeps_clear_of(t)
	_test_the_field_is_zero_outside_its_reach_and_falls_off_inside_it(t)
	_build_manager(t)
	await _test_they_all_speak_together(t)
	_test_mast_foot_answers_a_stable_id(t)
	_test_silencing_one_mast_works_for_the_rest_of_the_day(t)
	_test_silencing_every_mast_works_for_the_rest_of_the_day(t)
	_test_a_queued_mast_is_never_generated_inside_a_lethal_field(t)
	_teardown()

## Stands the masts of a day on the manager as the dawn plans them (`DawnMasts`), in place of
## whatever day the manager held (it is cleared first): one loudspeaker plan at each site's foot,
## known by the site's id, and on the curfew announcement's day a `curfew_announce` plan beside
## each, the two a site carries. The manager's streaming takes them as it takes a day's, and the
## dawn's own choice of them is `test_events_scheduler.gd`'s.
func _start(with_the_announcement := false) -> void:
	var plans: Array[EventPlan] = []
	var loudspeaker := Shipped.rows().mast()
	for site in _sites():
		var mast := EventPlan.new(loudspeaker, site.foot())
		mast.stand_as_a_mast(site.id())
		plans.append(mast)
		if with_the_announcement:
			var announcement := EventPlan.new(Shipped.rows().by_id("curfew_announce"),
					site.foot())
			announcement.stand_as_a_mast(site.id())
			plans.append(announcement)
	# The focus is far off the map, so nothing streams in until a test walks to a mast.
	_manager.start_recipe(plans, DaySpec.for_day(1), 1, Vector2(-1.0e6, -1.0e6))

# ---------------------------------------------------------------- no floor ---

## The property itself is gone, checked the one way that cannot fail to compile against a field
## that no longer exists: `Object.get()` is the dynamic accessor, and it answers `null` for a
## property nobody declared rather than raising the parse error a static `def.city_wide` would.
func _test_no_row_is_city_wide(t: TestRunner) -> void:
	t.check(EventDraft.new("").build().get("city_wide") == null,
			"EventDef carries no city_wide field any more")
	var loudspeaker := Shipped.rows().by_id("loudspeaker")
	var curfew := Shipped.rows().by_id("curfew_announce")
	t.check(loudspeaker.heard_within() > loudspeaker.core_within(),
			"the loudspeaker has an edge a route can go round")
	t.check(curfew.heard_within() > curfew.core_within(),
			"so does the curfew announcement it carries on DawnMasts.CURFEW_ANNOUNCE_DAY")

# ------------------------------------------------------------------- sites ---

func _test_the_sites_are_the_same_geometry_every_time(t: TestRunner) -> void:
	# Pure geometry, called twice: MastSites.compute() takes no day and no RNG, so "the same
	# places every day" is true of the function itself and not only of what build_day did with it.
	var once := MastSites.compute(Shipped.rows(), _map)
	var again := MastSites.compute(Shipped.rows(), _map)
	t.check(once.size() == Tuning.MAST_COUNT and again.size() == Tuning.MAST_COUNT,
			"MastSites.compute() always answers Tuning.MAST_COUNT sites (%d, %d)"
			% [once.size(), again.size()])
	for i in once.size():
		t.check(once[i].id() == again[i].id() and once[i].foot().distance_to(again[i].foot()) < 0.01,
				"site %d is the same site both times" % i)

## Checked over several seeds — the one guarantee here that a single lucky map cannot stand for.
func _test_a_mast_never_reaches_the_doorstep_or_a_calm_interior(t: TestRunner) -> void:
	var checked := 0
	for seed_value: int in SITE_SEEDS:
		var map := MapCache.of(seed_value)
		var reach := Shipped.rows().by_id("loudspeaker").heard_within()
		var doorstep := map.doorstep_world_position()
		var home := map.home_world_position()
		var home_margin := MastSites.MAST_HOME_STREET_MARGIN * float(CityMap.period()) * Tuning.TILE_SIZE
		for site in MastSites.compute(Shipped.rows(), map):
			checked += 1
			var tile_type := map.tile_at(map.world_to_tile(site.foot()))
			t.check(tile_type == GameEnums.TileType.SIDEWALK or tile_type == GameEnums.TileType.SQUARE,
					("seed %d: '%s' stands on her own sidewalk or a square's paving, not tile "
					% [seed_value, site.id()]) + "type %d (a mast is never in the middle of the road)"
					% tile_type)
			t.check(site.foot().distance_to(doorstep) >= reach,
					"seed %d: '%s' does not reach the doorstep (%.0fpx away, reach %.0fpx)"
					% [seed_value, site.id(), site.foot().distance_to(doorstep), reach])
			t.check(site.foot().distance_to(home) >= home_margin,
					"seed %d: '%s' is not on the home street" % [seed_value, site.id()])
			var seen := {}
			for block in map.calm_blocks_now():
				var anchor := map.anchor_of(block)
				if seen.has(anchor):
					continue
				seen[anchor] = true
				var interior := map.tile_rect_to_world(map.lot_rect(block)).grow(
						-MastSites.MAST_CALM_INTERIOR_MARGIN)
				if not interior.has_area():
					continue
				var closest := Vector2(clampf(site.foot().x, interior.position.x, interior.end.x),
						clampf(site.foot().y, interior.position.y, interior.end.y))
				t.check(site.foot().distance_to(closest) >= reach,
						"seed %d: '%s' does not reach the interior of the calm block at %s"
						% [seed_value, site.id(), block])
	t.check(checked == Tuning.MAST_COUNT * SITE_SEEDS.size(),
			"and every mast on every seed was actually checked (%d)" % checked)

## The street door a recipe's `setup.gates` stands is the one the day's own plan stands
## (`RegionPlanner.stand_door()`), at the points `MastSites` keeps a mast's field clear of: so a
## mast `SceneRecipeRuntime` places is already clear of every door it stands, by
## `MastSites.is_eligible()` alone. Asked of every street door a day plans
## (`RegionPlanner.plan_day()`) on the context city (the city every task scene is built on),
## from the first day with checkpoints and on the last.
func _test_a_door_a_recipe_stands_is_a_point_a_mast_keeps_clear_of(t: TestRunner) -> void:
	var map := MapCache.of(CONTEXT_SEED)
	var points := MastSites.possible_door_points(map)
	var bodies := 0
	var off_a_point := 0
	for day: int in [Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS - 1]:
		var plan := RegionPlanner.plan_day(Shipped.rows(), map, DaySpec.for_day(day),
				RouteTree.for_day(map, day, null))
		var stood := RegionPlan.new()
		for door in plan.door_segments():
			RegionPlanner.stand_door(Shipped.rows(), map, door, stood)
		for body in stood.door_plans():
			bodies += 1
			var nearest := INF
			for point in points:
				nearest = minf(nearest, point.distance_to(body.placed_at()))
			off_a_point += int(nearest > 0.01)
	t.check(bodies > 0 and off_a_point == 0,
			"every one of the %d bodies of a day's street doors stands on a point a mast keeps "
			% bodies + "clear of (%d do not)" % off_a_point)

# ------------------------------------------------------------------- field ---

func _test_the_field_is_zero_outside_its_reach_and_falls_off_inside_it(t: TestRunner) -> void:
	var def := Shipped.rows().by_id("loudspeaker")
	t.check(is_zero_approx(def.emission_at_distance(def.heard_within() + 1.0)),
			"the field is zero just past its own outer radius")
	var at_inner := def.emission_at_distance(def.core_within())
	var at_middle := def.emission_at_distance((def.core_within() + def.heard_within()) * 0.5)
	var at_outer := def.emission_at_distance(def.heard_within() - 1.0)
	t.check(at_inner > at_middle and at_middle > at_outer and at_outer > 0.0,
			"the field falls away between the inner and outer radius (%.2f > %.2f > %.2f > 0)"
			% [at_inner, at_middle, at_outer])
	t.check(is_equal_approx(def.emission_at_distance(0.0), at_inner),
			"and is flat inside the inner radius, like any other row's")

# -------------------------------------------------------------- the broadcast ---

func _build_manager(t: TestRunner) -> void:
	_world = WorldContext.new()
	t.add_child(_world)
	var run := RunState.new()
	run.start_run(SEED)
	_manager = EventManager.new(Shipped.rows(), EventSurroundings.new()
			.on(_map).drawn_in(_world))
	_manager.setup(run)
	t.add_child(_manager)
	# No player in this rig, so nothing streams on its own — `EventManager._physics_process()`
	# skips streaming while no player is handed in (`EventWorld.has_player()`), the same reason
	# `test_event_manager.gd` gives.
	# Streaming below is driven by hand, at whatever real moment each check wants a mast live.
	_manager.stream_within(10.0)

func _sites() -> Array[MastSites.Site]:
	return MastSites.compute(Shipped.rows(), _map)

## Lets `seconds` of the game's own clock pass in real physics frames, the engine sped up for the
## stretch (each frame then carries `1 / Engine.physics_ticks_per_second * Engine.time_scale`
## seconds) and put back after it. The frame in progress when the scale changes keeps the delta it
## started with, so one frame passes at the normal scale after; the checks that follow read a range.
func _advance(t: TestRunner, seconds: float) -> void:
	var frame := 1.0 / Engine.physics_ticks_per_second * FAST_SCALE
	var clock := Engine.time_scale
	Engine.time_scale = FAST_SCALE
	for i in maxi(1, int(round(seconds / frame))):
		await t.get_tree().physics_frame
	Engine.time_scale = clock
	await t.get_tree().physics_frame

func _plan_for(mast_id: String, row_id: String = "loudspeaker") -> EventPlan:
	for plan in _manager.plans():
		if plan.mast_id() == mast_id and plan.row_id() == row_id:
			return plan
	return null

## Two masts, met minutes apart, still read the same broadcast clock — the mechanism behind "all
## masts speak at once". `age` is set from the city's broadcast clock (`EventStreaming`) at the moment each
## one streams in (`EventStreaming.stream_in()`'s own doc), not from zero, so a mast met later in the day is
## not a mast that is "younger" — it is telling the same time as every other one.
func _test_they_all_speak_together(t: TestRunner) -> void:
	_start()
	var sites := _sites()
	t.check(sites.size() >= 2, "there are at least two masts to compare")
	if sites.size() < 2:
		return
	var a := sites[0]
	var b := sites[1]

	await _advance(t, 9.0)
	_manager.stream_around(a.foot())
	var plan_a := _plan_for(a.id())
	t.check(plan_a != null and plan_a.is_in_the_world(), "the first mast is live")
	if plan_a == null or not plan_a.is_in_the_world():
		return
	var age_a := _live(plan_a).age()

	await _advance(t, 6.0)
	# Walking to the second mast takes the first out of the world.
	_manager.stream_around(b.foot())
	var plan_b := _plan_for(b.id())
	t.check(plan_b != null and plan_b.is_in_the_world(), "the second mast is live")
	if plan_b == null or not plan_b.is_in_the_world():
		return
	var age_b := _live(plan_b).age()
	t.check(age_b > age_a + 5.0,
			"time genuinely passed between the two (%.1fs)" % (age_b - age_a))

	# The first mast streams back in on the very frame the second one is in the world: both read
	# the one clock, so their ages match although the first was first met minutes before.
	_manager.stream_around(a.foot())
	t.check(plan_a.is_in_the_world(), "the first mast is back in the world")
	if _live(plan_a):
		t.close_to(_live(plan_a).age(), age_b,
				"a mast streamed back in tells the same time as the one met minutes later", 0.05)

func _test_mast_foot_answers_a_stable_id(t: TestRunner) -> void:
	_start()
	var site := _sites()[0]
	t.check(_manager.mast_foot(site.id()).distance_to(site.foot()) < 0.01,
			"mast_foot() answers the same point MastSites named for this id")
	t.check(_manager.mast_foot("not_a_real_mast") == Vector2.INF,
			"and INF for an id today does not carry")

# -------------------------------------------------------------- silencing ---

func _test_silencing_one_mast_works_for_the_rest_of_the_day(t: TestRunner) -> void:
	_start()
	var target := _sites()[0]
	_manager.stream_around(target.foot())
	var plan := _plan_for(target.id())
	t.check(plan != null and plan.is_in_the_world(), "the mast is live before it is silenced")
	if not (plan and _live(plan)):
		return
	t.check(_live(plan).current_intensity() > 0.0, "and it is actually speaking")
	var nearby := target.foot() + Vector2(50.0, 0.0)
	# Asked once before silencing, on purpose: `contribution_at()` caches per `(age, position)`,
	# and silencing does not move `age` — without its own cache invalidation this would go on
	# answering the pre-silence figure for the rest of the tick; `EventInstance.silence()` drops that
	# cache (`ExcitementSource.invalidate_contribution()`) as it silences.
	var _primed := _live(plan).source().contribution_at(nearby)

	t.check(_manager.silence_mast(target.id()), "silencing a mast by id finds it")
	t.check(is_zero_approx(_live(plan).current_intensity()), "a silenced mast's field is gone")
	t.check(is_zero_approx(_live(plan).source().contribution_at(nearby)),
			"and contribution_at() answers zero in the same tick, not the pre-silence cache")
	t.check(not _live(plan).is_gone(), "but the mast still stands — it has not left")

	# Streamed out and back in, the silence holds.
	_manager.stream_around(Vector2(-99999.0, -99999.0))
	t.check(not plan.is_in_the_world(), "walking away streams it back out")
	_manager.stream_around(target.foot())
	t.check(plan.is_in_the_world(), "and walking back streams it in again")
	if _live(plan):
		t.check(_live(plan).is_silenced(), "still silenced — for the rest of the day")
		t.check(is_zero_approx(_live(plan).current_intensity()), "still no field")

func _test_silencing_every_mast_works_for_the_rest_of_the_day(t: TestRunner) -> void:
	_start(true)
	for site in _sites():
		_manager.stream_around(site.foot())
	# Today's own count of *standing* masts, read off the plans: the hand-built day stands one at
	# every site.
	var standing_ids := {}
	for plan in _manager.plans():
		if plan.mast_id() != "":
			standing_ids[plan.mast_id()] = true
	t.check(standing_ids.size() > 0 and standing_ids.size() <= Tuning.MAST_COUNT,
			"today carries between one and Tuning.MAST_COUNT masts (%d)" % standing_ids.size())

	var silenced := _manager.silence_all_masts()
	t.check(silenced == standing_ids.size(),
			("silencing every mast silences exactly the masts standing today (%d wanted, %d got) "
			% [standing_ids.size(), silenced])
			+ "— one per site, not one per row sharing that site on the curfew day")
	var mast_plans_checked := 0
	for plan in _manager.plans():
		if plan.mast_id() == "":
			continue
		mast_plans_checked += 1
		t.check(plan.is_silenced(), "'%s' at '%s' is silenced" % [plan.row_id(), plan.mast_id()])
		if _live(plan):
			t.check(is_zero_approx(_live(plan).current_intensity()),
					"'%s' at '%s' has no field" % [plan.row_id(), plan.mast_id()])
	t.check(mast_plans_checked == standing_ids.size() * 2,
			("and both of today's mast rows were checked (%d): the ordinary broadcast and "
			% mast_plans_checked) + "the curfew announcement, one pair per standing site")

## feathery-marmot, day 11's queued mast — *"if there is a mast queued up that will be the next
## event to be generated"* (quiet-yak, inbox #503). With a stationary
## `reversing_lorry` (lethal, 175px field) planned on a sidewalk, the mast is queued with only
## the sidewalk inside that field to stand on: the scheduler's acceptance refuses every tile, so no
## mast is generated, as `StreetInvalidation.room_around()` refuses any row inside a lethal field
## ("Nothing else happens inside a lethal event's field"). Offered sidewalk well clear of it, the mast
## is generated, joins the day's plan under an added id, and has room by the same rule. A mast put down
## where the director pointed, as before, fails the first half.
func _test_a_queued_mast_is_never_generated_inside_a_lethal_field(t: TestRunner) -> void:
	# A manager of its own, handed the city's map as the city's own (`in_the_city()`), which is what
	# planning a day, and so siting a mast in it, is asked over.
	var run := RunState.new()
	run.start_run(SEED)
	var manager := EventManager.new(Shipped.rows(), EventSurroundings.new()
			.in_the_city(_map).drawn_in(_world))
	manager.setup(run)
	t.add_child(manager)
	var map := _map
	var lorry_def := Shipped.rows().by_id("reversing_lorry")
	var walled: Array[Rect2i] = []
	var lorry_tile := Vector2i(-1, -1)
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if SpawnSiting.is_legal_ground(map, tile, walled) and not map.is_obstructed(tile) \
				and map.tile_to_world(tile).distance_to(map.doorstep_world_position()) > 600.0:
			lorry_tile = tile
			break
	var lorry := EventPlan.new(lorry_def, map.tile_to_world(lorry_tile))
	lorry.give_role(GameEnums.BlockerRole.FRICTION)
	# Planned with the walk, as a scene's recipe plans it: it streams in like any planned row
	# and its body is recorded where it stands.
	var planned: Array[EventPlan] = [lorry]
	manager.start_recipe(planned, DaySpec.for_day(11), 11, lorry.placed_at())
	var inside: Array[Vector2i] = []
	var clear: Array[Vector2i] = []
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if not SpawnSiting.is_legal_ground(map, tile, walled) or map.is_obstructed(tile):
			continue
		var gap := map.tile_to_world(tile).distance_to(lorry.placed_at())
		if gap > EventScheduler.EVENT_SPACING_ANY and gap < lorry_def.field_reach() - Tuning.TILE_SIZE:
			inside.append(tile)
		elif gap > lorry_def.field_reach() + 600.0 and gap < lorry_def.field_reach() + 900.0:
			clear.append(tile)
	t.check(not inside.is_empty() and not clear.is_empty(),
			"there is sidewalk inside the lorry's field and well clear of it (%d, %d)"
			% [inside.size(), clear.size()])
	var refused := manager.queue_a_mast(inside)
	t.check(refused == null, "offered only ground inside a lethal field, no mast is generated")
	var placed := manager.queue_a_mast(clear)
	t.check(placed != null and placed.mast_id().begins_with("added-")
			and placed in manager.plans(),
			"offered ground clear of it, a mast is generated into the day's plan")
	manager.free()

func _teardown() -> void:
	_manager.free()
	_world.free()

## The live event of `plan`, asked of the event manager.
func _live(plan: EventPlan) -> EventInstance:
	return _manager.event_of(plan)
