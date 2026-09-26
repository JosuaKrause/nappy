extends "res://tests/events_shared_city.gd"
## What a street actually costs her: running is the answer to exactly the one kind of thing that
## follows her and nothing else, nothing is cheaper to walk through than around it, the pavement
## can be blocked from day one, a day has enough in it to meet, danger arrives on schedule, the
## caps can spend the budget, the named decisions arrive, two of a kind are not the same incident,
## nothing happens inside a lethal field, a pursuer keeps no field clear, and the city remembers
## where she has already walked.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again"; further split out
## of a combined `test_events_scheduler.gd` once that file measured close to the two-minute budget
## on its own -- `test_events_scheduler.gd` keeps the scheduler's determinism and safety rules,
## which share nothing but the inherited `_map()`/`_planned()` with this half.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_running_is_the_answer_to_exactly_one_kind_of_thing(t)
	_test_the_cyclist_costs_what_he_did(t)
	_test_nothing_chases_her_before_the_run_is_taught(t)
	_test_nothing_is_cheaper_to_walk_through_than_around(t)
	_test_the_pavement_can_be_blocked_from_day_one(t)
	_test_a_day_has_enough_in_it_to_meet(t)
	_test_danger_arrives_before_act_three(t)
	_test_the_caps_can_spend_the_budget(t)
	_test_the_named_decisions_arrive(t)
	_test_two_of_a_kind_are_not_the_same_incident(t)
	_test_nothing_happens_inside_a_lethal_field(t)
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
	return (def.mean_emission_along_the_line() - Tuning.EXCITEMENT_DECAY_RUNNING
			+ Tuning.EXCITEMENT_FROM_RUNNING) * seconds

func _signature(planned: Array) -> String:
	var parts: Array[String] = []
	for plan in planned:
		parts.append("%s@%.1f,%.1f" % [plan.def.id, plan.position.x, plan.position.y])
	return "|".join(parts)

## The calm ground of a calm block — mirrors `EventScheduler._calm_rect`, which is the
## definition the guarantee is actually written over.
func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var layout: BlockLayout = map.block_layouts.get(block)
	if layout and BlockLayout.has(layout.open_rect):
		return layout.open_rect
	return CityMap.block_rect(block)

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

## **The cyclist's shorter warning was not asked to make him cheaper.** *(PLAYTEST-144, statement
## 16: "13 is not okay" — M207 shrank his field to shorten the warning and halved his full-pass
## cost as a side effect, 16.0 to 12.1 (`docs/DECISIONS.md`, M207).)* Pinned at the pre-M207 figure
## rather than compared against a stored "old" run, so a future change to his geometry has to keep
## clearing this line rather than quietly redefining it — `docs/COSTS.md`'s own rounding
## (one decimal place) is the tolerance.
const CYCLIST_FULL_PASS_COST := 16.0
const CYCLIST_FULL_PASS_COST_TOLERANCE := 0.1

func _test_the_cyclist_costs_what_he_did(t) -> void:
	var found := false
	for def in EventCatalogue.all():
		if def.id != "cyclist":
			continue
		found = true
		var cost := def.walk_through_cost()
		t.check(absf(cost - CYCLIST_FULL_PASS_COST) <= CYCLIST_FULL_PASS_COST_TOLERANCE,
				("cyclist: a full pass costs %.1f, not the %.1f it cost before the smaller field " +
				"made him cheaper for a shorter warning") % [cost, CYCLIST_FULL_PASS_COST])
	t.check(found, "the cyclist is still in the catalogue")

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
		t.check(def.warning_time() + 0.001 >= def.minimum_telegraph(),
				"'%s' warns for %.2fs before it can reach her against a required %.2fs"
				% [id, def.warning_time(), def.minimum_telegraph()])

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
