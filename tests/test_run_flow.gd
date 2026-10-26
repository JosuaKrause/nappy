extends RefCounted
## The run's flow through its screens (`RunFlow`): what each screen's continue leads to, and that a
## continue with no screen up leads nowhere.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SEED := 4242
## How many frames a boot may take to reach its first day before the test gives up on it.
const BOOT_FRAMES := 30

func run(t) -> void:
	await _test_a_tap_then_a_key_continue_once(t)

# ------------------------------------------------------------- the real boot ---

## A tap on the day's summary holds the continue button's pressed look for two frames before it
## continues (`DaySummary._acknowledge_and_continue()`), and a key continues at once, so a key
## pressed inside those two frames continues first and the tap's own continue arrives after the
## summary is gone. Only the first may start a day: the second reaches a run that is already walking.
func _test_a_tap_then_a_key_continue_once(t) -> void:
	var saved_paused: bool = t.get_tree().paused
	t.get_tree().paused = true
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(PackedStringArray(["--seed", str(SEED), "--no-telemetry",
			"--no-title", "--no-save"]), "", true))
	t.add_child(main)
	var frames := 0
	while frames < BOOT_FRAMES and not (main._day and main._day.is_running()):
		await t.get_tree().process_frame
		frames += 1
	t.check(main._day != null and main._day.is_running(), "the boot reached day 1")
	t.get_tree().paused = true
	EventBus.hard_fail_triggered.emit("car_strike")
	t.check(main._summary.is_showing(), "the lost day's summary is up")

	var started: Array[int] = []
	var count := func(day: int) -> void: started.append(day)
	EventBus.day_started.connect(count)
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = _off_the_restart_button(main._summary)
	main._summary._unhandled_input(tap)
	var key := InputEventAction.new()
	key.action = &"ui_accept"
	key.pressed = true
	main._summary._unhandled_input(key)
	for _frame in 4:
		await t.get_tree().process_frame
	EventBus.day_started.disconnect(count)
	t.check(started == [1], "a tap and a key inside the tap's two frames start the day once (%s)"
			% [started])

	t.remove_child(main)
	main.free()
	t.get_tree().paused = saved_paused

## A point on the screen whose tap is a continue, not the start of the held restart.
func _off_the_restart_button(summary: CanvasLayer) -> Vector2:
	var size: Vector2 = summary.get_viewport().get_visible_rect().size
	for x in range(1, 8):
		for y in range(1, 8):
			var at := Vector2(size.x * x / 8.0, size.y * y / 8.0)
			var design := ScreenOrientation.to_design_space(at, summary._wants_rotation())
			if not summary._restart_button.contains_design_point(design):
				return at
	return Vector2.ZERO
