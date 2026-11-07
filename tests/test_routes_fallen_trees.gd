extends RefCounted
## *(2026-09-11, the player: "fallen trees should only be possible on streets with trees and one
## spot should be empty (the fallen tree's spot)".)* A fallen tree only falls where a tree stood,
## exactly one pit of that street empties, and a day with no tree-lined street to hand still closes
## its full quota from what it does have.
##
## Split from `tests/test_routes.gd` under M125, "the test suite is slow again"; split out of
## `tests/routes_closures_rig.gd` on its own because `_test_a_fallen_tree_only_falls_where_a_tree_stood`
## re-plans a seed's whole fourteen days **uncached** -- the one place in the suite where that
## happens -- which the eleven invariant tests in `tests/routes_closures_rig.gd` never pay for.

const SEEDS := 12
const BASE_SEED := 5150

var _maps: Array[CityMap] = []
var _plan_cache := {}

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 13))
	_test_a_fallen_tree_only_falls_where_a_tree_stood(t)
	_test_a_day_with_no_tree_lined_street_still_closes_its_quota(t)


func _plan(map: CityMap, day: int) -> Array[RoadClosure]:
	_repaint_for(map, day)
	var key := "%d:%d" % [map.seed_used, day]
	if not _plan_cache.has(key):
		_plan_cache[key] = _plan_uncached(map, day)
	return _plan_cache[key]

func _repaint_for(map: CityMap, day: int) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)

## The real thing, with no memory of having been asked before — what `_test_closures_are_
## deterministic` calls twice to find out whether `ClosurePlanner.plan_day` itself repeats itself,
## rather than whether a cache does.
func _plan_uncached(map: CityMap, day: int) -> Array[RoadClosure]:
	_repaint_for(map, day)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
	return ClosurePlanner.plan_day(map, DaySpec.for_day(day), rng)

## *(2026-09-11, the player: "fallen trees should only be possible on streets with trees and one
## spot should be empty (the fallen tree's spot)".)* Two claims, and the gate is the weaker of
## them: a weight would have made this test pass for eleven seeds out of twelve.
##
## Planned uncached, because the pit record lives on the map and is written by the call — a cache
## hit would leave the map holding some other day's answer and the assertions below would be about
## nothing.
##
## **Four maps, and that uncached re-plan is exactly why.** Every other sweep of every day of every
## seed in this file is answered out of `_plan`'s cache; this one cannot be, so it is the only
## place where a seed costs a full fourteen days of real planning a second time. Four is enough for
## the guard at the bottom — some day across the sweep has to have felled a tree — many times over,
## and what the loop is actually checking is a **gate** inside `_pick_kind`, asked once per
## closure: a weight rather than a gate would have shown up on the first map that felled one.
func _test_a_fallen_tree_only_falls_where_a_tree_stood(t) -> void:
	var felled := 0
	for map: CityMap in _maps.slice(0, 4):
		var lined := StreetTrees.segment_keys_with_trees(map)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			for closure in _plan_uncached(map, day):
				if closure.kind != RoadClosure.Kind.FALLEN_TREE:
					continue
				felled += 1
				var key := closure.segment.key()
				t.check(lined.has(key),
						"seed %d day %d: a tree fell across %s, which never had one on it"
						% [map.seed_used, day, key])
				# Exactly one pit of that street is empty, and it is the one nearest the middle of
				# the street — the tree that fell is the one that is missing, and only that one.
				var centre := map.tile_rect_to_world(closure.segment.tile_rect()).get_center()
				var wanted := StreetTrees.pit_nearest(map, key, centre)
				var empty := 0
				for pit in StreetTrees.planted(map):
					if pit.segment_key == key and map.is_tree_pit_emptied(pit.tile):
						empty += 1
						t.check(wanted != null and pit.tile == wanted.tile,
								"seed %d day %d: %s's empty pit is %s, not the one nearest the wreck"
								% [map.seed_used, day, key, pit.tile])
				t.check(empty == 1,
						"seed %d day %d: %s has %d empty pits, want exactly one"
						% [map.seed_used, day, key, empty])
	t.check(felled > 0, "some day across the sweep felled a tree (%d)" % felled)

## The fork the gate could have opened: a day whose closable streets are all bare has no
## `FALLEN_TREE` to offer, and must still shut its act's quota rather than coming up short.
##
## `RoadClosure.KINDS` keeps `ROADWORKS` and `CRASH` available from day 1, so the kind roll can
## never run out. Asked of every closure the sweep's days put on a bare street, which is where
## `ClosurePlanner.plan_day()` rolls the kind with the fallen tree gated out, as well as of the days
## whose closures are all bare, because a day that happens never to reach a bare street would pass
## the second half vacuously.
func _test_a_day_with_no_tree_lined_street_still_closes_its_quota(t) -> void:
	var bare_closures := 0
	var bare_days := 0
	for map in _maps:
		var lined := StreetTrees.segment_keys_with_trees(map)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var closures := _plan(map, day)
			var any_lined := false
			for closure in closures:
				if lined.has(closure.segment.key()):
					any_lined = true
					continue
				bare_closures += 1
				t.check(closure.kind != RoadClosure.Kind.FALLEN_TREE,
						"seed %d day %d: a bare street is never closed by a fallen tree"
						% [map.seed_used, day])
				t.check(RoadClosure.KINDS.has(closure.kind),
						"seed %d day %d: a bare street still has something to have happened to it"
						% [map.seed_used, day])
			if any_lined:
				continue
			bare_days += 1
			var wanted := ClosurePlanner.closures_wanted(DaySpec.for_day(day))
			t.check(closures.size() == wanted,
					"seed %d day %d closed %d of its %d streets with no tree-lined one among them"
					% [map.seed_used, day, closures.size(), wanted])
	t.check(bare_closures > 0,
			"the sweep closed bare streets for the kind roll to be asked of (%d)" % bare_closures)
	t.check(bare_days > 0,
			"the sweep had days whose closures were all on bare streets (%d)" % bare_days)
