extends RefCounted
## `OneSidewalkOpenRule`: no street has both its sidewalks closed by bodies a draw put on them. One
## interaction each, on a hand-drawn map (`StreetMap.full()`, every block a building) under a fake
## corridor that names the streets beside the routes; the bodies are the catalogue's own, stood by
## hand. The street is the one east of junction (3, 3), tiles 48 to 55 along, its north sidewalk
## rows 42 and 43 and its south one rows 46 and 47.
##
## - **A second body across from the first** is refused anywhere along the street, and a body with
##   nothing across stands.
## - **A roadblock is never asked**: it spans the street by design.
## - **A street a seal already closes** refuses nothing.
## - **A body in the box at the street's end** reaching its last open sidewalk is refused.
## - **The setting**: near the routes (the game's), a street off the routes keeps its two walls;
##   every street, it does not.

const NONE: Array[EventPlan] = []
const EAST := Vector3i(3, 3, 0)
## A tile of the street's north sidewalk, and the street's other rows.
const NORTH_SIDE := Vector2i(51, 42)
const SOUTH_ROW := 47
const ALONG: Array[int] = [48, 49, 50, 51, 52, 53, 54, 55]

var _map: CityMap
var _corridor: FakeCorridor

func run(t: TestRunner) -> void:
	_map = StreetMap.full()
	_corridor = FakeCorridor.new().set_beside([EAST] as Array[Vector3i])
	_test_a_second_body_across_is_refused(t)
	_test_a_roadblock_is_never_asked(t)
	_test_a_street_a_seal_closes_refuses_nothing(t)
	_test_a_body_in_the_end_box_is_refused(t)
	_test_which_streets_it_covers_is_a_setting(t)

## `id` standing at the middle of `tile`.
func _standing(id: String, tile: Vector2i) -> EventPlan:
	return EventPlan.new(EventCatalogue.by_id(id), _map.tile_to_world(tile))

func _rule(streets: OneSidewalkOpenRule.Streets) -> OneSidewalkOpenRule:
	return OneSidewalkOpenRule.new(_map, _corridor, streets)

func _test_a_second_body_across_is_refused(t: TestRunner) -> void:
	var rule := _rule(OneSidewalkOpenRule.Streets.NEAR_THE_ROUTES)
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

func _test_a_roadblock_is_never_asked(t: TestRunner) -> void:
	var rule := _rule(OneSidewalkOpenRule.Streets.NEAR_THE_ROUTES)
	var first: Array[EventPlan] = [_standing("market_stall", NORTH_SIDE)]
	var at := Vector2i(51, 45)
	var roadblock := _standing("roadblock", at)
	t.check(roadblock.obstructs() and roadblock.row().spans_the_street(),
			"the roadblock is a body that spans the street")
	t.check(rule.allows(roadblock, at, first, first),
			"a roadblock across from a stall stands, though its body closes the other sidewalk")

func _test_a_street_a_seal_closes_refuses_nothing(t: TestRunner) -> void:
	var rule := _rule(OneSidewalkOpenRule.Streets.NEAR_THE_ROUTES)
	var seal := _standing("burst_water_main", Vector2i(51, 44))
	seal.stand_as_a_seal()
	var standing: Array[EventPlan] = [seal]
	var at := Vector2i(49, 42)
	t.check(rule.allows(_standing("market_stall", at), at, NONE, standing),
			"a stall on a street a seal already closes stands")

func _test_a_body_in_the_end_box_is_refused(t: TestRunner) -> void:
	var rule := _rule(OneSidewalkOpenRule.Streets.NEAR_THE_ROUTES)
	var first: Array[EventPlan] = [_standing("market_stall", NORTH_SIDE)]
	var corner := Vector2i(47, 46)
	t.check(_map.street_network().segment_containing(corner) == null,
			"the corner is in the junction box, on no street")
	t.check(not rule.allows(_standing("barricade", corner), corner, first, first),
			"a barricade in the box reaching the street's last open sidewalk is refused")

func _test_which_streets_it_covers_is_a_setting(t: TestRunner) -> void:
	var off := Vector3i(7, 7, 0)
	var segment := _map.street_network().by_key(off)
	t.check(_corridor.view_of(segment) == PlacementView.View.OFF_THE_ROUTE,
			"the street is off the routes")
	var rect := segment.tile_rect()
	var north := Vector2i(rect.position.x + 3, rect.position.y)
	var south := Vector2i(rect.position.x + 3, rect.end.y - 1)
	var first: Array[EventPlan] = [_standing("market_stall", north)]
	var second := _standing("market_stall", south)
	t.check(_rule(OneSidewalkOpenRule.Streets.NEAR_THE_ROUTES).allows(second, south, first, first),
			"near the routes, a street off them keeps its two walls")
	t.check(not _rule(OneSidewalkOpenRule.Streets.EVERY_STREET).allows(second, south, first, first),
			"every street, the second wall is refused there too")
