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
##   stall drawn after it is refused across from it; beside a poster crew on the far sidewalk's
##   outer row (pinned against the frontage) it stands, where read at its lane it would close the
##   inner row too. Its guard's catch lies inside its band, so the disc it is read at is its band at
##   every heat: where its guard hunts (heat 4 and 5) it still stands alone.
## - **A street a seal already closes** refuses nothing.
## - **A body in the box at the street's end** reaching its last open sidewalk is refused.
## - **Only her routes' streets**: a street beside the routes and one off them keep their two
##   walls.
## - **And the streets kept beside them** (day 1's walk left open on day 2): a street off the
##   routes handed in as kept refuses a second body across from the first.
## - **A body is read where it stands**: a leaf blower drawn on the south sidewalk's outer row
##   stands on the middle of its band, takes both rows, and is refused across from a stall.

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
	_test_a_closing_roadblock_stands_only_off_her_routes(t)
	_test_a_street_a_seal_closes_refuses_nothing(t)
	_test_a_body_in_the_end_box_is_refused(t)
	_test_only_her_routes_streets_are_asked(t)
	_test_a_kept_street_keeps_a_sidewalk(t)
	_test_a_body_is_read_where_it_stands(t)

## `id` standing at the middle of `tile`.
func _standing(id: String, tile: Vector2i) -> EventPlan:
	return EventPlan.new(Shipped.rows().by_id(id), _map.tile_to_world(tile))

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
		var hunting := Shipped.rows().heated(Shipped.rows()
				.by_id("roadblock"), level)
		var hot := EventPlan.new(hunting, _map.tile_to_world(at))
		t.check(hunting.ends_the_day() and rule.allows(hot, at, NONE, NONE),
				"at heat %d, where its guard hunts, a roadblock alone stands: its band is its body" % level)
		var hot_standing: Array[EventPlan] = [hot]
		t.check(not rule.allows(stall, NORTH_SIDE, hot_standing, hot_standing),
				"at heat %d a stall across from it is still refused" % level)
	# **Read where its body stands, on the kerb.** A poster crew on the far sidewalk's outer row
	# (pinned against the frontage, `EventDef.Pavement.AGAINST_THE_BUILDING`, so it stands where it
	# is drawn), level with the roadblock, closes that row beside it and not the inner row. The band
	# read on its kerb leaves the inner row's tiles clear past it, so the far sidewalk stays
	# walkable and the roadblock stands; read 16px across at its lane, the same band takes the inner
	# row's tile beside the crew and closes both sidewalks. An unpinned body there, such as a mast's
	# pole, stands on its band's middle and takes the inner row itself.
	var pole := EventPlan.new(Shipped.rows().by_id("poster_crew"),
			_map.tile_to_world(Vector2i(at.x, NORTH_SIDE.y)))
	var with_the_pole: Array[EventPlan] = [pole]
	t.check(pole.obstructs() and rule.allows(roadblock, at, with_the_pole, with_the_pole),
			"a roadblock level with a poster crew on the far sidewalk's outer row stands: read on "
			+ "its kerb, its band leaves the inner row open past the crew")
	for level: int in [EventDef.HEAT_HUNTS_LEVEL, Tuning.RESISTANCE_GOAL]:
		var hot := EventPlan.new(
				Shipped.rows().heated(Shipped.rows().by_id("roadblock"),
				level), _map.tile_to_world(at))
		t.check(rule.allows(hot, at, with_the_pole, with_the_pole),
				"at heat %d the hunting roadblock beside the crew stands too: its guard's catch lies "
				% level + "inside its band, so its band is the disc read")

## Every row that stands mid street, the closing roadblock among them, takes both sidewalks from the
## street's middle, so on a street of her routes it is refused alone, at any lane: what
## `EventDef.stands_off_the_route()` restates for the bag, held here in step with the rule. On a
## street beside the routes, where no sidewalk is kept, it stands.
func _test_a_closing_roadblock_stands_only_off_her_routes(t: TestRunner) -> void:
	var rule := _rule()
	var asked := 0
	for def in CatalogueRows.every():
		if not def.stands_mid_street():
			continue
		asked += 1
		t.check(def.stands_off_the_route(),
				"%s stands mid street, so the route's bags hold no marble of it" % def.id())
		for row: int in [44, 45]:
			var at := Vector2i(51, row)
			var closing := EventPlan.new(def, _map.tile_to_world(at))
			t.check(closing.obstructs(), "%s is a body that closes its street" % def.id())
			t.check(not rule.allows(closing, at, NONE, NONE),
					"%s alone on her route's street (lane row %d) is refused: its band takes both "
					% [def.id(), row] + "sidewalks")
	t.check(asked > 0, "there were rows that stand mid street to ask (%d)" % asked)
	var beside := _map.street_network().by_key(BESIDE)
	var rect := beside.tile_rect()
	var lane := rect.position + (Vector2i(3, Tuning.SIDEWALK_WIDTH) if beside.horizontal
			else Vector2i(Tuning.SIDEWALK_WIDTH, 3))
	var off := _standing("closing_roadblock", lane)
	t.check(rule.allows(off, lane, NONE, NONE),
			"a closing roadblock on a street beside her routes stands: that street keeps no sidewalk")

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

## The two ends of a street off the routes, one on each sidewalk, three tiles in from its west or
## north end.
func _across(segment: StreetNetwork.Segment) -> Array[Vector2i]:
	var rect := segment.tile_rect()
	var first_tile := rect.position + (Vector2i(3, 0) if segment.horizontal else Vector2i(0, 3))
	var second_tile := first_tile + (Vector2i(0, rect.size.y - 1) if segment.horizontal
			else Vector2i(rect.size.x - 1, 0))
	return [first_tile, second_tile]

## A street off the routes keeps its two walls (`_test_only_her_routes_streets_are_asked`), unless
## it is handed in as kept: day 1's walk on the day that leaves it open.
func _test_a_kept_street_keeps_a_sidewalk(t: TestRunner) -> void:
	var segment := _map.street_network().by_key(Vector3i(7, 7, 0))
	var tiles := _across(segment)
	var first: Array[EventPlan] = [_standing("market_stall", tiles[0])]
	var second := _standing("market_stall", tiles[1])
	t.check(_corridor.view_of(segment) == PlacementView.View.OFF_THE_ROUTE
			and _rule().allows(second, tiles[1], first, first),
			"the street is off the routes, and with nothing kept a second stall across stands")
	var kept: Array[StreetNetwork.Segment] = [segment]
	var keeping := OneSidewalkOpenRule.new(_map, _corridor, kept)
	t.check(not keeping.allows(second, tiles[1], first, first),
			"handed in as kept, the street refuses a second stall across from the first")
	var alone := tiles[1]
	t.check(keeping.allows(second, alone, NONE, NONE),
			"and a stall with nothing across stands there")

## **Read where it stands.** The leaf blower is drawn on the lane tile of the south sidewalk's outer
## row, and stands on the middle of the band (`BodyStance.of_plan()`), half a tile in, where its
## body and hers beside it take both of the band's rows. Read at the lane tile, the inner row
## would stay walkable past it.
func _test_a_body_is_read_where_it_stands(t: TestRunner) -> void:
	var rule := _rule()
	var at := Vector2i(NORTH_SIDE.x, SOUTH_ROW)
	var blower := _standing("leaf_blower", at)
	t.check(blower.obstructs() and BodyStance.of_plan(_map, blower).center() != blower.body_at(),
			"the leaf blower is a body that stands off the lane tile it was drawn on")
	var first: Array[EventPlan] = [_standing("market_stall", NORTH_SIDE)]
	t.check(not rule.allows(blower, at, first, first),
			"a leaf blower on the outer row across from a stall is refused: where it stands, it "
			+ "takes the whole south sidewalk")
	t.check(rule.allows(blower, at, NONE, NONE), "a leaf blower with nothing across stands")
