extends RefCounted
## `OneSidewalkOpenRule`: no street of her routes has both its sidewalks closed by bodies a draw
## put on them. One interaction each, on a hand-drawn map (`StreetMap.full()`, every block a
## building) under a fake corridor that names the street a route runs along and the streets beside
## it; the bodies are the catalogue's own, stood by hand. The street is the one east of junction (3, 3), tiles 48 to 55 along, its north sidewalk
## rows 42 and 43 and its south one rows 46 and 47.
##
## - **A second body across from the first** is refused anywhere along the street, and a body with
##   nothing across stands.
## - **A roadblock is asked too**: its band takes the sidewalk on its side of the road and the road,
##   read on its kerb, so it is refused across from a stall on the far one and stands alone, and a
##   stall drawn after it is refused across from it; beside a pole on the far sidewalk's outer row
##   it stands, where read at its lane it would close the inner row too. Its guard's catch lies inside its band, so the disc it is read at is
##   its band at every heat: where its guard hunts (heat 4 and 5) it still stands alone.
## - **A street a seal already closes** refuses nothing.
## - **A body in the box at the street's end** reaching its last open sidewalk is refused.
## - **Only her routes' streets**: a street beside the routes and one off them keep their two
##   walls.

const NONE: Array[EventPlan] = []
const EAST := Vector3i(3, 3, 0)
## The street running south from the east street's west junction, beside the routes.
const BESIDE := Vector3i(3, 3, 1)
## A tile of the street's north sidewalk, and the street's other rows.
const NORTH_SIDE := Vector2i(51, 42)
const SOUTH_ROW := 47
const ALONG: Array[int] = [48, 49, 50, 51, 52, 53, 54, 55]

var _map: CityMap
var _corridor: FakeCorridor

func run(t: TestRunner) -> void:
	_map = StreetMap.full()
	_corridor = FakeCorridor.new().set_routes([EAST] as Array[Vector3i], [] as Array[Vector2i],
			[] as Array[Vector2i]).set_beside([BESIDE] as Array[Vector3i])
	_test_a_second_body_across_is_refused(t)
	_test_a_roadblock_keeps_the_far_sidewalk(t)
	_test_a_street_a_seal_closes_refuses_nothing(t)
	_test_a_body_in_the_end_box_is_refused(t)
	_test_only_her_routes_streets_are_asked(t)

## `id` standing at the middle of `tile`.
func _standing(id: String, tile: Vector2i) -> EventPlan:
	return EventPlan.new(EventCatalogue.by_id(id), _map.tile_to_world(tile))

func _rule() -> OneSidewalkOpenRule:
	return OneSidewalkOpenRule.new(_map, _corridor)

func _test_a_second_body_across_is_refused(t: TestRunner) -> void:
	var rule := _rule()
	var first: Array[EventPlan] = [_standing("market_stall", NORTH_SIDE)]
	var refused := 0
	for x in ALONG:
		var tile := Vector2i(x, SOUTH_ROW)
		if not rule.allows(_standing("market_stall", tile), tile, first, first):
			refused += 1
	t.check(refused == ALONG.size(),
			"a second stall across from the first is refused all along the street (%d of %d)"
			% [refused, ALONG.size()])
	var alone := Vector2i(51, SOUTH_ROW)
	t.check(rule.allows(_standing("market_stall", alone), alone, NONE, NONE),
			"a stall with nothing across stands")

func _test_a_roadblock_keeps_the_far_sidewalk(t: TestRunner) -> void:
	var rule := _rule()
	var first: Array[EventPlan] = [_standing("market_stall", NORTH_SIDE)]
	var at := Vector2i(51, 45)
	var roadblock := _standing("roadblock", at)
	t.check(roadblock.obstructs() and roadblock.row().spans_the_street(),
			"the roadblock is a body that spans the street")
	t.check(not rule.allows(roadblock, at, first, first),
			"a roadblock across from a stall is refused: its band closes the other sidewalk")
	t.check(rule.allows(roadblock, at, NONE, NONE),
			"a roadblock alone stands: its band leaves the far sidewalk open")
	var standing: Array[EventPlan] = [roadblock]
	var stall := _standing("market_stall", NORTH_SIDE)
	t.check(not rule.allows(stall, NORTH_SIDE, standing, standing),
			"a stall drawn after the roadblock, on the sidewalk it left open, is refused")
	for level: int in [EventDef.HEAT_HUNTS_LEVEL, Tuning.RESISTANCE_GOAL]:
		var hunting := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), level)
		var hot := EventPlan.new(hunting, _map.tile_to_world(at))
		t.check(hunting.ends_the_day() and rule.allows(hot, at, NONE, NONE),
				"at heat %d, where its guard hunts, a roadblock alone stands: its band is its body" % level)
		var hot_standing: Array[EventPlan] = [hot]
		t.check(not rule.allows(stall, NORTH_SIDE, hot_standing, hot_standing),
				"at heat %d a stall across from it is still refused" % level)
	# **Read where its body stands, on the kerb.** A mast's pole on the far sidewalk's outer row,
	# level with the roadblock, closes that row beside it and not the inner row. The band read on
	# its kerb leaves the inner row's tiles clear past it, so the far sidewalk stays walkable and
	# the roadblock stands; read 16px across at its lane, the same band takes the inner row's
	# tile beside the pole and closes both sidewalks.
	var pole := EventPlan.new(EventCatalogue.by_id("loudspeaker"),
			_map.tile_to_world(Vector2i(at.x, NORTH_SIDE.y)))
	var with_the_pole: Array[EventPlan] = [pole]
	t.check(pole.obstructs() and rule.allows(roadblock, at, with_the_pole, with_the_pole),
			"a roadblock level with a pole on the far sidewalk's outer row stands: read on its "
			+ "kerb, its band leaves the inner row open past the pole")
	for level: int in [EventDef.HEAT_HUNTS_LEVEL, Tuning.RESISTANCE_GOAL]:
		var hot := EventPlan.new(
				EventCatalogue.heated(EventCatalogue.by_id("roadblock"), level),
				_map.tile_to_world(at))
		t.check(rule.allows(hot, at, with_the_pole, with_the_pole),
				"at heat %d the hunting roadblock beside the pole stands too: its guard's catch lies "
				% level + "inside its band, so its band is the disc read")

func _test_a_street_a_seal_closes_refuses_nothing(t: TestRunner) -> void:
	var rule := _rule()
	var seal := _standing("burst_water_main", Vector2i(51, 44))
	seal.stand_as_a_seal()
	var standing: Array[EventPlan] = [seal]
	var at := Vector2i(49, 42)
	t.check(rule.allows(_standing("market_stall", at), at, NONE, standing),
			"a stall on a street a seal already closes stands")

func _test_a_body_in_the_end_box_is_refused(t: TestRunner) -> void:
	var rule := _rule()
	var first: Array[EventPlan] = [_standing("market_stall", NORTH_SIDE)]
	var corner := Vector2i(47, 46)
	t.check(_map.street_network().segment_containing(corner) == null,
			"the corner is in the junction box, on no street")
	t.check(not rule.allows(_standing("barricade", corner), corner, first, first),
			"a barricade in the box reaching the street's last open sidewalk is refused")

func _test_only_her_routes_streets_are_asked(t: TestRunner) -> void:
	for key: Vector3i in [BESIDE, Vector3i(7, 7, 0)]:
		var segment := _map.street_network().by_key(key)
		var view := _corridor.view_of(segment)
		var rect := segment.tile_rect()
		var first_tile := rect.position + (Vector2i(3, 0) if segment.horizontal else Vector2i(0, 3))
		var second_tile := first_tile + (Vector2i(0, rect.size.y - 1) if segment.horizontal
				else Vector2i(rect.size.x - 1, 0))
		var first: Array[EventPlan] = [_standing("market_stall", first_tile)]
		t.check(view != PlacementView.View.ON_THE_ROUTE
				and _rule().allows(_standing("market_stall", second_tile), second_tile, first, first),
				"a street %s keeps its two walls" % ("beside the routes"
				if view == PlacementView.View.ROUTE_ADJACENT else "off the routes"))
