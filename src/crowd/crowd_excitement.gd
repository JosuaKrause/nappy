class_name CrowdExcitement
extends ExcitementSource
## **A body in the crowd as a thing that charges the baby** (`ExcitementSource`), composed into its
## `CrowdAgent` as `excitement`: what is a crowd body's own and nothing else — its field (the same
## falloff as an event's, so the crowd and the events are the same kind of quantity to the baby, plus
## the jolt a contact or a horn leaves, which it keeps), its own clock, how far it can reach, the
## walls of the map it walks, whether a car's strike box lies ahead of her, and its caret keyed on
## its clock.
##
## **Not cached the way an event's present rate is.** A crowd body's position and jolt are written
## from outside its own frame — `Crowd._bump()` and `Crowd._horn()` move the body and call
## `startle()` mid-tick — so a cache keyed on its clock could answer with the jolt or the position
## from before the bump that tick, the one frame a fresh startle is meant to show on.

var _agent: CrowdAgent

## The crowd's set this body is heard in (`CrowdSources`), handed in by the `Crowd` that makes the
## body, told whenever the jolt widens so the set's sweep never skips it; null for a body no crowd
## made.
var heard_in: CrowdSources = null

## The body's own simulation clock, in seconds, advanced once a frame by its own step
## (`advance()`). `landed()` is measured against it rather than the wall clock, so a paused game
## does not empty the halo and a rig measures the window on simulated time.
var _clock := 0.0

## Seconds of agitation left, and how loud the agitation started. A person she walked into is
## startled and says so; a car that had to sound its horn keeps sounding for a moment. This is how a
## contact reaches the meter *without* anything writing to `Baby.excitement`: the source is the body
## she touched, summed exactly like every other body.
var _jolt := 0.0
var _jolt_for := 1.0
var _jolt_intensity := 0.0
var _jolt_inner := 0.0
var _jolt_outer := 0.0:
	set(value):
		_jolt_outer = value
		var silent := value / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
		_jolt_silent_squared = silent * silent
		if heard_in:
			heard_in.widen_to(value)

## The squared distance past which the jolt's own falloff is exactly zero, worked out whenever its
## outer radius is written.
var _jolt_silent_squared := 0.0

## The body's kind's own field, taken up with the kind (`take_kind()`) so the field reads its own
## members: whether it is a car, the falloff's intensity and radii, the distance past which the
## ordinary field is exactly zero (squared, `_silent_squared`), and how far forward its field grows at
## the top of its kind's speed range (`_reach_scale`).
var _car := false
var _intensity := Tuning.PEDESTRIAN_INTENSITY
var _inner := Tuning.PEDESTRIAN_INNER_RADIUS
var _outer := Tuning.PEDESTRIAN_OUTER_RADIUS
var _silent_squared := 0.0
var _reach_scale := 1.0

func _init(agent: CrowdAgent) -> void:
	super(agent)
	_agent = agent
	take_kind(agent.kind)

## Takes up the field of a body of `kind`, told by the body whenever its kind is installed.
func take_kind(kind: CrowdAgent.Kind) -> void:
	_car = kind == CrowdAgent.Kind.CAR
	_intensity = Tuning.CAR_INTENSITY if _car else Tuning.PEDESTRIAN_INTENSITY
	_inner = Tuning.CAR_INNER_RADIUS if _car else Tuning.PEDESTRIAN_INNER_RADIUS
	_outer = Tuning.CAR_OUTER_RADIUS if _car else Tuning.PEDESTRIAN_OUTER_RADIUS
	var silent := _outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
	_silent_squared = silent * silent
	_reach_scale = Field.scale(Field.eccentricity(
			Tuning.CAR_SPEED.y if _car else Tuning.PEDESTRIAN_SPEED.y))

## The body's own simulation clock.
func clock() -> float:
	return _clock

## One frame of the body's own step: its clock moves on and its jolt runs down by `delta`.
func advance(delta: float) -> void:
	_clock += delta
	_jolt = maxf(0.0, _jolt - delta)

## Startles the body for `seconds`: the only way anything outside the crowd adds excitement to the
## world, and it deliberately adds it to a *body* rather than to the baby. **Never shortens an
## agitation already running**: a second bump on top of the first must not be able to make the
## first one quieter.
func startle(intensity: float, seconds: float, inner: float, outer: float) -> void:
	if _jolt > 0.0 and intensity * seconds < _jolt_intensity * _jolt:
		return
	_jolt = seconds
	_jolt_for = seconds
	_jolt_intensity = intensity
	_jolt_inner = inner
	_jolt_outer = outer

## True while the body is agitated, so the same contact is not written down twice.
func is_startled() -> bool:
	return _jolt > 0.0

## The jolt's own inner and outer radii, valid only while `is_startled()` — read by `DebugLayers`
## so its fields layer can draw the extra field a running jolt adds on top of the body's ordinary
## one, the same pair `_field()` sums in.
func jolt_radii() -> Vector2:
	return Vector2(_jolt_inner, _jolt_outer)

## What is left of the jolt, from 1 the moment it starts down to 0, and 1 while none is running: what
## a car's caret breathes with (`CrowdAgent._draw_mark()`).
func jolt_swell() -> float:
	return (_jolt / _jolt_for) if _jolt > 0.0 else 1.0

## `jolt_swell()` as it will stand `seconds` from now with nothing startling it again: what the
## caret breathes with on a drawn frame between two ticks (`CrowdAgent._draw_mark()`). Draw-only:
## nothing in the simulation calls it and it changes nothing.
func jolt_swell_after(seconds: float) -> float:
	return clampf((_jolt - seconds) / _jolt_for, 0.0, 1.0) if _jolt > 0.0 else 1.0

## Excitement per second this body puts out at a point, with no wall asked. The kernel is
## `GroundShape.eccentric_distance()`, eccentric while moving and the plain distance the instant it
## stops, off `velocity()`: a crowd body is always a point in field terms (see `GroundShape`'s class
## doc on why nobody builds the general capsule-and-ellipse sum).
##
## The jolt is added on top of the body's ordinary noise rather than replacing it, and fades linearly
## over its own duration, so a bump is a spike with a tail and two people bumped in the same second
## cost twice. **The same distance prices both**: the horn or the bump is the same source being
## louder, not a second one, so no wall lets it through either.
##
## **Every number it reads is its own member but the body's place and velocity**, because the whole
## crowd is asked this every drawn frame by `ExcitementHalo` and a member read is several times
## cheaper than asking another object.
func _field(at: Vector2) -> float:
	# d_eff = r * (1 - e * cos(theta)) is at least r * (1 - e_max), at every speed and heading.
	# Outside this bound both falloffs are zero, so the common distant-body case needs no
	# velocity/turn/pocket lookup or elliptical distance calculation. Read the current jolt each
	# time: a horn or an external bump can extend its reach between queries.
	var silent_squared := _jolt_silent_squared if _jolt > 0.0 and _jolt_outer > _outer \
			else _silent_squared
	var origin := _agent.global_position
	if origin.distance_squared_to(at) > silent_squared:
		return 0.0
	return _falloff_at(GroundShape.eccentric_distance(origin, _agent.velocity(), at))

## The field at an eccentric distance: the kind's falloff, and the running jolt's on top.
func _falloff_at(distance: float) -> float:
	var total := Field.falloff(distance, _intensity, _inner, _outer)
	if _jolt > 0.0:
		total += Field.falloff(distance, _jolt_intensity * (_jolt / _jolt_for), _jolt_inner,
				_jolt_outer)
	return total

## The city's map the body walks, or null for a data-level rig built without one.
func wall_grid() -> WorldMap:
	return _agent._map

## The body's velocity, which already carries its turns, yields, door holds and pockets.
func _projection_velocity() -> Vector2:
	return _agent.velocity()

## The furthest this body's field can currently reach: its ordinary outer radius, or the jolt's if
## one is running and reaches further (a car's `CAR_HORN_OUTER_RADIUS` past its `CAR_OUTER_RADIUS`),
## grown forward by `Field.scale()` at the fastest its kind ever moves — the top of its speed
## range rather than its current speed, so a body mid-approach is not skipped early on a reach that
## no longer describes it. No body to add a segment's length for, unlike an event's
## `EventDef.field_reach()`.
func _projection_reach() -> float:
	var reach := _outer
	if _jolt > 0.0:
		reach = maxf(reach, _jolt_outer)
	return reach * _reach_scale

## Every input the samples read, by value, every jolt value afresh: the crowd can move or startle
## this body without advancing its own clock.
func _projection_key(player_position: Vector2, velocity: Vector2) -> Array:
	return [_agent.global_position, player_position, player_velocity, velocity, _car,
		_jolt, _jolt_for, _jolt_intensity, _jolt_inner, _jolt_outer]

## Where the body stands and how far its field reaches, read once before the projection samples,
## since neither moves while it does.
var _projected_from := Vector2.ZERO
var _projected_silent_squared := 0.0

func _begin_the_projection(_velocity: Vector2) -> void:
	_projected_from = _agent.global_position
	_projected_silent_squared = _jolt_silent_squared if _jolt > 0.0 and _jolt_outer > _outer \
			else _silent_squared

## The field at the translated point, the same as `_field()` there; the body translates with it, so
## its own velocity, the one the projection runs on, orients it.
func _projected_field(sample: Vector2, velocity: Vector2) -> float:
	if _projected_from.distance_squared_to(sample) > _projected_silent_squared:
		return 0.0
	return _falloff_at(GroundShape.eccentric_distance(_projected_from, velocity, sample))

## Whether this car's strike box reaches her before the horizon is out, on its current course, her
## position held fixed, over the same rectangle `Crowd._strike()` tests for the collision: the car's
## front half, from its centre forward. Never for a walker — nothing about a pedestrian ends the day
## — and never for a car already too slow to strike at all (`Crowd._strike()`'s own guard).
func will_be_lethal(player_position: Vector2) -> bool:
	var agent := _agent
	if not _car or agent._speed < Tuning.CAR_STRIKE_MIN_SPEED:
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
