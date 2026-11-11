extends RefCounted
## Prints `ROLE day row role` (role 1 = WALL, 2 = FRICTION; other roles are not printed) for every
## catalogue row on every day, from `EventScheduler.role_for()`. It is the role table
## `tools/compare-placement-rows.py` reads (`--roles`): one table for both trees compared, since an
## older tree has no `role_for()`. Not a suite: it prints rather than asserting, and runs only by
## name:
##
##     tools/test.sh probes/placement_roles.gd

func run(t: TestRunner) -> void:
	for day: int in range(1, 15):
		for def: EventDef in EventCatalogue.all():
			var role: int = EventScheduler.role_for(def, day)
			if role == GameEnums.BlockerRole.WALL or role == GameEnums.BlockerRole.FRICTION:
				print("ROLE %d %s %d" % [day, def.id, role])
	t.check(true, "roles printed")
