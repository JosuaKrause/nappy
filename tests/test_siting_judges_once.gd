extends "res://tests/events_shared_city.gd"
## A placement asks each candidate its rules once, and every try still rolls.
##
## `EventScheduler._best_of()` rolls `EventScheduler.EVENT_PLACEMENT_TRIES` candidates out of the pool it is
## offered and asks each the whole rule chain against every plan of the day. The pool a walk
## siting offers is often one tile, and the director asks it once for every crew still owed in a
## look, so without the verdict kept per candidate a look that offers one tile to a dozen crews
## runs the chain `24 * 12` times for one answer — a frame of most of a second on a phone. So:
##
## - one placement over a pool (`WalkSiting.among()`) judges each distinct candidate (its tile and
##   the path built on it) exactly once, and answers what judging every try would have answered,
##   from the same stream left in the same state, for a still row, a pacing row and a row whose
##   path is rolled;
## - one look works out what it offers once (`WalkSiting.offers_worked_out`), however many copies
##   it asks, and judges no candidate twice while its verdicts stand;
## - inside a look (`WalkSiting.begin_look()`, which the director starts on every look), copies
##   asked about against the same plans share their verdicts: four crews offered one candidate
##   judge it once, not four times, and are answered what four separate asks answer, from the same
##   stream;
## - and the shared verdicts are dropped the moment they stop being true: a crew accepted in a look,
##   then a crew standing where it was put, and the next copy is not put there once the verdicts
##   are dropped, where the kept ones put it there; and the director drops them before and after
##   asking about a plan already placed and after every plan it places or moves.
##
## **What is counted is the siting's verdict store** (`EventScheduler.Verdicts`), which the siting
## is handed where it is built: the store `_best_of()` asks for a candidate's verdict before judging
## it and gives each verdict it judges. A store that counts (`CountingVerdicts`) counts the
## judgements, and one that keeps nothing (`ForgetfulVerdicts`) is a placement that judges every try
## afresh, which is the answer a kept verdict has to agree with.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_one_judgement_per_candidate(t)
	_test_one_offer_per_look(t)
	_test_a_look_shares_its_verdicts(t)
	_test_a_dropped_verdict_is_judged_again(t)
	_test_the_director_drops_the_verdicts(t)

## A verdict store that keeps what it is given, as the siting's own does, and counts: every
## judgement, every judgement of a candidate already judged since the verdicts were last dropped,
## and every candidate asked about, in order.
class CountingVerdicts extends EventScheduler.Verdicts:
	## How many candidates were judged: verdicts given to keep.
	var judged := 0
	## How many of those judgements were of a candidate judged before, with no drop in between.
	var again := 0
	## Every candidate asked about, in order, as the key the placement asks by.
	var asked: Array = []
	var _judged_since := {}

	## Overrides EventScheduler.Verdicts.of.
	func of(key: Array) -> Array:
		asked.append(key)
		return super.of(key)

	## Overrides EventScheduler.Verdicts.keep.
	func keep(key: Array, verdict: Array) -> void:
		judged += 1
		if _judged_since.has(key):
			again += 1
		_judged_since[key] = true
		super.keep(key, verdict)

	## Overrides EventScheduler.Verdicts.forget.
	func forget() -> void:
		_judged_since.clear()
		super.forget()

## A verdict store that keeps nothing, so every try is judged afresh: what a placement answered
## before its verdicts were kept. Holds the distinct candidates the tries of the last ask built.
class ForgetfulVerdicts extends EventScheduler.Verdicts:
	var candidates := {}

	## Overrides EventScheduler.Verdicts.of.
	func of(key: Array) -> Array:
		candidates[key] = true
		return []

	## Overrides EventScheduler.Verdicts.keep.
	func keep(_key: Array, _verdict: Array) -> void:
		pass

	## Overrides EventScheduler.Verdicts.forget.
	func forget() -> void:
		candidates.clear()

func _same(a: EventScheduler.Planned, b: EventScheduler.Planned) -> bool:
	if a == null or b == null:
		return a == b
	return a.position == b.position and a.path == b.path and a.facing == b.facing \
			and a.role == b.role

## Pools of tiles of a row's ground, each placed twice from one stream (`WalkSiting.among()`, the
## placement over a pool the game asks for day 11's mast): by a siting whose store counts, and by
## one whose store keeps nothing and so judges every try afresh.
func _test_one_judgement_per_candidate(t) -> void:
	var map := _map()
	var day := 9
	var already := _planned(day)
	var tree := RouteTree.for_day(map, day)
	var no_calm: Array[Vector2i] = []
	var counting := CountingVerdicts.new()
	var kept := EventScheduler.WalkSiting.new(day, map, tree, no_calm, PackedVector2Array(),
			counting)
	var forgetful := ForgetfulVerdicts.new()
	var afresh := EventScheduler.WalkSiting.new(day, map, tree, no_calm, PackedVector2Array(),
			forgetful)
	var asked := 0
	var agreed := 0
	var judged_once := 0
	var refused := 0
	for id in ["poster_crew", "homeless_yeller", "dog_walker"]:
		var def := EventCatalogue.by_id(id).for_day(day)
		var whole := EventScheduler.open_ground_for(def, map, {})
		var picker := RandomNumberGenerator.new()
		picker.seed = hash(id)
		# Pools of one, two and a handful of tiles, which is what a walk siting offers, and one of
		# thirty: the smaller the pool, the more tries repeat a candidate.
		for size in [1, 1, 1, 2, 2, 3, 5, 8, 30]:
			var pool: Array[Vector2i] = []
			for _i in size:
				pool.append(whole[picker.randi_range(0, whole.size() - 1)])
			var stream := picker.randi()
			var kept_rng := RandomNumberGenerator.new()
			kept_rng.seed = stream
			var fresh_rng := RandomNumberGenerator.new()
			fresh_rng.seed = stream
			var before := counting.judged
			var placed := kept.among(def, kept_rng, already, pool)
			var judged := counting.judged - before
			var reference := afresh.among(def, fresh_rng, already, pool)
			asked += 1
			if _same(placed, reference) and kept_rng.state == fresh_rng.state:
				agreed += 1
			if judged <= forgetful.candidates.size():
				judged_once += 1
			if placed == null:
				refused += 1
	t.check(agreed == asked,
			"a placement answers what judging every try answers, its stream left the same (%d of %d)"
			% [agreed, asked])
	t.check(judged_once == asked,
			"a placement judges no candidate twice (%d of %d)" % [judged_once, asked])
	t.check(refused < asked, "not every placement was refused (%d of %d)" % [refused, asked])

## Several fires owed at once, each asked in every look — a one-shot never waits its turn — walked
## down the day's longest route: each look works its offer out once, whatever the number of
## copies, and judges no candidate twice while its verdicts stand.
func _test_one_offer_per_look(t) -> void:
	var map := _map()
	var day := Tuning.RUN_TAUGHT_DAY
	var consumed: Array[String] = []
	var plans := EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map, consumed)
	var fire: EventDef = null
	for plan in plans:
		if plan.def.id == "burning_building":
			fire = plan.def
	var copies := 4
	for _i in copies - 1:
		plans.append(EventScheduler.Planned.new(fire, Vector2.INF))
	var owed := 0
	for plan in plans:
		if plan.def.on_her_way != null and not plan.is_placed():
			owed += 1
	var verdicts := CountingVerdicts.new()
	var siting := SpySiting.new(day, map, RouteTree.for_day(map, day), [] as Array[Vector2i],
			PackedVector2Array(), verdicts)
	siting.plans = plans
	var director := EventDirector.new(map)
	director.start_day(day, plans, _rng(day), siting)
	var route := _longest_route(day)
	var looks := 0
	var judging := 0
	var one_offer := 0
	var within := 0
	var begun := 0
	var at := route[0]
	for i in range(1, route.size()):
		var toward := route[i] - at
		while toward.length() > Tuning.WALK_SPEED * STEP:
			var velocity := toward.normalized() * Tuning.WALK_SPEED
			at += velocity * STEP
			var judged := verdicts.judged
			var again := verdicts.again
			var offers := siting.offers_worked_out
			var from := siting.calls.size()
			director.site_what_is_on_her_way(STEP, at, velocity, plans)
			var calls := siting.calls.slice(from)
			var begins := 0
			var ends := 0
			for call: Array in calls:
				if call[0] == "begin":
					begins += 1
				elif call[0] == "end":
					ends += 1
			if begins == 0:
				toward = route[i] - at
				continue
			looks += 1
			# One look begun and ended around everything the director asked in it.
			if begins == 1 and ends == 1 and calls[0][0] == "begin" and calls[-1][0] == "end":
				begun += 1
			if siting.offers_worked_out - offers <= 1:
				one_offer += 1
			# Every copy may be asked in a look, a placed one being moved as well as an unplaced
			# one being sited, and each is offered the same tiles.
			if verdicts.again == again:
				within += 1
			if verdicts.judged > judged:
				judging += 1
			toward = route[i] - at
	t.check(owed == copies, "the day owes the fires the test added (%d)" % owed)
	t.check(looks > 0, "there were looks (%d)" % looks)
	# The band the director sites a walk's events in: its near edge is outside the streaming
	# radius with its hysteresis (nothing is created in view), and its far edge is the walking
	# `ON_HER_WAY_SIGHT` seconds beyond that.
	var band_held := not siting.bands.is_empty()
	for band in siting.bands:
		band_held = band_held \
				and is_equal_approx(band.x, Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS) \
				and is_equal_approx(band.y - band.x, Tuning.WALK_SPEED * EventDirector.ON_HER_WAY_SIGHT)
	t.check(band_held, "every ask the director made sites between the streaming edge and a walk's sight beyond it (%d asks)" % siting.bands.size())
	t.check(judging > 0, "there were looks that judged a candidate (%d)" % judging)
	t.check(one_offer == looks,
			"a look works out what it offers once, for %d copies (%d of %d looks)"
			% [copies, one_offer, looks])
	t.check(within == looks,
			"a look judges no copy's candidate twice (%d of %d looks)" % [within, looks])
	t.check(begun == looks,
			"the director shares one set of verdicts across each look and ends it (%d of %d looks)"
			% [begun, looks])

## `copies` copies of `def` asked about from `at`, each from its own copy of one stream, inside one
## look or each on its own: `[the placements, the streams' states after, how many candidates were
## judged, how many distinct candidates were asked about]`.
func _ask_copies(siting: EventScheduler.WalkSiting, verdicts: CountingVerdicts, def: EventDef,
		already: Array[EventScheduler.Planned], at: Vector2, heading: Vector2, near: float,
		far: float, copies: int, in_a_look: bool) -> Array:
	var placed: Array[EventScheduler.Planned] = []
	var states: Array[int] = []
	var judged := verdicts.judged
	var from := verdicts.asked.size()
	if in_a_look:
		siting.begin_look()
	for copy in copies:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + copy
		placed.append(siting.ahead_of(def, rng, already, at, heading, near, far))
		states.append(rng.state)
	if in_a_look:
		siting.end_look()
	var distinct := {}
	for key: Array in verdicts.asked.slice(from):
		distinct[key] = true
	return [placed, states, verdicts.judged - judged, distinct.size()]

## Four crews owed, asked about from a place where all four are offered one candidate between them
## — a band ahead of her holding one tile of the row's ground — each from its own copy of one
## stream: inside a look the candidate is judged once for all four; outside one it is judged once
## for each; and both answer the same placements, leaving the streams in the same states.
func _test_a_look_shares_its_verdicts(t) -> void:
	var map := _map()
	var day := 9
	var already := _planned(day)
	var verdicts := CountingVerdicts.new()
	var siting := EventScheduler.WalkSiting.new(day, map, RouteTree.for_day(map, day),
			[] as Array[Vector2i], PackedVector2Array(), verdicts)
	var crew := EventCatalogue.by_id("poster_crew").for_day(day)
	# A crew stands in front of a blank wall, which only a city's buildings know; every front face
	# stands in for them here.
	for tile in EventScheduler.open_ground_for(crew, map, {}, EventDef.Pavement.AT_THE_FRONT):
		siting.fronts[tile] = true
	# The band the director sites the walk's events in: from the streaming edge to the sight of a
	# walk's `ON_HER_WAY_SIGHT` seconds beyond it.
	var near := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
	var far := near + Tuning.WALK_SPEED * EventDirector.ON_HER_WAY_SIGHT
	var copies := 4
	# Down the day's longest route until the four copies, asked each on its own, ask about one
	# candidate between them, which separate asks find without sharing anything.
	var route := _longest_route(day)
	var separate := []
	var shared := []
	for i in range(1, route.size()):
		var toward := (route[i] - route[i - 1]).normalized()
		separate = _ask_copies(siting, verdicts, crew, already, route[i - 1], toward, near, far,
				copies, false)
		if int(separate[3]) == 1:
			shared = _ask_copies(siting, verdicts, crew, already, route[i - 1], toward, near,
					far, copies, true)
			break
	t.check(not shared.is_empty(), "somewhere on the route offers the copies one candidate")
	if shared.is_empty():
		return
	t.check(int(shared[2]) == 1,
			"in a look, four copies offered one candidate judge it once (%d)" % shared[2])
	t.check(int(separate[2]) == copies,
			"outside a look, each copy judges it again (%d)" % separate[2])
	var same := true
	for copy in copies:
		var a: EventScheduler.Planned = shared[0][copy]
		var b: EventScheduler.Planned = separate[0][copy]
		same = same and _same(a, b) and shared[1][copy] == separate[1][copy]
	t.check(same, "a look's shared verdicts answer what separate asks answer, streams included")

## The day's longest route, walked out from the doorstep.
func _longest_route(day: int) -> PackedVector2Array:
	var tree := RouteTree.for_day(_map(), day)
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	var siting := EventScheduler.WalkSiting.new(day, _map(), tree, [] as Array[Vector2i],
			PackedVector2Array(), EventScheduler.Verdicts.new())
	for i in best.size():
		points.append(siting.cell_centre(best[best.size() - 1 - i]))
	return points

## A crew accepted inside a look, and then a crew of the same row standing where it was put: the
## next copy, rolled from the same stream, is not put there (nothing is ever drawn inside anything
## else, `EventScheduler.EVENT_SPACING_ANY`) — but only once the look's verdicts are dropped. Kept,
## they answer from before the crew stood there and put it on the very spot, which is the placement
## no fresh judgement makes and why the director drops them.
func _test_a_dropped_verdict_is_judged_again(t) -> void:
	var map := _map()
	var day := 9
	var already := _planned(day)
	var siting := EventScheduler.WalkSiting.new(day, map, RouteTree.for_day(map, day),
			[] as Array[Vector2i], PackedVector2Array(), EventScheduler.Verdicts.new())
	var crew := EventCatalogue.by_id("poster_crew").for_day(day)
	for tile in EventScheduler.open_ground_for(crew, map, {}, EventDef.Pavement.AT_THE_FRONT):
		siting.fronts[tile] = true
	# The band the director sites the walk's events in: from the streaming edge to the sight of a
	# walk's `ON_HER_WAY_SIGHT` seconds beyond it.
	var near := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
	var far := near + Tuning.WALK_SPEED * EventDirector.ON_HER_WAY_SIGHT
	# Down the day's longest route until the band ahead of her has a crew accepted.
	var route := _longest_route(day)
	var spot := Vector2.INF
	var heading := Vector2.ZERO
	for i in range(1, route.size()):
		var toward := (route[i] - route[i - 1]).normalized()
		if siting.ahead_of(crew, _stream(), already, route[i - 1], toward, near,
				far):
			spot = route[i - 1]
			heading = toward
			break
	t.check(spot != Vector2.INF, "somewhere on the route accepts a crew")
	if spot == Vector2.INF:
		return
	var answers := {}
	var stands := {}
	for dropped in [true, false]:
		siting.begin_look()
		var first := siting.ahead_of(crew, _stream(), already, spot, heading,
				near, far)
		var standing := already.duplicate()
		standing.append(EventScheduler.Planned.new(crew, first.position))
		stands[dropped] = first.position
		if dropped:
			siting.forget_the_verdicts()
		answers[dropped] = siting.ahead_of(crew, _stream(), standing, spot,
				heading, near, far)
		siting.end_look()
	var after_the_drop: EventScheduler.Planned = answers[true]
	var kept: EventScheduler.Planned = answers[false]
	t.check(after_the_drop == null or after_the_drop.position != stands[true],
			"with the verdicts dropped, a copy is not put where a crew now stands")
	t.check(kept != null and kept.position == stands[false],
			"kept, the verdicts would have put it there (the check above is not vacuous)")

## A fresh copy of one stream, the same every time: a copy asked from it rolls what the last did.
func _stream() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000
	return rng

## Spies on what the director asks of the siting, and on when it begins a look, drops the verdicts
## and ends the look.
class SpySiting extends EventScheduler.WalkSiting:
	## One entry per call, in order: `["begin"]`, `["ask", the plan asked about was placed, it was
	## sited]`, `["forget"]` or `["end"]`.
	var calls: Array = []
	## The `Vector2(near, far)` band of every ask the director made.
	var bands: Array[Vector2] = []
	## The plans the director is handed, to tell which one an ask is about: the one `already`
	## leaves out.
	var plans: Array[EventScheduler.Planned] = []

	## Overrides EventScheduler.WalkSiting.ahead_of.
	func ahead_of(def: EventDef, rng: RandomNumberGenerator,
			already: Array[EventScheduler.Planned], at: Vector2, heading: Vector2, near: float,
			far: float) -> EventScheduler.Planned:
		var others := {}
		for plan in already:
			others[plan] = true
		var placed := false
		for plan in plans:
			if not others.has(plan):
				placed = plan.is_placed()
		bands.append(Vector2(near, far))
		var sited := super.ahead_of(def, rng, already, at, heading, near, far)
		calls.append(["ask", placed, sited != null])
		return sited

	## Overrides EventScheduler.WalkSiting.begin_look.
	func begin_look() -> void:
		calls.append(["begin"])
		super.begin_look()

	## Overrides EventScheduler.WalkSiting.forget_the_verdicts.
	func forget_the_verdicts() -> void:
		calls.append(["forget"])
		super.forget_the_verdicts()

	## Overrides EventScheduler.WalkSiting.end_look.
	func end_look() -> void:
		calls.append(["end"])
		super.end_look()

## Day 3 with four fires owed, walked out down the day's longest route and back again, so fires are
## sited ahead of her and then left behind and moved: the director drops the look's verdicts just
## before and just after asking about a plan already placed, and once more after each plan it
## places or moves.
func _test_the_director_drops_the_verdicts(t) -> void:
	var map := _map()
	var day := Tuning.RUN_TAUGHT_DAY
	var consumed: Array[String] = []
	var plans := EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map, consumed)
	var fire: EventDef = null
	for plan in plans:
		if plan.def.id == "burning_building":
			fire = plan.def
	for _i in 3:
		plans.append(EventScheduler.Planned.new(fire, Vector2.INF))
	var siting := SpySiting.new(day, map, RouteTree.for_day(map, day), [] as Array[Vector2i],
			PackedVector2Array(), EventScheduler.Verdicts.new())
	siting.plans = plans
	var director := EventDirector.new(map)
	director.start_day(day, plans, _rng(day), siting)
	var out := _longest_route(day)
	var there_and_back := PackedVector2Array(out)
	for i in range(out.size() - 2, -1, -1):
		there_and_back.append(out[i])
	var at := there_and_back[0]
	for i in range(1, there_and_back.size()):
		var toward := there_and_back[i] - at
		while toward.length() > Tuning.WALK_SPEED * STEP:
			var velocity := toward.normalized() * Tuning.WALK_SPEED
			at += velocity * STEP
			director.site_what_is_on_her_way(STEP, at, velocity, plans)
			toward = there_and_back[i] - at
	var calls := siting.calls
	var placed_asks := 0
	var first_sitings := 0
	var bracketed := 0
	var dropped_after := 0
	for i in calls.size():
		if calls[i][0] != "ask":
			continue
		var placed: bool = calls[i][1]
		var sited: bool = calls[i][2]
		var forgets := 0
		var j := i + 1
		while j < calls.size() and calls[j][0] == "forget":
			forgets += 1
			j += 1
		# The last of them is the next ask's own when that ask is about a placed plan.
		if j < calls.size() and calls[j][0] == "ask" and calls[j][1]:
			forgets -= 1
		# Once for the placed plan's own body, once more for a plan placed or moved.
		var owed := (1 if placed else 0) + (1 if sited else 0)
		if placed:
			placed_asks += 1
			if i > 0 and calls[i - 1][0] == "forget" and forgets == owed:
				bracketed += 1
		elif sited:
			first_sitings += 1
			if forgets == owed:
				dropped_after += 1
	t.check(placed_asks > 0, "fires left behind her were asked about again (%d)" % placed_asks)
	t.check(first_sitings > 0, "fires were sited for the first time (%d)" % first_sitings)
	t.check(bracketed == placed_asks,
			"the verdicts are dropped just before and after asking about a placed plan (%d of %d)"
			% [bracketed, placed_asks])
	t.check(dropped_after == first_sitings,
			"the verdicts are dropped after each plan the look places (%d of %d)"
			% [dropped_after, first_sitings])
