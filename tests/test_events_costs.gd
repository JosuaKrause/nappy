extends "res://tests/events_shared_city.gd"
## What a street actually costs her: running is the answer to exactly the one kind of thing that
## follows her and nothing else, nothing is cheaper to walk through than around it, the pavement
## can be blocked from day one, a day has enough in it to meet, danger arrives on schedule, the
## named decisions arrive, no two events are drawn inside each other,
## nothing happens inside a lethal field, a pursuer keeps no field clear, and the city remembers
## where she has already walked.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again"; further split out
## of a combined `test_events_scheduler.gd` once that file measured close to the two-minute budget
## on its own -- `test_events_scheduler.gd` keeps the scheduler's determinism and safety rules,
## which share nothing but the inherited `_map()`/`_planned()` with this half.

const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_running_is_the_answer_to_exactly_one_kind_of_thing(t)
	_test_the_cyclist_costs_what_he_did(t)
	_test_nothing_chases_her_before_the_run_is_taught(t)
	_test_nothing_is_cheaper_to_walk_through_than_around(t)
	_test_the_pavement_can_be_blocked_from_day_one(t)
	_test_a_day_has_enough_in_it_to_meet(t)
	_test_danger_arrives_before_act_three(t)
	_test_the_named_decisions_arrive(t)
	_test_no_two_events_are_drawn_inside_each_other(t)
	_test_a_pursuer_keeps_no_field_clear(t)
	_test_the_city_remembers_where_she_went(t)


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
## are covered by the blanket `intensity <= 0.0` exemption. `loudspeaker` and `curfew_announce`
## are masts now, with a real field like any other row's — see `docs/EVENTS.md`, "No row is
## `city_wide`".)
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
	# The mean emission along the line is what `walk_through_cost()` charges over the walking time,
	# the walking decay added back.
	var mean := def.walk_through_cost() / (def.outer_radius * 2.0 / Tuning.WALK_SPEED) \
			+ Tuning.EXCITEMENT_DECAY_WALKING
	return (mean - Baby.EXCITEMENT_DECAY_RUNNING + Baby.EXCITEMENT_FROM_RUNNING) * seconds

func _signature(planned: Array[EventPlan]) -> String:
	var parts: Array[String] = []
	for plan in planned:
		parts.append("%s@%.1f,%.1f" % [plan.def.id, plan.position.x, plan.position.y])
	return "|".join(parts)

## The calm block she would find and settle in: the one the fewest of the day's rows spoil, as
## the day itself answers it (`DayEvents.spoilers_of()`).
func _quietest_calm_block(events: DayEvents, calm: CalmAreas) -> Vector2i:
	var best := Vector2i(-1, -1)
	var fewest := 1 << 30
	for block in calm.blocks():
		var spoilers := events.spoilers_of(block).size()
		if spoilers < fewest:
			fewest = spoilers
			best = block
	return best

func _test_running_is_the_answer_to_exactly_one_kind_of_thing(t: TestRunner) -> void:
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
		if def.pursuit != null:
			pursuers += 1
			# Walking loses ground and running gains it. Everything else about a pursuit follows
			# from this one line, including why it is the only place running can be correct.
			t.check(def.chase_speed() > Tuning.WALK_SPEED,
					"'%s' catches somebody who walks away from it" % def.id)
			t.check(def.chase_speed() < Tuning.RUN_SPEED,
					"'%s' does not catch somebody who runs" % def.id)
			t.check(def.hard_fail,
					"'%s' has to be lethal, or running from it is just an expensive walk" % def.id)
			t.check((Tuning.RUN_SPEED - def.chase_speed()) * def.duration >= def.inner_radius,
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

## **A shorter warning for the cyclist may not make him cheaper to pass.** *(PLAYTEST-144, statement
## 16: "13 is not okay" — the player's answer to a smaller field that shortened his warning and cut
## his full pass from 16.0 to 12.1; `docs/DECISIONS.md`, M207.)* So his full pass,
## `EventDef.walk_through_cost()`, is pinned at 16.0 rather than compared against a stored run, and a
## change to his geometry or his warning has to keep clearing this line rather than quietly
## redefining it — `docs/COSTS.md`'s own rounding (one decimal place) is the tolerance.
const CYCLIST_FULL_PASS_COST := 16.0
const CYCLIST_FULL_PASS_COST_TOLERANCE := 0.1

func _test_the_cyclist_costs_what_he_did(t: TestRunner) -> void:
	var found := false
	for def in EventCatalogue.all():
		if def.id != "cyclist":
			continue
		found = true
		var cost := def.walk_through_cost()
		t.check(absf(cost - CYCLIST_FULL_PASS_COST) <= CYCLIST_FULL_PASS_COST_TOLERANCE,
				("cyclist: a full pass costs %.1f, pinned at %.1f so that a change to his warning " +
				"does not make him cheaper") % [cost, CYCLIST_FULL_PASS_COST])
	t.check(found, "the cyclist is still in the catalogue")

## *(Playtest 07: "on day 3 we introduce the running key (it is possible to run before but not
## required)" and "so on day 1 we only introduce arrow keys".)*
##
## The two halves of that are a gate and a promise, and both are properties of the catalogue
## rather than of any one day's rolls, so they are checked here rather than left to a playtest.
func _test_nothing_chases_her_before_the_run_is_taught(t: TestRunner) -> void:
	for day in range(1, Tuning.RUN_TAUGHT_DAY):
		for def in EventCatalogue.available_on(day):
			t.check(def.pursuit == null,
					"day %d has nothing that has to be outrun ('%s')" % [day, def.id])
	var chasers := 0
	for def in EventCatalogue.available_on(Tuning.RUN_TAUGHT_DAY):
		chasers += 1 if def.pursuit != null else 0
	t.check(chasers > 0, "and the day the run is taught has something to teach it with")

## The measured failure playtest 02 found and M19 fixes: at intensity 7 the dog walker cost
## −0.1 points to walk straight through, so the correct play was to plough into it.
func _test_nothing_is_cheaper_to_walk_through_than_around(t: TestRunner) -> void:
	for def in EventCatalogue.all():
		if def.intensity <= 0.0 or def.id in _SCENERY:
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
func _test_the_pavement_can_be_blocked_from_day_one(t: TestRunner) -> void:
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
## Checked against what a day actually *places*, the bags' draws with their empty marbles and the
## caps, not against any one number, since a share the catalogue cannot fill is not density.
func _test_a_day_has_enough_in_it_to_meet(t: TestRunner) -> void:
	var blocks := Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y
	for day: int in [1, 3, 7, 14]:
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
	var early := 0
	var late := 0
	for plan in _planned(1):
		if plan.def.kind != GameEnums.EventKind.AMBIENT and plan.is_placed():
			early += 1
	for plan in _planned(14):
		if plan.def.kind != GameEnums.EventKind.AMBIENT and plan.is_placed():
			late += 1
	# A fifth more, not half again: what day 14 places is under half again what day 1 places, before
	# the bags as after (`tests/probes/placement_view_mix.gd`), so a bar of half again on what is
	# placed holds no day. A fifth keeps it a check on the ramp and not only on its direction.
	t.check(late * 5 > early * 6,
			"and a late day is markedly denser than an early one, a fifth more and over (%d placed on day 14, %d on day 1)"
			% [late, early])

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
func _test_danger_arrives_before_act_three(t: TestRunner) -> void:
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
		t.check(def.warning_time() + 0.001 >= def.minimum_telegraph(),
				"'%s' warns for %.2fs before it can reach her against a required %.2fs"
				% [id, def.warning_time(), def.minimum_telegraph()])

## The two events playtest 05 named, and the reason it named them: the dog-walker decision
## has to arrive more than once, and the café that exists to force a crossing has to be
## findable at all. Both are counted over the whole map, since what she meets on a route is
## a fraction of it.
##
## Stated as a **per-seed floor**, since the density is a fixed number of events: every row added
## to the day-1 pool takes a share of it, and a single total across a few seeds is a tight enough
## sample to fail on noise. Their weights went up to compensate — dog walkers and café frontages
## are what an ordinary street is mostly made of.
func _test_the_named_decisions_arrive(t: TestRunner) -> void:
	var map := _map()
	for city_seed: int in [4242, 77, 1301]:
		var seeded := CityGenerator.generate(city_seed)
		var consumed: Array[String] = []
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:1" % city_seed)
		var counts := {}
		for plan in GameDawn.of(DaySpec.for_day(1), rng, seeded).spent(consumed).plan().placements():
			counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
		# No day-1 map may be without either of them at all, which is the failure the player
		# actually reported: *"a restaurant — I never saw one."*
		t.check(int(counts.get("dog_walker", 0)) >= 4,
				"seed %d: day 1 carries %s dog walkers"
				% [city_seed, counts.get("dog_walker", 0)])
		t.check(int(counts.get("cafe_tables", 0)) >= 2,
				"seed %d: day 1 carries %s cafés" % [city_seed, counts.get("cafe_tables", 0)])
	t.check(map.calm_blocks.size() > 0, "and the map still has calm ground on it")

## **No two events are drawn inside each other**: every two placed events of a day stand at
## least `EventScheduler.EVENT_SPACING_ANY` apart, the one spacing no placement bends. Two of a
## kind may stand closer than `EVENT_SPACING_SAME` where two touching units each drew one; that a
## unit draws one of a row is `tests/test_events_scheduler.gd`'s.
func _test_no_two_events_are_drawn_inside_each_other(t: TestRunner) -> void:
	var pairs := 0
	for day: int in [1, 8, 14]:
		var planned := _planned(day)
		for i in planned.size():
			for j in range(i + 1, planned.size()):
				var a: EventPlan = planned[i]
				var b: EventPlan = planned[j]
				if not a.is_placed() or not b.is_placed():
					continue
				if a.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				if b.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				var gap := a.position.distance_to(b.position)
				pairs += 1
				t.check(gap >= EventScheduler.EVENT_SPACING_ANY - 0.5,
						"day %d: '%s' and '%s' are not drawn inside each other (%.0fpx)"
						% [day, a.def.id, b.def.id, gap])
	t.check(pairs > 0, "there were placed pairs to measure (%d)" % pairs)

## **The third case of the clearance rule, pinned over `EventDef.pursuit` rather than over
## either row that carries it today.** A lethal field that follows her is neither on the
## corridor nor off it, so placement cannot keep it clear of anything — `charging_dog` never
## reaches `StreetInvalidation.room_around()` at all on `Tuning.RUN_TAUGHT_DAY`, when it is still `AHEAD_OF_PLAYER`
## and sited with no tile, and `alley_robbery` (and `charging_dog` again, past the teaching day,
## once `spawn_mode_on()` answers `MAP`) is exempt only because `hard_fail` always classifies a
## `MAP`-placed `RECURRING`/`SCRIPTED` row `WALL` before `EventScheduler.role_for()` ever asks whether it
## pursues. Forcing the role off `WALL` here is what tells the two reasons apart, and it is why
## a third pursuer — one a future `EventScheduler.role_for()` change routes through `SET_PIECE` or `FRICTION`
## instead — inherits the exemption without anybody adding a case for it.
func _test_a_pursuer_keeps_no_field_clear(t: TestRunner) -> void:
	var pursuer := EventCatalogue.by_id("alley_robbery")
	t.check(pursuer.hard_fail and pursuer.pursuit != null, "alley_robbery is lethal and pursues")
	var off_wall := EventPlan.new(pursuer, Vector2.ZERO)
	off_wall.role = GameEnums.BlockerRole.FRICTION
	t.check(not off_wall.keeps_its_field_clear(),
			"a lethal pursuer keeps nothing clear even when it is not classified a wall")

	# The control: an otherwise identical lethal row that does not pursue still owes the rule off
	# the `WALL` role — the exemption is `EventDef.pursuit`, not "the role happens not to be WALL".
	var stationary := EventCatalogue.by_id("reversing_lorry")
	t.check(stationary.hard_fail and stationary.pursuit == null,
			"reversing_lorry is lethal and does not pursue, the contrast this needs")
	var off_wall_stationary := EventPlan.new(stationary, Vector2.ZERO)
	off_wall_stationary.role = GameEnums.BlockerRole.FRICTION
	t.check(off_wall_stationary.keeps_its_field_clear(),
			"and a lethal row that does not pursue keeps its field clear off the WALL role too")

	# And the exemption the other way: the same row classified a wall is the one the rule lets off.
	var walled := EventPlan.new(stationary, Vector2.ZERO)
	walled.role = GameEnums.BlockerRole.WALL
	t.check(not walled.keeps_its_field_clear(),
			"while a lethal wall is the exemption the rule makes, and keeps nothing clear")

## Playtest 05, finding 4: *"I was able to go to the same park on day one and two — this
## shouldn't be possible."* The complaint is not about repetition, it is that the game's only
## verb stopped being a decision on day two.
##
## Three things are checked, and the third is the one that makes it fair rather than punishing:
## the park she used gets something in it, the day still guarantees a *different* usable one,
## and what gets put there can never take the day or the ground away.
func _test_the_city_remembers_where_she_went(t: TestRunner) -> void:
	var map := _map()
	t.check(map.calm_blocks.size() >= 2,
			"the map has calm ground to choose between (%d blocks)" % map.calm_blocks.size())

	var used: Vector2i = map.calm_blocks[0]
	var used_set: Array[Vector2i] = [used]
	var calm := CalmAreas.of(map, used_set)
	var lot := calm.ground_of(used)
	var allowed := maxf(DawnSpoilers.OBSTRUCTION_A_PARK_CAN_HOLD,
			minf(lot.size.x, lot.size.y) / 16.0)
	var spoiled_days := 0
	for day in range(2, 15):
		var consumed: Array[String] = []
		var events := GameDawn.of(DaySpec.for_day(day), _rng(day), map).calm(calm).spent(consumed) \
				.plan()
		var planned := events.placements()

		var on_her_park := 0
		var clean_elsewhere := 0
		for block in calm.blocks():
			var spoilers := events.spoilers_of(block).size()
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
		# A busker is 22px of a 704px lot. See `DawnSpoilers.OBSTRUCTION_A_PARK_CAN_HOLD`.
		#
		# And the allowance is the lot's, not a constant:
		# `DawnSpoilers._things_to_put_in_a_park()` lets a
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
	var a := GameDawn.of(DaySpec.for_day(3), _rng(3), map).spent(forgetful).plan().placements()
	var nothing: Array[Vector2i] = []
	var b := GameDawn.of(DaySpec.for_day(3), _rng(3), map).calm(CalmAreas.of(map, nothing)) \
			.spent(remembering).plan().placements()
	t.check(_signature(a) == _signature(b),
			"and a day with nothing to remember is unchanged by the rule")

	# The whole run, played the way a player plays it: settle in the quietest calm block, and
	# the next day is planned knowing that. Measured over five seeds while this was built, the
	# repeat rate goes from 28% of days to 0 — this asserts the claim rather than the number.
	# Since playtest 12 the memory is the whole **act**, not the night before, so this walks the
	# run the way `RunCalendar.settled_this_act` does: the used set grows through an act and is
	# emptied at the boundary. A day must send her somewhere she has not been this act.
	var used_this_act: Array[Vector2i] = []
	var act := 0
	for day in range(1, 15):
		if Tuning.act_for_day(day) != act:
			act = Tuning.act_for_day(day)
			used_this_act = []
		var consumed: Array[String] = []
		var calm_today := CalmAreas.of(map, used_this_act)
		var quietest := _quietest_calm_block(GameDawn.of(DaySpec.for_day(day), _rng(day), map) \
				.calm(calm_today).spent(consumed).plan(), calm_today)
		t.check(not used_this_act.has(quietest),
				"day %d sends her somewhere she has not used this act" % day)
		used_this_act.append(quietest)
