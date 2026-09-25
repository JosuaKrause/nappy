extends RefCounted
## The lattice itself, checked by construction before anything closes it: 7x7 blocks is 8x8
## junctions, 56 streets each way; a calm zone takes its own streets out of the lattice; every tile
## knows which street it is on; and, before any day plans a single closure, the open city can
## already reach everywhere calm, no access segment is ever absent, no single street cuts off all
## the calm, and a doorway is never counted as a route.
##
## Split from `tests/test_routes.gd` under M125, "the test suite is slow again" -- this half is the
## lattice's own shape, checked over the twelve generated seeds without ever asking
## `ClosurePlanner` to plan a day.

## Enough seeds to catch a layout that only goes wrong in one arrangement. See
## `test_routes_closures.gd`'s own docstring for why twelve, and why it does not shrink.
const SEEDS := 12
const BASE_SEED := 5150

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 13))
	_test_the_lattice_is_the_lattice(t)
	_test_a_calm_zone_takes_its_streets_out_of_the_lattice(t)
	_test_a_tile_knows_which_street_it_is_on(t)
	_test_an_open_city_can_reach_everywhere_calm(t)
	_test_access_segments_are_never_absent(t)
	_test_no_single_street_cuts_off_all_the_calm(t)
	_test_a_doorway_is_not_a_route(t)


## 7x7 blocks is 8x8 junctions, 56 streets each way. If this is ever wrong every number
## below it is wrong too, so it is checked first and by construction.
func _test_the_lattice_is_the_lattice(t) -> void:
	var junctions := StreetNetwork.junction_count()
	t.check(junctions == Tuning.CITY_BLOCKS + Vector2i.ONE,
			"one more junction than blocks along each axis")
	var expected := junctions.y * (junctions.x - 1) + junctions.x * (junctions.y - 1)
	t.check(StreetNetwork.segments().size() == expected,
			"the lattice has %d streets" % expected)

	var map := _maps[0]
	for segment in StreetNetwork.segments():
		var rect := segment.tile_rect()
		t.check(rect.size == (Vector2i(Tuning.BLOCK_SIZE, Tuning.STREET_WIDTH)
				if segment.horizontal else Vector2i(Tuning.STREET_WIDTH, Tuning.BLOCK_SIZE)),
				"street %s is one block long and one corridor wide" % segment.key())
		if not map.has_street(segment.key()):
			continue   # absorbed into a calm zone; it is grass, and the next test says so
		# A street the player cannot walk down is not a street, and closing one would be a
		# closure nobody could see.
		var walkable := 0
		for tile in map.rect_tiles(rect):
			if map.is_walkable(tile):
				walkable += 1
		t.check(walkable == rect.size.x * rect.size.y,
				"every tile of street %s is walkable" % segment.key())

## M21. A multi-block calm zone is painted over the corridors between its own blocks, so the
## lattice has holes in it and route redundancy stops being true by construction.
##
## Four things have to hold together for that to be a hole rather than a bug, and each is a
## different way it could quietly not be one: the streets have to be **gone from the graph**,
## their ground has to be **calm rather than closed** (the player walks over it — that is the
## whole point), any junction *inside* the zone has to have **nothing reaching it**, and the ones
## around it have to still be reachable, because they are the ways in.
##
## **Every count here is stated over the footprint since M52**, because a zone may be a 2x1 now: a
## `w x h` zone absorbs `w*(h-1) + h*(w-1)` streets — four for the square, one for a rectangle —
## has `2*(w+h)` streets round it, and contains `(w-1)*(h-1)` junctions, which is **none** for a
## rectangle. A count written as `2 * CALM_ZONE_BLOCKS * (CALM_ZONE_BLOCKS - 1)` was the square's
## answer, and it agreed with the general one for as long as every zone was a square.
##
## **The apartment complex is the same mechanism and the opposite ground, so it is skipped here and
## checked in `tests/test_generator.gd` instead.** Its absorbed streets are absent from the lattice
## exactly like a zone's and they are *built over*, which is the one sentence in this test that
## reverses: a zone is walked through, and a complex is walked round.
func _test_a_calm_zone_takes_its_streets_out_of_the_lattice(t) -> void:
	var zones := 0
	for map in _maps:
		for anchor: Vector2i in map.zone_rects:
			if map.starting_purpose(anchor) == GameEnums.BlockPurpose.COURTYARD:
				continue
			zones += 1
			var footprint: Rect2i = map.zone_rects[anchor]
			var span := footprint.size
			var absorbed := span.x * (span.y - 1) + span.y * (span.x - 1)
			var found := 0
			for segment in StreetNetwork.segments():
				if map.has_street(segment.key()):
					continue
				var rect := segment.tile_rect()
				if not CityMap.blocks_tile_rect(footprint).encloses(rect):
					continue
				found += 1
				for tile in map.rect_tiles(rect):
					t.check(Tile.is_calm(map.tile_at(tile)),
							"seed %d: the street %s the zone took is calm ground at %s"
							% [map.seed_used, segment.key(), tile])
					t.check(not map.is_closed(tile),
							"seed %d: and is open — a zone is walked through, not walked round"
							% map.seed_used)
			t.check(found == absorbed,
					"seed %d zone %s absorbed its %d inside streets (found %d)"
					% [map.seed_used, anchor, absorbed, found])

			# Any junction inside the zone has nothing left reaching it; the ones on the edges are
			# T-junctions, which is what the milestone is for. A 2x1 has no interior junction at
			# all — its one absorbed street runs between two junctions that both survive.
			for y in range(footprint.position.y + 1, footprint.end.y):
				for x in range(footprint.position.x + 1, footprint.end.x):
					var inside := Vector2i(x, y)
					t.check(StreetNetwork.junction_distances([inside],
							map.blocked_segments()).size() == 1,
							"seed %d: junction %s inside zone %s is cut off from the whole city"
							% [map.seed_used, inside, anchor])
			var ways_in := StreetNetwork.around_blocks(footprint)
			t.check(ways_in.size() == 2 * (span.x + span.y),
					"seed %d zone %s has %d streets round it, one per block edge"
					% [map.seed_used, anchor, ways_in.size()])
			for segment in ways_in:
				t.check(map.has_street(segment.key()),
						"seed %d: the way in %s is a real street" % [map.seed_used, segment.key()])
	t.check(zones >= SEEDS, "every seed made a zone (%d over %d seeds)" % [zones, SEEDS])

## A junction belongs to no street on purpose: it is where the choice is made, so closing a
## street may never seal the corner it starts from.
func _test_a_tile_knows_which_street_it_is_on(t) -> void:
	var map := _maps[0]
	for segment in StreetNetwork.segments():
		for tile in map.rect_tiles(segment.tile_rect()):
			var found := StreetNetwork.segment_containing(tile)
			t.check(found != null and found.key() == segment.key(),
					"tile %s belongs to street %s" % [tile, segment.key()])
	for i in StreetNetwork.junction_count().x:
		var corner := Vector2i(i, i) * CityMap.period()
		t.check(StreetNetwork.segment_containing(corner) == null,
				"junction tile %s belongs to no street" % corner)

## The layout guarantee from docs/CITY.md, restated on the graph: with nothing closed, every
## piece of calm ground can be walked to. If this ever fails the *generator* is wrong, not the
## planner, and no closure set could rescue the day.
##
## **It asked for two ways in until 2026-08-31**, and the second is an offer now rather than a
## guarantee: *"the two routes guarantee is not a hard rule."* What replaces it here is not a
## weaker version of the same sentence but a different one — a hard blocker holds for the whole
## run, so what it may never do is make calm unreachable, and how many ways round it there are is
## the city's business. `tests/test_route_tree.gd` is where the second route is measured; the
## count below is what it came out as, kept as a floor rather than as the promise.
func _test_an_open_city_can_reach_everywhere_calm(t) -> void:
	var with_a_choice := 0
	var total := 0
	for map in _maps:
		var home := ClosurePlanner.home_street(map)
		t.check(home != null, "seed %d: the front door opens onto a street" % map.seed_used)
		for area in ClosurePlanner.calm_areas(map):
			t.check(StreetNetwork.route_count(home, area.access, map.blocked_segments(), 1) >= 1,
					"seed %d: calm area %s can be walked to before anything closes"
					% [map.seed_used, area.block])
			total += 1
			if StreetNetwork.route_count(home, area.access, map.blocked_segments(), 2) >= 2:
				with_a_choice += 1
	# Measured at 100% of areas on these seeds with the weaker gate in place. A floor well under
	# it, because the offer is allowed to fail on a map that cannot make it — what would be worth
	# knowing about is the offer quietly disappearing.
	t.check(float(with_a_choice) / float(total) >= 0.8,
			"and most of them still have a choice of ways in (%d of %d)" % [with_a_choice, total])

## `ClosurePlanner._access_segments` walks out from an area's tiles until it reaches a real
## street, and a four-block apartment complex's archway can cross the geometric footprint of the
## complex's own absorbed street on the way — a tile that is walkable and answers to a segment key,
## but is not a street any lattice search may use. Stopping there rather than walking through it is
## exactly the bug the milestone's own `_access_streets` had, arrived at by a different route: the
## found "street" is absent, `route_count` never reaches it, and the area reads as unreachable.
func _test_access_segments_are_never_absent(t) -> void:
	var checked := 0
	for map in _maps:
		for area in ClosurePlanner.calm_areas(map):
			for segment in area.access:
				checked += 1
				t.check(map.has_street(segment.key()),
						"seed %d: %s's access street %s is a real street, not an absent one"
						% [map.seed_used, area.block, segment.key()])
	t.check(checked > 0, "some calm area had access streets to check (%d)" % checked)

## Menger, the other way round, asked about the **city** rather than about one area: no single
## street may cut off *all* the calm. This is the winnability property the old edge-disjoint rule
## was standing in for, stated directly — by actually closing each street in turn, the same brute
## force `tests/test_generator.gd` uses on the tile grid, on one seed because it is
## O(streets x flow).
##
## **It used to be stated per area and cannot be any more.** *(2026-08-31.)* A calm area with one
## way in is legitimate — the design says so about courtyards and now about the tree's second
## probe — so *"this area survives any street being shut"* is false by construction the moment a
## dead end takes one of its ways in. What is not allowed to be false is that shutting one street
## leaves her nowhere to go, and that is the sentence worth holding: it is the one whose failure
## is an unwinnable run rather than a short day.
##
## The area's own access streets are excluded, and that exclusion is the doorway exemption rather
## than a convenience: a courtyard has one archway onto one street, so shutting that street does
## put it out of reach. `_test_a_doorway_is_not_a_route` below is the other half of this.
func _test_no_single_street_cuts_off_all_the_calm(t) -> void:
	var map := _maps[0]
	var home := ClosurePlanner.home_street(map)
	var areas := ClosurePlanner.calm_areas(map)
	for segment in StreetNetwork.segments():
		if segment.key() == home.key() or not map.has_street(segment.key()):
			continue
		var closed := map.blocked_segments()
		closed[segment.key()] = true
		var reachable := 0
		for area in areas:
			var doors := {}
			for door in area.access:
				doors[door.key()] = true
			# An area reached only through the street being shut is out of reach today, which is
			# the doorway exemption and not a failure.
			if doors.has(segment.key()) and area.access.size() == 1:
				continue
			if StreetNetwork.route_count(home, area.access, closed, 1) >= 1:
				reachable += 1
		t.check(reachable >= Tuning.MIN_CALM_AREAS_REACHABLE,
				"shutting %s still leaves %d calm areas to walk to, wanting %d"
				% [segment.key(), reachable, Tuning.MIN_CALM_AREAS_REACHABLE])

## The exemption, stated as a fact rather than left implicit: an area with one way in loses
## it if that way is shut, and it is the *invariant* — two other areas still reachable — that
## keeps the day winnable, not any promise about this one.
##
## A courtyard is the case that matters. If this ever stops finding one, the test has stopped
## checking anything and wants pointing at whatever replaced hidden calm.
func _test_a_doorway_is_not_a_route(t) -> void:
	var checked := 0
	for map in _maps:
		var home := ClosurePlanner.home_street(map)
		for area in ClosurePlanner.calm_areas(map):
			if area.access.size() != 1:
				continue
			checked += 1
			t.check(StreetNetwork.route_count(home, area.access, map.blocked_segments(), 1) >= 1,
					"seed %d: the one archway into %s can be walked to"
					% [map.seed_used, area.block])
			var closed := map.blocked_segments()
			closed[area.access[0].key()] = true
			t.check(StreetNetwork.route_count(home, area.access, closed, 1) == 0,
					"seed %d: and shutting that archway's street puts %s out of reach today"
					% [map.seed_used, area.block])
	t.check(checked > 0, "the city still has calm with a single way in (%d found)" % checked)
