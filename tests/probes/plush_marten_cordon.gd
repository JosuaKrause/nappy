extends RefCounted
## **Probe, not a suite** (`tools/test.sh probes/plush_marten_cordon.gd`): day 12's police cordon
## (`ParkCordon`) on several seeds, measured with her at the swing and the camera on her.
##
## For each seed it prints the walk from the swing to the point of the tape's line nearest it (the
## last gap), how long that walk takes at `Tuning.WALK_SPEED`, when the officers reach the edge and
## when the last gap is taped with her standing at the swing, and the latest she can set off walking
## from the swing straight out through the gap and still be outside when it closes — the margin
## walking has. Run it again after changing any `PARK_CLOSING_*` constant.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 314159, 11, 2026]
const STEP := 1.0 / 60.0
const PATIENCE := 40.0
## The set-off delays tried, half a second apart.
const DELAY_STEP := 0.5

func run(t) -> void:
	for seed_value in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		_measure(t, city, seed_value)
		city.free()

func _measure(t, city: City, seed_value: int) -> void:
	var standing := _play(t, city, seed_value, INF)
	if standing.is_empty():
		print("seed %d: no swing park" % seed_value)
		return
	var latest := -1.0
	var delay := 0.0
	while delay < Tuning.PARK_CLOSING_SECONDS + 2.0:
		var walked := _play(t, city, seed_value, delay)
		if walked.is_empty() or walked.trapped:
			break
		latest = delay
		delay += DELAY_STEP
	print("seed %d: swing to the last gap %.0fpx (%.1fs walking), officers at the edge %.1fs, "
			% [seed_value, standing.walk, standing.walk / Tuning.WALK_SPEED, standing.arrived]
			+ "last gap taped %.1fs standing (shut in: %s), %d stretches, " % [standing.closed,
			standing.trapped, standing.stretches] + "latest walking set-off that gets out %.1fs"
			% latest)
	t.check(standing.trapped, "seed %d: standing at the swing shuts her in" % seed_value)
	t.check(latest >= 2.0, "seed %d: walking out still works after 2s at the swing (%.1fs)"
			% [seed_value, latest])

## Plays day 12 from the swing's touch with her setting off walking out through the last gap after
## `delay` seconds (INF: she stands). Answers what was measured, or `{}` with no swing park.
func _play(t, city: City, seed_value: int, delay: float) -> Dictionary:
	var saved_state := GameState.city_state
	var saved_day := GameState.day
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	GameState.completed_resistance_steps = []
	var day := ResistanceSteps.swing_day()
	GameState.day = day
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _rng(seed_value, day, "closures"))
	city.events.start_day(day, _rng(seed_value, day, "events"), [], city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
	var result := {}
	var mark := director.current_step()
	director._on_contact_completed(mark.index if mark else -1)
	var task := director.current_step()
	if task and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		var swing := director.contact_position()
		director._on_contact_completed(task.index)
		var happenings: ResistanceHappenings = director._happenings
		var her := [swing]
		var shows := func(row: EventDef, feet: Vector2) -> bool:
			var view := Rect2((her[0] as Vector2) - Tuning.VIEW_HALF_EXTENT,
					Tuning.VIEW_HALF_EXTENT * 2.0)
			var box := EventInstance.footprint_of(row)
			return view.intersects(Rect2(feet + box.position, box.size))
		happenings.tick(STEP, her[0], Vector2.ZERO, shows)
		var cordon := happenings.cordon
		var exit := cordon.last_gap
		var out := exit + (exit - swing).normalized() * Tuning.TILE_SIZE * 2.0
		var clock := STEP
		var arrived := -1.0
		while happenings.is_closing() and clock < PATIENCE:
			if clock >= delay:
				her[0] = (her[0] as Vector2).move_toward(out, Tuning.WALK_SPEED * STEP)
			happenings.tick(STEP, her[0], Vector2.ZERO, shows)
			clock += STEP
			if arrived < 0.0:
				for officer in cordon.officers:
					if officer.phase == ParkCordon.Officer.Phase.TAPING:
						arrived = clock
		var count := 0
		for stretch in cordon.stretches:
			if stretch.needed:
				count += 1
		result = {"walk": swing.distance_to(exit), "arrived": arrived, "closed": cordon.closed_at,
				"trapped": cordon.trapped, "stretches": count}
		happenings.start_day(day + 1)
	director.free()
	GameState.city_state = saved_state
	GameState.day = saved_day
	GameState.completed_resistance_steps = saved_completed
	return result

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
