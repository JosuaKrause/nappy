class_name RigLock
extends Node
## A rig's window takes no OS focus, hears no real key or pointer press, and quits itself on a
## deadline: three defences for the one thing the player named about rig windows, that they take
## the focus away and stay open (PLAYTEST-133). A no-op the instant `config.is_rig` is false, which
## is every plain `tools/run.sh` session a person is playing.
##
## **Added first thing in `main._ready()`**, ahead of either boot's own branch, so every boot gets
## all three. The window flag is applied as early as a scene's script can act: Godot creates the
## OS window during engine start-up, before any scene script exists.
##
## **Two input defences, because a real key reaches the game two ways.** `_input()` closes the
## event-dispatch half (the pause action, the title's Space, the pause and title screens' raw
## `KEY_R`/`KEY_Q`, the debug keys). Erasing every action's `InputMap` bindings closes the polled
## half: `Stroller._physics_process()` reads `Input.get_vector()` every tick, never an event, so a
## real WASD press would still move her with every event marked handled. The rig's own presses
## (`AutoScreenshot`'s `Input.action_press()` and `Input.parse_input_event()`) do not go through
## `InputMap` matching, so they keep working.
##
## Runs through a pause, since it inherits `main`'s `PROCESS_MODE_ALWAYS`: whatever screen is up
## when the deadline passes, a rig still quits. `tools/shot.sh` (and a rig-flagged `tools/run.sh`)
## is the outside backstop for a process that stops running altogether.

## Whether this run is a rig's (`config.is_rig`), and so locked out — a member, so a test can set it.
var locked_out := false
## The `Time.get_ticks_msec()` reading the rig quits at, or `0` for none: a person's session, or a
## recording, which keeps `_quit_game_seconds` instead. `0` is safe as the sentinel because
## `Time.get_ticks_msec()` only grows from the process's start.
##
## **Real OS time, not accumulated frame `delta`, and that is load-bearing.** A covered, unfocused
## window can stall (`--disable-vsync` in `tools/shot.sh`/`tools/run.sh` is the fix) in a way that
## collapses how often `_process()` runs without collapsing what each call reports as its `delta`,
## so a deadline summed from `delta` can lag the wall clock by exactly what the stall hides. Reading
## the clock fresh means the next call to happen, however late, quits right then.
var _quit_deadline_msec := 0
## **Under Godot's movie writer (`config.recording`), the same deadline in game seconds**, or `0.0`
## for none. A recording runs frame-locked and saves every frame before drawing the next, so its
## wall clock runs several times slower than its game clock and a wall-clock deadline would end a
## legitimate recording partway; `delta` is exact there by construction. What stops a recording
## that has stopped running at all is the recording script's own outside kill
## (`tools/lib_dev_flags.sh`, `rig_kill_after_movie_seconds`).
var _quit_game_seconds := 0.0
## What the quit lines name as the limit.
var _limit_seconds := 0.0
## Each action `_erase_real_input()` emptied, mapped to the `InputEvent`s it held, so
## `_exit_tree()` can put them back. Empty for a run that is not a rig's.
var _erased_bindings: Dictionary[StringName, Array] = {}

## Locks a rig's run out, from `config`. Nothing happens for a run that is not a rig.
func setup(config: RunConfig) -> void:
	if not config.is_rig:
		return
	locked_out = true
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	_erase_real_input()
	_limit_seconds = config.rig_quit_seconds()
	if config.recording:
		_quit_game_seconds = _limit_seconds
	else:
		_quit_deadline_msec = Time.get_ticks_msec() + int(_limit_seconds * 1000.0)

## Whether a deadline is armed, wall clock or game seconds.
func has_a_deadline() -> bool:
	return _quit_deadline_msec != 0 or _quit_game_seconds != 0.0

func _process(delta: float) -> void:
	if _quit_deadline_msec != 0 and Time.get_ticks_msec() >= _quit_deadline_msec:
		printerr("[Main] a rig's own wall-clock limit (%.1fs) passed with the run still going; quitting"
				% _limit_seconds)
		get_tree().quit(1)
		return
	if _quit_game_seconds > 0.0:
		_quit_game_seconds -= delta
		if _quit_game_seconds <= 0.0:
			printerr("[Main] a recorded rig's own limit (%.1f game seconds) passed with the run still "
					% _limit_seconds + "going; quitting")
			get_tree().quit(1)

## Marks every real event handled while the run is locked out, so none reaches the game's own
## handlers. **A rig's own press gets through by a tag on the event, not by its class** — see
## `is_the_rigs_own_press()`. It cannot pre-empt a sibling's `_input()` in the same phase
## (`TouchControls`), since `set_input_as_handled()` only silences the phases after `_input`; the
## window flag above is what keeps a pointer from reaching the window in the first place.
func _input(event: InputEvent) -> void:
	if locked_out and not is_the_rigs_own_press(event):
		get_viewport().set_input_as_handled()

## Whether `event` is one a rig made itself. `AutoScreenshot._tap()` sets
## `event.device = InputEvent.DEVICE_ID_EMULATION` (Godot's `-1`, distinct from the keyboard's `16`
## and the mouse's `32`) before handing it to `Input.parse_input_event()`, which leaves the tag
## untouched on its way to every handler. Gating on the event's class instead would let a real key
## through, since `key:` presses are the same `InputEventKey` a real key is. Static and pure, so a
## test asks it without booting a `main`.
static func is_the_rigs_own_press(event: InputEvent) -> bool:
	return event.device == InputEvent.DEVICE_ID_EMULATION

## Every action `project.godot`'s `[input]` table defines, read live off `InputMap` so a new binding
## is covered without a second list, except Godot's own built-in `ui_*` actions, which nothing in
## this game reads and whose loss would cost the engine's debugging shortcuts. What it erases is kept
## in `_erased_bindings` for `_exit_tree()` to put back.
func _erase_real_input() -> void:
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			_erased_bindings[action] = InputMap.action_get_events(action)
			InputMap.action_erase_events(action)

## **The lock gives the bindings back when it leaves the tree.** `InputMap` is process-wide, so a lock
## that erased it and never restored it would outlive its own `main`: a rig's process quits with it
## and never notices, but a test that boots a rig-flagged `main` and frees it would leave every later
## test in the same process with no key bound to any action — `TouchControls` asking whether a key is
## `move_right` would hear no. Out of the tree, `_input()` no longer runs either, so the lock is
## off as a whole.
func _exit_tree() -> void:
	for action: StringName in _erased_bindings:
		if InputMap.has_action(action):
			for event: InputEvent in _erased_bindings[action]:
				InputMap.action_add_event(action, event)
	_erased_bindings.clear()
