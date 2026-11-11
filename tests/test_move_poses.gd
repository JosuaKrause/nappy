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
## **The day runs under `--invincible`, so nothing she meets ends it.** The walk is a rig, not a
## route: she goes in a straight line across roads and is stood against whichever walker is nearest,
## so whether a car or a pursuer catches her depends on where the crowd happens to walk. A lost day
## stops the tick that sets the cordon's officers out, and the cordon is what the walk is for, so the
## suite would otherwise rest on a chance that any change to how the crowd moves can undo. The suite
## checks the day still runs when the swing is touched.
##
## **The booted game is driven the way a player and the engine drive it** (`tests/booted_main.gd`):
## the title's joystick button pressed through the viewport, her marks read through the contact's
## own completion (`ContactPoint.complete_now()`), and every tick a real physics tick of the booted
## game (`tests/physics_ticks.gd`): `main` ticks the resistance and the day, and the engine ticks the
## events and the crowd, in the order the game runs them. Run at twice real time, so a tick is the
## 1/30 s the walk always took. The move a mover stands is read off the list the game's own passes
## read (`WorldMap.moves`), and the movers' poses off the nodes the game draws: an event's and a
## crowd body's position, and the cordon's officers' figures (`CordonOfficer`).
##
## **This suite combines modules, for a stated reason**: the guarantee is a contract *between* the
## movers and the map's list (every mover's move is on `WorldMap.moves` and stands where the mover
## does, at the end of every tick), so the crowd, the events, the resistance's cordon and the map are all
## real and ticking together, as the game ticks them. A fake for any of them could not hold the one
## thing checked, that a real mover of each kind leaves no stale or open move. It was named for the
## player and her walk, and the movers are not hers; their own suites hold what each does alone. The
## cities come from the cache of generated maps (`tests/city_map_cache.gd`).
##
## Every seed plays a run of its own (`tests/seat.gd`), and every boot is handed
## a save at a scratch path (`main.use_save()`), so nothing here leaks into the next suite or
## reaches the player's save.

const Boot := preload("res://tests/booted_main.gd")
const MapCache := preload("res://tests/city_map_cache.gd")
const Seat := preload("res://tests/seat.gd")
## The save every boot is handed, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_move_poses_scratch.json"
const SEEDS: Array[int] = [4242, 1]
## How many times real time the walk runs, so a physics tick carries 1/30 s.
const SCALE := 2.0
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

var _bumps := 0

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	var bumped := func(_at: Vector2) -> void: _bumps += 1
	EventBus.crowd_bumped.connect(bumped)
	for seed_value in SEEDS:
		await _walk_the_day(t, seed_value)
	EventBus.crowd_bumped.disconnect(bumped)

## A booted `Main` standing in day 12 on `seed_value`, a normal run under `--invincible`, reached
## with `--seed` and `--day`, walked from the title's joystick button, with the mark read.
func _day_twelve(t: TestRunner, seat: Seat, seed_value: int) -> Boot.Booted:
	var words := ["--invincible", "--seed", str(seed_value), "--day", str(ResistanceSteps.swing_day())]
	# The boot and the title take as many physics ticks as the wall clock gives them frames, so the
	# game runs them at a scale so small that a tick's delta moves nothing a pixel can show (never 0:
	# the crowd divides a step by its delta), and the walk starts from the same dawn. The boot's own
	# hold (`Boot.boot()`'s `still`) is not enough here: it ends when the boot does, and the hold has
	# to span the title press and the mark's completion as well.
	var clock := Engine.time_scale
	Engine.time_scale = Boot.STILL_SCALE
	var booted: Boot.Booted = await seat.boot(t, _SCRATCH_SAVE, words, null, false, MapCache.source())
	await Boot.press_title(t, booted.main, "Right")
	var summary := Boot.summary(booted.main)
	if summary and summary.is_showing():
		await Boot.press_continue(t, booted.main)
	var mark := Boot.resistance(booted.main).contact()
	if mark:
		mark.complete_now()
	Engine.time_scale = clock
	return booted

func _walk_the_day(t: TestRunner, seed_value: int) -> void:
	var seat := Seat.new(t)
	var booted: Boot.Booted = await _day_twelve(t, seat, seed_value)
	var main := booted.main
	var city := Boot.city(main)
	var day := Boot.day(main)
	var swing := Boot.resistance(main).contact_position()
	var seen := {}
	for instance in city.events.instances():
		seen[instance.get_instance_id()] = true
	var last := {}
	var counts := {"wrong": 0, "by_kind": {}, "turns": 0, "recycled": 0, "came": 0, "officers": 0, "ticks": 0}
	_bumps = 0
	# Her step is read at the project's own rate, here, before the ticks come faster.
	var step := Tuning.WALK_SPEED * SCALE / Engine.physics_ticks_per_second
	var ticks := PhysicsTicks.ticks_for(BEFORE_THE_SWING + AFTER_THE_SWING, SCALE)
	var swing_tick := PhysicsTicks.ticks_for(BEFORE_THE_SWING, SCALE)
	# At dawn, before any mover has stepped: each joined where it stands.
	_check_the_tick(t, main, seed_value, -1, counts, seen, last)
	_before_the_tick(t, main, seed_value, 0, swing_tick, swing, step, counts, seen, last)
	var after_each := func(ran: int) -> void:
		counts["ticks"] += 1
		_check_the_tick(t, main, seed_value, ran - 1, counts, seen, last)
		if ran < ticks:
			_before_the_tick(t, main, seed_value, ran, swing_tick, swing, step, counts, seen, last)
	await PhysicsTicks.pass_ticks_faster(t, ticks, PhysicsTicks.FASTER, after_each, SCALE)
	t.check(day.is_running(), "seed %d: the day still runs at the walk's end" % seed_value)
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
	booted.free_all()
	seat.end()

## What happens to her before the physics tick `tick` runs: the walk toward the swing, stood against
## a walker now and then, and the swing touched when the tick comes.
func _before_the_tick(t: TestRunner, main: Node2D, seed_value: int, tick: int, swing_tick: int,
		swing: Vector2, step: float, counts: Dictionary, seen: Dictionary, last: Dictionary) -> void:
	var player := Boot.player(main)
	if tick == swing_tick:
		t.check(Boot.day(main).is_running(), "seed %d: the day still runs when the swing is touched"
				% seed_value)
		player.global_position = swing
		var task := Boot.resistance(main).contact()
		if task:
			task.complete_now()
		# The cordon's officers set out on the tick that follows, none of them stepped yet.
		_check_the_tick(t, main, seed_value, tick, counts, seen, last)
	elif tick < swing_tick and tick % BUMP_EVERY == BUMP_EVERY - 1:
		_stand_against_a_walker(main)
	else:
		var here: Vector2 = player.global_position
		player.global_position = here.move_toward(swing, step)

## Stands her a few pixels off the nearest walker, inside his bump radius, so his bump pushes him.
func _stand_against_a_walker(main: Node2D) -> void:
	var player := Boot.player(main)
	var here: Vector2 = player.global_position
	var nearest: CrowdAgent = null
	for agent in Boot.city(main).crowd.agents():
		if agent.kind != CrowdAgent.Kind.WALKER or not agent.is_inside_tree():
			continue
		if nearest == null or agent.global_position.distance_squared_to(here) \
				< nearest.global_position.distance_squared_to(here):
			nearest = agent
	if nearest != null:
		player.global_position = nearest.global_position + Vector2(Crowd.BUMP_RADIUS * 0.5, 0.0)

func _check_the_tick(t: TestRunner, main: Node2D, seed_value: int, tick: int, counts: Dictionary,
		seen: Dictionary, last: Dictionary) -> void:
	var city := Boot.city(main)
	# What each mover stands at, by what it is.
	var poses: Array[Array] = []
	for instance in city.events.instances():
		if not instance.is_inside_tree():
			continue
		var id := instance.get_instance_id()
		if not seen.has(id):
			seen[id] = true
			counts["came"] += 1
		poses.append(["event %s" % instance.def.id, instance.position])
	for agent in city.crowd.agents():
		if not agent.is_inside_tree():
			continue
		var id := agent.get_instance_id()
		if agent.is_turning():
			counts["turns"] += 1
		if last.has(id) and (last[id] as Vector2).distance_to(agent.position) > RECYCLE_JUMP:
			counts["recycled"] += 1
		last[id] = agent.position
		poses.append(["crowd %s" % CrowdAgent.Kind.keys()[agent.kind], agent.position])
	for figure: Node in city.get_node("Entities").get_children():
		var officer := figure as CordonOfficer
		if officer != null and not officer.is_queued_for_deletion():
			counts["officers"] += 1
			poses.append(["cordon officer", officer.position])
	_check_the_moves(t, seed_value, tick, poses, city.map.moves.all(), counts)

## Every mover's pose has a move on the list standing there and closed, and every move on the list
## is some mover's: a move left behind, or one still open, would show a body where nobody is.
func _check_the_moves(t: TestRunner, seed_value: int, tick: int, poses: Array[Array],
		listed: Array[MoveProposal], counts: Dictionary) -> void:
	var standing := {}
	var open := 0
	for move in listed:
		if move.open:
			open += 1
		elif move.from == move.to:
			standing[move.from] = int(standing.get(move.from, 0)) + 1
		else:
			open += 1
	for pose in poses:
		var at: Vector2 = pose[1]
		if int(standing.get(at, 0)) > 0:
			standing[at] = int(standing[at]) - 1
			continue
		_count_one_wrong(t, seed_value, tick, pose[0], "no closed move on the list stands at %s" % at,
				counts)
	for at: Vector2 in standing:
		for i in int(standing[at]):
			_count_one_wrong(t, seed_value, tick, "a listed move",
					"it stands at %s, where no mover does" % at, counts)
	for i in open:
		_count_one_wrong(t, seed_value, tick, "a listed move", "it is open or between two poses",
				counts)

func _count_one_wrong(t: TestRunner, seed_value: int, tick: int, what: String, why: String,
		counts: Dictionary) -> void:
	counts["wrong"] += 1
	var kinds: Dictionary = counts["by_kind"]
	var kind := what.get_slice(" ", 0) if what.begins_with("event") else what
	kinds[kind] = int(kinds.get(kind, 0)) + 1
	if counts["wrong"] <= SHOWN:
		t.check(false, "seed %d tick %d: %s: %s" % [seed_value, tick, what, why])
