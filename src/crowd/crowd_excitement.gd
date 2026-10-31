class_name CrowdExcitement
extends ExcitementSource
## **A body in the crowd as a thing that charges the baby** (`ExcitementSource`), composed into its
## `CrowdAgent` as `excitement`: what is a crowd body's own and nothing else — its field (the same
## falloff as an event's, so the crowd and the events are the same kind of quantity to the baby, plus
## the jolt a contact or a horn leaves), how far it can reach, the walls of the map it walks, whether
## a car's strike box lies ahead of her, and its caret keyed on its own clock.
##
## **Not cached the way an event's present rate is.** A crowd body's position and jolt are written
## from outside its own frame — `Crowd._bump()` and `Crowd._horn()` move it and call
## `CrowdAgent.startle()` mid-tick — so a cache keyed on its clock could answer with the jolt or the
## position from before the bump that tick, the one frame a fresh startle is meant to show on.

var _agent: CrowdAgent

## How far forward each kind's field grows at the top of its speed range, worked out once.
var _car_scale := 1.0
var _walker_scale := 1.0

func _init(agent: CrowdAgent) -> void:
	super(agent)
	_agent = agent
	_car_scale = Tuning.field_scale(Tuning.field_eccentricity(Tuning.CAR_SPEED.y))
	_walker_scale = Tuning.field_scale(Tuning.field_eccentricity(Tuning.PEDESTRIAN_SPEED.y))

## The body's own simulation clock (`CrowdAgent.clock()`).
func clock() -> float:
	return _agent.clock()

## Excitement per second this body puts out at a point, with no wall asked. The kernel is
## `GroundShape.eccentric_distance()`, eccentric while moving and the plain distance the instant it
## stops, off `velocity()`: a crowd body is always a point in field terms (see `GroundShape`'s class
## doc on why nobody builds the general capsule-and-ellipse sum).
##
## The jolt is added on top of the body's ordinary noise rather than replacing it, and fades linearly
## over its own duration, so a bump is a spike with a tail and two people bumped in the same second
## cost twice. **The same distance prices both**: the horn or the bump is the same source being
## louder, not a second one, so no wall lets it through either.
func _field(at: Vector2) -> float:
	# d_eff = r * (1 - e * cos(theta)) is at least r * (1 - e_max), at every speed and heading.
	# Outside this bound both falloffs are zero, so the common distant-body case needs no
	# velocity/turn/pocket lookup or elliptical distance calculation. Read the current jolt each
	# time: a horn or an external bump can extend its reach between queries.
	var agent := _agent
	var car := agent.kind == CrowdAgent.Kind.CAR
	var outer := Tuning.CAR_OUTER_RADIUS if car else Tuning.PEDESTRIAN_OUTER_RADIUS
	if agent._jolt > 0.0:
		outer = maxf(outer, agent._jolt_outer)
	var reach := outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
	var origin := agent.global_position
	if origin.distance_squared_to(at) > reach * reach:
		return 0.0
	var distance := GroundShape.eccentric_distance(origin, agent.velocity(), at)
	var total := 0.0
	if car:
		total = Tuning.falloff(distance, Tuning.CAR_INTENSITY,
				Tuning.CAR_INNER_RADIUS, Tuning.CAR_OUTER_RADIUS)
	else:
		total = Tuning.falloff(distance, Tuning.PEDESTRIAN_INTENSITY,
				Tuning.PEDESTRIAN_INNER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS)
	if agent._jolt > 0.0:
		total += Tuning.falloff(distance, agent._jolt_intensity * (agent._jolt / agent._jolt_for),
				agent._jolt_inner, agent._jolt_outer)
	return total

## The city's map the body walks, or null for a data-level rig built without one.
func wall_grid() -> WorldMap:
	return _agent._map

## The body's velocity, which already carries its turns, yields, door holds and pockets.
func _projection_velocity() -> Vector2:
	return _agent.velocity()

## The furthest this body's field can currently reach: its ordinary outer radius, or the jolt's if
## one is running and reaches further (a car's `CAR_HORN_OUTER_RADIUS` past its `CAR_OUTER_RADIUS`),
## grown forward by `Tuning.field_scale()` at the fastest its kind ever moves — the top of its speed
## range rather than its current speed, so a body mid-approach is not skipped early on a reach that
## no longer describes it. No body to add a segment's length for, unlike an event's
## `EventDef.field_reach()`.
func _projection_reach() -> float:
	var agent := _agent
	var car := agent.kind == CrowdAgent.Kind.CAR
	var reach := Tuning.CAR_OUTER_RADIUS if car else Tuning.PEDESTRIAN_OUTER_RADIUS
	if agent._jolt > 0.0:
		reach = maxf(reach, agent._jolt_outer)
	return reach * (_car_scale if car else _walker_scale)

## Every input the samples read, by value, every jolt value afresh: the crowd can move or startle
## this body without advancing its own clock.
func _projection_key(player_position: Vector2, velocity: Vector2) -> Array:
	var agent := _agent
	return [agent.global_position, player_position, player_velocity, velocity, agent.kind,
		agent._jolt, agent._jolt_for, agent._jolt_intensity, agent._jolt_inner, agent._jolt_outer]

## The field at the translated point; the body translates with it, so its own velocity orients it.
func _projected_field(sample: Vector2, _velocity: Vector2) -> float:
	return _field(sample)

## Whether this car's strike box reaches her before the horizon is out, on its current course, her
## position held fixed, over the same rectangle `Crowd._strike()` tests for the collision: the car's
## front half, from its centre forward. Never for a walker — nothing about a pedestrian ends the day
## — and never for a car already too slow to strike at all (`Crowd._strike()`'s own guard).
func will_be_lethal(player_position: Vector2) -> bool:
	var agent := _agent
	if agent.kind != CrowdAgent.Kind.CAR or agent._speed < Tuning.CAR_STRIKE_MIN_SPEED:
		return false
	var vel := agent.velocity()
	var forward := agent.heading()
	var side := Vector2(-forward.y, forward.x)
	var offset := player_position - agent.global_position
	if absf(offset.dot(side)) > Tuning.CAR_STRIKE_HALF_WIDTH:
		return false
	# The box is the car's front half, 26px long, and a fast car covers more than that between two
	# samples, so the question is answered on the line rather than by stepping: the car closes on
	# her at `closing` px/s along its heading, and she is struck when the distance ahead of its
	# centre falls into [0, CAR_STRIKE_HALF_LENGTH] within the horizon.
	var ahead := offset.dot(forward)
	if ahead < 0.0:
		return false
	var closing := vel.dot(forward)
	if closing <= 0.0:
		return ahead <= Tuning.CAR_STRIKE_HALF_LENGTH
	return (ahead - Tuning.CAR_STRIKE_HALF_LENGTH) / closing <= Tuning.EXPECTED_IMPACT_HORIZON
