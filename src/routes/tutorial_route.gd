class_name TutorialRoute
extends RefCounted
## **Day 1's tutorial route**: the doorstep's street (the first block), then the lesson streets one
## after another, then the tutorial park, the way she is taught to walk on the day whose spec walks
## the tutorial (`DaySpec.walks_the_tutorial()`). A pure function of the run's city map, worked out
## once in the composition root (`main._build_the_city()`) and handed to `City`, which hands it on
## in the day's `DayStreets`; nothing derives it a second time, and a city handed none has none.
##
## The design is `docs/CITY.md`, "How the corridor is built" and "Sealing the tree". The player asked for day 1 sealed off
## past its first block, both sidewalks of every side street blocked and the street open, so that no
## valid route leaves the tutorial route past the first block (gentle-owl #1253).
##
## **Only a route the seals can close is taken**, checked before it is accepted (**city**), never
## repaired after. `for_city()` tries every route of six streets, then of seven (one lesson street
## left empty), and refuses one whose lesson streets
##
## - **run along the main road or end at one of its junctions**, past the first: the spine is never
##   sealed on a day, so it would be a way off along its sidewalks. The junction where the route
##   leaves the doorstep's street may stand on it, since that junction is first-block ground she may
##   turn off at anyway;
## - **are a precinct**: a soft seal leaves a precinct's paved middle walkable, and a lesson street
##   is never sealed. A precinct **side street** is allowed and sealed hard at its mouth
##   (`SealPlanner`), since a seal need not be a soft one where a soft pair cannot close the street;
## - **border open ground**, other than the tutorial park on the last street or at its far junction:
##   a park, a zone, a square or a courtyard opening onto a lesson street is a way off no seal closes;
## - **border the home block**: the home-street rule keeps every row off its four streets;
##
## and keeps, of the rest, one whose tutorial park is a park or a calm zone where one fits, a square
## or a courtyard otherwise, whose side streets past the first block open onto no open ground
## between the route and their seal (the park aside, at the last street's ends), whose junction
## boxes past the first open onto nothing past the pavement left of a street the city does not
## have (`CityMap.has_street()`), which no seal or wall closes, and from
## whose first block a second calm area stays reachable. A through-alley with a mouth on a lesson
## street or a side street's mouth half refuses nothing: the seals wall that mouth.

## The doorstep's street: the first block, which the route starts in and nothing seals.
var _home: StreetNetwork.Segment
## The lesson streets, in the order she walks them, the first leaving the doorstep's street.
var _streets: Array[StreetNetwork.Segment] = []
## The junctions the route passes, from the one it leaves the doorstep's street at to the far end
## of the last lesson street: one more than `_streets`.
var _junctions: Array[Vector2i] = []
## The tutorial park: the block that anchors it, and its own calm ground.
var _park_block := Vector2i(-1, -1)
var _park_rect := Rect2i()
## The map the route was laid on, for the questions about what opens onto it.
var _map: CityMap

## A route laid by hand or by `for_city()`: the doorstep's street, the lesson streets in order, the
## junctions from the doorstep's street to the far end of the last one, and the park.
func _init(map: CityMap, home: StreetNetwork.Segment, streets: Array[StreetNetwork.Segment],
		junctions: Array[Vector2i], park_block: Vector2i, park_rect: Rect2i) -> void:
	_map = map
	_home = home
	_streets = streets
	_junctions = junctions
	_park_block = park_block
	_park_rect = park_rect

# ---------------------------------------------------------------- questions ---

## The block that anchors the tutorial park, as `CityMap.calm_blocks_now()` names it.
func park_block() -> Vector2i:
	return _park_block

## Whether one of `blocks` lies in the tutorial park: the blocks she settled in, each named by the
## block she stood in (`CityMap.block_at()`), which in a calm zone may be any of its blocks.
func has_its_park_among(blocks: Array[Vector2i]) -> bool:
	for block in blocks:
		if _map.anchor_of(block) == _park_block:
			return true
	return false

## The doorstep's street: the first block, which the route starts in.
func doorstep_street() -> StreetNetwork.Segment:
	return _home

## The junctions the route passes, in the order she walks them: the one it leaves the doorstep's
## street at, then the far end of each lesson street, one more than `lesson_streets()`.
func junctions() -> Array[Vector2i]:
	return _junctions.duplicate()

## The junction where the route leaves the doorstep's street.
func turning_junction() -> Vector2i:
	return _junctions[0]

## The lesson streets, in the order she walks them, the first leaving the doorstep's street at
## `turning_junction()`: the one the first park sign points down (`ParkSigns`), and the streets a
## day that leaves day 1's walk open keeps unsealed and unclosed (`SealPlanner`, `ClosurePlanner`)
## and keeps a sidewalk of (`OneSidewalkOpenRule`).
func lesson_streets() -> Array[StreetNetwork.Segment]:
	return _streets.duplicate()

## The ground no other branch of the day's tree may use: the lesson streets, every junction box
## past the first, the half of each side street past the first block nearest the route (its
## mouth, where `SealPlanner` stands its seal), and the tutorial park. So no other branch merges
## into the route past its first block, reaches the park another way, or runs over a side street's
## mouth: a calm area that opens onto a side street is reached along the far half, so the seal at
## the mouth never stands on a branch and never leaves the side street open for one.
func kept_ground() -> Dictionary:
	var found := _ground_past_the_first_block()
	for tile in _map.rect_tiles(_park_rect):
		found[tile] = true
	for mouth in side_street_mouths():
		var segment: StreetNetwork.Segment = mouth[0]
		for tile in _map.rect_tiles(_mouth_half(segment, bool(mouth[1]))):
			found[tile] = true
	return found

## The half of `segment` nearest its `at_a` end: the ground a seal at that mouth stands on.
static func _mouth_half(segment: StreetNetwork.Segment, at_a: bool) -> Rect2i:
	var rect := segment.tile_rect()
	if segment.horizontal:
		var half := rect.size.x / 2
		return Rect2i(Vector2i(rect.position.x if at_a else rect.end.x - half, rect.position.y),
				Vector2i(half, rect.size.y))
	var tall := rect.size.y / 2
	return Rect2i(Vector2i(rect.position.x, rect.position.y if at_a else rect.end.y - tall),
			Vector2i(rect.size.x, tall))

## The side streets past the first block, each with the end of it that opens onto the route
## (`true` for its `a` end), one entry per mouth: every real street meeting the route at a junction
## past the first that is not a lesson street. A side street with both ends on the route has two.
func side_street_mouths() -> Array[Array]:
	var found: Array[Array] = []
	var on_route := {}
	for segment in _streets:
		on_route[segment.key()] = true
	for i in range(1, _junctions.size()):
		var junction := _junctions[i]
		for arm in _map.street_network().at_junction(junction):
			if on_route.has(arm.key()) or not _map.has_street(arm.key()):
				continue
			found.append([arm, arm.a == junction])
	return found

## The through-alleys with a mouth on a lesson street or on a side street's mouth half past the
## first block (the stub between the route's junction box and the side street's seal), each with
## which mouth (`true` for the one at its rect's start), one entry per such mouth.
func alley_mouths() -> Array[Array]:
	var found: Array[Array] = []
	var lesson := {}
	for segment in _streets:
		for tile in _map.rect_tiles(segment.tile_rect()):
			lesson[tile] = true
	for mouth in side_street_mouths():
		var segment: StreetNetwork.Segment = mouth[0]
		for tile in _map.rect_tiles(_mouth_half(segment, bool(mouth[1]))):
			lesson[tile] = true
	for rect in _map.alley_lots():
		if _map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
			continue
		var vertical := rect.size.x < rect.size.y
		for at_start: bool in [true, false]:
			var mouth := SealPlanner.alley_mouth_rect(rect, vertical, at_start)
			var outside := mouth.position + (
					(Vector2i.UP if at_start else Vector2i(0, mouth.size.y)) if vertical
					else (Vector2i.LEFT if at_start else Vector2i(mouth.size.x, 0)))
			if lesson.has(outside):
				found.append([rect, at_start])
	return found

## **The units the route runs through past the first block**, as tile rects, which is how
## `Location.part_of()` names a unit: each lesson street's, and the junction box at each end of
## one, the box where the route leaves the doorstep's street included. What day 1's lessons are
## stood among and every other location of is drawn empty (`DawnTutorial`).
func units_past_the_first_block() -> Array[Rect2i]:
	var units: Array[Rect2i] = []
	for segment in _streets:
		units.append(segment.tile_rect())
	for junction in _junctions:
		units.append(_box(junction))
	return units

func _ground_past_the_first_block() -> Dictionary:
	var found := {}
	for segment in _streets:
		for tile in _map.rect_tiles(segment.tile_rect()):
			found[tile] = true
	for i in range(1, _junctions.size()):
		for tile in _map.rect_tiles(_box(_junctions[i])):
			found[tile] = true
	return found

static func _box(junction: Vector2i) -> Rect2i:
	return Rect2i(junction * CityMap.period(), Vector2i(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH))

# ------------------------------------------------------------------- lessons ---

## **The lessons along the route, numbered as the progression numbers them** (gentle-owl #1253):
## (1) get to the park is the walk itself, then (2) a noise source she can pass wide, (3) one with
## less room, (4) crossing the road with no cars about, (5) crossing the road with cars, and (6)
## timing the yeller. Four stand on a lesson street of their own (`lesson_street()`); the two
## crossings are junctions: (4)'s at the start of its street (`crossing_with_no_cars()`), and (5)'s
## the far end of that street, where the line crosses a carriageway again (`_lay_the_line()`).
enum Lesson { NOISE_PASSED_WIDE = 2, NOISE_WITH_LESS_ROOM = 3, CROSSING_WITH_NO_CARS = 4,
		CROSSING_WITH_CARS = 5, TIMING_THE_YELLER = 6 }

## Where none is: a junction for a lesson the route is too short to lay.
const NO_JUNCTION := Vector2i(-1, -1)

## **The lesson street `lesson` stands on**, or null for a crossing or on a route too short for it.
## The streets count back from the last, the park's, which carries no lesson: a field on it would
## reach the park she has not used yet, which no row may (`UnusedCalmRule`). So the yeller is on
## the street before the park's, the crossing with no cars at the start of the street before his,
## the dog walker's street before that and the market stall's before that, and a route of six lesson
## streets leaves its first one empty. *Proposed, not asked for:* the street each lesson takes is
## the builder's reading of the progression on a route whose last street runs along the park.
func lesson_street(lesson: Lesson) -> StreetNetwork.Segment:
	var index := _index_of(lesson)
	return _streets[index] if index >= 0 else null

## **Whether `tile` is on the street `lesson` stands on** (`lesson_street()`): what the director
## asks before it sends lesson (3)'s dog walker. False for a crossing, or on a route too short for
## the lesson.
func is_on_lesson(lesson: Lesson, tile: Vector2i) -> bool:
	var street := lesson_street(lesson)
	return street != null and street.tile_rect().has_point(tile)

## **Whether `tile` is on her way to `lesson`'s street or on it**, going to the park or
## `homeward`: the street before it on that way (the doorstep's, for the first on her way out), the
## junction box she comes onto it by, or the street itself. Where the director asks to send lesson
## (3)'s dog walkers, which may set off before she turns the corner (`way_toward_her_along()`). False
## for a crossing, or on a route too short for it.
func is_coming_to_lesson(lesson: Lesson, tile: Vector2i, homeward := false) -> bool:
	var index := _index_of(lesson)
	if index < 0:
		return false
	if _streets[index].tile_rect().has_point(tile):
		return true
	var box := _box(_junctions[index + 1] if homeward else _junctions[index])
	var before: StreetNetwork.Segment = null
	if homeward:
		before = _streets[index + 1] if index + 1 < _streets.size() else null
	else:
		before = _streets[index - 1] if index > 0 else _home
	return box.has_point(tile) or (before != null and before.tile_rect().has_point(tile))

## **Whether `tile` is on `lesson`'s street or on the route past it toward the park**: its street,
## the junction box she comes onto it by from home, and every lesson street and junction box after
## it. On her walk home the director holds its route bag here until lesson (3)'s street has sent her
## its dog walker (`EventDirector`). False for a crossing, or on a route too short for it.
func lies_toward_the_park(lesson: Lesson, tile: Vector2i) -> bool:
	var index := _index_of(lesson)
	if index < 0:
		return false
	for i in range(index, _streets.size()):
		if _streets[i].tile_rect().has_point(tile):
			return true
	for i in range(index, _junctions.size()):
		if _box(_junctions[i]).has_point(tile):
			return true
	return false

## **The way along the line's sidewalk of `lesson`'s street toward her**, going to the park or
## `homeward`, as two world points down the middle of that sidewalk: the end she has still to come
## to, then the end she comes onto it at. A thing that walks it comes down her sidewalk toward her,
## round the corner she has still to turn, where the line straight on from her has no ground past the
## street's far end (a T, a calm zone, the map's edge). Empty for a crossing, or on a route too short
## for it.
func way_toward_her_along(lesson: Lesson, homeward := false) -> PackedVector2Array:
	var street := lesson_street(lesson)
	if street == null:
		return PackedVector2Array()
	var band := _map.tile_rect_to_world(line_sidewalk(street))
	var middle := band.get_center()
	var half := Vector2(band.size.x * 0.5 - Tuning.TILE_SIZE * 0.5, 0.0) if street.horizontal \
			else Vector2(0.0, band.size.y * 0.5 - Tuning.TILE_SIZE * 0.5)
	var from_home := _map.tile_rect_to_world(_box(arrives_at(street))).get_center()
	var one := middle - half
	var other := middle + half
	var near := one if one.distance_squared_to(from_home) < other.distance_squared_to(from_home) \
			else other
	var far := other if near == one else one
	return PackedVector2Array([near, far]) if homeward else PackedVector2Array([far, near])

## **The sidewalk she walks along `segment`**, a lesson street: the band of its tile rect
## (`Corridor.sidewalk_bands()`) the line keeps to, which the day's tree walks
## (`line_ground()`). An empty rect for a street the route does not run down.
func line_sidewalk(segment: StreetNetwork.Segment) -> Rect2i:
	var index := _streets.find(segment)
	if index < 0:
		return Rect2i()
	return Corridor.sidewalk_bands(segment.tile_rect(), segment.horizontal)[_line()[index]]

## **The sidewalk across the carriageway from the line on `segment`**, a lesson street: where the
## market stall stands, and the one the delivery van shuts. An empty rect for a street the route
## does not run down.
func far_sidewalk(segment: StreetNetwork.Segment) -> Rect2i:
	var index := _streets.find(segment)
	if index < 0:
		return Rect2i()
	return Corridor.sidewalk_bands(segment.tile_rect(), segment.horizontal)[1 - _line()[index]]

## **The junction where lesson (4) is crossed**, at the start of its street: the line arrives there
## on the sidewalk the van shuts just past the box and leaves on the other, so it crosses the
## street's carriageway. `NO_JUNCTION` on a route too short for it.
func crossing_with_no_cars() -> Vector2i:
	var index := _index_of(Lesson.CROSSING_WITH_NO_CARS)
	return _junctions[index] if index >= 0 else NO_JUNCTION

## **The ground past the crossing with no cars**, as tile rects: the sidewalk the line leaves lesson
## (4)'s junction on (`line_sidewalk()` of its street), every lesson street after it, and every
## junction box past that junction, lesson (5)'s at the street's far end first. The sidewalk she
## arrives toward, which the van shuts just past the box, is not on it, nor is the street's
## carriageway: she has not crossed yet. It is where the car-free start lets the cars in
## (`CarFreeStart`), so the lesson and the release read one answer. Empty on a route too short for
## lesson (4).
func ground_past_the_crossing_with_no_cars() -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	var index := _index_of(Lesson.CROSSING_WITH_NO_CARS)
	if index < 0:
		return rects
	rects.append(line_sidewalk(_streets[index]))
	for i in range(index + 1, _streets.size()):
		rects.append(_streets[i].tile_rect())
	for i in range(index + 1, _junctions.size()):
		rects.append(_box(_junctions[i]))
	return rects

## **The junction where she comes onto `segment`**, a lesson street: its end nearer the doorstep
## along the route. `NO_JUNCTION` for a street the route does not run down.
func arrives_at(segment: StreetNetwork.Segment) -> Vector2i:
	var index := _streets.find(segment)
	return _junctions[index] if index >= 0 else NO_JUNCTION

## **Whether `tile` is on the route**: the doorstep's street, a lesson street, either of its
## sidewalks or its carriageway, or one of the junction boxes along it. The director asks it on
## each of her steps on day 1, so it reads the rects rather than building the route's tiles.
func runs_over(tile: Vector2i) -> bool:
	if _home.tile_rect().has_point(tile):
		return true
	for segment in _streets:
		if segment.tile_rect().has_point(tile):
			return true
	for junction in _junctions:
		if _box(junction).has_point(tile):
			return true
	return false

## **Whether `tile` is in the tutorial park**: its own ground.
func has_in_its_park(tile: Vector2i) -> bool:
	return _park_rect.has_point(tile) and Tile.is_calm(_map.tile_at(tile))

## **The line she is meant to walk, as ground**: the sidewalk she walks along each lesson street
## (`line_sidewalk()`) and every junction box the route passes. The day's tree grows the park's
## branch on this alone (`RouteTree`), so the sidewalk the tree walks, which the day's rules keep
## free of bodies (`RouteSidewalkRule`), is the line's, and the far sidewalk is where a lesson's
## row may stand.
func line_ground() -> Dictionary:
	var found := {}
	for segment in _streets:
		for tile in _map.rect_tiles(line_sidewalk(segment)):
			found[tile] = true
	for junction in _junctions:
		for tile in _map.rect_tiles(_box(junction)):
			found[tile] = true
	return found

## The index into `_streets` of the street `lesson` stands on, counted back from the park's; -1
## for a crossing with cars, which is a junction, or on a route too short for it.
func _index_of(lesson: Lesson) -> int:
	if lesson == Lesson.CROSSING_WITH_CARS:
		return -1
	var order: Array[Lesson] = [Lesson.NOISE_PASSED_WIDE, Lesson.NOISE_WITH_LESS_ROOM,
			Lesson.CROSSING_WITH_NO_CARS, Lesson.TIMING_THE_YELLER]
	var index := _streets.size() - 1 - order.size() + order.find(lesson)
	return index if index >= 0 else -1

## The side of each lesson street the line keeps to, in `_streets`' order, as an index into
## `Corridor.sidewalk_bands()` of the street's rect: laid on the first ask (`_lay_the_line()`).
var _sides: Array[int] = []

func _line() -> Array[int]:
	if _sides.size() != _streets.size():
		_sides = _lay_the_line()
	return _sides

## **The line, chosen among every choice of sides**, the route's few streets making that a few
## dozen: on the last street the sidewalk along the park, where the tree's branch reaches it; at
## lesson (4)'s junction a change of side across its street, so the sidewalk she arrives toward is
## the one the van shuts; a carriageway crossed at lesson (5)'s junction where any line crosses one
## there; and, of the rest, the fewest crossings before lesson (4), where crossing is not yet
## taught, then the fewest in all.
func _lay_the_line() -> Array[int]:
	var count := _streets.size()
	var best: Array[int] = []
	if count == 0:
		return best
	var park := _park_side(_streets[count - 1])
	var crossing := _index_of(Lesson.CROSSING_WITH_NO_CARS)
	var best_cost := INF
	for bits in 1 << count:
		var sides: Array[int] = []
		for i in count:
			sides.append((bits >> i) & 1)
		if park >= 0 and sides[count - 1] != park:
			continue
		var cost := _cost_of(sides, crossing)
		if cost < best_cost:
			best_cost = cost
			best = sides
	if best.is_empty():
		best.resize(count)
		best.fill(0)
	return best

## What a choice of `sides` costs (`_lay_the_line()`): `INF` where it does not cross lesson
## (4)'s street at `crossing`'s junction.
func _cost_of(sides: Array[int], crossing: int) -> float:
	var cost := 0.0
	for i in sides.size():
		var junction := _junctions[i]
		var leaving := _corner(_streets[i], sides[i], junction)
		var crossed := 0
		if i == 0:
			crossed = mini(_crossings(junction, _corner(_home, 0, junction), leaving),
					_crossings(junction, _corner(_home, 1, junction), leaving))
		else:
			var arriving := _corner(_streets[i - 1], sides[i - 1], junction)
			crossed = _crossings(junction, arriving, leaving)
			if i == crossing and _across(_streets[i], arriving) == sides[i]:
				return INF
		if i < crossing:
			cost += 10.0 * crossed
		elif i == crossing + 1 and crossed == 0:
			cost += 1000.0
		else:
			cost += crossed
	return cost

## The corner of `junction`'s box where side `side` of `segment`, a street meeting there,
## meets it: `Vector2i(0 west or 1 east, 0 north or 1 south)`.
static func _corner(segment: StreetNetwork.Segment, side: int, junction: Vector2i) -> Vector2i:
	var other := segment.other_end(junction)
	if segment.horizontal:
		return Vector2i(0 if other.x < junction.x else 1, side)
	return Vector2i(side, 0 if other.y < junction.y else 1)

## The side of `segment` a corner of a box it meets is on, across the street.
static func _across(segment: StreetNetwork.Segment, corner: Vector2i) -> int:
	return corner.y if segment.horizontal else corner.x

## How many carriageways she crosses going round `junction`'s box from corner `from` to corner
## `to`, the fewer way round: one for each arm between them that is a street the city has
## (`CityMap.has_street()`), the pavement left of one it does not have crossed for nothing.
func _crossings(junction: Vector2i, from: Vector2i, to: Vector2i) -> int:
	if from == to:
		return 0
	if from.y == to.y:
		return _arm(junction, Vector2i(0, -1 if from.y == 0 else 1))
	if from.x == to.x:
		return _arm(junction, Vector2i(-1 if from.x == 0 else 1, 0))
	var by_row := _crossings(junction, from, Vector2i(to.x, from.y)) \
			+ _crossings(junction, Vector2i(to.x, from.y), to)
	var by_column := _crossings(junction, from, Vector2i(from.x, to.y)) \
			+ _crossings(junction, Vector2i(from.x, to.y), to)
	return mini(by_row, by_column)

## One where the street leaving `junction` toward `direction` is one the city has, else none.
func _arm(junction: Vector2i, direction: Vector2i) -> int:
	for segment in _map.street_network().at_junction(junction):
		if segment.other_end(junction) - junction == direction:
			return 1 if _map.has_street(segment.key()) else 0
	return 0

## The side of `segment` whose sidewalk the park lies along, or -1 where it lies along neither or
## both.
func _park_side(segment: StreetNetwork.Segment) -> int:
	var rect := segment.tile_rect()
	var found := -1
	for side in 2:
		var bands := Corridor.sidewalk_bands(rect, segment.horizontal)
		var band: Rect2i = bands[side]
		var step := (Vector2i.UP if side == 0 else Vector2i.DOWN) if segment.horizontal \
				else (Vector2i.LEFT if side == 0 else Vector2i.RIGHT)
		var outer := band.position + (step if side == 0 else step * band.size)
		var row := Rect2i(outer, Vector2i(band.size.x, 1) if segment.horizontal
				else Vector2i(1, band.size.y))
		if row.intersects(_park_rect):
			if found >= 0:
				return -1
			found = side
	return found

# ------------------------------------------------------------------ choosing ---

## The lesson streets a route of six streets has, the doorstep's not counted.
const LESSON_STREETS := 5

## Day 1's tutorial route on `map`, or null where no route keeps every rule. See the class doc.
## `rows` is the run's catalogue, whose seal rows decide where a side street's mouth is walled.
static func for_city(rows: EventCatalogue, map: CityMap) -> TutorialRoute:
	var chooser := _Chooser.new(rows, map)
	for length: int in [LESSON_STREETS, LESSON_STREETS + 1]:
		var found := chooser.choose(length)
		if found:
			return found
	return null

## The search `for_city()` runs, with what it has learned about each street and junction kept so
## a street is judged once however many candidates reach it.
class _Chooser extends RefCounted:
	var _rows: EventCatalogue
	var _map: CityMap
	var _areas: Array[ClosurePlanner.CalmArea] = []
	var _area_of := {}
	var _home: StreetNetwork.Segment
	var _home_keys := {}
	var _streets := {}
	var _boxes := {}
	var _paths: Array[Array] = []
	## The street trees' footprint, which a seal at a side street's mouth steps past.
	var _trees := {}

	func _init(rows: EventCatalogue, map: CityMap) -> void:
		_rows = rows
		_map = map
		_trees = StreetTrees.footprint_tiles(map)
		_areas = ClosurePlanner.calm_areas(map)
		for index in _areas.size():
			for tile in map.rect_tiles(_areas[index].rect):
				if Tile.is_calm(map.tile_at(tile)):
					_area_of[tile] = index
		_home = ClosurePlanner.home_street(map)
		for segment in map.street_network().around_blocks(
				Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
			_home_keys[segment.key()] = true

	## The first route of `length` lesson streets that keeps every rule, a park or a zone before a
	## square or a courtyard, in the street network's own order; null where none does.
	func choose(length: int) -> TutorialRoute:
		if not _home:
			return null
		_paths = []
		for first: Vector2i in [_home.a, _home.b]:
			var seen := {_home.a: true, _home.b: true}
			var streets: Array[StreetNetwork.Segment] = []
			var junctions: Array[Vector2i] = [first]
			_extend(first, streets, junctions, seen, length)
		for parks_first: bool in [true, false]:
			for path: Array in _paths:
				var found := _accepted(path, parks_first)
				if found:
					return found
		return null

	func _extend(at: Vector2i, streets: Array[StreetNetwork.Segment], junctions: Array[Vector2i],
			seen: Dictionary, length: int) -> void:
		if streets.size() == length:
			_paths.append([streets.duplicate(), junctions.duplicate()])
			return
		for segment in _map.street_network().at_junction(at):
			if segment.key() == _home.key() or not _map.has_street(segment.key()):
				continue
			var next := segment.other_end(at)
			if seen.has(next) or not _street_keeps(segment, streets.size() == length - 1,
					streets.is_empty()):
				continue
			if not streets.is_empty() and not _box_keeps(at):
				continue
			seen[next] = true
			streets.append(segment)
			junctions.append(next)
			_extend(next, streets, junctions, seen, length)
			streets.pop_back()
			junctions.pop_back()
			seen.erase(next)

	## Whether a lesson street keeps the rules it can be judged by alone; the last one borders
	## exactly one calm area, the park, and no earlier one borders any.
	func _street_keeps(segment: StreetNetwork.Segment, last: bool, first: bool) -> bool:
		if _home_keys.has(segment.key()) or _touches_the_main_road(segment, first):
			return false
		var facts := _street_facts(segment)
		if bool(facts["precinct"]) or bool(facts["open"]):
			return false
		var areas: Dictionary = facts["areas"]
		return areas.size() == 1 if last else areas.is_empty()

	## The main road along the street, or at a junction it ends at; the first lesson street's end
	## on the doorstep's street is first-block ground and does not count.
	func _touches_the_main_road(segment: StreetNetwork.Segment, first: bool) -> bool:
		var main := _map.main_road_corridor()
		if main < 0:
			return false
		if not segment.horizontal and segment.a.x == main:
			return true
		for end: Vector2i in [segment.a, segment.b]:
			var on_the_doorstep := end == _home.a or end == _home.b
			if end.x == main and not (first and on_the_doorstep):
				return true
		return false

	## Whether a junction box between two lesson streets opens onto no open ground.
	func _box_keeps(junction: Vector2i) -> bool:
		var border := _box_border(junction)
		return not bool(border["open"]) and (border["areas"] as Dictionary).is_empty()

	## What borders a junction box past the first block, as `_border_of()` answers, with the
	## pavement left of a street the city does not have (`CityMap.has_street()`) taken as part of
	## the box: no seal stands on such a stub and no wall closes an alley opening onto it, so
	## anything walkable past it but its own pavement and the box is a way off the route.
	func _box_border(junction: Vector2i) -> Dictionary:
		if not _boxes.has(junction):
			var box := TutorialRoute._box(junction)
			var border := _border_of(box)
			var past := _border_of_stubs(junction, box)
			(border["areas"] as Dictionary).merge(past["areas"] as Dictionary)
			border["open"] = bool(border["open"]) or bool(past["open"])
			_boxes[junction] = border
		return _boxes[junction]

	## What borders the pavement left of each absent street at `junction` that the box opens onto,
	## from outside that pavement and the box: the calm areas, by index, and whether any other
	## walkable ground does, a through-alley or another street's ground included.
	func _border_of_stubs(junction: Vector2i, box: Rect2i) -> Dictionary:
		var stub := {}
		var queue: Array[Vector2i] = []
		for arm in _map.street_network().at_junction(junction):
			if _map.has_street(arm.key()):
				continue
			var rect := arm.tile_rect()
			for tile in _map.rect_tiles(rect):
				if _map.is_street(tile) and not stub.has(tile) and _beside_rect(tile, box):
					stub[tile] = rect
					queue.append(tile)
		var head := 0
		while head < queue.size():
			var tile := queue[head]
			head += 1
			var rect: Rect2i = stub[tile]
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = tile + offset
				if rect.has_point(next) and not stub.has(next) and _map.is_street(next):
					stub[next] = rect
					queue.append(next)
		var areas := {}
		var open := false
		for tile: Vector2i in stub:
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var beside: Vector2i = tile + offset
				if stub.has(beside) or box.has_point(beside) or not _map.in_bounds(beside) \
						or not Tile.is_walkable(_map.tile_at(beside)):
					continue
				if _area_of.has(beside):
					areas[_area_of[beside]] = true
				else:
					open = true
		return {"areas": areas, "open": open}

	## Whether `tile` stands just outside `rect`, beside one of its edge tiles.
	static func _beside_rect(tile: Vector2i, rect: Rect2i) -> bool:
		for offset: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			if rect.has_point(tile + offset):
				return true
		return false

	func _street_facts(segment: StreetNetwork.Segment) -> Dictionary:
		var key := segment.key()
		if not _streets.has(key):
			var facts := _border_of(segment.tile_rect())
			facts["precinct"] = TutorialRoute.is_a_precinct(_map, segment)
			_streets[key] = facts
		return _streets[key]

	## What borders a rect from outside it, street and through-alley tiles aside: the calm areas,
	## by index, and whether any other open ground does.
	func _border_of(rect: Rect2i) -> Dictionary:
		var areas := {}
		var open := false
		for tile in _map.rect_tiles(rect):
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var beside: Vector2i = tile + offset
				if rect.has_point(beside) or not _map.in_bounds(beside):
					continue
				var type := _map.tile_at(beside)
				if not Tile.is_walkable(type) or _map.is_street(beside):
					continue
				if type == GameEnums.TileType.ALLEY \
						and _map.alley_lots().has(_map.alley_at(beside)):
					continue
				if _area_of.has(beside):
					areas[_area_of[beside]] = true
				else:
					open = true
		return {"areas": areas, "open": open}

	## The route a path stands for when it keeps the rules a whole path keeps, or null.
	func _accepted(path: Array, parks_first: bool) -> TutorialRoute:
		var streets: Array[StreetNetwork.Segment] = []
		streets.assign(path[0])
		var junctions: Array[Vector2i] = []
		junctions.assign(path[1])
		var areas: Dictionary = _street_facts(streets[streets.size() - 1])["areas"]
		var park: int = areas.keys()[0]
		if _is_a_park(_areas[park]) != parks_first:
			return null
		var far := _box_border(junctions[junctions.size() - 1])
		var at_far: Dictionary = far["areas"]
		if bool(far["open"]) or at_far.size() > 1 or (at_far.size() == 1 and not at_far.has(park)):
			return null
		var at_doorstep: Dictionary = _street_facts(_home)["areas"]
		if at_doorstep.has(park):
			return null
		var route := TutorialRoute.new(_map, _home, streets, junctions, _areas[park].block,
				_areas[park].rect)
		if not _mouths_keep(route, park, junctions.slice(junctions.size() - 2)):
			return null
		if not _second_area_reached(route, park):
			return null
		return route

	## Whether every side street's stub past the first block, between the route's junction box and
	## the row its seal stands on (`SealPlanner.tutorial_mouth_stub()`), opens onto no open ground:
	## the stub is a way off the route if a park, a square or a courtyard opens onto it. A
	## through-alley refuses nothing, since the seals wall its mouth there (`alley_mouths()`). The tutorial park
	## may open onto a side street at either end of the last lesson street (`last`): the park
	## borders that street from its first junction on, so she is at the park there anyway.
	func _mouths_keep(route: TutorialRoute, park: int, last: Array[Vector2i]) -> bool:
		for mouth in route.side_street_mouths():
			var segment: StreetNetwork.Segment = mouth[0]
			var at_a: bool = mouth[1]
			var border := _border_of(SealPlanner.tutorial_mouth_stub(_rows, _map, segment, at_a,
					_trees))
			if bool(border["open"]):
				return false
			var areas: Dictionary = border["areas"]
			var junction := segment.a if at_a else segment.b
			if areas.is_empty() or (last.has(junction) and areas.size() == 1 and areas.has(park)):
				continue
			return false
		return true

	func _is_a_park(area: ClosurePlanner.CalmArea) -> bool:
		if _map.calm_lot_blocks(area.block) > 1:
			return true
		for tile in _map.rect_tiles(area.rect):
			var type := _map.tile_at(tile)
			if type == GameEnums.TileType.COURTYARD or type == GameEnums.TileType.QUIET_SQUARE:
				return false
		return true

	## Whether a calm area other than the park is reachable from the doorstep's street and its two
	## junction boxes with the route's kept ground out, the carriageway crossed only in a junction
	## box and the main road walked only across: the ground the day's other branches grow on.
	func _second_area_reached(route: TutorialRoute, park: int) -> bool:
		var blocked := route.kept_ground()
		var sources := _map.rect_tiles(_home.tile_rect())
		for junction: Vector2i in [_home.a, _home.b]:
			sources.append_array(_map.rect_tiles(TutorialRoute._box(junction)))
		var seen := {}
		var queue: Array[Vector2i] = []
		for tile in sources:
			if _map.is_walkable(tile) and not blocked.has(tile):
				seen[tile] = true
				queue.append(tile)
		var main := _map.main_road_corridor()
		var head := 0
		while head < queue.size():
			var tile := queue[head]
			head += 1
			if _area_of.has(tile) and int(_area_of[tile]) != park:
				return true
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = tile + offset
				if seen.has(next) or blocked.has(next) or not _map.in_bounds(next) \
						or not _map.is_walkable(next):
					continue
				if CityMap.junction_at(next) == Vector2i(-1, -1):
					if Tile.is_road(_map.tile_at(next)):
						continue
					if main >= 0 and _map.street_kind_at(true, next) == GameEnums.StreetKind.MAIN:
						continue
				seen[next] = true
				queue.append(next)
		return false

## Whether `segment` is a precinct, read at its middle: the question a lesson street is refused on
## and a side street sealed hard on (`SealPlanner`).
static func is_a_precinct(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	var rect := segment.tile_rect()
	var along: int = rect.get_center().x if segment.horizontal else rect.get_center().y
	var index: int = segment.a.y if segment.horizontal else segment.a.x
	return map.street_kind(not segment.horizontal, index, along) == GameEnums.StreetKind.PEDESTRIAN
