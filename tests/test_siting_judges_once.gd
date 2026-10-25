extends "res://tests/events_shared_city.gd"
## A placement asks each candidate its rules once, and every try still rolls.
##
## `EventScheduler._best_of()` rolls `Tuning.EVENT_PLACEMENT_TRIES` candidates out of the pool it is
## offered and asks each the whole rule chain against every plan of the day. The pool a walk
## siting offers is often one tile, and the director asks it once for every crew still owed in a
## look, so without the verdict kept per candidate a look that offers one tile to a dozen crews
## runs the chain `24 * 12` times for one answer — a frame of most of a second on a phone. So:
##
## - one call of `_best_of()` judges each distinct candidate (its tile and the path built on it)
##   exactly once, and answers what judging every try would have answered, from the same stream
##   left in the same state, for a still row, a pacing row and a row whose path is rolled;
## - one look works out what it offers once (`WalkSiting.offers_worked_out`), however many copies
##   it asks, and judges no more candidates than there are distinct ones offered to each copy;
## - inside a look (`WalkSiting.begin_look()`, which the director starts on every look), copies
##   asked about against the same plans share their verdicts: four crews offered one tile judge it
##   once, not four times, and are answered what four separate asks answer, from the same stream;
## - and the shared verdicts are dropped the moment they stop being true: a crew accepted on a tile
##   in a look, then a crew standing on that tile, and the next copy is refused once the verdicts
##   are dropped, where the kept ones would accept it; and the director drops them before and after
##   asking about a plan already placed and after every plan it places or moves.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_one_judgement_per_candidate(t)
	_test_one_offer_per_look(t)
	_test_a_look_shares_its_verdicts(t)
	_test_a_dropped_verdict_is_judged_again(t)
	_test_the_director_drops_the_verdicts(t)

## What `_best_of()` answered before its verdicts were kept: every try judged afresh. Answers the
## placement and how many distinct candidates the tries built.
func _judging_every_try(def: EventDef, rng: RandomNumberGenerator, map: CityMap,
		pool: Array[Vector2i], role: GameEnums.BlockerRole, already: Array[EventScheduler.Planned],
		ground: Dictionary, corridor: Corridor) -> Array:
	var best: EventScheduler.Planned = null
	var best_room := -INF
	var seen := {}
	var no_calm: Array[Rect2] = []
	for _try in Tuning.EVENT_PLACEMENT_TRIES:
		var tile: Vector2i = pool[rng.randi_range(0, pool.size() - 1)]
		var candidate := EventScheduler._build_placement(def, map, tile, rng)
		if not candidate:
			continue
		seen[[tile, candidate.path]] = true
		var room := EventScheduler._judge(candidate, role, map, tile, already, already, ground,
				no_calm, corridor, PackedVector2Array())
		if room == INF:
			return [candidate, seen.size()]
		if room > best_room:
			best_room = room
			best = candidate
	return [best, seen.size()]

func _same(a: EventScheduler.Planned, b: EventScheduler.Planned) -> bool:
	if a == null or b == null:
		return a == b
	return a.position == b.position and a.path == b.path and a.facing == b.facing \
			and a.role == b.role

func _test_one_judgement_per_candidate(t) -> void:
	var map := _map()
	var day := 9
	var already := _planned(day)
	var corridor := Corridor.of(RouteTree.for_day(map, day))
	var no_calm: Array[Rect2] = []
	var asked := 0
	var agreed := 0
	var judged_once := 0
	var refused := 0
	for id in ["poster_crew", "homeless_yeller", "dog_walker"]:
		var def := EventScheduler._for_day(EventCatalogue.by_id(id), day)
		var role := EventScheduler._role_for(def, day)
		var ground := {}
		var whole := EventScheduler._ground_for(def, map, ground, corridor, role)
		var picker := RandomNumberGenerator.new()
		picker.seed = hash(id)
		# Pools of one, two and a handful of tiles, which is what a walk siting offers, and one of
		# thirty: the smaller the pool, the more tries repeat a candidate.
		for size in [1, 1, 1, 2, 2, 3, 5, 8, 30]:
			var pool: Array[Vector2i] = []
			for _i in size:
				pool.append(whole[picker.randi_range(0, whole.size() - 1)])
			var stream := picker.randi()
			var kept := RandomNumberGenerator.new()
			kept.seed = stream
			var fresh := RandomNumberGenerator.new()
			fresh.seed = stream
			var before := EventScheduler.judgements
			var placed := EventScheduler._best_of(def, kept, map, pool, role, already, ground,
					no_calm, corridor, PackedVector2Array())
			var judged := EventScheduler.judgements - before
			var reference := _judging_every_try(def, fresh, map, pool, role, already, ground,
					corridor)
			asked += 1
			if _same(placed, reference[0]) and kept.state == fresh.state:
				agreed += 1
			if judged <= int(reference[1]):
				judged_once += 1
			if placed == null:
				refused += 1
	t.check(asked == 27, "there were placements to ask (%d)" % asked)
	t.check(agreed == asked,
			"_best_of() answers what judging every try answers, its stream left the same (%d of %d)"
			% [agreed, asked])
	t.check(judged_once == asked,
			"_best_of() judges no candidate twice in one call (%d of %d)" % [judged_once, asked])
	t.check(refused < asked, "not every placement was refused (%d of %d)" % [refused, asked])

## Several fires owed at once, each asked in every look — a one-shot never waits its turn — walked
## down the day's longest route: each look works its offer out once, whatever the number of
## copies, and judges at most each copy's distinct candidates.
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
		if plan.def.sited_on_her_way() and not plan.is_placed():
			owed += 1
	var siting := EventScheduler.WalkSiting.new(day, map, RouteTree.for_day(map, day),
			[] as Array[Vector2i], PackedVector2Array())
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
			var judged := EventScheduler.judgements
			var band := director._siting_band()
			var offered: Array = siting._offer_ahead(fire, at, velocity.normalized(), band.x,
					band.y)[1]
			# Asking the offer here first is what the look would do; it must cost the look nothing.
			var offers := siting.offers_worked_out
			var since := director._since_the_last_look
			var looks_begun := siting.looks_begun
			director.site_what_is_on_her_way(STEP, at, velocity, plans)
			if director._since_the_last_look < since and offered.size() > 0:
				looks += 1
				if siting.looks_begun == looks_begun + 1 and siting._look_verdicts == null:
					begun += 1
				if siting.offers_worked_out == offers:
					one_offer += 1
				# Every copy may be asked in a look, a placed one being moved as well as an unplaced
				# one being sited, and each is offered the same tiles.
				var judged_now := EventScheduler.judgements - judged
				if judged_now <= owed * offered.size():
					within += 1
				if judged_now > 0:
					judging += 1
			toward = route[i] - at
	t.check(owed == copies, "the day owes the fires the test added (%d)" % owed)
	t.check(looks > 0, "there were looks with something offered (%d)" % looks)
	t.check(judging > 0, "there were looks that judged a candidate (%d)" % judging)
	t.check(one_offer == looks,
			"a look works out what it offers once, for %d copies (%d of %d looks)"
			% [copies, one_offer, looks])
	t.check(within == looks,
			"a look judges no copy's candidate twice (%d of %d looks)" % [within, looks])
	t.check(begun == looks,
			"the director shares one set of verdicts across each look and ends it (%d of %d looks)"
			% [begun, looks])

## Four crews owed, asked about in one look from a place where the band offers a single tile, each
## from its own copy of one stream: inside a look the tile is judged once for all four; outside one
## it is judged once for each; and both answer the same placements, leaving the streams in the
## same states.
func _test_a_look_shares_its_verdicts(t) -> void:
	var map := _map()
	var day := 9
	var already := _planned(day)
	var siting := EventScheduler.WalkSiting.new(day, map, RouteTree.for_day(map, day),
			[] as Array[Vector2i], PackedVector2Array())
	var crew := EventScheduler._for_day(EventCatalogue.by_id("poster_crew"), day)
	# A crew stands in front of a blank wall, which only a city's buildings know; every front face
	# stands in for them here.
	for tile in EventScheduler._open_ground_for(crew, map, {}, EventDef.Pavement.AT_THE_FRONT):
		siting.fronts[tile] = true
	var near := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
	var far := near + Tuning.WALK_SPEED * EventDirector.ON_HER_WAY_SIGHT
	# Down the day's longest route until the band ahead of her holds exactly one tile of the row's
	# ground.
	var route := _longest_route(day)
	var spot := Vector2.INF
	var heading := Vector2.ZERO
	for i in range(1, route.size()):
		var toward := (route[i] - route[i - 1]).normalized()
		var offer := siting._offer_ahead(crew, route[i - 1], toward, near, far)
		if (offer[1] as Array).size() == 1:
			spot = route[i - 1]
			heading = toward
			break
	t.check(spot != Vector2.INF, "somewhere on the route offers a single tile")
	if spot == Vector2.INF:
		return
	var copies := 4
	var answers := []
	var judged := []
	for in_a_look in [true, false]:
		var placed: Array[EventScheduler.Planned] = []
		var states: Array[int] = []
		var before := EventScheduler.judgements
		if in_a_look:
			siting.begin_look()
		for copy in copies:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1000 + copy
			placed.append(siting.ahead_of(crew, rng, already, spot, heading, near, far))
			states.append(rng.state)
		if in_a_look:
			siting.end_look()
		judged.append(EventScheduler.judgements - before)
		answers.append([placed, states])
	t.check(int(judged[0]) == 1,
			"in a look, four copies offered one tile judge it once (%d)" % judged[0])
	t.check(int(judged[1]) == copies,
			"outside a look, each copy judges it again (%d)" % judged[1])
	var same := true
	for copy in copies:
		var a: EventScheduler.Planned = answers[0][0][copy]
		var b: EventScheduler.Planned = answers[1][0][copy]
		same = same and _same(a, b) and answers[0][1][copy] == answers[1][1][copy]
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
	for i in best.size():
		points.append(EventScheduler.WalkSiting._cell_centre(_map(), best[best.size() - 1 - i]))
	return points

## A crew accepted on a one-tile offer inside a look, and then a crew of the same row standing on
## that very tile: the next copy is refused (nothing is ever drawn inside anything else,
## `Tuning.EVENT_SPACING_ANY`) — but only once the look's verdicts are dropped. Kept, they answer
## from before the crew stood there and accept it, which is the placement no fresh judgement makes
## and why the director drops them.
func _test_a_dropped_verdict_is_judged_again(t) -> void:
	var map := _map()
	var day := 9
	var already := _planned(day)
	var siting := EventScheduler.WalkSiting.new(day, map, RouteTree.for_day(map, day),
			[] as Array[Vector2i], PackedVector2Array())
	var crew := EventScheduler._for_day(EventCatalogue.by_id("poster_crew"), day)
	for tile in EventScheduler._open_ground_for(crew, map, {}, EventDef.Pavement.AT_THE_FRONT):
		siting.fronts[tile] = true
	var near := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
	var far := near + Tuning.WALK_SPEED * EventDirector.ON_HER_WAY_SIGHT
	# Down the day's longest route until the band ahead of her offers one tile that a crew is
	# accepted on.
	var route := _longest_route(day)
	var spot := Vector2.INF
	var heading := Vector2.ZERO
	for i in range(1, route.size()):
		var toward := (route[i] - route[i - 1]).normalized()
		var offer := siting._offer_ahead(crew, route[i - 1], toward, near, far)
		if (offer[1] as Array).size() != 1:
			continue
		if siting.ahead_of(crew, RandomNumberGenerator.new(), already, route[i - 1], toward, near,
				far):
			spot = route[i - 1]
			heading = toward
			break
	t.check(spot != Vector2.INF, "somewhere on the route accepts a crew on a single tile")
	if spot == Vector2.INF:
		return
	var answers := {}
	for dropped in [true, false]:
		siting.begin_look()
		var first := siting.ahead_of(crew, RandomNumberGenerator.new(), already, spot, heading,
				near, far)
		var standing := already.duplicate()
		standing.append(EventScheduler.Planned.new(crew, first.position))
		if dropped:
			siting.forget_the_verdicts()
		answers[dropped] = siting.ahead_of(crew, RandomNumberGenerator.new(), standing, spot,
				heading, near, far)
		siting.end_look()
	t.check(answers[true] == null,
			"with the verdicts dropped, a copy is refused the tile a crew now stands on")
	t.check(answers[false] != null,
			"kept, the verdicts would have accepted it (the check above is not vacuous)")

## Spies on what the director asks of the siting and when it drops the verdicts.
class SpySiting extends EventScheduler.WalkSiting:
	## One entry per call, in order: `["ask", the plan asked about was placed, it was sited]`,
	## `["forget"]` or `["end"]`.
	var calls: Array = []
	## The plans the director is handed, to tell which one an ask is about: the one `already`
	## leaves out.
	var plans: Array[EventScheduler.Planned] = []

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
		var sited := super.ahead_of(def, rng, already, at, heading, near, far)
		calls.append(["ask", placed, sited != null])
		return sited

	func forget_the_verdicts() -> void:
		calls.append(["forget"])
		super.forget_the_verdicts()

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
			PackedVector2Array())
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
