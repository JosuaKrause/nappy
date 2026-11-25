extends RefCounted
## Prints `ROLE day row role` (role 1 = WALL, 2 = FRICTION; other roles are not printed) for every
## catalogue row on every day, from EventScheduler.role_for() on origin/main 38ce03823. It is the
## role table compare_placement.py reads ("the role table it reads", grassy-magpie): one table for
## both trees, since v0.29.0 has no role_for(). Run as tests/probes/placement_roles.gd in today's
## checkout.

func run(t) -> void:
	for day in range(1, 15):
		for def in EventCatalogue.all():
			var role := int(EventScheduler.role_for(def, day))
			if role == 1 or role == 2:
				print("ROLE %d %s %d" % [day, def.id, role])
	t.check(true, "roles printed")
