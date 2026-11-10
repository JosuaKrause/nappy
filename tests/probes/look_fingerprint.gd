extends RefCounted
## **What every catalogue row's look draws, and what its drawn frames cost**, so a change to how the
## looks are built can be shown to draw exactly what they drew. Not a suite: it prints rather than
## asserts. Run by name, before and after a change, and compare the two outputs:
##
##     tools/test.sh probes/look_fingerprint.gd > before.txt
##     grep '^LK ' before.txt | shasum -a 256      (the same for after; `diff` the two `LK` files)
##
## **`LK` lines are the fingerprint**, deterministic and hashable. Every row of
## `EventCatalogue.all()` is stood twice, on open ground and on an east-west street, the way
## `tests/drawn_event.gd` stands one (a `RecordingEventDrawer` assigned before `setup()`, a map, a
## `WhereSheIs`), with an atlas that holds the events' group so that a crash's and a burst main's
## scenery is built. Each is stepped on a fixed tick (`1/30` s) through a drive, the same for every
## row, and every `SAMPLE_EVERY` ticks the frames a draw needs pass and the probe prints:
##
## - one line per picture the drawer was told since the last sample (canvas, kind, picture, rect,
##   mirrored, colour, band), a canvas named by what it is (`event`, `sliceN`, `band`, `far_guard`,
##   `sceneryN`) and never by an instance id;
## - one line of what the look answers (`drawn_rect_now()`, `mark_rect()`, `drawn_heading()`,
##   `current_bob()`) and one of where each drawing node stands and whether it is shown, each only
##   when it differs from the last sample's.
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
## calls of each live event's `look.redraw_if_the_picture_changed()` took, the redraw gate's share
## of a frame, for comparing two revisions' cost.
##
## **It asks only what every tree of the looks' step has**: the public methods named above and the
## members the spawner, streaming and the checkpoint controller write today (`is_pelican`,
## `silenced`, `gate_state`, `points_at`). A later change which makes one of those members private
## changes this probe with it.

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
	var ground := ""
	var drive := ""
	var holder: Node2D
	var instance: EventInstance
	var scenery_ids: Array[int] = []
	var last_answer := ""
	var last_nodes := ""
	## What a protest is handed to point at (`points`).
	var point := Vector2.ZERO

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
	for row in EventCatalogue.all():
		seen.row_draws[row.id] = 0
	for ground in GROUNDS:
		for drive in DRIVES:
			await _drive(t, atlas, ground, drive, seen)
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

## One drive on one ground: every row it applies to stood, stepped through the drive and sampled.
func _drive(t: TestRunner, atlas: AtlasLibrary, ground: String, drive: String, seen: Seen) -> void:
	var where := WhereSheIs.new()
	var rigs: Array[Rig] = []
	for row in EventCatalogue.all():
		if not _applies(row, drive):
			continue
		var rig := _stand(t, atlas, where, row, ground, drive)
		if drive == "hold" and rig.instance.hold == null:
			rig.holder.free()
			continue
		rigs.append(rig)
	await DrawnEvent.frames(t)
	for rig in rigs:
		_sample(rig, 0, seen)
	for tick in range(1, TICKS + 1):
		var she := _she_at(drive, tick)
		where.tell(she, Vector2.INF, Rect2(she - Vector2(576.0, 324.0), Vector2(1152.0, 648.0)))
		for rig in rigs:
			if rig.alive():
				_act(rig, tick)
				rig.instance.step(STEP)
		if tick % SAMPLE_EVERY == 0:
			await DrawnEvent.frames(t)
			for rig in rigs:
				_sample(rig, tick, seen)
		if tick == COST_AT and ground == "street" and drive == "walk":
			_cost(rigs, seen)
	for rig in rigs:
		rig.holder.free()

## Whether `drive` has anything to say about `row`.
func _applies(row: EventDef, drive: String) -> bool:
	match drive:
		"pelican":
			return row.look == EventDef.Look.CYCLIST
		"silenced":
			return row.look == EventDef.Look.LOUDSPEAKER_MAST
		"boom":
			return row.look == EventDef.Look.CHECKPOINT_GATE
		"hand":
			return row.look == EventDef.Look.CHECKPOINT_HUT \
					or row.look == EventDef.Look.CHECKPOINT_POST
		"points":
			return row.look == EventDef.Look.PROTEST
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
	instance.atlas = atlas
	instance.drawer = RecordingEventDrawer.new(atlas)
	var map: WorldMap = EastWestStreet.new() if ground == "street" else WorldMap.open_ground()
	var route := PackedVector2Array()
	if row.speed > 0.0:
		route = PackedVector2Array([AT, AT + Vector2(900.0, 0.0)])
	instance.setup(row, AT, route, Vector2.RIGHT, map, null, where)
	rig.holder.add_child(instance)
	rig.instance = instance
	match drive:
		"pelican":
			instance.is_pelican = true
		"silenced":
			instance.silenced = true
		"boom":
			instance.gate_state = RegionPlanner.GateState.new()
		"points":
			rig.point = AT + Vector2(0.0, -400.0)
			instance.points_at = Callable(rig, "point_now")
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
				instance.gate_state.raised = true
			elif tick == SWITCH_OFF_AT:
				instance.gate_state.raised = false
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
		var look := rig.instance.look
		var from := Time.get_ticks_usec()
		for i in COST_CALLS:
			look.redraw_if_the_picture_changed()
		seen.cost_usec += Time.get_ticks_usec() - from
		seen.cost_calls += COST_CALLS

## Prints what `rig`'s event drew since the last sample and what its look answers now.
func _sample(rig: Rig, tick: int, seen: Seen) -> void:
	if not rig.alive():
		return
	var instance := rig.instance
	var drawer := instance.drawer as RecordingEventDrawer
	var prefix := "LK %s %s %s t%d" % [rig.ground, rig.row.id, rig.drive, tick]
	var script := instance.look.get_script() as Script
	seen.looks[script.get_global_name()] = true
	for entry in drawer.draws:
		var picture: String = entry.picture
		var canvas: Node = entry.canvas
		var mirrored: bool = entry.mirrored
		seen.pictures[picture] = true
		seen.row_draws[rig.row.id] = int(seen.row_draws[rig.row.id]) + 1
		seen.lines += 1
		print("%s D %s %s %s r=%s m=%d c=%s b=%s" % [prefix, entry.kind,
				_canvas_name(rig, canvas), picture, _rect(entry.rect), 1 if mirrored else 0,
				_colour(entry.colour), _rect(entry.band)])
	drawer.draws.clear()
	var look := instance.look
	var answer := "%s %s %s %s" % [_rect(look.drawn_rect_now()), _rect(look.mark_rect()),
			_vec(look.drawn_heading()), _h(look.current_bob())]
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
	if canvas == rig.instance.look.band_node():
		return "band"
	if canvas is EventScenery:
		var id := canvas.get_instance_id()
		if not rig.scenery_ids.has(id):
			rig.scenery_ids.append(id)
		return "scenery%d" % rig.scenery_ids.find(id)
	if canvas.name == &"FarGuard":
		return "far_guard"
	var slice_index: Variant = canvas.get(&"index")
	if slice_index != null:
		return "slice%d" % int(slice_index)
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
