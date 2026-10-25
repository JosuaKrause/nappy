extends RefCounted
## The pursuer on foot: the one a torn poster's pursuit marble sends at her at once from off screen,
## a policeman through day 8 and a guardsman from day 9.
##
## The player's words *(inbox #591 in olive-hedgehog: "the poster pursuit should not be placed! it
## should happen instantly with the pursuer spawning off-screen! and it should be a proper pursuer
## not a police car -- maybe a policeman on foot?" · "the poster tear marble bag is a completely
## separate marble bag than the event marbles. nothing influences across them. the pursuer is not a
## scheduled event. it is instant! policemen get switched to guardman on day 9."; merry-stork, his
## catch: "Ends the day (Recommended)")*. A real `City` stands under every check that sends one,
## with a stand-in for her in the `"player"` group, the one thing `EventManager` asks of her here.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_the_two_rows_are_the_task_robbers_chase_in_a_uniform(t)
	_test_neither_is_ever_the_schedulers(t)
	_test_day_8_is_a_policeman_and_day_9_a_guardsman(t)
	_test_a_pursuit_marble_sends_him_at_once_from_off_screen_already_chasing(t)
	_test_a_second_marble_while_he_is_after_her_sends_nobody(t)
	_test_a_tear_and_its_pursuer_move_nothing_the_day_draws(t)
	_test_walking_away_is_caught_before_the_cap_and_running_shakes_him_off(t)
	_test_his_catch_ends_the_day_with_its_own_line(t)
	_test_the_man_out_of_the_car_owes_the_pursuit_contract(t)
	_test_his_stop_costs_her_and_never_ends_a_calm_day_by_itself(t)
	_test_he_waits_outside_a_hold_to_stop_her(t)
	_test_an_investigating_car_stops_on_its_road_and_a_policeman_gets_out(t)
	_test_the_whole_encounter_from_calm_never_ends_the_day(t)
	_test_an_investigating_car_never_stops_in_a_junction_box(t)
	_test_the_car_does_not_notice_her_through_a_building(t)
	_test_the_hunting_vans_hunt_on_foot(t)
	_test_no_vehicle_pursues_her(t)
	_test_a_hunting_van_stops_and_lets_men_out(t)
	_test_a_hunting_van_waits_for_its_men(t)

# ------------------------------------------------------------------ the rig ---

## A real city on `SEED`'s map in the tree, its events told it is `day`, and a stand-in for her at
## a sidewalk beside a building, returned as `[city, her]`.
func _city_with_her(t, day: int, seed_value := SEED) -> Array:
	var map := CityGenerator.generate(seed_value)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	city.events._day = day
	var her := Node2D.new()
	her.add_to_group("player")
	t.add_child(her)
	her.global_position = _a_sidewalk(map)
	return [city, her]

## The centre of a sidewalk tile on an east-west street, well inside the map and off the home block.
func _a_sidewalk(map: CityMap) -> Vector2:
	var middle := map.size / 2
	for radius in range(0, 40):
		for dx in range(-radius, radius + 1):
			var tile := middle + Vector2i(dx, radius)
			if map.tile_at(tile) == GameEnums.TileType.SIDEWALK and not map.is_on_home_block(tile) \
					and map.pavement_inward(tile).y != 0:
				return map.tile_to_world(tile)
	return map.tile_to_world(middle)

func _done(city: City, her: Node2D) -> void:
	her.free()
	city.free()

## Runs his warning down, a frame at a time, with her standing at `her`.
func _run_the_warning(city: City, her: Node2D) -> void:
	for i in int(1.0 / STEP):
		city.events._run_the_warnings(STEP, her.global_position)
		if city.events.pending_warnings().is_empty():
			return

# ------------------------------------------------------------------ the rows ---

## Every number of each is the task robber's (`robber_giving_chase`): his field, his 130px/s, his
## 26px catch and 116px lunge, the dog's half-second badge, no telegraph, the 30s cap — and his
## `hard_fail`. Only the picture and the id are their own.
func _test_the_two_rows_are_the_task_robbers_chase_in_a_uniform(t) -> void:
	var robber := EventCatalogue.by_id("robber_giving_chase")
	var looks := {"policeman_giving_chase": EventDef.Look.POLICEMAN_GIVING_CHASE,
			"guardsman_giving_chase": EventDef.Look.GUARDSMAN_GIVING_CHASE}
	for id: String in looks:
		var def := EventCatalogue.by_id(id)
		t.check(def != null, "the catalogue carries '%s'" % id)
		if not def:
			continue
		t.check(def.look == looks[id], "'%s' draws its own look" % id)
		t.check(def.warned_first and def.starts_by(PursuitSpec.Start.ARRIVES_CHASING) and def.telegraph_time == 0.0,
				"'%s' is warned of before it exists and arrives chasing, with no closing in" % id)
		t.check(is_equal_approx(def.offscreen_notice, robber.offscreen_notice)
				and def.offscreen_notice <= Tuning.WARNING_ALONE_MAX,
				"'%s' has the robber's %.1fs badge" % [id, robber.offscreen_notice])
		t.check(is_equal_approx(def.duration, Tuning.PURSUIT_TIME),
				"'%s' chases for the %.0fs cap" % [id, Tuning.PURSUIT_TIME])
		t.check(def.pursuit != null and is_equal_approx(def.chase_speed(), robber.chase_speed())
				and is_equal_approx(def.lethal_reach(), robber.lethal_reach())
				and is_equal_approx(def.standoff_reach(), robber.standoff_reach())
				and is_equal_approx(def.intensity, robber.intensity)
				and is_equal_approx(def.outer_radius, robber.outer_radius),
				"'%s' chases, catches and costs exactly as the task's robber" % id)
		t.check(def.hard_fail, "'%s' ends the day when he catches her" % id)
		t.check(def.shape != null and is_equal_approx(def.shape.reach(), robber.shape.reach()),
				"'%s' stands on the robber's own shape" % id)
		t.check(def.validate(), "'%s' passes the catalogue's own contracts" % id)

## Never placed by the scheduler and never in the day's queue: no day of the run, at any heat,
## offers either to the roll, its stream or its budget.
func _test_neither_is_ever_the_schedulers(t) -> void:
	for id: String in ["policeman_giving_chase", "guardsman_giving_chase"]:
		var offered := false
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			for heat in EventCatalogue.heat_levels():
				for def in EventCatalogue.available_on(day, heat):
					offered = offered or def.id == id
		t.check(not offered, "no day of the run, at any heat, offers '%s' to the scheduler" % id)

# ------------------------------------------------------------- day 8, day 9 ---

## "policemen get switched to guardman on day 9": through day 8 a policeman, from day 9 the guard,
## as the row and as what a pursuit marble actually sends.
func _test_day_8_is_a_policeman_and_day_9_a_guardsman(t) -> void:
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var expected := "guardsman_giving_chase" if day >= 9 else "policeman_giving_chase"
		t.check(EventCatalogue.on_foot_on(day).id == expected,
				"day %d's pursuer on foot is %s" % [day, expected])
	for day: int in [8, 9]:
		var rig := _city_with_her(t, day)
		var city: City = rig[0]
		var her: Node2D = rig[1]
		city.events.send_a_pursuer()
		_run_the_warning(city, her)
		var sent := city.events.sent_pursuer()
		var expected: EventDef.Look = EventDef.Look.GUARDSMAN_GIVING_CHASE if day == 9 \
				else EventDef.Look.POLICEMAN_GIVING_CHASE
		t.check(sent != null and sent.def.look == expected,
				"on day %d a pursuit marble sends %s" % [day,
				"a guardsman" if day == 9 else "a policeman"])
		_done(city, her)

# --------------------------------------------------------------- at once ---

## **At once, from off screen, already chasing**: the badge is up the moment the marble is drawn,
## with her standing still at the wall — no wait for a heading or a street — and nothing in the
## world; once its half second is up he is created wholly out of her sight, with a clear run at her,
## chasing from his first frame, and the counter is told once.
func _test_a_pursuit_marble_sends_him_at_once_from_off_screen_already_chasing(t) -> void:
	var rig := _city_with_her(t, 6)
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var told := [0]
	var on_sent := func() -> void: told[0] += 1
	EventBus.poster_pursuit_sent.connect(on_sent)
	var before := city.events.instances().size()
	city.events.send_a_pursuer()
	EventBus.poster_pursuit_sent.disconnect(on_sent)
	var warnings := city.events.pending_warnings()
	t.check(warnings.size() == 1 and warnings[0].def.id == "policeman_giving_chase",
			"the badge is up the moment the marble is drawn, with her standing still")
	t.check(city.events.instances().size() == before and city.events.sent_pursuer() == null,
			"and nothing is in the world yet")
	t.check(told[0] == 1, "the counter's poster-pursuit goes out as he is sent (%d)" % told[0])
	var start := city.events._where_the_sent_pursuer_starts(EventCatalogue.on_foot_on(6),
			her.global_position, Vector2.ZERO, true)
	t.check(start[1], "from a sidewalk in the city, his start has a clear run at her")
	_run_the_warning(city, her)
	var sent := city.events.sent_pursuer()
	t.check(sent != null, "once the badge's time is up he is in the world")
	if sent:
		var view := PendingWarning.seen_from(city.events.visible_view(), her.global_position)
		t.check(PendingWarning.is_out_of_sight(view, sent.def, her.global_position,
				sent.global_position),
				"created wholly out of her sight (%.0fpx off)"
				% sent.global_position.distance_to(her.global_position))
		t.check(sent.came_under_a_warning and not sent.is_telegraphing() and not sent.is_waiting(),
				"already chasing from his first frame, with no closing in")
		t.check(not city.events.plans().any(func(plan: EventScheduler.Planned) -> bool:
				return plan.live == sent), "and outside the day's plan")
	_done(city, her)

## One at a time: a second pursuit marble while his badge is up, or while he is after her, sends
## nobody more and tells the counter nothing; once he has given up, the next marble sends the next.
func _test_a_second_marble_while_he_is_after_her_sends_nobody(t) -> void:
	var rig := _city_with_her(t, 6)
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var told := [0]
	var on_sent := func() -> void: told[0] += 1
	EventBus.poster_pursuit_sent.connect(on_sent)
	city.events.send_a_pursuer()
	city.events.send_a_pursuer()
	t.check(city.events.pending_warnings().size() == 1 and told[0] == 1,
			"a second marble while his badge is up sends nobody (%d warnings, %d told)"
			% [city.events.pending_warnings().size(), told[0]])
	_run_the_warning(city, her)
	var first := city.events.sent_pursuer()
	city.events.send_a_pursuer()
	t.check(city.events.pending_warnings().is_empty() and told[0] == 1,
			"nor while he is after her")
	if first:
		first.give_up_the_chase()
	city.events.send_a_pursuer()
	t.check(city.events.pending_warnings().size() == 1 and told[0] == 2,
			"once he has given up, the next marble sends the next one")
	EventBus.poster_pursuit_sent.disconnect(on_sent)
	city.events.use_the_spec(DaySpec.for_section(DaySpec.Section.CITY,
			Tuning.FINALE_LENGTH_SECONDS))
	city.events._pending.clear()
	city.events._sent_after_her = null
	city.events.send_a_pursuer()
	t.check(city.events.pending_warnings().is_empty(), "and during the escape nobody is sent")
	_done(city, her)

## **"nothing influences across them"**: on a planned day, sending him and running his warning
## leaves the director's owed queue, its clock, its route bag and the day's stream exactly where
## they were.
func _test_a_tear_and_its_pursuer_move_nothing_the_day_draws(t) -> void:
	var rig := _city_with_her(t, 6)
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, 6])
	var consumed: Array[String] = []
	city.events.start_day(6, rng, consumed, her.global_position)
	var director := city.events._director
	var owed := director.owed()
	var next_in: float = director._next_in
	var state := rng.state
	var bag: MarbleBag = director._route
	var drawn := bag.drawn if bag else -1
	var in_front: Array = bag.bag_in_front().duplicate() if bag else []
	var bag_state := bag._rng.state if bag else 0
	var plans := city.events.plans().size()
	city.events.send_a_pursuer()
	_run_the_warning(city, her)
	t.check(city.events.sent_pursuer() != null, "on a planned day he is sent")
	t.check(director.owed() == owed and is_equal_approx(director._next_in, next_in)
			and rng.state == state, "the day's owed queue, its clock and its stream are untouched")
	t.check(bag == null or (bag.drawn == drawn and bag.bag_in_front() == in_front
			and bag._rng.state == bag_state), "and the route's bag draws what it would have")
	t.check(city.events.plans().size() == plans, "and nothing joins the day's plan")
	_done(city, her)

# ------------------------------------------------------------- the chase ---

## Walking straight away from him, from just out of sight above her, he catches her well within
## `Tuning.PURSUIT_TIME`, never giving up; running away as he is created, he gives up within a
## second. A bare instance, created as `EventManager.spawn_warned()` creates him.
func _test_walking_away_is_caught_before_the_cap_and_running_shakes_him_off(t) -> void:
	for id: String in ["policeman_giving_chase", "guardsman_giving_chase"]:
		var def := EventCatalogue.by_id(id)
		for running: bool in [false, true]:
			var pursuer := EventInstance.new()
			pursuer.setup(def, Vector2(0.0, -PendingWarning.least_distance() - 40.0))
			pursuer.came_under_a_warning = true
			pursuer.resume(EventManager.age_when_warned(def), 0.0)
			var at := Vector2.ZERO
			var elapsed := 0.0
			var caught := INF
			var speed := Tuning.RUN_SPEED if running else Tuning.WALK_SPEED
			while elapsed < def.duration + 1.0:
				at += Vector2.DOWN * speed * STEP
				pursuer.player_at = at
				pursuer.player_running = running
				pursuer._process(STEP)
				elapsed += STEP
				if pursuer.is_lethal_at(at):
					caught = elapsed
					break
				if pursuer.is_leaving or pursuer.is_finished:
					break
			if running:
				t.check(pursuer.gave_up and caught == INF and elapsed < 1.0,
						"'%s': running away, he gives up within a second (%.2fs)" % [id, elapsed])
			else:
				t.check(caught < def.duration and not pursuer.gave_up,
						"'%s': walking away, he catches her at %.1fs, before the %.0fs cap"
						% [id, caught, def.duration])
			pursuer.free()

## His catch ends the day, and the day says who it was.
func _test_his_catch_ends_the_day_with_its_own_line(t) -> void:
	for id: String in ["policeman_giving_chase", "guardsman_giving_chase"]:
		t.check(EventCatalogue.by_id(id).hard_fail, "'%s' is a hard fail" % id)
		var line: String = Texts.HARD_FAIL_TEXT.get(id, "")
		t.check(line != "", "'%s' has its own loss line" % id)

# ----------------------------------------------------------- out of the car ---

## The man an investigating patrol car lets out is the day's pursuer on foot, met in her view:
## not warned of from off screen and not arriving chasing, but standing where he got out with his
## hand raised for the badge's heads-up — `Tuning.WARNING_ALONE_MAX`, at least
## `Tuning.OFFSCREEN_WARNING_MIN` (inbox #764 in minty-lemur) — and then chasing under the pursuit contract, which
## `validate()` holds him to. **His catch is a stop, never the end of the
## day** *(inbox #669 in coral-lark: "it needs to give a substantial cost but not lethal directly")*: standing
## beside him she is reached only after his notice, and stopped rather than struck.
func _test_the_man_out_of_the_car_owes_the_pursuit_contract(t) -> void:
	for day: int in [8, 9]:
		var out := EventCatalogue.out_of_the_car(day)
		var own := EventCatalogue.on_foot_on(day)
		t.check(out.id == own.id and out.look == own.look,
				"day %d: the man out of a patrol car is %s" % [day, own.id])
		t.check(not out.hard_fail and is_equal_approx(out.stop_excitement,
				Tuning.OFFICER_STOP_EXCITEMENT),
				"day %d: and his catch is a stop of %.0f points, never the end of the day"
				% [day, out.stop_excitement])
		t.check(not out.warns_before_it_exists() and not out.starts_by(PursuitSpec.Start.ARRIVES_CHASING),
				"day %d: he gets out in her view, with no off-screen badge" % day)
		t.check(out.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) and out.pursuit.stands
				and is_equal_approx(out.telegraph_time, Tuning.WARNING_ALONE_MAX)
				and out.telegraph_time >= Tuning.OFFSCREEN_WARNING_MIN,
				"day %d: he stands with his hand raised for a %.1fs heads-up before he chases"
				% [day, out.telegraph_time])
		t.check(out.validate(), "day %d: and the pursuit contract holds him" % day)
		var her := Vector2.ZERO
		var man := EventInstance.new()
		man.setup(out, Vector2(60.0, 0.0))
		var stopped := INF
		var struck := false
		var elapsed := 0.0
		while elapsed < out.telegraph_time + 4.0:
			man.player_at = her
			man._process(STEP)
			elapsed += STEP
			struck = struck or man.is_lethal_at(her)
			if man.has_stopped_her():
				stopped = elapsed
				break
		t.check(stopped >= out.telegraph_time and stopped < INF,
				"day %d: standing beside him, he reaches her only after his notice (%.2fs)"
				% [day, stopped])
		t.check(not struck, "day %d: and his catch never strikes her" % day)
		man.free()

## **What reaching her costs** *(inbox #669 in coral-lark, the player: "we make it somewhat costly" · "it needs
## to give a substantial cost but not lethal directly" · "well if the excitement meter is already
## high it can be lethal")*: substantial — over a conversation's cost and over three contacts — and
## under the whole meter, so it never ends a calm day by itself, but more than the push at the cap
## that ends a high one (`Tuning.EXCITEMENT_OVERFLOW_TO_CRY`). Measured off his own field: standing
## beside him through the stop she takes the whole of it, and walking straight away the moment he
## reaches her takes little of it off — it is a moment, not a place; after the stop he charges
## nothing, walking back.
func _test_his_stop_costs_her_and_never_ends_a_calm_day_by_itself(t) -> void:
	var stop := Tuning.OFFICER_STOP_EXCITEMENT
	var contact := Tuning.BUMP_INTENSITY * Tuning.BUMP_DURATION * 0.5
	t.check(stop > Tuning.CHAT_EXCITEMENT and stop > 3.0 * contact,
			"a stop (%.0f) costs more than a conversation (%.0f) and three contacts (%.1f each)"
			% [stop, Tuning.CHAT_EXCITEMENT, contact])
	t.check(stop < Tuning.METER_MAX, "and less than the whole meter, so a calm day survives it")
	t.check(stop > Tuning.EXCITEMENT_OVERFLOW_TO_CRY,
			"but more than the push at the cap, so a meter already high can be ended by it")
	var out := EventCatalogue.out_of_the_car(8)
	for walks_away: bool in [false, true]:
		var man := EventInstance.new()
		man.setup(out, Vector2(60.0, 0.0))
		var her := Vector2.ZERO
		var landed := 0.0
		var after := 0.0
		var elapsed := 0.0
		while elapsed < out.telegraph_time + 8.0 and not man.is_finished:
			man.player_at = her
			man._process(STEP)
			elapsed += STEP
			if man.has_stopped_her() and not man.is_leaving:
				landed += man.contribution_at(her) * STEP
				if walks_away:
					her += Vector2.LEFT * Tuning.WALK_SPEED * STEP
			elif man.is_leaving:
				after += man.contribution_at(her) * STEP
		if walks_away:
			t.check(landed >= stop * 0.9,
					"walking away as he reaches her, she still takes %.1f of its %.0f" % [landed, stop])
		else:
			t.check(absf(landed - stop) <= 1.5,
					"standing beside him she takes the whole stop (%.1f of %.0f)" % [landed, stop])
		t.check(man.has_stopped_her() and after == 0.0,
				"and once he turns to walk back he charges nothing (%.2f)" % after)
		man.free()

## **Inside a district door's hold he waits for her**: the door's toll is all that reaches her
## there, so a stop would land nothing. Beside her through the whole hold he does not stop her; the
## frame she is let out, he does.
func _test_he_waits_outside_a_hold_to_stop_her(t) -> void:
	var out := EventCatalogue.out_of_the_car(8)
	var man := EventInstance.new()
	man.setup(out, Vector2(60.0, 0.0))
	var her := Vector2.ZERO
	var elapsed := 0.0
	man.she_is_held = true
	while elapsed < out.telegraph_time + 4.0:
		man.player_at = her
		man._process(STEP)
		elapsed += STEP
	t.check(not man.has_stopped_her() and man.global_position.distance_to(her) <= out.lethal_reach(),
			"held in a hut, he is beside her (%.0fpx) and has not stopped her"
			% man.global_position.distance_to(her))
	man.she_is_held = false
	man.player_at = her
	man._process(STEP)
	t.check(man.has_stopped_her(), "let out, she is stopped at once")
	man.free()

## A lane on an east-west street off the main road, with a sidewalk tile beside it: `[lane point,
## sidewalk point]` on `map`, or empty.
func _a_lane_beside_a_sidewalk(map: CityMap) -> Array:
	for y in range(2, map.size.y - 2):
		for x in range(12, map.size.x - 12):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.ROAD \
					or map.tile_at(tile + Vector2i.UP) != GameEnums.TileType.SIDEWALK:
				continue
			var run := true
			for dx in range(-10, 14):
				run = run and Tile.is_road(map.tile_at(tile + Vector2i(dx, 0)))
			if run and not map.is_on_home_block(tile + Vector2i.UP):
				return [map.tile_to_world(tile), map.tile_to_world(tile + Vector2i.UP)]
	return []

## One frame of what `EventManager` does for a vehicle and its men, with her where she
## stands: tell everything where she is, let out whoever is owed, tick every instance, and look for
## a day-ending catch.
func _tick(events: EventManager) -> void:
	events._tell_them_where_she_is()
	events._let_the_officers_out()
	for instance in events.instances().duplicate():
		instance._process(STEP)
	events._check_hard_fails()

## **The investigating car stops on its road, the man gets out and pursues her, reaches her, stops
## her, walks back and gets in, and the car drives on.** On a real city, through the manager's own
## steps: a heated patrol drives its lane toward her standing on the sidewalk beside it; it stays on
## its lane every frame, stops once she is within its reach, and the day's man — a policeman on day
## 8, a guardsman on day 9 — appears at its door on her side, with no badge; the car stands while he
## is out; standing still, she is reached after his notice and stopped, and the day does not end;
## he walks back along the way he came to the door he got out of and is gone there; and the car
## drives on along its route the way it was going — never turned round on the spot in her view.
func _test_an_investigating_car_stops_on_its_road_and_a_policeman_gets_out(t) -> void:
	for day: int in [8, 9]:
		var rig := _city_with_her(t, day)
		var city: City = rig[0]
		var her: Node2D = rig[1]
		var spot := _a_lane_beside_a_sidewalk(city.map)
		t.check(spot.size() == 2, "found a lane beside a sidewalk")
		if spot.size() != 2:
			_done(city, her)
			return
		var lane: Vector2 = spot[0]
		her.global_position = spot[1]
		var hot := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"),
				Tuning.RESISTANCE_GOAL)
		var route := PackedVector2Array([lane - Vector2(280.0, 0.0), lane + Vector2(400.0, 0.0)])
		for end in route:
			t.check(Tile.is_road(city.map.tile_type_at_world(end)), "its route is on the road")
		var car := city.events.spawn_extra(hot, route[0], route)
		var events := city.events
		var off_its_lane := 0.0
		var officer: EventInstance = null
		var door := Vector2.INF
		var out_at := INF
		var stopped_her_at := INF
		var back_at := Vector2.INF
		var stopped_at := Vector2.INF
		var car_moved := 0.0
		var turned_round := false
		var drove_on := 0.0
		var struck := [""]
		var on_struck := func(id: String) -> void: struck[0] = id
		EventBus.hard_fail_triggered.connect(on_struck)
		var elapsed := 0.0
		events._find_player()
		while elapsed < 30.0 and struck[0] == "" and drove_on < 40.0:
			_tick(events)
			elapsed += STEP
			off_its_lane = maxf(off_its_lane, absf(car.global_position.y - lane.y))
			turned_round = turned_round or car.facing_now().dot(Vector2.RIGHT) < 0.999
			if officer == null and car.its_officer() != null:
				officer = car.its_officer()
				# Where he was put down, the first point of his trail: this frame has already
				# stepped him toward her.
				door = officer.on_foot.trail[0]
				out_at = elapsed
				stopped_at = car.global_position
				t.check(events.pending_warnings().is_empty(),
						"day %d: he gets out with no off-screen badge" % day)
				var reach := door.distance_to(car.global_position)
				t.check(reach <= car.def.shape.radius + officer.def.shape.reach() + 2.0,
						"day %d: at the car's door (%.0fpx from its middle)" % [day, reach])
			if officer and is_instance_valid(officer):
				if stopped_her_at == INF and officer.has_stopped_her():
					stopped_her_at = elapsed
				back_at = officer.global_position
			if stopped_at != Vector2.INF:
				var out := officer != null and is_instance_valid(officer) and not officer.is_finished
				if out:
					car_moved = maxf(car_moved, car.global_position.distance_to(stopped_at))
				else:
					drove_on = car.global_position.x - stopped_at.x
		EventBus.hard_fail_triggered.disconnect(on_struck)
		var expected := "guardsman_giving_chase" if day >= 9 else "policeman_giving_chase"
		t.check(off_its_lane < 0.01, "day %d: the car kept to its lane (%.2fpx off it)"
				% [day, off_its_lane])
		t.check(stopped_at != Vector2.INF
				and stopped_at.distance_to(her.global_position) <= hot.notice_within() + 0.5,
				"day %d: it stopped once close to her (%.0fpx)"
				% [day, stopped_at.distance_to(her.global_position)])
		t.check(officer != null and is_instance_valid(officer) and officer.def.id == expected,
				"day %d: and %s got out" % [day, expected])
		t.check(car_moved < 0.01, "day %d: the car stood while he was out" % day)
		t.check(stopped_her_at < INF and stopped_her_at - out_at >= EventCatalogue.out_of_the_car(
				day).telegraph_time, "day %d: standing still, she is reached after his notice "
				% day + "(%.2fs) and stopped" % (stopped_her_at - out_at))
		t.check(struck[0] == "", "day %d: and the day does not end (%s)" % [day, struck[0]])
		t.check(back_at.distance_to(door) <= 1.0 and officer != null
				and (not is_instance_valid(officer) or officer.is_finished),
				"day %d: he walked back and got in at the door he got out of (%.1fpx from it)"
				% [day, back_at.distance_to(door)])
		t.check(drove_on >= 40.0, "day %d: and then the car drove on along its route (%.0fpx)"
				% [day, drove_on])
		t.check(not turned_round, "day %d: the way it was going, never turned round" % day)
		_done(city, her)

## **The whole encounter, from a calm meter, standing still, never ends the day by itself** — and
## costs her substantially. *(Inbox #669 in coral-lark, the player: "it needs to give a substantial cost but not
## lethal directly" · "well if the excitement meter is already high it can be lethal".)* On a real
## city through the manager's own steps, everything the day's events land on her where she stands,
## from the heated patrol coming up her street until the car, done with its man, has left her field
## or is gone: the car's approach, the man's notice and chase, his stop, his walk back, and the car
## driving on past her. No lights, so no car is held beside her by one. Standing still nothing
## decays (`Tuning.EXCITEMENT_DECAY_IDLE` is 0), so the sum is the meter from 0. Over the hand-made
## lane on days 8 and 9 and over real `_along_street_path()` routes on three seeds, her standing
## beside each at several places, the worst must stay under `Tuning.METER_MAX` by
## `ENCOUNTER_MARGIN` — the cap never reached, let alone the push past it that ends the day — and
## every encounter must cost more than his stop alone.
func _test_the_whole_encounter_from_calm_never_ends_the_day(t) -> void:
	t.check(is_zero_approx(Tuning.EXCITEMENT_DECAY_IDLE), "standing still, nothing decays")
	var hot := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"), Tuning.RESISTANCE_GOAL)
	var worst := 0.0
	var least := INF
	var encounters := 0
	for day: int in [8, 9]:
		var rig := _city_with_her(t, day)
		var city: City = rig[0]
		var her: Node2D = rig[1]
		var spot := _a_lane_beside_a_sidewalk(city.map)
		if spot.size() == 2:
			var lane: Vector2 = spot[0]
			her.global_position = spot[1]
			var landed := _the_whole_encounter(city, her, hot,
					PackedVector2Array([lane - Vector2(280.0, 0.0), lane + Vector2(400.0, 0.0)]))
			t.check(landed >= 0.0, "day %d: on the hand-made lane the man got out and was done" % day)
			if landed >= 0.0:
				encounters += 1
				worst = maxf(worst, landed)
				least = minf(least, landed)
		_done(city, her)
	for seed_value: int in [4242, 90210, 314159]:
		var rig := _city_with_her(t, 8, seed_value)
		var city: City = rig[0]
		var her: Node2D = rig[1]
		var map := city.map
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var routes := 0
		var tile := Vector2i(Tuning.STREET_WIDTH + 1, 0)
		for attempt in 4000:
			if routes >= 6:
				break
			tile = Vector2i(posmod(tile.x * 7 + 13 + attempt, map.size.x),
					posmod(tile.y * 5 + 29 + attempt * 3, map.size.y))
			if map.tile_at(tile) != GameEnums.TileType.ROAD or map.is_closed(tile):
				continue
			var route := EventScheduler._along_street_path(map, tile, hot, rng)
			if route.size() < 2 or route[0].distance_to(route[1]) < 400.0:
				continue
			routes += 1
			var along := (route[1] - route[0]).normalized()
			for fraction: float in [0.4, 0.6, 0.8]:
				var at := _beside(map, route[0].lerp(route[1], fraction), along)
				if at == Vector2.INF:
					continue
				her.global_position = at
				var landed := _the_whole_encounter(city, her, hot, route)
				if landed < 0.0:
					continue
				encounters += 1
				worst = maxf(worst, landed)
				least = minf(least, landed)
		_done(city, her)
	print("[test_pursuer_on_foot] the whole encounter, standing still from 0, over %d encounters: "
			% encounters + "%.1f to %.1f" % [least, worst])
	t.check(encounters >= 20, "%d whole encounters played out" % encounters)
	t.check(worst < Tuning.METER_MAX - ENCOUNTER_MARGIN,
			"the worst of them lands %.1f, under the whole meter by %.0f" % [worst, ENCOUNTER_MARGIN])
	t.check(least > Tuning.OFFICER_STOP_EXCITEMENT,
			"and the least costs her more than his stop alone (%.1f)" % least)

## How far under the whole meter the worst whole encounter has to stay: room for a source she
## passes on the way, on top of the push at the cap (`Tuning.EXCITEMENT_OVERFLOW_TO_CRY`) that
## would end the day.
const ENCOUNTER_MARGIN := 10.0

## Drives one heated patrol down `route` at her where she stands in `city`, through the manager's own
## steps with no lights, until it has let its man out, he is done, and the car has left her field
## or is gone — or 40s have passed, which leaves a car still standing beside her for her at a zebra
## she waits at, quiet, since it has not left her. Answers what landed on her, or -1 when the car
## never stopped for her or its man was not done. Everything the encounter put in the world is
## retired.
func _the_whole_encounter(city: City, her: Node2D, hot: EventDef,
		route: PackedVector2Array) -> float:
	var events := city.events
	var car := events.spawn_extra(hot, route[0], route)
	car.signals = null
	events._find_player()
	var landed := 0.0
	var officer: EventInstance = null
	var elapsed := 0.0
	while elapsed < 40.0:
		_tick(events)
		elapsed += STEP
		landed += events.total_excitement_at(her.global_position) * STEP
		if officer == null and car.its_officer() != null:
			officer = car.its_officer()
		var out_of_reach := car.global_position.distance_to(her.global_position) \
				> hot.outer_radius + hot.shape.reach()
		if car.is_finished or car.is_leaving or (car.investigation.has_investigated() and out_of_reach):
			break
	var finished := officer != null and (not is_instance_valid(officer) or officer.is_finished)
	for instance in events.instances().duplicate():
		events.retire(instance)
	events._retire_finished()
	return landed if finished else -1.0

## **It never stops in a junction box** *(sunny-finch: nothing enters a box it cannot leave)*, over
## real patrol routes rather than a hand-made one: on three seeds, `police_patrol`'s own
## `EventScheduler._along_street_path()` routes at full heat, her standing on the sidewalk beside
## the route at several places along it, the car driven until it stops for her. Wherever it stops,
## no part of its body — spine and width — is on a junction's tiles, the crossing street's
## corridor with its zebras; and some of those cars saw her from inside a box and drove on out of
## it first, so the rule is exercised and not only never met.
func _test_an_investigating_car_never_stops_in_a_junction_box(t) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"), Tuning.RESISTANCE_GOAL)
	var stops := 0
	var in_a_box := 0
	var drove_out := 0
	for seed_value: int in [4242, 90210, 314159]:
		var map := CityGenerator.generate(seed_value)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var routes := 0
		var tile := Vector2i(Tuning.STREET_WIDTH + 1, 0)
		for attempt in 4000:
			if routes >= 10:
				break
			tile = Vector2i(posmod(tile.x * 7 + 13 + attempt, map.size.x),
					posmod(tile.y * 5 + 29 + attempt * 3, map.size.y))
			if map.tile_at(tile) != GameEnums.TileType.ROAD or map.is_closed(tile):
				continue
			var route := EventScheduler._along_street_path(map, tile, hot, rng)
			if route.size() < 2 or route[0].distance_to(route[1]) < 400.0:
				continue
			routes += 1
			var along := (route[1] - route[0]).normalized()
			for fraction: float in [0.35, 0.55, 0.75, 0.9]:
				var her := _beside(map, route[0].lerp(route[1], fraction), along)
				if her == Vector2.INF:
					continue
				var result := _drive_until_it_stops(t, hot, route, map, her)
				if result.is_empty():
					continue
				stops += 1
				var car: EventInstance = result[0]
				if _body_on_a_junction(map, car):
					in_a_box += 1
				if result[1]:
					drove_out += 1
				car.free()
	t.check(stops >= 40, "real routes on three seeds stopped %d investigating cars" % stops)
	t.check(in_a_box == 0, "and none of them stood with its body in a junction box (%d did)"
			% in_a_box)
	t.check(drove_out > 0, "%d of them saw her from inside a box and drove out of it first"
			% drove_out)

## A walkable sidewalk point beside `at` across a route running `along`: the nearest sidewalk tile
## to either side within a street's width, or `Vector2.INF`.
func _beside(map: CityMap, at: Vector2, along: Vector2) -> Vector2:
	var across := along.orthogonal()
	for k in range(1, Tuning.STREET_WIDTH + 1):
		for side: float in [1.0, -1.0]:
			var point := at + across * side * float(k) * Tuning.TILE_SIZE
			if map.in_bounds(map.world_to_tile(point)) \
					and map.tile_at(map.world_to_tile(point)) == GameEnums.TileType.SIDEWALK:
				return point
	return Vector2.INF

## Drives a fresh heated patrol down `route` on `map` with her standing at `her` until it stops for
## her: `[car, saw her from inside a box]`, or empty when it reaches the end of its route without
## stopping. The car is left for the caller to free.
func _drive_until_it_stops(t, hot: EventDef, route: PackedVector2Array, map: CityMap,
		her: Vector2) -> Array:
	var car := EventInstance.new()
	car.setup(hot, route[0], route, (route[1] - route[0]).normalized(), map)
	t.add_child(car)
	car.set_process(false)
	var saw_in_a_box := false
	var elapsed := 0.0
	while elapsed < 60.0 and car.is_waiting() and not car.is_leaving and not car.is_finished:
		car.player_at = her
		car._process(STEP)
		elapsed += STEP
		if car.investigation.has_seen_her() and car.is_waiting():
			saw_in_a_box = true
	if car.is_waiting() or car.is_leaving or car.is_finished:
		car.free()
		return []
	return [car, saw_in_a_box]

## Whether any tile under the car's body — along its spine from tail to nose, and across its width
## — is on a junction: inside the crossing corridor as well as its own (`CityMap.junction_at()`).
func _body_on_a_junction(map: CityMap, car: EventInstance) -> bool:
	var axis := car.facing_now().normalized()
	var reach := car.def.shape.reach()
	for i in 17:
		for j in 3:
			var point := car.global_position + axis * lerpf(-reach, reach, float(i) / 16.0) \
					+ axis.orthogonal() * lerpf(-car.def.shape.radius, car.def.shape.radius,
					float(j) / 2.0)
			if CityMap.junction_at(map.world_to_tile(point)) != Vector2i(-1, -1):
				return true
	return false

# ------------------------------------------------------------ the hunting vans ---

## **A hunting van stops and lets men out** *(inbox #669 in coral-lark: "Van stops, men get out (Recommended)",
## and for the unmarked van "Same as the police")*: the night raid's and the unmarked van's hunting
## copies no longer pursue her themselves — they investigate, keeping their cold `hard_fail` — and
## let two men out, whose catch ends the day ("Ends the day (M56)"); cold each is what it always was.
func _test_the_hunting_vans_hunt_on_foot(t) -> void:
	for id: String in ["night_raid", "abduction"]:
		var cold := EventCatalogue.by_id(id)
		t.check(cold.hunts_on_foot and cold.lets_out == 2, "'%s' hunts on foot, with two men" % id)
		for level in EventCatalogue.heat_levels():
			var hot := EventCatalogue.heated(cold, level)
			var hunts := level >= Tuning.HEAT_HUNTS_LEVEL
			t.check(hot.pursuit == null and hot.hard_fail == cold.hard_fail,
					"'%s' heat %d: the van itself never chases her, and is as lethal as cold"
					% [id, level])
			t.check(hot.investigates == hunts, "'%s' heat %d: it lets men out iff it hunts"
					% [id, level])
			t.check(hot.validate(), "'%s' heat %d: and it is fair" % [id, level])
	for day: int in [8, 10]:
		var man := EventCatalogue.out_of_the_car(day, false)
		t.check(man.hard_fail and man.stop_excitement == 0.0 and man.validate(),
				"day %d: a hunting van's man ends the day when he catches her" % day)

## **No vehicle chases her like a running man, at any heat** *(azure-koala, finding 7: "police cars
## chasing the player behave like running people"; inbox #664: "I was chased by police cars still
## which is just silly")*: no row drawn as a vehicle (`EventInstance.WHEELS_BY_LOOK`) and no car
## that drives pursues her at any heat.
func _test_no_vehicle_pursues_her(t) -> void:
	var vehicles := 0
	for def in EventCatalogue.all():
		if not (def.drives or EventInstance.WHEELS_BY_LOOK.has(def.look)):
			continue
		vehicles += 1
		for level in EventCatalogue.heat_levels():
			t.check(not EventCatalogue.heated(def, level).pursuit != null,
					"'%s' at heat %d never pursues her" % [def.id, level])
	t.check(vehicles >= 3, "checked %d vehicle rows" % vehicles)

## **A hunting van waits for its men**: its `duration` runs from its notice, but it does not leave
## the kerb past `telegraph_time + duration` while a man it let out is still out; once he is back
## in, it leaves.
func _test_a_hunting_van_waits_for_its_men(t) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("abduction"), Tuning.RESISTANCE_GOAL)
	t.check(hot.duration > 0.0, "the hunting van has a duration of its own (%.0fs)" % hot.duration)
	var van := EventInstance.new()
	van.setup(hot, Vector2.ZERO)
	t.add_child(van)
	van.set_process(false)
	var far := Vector2(hot.notice_within() - 10.0, 0.0)
	van.player_at = far
	van._process(STEP)
	t.check(van.officers_owed() == 2, "it notices her and owes two men")
	var men: Array[EventInstance] = []
	for i in 2:
		var man := EventInstance.new()
		man.setup(EventCatalogue.out_of_the_car(10, false), Vector2(0.0, -60.0))
		van.let_out(man)
		men.append(man)
	var elapsed := 0.0
	var past := hot.telegraph_time + hot.duration + 2.0
	while elapsed < past:
		van.player_at = Vector2(2000.0, 0.0)
		van._process(STEP)
		elapsed += STEP
	t.check(not van.is_finished and not van.is_leaving,
			"%.0fs after its notice, past its own %.0fs, it still stands with its men out"
			% [elapsed, hot.telegraph_time + hot.duration])
	men[0]._finish()
	van._process(STEP)
	t.check(not van.is_finished and not van.is_leaving, "with one man still out it still stands")
	men[1]._finish()
	van._process(STEP)
	van._process(STEP)
	t.check(van.is_finished or van.is_leaving, "once both are back in, it leaves")
	for man in men:
		man.free()
	van.free()

## **The van stands, two men get out, and they hunt her.** On a real city on day 10, each hunting
## van's copy at the kerb with her along the sidewalk from it: once she is within its reach along a
## clear line, two guardsmen get out at its door with no badge, and the van never moves; standing
## still she is caught by one of them, and the day ends in his name.
func _test_a_hunting_van_stops_and_lets_men_out(t) -> void:
	for id: String in ["night_raid", "abduction"]:
		var rig := _city_with_her(t, 10)
		var city: City = rig[0]
		var her: Node2D = rig[1]
		var map := city.map
		var start := map.world_to_tile(her.global_position)
		var van_tile := Vector2i(-1, -1)
		for dx: int in [5, -5, 4, -4]:
			var clear := true
			for k in range(0, absi(dx) + 1):
				clear = clear and map.tile_at(start + Vector2i(signi(dx) * k, 0)) \
						== GameEnums.TileType.SIDEWALK
			if clear:
				van_tile = start + Vector2i(dx, 0)
				break
		t.check(van_tile != Vector2i(-1, -1), "found a sidewalk along from her to stand the van on")
		if van_tile == Vector2i(-1, -1):
			_done(city, her)
			return
		var hot := EventCatalogue.heated(EventCatalogue.by_id(id), Tuning.RESISTANCE_GOAL)
		var van := city.events.spawn_extra(hot, map.tile_to_world(van_tile))
		var where := van.global_position
		var events := city.events
		var men: Array[EventInstance] = []
		var moved := 0.0
		var struck := [""]
		var on_struck := func(by: String) -> void: struck[0] = by
		EventBus.hard_fail_triggered.connect(on_struck)
		var elapsed := 0.0
		events._find_player()
		while elapsed < 30.0 and struck[0] == "":
			_tick(events)
			elapsed += STEP
			moved = maxf(moved, van.global_position.distance_to(where))
			if men.is_empty() and not van.its_officers().is_empty():
				men = van.its_officers()
				t.check(events.pending_warnings().is_empty(),
						"'%s': they get out with no off-screen badge" % id)
		EventBus.hard_fail_triggered.disconnect(on_struck)
		t.check(men.size() == 2 and men.all(func(man: EventInstance) -> bool:
				return is_instance_valid(man) and man.def.id == "guardsman_giving_chase"),
				"'%s': two guardsmen got out of the van (%d)" % [id, men.size()])
		t.check(moved < 0.01, "'%s': the van never moved (%.2fpx)" % [id, moved])
		t.check(struck[0] == "guardsman_giving_chase",
				"'%s': standing still she is caught and the day ends in his name (%s)"
				% [id, struck[0]])
		_done(city, her)

## **It notices her only along a clear line**, as every notice does: within its reach but with a
## building between them, the car drives on rather than stopping.
func _test_the_car_does_not_notice_her_through_a_building(t) -> void:
	var map := CityGenerator.generate(SEED)
	var hot := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"), Tuning.RESISTANCE_GOAL)
	var found := _a_hidden_spot(map, hot.notice_within())
	t.check(found.size() == 2, "found walkable ground in its reach behind a building")
	if found.size() != 2:
		return
	var lane: Vector2 = found[0]
	var hidden: Vector2 = found[1]
	var car := EventInstance.new()
	car.setup(hot, lane, PackedVector2Array([lane, lane + Vector2(4000.0, 0.0)]), Vector2.RIGHT,
			map)
	t.add_child(car)
	car.set_process(false)
	car.player_at = hidden
	car._process(STEP)
	t.check(car.is_waiting() and car.officers_owed() == 0,
			"with a building between them, %.0fpx off, it has not noticed her"
			% lane.distance_to(hidden))
	car.free()

## A road tile centre on an east-west lane beside a sidewalk and a walkable point within `reach` of
## it whose straight line to it crosses a building — round a block's corner: `[lane, her]` on `map`,
## or empty.
func _a_hidden_spot(map: CityMap, reach: float) -> Array:
	var tiles := ceili(reach / Tuning.TILE_SIZE)
	for y in range(tiles, map.size.y - tiles):
		for x in range(tiles, map.size.x - tiles):
			var at := Vector2i(x, y)
			if map.tile_at(at) != GameEnums.TileType.ROAD \
					or map.tile_at(at + Vector2i.UP) != GameEnums.TileType.SIDEWALK:
				continue
			var lane := map.tile_to_world(at)
			for dy in range(-tiles, 0):
				for dx in range(-tiles, tiles + 1):
					var her := map.tile_to_world(at + Vector2i(dx, dy))
					if her.distance_to(lane) > reach or not map.is_walkable(map.world_to_tile(her)):
						continue
					var blocked := false
					for i in 65:
						var point := lane.lerp(her, float(i) / 64.0)
						blocked = blocked or map.tile_at(map.world_to_tile(point)) \
								== GameEnums.TileType.BUILDING
					if blocked:
						return [lane, her]
	return []
