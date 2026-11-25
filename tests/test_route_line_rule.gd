extends RefCounted
## `RouteLineRule`: her line followed from a route's junction box onto the sidewalks she walks to it
## and from it. One interaction each, on a hand-drawn map (`StreetMap.full()`, every block a
## building) round junction (3, 3), whose box is tiles 42 to 47 each way, under a fake corridor that
## names the route's streets, the junction they cross and the tiles they walk; the rows are the
## catalogue's own, stood by hand. The shapes are the free-line probe's
## (`tests/probes/m129_zero_cost_line.gd`), turned onto this junction.
##
## - **The seam:** her route comes along the west street's south sidewalk, crosses the box and goes
##   down the south street's east sidewalk. A leaf blower on the east street's south sidewalk four
##   tiles from the box leaves the south street's sidewalk a free line and the box a free region,
##   which do not touch: refused. One tile further down the street it leaves them touching: allowed.
##   With the south street the only route street at the box, the first is still refused. A stall
##   closing the walked sidewalk between the box and its far end is refused.
## - **A beat on another street:** a man shouting on the east street pacing into the box covers the
##   seam, and is refused with nothing across: the south street's far sidewalk is no way round for
##   a man on another street.
## - **A beat on her own street:** a man shouting on the south street's walked sidewalk, whose lens
##   closes it, is passed on its far sidewalk: allowed with that open; with café tables across it,
##   refused, and the tables are refused where they come second and allowed alone.
## - **A box split in two:** two barricades side by side across the box leave the west street's
##   side and the east street's side free and unjoined: refused; the second alone stands.
## - **Three route streets** stay joined past a barricade at the top of the box, and a barricade on
##   the south street's corner cuts it: refused.
## - **A box no street uses** keeps a free tile: an ice cream van whose field covers it all is
##   refused, a leaf blower beside it stands.
## - **A mouth:** with the north street a park her route crosses from the box, café tables in the
##   box's corner, whose field stops short of the park, close the box tiles the park opens onto:
##   refused; one corner over they stand.
## - **The home street:** with the east street the one the front door opens onto, and her route
##   leaving it down an alley from its south sidewalk, a man shouting on the street south of its
##   east box, pacing into the box, whose lens cuts the alley's mouth off the home street, is
##   refused, though no route runs along the home street and no route crosses either of its boxes;
##   with no home street named he stands, and further down his street he stands.

const NONE: Array[EventPlan] = []
const JUNCTION := Vector2i(3, 3)
const WEST := Vector3i(2, 3, 0)
const EAST := Vector3i(3, 3, 0)
const SOUTH := Vector3i(3, 3, 1)
## The sidewalks the routes walk: the west street's south one, the south street's east one and
## the east street's south one.
const WEST_SOUTH_SIDE := Rect2i(34, 46, 8, 2)
const SOUTH_EAST_SIDE := Rect2i(46, 48, 2, 8)
const EAST_SOUTH_SIDE := Rect2i(48, 46, 8, 2)

var _map: CityMap

func run(t: TestRunner) -> void:
	_map = StreetMap.full()
	_test_a_wide_field_that_cuts_the_seam_is_refused(t)
	_test_a_beat_on_another_street_over_the_seam_is_refused(t)
	_test_a_beat_on_her_own_street_is_passed_on_its_far_sidewalk(t)
	_test_a_box_split_in_two_is_refused(t)
	_test_three_route_streets_stay_joined(t)
	_test_a_box_no_street_uses_keeps_a_free_tile(t)
	_test_the_box_keeps_its_way_into_a_mouth(t)
	_test_the_home_street_is_part_of_her_line(t)

## `id` standing at the middle of `tile`, walking a beat to `to` where one is given.
func _standing(id: String, tile: Vector2i, to := Vector2i(-1, -1)) -> EventPlan:
	var at := _map.tile_to_world(tile)
	var beat := PackedVector2Array()
	if to != Vector2i(-1, -1):
		beat = PackedVector2Array([at, _map.tile_to_world(to)])
	return EventPlan.new(EventCatalogue.by_id(id), at, beat)

## The rule for routes along `streets`, walking `sides` (and `more` tiles off the streets), across
## the junction.
func _rule(streets: Array[Vector3i], sides: Array[Rect2i],
		more: Array[Vector2i] = []) -> RouteLineRule:
	var tiles: Array[Vector2i] = more.duplicate()
	for side in sides:
		for y in range(side.position.y, side.end.y):
			for x in range(side.position.x, side.end.x):
				tiles.append(Vector2i(x, y))
	var corridor := FakeCorridor.new().set_routes(streets, [JUNCTION] as Array[Vector2i], tiles)
	return RouteLineRule.new(_map, corridor)

func _west_to_south() -> RouteLineRule:
	return _rule([WEST, SOUTH] as Array[Vector3i], [WEST_SOUTH_SIDE, SOUTH_EAST_SIDE] as Array[Rect2i])

func _test_a_wide_field_that_cuts_the_seam_is_refused(t: TestRunner) -> void:
	var rule := _west_to_south()
	var at := Vector2i(51, 46)
	var further := Vector2i(52, 46)
	t.check(not rule.allows(_standing("leaf_blower", at), at, NONE, NONE),
			"a leaf blower that leaves the walked sidewalk and the box free but unjoined is refused")
	t.check(rule.allows(_standing("leaf_blower", further), further, NONE, NONE),
			"one tile further down its street it leaves them joined and stands")
	var alone := _rule([SOUTH] as Array[Vector3i], [SOUTH_EAST_SIDE] as Array[Rect2i])
	t.check(not alone.allows(_standing("leaf_blower", at), at, NONE, NONE),
			"with the south street the only route street at the box, it is still refused")
	t.check(alone.allows(_standing("leaf_blower", further), further, NONE, NONE),
			"and one tile further down it stands")
	var middle := Vector2i(46, 51)
	t.check(not rule.allows(_standing("market_stall", middle), middle, NONE, NONE),
			"a stall closing the walked sidewalk between the box and its far end is refused")

func _test_a_beat_on_another_street_over_the_seam_is_refused(t: TestRunner) -> void:
	var rule := _west_to_south()
	var man := _standing("homeless_yeller", Vector2i(49, 46), Vector2i(43, 46))
	t.check(not rule.allows(man, Vector2i(49, 46), NONE, NONE),
			"a man pacing from another street into the box over the seam is refused, nothing across")

func _test_a_beat_on_her_own_street_is_passed_on_its_far_sidewalk(t: TestRunner) -> void:
	var rule := _west_to_south()
	var man := _standing("homeless_yeller", Vector2i(47, 54), Vector2i(47, 46))
	var tables := _standing("cafe_tables", Vector2i(42, 50))
	var with_man: Array[EventPlan] = [man]
	var with_tables: Array[EventPlan] = [tables]
	t.check(rule.allows(man, Vector2i(47, 54), NONE, NONE),
			"a man pacing her walked sidewalk is passed on the far sidewalk, open")
	t.check(not rule.allows(man, Vector2i(47, 54), with_tables, with_tables),
			"with café tables across, he is refused")
	t.check(not rule.allows(tables, Vector2i(42, 50), with_man, with_man),
			"and the tables are refused where they come second")
	t.check(rule.allows(tables, Vector2i(42, 50), NONE, NONE),
			"the tables alone stand on the far sidewalk")

func _test_a_box_split_in_two_is_refused(t: TestRunner) -> void:
	var rule := _rule([WEST, EAST] as Array[Vector3i],
			[WEST_SOUTH_SIDE, EAST_SOUTH_SIDE] as Array[Rect2i])
	var top := _standing("barricade", Vector2i(44, 43))
	var bottom := _standing("barricade", Vector2i(44, 46))
	var with_top: Array[EventPlan] = [top]
	t.check(not rule.allows(bottom, Vector2i(44, 46), with_top, with_top),
			"two barricades across the box, its two route streets' sides free and unjoined, are refused")
	t.check(rule.allows(bottom, Vector2i(44, 46), NONE, NONE), "one alone stands")

func _test_three_route_streets_stay_joined(t: TestRunner) -> void:
	var rule := _rule([WEST, EAST, SOUTH] as Array[Vector3i],
			[WEST_SOUTH_SIDE, EAST_SOUTH_SIDE, SOUTH_EAST_SIDE] as Array[Rect2i])
	t.check(rule.allows(_standing("barricade", Vector2i(44, 43)), Vector2i(44, 43), NONE, NONE),
			"three route streets stay joined past a barricade at the top of the box")
	t.check(not rule.allows(_standing("barricade", Vector2i(47, 47)), Vector2i(47, 47), NONE, NONE),
			"a barricade on the corner the south street opens from cuts it and is refused")

func _test_a_box_no_street_uses_keeps_a_free_tile(t: TestRunner) -> void:
	var rule := _rule([] as Array[Vector3i], [] as Array[Rect2i])
	t.check(not rule.allows(_standing("ice_cream_van", Vector2i(44, 44)), Vector2i(44, 44),
			NONE, NONE), "a field covering the whole box of a route junction is refused")
	t.check(rule.allows(_standing("leaf_blower", Vector2i(51, 46)), Vector2i(51, 46), NONE, NONE),
			"a field covering part of it stands")

func _test_the_box_keeps_its_way_into_a_mouth(t: TestRunner) -> void:
	var map := StreetMap.full()
	var park: Array[Vector2i] = []
	for y in range(34, 42):
		for x in range(42, 48):
			map.set_tile(Vector2i(x, y), GameEnums.TileType.PARK)
			if x >= 46:
				park.append(Vector2i(x, y))
	var corridor := FakeCorridor.new().set_routes([SOUTH] as Array[Vector3i],
			[JUNCTION] as Array[Vector2i], park + _tiles_of(SOUTH_EAST_SIDE))
	var rule := RouteLineRule.new(map, corridor)
	var corner := Vector2i(46, 43)
	var other := Vector2i(43, 43)
	var tables := EventPlan.new(EventCatalogue.by_id("cafe_tables"), map.tile_to_world(corner))
	t.check(tables.distance_from(map.tile_to_world(Vector2i(46, 41))) > tables.row().line_reach(),
			"the tables' field stops short of the park")
	t.check(not rule.allows(tables, corner, NONE, NONE),
			"café tables closing the box tiles the park her route crosses opens onto are refused")
	t.check(rule.allows(EventPlan.new(EventCatalogue.by_id("cafe_tables"), map.tile_to_world(other)),
			other, NONE, NONE), "one corner over they stand")

func _test_the_home_street_is_part_of_her_line(t: TestRunner) -> void:
	var map := StreetMap.full()
	var alley: Array[Vector2i] = []
	for y in range(48, 56):
		for x in range(52, 54):
			map.set_tile(Vector2i(x, y), GameEnums.TileType.ALLEY)
			alley.append(Vector2i(x, y))
	var corridor := FakeCorridor.new().set_routes([] as Array[Vector3i], [] as Array[Vector2i],
			alley).set_home_street(EAST)
	var rule := RouteLineRule.new(map, corridor)
	var at := Vector2i(56, 51)
	var man := EventPlan.new(EventCatalogue.by_id("homeless_yeller"), map.tile_to_world(at),
			PackedVector2Array([map.tile_to_world(at), map.tile_to_world(Vector2i(56, 43))]))
	t.check(man.denies(map.tile_to_world(Vector2i(53, 47)), man.row().line_reach())
			and not man.denies(map.tile_to_world(Vector2i(53, 48)), man.row().line_reach()),
			"his lens covers the home street's sidewalk at the alley's mouth, not the alley")
	t.check(not rule.allows(man, at, NONE, NONE),
			"a man whose lens cuts her route's alley off the home street is refused")
	var nameless := RouteLineRule.new(map, FakeCorridor.new().set_routes(
			[] as Array[Vector3i], [] as Array[Vector2i], alley))
	t.check(nameless.allows(man, at, NONE, NONE), "with no home street named, he stands")
	var further := Vector2i(56, 55)
	var down := EventPlan.new(EventCatalogue.by_id("homeless_yeller"), map.tile_to_world(further),
			PackedVector2Array([map.tile_to_world(further), map.tile_to_world(Vector2i(56, 51))]))
	t.check(rule.allows(down, further, NONE, NONE), "further down his street he stands")

func _tiles_of(rect: Rect2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			tiles.append(Vector2i(x, y))
	return tiles
