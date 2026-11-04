extends RefCounted
## **Day 12's cordon officers, placed and walked, printed one line per sample**, so a change to the
## rules the cordon asks can be shown to put them exactly where they stood before. Not a suite: it
## prints rather than asserts. Run by name, before and after a change, and compare:
##
##     tools/test.sh probes/cordon_placement_fingerprint.gd > before.txt
##     grep '^CP ' before.txt > before.cp     (and the same for after; `diff` the two)
##
## Per seed of a sweep (the swing park on every size the generator builds), day 12 from the swing's
## touch, the camera on her as the game's view is, played twice: standing at the swing, and walking
## to just outside the last gap once the first frame has decided it. Printed: the last gap, the
## close's deadline and when the first officer is in view, the way out, then every officer's
## phase and position every `SAMPLE_EVERY` frames until the cordon closes and its officers are gone.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS_FROM := 1
const SEEDS_TO := 40
const LARGE_PARK_SEED := 90210
const STEP := 1.0 / 60.0
const PATIENCE := 90.0
const SAMPLE_EVERY := 15

func run(t) -> void:
	var seeds: Array[int] = []
	for seed_value in range(SEEDS_FROM, SEEDS_TO + 1):
		seeds.append(seed_value)
	seeds.append(LARGE_PARK_SEED)
	var printed := 0
	for seed_value in seeds:
		for walks in [false, true]:
			printed += _a_seed(t, seed_value, walks)
	print("CP_TOTAL %d lines" % printed)
	t.check(printed > 0, "there were officers to print (%d)" % printed)

func _a_seed(t, seed_value: int, walks: bool) -> int:
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var saved := {
		"state": GameState.attempt_spend.city_state, "day": GameState.header.day,
		"completed": GameState.resistance.completed_steps.duplicate(),
		"failed": GameState.resistance.failed_steps.duplicate(),
		"progress": GameState.resistance.progress,
		"package": GameState.resistance.carrying_package,
	}
	GameState.resistance.completed_steps = []
	GameState.resistance.failed_steps = []
	GameState.resistance.progress = 0
	GameState.resistance.carrying_package = false
	var day := ResistanceSteps.swing_day()
	GameState.header.day = day
	var state := CityState.new()
	GameState.attempt_spend.city_state = state
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _rng(seed_value, day, "closures"))
	city.events.start_day(DaySpec.for_day(day), _rng(seed_value, day, "events"), [],
			city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
	var mark := director.current_step()
	director._on_contact_completed(mark.index if mark else -1)
	var task := director.current_step()
	var printed := 0
	if task and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		var swing := director.contact_position()
		director._on_contact_completed(task.index)
		printed = _play(city, director._happenings, swing, walks, "seed %d %s" % [seed_value,
				"walking" if walks else "standing"])
		director._happenings.start_day(day + 1)
	director.free()
	city.free()
	GameState.attempt_spend.city_state = saved.state
	GameState.header.day = saved.day
	GameState.resistance.completed_steps = saved.completed
	GameState.resistance.failed_steps = saved.failed
	GameState.resistance.progress = saved.progress
	GameState.resistance.carrying_package = saved.package
	return printed

func _play(city: City, happenings: ResistanceHappenings, swing: Vector2, walks: bool, label: String) -> int:
	var her := [swing]
	_look(city, her[0])
	happenings.tick(STEP, her[0], Vector2.ZERO)
	var cordon := happenings.cordon
	var printed := 0
	_print("%s gap %s deadline %.3f in_view %.3f exit %s" % [label, cordon.last_gap,
			cordon.deadline, cordon.first_in_view, cordon._exit])
	printed += 1
	if walks:
		her[0] = cordon.last_gap + (cordon.last_gap - cordon.area.get_center()).normalized() \
				* Tuning.TILE_SIZE * 3.0
	var frame := 0
	var gone_for := 0
	while frame * STEP < PATIENCE:
		_look(city, her[0])
		happenings.tick(STEP, her[0], Vector2.ZERO)
		frame += 1
		if frame % SAMPLE_EVERY == 0 or cordon.is_closed():
			var parts: Array[String] = []
			for officer in cordon.officers:
				parts.append("%d@%s" % [officer.phase, officer.at])
			_print("%s f%d closed %.3f %s" % [label, frame, cordon.closed_at, " ".join(parts)])
			printed += 1
		if cordon.is_closed():
			var all_gone := true
			for officer in cordon.officers:
				all_gone = all_gone and officer.phase == ParkCordon.Officer.Phase.GONE
			gone_for += 1
			if all_gone or gone_for > 600:
				break
	return printed

func _print(line: String) -> void:
	print("CP ", line)

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

## The city's own view looked through about `at`, as the game's camera does.
func _look(city: City, at: Vector2) -> void:
	city.events.visible_view().look(
			Rect2(at - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0), null)
