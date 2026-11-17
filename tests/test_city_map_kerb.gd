extends RefCounted
## `CityMap.kerb_beside()`: where the kerb runs beside the carriageway lane a point stands in, the
## place a row that spans the street stands its body (`EventDef.stands_at_its_kerb()`, the
## roadblock). It is the lattice's geometry, so it is asked of points on a north-south street at
## tiles x 0..5, an east-west one at y 0..5, and the junction box where they meet, with no map.

## A coordinate inside a block, three tiles past a corridor: ground off the streets.
const OFF_THE_CORRIDOR := Tuning.STREET_WIDTH + 3
const TILE := float(Tuning.TILE_SIZE)

func run(t: TestRunner) -> void:
	_test_a_lane_point_goes_to_its_own_kerb(t)
	_test_a_point_on_a_kerb_stays(t)
	_test_no_kerb_outside_one_corridors_carriageway(t)

## A point in either carriageway lane goes across its street to the kerb on its own side, 64px or
## 128px from the corridor's edge, and stays where it was along the street.
func _test_a_lane_point_goes_to_its_own_kerb(t: TestRunner) -> void:
	var near_kerb := Tuning.SIDEWALK_WIDTH * TILE
	var far_kerb := (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH) * TILE
	for lane: int in [Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH - 1]:
		var kerb := near_kerb if lane * 2 < Tuning.STREET_WIDTH else far_kerb
		var north_south := WorldMap.centre_of(Vector2i(lane, OFF_THE_CORRIDOR)) + Vector2(3.0, 5.0)
		t.check(CityMap.kerb_beside(north_south).is_equal_approx(Vector2(kerb, north_south.y)),
				"a point in the lane at %.0fpx across a north-south street goes to the kerb at %.0fpx"
				% [north_south.x, kerb])
		var east_west := WorldMap.centre_of(Vector2i(OFF_THE_CORRIDOR, lane)) + Vector2(-4.0, 2.0)
		t.check(CityMap.kerb_beside(east_west).is_equal_approx(Vector2(east_west.x, kerb)),
				"a point in the lane at %.0fpx across an east-west street goes to the kerb at %.0fpx"
				% [east_west.y, kerb])

## A point already on either kerb line is where asking again puts it, so a body moved there and
## stood again (`EventInstance.move_to()`) stays.
func _test_a_point_on_a_kerb_stays(t: TestRunner) -> void:
	var along := WorldMap.centre_of(Vector2i(0, OFF_THE_CORRIDOR)).y
	for kerb: float in [Tuning.SIDEWALK_WIDTH * TILE,
			(Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH) * TILE]:
		var on_it := Vector2(kerb, along)
		t.check(CityMap.kerb_beside(on_it) == on_it, "a point on the kerb at %.0fpx stays" % kerb)
		var once := CityMap.kerb_beside(on_it + Vector2(-9.0, 0.0))
		t.check(CityMap.kerb_beside(once) == once,
				"a point 9px short of the kerb at %.0fpx, stood twice, stays where once put it" % kerb)

## No kerb is beside a sidewalk, a junction box (in both corridors at once, with no one kerb) or
## ground off the streets: the point is kept.
func _test_no_kerb_outside_one_corridors_carriageway(t: TestRunner) -> void:
	var sidewalk := WorldMap.centre_of(Vector2i(1, OFF_THE_CORRIDOR))
	t.check(CityMap.kerb_beside(sidewalk) == sidewalk, "a sidewalk point stays")
	var box_middle := WorldMap.centre_of(Vector2i(Tuning.SIDEWALK_WIDTH, Tuning.SIDEWALK_WIDTH))
	t.check(CityMap.kerb_beside(box_middle) == box_middle, "a point in a junction box's middle stays")
	var zebra := WorldMap.centre_of(Vector2i(Tuning.SIDEWALK_WIDTH, 0))
	t.check(CityMap.kerb_beside(zebra) == zebra, "a point on a junction box's zebra stays")
	var block := WorldMap.centre_of(Vector2i(OFF_THE_CORRIDOR, OFF_THE_CORRIDOR))
	t.check(CityMap.kerb_beside(block) == block, "a point off the streets stays")
