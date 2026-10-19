extends RefCounted
## Measurement probe for whether the escape's city section can be got through (downy-tapir,
## winnable-escape; minty-lemur #794, #785). Not a suite: it prints a table rather than asserting,
## so it lives under `tests/probes/` and runs only by name:
##
##     tools/test.sh probes/escape_winnable.gd          (prints ESCAPE_WINNABLE lines)
##
## **What it measures, per seed and per exit.** The section's plan as a straight city boot builds
## it (`--start-escape city`: `GameState.start_run(seed)`, the city built from the run seed, the
## plan drawn from `GameState.day_rng(day, "finale")`, as `main._plan_the_finale_city()` draws it):
## how many of the escape's four rows stand on each open street and how many streets stand none;
## the shortest walk from the service exit to the tunnel and to the bridge past every body standing
## for the whole walk (the bodies `tests/test_finale.gd` floods past) and keeping out of every
## van's lethal reach; how many of each row stand on that walk; and then that walk, walked through
## the plan's own events, once at `Tuning.WALK_SPEED` and once at `Tuning.RUN_SPEED`, from the
## sleeping baby and the empty meter a section starts with.
##
## **What is real and what is stood in for.** The city, the plan, `EventManager` (streaming,
## successors, the craters a burst leaves) and every `EventInstance` are the game's own, ticked by
## hand at the physics rate the way `tests/test_full_run.gd` ticks a day, with a real `Stroller`
## (physics off, moved by hand, so `run_excess_ratio()` and `is_idle()` read her real speed) as
## the one the manager tells every event about. **The meter is stood in for**: `Meter` below feeds
## it the way `Baby._update_excitement()`, `_update_sleepiness()` and `_update_state()` do —
## everything `City.excitement_sources_at()` lands, her own running, the alley's dread, the
## ground's decay multiplier, `Tuning.SLEEPING_SENSITIVITY` while asleep, the wake at
## `Tuning.EXCITEMENT_WAKE_THRESHOLD`, sleep coming back on calm ground, and crying once the bar
## sits at the top and `Tuning.EXCITEMENT_OVERFLOW_TO_CRY` more lands inside the overflow window.
## And the camera: each waiting charger is handed the view `RoadblockRig.view_round()` gives round
## her heading, since a rig has no viewport to look through. Collisions are not run: her line keeps
## a body's clearance off every solid piece by construction.
##
## **Her pace and her answers are the "sensible pace".** She follows the walk at the pace asked;
## when a roadblock's guard raises his hand she stands, `REACTION` after he charges she runs back
## along the walk until no charge is running, then stands until every guard she drew off has left
## his post for good, then walks on — the lure `tests/escape_roadblock_rig.gd` walks, played on the
## real plan. She does nothing else clever: she never stops to settle the baby, and she never waits
## for a burst to finish.
##
## **Why not the real game.** `RouteRig` (`--route`) is the game's own walker and it is not built on
## the `--start-escape` boot, which returns before the rig is made; wiring it there is `src/main.gd`
## and `src/dev/`, outside this probe's change. The cost of standing in is stated above.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const FinaleSuite := preload("res://tests/test_finale.gd")
const RoadblockRig := preload("res://tests/escape_roadblock_rig.gd")

## Twenty-four run seeds: `tests/test_finale.gd`'s own four, the probe seeds the escape's other
## probes use, the seed the player could not win (inbox #771 in minty-lemur), and small primes.
const SEEDS: Array[int] = [4242, 1, 77, 9001, 23, 5, 31337, 2024, 7, 808, 4216201080, 11, 13, 17,
		19, 29, 31, 37, 41, 43, 47, 53, 59, 61]
const ROWS: Array[String] = ["military_convoy", "finale_explosion", "abduction", "roadblock"]
const SHORT := {"military_convoy": "truck", "finale_explosion": "boom", "abduction": "van",
		"roadblock": "block"}
## The physics rate, the rate `EventManager` is ticked at in the game.
const STEP := 1.0 / 30.0
## How close to her walk a row stands to count as standing on it: half a street's width.
const ON_THE_WALK := 96.0
## How far off a van's lethal reach her walk is planned, px, on top of the reach itself.
const VAN_MARGIN := 6.0
## Her reaction to a guard's charge, s, as in `RoadblockRig.lure()`.
const REACTION := 0.3
## The grid her walk is planned on, px, the step `tests/test_finale.gd` floods past bodies on.
const GRID := 8.0
## The mixes measured: `slots` a street and the bag's marbles, trucks, explosions, vans, roadblocks
## and empty, in the player's order. `as built` is `Tuning`'s own, through `FinalePlanner.plan()`
## exactly as the game plans it. `ESCAPE_WINNABLE_MIX` replaces the list, as
## `<slots>:<trucks>,<explosions>,<vans>,<roadblocks>,<empty>` mixes separated by `;`.
const MIXES: Array[Dictionary] = [
	{"name": "as built"},
]

func run(t) -> void:
	var saved_seed := GameState.run_seed
	var saved_day := GameState.day
	var rows: Array[Dictionary] = []
	var mixes := _mixes()
	for seed_value in _seeds():
		rows.append_array(_measure_seed(t, seed_value, mixes))
	for mix in mixes:
		var own: Array[Dictionary] = []
		for row in rows:
			if row["mix"] == mix["name"]:
				own.append(row)
		_print_summary(mix["name"], own)
	GameState.run_seed = saved_seed
	GameState.day = saved_day
	t.check(true, "a probe asserts nothing")

## `SEEDS`, or the comma-separated seeds in `ESCAPE_WINNABLE_SEEDS` when it is set, for a quick look
## at one city.
func _seeds() -> Array[int]:
	var given := OS.get_environment("ESCAPE_WINNABLE_SEEDS")
	if given == "":
		return SEEDS
	var found: Array[int] = []
	for word in given.split(",", false):
		found.append(int(word))
	return found

## `MIXES`, or the ones `ESCAPE_WINNABLE_MIX` names.
func _mixes() -> Array[Dictionary]:
	var given := OS.get_environment("ESCAPE_WINNABLE_MIX")
	if given == "":
		return MIXES
	var found: Array[Dictionary] = []
	for text in given.split(";", false):
		var halves := text.split(":")
		var counts: Array[int] = []
		for word in halves[1].split(","):
			counts.append(int(word))
		found.append({"name": text, "slots": int(halves[0]), "counts": counts})
	return found

## Every mix's rows for one seed: one per exit.
func _measure_seed(t, seed_value: int, mixes: Array[Dictionary]) -> Array[Dictionary]:
	GameState.start_run(seed_value)
	var day := GameState.day
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(GameState.run_seed))
	GameState.city_state.begin_day(city.map.block_plans, day)
	city.start_finale(GameState.city_state, day)
	city.crowd.clear()
	city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	her.add_child(camera)
	her.carrying = true
	t.add_child(her)
	her.set_physics_process(false)
	var found: Array[Dictionary] = []
	var map := city.map
	var start := FinalePlanner.service_exit_world_position(map)
	for mix in mixes:
		var plan := _plan(map, day, mix)
		var streets := _street_counts(map, plan)
		for kind in [CityEdge.Kind.TUNNEL, CityEdge.Kind.BRIDGE]:
			var exit := map.tile_to_world(FinalePlanner.exit_tile(map, kind))
			var walk := _plan_the_walk(t, map, plan, start, exit)
			var row := {"mix": mix["name"], "seed": seed_value,
					"exit": "tunnel" if kind == CityEdge.Kind.TUNNEL else "bridge",
					"streets": streets["streets"], "empty": streets["empty"],
					"dangers": streets["dangers"], "length": _length(walk["line"]),
					"van_kept": walk["van_kept"], "reached": walk["reached"]}
			row["on_walk"] = _on_the_walk(map, plan, walk["line"])
			for pace: float in [Tuning.WALK_SPEED, Tuning.RUN_SPEED]:
				# A fresh plan for each walk: a plan's placements carry what their instances did.
				var fresh := _plan(map, day, mix)
				var result := _walk_it(city, her, fresh, walk["line"], exit, pace)
				row["walk" if pace == Tuning.WALK_SPEED else "run"] = result
			print(_line(row))
			found.append(row)
	her.free()
	city.free()
	return found

## The section's plan, drawn the way a straight city boot draws it; for a mix other than `as built`,
## the same plan with the escape's events drawn from that mix's bag on the stream the game's own
## bag is drawn on (`EventScheduler.escape_bag_seed()`), handed to `build_finale()` in place of
## `Tuning`'s.
func _plan(map: CityMap, day: int, mix: Dictionary) -> FinalePlanner.Plan:
	var rng := GameState.day_rng(day, "finale")
	if not mix.has("slots"):
		return FinalePlanner.plan(map, rng)
	var plan := FinalePlanner.plan(map, rng, false)
	var seals: Array[EventScheduler.Planned] = []
	seals.assign(plan.placements)
	var counts: Array = mix["counts"]
	var bag := EventScheduler.escape_bag({"military_convoy": counts[0],
			"finale_explosion": counts[1], "abduction": counts[2], "roadblock": counts[3],
			EventScheduler.ESCAPE_EMPTY_MARBLE: counts[4]}, EventScheduler.escape_bag_seed(rng))
	var ends: Array[Vector2] = [
			map.tile_to_world(FinalePlanner.exit_tile(map, CityEdge.Kind.TUNNEL)),
			map.tile_to_world(FinalePlanner.exit_tile(map, CityEdge.Kind.BRIDGE))]
	plan.placements.append_array(EventScheduler.build_finale(map, rng, plan.open_streets,
			FinalePlanner.service_exit_world_position(map), seals, ends, bag, int(mix["slots"])))
	return plan

## `{streets, empty, dangers}`: the open streets, those standing none of the four rows, and how many
## of the four rows stand on them in all.
func _street_counts(map: CityMap, plan: FinalePlanner.Plan) -> Dictionary:
	var empty := 0
	var dangers := 0
	for segment in plan.open_streets:
		var rect := map.tile_rect_to_world(segment.tile_rect()).grow(1.0)
		var here := 0
		for placement in plan.placements:
			if ROWS.has(placement.def.id) and rect.has_point(placement.position):
				here += 1
		dangers += here
		if here == 0:
			empty += 1
	return {"streets": plan.open_streets.size(), "empty": empty, "dangers": dangers}

## How many of each row stand within `ON_THE_WALK` of her line; a truck by the nearest point of
## its route.
func _on_the_walk(map: CityMap, plan: FinalePlanner.Plan, line: PackedVector2Array) -> Dictionary:
	var counts := {}
	for id in ROWS:
		counts[id] = 0
	for placement in plan.placements:
		if not ROWS.has(placement.def.id):
			continue
		var points: PackedVector2Array = placement.path if placement.path.size() > 1 \
				else PackedVector2Array([placement.position])
		var near := false
		for point in points:
			if _distance_to_line(point, line) <= ON_THE_WALK:
				near = true
				break
		if near:
			counts[placement.def.id] = int(counts[placement.def.id]) + 1
	return counts

static func _distance_to_line(point: Vector2, line: PackedVector2Array) -> float:
	var best := INF
	for i in range(line.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(point, line[i], line[i + 1])
		best = minf(best, closest.distance_to(point))
	return best

static func _length(line: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(line.size() - 1):
		total += line[i].distance_to(line[i + 1])
	return total

# ------------------------------------------------------------------ the walk ---

## The shortest walk from `start` to `exit` on the `GRID` past every body standing for the whole
## walk, kept `VAN_MARGIN` outside each van's lethal reach as well; where that leaves no walk, the
## walk without the vans' reach (`van_kept` false). `{line, reached, van_kept}`.
func _plan_the_walk(t, map: CityMap, plan: FinalePlanner.Plan, start: Vector2,
		exit: Vector2) -> Dictionary:
	var blocked := {}
	FinaleSuite._block_every_body(t, map, plan, blocked)
	var with_vans := blocked.duplicate()
	for placement in plan.placements:
		if placement.def.id != "abduction":
			continue
		var instance := EventInstance.new()
		instance.setup(placement.def, placement.position, placement.path, placement.facing, map)
		var at := instance.position
		instance.free()
		# Her centre is what a van takes her by (`EventInstance.is_lethal_at()`).
		var reach := placement.def.lethal_reach() + VAN_MARGIN
		for gy in range(floori((at.y - reach) / GRID), ceili((at.y + reach) / GRID) + 1):
			for gx in range(floori((at.x - reach) / GRID), ceili((at.x + reach) / GRID) + 1):
				if (Vector2(gx, gy) * GRID).distance_to(at) <= reach:
					with_vans[Vector2i(gx, gy)] = true
	var line := _shortest(map, with_vans, start, exit)
	if not line.is_empty():
		return {"line": line, "reached": true, "van_kept": true}
	line = _shortest(map, blocked, start, exit)
	return {"line": line, "reached": not line.is_empty(), "van_kept": false}

## A* over the grid's points her centre fits on, eight ways, a diagonal only where both of its
## sides are open. Ends within `Tuning.FINALE_EXIT_REACH` of `exit`, less a grid step. Empty when
## no walk exists.
func _shortest(map: CityMap, blocked: Dictionary, start: Vector2, exit: Vector2) -> PackedVector2Array:
	var width := ceili(float(map.size.x * Tuning.TILE_SIZE) / GRID) + 1
	var height := ceili(float(map.size.y * Tuning.TILE_SIZE) / GRID) + 1
	var fits := PackedByteArray()
	fits.resize(width * height)
	# 0 not asked yet, 1 fits, 2 does not.
	var cost := PackedFloat32Array()
	cost.resize(width * height)
	cost.fill(INF)
	var came := PackedInt32Array()
	came.resize(width * height)
	came.fill(-1)
	var from := Vector2i(roundi(start.x / GRID), roundi(start.y / GRID))
	var goal_reach := Tuning.FINALE_EXIT_REACH - GRID
	var begin := from.x + from.y * width
	cost[begin] = 0.0
	var heap: Array = [[_heuristic(from, exit), begin]]
	var ended := -1
	var steps: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	while not heap.is_empty():
		var top: Array = _pop(heap)
		var index: int = top[1]
		var at := Vector2i(index % width, index / width)
		if top[0] > cost[index] + _heuristic(at, exit) + 0.001:
			continue
		if (Vector2(at) * GRID).distance_to(exit) <= goal_reach:
			ended = index
			break
		for step in steps:
			var next := at + step
			if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
				continue
			if not _open(map, blocked, fits, width, next):
				continue
			if step.x != 0 and step.y != 0 and (
					not _open(map, blocked, fits, width, at + Vector2i(step.x, 0))
					or not _open(map, blocked, fits, width, at + Vector2i(0, step.y))):
				continue
			var next_index := next.x + next.y * width
			var through: float = cost[index] + (1.4142 if step.x != 0 and step.y != 0 else 1.0) * GRID
			if through < cost[next_index]:
				cost[next_index] = through
				came[next_index] = index
				_push(heap, [through + _heuristic(next, exit), next_index])
	if ended < 0:
		return PackedVector2Array()
	var reversed: Array[Vector2] = []
	var walk := ended
	while walk >= 0:
		reversed.append(Vector2(walk % width, walk / width) * GRID)
		walk = came[walk]
	var line := PackedVector2Array()
	line.append(start)
	for i in range(reversed.size() - 2, -1, -1):
		line.append(reversed[i])
	return line

static func _heuristic(at: Vector2i, exit: Vector2) -> float:
	return (Vector2(at) * GRID).distance_to(exit)

func _open(map: CityMap, blocked: Dictionary, fits: PackedByteArray, width: int,
		point: Vector2i) -> bool:
	var index := point.x + point.y * width
	if fits[index] == 0:
		var ok := not blocked.has(point) and FinaleSuite._she_fits(map, point, {})
		fits[index] = 1 if ok else 2
	return fits[index] == 1

static func _push(heap: Array, item: Array) -> void:
	heap.append(item)
	var i := heap.size() - 1
	while i > 0:
		var parent := (i - 1) / 2
		if heap[parent][0] <= heap[i][0]:
			break
		var swap: Array = heap[parent]
		heap[parent] = heap[i]
		heap[i] = swap
		i = parent

static func _pop(heap: Array) -> Array:
	var top: Array = heap[0]
	var last: Array = heap.pop_back()
	if heap.is_empty():
		return top
	heap[0] = last
	var i := 0
	while true:
		var left := i * 2 + 1
		var right := left + 1
		var least := i
		if left < heap.size() and heap[left][0] < heap[least][0]:
			least = left
		if right < heap.size() and heap[right][0] < heap[least][0]:
			least = right
		if least == i:
			break
		var swap: Array = heap[least]
		heap[least] = heap[i]
		heap[i] = swap
		i = least
	return top

## The point `s` px along `line`, and the way the line runs there.
static func _along(line: PackedVector2Array, s: float) -> Array:
	var left := s
	for i in range(line.size() - 1):
		var piece := line[i].distance_to(line[i + 1])
		if left <= piece or i == line.size() - 2:
			var heading := (line[i + 1] - line[i]).normalized()
			return [line[i] + heading * minf(left, piece), heading]
		left -= piece
	return [line[line.size() - 1], Vector2.ZERO]

## Walks `line` through the plan's events at `pace`, answering `{outcome, seconds, peak, end,
## woke, lured, struck}`: `outcome` one of `out`, `caught`, `cried`, `clock`, `no walk`.
func _walk_it(city: City, her: Stroller, plan: FinalePlanner.Plan, line: PackedVector2Array,
		exit: Vector2, pace: float) -> Dictionary:
	if line.size() < 2:
		return {"outcome": "no walk", "seconds": 0.0, "peak": 0.0, "end": 0.0, "woke": -1.0,
				"lured": 0, "struck": "", "landed": {}}
	var length := _length(line)
	var start := line[0]
	her.global_position = start
	her.velocity = Vector2.ZERO
	city.events.start_finale(plan.placements, start)
	var meter := Meter.new()
	var s := 0.0
	var clock := 0.0
	var outcome := "clock"
	var struck := ""
	var lured := {}
	var charged_for := 0.0
	var waited := 0.0
	var heading := (line[1] - line[0]).normalized()
	while clock < Tuning.FINALE_LENGTH_SECONDS:
		var instances := city.events.instances()
		var chasing := false
		var warned := false
		for instance in instances:
			if not is_instance_valid(instance) or instance.is_finished:
				continue
			if instance.is_chasing():
				chasing = true
				lured[instance] = true
			elif instance.def.pursues_within > 0.0 and not instance.is_waiting() \
					and not instance.is_a_spent_guard():
				warned = true
		var still_out := false
		for instance: EventInstance in lured:
			if is_instance_valid(instance) and not instance.is_finished \
					and not (instance.is_a_spent_guard() and not instance.is_leaving):
				still_out = true
		var speed := 0.0
		var direction := 1.0
		if chasing:
			charged_for += STEP
			if charged_for > REACTION:
				speed = Tuning.RUN_SPEED
				direction = -1.0
		elif warned:
			charged_for = 0.0
		elif still_out and waited < Tuning.PURSUIT_TIME:
			charged_for = 0.0
			waited += STEP
		else:
			charged_for = 0.0
			waited = 0.0
			speed = pace
		s = clampf(s + speed * direction * STEP, 0.0, length)
		var where: Array = _along(line, s)
		var at: Vector2 = where[0]
		if where[1] != Vector2.ZERO:
			heading = where[1]
		var facing: Vector2 = heading * direction
		her.global_position = at
		her.velocity = facing * speed
		city.events._physics_process(STEP)
		var view := RoadblockRig.view_round(at, facing)
		for instance in city.events.instances().duplicate():
			if not is_instance_valid(instance) or instance.is_finished:
				continue
			instance.player_view = view
			instance.baby_awake = not meter.asleep
			instance._process(STEP)
		for instance in city.events.instances():
			if is_instance_valid(instance) and instance.is_lethal_at(at):
				struck = instance.def.id
				break
		if struck != "":
			outcome = "caught"
			break
		meter.feed(city, her, at, STEP)
		if meter.cried:
			outcome = "cried"
			break
		clock += STEP
		if at.distance_to(exit) <= Tuning.FINALE_EXIT_REACH:
			outcome = "out"
			break
	var result := {"outcome": outcome, "seconds": clock, "peak": meter.peak,
			"end": meter.excitement, "woke": meter.woke_at, "lured": lured.size(), "struck": struck,
			"landed": meter.landed}
	city.events.clear()
	return result

## The meter, fed the way `Baby` feeds it. See the class note for what is stood in for.
class Meter extends RefCounted:
	var excitement := 0.0
	var sleepiness := Tuning.METER_MAX
	var asleep := true
	var cried := false
	var peak := 0.0
	## What each row landed on the meter in all, by id, after the sleeping baby's sensitivity.
	var landed := {}
	var woke_at := -1.0
	var _clock := 0.0
	var _overflow: Array = []

	func feed(city: City, her: Stroller, at: Vector2, delta: float) -> void:
		_clock += delta
		var incoming := 0.0
		var sensitivity := Tuning.SLEEPING_SENSITIVITY if asleep else 1.0
		for pair in city.excitement_sources_at(at):
			incoming += pair[1]
			var source: Object = pair[0]
			var id: String = source.def.id if source is EventInstance else "crowd"
			landed[id] = float(landed.get(id, 0.0)) + float(pair[1]) * sensitivity * delta
		var ratio := her.run_excess_ratio()
		incoming += Tuning.EXCITEMENT_FROM_RUNNING * ratio
		if city.is_alley(at):
			incoming += Tuning.EXCITEMENT_FROM_ALLEY
		incoming *= sensitivity
		var decay := Tuning.EXCITEMENT_DECAY_WALKING
		if her.is_idle():
			decay = Tuning.EXCITEMENT_DECAY_IDLE
		elif ratio > 0.0:
			decay = Tuning.EXCITEMENT_DECAY_RUNNING
		decay *= city.decay_multiplier(at)
		var before := excitement
		var net := incoming - decay
		excitement = clampf(before + net * delta, 0.0, Tuning.METER_MAX)
		peak = maxf(peak, excitement)
		if before >= Tuning.METER_MAX and net > 0.0:
			_overflow.append([_clock, net * delta])
		while not _overflow.is_empty() \
				and _overflow[0][0] < _clock - Tuning.EXCITEMENT_OVERFLOW_WINDOW:
			_overflow.pop_front()
		var overflow := 0.0
		for entry: Array in _overflow:
			overflow += entry[1]
		if excitement >= Tuning.METER_MAX and overflow >= Tuning.EXCITEMENT_OVERFLOW_TO_CRY:
			cried = true
			return
		if not asleep:
			if excitement >= Tuning.EXCITEMENT_CALM_THRESHOLD:
				pass
			elif her.is_idle():
				sleepiness -= Tuning.SLEEPINESS_DRAIN_IDLE * delta
			elif ratio <= 0.0:
				sleepiness += Tuning.SLEEPINESS_GAIN_WALKING * city.sleepiness_multiplier(at) * delta
			sleepiness = clampf(sleepiness, 0.0, Tuning.METER_MAX)
			if sleepiness >= Tuning.METER_MAX:
				asleep = true
		elif excitement >= Tuning.EXCITEMENT_WAKE_THRESHOLD:
			asleep = false
			sleepiness = Tuning.WAKE_SLEEPINESS_PENALTY
			if woke_at < 0.0:
				woke_at = _clock

# ------------------------------------------------------------------- printing ---

func _counts(counts: Dictionary) -> String:
	var parts: Array[String] = []
	for id in ROWS:
		parts.append("%s %d" % [SHORT[id], int(counts.get(id, 0))])
	return " ".join(parts)

func _result(result: Dictionary) -> String:
	var text := "%s %.1fs peak %.0f end %.0f" % [result["outcome"], result["seconds"],
			result["peak"], result["end"]]
	if result["woke"] >= 0.0:
		text += " woke %.0fs" % result["woke"]
	if result["lured"] > 0:
		text += " lured %d" % result["lured"]
	if result["struck"] != "":
		text += " by %s" % result["struck"]
	var landed: Dictionary = result["landed"]
	var parts: Array[String] = []
	for id: String in landed:
		if float(landed[id]) >= 0.5:
			parts.append("%s %.0f" % [SHORT.get(id, id), landed[id]])
	if not parts.is_empty():
		text += " (landed: %s)" % ", ".join(parts)
	return text

func _line(row: Dictionary) -> String:
	return ("ESCAPE_WINNABLE [%s] seed %d %s | %d streets, %d with none, %d dangers | walk %.0fpx%s%s"
			+ " | on it: %s | walking: %s | running: %s") % [row["mix"], row["seed"], row["exit"],
			row["streets"], row["empty"], row["dangers"], row["length"],
			"" if row["reached"] else " (no walk)",
			"" if row["van_kept"] else " (through a van's reach)", _counts(row["on_walk"]),
			_result(row["walk"]), _result(row["run"])]

func _print_summary(mix: String, rows: Array[Dictionary]) -> void:
	var streets := 0
	var empty := 0
	var dangers := 0
	var seen := {}
	var on_walk := {}
	var outcomes := {"walk": {}, "run": {}}
	var peaks := {"walk": 0.0, "run": 0.0}
	var outs := {"walk": 0, "run": 0}
	var times := {"walk": 0.0, "run": 0.0}
	for row in rows:
		if not seen.has(row["seed"]):
			seen[row["seed"]] = true
			streets += int(row["streets"])
			empty += int(row["empty"])
			dangers += int(row["dangers"])
		for id in ROWS:
			on_walk[id] = int(on_walk.get(id, 0)) + int(row["on_walk"][id])
		for pace: String in ["walk", "run"]:
			var result: Dictionary = row[pace]
			var outcome: String = result["outcome"]
			outcomes[pace][outcome] = int(outcomes[pace].get(outcome, 0)) + 1
			peaks[pace] += float(result["peak"])
			if outcome == "out":
				outs[pace] += 1
				times[pace] += float(result["seconds"])
	var walks := rows.size()
	var averaged := {}
	for id in ROWS:
		averaged[id] = float(on_walk.get(id, 0)) / maxf(1.0, walks)
	print("ESCAPE_WINNABLE [%s] | %d seeds, %d walks | %.2f dangers a street, %.0f%% of streets with none"
			% [mix, seen.size(), walks, float(dangers) / maxf(1.0, streets),
			100.0 * empty / maxf(1.0, streets)])
	var parts: Array[String] = []
	for id in ROWS:
		parts.append("%s %.1f" % [SHORT[id], averaged[id]])
	print("ESCAPE_WINNABLE [%s] | on a walk, on average: %s" % [mix, " ".join(parts)])
	for pace: String in ["walk", "run"]:
		print("ESCAPE_WINNABLE [%s] | %s: %s | mean peak %.0f | out in %.1fs on average" % [
				mix, "walking" if pace == "walk" else "running", outcomes[pace], peaks[pace] / walks,
				times[pace] / maxf(1.0, outs[pace])])
