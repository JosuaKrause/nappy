class_name Crowd
extends Node
## The city's own traffic: everyone who is not the player and not an event.
##
## This is where the noise floor comes from. Before it, a day could be won by circling the
## starting block, because an empty street was as quiet as a park; the city was decoration.
## Now a street is loud in proportion to how busy it is, a park is quiet because nobody is
## in it, and the player can see exactly why in both cases. Nothing in here is a
## city-wide constant — the floor is emergent, and it is standing right in front of you.
##
## Lookup is a linear scan, as it is for events. The population is an order of magnitude
## larger (around 120 rather than 22) and it is still one distance check each, once per
## physics frame, for the single query the baby makes.

var _agents: Array[CrowdAgent] = []
var _city: City
var _map: CityMap
var _player: Stroller
## A day only ends once, so a second car cannot claim the same run.
var _struck := false
## When the last horn went, so the exclamation mark over the player survives the gap between
## two cars in the same lane instead of strobing.
var _warned_at := -1000.0

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map

## Clears yesterday's crowd and populates today's. The population is fixed for the day and
## comes from the act, not the day: the streets thin out as the occupation settles in, and
## act III's empty city is told here rather than announced anywhere.
func start_day(day: int, rng: RandomNumberGenerator) -> void:
	clear()
	_struck = false
	_warned_at = -1000.0
	var act := Tuning.act_for_day(day)
	_populate(CrowdAgent.Kind.WALKER, Tuning.crowd_pedestrians(act), rng)
	_populate(CrowdAgent.Kind.CAR, Tuning.crowd_cars(act), rng)

func clear() -> void:
	for agent in _agents:
		agent.queue_free()
	_agents.clear()

## Agents alternate axes rather than rolling for one, so a crowd is never accidentally all
## north-south on a day when the coin came up that way.
func _populate(kind: CrowdAgent.Kind, count: int, rng: RandomNumberGenerator) -> void:
	for i in count:
		var agent := CrowdAgent.new()
		agent.setup(kind, _map, rng.randi(), 0.0 if i % 2 == 0 else 1.0)
		_city.add_entity(agent)
		_agents.append(agent)

# ----------------------------------------------------------------- contact ---
# Playtest 02, findings 2 and 3. Until M19 the crowd was a field with a picture attached: you
# could walk through a person, through a car, through a queue at a bus stop, and the only
# thing that happened was that a number moved. That is why the route was never a decision —
# every pavement was identical and none of them could hurt you.
#
# All three mechanisms live here rather than in `CrowdAgent` because all three are about the
# *player*, and an agent has no business knowing the player exists. One linear scan, the same
# shape and cost as the `total_excitement_at` the baby already runs every physics frame.

func _physics_process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Stroller
		if not _player:
			return
	var here := _player.global_position
	var on_the_road := Tile.is_road(_map.tile_type_at_world(here))
	var shove := Vector2.ZERO
	var closing := false

	for agent in _agents:
		if agent.kind == CrowdAgent.Kind.WALKER:
			shove += _bump(agent, here)
			continue
		agent.pedestrian_ahead = Vector2.INF
		if agent.global_position.distance_to(here) > Tuning.CAR_ZEBRA_SIGHT:
			continue
		agent.pedestrian_ahead = here
		if not on_the_road:
			continue
		if _strike(agent, here):
			return
		closing = _horn(agent, here) or closing

	if shove != Vector2.ZERO:
		_player.shove(shove.normalized() * Tuning.BUMP_SHOVE_SPEED)
	if closing:
		_warned_at = _now()
	# The exclamation mark says *the fairness contract is now about you and the clock has
	# started* — the load-bearing cue of M22's vocabulary, built here because M19 is what
	# creates the danger it warns about. See docs/EVENTS.md, "The visual vocabulary".
	_player.set_alert(_now() - _warned_at < Tuning.CAR_WARNING_HOLD)

## Displaces a pedestrian the player has walked into, startles them, and returns the share of
## the separation she takes herself.
##
## The separation is positional rather than a force, so two bodies can never end up inside
## each other however fast she is going — and the agent recovers on its own, because it steers
## back to its lane centre at `STEER_SPEED` like it does after any other displacement.
##
## Two things here were found by walking a rig down a real pavement and reading the meter,
## and neither is visible to a data-level test:
##
## - **Somebody bumped along their own line of travel steps aside.** Pushing them straight
##   down it separates nobody: she walks at 92 and they walk at 60, so a person bumped from
##   behind is ploughed along the pavement in front of her indefinitely. The first version did
##   that and a forty-second walk arrived at the far end pushing a wedge of pedestrians and
##   taking 150 excitement per second.
## - **A contact startles once, not once per frame.** `touching` is the hysteresis. Otherwise
##   one person held in contact for half a second costs what walking through a crowd should.
func _bump(agent: CrowdAgent, here: Vector2) -> Vector2:
	var away := agent.global_position - here
	var distance := away.length()
	if distance >= Tuning.BUMP_RADIUS:
		agent.touching = false
		return Vector2.ZERO

	# Exactly on top of each other: pick a side rather than dividing by zero.
	var direction := away / distance if distance > 0.01 else Vector2.RIGHT
	var forward := agent.heading()
	if absf(direction.dot(forward)) > 0.5:
		var side := Vector2(-forward.y, forward.x)
		direction = side if side.dot(away) >= 0.0 else -side

	var overlap := Tuning.BUMP_RADIUS - distance
	agent.global_position += direction * overlap * (1.0 - Tuning.BUMP_PLAYER_SHARE)
	if not agent.touching:
		agent.touching = true
		agent.startle(Tuning.BUMP_INTENSITY, Tuning.BUMP_DURATION,
				Tuning.BUMP_INNER_RADIUS, Tuning.BUMP_OUTER_RADIUS)
		EventBus.crowd_bumped.emit(here)
	return -direction * overlap

## A car strike, which ends the day.
##
## Two things keep it fair, and both are geometry rather than a warning: the box is the car
## the player can see, and it only counts while she is standing on the carriageway. The kerb
## is the edge she chose to step over — the same shape of contract the alley robbery has,
## where the alley is the warning. See `Tuning.validate_traffic()`.
func _strike(agent: CrowdAgent, here: Vector2) -> bool:
	if _struck or agent.speed() < Tuning.CAR_STRIKE_MIN_SPEED:
		return false
	var forward := agent.heading()
	var offset := here - agent.global_position
	if absf(offset.dot(forward)) > Tuning.CAR_STRIKE_HALF_LENGTH:
		return false
	if absf(offset.dot(Vector2(-forward.y, forward.x))) > Tuning.CAR_STRIKE_HALF_WIDTH:
		return false
	_struck = true
	EventBus.hard_fail_triggered.emit("car_strike")
	return true

## The horn, sounded at somebody standing in the lane this car is about to occupy. Returns
## true while the car is closing, which is what puts the mark over the player's head.
func _horn(agent: CrowdAgent, here: Vector2) -> bool:
	var forward := agent.heading()
	var offset := here - agent.global_position
	var ahead := offset.dot(forward)
	if ahead <= 0.0 or ahead > agent.speed() * Tuning.CAR_HORN_TIME:
		return false
	if absf(offset.dot(Vector2(-forward.y, forward.x))) > Tuning.CAR_STRIKE_HALF_WIDTH * 2.0:
		return false
	if not agent.is_startled():
		EventBus.car_near_miss.emit(here)
	agent.startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION,
			Tuning.CAR_HORN_INNER_RADIUS, Tuning.CAR_HORN_OUTER_RADIUS)
	return true

## Seconds since the scene started. Only ever used for differences, so the origin does not
## matter — and taking it from the engine rather than the day clock keeps the crowd working in
## a test rig that has no day.
func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

# ------------------------------------------------------------ WorldContext ---

## Summed excitement per second from everyone within earshot.
func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for agent in _agents:
		total += agent.contribution_at(world_position)
	return total

func agent_count() -> int:
	return _agents.size()

func agents() -> Array[CrowdAgent]:
	return _agents
