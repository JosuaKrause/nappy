extends RefCounted
## Contribution parity covers the elliptical boundary, transient jolts and externally moved bodies.
##
## The bodies are the crowd's own: agents a city's crowd made (`Crowd.add_recipe_actor()` for the
## pinned ones, `start_day()` for a day's crowd), startled through `CrowdExcitement.startle()` and
## aged through `advance()`, which the crowd calls, and read through the public queries the baby's
## halo asks (`contribution_at()`, `CrowdSources.sources_at()`).

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2
const RIG := preload("res://tests/test_crowd_bodies.gd")
const SEED := 4242
## The pace of the car brought to a standstill rather than placed at one.
const STOPPED := -1.0

var _rig = RIG.new()

func run(t) -> void:
	var map := CityGenerator.generate(SEED)
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	city.build(map)
	var street: Vector2i = _rig.a_straight_run(map, Tuning.BLOCK_SIZE)
	t.check(street.x >= 0, "this city has a straight stretch of street to put a body on")
	if street.x >= 0:
		_test_the_contribution_matches_the_unfiltered_kernel(t, city, map, street)
		_test_the_sweep_matches_the_unfiltered_loop(t, city, map)
		_test_a_wide_jolt_widens_what_the_sweep_asks(t, city)
	city.free()

## One walker and one car of the crowd, each at both ends of its kind's pace, a walker also giving
## way (hurrying and waiting), a car also stopped by a crash, a jolt of each radius running or not, and a car on a curved heading.
func _test_the_contribution_matches_the_unfiltered_kernel(t, city: City, map: CityMap,
		street: Vector2i) -> void:
	# The crowd's set the bodies are heard in, which their jolts widen as a crowd's own bodies do.
	var heard_in := city.crowd.sources
	var mismatches := 0
	var positive := 0
	var zero := 0
	var wider_than_the_crowds := 0
	var along := float(street.y + 2) * Tuning.TILE_SIZE
	var car_lane: int = CrowdLanes.road_lane(true, 1.0)
	var jolt_intensity := 18.0
	for kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		var paces: Vector2 = Tuning.CAR_SPEED if kind == CrowdAgent.Kind.CAR \
				else Tuning.PEDESTRIAN_SPEED
		# A car is also asked at a standstill, which a crash brings it to (`crashed_into()`, the
		# public call the crowd makes); `STOPPED` stands for that row, and the walker's standstill is
		# its waiting.
		var paces_asked: Array = [paces.x, paces.y]
		if kind == CrowdAgent.Kind.CAR:
			paces_asked.append(STOPPED)
		for pace in paces_asked:
			for yielding in ([0, 1, 2] if kind == CrowdAgent.Kind.WALKER else [0]):
				city.crowd.start_day(1, _rng(), Vector2.ZERO)
				city.crowd.clear()
				var agent: CrowdAgent = _rig.agent_on(city, map, kind, street.x,
						car_lane if kind == CrowdAgent.Kind.CAR else 0, along, 1.0, true,
						CrowdLanes.SIDEWALK_OFFSETS, paces.x if pace == STOPPED else pace)
				if pace == STOPPED:
					agent.crashed_into()
					t.check(agent.speed() == 0.0, "a car a crash stopped is at a standstill")
				# A yield is a walker's: a car has no hurry or wait to be in. Stepping aside along its own
				# line is hurrying, against it is waiting (`LaneMover.step_aside()`).
				if yielding == 1:
					agent.step_aside(agent.heading(), Tuning.BUMP_STEP_ASIDE, Tuning.BUMP_STEP_ASIDE_TIME)
				elif yielding == 2:
					agent.step_aside(-agent.heading(), Tuning.BUMP_STEP_ASIDE, Tuning.BUMP_STEP_ASIDE_TIME)
				for jolt_radius in [0.0, Tuning.CAR_HORN_OUTER_RADIUS, 400.0]:
					# Ages any jolt out, the way a body's own steps do.
					agent.excitement.advance(60.0)
					if jolt_radius > 0.0:
						agent.excitement.startle(jolt_intensity, 0.9, 45.0, jolt_radius)
					var outer := Tuning.CAR_OUTER_RADIUS if kind == CrowdAgent.Kind.CAR \
						else Tuning.PEDESTRIAN_OUTER_RADIUS
					outer = maxf(outer, jolt_radius)
					var bound := outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
					if bound > heard_in.silent_beyond():
						wider_than_the_crowds += 1
					for bearing in 24:
						var direction := Vector2.RIGHT.rotated(bearing * TAU / 24.0)
						for distance in [0.0, outer * 0.5, outer, bound - 0.001,
							bound, bound + 0.001, bound * 2.0]:
							var at: Vector2 = agent.global_position + direction * distance
							var expected := full_contribution(map, agent, at, jolt_intensity)
							if expected != agent.excitement.contribution_at(at):
								mismatches += 1
							if expected > 0.0:
								positive += 1
							else:
								zero += 1
	# A real curved heading, then a position and jolt change without advancing its own clock.
	city.crowd.start_day(1, _rng(), Vector2.ZERO)
	city.crowd.clear()
	var turner: CrowdAgent = _rig.agent_on(city, map, CrowdAgent.Kind.CAR, street.x, car_lane,
			along, 1.0)
	var arc := CarTurn.new()
	arc.radius = 48.0
	arc.travelled = 23.0
	turner.take_the_turn(arc, 0.0)
	turner.position = Vector2(700.0, -320.0)
	turner.excitement.startle(30.0, 1.0, 45.0, 600.0)
	for offset in [Vector2(800.0, 0.0), Vector2(100.0, 100.0), Vector2(-40.0, 0.0)]:
		var at: Vector2 = turner.global_position + offset
		if full_contribution(map, turner, at, 30.0) != turner.excitement.contribution_at(at):
			mismatches += 1
	t.check(positive > 0 and zero > 0, "parity covers contributing and silent bodies")
	t.check(mismatches == 0, "every tested contribution exactly matches the unfiltered kernel")
	# `CrowdSources.sources_at()` skips a body past `silent_beyond()` without asking it, so no
	# body's own early-out may reach further, however its jolt's radius was written.
	t.check(wider_than_the_crowds == 0,
			"no kind, pace or jolt reaches past the distance the crowd's sweep skips beyond")

## Last, since the crowd's set only ever grows (`CrowdSources.widen_to()`) and the sweep above is
## asked of the reach the tests before it made.
func _test_a_wide_jolt_widens_what_the_sweep_asks(t, city: City) -> void:
	var body: CrowdAgent = city.crowd.agents()[0]
	body.excitement.startle(30.0, 1.0, 45.0, 2000.0)
	t.check(city.crowd.sources.silent_beyond() >= 2000.0 / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX),
			"a jolt radius a body is startled to still widens what the sweep asks")

func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("contributions:%d" % SEED)
	return rng

## `CrowdSources.sources_at()` against an unfiltered loop over the same agents: the same agents, in
## the same order, with the same contributions, at points among a day's crowd of walkers and cars near
## and far — a horn-startled car among them, heard from further than any unstartled body reaches.
func _test_the_sweep_matches_the_unfiltered_loop(t, city: City, map: CityMap) -> void:
	city.crowd.start_day(1, _rng())
	var agents := city.crowd.agents()
	var loud: CrowdAgent = null
	for i in agents.size():
		var body := agents[i]
		if i % 7 == 0:
			body.excitement.startle(18.0, 0.9, 45.0, Tuning.CAR_HORN_OUTER_RADIUS)
		if body.kind == CrowdAgent.Kind.CAR and (loud == null or body.speed() > loud.speed()):
			loud = body
	# The fastest car of the day sounds the loudest horn: a moving body's field reaches furthest ahead.
	loud.excitement.startle(30.0, 1.0, 45.0, 400.0)
	var sources := city.crowd.sources
	var heard := 0
	var skipped := 0
	var differed := 0
	var reach := sources.silent_beyond()
	var centre := city.crowd.field().centre
	# Points among the crowd, and points a loud car's jolt alone reaches, beyond what an unstartled
	# body is heard from.
	var points: Array[Vector2] = []
	for sample in 30:
		points.append(centre + Vector2.RIGHT.rotated(sample * 0.9) * (sample * 45.0))
	for bearing in 8:
		for distance in [250.0, 390.0, 520.0, 650.0, 780.0]:
			points.append(loud.global_position + Vector2.RIGHT.rotated(bearing * TAU / 8.0) * distance)
	for at in points:
		var expected: Array = []
		for body in agents:
			var contribution := body.excitement.contribution_at(at)
			if contribution > 0.0:
				expected.append([body.excitement, contribution])
			if body.global_position.distance_to(at) > reach:
				skipped += 1
		heard += expected.size()
		if sources.sources_at(at) != expected:
			differed += 1
	t.check(heard > 0 and skipped > 0,
			"the sweep's parity covers bodies it hears (%d) and bodies it skips (%d)"
			% [heard, skipped])
	t.check(differed == 0, "CrowdSources.sources_at() returns exactly the unfiltered pairs "
			+ "(%d samples differed)" % differed)

## Frozen full calculation is the oracle: the production early rejection must only remove zeros. It
## reads the body as the baby's halo does, off its public state: its place, its velocity, whether a
## jolt is running and the jolt's radii and swell, and the intensity the test startled it with.
static func full_contribution(map: CityMap, agent: CrowdAgent, at: Vector2, jolt_intensity: float) -> float:
	var distance := GroundShape.eccentric_distance(agent.global_position, agent.velocity(), at)
	var total := 0.0
	if agent.kind == CrowdAgent.Kind.CAR:
		total = Field.falloff(distance, CrowdExcitement.CAR_INTENSITY,
			Tuning.CAR_INNER_RADIUS, Tuning.CAR_OUTER_RADIUS)
	else:
		total = Field.falloff(distance, CrowdExcitement.PEDESTRIAN_INTENSITY,
			Tuning.PEDESTRIAN_INNER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS)
	var jolt := agent.excitement
	if jolt.is_startled():
		total += Field.falloff(distance, jolt_intensity * jolt.jolt_swell(),
			jolt.jolt_radii().x, jolt.jolt_radii().y)
	# A building between them silences the whole of it; asked of every body, never only the near
	# ones, so the oracle stays the unfiltered calculation on a real map too.
	if map.wall_between(agent.global_position, at):
		return 0.0
	return total
