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

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map

## Clears yesterday's crowd and populates today's. The population is fixed for the day and
## comes from the act, not the day: the streets thin out as the occupation settles in, and
## act III's empty city is told here rather than announced anywhere.
func start_day(day: int, rng: RandomNumberGenerator) -> void:
	clear()
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
