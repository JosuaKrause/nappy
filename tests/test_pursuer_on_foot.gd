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

# ------------------------------------------------------------------ the rig ---

## A real city on `SEED`'s map in the tree, its events told it is `day`, and a stand-in for her at
## a sidewalk beside a building, returned as `[city, her]`.
func _city_with_her(t, day: int) -> Array:
	var map := CityGenerator.generate(SEED)
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
		t.check(def.warned_first and def.arrives_chasing and def.telegraph_time == 0.0,
				"'%s' is warned of before it exists and arrives chasing, with no closing in" % id)
		t.check(is_equal_approx(def.offscreen_notice, robber.offscreen_notice)
				and def.offscreen_notice <= Tuning.WARNING_ALONE_MAX,
				"'%s' has the robber's %.1fs badge" % [id, robber.offscreen_notice])
		t.check(is_equal_approx(def.duration, Tuning.PURSUIT_TIME),
				"'%s' chases for the %.0fs cap" % [id, Tuning.PURSUIT_TIME])
		t.check(def.pursues and is_equal_approx(def.pursue_speed, robber.pursue_speed)
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
	city.events._walking_the_finale = true
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
		var line: String = DayController._HARD_FAIL_TEXT.get(id, "")
		t.check(line != "", "'%s' has its own loss line" % id)
