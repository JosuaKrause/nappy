@warning_ignore_start("untyped_declaration", "unsafe_method_access")
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
##
## **Its cities come from the cache of generated cities** (`tests/city_map_cache.gd`): each
## seed's city is generated once in the test process and every case is handed a copy of its own,
## the same city `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const LANE_KEYS := preload("res://tests/lane_key_search.gd")
const SEED := 4242
const STEP := 1.0 / 60.0

var _city: City
var _junction := Vector2i(-1, -1)

## The owner a scenario's barrier is recorded under (`WorldMap.obstruct_tiles()` takes an
## `Object.get_instance_id()`): one barrier at a time, and each scenario's city is its own.
func _barrier_owner() -> int:
	return get_instance_id()

## Stands a stationary solid body on `tiles`, the way a café, a construction band or a kerbed van
## stands on them (`WorldMap.obstruct_tiles()`): a car meets it as it meets a closure
## (`CarStrategy.cannot_go_on()`), and the game writes it, where no street closure covers tiles
## inside a junction box or leaves lane stubs short of a half turn.
func _stand_a_body_on(tiles: Array[Vector2i]) -> void:
	_city.map.obstruct_tiles(_barrier_owner(), tiles)

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

func run(t: TestRunner) -> void:
	_test_the_turn_constants_hold_their_relationships(t)
	# Each scenario stands in a city of its own, built over a run of its own, so none leans on what
	# an earlier one left closed, held or driving.
	var scenarios: Array[Callable] = [
		_test_a_car_turns_into_each_arm_from_every_approach,
		_test_a_car_turns_round_when_every_arm_is_shut,
		_test_a_car_turns_round_in_the_street_short_of_a_barrier,
		_test_a_car_waits_for_the_lane_its_half_turn_lands_in,
		_test_a_car_with_no_road_either_way_stands_rather_than_flickering,
		_test_a_car_against_a_barrier_is_not_shunted_later,
		_test_a_plugged_arm_is_refused_rather_than_driven_into,
		_test_the_heading_is_the_direction_it_is_actually_travelling,
		_test_a_queue_keeps_its_distance_behind_a_turning_car,
		_test_a_turn_merges_into_a_lane_without_resetting_it,
		_test_two_cars_arriving_together_do_not_share_the_box,
		_test_a_turning_car_still_gives_way_at_a_zebra,
		_test_a_red_light_still_holds_a_car_that_is_turning,
		_test_a_car_turns_at_the_last_junction_before_the_boundary,
	]
	for scenario in scenarios:
		_city = RunCity.with_own_run(CITY_SCENE, SEED)
		t.add_child(_city)
		_city.build(MapCache.of(SEED))
		_junction = _plain_junction()
		t.check(_junction.x >= 0, "this city has an ordinary four-way junction to turn at")
		if _junction.x >= 0:
			scenario.call(t)
		_city.free()

# ------------------------------------------------------------------ the numbers ---

## The two constants a turn introduces, stated as the relationships that make them right rather
## than as the values — see `Tuning.CAR_TURN_SPEED`.
func _test_the_turn_constants_hold_their_relationships(t: TestRunner) -> void:
	var lateral := Tuning.CAR_TURN_SPEED * Tuning.CAR_TURN_SPEED / CarTurn.CAR_TURN_RADIUS_MIN
	t.check(lateral <= CarStrategy.CAR_BRAKE,
			"a car is never asked to corner harder than it can brake (%.0f against %.0f px/s²)"
			% [lateral, CarStrategy.CAR_BRAKE])
	t.check(Tuning.CAR_TURN_SPEED > Tuning.CAR_STRIKE_MIN_SPEED,
			"a car taking a corner is still fast enough to be lethal, so a junction is not a safe "
			+ "place to stand (%.0f over %.0f)"
			% [Tuning.CAR_TURN_SPEED, Tuning.CAR_STRIKE_MIN_SPEED])
	t.check(Tuning.CAR_TURN_SPEED < Tuning.CAR_SPEED.x,
			"and a turn always slows the slowest car down rather than speeding it up")
	t.check(CarTurn.CAR_TURN_RADIUS_MIN > Tuning.CAR_STRIKE_HALF_WIDTH,
			"the tightest arc is wider than the body's own half width, so no turn is a pivot "
			+ "(%.0f over %.0f)" % [CarTurn.CAR_TURN_RADIUS_MIN, Tuning.CAR_STRIKE_HALF_WIDTH])
	# The far-side arm is three times the radius of the near-side one, and both are fixed by where
	# the lanes are. If a lane ever moves, these move with it rather than being re-chosen.
	# The arc into each arm, as a car plans it from an east-bound lane: the turn away from its own
	# kerb waits for the tail to clear it and takes a tighter arc, so the arm's own radius is the
	# larger of its two turns'.
	var in_lane := CrowdLanes.lane_centre(0, CrowdLanes.road_lane(false, 1.0))
	var near := 0.0
	var far := 0.0
	for turning in [1.0, -1.0]:
		near = maxf(near, CarTurn.into_an_arm(false, 1.0, 0, in_lane, 0,
				CrowdLanes.ROAD_OFFSETS[0], turning, Vector2i.ZERO).radius)
		far = maxf(far, CarTurn.into_an_arm(false, 1.0, 0, in_lane, 0,
				CrowdLanes.ROAD_OFFSETS[1], turning, Vector2i.ZERO).radius)
	t.check(near >= CarTurn.CAR_TURN_RADIUS_MIN and far > near,
			"the near-side arm is the tightest arc the lanes allow and the far-side one is wider "
			+ "(%.0f and %.0f px)" % [near, far])

# --------------------------------------------------------------------- the turns ---

## The quarter turn, from all four approaches and into both arms.
##
## Each run shuts the way ahead and one of the two arms, so the arm the car takes is the one being
## asked about rather than one of two it might have rolled. What is checked is the same four things
## every time: the path never jumped, the body never left the carriageway, it landed on the lane it
## was turning into and pointing along it, and it got there.
func _test_a_car_turns_into_each_arm_from_every_approach(t: TestRunner) -> void:
	for vertical in [true, false]:
		for direction in [1.0, -1.0]:
			for turning in [1.0, -1.0]:
				_one_arm(t, vertical, direction, turning)

func _one_arm(t: TestRunner, vertical: bool, direction: float, turning: float) -> void:
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
	t.check(car.travelling_vertically() == not vertical and _direction_of(car) == turning,
			"%s: it comes out on the crossing axis pointing the way it turned" % name)
	t.check(_is_in_the_lane_on_its_right(car),
			"%s: and in the lane on its own right for the way it is now pointing" % name)
	var landed_on: float = car.position.x if car.travelling_vertically() else car.position.y
	var off := absf(landed_on - CrowdLanes.lane_centre(CrowdLanes.corridor_at(landed_on),
			CrowdLanes.road_lane(not vertical, turning)))
	t.check(off < 1.0, "%s: on the exit lane's own centre line, not steering back to it (%.1fpx off)"
			% [name, off])

## The about-face, from all four approaches, where the junction is boxed in on three sides. The
## crossing street's own carriageway is the room a half turn needs, so this one is taken in the
## middle of the box and stays on the road for the whole of it.
func _test_a_car_turns_round_when_every_arm_is_shut(t: TestRunner) -> void:
	for vertical in [true, false]:
		for direction in [1.0, -1.0]:
			_clear_the_holds()
			_hold(_ahead_of(vertical, direction))
			_hold(_arm(not vertical, 1.0))
			_hold(_arm(not vertical, -1.0))
			var car := _place_a_car(vertical, direction)
			var lane_before := car.lane_key()
			var watched := _watch(car, 10.0)
			var name := "%s%s" % ["+" if direction > 0.0 else "-", "y" if vertical else "x"]
			t.check(watched.turned and watched.finished,
					"boxed in on three sides (%s): the car turns round and completes it (%.2fs)"
					% [name, watched.seconds])
			_check_the_path(t, watched, "about-face " + name)
			t.check(car.travelling_vertically() == vertical and _direction_of(car) == -direction,
					"about-face %s: it comes out on the same street pointing back" % name)
			t.check(car.lane_key() != lane_before and _is_in_the_lane_on_its_right(car),
					"about-face %s: and in the other lane, which is the one on its own right now"
					% name)

## The about-face with no junction to take it in: a body standing across the mouth of the street, so the
## car has to turn round short of it. **This is the one manoeuvre whose swept body crosses a kerb**
## — a half turn between two lanes 32px apart is a 16px arc and the body's corners reach 40px from
## the centre of it — so the road check here is the looser one. Nothing else is relaxed: the barrier
## itself is still refused, which is what "never drive through a barrier" means.
func _test_a_car_turns_round_in_the_street_short_of_a_barrier(t: TestRunner) -> void:
	_clear_the_holds()
	_bar_the_junction_band()
	var car := _place_a_car(true, 1.0)
	var watched := _watch(car, 12.0, true)
	t.check(watched.turned and watched.finished,
			"a car meeting a barred junction turns round in the street (%.2fs)" % watched.seconds)
	_check_the_path(t, watched, "street about-face")
	t.check(_direction_of(car) == -1.0 and car.travelling_vertically(),
			"and comes out heading back the way it came")
	# That it never reached the barrier is `off_the_road` above: ground a body stands on fails the
	# same check the pavement does, which is what *never drive through a barrier* means here.

## **A car that cannot turn *this frame* waits and asks again; it does not give up and spin round.**
##
## The lane a half turn lands in is the other side of the car's own carriageway, and a car standing
## on the landing is traffic that is going somewhere. Reversing on the spot instead is the last
## resort (`CrowdAgent._turn_round()`), and it is the manoeuvre the player sees as a car flipping
## round without moving — so it may only be reached from a state that waiting cannot mend.
##
## The scenario is the street about-face above with one car added, parked in the oncoming lane
## exactly where the arc would put this one down. Held there by the rig rather than by any rule: a
## real car would be driving, and what is being asked is what the planner does while the spot is
## taken.
func _test_a_car_waits_for_the_lane_its_half_turn_lands_in(t: TestRunner) -> void:
	_clear_the_holds()
	_bar_the_junction_band()
	var car := _place_a_car(true, 1.0)
	# Where the car will come to rest, and therefore where its half turn will land: its brake aims a
	# half turn plus the geometry's own slack short of the barrier, and the arc ends level with the
	# entry on the other lane. See `CarTurn.about_face()` — the semicircle moves the car across the
	# carriageway and not along it.
	var barrier := float(_junction.y * CityMap.period() * Tuning.TILE_SIZE)
	var rests_at := barrier - Tuning.CAR_STRIKE_HALF_LENGTH - CarTurn.about_face_reach() \
			- CarStrategy.TURN_ROOM_MARGIN
	# A car stood on the landing, in the oncoming lane, held there by a figure standing just ahead of
	# it: what stops a car in the game. The figure keeps its place until it is asked to go.
	var blocker := _place_a_car(true, -1.0, -1, 0.0, rests_at)
	var figure_at := Vector2(blocker.position.x,
			rests_at - Tuning.CAR_STRIKE_HALF_LENGTH - CarStrategy.FIGURE_SETBACK - 2.0)
	# Joined beside the lane and stepped into it on the second frame. It is built standing its ground
	# (`stood_round`), so the separation pass keeps it in the lane whether or not it has moved.
	var figure := _a_figure(figure_at + Vector2(6.0, 0.0))
	# Put into the index before the car is ever asked, because `TrafficIndex` is rebuilt at the *end*
	# of a frame: a car that asks on the very first one reads an empty index and commits to a spot
	# the rig has already filled.
	_city.crowd.space_out_the_traffic(STEP)

	var waited := false
	var flipped := false
	var turned := false
	for frame in int(round(14.0 / STEP)):
		if frame == 2:
			figure.place(figure_at)
		_city.crowd.set_focus(car.position)
		var facing := _direction_of(car)
		_city.crowd.step(STEP)
		flipped = flipped or _direction_of(car) != facing
		if car.is_turning():
			turned = true
			break
		if not waited and car.speed() < Tuning.CAR_STOPPED_SPEED:
			# It is stopped at its aim point with the landing taken and it has not reversed. That is
			# the whole assertion; now let the lane clear and watch it take the arc it was refused.
			waited = true
			_city.map.moves.leave(figure)
	t.check(waited, "the car reached its aim point and waited for the lane its half turn lands in "
			+ "rather than finding it empty")
	t.check(not flipped, "it did not reverse on the spot while the landing was taken")
	t.check(turned, "and it took the arc once the lane cleared")
	_clear_the_holds()

## **And a car with no road either way stands still rather than shaking its head.**
##
## *(Playtest 76: "cars are still jumping around".)* A reversal swaps the lane a car belongs to
## without moving it, so the ordinary cross-steer then slides the body over to the other lane's
## centre — three pixels a frame, under every jump threshold there is, and from outside it is a car
## twitching between the two sides of the street. It repeats because the state that caused it is
## unchanged: a stub of carriageway shorter than a half turn is still a stub when the car is pointing
## the other way.
##
## So the last resort is refused where it cannot help, and the car does what any body with nowhere
## to go does — it stands, and leaves once nobody can see it go. The rig keeps the camera on it, so
## what is measured here is the standing rather than the leaving.
func _test_a_car_with_no_road_either_way_stands_rather_than_flickering(t: TestRunner) -> void:
	_clear_the_holds()
	var band := _junction.y * CityMap.period()
	var here := floori((float(band * Tuning.TILE_SIZE) - 4.0 * float(Tuning.TILE_SIZE))
			/ float(Tuning.TILE_SIZE))
	var stubs: Array[Vector2i] = []
	for step in [-2, 2]:
		for lane in CrowdLanes.ROAD_OFFSETS:
			stubs.append(Vector2i(_junction.x * CityMap.period() + lane, here + step))
	_stand_a_body_on(stubs)
	# Standing in the middle of the stub, at rest: there is less than a half turn's road at either
	# end of it, which is the state being asked about rather than one to be driven into. Placed
	# there as the entry places a car, and brought to rest as a collision brings one (`crashed_into()`).
	var car := _place_a_car(true, 1.0, -1, 0.0,
			float(here * Tuning.TILE_SIZE) + float(Tuning.TILE_SIZE) * 0.5)
	car.crashed_into()
	var facing := _direction_of(car)
	var lane_before := car.lane_key()
	var flips := 0
	var swings := 0.0
	var turned := false
	for frame in int(round(6.0 / STEP)):
		_city.crowd.set_focus(car.position)
		var was := _direction_of(car)
		var across := car.position.x
		_city.crowd.step(STEP)
		if _direction_of(car) != was:
			flips += 1
		swings = maxf(swings, absf(car.position.x - across))
		turned = turned or car.is_turning()
	t.check(flips == 0,
			"a car with less than a half turn's road at either end stands rather than reversing "
			+ "where it stands (%d reversals in six seconds)" % flips)
	t.check(_direction_of(car) == facing and car.lane_key() == lane_before and not turned,
			"it keeps the heading and the lane it had, so nothing slides it across the carriageway")
	t.check(swings < 1.0, "and it does not drift across its own street (%.1fpx in a frame)" % swings)
	t.check(car.strategy.nowhere_to_turn, "the planner knows why, rather than the car merely being stuck")
	# Guards against a scenario that proved nothing: the stub really was short at both ends.
	t.check(band >= 0, "the rig had a junction band to build the stub against")

## **A car inside its leader with a barrier behind it goes back as far as the ground allows, on that
## frame, and is never shunted later.**
##
## The queue's resolve slides the follower back by the overlap, and refuses to slide it onto ground
## no car could be on. Refused whole, the pair stays inside each other and the overlap is paid in one
## jump on whichever later frame the leader has pulled far enough ahead for the full slide to be
## legal — a frame nobody chooses, so possibly one she is watching. On the morning that is the
## probe's `behind a car already there on the first frame` row: a car placed in the stub of road
## just past a barrier, unpacked on the second frame instead of before the first.
##
## The rig is two cars heading away from a barred junction, the follower a little past the barrier
## and the leader a fraction of a car's length in front of it. The first frame is the resolve; every
## frame after it may move the follower no further than it could drive in one.
func _test_a_car_against_a_barrier_is_not_shunted_later(t: TestRunner) -> void:
	_clear_the_holds()
	_bar_the_junction_band()
	var past_the_barrier := float((_junction.y * CityMap.period() + Tuning.STREET_WIDTH)
			* Tuning.TILE_SIZE)
	# The follower is placed a little past the barrier and the leader a safe gap ahead of it; the
	# leader is then backed onto the follower by the same nudge the separation pass uses
	# (`nudge_back()`), which leaves it a fraction of a car's length in front.
	var follower := _place_a_car(true, 1.0, -1, 0.0, past_the_barrier + 40.0)
	var leader := _place_a_car(true, 1.0, -1, 0.0, past_the_barrier + 40.0 + 4.0 * Tuning.CAR_GAP_MIN)
	leader.nudge_back(4.0 * Tuning.CAR_GAP_MIN - 20.0)
	for car in [follower, leader]:
		car.crashed_into()
	_city.crowd.set_focus(follower.position)
	_city.crowd.step(STEP)
	var first := follower.position.y
	t.check(first <= past_the_barrier + 1.0,
			"the frame the overlap arises, the follower goes back as far as the barrier lets it "
			+ "(%.1fpx past the barrier's edge)" % (first - past_the_barrier))
	t.check(not _city.map.is_obstructed(_city.map.world_to_tile(follower.position)),
			"and not onto it")
	var a_frames_travel := Tuning.CAR_SPEED.y * STEP + 0.01
	var worst := 0.0
	var leader_went := 0.0
	for frame in int(round(3.0 / STEP)):
		_city.crowd.set_focus(follower.position)
		var was := follower.position
		_city.crowd.step(STEP)
		worst = maxf(worst, was.distance_to(follower.position))
		leader_went = leader.position.y - past_the_barrier
	t.check(leader_went > Tuning.CAR_GAP_MIN,
			"the leader drove clear of where a whole slide would have been legal (%.0fpx)"
			% leader_went)
	t.check(worst <= a_frames_travel,
			"and no frame after it moves the follower further than it could drive in one (worst "
			+ "%.1fpx, against %.1fpx)" % [worst, a_frames_travel])
	_clear_the_holds()

## Stands a body across both lanes of the junction band ahead, which is the barrier a car has to
## turn round short of.
func _bar_the_junction_band() -> void:
	var band := _junction.y * CityMap.period()
	var barred: Array[Vector2i] = []
	for offset in range(0, Tuning.STREET_WIDTH):
		for lane in CrowdLanes.ROAD_OFFSETS:
			barred.append(Vector2i(_junction.x * CityMap.period() + lane, band + offset))
	_stand_a_body_on(barred)

## An arm with a plug two tiles in is refused rather than turned into.
##
## The probe that picks an arm fires a single point seven tiles out and looks straight past a short
## plug — harmless when a car could reverse its heading wherever it stood, and a car parked in a
## cul-de-sac for the rest of the day now. What refuses it is the room the *exit* has to leave in.
func _test_a_plugged_arm_is_refused_rather_than_driven_into(t: TestRunner) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	_hold(_arm(false, -1.0))
	var plug: Array[Vector2i] = []
	var band := _junction.x * CityMap.period()
	for offset in range(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH + 2):
		for lane in CrowdLanes.ROAD_OFFSETS:
			plug.append(Vector2i(band + offset, _junction.y * CityMap.period() + lane))
	_stand_a_body_on(plug)
	var car := _place_a_car(true, 1.0)
	var watched := _watch(car, 12.0, true)
	var inside := 0
	for tile in plug:
		if _city.map.world_to_tile(car.position) == tile:
			inside += 1
	t.check(inside == 0, "the car never ends up inside the plug it could not have left")
	t.check(watched.turned, "it still makes a manoeuvre rather than standing there")
	t.check(_direction_of(car) == -1.0 or not car.travelling_vertically(),
			"and leaves by the arm that is open or by the way it came")
	_check_the_path(t, watched, "plugged arm")

## `LaneMover.heading()` is what everything downstream of a car reads — the strike box, the horn, the shadow
## and, once it is bound, the picture. So it has to be the direction the car is **actually** going,
## not the axis it belongs to, on every frame of a turn.
func _test_the_heading_is_the_direction_it_is_actually_travelling(t: TestRunner) -> void:
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
func _test_a_queue_keeps_its_distance_behind_a_turning_car(t: TestRunner) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	_hold(_arm(false, -1.0))
	var leader := _place_a_car(true, 1.0)
	var followers: Array[CrowdAgent] = []
	for i in 2:
		var follower := _place_a_car(true, 1.0, -1, float(i + 1) * Tuning.CAR_GAP_MIN * 1.6)
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

## **A car turning into a lane that already has traffic in it may not rearrange that traffic.**
## *(2026-09-12, [PLAYTEST-66](playtests/PLAYTEST-66.md): "a car doing a u-turn into a lane with
## traffic reset the other lane".)*
##
## The room a turn lands in is checked when the turn **commits**, which is a run-up plus a whole arc
## before the car is standing there, and the other lane keeps moving in the meantime. Landing on top
## of somebody then went to `Crowd.space_out_the_traffic()`'s front-to-back resolve, which can only
## move a body — and it compounds, so every car behind the newcomer is shunted by the overlap *plus*
## everything moved ahead of it. One arrival rearranges a whole queue.
##
## **The lane makes room by its own following rule**: while the booking stands, the nearest car
## behind it measures `gap_ahead` to the booked spot rather than to the next real car, so it eases
## off exactly as it would for anything else in front of it and the gap is open by the time the turn
## arrives. That is what is asserted first, because it is the mechanism; then the two properties a
## player can see — the incumbents keep their order and none of them ever moves further in a frame
## than a car can drive in one.
##
## **Both arms are left open and the queue is placed once the turn has booked a lane**, rather than
## the scenario choosing the arm. A car only ever turns because the way ahead is shut, so the ground
## *behind* a turn's landing is open road for an arm turn and is the blockage itself for an
## about-face — there is nowhere to stand a queue behind a half turn's landing. The code path is one
## and the same either way: `CarStrategy._land_the_turn()` merges, and `Crowd._keep_room_for_the_turning()` reads
## `LaneMover.turn_lane_key()` without caring which manoeuvre produced it.
func _test_a_turn_merges_into_a_lane_without_resetting_it(t: TestRunner) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	var turner := _place_a_car(true, 1.0)
	# The traffic in the lane the turn lands in is not known until the turn has been planned, so it
	# is put there once the turn has booked its lane (below).
	var queue: Array[CrowdAgent] = []

	# Close enough that the queue closes on the booked spot while the arc is still running, which is
	# the timing the whole defect lives in: free when the turn committed, taken when it arrived.
	var booked := INF
	for frame in int(round(6.0 / STEP)):
		if turner.is_turning() and turner.turn_lane_key() != turner.lane_key():
			booked = turner.turn_landing()
			for i in 3:
				queue.append(_place_a_car_in_lane(turner.turn_lane_key(),
						booked - 150.0 - float(i) * Tuning.CAR_GAP_MIN * 1.6))
			break
		_city.crowd.set_focus(turner.position)
		_city.crowd.step(STEP)
	t.check(booked != INF, "the car booked a place in a lane it was not already in")

	var worst_jump := 0.0
	var worst_backwards := 0.0
	var order := _queue_order(queue)
	var order_held := true
	var room_made := false
	var came_for_the_spot := false
	var landed := false
	for frame in int(round(4.0 / STEP)):
		var before: Array[Vector2] = []
		var positions: Array[float] = []
		for car in queue:
			before.append(car.position)
			positions.append(car.queue_position())
		_city.crowd.set_focus(turner.position)
		_city.crowd.step(STEP)
		if turner.is_turning():
			var follower := _nearest_behind(queue, turner.turn_landing())
			if follower:
				var to_the_booking := turner.turn_landing() - follower.queue_position()
				room_made = room_made or absf(follower.gap_ahead - to_the_booking) < 0.5
				came_for_the_spot = came_for_the_spot or to_the_booking < Tuning.CAR_GAP_MIN * 2.0
		else:
			landed = landed or turner.lane_key() == queue[0].lane_key()
		for i in queue.size():
			worst_jump = maxf(worst_jump, before[i].distance_to(queue[i].position))
			worst_backwards = maxf(worst_backwards, positions[i] - queue[i].queue_position())
		order_held = order_held and _queue_order(queue) == order

	t.check(came_for_the_spot,
			"the queue really did close on the booked spot while the turn was still running, so "
			+ "this is the collision the player saw rather than a car turning into an empty street")
	t.check(room_made,
			"the car behind the booking keeps a headway to it, so the lane opens the gap by driving "
			+ "rather than by being rearranged when the turn arrives")
	t.check(landed, "the turn completed and the car took up the lane it had booked")
	# One frame's travel at the fastest a car in this rig is ever going. A shunt is a car's own
	# length or more; ordinary driving is three pixels.
	var a_frames_travel := Tuning.CAR_SPEED.y * STEP + 0.01
	t.check(worst_jump <= a_frames_travel,
			"no car already in that lane moves further in a frame than it could drive (%.1fpx "
			% worst_jump + "against %.1fpx)" % a_frames_travel)
	t.check(worst_backwards <= 0.01,
			"and none of them is pushed backwards at all to make room (%.2fpx)" % worst_backwards)
	t.check(order_held, "the queue keeps its order the whole way through")
	var tightest := INF
	for car in queue:
		tightest = minf(tightest, absf(car.queue_position() - turner.queue_position()))
	t.check(tightest >= Tuning.CAR_GAP_MIN - 1.0,
			"and the car that joined ends up a full gap clear of everybody that was already there "
			+ "(%.0fpx against %.0f)" % [tightest, Tuning.CAR_GAP_MIN])

## Places a car in the lane `key` names, at `at` on that lane's own queue axis, through the entry
## `_place_a_car()` takes. The lane is one a turn has just booked a place in, which the placement
## helper could not have known about before the turn was planned. `CrowdAgent.queue_position()` is
## `along * direction`, and therefore its own inverse for a direction of plus or minus one.
func _place_a_car_in_lane(key: int, at: float) -> CrowdAgent:
	var parts := LANE_KEYS.parts_of(key)
	var vertical: bool = parts[0]
	var direction := float(parts[3])
	var heading := Vector2(0.0, direction) if vertical else Vector2(direction, 0.0)
	var placed := _city.crowd.add_recipe_actor("queued-%d" % _city.crowd.agent_count(),
			CrowdAgent.Kind.CAR,
			CarTurn.world(vertical, at * direction, CrowdLanes.lane_centre(parts[1], parts[2])),
			heading, Tuning.CAR_SPEED.x, 7)
	assert(placed["error"] == "", "the queued car is placed: %s" % placed["error"])
	return placed["actor"]

## The car in `queue` closest behind `at` on its own lane's queue axis, or `null` when they are all
## in front of it. "Behind" is smaller, since `CrowdAgent.queue_position()` is signed so that ahead
## is larger.
func _nearest_behind(queue: Array[CrowdAgent], at: float) -> CrowdAgent:
	var found: CrowdAgent = null
	var closest := INF
	for car in queue:
		var behind := at - car.queue_position()
		if behind > 0.0 and behind < closest:
			closest = behind
			found = car
	return found

## The cars of a queue by their own queue positions, front first — the ordering the separation pass
## sorts on, read back so a test can say whether anybody overtook or was overtaken.
func _queue_order(queue: Array[CrowdAgent]) -> Array:
	var sorted: Array[CrowdAgent] = queue.duplicate()
	sorted.sort_custom(func(a: CrowdAgent, b: CrowdAgent) -> bool:
		return a.queue_position() > b.queue_position())
	var order: Array = []
	for car in sorted:
		order.append(car.get_instance_id())
	return order

## Two cars at one box, one turning across the other's path. The box is rationed, so the turn holds
## the whole of it until its tail is clear — and what the crossing car does is wait, not arrive.
func _test_two_cars_arriving_together_do_not_share_the_box(t: TestRunner) -> void:
	_clear_the_holds()
	_hold(_ahead_of(true, 1.0))
	_hold(_arm(false, -1.0))
	var turner := _place_a_car(true, 1.0)
	# Placed on the open side of the box, which the entry accepts (the arm it comes along is held for
	# the scenario), then put level with the turner, so the box is decided rather than queued for.
	var crossing := _place_a_car(false, 1.0, -1, 0.0,
			float((_junction.x * CityMap.period() + Tuning.STREET_WIDTH + 4) * Tuning.TILE_SIZE))
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
func _test_a_turning_car_still_gives_way_at_a_zebra(t: TestRunner) -> void:
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
func _test_a_red_light_still_holds_a_car_that_is_turning(t: TestRunner) -> void:
	var signals := _city.signals
	var box := Vector2i(_city.map.main_road, _junction.y)
	t.check(signals != null and signals.is_signalled(box),
			"the spine's junction in the rig is signalled, so there is a light to meet")
	if signals == null or not signals.is_signalled(box):
		return
	_clear_the_holds()
	_hold(StreetNetwork.Segment.new(box, false).key())
	# Wound to the moment the spine's own arm goes red, so the car meets the light rather than
	# whichever phase the scenarios before it happened to leave running.
	var cycle := Tuning.signal_cycle_seconds()
	for tick in int(round(cycle * 10.0)):
		signals.elapsed = float(tick) * 0.1
		if signals.green_for(box, false):
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
## at the last junction — the boundary case of the same rule a barrier exercises.
func _test_a_car_turns_at_the_last_junction_before_the_boundary(t: TestRunner) -> void:
	_clear_the_holds()
	# The outermost street that is an ordinary one, the map's corner: its last junction has one arm to
	# turn into, or an about-face. A spine is kept by its lights and a precinct has no carriageway for
	# a car, so those are skipped.
	var start := (StreetNetwork.junction_count().x - 1) * CityMap.period() - 4
	var corridor := CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.y) - 1
	while corridor > 1 and (corridor == _city.map.main_road
			or _city.map.street_kind(false, corridor, start) != GameEnums.StreetKind.ORDINARY):
		corridor -= 1
	# Started in the last block before the edge, heading east at it.
	var car := _place_a_car(false, 1.0, corridor, 0.0,
			float((StreetNetwork.junction_count().x - 1) * CityMap.period() * Tuning.TILE_SIZE)
			- 4.0 * float(Tuning.TILE_SIZE))
	var watched := _watch(car, 10.0, true)
	t.check(watched.turned, "a car driving at the city boundary makes a manoeuvre at the last "
			+ "junction rather than driving off the map")
	_check_the_path(t, watched, "boundary")
	var extent := _city.map.world_size()
	t.check(car.position.x < extent.x and car.position.x > 0.0,
			"and is still inside the city afterwards")

# -------------------------------------------------------------------- the rig ---

## Every check a path owes, in one place: no jump, no snap, and no wheel off the carriageway.
func _check_the_path(t: TestRunner, watched: Manoeuvre, name: String) -> void:
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
## `CarStrategy._the_ground_a_turn_sweeps_is_clear`. Everything else still has to be ground the car
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
			if _city.map.is_closed(tile) or _city.map.is_obstructed(tile) \
					or _city.map.is_held_at(tile):
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
##
## `back` places it that many px further back down its lane than the usual run-up, which is how a
## scenario stands several cars in one lane: the entry refuses a car on top of another's queue.
## `at_along` puts it at that distance along its street instead.
func _place_a_car(vertical: bool, direction: float, corridor := -1, back := 0.0,
		at_along := INF) -> CrowdAgent:
	var street := _corridor(vertical) if corridor < 0 else corridor
	var lane := CrowdLanes.road_lane(vertical, direction)
	# Four tiles of run-up on the near side of the junction, which is far enough out to see the
	# blockage beyond it and near enough that the whole manoeuvre fits in a few seconds of rig.
	var band_index := _junction.y if vertical else _junction.x
	var band := float(band_index * CityMap.period() * Tuning.TILE_SIZE)
	var along := band - 4.0 * float(Tuning.TILE_SIZE) if direction > 0.0 \
			else band + float((Tuning.STREET_WIDTH + 4) * Tuning.TILE_SIZE)
	along -= direction * back
	if at_along != INF:
		along = at_along
	var heading := Vector2(0.0, direction) if vertical else Vector2(direction, 0.0)
	# The entry a task scene's pinned actor takes (`Crowd.add_recipe_actor()`): the lane, the
	# street under it and the traffic queue are checked as a rolled morning's are.
	var placed := _city.crowd.add_recipe_actor("turner-%d" % _city.crowd.agent_count(),
			CrowdAgent.Kind.CAR, CarTurn.world(vertical, along, CrowdLanes.lane_centre(street, lane)),
			heading, Tuning.CAR_SPEED.x, 7)
	assert(placed["error"] == "", "the scenario's car is placed: %s" % placed["error"])
	var car: CrowdAgent = placed["actor"]
	_city.crowd.set_focus(car.position)
	return car

## A figure standing at `at` on the map's list of moves, the radius an event figure walks at
## (`EventInstance.FIGURE_RADIUS`) and one that is stood round: what a car stops behind. It stays
## until it leaves the list (`ProposedMoves.leave()`).
func _a_figure(at: Vector2) -> MoveProposal:
	var move := MoveProposal.new()
	move.radius = EventInstance.FIGURE_RADIUS
	move.stood_round = true
	_city.map.moves.join(move, at)
	return move

## Which way along its street a car points once it is out of a turn: plus or minus one.
func _direction_of(car: CrowdAgent) -> float:
	var heading := car.heading()
	return heading.y if car.travelling_vertically() else heading.x

## Whether a car is in the lane on its own right for the way it points, on the street it is standing
## in: the lane `CrowdLanes.road_lane()` names, read off its lane key.
func _is_in_the_lane_on_its_right(car: CrowdAgent) -> bool:
	var vertical := car.travelling_vertically()
	var direction := _direction_of(car)
	var street := CrowdLanes.corridor_at(car.position.x if vertical else car.position.y)
	return car.lane_key() == LaneMover.make_lane_key(vertical, street,
			CrowdLanes.road_lane(vertical, direction), direction)

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
	_city.map.hold_segment(key, HeldStreets.Why.SEAL)

func _clear_the_holds() -> void:
	_city.map.clear_day_holds()
	_city.crowd.clear()
	# The day's pockets (`CrowdPockets`) are refreshed by a tick, so a tick of no time lets the last
	# scenario's holds stop deciding which ground is a pocket the entry refuses.
	_city.crowd.step(0.0)

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
			var segment := _city.map.network.by_key(key)
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
