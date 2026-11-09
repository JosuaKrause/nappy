extends RefCounted
## `WalkDraw`, the day's open locations drawn as she walks: every location out of her view within
## `WalkDraw.MUST_DRAW` of her is drawn at once, however many, so none reaches the stream radius
## undrawn; one more, the nearest ahead of her within `WalkDraw.BAND_FAR`, is drawn a tick; a
## location in her view is never drawn; and `draw_within()` draws every location within a radius.
## Run on a bare city's lattice (`CityMap.new()`, every street present, laid out with a corridor
## stand-in), with a stand-in for the draw (`_Draw`) that records which locations it was asked to
## draw and marks each drawn, empty: what a location draws is `LocationDraw`'s, checked in
## `tests/test_location_draw.gd`.
##
## - **A sharp turn draws everything that comes near at once**: standing at a junction, every
##   location within `MUST_DRAW` and out of her view is drawn on the one tick, behind her and to
##   the side included.
## - **Her view is never drawn**: a location she can see stays undrawn.
## - **The band ahead draws one a tick**: of the locations beyond `MUST_DRAW` and within `BAND_FAR`,
##   only the nearest ahead of her heading is drawn on a tick, and none behind her.
## - **`draw_within()` draws all**: every location within the radius, and none beyond it.

## The draw: records each location it is asked to draw and marks it drawn, with nothing in it.
class _Draw extends LocationDraw:
	var asked: Array[Location] = []

	func _init(locations: DayLocations) -> void:
		super(locations, {}, {}, null, {})

	## Overrides LocationDraw.draw.
	func draw(location: Location) -> EventScheduler.Planned:
		asked.append(location)
		location.record(null)
		return null

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
	_test_the_band_ahead_draws_one_a_tick(t)
	_test_draw_within_draws_all_within_the_radius(t)

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

func _test_the_band_ahead_draws_one_a_tick(t) -> void:
	var locations := _laid()
	var draw := _Draw.new(locations)
	var walk := WalkDraw.new(locations, draw)
	var at := _junction()
	var nobody_sees := func(_rect: Rect2) -> bool: return false
	walk.draw_ahead(at, Vector2.RIGHT, nobody_sees)
	var in_band: Array[Location] = []
	for location in draw.asked:
		if _distance(at, _rect_of(location)) > WalkDraw.MUST_DRAW:
			in_band.append(location)
	t.check(in_band.size() == 1, "one location beyond the must-draw radius is drawn on a tick (%d)"
			% in_band.size())
	if in_band.size() == 1:
		t.check(_rect_of(in_band[0]).get_center().x > at.x, "and it is ahead of her heading")
	var before := draw.asked.size()
	walk.draw_ahead(at, Vector2.RIGHT, nobody_sees)
	t.check(draw.asked.size() == before + 1, "the next tick draws the next one ahead (%d)"
			% (draw.asked.size() - before))

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
