extends RefCounted
## `RoadblockPhase`, the roadblock phase at dawn (inbox #1185): it draws among every route-adjacent
## section the day's ground offers a valid roadblock, with a bias toward the farthest from the
## roadblocks already placed, assigns each section it takes, asks an offer again once a roadblock
## stands within the ground's radius of it, and stops once every route tile has one close by. Run
## with stand-ins for both of what it is handed: the day's locations (`_Locations`, sections as the
## game lays them out: on their own streets, each its own index along its street, with its real tile
## rect and centre) and the day's ground (`_Ground`, whose offers, route tiles and close-by answers a
## check sets). The real ground's rules are the scheduler's own judge, checked in
## `tests/test_events_placement.gd`; the phase on a real day is `tests/test_events_scheduler.gd`'s
## day-13 check.

func run(t) -> void:
	_test_it_stops_once_every_route_tile_has_one_close_by(t)
	_test_a_section_offered_none_is_never_drawn(t)
	_test_it_stops_once_no_section_could_cover_a_tile_left(t)
	_test_every_offered_section_is_in_the_draw(t)
	_test_each_roadblock_leans_toward_the_farthest(t)
	_test_offers_near_a_roadblock_just_placed_are_asked_again(t)

const SEEDS := 300

## The day's locations, its route-adjacent sections set by hand.
class _Locations extends DayLocations:
	var sections: Array[Location] = []

	## Overrides DayLocations.sections_in.
	func sections_in(view: int) -> Array[Location]:
		var open: Array[Location] = []
		if view == PlacementView.View.ROUTE_ADJACENT:
			for section in sections:
				if not section.is_taken():
					open.append(section)
		return open

	## Overrides DayLocations.assign.
	func assign(section: Location, plan: EventScheduler.Planned) -> void:
		section.take(plan)

## The day's ground: the route tiles, which sections are offered a roadblock, which route tiles a
## roadblock in each section is close by, and the radius offers are asked again within, all set by
## the check.
class _Ground extends RoadblockGround:
	var tiles: Array[Vector2i] = []
	## Section -> the route tiles its roadblock is close by.
	var close_by := {}
	## Sections offered none.
	var refused := {}
	## Section -> the section whose roadblock standing refuses it afterwards.
	var refused_once := {}
	var radius := 0.0
	var stood: Array[EventScheduler.Planned] = []
	var _of := {}

	## Overrides RoadblockGround.route_tiles.
	func route_tiles() -> Array[Vector2i]:
		return tiles

	## Overrides RoadblockGround.offer.
	func offer(section: Location) -> EventScheduler.Planned:
		if refused.has(section):
			return null
		if refused_once.has(section):
			for plan in stood:
				if _of[plan] == refused_once[section]:
					return null
		var plan := EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"), section.centre())
		_of[plan] = section
		return plan

	## Overrides RoadblockGround.covers.
	func covers(plan: EventScheduler.Planned) -> Array[Vector2i]:
		return close_by.get(_of[plan], [] as Array[Vector2i])

	## Overrides RoadblockGround.reoffer_within.
	func reoffer_within() -> float:
		return radius

	## Overrides RoadblockGround.stand.
	func stand(plan: EventScheduler.Planned) -> void:
		stood.append(plan)

	## The section `plan` was offered for.
	func section_of(plan: EventScheduler.Planned) -> Location:
		return _of[plan]

## Where a block of 8 tiles splits into its three sections, 3, 2 and 3 tiles along the street, as
## `StreetLocations` lays them out.
const SECTION_TILES: Array[int] = [0, 3, 5, 8]

## Section `index` (0 to 2) of the street `key`, as the game lays it out: its tile rect a third of
## the street's length, its whole width, and its centre in world space.
static func _section(key: Vector3i, index: int) -> Location:
	var segment := StreetNetwork.Segment.new(Vector2i(key.x, key.y), key.z == 0)
	var street := segment.tile_rect()
	var along := Vector2i.RIGHT if segment.horizontal else Vector2i.DOWN
	var length := SECTION_TILES[index + 1] - SECTION_TILES[index]
	var size := Vector2i(length, street.size.y) if segment.horizontal \
			else Vector2i(street.size.x, length)
	var tiles := Rect2i(street.position + along * SECTION_TILES[index], size)
	var centre := (Vector2(tiles.position) + Vector2(tiles.size) * 0.5) * Tuning.TILE_SIZE
	return Location.new(segment, index, tiles, centre, PlacementView.View.ROUTE_ADJACENT, true)

static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

## Route tiles, by name.
static func _tiles(names: Array[int]) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for name in names:
		found.append(Vector2i(name, name))
	return found

## The phase run on `seed_value` over `sections` and `ground`: the sections it took, in order.
static func _taken(ground: _Ground, sections: Array[Location], seed_value: int) -> Array[Location]:
	var locations := _Locations.new()
	locations.sections = sections
	var taken: Array[Location] = []
	for plan in RoadblockPhase.new(locations, ground).place(_rng(seed_value)):
		taken.append(ground.section_of(plan))
	return taken

func _test_it_stops_once_every_route_tile_has_one_close_by(t) -> void:
	var always := true
	for seed_value in SEEDS:
		var a := _section(Vector3i(2, 2, 1), 0)
		var b := _section(Vector3i(5, 2, 1), 1)
		var c := _section(Vector3i(8, 2, 1), 2)
		var ground := _Ground.new()
		ground.tiles = _tiles([1, 2])
		ground.close_by = {a: _tiles([1]), b: _tiles([2]), c: _tiles([1])}
		var locations := _Locations.new()
		locations.sections = [a, b, c] as Array[Location]
		var phase := RoadblockPhase.new(locations, ground)
		var placed := phase.place(_rng(seed_value))
		var covered := {}
		var before_the_last := {}
		for index in placed.size():
			for tile in ground.covers(placed[index]):
				covered[tile] = true
				if index < placed.size() - 1:
					before_the_last[tile] = true
			always = always and ground.section_of(placed[index]).is_taken()
		always = always and covered.size() == 2 and before_the_last.size() < 2 \
				and phase.left_uncovered() == 0 and ground.stood.size() == placed.size()
	t.check(always, "every route tile gets a roadblock close by, and the phase stops with the one "
			+ "that covers the last: each section it drew taken and stood in the day (%d seeds)"
			% SEEDS)

func _test_a_section_offered_none_is_never_drawn(t) -> void:
	var never := true
	for seed_value in SEEDS:
		var refused := _section(Vector3i(2, 2, 1), 1)
		var other := _section(Vector3i(6, 4, 0), 1)
		var ground := _Ground.new()
		ground.tiles = _tiles([1, 2])
		ground.refused = {refused: true}
		ground.close_by = {refused: _tiles([1]), other: _tiles([2])}
		var locations := _Locations.new()
		locations.sections = [refused, other] as Array[Location]
		var phase := RoadblockPhase.new(locations, ground)
		var placed := phase.place(_rng(seed_value))
		never = never and not refused.is_taken() and placed.size() == 1 \
				and phase.left_uncovered() == 1
	t.check(never, "a section the day's ground offers no roadblock is never drawn, and the route "
			+ "tile only it was close by is left counted without one (%d seeds)" % SEEDS)

## A route tile no section reaches is never covered, so full coverage cannot be reached. The phase
## still stops: once A, the one section close by the other route tile, stands, no section left could
## bring a roadblock close by a tile that has none, so B and C, close by nothing, are not drawn after
## it. Before A they may be, since A could still cover a tile then.
func _test_it_stops_once_no_section_could_cover_a_tile_left(t) -> void:
	var always := true
	var nothing_first := 0
	for seed_value in SEEDS:
		var a := _section(Vector3i(2, 2, 1), 1)
		var b := _section(Vector3i(5, 2, 1), 1)
		var c := _section(Vector3i(8, 2, 1), 1)
		var ground := _Ground.new()
		ground.tiles = _tiles([1, 9])
		ground.close_by = {a: _tiles([1])}
		var locations := _Locations.new()
		locations.sections = [a, b, c] as Array[Location]
		var phase := RoadblockPhase.new(locations, ground)
		var placed := phase.place(_rng(seed_value))
		always = always and not placed.is_empty() and ground.section_of(placed.back()) == a \
				and phase.left_uncovered() == 1
		if placed.size() > 1:
			nothing_first += 1
	t.check(always, "where a route tile no section reaches is left, the phase stops with the last "
			+ "section that could still cover one: nothing is drawn after it (%d seeds)" % SEEDS)
	t.check(nothing_first > 0 and nothing_first < SEEDS,
			"and a section close by nothing is still drawn before it on some days (%d of %d)"
			% [nothing_first, SEEDS])

## A section close by no route tile is in the draw like any other: the bias ranks every offered
## section, and nothing leaves one out for what it would cover.
func _test_every_offered_section_is_in_the_draw(t) -> void:
	var drawn := 0
	for seed_value in SEEDS:
		var nothing := _section(Vector3i(9, 9, 0), 1)
		var other := _section(Vector3i(2, 2, 1), 1)
		var ground := _Ground.new()
		ground.tiles = _tiles([2])
		ground.close_by = {other: _tiles([2])}
		if _taken(ground, [nothing, other] as Array[Location], seed_value).has(nothing):
			drawn += 1
	t.check(drawn > SEEDS / 4 and drawn < SEEDS,
			"a section close by no route tile is still drawn, before the one that is, on some days "
			+ "(%d of %d)" % [drawn, SEEDS])

## A first roadblock is placed at A, the only section close by the first route tile; the second
## route tile is close by B, about 450px from A, and C, about 900px from it. With the weight the
## square of the distance, C is about four times as likely as B: drawn more often, and B still drawn.
func _test_each_roadblock_leans_toward_the_farthest(t) -> void:
	var near := 0
	var far := 0
	for seed_value in SEEDS:
		var a := _section(Vector3i(2, 2, 1), 1)
		var b := _section(Vector3i(3, 2, 1), 1)
		var c := _section(Vector3i(4, 2, 1), 1)
		var ground := _Ground.new()
		ground.tiles = _tiles([1, 2])
		ground.close_by = {a: _tiles([1]), b: _tiles([2]), c: _tiles([2])}
		var taken := _taken(ground, [a, b, c] as Array[Location], seed_value)
		if taken.size() != 2 or taken[0] != a:
			continue
		if taken[1] == b:
			near += 1
		elif taken[1] == c:
			far += 1
	t.check(near + far > SEEDS / 6, "there were draws after a first roadblock at A to count (%d)"
			% (near + far))
	t.check(far > 2 * near, "the section farther from the roadblock already placed is drawn more "
			+ "often (%d at about 900px against %d at about 450px)" % [far, near])
	t.check(near > 0, "and the nearer one is still drawn: a bias, not a rule (%d)" % near)

## B, the next section along A's street (80px from it), is offered a roadblock until one stands at A;
## D, the section after it (160px from A), is close by the same route tile as B. With the ground
## asking offers again within 100px of a roadblock just placed, B is never placed after A, though the
## bias would draw it about one time in five were its first offer kept.
func _test_offers_near_a_roadblock_just_placed_are_asked_again(t) -> void:
	var never := true
	var counted := 0
	for seed_value in SEEDS:
		var a := _section(Vector3i(2, 2, 1), 0)
		var b := _section(Vector3i(2, 2, 1), 1)
		var d := _section(Vector3i(2, 2, 1), 2)
		var ground := _Ground.new()
		ground.tiles = _tiles([1, 2])
		ground.close_by = {a: _tiles([1]), b: _tiles([2]), d: _tiles([2])}
		ground.refused_once = {b: a}
		ground.radius = 100.0
		var taken := _taken(ground, [a, b, d] as Array[Location], seed_value)
		if taken.is_empty() or taken[0] != a:
			continue
		counted += 1
		never = never and not taken.has(b) and taken.has(d)
	t.check(counted > 0, "there were days with A placed first to count (%d)" % counted)
	t.check(never, "a section whose offer the roadblock just placed beside it withdraws is not "
			+ "drawn after it")
