class_name CarTurn
extends RefCounted
## The curve a car follows out of the lane it is in and into the lane it is turning into.
##
## **A turn is a path, not a swap.** Changing the axis and the lane in one frame carries a car
## sideways across a carriageway and points it somewhere it has never travelled, so everything that
## reads the heading on that frame — the strike box, the horn, the shadow, the picture — reads
## something untrue. One circular arc is the whole of the alternative: tangent to the lane the car
## is in where it starts and tangent to the lane it is joining where it ends, so position and
## heading are continuous by construction and the exit lane is landed on exactly rather than
## steered toward afterwards.
##
## **The radius is geometry, not a dial.** An arc tangent to both lanes has one free parameter, and
## fixing it by where the arc *starts* — the near edge of the junction's carriageway — is what makes
## a turn sit inside the box it is taken in: the near-side arm is then a 16px radius and the far-side
## one 48px, because a lane centre is 16px from its own kerb and the two lanes are 32px apart. An
## about-face is the same statement with no choice left in it at all: the two lanes of one
## carriageway are 32px apart, so the semicircle joining them has a 16px radius and nothing else.
##
## Nothing here knows about the map. **Whether an arc fits is `CrowdAgent`'s question**, asked of the
## swept strike box before the car commits to it, because the answer is about ground rather than
## about geometry.

## The axis the car is travelling along when the arc begins, and which way it points along it.
var entry_vertical := false
var entry_direction := 1.0
## The corridor it is travelling down, which it is still inside for the whole of the turn.
var entry_corridor := 0

## Where the arc begins, as the entry corridor's own *along* coordinate. The car drives straight to
## this point in its own lane and starts curving exactly there, so the run-up is ordinary lane
## travel and the arc is the only part that is a turn.
var entry_along := 0.0
## Which way across its own corridor the arc bends, as +1 or -1 on the entry corridor's *cross*
## axis. The centre of the circle lies that way, one radius off.
var cross_sign := 1.0

var centre := Vector2.ZERO
var radius := 0.0
## Radians of arc: a quarter turn into an arm, a half turn for an about-face.
var sweep := 0.0
## Which way round the centre the car goes: +1 when the centre is on its right, in the same screen
## sense as `Crowd._is_to_the_right_of` — y points south, so the right of a heading is a quarter
## turn clockwise on screen.
var spin := 1.0
var start_angle := 0.0

## What the car becomes when the arc ends: the axis, corridor, lane and direction it takes up.
var exit_vertical := false
var exit_corridor := 0
var exit_lane := 0
var exit_direction := 1.0

## The junction box this turn happens in, as `CityMap.junction_at` names one. What holds the box
## shut against everybody else for as long as the car is in it.
var junction := Vector2i(-1, -1)

## How far along the arc the car has come, in px. The one piece of state here that moves.
var travelled := 0.0

## The quarter turn out of one corridor into an arm of the junction ahead.
##
## `cross` is where the car sits across its own corridor — its lane centre, near enough, and the arc
## is rebuilt on the car's true position at the instant it starts (`begin_at`), so a car a pixel off
## its lane still ends exactly on the lane it is joining.
static func into_an_arm(vertical: bool, direction: float, corridor: int, cross: float,
		band: int, lane: int, turning: float, box: Vector2i) -> CarTurn:
	var turn := CarTurn.new()
	# The lane the car is joining runs across the corridor it is in, so its centre is a coordinate
	# on the *along* axis: the arc has to reach it and be pointing along the new corridor there.
	var lane_along := CrowdLanes.lane_centre(band, lane)
	var entry := carriageway_edge(band, direction)
	# **A car's back swings to the outside of its turn**, and on the arm that turns *away* from its
	# own kerb the outside is that kerb. Beginning the arc at the carriageway's edge then drags the
	# tail over the pavement of the street it is still leaving — two pixels of it, measured, which is
	# all a 28px body in a 32px lane has to give. So that arm waits until the tail is past the kerb,
	# which is a body's half length into the junction, and takes the tighter arc that follows from
	# it. The other arm swings its tail into the far lane, which is road, and starts at the edge.
	if turning == -kerb_side(CrowdLanes.road_lane(vertical, direction)):
		entry += direction * Tuning.CAR_STRIKE_HALF_LENGTH
	turn.radius = absf(lane_along - entry)
	turn.sweep = PI * 0.5
	turn.entry_vertical = vertical
	turn.entry_direction = direction
	turn.entry_corridor = corridor
	turn.entry_along = lane_along - direction * turn.radius
	turn.cross_sign = turning
	turn.exit_vertical = not vertical
	turn.exit_corridor = band
	turn.exit_lane = lane
	turn.exit_direction = turning
	turn.junction = box
	turn.begin_at(cross)
	return turn

## The about-face: out of one lane of a carriageway and back down the other.
##
## **The radius has no slack in it at all**: the two lanes are 32px apart, so the semicircle joining
## them is 16px and there is no other value that both starts on one lane and ends on the other. That
## is what makes where it is taken the only question — see `about_face_reach()` for how much road it
## swallows, and `CrowdAgent._plan_a_turn` for the order the places are tried in. This only says
## where the arc goes.
static func about_face(vertical: bool, direction: float, corridor: int, from_lane: int,
		cross: float, at_along: float, lane: int, box: Vector2i) -> CarTurn:
	var turn := CarTurn.new()
	# Between the two lane *centres* rather than from wherever the car is sitting: the radius is
	# what decides where the arc ends, and it has to end on the lane rather than one drift off it.
	var across := CrowdLanes.lane_centre(corridor, lane) - CrowdLanes.lane_centre(corridor, from_lane)
	turn.radius = absf(across) * 0.5
	turn.sweep = PI
	turn.entry_vertical = vertical
	turn.entry_direction = direction
	turn.entry_corridor = corridor
	turn.entry_along = at_along
	turn.cross_sign = signf(across)
	turn.exit_vertical = vertical
	turn.exit_corridor = corridor
	turn.exit_lane = lane
	turn.exit_direction = -direction
	turn.junction = box
	turn.begin_at(cross)
	return turn

## Puts the arc on the car's actual cross position, which is what makes the start of it continuous
## rather than nearly continuous. Only the *cross* coordinate moves with the car: a quarter turn's
## exit lane is a coordinate on the along axis, so it is landed on exactly however far off its own
## lane centre the car began.
func begin_at(cross: float) -> void:
	centre = world(entry_vertical, entry_along, cross + cross_sign * radius)
	var start := world(entry_vertical, entry_along, cross)
	start_angle = (start - centre).angle()
	var forward := world(entry_vertical, entry_direction, 0.0)
	var right := Vector2(-forward.y, forward.x)
	spin = 1.0 if (centre - start).dot(right) > 0.0 else -1.0

func length() -> float:
	return radius * sweep

func is_about_face() -> bool:
	return exit_vertical == entry_vertical

## Where the car is `distance` px along the arc.
func point_at(distance: float) -> Vector2:
	var angle := start_angle + spin * distance / radius
	return centre + Vector2(cos(angle), sin(angle)) * radius

## Which way it is pointing there: the tangent, which is what makes the heading continuous through
## the whole manoeuvre and is the datum everything downstream of a heading reads.
func heading_at(distance: float) -> Vector2:
	var angle := start_angle + spin * distance / radius
	return Vector2(-sin(angle), cos(angle)) * spin

## Where the car ends up along the corridor it is joining, as that lane's own queue position — what
## a turn has to reserve, since a turn is a placement into somebody else's queue.
func landing() -> float:
	var end := point_at(length())
	return (end.y if exit_vertical else end.x) * exit_direction

## Tightens the arc so that it starts where the car already is, for a car that learns it has to turn
## after it has passed the entry the geometry would have chosen. False when what is left is tighter
## than `Tuning.CAR_TURN_RADIUS_MIN`, which is a turn the car cannot make and has to be refused
## rather than squeezed — an arc tighter than the body's own half width sweeps its inner flank
## backwards through the centre of the circle, which is a pivot and not a turn.
##
## An about-face has no slack to give: its radius is half the distance between the two lanes of one
## carriageway and there is no other value that lands on the lane.
func tighten_to(along: float, cross: float) -> bool:
	if is_about_face():
		return false
	var lane_along := CrowdLanes.lane_centre(exit_corridor, exit_lane)
	var tighter := absf(lane_along - along)
	if tighter < Tuning.CAR_TURN_RADIUS_MIN:
		return false
	radius = tighter
	entry_along = along
	begin_at(cross)
	return true

## How much road an about-face swallows in front of where it starts, in px.
##
## The furthest a corner of the swept body gets from the entry point over the whole half turn: the
## body's own half length off a circle whose radius is `CAR_TURN_RADIUS_MIN` plus its half width,
## which comes out at 40px — a car's own length, near enough, and it is the same number sideways,
## reached when the car is broadside. **A car has to stop this far short of a barrier to have
## anywhere to turn round in**, which is why the brake aims at that point rather than at the barrier.
static func about_face_reach() -> float:
	var radial := Tuning.CAR_TURN_RADIUS_MIN + Tuning.CAR_STRIKE_HALF_WIDTH
	return sqrt(radial * radial + Tuning.CAR_STRIKE_HALF_LENGTH * Tuning.CAR_STRIKE_HALF_LENGTH)

## Which way across a corridor the kerb on a car's own side of the road lies, as +1 or -1 on the
## cross axis. A lane is one side of a two-lane carriageway, so this is which side.
static func kerb_side(lane: int) -> float:
	return signf(float(lane) + 0.5 - float(Tuning.STREET_WIDTH) * 0.5)

## World coordinate of the near edge of a corridor's carriageway, coming at it along `direction`.
static func carriageway_edge(band: int, direction: float) -> float:
	var offset := Tuning.SIDEWALK_WIDTH if direction > 0.0 \
			else Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
	return float(band * CityMap.period() + offset) * float(Tuning.TILE_SIZE)

## And the middle of it, which is where an about-face is taken.
static func carriageway_centre(band: int) -> float:
	return float(band * CityMap.period()) * float(Tuning.TILE_SIZE) \
			+ float(Tuning.STREET_WIDTH) * float(Tuning.TILE_SIZE) * 0.5

## An (along, cross) pair as a world point, for whichever axis is the along one.
static func world(vertical: bool, along: float, cross: float) -> Vector2:
	return Vector2(cross, along) if vertical else Vector2(along, cross)
