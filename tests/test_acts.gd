extends RefCounted
## The escalation: act gating, the mechanics the later acts introduced, and the invariants
## that stop a late day from being quietly unwinnable.

const SEED := 4242
const STEP := 1.0 / 60.0
const CITY_SCENE := preload("res://scenes/world/city.tscn")

var _map: CityMap

func run(t) -> void:
	_map = CityGenerator.generate(SEED)
	_test_acts_are_gated_by_day(t)
	_test_a_protest_grows(t)
	_test_scars_outlive_the_day_that_made_them(t)
	_test_the_scarred_building_shows_burnt(t)
	_test_a_park_stays_reachable_every_day(t)
	_test_act_tints_differ(t)

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

# -------------------------------------------------------------------- gating ---

func _test_acts_are_gated_by_day(t) -> void:
	# The boundaries themselves are `Tuning.ACT_START_DAYS` and are not restated here — a check
	# that reads that array back would only ever fail because somebody moved an act on purpose.
	# What is worth pinning is the relationship between two tables that do not know about each
	# other: the run is exactly as long as its last act, so no day falls off the end of the acts.
	t.check(Tuning.act_for_day(Tuning.RUN_LENGTH_DAYS) == 4, "the last day is act IV")

	# Nothing from a later act may leak into an earlier day.
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var act := Tuning.act_for_day(day)
		for def in EventCatalogue.available_on(day):
			t.check(def.act_tag <= act,
					"day %d (act %d) does not offer '%s' from act %d"
					% [day, act, def.id, def.act_tag])

# ------------------------------------------------------------------ mechanics ---

func _instance(t, def: EventDef, at := Vector2.ZERO) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

func _test_a_protest_grows(t) -> void:
	var def := EventCatalogue.by_id("protest")
	t.check(def.intensity_ramp > 1.0, "a protest swells rather than holding")
	var instance := _instance(t, def)
	_advance(instance, def.telegraph_time + 0.05)

	# Sample across whole pulse periods so the ramp, not the pulse, is what is compared.
	var early := _peak_over(instance, def.pulse_period)
	_advance(instance, def.duration * 0.75)
	var late := _peak_over(instance, def.pulse_period)
	t.check(late > early * 1.3, "a protest is markedly worse later than when you saw it")
	t.check(late <= def.intensity * def.intensity_ramp + 0.01,
			"and never exceeds its stated ceiling")
	instance.free()

func _peak_over(instance: EventInstance, seconds: float) -> float:
	var peak := 0.0
	for i in int(round(seconds / STEP)):
		instance._process(STEP)
		peak = maxf(peak, instance.current_intensity())
	return peak

## The burnt-out shell is on the same corner on day 12 as it was the morning after the fire.
func _test_scars_outlive_the_day_that_made_them(t) -> void:
	var saved := GameState.scars.duplicate(true)
	var saved_day := GameState.day

	GameState.day = 3
	GameState.scars = []
	var where := _map.tile_to_world(Vector2i(40, 40))
	GameState.add_scar("burnt_shell", where)
	GameState.add_scar("burnt_shell", where)
	t.check(GameState.scars.size() == 1, "the same scar is not recorded twice")

	var consumed: Array[String] = []
	var same_day := EventScheduler.build_day(3, _rng(3), _map, consumed, GameState.scars)
	t.check(not _contains(same_day, "burnt_shell"),
			"a scar does not double up on the day it was made")

	for day in [4, 9, 14]:
		var later: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), _map, later, GameState.scars)
		t.check(_contains(planned, "burnt_shell"),
				"the burnt-out shell is still there on day %d" % day)
		for plan in planned:
			if plan.def.id == "burnt_shell":
				t.close_to(plan.position.distance_to(where), 0.0,
						"and it is on the same corner", 1.0)

	GameState.scars = saved
	GameState.day = saved_day

## **The fire only catches where there is a building to burn, and burns on that building alone.**
## Every tile `burning_building`'s own placement (`AT_THE_FRONT`) offers has one of the city's
## `Building`s directly north of it — never the edge of the world, which `CityMap.tile_at()` reads
## as `BUILDING` — and the flames drawn there (`EventInstance._flames_across()`) burn along the
## whole of that building's own facade and stay inside it, including at a site on the first or last
## column of its lot: every column the city draws a facade on carries a flame, and no column another
## building's roof covers does. *"the fire should be on the whole building not only the door"*
## (sandy-egret).
##
## **Then the dawn after it shows that building burnt** — *"the building is what needs to be burnt,
## not an object next to the building"* — through `City.start_day()`, the way a real morning
## reaches `City.mark_the_burnt_frontage()`, from a scar recorded where a real fire sites.
func _test_the_scarred_building_shows_burnt(t) -> void:
	var saved := GameState.scars.duplicate(true)
	var saved_day := GameState.day
	GameState.day = 4
	GameState.scars = []

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

	var sites := {}
	for tile in EventScheduler._open_ground_for(EventCatalogue.by_id("burning_building"),
			city.map, {}):
		sites[tile] = true
	t.check(sites.size() > 100,
			"seed %d: there are fronts for the fire to catch on (%d)" % [SEED, sites.size()])
	var nothing_behind: Array[Vector2i] = []
	var spilled: Array[Vector2i] = []
	var bare: Array[Vector2i] = []
	var on_a_roof: Array[Vector2i] = []
	var at_a_lot_end := 0
	var wider_than_five := 0
	var size := float(Tuning.TILE_SIZE)
	for tile: Vector2i in sites:
		var behind := _building_at(city, tile + Vector2i.UP)
		if not behind:
			nothing_behind.append(tile)
			continue
		if tile.x == behind.lot.position.x or tile.x == behind.lot.end.x - 1:
			at_a_lot_end += 1
		var at := city.map.tile_to_world(tile)
		var facade := city.map.tile_rect_to_world(behind.lot)
		if facade.size.x > 80.0:
			wider_than_five += 1
		var flames := EventInstance._flames_across(EventInstance._facade_runs_at(city.map, at))
		for flame in flames:
			if at.x + flame.x - flame.y * 0.5 < facade.position.x - 0.01 \
					or at.x + flame.x + flame.y * 0.5 > facade.end.x + 0.01:
				spilled.append(tile)
				break
		# Each column's middle, against every flame's own width: a column the building draws is
		# burning, one another building's roof covers (`Building.covered_ground_cols`) is not.
		for col in behind.lot.size.x:
			var middle := facade.position.x + (col + 0.5) * size
			var burning := false
			for flame in flames:
				if absf(at.x + flame.x - middle) <= flame.y * 0.5:
					burning = true
			var drawn := not behind._is_covered(col)
			if drawn and not burning:
				bare.append(tile)
				break
			if burning and not drawn:
				on_a_roof.append(tile)
				break
	t.check(nothing_behind.is_empty(),
			"every front the fire can catch on has a building behind it (%d do not, first %s)"
			% [nothing_behind.size(), nothing_behind.slice(0, 3)])
	t.check(at_a_lot_end > 0,
			"and some of them stand at a lot's end, where flames could spill over (%d)" % at_a_lot_end)
	t.check(spilled.is_empty(),
			"the flames stay on the burning building's own facade (%d spill over, first %s)"
			% [spilled.size(), spilled.slice(0, 3)])
	t.check(wider_than_five > 0,
			"and some fronts are wider than five flames could cover (%d)" % wider_than_five)
	t.check(bare.is_empty(),
			"the whole facade burns, every column it draws (%d leave one bare, first %s)"
			% [bare.size(), bare.slice(0, 3)])
	t.check(on_a_roof.is_empty(),
			"and never a column another building's roof covers (%d do, first %s)"
			% [on_a_roof.size(), on_a_roof.slice(0, 3)])

	# **Never the power station's front**: its facade is drawn whole whatever its condition says,
	# and its transformer yard has no wall for day 8's arrow to end on. Guarded against vacuity by
	# the station's own fronts, which the same lane offers any row that does not burn.
	var fire := EventCatalogue.by_id("burning_building")
	var station := CityMap.blocks_tile_rect(city.map.power_station)
	t.check(city.map.has_power_station(), "seed %d has a power station" % SEED)
	var station_fronts := 0
	for tile in city.map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if EventScheduler._wants_this_side(fire, city.map, tile) \
				and station.has_point(tile + Vector2i.UP):
			station_fronts += 1
	t.check(station_fronts > 0,
			"seed %d: the power station has fronts on the lane (%d)" % [SEED, station_fronts])
	var on_the_station: Array[Vector2i] = []
	for tile: Vector2i in sites:
		if station.has_point(tile + Vector2i.UP):
			on_the_station.append(tile)
	t.check(on_the_station.is_empty(),
			"the fire never catches on the power station (%d fronts do, first %s)"
			% [on_the_station.size(), on_the_station.slice(0, 3)])

	var site: Vector2i = sites.keys()[sites.size() / 2]
	var scarred := _building_at(city, site + Vector2i.UP)
	t.check(scarred != null, "the fire's site has a building behind it")
	if not scarred:
		city.free()
		GameState.scars = saved
		GameState.day = saved_day
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	city.start_day(CityState.new(), 4, rng)
	t.check(_burnt_count(city) == 0, "no building is burnt before any fire has left a scar")

	GameState.add_scar("burnt_shell", city.map.tile_to_world(site))
	city.start_day(CityState.new(), 4, rng)
	t.check(scarred.condition == Building.Condition.BURNT,
			"the dawn after the fire, the building behind its scar is drawn burnt")
	t.check(_burnt_count(city) == 1, "and no other building is (%d are)" % _burnt_count(city))
	city.start_day(CityState.new(), 5, rng)
	t.check(scarred.condition == Building.Condition.BURNT and _burnt_count(city) == 1,
			"and every dawn after that, the same one")
	# Day 11's market boards its block up during the day (`present_block()`), and the burnt
	# building is never boarded up with it.
	city.present_block(city._block_of(scarred.lot), CityState.new())
	t.check(scarred.condition == Building.Condition.BURNT,
			"its block shown anew during the day leaves the burnt building burnt")

	city.free()
	GameState.scars = saved
	GameState.day = saved_day

## The one `Building` whose lot holds `tile`, or null.
func _building_at(city: City, tile: Vector2i) -> Building:
	for building in city._buildings:
		if building.lot.has_point(tile):
			return building
	return null

func _burnt_count(city: City) -> int:
	var burnt := 0
	for building in city._buildings:
		if building.condition == Building.Condition.BURNT:
			burnt += 1
	return burnt

func _contains(planned: Array, id: String) -> bool:
	for plan in planned:
		if plan.def.id == id:
			return true
	return false

# ----------------------------------------------------------------- invariants ---

## From act II onwards several events physically close streets, and from act IV a run can
## accumulate permanent barricades. Any combination that seals the home off from every park
## makes the day unwinnable in a way the player cannot see coming.
func _test_a_park_stays_reachable_every_day(t) -> void:
	var saved := GameState.scars.duplicate(true)
	# Stack the deck: pretend several convoys have already left barricades around.
	GameState.scars = []
	for tile in [Vector2i(20, 45), Vector2i(45, 20), Vector2i(70, 45), Vector2i(45, 70)]:
		GameState.scars.append({
			"id": "barricade", "position": _map.tile_to_world(tile), "since_day": 1,
		})

	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), _map, consumed, GameState.scars)
		# Typed deliberately: passing a bare `Array` here makes GDScript coerce it at the
		# call boundary, and that coercion leaves the CityMap alive at shutdown ("N
		# ObjectDB instances were leaked"). Declaring the real element type avoids it.
		var blockers: Array[EventScheduler.Planned] = []
		for plan in planned:
			if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
				blockers.append(plan)
		var grid := ReachabilityGrid.build(_map)
		t.check(EventScheduler._park_is_reachable(_map, grid, blockers),
				"day %d leaves a walkable route from home to a park" % day)

	GameState.scars = saved

func _test_act_tints_differ(t) -> void:
	var seen: Array[Color] = []
	for act in [1, 2, 3, 4]:
		var tint := Palette.act_tint(act)
		for other in seen:
			t.check(not tint.is_equal_approx(other), "act %d has its own cast" % act)
		seen.append(tint)
	# The city gets colder, not warmer: blue rises relative to red across the run.
	var first := Palette.act_tint(1)
	var third := Palette.act_tint(3)
	t.check(third.b / third.r > first.b / first.r,
			"act III is cooler than act I")
