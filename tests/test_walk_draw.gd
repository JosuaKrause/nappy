extends RefCounted
## `WalkDraw`, the day's open locations drawn as she walks: every location out of her view within
## `WalkDraw.MUST_DRAW` of her is drawn whole at once, however many, so none reaches the stream
## radius undrawn; the nearest ahead of her within `WalkDraw.BAND_FAR` is drawn a marble ask a tick;
## a location in her view is never drawn; and `draw_within()` draws every location within a radius.
## Run on a bare city's lattice (`CityMap.new()`, every street present, laid out with a corridor
## stand-in), with a stand-in for the draw (`_Draw`) whose every draw takes `_Draw.ASKS` asks,
## records which locations it was asked to draw and marks each drawn, empty: what a location draws
## is `LocationDraw`'s, checked in `tests/test_location_draw.gd`.
##
## - **A sharp turn draws everything that comes near at once**: standing at a junction, every
##   location within `MUST_DRAW` and out of her view is drawn whole on the one tick, behind her and
##   to the side included, and `forced()` counts each.
## - **Her view is never drawn**: a location she can see stays undrawn, and a band draw under way
##   asks nothing while she can see its location.
## - **The band ahead asks once a tick**: of the locations beyond `MUST_DRAW` and within `BAND_FAR`,
##   only the nearest ahead of her heading is begun, one ask a tick; it holds nothing and is handed
##   to nobody until its last ask, and the next is begun only then.
## - **A band draw that comes within `MUST_DRAW` is finished whole**: the draw under way is ended
##   that tick, not begun again.
## - **A sidewalk is drawn after its section**: of every sidewalk a tick or `draw_within()` draws,
##   its section was drawn before it; and a sidewalk whose section she can see waits for it.
## - **`draw_within()` draws all**: every location within the radius, and none beyond it.

## The draw: every draw takes `ASKS` asks; records each location it begins, and each it ends, and
## marks it drawn with nothing in it.
class _Draw extends LocationDraw:
	const ASKS := 3
	var begun: Array[Location] = []
	var asked: Array[Location] = []

	func _init(locations: DayLocations) -> void:
		super(locations, {}, {}, null, {})

	## Overrides LocationDraw.draw.
	func draw(location: Location) -> EventScheduler.Planned:
		return finish(begin(location))

	## Overrides LocationDraw.begin.
	func begin(location: Location) -> LocationDraw.Asking:
		begun.append(location)
		return _Asking.new(location)

	## Overrides LocationDraw.finish.
	func finish(asking: LocationDraw.Asking) -> EventScheduler.Planned:
		while not asking.step():
			pass
		asked.append(asking.location)
		asking.location.record(null)
		return null

## A draw under way that ends on its `_Draw.ASKS`th ask.
class _Asking extends LocationDraw.Asking:
	var asks := 0

	## Overrides LocationDraw.Asking.step.
	func step() -> bool:
		asks += 1
		return asks >= _Draw.ASKS

## The corridor's view of every street: off the route.
class _Views extends Corridor:
	## Overrides Corridor.view_of.
	func view_of(_segment: StreetNetwork.Segment) -> int:
		return PlacementView.View.OFF_THE_ROUTE

	## Overrides Corridor.view_of_ground.
	func view_of_ground(_tiles: Rect2i) -> int:
		return PlacementView.View.OFF_THE_ROUTE

func run(t) -> void:
	_test_a_sharp_turn_draws_everything_that_comes_near_at_once(t)
	_test_her_view_is_never_drawn(t)
	_test_the_band_ahead_asks_once_a_tick(t)
	_test_a_band_draw_that_comes_near_is_finished_whole(t)
	_test_draw_within_draws_all_within_the_radius(t)
	_test_a_sidewalk_is_drawn_after_its_section(t)

## Where she stands: the middle of a junction box in the middle of the bare city.
func _junction() -> Vector2:
	var box := Vector2i(4, 4) * CityMap.period()
	return (Vector2(box) + Vector2.ONE * Tuning.STREET_WIDTH * 0.5) * Tuning.TILE_SIZE

func _laid() -> DayLocations:
	return DayLocations.lay_out(CityMap.new(), _Views.new())

static func _rect_of(location: Location) -> Rect2:
	return Rect2(Vector2(location.tiles().position) * Tuning.TILE_SIZE,
			Vector2(location.tiles().size) * Tuning.TILE_SIZE)

static func _distance(at: Vector2, rect: Rect2) -> float:
	return at.distance_to(Vector2(clampf(at.x, rect.position.x, rect.end.x),
			clampf(at.y, rect.position.y, rect.end.y)))

func _test_a_sharp_turn_draws_everything_that_comes_near_at_once(t) -> void:
	var locations := _laid()
	var draw := _Draw.new(locations)
	var walk := WalkDraw.new(locations, draw)
	var at := _junction()
	var nobody_sees := func(_rect: Rect2) -> bool: return false
	walk.draw_ahead(at, Vector2.RIGHT, nobody_sees)
	var near := 0
	var left := 0
	for location in locations.open_locations() + _drawn_of(draw):
		if _distance(at, _rect_of(location)) <= WalkDraw.MUST_DRAW:
			near += 1
			if not location.is_drawn():
				left += 1
	t.check(near > 20, "many locations are within the must-draw radius of a junction (%d)" % near)
	t.check(left == 0, "every one of them is drawn on the one tick, behind her and beside her too (%d left)"
			% left)
	t.check(walk.forced() == near, "and each is counted as forced (%d of %d)" % [walk.forced(), near])

func _test_her_view_is_never_drawn(t) -> void:
	var locations := _laid()
	var draw := _Draw.new(locations)
	var walk := WalkDraw.new(locations, draw)
	var at := _junction()
	var view := Rect2(at - Vector2(400, 300), Vector2(800, 600))
	var sees := func(rect: Rect2) -> bool: return view.intersects(rect)
	walk.draw_ahead(at, Vector2.RIGHT, sees)
	var seen_drawn := 0
	var seen := 0
	for location in locations.open_locations() + _drawn_of(draw):
		if view.intersects(_rect_of(location)):
			seen += 1
			if location.is_drawn():
				seen_drawn += 1
	t.check(seen > 0 and seen_drawn == 0, "no location in her view is drawn (%d of %d)" % [seen_drawn, seen])

func _test_the_band_ahead_asks_once_a_tick(t) -> void:
	var locations := _laid()
	var draw := _Draw.new(locations)
	var walk := WalkDraw.new(locations, draw)
	var at := _junction()
	var nobody_sees := func(_rect: Rect2) -> bool: return false
	var handed := walk.draw_ahead(at, Vector2.RIGHT, nobody_sees).size()
	var near := draw.asked.size()
	var band := _beyond_must_draw(at, draw.begun)
	t.check(band.size() == 1, "one location beyond the must-draw radius is begun on a tick (%d)" % band.size())
	if band.size() != 1:
		return
	var first := band[0]
	t.check(_rect_of(first).get_center().x > at.x, "and it is ahead of her heading")
	t.check(not first.is_drawn() and not draw.asked.has(first) and handed == 0,
			"a draw under way holds nothing and is handed to nobody (%d handed)" % handed)
	for tick in _Draw.ASKS - 1:
		walk.draw_ahead(at, Vector2.RIGHT, nobody_sees)
	t.check(first.is_drawn() and draw.asked.size() == near + 1,
			"its last ask, %d ticks on, ends it (%d ended)" % [_Draw.ASKS, draw.asked.size() - near])
	t.check(_beyond_must_draw(at, draw.begun).size() == 1, "and nothing else is begun before it ends")
	walk.draw_ahead(at, Vector2.RIGHT, nobody_sees)
	t.check(_beyond_must_draw(at, draw.begun).size() == 2, "the tick after begins the next one ahead")
	t.check(walk.forced() == near, "no band draw was forced (%d forced, %d near)" % [walk.forced(), near])

	# A band draw under way asks nothing while she can see its location.
	var paused := _laid()
	var paused_draw := _Draw.new(paused)
	var paused_walk := WalkDraw.new(paused, paused_draw)
	paused_walk.draw_ahead(at, Vector2.RIGHT, nobody_sees)
	var under_way := _beyond_must_draw(at, paused_draw.begun)
	if under_way.size() != 1:
		t.check(false, "one band draw is begun on the paused city (%d)" % under_way.size())
		return
	var its_rect := _rect_of(under_way[0])
	var sees_it := func(rect: Rect2) -> bool: return rect == its_rect
	for tick in _Draw.ASKS * 2:
		paused_walk.draw_ahead(at, Vector2.RIGHT, sees_it)
	t.check(not under_way[0].is_drawn() and _beyond_must_draw(at, paused_draw.begun).size() == 1,
			"a band draw under way waits while she can see its location, and nothing else is begun")

func _test_a_band_draw_that_comes_near_is_finished_whole(t) -> void:
	var locations := _laid()
	var draw := _Draw.new(locations)
	var walk := WalkDraw.new(locations, draw)
	var at := _junction()
	var nobody_sees := func(_rect: Rect2) -> bool: return false
	walk.draw_ahead(at, Vector2.RIGHT, nobody_sees)
	var band := _beyond_must_draw(at, draw.begun)
	if band.size() != 1:
		t.check(false, "one band draw is begun (%d)" % band.size())
		return
	var target := band[0]
	var forced_before := walk.forced()
	var there := _rect_of(target).get_center()
	walk.draw_ahead(there, Vector2.RIGHT, nobody_sees)
	t.check(target.is_drawn(), "a band draw under way that comes within the must-draw radius ends that tick")
	t.check(draw.begun.count(target) == 1, "and is ended, not begun again (%d begun)" % draw.begun.count(target))
	t.check(walk.forced() > forced_before, "and counts as forced")

## Of `drawn`, those beyond `WalkDraw.MUST_DRAW` of `at`.
static func _beyond_must_draw(at: Vector2, drawn: Array[Location]) -> Array[Location]:
	var beyond: Array[Location] = []
	for location in drawn:
		if _distance(at, _rect_of(location)) > WalkDraw.MUST_DRAW:
			beyond.append(location)
	return beyond

func _test_draw_within_draws_all_within_the_radius(t) -> void:
	var locations := _laid()
	var draw := _Draw.new(locations)
	var walk := WalkDraw.new(locations, draw)
	var at := _junction()
	walk.draw_within(at, 1500.0)
	var inside_left := 0
	var outside_drawn := 0
	for location in locations.open_locations() + _drawn_of(draw):
		var distance := _distance(at, _rect_of(location))
		if distance <= 1500.0 and not location.is_drawn():
			inside_left += 1
		if distance > 1500.0 and location.is_drawn():
			outside_drawn += 1
	t.check(inside_left == 0 and outside_drawn == 0,
			"draw_within draws every location within its radius and none beyond (%d left, %d beyond)"
			% [inside_left, outside_drawn])

## The locations `draw` has drawn, which `DayLocations.open_locations()` no longer lists.
func _drawn_of(draw: _Draw) -> Array[Location]:
	return draw.asked

func _test_a_sidewalk_is_drawn_after_its_section(t) -> void:
	var locations := _laid()
	var draw := _Draw.new(locations)
	var walk := WalkDraw.new(locations, draw)
	var at := _junction()
	var nobody_sees := func(_rect: Rect2) -> bool: return false
	for _tick in 40:
		walk.draw_ahead(at, Vector2.RIGHT, nobody_sees)
	walk.draw_within(at + Vector2(1600, 0), 600.0)
	var sidewalks := 0
	var before_its_section := 0
	for i in draw.asked.size():
		var sidewalk := draw.asked[i]
		if sidewalk.kind() != Location.Kind.SIDEWALK:
			continue
		sidewalks += 1
		var section := _section_of(sidewalk, draw.asked)
		if section == null or draw.asked.find(section) > i:
			before_its_section += 1
	t.check(sidewalks > 20 and before_its_section == 0,
			"every sidewalk drawn comes after its section (%d of %d before it)" % [before_its_section, sidewalks])

	# A sidewalk whose section she can see waits for her to look away.
	var seen := _laid()
	var seen_draw := _Draw.new(seen)
	var seen_walk := WalkDraw.new(seen, seen_draw)
	var sections := {}
	for location in seen.open_locations():
		if location.kind() == Location.Kind.SECTION:
			sections[_rect_of(location)] = true
	var sees_the_sections := func(rect: Rect2) -> bool: return sections.has(rect)
	seen_walk.draw_ahead(at, Vector2.RIGHT, sees_the_sections)
	var sidewalks_drawn := 0
	for location in seen_draw.asked:
		if location.kind() == Location.Kind.SIDEWALK:
			sidewalks_drawn += 1
	t.check(sidewalks_drawn == 0, "with every section in her view, no sidewalk is drawn (%d)" % sidewalks_drawn)

## The section `sidewalk` lies in, of `drawn`, or null.
static func _section_of(sidewalk: Location, drawn: Array[Location]) -> Location:
	for location in drawn:
		if location.kind() == Location.Kind.SECTION and sidewalk.shares_a_section_with(location):
			return location
	return null
