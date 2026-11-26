extends RefCounted
## What a street actually costs her, asked of the rows: running is the answer to exactly the one kind
## of thing that follows her and nothing else, nothing is cheaper to walk through than around it,
## the pavement can be blocked from day one, and a pursuer keeps no field clear. A row and a plan are
## built as they are and nothing else is: no city, no live event, no day planned.
##
## `test_events_scheduler.gd` keeps the scheduler's determinism and safety rules and
## what a planned day holds (its density, its danger, the named decisions, the city's memory).

const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_running_is_the_answer_to_exactly_one_kind_of_thing(t)
	_test_the_cyclist_costs_what_he_did(t)
	_test_nothing_chases_her_before_the_run_is_taught(t)
	_test_nothing_is_cheaper_to_walk_through_than_around(t)
	_test_the_pavement_can_be_blocked_from_day_one(t)
	_test_a_pursuer_keeps_no_field_clear(t)

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
	var seconds := def.heard_within() * 2.0 / Tuning.RUN_SPEED
	# The mean emission along the line is what `walk_through_cost()` charges over the walking time,
	# the walking decay added back.
	var mean := def.walk_through_cost() / (def.heard_within() * 2.0 / Tuning.WALK_SPEED) \
			+ Tuning.EXCITEMENT_DECAY_WALKING
	return (mean - Baby.EXCITEMENT_DECAY_RUNNING + Baby.EXCITEMENT_FROM_RUNNING) * seconds

func _test_running_is_the_answer_to_exactly_one_kind_of_thing(t: TestRunner) -> void:
	var pursuers := 0
	var running_is_cheaper := 0
	for def in CatalogueRows.every():
		if def.id() in _RUNNING_IS_CHEAPER:
			running_is_cheaper += 1
			t.check(_cost_to_run_through(def) < _cost_to_walk_through(def),
					("'%s' is named as the row running is cheaper on (%.1f running, %.1f walking) — "
					+ "if that has stopped being true, take it off the list rather than keeping it")
					% [def.id(), _cost_to_run_through(def), _cost_to_walk_through(def)])
			continue
		if def.pursues():
			pursuers += 1
			# Walking loses ground and running gains it. Everything else about a pursuit follows
			# from this one line, including why it is the only place running can be correct.
			t.check(def.chase_speed() > Tuning.WALK_SPEED,
					"'%s' catches somebody who walks away from it" % def.id())
			t.check(def.chase_speed() < Tuning.RUN_SPEED,
					"'%s' does not catch somebody who runs" % def.id())
			t.check(def.ends_the_day(),
					"'%s' has to be lethal, or running from it is just an expensive walk" % def.id())
			t.check((Tuning.RUN_SPEED - def.chase_speed()) * def.lasts_for() >= def.core_within(),
					"'%s' can be outrun by more than the radius that ends the day" % def.id())
			t.check(def.lasts_for() <= Tuning.PURSUIT_TIME,
					"'%s' gives up before the run costs more than the day it saves" % def.id())
			continue
		t.check(_cost_to_run_through(def) > _cost_to_walk_through(def),
				"running through '%s' (%.1f) costs more than walking (%.1f)"
				% [def.id(), _cost_to_run_through(def), _cost_to_walk_through(def)])
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
	for def in CatalogueRows.every():
		if def.id() != "cyclist":
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
			t.check(not def.pursues(),
					"day %d has nothing that has to be outrun ('%s')" % [day, def.id()])
	var chasers := 0
	for def in EventCatalogue.available_on(Tuning.RUN_TAUGHT_DAY):
		chasers += 1 if def.pursues() else 0
	t.check(chasers > 0, "and the day the run is taught has something to teach it with")

## The measured failure playtest 02 found and M19 fixes: at intensity 7 the dog walker cost
## −0.1 points to walk straight through, so the correct play was to plough into it.
func _test_nothing_is_cheaper_to_walk_through_than_around(t: TestRunner) -> void:
	for def in CatalogueRows.every():
		if def.peak() <= 0.0 or def.id() in _SCENERY:
			continue
		if def.id() in _PRICED_BY_THEIR_CAPTURE:
			# The exemption owes its own check, or it is a way of not being tested: a row excused
			# from costing something to walk past has to cost something to walk into.
			t.check(def.detains_her() and Tuning.CHAT_EXCITEMENT > 0.0,
					"'%s' is excused the field because the detention is what it charges (%.1f "
					% [def.id(), Tuning.CHAT_EXCITEMENT]
					+ "over %.1fs)" % def.detains_for())
			continue
		t.check(_cost_to_walk_through(def) > 0.0,
				"walking through '%s' costs more than walking around it (%.1f)"
				% [def.id(), _cost_to_walk_through(def)])
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
		if def.obstructs_within() > 0.0 and def.stands_on(GameEnums.TileType.SIDEWALK):
			blockers.append(def)
	t.check(not blockers.is_empty(),
			"something can be in the way of a pavement on day 1")
	# Sidewalk is two tiles; an obstruction wider than that would seal the pavement outright
	# rather than making it the wrong side of the street.
	for def in blockers:
		t.check(def.obstructs_within() * 2.0 < Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 2.0,
				"'%s' takes the pavement without sealing the street" % def.id())
		t.check(not def.moves(),
				"'%s' does not walk toward her: a moving wall on a two-tile pavement pins"
				% def.id())

## **The third case of the clearance rule, pinned over whether a row pursues
## (`EventDef.pursues()`) rather than over either of the two placed rows that pursue today,
## `charging_dog` and `alley_robbery`.** A lethal field that follows her is neither on the
## corridor nor off it, so placement cannot keep it clear of anything — `charging_dog` never
## reaches `StreetInvalidation.room_around()` at all on `Tuning.RUN_TAUGHT_DAY`, when it is
## still `AHEAD_OF_PLAYER` and sited with no tile, and `alley_robbery` (and `charging_dog`
## again, past the teaching day, once `spawn_mode_on()` answers `MAP`) is exempt only because
## lethal always classifies a `MAP`-placed `RECURRING`/`SCRIPTED` row `WALL` before
## `EventScheduler.role_for()` ever asks whether it pursues. Forcing the role off `WALL` here is
## what tells the two reasons apart, and it is why a third pursuer — one a future
## `EventScheduler.role_for()` change routes through `SET_PIECE` or `FRICTION` instead —
## inherits the exemption without anybody adding a case for it.
func _test_a_pursuer_keeps_no_field_clear(t: TestRunner) -> void:
	var pursuer := EventCatalogue.by_id("alley_robbery")
	t.check(pursuer.ends_the_day() and pursuer.pursues(), "alley_robbery is lethal and pursues")
	var off_wall := EventPlan.new(pursuer, Vector2.ZERO)
	off_wall.give_role(GameEnums.BlockerRole.FRICTION)
	t.check(not off_wall.keeps_its_field_clear(),
			"a lethal pursuer keeps nothing clear even when it is not classified a wall")

	# The control: an otherwise identical lethal row that does not pursue still owes the rule off
	# the `WALL` role — the exemption is that the row pursues (`EventDef.pursues()`), not "the
	# role happens not to be WALL".
	var stationary := EventCatalogue.by_id("reversing_lorry")
	t.check(stationary.ends_the_day() and not stationary.pursues(),
			"reversing_lorry is lethal and does not pursue, the contrast this needs")
	var off_wall_stationary := EventPlan.new(stationary, Vector2.ZERO)
	off_wall_stationary.give_role(GameEnums.BlockerRole.FRICTION)
	t.check(off_wall_stationary.keeps_its_field_clear(),
			"and a lethal row that does not pursue keeps its field clear off the WALL role too")

	# And the exemption the other way: the same row classified a wall is the one the rule lets off.
	var walled := EventPlan.new(stationary, Vector2.ZERO)
	walled.give_role(GameEnums.BlockerRole.WALL)
	t.check(not walled.keeps_its_field_clear(),
			"while a lethal wall is the exemption the rule makes, and keeps nothing clear")

