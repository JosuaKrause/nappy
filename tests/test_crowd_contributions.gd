extends RefCounted
## Contribution parity covers the elliptical boundary, transient jolts and externally moved bodies.

func run(t) -> void:
	var agent := CrowdAgent.new()
	var mismatches := 0
	var positive := 0
	var zero := 0
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
	agent.free()

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
	return total
