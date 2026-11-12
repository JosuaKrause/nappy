extends RefCounted
## Road closures over the last six maps of the sweep: the day-level invariant, counts, ground.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/routes_closures_rig.gd`.

const Rig := preload("res://tests/routes_closures_rig.gd")

func run(t: TestRunner) -> void:
	var rig: Rig = Rig.new()
	rig.prepare(6, 6)
	rig.case_every_planned_day_keeps_the_invariant(t)
	rig.case_the_home_street_is_never_closed(t)
	rig.case_closure_counts_follow_the_act(t)
	rig.case_most_of_a_closed_streets_ground_stays_closed(t)
	rig.case_calm_ground_is_still_walkable_to(t)
	rig.case_a_mid_segment_opening_stays_reachable_from_its_own_side(t)
	rig.case_a_closure_never_lands_on_a_calm_areas_own_access(t)
