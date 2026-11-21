extends RefCounted
## **Every answer every row gives**, so minty-quail row 4b's pull requests can show that writing a row
## as its parts changes no answer. Not a suite: it prints rather than asserts. Run by name, before and
## after a change, and compare. **Its output is its standard output** (`tools/test.sh` passes the
## engine's through), kept in a scratch folder outside the checkout, never committed. A step runs it on
## its base (`origin/main`) and on its head, in two worktrees, and `diff`s the two `RF` files:
##
##     tools/test.sh probes/row_fingerprint.gd > before.txt
##     grep -E '^RF[VP]? ' before.txt > before.rf      (the same after; diff the two .rf files)
##
## A run takes about fifteen seconds and is deterministic: two runs of one tree give identical `RF`
## lines. The step's rule is the design's: every base line is on the head unchanged, or under a part's
## prefix (`body().is_walked_round()` for the row's `is_walked_round()`) where the step moved a question
## into that part, and every such move is listed in the pull request's description; a head line with no
## base line is a question the step added; a changed `RFV` or `RFP` hash is read with `FULL` and is a
## failure unless it is one of those moves. `RF_DONE` ends the output, so a run that stopped early shows.
##
## Every public method of the row (found on the row's own script, so a method a pull request adds
## appears as a new line and one it removes as a missing line) is called on every catalogue row with
## a fixed table of arguments by parameter name; a method whose answer is an object other than a row
## (a shape, a piece, a part's settings) is printed through that object's own public methods, one
## level deep. `RF <id> <method>(<args>) <answer>` lines are the catalogue rows in full; `RFV
## <label> <hash> <lines>` the copies the game makes of them (each heat, each day, the copy sent
## ahead, the copy warned of first, the catalogue's own derived rows, a seal's copies); `RFP` the
## rows the region and seal planners stand on generated cities, by the same hash. A changed `RFV` or
## `RFP` hash is read in full by setting FULL.

const FULL := false
const SKIP: Array[String] = ["solid", "weigh_on", "send_ahead", "span_the_street", "draw_to_sack_piles",
		"validate", "at_heat", "for_day", "as_sent_ahead", "as_warned_first", "part", "redraft",
		"get_class", "duplicate"]
## The rows the game makes a copy warned of first of (`EventSpawner.as_warned()`): the copy validates
## itself as it is made, and only these are held to the flat minimum a warning first owes.
const WARNED_FIRST: Array[String] = ["military_convoy", "charging_dog"]
const SEEDS: Array[int] = [90210, 90241, 90272]
const DAYS: Array[int] = [3, 6, 9, 12, 14]

var _samples := {}

func run(t: TestRunner) -> void:
	_samples = {
		"count": [1, 2], "day": range(0, Tuning.RUN_LENGTH_DAYS + 2), "beside_the_routes": ["", "x"],
		"type": GameEnums.TileType.values(), "start": PursuitSpec.Start.values(),
		"ground": PlacementGround.Kind.values(), "run": [0.0, 24.0, 64.0, 128.0],
		"point": [0.0, 0.25, 0.5, 1.0], "at": [Vector2.ZERO, Vector2(10, 4), Vector2(40, -30), Vector2(150, 0)],
		"at_distance": [0.0, 10.0, 30.0, 60.0, 100.0, 150.0, 250.0], "at_intensity": [-1.0, 5.0],
		"share": [0.25, 1.0], "outer": [80.0, 200.0], "rate": [0.5, 2.0, 6.0],
		"walk_speed": [Tuning.WALK_SPEED, 150.0], "age": [0.0, 1.5, 7.0], "into_its_burst": [0.0, 0.5],
		"beat": [-1.0, 0.5], "vertical": [false, true],
	}
	var rows := EventCatalogue.all()
	for row in rows:
		for line in _dump(row):
			print("RF %s %s" % [row.id, line])
	var count := rows.size()
	for row in rows:
		for level in range(1, EventCatalogue.heat_levels()):
			_variant("%s@heat%d" % [row.id, level], EventCatalogue.heated(row, level))
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			_variant("%s@day%d" % [row.id, day], row.for_day(day))
		if row.is_sent_ahead():
			_variant("%s@sent" % row.id, row.as_sent_ahead())
		if row.id in WARNED_FIRST:
			_variant("%s@warned" % row.id, row.as_warned_first())
		_variant("%s@sealed" % row.id, SealPlanner.sealed_variant(row, false))
		_variant("%s@sealed_kerb" % row.id, SealPlanner.sealed_variant(row, true))
		_variant("%s@ground" % row.id, EventDirector._with_ground(row))
	_variant("escape_roadblock", EventCatalogue.escape_roadblock())
	_variant("building_fire", EventCatalogue.building_fire())
	_variant("explosion_outside", EventCatalogue.explosion_outside())
	_variant("lesson_dog", EventCatalogue.lesson_of(EventCatalogue.by_id("charging_dog")))
	_variant("task_guard", EventCatalogue.task_guard())
	_variant("task_guard_sent", EventCatalogue.task_guard_sent())
	_variant("neighbor_heading_home", EventCatalogue.neighbor_heading_home())
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var spec := DaySpec.for_day(day)
		_variant("on_foot@day%d" % day, EventCatalogue.on_foot_on(spec))
		_variant("out_of_the_car@day%d" % day, EventCatalogue.out_of_the_car(spec))
		_variant("out_of_the_car_goes@day%d" % day, EventCatalogue.out_of_the_car(spec, false))
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		for day in DAYS:
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var spec := DaySpec.for_day(day)
			var region := RegionPlanner.plan_day(map, spec, tree)
			var stood: Array[EventPlan] = []
			stood.append_array(region.door_bodies)
			stood.append_array(region.wall_bodies)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("row_fingerprint seals:%d:%d" % [seed_value, day])
			stood.append_array(SealPlanner.plan_day(map, spec, tree, rng))
			var seen := {}
			for plan in stood:
				var text := "\n".join(_dump(plan.row()))
				var key := "%s %d" % [plan.row_id(), text.hash()]
				if not seen.has(key):
					seen[key] = true
					print("RFP %d %d %s %d" % [seed_value, day, plan.row_id(), text.hash()])
	print("RF_DONE rows %d" % count)
	t.check(true, "ran")

func _variant(label: String, row: EventDef) -> void:
	var lines := _dump(row)
	print("RFV %s %d %d" % [label, "\n".join(lines).hash(), lines.size()])
	if FULL:
		for line in lines:
			print("RFF %s %s" % [label, line])

func _dump(target: Object, prefix := "", depth := 0) -> PackedStringArray:
	var lines := PackedStringArray()
	var script := target.get_script() as Script
	var methods := script.get_script_method_list()
	methods.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.name) < String(b.name))
	var done := {}
	for method: Dictionary in methods:
		var name := String(method.name)
		if name.begins_with("_") or name in SKIP or done.has(name) or (int(method.flags) & METHOD_FLAG_STATIC):
			continue
		done[name] = true
		var params: Array = method.args
		var combos: Array = [[]]
		var missing := ""
		for param: Dictionary in params:
			var values: Array = _samples.get(String(param.name), [])
			if values.is_empty():
				missing = String(param.name)
				break
			var grown: Array = []
			for combo: Array in combos:
				for value: Variant in values:
					grown.append(combo + [value])
			combos = grown
		if missing != "":
			lines.append("%s%s SKIPPED(no samples for %s)" % [prefix, name, missing])
			continue
		for combo: Array in combos:
			var answer: Variant = target.callv(name, combo)
			var call := "%s%s(%s)" % [prefix, name, ",".join(combo.map(func(v: Variant) -> String: return _text(v, 0)))]
			if answer is Object and not (answer is EventDef) and answer != null and depth == 0 \
					and not (answer is GroundShape):
				lines.append_array(_dump(answer as Object, call + ".", depth + 1))
			else:
				lines.append("%s %s" % [call, _text(answer, depth)])
	return lines

func _text(value: Variant, depth: int) -> String:
	if value == null:
		return "null"
	if value is float:
		return "%.5f" % value
	if value is EventDef:
		return "row:" + (value as EventDef).id
	if value is GroundShape:
		var shape := value as GroundShape
		return "GS(%d,%.4f,%.4f,%s)" % [shape.kind, shape.radius, shape.half_length, shape.half_extents]
	if value is Array:
		return "[" + ",".join((value as Array).map(func(v: Variant) -> String: return _text(v, depth))) + "]"
	if value is Object:
		var obj := value as Object
		if obj.has_method("offset_for"):
			return "P(%.4f,%.4f,%s)" % [obj.call("offset_for", false), obj.call("offset_for", true),
					_text(obj.call("ground_shape"), depth)]
		return "obj:" + String((obj.get_script() as Script).get_global_name()) if obj.get_script() else obj.get_class()
	return var_to_str(value)
