extends RefCounted
## Contribution parity covers the elliptical boundary, transient jolts and externally moved bodies.

func run(t) -> void:
	# `CrowdAgent._widest_jolt_outer` is a static that only grows, and every suite after this one in
	# the same process would otherwise ask the crowd's sweep with the jolts written below, which
	# skips nothing. Kept here and written back before any check is made.
	var widest_before := CrowdAgent._widest_jolt_outer
	var agent := CrowdAgent.new()
	var mismatches := 0
	var positive := 0
	var zero := 0
	var wider_than_the_crowds := 0
	for kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		agent.kind = kind
		for pace in [0.0, 74.0, 185.0, 700.0]:
			agent._speed = pace
			for hurry in [false, true]:
				agent._yield_left = 1.0 if hurry else 0.0
				agent._yield_hurry = hurry
				for jolt_radius in [0.0, Tuning.CAR_HORN_OUTER_RADIUS, 400.0]:
					agent._jolt = 0.0
					if jolt_radius > 0.0:
						agent.startle(18.0, 0.9, 45.0, jolt_radius)
					var outer := Tuning.CAR_OUTER_RADIUS if kind == CrowdAgent.Kind.CAR \
						else Tuning.PEDESTRIAN_OUTER_RADIUS
					outer = maxf(outer, jolt_radius)
					var bound := outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
					if bound > CrowdAgent.silent_beyond():
						wider_than_the_crowds += 1
					for bearing in 24:
						var direction := Vector2.RIGHT.rotated(bearing * TAU / 24.0)
						for distance in [0.0, outer * 0.5, outer, bound - 0.001,
							bound, bound + 0.001, bound * 2.0]:
							var at: Vector2 = agent.global_position + direction * distance
							var expected := full_contribution(agent, at)
							if expected != agent.contribution_at(at):
								mismatches += 1
							if expected > 0.0:
								positive += 1
							else:
								zero += 1
	# A real curved heading, then a position and jolt change without advancing its own clock.
	agent._turn = CarTurn.new()
	agent._turn.radius = 48.0
	agent._turn.travelled = 23.0
	agent._turn_run_up = 0.0
	agent.position = Vector2(700.0, -320.0)
	agent.startle(30.0, 1.0, 45.0, 600.0)
	for offset in [Vector2(800.0, 0.0), Vector2(100.0, 100.0), Vector2(-40.0, 0.0)]:
		var at: Vector2 = agent.global_position + offset
		if full_contribution(agent, at) != agent.contribution_at(at):
			mismatches += 1
	t.check(positive > 0 and zero > 0, "parity covers contributing and silent bodies")
	t.check(mismatches == 0, "every tested contribution exactly matches the unfiltered kernel")
	# `Crowd.excitement_sources_at()` skips a body past `silent_beyond()` without asking it, so no
	# body's own early-out may reach further, however its jolt's radius was written.
	t.check(wider_than_the_crowds == 0,
			"no kind, pace or jolt reaches past the distance the crowd's sweep skips beyond")
	var sweep := _sweep_parity()
	agent.set("_jolt_outer", 2000.0)
	var widened := CrowdAgent.silent_beyond()
	CrowdAgent._widest_jolt_outer = widest_before
	agent.free()
	t.check(widened >= 2000.0 / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX),
			"a jolt radius written straight to the field still widens what the sweep asks")
	t.check(sweep.x > 0 and sweep.y > 0,
			"the sweep's parity covers bodies it hears (%d) and bodies it skips (%d)"
			% [sweep.x, sweep.y])
	t.check(sweep.z == 0, "Crowd.excitement_sources_at() returns exactly the unfiltered pairs "
			+ "(%d samples differed)" % sweep.z)

## `Crowd.excitement_sources_at()` against an unfiltered loop over the same agents: the same
## agents, in the same order, with the same contributions, at points among a crowd of walkers and
## cars near and far — a horn-startled car among them, heard from further than any unstartled body
## reaches. Returns (bodies heard, bodies past the skip, samples that differed).
static func _sweep_parity() -> Vector3i:
	var crowd := Crowd.new()
	var agents: Array[CrowdAgent] = []
	for i in 40:
		var body := CrowdAgent.new()
		body.kind = CrowdAgent.Kind.CAR if i % 3 == 0 else CrowdAgent.Kind.WALKER
		body._speed = [0.0, 30.0, 185.0, 700.0][i % 4]
		body._vertical = i % 2 == 0
		body._direction = 1.0 if i % 5 < 3 else -1.0
		body.position = Vector2.RIGHT.rotated(i * 2.4) * (12.0 + i * 31.0)
		if i % 7 == 0:
			body.startle(18.0, 0.9, 45.0, Tuning.CAR_HORN_OUTER_RADIUS)
		agents.append(body)
	var loud := CrowdAgent.new()
	loud.kind = CrowdAgent.Kind.CAR
	loud._speed = 700.0
	loud._vertical = false
	loud._direction = -1.0
	loud.position = Vector2(600.0, 0.0)
	loud.startle(30.0, 1.0, 45.0, 400.0)
	agents.append(loud)
	crowd._agents = agents
	var heard := 0
	var skipped := 0
	var differed := 0
	var reach := CrowdAgent.silent_beyond()
	for sample in 30:
		var at := Vector2.RIGHT.rotated(sample * 0.9) * (sample * 23.0)
		var expected: Array = []
		for body in agents:
			var contribution := body.contribution_at(at)
			if contribution > 0.0:
				expected.append([body, contribution])
			if body.global_position.distance_to(at) > reach:
				skipped += 1
		heard += expected.size()
		if crowd.excitement_sources_at(at) != expected:
			differed += 1
	crowd._agents = []
	for body in agents:
		body.free()
	crowd.free()
	return Vector3i(heard, skipped, differed)

## Frozen full calculation is the oracle: the production early rejection must only remove zeros.
static func full_contribution(agent: CrowdAgent, at: Vector2) -> float:
	var distance := GroundShape.eccentric_distance(agent.global_position, agent.velocity(), at)
	var total := 0.0
	if agent.kind == CrowdAgent.Kind.CAR:
		total = Tuning.falloff(distance, Tuning.CAR_INTENSITY,
			Tuning.CAR_INNER_RADIUS, Tuning.CAR_OUTER_RADIUS)
	else:
		total = Tuning.falloff(distance, Tuning.PEDESTRIAN_INTENSITY,
			Tuning.PEDESTRIAN_INNER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS)
	if agent._jolt > 0.0:
		total += Tuning.falloff(distance, agent._jolt_intensity * (agent._jolt / agent._jolt_for),
			agent._jolt_inner, agent._jolt_outer)
	# A building between them silences the whole of it; asked of every body, never only the near
	# ones, so the oracle stays the unfiltered calculation on a real map too.
	if agent._map and agent._map.wall_between(agent.global_position, at):
		return 0.0
	return total
