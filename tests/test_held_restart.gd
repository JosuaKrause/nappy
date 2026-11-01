extends RefCounted
## M211 + M212 — the pause screen's held restart restarts a run rather than resuming it, a hold
## survives what the real engine and a second finger can throw at it, the disc it fills lights up
## the same way for a touch hold as it does for a mouse one, and the restart itself fires the
## instant the disc fills rather than waiting for a release, on both the pause screen and the day
## summary.
##
## Held apart from `tests/test_pause.gd` because pinning M211's own bug, M212's own fill-visible
## bug, and Playtest 144's fires-on-release bug all need the real engine's input dispatch
## (`Input.parse_input_event()` + `Input.flush_buffered_events()`), not the `Viewport.push_input()`
## every touch test in that file drives — see
## `_test_the_pause_restart_survives_its_own_emulated_mouse_click()`'s own doc for why that
## distinction is the whole bug. A second finger is pushed through the viewport, which is all a
## second finger needs.
##
## Every screen is built with its platform handed in (`use_platform()`, `use_touch()`), laid out by
## real frames, and its restart button found by the name the scene gives it and pressed where it is
## really drawn; a hold of a full second is a button handed a clock that moves a second
## (`ModeButton.use_clock()`), and the button's own frame sees it. Nothing reads or writes a
## private member, and no frame is called by hand.
##
## **Causes investigated for M212 and found not to be bugs**, so no test pins them: a drag off the
## disc (the restart handler never reads an `InputEventScreenDrag` at all, and a release ends
## the hold by its touch index alone — the position is never rechecked, so drifting off the disc
## mid-hold changes nothing); a release reaching another control (the release branch returns before
## the catch-all ever sees it, whether or not the hold actually completed); the sweep drawn only on
## hover (`ModeButton._draw()` paints from `hold_progress` alone, with no hover term in it at all —
## see `_test_the_restart_disc_lights_up_the_same_for_a_touch_hold_as_a_mouse_one()`'s own doc for
## the hover term that actually was missing, one function over, where the button chooses its fill).

const UI := preload("res://tests/ui_screens.gd")
const PAUSE := preload("res://scenes/ui/pause_screen.tscn")
const SUMMARY := preload("res://scenes/ui/day_summary.tscn")

func run(t) -> void:
	await _test_the_pause_restart_survives_its_own_emulated_mouse_click(t)
	await _test_the_pause_restart_ignores_a_second_touch_mid_hold(t)
	await _test_the_summary_restart_ignores_a_second_touch_mid_hold(t)
	await _test_the_restart_discs_fill_climbs_through_a_real_touch_hold(t)
	await _test_the_restart_disc_lights_up_the_same_for_a_touch_hold_as_a_mouse_one(t)
	await _test_the_restart_fires_the_instant_the_disc_fills_not_on_release(t)

## An open pause screen on a platform, its restart button on `clock`, laid out.
func _open_pause(t, touch: bool, clock: UI.FakeClock) -> PauseScreen:
	var pause: PauseScreen = PAUSE.instantiate()
	pause.use_run(GameState)
	pause.use_platform(touch, true)
	t.add_child(pause)
	UI.button(pause, "Restart").use_clock(clock.read)
	t.get_tree().paused = false
	pause.open()
	await UI.frames(t)
	return pause

## A summary showing a lost day on a platform, its restart button on `clock`, laid out.
func _open_summary(t, touch: bool, clock: UI.FakeClock) -> CanvasLayer:
	var summary: CanvasLayer = SUMMARY.instantiate()
	summary.use_touch(touch)
	t.add_child(summary)
	UI.button(summary, "Restart").use_clock(clock.read)
	summary.show_summary(SummaryModel.day_over(GameState,
			UI.ended(GameEnums.DayResult.LOST_TIMEOUT)), RunFlow.Mode.DAY_OVER)
	await UI.frames(t)
	return summary

## Sends `event` through the engine's own input pipeline, emulate-mouse-from-touch included, and
## lets it dispatch.
func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()

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
## same finger — so the pause screen's own catch-all (`TouchInput.is_press()`, which does not ask
## whether this device even has touch hardware to emulate a click from) read the emulated click as
## *carry on* a moment ahead of the real touch reaching the restart handler, and the two-frame
## acknowledge delay closed the screen and cancelled the hold before it could ever complete — the
## real touch's own matching release then landed on a screen already invisible and did nothing at
## all. **Fixed** by gating the mouse branch of the pause screen's catch-all on `not touch`,
## exactly as the restart handler's own mouse branch and `DaySummary`'s equivalent catch-all
## already are.
##
## The window is forced to the fixed design box for the span of this test: real engine dispatch
## applies the window's own stretch transform to an event's position, which `Viewport
## .push_input(event, true)` deliberately skips (see `tests/test_pause.gd`'s own doc for that flag)
## but the automatic dispatch `Input.parse_input_event()` drives does not, and this suite's own
## window defaults to a headless placeholder far smaller than `ScreenOrientation.DESIGN_SIZE`.
func _test_the_pause_restart_survives_its_own_emulated_mouse_click(t) -> void:
	var original_window_size: Vector2i = t.get_window().size
	t.get_window().size = Vector2i(ScreenOrientation.DESIGN_SIZE)
	var clock := UI.FakeClock.new()
	var pause := await _open_pause(t, true, clock)
	var restart := UI.button(pause, "Restart")
	var restarts := [0]
	var resumed := [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)
	pause.resumed.connect(func() -> void: resumed[0] += 1)
	var at := UI.centre(restart)

	_send(UI.touch_at(at, true, 0))
	t.check(restart.is_held_by(0),
			"the real touch press starts the hold despite its own emulated mouse click landing "
			+ "first in the engine's own dispatch order")

	# The clock moves the full hold, so the frame below resolves it as a completed hold rather than
	# the test waiting out a real RESTART_HOLD_SECONDS.
	clock.now += ModeButton.RESTART_HOLD_SECONDS
	# Fires the moment the disc fills — *(Playtest 144: "The button only activated when releasing
	# though. It should trigger the moment it is full.")* — not on the release further down.
	await UI.frames(t)
	t.check(restarts[0] == 1,
			"held the full duration through the real emulation pipeline, the disc filling restarts "
			+ "the pause before any release (got %d)" % restarts[0])

	# The gap a real hold spans, during which the pre-fix bug's own acknowledge — launched by the
	# emulated click above, ahead of the real press — resolves its two-frame delay and, pre-fix,
	# closes the screen and cancels the hold out from under it.
	await UI.frames(t)

	_send(UI.touch_at(at, false, 0))

	t.get_window().size = original_window_size
	t.check(restarts[0] == 1,
			"and the matching release does not restart the pause a second time (got %d)"
					% restarts[0])
	t.check(resumed[0] == 0,
			"and the click the engine emulates ahead of the real press never resumes the day instead")

	pause.close()
	t.get_tree().paused = false
	pause.free()

## **A second finger anywhere on the screen no longer reads as *carry on* while the restart disc is
## already held.** *(M212: "sometimes it just doesn't work at all... you have to hold long multiple
## times".)* `ModeButton.begin_hold()` refusing a second index used to fall straight through to the
## catch-all below, which read any other touch as *carry on* and resumed the day — exactly what a
## palm graze or the other hand steadying the phone can send while a thumb holds restart down.
func _test_the_pause_restart_ignores_a_second_touch_mid_hold(t) -> void:
	var clock := UI.FakeClock.new()
	var pause := await _open_pause(t, true, clock)
	var restart := UI.button(pause, "Restart")
	var restarts := [0]
	var resumed := [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)
	pause.resumed.connect(func() -> void: resumed[0] += 1)
	var at := UI.centre(restart)

	UI.push(pause, UI.touch_at(at, true, 0))
	t.check(restart.is_held_by(0), "the first finger starts the hold")

	# A second finger, elsewhere on the screen entirely — not a drag of the first, a distinct index.
	# A press that carries on is acknowledged two frames ahead of itself — see
	# `tests/test_pause.gd`'s own `_test_a_tap_advances_every_screen` for why — so both frames pass
	# to give a pre-fix regression every chance to actually fire, and to actually cancel the first
	# finger's hold by closing the screen, before this asks.
	UI.push(pause, UI.touch_at(Vector2(20.0, 20.0), true, 1))
	await UI.frames(t)
	t.check(resumed[0] == 0, "the stray second finger does not read as carrying on")
	t.check(pause.is_open(), "and the screen stays open")
	t.check(restart.is_held_by(0), "the original hold is undisturbed")

	clock.now += ModeButton.RESTART_HOLD_SECONDS
	await UI.frames(t)
	t.check(restarts[0] == 1, "and the first finger's own hold still fires once it fills")
	UI.push(pause, UI.touch_at(at, false, 0))
	t.check(restarts[0] == 1, "and the eventual release does not restart it a second time")
	t.check(resumed[0] == 0, "never having resumed along the way")

	pause.close()
	t.get_tree().paused = false
	pause.free()

## The day summary's own half of the same fix — it carries the identical guard, since a stray
## second finger reaches its own catch-all (the acknowledge that continues) exactly the same way.
func _test_the_summary_restart_ignores_a_second_touch_mid_hold(t) -> void:
	var clock := UI.FakeClock.new()
	var summary := await _open_summary(t, true, clock)
	var restart := UI.button(summary, "Restart")
	var restarts := [0]
	var continued := [0]
	summary.restart_requested.connect(func() -> void: restarts[0] += 1)
	summary.continued.connect(func(_raised_in: int) -> void: continued[0] += 1)
	var at := UI.centre(restart)

	UI.push(summary, UI.touch_at(at, true, 0))
	t.check(restart.is_held_by(0), "the first finger starts the hold")

	UI.push(summary, UI.touch_at(Vector2(20.0, 20.0), true, 1))
	await UI.frames(t)
	t.check(continued[0] == 0, "the stray second finger does not read as continuing")
	t.check(restart.is_held_by(0), "the original hold is undisturbed")

	clock.now += ModeButton.RESTART_HOLD_SECONDS
	await UI.frames(t)
	t.check(restarts[0] == 1, "and the first finger's own hold still fires once it fills")
	UI.push(summary, UI.touch_at(at, false, 0))
	t.check(restarts[0] == 1, "and the eventual release does not restart it a second time")
	t.check(continued[0] == 0, "never having continued along the way")

	t.get_tree().paused = false
	summary.free()

## **M212's own "the disc's radial fill shows while a touch is held."** `ModeButton.hold_progress`
## is what the button paints as the sweep — see that file's own class comment — so this reads the
## value a screenshot would otherwise be needed to see, partway through a hold that nothing
## interrupts, on both screens the button appears on. The clock stands exactly half a hold on, so
## the disc is exactly half full.
func _test_the_restart_discs_fill_climbs_through_a_real_touch_hold(t) -> void:
	var clock := UI.FakeClock.new()
	var pause := await _open_pause(t, true, clock)
	var pause_restart := UI.button(pause, "Restart")
	var pause_at := UI.centre(pause_restart)

	UI.push(pause, UI.touch_at(pause_at, true, 0))
	clock.now += ModeButton.RESTART_HOLD_SECONDS * 0.5
	await UI.frames(t)
	t.check(pause_restart.hold_progress > 0.3 and pause_restart.hold_progress < 0.7,
			"halfway through the hold, the pause screen's own disc is about half full (got %.2f)"
					% pause_restart.hold_progress)
	t.close_to(pause_restart.hold_progress, 0.5,
			"and exactly half full on a clock that stands half a hold on", 0.001)

	UI.push(pause, UI.touch_at(pause_at, false, 0))
	pause.close()
	t.get_tree().paused = false
	pause.free()

	var summary_clock := UI.FakeClock.new()
	var summary := await _open_summary(t, true, summary_clock)
	var summary_restart := UI.button(summary, "Restart")
	var summary_at := UI.centre(summary_restart)

	UI.push(summary, UI.touch_at(summary_at, true, 0))
	summary_clock.now += ModeButton.RESTART_HOLD_SECONDS * 0.5
	await UI.frames(t)
	t.check(summary_restart.hold_progress > 0.3 and summary_restart.hold_progress < 0.7,
			"and the day summary's own disc fills the same way (got %.2f)"
					% summary_restart.hold_progress)
	t.close_to(summary_restart.hold_progress, 0.5,
			"and exactly half full on the summary's clock too", 0.001)

	UI.push(summary, UI.touch_at(summary_at, false, 0))
	t.get_tree().paused = false
	summary.free()

## **M212's "the restart button doesn't visible fill up on mobile when pressing" — the sweep was
## never invisible, the disc under it was.** `ModeButton` picks `Palette.BUTTON_HOVER` — a
## materially brighter fill than the resting `Palette.BUTTON_FILL` — whenever it is hovered, and a
## mouse hold sets it: the pointer that is pressing the disc also sits on top of it, so the
## screens' own `not touch` mouse-motion branch marks the button hovered for as long as the hold
## lasts. A touch sets nothing of the kind — there is no motion event to read a finger's position
## from between its press and its release — so a touch hold used to leave the translucent sweep
## painted over the plain resting fill instead of the brighter one a mouse hold reaches, on top of
## a disc already mostly covered by the finger holding it. **Fixed** by having the button's look
## also read whether it is held, so any hold — whatever started it — reaches the same brighter base.
##
## Driven through the real engine's own emulate-mouse-from-touch pass (`Input.parse_input_event()`
## + `Input.flush_buffered_events()`), the same way
## `_test_the_pause_restart_survives_its_own_emulated_mouse_click()` above does, so an emulated
## mouse motion synced to the touch position — if one ever reached the hover — could not quietly
## mask the bug by marking the button hovered on its own.
func _test_the_restart_disc_lights_up_the_same_for_a_touch_hold_as_a_mouse_one(t) -> void:
	var original_window_size: Vector2i = t.get_window().size
	t.get_window().size = Vector2i(ScreenOrientation.DESIGN_SIZE)

	var clock := UI.FakeClock.new()
	var pause := await _open_pause(t, false, clock)
	var pause_restart := UI.button(pause, "Restart")
	var pause_at := UI.centre(pause_restart)

	var hover := InputEventMouseMotion.new()
	hover.position = pause_at
	_send(hover)
	_send(UI.mouse_at(pause_at, true))
	clock.now += ModeButton.RESTART_HOLD_SECONDS * 0.5
	await UI.frames(t)
	var mouse_bg := UI.fill(pause_restart)
	t.check(mouse_bg == Palette.BUTTON_HOVER,
			"halfway through a mouse hold, the pause screen's disc reads the brighter hover fill")

	_send(UI.mouse_at(pause_at, false))
	pause.close()
	t.get_tree().paused = false
	pause.free()

	clock = UI.FakeClock.new()
	pause = await _open_pause(t, true, clock)
	pause_restart = UI.button(pause, "Restart")
	pause_at = UI.centre(pause_restart)

	_send(UI.touch_at(pause_at, true, 0))
	clock.now += ModeButton.RESTART_HOLD_SECONDS * 0.5
	await UI.frames(t)
	var touch_bg := UI.fill(pause_restart)
	t.check(touch_bg == mouse_bg,
			"and halfway through a real touch hold the pause screen's disc reads the same fill "
			+ "(got %s, wanted the mouse hold's %s)" % [touch_bg, mouse_bg])

	_send(UI.touch_at(pause_at, false, 0))
	pause.close()
	t.get_tree().paused = false
	pause.free()

	clock = UI.FakeClock.new()
	var summary := await _open_summary(t, true, clock)
	var summary_restart := UI.button(summary, "Restart")
	var summary_at := UI.centre(summary_restart)

	_send(UI.touch_at(summary_at, true, 0))
	clock.now += ModeButton.RESTART_HOLD_SECONDS * 0.5
	await UI.frames(t)
	t.check(UI.fill(summary_restart) == Palette.BUTTON_HOVER,
			"and the day summary's own disc reads the same brighter fill under a real touch hold")

	_send(UI.touch_at(summary_at, false, 0))
	t.get_tree().paused = false
	summary.free()

	t.get_window().size = original_window_size

## **Playtest 144: "The button only activated when releasing though. It should trigger the moment
## it is full."** A completed hold used to be decided at `end_hold()`'s own return on release; a
## finger or a mouse button held down well past `RESTART_HOLD_SECONDS` still had to be lifted
## before anything happened. `ModeButton` now raises `hold_completed` — which
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

	# [screen, touch, what the screen's pointer is called, what carrying on is called]
	for case: Array in [["pause", true, "pause screen's real touch hold", "finger", "resumed"],
			["pause", false, "pause screen's real mouse hold", "button", "resumed"],
			["summary", true, "day summary's real touch hold", "finger", "continued"],
			["summary", false, "day summary's real mouse hold", "button", "continued"]]:
		var is_pause: bool = case[0] == "pause"
		var touch: bool = case[1]
		var clock := UI.FakeClock.new()
		var screen: Node
		if is_pause:
			screen = await _open_pause(t, touch, clock)
		else:
			screen = await _open_summary(t, touch, clock)
		var restarts := [0]
		var carried_on := [0]
		screen.restart_requested.connect(func() -> void: restarts[0] += 1)
		if is_pause:
			screen.resumed.connect(func() -> void: carried_on[0] += 1)
		else:
			screen.continued.connect(func(_raised_in: int) -> void: carried_on[0] += 1)
		var at := UI.centre(UI.button(screen, "Restart"))

		_send(UI.touch_at(at, true, 0) if touch else UI.mouse_at(at, true))
		clock.now += ModeButton.RESTART_HOLD_SECONDS
		await UI.frames(t)
		t.check(restarts[0] == 1,
				"the %s restarts the instant the disc fills, with the %s still down and no "
				% [case[2], case[3]] + "release sent yet (got %d)" % restarts[0])

		_send(UI.touch_at(at, false, 0) if touch else UI.mouse_at(at, false))
		var release_name: String = case[2].replace("real touch hold", "release").replace(
				"real mouse hold", "mouse release")
		t.check(restarts[0] == 1,
				"the %s does not restart it a second time" % release_name)
		t.check(carried_on[0] == 0, "and never reads as carrying on")

		if is_pause:
			screen.close()
		t.get_tree().paused = false
		screen.free()

	t.get_window().size = original_window_size
