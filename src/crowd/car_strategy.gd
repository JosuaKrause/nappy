class_name CarStrategy
extends LaneStrategy
## How a car in the crowd moves on the lanes: the half of a `LaneMover` that only a car has.
##
## A car keeps to its own lane on the right of the carriageway and cannot step anywhere else, so
## everything it does about the road ahead is decided early and checked before it moves: it gives
## way by braking toward a point (a zebra somebody waits at, a junction it has no right to, a gate,
## the car in front), turns only along an arc it has planned and found room for, is warned off a
## held street a junction away, and leaves the city by the spine's tunnel or bridge. The walker's
## half is `WalkerStrategy`; what both share is the mover, `LaneMover`.

## The places `_plan_a_turn()` looks for room, in the order it tries them, and the slots of
## `turn_refusals`. See that function for what each one is.
enum TurnCandidate { NEAR_ARM, FAR_ARM, BOX_ABOUT_FACE, STREET_ABOUT_FACE }

## What turned one candidate arc away — the answer `_commit_to_a_turn()` gives back.
##
## **Read the list in two halves, and the split is the whole point of naming them.** `LANDING_TAKEN`
## is another car standing where this one wants to stop, and another car drives away; everything
## below it is the ground, the geometry or the map, and none of those changes while the car waits
## where it is. So a refusal from the first half means *ask again next frame* and one from the
## second means *this arc will never fit from here*.
enum TurnRefusal {
	FITS,              ## Not a refusal: the car is committed to this arc.
	NOT_TRIED,         ## The planner stopped before this slot, or there is no such arm at all.
	LANDING_TAKEN,     ## Somebody is parked where the arc ends. Temporary.
	OUT_OF_SIGHT,      ## The run-up is longer than a car can see a junction from.
	PAST_THE_BLOCKAGE, ## The run-up would drive through the thing being turned away from.
	TOO_TIGHT,         ## What is left of the junction is a tighter arc than a car can turn.
	SWEEP_BLOCKED,     ## The body would pass over ground a car may not drive on.
	EXIT_PLUGGED,      ## The street the arc lands in has no room to turn round in further on.
}

## Which call reversed a car where it stood. `NONE` on a planner run that did not.
enum TurnRoundCause {
	NONE,
	OFF_THE_STREET,   ## Standing on ground no arc could legally sweep from — already illegal.
	STOPPED_NO_ROOM,  ## At rest with less than a nose's length of manoeuvring room in front.
}

const CAR_ACCELERATE := 150.0

## The deceleration a car *aims* at when it eases up to a stop line, as opposed to `CAR_BRAKE`,
## which is the hardest it can push. Giving way has to be **visible from the kerb**, which is why
## the looking starts at `Tuning.CAR_ZEBRA_SIGHT` rather than at the line, and why the approach is shaped
## by a gentle rate with only the emergency using the hard one.
##
## The relationship, and the one `tests/test_crowd.gd` states:
## `sqrt(2 · CAR_ZEBRA_APPROACH_BRAKE · Tuning.CAR_ZEBRA_SIGHT) >= Tuning.CAR_SPEED.y` — the fastest car in the
## city begins easing at the moment the zebra comes into sight, rather than holding speed and
## then grabbing the brake at the last legal instant.
##
## **Getting this wrong in the obvious way makes no car ever stop**: shaping the approach with
## `CAR_BRAKE` itself puts the onset of braking and the commit point at the *same* moment, so a car
## glides up to the line at full speed, decides it can no longer stop, and drives through. The test
## that catches it is the one that says *where* a car stops rather than whether.
const CAR_ZEBRA_APPROACH_BRAKE := 90.0

## Deceleration when a car gives way at a crossing, and how far ahead it looks for one. The
## relationship that matters is `Tuning.CAR_ZEBRA_SIGHT > braking_distance(Tuning.CAR_SPEED.y) +
## Tuning.CAR_STOP_LINE_SETBACK`: a car always has room to stop **at the line** for a zebra it can see,
## so giving way is never a screech.
const CAR_BRAKE := 320.0

## Why each arc `_plan_a_turn()` tried on its last run was refused, one `TurnRefusal` per
## `TurnCandidate` slot — the planner's own record of a decision that otherwise leaves no trace.
##
## **A refusal that is never written down is a manoeuvre nobody can account for.** Every entry in
## `_plan_a_turn()`'s list of places to turn either fits or is turned away by exactly one check, and
## which check it was is the difference between *wait, this will clear* and *this can never fit
## here* — the distinction the planner itself acts on and the one a measurement of the traffic needs
## to read back. Four ints written where the decision is taken, and `tests/probes/m152_car_jumps.gd`
## is what reads them.
var turn_refusals := PackedInt32Array()

## Which of `_plan_a_turn()`'s two ways out reversed this car where it stood, or `NONE` when the
## last run of the planner did not. Reset at the top of every `_plan_a_turn()`.
var turn_round_cause := TurnRoundCause.NONE

## Whether this car has already committed to an arc since the last time the road in front of it was
## clear — what tells a turn that was planned and taken apart from one that was never found. Cleared
## by `_look_ahead()` the moment nothing is blocking the lane any more.
var turned_on_this_approach := false

## Seconds this car has stood at a barrier with an arc that fits everywhere but in the lane it would
## land in. Runs while it waits and is put back to zero the moment anything about the situation
## changes — a turn taken, the road ahead clear again, or a refusal that waiting cannot mend. See
## `TURN_WAIT_SECONDS`.
var _waited_to_turn := 0.0


## The layers a car is stopped by today: closures and bodies. A soft seal takes only the pavements,
## so its carriageway stays open to a car.
static var _car_today := Mover.of(Mover.CLOSED | Mover.BODIES)

func _init(mover: LaneMover) -> void:
	super(mover)
	nose = Tuning.CAR_STRIKE_HALF_LENGTH
	acts_within = LaneMover.LOOKAHEAD_TILES
	shut_by_a_hold = true
	scans_from_its_lane = true
	today = _car_today

# -------------------------------------------------- the mover's questions ---

## The car's along-track length and across-track width for the shadow capsule — fixed constants
## rather than read off a texture, so a picture cannot resize the shadow.
const SHADOW_ALONG := 52.0
const SHADOW_ACROSS := 30.0

## Distance a car needs to stop from a given speed. Used by the crossing logic and asserted
## against `Tuning.CAR_ZEBRA_SIGHT` in `tests/test_crowd.gd`.
static func braking_distance(speed: float) -> float:
	return speed * speed / (2.0 * CAR_BRAKE)

## A car's ground shape — a capsule along its travel axis, sized from `SHADOW_ALONG` and
## `SHADOW_ACROSS`: `radius` is half the across measurement and `half_length` is what is left of
## half the along once the two end caps are accounted for.
##
## **No body for a car.** A car's lethality is `TrafficIndex`'s, not a field's, and a `StaticBody2D`
## here would change the crowd's own collision rules rather than only how it looks — see
## docs/EVENTS.md and the **crowd-traffic** skill on why separation between bodies is positional,
## never a shape a car could get pinned against. This shape is the shadow's and the debug view's;
## the lethal rectangle is `will_be_lethal()`'s strike box (`Tuning.CAR_STRIKE_HALF_LENGTH` and
## `CAR_STRIKE_HALF_WIDTH`).
static func shadow_shape() -> GroundShape:
	var radius := SHADOW_ACROSS * 0.5
	return GroundShape.segment(SHADOW_ALONG * 0.5 - radius, radius)

func ground_shape() -> GroundShape:
	return shadow_shape()

func lane_offsets_at(_along_tile: int) -> Array[int]:
	return CrowdLanes.ROAD_OFFSETS

func placement_problem() -> String:
	if _mover._direction != CrowdLanes.road_direction(_mover._vertical, _mover._lane):
		return "car direction contradicts right-hand traffic"
	return ""

func speed_range() -> Vector2:
	return Tuning.CAR_SPEED

## Off the map is somewhere a car may legitimately stand only on the spine, leaving by the tunnel or
## the bridge — the one place an entry band may begin outside the map.
func may_stand_off_the_map(tile: Vector2i) -> bool:
	return _mover._map.is_main_road(_mover._vertical, _mover._corridor) \
			and (tile.y < 0 or tile.y >= _mover._map.size.y)

## A precinct is paved end to end, so every tile of it says "street" and a car placed there would
## look perfectly settled right up to the moment it drove off down the paving. Asked at placement
## rather than at lane-choosing time because it is a question about a *place*, and the place is not
## decided until the along position is rolled.
func may_be_placed_on(tile: Vector2i) -> bool:
	return _mover._map.is_driveable_at(_mover._vertical, tile)

## A car's bob and its give-way run every frame. **A car in a turn is following a path that was
## checked before it started**, so none of the lane steering, look-ahead or diverting applies to it:
## the only thing left to decide is how far along the curve it has come. It is not recycled mid-turn
## either — a recycle is a teleport, and half a turn is the one place in a car's life where that
## would be seen.
##
## **A car sealed in** — the one case a placement cannot prevent (`setup()` already refuses to put
## one in a pocket) — stands where the seal caught it, since it cannot turn round against a barrier:
## `_pocket_factor()` reads `velocity()` down to zero, which is where the stopped picture comes from
## for free. Make-way and bump still land from outside, since a standing body still has to be got
## round. It leaves the way anybody else leaves the field, once nobody can see it go.
func begin_frame(delta: float) -> bool:
	_mover.advance_the_picture(delta)
	_give_way(delta)
	if _mover._turn:
		_follow_the_turn(delta)
		_claim_the_turn()
		return true
	if not is_in_a_pocket():
		return false
	if _mover._out_of_view():
		_mover._recycle()
	return true

## **A body a pocket has caught is travelling at nothing**, through `_pocket_factor()`: its field is
## a plain falloff rather than one stretched forward, and its projected impact and expected approach
## both answer "nowhere" the way a stopped body's should.
func paced_velocity(moving: Vector2) -> Vector2:
	return moving * _pocket_factor()

## Nothing in the way any more, so whatever this car did about the last thing that was is over and
## the next blockage is a fresh approach. See `turned_on_this_approach` and `nowhere_to_turn`.
func on_the_road_clear() -> void:
	turned_on_this_approach = false
	nowhere_to_turn = false
	_waited_to_turn = 0.0

## **A car changes lane with an about-face**: a lane is one side of a carriageway and which side
## depends on the way it is pointing, so a car that only flipped its heading would drive the wrong
## way down its own queue — and `space_out_the_traffic` would then have to resolve a head-on overlap
## the only way it can, by moving a body.
func on_turned_round() -> void:
	_mover._lane = CrowdLanes.road_lane(_mover._vertical, _mover._direction)
	_mover._lane_centre = lane_centre_here()
	claim_the_road_here()

## A car has no gait, and its stride is its own length, the same 52px the body is measured over.
func stride_length() -> float:
	return 2.0 * Tuning.CAR_STRIKE_HALF_LENGTH

## **A car picks its axis by weight**, rather than splitting it evenly as a walker does. An even
## split silently caps the main road: the axis is decided *before* the corridor, so `busyness` can
## only redistribute cars **within** an axis, and no weight — 5.0, 50, any number — can put more
## than half the traffic on one north-south street. Measured that way at act I density, the spine
## holds 11.2 cars of forty with a weight five times its neighbours'. So the two decisions are one:
## pick among the corridors of **both** axes in proportion to how busy each is, which is what the
## weight was always supposed to mean.
func choose_lane(_roll: float) -> void:
	_mover._vertical = _pick_axis_by_weight()
	_mover._corridor = CrowdLanes.pick_corridor_in_range(_mover._rng, _mover._map,
			_mover._vertical, _mover.field.corridor_range(_mover._vertical), true)
	_mover._lane = CrowdLanes.ROAD_OFFSETS[_mover._rng.randi_range(0, 1)]
	_mover._direction = CrowdLanes.road_direction(_mover._vertical, _mover._lane)
	_mover._speed = _mover._rng.randf_range(Tuning.CAR_SPEED.x, Tuning.CAR_SPEED.y)

## A car sits on the tile centre of its lane.
func lane_centre_here() -> float:
	return CrowdLanes.lane_centre(_mover._corridor, _mover._lane)

## A car at a stretch's end enters on the lane that drives that way, at its ordinary speed.
func enter_at_an_end(_along_tile: int) -> bool:
	_mover._lane = CrowdLanes.road_lane(_mover._vertical, _mover._direction)
	_mover._speed = _mover._rng.randf_range(Tuning.CAR_SPEED.x, Tuning.CAR_SPEED.y)
	return true

# -------------------------------------------------------- what a car does ---

## Whether this **car** is standing on carriageway today's seals have shut in — a junction with all
## four arms held, and whatever stub of lane is sealed in with it. See `CrowdPockets`.
##
## **A walker is never in one, and that is the record's own rule rather than a shortcut here.**
## Sealed-in ground is ground a person can walk the whole of, turning round at the barrier on the
## end of each stub, so there is nothing to keep walkers out of and nothing to stand still about. A
## car cannot turn round against a barrier, which is the whole difference.
##
## **Asked beside `_stands_on_a_street()` at a placement rather than folded into it**, because the
## two questions have different answers for a car that is already standing somewhere. Ground it
## may not stand on is a state to get out of *now*, which is what `_plan_a_turn()` does about it;
## a pocket is legal ground it simply cannot leave, and the answer to that is to stand where the
## seal caught it and go when nobody is looking, rather than to turn on the spot at all. Folding it
## in would turn the whole pocket into a wall and give every car in one a reason to steer at it
## every frame, which is exactly the state `step()` avoids by asking this question ahead of the
## step instead: nothing below it runs while this is true.
func is_in_a_pocket() -> bool:
	if _mover.pockets == null:
		return false
	return _mover.pockets.holds(_mover._map.world_to_tile(_mover.position))

## How fast this car is going as a fraction of its own pace while a pocket has caught it: nothing at
## all while it is standing where the seal caught it, its ordinary pace otherwise. Always one for a
## walker, which is never in a pocket.
##
## A factor beside `_hold_factor()` and `_yield_factor()` for the same reason those two are: nothing
## has to remember what the speed used to be. And it is what makes the stopped picture free —
## everything that draws or predicts a body reads `velocity()` rather than this agent's own step,
## so a car whose step simply stopped advancing would still be drawn and predicted as travelling.
## Reading `velocity()` down to zero here is the same trick a door hold already relies on.
func _pocket_factor() -> float:
	if _mover.pockets == null:
		return 1.0
	return 0.0 if _mover.pockets.holds(_mover._map.world_to_tile(_mover.position)) else 1.0

## Which way a car drives, weighted by the traffic each axis is carrying **inside the field**.
##
## Restricted to the corridors in view for the same reason `pick_corridor_in_range` is: the crowd
## is a population of the box around her, so the question is which streets *she* can see, and a
## spine two miles north is not competing for these cars. A field with no drivable weight in it at
## all — every corridor in view a precinct — falls back to an even split rather than dividing by
## nothing, exactly as the corridor pick does; the caller re-rolls anyway.
func _pick_axis_by_weight() -> bool:
	var vertical_weight := _axis_weight(true)
	var horizontal_weight := _axis_weight(false)
	var total := vertical_weight + horizontal_weight
	if total <= 0.0:
		return _mover._rng.randf() < 0.5
	return _mover._rng.randf() * total < vertical_weight

func _axis_weight(vertical: bool) -> float:
	var span := _mover.field.corridor_range(vertical)
	var total := 0.0
	for index in range(span.x, span.y + 1):
		total += CrowdLanes.busyness_for(_mover._map, vertical, index, true)
	return total

## **A zebra is only the safe way over if the traffic honours it** — otherwise it is paint, and the
## choice between crossing here and jaywalking there has one arm missing.
##
## Braking rather than stopping dead, and from `CAR_ZEBRA_SIGHT` out, because the giving way has to
## be *visible* from the kerb: a player deciding whether to step off needs to see the car slowing,
## not discover afterwards that it would have.
##
## It is also where a car decides not to drive through the one in front, waits its turn at a
## junction, or stops for a checkpoint gate. **The four wants compose by taking the lowest**, which
## is the whole trick: a car held at a box, a car held at a gate, and a car behind another car are
## the same behaviour asked for by different things, and giving any one of them its own brake would
## be a second answer to a question that already has one.
func _give_way(delta: float) -> void:
	var wanted := _mover._cruise
	if _mover.junction_hold < INF:
		wanted = minf(wanted, sqrt(2.0 * CAR_ZEBRA_APPROACH_BRAKE * _mover.junction_hold))
	if _mover.gate_hold < INF:
		wanted = minf(wanted, sqrt(2.0 * CAR_ZEBRA_APPROACH_BRAKE * _mover.gate_hold))
	# A turn it has committed to: ease toward the speed the arc is taken at over whatever run-up is
	# left, and hold that speed for the whole curve. When the junction came into sight too late for
	# the easing to finish — which the lookahead makes the ordinary case rather than the unlucky one
	# — the car is still braking as it turns, which is what a driver who took a corner a little fast
	# does. See `Tuning.CAR_TURN_SPEED`.
	if _mover._turn:
		wanted = minf(wanted, sqrt(Tuning.CAR_TURN_SPEED * Tuning.CAR_TURN_SPEED
				+ 2.0 * CAR_ZEBRA_APPROACH_BRAKE * _mover._turn_run_up))
	# And the wall itself, for the car that has no manoeuvre that fits. Nothing used to brake for a
	# blockage at all, because reversing on the spot was always available; refusing that has to leave
	# the car somewhere it could have stopped.
	var blockage := _room_to_stop_in()
	if blockage < INF:
		wanted = minf(wanted, sqrt(2.0 * CAR_ZEBRA_APPROACH_BRAKE * blockage))
	# **An event figure in its lane ahead, or coming into it** (inbox #884 in plaid-raven: the crowd
	# yields): braked for like a stop line, so the car stands short of the figure's body rather than
	# driving through it. See `_distance_to_a_figure()`.
	var figure := _distance_to_a_figure()
	if figure < INF:
		wanted = minf(wanted, sqrt(2.0 * CAR_ZEBRA_APPROACH_BRAKE * figure))
	var to_line := _distance_to_stop_line()
	if to_line < INF:
		# The speed that runs out exactly at the line at the *approach* rate. **Braking toward a
		# point rather than toward zero** is the whole of it: aiming at zero stops the car wherever
		# the curve happens to end, which is most of a block early.
		# The gentle rate is what makes the easing start in sight of the kerb — see
		# `CAR_ZEBRA_APPROACH_BRAKE` for what shaping it with `CAR_BRAKE` does instead.
		wanted = minf(wanted, sqrt(2.0 * CAR_ZEBRA_APPROACH_BRAKE * to_line))
	wanted = minf(wanted, _following_speed())
	var rate := CAR_BRAKE if wanted < _mover._speed else CAR_ACCELERATE
	_mover._speed = move_toward(_mover._speed, wanted, rate * delta)

## How far this car has to the stop line of a crossing it should give way at, or `INF` when
## there is nothing to give way to — nobody waiting, or **it is already too late to stop**.
##
## The second half is the **commit rule**. A car that arrives at the paint as the player reaches the
## kerb and brakes anyway parks on the zebra; there is only one safe thing it can do that late, and
## it is to clear the crossing. `CAR_ZEBRA_SIGHT`
## is nearly four times the distance a car needs to stop, so this only ever fires for somebody
## who stepped up *after* the car had committed, and never for a player who was waiting there.
func _distance_to_stop_line() -> float:
	var crossing := _crossing_ahead_somebody_is_waiting_at()
	if crossing == INF:
		return INF
	# Measured against the **paint**, not against the line. The setback is a comfort margin, so
	# ending up inside it is a car stopped a little close; ending up on the zebra is the thing
	# the rule exists to prevent. Written the other way round — commit when it cannot stop at
	# the *line* — a car that has come to rest exactly there has a braking distance of nothing,
	# decides it is too late, and drives off over the crossing it just stopped for.
	if crossing < braking_distance(_mover._speed):
		return INF
	return maxf(0.0, GiveWay.stop_line(crossing))

## **How far this car has to the point it stands at for an event figure**, or `INF` for none: a
## figure, an event car or a cordon officer in its lane ahead, or coming into it within
## `FIGURE_LEAD_TICKS` of its own travel, within `Tuning.CAR_ZEBRA_SIGHT` (the map's
## `SeparationPass.edge_ahead()`), less the car's nose and `FIGURE_SETBACK`. **Moving or standing,
## for as long as it stands** (inbox #909): a car never drives through a figure. One that has parked
## (`MoveProposal.parked`, the fire engine at its fire) is also a blockage the car turns round at,
## as at a blocked street (`_distance_to_the_blockage()`), so it does not hold the lane for the rest
## of the day; one that is only stopping — the patrol car at a red light or while its man is out —
## is waited for.
##
## **No commit rule, unlike her zebra's**: a car too close to stop for a figure brakes as hard as it
## can and its step is then held short of the figure's body (`give_way_on_the_step()`), since a
## figure crossing in front of it is not hers to step off the carriageway for, and the crowd yields
## (inbox #884 in plaid-raven). It never swerves: the brake and the hold are along its own lane.
## Nothing on an arc, which keeps the path it checked before it started (`MoveProposal`'s doc).
func _distance_to_a_figure() -> float:
	var road := road_before_a_figure()
	if road == INF:
		return INF
	return maxf(0.0, road - FIGURE_SETBACK)

## **The clear road from its nose to the near edge of the event figure it would stand for**, or
## `INF` for none (see `_distance_to_a_figure()` for which figures), looking `reach` ahead of its
## centre: what its brake aims short of, and what the junction box rule reads beside the car in
## front (`Crowd._can_clear_the_box()`), so a car does not drive into a box it would have to stand in
## for a figure beyond it. **The box rule looks past the box's far side**, further than the brake's
## `Tuning.CAR_ZEBRA_SIGHT`: a car at the stop line is a box's width and more from a figure standing
## just beyond it, and one that saw the figure only from inside the box would stand there.
func road_before_a_figure(reach := Tuning.CAR_ZEBRA_SIGHT) -> float:
	var separation := _mover._map.separation
	if not separation.has_keepers_for_cars() or (_mover._turn and _mover._turn_run_up <= 0.0):
		return INF
	var edge := separation.edge_ahead(_mover.global_position, _mover.heading(), SHADOW_ACROSS * 0.5,
			FIGURE_WIDEST, reach, FIGURE_LEAD_TICKS)
	if edge == INF:
		return INF
	return edge - nose

## **The clear road from its nose to the near edge of a parked figure in its lane ahead**
## (`MoveProposal.parked`, inbox #909), or `INF` for none: a blockage like a closed tile, met at
## the distance a car meets a wall at (`LaneMover.LOOKAHEAD`), since what it does about one is the
## same turn round. Read into `_distance_to_the_blockage()`, so the brake that leaves it room to
## turn and every arc the planner tries stop short of it.
func road_before_a_parked_figure() -> float:
	var separation := _mover._map.separation
	if not separation.has_keepers_for_cars() or (_mover._turn and _mover._turn_run_up <= 0.0):
		return INF
	var edge := separation.edge_ahead(_mover.global_position, _mover.heading(), SHADOW_ACROSS * 0.5,
			FIGURE_WIDEST, float(LaneMover.LOOKAHEAD), 0.0, true)
	if edge == INF:
		return INF
	return maxf(0.0, edge - nose)

## Whether a parked figure in its lane ahead is within the distance a car acts on a blockage at:
## what sends it to `divert()` beside a closed tile (`LaneMover.step()`).
func blocked_by_a_figure() -> bool:
	return road_before_a_parked_figure() < INF

## How far short of a figure's body a car means to stand, in px: a few pixels, since a figure
## crossing in front is gone a moment later and a car stopped a lane's length off it holds the
## street for nothing.
const FIGURE_SETBACK := 6.0
## How far ahead of a figure's own travel, in ticks, a car looks for it coming into its lane: half a
## second, so a dog running across the carriageway is braked for before it is in the lane, while a
## figure ambling along the kerb is not stood for on every tick it might step off it.
const FIGURE_LEAD_TICKS := 15.0
## The most of a figure's reach a car counts across its lane, in px: a crowd car's strike half width
## (`Tuning.CAR_STRIKE_HALF_WIDTH`). A figure's reach is the circle round its whole body, which is
## a dog's or a man's width but an event car's length, and an event car passing in the next lane,
## one lane width off, is not in this one.
const FIGURE_WIDEST := Tuning.CAR_STRIKE_HALF_WIDTH

## **Holds its proposed step short of an event figure's body ahead** (the map's
## `SeparationPass.room_ahead()`, over its own capsule): the guarantee under the brake in
## `_give_way()`, since a brake aims at a point and arrives late (the **crowd-traffic** skill). Only
## along its own lane, never across it, and only for a figure ahead of its centre — one that walks
## into its flank or its tail is walking away from where it is going. Its speed falls to what the
## held step covers, so everything that reads how fast it goes (the strike, the horn, its field)
## reads a car that has stopped.
func give_way_on_the_step(delta: float) -> void:
	var separation := _mover._map.separation
	if not separation.has_keepers_for_cars():
		return
	var move := _mover._move
	var forward := _mover.heading()
	var step := (move.to - move.from).dot(forward)
	if step <= 0.0:
		return
	var room := separation.room_ahead(move.from, forward, _mover.shape.half_length,
			_mover.shape.radius, FIGURE_WIDEST)
	if room >= step:
		return
	move.to -= forward * (step - room)
	_mover._speed = minf(_mover._speed, room / delta)

## The fastest this car may go and still keep `CAR_HEADWAY_TIME` of clear road in front of it.
##
## A time headway rather than a fixed distance, because a fixed one either tailgates at speed
## or leaves a bus-length gap in a jam. `CAR_GAP_MIN` is the standstill distance underneath it:
## without it the arithmetic asks for zero speed at zero gap, which is a car parked inside
## another car rather than behind it.
func _following_speed() -> float:
	if _mover.gap_ahead == INF:
		return _mover._cruise
	return maxf(0.0, (_mover.gap_ahead - Tuning.CAR_GAP_MIN) / Tuning.CAR_HEADWAY_TIME)

## Distance along the street to the **near edge** of the first crossing ahead that somebody is
## standing at, or `INF` for none.
##
## The near edge rather than the tile centre, because a zebra is several tiles deep and a car
## that stops a setback short of the middle of one is standing on the first half of it.
##
## `pedestrian_ahead` is only ever set for the handful of cars near the player, so this probe
## does not run for the other hundred.
##
## Which zebra, and whether this street gives way to her at all (**a main road does not**: its
## crossings are the light's), is `GiveWay`'s, the one answer the event cars read too.
func _crossing_ahead_somebody_is_waiting_at() -> float:
	if _mover.pedestrian_ahead == Vector2.INF:
		return INF
	# **A car mid-turn is inside the box and has nothing to give way at.** The scan below walks
	# tiles down one axis from the car's own tile, which is a question about a lane the car is not
	# in while it is on an arc — and stopping there would be stopping in the junction, which is the
	# one thing the box rules exist to prevent. The zebras a turn crosses are at the box's own edges
	# and the car gave way at them, or committed, on the way in.
	if _mover._turn and _mover._turn_run_up <= 0.0:
		return INF
	if not GiveWay.owes_her_way(_mover._map, _mover._vertical, _mover.global_position,
			_mover.pedestrian_ahead):
		return INF
	var edge := GiveWay.zebra_edge_ahead(_mover._map, _mover.global_position, _mover._vertical,
			_mover._direction, _mover.pedestrian_ahead)
	if edge == INF:
		return INF
	return (edge - _mover._along()) * _mover._direction

## Whether the street `distance` ahead along an axis is one this agent cannot travel: shut for
## the day, or not a street at all.
##
## The second half is the calm zones. A zone is painted straight over the corridors between its own
## blocks, so a lane that would run the width of the city runs into a park instead — and those tiles
## are perfectly walkable, which is why `is_closed` alone has nothing to say about them. Diverting
## is the same move a barricade produces, with the same good side effect: a street with nobody on it
## is a street that does not go through.
##
## Out of bounds **is** blocked, in `cannot_go_on()` below — a body that reaches the boundary
## pavement turns rather than walking into the mountain, and only a car on the spine leaves by the
## tunnel or the bridge. The map edge is still what `_has_left_the_field` recycles at. **The thing
## to watch is the pavement she is walking towards near an edge**: a body that turns round at the
## boundary instead of recycling is one fewer arriving from that side, and whether the edge
## streets read thinner for it is a played question rather than a tested one.
func _blocked_ahead(vertical: bool, direction: float, distance: float,
		from := Vector2.INF) -> bool:
	return cannot_go_on(vertical, _mover._tile_ahead(vertical, direction, distance, from))

## Whether the lane this car would land in has a car's length of road to spare where it would land.
##
## Walkers are exempt: two people on a pavement are not two cars in a lane, `space_out_the_traffic`
## has never looked at them, and there is nothing for this to prevent.
func _has_room_to_turn(crossing: int, turning: float) -> bool:
	if not _mover.traffic:
		return true
	var vertical := not _mover._vertical
	var lane := CrowdLanes.road_lane(vertical, turning)
	# After the turn the axes swap: what is currently the coordinate *across* this corridor becomes
	# the one *along* the new one, which is where in that queue the car would appear.
	var landing := _mover._cross() * turning
	return _mover.traffic.room_at(LaneMover.make_lane_key(vertical, crossing, lane, turning),
			landing, Tuning.CAR_GAP_MIN)

# -------------------------------------------------------------- car turns ---
# **A turn is a path a car has to be able to take, and both halves of that were missing.** It used
# to swap the axis and the lane in the frame it happened: the car was carried sideways across the
# carriageway by its own steering afterwards, and on the frame itself its heading jumped a right
# angle — or, turning round, a straight reversal — so the strike box, the horn and the picture all
# pointed somewhere the car had never been going. *(Playtest 53: "when a car turns or turns around
# it should make a proper turn".)*
#
# So a car now plans the whole manoeuvre before it starts it. `CarTurn` is the curve; everything
# here is the *deciding*: where the arc goes, whether the ground it sweeps is road the car may be
# on, whether the lane it lands in has room, and what it does when the answer is no.
#
# **What it does when the answer is no is stop.** A car that cannot fit a turn does not take a
# smaller one and does not fall back on the separation pass to repair it — it brakes for the
# blockage and stands there. See `_distance_to_the_blockage`.

## A car plans its way round the blockage ahead and commits to the whole of it before it moves.
##
## Called instead of the walker's `divert` body, and it takes the same two decisions in the same
## order: which arm of the junction (`_pick_an_arm`, unchanged, with the probes fired from the
## junction rather than from wherever the car is standing) and, when neither arm is open, the way it
## came. What is new is that each of those is now a *curve* that has to fit, so the order below is
## the order of preference among places to turn rather than a single answer:
##
## 1. **The arm it picked**, as a quarter turn taken from the junction's own carriageway entry.
## 2. **The other arm**, which is a wider arc — the far-side lane is three times the radius away —
##    and so fits in some junctions where the near one does not.
## 3. **An about-face in the middle of the junction box**, where the crossing street's own
##    carriageway is the room a half turn needs.
## 4. **An about-face in the street**, short of whatever is blocking it. This is the one manoeuvre
##    in the game whose swept body crosses a kerb, and it is a fact about the city rather than a
##    concession: the two lanes of a carriageway are 32px apart, so a half turn between them is a
##    16px arc and a car's own corners then reach 40px from the centre of it — 8px past a kerb that
##    is 32px away. There is no rounder way to do it, the alternative manoeuvre is a three-point
##    turn the traffic has no reverse gear for, and refusing it outright parks a third of the
##    traffic: measured over ninety seconds, stopped cars at the end went 10 → 33 of 34, because one
##    car nose-to-wall in a dead end takes its whole street with it. Nothing else is relaxed — the
##    wall, the closure, the seal and the building are all still refused.
func _plan_a_turn(delta: float) -> void:
	if _mover._turn:
		return
	_forget_the_last_plan()
	# Standing on ground it may not be on at all, which is a day that started behind a barrier. There
	# is no legal space to sweep and nothing to be gained by waiting for some, so the about-face on
	# the spot stays exactly what it was: the way out of a state that is already illegal.
	if not _mover._stands_on_a_street():
		turn_round_cause = TurnRoundCause.OFF_THE_STREET
		_mover._turn_round()
		return
	var band := GiveWay.box_index(_mover._along(), _mover._direction)
	if band < 0:
		return
	var box := _mover.junction_ahead()
	var probe := CarTurn.world(_mover._vertical, CarTurn.carriageway_centre(band), _mover._cross())
	var first := 1.0 if _mover._rng.randf() < 0.5 else -1.0
	var turning := _pick_an_arm(band, first, probe)
	if turning != 0.0:
		if _try_a_turn(TurnCandidate.NEAR_ARM, _arm_turn(band, turning, box)):
			return
		var other := _pick_an_arm(band, -turning, probe)
		if other != 0.0 and other != turning \
				and _try_a_turn(TurnCandidate.FAR_ARM, _arm_turn(band, other, box)):
			return
	if _try_a_turn(TurnCandidate.BOX_ABOUT_FACE, _about_face_at(CarTurn.carriageway_centre(band),
			box)):
		return
	var blockage := _distance_to_the_blockage()
	if blockage == INF:
		return
	# **Clamped to where the car already is, because an entry a hair behind it is not a tighter
	# arc.** A car that has braked for the barrier has come to rest at exactly this point, give or
	# take whatever fraction of a pixel its last frame bought, and a negative run-up sends the arc
	# to `tighten_to`, which an about-face can never satisfy — its radius is half the distance
	# between the two lanes and there is no other value that lands on one. Clamping makes the
	# question the one that actually matters: from here, is the ground the body sweeps still clear.
	if _try_a_turn(TurnCandidate.STREET_ABOUT_FACE,
			_about_face_at(_mover._along() + maxf(0.0, blockage - CarTurn.about_face_reach()) * _mover._direction,
			Vector2i(-1, -1)), true):
		return
	# **Nothing fits, and everything below is about the car that has run out of road to look with.** A
	# car still rolling keeps asking and nothing else happens to it, since a few pixels further on
	# the answer changes; one that has come to rest a half turn short of the barrier has arrived
	# where its own brake was aiming and has nowhere left to ask from.
	if _mover._speed >= Tuning.CAR_STOPPED_SPEED or _room_to_stop_in() >= nose:
		return
	# **But "no arc fitted this frame" is not "no arc can fit here".** The lane a half turn lands in
	# is the other side of this carriageway, and the traffic on it is going somewhere: a car standing
	# in the way of the landing is gone a moment later, and the arc that was refused for it fits on
	# the frame after that. So a temporary refusal is a reason to stand still and ask again rather
	# than a reason to give up on the manoeuvre — which is what the car is already doing anyway,
	# stopped at its own aim point with its followers queueing behind it exactly as they queue behind
	# any stopped car. See `TurnRefusal` for which refusals are which.
	#
	# **And the wait is bounded, which is the half that cannot be left out.** Waiting for a lane that
	# never clears is a car that never moves again, and a car that never moves again holds the
	# junction it is standing in and takes the whole street behind it: 33 of 34 cars at a standstill
	# in ninety seconds, measured, which is the reason this manoeuvre exists at all. See
	# `TURN_WAIT_SECONDS` for how long is long enough to tell passing traffic from a queue that is
	# waiting on something else.
	if _an_arc_may_yet_fit():
		_waited_to_turn += delta
		if _waited_to_turn < TURN_WAIT_SECONDS:
			return
	_waited_to_turn = 0.0
	# **And the way back has to be a way.** Reversing into a lane whose own road runs out inside a
	# half turn buys nothing: the car arrives in the same state pointing the other way, reverses
	# again a stride later, and what a player sees is a car shaking its head while the ordinary
	# cross-steer slides it between the two lane centres. A car with no road either way has nowhere
	# to go at all, which the crowd already has an answer for — it stands, and leaves once nobody
	# can see it go. See `nowhere_to_turn`.
	if _no_road_the_other_way():
		nowhere_to_turn = true
		return
	turn_round_cause = TurnRoundCause.STOPPED_NO_ROOM
	_mover._turn_round()

## How long a car waits for the lane a half turn lands in to clear before it gives up and reverses
## where it stands.
##
## **The number is what the car in the way costs, and anything longer is waiting on a queue.** What
## is standing on the landing is almost always the car that turned round just before this one, so
## what it has to do is clear its own minimum gap from a standing start, and the speed it does that
## at is the speed a turn is taken at. A landing still taken after that long is taken by something
## that is not driving away at all — and a car that waits on a stopped car is the beginning of a
## deadlock, which is the failure this whole manoeuvre exists to avoid.
const TURN_WAIT_SECONDS := Tuning.CAR_GAP_MIN / Tuning.CAR_TURN_SPEED

## Whether any arc the planner has just tried was turned away by something that will move on its
## own. See `TurnRefusal`: a lane that is occupied empties, and nothing else on that list does.
func _an_arc_may_yet_fit() -> bool:
	for slot in turn_refusals.size():
		if turn_refusals[slot] == TurnRefusal.LANDING_TAKEN:
			return true
	return false

## Whether the lane this car would reverse into has less road in front of it than a half turn needs,
## measured from that lane's own centre line and in the direction the car would then be pointing.
##
## Asked before the reversal rather than discovered after it, because discovering it after is the
## flicker: the reversal costs a stride (`_turn_round()`), the stride runs out, the state is
## unchanged, and the car reverses again for ever.
func _no_road_the_other_way() -> bool:
	var lane := CrowdLanes.road_lane(_mover._vertical, -_mover._direction)
	var centre := CrowdLanes.lane_centre(_mover._corridor, lane)
	var from := _mover._map.world_to_tile(CarTurn.world(_mover._vertical, _mover._along(), centre))
	var step := (Vector2i.DOWN if _mover._vertical else Vector2i.RIGHT) * -int(signf(_mover._direction))
	var needed := ceili((CarTurn.about_face_reach() + nose) / float(Tuning.TILE_SIZE))
	for i in range(1, needed + 1):
		if cannot_go_on(_mover._vertical, from + step * i):
			return true
	return false

## Empties the record of what the planner last decided, so that every entry in it is about the run
## that is about to happen rather than a leftover from the approach before.
func _forget_the_last_plan() -> void:
	turn_round_cause = TurnRoundCause.NONE
	# Re-established below or not at all, so a car whose way out opened again is never left carrying
	# a reason to be recycled that stopped being true.
	nowhere_to_turn = false
	if turn_refusals.size() != TurnCandidate.size():
		turn_refusals.resize(TurnCandidate.size())
	turn_refusals.fill(TurnRefusal.NOT_TRIED)

## Tries one candidate arc, writes down what happened to it, and says whether the car took it.
func _try_a_turn(slot: TurnCandidate, turn: CarTurn, over_the_kerb := false) -> bool:
	var refusal := _commit_to_a_turn(turn, over_the_kerb)
	turn_refusals[slot] = refusal
	return refusal == TurnRefusal.FITS

## The half turn back down the other lane, taken at a given point along this corridor.
func _about_face_at(at_along: float, box: Vector2i) -> CarTurn:
	return CarTurn.about_face(_mover._vertical, _mover._direction, _mover._corridor, _mover._lane, _mover._cross(), at_along,
			CrowdLanes.road_lane(_mover._vertical, -_mover._direction), box)

## The arc into one arm of the junction ahead. The lane it lands in is the one on its own right for
## the way it will then be pointing, which is the **new** axis's answer — driving on the right flips
## with the axis, exactly as it did when this was a lane swap.
func _arm_turn(band: int, turning: float, box: Vector2i) -> CarTurn:
	return CarTurn.into_an_arm(_mover._vertical, _mover._direction, _mover._corridor, _mover._cross(), band,
			CrowdLanes.road_lane(not _mover._vertical, turning), turning, box)

## Takes a planned turn if it fits, and says what turned it away if it does not.
##
## Three things have to be true, and none of them is revisited afterwards: there is a straight
## run-up to the arc rather than the arc starting behind the car, the ground the body sweeps is road
## it may drive on, and the lane it lands in has a car's length free. The room is then *held* for
## every frame of the manoeuvre, run-up included, so nothing else turns or recycles into the piece of
## road this car is already committed to.
##
## **Which check said no is part of the answer rather than a diagnostic afterthought**, because the
## caller's next move depends on it: the lane the arc lands in empties by itself and the ground it
## sweeps does not. See `TurnRefusal`.
func _commit_to_a_turn(turn: CarTurn, over_the_kerb := false) -> TurnRefusal:
	var run_up := (turn.entry_along - _mover._along()) * _mover._direction
	# Further off than the car watches a junction from is further off than it can know the road is
	# still going to be clear when it gets there.
	if run_up > Tuning.CAR_JUNCTION_SIGHT:
		return TurnRefusal.OUT_OF_SIGHT
	# **The run-up is driving, and it has to be legal driving.** Only the arc's own ground is swept
	# and checked; the straight before it is ordinary lane travel, so what says whether it is clear
	# is the lookahead. Without this a car blocked in mid-street plans for the junction *beyond* the
	# barrier — `GiveWay.box_index()` names the one it is heading for — and drives through the barrier
	# to reach it.
	if run_up > _distance_to_the_blockage():
		return TurnRefusal.PAST_THE_BLOCKAGE
	if run_up < 0.0:
		# Past the entry the geometry would have chosen — a car that only found out it was turning
		# once it was already in the box. What is left of the junction is a tighter arc, and one
		# tighter than `CarTurn.CAR_TURN_RADIUS_MIN` is refused rather than squeezed.
		if not turn.tighten_to(_mover._along(), _mover._cross()):
			return TurnRefusal.TOO_TIGHT
		run_up = 0.0
	if not _the_ground_a_turn_sweeps_is_clear(turn, over_the_kerb):
		return TurnRefusal.SWEEP_BLOCKED
	if not _the_exit_has_room_to_leave(turn):
		return TurnRefusal.EXIT_PLUGGED
	if not _has_room_to_land(turn):
		return TurnRefusal.LANDING_TAKEN
	_mover._turn = turn
	_mover._turn_run_up = run_up
	turned_on_this_approach = true
	_waited_to_turn = 0.0
	_claim_the_turn()
	return TurnRefusal.FITS

## Moves this car along its own planned turn: the straight run-up first, then the arc.
##
## **The frame that changes over from one to the other splits its travel between them**, so the car
## covers exactly `speed × delta` on it like every other frame and starts curving from the entry
## point rather than from wherever the last straight step happened to leave it. The same split
## happens at the far end, where what is left over is spent going straight down the new lane.
func _follow_the_turn(delta: float) -> void:
	var travel := _mover._speed * delta
	if _mover._turn_run_up > 0.0:
		var straight := minf(travel, _mover._turn_run_up)
		_mover._set_along(_mover._along() + straight * _mover._direction)
		_mover._set_cross(move_toward(_mover._cross(), _mover._lane_centre, LaneMover.STEER_SPEED * delta))
		_mover._turn_run_up -= straight
		travel -= straight
		if _mover._turn_run_up > 0.0:
			return
		# The arc is put on the car rather than the car on the arc: whatever fraction of a pixel it
		# is off its own lane centre is where the curve begins. A quarter turn still lands on its
		# exit lane exactly — see `CarTurn.begin_at`.
		_mover._turn.begin_at(_mover._cross())
	_mover._turn.travelled += travel
	if _mover._turn.travelled < _mover._turn.length():
		_mover.position = _mover._turn.point_at(_mover._turn.travelled)
		_mover.place_its_move()
		return
	var overshoot := _mover._turn.travelled - _mover._turn.length()
	_land_the_turn()
	_mover._set_along(_mover._along() + overshoot * _mover._direction)

## The end of a turn: the car takes up the axis, corridor, lane and direction it turned into.
##
## It is standing on the exit lane's own centre line, pointing along it, because that is where the
## arc ends — so there is nothing to steer back to and nothing that has to be spaced out. The
## lookahead is thrown away, since it is a cached answer about an axis this car no longer has.
##
## **The arrival stands where its own arc ended and nothing moves it off that point.** It is the
## point `_has_room_to_land()` checked before the car committed, `_claim_the_turn()` has held in
## `TrafficIndex` on every frame of the manoeuvre since, and `Crowd._keep_room_for_the_turning()`
## has been braking the exit lane's nearest follower for. **The room a turn needs is checked before
## the arc starts or the turn is not taken** — there is nothing left for the landing frame to
## decide.
##
## What can still be too close when the car gets there is that **follower**, and only ever from
## behind: a brake aims at a point and arrives late, so it settles a little inside
## `Tuning.CAR_GAP_MIN` rather than outside it. A body too close behind the arrival is the queue's
## business and the queue already has the rule for it —
## `Crowd.space_out_the_traffic()` resolves front to back and moves the car *behind*, by the
## overlap. **Sending the arrival to `join_the_back_of_the_queue()` instead is the trap here**: it
## drops the car a gap behind the **rearmost** car in the whole lane, which is where a recycled car
## belongs — at the entry band, with nothing but off-screen road behind it — and is most of a street
## behind a junction the player is watching. A car that drives a visible arc and then disappears
## backwards past every other car in the street is a manoeuvre being repaired after the fact, which
## is the one thing a turn may not rest on.
##
## The booking is handed back all the same, because `_claim_the_turn()` has been writing this car's
## own reservation into the index every frame and nothing else would ever take it out — a lane that
## kept it would refuse the next car to turn into that piece of road for the rest of the day. See
## `TrafficIndex.give_back()`.
func _land_the_turn() -> void:
	if _mover.traffic:
		_mover.traffic.give_back(_mover.turn_lane_key(), _mover._turn.landing())
	_mover.position = _mover._turn.point_at(_mover._turn.length())
	_mover.place_its_move()
	_mover._vertical = _mover._turn.exit_vertical
	_mover._corridor = _mover._turn.exit_corridor
	_mover._lane = _mover._turn.exit_lane
	_mover._direction = _mover._turn.exit_direction
	_mover._junction = _mover._turn.entry_corridor
	_mover._turn = null
	_mover._turn_run_up = 0.0
	_mover._lane_centre = _mover._lane_centre_here()
	_mover._forget_the_detour()
	_mover._scan_at = Vector2i(-9999, -9999)
	claim_the_road_here()

## Whether every tile the car's own body passes over during the arc is road it may drive on.
##
## **The car's body is the datum** — the 52×28px rectangle whose front half is the strike box — swept along the
## curve and sampled at its own corners and the points between them. It is deliberately the same
## rectangle the game already tells the player is the dangerous part of a car, rather than a second
## footprint nobody can see.
##
## What it adds to `cannot_go_on` is the **kerb**. Going straight, a car is kept off the pavement by
## lane arithmetic and `cannot_go_on` never had to say so — a sidewalk tile is a perfectly good
## street. A curve has no lane to be in the middle of, so the pavement has to be refused explicitly
## or the first tight turn puts a car's back wheels through a bus queue.
##
## `over_the_kerb` is the one exemption, and it is only ever granted to the about-face of last
## resort: see `_plan_a_turn` for why a half turn between two lanes of one carriageway cannot be
## contained by it. Everything a car may not *be* on — a wall, a closure, a seal, a precinct's
## paving, the ground outside the map — is refused either way.
func _the_ground_a_turn_sweeps_is_clear(turn: CarTurn, over_the_kerb: bool) -> bool:
	var seen := {}
	var length := turn.length()
	var steps := maxi(1, ceili(length / TURN_SWEEP_STEP))
	for i in steps + 1:
		var at := length * float(i) / float(steps)
		var centre := turn.point_at(at)
		var forward := turn.heading_at(at)
		var side := Vector2(-forward.y, forward.x)
		for a in TURN_BODY_SAMPLES.x:
			var along := lerpf(-1.0, 1.0, float(a) / float(TURN_BODY_SAMPLES.x - 1))
			for b in TURN_BODY_SAMPLES.y:
				var across := lerpf(-1.0, 1.0, float(b) / float(TURN_BODY_SAMPLES.y - 1))
				var tile := _mover._map.world_to_tile(centre
						+ forward * (along * Tuning.CAR_STRIKE_HALF_LENGTH)
						+ side * (across * Tuning.CAR_STRIKE_HALF_WIDTH))
				if seen.has(tile):
					continue
				seen[tile] = true
				if _cannot_drive_over(tile, over_the_kerb):
					return false
	return true

## How finely the swept body is sampled: a pose every `TURN_SWEEP_STEP` px of arc, and the strike
## box itself on a grid that includes its own four corners.
##
## Four pixels is a seventh of the tightest arc's own quarter turn, which is fine enough that the
## body cannot pass a whole tile between two poses. It is not free — a rejected turn is a hundred-odd
## tile questions — but a turn is a thing a car does a few times a minute, not a thing it does every
## frame, and the tiles are deduplicated because consecutive samples mostly land on the same one.
const TURN_SWEEP_STEP := 4.0

const TURN_BODY_SAMPLES := Vector2i(5, 3)

## Whether a tile is carriageway this car may sweep over: open today, in bounds, not a precinct's
## paving, and road rather than pavement. See `_the_ground_a_turn_sweeps_is_clear` for why the last
## one is asked here and nowhere else.
func _cannot_drive_over(tile: Vector2i, over_the_kerb: bool) -> bool:
	if cannot_go_on(_mover._vertical, tile):
		return true
	return not over_the_kerb and not Tile.is_road(_mover._map.tile_at(tile))

## Whether there is enough road past the end of the arc for the car to have got itself out of the
## turn — *nothing enters a junction it cannot leave*, asked of the street it is leaving into.
##
## **The arm a car picks is probed with a single point seven tiles out, and a single probe looks
## straight past a two-tile plug** — the same aliasing `_look_ahead` walks tiles to avoid. That was
## harmless while a car could reverse its heading wherever it stood: it turned into the cul-de-sac,
## met the plug and flipped. It is not harmless now, because a car that lands nose-to-wall has no
## room left to swing round in and stands there for the rest of the day, holding the junction it
## came through shut and taking the whole street behind it with it — measured, that one hole put
## 33 of 34 cars at a standstill inside ninety seconds.
##
## Stated over the room a *turnaround* needs rather than over some tile count: a car that can still
## turn round is never stuck, whatever it finds later.
func _the_exit_has_room_to_leave(turn: CarTurn) -> bool:
	var end := turn.point_at(turn.length())
	var forward := turn.heading_at(turn.length())
	var step := Vector2i(roundi(forward.x), roundi(forward.y))
	var needed := ceili((CarTurn.about_face_reach() + nose) / float(Tuning.TILE_SIZE))
	var here := _mover._map.world_to_tile(end)
	for i in range(1, needed + 1):
		if _cannot_drive_over(here + step * i, false):
			return false
	return true

## Whether the lane a planned turn lands in has a car's length of road to spare where it lands.
##
## The landing is the arc's own end point rather than the approximation `_has_room_to_turn` makes
## for the *preference* between two arms — those are the same question asked for different purposes,
## one to choose between arms and this one to refuse a turn outright, and this one knows exactly
## where the car will be standing.
func _has_room_to_land(turn: CarTurn) -> bool:
	if not _mover.traffic:
		return true
	return _mover.traffic.room_at(LaneMover.make_lane_key(turn.exit_vertical, turn.exit_corridor, turn.exit_lane,
			turn.exit_direction), turn.landing(), Tuning.CAR_GAP_MIN)

## Holds the piece of road a committed turn is going to land on, once a frame for as long as the
## manoeuvre lasts.
##
## **Two cars can commit to the same piece of road in one frame** — the index they both read is
## rebuilt once a frame and predates both of them — which is the same hole `TrafficIndex.claim()`
## closes for recycling, and a turn is the case where it is worst: the reservation has to outlive
## the whole manoeuvre rather than one frame, because the car is not in that lane yet and nothing
## else would put it in the index. Re-made every frame, since every rebuild throws it away.
func _claim_the_turn() -> void:
	if not _mover.traffic or not _mover._turn:
		return
	_mover.traffic.claim(_mover.turn_lane_key(), _mover._turn.landing())

## How far this car has to the near edge of the first thing it cannot drive past, or `INF` when the
## road ahead is clear as far as it looks: a tile it cannot go on, or a parked figure in its lane
## (`road_before_a_parked_figure()`, inbox #909), which it turns round at the same way.
##
## **Braking for it is what makes a turnaround possible at all.** Nothing used to brake for a
## blockage, because reversing the heading on the spot was always available however close the wall
## was. A car that has to swing round needs road to swing into, so `_room_to_stop_in` is what the
## brake actually aims at and this is the distance under it.
func _distance_to_the_blockage() -> float:
	# Nothing to answer on the arc itself: the lookahead is a cached scan down the lane the car has
	# left, and the ground the curve covers was checked before it started.
	if _mover._turn and _mover._turn_run_up <= 0.0:
		return INF
	var figure := road_before_a_parked_figure()
	if _mover._blocked_in > LaneMover.LOOKAHEAD_TILES:
		return figure
	var here := floori(_mover._along() / float(Tuning.TILE_SIZE))
	var tile := here + _mover._blocked_in * signi(int(_mover._direction))
	var edge := float(tile * Tuning.TILE_SIZE)
	if _mover._direction < 0.0:
		edge += float(Tuning.TILE_SIZE)
	return minf(figure, maxf(0.0, (edge - _mover._along()) * _mover._direction - nose))

## Where a car braking for a blockage aims to come to rest: a half turn's worth of road short of it,
## so that a car which has to turn round has somewhere to do it. A driver meeting a dead end stops a
## car's length off the wall rather than nosing into it, and for the same reason.
func _room_to_stop_in() -> float:
	# **Not while a turn is committed**, and this is the difference between a car that turns round at
	# a dead end and one that creeps to a halt just short of turning round: the two brakes aim at the
	# same point, and a car easing to *zero* there never reaches the entry it was easing toward. The
	# turn's own brake is what governs the approach once there is a turn, and the road it runs over
	# was checked before the car committed.
	if _mover._turn:
		return INF
	var blockage := _distance_to_the_blockage()
	if blockage == INF:
		return INF
	return maxf(0.0, blockage - CarTurn.about_face_reach() - TURN_ROOM_MARGIN)

## How much more road than the arc needs a car aims to leave itself when it brakes for a barrier.
##
## **A manoeuvre that fits exactly does not fit.** The brake aims at a point and arrives a frame
## late, the sweep is sampled rather than solved, and both of those are worth a fraction of a pixel
## — so a car that comes to rest with precisely `CarTurn.about_face_reach()` in front of it finds
## its own about-face refused, either as an arc starting behind the car or as a swept body clipping
## the tile the barrier is on. Stated as the slack the geometry already has: a 28px body in a 32px
## lane, which is the one spare distance anywhere in a turn and the same four pixels the arc's own
## entry is offset by where it swings its tail toward its kerb.
const TURN_ROOM_MARGIN := float(Tuning.TILE_SIZE) - 2.0 * Tuning.CAR_STRIKE_HALF_WIDTH

## Whether this car has gone further past the edge of the map than it may before it stops existing.
##
## **Nothing vanishes while you are looking at it** — the rule written for events, arriving at the
## crowd. A recycle normally happens at the edge of a box nowhere near anything the player can see;
## the three holes in the boundary are exactly where that is not true, because a car reaching the
## bridge is at the one place in the city that is *about* leaving.
##
## **A tile for everybody else, and that is not stinginess.** Outside the map is water, forest and
## mountainside — painted ground with no road on it — so a car allowed to overrun anywhere would
## drive into the sea. The spine is the exception because it is the only place the carriageway
## carries on through the border: `City._paint_outside_the_map` puts road out there at the spine's
## own width and nowhere else, and `CityEdge` is the tunnel and the bridge standing over it.
## Walkers keep the tile for the same reason — the pavements do not carry on, only the road does.
##
## **And on the spine the two ends differ, because what is out there differs.** North is a tunnel:
## a car heading out goes out of existence once its whole body is inside the mouth
## (`TUNNEL_ROOM`), never driving on across the mountain over it. South is a bridge whose deck
## runs `BRIDGE_RUN` out over the water, so a car stays on the deck for as long as any view could
## show it.
##
## Heading out, a spine car goes at the departure depth; heading in, it is still arriving and keeps
## the entry depth, or it would be recycled the frame after it came into existence.
func has_left_the_map(at: float, limit: float) -> bool:
	var north_room := float(Tuning.TILE_SIZE)
	var south_room := north_room
	if _mover._map.is_main_road(_mover._vertical, _mover._corridor):
		north_room = entry_room(false) if _mover._direction > 0.0 else TUNNEL_ROOM
		south_room = BRIDGE_RUN
	return at < -north_room or at > limit + south_room

## How far past the map's north edge a car departing into the tunnel exists: the depth of the
## dark opening (`CityEdge.TUNNEL_DEPTH_TILES`, opaque at its far end) plus half a car, so the
## car's rear is inside the dark before the car stops existing.
const TUNNEL_ROOM := float(CityEdge.TUNNEL_DEPTH_TILES * Tuning.TILE_SIZE) \
		+ Tuning.CAR_STRIKE_HALF_LENGTH

## How far past the map's south edge a car on the spine exists: the length of the bridge deck
## (`CityEdge.BRIDGE_DECK_PX`) less a car, so it is never driving off the end of the deck.
const BRIDGE_RUN := CityEdge.BRIDGE_DECK_PX - 2.0 * Tuning.CAR_STRIKE_HALF_LENGTH

## How far past the north edge a car coming out of the tunnel may be put: the roof over the
## portal (`CityMap.OUTSIDE_DEPTH_TILES` rows of mountain drawn over the traffic) less half a car,
## so it exists only under the roof or in the dark, never in the open. `TUNNEL_ROOM` is how
## shallow it may be put: front and rear already inside the opaque dark.
const TUNNEL_ENTRY_ROOM := float(CityMap.OUTSIDE_DEPTH_TILES * Tuning.TILE_SIZE) \
		- Tuning.CAR_STRIKE_HALF_LENGTH

## How far past the south edge a car coming onto the bridge is put at the least: further than
## the player's camera reaches past the edge (half the view's height, the look-ahead and a car),
## so a car is never put onto the deck where anybody standing at the map's edge can see it arrive.
const BRIDGE_ENTRY_MIN := Tuning.VIEW_HALF_EXTENT.y + Stroller.CAMERA_LOOK_AHEAD \
		+ 2.0 * Tuning.CAR_STRIKE_HALF_LENGTH + 24.0

func _spine_room(south: bool) -> float:
	return BRIDGE_RUN if south else TUNNEL_ENTRY_ROOM

## Pushes a spine car that has just rolled its entry past the map's edge out of anybody's sight:
## into the tunnel's dark and no deeper than the roof, or beyond the camera on the bridge deck.
func hide_the_spine_entry() -> void:
	if not _mover._map.is_main_road(_mover._vertical, _mover._corridor):
		return
	var extent := _mover._map.world_size()
	var limit: float = extent.y if _mover._vertical else extent.x
	var at := _mover._along()
	if _mover._direction > 0.0 and at < 0.0:
		_mover._set_along(minf(at, -TUNNEL_ROOM))
	elif _mover._direction < 0.0 and at > limit:
		_mover._set_along(maxf(at, limit + BRIDGE_ENTRY_MIN))

## How far past the true edge a **fresh** recycle may land. Departures have their own room in
## `has_left_the_map()`: ordinary agents get one tile, northbound cars stop inside the dark.
##
## **A departure's tile of slack is never seen**: it happens at the edge of the field's own box,
## hundreds of pixels from the camera, so the one frame it is a tile into the scree changes
## nothing anybody is looking at. An entry is the one placement that can be the very first frame
## on screen, and the plain boundary is exactly where a player standing at the edge of the map is
## looking — so an ordinary walker or car may not land past it at all. A car arriving on the
## spine instead lands beneath the tunnel roof or on the bridge deck, where the entry placement
## can keep its complete picture out of the player's view until it moves into sight.
func entry_room(south: bool) -> float:
	if not _mover._map.is_main_road(_mover._vertical, _mover._corridor):
		return 0.0
	return _spine_room(south)

## Drops a **recycled** car in behind whatever is already in its lane, when the entry point it
## rolled is not free. Nothing at all if it landed somewhere free, which is almost always.
##
## **`_recycle()` is the only caller, and where a recycle happens is the whole of why this is
## right.** An entry point is rolled six times against `TrafficIndex` and can still miss, and a car
## standing where another one already is leaves the separation pass the one thing it can do — shunt
## everybody *behind* it back by the overlap **plus** everything already moved in front of them,
## which compounds front to back so that one arrival rearranges a whole queue. Behind the last car
## is the one place in a lane that is free by construction, and moving the arrival there is the only
## correction that touches nobody else.
##
## It may put the car further back than the entry band is deep, which is exactly right **here**:
## further back is further off screen, and the alternative is a car appearing inside another one.
## That sentence is also the whole of why a turn's landing does not come through here — see
## `_land_the_turn()`, where further back is a junction the player is looking straight at.
##
## **Never past ground it could not have driven onto itself**, for the same reason `nudge_back`
## checks it: the rearmost car's own position says nothing about what stands behind it, and a queue
## that has backed up almost to a wall would otherwise place the newcomer inside it. Refusing the
## move leaves the car where it already is, which is the position this fallback exists to improve on
## rather than one it has to guarantee.
func join_the_back_of_the_queue() -> void:
	if not _mover.traffic or has_room_here():
		return
	var last := _mover.traffic.rearmost(_mover.lane_key())
	if last == INF:
		return
	var target := (last - Tuning.CAR_GAP_MIN) * _mover._direction
	var probe := Vector2(_mover._cross(), target) if _mover._vertical \
			else Vector2(target, _mover._cross())
	if cannot_go_on(_mover._vertical, _mover._map.world_to_tile(probe)):
		return
	_mover._set_along(target)

## Tells the index this car is here, so that another one recycling or turning later in the same
## frame does not choose the same piece of road. See `TrafficIndex.claim()`.
func claim_the_road_here() -> void:
	if not _mover.traffic:
		return
	_mover.traffic.claim(_mover.lane_key(), _mover.queue_position())

## Whether this car is standing in a piece of its own lane that no other car is in.
func has_room_here() -> bool:
	if not _mover.traffic:
		return true
	return _mover.traffic.room_at(_mover.lane_key(), _mover.queue_position(), Tuning.CAR_GAP_MIN)

## Whether this car's own centre may be on a tile: its whole predicate, the same one its
## look-ahead and its turns use.
func may_stand_on(tile: Vector2i) -> bool:
	return not cannot_go_on(_mover._vertical, tile)

## Whether a *tile* is somewhere this car may be. The predicate under the look-ahead, the turns and
## the queue's nudges, so "the way is shut" means one thing however it is asked.
##
## **It is two questions stacked and the order is the useful part.** `_never_a_street_here()` is the
## city — the lattice, the map's edge, a precinct's paving — and is true of a tile on every day of
## the run; everything after it is what *today* has placed on ground this car could otherwise
## travel.
func cannot_go_on(vertical: bool, tile: Vector2i) -> bool:
	if _never_a_street_here(vertical, tile):
		return true
	if not _mover._map.passable(tile, _closed_today):
		return true
	# A street held for today has a hard seal, a region wall or a closure's barriers standing across
	# the whole of it somewhere along its length. **That is a car's warning** — see
	# `_segment_is_shut`: a car has to turn at the last junction because it cannot turn round
	# against a barrier. A region door is carved out: it is a crossing the day means to keep open,
	# not a wall with a picture on it, and a car queues for its boom.
	if _mover._segment_is_shut(tile):
		return true
	# A stationary solid body standing in the street — a café, a construction band, a kerbed van.
	# **A car has nowhere to step**: one lane per direction and the oncoming one is not an option,
	# so a body on its own lane tile is a wall to it and it turns at the last junction the way it
	# does for a closure. The oncoming lane is a different tile and is untouched, which is the whole
	# difference between a body and a seal. A soft seal takes only the pavements, so it is not
	# asked here.
	return not _mover._map.passable(tile, _car_today)

## Whether a tile is ground a car could never travel, whatever today has or has not placed on it:
## off the map, not a street at all, or a precinct.
##
## **Out of bounds is blocked**, with one exception: a car on the spine's own corridor
## (`_map.main_road`) leaving by the tunnel to the north or the bridge to the south, the two edges
## `City._spawn_spine_exits` places them at — `CityEdge` draws the carriageway going on there, and
## nowhere else does the border carry a road. Stated over which edge and which corridor rather than
## over "vertical and out of bounds", because the spine is the one corridor this is true of, not
## every vertical one.
##
## **And a precinct is a wall to a car and a street to everybody else.** The tile map cannot say
## so — it is paving either way — so the street kind has to, or a car reaching the three blocks of a
## precinct drives onto them instead of turning off.
func _never_a_street_here(vertical: bool, tile: Vector2i) -> bool:
	if not _mover._map.in_bounds(tile):
		var leaves_by_the_spine := _mover._map.is_main_road(vertical, _mover._corridor) \
				and (tile.y < 0 or tile.y >= _mover._map.size.y)
		return not leaves_by_the_spine
	if not _mover._map.is_driveable_at(vertical, tile):
		return true
	return not _mover._map.is_street(tile)

## Traffic goes round a closure, and that is half of what makes one legible: the street with
## nobody on it is the street that is shut, which reads from a block away — further than the
## barrier itself does. A car that carried on would drive through the barrier, and a car that
## vanished at the junction would be worse: at this population something popping out of existence
## is very visible. **A car plans a curve** — see `_plan_a_turn`.
func divert(delta: float) -> void:
	_plan_a_turn(delta)

## Which way to turn out of `crossing`, trying `first` before the other one, or `0.0` for neither.
##
## Two questions and they are not the same question. **Can it go that way at all** is the tile map,
## and an arm that fails it is not an option — never a street, or shut for the day, since an arm a
## car cannot get out of is a car parked there for the rest of the day. **Is there room** is the
## other cars, and an arm that fails *that* is a bad option rather than no option.
##
## **The second one exists because a turn is a placement.** It takes the coordinate the car had
## along its old corridor and makes it the one it has across the new one, so the car materialises
## somewhere in another queue — and the separation rule then resolves the overlap the only way it
## can, by moving a body. Front-to-back, so the shortfall cascades down the queue behind it and a
## car is jumped backwards by up to six of its own lengths in a single frame. Off screen at the
## entry band that is exactly what it is for; at a junction the player is looking at, it is a car
## vanishing.
##
## Preferring rather than requiring, because a car that refuses to turn drives into the barrier it
## was avoiding. When both arms are full it takes the first one anyway and the resolve does what it
## can — which makes the jump the rare case instead of the usual one.
##
## `from` is where the two probes are fired from, and it matters because a car asks this question
## **before** it reaches the junction rather than from inside it: fired from where the car happens
## to be standing, a probe across the axis lands in the block beside it and reports both arms shut.
func _pick_an_arm(crossing: int, first: float, from := Vector2.INF) -> float:
	# A precinct is not an arm a car has. Neither of the two questions below would catch it: it is
	# paved end to end, so the tile map says it is a street, and there is never a car in it to
	# leave no room. A car with nowhere else to go turns round instead, which is what a driver
	# meeting a bollarded street actually does.
	if not _mover._map.is_driveable(not _mover._vertical, crossing,
			floori(_mover._cross() / float(Tuning.TILE_SIZE))):
		return 0.0
	var open: Array[float] = []
	for turning: float in [first, -first]:
		if not _blocked_ahead(not _mover._vertical, turning, LaneMover.LOOKAHEAD, from):
			open.append(turning)
	if open.is_empty():
		return 0.0
	for turning in open:
		if _has_room_to_turn(crossing, turning):
			return turning
	return open[0]
