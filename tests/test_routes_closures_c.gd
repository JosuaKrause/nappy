@warning_ignore_start("untyped_declaration")
extends RefCounted
## Road closures over the first six maps of the sweep: where a wall lands, access streets, the corridor.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/routes_closures_rig.gd`.

const Rig := preload("res://tests/routes_closures_rig.gd")

func run(t: TestRunner) -> void:
	var rig = Rig.new()
	rig.prepare(0, 6)
	rig.case_closures_land_where_a_wall_belongs(t)
	rig.case_a_closure_never_lands_on_a_calm_areas_own_access(t)
	rig.case_a_wall_off_the_corridor_never_fails_the_invariant(t)
