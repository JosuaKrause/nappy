extends RefCounted
## **Outside a step, every mover's move stands where the mover does** (`MoveProposal`), so the list a
## pass over every mover reads (`WorldMap.moves`, which holds no mover, only their moves) never shows
## a body somewhere it is not. Walked through a played day 12 on a booted `Main`: the crowd, the
## events and the resistance ticked at the physics tick each tick, her walking toward the swing and
## stood against a walker now and then so his bump pushes him, then the swing touched and the cordon
## closing round the park with its officers and escorts walking. At the end of every tick each live
## mover's move must be on its map's list, with `from` and `to` both at its pose and none open —
## and so it must at dawn before anybody has stepped, and the moment the swing sets the cordon's
## officers out, before any of them has:
##
## - every event in the world (`EventManager.instances()`), whether it was there at dawn or came
##   into the world during the tick;
## - every crowd walker and car (`Crowd.agents()`), through a car's turn, a body's recycling and a
##   walker's bump;
## - every cordon officer still out (`ParkCordon.officers`).
##
## The suite also checks the walk reached the cases it is for: a bump, a car's turn, a recycled body,
## an event that came into the world during the walk, and a cordon officer.
##
## `run()` snapshots the whole save first and puts it back last, and points `GameSave` at a scratch
## file, so nothing here leaks into the next suite or reaches the player's save.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SEEDS: Array[int] = [4242, 1]
const STEP := 1.0 / 30.0
## How long she walks the day before the swing, in seconds.
const BEFORE_THE_SWING := 25.0
## How long the walk goes on once the swing is touched, in seconds: the cordon's whole close.
const AFTER_THE_SWING := 30.0
## Every this many ticks she is stood against the nearest walker, so he bumps into her.
const BUMP_EVERY := 30
## A body that moves further than this in one tick was put somewhere new (recycled), in px.
const RECYCLE_JUMP := 64.0
## How many mismatches are printed, per seed.
const SHOWN := 8
const _SCRATCH_PATH := "user://test_move_poses_scratch.json"

var _bumps := 0

func run(t) -> void:
	var baseline := GameSave.file_data(GameState, false)
	GameSave.set_path_override(_SCRATCH_PATH)
	var bumped := func(_at: Vector2) -> void: _bumps += 1
	EventBus.crowd_bumped.connect(bumped)
	for seed_value in SEEDS:
		_walk_the_day(t, seed_value)
	EventBus.crowd_bumped.disconnect(bumped)
	GameSave._clear_now()
	GameSave.set_path_override("")
	GameSave.restore_run_data(GameState, baseline)
	GameState.hard_mode = bool(baseline["hard_mode"])
	GameState.checkpoint = baseline["checkpoint"]

## A booted `Main` standing in day 12 on `seed_value`, a normal run, with the mark read.
func _day_twelve(t, seed_value: int) -> Node2D:
	GameState.start_run(seed_value)
	GameState.header.day = ResistanceSteps.swing_day()
	GameSave._write_now(GameState, true)
	GameSave._uses_save_override = true
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(PackedStringArray(), "", true))
	t.add_child(main)
	GameSave._uses_save_override = null
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	main._on_title_start(ControlsMode.Mode.JOYSTICK, false, ControlsMode.Side.RIGHT)
	if main._flow.mode == RunFlow.Mode.BRIEF:
		main._on_summary_continued(main._flow.mode)
	var director: ResistanceDirector = main._resistance
	var mark := director.current_step()
	director._on_contact_completed(mark.index if mark else -1)
	return main

func _walk_the_day(t, seed_value: int) -> void:
	var main := _day_twelve(t, seed_value)
	var city: City = main._city
	var director: ResistanceDirector = main._resistance
	var swing := director.contact_position()
	var seen := {}
	for instance in city.events.instances():
		seen[instance.get_instance_id()] = true
	var last := {}
	var counts := {"wrong": 0, "by_kind": {}, "turns": 0, "recycled": 0, "came": 0, "officers": 0, "ticks": 0}
	_bumps = 0
	var ticks := int((BEFORE_THE_SWING + AFTER_THE_SWING) / STEP)
	var swing_tick := int(BEFORE_THE_SWING / STEP)
	# At dawn, before any mover has stepped: each joined where it stands.
	_check_the_tick(t, main, seed_value, -1, counts, seen, last)
	for tick in ticks:
		if tick == swing_tick:
			main._player.global_position = swing
			var task := director.current_step()
			director._on_contact_completed(task.index if task else -1)
			# The cordon's officers set out, none of them stepped yet: each joined where he stands.
			_check_the_tick(t, main, seed_value, tick, counts, seen, last)
		elif tick < swing_tick and tick % BUMP_EVERY == BUMP_EVERY - 1:
			_stand_against_a_walker(main)
		else:
			var here: Vector2 = main._player.global_position
			main._player.global_position = here.move_toward(swing, Tuning.WALK_SPEED * STEP)
		main._physics_process(STEP)
		city.events._physics_process(STEP)
		city.crowd._physics_process(STEP)
		counts["ticks"] += 1
		_check_the_tick(t, main, seed_value, tick, counts, seen, last)
	t.check(counts["wrong"] == 0, "seed %d: every live mover's move stands at its pose at the end "
			% seed_value + "of every one of %d ticks (%d wrong: %s)"
			% [counts["ticks"], counts["wrong"], counts["by_kind"]])
	t.check(_bumps > 0, "seed %d: the walk bumped a walker (%d)" % [seed_value, _bumps])
	t.check(counts["turns"] > 0, "seed %d: a crowd car turned (%d car ticks on a turn)"
			% [seed_value, counts["turns"]])
	t.check(counts["recycled"] > 0, "seed %d: a crowd body was recycled (%d)"
			% [seed_value, counts["recycled"]])
	t.check(counts["came"] > 0, "seed %d: an event came into the world during the walk (%d)"
			% [seed_value, counts["came"]])
	t.check(counts["officers"] > 0, "seed %d: cordon officers walked (%d officer ticks)"
			% [seed_value, counts["officers"]])
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()

## Stands her a few pixels off the nearest walker, inside his bump radius, so his bump pushes him.
func _stand_against_a_walker(main: Node2D) -> void:
	var here: Vector2 = main._player.global_position
	var nearest: CrowdAgent = null
	for agent in main._city.crowd.agents():
		if agent.kind != CrowdAgent.Kind.WALKER or not agent.is_inside_tree():
			continue
		if nearest == null or agent.global_position.distance_squared_to(here) \
				< nearest.global_position.distance_squared_to(here):
			nearest = agent
	if nearest != null:
		main._player.global_position = nearest.global_position + Vector2(Tuning.BUMP_RADIUS * 0.5, 0.0)

func _check_the_tick(t, main: Node2D, seed_value: int, tick: int, counts: Dictionary,
		seen: Dictionary, last: Dictionary) -> void:
	var city: City = main._city
	var listed := city.map.moves.all()
	for instance in city.events.instances():
		if not instance.is_inside_tree():
			continue
		var id := instance.get_instance_id()
		if not seen.has(id):
			seen[id] = true
			counts["came"] += 1
		_check_one(t, seed_value, tick, "event %s" % instance.def.id, instance._move,
				instance.position, listed, counts)
	for agent in city.crowd.agents():
		if not agent.is_inside_tree():
			continue
		var id := agent.get_instance_id()
		if agent._turn != null:
			counts["turns"] += 1
		if last.has(id) and (last[id] as Vector2).distance_to(agent.position) > RECYCLE_JUMP:
			counts["recycled"] += 1
		last[id] = agent.position
		_check_one(t, seed_value, tick, "crowd %s" % CrowdAgent.Kind.keys()[agent.kind],
				agent._move, agent.position, listed, counts)
	var cordon: ParkCordon = main._resistance._happenings.cordon
	if cordon == null:
		return
	for officer in cordon.officers:
		if officer.phase == ParkCordon.Officer.Phase.GONE:
			continue
		counts["officers"] += 1
		_check_one(t, seed_value, tick, "cordon officer", officer.move, officer.at, listed, counts)

func _check_one(t, seed_value: int, tick: int, what: String, move: MoveProposal, at: Vector2,
		listed: Array[MoveProposal], counts: Dictionary) -> void:
	if move.from == at and move.to == at and not move.open and listed.has(move):
		return
	counts["wrong"] += 1
	var kinds: Dictionary = counts["by_kind"]
	var kind := what.get_slice(" ", 0) if what.begins_with("event") else what
	kinds[kind] = int(kinds.get(kind, 0)) + 1
	if counts["wrong"] <= SHOWN:
		t.check(false, "seed %d tick %d: %s stands at %s, its move from %s to %s (open %s, listed %s)"
				% [seed_value, tick, what, at, move.from, move.to, move.open, listed.has(move)])
