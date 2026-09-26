extends RefCounted
## M211 + M212 — the pause screen's held restart restarts a run rather than resuming it, a hold
## survives what the real engine and a second finger can throw at it, the disc it fills lights up
## the same way for a touch hold as it does for a mouse one, and the restart itself fires the
## instant the disc fills rather than waiting for a release, on both the pause screen and the day
## summary.
##
## Held apart from `tests/test_pause.gd` because pinning M211's own bug, M212's own fill-visible
## bug, and Playtest 144's fires-on-release bug all need the real engine's input dispatch
## (`Input.parse_input_event()` + `Input.flush_buffered_events()`), not the bare
## `_unhandled_input()` calls or `Viewport.push_input()` every touch test in that file already
## drives — see `_test_the_pause_restart_survives_its_own_emulated_mouse_click()`'s own doc for why
## that distinction is the whole bug.
##
## **Causes investigated for M212 and found not to be bugs**, so no test pins them: a drag off the
## disc (`_handle_restart_touch()` never reads an `InputEventScreenDrag` at all, and a release ends
## the hold by its touch index alone — the position is never rechecked, so drifting off the disc
## mid-hold changes nothing); a release reaching another control (the release branch returns before
## the catch-all ever sees it, whether or not the hold actually completed); the sweep drawn only on
## hover (`ModeButton._draw()` paints from `hold_progress` alone, with no hover term in it at all —
## see `_test_the_restart_disc_lights_up_the_same_for_a_touch_hold_as_a_mouse_one()`'s own doc for
## the hover term that actually was missing, one function over in `_refresh_look()`).

const PAUSE := preload("res://scenes/ui/pause_screen.tscn")
const SUMMARY := preload("res://scenes/ui/day_summary.tscn")

func run(t) -> void:
	_test_the_pause_restart_survives_its_own_emulated_mouse_click(t)
	_test_the_pause_restart_ignores_a_second_touch_mid_hold(t)
	_test_the_summary_restart_ignores_a_second_touch_mid_hold(t)
	_test_the_restart_discs_fill_climbs_through_a_real_touch_hold(t)
	_test_the_restart_disc_lights_up_the_same_for_a_touch_hold_as_a_mouse_one(t)
	_test_the_restart_fires_the_instant_the_disc_fills_not_on_release(t)

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

	# Backdated so the fill below resolves this as a completed hold rather than the test waiting
	# out a real RESTART_HOLD_SECONDS.
	pause._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	# Fires the moment the disc fills — *(Playtest 144: "The button only activated when releasing
	# though. It should trigger the moment it is full.")* — not on the release further down.
	pause._restart_button._process(0.0)
	t.check(restarts[0] == 1,
			"held the full duration through the real emulation pipeline, the disc filling restarts "
			+ "the pause before any release (got %d)" % restarts[0])

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
			"and the matching release does not restart the pause a second time (got %d)"
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
	pause._restart_button._process(0.0)
	t.check(restarts[0] == 1, "and the first finger's own hold still fires once it fills")
	pause._unhandled_input(_touch_at(at, false, 0))
	t.check(restarts[0] == 1, "and the eventual release does not restart it a second time")
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
	summary._restart_button._process(0.0)
	t.check(restarts[0] == 1, "and the first finger's own hold still fires once it fills")
	summary._unhandled_input(_touch_at(at, false, 0))
	t.check(restarts[0] == 1, "and the eventual release does not restart it a second time")
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

## **M212's "the restart button doesn't visible fill up on mobile when pressing" — the sweep was
## never invisible, the disc under it was.** `ModeButton._refresh_look()` picks
## `Palette.BUTTON_HOVER` — a materially brighter fill than the resting `Palette.BUTTON_FILL` —
## whenever `_hovered_look` is set, and a mouse hold sets it: the pointer that is pressing the disc
## also sits on top of it, so `PauseScreen`/`DaySummary`'s own `not _touch` mouse-motion branch
## calls `ModeButton.set_hovered(true)` for as long as the hold lasts. A touch sets nothing of the
## kind — there is no motion event to read a finger's position from between its press and its
## release — so a touch hold used to leave `_draw()`'s translucent sweep painted over the plain
## resting fill instead of the brighter one a mouse hold reaches, on top of a disc already mostly
## covered by the finger holding it. **Fixed** by having `_refresh_look()` also read `is_held()`,
## so any hold — whatever started it — reaches the same brighter base.
##
## Driven through the real engine's own emulate-mouse-from-touch pass (`Input.parse_input_event()`
## + `Input.flush_buffered_events()`), the same way
## `_test_the_pause_restart_survives_its_own_emulated_mouse_click()` above does, so an emulated
## mouse motion synced to the touch position — if one ever reached `set_hovered()` — could not
## quietly mask the bug by setting `_hovered_look` on its own.
func _test_the_restart_disc_lights_up_the_same_for_a_touch_hold_as_a_mouse_one(t) -> void:
	var original_window_size: Vector2i = t.get_window().size
	t.get_window().size = Vector2i(ScreenOrientation.DESIGN_SIZE)

	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	pause._touch = false
	pause._refresh_buttons()
	t.get_tree().paused = false
	pause.open()
	pause._restart_button.position = Vector2(500.0, 400.0)
	pause._restart_button.size = Vector2(92.0, 108.0)
	var pause_at: Vector2 = pause._restart_button.get_global_rect().get_center()

	var hover := InputEventMouseMotion.new()
	hover.position = pause_at
	Input.parse_input_event(hover)
	Input.flush_buffered_events()
	Input.parse_input_event(_mouse_at(pause_at, true))
	Input.flush_buffered_events()
	pause._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS * 0.5
	pause._restart_button._process(0.0)
	var mouse_bg: Color = \
			(pause._restart_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	t.check(mouse_bg == Palette.BUTTON_HOVER,
			"halfway through a mouse hold, the pause screen's disc reads the brighter hover fill")

	Input.parse_input_event(_mouse_at(pause_at, false))
	Input.flush_buffered_events()
	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

	pause = PAUSE.instantiate()
	t.add_child(pause)
	pause._touch = true
	pause._refresh_buttons()
	t.get_tree().paused = false
	pause.open()
	pause._restart_button.position = Vector2(500.0, 400.0)
	pause._restart_button.size = Vector2(92.0, 108.0)
	pause_at = pause._restart_button.get_global_rect().get_center()

	Input.parse_input_event(_touch_at(pause_at, true, 0))
	Input.flush_buffered_events()
	pause._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS * 0.5
	pause._restart_button._process(0.0)
	var touch_bg: Color = \
			(pause._restart_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	t.check(touch_bg == mouse_bg,
			"and halfway through a real touch hold the pause screen's disc reads the same fill "
			+ "(got %s, wanted the mouse hold's %s)" % [touch_bg, mouse_bg])

	Input.parse_input_event(_touch_at(pause_at, false, 0))
	Input.flush_buffered_events()
	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	summary._touch = true
	summary.show_day(1, GameEnums.DayResult.LOST_TIMEOUT, "", 3)
	summary._restart_button.position = Vector2(500.0, 400.0)
	summary._restart_button.size = Vector2(92.0, 108.0)
	var summary_at: Vector2 = summary._restart_button.get_global_rect().get_center()

	Input.parse_input_event(_touch_at(summary_at, true, 0))
	Input.flush_buffered_events()
	summary._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS * 0.5
	summary._restart_button._process(0.0)
	var summary_touch_bg: Color = \
			(summary._restart_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	t.check(summary_touch_bg == Palette.BUTTON_HOVER,
			"and the day summary's own disc reads the same brighter fill under a real touch hold")

	Input.parse_input_event(_touch_at(summary_at, false, 0))
	Input.flush_buffered_events()
	t.get_tree().paused = false
	summary.queue_free()

	t.get_window().size = original_window_size

## **Playtest 144: "The button only activated when releasing though. It should trigger the moment
## it is full."** A completed hold used to be decided at `end_hold()`'s own return on release; a
## finger or a mouse button held down well past `RESTART_HOLD_SECONDS` still had to be lifted
## before anything happened. `ModeButton._process()` now raises `hold_completed` — which
## `PauseScreen`/`DaySummary` each connect straight to their own `restart_requested` — the instant
## `hold_progress` reaches `1.0`, while the touch or the mouse button is still down; the eventual
## release only tears the hold's own state down through `end_hold()`, which no longer restarts
## anything itself. Driven through the real engine's own dispatch
## (`Input.parse_input_event()` + `Input.flush_buffered_events()`) on both screens and both pointer
## kinds, asserting `restarts[0] == 1` **before** the release event is ever sent — the release is
## then sent anyway and checked not to raise it a second time, and not to read as *carry on*
## (`resumed`/`continued` stay `0`) either.
func _test_the_restart_fires_the_instant_the_disc_fills_not_on_release(t) -> void:
	var original_window_size: Vector2i = t.get_window().size
	t.get_window().size = Vector2i(ScreenOrientation.DESIGN_SIZE)

	# Pause screen, a real touch hold.
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
	var pause_at: Vector2 = pause._restart_button.get_global_rect().get_center()

	Input.parse_input_event(_touch_at(pause_at, true, 0))
	Input.flush_buffered_events()
	pause._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	pause._restart_button._process(0.0)
	t.check(restarts[0] == 1,
			"the pause screen's real touch hold restarts the instant the disc fills, with the "
			+ "finger still down and no release sent yet (got %d)" % restarts[0])

	Input.parse_input_event(_touch_at(pause_at, false, 0))
	Input.flush_buffered_events()
	t.check(restarts[0] == 1, "the pause screen's release does not restart it a second time")
	t.check(resumed[0] == 0, "and never reads as carrying on")

	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

	# Pause screen, a real mouse hold.
	pause = PAUSE.instantiate()
	t.add_child(pause)
	restarts = [0]
	resumed = [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)
	pause.resumed.connect(func() -> void: resumed[0] += 1)
	pause._touch = false
	pause._refresh_buttons()
	t.get_tree().paused = false
	pause.open()
	pause._restart_button.position = Vector2(500.0, 400.0)
	pause._restart_button.size = Vector2(92.0, 108.0)
	pause_at = pause._restart_button.get_global_rect().get_center()

	Input.parse_input_event(_mouse_at(pause_at, true))
	Input.flush_buffered_events()
	pause._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	pause._restart_button._process(0.0)
	t.check(restarts[0] == 1,
			"the pause screen's real mouse hold restarts the instant the disc fills, with the "
			+ "button still down and no release sent yet (got %d)" % restarts[0])

	Input.parse_input_event(_mouse_at(pause_at, false))
	Input.flush_buffered_events()
	t.check(restarts[0] == 1, "the pause screen's mouse release does not restart it a second time")
	t.check(resumed[0] == 0, "and never reads as carrying on")

	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

	# Day summary, a real touch hold.
	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	restarts = [0]
	var continued := [0]
	summary.restart_requested.connect(func() -> void: restarts[0] += 1)
	summary.continued.connect(func() -> void: continued[0] += 1)
	summary._touch = true
	summary.show_day(1, GameEnums.DayResult.LOST_TIMEOUT, "", 3)
	summary._restart_button.position = Vector2(500.0, 400.0)
	summary._restart_button.size = Vector2(92.0, 108.0)
	var summary_at: Vector2 = summary._restart_button.get_global_rect().get_center()

	Input.parse_input_event(_touch_at(summary_at, true, 0))
	Input.flush_buffered_events()
	summary._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	summary._restart_button._process(0.0)
	t.check(restarts[0] == 1,
			"the day summary's real touch hold restarts the instant the disc fills, with the "
			+ "finger still down and no release sent yet (got %d)" % restarts[0])

	Input.parse_input_event(_touch_at(summary_at, false, 0))
	Input.flush_buffered_events()
	t.check(restarts[0] == 1, "the day summary's release does not restart it a second time")
	t.check(continued[0] == 0, "and never reads as continuing")

	t.get_tree().paused = false
	summary.queue_free()

	# Day summary, a real mouse hold.
	summary = SUMMARY.instantiate()
	t.add_child(summary)
	restarts = [0]
	continued = [0]
	summary.restart_requested.connect(func() -> void: restarts[0] += 1)
	summary.continued.connect(func() -> void: continued[0] += 1)
	summary._touch = false
	summary.show_day(1, GameEnums.DayResult.LOST_TIMEOUT, "", 3)
	summary._restart_button.position = Vector2(500.0, 400.0)
	summary._restart_button.size = Vector2(92.0, 108.0)
	summary_at = summary._restart_button.get_global_rect().get_center()

	Input.parse_input_event(_mouse_at(summary_at, true))
	Input.flush_buffered_events()
	summary._restart_button._held_since = \
			Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	summary._restart_button._process(0.0)
	t.check(restarts[0] == 1,
			"the day summary's real mouse hold restarts the instant the disc fills, with the "
			+ "button still down and no release sent yet (got %d)" % restarts[0])

	Input.parse_input_event(_mouse_at(summary_at, false))
	Input.flush_buffered_events()
	t.check(restarts[0] == 1, "the day summary's mouse release does not restart it a second time")
	t.check(continued[0] == 0, "and never reads as continuing")

	t.get_tree().paused = false
	summary.queue_free()

	t.get_window().size = original_window_size

func _touch_at(position: Vector2, pressed: bool, index: int) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = index
	return event

func _mouse_at(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.pressed = pressed
	event.button_index = MOUSE_BUTTON_LEFT
	return event
