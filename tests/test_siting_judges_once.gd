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
##   it asks, and judges no more candidates than there are distinct ones offered to each copy.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_one_judgement_per_candidate(t)
	_test_one_offer_per_look(t)

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
	var plans := EventScheduler.build_day(day, _rng(day), map, consumed)
	var fire := EventCatalogue.by_id("burning_building")
	var copies := 4
	for _i in copies - 1:
		plans.append(EventScheduler.Planned.new(fire, Vector2.INF))
	var owed := 0
	for plan in plans:
		if plan.def.sited_on_her_way and not plan.is_placed():
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
			director.site_what_is_on_her_way(STEP, at, velocity, plans)
			if director._since_the_last_look < since and offered.size() > 0:
				looks += 1
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
