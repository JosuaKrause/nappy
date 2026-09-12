extends RefCounted
## How a car gets round a corner.
##
## The traffic suite next door asks what the crowd *is* — where it stands, how loud it is, whether
## it queues. This one asks about the one move a car makes that is neither of those: a turn, which
## used to be a swap of the axis and the lane between two frames and is now a planned arc. So every
## check here is about the **path**: that it is continuous, that the ground under it is road the car
## may be on, that it ends on the lane it was aiming at, and that nothing else in the traffic is
## broken by a car that is briefly on neither axis.
##
## **Driven through `Crowd.step()`**, never by walking the agents by hand: the separation pass and
## the index rebuild are half of what a turning car has to stay honest with, and a rig that skips
## them is not running the traffic the game runs. The scenarios build their own cars rather than
## taking whichever ones a day happens to produce — a turn is a rare event in a random minute, and
## a test that waits for one is a test that usually asserts nothing.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

var _city: City
var _junction := Vector2i(-1, -1)

## What watching a car through a manoeuvre measures.
class Manoeuvre extends RefCounted:
	## The furthest it moved between two frames, and the sharpest its heading turned, in px and
	## radians. Both are the whole of "continuous" as a rig can see it.
	var worst_step := 0.0
	var worst_swing := 0.0
	## Frames on which some part of the swept strike box was on ground a car may not drive over.
	var off_the_road := 0
	var turned := false
	var finished := false
	## How long the whole manoeuvre took, from committing to landing.
	var seconds := 0.0
	## The widest the actual travel direction and the reported heading ever disagreed, in radians.
	var worst_drift := 0.0

func run(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_junction = _plain_junction()
	t.check(_junction.x >= 0, "this city has an ordinary four-way junction to turn at")
	if _junction.x < 0:
		_city.free()
		return

	_test_the_turn_constants_hold_their_relationships(t)
	_test_a_car_turns_into_each_arm_from_every_approach(t)
	_test_a_car_turns_round_when_every_arm_is_shut(t)
	_test_a_car_turns_round_in_the_street_short_of_a_closure(t)
	_test_a_plugged_arm_is_refused_rather_than_driven_into(t)
	_test_the_heading_is_the_direction_it_is_actually_travelling(t)
	_test_a_queue_keeps_its_distance_behind_a_turning_car(t)
	_test_two_cars_arriving_together_do_not_share_the_box(t)
	_test_a_turning_car_still_gives_way_at_a_zebra(t)
	_test_a_red_light_still_holds_a_car_that_is_turning(t)
	_test_a_car_turns_at_the_last_junction_before_the_boundary(t)

	_city.free()

# ------------------------------------------------------------------ the numbers ---

## The two constants a turn introduces, stated as the relationships that make them right rather
## than as the values — see `Tuning.CAR_TURN_SPEED`.
func _test_the_turn_constants_hold_their_relationships(t) -> void:
	var lateral := Tuning.CAR_TURN_SPEED * Tuning.CAR_TURN_SPEED / Tuning.CAR_TURN_RADIUS_MIN
	t.check(lateral <= Tuning.CAR_BRAKE,
			"a car is never asked to corner harder than it can brake (%.0f against %.0f px/s²)"
			% [lateral, Tuning.CAR_BRAKE])
	t.check(Tuning.CAR_TURN_SPEED > Tuning.CAR_STRIKE_MIN_SPEED,
			"a car taking a corner is still fast enough to be lethal, so a junction is not a safe "
			+ "place to stand (%.0f over %.0f)"
			% [Tuning.CAR_TURN_SPEED, Tuning.CAR_STRIKE_MIN_SPEED])
	t.check(Tuning.CAR_TURN_SPEED < Tuning.CAR_SPEED.x,
			"and a turn always slows the slowest car down rather than speeding it up")
	t.check(Tuning.CAR_TURN_RADIUS_MIN > Tuning.CAR_STRIKE_HALF_WIDTH,
			"the tightest arc is wider than the body's own half width, so no turn is a pivot "
			+ "(%.0f over %.0f)" % [Tuning.CAR_TURN_RADIUS_MIN, Tuning.CAR_STRIKE_HALF_WIDTH])
	# The far-side arm is three times the radius of the near-side one, and both are fixed by where
	# the lanes are. If a lane ever moves, these move with it rather than being re-chosen.
	var near := absf(CrowdLanes.lane_centre(0, CrowdLanes.ROAD_OFFSETS[0])
			- CarTurn.carriageway_edge(0, 1.0))
	var far := absf(CrowdLanes.lane_centre(0, CrowdLanes.ROAD_OFFSETS[1])
			- CarTurn.carriageway_edge(0, 1.0))
	t.check(near >= Tuning.CAR_TURN_RADIUS_MIN and far > near,
			"the near-side arm is the tightest arc the lanes allow and the far-side one is wider "
			+ "(%.0f and %.0f px)" % [near, far])

# --------------------------------------------------------------------- the turns ---

## The quarter turn, from all four approaches and into both arms.
##
## Each run shuts the way ahead and one of the two arms, so the arm the car takes is the one being
## asked about rather than one of two it might have rolled. What is checked is the same four things
## every time: the path never jumped, the body never left the carriageway, it landed on the lane it
## was turning into and pointing along it, and it got there.
func _test_a_car_turns_into_each_arm_from_every_approach(t) -> void:
	for vertical in [true, false]:
		for direction in [1.0, -1.0]:
			for turning in [1.0, -1.0]:
				_one_arm(t, vertical, direction, turning)

func _one_arm(t, vertical: bool, direction: float, turning: float) -> void:
	_clear_the_holds()
	_hold(_ahead_of(vertical, direction))
	_hold(_arm(not vertical, -turning))
	var car := _place_a_car(vertical, direction)
	var watched := _watch(car, 8.0)
	var going := ""
	if vertical:
		going = "southbound" if direction > 0.0 else "northbound"
	else:
		going = "eastbound" if direction > 0.0 else "westbound"
	var name := "%s turning toward %s" % [going,
			("south" if turning > 0.0 else "north") if not vertical
			else ("east" if turning > 0.0 else "west")]
	t.check(watched.turned and watched.finished,
			"%s: the car takes the open arm and completes the turn (%.2fs)" % [name, watched.seconds])
	_check_the_path(t, watched, name)
	t.check(car.travelling_vertically() == not vertical and car._direction == turning,
			"%s: it comes out on the crossing axis pointing the way it turned" % name)
	t.check(car._lane == CrowdLanes.road_lane(not vertical, turning),
			"%s: and in the lane on its own right for the way it is now pointing" % name)
	var landed_on: float = car.position.x if car.travelling_vertically() else car.position.y
	var off := absf(landed_on - CrowdLanes.lane_centre(car._corridor, car._lane))
	t.check(off < 1.0, "%s: on the exit lane's own centre line, not steering back to it (%.1fpx off)"
			% [name, off])

## The about-face, from all four approaches, where the junction is boxed in on three sides. The
## crossing street's own carriageway is the room a half turn needs, so this one is taken in the
## middle of the box and stays on the road for the whole of it.
func _test_a_car_turns_round_when_every_arm_is_shut(t) -> void:
	for vertical in [true, false]:
		for direction in [1.0, -1.0]:
			_clear_the_holds()
			_hold(_ahead_of(vertical, direction))
			_hold(_arm(not vertical, 1.0))
			_hold(_arm(not vertical, -1.0))
			var car := _place_a_car(vertical, direction)
			var lane_before := car._lane
			var watched := _watch(car, 10.0)
			var name := "%s%s" % ["+" if direction > 0.0 else "-", "y" if vertical else "x"]
			t.check(watched.turned and watched.finished,
					"boxed in on three sides (%s): the car turns round and completes it (%.2fs)"
					% [name, watched.seconds])
			_check_the_path(t, watched, "about-face " + name)
			t.check(car.travelling_vertically() == vertical and car._direction == -direction,
					"about-face %s: it comes out on the same street pointing back" % name)
			t.check(car._lane != lane_before
					and car._lane == CrowdLanes.road_lane(vertical, -direction),
					"about-face %s: and in the other lane, which is the one on its own right now"
					% name)

## The about-face with no junction to take it in: a closure across the mouth of the street, so the
## car has to turn round short of it. **This is the one manoeuvre whose swept body crosses a kerb**
## — a half turn between two lanes 32px apart is a 16px arc and the body's corners reach 40px from
## the centre of it — so the road check here is the looser one. Nothing else is relaxed: the closure
## itself is still refused, which is what "never drive through a barrier" means.
func _test_a_car_turns_round_in_the_street_short_of_a_closure(t) -> void:
	_clear_the_holds()
	var band := _junction.y * CityMap.period()
	var closed: Array[Vector2i] = []
	for offset in range(0, Tuning.STREET_WIDTH):
		for lane in CrowdLanes.ROAD_OFFSETS:
			closed.append(Vector2i(_junction.x * CityMap.period() + lane, band + offset))
	for tile in closed:
		_city.map.closed_tiles[tile] = true
	var car := _place_a_car(true, 1.0)
	var watched := _watch(car, 12.0, true)
	t.check(watched.turned and watched.finished,
			"a car meeting a closed junction turns round in the street (%.2fs)" % watched.seconds)
	_check_the_path(t, watched, "street about-face")
	t.check(car._direction == -1.0 and car.travelling_vertically(),
			"and comes out heading back the way it came")
	# That it never reached the closure is `off_the_road` above: closed ground fails the same check
	# the pavement does, which is what *never drive through a barrier* means here.
	for tile in closed:
		_city.map.closed_tiles.erase(tile)

## An arm with a plug two tiles in is refused rather than turned into.
##
## The probe that picks an arm fires a single point seven tiles out and looks straight past a short
## plug — harmless when a car could reverse its heading wherever it stood, and a car parked in a
## cul-de-sac for the rest of the day now. What refuses it is the room the *exit* has to leave in.
func _test_a_plugged_arm_is_refused_rather_than_driven_into(t) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	_hold(_arm(false, -1.0))
	var plug: Array[Vector2i] = []
	var band := _junction.x * CityMap.period()
	for offset in range(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH + 2):
		for lane in CrowdLanes.ROAD_OFFSETS:
			plug.append(Vector2i(band + offset, _junction.y * CityMap.period() + lane))
	for tile in plug:
		_city.map.closed_tiles[tile] = true
	var car := _place_a_car(true, 1.0)
	var watched := _watch(car, 12.0, true)
	var inside := 0
	for tile in plug:
		if _city.map.world_to_tile(car.position) == tile:
			inside += 1
	t.check(inside == 0, "the car never ends up inside the plug it could not have left")
	t.check(watched.turned, "it still makes a manoeuvre rather than standing there")
	t.check(car._direction == -1.0 or not car.travelling_vertically(),
			"and leaves by the arm that is open or by the way it came")
	_check_the_path(t, watched, "plugged arm")
	for tile in plug:
		_city.map.closed_tiles.erase(tile)

## `heading()` is what everything downstream of a car reads — the strike box, the horn, the shadow
## and, once it is bound, the picture. So it has to be the direction the car is **actually** going,
## not the axis it belongs to, on every frame of a turn.
func _test_the_heading_is_the_direction_it_is_actually_travelling(t) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	_hold(_arm(false, -1.0))
	var car := _place_a_car(true, 1.0)
	var watched := _watch(car, 8.0)
	t.check(watched.turned, "the car turned, so there was a curve to measure")
	t.check(watched.worst_drift < deg_to_rad(6.0),
			"the reported heading is the direction it actually moved, all through the curve "
			+ "(worst %.1f°)" % rad_to_deg(watched.worst_drift))

# ------------------------------------------------------- the rest of the traffic ---

## A turning car is still in the queue it came from, and the queue behind it still keeps a car's
## length. Nothing may be teleported to make that true: the separation pass refuses to slide a car
## that is on an arc, so what gives is the follower.
func _test_a_queue_keeps_its_distance_behind_a_turning_car(t) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	_hold(_arm(false, -1.0))
	var leader := _place_a_car(true, 1.0)
	var followers: Array[CrowdAgent] = []
	for i in 2:
		var follower := _place_a_car(true, 1.0)
		follower.position.y = leader.position.y - float(i + 1) * Tuning.CAR_GAP_MIN * 1.6
		followers.append(follower)
	var closest := INF
	var worst_jump := 0.0
	var turned := false
	for frame in int(round(10.0 / STEP)):
		var before: Array[Vector2] = []
		for car in followers:
			before.append(car.position)
		_city.crowd.set_focus(leader.position)
		_city.crowd.step(STEP)
		turned = turned or leader.is_turning()
		for i in followers.size():
			worst_jump = maxf(worst_jump, before[i].distance_to(followers[i].position))
		for i in followers.size():
			for j in range(i + 1, followers.size()):
				closest = minf(closest, followers[i].position.distance_to(followers[j].position))
	t.check(turned, "the leader turned while the queue was behind it")
	t.check(closest >= Tuning.CAR_STRIKE_HALF_LENGTH * 2.0,
			"no two cars in the queue are inside each other (closest %.0fpx)" % closest)
	t.check(worst_jump <= Tuning.CAR_GAP_MIN,
			"and nobody is moved more than its own length in a frame (worst %.0fpx)" % worst_jump)
	var moving := 0
	for car in followers:
		if car.speed() > Tuning.CAR_STOPPED_SPEED:
			moving += 1
	t.check(moving > 0, "the queue is not deadlocked behind the turn")

## Two cars at one box, one turning across the other's path. The box is rationed, so the turn holds
## the whole of it until its tail is clear — and what the crossing car does is wait, not arrive.
func _test_two_cars_arriving_together_do_not_share_the_box(t) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	_hold(_arm(false, -1.0))
	var turner := _place_a_car(true, 1.0)
	var crossing := _place_a_car(false, 1.0)
	# Level with each other, so the box is decided rather than queued for.
	crossing.position.x = float(_junction.x * CityMap.period() * Tuning.TILE_SIZE) \
			- (float(_junction.y * CityMap.period() * Tuning.TILE_SIZE) - turner.position.y)
	var closest := INF
	var turned := false
	for frame in int(round(12.0 / STEP)):
		_city.crowd.set_focus(turner.position)
		_city.crowd.step(STEP)
		turned = turned or turner.is_turning()
		closest = minf(closest, turner.position.distance_to(crossing.position))
	t.check(turned, "the turning car took the box")
	t.check(closest > Tuning.CAR_STRIKE_HALF_LENGTH + Tuning.CAR_STRIKE_HALF_WIDTH,
			"and the crossing car never got inside it (closest %.0fpx)" % closest)
	t.check(turner.speed() > Tuning.CAR_STOPPED_SPEED
			or crossing.speed() > Tuning.CAR_STOPPED_SPEED,
			"neither of them is left waiting for the other for ever")

## The zebra is honoured on the way into a turn. A car brakes for somebody at the crossing, and the
## turn it has planned does not let it through early.
func _test_a_turning_car_still_gives_way_at_a_zebra(t) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	_hold(_arm(false, -1.0))
	var car := _place_a_car(true, 1.0)
	var waiting := _kerbside_of(car)
	var stopped := false
	var on_the_paint := 0
	for frame in int(round(6.0 / STEP)):
		_city.crowd.set_focus(car.position)
		car.pedestrian_ahead = waiting
		_city.crowd.step(STEP)
		if car.speed() < 1.0:
			stopped = true
		if stopped and _city.map.tile_type_at_world(car.position) \
				== GameEnums.TileType.CROSSING:
			on_the_paint += 1
	t.check(stopped, "a car with a turn planned still stops for somebody at the zebra")
	t.check(on_the_paint == 0, "and stops short of the paint rather than on it")
	car.pedestrian_ahead = Vector2.INF
	var watched := _watch(car, 8.0)
	t.check(watched.turned and watched.finished, "then takes its turn once the crossing is clear")

## A signal decides the box where there is one, and a planned turn does not argue with it. The car
## may not be inside the junction while its own arm is red.
func _test_a_red_light_still_holds_a_car_that_is_turning(t) -> void:
	var signals := _city.crowd.signals_for_tests()
	if not signals:
		return
	var box := Vector2i(_city.map.main_road, _junction.y)
	if not signals.is_signalled(box):
		return
	_clear_the_holds()
	_hold(StreetNetwork.Segment.new(box, false).key())
	# Wound to the moment the spine's own arm goes red, so the car meets the light rather than
	# whichever phase the scenarios before it happened to leave running.
	var cycle := Tuning.signal_cycle_seconds()
	for tick in int(round(cycle * 10.0)):
		signals.elapsed = float(tick) * 0.1
		if signals.phase_of(box) == TrafficSignals.Phase.SIDE_GREEN:
			break
	var car := _place_a_car(true, 1.0, box.x)
	var waited_on_red := false
	var crept_in_on_red := 0
	var turned := false
	for frame in int(round(20.0 / STEP)):
		_city.crowd.set_focus(car.position)
		_city.crowd.step(STEP)
		turned = turned or car.is_turning()
		var red := not signals.green_for(box, true)
		var inside := car.junction_occupied() == box
		if red and not inside and car.speed() < Tuning.CAR_STOPPED_SPEED:
			waited_on_red = true
		# Having waited, it may not then edge into the box while the light is still against it: the
		# signal decides the junction, and a car with a turn planned is not exempt from it.
		if red and inside and waited_on_red and not car.is_turning():
			crept_in_on_red += 1
	t.check(waited_on_red, "a car with a turn planned waits at a red light rather than taking it")
	t.check(crept_in_on_red == 0,
			"and does not edge into the box while the light is still against it (%d frames it did)"
			% crept_in_on_red)
	t.check(turned, "then takes the turn once it has the green")

## Out of bounds is a wall to everybody but a car on the spine, so a car heading for the edge turns
## at the last junction — the boundary case of the same rule a closure exercises.
func _test_a_car_turns_at_the_last_junction_before_the_boundary(t) -> void:
	_clear_the_holds()
	var corridor := CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.y) - 1
	if corridor == _city.map.main_road:
		corridor -= 1
	var car := _place_a_car(false, 1.0, corridor)
	# Started in the last block before the edge, heading east at it.
	car.position.x = float((StreetNetwork.junction_count().x - 1) * CityMap.period()
			* Tuning.TILE_SIZE) - 4.0 * float(Tuning.TILE_SIZE)
	var watched := _watch(car, 10.0, true)
	t.check(watched.turned, "a car driving at the city boundary makes a manoeuvre at the last "
			+ "junction rather than driving off the map")
	_check_the_path(t, watched, "boundary")
	var extent := _city.map.world_size()
	t.check(car.position.x < extent.x and car.position.x > 0.0,
			"and is still inside the city afterwards")

# -------------------------------------------------------------------- the rig ---

## Every check a path owes, in one place: no jump, no snap, and no wheel off the carriageway.
func _check_the_path(t, watched: Manoeuvre, name: String) -> void:
	t.check(watched.worst_step <= Tuning.CAR_SPEED.y * STEP + 0.01,
			"%s: no frame of it moves the car further than its own top speed allows (%.2fpx)"
			% [name, watched.worst_step])
	t.check(watched.worst_swing <= deg_to_rad(20.0),
			"%s: and the heading sweeps rather than jumping (worst %.1f° in a frame)"
			% [name, rad_to_deg(watched.worst_swing)])
	t.check(watched.off_the_road == 0,
			"%s: the swept body stays on ground a car may drive over (%d frames it did not)"
			% [name, watched.off_the_road])

## Runs the whole crowd with this car in it, watching the one manoeuvre it makes.
##
## `over_the_kerb` is the about-face's own exemption — see
## `CrowdAgent._the_ground_a_turn_sweeps_is_clear`. Everything else still has to be ground the car
## may stand on.
func _watch(car: CrowdAgent, seconds: float, over_the_kerb := false) -> Manoeuvre:
	var watched := Manoeuvre.new()
	var was_turning := false
	var started := 0.0
	for frame in int(round(seconds / STEP)):
		var before := car.position
		var facing := car.heading()
		_city.crowd.set_focus(car.position)
		_city.crowd.step(STEP)
		var moved := before.distance_to(car.position)
		watched.worst_step = maxf(watched.worst_step, moved)
		watched.worst_swing = maxf(watched.worst_swing, absf(facing.angle_to(car.heading())))
		if moved > 0.5:
			var travelled := (car.position - before).normalized()
			watched.worst_drift = maxf(watched.worst_drift,
					absf(travelled.angle_to(car.heading())))
		if car.is_turning():
			if not was_turning:
				watched.turned = true
				started = float(frame) * STEP
			if not _the_body_is_on_drivable_ground(car, over_the_kerb):
				watched.off_the_road += 1
		elif was_turning:
			# **The first manoeuvre and no more.** A car that has turned round drives back up the
			# street it came from and may well have to turn again before the rig runs out of
			# seconds, and then every assertion about "the turn" is about whichever one happened
			# last.
			watched.finished = true
			watched.seconds = float(frame) * STEP - started
			return watched
		was_turning = car.is_turning()
	return watched

## Whether the whole strike box is on ground this car may drive over, sampled the same way the
## turn's own validation samples it.
func _the_body_is_on_drivable_ground(car: CrowdAgent, over_the_kerb: bool) -> bool:
	var forward := car.heading()
	var side := Vector2(-forward.y, forward.x)
	for a in 5:
		var along := lerpf(-1.0, 1.0, float(a) / 4.0)
		for b in 3:
			var across := lerpf(-1.0, 1.0, float(b) / 2.0)
			var tile := _city.map.world_to_tile(car.position
					+ forward * (along * Tuning.CAR_STRIKE_HALF_LENGTH)
					+ side * (across * Tuning.CAR_STRIKE_HALF_WIDTH))
			if _city.map.is_closed(tile) or _city.map.is_held_at(tile):
				return false
			if not _city.map.in_bounds(tile):
				return false
			if over_the_kerb:
				if not _city.map.is_street(tile):
					return false
			elif not Tile.is_road(_city.map.tile_at(tile)):
				return false
	return true

## A car of this suite's own, placed in a lane and pointed at `_junction`. The crowd is emptied
## first so that what the scenario measures is the scenario.
func _place_a_car(vertical: bool, direction: float, corridor := -1) -> CrowdAgent:
	var car := CrowdAgent.new()
	car.traffic = _city.crowd.traffic()
	car.setup(CrowdAgent.Kind.CAR, _city.map, _city.crowd.field(), 7, 0.0)
	car._vertical = vertical
	car._corridor = _corridor(vertical) if corridor < 0 else corridor
	car._lane = CrowdLanes.road_lane(vertical, direction)
	car._direction = direction
	car._speed = Tuning.CAR_SPEED.x
	car._cruise = Tuning.CAR_SPEED.x
	car._lane_centre = CrowdLanes.lane_centre(car._corridor, car._lane)
	car._turn = null
	car._turn_run_up = 0.0
	car._scan_at = Vector2i(-9999, -9999)
	# Four tiles of run-up on the near side of the junction, which is far enough out to see the
	# blockage beyond it and near enough that the whole manoeuvre fits in a few seconds of rig.
	var band_index := _junction.y if vertical else _junction.x
	var band := float(band_index * CityMap.period() * Tuning.TILE_SIZE)
	var along := band - 4.0 * float(Tuning.TILE_SIZE) if direction > 0.0 \
			else band + float((Tuning.STREET_WIDTH + 4) * Tuning.TILE_SIZE)
	car.position = CarTurn.world(vertical, along, car._lane_centre)
	_city.add_entity(car)
	_city.crowd.agents().append(car)
	_city.crowd.set_focus(car.position)
	return car

## The corridor a car travelling on this axis uses to reach `_junction`.
func _corridor(vertical: bool) -> int:
	return _junction.x if vertical else _junction.y

## The segment carrying straight on out of `_junction` along an axis.
func _ahead_of(vertical: bool, direction: float) -> Vector3i:
	var from := _junction if direction > 0.0 \
			else _junction - (Vector2i.DOWN if vertical else Vector2i.RIGHT)
	return StreetNetwork.Segment.new(from, not vertical).key()

## The segment leaving `_junction` along the crossing axis, on one side or the other.
func _arm(vertical: bool, direction: float) -> Vector3i:
	return _ahead_of(vertical, direction)

func _hold(key: Vector3i) -> void:
	_city.map.hold_segment(key)

func _clear_the_holds() -> void:
	_city.map.clear_day_holds()
	_city.crowd.clear()

## Somebody standing on the first zebra this car is coming up to: the pavement band of the
## crossing corridor, on the car's own line, which is the gesture the give-way rule answers.
func _kerbside_of(car: CrowdAgent) -> Vector2:
	var band := float(_junction.y * CityMap.period() * Tuning.TILE_SIZE)
	return Vector2(car.position.x, band + float(Tuning.TILE_SIZE))

## A four-way junction of ordinary streets, away from the spine, the precincts and the edge — the
## plain case every scenario here wants, since a main road is kept by its lights and a precinct has
## no carriageway to turn on.
func _plain_junction() -> Vector2i:
	var count := StreetNetwork.junction_count()
	for x in range(2, count.x - 2):
		for y in range(2, count.y - 2):
			var junction := Vector2i(x, y)
			if x == _city.map.main_road:
				continue
			if _all_four_arms_are_plain(junction):
				return junction
	return Vector2i(-1, -1)

func _all_four_arms_are_plain(junction: Vector2i) -> bool:
	for vertical in [true, false]:
		for direction in [1.0, -1.0]:
			var key := _key_of(junction, vertical, direction)
			if not _city.map.has_street(key):
				return false
			var segment := StreetNetwork.by_key(key)
			if _city.map.is_held(segment):
				return false
			var rect := segment.tile_rect()
			for tile in [rect.position, rect.end - Vector2i.ONE]:
				if _city.map.street_kind_at(vertical, tile) != GameEnums.StreetKind.ORDINARY:
					return false
	# And the box itself is road rather than a park or a precinct's paving.
	var centre := Vector2i(junction.x * CityMap.period() + Tuning.STREET_WIDTH / 2,
			junction.y * CityMap.period() + Tuning.STREET_WIDTH / 2)
	return Tile.is_road(_city.map.tile_at(centre))

func _key_of(junction: Vector2i, vertical: bool, direction: float) -> Vector3i:
	var from := junction if direction > 0.0 \
			else junction - (Vector2i.DOWN if vertical else Vector2i.RIGHT)
	return StreetNetwork.Segment.new(from, not vertical).key()
