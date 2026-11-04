extends RefCounted
## **What the title, pause and summary suites share to drive those screens the way a player does**:
## events pushed through the viewport, real frames let pass, controls found by the names the scene
## gives them, and a clock a hold can be measured on without waiting out its second. Shared by
## `tests/test_pause.gd` and `tests/test_held_restart.gd`. A helper, not a suite: the runner loads
## only `test_*.gd`.

## A clock a test moves by hand, handed to `ModeButton.use_clock()` as `clock.read`.
class FakeClock:
	var now := 0.0

	func read() -> float:
		return now

## The `ModeButton` the scene names `node_name` ("Restart", "Continue", "Left", "Tap", "Right").
static func button(screen: Node, node_name: String) -> ModeButton:
	return screen.find_child(node_name, true, false) as ModeButton

## The `Label` (or `Control`) the scene names `node_name` ("Hint", "Body", "Standing", "Version").
static func control(screen: Node, node_name: String) -> Control:
	return screen.find_child(node_name, true, false) as Control

## The fill a button's resting disc is drawn with right now.
static func fill(button_node: ModeButton) -> Color:
	return (button_node.get_theme_stylebox("normal") as StyleBoxFlat).bg_color

## Where the middle of a button is on the screen, the point a finger on it lands on.
static func centre(button_node: ModeButton) -> Vector2:
	return button_node.get_global_rect().get_center()

## Pushes `event` through the viewport the screen is in — the GUI layer and then the unhandled
## pass, the route a real event takes. `in_local_coords` is set so the window's own stretch is not
## applied: a headless test window is not the 1280x720 box every screen is authored against.
static func push(screen: Node, event: InputEvent) -> void:
	screen.get_viewport().push_input(event, true)

## Lets `count` frames pass. A `process_frame` resumes before the nodes' own `_process` of the frame
## it names, so two are what one full frame of processing takes.
static func frames(t, count := 2) -> void:
	for i in count:
		await t.get_tree().process_frame

static func touch_at(position: Vector2, pressed: bool, index := 0) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = index
	return event

static func mouse_at(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.pressed = pressed
	event.button_index = MOUSE_BUTTON_LEFT
	return event

## A day's end as `DayDirector.finish_day()` settles one: what ended it, the loss's own sentence,
## the clock it ended on, and whether it sent a normal run back to its checkpoint.
static func ended(result: GameEnums.DayResult, reason := "", elapsed := 0.0, goes_back := false) -> DayEnd:
	var end := DayEnd.new()
	end.result = result
	end.reason = reason
	end.elapsed_seconds = elapsed
	end.goes_back = goes_back
	return end
