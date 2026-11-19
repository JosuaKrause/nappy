extends RefCounted
## The screen-edge badge's control (`DangerEdge`) alone: what it hands its badge model each frame
## about what she can see. Which dangers get a badge and when is the model's, checked in
## `tests/test_badge_model.gd` with a rectangle for a view and the edge's drawing there too; here
## the edge is handed an event source of its own, a stand-in answering the live events and the day's
## view as `EventManager` does (`instances()`, `visible_view()`), and one stand-in live event, the
## military convoy, moved by hand between real frames. What is checked is that the edge asks the view
## she has: a badge comes down on the frame any of its thing is in sight, and nothing just past the
## screen's edge, inside the badge's margin, is raised one fresh. The edge is hidden, so it draws
## nothing and is handed no atlas.

## The convoy's drawn box about its feet, read off `EventFootprints.drawn_box_of()`: all of it
## stands above its feet, so a convoy just above the view is wholly out of sight.
const CONVOY_BOX := Rect2(-30.0, -38.0, 60.0, 38.0)

func run(t: TestRunner) -> void:
	await _test_a_badge_comes_down_the_frame_its_danger_is_in_sight(t)
	await _test_nothing_in_the_margin_is_raised_a_badge_fresh(t)

## **A badge comes down on the frame any of its danger is in sight** (the danger vocabulary's badge,
## kept until the thing is in sight). The convoy closes on her from above, out of sight and out past
## the margin, where the edge raises its badge; it drives on into the view, and the badge is up on
## every frame until the first frame any of it shows, and down on that frame.
func _test_a_badge_comes_down_the_frame_its_danger_is_in_sight(t: TestRunner) -> void:
	var rig := _rig(t, Vector2(0.0, -421.0))
	var edge: DangerEdge = rig["edge"]
	var convoy: Node2D = rig["convoy"]
	var went_up := false
	var down_early := 0
	var seen := false
	var down_when_seen := false
	while not seen and convoy.position.y < 0.0:
		convoy.position.y += 8.0
		await _next_frame(t)
		var up := _up(edge)
		if _in_sight(convoy.position):
			seen = true
			down_when_seen = not up
		elif went_up and not up:
			down_early += 1
		went_up = went_up or up
	t.check(went_up, "closing from out past the margin, the convoy's badge goes up")
	t.check(down_early == 0,
			"and stays up on every frame it is out of sight (%d frames down)" % down_early)
	t.check(seen and down_when_seen,
			"and comes down on the first frame any of it is in sight (at %s)" % convoy.position)
	_put_away(rig)

## **Nothing just past the screen's edge is raised a badge fresh.** A thing sitting on the boundary
## would otherwise trade places with its own badge every frame, so the edge counts the badge's margin
## (`BadgeModel.SCREEN_MARGIN` screen px, `DangerEdge.world_per_screen_px()` world px each) as in
## sight when it asks whether to raise one. The convoy closes on her from inside that margin, wholly
## out of sight on every frame, and is raised no badge on any of them.
func _test_nothing_in_the_margin_is_raised_a_badge_fresh(t: TestRunner) -> void:
	var margin := BadgeModel.SCREEN_MARGIN * DangerEdge.world_per_screen_px()
	var top := -Tuning.VIEW_HALF_EXTENT.y
	var rig := _rig(t, Vector2(0.0, top - margin + 10.0))
	var edge: DangerEdge = rig["edge"]
	var convoy: Node2D = rig["convoy"]
	var frames := 0
	var up := 0
	var shown := 0
	while convoy.position.y < top - 3.0:
		convoy.position.y += 2.0
		await _next_frame(t)
		frames += 1
		up += int(_up(edge))
		shown += int(_in_sight(convoy.position))
	t.check(frames > 10 and shown == 0,
			"the convoy closed for %d frames inside the margin, out of sight on all of them (%d shown)"
			% [frames, shown])
	t.check(up == 0, "and no badge was raised on any of them (%d frames up)" % up)
	_put_away(rig)

## The edge watching the stand-in source, with her standing at the origin and the convoy at `at`.
func _rig(t: TestRunner, at: Vector2) -> Dictionary:
	var source := _Source.new()
	t.add_child(source)
	var her := Node2D.new()
	t.add_child(her)
	var convoy := _Coming.new(EventCatalogue.by_id("military_convoy"), CONVOY_BOX)
	convoy.position = at
	source.bring(convoy)
	var edge := DangerEdge.new()
	edge.visible = false
	edge.setup(source, her)
	t.add_child(edge)
	return {"edge": edge, "convoy": convoy, "nodes": [edge, her, source]}

func _put_away(rig: Dictionary) -> void:
	for node: Node in rig["nodes"]:
		node.free()

## Whether any of a convoy standing at `at` is in the view about her at the origin: its feet, or
## any of its drawn box.
static func _in_sight(at: Vector2) -> bool:
	var view := Rect2(-Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	return view.has_point(at) or view.intersects(Rect2(at + CONVOY_BOX.position, CONVOY_BOX.size))

## Whether the convoy's badge is on the edge.
static func _up(edge: DangerEdge) -> bool:
	for badge in edge.announcing():
		if badge["id"] == "military_convoy":
			return true
	return false

## Waits until the process frame count moves on, so the edge has measured the frame that began with
## the convoy where it was put.
static func _next_frame(t: TestRunner) -> void:
	var asked_in := Engine.get_process_frames()
	while Engine.get_process_frames() == asked_in:
		await t.get_tree().process_frame

## An event source the edge reads as it reads `EventManager`: the live events it was brought, and
## the day's view, about her at the origin with nothing covering it.
class _Source extends Node:
	var _coming: Array[EventInstance] = []
	var _view := VisibleView.around(Vector2.ZERO, null)

	## Puts `instance` in the world, among the live events.
	func bring(instance: EventInstance) -> void:
		add_child(instance)
		instance.set_process(false)
		_coming.append(instance)

	func instances() -> Array[EventInstance]:
		return _coming

	func visible_view() -> VisibleView:
		return _view

## A live event of `row` the edge reads: its row, its name in the log and the box it draws, standing
## wherever it is put, set up for nothing else and hidden.
class _Coming extends EventInstance:
	var _row: EventDef
	var _box: Rect2

	func _init(the_row: EventDef, box: Rect2) -> void:
		super()
		_row = the_row
		_box = box
		visible = false

	## Overrides EventInstance._ready.
	func _ready() -> void:
		pass

	## Overrides EventInstance.row.
	func row() -> EventDef:
		return _row

	## Overrides EventInstance.logged_name.
	func logged_name() -> String:
		return _row.id

	## Overrides EventInstance.drawn_box.
	func drawn_box() -> Rect2:
		return _box
