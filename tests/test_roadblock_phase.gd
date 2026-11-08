extends RefCounted
## `RoadblockPhase`, the roadblock phase at dawn (inbox #1185): it draws route-adjacent sections with
## a bias toward the farthest from the roadblocks already placed, considers only a section the day's
## ground offers a roadblock, assigns each section it takes, and stops once every route tile has one
## close by. Run with stand-ins for both of what it is handed: the day's locations (a handful of
## sections built by hand, `_Locations`) and the day's ground (`_Ground`, whose offers, route tiles
## and close-by answers a check sets). The real ground's rules are the scheduler's own judge, checked
## in `tests/test_events_placement.gd`; the phase on a real day is `tests/test_events_scheduler.gd`'s
## day-13 check.

func run(t) -> void:
	_test_it_stops_once_every_route_tile_has_one_close_by(t)
	_test_a_section_offered_none_is_never_drawn(t)
	_test_a_section_close_by_nothing_new_takes_none(t)
	_test_each_roadblock_leans_toward_the_farthest(t)
	_test_offers_near_a_roadblock_just_placed_are_asked_again(t)

const REACH := 100000.0
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

## The day's ground: the route tiles, which sections are offered a roadblock, and which route tiles
## a roadblock in each section is close by, all set by the check.
class _Ground extends RoadblockGround:
	var tiles: Array[Vector2i] = []
	## Section -> the route tiles its roadblock is close by.
	var close_by := {}
	## Sections offered none.
	var refused := {}
	## Section -> the section whose roadblock standing refuses it afterwards.
	var refused_once := {}
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

	## Overrides RoadblockGround.stand.
	func stand(plan: EventScheduler.Planned) -> void:
		stood.append(plan)

	## The section `plan` was offered for.
	func section_of(plan: EventScheduler.Planned) -> Location:
		return _of[plan]

static func _section(at: Vector2) -> Location:
	return Location.new(StreetNetwork.Segment.new(Vector2i.ZERO, true), 1, Rect2i(), at,
			PlacementView.View.ROUTE_ADJACENT, true)

static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

## The sections the phase took on `seed_value`, in order, over fresh copies of `sections`.
static func _placed(ground: _Ground, sections: Array[Location], seed_value: int,
		reoffer_within := 0.0) -> Array[Location]:
	var locations := _Locations.new()
	locations.sections = sections
	var phase := RoadblockPhase.new(locations, ground, REACH, reoffer_within)
	var taken: Array[Location] = []
	for plan in phase.place(_rng(seed_value)):
		taken.append(ground.section_of(plan))
	return taken

func _test_it_stops_once_every_route_tile_has_one_close_by(t) -> void:
	var always := true
	for seed_value in SEEDS:
		var a := _section(Vector2(0, 0))
		var b := _section(Vector2(500, 0))
		var c := _section(Vector2(1000, 0))
		var ground := _Ground.new()
		ground.tiles = [Vector2i(1, 1), Vector2i(2, 2)] as Array[Vector2i]
		ground.close_by = {a: [Vector2i(1, 1)] as Array[Vector2i],
				b: [Vector2i(2, 2)] as Array[Vector2i], c: [Vector2i(1, 1)] as Array[Vector2i]}
		var locations := _Locations.new()
		locations.sections = [a, b, c] as Array[Location]
		var phase := RoadblockPhase.new(locations, ground, REACH, 0.0)
		var placed := phase.place(_rng(seed_value))
		var covered := {}
		for plan in placed:
			for tile in ground.covers(plan):
				covered[tile] = true
			always = always and ground.section_of(plan).is_taken()
		always = always and placed.size() == 2 and covered.size() == 2 \
				and phase.left_uncovered() == 0 and ground.stood.size() == 2
	t.check(always, "every route tile gets a roadblock close by, then the phase stops: two placed, "
			+ "each section taken and each stood in the day, on every one of %d seeds" % SEEDS)

func _test_a_section_offered_none_is_never_drawn(t) -> void:
	var never := true
	for seed_value in SEEDS:
		var refused := _section(Vector2(0, 0))
		var other := _section(Vector2(800, 0))
		var ground := _Ground.new()
		ground.tiles = [Vector2i(1, 1), Vector2i(2, 2)] as Array[Vector2i]
		ground.refused = {refused: true}
		ground.close_by = {refused: [Vector2i(1, 1)] as Array[Vector2i],
				other: [Vector2i(2, 2)] as Array[Vector2i]}
		var locations := _Locations.new()
		locations.sections = [refused, other] as Array[Location]
		var phase := RoadblockPhase.new(locations, ground, REACH, 0.0)
		var placed := phase.place(_rng(seed_value))
		never = never and not refused.is_taken() and placed.size() == 1 \
				and phase.left_uncovered() == 1
	t.check(never, "a section the day's ground offers no roadblock is never drawn, and the route "
			+ "tile only it was close by is left counted without one (%d seeds)" % SEEDS)

func _test_a_section_close_by_nothing_new_takes_none(t) -> void:
	var never := true
	for seed_value in SEEDS:
		var useless := _section(Vector2(0, 0))
		var other := _section(Vector2(800, 0))
		var ground := _Ground.new()
		ground.tiles = [Vector2i(2, 2)] as Array[Vector2i]
		ground.close_by = {other: [Vector2i(2, 2)] as Array[Vector2i]}
		var taken := _placed(ground, [useless, other] as Array[Location], seed_value)
		never = never and taken == ([other] as Array[Location]) and not useless.is_taken()
	t.check(never, "a section whose roadblock would be close by no route tile left without one "
			+ "takes none (%d seeds)" % SEEDS)

## A first roadblock is placed at A, the only section close by the first route tile; the second
## route tile is close by B, 500px from A, and C, 1,000px from it. With the weight the square of
## the distance, C is four times as likely as B: drawn more often, and B still drawn.
func _test_each_roadblock_leans_toward_the_farthest(t) -> void:
	var near := 0
	var far := 0
	for seed_value in SEEDS:
		var a := _section(Vector2(0, 0))
		var b := _section(Vector2(500, 0))
		var c := _section(Vector2(1000, 0))
		var ground := _Ground.new()
		ground.tiles = [Vector2i(1, 1), Vector2i(2, 2)] as Array[Vector2i]
		ground.close_by = {a: [Vector2i(1, 1)] as Array[Vector2i],
				b: [Vector2i(2, 2)] as Array[Vector2i], c: [Vector2i(2, 2)] as Array[Vector2i]}
		var taken := _placed(ground, [a, b, c] as Array[Location], seed_value)
		if taken.size() != 2 or taken[0] != a:
			continue
		if taken[1] == b:
			near += 1
		elif taken[1] == c:
			far += 1
	t.check(near + far > SEEDS / 6, "there were draws after a first roadblock at A to count (%d)"
			% (near + far))
	t.check(far > 2 * near, "the section farther from the roadblock already placed is drawn more "
			+ "often (%d at 1,000px against %d at 500px)" % [far, near])
	t.check(near > 0, "and the nearer one is still drawn: a bias, not a rule (%d)" % near)

## B is offered a roadblock until one stands at A, 100px away; D, far off, is close by the same
## route tile as B. With the offers asked again within 200px of a roadblock just placed, B is never
## placed after A.
func _test_offers_near_a_roadblock_just_placed_are_asked_again(t) -> void:
	var never := true
	var counted := 0
	for seed_value in SEEDS:
		var a := _section(Vector2(0, 0))
		var b := _section(Vector2(100, 0))
		var d := _section(Vector2(5000, 0))
		var ground := _Ground.new()
		ground.tiles = [Vector2i(1, 1), Vector2i(2, 2)] as Array[Vector2i]
		ground.close_by = {a: [Vector2i(1, 1)] as Array[Vector2i],
				b: [Vector2i(2, 2)] as Array[Vector2i], d: [Vector2i(2, 2)] as Array[Vector2i]}
		ground.refused_once = {b: a}
		var taken := _placed(ground, [a, b, d] as Array[Location], seed_value, 200.0)
		if taken.is_empty() or taken[0] != a:
			continue
		counted += 1
		never = never and not taken.has(b) and taken.has(d)
	t.check(counted > 0, "there were days with A placed first to count (%d)" % counted)
	t.check(never, "a section whose offer the roadblock just placed beside it withdraws is not "
			+ "drawn after it")
