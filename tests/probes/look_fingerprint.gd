extends RefCounted
## **What every catalogue row's look draws, and what its drawn frames cost**, so a change to how the
## looks are built can be shown to draw exactly what they drew. Not a suite: it prints rather than
## asserts. Run by name, before and after a change, and compare the two outputs:
##
##     tools/test.sh probes/look_fingerprint.gd > before.txt
##     grep '^LK ' before.txt | shasum -a 256      (the same for after; `diff` the two `LK` files)
##
## **`LK` lines are the fingerprint**, deterministic and hashable. Every row of
## `CatalogueRows.every()` is stood twice, on open ground and on an east-west street, the way
## `tests/drawn_event.gd` stands one (a `RecordingEventDrawer` assigned before `setup()`, a map, a
## `WhereSheIs`), with an atlas that holds the events' group so that a crash's and a burst main's
## scenery is built. Each is stepped on a fixed tick (`1/30` s) through a drive, the same for every
## row, and every `SAMPLE_EVERY` ticks the frames a draw needs pass and the probe prints:
##
## - one line per picture the drawer was told since the last sample (canvas, kind, picture, rect,
##   mirrored, colour, band), a canvas named by what it is (`event`, `sliceN`, `band`, `far_guard`,
##   `sceneryN`) and never by an instance id;
## - one line of what a look made round a fake event that answers what the event answers
##   (`FakeEvent.answering_as()`) answers (`drawn_rect_now()`, `mark_rect()`, `current_bob()`) and
##   one of where each drawing node stands and whether it is shown, each only when it differs from
##   the last sample's. **A look made round a copy is not the live look**: it is handed no barrier
##   post, no stance and no view sector carried from frame to frame, so its `_drawn_heading()` (a
##   posted guard's heading at his band) is not printed; the heading the live look chose is in the
##   `D` lines, as the picture it stood on each canvas. The `A` line proves what the copy answers
##   for the drawn rectangle, the caret's rectangle and the bob, which no state the copy leaves out
##   changes in this catalogue; it no longer proves the heading.
##
## Every float is the hex of its 64 bits. The drives: `never` (she is never near), `walk` (she walks
## up to it, stands beside it and walks on, told through the `WhereSheIs` once a tick as its manager
## tells it), `away` (the same walk, and it is sent away: `leave_for_a_completed_task()`, then
## `give_up_the_chase()` for a pursuer that is chasing), and the states only a hand-in reaches, each
## set the way the game sets it, under the walk: `pelican`, `silenced`, `boom`, `hand`, `hold`,
## `points`.
##
## **`LK_SEEN` is the guard against a probe that checked nothing**: the look classes reached, the
## count of distinct pictures, and the rows that drew nothing (the rows with no picture of their
## own). **`LK_COST`** is the one line that is not the fingerprint: the microseconds a fixed number of
## drawn frames' own work (`EventInstance._process()`, whose cost is its look's redraw gate) took,
## the gate's share of a frame, for comparing two revisions' cost.
##
## **Which rows:** the catalogue's, each one's full-heat copy (`@heat`) and last-day copy (`@late`)
## where either differs from the row, so the roadblock's guard who sets off, its far guard and the
## later-day charging dog are drawn, and the derived rows a day makes: the man a patrol car lets out,
## the policeman on day 1 (through day 8) and the guardsman on the last day, each as a stop and as a
## hunt (`out_of_the_car`), and `building_fire`, `task_guard_sent`. The far guard's node places
## itself on the engine's physics tick, which two runs do not share, so the `N` lines leave his
## place out; his `D` lines are stable.
## The cost pass stands events of its own, after the fingerprint, so asking the gate changes no line.
## What no sample separates is a key term alone (`is_waiting()`, `is_chatting()`, `has_stopped_her()`,
## `is_on_its_way_out()`): each changes at the same sample as another term.
##
## **It asks only what every tree of the looks' step has.** Of `EventInstance`: `setup()`, `step()`,
## `hold`, `atlas`, `drawer`, `is_chasing()`, `leave_for_a_completed_task()`,
## `give_up_the_chase()`, `raise_its_guards_hand()`, `start_chat()`, and the members the spawner,
## streaming and the checkpoint controller write today (`be_drawn_as_the_pelican()`, `silence()`, `gate_state`,
## `points_at`). By string, so a rename shows as a difference in the labels rather than hiding one: a
## slice's place among the slices the drawer saw drawn (`RecordingEventDrawer.slices()`) and the far
## guard's node found by its name `FarGuard`. Of the look made round a fake: `drawn_rect_now()`,
## `mark_rect()`, `current_bob()`. Of the rows: `EventDef.id()`, `look`,
## `speed`, `for_day()`, and `CatalogueRows.every()`, `heated()`, `heat_levels()`,
## `out_of_the_car()`, `building_fire()`, `task_guard_sent()`. A later change which makes one
## of those private changes this probe with it.

const DrawnEvent := preload("res://tests/drawn_event.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")
const EastWestStreet := preload("res://tests/east_west_street.gd")

const STEP := 1.0 / 30.0
const SAMPLE_EVERY := 6
const TICKS := 540
## How many times each live event's redraw gate is asked in the cost pass, at tick `COST_AT`.
const COST_CALLS := 400
const COST_AT := 240
## Where she starts, where she stands beside the event and her speed in px per tick.
const AT := DrawnEvent.AT
const SHE_STARTS := Vector2(-450.0, 30.0)
const SHE_BESIDE := Vector2(-40.0, 40.0)
const SHE_PER_TICK := 4.5
const SHE_ARRIVES := 90
const SHE_STANDS_UNTIL := 180
const SHE_FAR := Vector2(6000.0, 0.0)
const LEAVE_AT := 150
const GIVE_UP_AT := 210
const SWITCH_ON_AT := 60
const SWITCH_OFF_AT := 240
const HOLD_AT := 120
const POINTS_MOVE_AT := 150

const DRIVES: Array[String] = ["never", "walk", "away", "pelican", "silenced", "boom", "hand",
		"hold", "points"]
const GROUNDS: Array[String] = ["open", "street"]

## One event of one drive, and what the probe remembers of it between samples.
class Rig extends RefCounted:
	var row: EventDef
	## The row's name in the output: its id, and which copy of it when it is not the catalogue's.
	var label := ""
	var ground := ""
	var drive := ""
	var holder: Node2D
	var instance: EventInstance
	var scenery_ids: Array[int] = []
	## The slices the drawer has seen so far, in the order they were first seen.
	var slices: Array[SpreadLook.Slice] = []
	var last_answer := ""
	var last_nodes := ""
	## What a protest is handed to point at (`points`).
	var point := Vector2.ZERO
	## The boom state a gate is handed (`boom`), which the drive raises and lowers.
	var gate: GateState

	func point_now() -> Vector2:
		return point

	func alive() -> bool:
		return instance != null and is_instance_valid(instance)

## What the whole run saw, for `LK_SEEN` and `LK_COST`.
class Seen extends RefCounted:
	var lines := 0
	var looks := {}
	var pictures := {}
	var row_draws := {}
	var cost_usec := 0
	var cost_calls := 0

func run(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(EventPictures.ATLAS_GROUP)
	var seen := Seen.new()
	_stand_the_rows()
	for label in _labels:
		seen.row_draws[label] = 0
	for ground in GROUNDS:
		for drive in DRIVES:
			await _drive(t, atlas, ground, drive, seen, false)
	# The cost pass stands its own events, so asking the gate leaves the fingerprint as it was.
	await _drive(t, atlas, "street", "walk", seen, true)
	atlas.release(EventPictures.ATLAS_GROUP)
	var empty: Array[String] = []
	for id: String in seen.row_draws:
		var drawn: int = seen.row_draws[id]
		if drawn == 0:
			empty.append(id)
	var classes: Array[String] = []
	for look_name: String in seen.looks:
		classes.append(look_name)
	classes.sort()
	print("LK_SEEN looks=%d [%s] pictures=%d empty=%d [%s]" % [classes.size(), ",".join(classes),
			seen.pictures.size(), empty.size(), ",".join(empty)])
	print("LK_COST %d usec over %d calls" % [seen.cost_usec, seen.cost_calls])
	print("LK_TOTAL %d lines" % seen.lines)
	t.check(seen.lines > 0, "there were pictures to print (%d)" % seen.lines)

## The rows the game stands, each with its name: the catalogue's, each one's full-heat copy
## (`EventCatalogue.shipped().heated()`) and its copy on the last day (`EventDef.for_day()`) where either
## differs from the row, and the derived rows a day makes (`out_of_the_car()`,
## `building_fire()`, `task_guard_sent()`).
func _stand_the_rows() -> void:
	var last_day := DaySpec.for_day(Tuning.RUN_LENGTH_DAYS)
	for row in CatalogueRows.every():
		_add_a_row(row, row.id())
		var hot := EventCatalogue.shipped().heated(row, EventCatalogue.heat_levels() - 1)
		if hot != row:
			_add_a_row(hot, row.id() + "@heat")
		var late := row.for_day(Tuning.RUN_LENGTH_DAYS)
		if late != row:
			_add_a_row(late, row.id() + "@late")
	_add_a_row(EventCatalogue.shipped().out_of_the_car(last_day), "guardsman_out_of_the_car")
	_add_a_row(EventCatalogue.shipped().out_of_the_car(last_day, false), "guardsman_out_of_the_car@hunts")
	var first_day := DaySpec.for_day(1)
	_add_a_row(EventCatalogue.shipped().out_of_the_car(first_day), "policeman_out_of_the_car")
	_add_a_row(EventCatalogue.shipped().out_of_the_car(first_day, false), "policeman_out_of_the_car@hunts")
	_add_a_row(EventCatalogue.shipped().building_fire(), "building_fire")
	_add_a_row(EventCatalogue.shipped().task_guard_sent(), "task_guard_sent")

func _add_a_row(row: EventDef, label: String) -> void:
	_rows.append(row)
	_labels.append(label)

var _rows: Array[EventDef] = []
var _labels: Array[String] = []

## One drive on one ground: every row it applies to stood, stepped through the drive and sampled,
## or, when `timing`, stepped as far as `COST_AT` without a line printed and then timed.
func _drive(t: TestRunner, atlas: AtlasLibrary, ground: String, drive: String, seen: Seen,
		timing: bool) -> void:
	var where := WhereSheIs.new()
	var rigs: Array[Rig] = []
	for index in _rows.size():
		var row := _rows[index]
		if not _applies(row, drive):
			continue
		var rig := _stand(t, atlas, where, row, ground, drive)
		rig.label = _labels[index]
		if drive == "hold" and not rig.instance.detains_her():
			rig.holder.free()
			continue
		rigs.append(rig)
	await DrawnEvent.frames(t)
	for rig in rigs:
		if not timing:
			_sample(rig, 0, seen)
	for tick in range(1, TICKS + 1):
		var she := _she_at(drive, tick)
		var sight := VisibleView.new()
		sight.look(Rect2(she - Vector2(576.0, 324.0), Vector2(1152.0, 648.0)), null)
		where.tell(she, Vector2.INF, sight)
		for rig in rigs:
			if rig.alive():
				_act(rig, tick)
				rig.instance.step(STEP)
		if tick % SAMPLE_EVERY == 0:
			await DrawnEvent.frames(t)
			for rig in rigs:
				if not timing:
					_sample(rig, tick, seen)
		if timing and tick == COST_AT:
			_cost(rigs, seen)
			break
	for rig in rigs:
		rig.holder.free()

## Whether `drive` has anything to say about `row`.
func _applies(row: EventDef, drive: String) -> bool:
	match drive:
		"pelican":
			return row.picture() == EventDef.Look.CYCLIST
		"silenced":
			return row.picture() == EventDef.Look.LOUDSPEAKER_MAST
		"boom":
			return row.picture() == EventDef.Look.CHECKPOINT_GATE
		"hand":
			return row.picture() == EventDef.Look.CHECKPOINT_HUT \
					or row.picture() == EventDef.Look.CHECKPOINT_POST
		"points":
			return row.picture() == EventDef.Look.PROTEST
	return true

## `row` stood the way `DrawnEvent.build()` stands one, under a holder of its own so that what the
## look puts beside it is found there, and with a route to walk when the row moves.
func _stand(t: TestRunner, atlas: AtlasLibrary, where: WhereSheIs, row: EventDef, ground: String,
		drive: String) -> Rig:
	var rig := Rig.new()
	rig.row = row
	rig.ground = ground
	rig.drive = drive
	rig.holder = Node2D.new()
	t.add_child(rig.holder)
	var instance := EventInstance.new()
	var map: WorldMap = EastWestStreet.new() if ground == "street" else WorldMap.open_ground()
	var route := PackedVector2Array()
	if row.speed() > 0.0:
		route = PackedVector2Array([AT, AT + Vector2(900.0, 0.0)])
	var surroundings := EventSurroundings.new().on(map).hearing(where).drawn_from(atlas) \
			.drawing_through(DrawnEvent.recording(instance, RecordingEventDrawer.new(atlas)))
	if drive == "boom":
		rig.gate = GateState.new()
	if drive == "points":
		rig.point = AT + Vector2(0.0, -400.0)
		surroundings.pointing_protests_with(Callable(rig, "point_now"))
	instance.setup(row, AT, route, Vector2.RIGHT, surroundings, rig.gate)
	rig.holder.add_child(instance)
	rig.instance = instance
	match drive:
		"pelican":
			instance.be_drawn_as_the_pelican()
		"silenced":
			instance.silence()
	return rig

## Where she is at `tick` under `drive`.
func _she_at(drive: String, tick: int) -> Vector2:
	if drive == "never":
		return AT + SHE_FAR
	var beside := AT + SHE_BESIDE
	if tick < SHE_ARRIVES:
		return AT + SHE_STARTS + (beside - AT - SHE_STARTS) * (float(tick) / float(SHE_ARRIVES))
	if tick < SHE_STANDS_UNTIL:
		return beside
	return beside + Vector2(SHE_PER_TICK * float(tick - SHE_STANDS_UNTIL), 0.0)

## What `drive` does to `rig` at `tick`, before the event's step.
func _act(rig: Rig, tick: int) -> void:
	var instance := rig.instance
	match rig.drive:
		"away":
			if tick == LEAVE_AT:
				instance.leave_for_a_completed_task()
			if tick == GIVE_UP_AT and instance.is_chasing():
				instance.give_up_the_chase()
		"boom":
			if tick == SWITCH_ON_AT:
				rig.gate.set_boom_up(true)
			elif tick == SWITCH_OFF_AT:
				rig.gate.set_boom_up(false)
		"hand":
			if tick == SWITCH_ON_AT:
				instance.raise_its_guards_hand(true)
			elif tick == SWITCH_OFF_AT:
				instance.raise_its_guards_hand(false)
		"hold":
			if tick == HOLD_AT:
				instance.start_chat()
		"points":
			if tick == POINTS_MOVE_AT:
				rig.point = AT + Vector2(400.0, 0.0)

## The microseconds `COST_CALLS` asks of each live event's redraw gate took.
func _cost(rigs: Array[Rig], seen: Seen) -> void:
	for rig in rigs:
		if not rig.alive():
			continue
		var from := Time.get_ticks_usec()
		for i in COST_CALLS:
			rig.instance._process(0.0)
		seen.cost_usec += Time.get_ticks_usec() - from
		seen.cost_calls += COST_CALLS

## Prints what `rig`'s event drew since the last sample and what its look answers now.
func _sample(rig: Rig, tick: int, seen: Seen) -> void:
	if not rig.alive():
		return
	var instance := rig.instance
	var drawer := DrawnEvent.drawer_of(instance)
	var prefix := "LK %s %s %s t%d" % [rig.ground, rig.label, rig.drive, tick]
	var fake := FakeEvent.answering_as(instance)
	var look := fake.look_for(rig.row)
	var script := look.get_script() as Script
	seen.looks[script.get_global_name()] = true
	for slice in drawer.slices():
		if not rig.slices.has(slice):
			rig.slices.append(slice)
	for entry in drawer.draws:
		var picture: String = entry.picture
		var canvas: Node = entry.canvas
		var mirrored: bool = entry.mirrored
		seen.pictures[picture] = true
		seen.row_draws[rig.label] = int(seen.row_draws[rig.label]) + 1
		seen.lines += 1
		print("%s D %s %s %s r=%s m=%d c=%s b=%s" % [prefix, entry.kind,
				_canvas_name(rig, canvas), picture, _rect(entry.rect), 1 if mirrored else 0,
				_colour(entry.colour), _rect(entry.band)])
	drawer.draws.clear()
	var answer := "%s %s %s" % [_rect(look.drawn_rect_now()), _rect(look.mark_rect()),
			_h(look.current_bob())]
	fake.free()
	if answer != rig.last_answer:
		rig.last_answer = answer
		seen.lines += 1
		print("%s A %s" % [prefix, answer])
	var nodes := _nodes(rig, rig.holder, "")
	if nodes != rig.last_nodes:
		rig.last_nodes = nodes
		seen.lines += 1
		print("%s N %s" % [prefix, nodes])

## Where each drawing node under `node` stands and whether it is shown, depth first, each named by
## what it is.
func _nodes(rig: Rig, node: Node, path: String) -> String:
	var found := ""
	var index := 0
	for child in node.get_children():
		var item := child as Node2D
		if item != null:
			var label := path + _canvas_name(rig, item, "n%d" % index)
			# The far guard's node places itself on the engine's physics tick, which no two runs
			# share, so only his drawn lines (`D`) are printed.
			if label == "far_guard":
				index += 1
				continue
			found += "%s@%s%s " % [label, _vec(item.global_position),
					"+" if item.visible else "-"]
			found += _nodes(rig, item, label + "/")
		index += 1
	return found

## What `canvas` is, never its instance id: the event, one of its slices, the band, the far guard, or
## a scenery in the order the look made them.
func _canvas_name(rig: Rig, canvas: Node, fallback := "other") -> String:
	if canvas == rig.instance:
		return "event"
	if canvas is RoadblockLook.RoadblockBand:
		return "band"
	if canvas is EventScenery:
		var id := canvas.get_instance_id()
		if not rig.scenery_ids.has(id):
			rig.scenery_ids.append(id)
		return "scenery%d" % rig.scenery_ids.find(id)
	if canvas.name == &"FarGuard":
		return "far_guard"
	var slices: Array[SpreadLook.Slice] = []
	for slice in rig.slices:
		if is_instance_valid(slice):
			slices.append(slice)
	slices.sort_custom(func(first: SpreadLook.Slice, second: SpreadLook.Slice) -> bool:
		return first.get_index() < second.get_index())
	for slice_at in slices.size():
		if slices[slice_at] == canvas:
			return "slice%d" % slice_at
	return fallback

static func _h(value: float) -> String:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	return bytes.hex_encode()

static func _vec(v: Vector2) -> String:
	return "%s,%s" % [_h(v.x), _h(v.y)]

static func _rect(r: Rect2) -> String:
	return "%s,%s" % [_vec(r.position), _vec(r.size)]

static func _colour(c: Color) -> String:
	return "%s,%s,%s,%s" % [_h(c.r), _h(c.g), _h(c.b), _h(c.a)]
