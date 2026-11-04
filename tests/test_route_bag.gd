extends RefCounted
## What she meets on her route is drawn from a marble bag, and the bag is a queue of bags.
##
## Holds what a run cannot show at a glance: that a bag put in front of another leaves the one it
## interrupted exactly as it was, that rigging a bag makes and loses no marble but the ensured one
## (inbox #561 in coral-bunny: "you will be left with two initialized bags: 1 with x elements and one with n-x+1
## elements"), that an inner bag of n marbles gives n events and is gone, that a stretch of her
## route the length of a bag has the rows' own mix, that day 3's lesson is still first and paid for
## by nothing in the bag, and that after day 6's and day 11's marks the task's row is one of the next
## events placed on her route, ahead of her, where she can reach it, and in the world once she walks
## on.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
## The run's seed under the mark tests: which ground a route marble finds depends on it, and these
## checks hold on seed 2.
const RUN_SEED := 2
const STEP := 0.1
## How many times a route mast is sited again from where she was, each by a stream of its own.
const MAST_SITINGS := 40

func run(t) -> void:
	t.gives_back_observers()
	_test_a_bag_in_front_leaves_the_one_it_interrupted_as_it_was(t)
	_test_a_rig_makes_and_loses_no_marble_but_the_ensured_one(t)
	_test_a_rig_bigger_than_the_ordinary_set_gets_its_size(t)
	_test_a_marble_peeked_at_is_the_marble_drawn(t)
	_test_a_spaced_rig_comes_after_its_bag_and_no_sooner(t)
	_test_an_inner_bag_of_n_gives_n_events_and_is_gone(t)
	_test_a_rig_over_a_bag_marble_keeps_its_ensured_marble_within_x(t)
	_test_day_3s_lesson_is_first_and_a_bag_of_its_own(t)
	_test_a_stretch_of_her_route_the_length_of_a_bag_has_its_mix(t)
	_test_after_the_mark_the_task_row_is_put_on_her_route(t)
	_test_a_place_that_cannot_be_sited_holds_nothing_up(t)

# --------------------------------------------------------------- the queue ---

## A special bag put in front is drawn whole first, and the bag it interrupted then hands out exactly
## the marbles it had left — together with what it had already handed out, its whole set once.
func _test_a_bag_in_front_leaves_the_one_it_interrupted_as_it_was(t) -> void:
	var ordinary := ["a", "a", "b", "b", "b"]
	var bag := MarbleBag.new([], ordinary, 7)
	var first: Array = [bag.draw(), bag.draw()]
	bag.put_in_front(["x", "y"])
	t.check(bag.sizes() == [2, 3], "the special bag is in front of the three marbles left (%s)"
			% [bag.sizes()])
	var special: Array = [bag.draw(), bag.draw()]
	special.sort()
	t.check(special == ["x", "y"], "the special bag is drawn whole first (%s)" % [special])
	var rest: Array = first + [bag.draw(), bag.draw(), bag.draw()]
	rest.sort()
	t.check(rest == ordinary, "and the interrupted bag carries on with what it had left (%s)" % [rest])
	t.check(bag.left() == 0 and bag.sizes().is_empty(), "every bag is empty after its last marble")
	t.check(ordinary.has(bag.draw()), "and an empty queue is filled with the ordinary set again")

## Rigging takes `x - 1` marbles out of the bag being drawn from and puts them, with the ensured one,
## in front: the two bags left are `x` and `n - x + 1` marbles, and between them they hold the
## marbles the active bag held plus the ensured one, nothing made and nothing lost. Asked of a bag
## part drawn and of one not yet filled, over several seeds, so where the rig's marbles come from
## is drawn rather than fixed.
func _test_a_rig_makes_and_loses_no_marble_but_the_ensured_one(t) -> void:
	var ordinary := MarbleBag.in_proportion({"cat": 2.5, "cyclist": 1.5, "dog": 3.0}, 2.0)
	var x := ResistanceSteps.TASK_CONTACT_WITHIN_THE_NEXT
	for seed_value: int in [1, 2, 3, 4, 5]:
		for drawn_first: int in [0, 3]:
			var bag := MarbleBag.new([], ordinary, seed_value)
			bag.skip(drawn_first)
			var n := ordinary.size() - drawn_first
			var before := bag.bag_in_front() if drawn_first > 0 else ordinary.duplicate()
			bag.rig(["yeller"], x)
			t.check(bag.sizes() == [x, n - x + 1],
					"seed %d, %d drawn: the rig leaves a bag of %d and one of %d (%s)"
					% [seed_value, drawn_first, x, n - x + 1, bag.sizes()])
			var after: Array = []
			for _i in n + 1:
				after.append(bag.draw())
			var expected: Array = before + ["yeller"]
			expected.sort()
			var rigged := after.slice(0, x)
			after.sort()
			t.check(after == expected, ("seed %d, %d drawn: the two bags hold the active bag's " +
					"marbles and the ensured one, no more and no fewer") % [seed_value, drawn_first])
			t.check(rigged.has("yeller"), "seed %d, %d drawn: the ensured marble is in the first %d"
					% [seed_value, drawn_first, x])

## A rig bigger than the ordinary set still gets its size: an empty queue is filled with the ordinary
## set, and one more ordinary bag is filled at the back when that runs out (`MarbleBag._take()`), the
## same one more a queue that was not empty gets. Asked of an ordinary set of two, so a rig of four
## needs three marbles taken: two from the first fill and one from the second.
func _test_a_rig_bigger_than_the_ordinary_set_gets_its_size(t) -> void:
	var ordinary := ["a", "b"]
	for seed_value: int in [1, 2, 3]:
		var empty := MarbleBag.new([], ordinary, seed_value)
		empty.rig(["x"], 4)
		t.check(empty.sizes() == [4, 1],
				"seed %d: a rig of 4 over an empty queue fills it twice and is a bag of 4 (%s)"
				% [seed_value, empty.sizes()])
		var part_drawn := MarbleBag.new([], ordinary, seed_value)
		part_drawn.draw()
		part_drawn.rig(["x"], 4)
		t.check(part_drawn.sizes() == [4],
				"seed %d: a rig of 4 over one marble left fills one more bag and is a bag of 4 (%s)"
				% [seed_value, part_drawn.sizes()])
		var too_big := MarbleBag.new([], ordinary, seed_value)
		too_big.rig(["x"], 7)
		t.check(too_big.sizes() == [5],
				"seed %d: and no more than the two fills an empty queue has are taken (%s)"
				% [seed_value, too_big.sizes()])

## Asking which marble comes next does not change it: a bag peeked at before every draw draws what
## the same bag drawn straight would, and a bag put in front after a peek leaves the peeked marble in
## the bag it was in.
func _test_a_marble_peeked_at_is_the_marble_drawn(t) -> void:
	var ordinary := MarbleBag.in_proportion({"a": 1.0, "b": 2.0, "c": 3.0}, 2.0)
	var straight := MarbleBag.new([], ordinary, 99)
	var peeked := MarbleBag.new([], ordinary, 99)
	var same := true
	for _i in ordinary.size() * 3:
		var looked: Variant = peeked.peek()
		var drawn: Variant = peeked.draw()
		same = same and looked == drawn and straight.draw() == drawn
	t.check(same, "a peek names the marble the draw takes, and the draws are the straight bag's")
	var interrupted := MarbleBag.new([], ordinary, 5)
	interrupted.peek()
	interrupted.put_in_front(["z"])
	t.check(interrupted.sizes() == [1, ordinary.size()],
			"a bag put in front after a peek leaves the peeked marble where it was (%s)"
			% [interrupted.sizes()])

## The two-bag shape: a bag of `before` marbles taken out of the active bag, none of them the
## ensured one, then the ensured one, then what is left — so the ensured marble is drawn exactly
## after `before` others, and the bags between them still hold the active bag's marbles and it.
func _test_a_spaced_rig_comes_after_its_bag_and_no_sooner(t) -> void:
	var ordinary := MarbleBag.in_proportion({"cat": 2.5, "cyclist": 1.5, "dog": 1.4}, 2.0)
	var before := 5
	for seed_value: int in [11, 12, 13, 14, 15]:
		var bag := MarbleBag.new([], ordinary, seed_value)
		bag.take("dog")
		bag.rig_spaced(["dog"], before)
		var n := ordinary.size()
		t.check(bag.sizes() == [before, 1, n - 1 - before], "seed %d: bags of %d, 1 and %d (%s)"
				% [seed_value, before, n - 1 - before, bag.sizes()])
		var drawn: Array = []
		for _i in n:
			drawn.append(bag.draw())
		t.check(not drawn.slice(0, before).has("dog") and drawn[before] == "dog",
				"seed %d: the dog is drawn sixth and not before (%s)" % [seed_value, drawn])
		var sorted := drawn.duplicate()
		sorted.sort()
		var expected := ordinary.duplicate()
		expected.sort()
		t.check(sorted == expected, ("seed %d: with the dog's own marble taken out, the bags " +
				"between them hold the ordinary set exactly") % seed_value)

## A marble that is itself a bag *(inbox #561 in coral-bunny; asked whether a drawn bag marble goes back at once or
## with the next outer fill: "The inner bag becomes empty after n draws")*: drawing it draws from
## it and it goes straight back into the outer bag, and an inner bag of n marbles gives exactly n
## events and is then never drawn again — not by this outer bag and not by any later fill. A bag
## marble left last in its bag drains its inner bag and stops. Peeking names what a draw gives.
func _test_an_inner_bag_of_n_gives_n_events_and_is_gone(t) -> void:
	var others := ["cat", "cat", "dog", "dog", "dog"]
	var inner_marbles := ["robber", "van", "van"]
	var peeked_right := true
	for seed_value: int in [3, 4, 5, 6, 7]:
		var inner := MarbleBag.new([], inner_marbles, seed_value)
		var outer := MarbleBag.new([], others + [inner], seed_value + 100)
		var first: Array = []
		for _i in others.size() + inner_marbles.size():
			var looked: Variant = outer.peek()
			var marble: Variant = outer.draw()
			peeked_right = peeked_right and looked == marble
			first.append(marble)
		first.sort()
		var expected: Array = others + inner_marbles
		expected.sort()
		t.check(first == expected, ("seed %d: back in at once, the first outer bag gives its %d " +
				"marbles and all %d of the inner bag's (%s)")
				% [seed_value, others.size(), inner_marbles.size(), first])
		var later: Array = []
		for _i in others.size() * 3:
			later.append(outer.draw())
		var from_inner := 0
		for marble: Variant in later:
			if inner_marbles.has(marble):
				from_inner += 1
		t.check(from_inner == 0 and later.size() == others.size() * 3,
				"seed %d: and once its inner bag is empty the bag marble is never drawn again (%s)"
				% [seed_value, later])
	t.check(peeked_right, "a peek at a bag marble names what its draw gives")

	var last_inner := MarbleBag.new(inner_marbles, [], 8)
	var last := MarbleBag.new([last_inner], ["cat"], 9)
	var drained: Array = []
	for _i in inner_marbles.size():
		drained.append(last.draw())
	drained.sort()
	t.check(drained == inner_marbles and last.draw() == "cat" and last.draw() == "cat",
			"a bag marble left last in its bag drains its %d marbles and stops (%s)"
			% [inner_marbles.size(), drained])

## A rig fills its x−1 by *drawing* from the active bag (inbox #561 in coral-bunny: "fill the
## remaining x-1 items by *drawing* from the currently active bag. x defines how soon we want to get
## the guaranteed event"), so a bag marble it reaches gives a draw from its inner bag and stays where
## it is. The rigged bag then holds only plain marbles and the ensured one comes within x draws,
## every time, and the inner bag still gives exactly its n marbles.
func _test_a_rig_over_a_bag_marble_keeps_its_ensured_marble_within_x(t) -> void:
	var x := 2
	var late := 0
	var reached_the_bag_marble := 0
	var a_bag_in_the_rig := 0
	var inner_count_wrong := 0
	for seed_value in 1000:
		var inner := MarbleBag.new([], ["robber", "van", "van"], seed_value * 7 + 1)
		var outer := MarbleBag.new([], ["cat", "cat", "dog", inner], seed_value)
		outer.rig(["yeller"], x)
		var rigged := outer.bag_in_front()
		for marble: Variant in rigged:
			if marble is MarbleBag:
				a_bag_in_the_rig += 1
			if marble in ["robber", "van"]:
				reached_the_bag_marble += 1
		var drawn: Array = []
		for _i in x:
			drawn.append(outer.draw())
		if not drawn.has("yeller"):
			late += 1
		for _i in 6:
			drawn.append(outer.draw())
		var from_inner := 0
		for marble: Variant in drawn:
			if marble in ["robber", "van"]:
				from_inner += 1
		if from_inner != 3:
			inner_count_wrong += 1
	t.check(reached_the_bag_marble > 0, "the rig's fill reached the bag marble on %d of 1000 seeds"
			% reached_the_bag_marble)
	t.check(a_bag_in_the_rig == 0 and late == 0,
			"a rig of %d over a bag holding a bag marble holds no bag marble (%d) and gives its ensured marble within %d draws (late %d of 1000)"
			% [x, a_bag_in_the_rig, x, late])
	t.check(inner_count_wrong == 0,
			"and the inner bag still gives exactly its 3 marbles, rig and all (wrong on %d of 1000)"
			% inner_count_wrong)

# ------------------------------------------------------------- her route ---

## Over the first bag's length of what the director hands out, every row is met exactly as often as
## the bag holds it — `EventDirector.ROUTE_BAG_MARBLES_PER_WEIGHT` marbles per unit of weight — whatever
## order they come in. A roll at the same weights misses that on most days (the probe
## `tests/probes/olive_badger_route_mix.gd` measures how far), so three seeds holding it is the bag.
func _test_a_stretch_of_her_route_the_length_of_a_bag_has_its_mix(t) -> void:
	var day := 5
	for seed_value: int in [4242, 90210, 1234567]:
		var map := CityGenerator.generate(seed_value)
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var plan_rng := RandomNumberGenerator.new()
		plan_rng.seed = hash("route-bag:%d" % seed_value)
		var plans := EventScheduler.build_day(DaySpec.for_day(day), plan_rng, map, [], [], [], tree, 0)
		var director := EventDirector.new(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("route-bag:ahead:%d" % seed_value)
		director.start_day(day, plans, rng)
		var weights := {}
		for row in EventDirector.route_rows_on(day, 0):
			weights[row.id] = row.weight
		var expected := {}
		for marble: String in MarbleBag.in_proportion(weights, EventDirector.ROUTE_BAG_MARBLES_PER_WEIGHT,
				EventDirector.ROUTE_BAG_MARBLES_OF):
			expected[marble] = int(expected.get(marble, 0)) + 1
		var length := 0
		for id: String in expected:
			length += int(expected[id])
		t.check(expected.size() >= 2 and director.owed() >= length,
				"seed %d: the bag holds %d rows and the day owes a bag's worth (%d of %d)"
				% [seed_value, expected.size(), director.owed(), length])
		var met := {}
		var counted := 0
		var at := CrowdLanes.arterial_pavement(map)
		at.y = map.world_size().y * 0.5
		var velocity := Vector2(0.0, -Tuning.WALK_SPEED)
		var y_max: float = map.world_size().y
		var walked := 0.0
		while counted < length and walked < 2000.0:
			var due := director.due(STEP, at, velocity)
			if not due.is_empty():
				var id := (due[0] as EventDef).id
				# A row owed as itself — a sprinkled dog — is not one of the bag's marbles.
				if expected.has(id):
					met[id] = int(met.get(id, 0)) + 1
					counted += 1
			at += velocity * STEP
			if at.y < 0.0 or at.y > y_max:
				velocity.y = -velocity.y
				at.y = clampf(at.y, 0.0, y_max)
			walked += STEP
		t.check(met == expected, "seed %d: the first %d she meets are the bag's own mix (%s, bag %s)"
				% [seed_value, length, met, expected])

## Day 3's lesson through the director: on a real day's plan the dog is the first thing she meets,
## at `LESSON_DELAY`, out of a rigged bag of one in front of the route's bag, and the ordinary bag
## after it still holds every dog marble it was filled with. *(inbox #561 in coral-bunny: "keep it first" · inbox
## #566 in feathery-stork: "but the first dog is a rigged bag with only one entry that is separate from anything that
## comes after" · "the lesson is not paid for".)*
func _test_day_3s_lesson_is_first_and_a_bag_of_its_own(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	for seed_value: int in [4242, 90210]:
		var map := CityGenerator.generate(seed_value)
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var plan_rng := RandomNumberGenerator.new()
		plan_rng.seed = hash("route-bag:lesson:%d" % seed_value)
		var plans := EventScheduler.build_day(DaySpec.for_day(day), plan_rng, map, [], [], [], tree, 0)
		var director := EventDirector.new(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("route-bag:lesson:ahead:%d" % seed_value)
		director.start_day(day, plans, rng)
		var bag := director.route_bag()
		t.check(bag.sizes() == [1] and bag.bag_in_front() == ["charging_dog"],
				"seed %d: the lesson is a bag of one dog in front of the route's bag (%s, %s)"
				% [seed_value, bag.sizes(), bag.bag_in_front()])
		var first := ""
		var first_at := 0.0
		var at := CrowdLanes.arterial_pavement(map)
		at.y = map.world_size().y * 0.5
		var velocity := Vector2(0.0, -Tuning.WALK_SPEED)
		var walked := 0.0
		while first == "" and walked < 60.0:
			var due := director.due(STEP, at, velocity)
			at += velocity * STEP
			walked += STEP
			if not due.is_empty():
				first = (due[0] as EventDef).id
				first_at = walked
		t.check(first == "charging_dog_tutorial",
				"seed %d: the first thing she meets is the lesson's dog, its own row (%s)"
				% [seed_value, first])
		t.close_to(first_at, EventDirector.LESSON_DELAY,
				"seed %d: and she meets it at LESSON_DELAY of walking" % seed_value, STEP * 1.5)
		# The next marble fills the ordinary bag: the lesson took none of it.
		bag.peek()
		var ordinary := bag.bag_in_front()
		var dogs: int = EventDirector.ROUTE_BAG_MARBLES_OF["charging_dog"]
		t.check(ordinary.count("charging_dog") == dogs,
				"seed %d: the ordinary bag after the lesson keeps all %d of its dog marbles (%d of %d)"
				% [seed_value, dogs, ordinary.count("charging_dog"), ordinary.size()])

## Day 6's man shouting and day 11's second mast, through a real city: reading the mark rigs her
## route with a bag of the task's size holding the row once; walking the day's route, its marble is
## one of that many events handed out on it, and the place is put ahead of her past the streaming
## band on ground the route runs along, reachable from where she is, and in the world when she walks
## to it.
func _test_after_the_mark_the_task_row_is_put_on_her_route(t) -> void:
	_a_mark_puts_a_place_on_her_route(t, 6, "homeless_yeller", ResistanceSteps.TASK_CONTACT_WITHIN_THE_NEXT)
	_a_mark_puts_a_place_on_her_route(t, 11, "loudspeaker", ResistanceSteps.MAST_WITHIN_THE_NEXT)

## A siting that refuses every place, as `WalkSiting.ahead_of()` does when she is off the day's
## routes or walking home inside the streaming band of the branch's end; it counts how often it was
## asked to site a mast.
class RefusingSiting extends EventScheduler.WalkSiting:
	var asked := 0

	func ahead_of(def: EventDef, _rng: RandomNumberGenerator,
			_already: Array[EventScheduler.Planned], _at: Vector2, _heading: Vector2,
			_near: float, _far: float) -> EventScheduler.Planned:
		if def.id == "loudspeaker":
			asked += 1
		return null

## **A place marble that cannot be sited holds nothing up.** Day 11's case: the return's patrols are
## rigged, and a mast is the next marble in front of them; the siting refuses it for the whole walk.
## The mast is handed to her walk to site, unplaced, and every return patrol still comes behind it,
## while the refused siting is asked once a look (`EventDirector.ON_HER_WAY_LOOK`) rather than on
## every frame. Holding the head of the queue until it found a site, the mast would stop every event
## behind it.
func _test_a_place_that_cannot_be_sited_holds_nothing_up(t) -> void:
	var day := 11
	var map := CityGenerator.generate(SEED)
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)
	var tree := RouteTree.for_day(map, day)
	var plan_rng := RandomNumberGenerator.new()
	plan_rng.seed = hash("route-bag:refused:%d" % SEED)
	var plans := EventScheduler.build_day(DaySpec.for_day(day), plan_rng, map, [], [], [], tree, 0)
	var no_calm: Array[Vector2i] = []
	var siting := RefusingSiting.new(day, map, tree, no_calm, PackedVector2Array())
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("route-bag:refused:ahead:%d" % SEED)
	director.start_day(day, plans, rng, siting)
	director.owe_the_return(day, 0)
	var mast: Array[String] = ["loudspeaker"]
	director.rig_her_route(mast, 1, 0, siting)
	var count: int = EventDirector.RETURN_PATROLS_PER_ACT[Tuning.act_for_day(day) - 1]
	t.check(count > 0 and director.route_bag().peek() == "loudspeaker",
			"day %d owes %d return patrols, and a mast is the next marble in front of them" % [day, count])
	var at := CrowdLanes.arterial_pavement(map)
	at.y = map.world_size().y * 0.5
	var velocity := Vector2(0.0, -Tuning.WALK_SPEED)
	var y_max: float = map.world_size().y
	var met: Array[String] = []
	var walked := 0.0
	while walked < 300.0 and met.count("police_patrol") < count:
		director.site_what_is_on_her_way(STEP, at, velocity, plans)
		var due := director.due(STEP, at, velocity)
		if not due.is_empty():
			met.append((due[0] as EventDef).id)
		at += velocity * STEP
		if at.y < 0.0 or at.y > y_max:
			velocity.y = -velocity.y
			at.y = clampf(at.y, 0.0, y_max)
		walked += STEP
	t.check(director.route_bag().peek() != "loudspeaker" and siting.asked > 0,
			"the mast was handed to her walk to site (its marble is drawn and the siting was asked for it)")
	t.check(met.count("police_patrol") == count,
			"every return patrol still comes behind the mast that cannot be sited (%s)" % [met])
	var looks := int(walked / EventDirector.ON_HER_WAY_LOOK) + 1
	t.check(siting.asked > 0 and siting.asked <= looks,
			"the refused siting is asked on the look's cadence, %d times in %.0fs of walking"
			% [siting.asked, walked])

func _a_mark_puts_a_place_on_her_route(t, day: int, row: String, size: int) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("route-bag:%d:%d:closures" % [SEED, day])
	city.start_day(state, day, rng)
	var events_rng := RandomNumberGenerator.new()
	events_rng.seed = hash("route-bag:%d:%d:events" % [SEED, day])
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_day(day), events_rng, consumed)

	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < day:
			done.append(step.index)
	city.run.resistance.completed_steps = done
	city.run.resistance.failed_steps = []
	city.run.resistance.progress = 0
	var resistance := ResistanceDirector.new()
	var told: Array[String] = []
	resistance.trace = RunTrace.recording(told)
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city, city.map)
	var resistance_rng := RandomNumberGenerator.new()
	resistance_rng.seed = hash("route-bag:%d:%d:resistance" % [SEED, day])
	resistance.start_day(day, resistance_rng, 300.0)
	var mark := resistance.current_step()
	t.check(mark != null and mark.is_pickup and mark.day == day, "day %d opens on its mark" % day)
	if mark:
		resistance.contact().complete_now()
	# Reading the mark is one frame of play, and the rig is part of it: a mast's siting must not be
	# prepared over the whole city's ground, only over what a siting is offered. The work is counted
	# in tiles asked, never in time.
	var walk_siting := city.events.ahead.walk_siting()
	if walk_siting:
		t.check(walk_siting.mast_checks == 0,
				"day %d: the rig asks no tile whether a mast may stand there (%d)"
				% [day, walk_siting.mast_checks])
	var rigged := _the_rigged_bag(told)
	t.check(rigged.size() == size and rigged.count(row) == 1,
			"day %d: reading the mark rigs her route with a bag of %d holding one %s (%s)"
			% [day, size, row, rigged])
	resistance.free()

	var path := _the_longest_route(city)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	city.events.use_player(player)
	t.check(path.size() >= 2 and city.events.world.has_player(), "a route to walk and her on it")
	if path.size() < 2:
		player.free()
		city.free()
		return
	var index := 0
	var direction := 1
	player.global_position = path[0]
	var handed := 0
	var handed_when_sited := -1
	var placed: Array[EventScheduler.Planned] = []
	var her_at_siting := Vector2.INF
	var heading_at_siting := Vector2.ZERO
	var walked := 0.0
	while (handed < size or placed.is_empty()) and walked < 600.0:
		var next: Vector2 = path[index + direction] if index + direction >= 0 \
				and index + direction < path.size() else Vector2.INF
		if next == Vector2.INF:
			direction = -direction
			continue
		var toward := next - player.global_position
		if toward.length() < Tuning.WALK_SPEED * STEP:
			player.global_position = next
			index += direction
			continue
		player.velocity = toward.normalized() * Tuning.WALK_SPEED
		var owed_before := city.events.owed_ahead()
		var plans_before := city.events.plans().size()
		# In the order the manager's own tick runs them: what her walk sites, then what is owed.
		city.events.ahead.site_what_is_on_her_way(STEP)
		city.events.ahead.place_what_is_owed_ahead(STEP)
		if city.events.owed_ahead() < owed_before:
			handed += 1
		for plan in city.events.plans().slice(plans_before):
			if (plan as EventScheduler.Planned).def.id == row:
				placed.append(plan)
				handed_when_sited = handed
				her_at_siting = player.global_position
				heading_at_siting = player.velocity.normalized()
		player.global_position += player.velocity * STEP
		walked += STEP
	# The place waits on her walk for a site, so what the rig guarantees is the marble's place in the
	# queue; what she sees of it is the place's siting, and on this run's seed it comes within the
	# `size` events handed out since the mark.
	t.check(handed_when_sited >= 0 and handed_when_sited <= size,
			"day %d: the %s's place is sited within the next %d events on her route (%d handed)"
			% [day, row, size, handed_when_sited])
	t.check(placed.size() == 1, "day %d: and one %s is put on her route (%d)"
			% [day, row, placed.size()])
	if placed.size() == 1:
		var plan := placed[0]
		var map := city.map
		t.check(city.events.ahead.director().is_from_her_route(plan),
				"day %d: and it is a place her route's marble handed to her walk" % day)
		var tile := map.world_to_tile(plan.position)
		t.check(not city.route_tree().branches_on(tile).is_empty(),
				"day %d: it stands on ground the day's routes run along" % day)
		t.check(plan.position.distance_to(her_at_siting) >= Tuning.EVENT_STREAM_RADIUS,
				"day %d: it is put past the streaming band, so it is never seen to appear (%.0fpx)"
				% [day, plan.position.distance_to(her_at_siting)])
		var grid := ReachabilityGrid.build(map)
		var reached := grid.flood([map.world_to_tile(her_at_siting)])
		t.check(grid.reaches(tile, {}, reached), "day %d: she can walk to it from where she was" % day)
		if row == "loudspeaker":
			t.check(plan.mast_id == EventScheduler.added_mast_id(plan.position),
					"a mast put on her route is a mast the day can silence, named by its foot")
			t.check(MastSites.is_eligible(plan.position, map),
					"a mast put on her route stands where a mast site may (off the home street)")
			# And not by luck of this seed: what a route mast is offered along the branch she was
			# walking holds no tile a mast site would refuse, out of a sidewalk and square that do
			# hold some. Sited again and again from where she was, by streams of their own, every
			# site a mast is offered is a tile a mast site may be.
			var mast := city.events.ahead.director().route_row(row)
			var ground := {}
			for at: Vector2i in EventScheduler.open_ground_for(mast, map, {}, mast.pavement_side,
					city.events.ahead.holds_the_home_streets):
				ground[at] = true
			var siting := city.events.ahead.walk_siting()
			t.check(siting.mast_checks > 0 and siting.mast_checks * 10 < ground.size(),
					"siting it asked %d tiles whether a mast may stand there, of %d tiles of ground"
					% [siting.mast_checks, ground.size()])
			print("[test_route_bag] siting the route mast asked %d tiles of %d tiles of ground"
					% [siting.mast_checks, ground.size()])
			var door_points := MastSites.possible_door_points(map)
			var refused_ground := 0
			for at: Vector2i in ground:
				if not MastSites.is_eligible(map.tile_to_world(at), map, door_points):
					refused_ground += 1
			var sited := 0
			var refused_sited := 0
			for i in MAST_SITINGS:
				var siting_rng := RandomNumberGenerator.new()
				siting_rng.seed = hash("route-bag:mast-sitings:%d" % i)
				var again := siting.ahead_of(mast, siting_rng, city.events.plans(), her_at_siting,
						heading_at_siting, 0.0, INF)
				if again == null or again.position == Vector2.INF:
					continue
				sited += 1
				if not MastSites.is_eligible(again.position, map, door_points):
					refused_sited += 1
			t.check(sited > 0 and refused_sited == 0 and refused_ground > 0,
					"a route mast is sited %d times ahead of her, none of them on the %d tiles of its ground a mast site refuses (%d)"
					% [sited, refused_ground, refused_sited])
		t.check(plan.live == null, "day %d: it is not in the world while she is far from it" % day)
		city.events.stream_around(plan.position)
		t.check(plan.live != null and is_instance_valid(plan.live),
				"day %d: and it is in the world once she walks to it" % day)
	player.free()
	city.free()

## The marbles of the bag the resistance director says it rigged her route with, off its line in the
## run log ("the next N on her route are drawn from a rigged bag: a, b"); empty when it said none.
func _the_rigged_bag(told: Array[String]) -> Array:
	var marker := "drawn from a rigged bag: "
	for line in told:
		var at := line.find(marker)
		if at >= 0:
			return Array(line.substr(at + marker.length()).split(", "))
	return []

## The cell centres of the day's longest route, from the doorstep end out — the walk she takes.
func _the_longest_route(city: City) -> Array[Vector2]:
	var siting := EventScheduler.WalkSiting.new(city.events.world.day, city.map, city.route_tree(),
			[], PackedVector2Array())
	var longest: Array = []
	for branch in city.route_tree().branches:
		for route: Array in branch.routes:
			if route.size() > longest.size():
				longest = route
	var points: Array[Vector2] = []
	for i in range(longest.size() - 1, -1, -1):
		points.append(siting.cell_centre(longest[i]))
	return points
