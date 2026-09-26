extends RefCounted
## M211 — the pause screen's held restart restarts a run rather than resuming it.
##
## Held apart from `tests/test_pause.gd` because pinning this bug needs the real engine's input
## dispatch (`Input.parse_input_event()` + `Input.flush_buffered_events()`), not the bare
## `_unhandled_input()` calls or `Viewport.push_input()` every touch test in that file already
## drives — see `_test_the_pause_restart_survives_its_own_emulated_mouse_click()`'s own doc for why
## that distinction is the whole bug.

const PAUSE := preload("res://scenes/ui/pause_screen.tscn")

func run(t) -> void:
	_test_the_pause_restart_survives_its_own_emulated_mouse_click(t)

## **The bug playtest 142 found, reproduced through the real engine's own input pipeline.**
## *(2026-09-26, the player: "the pause screen is currently bugged where you cannot restart from
## it. it just goes back to the current game when pressing the button.")*
##
## `Input.parse_input_event()` + `Input.flush_buffered_events()` is the one call in this suite that
## runs Godot's own emulate-mouse-from-touch pass (`project.godot` leaves
## `input_devices/pointing/emulate_mouse_from_touch` at its default, `true`) — `Viewport
## .push_input()`, which every touch test in `tests/test_pause.gd` uses, bypasses that pass
## entirely. Instrumenting every event `_input()` saw, ahead of this fix, showed the emulated
## `InputEventMouseButton` press dispatching *before* the real `InputEventScreenTouch` press for the
## same finger — so `PauseScreen._unhandled_input()`'s own catch-all (`TouchInput.is_press()`, which
## does not ask whether this device even has touch hardware to emulate a click from) read the
## emulated click as *carry on* a moment ahead of the real touch reaching `_handle_restart_touch()`,
## and `_acknowledge_and_resume()`'s own two-`process_frame` delay closed the screen and cancelled
## the hold before it could ever complete — the real touch's own matching release then landed on a
## screen already invisible (`_unhandled_input()`'s own `if not visible: return`) and did nothing at
## all. **Fixed** by gating the mouse branch of `PauseScreen._unhandled_input()`'s catch-all on
## `not _touch`, exactly as `_handle_restart_touch()`'s own mouse branch and `DaySummary`'s
## equivalent catch-all already are.
##
## The window is forced to the fixed design box for the span of this test: real engine dispatch
## applies the window's own stretch transform to an event's position, which `Viewport
## .push_input(event, true)` deliberately skips (see `tests/test_pause.gd`'s own doc for that flag)
## but the automatic dispatch `Input.parse_input_event()` drives does not, and this suite's own
## window defaults to a headless placeholder far smaller than `ScreenOrientation.DESIGN_SIZE`.
func _test_the_pause_restart_survives_its_own_emulated_mouse_click(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var restarts := [0]
	var resumed := [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)
	pause.resumed.connect(func() -> void: resumed[0] += 1)

	pause._touch = true
	pause._refresh_buttons()
	t.get_tree().paused = false
	pause.open()
	pause._restart_button.position = Vector2(500.0, 400.0)
	pause._restart_button.size = Vector2(92.0, 108.0)
	var at: Vector2 = pause._restart_button.get_global_rect().get_center()

	var original_window_size: Vector2i = t.get_window().size
	t.get_window().size = Vector2i(ScreenOrientation.DESIGN_SIZE)

	var press := InputEventScreenTouch.new()
	press.position = at
	press.pressed = true
	press.index = 0
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	t.check(pause._restart_button.is_held_by(0),
			"the real touch press starts the hold despite its own emulated mouse click landing "
			+ "first in the engine's own dispatch order")

	# Backdated so the pending frames below resolve this as a completed hold rather than the test
	# waiting out a real RESTART_HOLD_SECONDS.
	pause._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS

	# The gap a real hold spans, during which the pre-fix bug's own `_acknowledge_and_resume()` —
	# launched by the emulated click above, ahead of the real press — resolves its two-`process_frame`
	# delay and, pre-fix, closes the screen and cancels the hold out from under it.
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()

	var release := InputEventScreenTouch.new()
	release.position = at
	release.pressed = false
	release.index = 0
	Input.parse_input_event(release)
	Input.flush_buffered_events()

	t.get_window().size = original_window_size
	t.check(restarts[0] == 1,
			"held the full duration through the real emulation pipeline, the pause restarts (got %d)"
					% restarts[0])
	t.check(resumed[0] == 0,
			"and the click the engine emulates ahead of the real press never resumes the day instead")

	pause.close()
	t.get_tree().paused = false
	pause.queue_free()
