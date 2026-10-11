extends RefCounted
## Scratch, never committed: prints every plan of every day for a few seeds, for a diff between
## two checkouts.

func run(t) -> void:
	var out := FileAccess.open(OS.get_environment("PLAN_DUMP"), FileAccess.WRITE)
	var lines := 0
	for seed in [4242, 67, 11]:
		var map := CityGenerator.generate(seed)
		var consumed: Array[String] = []
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d" % [seed, day])
			var plans := EventScheduler.build_day(day, rng, map, consumed)
			for plan in plans:
				out.store_line("%d %d %s %s %s %s %d" % [seed, day, plan.def.id, str(plan.position),
						str(plan.path), str(plan.facing), plan.role])
				lines += 1
	out.close()
	t.check(lines > 1000, "plans dumped (%d)" % lines)
