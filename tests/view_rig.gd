extends RefCounted
## One generated city and its crowd's field, for a suite that needs crowd members standing on real
## lanes: `CrowdAgent`s placed the way the game places them (`setup()`, `setup_at()`), then driven
## through their public API. `tests/test_walker_views.gd` and `tests/test_car_views.gd` use it.
##
## Placement is the game's own: `setup()` rolls a lane, a direction and a speed, so a suite that
## wants an agent heading one particular way asks `place()`, which rolls placements until one does.
## `place_at_speed()` then takes that lane for an agent at a speed the suite chooses
## (`CrowdAgent.setup_at()`, the pinned-actor placement the authored scenes use).

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
## How many placement rolls `place()` makes before it gives up on a heading.
const ROLLS := 400

var city: City

func _init(host: Node) -> void:
	city = RunCity.of_the_run(CITY_SCENE)
	host.add_child(city)
	city.build(CityGenerator.generate(SEED))
	# The atlas page every crowd picture is drawn from, held the way `Crowd.start_day()` holds it for
	# the day, so a halo or a drawn frame of an agent placed here finds its regions.
	AtlasLibrary.acquire(Crowd.ATLAS_GROUP)

func free_city() -> void:
	AtlasLibrary.release(Crowd.ATLAS_GROUP)
	city.free()

## A walker's look over `agent`: `WalkerLook` is a public class that reads the agent's heading and
## velocity and writes nothing to it, so a suite that checks which view or stride frame a placed
## walker would draw builds its own look over it and drives it with the agent's own `velocity()`.
static func walker_look(agent: CrowdAgent) -> WalkerLook:
	return WalkerLook.new(agent)

## A car's look over `agent`, for the same reason (`CarLook`).
static func car_look(agent: CrowdAgent) -> CarLook:
	return CarLook.new(agent)

## A fresh agent of `kind` placed by `setup()`, as its rolled `seed_value` has it.
func rolled(kind: CrowdAgent.Kind, seed_value: int) -> CrowdAgent:
	var agent := CrowdAgent.new()
	agent.setup(kind, city.map, city.crowd.field(), seed_value, 0.5 * float(seed_value % 2))
	return agent

## An agent of `kind` that `setup()` placed travelling along `heading` (a cardinal unit vector), or
## null when no roll in `ROLLS` did.
func place(kind: CrowdAgent.Kind, heading: Vector2) -> CrowdAgent:
	for seed_value in range(1, ROLLS):
		var agent := rolled(kind, seed_value)
		if agent.heading().is_equal_approx(heading):
			return agent
		agent.free()
	return null

## An agent of `kind` on a lane `setup()` found for `heading`, pinned there at `speed`
## (`setup_at()`), or null when there is no such lane or `setup_at()` refuses it.
func place_at_speed(kind: CrowdAgent.Kind, heading: Vector2, speed: float) -> CrowdAgent:
	var scout := place(kind, heading)
	if scout == null:
		return null
	var at := scout.position
	scout.free()
	var agent := CrowdAgent.new()
	var problem := agent.setup_at(kind, city.map, city.crowd.field(), 1, at, heading, speed)
	if not problem.is_empty():
		agent.free()
		return null
	return agent
