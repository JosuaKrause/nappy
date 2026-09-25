extends RefCounted
## M202, a rig's own presses reach the game: since M195, `main._input()` marks every event handled
## while `_rig_locked_out`, which is exactly the state every `--press` run is in — `--press` is one
## of `DevFlags._RIG_FLAGS`, so the lockout and the flag are never apart — and that swallowed the
## rig's own injected presses along with a real key or pointer, so `--press pause 3` paused nothing
## and `AutoScreenshot._debug_snapshot_action()` never saw `snapshot_burst` either.
##
## `main._is_the_rigs_own_press()` is what `_input()` now reads instead of marking every event
## handled outright: whether `event.device` carries `InputEvent.DEVICE_ID_EMULATION`, the constant
## `AutoScreenshot._tap()` tags its own events with before handing them to `Input.parse_input_event
## ()`. A test cannot boot a real `main` to prove `_input()` itself — `tests/test_main.gd`'s own
## class doc says why: `_ready()` starts a whole run — so `Gate` below is `_input()`'s one line,
## copied rather than boots, reading the same static predicate `main._input()` reads; if that
## predicate answers wrong, this suite and the real gate are wrong the same way.

const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")
const AUTO_SCREENSHOT: GDScript = preload("res://src/dev/auto_screenshot.gd")

## `main._input()`'s own gate, copied rather than driven through a booted `main` — see this file's
## own class doc. `locked_out` stands in for `_rig_locked_out`.
class Gate extends Node:
	var locked_out := false
	func _input(event: InputEvent) -> void:
		if locked_out and not MAIN_SCRIPT._is_the_rigs_own_press(event):
			get_viewport().set_input_as_handled()

## Stands in for `main._unhandled_input()`'s own guards (the pause action, the debug snapshot keys):
## anything that reaches this has cleared `Gate` above, the same way reaching `main._unhandled_input
## ()` means `main._input()` did not mark the event handled first.
class Catcher extends Node:
	var seen: Array[InputEvent] = []
	func _unhandled_input(event: InputEvent) -> void:
		seen.append(event)

func run(t) -> void:
	_test_is_the_rigs_own_press(t)
	_test_a_real_key_and_pointer_press_are_swallowed_while_locked_out(t)
	_test_both_forms_of_a_taps_press_reach_the_unhandled_phase_while_locked_out(t)
	_test_the_gate_does_nothing_once_the_rig_unlocks(t)

# ------------------------------------------------------------------ predicate ---

## The predicate on its own, both event classes `--press` can produce (`InputEventAction` for a
## named action, `InputEventKey` for `key:<name>`) and both the default a fresh event carries and
## the two device ids Godot itself reserves for real hardware — `DEVICE_ID_KEYBOARD` (16) and
## `DEVICE_ID_MOUSE` (32) — so this is not merely "false unless tagged" by accident of the default.
func _test_is_the_rigs_own_press(t) -> void:
	var untagged_action := InputEventAction.new()
	untagged_action.action = &"pause"
	t.check(not MAIN_SCRIPT._is_the_rigs_own_press(untagged_action),
			"a freshly-built action event, device left at its default, is not the rig's own")

	var untagged_key := InputEventKey.new()
	untagged_key.keycode = KEY_R
	t.check(not MAIN_SCRIPT._is_the_rigs_own_press(untagged_key),
			"a freshly-built key event, device left at its default, is not the rig's own")

	var keyboard_key := InputEventKey.new()
	keyboard_key.keycode = KEY_R
	keyboard_key.device = InputEvent.DEVICE_ID_KEYBOARD
	t.check(not MAIN_SCRIPT._is_the_rigs_own_press(keyboard_key),
			"a key tagged as real keyboard hardware is not the rig's own")

	var mouse_click := InputEventMouseButton.new()
	mouse_click.device = InputEvent.DEVICE_ID_MOUSE
	t.check(not MAIN_SCRIPT._is_the_rigs_own_press(mouse_click),
			"a click tagged as a real mouse is not the rig's own")

	var tagged_action := InputEventAction.new()
	tagged_action.action = &"pause"
	tagged_action.device = InputEvent.DEVICE_ID_EMULATION
	t.check(MAIN_SCRIPT._is_the_rigs_own_press(tagged_action),
			"an action event tagged DEVICE_ID_EMULATION is the rig's own")

	var tagged_key := InputEventKey.new()
	tagged_key.keycode = KEY_R
	tagged_key.device = InputEvent.DEVICE_ID_EMULATION
	t.check(MAIN_SCRIPT._is_the_rigs_own_press(tagged_key),
			"a key event tagged DEVICE_ID_EMULATION is the rig's own")

# ---------------------------------------------------------------------- gate ---

## A real-looking key and a real-looking pointer press, neither tagged, while the gate is locked
## out — both must be marked handled before `Catcher` ever sees them. `Input.flush_buffered_events()`
## is what makes `Input.parse_input_event()` dispatch synchronously rather than queue for a frame
## this suite never runs.
func _test_a_real_key_and_pointer_press_are_swallowed_while_locked_out(t) -> void:
	var gate := Gate.new()
	t.add_child(gate)
	var catcher := Catcher.new()
	t.add_child(catcher)
	gate.locked_out = true

	var real_key := InputEventKey.new()
	real_key.keycode = KEY_R
	real_key.pressed = true
	Input.parse_input_event(real_key)
	Input.flush_buffered_events()
	t.check(catcher.seen.is_empty(), "a real-looking key press never reaches the unhandled phase")

	var real_click := InputEventMouseButton.new()
	real_click.button_index = MOUSE_BUTTON_LEFT
	real_click.pressed = true
	Input.parse_input_event(real_click)
	Input.flush_buffered_events()
	t.check(catcher.seen.is_empty(), "a real-looking pointer press never reaches it either")

	gate.free()
	catcher.free()

## The two `--press` forms `AutoScreenshot._tap()` builds — a bare action (`pause`) and a `key:`
## keycode (`key:r`) — driven through the real `_tap()` rather than a hand-built stand-in, so a
## regression in the tagging itself, not only in this suite's idea of it, would fail here.
func _test_both_forms_of_a_taps_press_reach_the_unhandled_phase_while_locked_out(t) -> void:
	var gate := Gate.new()
	t.add_child(gate)
	var catcher := Catcher.new()
	t.add_child(catcher)
	gate.locked_out = true

	var rig: Node = AUTO_SCREENSHOT.new()
	rig._tap("pause")
	Input.flush_buffered_events()
	t.check(catcher.seen.size() == 2,
			"the action form presses and releases, both reaching the unhandled phase (got %d)"
			% catcher.seen.size())
	for event in catcher.seen:
		t.check(event is InputEventAction and event.action == &"pause",
				"and each one is the pause action the rig actually pressed (got %s)" % event)
	catcher.seen.clear()

	rig._tap("key:r")
	Input.flush_buffered_events()
	t.check(catcher.seen.size() == 2,
			"the key: form presses and releases too, both reaching the unhandled phase (got %d)"
			% catcher.seen.size())
	for event in catcher.seen:
		t.check(event is InputEventKey and event.keycode == KEY_R,
				"and each one is the R key the rig actually tapped (got %s)" % event)

	rig.free()
	gate.free()
	catcher.free()

## The gate off (a plain, unlocked run) has nothing to prove about tagging: every event, real or
## the rig's own, already reaches the unhandled phase, so this is what says the two tests above are
## about the lockout and not about `Catcher` catching everything regardless.
func _test_the_gate_does_nothing_once_the_rig_unlocks(t) -> void:
	var gate := Gate.new()
	t.add_child(gate)
	var catcher := Catcher.new()
	t.add_child(catcher)
	gate.locked_out = false

	var real_key := InputEventKey.new()
	real_key.keycode = KEY_R
	real_key.pressed = true
	Input.parse_input_event(real_key)
	Input.flush_buffered_events()
	t.check(catcher.seen.size() == 1, "with the rig unlocked, a real key reaches it same as ever")

	gate.free()
	catcher.free()
