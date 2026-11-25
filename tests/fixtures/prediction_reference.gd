extends RefCounted
## Independent pre-reuse gross projection, kept for bitwise behavioral comparisons.
## The sampling loops and arithmetic follow the stacked baseline; no new cache path is used.
## `her_velocity` and `sensitivity` are her motion as the halo last told the source
## (`ExcitementSource.set_her_motion()`), which the suite's told sources keep.

static func event_gross(source: EventInstance, player_position: Vector2, her_velocity: Vector2,
		sensitivity: float) -> float:
	if source.is_gone() or source.is_on_its_way_out() or source.source().is_outranked():
		return 0.0
	var velocity := source.caret_velocity()
	var closing := her_velocity - velocity
	var reach := closing.length() * Tuning.EXPECTED_IMPACT_HORIZON + source.row().field_reach()
	if source.global_position.distance_to(player_position) > reach:
		return 0.0
	if velocity.is_zero_approx() and her_velocity.is_zero_approx():
		return 0.0
	var current_rate := source.source().contribution_at(player_position)
	var live_intensity := source.caret_intensity_over_horizon()
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var landed := 0.0
	var grid := source.source().wall_grid()
	for i in steps:
		var time := float(i + 1) * dt
		var sample := player_position + her_velocity * time - velocity * time
		var rate := source.field_at(sample, live_intensity, velocity)
		if rate > 0.0 and grid != null and grid.wall_between(source.global_position, sample):
			rate = 0.0
		landed += rate * dt
	var gross := landed - current_rate * Tuning.EXPECTED_IMPACT_HORIZON
	return maxf(gross * sensitivity, 0.0)

static func crowd_gross(source: CrowdAgent, player_position: Vector2, her_velocity: Vector2,
		sensitivity: float) -> float:
	var vel := source.velocity()
	var closing := her_velocity - vel
	var reach := closing.length() * Tuning.EXPECTED_IMPACT_HORIZON + _crowd_reach(source)
	if source.global_position.distance_to(player_position) > reach:
		return 0.0
	if vel.is_zero_approx() and her_velocity.is_zero_approx():
		return 0.0
	var current_rate := source.mood().contribution_at(player_position)
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var landed := 0.0
	for i in steps:
		var time := float(i + 1) * dt
		landed += source.mood().contribution_at(
				player_position + her_velocity * time - vel * time) * dt
	var gross := landed - current_rate * Tuning.EXPECTED_IMPACT_HORIZON
	return maxf(gross * sensitivity, 0.0)

## The furthest the body's field reaches, worked out from the tuning and what the body shows: its
## kind's outer radius, or the jolt's while one is running and reaches further, grown forward by
## `Field.scale()` at the top of its kind's speed range. This is its own working-out and shares
## nothing with the source's, so a wrong reach in the source shows as a failed parity.
static func _crowd_reach(source: CrowdAgent) -> float:
	var car := source.lane().kind() == CrowdAgent.Kind.CAR
	var reach := Tuning.CAR_OUTER_RADIUS if car else Tuning.PEDESTRIAN_OUTER_RADIUS
	if source.mood().is_startled():
		reach = maxf(reach, source.mood().jolt_radii().y)
	var top_speed := Tuning.CAR_SPEED.y if car else Tuning.PEDESTRIAN_SPEED.y
	return reach * Field.scale(Field.eccentricity(top_speed))
