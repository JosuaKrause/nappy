extends RefCounted
## M211 + M212 — the pause screen's held restart restarts a run rather than resuming it, and a
## hold survives what the real engine and a second finger can throw at it, on both the pause screen
## and the day summary.
##
## Held apart from `tests/test_pause.gd` because pinning M211's own bug needs the real engine's
## input dispatch (`Input.parse_input_event()` + `Input.flush_buffered_events()`), not the bare
## `_unhandled_input()` calls or `Viewport.push_input()` every touch test in that file already
## drives — see `_test_the_pause_restart_survives_its_own_emulated_mouse_click()`'s own doc for why
## that distinction is the whole bug.
##
## **Causes investigated for M212 and found not to be bugs**, so no test pins them: a drag off the
## disc (`_handle_restart_touch()` never reads an `InputEventScreenDrag` at all, and a release ends
## the hold by its touch index alone — the position is never rechecked, so drifting off the disc
## mid-hold changes nothing); a release reaching another control (the release branch returns before
## the catch-all ever sees it, whether or not the hold actually completed); the fill drawn only on
## hover (`ModeButton._draw()` paints from `hold_progress` alone, with no hover term in it at all).

const PAUSE := preload("res://scenes/ui/pause_screen.tscn")
const SUMMARY := preload("res://scenes/ui/day_summary.tscn")

func run(t) -> void:
	_test_the_pause_restart_survives_its_own_emulated_mouse_click(t)
	_test_the_pause_restart_ignores_a_second_touch_mid_hold(t)
	_test_the_summary_restart_ignores_a_second_touch_mid_hold(t)
	_test_the_restart_discs_fill_climbs_through_a_real_touch_hold(t)

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

## **A second finger anywhere on the screen no longer reads as *carry on* while the restart disc is
## already held.** *(M212: "sometimes it just doesn't work at all... you have to hold long multiple
## times".)* `ModeButton.begin_hold()` refusing a second index used to fall straight through to the
## catch-all below, which read any other touch as *carry on* and resumed the day — exactly what a
## palm graze or the other hand steadying the phone can send while a thumb holds restart down.
func _test_the_pause_restart_ignores_a_second_touch_mid_hold(t) -> void:
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
	var at: Vector2 = pause._restart_button.catch_rect().get_center()

	pause._unhandled_input(_touch_at(at, true, 0))
	t.check(pause._restart_button.is_held_by(0), "the first finger starts the hold")

	# A second finger, elsewhere on the screen entirely — not a drag of the first, a distinct index.
	# `_acknowledge_and_resume()` acknowledges two `process_frame`s ahead of itself — see
	# `tests/test_pause.gd`'s own `_test_a_tap_advances_every_screen` for why — so both are emitted
	# manually to give a pre-fix regression every chance to actually fire, and to actually cancel
	# the first finger's hold through `close()`'s own `_restart_button.cancel_hold()`, before this asks.
	pause._unhandled_input(_touch_at(Vector2(20.0, 20.0), true, 1))
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(resumed[0] == 0, "the stray second finger does not read as carrying on")
	t.check(pause.is_open(), "and the screen stays open")
	t.check(pause._restart_button.is_held_by(0), "the original hold is undisturbed")

	pause._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	pause._unhandled_input(_touch_at(at, false, 0))
	t.check(restarts[0] == 1, "and the first finger's own hold still restarts once released")
	t.check(resumed[0] == 0, "never having resumed along the way")

	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

## The day summary's own half of the same fix — `DaySummary._handle_restart_touch()` carries the
## identical guard, since a stray second finger reaches its own catch-all
## (`_acknowledge_and_continue()`) exactly the same way.
func _test_the_summary_restart_ignores_a_second_touch_mid_hold(t) -> void:
	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	var restarts := [0]
	var continued := [0]
	summary.restart_requested.connect(func() -> void: restarts[0] += 1)
	summary.continued.connect(func() -> void: continued[0] += 1)

	summary._touch = true
	summary.show_day(1, GameEnums.DayResult.LOST_TIMEOUT, "", 3)
	summary._restart_button.position = Vector2(500.0, 400.0)
	summary._restart_button.size = Vector2(92.0, 108.0)
	var at: Vector2 = summary._restart_button.catch_rect().get_center()

	summary._unhandled_input(_touch_at(at, true, 0))
	t.check(summary._restart_button.is_held_by(0), "the first finger starts the hold")

	summary._unhandled_input(_touch_at(Vector2(20.0, 20.0), true, 1))
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(continued[0] == 0, "the stray second finger does not read as continuing")
	t.check(summary._restart_button.is_held_by(0), "the original hold is undisturbed")

	summary._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	summary._unhandled_input(_touch_at(at, false, 0))
	t.check(restarts[0] == 1, "and the first finger's own hold still restarts once released")
	t.check(continued[0] == 0, "never having continued along the way")

	t.get_tree().paused = false
	summary.queue_free()

## **M212's own "the disc's radial fill shows while a touch is held."** `ModeButton.hold_progress`
## is what `_draw()` paints as the sweep — see that file's own class comment — so this reads the
## value a screenshot would otherwise be needed to see, partway through a hold that nothing
## interrupts, on both screens the button appears on.
func _test_the_restart_discs_fill_climbs_through_a_real_touch_hold(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	pause._touch = true
	pause._refresh_buttons()
	t.get_tree().paused = false
	pause.open()
	pause._restart_button.position = Vector2(500.0, 400.0)
	pause._restart_button.size = Vector2(92.0, 108.0)
	var pause_at: Vector2 = pause._restart_button.catch_rect().get_center()

	pause._unhandled_input(_touch_at(pause_at, true, 0))
	pause._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS * 0.5
	pause._restart_button._process(0.0)
	t.check(pause._restart_button.hold_progress > 0.3 and pause._restart_button.hold_progress < 0.7,
			"halfway through the hold, the pause screen's own disc is about half full (got %.2f)"
					% pause._restart_button.hold_progress)

	pause._unhandled_input(_touch_at(pause_at, false, 0))
	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	summary._touch = true
	summary.show_day(1, GameEnums.DayResult.LOST_TIMEOUT, "", 3)
	summary._restart_button.position = Vector2(500.0, 400.0)
	summary._restart_button.size = Vector2(92.0, 108.0)
	var summary_at: Vector2 = summary._restart_button.catch_rect().get_center()

	summary._unhandled_input(_touch_at(summary_at, true, 0))
	summary._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS * 0.5
	summary._restart_button._process(0.0)
	t.check(summary._restart_button.hold_progress > 0.3
				and summary._restart_button.hold_progress < 0.7,
			"and the day summary's own disc fills the same way (got %.2f)"
					% summary._restart_button.hold_progress)

	summary._unhandled_input(_touch_at(summary_at, false, 0))
	t.get_tree().paused = false
	summary.queue_free()

func _touch_at(position: Vector2, pressed: bool, index: int) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = index
	return event
