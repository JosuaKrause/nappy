extends RefCounted
## Independent pre-reuse gross projection, kept for bitwise behavioral comparisons.
## The sampling loops and arithmetic follow the stacked baseline; no new cache path is used.

static func event_gross(source: EventInstance, player_position: Vector2) -> float:
	if source.is_finished or source.is_leaving or source.outranked_by_a_stronger_barrier:
		return 0.0
	var velocity := source._caret_velocity()
	var closing := source.player_velocity - velocity
	var reach := closing.length() * Tuning.EXPECTED_IMPACT_HORIZON + source.def.field_reach()
	if source.global_position.distance_to(player_position) > reach:
		return 0.0
	if velocity.is_zero_approx() and source.player_velocity.is_zero_approx():
		return 0.0
	var current_rate := source.contribution_at(player_position)
	var live_intensity := source._caret_intensity_over_horizon()
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var landed := 0.0
	for i in steps:
		var time := float(i + 1) * dt
		var sample := player_position + source.player_velocity * time - velocity * time
		landed += source.contribution_at(sample, live_intensity, velocity) * dt
	var gross := landed - current_rate * Tuning.EXPECTED_IMPACT_HORIZON
	return maxf(gross * source.player_sensitivity, 0.0)

static func crowd_gross(source: CrowdAgent, player_position: Vector2) -> float:
	var vel := source.velocity()
	var closing := source.player_velocity - vel
	var reach := closing.length() * Tuning.EXPECTED_IMPACT_HORIZON + source._current_reach()
	if source.global_position.distance_to(player_position) > reach:
		return 0.0
	if vel.is_zero_approx() and source.player_velocity.is_zero_approx():
		return 0.0
	var current_rate := source.contribution_at(player_position)
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var landed := 0.0
	for i in steps:
		var time := float(i + 1) * dt
		landed += source.contribution_at(player_position + source.player_velocity * time - vel * time) * dt
	var gross := landed - current_rate * Tuning.EXPECTED_IMPACT_HORIZON
	return maxf(gross * source.player_sensitivity, 0.0)
