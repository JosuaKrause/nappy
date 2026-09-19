extends RefCounted
## Reproducible crowd-query workload, not a whole-game frame or a phone benchmark.
## Run explicitly with tools/test.sh probes/m159_contribution_cost.gd; raw timings print at end.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const ORACLE := preload("res://tests/test_crowd_contributions.gd")
const STEP := 1.0 / 30.0
const BATCH := 32

func run(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	var reports: Array = []
	for repetition in 3:
		for day in [1, 9]:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("contribution-cost:4242:%d" % day)
			var here := city.map.home_world_position()
			city.crowd.start_day(day, rng, here)
			var rows: Array = []
			var mismatch := 0
			for frame in 330:
				var direction := Vector2.DOWN if frame < 90 else \
					(Vector2.RIGHT if (frame - 90) / 60 % 2 == 0 else Vector2.LEFT)
				here += direction * Tuning.WALK_SPEED * STEP
				city.crowd.set_focus(here)
				city.crowd.step(STEP)
				if frame < 150:
					continue
				var expected := 0.0
				var silent := 0
				for agent: CrowdAgent in city.crowd.agents():
					var contribution := ORACLE.full_contribution(agent, here)
					if contribution != agent.contribution_at(here):
						mismatch += 1
					expected += contribution
					if contribution == 0.0:
						silent += 1
				var checksum := 0.0
				var started := Time.get_ticks_usec()
				for repeat in BATCH:
					for pair in city.crowd.excitement_sources_at(here):
						checksum += pair[1]
				var elapsed := Time.get_ticks_usec() - started
				rows.append([frame, float(elapsed) / BATCH, expected, silent,
					city.crowd.agent_count(), here.x, here.y])
				if not is_equal_approx(checksum / BATCH, expected):
					mismatch += 1
			t.check(mismatch == 0, "day %d workload preserves each source and the total" % day)
			reports.append({"repetition": repetition, "day": day, "mismatches": mismatch,
				"samples": rows})
	city.free()
	print("CROWD_COST_JSON " + JSON.stringify({"schema_version": 1, "seed": 4242,
		"engine": Engine.get_version_info(), "os": OS.get_name(), "processor": OS.get_processor_name(),
		"warmup_simulated_seconds": 5, "window_simulated_seconds": 6, "step_seconds": STEP,
		"batch_sweeps": BATCH, "columns": ["simulation_frame", "usec_per_source_sweep",
		"total_contribution", "zero_sources", "agents", "query_x", "query_y"], "runs": reports}))
